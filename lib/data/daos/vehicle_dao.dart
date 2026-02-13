import '../database_helper.dart';
import '../models/vehicle_model.dart';

class VehicleDao {
  final dbProvider = DatabaseHelper.instance;

  Future<int> create(Vehicle vehicle) async {
    final db = await dbProvider.database;
    return await db.insert('vehicles', vehicle.toMap());
  }

  Future<Vehicle?> read(int id) async {
    final db = await dbProvider.database;
    final maps = await db.query(
      'vehicles',
       // We can just select *, simpler than listing all columns unless we need strict filtering
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Vehicle.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Vehicle>> readAll() async {
    final db = await dbProvider.database;
    final result = await db.query('vehicles');
    return result.map((json) => Vehicle.fromMap(json)).toList();
  }

  Future<int> update(Vehicle vehicle) async {
    final db = await dbProvider.database;
    return db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await dbProvider.database;
    return await db.delete(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
