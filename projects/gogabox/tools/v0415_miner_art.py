#!/usr/bin/env python3
"""
v0415 GOLD MINER ART FORGE
Cuts + code-modifies the scraped gamesnacks goldminertom assets (the owner's
scrape law) into assets/games/goldminer/.

Outputs:
  rig_<skin>.png x5        the composed miner rig (tower + miner + winch)
  claw_open.png            the swinging claw (bare, from hook-sheet1)
  claw_closed.png          code-modified: prongs rotated inward (grips items)
  gold_<skin>_{s,m,l}.png  the golds (g2/g3/g4) x5 vein skins
  rock_<skin>_{s,s2,m,l}.png  rocks (r1, r2, rock, rock*1.35) x5 vein skins
  bomb.png                 the bomb (never skinned - the owner's law)
  coin.png                 the glowing GOGACoin gold (g1 + baked glow)
  dust.png / dust_dark.png the drag-trail puffs (the darker-dust law)
  fx_explode_0..5.png      the blast frames (sheet0 4 + sheet1 2)
  bg_surface.png           1080x360 sky + silhouette + surface line
  bg_field.png             1080x1460 the dirt field texture
  bg_bedrock.png           1080x180 the bottom bedrock strip
  logo.png                 the GOLD MINER intro logo (from title-sheet0)
Every output lands in a montage the eye pass reviews.
"""
import os, math
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

SRC = "/home/z/my-project/study_locker/gamesnacks/goldminertom/images"
OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/games/goldminer"
MON = "/home/z/my-project/study_locker/gamesnacks/goldminertom/montages"
os.makedirs(OUT, exist_ok=True)
os.makedirs(MON, exist_ok=True)

def load(n):
    return Image.open(f"{SRC}/{n}").convert("RGBA")

def save(im, n):
    im.save(f"{OUT}/{n}")
    return im

# ---------------------------------------------------------------- hsv helpers
def rgb_to_hsv_px(r, g, b):
    r_, g_, b_ = r/255.0, g/255.0, b/255.0
    mx, mn = max(r_, g_, b_), min(r_, g_, b_)
    d = mx - mn
    if d == 0: h = 0.0
    elif mx == r_: h = ((g_-b_)/d) % 6
    elif mx == g_: h = (b_-r_)/d + 2
    else: h = (r_-g_)/d + 4
    return h*60.0, (0.0 if mx == 0 else d/mx), mx

def hsv_shift(im, dh=0.0, s_mul=1.0, v_mul=1.0, sat_lo=0.25, mask_only=None):
    """Hue-shift pixels whose saturation > sat_lo (keeps steel/white/ink)."""
    im = im.copy(); px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0: continue
            h, s, v = rgb_to_hsv_px(r, g, b)
            if s < sat_lo: continue
            if mask_only is not None and not mask_only(h, s, v): continue
            h2 = (h + dh) % 360.0
            s2 = min(1.0, s*s_mul); v2 = min(1.0, v*v_mul)
            c = v2*s2; x2 = c*(1 - abs((h2/60.0) % 2 - 1)); m = v2 - c
            if h2 < 60: rr, gg, bb = c, x2, 0.0
            elif h2 < 120: rr, gg, bb = x2, c, 0.0
            elif h2 < 180: rr, gg, bb = 0.0, c, x2
            elif h2 < 240: rr, gg, bb = 0.0, x2, c
            elif h2 < 300: rr, gg, bb = x2, 0.0, c
            else: rr, gg, bb = c, 0.0, x2
            px[x, y] = (int((rr+m)*255), int((gg+m)*255), int((bb+m)*255), a)
    return im

def recolor_all(im, dh, s_mul=1.0, v_mul=1.0):
    return hsv_shift(im, dh, s_mul, v_mul, sat_lo=0.0)

# ================================================================ 1. THE CLAW
sheet1 = load("hook-sheet1.png")
sheet0 = load("hook-sheet0.png")

claw_open = sheet1.crop((138, 60, 200, 108))
save(claw_open, "claw_open.png")

# measure the hub: the steel wheel = topmost dense gray blob. Scan rows.
def hub_center(im):
    px = im.load(); best = None
    for y in range(im.height):
        run = 0; start = None
        for x in range(im.width):
            r, g, b, a = px[x, y]
            steel = a > 120 and abs(r-g) < 34 and abs(g-b) < 34 and 120 < r < 215
            if steel:
                if start is None: start = x
                run += 1
            else:
                if run >= 8:
                    return (start + run/2.0, y + 5.0)
                run = 0; start = None
        if run >= 8:
            return (start + run/2.0, y + 5.0)
    return (im.width/2.0, 8.0)

hx, hy = hub_center(claw_open)
print(f"claw hub measured at ({hx:.1f},{hy:.1f}) in {claw_open.size}")

# CLOSED CLAW: rotate each prong inward around the hub.
def build_closed(im, hx, hy, angle=42, swap=False):
    w, h = im.size
    pad = 26
    def padded(layer):
        p = Image.new("RGBA", (w + pad*2, h + pad*2), (0, 0, 0, 0))
        p.alpha_composite(layer, (pad, pad))
        return p
    px = im.load()
    left = Image.new("RGBA", im.size, (0, 0, 0, 0))
    right = Image.new("RGBA", im.size, (0, 0, 0, 0))
    hub = Image.new("RGBA", im.size, (0, 0, 0, 0))
    lp, rp, hp = left.load(), right.load(), hub.load()
    HW = 9   # the hub wheel's half width: never rotated (stays round)
    for y in range(h):
        for x in range(w):
            p = px[x, y]
            if p[3] == 0: continue
            if x < hx - HW: lp[x, y] = p
            elif x > hx + HW: rp[x, y] = p
            else: hp[x, y] = p
    hub_l = (hx + pad, hy + pad)     # pivot in the PADDED layer's coords
    la, ra = ((angle, -angle) if swap else (-angle, angle))
    # rotate the PADDED prong layers (never clip their own rect), then erase
    # everything swept ABOVE the hub (the arm tails' stray streaks)
    def sweep(layer, ang):
        r = padded(layer).rotate(ang, center=hub_l, resample=Image.BICUBIC)
        rp2 = r.load()
        for y in range(0, int(hub_l[1]) - 6):
            for x in range(r.width):
                rp2[x, y] = (0, 0, 0, 0)
        return r
    left_r = sweep(left, la)
    right_r = sweep(right, ra)
    canvas = Image.new("RGBA", (w + pad*2, h + pad*2), (0, 0, 0, 0))
    canvas.alpha_composite(left_r)
    canvas.alpha_composite(right_r)
    canvas.alpha_composite(padded(hub))   # the hub rides unrotated on top
    # keep only the largest connected component: the sweep's stray wisps
    # are separate islands - they die here
    cp = canvas.load()
    cmask = [[1 if cp[x, y][3] > 30 else 0 for x in range(canvas.width)]
                    for y in range(canvas.height)]
    cseen = [[False]*canvas.width for _ in range(canvas.height)]
    cbest = None
    for yy in range(canvas.height):
        for xx in range(canvas.width):
            if cmask[yy][xx] and not cseen[yy][xx]:
                stack = [(xx, yy)]; cseen[yy][xx] = True
                cells = []
                while stack:
                    cx2, cy2 = stack.pop(); cells.append((cx2, cy2))
                    for dx, dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,-1),(1,-1),(-1,1)):
                        nx, ny = cx2+dx, cy2+dy
                        if 0 <= nx < canvas.width and 0 <= ny < canvas.height \
                                        and cmask[ny][nx] and not cseen[ny][nx]:
                            cseen[ny][nx] = True; stack.append((nx, ny))
                if cbest is None or len(cells) > len(cbest):
                    cbest = cells
    keep2 = set(cbest)
    clean = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    opn = clean.load()
    for (cx2, cy2) in keep2:
        opn[cx2, cy2] = cp[cx2, cy2]
    canvas = clean
    # crop to CONTENT - the closed prongs reach below the open bbox
    cb = canvas.getbbox()
    return canvas.crop(cb), (hx + pad - cb[0], hy + pad - cb[1])

# prong law: the open claw's tips hang bottom-left / bottom-right; closing
# swings each tip INWARD toward bottom-center = left prong CCW, right CW.
claw_closed, hub_c = build_closed(claw_open, hx, hy, 30, swap=True)
save(claw_closed, "claw_closed.png")

# ================================================================ 2. THE RIG
# tower (elevator) + miner head/body/arm + winch roll, composed on one canvas.
tower = load("elevator-sheet0.png")          # 173x231 wooden frame
head = load("miner_miner_h1-sheet0.png")     # 86x88
body = load("miner_miner_bodym-sheet0.png")  # 66x68
arm = load("miner_miner_arm-sheet0.png")     # 38x49 (holds the crank)
roll = load("miner_miner_roll-sheet0.png")   # 73x68 wooden winch
shadow = load("miner_miner_shadow-sheet0.png")

RIG_W, RIG_H = 360, 300
def build_rig():
    c = Image.new("RGBA", (RIG_W, RIG_H), (0, 0, 0, 0))
    # tower right of center; miner left, cranking the roll at tower's base
    c.alpha_composite(tower, (RIG_W - tower.width - 18, RIG_H - tower.height - 6))
    # the miner rides INSIDE the frame
    c.alpha_composite(shadow, (RIG_W - tower.width + 2, RIG_H - 40))
    c.alpha_composite(body, (RIG_W - tower.width - 14, RIG_H - body.height - 44))
    c.alpha_composite(head, (RIG_W - tower.width - 6, RIG_H - head.height - 72))
    c.alpha_composite(arm, (RIG_W - tower.width + 38, RIG_H - 108))
    # the winch roll at the tower's top: THE ROPE ANCHOR
    rx = RIG_W - tower.width + 34
    c.alpha_composite(roll, (rx, 26))
    return c, (rx + roll.width // 2, 26 + 20)   # anchor = roll hub

rig_classic, ANCHOR = build_rig()
save(rig_classic, "rig_classic.png")
print(f"rig anchor (rope hub) at {ANCHOR} on {rig_classic.size}")

MINER_SKINS = [
    ("classic", 0.0, 1.0, 1.0),
    ("emerald", 96.0, 0.9, 1.02),
    ("royal", 216.0, 1.05, 1.0),
    ("crimson", -38.0, 1.12, 1.0),
    ("frost", 168.0, 0.75, 1.06),
]
for sid, dh, sm, vm in MINER_SKINS:
    if sid == "classic": continue
    # sat floor 0.38: the saturated CLOTHES recolor, the wood tower + hat
    # keep their material (the skin law: the miner re-dresses, the wood
    # stays wood)
    save(hsv_shift(rig_classic, dh, sm, vm, sat_lo=0.38), f"rig_{sid}.png")

# ================================================================ 3. ITEMS
g2 = load("g2-sheet0.png")     # 66x57  -> gold S
g3 = load("g3-sheet0.png")     # 141x120 -> gold M
g4 = load("g4-sheet0.png")     # 168x148 -> gold L
r1 = load("r1-sheet0.png")     # 70x58  -> rock S
r2 = load("r2-sheet0.png")     # 71x71  -> rock S alt
rk = load("rock-sheet0.png")   # 128x128 -> rock M
bomb = load("bombsprite-sheet0.png")
# the sheet carries bomb + dashed ring + X marker: keep the LARGEST
# connected component's PIXELS (mask out everything else), then bbox
bp = bomb.load()
bmask = [[1 if bp[x, y][3] > 40 else 0 for x in range(bomb.width)] for y in range(bomb.height)]
seen = [[False]*bomb.width for _ in range(bomb.height)]
best = None
for yy in range(bomb.height):
    for xx in range(bomb.width):
        if bmask[yy][xx] and not seen[yy][xx]:
            stack = [(xx, yy)]; seen[yy][xx] = True
            minx = maxx = xx; miny = maxy = yy; area = 0; cells = []
            while stack:
                cx, cy = stack.pop(); area += 1; cells.append((cx, cy))
                minx = min(minx, cx); maxx = max(maxx, cx)
                miny = min(miny, cy); maxy = max(maxy, cy)
                for dx, dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,-1),(1,-1),(-1,1)):
                    nx, ny = cx+dx, cy+dy
                    if 0 <= nx < bomb.width and 0 <= ny < bomb.height and bmask[ny][nx] and not seen[ny][nx]:
                        seen[ny][nx] = True; stack.append((nx, ny))
            if best is None or area > best[0]:
                best = (area, minx, miny, maxx, maxy, cells)
keep = set(best[5])
out = Image.new("RGBA", (best[3]-best[1]+5, best[4]-best[2]+5), (0, 0, 0, 0))
op = out.load()
for (cx, cy) in keep:
    op[cx-best[1]+2, cy-best[2]+2] = bp[cx, cy]
bomb_c = out
print(f"bomb crop {bomb_c.size} (component area {best[0]}) from {bomb.size}")
save(bomb_c, "bomb.png")

rock_l = rk.resize((int(rk.width*1.35), int(rk.height*1.35)), Image.LANCZOS)

def gold_mask(h, s, v):
    return s > 0.35 and 30 < h < 62

def rock_mask(h, s, v):
    return s > 0.08 and v < 0.92

VEIN_SKINS = [
    ("classic", None, None),
    ("emerald", ("gold", 88.0, 0.9, 1.0), ("rock", 70.0, 0.55, 0.9)),
    # gold base hue ~55: amethyst -> 275 (dh+220), candy pink -> 330 (dh-85),
    # obsidian -> dark ember (dh-8, value crushed)
    ("amethyst", ("gold", 220.0, 1.02, 0.98), ("rock", 250.0, 0.5, 0.82)),
    ("candy", ("gold", -85.0, 1.15, 1.08), ("rock", 195.0, 0.6, 1.05)),
    ("obsidian", ("gold", -8.0, 1.35, 0.78), ("rock", 0.0, 0.25, 0.5)),
]
GOLDS = {"s": g2, "m": g3, "l": g4}
ROCKS = {"s": r1, "s2": r2, "m": rk, "l": rock_l}
for vid, gspec, rspec in VEIN_SKINS:
    for k, im in GOLDS.items():
        out = im if vid == "classic" else hsv_shift(im, *gspec[1:], sat_lo=0.3, mask_only=gold_mask)
        save(out, f"gold_{vid}_{k}.png")
    for k, im in ROCKS.items():
        out = im if vid == "classic" else hsv_shift(im, *rspec[1:], sat_lo=0.06, mask_only=rock_mask)
        save(out, f"rock_{vid}_{k}.png")

# ================================================================ 4. THE COIN
g1 = load("g1-sheet0.png")
spark = load("shinetitle-sheet0.png")
coin = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
glow = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.ellipse([10, 10, 86, 86], fill=(255, 220, 90, 110))
glow = glow.filter(ImageFilter.GaussianBlur(10))
coin.alpha_composite(glow)
big_g1 = g1.resize((56, 50), Image.LANCZOS)
coin.alpha_composite(big_g1, (20, 23))
sp = spark.resize((30, 30), Image.LANCZOS)
coin.alpha_composite(sp, (44, 6))
coin.alpha_composite(sp.resize((18, 18), Image.LANCZOS), (14, 52))
save(coin, "coin.png")

# ================================================================ 5. DUST
dust = load("dustparticle.png")
d1 = ImageEnhance.Brightness(dust).enhance(0.55)
save(d1, "dust.png")
d2 = ImageEnhance.Brightness(dust).enhance(0.34)
save(d2, "dust_dark.png")

# ================================================================ 6. EXPLOSION
ex0 = load("expoanimation-sheet0.png")
ex1 = load("expoanimation-sheet1.png")
for i in range(4):
    save(ex0.crop((i % 2*256, i//2*256, i % 2*256+256, i//2*256+256)), f"fx_explode_{i}.png")
# sheet1's two extra frames cut at the pack seam - the 4 clean cells above
# carry the whole blast (smoke -> ring -> pebbles -> sparkle); dropped.

# ================================================================ 7. BACKGROUNDS
ground = load("groundtile.png")       # 512x50 surface line
sil = load("gametopbg.png")           # 478x190 dark skyline
bt1 = load("bgtile1.png")             # 502x90 dark band
bt2 = load("bgtile2.png")             # 505x105
bt3 = load("bgtile3.png")             # 366x90
bt4 = load("bgtile4.png")             # 272x257 dirt clumps
bed = load("bottomtile.png")          # 765x358 striped bedrock

W = 1080
SURF_H = 360
surf = Image.new("RGBA", (W, SURF_H))
dr = ImageDraw.Draw(surf)
# dusk sky: plum -> warm horizon (the live title palette)
for y in range(SURF_H):
    t = y / SURF_H
    r = int(46 + (122-46)*t); g = int(34 + (74-34)*t); b = int(52 + (56-52)*t)
    dr.line([(0, y), (W, y)], fill=(r, g, b))
# the dark rocky silhouette rides the horizon (tiled, 2 rows depth)
silrow = Image.new("RGBA", (W, sil.height))
for i in range(0, W, sil.width):
    silrow.alpha_composite(sil, (i, 0))
surf.alpha_composite(silrow, (0, SURF_H - 210))
# surface line (the grass/dirt lip the rig stands on) tiled + a darker lip
grow = Image.new("RGBA", (W, ground.height))
for i in range(0, W, ground.width - 2):
    grow.alpha_composite(ground, (i, 0))
surf.alpha_composite(grow, (0, SURF_F := SURF_H - ground.height))
dr2 = ImageDraw.Draw(surf)
dr2.rectangle([0, SURF_H - 26, W, SURF_H], fill=(38, 22, 14, 255))
save(surf, "bg_surface.png")

FIELD_H = 1460
field = Image.new("RGBA", (W, FIELD_H))
fd = ImageDraw.Draw(field)
fd.rectangle([0, 0, W, FIELD_H], fill=(74, 47, 34, 255))   # the live dirt base
# the lighter brown wavy blobs (the live look), seeded deterministic
import random
rng = random.Random(20260919)
for i in range(90):
    bx = rng.randint(-60, W); by = rng.randint(0, FIELD_H)
    bw = rng.randint(90, 260); bh = int(bw*rng.uniform(0.45, 0.7))
    tone = rng.choice([(88, 58, 41), (97, 64, 45), (82, 52, 37), (104, 70, 48)])
    fd.ellipse([bx, by, bx+bw, by+bh], fill=tone + (255,))
# the bgtile4 clump pass is DROPPED (the film pass: the pebble clusters
# read as mud splats over the soft blob dirt - the blobs alone carry it)
# deep vignette toward the bottom (the deeper, the darker)
vig = Image.new("L", (1, FIELD_H))
for y in range(FIELD_H):
    t = y / FIELD_H
    vig.putpixel((0, y), int(255 - 70*t))
vig = vig.resize((W, FIELD_H))
r_, g_, b_, a_ = field.split()
va = a_.point(lambda v: v)
dark = Image.new("RGBA", (W, FIELD_H), (20, 10, 6, 255))
field = Image.composite(field, Image.alpha_composite(dark, field), vig)
save(field, "bg_field.png")

BED_H = 190
bedrock = Image.new("RGBA", (W, BED_H))
brow = bed.resize((int(bed.width*BED_H/bed.height), BED_H), Image.LANCZOS)
for i in range(0, W, brow.width - 2):
    bedrock.alpha_composite(brow, (i, 0))
save(bedrock, "bg_bedrock.png")

# ================================================================ 8. LOGO
title = load("title-sheet0.png")
# the sheet stacks TWO renders of the wordmark: split at the transparent
# gap row between them, keep the top one
tp = title.load()
gap = None
for y in range(8, title.height):
    if all(tp[x, y][3] == 0 for x in range(title.width)):
        # a real gap: at least 6 consecutive empty rows
        if all(all(tp[x, y+k][3] == 0 for x in range(title.width))
                for k in range(6) if y+k < title.height):
            gap = y
            break
if gap is None: gap = title.height // 2
logo = title.crop((0, 0, title.width, gap))
lb = logo.getbbox()
logo = logo.crop(lb)
save(logo, "logo.png")
print(f"logo cut {logo.size} (gap at y={gap}) from bbox {lb}")

# ================================================================ 9. THE EYE PASS MONTAGE
names = sorted(n for n in os.listdir(OUT) if n.endswith(".png"))
cell = 200; cols = 8
rows = (len(names) + cols - 1)//cols
M = Image.new("RGBA", (cols*cell, rows*(cell + 18)), (40, 40, 60, 255))
md = ImageDraw.Draw(M)
for i, n in enumerate(names):
    im = Image.open(f"{OUT}/{n}").convert("RGBA")
    sc = min((cell-10)/im.width, (cell-10)/im.height, 1.0)
    if sc < 1.0:
        im = im.resize((max(1, int(im.width*sc)), max(1, int(im.height*sc))))
    x = (i % cols)*cell; y = (i//cols)*(cell + 18)
    M.paste(im, (x + (cell-im.width)//2, y + (cell-im.height)//2), im)
    md.text((x + 6, y + cell + 2), n[:26], fill=(255, 255, 160, 255))
M.save(f"{MON}/forge_out.png")
print(f"FORGE DONE: {len(names)} files -> {OUT}")
