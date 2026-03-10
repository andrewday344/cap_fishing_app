import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/safety_item_model.dart';
import '../safety/safety_equipment_screen.dart';
import '../catch_log/catch_log_screen.dart';
import '../logbook/logbook_screen.dart';
import '../wind_forecast_screen.dart';
import '../tide_forecast_screen.dart';
import '../swell_forecast_screen.dart';
import '../fish_gallery_screen.dart';
import '../../services/willy_weather_service.dart';

class DashboardScreen extends StatefulWidget {
  final bool isInshore;
  const DashboardScreen({super.key, required this.isInshore});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _weatherFuture;
  List<SafetyItem> _safetyGear = [];
  bool _isSafetyLoading = true;

  @override
  void initState() {
    super.initState();
    _weatherFuture = WillyWeatherService().getMarineWeather();
    _loadSafetyStatus();
  }

  Future<void> _loadSafetyStatus() async {
    final gear = await DatabaseService.instance.getAllSafetyItems();
    if (mounted) {
      setState(() {
        _safetyGear = gear;
        _isSafetyLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic for the Safety Summary Card
    final expiredCount = _safetyGear.where((item) => item.daysUntilExpiry < 0).length;
    final warningCount = _safetyGear.where((item) => item.daysUntilExpiry >= 0 && item.daysUntilExpiry < 30).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("SEACLIFF FISHING", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _weatherFuture = WillyWeatherService().getMarineWeather());
              _loadSafetyStatus();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: SAFETY STATUS ---
            _buildSafetySummaryCard(expiredCount, warningCount),
            const SizedBox(height: 25),

            // --- SECTION 2: ENVIRONMENT (Weather) ---
            _buildSectionLabel("MARINE ENVIRONMENT"),
            const SizedBox(height: 10),
            FutureBuilder<Map<String, dynamic>>(
              future: _weatherFuture,
              builder: (context, snapshot) {
                final data = snapshot.data;
                return Row(
                  children: [
                    _NavSmallTile(
                      label: "Wind",
                      icon: Icons.air,
                      color: Colors.blue,
                      value: data != null ? "${data['windKnots']}kts" : "--",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => WindForecastScreen(forecastData: data?['forecasts']))),
                    ),
                    const SizedBox(width: 10),
                    _NavSmallTile(
                      label: "Tides",
                      icon: Icons.tsunami,
                      color: Colors.cyan,
                      value: "View",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TideForecastScreen(forecastData: data?['forecasts']))),
                    ),
                    const SizedBox(width: 10),
                    _NavSmallTile(
                      label: "Swell",
                      icon: Icons.waves,
                      color: Colors.indigo,
                      value: "View",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SwellForecastScreen(forecastData: data?['forecasts']))),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 25),

            // --- SECTION 3: FISHING TOOLS ---
            _buildSectionLabel("FISHING LOGS"),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _NavLargeTile(
                    label: "New Catch",
                    subText: "Private Record",
                    icon: Icons.add_box_rounded,
                    color: Colors.green.shade700,
                    onTap: () async {
                      final weather = await _weatherFuture;
                      if (context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => CatchLogScreen(currentWeatherData: weather)));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NavLargeTile(
                    label: "Logbook",
                    subText: "History & Intel",
                    icon: Icons.menu_book_rounded,
                    color: Colors.orange.shade800,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LogbookScreen())),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // --- SECTION 4: VESSEL & COMPLIANCE ---
            _buildSectionLabel("VESSEL & COMPLIANCE"),
            const SizedBox(height: 10),
            _NavWideTile(
              label: "Safety Equipment Gallery",
              subText: "Track Flare & EPIRB Expiries",
              icon: Icons.shield_rounded,
              color: const Color(0xFF004E92),
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const SafetyEquipmentScreen())
              ).then((_) => _loadSafetyStatus()),
            ),
            const SizedBox(height: 12),
            _NavWideTile(
              label: "Fish Species Gallery",
              subText: "SA Size & Bag Limits",
              icon: Icons.set_meal_rounded,
              color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FishGalleryScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade600, letterSpacing: 1.1));
  }

  Widget _buildSafetySummaryCard(int expired, int warning) {
    if (_isSafetyLoading) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
    
    Color cardColor = Colors.green.shade600;
    String title = "VESSEL READY";
    String subtitle = "All safety gear is in date";
    IconData icon = Icons.check_circle_outline;

    if (expired > 0) {
      cardColor = Colors.red.shade700;
      title = "ACTION REQUIRED";
      subtitle = "$expired ITEMS EXPIRED";
      icon = Icons.gpp_bad_rounded;
    } else if (warning > 0) {
      cardColor = Colors.orange.shade700;
      title = "MAINTENANCE DUE";
      subtitle = "$warning items expiring soon";
      icon = Icons.pending_actions_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: cardColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 44),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 18),
        ],
      ),
    );
  }
}

// --- REUSABLE HUB TILES ---

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
              Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w900)),
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
    return InkWell(
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
    );
  }
}