from PIL import Image
import os, sys

BASE = "dcss/Dungeon Crawl Stone Soup Full"
def sheet(paths, out, cell=40, cols=16, scale=2):
    tiles = []
    for p in paths:
        fp = os.path.join(BASE, p)
        if os.path.exists(fp):
            tiles.append((p, fp))
    if not tiles:
        print("EMPTY", out); return
    rows = (len(tiles)+cols-1)//cols
    img = Image.new("RGB", (cols*cell, rows*cell), (30,30,34))
    from PIL import ImageDraw
    d = ImageDraw.Draw(img)
    for i,(name,fp) in enumerate(tiles):
        im = Image.open(fp).convert("RGBA")
        im = im.resize((im.width*scale, im.height*scale), Image.NEAREST)
        x, y = (i%cols)*cell, (i//cols)*cell
        img.paste(im, (x+ (cell-im.width)//2, y+(cell-im.height)//2), im)
        d.text((x+2,y+1), str(i), fill=(255,80,80))
    img.save(out)
    with open(out+".txt","w") as f:
        for i,(name,_) in enumerate(tiles): f.write(f"{i}\t{name}\n")
    print(out, len(tiles), "tiles")
