import 'package:flutter/material.dart';

enum SafetyVerdict { go, caution, stayHome }

class SafetyEngine {
  static const double inshoreLimit = 15.0; 
  static const double offshoreLimit = 22.0;

  static SafetyVerdict getVerdict(bool isInshore, double windSpeed) {
    double limit = isInshore ? inshoreLimit : offshoreLimit;
    if (windSpeed < limit - 5) return SafetyVerdict.go;
    if (windSpeed < limit) return SafetyVerdict.caution;
    return SafetyVerdict.stayHome;
  }

  static Color getStatusColor(SafetyVerdict verdict) {
    switch (verdict) {
      case SafetyVerdict.go: return Colors.green;
      case SafetyVerdict.caution: return Colors.orange;
      case SafetyVerdict.stayHome: return Colors.red;
    }
  }
}