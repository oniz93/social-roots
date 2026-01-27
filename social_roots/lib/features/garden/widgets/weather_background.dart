import 'package:flutter/material.dart';

class WeatherBackground extends StatelessWidget {
  final double healthPercentage;

  const WeatherBackground({super.key, required this.healthPercentage});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(gradient: _getGradient()),
      child: Stack(
        children: [
          // Weather effects
          if (healthPercentage < 50) _buildRainEffect(),
          if (healthPercentage >= 80) _buildSunEffect(),
        ],
      ),
    );
  }

  LinearGradient _getGradient() {
    if (healthPercentage >= 80) {
      // Sunny day
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF87CEEB), // Sky blue
          Color(0xFF98FB98), // Pale green
          Color(0xFF90EE90), // Light green (grass)
        ],
        stops: [0.0, 0.6, 1.0],
      );
    } else if (healthPercentage >= 50) {
      // Partly cloudy
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFB0C4DE), // Light steel blue
          Color(0xFFA8C8A8), // Sage green
          Color(0xFF8FBC8F), // Dark sea green
        ],
        stops: [0.0, 0.6, 1.0],
      );
    } else {
      // Overcast/Rainy
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF696969), // Dim gray
          Color(0xFF808080), // Gray
          Color(0xFF6B8E6B), // Muted green
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
  }

  Widget _buildSunEffect() {
    return Positioned(
      top: 60,
      right: 40,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.yellow.shade300,
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.shade200.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRainEffect() {
    // Simple rain overlay
    return Positioned.fill(child: CustomPaint(painter: RainPainter()));
  }
}

class RainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw simple rain lines
    for (int i = 0; i < 50; i++) {
      final x = (i * 20.0) % size.width;
      final y1 = (i * 15.0) % size.height;
      final y2 = y1 + 20;

      canvas.drawLine(Offset(x, y1), Offset(x - 5, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
