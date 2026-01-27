import 'package:isar/isar.dart';

part 'note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;

  @Index()
  late int plantId; // Foreign key to Plant

  late DateTime createdAt;
  late DateTime updatedAt;

  late String content; // The actual note text

  // Quick tags
  List<String> tags = [];

  // Reminder functionality
  DateTime? reminderDate;
  bool reminderCompleted = false;
  String? reminderMessage; // Custom notification text
}

// Predefined tags for quick selection
class NoteTags {
  static const String birthday = 'Birthday';
  static const String giftIdea = 'Gift Idea';
  static const String work = 'Work';
  static const String family = 'Family';
  static const String health = 'Health';
  static const String travel = 'Travel';
  static const String hobby = 'Hobby';
  static const String important = 'Important';

  static List<String> get all => [
    birthday,
    giftIdea,
    work,
    family,
    health,
    travel,
    hobby,
    important,
  ];
}
