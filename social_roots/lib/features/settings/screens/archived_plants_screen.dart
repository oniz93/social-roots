import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart'; // Added for isarProvider and filter
import '../../../core/services/database_service.dart'; // Added for isarProvider
import '../../../data/models/plant.dart';
import '../../../data/repositories/plant_repository.dart';

final archivedPlantsProvider = FutureProvider<List<Plant>>((ref) async {
  final isar = ref.watch(isarProvider);
  return isar.plants
      .filter()
      .isArchivedEqualTo(true)
      .sortByArchivedDateDesc()
      .findAll();
});

class ArchivedPlantsScreen extends ConsumerWidget {
  const ArchivedPlantsScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(archivedPlantsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Composted Plants'),
      ),
      body: plantsAsync.when(
        data: (plants) {
          if (plants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No composted plants',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              return _ArchivedPlantTile(
                plant: plant,
                onRestore: () => _restorePlant(context, ref, plant),
                onDelete: () => _deletePlant(context, ref, plant),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
  
  Future<void> _restorePlant(
    BuildContext context,
    WidgetRef ref,
    Plant plant,
  ) async {
    final repository = ref.read(plantRepositoryProvider);
    await repository.restorePlant(plant.id);
    ref.invalidate(archivedPlantsProvider);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${plant.displayName} restored!')),
      );
    }
  }
  
  Future<void> _deletePlant(
    BuildContext context,
    WidgetRef ref,
    Plant plant,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text(
          'This will permanently delete ${plant.displayName} and all its history. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final repository = ref.read(plantRepositoryProvider);
      await repository.deletePlant(plant.id);
      ref.invalidate(archivedPlantsProvider);
    }
  }
}

class _ArchivedPlantTile extends StatelessWidget {
  final Plant plant;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  
  const _ArchivedPlantTile({
    required this.plant,
    required this.onRestore,
    required this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Icon(
                Icons.local_florist,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    plant.plantType.displayName,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  if (plant.archivedDate != null)
                    Text(
                      'Composted ${DateFormat.yMMMd().format(plant.archivedDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: onRestore,
              child: const Text('Restore'),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
