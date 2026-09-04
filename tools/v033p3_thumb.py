#!/usr/bin/env python3
"""v0.3.3 PATCH 3 - the matcher store thumbnail, reborn in the template look:
the plate + a centered gem wall on the pink checker cells + the four NEW
specials (bomb rim / row sweeper stripe / column sweeper stripe / rainbow
remover) + the drop parcel + the GOGACoin. 960x640."""
from PIL import Image, ImageDraw, ImageFilter
import math, random

ROOT = "/home/z/my-project/repo/GOGABox/projects/gogabox/assets"
W, H = 960, 640
random.seed(33)

bg = Image.open(f"{ROOT}/games/matcher/bg/bg_tpl.png").convert("RGBA")
s = max(W / bg.width, H / bg.height)
bg = bg.resize((int(bg.width * s + 0.5), int(bg.height * s + 0.5)), Image.LANCZOS)
im = bg.crop(((bg.width - W) // 2, (bg.height - H) // 2,
              (bg.width - W) // 2 + W, (bg.height - H) // 2 + H)).copy()
d = ImageDraw.Draw(im)

# the plate
plate = Image.open(f"{ROOT}/games/matcher/bg/plate.png").convert("RGBA")
CS = 88                      # cell size on the thumb
COLS, ROWS = 8, 5
bw, bh = COLS * CS, ROWS * CS
bx, by = (W - bw) // 2, (H - bh) // 2 + 14
plate2 = plate.resize((bw + 24, bh + 24), Image.LANCZOS)
im.alpha_composite(plate2, (bx - 12, by - 12))

# the checker cells (the template pair)
cl = Image.open(f"{ROOT}/games/matcher/bg/cell_tpl_light.png").convert("RGBA").resize((CS, CS), Image.LANCZOS)
cd = Image.open(f"{ROOT}/games/matcher/bg/cell_tpl_dark.png").convert("RGBA").resize((CS, CS), Image.LANCZOS)
for r in range(ROWS):
    for c in range(COLS):
        cell = cl if (r + c) % 2 == 0 else cd
        im.alpha_composite(cell, (bx + c * CS, by + r * CS))

# the gems
gems = [Image.open(f"{ROOT}/games/matcher/gems/gem_{i}.png").convert("RGBA").resize((int(CS * 0.94),) * 2, Image.LANCZOS)
        for i in range(5)]
donut = Image.open(f"{ROOT}/games/matcher/gems/donut_1.png").convert("RGBA").resize((int(CS * 0.94),) * 2, Image.LANCZOS)

def put(r, c, tex):
    im.alpha_composite(tex, (bx + c * CS + int(CS * 0.03), by + r * CS + int(CS * 0.03)))

# a quiet wall (no 3-runs) via a simple shuffle-until-quiet
grid = []
for r in range(ROWS):
    row = []
    for c in range(COLS):
        v = random.randrange(5)
        while (c >= 2 and row[-1] == v and row[-2] == v) or \
              (r >= 2 and grid[r - 1][c] == v and grid[r - 2][c] == v):
            v = random.randrange(5)
        row.append(v)
    grid.append(row)
for r in range(ROWS):
    for c in range(COLS):
        put(r, c, gems[grid[r][c]])

# THE FOUR SPECIALS on their gems: bomb (warm rim), rowh (cyan stripe),
# colv (magenta stripe), hyper (rainbow)
def rim_glow(r, c, col):
    gx = bx + c * CS + CS // 2
    gy = by + r * CS + CS // 2
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dg = ImageDraw.Draw(glow)
    dg.ellipse((gx - CS * 0.62, gy - CS * 0.62, gx + CS * 0.62, gy + CS * 0.62),
               fill=col + (110,))
    glow = glow.filter(ImageFilter.GaussianBlur(10))
    im.alpha_composite(glow)

def stripe(r, c, col, vertical):
    gx = bx + c * CS + CS // 2
    gy = by + r * CS + CS // 2
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dg = ImageDraw.Draw(glow)
    if vertical:
        dg.rectangle((gx - 7, gy - CS * 0.55, gx + 7, gy + CS * 0.55), fill=col + (200,))
    else:
        dg.rectangle((gx - CS * 0.55, gy - 7, gx + CS * 0.55, gy + 7), fill=col + (200,))
    glow = glow.filter(ImageFilter.GaussianBlur(4))
    im.alpha_composite(glow)

def rainbow(r, c):
    gx = bx + c * CS + CS // 2
    gy = by + r * CS + CS // 2
    rr = CS * 0.5
    steps = 36
    for i in range(steps):
        a0 = 2 * math.pi * i / steps
        a1 = 2 * math.pi * (i + 1) / steps
        hue = (i / steps) * 360
        import colorsys
        col = tuple(int(v * 255) for v in colorsys.hsv_to_rgb(hue / 360, 0.9, 1.0))
        d.pieslice((gx - rr, gy - rr, gx + rr, gy + rr), math.degrees(a0), math.degrees(a1),
                   fill=col + (235,))
    core = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dc = ImageDraw.Draw(core)
    dc.ellipse((gx - 14, gy - 14, gx + 14, gy + 14), fill=(255, 255, 255, 230))
    im.alpha_composite(core)

# special positions (r, c)
sb = (1, 1)   # bomb - warm
sr = (1, 6)   # row sweeper - cyan
sc = (3, 3)   # column sweeper - magenta
sh = (3, 6)   # the remover - rainbow
rim_glow(*sb, (255, 140, 40))
stripe(*sr, (120, 230, 255), vertical=False)
stripe(*sc, (255, 130, 235), vertical=True)
# the remover replaces its gem entirely
gx = bx + sh[1] * CS + CS // 2
gy = by + sh[0] * CS + CS // 2
rainbow(*sh)
d.ellipse((gx - CS * 0.5, gy - CS * 0.5, gx + CS * 0.5, gy + CS * 0.5),
          outline=(255, 255, 255, 240), width=4)

# the parcel on the wall (a drop-down taste) + the coin
parcel = Image.open(f"{ROOT}/games/matcher/modes/item_parcel.png").convert("RGBA")
parcel = parcel.resize((int(CS * 0.9),) * 2, Image.LANCZOS)
put(4, 4, parcel)
coin = Image.open(f"{ROOT}/ui/coin.png").convert("RGBA")
coin = coin.resize((int(CS * 0.8),) * 2, Image.LANCZOS)
put(4, 1, coin)

# the wordmark
d = ImageDraw.Draw(im)
d.rounded_rectangle((W // 2 - 210, 18, W // 2 + 210, 84), radius=18, fill=(30, 34, 52, 210))
d.text((W // 2, 50), "MATCHER", anchor="mm", fill=(255, 244, 200))

im.convert("RGB").save(f"{ROOT}/thumbs/matcher.png")
print("thumb reborn", im.size)
