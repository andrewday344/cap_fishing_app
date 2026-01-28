import 'dart:convert';
import 'package:http/http.dart' as http;

class WillyWeatherService {
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZGy'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    final String url = 'https://corsproxy.io/?https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=2';

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> fullJson = json.decode(response.body);
        
        // Safety check: Make sure observational data actually exists
        final obsContainer = fullJson['observational'];
        final obs = (obsContainer != null) ? obsContainer['observations'] : null;

        return {
          'windKnots': obs != null ? (obs['wind']['speed'] / 1.852).round() : 0,
          'windDir': obs != null ? obs['wind']['directionText'] : '--',
          'temp': obs != null ? obs['temperature']['temperature'].round() : 0,
          'seas': (obs != null && obs['wave'] != null) ? "${obs['wave']['height']}m" : "--",
          
          // This is the part your Tide Screen needs!
          'forecasts': fullJson['forecasts'], 
        };
      } else {
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching weather: $e");
      // Return an empty map with forecasts so the app doesn't crash
      return {
        'windKnots': 0,
        'windDir': '--',
        'temp': 0,
        'seas': '--',
        'forecasts': null,
      };
    }
  } 
}