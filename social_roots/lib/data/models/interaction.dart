import 'package:isar/isar.dart';

part 'interaction.g.dart';

@collection
class Interaction {
  Id id = Isar.autoIncrement;

  @Index()
  late int plantId; // Foreign key to Plant

  late DateTime timestamp;

  @Enumerated(EnumType.name)
  late InteractionType type;

  String? summary; // Optional user notes about the interaction

  // For linking to specific notes if relevant
  int? linkedNoteId;
}

enum InteractionType {
  quickText, // Drop - 20% boost
  phoneCall, // Cup - 50% boost
  meetup, // Watering Can - 100% boost
}

extension InteractionTypeExtension on InteractionType {
  String get displayName {
    switch (this) {
      case InteractionType.quickText:
        return 'Quick Text';
      case InteractionType.phoneCall:
        return 'Phone Call';
      case InteractionType.meetup:
        return 'Hangout';
    }
  }

  String get icon {
    switch (this) {
      case InteractionType.quickText:
        return 'assets/images/drop.png';
      case InteractionType.phoneCall:
        return 'assets/images/cup.png';
      case InteractionType.meetup:
        return 'assets/images/watering_can.png';
    }
  }

  double get healthBoost {
    switch (this) {
      case InteractionType.quickText:
        return 20.0;
      case InteractionType.phoneCall:
        return 50.0;
      case InteractionType.meetup:
        return 100.0;
    }
  }

  String get description {
    switch (this) {
      case InteractionType.quickText:
        return 'Text, meme, or quick message';
      case InteractionType.phoneCall:
        return 'Voice or video call';
      case InteractionType.meetup:
        return 'In-person hangout or meal';
    }
  }
}
