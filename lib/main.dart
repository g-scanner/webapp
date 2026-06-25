import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/types.dart';
import 'services/db_service.dart';

import 'widgets/camera_module.dart';
import 'widgets/history_list.dart';
import 'widgets/database_products.dart';
import 'widgets/settings_panel.dart';
import 'widgets/my_reports_list.dart';
import 'widgets/product_detail_card.dart';

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
      home: const MainScreen(),
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

  List<Product> products = [];
  List<ScanHistoryItem> history = [];
  List<ProductReport> reports = [];
  UserSettings userSettings = UserSettings(
    strictMode: false,
    alertLactose: false,
    warnAdditives: true,
    autoSaveHistory: true,
    preferredLanguage: "it",
  );

  String? userId;
  Product? selectedProduct;
  List<String> reportedSessionBarcodes = [];
  bool scanningProgress = false;
  String? scanError;
  bool loadingApp = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // 1. Effettua/Recupera il login in modo sicuro
      final userCred = await FirebaseAuth.instance.signInAnonymously();
      if (mounted) {
        setState(() {
          userId = userCred.user?.uid;
        });
      }

      // 2. Scarica i dati SOLO ORA che sei certo che auth.currentUser esista
      // e il database non verrà interrogato due volte
      await Future.wait([
        _fetchProducts(),
        _fetchHistory(),
        _fetchReports(),
        _fetchSettings(),
      ]);

      // 3. Listener passivo per futuri cambi di utenza (senza far scattare chiamate duplicate all'avvio)
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (mounted) {
          setState(() {
            userId = user?.uid;
          });
        }
      });
    } catch (e) {
      print("Inizializzazione fallita: $e");
    } finally {
      if (mounted) {
        setState(() {
          loadingApp = false;
        });
      }
    }
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
    final data = await DbService.getLocalSettings();
    if (mounted) setState(() => userSettings = data);
  }

  Future<void> refreshAllData() async {
    // Il RefreshIndicator richiede un Future per capire quando far sparire la rotellina
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
      setState(() {
        selectedProduct = product;
      });
      _fetchHistory();
      _fetchProducts();
    } catch (e) {
      setState(() {
        scanError = "Errore di analisi o connessione con il database celiaci.";
      });
    } finally {
      setState(() {
        scanningProgress = false;
      });
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
        if (selectedProduct?.barcode == barcode) {
          selectedProduct = Product(
            barcode: selectedProduct!.barcode,
            name: selectedProduct!.name,
            brand: selectedProduct!.brand,
            ingredients: selectedProduct!.ingredients,
            allergens: selectedProduct!.allergens,
            status: GlutenSafetyStatus.incerto,
            reason:
                "ATTENZIONE: Segnalata etichetta incongruente o obsoleta dagli utenti. Note: ${reportData['comments']}",
            ingredientsAnalyzed: selectedProduct!.ingredientsAnalyzed,
            imageUrl: selectedProduct!.imageUrl,
            lastUpdated: selectedProduct!.lastUpdated,
            reportCount: selectedProduct!.reportCount,
          );
        }
      });

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
      setState(() {
        selectedProduct = finalProduct;
      });
      await _fetchProducts();
    } catch (e) {
      print("Aggiornamento fallito: $e");
    }
  }

  Future<void> handleDeleteHistoryByBarcode(String barcode) async {
    await DbService.deleteHistoryByBarcodeLocal(barcode);
    setState(() {
      selectedProduct = null;
    });
    await _fetchHistory();
  }

  Future<void> handleDeleteReport(String reportId) async {
    await DbService.deleteReportFromDb(reportId);
    setState(() {
      reportedSessionBarcodes.removeWhere((b) => selectedProduct?.barcode == b);
      selectedProduct = null;
    });
    await _fetchReports();
    await _fetchProducts();
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

    if (selectedProduct != null) {
      final userReport = reports.cast<ProductReport?>().firstWhere(
        (r) => r?.barcode == selectedProduct!.barcode && r?.userId == userId,
        orElse: () => null,
      );
      final isInHistory = history.any(
        (h) => h.barcode == selectedProduct!.barcode,
      );

      return ProductDetailCard(
        product: selectedProduct!,
        onBack: () => setState(() => selectedProduct = null),
        onReportSubmit: handleReportSubmit,
        onProductUpdate: handleProductUpdate,
        userSettings: userSettings,
        onDeleteHistoryByBarcode: isInHistory && _currentIndex != 4
            ? handleDeleteHistoryByBarcode
            : null,
        hasReportedThisSession:
            reportedSessionBarcodes.contains(selectedProduct!.barcode) ||
            userReport != null,
        userReportId: userReport?.id,
        onDeleteReport: handleDeleteReport,
      );
    }

    switch (_currentIndex) {
      case 0:
        return CameraModule(
          onScanSuccess: handleScanSuccess,
          scanningProgress: scanningProgress,
          scanError: scanError,
        );
      case 1:
        return HistoryList(
          history: history,
          liveProducts: products,
          onRefresh: refreshAllData,
          onSelectItem: (barcode) {
            final match = products.cast<Product?>().firstWhere(
              (p) => p?.barcode == barcode,
              orElse: () => null,
            );
            if (match != null) {
              setState(() => selectedProduct = match);
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
        );
      case 2:
        return DatabaseProducts(
          products: products,
          onRefresh: refreshAllData,
          onSelectItem: (barcode) {
            final match = products.cast<Product?>().firstWhere(
              (p) => p?.barcode == barcode,
              orElse: () => null,
            );
            if (match != null) {
              setState(() => selectedProduct = match);
            }
          },
        );
      case 3:
        return SettingsPanel(
          settings: userSettings,
          reports: reports,
          onSettingsChange: (newSet) async {
            await DbService.saveLocalSettings(newSet);
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
          onViewReports: () => setState(() => _currentIndex = 4),
        );
      case 4:
        return MyReportsList(
          reports: reports,
          onBack: () => setState(() => _currentIndex = 3),
          onSelectReport: (barcode) {
            final match = products.cast<Product?>().firstWhere(
              (p) => p?.barcode == barcode,
              orElse: () => null,
            );
            if (match != null) {
              setState(() => selectedProduct = match);
            }
          },
          onDeleteReport: handleDeleteReport,
        );
      default:
        return Container();
    }
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
            selectedProduct = null;
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FC),
      appBar: selectedProduct != null
          ? null
          : AppBar(
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
      bottomNavigationBar: _currentIndex == 4 ? null : _buildCustomBottomNav(),
    );
  }
}
