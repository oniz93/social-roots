# Social Roots 🌱

**Grow your relationships.** Social Roots is a personal CRM that turns your
social circle into a living digital garden. Every contact becomes a plant;
every call, text or meetup waters it. Neglect a relationship and the plant
wilts — a gentle nudge to reach out and reconnect.

Built with Flutter for iOS and Android. Local-first: contact data never
leaves your device.

## Features (MVP)

- **Social Garden** — grid of plants sorted by thirst, with a weather
  background that reflects your garden's overall health
- **Plant mechanic** — three watering types (Quick Text +20%, Phone Call
  +50%, Hangout +100%) with haptics and sound
- **Decay engine** — plants move through thriving → thirsty → wilting →
  critical → dormant based on time since last contact
- **Onboarding** — contacts permission, core-circle selection and a quiz
  that assigns each contact a plant difficulty
- **Notes & journal** — tags, photo memories and "Remember This" reminders
- **Notifications** — Morning Dew summary and Wilt Warnings, locally
  scheduled (no server)
- **Vacation mode** — pause decay while you're away; snooze individual
  plants
- **Bloom Moments** — attach photos to interactions
- **Garden analytics** — health distribution and watering history
- **Compost (archive)** — remove a plant without losing its history

## Tech stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter (Dart), Material 3 |
| State | Riverpod (codegen) |
| Database | Isar (local-first, no backend) |
| Animation | Rive (planned) + built-in procedural placeholder plants |
| Notifications | flutter_local_notifications |
| Contacts | flutter_contacts + permission_handler |
| Fonts | Nunito |
| Audio | Procedurally generated sound effects |

## Repository layout

```
social_roots/   Flutter app (see social_roots/README.md)
assets/         fonts, audio, images, rive (see assets/README.md)
tasks/          MVP task specifications (01-13)
SocialRoots.md  Business Requirement Document
web/            Marketing site for socialroots.app
```

## Getting started

Prerequisites:

- Flutter 3.44+ (`flutter doctor`)
- Xcode + CocoaPods (iOS)
- JDK 17 — the Android toolchain requires it:
  `flutter config --jdk-dir=/path/to/jdk17`
- Android NDK r29 (installed automatically by Gradle if SDK licenses are
  accepted; `sdkmanager --install "ndk;29.0.13846066"` to install manually)

```bash
flutter pub get
flutter run            # pick a simulator/device
flutter analyze        # 0 issues
flutter test           # 6/6 passing
```

## Branching workflow

- `main` is the base branch and always buildable.
- Every feature/fix lands on its own branch and is merged via pull request:

```
git checkout -b feature/my-change main
# ... commits ...
git push -u origin feature/my-change
# open a PR against main
```

- Assets live on their own branches so each PR stays reviewable
  (fonts, audio, icons, app icons are independent PRs).
- Suggested merge order (only `feature/assets-images` must land before
  `feature/analyze-cleanup`, which builds on it; everything else is
  independent; merge `feature/android-build-fix` before
  `feature/dependency-upgrades` so permission_handler 13 gets
  compileSdk 37):

  1. feature/android-build-fix
  2. feature/assets-audio
  3. feature/assets-fonts
  4. feature/assets-images
  5. feature/assets-rive-fix
  6. feature/android-app-icon
  7. feature/test-suite-fix
  8. feature/analyze-cleanup
  9. feature/readme-docs
  10. feature/website
  11. feature/dependency-upgrades

## Docs

- [Business Requirement Document](SocialRoots.md)
- [Task specifications](tasks/00-mvp-summary.md)
- [Asset guide](social_roots/assets/README.md)
- [App Store submission materials](submission/submission_info.md) *(local only)*

## Links

- Marketing: https://socialroots.app
- Privacy policy: https://socialroots.app/privacy
- Support: https://socialroots.app/support
