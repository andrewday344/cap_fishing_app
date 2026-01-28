import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For debugPrint

class WillyWeatherService {
  // Triple check: Make sure there are no spaces at the start or end of your key
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    // I am removing the 'corsproxy' for a moment to see if that's the blocker.
    // If you are on a real iPhone, you often don't need the proxy!
    final String url = 'https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=2';

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> fullJson = json.decode(response.body);
        
        // Let's grab the observation block
        final obs = fullJson['observational']?['observations'];

        return {
          'windKnots': obs != null ? (obs['wind']['speed'] / 1.852).round() : 5, // Default 5 to see if it's working
          'windDir': obs != null ? obs['wind']['directionText'] : 'CALM',
          'temp': obs != null ? obs['temperature']['temperature'].round() : 20,
          'seas': (obs != null && obs['wave'] != null) ? "${obs['wave']['height']}m" : "0.5m",
          'forecasts': fullJson['forecasts'], 
        };
      } else {
        // If we get here, the API rejected us (401 = Bad Key, 404 = Bad URL)
        debugPrint("API Error: ${response.statusCode}");
        return _emptyData("Error ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Network Error: $e");
      return _emptyData("Connection Failed");
    }
  }

  Map<String, dynamic> _emptyData(String errorMsg) {
    return {
      'windKnots': 0,
      'windDir': errorMsg,
      'temp': 0,
      'seas': '--',
      'forecasts': null,
    };
  }
}