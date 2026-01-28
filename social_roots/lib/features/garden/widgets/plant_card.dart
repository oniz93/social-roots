import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../shared/widgets/animated_plant_widget.dart';
import '../../../data/models/plant.dart';

class PlantCard extends StatefulWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;

  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.onSwipeRight,
    this.onSwipeLeft,
  });

  @override
  State<PlantCard> createState() => _PlantCardState();
}

class _PlantCardState extends State<PlantCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return Dismissible(
      key: Key('plant_${plant.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onSwipeRight?.call();
        } else {
          widget.onSwipeLeft?.call();
        }
        return false;
      },
      background: _buildSwipeBackground(
        icon: Icons.water_drop,
        label: 'Quick Water',
        color: Colors.blue,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        icon: Icons.snooze,
        label: 'Snooze',
        color: Colors.orange,
        alignment: Alignment.centerRight,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getStateColor(plant.healthState).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Background gradient based on health
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _getCardGradient(plant.healthState),
                        ),
                      ),
                    ),
                  ),

                  // Decorative pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CardPatternPainter(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),

                  // Shimmer effect for thriving plants
                  if (plant.healthState == PlantHealthState.thriving)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: ShimmerPainter(
                              progress: _shimmerController.value,
                            ),
                          );
                        },
                      ),
                    ),

                  // Main content
                  Column(
                    children: [
                      // Plant visual area
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            // Plant illustration
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: _buildPlantVisual(),
                              ),
                            ),

                            // Health indicator badge
                            Positioned(
                              top: 10,
                              right: 10,
                              child: _buildHealthBadge(plant),
                            ),

                            // Snooze indicator
                            if (plant.snoozedUntil != null &&
                                DateTime.now().isBefore(plant.snoozedUntil!))
                              Positioned(
                                top: 10,
                                left: 10,
                                child: _buildSnoozeBadge(),
                              ),

                            // Water droplet indicator for thirsty plants
                            if (plant.healthState == PlantHealthState.thirsty ||
                                plant.healthState == PlantHealthState.wilting)
                              Positioned(
                                top: 45,
                                right: 15,
                                child: _buildThirstIndicator(),
                              ),
                          ],
                        ),
                      ),

                      // Name plate at bottom
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getSoilColor(
                                plant.currentHealth,
                              ).withOpacity(0.9),
                              _getSoilColor(plant.currentHealth),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Contact name
                            Text(
                              plant.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            // Plant type with icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getPlantTypeIcon(plant.plantType),
                                  size: 12,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  plant.plantType.displayName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required IconData icon,
    required String label,
    required Color color,
    required Alignment alignment,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.3)],
          begin: alignment == Alignment.centerLeft
              ? Alignment.centerRight
              : Alignment.centerLeft,
          end: alignment,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantVisual() {
    return SizedBox(
      width: 100,
      height: 100,
      child: AnimatedPlantWidget(
        plantType: widget.plant.plantType,
        health: widget.plant.currentHealth,
      ),
    );
  }

  Widget _buildHealthBadge(Plant plant) {
    final health = plant.currentHealth;
    final state = plant.healthState;
    final color = _getStateColor(state);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${health.round()}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnoozeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bedtime, size: 12, color: Colors.orange.shade700),
          const SizedBox(width: 4),
          Text(
            'Zzz',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThirstIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(value * math.pi * 2) * 3),
          child: Icon(
            Icons.water_drop,
            size: 18,
            color: Colors.blue.shade400.withOpacity(0.8),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  List<Color> _getCardGradient(PlantHealthState state) {
    switch (state) {
      case PlantHealthState.thriving:
        return [
          const Color(0xFFF1F8E9), // Light green tint
          const Color(0xFFE8F5E9),
          Colors.white,
        ];
      case PlantHealthState.thirsty:
        return [
          const Color(0xFFE3F2FD), // Light blue tint
          const Color(0xFFE8F4FC),
          Colors.white,
        ];
      case PlantHealthState.wilting:
        return [
          const Color(0xFFFFF8E1), // Light amber tint
          const Color(0xFFFFFDE7),
          Colors.white,
        ];
      case PlantHealthState.critical:
        return [
          const Color(0xFFFFEBEE), // Light red tint
          const Color(0xFFFFF5F5),
          Colors.white,
        ];
      case PlantHealthState.dormant:
        return [
          const Color(0xFFECEFF1), // Light grey tint
          const Color(0xFFFAFAFA),
          Colors.white,
        ];
    }
  }

  Color _getStateColor(PlantHealthState state) {
    switch (state) {
      case PlantHealthState.thriving:
        return const Color(0xFF43A047);
      case PlantHealthState.thirsty:
        return const Color(0xFF1E88E5);
      case PlantHealthState.wilting:
        return const Color(0xFFFB8C00);
      case PlantHealthState.critical:
        return const Color(0xFFE53935);
      case PlantHealthState.dormant:
        return const Color(0xFF757575);
    }
  }

  Color _getSoilColor(double health) {
    if (health >= 80) {
      return const Color(0xFF4E342E); // Rich dark brown
    } else if (health >= 60) {
      return const Color(0xFF5D4037); // Medium brown
    } else if (health >= 40) {
      return const Color(0xFF6D4C41); // Light brown
    } else {
      return const Color(0xFF8D6E63); // Pale brown
    }
  }

  IconData _getPlantTypeIcon(PlantType type) {
    switch (type) {
      case PlantType.cactus:
        return Icons.spa;
      case PlantType.snakePlant:
        return Icons.grass;
      case PlantType.succulent:
        return Icons.eco;
      case PlantType.monstera:
        return Icons.forest;
      case PlantType.sunflower:
        return Icons.wb_sunny;
      case PlantType.pothos:
        return Icons.nature;
      case PlantType.orchid:
        return Icons.local_florist;
      case PlantType.fern:
        return Icons.park;
      case PlantType.rose:
        return Icons.favorite;
    }
  }
}

class CardPatternPainter extends CustomPainter {
  final Color color;

  CardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw subtle diagonal lines
    for (double i = -size.height; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ShimmerPainter extends CustomPainter {
  final double progress;

  ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final shimmerWidth = size.width * 0.5;
    final shimmerPosition =
        -shimmerWidth + (size.width + shimmerWidth * 1.5) * progress;

    final paint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
          ).createShader(
            Rect.fromLTWH(shimmerPosition, 0, shimmerWidth, size.height),
          );

    canvas.save();
    // Skew the canvas to create a diagonal shimmer
    canvas.skew(-0.2, 0.0);

    // Draw the rect slightly larger to cover the skew
    canvas.drawRect(
      Rect.fromLTWH(
        shimmerPosition + size.height * 0.1,
        -10,
        shimmerWidth,
        size.height + 20,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
