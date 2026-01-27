# Task 04: Plant Health Engine

## Priority: HIGH
## Estimated Time: 4-5 hours
## Platform Focus: iOS First

---

## Objective
Implement the complete plant health system including decay calculation, watering mechanics, snooze/vacation mode, and health state transitions with Rive animation integration.

---

## Context
The health engine is the core game loop of Social Roots. It determines:
- How healthy each plant is based on time since last interaction
- When plants transition between health states
- How different interaction types restore health
- Special modes like snooze and vacation

### Health States
| State | Health % | Visual | User Feeling |
|-------|----------|--------|--------------|
| Thriving | 80-100% | Upright, swaying, vibrant | Pride |
| Thirsty | 60-79% | Slight droop, "feed me" icon | Gentle reminder |
| Wilting | 40-59% | Leaves curl, desaturated | Concern |
| Critical | 20-39% | Petals fall, stem bends | Urgency |
| Dormant | 0-19% | Dry stick | Guilt/Revival needed |

### Watering Types
| Type | Health Boost | Trigger |
|------|-------------|---------|
| Drop (Quick Text) | +20% | Short message, meme |
| Cup (Phone Call) | +50% | Voice/video call |
| Watering Can (Meetup) | +100% | In-person hangout |

---

## Implementation

### 1. Health Calculator Utility (`lib/core/utils/health_calculator.dart`)
```dart
import '../../data/models/plant.dart';

class HealthCalculator {
  /// Calculate current health for a plant
  static double calculateHealth({
    required DateTime lastWatered,
    required int difficultyLevel,
    DateTime? snoozedUntil,
    bool isArchived = false,
  }) {
    if (isArchived) return 0.0;
    
    final now = DateTime.now();
    
    // If snoozed, return full health
    if (snoozedUntil != null && now.isBefore(snoozedUntil)) {
      return 100.0;
    }
    
    final hoursSinceWatering = now.difference(lastWatered).inMinutes / 60.0;
    final gracePeriodHours = getGracePeriodHours(difficultyLevel);
    final decayRatePerHour = getDecayRatePerHour(difficultyLevel);
    
    // Still within grace period
    if (hoursSinceWatering <= gracePeriodHours) {
      return 100.0;
    }
    
    // Calculate decay
    final hoursDecaying = hoursSinceWatering - gracePeriodHours;
    final healthLost = hoursDecaying * decayRatePerHour;
    final health = 100.0 - healthLost;
    
    return health.clamp(0.0, 100.0);
  }
  
  /// Get grace period in hours based on difficulty
  static double getGracePeriodHours(int difficultyLevel) {
    switch (difficultyLevel) {
      case 1: return 7 * 24;   // 7 days (168 hours)
      case 2: return 3 * 24;   // 3 days (72 hours)
      case 3: return 2 * 24;   // 2 days (48 hours)
      default: return 3 * 24;
    }
  }
  
  /// Get decay rate per hour based on difficulty
  static double getDecayRatePerHour(int difficultyLevel) {
    switch (difficultyLevel) {
      case 1: return 0.5;   // 0.5% per hour (slower for MVP testing)
      case 2: return 2.0;   // 2% per hour
      case 3: return 5.0;   // 5% per hour
      default: return 2.0;
    }
  }
  
  /// Get health state from percentage
  static PlantHealthState getHealthState(double health) {
    if (health >= 80) return PlantHealthState.thriving;
    if (health >= 60) return PlantHealthState.thirsty;
    if (health >= 40) return PlantHealthState.wilting;
    if (health >= 20) return PlantHealthState.critical;
    return PlantHealthState.dormant;
  }
  
  /// Calculate time until next state transition
  static Duration? timeUntilNextState({
    required double currentHealth,
    required int difficultyLevel,
  }) {
    final decayRate = getDecayRatePerHour(difficultyLevel);
    final currentState = getHealthState(currentHealth);
    
    double nextThreshold;
    switch (currentState) {
      case PlantHealthState.thriving:
        nextThreshold = 80.0;
        break;
      case PlantHealthState.thirsty:
        nextThreshold = 60.0;
        break;
      case PlantHealthState.wilting:
        nextThreshold = 40.0;
        break;
      case PlantHealthState.critical:
        nextThreshold = 20.0;
        break;
      case PlantHealthState.dormant:
        return null; // Already at lowest state
    }
    
    final healthToLose = currentHealth - nextThreshold;
    final hoursUntilNext = healthToLose / decayRate;
    
    return Duration(minutes: (hoursUntilNext * 60).round());
  }
  
  /// Check if plant needs urgent attention
  static bool needsUrgentAttention(double health) {
    return health < 40; // Critical or Dormant
  }
  
  /// Check if plant is about to enter critical state
  static bool isApproachingCritical({
    required double currentHealth,
    required int difficultyLevel,
  }) {
    if (currentHealth <= 40) return false; // Already critical or worse
    
    final timeUntil = timeUntilNextState(
      currentHealth: currentHealth,
      difficultyLevel: difficultyLevel,
    );
    
    if (timeUntil == null) return false;
    
    // Alert if will become critical within 24 hours
    return currentHealth <= 60 && timeUntil.inHours <= 24;
  }
}
```

### 2. Plant Repository (`lib/data/repositories/plant_repository.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../core/services/database_service.dart';
import '../../core/utils/health_calculator.dart';
import '../models/plant.dart';
import '../models/interaction.dart';

class PlantRepository {
  final Isar _isar;
  
  PlantRepository(this._isar);
  
  // ==================== READ OPERATIONS ====================
  
  /// Get all active plants sorted by health (thirstiest first)
  Future<List<Plant>> getAllPlantsSortedByHealth() async {
    final plants = await _isar.plants
        .filter()
        .isArchivedEqualTo(false)
        .findAll();
    
    // Sort by health ascending (thirstiest first)
    plants.sort((a, b) => a.currentHealth.compareTo(b.currentHealth));
    return plants;
  }
  
  /// Get plants by health state
  Future<List<Plant>> getPlantsByState(PlantHealthState state) async {
    final plants = await getAllPlantsSortedByHealth();
    return plants.where((p) => p.healthState == state).toList();
  }
  
  /// Get the N thirstiest plants
  Future<List<Plant>> getThirstiestPlants(int count) async {
    final plants = await getAllPlantsSortedByHealth();
    return plants.take(count).toList();
  }
  
  /// Get plants needing urgent attention
  Future<List<Plant>> getPlantsNeedingAttention() async {
    final plants = await getAllPlantsSortedByHealth();
    return plants.where((p) => 
      HealthCalculator.needsUrgentAttention(p.currentHealth)
    ).toList();
  }
  
  /// Get plant by ID
  Future<Plant?> getPlant(int id) async {
    return _isar.plants.get(id);
  }
  
  /// Get plant by contact ID
  Future<Plant?> getPlantByContactId(String contactId) async {
    return _isar.plants
        .filter()
        .contactIdEqualTo(contactId)
        .findFirst();
  }
  
  /// Watch all plants (stream)
  Stream<List<Plant>> watchAllPlants() {
    return _isar.plants
        .filter()
        .isArchivedEqualTo(false)
        .watch(fireImmediately: true);
  }
  
  /// Watch a single plant
  Stream<Plant?> watchPlant(int id) {
    return _isar.plants.watchObject(id, fireImmediately: true);
  }
  
  // ==================== WRITE OPERATIONS ====================
  
  /// Create a new plant
  Future<Plant> createPlant({
    required String contactId,
    required String displayName,
    required PlantType plantType,
    required int difficultyLevel,
    String? photoUrl,
  }) async {
    final plant = Plant()
      ..contactId = contactId
      ..displayName = displayName
      ..plantType = plantType
      ..difficultyLevel = difficultyLevel
      ..photoUrl = photoUrl
      ..lastWatered = DateTime.now()
      ..plantedDate = DateTime.now();
    
    await _isar.writeTxn(() async {
      await _isar.plants.put(plant);
    });
    
    return plant;
  }
  
  /// Water a plant with an interaction
  Future<void> waterPlant({
    required int plantId,
    required InteractionType type,
    String? summary,
  }) async {
    await _isar.writeTxn(() async {
      final plant = await _isar.plants.get(plantId);
      if (plant == null) return;
      
      // Create interaction record
      final interaction = Interaction()
        ..plantId = plantId
        ..timestamp = DateTime.now()
        ..type = type
        ..summary = summary;
      
      await _isar.interactions.put(interaction);
      
      // Update plant's last watered time
      plant.lastWatered = DateTime.now();
      await _isar.plants.put(plant);
    });
  }
  
  /// Snooze a plant (pause decay)
  Future<void> snoozePlant(int plantId, Duration duration) async {
    await _isar.writeTxn(() async {
      final plant = await _isar.plants.get(plantId);
      if (plant == null) return;
      
      plant.snoozedUntil = DateTime.now().add(duration);
      await _isar.plants.put(plant);
    });
  }
  
  /// Cancel snooze for a plant
  Future<void> cancelSnooze(int plantId) async {
    await _isar.writeTxn(() async {
      final plant = await _isar.plants.get(plantId);
      if (plant == null) return;
      
      plant.snoozedUntil = null;
      await _isar.plants.put(plant);
    });
  }
  
  /// Archive (compost) a plant
  Future<void> archivePlant(int plantId) async {
    await _isar.writeTxn(() async {
      final plant = await _isar.plants.get(plantId);
      if (plant == null) return;
      
      plant.isArchived = true;
      plant.archivedDate = DateTime.now();
      await _isar.plants.put(plant);
    });
  }
  
  /// Restore an archived plant
  Future<void> restorePlant(int plantId) async {
    await _isar.writeTxn(() async {
      final plant = await _isar.plants.get(plantId);
      if (plant == null) return;
      
      plant.isArchived = false;
      plant.archivedDate = null;
      plant.lastWatered = DateTime.now(); // Reset health on restore
      await _isar.plants.put(plant);
    });
  }
  
  /// Delete a plant permanently
  Future<void> deletePlant(int plantId) async {
    await _isar.writeTxn(() async {
      // Delete associated interactions
      await _isar.interactions
          .filter()
          .plantIdEqualTo(plantId)
          .deleteAll();
      
      // Delete associated notes
      await _isar.notes
          .filter()
          .plantIdEqualTo(plantId)
          .deleteAll();
      
      // Delete the plant
      await _isar.plants.delete(plantId);
    });
  }
  
  // ==================== STATISTICS ====================
  
  /// Get garden health percentage
  Future<double> getGardenHealth() async {
    final plants = await getAllPlantsSortedByHealth();
    if (plants.isEmpty) return 100.0;
    
    final totalHealth = plants.fold<double>(
      0, (sum, plant) => sum + plant.currentHealth
    );
    
    return totalHealth / plants.length;
  }
  
  /// Get count of plants in each health state
  Future<Map<PlantHealthState, int>> getHealthDistribution() async {
    final plants = await getAllPlantsSortedByHealth();
    
    final distribution = <PlantHealthState, int>{};
    for (final state in PlantHealthState.values) {
      distribution[state] = 0;
    }
    
    for (final plant in plants) {
      distribution[plant.healthState] = 
          (distribution[plant.healthState] ?? 0) + 1;
    }
    
    return distribution;
  }
  
  /// Get percentage of healthy plants (for weather system)
  Future<double> getHealthyPercentage() async {
    final plants = await getAllPlantsSortedByHealth();
    if (plants.isEmpty) return 100.0;
    
    final healthyCount = plants.where((p) => 
      p.healthState == PlantHealthState.thriving ||
      p.healthState == PlantHealthState.thirsty
    ).length;
    
    return (healthyCount / plants.length) * 100;
  }
}

// Provider
final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return PlantRepository(isar);
});

// Stream provider for reactive plant list
final plantsStreamProvider = StreamProvider<List<Plant>>((ref) {
  final repository = ref.watch(plantRepositoryProvider);
  return repository.watchAllPlants();
});

// Future provider for thirstiest plants
final thirstiestPlantsProvider = FutureProvider.family<List<Plant>, int>((ref, count) {
  final repository = ref.watch(plantRepositoryProvider);
  return repository.getThirstiestPlants(count);
});

// Garden health provider
final gardenHealthProvider = FutureProvider<double>((ref) {
  final repository = ref.watch(plantRepositoryProvider);
  return repository.getGardenHealth();
});
```

### 3. Vacation Mode Service (`lib/core/services/vacation_mode_service.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/plant.dart';

class VacationModeService {
  final Isar _isar;
  
  static const _vacationEndKey = 'vacation_mode_end';
  
  VacationModeService(this._isar);
  
  /// Check if vacation mode is active
  Future<bool> isVacationModeActive() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeMs = prefs.getInt(_vacationEndKey);
    
    if (endTimeMs == null) return false;
    
    final endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMs);
    return DateTime.now().isBefore(endTime);
  }
  
  /// Get vacation mode end time
  Future<DateTime?> getVacationEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeMs = prefs.getInt(_vacationEndKey);
    
    if (endTimeMs == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(endTimeMs);
  }
  
  /// Activate vacation mode for all plants
  Future<void> activateVacationMode(Duration duration) async {
    final endTime = DateTime.now().add(duration);
    
    // Save end time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_vacationEndKey, endTime.millisecondsSinceEpoch);
    
    // Update all plants
    await _isar.writeTxn(() async {
      final plants = await _isar.plants
          .filter()
          .isArchivedEqualTo(false)
          .findAll();
      
      for (final plant in plants) {
        plant.snoozedUntil = endTime;
        await _isar.plants.put(plant);
      }
    });
  }
  
  /// Deactivate vacation mode
  Future<void> deactivateVacationMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vacationEndKey);
    
    // Clear snooze from all plants
    await _isar.writeTxn(() async {
      final plants = await _isar.plants
          .filter()
          .isArchivedEqualTo(false)
          .findAll();
      
      for (final plant in plants) {
        plant.snoozedUntil = null;
        await _isar.plants.put(plant);
      }
    });
  }
  
  /// Get remaining vacation time
  Future<Duration?> getRemainingVacationTime() async {
    final endTime = await getVacationEndTime();
    if (endTime == null) return null;
    
    final remaining = endTime.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }
}

final vacationModeServiceProvider = Provider<VacationModeService>((ref) {
  final isar = ref.watch(isarProvider);
  return VacationModeService(isar);
});

final vacationModeActiveProvider = FutureProvider<bool>((ref) {
  final service = ref.watch(vacationModeServiceProvider);
  return service.isVacationModeActive();
});
```

### 4. Rive Animation Controller (`lib/core/services/plant_animation_service.dart`)
```dart
import 'package:rive/rive.dart';

/// Controls Rive plant animations based on health state
class PlantAnimationController {
  late RiveAnimationController _controller;
  late StateMachineController? _stateMachine;
  SMINumber? _healthInput;
  SMITrigger? _waterTrigger;
  SMITrigger? _reviveTrigger;
  
  bool _isInitialized = false;
  
  /// Initialize with an Artboard
  void init(Artboard artboard) {
    _stateMachine = StateMachineController.fromArtboard(
      artboard,
      'PlantStateMachine', // State machine name in Rive file
    );
    
    if (_stateMachine != null) {
      artboard.addController(_stateMachine!);
      
      // Get inputs from state machine
      _healthInput = _stateMachine!.findInput<double>('health') as SMINumber?;
      _waterTrigger = _stateMachine!.findInput<bool>('water') as SMITrigger?;
      _reviveTrigger = _stateMachine!.findInput<bool>('revive') as SMITrigger?;
    }
    
    _isInitialized = true;
  }
  
  /// Update plant health (0.0 to 1.0)
  void setHealth(double health) {
    if (!_isInitialized || _healthInput == null) return;
    _healthInput!.value = health / 100.0; // Convert 0-100 to 0-1
  }
  
  /// Trigger watering animation
  void triggerWater() {
    if (!_isInitialized || _waterTrigger == null) return;
    _waterTrigger!.fire();
  }
  
  /// Trigger revival animation (for dormant plants)
  void triggerRevive() {
    if (!_isInitialized || _reviveTrigger == null) return;
    _reviveTrigger!.fire();
  }
  
  /// Clean up
  void dispose() {
    _stateMachine?.dispose();
  }
}

/// Widget wrapper for animated plant
class AnimatedPlant extends StatefulWidget {
  final String plantType;
  final double health;
  final bool showWaterAnimation;
  
  const AnimatedPlant({
    super.key,
    required this.plantType,
    required this.health,
    this.showWaterAnimation = false,
  });
  
  @override
  State<AnimatedPlant> createState() => _AnimatedPlantState();
}

class _AnimatedPlantState extends State<AnimatedPlant> {
  final PlantAnimationController _controller = PlantAnimationController();
  
  @override
  void didUpdateWidget(AnimatedPlant oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.health != widget.health) {
      _controller.setHealth(widget.health);
    }
    
    if (widget.showWaterAnimation && !oldWidget.showWaterAnimation) {
      _controller.triggerWater();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return RiveAnimation.asset(
      'assets/rive/plants/${widget.plantType}.riv',
      onInit: (artboard) {
        _controller.init(artboard);
        _controller.setHealth(widget.health);
      },
      fit: BoxFit.contain,
    );
  }
}
```

---

## Acceptance Criteria
- [ ] Health calculation correctly applies grace period and decay rate
- [ ] Different difficulty levels decay at different rates
- [ ] Watering restores correct health percentages
- [ ] Health states map correctly to health percentages
- [ ] Snooze mode pauses decay
- [ ] Vacation mode affects all plants
- [ ] Plants stream updates reactively
- [ ] Rive animation controller updates health smoothly
- [ ] Time until next state calculated correctly

---

## Test Cases
```dart
void main() {
  group('HealthCalculator', () {
    test('returns 100% within grace period', () {
      final health = HealthCalculator.calculateHealth(
        lastWatered: DateTime.now().subtract(Duration(days: 1)),
        difficultyLevel: 1, // 7 day grace
      );
      expect(health, equals(100.0));
    });
    
    test('decays correctly after grace period', () {
      final health = HealthCalculator.calculateHealth(
        lastWatered: DateTime.now().subtract(Duration(days: 8)), // Past 7-day grace
        difficultyLevel: 1, // 0.5% per hour decay
      );
      // 8 days = 192 hours, grace = 168 hours, decaying = 24 hours
      // Health = 100 - (24 * 0.5) = 88%
      expect(health, closeTo(88.0, 1.0));
    });
    
    test('snooze prevents decay', () {
      final health = HealthCalculator.calculateHealth(
        lastWatered: DateTime.now().subtract(Duration(days: 30)),
        difficultyLevel: 3,
        snoozedUntil: DateTime.now().add(Duration(days: 1)),
      );
      expect(health, equals(100.0));
    });
  });
}
```

---

## Dependencies
- Task 01: Project Setup
- Task 02: Data Models

## Blocks
- Task 05: Garden Home Screen
- Task 06: Plant Detail Screen
- Task 07: Watering Interaction
