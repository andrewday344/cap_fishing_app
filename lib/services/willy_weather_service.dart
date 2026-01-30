import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WillyWeatherService {
  // Exact key from your screenshot: No 'y', ends in ZG
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    final String proxyUrl = 'https://api.willyweather.com.au/v2/MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=2';
    
    // Using AllOrigins to bypass the 403 Domain Lock issues common in development
    //final String proxyUrl = 'https://api.allorigins.win/get?url=${Uri.encodeComponent(targetUrl)}';

    try {
      final response = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> wrapper = json.decode(response.body);
        
        // AllOrigins puts the weather data inside a string called 'contents'
        final String rawContents = wrapper['contents'];
        final Map<String, dynamic> fullJson = json.decode(rawContents);
        
        // If the API itself returns an error (like 403), it will be inside 'contents'
        if (fullJson['error'] != null) {
          return _emptyData("API: ${fullJson['error']}");
        }

        final obs = fullJson['observational']?['observations'];
        final forecasts = fullJson['forecasts'];

        // --- Data Extraction ---
        String swellHeight = "--";
        String swellDir = "";
        if (forecasts != null && forecasts['swell'] != null) {
          final firstSwell = forecasts['swell']['days'][0]['entries'][0];
          swellHeight = "${firstSwell['height']}m";
          swellDir = firstSwell['directionText'];
        }

        String nextTideTime = "--";
        if (forecasts != null && forecasts['tides'] != null) {
          final tideEntries = forecasts['tides']['days'][0]['entries'] as List;
          final now = DateTime.now();
          for (var entry in tideEntries) {
            DateTime tideTime = DateTime.parse(entry['dateTime']);
            if (tideTime.isAfter(now)) {
              nextTideTime = DateFormat('h:mm a').format(tideTime);
              break; 
            }
          }
        }

        return {
          'windKnots': obs != null ? (obs['wind']['speed'] / 1.852).round() : 0,
          'windDir': obs != null ? obs['wind']['directionText'] : '--',
          'temp': obs != null ? obs['temperature']['temperature'].round() : 0,
          'seas': (obs != null && obs['wave'] != null) ? "${obs['wave']['height']}m" : "--",
          'swellHeight': swellHeight,
          'swellDir': swellDir,
          'nextTide': nextTideTime,
          'forecasts': forecasts,
          'lastUpdated': DateFormat('h:mm a').format(DateTime.now()),
        };
      } else {
        return _emptyData("HTTP ${response.statusCode}");
      }
    } catch (e) {
      // Shows the specific error (e.g., FormatException if proxy sends back junk)
      return _emptyData("Error: ${e.toString().split(':').first}");
    }
  }

  Map<String, dynamic> _emptyData(String msg) {
    return {
      'windKnots': 0, 'windDir': msg, 'temp': 0, 'seas': '--', 
      'swellHeight': '--', 'swellDir': '', 'nextTide': '--',
      'forecasts': null, 'lastUpdated': '--',
    };
  }
}