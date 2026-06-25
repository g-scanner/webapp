import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// --- Material 3 Design Colors ---
const Color primaryContainer = Color(0xFF2E7D32);
const Color surfaceContainerLowest = Color(0xFFFFFFFF);
const Color surfaceContainer = Color(0xFFEFEDF1);
const Color surfaceContainerLow = Color(0xFFF5F3F7);
const Color surfaceContainerHighest = Color(0xFFE3E2E6);
const Color onSurface = Color(0xFF1B1B1E);
const Color onSurfaceVariant = Color(0xFF40493D);
const Color errorColor = Color(0xFFBA1A1A);
const Color tertiaryContainer = Color(0xFFAD5600);

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

class _CameraModuleState extends State<CameraModule> {
  final TextEditingController _manualCodeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _manualCodeController.dispose();
    _scannerController.dispose();
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
    return Container(
      color: surfaceContainerLowest,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Intestazione ────────────────────────────────────────────────
            const Text(
              "Scan Product",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: onSurface,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Align barcode within frame to check celiac safety.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: onSurfaceVariant),
            ),
            const SizedBox(height: 32),

            // ── Card Integrata (Fotocamera + Inserimento Manuale) ───────────
            _buildIntegratedCard(),

            // Errore eventuale scansione
            if (widget.scanError != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.scanError!,
                        style: const TextStyle(fontSize: 14, color: errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── Guide Indicatori Bento ──────────────────────────────────────
            _buildSafetyGuide(),
          ],
        ),
      ),
    );
  }

  /// ── Nuova Card Unica per Fotocamera e Input ──────────────────────────────
  Widget _buildIntegratedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(40), // 40px come nel CSS (2.5rem)
        border: Border.all(color: surfaceContainerHighest),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Area Fotocamera
          _buildCameraArea(),

          // 2. Divisore "oppure"
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Divider(color: surfaceContainerHighest, thickness: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Oppure",
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurfaceVariant.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(color: surfaceContainerHighest, thickness: 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Inserimento Manuale
          _buildManualInput(),
        ],
      ),
    );
  }

  Widget _buildCameraArea() {
    const double buttonOverflow = 38.0;

    return Stack(
      children: [
        // Riquadro Fotocamera Principale
        Padding(
          padding: const EdgeInsets.only(bottom: buttonOverflow),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                32.0,
              ), // Arrotondato bene come nel CSS
              color: surfaceContainer,
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;

                  final double frameW = w * 0.85;
                  final double frameH = h * 0.65;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.1,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.85),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 2,
                                height: 24,
                                color: primaryContainer,
                              ),
                              Container(
                                width: 24,
                                height: 2,
                                color: primaryContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          width: frameW,
                          height: frameH,
                          child: _buildCorners(),
                        ),
                      ),
                      if (widget.scanningProgress)
                        Container(
                          color: Colors.black.withOpacity(0.6),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: primaryContainer,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Analyzing...",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),

        // Pulsante Flash
        Positioned(
          bottom: 15,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                onPressed: () => _scannerController.toggleTorch(),
                backgroundColor: surfaceContainerHighest,
                foregroundColor: onSurface,
                elevation: 4,
                shape: const CircleBorder(),
                child: ValueListenableBuilder<TorchState>(
                  valueListenable: _scannerController.torchState,
                  builder: (context, state, child) {
                    return Icon(
                      state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: surfaceContainerLow,
              borderRadius: BorderRadius.circular(28), // Design a pillola
              border: Border.all(color: surfaceContainerHighest),
            ),
            child: Center(
              child: TextField(
                controller: _manualCodeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16, color: onSurface),
                decoration: InputDecoration(
                  hintText: "Manual Barcode Entry",
                  hintStyle: TextStyle(
                    color: onSurfaceVariant.withOpacity(0.4),
                  ),
                  border: InputBorder.none, // Rimossa la riga sotto
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: widget.scanningProgress ? null : _handleManualSearch,
          style: FilledButton.styleFrom(
            backgroundColor: primaryContainer.withOpacity(0.1),
            foregroundColor: primaryContainer,
            elevation: 0,
            minimumSize: const Size(0, 56),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28), // Design a pillola
            ),
          ),
          child: const Text(
            "Search",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyGuide() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            "Safety Indicators",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  Icons.check_circle_rounded,
                  "Safe",
                  "Gluten-free",
                  primaryContainer,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  Icons.warning_rounded,
                  "Uncertain",
                  "Check label",
                  tertiaryContainer,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  Icons.cancel_rounded,
                  "Unsafe",
                  "Has gluten",
                  errorColor,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  Icons.help_rounded,
                  "Unknown",
                  "Not found",
                  onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: surfaceContainerLowest,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: onSurface,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10,
            color: onSurfaceVariant,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCorners() {
    const double cornerLen = 28;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(cornerLen, cornerLen),
            painter: _CornerPainter(
              color: primaryContainer,
              alignment: Alignment.topLeft,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(cornerLen, cornerLen),
            painter: _CornerPainter(
              color: primaryContainer,
              alignment: Alignment.topRight,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(cornerLen, cornerLen),
            painter: _CornerPainter(
              color: primaryContainer,
              alignment: Alignment.bottomLeft,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(cornerLen, cornerLen),
            painter: _CornerPainter(
              color: primaryContainer,
              alignment: Alignment.bottomRight,
            ),
          ),
        ),
      ],
    );
  }
}

// ── CUSTOM PAINTER ──────────────────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final Alignment alignment;

  _CornerPainter({
    required this.color,
    this.strokeWidth = 4,
    this.radius = 12,
    required this.alignment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final d = strokeWidth / 2;

    if (alignment == Alignment.topLeft) {
      path.moveTo(d, size.height);
      path.lineTo(d, radius);
      path.quadraticBezierTo(d, d, radius, d);
      path.lineTo(size.width, d);
    } else if (alignment == Alignment.topRight) {
      path.moveTo(0, d);
      path.lineTo(size.width - radius, d);
      path.quadraticBezierTo(size.width - d, d, size.width - d, radius);
      path.lineTo(size.width - d, size.height);
    } else if (alignment == Alignment.bottomLeft) {
      path.moveTo(d, 0);
      path.lineTo(d, size.height - radius);
      path.quadraticBezierTo(d, size.height - d, radius, size.height - d);
      path.lineTo(size.width, size.height - d);
    } else if (alignment == Alignment.bottomRight) {
      path.moveTo(size.width - d, 0);
      path.lineTo(size.width - d, size.height - radius);
      path.quadraticBezierTo(
        size.width - d,
        size.height - d,
        size.width - radius,
        size.height - d,
      );
      path.lineTo(0, size.height - d);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}
