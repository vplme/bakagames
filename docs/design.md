# Design — Baka Games (puzzle-games shell + Bird Sort)

## Fixed decisions (from the brief)

- Flutter latest stable; plain widgets + implicit/explicit animations. No Flame.
- No state-management package: engine state is immutable, UI holds `GameState`
  in a `ValueNotifier` + `ValueListenableBuilder`.
- Layout: `app/` (Flutter), `packages/game_core/` and `packages/bird_sort/`
  (pure Dart, no `flutter` SDK dependency; tests run with `dart test`).
- Persistence: `shared_preferences`, one JSON blob per game id.
- Levels generated deterministically: index → seed → generator → solver check.
- Ruleset differences are per-level flags (`removeBranchOnComplete`,
  `partialMovesAllowed`), not modes.
- Boosters: undo (free, unlimited), extra branch (once/level), hint (solver).
  No timers/lives/coins.
- Art: simple vector birds via `CustomPainter`; no imitation of existing apps.

## Bird Sort rules (as implemented)

- Branches hold `capacity` birds, ordered trunk→tip; only tip-side birds move.
- Movable unit: *linked group* = maximal same-colour run ending at the tip.
- Move A→B valid iff: A non-empty, A≠B, neither removed, B has ≥1 free slot,
  B empty or tip colours match.
- Move size is **canonical**: `min(group, freeOnB)` when
  `partialMovesAllowed`, else the move is only valid when the whole group fits
  (`freeOnB ≥ group`) and moves whole. `applyMove` rejects a `Move` whose
  `count` differs from the canonical size — the player never chooses a count.
- Completion (full + single-colour) triggers on the **destination** branch of a
  move: birds fly away; branch stays (empty, reusable) when
  `removeBranchOnComplete == false`, is removed when `true`.
- Win: every non-removed branch is empty.
- Stuck: not won and no valid move exists other than *trivial* ones (moving a
  linked group that is the sole occupant of its branch to an empty branch).

## Decisions made during implementation

- **Equality**: `Branch`, `Level`, `Move` are deep value types. `GameState`
  equality compares `level` + current `branches` + `isWon`/`isStuck` but
  **excludes `history`** — two states reached by different paths are "the same
  position". Undo tests compare against the exact prior state object.
- **No extra runtime dependencies** in the pure packages: deep list equality
  and hashing are implemented locally instead of pulling `package:collection`
  (working agreement: ask before adding deps; avoided instead). Dev-deps:
  `test` and `lints` only.
- **Initially-complete branches**: a seeded deal could produce a full
  single-colour branch. The engine does not auto-fly branches at level start;
  the **generator rejects** such deals and re-rolls. (Hand-written levels used
  in tests must avoid them.)
- **`undo` on empty history** returns the state unchanged (no throw);
  `restart` returns `history.first` or the state itself if history is empty.
- **Only the destination** of a move can complete, so `applyMove` checks just
  that branch (source only shrinks; other branches are untouched).
- **RNG** (phase 2): splitmix64 to derive per-index seeds, xorshift64* stream
  for shuffling — implemented in `bird_sort`, stable across platforms/Dart
  versions.
- **Icon descriptor** in `game_core` is a plain `String iconName` mapped to an
  `IconData` inside `app/` (game_core stays Flutter-free).
- `GameProgress.highestUnlocked` is a **0-based level index**; level 0 is
  always unlocked; completing level n unlocks n+1.

## Solver (phase 2)

- A* over canonical states. Key: sorted multiset of non-removed branch
  contents (branch identity/side irrelevant to solvability).
- Heuristic: `Σ per branch (colour segments − 1)` + number of colours not yet
  flown. Rationale: each extra segment needs ≥1 move to merge away, and each
  colour still on the tree needs ≥1 final "completing" move; slightly
  optimistic in edge cases but close to admissible and cheap.
- Prunes trivial moves and immediate reversals of the previous move.
- `maxNodes` budget; exceeding it ⇒ `budgetExceeded = true`, solvable
  *unknown* (not "unsolvable").
- Package stays synchronous; the app runs it via `Isolate.run`.

## Generator (phase 2)

- Deal `colours × capacity` birds shuffled with the seeded RNG into `colours`
  full branches + `emptyBranches` empty ones; sides alternate left/right.
- Reject & re-roll (seed derived from `(seed, attempt)`) when: unsolvable,
  budget exceeded, optimal move count below the tier minimum, or any branch
  is complete at deal time.
- Difficulty tier table in code maps index ranges → params; easy to edit.
- `levelFor(index)`: seed = splitmix64(index).

## UI decisions (phases 3–4)

- **Bird identity**: the engine deals in colour ids only; the UI keeps a
  mirror of stable per-bird uids (`PlayController.birdIds`) updated in
  lockstep with every engine transition. The whole tree renders as one Stack
  of `AnimatedPositioned` birds keyed by uid, which makes cross-branch
  flight, staggering (per-bird `Interval` curves), flock departure and undo
  animation fall out of the layout for free.
- **Extra-branch booster** is an engine transition (`addEmptyBranch`) that
  pushes onto history like a move: undo can revert it (the booster is *not*
  refunded — once per level attempt), restart returns to the original level
  without the branch. The board reads sides/capacity from the current state,
  never the initial level, since the branch count can grow mid-level.
- **Hint** applies the solver's first move. It solves a history-stripped
  snapshot in `Isolate.run` (closure hoisted to a top-level function —
  a closure created inside the State over-captures unsendable context),
  discards stale results if the position changed meanwhile, and shows a
  "no solution from here" snackbar on unsolvable/unknown.
- **Win callback** is `onWon(levelIndex, moves)` so the "next level" chain
  from the win sheet keeps saving progress for the right level.
- **Dev-dependency judgment call**: `shared_preferences_platform_interface`
  (dev only) is used to back `SharedPreferencesAsync` with the in-memory
  store in tests. Treated as part of the already-approved
  `shared_preferences` (same plugin, same authors, test-only); flagged here
  per the working agreement.
- Sound is a persisted toggle with no audio behind it yet, per the brief.

## Tier tuning report (generator_test.dart, first 200 levels)

```
tier      levels  reject-rate  avg-nodes  max-nodes  avg-optimal
3c/2e     10      9.1%         14         31         9.3
4c/2e     10      0.0%         18         36         12.7
5c/2e     10      0.0%         20         36         16.0
5c/1e/rm  30      77.8%        26         52         15.0
6c/1e/rm  140     93.0%        35         108        18.9
```

Removal tiers reject far more often (as expected — mostly "shorter than
`minOptimalMoves`" plus genuinely unsolvable 1-empty deals), but node counts
are tiny, so even a 93% rejection rate (~14 deals/level) generates instantly.

## Open questions

*(none currently — anything ambiguous gets logged here before guessing)*
