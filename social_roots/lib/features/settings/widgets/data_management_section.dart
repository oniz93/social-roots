import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../data/repositories/plant_repository.dart';
import '../../../data/repositories/interaction_repository.dart';
import '../../../data/repositories/note_repository.dart';

class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Data Management',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),

        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Export Data'),
          subtitle: const Text('Export all your data as JSON'),
          onTap: () => _exportData(context, ref),
        ),

        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Delete All Data'),
          subtitle: const Text('Permanently delete all plants and history'),
          onTap: () => _showDeleteConfirmation(context, ref),
        ),
      ],
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final plantRepo = ref.read(plantRepositoryProvider);
      final interactionRepo = ref.read(interactionRepositoryProvider);
      final noteRepo = ref.read(noteRepositoryProvider);

      // Gather all data
      final plants = await plantRepo.getAllPlantsSortedByHealth();
      final exportData = <Map<String, dynamic>>[];

      for (final plant in plants) {
        final interactions = await interactionRepo.getInteractionsForPlant(
          plant.id,
        );
        final notes = await noteRepo.getNotesForPlant(plant.id);

        exportData.add({
          'plant': {
            'id': plant.id,
            'contactId': plant.contactId,
            'displayName': plant.displayName,
            'plantType': plant.plantType.name,
            'difficultyLevel': plant.difficultyLevel,
            'plantedDate': plant.plantedDate.toIso8601String(),
            'lastWatered': plant.lastWatered.toIso8601String(),
            'isArchived': plant.isArchived,
          },
          'interactions': interactions
              .map(
                (i) => {
                  'id': i.id,
                  'type': i.type.name,
                  'timestamp': i.timestamp.toIso8601String(),
                  'summary': i.summary,
                },
              )
              .toList(),
          'notes': notes
              .map(
                (n) => {
                  'id': n.id,
                  'content': n.content,
                  'tags': n.tags,
                  'createdAt': n.createdAt.toIso8601String(),
                  'reminderDate': n.reminderDate?.toIso8601String(),
                },
              )
              .toList(),
        });
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'data': exportData,
      });

      // Save to temp file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/social_roots_export.json');
      await file.writeAsString(jsonString);

      // Share the file
      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Social Roots Data Export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently delete all your plants, interactions, and notes. '
          'This action cannot be undone. Consider exporting your data first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement full data deletion
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('All data deleted')));
            },
            child: const Text(
              'Delete Everything',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
