import 'package:flutter/material.dart';

class NotesSection extends StatelessWidget {
  final int plantId;

  const NotesSection({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Notes feature coming soon!'),
        ],
      ),
    );
  }
}
