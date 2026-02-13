import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('motofile.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 6, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await _createDocumentTable(db);
    await _createVehicleTable(db);
    await _createServiceLogTable(db);
    await _createFuelLogTable(db);
    await _createReminderTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createVehicleTable(db);
    }
    if (oldVersion < 3) {
      await _createServiceLogTable(db);
    }
    if (oldVersion < 4) {
      await _createFuelLogTable(db);
    }
    if (oldVersion < 5) {
      await _createReminderTable(db);
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE vehicles ADD COLUMN image_path TEXT');
      } catch (e) {
        print("Error adding image_path column: $e");
      }
    }
  }

  Future _createDocumentTable(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT'; // For optional dates

    await db.execute('''
CREATE TABLE documents (
  id $idType,
  doc_type $textType,
  file_path $textType,
  issue_date $textTypeNullable,
  expiry_date $textTypeNullable,
  status $textType
)
''');
  }

  Future _createReminderTable(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const intType = 'INTEGER NOT NULL';
    const textType = 'TEXT NOT NULL';
    const intTypeNullable = 'INTEGER';
    const textTypeNullable = 'TEXT';

    await db.execute('''
CREATE TABLE reminders (
  id $idType,
  vehicle_id $intType,
  title $textType,
  due_odometer $intTypeNullable,
  due_date $textTypeNullable,
  is_recurring $intType,
  recurring_odometer_interval $intTypeNullable,
  recurring_days_interval $intTypeNullable
)
''');
  }

  Future _createFuelLogTable(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const intType = 'INTEGER NOT NULL';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE fuel_logs (
  id $idType,
  vehicle_id $intType,
  date $textType,
  liters $realType,
  price_per_liter $realType,
  total_cost $realType,
  odometer $intType
)
''');
  }

  Future _createServiceLogTable(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const intType = 'INTEGER NOT NULL';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
CREATE TABLE service_logs (
  id $idType,
  vehicle_id $intType,
  date $textType,
  service_type $textType,
  cost $realType,
  odometer $intType,
  notes $textTypeNullable
)
''');
  }

  Future _createVehicleTable(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
CREATE TABLE vehicles (
  id $idType,
  name $textType,
  type $textType,
  make $textType,
  model $textType,
  year $textType,
  license_plate $textType,
  vin $textType,
  engine_number $textType,
  color $textType,
  image_path $textTypeNullable,
  tyre_pressure $textTypeNullable,
  oil_type $textTypeNullable,
  fuel_capacity $textTypeNullable,
  notes $textTypeNullable
)
''');
  }
}
