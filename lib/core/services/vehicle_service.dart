import '../../data/daos/vehicle_dao.dart';
import '../../data/daos/service_log_dao.dart';
import '../../data/daos/fuel_log_dao.dart';
import '../../data/daos/reminder_dao.dart';
import '../../data/daos/daily_log_dao.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/service_log_model.dart';
import '../../data/models/fuel_log_model.dart';
import '../../data/models/reminder_model.dart';
import '../../data/models/daily_log_model.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';


class VehicleService extends ChangeNotifier {
  final _vehicleDao = VehicleDao();
  final _serviceLogDao = ServiceLogDao();
  final _fuelLogDao = FuelLogDao();
  final _reminderDao = ReminderDao();
  final _dailyLogDao = DailyLogDao();
  
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;

  Future<void> loadVehicles() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _vehicles = await _vehicleDao.readAll();
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await _vehicleDao.create(vehicle);
    await loadVehicles();
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _vehicleDao.update(vehicle);
    await loadVehicles();
  }

  Future<void> deleteVehicle(int id) async {
    await _vehicleDao.delete(id);
    await loadVehicles();
  }

  Future<Vehicle?> getVehicle(int id) async {
    return await _vehicleDao.read(id);
  }

  // Service Logs
  Future<List<ServiceLog>> getServiceLogs(int vehicleId) async {
    return await _serviceLogDao.readByVehicle(vehicleId);
  }

  Future<void> addServiceLog(ServiceLog log) async {
    await _serviceLogDao.create(log);
    notifyListeners();
  }

  Future<void> deleteServiceLog(int id) async {
    await _serviceLogDao.delete(id);
    notifyListeners();
  }

  // Fuel Logs
  Future<List<FuelLog>> getFuelLogs(int vehicleId) async {
    return await _fuelLogDao.readByVehicle(vehicleId);
  }

  Future<void> addFuelLog(FuelLog log) async {
    await _fuelLogDao.create(log);
    notifyListeners();
  }

  Future<void> deleteFuelLog(int id) async {
    await _fuelLogDao.delete(id);
    notifyListeners();
  }

  // Reminders
  Future<List<Reminder>> getReminders(int vehicleId) async {
    return await _reminderDao.readByVehicle(vehicleId);
  }

  Future<void> addReminder(Reminder reminder) async {
    await _reminderDao.create(reminder);
    notifyListeners();
  }

  Future<void> deleteReminder(int id) async {
    await _reminderDao.delete(id);
    notifyListeners();
  }

  // Daily Logs
  Future<List<DailyLog>> getDailyLogs(int vehicleId) async {
    return await _dailyLogDao.readByVehicle(vehicleId);
  }

  Future<void> saveDailyLog(DailyLog log) async {
    final existingLog = await _dailyLogDao.readByDate(log.vehicleId, log.date);
    if (existingLog != null) {
      final updatedLog = DailyLog(
        id: existingLog.id,
        vehicleId: log.vehicleId,
        date: log.date,
        time: log.time,
        odometer: log.odometer,
        fuelAdded: log.fuelAdded,
      );
      await _dailyLogDao.update(updatedLog);
    } else {
      await _dailyLogDao.create(log);
    }

    if (log.fuelAdded != null && log.fuelAdded! > 0) {
      // Create a corresponding FuelLog
      final fuelLog = FuelLog(
        vehicleId: log.vehicleId,
        date: log.date,
        liters: log.fuelAdded!,
        pricePerLiter: 0.0,
        totalCost: 0.0,
        odometer: log.odometer,
      );
      await addFuelLog(fuelLog);
    } else {
      notifyListeners();
    }
    
    // Update Home Widget Stats
    await updateWidgetStats(log.vehicleId);
  }

  Future<void> updateWidgetStats(int vehicleId) async {
    final logs = await _dailyLogDao.readByVehicle(vehicleId);
    if (logs.isEmpty) return;

    // Sort ascending by date
    logs.sort((a, b) => a.date.compareTo(b.date));

    final latestLog = logs.last;
    int distance = 0;
    double? mileage;

    if (logs.length > 1) {
      final prevLog = logs[logs.length - 2];
      distance = latestLog.odometer - prevLog.odometer;
      
      if (latestLog.fuelAdded != null && latestLog.fuelAdded! > 0 && distance > 0) {
        mileage = distance / latestLog.fuelAdded!;
      }
    }

    // Push to HomeWidget
    await HomeWidget.saveWidgetData<String>('distance_text', '$distance km');
    await HomeWidget.saveWidgetData<String>('mileage_text', mileage != null ? '${mileage.toStringAsFixed(1)} km/L' : 'N/A');
    
    await HomeWidget.updateWidget(
      name: 'DailyLogWidgetProvider',
      androidName: 'com.vynix.motofile.DailyLogWidgetProvider',
    );
  }

  Future<void> deleteDailyLog(int id) async {
    await _dailyLogDao.delete(id);
    notifyListeners();
  }
}
