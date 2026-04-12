// lib/providers/session_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../models/delivery.dart';

class SessionState {
  final Session? currentSession;
  final List<DeliveryStatus> deliveries;

  const SessionState({this.currentSession, this.deliveries = const []});

  SessionState copyWith({Session? currentSession, List<DeliveryStatus>? deliveries}) =>
      SessionState(
        currentSession: currentSession ?? this.currentSession,
        deliveries: deliveries ?? this.deliveries,
      );
}

class DeliveryStatus {
  final int number;
  final String filename;
  final bool isComplete;

  const DeliveryStatus({
    required this.number,
    required this.filename,
    this.isComplete = false,
  });

  DeliveryStatus copyWith({bool? isComplete}) =>
      DeliveryStatus(number: number, filename: filename, isComplete: isComplete ?? this.isComplete);
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(const SessionState());

  void setSession(Session session) {
    state = SessionState(currentSession: session, deliveries: []);
  }

  void addDelivery(String filename, int number) {
    state = state.copyWith(
      deliveries: [...state.deliveries, DeliveryStatus(number: number, filename: filename)],
    );
  }

  void markDeliveryComplete(String filename) {
    state = state.copyWith(
      deliveries: state.deliveries
          .map((d) => d.filename == filename ? d.copyWith(isComplete: true) : d)
          .toList(),
    );
  }

  void clearSession() {
    state = const SessionState();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (_) => SessionNotifier(),
);
