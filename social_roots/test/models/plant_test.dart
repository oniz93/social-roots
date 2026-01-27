import 'package:flutter_test/flutter_test.dart';
import 'package:social_roots/core/utils/health_calculator.dart';

void main() {
  group('HealthCalculator', () {
    test('returns 100% within grace period', () {
      final health = HealthCalculator.calculateHealth(
        lastWatered: DateTime.now().subtract(const Duration(days: 1)),
        difficultyLevel: 1, // 7 day grace
      );
      expect(health, equals(100.0));
    });

    test('decays correctly after grace period', () {
      final health = HealthCalculator.calculateHealth(
        lastWatered: DateTime.now().subtract(
          const Duration(days: 8),
        ), // Past 7-day grace
        difficultyLevel: 1, // 0.5% per hour decay
      );
      // 8 days = 192 hours, grace = 168 hours, decaying = 24 hours
      // Health = 100 - (24 * 0.5) = 88%
      expect(health, closeTo(88.0, 1.0));
    });

    test('snooze prevents decay', () {
      final health = HealthCalculator.calculateHealth(
        lastWatered: DateTime.now().subtract(const Duration(days: 30)),
        difficultyLevel: 3,
        snoozedUntil: DateTime.now().add(const Duration(days: 1)),
      );
      expect(health, equals(100.0));
    });
  });
}
