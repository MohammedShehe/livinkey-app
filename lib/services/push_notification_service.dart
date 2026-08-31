import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

/// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // Lazy getter – only accessed AFTER Firebase.initializeApp()
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ApiService _api = ApiService();
  bool _isInitialized = false;
  bool _isFirebaseInitialized = false;
  String? _fcmToken;

  // Track whether we already handled an initial (terminated) message
  bool _initialMessageHandled = false;

  /// Initialize Firebase only (called from main())
  Future<void> initializeFirebaseOnly() async {
    if (_isFirebaseInitialized) return;

    try {
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;
    } catch (e) {
      // Don't block app startup
      _isFirebaseInitialized = true;
    }
  }

  /// Full push-notification init – call AFTER login so auth is valid
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!_isFirebaseInitialized) {
        await Firebase.initializeApp();
        _isFirebaseInitialized = true;
      }

      if (!kIsWeb) {
        await _requestPermissions();
        await _initializeLocalNotifications();
        await _getFCMToken();
        await _setupMessageHandlers();
      }

      _isInitialized = true;
    } catch (e) {
      // Don't block app startup
      _isInitialized = true;
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (Platform.isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _fcm.getToken();
      if (_fcmToken != null) {
        await _storeFCMToken(_fcmToken!);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _storeFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      final response = await _api.updateFCMToken(token);
      // if it fails we still keep the token locally as pending
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_fcm_token', token);
    }
  }

  Future<void> retryPendingToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingToken = prefs.getString('pending_fcm_token');

      if (pendingToken != null && pendingToken.isNotEmpty) {
        final response = await _api.updateFCMToken(pendingToken);
        if (response['success'] == true) {
          await prefs.remove('pending_fcm_token');
        }
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _setupMessageHandlers() async {
    // 1. Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // 2. Background messages (must be top-level)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. App opened from terminated state
    if (!_initialMessageHandled) {
      final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _initialMessageHandled = true;
        // Delay a little so the navigator is ready
        Future.delayed(const Duration(milliseconds: 800), () {
          _handleNotificationData(initialMessage.data);
        });
      }
    }

    // 4. App opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationData(message.data);
    });

    // 5. Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _storeFCMToken(newToken);
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);

    // Refresh the in-app notification list so the badge updates immediately
    try {
      NotificationService().refresh(isTenant: true);
    } catch (_) {}
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final String title = message.notification?.title ?? 'Livinkey';
    final String body =
        message.notification?.body ?? 'You have a new notification';

    // Encode the whole data map as payload so we can navigate correctly
    final String payload = _encodePayload(message.data);

    const androidDetails = AndroidNotificationDetails(
      'livinkey_channel',
      'Livinkey Notifications',
      channelDescription: 'Notifications from Livinkey',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF92C24A),
      ledOnMs: 1000,
      ledOffMs: 500,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );

    await _updateAppBadge();
  }

  String _encodePayload(Map<String, dynamic> data) {
    // Simple key=value&key2=value2 encoding
    return data.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

  Map<String, dynamic> _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return {};
    final map = <String, dynamic>{};
    for (final part in payload.split('&')) {
      final idx = part.indexOf('=');
      if (idx > 0) {
        final key = part.substring(0, idx);
        final value = Uri.decodeComponent(part.substring(idx + 1));
        map[key] = value;
      }
    }
    return map;
  }

  void _handleNotificationTap(NotificationResponse response) {
    final data = _decodePayload(response.payload);
    _handleNotificationData(data);
  }

  /// Navigate to the correct screen based on notification type
  void _handleNotificationData(Map<String, dynamic> data) {
    final String type = (data['type'] ?? data['action'] ?? '').toString().toLowerCase();

    // Wait until navigator is ready
    void tryNavigate() {
      final nav = navigatorKey.currentState;
      if (nav == null) {
        // Retry a few times
        Future.delayed(const Duration(milliseconds: 300), tryNavigate);
        return;
      }

      switch (type) {
        case 'bill_created':
        case 'bill_paid':
        case 'bill_partially_paid':
        case 'bill_fine_applied':
        case 'payment_reminder':
        case 'payment':
          nav.pushNamed('/tenant-payments');
          break;

        case 'maintenance_created':
        case 'maintenance_started':
        case 'maintenance_completed':
        case 'maintenance_reminder':
        case 'maintenance':
          nav.pushNamed('/tenant-maintenance');
          break;

        case 'document_reminder':
        case 'efrro_expiry':
        case 'document':
          nav.pushNamed('/tenant-documents');
          break;

        default:
          // Fallback – open tenant home
          nav.pushNamed('/tenant-home');
          break;
      }
    }

    tryNavigate();
  }

  Future<void> _updateAppBadge() async {
    try {
      if (Platform.isIOS) return;

      bool isSupported = false;
      try {
        isSupported = await AppBadgePlus.isSupported();
      } catch (e) {
        return;
      }

      if (!isSupported) return;

      final count = await _api.getUnreadTenantCount();
      final unreadCount = count['unreadCount'] ?? 0;
      await AppBadgePlus.updateBadge(unreadCount is int ? unreadCount : 0);
    } catch (e) {
      // ignore
    }
  }

  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  Future<void> removeToken() async {
    if (_fcmToken != null) {
      await _api.removeFCMToken(token: _fcmToken);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
    await prefs.remove('pending_fcm_token');
    _fcmToken = null;
  }

  /// Call this when the app returns to the foreground
  Future<void> onAppResumed({bool isTenant = true}) async {
    try {
      await NotificationService().refresh(isTenant: isTenant);
      await _updateAppBadge();
    } catch (_) {}
  }
}

/// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final localNotifications = FlutterLocalNotificationsPlugin();

  const androidDetails = AndroidNotificationDetails(
    'livinkey_background_channel',
    'Livinkey Notifications',
    channelDescription: 'Livinkey background notifications',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  const details = NotificationDetails(android: androidDetails);

  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    message.notification?.title ?? 'Livinkey',
    message.notification?.body ?? 'You have a new notification',
    details,
    payload: message.data.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&'),
  );
}