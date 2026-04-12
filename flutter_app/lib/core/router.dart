import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/session/create_session_screen.dart';
import '../screens/session/session_results_screen.dart';
import '../screens/camera/camera_screen.dart';
import '../screens/results/results_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final loggedIn = ref.read(authProvider).isLoggedIn;
      final path = state.uri.path;

      final onAuth  = path.startsWith('/login') ||
                      path.startsWith('/register') ||
                      path == '/splash';

      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && (path == '/login' || path == '/splash')) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash',    builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',     builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',  builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: '/session/create',
        builder: (_, __) => const CreateSessionScreen(),
      ),
      GoRoute(
        path: '/session/camera',
        builder: (context, state) {
          final sid = int.tryParse(state.uri.queryParameters['sessionId'] ?? '');
          return CameraScreen(sessionId: sid);
        },
      ),
      GoRoute(
        path: '/session/results',
        builder: (context, state) {
          final sid = int.tryParse(state.uri.queryParameters['sessionId'] ?? '');
          return SessionResultsScreen(sessionId: sid);
        },
      ),
      GoRoute(
        path: '/delivery/results',
        builder: (context, state) {
          final filename   = state.uri.queryParameters['filename'] ?? '';
          final deliveryId = int.tryParse(state.uri.queryParameters['deliveryId'] ?? '');
          return ResultsScreen(filename: filename, deliveryId: deliveryId);
        },
      ),
    ],
  );
});
