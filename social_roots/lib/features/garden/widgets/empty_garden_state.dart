import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../../core/services/contact_service.dart';

class EmptyGardenState extends ConsumerStatefulWidget {
  const EmptyGardenState({super.key});

  @override
  ConsumerState<EmptyGardenState> createState() => _EmptyGardenStateState();
}

class _EmptyGardenStateState extends ConsumerState<EmptyGardenState>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _seedController;
  late AnimationController _shimmerController;
  final List<FloatingSeed> _seeds = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _seedController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Generate floating seeds
    for (int i = 0; i < 8; i++) {
      _seeds.add(
        FloatingSeed(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 3 + _random.nextDouble() * 4,
          speed: 0.001 + _random.nextDouble() * 0.002,
          wobblePhase: _random.nextDouble() * math.pi * 2,
          rotationSpeed: 0.01 + _random.nextDouble() * 0.02,
          rotation: _random.nextDouble() * math.pi * 2,
        ),
      );
    }

    _seedController.addListener(_updateSeeds);
  }

  void _updateSeeds() {
    setState(() {
      for (final seed in _seeds) {
        seed.y -= seed.speed;
        seed.wobblePhase += 0.03;
        seed.x += math.sin(seed.wobblePhase) * 0.002;
        seed.rotation += seed.rotationSpeed;

        if (seed.y < -0.1) {
          seed.y = 1.1;
          seed.x = _random.nextDouble();
        }
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _seedController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating seeds background
        Positioned.fill(
          child: CustomPaint(painter: FloatingSeedsPainter(seeds: _seeds)),
        ),

        // Main content
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated empty pot illustration
                AnimatedBuilder(
                  animation: _floatController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        math.sin(_floatController.value * math.pi) * 8,
                      ),
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: EmptyPotPainter(
                            shimmerValue: _shimmerController.value,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title with gradient
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, Colors.green.shade200, Colors.white],
                    stops: [
                      (_shimmerController.value - 0.3).clamp(0, 1),
                      _shimmerController.value.clamp(0, 1),
                      (_shimmerController.value + 0.3).clamp(0, 1),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Your garden awaits',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Plant your first seed to start\nnurturing your relationships',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Animated button
                AnimatedBuilder(
                  animation: _floatController,
                  builder: (context, child) {
                    final scale =
                        1.0 +
                        math.sin(_floatController.value * math.pi * 2) * 0.03;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade400.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final status = ref.read(contactPermissionProvider);
                        if (status == ContactPermissionStatus.granted) {
                          Navigator.pushNamed(context, '/contact-selection');
                        } else {
                          Navigator.pushNamed(context, '/permissions');
                        }
                      },
                      icon: const Icon(Icons.eco, size: 22),
                      label: const Text('Plant Your First Seed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Hint text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Each contact becomes a plant to nurture',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FloatingSeed {
  double x;
  double y;
  double size;
  double speed;
  double wobblePhase;
  double rotation;
  double rotationSpeed;

  FloatingSeed({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.wobblePhase,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class FloatingSeedsPainter extends CustomPainter {
  final List<FloatingSeed> seeds;

  FloatingSeedsPainter({required this.seeds});

  @override
  void paint(Canvas canvas, Size size) {
    for (final seed in seeds) {
      canvas.save();
      canvas.translate(seed.x * size.width, seed.y * size.height);
      canvas.rotate(seed.rotation);

      // Draw dandelion seed shape
      final stemPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      final fluffPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.fill;

      // Seed body
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, seed.size),
          width: seed.size * 0.4,
          height: seed.size * 0.8,
        ),
        Paint()..color = Colors.brown.shade300.withOpacity(0.6),
      );

      // Stem
      canvas.drawLine(
        Offset(0, seed.size * 0.5),
        Offset(0, -seed.size * 0.5),
        stemPaint,
      );

      // Fluffy top (parachute)
      final fluffCount = 8;
      for (int i = 0; i < fluffCount; i++) {
        final angle = (i / fluffCount) * math.pi * 2;
        final fluffLength = seed.size * 1.2;

        canvas.drawLine(
          const Offset(0, 0),
          Offset(
            math.cos(angle) * fluffLength,
            math.sin(angle) * fluffLength * 0.6 - fluffLength * 0.3,
          ),
          stemPaint,
        );

        // Tiny fluff at the end
        canvas.drawCircle(
          Offset(
            math.cos(angle) * fluffLength,
            math.sin(angle) * fluffLength * 0.6 - fluffLength * 0.3,
          ),
          0.8,
          fluffPaint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant FloatingSeedsPainter oldDelegate) => true;
}

class EmptyPotPainter extends CustomPainter {
  final double shimmerValue;

  EmptyPotPainter({required this.shimmerValue});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.88),
        width: size.width * 0.6,
        height: size.height * 0.08,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Pot dimensions
    final potTop = centerY - 10;
    final potBottom = size.height * 0.85;
    final potTopWidth = size.width * 0.45;
    final potBottomWidth = size.width * 0.35;

    // Pot body with gradient
    final potPath = Path()
      ..moveTo(centerX - potTopWidth / 2, potTop + 15)
      ..lineTo(centerX - potBottomWidth / 2, potBottom)
      ..lineTo(centerX + potBottomWidth / 2, potBottom)
      ..lineTo(centerX + potTopWidth / 2, potTop + 15)
      ..close();

    final potGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.brown.shade600,
        Colors.brown.shade400,
        Colors.brown.shade500,
      ],
    );

    canvas.drawPath(
      potPath,
      Paint()
        ..shader = potGradient.createShader(
          Rect.fromLTRB(
            centerX - potTopWidth / 2,
            potTop,
            centerX + potTopWidth / 2,
            potBottom,
          ),
        ),
    );

    // Pot rim
    final rimPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, potTop + 8),
            width: potTopWidth + 12,
            height: 16,
          ),
          const Radius.circular(3),
        ),
      );

    canvas.drawPath(rimPath, Paint()..color = Colors.brown.shade700);

    // Rim highlight
    canvas.drawLine(
      Offset(centerX - potTopWidth / 2 - 4, potTop + 4),
      Offset(centerX + potTopWidth / 2 + 4, potTop + 4),
      Paint()
        ..color = Colors.brown.shade300.withOpacity(0.5)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Soil in pot
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, potTop + 18),
        width: potTopWidth - 4,
        height: 14,
      ),
      Paint()..color = Colors.brown.shade800,
    );

    // Soil texture
    final soilDetailPaint = Paint()
      ..color = Colors.brown.shade900.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final dotX = centerX + (i - 2.5) * 10;
      final dotY = potTop + 16 + math.sin(i * 1.5) * 2;
      canvas.drawCircle(Offset(dotX, dotY), 1.5, soilDetailPaint);
    }

    // Decorative elements - small sprout trying to grow
    final sproutPhase = shimmerValue * math.pi * 2;
    final sproutHeight = 15 + math.sin(sproutPhase) * 3;

    // Tiny sprout
    final sproutPaint = Paint()
      ..color = Colors.green.shade400.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, potTop + 14),
      Offset(
        centerX + math.sin(sproutPhase * 0.5) * 2,
        potTop + 14 - sproutHeight,
      ),
      sproutPaint,
    );

    // Tiny leaves
    final leafPaint = Paint()
      ..color = Colors.green.shade400.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(
      centerX + math.sin(sproutPhase * 0.5) * 2,
      potTop + 14 - sproutHeight,
    );

    // Left leaf
    final leftLeaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-8, -4, -6, 4)
      ..quadraticBezierTo(-2, 2, 0, 0);
    canvas.drawPath(leftLeaf, leafPaint);

    // Right leaf
    final rightLeaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(8, -4, 6, 4)
      ..quadraticBezierTo(2, 2, 0, 0);
    canvas.drawPath(rightLeaf, leafPaint);

    canvas.restore();

    // Sparkle/shimmer effect indicating potential
    final shimmerPositions = [
      Offset(centerX - 25, potTop - 20),
      Offset(centerX + 20, potTop - 15),
      Offset(centerX - 15, potTop - 5),
      Offset(centerX + 30, potTop - 25),
    ];

    for (int i = 0; i < shimmerPositions.length; i++) {
      final phase = (shimmerValue + i * 0.25) % 1.0;
      final opacity = math.sin(phase * math.pi) * 0.6;

      if (opacity > 0) {
        _drawSparkle(
          canvas,
          shimmerPositions[i].dx,
          shimmerPositions[i].dy,
          4 + math.sin(phase * math.pi) * 2,
          opacity,
        );
      }
    }

    // Decorative pot pattern (simple lines)
    final patternPaint = Paint()
      ..color = Colors.brown.shade300.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Horizontal lines on pot
    for (int i = 1; i <= 2; i++) {
      final lineY = potTop + 15 + (potBottom - potTop - 15) * (i / 3);
      final lineWidth = potTopWidth - (potTopWidth - potBottomWidth) * (i / 3);

      canvas.drawLine(
        Offset(centerX - lineWidth / 2 + 5, lineY),
        Offset(centerX + lineWidth / 2 - 5, lineY),
        patternPaint,
      );
    }
  }

  void _drawSparkle(
    Canvas canvas,
    double x,
    double y,
    double size,
    double opacity,
  ) {
    final paint = Paint()
      ..color = Colors.yellow.shade200.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // Four-pointed star
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

  @override
  bool shouldRepaint(covariant EmptyPotPainter oldDelegate) =>
      oldDelegate.shimmerValue != shimmerValue;
}
