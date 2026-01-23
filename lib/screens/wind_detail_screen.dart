import 'package:flutter/material.dart';

class WindDetailScreen extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const WindDetailScreen({super.key, required this.weatherData});

@override
Widget build(BuildContext context) {
  List<dynamic> entries = [];
  
  // A safer way to "dig" through the JSON
  if (weatherData['forecasts'] != null && 
      weatherData['forecasts']['wind'] != null &&
      weatherData['forecasts']['wind']['days'] != null &&
      weatherData['forecasts']['wind']['days'].isNotEmpty) {
    
    entries = weatherData['forecasts']['wind']['days'][0]['entries'] ?? [];
  }

    return Scaffold(
      appBar: AppBar(title: const Text("Seacliff Wind Forecast")),
      body: Column(
        children: [
          // Header showing current conditions
          _buildCurrentHeader(),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.history_toggle_off, color: Colors.blue),
                SizedBox(width: 8),
                Text("HOURLY FORECAST (KNOTS)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ],
            ),
          ),

          // 2. The Dynamic Forecast List
          Expanded(
            child: entries.isEmpty 
              ? const Center(child: Text("No forecast data available"))
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    
                    // Format the time from the 'dateTime' string
                    final DateTime time = DateTime.parse(entry['dateTime']);
                    final String timeLabel = "${time.hour}:00";
                    
                    return ListTile(
                      leading: Container(
                        width: 60,
                        alignment: Alignment.centerLeft,
                        child: Text(timeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      title: Text("${entry['speed']} kts", style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(entry['directionText'] ?? ""),
                      trailing: _getWindIcon(entry['speed']),
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
          const Text("CURRENTLY", style: TextStyle(color: Colors.white70, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text("${weatherData['windKnots']} kts", 
            style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
          Text(weatherData['windDir'] ?? "", 
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
    );
  }

  // Visual helper for the list
  Widget _getWindIcon(dynamic speed) {
    double s = double.tryParse(speed.toString()) ?? 0.0;
    if (s > 20) return const Icon(Icons.warning, color: Colors.red);
    if (s > 15) return const Icon(Icons.air, color: Colors.orange);
    return const Icon(Icons.check_circle, color: Colors.green);
  }
}