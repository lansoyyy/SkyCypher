import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:skycypher/firebase_options.dart';
import 'package:skycypher/widgets/auth_wrapper.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;
import 'package:skycypher/services/aircraft_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: 'skycypher-d55ee',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize default aircraft data
  await AircraftService.initializeDefaultAircraft();

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
      home: const AuthWrapper(),
    );
  }
}
