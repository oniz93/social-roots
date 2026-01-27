import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/contact_service.dart';
import '../../../data/models/plant.dart';
import '../../../data/repositories/plant_repository.dart';

class AddPlantScreen extends ConsumerStatefulWidget {
  final int? editPlantId;
  
  const AddPlantScreen({super.key, this.editPlantId});
  
  @override
  ConsumerState<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends ConsumerState<AddPlantScreen> {
  Contact? _selectedContact;
  PlantType _selectedPlantType = PlantType.monstera;
  int _selectedDifficulty = 2;
  final _nameController = TextEditingController();
  
  bool get isEditing => widget.editPlantId != null;
  
  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadExistingPlant();
    }
  }
  
  Future<void> _loadExistingPlant() async {
    final repository = ref.read(plantRepositoryProvider);
    final plant = await repository.getPlant(widget.editPlantId!);
    if (plant != null) {
      setState(() {
        _nameController.text = plant.displayName;
        _selectedPlantType = plant.plantType;
        _selectedDifficulty = plant.difficultyLevel;
      });
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Plant' : 'Add Plant'),
        actions: [
          TextButton(
            onPressed: _canSave() ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact selection (only for new plants)
          if (!isEditing) ...[
            Text(
              'Choose a Contact',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildContactSelector(),
            const SizedBox(height: 24),
          ],
          
          // Name field
          Text(
            'Display Name',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'How you want to remember them',
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Plant type selection
          Text(
            'Plant Type',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildPlantTypeSelector(),
          
          const SizedBox(height: 24),
          
          // Difficulty selection
          Text(
            'Contact Frequency',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildDifficultySelector(),
        ],
      ),
    );
  }
  
  Widget _buildContactSelector() {
    final contactsAsync = ref.watch(contactsProvider);
    
    return contactsAsync.when(
      data: (contacts) {
        return InkWell(
          onTap: () => _showContactPicker(contacts),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: _selectedContact?.thumbnail != null
                      ? MemoryImage(_selectedContact!.thumbnail!)
                      : null,
                  child: _selectedContact?.thumbnail == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedContact?.displayName ?? 'Select a contact',
                    style: TextStyle(
                      color: _selectedContact == null 
                          ? Colors.grey 
                          : Colors.black,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
  
  void _showContactPicker(List<Contact> contacts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search contacts...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (query) {
                    // TODO: Filter contacts
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: contact.thumbnail != null
                            ? MemoryImage(contact.thumbnail!)
                            : null,
                        child: contact.thumbnail == null
                            ? Text(contact.displayName[0])
                            : null,
                      ),
                      title: Text(contact.displayName),
                      onTap: () {
                        setState(() {
                          _selectedContact = contact;
                          _nameController.text = contact.displayName;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildPlantTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PlantType.values.map((type) {
        final isSelected = _selectedPlantType == type;
        return ChoiceChip(
          label: Text(type.displayName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedPlantType = type;
                _selectedDifficulty = type.defaultDifficulty;
              });
            }
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildDifficultySelector() {
    final options = [
      ('Every few days', 3, Colors.red.shade100),
      ('Weekly', 2, Colors.orange.shade100),
      ('Monthly', 1, Colors.green.shade100),
    ];
    
    return Column(
      children: options.map((option) {
        final (label, difficulty, color) = option;
        final isSelected = _selectedDifficulty == difficulty;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _selectedDifficulty = difficulty),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? color : null,
                border: Border.all(
                  color: isSelected ? Colors.grey.shade400 : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(label),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  bool _canSave() {
    if (isEditing) {
      return _nameController.text.isNotEmpty;
    }
    return _selectedContact != null && _nameController.text.isNotEmpty;
  }
  
  Future<void> _save() async {
    final repository = ref.read(plantRepositoryProvider);
    
    if (isEditing) {
      await repository.updatePlant(
        id: widget.editPlantId!,
        displayName: _nameController.text,
        plantType: _selectedPlantType,
        difficultyLevel: _selectedDifficulty,
      );
    } else {
      await repository.createPlant(
        contactId: _selectedContact!.id,
        displayName: _nameController.text,
        plantType: _selectedPlantType,
        difficultyLevel: _selectedDifficulty,
      );
    }
    
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
