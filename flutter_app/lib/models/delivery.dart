// lib/models/delivery.dart
class Delivery {
  final int id;
  final int sessionId;
  final int? deliveryNumber;
  final String? videoFilename;

  const Delivery({
    required this.id,
    required this.sessionId,
    this.deliveryNumber,
    this.videoFilename,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
        id: json['id'] as int,
        sessionId: json['session_id'] as int,
        deliveryNumber: json['delivery_number'] as int?,
        videoFilename: json['video_filename'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'delivery_number': deliveryNumber,
        'video_filename': videoFilename,
      };
}
