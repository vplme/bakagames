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
