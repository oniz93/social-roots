import 'package:flutter/material.dart';
import 'dart:math' as math;

class WeatherBackground extends StatefulWidget {
  final double healthPercentage;

  const WeatherBackground({super.key, required this.healthPercentage});

  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground>
    with TickerProviderStateMixin {
  late AnimationController _rainController;
  late AnimationController _sunController;
  late AnimationController _cloudController;

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _sunController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _cloudController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rainController.dispose();
    _sunController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(gradient: _getGradient()),
      child: Stack(
        children: [
          // Decorative grass at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 100),
              painter: GrassPainter(health: widget.healthPercentage),
            ),
          ),

          // Clouds for partly cloudy weather
          if (widget.healthPercentage >= 50 && widget.healthPercentage < 80)
            AnimatedBuilder(
              animation: _cloudController,
              builder: (context, child) => _buildClouds(),
            ),

          // Rain for low health
          if (widget.healthPercentage < 50)
            AnimatedBuilder(
              animation: _rainController,
              builder: (context, child) => CustomPaint(
                size: Size.infinite,
                painter: AnimatedRainPainter(
                  animationValue: _rainController.value,
                  intensity: (50 - widget.healthPercentage) / 50,
                ),
              ),
            ),

          // Storm clouds for very low health
          if (widget.healthPercentage < 30) _buildStormClouds(),

          // Sun for healthy garden
          if (widget.healthPercentage >= 80)
            AnimatedBuilder(
              animation: _sunController,
              builder: (context, child) => _buildAnimatedSun(),
            ),

          // Birds for very healthy garden
          if (widget.healthPercentage >= 90)
            AnimatedBuilder(
              animation: _cloudController,
              builder: (context, child) => _buildBirds(),
            ),
        ],
      ),
    );
  }

  LinearGradient _getGradient() {
    if (widget.healthPercentage >= 80) {
      // Beautiful sunny day
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF64B5F6), // Bright sky blue
          Color(0xFF81D4FA), // Light sky blue
          Color(0xFFB2DFDB), // Pale teal
          Color(0xFF81C784), // Light green
          Color(0xFF66BB6A), // Medium green
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      );
    } else if (widget.healthPercentage >= 50) {
      // Partly cloudy
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF90A4AE), // Blue grey
          Color(0xFFB0BEC5), // Light blue grey
          Color(0xFFA5D6A7), // Light green
          Color(0xFF81C784), // Medium green
        ],
        stops: [0.0, 0.4, 0.7, 1.0],
      );
    } else if (widget.healthPercentage >= 30) {
      // Overcast
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF78909C), // Blue grey 400
          Color(0xFF90A4AE), // Blue grey 300
          Color(0xFF8D9E88), // Muted sage
          Color(0xFF6B7B6A), // Dark sage
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      );
    } else {
      // Stormy
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF455A64), // Blue grey 700
          Color(0xFF546E7A), // Blue grey 600
          Color(0xFF607D8B), // Blue grey 500
          Color(0xFF5D6D5E), // Dark muted green
        ],
        stops: [0.0, 0.3, 0.6, 1.0],
      );
    }
  }

  Widget _buildAnimatedSun() {
    return Positioned(
      top: 50,
      right: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sun rays (rotating)
          Transform.rotate(
            angle: _sunController.value * 2 * math.pi,
            child: CustomPaint(
              size: const Size(120, 120),
              painter: SunRaysPainter(),
            ),
          ),
          // Pulsing glow
          Container(
            width: 70 + math.sin(_sunController.value * 2 * math.pi) * 5,
            height: 70 + math.sin(_sunController.value * 2 * math.pi) * 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.yellow.shade200,
                  Colors.yellow.shade300.withValues(alpha: 0.5),
                  Colors.orange.shade200.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
                stops: const [0.4, 0.6, 0.8, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.shade300.withValues(alpha: 0.6),
                  blurRadius: 40,
                  spreadRadius: 15,
                ),
                BoxShadow(
                  color: Colors.orange.shade200.withValues(alpha: 0.3),
                  blurRadius: 60,
                  spreadRadius: 25,
                ),
              ],
            ),
          ),
          // Sun face
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.yellow.shade100, Colors.yellow.shade400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClouds() {
    return Stack(
      children: [
        Positioned(
          top: 80,
          left: -50 + (_cloudController.value * 400),
          child: _buildCloud(60, 0.6),
        ),
        Positioned(
          top: 120,
          right: -30 + ((1 - _cloudController.value) * 350),
          child: _buildCloud(50, 0.5),
        ),
        Positioned(
          top: 60,
          left: 100 + (_cloudController.value * 200),
          child: _buildCloud(40, 0.4),
        ),
      ],
    );
  }

  Widget _buildCloud(double size, double opacity) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: size * 2,
        height: size,
        child: CustomPaint(painter: CloudPainter()),
      ),
    );
  }

  Widget _buildStormClouds() {
    return Stack(
      children: [
        Positioned(top: 30, left: 20, child: _buildDarkCloud(100)),
        Positioned(top: 50, right: 40, child: _buildDarkCloud(80)),
        Positioned(
          top: 40,
          left: MediaQuery.of(context).size.width / 3,
          child: _buildDarkCloud(90),
        ),
      ],
    );
  }

  Widget _buildDarkCloud(double size) {
    return SizedBox(
      width: size * 2,
      height: size,
      child: CustomPaint(painter: StormCloudPainter()),
    );
  }

  Widget _buildBirds() {
    final offset = _cloudController.value * MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Positioned(
          top: 100,
          left: offset % MediaQuery.of(context).size.width,
          child: const _Bird(),
        ),
        Positioned(
          top: 130,
          left: (offset + 50) % MediaQuery.of(context).size.width,
          child: const _Bird(size: 12),
        ),
        Positioned(
          top: 90,
          left: (offset + 80) % MediaQuery.of(context).size.width,
          child: const _Bird(size: 10),
        ),
      ],
    );
  }
}

class _Bird extends StatelessWidget {
  final double size;
  const _Bird({this.size = 15});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size * 2, size), painter: BirdPainter());
  }
}

class BirdPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.25,
        0,
        size.width * 0.5,
        size.height * 0.3,
      )
      ..quadraticBezierTo(size.width * 0.75, 0, size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SunRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.yellow.shade300.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final innerRadius = 35.0;
      final outerRadius = 55.0;

      final start = Offset(
        center.dx + math.cos(angle) * innerRadius,
        center.dy + math.sin(angle) * innerRadius,
      );
      final end = Offset(
        center.dx + math.cos(angle) * outerRadius,
        center.dy + math.sin(angle) * outerRadius,
      );

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.addOval(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.4,
        size.width * 0.35,
        size.height * 0.5,
      ),
    );
    path.addOval(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.15,
        size.width * 0.4,
        size.height * 0.6,
      ),
    );
    path.addOval(
      Rect.fromLTWH(
        size.width * 0.5,
        size.height * 0.3,
        size.width * 0.4,
        size.height * 0.55,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StormCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.grey.shade600, Colors.grey.shade800],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.addOval(
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.35,
        size.width * 0.4,
        size.height * 0.55,
      ),
    );
    path.addOval(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.1,
        size.width * 0.45,
        size.height * 0.65,
      ),
    );
    path.addOval(
      Rect.fromLTWH(
        size.width * 0.45,
        size.height * 0.25,
        size.width * 0.45,
        size.height * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnimatedRainPainter extends CustomPainter {
  final double animationValue;
  final double intensity;

  AnimatedRainPainter({required this.animationValue, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final dropCount = (80 * intensity).toInt() + 20;
    final random = math.Random(42);

    for (int i = 0; i < dropCount; i++) {
      final baseX = random.nextDouble() * size.width;
      final speed = 0.5 + random.nextDouble() * 0.5;
      final length = 15.0 + random.nextDouble() * 20.0;
      final opacity = 0.2 + random.nextDouble() * 0.3;

      final y =
          ((animationValue * speed + i / dropCount) % 1.0) *
          (size.height + length);
      final x = baseX - (y * 0.1);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x, y), Offset(x - 3, y + length), paint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedRainPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.intensity != intensity;
  }
}

class GrassPainter extends CustomPainter {
  final double health;

  GrassPainter({required this.health});

  @override
  void paint(Canvas canvas, Size size) {
    final grassColor = Color.lerp(
      const Color(0xFF5D4037), // Brown (unhealthy)
      const Color(0xFF4CAF50), // Green (healthy)
      health / 100,
    )!;

    final paint = Paint()
      ..color = grassColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    // Create wavy grass line
    for (double x = 0; x <= size.width; x += 20) {
      final y =
          size.height - 20 - math.sin(x * 0.05) * 10 - (health / 100) * 30;
      if (x == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw grass blades for healthy gardens
    if (health > 60) {
      final bladePaint = Paint()
        ..color = grassColor.withValues(alpha: 0.4)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final random = math.Random(42);
      final bladeCount = (health / 2).toInt();

      for (int i = 0; i < bladeCount; i++) {
        final x = random.nextDouble() * size.width;
        final baseY = size.height - 10;
        final height = 15 + random.nextDouble() * 20;
        final curve = random.nextDouble() * 10 - 5;

        final bladePath = Path()
          ..moveTo(x, baseY)
          ..quadraticBezierTo(
            x + curve,
            baseY - height / 2,
            x + curve * 0.5,
            baseY - height,
          );

        canvas.drawPath(bladePath, bladePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GrassPainter oldDelegate) {
    return oldDelegate.health != health;
  }
}
