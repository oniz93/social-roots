import 'package:flutter/material.dart';

class PlantQuizScreen extends StatelessWidget {
  const PlantQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant Quiz (Placeholder)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Task 09: Plant Quiz Implementation Needed'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to garden as a temporary skip
                Navigator.of(context).pushNamedAndRemoveUntil('/garden', (route) => false);
              },
              child: const Text('Skip to Garden'),
            ),
          ],
        ),
      ),
    );
  }
}
