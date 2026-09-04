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
import 'package:gscanner/core/theme/theme.dart';
import 'package:gscanner/core/utils/responsive_wrapper.dart';

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

  GlobalKey<NavigatorState> get _contentNavigatorKey =>
      _navController.contentNavigatorKey;
  Map<String, ValueNotifier<Product?>> get _openProductNotifiers =>
      _navController.openProductNotifiers;
  Map<String, ValueNotifier<String?>> get _openReportIdNotifiers =>
      _navController.openReportIdNotifiers;

  bool _requiresSyncDecision = false;
  int _anonymousHistoryCount = 0;

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
              _anonymousHistoryCount =
                  localHistory.length + localReports.length;
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

  Future<void> handleScanSuccess(String barcode) async {
    setState(() {
      scanningProgress = true;
      scanError = null;
      _navController.setCameraActive(false);
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
          setState(() => _navController.setCameraActive(true));
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
    await DbService.deleteHistoryByBarcodeLocal(barcode);
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
            content: Text('product.deleteReport.errorMessage'.tr()),
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
    await _loadLocalReports();
  }

  void _navigateToProduct(Product match) async {
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
      setState(() => _navController.setCameraActive(true));
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
              _navController.resetToScanner();
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

  @override
  Widget build(BuildContext context) {
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
