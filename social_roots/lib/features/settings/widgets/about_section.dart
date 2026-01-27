import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('Version'),
          subtitle: Text('1.0.0'),
        ),
        
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchUrl('https://socialroots.app/privacy'),
        ),
        
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('Terms of Service'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchUrl('https://socialroots.app/terms'),
        ),
        
        ListTile(
          leading: const Icon(Icons.mail),
          title: const Text('Send Feedback'),
          onTap: () => _launchUrl('mailto:feedback@socialroots.app'),
        ),
        
        ListTile(
          leading: const Icon(Icons.star),
          title: const Text('Rate the App'),
          onTap: () {
            // TODO: Link to App Store
          },
        ),
        
        const SizedBox(height: 16),
        
        Center(
          child: Text(
            'Made with 💚 for meaningful connections',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }
  
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
