class Vehicle {
  final int? id;
  final String name; // "My Avenger"
  final String type; // "Bike", "Car"
  final String make; // "Yamaha", "Toyota"
  final String model; // "R15", "Corolla"
  final String year;
  final String licensePlate;
  final String vin; // Chassis Number
  final String engineNumber;
  final String color;
  final String? imagePath; // Local path to user selected image
  
  // Specs
  final String? tyrePressure;
  final String? oilType;
  final String? fuelCapacity;
  final String? notes;

  Vehicle({
    this.id,
    required this.name,
    required this.type,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.vin,
    required this.engineNumber,
    required this.color,
    this.imagePath,
    this.tyrePressure,
    this.oilType,
    this.fuelCapacity,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'make': make,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
      'vin': vin,
      'engine_number': engineNumber,
      'color': color,
      'image_path': imagePath,
      'tyre_pressure': tyrePressure,
      'oil_type': oilType,
      'fuel_capacity': fuelCapacity,
      'notes': notes,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      make: map['make'],
      model: map['model'],
      year: map['year'],
      licensePlate: map['license_plate'],
      vin: map['vin'],
      engineNumber: map['engine_number'],
      color: map['color'],
      imagePath: map['image_path'],
      tyrePressure: map['tyre_pressure'],
      oilType: map['oil_type'],
      fuelCapacity: map['fuel_capacity'],
      notes: map['notes'],
    );
  }
  
  Vehicle copyWith({
    int? id,
    String? name,
    String? type,
    String? make,
    String? model,
    String? year,
    String? licensePlate,
    String? vin,
    String? engineNumber,
    String? color,
    String? imagePath,
    String? tyrePressure,
    String? oilType,
    String? fuelCapacity,
    String? notes,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      engineNumber: engineNumber ?? this.engineNumber,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      tyrePressure: tyrePressure ?? this.tyrePressure,
      oilType: oilType ?? this.oilType,
      fuelCapacity: fuelCapacity ?? this.fuelCapacity,
      notes: notes ?? this.notes,
    );
  }
}
