import 'package:flutter/material.dart'; // This fixes the 'Color' and 'Colors' errors

enum SafetyVerdict { go, caution, stay }

class SafetyEngine {
  static SafetyVerdict getVerdict(bool isInshore, double windSpeed, String warning) {
    
    // 1. HARD OVERRIDE: Active Marine Warnings take priority
    if (warning != 'NIL' && warning.isNotEmpty) {
      String upperWarning = warning.toUpperCase();
      if (upperWarning.contains("GALE") || upperWarning.contains("STORM") || upperWarning.contains("DANGEROUS")) {
        return SafetyVerdict.stay;
      }
      return SafetyVerdict.caution;
    }

    // 2. Standard Wind Logic
    if (isInshore) {
      if (windSpeed <= 15) return SafetyVerdict.go;
      if (windSpeed <= 20) return SafetyVerdict.caution;
      return SafetyVerdict.stay;
    } else {
      if (windSpeed <= 12) return SafetyVerdict.go;
      if (windSpeed <= 15) return SafetyVerdict.caution;
      return SafetyVerdict.stay;
    }
  }

  static Color getStatusColor(SafetyVerdict verdict) {
    switch (verdict) {
      case SafetyVerdict.go: return Colors.green.shade700;
      case SafetyVerdict.caution: return Colors.orange.shade800;
      case SafetyVerdict.stay: return Colors.red.shade900;
    }
  }
}