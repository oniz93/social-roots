import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/plant.dart';
import '../../../data/repositories/plant_repository.dart';
import 'plant_card.dart';

class PlantGrid extends StatelessWidget {
  final List<Plant> plants;

  const PlantGrid({super.key, required this.plants});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: plants.length,
      itemBuilder: (context, index) {
        final plant = plants[index];
        return PlantCard(
          plant: plant,
          onTap: () => _navigateToDetail(context, plant),
          onSwipeRight: () => _quickWater(context, plant),
          onSwipeLeft: () => _snoozePlant(context, plant),
        );
      },
    );
  }

  void _navigateToDetail(BuildContext context, Plant plant) {
    Navigator.pushNamed(context, '/plant-detail', arguments: plant.id);
  }

  void _quickWater(BuildContext context, Plant plant) {
    // Quick "thinking of you" text interaction
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent love to ${plant.displayName}!'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Undo logic
          },
        ),
      ),
    );
  }

  void _snoozePlant(BuildContext context, Plant plant) {
    // Snooze for 24 hours
    showModalBottomSheet(
      context: context,
      builder: (context) => _SnoozeSheet(plant: plant),
    );
  }
}

class _SnoozeSheet extends ConsumerWidget {
  final Plant plant;

  const _SnoozeSheet({required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Snooze ${plant.displayName}?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Decay will be paused during snooze.'),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('24 hours'),
            onTap: () => _snooze(context, ref, const Duration(hours: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('3 days'),
            onTap: () => _snooze(context, ref, const Duration(days: 3)),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('1 week'),
            onTap: () => _snooze(context, ref, const Duration(days: 7)),
          ),
        ],
      ),
    );
  }

  void _snooze(BuildContext context, WidgetRef ref, Duration duration) {
    final repository = ref.read(plantRepositoryProvider);
    repository.snoozePlant(plant.id, duration);
    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${plant.displayName} snoozed')));
  }
}
