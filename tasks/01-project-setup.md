# Task 01: Flutter Project Setup

## Priority: HIGH
## Estimated Time: 2-3 hours
## Platform Focus: iOS First

---

## Objective
Initialize the Flutter project with all required dependencies and configure the project structure for the Social Roots app.

---

## Context
Social Roots is a personal CRM app that gamifies social interactions using a "digital garden" metaphor. Each contact is represented as a plant that requires "watering" (interactions) to stay healthy.

### Tech Stack
- **Framework:** Flutter (Dart)
- **Animation:** Rive
- **Local Database:** Isar
- **Backend (Future):** Supabase or Firebase
- **AI (Future):** Google Gemini or OpenAI API

---

## Steps

### 1. Create Flutter Project
```bash
flutter create social_roots --org com.socialroots --platforms ios,android
cd social_roots
```

### 2. Configure iOS Settings
Edit `ios/Runner/Info.plist` to add required permissions:
```xml
<!-- Contacts Permission -->
<key>NSContactsUsageDescription</key>
<string>Social Roots needs access to your contacts to create your digital garden. Your data stays on your device.</string>

<!-- Notifications Permission -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### 3. Add Dependencies to `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Database
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # Contacts
  flutter_contacts: ^1.1.7+1
  permission_handler: ^11.1.0
  
  # Animation
  rive: ^0.12.4
  
  # UI/UX
  flutter_haptic: ^3.0.0
  audioplayers: ^5.2.1
  
  # Utilities
  intl: ^0.18.1
  uuid: ^4.2.2
  url_launcher: ^6.2.2
  share_plus: ^7.2.1
  
  # Local Notifications
  flutter_local_notifications: ^16.3.0
  
  # Deep Linking
  uni_links: ^0.5.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  
  # Code Generation
  isar_generator: ^3.1.0+1
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.9
  json_serializable: ^6.7.1
```

### 4. Project Folder Structure
Create the following directory structure:
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── plant_types.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   └── health_calculator.dart
│   └── services/
│       ├── database_service.dart
│       ├── contact_service.dart
│       └── notification_service.dart
├── data/
│   ├── models/
│   │   ├── plant.dart
│   │   ├── interaction.dart
│   │   └── note.dart
│   └── repositories/
│       ├── plant_repository.dart
│       └── interaction_repository.dart
├── features/
│   ├── onboarding/
│   │   ├── screens/
│   │   └── widgets/
│   ├── garden/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── providers/
│   ├── plant_detail/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── providers/
│   └── settings/
│       ├── screens/
│       └── widgets/
└── shared/
    └── widgets/
        ├── plant_card.dart
        └── loading_indicator.dart

assets/
├── rive/
│   └── plants/
├── images/
├── fonts/
└── audio/
```

### 5. Configure Assets in `pubspec.yaml`
```yaml
flutter:
  uses-material-design: true
  
  assets:
    - assets/rive/plants/
    - assets/images/
    - assets/audio/
  
  fonts:
    - family: Nunito
      fonts:
        - asset: assets/fonts/Nunito-Regular.ttf
        - asset: assets/fonts/Nunito-Bold.ttf
          weight: 700
```

### 6. Initialize Main Entry Point
Create a basic `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
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
```

### 7. Run iOS Setup
```bash
cd ios
pod install
cd ..
flutter run -d ios
```

---

## Acceptance Criteria
- [ ] Flutter project created with correct organization identifier
- [ ] All dependencies installed without conflicts
- [ ] iOS permissions configured in Info.plist
- [ ] Project folder structure created
- [ ] App runs on iOS Simulator without errors
- [ ] Isar database initializes successfully

---

## Notes
- Minimum iOS version: 13.0
- Ensure CocoaPods is up to date: `sudo gem install cocoapods`
- If Isar fails to generate, run: `dart run build_runner build --delete-conflicting-outputs`

---

## Dependencies on Other Tasks
- None (This is the first task)

## Blocks
- Task 02: Data Models
- Task 03: Contact Permissions
- All subsequent tasks
