import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:livinkey/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/tenant/tenant_screen.dart';
import 'screens/guest/guest_screen.dart';
import 'services/api_service.dart';
import 'models/auth_models.dart';
import 'widgets/livinkey_logo.dart' hide kLivinkeyBlack, kLivinkeyGreen;

void main() {
  runApp(const LivinkeyApp());
}

class LivinkeyApp extends StatelessWidget {
  const LivinkeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Livinkey',
      debugShowCheckedModeBanner: false,
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
    );
  }
}

// ============================================================
// FIXED: AuthGuard handles auto-login
// ============================================================
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
          
          // Determine which screen to show based on role
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

    // Navigate to the appropriate screen
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