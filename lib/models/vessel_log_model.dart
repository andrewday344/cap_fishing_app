class VesselLog {
  final String id;
  final DateTime date;
  final double engineHours;
  final double fuelAdded; // Litres
  final String notes;
  final bool isServiceRecord;

  VesselLog({
    required this.id,
    required this.date,
    required this.engineHours,
    this.fuelAdded = 0.0,
    this.notes = "",
    this.isServiceRecord = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'engineHours': engineHours,
    'fuelAdded': fuelAdded,
    'notes': notes,
    'isServiceRecord': isServiceRecord,
  };

  factory VesselLog.fromMap(Map<String, dynamic> map) => VesselLog(
    id: map['id'],
    date: DateTime.parse(map['date']),
    engineHours: (map['engineHours'] as num).toDouble(),
    fuelAdded: (map['fuelAdded'] as num).toDouble(),
    notes: map['notes'] ?? "",
    isServiceRecord: map['isServiceRecord'] ?? false,
  );
}