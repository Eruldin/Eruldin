from montage import sheet
import glob, os
BASE = "dcss/Dungeon Crawl Stone Soup Full"
names = [
 "monster/death_knight.png","monster/hell_knight_new.png","monster/deep_elf_blademaster.png",
 "monster/deep_elf_knight_new.png","monster/daeva.png","monster/angel.png","monster/anubis_guard.png",
 "monster/orc_knight_new.png","monster/tengu_reaver.png","monster/ironbrand_convoker.png",
 "monster/ironheart_preserver.png","monster/orb_guardian_new.png","monster/vault/vault_guard.png",
 "monster/spriggan_defender.png","monster/deep_dwarf_death_knight.png","monster/human_new.png",
 "monster/grand_avatar.png","monster/titan_new.png","monster/minotaur.png","monster/glowing_shapeshifter.png",
]
# bosses
names += ["monster/demons/balrug_new.png","monster/demons/fiend.png","monster/demons/demonic_crawler.png",
 "monster/dragons/fire_dragon_new.png" ,"monster/dragons/ice_dragon_new.png","monster/dragons/golden_dragon.png" if os.path.exists(BASE+"/monster/dragons/golden_dragon.png") else "monster/golden_dragon.png",
 "monster/undead/bone_dragon_new.png","monster/juggernaut.png","monster/ettin_new.png","monster/demons/green_death.png",
 "monster/demons/executioner.png","monster/cyclops_new.png","monster/demons/pandemonium_lord.png"]
names = [n for n in names if os.path.exists(BASE+"/"+n)]
sheet(names, "sel_heroes_bosses.png", cols=16, cell=56, scale=3)
