import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CameraModule extends StatefulWidget {
  final Future<void> Function(String barcode) onScanSuccess;
  final bool scanningProgress;
  final String? scanError;

  const CameraModule({
    super.key,
    required this.onScanSuccess,
    required this.scanningProgress,
    this.scanError,
  });

  @override
  State<CameraModule> createState() => _CameraModuleState();
}

class _CameraModuleState extends State<CameraModule>
    with SingleTickerProviderStateMixin {
  final TextEditingController _manualCodeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessing = false;
  late AnimationController _animController;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _manualCodeController.dispose();
    _scannerController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleManualSearch() {
    if (_manualCodeController.text.trim().isEmpty) return;
    widget.onScanSuccess(_manualCodeController.text.trim());
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || widget.scanningProgress) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _isProcessing = true;
      await widget.onScanSuccess(barcodes.first.rawValue!);
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scan Card
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28.0),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "Scannerizza Codice Prodotto",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Inquadra il codice a barre o QR code con la fotocamera per analizzare all'istante la presenza di allergeni o glutine.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // ── Camera Viewport ──────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Feed camera
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: _onDetect,
                        ),

                        // Overlay sfumatura bordi (vignette)
                        _buildVignette(),

                        // Mirino centrale con angoli
                        _buildScanFrame(),

                        // Linea di scansione animata
                        if (!widget.scanningProgress)
                          AnimatedBuilder(
                            animation: _scanLineAnim,
                            builder: (context, _) {
                              return Align(
                                alignment: Alignment(0, (_scanLineAnim.value * 2) - 1),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 60),
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.green.withValues(alpha: 0.9),
                                        Colors.transparent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            },
                          ),

                        // Overlay analisi in corso
                        if (widget.scanningProgress)
                          Container(
                            color: Colors.black.withValues(alpha: 0.7),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Colors.green),
                                  SizedBox(height: 16),
                                  Text(
                                    "Analisi in corso...",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                if (widget.scanError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.scanError!,
                            style:
                                TextStyle(fontSize: 12, color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Ricerca manuale
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualCodeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Digita codice a barre...",
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: widget.scanningProgress ? null : _handleManualSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Cerca"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Guida stati (ordine: Verde > Grigio > Giallo > Rosso) ──────────
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "GUIDA AGLI STATI",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGuideItem(
                  "🟢", "ADATTO (Gluten-Safe)",
                  "Bollino ufficiale 'Senza Glutine' presente e nessun ingrediente a rischio.",
                  Colors.green.shade50, Colors.green.shade900,
                ),
                const SizedBox(height: 12),
                _buildGuideItem(
                  "⚪", "SCONOSCIUTO",
                  "Dati assenti nel database. Controlla sempre l'etichetta fisica.",
                  Colors.grey.shade100, Colors.grey.shade900,
                ),
                const SizedBox(height: 12),
                _buildGuideItem(
                  "🟡", "INCERTO (Attenzione)",
                  "Nessun bollino GF, o segnalazione attiva da altri utenti. Verifica la confezione.",
                  Colors.orange.shade50, Colors.orange.shade900,
                ),
                const SizedBox(height: 12),
                _buildGuideItem(
                  "🔴", "NON ADATTO",
                  "Contiene ingredienti con glutine o è segnalato come non adatto ai celiaci.",
                  Colors.red.shade50, Colors.red.shade900,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Sfumatura ai quattro bordi del viewport (vignette)
  Widget _buildVignette() {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.55),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ),
    );
  }

  /// Mirino con angoli verdi
  Widget _buildScanFrame() {
    const double frameSize = 200;
    const double cornerLen = 24;
    const double cornerThick = 3.5;
    const Color cornerColor = Colors.green;

    return Center(
      child: SizedBox(
        width: frameSize,
        height: frameSize,
        child: Stack(
          children: [
            // Punto centrale
            Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
            ),

            // Angolo top-left
            Positioned(
              top: 0, left: 0,
              child: _corner(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(4)),
                top: cornerThick, left: cornerThick, right: null, bottom: null,
                w: cornerLen, h: cornerLen, color: cornerColor,
              ),
            ),
            // Angolo top-right
            Positioned(
              top: 0, right: 0,
              child: _corner(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(4)),
                top: cornerThick, right: cornerThick, left: null, bottom: null,
                w: cornerLen, h: cornerLen, color: cornerColor,
              ),
            ),
            // Angolo bottom-left
            Positioned(
              bottom: 0, left: 0,
              child: _corner(
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(4)),
                bottom: cornerThick, left: cornerThick, right: null, top: null,
                w: cornerLen, h: cornerLen, color: cornerColor,
              ),
            ),
            // Angolo bottom-right
            Positioned(
              bottom: 0, right: 0,
              child: _corner(
                borderRadius: const BorderRadius.only(bottomRight: Radius.circular(4)),
                bottom: cornerThick, right: cornerThick, left: null, top: null,
                w: cornerLen, h: cornerLen, color: cornerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner({
    required BorderRadius borderRadius,
    double? top, double? left, double? right, double? bottom,
    required double w, required double h, required Color color,
  }) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        border: Border(
          top: top != null ? BorderSide(color: color, width: top) : BorderSide.none,
          left: left != null ? BorderSide(color: color, width: left) : BorderSide.none,
          right: right != null ? BorderSide(color: color, width: right) : BorderSide.none,
          bottom: bottom != null ? BorderSide(color: color, width: bottom) : BorderSide.none,
        ),
        borderRadius: borderRadius,
      ),
    );
  }

  Widget _buildGuideItem(String icon, String title, String desc, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 12)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: textColor, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
