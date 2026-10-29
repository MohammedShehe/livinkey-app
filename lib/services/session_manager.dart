// lib/services/session_manager.dart
import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'push_notification_service.dart' show navigatorKey, PushNotificationService;

/// Ends the user's session ONLY when the server confirms it is really over
/// (token expired after the number of days configured in the backend, token
/// invalid, or the account was deactivated). Network problems, server errors
/// and permission errors never reach this class.
class SessionManager {
  SessionManager._();
  static final SessionManager _instance = SessionManager._();
  factory SessionManager() => _instance;

  bool _ending = false;

  /// Called after a successful login so a later expiry can be handled again.
  void reset() => _ending = false;

  /// User-initiated logout. Never blocks on the network: the push token is
  /// removed on a best-effort basis (4s max), then the local session is cleared
  /// and the whole navigation stack is replaced with the login screen.
  Future<void> logout() async {
    try {
      await PushNotificationService().removeToken().timeout(const Duration(seconds: 4));
    } catch (_) {}
    await ApiService().clearToken();
    _ending = true; // ignore late 401s from requests still in flight

    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
        SnackBar(
          content: const Text('You have been logged out.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1C1C1C),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: kLivinkeyGreen.withOpacity(0.5)),
          ),
        ),
      );
    });
  }

  Future<void> endSession(String message) async {
    if (_ending) return;
    _ending = true;

    await ApiService().clearToken();

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );

    // Show the reason once the login screen is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1C1C1C),
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: kLivinkeyGreen.withOpacity(0.5)),
          ),
        ),
      );
    });
  }
}
