import '../models/catch_model.dart';
import '../services/database_service.dart';

class NotificationEngine {
  static const double windTolerance = 4.0; 
  static const double tempTolerance = 3.0; 

  static Future<String?> checkConditions(Map<String, dynamic> currentData) async {
    final List<Catch> history = await DatabaseService.instance.readAllCatches();
    
    if (history.isEmpty) return null;

    final double curWind = (currentData['windKnots'] as num).toDouble();
    final double curTemp = (currentData['temp'] as num).toDouble();
    final String curTide = (currentData['nextTide'] ?? "").toString().toLowerCase();

    for (var record in history) {
      bool windMatch = (record.wind - curWind).abs() <= windTolerance;
      bool tempMatch = (record.temp - curTemp).abs() <= tempTolerance; // Now we use this!
      
      bool tideMatch = false;
      if (record.tide.isNotEmpty && curTide.isNotEmpty) {
        String logTide = record.tide.split(' ')[0].toLowerCase();
        if (curTide.contains(logTide)) {
          tideMatch = true;
        }
      }

      // Check all three for a high-confidence "Intel" match
      if (windMatch && tideMatch && tempMatch) {
        return "Conditions match your ${record.species} catch! Time to hit the water.";
      }
    }

    return null; 
  }
}