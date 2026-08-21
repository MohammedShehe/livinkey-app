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

// NEW: Import push notification service
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ============================================================
  // FIXED: Initialize Firebase only, NOT the full push service
  // PushNotificationService.initialize() will be called AFTER login
  // so the user is authenticated when saving FCM token.
  // ============================================================
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
      // NEW: Use the global navigator key for navigation from notifications
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
      // NEW: Named routes for navigation from notifications
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

class _AuthGuardState extends State<AuthGuard> {
  bool _isLoading = true;
  String? _initialRoute;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
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
          } else if (role == 'guest' || user.role == 'guest') {
            _initialRoute = 'guest';
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