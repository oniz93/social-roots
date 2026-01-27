import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/plant.dart';
import '../../../data/repositories/plant_repository.dart';
import '../../../shared/widgets/placeholder_plant_widget.dart';

class EditPlantScreen extends ConsumerStatefulWidget {
  final int plantId;

  const EditPlantScreen({super.key, required this.plantId});

  @override
  ConsumerState<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends ConsumerState<EditPlantScreen> {
  Plant? _plant;
  PlantType? _selectedPlantType;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPlant();
  }

  Future<void> _loadPlant() async {
    final repository = ref.read(plantRepositoryProvider);
    final plant = await repository.getPlant(widget.plantId);
    if (mounted) {
      setState(() {
        _plant = plant;
        _selectedPlantType = plant?.plantType;
        _isLoading = false;
      });
    }
  }

  bool get _hasChanges =>
      _plant != null && _selectedPlantType != _plant!.plantType;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Plant')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_plant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Plant')),
        body: const Center(child: Text('Plant not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${_plant!.displayName}'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _showConfirmDialog,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Plant preview
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green.shade300, Colors.green.shade500],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: AnimatedPlaceholderPlant(
                    plantType: _selectedPlantType!,
                    health: 100, // Preview at full health
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedPlantType!.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Info card about health reset
          if (_hasChanges)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Changing the plant type will reset health to 100%',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // Plant type selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Choose Plant Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Plant type grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: PlantType.values.length,
              itemBuilder: (context, index) {
                final type = PlantType.values[index];
                final isSelected = _selectedPlantType == type;
                final isOriginal = _plant!.plantType == type;

                return _PlantTypeCard(
                  type: type,
                  isSelected: isSelected,
                  isOriginal: isOriginal,
                  onTap: () => setState(() => _selectedPlantType = type),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Plant Type?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Changing from ${_plant!.plantType.displayName} to ${_selectedPlantType!.displayName} will:',
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Reset health to 100%'),
            _buildBulletPoint(
              'Set watering frequency to ${_getDifficultyLabel(_selectedPlantType!.defaultDifficulty)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _save();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Monthly (Easy)';
      case 2:
        return 'Weekly (Medium)';
      case 3:
        return 'Every few days (Hard)';
      default:
        return 'Unknown';
    }
  }

  Future<void> _save() async {
    if (_selectedPlantType == null || !_hasChanges) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(plantRepositoryProvider);
      await repository.updatePlantType(
        id: widget.plantId,
        plantType: _selectedPlantType!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Changed to ${_selectedPlantType!.displayName} - Health reset to 100%!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate changes were made
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }
}

class _PlantTypeCard extends StatelessWidget {
  final PlantType type;
  final bool isSelected;
  final bool isOriginal;
  final VoidCallback onTap;

  const _PlantTypeCard({
    required this.type,
    required this.isSelected,
    required this.isOriginal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedPlaceholderPlant(
                      plantType: type,
                      health: 100,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    type.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Current indicator
            if (isOriginal)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Selected checkmark
            if (isSelected && !isOriginal)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
