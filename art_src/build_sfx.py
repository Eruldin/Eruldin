# build_sfx.py — layered sound-design synthesis -> real .wav files in audio/
# Same philosophy as paint_figures.py: authored locally, no external assets.
# Each sound is built from filtered noise, inharmonic metallic partials,
# FM growls and shaped envelopes — far richer than the old sine+noise beeps.
import wave, math, os
import numpy as np

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "audio")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(20260705)


def n_(dur):
    return int(SR * dur)


def noise(dur):
    return rng.standard_normal(n_(dur))


def sine(f, dur, phase=0.0):
    t = np.arange(n_(dur)) / SR
    return np.sin(2 * np.pi * f * t + phase)


def sweep_sine(f0, f1, dur):
    n = n_(dur)
    t = np.arange(n) / SR
    ph = np.cumsum(np.linspace(f0, f1, n)) * 2 * np.pi / SR
    return np.sin(ph)


def env_exp(dur, decay, attack=0.003):
    n = n_(dur)
    t = np.arange(n) / SR
    a = np.minimum(1.0, t / attack)
    return a * np.exp(-t * decay)


def env_ar(dur, attack, release):
    n = n_(dur)
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / attack) * np.minimum(1.0, (dur - t) / release)
    return np.clip(e, 0, 1)


def _biquad(x, b0, b1, b2, a1, a2):
    y = np.zeros_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for i in range(len(x)):
        xn = x[i]
        yn = b0 * xn + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        y[i] = yn
        x2, x1 = x1, xn
        y2, y1 = y1, yn
    return y


def lowpass(x, fc):
    w = 2 * np.pi * fc / SR
    a = np.exp(-w)
    b0, a1 = 1 - a, -a
    y = np.zeros_like(x)
    y1 = 0.0
    for i in range(len(x)):
        y1 = b0 * x[i] - a1 * y1
        y[i] = y1
    return y


def highpass(x, fc):
    return x - lowpass(x, fc)


def bandpass(x, fc, q=1.0):
    w = 2 * np.pi * fc / SR
    alpha = np.sin(w) / (2 * q)
    cw = np.cos(w)
    b0, b1, b2 = alpha, 0.0, -alpha
    a0, a1, a2 = 1 + alpha, -2 * cw, 1 - alpha
    return _biquad(x, b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)


def nb(dur, fc, q, decay, lp=False):
    """Filtered noise burst with matching envelope."""
    x = lowpass(noise(dur), fc) if lp else bandpass(noise(dur), fc, q)
    return x * env_exp(dur, decay)


def metal(freqs, dur, decays=None, gains=None):
    """Inharmonic metallic partials — the clang body of impacts.
    Detuned pairs + downward glide = struck steel, not a synth beep."""
    out = np.zeros(n_(dur))
    t = np.arange(n_(dur)) / SR
    for i, f in enumerate(freqs):
        d = (decays[i] if decays else 9.0 + i * 6.0) * rng.uniform(0.85, 1.2)
        g = gains[i] if gains else 1.0 / (i + 1)
        for det in (-0.004, 0.003):  # ±0.4% chorus pairs
            glide = 1.0 - 0.03 * (t / dur)  # slight pitch sag
            wob = np.sin(2 * np.pi * (2.0 + i * 0.7) * t) * 1.5
            out += np.sin(2 * np.pi * f * (1 + det) * glide * t + wob) * env_exp(dur, d) * g * 0.5
    return out


def metal_rich(base, dur, n=9, spread=1.35):
    """Cluster of inharmonic partials above `base` — dense clang."""
    fr = [base * (1.0 + spread * i * rng.uniform(0.7, 1.3)) / (1.0 + i * 0.15) for i in range(1, n + 1)]
    return metal(fr, dur)


def grit(x, drive=2.5):
    """Tanh waveshaper — adds harmonics/bite, kills 'pure synth' feel."""
    return np.tanh(x * drive) / np.tanh(drive)


def space(x, taps=(0.041, 0.073, 0.121), g=0.28):
    """Short multi-tap ambience — puts the sound inside a space."""
    out = x.copy()
    for i, td in enumerate(taps):
        k = n_(td)
        gg = g / (i + 1)
        out[k:] += x[:-k] * gg
    return out


def norm(x, peak=0.89):
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 0 else x


def mix(*xs):
    L = max(len(x) for x in xs)
    out = np.zeros(L)
    for x in xs:
        out[:len(x)] += x
    return out


def pad(x, dur):
    out = np.zeros(n_(dur))
    out[:min(len(x), len(out))] = x[:len(out)]
    return out


def shift(x, dt):
    return np.concatenate([np.zeros(n_(dt)), x])


def seamless(x, xf=2.0):
    """Crossfade tail into head so LOOP_FORWARD wraps cleanly."""
    k = n_(xf)
    if len(x) <= k:
        return x
    w = np.linspace(1.0, 0.0, k)
    head = x[:k]
    x[-k:] = x[-k:] * w + head * (1 - w)
    return x[:-k]


def save(name, x):
    x = norm(np.nan_to_num(x))
    pcm = (x * 32767).astype(np.int16)
    p = os.path.join(OUT, name + ".wav")
    with wave.open(p, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f"  {name}.wav  {len(x)/SR:.2f}s")


# ---------------- SFX ----------------

def s_slash():
    d = 0.24
    x = bandpass(noise(d), 500, 0.8)
    t = np.arange(len(x)) / SR
    fc = 600 + 2200 * np.sin(t / d * np.pi)
    out = np.zeros_like(x)
    for i in range(0, len(x), 256):
        seg = x[i:i + 256]
        c = fc[min(i, len(fc) - 1)]
        out[i:i + 256] = bandpass(seg, c, 1.2)
    # air-cutting whistle layer + edge sizzle
    whistle = sweep_sine(1500, 420, d) * env_ar(d, 0.03, 0.12) * 0.25
    sizz = highpass(noise(d), 5200) * env_exp(d, 22) * 0.12
    return (out * env_ar(d, 0.02, 0.1) + whistle + sizz) * 0.9


def s_hit(heavy=False):
    d = 0.6 if heavy else 0.38
    # transient crack -> clang body -> low thunk -> room tail
    crack = nb(0.018 if not heavy else 0.03, 3600 if not heavy else 2200, 0.9, 90)
    clang = metal_rich(900 if not heavy else 520, d, n=8, spread=1.5)
    td = 0.09 if not heavy else 0.16
    thunk = sweep_sine(210 if not heavy else 150, 62, td) * env_exp(td, 30)
    out = pad(crack * 1.3, d) + clang * 0.45 + pad(thunk, d) * 0.95
    if heavy:
        out += sine(44, d) * env_exp(d, 7) * 0.8
    return space(grit(out, 2.2), g=0.22)


def s_crit():
    d = 0.42
    ting = metal_rich(2700, d, n=7, spread=1.1) * 0.8
    zip_ = sweep_sine(2400, 900, 0.07) * env_exp(0.07, 40) * 0.4
    return space(grit(mix(ting, pad(zip_, d)), 2.4), g=0.2)


def s_dash():
    d = 0.32
    x = noise(d)
    t = np.arange(len(x)) / SR
    fc = 400 + 1500 * np.sin(t / d * np.pi)
    out = np.zeros_like(x)
    for i in range(0, len(x), 256):
        c = fc[min(i, len(fc) - 1)]
        out[i:i + 256] = bandpass(x[i:i + 256], c, 1.5)
    low = lowpass(noise(d), 300) * env_ar(d, 0.05, 0.15) * 0.4
    return out * env_ar(d, 0.04, 0.12) * 0.75 + low


def s_parry():
    d = 0.16
    return grit(metal_rich(1900, d, n=6, spread=1.2) * 0.9 + pad(nb(0.02, 3800, 1, 90), d), 2.5)


def s_parry_ok():
    d = 0.65
    clang = metal_rich(1700, d, n=8, spread=1.4) * 0.75
    chim = mix(sine(1320, d) * env_exp(d, 7), sine(1980, d) * env_exp(d, 9) * 0.6)
    ring = metal_rich(2900, d, n=4, spread=0.8) * 0.3
    return space(grit(mix(clang, shift(chim, 0.04) * 0.5, ring), 2.4), g=0.28)


def s_charge_full():
    d = 0.6
    return mix(*[shift(sine(f, d) * env_exp(d, 8), i * 0.06)
                 for i, f in enumerate([880, 1174, 1760])]) * 0.7


def s_stance():
    d = 1.0
    e = env_ar(d, 0.15, 0.5)
    return mix(*[sine(f, d) for f in [196, 294, 392]]) * e * 0.5


def s_gate_open():
    d = 1.5
    rumble = lowpass(noise(d), 110) * env_ar(d, 0.05, 0.6) * 1.0
    chim = mix(*[shift(sine(f, d) * env_exp(d, 4.5), i * 0.12)
                 for i, f in enumerate([220, 330, 440, 660])]) * 0.4
    scrape = bandpass(noise(0.55), 640, 1.4) * env_ar(0.55, 0.12, 0.3) * 0.3
    stone = nb(0.1, 300, 0, 18, lp=True) * 0.5
    return space(mix(rumble, pad(chim, d), pad(scrape, d), pad(shift(stone, 0.15), d)), g=0.35)


def s_plasma():
    d = 0.42
    zap = sweep_sine(260, 60, d) * env_exp(d, 9) * 0.8
    hiss = bandpass(noise(d), 1700, 1.1) * env_exp(d, 17) * 0.35
    return grit(zap + hiss, 2.6)


def s_plasma_charge():
    d = 0.95
    rise = sweep_sine(110, 780, d) * env_ar(d, 0.45, 0.1) * 0.55
    hiss = bandpass(noise(d), 950, 1.4) * env_ar(d, 0.5, 0.08) * 0.3
    crackle = nb(0.2, 2800, 1.5, 12) * env_ar(0.2, 0.15, 0.05) * 0.3
    return grit(mix(rise, hiss, pad(shift(crackle, 0.7), d)), 2.4)


def s_shoot():
    d = 0.24
    return grit(sweep_sine(980, 170, d) * env_exp(d, 20) * 0.8 + pad(nb(0.03, 2600, 1, 70), d), 2.4)


def s_die():
    d = 0.85
    crunch = nb(0.16, 850, 0, 26, lp=True) * 1.1
    crackle = nb(0.07, 2400, 1.2, 40) * 0.5
    fall = sweep_sine(190, 48, d) * env_exp(d, 6.5) * 0.75
    splat = nb(0.13, 520, 0.9, 22) * 0.65
    wet = nb(0.3, 300, 0.7, 14, lp=True) * 0.4
    return space(grit(mix(pad(crunch, d), pad(shift(crackle, 0.03), d),
                        pad(shift(splat, 0.06), d), pad(shift(wet, 0.09), d), fall), 2.6), g=0.24)


def s_hurt():
    d = 0.4
    body = sweep_sine(300, 120, 0.09) * env_exp(0.09, 18) * 0.8
    flesh = nb(0.09, 1100, 0, 32, lp=True) * 0.8
    sub = sine(85, d) * env_exp(d, 11) * 0.55
    ring = metal_rich(1400, d, n=4, spread=0.9) * 0.25
    return space(grit(mix(body, pad(flesh, d), sub, ring), 2.2), g=0.18)


def s_door():
    d = 0.95
    clunk = sine(130, d) * env_exp(d, 11) * 0.9 + pad(nb(0.11, 560, 0, 22, lp=True), d) * 0.7
    chim = mix(sine(330, d) * env_exp(d, 6), sine(495, d) * env_exp(d, 8) * 0.6)
    return space(mix(pad(clunk, d), pad(shift(chim, 0.1), d) * 0.5), g=0.3)


def s_boon():
    d = 1.2
    chim = mix(*[shift(sine(f, d) * env_exp(d, 5.5), i * 0.09)
                 for i, f in enumerate([523, 659, 784, 1046])])
    sparkle = metal_rich(2400, d, n=5, spread=0.7) * 0.25
    shimmer = sine(2093, d) * env_exp(d, 8) * np.sin(np.arange(n_(d)) / SR * 22) * 0.15
    return space(mix(chim * 0.55, sparkle, shimmer), taps=(0.09, 0.17, 0.28), g=0.4)


def s_ui():
    d = 0.09
    return sine(1250, d) * env_exp(d, 60) * 0.6 + pad(nb(0.015, 3000, 1, 120), d)


def s_heal():
    d = 0.8
    return mix(sine(660, d) * env_exp(d, 5), shift(sine(880, d) * env_exp(d, 6), 0.12) * 0.8) * 0.6


def s_roar():
    d = 1.7
    t = np.arange(n_(d)) / SR
    # dual detuned growl carriers + FM rasp + breath noise + sub hit
    car = 58 + 26 * np.sin(t * 4.2) + 20 * t
    mod = np.sin(2 * np.pi * 26 * t)
    g1 = np.sin(2 * np.pi * np.cumsum(car) / SR + 2.8 * mod)
    g2 = np.sin(2 * np.pi * np.cumsum(car * 0.5) / SR + 1.8 * np.sin(2 * np.pi * 19 * t))
    rasp = np.sin(2 * np.pi * np.cumsum(car * 2.02) / SR) * np.exp(-t * 2.0) * 0.3
    breath = bandpass(noise(d), 480, 0.7) * (0.55 + 0.45 * np.sin(t * 3.1))
    e = env_ar(d, 0.10, 0.75)
    sub = sine(38, d) * env_exp(d, 2.6) * 0.6
    out = (g1 * 0.6 + g2 * 0.45 + rasp + breath * 0.55) * e + sub
    return space(grit(out, 3.0), taps=(0.055, 0.11, 0.19), g=0.4)


def s_alarm():
    d = 1.0
    gate = (sine(9, d) > 0).astype(float)
    low = sine(175, d) * env_exp(d, 4) * gate
    high = sine(220, d) * env_exp(d, 5)
    return space(grit(mix(high, low), 2.0), g=0.25) * 0.6


def s_explode():
    d = 1.4
    boom = sweep_sine(95, 30, d) * env_exp(d, 4.2) * 1.15
    crack = nb(0.05, 3000, 0.8, 60) * 0.8
    blast = lowpass(noise(d), 700) * env_exp(d, 8.5) * 0.8
    debris = nb(0.55, 1900, 0.9, 13) * 0.35
    rumble = sine(36, d) * env_exp(d, 5) * 0.5
    return space(grit(mix(boom, pad(crack, d), blast, pad(shift(debris, 0.09), d), rumble), 2.8), g=0.32)


def s_pickup():
    d = 0.4
    return mix(sine(880, d) * env_exp(d, 14), shift(sine(1174, d) * env_exp(d, 16), 0.05) * 0.8,
               metal([3200], d, decays=[18]) * 0.2) * 0.7


# ---------------- MUSIC (seamless loops) ----------------

def m_track(freqs, motif, dur, pulse_every=0.0, wind_fc=400, tension=0.0):
    """Layered ambient: detuned beating drones + wind + echoing bells + pulse.
    Rendered past `dur` then wrapped for a seamless loop."""
    ext = dur + 2.5
    n = n_(ext)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for k, f in enumerate(freqs):
        for det in (-0.006, 0.005):  # wide detuned pair — chorus thickness
            beat = 1.8 * np.sin(2 * np.pi * (0.09 + k * 0.06) * t + k * 1.7)
            out += np.sin(2 * np.pi * (f * (1 + det) + beat) * t) / (k + 1) * 0.5
        out += np.sin(2 * np.pi * (f * 2.003) * t) * 0.09 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.043 * t + k))
    out *= 0.17
    # two wind bands, slowly wandering
    for fc, g, lfo in ((wind_fc, 0.05, 0.031), (wind_fc * 0.4, 0.04, 0.017)):
        w = bandpass(noise(ext), fc, 0.6)
        wenv = 0.5 + 0.5 * np.sin(2 * np.pi * lfo * t + 1.0)
        out += w * wenv * g
    # sparse bells with echo taps
    step = ext / 7.0
    for i in range(8):
        f = motif[(i * 3 + 1) % len(motif)]
        start = int((i * step * 0.875 + 0.4) * SR)
        ln = n_(2.2)
        if start + ln > n:
            continue
        seg = np.sin(2 * np.pi * f * np.arange(ln) / SR) * env_exp(2.2, 3.0)
        seg += np.roll(np.sin(2 * np.pi * f * np.arange(ln) / SR) * env_exp(2.2, 4.0), n_(0.31)) * 0.4
        out[start:start + ln] += seg * 0.09
    # dissonant tension shimmer for boss
    if tension > 0:
        out += np.sin(2 * np.pi * motif[0] * t) * np.sin(2 * np.pi * (motif[0] * 1.06) * t) * tension * 0.05
        rum = lowpass(noise(ext), 60) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.11 * t))
        out += rum * tension * 0.35
    # combat pulse — saturated thump
    if pulse_every > 0:
        ph = t % pulse_every
        thump = np.sin(2 * np.pi * 52 * t) * np.exp(-ph * 11.0)
        out += np.tanh(thump * 2.0) * 0.38
    out *= env_ar(ext, 0.8, 0.8) * 0.9 + 0.1
    return seamless(out, 2.5)


def main():
    print("SFX:")
    save("slash", s_slash())
    save("hit", s_hit())
    save("hitHeavy", s_hit(True))
    save("crit", s_crit())
    save("dash", s_dash())
    save("parry", s_parry())
    save("parryOk", s_parry_ok())
    save("chargeFull", s_charge_full())
    save("stance", s_stance())
    save("gateOpen", s_gate_open())
    save("plasma", s_plasma())
    save("plasmaCharge", s_plasma_charge())
    save("shoot", s_shoot())
    save("die", s_die())
    save("hurt", s_hurt())
    save("door", s_door())
    save("boon", s_boon())
    save("ui", s_ui())
    save("heal", s_heal())
    save("roar", s_roar())
    save("alarm", s_alarm())
    save("explode", s_explode())
    save("pickup", s_pickup())
    print("MUSIC:")
    save("mus_hub", m_track([55.0, 82.4, 110.0], [220.0, 277.2, 329.6, 440.0], 26.0, wind_fc=300))
    save("mus_0", m_track([49.0, 73.4, 98.0], [196.0, 233.1, 293.7, 392.0], 30.0, pulse_every=0.85, wind_fc=500))
    save("mus_boss", m_track([36.7, 55.0, 73.4, 110.0], [146.8, 155.6, 220.0], 24.0, pulse_every=0.6, wind_fc=700, tension=1.0))


if __name__ == "__main__":
    main()
