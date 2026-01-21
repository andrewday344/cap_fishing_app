

class TideService {
  // Mock data for Seacliff, Jan 2026
  static Map<String, dynamic> getSeacliffTides() {
    return {
      'lowTide': DateTime.now().subtract(const Duration(hours: 2)),
      'highTide': DateTime.now().add(const Duration(hours: 4)),
      'lowHeight': 0.2,
      'highHeight': 1.4,
    };
  }

  static String getTideStatus() {
    // Logic to determine if tide is rising or falling
    return "Rising (Incoming)";
  }
}