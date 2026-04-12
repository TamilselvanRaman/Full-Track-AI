// lib/models/analysis_result.dart
class AnalysisResult {
  final int id;
  final int deliveryId;
  final double? speed;
  final String? line;
  final String? length;
  final double? swing;
  final double? pitchmapX;
  final double? pitchmapY;
  final double? releasePointX;
  final double? releasePointY;

  const AnalysisResult({
    required this.id,
    required this.deliveryId,
    this.speed,
    this.line,
    this.length,
    this.swing,
    this.pitchmapX,
    this.pitchmapY,
    this.releasePointX,
    this.releasePointY,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        id: json['id'] as int,
        deliveryId: json['delivery_id'] as int,
        speed: (json['speed'] as num?)?.toDouble(),
        line: json['line'] as String?,
        length: json['length'] as String?,
        swing: (json['swing'] as num?)?.toDouble(),
        pitchmapX: (json['pitchmap_x'] as num?)?.toDouble(),
        pitchmapY: (json['pitchmap_y'] as num?)?.toDouble(),
        releasePointX: (json['release_point_x'] as num?)?.toDouble(),
        releasePointY: (json['release_point_y'] as num?)?.toDouble(),
      );

  /// Build from the legacy trajectory JSON that the `/video/trajectory/{filename}` endpoint returns
  factory AnalysisResult.fromTrajectoryJson(Map<String, dynamic> json) {
    final analytics = json['analytics'] as Map<String, dynamic>? ?? {};
    final pitchmap = analytics['pitchmap'] as Map<String, dynamic>? ?? {};
    final releasePoint = analytics['release_point'] as Map<String, dynamic>? ?? {};
    return AnalysisResult(
      id: 0,
      deliveryId: 0,
      speed: (analytics['speed'] as num?)?.toDouble(),
      line: analytics['line'] as String?,
      length: analytics['length'] as String?,
      swing: (analytics['swing'] as num?)?.toDouble(),
      pitchmapX: (pitchmap['x'] as num?)?.toDouble(),
      pitchmapY: (pitchmap['y'] as num?)?.toDouble(),
      releasePointX: (releasePoint['x'] as num?)?.toDouble(),
      releasePointY: (releasePoint['y'] as num?)?.toDouble(),
    );
  }
}
