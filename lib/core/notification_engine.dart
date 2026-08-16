import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/database_service.dart';
import '../models/catch_model.dart';

class NotificationEngine {
  /// Compares live weather to historical catches and returns an alert if conditions match.
  static Future<String?> checkConditions(Map<String, dynamic> liveData) async {
    try {
      // 1. EXTRACT LIVE CONDITIONS
      double liveWind = (liveData['windKnots'] is num) ? (liveData['windKnots'] as num).toDouble() : 0.0;
      
      String liveTideStr = (liveData['nextTide'] ?? "").toString().toUpperCase();
      bool isLiveHighTide = liveTideStr.contains('H'); 
      
      // 2. FETCH USER ALGORITHM SETTINGS
      var box = Hive.box('settings');
      double windTol = box.get('alg_wind_tol', defaultValue: 5.0);
      bool requireTideMatch = box.get('alg_tide_match', defaultValue: true);
      double minScore = box.get('alg_min_score', defaultValue: 80.0);

      // 3. FETCH HISTORICAL CATCHES
      // 👇 FIXED: Changed to readAllCatches() to match your DatabaseService 👇
      List<Catch> history = await DatabaseService.instance.readAllCatches();
      
      if (history.isEmpty) return null; 

      Set<String> recommendedSpecies = {};

      // 4. THE MATCHING ALGORITHM
      for (var pastCatch in history) {
        double score = 100.0; 
        
        // --- A. WIND PENALTY ---
        double windDiff = (pastCatch.wind - liveWind).abs();
        
        if (windDiff > windTol) {
          score -= ((windDiff - windTol) * 10); 
        }

        // --- B. TIDE PENALTY ---
        if (requireTideMatch) {
           String pastTide = pastCatch.tide.toUpperCase();
           bool isPastHighTide = pastTide.contains('H') || pastTide.contains('HIGH');
           
           if (isLiveHighTide != isPastHighTide) {
             score -= 25.0; 
           }
        }

        // --- C. THE VERDICT ---
        if (score >= minScore) {
          recommendedSpecies.add(pastCatch.species);
        }
      }

      // 5. FORMAT THE ALERT
      if (recommendedSpecies.isNotEmpty) {
        List<String> speciesList = recommendedSpecies.toList();
        String speciesText = speciesList.join(", ");
        return "🎯 CONDITIONS ARE PERFECT FOR: $speciesText";
      }

      return null; 
      
    } catch (e) {
      debugPrint("Engine Error: $e");
      return null; 
    }
  }
}