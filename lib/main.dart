import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:c_a_p/screens/dashboard/dashboard_screen.dart'; 
import 'package:c_a_p/services/database_service.dart';
import 'package:c_a_p/models/vessel_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  String debugStatus = "Starting...";

  
    await Hive.openBox('settings');
  
  try {
    debugStatus = "Initializing Hive...";
    await Hive.initFlutter();
    
    debugStatus = "Registering Adapters...";
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(VesselProfileAdapter());
    }
    debugStatus = "Opening Vessel Box...";
    try {
      // Try to open it normally
      await Hive.openBox<VesselProfile>('vessel_profile');
    } catch (e) {
      // If it fails (likely due to the null/String error), wipe it and start fresh
      debugPrint("Box corrupted or schema mismatch. Resetting... $e");
      await Hive.deleteBoxFromDisk('vessel_profile'); 
      await Hive.openBox<VesselProfile>('vessel_profile');
    }
    debugStatus = "Opening Vessel Box...";
    await Hive.openBox<VesselProfile>('vessel_profile');
    
    debugStatus = "Initializing Database Service...";
    await DatabaseService.instance.init();
    
    runApp(const SeacliffApp());
  } catch (e) {
    // IF THE APP CRASHES, SHOW THE ERROR ON SCREEN INSTEAD OF A WHITE PAGE
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text("FATAL ERROR at $debugStatus\n\n$e", 
                 style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ),
      ),
    ));
  }
}

class SeacliffApp extends StatelessWidget {
  const SeacliffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conditions Are Perfect Fishing App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004E92)),
        useMaterial3: true,
      ),
      home: const DashboardScreen(isInshore: true), 
    );
  }
}