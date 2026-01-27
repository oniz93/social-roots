import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/garden_providers.dart';

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
            onPressed: () => _showStats(context, s),
            icon: Badge(
              isLabelVisible: s.needsAttentionCount > 0,
              label: Text('${s.needsAttentionCount}'),
              child: const Icon(Icons.bar_chart, color: Colors.white),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Settings
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    );
  }

  void _showStats(BuildContext context, GardenStats stats) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Garden Health',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'Thriving',
              count: stats.thrivingCount,
              color: Colors.green,
            ),
            _StatRow(
              label: 'Thirsty',
              count: stats.thirstyCount,
              color: Colors.blue,
            ),
            _StatRow(
              label: 'Wilting',
              count: stats.wiltingCount,
              color: Colors.orange,
            ),
            _StatRow(
              label: 'Critical',
              count: stats.criticalCount,
              color: Colors.red,
            ),
            _StatRow(
              label: 'Dormant',
              count: stats.dormantCount,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stats.averageHealth / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                stats.averageHealth >= 80
                    ? Colors.green
                    : stats.averageHealth >= 50
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Average Health: ${stats.averageHealth.round()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
