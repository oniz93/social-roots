import 'package:isar/isar.dart';
import '../../core/utils/health_calculator.dart';
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
  @ignore
  double get currentHealth {
    return HealthCalculator.calculateHealth(
      lastWatered: lastWatered,
      difficultyLevel: difficultyLevel,
      snoozedUntil: snoozedUntil,
      isArchived: isArchived,
    );
  }

  @ignore
  PlantHealthState get healthState {
    return HealthCalculator.getHealthState(currentHealth);
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
      // To restore X% health, we move lastWatered forward by (X / decayRate) hours
      final decayRate = HealthCalculator.getDecayRatePerHour(difficultyLevel);
      final hoursToRestore = healthBoost / decayRate;
      lastWatered = lastWatered.add(
        Duration(minutes: (hoursToRestore * 60).toInt()),
      );

      // Ensure lastWatered is not in the future
      if (lastWatered.isAfter(now)) {
        lastWatered = now;
      }
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
      case PlantType.cactus:
        return 'Cactus';
      case PlantType.snakePlant:
        return 'Snake Plant';
      case PlantType.succulent:
        return 'Succulent';
      case PlantType.monstera:
        return 'Monstera';
      case PlantType.sunflower:
        return 'Sunflower';
      case PlantType.pothos:
        return 'Pothos';
      case PlantType.orchid:
        return 'Orchid';
      case PlantType.fern:
        return 'Fern';
      case PlantType.rose:
        return 'Rose';
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
  thriving, // 80-100%
  thirsty, // 60-79%
  wilting, // 40-59%
  critical, // 20-39%
  dormant, // 0-19%
}

extension PlantHealthStateExtension on PlantHealthState {
  double get riveAnimationInput {
    switch (this) {
      case PlantHealthState.thriving:
        return 1.0;
      case PlantHealthState.thirsty:
        return 0.75;
      case PlantHealthState.wilting:
        return 0.5;
      case PlantHealthState.critical:
        return 0.25;
      case PlantHealthState.dormant:
        return 0.0;
    }
  }
}
