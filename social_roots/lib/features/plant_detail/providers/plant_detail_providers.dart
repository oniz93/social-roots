import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/plant.dart';
import '../../../data/models/interaction.dart';
import '../../../data/models/note.dart';
import '../../../data/repositories/plant_repository.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../core/services/database_service.dart';

// Provider for single plant details
final plantDetailProvider = FutureProvider.family<Plant?, int>((ref, plantId) async {
  final repository = ref.watch(plantRepositoryProvider);
  return repository.getPlant(plantId);
});

// Stream provider for real-time updates
final plantStreamProvider = StreamProvider.family<Plant?, int>((ref, plantId) {
  final repository = ref.watch(plantRepositoryProvider);
  return repository.watchPlant(plantId);
});

// Interaction history provider
final interactionHistoryProvider = FutureProvider.family<List<Interaction>, int>((ref, plantId) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getInteractionsForPlant(plantId);
});

// Notes provider
final notesProvider = FutureProvider.family<List<Note>, int>((ref, plantId) async {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getNotesForPlant(plantId);
});
