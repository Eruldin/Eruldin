#!/usr/bin/env python3
# Build res://art/ from DCSS tileset. Generates frame variants, composites,
# portraits, and a manifest.json consumed by pixel.gd.
from PIL import Image, ImageEnhance
import os, json, glob, sys

SRC = "dcss/Dungeon Crawl Stone Soup Full"
OUT = "../art"
os.makedirs(OUT, exist_ok=True)

def P(p):
    return os.path.join(SRC, p)

def load(p):
    return Image.open(P(p)).convert("RGBA")

CANVAS = 64  # actor frame canvas (32px tile x2)

def tile2canvas(im, scale=2):
    im2 = im.resize((im.width*scale, im.height*scale), Image.NEAREST)
    c = Image.new("RGBA", (CANVAS, CANVAS), (0,0,0,0))
    c.paste(im2, ((CANVAS-im2.width)//2, CANVAS-im2.height), im2)
    return c

def xform(im, rot=0, dx=0, dy=0, sx=1.0, sy=1.0, tint=None, alpha=1.0):
    out = im
    if sx != 1.0 or sy != 1.0:
        nw, nh = max(1,int(im.width*sx)), max(1,int(im.height*sy))
        out = out.resize((nw, nh), Image.NEAREST)
        c = Image.new("RGBA", im.size, (0,0,0,0))
        c.paste(out, ((im.width-nw)//2, im.height-nh), out)
        out = c
    if rot:
        out = out.rotate(-rot, resample=Image.BICUBIC, center=(im.width/2, im.height/2))
    if dx or dy:
        c = Image.new("RGBA", im.size, (0,0,0,0))
        c.paste(out, (int(dx), int(dy)), out)
        out = c
    if tint:
        r,g,b,a = out.split()
        r = r.point(lambda v: min(255, int(v*(1+tint[0]))))
        g = g.point(lambda v: min(255, int(v*(1+tint[1]))))
        b = b.point(lambda v: min(255, int(v*(1+tint[2]))))
        out = Image.merge("RGBA", (r,g,b,a))
    if alpha < 1.0:
        r,g,b,a = out.split()
        a = a.point(lambda v: int(v*alpha))
        out = Image.merge("RGBA", (r,g,b,a))
    return out

ANIM_SPEC = {
    "idle":   [(0,0,0,1,1), (0,0,-1,1,1)],
    "run":    [(0,0,2,1,0.92), (0,0,-2,1,1), (0,0,2,1,0.92), (0,0,0,1,1)],
    "windup": [(-9,-3,0,1,1)],
    "strike": [(12,4,0,1,1)],
    "atk1":   [(14,4,0,1,1)],
    "atk2":   [(-16,3,0,1,1)],
    "atk3":   [(18,6,0,1.06,1)],
    "dash":   [(24,4,0,1.12,0.94)],
    "parry":  [(-6,0,0,1.06,1.06)],
    "charge": [(-5,-2,0,1,1)],
    "hurt":   [(0,0,0,1,1,"red")],
    "die":    [(65,0,4,1,1,None,0.75), (82,0,8,1,1,None,0.5), (90,0,10,1,1,None,0.3)],
    "atk":    [(10,4,0,1,1)],
    "p2":     [(-8,-2,0,1,1)],
}

def gen_frames(key, base_canvas, anims, manifest):
    files = {}
    for anim in anims:
        specs = ANIM_SPEC[anim]
        arr = []
        for i, sp in enumerate(specs):
            rot, dx, dy, sx, sy = sp[:5]
            tint = "t" if len(sp) > 5 and sp[5] == "red" else None
            al = sp[6] if len(sp) > 6 else 1.0
            img = xform(base_canvas, rot, dx, dy, sx, sy,
                        (0.45,-0.25,-0.25) if tint else None, al)
            fn = f"{key}_{anim}_{i}.png"
            img.save(os.path.join(OUT, fn))
            arr.append("art/"+fn)
        files[anim] = arr
    manifest["frames"][key] = files

def portrait(src_canvas, out_name, crop=(4,2,28,22)):
    # src_canvas is the original 32x32 tile
    im = src_canvas.crop(crop).resize((56,56), Image.NEAREST)
    im.save(os.path.join(OUT, out_name))
    return "art/"+out_name

manifest = {"sprites": {}, "frames": {}}

def S(name, dcss, scale=2, canvas=False):
    im = load(dcss)
    if canvas:
        im = tile2canvas(im, scale)
    elif scale != 1:
        im = im.resize((im.width*scale, im.height*scale), Image.NEAREST)
    fn = name + ".png"
    im.save(os.path.join(OUT, fn))
    manifest["sprites"][name] = "art/"+fn

# ---------------- ELY composite ----------------
ely = Image.new("RGBA", (32,32), (0,0,0,0))
for layer in [
    "player/base/human_male.png",
    "player/cloak/cyan.png",
    "player/legs/metal_gray.png",
    "player/boots/mesh_black.png",
    "player/body/bplate_metal_1.png",
    "player/gloves/gauntlet_blue.png",
    "player/head/band_blue.png",
    "player/hand_right/black_sword.png",
]:
    if os.path.exists(P(layer)):
        ely.paste(load(layer), (0,0), load(layer))
    else:
        print("MISSING LAYER", layer)
ely_canvas = tile2canvas(ely)
gen_frames("ely", ely_canvas, ["idle","run","atk1","atk2","atk3","dash","parry","charge","hurt","die"], manifest)
manifest["sprites"]["por_ely"] = portrait(ely, "por_ely.png", (8,0,26,18))
ely.save(os.path.join(OUT, "ely_base.png"))

# ---------------- ENEMIES (kind -> per-biome skins) ----------------
ENEMIES = {
 "husk":     ["monster/mutant_beast.png", "monster/formicid.png", "monster/undead/ghoul.png", "monster/undead/eidolon.png"],
 "spitter":  ["monster/eyes/eye_of_devastation_new.png", "monster/deep_elf_sorcerer.png", "monster/necromancer_new.png", "monster/eyes/shining_eye_new.png"],
 "turret":   ["monster/statues/firespitter_statue_new.png", "monster/nonliving/crystal_guardian.png", "dungeon/statues/statue_archer.png", "dungeon/statues/statue_angel.png"],
 "drone":    ["monster/nonliving/battlesphere.png", "monster/nonliving/orb_of_electricity.png", "monster/nonliving/insubstantial_wisp.png", "monster/eyes/golden_eye_new.png"],
 "sentinel": ["monster/nonliving/iron_golem.png", "monster/nonliving/crystal_golem.png", "monster/deep_dwarf_death_knight.png", "monster/angel.png"],
}
for kind, skins in ENEMIES.items():
    for b, path in enumerate(skins):
        key = kind if b == 0 else f"{kind}_{b}"
        if not os.path.exists(P(path)):
            print("MISSING", key, path); continue
        gen_frames(key, tile2canvas(load(path)), ["idle","windup","strike","hurt","die"], manifest)

# ---------------- BOSSES ----------------
BOSSES = {
 "rex":  "monster/demons/balrug_new.png",
 "host": "monster/demons/green_death.png",
 "nahum":"monster/hell_knight_new.png",
 "tuman":"monster/juggernaut.png",
 "kirin":"monster/necromancer_new.png",
 "const":"monster/daeva.png",
}
for key, path in BOSSES.items():
    tile = load(path)
    gen_frames(key, tile2canvas(tile), ["idle","atk","p2","hurt","die"], manifest)
    manifest["sprites"]["por_"+key] = portrait(tile, f"por_{key}.png", (4,0,28,22))

# ---------------- NPCS ----------------
NPCS = {
 "rhasa":  ("monster/deep_dwarf_berserker.png", (6,2,26,20)),
 "neva":   ("monster/elf_new.png", (6,2,26,20)),
 "saphire":("monster/deep_elf_blademaster.png", (6,2,26,20)),
 "vane":   ("monster/deep_elf_mage.png", (6,2,26,20)),
}
for nid,(path,crop) in NPCS.items():
    tile = load(path)
    c = tile2canvas(tile)
    # npc2_<id> = idle frame, npcb_<id> = bob frame (npc.gd swaps between them)
    c.save(os.path.join(OUT, f"npc2_{nid}.png")); manifest["sprites"][f"npc2_{nid}"] = f"art/npc2_{nid}.png"
    xform(c, 0,0,-1).save(os.path.join(OUT, f"npcb_{nid}.png")); manifest["sprites"][f"npcb_{nid}"] = f"art/npcb_{nid}.png"
    manifest["sprites"]["por_"+nid] = portrait(tile, f"por_{nid}.png", crop)

# ---------------- FLOORS ----------------
FLOORS = {
 "hub": ["dungeon/floor/floor_sand_rock_0.png","dungeon/floor/floor_sand_rock_1.png","dungeon/floor/floor_sand_rock_2.png"],
 "0":   ["dungeon/floor/dirt_0_new.png","dungeon/floor/dirt_1_new.png","dungeon/floor/dirt_2_new.png"],
 "1":   ["dungeon/floor/mesh_0_new.png","dungeon/floor/mesh_1_new.png","dungeon/floor/mesh_2_new.png"],
 "2":   ["dungeon/floor/floor_vines_0_new.png","dungeon/floor/floor_vines_1_new.png","dungeon/floor/floor_vines_2_new.png"],
 "3":   ["dungeon/floor/marble_floor_1.png","dungeon/floor/marble_floor_2.png","dungeon/floor/marble_floor_3.png"],
}
for key, paths in FLOORS.items():
    for i,p in enumerate(paths):
        S(f"t2_{key}_{i}", p, scale=1)

WALLS = {
 "hub":"dungeon/wall/brick_brown_0.png",
 "0":  "dungeon/wall/catacombs_0.png",
 "1":  "dungeon/wall/lab-metal_0.png",
 "2":  "dungeon/wall/metal_wall_white_0.png",
 "3":  "dungeon/wall/marble_wall_1.png",
}
for key,p in WALLS.items():
    S(f"w2_{key}", p, scale=1)

# ---------------- DOORS / GATE ----------------
S("door2", "dungeon/doors/runed_door.png", scale=3)
S("door_open", "dungeon/doors/open_door.png", scale=3)
gate = Image.new("RGBA", (192,64), (0,0,0,0))
for i,part in enumerate(["gate_sealed_left.png","gate_sealed_middle.png","gate_sealed_right.png"]):
    t = load("dungeon/doors/"+part).resize((64,64), Image.NEAREST)
    gate.paste(t, (i*64,0), t)
gate.save(os.path.join(OUT,"gate2.png")); manifest["sprites"]["gate2"] = "art/gate2.png"
gate_o = Image.new("RGBA", (192,64), (0,0,0,0))
for i,part in enumerate(["gate_open_left.png","gate_open_middle.png","gate_open_right.png"]):
    t = load("dungeon/doors/"+part).resize((64,64), Image.NEAREST)
    gate_o.paste(t, (i*64,0), t)
gate_o.save(os.path.join(OUT,"gate_open.png")); manifest["sprites"]["gate_open"] = "art/gate_open.png"
S("portal", "dungeon/gateways/portal.png", scale=2)

# ---------------- PROPS ----------------
PROPS = {
 "rock":   "dungeon/boulder.png",
 "bones":  "monster/undead/skeletons/skeleton_humanoid_small_old.png",
 "crate":  "dungeon/chest_2_closed.png",
 "pod":    "monster/fungi_plants/giant_spore.png",
 "crystal":"item/misc/misc_crystal_new.png",
 "vent":   "dungeon/traps/gas_trap.png",
 "vat":    "monster/fungi_plants/oklob_plant.png",
 "wreck":  "dungeon/statues/crumbled_column_1.png",
 "pillar": "dungeon/statues/crumbled_column.png",
 "statue": "dungeon/statues/statue_ancient_hero.png",
 "banner": "dungeon/wall/banners/banner_1.png",
 "tree":   "dungeon/trees/tree_1_red.png",
 "shrub":  "monster/fungi_plants/bush_3.png",
 "tent":   "dungeon/shops/abandoned_shop.png",
 "medic":  "dungeon/statues/statue_angel.png",
 "campfire": "effect/cloud_fire_1.png",
}
for name,p in PROPS.items():
    if os.path.exists(P(p)): S(name, p, scale=1)
    else: print("MISSING PROP", name, p)

# ---------------- DECALS ----------------
# transparent splats — safe to rotate freely in _scatter_decals
bloods = sorted(glob.glob(P("misc/blood/blood_red_*.png")))[:4]
for i,fp in enumerate(bloods):
    im = Image.open(fp).convert("RGBA")
    im.save(os.path.join(OUT, f"dec_stain_{i}.png")); manifest["sprites"][f"dec_stain_{i}"] = f"art/dec_stain_{i}.png"
# flattened skeletons read as remains on the ground
skel = load("monster/undead/skeletons/skeleton_humanoid_small_old.png")
for i in range(3):
    flat = xform(skel, 0, 0, 0, 1.0, 0.5, tint=(-0.35,-0.35,-0.3), alpha=0.8)
    flat.save(os.path.join(OUT, f"dec_bones_{i}.png")); manifest["sprites"][f"dec_bones_{i}"] = f"art/dec_bones_{i}.png"
# floor patches: tile texture cut into an organic blob shape (no square edges)
def blob_patch(tile, seed):
    import random
    rng = random.Random(seed)
    m = Image.new("L", (32,32), 0)
    from PIL import ImageDraw
    d = ImageDraw.Draw(m)
    for _ in range(9):
        cx = 16 + rng.randint(-7,7); cy = 16 + rng.randint(-7,7)
        r = rng.randint(4,9)
        d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=255)
    m = m.point(lambda v: 255 if v > 0 else 0)
    out = tile.copy(); out.putalpha(m)
    return out
PATCHES = {
 "dec_crack_0": "dungeon/floor/dirt_full_new.png",
 "dec_tuft_0":  "dungeon/floor/grass/grass0-dirt-mix_2.png",
 "dec_vein_0":  "dungeon/floor/floor_nerves_1_new.png",
}
for i,(name,p) in enumerate(PATCHES.items()):
    if os.path.exists(P(p)):
        blob_patch(load(p), 40+i).save(os.path.join(OUT, name+".png"))
        manifest["sprites"][name] = "art/"+name+".png"
    else: print("MISSING PATCH", name, p)

# ---------------- ICONS ----------------
def first_glob(pat):
    g = glob.glob(P(pat))
    return os.path.relpath(g[0], SRC).replace("\\","/") if g else None

ICONS = {
 # HUD / rewards
 "ico_frag": "item/misc/misc_crystal_new.png",
 "ico_heal": first_glob("item/potion/ruby_red*.png") or first_glob("item/potion/*red*.png"),
 "ico_boon": "item/book/book_indigo.png",
 "ico_exit": "dungeon/gateways/enter.png",
 "icn_dash": "item/armor/feet/boots_iron_2.png",
 "icn_skull": first_glob("item/misc/*skull*.png") or "item/misc/misc_rune.png",
 "icn_crown": first_glob("item/misc/*crown*.png") or "item/misc/misc_orb.png",
 # patrons
 "icn_rhasa": "item/weapon/golden_sword.png",
 "icn_neva":  first_glob("item/potion/*magenta*.png") or first_glob("item/potion/*.png"),
 "icn_saphire":"gui/spells/disciplines/poison.png",
 "icn_rex":   "gui/spells/air/chain_lightning_new.png",
 "icn_kovan": "dungeon/wall/beehives_0.png",
 # upgrades
 "icn_upg_hp":     first_glob("item/potion/*red*.png"),
 "icn_upg_dmg":    "item/weapon/demon_blade.png",
 "icn_upg_dash":   "item/armor/feet/boots_iron_2.png",
 "icn_upg_revive": "gui/spells/air/flight.png",
 "icn_upg_frag":   "item/misc/misc_crystal_new.png",
 "icn_upg_shield": "item/armor/shields/shield_1.png",
 # stance
 "icn_stance_cleave": "item/weapon/double_sword_new.png",
 "icn_stance_duel":   "item/weapon/blessed_blade.png",
}
for name,p in ICONS.items():
    if p and os.path.exists(P(p)):
        S(name, p, scale=2)
    else:
        print("MISSING ICON", name, p)

# projectile sprites for plasma/enemy shots
for i,path in enumerate(["effect/arrow_2.png","effect/arrow_5.png","effect/arrow_7.png"]):
    if os.path.exists(P(path)): S(f"proj_{i}", path, scale=1)

# manifest as GDScript const — always packed into exports (json might not be)
gd = "class_name ArtManifest\nextends RefCounted\n\nconst SPRITES := {\n"
for k,v in manifest["sprites"].items():
    gd += f'\t"{k}": "{v}",\n'
gd += "}\n\nconst FRAMES := {\n"
for k,anims in manifest["frames"].items():
    gd += f'\t"{k}": {{'
    for anim,files in anims.items():
        gd += f'"{anim}": {json.dumps(files)}, '
    gd += "},\n"
gd += "}\n"
with open("../src/art_manifest.gd","w") as f:
    f.write(gd)
print("DONE", len(manifest["sprites"]), "sprites,", len(manifest["frames"]), "frame sets")
