import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class WillyWeatherService {
  final String apiKey = 'MjkzZmUzMTVlYTdhNDIzNjRiZjhjZG'; 

  Future<Map<String, dynamic>> getMarineWeather() async {
    final String targetUrl = 'https://api.willyweather.com.au/v2/$apiKey/locations/9765/weather.json?observational=true&forecasts=wind,tides,swell&days=5';
    
    // Use AllOrigins proxy to bypass CORS when running in Chrome/Web simulation
    final String proxyUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}';

    debugPrint("--- WILLYWEATHER WEB DEBUG START ---");
    debugPrint("Target URL: $targetUrl");

    try {
      final response = await http.get(
        Uri.parse(proxyUrl),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      debugPrint("HTTP STATUS: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        debugPrint("SUCCESS: Data received via proxy.");
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Using your original logic with added null-checks to prevent the red screen crash
        final obs = data['observational']?['observations'];
        final forecasts = data['forecasts'];

        return {
          'windKnots': obs != null ? (obs['wind']['speed'] / 1.852).round() : 0,
          'windDir': obs != null ? obs['wind']['directionText'] : '--',
          'temp': obs != null ? obs['temperature']['temperature'].round() : 0,
          'seas': _extractSwell(forecasts),
          'swellHeight': _extractSwell(forecasts),
          'swellDir': _extractSwellDir(forecasts),
          'nextTide': _getNextTide(forecasts),
          'forecasts': forecasts ?? {}, // Fixed: Return empty map instead of null to prevent crash
          'warning': forecasts?['warnings']?[0]?['title'] ?? 'NIL',
          'lastUpdated': DateFormat('h:mm a').format(DateTime.now()),
        };
      } else {
        debugPrint("FAIL BODY: ${response.body}");
        return _emptyData("Error ${response.statusCode}");
      }
    } on SocketException catch (e) {
      debugPrint("NETWORK ERROR: $e");
      return _emptyData("No Internet");
    } catch (e) {
      debugPrint("UNEXPECTED ERROR: $e");
      return _emptyData("App Error");
    } finally {
      debugPrint("--- WILLYWEATHER WEB DEBUG END ---");
    }
  }

  // --- YOUR ORIGINAL HELPERS (Fully Preserved) ---

  String _getNextTide(Map<String, dynamic>? forecasts) {
    try {
      final tideDays = forecasts?['tides']?['days'];
      if (tideDays == null) return "--";
      final now = DateTime.now();
      for (var day in tideDays) {
        for (var entry in day['entries']) {
          DateTime tideTime = DateTime.parse(entry['dateTime']);
          if (tideTime.isAfter(now)) {
            String type = entry['type'] == 'high' ? 'H' : 'L';
            return "$type ${DateFormat('h:mm a').format(tideTime)}";
          }
        }
      }
    } catch (_) {}
    return "--";
  }

  String _extractSwell(Map<String, dynamic>? forecasts) {
    try {
      return "${forecasts?['swell']?['days'][0]['entries'][0]['height']}m";
    } catch (_) { return "0.0m"; }
  }

  String _extractSwellDir(Map<String, dynamic>? forecasts) {
    try {
      return forecasts?['swell']?['days'][0]['entries'][0]['directionText'] ?? "";
    } catch (_) { return ""; }
  }

// ... inside WillyWeatherService ...

    Map<String, dynamic> _emptyData(String msg) {
      return {
        'windKnots': 0, 
        'windDir': msg, 
        'temp': 0, 
        'seas': '--', 
        'swellHeight': '--', 
        'swellDir': '', 
        'nextTide': '--',
        // We provide the EXACT structure the forecast screens expect
        'forecasts': {
          'wind': {'days': []},
          'tides': {'days': []},
          'swell': {'days': []},
        }, 
        'lastUpdated': '--',
      };
    }
  }