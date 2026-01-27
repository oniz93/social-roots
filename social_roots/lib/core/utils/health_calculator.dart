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
      case 1:
        return 7 * 24; // 7 days (168 hours)
      case 2:
        return 3 * 24; // 3 days (72 hours)
      case 3:
        return 2 * 24; // 2 days (48 hours)
      default:
        return 3 * 24;
    }
  }

  /// Get decay rate per hour based on difficulty
  static double getDecayRatePerHour(int difficultyLevel) {
    switch (difficultyLevel) {
      case 1:
        return 0.5; // 0.5% per hour (slower for MVP testing)
      case 2:
        return 2.0; // 2% per hour
      case 3:
        return 5.0; // 5% per hour
      default:
        return 2.0;
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
