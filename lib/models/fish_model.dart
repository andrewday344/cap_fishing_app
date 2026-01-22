class Fish {
  final String name;
  final String sizeLimit;
  final String bagLimit;
  final String description;
  final String imagePath; // We can use a placeholder for now

  Fish({
    required this.name, 
    required this.sizeLimit, 
    required this.bagLimit, 
    this.description = "",
    this.imagePath = "https://via.placeholder.com/150" 
  });
}

// Local SA Data
List<Fish> saFishGallery = [
  Fish(name: "King George Whiting", sizeLimit: "32 cm", bagLimit: "10 per person"),
  Fish(name: "Snapper", sizeLimit: "38 cm (Check Closures)", bagLimit: "Check Regional Rules"),
  Fish(name: "Southern Calamari", sizeLimit: "No Size Limit", bagLimit: "15 per person"),
  Fish(name: "Garfish", sizeLimit: "23 cm", bagLimit: "20 per person"),
];