import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

String getTimeOfDay() {
  final hour = DateTime.now().hour;
  // Always use local device time so the greeting matches the user's timezone
  if (hour >= 5 && hour < 12) return 'Good Morning';
  if (hour >= 12 && hour < 17) return 'Good Afternoon';
  if (hour >= 17 && hour < 21) return 'Good Evening';
  return 'Good Night';
}

String formatDate(DateTime date) {
  return '${date.day} ${_monthName(date.month)}, ${date.year}';
}

String _monthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month - 1];
}

String getInitials(String name) {
  if (name.isEmpty) return '';
  final parts = name.trim().split(' ');
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

void hapticFeedback() {
  HapticFeedback.lightImpact();
}

void hapticSelection() {
  HapticFeedback.selectionClick();
}