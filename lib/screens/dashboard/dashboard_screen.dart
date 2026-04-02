import 'dart:math' as math; 
import '../vessel/vessel_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import '../../core/safety_engine.dart';
import '../../core/notification_engine.dart'; 
import '../../services/willy_weather_service.dart';
import '../../services/database_service.dart';
import '../../models/safety_item_model.dart';
import '../../models/vessel_log_model.dart';
import '../../models/vessel_profile.dart'; 
import '../logbook/logbook_screen.dart';
import '../catch_log/catch_log_screen.dart';
import '../wind_forecast_screen.dart';
import '../tide_forecast_screen.dart';
import '../fish_gallery_screen.dart';
import '../safety/safety_equipment_screen.dart';
import '../safety/pre_launch_screen.dart';
import '../vessel/vessel_log_screen.dart';

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
  late Box<VesselProfile> _vesselBox; 
  
  double _currentSpeedKnots = 0.0;
  SpeedUnit _speedUnit = SpeedUnit.knots;
  TempUnit _tempUnit = TempUnit.celsius;

  List<SafetyItem> _safetyGear = [];
  List<VesselLog> _vesselLogs = [];
  bool _isDataLoading = true;
  
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
    _vesselBox = Hive.box<VesselProfile>('vessel_profile');
    _weatherFuture = _fetchWeatherAndCheckMatches(); 
    _initSpeedometer();
    _loadVesselData();
  }

  // --- SAFETY LOGIC ---
  List<String> _getSafetyWarnings(VesselProfile vessel, Map<String, dynamic>? forecasts) {
    List<String> warnings = [];
    if (forecasts == null || forecasts['wind'] == null) return warnings;

    final windForecast = forecasts['wind'] as List<dynamic>;
    final swellForecast = forecasts['swell'] as List<dynamic>?;
    
    if (windForecast.isEmpty) return warnings;

    final nowWind = (windForecast.first['speed'] ?? 0) / 1.852;
    final double nowSwell = (swellForecast != null && swellForecast.isNotEmpty) 
        ? (swellForecast.first['height'] ?? 0.0) : 0.0;

    for (int i = 1; i < math.min(windForecast.length, 7); i++) {
      final futureWind = (windForecast[i]['speed'] ?? 0) / 1.852;
      
      double windPct = ((futureWind - nowWind) / nowWind) * 100;
      
      if (windPct >= (vessel.windIncreaseThreshold ?? 30.0) && nowWind > 5) {
        warnings.add("Wind increasing ${windPct.toStringAsFixed(0)}% in ${i}h.");
        break;
      }

      if (swellForecast != null && swellForecast.length > i) {
        double futureSwell = swellForecast[i]['height'] ?? 0.0;
        double swellDiff = futureSwell - nowSwell;
        
        if (swellDiff >= (vessel.swellIncreaseThreshold ?? 0.5)) {
          warnings.add("Swell rising ${swellDiff.toStringAsFixed(1)}m in ${i}h.");
          break;
        }
      }
    }

    if (vessel.notificationsEnabled ?? true) {
      final hour = DateTime.now().hour;
      if (hour >= 17 || hour <= 5) {
        warnings.add("Low light conditions. Night launch not recommended.");
      }
    }

    return warnings;
  }

  Widget _buildSafetyAlerts(VesselProfile vessel, Map<String, dynamic>? forecasts) {
    final warnings = _getSafetyWarnings(vessel, forecasts);
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(25),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notification_important, color: Colors.orange.shade900),
              const SizedBox(width: 8),
              Text("SAFETY ALERT: ${vessel.name.toUpperCase()}", 
                   style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
            ],
          ),
          const SizedBox(height: 8),
          ...warnings.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text("• $w", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          )),
        ],
      ),
    );
  }

  Future<void> _loadVesselData() async {
    final gear = await DatabaseService.instance.getAllSafetyItems();
    final logs = await DatabaseService.instance.getAllVesselLogs();
    if (mounted) {
      setState(() {
        _safetyGear = gear;
        _vesselLogs = logs;
        _isDataLoading = false;
      });
    }
  }

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
      _weatherFuture = _fetchWeatherAndCheckMatches(); 
    });
    _loadVesselData();
  }

  void _checkForFishingMatch(Map<String, dynamic> liveData) async {
    String? alertMessage = await NotificationEngine.checkConditions(liveData);
    if (alertMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(alertMessage),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherFuture,
      builder: (context, weatherSnapshot) {
        
        // --- UPDATED LOADING SCREEN (FIX 2) ---
        if (weatherSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF004E92)),
                  const SizedBox(height: 20),
                  const Text("⚓ Seacliff Fishing App", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text("Fetching Marine Forecast...", 
                      style: TextStyle(color: Colors.blueGrey)),
                  const SizedBox(height: 40),
                  // EMERGENCY EXIT: If it takes too long, let the user in manually
                  TextButton(
                    onPressed: () => setState(() {
                      _weatherFuture = Future.value({
                        'windKnots': 0, 
                        'windDir': '--', 
                        'temp': 0, 
                        'warning': 'OFFLINE',
                        'forecasts': null
                      });
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("Skip to Dashboard >", 
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          );
        }

        if (weatherSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text("Weather Error: ${weatherSnapshot.error}"),
                  ElevatedButton(
                    onPressed: _handleRefresh, 
                    child: const Text("Retry Connection")
                  ),
                ],
              ),
            ),
          );
        }
        // ------------------------------------

        Map<String, dynamic> data = weatherSnapshot.data ?? {
          'windKnots': 0, 'windDir': '--', 'temp': 0, 'warning': 'NIL', 'forecasts': null,
        };

        final double windSpeedNum = (data['windKnots'] is num) ? data['windKnots'].toDouble() : 0.0;
        final String currentWarning = data['warning'] ?? 'NIL';
        
        final verdict = SafetyEngine.getVerdict(widget.isInshore, windSpeedNum, currentWarning);
        final Color statusColor = SafetyEngine.getStatusColor(verdict);

        // Safely get the boat. Check length instead of just isNotEmpty
        final myBoat = (_vesselBox.length > 0) 
            ? _vesselBox.getAt(0) 
            : null;
            
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text("Seacliff Fishing", style: TextStyle(fontWeight: FontWeight.w900)),
            centerTitle: true,
            leading: IconButton(icon: const Icon(Icons.refresh, size: 28), onPressed: _handleRefresh),
            actions: [
              PopupMenuButton(
                icon: const Icon(Icons.settings, size: 28),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text("Speed: ${_speedUnit.name.toUpperCase()}"),
                    onTap: () => setState(() => _speedUnit = _speedUnit == SpeedUnit.kmh ? SpeedUnit.knots : SpeedUnit.kmh),
                  ),
                  PopupMenuItem(
                    child: Text("Temp: ${_tempUnit.name.toUpperCase()}"),
                    onTap: () => setState(() => _tempUnit = _tempUnit == TempUnit.fahrenheit ? TempUnit.celsius : TempUnit.fahrenheit),
                  ),
                  PopupMenuItem(
                    child: const Text("Fleet & Vessel Settings"),
                    onTap: () {
                      Future.delayed(Duration.zero, () {
                        if (context.mounted) {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (c) => const VesselSettingsScreen()),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (myBoat != null) _buildSafetyAlerts(myBoat, data['forecasts']),
                _buildSafetySummaryCard(statusColor),
                const SizedBox(height: 12),
                _buildSafetyCard(myBoat, windSpeedNum.toInt()),
                const SizedBox(height: 20),
                _buildSectionLabel("LIVE BOAT DATA"),
                Row(
                  children: [
                    Expanded(
                      child: _BriefHeaderCard(
                        label: "Boat Speed",
                        value: _formatSpeed(_currentSpeedKnots),
                        icon: Icons.speed,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BriefHeaderCard(
                        label: "Engine Hours",
                        value: "${(_vesselLogs.isEmpty ? 0.0 : _vesselLogs.first.engineHours).toStringAsFixed(1)}h",
                        icon: Icons.timer_outlined,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                _buildSectionLabel("MARINE ENVIRONMENT"),
                Row(
                  children: [
                    _NavSmallTile(
                      label: "Wind",
                      value: "${windSpeedNum.toInt()}kts ${data['windDir']}",
                      icon: Icons.air, color: Colors.blue,
                      onTap: () {
                        if (data['forecasts'] != null) {
                           Navigator.push(context, MaterialPageRoute(builder: (c) => WindForecastScreen(forecastData: data['forecasts'])));
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    _NavSmallTile(
                      label: "Tides",
                      value: data['nextTide'] ?? "View",
                      icon: Icons.tsunami, color: Colors.cyan,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => TideForecastScreen(forecastData: data['forecasts']))),
                    ),
                    const SizedBox(width: 10),
                    _NavSmallTile(
                      label: "Temp",
                      value: _formatTemp(((data['temp'] ?? 0) as num).toDouble()),
                      icon: Icons.thermostat, color: Colors.deepOrange,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                _buildSectionLabel("FISHING LOGS & INTEL"),
                Row(
                  children: [
                    Expanded(
                      child: _NavLargeTile(
                        label: "New Catch", subText: "Private Log",
                        icon: Icons.add_box_rounded, color: Colors.green.shade700,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => CatchLogScreen(currentWeatherData: data))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NavLargeTile(
                        label: "Logbook", subText: "Intel & Catch History",
                        icon: Icons.menu_book_rounded, color: Colors.orange.shade800,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LogbookScreen())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _NavWideTile(
                  label: "Fish Species Gallery", subText: "SA Size & Bag Limits",
                  icon: Icons.set_meal_rounded, color: Colors.teal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const FishGalleryScreen())),
                ),
                const SizedBox(height: 25),
                _buildSectionLabel("VESSEL & COMPLIANCE"),
                _NavWideTile(
                  label: "Maintenance Log", subText: "Service: ${myBoat?.engineHp ?? 0}HP Engine",
                  icon: Icons.handyman_rounded, color: Colors.blueGrey,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const VesselLogScreen())).then((_) => _loadVesselData()),
                ),
                _NavWideTile(
                  label: "Safety Equipment", subText: "Rego: ${myBoat?.registration ?? '---'}",
                  icon: Icons.shield_rounded, color: const Color(0xFF004E92),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SafetyEquipmentScreen())).then((_) => _loadVesselData()),
                ),
                _NavWideTile(
                  label: "Pre-Launch Checklist", subText: "Go/No-Go Safety Check",
                  icon: Icons.checklist_rtl_rounded, color: Colors.deepPurple,
                  onTap: () async {
                    final weather = await _weatherFuture;
                    if (context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => PreLaunchScreen(weatherSnapshot: weather)));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSafetyCard(VesselProfile? vessel, int windKnots) {
    bool isHighRisk = windKnots > 15; 
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: (vessel?.length ?? 5.0) < 4.8 || isHighRisk ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (vessel?.length ?? 5.0) < 4.8 || isHighRisk ? Colors.orange : Colors.green),
      ),
      child: Row(
        children: [
          Icon(Icons.gpp_maybe, color: (vessel?.length ?? 5.0) < 4.8 || isHighRisk ? Colors.orange : Colors.green),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${vessel?.name ?? 'VESSEL'} STATUS", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                Text(vessel?.lifejacketRequirement ?? "Add vessel in settings", 
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade600, letterSpacing: 1.1)),
    );
  }

  Widget _buildSafetySummaryCard(Color safetyEngineColor) {
    if (_isDataLoading) return const LinearProgressIndicator();

    final expired = _safetyGear.where((i) => i.daysUntilExpiry < 0).length;
    final warning = _safetyGear.where((i) => i.daysUntilExpiry >= 0 && i.daysUntilExpiry < 30).length;
    
    bool serviceOverdue = false;
    if (_vesselLogs.isNotEmpty) {
      final lastSvc = _vesselLogs.firstWhere((l) => l.isServiceRecord, orElse: () => _vesselLogs.last);
      if (_vesselLogs.first.engineHours - lastSvc.engineHours >= 100) serviceOverdue = true;
    }

    Color finalColor = safetyEngineColor;
    String title = "VESSEL READY";
    String subtitle = "Conditions at ${_selectedRamp.name}: Perfect";

    if (expired > 0) {
      finalColor = Colors.red.shade700;
      title = "ACTION REQUIRED";
      subtitle = "$expired ITEMS EXPIRED";
    } else if (warning > 0 || serviceOverdue) {
      finalColor = Colors.orange.shade700;
      title = "MAINTENANCE DUE";
      subtitle = serviceOverdue ? "Service Overdue (100h)" : "Gear expiring soon";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: finalColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: finalColor.withAlpha(75), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSpeed(double s) => _speedUnit == SpeedUnit.kmh 
      ? "${(s * 1.852).toStringAsFixed(1)} km/h" 
      : "${s.toStringAsFixed(1)} kts";

  String _formatTemp(double t) => _tempUnit == TempUnit.fahrenheit 
      ? "${((t * 9/5) + 32).toStringAsFixed(0)}°F" 
      : "${t.toStringAsFixed(0)}°C";
}

// --- HELPER CLASSES ---

class _NavSmallTile extends StatelessWidget {
  final String label, value; final IconData icon; final Color color; final VoidCallback onTap;
  const _NavSmallTile({required this.label, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 5),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLargeTile extends StatelessWidget {
  final String label, subText; final IconData icon; final Color color; final VoidCallback onTap;
  const _NavLargeTile({required this.label, required this.subText, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.black12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 15),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            Text(subText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _NavWideTile extends StatelessWidget {
  final String label, subText; final IconData icon; final Color color; final VoidCallback onTap;
  const _NavWideTile({required this.label, required this.subText, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(subText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}

class _BriefHeaderCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _BriefHeaderCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}