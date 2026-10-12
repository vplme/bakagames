# Lantern Mahjong festival theme

The library card, game home, guide, board and completion screen use the locally bundled `app/assets/mahjong/lantern-festival.webp` (1024 × 1536, approximately 334 KB). The opaque scene was created with the built-in image generation tool on 2026-10-12 and encoded as WebP at quality 86. No external artwork is downloaded at runtime.

## Generation prompt

Use case: illustration-story. Asset type: colorful mobile Mahjong game background and home card illustration. Create a richly illustrated Chinese lantern festival garden at blue hour, warm glowing vermilion and gold hanging lanterns across the upper frame, curved traditional pavilion roofs, a small arched bridge over turquoise water, lotus blossoms and flowering plum trees, a few tiny visitors strolling with lanterns in the middle distance. Charming polished hand-painted casual puzzle game artwork, rounded inviting forms, saturated jade teal, coral red, golden amber and twilight indigo. Lively scene with depth and lovely details, lantern reflections in water. Portrait composition 1024x1536, the upper third is an inviting festival scene, quieter dark teal water in the middle/lower center behind an overlaid game board. Full bleed opaque background. No lettering, no logos, no UI, no tiles, no borders, no watermark.

## Tiles and motion

`lantern_art.dart` draws eleven original vector motifs: lantern, lotus, bamboo, moon, plum blossom, koi, fan, cloud, pine, golden knot and star. Shape and numeric labels distinguish pairs independently of color. Free tiles have ivory faces and solid jade bodies; blocked tiles have softly shaded jade faces. Every tile exposes a 3-pixel right edge and 7-pixel bottom edge. Each higher layer sits directly above its support with a 7-pixel rise matching the solid bottom edge and a short contact shadow. Row spacing reserves the full stack height, preventing tiles from covering neighbouring cells. One to four small gold marks identify the layer, also announced in tile semantics and tooltips. Tiles have a 72-pixel minimum pitch height; dense boards scroll on compact screens to keep the symbols readable. Each layout’s tile footprint has equal horizontal margins; collection effects share the same position calculation.

Selection lifts and scales a tile over 180 ms with a gold border and glow. Successful matches hold both highlighted tiles briefly, then float them toward the lanterns with fading gold sparkles over 720 ms. Logical removal is immediate, allowing concurrent matches. Stable tile and collection keys prevent animation state from transferring between tiles. Undo and restart clear transient effects. The final match saves immediately; the completion panel appears after the last flight. Existing persistence retry behavior remains intact.

System and app reduced-motion preferences skip collection flights and selection transitions. Existing haptic preferences remain respected. No new audio is introduced.

## Level progression

The existing `mahjong` ID and level indices 0–29 are retained. Previously completed deals and their results remain credited; replay does not add collection credit. The old mirrored deals are replaced, so replaying an old level now uses its new puzzle. Existing best-move records are retained rather than reset.

| Deals | Difficulty | Tiles | Layers | Base random-play completion |
| --- | --- | --- | --- | --- |
| 1–6 | Gentle | 24–28 | 1 | 87.0% |
| 7–12 | Growing | 32–36 | 2 | 66.6% |
| 13–18 | Thoughtful | 40–44 | 3 | 41.8% |
| 19–24 | Tricky | 48–52 | 3 | 28.0% |
| 25–30 | Expert | 56–60 | 4 | 21.2% |

All 30 layouts are distinct. Seeded growth creates stepped, winding and irregular supported stacks, rather than repeating the same pyramid. Partners are assigned along a verified removal path across arbitrary free positions, not mirrored endpoints. Later boards repeat symbols more often, making the choice of *which* two matching tiles to remove important. Every initial deal has a complete solution; an arbitrary legal choice can still produce a dead end. Unlimited undo and restart remain available. Hints identify a legal pair, not necessarily a winning continuation.

Difficulty rises by band, with variation between deals within a band; individual levels are not guaranteed to be strictly harder than the previous level. The percentages above cover the base layouts without lantern constraints or timers and are a relative planning-demand proxy, not human win rates: 256 deterministic random-legal-pair playthroughs per deal, with a seed different from candidate selection. The tool searches up to 160 candidates per deal using 64 trial games, then measures the selected board on those 256 held-out trials. It does not calibrate human visual-search time. The raw results are in `difficulty-calibration.json`.

`app/lib/games/mahjong/deals.dart` bundles the tile positions, faces, ordered lantern targets and solution witnesses. Only these small immutable data tables are loaded at runtime. Generation, backtracking and calibration run offline, never on the UI isolate. To regenerate from `app/`:

```sh
dart run tool/mahjong_generate.dart
dart format lib/games/mahjong/deals.dart
```

The game-specific difficulty descriptions are supplied to the shared deal menu through optional callbacks; Solitaire keeps its existing descriptions. All deals stay available for replay or for players who want to jump ahead.

## Ordered lanterns and timed levels

- Deals 1–18 remain untimed and have no lantern objective.
- Deals 19–21 require two lanterns to be freed in order; deals 22–27 require three; deals 28–30 require four.
- Deals 25–30 also have time limits of 8:00, 7:00, 6:30, 6:00, 5:30 and 5:00 respectively. These are initial design limits, not calibrated human completion times.

A numbered bulb marker stays on top of each target stack, including when the actual objective tile is buried. Gold marks the next target. A lantern lights when its target tile is free (uncovered with an open side). An attempted pair that would free a later lantern too early is rejected without changing the board or history. Hints consider this rule. A pair may light consecutive objectives together; it cannot skip an unlit earlier objective. Undo restores both tiles and lantern credit.

The offline generator selects initially covered targets from distinct stacks and distinct reveal steps on each deal's known solution path. It verifies the path again with the objective constraints enabled. To update only targets on the existing baked layouts, run `dart run tool/mahjong_generate.dart --objectives-only`, followed by Dart formatting; the full generator also emits targets.

The clock starts with the first free-tile selection or hint, pauses while the game menu is open (including Settings opened from it) and while the app is not resumed, and stops immediately on the final successful pair. Reduced-motion preferences do not speed up the clock. Time expiry disables matching, hints and undo, displays a retry panel and awards no new completion credit. Restart restores the same puzzle, all lanterns and the full time allowance. Undo during a live attempt does not refund time. Existing completion records are retained even if a later replay times out. The win is persisted immediately; collection effects may finish afterward.

## Verification

- Flutter analysis and full app widget/unit suite.
- Dedicated tests for equal tile margins and visible layer ledges on compact, phone, tablet and landscape screens; readable compact tile symbols; collection origins; selected tile scale, overlapping collections, undo during collection, system/app reduced motion, and saving the final pair before its completion animation ends.
- Model tests replay and undo every solution, verify supported stacks, deterministic deals, shape diversity, even symbol counts and low mirror matching, and measure the difficulty curve with another independent set of random games. Widget tests complete narrow, middle and expert deals at 320 × 568 and 130% text, and verify progression descriptions plus retained completion records.
- Challenge tests cover all ordered solution witnesses, atomic wrong-order rejection, hint legality, lantern undo, decreasing time limits, idle start, reduced motion, menu/system-back/background pause and resume, expiry without credit, retry and winning just before the deadline.
- Existing table-game checks cover 320 × 568 at 130% text, portrait, tablet and landscape layouts, library navigation and save retries.
- `gameplay-preview.png` (390 × 844), `compact-preview.png` (320 × 568 at 130% text) and `expert-preview.png` (deal 30 at 320 × 568 and 130% text) are Flutter test-rendered previews with actual artwork and Roboto loaded. They are visual verification, not device performance measurements.

Physical-device animation smoothness and haptic feel have not been verified.
