#!/usr/bin/env python3
"""v0.3.3 PATCH 4 - the matcher store thumbnail, THE IN-GAME SHOT WAY (the
owner: "i recommend taking an in-game shot and modify it with internal game
code to design it perfectly, maybe even making patterns with gems"): the
Xvfb screenshot of the real board (the physics-poured gems, the checker
cells, TWO REAL shader specials) floats on the game's own blue backdrop.
NO title text, no fake specials, no coin anywhere. 960x640."""
from PIL import Image, ImageDraw, ImageFilter

SHOT = "/tmp/shots/thumb_raw.png"
OUT = ("/home/z/my-project/repo/GOGABox/projects/gogabox"
       "/assets/games/matcher/thumb.png")
W, H = 960, 640

shot = Image.open(SHOT).convert("RGB")

# the board crop (board_o=(140,576) cell_px=100 - printed by the qa scene)
bx, by, cs = 140, 576, 100
board = shot.crop((bx - 10, by - 10, bx + 8 * cs + 10, by + 8 * cs + 10))

# the game's own blue backdrop: sample the clean left margin strip
# (pure sky, no HUD, no board) and stretch it
sky = shot.crop((6, 200, 132, 1800)).resize((W, H), Image.LANCZOS)
sky = sky.filter(ImageFilter.GaussianBlur(8))
im = sky.copy()

# the board, soft-shadowed, centered
BS = 600
board2 = board.resize((BS, BS), Image.LANCZOS)
mask = Image.new("L", (BS + 40, BS + 40), 0)
dm = ImageDraw.Draw(mask)
dm.rounded_rectangle((20, 20, BS + 19, BS + 19), radius=26, fill=255)
mask = mask.filter(ImageFilter.GaussianBlur(2))
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ds = ImageDraw.Draw(shadow)
ds.rounded_rectangle((W // 2 - BS // 2 - 6, H // 2 - BS // 2 + 10,
                      W // 2 + BS // 2 + 6, H // 2 + BS // 2 + 22),
                     radius=30, fill=(8, 16, 40, 150))
shadow = shadow.filter(ImageFilter.GaussianBlur(14))
shadow_rgb = Image.new("RGB", (W, H), (0, 0, 0))
im = Image.composite(shadow_rgb, im, shadow.split()[3].point(lambda v: v * 55 // 100))
board_mask = mask.crop((20, 20, BS + 20, BS + 20))
im.paste(board2, (W // 2 - BS // 2, H // 2 - BS // 2), board_mask)

im.save(OUT)
print("thumb written:", OUT, im.size)
