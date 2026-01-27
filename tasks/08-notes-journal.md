# Task 08: Notes & Journal System

## Priority: MEDIUM
## Estimated Time: 4-5 hours
## Platform Focus: iOS First

---

## Objective
Implement the note-taking and journal system for each plant, including quick tags, reminders, and the "Remember This" feature.

---

## Context
Notes are essential for the CRM aspect of Social Roots. They help users remember important details about their contacts, such as:
- Birthdays and anniversaries
- Family member names
- Work situations
- Gift ideas
- Health updates

### Key Features
- **Quick Tags:** Pre-set categories for fast organization
- **Reminders:** One-time notifications linked to notes
- **"Remember This":** Mark facts as important with reminder option
- **Search:** Find notes across all plants

---

## Implementation

### 1. Note Repository (`lib/data/repositories/note_repository.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../core/services/database_service.dart';
import '../models/note.dart';

class NoteRepository {
  final Isar _isar;
  
  NoteRepository(this._isar);
  
  // ==================== CREATE ====================
  
  /// Create a new note
  Future<Note> createNote({
    required int plantId,
    required String content,
    List<String> tags = const [],
    DateTime? reminderDate,
    String? reminderMessage,
  }) async {
    final note = Note()
      ..plantId = plantId
      ..content = content
      ..tags = tags
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..reminderDate = reminderDate
      ..reminderMessage = reminderMessage
      ..reminderCompleted = false;
    
    await _isar.writeTxn(() async {
      await _isar.notes.put(note);
    });
    
    return note;
  }
  
  // ==================== READ ====================
  
  /// Get all notes for a plant
  Future<List<Note>> getNotesForPlant(int plantId) async {
    return _isar.notes
        .filter()
        .plantIdEqualTo(plantId)
        .sortByCreatedAtDesc()
        .findAll();
  }
  
  /// Get notes with a specific tag
  Future<List<Note>> getNotesByTag(int plantId, String tag) async {
    return _isar.notes
        .filter()
        .plantIdEqualTo(plantId)
        .tagsElementContains(tag)
        .sortByCreatedAtDesc()
        .findAll();
  }
  
  /// Get all notes with reminders
  Future<List<Note>> getNotesWithReminders(int plantId) async {
    return _isar.notes
        .filter()
        .plantIdEqualTo(plantId)
        .reminderDateIsNotNull()
        .sortByReminderDate()
        .findAll();
  }
  
  /// Get upcoming reminders (all plants)
  Future<List<Note>> getUpcomingReminders() async {
    final now = DateTime.now();
    return _isar.notes
        .filter()
        .reminderDateIsNotNull()
        .reminderCompletedEqualTo(false)
        .reminderDateGreaterThan(now)
        .sortByReminderDate()
        .findAll();
  }
  
  /// Get overdue reminders
  Future<List<Note>> getOverdueReminders() async {
    final now = DateTime.now();
    return _isar.notes
        .filter()
        .reminderDateIsNotNull()
        .reminderCompletedEqualTo(false)
        .reminderDateLessThan(now)
        .sortByReminderDateDesc()
        .findAll();
  }
  
  /// Search notes by content
  Future<List<Note>> searchNotes(String query) async {
    return _isar.notes
        .filter()
        .contentContains(query, caseSensitive: false)
        .sortByCreatedAtDesc()
        .findAll();
  }
  
  /// Search notes for a specific plant
  Future<List<Note>> searchNotesForPlant(int plantId, String query) async {
    return _isar.notes
        .filter()
        .plantIdEqualTo(plantId)
        .contentContains(query, caseSensitive: false)
        .sortByCreatedAtDesc()
        .findAll();
  }
  
  /// Get a single note
  Future<Note?> getNote(int noteId) async {
    return _isar.notes.get(noteId);
  }
  
  // ==================== UPDATE ====================
  
  /// Update note content
  Future<void> updateNote({
    required int noteId,
    String? content,
    List<String>? tags,
  }) async {
    await _isar.writeTxn(() async {
      final note = await _isar.notes.get(noteId);
      if (note != null) {
        if (content != null) note.content = content;
        if (tags != null) note.tags = tags;
        note.updatedAt = DateTime.now();
        await _isar.notes.put(note);
      }
    });
  }
  
  /// Set/update reminder for a note
  Future<void> setReminder({
    required int noteId,
    required DateTime reminderDate,
    String? message,
  }) async {
    await _isar.writeTxn(() async {
      final note = await _isar.notes.get(noteId);
      if (note != null) {
        note.reminderDate = reminderDate;
        note.reminderMessage = message;
        note.reminderCompleted = false;
        note.updatedAt = DateTime.now();
        await _isar.notes.put(note);
      }
    });
  }
  
  /// Mark reminder as completed
  Future<void> completeReminder(int noteId) async {
    await _isar.writeTxn(() async {
      final note = await _isar.notes.get(noteId);
      if (note != null) {
        note.reminderCompleted = true;
        note.updatedAt = DateTime.now();
        await _isar.notes.put(note);
      }
    });
  }
  
  /// Remove reminder from note
  Future<void> removeReminder(int noteId) async {
    await _isar.writeTxn(() async {
      final note = await _isar.notes.get(noteId);
      if (note != null) {
        note.reminderDate = null;
        note.reminderMessage = null;
        note.reminderCompleted = false;
        note.updatedAt = DateTime.now();
        await _isar.notes.put(note);
      }
    });
  }
  
  // ==================== DELETE ====================
  
  /// Delete a note
  Future<void> deleteNote(int noteId) async {
    await _isar.writeTxn(() async {
      await _isar.notes.delete(noteId);
    });
  }
  
  /// Delete all notes for a plant
  Future<void> deleteAllNotes(int plantId) async {
    await _isar.writeTxn(() async {
      await _isar.notes
          .filter()
          .plantIdEqualTo(plantId)
          .deleteAll();
    });
  }
}

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return NoteRepository(isar);
});
```

### 2. Notes Section Widget (`lib/features/plant_detail/widgets/notes_section.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/note.dart';
import '../../../data/repositories/note_repository.dart';
import '../providers/plant_detail_providers.dart';

class NotesSection extends ConsumerWidget {
  final int plantId;
  
  const NotesSection({super.key, required this.plantId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider(plantId));
    
    return notesAsync.when(
      data: (notes) {
        return Column(
          children: [
            // Add note button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showAddNoteSheet(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Note'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            
            if (notes.isEmpty)
              Expanded(
                child: Center(
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
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    return NoteCard(
                      note: notes[index],
                      onEdit: () => _showEditNoteSheet(context, ref, notes[index]),
                      onDelete: () => _deleteNote(ref, notes[index]),
                    );
                  },
                ),
              ),
          ],
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
          ref.refresh(notesProvider(plantId));
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
          ref.refresh(notesProvider(plantId));
        },
      ),
    );
  }
  
  Future<void> _deleteNote(WidgetRef ref, Note note) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.deleteNote(note.id);
    ref.refresh(notesProvider(plantId));
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
                  children: note.tags.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                    backgroundColor: _getTagColor(tag).withOpacity(0.2),
                    labelStyle: TextStyle(color: _getTagColor(tag)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),
              
              if (note.tags.isNotEmpty)
                const SizedBox(height: 8),
              
              // Content
              Text(
                note.content,
                style: const TextStyle(fontSize: 15),
              ),
              
              const SizedBox(height: 12),
              
              // Footer
              Row(
                children: [
                  // Date
                  Text(
                    DateFormat.yMMMd().format(note.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  // Reminder indicator
                  if (note.reminderDate != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      note.reminderCompleted 
                          ? Icons.check_circle 
                          : Icons.alarm,
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
```

### 3. Add Note Sheet (`lib/features/plant_detail/widgets/add_note_sheet.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/note.dart';
import '../../../data/repositories/note_repository.dart';

class AddNoteSheet extends ConsumerStatefulWidget {
  final int plantId;
  final Note? existingNote;
  final VoidCallback onSaved;
  
  const AddNoteSheet({
    super.key,
    required this.plantId,
    this.existingNote,
    required this.onSaved,
  });
  
  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> {
  final _contentController = TextEditingController();
  final _reminderMessageController = TextEditingController();
  final Set<String> _selectedTags = {};
  DateTime? _reminderDate;
  bool _showReminder = false;
  
  bool get isEditing => widget.existingNote != null;
  
  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _contentController.text = widget.existingNote!.content;
      _selectedTags.addAll(widget.existingNote!.tags);
      _reminderDate = widget.existingNote!.reminderDate;
      _reminderMessageController.text = widget.existingNote!.reminderMessage ?? '';
      _showReminder = _reminderDate != null;
    }
  }
  
  @override
  void dispose() {
    _contentController.dispose();
    _reminderMessageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Note' : 'Add Note',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Quick Tags
              Text(
                'Quick Tags',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: NoteTags.all.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: Colors.green.shade100,
                    checkmarkColor: Colors.green,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Content
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Note',
                  hintText: 'What do you want to remember?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),
              
              const SizedBox(height: 24),
              
              // Reminder toggle
              SwitchListTile(
                title: const Text('Set Reminder'),
                subtitle: const Text('Get notified about this note'),
                value: _showReminder,
                onChanged: (value) {
                  setState(() {
                    _showReminder = value;
                    if (!value) {
                      _reminderDate = null;
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              // Reminder options
              if (_showReminder) ...[
                const SizedBox(height: 16),
                
                // Date picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _reminderDate != null
                        ? DateFormat.yMMMd().format(_reminderDate!)
                        : 'Select Date',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectDate(context),
                ),
                
                // Reminder message
                TextField(
                  controller: _reminderMessageController,
                  decoration: InputDecoration(
                    labelText: 'Reminder Message (optional)',
                    hintText: 'Ask about...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Save button
              ElevatedButton(
                onPressed: _contentController.text.isNotEmpty ? _save : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.green,
                ),
                child: Text(isEditing ? 'Save Changes' : 'Add Note'),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _reminderDate ?? DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      
      if (time != null) {
        setState(() {
          _reminderDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  Future<void> _save() async {
    final repository = ref.read(noteRepositoryProvider);
    
    if (isEditing) {
      await repository.updateNote(
        noteId: widget.existingNote!.id,
        content: _contentController.text,
        tags: _selectedTags.toList(),
      );
      
      if (_showReminder && _reminderDate != null) {
        await repository.setReminder(
          noteId: widget.existingNote!.id,
          reminderDate: _reminderDate!,
          message: _reminderMessageController.text.isNotEmpty
              ? _reminderMessageController.text
              : null,
        );
      } else if (!_showReminder && widget.existingNote!.reminderDate != null) {
        await repository.removeReminder(widget.existingNote!.id);
      }
    } else {
      await repository.createNote(
        plantId: widget.plantId,
        content: _contentController.text,
        tags: _selectedTags.toList(),
        reminderDate: _showReminder ? _reminderDate : null,
        reminderMessage: _showReminder && _reminderMessageController.text.isNotEmpty
            ? _reminderMessageController.text
            : null,
      );
    }
    
    widget.onSaved();
  }
}
```

### 4. Reminder List Widget (`lib/shared/widgets/reminder_list.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/note.dart';
import '../../data/models/plant.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/plant_repository.dart';

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
```

---

## Acceptance Criteria
- [ ] Notes can be created with content and optional tags
- [ ] Quick tags are available for fast categorization
- [ ] Notes can be edited and deleted
- [ ] Reminders can be set with date, time, and optional message
- [ ] Reminder indicator shows on notes with active reminders
- [ ] Reminders can be marked as completed
- [ ] Notes are sorted by creation date (newest first)
- [ ] Empty state shown when no notes exist
- [ ] Notes search works across all content

---

## Dependencies
- Task 01: Project Setup
- Task 02: Data Models
- Task 06: Plant Detail Screen

## Blocks
- Task 10: Notifications (reminders trigger notifications)
