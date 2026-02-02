import 'package:flutter/material.dart';
import '../widgets/plant_quiz.dart';
import '../widgets/plant_creation_page.dart';

class PlantQuizScreen extends StatelessWidget {
  const PlantQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Customize Your Plants'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: PlantQuiz(
        onQuizComplete: () {
          // Navigate to plant creation page in standalone mode
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const PlantCreationPage(
                isOnboarding: false,
              ),
            ),
          );
        },
      ),
    );
  }
}