import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PushNotificationService {
  static final PushNotificationService _instance = 
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // ============================================================
  // FIXED: Changed from eager field to lazy getter
  // Now FirebaseMessaging.instance is only accessed AFTER
  // Firebase.initializeApp() has been called
  // ============================================================
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  final ApiService _api = ApiService();
  bool _isInitialized = false;
  String? _fcmToken;

  /// Initialize push notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // ============================================================
      // CRITICAL: Initialize Firebase FIRST before anything else
      // ============================================================
      await Firebase.initializeApp();

      // Skip Firebase Messaging on web
      if (!kIsWeb) {
        // Request permissions
        await _requestPermissions();

        // Initialize local notifications
        await _initializeLocalNotifications();

        // Get FCM token
        await _getFCMToken();

        // Setup message handlers
        await _setupMessageHandlers();
      } else {
        print('⚠️ Firebase Messaging skipped on web platform');
      }

      _isInitialized = true;
      print('✅ Push Notification Service initialized');
    } catch (e) {
      print('❌ Push Notification initialization error: $e');
      _isInitialized = true; // Don't block app startup
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('⚠️ Notification permissions not granted');
    } else {
      print('✅ Notification permissions granted');
    }

    if (Platform.isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  /// Get and store FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _fcm.getToken();
      if (_fcmToken != null) {
        print('✅ FCM Token: $_fcmToken');
        await _storeFCMToken(_fcmToken!);
      }
    } catch (e) {
      print('❌ Failed to get FCM token: $e');
    }
  }

  /// Store FCM token locally and send to backend
  Future<void> _storeFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      
      // Send to backend
      await _api.updateFCMToken(token);
    } catch (e) {
      print('❌ Failed to store FCM token: $e');
    }
  }

  /// Setup message handlers
  Future<void> _setupMessageHandlers() async {
    // 1. Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Foreground message received');
      _handleForegroundMessage(message);
    });

    // 2. Background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. App opened from terminated state
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      print('📱 App opened from terminated state');
      _handleNotificationData(initialMessage.data);
    }

    // 4. App opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App opened from background');
      _handleNotificationData(message.data);
    });

    // 5. Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token refreshed');
      _storeFCMToken(newToken);
    });
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);
    
    // Refresh in-app notifications
    _api.getTenantNotifications().then((_) {
      // Notification service will update automatically
    });
  }

  /// Show local notification (for foreground)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final String title = message.notification?.title ?? 'Livinkey';
    final String body = message.notification?.body ?? 'You have a new notification';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: message.data['action'] ?? 'open',
    );

    // Update app badge
    await _updateAppBadge();
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = {'action': response.payload!};
      _handleNotificationData(data);
    }
  }

  /// Handle notification data (navigate to appropriate screen)
  void _handleNotificationData(Map<String, dynamic> data) {
    final String type = data['type'] ?? '';
    
    if (navigatorKey.currentContext == null) return;

    // Navigate based on notification type
    switch (type) {
      case 'bill_created':
      case 'bill_paid':
      case 'bill_partially_paid':
      case 'bill_fine_applied':
      case 'payment_reminder':
        navigatorKey.currentState!.pushNamed('/tenant-payments');
        break;
      
      case 'maintenance_created':
      case 'maintenance_started':
      case 'maintenance_completed':
        navigatorKey.currentState!.pushNamed('/tenant-maintenance');
        break;
      
      case 'document_reminder':
      case 'efrro_expiry':
        navigatorKey.currentState!.pushNamed('/tenant-documents');
        break;
      
      default:
        navigatorKey.currentState!.pushNamed('/tenant-home');
        break;
    }
  }

  /// Update app icon badge
  Future<void> _updateAppBadge() async {
    try {
      // Skip badge update on iOS (handled natively by APNs)
      if (Platform.isIOS) {
        print('⚠️ App badge handled by iOS system');
        return;
      }

      // Check if the app badge is supported (Android only)
      bool isSupported = false;
      try {
        isSupported = await AppBadgePlus.isSupported();
      } catch (e) {
        print('⚠️ App badge not supported: $e');
        return;
      }

      if (!isSupported) {
        print('⚠️ App badge not supported on this device');
        return;
      }

      final count = await _api.getUnreadTenantCount();
      final unreadCount = count['unreadCount'] ?? 0;

      await AppBadgePlus.updateBadge(unreadCount);
    } catch (e) {
      print('❌ Failed to update app badge: $e');
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    return _fcmToken;
  }

  /// Remove FCM token on logout
  Future<void> removeToken() async {
    if (_fcmToken != null) {
      await _api.removeFCMToken(token: _fcmToken);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 Background message received');
  
  final FlutterLocalNotificationsPlugin localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'livinkey_background_channel',
    'Livinkey Notifications',
    channelDescription: 'Livinkey background notifications',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
  );

  await localNotifications.show(
    DateTime.now().millisecond,
    message.notification?.title ?? 'Livinkey',
    message.notification?.body ?? 'You have a new notification',
    details,
    payload: message.data['action'] ?? 'open',
  );
}