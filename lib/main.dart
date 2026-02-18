import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Use the package: path instead of the relative path to be safe
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
      debugShowCheckedModeBanner: false, // Cleaner look for your dashboard
      title: 'Seacliff Fishing',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Ensure the name here matches exactly: DashboardScreen
      home: const DashboardScreen(isInshore: true), 
    );
  }
}