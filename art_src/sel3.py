from montage import sheet
import glob, os
BASE = "dcss/Dungeon Crawl Stone Soup Full"
cands = []
# floors: crystal/metal/stone variants per biome
for pat in ["dungeon/floor/crystal*","dungeon/floor/metal*","dungeon/floor/grey_dirt*","dungeon/floor/pebble*","dungeon/floor/sandstone*","dungeon/floor/ice*","dungeon/floor/lava*","dungeon/floor/marble*","dungeon/floor/rough*","dungeon/floor/mesh*","dungeon/floor/rect*","dungeon/floor/vault*","dungeon/floor/academic*","dungeon/floor/dirt*","dungeon/floor/floor*"]:
    cands += [os.path.relpath(f,BASE) for f in sorted(glob.glob(BASE+"/"+pat))][:6]
sheet(cands[:80], "sel_floors.png", cols=16)
cands = []
for pat in ["dungeon/wall/brick*","dungeon/wall/crystal*","dungeon/wall/metal*","dungeon/wall/rock*","dungeon/wall/stone*","dungeon/wall/undead*","dungeon/wall/slime*","dungeon/wall/vault*","dungeon/wall/bars*","dungeon/wall/hive*","dungeon/wall/lair*"]:
    cands += [os.path.relpath(f,BASE) for f in sorted(glob.glob(BASE+"/"+pat))][:4]
cands += [os.path.relpath(f,BASE) for f in sorted(glob.glob(BASE+"/dungeon/doors/*.png"))]
cands += [os.path.relpath(f,BASE) for f in sorted(glob.glob(BASE+"/dungeon/gateways/*.png"))]
sheet(cands[:80], "sel_walls_doors.png", cols=16)
