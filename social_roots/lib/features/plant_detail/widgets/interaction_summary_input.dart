import 'package:flutter/material.dart';

class InteractionSummaryInput extends StatefulWidget {
  final Function(String?) onSubmit;
  final VoidCallback onCancel;
  
  const InteractionSummaryInput({
    super.key,
    required this.onSubmit,
    required this.onCancel,
  });
  
  @override
  State<InteractionSummaryInput> createState() => _InteractionSummaryInputState();
}

class _InteractionSummaryInputState extends State<InteractionSummaryInput> {
  final _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a note (optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'What did you talk about?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => widget.onSubmit(null),
                child: const Text('Skip'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => widget.onSubmit(
                  _controller.text.isEmpty ? null : _controller.text,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
