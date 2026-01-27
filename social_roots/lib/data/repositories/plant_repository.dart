import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../core/services/database_service.dart';
import '../../core/utils/health_calculator.dart';
import '../models/plant.dart';
import '../models/interaction.dart';
import '../models/note.dart';

class PlantRepository {
  final Isar _isar;

  PlantRepository(this._isar);

  // ==================== READ OPERATIONS ====================

  /// Get all active plants sorted by health (thirstiest first)
  Future<List<Plant>> getAllPlantsSortedByHealth() async {
    final plants = await _isar.plants
        .filter()
        .isArchivedEqualTo(false)
        .findAll();

    // Sort by health ascending (thirstiest first)
    plants.sort((a, b) => a.currentHealth.compareTo(b.currentHealth));
    return plants;
  }

  /// Get plants by health state
  Future<List<Plant>> getPlantsByState(PlantHealthState state) async {
    final plants = await getAllPlantsSortedByHealth();
    return plants.where((p) => p.healthState == state).toList();
  }

  /// Get the N thirstiest plants
  Future<List<Plant>> getThirstiestPlants(int count) async {
    final plants = await getAllPlantsSortedByHealth();
    return plants.take(count).toList();
  }

  /// Get plants needing urgent attention
  Future<List<Plant>> getPlantsNeedingAttention() async {
    final plants = await getAllPlantsSortedByHealth();
    return plants
        .where((p) => HealthCalculator.needsUrgentAttention(p.currentHealth))
        .toList();
  }

  /// Get plant by ID
  Future<Plant?> getPlant(int id) async {
    return _isar.plants.get(id);
  }

  /// Get plant by contact ID
  Future<Plant?> getPlantByContactId(String contactId) async {
    return _isar.plants.filter().contactIdEqualTo(contactId).findFirst();
  }

  /// Watch all plants (stream)
  Stream<List<Plant>> watchAllPlants() {
    return _isar.plants
        .filter()
        .isArchivedEqualTo(false)
        .watch(fireImmediately: true);
  }

  /// Watch a single plant
  Stream<Plant?> watchPlant(int id) {
    return _isar.plants.watchObject(id, fireImmediately: true);
  }

  // ==================== WRITE OPERATIONS ====================

  /// Create a new plant
  Future<Plant> createPlant({
    required String contactId,
    required String displayName,
    required PlantType plantType,
    required int difficultyLevel,
    String? photoUrl,
  }) async {
    final plant = Plant()
      ..contactId = contactId
      ..displayName = displayName
      ..plantType = plantType
      ..difficultyLevel = difficultyLevel
      ..photoUrl = photoUrl
      ..lastWatered = DateTime.now()
      ..plantedDate = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.plants.put(plant);
    });

    return plant;
  }

  /// Water a plant with an interaction
  Future<void> waterPlant({
    required int plantId,
    required InteractionType type,
    String? summary,
  }) async {
    await _isar.writeTxn(() async {
      final plant = await _isar.plants.get(plantId);
      if (plant == null) return;

      // Create interaction record
      final interaction = Interaction()
        ..plantId = plantId
        ..timestamp = DateTime.now()
        ..type = type
        ..summary = summary;

      await _isar.interactions.put(interaction);

      // Update plant's last watered time
      plant.lastWatered = DateTime.now();
      await _isar.plants.put(plant);
    });
  }

  /// Snooze a plant (pause decay)
  Future<void> snoozePlant(int plantId, Duration duration) async {
    await _isar.writeTxn(() async {
      final plant = await _isar.plants.get(plantId);
      if (plant == null) return;

      plant.snoozedUntil = DateTime.now().add(duration);
      await _isar.plants.put(plant);
    });
  }

  /// Cancel snooze for a plant
  Future<void> cancelSnooze(int plantId) async {
    await _isar.writeTxn(() async {
      final plant = await _isar.plants.get(plantId);
      if (plant == null) return;

      plant.snoozedUntil = null;
      await _isar.plants.put(plant);
    });
  }

  /// Archive (compost) a plant
  Future<void> archivePlant(int plantId) async {
    await _isar.writeTxn(() async {
      final plant = await _isar.plants.get(plantId);
      if (plant == null) return;

      plant.isArchived = true;
      plant.archivedDate = DateTime.now();
      await _isar.plants.put(plant);
    });
  }

  /// Restore an archived plant
  Future<void> restorePlant(int plantId) async {
    await _isar.writeTxn(() async {
      final plant = await _isar.plants.get(plantId);
      if (plant == null) return;

      plant.isArchived = false;
      plant.archivedDate = null;
      plant.lastWatered = DateTime.now(); // Reset health on restore
      await _isar.plants.put(plant);
    });
  }

  /// Delete a plant permanently
  Future<void> deletePlant(int plantId) async {
    await _isar.writeTxn(() async {
      // Delete associated interactions
      await _isar.interactions.filter().plantIdEqualTo(plantId).deleteAll();

      // Delete associated notes
      await _isar.notes.filter().plantIdEqualTo(plantId).deleteAll();

      // Delete the plant
      await _isar.plants.delete(plantId);
    });
  }

  // ==================== STATISTICS ====================

  /// Get garden health percentage
  Future<double> getGardenHealth() async {
    final plants = await getAllPlantsSortedByHealth();
    if (plants.isEmpty) return 100.0;

    final totalHealth = plants.fold<double>(
      0,
      (sum, plant) => sum + plant.currentHealth,
    );

    return totalHealth / plants.length;
  }

  /// Get count of plants in each health state
  Future<Map<PlantHealthState, int>> getHealthDistribution() async {
    final plants = await getAllPlantsSortedByHealth();

    final distribution = <PlantHealthState, int>{};
    for (final state in PlantHealthState.values) {
      distribution[state] = 0;
    }

    for (final plant in plants) {
      distribution[plant.healthState] =
          (distribution[plant.healthState] ?? 0) + 1;
    }

    return distribution;
  }

  /// Get percentage of healthy plants (for weather system)
  Future<double> getHealthyPercentage() async {
    final plants = await getAllPlantsSortedByHealth();
    if (plants.isEmpty) return 100.0;

    final healthyCount = plants
        .where(
          (p) =>
              p.healthState == PlantHealthState.thriving ||
              p.healthState == PlantHealthState.thirsty,
        )
        .length;

    return (healthyCount / plants.length) * 100;
  }
}

// Provider
final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return PlantRepository(isar);
});

// Stream provider for reactive plant list
final plantsStreamProvider = StreamProvider<List<Plant>>((ref) {
  final repository = ref.watch(plantRepositoryProvider);
  return repository.watchAllPlants();
});

// Future provider for thirstiest plants
final thirstiestPlantsProvider = FutureProvider.family<List<Plant>, int>((
  ref,
  count,
) {
  final repository = ref.watch(plantRepositoryProvider);
  return repository.getThirstiestPlants(count);
});

// Garden health provider
final gardenHealthProvider = FutureProvider<double>((ref) {
  final repository = ref.watch(plantRepositoryProvider);
  return repository.getGardenHealth();
});
