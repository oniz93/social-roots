import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/welcome_page.dart';
import '../widgets/concept_page.dart';
import 'permission_screen.dart';
import 'contact_selection_screen.dart';
import '../widgets/plant_quiz.dart';
import '../widgets/plant_creation_page.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentStep(state.currentStep),
      ),
    );
  }
  
  Widget _buildCurrentStep(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
        return const WelcomePage(key: ValueKey('welcome'));
      case OnboardingStep.concept:
        return const ConceptPage(key: ValueKey('concept'));
      case OnboardingStep.permission:
        return const PermissionScreen(key: ValueKey('permission'), isOnboarding: true);
      case OnboardingStep.contactSelection:
        return const ContactSelectionScreen(key: ValueKey('selection'), isOnboarding: true);
      case OnboardingStep.plantQuiz:
        return const PlantQuiz(key: ValueKey('quiz'));
      case OnboardingStep.plantCreation:
        return const PlantCreationPage(key: ValueKey('creation'));
      case OnboardingStep.complete:
        return const SizedBox.shrink(); // Will navigate away
    }
  }
}
