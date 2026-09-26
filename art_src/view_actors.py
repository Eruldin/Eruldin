from PIL import Image
import json, os
OUT = "../art"
m = json.load(open(OUT+"/manifest.json"))
# show: ely composite, one frame of each enemy kind skin, bosses, npcs
keys = ["ely","husk","husk_1","husk_2","husk_3","spitter","spitter_1","spitter_2","spitter_3",
        "turret","turret_1","turret_2","turret_3","drone","drone_1","drone_2","drone_3",
        "sentinel","sentinel_1","sentinel_2","sentinel_3","rex","host","nahum","tuman","kirin","const"]
cell, cols = 72, 14
rows = (len(keys)+cols-1)//cols + 1
img = Image.new("RGB", (cols*cell, rows*cell), (28,28,32))
from PIL import ImageDraw
d = ImageDraw.Draw(img)
names = []
i = 0
for k in keys:
    f = m["frames"].get(k,{}).get("idle",[None])[0]
    if f:
        im = Image.open(OUT+"/"+f.split("/")[-1]).convert("RGBA")
        x,y = (i%cols)*cell,(i//cols)*cell
        img.paste(im,(x+4,y+2),im)
        d.text((x+3,y+cell-9), k[:11], fill=(255,255,120))
    i += 1
# npc row
for j,nid in enumerate(["rhasa","neva","saphire","vane"]):
    im = Image.open(OUT+f"/npc2_{nid}.png").convert("RGBA")
    x,y = j*cell, rows-1
    img.paste(im,(x+4,y*cell+2),im)
    d.text((x+3,y*cell+cell-9), nid, fill=(255,255,120))
img.save("view_actors.png")
print("ok")
