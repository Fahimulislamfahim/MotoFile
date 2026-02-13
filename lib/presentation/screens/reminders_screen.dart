import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/vehicle_service.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/reminder_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/premium_background.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/glass_card.dart';
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
       if (diff < 0) return AppColors.error; 
       if (diff < 7) return AppColors.warning; 
    }
    return AppColors.success;
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
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PremiumAppBar(title: '${widget.vehicle.name} Reminders'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No Reminders Set',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.withOpacity(0.7)),
                        ),
                        const SizedBox(height: 8),
                        Text('Set alerts for oil changes, renewals, etc.', style: TextStyle(color: Colors.grey.withOpacity(0.5))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      final statusColor = _getStatusColor(reminder);
                      final statusText = _getStatusText(reminder);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          borderRadius: 32, // Roundish
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.notifications_active_rounded, color: statusColor),
                            ),
                            title: Text(
                              reminder.title, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                                if (reminder.isRecurring)
                                  Row(
                                    children: [
                                      Icon(Icons.repeat_rounded, size: 12, color: Colors.grey.withOpacity(0.7)),
                                      const SizedBox(width: 4),
                                      Text('Repeating', style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.7))),
                                    ],
                                  )
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.check_circle_outline_rounded, color: Colors.grey.withOpacity(0.5)),
                              onPressed: () => _deleteReminder(reminder.id!),
                            ),
                          ),
                        ).animate().fadeIn(delay: (index * 50).ms).slideX(),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addReminder,
          backgroundColor: AppColors.accentLight,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 32),
        ).animate().scale(delay: 500.ms),
      ),
    );
  }
}
