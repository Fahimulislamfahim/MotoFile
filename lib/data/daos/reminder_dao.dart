import '../database_helper.dart';
import '../models/reminder_model.dart';

class ReminderDao {
  final dbProvider = DatabaseHelper.instance;

  Future<int> create(Reminder reminder) async {
    final db = await dbProvider.database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<List<Reminder>> readByVehicle(int vehicleId) async {
    final db = await dbProvider.database;
    final result = await db.query(
      'reminders',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'due_date ASC',
    );
    return result.map((json) => Reminder.fromMap(json)).toList();
  }

  Future<int> delete(int id) async {
    final db = await dbProvider.database;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
