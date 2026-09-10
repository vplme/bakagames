# Pocket Aviary

Implemented in the existing Flutter game. The bird_sort game ID, saved JSON schema, completed levels, best-move records, sorting rules, undo history, and solver remain compatible.

## Play and progression

- Fifteen fixed species/color identities: cardinal/red, blue jay/blue, canary/yellow, parakeet/green, owl/purple, finch/orange, kingfisher/turquoise, cockatoo/pink, puffin/charcoal, woodpecker/chestnut, toucan/lime, dove/pearl, quail/slate, hoopoe/sand, hummingbird/mint.
- Spacious numbered perches, legal-destination outlines, selection hop, breathing, blinking, head tilts, flight arcs, wing motion, landing squash, branch bounce, invalid-move shake, flock hop/departure, sparkles, and local chirps.
- Input remains active during movement; a new transition starts from the current interpolated position.
- Next level appears on completion without waiting for celebration. It waits for persistence and offers retry after a save failure.
- Collection derives from distinct completed levels: three starter birds, then discoveries at 3, 8, 15, 24, 35, 48, 63, 80, 99, 120, 143, and 168 completions. Replays never duplicate collection credit.
- Sunny garden, cherry grove, and moonlit forest rotate every ten levels. Every fifth puzzle is an easier three-species breather. Other puzzles retain original seeded positions with a bijective species remapping. Existing best scores remain saved, including scores on levels now used as breathers.
- Both the OS reduced-motion preference and the in-app switch suppress idle motion and use instant moves. Sound and haptic switches persist independently.
- Compact screens/enlarged text scroll vertically instead of shrinking birds. Perches have a minimum 66-pixel height.

## Assets

All gameplay assets are local under `app/assets/aviary/`: fifteen 256×256 RGBA WebP sprites, three 768×1152 WebP habitats, and two short mono WAV bird calls. Total payload: **481,130 bytes**. The reference sheet lives beside this file as `character-reference.png`.

Artwork used the built-in `image_gen.imagegen` tool. The generated reference PNG provenance identifies **gpt-image 2.0**. The tool offered no model selector; GPT Image 2.5 was not available to select. No claim is made that 2.5 was used. See `prompts.md` for the reference, individual sprite, habitat, and transparency-repair prompts.

Birds were generated individually from the reference, then reduced using `cwebp` (quality 86, alpha preserved). Habitats use quality 82. All eight final sprite files were checked for real alpha. The first finch outputs had a baked checkerboard and were discarded; a fresh referenced generation supplied the final transparent sprite. Foot baselines and edges were inspected in the iPhone simulator.

Chirps are original synthesized sine-sweep motifs, bundled as 22,050 Hz mono PCM WAV, played through audioplayers. No runtime asset downloads or online services are used.

## Verification — 2026-09-09

- `cd app && flutter analyze`: clean.
- `cd app && flutter test`: **15 passed**. Covers rules/controller synchronization, undo/restart, hints, extra branch, collection milestones, deterministic solvability through level 500 samples, 320×568 with 130% text, save-failure retry, and rapid undo during flight.
- `cd packages/bird_sort && dart test`: **39 passed**, including all first 200 original generated levels solved within budget.
- `cd app && flutter build ios --simulator`: passed, including native audio integration.
- Framework performance smoke test: **2.69 ms per frame** averaged across 120 pumped frames on the local host with a six-species board. This measures Flutter test framework work, **not physical-device GPU timing or release FPS**. Physical iPhone/Android profiling remains a release QA step. The earlier simulator VM trace connection expired and was not used as performance evidence.
- Manual iPhone 17 Pro simulator: readable first-level birds and alpha edges, selection glow/valid destinations, completed level 1 in eight hint-assisted moves, next-level navigation, collection display. Replaying level 1 preserved 12 distinct completions and five discovered birds.
- Screenshots: `screenshots/home.png`, `gameplay.png`, `habitats.png`, `collection.png`, `completion.png`. These are actual simulator captures; different captures reflect the saved progress present at capture time.

## Main implementation files

`app/lib/games/bird_sort/aviary.dart` contains species identities, habitat selection, and collection UI; `aviary_levels.dart` controls pacing; `board.dart` animates stable bird identities; `play_screen.dart` coordinates play, saving, controls, and completion. The shell home and level path share the new identity. The app dependency lockfile is included for reproducible builds.

## Additional birds — 2026-09-09

Puffin “Pebble” (species 8) and Woodpecker “Woody” (species 9) extend the collection at 48 and 63 distinct completed levels. Earlier identities and milestones remain unchanged. Later levels introduce the new species through the existing bijective mapping, preserving each puzzle’s grouping and difficulty. Saved progress requires no migration.

New sprites were generated with the built-in image tool; exact prompts and output paths are in [new-birds-prompts.md](new-birds-prompts.md). Both optimized 256×256 WebP files have real alpha (range 0–254). Sprite-specific blink positions and eyelid colors were added. [new-birds.png](screenshots/new-birds.png) is a Flutter widget-test capture used to inspect transparent edges and foot placement on the gameplay background; its text uses the test font, and it is not a simulator/device capture.

Verification: Flutter analysis clean; all 20 app tests and 39 engine tests pass. The added regression exercises both new species, blinking, and a legal move on a 320×568 screen at 130% text. Deterministic solver coverage includes both new introduction boundaries. Physical-device verification was not repeated for this asset expansion.

## Five more birds — 2026-09-09

Added species IDs 10–14: Toucan “Rio” at 80 completions, Dove “Pearl” at 99, Quail “Dot” at 120, Hoopoe “Cleo” at 143, and Hummingbird “Jewel” at 168. Existing IDs and milestones remain unchanged. Collection totals now show 15. Species variety expands through the existing bijective mapping without increasing the number of sorting groups per puzzle or changing saved progress.

Generated each sprite separately with the built-in image tool; [five-more-birds-prompts.md](five-more-birds-prompts.md) records exact prompts and final asset paths. All five optimized 256×256 WebP sprites have genuine transparency (alpha minima 0, maxima 253–254). Added sprite-specific eye coordinates and eyelid colors. [five-more-birds.png](screenshots/five-more-birds.png) is a Flutter widget-test board capture for checking silhouettes, transparency, and foot placement on the gameplay background; labels use the test font.

Verification: clean Flutter analysis, all 23 app tests and 39 engine tests pass. Tests cover all 15 species in deterministic solvable puzzles, the new collection boundaries, appearance within the following rotation, and compact-screen animation/moves for every added species at 320×568 and 130% text. No new physical-device performance measurements were taken.
