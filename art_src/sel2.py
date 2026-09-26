from montage import sheet
import glob, os
BASE = "dcss/Dungeon Crawl Stone Soup Full"
# melee grunts + ranged + flyers + big boss candidates
cands = []
for d,ks in [
  ("monster/undead", ["ghoul","skeleton","zombie","wraith","shadow","wight","flayed"]),
  ("monster/animals", ["hound","rat","bat","jackal","wolf","snake","adder","scorpion","spider","worm"]),
  ("monster/eyes", ["eye","orb"]),
  ("monster/nonliving", ["golem","gargoyle","elemental","vortex","lightning","prism","wisp","battlesphere"]),
  ("monster/demons", ["demonic_crawler","beast","fiend","hellion","chaos_spawn","abomination_small"]),
  ("monster/dragons", ["dragon","drake","wyvern","lindwurm"]),
  ("monster/aberration", []),
  ("monster/amorphous", ["slime","jelly","ooze","blob"]),
  ("monster/aquatic", ["electric_eel"]),
  ("monster/spriggan", []),
  ("monster/drakes", []),
]:
    fs = sorted(glob.glob(BASE+"/"+d+"/*.png"))
    if ks:
        fs = [f for f in fs if any(k in os.path.basename(f) for k in ks)]
    cands += [os.path.relpath(f,BASE) for f in fs]
sheet(cands[:96], "sel_monsters.png", cols=16)
