# Pocket Aviary

Implemented in the existing Flutter game. The bird_sort game ID, saved JSON schema, completed levels, best-move records, sorting rules, undo history, and solver remain compatible.

## Play and progression

- Eight fixed species/color identities: cardinal/red, blue jay/blue, canary/yellow, parakeet/green, owl/purple, finch/orange, kingfisher/turquoise, cockatoo/pink.
- Spacious numbered perches, legal-destination outlines, selection hop, breathing, blinking, head tilts, flight arcs, wing motion, landing squash, branch bounce, invalid-move shake, flock hop/departure, sparkles, and local chirps.
- Input remains active during movement; a new transition starts from the current interpolated position.
- Next level appears on completion without waiting for celebration. It waits for persistence and offers retry after a save failure.
- Collection derives from distinct completed levels: three starter birds, then discoveries at 3, 8, 15, 24, and 35 completions. Replays never duplicate collection credit.
- Sunny garden, cherry grove, and moonlit forest rotate every ten levels. Every fifth puzzle is an easier three-species breather. Other puzzles retain original seeded positions with a bijective species remapping. Existing best scores remain saved, including scores on levels now used as breathers.
- Both the OS reduced-motion preference and the in-app switch suppress idle motion and use instant moves. Sound and haptic switches persist independently.
- Compact screens/enlarged text scroll vertically instead of shrinking birds. Perches have a minimum 66-pixel height.

## Assets

All gameplay assets are local under `app/assets/aviary/`: eight 256×256 RGBA WebP sprites, three 768×1152 WebP habitats, and two short mono WAV bird calls. Total payload: **383,562 bytes**. The reference sheet lives beside this file as `character-reference.png`.

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
