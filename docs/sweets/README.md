# Pocket Sweets assets

Original candy artwork was generated with the built-in image generation tool.
[Exact prompts and generation records](artwork-prompts.md) document provenance,
alpha verification, atlas layout, optimization, and visual QA.

- [`candy-atlas.webp`](../../app/assets/sweets/candy-atlas.webp): six glossy candy sprites, actual transparency, about 272 KB.
- [`garden.webp`](../../app/assets/sweets/garden.webp): candy garden background, about 143 KB.
- [`gameplay-preview.png`](gameplay-preview.png): rendered app preview.

`SweetPiece` shares one cached atlas across the board; shape IDs and names remain
stable. Stripe orientation and rainbow base-type badges are drawn by Flutter.
Bounded sugar bursts run only during clearing; reduced motion suppresses them.
All image and audio assets load locally, without networking or new permissions.

`generate_audio.py` produces the original two-note match and four-note completion
sounds in `app/assets/sweets/`, using sine tones and an amplitude envelope.
No recordings or samples are used. Run `python3 docs/sweets/generate_audio.py` to
reproduce the mono 22,050 Hz WAVs, including five rising pentatonic cascade
chimes with soft pops and bell harmonics. Each disappearing wave plays once;
special/create snapshots do not double-trigger audio. Pitch caps at tier five,
and completion plays after resolution. Reduced motion uses one summary cue. They honor the shared sound preference;
physical-device listening and haptic checks remain outstanding.

## Library and home layout

The home now follows Pocket Aviary's structure while retaining the candy garden
and its own palette. See [home-preview.png](home-preview.png) and
[entry-preview.png](entry-preview.png) for Flutter test renders with a local font
substitution. `SweetsHero` composes existing sprites on a cream candy tray; no new
raster generation was needed. These are visual QA renders, not device captures.

## Campaign progression

The campaign now has 90 stable level indices. Caramel diamond unlocks at level
46, raspberry ring at 61, and peach twist at 76. Striped sweets unlock at
level 16 and rainbow sweets at level 31: one unlock after every 15 levels. These original vector sweets
are painted locally by Flutter with distinct silhouettes. The engine uses each
level's target count to restrict both initial pieces and refills to unlocked
varieties. Later levels have larger collection goals and up to eight varieties.
Original level seeds and saved progress IDs remain stable.

The Sweet Guide combines unlock status and instructions for every progression sweet.
Matched caramel lines clear direct neighbors of the middle sweet; raspberry lines
clear diagonal neighbors; peach lines clear two cells on each horizontal side.
Each run triggers once, with no wrapping at edges or recursive variety activation.
Caught striped and rainbow sweets still activate, and newly created specials survive. Atlas sprites are positioned using
the centers of their visible alpha bounds, correcting the heart's offset without
changing the source artwork. Undo and restart are tested at each unlock boundary;
the full campaign is checked for deterministic, legal completion by hint play.
