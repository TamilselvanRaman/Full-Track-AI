// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({bool? isLoggedIn, bool? isLoading, String? errorMessage}) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _auth;
  AuthNotifier(this._auth) : super(const AuthState());

  Future<void> checkAuth() async {
    final loggedIn = await _auth.isLoggedIn();
    state = state.copyWith(isLoggedIn: loggedIn);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await _auth.login(email, password);
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: success,
        errorMessage: null,
      );
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await _auth.register(email, password, fullName);
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    state = const AuthState();
  }
}

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);
