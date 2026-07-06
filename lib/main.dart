import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gscanner/widgets/sync_data_screen.dart';
import 'firebase_options.dart';

import 'models/types.dart';
import 'services/db_service.dart';

import 'widgets/camera_module.dart';
import 'widgets/history_list.dart';
import 'widgets/database_products.dart';
import 'widgets/settings_panel.dart';
import 'widgets/product_detail_card.dart';

// IMPORTA LA NUOVA SCHERMATA
import 'widgets/auth_screen.dart';

import 'widgets/responsive_wrapper.dart';

// --- Colori estratti dal tuo Tailwind HTML ---
const Color surfaceLowest = Color(0xFFFFFFFF);
const Color surfaceContainerLow = Color(0xFFF5F3F7);
const Color secondaryContainer = Color(0xFF54A0FE);
const Color onSecondaryContainer = Color(0xFF003567);
const Color onSurfaceVariant = Color(0xFF40493D);
const Color onSurface = Color(0xFF1B1B1E);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  bool _isSyncing = false;
  bool _settingsAlreadySynced = false;

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
            });
          }
          return;
        }
        // Sincronizza le impostazioni con Firestore per utenti registrati
        if (!user.isAnonymous) {
          settings = await DbService.syncSettingsWithFirestore(settings);
          _settingsAlreadySynced = true;
          if (mounted) setState(() => userSettings = settings);
        }
      }

      await _loadAllData();
    } catch (e) {
      print("Inizializzazione fallita: $e");
    }
  }

  // 4. Estrai il caricamento dei dati in una funzione a parte (per richiamarla dopo la decisione)
  Future<void> _loadAllData() async {
    await Future.wait([_fetchHistory(), _fetchSettings()]);
    // Carica prodotti e segnalazioni in background (non bloccanti)
    _fetchProducts();
    _fetchReports();
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
    if (user != null && !user.isAnonymous && !_settingsAlreadySynced) {
      data = await DbService.syncSettingsWithFirestore(data);
    }
    _settingsAlreadySynced = false;
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
            color: Colors.black.withValues(alpha: 0.05),
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
    final bool isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
            _isCameraActive = index == 0;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? secondaryContainer.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? onSecondaryContainer : onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? onSecondaryContainer : onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // SE L'UTENTE DEVE PRENDERE UNA DECISIONE DI SINCRONIZZAZIONE
    if (_requiresSyncDecision) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF9FC),
        body: SyncDataScreen(
          historyCount: _anonymousHistoryCount,
          onDecision: (bool wantToSync) async {
            setState(() {
              _requiresSyncDecision = false;
              _isSyncing = true;
            });

            if (wantToSync) {
              await DbService.migrateLocalDataToFirestore(userId!);
            } else {
              await DbService.wipeAllLocalData();
            }

            await _loadAllData();
            setState(() {
              _isSyncing = false;
            });
          },
        ),
      );
    }

    // SE C'È UN PROCESSO DI SINCRONIZZAZIONE ATTIVO
    if (_isSyncing) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF9FC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0D631B)),
        ),
      );
    }

    final bool isWideScreen = MediaQuery.of(context).size.width > 720;

    final scaffold = Scaffold(
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
      body: _buildBody(),
      bottomNavigationBar: (isWideScreen || _currentIndex == 4)
          ? null
          : _buildCustomBottomNav(),
    );

    if (isWideScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF9FC),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 800,
            ), // Rail (approx 80) + gap (24) + content (600)
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentIndex != 4)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 24,
                      bottom: 24,
                      left: 16,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceLowest,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: NavigationRail(
                        backgroundColor: Colors.transparent,
                        groupAlignment: 0.0,
                        selectedIndex: _currentIndex < 4 ? _currentIndex : 0,
                        onDestinationSelected: (int index) {
                          setState(() {
                            _currentIndex = index;
                            _isCameraActive = index == 0;
                          });
                        },
                        selectedLabelTextStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: onSecondaryContainer,
                        ),
                        unselectedLabelTextStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: onSurfaceVariant,
                        ),
                        selectedIconTheme: const IconThemeData(
                          color: onSecondaryContainer,
                        ),
                        unselectedIconTheme: const IconThemeData(
                          color: onSurfaceVariant,
                        ),
                        indicatorColor: secondaryContainer,
                        labelType: NavigationRailLabelType.all,
                        destinations: const [
                          NavigationRailDestination(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            icon: Icon(Icons.qr_code_scanner),
                            label: Text('Scansione'),
                          ),
                          NavigationRailDestination(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            icon: Icon(Icons.history),
                            label: Text('Cronologia'),
                          ),
                          NavigationRailDestination(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            icon: Icon(Icons.report_problem),
                            label: Text('Segnalazioni'),
                          ),
                          NavigationRailDestination(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            icon: Icon(Icons.settings),
                            label: Text('Impostazioni'),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: ResponsiveMaxCardWidth(maxWidth: 600, child: scaffold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ResponsiveMaxCardWidth(child: scaffold);
  }
}
