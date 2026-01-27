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
