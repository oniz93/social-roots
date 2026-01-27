import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/garden_providers.dart';
import '../widgets/plant_grid.dart';
import '../widgets/weather_background.dart';
import '../widgets/garden_app_bar.dart';
import '../widgets/empty_garden_state.dart';

class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the StreamProvider instead of FutureProvider for real-time updates
    final plantsAsync = ref.watch(watchPlantsProvider);
    final gardenHealth = ref.watch(gardenHealthProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GardenAppBar(),
      body: Stack(
        children: [
          // Dynamic weather background
          gardenHealth.when(
            data: (health) => WeatherBackground(healthPercentage: health),
            loading: () => const WeatherBackground(healthPercentage: 100),
            error: (_, __) => const WeatherBackground(healthPercentage: 50),
          ),

          // Main content
          SafeArea(
            child: plantsAsync.when(
              data: (plants) {
                if (plants.isEmpty) {
                  return const EmptyGardenState();
                }
                // Sort plants manually if the stream doesn't return them sorted
                // But the provider name `watchPlantsProvider` suggests it might just watch all plants.
                // Let's check `PlantRepository.watchAllPlants` implementation if possible or just sort here.
                // The task said `plantsStreamProvider` from `PlantRepository` but I used `watchAllPlants`.
                // For now, let's sort them here to be safe or assume the repository handles it.
                // Actually, let's just use the list as is, assuming the user might want to change sort later
                // but for now the requirement is "Thirstiest First".
                // Let's sort them here to be sure.
                final sortedPlants = List.of(plants);
                sortedPlants.sort(
                  (a, b) => a.currentHealth.compareTo(b.currentHealth),
                );

                return PlantGrid(plants: sortedPlants);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load garden',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextButton(
                      onPressed: () => ref.refresh(watchPlantsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
          context,
          '/contact-selection',
        ), // Changed to match existing route
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
