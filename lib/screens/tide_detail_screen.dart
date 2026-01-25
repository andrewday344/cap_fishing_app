import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TideDetailScreen extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const TideDetailScreen({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    List<dynamic> tideEntries = [];
    String debugInfo = "";

    // 1. Dig into the JSON structure you provided
    try {
      if (weatherData.containsKey('forecasts')) {
        final forecasts = weatherData['forecasts'];
        if (forecasts != null && forecasts['tides'] != null) {
          final tideData = forecasts['tides'];
          final days = tideData['days'] as List;
          if (days.isNotEmpty) {
            tideEntries = days[0]['entries'] as List;
          }
        } else {
          debugInfo = "Forecasts found, but 'tides' key is missing.";
        }
      } else {
        debugInfo = "The 'forecasts' key is missing entirely from weatherData.";
      }
    } catch (e) {
      debugInfo = "Error parsing: $e";
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