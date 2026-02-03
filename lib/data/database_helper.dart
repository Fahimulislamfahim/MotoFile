import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/document_model.dart';
import 'models/vehicle_model.dart';
import 'models/service_log_model.dart';
import 'models/fuel_log_model.dart';
import 'models/reminder_model.dart';

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
      version: 5, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
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
  tyre_pressure $textTypeNullable,
  oil_type $textTypeNullable,
  fuel_capacity $textTypeNullable,
  notes $textTypeNullable
)
''');
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE documents (
  id $idType,
  doc_type $textType,
  file_path $textType,
  issue_date TEXT,
  expiry_date TEXT,
  status $textType
)
''');

    await _createVehicleTable(db);
    await _createServiceLogTable(db);
    await _createFuelLogTable(db);
    await _createReminderTable(db);
  }

  Future<int> create(Document document) async {
    final db = await instance.database;
    return await db.insert('documents', document.toMap());
  }

  Future<Document?> readDocument(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'documents',
      columns: ['id', 'doc_type', 'file_path', 'issue_date', 'expiry_date', 'status'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Document.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Document>> readAllDocuments() async {
    final db = await instance.database;
    final result = await db.query('documents');
    return result.map((json) => Document.fromMap(json)).toList();
  }

  Future<int> update(Document document) async {
    final db = await instance.database;
    return db.update(
      'documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // Vehicle CRUD Operations
  Future<int> createVehicle(Vehicle vehicle) async {
    final db = await instance.database;
    return await db.insert('vehicles', vehicle.toMap());
  }

  Future<Vehicle?> readVehicle(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'vehicles',
      columns: Vehicle(
        name: '', type: '', make: '', model: '', year: '', 
        licensePlate: '', vin: '', engineNumber: '', color: ''
      ).toMap().keys.toList().where((k) => k != 'id').toList()..add('id'),
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Vehicle.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Vehicle>> readAllVehicles() async {
    final db = await instance.database;
    final result = await db.query('vehicles');
    return result.map((json) => Vehicle.fromMap(json)).toList();
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await instance.database;
    return db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<int> deleteVehicle(int id) async {
    final db = await instance.database;
    return await db.delete(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Service Log CRUD Operations
  Future<int> createServiceLog(ServiceLog log) async {
    final db = await instance.database;
    return await db.insert('service_logs', log.toMap());
  }

  Future<List<ServiceLog>> readServiceLogs(int vehicleId) async {
    final db = await instance.database;
    final result = await db.query(
      'service_logs',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return result.map((json) => ServiceLog.fromMap(json)).toList();
  }

  Future<int> deleteServiceLog(int id) async {
    final db = await instance.database;
    return await db.delete(
      'service_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // Fuel Log CRUD Operations
  Future<int> createFuelLog(FuelLog log) async {
    final db = await instance.database;
    return await db.insert('fuel_logs', log.toMap());
  }

  Future<List<FuelLog>> readFuelLogs(int vehicleId) async {
    final db = await instance.database;
    final result = await db.query(
      'fuel_logs',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return result.map((json) => FuelLog.fromMap(json)).toList();
  }

  Future<int> deleteFuelLog(int id) async {
    final db = await instance.database;
    return await db.delete(
      'fuel_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // Reminder CRUD Operations
  Future<int> createReminder(Reminder reminder) async {
    final db = await instance.database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<List<Reminder>> readReminders(int vehicleId) async {
    final db = await instance.database;
    final result = await db.query(
      'reminders',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'due_date ASC', // Show soonest date first. Ideally mix with odometer.
    );
    return result.map((json) => Reminder.fromMap(json)).toList();
  }

  Future<int> deleteReminder(int id) async {
    final db = await instance.database;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
