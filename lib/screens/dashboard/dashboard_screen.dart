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
import '../wind_forecast_screen.dart';
import '../tide_forecast_screen.dart';
import '../swell_forecast_screen.dart'; // <--- Added this import

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
        
        Map<String, dynamic> data = {
          'windKnots': 0, 
          'windDir': '--', 
          'currentTide': '--',
          'nextTide': '--', 
          'swellHeight': '--', 
          'swellDir': '', 
          'seas': '--', 
          'temp': '--',
          'forecasts': null,
        };

        if (weatherSnapshot.hasData) {
          data = weatherSnapshot.data!;
        }

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
                      // WIND TREND
                      GestureDetector(
                        onTap: () {
                          if (data['forecasts'] != null) {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => WindForecastScreen(forecastData: data['forecasts'])
                              )
                            );
                          }
                        },
                        child: DataTile(
                          label: "Wind Trend", 
                          value: "${windSpeed.toInt()} kts $windDir", 
                          icon: Icons.insights, 
                          color: Colors.blue
                        ),
                      ),
                      
                      // TIDE DETAILS
                      GestureDetector(
                        onTap: () {
                          if (data['forecasts'] != null) {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => TideForecastScreen(forecastData: data['forecasts']),
                              ),
                            );
                          }
                        },
                        child: DataTile(
                          label: "Tide Details", 
                          value: data['forecasts'] != null ? "View Forecast" : "Loading...",
                          icon: Icons.tsunami, 
                          color: Colors.blueAccent,
                        ),
                      ),

                      // SEAS & SWELL (Merged for order: Seas before Swell)
                      GestureDetector(
                        onTap: () {
                          if (data['forecasts'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SwellForecastScreen(forecastData: data['forecasts']),
                              ),
                            );
                          }
                        },
                        child: DataTile(
                          label: "Seas & Swell", 
                          value: data['forecasts'] != null ? "View Forecast" : "Loading...", 
                          icon: Icons.waves, 
                          color: Colors.indigo
                        ),
                      ),

                      DataTile(label: "Next Tide", value: data['nextTide'] ?? '--', icon: Icons.timer, color: Colors.teal),
                      DataTile(label: "Temp", value: "${data['temp'] ?? '--'}°C", icon: Icons.thermostat, color: Colors.orange),

                      // FISH GALLERY
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
                
                Text(
                  "Last Updated: ${data['lastUpdated'] ?? '--'}",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
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
          // Fixed: replaced withOpacity with withValues
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