import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../data/models/plant.dart';
import 'placeholder_plant_widget.dart';

class AnimatedPlantWidget extends StatefulWidget {
  final PlantType plantType;
  final double health;
  final bool showWateringAnimation;
  final bool showRevivalAnimation;
  final VoidCallback? onAnimationComplete;
  
  const AnimatedPlantWidget({
    super.key,
    required this.plantType,
    required this.health,
    this.showWateringAnimation = false,
    this.showRevivalAnimation = false,
    this.onAnimationComplete,
  });
  
  @override
  State<AnimatedPlantWidget> createState() => _AnimatedPlantWidgetState();
}

class _AnimatedPlantWidgetState extends State<AnimatedPlantWidget> {
  Artboard? _artboard;
  StateMachineController? _controller;
  SMINumber? _healthInput;
  SMITrigger? _waterTrigger;
  SMITrigger? _reviveTrigger;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }
  
  Future<void> _loadRiveFile() async {
    try {
      final file = await RiveFile.asset(widget.plantType.riveAssetPath);
      final artboard = file.mainArtboard.instance();
      
      _controller = StateMachineController.fromArtboard(
        artboard,
        'PlantStateMachine',
        onStateChange: _onStateChange,
      );
      
      if (_controller != null) {
        artboard.addController(_controller!);
        
        _healthInput = _controller!.findInput<double>('health') as SMINumber?;
        _waterTrigger = _controller!.findInput<bool>('water') as SMITrigger?;
        _reviveTrigger = _controller!.findInput<bool>('revive') as SMITrigger?;
        
        // Set initial health
        _updateHealth();
      }
      
      if (mounted) {
        setState(() {
          _artboard = artboard;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading Rive file: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }
  
  void _onStateChange(String stateMachineName, String stateName) {
    // Called when animation states change
    if (stateName == 'Idle' && 
        (widget.showWateringAnimation || widget.showRevivalAnimation)) {
      widget.onAnimationComplete?.call();
    }
  }
  
  @override
  void didUpdateWidget(AnimatedPlantWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.plantType != widget.plantType) {
      _loadRiveFile();
      return;
    }

    if (oldWidget.health != widget.health) {
      _updateHealth();
    }
    
    if (widget.showWateringAnimation && !oldWidget.showWateringAnimation) {
      _triggerWater();
    }
    
    if (widget.showRevivalAnimation && !oldWidget.showRevivalAnimation) {
      _triggerRevival();
    }
  }
  
  void _updateHealth() {
    _healthInput?.value = widget.health / 100.0;
  }
  
  void _triggerWater() {
    _waterTrigger?.fire();
  }
  
  void _triggerRevival() {
    _reviveTrigger?.fire();
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_artboard == null || _hasError) {
      return _buildPlaceholder();
    }
    
    return Rive(
      artboard: _artboard!,
      fit: BoxFit.contain,
    );
  }
  
  Widget _buildPlaceholder() {
    return AnimatedPlaceholderPlant(
      plantType: widget.plantType,
      health: widget.health,
    );
  }
}
