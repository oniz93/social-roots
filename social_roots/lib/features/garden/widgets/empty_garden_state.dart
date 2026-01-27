import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/contact_service.dart';

class EmptyGardenState extends ConsumerWidget {
  const EmptyGardenState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 24),
            Text(
              'Your garden is empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first plant to start nurturing your relationships',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                final status = ref.read(contactPermissionProvider);
                if (status == ContactPermissionStatus.granted) {
                  Navigator.pushNamed(context, '/contact-selection');
                } else {
                  Navigator.pushNamed(context, '/permissions');
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Plant Your First Seed'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
