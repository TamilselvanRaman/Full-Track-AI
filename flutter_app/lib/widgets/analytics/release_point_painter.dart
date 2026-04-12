// lib/widgets/analytics/release_point_painter.dart
import 'package:flutter/material.dart';
import '../../models/analysis_result.dart';

class ReleasePointPainter extends CustomPainter {
  final AnalysisResult? result;
  ReleasePointPainter({this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final w  = size.width;
    final h  = size.height;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF141928),
    );

    // Draw a simplified stick-person (bowler silhouette)
    final bodyPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.15), 18, bodyPaint);
    // Torso
    canvas.drawLine(Offset(w * 0.5, h * 0.22), Offset(w * 0.5, h * 0.58), bodyPaint);
    // Arms
    canvas.drawLine(Offset(w * 0.5, h * 0.32), Offset(w * 0.2, h * 0.25), bodyPaint);
    canvas.drawLine(Offset(w * 0.5, h * 0.32), Offset(w * 0.8, h * 0.25), bodyPaint);
    // Legs
    canvas.drawLine(Offset(w * 0.5, h * 0.58), Offset(w * 0.3, h * 0.85), bodyPaint);
    canvas.drawLine(Offset(w * 0.5, h * 0.58), Offset(w * 0.7, h * 0.85), bodyPaint);

    // Release point crosshair target
    final rpX = result?.releasePointX != null
        ? w * (result!.releasePointX! / 100)
        : w * 0.78;
    final rpY = result?.releasePointY != null
        ? h * (result!.releasePointY! / 100)
        : h * 0.26;

    const crossSize  = 12.0;
    final crossPaint = Paint()..color = Colors.red;

    canvas.drawLine(
      Offset(rpX - crossSize, rpY),
      Offset(rpX + crossSize, rpY),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(rpX, rpY - crossSize),
      Offset(rpX, rpY + crossSize),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2,
    );

    canvas.drawCircle(
      Offset(rpX, rpY),
      8,
      Paint()
        ..color = Colors.red.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(rpX, rpY),
      8,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant ReleasePointPainter old) => old.result != result;
}
