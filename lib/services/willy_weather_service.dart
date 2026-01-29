import 'dart:convert';
import 'package:http/http.dart' as http;

class WillyWeatherService {
  // Ensure there are NO spaces inside these quotes
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZGy'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    // Switched to 'allorigins' proxy - often more stable than 'corsproxy'
    final String url = 'https://api.allorigins.win/get?url=${Uri.encodeComponent('https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=2')}';

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // AllOrigins wraps the response in a 'contents' field
        final Map<String, dynamic> wrapper = json.decode(response.body);
        final Map<String, dynamic> fullJson = json.decode(wrapper['contents']);
        
        final obs = fullJson['observational']?['observations'];

        return {
          'windKnots': obs != null ? (obs['wind']['speed'] / 1.852).round() : 0,
          'windDir': obs != null ? obs['wind']['directionText'] : '--',
          'temp': obs != null ? obs['temperature']['temperature'].round() : 0,
          'seas': (obs != null && obs['wave'] != null) ? "${obs['wave']['height']}m" : "--",
          'forecasts': fullJson['forecasts'], 
        };
      } else {
        return _emptyData("Error ${response.statusCode}");
      }
    } catch (e) {
      return _emptyData("Conn Error");
    }
  }

  Map<String, dynamic> _emptyData(String msg) {
    return {
      'windKnots': 0, 'windDir': msg, 'temp': 0, 'seas': '--', 'forecasts': null,
    };
  }
}