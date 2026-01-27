import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/services/database_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_task_service.dart';
import 'data/models/plant.dart';
import 'data/models/interaction.dart';
import 'data/models/note.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Isar Database
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [PlantSchema, InteractionSchema, NoteSchema],
    directory: dir.path,
  );
  
  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.init();
  
  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const SocialRootsApp(),
    ),
  );
}