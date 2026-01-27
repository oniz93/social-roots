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
              child: const Icon(
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
