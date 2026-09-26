from montage import sheet
import glob, os
BASE = "dcss/Dungeon Crawl Stone Soup Full"
def pngs(pat):
    return [os.path.relpath(f,BASE) for f in sorted(glob.glob(BASE+"/"+pat)) if f.endswith(".png")]
cands = []
for pat in ["item/weapon/*.png","item/weapon/artefact/*.png","item/staff/*.png","item/wand/*.png"]:
    cands += pngs(pat)
sheet(cands[:96], "sel_weapons.png", cols=16)
cands = []
for pat in ["gui/abilities/*.png","gui/spells/conjuration/*.png","gui/spells/air/*.png","gui/invocations/*.png","gui/skills/*.png","item/potion/*.png","item/misc/*.png","item/gold/*.png","item/armor/*.png"]:
    cands += pngs(pat)
sheet(cands[:96], "sel_icons.png", cols=16)
