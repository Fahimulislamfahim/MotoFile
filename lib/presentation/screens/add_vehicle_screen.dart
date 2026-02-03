import 'package:flutter/material.dart';
import '../../data/models/vehicle_model.dart';
import '../../core/services/vehicle_service.dart';
import 'package:provider/provider.dart';

class AddEditVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const AddEditVehicleScreen({super.key, this.vehicle});

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _licensePlateController;
  late TextEditingController _vinController;
  late TextEditingController _engineNumberController;
  late TextEditingController _colorController;
  
  late TextEditingController _tyrePressureController;
  late TextEditingController _oilTypeController;
  late TextEditingController _fuelCapacityController;
  late TextEditingController _notesController;

  String _selectedType = 'Bike';
  final List<String> _vehicleTypes = ['Bike', 'Car', 'Scooter', 'Truck'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vehicle?.name ?? '');
    _makeController = TextEditingController(text: widget.vehicle?.make ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _yearController = TextEditingController(text: widget.vehicle?.year ?? '');
    _licensePlateController = TextEditingController(text: widget.vehicle?.licensePlate ?? '');
    _vinController = TextEditingController(text: widget.vehicle?.vin ?? '');
    _engineNumberController = TextEditingController(text: widget.vehicle?.engineNumber ?? '');
    _colorController = TextEditingController(text: widget.vehicle?.color ?? '');
    
    _tyrePressureController = TextEditingController(text: widget.vehicle?.tyrePressure ?? '');
    _oilTypeController = TextEditingController(text: widget.vehicle?.oilType ?? '');
    _fuelCapacityController = TextEditingController(text: widget.vehicle?.fuelCapacity ?? '');
    _notesController = TextEditingController(text: widget.vehicle?.notes ?? '');

    if (widget.vehicle != null) {
      _selectedType = widget.vehicle!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _engineNumberController.dispose();
    _colorController.dispose();
    _tyrePressureController.dispose();
    _oilTypeController.dispose();
    _fuelCapacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      final vehicle = Vehicle(
        id: widget.vehicle?.id,
        name: _nameController.text,
        type: _selectedType,
        make: _makeController.text,
        model: _modelController.text,
        year: _yearController.text,
        licensePlate: _licensePlateController.text,
        vin: _vinController.text,
        engineNumber: _engineNumberController.text,
        color: _colorController.text,
        tyrePressure: _tyrePressureController.text,
        oilType: _oilTypeController.text,
        fuelCapacity: _fuelCapacityController.text,
        notes: _notesController.text,
      );

      final vehicleService = Provider.of<VehicleService>(context, listen: false);

      if (widget.vehicle == null) {
        await vehicleService.addVehicle(vehicle);
      } else {
        await vehicleService.updateVehicle(vehicle);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Info'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Nickname (e.g. My Avenger)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.two_wheeler),
                ),
                items: _vehicleTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _makeController,
                      decoration: const InputDecoration(labelText: 'Make (Yamaha)', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(labelText: 'Model (R15)', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Identification'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licensePlateController,
                decoration: const InputDecoration(
                  labelText: 'License Plate',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vinController,
                decoration: const InputDecoration(
                  labelText: 'VIN / Chassis Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fingerprint),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _engineNumberController,
                decoration: const InputDecoration(
                  labelText: 'Engine Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.engineering),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Specs (Optional)'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tyrePressureController,
                      decoration: const InputDecoration(labelText: 'Tyre Pressure (PSI)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _fuelCapacityController,
                      decoration: const InputDecoration(labelText: 'Fuel Capacity (L)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _oilTypeController,
                decoration: const InputDecoration(
                  labelText: 'Engine Oil Grade',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.opacity),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveVehicle,
                  child: const Text('Save Vehicle'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return  Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
