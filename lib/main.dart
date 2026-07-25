import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gscanner/widgets/sync_data_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

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
import 'package:mobile_scanner/mobile_scanner.dart';

// --- Colori estratti dal tuo Tailwind HTML ---
const Color surfaceLowest = Color(0xFFFFFFFF);
const Color surfaceContainerLow = Color(0xFFF5F3F7);
const Color secondaryContainer = Color(0xFF54A0FE);
const Color onSecondaryContainer = Color(0xFF003567);
const Color onSurfaceVariant = Color(0xFF40493D);
const Color onSurface = Color(0xFF1B1B1E);

final MobileScannerController globalScannerController = MobileScannerController(
  detectionSpeed: DetectionSpeed.noDuplicates,
  formats: const [
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.qrCode,
  ],
  cameraResolution: const Size(480, 640),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Avvia il warmup della fotocamera durante lo splash nativo se l'utente è già loggato
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      globalScannerController.start();
    } catch (e) {
      print("Camera autostart in main failed: $e");
    }
  }

  usePathUrlStrategy();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'G-Scanner',
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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isCameraActive = true;

  List<Product> products = [];
  List<ScanHistoryItem> history = [];
  List<ProductReport> reports = [];
  bool _isHistorySynced = false;
  bool _isReportsSynced = false;
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

  final GlobalKey<NavigatorState> _contentNavigatorKey =
      GlobalKey<NavigatorState>();

  bool _requiresSyncDecision = false;
  int _anonymousHistoryCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      globalScannerController.start();
    } catch (e) {
      print("Camera start error in MainScreen initState: $e");
    }
    _initApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_currentIndex == 0 && _isCameraActive) {
        try {
          globalScannerController.start();
        } catch (_) {}
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      try {
        globalScannerController.stop();
      } catch (_) {}
    }
  }

  Future<void> _initApp() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) setState(() => userId = user?.uid);

      if (user != null) {
        // Carica impostazioni locali (istantaneo)
        var settings = await DbService.getLocalSettings();
        if (mounted) setState(() => userSettings = settings);

        // Controlla dati orfani per migrazione
        final localHistory = await DbService.getLocalUnsyncedHistory();
        final localReports = await DbService.getLocalUnsyncedReports();

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
      }

      // FASE 1: Carica dati locali istantaneamente
      await _loadAllLocalData();

      // FASE 2: Sincronizza con Firestore in background (fire-and-forget)
      _syncEverythingWithFirestore();
    } catch (e) {
      print("Inizializzazione fallita: $e");
    }
  }

  Future<void> _loadAllData() async {
    await _loadAllLocalData();
    _syncEverythingWithFirestore();
  }

  Future<void> _loadAllLocalData() async {
    await Future.wait([
      _loadLocalHistory(),
      _loadLocalReports(),
      _loadLocalSettings(),
      _loadLocalProducts(),
    ]);
  }

  Future<void> _loadLocalProducts() async {
    final localData = await DbService.getLocalProducts();
    if (mounted) {
      setState(() {
        products = localData;
      });
    }
  }

  Future<void> _loadLocalHistory() async {
    final localData = await DbService.getHistory();
    if (mounted) {
      setState(() {
        history = localData;
      });
    }
  }

  Future<void> _loadLocalReports() async {
    final localData = await DbService.fetchUserReports();
    if (mounted) {
      setState(() {
        reports = localData;
      });
    }
  }

  Future<void> _loadLocalSettings() async {
    final data = await DbService.getLocalSettings();
    if (mounted) setState(() => userSettings = data);
  }

  void _syncEverythingWithFirestore() {
    // Sincronizza prodotti in background (comune a tutti gli utenti, anche anonimi)
    DbService.fetchAllProducts()
        .then((remoteData) {
          if (mounted) setState(() => products = remoteData);
        })
        .catchError((e) {
          print("Failed to sync products from Firestore: $e");
        });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      // Per utenti anonimi non c'è nulla da sincronizzare per cronologia e segnalazioni personali, segna come completato
      if (mounted) {
        setState(() {
          _isHistorySynced = true;
          _isReportsSynced = true;
        });
      }
      return;
    }

    // Sincronizza impostazioni in background
    DbService.syncSettingsWithFirestore(userSettings)
        .then((syncedSettings) {
          if (mounted) setState(() => userSettings = syncedSettings);
        })
        .catchError((e) {
          print("Failed to sync settings from Firestore: $e");
        });

    // Sincronizza cronologia in background
    DbService.syncHistoryWithFirestore()
        .then((remoteData) {
          if (mounted) {
            setState(() {
              history = remoteData;
              _isHistorySynced = true;
            });
          }
        })
        .catchError((e) {
          print("Failed to sync history from Firestore: $e");
          if (mounted) setState(() => _isHistorySynced = true);
        });

    // Sincronizza segnalazioni in background
    DbService.syncReportsWithFirestore()
        .then((remoteData) {
          if (mounted) {
            setState(() {
              reports = remoteData;
              _isReportsSynced = true;
            });
          }
        })
        .catchError((e) {
          print("Failed to sync reports from Firestore: $e");
          if (mounted) setState(() => _isReportsSynced = true);
        });
  }

  Future<void> _fetchProducts() async {
    final data = await DbService.fetchAllProducts();
    if (mounted) {
      setState(() {
        products = data;
      });
    }
  }

  Future<void> refreshAllData() async {
    setState(() {
      _isHistorySynced = false;
      _isReportsSynced = false;
    });
    await Future.wait([
      _loadLocalHistory(),
      _loadLocalReports(),
      _loadLocalProducts(),
    ]);
    _syncEverythingWithFirestore();
  }

  Future<void> handleScanSuccess(String barcode) async {
    setState(() {
      scanningProgress = true;
      scanError = null;
      _isCameraActive = false;
    });

    try {
      await globalScannerController.stop();
    } catch (_) {}

    final productNotifier = ValueNotifier<Product?>(null);
    final placeholderProduct = Product(
      barcode: barcode,
      name: "Caricamento prodotto...",
      brand: "Analisi in corso",
      status: GlutenSafetyStatus.incerto,
      ingredients: "Analisi degli ingredienti e degli allergeni in corso...",
      allergens: const [],
      reason: "Elaborazione dati dal database in corso...",
      lastUpdated: DateTime.now().toIso8601String(),
    );

    if (mounted) {
      final userReport = reports.cast<ProductReport?>().firstWhere(
        (r) => r?.barcode == barcode && r?.userId == userId,
        orElse: () => null,
      );
      final isInHistory = history.any((h) => h.barcode == barcode);

      final route = MaterialPageRoute(
        builder: (context) => ProductDetailCard(
          product: placeholderProduct,
          productNotifier: productNotifier,
          isLoading: true,
          onBack: () => Navigator.pop(context),
          onReportSubmit: handleReportSubmit,
          onProductUpdate: handleProductUpdate,
          userSettings: userSettings,
          onDeleteHistoryByBarcode:
              isInHistory ? handleDeleteHistoryByBarcode : null,
          hasReportedThisSession:
              reportedSessionBarcodes.contains(barcode) ||
              userReport != null,
          userReportId: userReport?.id,
          onDeleteReport: handleDeleteReport,
        ),
      );

      final isWideScreen = MediaQuery.of(context).size.width > 960;
      final Future<void> pushFuture;
      if (isWideScreen) {
        pushFuture = _contentNavigatorKey.currentState?.push(route) ?? Future.value();
      } else {
        pushFuture = Navigator.push(context, route);
      }

      pushFuture.then((_) async {
        if (mounted) {
          setState(() => _isCameraActive = true);
          if (_currentIndex == 0) {
            try {
              await globalScannerController.start();
            } catch (_) {}
          }
        }
      });
    }

    try {
      final product = await DbService.scanBarcodeClientSide(
        barcode,
        userSettings,
      );
      productNotifier.value = product;
      _loadLocalHistory();
      _fetchProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Errore di analisi o connessione con il database."),
            backgroundColor: Color(0xFFBA1A1A),
          ),
        );
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
        product,
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

      await Future.wait([_loadLocalReports(), _fetchProducts()]);
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
        ingredientsMap: updatedProduct.ingredientsMap,
        allergensMap: updatedProduct.allergensMap,
        reasonsMap: updatedProduct.reasonsMap,
        ingredientsAnalyzedMap: updatedProduct.ingredientsAnalyzedMap,
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
    await _loadLocalHistory();
  }

  Future<void> handleDeleteReport(String reportId) async {
    await DbService.deleteReportFromDb(reportId);
    await DbService.deleteLocalReport(reportId);
    setState(() {}); // Forza l'aggiornamento
    await _loadLocalReports();
    await _fetchProducts();
  }

  void _navigateToProduct(Product match) async {
    setState(() => _isCameraActive = false);
    try {
      await globalScannerController.stop();
    } catch (e) {
      print("Error stopping camera on navigation: $e");
    }

    if (!mounted) return;

    final userReport = reports.cast<ProductReport?>().firstWhere(
      (r) => r?.barcode == match.barcode && r?.userId == userId,
      orElse: () => null,
    );
    final isInHistory = history.any((h) => h.barcode == match.barcode);

    final route = MaterialPageRoute(
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
    );

    final isWideScreen = MediaQuery.of(context).size.width > 960;
    final Future<void> pushFuture;
    if (isWideScreen) {
      pushFuture = _contentNavigatorKey.currentState?.push(route) ?? Future.value();
    } else {
      pushFuture = Navigator.push(context, route);
    }

    await pushFuture;

    if (mounted) {
      setState(() => _isCameraActive = true);
      if (_currentIndex == 0) {
        try {
          await globalScannerController.start();
        } catch (e) {
          print("Error starting camera on back navigation: $e");
        }
      }
    }
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex > 3 ? 3 : _currentIndex,
      children: [
        CameraModule(
          controller: globalScannerController,
          isActive: _isCameraActive && _currentIndex == 0,
          onScanSuccess: handleScanSuccess,
          scanningProgress: scanningProgress,
          scanError: scanError,
        ),
        HistoryList(
          history: history,
          liveProducts: products,
          onRefresh: refreshAllData,
          userSettings: userSettings,
          isSynced: _isHistorySynced,
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
            await _loadLocalHistory();
          },
          onDeleteHistoryItem: (id) async {
            await DbService.deleteHistoryItemLocal(id);
            await _loadLocalHistory();
          },
        ),
        DatabaseProducts(
          products: products,
          reportedBarcodes: userSettings.reportedBarcodes,
          onRefresh: refreshAllData,
          isSynced: _isReportsSynced,
          userSettings: userSettings,
          userReports: reports,
          onDeleteReport: handleDeleteReport,
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
            setState(() => userSettings = newSet);
            await DbService.saveLocalSettings(newSet);
            // Salva su Firestore in background senza bloccare la UI
            DbService.saveSettings(newSet);
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
            await _loadLocalHistory();
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
        onTap: () async {
          setState(() {
            _currentIndex = index;
            _isCameraActive = index == 0;
          });
          if (index == 0) {
            try {
              await globalScannerController.start();
            } catch (_) {}
          } else {
            try {
              await globalScannerController.stop();
            } catch (_) {}
          }
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

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 960;

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
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_contentNavigatorKey.currentState?.canPop() == true) {
              _contentNavigatorKey.currentState?.maybePop();
            }
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700, maxHeight: 900),
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
                          onDestinationSelected: (int index) async {
                            _contentNavigatorKey.currentState
                                ?.popUntil((route) => route.isFirst);
                            setState(() {
                              _currentIndex = index;
                              _isCameraActive = index == 0;
                            });
                            if (index == 0) {
                              try {
                                await globalScannerController.start();
                              } catch (_) {}
                            } else {
                              try {
                                await globalScannerController.stop();
                              } catch (_) {}
                            }
                          },
                          minWidth: 104,
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
                          indicatorColor: secondaryContainer.withValues(
                            alpha: 0.2,
                          ),
                          labelType: NavigationRailLabelType.all,
                          destinations: const [
                            NavigationRailDestination(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              icon: Icon(Icons.qr_code_scanner),
                              selectedIcon: Icon(Icons.qr_code_scanner),
                              label: Text('Scansione'),
                            ),
                            NavigationRailDestination(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              icon: Icon(Icons.history),
                              selectedIcon: Icon(Icons.history),
                              label: Text('Cronologia'),
                            ),
                            NavigationRailDestination(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              icon: Icon(Icons.report_problem_outlined),
                              selectedIcon: Icon(Icons.report_problem),
                              label: Text('Segnalazioni'),
                            ),
                            NavigationRailDestination(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              icon: Icon(Icons.settings_outlined),
                              selectedIcon: Icon(Icons.settings),
                              label: Text('Impostazioni'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 24,
                          bottom: 24,
                          left: 16,
                          right: 16,
                        ),
                        child: Container(
                          width: 500,
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
                          child: Navigator(
                            key: _contentNavigatorKey,
                            pages: [
                              MaterialPage(
                                key: ValueKey(_currentIndex),
                                child: scaffold,
                              ),
                            ],
                            onPopPage: (route, result) {
                              return route.didPop(result);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ResponsiveMaxCardWidth(maxWidth: 500, child: scaffold);
  }
}
