# Baka Games icon

Open `BakaGames.icon` in Apple Icon Composer. It contains three editable SVG layers: golden lower curve in front, coral arc, and the taller indigo stem behind them. The background is warm ivory with an automatic gradient. Native specular effects are enabled, translucency is 35%, and neutral shadow opacity is 65%.

The independent 1024 × 1024 SVG sources are in `layers/`, with copies embedded in the icon bundle. Corners are supplied by the system, not drawn into these layers.

`approved-glass-reference.png` is the image-generation concept approved in the conversation. The vectors recreate its design; Icon Composer supplies native glass lighting, which is softer than the illustrated optical-glass reflections. This is not a pixel-identical reproduction of the raster.

Verified by opening the saved bundle in Icon Composer and inspecting default, dark, and mono previews. All three layers render and remain editable. JSON and embedded SVG files parse successfully. The iOS app now includes `app/ios/Runner/BakaGames.icon`, and all Xcode build configurations select `BakaGames` as the app icon. The older `AppIcon.appiconset` still contains the unused Flutter placeholder. No physical-device verification is recorded here.


## Android

Android uses the same indigo, coral, and gold SVG paths as the integrated iOS icon, on warm ivory (`#FFF7E6`). It is a flat vector adaptation; Apple Icon Composer glass effects are not reproduced.

- Android 8+ uses separate adaptive background and foreground resources, with the mark centered inside the 66dp safe circle on a 108dp canvas.
- Android 13+ also supplies a monochrome silhouette for launcher-controlled themed colors.
- Older Android versions use density-specific PNGs (48, 72, 96, 144, and 192 pixels).
- The manifest continues to reference `@mipmap/ic_launcher`; Android selects the appropriate version automatically.

Regenerate from the integrated iOS SVG sources with `node docs/app-icon/android/generate.cjs` (requires the `sharp` Node package, optionally supplied through `NODE_PATH`). The generator also writes `android/preview.svg` and `android/preview.png`; the latter illustrates circular, rounded-square, and themed masks. Theme preview colors are illustrative; the launcher chooses actual colors. Artwork and mask previews were visually inspected, all Android resource XML parsed successfully, and `flutter build apk --debug` passed. Physical-device launcher verification remains outstanding.
