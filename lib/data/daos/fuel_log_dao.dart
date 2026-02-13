import '../database_helper.dart';
import '../models/fuel_log_model.dart';

class FuelLogDao {
  final dbProvider = DatabaseHelper.instance;

  Future<int> create(FuelLog log) async {
    final db = await dbProvider.database;
    return await db.insert('fuel_logs', log.toMap());
  }

  Future<List<FuelLog>> readByVehicle(int vehicleId) async {
    final db = await dbProvider.database;
    final result = await db.query(
      'fuel_logs',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return result.map((json) => FuelLog.fromMap(json)).toList();
  }

  Future<int> delete(int id) async {
    final db = await dbProvider.database;
    return await db.delete(
      'fuel_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
