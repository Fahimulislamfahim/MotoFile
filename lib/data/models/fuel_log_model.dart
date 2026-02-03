class FuelLog {
  final int? id;
  final int vehicleId;
  final String date;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final int odometer;

  FuelLog({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    required this.odometer,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'date': date,
      'liters': liters,
      'price_per_liter': pricePerLiter,
      'total_cost': totalCost,
      'odometer': odometer,
    };
  }

  factory FuelLog.fromMap(Map<String, dynamic> map) {
    return FuelLog(
      id: map['id'],
      vehicleId: map['vehicle_id'],
      date: map['date'],
      liters: map['liters'],
      pricePerLiter: map['price_per_liter'],
      totalCost: map['total_cost'],
      odometer: map['odometer'],
    );
  }
}
