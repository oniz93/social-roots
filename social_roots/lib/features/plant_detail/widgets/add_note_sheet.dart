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
