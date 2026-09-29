# build_pack_assets.py — listed pack'lerden gercek asset'leri keser ve
# art/pack/ + audio/ altina koyar; src/pack_manifest.gd'yi yazar.
# Calistir:  python tools/build_pack_assets.py   (repo kokunden, PIL gerekli)
import os, sys, math, random, shutil
from PIL import Image, ImageEnhance

SRC = r"C:\Users\PC\Desktop\Assetler Honor Meselesi"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "art", "pack")
AUD = os.path.join(ROOT, "audio")
os.makedirs(ART, exist_ok=True)

sprites = {}   # key -> res:// relative path
frames = {}    # key -> {anim: [paths]}

def sp(key, rel): sprites[key] = rel.replace("\\", "/")
def fr(key, anim, paths): frames.setdefault(key, {})[anim] = [p.replace("\\", "/") for p in paths]

def S(*p): return os.path.join(SRC, *p)

def save(img, name):
    img.save(os.path.join(ART, name), optimize=True)
    return "art/pack/" + name

# ---------- helpers ----------

def load(rel):
    p = os.path.join(SRC, rel)
    if not os.path.exists(p):
        print("!! missing", p); return None
    return Image.open(p).convert("RGBA")

def trim(img, pad=2):
    bb = img.getchannel("A").getbbox()
    if bb is None: return img
    x0, y0, x1, y1 = bb
    return img.crop((max(0, x0-pad), max(0, y0-pad), min(img.width, x1+pad), min(img.height, y1+pad)))

def upscale_px(img, target_h):
    """piksel-art prop'u net tutsun diye NEAREST ile ~target_h yukseklige cikar"""
    f = max(1, round(target_h / img.height))
    return img.resize((img.width*f, img.height*f), Image.NEAREST)

def put_on_canvas(img, cw=140, ch=150):
    c = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    x = (cw - img.width) // 2
    y = ch - img.height            # taban hizali (grounded prop)
    c.alpha_composite(img, (x, y))
    return c

def strip_frames(img, fw=None, fh=None, count=None):
    """yatay sprite strip -> kare listesi"""
    if fw is None: fw = img.width
    if fh is None: fh = img.height
    out = []
    n = img.width // fw
    if count: n = min(n, count)
    for i in range(n):
        f = img.crop((i*fw, 0, (i+1)*fw, min(fh, img.height)))
        out.append(f)
    return out

def save_frames(frames_list, prefix):
    paths = []
    for i, f in enumerate(frames_list):
        paths.append(save(f, "%s_%d.png" % (prefix, i)))
    return paths

# ======================================================================
# 1) ZEMINLER: boyanmis g_gr_*'nin pismis siyah kenarini ac —
#    ic bolgeyi disa dogru uzat (testere-bant siyah blok fix'i)
# ======================================================================
def fix_ground(b, brighten=1.0, tint=None):
    src = os.path.join(ROOT, "art", "gen", "g_gr_%d.png" % b)
    if not os.path.exists(src):
        print("!! no ground", b); return
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    ix, iy = int(w*0.09), int(h*0.09)
    im = im.crop((ix, iy, w-ix, h-iy)).resize((w, h), Image.LANCZOS)
    if brighten != 1.0:
        im = ImageEnhance.Brightness(im).enhance(brighten)
    if tint:
        ov = Image.new("RGBA", im.size, tint)
        im = Image.blend(im, ov, tint[3]/255.0)
    save(im, "gr_%d.png" % b)
    sp("gr_%d" % b, "art/pack/gr_%d.png" % b)

for b in range(9):
    fix_ground(b)
fix_ground(4, brighten=1.22)                     # Cürük Bataklik — karanlikti
fix_ground(5, brighten=1.18, tint=(90,40,10,18)) # Kül Ovası — kor tonu
print("grounds done")

# ======================================================================
# 2) DUVAR BANTLARI w2_4..w2_8 — eksik biyom duvarlari gercek tile'lardan
# ======================================================================
def pick_cells(img, cell, want, region=None, seed=7):
    """tileset'ten dolu gorunen huceleri sec"""
    rng = random.Random(seed)
    px = img.load()
    x0, y0, x1, y1 = region or (0, 0, img.width, img.height)
    cand = []
    for cy in range(y0, y1 - cell + 1, cell):
        for cx in range(x0, x1 - cell + 1, cell):
            opa = var = 0
            cols = []
            for y in range(cy, cy+cell, 4):
                for x in range(cx, cx+cell, 4):
                    p = px[x, y]
                    opa += p[3] > 200
                    cols.append(p[:3])
            if opa < 14: continue
            r = sum(c[0] for c in cols)/len(cols)
            g = sum(c[1] for c in cols)/len(cols)
            bl = sum(c[2] for c in cols)/len(cols)
            lum = (r+g+bl)/3
            if lum < 25 or lum > 210: continue
            cand.append((cx, cy, lum))
    rng.shuffle(cand)
    return cand[:want]

def wall_tile(cells_src, tint=None, cell=16):
    """2x2 hucelik 32px duvar dokusu"""
    t = Image.new("RGBA", (cell*2, cell*2))
    for i, (cx, cy, _) in enumerate(cells_src[:4]):
        t.paste(cells_src_img.crop((cx, cy, cx+cell, cy+cell)),
                ((i % 2)*cell, (i // 2)*cell))
    if tint:
        px = t.load()
        for y in range(t.height):
            for x in range(t.width):
                r, g, b, a = px[x, y]
                if a:
                    px[x, y] = (int(r*tint[0]), int(g*tint[1]), int(b*tint[2]), a)
    return t

# 4 Çürük Bataklık: gothic cemetery duvar taslari -> yesil-mor nem
src = load("gothicvania-cemetery-files/gothicvania-cemetery-files/Assets/Environment/tileset.png")
if src:
    cells_src_img = src
    cells = pick_cells(src, 16, 8, region=(0, 0, src.width, min(src.height, 480)))
    if len(cells) >= 4:
        w = wall_tile(cells, (0.85, 1.0, 0.75))
        save(w, "w2_4.png"); sp("w2_4", "art/pack/w2_4.png")

# 5 Kül Ovası: post-apoc tugla -> gri-kor
pa = load("PostApocalypse_AssetPack_v1.1.2/Tiles/Brick-Wall_TileSet.png")
if pa:
    cells_src_img = pa
    cells = pick_cells(pa, 16, 8)
    if len(cells) >= 4:
        w = wall_tile(cells, (0.75, 0.62, 0.55))
        save(w, "w2_5.png"); sp("w2_5", "art/pack/w2_5.png")

# 6 Kızıl Çöl: ayni tugla -> kum tonta
if pa:
    w = wall_tile(cells, (1.15, 0.95, 0.62))
    save(w, "w2_6.png"); sp("w2_6", "art/pack/w2_6.png")

# 7 Kristal Çukur: 0x72 zindan duvari -> mor
dw = load("0x72_DungeonTilesetII_v1.7/0x72_DungeonTilesetII_v1.7/atlas_walls_low-16x16.png")
if dw:
    cells_src_img = dw
    cells = pick_cells(dw, 16, 8)
    if len(cells) >= 4:
        w = wall_tile(cells, (0.85, 0.6, 1.25))
        save(w, "w2_7.png"); sp("w2_7", "art/pack/w2_7.png")

# 8 Donmuş Çatlak: sunnyland winter buz blogu
wt = load("Phaser-demo-sunnyland winter/sunnyland winter/assets/environment/tileset.png")
if wt:
    cells_src_img = wt
    cells = pick_cells(wt, 16, 8, seed=11)
    if len(cells) >= 4:
        w = wall_tile(cells, (0.8, 0.95, 1.25))
        save(w, "w2_8.png"); sp("w2_8", "art/pack/w2_8.png")
print("walls done")

# ======================================================================
# 3) PROP'LAR — gercek nesneler, ~120px taban hizali canvas'ta
# ======================================================================
def prop(key, rel, th=120, tint=None):
    im = load(rel)
    if im is None: return
    im = trim(im)
    im = upscale_px(im, th)
    if tint:
        px = im.load()
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, a = px[x, y]
                if a:
                    px[x, y] = (min(255, int(r*tint[0])), min(255, int(g*tint[1])), min(255, int(b*tint[2])), a)
    save(put_on_canvas(im), "pk_%s.png" % key)
    sp("pk_%s" % key, "art/pack/pk_%s.png" % key)

PO = "PostApocalypse_AssetPack_v1.1.2/Objects/"
WC = "warped city files/warped city files/Assets/ENVIRONMENT/props/"
# 0/1/5/6 -> postapoc kalintilari
prop("pa_tires",  PO+"2-Tires_Grass_Bleak-Yellow.png", 70)
prop("pa_barrel", PO+"Barrel_rust_red_1.png", 60)
prop("pa_bench",  PO+"Bench_2_down_Overgrown_Bleak-Yellow.png", 80)
prop("pa_tires2", PO+"2-Tires_Grass_Green.png", 70)
prop("pa_barrel2",PO+"Barrel_rust_blue_1.png", 60)
prop("pa_bench2", PO+"Bench_4_side_Overgrown_Green.png", 80)
# 2/3 -> warped city kalintilari
prop("wc_antenna", WC+"antenna.png", 150)
prop("wc_banner",  WC+"banner-big/banner-big-1.png", 110)
prop("wc_neon",    WC+"banner-neon/banner-neon-1.png", 90)
prop("wc_arrow",   WC+"banner-arrow.png", 70)
# 7 -> stringstar kristal/uzayli bitki (tileset'ten tek huceler)
st = load("stringstar fields/tileset.png")
if st:
    cells_src_img = st
    got = 0
    for cx, cy, lum in pick_cells(st, 16, 24, seed=21):
        c = trim(st.crop((cx, cy, cx+16, cy+16)))
        if c.width < 8: continue
        save(put_on_canvas(upscale_px(c, 96)), "pk_ss_%d.png" % got)
        sp("pk_ss_%d" % got, "art/pack/pk_ss_%d.png" % got)
        got += 1
        if got >= 3: break
# 8 -> sunnyland winter cam/buz
if wt:
    for i, (cx, cy, lum) in enumerate(pick_cells(wt, 32, 12, seed=31)[:4]):
        c = trim(wt.crop((cx, cy, cx+32, cy+32)))
        if c.width < 10: continue
        save(put_on_canvas(upscale_px(c, 96)), "pk_wt_%d.png" % i)
        sp("pk_wt_%d" % i, "art/pack/pk_wt_%d.png" % i)
print("props done")

# ======================================================================
# 4) DUSMAN VARYANTLARI — <kind>_<biome> otomatik secilir
# ======================================================================
TR = "Tiny RPG Character Asset Pack 02 v1.01-Free Demon_A&Blood Monster_A/Tiny RPG Character Asset Pack 02 -Free Demon_A&Blood Monster_A/Characters(100x100 split)/"
def tr_strip(name, rel):
    im = load(TR + rel)
    if im is None: return []
    return strip_frames(im, 100, 100)

# Kül Ovasi: KOR PENÇE -> Blood Monster, ATEŞ RUHU -> Demon
bm = {"idle": tr_strip("bm_i", "Blood Monster_A/Blood Monster_A/Blood Monster_A_Idle.png"),
      "windup": tr_strip("bm_w", "Blood Monster_A/Blood Monster_A/Blood Monster_A_Walk.png")[:2],
      "strike": tr_strip("bm_a", "Blood Monster_A/Blood Monster_A/Blood Monster_A.png"),
      "hurt": tr_strip("bm_h", "Blood Monster_A/Blood Monster_A/Blood Monster_A_Hurt.png"),
      "die": tr_strip("bm_d", "Blood Monster_A/Blood Monster_A/Blood Monster_A_Death.png")}
dm = {"idle": tr_strip("dm_i", "Demon_A/Demon_A/Demon_A_Idle.png"),
      "windup": tr_strip("dm_w", "Demon_A/Demon_A/Demon_A_Walk.png")[:2],
      "strike": tr_strip("dm_a", "Demon_A/Demon_A/Demon_A_Attack01.png") + tr_strip("dm_a2", "Demon_A/Demon_A/Demon_A_Attack02.png"),
      "hurt": tr_strip("dm_h", "Demon_A/Demon_A/Demon_A_Hurt.png"),
      "die": tr_strip("dm_d", "Demon_A/Demon_A/Demon_A_Death.png")}
for key, bank in (("korp_5", bm), ("atesruh_5", dm)):
    for anim, fl in bank.items():
        if not fl: continue
        mini = []
        for i, f in enumerate(fl):
            f = trim(f)
            f.thumbnail((64, 64), Image.NEAREST)
            mini.append(f)
        fr(key, anim, save_frames(mini, "en_%s_%s" % (key, anim)))

# Bataklik: İTZPAPALOTL -> sunnyland yarasa
SL = "SunnyLand Enemies 1 files/SunnyLand Enemies 1 files/Assets/"
batfly = [load(SL+"bat/bat-fly/bat-fly%d.png" % i) for i in (1, 2, 3)]
bathang = [load(SL+"bat/bat-hang/bat-hang%d.png" % i) for i in (1, 2, 3, 4)]
batfly = [b for b in batfly if b]; bathang = [b for b in bathang if b]
if batfly:
    fr("itizpap_4", "idle", save_frames([trim(b) for b in batfly], "en_bat_i"))
    fr("itizpap_4", "windup", save_frames([trim(b) for b in bathang[:2] or batfly], "en_bat_w"))
    fr("itizpap_4", "strike", save_frames([trim(b) for b in batfly[::-1]], "en_bat_s"))
    fr("itizpap_4", "die", save_frames([trim(bathang[-1])] if bathang else [trim(batfly[0])], "en_bat_d"))
    sp("cr_4", save_frames([trim(batfly[0])], "cr_4")[0])  # bataklik critter'i
print("enemies done")

# ======================================================================
# 5) VFX — net sprite'lar
# ======================================================================
# fx_boom: gigapack gercek patlama karesi (generated yerine)
GG = "Super Pixel Effects Gigapack (Free Version) v2.9.0/Super Pixel Effects Gigapack (Free Version)/PNG/Explosions/"
import glob as gl
boom_frames = sorted(gl.glob(S(GG + "epic_explosion_001/epic_explosion_001_large_orange/*.png"), recursive=True))
if boom_frames:
    mid = Image.open(boom_frames[len(boom_frames)//2]).convert("RGBA")
    mid = trim(mid)
    mid.thumbnail((128, 128), Image.LANCZOS)
    save(mid, "fx_boom.png"); sp("fx_boom", "art/pack/fx_boom.png")
# hz_pool: net kenarli aura (spell halo / nova) -> hazard havuzu dokusu
halo = None
GGP = "Super Pixel Effects Gigapack (Free Version) v2.9.0/Super Pixel Effects Gigapack (Free Version)/PNG/"
for pat in ("Fantasy Spells/*/*/*.png", "Auras/*/*/*.png", "Portals/*/*/*.png"):
    cand = [c for c in sorted(gl.glob(S(GGP + pat), recursive=True))
            if any(w in os.path.basename(c).lower() or w in os.path.dirname(c).lower()
                   for w in ("aura", "halo", "nova", "circle", "heal"))]
    if cand:
        halo = Image.open(cand[len(cand)//2]).convert("RGBA"); break
if halo is None:
    cand = [c for c in sorted(gl.glob(S("VFX Free Pack/**/*.png"), recursive=True))
            if any(w in os.path.basename(c).lower() for w in ("nova", "aura", "circle"))]
    if cand: halo = Image.open(cand[0]).convert("RGBA")
if halo:
    halo = trim(halo)
    halo.thumbnail((96, 96), Image.LANCZOS)
    save(halo, "hz_pool.png"); sp("hz_pool", "art/pack/hz_pool.png")
# fx_die: Legacy EnemyDeath orta kare — dusman olum efekti
ed = load("Legacy Collection/Legacy Collection/Assets/Explosions and Magic/EnemyDeath/Sprites/enemy-death4.png")
if ed:
    e = trim(ed); e.thumbnail((96, 96), Image.NEAREST)
    save(e, "fx_die.png"); sp("fx_die", "art/pack/fx_die.png")
print("vfx done")

# ======================================================================
# 6) MUZIK — eksik biyomlar + synth olani gercek parcayla
#    (audio._clip onceligi ogg>mp3>wav → .ogg koymak yeterli)
# ======================================================================
xd = sorted(gl.glob(S("xDeviruchi - 16 bit Fantasy & Adventure (2025)/**/*.ogg"), recursive=True))
def find_xd(part):
    for p in xd:
        if part.lower() in os.path.basename(p).lower(): return p
    return None
music_map = {
    "mus_0": "Where The Winds Roam",   # Tarla — ruzgarli bozkir
    "mus_2": "Falling Apart",          # Harabe — cokus
    "mus_5": None,                     # Kül Ovası -> dark ambient
}
for name, part in music_map.items():
    if part is None: continue
    p = find_xd(part)
    if p: shutil.copy(p, os.path.join(AUD, name + ".ogg"))
da = sorted(gl.glob(S("Dark Ambient Soundscape/**/*.ogg"), recursive=True)) + sorted(gl.glob(S("Dark Ambient Soundscape/**/*.wav"), recursive=True))
for p in da:
    if "ashes" in os.path.basename(p).lower():
        shutil.copy(p, os.path.join(AUD, "mus_5.ogg")); break
# Diyalog blip'leri — Grunting kisa sesler
GR = "Super Dialogue Audio Pack v1/Super Dialogue Audio Pack v1/Step 2 - Audio Files/9 - Grunting/"
gm = sorted(gl.glob(S(GR + "Male/Ian Lampert/grunting_*_ian.wav"), recursive=True))[:3]
gf = sorted(gl.glob(S(GR + "Female/Karen Cenon/grunting_*_karen.wav"), recursive=True))[:2]
for i, p in enumerate(gm): shutil.copy(p, os.path.join(AUD, "grunt_m%d.wav" % i))
for i, p in enumerate(gf): shutil.copy(p, os.path.join(AUD, "grunt_f%d.wav" % i))
print("audio done")

# ======================================================================
# 7) MANIFEST
# ======================================================================
lines = ["class_name PackManifest", "extends RefCounted", "",
         "# gercek paket asset'leri — tools/build_pack_assets.py uretir", "",
         "const SPRITES := {"]
for k in sorted(sprites):
    lines.append('\t"%s": "%s",' % (k, sprites[k]))
lines += ["}", "", "const FRAMES := {"]
for k in sorted(frames):
    lines.append('\t"%s": {' % k)
    for anim, paths in frames[k].items():
        lines.append('\t\t"%s": [%s],' % (anim, ", ".join('"%s"' % p for p in paths)))
    lines.append("\t},")
lines.append("}")
with open(os.path.join(ROOT, "src", "pack_manifest.gd"), "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
print("manifest: %d sprites, %d frame-banks" % (len(sprites), len(frames)))
