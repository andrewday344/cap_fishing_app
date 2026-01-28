import '../logbook/logbook_screen.dart';
import 'package:flutter/material.dart';
import '../../core/safety_engine.dart';
import '../../widgets/data_tile.dart';
import '../catch_log/catch_log_screen.dart';
import '../../widgets/safety_map_card.dart';
import '../../services/location_service.dart';
import '../../services/willy_weather_service.dart';
import 'package:geolocator/geolocator.dart';
import '../fish_gallery_screen.dart';
import '../wind_detail_screen.dart';
import '../tide_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isInshore;
  const DashboardScreen({super.key, required this.isInshore});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Key _refreshKey = UniqueKey();

  void _handleRefresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      key: _refreshKey,
      future: WillyWeatherService().getMarineWeather(),
      builder: (context, weatherSnapshot) {
        
        // 1. Initialize data with default values
        Map<String, dynamic> data = {
          'windKnots': 0, 
          'windDir': '--', 
          'currentTide': '--',
          'nextTide': '--', 
          'swellHeight': '--', 
          'swellDir': '', 
          'seas': '--', 
          'temp': '--',
          'forecasts': null, // Important: Initialize as null
        };

        // 2. If data is loaded, use it
        if (weatherSnapshot.hasData) {
          data = weatherSnapshot.data!;

          debugPrint("DASHBOARD DATA KEYS: ${data.keys.toList()}");
          debugPrint("FORECAST DATA EXISTS: ${data['forecasts'] != null}");
        }

        // 3. Extract variables safely
        final dynamic rawWind = data['windKnots'];
        final double windSpeed = (rawWind is num) ? rawWind.toDouble() : double.tryParse(rawWind.toString()) ?? 0.0;
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
              onPressed: _handleRefresh,
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
                if (weatherSnapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 2),
                
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
                
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      // WIND TILE
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => WindDetailScreen(weatherData: data))
                        ),
                        child: DataTile(
                          label: "Wind", 
                          value: "${windSpeed.toInt()} kts $windDir", 
                          icon: Icons.air, 
                          color: Colors.blue
                        ),
                      ),
                      
                      // TIDE TILE
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => TideDetailScreen(weatherData: data))
                        ),
                          child: DataTile(
                          label: "Tide", 
                          //value: "View Forecast", 
                          value: data['forecasts'] != null ? "Ready" : "Missing Forecasts",
                          icon: Icons.tsunami, 
                          color: Colors.blueAccent
                        ),
                      ),

                      DataTile(label: "Next Tide", value: data['nextTide'] ?? '--', icon: Icons.timer, color: Colors.teal),
                      DataTile(label: "Swell", value: "${data['swellHeight'] ?? '--'} ${data['swellDir'] ?? ''}", icon: Icons.waves, color: Colors.indigo),
                      DataTile(label: "Seas", value: data['seas'] ?? '--', icon: Icons.tsunami, color: Colors.blueGrey),
                      DataTile(label: "Temp", value: "${data['temp'] ?? '--'}°C", icon: Icons.thermostat, color: Colors.orange),

                      // FISH GALLERY TILE
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const FishGalleryScreen())
                        ),
                        child: const DataTile(
                          label: "Fish Gallery", 
                          value: "Limits & Sizes", 
                          icon: Icons.set_meal, 
                          color: Colors.green
                        ),
                      ),
                    ],
                  ),
                ),

                // RECORD CATCH BUTTON
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
    String message = "STAY INSHORE";
    if (verdict == SafetyVerdict.go) message = "GOOD TO LAUNCH";
    if (verdict == SafetyVerdict.caution) message = "PROCEED WITH CAUTION";

    return Column(
      children: [
        Text(
          message,
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