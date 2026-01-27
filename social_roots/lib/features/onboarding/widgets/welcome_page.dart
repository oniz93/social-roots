import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../providers/onboarding_provider.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _leafController;
  late AnimationController _pulseController;
  late AnimationController _growController;
  final List<FloatingLeaf> _leaves = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _leafController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _growController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    // Generate floating leaves
    for (int i = 0; i < 12; i++) {
      _leaves.add(
        FloatingLeaf(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 8 + _random.nextDouble() * 12,
          speed: 0.0008 + _random.nextDouble() * 0.0012,
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: 0.01 + _random.nextDouble() * 0.02,
          wobblePhase: _random.nextDouble() * math.pi * 2,
          color: [
            Colors.green.shade300,
            Colors.green.shade400,
            Colors.green.shade500,
            Colors.teal.shade300,
          ][_random.nextInt(4)],
        ),
      );
    }

    _leafController.addListener(_updateLeaves);
  }

  void _updateLeaves() {
    setState(() {
      for (final leaf in _leaves) {
        leaf.y -= leaf.speed;
        leaf.rotation += leaf.rotationSpeed;
        leaf.wobblePhase += 0.02;
        leaf.x += math.sin(leaf.wobblePhase) * 0.001;

        if (leaf.y < -0.15) {
          leaf.y = 1.15;
          leaf.x = _random.nextDouble();
        }
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _leafController.dispose();
    _pulseController.dispose();
    _growController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade200,
            Colors.green.shade400,
            Colors.green.shade600,
            Colors.green.shade700,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundCirclesPainter(
                animationValue: _floatController.value,
              ),
            ),
          ),

          // Floating leaves
          Positioned.fill(
            child: CustomPaint(painter: FloatingLeavesPainter(leaves: _leaves)),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Animated logo with growing plant
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
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale =
                            1.0 +
                            math.sin(_pulseController.value * math.pi) * 0.03;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.shade900.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: AnimatedBuilder(
                              animation: _growController,
                              builder: (context, _) {
                                return CustomPaint(
                                  painter: LogoPlantPainter(
                                    growthProgress: _growController.value,
                                    pulseValue: _pulseController.value,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Title with shimmer effect
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.green.shade100,
                            Colors.white,
                          ],
                          stops: [
                            (_pulseController.value - 0.3).clamp(0, 1),
                            _pulseController.value.clamp(0, 1),
                            (_pulseController.value + 0.3).clamp(0, 1),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'Social Roots',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Tagline with fade-in animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          'Nurture your relationships',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.95),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'like a garden',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Feature hints
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(opacity: value, child: child);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFeatureHint(Icons.people, 'Connect'),
                          _buildFeatureHint(Icons.water_drop, 'Nurture'),
                          _buildFeatureHint(Icons.eco, 'Grow'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Get Started Button with animation
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale =
                          1.0 +
                          math.sin(_pulseController.value * math.pi * 2) * 0.02;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade900.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(onboardingProvider.notifier).nextStep();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green.shade700,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.green.shade700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHint(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class FloatingLeaf {
  double x;
  double y;
  double size;
  double speed;
  double rotation;
  double rotationSpeed;
  double wobblePhase;
  Color color;

  FloatingLeaf({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
    required this.wobblePhase,
    required this.color,
  });
}

class FloatingLeavesPainter extends CustomPainter {
  final List<FloatingLeaf> leaves;

  FloatingLeavesPainter({required this.leaves});

  @override
  void paint(Canvas canvas, Size size) {
    for (final leaf in leaves) {
      canvas.save();
      canvas.translate(leaf.x * size.width, leaf.y * size.height);
      canvas.rotate(leaf.rotation);

      final paint = Paint()
        ..color = leaf.color.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      // Draw leaf shape
      final path = Path()
        ..moveTo(0, -leaf.size)
        ..quadraticBezierTo(
          leaf.size * 0.8,
          -leaf.size * 0.3,
          leaf.size * 0.3,
          leaf.size * 0.5,
        )
        ..quadraticBezierTo(
          0,
          leaf.size * 0.8,
          -leaf.size * 0.3,
          leaf.size * 0.5,
        )
        ..quadraticBezierTo(-leaf.size * 0.8, -leaf.size * 0.3, 0, -leaf.size);

      canvas.drawPath(path, paint);

      // Leaf vein
      final veinPaint = Paint()
        ..color = leaf.color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      canvas.drawLine(
        Offset(0, -leaf.size * 0.8),
        Offset(0, leaf.size * 0.5),
        veinPaint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant FloatingLeavesPainter oldDelegate) => true;
}

class BackgroundCirclesPainter extends CustomPainter {
  final double animationValue;

  BackgroundCirclesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Large decorative circles
    final circles = [
      Offset(-size.width * 0.3, size.height * 0.1),
      Offset(size.width * 1.2, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 1.1),
    ];

    final radii = [size.width * 0.5, size.width * 0.4, size.width * 0.6];

    for (int i = 0; i < circles.length; i++) {
      final offset = math.sin(animationValue * math.pi + i) * 10;
      canvas.drawCircle(
        circles[i] + Offset(offset, offset),
        radii[i],
        circlePaint,
      );
    }

    // Concentric rings at the top
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int r = 1; r <= 5; r++) {
      canvas.drawCircle(
        Offset(size.width * 0.5, -size.height * 0.2),
        size.width * 0.3 * r,
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundCirclesPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class LogoPlantPainter extends CustomPainter {
  final double growthProgress;
  final double pulseValue;

  LogoPlantPainter({required this.growthProgress, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw pot
    _drawPot(canvas, size, centerX, centerY);

    // Draw growing plant
    if (growthProgress > 0) {
      _drawPlant(canvas, size, centerX, centerY);
    }
  }

  void _drawPot(Canvas canvas, Size size, double centerX, double centerY) {
    final potTop = centerY + 10;
    final potBottom = centerY + 35;
    final potTopWidth = 45.0;
    final potBottomWidth = 35.0;

    // Pot body
    final potPath = Path()
      ..moveTo(centerX - potTopWidth / 2, potTop + 5)
      ..lineTo(centerX - potBottomWidth / 2, potBottom)
      ..lineTo(centerX + potBottomWidth / 2, potBottom)
      ..lineTo(centerX + potTopWidth / 2, potTop + 5)
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, potTop + 3),
          width: potTopWidth + 8,
          height: 8,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.brown.shade700,
    );

    // Soil
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, potTop + 8),
        width: potTopWidth - 4,
        height: 8,
      ),
      Paint()..color = Colors.brown.shade800,
    );
  }

  void _drawPlant(Canvas canvas, Size size, double centerX, double centerY) {
    final stemHeight = 50 * growthProgress;
    final potTop = centerY + 10;

    // Main stem
    final stemPaint = Paint()
      ..color = Colors.green.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final swayOffset = math.sin(pulseValue * math.pi * 2) * 2;

    canvas.drawLine(
      Offset(centerX, potTop + 5),
      Offset(centerX + swayOffset, potTop + 5 - stemHeight),
      stemPaint,
    );

    // Leaves
    if (growthProgress > 0.3) {
      final leafProgress = ((growthProgress - 0.3) / 0.7).clamp(0.0, 1.0);

      // Left leaf
      _drawLeaf(
        canvas,
        centerX + swayOffset * 0.5 - 5,
        potTop + 5 - stemHeight * 0.5,
        20 * leafProgress,
        -0.5 + swayOffset * 0.02,
      );

      // Right leaf
      if (growthProgress > 0.5) {
        final rightProgress = ((growthProgress - 0.5) / 0.5).clamp(0.0, 1.0);
        _drawLeaf(
          canvas,
          centerX + swayOffset * 0.7 + 5,
          potTop + 5 - stemHeight * 0.7,
          18 * rightProgress,
          0.5 + swayOffset * 0.02,
        );
      }

      // Top leaves
      if (growthProgress > 0.7) {
        final topProgress = ((growthProgress - 0.7) / 0.3).clamp(0.0, 1.0);
        _drawLeaf(
          canvas,
          centerX + swayOffset - 3,
          potTop + 5 - stemHeight + 5,
          15 * topProgress,
          -0.3 + swayOffset * 0.03,
        );
        _drawLeaf(
          canvas,
          centerX + swayOffset + 3,
          potTop + 5 - stemHeight + 5,
          15 * topProgress,
          0.3 + swayOffset * 0.03,
        );
      }
    }
  }

  void _drawLeaf(
    Canvas canvas,
    double x,
    double y,
    double size,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);

    final leafGradient = RadialGradient(
      center: const Alignment(0, -0.3),
      radius: 1,
      colors: [Colors.green.shade500, Colors.green.shade700],
    );

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-size * 0.5, -size * 0.3, 0, -size)
      ..quadraticBezierTo(size * 0.5, -size * 0.3, 0, 0);

    canvas.drawPath(
      path,
      Paint()
        ..shader = leafGradient.createShader(
          Rect.fromLTRB(-size, -size, size, 0),
        ),
    );

    // Leaf vein
    canvas.drawLine(
      const Offset(0, -2),
      Offset(0, -size * 0.8),
      Paint()
        ..color = Colors.green.shade800.withOpacity(0.5)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LogoPlantPainter oldDelegate) =>
      oldDelegate.growthProgress != growthProgress ||
      oldDelegate.pulseValue != pulseValue;
}
