import 'dart:convert';
import 'dart:io'; // Needed for SocketException
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WillyWeatherService {
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    final String url = 'https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=2';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> fullJson = json.decode(response.body);
        final obs = fullJson['observational']?['observations'];
        final forecasts = fullJson['forecasts'];

        return {
          'windKnots': obs != null ? (obs['wind']['speed'] / 1.852).round() : 0,
          'windDir': obs != null ? obs['wind']['directionText'] : '--',
          'temp': obs != null ? obs['temperature']['temperature'].round() : 0,
          'seas': (obs != null && obs['wave'] != null) ? "${obs['wave']['height']}m" : "--",
          'swellHeight': forecasts?['swell']?['days'][0]['entries'][0]['height'].toString() ?? "--",
          'swellDir': forecasts?['swell']?['days'][0]['entries'][0]['directionText'] ?? "",
          'nextTide': _getNextTide(forecasts),
          'forecasts': forecasts,
          'lastUpdated': DateFormat('h:mm a').format(DateTime.now()),
        };
      } else {
        // This captures 401, 403, etc.
        return _emptyData("Status: ${response.statusCode}");
      }
    } on SocketException {
      return _emptyData("Network: No Path");
    } on HandshakeException {
      return _emptyData("Security Block");
    } catch (e) {
      // This shows the actual error string on your iPhone
      return _emptyData(e.toString().split(':').last.trim());
    }
  }

  String _getNextTide(dynamic forecasts) {
    if (forecasts == null || forecasts['tides'] == null) return "--";
    final tideEntries = forecasts['tides']['days'][0]['entries'] as List;
    final now = DateTime.now();
    for (var entry in tideEntries) {
      if (DateTime.parse(entry['dateTime']).isAfter(now)) {
        return DateFormat('h:mm a').format(DateTime.parse(entry['dateTime']));
      }
    }
    return "--";
  }

  Map<String, dynamic> _emptyData(String msg) {
    return {
      'windKnots': 0, 'windDir': msg, 'temp': 0, 'seas': '--', 
      'swellHeight': '--', 'swellDir': '', 'nextTide': '--',
      'forecasts': null, 'lastUpdated': '--',
    };
  }
}