# RETIRED (v040-11): the owner ordered the original-cut art pipeline DEAD
# ("nuke all original_art and make our own one"). This tool cut/modded the
# original's own sprites - it must NEVER run again. Our art lives in
# tools/v0411_worm_ours.py (drawn by code, zero original bytes).
# =====================================================================================
#!/usr/bin/env python3
"""contact sheets of the death worm study sprites - the eyes before the hands."""
import os, math, sys
from PIL import Image, ImageDraw

SRC = os.path.expanduser("~/my-project/study_out/deathworm/sprites")
OUT = os.path.expanduser("~/my-project/study_out/deathworm/sheets")
os.makedirs(OUT, exist_ok=True)

FAMS = {}
for f in sorted(os.listdir(SRC)):
    if not f.endswith(".png"): continue
    fam = f.split("_")[0]
    if f.startswith("dbskin_"):
        fam = "dbskin_" + f.split("_")[1] + "_" + f.split("_")[2] + "_" + (f.split("_")[3] if len(f.split("_"))>3 else "")
    FAMS.setdefault(fam, []).append(f)

# also a master sheet with the game families
def sheet(files, out, cell=110, cols=14):
    files = [f for f in files if os.path.exists(os.path.join(SRC, f))]
    if not files: return 0
    rows = math.ceil(len(files)/cols)
    im = Image.new("RGB", (cols*cell, rows*cell+18), (24,26,30))
    d = ImageDraw.Draw(im)
    for i, f in enumerate(files):
        try:
            s = Image.open(os.path.join(SRC, f)).convert("RGBA")
            s.thumbnail((cell-6, cell-6))
            bg = Image.new("RGBA", (cell, cell), (0,0,0,0))
            bg.paste(s, ((cell-s.width)//2, (cell-s.height)//2), s)
            x, y = (i%cols)*cell, (i//cols)*cell
            im.paste(bg.convert("RGB"), (x, y+18), bg.convert("RGBA").split()[3])
        except Exception as e:
            print("!", f, e)
    for i, f in enumerate(files):
        x, y = (i%cols)*cell+2, (i//cols)*cell+18
        d.text((x, y-11), f[:18], fill=(180,220,255))
    im.save(os.path.join(OUT, out))
    return len(files)

if __name__ == "__main__":
    wanted = sys.argv[1] if len(sys.argv) > 1 else None
    total = 0
    for fam in sorted(FAMS):
        if wanted and wanted not in fam: continue
        n = sheet(FAMS[fam], f"{fam}.png")
        total += n
    print("sheets done:", total, "sprites")
