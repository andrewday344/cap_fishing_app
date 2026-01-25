import 'dart:convert';
import 'package:http/http.dart' as http;

class WillyWeatherService {
  // Replace this with your actual key
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZGy'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    final String url = 'https://corsproxy.io/?https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=2';

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> fullJson = json.decode(response.body);
        
        // Navigate to the observations block
        final obs = fullJson['observational']['observations'];
        
        return {
          // Flattening the data for the Dashboard
          'windKnots': (obs['wind']['speed'] / 1.852).round(),
          'windDir': obs['wind']['directionText'],
          'temp': obs['temperature']['temperature'].round(),
          'seas': obs['wave'] != null ? "${obs['wave']['height']}m" : "--",
          
          // Passing the raw forecast through for Detail Screens
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