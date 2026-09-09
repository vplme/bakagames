# Artwork prompt set

Tool: built-in `image_gen.imagegen`, model provenance gpt-image 2.0. Each bird used the generated reference sheet as `referenced_image_paths`. No external character references were used.

## Reference sheet — first generation

> Use case: stylized-concept. Create an original Pocket Aviary character reference sheet: eight tiny collectible birds in a clean 4 by 2 grid on warm ivory, no text. In order red cardinal (pointed crest black mask), yellow canary (round fluffy sunny cheeks), blue jay (swept triangular crest striped tail), green parakeet (slender long tail yellow face), purple owl (ear tufts huge eyes squat body), pink cockatoo (fan crest rosy cheeks), orange finch (round rust wings cream cheek), turquoise kingfisher (long pointed beak short spiky crest). Charming polished storybook game illustration, soft dimensional gouache with crisp silhouettes, dark expressive eyes, joyful distinct personalities. All front three-quarter facing right, full body including two little feet aligned on same baseline, consistent scale and upper-left lighting. Large readable color masses, minimal tiny details, suitable for 48px phone sprites. No branches, no props, no shadows outside birds. This is the reference for subsequent isolated assets.

Saved as `character-reference.png`.

## Cardinal

> Reference image is the Pocket Aviary character identity sheet. Generate a single isolated red cardinal sprite matching its red cardinal exactly, simplified crisp dimensional storybook game artwork readable at 48px, front three-quarter facing right, full body crest tail and two feet, feet at bottom baseline, tightly centered with 5 percent padding, actual transparent background alpha, no ground shadow, no props, no text. Square asset.

## Individual sprite prompt

Separate calls replaced `{species}` with yellow canary, blue jay, green parakeet, purple owl, pink cockatoo, orange finch, and turquoise kingfisher:

> Reference image is the Pocket Aviary character identity sheet. Generate one isolated {species} sprite matching that character, simplified crisp dimensional storybook artwork readable at 48px. Front three-quarter facing right, full crest tail body and TWO feet entirely within frame. Feet at bottom baseline. Centered with 6 percent padding, consistent upper-left lighting. Actual transparent alpha background, no shadow, no props, no text. Square asset.

## Final finch regeneration

Two prior finch candidates were rejected for baked-in checkerboards. This fresh call used the original reference sheet and supplied the final asset:

> Create a transparent PNG sprite of ONE orange finch based on the orange finch character in this reference. This MUST use the image transparency feature: outside the bird alpha=0. No checkerboard pixels, no solid white or gray background. The other seven bird sprites successfully have transparent alpha; this one must match. Full-body round orange finch with cream cheeks, brown orange wings, expressive black eye, little feet at baseline. Front three-quarter facing right. Original polished gouache collectible bird character. Center full silhouette with six percent transparent padding. No props, no ground, no shadow, no text.

## Habitats

Separate new-image calls used the following template:

> Use case: stylized-concept. Pocket Aviary mobile puzzle habitat background. {scene}. Polished soft dimensional gouache storybook game art, original charming miniature world. Portrait 2:3 composition. Keep middle 75 percent extremely quiet low contrast pale open negative space for bird puzzle, foliage only at outer edges, rich lush detail near bottom edge. No birds, no perches, no UI, no text. Upper-left diffuse light, soft painterly shapes.

Scenes:

- Garden: sunny miniature garden with distant soft sage trees, a tiny winding stepping stone path, daisies and ferns in the bottom corners, warm cream sky
- Cherry: miniature cherry blossom grove, pink blossom boughs framing upper corners, tiny mossy stepping stones and petals in lower corners, quiet pale blush sky
- Moon: miniature moonlit forest, indigo foliage framing corners, soft teal ferns and glowing tiny flowers below, crescent moon high above, quiet desaturated blue center

## Final generation provenance

| Asset | Generated source filename |
| --- | --- |
| Reference | exec-5ead45db-7086-459f-bbba-1467c67ce569.png |
| Cardinal | exec-b5d03c8e-592b-4491-a2f3-5293019baf2d.png |
| Canary | exec-0080cb8d-957d-4d8d-96c6-94387340b6e4.png |
| Blue jay | exec-a3d10047-2bdc-45d9-bfb6-9340b5fe60b7.png |
| Parakeet | exec-f3997879-1254-4557-9bbb-7902e16bd16c.png |
| Owl | exec-af50cba4-008f-422c-a28f-6d6cd881d7e8.png |
| Cockatoo | exec-0e1df6b2-ee8a-45b4-8862-52ab5fb85c4f.png |
| Finch | exec-e0568043-ffa2-438d-9dda-7c1071791368.png |
| Kingfisher | exec-7960019f-6935-40a9-b8dd-4127460c9427.png |
| Garden | exec-9537cdd4-1816-497e-864f-33b2bcb6fae6.png |
| Cherry | exec-320461d6-15d5-4c93-9373-c2a2f6b716d0.png |
| Moon | exec-455bf068-ece3-4c8b-b3a9-453790194b74.png |

All final gameplay outputs are bundled in `app/assets/aviary/`; the application never refers to the image tool's output directory.
