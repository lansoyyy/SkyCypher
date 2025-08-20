import 'package:flutter/material.dart';
import 'package:skycypher/screens/splash_screen.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyCypher',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: app_colors.primary,
      ),
      home: const SplashScreen(),
    );
  }
}
