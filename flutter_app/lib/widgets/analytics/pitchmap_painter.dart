// lib/widgets/analytics/pitchmap_painter.dart
import 'package:flutter/material.dart';
import '../../models/analysis_result.dart';

class PitchmapPainter extends CustomPainter {
  final AnalysisResult? result;
  PitchmapPainter({this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Zone fills ─────────────────────────────────────────────────────
    final zones = [
      (Rect.fromLTWH(0, 0, w, h * 0.20),         const Color(0xFFE53935), 'SHORT'),
      (Rect.fromLTWH(0, h * 0.20, w, h * 0.25),  const Color(0xFF00897B), 'GOOD LENGTH'),
      (Rect.fromLTWH(0, h * 0.45, w, h * 0.25),  const Color(0xFF1565C0), 'FULL'),
      (Rect.fromLTWH(0, h * 0.70, w, h * 0.30),  const Color(0xFFF57F17), 'YORKER'),
    ];

    for (final (rect, color, label) in zones) {
      canvas.drawRect(rect, Paint()..color = color.withOpacity(0.3));
      // Zone label
      TextPainter(
        text: TextSpan(
            text: label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )
        ..layout(maxWidth: w)
        ..paint(canvas, Offset(8, rect.top + 4));

      // Bottom border
      canvas.drawLine(
        Offset(0, rect.bottom),
        Offset(w, rect.bottom),
        Paint()
          ..color = color.withOpacity(0.5)
          ..strokeWidth = 0.5,
      );
    }

    // Centre line
    canvas.drawLine(
      Offset(w / 2, 0),
      Offset(w / 2, h),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 1,
    );

    // Crease line
    canvas.drawLine(
      Offset(w * 0.1, h * 0.72),
      Offset(w * 0.9, h * 0.72),
      Paint()
        ..color = Colors.white38
        ..strokeWidth = 1.5,
    );

    // ── Bounce dot ──────────────────────────────────────────────────────
    if (result?.pitchmapX != null && result?.pitchmapY != null) {
      final dotX = w * (result!.pitchmapX! / 100);
      final dotY = h * (result!.pitchmapY! / 100);
      canvas.drawCircle(
        Offset(dotX, dotY),
        8,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        6,
        Paint()..color = Colors.red,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PitchmapPainter old) => old.result != result;
}
