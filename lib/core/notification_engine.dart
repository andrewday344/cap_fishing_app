import '../models/catch_model.dart';
import '../services/database_service.dart';

class NotificationEngine {
  // Define how 'close' the weather needs to be to trigger a match
  static const double windThreshold = 3.0; // +/- 3 knots
  static const double tempThreshold = 2.0; // +/- 2 degrees

  static Future<String?> checkConditions(Map<String, dynamic> currentData) async {
    final List<Catch> history = await DatabaseService.instance.readAllCatches();
    
    if (history.isEmpty) return null;

    final double curWind = (currentData['windKnots'] as num).toDouble();
    final double curTemp = (currentData['temp'] as num).toDouble();
    final String curTide = currentData['nextTide'] ?? "";

    for (var record in history) {
      // Logic: If wind is similar AND temp is similar AND it's the same tide phase
      bool windMatch = (record.wind - curWind).abs() <= windThreshold;
      bool tempMatch = (record.temp - curTemp).abs() <= tempThreshold;
      bool tideMatch = record.tide.contains(curTide.split(' ')[0]); // Simplified match

      if (windMatch && tempMatch && tideMatch) {
        return "Conditions match your ${record.species} catch! Get the gear ready.";
      }
    }
    return null;
  }
}