"""Original procedural foley and tonal rewards. Python standard library only."""
import math, random, struct, wave
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2] / 'app/assets'
RATE = 24000
random.seed(42)

def render(theme, name, notes=(), foley=False):
    duration = max([start + 1.35 for start, _, _ in notes] + [.24])
    samples = [0.] * int(RATE * duration)
    for start, midi, gain in notes:
        freq = 440 * 2 ** ((midi - 69) / 12)
        for j in range(int(RATE * 1.35)):
            t = j / RATE
            envelope = min(1, t / .006) * math.exp(-t * (5 if theme == 'mahjong' else 4))
            tone = (math.sin(2 * math.pi * freq * t) + .24 * math.sin(2 * math.pi * freq * (2.76 if theme == 'mahjong' else 2) * t) * math.exp(-t * 9))
            samples[int(start * RATE) + j] += gain * envelope * tone
    if foley:
        for j in range(int(RATE * .14)):
            t = j / RATE
            noise = random.uniform(-1, 1)
            samples[j] += .16 * min(1, t / .002) * math.exp(-t * (65 if theme == 'mahjong' else 32)) * (math.sin(2 * math.pi * 920 * t) if theme == 'mahjong' else noise)
    peak = max(abs(s) for s in samples) or 1
    scale = min(1, .8 / peak)
    with wave.open(str(ROOT / theme / (name + '.wav')), 'wb') as out:
        out.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        out.writeframes(b''.join(struct.pack('<h', round(s * scale * 32767)) for s in samples))

for theme, root in [('mahjong', 74), ('solitaire', 69)]:
    render(theme, 'select', foley=True)
    render(theme, 'move', [(0, root, .14), (.075, root + 7, .12)], True)
    render(theme, 'draw', foley=True)
    render(theme, 'undo', [(0, root + 7, .09), (.09, root, .08)], True)
    render(theme, 'hint', [(0, root + 12, .1), (.17, root + 7, .08)])
    render(theme, 'deal', [(i * .09, root + n, .13) for i, n in enumerate([0, 4, 7])], True)
    for stage in range(4):
        render(theme, f'reward{stage}', [(0, root + [0, 2, 4, 7][stage], .19), (.1, root + [7, 9, 11, 14][stage], .14)], True)
    render(theme, 'milestone', [(i * .12, root + n, .18) for i, n in enumerate([0, 4, 7, 12])])
    render(theme, 'win', [(i * .14, root + n, .19) for i, n in enumerate([0, 4, 7, 12, 7, 16])] + [(1.05, root + n, .13) for n in [0, 7, 12]])
