import '../../data/database_helper.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/service_log_model.dart';
import '../../data/models/fuel_log_model.dart';
import '../../data/models/reminder_model.dart';
import 'package:flutter/foundation.dart';

class VehicleService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;

  Future<void> loadVehicles() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _vehicles = await _db.readAllVehicles();
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await _db.createVehicle(vehicle);
    await loadVehicles();
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _db.updateVehicle(vehicle);
    await loadVehicles();
  }

  Future<void> deleteVehicle(int id) async {
    await _db.deleteVehicle(id);
    await loadVehicles();
  }

  Future<Vehicle?> getVehicle(int id) async {
    return await _db.readVehicle(id);
  }

  // Service Logs
  Future<List<ServiceLog>> getServiceLogs(int vehicleId) async {
    return await _db.readServiceLogs(vehicleId);
  }

  Future<void> addServiceLog(ServiceLog log) async {
    await _db.createServiceLog(log);
    notifyListeners();
  }

  Future<void> deleteServiceLog(int id) async {
    await _db.deleteServiceLog(id);
    notifyListeners();
  }

  // Fuel Logs
  Future<List<FuelLog>> getFuelLogs(int vehicleId) async {
    return await _db.readFuelLogs(vehicleId);
  }

  Future<void> addFuelLog(FuelLog log) async {
    await _db.createFuelLog(log);
    notifyListeners();
  }

  Future<void> deleteFuelLog(int id) async {
    await _db.deleteFuelLog(id);
    notifyListeners();
  }

  // Reminders
  Future<List<Reminder>> getReminders(int vehicleId) async {
    return await _db.readReminders(vehicleId);
  }

  Future<void> addReminder(Reminder reminder) async {
    await _db.createReminder(reminder);
    notifyListeners();
  }

  Future<void> deleteReminder(int id) async {
    await _db.deleteReminder(id);
    notifyListeners();
  }
}
