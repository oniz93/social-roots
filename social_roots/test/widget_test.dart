import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_roots/app.dart';
import 'package:social_roots/features/garden/providers/garden_providers.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Wrap the app in a ProviderScope for Riverpod and override providers to avoid Isar dependency
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchPlantsProvider.overrideWith((ref) => Stream.value([])),
          gardenHealthProvider.overrideWith((ref) async => 100.0),
          gardenStatsProvider.overrideWith(
            (ref) async => GardenStats(
              totalPlants: 0,
              healthDistribution: {},
              averageHealth: 100.0,
            ),
          ),
        ],
        child: const SocialRootsApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Check if the GardenScreen (empty state) is displayed
    // The empty state has text "Your garden awaits"
    expect(find.text('Your garden awaits'), findsOneWidget);
    expect(find.text('Plant Your First Seed'), findsOneWidget);
  });
}
