import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'birthdays.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE birthdays (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            day INTEGER NOT NULL,
            month INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    final db = await database;
    return await db.query('birthdays');
  }

  Future<int> addItem(String name, int day, int month) async {
    final db = await database;
    return await db.insert('birthdays', {
      'name': name,
      'day': day,
      'month': month,
    });
  }

  Future<int> updateItem(int id, String name, int day, int month) async {
    final db = await database;
    return await db.update(
      'birthdays',
      {
        'name': name,
        'day': day,
        'month': month,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete(
      'birthdays',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
