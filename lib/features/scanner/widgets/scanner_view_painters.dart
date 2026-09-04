// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';

class CornerPainter extends CustomPainter {
  final Color color;
  final Alignment alignment;

  static const double strokeWidth = 4.0;
  static const double radius = 12.0;

  CornerPainter({required this.color, required this.alignment});

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
  bool shouldRepaint(covariant CornerPainter oldDelegate) => false;
}

class VignetteBorderPainter extends CustomPainter {
  final double frameWidth;
  final double frameHeight;

  VignetteBorderPainter({required this.frameWidth, required this.frameHeight});

  static const double _targetMaxOpacity = 0.75;
  static const int _steps = 45;

  double _getTargetOpacity(int k) {
    if (k >= _steps - 1) return 0.0;
    final double t = 1.0 - (k / (_steps - 1));
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

    final double startWidth = size.width * 1.3;
    final double startHeight = size.height * 1.3;

    for (int i = 0; i < _steps; i++) {
      final double currentTarget = _getTargetOpacity(i);
      final double innerTarget = _getTargetOpacity(i + 1);

      double layerAlpha = 0.0;
      if (innerTarget < 1.0) {
        layerAlpha = (currentTarget - innerTarget) / (1.0 - innerTarget);
      }
      layerAlpha = layerAlpha.clamp(0.0, 1.0);

      final Paint paint = Paint()
        ..color = Colors.black.withValues(alpha: layerAlpha)
        ..style = PaintingStyle.fill;

      final double t = i / (_steps - 1);
      final double currentWidth = startWidth + (frameWidth - startWidth) * t;
      final double currentHeight =
          startHeight + (frameHeight - startHeight) * t;

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

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant VignetteBorderPainter oldDelegate) =>
      oldDelegate.frameWidth != frameWidth ||
      oldDelegate.frameHeight != frameHeight;
}
