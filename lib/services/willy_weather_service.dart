import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WillyWeatherService {
  // Corrected key with the 'y' at the end
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    // Re-added the CORS proxy
    final String url = 'https://corsproxy.io/?https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=2';

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> fullJson = json.decode(response.body);
        
        // Safety check for the observational data
        final obsContainer = fullJson['observational'];
        final obs = (obsContainer != null) ? obsContainer['observations'] : null;

        return {
          // Calculation: km/h to Knots
          'windKnots': obs != null ? (obs['wind']['speed'] / 1.852).round() : 0,
          'windDir': obs != null ? obs['wind']['directionText'] : '--',
          'temp': obs != null ? obs['temperature']['temperature'].round() : 0,
          'seas': (obs != null && obs['wave'] != null) ? "${obs['wave']['height']}m" : "--",
          
          // The crucial payload for your Detail Screens
          'forecasts': fullJson['forecasts'], 
        };
      } else {
        debugPrint("API Error: ${response.statusCode}");
        return _emptyData("Error ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Connection Error: $e");
      return _emptyData("Offline");
    }
  }

  Map<String, dynamic> _emptyData(String msg) {
    return {
      'windKnots': 0, 'windDir': msg, 'temp': 0, 'seas': '--', 'forecasts': null,
    };
  }
}