#!/usr/bin/env python3
# ============================================================================
# v034 COSMIC SPUD - the art pipeline.
# Curates the CC0 kenney/OGA hunt (download/cs_assets/raw/sprites) into the
# repo and PIL-draws everything the hunt could not cover:
#   SPUDNIK (the potato cosmonaut), the 12 enemies, 3 bosses, 12 weapons
#   (icon + world sprite), bullets, pickups, and 4 SEAMLESS theme grounds
#   (decayed desert day/night, abandoned park day/night).
# Every output lands in projects/gogabox/assets/games/cosmic_spud/.
# Provenance: assets.manifest.json + docs/goga_docs/gogames_ideas/cosmic_spud.md
# ============================================================================
import math, os, random, shutil
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

RAW = "/home/z/my-project/download/cs_assets/raw/sprites"
OUT = "/home/z/my-project/repo/GOGABox/projects/gogabox/assets/games/cosmic_spud"
for d in ["hero", "enemies", "weapons", "bullets", "pickups", "fx", "ground",
          "props", "ui"]:
    os.makedirs(f"{OUT}/{d}", exist_ok=True)

# ----------------------------------------------------------------- palette
DES_DAY = {"base": (196, 158, 106), "alt": (184, 146, 96), "deco": (150, 116, 72)}
DES_NGT = {"base": (58, 54, 84), "alt": (52, 48, 76), "deco": (84, 78, 118)}
PRK_DAY = {"base": (116, 154, 92), "alt": (106, 144, 84), "deco": (88, 124, 70)}
PRK_NGT = {"base": (44, 62, 58), "alt": (38, 56, 52), "deco": (66, 96, 86)}

def save(img, rel):
    img.save(f"{OUT}/{rel}")
    print("wrote", rel, img.size)

# ============================================================ ground baking
def bake_ground(pal, cracks, seed, rel, glints=False):
    # seamless 640x360: per-32px cell shade variation on a WRAPPED grid +
    # sparse decals, so in-engine tiling never shows a seam.
    random.seed(seed)
    W, H = 640, 360
    img = Image.new("RGB", (W, H))
    px = img.load()
    cw, ch = 32, 36
    # wrapped cell brightness grid
    cells = {}
    for cy in range(-1, H // ch + 2):
        for cx in range(-1, W // cw + 2):
            cells[(cx, cy)] = random.uniform(-14, 14)
    for y in range(H):
        fy = y / ch
        cy0, cy1 = int(math.floor(fy)), int(math.floor(fy)) + 1
        ty = fy - math.floor(fy)
        for x in range(W):
            fx = x / cw
            cx0, cx1 = int(math.floor(fx)), int(math.floor(fx)) + 1
            tx = fx - math.floor(fx)
            v00 = cells[((cx0 + 64) % 64, (cy0 + 64) % 64)]
            v10 = cells[((cx1 + 64) % 64, (cy0 + 64) % 64)]
            v01 = cells[((cx0 + 64) % 64, (cy1 + 64) % 64)]
            v11 = cells[((cx1 + 64) % 64, (cy1 + 64) % 64)]
            v = (v00 * (1 - tx) * (1 - ty) + v10 * tx * (1 - ty)
                 + v01 * (1 - tx) * ty + v11 * tx * ty)
            base = pal["alt"] if (cx0 + cy0) % 2 == 0 else pal["base"]
            px[x, y] = tuple(max(0, min(255, int(c + v))) for c in base)
    d = ImageDraw.Draw(img)
    # cracks / grass tufts (wrapped: draw at x and x-W to stay seamless)
    for i in range(cracks):
        x, y = random.randint(0, W), random.randint(0, H)
        pts, a, ln = [], random.uniform(0, math.pi), random.randint(18, 46)
        cxp, cyp = x, y
        for s in range(6):
            a += random.uniform(-0.5, 0.5)
            cxp += math.cos(a) * ln / 6
            cyp += math.sin(a) * ln / 6
            pts.append((cxp, cyp))
        for ox in (-W, 0, W):
            d.line([(px_ + ox, py_) for px_, py_ in pts],
                   fill=pal["deco"], width=2)
    # pebbles / flowers
    for i in range(46):
        x, y, r = random.randint(0, W), random.randint(0, H), random.randint(1, 3)
        c = tuple(max(0, min(255, int(c * random.uniform(0.72, 0.9))))
                  for c in pal["base"])
        for ox in (-W, 0, W):
            d.ellipse([x - r + ox, y - r, x + r + ox, y + r], fill=c)
    if glints:  # night minerals / fireflies seeds
        for i in range(16):
            x, y, r = random.randint(0, W), random.randint(0, H), random.randint(1, 2)
            d.ellipse([x - r, y - r, x + r, y + r], fill=(140, 220, 255, 200))
    save(img, rel)

bake_ground(DES_DAY, 26, 3411, "ground/desert_day.png")
bake_ground(DES_NGT, 26, 7788, "ground/desert_night.png", glints=True)
bake_ground(PRK_DAY, 40, 5150, "ground/park_day.png")
bake_ground(PRK_NGT, 40, 9912, "ground/park_night.png", glints=True)

# ================================================================== SPUDNIK
def spudnik(size=64):
    # facing RIGHT (angle 0) - the engine rotates it to the aim
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    # boots
    d.ellipse([cx - 22, cy + 8, cx - 6, cy + 20], fill=(84, 62, 40))
    d.ellipse([cx + 2, cy + 10, cx + 18, cy + 22], fill=(72, 52, 34))
    # potato body (soft radial shading)
    body = [cx - 20, cy - 16, cx + 20, cy + 18]
    for i, r in enumerate([(212, 168, 96), (198, 152, 84), (180, 134, 72)]):
        inset = i * 3
        d.ellipse([body[0] + inset, body[1] + inset,
                   body[2] - inset, body[3] - inset], fill=r + (255,))
    # potato eyes (dark speckles)
    for sx, sy, r in [(-10, -4, 2.6), (6, 2, 2.2), (-2, 8, 1.8), (12, -8, 1.6)]:
        d.ellipse([cx + sx - r, cy + sy - r, cx + sx + r, cy + sy + r],
                  fill=(120, 88, 46, 255))
    # face: two big eyes looking right
    for ex in (-4, 10):
        d.ellipse([cx + ex - 4, cy - 8, cx + ex + 4, cy], fill=(255, 255, 255, 255))
        d.ellipse([cx + ex + 1, cy - 6, cx + ex + 4, cy - 3], fill=(30, 30, 40, 255))
    # glass dome helmet
    dome = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    dd = ImageDraw.Draw(dome)
    dd.ellipse([cx - 24, cy - 26, cx + 24, cy + 6], fill=(150, 230, 255, 58))
    dd.ellipse([cx - 24, cy - 26, cx + 24, cy + 6], outline=(200, 245, 255, 210), width=3)
    dd.arc([cx - 18, cy - 22, cx + 2, cy - 8], 200, 300,
           fill=(255, 255, 255, 190), width=3)
    img.alpha_composite(dome)
    # antenna
    d.line([cx - 2, cy - 26, cx - 2, cy - 34], fill=(210, 210, 220, 255), width=3)
    d.ellipse([cx - 5, cy - 38, cx + 1, cy - 32], fill=(255, 90, 90, 255))
    return img

save(spudnik(64), "hero/spudnik.png")

# ================================================================== enemies
def blob(size, base, dark, eyes=2, spots=None, outline=None):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = size // 2
    r = size // 2 - 4
    d.ellipse([c - r, c - r, c + r, c + r], fill=dark + (255,))
    d.ellipse([c - r + 3, c - r + 3, c + r - 3, c + r - 3], fill=base + (255,))
    if spots:
        for sx, sy, sr in spots:
            d.ellipse([c + sx - sr, c + sy - sr, c + sx + sr, c + sy + sr],
                      fill=dark + (255,))
    for ex in range(eyes):
        exx = c - r // 3 + ex * (2 * r // 3)
        d.ellipse([exx - 4, c - 6, exx + 4, c + 4], fill=(255, 255, 255, 255))
        d.ellipse([exx - 1, c - 4, exx + 3, c + 1], fill=(24, 20, 30, 255))
    if outline:
        d.ellipse([c - r, c - r, c + r, c + r], outline=outline + (230,), width=2)
    return img

save(blob(44, (226, 74, 64), (168, 44, 38), spots=[(6, 8, 3), (-10, -8, 2)]),
     "enemies/blab.png")
save(blob(34, (240, 150, 54), (186, 104, 30)), "enemies/sprinter.png")
save(blob(56, (158, 92, 214), (108, 54, 158), spots=[(10, 6, 5), (-12, 2, 4), (2, -12, 3)]),
     "enemies/chunk.png")
# spitter: green tripod - blob + legs
img = blob(46, (98, 200, 92), (54, 140, 52))
d = ImageDraw.Draw(img)
d.line([16, 34, 10, 44], fill=(54, 140, 52, 255), width=4)
d.line([30, 34, 36, 44], fill=(54, 140, 52, 255), width=4)
d.line([23, 36, 23, 44], fill=(54, 140, 52, 255), width=4)
d.ellipse([19, 4, 27, 12], fill=(30, 90, 30, 255))
save(img, "enemies/spitter.png")
# aura wraith: ghost with tail wisps
img = Image.new("RGBA", (56, 56), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.polygon([(28, 6), (46, 22), (42, 46), (36, 38), (28, 48), (20, 38), (14, 46), (10, 22)],
          fill=(168, 108, 240, 235))
d.polygon([(28, 10), (42, 24), (38, 40), (28, 34), (18, 40), (14, 24)],
          fill=(196, 140, 255, 235))
for ex in (22, 32):
    d.ellipse([ex - 2, 20, ex + 2, 26], fill=(255, 255, 255, 255))
    d.ellipse([ex, 22, ex + 2, 25], fill=(60, 20, 90, 255))
save(img, "enemies/wraith.png")
# broodmother: yellow with egg sac
img = blob(52, (232, 200, 70), (176, 142, 34))
d = ImageDraw.Draw(img)
d.ellipse([30, 26, 46, 44], fill=(252, 232, 150, 255))
d.ellipse([34, 30, 42, 40], fill=(240, 200, 90, 255))
for sx, sy in [(36, 33), (40, 36)]:
    d.ellipse([sx - 2, sy - 2, sx + 2, sy + 2], fill=(150, 110, 20, 255))
save(img, "enemies/brood.png")
save(blob(22, (92, 130, 240), (54, 84, 178)), "enemies/minion.png")
# mender: green with a white cross
img = blob(52, (110, 210, 130), (60, 150, 80))
d = ImageDraw.Draw(img)
d.rectangle([24, 14, 29, 32], fill=(255, 255, 255, 255))
d.rectangle([17, 21, 36, 26], fill=(255, 255, 255, 255))
save(img, "enemies/mender.png")
# charger: white wedge with red horn (faces right)
img = Image.new("RGBA", (52, 44), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.polygon([(6, 12), (34, 8), (48, 22), (34, 36), (6, 32)], fill=(214, 218, 228, 255))
d.polygon([(34, 14), (48, 22), (34, 30)], fill=(150, 154, 168, 255))
d.polygon([(40, 16), (52, 22), (40, 28)], fill=(240, 70, 60, 255))
d.ellipse([14, 16, 24, 26], fill=(255, 255, 255, 255))
d.ellipse([19, 19, 24, 24], fill=(20, 20, 28, 255))
save(img, "enemies/charger.png")
# boomling: black bomb with fuse spark
img = blob(40, (58, 58, 70), (30, 30, 40))
d = ImageDraw.Draw(img)
d.line([28, 8, 34, 2], fill=(220, 200, 120, 255), width=3)
d.ellipse([31, 0, 38, 6], fill=(255, 160, 60, 255))
save(img, "enemies/boomling.png")
# splitter: violet split blob
img = blob(44, (168, 96, 200), (118, 56, 150))
d = ImageDraw.Draw(img)
d.line([22, 8, 22, 38], fill=(118, 56, 150, 255), width=4)
save(img, "enemies/splitter.png")
# orbiter: cyan saucer
img = Image.new("RGBA", (48, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.ellipse([4, 10, 44, 28], fill=(40, 130, 160, 255))
d.ellipse([10, 4, 38, 20], fill=(90, 210, 240, 255))
d.ellipse([20, 8, 28, 15], fill=(220, 250, 255, 255))
save(img, "enemies/orbiter.png")

# =================================================================== bosses
save(blob(112, (172, 118, 76), (116, 74, 44), spots=[(18, 10, 8), (-24, -12, 7), (2, 26, 6)]),
     "enemies/boss_heap.png")
img = Image.new("RGBA", (112, 112), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
for pts, col in [([(56, 8), (86, 40), (70, 62), (38, 54)], (120, 220, 250, 255)),
                 ([(30, 30), (62, 44), (48, 78), (20, 66)], (88, 178, 216, 255)),
                 ([(70, 56), (100, 70), (84, 98), (58, 86)], (150, 236, 255, 255))]:
    d.polygon(pts, fill=col)
d.ellipse([40, 44, 72, 74], fill=(230, 250, 255, 255))
d.ellipse([50, 52, 62, 64], fill=(60, 140, 190, 255))
save(img, "enemies/boss_prism.png")
img = Image.new("RGBA", (112, 112), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.polygon([(56, 6), (88, 46), (76, 100), (36, 100), (24, 46)], fill=(52, 44, 66, 255))
d.polygon([(56, 18), (78, 48), (70, 88), (42, 88), (34, 48)], fill=(84, 66, 110, 255))
d.ellipse([40, 36, 72, 62], fill=(240, 70, 80, 255))
d.ellipse([48, 42, 64, 56], fill=(120, 20, 30, 255))
d.line([84, 30, 104, 66], fill=(200, 210, 230, 255), width=5)
save(img, "enemies/boss_reaper.png")

# ================================================================== weapons
GUNS = {
    "smg":       {"icon": (216, 200, 90),  "barrel": 18},
    "shotgun":   {"icon": (200, 120, 60),  "barrel": 20},
    "rifle":     {"icon": (150, 150, 160), "barrel": 24},
    "laser":     {"icon": (90, 220, 250),  "barrel": 20},
    "cannon":    {"icon": (150, 110, 80),  "barrel": 16},
    "frost":     {"icon": (120, 200, 250), "barrel": 18},
    "flame":     {"icon": (250, 140, 60),  "barrel": 16},
    "rail":      {"icon": (170, 120, 250), "barrel": 26},
    "boomerang": {"icon": (230, 190, 90),  "barrel": 14},
    "minigun":   {"icon": (120, 120, 130), "barrel": 22},
    "fryer":     {"icon": (250, 210, 120), "barrel": 14},
    "gravity":   {"icon": (140, 110, 200), "barrel": 14},
}
for name, g in GUNS.items():
    icon = Image.new("RGBA", (44, 44), (0, 0, 0, 0))
    d = ImageDraw.Draw(icon)
    d.ellipse([4, 4, 40, 40], fill=(40, 42, 54, 235))
    d.ellipse([6, 6, 38, 38], outline=g["icon"] + (255,), width=3)
    d.polygon([(12, 22), (30, 16), (36, 22), (30, 28)], fill=g["icon"] + (255,))
    d.rectangle([8, 20, 14, 24], fill=(80, 84, 100, 255))
    save(icon, f"weapons/icon_{name}.png")
    # world sprite: horizontal gun, facing right, pivot near the grip
    gun = Image.new("RGBA", (30, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(gun)
    d.rectangle([2, 5, 26, 9], fill=(70, 72, 86, 255))
    d.rectangle([8, 9, 14, 13], fill=(54, 56, 68, 255))
    d.rectangle([24, 4, 28, 10], fill=g["icon"] + (255,))
    save(gun, f"weapons/gun_{name}.png")

# ================================================================== bullets
def bullet(rel, w, h, col, glow=None):
    img = Image.new("RGBA", (max(w, 4) + 6, max(h, 4) + 6), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x0, y0 = 3, 3
    if glow:
        d.ellipse([x0 - 2, y0 - 2, x0 + w + 2, y0 + h + 2], fill=glow + (90,))
    d.ellipse([x0, y0, x0 + w, y0 + h], fill=col + (255,))
    save(img, rel)

bullet("bullets/bolt.png", 10, 5, (255, 220, 90), (255, 200, 60))
bullet("bullets/pellet.png", 5, 5, (250, 190, 110), (255, 160, 80))
bullet("bullets/slug.png", 13, 4, (220, 225, 235), (160, 170, 200))
bullet("bullets/bomb.png", 9, 9, (60, 60, 70), (255, 120, 60))
bullet("bullets/shard.png", 8, 8, (150, 220, 255), (90, 180, 250))
bullet("bullets/rail.png", 16, 4, (190, 140, 255), (140, 90, 220))
bullet("bullets/spit.png", 7, 7, (110, 220, 100), (60, 180, 60))
bullet("bullets/orb.png", 12, 12, (150, 110, 220), (100, 70, 180))
img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.arc([2, 2, 17, 17], 300, 240, fill=(240, 200, 90, 255), width=4)
save(img, "bullets/boomerang.png")

# ================================================================== pickups
img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.polygon([(8, 1), (15, 8), (8, 15), (1, 8)], fill=(90, 230, 255, 255))
d.polygon([(8, 4), (12, 8), (8, 12), (4, 8)], fill=(190, 250, 255, 255))
save(img, "pickups/xp.png")
img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.ellipse([1, 1, 15, 15], fill=(250, 200, 60, 255))
d.ellipse([3, 3, 13, 13], outline=(220, 160, 30, 255), width=2)
d.rectangle([7, 4, 9, 12], fill=(160, 110, 20, 255))
d.rectangle([5, 6, 11, 8], fill=(160, 110, 20, 255))
save(img, "pickups/coin.png")
img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.polygon([(3, 5), (8, 1), (13, 5), (13, 9), (8, 15), (3, 9)], fill=(240, 70, 80, 255))
save(img, "pickups/heart.png")

# ================================================== fx curation (kenney subset)
KEN_PART = f"{RAW}/kenney_particle_pack/PNG (Transparent)"
for f, out in [("circle_01.png", "fx/circle.png"), ("circle_02.png", "fx/circle_soft.png"),
               ("dirt_01.png", "fx/dirt.png"), ("dirt_03.png", "fx/dirt2.png"),
               ("fire_01.png", "fx/fire.png"), ("flame_01.png", "fx/flame.png"),
               ("flare_01.png", "fx/flare.png"), ("light_01.png", "fx/light.png"),
               ("smoke_01.png", "fx/smoke.png"), ("star_01.png", "fx/star.png"),
               ("muzzle_01.png", "fx/muzzle.png"), ("muzzle_02.png", "fx/muzzle2.png")]:
    p = f"{KEN_PART}/{f}"
    if os.path.exists(p):
        im = Image.open(p).convert("RGBA")
        im.thumbnail((128, 128), Image.LANCZOS)
        save(im, out)

# ================================================== props (PIL, same smooth
# style as the units - the kenney tiny_town tiles are 16px pixel-art and
# clash with the drawn units)
def prop_rock():
    img = Image.new("RGBA", (72, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(8, 48), (4, 30), (20, 10), (46, 6), (66, 22), (64, 46)],
              fill=(138, 130, 122, 255))
    d.polygon([(20, 14), (44, 10), (58, 24), (50, 38), (24, 40), (12, 28)],
              fill=(162, 154, 146, 255))
    d.polygon([(24, 18), (42, 14), (52, 26), (30, 32)], fill=(184, 178, 170, 255))
    return img

def prop_crate():
    img = Image.new("RGBA", (52, 52), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 4, 48, 48], fill=(158, 116, 70, 255))
    d.rectangle([4, 4, 48, 48], outline=(108, 78, 46, 255), width=4)
    d.line([6, 6, 46, 46], fill=(122, 88, 52, 255), width=5)
    d.line([46, 6, 6, 46], fill=(122, 88, 52, 255), width=5)
    d.rectangle([8, 8, 44, 44], outline=(184, 140, 92, 255), width=2)
    return img

def prop_barrel():
    img = Image.new("RGBA", (40, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([6, 4, 34, 52], 10, fill=(110, 130, 150, 255))
    d.rounded_rectangle([10, 4, 30, 52], 8, fill=(140, 160, 180, 255))
    d.rectangle([6, 14, 34, 20], fill=(80, 96, 112, 255))
    d.rectangle([6, 36, 34, 42], fill=(80, 96, 112, 255))
    d.ellipse([14, 8, 26, 16], fill=(240, 160, 60, 255))
    return img

def prop_tree():
    img = Image.new("RGBA", (76, 92), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([34, 52, 42, 88], fill=(112, 84, 56, 255))
    d.polygon([(34, 60), (20, 72), (34, 74)], fill=(112, 84, 56, 255))
    for cx, cy, r in [(38, 26, 24), (20, 40, 16), (56, 40, 16), (38, 44, 18)]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(64, 118, 62, 255))
    for cx, cy, r in [(32, 20, 12), (52, 36, 9), (24, 38, 8)]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(84, 146, 78, 255))
    return img

def prop_bench():
    img = Image.new("RGBA", (72, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 14, 68, 22], fill=(146, 108, 70, 255))
    d.rectangle([4, 14, 68, 22], outline=(104, 76, 48, 255), width=2)
    d.rectangle([8, 24, 16, 34], fill=(104, 76, 48, 255))
    d.rectangle([56, 24, 64, 34], fill=(104, 76, 48, 255))
    d.line([8, 18, 64, 18], fill=(176, 134, 90, 255), width=2)
    return img

def prop_fence():
    img = Image.new("RGBA", (84, 44), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for x in (6, 34, 62):
        d.rectangle([x, 6, x + 10, 40], fill=(150, 118, 82, 255))
        d.polygon([(x, 6), (x + 5, 0), (x + 10, 6)], fill=(150, 118, 82, 255))
    d.rectangle([0, 14, 84, 20], fill=(122, 94, 62, 255))
    d.rectangle([0, 28, 84, 34], fill=(122, 94, 62, 255))
    return img

def prop_shrub():
    img = Image.new("RGBA", (48, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for cx, cy, r in [(16, 22, 12), (32, 22, 12), (24, 14, 12)]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(88, 128, 66, 255))
    for cx, cy, r in [(20, 16, 6), (32, 20, 5)]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(110, 156, 82, 255))
    return img

def prop_skull():
    img = Image.new("RGBA", (44, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([6, 4, 38, 32], fill=(226, 220, 206, 255))
    d.rectangle([12, 26, 32, 38], fill=(210, 202, 188, 255))
    d.ellipse([13, 13, 21, 23], fill=(50, 44, 40, 255))
    d.ellipse([24, 13, 32, 23], fill=(50, 44, 40, 255))
    d.polygon([20, 27, 24, 27, 22, 32], fill=(120, 110, 100, 255))
    d.line([15, 33, 17, 38], fill=(120, 110, 100, 255), width=2)
    d.line([27, 33, 25, 38], fill=(120, 110, 100, 255), width=2)
    return img

for fn in [prop_rock, prop_crate, prop_barrel, prop_tree, prop_bench,
           prop_fence, prop_shrub, prop_skull]:
    p = fn()
    name = fn.__name__.replace("prop_", "")
    save(p, f"props/{name}.png")

# a dead ferris wheel silhouette for the park horizon + machine ribs desert
img = Image.new("RGBA", (220, 200), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
c = (110, 120)
d.ellipse([c[0] - 80, c[1] - 80, c[0] + 80, c[1] + 80], outline=(60, 74, 52, 255), width=5)
for a in range(8):
    x = c[0] + math.cos(a * math.pi / 4) * 80
    y = c[1] + math.sin(a * math.pi / 4) * 80
    d.line([c[0], c[1], x, y], fill=(60, 74, 52, 255), width=4)
    d.ellipse([x - 7, y - 7, x + 7, y + 7], outline=(60, 74, 52, 255), width=3)
d.line([c[0] - 40, c[1] + 80, c[0], c[1]], fill=(60, 74, 52, 255), width=6)
d.line([c[0] + 40, c[1] + 80, c[0], c[1]], fill=(60, 74, 52, 255), width=6)
save(img, "props/ferris.png")

print("COSMIC SPUD art pipeline done.")
