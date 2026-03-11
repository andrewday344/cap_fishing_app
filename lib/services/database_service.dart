import 'package:hive_flutter/hive_flutter.dart';
import '../models/catch_model.dart';
import '../models/safety_item_model.dart';
import '../models/vessel_log_model.dart'; // FIXED: Added missing import

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  
  static const String _catchBoxName = 'catches_v2';
  static const String _safetyBoxName = 'safety_gear';
  static const String _vesselBoxName = 'vessel_logs'; // Vessel box name

  DatabaseService._init();

  Future<void> init() async {
    await Hive.initFlutter();
    
    if (!Hive.isBoxOpen(_catchBoxName)) {
      await Hive.openBox(_catchBoxName);
    }
    
    if (!Hive.isBoxOpen(_safetyBoxName)) {
      await Hive.openBox(_safetyBoxName);
    }

    if (!Hive.isBoxOpen(_vesselBoxName)) {
      await Hive.openBox(_vesselBoxName);
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

  // --- VESSEL LOG METHODS ---

  Future<void> saveVesselLog(VesselLog log) async {
    final box = Hive.box(_vesselBoxName);
    await box.put(log.id, log.toMap());
  }

  Future<List<VesselLog>> getAllVesselLogs() async {
    final box = Hive.box(_vesselBoxName);
    
    // Map the items to a list of VesselLog objects
    final List<VesselLog> logs = box.values.map((item) {
      return VesselLog.fromMap(Map<String, dynamic>.from(item));
    }).toList();

    // FIXED: Null-safe sorting logic for 2026 Dart standards
    logs.sort((a, b) => b.date.compareTo(a.date));
    
    return logs;
  }

  Future<void> deleteVesselLog(String id) async {
    final box = Hive.box(_vesselBoxName);
    await box.delete(id);
  }
}