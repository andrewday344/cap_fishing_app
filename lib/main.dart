import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:c_a_p/screens/dashboard/dashboard_screen.dart'; 

void main() async {
  // 1. Essential for any async work in main
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Fix for Desktop/Emulator testing
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  } catch (e) {
    debugPrint("Database initialization warning: $e");
  }

  // 3. Launch the app
  runApp(const SeacliffApp());
}

class SeacliffApp extends StatelessWidget {
  const SeacliffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seacliff Fishing App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004E92)),
        useMaterial3: true,
      ),
      // Use true for SA South Coast/Inshore safety logic
      home: const DashboardScreen(isInshore: true), 
    );
  }
}