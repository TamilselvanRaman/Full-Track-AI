import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../services/session_service.dart';

final sessionHistoryProvider = FutureProvider.autoDispose<List<Session>>((ref) async {
  final service = SessionService();
  return service.getMySessions();
});
