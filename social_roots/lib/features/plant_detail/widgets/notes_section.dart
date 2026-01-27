import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/note.dart';
import '../../../data/repositories/note_repository.dart';
import '../providers/plant_detail_providers.dart';
import 'add_note_sheet.dart';

class NotesSection extends ConsumerWidget {
  final int plantId;

  const NotesSection({super.key, required this.plantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider(plantId));

    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddNoteSheet(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Note'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 48),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No notes yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    const Text('Add notes to remember important details'),
                  ],
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: notes.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddNoteSheet(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Note'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              );
            }
            return NoteCard(
              note: notes[index - 1],
              onEdit: () => _showEditNoteSheet(context, ref, notes[index - 1]),
              onDelete: () => _deleteNote(ref, notes[index - 1]),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showAddNoteSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddNoteSheet(
        plantId: plantId,
        onSaved: () {
          Navigator.pop(context);
          ref.invalidate(notesProvider(plantId));
        },
      ),
    );
  }

  void _showEditNoteSheet(BuildContext context, WidgetRef ref, Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddNoteSheet(
        plantId: plantId,
        existingNote: note,
        onSaved: () {
          Navigator.pop(context);
          ref.invalidate(notesProvider(plantId));
        },
      ),
    );
  }

  Future<void> _deleteNote(WidgetRef ref, Note note) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.deleteNote(note.id);
    ref.invalidate(notesProvider(plantId));
  }
}

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tags
              if (note.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: note.tags
                      .map(
                        (tag) => Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: _getTagColor(tag).withOpacity(0.2),
                          labelStyle: TextStyle(color: _getTagColor(tag)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),

              if (note.tags.isNotEmpty) const SizedBox(height: 8),

              // Content
              Text(note.content, style: const TextStyle(fontSize: 15)),

              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  // Date
                  Text(
                    DateFormat.yMMMd().format(note.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  // Reminder indicator
                  if (note.reminderDate != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      note.reminderCompleted ? Icons.check_circle : Icons.alarm,
                      size: 16,
                      color: note.reminderCompleted
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.MMMd().format(note.reminderDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: note.reminderCompleted
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Delete button
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(context),
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'birthday':
        return Colors.pink;
      case 'gift idea':
        return Colors.purple;
      case 'work':
        return Colors.blue;
      case 'family':
        return Colors.green;
      case 'health':
        return Colors.red;
      case 'travel':
        return Colors.orange;
      case 'hobby':
        return Colors.teal;
      case 'important':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
