import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Ensure Hive is imported here
import 'package:c_a_p/screens/dashboard/dashboard_screen.dart'; 
import 'package:c_a_p/services/database_service.dart';
import 'package:c_a_p/models/vessel_profile.dart'; // Import the model


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Hive.initFlutter();
    
    // Register Adapter only if it hasn't been yet
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(VesselProfileAdapter());
    }
    
    // Open the box
    await Hive.openBox<VesselProfile>('vessel_profile');
    
    // Initialize DB Service
    await DatabaseService.instance.init();
    
  } catch (e) {
    // If Hive fails on web, we print the error but still start the app
    debugPrint("Startup Error: $e");
  }

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