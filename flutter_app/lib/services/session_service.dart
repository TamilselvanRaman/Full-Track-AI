// lib/services/session_service.dart
import 'api_client.dart';
import '../models/session.dart';

class SessionService {
  final _client = ApiClient().dio;

  Future<Session> createSession({
    required String name,
    required String sessionType,
    String? bowlingType,
    String? filmingMethod,
    double pitchLength = 22.0,
  }) async {
    final response = await _client.post('/session/create', data: {
      'name': name,
      'session_type': sessionType,
      'bowling_type': bowlingType,
      'filming_method': filmingMethod,
      'pitch_length': pitchLength,
    });
    return Session.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Session> getSession(int sessionId) async {
    final response = await _client.get('/session/$sessionId');
    return Session.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Session>> getMySessions() async {
    final response = await _client.get('/session/mine');
    final List data = response.data as List;
    return data.map((json) => Session.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> deleteSession(int sessionId) async {
    await _client.delete('/session/$sessionId');
  }
}
