"""Original local sine-tone effects for Pocket Sweets (Python standard library)."""
import math
from pathlib import Path
import struct
import wave

OUT = Path(__file__).resolve().parents[2] / 'app/assets/sweets'
OUT.mkdir(parents=True, exist_ok=True)
for name, notes in [('match', [660, 880]), ('complete', [523.25, 659.25, 783.99, 1046.5])]:
    rate = 22050
    samples = []
    duration = .10 if name == 'match' else .16
    for frequency in notes:
        for i in range(int(rate * duration)):
            t = i / rate
            envelope = min(1, t / .008) * (1 - t / duration) ** 2
            signal = math.sin(2 * math.pi * frequency * t)
            samples.append(int(signal * envelope * .22 * 32767))
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as output:
        output.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(samples), *samples))

# Rising C-major pentatonic candy chimes. A soft pitch-dropping pop anchors
# each hit; staggered upper partials add sparkle without a harsh attack.
for tier, midi in enumerate([76, 79, 81, 84, 88], start=1):
    rate = 22050
    duration = .28
    samples = []
    frequency = 440 * 2 ** ((midi - 69) / 12)
    for i in range(int(rate * duration)):
        t = i / rate
        signal = 0.0
        for ratio, delay, gain in [(1, 0, .30), (2, .018, .075), (3, .036, .025)]:
            age = t - delay
            if age >= 0:
                envelope = min(1, age / .004) * math.exp(-age * 19)
                signal += gain * envelope * math.sin(2 * math.pi * frequency * ratio * age)
        signal += .12 * math.exp(-t * 65) * math.sin(2 * math.pi * (180 * t + 3 * (1 - math.exp(-40 * t))))
        signal *= min(1, (duration - t) / .025)
        samples.append(int(signal * 32767))
    with wave.open(str(OUT / f'cascade_{tier}.wav'), 'wb') as output:
        output.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(samples), *samples))
