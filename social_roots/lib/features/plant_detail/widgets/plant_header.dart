import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../../../shared/widgets/placeholder_plant_widget.dart';
import '../../../data/models/plant.dart';

class PlantHeader extends StatefulWidget {
  final Plant plant;

  const PlantHeader({super.key, required this.plant});

  @override
  State<PlantHeader> createState() => _PlantHeaderState();
}

class _PlantHeaderState extends State<PlantHeader>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  final List<BackgroundParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _generateParticles();
    _particleController.addListener(_updateParticles);
  }

  void _generateParticles() {
    final particleCount = widget.plant.currentHealth >= 60 ? 15 : 8;
    for (int i = 0; i < particleCount; i++) {
      _particles.add(
        BackgroundParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 2 + _random.nextDouble() * 4,
          speed: 0.0005 + _random.nextDouble() * 0.001,
          opacity: 0.2 + _random.nextDouble() * 0.4,
          wobblePhase: _random.nextDouble() * math.pi * 2,
          type: _getParticleType(),
        ),
      );
    }
  }

  ParticleType _getParticleType() {
    switch (widget.plant.healthState) {
      case PlantHealthState.thriving:
        return ParticleType.sparkle;
      case PlantHealthState.thirsty:
        return ParticleType.leaf;
      case PlantHealthState.wilting:
        return ParticleType.leaf;
      case PlantHealthState.critical:
        return ParticleType.petal;
      case PlantHealthState.dormant:
        return ParticleType.dust;
    }
  }

  void _updateParticles() {
    setState(() {
      for (final particle in _particles) {
        particle.y -= particle.speed;
        particle.wobblePhase += 0.02;
        particle.x += math.sin(particle.wobblePhase) * 0.001;

        if (particle.y < -0.1) {
          particle.y = 1.1;
          particle.x = _random.nextDouble();
        }
      }
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _getGradientColors(),
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: HeaderBackgroundPainter(
                health: widget.plant.currentHealth,
                animationValue: _shimmerController.value,
              ),
            ),
          ),

          // Floating particles
          Positioned.fill(
            child: CustomPaint(
              painter: ParticlesPainter(
                particles: _particles,
                healthState: widget.plant.healthState,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate sizes based on available height
                  final availableHeight = constraints.maxHeight;
                  final isCompact = availableHeight < 320;
                  final plantSize = isCompact ? 100.0 : 120.0;
                  final ringSize = isCompact ? 140.0 : 160.0;
                  final titleFontSize = isCompact ? 20.0 : 24.0;
                  final topSpace = isCompact ? 32.0 : 40.0;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: topSpace), // Space for app bar
                      // Health ring around plant
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulseScale = widget.plant.currentHealth >= 80
                              ? 1.0 + _pulseController.value * 0.05
                              : 1.0;

                          return Transform.scale(
                            scale: pulseScale,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glowing health ring
                                CustomPaint(
                                  size: Size(ringSize, ringSize),
                                  painter: HealthRingPainter(
                                    health: widget.plant.currentHealth,
                                    healthState: widget.plant.healthState,
                                    pulseValue: _pulseController.value,
                                  ),
                                ),
                                // Plant
                                SizedBox(
                                  width: plantSize,
                                  height: plantSize,
                                  child: AnimatedPlaceholderPlant(
                                    plantType: widget.plant.plantType,
                                    health: widget.plant.currentHealth,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 8),

                      // Plant name with shadow
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.8),
                                Colors.white,
                              ],
                              stops: [
                                (_shimmerController.value - 0.3).clamp(0, 1),
                                _shimmerController.value.clamp(0, 1),
                                (_shimmerController.value + 0.3).clamp(0, 1),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              widget.plant.displayName,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 4),

                      // Plant type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPlantTypeIcon(),
                              size: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.plant.plantType.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Stats row
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildStatChip(
                            icon: Icons.favorite,
                            label: '${widget.plant.currentHealth.toInt()}%',
                            color: _getHealthColor(),
                          ),
                          _buildStatChip(
                            icon: Icons.calendar_today,
                            label: DateFormat.MMMd().format(
                              widget.plant.plantedDate,
                            ),
                            color: Colors.white.withOpacity(0.8),
                          ),
                          if (widget.plant.snoozedUntil != null)
                            _buildStatChip(
                              icon: Icons.pause_circle_outline,
                              label: 'Snoozed',
                              color: Colors.blue.shade200,
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPlantTypeIcon() {
    switch (widget.plant.plantType) {
      case PlantType.cactus:
        return Icons.grass;
      case PlantType.snakePlant:
        return Icons.straighten;
      case PlantType.succulent:
        return Icons.local_florist;
      case PlantType.monstera:
        return Icons.eco;
      case PlantType.sunflower:
        return Icons.wb_sunny;
      case PlantType.pothos:
        return Icons.nature;
      case PlantType.orchid:
        return Icons.filter_vintage;
      case PlantType.fern:
        return Icons.spa;
      case PlantType.rose:
        return Icons.local_florist;
    }
  }

  Color _getHealthColor() {
    switch (widget.plant.healthState) {
      case PlantHealthState.thriving:
        return Colors.green.shade300;
      case PlantHealthState.thirsty:
        return Colors.yellow.shade300;
      case PlantHealthState.wilting:
        return Colors.orange.shade300;
      case PlantHealthState.critical:
        return Colors.red.shade300;
      case PlantHealthState.dormant:
        return Colors.grey.shade400;
    }
  }

  List<Color> _getGradientColors() {
    switch (widget.plant.healthState) {
      case PlantHealthState.thriving:
        return [
          Colors.green.shade300,
          Colors.green.shade500,
          Colors.green.shade700,
        ];
      case PlantHealthState.thirsty:
        return [
          Colors.green.shade200,
          Colors.green.shade400,
          Colors.green.shade600,
        ];
      case PlantHealthState.wilting:
        return [
          Colors.orange.shade200,
          Colors.orange.shade400,
          Colors.orange.shade600,
        ];
      case PlantHealthState.critical:
        return [Colors.red.shade200, Colors.red.shade400, Colors.red.shade600];
      case PlantHealthState.dormant:
        return [
          Colors.grey.shade300,
          Colors.grey.shade500,
          Colors.grey.shade600,
        ];
    }
  }
}

enum ParticleType { sparkle, leaf, petal, dust }

class BackgroundParticle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double wobblePhase;
  ParticleType type;

  BackgroundParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.wobblePhase,
    required this.type,
  });
}

class HeaderBackgroundPainter extends CustomPainter {
  final double health;
  final double animationValue;

  HeaderBackgroundPainter({required this.health, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle wave pattern at the bottom
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    for (int layer = 0; layer < 3; layer++) {
      final path = Path();
      final waveHeight = 20 + layer * 10.0;
      final waveOffset = animationValue * math.pi * 2 + layer * 0.5;

      path.moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 10) {
        final y =
            size.height -
            waveHeight +
            math.sin(x / 50 + waveOffset) * (10 + layer * 5);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();

      canvas.drawPath(path, wavePaint);
    }

    // Decorative circles in corners
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(-size.width * 0.2, -size.height * 0.1),
      size.width * 0.5,
      circlePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 1.1, size.height * 0.3),
      size.width * 0.4,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant HeaderBackgroundPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class ParticlesPainter extends CustomPainter {
  final List<BackgroundParticle> particles;
  final PlantHealthState healthState;

  ParticlesPainter({required this.particles, required this.healthState});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = particle.x * size.width;
      final y = particle.y * size.height;

      switch (particle.type) {
        case ParticleType.sparkle:
          _drawSparkle(canvas, x, y, particle.size, particle.opacity);
          break;
        case ParticleType.leaf:
          _drawLeaf(
            canvas,
            x,
            y,
            particle.size,
            particle.opacity,
            particle.wobblePhase,
          );
          break;
        case ParticleType.petal:
          _drawPetal(
            canvas,
            x,
            y,
            particle.size,
            particle.opacity,
            particle.wobblePhase,
          );
          break;
        case ParticleType.dust:
          _drawDust(canvas, x, y, particle.size, particle.opacity);
          break;
      }
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
      ..color = Colors.yellow.shade100.withOpacity(opacity)
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

  void _drawLeaf(
    Canvas canvas,
    double x,
    double y,
    double size,
    double opacity,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);

    final paint = Paint()
      ..color = Colors.green.shade300.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, -size)
      ..quadraticBezierTo(size * 0.8, 0, 0, size)
      ..quadraticBezierTo(-size * 0.8, 0, 0, -size);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawPetal(
    Canvas canvas,
    double x,
    double y,
    double size,
    double opacity,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);

    final paint = Paint()
      ..color = Colors.red.shade200.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, -size)
      ..quadraticBezierTo(size * 0.6, -size * 0.3, 0, size * 0.5)
      ..quadraticBezierTo(-size * 0.6, -size * 0.3, 0, -size);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawDust(
    Canvas canvas,
    double x,
    double y,
    double size,
    double opacity,
  ) {
    final paint = Paint()
      ..color = Colors.grey.shade300.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), size * 0.5, paint);
  }

  @override
  bool shouldRepaint(covariant ParticlesPainter oldDelegate) => true;
}

class HealthRingPainter extends CustomPainter {
  final double health;
  final PlantHealthState healthState;
  final double pulseValue;

  HealthRingPainter({
    required this.health,
    required this.healthState,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Health arc
    final healthAngle = (health / 100) * math.pi * 2;
    final healthPaint = Paint()
      ..color = _getHealthColor().withOpacity(0.8 + pulseValue * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      healthAngle,
      false,
      healthPaint,
    );

    // Glow effect for thriving plants
    if (health >= 80) {
      final glowPaint = Paint()
        ..color = _getHealthColor().withOpacity(0.3 * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        healthAngle,
        false,
        glowPaint,
      );
    }

    // Dot at the end of the arc
    final dotAngle = -math.pi / 2 + healthAngle;
    final dotX = center.dx + math.cos(dotAngle) * radius;
    final dotY = center.dy + math.sin(dotAngle) * radius;

    canvas.drawCircle(Offset(dotX, dotY), 5, Paint()..color = Colors.white);
  }

  Color _getHealthColor() {
    switch (healthState) {
      case PlantHealthState.thriving:
        return Colors.green.shade400;
      case PlantHealthState.thirsty:
        return Colors.yellow.shade400;
      case PlantHealthState.wilting:
        return Colors.orange.shade400;
      case PlantHealthState.critical:
        return Colors.red.shade400;
      case PlantHealthState.dormant:
        return Colors.grey.shade400;
    }
  }

  @override
  bool shouldRepaint(covariant HealthRingPainter oldDelegate) =>
      oldDelegate.health != health || oldDelegate.pulseValue != pulseValue;
}
