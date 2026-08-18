import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../data/models/plant.dart';

/// Enhanced placeholder plant widget with unique visuals for each plant type
class AnimatedPlaceholderPlant extends StatefulWidget {
  final PlantType plantType;
  final double health;

  const AnimatedPlaceholderPlant({
    super.key,
    required this.plantType,
    required this.health,
  });

  @override
  State<AnimatedPlaceholderPlant> createState() =>
      _AnimatedPlaceholderPlantState();
}

class _AnimatedPlaceholderPlantState extends State<AnimatedPlaceholderPlant>
    with TickerProviderStateMixin {
  late AnimationController _swayController;
  late AnimationController _petalController;
  late AnimationController _sparkleController;
  final List<FallingPetal> _petals = [];
  final List<Sparkle> _sparkles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _swayController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _petalController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat();

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();

    // Generate falling petals for critical plants
    if (widget.health < 40) {
      _generatePetals();
    }

    // Generate sparkles for thriving plants
    if (widget.health >= 80) {
      _generateSparkles();
    }

    _petalController.addListener(_updatePetals);
    _sparkleController.addListener(_updateSparkles);
  }

  void _generatePetals() {
    final petalCount = widget.health < 20 ? 8 : 4;
    for (int i = 0; i < petalCount; i++) {
      _petals.add(
        FallingPetal(
          x: _random.nextDouble(),
          y: _random.nextDouble() * 0.5,
          size: 4 + _random.nextDouble() * 4,
          speed: 0.002 + _random.nextDouble() * 0.003,
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: 0.02 + _random.nextDouble() * 0.03,
          wobble: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  void _generateSparkles() {
    for (int i = 0; i < 6; i++) {
      _sparkles.add(
        Sparkle(
          x: 0.2 + _random.nextDouble() * 0.6,
          y: 0.1 + _random.nextDouble() * 0.5,
          size: 2 + _random.nextDouble() * 3,
          opacity: _random.nextDouble(),
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  void _updatePetals() {
    if (_petals.isEmpty) return;
    setState(() {
      for (final petal in _petals) {
        petal.y += petal.speed;
        petal.rotation += petal.rotationSpeed;
        petal.wobble += 0.05;
        petal.x += math.sin(petal.wobble) * 0.002;

        if (petal.y > 1.0) {
          petal.y = -0.1;
          petal.x = _random.nextDouble();
        }
      }
    });
  }

  void _updateSparkles() {
    if (_sparkles.isEmpty) return;
    setState(() {
      for (final sparkle in _sparkles) {
        sparkle.phase += 0.1;
        sparkle.opacity = (math.sin(sparkle.phase) + 1) / 2;
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedPlaceholderPlant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.health != widget.health) {
      _petals.clear();
      _sparkles.clear();
      if (widget.health < 40) {
        _generatePetals();
      }
      if (widget.health >= 80) {
        _generateSparkles();
      }
    }
  }

  @override
  void dispose() {
    _swayController.dispose();
    _petalController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _swayController,
      builder: (context, child) {
        return CustomPaint(
          painter: EnhancedPlantPainter(
            plantType: widget.plantType,
            health: widget.health,
            animationValue: _swayController.value,
            petals: _petals,
            sparkles: _sparkles,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class FallingPetal {
  double x;
  double y;
  double size;
  double speed;
  double rotation;
  double rotationSpeed;
  double wobble;

  FallingPetal({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
    required this.wobble,
  });
}

class Sparkle {
  double x;
  double y;
  double size;
  double opacity;
  double phase;

  Sparkle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.phase,
  });
}

class EnhancedPlantPainter extends CustomPainter {
  final PlantType plantType;
  final double health;
  final double animationValue;
  final List<FallingPetal> petals;
  final List<Sparkle> sparkles;

  EnhancedPlantPainter({
    required this.plantType,
    required this.health,
    required this.animationValue,
    required this.petals,
    required this.sparkles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height * 0.85;

    // Draw falling petals for unhealthy plants
    if (petals.isNotEmpty) {
      _drawFallingPetals(canvas, size);
    }

    // Draw sparkles for thriving plants
    if (sparkles.isNotEmpty) {
      _drawSparkles(canvas, size);
    }

    // Draw decorative pot with shadow
    _drawPotWithShadow(canvas, size, centerX, baseY);

    // Draw plant based on type
    switch (plantType) {
      case PlantType.cactus:
        _drawCactus(canvas, size, centerX, baseY);
        break;
      case PlantType.snakePlant:
        _drawSnakePlant(canvas, size, centerX, baseY);
        break;
      case PlantType.succulent:
        _drawSucculent(canvas, size, centerX, baseY);
        break;
      case PlantType.monstera:
        _drawMonstera(canvas, size, centerX, baseY);
        break;
      case PlantType.sunflower:
        _drawSunflower(canvas, size, centerX, baseY);
        break;
      case PlantType.pothos:
        _drawPothos(canvas, size, centerX, baseY);
        break;
      case PlantType.orchid:
        _drawOrchid(canvas, size, centerX, baseY);
        break;
      case PlantType.fern:
        _drawFern(canvas, size, centerX, baseY);
        break;
      case PlantType.rose:
        _drawRose(canvas, size, centerX, baseY);
        break;
    }
  }

  void _drawFallingPetals(Canvas canvas, Size size) {
    final petalColor = _getPetalColor();
    for (final petal in petals) {
      canvas.save();
      canvas.translate(petal.x * size.width, petal.y * size.height);
      canvas.rotate(petal.rotation);

      final paint = Paint()
        ..color = petalColor.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;

      // Draw teardrop-shaped petal
      final path = Path()
        ..moveTo(0, -petal.size)
        ..quadraticBezierTo(petal.size * 0.8, 0, 0, petal.size)
        ..quadraticBezierTo(-petal.size * 0.8, 0, 0, -petal.size);

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _drawSparkles(Canvas canvas, Size size) {
    for (final sparkle in sparkles) {
      final paint = Paint()
        ..color = Colors.yellow.shade200.withValues(alpha: sparkle.opacity * 0.8)
        ..style = PaintingStyle.fill;

      final x = sparkle.x * size.width;
      final y = sparkle.y * size.height;

      // Draw star shape
      _drawStar(canvas, x, y, sparkle.size, paint);
    }
  }

  void _drawStar(Canvas canvas, double x, double y, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final outerX = x + math.cos(angle) * size;
      final outerY = y + math.sin(angle) * size;
      final innerAngle = angle + math.pi / 4;
      final innerX = x + math.cos(innerAngle) * size * 0.3;
      final innerY = y + math.sin(innerAngle) * size * 0.3;

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  Color _getPetalColor() {
    switch (plantType) {
      case PlantType.rose:
        return Colors.red.shade300;
      case PlantType.orchid:
        return Colors.purple.shade200;
      case PlantType.sunflower:
        return Colors.yellow.shade300;
      default:
        return Colors.green.shade300;
    }
  }

  void _drawPotWithShadow(
    Canvas canvas,
    Size size,
    double centerX,
    double baseY,
  ) {
    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, size.height - 5),
        width: 70,
        height: 12,
      ),
      shadowPaint,
    );

    // Pot body - terracotta gradient effect
    final potRect = Rect.fromLTRB(
      centerX - 30,
      baseY,
      centerX + 30,
      size.height - 3,
    );

    final potGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.brown.shade500,
        Colors.brown.shade300,
        Colors.brown.shade400,
      ],
    );

    final potPath = Path()
      ..moveTo(centerX - 30, baseY)
      ..lineTo(centerX - 25, size.height - 3)
      ..lineTo(centerX + 25, size.height - 3)
      ..lineTo(centerX + 30, baseY)
      ..close();

    canvas.drawPath(
      potPath,
      Paint()..shader = potGradient.createShader(potRect),
    );

    // Pot rim
    final rimPaint = Paint()
      ..color = Colors.brown.shade600
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, baseY - 2),
          width: 66,
          height: 8,
        ),
        const Radius.circular(2),
      ),
      rimPaint,
    );

    // Soil with texture
    final soilColor = Color.lerp(
      Colors.brown.shade200,
      Colors.brown.shade800,
      health / 100,
    )!;

    final soilPaint = Paint()
      ..color = soilColor
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, baseY), width: 58, height: 14),
      soilPaint,
    );

    // Soil texture dots
    if (health > 50) {
      final texturePaint = Paint()
        ..color = Colors.brown.shade900.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 5; i++) {
        final offsetX = (i - 2) * 10.0;
        canvas.drawCircle(Offset(centerX + offsetX, baseY), 1.5, texturePaint);
      }
    }
  }

  // Calculate sway and droop based on health
  double get _swayAmount {
    return health > 60
        ? math.sin(animationValue * math.pi * 2) * 4 * (health / 100)
        : 0;
  }

  double get _droopAngle {
    return ((100 - health) / 100) * (math.pi / 5);
  }

  Color get _stemColor {
    if (health >= 60) return Colors.green.shade700;
    if (health >= 40) return Colors.green.shade500;
    if (health >= 20) return Colors.amber.shade700;
    return Colors.brown.shade400;
  }

  Color get _leafColor {
    if (health >= 60) return Colors.green.shade600;
    if (health >= 40) return Colors.green.shade400;
    if (health >= 20) return Colors.yellow.shade700;
    return Colors.brown.shade300;
  }

  // === CACTUS ===
  void _drawCactus(Canvas canvas, Size size, double centerX, double baseY) {
    final cactusColor = health >= 50
        ? Colors.green.shade600
        : Colors.green.shade300;
    final highlightColor = health >= 50
        ? Colors.green.shade400
        : Colors.green.shade200;

    final height = size.height * 0.45 * (0.6 + health / 250);

    // Main body
    final bodyPath = Path();
    bodyPath.moveTo(centerX - 18, baseY - 5);
    bodyPath.quadraticBezierTo(
      centerX - 22 + _swayAmount * 0.3,
      baseY - height * 0.5,
      centerX - 15 + _swayAmount * 0.5,
      baseY - height,
    );
    bodyPath.quadraticBezierTo(
      centerX + _swayAmount,
      baseY - height - 15,
      centerX + 15 + _swayAmount * 0.5,
      baseY - height,
    );
    bodyPath.quadraticBezierTo(
      centerX + 22 + _swayAmount * 0.3,
      baseY - height * 0.5,
      centerX + 18,
      baseY - 5,
    );
    bodyPath.close();

    // Gradient for 3D effect
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [cactusColor, highlightColor, cactusColor],
    );

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = bodyGradient.createShader(
          Rect.fromLTRB(centerX - 22, baseY - height - 15, centerX + 22, baseY),
        ),
    );

    // Draw ridges
    final ridgePaint = Paint()
      ..color = Colors.green.shade800.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = -1; i <= 1; i++) {
      final ridgePath = Path();
      final offsetX = i * 8.0;
      ridgePath.moveTo(centerX + offsetX, baseY - 8);
      ridgePath.quadraticBezierTo(
        centerX + offsetX + _swayAmount * 0.5,
        baseY - height * 0.5,
        centerX + offsetX + _swayAmount,
        baseY - height + 5,
      );
      canvas.drawPath(ridgePath, ridgePaint);
    }

    // Draw spines
    if (health >= 30) {
      final spinePaint = Paint()
        ..color = Colors.yellow.shade100
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round;

      for (int row = 0; row < 4; row++) {
        final y = baseY - 15 - row * (height - 20) / 4;
        for (int col = -1; col <= 1; col++) {
          final x = centerX + col * 12 + _swayAmount * (row / 4);
          // Draw small star-like spines
          for (int s = 0; s < 3; s++) {
            final angle = s * math.pi / 3 - math.pi / 6;
            canvas.drawLine(
              Offset(x, y),
              Offset(x + math.cos(angle) * 4, y + math.sin(angle) * 4),
              spinePaint,
            );
          }
        }
      }
    }

    // Flower on top for healthy cactus
    if (health >= 80) {
      final flowerCenter = Offset(centerX + _swayAmount, baseY - height - 8);

      // Petals
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3 + animationValue * 0.2;
        final petalPath = Path();
        petalPath.moveTo(flowerCenter.dx, flowerCenter.dy);
        petalPath.quadraticBezierTo(
          flowerCenter.dx + math.cos(angle) * 12,
          flowerCenter.dy + math.sin(angle) * 8,
          flowerCenter.dx + math.cos(angle) * 8,
          flowerCenter.dy + math.sin(angle) * 12,
        );
        canvas.drawPath(
          petalPath,
          Paint()
            ..color = Colors.pink.shade300
            ..style = PaintingStyle.fill,
        );
      }

      // Center
      canvas.drawCircle(
        flowerCenter,
        4,
        Paint()..color = Colors.yellow.shade400,
      );
    }
  }

  // === SNAKE PLANT ===
  void _drawSnakePlant(Canvas canvas, Size size, double centerX, double baseY) {
    final leafCount = health >= 60 ? 5 : (health >= 30 ? 3 : 2);
    final maxHeight = size.height * 0.55 * (0.5 + health / 200);

    for (int i = 0; i < leafCount; i++) {
      final leafIndex = i - (leafCount - 1) / 2;
      final angleOffset = leafIndex * 0.15;
      final heightMultiplier = 1.0 - (leafIndex.abs() * 0.15);
      final leafHeight = maxHeight * heightMultiplier;

      final baseOffset = leafIndex * 6;
      final sway = _swayAmount * (1 + i * 0.1);

      _drawSnakeLeaf(
        canvas,
        centerX + baseOffset,
        baseY - 5,
        leafHeight,
        angleOffset + _droopAngle * 0.3,
        sway,
      );
    }
  }

  void _drawSnakeLeaf(
    Canvas canvas,
    double x,
    double y,
    double height,
    double angle,
    double sway,
  ) {
    final leafWidth = 14.0;

    final path = Path();

    // Calculate tip position with sway
    final tipX = x + math.sin(angle) * height + sway;
    final tipY = y - math.cos(angle) * height;

    path.moveTo(x - leafWidth / 2, y);

    // Left edge
    path.quadraticBezierTo(
      x - leafWidth / 2 + sway * 0.3,
      y - height * 0.5,
      tipX - 2,
      tipY + 5,
    );

    // Pointed tip
    path.lineTo(tipX, tipY);
    path.lineTo(tipX + 2, tipY + 5);

    // Right edge
    path.quadraticBezierTo(
      x + leafWidth / 2 + sway * 0.3,
      y - height * 0.5,
      x + leafWidth / 2,
      y,
    );

    path.close();

    // Gradient fill
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        _leafColor.withGreen(((_leafColor.g * 255).round() * 0.8).toInt()),
        _leafColor,
        _leafColor.withGreen(((_leafColor.g * 255).round() * 0.8).toInt()),
      ],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTRB(x - 10, tipY, x + 10, y),
        ),
    );

    // Yellow edge bands (characteristic of snake plant)
    if (health >= 40) {
      final edgePaint = Paint()
        ..color = Colors.yellow.shade200.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawPath(path, edgePaint);
    }

    // Horizontal pattern bands
    if (health >= 50) {
      final bandPaint = Paint()
        ..color = Colors.green.shade900.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (int b = 1; b < 5; b++) {
        final bandY = y - (height * b / 5);
        final bandWidth = leafWidth * (1 - b * 0.15);
        canvas.drawLine(
          Offset(x - bandWidth / 2 + sway * (b / 5), bandY),
          Offset(x + bandWidth / 2 + sway * (b / 5), bandY),
          bandPaint,
        );
      }
    }
  }

  // === SUCCULENT ===
  void _drawSucculent(Canvas canvas, Size size, double centerX, double baseY) {
    final layers = health >= 60 ? 3 : 2;
    final succulentColor = health >= 50
        ? Colors.teal.shade400
        : Colors.teal.shade200;

    for (int layer = layers - 1; layer >= 0; layer--) {
      final layerY = baseY - 8 - layer * 12;
      final petalCount = layer == 0 ? 8 : (layer == 1 ? 6 : 4);
      final petalSize = 18 - layer * 4.0;

      for (int i = 0; i < petalCount; i++) {
        final angle =
            (i / petalCount) * math.pi * 2 + layer * 0.3 + _swayAmount * 0.02;

        final petalX = centerX + math.cos(angle) * (petalSize * 0.5);
        final petalY = layerY + math.sin(angle) * (petalSize * 0.25);

        _drawSucculentPetal(
          canvas,
          petalX,
          petalY,
          petalSize,
          angle,
          succulentColor,
          layer,
        );
      }
    }

    // Center rosette
    canvas.drawCircle(
      Offset(centerX, baseY - 8 - (layers - 1) * 12),
      4,
      Paint()
        ..color = succulentColor.withGreen(
          ((succulentColor.g * 255).round() * 1.2).toInt().clamp(0, 255),
        ),
    );
  }

  void _drawSucculentPetal(
    Canvas canvas,
    double x,
    double y,
    double size,
    double angle,
    Color color,
    int layer,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle + math.pi / 2);

    final path = Path();
    path.moveTo(0, size * 0.3);
    path.quadraticBezierTo(-size * 0.4, 0, 0, -size * 0.7);
    path.quadraticBezierTo(size * 0.4, 0, 0, size * 0.3);

    // Gradient for 3D chubby look
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [color.withValues(alpha: 0.8), color, color.withValues(alpha: 0.8)],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTRB(-size / 2, -size, size / 2, size / 2),
        ),
    );

    // Highlight
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    canvas.restore();
  }

  // === MONSTERA ===
  void _drawMonstera(Canvas canvas, Size size, double centerX, double baseY) {
    final leafCount = health >= 60 ? 3 : 2;
    final stemHeight = size.height * 0.3;

    // Draw stems and leaves
    for (int i = 0; i < leafCount; i++) {
      final angle = (i - (leafCount - 1) / 2) * 0.4;
      final leafSize = (40 - i * 8) * (0.5 + health / 200);

      // Stem
      final stemPaint = Paint()
        ..color = _stemColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      final stemPath = Path();
      final endX =
          centerX + math.sin(angle + _droopAngle) * stemHeight + _swayAmount;
      final endY = baseY - math.cos(angle + _droopAngle) * stemHeight;

      stemPath.moveTo(centerX + i * 5 - 5, baseY - 5);
      stemPath.quadraticBezierTo(
        centerX + _swayAmount * 0.5,
        baseY - stemHeight * 0.5,
        endX,
        endY,
      );

      canvas.drawPath(stemPath, stemPaint);

      // Monstera leaf
      _drawMonsteraLeaf(
        canvas,
        endX,
        endY,
        leafSize,
        angle + _swayAmount * 0.02,
      );
    }
  }

  void _drawMonsteraLeaf(
    Canvas canvas,
    double x,
    double y,
    double size,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);

    final leafPath = Path();

    // Heart-shaped leaf with characteristic holes
    leafPath.moveTo(0, size * 0.1);

    // Left lobe
    leafPath.cubicTo(
      -size * 0.8,
      -size * 0.2,
      -size * 0.9,
      -size * 0.8,
      0,
      -size,
    );

    // Right lobe
    leafPath.cubicTo(
      size * 0.9,
      -size * 0.8,
      size * 0.8,
      -size * 0.2,
      0,
      size * 0.1,
    );

    // Gradient fill
    final gradient = RadialGradient(
      center: const Alignment(0, -0.3),
      radius: 1.2,
      colors: [
        _leafColor,
        _leafColor.withGreen(((_leafColor.g * 255).round() * 0.8).toInt()),
      ],
    );

    canvas.drawPath(
      leafPath,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTRB(-size, -size, size, size * 0.2),
        ),
    );

    // Characteristic holes (fenestrations) for healthy plants
    if (health >= 50) {
      final holePaint = Paint()
        ..color = Colors.green.shade900.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      // Left holes
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-size * 0.35, -size * 0.4),
          width: size * 0.2,
          height: size * 0.35,
        ),
        holePaint,
      );

      // Right holes
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size * 0.35, -size * 0.4),
          width: size * 0.2,
          height: size * 0.35,
        ),
        holePaint,
      );
    }

    // Center vein
    final veinPaint = Paint()
      ..color = Colors.green.shade800.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(0, size * 0.05), Offset(0, -size * 0.9), veinPaint);

    canvas.restore();
  }

  // === SUNFLOWER ===
  void _drawSunflower(Canvas canvas, Size size, double centerX, double baseY) {
    final stemHeight = size.height * 0.5 * (0.5 + health / 200);
    final flowerSize = 28 * (0.5 + health / 200);

    // Stem
    final stemPaint = Paint()
      ..color = _stemColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final tipX = centerX + math.sin(_droopAngle) * stemHeight + _swayAmount;
    final tipY = baseY - math.cos(_droopAngle) * stemHeight;

    final stemPath = Path();
    stemPath.moveTo(centerX, baseY - 5);
    stemPath.quadraticBezierTo(
      centerX + _swayAmount * 0.5,
      baseY - stemHeight * 0.5,
      tipX,
      tipY,
    );

    canvas.drawPath(stemPath, stemPaint);

    // Leaves on stem
    if (health >= 40) {
      _drawSunflowerLeaf(
        canvas,
        centerX + 5,
        baseY - stemHeight * 0.3,
        20,
        0.3,
      );
      _drawSunflowerLeaf(
        canvas,
        centerX - 5,
        baseY - stemHeight * 0.5,
        18,
        -0.4,
      );
    }

    // Flower head
    _drawSunflowerHead(canvas, tipX, tipY, flowerSize);
  }

  void _drawSunflowerLeaf(
    Canvas canvas,
    double x,
    double y,
    double size,
    double angle,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size * 0.5, -size * 0.3, size, 0);
    path.quadraticBezierTo(size * 0.5, size * 0.3, 0, 0);

    canvas.drawPath(path, Paint()..color = _leafColor);
    canvas.restore();
  }

  void _drawSunflowerHead(Canvas canvas, double x, double y, double size) {
    final petalColor = health >= 40
        ? Colors.yellow.shade500
        : Colors.yellow.shade200;
    final centerColor = health >= 40
        ? Colors.brown.shade700
        : Colors.brown.shade400;

    // Petals
    final petalCount = 12;
    for (int i = 0; i < petalCount; i++) {
      final angle = (i / petalCount) * math.pi * 2 + animationValue * 0.1;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      final petalPath = Path();
      petalPath.moveTo(0, -size * 0.3);
      petalPath.quadraticBezierTo(size * 0.2, -size * 0.6, 0, -size);
      petalPath.quadraticBezierTo(-size * 0.2, -size * 0.6, 0, -size * 0.3);

      canvas.drawPath(petalPath, Paint()..color = petalColor);

      // Petal highlight
      canvas.drawPath(
        petalPath,
        Paint()
          ..color = Colors.yellow.shade300.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      canvas.restore();
    }

    // Center disk with seeds pattern
    canvas.drawCircle(Offset(x, y), size * 0.35, Paint()..color = centerColor);

    // Seed pattern
    if (health >= 50) {
      final seedPaint = Paint()
        ..color = Colors.brown.shade900
        ..style = PaintingStyle.fill;

      for (int ring = 1; ring <= 2; ring++) {
        final ringRadius = size * 0.12 * ring;
        final seedCount = 6 + ring * 2;
        for (int s = 0; s < seedCount; s++) {
          final seedAngle = (s / seedCount) * math.pi * 2;
          canvas.drawCircle(
            Offset(
              x + math.cos(seedAngle) * ringRadius,
              y + math.sin(seedAngle) * ringRadius,
            ),
            1.5,
            seedPaint,
          );
        }
      }
    }
  }

  // === POTHOS ===
  void _drawPothos(Canvas canvas, Size size, double centerX, double baseY) {
    final vineCount = health >= 60 ? 4 : 3;

    for (int i = 0; i < vineCount; i++) {
      final startAngle = (i / (vineCount - 1) - 0.5) * 0.8;
      final vineLength = (size.height * 0.4 + i * 10) * (0.5 + health / 200);

      _drawPothosVine(
        canvas,
        centerX + i * 8 - 12,
        baseY - 5,
        vineLength,
        startAngle,
      );
    }
  }

  void _drawPothosVine(
    Canvas canvas,
    double x,
    double y,
    double length,
    double angle,
  ) {
    final vinePaint = Paint()
      ..color = _stemColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(x, y);

    // Wavy vine with cascading effect
    final segments = 5;
    double currentX = x;
    double currentY = y;

    for (int s = 0; s < segments; s++) {
      final progress = s / segments;
      final segmentLength = length / segments;
      final wobble =
          math.sin(progress * math.pi * 2 + animationValue * math.pi * 2) * 8;

      final nextX =
          x + angle * length * progress + wobble + _swayAmount * progress;
      final nextY = y - segmentLength * (s + 1) + progress * 20; // Cascade down

      path.quadraticBezierTo(
        (currentX + nextX) / 2 + wobble,
        (currentY + nextY) / 2,
        nextX,
        nextY,
      );

      // Draw leaf at each segment
      if (health >= 30 + s * 10) {
        _drawPothosLeaf(canvas, nextX, nextY, 12.0 - s, angle + wobble * 0.05);
      }

      currentX = nextX;
      currentY = nextY;
    }

    canvas.drawPath(path, vinePaint);
  }

  void _drawPothosLeaf(
    Canvas canvas,
    double x,
    double y,
    double size,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);

    // Heart-shaped leaf
    final path = Path();
    path.moveTo(0, size * 0.2);
    path.cubicTo(-size * 0.6, 0, -size * 0.5, -size * 0.8, 0, -size);
    path.cubicTo(size * 0.5, -size * 0.8, size * 0.6, 0, 0, size * 0.2);

    final gradient = RadialGradient(
      center: const Alignment(0.2, -0.3),
      radius: 1,
      colors: [
        _leafColor,
        _leafColor.withGreen(((_leafColor.g * 255).round() * 0.85).toInt()),
      ],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTRB(-size, -size, size, size),
        ),
    );

    // Variegation pattern for healthy plants
    if (health >= 60) {
      final variegationPaint = Paint()
        ..color = Colors.yellow.shade100.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;

      final varPath = Path();
      varPath.moveTo(-size * 0.2, -size * 0.3);
      varPath.quadraticBezierTo(0, -size * 0.6, size * 0.1, -size * 0.4);
      varPath.quadraticBezierTo(0, -size * 0.2, -size * 0.2, -size * 0.3);

      canvas.drawPath(varPath, variegationPaint);
    }

    canvas.restore();
  }

  // === ORCHID ===
  void _drawOrchid(Canvas canvas, Size size, double centerX, double baseY) {
    final stemHeight = size.height * 0.5 * (0.5 + health / 200);
    final flowerCount = health >= 70 ? 3 : (health >= 40 ? 2 : 1);

    // Curved stem
    final stemPaint = Paint()
      ..color = _stemColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final stemPath = Path();
    stemPath.moveTo(centerX, baseY - 5);

    // S-curve stem
    stemPath.cubicTo(
      centerX - 15 + _swayAmount,
      baseY - stemHeight * 0.3,
      centerX + 15 + _swayAmount,
      baseY - stemHeight * 0.7,
      centerX + _swayAmount,
      baseY - stemHeight,
    );

    canvas.drawPath(stemPath, stemPaint);

    // Orchid flowers along the stem
    for (int i = 0; i < flowerCount; i++) {
      final t = 0.5 + i * 0.2;
      final flowerX = centerX + math.sin(t * math.pi) * 12 + _swayAmount * t;
      final flowerY = baseY - stemHeight * t;

      _drawOrchidFlower(canvas, flowerX, flowerY, 16 - i * 2);
    }

    // Leaves at base
    for (int i = 0; i < 3; i++) {
      final leafAngle = (i - 1) * 0.4;
      _drawOrchidLeaf(canvas, centerX + (i - 1) * 8, baseY - 3, 35, leafAngle);
    }
  }

  void _drawOrchidFlower(Canvas canvas, double x, double y, double size) {
    final petalColor = health >= 50
        ? Colors.purple.shade300
        : Colors.purple.shade100;
    final centerColor = health >= 50
        ? Colors.purple.shade600
        : Colors.purple.shade300;

    // Back petals (sepals)
    for (int i = 0; i < 3; i++) {
      final angle = i * math.pi * 2 / 3 - math.pi / 2;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      final petalPath = Path();
      petalPath.moveTo(0, 0);
      petalPath.quadraticBezierTo(-size * 0.3, -size * 0.4, 0, -size);
      petalPath.quadraticBezierTo(size * 0.3, -size * 0.4, 0, 0);

      canvas.drawPath(petalPath, Paint()..color = petalColor.withValues(alpha: 0.7));
      canvas.restore();
    }

    // Front petals (larger, rounder)
    for (int i = 0; i < 2; i++) {
      final angle = (i == 0 ? -0.5 : 0.5);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      final petalPath = Path();
      petalPath.addOval(
        Rect.fromCenter(
          center: Offset(0, -size * 0.5),
          width: size * 0.6,
          height: size * 0.8,
        ),
      );

      canvas.drawPath(petalPath, Paint()..color = petalColor);
      canvas.restore();
    }

    // Lip (labellum)
    final lipPath = Path();
    lipPath.moveTo(x, y);
    lipPath.quadraticBezierTo(
      x - size * 0.3,
      y + size * 0.3,
      x,
      y + size * 0.6,
    );
    lipPath.quadraticBezierTo(x + size * 0.3, y + size * 0.3, x, y);

    canvas.drawPath(lipPath, Paint()..color = centerColor);

    // Center column
    canvas.drawCircle(
      Offset(x, y - 2),
      size * 0.15,
      Paint()..color = Colors.yellow.shade300,
    );
  }

  void _drawOrchidLeaf(
    Canvas canvas,
    double x,
    double y,
    double length,
    double angle,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(
      -8 + _swayAmount * 0.2,
      -length * 0.3,
      -6,
      -length * 0.7,
    );
    path.quadraticBezierTo(0, -length - 5, 6, -length * 0.7);
    path.quadraticBezierTo(8 + _swayAmount * 0.2, -length * 0.3, 0, 0);

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _leafColor,
        _leafColor.withGreen(((_leafColor.g * 255).round() * 1.1).toInt().clamp(0, 255)),
      ],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(Rect.fromLTRB(-10, -length, 10, 0)),
    );

    canvas.restore();
  }

  // === FERN ===
  void _drawFern(Canvas canvas, Size size, double centerX, double baseY) {
    final frondCount = health >= 60 ? 7 : 5;
    final maxHeight = size.height * 0.55 * (0.5 + health / 200);

    for (int i = 0; i < frondCount; i++) {
      final angle = (i / (frondCount - 1) - 0.5) * 1.2 + _droopAngle * 0.5;
      final frondHeight =
          maxHeight *
          (0.7 + (1 - (i - frondCount / 2).abs() / (frondCount / 2)) * 0.3);

      _drawFernFrond(canvas, centerX, baseY - 5, frondHeight, angle);
    }
  }

  void _drawFernFrond(
    Canvas canvas,
    double x,
    double y,
    double length,
    double angle,
  ) {
    final stemPaint = Paint()
      ..color = _stemColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Main stem
    final endX = x + math.sin(angle) * length + _swayAmount;
    final endY = y - math.cos(angle) * length;

    final stemPath = Path();
    stemPath.moveTo(x, y);
    stemPath.quadraticBezierTo(
      x + math.sin(angle) * length * 0.5 + _swayAmount * 0.5,
      y - math.cos(angle) * length * 0.5,
      endX,
      endY,
    );

    canvas.drawPath(stemPath, stemPaint);

    // Leaflets along the frond
    final leafletCount = (health / 10).floor().clamp(4, 10);
    for (int l = 1; l <= leafletCount; l++) {
      final t = l / (leafletCount + 1);
      final leafletX = x + math.sin(angle) * length * t + _swayAmount * t;
      final leafletY = y - math.cos(angle) * length * t;
      final leafletSize = 8 * (1 - t * 0.5);

      // Left leaflet
      _drawFernLeaflet(
        canvas,
        leafletX,
        leafletY,
        leafletSize,
        angle - math.pi / 3,
      );
      // Right leaflet
      _drawFernLeaflet(
        canvas,
        leafletX,
        leafletY,
        leafletSize,
        angle + math.pi / 3,
      );
    }
  }

  void _drawFernLeaflet(
    Canvas canvas,
    double x,
    double y,
    double size,
    double angle,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size * 0.5, -size * 0.3, size, 0);
    path.quadraticBezierTo(size * 0.5, size * 0.1, 0, 0);

    canvas.drawPath(path, Paint()..color = _leafColor);
    canvas.restore();
  }

  // === ROSE ===
  void _drawRose(Canvas canvas, Size size, double centerX, double baseY) {
    final stemHeight = size.height * 0.5 * (0.5 + health / 200);

    // Thorny stem
    final stemPaint = Paint()
      ..color = _stemColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final tipX = centerX + math.sin(_droopAngle) * stemHeight + _swayAmount;
    final tipY = baseY - math.cos(_droopAngle) * stemHeight;

    final stemPath = Path();
    stemPath.moveTo(centerX, baseY - 5);
    stemPath.quadraticBezierTo(
      centerX + _swayAmount * 0.5,
      baseY - stemHeight * 0.5,
      tipX,
      tipY + 15,
    );

    canvas.drawPath(stemPath, stemPaint);

    // Thorns
    if (health >= 30) {
      final thornPaint = Paint()
        ..color = _stemColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      for (int t = 1; t <= 4; t++) {
        final thornY = baseY - stemHeight * t / 5;
        final thornX = centerX + _swayAmount * (t / 5);
        final side = t.isOdd ? 1 : -1;

        canvas.drawLine(
          Offset(thornX, thornY),
          Offset(thornX + side * 5, thornY - 3),
          thornPaint,
        );
      }
    }

    // Leaves
    if (health >= 40) {
      _drawRoseLeaf(canvas, centerX - 5, baseY - stemHeight * 0.3, 18, -0.5);
      _drawRoseLeaf(canvas, centerX + 5, baseY - stemHeight * 0.6, 15, 0.4);
    }

    // Rose bloom
    _drawRoseBloom(canvas, tipX, tipY, 22 * (0.5 + health / 200));
  }

  void _drawRoseLeaf(
    Canvas canvas,
    double x,
    double y,
    double size,
    double angle,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    // Compound leaf with 3 leaflets
    for (int i = -1; i <= 1; i++) {
      final leafletPath = Path();
      final offsetX = i * size * 0.4;
      final offsetY = i.abs() * size * 0.2;

      leafletPath.moveTo(offsetX, offsetY);
      leafletPath.quadraticBezierTo(
        offsetX - size * 0.3,
        offsetY - size * 0.3,
        offsetX,
        offsetY - size * 0.6,
      );
      leafletPath.quadraticBezierTo(
        offsetX + size * 0.3,
        offsetY - size * 0.3,
        offsetX,
        offsetY,
      );

      canvas.drawPath(leafletPath, Paint()..color = _leafColor);

      // Serrated edges
      final edgePaint = Paint()
        ..color = _leafColor.withGreen(((_leafColor.g * 255).round() * 0.8).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      canvas.drawPath(leafletPath, edgePaint);
    }

    canvas.restore();
  }

  void _drawRoseBloom(Canvas canvas, double x, double y, double size) {
    final petalColor = health >= 50 ? Colors.red.shade400 : Colors.red.shade200;
    final innerColor = health >= 50 ? Colors.red.shade600 : Colors.red.shade300;

    // Outer petals (5 visible)
    for (int layer = 0; layer < 3; layer++) {
      final layerSize = size * (1 - layer * 0.2);
      final petalCount = 5;
      final rotationOffset = layer * 0.3;

      for (int i = 0; i < petalCount; i++) {
        final angle =
            (i / petalCount) * math.pi * 2 +
            rotationOffset +
            animationValue * 0.05;

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angle);

        final petalPath = Path();

        // Cupped petal shape
        petalPath.moveTo(-layerSize * 0.25, 0);
        petalPath.cubicTo(
          -layerSize * 0.35,
          -layerSize * 0.5,
          -layerSize * 0.15,
          -layerSize * 0.9,
          0,
          -layerSize,
        );
        petalPath.cubicTo(
          layerSize * 0.15,
          -layerSize * 0.9,
          layerSize * 0.35,
          -layerSize * 0.5,
          layerSize * 0.25,
          0,
        );
        petalPath.quadraticBezierTo(0, layerSize * 0.1, -layerSize * 0.25, 0);

        final color = Color.lerp(petalColor, innerColor, layer / 3)!;
        canvas.drawPath(petalPath, Paint()..color = color);

        // Subtle gradient highlight
        canvas.drawPath(
          petalPath,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.1 * (1 - layer / 3))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );

        canvas.restore();
      }
    }

    // Center spiral effect
    if (health >= 60) {
      final spiralPaint = Paint()
        ..color = innerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      final spiralPath = Path();
      spiralPath.moveTo(x, y);
      for (double t = 0; t < math.pi * 4; t += 0.3) {
        final r = t * 0.8;
        spiralPath.lineTo(x + math.cos(t) * r, y + math.sin(t) * r);
      }
      canvas.drawPath(spiralPath, spiralPaint);
    }
  }

  @override
  bool shouldRepaint(covariant EnhancedPlantPainter oldDelegate) {
    return oldDelegate.health != health ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.petals.length != petals.length ||
        oldDelegate.sparkles.length != sparkles.length;
  }
}
