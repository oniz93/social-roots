# Task 10: Local Notifications

## Priority: MEDIUM
## Estimated Time: 4-5 hours
## Platform Focus: iOS First

---

## Objective
Implement the local notification system including the "Morning Dew" summary, "Wilt Warning" alerts, and reminder notifications.

---

## Context
Notifications are critical for engagement but must avoid fatigue. The strategy:
- **Morning Dew:** Daily 9 AM summary of top 3 thirstiest plants
- **Wilt Warning:** Alert when a plant is about to hit "Critical" state
- **Reminders:** One-time notifications for note reminders

### Notification Rules
- No more than 1 Morning Dew per day
- Wilt Warnings only for plants approaching Critical (not already there)
- Users can configure notification preferences
- All notifications should deep-link to relevant screens

---

## Implementation

### 1. Notification Service (`lib/core/services/notification_service.dart`)
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../../data/models/plant.dart';
import '../../data/models/note.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  
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
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const initSettings = InitializationSettings(
      iOS: darwinSettings,
      android: androidSettings,
    );
    
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Request permissions on iOS
    await _requestPermissions();
    
    // Create notification channels (Android)
    await _createNotificationChannels();
  }
  
  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
  
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
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
    // Handle notification tap - navigate to relevant screen
    final payload = response.payload;
    if (payload != null) {
      // Parse payload and navigate
      // Format: "type:id" e.g., "plant:123" or "reminder:456"
      final parts = payload.split(':');
      if (parts.length == 2) {
        final type = parts[0];
        final id = int.tryParse(parts[1]);
        
        // Navigation will be handled by the app's navigation service
        // This is a callback that can be registered from the main app
      }
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
      _morningDewNotificationId,
      'Good Morning! ☀️',
      'Check on your garden - some plants might need water',
      scheduledDate,
      NotificationDetails(
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: const AndroidNotificationDetails(
          _morningDewChannelId,
          'Morning Dew',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
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
      _morningDewNotificationId,
      'Morning Dew ☀️',
      message,
      NotificationDetails(
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: const AndroidNotificationDetails(
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
    await _plugin.cancel(_morningDewNotificationId);
  }
  
  // ==================== WILT WARNINGS ====================
  
  /// Schedule a Wilt Warning for a specific plant
  Future<void> scheduleWiltWarning(Plant plant, Duration delay) async {
    final notificationId = _wiltWarningBaseId + plant.id;
    
    await _plugin.cancel(notificationId);
    
    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);
    
    await _plugin.zonedSchedule(
      notificationId,
      'Emergency! 🌿',
      'Your ${plant.plantType.displayName} (${plant.displayName}) is losing petals!',
      scheduledDate,
      NotificationDetails(
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: const AndroidNotificationDetails(
          _wiltWarningChannelId,
          'Wilt Warnings',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'plant:${plant.id}',
    );
  }
  
  /// Cancel Wilt Warning for a specific plant
  Future<void> cancelWiltWarning(int plantId) async {
    await _plugin.cancel(_wiltWarningBaseId + plantId);
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
    
    await _plugin.cancel(notificationId);
    
    final scheduledDate = tz.TZDateTime.from(note.reminderDate!, tz.local);
    
    // Don't schedule if in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;
    
    final message = note.reminderMessage ?? 'You have a reminder about $plantName';
    
    await _plugin.zonedSchedule(
      notificationId,
      'Reminder: $plantName',
      message,
      scheduledDate,
      NotificationDetails(
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: const AndroidNotificationDetails(
          _reminderChannelId,
          'Reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'plant:${note.plantId}',
    );
  }
  
  /// Cancel a reminder notification
  Future<void> cancelReminder(int noteId) async {
    await _plugin.cancel(_reminderBaseId + noteId);
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
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.checkPermissions();
    
    return iOS?.isEnabled ?? false;
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
```

### 2. Notification Scheduler (`lib/core/services/notification_scheduler.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/plant.dart';
import '../../data/models/note.dart';
import '../../data/repositories/plant_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../core/utils/health_calculator.dart';
import 'notification_service.dart';

class NotificationScheduler {
  final NotificationService _notificationService;
  final PlantRepository _plantRepository;
  final NoteRepository _noteRepository;
  
  NotificationScheduler({
    required NotificationService notificationService,
    required PlantRepository plantRepository,
    required NoteRepository noteRepository,
  })  : _notificationService = notificationService,
        _plantRepository = plantRepository,
        _noteRepository = noteRepository;
  
  /// Initialize and schedule all notifications
  Future<void> initializeNotifications() async {
    await _notificationService.init();
    await scheduleMorningDew();
    await scheduleWiltWarnings();
    await scheduleReminders();
  }
  
  /// Schedule the daily Morning Dew notification
  Future<void> scheduleMorningDew() async {
    await _notificationService.scheduleMorningDew();
  }
  
  /// Check and schedule Wilt Warnings for all plants
  Future<void> scheduleWiltWarnings() async {
    final plants = await _plantRepository.getAllPlantsSortedByHealth();
    
    for (final plant in plants) {
      await updateWiltWarningForPlant(plant);
    }
  }
  
  /// Update Wilt Warning for a specific plant
  Future<void> updateWiltWarningForPlant(Plant plant) async {
    // Cancel existing warning
    await _notificationService.cancelWiltWarning(plant.id);
    
    // Don't schedule if archived or snoozed
    if (plant.isArchived) return;
    if (plant.snoozedUntil != null && 
        DateTime.now().isBefore(plant.snoozedUntil!)) {
      return;
    }
    
    // Only schedule if approaching critical (currently thirsty or wilting)
    if (plant.healthState != PlantHealthState.thirsty &&
        plant.healthState != PlantHealthState.wilting) {
      return;
    }
    
    // Calculate time until critical
    final timeUntilCritical = HealthCalculator.timeUntilNextState(
      currentHealth: plant.currentHealth,
      difficultyLevel: plant.difficultyLevel,
    );
    
    if (timeUntilCritical == null) return;
    
    // Schedule warning 1 hour before critical
    final warningDelay = timeUntilCritical - const Duration(hours: 1);
    
    if (warningDelay.isNegative) {
      // Already past warning time, show now
      await _notificationService.scheduleWiltWarning(
        plant,
        const Duration(minutes: 5),
      );
    } else {
      await _notificationService.scheduleWiltWarning(plant, warningDelay);
    }
  }
  
  /// Schedule all upcoming reminders
  Future<void> scheduleReminders() async {
    final reminders = await _noteRepository.getUpcomingReminders();
    
    for (final note in reminders) {
      final plant = await _plantRepository.getPlant(note.plantId);
      if (plant != null) {
        await _notificationService.scheduleReminder(
          note: note,
          plantName: plant.displayName,
        );
      }
    }
  }
  
  /// Schedule a specific reminder
  Future<void> scheduleReminder(Note note, String plantName) async {
    await _notificationService.scheduleReminder(
      note: note,
      plantName: plantName,
    );
  }
  
  /// Cancel a specific reminder
  Future<void> cancelReminder(int noteId) async {
    await _notificationService.cancelReminder(noteId);
  }
  
  /// Reschedule notifications after a plant is watered
  Future<void> onPlantWatered(int plantId) async {
    final plant = await _plantRepository.getPlant(plantId);
    if (plant != null) {
      // Cancel existing Wilt Warning since plant is now healthier
      await _notificationService.cancelWiltWarning(plantId);
      
      // Schedule new warning based on new health
      await updateWiltWarningForPlant(plant);
    }
  }
  
  /// Cancel all notifications for a plant (e.g., when archived)
  Future<void> cancelNotificationsForPlant(int plantId) async {
    await _notificationService.cancelWiltWarning(plantId);
  }
  
  /// Trigger immediate Morning Dew check
  Future<void> triggerMorningDewNow() async {
    final thirstyPlants = await _plantRepository.getThirstiestPlants(5);
    final needsWater = thirstyPlants.where((p) => 
      p.healthState != PlantHealthState.thriving
    ).toList();
    
    if (needsWater.isNotEmpty) {
      await _notificationService.showMorningDewNow(needsWater);
    }
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(
    notificationService: ref.watch(notificationServiceProvider),
    plantRepository: ref.watch(plantRepositoryProvider),
    noteRepository: ref.watch(noteRepositoryProvider),
  );
});
```

### 3. Notification Settings UI (`lib/features/settings/widgets/notification_settings.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/notification_scheduler.dart';

// Notification preferences
final morningDewEnabledProvider = StateProvider<bool>((ref) => true);
final wiltWarningsEnabledProvider = StateProvider<bool>((ref) => true);
final remindersEnabledProvider = StateProvider<bool>((ref) => true);

class NotificationSettings extends ConsumerWidget {
  const NotificationSettings({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final morningDewEnabled = ref.watch(morningDewEnabledProvider);
    final wiltWarningsEnabled = ref.watch(wiltWarningsEnabledProvider);
    final remindersEnabled = ref.watch(remindersEnabledProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        
        SwitchListTile(
          title: const Text('Morning Dew'),
          subtitle: const Text('Daily 9 AM summary of thirsty plants'),
          value: morningDewEnabled,
          onChanged: (value) {
            ref.read(morningDewEnabledProvider.notifier).state = value;
            _updateMorningDew(ref, value);
          },
          secondary: const Icon(Icons.wb_sunny),
        ),
        
        SwitchListTile(
          title: const Text('Wilt Warnings'),
          subtitle: const Text('Alerts when plants approach critical state'),
          value: wiltWarningsEnabled,
          onChanged: (value) {
            ref.read(wiltWarningsEnabledProvider.notifier).state = value;
            _updateWiltWarnings(ref, value);
          },
          secondary: const Icon(Icons.warning_amber),
        ),
        
        SwitchListTile(
          title: const Text('Reminders'),
          subtitle: const Text('Notifications for note reminders'),
          value: remindersEnabled,
          onChanged: (value) {
            ref.read(remindersEnabledProvider.notifier).state = value;
            // Reminders are scheduled individually, just track preference
          },
          secondary: const Icon(Icons.alarm),
        ),
        
        const Divider(),
        
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Morning Dew Time'),
          subtitle: const Text('9:00 AM'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Time picker
          },
        ),
        
        const Divider(),
        
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _testNotification(ref),
            icon: const Icon(Icons.notifications_active),
            label: const Text('Test Notification'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _updateMorningDew(WidgetRef ref, bool enabled) async {
    final notificationService = ref.read(notificationServiceProvider);
    if (enabled) {
      await notificationService.scheduleMorningDew();
    } else {
      await notificationService.cancelMorningDew();
    }
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('morning_dew_enabled', enabled);
  }
  
  Future<void> _updateWiltWarnings(WidgetRef ref, bool enabled) async {
    if (enabled) {
      final scheduler = ref.read(notificationSchedulerProvider);
      await scheduler.scheduleWiltWarnings();
    } else {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.cancelAllWiltWarnings();
    }
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wilt_warnings_enabled', enabled);
  }
  
  Future<void> _testNotification(WidgetRef ref) async {
    final scheduler = ref.read(notificationSchedulerProvider);
    await scheduler.triggerMorningDewNow();
  }
}
```

### 4. Background Task Handler (`lib/core/services/background_task_service.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_scheduler.dart';

class BackgroundTaskService {
  final NotificationScheduler _scheduler;
  
  BackgroundTaskService(this._scheduler);
  
  /// Called when app comes to foreground
  Future<void> onAppResumed() async {
    // Reschedule notifications in case any expired
    await _scheduler.scheduleWiltWarnings();
  }
  
  /// Called periodically (e.g., via WorkManager on Android)
  Future<void> onBackgroundFetch() async {
    // Update Wilt Warnings based on current plant states
    await _scheduler.scheduleWiltWarnings();
  }
  
  /// Called at app startup
  Future<void> onAppStartup() async {
    await _scheduler.initializeNotifications();
  }
}

final backgroundTaskServiceProvider = Provider<BackgroundTaskService>((ref) {
  return BackgroundTaskService(ref.watch(notificationSchedulerProvider));
});
```

---

## Acceptance Criteria
- [ ] Notifications permission requested on iOS
- [ ] Morning Dew scheduled for 9 AM daily
- [ ] Morning Dew shows top 3 thirstiest plants by name
- [ ] Wilt Warning triggers ~1 hour before Critical state
- [ ] Wilt Warning canceled when plant is watered
- [ ] Reminders trigger at scheduled time
- [ ] Tapping notification opens relevant screen
- [ ] Settings allow toggling each notification type
- [ ] Notifications respect snooze/vacation mode
- [ ] Test notification button works

---

## iOS-Specific Notes
- Request notification permissions early but not immediately at launch
- Badge count can show number of thirsty plants
- Critical alerts (iOS 12+) could be used for Wilt Warnings
- Background App Refresh needed for timely notifications

---

## Required Setup

### iOS (Info.plist)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### timezone package setup
Add to pubspec.yaml:
```yaml
dependencies:
  timezone: ^0.9.2
```

---

## Dependencies
- Task 01: Project Setup
- Task 02: Data Models
- Task 04: Plant Health Engine
- Task 08: Notes & Journal (for reminders)

## Blocks
- Complete notification system
