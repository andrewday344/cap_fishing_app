import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TideDetailScreen extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const TideDetailScreen({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    List<dynamic> tideEntries = [];
    String debugInfo = "";

    // Inside the build method of TideDetailScreen
try {
  if (weatherData['forecasts'] != null) {
    final forecasts = weatherData['forecasts'];
    
    // Debug print to see what is actually inside forecasts
    print("Keys inside forecasts: ${forecasts.keys.toList()}");

      if (forecasts['tides'] != null) {
        final tidesData = forecasts['tides'];
        final List days = tidesData['days'] ?? [];
        if (days.isNotEmpty) {
          tideEntries = days[0]['entries'] ?? [];
        }
      } else {
        debugInfo = "Tides key missing. Available: ${forecasts.keys.toList()}";
      }
    } else {
      debugInfo = "Forecasts key is null or missing.";
    }
  } catch (e) {
    debugInfo = "Error: $e";
  }

    return Scaffold(
      appBar: AppBar(title: const Text("Seacliff Tides")),
      body: Column(
        children: [
          _buildHeader(),
          if (tideEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(debugInfo, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: tideEntries.isEmpty
                ? const Center(child: Text("Waiting for tide data..."))
                : ListView.builder(
                    itemCount: tideEntries.length,
                    itemBuilder: (context, index) {
                      final entry = tideEntries[index];
                      // Format: 2026-01-25 02:43:00
                      final DateTime time = DateTime.parse(entry['dateTime']);
                      final String type = entry['type'].toString().toUpperCase();
                      
                      return ListTile(
                        leading: Icon(
                          type == "HIGH" ? Icons.expand_less : Icons.expand_more,
                          color: type == "HIGH" ? Colors.blue : Colors.orange,
                          size: 40,
                        ),
                        title: Text(DateFormat('h:mm a').format(time), 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        subtitle: Text(type, style: const TextStyle(fontSize: 16)),
                        trailing: Text("${entry['height']}m", 
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: Colors.blue.shade900,
      child: const Column(
        children: [
          Icon(Icons.waves, color: Colors.white, size: 48),
          SizedBox(height: 8),
          Text("DAILY TIDE CHART", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}