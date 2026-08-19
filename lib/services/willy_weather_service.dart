import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class WillyWeatherService {
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  // Accept dynamic locationId (defaults to Seacliff: '9765')
  Future<Map<String, dynamic>> getMarineWeather({String locationId = '9765'}) async {
    final String targetUrl = 'https://api.willyweather.com.au/v2/$apiKey/locations/$locationId/weather.json?observational=true&forecasts=wind,tides,swell&days=5';
    
    final String proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';
    final String finalUrl = kIsWeb ? proxyUrl : targetUrl;

    debugPrint("--- WILLYWEATHER ATTEMPTING FETCH FOR LOCATION $locationId ---");

    try {
      final response = await http.get(Uri.parse(finalUrl))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        debugPrint("✅ SUCCESS: Live data retrieved.");
        return _processData(json.decode(response.body));
      } else {
        debugPrint("❌ WILLYWEATHER CONNECTION FAILED!");
        return _getSimulationData();
      }
    } catch (e) {
      debugPrint("🚨 CRITICAL API CRASH ($e).");
      return _getSimulationData();
    }
  }

  Map<String, dynamic> _processData(Map<String, dynamic> data) {
    final obs = data['observational']?['observations'];
    final forecasts = data['forecasts'];

    return {
      'windKnots': obs != null ? ((obs['wind']?['speed'] ?? 0) / 1.852).round() : 0,
      'windDir': obs != null ? (obs['wind']?['directionText'] ?? '--') : '--',
      'temp': obs != null ? (obs['temperature']?['temperature'] ?? 0).round() : 0,
      'seas': _extractSwell(forecasts),
      'swellHeight': _extractSwell(forecasts),
      'swellDir': _extractSwellDir(forecasts),
      'nextTide': _getNextTide(forecasts),
      'forecasts': forecasts ?? {},
      'warning': (forecasts?['warnings'] != null && forecasts!['warnings'].isNotEmpty) 
          ? forecasts['warnings'][0]['title'] 
          : 'NIL',
      'lastUpdated': DateFormat('h:mm a').format(DateTime.now()),
    };
  }

  Map<String, dynamic> _getSimulationData() {
    return _processData({
      "forecasts": {
        "wind": {"days": [{"dateTime": "2026-03-16 00:00:00", "entries": [{"dateTime": "2026-03-16 12:30:00", "speed": 11.9, "directionText": "ENE"}]}]},
        "tides": {"days": [{"dateTime": "2026-03-16 00:00:00", "entries": [{"dateTime": "2026-03-16 18:08:00", "height": 1.65, "type": "high"}]}]},
        "swell": {"days": [{"dateTime": "2026-03-16 00:00:00", "entries": [{"dateTime": "2026-03-16 12:30:00", "height": 0.2, "directionText": "SSW"}]}]}
      },
      "observational": {
        "observations": {
          "temperature": {"temperature": 18.6},
          "wind": {"speed": 1.8, "directionText": "S"}
        }
      }
    });
  }

  String _getNextTide(Map<String, dynamic>? forecasts) {
    try {
      final tideDays = forecasts?['tides']?['days'];
      if (tideDays == null) return "--";
      final now = DateTime.now();
      for (var day in tideDays) {
        for (var entry in day['entries']) {
          DateTime tideTime = DateTime.parse(entry['dateTime']);
          if (tideTime.isAfter(now)) {
            return "${entry['type'] == 'high' ? 'H' : 'L'} ${DateFormat('h:mm a').format(tideTime)}";
          }
        }
      }
    } catch (_) {}
    return "--";
  }

  String _extractSwell(Map<String, dynamic>? forecasts) {
    try {
      final entries = forecasts?['swell']?['days']?[0]['entries'];
      if (entries != null && entries.isNotEmpty) {
        return "${entries[0]['height']}m";
      }
    } catch (_) {}
    return "0.0m";
  }

  String _extractSwellDir(Map<String, dynamic>? forecasts) {
    try {
      final entries = forecasts?['swell']?['days']?[0]['entries'];
      return entries?[0]['directionText'] ?? "";
    } catch (_) { return ""; }
  }
}