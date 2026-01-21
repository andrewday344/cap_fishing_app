class Catch {
  final int? id;
  final String species;
  final double length;
  final int quantity; // Added
  final String notes;   // Added
  final String date;

  Catch({
    this.id, 
    required this.species, 
    required this.length, 
    required this.quantity, // Added
    required this.notes,    // Added
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'species': species,
      'length': length,
      'quantity': quantity, // Added
      'notes': notes,       // Added
      'date': date,
    };
  }

  factory Catch.fromMap(Map<String, dynamic> map) {
    return Catch(
      id: map['id'],
      species: map['species'],
      length: (map['length'] as num).toDouble(),
      quantity: map['quantity'] ?? 1, // Added with default
      notes: map['notes'] ?? '',       // Added with default
      date: map['date'],
    );
  }
}