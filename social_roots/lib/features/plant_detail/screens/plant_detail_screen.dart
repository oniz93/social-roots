import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/plant.dart';
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

  const PlantDetailScreen({super.key, required this.plantId});

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
  ConsumerState<_PlantDetailContent> createState() =>
      _PlantDetailContentState();
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
          SliverToBoxAdapter(child: QuickActions(plant: plant)),

          // Tab bar for History/Notes
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(tabController: _tabController),
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
        Navigator.pushNamed(context, '/edit-plant', arguments: plant.id).then((
          result,
        ) {
          // Refresh if changes were made
          if (result == true) {
            ref.refresh(plantDetailProvider(plant.id));
          }
        });
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Plant snoozed')));
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
            child: const Text('Compost', style: TextStyle(color: Colors.red)),
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
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
