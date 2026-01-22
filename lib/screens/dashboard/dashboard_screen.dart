import '../logbook/logbook_screen.dart';
import 'package:flutter/material.dart';
import '../../core/safety_engine.dart';
import '../../widgets/data_tile.dart';
import '../catch_log/catch_log_screen.dart';
//import '../../widgets/tide_card.dart';
import '../../widgets/safety_map_card.dart';
import '../../services/location_service.dart';
import '../../services/willy_weather_service.dart'; // Ensure this exists
import 'package:geolocator/geolocator.dart';
class DashboardScreen extends StatefulWidget {
  final bool isInshore;
  const DashboardScreen({super.key, required this.isInshore});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // A unique key to force the FutureBuilder to restart
  Key _refreshKey = UniqueKey();

  void _handleRefresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      key: _refreshKey, // This is the "magic" that triggers the reload
      future: WillyWeatherService().getMarineWeather(),
      builder: (context, weatherSnapshot) {
        
        // ... (Keep all your existing Map data and logic here) ...
        Map<String, dynamic> data = {
          'windKnots': '0.0', 'windDir': '--', 'currentTide': 'Loading...',
          'nextTide': '--', 'swellHeight': '--', 'swellDir': '', 'seas': '--', 'temp': '--',
        };
        if (weatherSnapshot.hasData) {
          data = weatherSnapshot.data!;
        }
        final double windSpeed = double.tryParse(data['windKnots'].toString()) ?? 0.0;
        final String windDir = data['windDir'] ?? "--";
        final verdict = SafetyEngine.getVerdict(widget.isInshore, windSpeed);
        final statusColor = SafetyEngine.getStatusColor(verdict);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text("Seacliff Dashboard"),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Weather",
              onPressed: _handleRefresh, // Triggers the reload
            ),
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

                // If it's loading, show a small progress bar at the top
                if (weatherSnapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 2),
                
                // ... (Rest of your UI: Gauge, GPS, GridView, etc.) ...
                _SafetyGauge(windSpeed: windSpeed, color: statusColor, verdict: verdict),
                const SizedBox(height: 20),

                // GPS TRACKER
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
                
                // Weather Data Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      DataTile(label: "Wind", value: "${windSpeed.toInt()} kts $windDir", icon: Icons.air, color: Colors.blue),
                      DataTile(label: "Current Tide", value: data['currentTide'], icon: Icons.water, color: Colors.cyan),
                      DataTile(label: "Next Tide", value: data['nextTide'], icon: Icons.timer, color: Colors.teal),
                      DataTile(label: "Swell", value: "${data['swellHeight']} ${data['swellDir']}", icon: Icons.waves, color: Colors.indigo),
                      DataTile(label: "Seas", value: data['seas'], icon: Icons.tsunami, color: Colors.blueGrey),
                      DataTile(label: "Temp", value: data['temp'], icon: Icons.thermostat, color: Colors.orange),
                      const DataTile(label: "Bite Status", value: "High", icon: Icons.phishing, color: Colors.green),
                    ],
                  ),
                ),

                // Record Catch Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CatchLogScreen()),
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("RECORD PRIVATE CATCH", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
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
      },
    );
  }
}

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
          // UPDATED LINE BELOW:
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