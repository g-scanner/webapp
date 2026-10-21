// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:gscanner/models/models.dart';
import 'package:gscanner/services/analyzer_service.dart';
import 'package:gscanner/services/db_service.dart';
import 'package:gscanner/services/database/background_sync_manager.dart';
import 'package:gscanner/core/core.dart';

import 'package:gscanner/features/scanner/camera_module.dart';
import 'package:gscanner/features/history/history_list.dart';
import 'package:gscanner/features/reports/reports_list.dart';
import 'package:gscanner/features/settings/settings_panel.dart';
import 'package:gscanner/features/product_detail/product_detail_card.dart';
import 'package:gscanner/features/reports/report_detail_card.dart';

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

  /// Set dei barcode annullati o falliti per evitare che Future asincroni tardivi salvino dati.
  final Set<String> _cancelledBarcodes = {};

  /// Timer periodico per la verifica automatica in background dei prodotti scansionati offline
  /// non appena torna la connessione Internet.
  Timer? _offlineVerificationTimer;
  bool _isVerifyingOfflineProducts = false;

  GlobalKey<NavigatorState> get _contentNavigatorKey =>
      _navController.contentNavigatorKey;
  Map<String, ValueNotifier<Product?>> get _openProductNotifiers =>
      _navController.openProductNotifiers;
  Map<String, ValueNotifier<String?>> get _openReportIdNotifiers =>
      _navController.openReportIdNotifiers;
  Map<String, ValueNotifier<bool>> get _openStaleNotifiers =>
      _navController.openStaleNotifiers;
  Map<String, ValueNotifier<bool>> get _openOfflineDbNotifiers =>
      _navController.openOfflineDbNotifiers;

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
    _offlineVerificationTimer?.cancel();
    _offlineVerificationTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    _navController.removeListener(_onNavigationChanged);
    _navController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Il ciclo di vita della fotocamera viene ora gestito reattivamente
    // in CameraModule tramite ScannerStateManager.
    if (state == AppLifecycleState.resumed) {
      _startOfflineVerificationTimerIfNeeded();
      _autoDownloadOfflineDbIfNeeded(userSettings);
    }
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

        if (user.isAnonymous) {
          // Traccia l'UID anonimo corrente per confronti futuri
          // (la decisione di sync/wipe è gestita da MyApp prima del mount)
          await DbService.trackAnonymousSession(user.uid);
        }
      }

      await _loadAllLocalData();
      _syncEverythingWithFirestore();
    } catch (e) {
      debugPrint("Inizializzazione fallita: $e");
    }
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
      _startOfflineVerificationTimerIfNeeded();
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
        final reportBarcodes = localData
            .map((r) => r.barcode)
            .where((b) => b.isNotEmpty)
            .toSet();
        final currentBarcodes = userSettings.reportedBarcodes.toSet();
        if (!currentBarcodes.containsAll(reportBarcodes)) {
          final merged = {...currentBarcodes, ...reportBarcodes}.toList();
          userSettings = userSettings.copyWith(
            userId: userSettings.userId ?? userId,
            reportedBarcodes: merged,
          );
          DbService.saveLocalSettings(userSettings);
        }
      });
    }
  }

  Future<void> _loadLocalSettings() async {
    final data = await DbService.getLocalSettings();
    themeNotifier.value = themeModeFromString(data.preferredTheme);
    if (mounted) {
      setState(() => userSettings = data);
      context.setLocale(Locale(data.preferredLanguage));
      _autoDownloadOfflineDbIfNeeded(data);
      BackgroundSyncManager.updatePeriodicTaskRegistration(data);
    }
  }

  void _autoDownloadOfflineDbIfNeeded(UserSettings currentSettings) {
    OfflineDbSyncService.autoDownloadIfNeeded(
      settings: currentSettings,
      onSettingsChange: (updatedSettings) async {
        final bool hadActualUpdate =
            currentSettings.offlineDbLastSyncedAt !=
            updatedSettings.offlineDbLastSyncedAt;
        if (mounted) {
          setState(() => userSettings = updatedSettings);
          if (hadActualUpdate) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('settings.offlineDatabase.autoSyncSuccess'.tr()),
                backgroundColor: context.colorScheme.primary,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
        await DbService.saveSettings(updatedSettings);
      },
    );
  }

  void _syncEverythingWithFirestore() {
    DbService.performDeltaSync()
        .then((_) async {
          final updated = await DbService.getLocalProducts();
          if (mounted) {
            setState(() => products = updated);
            _startOfflineVerificationTimerIfNeeded();
          }
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
          if (mounted) {
            setState(() => userSettings = syncedSettings);
            themeNotifier.value = themeModeFromString(syncedSettings.preferredTheme);
            if (context.locale.languageCode != syncedSettings.preferredLanguage) {
              context.setLocale(Locale(syncedSettings.preferredLanguage));
            }
            _autoDownloadOfflineDbIfNeeded(syncedSettings);
          }
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
            _resolveMissingProductsForHistory();
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
          final isOfflineActive =
              _openOfflineDbNotifiers[barcode]?.value ?? false;
          final currentOpenProduct = _openProductNotifiers[barcode]?.value;
          final prod = products.cast<Product?>().firstWhere(
            (p) => p?.barcode == barcode,
            orElse: () => null,
          );
          if (prod != null) {
            if ((isOfflineActive ||
                    (currentOpenProduct?.isFromOfflineDb ?? false)) &&
                (prod.isFromOfflineDb ||
                    prod.needsVerification ||
                    prod.isOfflineNotFound)) {
              continue;
            }
            _openProductNotifiers[barcode]!.value = prod;
            _openOfflineDbNotifiers[barcode]?.value =
                prod.isFromOfflineDb || prod.isOfflineNotFound;
            _openStaleNotifiers[barcode]?.value = prod.isStale;
          }
        }
      });
      _startOfflineVerificationTimerIfNeeded();
    }
    DbService.performDeltaSync()
        .then((_) async {
          final updated = await DbService.getLocalProducts();
          if (mounted) {
            setState(() {
              products = updated;
              for (var barcode in _openProductNotifiers.keys) {
                final isOfflineActive =
                    _openOfflineDbNotifiers[barcode]?.value ?? false;
                final currentOpenProduct =
                    _openProductNotifiers[barcode]?.value;
                final prod = updated.cast<Product?>().firstWhere(
                  (p) => p?.barcode == barcode,
                  orElse: () => null,
                );
                if (prod != null) {
                  if ((isOfflineActive ||
                          (currentOpenProduct?.isFromOfflineDb ?? false)) &&
                      (prod.isFromOfflineDb ||
                          prod.needsVerification ||
                          prod.isOfflineNotFound)) {
                    continue;
                  }
                  _openProductNotifiers[barcode]!.value = prod;
                  _openOfflineDbNotifiers[barcode]?.value =
                      prod.isFromOfflineDb || prod.isOfflineNotFound;
                  _openStaleNotifiers[barcode]?.value = prod.isStale;
                }
              }
            });
            _startOfflineVerificationTimerIfNeeded();
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
    _startOfflineVerificationTimerIfNeeded();
    _resolveMissingProductsForHistory();
  }

  Future<bool> handleScanSuccess(String barcode) async {
    // Se è già in corso una scansione per questo barcode, deduplica ed evita scan concorrenti
    if (_pendingScans.containsKey(barcode)) {
      return false;
    }

    _cancelledBarcodes.remove(barcode);

    // 0. Fail-fast immediato se offline e nessun DB disponibile (né cache locale né DB offline):
    // Se siamo offline e il prodotto non è già memorizzato localmente e non abbiamo il DB offline installato,
    // abortiamo subito senza aprire lo skeleton e senza creare elementi orfani in cronologia.
    final localProduct = await LocalCacheService.getLocalProductByBarcode(
      barcode,
    );
    final isConnected = await ConnectivityHelper.hasInternetConnection();
    final hasOfflineDb = await OfflineDbService.isDatabaseInstalled();
    if (localProduct == null && !isConnected && !hasOfflineDb) {
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

    final isStaleDataNotifier = _openStaleNotifiers.putIfAbsent(
      barcode,
      () => ValueNotifier<bool>(false),
    );
    isStaleDataNotifier.value = false;

    final isOfflineDbNotifier = _openOfflineDbNotifiers.putIfAbsent(
      barcode,
      () => ValueNotifier<bool>(false),
    );
    isOfflineDbNotifier.value = false;

    Future<void>? pushFuture;

    if (mounted) {
      final userReport = reports.cast<ProductReport?>().firstWhere(
        (r) => r?.barcode == barcode && (userId == null || r?.userId == userId),
        orElse: () => null,
      );

      final reportIdNotifier = _openReportIdNotifiers.putIfAbsent(
        barcode,
        () => ValueNotifier<String?>(userReport?.id),
      );
      reportIdNotifier.value = userReport?.id;

      final isWideScreen = MediaQuery.of(context).size.width > 960;
      final route = MaterialPageRoute(
        builder: (context) => ProductDetailCard(
          product: placeholderProduct,
          productNotifier: productNotifier,
          reportIdNotifier: reportIdNotifier,
          isInHistoryNotifier: isInHistoryNotifier,
          isStaleDataNotifier: isStaleDataNotifier,
          isOfflineDbNotifier: isOfflineDbNotifier,
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
          useResponsiveWrapper: !isWideScreen,
        ),
      );

      _pendingDetailClosers[barcode] = () {
        if (route.isActive) {
          route.navigator?.pop();
        }
      };

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
        _openStaleNotifiers.remove(barcode)?.dispose();
        _openOfflineDbNotifiers.remove(barcode)?.dispose();
      }
    }

    final scanFuture = () async {
      final scanStartTime = DateTime.now();
      const maxScanDuration = Duration(seconds: 28);
      const retryDelay = Duration(seconds: 4);
      int scanRetries = 0;
      const maxScanRetries =
          2; // 2 retry (3 tentativi totali: iniziale + 2 retry)

      try {
        ScanResult? scanResult;

        while (true) {
          final elapsed = DateTime.now().difference(scanStartTime);
          if (elapsed >= maxScanDuration ||
              _cancelledBarcodes.contains(barcode)) {
            throw const OffNetworkException();
          }

          try {
            scanResult = await DbService.scanBarcodeClientSide(
              barcode,
              userSettings,
            );
            break; // Scansione completata con successo!
          } on OfflineWithoutDbException catch (_) {
            rethrow;
          } on OffNetworkException catch (_) {
            final hasNet = await ConnectivityHelper.hasInternetConnection();
            if (!hasNet) {
              rethrow;
            }
            scanRetries++;
            final currentElapsed = DateTime.now().difference(scanStartTime);
            if (scanRetries > maxScanRetries ||
                currentElapsed >= maxScanDuration ||
                !mounted) {
              rethrow;
            }
            await Future.delayed(retryDelay);
          } catch (_) {
            rethrow;
          }
        }

        // Se nel frattempo la scansione era stata annullata o è fallita, scarta il risultato:
        if (_cancelledBarcodes.contains(barcode)) {
          return;
        }

        if (!detailClosed) {
          isStaleDataNotifier.value = scanResult.isStaleResult;
          isOfflineDbNotifier.value =
              scanResult.isOfflineResult || scanResult.isOfflineNotFoundResult;
          isInHistoryNotifier.value = true;
        }
        productNotifier.value = scanResult.product;
        await _loadLocalHistory();
        _fetchProducts();
        if (scanResult.product.needsVerification) {
          _startOfflineVerificationTimerIfNeeded();
        }

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
          setState(() => scanningProgress = _pendingScans.isNotEmpty);
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
      _openStaleNotifiers.remove(barcode)?.dispose();
      _openOfflineDbNotifiers.remove(barcode)?.dispose();
      if (mounted) {
        setState(() {
          scanningProgress = _pendingScans.isNotEmpty;
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
    _cancelledBarcodes.add(barcode);

    // 1. Rimuovi IMMEDIATAMENTE dalle strutture in memoria per aggiornare la UI
    _pendingScans.remove(barcode);
    _pendingHistoryItems.remove(barcode);

    // 2. Chiudi IMMEDIATAMENTE la route se aperta
    final closer = _pendingDetailClosers.remove(barcode);
    if (closer != null) {
      closer();
    }

    // 3. Mostra la notifica di fallimento
    if (mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              closer != null
                  ? localizationKey.tr()
                  : 'scanner.result.backgroundScanFailed'.tr(),
            ),
          ),
        );
      }
    }

    // 4. AGGIORNA SUBITO LA UI: la card skeleton scompare all'istante
    if (mounted) {
      setState(() {
        scanningProgress = _pendingScans.isNotEmpty;
      });
    }

    // 5. Pulizia asincrona protetta da timeout per non bloccare
    try {
      await DbService.deleteHistoryByBarcodeLocal(barcode).timeout(
        const Duration(seconds: 3),
        onTimeout: () =>
            debugPrint("Firestore history delete timeout (offline)"),
      );
    } catch (e) {
      debugPrint("Errore rimozione history item fallito: $e");
    }
    await _loadLocalHistory();

    if (mounted) {
      setState(() {});
    }
  }

  /// Effettua il refresh asincrono applicando l'architettura a 3 livelli:
  /// controlla prima Firestore (`products/{barcode}`) verificandone la freschezza (Super Fresh, Tolleranza, Stale)
  /// e solo se mancante o stale interroga Open Food Facts.
  Future<void> _refreshProductOnline(String barcode) async {
    try {
      final updatedProduct = await DbService.resolveProductOnline(
        barcode,
        userSettings,
        onBackgroundRefreshed: (freshProduct) {
          if (!mounted) return;
          setState(() {
            final idx = products.indexWhere((p) => p.barcode == barcode);
            if (idx != -1) {
              products[idx] = freshProduct;
            }
          });
          if (_openProductNotifiers.containsKey(barcode)) {
            _openProductNotifiers[barcode]!.value = freshProduct;
          }
        },
      );

      if (updatedProduct != null) {
        if (mounted) {
          setState(() {
            final idx = products.indexWhere((p) => p.barcode == barcode);
            if (idx != -1) {
              products[idx] = updatedProduct;
            } else {
              products.add(updatedProduct);
            }
          });
        }
        if (_openProductNotifiers.containsKey(barcode)) {
          _openProductNotifiers[barcode]!.value = updatedProduct;
        }
        if (_openStaleNotifiers.containsKey(barcode)) {
          _openStaleNotifiers[barcode]!.value = false;
        }
        if (_openOfflineDbNotifiers.containsKey(barcode)) {
          _openOfflineDbNotifiers[barcode]!.value = false;
        }
        _fetchProducts();
      }
    } catch (e) {
      debugPrint("Errore durante il refresh online del prodotto: $e");
    }
  }

  /// Avvia, se necessario, il timer di polling per verificare i prodotti scansionati
  /// offline non appena la connessione a Internet viene ripristinata.
  void _startOfflineVerificationTimerIfNeeded() {
    final hasPending = products.any((p) => p.needsVerification);
    if (!hasPending) {
      _offlineVerificationTimer?.cancel();
      _offlineVerificationTimer = null;
      return;
    }

    if (_offlineVerificationTimer != null &&
        _offlineVerificationTimer!.isActive) {
      _verifyPendingOfflineProducts();
      return;
    }

    _offlineVerificationTimer?.cancel();
    _verifyPendingOfflineProducts();
    _offlineVerificationTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (!mounted) {
          _offlineVerificationTimer?.cancel();
          _offlineVerificationTimer = null;
          return;
        }
        final stillPending = products.any((p) => p.needsVerification);
        if (!stillPending) {
          _offlineVerificationTimer?.cancel();
          _offlineVerificationTimer = null;
          return;
        }
        _verifyPendingOfflineProducts();
      },
    );
  }

  /// Esegue la verifica online da Open Food Facts per tutti i prodotti in sospeso (needsVerification: true).
  /// Aggiorna in-place la cache locale e la lista in memoria, facendo sparire il badge offline.
  Future<void> _verifyPendingOfflineProducts() async {
    if (_isVerifyingOfflineProducts || !mounted) return;
    try {
      final isOnline = await ConnectivityHelper.hasInternetConnection();
      if (!isOnline || !mounted) return;

      final unverified = products.where((p) => p.needsVerification).toList();
      if (unverified.isEmpty) {
        _offlineVerificationTimer?.cancel();
        _offlineVerificationTimer = null;
        return;
      }

      _isVerifyingOfflineProducts = true;
      for (final p in unverified) {
        if (!mounted) break;
        await _refreshProductOnline(p.barcode);
      }
    } catch (e) {
      debugPrint("Verifica offline prodotti fallita: $e");
    } finally {
      if (mounted) {
        _isVerifyingOfflineProducts = false;
        final stillPending = products.any((p) => p.needsVerification);
        if (!stillPending) {
          _offlineVerificationTimer?.cancel();
          _offlineVerificationTimer = null;
        }
      }
    }
  }

  bool _isResolvingHistoryProducts = false;

  /// Risolve automaticamente i prodotti mancanti per tutte le voci di cronologia sincronizzate.
  /// Cerca prima in cache SQLite, poi su Firestore per recuperare i dati verificati completi.
  Future<void> _resolveMissingProductsForHistory() async {
    if (_isResolvingHistoryProducts || !mounted) return;
    _isResolvingHistoryProducts = true;
    try {
      final missingBarcodes = history
          .map((h) => h.barcode)
          .where((b) => b.isNotEmpty && !products.any((p) => p.barcode == b))
          .toSet();

      if (missingBarcodes.isEmpty) return;

      final hasOfflineDb = await OfflineDbService.isDatabaseInstalled();

      final List<Product> newlyFound = [];
      for (final barcode in missingBarcodes) {
        if (!mounted) break;
        // 1. Cerca in SQLite
        var prod = await DbService.getLocalProductByBarcode(barcode);
        // 2. Se non presente in SQLite, cerca su Firestore
        prod ??= await DbService.getProductByBarcode(barcode);
        // 3. Fallback sul database offline locale se installato
        if (prod == null && hasOfflineDb) {
          prod = await OfflineDbService.searchProduct(barcode);
          if (prod != null) {
            await DbService.upsertLocalProduct(prod);
          }
        }
        if (prod != null) {
          newlyFound.add(prod);
        }
      }

      if (newlyFound.isNotEmpty && mounted) {
        setState(() {
          for (final p in newlyFound) {
            final idx =
                products.indexWhere((existing) => existing.barcode == p.barcode);
            if (idx != -1) {
              products[idx] = p;
            } else {
              products.add(p);
            }
          }
        });
        if (newlyFound.any((p) => p.needsVerification)) {
          _startOfflineVerificationTimerIfNeeded();
        }
      }
    } catch (e) {
      debugPrint("Errore durante la risoluzione dei prodotti di cronologia: $e");
    } finally {
      if (mounted) {
        _isResolvingHistoryProducts = false;
      }
    }
  }

  /// Apre la schermata di dettaglio di un prodotto esistente dalla cronologia o dalle segnalazioni
  /// SENZA registrare un nuovo evento di scansione (nessuna duplicazione in cronologia!).
  Future<void> _openHistoryProduct(String barcode) async {
    // 1. Se è una scansione pendente (ancora in caricamento), naviga
    // direttamente alla skeleton view con il notifier condiviso.
    if (_pendingScans.containsKey(barcode)) {
      _navigateToPendingProduct(barcode);
      return;
    }

    // 2. Cerca nella lista in memoria dei prodotti
    Product? match = products.cast<Product?>().firstWhere(
      (p) => p?.barcode == barcode,
      orElse: () => null,
    );

    // 3. Se non in memoria, cerca nel database locale SQLite (cache)
    match ??= await DbService.getLocalProductByBarcode(barcode);

    // 4. Se ancora non presente localmente, cerca su Firestore
    match ??= await DbService.getProductByBarcode(barcode);

    // 5. Se ancora non trovato, cerca nel DB offline se installato
    if (match == null && await OfflineDbService.isDatabaseInstalled()) {
      match = await OfflineDbService.searchProduct(barcode);
      if (match != null) {
        await DbService.upsertLocalProduct(match);
      }
    }

    // 6. Se ancora non trovato (es. record cronologico di prodotto sconosciuto):
    // Crea un prodotto provvisorio locale contrassegnato con needsVerification: true.
    // MAI inviare a Firestore e MAI invocare saveHistoryItem!
    if (match == null) {
      match = OfflineDbService.createOfflineNotFoundProduct(barcode);
      await DbService.upsertLocalProduct(match);
    }

    if (mounted) {
      setState(() {
        if (!products.any((p) => p.barcode == barcode)) {
          products.add(match!);
        }
      });
    }

    // 6. Naviga alla schermata di dettaglio del prodotto ESISTENTE
    // (ProductDetailCard gestirà reattivamente il refresh online se e quando la rete è attiva)
    if (match.needsVerification) {
      _startOfflineVerificationTimerIfNeeded();
    }
    _navigateToProduct(match);
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
      final Product updatedProd;
      if (pIdx != -1) {
        final p = products[pIdx];
        updatedProd = Product(
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
        products[pIdx] = updatedProd;
        if (_openProductNotifiers.containsKey(barcode)) {
          _openProductNotifiers[barcode]!.value = updatedProd;
        }
      } else {
        updatedProd = Product(
          barcode: barcode,
          nameMap: product.nameMap,
          brandMap: product.brandMap,
          ingredientsMap: product.ingredientsMap,
          allergensMap: product.allergensMap,
          lastUpdated: DateTime.now().toIso8601String(),
          pendingReportsCount: 1,
        );
        products.add(updatedProd);
      }
      await DbService.upsertLocalProduct(updatedProd);

      setState(() {
        reportedSessionBarcodes.add(barcode);
        if (!userSettings.reportedBarcodes.contains(barcode)) {
          userSettings = userSettings.copyWith(
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
    // 1. Aggiornamento ottimistico immediato in UI (0 ms)
    if (mounted) {
      setState(() {
        history.removeWhere((item) => item.barcode == barcode);
      });
    }

    // 2. Persistenza locale SQLite & tombstone + sync remoto asincrono
    try {
      await DbService.deleteHistoryByBarcodeLocal(barcode);
    } catch (e) {
      debugPrint("Error deleting history by barcode: $e");
    }
    await _loadLocalHistory();
  }

  Future<void> handleDeleteHistoryItem(String id) async {
    if (id.startsWith('pending_')) {
      final barcode = id.substring('pending_'.length);
      _cancelledBarcodes.add(barcode);
      _pendingScans.remove(barcode);
      _pendingHistoryItems.remove(barcode);
      _pendingDetailClosers.remove(barcode);
      if (mounted) {
        setState(() {
          scanningProgress = _pendingScans.isNotEmpty;
        });
      }
      return;
    }

    // 1. Aggiornamento ottimistico immediato in UI (0 ms)
    if (mounted) {
      setState(() {
        history.removeWhere((item) => item.id == id);
      });
    }

    // 2. Persistenza locale SQLite & tombstone + sync remoto asincrono
    try {
      await DbService.deleteHistoryItemLocal(id);
    } catch (e) {
      debugPrint("Error deleting history item: $e");
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
    String? barcode = report?.barcode;
    if (barcode == null) {
      for (final entry in _openReportIdNotifiers.entries) {
        if (entry.value.value == reportId) {
          barcode = entry.key;
          break;
        }
      }
    }

    // 1. Aggiornamento ottimistico immediato in UI (0 ms)
    if (mounted) {
      setState(() {
        reports.removeWhere((r) => r.id == reportId);

        if (barcode != null) {
          reportedSessionBarcodes.remove(barcode);

          final pIdx = products.indexWhere((p) => p.barcode == barcode);
          if (pIdx != -1) {
            final p = products[pIdx];
            final updatedProd = Product(
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
            products[pIdx] = updatedProd;
            DbService.upsertLocalProduct(updatedProd);
            if (_openProductNotifiers.containsKey(barcode)) {
              _openProductNotifiers[barcode]!.value = updatedProd;
            }
            if (_openReportIdNotifiers.containsKey(barcode)) {
              _openReportIdNotifiers[barcode]!.value = null;
            }
          }

          final updatedBarcodes = List<String>.from(userSettings.reportedBarcodes)
            ..remove(barcode);
          userSettings = userSettings.copyWith(
            userId: userSettings.userId ?? userId,
            reportedBarcodes: updatedBarcodes,
          );
        }
      });
    }

    // 2. Persistenza locale SQLite & tombstone + sync cloud asincrono
    try {
      await DbService.deleteLocalReport(reportId);
      DbService.deleteReportFromDb(reportId);
      DbService.saveLocalSettings(userSettings);
      DbService.saveSettings(userSettings);
    } catch (e) {
      debugPrint("Error deleting report: $e");
    }
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
      (r) =>
          r?.barcode == match.barcode &&
          (userId == null || r?.userId == userId),
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

    // Determina se il prodotto proviene dal DB offline locale.
    // Viene verificato sia il flag del modello che l'eventuale presenza nel DB offline
    // quando il dispositivo è offline o il prodotto non è stato sincronizzato online.
    bool isFromOffline = match.isFromOfflineDb || match.isOfflineNotFound;
    if (!isFromOffline) {
      final isConnected = await ConnectivityHelper.hasInternetConnection();
      if (!isConnected && await OfflineDbService.isDatabaseInstalled()) {
        final offlineCheck = await OfflineDbService.searchProduct(
          match.barcode,
        );
        if (offlineCheck != null) {
          isFromOffline = true;
          // Se il prodotto in cache locale era stale (>30gg), prediligi il record del DB offline!
          if (match.isStale) {
            match = offlineCheck;
            await DbService.upsertLocalProduct(match);
            notifier.value = match;
          }
        }
      }
    }

    // Crea il notifier reattivo per lo stato stale, inizializzato dal valore corrente.
    // Viene passato al ProductDetailCard così che _onProductNotifierChanged
    // possa azzerarlo quando il prodotto viene rinfrescato da delta sync o background check.
    final staleNotifier = _openStaleNotifiers.putIfAbsent(
      match.barcode,
      () => ValueNotifier<bool>(match.isStale && !isFromOffline),
    );
    staleNotifier.value = match.isStale && !isFromOffline;

    if (!mounted) return;

    final offlineDbNotifier = _openOfflineDbNotifiers.putIfAbsent(
      match.barcode,
      () => ValueNotifier<bool>(isFromOffline),
    );
    offlineDbNotifier.value = isFromOffline;

    final historyItem = history.cast<ScanHistoryItem?>().firstWhere(
      (h) => h?.barcode == match.barcode,
      orElse: () => null,
    );

    final isWideScreen = MediaQuery.of(context).size.width > 960;
    final route = MaterialPageRoute(
      builder: (context) => ProductDetailCard(
        product: match,
        productNotifier: notifier,
        reportIdNotifier: reportIdNotifier,
        isStaleDataNotifier: staleNotifier,
        isOfflineDbNotifier: offlineDbNotifier,
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
        useResponsiveWrapper: !isWideScreen,
      ),
    );

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
    _openOfflineDbNotifiers.remove(match.barcode)?.dispose();

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
      (r) => r?.barcode == barcode && (userId == null || r?.userId == userId),
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

    final isStaleDataNotifier = _openStaleNotifiers.putIfAbsent(
      barcode,
      () => ValueNotifier<bool>(false),
    );
    isStaleDataNotifier.value = false;
    final offlineDbNotifier = _openOfflineDbNotifiers.putIfAbsent(
      barcode,
      () => ValueNotifier<bool>(false),
    );

    final historyItem = history.cast<ScanHistoryItem?>().firstWhere(
      (h) => h?.barcode == barcode,
      orElse: () => null,
    );

    final isWideScreen = MediaQuery.of(context).size.width > 960;
    final route = MaterialPageRoute(
      builder: (context) => ProductDetailCard(
        product: placeholderProduct,
        productNotifier: pendingNotifier,
        reportIdNotifier: reportIdNotifier,
        isInHistoryNotifier: isInHistoryNotifier,
        isStaleDataNotifier: isStaleDataNotifier,
        isOfflineDbNotifier: offlineDbNotifier,
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
        useResponsiveWrapper: !isWideScreen,
      ),
    );

    _pendingDetailClosers[barcode] = () {
      if (route.isActive) {
        route.navigator?.pop();
      }
    };

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
    _openStaleNotifiers.remove(barcode)?.dispose();
    _openOfflineDbNotifiers.remove(barcode)?.dispose();
    isInHistoryNotifier.dispose();

    if (mounted) {
      setState(() => _navController.setCameraActive(true));
    }
  }

  void _openReportDetail(BuildContext context, Product loadedProduct) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 960;
    final reportOfProduct = reports.cast<ProductReport?>().firstWhere(
      (r) =>
          r?.barcode == loadedProduct.barcode &&
          (userId == null || r?.userId == userId),
      orElse: () => null,
    );
    final bool isOwn =
        reportedSessionBarcodes.contains(loadedProduct.barcode) ||
        reportOfProduct != null;
    final String comment = reportOfProduct?.comments ?? '';
    final String rDate = reportOfProduct != null
        ? reportOfProduct.submittedAt
        : "";

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
          await DbService.voteOnReportByBarcode(loadedProduct.barcode, vote);
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
          onSelectItem: _openHistoryProduct,
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
          onSelectItem: _openHistoryProduct,
        ),
        SettingsPanel(
          firebaseAuth: _auth,
          settings: userSettings,
          onSettingsChange: (newSet) async {
            setState(() => userSettings = newSet);
            themeNotifier.value = themeModeFromString(newSet.preferredTheme);
            await DbService.saveSettings(newSet);
            await BackgroundSyncManager.updatePeriodicTaskRegistration(newSet);
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
