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
      title: 'Scanner Celiachia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
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
      // Aspettiamo il sign-in anonimo prima di tutto
      final userCred = await FirebaseAuth.instance.signInAnonymously();
      setState(() {
        userId = userCred.user?.uid;
      });

      // Ascoltiamo cambi di auth successivi (es. logout/login)
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        setState(() {
          userId = user?.uid;
        });
        // Ricarica storia e segnalazioni quando l'utente cambia
        await Future.wait([_fetchHistory(), _fetchReports()]);
      });

      await Future.wait([
        _fetchProducts(),
        _fetchHistory(),
        _fetchReports(),
        _fetchSettings(),
      ]);
    } catch (e) {
      print("Inizializzazione fallita: $e");
    } finally {
      setState(() {
        loadingApp = false;
      });
    }
  }

  Future<void> _fetchProducts() async {
    final data = await DbService.fetchAllProducts();
    setState(() {
      products = data;
    });
  }

  Future<void> _fetchHistory() async {
    final data = await DbService.getHistory();
    setState(() {
      history = data;
    });
  }

  Future<void> _fetchReports() async {
    final data = await DbService.fetchUserReports();
    setState(() {
      reports = data;
    });
  }

  Future<void> _fetchSettings() async {
    final data = await DbService.getLocalSettings();
    setState(() {
      userSettings = data;
    });
  }

  Future<void> handleScanSuccess(String barcode) async {
    setState(() {
      scanningProgress = true;
      scanError = null;
    });

    try {
      final product = await DbService.scanBarcodeClientSide(barcode, userSettings);
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

  Future<void> handleReportSubmit(String barcode, Map<String, dynamic> reportData) async {
    try {
      final product = products.firstWhere((p) => p.barcode == barcode, orElse: () => Product(
        barcode: barcode, name: "Product", brand: "Brand", ingredients: "", allergens: [], status: GlutenSafetyStatus.sconosciuto, reason: "", lastUpdated: "",
      ));

      await DbService.submitProductReportClientSide(
        barcode,
        product.name,
        product.brand,
        reportData
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
            reason: "ATTENZIONE: Segnalata etichetta incongruente o obsoleta dagli utenti. Note: ${reportData['comments']}",
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
    // Basic logic stub for updating local product
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
      await DbService.db.collection('products').doc(finalProduct.barcode).set(finalProduct.toJson(), SetOptions(merge: true));
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
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text("Inizializzazione Database...", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (selectedProduct != null) {
      final userReport = reports.cast<ProductReport?>().firstWhere(
        (r) => r?.barcode == selectedProduct!.barcode && r?.userId == userId, 
        orElse: () => null
      );
      final isInHistory = history.any((h) => h.barcode == selectedProduct!.barcode);

      return ProductDetailCard(
        product: selectedProduct!,
        onBack: () => setState(() => selectedProduct = null),
        onReportSubmit: handleReportSubmit,
        onProductUpdate: handleProductUpdate,
        userSettings: userSettings,
        onDeleteHistoryByBarcode: isInHistory && _currentIndex != 4 ? handleDeleteHistoryByBarcode : null,
        hasReportedThisSession: reportedSessionBarcodes.contains(selectedProduct!.barcode) || userReport != null,
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
          onSelectItem: (barcode) {
            final match = products.cast<Product?>().firstWhere((p) => p?.barcode == barcode, orElse: () => null);
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
          onSelectItem: (barcode) {
            final match = products.cast<Product?>().firstWhere((p) => p?.barcode == barcode, orElse: () => null);
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
          reports: reports, // già filtrate per userId da fetchUserReports()
          onBack: () => setState(() => _currentIndex = 3),
          onSelectReport: (barcode) {
            final match = products.cast<Product?>().firstWhere((p) => p?.barcode == barcode, orElse: () => null);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Scanner Celiachia", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade800,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _currentIndex == 4 ? null : BottomNavigationBar(
        currentIndex: _currentIndex > 3 ? 3 : _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        elevation: 10,
        onTap: (index) {
          setState(() {
            selectedProduct = null;
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: "Scansione"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Cronologia"),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber), label: "Segnalazioni"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Impostazioni"),
        ],
      ),
    );
  }
}
