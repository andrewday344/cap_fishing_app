import '../logbook/logbook_screen.dart';
import 'package:flutter/material.dart';
import '../../core/safety_engine.dart';
import '../../widgets/data_tile.dart';
import '../catch_log/catch_log_screen.dart'; // Import the new screen
import '../../widgets/tide_card.dart';
import '../../widgets/safety_map_card.dart';
import '../../services/location_service.dart';
import 'package:geolocator/geolocator.dart'; // REQUIRED for the Position type


class DashboardScreen extends StatelessWidget {
  final bool isInshore;
  const DashboardScreen({super.key, required this.isInshore});

  @override
  Widget build(BuildContext context) {
    // Mock Data for Seacliff
    const double windSpeed = 18.0; 
    final verdict = SafetyEngine.getVerdict(isInshore, windSpeed);
    final statusColor = SafetyEngine.getStatusColor(verdict);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Seacliff Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "View Private Logbook",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LogbookScreen()), // Cleaned up
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _SafetyGauge(windSpeed: windSpeed, color: statusColor, verdict: verdict),
            const SizedBox(height: 20),
            const TideCard(),            
            const SizedBox(height: 12),

            // REAL-TIME GPS TRACKER
            StreamBuilder<Position>(
              stream: LocationService().getPositionStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text("GPS Error: Check Permissions");
                }
                
                if (!snapshot.hasData) {
                  // While waiting for the first GPS fix
                  return const SafetyMapCard(distanceInMeters: 0);
                }

                final position = snapshot.data!;
                final distance = LocationService().getDistanceToRamp(
                  position.latitude, 
                  position.longitude
                );

                return SafetyMapCard(distanceInMeters: distance);
              },
            ),

            const SafetyMapCard(distanceInMeters: 2400), // Mocked at 2.4km for now

            const SizedBox(height: 20),
            
            // 2. Weather Data Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: const [
                  DataTile(label: "Wind", value: "18 kts", icon: Icons.air, color: Colors.blue),
                  DataTile(label: "Tide", value: "0.9m Low", icon: Icons.water, color: Colors.cyan),
                  DataTile(label: "Swell", value: "0.4m", icon: Icons.waves, color: Colors.indigo),
                  DataTile(label: "Bite Status", value: "High", icon: Icons.phishing, color: Colors.green),
                ],
              ),
            ),

            // 3. The "Record Catch" Button (Restored)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Standard Flutter navigation to the Catch Log
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CatchLogScreen()),
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("RECORD PRIVATE CATCH", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60), // Tall button for easy tapping
                  backgroundColor: const Color(0xFF004E92),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Private helper for the Gauge
class _SafetyGauge extends StatelessWidget {
  final double windSpeed;
  final Color color;
  final SafetyVerdict verdict;

  const _SafetyGauge({required this.windSpeed, required this.color, required this.verdict});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          verdict == SafetyVerdict.go ? "GOOD TO LAUNCH" : 
          verdict == SafetyVerdict.caution ? "PROCEED WITH CAUTION" : "STAY INSHORE",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)
        ),
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 70,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("${windSpeed.toInt()}", 
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color)),
              Text("KNOTS", style: TextStyle(fontSize: 14, color: color)),
            ],
          ),
        ),
      ],
    );
  }
}