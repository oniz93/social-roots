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
