import 'package:hive_flutter/hive_flutter.dart';
import '../models/catch_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static const String _boxName = 'catches';

  DatabaseService._init();

  // Initialize Hive for the web
  Future<void> init() async {
    await Hive.initFlutter();
    // Register a simplified adapter or store as Map
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  Future<List<Catch>> readAllCatches() async {
    final box = Hive.box(_boxName);
    // Convert the stored maps back into Catch objects
    return box.values.map((item) {
      final map = Map<String, dynamic>.from(item);
      return Catch.fromMap(map);
    }).toList().reversed.toList(); // Newest first
  }

  Future<void> saveCatch(Catch item) async {
    final box = Hive.box(_boxName);
    // Generate an ID if it's new
    final id = DateTime.now().millisecondsSinceEpoch;
    final itemWithId = item.copy(id: id);
    await box.put(id, itemWithId.toMap());
  }

  Future<void> update(Catch item) async {
    final box = Hive.box(_boxName);
    if (item.id != null) {
      await box.put(item.id, item.toMap());
    }
  }
}