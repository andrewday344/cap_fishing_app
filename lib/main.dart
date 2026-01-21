import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('catches');
  runApp(const SeacliffApp()); // Ensure this name matches the class below
}

class SeacliffApp extends StatelessWidget {
  const SeacliffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seacliff Fishing',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // FIX: Added the isInshore parameter here
      home: const DashboardScreen(isInshore: true), 
    );
  }
}