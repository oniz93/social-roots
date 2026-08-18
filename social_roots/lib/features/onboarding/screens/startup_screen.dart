import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';

class StartupScreen extends ConsumerStatefulWidget {
  const StartupScreen({super.key});

  @override
  ConsumerState<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    // Artificial delay for branding/loading smoothness
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    final completed = await ref.read(onboardingProvider.notifier).isOnboardingComplete();
    
    if (!mounted) return;

    if (completed) {
      Navigator.pushReplacementNamed(context, '/garden');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(
              Icons.eco,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}
