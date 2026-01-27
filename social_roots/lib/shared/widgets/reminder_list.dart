import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/note.dart';
import '../../data/repositories/note_repository.dart';
import '../../features/plant_detail/providers/plant_detail_providers.dart';

final upcomingRemindersProvider = FutureProvider<List<Note>>((ref) async {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getUpcomingReminders();
});

class ReminderList extends ConsumerWidget {
  const ReminderList({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(upcomingRemindersProvider);
    
    return remindersAsync.when(
      data: (reminders) {
        if (reminders.isEmpty) {
          return const Center(
            child: Text('No upcoming reminders'),
          );
        }
        
        return ListView.builder(
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            return ReminderTile(note: reminders[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class ReminderTile extends ConsumerWidget {
  final Note note;
  
  const ReminderTile({super.key, required this.note});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantAsync = ref.watch(plantDetailProvider(note.plantId));
    
    return plantAsync.when(
      data: (plant) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.orange.shade100,
            child: Icon(Icons.alarm, color: Colors.orange.shade700),
          ),
          title: Text(plant?.displayName ?? 'Unknown'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.reminderMessage ?? note.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                DateFormat.yMMMd().add_jm().format(note.reminderDate!),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            onPressed: () => _completeReminder(ref),
            icon: const Icon(Icons.check_circle_outline),
            color: Colors.green,
          ),
          onTap: () {
            // Navigate to plant detail
            Navigator.pushNamed(
              context,
              '/plant-detail',
              arguments: note.plantId,
            );
          },
        );
      },
      loading: () => const ListTile(
        leading: CircularProgressIndicator(),
      ),
      error: (e, _) => ListTile(
        title: Text('Error: $e'),
      ),
    );
  }
  
  Future<void> _completeReminder(WidgetRef ref) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.completeReminder(note.id);
    ref.refresh(upcomingRemindersProvider);
  }
}
