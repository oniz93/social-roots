# Task 09: Onboarding Flow

## Priority: HIGH
## Estimated Time: 5-6 hours
## Platform Focus: iOS First

---

## Objective
Build the complete first-time user onboarding experience including welcome screens, contact permission, contact selection, and the plant assignment quiz.

---

## Context
Onboarding is crucial for user retention. The flow should:
1. Explain the app concept clearly
2. Request permissions with clear privacy messaging
3. Let users select their "Core Circle" contacts
4. Assign appropriate plant types based on desired contact frequency
5. Create initial plants and guide to the garden

### The Quiz Flow
For the first 3 contacts, users answer: "How often do you want to talk to this person?"
- **Every few days** → High Maintenance Plant (Orchid, Fern)
- **Weekly** → Medium Plant (Monstera, Sunflower)
- **Monthly/Rarely** → Low Maintenance Plant (Cactus, Snake Plant)

After the quiz, remaining contacts are assigned medium difficulty by default.

---

## Implementation

### 1. Onboarding State Provider (`lib/features/onboarding/providers/onboarding_provider.dart`)
```dart
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
```

### 2. Onboarding Screen (`lib/features/onboarding/screens/onboarding_screen.dart`)
```dart
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
        return const PermissionScreen(key: ValueKey('permission'));
      case OnboardingStep.contactSelection:
        return const ContactSelectionScreen(key: ValueKey('selection'));
      case OnboardingStep.plantQuiz:
        return const PlantQuiz(key: ValueKey('quiz'));
      case OnboardingStep.plantCreation:
        return const PlantCreationPage(key: ValueKey('creation'));
      case OnboardingStep.complete:
        return const SizedBox.shrink(); // Will navigate away
    }
  }
}
```

### 3. Welcome Page (`lib/features/onboarding/widgets/welcome_page.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade300,
            Colors.green.shade600,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Logo/Icon
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.eco,
                  size: 80,
                  color: Colors.green.shade600,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Title
              const Text(
                'Social Roots',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tagline
              Text(
                'Nurture your relationships\nlike a garden',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Get Started Button
              ElevatedButton(
                onPressed: () {
                  ref.read(onboardingProvider.notifier).nextStep();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade600,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 4. Concept Page (`lib/features/onboarding/widgets/concept_page.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';

class ConceptPage extends ConsumerStatefulWidget {
  const ConceptPage({super.key});
  
  @override
  ConsumerState<ConceptPage> createState() => _ConceptPageState();
}

class _ConceptPageState extends ConsumerState<ConceptPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final _concepts = [
    _ConceptItem(
      icon: Icons.people,
      title: 'Your Relationships, Visualized',
      description: 'Each person in your life becomes a unique plant in your digital garden.',
    ),
    _ConceptItem(
      icon: Icons.water_drop,
      title: 'Water to Connect',
      description: 'Log calls, texts, and meetups to "water" your plants and keep them healthy.',
    ),
    _ConceptItem(
      icon: Icons.favorite,
      title: 'Watch Them Thrive',
      description: 'Stay connected and watch your garden flourish. Neglect it, and plants will wilt.',
    ),
    _ConceptItem(
      icon: Icons.note,
      title: 'Never Forget Details',
      description: 'Keep notes, set reminders, and always have something meaningful to talk about.',
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  ref.read(onboardingProvider.notifier).nextStep();
                },
                child: const Text('Skip'),
              ),
            ),
            
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _concepts.length,
                itemBuilder: (context, index) {
                  final concept = _concepts[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            concept.icon,
                            size: 60,
                            color: Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          concept.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          concept.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_concepts.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? Colors.green 
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 32),
            
            // Next button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage < _concepts.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    ref.read(onboardingProvider.notifier).nextStep();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: Colors.green,
                ),
                child: Text(
                  _currentPage < _concepts.length - 1 ? 'Next' : 'Continue',
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ConceptItem {
  final IconData icon;
  final String title;
  final String description;
  
  _ConceptItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
```

### 5. Plant Quiz (`lib/features/onboarding/widgets/plant_quiz.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/contact_service.dart';
import '../providers/onboarding_provider.dart';
import '../../../data/models/plant.dart';

class PlantQuiz extends ConsumerWidget {
  const PlantQuiz({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final contactIds = state.selectedContactIds.toList();
    final currentIndex = state.quizContactIndex;
    
    // Only quiz first 3 contacts
    final quizCount = contactIds.length.clamp(0, 3);
    
    if (currentIndex >= quizCount) {
      // Quiz complete, move to plant creation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(onboardingProvider.notifier).nextStep();
      });
      return const Center(child: CircularProgressIndicator());
    }
    
    return _QuizQuestion(
      contactId: contactIds[currentIndex],
      questionNumber: currentIndex + 1,
      totalQuestions: quizCount,
    );
  }
}

class _QuizQuestion extends ConsumerWidget {
  final String contactId;
  final int questionNumber;
  final int totalQuestions;
  
  const _QuizQuestion({
    required this.contactId,
    required this.questionNumber,
    required this.totalQuestions,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactService = ref.watch(contactServiceProvider);
    
    return FutureBuilder<Contact?>(
      future: contactService.getContact(contactId),
      builder: (context, snapshot) {
        final contact = snapshot.data;
        final displayName = contact?.displayName ?? 'This Person';
        
        return Container(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: questionNumber / totalQuestions,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Colors.green),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Question $questionNumber of $totalQuestions',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  
                  const Spacer(),
                  
                  // Contact avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: contact?.thumbnail != null 
                        ? MemoryImage(contact!.thumbnail!)
                        : null,
                    child: contact?.thumbnail == null 
                        ? Text(
                            displayName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 36),
                          )
                        : null,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  const Text(
                    'How often do you want to\nstay in touch?',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Options
                  _FrequencyOption(
                    title: 'Every few days',
                    subtitle: 'High maintenance plant',
                    plants: 'Orchid, Fern',
                    color: Colors.red.shade100,
                    icon: Icons.local_florist,
                    onTap: () => _selectDifficulty(ref, 3),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _FrequencyOption(
                    title: 'Weekly',
                    subtitle: 'Medium maintenance plant',
                    plants: 'Monstera, Sunflower',
                    color: Colors.orange.shade100,
                    icon: Icons.eco,
                    onTap: () => _selectDifficulty(ref, 2),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _FrequencyOption(
                    title: 'Monthly or less',
                    subtitle: 'Low maintenance plant',
                    plants: 'Cactus, Snake Plant',
                    color: Colors.green.shade100,
                    icon: Icons.grass,
                    onTap: () => _selectDifficulty(ref, 1),
                  ),
                  
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _selectDifficulty(WidgetRef ref, int difficulty) {
    ref.read(onboardingProvider.notifier).setContactDifficulty(
      contactId,
      difficulty,
    );
  }
}

class _FrequencyOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String plants;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  
  const _FrequencyOption({
    required this.title,
    required this.subtitle,
    required this.plants,
    required this.color,
    required this.icon,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    plants,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
```

### 6. Plant Creation Page (`lib/features/onboarding/widgets/plant_creation_page.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/contact_service.dart';
import '../../../data/models/plant.dart';
import '../../../data/repositories/plant_repository.dart';
import '../providers/onboarding_provider.dart';

class PlantCreationPage extends ConsumerStatefulWidget {
  const PlantCreationPage({super.key});
  
  @override
  ConsumerState<PlantCreationPage> createState() => _PlantCreationPageState();
}

class _PlantCreationPageState extends ConsumerState<PlantCreationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _createdCount = 0;
  int _totalCount = 0;
  bool _isComplete = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _createPlants();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _createPlants() async {
    final state = ref.read(onboardingProvider);
    final contactService = ref.read(contactServiceProvider);
    final plantRepository = ref.read(plantRepositoryProvider);
    
    final contactIds = state.selectedContactIds.toList();
    setState(() => _totalCount = contactIds.length);
    
    for (int i = 0; i < contactIds.length; i++) {
      final contactId = contactIds[i];
      
      // Get contact details
      final contact = await contactService.getContact(contactId);
      if (contact == null) continue;
      
      // Determine difficulty (from quiz or default to 2)
      final difficulty = state.contactDifficulties[contactId] ?? 2;
      
      // Assign plant type based on difficulty
      final plantType = _getPlantTypeForDifficulty(difficulty);
      
      // Create the plant
      await plantRepository.createPlant(
        contactId: contactId,
        displayName: contact.displayName,
        plantType: plantType,
        difficultyLevel: difficulty,
      );
      
      setState(() => _createdCount = i + 1);
      
      // Small delay for animation effect
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    setState(() => _isComplete = true);
    
    // Mark onboarding complete
    await ref.read(onboardingProvider.notifier).completeOnboarding();
  }
  
  PlantType _getPlantTypeForDifficulty(int difficulty) {
    switch (difficulty) {
      case 1:
        // Easy - randomly pick from easy plants
        final easyPlants = [PlantType.cactus, PlantType.snakePlant, PlantType.succulent];
        return easyPlants[DateTime.now().millisecond % easyPlants.length];
      case 2:
        // Medium
        final mediumPlants = [PlantType.monstera, PlantType.sunflower, PlantType.pothos];
        return mediumPlants[DateTime.now().millisecond % mediumPlants.length];
      case 3:
        // Hard
        final hardPlants = [PlantType.orchid, PlantType.fern, PlantType.rose];
        return hardPlants[DateTime.now().millisecond % hardPlants.length];
      default:
        return PlantType.monstera;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade300,
            Colors.green.shade600,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Animation area
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: _isComplete
                    ? Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green.shade600,
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _totalCount > 0 
                                ? _createdCount / _totalCount 
                                : null,
                            strokeWidth: 6,
                            valueColor: AlwaysStoppedAnimation(
                              Colors.green.shade600,
                            ),
                          ),
                          Icon(
                            Icons.local_florist,
                            size: 50,
                            color: Colors.green.shade600,
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 48),
              
              // Status text
              Text(
                _isComplete 
                    ? 'Your Garden is Ready!'
                    : 'Planting Your Garden...',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Progress count
              Text(
                _isComplete 
                    ? '$_totalCount plants created'
                    : '$_createdCount of $_totalCount',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              
              const Spacer(),
              
              // Continue button
              if (_isComplete)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/garden');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade600,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Enter Your Garden',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Acceptance Criteria
- [ ] Welcome screen displays with app branding
- [ ] Concept carousel explains the app in 4 steps
- [ ] Skip button available throughout onboarding
- [ ] Permission screen requests contacts with clear privacy message
- [ ] Contact selection allows multi-select with search
- [ ] Quiz asks about first 3 contacts with frequency options
- [ ] Plants are created with appropriate types based on quiz answers
- [ ] Remaining contacts get default medium difficulty
- [ ] Progress indicator shows during plant creation
- [ ] "Enter Your Garden" button navigates to main garden
- [ ] Onboarding state persists (doesn't repeat after completion)

---

## Dependencies
- Task 01: Project Setup
- Task 02: Data Models
- Task 03: Contact Permission
- Task 04: Plant Health Engine

## Blocks
- User can't access garden without completing onboarding
