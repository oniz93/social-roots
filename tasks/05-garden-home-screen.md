# Task 05: Garden Home Screen

## Priority: HIGH
## Estimated Time: 6-8 hours
## Platform Focus: iOS First

---

## Objective
Build the main Garden dashboard showing all plants in a grid layout with health indicators, weather system background, and sorting by thirstiness.

---

## Context
The Garden is the emotional center of Social Roots. Users see their "digital garden" with all their relationship plants. Key features:
- **Grid View:** Plants displayed in a responsive grid
- **Health Sorting:** Thirstiest plants automatically float to top
- **Weather System:** Background changes based on overall garden health
- **Quick Actions:** Tap to view details, swipe for quick interactions

### Weather System Rules
| Garden Health | Weather | Background |
|--------------|---------|------------|
| >80% healthy | Sunny | Bright, warm gradient |
| 50-80% healthy | Partly Cloudy | Neutral gradient |
| <50% healthy | Rainy/Overcast | Dark, grey gradient |

---

## Implementation

### 1. Garden Screen (`lib/features/garden/screens/garden_screen.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/plant.dart';
import '../../../data/repositories/plant_repository.dart';
import '../providers/garden_providers.dart';
import '../widgets/plant_grid.dart';
import '../widgets/weather_background.dart';
import '../widgets/garden_app_bar.dart';
import '../widgets/empty_garden_state.dart';

class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(sortedPlantsProvider);
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
                return PlantGrid(plants: plants);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load garden',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextButton(
                      onPressed: () => ref.refresh(sortedPlantsProvider),
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
        onPressed: () => Navigator.pushNamed(context, '/add-plant'),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 2. Garden Providers (`lib/features/garden/providers/garden_providers.dart`)
```dart
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
```

### 3. Weather Background (`lib/features/garden/widgets/weather_background.dart`)
```dart
import 'package:flutter/material.dart';

class WeatherBackground extends StatelessWidget {
  final double healthPercentage;
  
  const WeatherBackground({
    super.key,
    required this.healthPercentage,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: _getGradient(),
      ),
      child: Stack(
        children: [
          // Weather effects
          if (healthPercentage < 50) _buildRainEffect(),
          if (healthPercentage >= 80) _buildSunEffect(),
        ],
      ),
    );
  }
  
  LinearGradient _getGradient() {
    if (healthPercentage >= 80) {
      // Sunny day
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF87CEEB), // Sky blue
          Color(0xFF98FB98), // Pale green
          Color(0xFF90EE90), // Light green (grass)
        ],
        stops: [0.0, 0.6, 1.0],
      );
    } else if (healthPercentage >= 50) {
      // Partly cloudy
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFB0C4DE), // Light steel blue
          Color(0xFFA8C8A8), // Sage green
          Color(0xFF8FBC8F), // Dark sea green
        ],
        stops: [0.0, 0.6, 1.0],
      );
    } else {
      // Overcast/Rainy
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF696969), // Dim gray
          Color(0xFF808080), // Gray
          Color(0xFF6B8E6B), // Muted green
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
  }
  
  Widget _buildSunEffect() {
    return Positioned(
      top: 60,
      right: 40,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.yellow.shade300,
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.shade200.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRainEffect() {
    // Simple rain overlay
    return Positioned.fill(
      child: CustomPaint(
        painter: RainPainter(),
      ),
    );
  }
}

class RainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;
    
    // Draw simple rain lines
    for (int i = 0; i < 50; i++) {
      final x = (i * 20.0) % size.width;
      final y1 = (i * 15.0) % size.height;
      final y2 = y1 + 20;
      
      canvas.drawLine(
        Offset(x, y1),
        Offset(x - 5, y2),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 4. Plant Grid (`lib/features/garden/widgets/plant_grid.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/plant.dart';
import 'plant_card.dart';

class PlantGrid extends StatelessWidget {
  final List<Plant> plants;
  
  const PlantGrid({
    super.key,
    required this.plants,
  });
  
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
    Navigator.pushNamed(
      context,
      '/plant-detail',
      arguments: plant.id,
    );
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plant.displayName} snoozed')),
    );
  }
}
```

### 5. Plant Card (`lib/features/garden/widgets/plant_card.dart`)
```dart
import 'package:flutter/material.dart';

import '../../../data/models/plant.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;
  
  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.onSwipeRight,
    this.onSwipeLeft,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('plant_${plant.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onSwipeRight?.call();
        } else {
          onSwipeLeft?.call();
        }
        return false; // Don't actually dismiss
      },
      background: _buildSwipeBackground(
        icon: Icons.favorite,
        color: Colors.pink,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        icon: Icons.snooze,
        color: Colors.orange,
        alignment: Alignment.centerRight,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Plant visual
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Plant illustration/Rive animation placeholder
                    Center(
                      child: _buildPlantVisual(),
                    ),
                    
                    // Health indicator
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildHealthIndicator(),
                    ),
                    
                    // Snooze indicator
                    if (plant.snoozedUntil != null &&
                        DateTime.now().isBefore(plant.snoozedUntil!))
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.snooze, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Snoozed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Soil/pot area
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _getSoilColor(),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      plant.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.plantType.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSwipeBackground({
    required IconData icon,
    required Color color,
    required Alignment alignment,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: color, size: 28),
    );
  }
  
  Widget _buildPlantVisual() {
    // Placeholder - will be replaced with Rive animation
    final healthState = plant.healthState;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.local_florist,
          size: 64,
          color: _getPlantColor(healthState),
        ),
        if (healthState == PlantHealthState.thirsty ||
            healthState == PlantHealthState.wilting)
          const Icon(
            Icons.water_drop_outlined,
            size: 20,
            color: Colors.blue,
          ),
      ],
    );
  }
  
  Widget _buildHealthIndicator() {
    final health = plant.currentHealth;
    final state = plant.healthState;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStateColor(state).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${health.round()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Color _getPlantColor(PlantHealthState state) {
    switch (state) {
      case PlantHealthState.thriving:
        return Colors.green.shade600;
      case PlantHealthState.thirsty:
        return Colors.green.shade400;
      case PlantHealthState.wilting:
        return Colors.yellow.shade700;
      case PlantHealthState.critical:
        return Colors.orange.shade700;
      case PlantHealthState.dormant:
        return Colors.brown.shade400;
    }
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
  
  Color _getSoilColor() {
    // Soil color changes based on health (dark = wet, light = dry)
    final health = plant.currentHealth;
    
    if (health >= 80) {
      return const Color(0xFF5D4037); // Dark brown (wet)
    } else if (health >= 60) {
      return const Color(0xFF795548); // Medium brown
    } else if (health >= 40) {
      return const Color(0xFF8D6E63); // Light brown
    } else {
      return const Color(0xFFBCAAA4); // Tan (dry)
    }
  }
}
```

### 6. Garden App Bar (`lib/features/garden/widgets/garden_app_bar.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/garden_providers.dart';

class GardenAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const GardenAppBar({super.key});
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(gardenStatsProvider);
    
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'My Garden',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Quick stats button
        stats.when(
          data: (s) => IconButton(
            onPressed: () => _showStats(context, s),
            icon: Badge(
              isLabelVisible: s.needsAttentionCount > 0,
              label: Text('${s.needsAttentionCount}'),
              child: const Icon(Icons.bar_chart, color: Colors.white),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        
        // Settings
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    );
  }
  
  void _showStats(BuildContext context, GardenStats stats) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Garden Health',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'Thriving',
              count: stats.thrivingCount,
              color: Colors.green,
            ),
            _StatRow(
              label: 'Thirsty',
              count: stats.thirstyCount,
              color: Colors.blue,
            ),
            _StatRow(
              label: 'Wilting',
              count: stats.wiltingCount,
              color: Colors.orange,
            ),
            _StatRow(
              label: 'Critical',
              count: stats.criticalCount,
              color: Colors.red,
            ),
            _StatRow(
              label: 'Dormant',
              count: stats.dormantCount,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stats.averageHealth / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                stats.averageHealth >= 80 ? Colors.green :
                stats.averageHealth >= 50 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Average Health: ${stats.averageHealth.round()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  
  const _StatRow({
    required this.label,
    required this.count,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
```

### 7. Empty Garden State (`lib/features/garden/widgets/empty_garden_state.dart`)
```dart
import 'package:flutter/material.dart';

class EmptyGardenState extends StatelessWidget {
  const EmptyGardenState({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 24),
            Text(
              'Your garden is empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first plant to start nurturing your relationships',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-plant'),
              icon: const Icon(Icons.add),
              label: const Text('Plant Your First Seed'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
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
- [ ] Garden screen displays all non-archived plants
- [ ] Plants are sorted by health (thirstiest first)
- [ ] Each plant card shows name, type, and health percentage
- [ ] Weather background changes based on overall garden health
- [ ] Swipe right on plant triggers quick water action
- [ ] Swipe left on plant shows snooze options
- [ ] Tap on plant navigates to detail screen
- [ ] Empty state shown when no plants exist
- [ ] Stats modal shows health distribution
- [ ] Soil color changes based on plant health

---

## UI/UX Notes
- Use haptic feedback on swipe actions
- Animate weather transitions smoothly (500ms)
- Consider adding pull-to-refresh for manual data reload
- Plant cards should have subtle shadows for depth
- Grid should be responsive (2 columns on phone, 3 on tablet)

---

## Dependencies
- Task 01: Project Setup
- Task 02: Data Models
- Task 04: Plant Health Engine

## Blocks
- Task 06: Plant Detail Screen
- Task 07: Watering Interaction
