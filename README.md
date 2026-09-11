# Baka Games

A single app full of stupidly fun little games. No ads, no tracking, no accounts.

*Baka* (馬鹿) is Japanese for "silly" — which is exactly the kind of game this is
for. Simple, pleasant, a bit pointless. The good kind of pointless.

## Why this exists

The casual puzzle games our family members love are usually free, and you pay for them
in a currency that is not easy to miss:
- full-page interstitial ads with a five-second countdown
- a close button three pixels wide
- a one-tap install of whatever sketchy app bought ads.

For most of us that is merely obnoxious. For the people most likely to be playing
these games all afternoon — grandparents, young kids — it is a real problem. They
are being asked to make a security judgement, over and over, under a countdown
timer, in a UI deliberately designed to make the wrong tap the easy one. It is not
reasonable to expect someone to tell a real close button from a fake one, or a
safe app from a data-harvesting one, dozens of times a day. Eventually a tap lands
in the wrong place, and something gets installed that nobody wanted.

The fix does not have to be complicated. If the games they want are all in one
app, and that app never shows an ad or asks for anything, there is no sketchy tap
to make. You install it once for them, and it is done. That is the entire idea.

**What that means in practice:**

- **No ads.** Not "fewer ads", not "ads you can pay to remove". None.
- **No tracking, no analytics, no telemetry.** Nothing is sent anywhere.
- **No account, no login, no cloud.** Progress is a JSON blob in local storage.
- **No permissions.** The Android manifest declares no `uses-permission` at all —
  including no `INTERNET`. There is no ad or analytics SDK in the dependency
  tree, and no networking code in this repo. (`audioplayers` pulls in `http`
  transitively because it *can* stream audio from a URL; this app only ever
  plays locally bundled WAV files, and without the `INTERNET` permission
  Android would refuse the connection regardless.)
- **No dark patterns.** No timers, lives, streaks, coins, or nagging. Undo is
  free and unlimited. You cannot lose, and nothing is ever gated behind a wait.

The point is an app you can hand to someone you love and then stop thinking about.

## The games

| Game | What it is |
| --- | --- |
| **Pocket Aviary** | Sort birds onto branches until each branch holds one species. 500 levels, generated deterministically and verified solvable by the built-in solver, with 15 birds and 50 habitats to unlock as you go. |

**Pocket Sweets** offers 30 match-three picnics with unlimited moves, collection goals, striped and rainbow sweets, cascades, hints, and undo. Progress stays on your device. See [the implementation tracker](docs/match-three-plan.md) for remaining device playtesting. Original glossy candy artwork and a candy-garden backdrop are bundled locally.

More to come — the shell is built to hold a library of them.

## Design notes

A few choices worth calling out, since they are the reason the app feels the way
it does:

- **Every level is checked before you see it.** Levels are generated from the
  level index (index → seed → generator → solver) rather than hand-authored, and
  a level is only shipped if the solver can actually finish it. No dead ends.
- **Difficulty ramps, but it always lets up.** Every fifth puzzle is a deliberate
  three-species breather, and the hint button runs the same solver.
- **The game engine is pure Dart.** `packages/bird_sort/` has no Flutter
  dependency, so the rules, generator, and solver are tested with plain
  `dart test`, separately from the UI.
- **It should work on the phone your family actually has.** The layout is
  verified down to 320×568 at 130% text scaling — on small screens the board
  scrolls rather than shrinking the birds below a readable size.
- **Motion and sound can be turned off.** Both the OS reduced-motion setting and
  an in-app toggle suppress idle animation and make moves instant. Sound and
  haptics are independent switches.

## Project layout

```
app/                     Flutter app (UI, shell, per-game screens)
  lib/shell/             Game library, settings, local progress storage
  lib/games/bird_sort/   Bird Sort UI and artwork
packages/game_core/      Shared game + progress contracts (pure Dart)
packages/bird_sort/      Bird Sort rules, generator, solver (pure Dart)
docs/                    Design notes and asset provenance
```

Adding a game means adding one `GameEntry` to the registry: it supplies its own
play screen, level picker, and optional landing screen, and the shared shell
handles the rest.

## Running it

Requires the Flutter SDK (Dart `^3.12.2`). Targets iOS and Android.

```bash
cd app
flutter pub get
flutter run
```

### Tests

Run each from the repository root:

```bash
(cd app && flutter analyze && flutter test)  # app + widget tests
(cd packages/bird_sort && dart test)         # engine, generator, solver
(cd packages/game_core && dart test)         # shared contracts
```

## Artwork

Bird sprites and habitat backgrounds are AI-generated and bundled locally — the
app loads no remote assets. The exact prompts and generation records are kept in
`docs/aviary/` for provenance. Bird calls are original synthesized sine-sweep
motifs.

## Contributing

This is a personal project, but if you have a stupidly fun game idea that fits
the constraints above — no ads, no tracking, no dark patterns, playable by a
seven-year-old and a seventy-year-old — feel free to open an issue.
