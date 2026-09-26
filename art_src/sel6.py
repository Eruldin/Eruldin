from montage import sheet
import glob, os
BASE = "dcss/Dungeon Crawl Stone Soup Full"
names = [
 "monster/mutant_beast.png","monster/undead/ghoul.png","monster/aberration/ugly_thing_new.png",
 "monster/eyes/eye_of_devastation_new.png","monster/nonliving/battlesphere.png","monster/nonliving/iron_golem.png",
 "monster/nonliving/crystal_golem.png","monster/nonliving/electric_golem.png","monster/nonliving/ball_lightning.png",
 "monster/nonliving/guardian_golem.png","monster/necromancer_new.png","monster/deep_elf_high_priest.png",
 "monster/orc_warlord.png","monster/deep_dwarf_berserker.png","monster/elf_new.png","monster/water_nymph.png",
 "monster/deep_elf_mage.png","monster/gnome.png","monster/satyr.png","monster/tengu_warrior.png",
 "monster/statues/statue_impish.png","monster/statues/statue_orb_guardian.png","monster/statues/statue_centaur.png",
 "monster/formicid.png","monster/fire_giant_new.png","monster/salamander.png","monster/demons/hellion_new.png",
 "monster/undead/eidolon.png","monster/undead/wraith.png","monster/undead/freezing_wraith.png",
 "monster/abyss/ancient_zyme.png" if os.path.exists(BASE+"/monster/abyss/ancient_zyme.png") else "monster/amorphous/azure_jelly.png",
]
names = [n for n in names if os.path.exists(BASE+"/"+n)]
sheet(names, "sel_cast2.png", cols=16, cell=56, scale=3)
