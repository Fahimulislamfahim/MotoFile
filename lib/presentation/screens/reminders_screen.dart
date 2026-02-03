import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/vehicle_service.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/reminder_model.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  final Vehicle vehicle;

  const RemindersScreen({super.key, required this.vehicle});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final service = Provider.of<VehicleService>(context, listen: false);
    final reminders = await service.getReminders(widget.vehicle.id!);
    if (mounted) {
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    }
  }

  void _addReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderScreen(vehicle: widget.vehicle),
      ),
    );

    if (result == true) {
      _loadReminders();
    }
  }

  void _deleteReminder(int id) async {
    final service = Provider.of<VehicleService>(context, listen: false);
    await service.deleteReminder(id);
    _loadReminders();
  }
  
  Color _getStatusColor(Reminder reminder) {
    if (reminder.dueDate != null) {
       final due = DateTime.parse(reminder.dueDate!);
       final diff = due.difference(DateTime.now()).inDays;
       if (diff < 0) return Colors.red; // Overdue
       if (diff < 7) return Colors.orange; // Due soon
    }
    // Odometer logic would require current odometer reference, which we don't strictly have here efficiently without querying last log.
    // For simplicity, returning green for now if not overdue by date.
    return Colors.green;
  }

  String _getStatusText(Reminder reminder) {
    if (reminder.dueDate != null) {
       final due = DateTime.parse(reminder.dueDate!);
       final diff = due.difference(DateTime.now()).inDays;
       if (diff < 0) return 'Overdue by ${diff.abs()} days';
       if (diff == 0) return 'Due Today';
       if (diff < 7) return 'Due in $diff days';
       return DateFormat('MMM d, yyyy').format(due);
    }
    if (reminder.dueOdometer != null) {
      return 'At ${reminder.dueOdometer} km';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle.name} Reminders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No Reminders Set',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      const Text('Set alerts for oil changes, renewals, etc.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = _reminders[index];
                    final statusColor = _getStatusColor(reminder);
                    final statusText = _getStatusText(reminder);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.1),
                          child: Icon(Icons.notifications, color: statusColor),
                        ),
                        title: Text(
                          reminder.title, 
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                            if (reminder.isRecurring)
                              const Row(
                                children: [
                                  Icon(Icons.repeat, size: 12, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text('Repeating', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              )
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.grey),
                          onPressed: () {
                             // "Complete" the reminder -> if recurring, reset it. If not, delete it.
                             // For now, let's just delete/dismiss.
                             _deleteReminder(reminder.id!);
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
    );
  }
}
