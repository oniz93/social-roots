import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/plant.dart';
import '../../../data/models/interaction.dart';
import '../controllers/watering_controller.dart';
import 'water_flow_animation.dart';
import 'interaction_summary_input.dart';

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
      isScrollControlled: true,
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
              iconAsset: InteractionType.quickText.icon,
              title: 'Quick Text',
              subtitle: 'Sent a message, meme, or reaction',
              boost: '+20%',
              color: Colors.blue,
              onTap: () => _handleWaterSelection(context, ref, InteractionType.quickText),
            ),
            const SizedBox(height: 12),
            
            _WaterOption(
              iconAsset: InteractionType.phoneCall.icon,
              title: 'Phone Call',
              subtitle: 'Had a voice or video call',
              boost: '+50%',
              color: Colors.green,
              onTap: () => _handleWaterSelection(context, ref, InteractionType.phoneCall),
            ),
            const SizedBox(height: 12),
            
            _WaterOption(
              iconAsset: InteractionType.meetup.icon,
              title: 'Hangout',
              subtitle: 'Met up in person',
              boost: '+100%',
              color: Colors.purple,
              onTap: () => _handleWaterSelection(context, ref, InteractionType.meetup),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  void _handleWaterSelection(
    BuildContext context,
    WidgetRef ref,
    InteractionType type,
  ) {
    Navigator.pop(context); // Close options sheet
    
    // Show summary input
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: InteractionSummaryInput(
          onCancel: () => Navigator.pop(context),
          onSubmit: (summary, photoPath) {
            Navigator.pop(context);
            _performWatering(context, ref, type, summary, photoPath);
          },
        ),
      ),
    );
  }
  
  Future<void> _performWatering(
    BuildContext context,
    WidgetRef ref,
    InteractionType type,
    String? summary,
    String? photoPath,
  ) async {
    // Show animation overlay
    showDialog(
      context: context,
      barrierColor: Colors.black12,
      barrierDismissible: false,
      builder: (context) => WaterFlowAnimation(
        type: type,
        onComplete: () => Navigator.pop(context),
      ),
    );
    
    // Execute logic
    final controller = ref.read(wateringControllerProvider(plant.id).notifier);
    final result = await controller.water(
      plant: plant,
      type: type,
      summary: summary,
      photoPath: photoPath,
    );
    
    // Show result
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.wasRevival ? Colors.purple : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    // Notify parent to refresh
    onWatered();
  }
}

class _WaterOption extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final String boost;
  final Color color;
  final VoidCallback onTap;
  
  const _WaterOption({
    required this.iconAsset,
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
              backgroundColor: color.withValues(alpha: 0.2),
              child: Image.asset(iconAsset, width: 30, height: 30),
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
                color: Colors.green.withValues(alpha: 0.2),
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
