import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/plant.dart';
import '../../../data/models/interaction.dart';
import '../../../data/repositories/interaction_repository.dart';
import '../../../core/services/haptic_service.dart';

/// Handles quick water gestures from the garden grid
class QuickWaterHandler {
  static Future<void> quickWater(
    BuildContext context,
    WidgetRef ref,
    Plant plant,
  ) async {
    // Quick text is the default for swipe actions
    const type = InteractionType.quickText;

    // Haptic feedback
    HapticService.lightImpact();

    // Log the interaction
    final repository = ref.read(interactionRepositoryProvider);
    await repository.logInteraction(
      plantId: plant.id,
      type: type,
      summary: 'Thinking of you',
    );

    // Show confirmation - capture ScaffoldMessenger before async gap
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.water_drop, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Sent love to ${plant.displayName}!'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Implement undo
          },
        ),
      ),
    );
  }
}
