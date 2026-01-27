import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/notification_settings.dart';
import '../widgets/vacation_mode_card.dart';
import '../widgets/archived_plants_tile.dart';
import '../widgets/data_management_section.dart';
import '../widgets/about_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: const [
          VacationModeCard(),
          Divider(height: 1),
          ArchivedPlantsTile(),
          Divider(height: 32),
          NotificationSettings(),
          Divider(height: 32),
          DataManagementSection(),
          Divider(height: 32),
          AboutSection(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
