import 'package:flutter/material.dart';

class Fish {
  final String name;
  final String sizeLimit;
  final String bagLimit;
  final Color statusColor; // Added this field
  final String imagePath;  // Keep this for future photos

  Fish({
    required this.name, 
    required this.sizeLimit, 
    required this.bagLimit,
    this.statusColor = Colors.green, // Default to green if not specified
    this.imagePath = "https://via.placeholder.com/150", // Default placeholder
  });
}

// Updated list to include the statusColor for specific fish
List<Fish> saFishGallery = [
  Fish(name: "King George Whiting", sizeLimit: "32 cm", bagLimit: "10 (Total 20)"),
  Fish(name: "Snapper", sizeLimit: "38 cm", bagLimit: "CLOSED", statusColor: Colors.red),
  Fish(name: "Southern Calamari", sizeLimit: "No Limit", bagLimit: "15 (Total 30)"),
  Fish(name: "Garfish", sizeLimit: "23 cm", bagLimit: "20 per person"),
  Fish(name: "Blue Swimmer Crab", sizeLimit: "11 cm", bagLimit: "20 per person"),
  Fish(name: "Flathead", sizeLimit: "30 cm", bagLimit: "10 per person"),
  Fish(name: "Silver Trevally", sizeLimit: "24 cm", bagLimit: "20 per person"),
  Fish(name: "Yellowtail Kingfish", sizeLimit: "60 cm", bagLimit: "2 per person"),
  Fish(name: "Tommie Ruff", sizeLimit: "No Limit", bagLimit: "20 per person"),
  Fish(name: "Snook", sizeLimit: "45 cm", bagLimit: "20 per person"),
];