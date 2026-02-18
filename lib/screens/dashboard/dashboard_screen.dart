import '../logbook/logbook_screen.dart';
import 'package:flutter/material.dart';
import '../../core/safety_engine.dart';
import '../../widgets/data_tile.dart';
import '../catch_log/catch_log_screen.dart';
import '../../widgets/safety_map_card.dart';
import '../../services/location_service.dart';
import '../../services/willy_weather_service.dart';
import 'package:geolocator/geolocator.dart';
import '../wind_forecast_screen.dart';
import '../tide_forecast_screen.dart';
import '../swell_forecast_screen.dart';

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
          'temp': '--',
          'warning': 'NIL',
          'forecasts': null,
        };

        if (weatherSnapshot.hasData) {
          data = weatherSnapshot.data!;
        }

        final dynamic rawWind = data['windKnots'];
        final double windSpeedNum = (rawWind is num) ? rawWind.toDouble() : double.tryParse(rawWind.toString()) ?? 0.0;
        final String windDir = data['windDir'] ?? "--";
        
        final verdict = SafetyEngine.getVerdict(widget.isInshore, windSpeedNum);
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
                
                // 1. Safety Verdict Message
                Text(
                  verdict == SafetyVerdict.go ? "GOOD TO LAUNCH" : 
                  (verdict == SafetyVerdict.caution ? "PROCEED WITH CAUTION" : "STAY INSHORE"),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor)
                ),
                
                const SizedBox(height: 10),

                // 2. The Bridge Widget (framing Wind, Temp, Warnings)
                StreamBuilder<Position>(
                  stream: LocationService().getPositionStream(),
                  builder: (context, gpsSnapshot) {
                    final distance = gpsSnapshot.hasData 
                      ? LocationService().getDistanceToRamp(gpsSnapshot.data!.latitude, gpsSnapshot.data!.longitude)
                      : 0.0;
                    
                    return SafetyMapCard(
                      distanceInMeters: distance,
                      temp: data['temp']?.toString() ?? "--",
                      windSpeed: windSpeedNum.toInt().toString(),
                      warning: data['warning'],
                    );
                  },
                ),

                const SizedBox(height: 20),
                
                // 3. Navigation Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _navTile(context, "Wind Trend", "${windSpeedNum.toInt()} kts $windDir", Icons.insights, Colors.blue, 
                        () => _push(context, WindForecastScreen(forecastData: data['forecasts']), data['forecasts'])),
                      
                      _navTile(context, "Tide Details", "View Forecast", Icons.tsunami, Colors.blueAccent, 
                        () => _push(context, TideForecastScreen(forecastData: data['forecasts']), data['forecasts'])),

                      _navTile(context, "Seas & Swell", "View Forecast", Icons.waves, Colors.indigo, 
                        () => _push(context, SwellForecastScreen(forecastData: data['forecasts']), data['forecasts'])),

                      DataTile(label: "Next Tide", value: data['nextTide'] ?? '--', icon: Icons.timer, color: Colors.teal),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CatchLogScreen())),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("RECORD PRIVATE CATCH", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              ],
            ),
          ),
        );
      },
    );
  }

  void _push(BuildContext context, Widget screen, dynamic check) {
    if (check != null) Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _navTile(BuildContext context, String label, String val, IconData icon, Color color, VoidCallback tap) {
    return GestureDetector(onTap: tap, child: DataTile(label: label, value: val, icon: icon, color: color));
  }
}