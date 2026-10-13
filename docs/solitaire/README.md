# Enchanted Moon Garden

Moonlit Solitaire uses a locally bundled, opaque 1024 × 1536 illustration at `app/assets/solitaire/moon-garden.webp` (approximately 444 KB, WebP quality 86). Created with the built-in image generation tool on 2026-10-13. No remote artwork is loaded at runtime.

## Generation prompt

Use case: illustration-story. Asset type: locally bundled background illustration for a polished mobile card game, Moonlit Solitaire. Create a portrait enchanted moon garden at night, richly painted storybook art with luminous colors and intricate flowers. Large warm ivory crescent moon high in a deep indigo sky, delicate tiny golden stars, turquoise and teal foliage, violet bellflowers and pink blossoms framing the sides, a tranquil reflecting pond opening into the center, one small charming ivory bunny sitting beside the pond near the lower right. Soft golden fireflies, lilac moon glow, jewel blue shadows. Beautiful welcoming magical garden, cozy rather than spooky. Composition: portrait 2:3; detailed botanical framing at edges, luminous crescent in upper quarter, calm darker lower-central pond area with restrained detail to sit behind readable playing cards; useful as both full-screen background and cropped home hero. Painterly premium game illustration, dimensional brushwork, no UI, no playing cards, no lettering, no logos, no watermark. Opaque full-bleed image.

## Implementation

The garden appears on the library preview, scrolling game home, gameplay board, and completion backdrop. Ivory cards retain distinct red and dark suits. Original vector crescent-and-star card backs and the glowing moon pocket complement the illustration. Existing bunny face-card artwork remains. All artwork is opaque; no cutout transparency is required.

Fireflies briefly twinkle on entry (2.8 seconds), then settle. Placing a card on a foundation produces a 650 ms star effect without delaying input. Undo and new deals clear foundation effects. System and app reduced-motion preferences suppress both effects. Sound and haptic preferences are unchanged. Random deals, undo, and last-played ordering remain intact; no level progression is reintroduced.

## Verification

Flutter analysis and the full app test suite, including compact 320 × 568 layouts at 130% text, tablet and landscape boards, scrolling home and rules, reduced motion, reshuffling, and recent-game ordering. `home-preview.png` and `gameplay-preview.png` are Flutter-rendered previews at 390 × 844 logical pixels with the actual bundled artwork and fonts. They are visual checks, not physical-device performance measurements.
