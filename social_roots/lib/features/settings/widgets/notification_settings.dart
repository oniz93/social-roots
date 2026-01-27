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
