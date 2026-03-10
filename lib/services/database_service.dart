import 'package:hive_flutter/hive_flutter.dart';
import '../models/catch_model.dart';
import '../models/safety_item_model.dart'; 

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  
  // Box names for organization
  static const String _catchBoxName = 'catches_v2';
  static const String _safetyBoxName = 'safety_gear';

  DatabaseService._init();

  /// Initializes Hive and opens all necessary local storage boxes
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Open Catch Log Box
    if (!Hive.isBoxOpen(_catchBoxName)) {
      await Hive.openBox(_catchBoxName);
    }
    
    // Open Safety Equipment Box
    if (!Hive.isBoxOpen(_safetyBoxName)) {
      await Hive.openBox(_safetyBoxName);
    }
  }

  // --- CATCH LOG METHODS ---

  Future<List<Catch>> readAllCatches() async {
    final box = Hive.box(_catchBoxName);
    return box.values.map((item) {
      return Catch.fromMap(Map<String, dynamic>.from(item));
    }).toList().reversed.toList(); 
  }

  Future<void> saveCatch(Catch item) async {
    final box = Hive.box(_catchBoxName);
    final id = DateTime.now().millisecondsSinceEpoch;
    final itemWithId = item.copy(id: id);
    await box.put(id, itemWithId.toMap());
  }

  // RESTORED: Renamed from updateCatch back to update to fix your error
  Future<void> update(Catch item) async {
    final box = Hive.box(_catchBoxName);
    if (item.id != null) {
      await box.put(item.id, item.toMap());
    }
  }

  // --- SAFETY EQUIPMENT METHODS ---

  Future<void> saveSafetyItem(SafetyItem item) async {
    final box = Hive.box(_safetyBoxName);
    await box.put(item.id, item.toMap());
  }

  Future<List<SafetyItem>> getAllSafetyItems() async {
    final box = Hive.box(_safetyBoxName);
    return box.values.map((item) {
      return SafetyItem.fromMap(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<void> deleteSafetyItem(String id) async {
    final box = Hive.box(_safetyBoxName);
    await box.delete(id);
  }
}