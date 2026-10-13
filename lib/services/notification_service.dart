import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'studyfy_reminders',
      'Study reminders',
      channelDescription: 'Reminders for your study sessions',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  // Call once when the app starts
  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: android));
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      // If notifications fail, the rest of the app still works.
    }
  }

  // Schedules a reminder at the exact date and time of the session.
  // Android may deliver it a minute or two late to save battery.
  Future<void> scheduleTask(Task task) async {
    final id = task.id;
    if (id == null) return;
    try {
      await _plugin.cancel(id);
      if (task.isDone) return;

      final when = task.dueDate.toLocal();
      if (!when.isAfter(DateTime.now())) return; // time already passed

      await _plugin.zonedSchedule(
        id,
        'Time to study: ${task.subject}',
        '${task.title} starts now. Open Studyfy and get going!',
        tz.TZDateTime.from(when, tz.UTC),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      // A failed reminder should never break saving a session.
    }
  }

  Future<void> cancelTask(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {}
  }

  // Shows a notification immediately (used by the bell button for testing)
  Future<void> showTest() async {
    try {
      await _plugin.show(
        0,
        'Studyfy',
        'Notifications are working!',
        _details,
      );
    } catch (e) {}
  }
}