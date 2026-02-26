import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/catch_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('catches.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE catches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        species TEXT,
        quantity INTEGER,
        notes TEXT,
        date TEXT,
        temp REAL,
        wind REAL,
        tide TEXT
      )
    ''');
  }

  Future<List<Catch>> readAllCatches() async {
    final db = await instance.database;
    final result = await db.query('catches', orderBy: 'date DESC');
    return result.map((json) => Catch.fromMap(json)).toList();
  }

  Future<int> update(Catch item) async {
    final db = await instance.database;
    return await db.update(
      'catches',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }
}