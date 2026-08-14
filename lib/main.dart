// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'widgets/livinkey_logo.dart';

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
      home: const SplashScreen(),
      // Add navigation observers for better route management
      navigatorObservers: [RouteObserver()],
    );
  }
}