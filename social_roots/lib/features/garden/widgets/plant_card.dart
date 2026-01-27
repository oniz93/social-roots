import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/plant_animation_service.dart';
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
                    // Plant illustration/Rive animation
                    Center(child: _buildPlantVisual()),

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
    // We use AnimatedPlant which uses Rive.
    // Since assets might be missing in dev environment, Rive might fail or show nothing.
    // Ideally we would wrap this in a builder or error handler, but for now we follow the instruction
    // to integrate the AnimatedPlant widget.

    if (kEnableRiveAnimations) {
      return SizedBox(
        width: 120,
        height: 120,
        child: AnimatedPlant(
          plantType: plant.plantType.name,
          health: plant.currentHealth,
        ),
      );
    }

    // Fallback Icon
    final healthState = plant.healthState;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.local_florist, size: 64, color: _getPlantColor(healthState)),
        if (healthState == PlantHealthState.thirsty ||
            healthState == PlantHealthState.wilting)
          const Icon(Icons.water_drop_outlined, size: 20, color: Colors.blue),
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
