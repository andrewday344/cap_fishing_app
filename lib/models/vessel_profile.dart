import 'package:hive/hive.dart';

// 1. MUST match the filename exactly
part 'vessel_profile.g.dart'; 

@HiveType(typeId: 3) // 2. Make sure typeId 3 isn't used elsewhere
class VesselProfile extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double length;

  @HiveField(2)
  final bool isPowered;

  VesselProfile({
    required this.name, 
    required this.length, 
    this.isPowered = true
  });

  String get lifejacketRequirement => length < 4.8 
      ? "MANDATORY: Wear lifejacket at all times." 
      : "REQUIRED: During heightened risk.";
}