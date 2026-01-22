import 'dart:convert';
import 'package:http/http.dart' as http;

class WillyWeatherService {
  static const String apiKey = String.fromEnvironment('WILLY_API_KEY');
  // Seacliff, SA Location ID
  final String locationId = '9765'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
  final url = 'https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // 1. Get current wind from OBSERVATIONAL data
      final obs = data['observational']['observations'];
      final windSpeed = obs['wind']['speed']; // Usually in km/h
      final windDir = obs['wind']['directionText'];

      // 2. Get tide from FORECASTS data
      // WillyWeather: forecasts -> tides -> days -> [0] -> entries -> [0]
      final tideEntries = data['forecasts']['tides']['days'][0]['entries'];
      final nextTide = tideEntries[0]; // The very next tide change

      return {
        'temp': obs['temperature']['temperature'],
        'windKnots': (windSpeed / 1.852).toStringAsFixed(1), // Convert km/h to Knots
        'windDir': windDir,
        'tideStatus': "${nextTide['type'].toUpperCase()} at ${nextTide['dateTime'].split(' ')[1].substring(0, 5)}",
      };
    }
  } catch (e) {
    return {'error': e.toString()};
  }
  return {'error': 'Unknown error'};
}
}