import 'package:hive_flutter/hive_flutter.dart';
import '../models/catch_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static const String _boxName = 'catches_v2';

  DatabaseService._init();

  // Call this in your main.dart
  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  Future<List<Catch>> readAllCatches() async {
    final box = Hive.box(_boxName);
    // Convert Hive's dynamic map back to our Catch model
    return box.values.map((item) {
      return Catch.fromMap(Map<String, dynamic>.from(item));
    }).toList().reversed.toList();
  }

  Future<void> saveCatch(Catch item) async {
    final box = Hive.box(_boxName);
    // Use timestamp as a unique ID for local storage
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