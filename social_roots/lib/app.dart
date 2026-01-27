import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/background_task_service.dart';
import 'core/services/notification_service.dart';
import 'features/onboarding/screens/startup_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/screens/permission_screen.dart';
import 'features/onboarding/screens/contact_selection_screen.dart';
import 'features/onboarding/screens/manual_mode_screen.dart';
import 'features/onboarding/screens/plant_quiz_screen.dart';
import 'features/garden/screens/garden_screen.dart';
import 'features/plant_detail/screens/plant_detail_screen.dart';

class SocialRootsApp extends ConsumerStatefulWidget {
  const SocialRootsApp({super.key});

  @override
  ConsumerState<SocialRootsApp> createState() => _SocialRootsAppState();
}

class _SocialRootsAppState extends ConsumerState<SocialRootsApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize notifications and background tasks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backgroundTaskServiceProvider).onAppStartup();
      
      // Listen to notification taps
      final notificationService = ref.read(notificationServiceProvider);
      _notificationSubscription = notificationService.navigationStream.listen((payload) {
        _handleNotificationPayload(payload);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(backgroundTaskServiceProvider).onAppResumed();
    }
  }

  void _handleNotificationPayload(String payload) {
    final parts = payload.split(':');
    if (parts.length != 2) return;

    final type = parts[0];
    final idStr = parts[1];

    if (type == 'garden') {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil('/garden', (route) => false);
    } else if (type == 'plant') {
      final id = int.tryParse(idStr);
      if (id != null) {
        // Navigate to garden first (as base), then push detail
        _navigatorKey.currentState?.pushNamedAndRemoveUntil('/garden', (route) => false);
        _navigatorKey.currentState?.pushNamed(
          '/plant-detail',
          arguments: id,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Social Roots',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Nunito',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartupScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/garden': (context) => const GardenScreen(),
        '/permissions': (context) => const PermissionScreen(),
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