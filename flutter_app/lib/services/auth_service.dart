// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  final _client = ApiClient().dio;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Login with email/password. Returns true if successful.
  Future<bool> login(String email, String password) async {
    try {
      final response = await _client.post(
        '/login/access-token',
        data: {
          'username': email,
          'password': password,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      final token = response.data['access_token'] as String?;
      if (token != null) {
        try {
          await _storage.write(key: 'access_token', value: token);
        } catch (e) {
          debugPrint('Storage write error during login: $e');
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('Dio error during login: ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        final detail = e.response?.data['detail'] ?? 'Invalid email or password.';
        throw Exception(detail);
      }
      throw Exception('Server error during login. Please try again later.');
    } catch (e) {
      debugPrint('Unexpected error during login: $e');
      throw Exception('An unexpected error occurred during login.');
    }
  }

  /// Register new user. Returns true if successful.
  Future<bool> register(String email, String password, String fullName) async {
    try {
      await _client.post('/users/', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });
      return true;
    } on DioException catch (e) {
      debugPrint('Dio error during register: ${e.response?.data ?? e.message}');
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        throw Exception(e.response?.data['detail']);
      }
      throw Exception('Server error during registration. Please try again later.');
    } catch (e) {
      debugPrint('Unexpected error during register: $e');
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  /// Logout — clears token from storage.
  Future<void> logout() async {
    try {
      await _storage.delete(key: 'access_token');
    } catch (e) {
      debugPrint('Storage error during logout: $e');
    }
  }

  /// Returns true if a token exists.
  Future<bool> isLoggedIn() async {
    try {
      final token = await _storage.read(key: 'access_token').timeout(const Duration(seconds: 2));
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('Storage read error during isLoggedIn: $e');
      // Keystore corruption / PlatformException / TimeoutException
      try {
        await _storage.deleteAll().timeout(const Duration(seconds: 1));
      } catch (innerError) {
        debugPrint('Failed to wipe corrupted storage: $innerError');
      }
      return false;
    }
  }
}
