# Assets

This folder holds every bundled resource used by the app.

| Folder  | Contents | Status |
|---------|----------|--------|
| `audio/`   | Sound effects & ambient loop (MP3, 44.1 kHz mono) | ✅ ready |
| `fonts/`   | Nunito Regular / SemiBold / Bold (OFL licence)     | ✅ ready |
| `images/`  | Interaction icons: drop, cup, watering can (PNG)    | ✅ ready |
| `rive/`    | Animated plants — see `rive/README.md`              | ⏳ pending |

## Audio

The four sounds were synthesised procedurally for this project
(no third-party recordings):

- `water_drop.mp3` — droplet "plink" (pitch bend + splash tail), 0.7 s
- `water_pour.mp3` — flowing water noise with rise/fall envelope, 2.6 s
- `revival_success.mp3` — soft major arpeggio with shimmer, 1.8 s
- `garden_ambient.mp3` — loopable breeze + sparse birdsong, 12 s
  (edges are crossfaded so the loop is seamless)

## Fonts

Nunito is used as the app typeface (see `pubspec.yaml`). The static
instances (Regular 400, SemiBold 600, Bold 700) were derived from the
official variable font, distributed under the SIL Open Font License.

## Images

Flat-style interaction icons drawn for Social Roots, 512 × 512 px with
transparent backgrounds:

- `drop.png` — Quick Text
- `cup.png` — Phone Call
- `watering_can.png` — Hangout / Meetup
