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
  Fish(
    name: "King George Whiting", 
    sizeLimit: "32 cm", 
    bagLimit: "10 per person"
  ),
  Fish(
    name: "Snapper", 
    sizeLimit: "38 cm", 
    bagLimit: "CLOSED (Check PIRSA)", 
    statusColor: Colors.red // This triggers the warning icon
  ),
  Fish(
    name: "Southern Calamari", 
    sizeLimit: "No Size Limit", 
    bagLimit: "15 per person"
  ),
  Fish(
    name: "Garfish", 
    sizeLimit: "23 cm", 
    bagLimit: "20 per person"
  ),
  Fish(
    name: "Blue Swimmer Crab", 
    sizeLimit: "11 cm", 
    bagLimit: "20 per person"
  ),
];