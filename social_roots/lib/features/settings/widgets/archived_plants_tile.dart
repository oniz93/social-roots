import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/archived_plants_screen.dart';

class ArchivedPlantsTile extends ConsumerWidget {
  const ArchivedPlantsTile({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.archive),
      title: const Text('Composted Plants'),
      subtitle: const Text('View and restore archived plants'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ArchivedPlantsScreen(),
          ),
        );
      },
    );
  }
}
