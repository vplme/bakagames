"""Original Pocket Pusher Foley and musical rewards; standard library only.

Deterministic modal metal, filtered noise, soft impacts and bell partials.
Run from any directory to regenerate the bundled 22.05 kHz mono PCM assets.
"""
import math
from pathlib import Path
import random
import struct
import wave

RATE = 22050
OUT = Path(__file__).resolve().parents[2] / 'app/assets/pusher'
rng = random.Random(731)


def render(name, hits, duration):
    samples = [0.0] * int(RATE * duration)
    for start, frequency, gain, material in hits:
        length = .42 if material == 'metal' else .6
        previous = 0
        for i in range(int(RATE * length)):
            index = int(start * RATE) + i
            if index >= len(samples):
                break
            t = i / RATE
            attack = min(1, t / .002)
            noise = rng.uniform(-1, 1)
            soft_noise = (noise + previous) * .5
            previous = noise
            if material == 'metal':
                # Inharmonic coin resonances, a contact click and low tray body.
                signal = sum(a * math.sin(2 * math.pi * frequency * r * t)
                             * math.exp(-t * d)
                             for r, a, d in [(1, .48, 17), (1.47, .23, 23),
                                             (2.09, .10, 32)])
                signal += .25 * soft_noise * math.exp(-t * 150)
                signal += .22 * math.sin(2 * math.pi * 170 * t) * math.exp(-t * 45)
            elif material == 'soft':
                signal = .7 * math.sin(2 * math.pi * (frequency * t +
                          2 * (1 - math.exp(-t * 30)))) * math.exp(-t * 20)
                signal += .3 * soft_noise * math.exp(-t * 35)
            else:
                signal = sum(a * math.sin(2 * math.pi * frequency * r * t)
                             * math.exp(-t * d)
                             for r, a, d in [(1, .7, 8), (2, .15, 14), (3, .05, 20)])
            samples[index] += gain * attack * signal
    peak = max(abs(s) for s in samples) or 1
    scale = min(1, .85 / peak)
    # Fade tails to zero; headroom remains for overlapping playback voices.
    pcm = [int(s * scale * min(1, (len(samples) - i - 1) / 400) * 32767)
           for i, s in enumerate(samples)]
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))


render('insert', [(0, 1550, .55, 'metal'), (.065, 1100, .23, 'metal')], .3)
render('collect', [(0, 1250, .65, 'metal'), (.055, 1875, .32, 'metal'),
                   (.11, 940, .18, 'metal')], .48)
for name, count in [('cascade', 5), ('cascade_big', 10)]:
    hits = [(i * .038, rng.uniform(950, 2300), .48, 'metal') for i in range(count)]
    hits += [(.03, 523.25, .22, 'bell'), (.13, 783.99, .22, 'bell')]
    render(name, hits, .85)
render('valuable', [(0, 900, .6, 'metal'), (.06, 659.25, .4, 'bell'),
                    (.14, 987.77, .3, 'bell')], .8)
render('side', [(0, 750, .4, 'metal'), (.06, 510, .3, 'metal'),
                (.14, 280, .25, 'soft')], .42)
render('toy_side', [(0, 180, .6, 'soft'), (.12, 110, .35, 'soft')], .45)
render('toy_spawn', [(0, 220, .45, 'soft'), (.06, 659.25, .35, 'bell'),
                     (.15, 880, .3, 'bell')], .75)
for name, notes in [('toy_collect', [523.25, 659.25, 783.99, 1046.5]),
                    ('reward_spawn', [392, 587.33, 783.99]),
                    ('bonus', [659.25, 783.99, 1046.5]),
                    ('unlock', [523.25, 659.25, 783.99, 1046.5, 1318.51])]:
    hits = [(0, 160, .5, 'soft')]
    hits += [(i * .09 + .03, f, .42, 'bell') for i, f in enumerate(notes)]
    render(name, hits, 1.1)
