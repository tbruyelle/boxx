#!/usr/bin/env python3
"""Generate sound effects for BoXX game."""

import wave, struct, math, random, os

SAMPLE_RATE = 44100
OUT_DIR = os.path.dirname(__file__)


def write_wav(filename, samples, rate=SAMPLE_RATE):
    path = os.path.join(OUT_DIR, filename)
    with wave.open(path, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(rate)
        data = [int(max(-1, min(1, s)) * 32767) for s in samples]
        f.writeframes(struct.pack('<' + 'h' * len(data), *data))
    print(f"  {filename} ({len(samples)/rate:.2f}s)")


def gen_move():
    """Quick soft whoosh/slide."""
    dur = 0.12
    samples = []
    for i in range(int(dur * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        p = t / dur
        freq = 300 + p * 400
        env = (1 - p) * 0.3
        random.seed(int(t * 8000))
        s = (random.random() * 2 - 1) * 0.5 + math.sin(2 * math.pi * freq * t)
        samples.append(s * env)
    return samples


def gen_fire():
    """Soft pop/thump shot sound."""
    dur = 0.1
    samples = []
    for i in range(int(dur * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        p = t / dur
        freq = 250 - p * 100
        env = (1 - p) ** 3 * 0.25
        s = math.sin(2 * math.pi * freq * t)
        random.seed(int(t * 12000))
        s += (random.random() * 2 - 1) * max(0, 1 - p * 3) * 0.15
        samples.append(s * env)
    return samples


def gen_hit_wall():
    """Dull thud/impact on wall."""
    dur = 0.2
    samples = []
    for i in range(int(dur * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        p = t / dur
        freq = 120 - p * 60
        env = (1 - p) ** 3 * 0.5
        s = math.sin(2 * math.pi * freq * t)
        random.seed(int(t * 20000))
        s += (random.random() * 2 - 1) * (1 - p) ** 4 * 0.3
        samples.append(s * env)
    return samples


def gen_hit_monster():
    """Meaty splat on monster."""
    dur = 0.18
    samples = []
    for i in range(int(dur * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        p = t / dur
        freq = 200 - p * 120
        env = (1 - p) ** 2 * 0.45
        s = math.sin(2 * math.pi * freq * t) * 0.6
        random.seed(int(t * 30000))
        noise = (random.random() * 2 - 1)
        s += noise * (1 - p) ** 2 * 0.5
        s += math.sin(2 * math.pi * 60 * t) * (1 - p) * 0.3
        samples.append(s * env)
    return samples


def gen_cell_fall():
    """Descending tone + thump when cell falls."""
    dur = 0.35
    samples = []
    for i in range(int(dur * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        p = t / dur
        freq = 400 * (1 - p * 0.8)
        env_whistle = max(0, 1 - p * 1.5) * 0.2
        s = math.sin(2 * math.pi * freq * t) * env_whistle
        if p > 0.6:
            impact_p = (p - 0.6) / 0.4
            impact_env = (1 - impact_p) ** 3 * 0.4
            s += math.sin(2 * math.pi * 80 * t) * impact_env
            random.seed(int(t * 15000))
            s += (random.random() * 2 - 1) * (1 - impact_p) ** 4 * 0.15
        samples.append(s)
    return samples


def gen_confirm():
    """Two-note ascending chime for menu transitions."""
    dur = 0.3
    samples = []
    for i in range(int(dur * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        if t < 0.15:
            freq = 523.25  # C5
            env = (1 - t / 0.15) * 0.3
        else:
            t2 = t - 0.15
            freq = 659.25  # E5
            env = (1 - t2 / 0.15) * 0.35
        s = math.sin(2 * math.pi * freq * t) * 0.7
        s += math.sin(2 * math.pi * freq * 2 * t) * 0.2
        s += math.sin(2 * math.pi * freq * 3 * t) * 0.1
        samples.append(s * env)
    return samples


def gen_explosion():
    """Big boom with rumble and noise decay."""
    dur = 0.6
    samples = []
    for i in range(int(dur * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        p = t / dur
        freq = 80 - p * 40
        env = (1 - p) ** 2 * 0.5
        s = math.sin(2 * math.pi * freq * t) * 0.6
        random.seed(int(t * 44100))
        noise_env = max(0, 1 - p * 2) ** 2
        s += (random.random() * 2 - 1) * noise_env * 0.6
        s += math.sin(2 * math.pi * (200 - p * 150) * t) * (1 - p) ** 3 * 0.3
        samples.append(s * env)
    return samples


def gen_victory():
    """Ascending fanfare jingle."""
    dur = 0.6
    notes = [(261.63, 0, 0.12), (329.63, 0.12, 0.12), (392.00, 0.24, 0.12), (523.25, 0.36, 0.22)]
    samples = []
    for i in range(int(dur * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        s = 0.0
        for freq, start, ndur in notes:
            dt = t - start
            if 0 <= dt <= ndur:
                env = 0.35
                if dt < 0.01: env *= dt / 0.01
                if dt > ndur - 0.03: env *= (ndur - dt) / 0.03
                s += math.sin(2 * math.pi * freq * t) * 0.6 * env
                s += math.sin(2 * math.pi * freq * 2 * t) * 0.25 * env
                s += math.sin(2 * math.pi * freq * 3 * t) * 0.15 * env
        samples.append(max(-1, min(1, s)))
    return samples


if __name__ == '__main__':
    print("Generating sound effects:")
    write_wav('sfx_move.wav', gen_move())
    write_wav('sfx_fire.wav', gen_fire())
    write_wav('sfx_hit_wall.wav', gen_hit_wall())
    write_wav('sfx_hit_monster.wav', gen_hit_monster())
    write_wav('sfx_cell_fall.wav', gen_cell_fall())
    write_wav('sfx_confirm.wav', gen_confirm())
    write_wav('sfx_explosion.wav', gen_explosion())
    write_wav('sfx_victory.wav', gen_victory())
    print("Done!")
