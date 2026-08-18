import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_roots/data/models/plant.dart';
import 'package:social_roots/features/garden/screens/garden_screen.dart';
import 'package:social_roots/features/garden/providers/garden_providers.dart';

void main() {
  group('GardenScreen', () {
    testWidgets('shows empty state when no plants', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchPlantsProvider.overrideWith((ref) => Stream.value([])),
            gardenHealthProvider.overrideWith((ref) async => 100.0),
          ],
          child: const MaterialApp(home: GardenScreen()),
        ),
      );

      // Bounded pumps: continuous animations never settle in tests.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Your garden awaits'), findsOneWidget);
      expect(find.text('Plant Your First Seed'), findsOneWidget);
    });

    testWidgets('shows plants when data exists', (tester) async {
      final plants = [
        Plant()
          ..id = 1
          ..displayName = 'Mom'
          ..plantType = PlantType.succulent
          ..difficultyLevel = 1
          ..lastWatered = DateTime.now()
          ..plantedDate = DateTime.now(),
        Plant()
          ..id = 2
          ..displayName = 'Best Friend'
          ..plantType = PlantType.fern
          ..difficultyLevel = 2
          ..lastWatered = DateTime.now().subtract(const Duration(days: 5))
          ..plantedDate = DateTime.now(),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchPlantsProvider.overrideWith((ref) => Stream.value(plants)),
            gardenHealthProvider.overrideWith((ref) async => 80.0),
            // We need to override gardenStatsProvider because AppBar uses it
            gardenStatsProvider.overrideWith(
              (ref) async => GardenStats(
                totalPlants: 2,
                healthDistribution: {},
                averageHealth: 80.0,
              ),
            ),
          ],
          child: const MaterialApp(home: GardenScreen()),
        ),
      );

      // Bounded pumps: continuous animations never settle in tests.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Mom'), findsOneWidget);
      expect(find.text('Best Friend'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
