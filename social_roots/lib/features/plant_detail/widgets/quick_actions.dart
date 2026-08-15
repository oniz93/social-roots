import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/plant.dart';
import '../../../data/models/interaction.dart';
import '../controllers/watering_controller.dart';

class QuickActions extends ConsumerWidget {
  final Plant plant;

  const QuickActions({super.key, required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.phone,
                label: 'Call',
                color: Colors.green,
                onTap: () => _makeCall(),
              ),
              _ActionButton(
                icon: Icons.message,
                label: 'Message',
                color: Colors.blue,
                onTap: () => _sendMessage(),
              ),
              _ActionButton(
                icon: Icons.email,
                label: 'Email',
                color: Colors.orange,
                onTap: () => _sendEmail(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _sendVibe(context, ref),
              icon: const Icon(Icons.bolt, color: Colors.white),
              label: const Text('Send Quick Vibe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makeCall() async {
    // In real implementation, get phone from contact
    final uri = Uri.parse('tel:+1234567890');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendMessage() async {
    final uri = Uri.parse('sms:+1234567890');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail() async {
    final uri = Uri.parse('mailto:example@email.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendVibe(BuildContext context, WidgetRef ref) async {
     // 1. Launch SMS
    final uri = Uri.parse('sms:+1234567890?body=Thinking of you! 🌱');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
    
    // 2. Log Interaction (Drop)
    final controller = ref.read(wateringControllerProvider(plant.id).notifier);
    await controller.water(
        plant: plant,
        type: InteractionType.quickText,
        summary: "Quick Vibe: Thinking of you! 🌱"
    );
    
    // 3. Feedback
    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
               content: Text("Vibe sent & Plant watered!"),
               duration: Duration(seconds: 2),
           )
       );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
