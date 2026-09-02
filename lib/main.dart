import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:livinkey/screens/tenant/documents_screen.dart';
import 'package:livinkey/screens/tenant/maintenance_screen.dart';
import 'package:livinkey/screens/tenant/payments_screen.dart';
import 'package:livinkey/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/tenant/tenant_screen.dart';
import 'screens/guest/guest_screen.dart';
import 'services/api_service.dart';
import 'models/auth_models.dart';
import 'widgets/livinkey_logo.dart' hide kLivinkeyBlack, kLivinkeyGreen;
import 'services/push_notification_service.dart';
import 'services/notification_service.dart';
import 'widgets/common/unread_notifications_modal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final pushService = PushNotificationService();
  await pushService.initializeFirebaseOnly();

  runApp(const LivinkeyApp());
}

class LivinkeyApp extends StatelessWidget {
  const LivinkeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Livinkey',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        scaffoldBackgroundColor: kLivinkeyBlack,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kLivinkeyGreen,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthGuard(),
      navigatorObservers: [RouteObserver()],
      routes: {
        '/tenant-home': (context) => const TenantScreen(),
        '/tenant-payments': (context) => const PaymentsScreen(),
        '/tenant-maintenance': (context) => const MaintenanceScreen(),
        '/tenant-documents': (context) => const DocumentsScreen(),
      },
    );
  }
}

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> with WidgetsBindingObserver {
  bool _isLoading = true;
  String? _initialRoute;
  final ApiService _api = ApiService();
  bool _isTenant = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground
      _onAppResumed();
    }
  }

  bool _isShowingUnreadModal = false;

  Future<void> _onAppResumed() async {
    if (_initialRoute == 'tenant' || _initialRoute == 'guest') {
      final isTenant = _initialRoute == 'tenant';
      await PushNotificationService().onAppResumed(isTenant: isTenant);
      await NotificationService().refresh(isTenant: isTenant);

      // Show unread modal if there are unread notifications
      await _showUnreadModalIfNeeded(isTenant: isTenant);
    }
  }

  Future<void> _showUnreadModalIfNeeded({required bool isTenant}) async {
    // Wait for the navigator + home screen to be fully ready
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    if (_isShowingUnreadModal) return;

    // Prefer the dedicated unread endpoint (matches the bell badge source)
    List<NotificationModel> unread =
        await NotificationService().fetchUnreadNotifications(isTenant: isTenant);

    // Fallback: if count says there are unread but list is empty, refresh once more
    if (unread.isEmpty && NotificationService().unreadCount > 0) {
      await NotificationService().refresh(isTenant: isTenant);
      unread = await NotificationService()
          .fetchUnreadNotifications(isTenant: isTenant);
      if (unread.isEmpty) {
        // Last resort: use whatever is in the local cache marked unread
        unread = NotificationService().unreadNotifications;
      }
    }

    if (unread.isEmpty) return;

    final nav = navigatorKey.currentState;
    final navContext = navigatorKey.currentContext;
    if (nav == null || navContext == null) return;
    if (!navContext.mounted) return;

    _isShowingUnreadModal = true;
    try {
      await showDialog(
        context: navContext,
        barrierDismissible: true,
        useRootNavigator: true,
        builder: (_) => UnreadNotificationsModal(
          notifications: unread,
          isTenant: isTenant,
          onMarkAllRead: () async {
            await NotificationService().markAllAsRead(isTenant: isTenant);
          },
          onTapNotification: (notification) async {
            await NotificationService()
                .markAsRead(notification.id, isTenant: isTenant);
            _navigateFromNotification(notification);
          },
        ),
      );
    } finally {
      _isShowingUnreadModal = false;
    }
  }

  void _navigateFromNotification(NotificationModel notification) {
    final type = (notification.type ?? '').toLowerCase();
    final nav = navigatorKey.currentState;
    if (nav == null) return;

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
        nav.pushNamed('/tenant-home');
    }
  }

  Future<void> _checkAuth() async {
    await _api.init();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(kStorageToken);
      final userJson = prefs.getString(kStorageUser);
      final role = prefs.getString(kStorageRole);

      if (token != null && token.isNotEmpty && userJson != null) {
        try {
          final user = UserModel.fromJson(jsonDecode(userJson));

          if (role == 'tenant' || user.role == 'tenant') {
            _initialRoute = 'tenant';
            _isTenant = true;
          } else if (role == 'guest' || user.role == 'guest') {
            _initialRoute = 'guest';
            _isTenant = false;
          } else {
            _initialRoute = 'splash';
          }
        } catch (e) {
          _initialRoute = 'splash';
        }
      } else {
        _initialRoute = 'splash';
      }
    } catch (e) {
      _initialRoute = 'splash';
    }

    if (mounted) {
      setState(() => _isLoading = false);

      // After first paint, if user is logged in, refresh + show modal
      if (_initialRoute == 'tenant' || _initialRoute == 'guest') {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await NotificationService().initialize(isTenant: _isTenant);
          await PushNotificationService().initialize();
          await PushNotificationService().retryPendingToken();
          // Force a fresh unread fetch then show modal
          await NotificationService().refresh(isTenant: _isTenant);
          await _showUnreadModalIfNeeded(isTenant: _isTenant);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kLivinkeyBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kLivinkeyGreen),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      );
    }

    switch (_initialRoute) {
      case 'tenant':
        return const TenantScreen();
      case 'guest':
        return const GuestScreen();
      default:
        return const SplashScreen();
    }
  }
}