import 'package:hive/hive.dart';
import '../models/catch_model.dart'; // Ensure this import exists

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  final _box = Hive.box('catches');

  // FIX 1: Convert Catch object to Map before saving
  Future<void> createCatch(Catch catchData) async {
    await _box.add(catchData.toMap()); 
  }

  // FIX 2: Convert Maps from Hive back into Catch objects for the UI
  Future<List<Catch>> readAllCatches() async {
    final data = _box.values.toList();
    return data.map((item) {
      return Catch.fromMap(Map<String, dynamic>.from(item));
    }).toList();
  }
}