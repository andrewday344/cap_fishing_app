import 'dart:convert';
import 'package:http/http.dart' as http;

class WillyWeatherService {
  // Replace this with your actual key
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZGy'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    final String url = 'https://corsproxy.io/?https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=2';

    try {
      final response = await http.get(Uri.parse(url));
      
      // Inside willy_weather_service.dart
      if (response.statusCode == 200) {
        final Map<String, dynamic> fullJson = json.decode(response.body);
        final obs = fullJson['observational']['observations'];

        return {
          'windKnots': (obs['wind']['speed'] / 1.852).round(),
          'windDir': obs['wind']['directionText'],
          'temp': obs['temperature']['temperature'].round(),
          'seas': obs['wave'] != null ? "${obs['wave']['height']}m" : "--",
          
          // MAKE SURE THIS IS EXACTLY fullJson['forecasts']
          'forecasts': fullJson['forecasts'], 
      };
} else {
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching weather: $e");
      rethrow;
    }
  } // <--- This closes the getMarineWeather method
} // <--- This closes the WillyWeatherService class