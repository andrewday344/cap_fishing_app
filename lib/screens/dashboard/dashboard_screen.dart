import '../logbook/logbook_screen.dart';
import 'package:flutter/material.dart';
import '../../core/safety_engine.dart';
import '../../widgets/data_tile.dart';
//import '../catch_log/catch_log_screen.dart'; // Import the new screen
//import '../../widgets/tide_card.dart';
import '../../widgets/safety_map_card.dart';
import '../../services/location_service.dart';
import 'package:geolocator/geolocator.dart'; // REQUIRED for the Position type
import '../../services/willy_weather_service.dart';

class DashboardScreen extends StatelessWidget {
  final bool isInshore;
  const DashboardScreen({super.key, required this.isInshore});

  @override
  Widget build(BuildContext context) {
    // 2. We use a FutureBuilder to wrap the whole screen or just the data parts
    return FutureBuilder<Map<String, dynamic>>(
      future: WillyWeatherService().getMarineWeather(), // Call the service
      builder: (context, weatherSnapshot) {
        
        // Default values while loading or on error
        double windSpeed = 0.0;
        String windDir = "--";
        String tideInfo = "Loading...";

        if (weatherSnapshot.hasData) {
          final data = weatherSnapshot.data!;
          windSpeed = double.tryParse(data['windKnots'] ?? '0') ?? 0.0;
          windDir = data['windDir'] ?? "";
          tideInfo = "Next: ${data['tideStatus']}";
        }

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
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LogbookScreen())),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Live Wind Gauge
                _SafetyGauge(windSpeed: windSpeed, color: statusColor, verdict: verdict),
                
                const SizedBox(height: 20),
                Text(tideInfo, style: const TextStyle(fontWeight: FontWeight.bold)), 
                const SizedBox(height: 12),

                // YOUR EXISTING GPS STREAM
                StreamBuilder<Position>(
                  stream: LocationService().getPositionStream(),
                  builder: (context, gpsSnapshot) {
                    final distance = gpsSnapshot.hasData 
                      ? LocationService().getDistanceToRamp(gpsSnapshot.data!.latitude, gpsSnapshot.data!.longitude)
                      : 0.0;
                    return SafetyMapCard(distanceInMeters: distance);
                  },
                ),

                const SizedBox(height: 20),
                
                // Weather Data Grid with LIVE WillyWeather values
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      DataTile(label: "Wind", value: "${windSpeed.toInt()} kts $windDir", icon: Icons.air, color: Colors.blue),
                      DataTile(label: "Tide", value: tideInfo, icon: Icons.water, color: Colors.cyan),
                      const DataTile(label: "Swell", value: "0.4m", icon: Icons.waves, color: Colors.indigo),
                      const DataTile(label: "Bite Status", value: "High", icon: Icons.phishing, color: Colors.green),
                    ],
                  ),
                ),

                // Record Catch Button... (Keep your existing button code here)
              ],
            ),
          ),
        );
      }
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