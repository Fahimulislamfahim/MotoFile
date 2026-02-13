import '../../data/daos/vehicle_dao.dart';
import '../../data/daos/service_log_dao.dart';
import '../../data/daos/fuel_log_dao.dart';
import '../../data/daos/reminder_dao.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/service_log_model.dart';
import '../../data/models/fuel_log_model.dart';
import '../../data/models/reminder_model.dart';
import 'package:flutter/foundation.dart';

class VehicleService extends ChangeNotifier {
  final _vehicleDao = VehicleDao();
  final _serviceLogDao = ServiceLogDao();
  final _fuelLogDao = FuelLogDao();
  final _reminderDao = ReminderDao();
  
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
}
