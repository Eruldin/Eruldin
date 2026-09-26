#!/usr/bin/env python3
# build_concept.py — slice the user's concept panels into game sprites.
#
# Pre-rendered sprite pipeline (Fallout/Diablo style): crop each character
# from the painted panel, key out the dark background, downscale to sprite
# height, and emit frame variants + portraits + room backdrops + cinematic
# stills. Output goes to art/ and src/concept_manifest.gd (same dict shapes
# as art_manifest.gd so pixel.gd can merge them).

import os
import numpy as np
from PIL import Image, ImageFilter, ImageOps, ImageEnhance
from collections import deque

ROOT = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(ROOT)                 # dusus-protocol/
DOCS = os.path.dirname(PROJ)                 # "Düşüş Oyun Projesi/"
OUT = os.path.join(PROJ, "art")
MAN = os.path.join(PROJ, "src", "concept_manifest.gd")

P_ANA = os.path.join(DOCS, "ChatGPT_Image_17_May_2026_14_08_36_1.png")
P_YAN = os.path.join(DOCS, "ChatGPT_Image_17_May_2026_14_08_36_2.png")
P_DUS = os.path.join(DOCS, "ChatGPT_Image_17_May_2026_14_08_37_3.png")
P_END = os.path.join(DOCS, "ChatGPT_Image_17_May_2026_14_08_37_4.png")
P_SOL = os.path.join(DOCS, "ChatGPT_Image_17_May_2026_14_08_37_5.png")
P_SIM = os.path.join(DOCS, "ChatGPT_Image_17_May_2026_14_08_37_6.png")
P_AET = os.path.join(DOCS, "ChatGPT_Image_17_May_2026_14_08_38_7.png")

SPRITES = {}
FRAMES = {}

# ------------------------------------------------------------- bg removal

def cut_figure(im, dark=30):
    """Key out the near-black panel background via border flood-fill on the
    dark mask, then trim to the silhouette bbox. Returns RGBA image."""
    a = np.array(im.convert("RGB"), dtype=np.uint8)
    lum = a.max(axis=2)
    H, W = lum.shape
    dark_mask = lum < dark
    # flood fill dark pixels connected to the border -> background
    bg = np.zeros((H, W), dtype=bool)
    q = deque()
    for x in range(W):
        for y in (0, H - 1):
            if dark_mask[y, x] and not bg[y, x]:
                bg[y, x] = True; q.append((y, x))
    for y in range(H):
        for x in (0, W - 1):
            if dark_mask[y, x] and not bg[y, x]:
                bg[y, x] = True; q.append((y, x))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < H and 0 <= nx < W and dark_mask[ny, nx] and not bg[ny, nx]:
                bg[ny, nx] = True; q.append((ny, nx))
    opaque = ~bg
    # connected components of the opaque mask
    seen = np.zeros((H, W), dtype=bool)
    comps = []
    for y in range(H):
        for x in range(W):
            if opaque[y, x] and not seen[y, x]:
                pts = []
                q = deque([(y, x)])
                seen[y, x] = True
                while q:
                    cy, cx = q.popleft()
                    pts.append((cy, cx))
                    for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < H and 0 <= nx < W and opaque[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            q.append((ny, nx))
                comps.append(pts)
    # cluster-aligned crop is tight, but labels/rings still survive at the
    # top/bottom — chain-merge fragments that sit near the largest piece
    # (the body), and drop anything outside its vertical span
    comps.sort(key=len, reverse=True)
    boxes = []
    for pts in comps:
        ys = [p[0] for p in pts]; xs = [p[1] for p in pts]
        boxes.append((min(ys), min(xs), max(ys), max(xs)))
    kept = np.zeros(len(comps), dtype=bool)
    if comps:
        kept[0] = True
    def near(i, dist):
        y0, x0, y1, x1 = boxes[i]
        for j in range(len(comps)):
            if not kept[j]:
                continue
            a0, b0, a1, b1 = boxes[j]
            if x1 + dist >= b0 and x0 - dist <= b1 and y1 + dist >= a0 and y0 - dist <= a1:
                return True
        return False
    for _ in range(3):
        for i in range(1, len(comps)):
            if not kept[i] and len(comps[i]) >= 6 and near(i, 26):
                kept[i] = True
    if comps:
        ly0, _, ly1, _ = boxes[0]
        lh = max(1, ly1 - ly0)
        for i in range(1, len(comps)):
            if kept[i]:
                y0, _, y1, _ = boxes[i]
                if y1 < ly0 - 0.12 * lh or y0 > ly1 + 0.12 * lh:
                    kept[i] = False
    keep = np.zeros((H, W), dtype=bool)
    for i in range(len(comps)):
        if kept[i]:
            for y, x in comps[i]:
                keep[y, x] = True
    # close the silhouette: dilate ~11px (merges armour fragments into one
    # body), fill interior holes, then erode back ~8px
    m = keep
    for _ in range(11):
        m = m | np.roll(m, 1, 0) | np.roll(m, -1, 0) | np.roll(m, 1, 1) | np.roll(m, -1, 1)
    inv = ~m
    reach = np.zeros((H, W), dtype=bool)
    q = deque()
    for x in range(W):
        for y in (0, H - 1):
            if inv[y, x] and not reach[y, x]:
                reach[y, x] = True; q.append((y, x))
    for y in range(H):
        for x in (0, W - 1):
            if inv[y, x] and not reach[y, x]:
                reach[y, x] = True; q.append((y, x))
    while q:
        cy, cx = q.popleft()
        for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < H and 0 <= nx < W and inv[ny, nx] and not reach[ny, nx]:
                reach[ny, nx] = True; q.append((ny, nx))
    filled = m | ~reach
    for _ in range(8):
        e = filled & np.roll(filled, 1, 0) & np.roll(filled, -1, 0) & np.roll(filled, 1, 1) & np.roll(filled, -1, 1)
        e[0, :] = False; e[-1, :] = False; e[:, 0] = False; e[:, -1] = False
        filled = e
    alpha = np.where(filled, 255, 0).astype(np.uint8)
    rgba = np.dstack([a, alpha])
    out = Image.fromarray(rgba, "RGBA")
    # feather edge 1px
    am = out.getchannel("A").filter(ImageFilter.GaussianBlur(1.1))
    out.putalpha(am.point(lambda v: min(255, int(v * 1.35))))
    # trim to silhouette
    bbox = out.getbbox()
    if bbox:
        pad = 6
        l, t, r, b = bbox
        out = out.crop((max(0, l - pad), max(0, t - pad), min(W, r + pad), min(H, b + pad)))
    return out

# ------------------------------------------------------------- slots

def slots(panel_path, n=7, y0=100, y1=622):
    """Detect the n character columns by bright-pixel projection and crop
    each figure fully inside its own box (even division misaligned crops
    and produced 1.5-character fragments)."""
    im = Image.open(panel_path).convert("RGB")
    a = np.array(im)[y0 + 10:y1 - 12]
    lum = a.max(axis=2)
    col = (lum > 45).sum(axis=0).astype(np.float32)
    sm = np.convolve(col, np.ones(15) / 15, "same")
    th = sm.max() * 0.12
    on = sm > th
    spans = []
    s = None
    for x in range(len(on)):
        if on[x] and s is None:
            s = x
        elif not on[x] and s is not None:
            spans.append((s, x))
            s = None
    if s is not None:
        spans.append((s, len(on)))
    clusters = [(a0, b0) for a0, b0 in spans if b0 - a0 > 60]
    centers = [(a0 + b0) // 2 for a0, b0 in clusters[:n]]
    out = []
    for i, c in enumerate(centers):
        left = centers[i - 1] + 12 if i > 0 else clusters[i][0] - 8
        right = centers[i + 1] - 12 if i < len(centers) - 1 else clusters[i][1] + 8
        # never cut a neighbouring figure: clamp to this cluster's own span ± pad
        left = max(left, clusters[i][0] - 10)
        right = min(right, clusters[i][1] + 10)
        out.append(im.crop((int(left), y0, int(right), y1)))
    return out

def norm_height(fig, h):
    if fig.height == 0: return fig
    w = int(fig.width * h / fig.height)
    return fig.resize((w, h), Image.LANCZOS)

def _shift(fig, dx=0, dy=0):
    out = Image.new("RGBA", fig.size, (0, 0, 0, 0))
    out.paste(fig, (dx, dy), fig)
    return out

def _tint(fig, rm=1.0, gm=1.0, bm=1.0, ra=0):
    r, g, b, a = fig.split()
    r = r.point(lambda v: min(255, int(v * rm + ra)))
    g = g.point(lambda v: min(255, int(v * gm)))
    b = b.point(lambda v: min(255, int(v * bm)))
    return Image.merge("RGBA", (r, g, b, a))

def frame_variants(fig):
    """All animation states the game requests, as pose variants of the
    rendered figure: idle/run/windup/strike/atk1-3/dash/parry/charge/
    hurt/die/p2."""
    w, h = fig.size
    f = {}
    f["idle"] = [fig, fig.resize((w, int(h * 0.985)), Image.LANCZOS)]
    lean = fig.rotate(-4, resample=Image.BICUBIC)
    f["run"] = [lean, _shift(lean.resize((w, int(h * 0.96)), Image.LANCZOS), 0, 3)]
    f["windup"] = [fig.rotate(5, resample=Image.BICUBIC)]
    lunge = ImageEnhance.Brightness(fig.rotate(-8, resample=Image.BICUBIC)).enhance(1.08)
    f["strike"] = [_shift(lunge, int(w * 0.05), 2)]
    f["atk"] = f["strike"]
    f["atk1"] = [_shift(fig.rotate(-10, resample=Image.BICUBIC), int(w * 0.04), 0)]
    f["atk2"] = [_shift(fig.rotate(6, resample=Image.BICUBIC), -int(w * 0.03), 0)]
    f["atk3"] = [_shift(ImageEnhance.Brightness(fig.rotate(-13, resample=Image.BICUBIC)).enhance(1.1), int(w * 0.06), 2)]
    f["dash"] = [fig.rotate(-22, resample=Image.BICUBIC).resize((int(w * 1.12), int(h * 0.9)), Image.LANCZOS)]
    f["parry"] = [fig.rotate(4, resample=Image.BICUBIC).resize((int(w * 0.96), h), Image.LANCZOS)]
    charge = _tint(fig.resize((int(w * 0.97), int(h * 0.93)), Image.LANCZOS), 0.8, 0.85, 1.0)
    f["charge"] = [charge]
    f["hurt"] = [fig.rotate(6, resample=Image.BICUBIC)]
    die = fig.rotate(68, resample=Image.BICUBIC, expand=False)
    die.putalpha(die.getchannel("A").point(lambda v: int(v * 0.75)))
    f["die"] = [die]
    f["p2"] = [_tint(fig, 1.35, 0.75, 0.75, 30)]
    return f

def portrait(fig, size=96):
    """Head-and-shoulders crop from the trimmed figure."""
    w, h = fig.size
    box = (int(w * 0.14), 0, int(w * 0.86), int(h * 0.34))
    head = fig.crop(box)
    side = max(head.width, head.height)
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sq.paste(head, ((side - head.width) // 2, (side - head.height) // 2))
    return sq.resize((size, size), Image.LANCZOS)

def vignette_cut(crop, pad=8, fade=44):
    """Tight-crop the figure by its bright content, then keep ALL pixels
    (black armour survives, unlike luminance keying) and fade only the
    crop edges to transparent. The near-black panel interior reads as a
    smoky aura on the game's dark floor."""
    a = np.array(crop.convert("RGB"), dtype=np.uint8)
    lum = a.max(axis=2)
    H, W = lum.shape
    # figure core only — the card's smoky interior lum (~45-60) must not
    # stretch the bbox to the card edges, or the card frame survives
    ys, xs = np.where(lum > 72)
    if len(ys) == 0:
        ys, xs = np.where(lum > 45)
    if len(ys) == 0:
        return crop.convert("RGBA")
    y0, y1 = max(0, ys.min() - pad), min(H, ys.max() + pad)
    x0, x1 = max(0, xs.min() - pad), min(W, xs.max() + pad)
    out = crop.convert("RGBA").crop((x0, y0, x1, y1))
    w, h = out.size
    # elliptical vignette — hugs the standing figure instead of leaving a
    # dark rectangle slab on the floor
    xx = (np.arange(w) - (w - 1) / 2.0) / (w / 2.0)
    yy = (np.arange(h) - (h - 1) / 2.0) / (h / 2.0)
    r = np.sqrt(xx[None, :] ** 2 + yy[:, None] ** 2)
    alpha = np.clip((1.0 - r) / 0.34, 0.0, 1.0)
    alpha = (alpha * 255).astype(np.uint8)
    out.putalpha(Image.fromarray(alpha, "L"))
    return out

def emit(name, fig, h, do_portrait=True, do_frames=True, game_key=None):
    fig = norm_height(fig, h)
    # lift readability on the dark floor — the grimdark source is ~40% too
    # dark for 70-110px sprites
    fig = ImageEnhance.Brightness(fig).enhance(1.38)
    fig = ImageEnhance.Contrast(fig).enhance(1.12)
    path = f"{name}_base.png"
    fig.save(os.path.join(OUT, path))
    SPRITES[name] = "art/" + path
    if do_frames:
        sets = {}
        for st, arr in frame_variants(fig).items():
            files = []
            for i, fr in enumerate(arr):
                fn = f"{name}_{st}_{i}.png"
                fr.save(os.path.join(OUT, fn))
                files.append("art/" + fn)
            sets[st] = files
        FRAMES[name] = sets
        if game_key:
            FRAMES[game_key] = sets
    if do_portrait:
        p = portrait(fig)
        fn = f"por_{name}.png"
        p.save(os.path.join(OUT, fn))
        SPRITES[f"por_{name}"] = "art/" + fn
        if game_key:
            SPRITES[f"por_{game_key}"] = "art/" + fn

# ------------------------------------------------------------- env panels

def env_boxes(W, H):
    return [(60, 118, 815, 455), (845, 118, 1605, 455),
            (60, 468, 815, 805), (845, 468, 1605, 805)]

def env_crops(panel_path):
    im = Image.open(panel_path)
    W, H = im.size
    full, scene = [], []
    for b in env_boxes(W, H):
        c = im.crop(b)
        full.append(c)
        # illustration region only (skip the left text column)
        sc = c.crop((int(c.width * 0.27), int(c.height * 0.06), c.width, c.height))
        scene.append(sc)
    return full, scene

# ================================================================= main

os.makedirs(OUT, exist_ok=True)

# --- character sheets ---------------------------------------------------
ana = slots(P_ANA)
yan = slots(P_YAN)
dus = slots(P_DUS)

# heights tuned so heroes read bigger than fodder (emitted ~2x on-screen
# px; the game fits body.scale to a target height so painted art stays crisp)
CHARS = [
    # (key, slot_image, sprite_height, game_frame_key)
    ("rhasa",   ana[0], 128, "rhasa"),   ("ely",    ana[1], 150, "ely"),
    ("elyb",    ana[2], 118, None),      ("rex",    ana[3], 160, "rex"),
    ("saphire", ana[4], 112, "saphire"), ("kirin",  ana[5], 148, "kirin"),
    ("const",   ana[6], 150, "const"),
    ("nahum",   yan[0], 155, "nahum"),   ("tuman",  yan[1], 148, "tuman"),
    ("david",   yan[2], 110, None),      ("ehnar",  yan[3], 116, "vane"),
    ("varl",    yan[4], 116, None),      ("viawar", yan[5], 112, "neva"),
    ("alfa",    dus[0], 130, "sentinel"),("rex2",   dus[1], 132, None),
    ("ahusk",   dus[2], 120, "turret"),  ("konakci",dus[3], 96,  "husk"),
    ("zirkon",  dus[4], 108, "spitter"), ("cereb",  dus[5], 84,  "drone"),
    ("host",    dus[6], 170, "host"),
]
for name, im, h, gk in CHARS:
    fig = vignette_cut(im)
    emit("c_" + name, fig, h, game_key=gk)
    print("char", name, fig.size)

# biome-variant enemy lookups (husk_1..3 etc.) resolve to the same painted
# frames so concept art wins over the DCSS per-biome variants
for kind in ("husk", "spitter", "turret", "drone", "sentinel"):
    for b in (1, 2, 3):
        FRAMES[f"{kind}_{b}"] = FRAMES[kind]

# NPC bodies: npc.gd asks for npc2_<id>/npcb_<id> sprites
for nid, ckey in (("rhasa", "c_rhasa"), ("neva", "c_viawar"),
                  ("saphire", "c_saphire"), ("vane", "c_ehnar")):
    SPRITES[f"npc2_{nid}"] = SPRITES[ckey]
    SPRITES[f"npcb_{nid}"] = SPRITES[ckey]

# --- environment backdrops + cinematic stills ---------------------------
BIOME_PANELS = {0: P_END, 1: P_SIM, 2: P_SOL, 3: P_AET}
def bottom_fade(im, frac=0.30):
    """Fade the bottom frac of an image to transparent — lets a painted
    backdrop dissolve into the tiled floor instead of cutting hard."""
    im = im.convert("RGBA")
    w, h = im.size
    a = np.array(im, dtype=np.uint8)
    ys = np.arange(h, dtype=np.float32)
    start = h * (1.0 - frac)
    ramp = np.clip((h - ys) / max(1.0, h * frac), 0.0, 1.0) ** 0.8
    a[:, :, 3] = (a[:, :, 3].astype(np.float32) * ramp[:, None]).astype(np.uint8)
    return Image.fromarray(a, "RGBA")

for biome, path in BIOME_PANELS.items():
    full, scene = env_crops(path)
    for i, (f, s) in enumerate(zip(full, scene)):
        # room backdrop (scene only, bottom-faded for the floor blend)
        sb = s.resize((900, int(s.height * 900 / s.width)), Image.LANCZOS)
        sb = bottom_fade(sb)
        fn = f"cbg_{biome}_{i}.png"; sb.save(os.path.join(OUT, fn))
        SPRITES[f"cbg_{biome}_{i}"] = "art/" + fn
        # below-room vista: same scene with the fade on TOP (dissolves
        # under the floor edge; the void below the room becomes depths)
        sv = ImageOps.flip(bottom_fade(ImageOps.flip(s.resize(
            (900, int(s.height * 900 / s.width)), Image.LANCZOS))))
        fn3 = f"cbv_{biome}_{i}.png"; sv.save(os.path.join(OUT, fn3))
        SPRITES[f"cbv_{biome}_{i}"] = "art/" + fn3
        # cinematic still (whole dossier card)
        fb = f.resize((1280, int(f.height * 1280 / f.width)), Image.LANCZOS)
        fn2 = f"cine_{biome}_{i}.png"; fb.save(os.path.join(OUT, fn2))
        SPRITES[f"cine_{biome}_{i}"] = "art/" + fn2
    print("biome", biome, "panels ok")

# hub backdrop = Viator Kampi panel (Endusterra #2), scene region
_, scene_end = env_crops(P_END)
hub = scene_end[1].resize((1000, int(scene_end[1].height * 1000 / scene_end[1].width)), Image.LANCZOS)
hub = bottom_fade(hub)
hub.save(os.path.join(OUT, "cbg_hub.png"))
SPRITES["cbg_hub"] = "art/cbg_hub.png"
hubv = ImageOps.flip(bottom_fade(ImageOps.flip(hub)))
hubv.save(os.path.join(OUT, "cbv_hub.png"))
SPRITES["cbv_hub"] = "art/cbv_hub.png"

# room.gd asks for bg_<key> — route to the painted vista panels
for b in range(4):
    SPRITES[f"bg_{b}"] = SPRITES[f"cbg_{b}_0"]
SPRITES["bg_hub"] = SPRITES["cbg_hub"]
SPRITES["title_bg"] = SPRITES["cine_0_0"]

# --- manifest ------------------------------------------------------------
def gd_val(v):
    if isinstance(v, str):
        return '"%s"' % v
    if isinstance(v, list):
        return "[" + ", ".join(gd_val(x) for x in v) + "]"
    if isinstance(v, dict):
        return "{" + ", ".join('%s: %s' % (gd_val(k), gd_val(x)) for k, x in v.items()) + "}"
    return str(v)

with open(MAN, "w", encoding="utf8") as fp:
    fp.write("class_name ConceptManifest\nextends RefCounted\n\n")
    fp.write("const SPRITES := " + gd_val(SPRITES) + "\n\n")
    fp.write("const FRAMES := " + gd_val(FRAMES) + "\n")

print("DONE", len(SPRITES), "sprites,", len(FRAMES), "frame sets")
