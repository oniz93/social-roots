import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:social_roots/app.dart';
import 'package:social_roots/core/services/background_task_service.dart';
import 'package:social_roots/core/services/notification_service.dart';
import 'package:social_roots/features/garden/providers/garden_providers.dart';

/// Startup services are stubbed out: Isar and the local-notification
/// plugin are not available in the widget test environment.
class _FakeBackgroundTaskService implements BackgroundTaskService {
  @override
  Future<void> onAppStartup() async {}

  @override
  Future<void> onAppResumed() async {}

  @override
  Future<void> onBackgroundFetch() async {}
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Pretend onboarding is complete so the app lands on the garden.
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    // Wrap the app in a ProviderScope and override providers that need
    // Isar or platform plugins, which don't exist in widget tests.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backgroundTaskServiceProvider
              .overrideWith((ref) => _FakeBackgroundTaskService()),
          notificationServiceProvider
              .overrideWith((ref) => NotificationService()),
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

    // Bounded pumps instead of pumpAndSettle: the garden screen runs
    // continuous placeholder-plant animations, so the tree never "settles".
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Check if the GardenScreen (empty state) is displayed
    // The empty state has text "Your garden awaits"
    expect(find.text('Your garden awaits'), findsOneWidget);
    expect(find.text('Plant Your First Seed'), findsOneWidget);
  });
}
