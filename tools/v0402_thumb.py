#!/usr/bin/env python3
"""HEAVY WAR thumbnail (v040-2) - 960x640 from the ORIGINAL's own sprites.
v3 after the eye pass: the clean silver jet under the reticle, the arm
breaking the tank's silhouette, bright shells, no clutter.
"""
from PIL import Image

SRC = "/home/z/my-project/gogabox/projects/gogabox/assets/games/hwsrc"
OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/thumbs/heavywar.png"
W, H = 960, 640

img = Image.new("RGBA", (W, H), (0, 0, 0, 255))

# ---- sky by width (always covers)
sky = Image.open(f"{SRC}/backgrounds/blastnya_sky.jpg").convert("RGBA")
sky = sky.resize((W, int(sky.height * W / sky.width)), Image.LANCZOS)
img.paste(sky.crop((0, 0, W, H)), (0, 0))

GROUND_Y = 566

far = Image.open(f"{SRC}/backgrounds/blastnya_bg.png").convert("RGBA")
img.paste(far, (0, GROUND_Y - far.height), far)

mid = Image.open(f"{SRC}/backgrounds/blastnya_bg2.png").convert("RGBA")
img.paste(mid, (0, GROUND_Y - mid.height + 60), mid)

gnd = Image.open(f"{SRC}/backgrounds/blastnya_ground.png").convert("RGBA")
g = gnd.resize((640, 120), Image.LANCZOS)
x = 0
while x < W:
    img.paste(g, (x, GROUND_Y), g)
    x += g.width


def paste(path, box, cx, cy, s, rot=0):
    t = Image.open(path).convert("RGBA")
    c = t.crop(box)
    c = c.resize((int(c.width * s), int(c.height * s)), Image.LANCZOS)
    if rot:
        c = c.rotate(rot, expand=True, resample=Image.BICUBIC)
    img.paste(c, (int(cx - c.width / 2), int(cy - c.height / 2)), c)


# ---- the shadow + the body, then the arm ON TOP (the source's order)
paste(f"{SRC}/sprites/tankshadow.png", (0, 0, 80, 20), 196, 602, 3.8)
paste(f"{SRC}/sprites/tank.png", (0, 0, 80, 55), 190, 556, 3.8)
# ---- the flash bursts right off the turret ring (the barrel art is
# hairline in the strip - it reads in-game, never in a still)
paste(f"{SRC}/sprites/muzzleflash.png", (0, 0, 50, 50), 208, 448, 2.6)

# ---- the explosion breathing on its own
paste(f"{SRC}/sprites/explosion.png", (4 * 160, 0, 5 * 160, 160),
      764, 302, 2.2)

# ---- the clean silver jet + the red reticle dominating the lock
paste(f"{SRC}/sprites/smalljet.png", (0, 0, 80, 30), 596, 176, 2.1)
paste(f"{SRC}/sprites/target1.png", (0, 0, 56, 56), 596, 176, 3.0)

# ---- the friend helicopter up top
paste(f"{SRC}/sprites/pupcopter.png", (0, 0, 120, 44), 148, 106, 2.2)
paste(f"{SRC}/sprites/pup_02.png", (0, 0, 32, 32), 238, 170, 1.7)

img.convert("RGB").save(OUT)
print("thumb ->", OUT, img.size)
