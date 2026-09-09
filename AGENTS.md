# Repository guidance

## Structure and commands

- `app/` is the Flutter application. Run `flutter analyze` and `flutter test` from that directory, not the repository root.
- `packages/bird_sort/` is the pure Dart sorting engine, generator, and solver. Keep it independent of Flutter; run `dart test` there when changing rules or generation.
- `packages/game_core/` defines shared game and progress contracts.
- For Pocket Aviary design, asset provenance, and prior verification, read `docs/aviary/README.md`. Reference artwork and generation prompts are in `docs/aviary/`.

## Compatibility and game behavior

- Baka Games is a multi-game app. Keep the shared home as the game-selection library; game-specific homes, artwork, and level themes belong under `app/lib/games/`. Supply card previews and optional landing screens through `GameEntry`, rather than importing a game into the shared shell.
- Preserve the persisted game ID `bird_sort` and existing progress records when changing branding or progression. Collection credit comes from distinct completed levels, not win events; replays must not add unlock credit.
- Keep sorting decisions in the engine. The Flutter `PlayController` maintains stable bird IDs alongside engine state for animation; undo, restart, and completion must keep both representations aligned.
- Keep level generation and hint solving off the UI isolate. Use top-level isolate helpers that capture only sendable inputs: closures created alongside State-capturing callbacks can accidentally capture unsendable UI state.
- Allow input during flight. Honor both system and app reduced-motion preferences, plus sound and haptic settings. Wait for progress persistence before enabling next-level navigation and retain save retry behavior.

## Artwork and verification

- Keep species/color IDs consistent with `aviary.dart` and `palette.dart`; species silhouettes must distinguish sorting groups independently of color.
- Bundle optimized assets locally. A generated checkerboard is not transparency: inspect the actual alpha channel and preview edges and foot placement on the gameplay background.
- Blink overlays use sprite-specific eye coordinates in `board.dart`. Recheck those coordinates and eyelid colors whenever replacing artwork.
- Check compact screens and enlarged text. Prefer scrolling to shrinking birds below readable gameplay size; the existing regression covers 320×568 at 130% text.
- Continuous idle animation prevents `pumpAndSettle` from settling. Use reduced motion for static widget tests and bounded `pump` calls for animation tests. Tap stable `branchN` keys instead of approximate screen coordinates.
- Framework test timings are not GPU timings or release FPS. Physical-device performance and audio/haptic feel require separate device verification.
