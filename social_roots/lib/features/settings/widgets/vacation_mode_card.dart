import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/vacation_mode_service.dart';

class VacationModeCard extends ConsumerWidget {
  const VacationModeCard({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActiveAsync = ref.watch(vacationModeActiveProvider);
    
    return isActiveAsync.when(
      data: (isActive) => _buildCard(context, ref, isActive),
      loading: () => const ListTile(
        leading: CircularProgressIndicator(),
        title: Text('Loading...'),
      ),
      error: (e, _) => ListTile(
        leading: const Icon(Icons.error),
        title: Text('Error: $e'),
      ),
    );
  }
  
  Widget _buildCard(BuildContext context, WidgetRef ref, bool isActive) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: isActive ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.beach_access,
                  color: isActive ? Colors.orange : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vacation Mode',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isActive 
                            ? 'Garden is being looked after' 
                            : 'Pause decay for all plants',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (value) {
                    if (value) {
                      _showVacationDialog(context, ref);
                    } else {
                      _deactivateVacation(ref);
                    }
                  },
                  activeTrackColor: Colors.orange,
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              FutureBuilder<DateTime?>(
                future: ref.read(vacationModeServiceProvider).getVacationEndTime(),
                builder: (context, snapshot) {
                  if (snapshot.data == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Ends ${DateFormat.yMMMd().add_jm().format(snapshot.data!)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showVacationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activate Vacation Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How long will you be away?'),
            const SizedBox(height: 24),
            ListTile(
              title: const Text('3 days'),
              onTap: () => _activateVacation(context, ref, const Duration(days: 3)),
            ),
            ListTile(
              title: const Text('1 week'),
              onTap: () => _activateVacation(context, ref, const Duration(days: 7)),
            ),
            ListTile(
              title: const Text('2 weeks'),
              onTap: () => _activateVacation(context, ref, const Duration(days: 14)),
            ),
            ListTile(
              title: const Text('1 month'),
              onTap: () => _activateVacation(context, ref, const Duration(days: 30)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _activateVacation(
    BuildContext context,
    WidgetRef ref,
    Duration duration,
  ) async {
    Navigator.pop(context);
    final service = ref.read(vacationModeServiceProvider);
    await service.activateVacationMode(duration);
    ref.invalidate(vacationModeActiveProvider);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vacation mode activated!')),
      );
    }
  }
  
  Future<void> _deactivateVacation(WidgetRef ref) async {
    final service = ref.read(vacationModeServiceProvider);
    await service.deactivateVacationMode();
    ref.invalidate(vacationModeActiveProvider);
  }
}
