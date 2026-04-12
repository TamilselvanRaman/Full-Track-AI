// lib/widgets/analytics/beehive_painter.dart
import 'package:flutter/material.dart';
import '../../models/analysis_result.dart';

class BeehivePainter extends CustomPainter {
  final AnalysisResult? result;
  BeehivePainter({this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final w  = size.width;
    final h  = size.height;
    final cx = w / 2;

    // Stumps background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF141928),
    );

    // Draw 3 stump columns (5 zones high = 3x5 grid)
    const cols = 3;
    const rows = 5;
    final cellW = w / cols;
    final cellH = h / rows;

    for (int col = 0; col < cols; col++) {
      for (int row = 0; row < rows; row++) {
        final rect = Rect.fromLTWH(
          col * cellW + 2,
          row * cellH + 2,
          cellW - 4,
          cellH - 4,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = const Color(0xFF1C2340),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()
            ..color = Colors.blueAccent.withOpacity(0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }
    }

    // Highlight impact zone based on line/length
    if (result?.line != null || result?.length != null) {
      final impactCol = _colFromLine(result?.line);
      final impactRow = _rowFromLength(result?.length);
      final highlightRect = Rect.fromLTWH(
        impactCol * cellW + 2,
        impactRow * cellH + 2,
        cellW - 4,
        cellH - 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, const Radius.circular(4)),
        Paint()..color = Colors.redAccent.withOpacity(0.75),
      );
    }

    // Stump posts
    for (int i = 0; i < 3; i++) {
      final x = (i + 0.5) * (w / 3);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, h),
        Paint()
          ..color = Colors.white60
          ..strokeWidth = 2,
      );
    }

    // Bails
    canvas.drawLine(
      Offset(w / 3, 0),
      Offset(2 * w / 3, 0),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3,
    );
  }

  int _colFromLine(String? line) {
    switch (line?.toLowerCase()) {
      case 'off stump':
        return 2;
      case 'leg stump':
        return 0;
      default:
        return 1; // middle
    }
  }

  int _rowFromLength(String? length) {
    switch (length?.toLowerCase()) {
      case 'short':
        return 0;
      case 'good length':
        return 1;
      case 'full':
        return 3;
      case 'yorker':
        return 4;
      default:
        return 2;
    }
  }

  @override
  bool shouldRepaint(covariant BeehivePainter old) => old.result != result;
}
