import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skycypher/screens/login_screen.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.9, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_controller);
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(_controller);

    _controller.forward();

    // Navigate to Home after a short delay
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Image.asset(
              'assets/images/logo.png',
              width: 160,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
