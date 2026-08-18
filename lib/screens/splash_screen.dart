import 'package:flutter/material.dart';
import '../widgets/livinkey_logo.dart';
import 'get_started_screen.dart';
import 'auth/login_screen.dart';
import '../services/audio_service.dart';
import '../services/api_service.dart';
import 'tenant/tenant_screen.dart';
import 'guest/guest_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _keyRotation;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playBackgroundMusic();
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9500),
    );

    _keyRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _startSequence();
  }

  Future<void> _playBackgroundMusic() async {
    await AudioService.playBackgroundMusic('splash_screen.mp3');
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await _controller.forward();

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    if (mounted) {
      // ============================================================
      // FIXED: Check if user is already logged in
      // ============================================================
      await _api.init();
      final isLoggedIn = await _api.isLoggedIn();
      
      if (isLoggedIn) {
        final role = await _api.getStoredRole();
        if (role == 'tenant') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TenantScreen()),
          );
        } else if (role == 'guest') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GuestScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GetStartedScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double logoWidth = (screenWidth * 0.72).clamp(220.0, 420.0);

    return Scaffold(
      backgroundColor: kLivinkeyBlack,
      body: Center(
        child: LivinkeyLogo(
          keyAnimation: _keyRotation,
          width: logoWidth,
        ),
      ),
    );
  }
}