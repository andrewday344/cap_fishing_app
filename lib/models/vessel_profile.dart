import 'package:hive/hive.dart';

part 'vessel_profile.g.dart'; 

@HiveType(typeId: 3)
class VesselProfile extends HiveObject {
  // Existing Fields (Indices 0, 1, 2 were already in your old data, so they are safe)
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double length;

  @HiveField(2)
  final bool isPowered;

  // --- NEW FEATURES (Made Nullable with '?' to prevent the crash) ---
  
  @HiveField(3)
  final String? registration; // Safe from null crashes

  @HiveField(4)
  final int? engineHp; 

  @HiveField(5)
  final double? windIncreaseThreshold; 

  @HiveField(6)
  final double? swellIncreaseThreshold; 

  @HiveField(7)
  final bool? notificationsEnabled;

  VesselProfile({
    required this.name, 
    required this.length, 
    this.isPowered = true,
    this.registration = '',
    this.engineHp = 0,
    this.windIncreaseThreshold = 30.0,
    this.swellIncreaseThreshold = 0.5,
    this.notificationsEnabled = true,
  });

  // --- Helper Getters (These handle the nulls so the rest of your app doesn't have to) ---
  
  String get displayRegistration => registration ?? "N/A";
  int get displayHp => engineHp ?? 0;
  double get windThreshold => windIncreaseThreshold ?? 30.0;
  double get swellThreshold => swellIncreaseThreshold ?? 0.5;

  String get lifejacketRequirement => length < 4.8 
      ? "MANDATORY: Wear lifejacket at all times." 
      : "REQUIRED: During heightened risk.";

  bool isSafeToLaunch(DateTime time, DateTime sunrise, DateTime sunset) {
    if (time.isBefore(sunrise) || time.isAfter(sunset)) return false;
    return true;
  }
}