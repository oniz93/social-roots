# Social Roots — Flutter app

The main repository README lives at the repo root. This file covers
app-specific developer notes.

## Run

```bash
flutter pub get
flutter run
```

## Quality gates

```bash
flutter analyze   # expected: No issues found
flutter test      # expected: All tests passed
```

## Assets

Everything bundled with the app lives under `assets/` — see
[assets/README.md](assets/README.md) for the inventory and the Rive
state-machine contract. The Android launcher icon and splash are branded;
the iOS icon lives in `ios/Runner/Assets.xcassets`.

## Android build notes

- Requires JDK 17 (`flutter config --jdk-dir=...`).
- The build pins the NDK to r29 (`ndkVersion` in `android/app/build.gradle.kts`);
  keep it in sync with your local SDK, or let Gradle auto-install it.
- Debug signing is used for release builds until a real keystore is added.
