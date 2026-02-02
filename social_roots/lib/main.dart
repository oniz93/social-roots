import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/services/database_service.dart';
import 'core/services/notification_service.dart';
import 'data/models/plant.dart';
import 'data/models/interaction.dart';
import 'data/models/note.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppStartupWidget());
}

class AppStartupWidget extends StatefulWidget {
  const AppStartupWidget({super.key});

  @override
  State<AppStartupWidget> createState() => _AppStartupWidgetState();
}

class _AppStartupWidgetState extends State<AppStartupWidget> {
  Isar? _isar;
  NotificationService? _notificationService;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Set preferred orientation
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Initialize Isar Database
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open([
        PlantSchema,
        InteractionSchema,
        NoteSchema,
      ], directory: dir.path);

      // Initialize notifications
      _notificationService = NotificationService();
      await _notificationService!.init();

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Initialization failed: $e');
      // In a real app, you might want to show an error screen here
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(
              color: Colors.green,
            ),
          ),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(_isar!),
        notificationServiceProvider.overrideWithValue(_notificationService!),
      ],
      child: const SocialRootsApp(),
    );
  }
}
