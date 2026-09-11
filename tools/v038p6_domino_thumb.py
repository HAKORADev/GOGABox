#!/usr/bin/env python3
"""
v0.3.8-6 DOMINO THUMBNAIL - THE CODE-DESIGNED POSTER (the owner's call:
"update the thumbnail of dominoes, maybe use the game original resolution
then resize it to the proper size? or just use code to design it layer by
layer? ... you still can put dominoes and make the scene as real
code-designed image i guess").

The old thumb was a raw landscape capture of the portrait game: the brown
letterbox bands (the project clear tone) showed at the bottom - the owner:
"i do not want a brown area at the bottom, make it green too". This poster
is built LAYER BY LAYER from the game's REAL assets, at 1440x960 (2x the
960x640 canvas - "game original resolution, then resize"), downscaled with
Lanczos:

  L1  the real bg2 tavern felt, cover-fit - GREEN everywhere, zero brown
  L2  a soft edge vignette (depth, not a fake light spot)
  L3  the real serpentine chain (scraped bg3 ivory faces, honest matching
      pips, lying tiles = the standing face tipped 90 deg like the game's
      draw_set_transform law, the double standing as the corner)
  L4  the boneyard stack of real backs, top-right
  L5  the GOGACoin resting on the chain's open end (the coin race)
  L6  the foreground hand fan - four big standing tiles, soft shadows
  L7  two standing set-up tiles, top-left (the table breathes)

No baked text (THUMBNAILS.md R2). Deterministic. Run from repo root.
"""

from PIL import Image, ImageDraw, ImageFilter
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "projects", "gogabox")
A = lambda *p: os.path.join(ROOT, *p)

W, H = 1440, 960          # the 2x work canvas
OUT_W, OUT_H = 960, 640   # the locked thumb canvas

# ---------------------------------------------------------------- assets
FELT = Image.open(A("assets/games/domino/grounds/bg2.png")).convert("RGB")
COIN = Image.open(A("assets/ui/coin.png")).convert("RGBA")
BACK = Image.open(A("assets/games/domino/tiles/bg3/back.png")).convert("RGBA")

_face_cache = {}
def face_file(a, b):
    """the real scraped face files are stored lo-hi (top=lo); returns the
    image whose TOP half equals `top` - flipping the standing face when the
    chain needs the bigger value toward an end (the game flips halves too)"""
    lo, hi = min(a, b), max(a, b)
    key = (lo, hi, a)   # top = a
    if key not in _face_cache:
        im = Image.open(A("assets/games/domino/tiles/bg3",
                          f"{lo}-{hi}.png")).convert("RGBA")
        if a != lo:
                im = im.transpose(Image.FLIP_TOP_BOTTOM)   # top = hi now
        _face_cache[key] = im
    return _face_cache[key]

# ---------------------------------------------------------------- helpers
def cover(img, w, h):
    """cover-fit crop: fills w x h, center crop, zero spill"""
    s = max(w / img.width, h / img.height)
    nw, nh = round(img.width * s), round(img.height * s)
    im = img.resize((nw, nh), Image.LANCZOS)
    x, y = (nw - w) // 2, (nh - h) // 2
    return im.crop((x, y, x + w, y + h))

def shadow_of(tile, dy=14, blur=16, alpha=70, grow=0.06):
    """a soft honest drop shadow under a tile (2D, offset, never painted
    on the tile itself - the owner killed the fake in-domino shading)"""
    gw = max(2, round(max(tile.size) * grow))
    sh = Image.new("RGBA", (tile.width + gw * 2, tile.height + gw * 2), (0, 0, 0, 0))
    m = Image.new("L", sh.size, 0)
    md = ImageDraw.Draw(m)
    md.rounded_rectangle([gw, gw, gw + tile.width - 1, gw + tile.height - 1],
                         radius=26, fill=alpha)
    m = m.filter(ImageFilter.GaussianBlur(blur))
    black = Image.new("RGBA", sh.size, (6, 14, 4, 255))
    sh.paste(black, (0, dy), m)
    return sh

def paste_with_shadow(base, tile, xy, angle=0.0):
    """rotate tile (+ its shadow) around the center, paste at xy = center"""
    if abs(angle) > 0.01:
        tile = tile.rotate(angle, resample=Image.BICUBIC, expand=True)
    sh = shadow_of(tile)
    px, py = int(xy[0] - sh.width / 2), int(xy[1] - sh.height / 2 + 6)
    base.alpha_composite(sh, (px, py))
    base.alpha_composite(tile, (int(xy[0] - tile.width / 2),
                                int(xy[1] - tile.height / 2)))

def lying(a, b, scale):
    """a lying tile: the standing face tipped +90 CCW (PIL) - the TOP half
    becomes the LEFT end, so a lying a-b reads left=a, right=b: the honest
    chain order (same truth the game's draw_set_transform law renders)."""
    t = face_file(a, b).rotate(90, expand=True)
    return t.resize((round(t.width * scale), round(t.height * scale)),
                    Image.LANCZOS)

def standing(a, b, scale):
    t = face_file(a, b)
    return t.resize((round(t.width * scale), round(t.height * scale)),
                    Image.LANCZOS)

# ================================================================= the scene
scene = FELT.convert("RGBA")
scene = cover(scene, W, H)

# L2 - the vignette: the room dims toward the rails (depth, no fake spot)
vig = Image.new("L", (W, H), 0)
vd = ImageDraw.Draw(vig)
vd.rectangle([W * 0.10, H * 0.12, W * 0.90, H * 0.88], fill=90)
vig = vig.filter(ImageFilter.GaussianBlur(120))
dark = Image.new("RGBA", (W, H), (4, 26, 2, 255))
scene = Image.composite(scene, Image.alpha_composite(dark, scene), vig)

# L3 - THE CHAIN: a real serpentine, honest matching pips (every neighbour
# shares the touching end), the S-pack the game draws: one row left->right,
# a standing double turns it, one row running back under it.
S_LIE = 1.32            # lying tile scale (99x188 face -> ~248x131 lying)
S_STAND = 1.05
LW = round(188 * S_LIE)  # lying long side
LH = round(99 * S_LIE)   # lying short side
STEP = LW - 8
row1 = [(6, 4), (4, 4), (4, 1), (1, 3), (3, 6)]     # left -> right
corner = (6, 6)                                      # the standing turn
row2 = [(5, 2), (2, 2), (2, 0), (0, 6)]              # left -> right, plugs
                                                     # its 6 UNDER the corner
y1 = 320
x = 110
for a, b in row1:
    paste_with_shadow(scene, lying(a, b, S_LIE), (x + LW // 2, y1))
    x += STEP
# the corner double stands astride the bend (the game's corner law)
cx = x + 14 + round(99 * S_STAND) // 2
cy = y1 + round(LH * 0.28)
paste_with_shadow(scene, standing(*corner, S_STAND), (cx, cy))
# row 2 runs back, one pitch below, its first tile plugs under the corner
y2 = y1 + round(LH * 1.62)
xr = cx - 26
for a, b in reversed(row2):
    xr -= STEP
    paste_with_shadow(scene, lying(a, b, S_LIE), (xr + LW // 2, y2))

# L5 - THE GOGACOIN on the chain's open end (the coin race seat)
coin = COIN.resize((104, 104), Image.LANCZOS)
paste_with_shadow(scene, coin, (xr - 34, y2), angle=0)

# L4 - THE BONEYARD: real backs stacked at the top right (the draw pile)
for i in range(4):
    b = BACK.resize((round(99 * 1.12), round(188 * 1.12)), Image.LANCZOS)
    paste_with_shadow(scene, b, (W - 148 + (i % 2) * 6,
                                 150 - i * 10), angle=(i - 1.5) * 2.2)

# L7 - two standing set-up tiles, top left (the table breathes)
paste_with_shadow(scene, standing(3, 3, 0.9), (150, 160), angle=-6)
paste_with_shadow(scene, standing(2, 4, 0.9), (256, 190), angle=5)

# L6 - THE HAND FAN: four big standing tiles, bottom left (the out-of-frame
# hand, closer to the camera)
fan = [(2, 5), (5, 5), (5, 1), (1, 6)]
angles = [-9.0, -3.0, 3.0, 9.0]
fx = 320
for (a, b), ang in zip(fan, angles):
    t = standing(a, b, 1.95)
    paste_with_shadow(scene, t, (fx, H - 175), angle=ang)
    fx += 205

# poster finish: downscale to the locked canvas
final = scene.convert("RGB").resize((OUT_W, OUT_H), Image.LANCZOS)
out = A("assets/thumbs/domino.png")
final.save(out, "PNG")
print("wrote", out, final.size)
