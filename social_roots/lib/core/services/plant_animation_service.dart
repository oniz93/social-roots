import 'package:rive/rive.dart';
import 'package:flutter/material.dart';

/// Controls Rive plant animations based on health state
class PlantAnimationController {
  late RiveAnimationController _controller;
  late StateMachineController? _stateMachine;
  SMINumber? _healthInput;
  SMITrigger? _waterTrigger;
  SMITrigger? _reviveTrigger;

  bool _isInitialized = false;

  /// Initialize with an Artboard
  void init(Artboard artboard) {
    _stateMachine = StateMachineController.fromArtboard(
      artboard,
      'PlantStateMachine', // State machine name in Rive file
    );

    if (_stateMachine != null) {
      artboard.addController(_stateMachine!);

      // Get inputs from state machine
      _healthInput = _stateMachine!.findInput<double>('health') as SMINumber?;
      _waterTrigger = _stateMachine!.findInput<bool>('water') as SMITrigger?;
      _reviveTrigger = _stateMachine!.findInput<bool>('revive') as SMITrigger?;
    }

    _isInitialized = true;
  }

  /// Update plant health (0.0 to 1.0)
  void setHealth(double health) {
    if (!_isInitialized || _healthInput == null) return;
    _healthInput!.value = health / 100.0; // Convert 0-100 to 0-1
  }

  /// Trigger watering animation
  void triggerWater() {
    if (!_isInitialized || _waterTrigger == null) return;
    _waterTrigger!.fire();
  }

  /// Trigger revival animation (for dormant plants)
  void triggerRevive() {
    if (!_isInitialized || _reviveTrigger == null) return;
    _reviveTrigger!.fire();
  }

  /// Clean up
  void dispose() {
    _stateMachine?.dispose();
  }
}

/// Widget wrapper for animated plant
class AnimatedPlant extends StatefulWidget {
  final String plantType;
  final double health;
  final bool showWaterAnimation;

  const AnimatedPlant({
    super.key,
    required this.plantType,
    required this.health,
    this.showWaterAnimation = false,
  });

  @override
  State<AnimatedPlant> createState() => _AnimatedPlantState();
}

class _AnimatedPlantState extends State<AnimatedPlant> {
  final PlantAnimationController _controller = PlantAnimationController();

  @override
  void didUpdateWidget(AnimatedPlant oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.health != widget.health) {
      _controller.setHealth(widget.health);
    }

    if (widget.showWaterAnimation && !oldWidget.showWaterAnimation) {
      _controller.triggerWater();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RiveAnimation.asset(
      'assets/rive/plants/${widget.plantType}.riv',
      onInit: (artboard) {
        _controller.init(artboard);
        _controller.setHealth(widget.health);
      },
      fit: BoxFit.contain,
    );
  }
}
