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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: duration,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    show(
      context,
      message,
      color: Colors.red.shade700,
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
      color: Colors.orange.shade700,
      icon: Icons.warning_rounded,
      duration: const Duration(seconds: 4),
    );
  }

  static void showInfo(BuildContext context, String message) {
    show(
      context,
      message,
      color: Colors.blue.shade700,
      icon: Icons.info_outline_rounded,
      duration: const Duration(seconds: 3),
    );
  }
}