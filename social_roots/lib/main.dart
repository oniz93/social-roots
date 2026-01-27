import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/models/plant.dart';
import 'data/models/interaction.dart';
import 'data/models/note.dart';
import 'core/services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar Database
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    PlantSchema,
    InteractionSchema,
    NoteSchema,
  ], directory: dir.path);

  runApp(
    ProviderScope(
      overrides: [
        // Provide Isar instance globally
        isarProvider.overrideWithValue(isar),
      ],
      child: const SocialRootsApp(),
    ),
  );
}
