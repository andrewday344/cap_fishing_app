import 'dart:convert';
import 'package:http/http.dart' as http;

class WillyWeatherService {
  static const String apiKey = String.fromEnvironment('WILLY_API_KEY');
  // Seacliff, SA Location ID
  final String locationId = '9765'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    // We request observational (current) and wind/tide forecasts
    final url = 'https://api.willyweather.com.au/v2/$apiKey/locations/$locationId/weather.json?observational=true&forecasts=wind,tides';

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract current wind from observations
        final obs = data['observational']['observations'];
        final wind = obs['wind'];
        
        // WillyWeather usually returns km/h. To get Knots: 
        double windKm = (wind['speed'] as num).toDouble();
        double knots = windKm / 1.852;

        return {
          'temp': obs['temperature']['temperature'],
          'windKnots': knots.toStringAsFixed(1),
          'windDir': wind['directionText'],
          'tideStatus': data['forecasts']['tides']['days'][0]['entries'][0]['type'], // High or Low
        };
      } else {
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }
}