import 'package:flutter/material.dart';

import 'features/onboarding/screens/permission_screen.dart';
import 'features/onboarding/screens/contact_selection_screen.dart';
import 'features/onboarding/screens/manual_mode_screen.dart';
import 'features/onboarding/screens/plant_quiz_screen.dart';
import 'features/garden/screens/garden_screen.dart';
import 'features/plant_detail/screens/plant_detail_screen.dart';

class SocialRootsApp extends StatelessWidget {
  const SocialRootsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Roots',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Nunito',
      ),
      initialRoute: '/garden',
      routes: {
        '/': (context) => const PermissionScreen(),
        '/garden': (context) => const GardenScreen(),
        '/contact-selection': (context) => const ContactSelectionScreen(),
        '/manual-mode': (context) => const ManualModeScreen(),
        '/plant-quiz': (context) => const PlantQuizScreen(),
        '/plant-detail': (context) {
          final plantId = ModalRoute.of(context)!.settings.arguments as int;
          return PlantDetailScreen(plantId: plantId);
        },
      },
    );
  }
}
