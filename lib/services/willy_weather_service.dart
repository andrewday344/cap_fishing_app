import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WillyWeatherService {
  // Your confirmed key from the screenshot
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    // DIRECT URL (No proxy)
    final String url = 'https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=2';

    try {
      // Direct call to WillyWeather
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> fullJson = json.decode(response.body);
        
        // No need to unwrap 'contents' anymore!
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
        // If it's still 403, we know the "URL" setting in your API panel is the issue
        return _emptyData("Error ${response.statusCode}");
      }
    } catch (e) {
      return _emptyData("Check Internet");
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