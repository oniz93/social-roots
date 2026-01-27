import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../data/models/plant.dart';
import '../../data/models/interaction.dart';
import '../../data/models/note.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar must be initialized in main.dart');
});

class DatabaseService {
  final Isar _isar;

  DatabaseService(this._isar);

  // Plant Operations
  Future<List<Plant>> getAllPlants({bool includeArchived = false}) async {
    if (includeArchived) {
      return _isar.plants.where().findAll();
    }
    return _isar.plants.filter().isArchivedEqualTo(false).findAll();
  }

  Future<Plant?> getPlantById(int id) async {
    return _isar.plants.get(id);
  }

  Future<Plant?> getPlantByContactId(String contactId) async {
    return _isar.plants.filter().contactIdEqualTo(contactId).findFirst();
  }

  Future<int> savePlant(Plant plant) async {
    return _isar.writeTxn(() => _isar.plants.put(plant));
  }

  Future<void> deletePlant(int id) async {
    await _isar.writeTxn(() => _isar.plants.delete(id));
  }

  Future<void> archivePlant(int id) async {
    final plant = await getPlantById(id);
    if (plant != null) {
      plant.isArchived = true;
      plant.archivedDate = DateTime.now();
      await savePlant(plant);
    }
  }

  // Interaction Operations
  Future<int> saveInteraction(Interaction interaction) async {
    return _isar.writeTxn(() => _isar.interactions.put(interaction));
  }

  Future<List<Interaction>> getInteractionsForPlant(int plantId) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .sortByTimestampDesc()
        .findAll();
  }

  // Note Operations
  Future<int> saveNote(Note note) async {
    note.updatedAt = DateTime.now();
    return _isar.writeTxn(() => _isar.notes.put(note));
  }

  Future<List<Note>> getNotesForPlant(int plantId) async {
    return _isar.notes
        .filter()
        .plantIdEqualTo(plantId)
        .sortByCreatedAtDesc()
        .findAll();
  }

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

  // Statistics
  Future<int> getTotalPlantCount() async {
    return _isar.plants.filter().isArchivedEqualTo(false).count();
  }

  Future<int> getHealthyPlantCount() async {
    final plants = await getAllPlants();
    return plants.where((p) => p.currentHealth >= 80).length;
  }

  Future<double> getGardenHealthPercentage() async {
    final plants = await getAllPlants();
    if (plants.isEmpty) return 100.0;

    final healthyCount = plants.where((p) => p.currentHealth >= 80).length;
    return (healthyCount / plants.length) * 100;
  }
}

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final isar = ref.watch(isarProvider);
  return DatabaseService(isar);
});
