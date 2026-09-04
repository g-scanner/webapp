// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gscanner/widgets/sync_data_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:easy_localization/easy_localization.dart';

import 'models/models.dart';
import 'services/analyzer_service.dart';
import 'services/db_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';

import 'widgets/camera_module.dart';
import 'widgets/history_list.dart';
import 'widgets/reports_list.dart';
import 'widgets/settings_panel.dart';
import 'widgets/product_detail_card.dart';
import 'widgets/report_detail_card.dart';

import 'widgets/auth_screen.dart';
import 'widgets/responsive_wrapper.dart';
import 'core/localization/modular_asset_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();

  usePathUrlStrategy();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('it'),
        Locale('en'),
        Locale('de'),
        Locale('fr'),
        Locale('es'),
      ],
      path: 'assets/locales',
      fallbackLocale: const Locale('it'),
      useOnlyLangCode: true,
      assetLoader: const ModularAssetLoader(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final FirebaseAuth? auth;
  const MyApp({super.key, this.auth});

  @override
  Widget build(BuildContext context) {
    final firebaseAuth = auth ?? FirebaseAuth.instance;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'G-Scanner',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: currentThemeMode,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          // LOGICA DI ROUTING: Ascolta i cambiamenti di stato di Firebase
          home: StreamBuilder<User?>(
            stream: firebaseAuth.authStateChanges(),
            builder: (context, snapshot) {
              // 1. In attesa della risposta da Firebase
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }

              // 2. Utente Loggato (Social o Anonimo) -> Vai all'app
              if (snapshot.hasData && snapshot.data != null) {
                return MainScreen(auth: firebaseAuth);
              }

              // 3. Nessun utente loggato -> Mostra la UI di Login
              return AuthScreen(firebaseAuth: firebaseAuth);
            },
          ),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final FirebaseAuth? auth;
  const MainScreen({super.key, this.auth});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  int _currentIndex = 0;
  bool _isCameraActive = true;
  double _maxKeyboardHeight = 0.0;

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
    preferredLanguage: UserSettings.defaultSystemLanguage,
    preferredTheme: "system",
  );

  String? userId;
  List<String> reportedSessionBarcodes = [];
  bool scanningProgress = false;
  String? scanError;
  bool _isSyncing = false;

  final GlobalKey<NavigatorState> _contentNavigatorKey =
      GlobalKey<NavigatorState>();
  final Map<String, ValueNotifier<Product?>> _openProductNotifiers = {};
  final Map<String, ValueNotifier<String?>> _openReportIdNotifiers = {};

  bool _requiresSyncDecision = false;
  int _anonymousHistoryCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Non avviamo globalScannerController.start() qui per evitare race-condition su web:
    // l'avvio della fotocamera viene ora interamente demandato a CameraModule.
    _initApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Il ciclo di vita della fotocamera viene ora gestito reattivamente
    // in CameraModule tramite ScannerStateManager.
  }

  bool get _shouldEnableKeyboardDismiss {
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
    }
    return defaultTargetPlatform != TargetPlatform.windows &&
        defaultTargetPlatform != TargetPlatform.macOS &&
        defaultTargetPlatform != TargetPlatform.linux;
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    if (_shouldEnableKeyboardDismiss) {
      final view = View.maybeOf(context);
      if (view == null) return;

      final currentBottomInset = view.viewInsets.bottom;

      if (currentBottomInset == 0) {
        // La tastiera è completamente scomparsa.
        // Resettiamo l'altezza massima per la prossima volta.
        _maxKeyboardHeight = 0.0;
      } else {
        // La tastiera è (almeno parzialmente) aperta.
        // Registriamo il picco massimo di altezza raggiunto.
        if (currentBottomInset > _maxKeyboardHeight) {
          _maxKeyboardHeight = currentBottomInset;
        }

        // LA MAGIA:
        // Se l'altezza attuale crolla sotto il 75% dell'altezza massima,
        // ignoriamo i piccoli cambi (come T9 o Emoji) e deduciamo che
        // l'utente ha avviato l'animazione di chiusura.
        if (currentBottomInset < (_maxKeyboardHeight * 0.75)) {
          final currentFocus = FocusManager.instance.primaryFocus;
          if (currentFocus != null && currentFocus.hasFocus) {
            currentFocus.unfocus();
          }
        }
      }
    }
  }

  Future<void> _initApp() async {
    try {
      final user = _auth.currentUser;
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
      debugPrint("Inizializzazione fallita: $e");
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
    themeNotifier.value = themeModeFromString(data.preferredTheme);
    if (mounted) {
      setState(() => userSettings = data);
      // Sincronizza la locale UI con la preferenza dell'utente
      context.setLocale(Locale(data.preferredLanguage));
    }
  }

  void _syncEverythingWithFirestore() {
    // Delta sync prodotti in background
    DbService.performDeltaSync()
        .then((_) async {
          final updated = await DbService.getLocalProducts();
          if (mounted) setState(() => products = updated);
        })
        .catchError((e) {
          debugPrint("Failed to delta sync products: $e");
        });

    final user = _auth.currentUser;
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
          debugPrint("Failed to sync settings from Firestore: $e");
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
          debugPrint("Failed to sync history from Firestore: $e");
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
          debugPrint("Failed to sync reports from Firestore: $e");
          if (mounted) setState(() => _isReportsSynced = true);
        });
  }

  Future<void> _fetchProducts() async {
    // Usa la cache locale come fonte di verità primaria
    final data = await DbService.getLocalProducts();
    if (mounted) {
      setState(() {
        products = data;
        for (var barcode in _openProductNotifiers.keys) {
          final prod = products.cast<Product?>().firstWhere(
            (p) => p?.barcode == barcode,
            orElse: () => null,
          );
          if (prod != null) {
            _openProductNotifiers[barcode]!.value = prod;
          }
        }
      });
    }
    // Delta sync in background
    DbService.performDeltaSync()
        .then((_) async {
          final updated = await DbService.getLocalProducts();
          if (mounted) {
            setState(() {
              products = updated;
              for (var barcode in _openProductNotifiers.keys) {
                final prod = updated.cast<Product?>().firstWhere(
                  (p) => p?.barcode == barcode,
                  orElse: () => null,
                );
                if (prod != null) {
                  _openProductNotifiers[barcode]!.value = prod;
                }
              }
            });
          }
        })
        .catchError((e) {
          debugPrint('Delta sync error: $e');
          return null;
        });
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

    final productNotifier = ValueNotifier<Product?>(null);
    _openProductNotifiers[barcode] = productNotifier;
    final placeholderProduct = Product(
      barcode: barcode,
      nameMap: const {'it': 'Caricamento prodotto...'},
      brandMap: const {'it': 'Analisi in corso'},
      ingredientsMap: const {'it': 'Analisi degli ingredienti in corso...'},
      allergensMap: const {'it': <String>[]},
      lastUpdated: DateTime.now().toIso8601String(),
      pendingReportsCount: 0,
    );

    // Dichiarato prima dell'if(mounted) per essere accessibile nel try block.
    final isInHistoryNotifier = ValueNotifier<bool>(
      history.any((h) => h.barcode == barcode),
    );

    if (mounted) {
      final userReport = reports.cast<ProductReport?>().firstWhere(
        (r) => r?.barcode == barcode && r?.userId == userId,
        orElse: () => null,
      );

      final reportIdNotifier = _openReportIdNotifiers.putIfAbsent(
        barcode,
        () => ValueNotifier<String?>(userReport?.id),
      );
      reportIdNotifier.value = userReport?.id;

      final route = MaterialPageRoute(
        builder: (context) => ProductDetailCard(
          product: placeholderProduct,
          productNotifier: productNotifier,
          reportIdNotifier: reportIdNotifier,
          isInHistoryNotifier: isInHistoryNotifier,
          isLoading: true,
          scannedAt: DateTime.now().toIso8601String(),
          onBack: () => Navigator.pop(context),
          onReportSubmit: handleReportSubmit,
          onProductUpdate: handleProductUpdate,
          userSettings: userSettings,
          onDeleteHistoryByBarcode: handleDeleteHistoryByBarcode,
          hasReportedThisSession:
              reportedSessionBarcodes.contains(barcode) || userReport != null,
          userReportId: userReport?.id,
          onDeleteReport: handleDeleteReport,
          useResponsiveWrapper: MediaQuery.of(context).size.width <= 960,
          onViewReport: (loadedProduct) {
            final double screenWidth = MediaQuery.of(context).size.width;
            final bool isWideScreen = screenWidth > 960;
            final reportOfProduct = reports.cast<ProductReport?>().firstWhere(
              (r) => r?.barcode == loadedProduct.barcode && r?.userId == userId,
              orElse: () => null,
            );
            final bool isOwn =
                reportedSessionBarcodes.contains(loadedProduct.barcode) ||
                reportOfProduct != null;
            final String comment = reportOfProduct?.comments ?? '';
            final String rDate = reportOfProduct != null
                ? reportOfProduct.submittedAt
                : "";

            // Calcola originalStatus al volo (senza usare il campo legacy)
            final origLang = userSettings.preferredLanguage;
            final origAnalysis = AnalyzerService.analyzeGlutenSafety(
              name: loadedProduct.getName(origLang),
              brand: loadedProduct.getBrand(origLang),
              ingredients: loadedProduct.getIngredients(origLang),
              allergensList: loadedProduct.getAllergens(origLang),
              reportCount: 0,
              categoriesTags: const [],
              strictMode: userSettings.strictMode,
              warnAdditives: userSettings.warnAdditives,
              alertLactose: userSettings.alertLactose,
              preferredLanguage: origLang,
              ignoreReports: true,
            );
            final routeReport = MaterialPageRoute(
              builder: (context) => ReportDetailCard(
                product: loadedProduct,
                originalStatus: origAnalysis.status,
                onBack: () => Navigator.pop(context),
                reportReasonKey: reportOfProduct?.type ?? "label_unclear",
                reportComment: comment.isNotEmpty ? comment : "Nessun commento",
                reportDate: rDate,
                onVote: (vote) async {
                  await DbService.voteOnReportByBarcode(
                    loadedProduct.barcode,
                    vote,
                  );
                },
                onInitVote: () async {
                  return await DbService.getReportVoteDataByBarcode(
                    loadedProduct.barcode,
                  );
                },
                userSettings: userSettings,
                isOwnReport: isOwn,
                reportId: reportOfProduct?.id,
                onDeleteReport: handleDeleteReport,
                showProductLink: false,
                useResponsiveWrapper: !isWideScreen,
              ),
            );

            if (isWideScreen) {
              _contentNavigatorKey.currentState?.push(routeReport);
            } else {
              Navigator.push(context, routeReport);
            }
          },
        ),
      );

      final isWideScreen = MediaQuery.of(context).size.width > 960;
      final Future<void> pushFuture;
      if (isWideScreen) {
        pushFuture =
            _contentNavigatorKey.currentState?.push(route) ?? Future.value();
      } else {
        pushFuture = Navigator.push(context, route);
      }

      pushFuture.then((_) async {
        _openProductNotifiers.remove(barcode);
        _openReportIdNotifiers.remove(barcode);
        isInHistoryNotifier.dispose();
        if (mounted) {
          setState(() => _isCameraActive = true);
        }
      });
    }

    try {
      final product = await DbService.scanBarcodeClientSide(
        barcode,
        userSettings,
      );
      productNotifier.value = product;
      await _loadLocalHistory();
      // Notifica il widget che il prodotto è ora in cronologia:
      // il menu "Elimina dalla cronologia" apparirà istantaneamente.
      isInHistoryNotifier.value = true;
      _fetchProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Errore di analisi o connessione con il database."),
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
      final lang = userSettings.preferredLanguage;
      final product = products.firstWhere(
        (p) => p.barcode == barcode,
        orElse: () => Product(
          barcode: barcode,
          nameMap: const {'it': 'Prodotto'},
          brandMap: const {'it': ''},
          ingredientsMap: const {'it': ''},
          allergensMap: const {'it': <String>[]},
          lastUpdated: '',
        ),
      );

      // Aggiorna ottimisticamente pendingReportsCount in memoria (Pure-Data)
      final pIdx = products.indexWhere((p) => p.barcode == barcode);
      if (pIdx != -1) {
        final p = products[pIdx];
        products[pIdx] = Product(
          barcode: p.barcode,
          nameMap: p.nameMap,
          brandMap: p.brandMap,
          ingredientsMap: p.ingredientsMap,
          allergensMap: p.allergensMap,
          imageUrl: p.imageUrl,
          lastUpdated: p.lastUpdated,
          pendingReportsCount: p.pendingReportsCount + 1,
          fetchedFromOffAt: p.fetchedFromOffAt,
        );
        if (_openProductNotifiers.containsKey(barcode)) {
          _openProductNotifiers[barcode]!.value = products[pIdx];
        }
      }

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
            preferredTheme: userSettings.preferredTheme,
            reportedBarcodes: [...userSettings.reportedBarcodes, barcode],
          );
        }
      });

      final newReport = await DbService.submitProductReportClientSide(
        barcode,
        product.getName(lang),
        product.getBrand(lang),
        reportData,
      );

      if (_openReportIdNotifiers.containsKey(barcode)) {
        _openReportIdNotifiers[barcode]!.value = newReport.id;
      }

      await DbService.saveSettings(userSettings);
      await Future.wait([_loadLocalReports(), _fetchProducts()]);
    } catch (e) {
      debugPrint("Segnalazione fallita: $e");
    }
  }

  Future<void> handleProductUpdate(Product updatedProduct) async {
    try {
      // Pure-Data: salva solo i campi raw, no status/reason pre-calcolati
      final finalProduct = Product(
        barcode: updatedProduct.barcode,
        nameMap: updatedProduct.nameMap,
        brandMap: updatedProduct.brandMap,
        ingredientsMap: updatedProduct.ingredientsMap,
        allergensMap: updatedProduct.allergensMap,
        imageUrl: updatedProduct.imageUrl,
        lastUpdated: DateTime.now().toIso8601String(),
        pendingReportsCount: updatedProduct.pendingReportsCount,
        fetchedFromOffAt: updatedProduct.fetchedFromOffAt,
      );
      await DbService.db
          .collection('products')
          .doc(finalProduct.barcode)
          .set(finalProduct.toJson(), SetOptions(merge: true));

      if (_openProductNotifiers.containsKey(finalProduct.barcode)) {
        _openProductNotifiers[finalProduct.barcode]!.value = finalProduct;
      }
      await _fetchProducts();
    } catch (e) {
      debugPrint("Aggiornamento fallito: $e");
    }
  }

  Future<void> handleDeleteHistoryByBarcode(String barcode) async {
    await DbService.deleteHistoryByBarcodeLocal(barcode);
    await _loadLocalHistory();
  }

  Future<void> handleDeleteReport(String reportId) async {
    final report = reports.cast<ProductReport?>().firstWhere(
      (r) => r?.id == reportId,
      orElse: () => null,
    );
    final String? barcode = report?.barcode;

    // Non-ottimistico: aspettiamo la conferma del server prima di aggiornare la UI.
    // Per operazioni irreversibili è sbagliato assumere il successo in anticipo.
    try {
      await DbService.deleteReportFromDb(reportId);
      await DbService.deleteLocalReport(reportId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product.deleteReport.errorMessage'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return; // UI rimane invariata: il report non è stato eliminato
    }

    // Solo dopo la conferma del server aggiorniamo la UI
    if (mounted && barcode != null) {
      setState(() {
        reportedSessionBarcodes.remove(barcode);

        // Decrementa pendingReportsCount
        final pIdx = products.indexWhere((p) => p.barcode == barcode);
        if (pIdx != -1) {
          final p = products[pIdx];
          products[pIdx] = Product(
            barcode: p.barcode,
            nameMap: p.nameMap,
            brandMap: p.brandMap,
            ingredientsMap: p.ingredientsMap,
            allergensMap: p.allergensMap,
            imageUrl: p.imageUrl,
            lastUpdated: p.lastUpdated,
            pendingReportsCount: (p.pendingReportsCount - 1).clamp(0, 9999),
            fetchedFromOffAt: p.fetchedFromOffAt,
          );
          if (_openProductNotifiers.containsKey(barcode)) {
            _openProductNotifiers[barcode]!.value = products[pIdx];
          }
          if (_openReportIdNotifiers.containsKey(barcode)) {
            _openReportIdNotifiers[barcode]!.value = null;
          }
        }

        final updatedBarcodes = List<String>.from(
          userSettings.reportedBarcodes,
        )..remove(barcode);
        userSettings = UserSettings(
          userId: userSettings.userId,
          strictMode: userSettings.strictMode,
          alertLactose: userSettings.alertLactose,
          warnAdditives: userSettings.warnAdditives,
          autoSaveHistory: userSettings.autoSaveHistory,
          preferredLanguage: userSettings.preferredLanguage,
          preferredTheme: userSettings.preferredTheme,
          reportedBarcodes: updatedBarcodes,
        );
      });
    }

    DbService.saveLocalSettings(userSettings);
    DbService.saveSettings(userSettings);
    // Ricarica solo i report locali (senza refetch dei prodotti che causa il flash)
    await _loadLocalReports();
  }

  void _navigateToProduct(Product match) async {
    setState(() => _isCameraActive = false);

    if (!mounted) return;

    final userReport = reports.cast<ProductReport?>().firstWhere(
      (r) => r?.barcode == match.barcode && r?.userId == userId,
      orElse: () => null,
    );
    final isInHistory = history.any((h) => h.barcode == match.barcode);

    final notifier = _openProductNotifiers.putIfAbsent(
      match.barcode,
      () => ValueNotifier<Product?>(match),
    );
    notifier.value = match;

    final reportIdNotifier = _openReportIdNotifiers.putIfAbsent(
      match.barcode,
      () => ValueNotifier<String?>(userReport?.id),
    );
    reportIdNotifier.value = userReport?.id;

    final historyItem = history.cast<ScanHistoryItem?>().firstWhere(
      (h) => h?.barcode == match.barcode,
      orElse: () => null,
    );

    final route = MaterialPageRoute(
      builder: (context) => ProductDetailCard(
        product: match,
        productNotifier: notifier,
        reportIdNotifier: reportIdNotifier,
        scannedAt: historyItem?.scannedAt,
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
        useResponsiveWrapper: MediaQuery.of(context).size.width <= 960,
        onViewReport: (loadedProduct) {
          final double screenWidth = MediaQuery.of(context).size.width;
          final bool isWideScreen = screenWidth > 960;
          final reportOfProduct = reports.cast<ProductReport?>().firstWhere(
            (r) => r?.barcode == loadedProduct.barcode && r?.userId == userId,
            orElse: () => null,
          );
          final bool isOwn =
              reportedSessionBarcodes.contains(loadedProduct.barcode) ||
              reportOfProduct != null;
          final String comment = reportOfProduct?.comments ?? '';
          final String rDate = reportOfProduct != null
              ? reportOfProduct.submittedAt
              : "";

          // Calcola originalStatus on-the-fly senza campi legacy
          final oLang = userSettings.preferredLanguage;
          final oAnalysis = AnalyzerService.analyzeGlutenSafety(
            name: loadedProduct.getName(oLang),
            brand: loadedProduct.getBrand(oLang),
            ingredients: loadedProduct.getIngredients(oLang),
            allergensList: loadedProduct.getAllergens(oLang),
            reportCount: 0,
            categoriesTags: const [],
            strictMode: userSettings.strictMode,
            warnAdditives: userSettings.warnAdditives,
            alertLactose: userSettings.alertLactose,
            preferredLanguage: oLang,
            ignoreReports: true,
          );
          final routeReport = MaterialPageRoute(
            builder: (context) => ReportDetailCard(
              product: loadedProduct,
              originalStatus: oAnalysis.status,
              onBack: () => Navigator.pop(context),
              reportReasonKey: reportOfProduct?.type ?? "label_unclear",
              reportComment: comment.isNotEmpty ? comment : "Nessun commento",
              reportDate: rDate,
              onVote: (vote) async {
                await DbService.voteOnReportByBarcode(
                  loadedProduct.barcode,
                  vote,
                );
              },
              onInitVote: () async {
                return await DbService.getReportVoteDataByBarcode(
                  loadedProduct.barcode,
                );
              },
              userSettings: userSettings,
              isOwnReport: isOwn,
              reportId: reportOfProduct?.id,
              onDeleteReport: handleDeleteReport,
              showProductLink: false,
              useResponsiveWrapper: !isWideScreen,
            ),
          );

          if (isWideScreen) {
            _contentNavigatorKey.currentState?.push(routeReport);
          } else {
            Navigator.push(context, routeReport);
          }
        },
      ),
    );

    final isWideScreen = MediaQuery.of(context).size.width > 960;
    final Future<void> pushFuture;
    if (isWideScreen) {
      pushFuture =
          _contentNavigatorKey.currentState?.push(route) ?? Future.value();
    } else {
      pushFuture = Navigator.push(context, route);
    }

    await pushFuture;
    _openProductNotifiers.remove(match.barcode);
    _openReportIdNotifiers.remove(match.barcode);

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
        ReportsList(
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
          firebaseAuth: _auth,
          settings: userSettings,
          onSettingsChange: (newSet) async {
            setState(() => userSettings = newSet);
            themeNotifier.value = themeModeFromString(newSet.preferredTheme);
            await DbService.saveSettings(newSet);
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
        color: context.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.2 : 0.05,
            ),
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
                "common.navigation.scanner".tr(),
              ),
              _buildNavItem(1, Icons.history, Icons.history, "common.navigation.history".tr()),
              _buildNavItem(
                2,
                Icons.report_problem,
                Icons.report_problem_outlined,
                "common.navigation.reports".tr(),
              ),
              _buildNavItem(
                3,
                Icons.settings,
                Icons.settings_outlined,
                "common.navigation.settings".tr(),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: () async {
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
                    ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
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
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
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
        backgroundColor: context.colorScheme.surface,
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
      return Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: context.colorScheme.primary),
        ),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 960;

    Widget bodyWidget = _buildBody();
    // Su dispositivi senza tastiera fisica (incluso web su Android/iOS),
    // toccando fuori dal textfield o abbassando la tastiera si rimuove il focus.
    if (_shouldEnableKeyboardDismiss) {
      bodyWidget = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: bodyWidget,
      );
    }

    final scaffold = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "common.appName".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: bodyWidget,
      bottomNavigationBar: (isWideScreen || _currentIndex == 4)
          ? null
          : _buildCustomBottomNav(),
    );

    if (isWideScreen) {
      final colorScheme = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        left: 24,
                        right: 12,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.cardBackground,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: context.isDarkMode ? 0.2 : 0.06,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(23),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: NavigationRail(
                              backgroundColor: Colors.transparent,
                              groupAlignment: 0.0,
                              selectedIndex: _currentIndex < 4
                                  ? _currentIndex
                                  : 0,
                              onDestinationSelected: (int index) async {
                                _contentNavigatorKey.currentState?.popUntil(
                                  (route) => route.isFirst,
                                );
                                setState(() {
                                  _currentIndex = index;
                                  _isCameraActive = index == 0;
                                });
                              },
                              selectedLabelTextStyle: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSecondaryContainer,
                              ),
                              unselectedLabelTextStyle: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              selectedIconTheme: IconThemeData(
                                color: colorScheme.onSecondaryContainer,
                              ),
                              unselectedIconTheme: IconThemeData(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              indicatorColor: colorScheme.secondaryContainer
                                  .withValues(alpha: 0.3),
                              labelType: NavigationRailLabelType.all,
                              destinations: [
                                NavigationRailDestination(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  icon: const Icon(Icons.qr_code_scanner),
                                  selectedIcon: const Icon(Icons.qr_code_scanner),
                                  label: Text("common.navigation.scanner".tr()),
                                ),
                                NavigationRailDestination(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  icon: const Icon(Icons.history),
                                  selectedIcon: const Icon(Icons.history),
                                  label: Text("common.navigation.history".tr()),
                                ),
                                NavigationRailDestination(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  icon: const Icon(Icons.report_problem_outlined),
                                  selectedIcon: const Icon(Icons.report_problem),
                                  label: Text("common.navigation.reports".tr()),
                                ),
                                NavigationRailDestination(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  icon: const Icon(Icons.settings_outlined),
                                  selectedIcon: const Icon(Icons.settings),
                                  label: Text("common.navigation.settings".tr()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 24,
                          bottom: 24,
                          left: 12,
                          right: 24,
                        ),
                        child: Container(
                          width: 500,
                          decoration: BoxDecoration(
                            color: context.cardBackground,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: context.isDarkMode ? 0.2 : 0.06,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: Navigator(
                              key: _contentNavigatorKey,
                              pages: [
                                MaterialPage(
                                  key: const ValueKey('main_scaffold_page'),
                                  child: scaffold,
                                ),
                              ],
                              onDidRemovePage: (page) {
                                return;
                              },
                            ),
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
