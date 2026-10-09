# RunnerGame — project rules

## Decision ownership
- The user makes all **product decisions**: hazard and obstacle types, player movement and controls,
  game rules (lives, scoring, difficulty), sounds and music, visual style, menu and settings content.
- When a task needs one of these decided, **ask the user first**. Offer options with a recommendation.
  Never silently pick a product default, even for small details.
- Claude decides technical implementation details within the agreed architecture
  (code structure, algorithms, tests, tooling) and mentions significant ones.

## No fallbacks without explicit confirmation
- Do not implement fallbacks without the user's explicit confirmation. This includes default values
  substituted when data is missing or unreadable, alternative code paths when a framework or tool fails,
  silently skipping a feature, retry-then-give-up logic, and "use X if Y isn't available" behaviour
  in code, build scripts or tooling.
- When a failure case needs handling, describe it and ask the user how it should behave.
- Confirmed fallbacks are listed here so they stay visible:
  - Unreadable saved settings → alert, reset to first-launch settings.
  - Unreadable saved best score → alert, reset to "no best score".
  - Audio engine fails to start → alert, game runs without sound.

## Terminology
- "Architecture" means **project architecture**: the modules of the project and the relations between
  them (MVC, MVVM, …). It does not mean the toolkit (SpriteKit, SwiftUI, Metal); toolkit is a separate decision.

## Architecture: MVVM
- Model (`RunnerGame/Model`): pure Swift game rules, imports only Foundation.
- ViewModel (`RunnerGame/ViewModel`): Foundation + Observation; uses Model and service protocols; never Views, SwiftUI or SpriteKit.
- View (`RunnerGame/View`): SwiftUI and SpriteKit; talks only to its ViewModel.
- Services (`RunnerGame/Services`): protocols plus system-framework implementations.
- App (`RunnerGame/App`): the only place concrete services are created and injected.

## Build
- Xcode lives at /Applications/Xcode.app; xcode-select points at Command Line Tools,
  so CLI commands set DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer.
- `make generate` (XcodeGen), `make build`, `make test`, `make run`.
- After adding or removing files, rerun `make generate`; edit `project.yml`, not the .xcodeproj.
