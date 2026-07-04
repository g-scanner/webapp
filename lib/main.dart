import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gscanner/widgets/sync_data_screen.dart';

import 'models/types.dart';
import 'services/db_service.dart';

import 'widgets/camera_module.dart';
import 'widgets/history_list.dart';
import 'widgets/database_products.dart';
import 'widgets/settings_panel.dart';
import 'widgets/product_detail_card.dart';

// IMPORTA LA NUOVA SCHERMATA
import 'widgets/auth_screen.dart';

// --- Colori estratti dal tuo Tailwind HTML ---
const Color surfaceContainerLow = Color(0xFFF5F3F7);
const Color secondaryContainer = Color(0xFF54A0FE);
const Color onSecondaryContainer = Color(0xFF003567);
const Color onSurfaceVariant = Color(0xFF40493D);
const Color onSurface = Color(0xFF1B1B1E);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GScan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D631B)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      // LOGICA DI ROUTING: Ascolta i cambiamenti di stato di Firebase
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. In attesa della risposta da Firebase
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF0D631B)),
              ),
            );
          }

          // 2. Utente Loggato (Social o Anonimo) -> Vai all'app
          if (snapshot.hasData && snapshot.data != null) {
            return const MainScreen();
          }

          // 3. Nessun utente loggato -> Mostra la UI di Login
          return const AuthScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isCameraActive = true;

  List<Product> products = [];
  List<ScanHistoryItem> history = [];
  List<ProductReport> reports = [];
  UserSettings userSettings = UserSettings(
    strictMode: true,
    alertLactose: false,
    warnAdditives: true,
    autoSaveHistory: true,
    preferredLanguage: "it",
  );

  String? userId;
  List<String> reportedSessionBarcodes = [];
  bool scanningProgress = false;
  String? scanError;
  bool loadingApp = true;

  bool _requiresSyncDecision = false;
  int _anonymousHistoryCount = 0;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) setState(() => userId = user?.uid);

      if (user != null) {
        var settings = await DbService.getLocalSettings();

        // ATTENZIONE: Qui usiamo il NUOVO metodo per forzare la lettura locale!
        final localHistory = await DbService.getLocalUnsyncedHistory();
        final localReports = await DbService.getLocalUnsyncedReports();

        // Se l'utente è Google/Facebook, ci sono dati locali "orfani" e l'ID è cambiato
        if (!user.isAnonymous &&
            (localHistory.isNotEmpty || localReports.isNotEmpty) &&
            settings.userId != user.uid) {
          if (mounted) {
            setState(() {
              _anonymousHistoryCount =
                  localHistory.length + localReports.length;
              _requiresSyncDecision = true;
              loadingApp = false;
            });
          }
          return;
        }
        // Sincronizza le impostazioni con Firestore per utenti registrati
        if (!user.isAnonymous) {
          settings = await DbService.syncSettingsWithFirestore(settings);
          if (mounted) setState(() => userSettings = settings);
        }
      }

      await _loadAllData();
    } catch (e) {
      print("Inizializzazione fallita: $e");
      if (mounted) setState(() => loadingApp = false);
    }
  }

  // 4. Estrai il caricamento dei dati in una funzione a parte (per richiamarla dopo la decisione)
  Future<void> _loadAllData() async {
    await Future.wait([_fetchHistory(), _fetchSettings()]);
    _fetchProducts();
    _fetchReports();
    if (mounted) setState(() => loadingApp = false);
  }

  Future<void> _fetchProducts() async {
    final data = await DbService.fetchAllProducts();
    if (mounted) setState(() => products = data);
  }

  Future<void> _fetchHistory() async {
    final data = await DbService.getHistory();
    if (mounted) setState(() => history = data);
  }

  Future<void> _fetchReports() async {
    final data = await DbService.fetchUserReports();
    if (mounted) setState(() => reports = data);
  }

  Future<void> _fetchSettings() async {
    var data = await DbService.getLocalSettings();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      data = await DbService.syncSettingsWithFirestore(data);
    }
    if (mounted) setState(() => userSettings = data);
  }

  Future<void> refreshAllData() async {
    await Future.wait([_fetchProducts(), _fetchHistory(), _fetchReports()]);
  }

  Future<void> handleScanSuccess(String barcode) async {
    setState(() {
      scanningProgress = true;
      scanError = null;
    });

    try {
      final product = await DbService.scanBarcodeClientSide(
        barcode,
        userSettings,
      );
      _fetchHistory();
      _fetchProducts();

      if (mounted) {
        _navigateToProduct(product);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          scanError =
              "Errore di analisi o connessione con il database celiaci.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          scanningProgress = false;
        });
      }
    }
  }

  Future<void> handleReportSubmit(
    String barcode,
    Map<String, dynamic> reportData,
  ) async {
    try {
      final product = products.firstWhere(
        (p) => p.barcode == barcode,
        orElse: () => Product(
          barcode: barcode,
          name: "Product",
          brand: "Brand",
          ingredients: "",
          allergens: [],
          status: GlutenSafetyStatus.sconosciuto,
          reason: "",
          lastUpdated: "",
        ),
      );

      await DbService.submitProductReportClientSide(
        barcode,
        product.name,
        product.brand,
        reportData,
      );

      setState(() {
        reportedSessionBarcodes.add(barcode);
        if (!userSettings.reportedBarcodes.contains(barcode)) {
          userSettings = UserSettings(
            userId: userSettings.userId,
            strictMode: userSettings.strictMode,
            alertLactose: userSettings.alertLactose,
            warnAdditives: userSettings.warnAdditives,
            autoSaveHistory: userSettings.autoSaveHistory,
            preferredLanguage: userSettings.preferredLanguage,
            reportedBarcodes: [...userSettings.reportedBarcodes, barcode],
          );
        }
      });
      await DbService.saveSettings(userSettings);

      await Future.wait([_fetchReports(), _fetchProducts()]);
    } catch (e) {
      print("Segnalazione fallita: $e");
    }
  }

  Future<void> handleProductUpdate(Product updatedProduct) async {
    try {
      final finalProduct = Product(
        barcode: updatedProduct.barcode,
        name: updatedProduct.name,
        brand: updatedProduct.brand,
        ingredients: updatedProduct.ingredients,
        allergens: updatedProduct.allergens,
        status: updatedProduct.status,
        reason: updatedProduct.reason,
        ingredientsAnalyzed: updatedProduct.ingredientsAnalyzed,
        imageUrl: updatedProduct.imageUrl,
        lastUpdated: DateTime.now().toIso8601String(),
        reportCount: updatedProduct.reportCount,
      );
      await DbService.db
          .collection('products')
          .doc(finalProduct.barcode)
          .set(finalProduct.toJson(), SetOptions(merge: true));

      await _fetchProducts();
    } catch (e) {
      print("Aggiornamento fallito: $e");
    }
  }

  Future<void> handleDeleteHistoryByBarcode(String barcode) async {
    await DbService.deleteHistoryByBarcodeLocal(barcode);
    await _fetchHistory();
  }

  Future<void> handleDeleteReport(String reportId) async {
    await DbService.deleteReportFromDb(reportId);
    setState(() {}); // Forza l'aggiornamento
    await _fetchReports();
    await _fetchProducts();
  }

  void _navigateToProduct(Product match) async {
    setState(() => _isCameraActive = false);

    final userReport = reports.cast<ProductReport?>().firstWhere(
      (r) => r?.barcode == match.barcode && r?.userId == userId,
      orElse: () => null,
    );
    final isInHistory = history.any((h) => h.barcode == match.barcode);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailCard(
          product: match,
          onBack: () => Navigator.pop(context),
          onReportSubmit: handleReportSubmit,
          onProductUpdate: handleProductUpdate,
          userSettings: userSettings,
          onDeleteHistoryByBarcode: isInHistory
              ? handleDeleteHistoryByBarcode
              : null,
          hasReportedThisSession:
              reportedSessionBarcodes.contains(match.barcode) ||
              userReport != null,
          userReportId: userReport?.id,
          onDeleteReport: handleDeleteReport,
        ),
      ),
    );

    if (mounted) {
      setState(() => _isCameraActive = true);
    }
  }

  Widget _buildBody() {
    if (loadingApp) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF0D631B)),
            SizedBox(height: 16),
            Text(
              "Inizializzazione Database...",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return IndexedStack(
      index: _currentIndex > 3 ? 3 : _currentIndex,
      children: [
        CameraModule(
          isActive: _isCameraActive && _currentIndex == 0,
          onScanSuccess: handleScanSuccess,
          scanningProgress: scanningProgress,
          scanError: scanError,
        ),
        HistoryList(
          history: history,
          liveProducts: products,
          onRefresh: refreshAllData,
          onSelectItem: (barcode) {
            final match = products.cast<Product?>().firstWhere(
              (p) => p?.barcode == barcode,
              orElse: () => null,
            );
            if (match != null) {
              _navigateToProduct(match);
            }
          },
          onClearHistory: () async {
            await DbService.wipeHistoryLocal();
            await _fetchHistory();
          },
          onDeleteHistoryItem: (id) async {
            await DbService.deleteHistoryItemLocal(id);
            await _fetchHistory();
          },
        ),
        DatabaseProducts(
          products: products,
          reportedBarcodes: userSettings.reportedBarcodes,
          onRefresh: refreshAllData,
          onSelectItem: (barcode) {
            final match = products.cast<Product?>().firstWhere(
              (p) => p?.barcode == barcode,
              orElse: () => null,
            );
            if (match != null) {
              _navigateToProduct(match);
            }
          },
        ),
        SettingsPanel(
          settings: userSettings,
          onSettingsChange: (newSet) async {
            await DbService.saveSettings(newSet);
            setState(() => userSettings = newSet);
          },
          onResetDB: () async {
            await DbService.wipeHistoryLocal();
            setState(() {
              history = [];
              _currentIndex = 0;
            });
          },
          onClearHistory: () async {
            await DbService.wipeHistoryLocal();
            await _fetchHistory();
          },
        ),
      ],
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildNavItem(
                0,
                Icons.qr_code_scanner,
                Icons.qr_code_scanner,
                "Scansione",
              ),
              _buildNavItem(1, Icons.history, Icons.history, "Cronologia"),
              _buildNavItem(
                2,
                Icons.report_problem,
                Icons.report_problem_outlined,
                "Segnalazioni",
              ),
              _buildNavItem(
                3,
                Icons.settings,
                Icons.settings_outlined,
                "Impostazioni",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final activeIndex = _currentIndex > 3 ? 3 : _currentIndex;
    final isSelected = activeIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? secondaryContainer.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    color: isSelected ? onSecondaryContainer : onSurfaceVariant,
                    size: 26,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? onSecondaryContainer
                            : onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // SE L'UTENTE DEVE PRENDERE UNA DECISIONE, SOSTITUIAMO TUTTO LO SCHERMO
    if (_requiresSyncDecision) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF9FC),
        body: SyncDataScreen(
          historyCount: _anonymousHistoryCount,
          onDecision: (bool wantToSync) async {
            // L'utente ha premuto un pulsante, riattiviamo il caricamento
            setState(() {
              _requiresSyncDecision = false;
              loadingApp = true;
            });

            if (wantToSync) {
              // Ha scelto di UNIRE: migra cronologia, segnalazioni e barcode segnalati
              await DbService.migrateLocalDataToFirestore(userId!);
            } else {
              // Ha scelto di CANCELLARE: Svuotiamo tutti i dati locali e assegniamo il nuovo ID
              await DbService.wipeAllLocalData();
            }

            // Adesso riprendiamo il caricamento normale dei dati
            await _loadAllData();
          },
        ),
      );
    }

    // ALTRIMENTI MOSTRA LA NORMALE APP
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FC),
      appBar: AppBar(
        title: const Text(
          "G-Scanner",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: -0.5,
            color: onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _buildBody(), // Il tuo IndexedStack originale
      bottomNavigationBar: _currentIndex == 4 ? null : _buildCustomBottomNav(),
    );
  }
}
