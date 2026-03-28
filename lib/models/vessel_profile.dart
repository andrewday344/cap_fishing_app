import 'package:hive/hive.dart';

part 'vessel_profile.g.dart'; 

@HiveType(typeId: 3)
class VesselProfile extends HiveObject {
  // Existing Fields (Don't change these numbers!)
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double length;

  @HiveField(2)
  final bool isPowered;

  // --- NEW FEATURES ---
  
  @HiveField(3)
  final String registration; // e.g., "SA123"

  @HiveField(4)
  final int engineHp; // e.g., 50

  // --- SAFETY & NOTIFICATION SETTINGS ---
  
  @HiveField(5)
  final double windIncreaseThreshold; // Percentage (e.g., 20.0 for 20%)

  @HiveField(6)
  final double swellIncreaseThreshold; // Meters (e.g., 0.5)

  @HiveField(7)
  final bool notificationsEnabled;

  VesselProfile({
    required this.name, 
    required this.length, 
    this.isPowered = true,
    this.registration = '',
    this.engineHp = 0,
    this.windIncreaseThreshold = 30.0, // Default 30% increase
    this.swellIncreaseThreshold = 0.5, // Default 0.5m increase
    this.notificationsEnabled = true,
  });

  // Helper for your Dashboard logic
  String get lifejacketRequirement => length < 4.8 
      ? "MANDATORY: Wear lifejacket at all times." 
      : "REQUIRED: During heightened risk.";

  // Helper for your "Don't go out in dark" logic
  bool isSafeToLaunch(DateTime time, DateTime sunrise, DateTime sunset) {
    // Returns false if it's before sunrise or after sunset
    if (time.isBefore(sunrise) || time.isAfter(sunset)) return false;
    return true;
  }
}