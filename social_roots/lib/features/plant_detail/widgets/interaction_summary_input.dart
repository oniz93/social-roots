import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class InteractionSummaryInput extends StatefulWidget {
  final Function(String?, String?) onSubmit;
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
  String? _pickedImagePath;
  final ImagePicker _picker = ImagePicker();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImagePath = image.path;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImagePath = null;
    });
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
          const SizedBox(height: 12),
          
          if (_pickedImagePath != null)
             Stack(
               children: [
                 ClipRRect(
                   borderRadius: BorderRadius.circular(8),
                   child: Image.file(
                     File(_pickedImagePath!),
                     height: 100,
                     width: 100,
                     fit: BoxFit.cover,
                   ),
                 ),
                 Positioned(
                   top: 4,
                   right: 4,
                   child: GestureDetector(
                     onTap: _removeImage,
                     child: Container(
                       padding: const EdgeInsets.all(4),
                       decoration: const BoxDecoration(
                         color: Colors.black54,
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.close, color: Colors.white, size: 16),
                     ),
                   ),
                 ),
               ],
             )
          else
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Add Photo Memory'),
            ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => widget.onSubmit(null, null),
                child: const Text('Skip'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => widget.onSubmit(
                  _controller.text.isEmpty ? null : _controller.text,
                  _pickedImagePath,
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
