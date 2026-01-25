import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TideDetailScreen extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const TideDetailScreen({super.key, required this.weatherData});

  @override
Widget build(BuildContext context) {
  // Use 'Map.from' to ensure Flutter treats it as a Map
  final Map<String, dynamic> fullData = Map<String, dynamic>.from(weatherData);
  List<dynamic> tideEntries = [];

  if (fullData.containsKey('forecasts') && fullData['forecasts']['tides'] != null) {
    final days = fullData['forecasts']['tides']['days'] as List;
    if (days.isNotEmpty) {
      tideEntries = days[0]['entries'] as List;
    }
  }

    return Scaffold(
      appBar: AppBar(title: const Text("Seacliff Tides")),
      body: Column(
        children: [
          _buildTideHeader(tideEntries),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("TODAY'S TIDE TIMES", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Expanded(
            child: tideEntries.isEmpty
                ? const Center(child: Text("No tide data found in response"))
                : ListView.builder(
                    itemCount: tideEntries.length,
                    itemBuilder: (context, index) {
                      final entry = tideEntries[index];
                      final DateTime time = DateTime.parse(entry['dateTime']);
                      final String type = entry['type']?.toUpperCase() ?? "TIDE";
                      
                      return ListTile(
                        leading: Icon(
                          type == "HIGH" ? Icons.trending_up : Icons.trending_down,
                          color: type == "HIGH" ? Colors.blue : Colors.orange,
                        ),
                        title: Text(DateFormat('h:mm a').format(time), 
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        subtitle: Text(type),
                        trailing: Text("${entry['height']}m", 
                          style: const TextStyle(fontSize: 18, color: Colors.blueGrey)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTideHeader(List tideEntries) {
    return Container(
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.blue.shade800),
      child: const Column(
        children: [
          Icon(Icons.waves, color: Colors.white, size: 40),
          SizedBox(height: 10),
          Text("TIDE FORECAST", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}