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
  bool _isFirebaseInitialized = false;
  String? _fcmToken;

  /// ============================================================
  /// NEW: Initialize Firebase only (called from main())
  /// This sets up Firebase without trying to save FCM tokens
  /// ============================================================
  Future<void> initializeFirebaseOnly() async {
    if (_isFirebaseInitialized) return;
    
    try {
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;
    } catch (e) {
      _isFirebaseInitialized = true; // Don't block app startup
    }
  }

  /// ============================================================
  /// FIXED: Initialize push notifications (called AFTER login)
  /// Now the user is authenticated when we save FCM token
  /// ============================================================
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Ensure Firebase is initialized first
      if (!_isFirebaseInitialized) {
        await Firebase.initializeApp();
        _isFirebaseInitialized = true;
      }

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
      }

      _isInitialized = true;
    } catch (e) {
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
    } else {
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
        await _storeFCMToken(_fcmToken!);
      }
    } catch (e) {
    }
  }

  /// ============================================================
  /// FIXED: Store FCM token locally and send to backend
  /// Now this is called AFTER login, so authentication is valid
  /// ============================================================
  Future<void> _storeFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      
      // ============================================================
      // FIXED: Send to backend - user is now authenticated
      // because this is called after login
      // ============================================================
      final response = await _api.updateFCMToken(token);
    } catch (e) {
      // Store token locally as pending, will retry on next login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_fcm_token', token);
    }
  }

  /// ============================================================
  /// NEW: Retry saving pending FCM token after login
  /// ============================================================
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
    }
  }

  /// Setup message handlers
  Future<void> _setupMessageHandlers() async {
    // 1. Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // 2. Background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. App opened from terminated state
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
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
        return;
      }

      // Check if the app badge is supported (Android only)
      bool isSupported = false;
      try {
        isSupported = await AppBadgePlus.isSupported();
      } catch (e) {
        return;
      }

      if (!isSupported) {
        return;
      }

      final count = await _api.getUnreadTenantCount();
      final unreadCount = count['unreadCount'] ?? 0;

      await AppBadgePlus.updateBadge(unreadCount);
    } catch (e) {
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;
    
    // Try to get from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  /// Remove FCM token on logout
  Future<void> removeToken() async {
    if (_fcmToken != null) {
      await _api.removeFCMToken(token: _fcmToken);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
    await prefs.remove('pending_fcm_token');
    _fcmToken = null;
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
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