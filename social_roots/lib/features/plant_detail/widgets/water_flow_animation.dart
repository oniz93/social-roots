import 'package:flutter/material.dart';
import 'dart:math';

import '../../../data/models/interaction.dart';

class WaterFlowAnimation extends StatefulWidget {
  final InteractionType type;
  final VoidCallback? onComplete;
  
  const WaterFlowAnimation({
    super.key,
    required this.type,
    this.onComplete,
  });
  
  @override
  State<WaterFlowAnimation> createState() => _WaterFlowAnimationState();
}

class _WaterFlowAnimationState extends State<WaterFlowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dropAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: _getDuration()),
      vsync: this,
    );
    
    _dropAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }
  
  int _getDuration() {
    switch (widget.type) {
      case InteractionType.quickText:
        return 500;
      case InteractionType.phoneCall:
        return 800;
      case InteractionType.meetup:
        return 1200;
    }
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
        return Stack(
          alignment: Alignment.center,
          children: [
            // Water drops
            ..._buildWaterDrops(),
            
            // Central icon
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(),
                  size: 40,
                  color: Colors.blue,
                ),
              ),
            ),
            
            // Sparkles for meetup
            if (widget.type == InteractionType.meetup)
              ..._buildSparkles(),
          ],
        );
      },
    );
  }
  
  IconData _getIcon() {
    switch (widget.type) {
      case InteractionType.quickText:
        return Icons.water_drop;
      case InteractionType.phoneCall:
        return Icons.local_cafe;
      case InteractionType.meetup:
        return Icons.celebration;
    }
  }
  
  List<Widget> _buildWaterDrops() {
    final dropCount = widget.type == InteractionType.meetup ? 8 : 4;
    return List.generate(dropCount, (index) {
      final angle = (index / dropCount) * 2 * 3.14159;
      final distance = 60 * _dropAnimation.value;
      
      return Positioned(
        left: 50 + distance * cos(angle) - 10,
        top: 50 + distance * sin(angle) - 10,
        child: Opacity(
          opacity: 1 - _dropAnimation.value,
          child: Icon(
            Icons.water_drop,
            size: 20,
            color: Colors.blue.shade300,
          ),
        ),
      );
    });
  }
  
  List<Widget> _buildSparkles() {
    return List.generate(6, (index) {
      final angle = (index / 6) * 2 * 3.14159 + 0.5;
      final distance = 80 * _dropAnimation.value;
      
      return Positioned(
        left: 50 + distance * cos(angle) - 8,
        top: 50 + distance * sin(angle) - 8,
        child: Opacity(
          opacity: 1 - _dropAnimation.value,
          child: Icon(
            Icons.star,
            size: 16,
            color: Colors.yellow.shade600,
          ),
        ),
      );
    });
  }
}
