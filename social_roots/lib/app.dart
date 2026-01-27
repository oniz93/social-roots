import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_task_service.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/garden/screens/garden_screen.dart';

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
    
    // Initialize background tasks
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
    if (_navigatorKey.currentContext != null) {
      AppRouter.handleDeepLink(_navigatorKey.currentContext!, payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Social Roots',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const _InitialScreen(),
    );
  }
}

class _InitialScreen extends ConsumerWidget {
  const _InitialScreen();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: ref.read(onboardingProvider.notifier).isOnboardingComplete(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final isComplete = snapshot.data ?? false;
        
        if (isComplete) {
          return const GardenScreen();
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}
