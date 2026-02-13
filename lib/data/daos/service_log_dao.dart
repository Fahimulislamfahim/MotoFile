import '../database_helper.dart';
import '../models/service_log_model.dart';

class ServiceLogDao {
  final dbProvider = DatabaseHelper.instance;

  Future<int> create(ServiceLog log) async {
    final db = await dbProvider.database;
    return await db.insert('service_logs', log.toMap());
  }

  Future<List<ServiceLog>> readByVehicle(int vehicleId) async {
    final db = await dbProvider.database;
    final result = await db.query(
      'service_logs',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return result.map((json) => ServiceLog.fromMap(json)).toList();
  }

  Future<int> delete(int id) async {
    final db = await dbProvider.database;
    return await db.delete(
      'service_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
