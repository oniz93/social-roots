# Task 02: Isar Data Models

## Priority: HIGH
## Estimated Time: 3-4 hours
## Platform Focus: iOS First

---

## Objective
Implement the Isar database schema with Plant, Interaction, and Note models including the health decay algorithm.

---

## Context
The data model is the backbone of Social Roots. Each Plant represents a contact and tracks:
- Health status (0-100%)
- Last interaction date
- Plant type and difficulty level
- Linked interactions and notes

### The Decay Algorithm
```
Health = 100 - ((HoursSinceWatering - GracePeriod) / DecayRate)
```

**Plant Difficulty Levels:**
| Level | Grace Period | Decay Rate | Example Plants |
|-------|-------------|------------|----------------|
| 1 (Easy) | 7 days | 1% per hour | Cactus, Snake Plant |
| 2 (Medium) | 3 days | 5% per hour | Monstera, Sunflower |
| 3 (Hard) | 2 days | 10% per hour | Orchid, Fern, Rose |

---

## Implementation

### 1. Plant Model (`lib/data/models/plant.dart`)
```dart
import 'package:isar/isar.dart';
import 'interaction.dart';
import 'note.dart';

part 'plant.g.dart';

@collection
class Plant {
  Id id = Isar.autoIncrement;

  @Index()
  late String contactId; // Links to OS Contact ID

  late String displayName;
  String? photoUrl; // Cached contact photo path
  
  @Enumerated(EnumType.name)
  late PlantType plantType;
  
  late int difficultyLevel; // 1 (Easy), 2 (Medium), 3 (Hard)
  
  late DateTime lastWatered;
  late DateTime plantedDate;
  
  // Snooze/Vacation mode
  DateTime? snoozedUntil;
  
  // Archived ("Composted") plants
  bool isArchived = false;
  DateTime? archivedDate;
  
  // Relationships
  final interactions = IsarLinks<Interaction>();
  final notes = IsarLinks<Note>();
  
  // Computed Properties
  double get currentHealth {
    if (isArchived) return 0;
    if (snoozedUntil != null && DateTime.now().isBefore(snoozedUntil!)) {
      return 100; // Paused during snooze
    }
    return _calculateHealth();
  }
  
  PlantHealthState get healthState {
    final health = currentHealth;
    if (health >= 80) return PlantHealthState.thriving;
    if (health >= 60) return PlantHealthState.thirsty;
    if (health >= 40) return PlantHealthState.wilting;
    if (health >= 20) return PlantHealthState.critical;
    return PlantHealthState.dormant;
  }
  
  double _calculateHealth() {
    final now = DateTime.now();
    final hoursSinceWatering = now.difference(lastWatered).inHours.toDouble();
    
    // Get grace period and decay rate based on difficulty
    final gracePeriodHours = _getGracePeriodHours();
    final decayRatePerHour = _getDecayRatePerHour();
    
    // If still within grace period, health is 100
    if (hoursSinceWatering <= gracePeriodHours) {
      return 100.0;
    }
    
    // Calculate decay
    final hoursDecaying = hoursSinceWatering - gracePeriodHours;
    final healthLost = hoursDecaying * decayRatePerHour;
    final health = 100.0 - healthLost;
    
    return health.clamp(0.0, 100.0);
  }
  
  double _getGracePeriodHours() {
    switch (difficultyLevel) {
      case 1: return 7 * 24; // 7 days
      case 2: return 3 * 24; // 3 days
      case 3: return 2 * 24; // 2 days
      default: return 3 * 24;
    }
  }
  
  double _getDecayRatePerHour() {
    switch (difficultyLevel) {
      case 1: return 1.0;  // 1% per hour
      case 2: return 5.0;  // 5% per hour
      case 3: return 10.0; // 10% per hour
      default: return 5.0;
    }
  }
  
  // Water the plant with different interaction types
  void water(InteractionType type) {
    final now = DateTime.now();
    final healthBoost = type.healthBoost;
    
    // Calculate new lastWatered to reflect the boost
    // We move lastWatered forward to simulate health restoration
    final currentHealth = this.currentHealth;
    final newHealth = (currentHealth + healthBoost).clamp(0.0, 100.0);
    
    if (newHealth >= 100) {
      lastWatered = now;
    } else {
      // Partial restoration - adjust lastWatered accordingly
      lastWatered = now;
    }
  }
}

enum PlantType {
  // Easy (Difficulty 1)
  cactus,
  snakePlant,
  succulent,
  
  // Medium (Difficulty 2)
  monstera,
  sunflower,
  pothos,
  
  // Hard (Difficulty 3)
  orchid,
  fern,
  rose,
}

extension PlantTypeExtension on PlantType {
  String get displayName {
    switch (this) {
      case PlantType.cactus: return 'Cactus';
      case PlantType.snakePlant: return 'Snake Plant';
      case PlantType.succulent: return 'Succulent';
      case PlantType.monstera: return 'Monstera';
      case PlantType.sunflower: return 'Sunflower';
      case PlantType.pothos: return 'Pothos';
      case PlantType.orchid: return 'Orchid';
      case PlantType.fern: return 'Fern';
      case PlantType.rose: return 'Rose';
    }
  }
  
  int get defaultDifficulty {
    switch (this) {
      case PlantType.cactus:
      case PlantType.snakePlant:
      case PlantType.succulent:
        return 1;
      case PlantType.monstera:
      case PlantType.sunflower:
      case PlantType.pothos:
        return 2;
      case PlantType.orchid:
      case PlantType.fern:
      case PlantType.rose:
        return 3;
    }
  }
  
  String get riveAssetPath {
    return 'assets/rive/plants/${name}.riv';
  }
}

enum PlantHealthState {
  thriving,  // 80-100%
  thirsty,   // 60-79%
  wilting,   // 40-59%
  critical,  // 20-39%
  dormant,   // 0-19%
}

extension PlantHealthStateExtension on PlantHealthState {
  double get riveAnimationInput {
    switch (this) {
      case PlantHealthState.thriving: return 1.0;
      case PlantHealthState.thirsty: return 0.75;
      case PlantHealthState.wilting: return 0.5;
      case PlantHealthState.critical: return 0.25;
      case PlantHealthState.dormant: return 0.0;
    }
  }
}
```

### 2. Interaction Model (`lib/data/models/interaction.dart`)
```dart
import 'package:isar/isar.dart';

part 'interaction.g.dart';

@collection
class Interaction {
  Id id = Isar.autoIncrement;
  
  @Index()
  late int plantId; // Foreign key to Plant
  
  late DateTime timestamp;
  
  @Enumerated(EnumType.name)
  late InteractionType type;
  
  String? summary; // Optional user notes about the interaction
  
  // For linking to specific notes if relevant
  int? linkedNoteId;
}

enum InteractionType {
  quickText,  // Drop - 20% boost
  phoneCall,  // Cup - 50% boost
  meetup,     // Watering Can - 100% boost
}

extension InteractionTypeExtension on InteractionType {
  String get displayName {
    switch (this) {
      case InteractionType.quickText: return 'Quick Text';
      case InteractionType.phoneCall: return 'Phone Call';
      case InteractionType.meetup: return 'Hangout';
    }
  }
  
  String get icon {
    switch (this) {
      case InteractionType.quickText: return 'assets/images/drop.png';
      case InteractionType.phoneCall: return 'assets/images/cup.png';
      case InteractionType.meetup: return 'assets/images/watering_can.png';
    }
  }
  
  double get healthBoost {
    switch (this) {
      case InteractionType.quickText: return 20.0;
      case InteractionType.phoneCall: return 50.0;
      case InteractionType.meetup: return 100.0;
    }
  }
  
  String get description {
    switch (this) {
      case InteractionType.quickText: return 'Text, meme, or quick message';
      case InteractionType.phoneCall: return 'Voice or video call';
      case InteractionType.meetup: return 'In-person hangout or meal';
    }
  }
}
```

### 3. Note Model (`lib/data/models/note.dart`)
```dart
import 'package:isar/isar.dart';

part 'note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;
  
  @Index()
  late int plantId; // Foreign key to Plant
  
  late DateTime createdAt;
  late DateTime updatedAt;
  
  late String content; // The actual note text
  
  // Quick tags
  List<String> tags = [];
  
  // Reminder functionality
  DateTime? reminderDate;
  bool reminderCompleted = false;
  String? reminderMessage; // Custom notification text
}

// Predefined tags for quick selection
class NoteTags {
  static const String birthday = 'Birthday';
  static const String giftIdea = 'Gift Idea';
  static const String work = 'Work';
  static const String family = 'Family';
  static const String health = 'Health';
  static const String travel = 'Travel';
  static const String hobby = 'Hobby';
  static const String important = 'Important';
  
  static List<String> get all => [
    birthday,
    giftIdea,
    work,
    family,
    health,
    travel,
    hobby,
    important,
  ];
}
```

### 4. Database Service (`lib/core/services/database_service.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/plant.dart';
import '../../data/models/interaction.dart';
import '../../data/models/note.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar must be initialized in main.dart');
});

class DatabaseService {
  final Isar _isar;
  
  DatabaseService(this._isar);
  
  // Plant Operations
  Future<List<Plant>> getAllPlants({bool includeArchived = false}) async {
    if (includeArchived) {
      return _isar.plants.where().findAll();
    }
    return _isar.plants.filter().isArchivedEqualTo(false).findAll();
  }
  
  Future<Plant?> getPlantById(int id) async {
    return _isar.plants.get(id);
  }
  
  Future<Plant?> getPlantByContactId(String contactId) async {
    return _isar.plants.filter().contactIdEqualTo(contactId).findFirst();
  }
  
  Future<int> savePlant(Plant plant) async {
    return _isar.writeTxn(() => _isar.plants.put(plant));
  }
  
  Future<void> deletePlant(int id) async {
    await _isar.writeTxn(() => _isar.plants.delete(id));
  }
  
  Future<void> archivePlant(int id) async {
    final plant = await getPlantById(id);
    if (plant != null) {
      plant.isArchived = true;
      plant.archivedDate = DateTime.now();
      await savePlant(plant);
    }
  }
  
  // Interaction Operations
  Future<int> saveInteraction(Interaction interaction) async {
    return _isar.writeTxn(() => _isar.interactions.put(interaction));
  }
  
  Future<List<Interaction>> getInteractionsForPlant(int plantId) async {
    return _isar.interactions
        .filter()
        .plantIdEqualTo(plantId)
        .sortByTimestampDesc()
        .findAll();
  }
  
  // Note Operations
  Future<int> saveNote(Note note) async {
    note.updatedAt = DateTime.now();
    return _isar.writeTxn(() => _isar.notes.put(note));
  }
  
  Future<List<Note>> getNotesForPlant(int plantId) async {
    return _isar.notes
        .filter()
        .plantIdEqualTo(plantId)
        .sortByCreatedAtDesc()
        .findAll();
  }
  
  Future<List<Note>> getUpcomingReminders() async {
    final now = DateTime.now();
    return _isar.notes
        .filter()
        .reminderDateIsNotNull()
        .reminderCompletedEqualTo(false)
        .reminderDateGreaterThan(now)
        .sortByReminderDate()
        .findAll();
  }
  
  // Statistics
  Future<int> getTotalPlantCount() async {
    return _isar.plants.filter().isArchivedEqualTo(false).count();
  }
  
  Future<int> getHealthyPlantCount() async {
    final plants = await getAllPlants();
    return plants.where((p) => p.currentHealth >= 80).length;
  }
  
  Future<double> getGardenHealthPercentage() async {
    final plants = await getAllPlants();
    if (plants.isEmpty) return 100.0;
    
    final healthyCount = plants.where((p) => p.currentHealth >= 80).length;
    return (healthyCount / plants.length) * 100;
  }
}

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final isar = ref.watch(isarProvider);
  return DatabaseService(isar);
});
```

### 5. Generate Isar Schemas
Run the build_runner to generate the Isar schema files:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Acceptance Criteria
- [ ] Plant model with all fields and computed health property
- [ ] Interaction model with type enum and health boost values
- [ ] Note model with tags and reminder support
- [ ] Health decay algorithm correctly calculates based on difficulty
- [ ] PlantHealthState correctly maps health percentage to state
- [ ] DatabaseService provides CRUD operations for all models
- [ ] Isar schemas generate without errors
- [ ] Unit tests pass for health calculation

---

## Unit Tests to Write
```dart
// test/models/plant_test.dart
void main() {
  group('Plant Health Calculation', () {
    test('should return 100% health within grace period', () {
      final plant = Plant()
        ..difficultyLevel = 1 // Cactus - 7 day grace
        ..lastWatered = DateTime.now().subtract(Duration(days: 5));
      
      expect(plant.currentHealth, equals(100.0));
    });
    
    test('should decay after grace period', () {
      final plant = Plant()
        ..difficultyLevel = 3 // Rose - 2 day grace, 10%/hour decay
        ..lastWatered = DateTime.now().subtract(Duration(days: 3));
      
      // 3 days = 72 hours. Grace = 48 hours. Decaying = 24 hours.
      // Health = 100 - (24 * 10) = 100 - 240 = clamped to 0
      expect(plant.currentHealth, equals(0.0));
    });
    
    test('should return correct health state', () {
      final plant = Plant()
        ..difficultyLevel = 2
        ..lastWatered = DateTime.now();
      
      expect(plant.healthState, equals(PlantHealthState.thriving));
    });
  });
}
```

---

## Dependencies
- Task 01: Project Setup (must be completed first)

## Blocks
- Task 04: Plant Health Engine
- Task 05: Garden Home Screen
- Task 06: Plant Detail Screen
