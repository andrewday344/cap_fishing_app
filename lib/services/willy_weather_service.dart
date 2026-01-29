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

        // FALLBACK LOGIC: If real-time (obs) is null, use the first forecast entry
        var windSpeed = 0.0;
        var windDir = '--';
        
        if (obs != null) {
          windSpeed = (obs['wind']['speed'] as num).toDouble();
          windDir = obs['wind']['directionText'];
        } else if (forecasts != null && forecasts['wind'] != null) {
          // Grab the first forecast entry of the first day
          final firstForecast = forecasts['wind']['days'][0]['entries'][0];
          windSpeed = (firstForecast['speed'] as num).toDouble();
          windDir = firstForecast['directionText'];
        }

        return {
          'windKnots': (windSpeed / 1.852).round(),
          'windDir': windDir,
          'temp': obs != null ? obs['temperature']['temperature'].round() : 20,
          'seas': (obs != null && obs['wave'] != null) ? "${obs['wave']['height']}m" : "0.5m",
          'forecasts': forecasts,
          'lastUpdated': DateFormat('h:mm a').format(DateTime.now()), // ADDED THIS
        };
      }
      return _emptyData("API Down");
    } catch (e) {
      return _emptyData("Conn Error");
    }
  }

  Map<String, dynamic> _emptyData(String msg) {
    return {
      'windKnots': 0, 'windDir': msg, 'temp': 0, 'seas': '--', 'forecasts': null, 'lastUpdated': '--',
    };
  }
}