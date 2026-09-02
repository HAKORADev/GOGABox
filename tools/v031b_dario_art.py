#!/usr/bin/env python3
"""v0.3.1 PATCH II - CURSED DARIO ASSET OVERHAUL (the owner: "these assets
are trash... i need more realistic assets... try hard because this is the
most critical step in this whole game").

THE NEW KIT (hunted via GitHub mirrors, reviewed under tools/hunt_*):
 - Pixel Adventure by PIXEL FROG (pixelfrog-assets.itch.io/pixel-adventure-1,
   free for commercial + non-commercial; mirrored at marpor/PixelAdventure):
   Pink Man hero, Snail/Bat/Plant/Rino/Turtle enemies, Ghost boss base,
   terrain tiles, ?-crates, spikes, fire, falling platforms, trophy, bullets.
 - Sunny Land by ANSIMUZ (ansimuz.itch.io/sunny-land-pixel-art, free for
   commercial + non-commercial; mirrored at Kevin1321/DA_Module_12_SunnyLand):
   the parallax forest background layers.
 - The GOGACoin keeps its own art (item_coin.png) - it is the Box-wide
   currency identity.
 - The Witcher = the PA Ghost recolored cursed-lavender with a pixel witch
   hat baked on; her curse bolt = the PA Trunk bullet recolored purple.

Everything is sliced from the sprite sheets, pre-scaled by integer factors
(NOT resampled art - nearest-neighbor only) and written to
assets/games/dario/ under the SAME file names the game code already loads
wherever the semantics survived.
"""
from PIL import Image
import os

PA = "/home/z/my-project/hunt/PixelAdventure/PixelAdventure"
SL = "/home/z/my-project/hunt/sl"
OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/games/dario"

written = []

def sheet(rel):
    return Image.open(os.path.join(PA, rel)).convert("RGBA")

def frames(im, fw, fh):
    n = im.width // fw
    assert im.width % fw == 0, f"sheet {im.size} not divisible by {fw}"
    return [im.crop((i * fw, 0, (i + 1) * fw, fh)) for i in range(n)]

def save(name, im, scale):
    if scale != 1:
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    im.save(os.path.join(OUT, name))
    written.append((name, im.size))
    return im

def terr(cx, cy):
    t = TERR.crop((cx * 16, cy * 16, cx * 16 + 16, cy * 16 + 16))
    return t

TERR = sheet("Terrain/Terrain (16x16).png")

# ---------------------------------------------------------------- hero
hero = sheet("Main Characters/Pink Man/Idle (32x32).png")
f = frames(hero, 32, 32)
save("hero_stand.png", f[0], 3)
f = frames(sheet("Main Characters/Pink Man/Run (32x32).png"), 32, 32)
for i in range(4):
    save(f"hero_walk{i+1}.png", f[i], 3)
save("hero_jump.png", frames(sheet("Main Characters/Pink Man/Jump (32x32).png"), 32, 32)[0], 3)
save("hero_fall.png", frames(sheet("Main Characters/Pink Man/Fall (32x32).png"), 32, 32)[0], 3)
save("hero_hurt.png", frames(sheet("Main Characters/Pink Man/Hit (32x32).png"), 32, 32)[0], 3)

# ---------------------------------------------------------------- enemies
f = frames(sheet("Enemies/Snail/Walk (38x24).png"), 38, 24)
save("enemy_snail1.png", f[0], 2)
save("enemy_snail2.png", f[1], 2)
f = frames(sheet("Enemies/Bat/Flying (46x30).png"), 46, 30)
save("enemy_fly1.png", f[0], 2)
save("enemy_fly2.png", f[2], 2)
f = frames(sheet("Enemies/Plant/Idle (44x42).png"), 44, 42)
save("enemy_spitter1.png", f[0], 2)
save("enemy_spitter2.png", f[1], 2)
save("enemy_spitter_atk.png", frames(sheet("Enemies/Plant/Attack (44x42).png"), 44, 42)[1], 2)
save("spitter_bullet.png", sheet("Enemies/Plant/Bullet.png"), 3)
f = frames(sheet("Enemies/Rino/Run (52x34).png"), 52, 34)
save("enemy_blocker1.png", f[0], 2)
save("enemy_blocker2.png", f[2], 2)
save("enemy_blocker_hit.png", frames(sheet("Enemies/Rino/Hit (52x34).png"), 52, 34)[0], 2)
f = frames(sheet("Enemies/Turtle/Spikes in (44x26).png"), 44, 26)
save("enemy_spiky1.png", f[1], 2)          # spikes in - STOMPABLE
f = frames(sheet("Enemies/Turtle/Spikes out (44x26).png"), 44, 26)
save("enemy_spiky2.png", f[1], 2)          # spikes out - DEADLY

# ---------------------------------------------------------------- the witcher
def recolor_ghost(im):
    """whites/pales -> cursed lavender, blues -> deeper purple."""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            mx, mn = max(r, g, b), min(r, g, b)
            if mx > 200 and mx - mn < 40:          # near white body
                px[x, y] = (216, 196, 255, a)
            elif b > r and b > 120:                 # blue shading
                px[x, y] = (min(255, r + 60), g // 2, min(255, b), a)
            elif mx < 60:                           # keep dark outlines
                pass
    return im

def witch_hat(im):
    """bake a pixel witch hat over the ghost (44x30 -> 44x40 canvas)."""
    w, h = im.width, im.height + 10
    cv = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cv.paste(im, (0, 10), im)
    px = cv.load()
    DARK = (52, 34, 84, 255)
    MID = (74, 48, 118, 255)
    BAND = (40, 26, 66, 255)
    BUCK = (255, 176, 32, 255)
    y0 = 2
    # brim (row y0+8..y0+9, wide)
    for x in range(8, w - 6):
        px[x, y0 + 8] = DARK
        px[x, y0 + 9] = BAND
    # cone
    top = [(20, 0), (21, 0)]
    for r in range(8):
        span = 2 + r * 2
        cxp = 20 - r // 3            # the tip leans left, cursed
        for x in range(cxp, cxp + span):
            if 0 <= x < w:
                px[x, y0 + 7 - r] = MID if (x + r) % 3 else DARK
    # buckle
    px[17, y0 + 6] = BUCK
    px[18, y0 + 6] = BUCK
    px[17, y0 + 7] = BUCK
    px[18, y0 + 7] = BUCK
    return cv

g_id = frames(sheet("Enemies/Ghost/Idle (44x30).png"), 44, 30)
save("witcher1.png", witch_hat(recolor_ghost(g_id[0])), 3)
save("witcher2.png", witch_hat(recolor_ghost(g_id[4])), 3)
g_ap = frames(sheet("Enemies/Ghost/Appear (44x30).png"), 44, 30)
for i in range(4):
    save(f"witcher_appear{i+1}.png", witch_hat(recolor_ghost(g_ap[i])), 3)

# the curse bolt: the trunk bullet, purple
bolt = sheet("Enemies/Trunk/Bullet.png")
px = bolt.load()
for y in range(bolt.height):
    for x in range(bolt.width):
        r, g, b, a = px[x, y]
        if a == 0:
            continue
        if r > 100:                      # browns -> purples
            px[x, y] = (min(255, g + 110), g // 3, min(255, r + 30), a)
save("curse_bolt.png", bolt, 5)

# ---------------------------------------------------------------- tiles
save("tile_grass.png", terr(7, 0), 5)
save("tile_grass_l.png", terr(6, 0), 5)
save("tile_grass_r.png", terr(8, 0), 5)
save("tile_dirt.png", terr(7, 1), 5)
save("tile_brick.png", terr(18, 4), 5)

# the ? crate: Box2 + an amber pixel ? on the front
box = sheet("Items/Boxes/Box2/Idle.png")
px = box.load()
Q = (255, 176, 32, 255)
QD = (140, 90, 10, 255)
ox, oy = box.width // 2 - 5, box.height // 2 - 7
glyph = ["..####..", ".##..##.", ".....##.", "....##..", "...##...", "........",
         "...##...", "...##..."]
for r, row in enumerate(glyph):
    for c, ch in enumerate(row):
        if ch == "#" and oy + r < box.height and ox + c < box.width:
            px[ox + c, oy + r] = Q
            px[ox + c + 1, oy + r + 1] = QD
save("tile_box.png", box, 3)
save("tile_box_empty.png", sheet("Items/Boxes/Box1/Idle.png"), 3)

save("tile_spikes.png", sheet("Traps/Spikes/Idle.png"), 5)
f = frames(sheet("Traps/Fire/On (16x32).png"), 16, 32)
save("fire1.png", f[0], 5)
save("fire2.png", f[1], 5)
save("fire_off.png", sheet("Traps/Fire/Off.png"), 5)
f = frames(sheet("Traps/Falling Platforms/On (32x10).png"), 32, 10)
save("plat_on.png", f[0], 5)
save("plat_off.png", sheet("Traps/Falling Platforms/Off.png"), 5)
save("tile_goal.png", sheet("Items/Checkpoints/End/End (Idle).png"), 2)
# the mover deck: the terrain sheet's studded platform strip (cols 18-21, row 0)
mover = TERR.crop((18 * 16, 0, 22 * 16, 16))
save("mover_plank.png", mover, 3)

# ---------------------------------------------------------------- the sky
os.makedirs(SL, exist_ok=True)
if not os.path.exists(os.path.join(SL, "forest_far.png")):
    raise SystemExit("sunny land layers missing - run the fetch first")
save("bg_far.png", Image.open(os.path.join(SL, "forest_far.png")).convert("RGBA"), 1)
save("bg_mid.png", Image.open(os.path.join(SL, "forest_mid.png")).convert("RGBA"), 1)

# the pixel moon (16x16 crescent drawn on the pixel grid, x5)
m = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
px = m.load()
for y in range(16):
    for x in range(16):
        d2 = (x - 8) ** 2 + (y - 8) ** 2
        d2b = (x - 11) ** 2 + (y - 6) ** 2
        if d2 <= 36 and d2b > 20:
            px[x, y] = (235, 232, 210, 255)
        elif d2 <= 36 and d2b > 12:
            px[x, y] = (196, 192, 178, 255)
save("deco_moon.png", m, 5)

# ---------------------------------------------------------------- manifest
print(f"wrote {len(written)} files:")
for n, s in written:
    print(f"  {n:26s} {s[0]}x{s[1]}")
