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
                const Icon(Icons.water_drop, color: Colors.blue, size: 20),
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
                    const Icon(Icons.snooze, color: Colors.orange, size: 20),
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
