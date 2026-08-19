class Ramp {
  final String name;
  final String region;
  final double lat;
  final double lng;
  final String willyWeatherId;

  Ramp({
    required this.name,
    required this.region,
    required this.lat,
    required this.lng,
    required this.willyWeatherId,
  });
}

class RampDirectory {
  static final List<Ramp> allRamps = [
    // --- ADELAIDE METRO ---
    Ramp(name: "Seacliff", region: "Adelaide Metro", lat: -35.0436, lng: 138.5194, willyWeatherId: "9765"),
    Ramp(name: "West Beach", region: "Adelaide Metro", lat: -34.9383, lng: 138.4994, willyWeatherId: "9762"),
    Ramp(name: "O'Sullivan Beach", region: "Adelaide Metro", lat: -35.1278, lng: 138.4689, willyWeatherId: "9766"),
    Ramp(name: "North Haven", region: "Adelaide Metro", lat: -34.7939, lng: 138.4844, willyWeatherId: "9759"),
    Ramp(name: "Outer Harbor", region: "Adelaide Metro", lat: -34.7788, lng: 138.4844, willyWeatherId: "9758"),

    // --- FLEURIEU PENINSULA ---
    Ramp(name: "Wirrina Cove", region: "Fleurieu Peninsula", lat: -35.5000, lng: 138.1500, willyWeatherId: "9772"),
    Ramp(name: "Cape Jervis", region: "Fleurieu Peninsula", lat: -35.6033, lng: 138.0933, willyWeatherId: "9774"),
    Ramp(name: "Victor Harbor", region: "Fleurieu Peninsula", lat: -35.5528, lng: 138.6200, willyWeatherId: "9775"),

    // --- YORKE PENINSULA ---
    Ramp(name: "Edithburgh", region: "Yorke Peninsula", lat: -35.0833, lng: 137.7500, willyWeatherId: "9820"),
    Ramp(name: "Marion Bay", region: "Yorke Peninsula", lat: -35.2333, lng: 136.9833, willyWeatherId: "9824"),
    Ramp(name: "Wallaroo", region: "Yorke Peninsula", lat: -33.9333, lng: 137.6167, willyWeatherId: "9812"),
    Ramp(name: "Port Hughes", region: "Yorke Peninsula", lat: -34.0667, lng: 137.5500, willyWeatherId: "9813"),
    Ramp(name: "Stansbury", region: "Yorke Peninsula", lat: -34.9000, lng: 137.8000, willyWeatherId: "9818"),

    // --- EYRE PENINSULA ---
    Ramp(name: "Port Lincoln", region: "Eyre Peninsula", lat: -34.7333, lng: 135.8667, willyWeatherId: "9854"),
    Ramp(name: "Coffin Bay", region: "Eyre Peninsula", lat: -34.6167, lng: 135.4667, willyWeatherId: "9856"),
    Ramp(name: "Tumby Bay", region: "Eyre Peninsula", lat: -34.3833, lng: 136.1000, willyWeatherId: "9852"),
  ];

  static Map<String, List<Ramp>> getRampsByRegion() {
    Map<String, List<Ramp>> grouped = {};
    for (var ramp in allRamps) {
      if (!grouped.containsKey(ramp.region)) {
        grouped[ramp.region] = [];
      }
      grouped[ramp.region]!.add(ramp);
    }
    return grouped;
  }
}