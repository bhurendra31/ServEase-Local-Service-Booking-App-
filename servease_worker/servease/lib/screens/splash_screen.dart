import 'dart:async';
import 'package:flutter/material.dart';

// 🔽 IMPORTANT: import AuthGate
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // ⏳ Splash duration
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        _slideRoute(const AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A90E2),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🟦 APP LOGO
            Image.asset(
              'assets/images/logo.png', // 🔴 CHANGE if path is different
              height: 150,
            ),

            const SizedBox(height: 10),

            // 🟦 APP NAME
            const Text(
              'ServEase',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 6),

            // 🟦 SUBTITLE
            const Text(
              'Local Service Booking App...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= SLIDE ANIMATION ROUTE =================
PageRouteBuilder _slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 1050),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // 👉 slide from right
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
