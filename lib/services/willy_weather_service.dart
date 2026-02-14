import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WillyWeatherService {
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    // We add forecasts for wind, tides, and swell back in
    final String targetUrl = 'https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=2';
    final String proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';

    try {
      final response = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final obs = data['observational']?['observations'];
        final forecasts = data['forecasts'];

        // Extraction with "Null Safety" to prevent crashes
        return {
          'windKnots': obs != null ? (obs['wind']['speed'] / 1.852).round() : 0,
          'windDir': obs != null ? obs['wind']['directionText'] : '--',
          'temp': obs != null ? obs['temperature']['temperature'].round() : 0,
          'seas': _extractSwell(forecasts),
          'swellHeight': _extractSwell(forecasts),
          'swellDir': _extractSwellDir(forecasts),
          'nextTide': _getNextTide(forecasts),
          'forecasts': forecasts,
          'lastUpdated': DateFormat('h:mm a').format(DateTime.now()),
        };
      } else {
        return _emptyData("Status ${response.statusCode}");
      }
    } catch (e) {
      return _emptyData("Connection Error");
    }
  }

  // Helper to find the next tide in the list
  String _getNextTide(Map<String, dynamic>? forecasts) {
    try {
      final tideDays = forecasts?['tides']?['days'];
      if (tideDays == null) return "--";
      
      final now = DateTime.now();
      for (var day in tideDays) {
        for (var entry in day['entries']) {
          DateTime tideTime = DateTime.parse(entry['dateTime']);
          if (tideTime.isAfter(now)) {
            String type = entry['type'] == 'high' ? 'H' : 'L';
            return "$type ${DateFormat('h:mm a').format(tideTime)}";
          }
        }
      }
    } catch (_) {}
    return "--";
  }

  String _extractSwell(Map<String, dynamic>? forecasts) {
    try {
      return "${forecasts?['swell']?['days'][0]['entries'][0]['height']}m";
    } catch (_) { return "0.0m"; }
  }

  String _extractSwellDir(Map<String, dynamic>? forecasts) {
    try {
      return forecasts?['swell']?['days'][0]['entries'][0]['directionText'] ?? "";
    } catch (_) { return ""; }
  }

  Map<String, dynamic> _emptyData(String msg) {
    return {
      'windKnots': 0, 'windDir': msg, 'temp': 0, 'seas': '--', 
      'swellHeight': '--', 'swellDir': '', 'nextTide': '--',
      'forecasts': null, 'lastUpdated': '--',
    };
  }
}