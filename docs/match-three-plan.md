# Match-three implementation plan

Status: campaign, original candy artwork, visual feedback, and local sound implemented; physical-device playtesting remains.
Last updated: 2026-09-11.

Use this document to track implementation across sessions. Check items only when
completed, record validation results, and update the handoff section before
ending an implementation session.

## Direction and agreed decisions

- Add a cozy match-three game to the Baka Games library alongside Pocket Aviary.
- **Unlimited moves are confirmed.** Levels end when collection goals are met.
  Move count is only an optional personal best, not a failure condition.
- Preserve the app's principles: no ads, tracking, accounts, timers, lives,
  paid boosts, or waiting gates. Everything works offline.
- **Pocket Sweets** is a working title, not a finalized name.
- Use original candy artwork, with types distinguishable by shape and color.

## Proposed first release

- A 7×7 board with five sweet types.
- Swipe adjacent pieces, or tap two adjacent cells, to swap.
- A swap that makes no match returns without counting a move.
- Matches of three or more clear; gravity and refills create cascades.
- Collection goals introduce the mechanics gradually across 30 levels.
- Four in a line creates a row/column clearer; five in a line creates a color
  clearer. Exact creation and activation rules must be specified before coding.
- Free hints, unlimited undo, and restart.
- Hints suggest a valid move rather than claiming an optimal solution.
- Automatically reshuffle boards with no legal moves.
- Defer blockers, T/L bombs, and special-piece combinations until the core feels
  good. Do not silently expand the initial scope to include them.

## Milestone 1 — One polished playable level

Complete the basic loop before expanding the campaign or adding specials.

### Rules and engine

- [x] Specify board coordinates, swap validity, match detection, simultaneous
  clearing, gravity, refill order, cascade ordering, and goal counting.
- [x] Specify starting-board constraints and dead-board recovery, including a
  bounded fallback so generation and reshuffling cannot loop indefinitely.
- [x] Define a seeded level format and reproducible random state. Validate
  playable starts; do not claim full solver verification as used by Bird Sort.
- [x] Create `packages/match_three/` as a Flutter-independent Dart package.
- [x] Implement swaps, matches, cascades, collection goals, and completion.
- [x] Implement deterministic refill and automatic dead-board reshuffling.
- [x] Implement legal-move hints, restart, and full-turn undo. Undo must restore
  pieces, goals, move count, and random state, including after cascades.
- [x] Emit explicit resolution steps and stable piece IDs for the UI.

### Playable UI

- [x] Create game-owned code in `app/lib/games/match_three/`.
- [x] Build one level with readable pieces, collection targets, and move count.
- [x] Support both swipe and tap-to-swap input with clear selection feedback.
- [x] Animate swaps, invalid-swap returns, clears, falls, and refills from engine
  resolution steps; prevent overlapping swaps during resolution.
- [x] Provide hints, undo, restart, and a completion state.
- [x] Honor system and app reduced motion with instant resolution.
- [x] Check compact layout and enlarged text before committing to board sizing.
- [ ] Playtest and tune the basic interaction before moving to milestone 2.

## Milestone 2 — Specials and campaign

- [x] Specify special-piece placement, orientation, activation, chain reactions,
  and collection credit. Explicitly define behavior for intersecting matches and
  interactions involving existing specials, including deferred combinations.
- [x] Implement four-in-line row/column clearers and five-in-line color clearers.
- [x] Add distinctive visuals and understandable feedback for specials.
- [x] Author 30 introductory level configurations using fixed seeds.
- [x] Introduce collection goals and specials gradually, with gentler levels
  between harder ones.
- [ ] Validate all starting boards and playtest goal pacing. Unlimited moves
  removes failure pressure but does not automatically make levels enjoyable.

## Milestone 3 — Library integration and polish

- [x] Add a game definition with stable persistence ID `match_three`.
- [x] Register a `GameEntry` supplying its preview, landing screen, level picker,
  and play screen. Keep the shared home as the game-selection library.
- [x] Add the package dependency to the Flutter app.
- [x] Reuse `GameProgress` completion and best-move storage; preserve existing
  `bird_sort` progress and avoid unnecessary shared-contract changes.
- [x] Await progress persistence before enabling next-level navigation and offer
  save retry on failure. Replays must not inflate distinct completion counts.
- [x] Add original locally bundled artwork and document asset provenance.
- [x] Add local game-specific sound effects honoring shared sound preferences;
  honor haptic preferences as well.
- [x] Add accessible cell/piece labels and controls; distinguish types by shape.
- [ ] Finalize title and library copy, then update the repository README.

## Verification and acceptance

- [ ] Engine tests cover invalid swaps, overlapping matches, cascade ordering,
  goal counting, specials, deterministic refills, and dead-board recovery.
- [x] Engine tests prove undo restores the complete prior turn and restart
  reproduces the initial state.
- [x] Widget tests cover both input methods, resolution input handling, hints,
  undo, restart, completion, save failure/retry, and next-level navigation.
- [x] Verify library navigation and independent progress for both games.
- [x] Check 320×568 at 130% text scaling with readable pieces and usable controls;
  prefer scrolling to shrinking pieces below readable size.
- [ ] Verify system and app reduced-motion settings, sound, and haptic switches.
- [x] Run `dart test` from `packages/match_three/`.
- [x] Run `flutter analyze` and `flutter test` from `app/`.
- [ ] Run `dart test` from `packages/game_core/` if shared contracts change, and
  from `packages/bird_sort/` if its rules or generation change.
- [ ] Verify animation performance and audio/haptic feel on a physical device.
  Framework test timings are not GPU timings or release FPS.

For static widget tests use reduced motion; for animation tests use bounded
`pump` calls rather than relying on `pumpAndSettle` with continuous animations.
Keep expensive generation or search off the UI isolate, using top-level helpers
with sendable inputs. Follow repository `AGENTS.md` throughout implementation.

## Session handoff

**Current state:** Pocket Sweets now has 30 fixed campaign configurations. Level 1
retains its original seed/targets and persisted completion. Stripes begin at level
6 and rainbows at level 11. Special creation/activation and chained clears restore
correctly with undo. The library opens a game-owned landing screen, picker, and
play screens. Next-level navigation waits for progress saving, with retry on
failure. Hint search and restart generation run in isolates. Shared sound settings
now support game-owned asset paths; two original local WAV effects are bundled.

Rules: [match-three-rules.md](match-three-rules.md).
Asset provenance: [sweets/README.md](sweets/README.md).

**Artwork update:** Original glossy heart/leaf/star/hexagon/drop sprites and a
rainbow bonbon replace Material icons. The candy garden appears in the library
preview, landing screen, picker, and gameplay. Plum board cells, cream goal chips,
pink controls, selection scaling, short sugar bursts, and a completion card give
the game a cohesive visual style. Images total about 415 KB, load locally, and
preserve real alpha. Exact prompts and QA are in [sweets/artwork-prompts.md](sweets/artwork-prompts.md).

**Next step:** Play through levels on a physical device and tune goals, animation
feel, and audio/haptic feedback. Add forced post-turn dead-board/cascade-cap and
special-intersection edge-case coverage before release. The working title remains
Pocket Sweets; T/L bombs, blockers, and combination bonuses stay deferred.

**Validation performed:** All 32 app tests pass after artwork integration, including
compact board access, save retry/navigation, normal-motion input locks, bounded
sugar bursts, and reduced-motion suppression. Flutter analysis passes. Inspected
rendered 390×844 gameplay/landing views and 320×568 at 130% text, including sprite
alpha edges against the plum board. The unchanged engine previously passed 11
tests, with all 30 levels completed under legal hint play. No physical-device
performance, human campaign playtest, audio listening, or haptic check is claimed.

### Session log

| Date | Work completed | Validation / remaining work |
| --- | --- | --- |
| 2026-09-11 | Saved plan and confirmed unlimited-moves direction. | Implementation not started; begin milestone 1. |
| 2026-09-11 | Implemented engine, first level, library entry, persistence and tests. | 5 engine tests and 29 app tests pass; device playtest and polish next. |
| 2026-09-11 | Added specials, 30 levels, landing screen, next-level flow, local sound, and compact board controls. | 11 engine and 32 app tests pass; device playtesting and artwork remain. |
| 2026-09-11 | Integrated original candy atlas and garden art, plum board, goal chips, special markings, sugar bursts, and completion card. | 32 app tests pass; alpha and phone renders inspected; device playtesting next. |

### Home and library layout update — 2026-09-11

- Library entry now fills its artwork area with the candy garden and a larger
  candy display; subtitle copy introduces matches and rainbow sweets.
- Game home follows Pocket Aviary's layout: All games and Settings navigation,
  large centered title/tagline, hero display, full-width Play button, completed
  picnic progress, and Level path / Sweet guide tiles. The guide explains current
  mechanics; it does not invent new collectible rewards or change progression.
- Game-specific layout is in `sweets_home_screen.dart` and `sweets_preview.dart`.
  The shared library shell and Pocket Aviary are unchanged.
- Reuses existing generated artwork; no new images or runtime dependencies.
- Rendered 390×844 home/card and 320×568 at 130% text inspected. Compact navigation
  regression covers guide, settings, level path and All games. Full app suite:
  33 tests pass; Flutter analysis clean. Device verification remains outstanding.

### Gameplay navigation consistency — 2026-09-11

- Pocket Sweets now follows Aviary's gameplay header: circular rounded Back and
  tune/settings buttons, centered uppercase game title and subtitle, level name
  above a prominent level number, and a separate move-count pill.
- Both games use `shell/play_controls.dart` for circular icon buttons with labels
  underneath. Sweets orders its actions Undo, Restart, Hint; Aviary retains its
  game-specific extra-branch action between Restart and Hint. Each game retains
  its own palette, rules, and persistence behavior.
- Added coverage for settings access, icon identities and action order. Updated
  disabled-control assertions for the shared component. Phone and compact renders
  inspected; 34 app tests pass and Flutter analysis is clean.

### Completion overlay — 2026-09-11

Completion now appears in a centered, viewport-constrained dialog over a dimmed
board rather than below the scrolling gameplay content. The background is blocked
from pointer, focus, and accessibility interaction while the overlay is open.
Save status/retry and saved-only navigation remain inside the overlay. Back to
board closes it to allow undo/restart; Show completion reopens it without replaying
or resaving the win. The dialog can scroll internally for unusually large text.

All 35 app tests pass; Flutter analysis is clean. Completion regressions verify
retry and next-level actions are directly hit-testable without scrolling the game
on regular screens and at 320×568 with 130% text, including close/reopen behavior.
