# Task 13: Rive Plant Animations

## Priority: MEDIUM
## Estimated Time: 8-10 hours (includes design work)
## Platform Focus: iOS First

---

## Objective
Create Rive animations for plant visualizations with state machines that respond to health levels, including watering and revival animations.

---

## Context
Rive is essential for the organic, visceral feel of plant health. Each plant needs:
- **Health State Machine:** Smoothly blends between 5 states
- **Watering Animation:** Triggered when plant is watered
- **Revival Animation:** Special effect when dormant plant is revived

### Health States to Animate
| State | Visual Characteristics |
|-------|----------------------|
| Thriving (80-100%) | Upright, gently swaying, vibrant colors |
| Thirsty (60-79%) | Slight droop, slightly desaturated |
| Wilting (40-59%) | Leaves curling, yellowing |
| Critical (20-39%) | Heavy droop, petals falling |
| Dormant (0-19%) | Brown/grey stick, no movement |

---

## Implementation

### 1. Rive File Structure
Each plant type needs its own Rive file with this structure:

```
assets/rive/plants/
├── cactus.riv
├── snake_plant.riv
├── succulent.riv
├── monstera.riv
├── sunflower.riv
├── pothos.riv
├── orchid.riv
├── fern.riv
└── rose.riv
```

### 2. State Machine Design (for Rive Editor)

**State Machine Name:** `PlantStateMachine`

**Inputs:**
- `health` (Number, 0.0 to 1.0) - Drives the health blend
- `water` (Trigger) - Triggers watering animation
- `revive` (Trigger) - Triggers revival animation

**States:**
1. `Idle` - Default state, health-driven blend
2. `Watering` - Plays water animation, returns to Idle
3. `Revival` - Plays revival animation, returns to Idle

**Blend Tree (in Idle state):**
- Health 0.0-0.2 → Dormant animation
- Health 0.2-0.4 → Critical animation
- Health 0.4-0.6 → Wilting animation
- Health 0.6-0.8 → Thirsty animation
- Health 0.8-1.0 → Thriving animation

### 3. Animation Widget (`lib/shared/widgets/animated_plant_widget.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../data/models/plant.dart';

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
      
      setState(() {
        _artboard = artboard;
      });
    } catch (e) {
      debugPrint('Error loading Rive file: $e');
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
    if (_artboard == null) {
      return _buildPlaceholder();
    }
    
    return Rive(
      artboard: _artboard!,
      fit: BoxFit.contain,
    );
  }
  
  Widget _buildPlaceholder() {
    // Show static placeholder while Rive loads
    return Container(
      color: Colors.green.shade50,
      child: Center(
        child: Icon(
          Icons.local_florist,
          size: 48,
          color: _getHealthColor(),
        ),
      ),
    );
  }
  
  Color _getHealthColor() {
    final health = widget.health;
    if (health >= 80) return Colors.green;
    if (health >= 60) return Colors.lightGreen;
    if (health >= 40) return Colors.orange;
    if (health >= 20) return Colors.deepOrange;
    return Colors.brown;
  }
}
```

### 4. Placeholder Plant Painter (Until Rive Assets Ready)
```dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../data/models/plant.dart';

class PlaceholderPlantPainter extends CustomPainter {
  final PlantType plantType;
  final double health;
  final double animationValue;
  
  PlaceholderPlantPainter({
    required this.plantType,
    required this.health,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height * 0.85;
    
    // Draw pot
    _drawPot(canvas, size, centerX, baseY);
    
    // Draw stem with health-based droop
    _drawStem(canvas, size, centerX, baseY);
    
    // Draw leaves/flowers based on plant type
    _drawPlant(canvas, size, centerX, baseY);
  }
  
  void _drawPot(Canvas canvas, Size size, double centerX, double baseY) {
    final potPaint = Paint()
      ..color = Colors.brown.shade400
      ..style = PaintingStyle.fill;
    
    final potPath = Path()
      ..moveTo(centerX - 30, baseY)
      ..lineTo(centerX - 25, size.height)
      ..lineTo(centerX + 25, size.height)
      ..lineTo(centerX + 30, baseY)
      ..close();
    
    canvas.drawPath(potPath, potPaint);
    
    // Soil - color based on health
    final soilColor = Color.lerp(
      Colors.brown.shade200, // Dry
      Colors.brown.shade800, // Wet
      health / 100,
    )!;
    
    final soilPaint = Paint()
      ..color = soilColor
      ..style = PaintingStyle.fill;
    
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, baseY),
        width: 60,
        height: 15,
      ),
      soilPaint,
    );
  }
  
  void _drawStem(Canvas canvas, Size size, double centerX, double baseY) {
    final stemPaint = Paint()
      ..color = _getStemColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    // Calculate droop based on health
    final droopFactor = (100 - health) / 100;
    final droopAngle = droopFactor * math.pi / 4; // Max 45 degree droop
    
    // Add gentle sway for healthy plants
    final swayOffset = health > 60 
        ? math.sin(animationValue * math.pi * 2) * 5 * (health / 100)
        : 0.0;
    
    final stemPath = Path();
    final stemHeight = size.height * 0.5 * (0.5 + health / 200);
    
    stemPath.moveTo(centerX, baseY - 5);
    
    // Bezier curve for drooping stem
    final endX = centerX + math.sin(droopAngle) * stemHeight + swayOffset;
    final endY = baseY - math.cos(droopAngle) * stemHeight;
    
    final controlX = centerX + swayOffset * 0.5;
    final controlY = baseY - stemHeight * 0.6;
    
    stemPath.quadraticBezierTo(controlX, controlY, endX, endY);
    
    canvas.drawPath(stemPath, stemPaint);
  }
  
  void _drawPlant(Canvas canvas, Size size, double centerX, double baseY) {
    // Draw leaves or flowers based on plant type
    final flowerPaint = Paint()
      ..color = _getFlowerColor()
      ..style = PaintingStyle.fill;
    
    final droopFactor = (100 - health) / 100;
    final stemHeight = size.height * 0.5 * (0.5 + health / 200);
    final droopAngle = droopFactor * math.pi / 4;
    
    final swayOffset = health > 60 
        ? math.sin(animationValue * math.pi * 2) * 5 * (health / 100)
        : 0.0;
    
    final flowerX = centerX + math.sin(droopAngle) * stemHeight + swayOffset;
    final flowerY = baseY - math.cos(droopAngle) * stemHeight;
    
    // Draw simple flower/leaf shape
    final flowerSize = 20 * (0.5 + health / 200);
    
    if (plantType == PlantType.sunflower) {
      // Draw petals
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final petalX = flowerX + math.cos(angle) * flowerSize;
        final petalY = flowerY + math.sin(angle) * flowerSize * 0.8;
        
        canvas.drawCircle(
          Offset(petalX, petalY),
          flowerSize * 0.4,
          flowerPaint,
        );
      }
      // Center
      canvas.drawCircle(
        Offset(flowerX, flowerY),
        flowerSize * 0.5,
        Paint()..color = Colors.brown.shade600,
      );
    } else {
      // Generic flower/leaf
      canvas.drawCircle(
        Offset(flowerX, flowerY),
        flowerSize,
        flowerPaint,
      );
    }
  }
  
  Color _getStemColor() {
    if (health >= 60) return Colors.green.shade700;
    if (health >= 40) return Colors.green.shade500;
    if (health >= 20) return Colors.amber.shade600;
    return Colors.brown.shade300;
  }
  
  Color _getFlowerColor() {
    if (health >= 60) {
      // Vibrant colors based on plant type
      switch (plantType) {
        case PlantType.rose:
          return Colors.red;
        case PlantType.sunflower:
          return Colors.yellow;
        case PlantType.orchid:
          return Colors.purple;
        default:
          return Colors.green;
      }
    } else if (health >= 40) {
      return Colors.yellow.shade600;
    } else if (health >= 20) {
      return Colors.brown.shade300;
    }
    return Colors.brown.shade200;
  }
  
  @override
  bool shouldRepaint(covariant PlaceholderPlantPainter oldDelegate) {
    return oldDelegate.health != health ||
           oldDelegate.animationValue != animationValue;
  }
}

class AnimatedPlaceholderPlant extends StatefulWidget {
  final PlantType plantType;
  final double health;
  
  const AnimatedPlaceholderPlant({
    super.key,
    required this.plantType,
    required this.health,
  });
  
  @override
  State<AnimatedPlaceholderPlant> createState() => _AnimatedPlaceholderPlantState();
}

class _AnimatedPlaceholderPlantState extends State<AnimatedPlaceholderPlant>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: PlaceholderPlantPainter(
            plantType: widget.plantType,
            health: widget.health,
            animationValue: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}
```

### 5. Rive Asset Specifications

**For each plant, create in Rive:**

#### Cactus
- Simple, minimal movement in healthy state
- Spines droop when unhealthy
- Turn grey/brown when dormant

#### Sunflower
- Head tracks "sun" (slight movement)
- Petals fall in critical state
- Stem bends dramatically when wilting

#### Rose
- Petals detach one by one as health drops
- Thorns visible even when dormant
- Beautiful bloom animation on revival

#### Monstera
- Iconic split leaves
- Leaves curl inward when thirsty
- New leaf unfurls on revival

#### Orchid
- Delicate swaying
- Flowers drop in critical state
- Multiple blooms appear at full health

---

## Acceptance Criteria
- [ ] Rive files created for at least 3 plant types
- [ ] State machine responds to health input smoothly
- [ ] Watering trigger plays water animation
- [ ] Revival trigger plays revival animation
- [ ] Placeholder animation works while Rive loads
- [ ] Plant widget integrates with plant cards
- [ ] Health changes cause smooth visual transitions
- [ ] Dormant state looks clearly "dormant"

---

## Design Notes
- Use Rive Community for inspiration
- Keep file sizes small (<500KB each)
- Test on older iOS devices for performance
- Consider creating a "generic" plant for fallback

---

## Dependencies
- Task 01: Project Setup
- Task 04: Plant Health Engine

## Blocks
- Enhances Task 05: Garden Home Screen
- Enhances Task 06: Plant Detail Screen
