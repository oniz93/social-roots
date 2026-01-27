import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/plant.dart';
import '../../../core/services/contact_service.dart';

class QuickActions extends StatelessWidget {
  final Plant plant;
  
  const QuickActions({super.key, required this.plant});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
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
    );
  }
  
  Future<void> _makeCall() async {
    // In real implementation, get phone from contact
    // For now, show placeholder
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
