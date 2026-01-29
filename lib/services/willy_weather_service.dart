import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WillyWeatherService {
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    // We are wrapping the URL in the AllOrigins proxy
    final String targetUrl = 'https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=2';
    final String proxyUrl = 'https://api.allorigins.win/get?url=${Uri.encodeComponent(targetUrl)}';

    try {
      final response = await http.get(Uri.parse(proxyUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> wrapper = json.decode(response.body);
        
        // This is the "Drill Down" step
        final String rawContents = wrapper['contents'];
        final Map<String, dynamic> fullJson = json.decode(rawContents);
        
        // Check if observations exist
        final obs = fullJson['observational']?['observations'];
        final forecasts = fullJson['forecasts'];

        return {
          'windKnots': obs != null ? (obs['wind']['speed'] / 1.852).round() : 0,
          'windDir': obs != null ? obs['wind']['directionText'] : '--',
          'temp': obs != null ? obs['temperature']['temperature'].round() : 0,
          'seas': (obs != null && obs['wave'] != null) ? "${obs['wave']['height']}m" : "--",
          'forecasts': forecasts, // Passing the full forecast block
        };
      } else {
        debugPrint("Proxy returned status: ${response.statusCode}");
        return _emptyData("Proxy Error");
      }
    } catch (e) {
      debugPrint("Service Catch: $e");
      return _emptyData("Conn Fail");
    }
  }

  Map<String, dynamic> _emptyData(String msg) {
    return {
      'windKnots': 0, 'windDir': msg, 'temp': 0, 'seas': '--', 'forecasts': null,
    };
  }
}