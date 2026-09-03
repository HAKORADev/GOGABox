#!/usr/bin/env python3
# ============================================================================
# thumb_composer.py - THE PROGRAMMABLE THUMBNAIL MAKER (v0.1.7).
#
# Hand-designed scenes in code, driven by a tiny per-game SPEC the dev can
# re-tune in seconds when the owner says e.g.:
#
#   "make the snake appear with tail to be up to 9 and straight to left
#    then straight to up before apple by 3 steps"
#
#   -> SNAKE_SPEC = dict(length=9, path=[("L", 5), ("U", 3)],
#                        apple=("ahead", 3))
#
# That is the whole point: thumbnails are POSED, not captured, not painted
# by hand. Every scene draws the game's REAL assets (assets/games/<id>/)
# on the universal 960x640 canvas (rule R1) and is deterministic -
# re-runs are pixel-identical. No baked titles on real-game thumbs (R2);
# the composer's text() exists for SOON tiles and owner opt-ins only.
#
# Usage:
#   python3 tools/thumb_composer.py --game snake
#   python3 tools/thumb_composer.py --all
#   python3 tools/thumb_composer.py --game snake --out /tmp/snake.png
#   python3 tools/thumb_composer.py --sheet /tmp/sheet.png
# ============================================================================
import argparse
import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from derive_assets import font, INK, CARD, ACCENT, HOT, GOOD, COIN, BAD  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # projects/gogabox
ASSETS = os.path.join(ROOT, "assets")
W, H = 960, 640                 # rule R1: the universal canvas

# Direction letters -> unit vectors (grid space: x right, y DOWN).
DIRS = {"L": (-1, 0), "R": (1, 0), "U": (0, -1), "D": (0, 1)}


# ----------------------------------------------------------------- helpers

def game_asset(rel):
    return os.path.join(ASSETS, rel)


def load_sprite(rel, size=None):
    """Load a real game sprite, optionally resized (BICUBIC keeps the
    painted style soft; use nearest=0 default)."""
    img = Image.open(game_asset(rel)).convert("RGBA")
    if size:
        img = img.resize((size, size), Image.BICUBIC)
    return img


def grid_dir_rotation(fx, fy):
    """PIL rotate() degrees so an UP-facing sprite faces (fx, fy)."""
    return math.degrees(math.atan2(-fx, -fy))


# ------------------------------------------------------------------- Scene

class Scene:
    """960x640 canvas with simple layer compositing.

    backdrop()/solid() paint the BASE. Everything after goes to the working
    layer. fade_below(a) fades EVERYTHING drawn so far to `a` alpha and
    opens a fresh layer - that is the owner's matcher recipe
    ("make the grid, fade the image out a little, composite 3 candies on
    top"). stamp() pastes real sprites center-anchored.
    """

    def __init__(self, w=W, h=H):
        self.w, self.h = w, h
        self.base = Image.new("RGBA", (w, h))
        self.baked = []                      # faded layers so far
        self.work = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.work)

    # -- base -----------------------------------------------------------
    def solid(self, rgb):
        self.base.paste(Image.new("RGBA", (self.w, self.h), rgb), (0, 0))
        return self

    def backdrop(self, top, bottom):
        """Vertical gradient."""
        g = Image.new("RGBA", (1, self.h))
        px = []
        for y in range(self.h):
            t = y / max(1, self.h - 1)
            px.append((
                int(top[0] + (bottom[0] - top[0]) * t),
                int(top[1] + (bottom[1] - top[1]) * t),
                int(top[2] + (bottom[2] - top[2]) * t), 255))
        g.putdata(px)
        self.base.paste(g.resize((self.w, self.h)), (0, 0))
        return self

    # -- layer ops -------------------------------------------------------
    def fade_below(self, alpha):
        """Fade everything drawn so far to `alpha` (0..255); new layer opens."""
        acc = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        for layer in self.baked + [self.work]:
            acc.alpha_composite(layer)
        a = acc.getchannel("A").point(lambda v: int(v * alpha / 255.0))
        acc.putalpha(a)
        self.baked = [acc]
        self.work = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.work)
        return self

    # -- shapes (on the working layer) ------------------------------------
    def rect(self, box, r=0, fill=None, outline=None, width=1):
        if r > 0:
            self.d.rounded_rectangle(box, radius=r, fill=fill,
                                     outline=outline, width=width)
        else:
            self.d.rectangle(box, fill=fill, outline=outline, width=width)
        return self

    def line(self, pts, fill, width=4):
        self.d.line(pts, fill=fill, width=width, joint="curve")
        return self

    def ellipse(self, box, fill=None, outline=None, width=1):
        self.d.ellipse(box, fill=fill, outline=outline, width=width)
        return self

    def polygon(self, pts, fill):
        self.d.polygon(pts, fill=fill)
        return self

    # -- stamps -----------------------------------------------------------
    def stamp(self, img, cx, cy, scale=1.0, rot=0, alpha=255):
        """Paste a real sprite centered at (cx, cy), scaled, rotated
        (PIL degrees, positive = CCW), faded to `alpha`."""
        if isinstance(img, str):
            img = load_sprite(img)
        if scale != 1.0:
            img = img.resize((max(1, int(img.width * scale)),
                              max(1, int(img.height * scale))), Image.BICUBIC)
        if rot:
            img = img.rotate(rot, expand=True, resample=Image.BICUBIC)
        if alpha < 255:
            img = img.copy()
            img.putalpha(img.getchannel("A").point(
                lambda v: int(v * alpha / 255.0)))
        self.work.alpha_composite(img, (int(cx - img.width / 2),
                                        int(cy - img.height / 2)))
        return self

    def glow(self, cx, cy, r, rgb, alpha=110):
        """Soft radial halo behind a sprite (the 'pop' for key objects).
        True radial falloff - no square edges, no smear."""
        r = int(r)
        m = Image.new("L", (r * 2, r * 2), 0)
        md = ImageDraw.Draw(m)
        steps = 14
        for i in range(steps):
            t = i / (steps - 1)                      # 0 -> 1
            rr = max(1, int(r * (1.0 - t)))          # big+faint first ...
            a = int(alpha * t ** 1.6)                # ... small+bright last
            md.ellipse([r - rr, r - rr, r + rr, r + rr], fill=a)
        halo = Image.new("RGBA", (r * 2, r * 2), rgb + (0,))
        halo.putalpha(m)
        self.work.alpha_composite(halo, (int(cx - r), int(cy - r)))
        return self

    # -- finish -----------------------------------------------------------
    def vignette(self, strength=110):
        ov = Image.new("L", (self.w, self.h), 0)
        od = ImageDraw.Draw(ov)
        od.rectangle([0, 0, self.w, self.h], outline=90, width=120)
        ov = ov.filter(ImageFilter.GaussianBlur(100))
        dark = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 255))
        dark.putalpha(ov.point(lambda v: min(strength, v)))
        self.work.alpha_composite(dark)
        return self

    def text(self, txt, size, cx, cy, fill=(255, 250, 240),
             big=True, shadow=True):
        """SOON tiles + owner opt-ins only (rule R2 keeps real thumbs clean)."""
        f = font(size, big=big)
        bb = self.d.textbbox((0, 0), txt, font=f)
        tw, th = bb[2] - bb[0], bb[3] - bb[1]
        x, y = cx - tw // 2 - bb[0], cy - th // 2 - bb[1]
        if shadow:
            self.d.text((x + 3, y + 3), txt, font=f, fill=(0, 0, 0))
        self.d.text((x, y), txt, font=f, fill=fill)
        return self

    def render(self):
        out = self.base.copy()
        for layer in self.baked + [self.work]:
            out.alpha_composite(layer)
        return out.convert("RGB")


# ============================================================================
# THE SPECS - this is what the owner edits through me. One dict per game,
# plain keys, measured in the game's own units (cells, lanes, tiles).
# The snake spec below IS the owner's example sentence, verbatim.
# ============================================================================

SNAKE_SPEC = dict(
    board=(9, 7),                 # cols x rows on screen (poster board)
    cell=84,                      # px per cell -> 756x588 board
    length=9,                     # "tail to be up to 9"
    path=[("L", 5), ("U", 3)],    # "straight to left then straight to up"
    apple=("ahead", 3),           # "before apple by 3 steps" (ahead of head)
    coin=(7, 2),                  # stage a GOGACoin in the open board space
    skin="classic",
)


def snake_cells(spec):
    """Expand the pose spec into board cells. Path runs start at the TAIL;
    the head is the END of the path and faces the last run's direction.
    Returns (cells, facing, apple_cell). The apple ("ahead", n) sits n cells
    beyond the head and is INCLUDED in the fit box, so a pose plus its apple
    always lands fully on the board (clamped, never clipped)."""
    cols, rows = spec["board"]
    cells = [(0, 0)]                      # tail at origin (re-anchored later)
    facing = DIRS["D"]
    for run in spec["path"]:
        letter, n = run
        facing = DIRS[letter]
        for _ in range(n):
            x, y = cells[-1]
            cells.append((x + facing[0], y + facing[1]))
    cells = cells[-int(spec["length"]):]          # cap at `length` segments
    head = cells[-1]
    apple = None
    if isinstance(spec.get("apple"), tuple) and spec["apple"][0] == "ahead":
        n = int(spec["apple"][1])
        apple = (head[0] + facing[0] * n, head[1] + facing[1] * n)
    elif spec.get("apple"):
        apple = tuple(spec["apple"])
    # fit cells + apple together, centered, clamped onto the board
    pts = cells + ([apple] if apple else [])
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    pw, ph = max(xs) - min(xs) + 1, max(ys) - min(ys) + 1
    if pw > cols or ph > rows:
        raise SystemExit(
            "snake pose (%dx%d cells incl. apple) does not fit the %dx%d "
            "board - shorten the path/apple or grow spec['board']"
            % (pw, ph, cols, rows))
    ox = (cols - pw) // 2 - min(xs)
    oy = (rows - ph) // 2 - min(ys)
    ox += max(0, -min(p[0] + ox for p in pts)) \
        - max(0, max(p[0] + ox for p in pts) - (cols - 1))
    oy += max(0, -min(p[1] + oy for p in pts)) \
        - max(0, max(p[1] + oy for p in pts) - (rows - 1))
    cells = [(c[0] + ox, c[1] + oy) for c in cells]
    if apple:
        apple = (apple[0] + ox, apple[1] + oy)
    return cells, facing, apple


def scene_snake(spec=SNAKE_SPEC):
    cols, rows = spec["board"]
    cell = spec["cell"]
    bw, bh = cols * cell, rows * cell
    bx, by = (W - bw) // 2, (H - bh) // 2
    sc = Scene()
    sc.backdrop((16, 34, 18), (10, 22, 12))
    # board panel + checker (the game's own colors: panel 1e3320, alt 224824)
    sc.rect([bx - 12, by - 12, bx + bw + 12, by + bh + 12], r=22,
            fill=(30, 51, 32))
    for gy in range(rows):
        for gx in range(cols):
            if (gx + gy) % 2 == 0:
                sc.rect([bx + gx * cell, by + gy * cell,
                         bx + (gx + 1) * cell, by + (gy + 1) * cell],
                        fill=(34, 72, 36))
    sc.vignette(90)

    cells, facing, apple = snake_cells(spec)
    body = load_sprite("games/snake/body_%s.png" % spec["skin"], int(cell * 0.98))
    head = load_sprite("games/snake/head_%s.png" % spec["skin"], int(cell * 0.98))
    apple_img = load_sprite("games/snake/apple.png", int(cell * 0.94))

    def cc(c):
        return (bx + c[0] * cell + cell // 2, by + c[1] * cell + cell // 2)

    # staged coin (the GOGACoin story) - default: two cells right of tail
    coin = spec.get("coin")
    if coin:
        cx, cy = cc(coin)
        sc.glow(cx, cy, int(cell * 0.8), (255, 201, 60), 80)
        sc.stamp("ui/coin.png", cx, cy, scale=cell * 0.8 / 128.0)
    # apple with a warm glow (the objective must read instantly)
    ax, ay = cc(apple)
    sc.glow(ax, ay, int(cell * 0.85), (255, 120, 90), 90)
    sc.stamp(apple_img, ax, ay)
    # body cells first, then the HEAD (end of the path) rotated to its facing
    for c in cells[:-1]:
        x, y = cc(c)
        sc.stamp(body, x, y)
    hx, hy = cc(cells[-1])
    sc.stamp(head, hx, hy, rot=grid_dir_rotation(facing[0], facing[1]))
    return sc.render()


# ------------------------------------------------------------------- rally

RALLY_SPEC = dict(
    court_pad=64,                 # court margin from canvas edge
    player_x=200,                 # player paddle column (left side)
    player_y=0.62,                # paddle center as H fraction (0..1)
    ai_x=W - 200,                 # AI paddle column
    ai_y=0.38,
    ball=(0.31, 0.62),            # ball just off the player paddle
    speed_lines=True,             # motion streaks trailing the smash
)


def scene_rally(spec=RALLY_SPEC):
    sc = Scene()
    sc.solid((26, 16, 48))
    # court: soft inner panel like the real game's dark stage
    p = spec["court_pad"]
    sc.rect([p, p, W - p, H - p], r=28, fill=(34, 22, 60))
    # center net (dashed)
    for i in range(9):
        y0 = p + 18 + i * ((H - 2 * p - 18) / 9.0)
        sc.rect([W // 2 - 4, y0, W // 2 + 4, y0 + (H - 2 * p) / 9.0 * 0.55],
                fill=(255, 255, 255))
    # top/bottom rails
    sc.rect([p, p - 10, W - p, p + 10], r=5, fill=(64, 48, 100))
    sc.rect([p, H - p - 10, W - p, H - p + 10], r=5, fill=(64, 48, 100))
    sc.vignette(100)

    paddle = load_sprite("games/rally/paddle.png")
    ball = load_sprite("games/rally/ball.png")
    py = spec["player_y"] * H
    ay = spec["ai_y"] * H
    bx, by = spec["ball"][0] * W, spec["ball"][1] * H
    # motion trail: fading dots behind the ball (it just got smashed left)
    if spec.get("speed_lines"):
        for k in range(3):
            tr = 30 - k * 7
            sc.ellipse([bx + 64 + k * 30 - tr, by - tr,
                        bx + 64 + k * 30 + tr, by + tr],
                       fill=(255, 255, 255, 150 - k * 45))
    # AI paddle (top-right), player paddle catching the ball (bottom-left)
    sc.stamp(paddle, spec["ai_x"], ay, rot=90)
    sc.glow(bx, by, 66, (255, 200, 120), 70)
    sc.stamp(paddle, spec["player_x"], py, rot=90)
    sc.stamp(ball, bx, by, scale=0.9)
    return sc.render()


# ------------------------------------------------------------------- lanes

# v0.2.4 SPACE DASH - the posed battle: a fleet of real enemy hulls
# descending five alpha lanes, the Ember hull firing yellow beams into a
# grunt, a thunder chain arcing across, an explosion blooming, the loot
# (coin + power pill) falling. No baked text (rule R2).
LANES_SPEC = dict(
    lane_xs=(1 / 6.0, 0.5, 5 / 6.0),   # guide rails as W fractions
    ship=(0.40, 0.86, 1.0),            # (fx, fy, scale) the player hull
    enemies=(                          # (sprite, fx, fy, scale, flip)
        ("enemy_grunt", 0.40, 0.47, 0.9, False),     # the marked victim
        ("enemy_runner", 0.68, 0.30, 0.78, False),
        ("enemy_grunt2", 0.14, 0.34, 0.8, False),
        ("enemy_tank", 0.86, 0.62, 1.0, False),
        ("enemy_shooter", 0.30, 0.14, 0.7, False),
        ("enemy_ufo_red", 0.60, 0.66, 0.8, False),   # the rare elite
    ),
    beams=((0.40, 0.76), (0.40, 0.63), (0.40, 0.55)),  # bolts to the victim
    bolt_flash=(0.40, 0.51),                     # muzzle impact glow
    thunder=((0.62, 0.72), (0.50, 0.44), (0.30, 0.20)),  # the chain arc
    boom=(0.90, 0.20, 1.6),                      # explosion bloom, open sky
    coin=(0.085, 0.70, 0.55),
    pill=(0.155, 0.60, 1.4),
)


def scene_lanes(spec=LANES_SPEC):
    sc = Scene()
    sc.backdrop((13, 20, 46), (5, 7, 22))
    # nebula breath + starfield, painted soft
    sc.glow(W * 0.72, H * 0.22, 190, (52, 78, 168), 60)
    sc.glow(W * 0.18, H * 0.62, 160, (86, 44, 140), 46)
    for i in range(46):
        sx = (i * 211) % W
        sy = (i * 137 + 29) % H
        a = 120 + (i * 53) % 110
        r = 1 + (i % 3)
        sc.ellipse([sx - r, sy - r, sx + r, sy + r], fill=(220, 232, 255, a))
    # the five ALPHA lane rails (the owner's lane law)
    for i in range(6):
        x = W * (0.083 + i * 0.1667)
        sc.line([(x, 0), (x, H)], (110, 190, 255, 34), width=3)
    # the descending fleet (real Kenney hulls, nose-down as drawn)
    for rel, fx, fy, s, flip in spec["enemies"]:
        img = load_sprite("games/lanes/%s.png" % rel)
        sc.stamp(img, fx * W, fy * H, scale=s * 1.35)
    # yellow beams climbing at the marked victim
    for bx, by in spec["beams"]:
        img = load_sprite("games/lanes/laser_yellow.png")
        sc.stamp(img, bx * W, by * H, scale=3.1)
    sc.glow(spec["bolt_flash"][0] * W, spec["bolt_flash"][1] * H, 70,
            (255, 230, 120), 130)
    # the thunder chain arcing between hulls
    pts = [(fx * W, fy * H) for fx, fy in spec["thunder"]]
    for a, b in zip(pts, pts[1:]):
        sc.line([a, b], (235, 242, 255, 235), width=6)
        sc.line([a, b], (255, 255, 255, 255), width=2)
    # the bloom where an elite just died
    bx, by, bs = spec["boom"]
    sc.glow(bx * W, by * H, 84 * bs, (255, 176, 60), 200)
    sc.glow(bx * W, by * H, 40 * bs, (255, 236, 180), 230)
    # loot on the way down
    coin = load_sprite("ui/coin.png")
    sc.stamp(coin, spec["coin"][0] * W, spec["coin"][1] * H,
             scale=spec["coin"][2])
    pill = load_sprite("games/lanes/item_power.png")
    sc.stamp(pill, spec["pill"][0] * W, spec["pill"][1] * H,
             scale=spec["pill"][2])
    # the player hull + its engine fire (real sprites, nose-up)
    sx, sy, ss = spec["ship"]
    fire = load_sprite("games/lanes/fire_00.png")
    sc.stamp(fire, sx * W, sy * H + 78, scale=2.1)
    sc.glow(sx * W, sy * H, 120, (90, 160, 255), 70)
    ship = load_sprite("games/lanes/ship_orange.png")
    sc.stamp(ship, sx * W, sy * H, scale=ss * 1.5)
    sc.vignette(95)
    return sc.render()


# ----------------------------------------------------------------- invaders

# The v0.3.2 look: the protector over a planet arc, the alien formation
# weaving above, the blue balls mid-flight, the boss looming in the sky,
# the coin + the power core drifting down.
INVADERS_SPEC = dict(
    ship=(0.22, 0.80, 1.6),            # the protector, nose-up
    enemies=(
        ("en_grunt", 0.44, 0.24, 1.5, False),
        ("en_swift", 0.62, 0.36, 1.4, False),
        ("en_diver", 0.30, 0.40, 1.3, False),
        ("en_brute", 0.80, 0.24, 1.5, False),
        ("en_weaver", 0.16, 0.18, 1.3, False),
    ),
    boss="boss_invader",               # the master watching from the dark
    boss_pos=(0.86, 0.52, 1.15),
    bolts=((0.255, 0.70), (0.27, 0.60), (0.29, 0.50), (0.31, 0.41)),
    impact=(0.33, 0.33),
    coin=(0.06, 0.86, 0.9),
    power=(0.12, 0.92, 0.9),
)


def scene_invaders(spec=INVADERS_SPEC):
    sc = Scene()
    sc.backdrop((8, 12, 34), (3, 4, 14))
    sc.glow(W * 0.70, H * 0.18, 200, (48, 40, 120), 56)
    sc.glow(W * 0.16, H * 0.30, 150, (30, 70, 140), 46)
    for i in range(40):
        sx = (i * 233) % W
        sy = (i * 149 + 31) % int(H * 0.72)
        a = 110 + (i * 59) % 120
        r = 1 + (i % 3)
        sc.ellipse([sx - r, sy - r, sx + r, sy + r], fill=(215, 228, 255, a))
    # the alien world's surface arc at the bottom (the tour's law)
    sc.ellipse([int(-W * 0.25), int(H * 0.82), int(W * 1.25), int(H * 1.9)],
               fill=(22, 30, 66))
    sc.ellipse([int(-W * 0.25), int(H * 0.84), int(W * 1.25), int(H * 1.86)],
               fill=(36, 52, 108))
    sc.glow(W * 0.5, H * 0.86, 260, (60, 90, 190), 60)
    # the boss hanging in the sky
    boss = load_sprite("games/invaders/%s.png" % spec["boss"])
    bx, by, bs = spec["boss_pos"]
    sc.glow(bx * W, by * H, 170, (120, 70, 220), 60)
    sc.stamp(boss, bx * W, by * H, scale=bs)
    # the formation (real sprites)
    for rel, fx, fy, s, flip in spec["enemies"]:
        img = load_sprite("games/invaders/%s.png" % rel)
        sc.stamp(img, fx * W, fy * H, scale=s)
    # the blue balls climbing at the marked victim
    for bx2, by2 in spec["bolts"]:
        img = load_sprite("games/invaders/w_azure.png")
        sc.stamp(img, bx2 * W, by2 * H, scale=2.6)
    ix, iy = spec["impact"]
    sc.glow(ix * W, iy * H, 64, (140, 200, 255), 150)
    # the loot drifting down
    coin = load_sprite("ui/coin.png")
    sc.stamp(coin, spec["coin"][0] * W, spec["coin"][1] * H, scale=spec["coin"][2])
    power = load_sprite("games/invaders/item_power.png")
    sc.stamp(power, spec["power"][0] * W, spec["power"][1] * H, scale=spec["power"][2])
    # the protector + its dynamic blue tail (real sprite)
    sx, sy, ss = spec["ship"]
    tail_col = (80, 150, 255)
    for k in range(5):
        sc.glow(sx * W, sy * H + 66 + k * 26, 34 - k * 5, tail_col, 110 - k * 16)
    sc.glow(sx * W, sy * H, 110, tail_col, 66)
    ship = load_sprite("games/invaders/ship_azure.png")
    sc.stamp(ship, sx * W, sy * H, scale=ss * 1.7)
    sc.vignette(95)
    return sc.render()


# ----------------------------------------------------------------- slasher

# The v0.2.9 REWORK look: the dusk minimal background, the painted fruits,
# a sliced watermelon mid-burst (the halves + the juice), the glowing
# blade ribbon, the coin riding by.
# The v0.3.1 look = the CURRENT game: the classic wood board, the classic
# fruits, a sliced apple mid-burst (its two real art halves), the juice,
# the blade ribbon, the coin, the boom.
SLASHER_SPEC = dict(
    fruits=((0, 0.26, 0.26, 0.42), (1, 0.76, 0.28, 0.40),
            (2, 0.58, 0.16, 0.40)),      # (kind, fx, fy, scale)
    bomb=(0.88, 0.72, 0.42),
    slash=((0.06, 0.90), (0.28, 0.64), (0.54, 0.74), (0.90, 0.18)),
    juice=((0.42, 0.52), (0.50, 0.62), (0.38, 0.66), (0.52, 0.46)),
    coin=(0.12, 0.36, 0.34),
)


def scene_slasher(spec=SLASHER_SPEC):
    sc = Scene()
    # the WOOD: the classic board tiled with mirrored seams
    wood = Image.open(game_asset("games/slasher/classic/background.jpg")).convert("RGB")
    wtile = Image.new("RGB", (W, H))
    for row in range(2):
        for col in range(2):
            t = wood
            if col % 2 == 1:
                t = ImageOps.mirror(t)
            if row % 2 == 1:
                t = ImageOps.flip(t)
            wtile.paste(t, (col * wood.width - (wood.width * 2 - W) // 2,
                            row * wood.height - (wood.height * 2 - H) // 2))
    sc.work.alpha_composite(wtile.convert("RGBA"))
    dr = ImageDraw.Draw(sc.work)
    for i in range(10):                        # the tiny sparkles
        rr = __import__("random").Random(900 + i)
        bx, by = rr.uniform(0, W), rr.uniform(0, H)
        sc.ellipse([bx - 2, by - 2, bx + 2, by + 2], fill=(255, 250, 230, 60))
    for kind, fx, fy, s in spec["fruits"]:
        x, y = fx * W, fy * H
        sc.glow(x, y, 80, (255, 230, 170), 34)
        sc.stamp("games/slasher/classic/c_%s.png"
                 % ["apple", "banana", "peach"][kind], x, y, scale=s)
    # the SLICED apple: its two real art halves, thrown apart
    for half, side in _apple_halves():
        hx = 0.42 * W - 30 * side
        hy = 0.55 * H + (8 if side < 0 else -6)
        half = half.rotate(-24 * side, expand=True, resample=Image.BICUBIC)
        sc.work.alpha_composite(half, (int(hx - half.width / 2),
                                       int(hy - half.height / 2)))
    for jx, jy in spec["juice"]:
        sc.ellipse([jx * W - 9, jy * H - 9, jx * W + 9, jy * H + 9],
                   fill=(205, 233, 126, 235))
        sc.ellipse([jx * W - 4, jy * H - 4, jx * W + 4, jy * H + 4],
                   fill=(255, 255, 255, 60))
    if spec.get("bomb"):
        fx, fy, s = spec["bomb"]
        sc.glow(fx * W, fy * H, 60, (255, 120, 60), 60)
        sc.stamp("games/slasher/classic/c_bomb.png", fx * W, fy * H, scale=s)
    if spec.get("coin"):
        fx, fy, s = spec["coin"]
        sc.glow(fx * W, fy * H, 70, (255, 210, 80), 95)
        sc.stamp("ui/coin.png", fx * W, fy * H, scale=s)
    pts = [(fx * W, fy * H) for fx, fy in spec["slash"]]
    sc.line(pts, (255, 240, 210, 80), width=20)
    sc.line(pts, (255, 255, 255, 230), width=7)
    sc.vignette(70)
    return sc.render()


def _apple_halves():
    """the two REAL art halves of the classic apple"""
    out = []
    for name, side in [("c_apple_h1.png", -1), ("c_apple_h2.png", 1)]:
        out.append((Image.open(game_asset("games/slasher/classic/" + name))
                    .convert("RGBA"), side))
    return out


# ------------------------------------------------------------------ hopper

# v0.2.6: the thumb wears the CLEAN sky law (no mountains/trees), the
# lumpy REAL snow caps, the small corner sun and the eye-ful characters.
HOPPER_SPEC = dict(
    platforms=((0.24, 0.80, 0.92), (0.64, 0.60, 0.80), (0.42, 0.36, 0.70)),
    player=(0.47, 0.20),          # mid-air between plat 2 and 3
    snow=30,
    coin=(0.76, 0.42),
)


def scene_hopper(spec=HOPPER_SPEC):
    sc = Scene()
    sc.backdrop((140, 200, 235), (219, 240, 252))
    # the SMALL sun (the snake law: tiny core, tight halo)
    sx, sy = int(W * 0.86), int(H * 0.14)
    sc.glow(sx, sy, 64, (255, 244, 200), 90)
    sc.ellipse([sx - 30, sy - 30, sx + 30, sy + 30], fill=(255, 246, 214, 235))
    sc.ellipse([sx - 20, sy - 20, sx + 20, sy + 20], fill=(255, 252, 236, 255))
    # soft clean clouds
    for cx, cy, s in ((0.20, 0.15, 1.0), (0.72, 0.30, 0.75), (0.50, 0.62, 0.85)):
        x, y = cx * W, cy * H
        sc.ellipse([x - 95 * s, y - 24 * s, x + 95 * s, y + 24 * s],
                   fill=(255, 255, 255, 175))
        sc.ellipse([x - 48 * s, y - 44 * s, x + 42 * s, y + 6 * s],
                   fill=(255, 255, 255, 185))
    # platforms: sandy ledges with LUMPY snow caps that grew flake by flake
    for fx, fy, s in spec["platforms"]:
        px_, py_ = fx * W, fy * H
        pw_, ph_ = 210 * s, 34 * s
        sc.rect([px_ - pw_ / 2, py_ - ph_ / 2, px_ + pw_ / 2, py_ + ph_ / 2],
                r=10, fill=(201, 168, 106))
        sc.rect([px_ - pw_ / 2, py_ - ph_ / 2, px_ + pw_ / 2, py_ - ph_ / 2 + 10],
                r=6, fill=(227, 201, 141))
        # the lumps: overlapping half-ellipses riding the top edge
        import random
        rng = random.Random(int(fx * 1000))
        n = 5
        for i in range(n):
            lx = px_ - pw_ / 2 + (i + 0.5) * pw_ / n
            lr = (pw_ / n) * (0.62 + 0.22 * rng.random())
            sc.ellipse([lx - lr, py_ - ph_ / 2 - lr * 0.9,
                        lx + lr, py_ - ph_ / 2 + lr * 0.5],
                       fill=(255, 255, 255, 244))
    # a GOGACoin between the ledges
    if spec.get("coin"):
        kx, ky = spec["coin"][0] * W, spec["coin"][1] * H
        sc.glow(kx, ky, 40, (255, 216, 110), 120)
        sc.ellipse([kx - 20, ky - 20, kx + 20, ky + 20], fill=(246, 200, 80))
        sc.ellipse([kx - 13, ky - 13, kx + 13, ky + 13],
                   outline=(255, 232, 160), width=3)
    # the SNOWBALL with its eyes (mouthless, the owner rule)
    bx, by = spec["player"][0] * W, spec["player"][1] * H
    R = 52
    sc.glow(bx, by, 96, (255, 255, 255), 70)
    sc.ellipse([bx - R, by - R, bx + R, by + R], fill=(143, 169, 189))
    sc.ellipse([bx - R + 5, by - R + 5, bx + R - 5, by + R - 5],
               fill=(223, 233, 242))
    sc.ellipse([bx - R + 8, by - R + 12, bx + R - 8, by + R - 4],
               fill=(255, 255, 255, 250))
    sc.ellipse([bx - 30, by - 34, bx + 2, by - 2], fill=(255, 255, 255, 140))
    for ex in (-14, 16):
        sc.ellipse([bx + ex - 11, by - 16, bx + ex + 11, by + 8],
                   fill=(255, 255, 255, 255))
        sc.ellipse([bx + ex - 4, by - 8, bx + ex + 6, by + 3],
                   fill=(26, 36, 48, 255))
    # the falling snow (deterministic sprinkle)
    for i in range(spec.get("snow", 0)):
        x = (i * 367) % W
        y = (i * 211 + 40) % H
        r = 3 + (i % 3)
        sc.ellipse([x, y, x + r, y + r], fill=(255, 255, 255, 215))
    sc.vignette(80)
    return sc.render()


# ------------------------------------------------------------------- merge

# The v0.2.8 look: the big centered board on the WARM PAPER (the owner:
# "the classic theme background is blue... for classic, make the background
# really suitable" - the deep blue belongs to Deep Sea alone). The old
# "+1" pop is GONE - its Kenney "1" glyph read as "41" on an empty square
# (the owner: "an empty square has number 41 which is weird"). None =
# empty cell.
MERGE_SPEC = dict(
    grid=[
        ["1024", "512", "256", "128"],
        ["8", "16", "32", "64"],
        ["4", "2", None, "8"],
        ["2", None, None, "4"],
    ],
    coin_cell=(1, 3),             # the empty cell wearing the GOGACoin
    colors={"2": "efe6d8", "4": "edd9b0", "8": "f2b179", "16": "f59563",
            "32": "f67c5f", "64": "f65e3b", "128": "edcf72", "256": "edcc61",
            "512": "edc22e", "1024": "edc850"},
    light_ink={"efe6d8", "edd9b0", "edcf72", "edcc61", "edc850", "edc22e"},
    tile=138, gap=12,
    hero="1024",                  # the tile that gets the glow
    bg_top=(250, 248, 239), bg_bottom=(233, 222, 202),
)


def scene_merge(spec=MERGE_SPEC):
    sc = Scene()
    sc.backdrop(spec["bg_top"], spec["bg_bottom"])
    t, g = spec["tile"], spec["gap"]
    grid = spec["grid"]
    rows, cols = len(grid), len(grid[0])
    bw = cols * t + (cols + 1) * g
    bh = rows * t + (rows + 1) * g
    bx, by = (W - bw) // 2, (H - bh) // 2 + 10
    # the soft warm halo behind the board (the paper breathes)
    sc.glow(W // 2, H // 2, int(bw * 0.78), (255, 252, 240), 60)
    # the frame (the classic warm brown, reads on the cream paper)
    sc.rect([bx - 10, by - 10, bx + bw + 10, by + bh + 10], r=22,
            fill=(185, 169, 154))
    for r_i, row in enumerate(grid):
        for c_i, label in enumerate(row):
            x = bx + g + c_i * (t + g)
            y = by + g + r_i * (t + g)
            if label is None:
                sc.rect([x, y, x + t, y + t], r=14, fill=(205, 193, 180))
                if (c_i, r_i) == spec["coin_cell"]:
                    # the GOGACoin grown in the empty cell (the real asset,
                    # with its warm halo so it reads TAKE ME)
                    sc.glow(x + t / 2, y + t / 2, int(t * 0.62), (255, 210, 70), 90)
                    coin = load_sprite("ui/coin.png", int(t * 0.62))
                    sc.stamp(coin, x + t / 2, y + t / 2)
                continue
            color = spec["colors"][label]
            sc.rect([x, y, x + t, y + t], r=14, fill="#" + color)
            if label == spec.get("hero"):
                sc.glow(x + t / 2, y + t / 2, int(t * 0.95), (255, 220, 90), 95)
            # fit the label inside the tile by MEASUREMENT (the game scales
            # fonts too; Kenney Rocket runs wide)
            size = int(t * 0.44)
            fd = ImageDraw.Draw(sc.work)
            max_w = t * 0.84
            while size > 12:
                f = font(size)
                bb = fd.textbbox((0, 0), label, font=f)
                if bb[2] - bb[0] <= max_w and bb[3] - bb[1] <= t * 0.7:
                    break
                size -= 2
            ink = INK if color in spec["light_ink"] else (255, 255, 255)
            fd.text((x + (t - bb[2] + bb[0]) / 2, y + (t - bb[3] + bb[1]) / 2),
                    label, font=f, fill=ink)
    sc.vignette(64)
    return sc.render()


# ------------------------------------------------------------------- dario

# The v0.3.1 CURSED DARIO look: the Kenney day sky, the grass/dirt ground,
# the ? box, the snail, the purple Witcher silhouette looming, the hero
# mid-jump with the blade of... no - just the classic stomp arc.
DARIO_SPEC = dict(
    ground_y=0.78,
    gap=(0.42, 0.62),
    ledge=(0.55, 1.9),            # the grass ledge with the ? box
    hero=(0.40, 0.46, -8),        # mid-jump over the pit
    coins=((0.47, 0.30), (0.53, 0.24), (0.59, 0.30)),
    snail=(0.76, 0.95),
    witcher=(0.86, 0.30),
    box=(0.60, 0.50),
)


def scene_dario(spec=DARIO_SPEC):
    sc = Scene()
    # the day sky (the Kenney bg, mirrored-tiled across the whole canvas)
    bg = Image.open(game_asset("games/dario/bg_day.png")).convert("RGBA")
    ncols = W // bg.width + 2
    nrows = H // bg.height + 2
    x0 = -(bg.width * ncols - W) // 2
    y0 = -(bg.height * nrows - H) // 2
    for row in range(nrows):
        for col in range(ncols):
            t = bg
            if col % 2 == 1:
                t = ImageOps.mirror(t)
            if row % 2 == 1:
                t = ImageOps.flip(t)
            sc.work.alpha_composite(t, (x0 + col * bg.width,
                            y0 + row * bg.height))
    gy = int(spec["ground_y"] * H)
    # the Witcher LOOMS in the sky (the curse)
    wimg = Image.open(game_asset("games/dario/witcher.png")).convert("RGBA")
    wimg = wimg.resize((200, 240), Image.BICUBIC)
    wfx, wfy = spec["witcher"]
    glow = Image.new("RGBA", (260, 300), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([30, 30, 230, 270], fill=(150, 80, 200, 70))
    glow = glow.filter(ImageFilter.GaussianBlur(20))
    sc.work.alpha_composite(glow, (int(wfx * W) - 130, int(wfy * H) - 150))
    sc.work.alpha_composite(wimg, (int(wfx * W) - 100, int(wfy * H) - 120))
    # the ground: grass lips + dirt bodies, split by THE pit
    grass = load_sprite("games/dario/tile_grass.png")
    dirt = load_sprite("image_cache_fix", ) if False else load_sprite(
            "games/dario/tile_dirt.png")
    ts = grass.width
    x = 0
    gx0, gx1 = spec["gap"][0] * W, spec["gap"][1] * W
    while x < W:
        cx = x + ts / 2
        if gx0 - 6 <= cx <= gx1 + 6:
            x += ts
            continue
        sc.stamp(grass, cx, gy + ts / 2)
        sc.stamp(dirt, cx, gy + ts * 1.5)
        x += ts
    # the ledge with the ? box
    lfx, lrows = spec["ledge"]
    lx = int(lfx * W)
    ly = gy - int(lrows * ts)
    for k in range(3):
        sc.stamp(grass, lx - ts + k * ts, ly + ts / 2)
        sc.stamp(dirt, lx - ts + k * ts, ly + ts * 1.5)
    bfx, bfy = spec["box"]
    boximg = load_sprite("games/dario/tile_box_coin.png")
    sc.stamp(boximg, bfx * W, ly - boximg.height / 2 + 4)
    # the coins
    coin = load_sprite("games/dario/item_coin.png", 56)
    for fx, fy in spec["coins"]:
        sc.glow(fx * W, fy * H, 40, (255, 210, 80), 80)
        sc.stamp(coin, fx * W, fy * H)
    # the snail
    sfx, ss = spec["snail"]
    snail = load_sprite("games/dario/enemy_snail1.png")
    sc.stamp(snail, sfx * W, gy - snail.height * ss / 2, scale=ss)
    # THE HERO mid-jump
    hero = load_sprite("games/dario/hero_jump.png")
    hfx, hfy, tilt = spec["hero"]
    sc.glow(hfx * W, hfy * H, 90, (255, 255, 255), 55)
    sc.stamp(hero, hfx * W, hfy * H, scale=1.35, rot=tilt)
    sc.vignette(58)
    return sc.render()


# ---------------------------------------------------------------------- xo

# The v0.2.8 SKETCH REMAKE look (the owner: "rename it to just XO without
# the word ladder and remake it" + his xo html): the sketchbook page, the
# white board with the hard ink offset shadow, the red X vs the blue O,
# the amber winning strike, and the GOGACoin waiting in an empty cell
# (the per-3-rounds coin race). NO ladder - the ladder is gone.
XO_SPEC = dict(
    board_c=(0.52, 0.52),         # board center (fractions)
    cell=172,                     # px per cell
    xs=((0, 0), (1, 0), (2, 0)),      # X's winning row (a real 5-move game)
    os=((1, 1), (0, 2)),              # O's two replies
    win_line=((0, 0), (2, 0)),    # the amber strike (the drama)
    coin_cell=(2, 2),             # the GOGACoin waiting in an empty cell
)


def scene_xo(spec=XO_SPEC):
    sc = Scene()
    # the sketchbook page (warm paper, the faint ruled lines)
    sc.backdrop((250, 249, 246), (238, 234, 226))
    dr = ImageDraw.Draw(sc.work)
    for y in range(40, H, 46):
        dr.line([(0, y), (W, y)], fill=(0, 0, 0, 9), width=2)
    dr.line([(34, 0), (34, H)], fill=(217, 90, 90, 24), width=3)
    bcx, bcy = spec["board_c"][0] * W, spec["board_c"][1] * H
    cell = spec["cell"]
    half = cell * 1.5

    def cc(cxy):
        return (bcx - half + cxy[0] * cell + cell / 2,
                bcy - half + cxy[1] * cell + cell / 2)

    def rough_line(p0, p1, width, col, seed):
        # a hand-drawn stroke: wobble perpendicular, round joints
        rr = __import__("random").Random(seed)
        dx, dy = p1[0] - p0[0], p1[1] - p0[1]
        ln = max(1.0, (dx * dx + dy * dy) ** 0.5)
        ux, uy = dx / ln, dy / ln
        px, py = -uy, ux
        pts = []
        for k in range(8):
            f = k / 7.0
            w = (rr.uniform(-1, 1)) * 3.0
            pts.append((p0[0] + dx * f + px * w, p0[1] + dy * f + py * w))
        dr.line(pts, fill=col, width=width, joint="curve")

    def cross(cxy, col, dark, r, seed, width=17):
        x, y = cc(cxy)
        rough_line((x - r + 4, y - r + 4), (x + r + 4, y + r + 4), width,
                   dark + (210,), seed)
        rough_line((x - r, y - r), (x + r, y + r), width, col + (255,), seed + 1)
        rough_line((x - r + 4, y + r + 4), (x + r + 4, y - r + 4), width,
                   dark + (210,), seed + 2)
        rough_line((x - r, y + r), (x + r, y - r), width, col + (255,), seed + 3)

    def ring(cxy, col, dark, r, seed, width=17):
        x, y = cc(cxy)
        rr = __import__("random").Random(seed)
        a0 = rr.uniform(0, 6.28)
        for rad, ccol in ((r + 4, dark + (210,)), (r, col + (255,))):
            pts = []
            for k in range(27):
                ang = a0 + 6.283 * k / 26.0
                wob = rr.uniform(-1, 1) * 2.6
                pts.append((x + math.cos(ang) * (rad + wob),
                            y + math.sin(ang) * (rad + wob)))
            dr.line(pts, fill=ccol, width=width, joint="curve")

    # the board plate: white, ink rim, hard offset shadow (the html look)
    pad = 26
    sc.rect([bcx - half - pad + 7, bcy - half - pad + 7,
             bcx + half + pad + 7, bcy + half + pad + 7], r=22,
            fill=(26, 26, 26))
    sc.rect([bcx - half - pad, bcy - half - pad,
             bcx + half + pad, bcy + half + pad], r=22, fill=(255, 255, 255))
    sc.rect([bcx - half - pad, bcy - half - pad,
             bcx + half + pad, bcy + half + pad], r=22,
            outline=(26, 26, 26), width=5)
    # the four wobbly grid strokes
    for k in (1, 2):
        off = -half + k * cell
        rough_line((bcx + off, bcy - half + 8), (bcx + off, bcy + half - 8),
                   7, (26, 26, 26, 205), 40 + k)
        rough_line((bcx - half + 8, bcy + off), (bcx + half - 8, bcy + off),
                   7, (26, 26, 26, 205), 50 + k)
    XCOL, XDARK = (239, 68, 68), (153, 27, 27)
    OCOL, ODARK = (59, 130, 246), (30, 64, 175)
    # the amber winners glow behind the strike row
    wl = spec["win_line"]
    for cxy in wl:
        x, y = cc(cxy)
        sc.glow(x, y, int(cell * 0.72), (245, 158, 11), 80)
    for cxy in spec["xs"]:
        cross(cxy, XCOL, XDARK, int(cell * 0.29), hash(cxy) % 997)
    for cxy in spec["os"]:
        ring(cxy, OCOL, ODARK, int(cell * 0.29), hash(cxy) % 997 + 13)
    # the amber strike across the winning row (the marker swipe)
    x0, y0 = cc(wl[0])
    x1, y1 = cc(wl[1])
    rough_line((x0 - cell * 0.22, y0), (x1 + cell * 0.22, y1), 13,
               (245, 158, 11, 235), 77)
    # the GOGACoin waiting in an empty cell (the coin race)
    cx, cy = cc(spec["coin_cell"])
    sc.glow(cx, cy, int(cell * 0.6), (255, 210, 70), 95)
    coin = load_sprite("ui/coin.png", int(cell * 0.56))
    sc.stamp(coin, cx, cy)
    sc.vignette(56)
    return sc.render()


# ----------------------------------------------------------- registry/CLI

# Real-game scenes (composed, 960x640, no baked text - rule R2).
SCENES = {
    "snake": scene_snake,
    "rally": scene_rally,
    "lanes": scene_lanes,
    "invaders": scene_invaders,
    "slasher": scene_slasher,
    "hopper": scene_hopper,
    "merge": scene_merge,
    "dario": scene_dario,
    "xo": scene_xo,
}

# SOON tiles keep the v0.1.6 placeholder design (rule R4). This list shrinks
# as games leave the workshop - dario/xo left in v0.1.7.
SOON_NAMES = {"hen": "HEN INVADERS", "spud": "COSMIC SPUD",
              "maze": "ESCAPE THE MAZE", "matcher": "MATCHER",
              "keys": "KEY SINGER", "poptd": "POP TD"}


def q_mark(size, fill):
    """The Kenney_Rocket ? is DOTLESS with a stub tail - it never read like
    a real question mark. v0.1.9 owner fix: 'add more blocks to make the
    tail a little longer like a real ?' - the stub grows into a proper
    straight drop and the dot lands below it, with a gap (same surgery
    language as the v0.0.9 mystery_q fix). Returns a cropped RGBA glyph."""
    f = font(size, big=True)
    img = Image.new("RGBA", (size * 2 + 40, size * 2 + 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.text((20, 20), "?", font=f, fill=fill)
    bb = img.getbbox()
    px = img.load()
    gh = bb[3] - bb[1]
    # the tail stub = whatever ink the bottom rows carry (x-range of the
    # lowest stem)
    xs = [x for x in range(img.width) if px[x, bb[3] - 2][3] > 40]
    if xs and gh > 0:
        x0, x1 = min(xs), max(xs)
        drop = int(gh * 0.36)
        d.rectangle([x0, bb[3] - 2, x1, bb[3] + drop], fill=fill)
        # the dot below the tail, with a gap - that is what makes it a
        # REAL ?  (hook + drop + dot)
        gap = int(size * 0.10)
        dot = int((x1 - x0) * 1.12)
        dcx = (x0 + x1) // 2
        d.rounded_rectangle([dcx - dot // 2, bb[3] + drop + gap,
                             dcx + dot // 2, bb[3] + drop + gap + dot],
                            radius=max(3, dot // 6), fill=fill)
    return img.crop(img.getbbox())


def scene_soon(title):
    sc = Scene()
    sc.solid((52, 42, 66))
    for i in range(-640, W, 180):
        sc.polygon([(i, H), (i + 60, H), (i + 700, 0), (i + 640, 0)],
                   (64, 52, 84, 255))
    sc.stamp(q_mark(240, (122, 108, 180, 255)), W // 2, 218)
    sc.text(title, 60, W // 2, 500, fill=(210, 200, 240))
    sc.text("SOON", 40, W // 2, 564, fill=(150, 130, 210), big=False,
            shadow=False)
    return sc.render()


def compose(game):
    if game in SCENES:
        return SCENES[game]()
    if game in SOON_NAMES:
        return scene_soon(SOON_NAMES[game])
    raise SystemExit("unknown game: %s (have %s + SOON %s)" % (
        game, ", ".join(sorted(SCENES)), ", ".join(sorted(SOON_NAMES))))


def install(games):
    """Write thumbs straight into assets/thumbs (same contract as
    derive_assets.py thumbs()). Deterministic: same spec -> same pixels."""
    tdir = os.path.join(ASSETS, "thumbs")
    os.makedirs(tdir, exist_ok=True)
    for g in games:
        compose(g).save(os.path.join(tdir, "%s.png" % g))
        print("thumb: %s.png" % g)


def sheet(out_path, games=None):
    """Contact sheet of every composed scene (the vision-review helper)."""
    games = games or sorted(SCENES) + ["__SOON__"]
    cols = 4
    tw, th = 480, 320
    rows = (len(games) + cols - 1) // cols
    sh = Image.new("RGB", (cols * tw + (cols + 1) * 8,
                           rows * th + (rows + 1) * 8), (20, 18, 28))
    for i, g in enumerate(games):
        img = (scene_soon("WORKSHOP") if g == "__SOON__" else compose(g)) \
            .resize((tw, th), Image.LANCZOS)
        x = 8 + (i % cols) * (tw + 8)
        y = 8 + (i // cols) * (th + 8)
        sh.paste(img, (x, y))
    sh.save(out_path)
    print("sheet:", out_path)


def compare(out_path, old_dir, games):
    """Before/after proof: old thumb LEFT, composed thumb RIGHT."""
    tw, th = 480, 320
    pad = 34
    rows = len(games)
    sh = Image.new("RGB", (2 * tw + 3 * pad, rows * th + (rows + 1) * pad + 8),
                   (20, 18, 28))
    d = ImageDraw.Draw(sh)
    d.text((pad, 8), "BEFORE", font=font(26), fill=(232, 87, 74))
    d.text((tw + 2 * pad, 8), "AFTER (composed 960x640)", font=font(26),
           fill=(88, 196, 112))
    for i, g in enumerate(games):
        y = pad + 8 + i * th + i * 26
        old = os.path.join(old_dir, "%s.png" % g)
        if os.path.exists(old):
            o = Image.open(old).convert("RGB")
            o = o.resize((tw, int(o.height * tw / o.width)), Image.LANCZOS)
            sh.paste(o, (pad, y + (th - o.height) // 2))
        new = compose(g).resize((tw, th), Image.LANCZOS)
        sh.paste(new, (tw + 2 * pad, y))
        d.text((pad + 4, y + 4), g, font=font(20), fill=(255, 220, 170))
    sh.save(out_path)
    print("compare:", out_path)


def main():
    ap = argparse.ArgumentParser(
        description="GOGABox programmable thumbnail composer (960x640)")
    ap.add_argument("--game", help="one game id")
    ap.add_argument("--all", action="store_true", help="install all thumbs")
    ap.add_argument("--out", help="write single scene to this path")
    ap.add_argument("--sheet", help="write a contact sheet to this path")
    ap.add_argument("--compare", nargs=2, metavar=("OLD_DIR", "OUT_PNG"),
                    help="before/after proof sheet")
    args = ap.parse_args()
    if args.compare:
        old_dir, out_png = args.compare
        compare(out_png, old_dir, sorted(SCENES))
    elif args.sheet:
        sheet(args.sheet)
    elif args.out and args.game:
        compose(args.game).save(args.out)
        print("wrote", args.out)
    elif args.all:
        install(sorted(SCENES) + sorted(SOON_NAMES))
    elif args.game:
        compose(args.game).show()
    else:
        ap.print_help()


if __name__ == "__main__":
    main()
