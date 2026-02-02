import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../../data/models/plant.dart';
import '../../data/models/note.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Stream for navigation events
  final _navigationStreamController = StreamController<String>.broadcast();
  Stream<String> get navigationStream => _navigationStreamController.stream;

  // Notification channel IDs
  static const String _morningDewChannelId = 'morning_dew';
  static const String _wiltWarningChannelId = 'wilt_warning';
  static const String _reminderChannelId = 'reminders';

  // Notification IDs
  static const int _morningDewNotificationId = 1;
  static const int _wiltWarningBaseId = 1000;
  static const int _reminderBaseId = 2000;

  Future<void> init() async {
    tz.initializeTimeZones();

    // iOS settings
    const darwinSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(
      iOS: darwinSettings,
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions later in the UI flow
    // await requestPermissions();

    // Create notification channels (Android)
    await _createNotificationChannels();
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _morningDewChannelId,
          'Morning Dew',
          description: 'Daily summary of plants needing attention',
          importance: Importance.high,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _wiltWarningChannelId,
          'Wilt Warnings',
          description: 'Alerts when plants are in critical condition',
          importance: Importance.high,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _reminderChannelId,
          'Reminders',
          description: 'Note reminders you set',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _navigationStreamController.add(payload);
    }
  }

  // ==================== MORNING DEW ====================

  /// Schedule the daily Morning Dew notification
  Future<void> scheduleMorningDew() async {
    await cancelMorningDew();

    // Schedule for 9 AM every day
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9, // 9 AM
      0,
    );

    // If 9 AM has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _morningDewNotificationId,
      title: 'Good Morning! ☀️',
      body: 'Check on your garden - some plants might need water',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          _morningDewChannelId,
          'Morning Dew',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: 'garden:all',
    );
  }

  /// Show immediate Morning Dew with specific plant names
  Future<void> showMorningDewNow(List<Plant> thirstyPlants) async {
    if (thirstyPlants.isEmpty) return;

    final names = thirstyPlants.take(3).map((p) => p.displayName).join(', ');
    final message = thirstyPlants.length <= 3
        ? '$names ${thirstyPlants.length == 1 ? 'is' : 'are'} looking thirsty today. 💧'
        : '$names and ${thirstyPlants.length - 3} others need water today. 💧';

    await _plugin.show(
      id: _morningDewNotificationId,
      title: 'Morning Dew ☀️',
      body: message,
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          _morningDewChannelId,
          'Morning Dew',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: 'garden:all',
    );
  }

  /// Cancel Morning Dew notification
  Future<void> cancelMorningDew() async {
    await _plugin.cancel(id: _morningDewNotificationId);
  }

  /// Show a test notification (always fires regardless of plant state)
  Future<void> showTestNotification() async {
    await _plugin.show(
      id: _morningDewNotificationId,
      title: 'Test Notification ✅',
      body: 'Notifications are working! Your plants will thank you.',
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          _morningDewChannelId,
          'Morning Dew',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: 'garden:all',
    );
  }

  // ==================== WILT WARNINGS ====================

  /// Schedule a Wilt Warning for a specific plant
  Future<void> scheduleWiltWarning(Plant plant, Duration delay) async {
    final notificationId = _wiltWarningBaseId + plant.id;

    await _plugin.cancel(id: notificationId);

    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'Emergency! 🌿',
      body:
          'Your ${plant.plantType.displayName} (${plant.displayName}) is losing petals!',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          _wiltWarningChannelId,
          'Wilt Warnings',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'plant:${plant.id}',
    );
  }

  /// Cancel Wilt Warning for a specific plant
  Future<void> cancelWiltWarning(int plantId) async {
    await _plugin.cancel(id: _wiltWarningBaseId + plantId);
  }

  /// Cancel all Wilt Warnings
  Future<void> cancelAllWiltWarnings() async {
    // We'd need to track all scheduled warnings to cancel them
    // For now, we'll rely on individual cancellation
  }

  // ==================== REMINDERS ====================

  /// Schedule a reminder notification
  Future<void> scheduleReminder({
    required Note note,
    required String plantName,
  }) async {
    if (note.reminderDate == null) return;

    final notificationId = _reminderBaseId + note.id;

    await _plugin.cancel(id: notificationId);

    final scheduledDate = tz.TZDateTime.from(note.reminderDate!, tz.local);

    // Don't schedule if in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final message =
        note.reminderMessage ?? 'You have a reminder about $plantName';

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'Reminder: $plantName',
      body: message,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          _reminderChannelId,
          'Reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'plant:${note.plantId}',
    );
  }

  /// Cancel a reminder notification
  Future<void> cancelReminder(int noteId) async {
    await _plugin.cancel(id: _reminderBaseId + noteId);
  }

  // ==================== UTILITIES ====================

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final iOS = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();

    return iOS?.isEnabled ?? false;
  }

  // ==================== DEBUG NOTIFICATIONS ====================

  /// Show a test reminder notification
  Future<void> showTestReminderNotification() async {
    await _plugin.show(
      id: _reminderBaseId,
      title: 'Reminder: Test Plant',
      body: 'This is a test reminder notification. Check in with your friend!',
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          _reminderChannelId,
          'Reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      payload: 'garden:all',
    );
  }

  /// Show a test wilt warning notification
  Future<void> showTestWiltWarningNotification() async {
    await _plugin.show(
      id: _wiltWarningBaseId,
      title: 'Emergency!',
      body: 'Your Test Plant is losing petals! Water them soon.',
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          _wiltWarningChannelId,
          'Wilt Warnings',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: 'garden:all',
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
