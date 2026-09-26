from montage import sheet
import os
BASE = "dcss/Dungeon Crawl Stone Soup Full"
# humanoid warriors for Ely
import glob
pl = sorted(glob.glob(BASE+"/player/base/*.png"))
names = [os.path.relpath(p,BASE) for p in pl]
# pick fighter-looking ones: human, paladin-ish, merfolk, demonspawn
want = [n for n in names if any(k in n for k in ["human","demonspawn_red_male","demigod","halfling","kobold","ogre_male","troll","naga","felid","minotaur","centaur_brown_male","deep_dwarf_male","gargoyle_male","ghoul","mummy","octopode","spriggan","vine_stalker","felids"])]
sheet(want[:48], "sel_players.png")
