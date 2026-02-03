import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/vehicle_service.dart';
import '../../data/models/service_log_model.dart';
import '../../data/models/vehicle_model.dart';

class AddServiceScreen extends StatefulWidget {
  final Vehicle vehicle;

  const AddServiceScreen({super.key, required this.vehicle});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _costController;
  late TextEditingController _odometerController;
  late TextEditingController _notesController;
  String _selectedServiceType = 'General Service';
  
  final List<String> _serviceTypes = [
    'General Service',
    'Oil Change',
    'Tyre Replacement',
    'Brake Service',
    'Battery Replacement',
    'Repair',
    'Other'
  ];

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
    _costController = TextEditingController();
    _odometerController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _costController.dispose();
    _odometerController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _saveService() async {
    if (_formKey.currentState!.validate()) {
      final serviceLog = ServiceLog(
        vehicleId: widget.vehicle.id!,
        date: _dateController.text,
        serviceType: _selectedServiceType,
        cost: double.parse(_costController.text),
        odometer: int.parse(_odometerController.text),
        notes: _notesController.text,
      );

      await Provider.of<VehicleService>(context, listen: false).addServiceLog(serviceLog);

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      '${widget.vehicle.name} (${widget.vehicle.model})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              DropdownButtonFormField<String>(
                value: _selectedServiceType,
                decoration: const InputDecoration(
                  labelText: 'Service Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build),
                ),
                items: _serviceTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _selectedServiceType = value!),
              ),
              const SizedBox(height: 16),
              
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

              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Odometer (km)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.speed),
                      ),
                      validator: (value) {
                         if (value == null || value.isEmpty) return 'Required';
                         if (int.tryParse(value) == null) return 'Invalid number';
                         return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cost',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
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
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveService,
                  child: const Text('Save Log'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
