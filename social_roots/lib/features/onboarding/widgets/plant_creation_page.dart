import 'package:flutter/material.dart';
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
    if (!mounted) return;
    setState(() => _totalCount = contactIds.length);

    for (int i = 0; i < contactIds.length; i++) {
      final contactId = contactIds[i];

      // Get contact details
      final contact = await contactService.getContact(contactId);
      if (!mounted) return;
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

      if (!mounted) return;
      setState(() => _createdCount = i + 1);

      // Small delay for animation effect
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;
    setState(() => _isComplete = true);

    // Mark onboarding complete
    await ref.read(onboardingProvider.notifier).completeOnboarding();
  }

  PlantType _getPlantTypeForDifficulty(int difficulty) {
    switch (difficulty) {
      case 1:
        // Easy - randomly pick from easy plants
        final easyPlants = [
          PlantType.cactus,
          PlantType.snakePlant,
          PlantType.succulent,
        ];
        return easyPlants[DateTime.now().millisecond % easyPlants.length];
      case 2:
        // Medium
        final mediumPlants = [
          PlantType.monstera,
          PlantType.sunflower,
          PlantType.pothos,
        ];
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
          colors: [Colors.green.shade300, Colors.green.shade600],
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
