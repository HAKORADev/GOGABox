#!/usr/bin/env python3
"""The CURSED DARIO thumbnail - recomposed to the NEW Pixel Adventure +
Sunny Land look: the forest, the continuous grass, Pink Man mid-run, a
spiked-out turtle, the ? crate and the ghost-witcher looming behind."""
from PIL import Image, ImageDraw

ART = "/home/z/my-project/gogabox/projects/gogabox/assets/games/dario"
OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/thumbs/dario.png"
W, H = 960, 640

cv = Image.new("RGBA", (W, H), (0, 0, 0, 255))

# the forest sky + far layer tiled
far = Image.open(f"{ART}/bg_far.png").convert("RGBA")
fs = 6
far = far.resize((far.width * fs, far.height * fs), Image.NEAREST)
for x in range(0, W, far.width):
    cv.paste(far, (x, 0))
mid = Image.open(f"{ART}/bg_mid.png").convert("RGBA")
ms = 5
mid = mid.resize((mid.width * ms, mid.height * ms), Image.NEAREST)
for x in range(0, W, mid.width):
    cv.alpha_composite(mid, (x, H - mid.height))

# the ground strip
grass = Image.open(f"{ART}/tile_grass.png").convert("RGBA")
dirt = Image.open(f"{ART}/tile_dirt.png").convert("RGBA")
for row in range(2):
    for x in range(0, W, 80):
        t = grass if row == 0 else dirt
        cv.alpha_composite(t, (x, H - 160 + row * 80))

# the trophy
goal = Image.open(f"{ART}/tile_goal.png").convert("RGBA")
cv.alpha_composite(goal, (W - 150, H - 160 - 128 + 24))

# the ? crate on a brick
brick = Image.open(f"{ART}/tile_brick.png").convert("RGBA")
box = Image.open(f"{ART}/tile_box.png").convert("RGBA")
for i, x in enumerate([300, 380]):
    cv.alpha_composite(brick, (x, 250))
    cv.alpha_composite(box, (x - 2, 250 - 66))

# the hero mid-run (frame 2), big, standing on the ground
hero = Image.open(f"{ART}/hero_walk2.png").convert("RGBA")
hero = hero.resize((hero.width * 2, hero.height * 2), Image.NEAREST)
cv.alpha_composite(hero, (430, H - 160 - hero.height + 14))

# the spiky turtle (spikes OUT - the danger)
spiky = Image.open(f"{ART}/enemy_spiky2.png").convert("RGBA")
spiky = spiky.resize((int(spiky.width * 1.6), int(spiky.height * 1.6)), Image.NEAREST)
cv.alpha_composite(spiky, (600, H - 160 - spiky.height + 30))

# the ghost witcher looming in the back, translucent
witch = Image.open(f"{ART}/witcher1.png").convert("RGBA")
witch = witch.resize((int(witch.width * 1.7), int(witch.height * 1.7)), Image.NEAREST)
wm = witch.copy()
wm.putalpha(wm.split()[3].point(lambda a: a * 0.62))
cv.alpha_composite(wm, (W - witch.width - 30, 60))

# the curse bolt
bolt = Image.open(f"{ART}/curse_bolt.png").convert("RGBA")
bolt = bolt.resize((int(bolt.width * 0.8), int(bolt.height * 0.8)), Image.NEAREST)
cv.alpha_composite(bolt, (250, 120))

cv.convert("RGB").save(OUT)
print("thumb written", OUT)
