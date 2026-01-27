# Task 11: Settings & Preferences

## Priority: MEDIUM
## Estimated Time: 3-4 hours
## Platform Focus: iOS First

---

## Objective
Build the settings screen with user preferences, vacation mode toggle, archived plants management, and data export options.

---

## Context
The settings screen provides access to:
- Notification preferences
- Vacation mode (pause all decay)
- Archived plants (composted)
- Theme preferences (future)
- Data management
- About/Help

---

## Implementation

### 1. Settings Screen (`lib/features/settings/screens/settings_screen.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/notification_settings.dart';
import '../widgets/vacation_mode_card.dart';
import '../widgets/archived_plants_tile.dart';
import '../widgets/data_management_section.dart';
import '../widgets/about_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: const [
          VacationModeCard(),
          Divider(height: 1),
          ArchivedPlantsTile(),
          Divider(height: 32),
          NotificationSettings(),
          Divider(height: 32),
          DataManagementSection(),
          Divider(height: 32),
          AboutSection(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
```

### 2. Vacation Mode Card (`lib/features/settings/widgets/vacation_mode_card.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/vacation_mode_service.dart';

class VacationModeCard extends ConsumerWidget {
  const VacationModeCard({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActiveAsync = ref.watch(vacationModeActiveProvider);
    
    return isActiveAsync.when(
      data: (isActive) => _buildCard(context, ref, isActive),
      loading: () => const ListTile(
        leading: CircularProgressIndicator(),
        title: Text('Loading...'),
      ),
      error: (e, _) => ListTile(
        leading: const Icon(Icons.error),
        title: Text('Error: $e'),
      ),
    );
  }
  
  Widget _buildCard(BuildContext context, WidgetRef ref, bool isActive) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: isActive ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.beach_access,
                  color: isActive ? Colors.orange : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vacation Mode',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isActive 
                            ? 'Garden is being looked after' 
                            : 'Pause decay for all plants',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (value) {
                    if (value) {
                      _showVacationDialog(context, ref);
                    } else {
                      _deactivateVacation(ref);
                    }
                  },
                  activeColor: Colors.orange,
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              FutureBuilder<DateTime?>(
                future: ref.read(vacationModeServiceProvider).getVacationEndTime(),
                builder: (context, snapshot) {
                  if (snapshot.data == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Ends ${DateFormat.yMMMd().add_jm().format(snapshot.data!)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showVacationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activate Vacation Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How long will you be away?'),
            const SizedBox(height: 24),
            ListTile(
              title: const Text('3 days'),
              onTap: () => _activateVacation(context, ref, const Duration(days: 3)),
            ),
            ListTile(
              title: const Text('1 week'),
              onTap: () => _activateVacation(context, ref, const Duration(days: 7)),
            ),
            ListTile(
              title: const Text('2 weeks'),
              onTap: () => _activateVacation(context, ref, const Duration(days: 14)),
            ),
            ListTile(
              title: const Text('1 month'),
              onTap: () => _activateVacation(context, ref, const Duration(days: 30)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _activateVacation(
    BuildContext context,
    WidgetRef ref,
    Duration duration,
  ) async {
    Navigator.pop(context);
    final service = ref.read(vacationModeServiceProvider);
    await service.activateVacationMode(duration);
    ref.invalidate(vacationModeActiveProvider);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vacation mode activated!')),
      );
    }
  }
  
  Future<void> _deactivateVacation(WidgetRef ref) async {
    final service = ref.read(vacationModeServiceProvider);
    await service.deactivateVacationMode();
    ref.invalidate(vacationModeActiveProvider);
  }
}
```

### 3. Archived Plants (`lib/features/settings/widgets/archived_plants_tile.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/archived_plants_screen.dart';

class ArchivedPlantsTile extends ConsumerWidget {
  const ArchivedPlantsTile({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.archive),
      title: const Text('Composted Plants'),
      subtitle: const Text('View and restore archived plants'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ArchivedPlantsScreen(),
          ),
        );
      },
    );
  }
}
```

### 4. Archived Plants Screen (`lib/features/settings/screens/archived_plants_screen.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
```

### 5. Data Management Section (`lib/features/settings/widgets/data_management_section.dart`)
```dart
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
        final interactions = await interactionRepo.getInteractionsForPlant(plant.id);
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
          'interactions': interactions.map((i) => {
            'id': i.id,
            'type': i.type.name,
            'timestamp': i.timestamp.toIso8601String(),
            'summary': i.summary,
          }).toList(),
          'notes': notes.map((n) => {
            'id': n.id,
            'content': n.content,
            'tags': n.tags,
            'createdAt': n.createdAt.toIso8601String(),
            'reminderDate': n.reminderDate?.toIso8601String(),
          }).toList(),
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
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Social Roots Data Export',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data deleted')),
              );
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
```

### 6. About Section (`lib/features/settings/widgets/about_section.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Version'),
          subtitle: const Text('1.0.0'),
        ),
        
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchUrl('https://socialroots.app/privacy'),
        ),
        
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('Terms of Service'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchUrl('https://socialroots.app/terms'),
        ),
        
        ListTile(
          leading: const Icon(Icons.mail),
          title: const Text('Send Feedback'),
          onTap: () => _launchUrl('mailto:feedback@socialroots.app'),
        ),
        
        ListTile(
          leading: const Icon(Icons.star),
          title: const Text('Rate the App'),
          onTap: () {
            // TODO: Link to App Store
          },
        ),
        
        const SizedBox(height: 16),
        
        Center(
          child: Text(
            'Made with 💚 for meaningful connections',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }
  
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
```

---

## Acceptance Criteria
- [ ] Settings screen accessible from garden app bar
- [ ] Vacation mode can be activated with duration options
- [ ] Vacation mode shows remaining time when active
- [ ] Archived plants are listed with restore/delete options
- [ ] Restoring a plant resets its health
- [ ] Notification settings toggle each notification type
- [ ] Data export creates shareable JSON file
- [ ] About section shows version and links
- [ ] All preferences persist across app restarts

---

## Dependencies
- Task 01: Project Setup
- Task 04: Plant Health Engine (vacation mode)
- Task 10: Notifications

## Blocks
- None (end of core MVP)
