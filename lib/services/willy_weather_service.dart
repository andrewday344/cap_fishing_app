import 'dart:convert';
import 'package:http/http.dart' as http;

class WillyWeatherService {
  static const String apiKey = String.fromEnvironment('WILLY_API_KEY');
  // Seacliff, SA Location ID
  final String locationId = '9765'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
  // 1. Added "swell" to the forecasts list
  final url = 'https://corsproxy.io/?https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final obs = data['observational']['observations'];
      
      // CURRENT DATA
      double temp = (obs['temperature']['temperature'] as num).toDouble();
      double windSpeed = (obs['wind']['speed'] as num).toDouble();
      String windDir = obs['wind']['directionText'];

      // TIDE LOGIC (Finding Current vs Next)
      final tideEntries = data['forecasts']['tides']['days'][0]['entries'];
      final now = DateTime.now();
      
      // Find the first tide entry that is AFTER right now
      var nextTide = tideEntries.firstWhere(
        (e) => DateTime.parse(e['dateTime']).isAfter(now),
        orElse: () => tideEntries[0],
      );
      
      // The one before it was the "Current/Last" status
      int index = tideEntries.indexOf(nextTide);
      var lastTide = index > 0 ? tideEntries[index - 1] : tideEntries[0];

      // SWELL LOGIC
      final swellData = data['forecasts']['swell']['days'][0]['entries'][0];

      return {
        'temp': "${temp.toStringAsFixed(1)}°C",
        'windKnots': (windSpeed / 1.852).toStringAsFixed(1),
        'windDir': windDir,
        'currentTide': lastTide['type'].toUpperCase(),
        'nextTide': "${nextTide['type'].toUpperCase()} at ${nextTide['dateTime'].split(' ')[1].substring(0, 5)}",
        'swellHeight': "${swellData['height']}m",
        'swellDir': swellData['directionText'],
        'seas': "${(swellData['height'] * 0.7).toStringAsFixed(1)}m", // Estimated local seas
      };
    }
  } catch (e) {
    return {'error': e.toString()};
  }
  return {'error': 'Data missing'};
}
}