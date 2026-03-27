import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Ensure Hive is imported here
import 'package:c_a_p/screens/dashboard/dashboard_screen.dart'; 
import 'package:c_a_p/services/database_service.dart';
import 'package:c_a_p/models/vessel_profile.dart'; // Import the model

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive (via your service)
  await DatabaseService.instance.init();

  // 2. Register the new Vessel Adapter
  // This is the "Step 3" that links your generated g.dart file to the database
  Hive.registerAdapter(VesselProfileAdapter());

  // 3. Open the Vessel Box
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