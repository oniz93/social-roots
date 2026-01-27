import 'package:flutter/material.dart';

import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/garden/screens/garden_screen.dart';
import '../../features/plant_detail/screens/plant_detail_screen.dart';
import '../../features/plant_detail/screens/edit_plant_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/onboarding/screens/contact_selection_screen.dart';
import '../../features/onboarding/screens/manual_mode_screen.dart';
import '../../features/plant_detail/screens/add_plant_screen.dart';
import '../../features/onboarding/screens/plant_quiz_screen.dart';

class AppRouter {
  static const String onboarding = '/onboarding';
  static const String garden = '/garden';
  static const String plantDetail = '/plant-detail';
  static const String settings = '/settings';
  static const String addPlant = '/add-plant';
  static const String editPlant = '/edit-plant';
  static const String contactSelection = '/contact-selection';
  static const String manualMode = '/manual-mode';
  static const String plantQuiz = '/plant-quiz';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case garden:
        return MaterialPageRoute(
          builder: (_) => const GardenScreen(),
          settings: settings,
        );

      case plantDetail:
        final plantId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => PlantDetailScreen(plantId: plantId),
          settings: settings,
        );

      case AppRouter.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      case addPlant:
        return MaterialPageRoute(
          builder: (_) => const AddPlantScreen(),
          settings: settings,
          fullscreenDialog: true,
        );

      case editPlant:
        final plantId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => EditPlantScreen(plantId: plantId),
          settings: settings,
          fullscreenDialog: true,
        );

      case contactSelection:
        return MaterialPageRoute(
          builder: (_) => const ContactSelectionScreen(),
          settings: settings,
        );

      case manualMode:
        return MaterialPageRoute(
          builder: (_) => const ManualModeScreen(),
          settings: settings,
        );

      case plantQuiz:
        return MaterialPageRoute(
          builder: (_) => const PlantQuizScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const GardenScreen(),
          settings: settings,
        );
    }
  }

  /// Handle deep link navigation
  static void handleDeepLink(BuildContext context, String? payload) {
    if (payload == null) return;

    final parts = payload.split(':');
    if (parts.length != 2) return;

    final type = parts[0];
    final id = int.tryParse(parts[1]);

    switch (type) {
      case 'plant':
        if (id != null) {
          Navigator.pushNamed(context, plantDetail, arguments: id);
        }
        break;
      case 'garden':
        Navigator.pushNamedAndRemoveUntil(context, garden, (route) => false);
        break;
    }
  }
}
