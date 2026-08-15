import 'package:flutter_riverpod/legacy.dart';

import '../../../data/models/plant.dart';
import '../../../data/models/interaction.dart';
import '../../../data/repositories/interaction_repository.dart';
import '../../../data/repositories/plant_repository.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/audio_service.dart';

enum WateringState {
  idle,
  watering,
  success,
  revival,
}

class WateringResult {
  final bool success;
  final double healthBefore;
  final double healthAfter;
  final bool wasRevival;
  final String message;
  
  WateringResult({
    required this.success,
    required this.healthBefore,
    required this.healthAfter,
    required this.wasRevival,
    required this.message,
  });
}

class WateringController extends StateNotifier<WateringState> {
  final InteractionRepository _interactionRepository;
  final PlantRepository _plantRepository;
  final AudioService _audioService;
  
  WateringController({
    required InteractionRepository interactionRepository,
    required PlantRepository plantRepository,
    required AudioService audioService,
  })  : _interactionRepository = interactionRepository,
        _plantRepository = plantRepository,
        _audioService = audioService,
        super(WateringState.idle);
  
  Future<WateringResult> water({
    required Plant plant,
    required InteractionType type,
    String? summary,
    String? photoPath,
  }) async {
    state = WateringState.watering;
    
    final healthBefore = plant.currentHealth;
    final wasDormant = plant.healthState == PlantHealthState.dormant;
    
    // Trigger haptic based on type
    HapticService.forInteractionType(type);
    
    // Log the interaction
    await _interactionRepository.logInteraction(
      plantId: plant.id,
      type: type,
      summary: summary,
      photoPath: photoPath,
    );
    
    // Refresh plant data
    final updatedPlant = await _plantRepository.getPlant(plant.id);
    final healthAfter = updatedPlant?.currentHealth ?? 100;
    
    // Check for revival
    final isRevival = wasDormant && type == InteractionType.meetup;
    
    if (isRevival) {
      state = WateringState.revival;
      await HapticService.successPattern();
      await _audioService.playRevivalSuccess();
    } else {
      state = WateringState.success;
      // Play appropriate sound
      switch (type) {
        case InteractionType.quickText:
          await _audioService.playWaterDrop();
          break;
        case InteractionType.phoneCall:
        case InteractionType.meetup:
          await _audioService.playWaterPour();
          break;
      }
    }
    
    // Reset state after animation
    await Future.delayed(const Duration(milliseconds: 1500));
    state = WateringState.idle;
    
    return WateringResult(
      success: true,
      healthBefore: healthBefore,
      healthAfter: healthAfter,
      wasRevival: isRevival,
      message: isRevival 
          ? '${plant.displayName} has been revived!' 
          : 'Watered ${plant.displayName}! +${type.healthBoost.round()}%',
    );
  }
}

final wateringControllerProvider = StateNotifierProvider.family<
    WateringController, WateringState, int>((ref, plantId) {
  return WateringController(
    interactionRepository: ref.watch(interactionRepositoryProvider),
    plantRepository: ref.watch(plantRepositoryProvider),
    audioService: ref.watch(audioServiceProvider),
  );
});
