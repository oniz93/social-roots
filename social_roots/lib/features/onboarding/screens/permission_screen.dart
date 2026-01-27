import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/contact_service.dart';

class PermissionScreen extends ConsumerWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionStatus = ref.watch(contactPermissionProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Garden illustration
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_florist,
                      size: 100,
                      color: Colors.green.shade700,
                    ),
                  ),

                  const SizedBox(height: 48),

                  Text(
                    'Plant Your First Seeds',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Social Roots needs access to your contacts to create your digital garden. Each contact becomes a unique plant that you\'ll nurture.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Privacy assurance
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your contacts stay on your device. We never upload or sell your data.',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Action buttons based on status
                  _buildActionButton(context, ref, permissionStatus),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => _enterManualMode(context),
                    child: const Text('Or enter contacts manually'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    ContactPermissionStatus status,
  ) {
    switch (status) {
      case ContactPermissionStatus.notDetermined:
      case ContactPermissionStatus.denied:
        return ElevatedButton(
          onPressed: () => _requestPermission(ref),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: Colors.green,
          ),
          child: const Text(
            'Allow Contact Access',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        );

      case ContactPermissionStatus.permanentlyDenied:
        return Column(
          children: [
            Text(
              'Permission was denied. Please enable it in Settings.',
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openSettings(ref),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );

      case ContactPermissionStatus.granted:
        // Navigate to contact selection
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/contact-selection');
        });
        return const CircularProgressIndicator();

      case ContactPermissionStatus.restricted:
        return Text(
          'Contact access is restricted on this device. You can still use Manual Mode.',
          style: TextStyle(color: Colors.orange.shade700),
          textAlign: TextAlign.center,
        );
    }
  }

  Future<void> _requestPermission(WidgetRef ref) async {
    await ref.read(contactPermissionProvider.notifier).requestPermission();
  }

  Future<void> _openSettings(WidgetRef ref) async {
    final service = ref.read(contactServiceProvider);
    await service.openSettings();
    // Refresh status when user returns
    await ref.read(contactPermissionProvider.notifier).refresh();
  }

  void _enterManualMode(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/manual-mode');
  }
}
