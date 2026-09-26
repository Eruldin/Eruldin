from montage import sheet
import glob, os
BASE = "dcss/Dungeon Crawl Stone Soup Full"
cands = []
# props: statues, trees, altars, vaults, water/lava
for pat in ["dungeon/statues/*","dungeon/trees/*","dungeon/altars/*","dungeon/vaults/*","dungeon/traps/*","misc/blood/*","effect/*","dungeon/water/*","dungeon/floor/sigils/*"]:
    cands += [os.path.relpath(f,BASE) for f in sorted(glob.glob(BASE+"/"+pat))]
sheet(cands[:112], "sel_props_fx.png", cols=16)
cands = []
for pat in ["item/weapon/*","item/staff/*","item/wand/*","item/rod/*"]:
    cands += [os.path.relpath(f,BASE) for f in sorted(glob.glob(BASE+"/"+pat))]
sheet(cands[:96], "sel_weapons.png", cols=16)
cands = []
for pat in ["gui/abilities/*","gui/spells/conjuration/*","gui/spells/air/*","gui/invocations/*","gui/skills/*","item/potion/*","item/misc/*","item/gold/*"]:
    cands += [os.path.relpath(f,BASE) for f in sorted(glob.glob(BASE+"/"+pat))]
sheet(cands[:96], "sel_icons.png", cols=16)
