class Catch {
  final int? id;
  final String species;
  final int quantity;
  final String notes;
  final String date;
  final double temp;
  final double wind;
  final String tide;

  Catch({
    this.id,
    required this.species,
    required this.quantity,
    required this.notes,
    required this.date,
    required this.temp,
    required this.wind,
    required this.tide,
  });

  Catch copy({
    int? id,
    String? species,
    int? quantity,
    String? notes,
    String? date,
    double? temp,
    double? wind,
    String? tide,
  }) =>
      Catch(
        id: id ?? this.id,
        species: species ?? this.species,
        quantity: quantity ?? this.quantity,
        notes: notes ?? this.notes,
        date: date ?? this.date,
        temp: temp ?? this.temp,
        wind: wind ?? this.wind,
        tide: tide ?? this.tide,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'species': species,
      'quantity': quantity,
      'notes': notes,
      'date': date,
      'temp': temp,
      'wind': wind,
      'tide': tide,
    };
  }

  static Catch fromMap(Map<String, dynamic> map) {
    return Catch(
      id: map['id'],
      species: map['species'] ?? '',
      quantity: map['quantity'] ?? 0,
      notes: map['notes'] ?? '',
      date: map['date'] ?? '',
      temp: (map['temp'] as num?)?.toDouble() ?? 0.0,
      wind: (map['wind'] as num?)?.toDouble() ?? 0.0,
      tide: map['tide'] ?? '',
    );
  }
}