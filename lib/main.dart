import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Ensure Hive is imported here
import 'package:c_a_p/screens/dashboard/dashboard_screen.dart'; 
import 'package:c_a_p/services/database_service.dart';
import 'package:c_a_p/models/vessel_profile.dart'; // Import the model

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Ensure Hive is ready
  
  // 1. Initialize your custom database service
  await DatabaseService.instance.init();

  // 2. Register and OPEN the vessel box before running the app
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(VesselProfileAdapter());
  }
  await Hive.openBox<VesselProfile>('vessel_profile'); 

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
      home: const DashboardScreen(isInshore: true), 
    );
  }
}