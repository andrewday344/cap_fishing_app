import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // You might need to add 'intl' to pubspec.yaml or use basic parsing

class WindDetailScreen extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const WindDetailScreen({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    final forecasts = weatherData['forecasts'];
    List<dynamic> entries = [];
    


    // Using the exact path from your JSON: forecasts -> wind -> days[0] -> entries
    try {
      if (forecasts != null && forecasts['wind'] != null) {
        final windData = forecasts['wind'];
        if (windData['days'] != null && windData['days'].isNotEmpty) {
          entries = windData['days'][0]['entries'] ?? [];
        }
      }
    } catch (e) {
      entries = [];
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Seacliff Wind Forecast")),
      body: Column(
        children: [
          _buildCurrentHeader(),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.history_toggle_off, color: Colors.blue),
                SizedBox(width: 8),
                Text("HOURLY FORECAST (KNOTS)", 
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ],
            ),
          ),

          Expanded(
            child: entries.isEmpty 
              ? const Center(child: Text("No forecast data available"))
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    
                    // 1. Parse Time
                    final DateTime time = DateTime.parse(entry['dateTime']);
                    final String timeLabel = DateFormat('h:mm a').format(time);
                    
                    // 2. Convert km/h to Knots (multiply by 0.5399)
                    final double speedKmH = double.tryParse(entry['speed'].toString()) ?? 0.0;
                    final int speedKnots = (speedKmH / 1.852).round(); // Official marine conversion
                    
                    return ListTile(
                      leading: Text(timeLabel, 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                      title: Text("$speedKnots kts", 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      subtitle: Text(entry['directionText'] ?? ""),
                      trailing: _getWindIcon(speedKnots),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }

  Widget _buildCurrentHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      width: double.infinity,
      child: Column(
        children: [
          const Text("CURRENT OBSERVATION", style: TextStyle(color: Colors.white70, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text("${weatherData['windKnots']} kts", 
            style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
          Text(weatherData['windDir'] ?? "", 
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _getWindIcon(int knots) {
    if (knots >= 20) return const Icon(Icons.warning, color: Colors.red);
    if (knots >= 15) return const Icon(Icons.air, color: Colors.orange);
    return const Icon(Icons.check_circle, color: Colors.green);
  }
}