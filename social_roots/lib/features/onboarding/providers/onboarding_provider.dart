import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OnboardingStep {
  welcome,
  concept,
  permission,
  contactSelection,
  plantQuiz,
  plantCreation,
  complete,
}

class OnboardingState {
  final OnboardingStep currentStep;
  final Set<String> selectedContactIds;
  final Map<String, int> contactDifficulties; // contactId -> difficulty (1-3)
  final int quizContactIndex;
  final bool isLoading;
  
  OnboardingState({
    this.currentStep = OnboardingStep.welcome,
    this.selectedContactIds = const {},
    this.contactDifficulties = const {},
    this.quizContactIndex = 0,
    this.isLoading = false,
  });
  
  OnboardingState copyWith({
    OnboardingStep? currentStep,
    Set<String>? selectedContactIds,
    Map<String, int>? contactDifficulties,
    int? quizContactIndex,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedContactIds: selectedContactIds ?? this.selectedContactIds,
      contactDifficulties: contactDifficulties ?? this.contactDifficulties,
      quizContactIndex: quizContactIndex ?? this.quizContactIndex,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());
  
  static const _onboardingCompleteKey = 'onboarding_complete';
  
  /// Check if onboarding was already completed
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }
  
  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }
  
  void goToStep(OnboardingStep step) {
    state = state.copyWith(currentStep: step);
  }
  
  void nextStep() {
    final nextIndex = state.currentStep.index + 1;
    if (nextIndex < OnboardingStep.values.length) {
      state = state.copyWith(currentStep: OnboardingStep.values[nextIndex]);
    }
  }
  
  void previousStep() {
    final prevIndex = state.currentStep.index - 1;
    if (prevIndex >= 0) {
      state = state.copyWith(currentStep: OnboardingStep.values[prevIndex]);
    }
  }
  
  void toggleContact(String contactId) {
    final current = Set<String>.from(state.selectedContactIds);
    if (current.contains(contactId)) {
      current.remove(contactId);
    } else {
      current.add(contactId);
    }
    state = state.copyWith(selectedContactIds: current);
  }

  void setSelectedContacts(Set<String> contactIds) {
    state = state.copyWith(selectedContactIds: contactIds);
  }
  
  void setContactDifficulty(String contactId, int difficulty) {
    final current = Map<String, int>.from(state.contactDifficulties);
    current[contactId] = difficulty;
    state = state.copyWith(
      contactDifficulties: current,
      quizContactIndex: state.quizContactIndex + 1,
    );
  }
  
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
  
  void reset() {
    state = OnboardingState();
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
