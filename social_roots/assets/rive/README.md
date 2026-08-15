# Rive Plant Animations

**Status: not yet added.** The app currently ships with
`kEnableRiveAnimations = false` and renders the built-in placeholder
plants instead. When the `.riv` files land here, flip that flag to
`true` in `lib/core/constants/app_constants.dart`.

## Expected files

One `.riv` per plant type, named after the `PlantType` enum value
(`lib/data/models/plant.dart`):

```
cactus.riv, snakePlant.riv, succulent.riv,
monstera.riv, sunflower.riv, pothos.riv,
orchid.riv, fern.riv, rose.riv
```

The code loads them as `assets/rive/plants/<name>.riv`.

## State machine contract

Each file must contain a state machine named **`PlantStateMachine`**
with:

| Input  | Type     | Meaning                                     |
|--------|----------|---------------------------------------------|
| `health` | Number | Plant health, 0.0 (dormant) to 1.0 (thriving) |
| `water`  | Trigger  | Fired when the plant is watered             |
| `revive` | Trigger  | Fired when a dormant plant is revived       |

The widget treats a return to the **`Idle`** state as "animation
finished" (`AnimatedPlantWidget.onAnimationComplete`), so water/revive
one-shots should transition back to `Idle` when done.

See `tasks/13-rive-animations.md` for the original design spec.
