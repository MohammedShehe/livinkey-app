// lib/services/app_events.dart
import 'package:flutter/foundation.dart';

/// Lightweight "something may have changed" signal.
/// Increments when the app returns to the foreground, a push notification
/// arrives, or the user pulls to refresh anywhere. Screens listen and reload
/// their data silently so everything stays up to date without manual refreshes.
class AppEvents {
  AppEvents._();
  static final ValueNotifier<int> refreshTick = ValueNotifier<int>(0);
  static void requestRefresh() => refreshTick.value++;
}
