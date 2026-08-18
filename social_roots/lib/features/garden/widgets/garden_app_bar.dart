import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/garden_providers.dart';
import '../screens/garden_analytics_screen.dart';

class GardenAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const GardenAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(gardenStatsProvider);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'My Garden',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        // Quick stats button
        stats.when(
          data: (s) => IconButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GardenAnalyticsScreen())
            ),
            icon: Badge(
              isLabelVisible: s.needsAttentionCount > 0,
              label: Text('${s.needsAttentionCount}'),
              child: const Icon(Icons.bar_chart, color: Colors.white),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        // Settings
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    );
  }
}

