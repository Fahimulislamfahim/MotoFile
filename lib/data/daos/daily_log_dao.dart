import '../database_helper.dart';
import '../models/daily_log_model.dart';

class DailyLogDao {
  final dbProvider = DatabaseHelper.instance;

  Future<int> create(DailyLog log) async {
    final db = await dbProvider.database;
    return await db.insert('daily_logs', log.toMap());
  }

  Future<List<DailyLog>> readByVehicle(int vehicleId) async {
    final db = await dbProvider.database;
    final result = await db.query(
      'daily_logs',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return result.map((json) => DailyLog.fromMap(json)).toList();
  }

  Future<DailyLog?> readByDate(int vehicleId, String date) async {
    final db = await dbProvider.database;
    final result = await db.query(
      'daily_logs',
      where: 'vehicle_id = ? AND date = ?',
      whereArgs: [vehicleId, date],
    );
    if (result.isNotEmpty) {
      return DailyLog.fromMap(result.first);
    }
    return null;
  }

  Future<int> update(DailyLog log) async {
    final db = await dbProvider.database;
    return await db.update(
      'daily_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await dbProvider.database;
    return await db.delete(
      'daily_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
