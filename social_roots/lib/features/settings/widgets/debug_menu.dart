import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../../../data/repositories/plant_repository.dart';

class DebugMenu extends ConsumerStatefulWidget {
  const DebugMenu({super.key});

  @override
  ConsumerState<DebugMenu> createState() => _DebugMenuState();
}

class _DebugMenuState extends ConsumerState<DebugMenu> {
  bool _isExpanded = false;
  bool _isLoading = false;

  Future<void> _runDebugAction(
    String actionName,
    Future<void> Function() action,
  ) async {
    setState(() => _isLoading = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$actionName completed'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.bug_report, color: Colors.orange),
          title: const Text('Debug Menu'),
          subtitle: const Text('Developer tools'),
          trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
        ),
        if (_isExpanded) ...[
          Container(
            color: Colors.orange.withValues(alpha: 0.05),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'These actions are for testing only',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _buildDebugTile(
                  icon: Icons.fast_forward,
                  title: 'Simulate 1 Day Passing',
                  subtitle: 'Move all plant timers forward by 24 hours',
                  onTap: () => _runDebugAction('Simulate 1 day', () async {
                    final repository = ref.read(plantRepositoryProvider);
                    await repository.debugSimulateTimePassing(
                      const Duration(days: 1),
                    );
                  }),
                ),
                _buildDebugTile(
                  icon: Icons.refresh,
                  title: 'Reset All Health Bars',
                  subtitle: 'Set all plants to 100% health',
                  onTap: () => _runDebugAction('Reset health', () async {
                    final repository = ref.read(plantRepositoryProvider);
                    await repository.debugResetAllHealth();
                  }),
                ),
                const Divider(height: 1),
                _buildDebugTile(
                  icon: Icons.alarm,
                  title: 'Send Reminder Notification',
                  subtitle: 'Test reminder notification',
                  onTap: () => _runDebugAction(
                    'Reminder notification',
                    () async {
                      final notificationService = ref.read(
                        notificationServiceProvider,
                      );
                      await notificationService.showTestReminderNotification();
                    },
                  ),
                ),
                _buildDebugTile(
                  icon: Icons.warning_amber,
                  title: 'Send Wilt Warning Notification',
                  subtitle: 'Test wilt warning notification',
                  onTap: () =>
                      _runDebugAction('Wilt warning notification', () async {
                        final notificationService = ref.read(
                          notificationServiceProvider,
                        );
                        await notificationService
                            .showTestWiltWarningNotification();
                      }),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDebugTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_arrow, size: 20),
      onTap: _isLoading ? null : onTap,
      dense: true,
    );
  }
}
