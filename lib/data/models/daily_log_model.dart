class DailyLog {
  final int? id;
  final int vehicleId;
  final String date; // Format: yyyy-MM-dd
  final String? time; // Format: HH:mm:ss (or ISO8601)
  final int odometer;
  final double? fuelAdded;

  DailyLog({
    this.id,
    required this.vehicleId,
    required this.date,
    this.time,
    required this.odometer,
    this.fuelAdded,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'date': date,
      'time': time,
      'odometer': odometer,
      'fuel_added': fuelAdded,
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'],
      vehicleId: map['vehicle_id'],
      date: map['date'],
      time: map['time'],
      odometer: map['odometer'],
      fuelAdded: map['fuel_added'],
    );
  }
}
