// lib/widgets/common/snackbar_helper.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class SnackbarHelper {
  static void show(
    BuildContext context,
    String message, {
    Color color = kLivinkeyGreen,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    // Dismiss any existing snackbars for clean feedback
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: duration,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        elevation: 6,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    // Map common technical phrases to friendlier copy when possible
    final friendly = _toFriendlyMessage(message);
    show(
      context,
      friendly,
      color: const Color(0xFFC62828),
      icon: Icons.error_outline_rounded,
      duration: const Duration(seconds: 4),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(
      context,
      message,
      color: kLivinkeyGreen,
      icon: Icons.check_circle_rounded,
      duration: const Duration(seconds: 3),
    );
  }

  static void showWarning(BuildContext context, String message) {
    show(
      context,
      message,
      color: const Color(0xFFEF6C00),
      icon: Icons.warning_amber_rounded,
      duration: const Duration(seconds: 4),
    );
  }

  static void showInfo(BuildContext context, String message) {
    show(
      context,
      message,
      color: const Color(0xFF1565C0),
      icon: Icons.info_outline_rounded,
      duration: const Duration(seconds: 3),
    );
  }

  /// Converts occasional technical / backend messages into user-friendly text.
  static String _toFriendlyMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('socket') || lower.contains('connection') || lower.contains('network') || lower.contains('timeout')) {
      return 'Unable to connect. Please check your internet and try again.';
    }
    if (lower.contains('unauthorized') || lower.contains('401') || lower.contains('token')) {
      return 'Your session has expired. Please log in again.';
    }
    if (lower.contains('server') || lower.contains('500') || lower.contains('internal')) {
      return 'Something went wrong on our side. Please try again shortly.';
    }
    if (lower.contains('not found') || lower.contains('404')) {
      return 'The requested information could not be found.';
    }
    if (lower.trim().isEmpty || lower == 'null' || lower.contains('exception')) {
      return 'Something went wrong. Please try again.';
    }
    return message;
  }
}