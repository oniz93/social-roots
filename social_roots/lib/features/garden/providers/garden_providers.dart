import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/plant.dart';
import '../../../data/repositories/plant_repository.dart';

// Sorted plants provider (thirstiest first)
final sortedPlantsProvider = FutureProvider<List<Plant>>((ref) async {
  final repository = ref.watch(plantRepositoryProvider);
  return repository.getAllPlantsSortedByHealth();
});

// Watch plants for reactive updates
final watchPlantsProvider = StreamProvider<List<Plant>>((ref) {
  final repository = ref.watch(plantRepositoryProvider);
  return repository.watchAllPlants();
});

// Garden statistics
final gardenStatsProvider = FutureProvider<GardenStats>((ref) async {
  final repository = ref.watch(plantRepositoryProvider);
  final plants = await repository.getAllPlantsSortedByHealth();
  final distribution = await repository.getHealthDistribution();
  final health = await repository.getGardenHealth();

  return GardenStats(
    totalPlants: plants.length,
    healthDistribution: distribution,
    averageHealth: health,
  );
});

// Garden Health Provider
final gardenHealthProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(plantRepositoryProvider);
  return repository.getGardenHealth();
});

class GardenStats {
  final int totalPlants;
  final Map<PlantHealthState, int> healthDistribution;
  final double averageHealth;

  GardenStats({
    required this.totalPlants,
    required this.healthDistribution,
    required this.averageHealth,
  });

  int get thrivingCount => healthDistribution[PlantHealthState.thriving] ?? 0;
  int get thirstyCount => healthDistribution[PlantHealthState.thirsty] ?? 0;
  int get wiltingCount => healthDistribution[PlantHealthState.wilting] ?? 0;
  int get criticalCount => healthDistribution[PlantHealthState.critical] ?? 0;
  int get dormantCount => healthDistribution[PlantHealthState.dormant] ?? 0;

  int get needsAttentionCount => wiltingCount + criticalCount + dormantCount;
}
