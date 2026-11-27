"""Render original VELORA instrumental loops; no samples or third-party recordings.

Usage: python3 create_soundtracks.py /path/to/output-directory
"""
import array
import math
from pathlib import Path
import random
import sys
import wave

RATE = 22050
TAU = math.tau
STYLES = {
    'running': (118, [50, 46, 53, 48]),
    'training': (112, [45, 48, 41, 43]),
    'basketball': (100, [43, 46, 48, 41]),
    'trail': (96, [48, 43, 45, 41]),
    'lifestyle': (108, [53, 48, 50, 46]),
}


def render(name, bpm, roots, directory):
    beat = 60 / bpm
    length = 32 * beat
    samples = array.array('f', [0]) * int(length * RATE)
    rng = random.Random(name)

    def tone(start, duration, midi, gain, bass=False):
        frequency = 440 * 2 ** ((midi - 69) / 12)
        offset = int(start * RATE)
        for i in range(min(int(duration * RATE), len(samples) - offset)):
            t = i / RATE
            envelope = min(t / 0.008, 1) * math.exp(-t * (5 if bass else 9))
            oscillator = math.sin(TAU * frequency * t)
            oscillator += (0.18 if bass else 0.3) * math.sin(TAU * frequency * 2 * t)
            samples[offset + i] += oscillator * envelope * gain

    for step in range(64):
        moment = step * beat / 2
        root = roots[(step // 16) % 4]
        if step % 2 == 0:
            tone(moment, beat * 0.7, root - 12, 0.22, True)
        if step % 8 in (1, 3, 6):
            note = root + [12, 19, 15, 22][(step // 2) % 4]
            tone(moment, beat, note, 0.075)
            tone(moment + beat * 0.75, beat * 0.6, note, 0.025)
        # Synthesized kick, hats and clap; no sampled sounds.
        offset = int(moment * RATE)
        for i in range(min(int(0.22 * RATE), len(samples) - offset)):
            t = i / RATE
            if step % 2 == 0:
                phase = TAU * (48 * t + 70 * (1 - math.exp(-t * 32)) / 32)
                samples[offset + i] += math.sin(phase) * math.exp(-t * 22) * 0.35
            noise = rng.uniform(-1, 1)
            samples[offset + i] += noise * math.exp(-t * 130) * 0.055
            if step % 8 in (2, 6):
                samples[offset + i] += noise * math.exp(-t * 36) * 0.09

    peak = max(abs(value) for value in samples) or 1
    pcm = array.array('h')
    for i, value in enumerate(samples):
        # A short fade prevents clicks when the loop repeats.
        edge = min(1, i / (RATE * 0.02), (len(samples) - i) / (RATE * 0.04))
        pcm.append(int(max(-1, min(1, value / peak * 0.66 * edge)) * 32767))
    target = directory / f'{name}.wav'
    with wave.open(str(target), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(pcm.tobytes())
    print(f'{name}: {bpm} BPM, {length:.1f}s original instrumental')


if __name__ == '__main__':
    output_directory = Path(sys.argv[1])
    output_directory.mkdir(parents=True, exist_ok=True)
    for category, (tempo, progression) in STYLES.items():
        render(category, tempo, progression, output_directory)
