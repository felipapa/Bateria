"""Measure BPM and first-beat offset of an mp3 and optionally generate a chart.

Usage:
    py -3 tools/analyze_song.py song.mp3                 # report only
    py -3 tools/analyze_song.py song.mp3 --chart out.json --rank 2

Needs numpy and miniaudio (pip install numpy miniaudio).
The chart generator places notes on onsets of the music quantised to the
detected beat grid, so notes always land on real hits in the audio.
"""

import argparse
import json
import sys

import miniaudio
import numpy as np

import chart_rules

SR = 22050
HOP = 256
NFFT = 1024


def load_mono(path):
    decoded = miniaudio.decode_file(path, output_format=miniaudio.SampleFormat.FLOAT32,
                                    nchannels=1, sample_rate=SR)
    return np.asarray(decoded.samples, dtype=np.float32)


def stft_mag(x):
    window = np.hanning(NFFT).astype(np.float32)
    count = 1 + (len(x) - NFFT) // HOP
    idx = np.arange(NFFT)[None, :] + HOP * np.arange(count)[:, None]
    return np.abs(np.fft.rfft(x[idx] * window, axis=1))


def onset_envelope(mag, lo_hz=0, hi_hz=SR / 2):
    freqs = np.fft.rfftfreq(NFFT, 1.0 / SR)
    band = (freqs >= lo_hz) & (freqs <= hi_hz)
    logmag = np.log1p(mag[:, band] * 10.0)
    flux = np.maximum(0.0, np.diff(logmag, axis=0)).sum(axis=1)
    flux = np.concatenate([[0.0], flux])
    # remove slow trend so loud sections do not dominate
    kernel = np.ones(43) / 43.0
    flux = np.maximum(0.0, flux - np.convolve(flux, kernel, mode="same"))
    return flux


def estimate_tempo(env, fps):
    """Return (bpm, offset_seconds) using a comb-filter score over a fine BPM grid."""
    best = (-1.0, 120.0, 0.0)
    env = env / (env.max() + 1e-9)
    times = np.arange(len(env)) / fps
    for bpm in np.arange(70.0, 200.0, 0.05):
        period = 60.0 / bpm
        # fold onsets into one beat period; the peak of the folded histogram is the phase
        phase = np.mod(times, period) / period
        bins = 32
        hist = np.bincount((phase * bins).astype(int) % bins, weights=env, minlength=bins)
        hist = hist + 0.5 * np.roll(hist, 1) + 0.5 * np.roll(hist, -1)
        score = hist.max() / (hist.mean() + 1e-9)
        if score > best[0]:
            best = (score, bpm, (np.argmax(hist) + 0.5) / bins * period)
    return best[1], best[2]


def refine(env, fps, bpm, offset):
    """Least-squares fit of beat times to the strongest onset near every beat."""
    period = 60.0 / bpm
    peaks = []
    dur = len(env) / fps
    n = 0
    while offset + n * period < dur - period:
        t = offset + n * period
        lo = int(max(0, (t - period * 0.2) * fps))
        hi = int(min(len(env), (t + period * 0.2) * fps))
        if hi > lo:
            k = lo + int(np.argmax(env[lo:hi]))
            if env[k] > env.mean() * 1.5:
                peaks.append((n, k / fps))
        n += 1
    if len(peaks) < 20:
        return bpm, offset
    ns = np.array([p[0] for p in peaks], dtype=float)
    ts = np.array([p[1] for p in peaks], dtype=float)
    slope, intercept = np.polyfit(ns, ts, 1)
    return 60.0 / slope, intercept


def first_beat_offset(offset, period, env, fps):
    """Shift offset to the first beat where real music starts (not silence)."""
    thresh = env.mean() * 2.0
    start = int(np.argmax(env > thresh)) / fps
    beats = max(0, int(round((start - offset) / period)))
    return offset + beats * period


def generate_chart(env_low, env_all, fps, bpm, offset, duration, rank):
    """Chart playable with two drumsticks.

    - at most 2 simultaneous notes (a chord needs both sticks)
    - minimum time between notes and a longer one before reusing the same pad
    - chords only on strong beats and only now and then
    """
    period = 60.0 / bpm
    sub = {0: 1, 1: 2, 2: 2, 3: 2}.get(rank, 2)
    step = period / sub
    min_gap = {0: 0.45, 1: 0.34, 2: 0.22, 3: 0.18}.get(rank, 0.3)
    same_lane_gap = min_gap + 0.10
    chord_every = {0: 0, 1: 0, 2: 8, 3: 4}.get(rank, 0)  # beats between chords
    target_rate = {0: 1.3, 1: 2.2, 2: 3.4, 3: 4.0}.get(rank, 2.0)  # notes per second
    n_slots = int((duration - offset) / step)
    strengths = []
    for i in range(n_slots):
        t = offset + i * step
        lo = int(max(0, (t - step * 0.4) * fps))
        hi = int(min(len(env_all), (t + step * 0.4) * fps + 1))
        strengths.append(env_all[lo:hi].max() if hi > lo else 0.0)
    keep = min(1.0, target_rate * duration / max(1, n_slots))
    thr = float(np.quantile(np.array(strengths), 1.0 - keep)) if strengths else 0.0
    notes = []
    last_time = -9.0
    last_lane = 1
    lane_last_time = [-9.0] * 4
    last_chord_beat = -99
    for i in range(n_slots):
        t = offset + i * step
        lo = int(max(0, (t - step * 0.4) * fps))
        hi = int(min(len(env_all), (t + step * 0.4) * fps + 1))
        if hi <= lo:
            continue
        strength = env_all[lo:hi].max()
        on_beat = (i % sub == 0)
        if strength < thr * (1.0 if on_beat else 1.25):
            continue
        if t - last_time < min_gap - 1e-6:
            continue
        # choose a lane that is comfortable for the hands: not the last one,
        # preferring neighbours, and not a pad that was hit very recently
        candidates = [l for l in range(4) if l != last_lane and t - lane_last_time[l] >= same_lane_gap]
        if not candidates:
            continue
        candidates.sort(key=lambda l: (abs(l - last_lane) > 2, (l * 5 + i * 3) % 7))
        lane = candidates[0]
        notes.append({"time": round(float(t), 4), "lane": int(lane)})
        lane_last_time[lane] = t
        beat = i // sub
        strong = on_beat and beat % 4 == 0
        if chord_every and strong and beat - last_chord_beat >= chord_every                 and env_low[lo:hi].max() > env_low.mean() * 2.5:
            partner = (lane + 2) % 4
            if t - lane_last_time[partner] >= same_lane_gap:
                notes.append({"time": round(float(t), 4), "lane": int(partner)})
                lane_last_time[partner] = t
                last_chord_beat = beat
        last_time = t
        last_lane = lane
    return notes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("song")
    ap.add_argument("--chart")
    ap.add_argument("--rank", type=int, default=1)
    ap.add_argument("--double", action="store_true", help="use twice the detected BPM (fast songs detected at half tempo)")
    args = ap.parse_args()

    x = load_mono(args.song)
    duration = len(x) / SR
    mag = stft_mag(x)
    fps = SR / HOP
    env = onset_envelope(mag)
    env_low = onset_envelope(mag, 30, 200)
    bpm, offset = estimate_tempo(env, fps)
    while bpm > 150.0:  # fold octave errors into a playable range
        bpm /= 2.0
    bpm, offset = refine(env, fps, bpm, offset)
    if args.double:
        bpm *= 2.0
    offset = first_beat_offset(offset, 60.0 / bpm, env, fps)
    print(json.dumps({"bpm": round(bpm, 3), "offset": round(float(offset), 4),
                      "duration": round(duration, 3)}))
    if args.chart:
        notes = generate_chart(env_low, env, fps, bpm, offset, duration, args.rank)
        notes, moved, dropped = chart_rules.enforce_lane_gap(notes)
        print("regla 1 s por carril: %d movidas, %d descartadas" % (moved, dropped), file=sys.stderr)
        with open(args.chart, "w", encoding="utf-8") as f:
            json.dump(notes, f)
        print(f"{len(notes)} notas -> {args.chart}", file=sys.stderr)


if __name__ == "__main__":
    main()
