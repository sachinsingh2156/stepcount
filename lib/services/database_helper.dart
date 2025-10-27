import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/step_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('steps_db.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        steps INTEGER NOT NULL,
        distance REAL NOT NULL,
        calories REAL NOT NULL,
        activityTime REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_date ON daily_steps(date)
    ''');
  }

  // Insert or update daily step data
  Future<void> insertOrUpdateDailySteps(DailyStepData data) async {
    final db = await database;
    await db.insert(
      'daily_steps',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get today's data
  Future<DailyStepData?> getTodayData() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_steps',
      where: 'date = ?',
      whereArgs: [today],
    );

    if (maps.isNotEmpty) {
      return DailyStepData.fromMap(maps.first);
    }
    return null;
  }

  // Get all daily data
  Future<List<DailyStepData>> getAllDailyData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_steps',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => DailyStepData.fromMap(maps[i]));
  }

  // Get data for a specific date range
  Future<List<DailyStepData>> getDataForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_steps',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      ],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) => DailyStepData.fromMap(maps[i]));
  }

  // Delete a specific day's data
  Future<void> deleteDataByDate(String date) async {
    final db = await database;
    await db.delete(
      'daily_steps',
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('daily_steps');
  }

  // Get total steps for a period
  Future<int> getTotalStepsForPeriod(DateTime start, DateTime end) async {
    final data = await getDataForDateRange(start, end);
    return data.fold<int>(0, (sum, d) => sum + d.steps);
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

