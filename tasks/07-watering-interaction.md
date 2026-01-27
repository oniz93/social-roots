# Task 07: Watering & Interaction Logging

## Priority: HIGH
## Estimated Time: 4-5 hours
## Platform Focus: iOS First

---

## Objective
Implement the complete watering interaction flow including haptic feedback, visual animations, and optional interaction notes.

---

## Context
Watering is the core interaction loop of Social Roots. When a user "waters" a plant, they are logging an interaction with that contact. The experience should be satisfying and rewarding.

### Watering Types & Effects
| Type | Health Boost | Haptic | Animation |
|------|-------------|--------|-----------|
| Quick Text | +20% | Light tap | Water drop |
| Phone Call | +50% | Medium impact | Cup pour |
| Meetup | +100% | Heavy thud + success | Watering can + sparkles |

### Special: Revival Watering
When a dormant plant (0-19% health) receives a meetup interaction, it triggers a "Revival" animation with special audio/haptic feedback.

---

## Implementation

### 1. Interaction Repository (`lib/data/repositories/interaction_repository.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../core/services/database_service.dart';
import '../models/interaction.dart';
import '../models/plant.dart';

class InteractionRepository {
  final Isar _isar;
  
  InteractionRepository(this._isar);
  
  // ==================== CREATE ====================
  
  /// Log a new interaction and update plant health
  Future<Interaction> logInteraction({
    required int plantId,
    required InteractionType type,
    String? summary,
    int? linkedNoteId,
  }) async {
    late Interaction interaction;
    
    await _isar.writeTxn(() async {
      // Create the interaction
      interaction = Interaction()
        ..plantId = plantId
        ..timestamp = DateTime.now()
        ..type = type
        ..summary = summary
        ..linkedNoteId = linkedNoteId;
      
      await _isar.interactions.put(interaction);
      
      // Update plant's lastWatered time
      final plant = await _isar.plants.get(plantId);
      if (plant != null) {
        plant.lastWatered = DateTime.now();
        await _isar.plants.put(plant);
      }
    });
    
    return interaction;
  }
  
  // ==================== READ ====================
  
  /// Get all interactions for a plant
  Future<List<Interaction>> getInteractionsForPlant(int plantId) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .sortByTimestampDesc()
        .findAll();
  }
  
  /// Get recent interactions for a plant (last N)
  Future<List<Interaction>> getRecentInteractions(int plantId, int limit) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();
  }
  
  /// Get interaction count for a plant
  Future<int> getInteractionCount(int plantId) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .count();
  }
  
  /// Get interactions by type
  Future<List<Interaction>> getInteractionsByType(
    int plantId,
    InteractionType type,
  ) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .typeEqualTo(type)
        .sortByTimestampDesc()
        .findAll();
  }
  
  /// Get interactions in date range
  Future<List<Interaction>> getInteractionsInRange(
    int plantId,
    DateTime start,
    DateTime end,
  ) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .timestampBetween(start, end)
        .sortByTimestampDesc()
        .findAll();
  }
  
  /// Get the last interaction for a plant
  Future<Interaction?> getLastInteraction(int plantId) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .sortByTimestampDesc()
        .findFirst();
  }
  
  // ==================== UPDATE ====================
  
  /// Update interaction summary
  Future<void> updateInteractionSummary(int interactionId, String summary) async {
    await _isar.writeTxn(() async {
      final interaction = await _isar.interactions.get(interactionId);
      if (interaction != null) {
        interaction.summary = summary;
        await _isar.interactions.put(interaction);
      }
    });
  }
  
  // ==================== DELETE ====================
  
  /// Delete an interaction
  Future<void> deleteInteraction(int interactionId) async {
    await _isar.writeTxn(() async {
      await _isar.interactions.delete(interactionId);
    });
  }
  
  /// Delete all interactions for a plant
  Future<void> deleteAllInteractions(int plantId) async {
    await _isar.writeTxn(() async {
      await _isar.interactions
          .filter()
          .plantIdEqualTo(plantId)
          .deleteAll();
    });
  }
  
  // ==================== STATISTICS ====================
  
  /// Get total interactions across all plants
  Future<int> getTotalInteractionCount() async {
    return _isar.interactions.count();
  }
  
  /// Get interaction breakdown by type for a plant
  Future<Map<InteractionType, int>> getInteractionBreakdown(int plantId) async {
    final breakdown = <InteractionType, int>{};
    
    for (final type in InteractionType.values) {
      breakdown[type] = await _isar.interactions
          .filter()
          .plantIdEqualTo(plantId)
          .typeEqualTo(type)
          .count();
    }
    
    return breakdown;
  }
  
  /// Get streak data (consecutive days with interactions)
  Future<int> getCurrentStreak(int plantId) async {
    final interactions = await getInteractionsForPlant(plantId);
    if (interactions.isEmpty) return 0;
    
    int streak = 1;
    DateTime lastDate = _dateOnly(interactions.first.timestamp);
    
    for (int i = 1; i < interactions.length; i++) {
      final currentDate = _dateOnly(interactions[i].timestamp);
      final diff = lastDate.difference(currentDate).inDays;
      
      if (diff == 1) {
        streak++;
        lastDate = currentDate;
      } else if (diff > 1) {
        break;
      }
    }
    
    return streak;
  }
  
  DateTime _dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}

final interactionRepositoryProvider = Provider<InteractionRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return InteractionRepository(isar);
});
```

### 2. Haptic Service (`lib/core/services/haptic_service.dart`)
```dart
import 'package:flutter/services.dart';

class HapticService {
  /// Light haptic for quick text
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }
  
  /// Medium haptic for phone call
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
  
  /// Heavy haptic for meetup/revival
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
  
  /// Selection click
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
  
  /// Success pattern (for revival)
  static Future<void> successPattern() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.lightImpact();
  }
  
  /// Water flow simulation (rapid light taps)
  static Future<void> waterFlow({int duration = 1000}) async {
    final iterations = duration ~/ 50;
    for (int i = 0; i < iterations; i++) {
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
  
  /// Get haptic for interaction type
  static void forInteractionType(InteractionType type) {
    switch (type) {
      case InteractionType.quickText:
        lightImpact();
        break;
      case InteractionType.phoneCall:
        mediumImpact();
        break;
      case InteractionType.meetup:
        heavyImpact();
        break;
    }
  }
}
```

### 3. Audio Service (`lib/core/services/audio_service.dart`)
```dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;
  
  bool get isMuted => _isMuted;
  
  Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.stop);
  }
  
  void toggleMute() {
    _isMuted = !_isMuted;
  }
  
  /// Play water drop sound
  Future<void> playWaterDrop() async {
    if (_isMuted) return;
    await _player.play(AssetSource('audio/water_drop.mp3'));
  }
  
  /// Play water pour sound
  Future<void> playWaterPour() async {
    if (_isMuted) return;
    await _player.play(AssetSource('audio/water_pour.mp3'));
  }
  
  /// Play revival success chord
  Future<void> playRevivalSuccess() async {
    if (_isMuted) return;
    await _player.play(AssetSource('audio/revival_success.mp3'));
  }
  
  /// Play ambient garden sounds
  Future<void> playAmbient() async {
    if (_isMuted) return;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('audio/garden_ambient.mp3'));
  }
  
  /// Stop all sounds
  Future<void> stop() async {
    await _player.stop();
  }
  
  void dispose() {
    _player.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
```

### 4. Watering Controller (`lib/features/plant_detail/controllers/watering_controller.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
```

### 5. Enhanced Water Flow Widget (`lib/features/plant_detail/widgets/water_flow_animation.dart`)
```dart
import 'package:flutter/material.dart';

import '../../../data/models/interaction.dart';

class WaterFlowAnimation extends StatefulWidget {
  final InteractionType type;
  final VoidCallback? onComplete;
  
  const WaterFlowAnimation({
    super.key,
    required this.type,
    this.onComplete,
  });
  
  @override
  State<WaterFlowAnimation> createState() => _WaterFlowAnimationState();
}

class _WaterFlowAnimationState extends State<WaterFlowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dropAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: _getDuration()),
      vsync: this,
    );
    
    _dropAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }
  
  int _getDuration() {
    switch (widget.type) {
      case InteractionType.quickText:
        return 500;
      case InteractionType.phoneCall:
        return 800;
      case InteractionType.meetup:
        return 1200;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Water drops
            ..._buildWaterDrops(),
            
            // Central icon
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(),
                  size: 40,
                  color: Colors.blue,
                ),
              ),
            ),
            
            // Sparkles for meetup
            if (widget.type == InteractionType.meetup)
              ..._buildSparkles(),
          ],
        );
      },
    );
  }
  
  IconData _getIcon() {
    switch (widget.type) {
      case InteractionType.quickText:
        return Icons.water_drop;
      case InteractionType.phoneCall:
        return Icons.local_cafe;
      case InteractionType.meetup:
        return Icons.celebration;
    }
  }
  
  List<Widget> _buildWaterDrops() {
    final dropCount = widget.type == InteractionType.meetup ? 8 : 4;
    return List.generate(dropCount, (index) {
      final angle = (index / dropCount) * 2 * 3.14159;
      final distance = 60 * _dropAnimation.value;
      
      return Positioned(
        left: 50 + distance * cos(angle) - 10,
        top: 50 + distance * sin(angle) - 10,
        child: Opacity(
          opacity: 1 - _dropAnimation.value,
          child: Icon(
            Icons.water_drop,
            size: 20,
            color: Colors.blue.shade300,
          ),
        ),
      );
    });
  }
  
  List<Widget> _buildSparkles() {
    return List.generate(6, (index) {
      final angle = (index / 6) * 2 * 3.14159 + 0.5;
      final distance = 80 * _dropAnimation.value;
      
      return Positioned(
        left: 50 + distance * cos(angle) - 8,
        top: 50 + distance * sin(angle) - 8,
        child: Opacity(
          opacity: 1 - _dropAnimation.value,
          child: Icon(
            Icons.star,
            size: 16,
            color: Colors.yellow.shade600,
          ),
        ),
      );
    });
  }
}

double cos(double radians) => 
    (radians - radians * radians * radians / 6);
double sin(double radians) => 
    (radians - radians * radians * radians / 6 + radians * radians * radians * radians * radians / 120);
```

### 6. Quick Water Gesture Handler (`lib/features/garden/widgets/quick_water_handler.dart`)
```dart
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
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
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
```

### 7. Interaction Summary Input (`lib/features/plant_detail/widgets/interaction_summary_input.dart`)
```dart
import 'package:flutter/material.dart';

class InteractionSummaryInput extends StatefulWidget {
  final Function(String?) onSubmit;
  final VoidCallback onCancel;
  
  const InteractionSummaryInput({
    super.key,
    required this.onSubmit,
    required this.onCancel,
  });
  
  @override
  State<InteractionSummaryInput> createState() => _InteractionSummaryInputState();
}

class _InteractionSummaryInputState extends State<InteractionSummaryInput> {
  final _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a note (optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'What did you talk about?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => widget.onSubmit(null),
                child: const Text('Skip'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => widget.onSubmit(
                  _controller.text.isEmpty ? null : _controller.text,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## Acceptance Criteria
- [ ] All three interaction types log correctly with proper health boosts
- [ ] Haptic feedback triggers for each interaction type
- [ ] Audio plays for watering (when not muted)
- [ ] Revival animation triggers for dormant plants receiving meetup
- [ ] Quick water swipe gesture works from garden grid
- [ ] Optional summary can be added to interactions
- [ ] Interaction history shows in plant detail
- [ ] Undo option available briefly after quick water

---

## Audio Assets Required
Create placeholder audio files in `assets/audio/`:
- `water_drop.mp3` - Short drip sound
- `water_pour.mp3` - Longer pouring sound
- `revival_success.mp3` - Success chord
- `garden_ambient.mp3` - Optional ambient loop

---

## Dependencies
- Task 01: Project Setup
- Task 02: Data Models
- Task 04: Plant Health Engine
- Task 06: Plant Detail Screen

## Blocks
- Task 10: Notifications (interaction triggers notification updates)
