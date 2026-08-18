import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/contact_service.dart';
import '../providers/onboarding_provider.dart';

class PlantQuiz extends ConsumerWidget {
  final VoidCallback? onQuizComplete;

  const PlantQuiz({super.key, this.onQuizComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(onboardingProvider, (previous, next) {
      final contactIds = next.selectedContactIds.toList();
      if (contactIds.isEmpty) return;

      final quizCount = contactIds.length;
      final prevIndex = previous?.quizContactIndex ?? 0;
      final nextIndex = next.quizContactIndex;

      // Trigger navigation only when we transition to completion
      if (prevIndex < quizCount && nextIndex >= quizCount) {
        if (onQuizComplete != null) {
          onQuizComplete!();
        } else {
          ref.read(onboardingProvider.notifier).nextStep();
        }
      }
    });

    final state = ref.watch(onboardingProvider);
    final contactIds = state.selectedContactIds.toList();
    final currentIndex = state.quizContactIndex;

    // If no contacts selected, skip quiz entirely
    if (contactIds.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (onQuizComplete != null) {
          onQuizComplete!();
        } else {
          ref.read(onboardingProvider.notifier).nextStep();
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    // Quiz all selected contacts
    final quizCount = contactIds.length;

    if (currentIndex >= quizCount) {
      // Quiz complete, show loading while navigating
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
          color: const Color(0xFF1A1A1A),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Progress indicator
                    LinearProgressIndicator(
                      value: questionNumber / totalQuestions,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(Colors.green),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Question $questionNumber of $totalQuestions',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),

                    const SizedBox(height: 32),

                    // Contact avatar
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green.shade800,
                      backgroundImage: contact?.photo?.thumbnail != null
                          ? MemoryImage(contact!.photo!.thumbnail!)
                          : null,
                      child: contact?.photo?.thumbnail == null
                          ? Text(
                              displayName[0].toUpperCase(),
                              style: const TextStyle(fontSize: 36, color: Colors.white),
                            )
                          : null,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'How often do you want to\nstay in touch?',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Options
                    _FrequencyOption(
                      title: 'Every few days',
                      subtitle: 'High maintenance plant',
                      plants: 'Orchid, Fern',
                      color: Colors.red.withValues(alpha: 0.15),
                      icon: Icons.local_florist,
                      iconColor: Colors.red.shade300,
                      onTap: () => _selectDifficulty(ref, 3),
                    ),

                    const SizedBox(height: 16),

                    _FrequencyOption(
                      title: 'Weekly',
                      subtitle: 'Medium maintenance plant',
                      plants: 'Monstera, Sunflower',
                      color: Colors.orange.withValues(alpha: 0.15),
                      icon: Icons.eco,
                      iconColor: Colors.orange.shade300,
                      onTap: () => _selectDifficulty(ref, 2),
                    ),

                    const SizedBox(height: 16),

                    _FrequencyOption(
                      title: 'Monthly or less',
                      subtitle: 'Low maintenance plant',
                      plants: 'Cactus, Snake Plant',
                      color: Colors.green.withValues(alpha: 0.15),
                      icon: Icons.grass,
                      iconColor: Colors.green.shade300,
                      onTap: () => _selectDifficulty(ref, 1),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectDifficulty(WidgetRef ref, int difficulty) {
    ref
        .read(onboardingProvider.notifier)
        .setContactDifficulty(contactId, difficulty);
  }
}

class _FrequencyOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String plants;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;

  const _FrequencyOption({
    required this.title,
    required this.subtitle,
    required this.plants,
    required this.color,
    required this.iconColor,
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
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: iconColor),
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
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
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
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
