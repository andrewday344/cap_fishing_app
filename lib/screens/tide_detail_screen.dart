import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TideDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? weatherData;

  const TideDetailScreen({super.key, this.weatherData});

  @override
  Widget build(BuildContext context) {
    List<dynamic> tideEntries = [];
    String errorMessage = "No data received from Dashboard.";

    if (weatherData != null) {
      if (weatherData!['forecasts'] != null) {
        try {
          final forecasts = weatherData!['forecasts'];
          final tides = forecasts['tides'];
          final days = tides['days'] as List;
          tideEntries = days[0]['entries'];
        } catch (e) {
          errorMessage = "Format Error: Could not find Tide entries in Forecast.";
        }
      } else {
        errorMessage = "The Service did not return any Forecasts.";
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Tide Details")),
      body: tideEntries.isEmpty 
        ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
        : ListView.builder(
            itemCount: tideEntries.length,
            itemBuilder: (context, index) {
              final entry = tideEntries[index];
              return ListTile(
                title: Text(entry['type'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(entry['dateTime']),
                trailing: Text("${entry['height']}m"),
              );
            },
          ),
    );
  }
}