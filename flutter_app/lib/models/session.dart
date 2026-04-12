// lib/models/session.dart
class Session {
  final int id;
  final int userId;
  final String name;
  final String sessionType;
  final String? bowlingType;
  final String? filmingMethod;
  final double pitchLength;
  final DateTime? createdAt;

  const Session({
    required this.id,
    required this.userId,
    required this.name,
    required this.sessionType,
    this.bowlingType,
    this.filmingMethod,
    this.pitchLength = 22.0,
    this.createdAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        name: json['name'] as String,
        sessionType: json['session_type'] as String,
        bowlingType: json['bowling_type'] as String?,
        filmingMethod: json['filming_method'] as String?,
        pitchLength: (json['pitch_length'] as num?)?.toDouble() ?? 22.0,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'session_type': sessionType,
        'bowling_type': bowlingType,
        'filming_method': filmingMethod,
        'pitch_length': pitchLength,
      };
}
