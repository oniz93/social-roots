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
