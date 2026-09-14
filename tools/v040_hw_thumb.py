#!/usr/bin/env python3
"""HEAVY WAR thumbnail (v040) - 480x320 drawn from the game's OWN sprites
(the house law: menu tiles match the real art). Snow place + the tank + a
scout formation + the gunship face + the stencil title."""
from PIL import Image, ImageDraw, ImageFont

GAME = "/home/z/my-project/gogabox/projects/gogabox/assets/games/heavywar"
THUMBS = "/home/z/my-project/gogabox/projects/gogabox/assets/thumbs"
W, H = 480, 320

img = Image.new("RGBA", (W, H), (191, 227, 255, 255))
d = ImageDraw.Draw(img)
# sky band
d.rectangle((0, 0, W, 70), fill=(150, 196, 236, 255))
# far hills
d.polygon([(0, 210), (90, 150), (200, 205), (300, 160), (420, 215), (480, 190),
           (480, 240), (0, 240)], fill=(156, 200, 232, 255))
# ground strip
d.rectangle((0, 240, W, H), fill=(232, 244, 251, 255))
d.rectangle((0, 268, W, 300), fill=(185, 206, 222, 255))
for x in range(10, W, 62):
    d.rectangle((x, 280, x + 28, 288), fill=(240, 248, 255, 255))
# pine dress
for x, h in [(30, 46), (70, 34), (430, 44), (396, 30)]:
    d.polygon([(x, 240 - h), (x + 11, 240), (x - 11, 240)], fill=(110, 150, 178, 255))

def paste(name, cx, cy, scale=1.0):
    s = Image.open(f"{GAME}/spr_{name}.png").convert("RGBA")
    if scale != 1.0:
        s = s.resize((int(s.width * scale), int(s.height * scale)))
    img.alpha_composite(s, (int(cx - s.width / 2), int(cy - s.height / 2)))

# the cast
paste("boss_gunship", 388, 92, 0.42)
paste("enemy_scout", 150, 70, 0.9)
paste("enemy_dart", 230, 48, 0.85)
paste("enemy_raider", 300, 120, 0.8)
paste("heli", 70, 60, 0.7)
paste("tank", 150, 262, 1.15)
paste("boom", 320, 250, 0.55)

# THE TITLE: stencil-heavy, boxed
font = None
for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
          "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"]:
    try:
        font = ImageFont.truetype(p, 52)
        break
    except Exception:
        pass
txt = "HEAVY WAR"
tw = d.textlength(txt, font=font)
tx, ty = (W - tw) / 2, 108
d.rectangle((tx - 18, ty - 8, tx + tw + 18, ty + 66), fill=(26, 21, 18, 230))
d.text((tx, ty), txt, font=font, fill=(255, 224, 138, 255))
d.rectangle((tx - 18, ty - 8, tx + tw + 18, ty + 66), outline=(255, 176, 32, 255), width=3)

img.convert("RGB").save(f"{THUMBS}/heavywar.png")
print("thumb written", img.size)
