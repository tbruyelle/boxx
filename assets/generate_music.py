#!/usr/bin/env python3
"""Generate chiptune music loop for BoXX game."""

import wave, struct, math, random

SAMPLE_RATE = 44100
BPM = 140
BEAT = 60.0 / BPM
BAR = BEAT * 4
TOTAL_BARS = 16
DURATION = TOTAL_BARS * BAR

NOTE = {
    'C3': 130.81, 'D3': 146.83, 'E3': 164.81, 'F3': 174.61, 'G3': 196.00, 'A3': 220.00, 'B3': 246.94,
    'C4': 261.63, 'D4': 293.66, 'E4': 329.63, 'F4': 349.23, 'G4': 392.00, 'A4': 440.00, 'B4': 493.88,
    'C5': 523.25, 'D5': 587.33, 'E5': 659.25, 'F5': 698.46, 'G5': 783.99, 'A5': 880.00,
}


def square_wave(freq, t, duty=0.5):
    if freq == 0: return 0
    phase = (t * freq) % 1.0
    return 0.3 if phase < duty else -0.3


def triangle_wave(freq, t):
    if freq == 0: return 0
    phase = (t * freq) % 1.0
    return (4 * abs(phase - 0.5) - 1) * 0.25


def saw_wave(freq, t):
    if freq == 0: return 0
    phase = (t * freq) % 1.0
    return (phase * 2 - 1) * 0.15


def envelope(t, note_start, note_dur, attack=0.01, release=0.05):
    dt = t - note_start
    if dt < 0 or dt > note_dur: return 0
    if dt < attack: return dt / attack
    if dt > note_dur - release: return (note_dur - dt) / release
    return 1.0


# Section A melody (bars 0-3)
melody_a = [
    ('E4', 0, BEAT*0.8), ('G4', BEAT, BEAT*0.8), ('A4', BEAT*2, BEAT*0.8), ('G4', BEAT*3, BEAT*0.5),
    ('E4', BAR, BEAT*0.8), ('D4', BAR+BEAT, BEAT*0.8), ('C4', BAR+BEAT*2, BEAT*1.5), ('D4', BAR+BEAT*3.5, BEAT*0.4),
    ('E4', BAR*2, BEAT*0.8), ('G4', BAR*2+BEAT, BEAT*0.8), ('A4', BAR*2+BEAT*2, BEAT*0.8), ('B4', BAR*2+BEAT*3, BEAT*0.8),
    ('C5', BAR*3, BEAT*1.5), ('B4', BAR*3+BEAT*2, BEAT*0.8), ('A4', BAR*3+BEAT*3, BEAT*0.8),
]

# Section B melody (bars 4-7) - higher energy
melody_b = [
    ('C5', 0, BEAT*0.6), ('D5', BEAT*0.75, BEAT*0.6), ('E5', BEAT*1.5, BEAT*0.8), ('D5', BEAT*2.5, BEAT*0.5), ('C5', BEAT*3, BEAT*0.8),
    ('A4', BAR, BEAT*0.8), ('B4', BAR+BEAT, BEAT*0.6), ('C5', BAR+BEAT*1.75, BEAT*0.6), ('E5', BAR+BEAT*2.5, BEAT*1.2),
    ('G5', BAR*2, BEAT*0.5), ('E5', BAR*2+BEAT*0.75, BEAT*0.5), ('D5', BAR*2+BEAT*1.5, BEAT*0.8), ('C5', BAR*2+BEAT*2.5, BEAT*0.5), ('D5', BAR*2+BEAT*3, BEAT*0.8),
    ('E5', BAR*3, BEAT*1.0), ('C5', BAR*3+BEAT*1.5, BEAT*0.5), ('A4', BAR*3+BEAT*2, BEAT*0.6), ('G4', BAR*3+BEAT*3, BEAT*0.8),
]

# Section C melody (bars 8-11) - breakdown, sparser
melody_c = [
    ('C4', 0, BEAT*1.5), ('E4', BEAT*2, BEAT*1.5),
    ('G4', BAR, BEAT*1.5), ('A4', BAR+BEAT*2, BEAT*0.8), ('G4', BAR+BEAT*3, BEAT*0.8),
    ('F4', BAR*2, BEAT*1.5), ('E4', BAR*2+BEAT*2, BEAT*1.5),
    ('D4', BAR*3, BEAT*0.8), ('E4', BAR*3+BEAT, BEAT*0.8), ('G4', BAR*3+BEAT*2, BEAT*0.5), ('A4', BAR*3+BEAT*2.75, BEAT*0.5), ('B4', BAR*3+BEAT*3.5, BEAT*0.4),
]

# Section D melody (bars 12-15) - climax, fast arpeggios
melody_d = [
    ('C5', 0, BEAT*0.4), ('E5', BEAT*0.5, BEAT*0.4), ('G5', BEAT, BEAT*0.4), ('E5', BEAT*1.5, BEAT*0.4), ('C5', BEAT*2, BEAT*0.8), ('B4', BEAT*3, BEAT*0.8),
    ('A4', BAR, BEAT*0.4), ('C5', BAR+BEAT*0.5, BEAT*0.4), ('E5', BAR+BEAT, BEAT*0.4), ('C5', BAR+BEAT*1.5, BEAT*0.4), ('A4', BAR+BEAT*2, BEAT*1.5),
    ('G4', BAR*2, BEAT*0.4), ('B4', BAR*2+BEAT*0.5, BEAT*0.4), ('D5', BAR*2+BEAT, BEAT*0.4), ('G5', BAR*2+BEAT*1.5, BEAT*0.8), ('E5', BAR*2+BEAT*2.5, BEAT*0.5), ('D5', BAR*2+BEAT*3, BEAT*0.8),
    ('C5', BAR*3, BEAT*0.8), ('E5', BAR*3+BEAT, BEAT*0.8), ('G5', BAR*3+BEAT*2, BEAT*0.6), ('A5', BAR*3+BEAT*2.75, BEAT*1.0),
]

sections_melody = [melody_a, melody_b, melody_c, melody_d]

# Bass progressions per section (one note per bar)
bass_a = ['C3', 'G3', 'A3', 'F3']
bass_b = ['A3', 'F3', 'C3', 'G3']
bass_c = ['C3', 'E3', 'F3', 'G3']
bass_d = ['C3', 'A3', 'G3', 'C3']
sections_bass = [bass_a, bass_b, bass_c, bass_d]

# Arpeggio chords per section (triads)
arp_a = [['C4','E4','G4'], ['G3','B3','D4'], ['A3','C4','E4'], ['F3','A3','C4']]
arp_b = [['A3','C4','E4'], ['F3','A3','C4'], ['C4','E4','G4'], ['G3','B3','D4']]
arp_c = [['C4','E4','G4'], ['E3','G3','B3'], ['F3','A3','C4'], ['G3','B3','D4']]
arp_d = [['C4','E4','G4'], ['A3','C4','E4'], ['G3','B3','D4'], ['C4','E4','G4']]
sections_arp = [arp_a, arp_b, arp_c, arp_d]

# Drum patterns vary per section
sections_kick = [
    [0, BEAT*2],                    # A: standard
    [0, BEAT*1.5, BEAT*2],          # B: denser
    [0, BEAT*2.5],                  # C: sparse
    [0, BEAT, BEAT*2, BEAT*3],      # D: four on the floor
]
sections_snare = [
    [BEAT, BEAT*3],                 # A: standard backbeat
    [BEAT, BEAT*2.5, BEAT*3.5],     # B: syncopated
    [BEAT*2],                       # C: half time
    [BEAT, BEAT*3],                 # D: standard backbeat
]


def generate():
    samples = []
    num_samples = int(DURATION * SAMPLE_RATE)

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        sample = 0.0

        section_idx = int(t / (BAR * 4)) % 4
        t_section = t % (BAR * 4)
        t_in_bar = t % BAR
        bar_in_section = int(t_section / BAR) % 4

        melody = sections_melody[section_idx]
        bass_seq = sections_bass[section_idx]
        arp_chords = sections_arp[section_idx]
        kick_pattern = sections_kick[section_idx]
        snare_pattern = sections_snare[section_idx]

        # Melody (square wave, varying duty per section)
        duty = [0.25, 0.35, 0.15, 0.5][section_idx]
        for note_name, start, dur in melody:
            freq = NOTE[note_name]
            env = envelope(t_section, start, dur)
            if env > 0:
                sample += square_wave(freq, t, duty) * env * 0.35

        # Bass
        bass_freq = NOTE[bass_seq[bar_in_section]]
        bass_env = envelope(t_in_bar, 0, BAR * 0.9, 0.01, 0.1)
        sample += triangle_wave(bass_freq, t) * bass_env * 0.45

        # Arpeggios (sections B and D only, 16th notes cycling through chord)
        if section_idx in [1, 3]:
            chord = arp_chords[bar_in_section]
            sixteenth = BEAT * 0.25
            arp_idx = int(t_in_bar / sixteenth) % len(chord)
            arp_freq = NOTE[chord[arp_idx]]
            arp_pos = int(t_in_bar / sixteenth) * sixteenth
            arp_env = envelope(t_in_bar, arp_pos, sixteenth * 0.8, 0.005, 0.02)
            sample += saw_wave(arp_freq, t) * arp_env * 0.25

        # Drums
        for kt in kick_pattern:
            dt = t_in_bar - kt
            if 0 <= dt < 0.1:
                sample += math.sin(2 * math.pi * (160 - dt*800) * dt) * (1 - dt/0.1) * 0.35

        for st in snare_pattern:
            dt = t_in_bar - st
            if 0 <= dt < 0.08:
                random.seed(int(dt * 44100))
                sample += (random.random()*2-1) * (1 - dt/0.08) * 0.2

        # Hi-hats (8th notes, quieter on breakdown)
        hihat_vol = 0.06 if section_idx == 2 else 0.1
        for h in range(8):
            ht = BEAT * h * 0.5
            dt = t_in_bar - ht
            if 0 <= dt < 0.03:
                random.seed(int(t * 44100))
                sample += (random.random()*2-1) * (1 - dt/0.03) * hihat_vol

        sample = max(-1, min(1, sample))
        samples.append(int(sample * 32767))

    return samples


if __name__ == '__main__':
    import os
    samples = generate()
    out_path = os.path.join(os.path.dirname(__file__), 'music_loop.wav')
    with wave.open(out_path, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        f.writeframes(struct.pack('<' + 'h' * len(samples), *samples))
    print(f"Generated {DURATION:.1f}s music ({len(samples)} samples, {TOTAL_BARS} bars, 4 sections)")
    print(f"Output: {out_path}")
