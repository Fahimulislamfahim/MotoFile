import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/vehicle_service.dart';
import '../../data/models/fuel_log_model.dart';
import '../../data/models/vehicle_model.dart';

class AddFuelScreen extends StatefulWidget {
  final Vehicle vehicle;

  const AddFuelScreen({super.key, required this.vehicle});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _litersController;
  late TextEditingController _priceController;
  late TextEditingController _totalCostController;
  late TextEditingController _odometerController;
  
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
    _litersController = TextEditingController();
    _priceController = TextEditingController();
    _totalCostController = TextEditingController();
    _odometerController = TextEditingController();
    
    _litersController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _litersController.dispose();
    _priceController.dispose();
    _totalCostController.dispose();
    _odometerController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final liters = double.tryParse(_litersController.text);
    final price = double.tryParse(_priceController.text);
    
    if (liters != null && price != null) {
      final total = liters * price;
      _totalCostController.text = total.toStringAsFixed(2);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveFuelLog() async {
    if (_formKey.currentState!.validate()) {
      final fuelLog = FuelLog(
        vehicleId: widget.vehicle.id!,
        date: _dateController.text,
        liters: double.parse(_litersController.text),
        pricePerLiter: double.parse(_priceController.text),
        totalCost: double.parse(_totalCostController.text),
        odometer: int.parse(_odometerController.text),
      );

      await Provider.of<VehicleService>(context, listen: false).addFuelLog(fuelLog);

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Fuel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_gas_station, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      '${widget.vehicle.name} (${widget.vehicle.model})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _odometerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Odometer (km)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.speed),
                  helperText: 'Required for mileage calculation',
                ),
                validator: (value) {
                   if (value == null || value.isEmpty) return 'Required';
                   if (int.tryParse(value) == null) return 'Invalid number';
                   return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _litersController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Liters',
                        border: OutlineInputBorder(),
                        suffixText: 'L',
                      ),
                      validator: (value) {
                         if (value == null || value.isEmpty) return 'Required';
                         if (double.tryParse(value) == null) return 'Invalid number';
                         return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price/Liter',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                         if (value == null || value.isEmpty) return 'Required';
                         if (double.tryParse(value) == null) return 'Invalid number';
                         return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _totalCostController,
                readOnly: true, // Auto-calculated
                decoration: const InputDecoration(
                  labelText: 'Total Cost',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  filled: true,
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveFuelLog,
                  child: const Text('Save Fuel Log'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
