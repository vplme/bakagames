# Pocket Sweets artwork prompts — 2026-09-11

Generated with the built-in `image_gen` tool, not the CLI/API fallback.
No existing artwork was supplied as a reference. Runtime files are locally bundled.

## Candy garden

Output: `app/assets/sweets/garden.webp` (1024×1536, WebP quality 86).
Original generation: `exec-c308e046-ba9c-4e30-b08f-afc82b74f57d.png`.

> Use case: stylized-concept. Asset type: original mobile match-three game background illustration for Pocket Sweets. Create a premium, joyful candy garden at twilight, portrait 1024x1536. Soft sculpted 3D confectionery, raspberry-pink candy hills, lavender sky, peach clouds, glossy jewel-like gumdrops, striped candy canes and tiny sugar stars at the extreme edges. A dreamy pink candy-shop pavilion in the lower corner. Luminous saturated raspberry, plum, turquoise accents and warm buttercream. Composition: center 70 percent remains calm smooth lavender-to-pink atmospheric negative space for a readable game board and UI; detailed scenery mostly on bottom 20 percent and outer edges. Gentle cinematic lighting, polished tactile materials, delightful and sophisticated, not noisy. No text, no lettering, no logos, no UI, no checkerboard. Opaque full bleed background.

## Candy sprite atlas

Output: `app/assets/sweets/candy-atlas.webp` (768×512, lossless WebP after Lanczos
reduction from 1536×1024). Equal 3×2 grid, row-major order: heart, leaf, star,
hexagon, drop, rainbow. The runtime crops five percent from each cell edge to
reduce padding. Stripe markings are drawn in Flutter; rainbow pieces show a small
base-type candy badge so the underlying type remains distinguishable by shape.

Original generation: `exec-5015d5c2-9ecd-468f-bed9-b5548a467eed.png`.
Verified RGBA alpha: 916,297 fully transparent source pixels, 623,078 above alpha
240. Sampled outer corners and grid gutters have alpha zero. Colored RGB values
under transparent pixels are not a visible backdrop. Alpha was preserved during
optimization, and edges were inspected on the actual plum gameplay board.

> Use case: stylized-concept. Asset type: one production sprite atlas for an original mobile match-three game, Pocket Sweets. A precisely aligned 3-column by 2-row sprite sheet, landscape 1536x1024, SIX separate glossy candy pieces, each centered within its own equal 512x512 cell and occupying 70 percent of cell width/height, generous empty gutters, nothing crossing cell edges. Reading order: top left raspberry red plump HEART gummy; top middle emerald mint green single LEAF-shaped candy with one sculpted vein; top right saturated violet plump five-point STAR gummy; bottom left golden honey-orange beveled HEXAGON hard candy; bottom middle cyan-blue plump TEARDROP gummy pointed at top; bottom right rainbow swirl spherical BONBON. Candy-shop jewel quality: juicy translucent edges, thick rounded sculpted silhouettes, bright clean specular highlight on upper left, subtle inner glow, deep saturated edges, soft self-shadow on each candy only. Front-facing orthographic consistent scale and lighting, readable at 40 pixels, no faces, no wrappers, no text, no extra objects or particles. Genuinely TRANSPARENT background with actual alpha channel, no white matte, no checkerboard pixels, no environment, no cast ground shadow. Precise equal-grid atlas, no borders.

## Validation

Rendered gameplay at 390×844 and compact controls at 320×568 with 130% text.
Inspected real sprite shapes and alpha edges, landing art, and full-height backdrop.
`gameplay-preview.png` is a Flutter test render using Arial substituted for Roboto
for local visual inspection, not a physical-device screenshot or performance claim.
Sugar bursts are bounded to 420 ms and suppressed by reduced-motion settings.
