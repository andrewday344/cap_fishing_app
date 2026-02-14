import 'dart:convert';
import 'package:http/http.dart' as http;

class WillyWeatherService {
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    final String url = 'https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          // This tells WillyWeather "I am a normal Safari browser"
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final obs = data['observational']?['observations'];

        return {
          'windKnots': (obs['wind']['speed'] / 1.852).round(),
          'windDir': obs['wind']['directionText'] ?? '--',
          'temp': obs['temperature']['temperature']?.round() ?? 0,
          'seas': '--', 
          'swellHeight': '--',
          'swellDir': '',
          'nextTide': '--',
          'forecasts': null,
          'lastUpdated': 'Updated',
        };
      } else {
        // If it's a 403 or 401, it's a WillyWeather permission issue
        return _emptyData("Status ${response.statusCode}");
      }
    } catch (e) {
      // If it still says "Blocked", we will show the actual error name
      return _emptyData("Err: ${e.runtimeType}");
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