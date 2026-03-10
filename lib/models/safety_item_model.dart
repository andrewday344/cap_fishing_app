import 'package:flutter/material.dart';

class SafetyItem {
  final String id;
  final String name;
  final DateTime expiryDate;
  final String category; // e.g., 'Flare', 'EPIRB', 'Lifejacket'

  SafetyItem({
    required this.id,
    required this.name,
    required this.expiryDate,
    required this.category,
  });

  // Helper to calculate days remaining
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  // Status color logic
  Color get statusColor {
    if (daysUntilExpiry < 0) return Colors.red;        // Expired
    if (daysUntilExpiry < 30) return Colors.orange;    // Warning (30 days)
    return Colors.green;                               // Safe
  }

  // For Hive Storage
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'expiryDate': expiryDate.toIso8601String(),
    'category': category,
  };

  factory SafetyItem.fromMap(Map<String, dynamic> map) => SafetyItem(
    id: map['id'],
    name: map['name'],
    expiryDate: DateTime.parse(map['expiryDate']),
    category: map['category'],
  );
}