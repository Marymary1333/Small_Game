# RunnerGame

A 2D jump-and-dodge runner for macOS, inspired by Donkey Kong. The player runs automatically
over a parallax background, jumps over barrels and spikes, ducks under birds, avoids falling rocks,
and collects coins.

**Phase 1** proves the mechanics with simple shapes. Real art comes in phase 2.

## Requirements

- macOS 14 or later
- Xcode 15 at `/Applications/Xcode.app`
- XcodeGen (`brew install xcodegen`)

## Open and run

```bash
make generate
open RunnerGame.xcodeproj
```

In Xcode, press ⌘R to run and ⌘U to test. From the terminal:

```bash
make run
make test
```

`project.yml` is the source of truth for the Xcode project. After adding, moving or removing
files, run `make generate` again. Changes made only in Xcode's project settings are overwritten.

## Controls

| Key | Action |
|---|---|
| ↑ | Jump; press again in the air to double jump |
| ↓ (hold) | Duck |
| Esc | Pause menu; press again to resume |
| ⌘, | Settings |
| ⇧⌘H | Show hitboxes (Debug builds only) |

## Project structure (MVVM)

```
RunnerGame/
  App/        entry point, root navigation, composition root (creates services)
  Model/      pure Swift game rules: engine, collision, spawner, difficulty, settings types
  Services/   audio synthesis, settings and best-score persistence
  ViewModel/  app navigation, game, menu and settings state
  View/       SwiftUI screens and the SpriteKit scene
RunnerGameTests/  unit tests with fake services
```

Dependencies point one way: View → ViewModel → Model, with ViewModels using service protocols.
Model and ViewModel code never imports SwiftUI, SpriteKit, AppKit or AVFoundation.

## Tuning

Gameplay numbers live in two places:

- `RunnerGame/Model/GameCore/GameConfig.swift`: gravity, jump strength, sizes, invincibility time, spawn distances.
- `RunnerGame/Model/Settings/Difficulty.swift`: per-level speed, speed ramp, gaps between hazards, hazard mix.

## Phase 2: art

Drawing code is isolated in `RunnerGame/View/Game/`. Replacing the shape nodes
(character, hazards, coins, parallax layers) with sprites does not touch the Model,
ViewModels or tests.

## Failure handling

Only these fallbacks exist, each confirmed by the product owner:

- Unreadable saved settings: alert, then reset to first-launch settings.
- Unreadable saved best score: alert, then reset to no best score.
- Audio fails to start: alert, then the game runs without sound.
