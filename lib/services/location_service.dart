import 'package:geolocator/geolocator.dart';

class LocationService {
  // Seacliff Boat Ramp Coordinates
  static const double rampLat = -35.0436;
  static const double rampLon = 138.5205;

  // This provides the real-time stream of coordinates
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Updates every 10 meters moved
      ),
    );
  }

  // Calculates distance in meters between two points
  double getDistanceToRamp(double currentLat, double currentLon) {
    return Geolocator.distanceBetween(
      currentLat, 
      currentLon, 
      rampLat, 
      rampLon
    );
  }

  // Initial check for permissions
  Future<void> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }
}