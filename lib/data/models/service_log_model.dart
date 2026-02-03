class ServiceLog {
  final int? id;
  final int vehicleId;
  final String date;
  final String serviceType; // "Oil Change", "Repair", "General Service"
  final double cost;
  final int odometer;
  final String? notes; // Details about the service.

  ServiceLog({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.serviceType,
    required this.cost,
    required this.odometer,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'date': date,
      'service_type': serviceType,
      'cost': cost,
      'odometer': odometer,
      'notes': notes,
    };
  }

  factory ServiceLog.fromMap(Map<String, dynamic> map) {
    return ServiceLog(
      id: map['id'],
      vehicleId: map['vehicle_id'],
      date: map['date'],
      serviceType: map['service_type'],
      cost: map['cost'],
      odometer: map['odometer'],
      notes: map['notes'],
    );
  }
}
