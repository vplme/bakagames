# app

The Flutter application for [Baka Games](../README.md) — the shared game library
shell plus the per-game UI.

The game rules themselves live outside this directory, in `packages/bird_sort/`
and `packages/game_core/`, so they can be tested without Flutter.

```bash
flutter pub get
flutter run

flutter analyze
flutter test
```

See [`../docs/design.md`](../docs/design.md) for the architecture and
[`../AGENTS.md`](../AGENTS.md) for the working conventions.
