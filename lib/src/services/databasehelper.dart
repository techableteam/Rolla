import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'trip_database.db';
  static const String _tableName = 'trips';

  // Initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Create the database
  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE $_tableName(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tripId TEXT,
          start_address TEXT,
          stop_address TEXT,
          destination_address TEXT,
          destination_text_address TEXT,
          start_location TEXT,
          stop_locations TEXT,
          trip_start_date TEXT,
          droppins TEXT
        )
      ''');
    });
  }

  // Insert a new trip into the database
  Future<void> insertTrip(Map<String, dynamic> tripData) async {
    final db = await database;
    await db.insert(_tableName, tripData);
  }

  // Get all trips from the database
  Future<List<Map<String, dynamic>>> getTrips() async {
    final db = await database;
    return await db.query(_tableName);
  }

  // Delete the entire database (Renamed to avoid conflict)
  Future<void> deleteLocalDatabase() async {
    final dbPath =
        join(await getDatabasesPath(), _dbName); // Get the database path
    await deleteDatabase(
        dbPath); // Correctly call sqflite's deleteDatabase with the db path
  }
}
