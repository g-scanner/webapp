// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:gscanner/models/models.dart';
import 'package:gscanner/services/analyzer_service.dart';
import 'package:gscanner/services/db_service.dart';
import 'package:gscanner/core/core.dart';

import 'package:gscanner/features/scanner/camera_module.dart';
import 'package:gscanner/features/history/history_list.dart';
import 'package:gscanner/features/reports/reports_list.dart';
import 'package:gscanner/features/settings/settings_panel.dart';
import 'package:gscanner/features/product_detail/product_detail_card.dart';
import 'package:gscanner/features/reports/report_detail_card.dart';
import 'package:gscanner/features/sync/sync_data_screen.dart';

import 'controllers/main_navigation_controller.dart';
import 'widgets/main_custom_bottom_nav.dart';
import 'widgets/main_desktop_navigation_rail.dart';
import 'widgets/main_indexed_stack.dart';

/// Schermata principale (Shell) dell'applicazione G-Scanner.
/// Coordina la navigazione a tab, la sincronizzazione dei dati e il routing ai dettagli.
class MainScreen extends StatefulWidget {
  final FirebaseAuth? auth;
  const MainScreen({super.key, this.auth});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;

  final MainNavigationController _navController = MainNavigationController();
  int get _currentIndex => _navController.currentIndex;
  bool get _isCameraActive => _navController.isCameraActive;

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

  /// Scansioni in background: il fetch continua anche se l'utente torna
  /// indietro dalla schermata del prodotto.  Barcode → productNotifier.
  /// Quando il fetch termina, il notifier viene aggiornato e il barcode rimosso.
  final Map<String, ValueNotifier<Product?>> _pendingScans = {};

  /// Elementi temporanei di cronologia per mostrare la card skeleton nella lista
  /// finché il fetch in background non è completato.
  final Map<String, ScanHistoryItem> _pendingHistoryItems = {};

  /// Callback per chiudere la route di dettaglio del prodotto (se attualmente aperta)
  /// in caso di fallimento della scansione.
  final Map<String, VoidCallback> _pendingDetailClosers = {};

  GlobalKey<NavigatorState> get _contentNavigatorKey =>
      _navController.contentNavigatorKey;
  Map<String, ValueNotifier<Product?>> get _openProductNotifiers =>
      _navController.openProductNotifiers;
  Map<String, ValueNotifier<String?>> get _openReportIdNotifiers =>
      _navController.openReportIdNotifiers;
  Map<String, ValueNotifier<bool>> get _openStaleNotifiers =>
      _navController.openStaleNotifiers;

  bool _requiresSyncDecision = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navController.addListener(_onNavigationChanged);
    _initApp();
  }

  void _onNavigationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navController.removeListener(_onNavigationChanged);
    _navController.dispose();
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
        _navController.maxKeyboardHeight = 0.0;
      } else {
        if (currentBottomInset > _navController.maxKeyboardHeight) {
          _navController.maxKeyboardHeight = currentBottomInset;
        }

        if (currentBottomInset < (_navController.maxKeyboardHeight * 0.75)) {
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
        var settings = await DbService.getLocalSettings();
        if (mounted) setState(() => userSettings = settings);

        final localHistory = await DbService.getLocalUnsyncedHistory();
        final localReports = await DbService.getLocalUnsyncedReports();

        if (!user.isAnonymous &&
            (localHistory.isNotEmpty || localReports.isNotEmpty) &&
            settings.userId != user.uid) {
          if (mounted) {
            setState(() {
              _requiresSyncDecision = true;
            });
          }
          return;
        }
      }

      await _loadAllLocalData();
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
      context.setLocale(Locale(data.preferredLanguage));
    }
  }

  void _syncEverythingWithFirestore() {
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
      if (mounted) {
        setState(() {
          _isHistorySynced = true;
          _isReportsSynced = true;
        });
      }
      return;
    }

    DbService.syncSettingsWithFirestore(userSettings)
        .then((syncedSettings) {
          if (mounted) setState(() => userSettings = syncedSettings);
        })
        .catchError((e) {
          debugPrint("Failed to sync settings from Firestore: $e");
        });

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

  Future<bool> handleScanSuccess(String barcode) async {
    // 0. Fail-fast immediato se offline e prodotto non in cache SQLite:
    // Se siamo offline e il prodotto non è già memorizzato localmente, abortiamo subito
    // senza aprire lo skeleton e senza creare elementi orfani in cronologia.
    final localProduct =
        await LocalCacheService.getLocalProductByBarcode(barcode);
    final isConnected = await ConnectivityHelper.hasInternetConnection();
    if (localProduct == null && !isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('scanner.result.offlineNoDbPrompt'.tr())),
        );
      }
      return false;
    }

    final now = DateTime.now().toIso8601String();
    final pendingItem = ScanHistoryItem(
      id: 'pending_$barcode',
      barcode: barcode,
      scannedAt: now,
    );

    final productNotifier = ValueNotifier<Product?>(null);
    _openProductNotifiers[barcode] = productNotifier;

    // Registra la scansione come "pending" fin da subito. Il notifier è
    // condiviso con _openProductNotifiers: quando il fetch termina (o se
    // l'utente torna indietro) la storia può mostrare lo stato di caricamento.
    _pendingScans[barcode] = productNotifier;
    _pendingHistoryItems[barcode] = pendingItem;

    setState(() {
      scanningProgress = true;
      scanError = null;
      _navController.setCameraActive(false);
    });

    final placeholderProduct = Product(
      barcode: barcode,
      nameMap: const {'it': 'Caricamento prodotto...'},
      brandMap: const {'it': 'Analisi in corso'},
      ingredientsMap: const {'it': 'Analisi degli ingredienti in corso...'},
      allergensMap: const {'it': <String>[]},
      lastUpdated: DateTime.now().toIso8601String(),
      pendingReportsCount: 0,
    );

    final isInHistoryNotifier = ValueNotifier<bool>(
      history.any((h) => h.barcode == barcode),
    );

    final isStaleDataNotifier = ValueNotifier<bool>(false);

    Future<void>? pushFuture;

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
          isStaleDataNotifier: isStaleDataNotifier,
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
          onViewReport: (loadedProduct) =>
              _openReportDetail(context, loadedProduct),
          onRefreshOnline: _refreshProductOnline,
        ),
      );

      _pendingDetailClosers[barcode] = () {
        if (route.isActive) {
          route.navigator?.pop();
        }
      };

      final isWideScreen = MediaQuery.of(context).size.width > 960;
      if (isWideScreen) {
        pushFuture =
            _contentNavigatorKey.currentState?.push(route) ?? Future.value();
      } else {
        pushFuture = Navigator.push(context, route);
      }
    }

    bool detailClosed = false;
    bool scanFinished = false;

    void cleanupNotifiers() {
      if (detailClosed && scanFinished) {
        isInHistoryNotifier.dispose();
        isStaleDataNotifier.dispose();
      }
    }

    final scanFuture = () async {
      try {
        ScanResult? scanResult;
        // Se la connessione è debole, attendiamo con un numero limitato di retry (2 retry, 3 tentativi totali).
        // Con pause da 8s e i timeout delle richieste, il tempo totale si colloca tra i 16 e i 28 secondi,
        // senza sovraccaricare il server di richieste.
        int scanRetries = 0;
        const maxScanRetries = 2;
        const retryDelay = Duration(seconds: 8);

        while (true) {
          try {
            scanResult = await DbService.scanBarcodeClientSide(
              barcode,
              userSettings,
            );
            break; // Scansione completata con successo!
          } on OfflineWithoutDbException catch (_) {
            scanRetries++;
            if (scanRetries > maxScanRetries || !mounted) {
              rethrow;
            }
            await Future.delayed(retryDelay);
            final hasNet = await ConnectivityHelper.hasInternetConnection();
            if (!hasNet) {
              rethrow;
            }
          } on OffNetworkException catch (_) {
            scanRetries++;
            if (scanRetries > maxScanRetries || !mounted) {
              rethrow;
            }
            await Future.delayed(retryDelay);
            final hasNet = await ConnectivityHelper.hasInternetConnection();
            if (!hasNet) {
              rethrow;
            }
          }
        }

        if (!detailClosed) {
          isStaleDataNotifier.value = scanResult.isStaleResult;
          isInHistoryNotifier.value = true;
        }
        productNotifier.value = scanResult.product;
        await _loadLocalHistory();
        _fetchProducts();

        // Se il risultato è stale (dispositivo offline o fallback da cache), avvia un check
        // in background con callback: quando il prodotto viene rinfrescato da OFF,
        // aggiorna productNotifier così che il banner stale sparisca automaticamente.
        if (scanResult.isStaleResult) {
          OffIngestionService.checkAndRefreshOffStaleCache(
            db: DbService.db,
            product: scanResult.product,
            settings: userSettings,
            onRefreshed: (freshProduct) {
              if (_openProductNotifiers.containsKey(freshProduct.barcode)) {
                _openProductNotifiers[freshProduct.barcode]!.value =
                    freshProduct;
              }
            },
          );
        }
      } on OfflineWithoutDbException catch (e) {
        await _handleScanFailure(barcode, e.localizationKey);
      } on OffNetworkException catch (e) {
        await _handleScanFailure(barcode, e.localizationKey);
      } catch (_) {
        await _handleScanFailure(barcode, 'scanner.result.analysisError');
      } finally {
        scanFinished = true;
        cleanupNotifiers();
        _pendingScans.remove(barcode);
        _pendingHistoryItems.remove(barcode);
        _pendingDetailClosers.remove(barcode);
        if (mounted) {
          setState(() => scanningProgress = false);
        }
      }
    }();

    if (pushFuture != null) {
      await pushFuture;
      detailClosed = true;
      cleanupNotifiers();
      _pendingDetailClosers.remove(barcode);

      // Quando l'utente torna indietro dalla schermata di dettaglio prodotto:
      // se al momento del ritorno i dati del prodotto sono stati caricati con successo
      // (non più in stato skeleton), restituiamo true per svuotare l'inserimento manuale.
      // Se invece l'utente è tornato indietro mentre la schermata era ancora in caricamento
      // con skeleton (o in caso di errore), restituiamo false per preservare il codice digitato.
      final wasLoaded = productNotifier.value != null;

      _openProductNotifiers.remove(barcode);
      _openReportIdNotifiers.remove(barcode);
      if (mounted) {
        setState(() {
          scanningProgress = false;
          _navController.setCameraActive(true);
        });
      }
      return wasLoaded;
    } else {
      await scanFuture;
      return productNotifier.value != null;
    }
  }

  /// Gestisce il fallimento di una scansione sia se l'utente è ancora nella route skeleton,
  /// sia se è tornato indietro (es. alla cronologia o fotocamera).
  Future<void> _handleScanFailure(
    String barcode,
    String localizationKey,
  ) async {
    final closer = _pendingDetailClosers.remove(barcode);
    if (closer != null) {
      // Caso 1: L'utente si trova attualmente sulla schermata skeleton del prodotto.
      // Chiudiamo la schermata e mostriamo lo snackbar di errore specifico.
      closer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizationKey.tr())),
        );
      }
    } else {
      // Caso 2: L'utente è tornato indietro durante il caricamento e si trova altrove
      // (es. in cronologia, fotocamera o impostazioni). Mostriamo l'avviso che la scansione è fallita.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('scanner.result.backgroundScanFailed'.tr())),
        );
      }
    }

    // In entrambi i casi: rimuoviamo la card skeleton dalla cronologia ed eliminiamo
    // ogni eventuale traccia dal database locale, così che riscansionando in futuro
    // non risorga alcun prodotto fallito.
    _pendingScans.remove(barcode);
    _pendingHistoryItems.remove(barcode);
    try {
      await DbService.deleteHistoryByBarcodeLocal(barcode);
    } catch (e) {
      debugPrint("Errore rimozione history item fallito: $e");
    }
    await _loadLocalHistory();

    if (mounted) {
      setState(() {
        scanningProgress = false;
      });
    }
  }

  /// Effettua il refresh asincrono da Open Food Facts per un prodotto attualmente
  /// visualizzato e stale, non appena la connessione torna disponibile.
  Future<void> _refreshProductOnline(String barcode) async {
    try {
      final offResult = await OffIngestionService.fetchOffProduct(
        barcode,
        userSettings,
      );

      Product? updatedProduct;
      if (offResult.status == OffFetchStatus.found && offResult.product != null) {
        updatedProduct = offResult.product!;
      } else if (offResult.status == OffFetchStatus.notFound) {
        // Se OFF conferma che non esiste, crea un ghost product fresco
        final nowIso = DateTime.now().toIso8601String();
        updatedProduct = Product(
          barcode: barcode,
          nameMap: {},
          brandMap: {},
          ingredientsMap: {},
          allergensMap: {},
          pendingReportsCount: 0,
          lastUpdated: nowIso,
          fetchedFromOffAt: nowIso,
        );
      }

      if (updatedProduct != null) {
        await DbService.upsertLocalProduct(updatedProduct);
        if (_openProductNotifiers.containsKey(barcode)) {
          _openProductNotifiers[barcode]!.value = updatedProduct;
        }
        if (_openStaleNotifiers.containsKey(barcode)) {
          _openStaleNotifiers[barcode]!.value = false;
        }
        _fetchProducts();
      }
    } catch (e) {
      debugPrint("Errore durante il refresh online del prodotto stale: $e");
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
    try {
      await DbService.deleteHistoryByBarcodeLocal(barcode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.actions.deleteError'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }
    await _loadLocalHistory();
  }

  Future<void> handleDeleteHistoryItem(String id) async {
    try {
      await DbService.deleteHistoryItemLocal(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.actions.deleteError'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }
    await _loadLocalHistory();
  }

  Future<void> handleClearHistory() async {
    try {
      await DbService.wipeHistoryLocal();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.actions.deleteHistoryError'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      rethrow;
    }
    await _loadLocalHistory();
  }

  Future<void> handleDeleteReport(String reportId) async {
    final report = reports.cast<ProductReport?>().firstWhere(
      (r) => r?.id == reportId,
      orElse: () => null,
    );
    final String? barcode = report?.barcode;

    try {
      await DbService.deleteReportFromDb(reportId);
      await DbService.deleteLocalReport(reportId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.actions.deleteError'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    if (mounted && barcode != null) {
      setState(() {
        reportedSessionBarcodes.remove(barcode);

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

        final updatedBarcodes = List<String>.from(userSettings.reportedBarcodes)
          ..remove(barcode);
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
    await _loadLocalReports();
  }

  void _navigateToProduct(Product match) async {
    // Se il barcode è ancora in caricamento (scansione pendente), mostra
    // la schermata skeleton con il notifier pendente che aggiornerà
    // automaticamente quando il fetch termina.
    if (_pendingScans.containsKey(match.barcode)) {
      _navigateToPendingProduct(match.barcode);
      return;
    }

    setState(() => _navController.setCameraActive(false));

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

    // Crea il notifier reattivo per lo stato stale, inizializzato dal valore corrente.
    // Viene passato al ProductDetailCard così che _onProductNotifierChanged
    // possa azzerarlo quando il prodotto viene rinfrescato da delta sync o background check.
    final staleNotifier = _openStaleNotifiers.putIfAbsent(
      match.barcode,
      () => ValueNotifier<bool>(match.isStale),
    );
    staleNotifier.value = match.isStale;

    final historyItem = history.cast<ScanHistoryItem?>().firstWhere(
      (h) => h?.barcode == match.barcode,
      orElse: () => null,
    );

    final route = MaterialPageRoute(
      builder: (context) => ProductDetailCard(
        product: match,
        productNotifier: notifier,
        reportIdNotifier: reportIdNotifier,
        isStaleDataNotifier: staleNotifier,
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
        onViewReport: (loadedProduct) =>
            _openReportDetail(context, loadedProduct),
        onRefreshOnline: _refreshProductOnline,
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
    _openStaleNotifiers.remove(match.barcode)?.dispose();

    if (mounted) {
      setState(() => _navController.setCameraActive(true));
    }
  }

  /// Naviga a un prodotto la cui scansione è ancora in corso (pendente).
  /// Mostra il ProductDetailCard in modalità skeleton con il notifier
  /// condiviso con la scansione in background.
  void _navigateToPendingProduct(String barcode) async {
    setState(() => _navController.setCameraActive(false));
    if (!mounted) return;

    final pendingNotifier = _pendingScans[barcode]!;

    // Riusa il notifier pendente come openProductNotifier per questa sessione.
    _openProductNotifiers[barcode] = pendingNotifier;

    final placeholderProduct = Product(
      barcode: barcode,
      nameMap: const {'it': 'Caricamento prodotto...'},
      brandMap: const {'it': 'Analisi in corso'},
      ingredientsMap: const {'it': 'Analisi degli ingredienti in corso...'},
      allergensMap: const {'it': <String>[]},
      lastUpdated: DateTime.now().toIso8601String(),
      pendingReportsCount: 0,
    );

    final userReport = reports.cast<ProductReport?>().firstWhere(
      (r) => r?.barcode == barcode && r?.userId == userId,
      orElse: () => null,
    );

    final reportIdNotifier = _openReportIdNotifiers.putIfAbsent(
      barcode,
      () => ValueNotifier<String?>(userReport?.id),
    );
    reportIdNotifier.value = userReport?.id;

    final isInHistoryNotifier = ValueNotifier<bool>(
      history.any((h) => h.barcode == barcode),
    );

    final isStaleDataNotifier = ValueNotifier<bool>(false);

    final historyItem = history.cast<ScanHistoryItem?>().firstWhere(
      (h) => h?.barcode == barcode,
      orElse: () => null,
    );

    final route = MaterialPageRoute(
      builder: (context) => ProductDetailCard(
        product: placeholderProduct,
        productNotifier: pendingNotifier,
        reportIdNotifier: reportIdNotifier,
        isInHistoryNotifier: isInHistoryNotifier,
        isStaleDataNotifier: isStaleDataNotifier,
        isLoading: true,
        scannedAt: historyItem?.scannedAt ?? DateTime.now().toIso8601String(),
        onBack: () => Navigator.pop(context),
        onReportSubmit: handleReportSubmit,
        onProductUpdate: handleProductUpdate,
        userSettings: userSettings,
        onDeleteHistoryByBarcode: handleDeleteHistoryByBarcode,
        hasReportedThisSession:
            reportedSessionBarcodes.contains(barcode) || userReport != null,
        userReportId: userReport?.id,
        onDeleteReport: handleDeleteReport,
        onViewReport: (loadedProduct) =>
            _openReportDetail(context, loadedProduct),
        onRefreshOnline: _refreshProductOnline,
      ),
    );

      _pendingDetailClosers[barcode] = () {
        if (route.isActive) {
          route.navigator?.pop();
        }
      };

      final isWideScreen = MediaQuery.of(context).size.width > 960;
      final Future<void> pushFuture;
      if (isWideScreen) {
        pushFuture =
            _contentNavigatorKey.currentState?.push(route) ?? Future.value();
      } else {
        pushFuture = Navigator.push(context, route);
      }

      await pushFuture;
      _pendingDetailClosers.remove(barcode);
      _openProductNotifiers.remove(barcode);
    _openReportIdNotifiers.remove(barcode);
    isInHistoryNotifier.dispose();
    isStaleDataNotifier.dispose();

    if (mounted) {
      setState(() => _navController.setCameraActive(true));
    }
  }

  void _openReportDetail(BuildContext context, Product loadedProduct) {
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
    final String rDate =
        reportOfProduct != null ? reportOfProduct.submittedAt : "";

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
  }

  void _onTabSelected(int index) {
    _navController.selectTab(index);
  }

  Widget _buildBody() {
    return MainIndexedStack(
      currentIndex: _currentIndex,
      children: [
        CameraModule(
          isActive: _isCameraActive && _currentIndex == 0,
          onScanSuccess: handleScanSuccess,
          scanningProgress: scanningProgress,
          scanError: scanError,
        ),
        HistoryList(
          history: [
            ..._pendingHistoryItems.values,
            ...history.where(
              (h) => !_pendingHistoryItems.containsKey(h.barcode),
            ),
          ],
          liveProducts: products,
          pendingBarcodes: _pendingScans.keys.toSet(),
          onRefresh: refreshAllData,
          userSettings: userSettings,
          isSynced: _isHistorySynced,
          onSelectItem: (barcode) {
            // Se è una scansione pendente (ancora in caricamento), naviga
            // direttamente alla skeleton view con il notifier condiviso.
            if (_pendingScans.containsKey(barcode)) {
              _navigateToPendingProduct(barcode);
              return;
            }
            final match = products.cast<Product?>().firstWhere(
              (p) => p?.barcode == barcode,
              orElse: () => null,
            );
            if (match != null) {
              _navigateToProduct(match);
            } else {
              handleScanSuccess(barcode);
            }
          },
          onClearHistory: handleClearHistory,
          onDeleteHistoryItem: handleDeleteHistoryItem,
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
              _navController.resetToScanner();
            });
          },
          onClearHistory: handleClearHistory,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_requiresSyncDecision) {
      return Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: SyncDataScreen(
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
          : MainCustomBottomNav(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
            ),
    );

    if (isWideScreen) {
      return MainDesktopNavigationRail(
        currentIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        contentNavigatorKey: _contentNavigatorKey,
        child: scaffold,
      );
    }

    return ResponsiveMaxCardWidth(maxWidth: 500, child: scaffold);
  }
}
