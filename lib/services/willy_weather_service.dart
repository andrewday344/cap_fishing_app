import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WillyWeatherService {
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    final String url = 'https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=2';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> fullJson = json.decode(response.body);
        
        // --- OBSERVATIONAL DATA (Real-time) ---
        final obs = fullJson['observational']?['observations'];
        final forecasts = fullJson['forecasts'];

        // --- SWELL EXTRACTION ---
        String swellHeight = "--";
        String swellDir = "";
        if (forecasts != null && forecasts['swell'] != null) {
          final firstSwell = forecasts['swell']['days'][0]['entries'][0];
          swellHeight = "${firstSwell['height']}m";
          swellDir = firstSwell['directionText'];
        }

        return {
          'windKnots': obs != null ? (obs['wind']['speed'] / 1.852).round() : 0,
          'windDir': obs != null ? obs['wind']['directionText'] : '--',
          'temp': obs != null ? obs['temperature']['temperature'].round() : 0,
          'seas': swellHeight, // Using swell height as a proxy for sea state
          'swellHeight': swellHeight,
          'swellDir': swellDir,
          'nextTide': _getNextTide(forecasts),
          'forecasts': forecasts,
          'lastUpdated': DateFormat('h:mm a').format(DateTime.now()),
        };
      } else {
        return _emptyData("Status: ${response.statusCode}");
      }
    } catch (e) {
      // If this triggers, the app is being blocked by local permissions
      return _emptyData("Blocked: Check Permissions");
    }
  }

  String _getNextTide(dynamic forecasts) {
    if (forecasts == null || forecasts['tides'] == null) return "--";
    final List days = forecasts['tides']['days'];
    final now = DateTime.now();

    for (var day in days) {
      final List entries = day['entries'];
      for (var entry in entries) {
        DateTime tideTime = DateTime.parse(entry['dateTime']);
        if (tideTime.isAfter(now)) {
          return "${DateFormat('h:mm a').format(tideTime)} (${entry['type']})";
        }
      }
    }
    return "--";
  }

  Map<String, dynamic> _emptyData(String msg) {
    return {
      'windKnots': 0, 'windDir': msg, 'temp': 0, 'seas': '--', 
      'swellHeight': '--', 'swellDir': '', 'nextTide': '--',
      'forecasts': null, 'lastUpdated': '--',
    };
  }
}