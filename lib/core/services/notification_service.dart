import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  Future<void> scheduleExpiryNotification({
    required int id,
    required String title,
    required DateTime expiryDate,
  }) async {
    // Schedule notification 7 days before expiry
    final scheduledDate7Days = expiryDate.subtract(const Duration(days: 7));
    if (scheduledDate7Days.isAfter(DateTime.now())) {
       await _scheduleNotification(
        id: id * 10 + 1, // Unique ID
        title: 'Document Expiring Soon',
        body: 'Your $title is expiring in 7 days on ${expiryDate.toString().split(' ')[0]}.',
        scheduledDate: scheduledDate7Days,
      );
    }
   

    // Schedule notification 1 day before expiry
    final scheduledDate1Day = expiryDate.subtract(const Duration(days: 1));
    if (scheduledDate1Day.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: id * 10 + 2,
        title: 'Document Expiry Warning',
        body: 'Your $title expires tomorrow! Renew it now.',
        scheduledDate: scheduledDate1Day,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_channel',
          'Document Expiry',
          channelDescription: 'Notifications for document expiry dates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotifications(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id * 10 + 1);
    await flutterLocalNotificationsPlugin.cancel(id * 10 + 2);
  }
}
