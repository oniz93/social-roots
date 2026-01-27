# Task 06: Plant Detail Screen

## Priority: HIGH
## Estimated Time: 5-6 hours
## Platform Focus: iOS First

---

## Objective
Build the individual plant detail screen showing full plant visualization, interaction history, notes, and action buttons for watering and communication.

---

## Context
The Plant Detail screen is where users deeply engage with a single relationship. It shows:
- Large animated plant visualization
- Health status and time tracking
- Interaction history (past waterings)
- Notes/journal entries
- Quick action buttons (Call, Message, Email)
- Water button for logging new interactions

---

## Implementation

### 1. Plant Detail Screen (`lib/features/plant_detail/screens/plant_detail_screen.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/plant.dart';
import '../../../data/models/interaction.dart';
import '../../../data/repositories/plant_repository.dart';
import '../providers/plant_detail_providers.dart';
import '../widgets/plant_header.dart';
import '../widgets/health_status_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/interaction_history.dart';
import '../widgets/notes_section.dart';
import '../widgets/water_button.dart';

class PlantDetailScreen extends ConsumerWidget {
  final int plantId;
  
  const PlantDetailScreen({
    super.key,
    required this.plantId,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantAsync = ref.watch(plantDetailProvider(plantId));
    
    return plantAsync.when(
      data: (plant) {
        if (plant == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Plant not found')),
          );
        }
        return _PlantDetailContent(plant: plant);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PlantDetailContent extends ConsumerStatefulWidget {
  final Plant plant;
  
  const _PlantDetailContent({required this.plant});
  
  @override
  ConsumerState<_PlantDetailContent> createState() => _PlantDetailContentState();
}

class _PlantDetailContentState extends ConsumerState<_PlantDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible header with plant animation
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: _getBackgroundColor(plant.healthState),
            flexibleSpace: FlexibleSpaceBar(
              background: PlantHeader(plant: plant),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, plant),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'snooze',
                    child: ListTile(
                      leading: Icon(Icons.snooze),
                      title: Text('Snooze'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit Plant'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'compost',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Compost'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Health status card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: HealthStatusCard(plant: plant),
            ),
          ),
          
          // Quick action buttons (Call, Message, Email)
          SliverToBoxAdapter(
            child: QuickActions(plant: plant),
          ),
          
          // Tab bar for History/Notes
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabController: _tabController,
            ),
          ),
          
          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                InteractionHistory(plantId: plant.id),
                NotesSection(plantId: plant.id),
              ],
            ),
          ),
        ],
      ),
      
      // Water button
      floatingActionButton: WaterButton(
        plant: plant,
        onWatered: () => ref.refresh(plantDetailProvider(plant.id)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
  Color _getBackgroundColor(PlantHealthState state) {
    switch (state) {
      case PlantHealthState.thriving:
        return Colors.green.shade400;
      case PlantHealthState.thirsty:
        return Colors.green.shade300;
      case PlantHealthState.wilting:
        return Colors.orange.shade300;
      case PlantHealthState.critical:
        return Colors.red.shade300;
      case PlantHealthState.dormant:
        return Colors.grey.shade400;
    }
  }
  
  void _handleMenuAction(String action, Plant plant) {
    switch (action) {
      case 'snooze':
        _showSnoozeDialog(plant);
        break;
      case 'edit':
        Navigator.pushNamed(context, '/edit-plant', arguments: plant.id);
        break;
      case 'compost':
        _showCompostConfirmation(plant);
        break;
    }
  }
  
  void _showSnoozeDialog(Plant plant) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Snooze ${plant.displayName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Decay will pause during snooze.'),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('24 hours'),
              onTap: () => _snooze(const Duration(hours: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('3 days'),
              onTap: () => _snooze(const Duration(days: 3)),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('1 week'),
              onTap: () => _snooze(const Duration(days: 7)),
            ),
          ],
        ),
      ),
    );
  }
  
  void _snooze(Duration duration) {
    final repository = ref.read(plantRepositoryProvider);
    repository.snoozePlant(widget.plant.id, duration);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plant snoozed')),
    );
  }
  
  void _showCompostConfirmation(Plant plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compost this plant?'),
        content: Text(
          'This will archive ${plant.displayName}. '
          'You can restore it later from settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final repository = ref.read(plantRepositoryProvider);
              repository.archivePlant(plant.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to garden
            },
            child: const Text(
              'Compost',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  
  _TabBarDelegate({required this.tabController});
  
  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: tabController,
        labelColor: Colors.green,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.green,
        tabs: const [
          Tab(text: 'History', icon: Icon(Icons.history)),
          Tab(text: 'Notes', icon: Icon(Icons.note)),
        ],
      ),
    );
  }
  
  @override
  double get maxExtent => 72;
  
  @override
  double get minExtent => 72;
  
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
```

### 2. Plant Detail Providers (`lib/features/plant_detail/providers/plant_detail_providers.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/plant.dart';
import '../../../data/models/interaction.dart';
import '../../../data/models/note.dart';
import '../../../data/repositories/plant_repository.dart';
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
  final db = ref.watch(databaseServiceProvider);
  return db.getNotesForPlant(plantId);
});
```

### 3. Plant Header Widget (`lib/features/plant_detail/widgets/plant_header.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/plant.dart';

class PlantHeader extends StatelessWidget {
  final Plant plant;
  
  const PlantHeader({super.key, required this.plant});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _getGradientColors(),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40), // Space for app bar
            
            // Plant animation placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_florist,
                size: 80,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Plant name
            Text(
              plant.displayName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Plant type
            Text(
              plant.plantType.displayName,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Planted date
            Text(
              'Planted ${DateFormat.yMMMd().format(plant.plantedDate)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Color> _getGradientColors() {
    switch (plant.healthState) {
      case PlantHealthState.thriving:
        return [Colors.green.shade300, Colors.green.shade600];
      case PlantHealthState.thirsty:
        return [Colors.green.shade200, Colors.green.shade400];
      case PlantHealthState.wilting:
        return [Colors.orange.shade200, Colors.orange.shade400];
      case PlantHealthState.critical:
        return [Colors.red.shade200, Colors.red.shade400];
      case PlantHealthState.dormant:
        return [Colors.grey.shade300, Colors.grey.shade500];
    }
  }
}
```

### 4. Health Status Card (`lib/features/plant_detail/widgets/health_status_card.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/plant.dart';
import '../../../core/utils/health_calculator.dart';

class HealthStatusCard extends StatelessWidget {
  final Plant plant;
  
  const HealthStatusCard({super.key, required this.plant});
  
  @override
  Widget build(BuildContext context) {
    final health = plant.currentHealth;
    final state = plant.healthState;
    final timeUntilNext = HealthCalculator.timeUntilNextState(
      currentHealth: health,
      difficultyLevel: plant.difficultyLevel,
    );
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Health Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStateColor(state).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStateName(state),
                    style: TextStyle(
                      color: _getStateColor(state),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Health bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: health / 100,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(_getStateColor(state)),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${health.round()}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getStateColor(state),
                  ),
                ),
                if (timeUntilNext != null)
                  Text(
                    'Next state in ${_formatDuration(timeUntilNext)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Last watered
            Row(
              children: [
                Icon(Icons.water_drop, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Last watered: ${_formatLastWatered(plant.lastWatered)}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            
            // Snooze status
            if (plant.snoozedUntil != null &&
                DateTime.now().isBefore(plant.snoozedUntil!))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.snooze, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Snoozed until ${DateFormat.MMMd().format(plant.snoozedUntil!)}',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Color _getStateColor(PlantHealthState state) {
    switch (state) {
      case PlantHealthState.thriving:
        return Colors.green;
      case PlantHealthState.thirsty:
        return Colors.blue;
      case PlantHealthState.wilting:
        return Colors.orange;
      case PlantHealthState.critical:
        return Colors.red;
      case PlantHealthState.dormant:
        return Colors.grey;
    }
  }
  
  String _getStateName(PlantHealthState state) {
    switch (state) {
      case PlantHealthState.thriving:
        return 'Thriving';
      case PlantHealthState.thirsty:
        return 'Thirsty';
      case PlantHealthState.wilting:
        return 'Wilting';
      case PlantHealthState.critical:
        return 'Critical';
      case PlantHealthState.dormant:
        return 'Dormant';
    }
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inMinutes}m';
    }
  }
  
  String _formatLastWatered(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}
```

### 5. Quick Actions (`lib/features/plant_detail/widgets/quick_actions.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/plant.dart';
import '../../../core/services/contact_service.dart';

class QuickActions extends StatelessWidget {
  final Plant plant;
  
  const QuickActions({super.key, required this.plant});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.phone,
            label: 'Call',
            color: Colors.green,
            onTap: () => _makeCall(),
          ),
          _ActionButton(
            icon: Icons.message,
            label: 'Message',
            color: Colors.blue,
            onTap: () => _sendMessage(),
          ),
          _ActionButton(
            icon: Icons.email,
            label: 'Email',
            color: Colors.orange,
            onTap: () => _sendEmail(),
          ),
        ],
      ),
    );
  }
  
  Future<void> _makeCall() async {
    // In real implementation, get phone from contact
    // For now, show placeholder
    final uri = Uri.parse('tel:+1234567890');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  Future<void> _sendMessage() async {
    final uri = Uri.parse('sms:+1234567890');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  Future<void> _sendEmail() async {
    final uri = Uri.parse('mailto:example@email.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 6. Interaction History (`lib/features/plant_detail/widgets/interaction_history.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/interaction.dart';
import '../providers/plant_detail_providers.dart';

class InteractionHistory extends ConsumerWidget {
  final int plantId;
  
  const InteractionHistory({super.key, required this.plantId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(interactionHistoryProvider(plantId));
    
    return historyAsync.when(
      data: (interactions) {
        if (interactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No interactions yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                const Text('Water this plant to add your first interaction'),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: interactions.length,
          itemBuilder: (context, index) {
            final interaction = interactions[index];
            return _InteractionTile(interaction: interaction);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _InteractionTile extends StatelessWidget {
  final Interaction interaction;
  
  const _InteractionTile({required this.interaction});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(interaction.type).withOpacity(0.2),
          child: Icon(
            _getTypeIcon(interaction.type),
            color: _getTypeColor(interaction.type),
          ),
        ),
        title: Text(interaction.type.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat.yMMMd().add_jm().format(interaction.timestamp)),
            if (interaction.summary != null && interaction.summary!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  interaction.summary!,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
          ],
        ),
        trailing: Text(
          '+${interaction.type.healthBoost.round()}%',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  IconData _getTypeIcon(InteractionType type) {
    switch (type) {
      case InteractionType.quickText:
        return Icons.chat_bubble;
      case InteractionType.phoneCall:
        return Icons.phone;
      case InteractionType.meetup:
        return Icons.people;
    }
  }
  
  Color _getTypeColor(InteractionType type) {
    switch (type) {
      case InteractionType.quickText:
        return Colors.blue;
      case InteractionType.phoneCall:
        return Colors.green;
      case InteractionType.meetup:
        return Colors.purple;
    }
  }
}
```

### 7. Water Button (`lib/features/plant_detail/widgets/water_button.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/plant.dart';
import '../../../data/models/interaction.dart';
import '../../../data/repositories/plant_repository.dart';

class WaterButton extends ConsumerWidget {
  final Plant plant;
  final VoidCallback onWatered;
  
  const WaterButton({
    super.key,
    required this.plant,
    required this.onWatered,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _showWaterOptions(context, ref),
      backgroundColor: Colors.blue,
      icon: const Icon(Icons.water_drop),
      label: const Text('Water'),
    );
  }
  
  void _showWaterOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Interaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'How did you connect with ${plant.displayName}?',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            
            _WaterOption(
              icon: Icons.chat_bubble,
              title: 'Quick Text',
              subtitle: 'Sent a message, meme, or reaction',
              boost: '+20%',
              color: Colors.blue,
              onTap: () => _water(context, ref, InteractionType.quickText),
            ),
            const SizedBox(height: 12),
            
            _WaterOption(
              icon: Icons.phone,
              title: 'Phone Call',
              subtitle: 'Had a voice or video call',
              boost: '+50%',
              color: Colors.green,
              onTap: () => _water(context, ref, InteractionType.phoneCall),
            ),
            const SizedBox(height: 12),
            
            _WaterOption(
              icon: Icons.people,
              title: 'Hangout',
              subtitle: 'Met up in person',
              boost: '+100%',
              color: Colors.purple,
              onTap: () => _water(context, ref, InteractionType.meetup),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Future<void> _water(
    BuildContext context,
    WidgetRef ref,
    InteractionType type,
  ) async {
    Navigator.pop(context); // Close bottom sheet
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Water the plant
    final repository = ref.read(plantRepositoryProvider);
    await repository.waterPlant(
      plantId: plant.id,
      type: type,
    );
    
    // Play success animation/sound
    // TODO: Add Rive watering animation
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${plant.displayName} watered! +${type.healthBoost.round()}% health',
        ),
        backgroundColor: Colors.green,
      ),
    );
    
    // Refresh data
    onWatered();
  }
}

class _WaterOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String boost;
  final Color color;
  final VoidCallback onTap;
  
  const _WaterOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.boost,
    required this.color,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                boost,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Acceptance Criteria
- [ ] Plant detail screen loads correctly with plant data
- [ ] Header shows plant animation, name, type, and planted date
- [ ] Health status card displays current health with progress bar
- [ ] Time until next state shown when applicable
- [ ] Quick actions (Call, Message, Email) trigger appropriate apps
- [ ] Interaction history tab shows past waterings
- [ ] Notes tab shows journal entries (see Task 08)
- [ ] Water button opens interaction type selector
- [ ] Watering updates health and shows confirmation
- [ ] Snooze option available in menu
- [ ] Compost option archives plant

---

## Dependencies
- Task 01: Project Setup
- Task 02: Data Models
- Task 04: Plant Health Engine
- Task 05: Garden Home Screen

## Blocks
- Task 07: Watering Interaction (enhanced)
- Task 08: Notes & Journal
