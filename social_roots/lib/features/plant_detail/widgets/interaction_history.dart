import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/interaction.dart';
import '../providers/plant_detail_providers.dart';

class InteractionHistory extends ConsumerWidget {
  final int plantId;
  
  const InteractionHistory({super.key, required this.plantId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(interactionHistoryProvider(plantId));
    
    return historyAsync.when(
      data: (interactions) {
        if (interactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No interactions yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                const Text('Water this plant to add your first interaction'),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: interactions.length,
          itemBuilder: (context, index) {
            final interaction = interactions[index];
            return _InteractionTile(interaction: interaction);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _InteractionTile extends StatelessWidget {
  final Interaction interaction;
  
  const _InteractionTile({required this.interaction});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(interaction.type).withValues(alpha: 0.2),
          child: Image.asset(
            interaction.type.icon,
            width: 26,
            height: 26,
          ),
        ),
        title: Text(interaction.type.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat.yMMMd().add_jm().format(interaction.timestamp)),
            if (interaction.summary != null && interaction.summary!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  interaction.summary!,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
          ],
        ),
        trailing: Text(
          '+${interaction.type.healthBoost.round()}%',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  
  Color _getTypeColor(InteractionType type) {
    switch (type) {
      case InteractionType.quickText:
        return Colors.blue;
      case InteractionType.phoneCall:
        return Colors.green;
      case InteractionType.meetup:
        return Colors.purple;
    }
  }
}
