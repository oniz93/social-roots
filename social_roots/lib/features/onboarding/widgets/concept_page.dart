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
      color: const Color(0xFF1A1A1A),
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
                child: const Text('Skip', style: TextStyle(color: Colors.white70)),
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
                            color: Colors.green.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            concept.icon,
                            size: 60,
                            color: Colors.green.shade400,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          concept.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          concept.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
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
                        : Colors.white.withOpacity(0.2),
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
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _currentPage < _concepts.length - 1 ? 'Next' : 'Continue',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
