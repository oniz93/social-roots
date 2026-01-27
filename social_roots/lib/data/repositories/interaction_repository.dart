import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../core/services/database_service.dart';
import '../models/interaction.dart';
import '../models/plant.dart';

class InteractionRepository {
  final Isar _isar;
  
  InteractionRepository(this._isar);
  
  // ==================== CREATE ====================
  
  /// Log a new interaction and update plant health
  Future<Interaction> logInteraction({
    required int plantId,
    required InteractionType type,
    String? summary,
    int? linkedNoteId,
  }) async {
    late Interaction interaction;
    
    await _isar.writeTxn(() async {
      // Create the interaction
      interaction = Interaction()
        ..plantId = plantId
        ..timestamp = DateTime.now()
        ..type = type
        ..summary = summary
        ..linkedNoteId = linkedNoteId;
      
      await _isar.interactions.put(interaction);
      
      // Update plant's lastWatered time
      final plant = await _isar.plants.get(plantId);
      if (plant != null) {
        plant.lastWatered = DateTime.now();
        await _isar.plants.put(plant);
      }
    });
    
    return interaction;
  }
  
  // ==================== READ ====================
  
  /// Get all interactions for a plant
  Future<List<Interaction>> getInteractionsForPlant(int plantId) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .sortByTimestampDesc()
        .findAll();
  }
  
  /// Get recent interactions for a plant (last N)
  Future<List<Interaction>> getRecentInteractions(int plantId, int limit) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();
  }
  
  /// Get interaction count for a plant
  Future<int> getInteractionCount(int plantId) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .count();
  }
  
  /// Get interactions by type
  Future<List<Interaction>> getInteractionsByType(
    int plantId,
    InteractionType type,
  ) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .typeEqualTo(type)
        .sortByTimestampDesc()
        .findAll();
  }
  
  /// Get interactions in date range
  Future<List<Interaction>> getInteractionsInRange(
    int plantId,
    DateTime start,
    DateTime end,
  ) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .timestampBetween(start, end)
        .sortByTimestampDesc()
        .findAll();
  }
  
  /// Get the last interaction for a plant
  Future<Interaction?> getLastInteraction(int plantId) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .sortByTimestampDesc()
        .findFirst();
  }
  
  // ==================== UPDATE ====================
  
  /// Update interaction summary
  Future<void> updateInteractionSummary(int interactionId, String summary) async {
    await _isar.writeTxn(() async {
      final interaction = await _isar.interactions.get(interactionId);
      if (interaction != null) {
        interaction.summary = summary;
        await _isar.interactions.put(interaction);
      }
    });
  }
  
  // ==================== DELETE ====================
  
  /// Delete an interaction
  Future<void> deleteInteraction(int interactionId) async {
    await _isar.writeTxn(() async {
      await _isar.interactions.delete(interactionId);
    });
  }
  
  /// Delete all interactions for a plant
  Future<void> deleteAllInteractions(int plantId) async {
    await _isar.writeTxn(() async {
      await _isar.interactions
          .filter()
          .plantIdEqualTo(plantId)
          .deleteAll();
    });
  }
  
  // ==================== STATISTICS ====================
  
  /// Get total interactions across all plants
  Future<int> getTotalInteractionCount() async {
    return _isar.interactions.count();
  }
  
  /// Get interaction breakdown by type for a plant
  Future<Map<InteractionType, int>> getInteractionBreakdown(int plantId) async {
    final breakdown = <InteractionType, int>{};
    
    for (final type in InteractionType.values) {
      breakdown[type] = await _isar.interactions
          .filter()
          .plantIdEqualTo(plantId)
          .typeEqualTo(type)
          .count();
    }
    
    return breakdown;
  }
  
  /// Get streak data (consecutive days with interactions)
  Future<int> getCurrentStreak(int plantId) async {
    final interactions = await getInteractionsForPlant(plantId);
    if (interactions.isEmpty) return 0;
    
    int streak = 1;
    DateTime lastDate = _dateOnly(interactions.first.timestamp);
    
    for (int i = 1; i < interactions.length; i++) {
      final currentDate = _dateOnly(interactions[i].timestamp);
      final diff = lastDate.difference(currentDate).inDays;
      
      if (diff == 1) {
        streak++;
        lastDate = currentDate;
      } else if (diff > 1) {
        break;
      }
    }
    
    return streak;
  }
  
  DateTime _dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}

final interactionRepositoryProvider = Provider<InteractionRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return InteractionRepository(isar);
});
