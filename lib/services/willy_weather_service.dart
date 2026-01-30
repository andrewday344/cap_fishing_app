import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WillyWeatherService {
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    final String targetUrl = 'https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=2';
    final String proxyUrl = 'https://api.allorigins.win/get?url=${Uri.encodeComponent(targetUrl)}';

    try {
      final response = await http.get(Uri.parse(proxyUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> wrapper = json.decode(response.body);
        final Map<String, dynamic> fullJson = json.decode(wrapper['contents']);
        
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

        // --- NEXT TIDE EXTRACTION ---
        String nextTideTime = "--";
        if (forecasts != null && forecasts['tides'] != null) {
          final tideEntries = forecasts['tides']['days'][0]['entries'] as List;
          final now = DateTime.now();
          
          // Find the first tide entry that happens AFTER now
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
          'seas': (obs != null && obs['wave'] != null) ? "${obs['wave']['height']}m" : "0.5m",
          'swellHeight': swellHeight,
          'swellDir': swellDir,
          'nextTide': nextTideTime,
          'forecasts': forecasts,
          'lastUpdated': DateFormat('h:mm a').format(DateTime.now()),
        };
      }
      return _emptyData("API Down");
    } catch (e) {
      return _emptyData("Conn Error");
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