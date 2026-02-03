class Reminder {
  final int? id;
  final int vehicleId;
  final String title; // "Oil Change", "Tyre Check"
  final int? dueOdometer;
  final String? dueDate;
  final bool isRecurring;
  final int? recurringOdometerInterval;
  final int? recurringDaysInterval;

  Reminder({
    this.id,
    required this.vehicleId,
    required this.title,
    this.dueOdometer,
    this.dueDate,
    this.isRecurring = false,
    this.recurringOdometerInterval,
    this.recurringDaysInterval,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'title': title,
      'due_odometer': dueOdometer,
      'due_date': dueDate,
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_odometer_interval': recurringOdometerInterval,
      'recurring_days_interval': recurringDaysInterval,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      vehicleId: map['vehicle_id'],
      title: map['title'],
      dueOdometer: map['due_odometer'],
      dueDate: map['due_date'],
      isRecurring: map['is_recurring'] == 1,
      recurringOdometerInterval: map['recurring_odometer_interval'],
      recurringDaysInterval: map['recurring_days_interval'],
    );
  }
}
