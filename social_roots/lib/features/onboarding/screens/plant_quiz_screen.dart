import 'package:flutter/material.dart';
import '../widgets/plant_quiz.dart';
import '../widgets/plant_creation_page.dart';

class PlantQuizScreen extends StatelessWidget {
  const PlantQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customize Your Plants')),
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