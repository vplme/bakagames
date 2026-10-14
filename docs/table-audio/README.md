# Lantern and moon garden sound design

Original, locally synthesized mono PCM WAV effects (24 kHz, 16 bit); no third-party recordings or runtime synthesis. Rebuild with `python3 docs/table-audio/generate.py` from the repository root. The deterministic generator uses only Python's standard library.

Mahjong uses short wooden tile attacks and bell overtones. Successful matches rise through four pentatonic stages as the board clears, lantern objectives receive a four-note flourish, and clearing the garden resolves into a longer chord.

Solitaire uses quiet paper-like noise and warm harp harmonics. Moving cards receives a small two-note response, revealing hidden cards earns a brighter reward, and foundation pitches rise with rank. Completing a suit gets a flourish; completing all foundations gets the full cadence. The moon pocket has a delicate two-note cue. Draw, recycle, undo, hint, and new-deal actions have restrained feedback.

Touch and reward playback use separate bounded voices. Muting, opening the game menu, backgrounding, and disposing the screen stop playback. Failed moves do not earn reward sounds. No background music loop.

Validation: modified Dart files pass static analysis; WAV files checked for format, non-silence, and peak headroom. Physical-device listening is still needed to assess volume, latency, and feel.
