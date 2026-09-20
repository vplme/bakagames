# Squad Rusher

An offline, portrait-first squad arcade vertical slice for the Baka Games library.
Game ID: `mergefront`. No monetization, timers, accounts, or network calls.

## Play

Deploy three cards, hold anywhere in the lower half of the battlefield, and drag
left or right. Relative steering avoids jumping the squad to a newly placed
finger. Only the first pointer controls movement; cancellation releases it.
Firing is automatic. Mobile enemies that pass outside your squad's lane damage
the base: swarm 2, regular 5, heavy 12. Base health starts at 100 each run; zero
ends the mission even with surviving units. Direct collisions damage the squad
instead. Missed supplies, barrels, barricades and pylons do not damage the base.
Squad armor, shields and healing do not protect or repair the base. The HUD shows
base health and a critical warning at 25, while hit messages show health/shield
loss and casualties for 2.5 seconds, taking priority over gate previews. Wounded
soldiers have small health bars. Results show escapes, remaining base health and
the reason for defeat. All damage feedback works with reduced motion.
 The next gate's selected outcome appears below the field.
The formation center chooses exactly one gate when it crosses the gate line.
Staying on the center divider misses both gates. Equal recruitment outcomes at
capacity are replaced with protection versus power before their preview appears.
Full-health healing gates become armor (or an elite when already armored);
owned spread, piercing and armor abilities become damage. Duplicate outcomes
become an elite tradeoff. Offers lock before preview.

Mission one opens with recruits versus multiplication at four seconds, then +40% fire
rate with a −15% shot-damage cost versus +20% damage at thirteen seconds. Every mission includes the full gate rotation, trading healing, recruitment,
armor, piercing, spread, and elite firepower. The boss arrives at 116–128 seconds;
the encounter ends by 164–176 seconds. The timer is a run limit, not an energy
system. Losing still earns a card and coins. Restarting or abandoning an unfinished
run earns nothing and consumes nothing.

Tap inventory cards to equip or unequip. Hold and drag matching cards together to
merge, or use the accessible **Merge** button followed by the matching card. A
merge consumes two identical roles/ranks and creates the next rank, capped at six.
The upgraded card inherits equipment status. Three distinct victories unlock one
additional slot, up to six. A replay earns ordinary rewards but no first-clear
bonus or additional milestone credit.

Pause is beside the squad counter. Options contain master sound, separate music
and effects, haptics, shared reduced motion, a role guide, and steering sensitivity.
Losing app focus pauses play and audio; resuming requires an explicit action.
Menus scroll at large text sizes. Gameplay is constrained to a portrait aspect
ratio even inside a wider host window, without changing other games' orientation.

## Code and balance

- `app/lib/games/mergefront/model.dart`: Flutter-free deterministic model, twenty
  named seeds, inventory, gates, fixed-step combat, damage and rewards.
- `mergefront_game.dart`: registration, loadout, touch/lifecycle integration,
  results, settings and persistence. Rendering uses a bounded `CustomPainter`;
  this scene does not need Flame's component or physics machinery.
- `art.dart`: original vector kit, cards, library/landing illustration, battlefield,
  formations, merge reveal, effects and two boss designs.
- `audio.dart`: local sound playback, throttling, preference/lifecycle handling,
  pitch variation and event ducking.

The model takes 1/60-second steps with a 250 ms catch-up cap. There is no costly
level search or generation: a seeded PRNG selects from a small encounter table.
Per-tick work is bounded by 24 soldiers, 48 enemies, 72 shot traces, 36 impact
effects and six warnings. This small simulation runs on the UI isolate; future
expensive generation, search or large-scale simulation must use a top-level
isolate worker with sendable data. No soldier pathfinding or physics bodies exist.
Shots are visual traces of resolved hits, so frame rate does not alter damage.

Important tuning values:

| Variable | Initial value / rule |
| --- | --- |
| Initial equipped units | Rifle, Scatter, Heavy |
| Formation cap | 24 combat units; no visual-only inflation |
| Rifle / Scatter / Heavy / Support / Drone shot damage | 7 / 5 / 27 / 4 / 8 |
| Shot intervals | .7 / 1.05 / 1.7 / 1.3 / .85 seconds |
| Rank damage | base × 1.65^(rank − 1) |
| Shield enemy resistance | 70%; drone and piercing bypass |
| Armor | 35% incoming damage reduction |
| Support shield | 24 every five seconds, capped at 100 |
| Permanent boosts | damage +16% × sqrt(upgrades), health +18% × sqrt(upgrades) |
| Upgrade price | 45 + 35 × purchased upgrades of that stat |
| Coins | 12 + 2 × kills + supplies + 45 victory + 35 first clear |
| Cards | one on loss, two on victory; role disclosed before deployment |

Waves arrive about every 2.1 seconds initially, accelerating through the run,
with short recovery windows. Groups contain two enemies early, three later, or
five swarm units. Shield groups enter after 35 seconds, ranged groups after 45,
and heavies after 60, including mission one. Supplies arrive every sixth wave;
barrels and later-mission pylons punctuate pressure. Enemies move faster and gain
health over the run. Bosses receive reinforcements every 5.5 seconds and attack
every 2.8 seconds; telegraphed hits deal 38 + 2.5 × mission index damage.
The remaining fifteen named seeds remix encounters with increasing spawn pressure.
They are content-ready remixes, not fifteen independently art-directed campaigns.
Boss designs are Bellcrab and Kite Engine. Patterns include an aimed lane, center
pressure, and a two-edge sweep with an open center; warnings precede damage by
1.4–1.5 seconds. Late-game human difficulty still needs device playtesting.

## Persistence and failures

`mergefront.profile.v1` stores a versioned JSON snapshot of cards, equipped IDs,
coins, upgrades, distinct completed levels, best kill counts, run count, music,
effects and sensitivity. Shared sound/haptic/motion settings retain their existing
app-wide keys. Saves include both reward and milestone changes in one write.
Run rewards are applied once in memory. Results navigation and inventory mutations
are disabled while saving or after failure; **Retry save** writes the same current
snapshot without issuing another reward. Load failure offers retry and never
silently resets an existing profile. Mid-run combat is intentionally not restored
after process death; the persisted loadout and previously earned progress survive.

## Assets, provenance and licensing

All Mergefront media was created specifically for this implementation. No reference
screenshots, game assets, music samples, sound libraries, branded equipment or
recognizable melodies were used. The new procedural artwork and generated WAV
assets are offered under **CC0-1.0**. Existing app code and third-party packages
retain their respective licensing; this does not relicense them.

The vector kit uses geometric silhouettes with cyan/cream toy bodies, upper-left
highlights, navy equipment and warm ground shadows. Five roles each have six ranks:
crest, shoulder plates, pack, antenna and crown fins add geometry as rank increases.
Enemy roles use five silhouettes, and the two bosses have separate chassis shapes.
Five mission settings (sunlit coast, overgrown gardens, desert ruins, copper
foundry and moonlit harbor) have distinct surfaces and roadside scenery. The
selected mission previews its setting before deployment. `terrain.dart` draws
the additional environments; `Level.style` assigns settings to all twenty missions.
These are visual styles; collision lanes and encounter balance stay the same.
Coastal color palettes, layered water and foam, beveled stone slabs, cracks,
drainage slots, mooring posts, leafy planters, chest vents and armor fasteners
add locally drawn detail. Terrain, gates, crates, barrels, pylons, barricades, shot traces, muzzle flashes,
shields and impact bursts are drawn locally. Mission previews reuse this kit.
The library card uses an original AI-generated toy-diorama illustration bundled
as `app/assets/mergefront/squad-rusher-cover.webp`; see [the generation prompt](cover-prompt.md).
The cover is opaque and optimized locally; gameplay retains its vector artwork.
There are no external fonts or runtime asset downloads. Flutter's built-in Material icons label menus.

`app/tool/mergefront_audio.dart` reproducibly synthesizes mono 22,050 Hz 16-bit WAVs
in `app/assets/mergefront/`. Run it from `app/` with
`dart run tool/mergefront_audio.dart`. `coast_loop.wav` is an eight-bar 128 BPM
original plucked-sine/bass/percussion loop. The boss arrangement adds rounded tonal
accents. Gate, merge, toy snap, heavy thump, scatter burst, shields, recruits, preview,
coins, UI, enemy pop, warning pulse, victory and defeat use oscillator envelopes.
These are small original synthesized assets that can be replaced with richer
recordings. Events duck music, repeated shots are throttled, and effects vary pitch
and volume slightly. Major cues suppress repetitive effects briefly to stay audible.

Reduced motion removes idle bounce, terrain scrolling, recoil/muzzle decoration,
impact particles and merge movement. Essential movement, shots, gate labels,
warnings, counters and results remain visible. There is no camera shake or zoom.

## Extending the slice

Add a `Level` with a unique seed/name/lesson; adjust unlock limits alongside the
list if going beyond twenty. Add authored gate pairs in the run constructor and
encounter recipes in `_tick`; keep effects outside random selection so audio and
motion preferences cannot change the seeded run.

For a unit role, update `Role`, `RoleInfo`, the damage/interval/range tables,
`paintUnit`, reward mapping and serialization migration. For a gate, extend
`GateKind`, label/headline/caption/preview and `Run.apply`; test arithmetic and caps.
For an enemy, extend `EnemyKind`, spawn health, behavior, renderer and targeting
tests. Preserve enum ordering for existing saved data, or migrate the schema.
For sound, add a procedural asset or a documented original local recording, map
the event in `MergefrontAudio`, and retain master mute and lifecycle checks.

## Verification

Run from `app/`: `flutter analyze` and `flutter test`.

Squad Rusher naming and environment revision verified on 2026-09-20: clean
analysis and all 101 app tests passing. All five settings were rendered and
visually inspected in preview and combat. Previous slice verification also included a successful
`flutter build apk --debug --no-pub`; that APK predates this revision. APK: `app/build/app/outputs/flutter-apk/app-debug.apk`.
The visual atlas was rendered and inspected on the actual coastal background.
Audio media totals about 1.6 MB, including both music arrangements.

Model tests cover gate ordering, merge eligibility/results, capacity, range and
shield rules, support/armor, deterministic waves, rewards, one-time milestones,
serialization, and a steering strategy that wins the first five starter missions.
Widget tests cover library launch, steering and multitouch cancellation, one-gate
activation, pause/restart/lifecycle, merging, save failure/retry, real run completion
and replay, settings, reduced motion and 320×568 at 130% text. Tests use bounded
pumps, never `pumpAndSettle` for active scenes.

`MERGEFRONT_CAPTURE=1 flutter test test/mergefront_visual_test.dart` optionally
writes `/tmp/mergefront-visual.png`, showing all thirty role/rank treatments and a
coastal battlefield for inspection. It also writes `/tmp/squad-rusher-settings.png`
with previews and combat views of all five settings. The capture font is a local test-only system
font, never bundled in the app.

Framework tests and the simulated steering agent do not establish GPU performance,
human difficulty or physical-device audio/haptic feel. Those remain device checks.
