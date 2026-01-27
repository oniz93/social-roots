import 'package:flutter/services.dart';
import '../../data/models/interaction.dart';

class HapticService {
  /// Light haptic for quick text
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }
  
  /// Medium haptic for phone call
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
  
  /// Heavy haptic for meetup/revival
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
  
  /// Selection click
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
  
  /// Success pattern (for revival)
  static Future<void> successPattern() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.lightImpact();
  }
  
  /// Water flow simulation (rapid light taps)
  static Future<void> waterFlow({int duration = 1000}) async {
    final iterations = duration ~/ 50;
    for (int i = 0; i < iterations; i++) {
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
  
  /// Get haptic for interaction type
  static void forInteractionType(InteractionType type) {
    switch (type) {
      case InteractionType.quickText:
        lightImpact();
        break;
      case InteractionType.phoneCall:
        mediumImpact();
        break;
      case InteractionType.meetup:
        heavyImpact();
        break;
    }
  }
}
