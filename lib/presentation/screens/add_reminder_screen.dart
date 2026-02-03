import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/vehicle_service.dart';
import '../../data/models/reminder_model.dart';
import '../../data/models/vehicle_model.dart';

class AddReminderScreen extends StatefulWidget {
  final Vehicle vehicle;

  const AddReminderScreen({super.key, required this.vehicle});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _dueOdometerController;
  late TextEditingController _dueDateController;
  late TextEditingController _recurringOdoController;
  late TextEditingController _recurringDaysController;
  
  bool _isRecurring = false;
  DateTime? _selectedDate;

  final List<String> _suggestedTitles = [
    'Oil Change',
    'Tyre Rotation',
    'Brake Inspection',
    'Air Filter Change',
    'Coolant Check',
    'Chain Lube',
    'Insurance Renewal',
    'Tax Renewal'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _dueOdometerController = TextEditingController();
    _dueDateController = TextEditingController();
    _recurringOdoController = TextEditingController();
    _recurringDaysController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dueOdometerController.dispose();
    _dueDateController.dispose();
    _recurringOdoController.dispose();
    _recurringDaysController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dueDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      // Validate that at least one of Odo or Date is provided
      if (_dueOdometerController.text.isEmpty && _dueDateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set either a Due Date or Due Odometer')),
        );
        return;
      }

      final reminder = Reminder(
        vehicleId: widget.vehicle.id!,
        title: _titleController.text,
        dueOdometer: int.tryParse(_dueOdometerController.text),
        dueDate: _dueDateController.text.isNotEmpty ? _dueDateController.text : null,
        isRecurring: _isRecurring,
        recurringOdometerInterval: int.tryParse(_recurringOdoController.text),
        recurringDaysInterval: int.tryParse(_recurringDaysController.text),
      );

      await Provider.of<VehicleService>(context, listen: false).addReminder(reminder);

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Reminder'),
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
                    Icon(Icons.notifications_active, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      '${widget.vehicle.name} (${widget.vehicle.model})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return _suggestedTitles.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _titleController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                   // Sync internal controller with the autocomplete one
                   controller.addListener(() {
                     _titleController.text = controller.text;
                   });
                   return TextFormField(
                     controller: controller,
                     focusNode: focusNode,
                     onEditingComplete: onEditingComplete,
                     decoration: const InputDecoration(
                       labelText: 'Title (e.g., Oil Change)',
                       border: OutlineInputBorder(),
                       prefixIcon: Icon(Icons.title),
                     ),
                     validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                   );
                },
              ),
              
              const SizedBox(height: 16),
              const Text('Trigger (Set at least one)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),

              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _dueOdometerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Due Odometer (km)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.speed),
                ),
              ),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _isRecurring,
                    onChanged: (val) {
                      setState(() {
                        _isRecurring = val ?? false;
                      });
                    },
                  ),
                  const Text('Repeating Reminder'),
                ],
              ),
              
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _recurringDaysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Repeat every X Days',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _recurringOdoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Repeat every X km',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveReminder,
                  child: const Text('Set Reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
