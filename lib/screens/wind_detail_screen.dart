import 'package:flutter/material.dart';

class WindDetailScreen extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const WindDetailScreen({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    // Note: WillyWeather provides forecast data in a nested structure
    // This logic assumes you updated the service to include 'forecasts=wind'
    return Scaffold(
      appBar: AppBar(title: const Text("Wind Forecast")),
      body: Column(
        children: [
          // Header with Current Wind
          Container(
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
                const Text("CURRENTLY AT SEACLIFF", style: TextStyle(color: Colors.white70, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text("${weatherData['windKnots']} kts", 
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                Text(weatherData['windDir'] ?? "", 
                  style: const TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.history_toggle_off, color: Colors.blue),
                SizedBox(width: 8),
                Text("HOURLY FORECAST", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Forecast List
          Expanded(
            child: ListView.separated(
              itemCount: 12, // Show next 12 hours
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                // We will populate this with real forecast data in the next step
                // For now, it's a clean placeholder for the push test
                return ListTile(
                  leading: Text("${DateTime.now().hour + index + 1}:00", 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  title: const Text("Checking forecast..."),
                  trailing: const Icon(Icons.air, color: Colors.blueGrey),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}