import 'dart:convert';
import 'package:http/http.dart' as http;

class WillyWeatherService {
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    // 1. SIMPLIFIED URL: Only asking for observational (current) data
    final String url = 'https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> fullJson = json.decode(response.body);
        final obs = fullJson['observational']?['observations'];

        if (obs == null) return _emptyData("No Obs Data");

        return {
          'windKnots': (obs['wind']['speed'] / 1.852).round(),
          'windDir': obs['wind']['directionText'] ?? '--',
          'temp': obs['temperature']['temperature']?.round() ?? 0,
          'seas': '--', 
          'swellHeight': '--',
          'swellDir': '',
          'nextTide': 'Paused', // Keeping it simple for now
          'forecasts': null,
          'lastUpdated': 'Live',
        };
      } else {
        return _emptyData("Error ${response.statusCode}");
      }
    } catch (e) {
      // If this still says "Blocked", we know it's the connection, not the code
      return _emptyData("Blocked");
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