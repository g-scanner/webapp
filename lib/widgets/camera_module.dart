import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// --- Material 3 Design Colors ---
const Color primaryContainer = Color(0xFF2E7D32);
const Color surfaceContainerLowest = Color(0xFFFFFFFF);
const Color surfaceContainer = Color(0xFFEFEDF1);
const Color surfaceContainerLow = Color(0xFFF5F3F7);
const Color surfaceContainerHighest = Color(0xFFE3E2E6);
const Color outlineVariant = Color(0xFFBFCABA);
const Color onSurface = Color(0xFF1B1B1E);
const Color onSurfaceVariant = Color(0xFF40493D);
const Color errorColor = Color(0xFFBA1A1A);
const Color tertiaryContainer = Color(0xFFAD5600);

class CameraModule extends StatefulWidget {
  final Future<void> Function(String barcode) onScanSuccess;
  final bool scanningProgress;
  final String? scanError;
  final bool isActive;

  const CameraModule({
    super.key,
    required this.onScanSuccess,
    required this.scanningProgress,
    this.scanError,
    this.isActive = true,
  });

  @override
  State<CameraModule> createState() => _CameraModuleState();
}

class _CameraModuleState extends State<CameraModule> {
  final TextEditingController _manualCodeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.qrCode,
    ],
    cameraResolution: const Size(480, 640),
  );

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _scannerController.start();
    }
  }

  @override
  void didUpdateWidget(CameraModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _scannerController.start();
      } else {
        _scannerController.stop();
      }
    }
  }

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
        // Margini esterni alla card
        padding: const EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 16.0,
          bottom: 40.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Card Integrata (Testo + Fotocamera + Inserimento Manuale) ───
            _buildIntegratedCard(),

            // Errore eventuale scansione
            if (widget.scanError != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: errorColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: errorColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.scanError!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: errorColor,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
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

  /// ── Card Unica Material 3: Spaziosa, Rotonda e Pulita ────────────────────
  Widget _buildIntegratedCard() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(36), // Raggio armonioso per M3
        border: Border.all(
          color: outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: onSurface.withValues(
              alpha: 0.04,
            ), // Ombra impalpabile e diffusa
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        // Spaziature interne perfette
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Intestazione ───────────────────────────────────────────
            const Text(
              "Scan Product",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: onSurface,
                fontFamily: 'Inter',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Align barcode within frame to check celiac safety.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32), // Respiro tra testo e fotocamera
            // 1. Area Fotocamera
            _buildCameraArea(),

            // 2. Divisore "oppure" spazioso
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 24.0, // Respiro verticale bilanciato
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Divider(
                      color: surfaceContainerHighest,
                      thickness: 1.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Oppure",
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurfaceVariant.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(
                      color: surfaceContainerHighest,
                      thickness: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Inserimento Manuale
            _buildManualInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    const double buttonOverflow = 28.0;

    return Stack(
      children: [
        // Riquadro Fotocamera Principale
        Padding(
          padding: const EdgeInsets.only(bottom: buttonOverflow),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.0), // Curve interne dolci
              color: surfaceContainer,
            ),
            clipBehavior: Clip.antiAlias,
            // ASPECT RATIO A RETTANGOLO (16/10)
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
                      CustomPaint(
                        size: Size(w, h),
                        painter: _VignetteBorderPainter(
                          frameWidth: frameW,
                          frameHeight: frameH,
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
                          color: Colors.black.withValues(alpha: 0.6),
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

        // ── Pulsante Flash Ricostruito M3 Perfettamente Centrato ──
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                final bool isOn = state.torchState == TorchState.on;

                return Material(
                  color: isOn ? primaryContainer : surfaceContainerLowest,
                  elevation:
                      4, // Ombra definita per spiccare dal nero della fotocamera
                  shadowColor: Colors.black.withValues(alpha: 0.4),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _scannerController.toggleTorch(),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Center(
                        child: Icon(
                          // La torcia è un'icona perfettamente simmetrica
                          isOn ? Icons.flashlight_on : Icons.flashlight_off,
                          size: 24,
                          color: isOn ? surfaceContainerLowest : onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
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
              borderRadius: BorderRadius.circular(999), // Forma a pillola
              border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: TextField(
                controller: _manualCodeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 16,
                  color: onSurface,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: "Manual Barcode",
                  hintStyle: TextStyle(
                    color: onSurfaceVariant.withValues(alpha: 0.5),
                    letterSpacing: 0,
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
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
            backgroundColor: primaryContainer.withValues(alpha: 0.1),
            foregroundColor: primaryContainer,
            elevation: 0,
            minimumSize: const Size(0, 56),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: const Text(
            "Search",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyGuide() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Text(
            "Safety Indicators",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 28),
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: surfaceContainerLowest,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: onSurface,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
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
  final Alignment alignment;

  static const double strokeWidth = 4.0;
  static const double radius = 12.0;

  _CornerPainter({required this.color, required this.alignment});

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

/// Disegna un gradiente infallibile calcolando matematicamente l'Alpha Blending.
/// Utilizza una curva (Curves.easeInOut) per garantire che l'opacità al bordo del
/// riquadro parta ESATTAMENTE da 0.0 e salga in modo morbidissimo verso l'esterno.
class _VignetteBorderPainter extends CustomPainter {
  final double frameWidth;
  final double frameHeight;

  _VignetteBorderPainter({required this.frameWidth, required this.frameHeight});

  // L'oscurità massima raggiunta ai bordi estremi dello schermo
  static const double _targetMaxOpacity = 0.75;

  // Alzato a 45 per garantire che la curva matematica non mostri mai "scalini"
  static const int _steps = 45;

  // Calcola l'opacità totale che il gradiente deve avere ad un determinato step.
  // k=0 è il bordo esterno (più scuro), k=_steps-1 è il riquadro centrale (0.0).
  double _getTargetOpacity(int k) {
    if (k >= _steps - 1) return 0.0;

    // t va da 0.0 (interno) a 1.0 (esterno)
    final double t = 1.0 - (k / (_steps - 1));

    // Curves.easeInOut garantisce che il gradiente parta piatto da 0 e acceleri dolcemente
    final double curveT = Curves.easeInOut.transform(t);
    return _targetMaxOpacity * curveT;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final screenRect = Rect.fromLTRB(
      -100,
      -100,
      size.width + 100,
      size.height + 100,
    );

    // Partiamo da fuori lo schermo per coprire bene anche gli angoli del dispositivo
    final double startWidth = size.width * 1.3;
    final double startHeight = size.height * 1.3;

    for (int i = 0; i < _steps; i++) {
      final double currentTarget = _getTargetOpacity(i);
      final double innerTarget = _getTargetOpacity(i + 1);

      // --- LA MAGIA DELL'ALPHA BLENDING ---
      // Calcoliamo esattamente quale opacità (layerAlpha) deve avere questo strato
      // per raggiungere il 'currentTarget', sapendo che sotto di esso ci sono strati
      // che arrivano a 'innerTarget'.
      double layerAlpha = 0.0;
      if (innerTarget < 1.0) {
        layerAlpha = (currentTarget - innerTarget) / (1.0 - innerTarget);
      }
      // Sicurezza contro approssimazioni in virgola mobile
      layerAlpha = layerAlpha.clamp(0.0, 1.0);

      final Paint paint = Paint()
        ..color = Colors.black.withValues(alpha: layerAlpha)
        ..style = PaintingStyle.fill;

      // Interpola la dimensione geometrica del livello
      final double t = i / (_steps - 1);
      final double currentWidth = startWidth + (frameWidth - startWidth) * t;
      final double currentHeight =
          startHeight + (frameHeight - startHeight) * t;

      // Curvatura dinamica: più ampia all'esterno, aderente a 24 al centro
      final double currentRadius = 60.0 + (24.0 - 60.0) * t;

      final RRect hole = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: currentWidth,
          height: currentHeight,
        ),
        Radius.circular(currentRadius),
      );

      final Path path = Path()
        ..addRect(screenRect)
        ..addRRect(hole)
        ..fillType = PathFillType.evenOdd;

      // Lo strato più vicino al centro avrà letteralmente opacità 0.0!
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VignetteBorderPainter oldDelegate) =>
      oldDelegate.frameWidth != frameWidth ||
      oldDelegate.frameHeight != frameHeight;
}
