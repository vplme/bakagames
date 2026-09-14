# Pocket Pusher

First playable machine, registered as `coin_pusher`. Uses Flame 1.38 and
Forge2D 0.13 directly: the older Flame adapter conflicts with Flame's newer
vector types. The physics model does not import Flutter or Flame.

Tap the board to choose a drop position; the Drop button repeats the last
position (centre until the first tap). Coins cost
one; gold pays one and every twelfth drop is a blue coin worth five. Front
exits pay once; side exits are lost. Twenty collected objects award ten extra
coins. An empty wallet can refill forty coins for free. There are no purchases.

The tabletop has no forward gravity. Horizontal movement comes from drops,
pusher contact, and collisions; vertical gravity settles unsupported objects.
The simulation uses upright cylinders with height, gravity, support and contact
friction at 60 fixed steps per second, capped at 160 coins. Height-filtered
Forge2D contacts allow coins to overlap on different layers. Coins can land on
other coins, ride moving supports and fall when unsupported. This simplified
stacking model does not simulate arbitrary rigid-body tilt or tumbling. The
renderer projects the cabinet and solid coin rims into an oblique perspective.
Essential pusher movement remains with reduced motion; falling effects are
suppressed by either the app preference or system disable-animations setting.

One versioned JSON record (`coin_pusher.session.v1`) stores balance, bonus,
collection total, drop count, pusher phase, and each coin's position, velocity,
value, height and vertical velocity. Schema 3 preserves schema 1/2 saves and adds toy IDs, collection counts, the
random generator state, and a one-time starter-prize flag. Writes are serialized, occur after transactions and every two
seconds, and are awaited on normal exit. Backgrounding saves and pauses;
Resume is explicit. Abrupt process termination may lose the latest unsaved
interval. A failed save exposes retry and prevents normal exit. Existing game
progress keys are untouched.

Cabinet geometry, wood grain, daisies and coins are drawn in code.
The cabinet has recessed side loss channels, exposed tabletop edges, and an
open collection tray with a lower floor, side walls and raised front lip. Falling
objects render behind the rails and tray lip. Solid end panels join the side rails to the tray lip so the channel floors do
not leave exposed dark triangles at the front corners. The pastel cabinet uses
mint felt, blush trim, and a rounded cream-edged pink sign with bear mascots.
Title lettering is laid out at pixel scale; decorative yellow bulbs are removed.
The library cover and eleven plush sprites are original AI-generated artwork; see
[artwork.md](artwork.md) for prompts and asset preparation. Sound effects are
original local synthesis; no reference recordings are copied. Regenerate them
with `python3 docs/pusher/generate_audio.py` (standard library only).

The sound palette includes metallic chute clicks and tray clinks, two fuller
cascade tiers, valuable-coin chimes, soft toy arrivals and collection melodies,
quieter coin/toy side losses, reward appearances, bonuses and toy unlocks.
Physics emits transient events for actual spawns and exits; these do not alter
saved progress. The mixer groups events over 90 ms and builds coin cascades
across gaps shorter than 650 ms, using object counts rather than payout values.
Five bounded audio voices separate chute, tray, toys, side losses and rewards.
App sound preferences apply immediately, and pausing, leaving or backgrounding
stops playback. Assets are mono 22.05 kHz PCM with faded tails and headroom.
The previous `coin.wav` is retained but no longer used by Pocket Pusher.

Tests cover one-time payouts, side losses, bonuses, spending, refill,
serialization, sustained pushing, and 320×568 layout at 130% text. Device GPU
performance and sound/haptic feel remain to be verified on physical hardware.

Three large plush prizes can occupy the board at once. Fresh games and migrated
sessions receive three random toys once; every twelve accepted drops attempts to
spawn a replacement if space is available. Each toy has a larger collision radius
and height, rides coin stacks, and is worth five coins plus one collection entry
when it exits at the front. Side exits never add collection credit. Reopening a
session preserves both remaining toys and collected counts. The collection shelf shows starter and milestone toys, including locked states
and duplicate counts.

## Stack and gravity tuning

Coins now drop from a fixed-height chute rather than a height relative to the
pile, with no artificial forward launch velocity. Vertical gravity is 18 board
units/s²; airborne horizontal drag is low, while tabletop drag settles motion.
No forward gravity is applied. Stable supports use a capped friction impulse
with equal reaction on the supporting object. Small overlaps support a landing
briefly but slip sideways when the centre is unsupported; multiple supports can
balance a coin between them. This remains an upright-cylinder approximation,
not full rotating 3D rigid-body physics.

The maximum intended coin stack is three coins (base heights 0, .22, .44).
Drops onto a third layer, an airborne coin or a toy are rejected before spending
currency. Old taller piles and coins that arrive above the limit slide sideways
to settle, preserving all objects and collected progress. Toy bodies retain
their own larger height; they are not counted as single thin coin layers.

## Narrow rear pusher

The central paddle spans x=2.1–7.9 on the 9.5-unit coin bed (about 61%).
Fixed rear shoulders flare outward into the full-width front bed; their
Forge2D boundaries follow the rendered shape. Tap aiming clamps
to the central drop opening (x=2.5–7.5). Existing sessions and collection
records retain their schema and contents. Tests cover central pushing, stationary
outer-bed coins, clamped drops and save roundtrips, alongside the full app suite.
Proportions were informed by the user-provided
[Coin Pusher reference](https://play.google.com/store/apps/details?id=com.CoinGame.CoinPusher&hl=en);
the pastel artwork remains drawn locally in code.

## Toy progression (250–2,000 coins)

Honey Bear, Clover Bunny and Mint Dragon remain available from the start.
Eight additional toys unlock using the existing lifetime `collected` total:

| Lifetime coins | New toy |
| --- | --- |
| 250 | Apricot Fox |
| 500 | Peaches Cat |
| 750 | Pebble Penguin |
| 1,000 | Pistachio Frog |
| 1,250 | Cocoa Otter |
| 1,500 | Bluebell Elephant |
| 1,750 | Starlight Unicorn |
| 2,000 | Petal Axolotl |

Front payouts contribute their coin value (including five-coin toys and blue
coins). Side losses, free refills and bonus awards do not count. Spending and
board resets retain lifetime progress. Existing saves receive earned unlocks
automatically; starter IDs 1–3 and the session key remain unchanged. The schema 3
reader now accepts the eight appended toy IDs as well.

Only unlocked toys can spawn. A newly unlocked, uncollected toy not already on
the board gets priority at the next eligible spawn; the limit stays three toys
on the board. Unlocking does not automatically give collection credit: the toy
still needs to reach the front tray. A Cuddly collection button below the play controls opens a draggable bottom
sheet, matching the Aviary collection pattern. It includes a close button,
scrolling, a progress bar and locked goals, with two columns on compact screens.
The machine pauses while browsing and resumes on dismissal only if it was
previously running, no save error occurred and the app was not backgrounded.

Verification covers every threshold, one-time unlock notifications, spawn
eligibility, new toy save roundtrips, reset retention, excluded progress sources,
and the completed shelf at 320×568 with 130% text. Board edge highlights render
before the raised shoulders so they cannot appear through the walls.

## Combo rewards and depth order

Collect five ordinary/blue coins through the front within one second to earn a
large coin worth 10. Collect ten in that same window to also earn a gold bar
worth 25. The one-second window starts with the first coin, uses fixed simulation
time and pauses with the machine. Each tier fires once per window. Toys, special
rewards, side losses and the ten-coin bonus do not add to the combo count.

Earned rewards drop into the central board area and pay only when pushed into
the front tray. A large coin has radius .65; a bar has an upright, non-rotating
1.6×.8 rectangular collision footprint and height .38. Its stacking/support
checks retain the engine's approximate radial support model. Both are rendered
in code, including their falling visuals. Up to ten special rewards can be
on the board; additional earned rewards wait for a free slot and the overall
160-object cap. Reset clears the active combo and pending rewards along with
the board. Lifetime collections remain.

Schema 3 accepts values 10 and 25 for the new objects and optional combo-count,
remaining-time and queued-reward fields. Older saves default these to zero.
Current and pending rewards survive reopening without duplicate combo awards.

Object drawing sorts by board depth first and height only for equal depth, so
a raised rear toy no longer draws over a nearer toy. Regression checks cover
that overlap, simultaneous and frame-split combos, queued rewards, new payout
values, exclusions and save roundtrips.
