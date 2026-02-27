import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/safety_engine.dart';
import '../../core/notification_engine.dart'; // Added for Point 4
import '../../services/location_service.dart';
import '../../services/willy_weather_service.dart';
import '../logbook/logbook_screen.dart';
import '../catch_log/catch_log_screen.dart';
import '../wind_forecast_screen.dart';
import '../tide_forecast_screen.dart';
import '../swell_forecast_screen.dart';
import '../fish_gallery_screen.dart';

// --- MODELS & ENUMS ---

enum SpeedUnit { knots, kmh }
enum TempUnit { celsius, fahrenheit }

class Ramp {
  final String name;
  final double lat;
  final double lng;
  Ramp(this.name, this.lat, this.lng);
}

class DashboardScreen extends StatefulWidget {
  final bool isInshore;
  const DashboardScreen({super.key, required this.isInshore});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _weatherFuture;
  double _currentSpeedKnots = 0.0;

  SpeedUnit _speedUnit = SpeedUnit.knots;
  TempUnit _tempUnit = TempUnit.celsius;
  
  final List<Ramp> _saRamps = [
    Ramp("Seacliff", -35.0436, 138.5194),
    Ramp("North Haven", -34.7939, 138.4844),
    Ramp("O'Sullivan Beach", -35.1278, 138.4689),
    Ramp("West Beach", -34.9383, 138.4994),
    Ramp("Edithburgh", -35.0833, 137.7500),
  ];
  late Ramp _selectedRamp;

  @override
  void initState() {
    super.initState();
    _selectedRamp = _saRamps[0];
    _weatherFuture = _fetchWeatherAndCheckMatches(); // Point 4: Initial check
    _initSpeedometer();
  }

  // Point 4: Helper to wrap the weather fetch with the notification check
  Future<Map<String, dynamic>> _fetchWeatherAndCheckMatches() async {
    final data = await WillyWeatherService().getMarineWeather();
    _checkForFishingMatch(data);
    return data;
  }

  void _initSpeedometer() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentSpeedKnots = position.speed * 1.94384;
        });
      }
    });
  }

  void _handleRefresh() {
    setState(() {
      _weatherFuture = _fetchWeatherAndCheckMatches(); // Point 4: Refresh check
    });
  }

  // Point 4: Notification logic integration
  void _checkForFishingMatch(Map<String, dynamic> liveData) async {
    String? alertMessage = await NotificationEngine.checkConditions(liveData);
    
    if (alertMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.stars, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(alertMessage)),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: "LOGBOOK", 
            textColor: Colors.white,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LogbookScreen())),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherFuture,
      builder: (context, weatherSnapshot) {
        Map<String, dynamic> data = {
          'windKnots': 0,
          'windDir': '--',
          'temp': 0,
          'warning': 'NIL',
          'forecasts': null,
        };

        if (weatherSnapshot.hasData) {
          data = weatherSnapshot.data!;
        }

        final double windSpeedNum = (data['windKnots'] is num) ? data['windKnots'].toDouble() : 0.0;
        final verdict = SafetyEngine.getVerdict(widget.isInshore, windSpeedNum);
        final statusColor = SafetyEngine.getStatusColor(verdict);

        final Color bgColor = verdict == SafetyVerdict.go 
            ? const Color(0xFFF1F5F9) 
            : (verdict == SafetyVerdict.caution ? Colors.yellow.shade100 : Colors.red.shade100);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: Text(_selectedRamp.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            leading: IconButton(icon: const Icon(Icons.refresh, size: 28), onPressed: _handleRefresh),
            actions: [
              if (data['warning'] != 'NIL')
                IconButton(
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 34),
                  onPressed: () => _showWarningPopup(context, data['warning']),
                ),
              PopupMenuButton(
                icon: const Icon(Icons.settings, size: 28),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text("Speed: ${_speedUnit.name.toUpperCase()}"),
                    onTap: () => setState(() => _speedUnit = _speedUnit == SpeedUnit.knots ? SpeedUnit.kmh : SpeedUnit.knots),
                  ),
                  PopupMenuItem(
                    child: Text("Temp: ${_tempUnit.name.toUpperCase()}"),
                    onTap: () => setState(() => _tempUnit = _tempUnit == TempUnit.celsius ? TempUnit.fahrenheit : TempUnit.celsius),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (weatherSnapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 2),
                
                Text(
                  verdict == SafetyVerdict.go ? "GOOD TO LAUNCH" : (verdict == SafetyVerdict.caution ? "PROCEED WITH CAUTION" : "STAY INSHORE"),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: statusColor),
                ),
                const SizedBox(height: 15),

                StreamBuilder<Position>(
                  stream: LocationService().getPositionStream(),
                  builder: (context, gpsSnapshot) {
                    final distance = gpsSnapshot.hasData 
                        ? LocationService().getDistanceToRamp(gpsSnapshot.data!.latitude, gpsSnapshot.data!.longitude) 
                        : 0.0;

                    return Row(
                      children: [
                        Expanded(
                          child: _BriefHeaderCard(
                            label: "To Ramp",
                            value: "${(distance / 1000).toStringAsFixed(1)} km",
                            icon: Icons.place,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BriefHeaderCard(
                            label: "Boat Speed",
                            value: _formatSpeed(_currentSpeedKnots),
                            icon: Icons.speed,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    _LargeNavTile(
                      label: "Wind",
                      value: "${windSpeedNum.toInt()} kts ${data['windDir']}",
                      icon: Icons.air,
                      color: Colors.blue,
                      onTap: () => _push(context, WindForecastScreen(forecastData: data['forecasts'])),
                    ),
                    _LargeNavTile(
                      label: "Seas & Swell",
                      value: "View Forecast",
                      icon: Icons.waves,
                      color: Colors.indigo,
                      onTap: () => _push(context, SwellForecastScreen(forecastData: data['forecasts'])),
                    ),
                    _LargeNavTile(
                      label: "Tides",
                      value: data['nextTide'] ?? "Forecast",
                      icon: Icons.tsunami,
                      color: Colors.blueAccent,
                      onTap: () => _push(context, TideForecastScreen(forecastData: data['forecasts'])),
                    ),
                    _LargeNavTile(
                      label: "Fish Gallery",
                      value: "Species Info",
                      icon: Icons.set_meal,
                      color: Colors.orange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FishGalleryScreen())),
                    ),
                    _LargeNavTile(
                      label: "Temp",
                      value: _formatTemp((data['temp'] as num).toDouble()),
                      icon: Icons.thermostat,
                      color: Colors.deepOrange,
                      onTap: () {},
                    ),
                    _LargeNavTile(
                      label: "Change Ramp",
                      value: _selectedRamp.name,
                      icon: Icons.anchor,
                      color: Colors.teal,
                      onTap: () => _showRampSelector(context),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                
                // PRIMARY ACTION
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => CatchLogScreen(currentWeatherData: data))
                  ),
                  icon: const Icon(Icons.add_circle, size: 28),
                  label: const Text("RECORD PRIVATE CATCH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 70),
                    backgroundColor: const Color(0xFF004E92),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),

                const SizedBox(height: 10),

                // SECONDARY ACTION (HISTORY)
                TextButton(
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const LogbookScreen())
                  ),
                  child: const Text(
                    "VIEW MY LOGBOOK & HISTORY", 
                    style: TextStyle(
                      color: Colors.blueGrey, 
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline
                    )
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatSpeed(double s) => _speedUnit == SpeedUnit.kmh 
      ? "${(s * 1.852).toStringAsFixed(1)} km/h" 
      : "${s.toStringAsFixed(1)} kts";

  String _formatTemp(double t) => _tempUnit == TempUnit.fahrenheit 
      ? "${((t * 9/5) + 32).toStringAsFixed(0)}°F" 
      : "${t.toStringAsFixed(0)}°C";

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _showWarningPopup(BuildContext context, String warning) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 10), Text("Weather Warning")]),
        content: Text(warning),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))],
      ),
    );
  }

  void _showRampSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _saRamps.length,
          itemBuilder: (context, i) => ListTile(
            leading: const Icon(Icons.anchor),
            title: Text(_saRamps[i].name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            onTap: () {
              setState(() => _selectedRamp = _saRamps[i]);
              _handleRefresh(); // Point 4: Trigger refresh check on ramp change
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}

class _BriefHeaderCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _BriefHeaderCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _LargeNavTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _LargeNavTile({required this.label, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}