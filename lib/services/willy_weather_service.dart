import 'dart:convert';
import 'package:http/http.dart' as http;

class WillyWeatherService {
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    // We wrap the WillyWeather URL inside a CORS proxy
    // This tells the proxy: "Fetch this for me and add the 'Allow' headers"
    final String targetUrl = 'https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true';
    final String proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';

    try {
      final response = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Safety check to ensure the JSON structure exists
        if (data['observational'] == null) return _emptyData("No Data");
        
        final obs = data['observational']['observations'];

        return {
          'windKnots': (obs['wind']['speed'] / 1.852).round(),
          'windDir': obs['wind']['directionText'] ?? '--',
          'temp': obs['temperature']['temperature']?.round() ?? 0,
          'seas': '--', 
          'swellHeight': '--',
          'swellDir': '',
          'nextTide': 'Ready',
          'forecasts': null,
          'lastUpdated': 'Updated',
        };
      } else {
        return _emptyData("Server Err: ${response.statusCode}");
      }
    } catch (e) {
      // This catches the 'minified' errors and gives us a readable hint
      return _emptyData("Connection Error");
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