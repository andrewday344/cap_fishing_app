import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Replace 'c_a_p' with your actual package name from pubspec.yaml if different
import 'package:c_a_p/screens/dashboard/dashboard_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('catches');
  runApp(const SeacliffApp());
}

class SeacliffApp extends StatelessWidget {
  const SeacliffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(isInshore: true), // This will now recognize the class [cite: 973]
    );
  }
}