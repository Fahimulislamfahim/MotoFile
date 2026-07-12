import 'package:flutter_test/flutter_test.dart';
import 'package:motofile/data/models/vehicle_model.dart';

void main() {
  group('Vehicle Model Tests', () {
    final minimalVehicle = Vehicle(
      name: 'My Avenger',
      type: 'Bike',
      make: 'Bajaj',
      model: 'Avenger',
      year: '2020',
      licensePlate: 'ABC-1234',
      vin: 'VIN1234567890',
      engineNumber: 'ENG0987654321',
      color: 'Black',
    );

    final fullVehicle = Vehicle(
      id: 1,
      name: 'My Avenger',
      type: 'Bike',
      make: 'Bajaj',
      model: 'Avenger',
      year: '2020',
      licensePlate: 'ABC-1234',
      vin: 'VIN1234567890',
      engineNumber: 'ENG0987654321',
      color: 'Black',
      imagePath: '/path/to/image.png',
      tyrePressure: '32 psi',
      oilType: 'Synthetic',
      fuelCapacity: '13L',
      notes: 'Some notes',
    );

    test('should instantiate Vehicle correctly', () {
      expect(minimalVehicle.name, 'My Avenger');
      expect(minimalVehicle.type, 'Bike');
      expect(minimalVehicle.id, isNull);

      expect(fullVehicle.id, 1);
      expect(fullVehicle.imagePath, '/path/to/image.png');
    });

    group('toMap', () {
      test('should return a map with only required fields when optional fields are null', () {
        final map = minimalVehicle.toMap();

        expect(map, {
          'id': null,
          'name': 'My Avenger',
          'type': 'Bike',
          'make': 'Bajaj',
          'model': 'Avenger',
          'year': '2020',
          'license_plate': 'ABC-1234',
          'vin': 'VIN1234567890',
          'engine_number': 'ENG0987654321',
          'color': 'Black',
          'image_path': null,
          'tyre_pressure': null,
          'oil_type': null,
          'fuel_capacity': null,
          'notes': null,
        });
      });

      test('should return a map with all fields when all fields are populated', () {
        final map = fullVehicle.toMap();

        expect(map, {
          'id': 1,
          'name': 'My Avenger',
          'type': 'Bike',
          'make': 'Bajaj',
          'model': 'Avenger',
          'year': '2020',
          'license_plate': 'ABC-1234',
          'vin': 'VIN1234567890',
          'engine_number': 'ENG0987654321',
          'color': 'Black',
          'image_path': '/path/to/image.png',
          'tyre_pressure': '32 psi',
          'oil_type': 'Synthetic',
          'fuel_capacity': '13L',
          'notes': 'Some notes',
        });
      });
    });

    group('fromMap', () {
      test('should create a Vehicle with only required fields when optional fields are null', () {
        final map = {
          'id': null,
          'name': 'My Avenger',
          'type': 'Bike',
          'make': 'Bajaj',
          'model': 'Avenger',
          'year': '2020',
          'license_plate': 'ABC-1234',
          'vin': 'VIN1234567890',
          'engine_number': 'ENG0987654321',
          'color': 'Black',
          'image_path': null,
          'tyre_pressure': null,
          'oil_type': null,
          'fuel_capacity': null,
          'notes': null,
        };

        final vehicle = Vehicle.fromMap(map);

        expect(vehicle.id, isNull);
        expect(vehicle.name, 'My Avenger');
        expect(vehicle.type, 'Bike');
        expect(vehicle.make, 'Bajaj');
        expect(vehicle.model, 'Avenger');
        expect(vehicle.year, '2020');
        expect(vehicle.licensePlate, 'ABC-1234');
        expect(vehicle.vin, 'VIN1234567890');
        expect(vehicle.engineNumber, 'ENG0987654321');
        expect(vehicle.color, 'Black');
        expect(vehicle.imagePath, isNull);
        expect(vehicle.tyrePressure, isNull);
        expect(vehicle.oilType, isNull);
        expect(vehicle.fuelCapacity, isNull);
        expect(vehicle.notes, isNull);
      });

      test('should create a Vehicle with all fields populated', () {
        final map = {
          'id': 1,
          'name': 'My Avenger',
          'type': 'Bike',
          'make': 'Bajaj',
          'model': 'Avenger',
          'year': '2020',
          'license_plate': 'ABC-1234',
          'vin': 'VIN1234567890',
          'engine_number': 'ENG0987654321',
          'color': 'Black',
          'image_path': '/path/to/image.png',
          'tyre_pressure': '32 psi',
          'oil_type': 'Synthetic',
          'fuel_capacity': '13L',
          'notes': 'Some notes',
        };

        final vehicle = Vehicle.fromMap(map);

        expect(vehicle.id, 1);
        expect(vehicle.name, 'My Avenger');
        expect(vehicle.type, 'Bike');
        expect(vehicle.make, 'Bajaj');
        expect(vehicle.model, 'Avenger');
        expect(vehicle.year, '2020');
        expect(vehicle.licensePlate, 'ABC-1234');
        expect(vehicle.vin, 'VIN1234567890');
        expect(vehicle.engineNumber, 'ENG0987654321');
        expect(vehicle.color, 'Black');
        expect(vehicle.imagePath, '/path/to/image.png');
        expect(vehicle.tyrePressure, '32 psi');
        expect(vehicle.oilType, 'Synthetic');
        expect(vehicle.fuelCapacity, '13L');
        expect(vehicle.notes, 'Some notes');
      });
    });

    group('copyWith', () {
      test('should return a new Vehicle with updated values', () {
        final updatedVehicle = minimalVehicle.copyWith(
          id: 2,
          color: 'Red',
          notes: 'New notes',
        );

        expect(updatedVehicle.id, 2);
        expect(updatedVehicle.name, 'My Avenger');
        expect(updatedVehicle.color, 'Red');
        expect(updatedVehicle.notes, 'New notes');

        // original vehicle remains unchanged
        expect(minimalVehicle.id, isNull);
        expect(minimalVehicle.color, 'Black');
      });

      test('should return a new Vehicle with exact same values if no arguments are provided', () {
        final sameVehicle = fullVehicle.copyWith();

        expect(sameVehicle.id, fullVehicle.id);
        expect(sameVehicle.name, fullVehicle.name);
        expect(sameVehicle.type, fullVehicle.type);
        expect(sameVehicle.make, fullVehicle.make);
        expect(sameVehicle.model, fullVehicle.model);
        expect(sameVehicle.year, fullVehicle.year);
        expect(sameVehicle.licensePlate, fullVehicle.licensePlate);
        expect(sameVehicle.vin, fullVehicle.vin);
        expect(sameVehicle.engineNumber, fullVehicle.engineNumber);
        expect(sameVehicle.color, fullVehicle.color);
        expect(sameVehicle.imagePath, fullVehicle.imagePath);
        expect(sameVehicle.tyrePressure, fullVehicle.tyrePressure);
        expect(sameVehicle.oilType, fullVehicle.oilType);
        expect(sameVehicle.fuelCapacity, fullVehicle.fuelCapacity);
        expect(sameVehicle.notes, fullVehicle.notes);
      });
    });
  });
}
