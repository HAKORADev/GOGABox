#!/usr/bin/env python3
"""
v0415 GOLD MINER THUMBNAIL (960x640, the box's tile format)
Composed from the game's OWN forged sprites (the chroma-cutout law: never
re-drawn) - the rig on its surface, the claw mid-swing biting an L gold,
the field wearing S/M golds, a rock and a bomb, the intro logo on top.
"""
from PIL import Image, ImageDraw, ImageFilter

A = "/home/z/my-project/gogabox/projects/gogabox/assets/games/goldminer/"
OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/thumbs/goldminer.png"
MON = "/home/z/my-project/study_locker/gamesnacks/goldminertom/montages/"

W, H = 960, 640
M = Image.new("RGBA", (W, H), (0, 0, 0, 255))

# ---- the world: surface band + field (from the forged backgrounds)
surf = Image.open(A + "bg_surface.png").convert("RGBA")      # 1080x360
field = Image.open(A + "bg_field.png").convert("RGBA")       # 1080x1460
sw = surf.resize((int(1080*1.3), int(360*1.3)), Image.LANCZOS)
M.paste(sw, (-230, -330), sw)
fw = field.crop((0, 760, 1080, 1280)).resize((W, H), Image.LANCZOS)
M.alpha_composite(fw, (0, 150))

# ---- the rig (anchored right-of-center), sitting on the surface line
rig = Image.open(A + "rig_classic.png").convert("RGBA")
rig = rig.resize((int(360*1.15), int(300*1.15)), Image.LANCZOS)
rig_y = 78
M.alpha_composite(rig, (560, rig_y))

# ---- the rope + claw biting the L gold (the hero moment)
claw_c = Image.open(A + "claw_closed.png").convert("RGBA")
gold_l = Image.open(A + "gold_classic_l.png").convert("RGBA")
gold_m = Image.open(A + "gold_classic_m.png").convert("RGBA")
gold_s = Image.open(A + "gold_classic_s.png").convert("RGBA")
rock_m = Image.open(A + "rock_classic_m.png").convert("RGBA")
bomb = Image.open(A + "bomb.png").convert("RGBA")
coin = Image.open(A + "coin.png").convert("RGBA")
dust = Image.open(A + "dust_dark.png").convert("RGBA")

dr = ImageDraw.Draw(M)
# the rope from the winch hub down-left to the claw
hub = (560 + int(257*1.15), rig_y + int(46*1.15))
tip = (392, 300)
dr.line([hub, tip], fill=(72, 58, 44, 255), width=7)

# the field cast (composed, overlap-checked by eye below)
M.alpha_composite(rock_m.resize((150, 150), Image.LANCZOS), (56, 452))
M.alpha_composite(bomb.resize((120, 133), Image.LANCZOS), (712, 486))
M.alpha_composite(gold_s.resize((56, 50), Image.LANCZOS), (240, 415))
M.alpha_composite(gold_m.resize((96, 82), Image.LANCZOS), (790, 352))
# the dragged L gold under the closed claw (the reel moment)
gl = gold_l.resize((210, 184), Image.LANCZOS)
M.alpha_composite(gl, (tip[0] - 96, tip[1] + 26))
cc = claw_c.resize((96, 102), Image.LANCZOS)
M.alpha_composite(cc, (tip[0] - 48, tip[1] - 22))
# dust puffs under the dragged gold (the trail law)
for i, (dx, dy, s) in enumerate([(84, 138, 0.8), (150, 182, 0.65)]):
    d = dust.resize((int(91*s), int(100*s)), Image.LANCZOS)
    M.alpha_composite(d, (tip[0]+dx, tip[1]+dy))

# ---- the coin, glowing top-left of the field
coin_s = coin.resize((110, 110), Image.LANCZOS)
M.alpha_composite(coin_s, (70, 300))

# ---- the wordmark on the sky
logo = Image.open(A + "logo.png").convert("RGBA")
lw = 430
lh = int(logo.height * lw / logo.width)
logo = logo.resize((lw, lh), Image.LANCZOS)
shadow = Image.new("RGBA", (lw+8, lh+8), (0, 0, 0, 0))
ld = ImageDraw.Draw(shadow)
ld.text((6, 6), "", fill=(0,0,0,0))
shadow = logo.filter(ImageFilter.GaussianBlur(0))
M.alpha_composite(logo, (36, 30))

M.convert("RGB").save(OUT)
M.save(MON + "thumb_draft.png")
print("thumb saved", M.size)
