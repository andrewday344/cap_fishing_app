import 'package:hive/hive.dart';

// This MUST match the filename exactly
part 'vessel_profile.g.dart';

@HiveType(typeId: 3)
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
    this.isPowered = true,
  });

  String get lifejacketRequirement {
    if (length < 4.8) {
      return "MANDATORY: Lifejackets must be worn at all times (Vessel <4.8m).";
    }
    return "REQUIRED: During heightened risk (Vessel >4.8m).";
  }
}