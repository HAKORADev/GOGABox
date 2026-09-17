#!/usr/bin/env python3
"""v040-11 DEADLY WORM - OUR OWN ART (the owner's order: "nuke all
original_art and make our own one; when you work on our new art, study
from the original - 'oh original has that animal, let me do it then'").

ZERO original bytes are read or cut. The original's DESIGN LANGUAGE is
the teacher (studied from the archived sheets in study_locker):
  - the worm: a giant round-jawed head with a teeth ring, scalloped
    fin-shaped body segments, a tapered tail spike
  - the creatures: painterly side-view animals that walk LEFT with dark
    rims - camel, tiger, puma, polar bear, penguin, mole, lizard, yeti
  - the humans: small runners with skin/clothes variants, 10-frame runs
  - the machines: chunky side-view vehicles, spinning rotors/props
Everything here is DRAWN BY CODE with one cohesive design system:
dark outline, two-stop gradient bodies, belly light, rim light, grain.
Deterministic (fixed seeds) and idempotent.

Usage: python3 tools/v0411_worm_ours.py [family ...]
       (no args = everything; families: worms humans animals ground
        vehicles shots fx places pows shop extras thumb montage)
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = "/home/z/my-project/gogabox/projects/gogabox"
OUT = ROOT + "/assets/games/deathworm"
THUMB_OUT = ROOT + "/assets/thumbs"

os.makedirs(OUT, exist_ok=True)
for sub in ("worms", "things/humans", "things/animals", "things/ground",
            "things/vehicles", "things/shots", "things/fx", "places",
            "pows", "shop"):
    os.makedirs(OUT + "/" + sub, exist_ok=True)

# ----------------------------------------------------------------- kit
FONT_PATHS = ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
              "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]


def font(sz):
    for p in FONT_PATHS:
        try:
            return ImageFont.truetype(p, sz)
        except Exception:
            continue
    return ImageFont.load_default()


def rng_for(name):
    return random.Random("v0411-ours-" + name)


def lerp(a, b, t):
    return a + (b - a) * t


def mix(c1, c2, t):
    return tuple(int(round(lerp(c1[i], c2[i], t))) for i in range(3))


def darken(c, f):
    return tuple(max(0, int(round(v * f))) for v in c[:3])


def lighten(c, f):
    return tuple(min(255, int(round(255 - (255 - v) * f))) for v in c[:3])


def with_a(c, a=255):
    return (c[0], c[1], c[2], a)


def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def vgrad(d, box, top, bot):
    """a two-stop vertical gradient rect"""
    x0, y0, x1, y1 = [int(round(v)) for v in box]
    h = max(1, y1 - y0)
    for y in range(y0, y1):
        d.line([(x0, y), (x1, y)], fill=with_a(mix(top, bot, (y - y0) / h)))


def blob(d, pts, fill, outline=None, width=4):
    d.polygon(pts, fill=fill, outline=outline, width=width)


def ellipse_pts(cx, cy, rx, ry, n=26, rot=0.0):
    return [(cx + math.cos(math.tau * i / n + rot) * rx,
             cy + math.sin(math.tau * i / n + rot) * ry) for i in range(n)]


def draw_ellipse(d, cx, cy, rx, ry, fill, outline=None, width=4, rot=0.0):
    d.polygon(ellipse_pts(cx, cy, rx, ry, rot=rot), fill=fill,
              outline=outline, width=width)


def draw_grad_ellipse(d, cx, cy, rx, ry, top, bot, outline=None, w=4):
    """an ellipse filled with a vertical gradient (mask + paste)"""
    n = 32
    mask = Image.new("L", (int(rx * 2 + 4), int(ry * 2 + 4)), 0)
    md = ImageDraw.Draw(mask)
    md.polygon([(2 + rx + math.cos(math.tau * i / n) * rx,
                 2 + ry + math.sin(math.tau * i / n) * ry) for i in range(n)],
               fill=255)
    grad = Image.new("RGBA", mask.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for yy in range(mask.size[1]):
        t = yy / max(1, mask.size[1] - 1)
        gd.line([(0, yy), (mask.size[0], yy)], fill=with_a(mix(top, bot, t)))
    d._image.paste(grad, (int(cx - rx - 2), int(cy - ry - 2)), mask)
    if outline is not None:
        d.polygon(ellipse_pts(cx, cy, rx, ry), outline=outline, width=w)


class Layer:
    """wrap an RGBA image so draw helpers can paste gradients"""

    def __init__(self, w, h):
        self.im = canvas(w, h)
        self.d = ImageDraw.Draw(self.im)
        self.w, self.h = w, h

    def paste(self, src, pos, mask=None):
        self.im.paste(src, pos, mask)


def finish(im, name, alpha_stats=False):
    im.save(OUT + "/" + name)
    return name


def grain(im, name, amount=10, density=0.045):
    """a subtle pixel grain so flat gradients read painterly"""
    r = rng_for("grain-" + name)
    d = ImageDraw.Draw(im)
    w, h = im.size
    for _ in range(int(w * h * density)):
        x, y = r.randrange(w), r.randrange(h)
        px = im.getpixel((x, y))
        if px[3] > 30:
            f = r.uniform(-amount, amount)
            c = (max(0, min(255, int(px[0] + f))),
                 max(0, min(255, int(px[1] + f))),
                 max(0, min(255, int(px[2] + f))), px[3])
            d.point((x, y), fill=c)


def outline_im(im, color=(28, 16, 12, 255), width=3):
    """stroke the silhouette: dilated alpha minus original"""
    a = im.split()[3]
    dil = a.filter(ImageFilter.MaxFilter(width * 2 + 1))
    ring = Image.new("RGBA", im.size, color)
    ring.putalpha(dil.point(lambda v: 255 if v > 90 else 0))
    base = ring.copy()
    base.alpha_composite(im)
    return base


# ================================================================ THE WORMS
# the teacher's anatomy: a giant round-jawed head (a teeth ring around the
# mouth), scalloped fin-shaped body segments, a tapered tail spike - our
# own ten identities wear that anatomy in OUR colors.
WORMS = [
    {"id": "w01", "name": "THE CLASSIC", "skin": (214, 60, 48),
     "belly": (240, 150, 110), "fin": (110, 118, 138), "eye": (250, 214, 70)},
    {"id": "w02", "name": "THE EEL", "skin": (44, 160, 150),
     "belly": (150, 232, 210), "fin": (30, 108, 116), "eye": (250, 240, 160)},
    {"id": "w03", "name": "THE DUNE", "skin": (206, 164, 96),
     "belly": (238, 214, 160), "fin": (150, 112, 62), "eye": (90, 60, 30)},
    {"id": "w04", "name": "THE STAR", "skin": (150, 84, 200),
     "belly": (216, 170, 240), "fin": (94, 52, 140), "eye": (255, 220, 120)},
    {"id": "w05", "name": "THE FROST", "skin": (92, 160, 214),
     "belly": (190, 226, 248), "fin": (52, 100, 160), "eye": (220, 245, 255)},
    {"id": "w06", "name": "THE TITAN", "skin": (128, 92, 62),
     "belly": (196, 156, 112), "fin": (84, 58, 38), "eye": (255, 190, 80)},
    {"id": "w07", "name": "THE VIPER", "skin": (88, 170, 70),
     "belly": (178, 226, 140), "fin": (44, 110, 44), "eye": (255, 200, 60)},
    {"id": "w08", "name": "THE ROBO", "skin": (140, 148, 158),
     "belly": (198, 206, 214), "fin": (86, 92, 104), "eye": (80, 230, 255)},
    {"id": "w09", "name": "THE CYBER", "skin": (40, 190, 220),
     "belly": (150, 240, 250), "fin": (16, 90, 130), "eye": (120, 255, 190)},
    {"id": "w10", "name": "THE DRAGON", "skin": (230, 150, 36),
     "belly": (250, 208, 120), "fin": (160, 84, 20), "eye": (255, 240, 150)},
]

HEAD = 190          # the head canvas is square-ish; the jaw is the star


def worm_head(w, open_mouth):
    """the giant round head facing RIGHT - the teacher's star piece"""
    S = HEAD + 60
    L = Layer(S, S)
    cx, cy = S * 0.44, S * 0.52
    R = HEAD * 0.46
    skin, belly = w["skin"], w["belly"]
    dark = darken(skin, 0.55)
    # the skull dome (a big round mass, slightly egg toward the jaw)
    draw_grad_ellipse(L.d, cx, cy - R * 0.12, R * 1.06, R * 0.98,
                      lighten(skin, 1.02), darken(skin, 0.78),
                      outline=(28, 16, 12, 255), w=5)
    # the jaw: an open wedge under the skull (wider when open)
    jaw_open = 0.62 if open_mouth else 0.18
    jx, jy = cx + R * 0.42, cy + R * 0.30
    jaw = [
        (jx - R * 0.62, jy - R * (0.10 + jaw_open * 0.72)),
        (jx + R * 0.86, jy - R * (0.02 + jaw_open * 0.38)),
        (jx + R * 0.92, jy + R * 0.10),
        (jx + R * 0.10, jy + R * 0.52),
        (jx - R * 0.66, jy + R * 0.30),
    ]
    L.d.polygon(jaw, fill=with_a(darken(skin, 0.82)))
    L.d.polygon(jaw, outline=(28, 16, 12, 255), width=5)
    # the mouth interior (only honest when open)
    if open_mouth:
        mouth = [
            (jx - R * 0.42, jy - R * (0.04 + jaw_open * 0.46)),
            (jx + R * 0.72, jy - R * (0.02 + jaw_open * 0.24)),
            (jx + R * 0.54, jy + R * 0.20),
            (jx - R * 0.30, jy + R * 0.26),
        ]
        L.d.polygon(mouth, fill=(52, 12, 12, 255))
        # the tongue
        L.d.polygon([(jx - R * 0.10, jy + R * 0.14),
                     (jx + R * 0.42, jy + R * 0.08),
                     (jx + R * 0.10, jy + R * 0.24)],
                    fill=(226, 92, 92, 255))
    # THE TEETH RING (the teacher's signature): BIG irregular fangs
    tooth = (250, 246, 230, 255)
    tooth_d = (210, 200, 176, 255)
    rr2 = rng_for("teeth-" + w["id"] + str(open_mouth))
    n_top = 5
    for i in range(n_top):
        t = i / (n_top - 1)
        bx = lerp(jx - R * 0.46, jx + R * 0.66, t)
        by = jy - R * (0.02 + jaw_open * (0.40 - 0.24 * t))
        h = R * (0.30 + 0.10 * rr2.random() - 0.08 * abs(t - 0.5))
        wd = R * (0.11 + 0.03 * rr2.random())
        L.d.polygon([(bx - wd, by), (bx + wd, by), (bx + wd * 0.2, by + h)],
                    fill=tooth, outline=(70, 40, 30, 255))
    n_bot = 4
    for i in range(n_bot):
        t = i / (n_bot - 1)
        bx = lerp(jx - R * 0.28, jx + R * 0.52, t)
        by = jy + R * (0.34 - jaw_open * 0.10)
        h = R * (0.24 + 0.08 * rr2.random())
        wd = R * (0.10 + 0.03 * rr2.random())
        L.d.polygon([(bx - wd, by), (bx + wd, by), (bx - wd * 0.2, by - h)],
                    fill=tooth_d, outline=(70, 40, 30, 255))
    # the eye (angry brow, the teacher's read)
    ex, ey = cx + R * 0.10, cy - R * 0.34
    draw_ellipse(L.d, ex, ey, R * 0.20, R * 0.16, (252, 250, 240, 255),
                 outline=(28, 16, 12, 255), width=4)
    L.d.ellipse([ex - R * 0.07, ey - R * 0.07, ex + R * 0.07, ey + R * 0.07],
                fill=with_a(darken(w["eye"], 0.72)))
    L.d.polygon([(ex - R * 0.30, ey - R * 0.28), (ex + R * 0.26, ey - R * 0.40),
                 (ex + R * 0.22, ey - R * 0.22)],
                fill=with_a(darken(skin, 0.42)))
    # the head fins (identity: horns for some, fins for others)
    if w["id"] in ("w01", "w06", "w10"):
        for hx, hy, hr in [(-0.30, -0.86, 0.24), (0.10, -0.98, 0.20)]:
            L.d.polygon([(cx + R * (hx - 0.10), cy + R * hy),
                         (cx + R * (hx + 0.16), cy + R * (hy - 0.26)),
                         (cx + R * (hx + 0.26), cy + R * (hy + 0.06))],
                        fill=with_a(w["fin"]),
                        outline=(28, 16, 12, 255))
    elif w["id"] in ("w02", "w09"):
        L.d.polygon([(cx - R * 0.5, cy - R * 0.6),
                     (cx - R * 0.95, cy - R * 0.95),
                     (cx - R * 0.38, cy - R * 0.92)],
                    fill=with_a(w["fin"]), outline=(28, 16, 12, 255))
    # gill slits on the cheek
    for g in range(3):
        gy = cy + R * (-0.10 + g * 0.14)
        L.d.line([(cx - R * 0.72, gy), (cx - R * 0.52, gy - R * 0.06)],
                 fill=with_a(darken(skin, 0.6)), width=4)
    # rim light
    L.d.arc([cx - R * 1.06, cy - R * 1.16, cx + R * 1.06, cy + R * 0.84],
            200, 300, fill=with_a(lighten(skin, 0.9)), width=4)
    im = outline_im(L.im, (24, 12, 10, 255), 3)
    grain(im, w["id"] + "-head")
    return im.crop(im.getbbox())


def worm_body(w):
    """a scalloped fin-segment facing RIGHT (the chain reuses it)"""
    Wc, Hc = 150, 120
    L = Layer(Wc, Hc)
    skin, fin = w["skin"], w["fin"]
    # the segment mass
    draw_grad_ellipse(L.d, Wc * 0.46, Hc * 0.5, Wc * 0.40, Hc * 0.36,
                      lighten(skin, 0.84), darken(skin, 0.72),
                      outline=(28, 16, 12, 255), w=4)
    # the belly ridge
    L.d.chord([Wc * 0.12, Hc * 0.42, Wc * 0.82, Hc * 0.94], 15, 165,
              fill=with_a(w["belly"]))
    # the top fin scallop (the teacher's leaf shape)
    L.d.polygon([(Wc * 0.18, Hc * 0.34), (Wc * 0.40, Hc * 0.04),
                 (Wc * 0.56, Hc * 0.28), (Wc * 0.74, Hc * 0.06),
                 (Wc * 0.82, Hc * 0.36)],
                fill=with_a(darken(fin, 0.9)), outline=(28, 16, 12, 255))
    # the bottom fin spur
    L.d.polygon([(Wc * 0.42, Hc * 0.86), (Wc * 0.56, Hc * 1.02),
                 (Wc * 0.64, Hc * 0.84)],
                fill=with_a(darken(fin, 0.75)), outline=(28, 16, 12, 255))
    im = outline_im(L.im, (24, 12, 10, 255), 3)
    grain(im, w["id"] + "-body")
    return im.crop(im.getbbox())


def worm_tail(w):
    Wc, Hc = 150, 110
    L = Layer(Wc, Hc)
    skin, fin = w["skin"], w["fin"]
    # tapered spike riding right
    pts = [(Wc * 0.06, Hc * 0.62), (Wc * 0.42, Hc * 0.22),
           (Wc * 0.62, Hc * 0.30), (Wc * 0.96, Hc * 0.50),
           (Wc * 0.60, Hc * 0.70), (Wc * 0.40, Hc * 0.80)]
    L.d.polygon(pts, fill=with_a(darken(skin, 0.85)),
                outline=(28, 16, 12, 255))
    L.d.polygon([(Wc * 0.10, Hc * 0.60), (Wc * 0.40, Hc * 0.30),
                 (Wc * 0.52, Hc * 0.44), (Wc * 0.30, Hc * 0.66)],
                fill=with_a(w["fin"]))
    im = outline_im(L.im, (24, 12, 10, 255), 3)
    grain(im, w["id"] + "-tail")
    return im.crop(im.getbbox())


def worm_preview(w):
    """the worms-menu portrait: head + two segments composed"""
    head = worm_head(w, False)
    body = worm_body(w)
    tail = worm_tail(w)
    Wc, Hc = 300, 190
    L = Layer(Wc, Hc)
    sc = 0.62
    b2 = body.resize((int(body.width * sc), int(body.height * sc)))
    t2 = tail.resize((int(tail.width * sc), int(tail.height * sc)))
    h2 = head.resize((int(head.width * 0.78), int(head.height * 0.78)))
    L.im.alpha_composite(t2, (8, Hc - t2.height - 42))
    L.im.alpha_composite(b2, (t2.width - 26, Hc - b2.height - 52))
    L.im.alpha_composite(h2, (t2.width + b2.width - 62, Hc - h2.height - 16))
    return L.im.crop(L.im.getbbox())


# ================================================================ THE HUMANS
# the teacher's runners: small folk in clothes variants, a 10-frame run.
# ours: 8 skins - the desert folk, the casuals, the jungle pair, the punk,
# the woman - each with its own palette + hair/hat identity.
HUMANS = [
    {"skin": "arab",   "robe": (232, 214, 172), "head": (224, 172, 132),
     "hair": (250, 246, 232), "pants": (214, 196, 158)},
    {"skin": "casual1", "robe": (74, 130, 200), "head": (236, 186, 148),
     "hair": (70, 48, 30), "pants": (52, 60, 90)},
    {"skin": "casual2", "robe": (196, 84, 70), "head": (240, 196, 156),
     "hair": (40, 34, 30), "pants": (60, 54, 66)},
    {"skin": "casual3", "robe": (232, 168, 52), "head": (220, 168, 126),
     "hair": (110, 76, 40), "pants": (86, 64, 44)},
    {"skin": "jungle1", "robe": (86, 150, 84), "head": (198, 148, 108),
     "hair": (30, 26, 22), "pants": (56, 92, 54)},
    {"skin": "jungle2", "robe": (150, 110, 78), "head": (206, 152, 112),
     "hair": (52, 36, 24), "pants": (94, 70, 48)},
    {"skin": "punk",   "robe": (52, 48, 56), "head": (238, 190, 150),
     "hair": (200, 60, 120), "pants": (36, 32, 40)},
    {"skin": "woman",  "robe": (208, 96, 150), "head": (242, 198, 160),
     "hair": (140, 84, 40), "pants": (160, 70, 110)},
    {"skin": "soldier", "robe": (96, 116, 74), "head": (222, 174, 134),
     "hair": (70, 92, 56), "pants": (72, 86, 58)},
    {"skin": "bazooka", "robe": (110, 122, 84), "head": (216, 168, 128),
     "hair": (52, 66, 44), "pants": (78, 90, 62)},
    {"skin": "police", "robe": (52, 64, 130), "head": (232, 184, 144),
     "hair": (38, 44, 70), "pants": (34, 40, 78)},
    {"skin": "polar1", "robe": (188, 158, 116), "head": (228, 180, 142),
     "hair": (120, 96, 70), "pants": (140, 116, 84)},
    {"skin": "polar2", "robe": (176, 70, 58), "head": (234, 188, 148),
     "hair": (60, 44, 34), "pants": (120, 52, 44)},
]

HW, HH = 96, 116


def human_frame(c, i):
    """a 10-frame run cycle facing LEFT: lean body, pumping arms,
    swinging legs - the teacher's little runners"""
    r = rng_for("human-" + c["skin"])
    L = Layer(HW, HH)
    ph = math.tau * i / 10.0
    swing = math.sin(ph)
    lift = max(0.0, math.cos(ph))
    head_y = 30 - lift * 2.0
    cx = HW * 0.52
    lean = -6.0
    dark = darken(c["robe"], 0.66)
    # the back leg (darker)
    bk = [(cx + lean + swing * 12.0, 74), (cx + lean + swing * 20.0, 96),
          (cx + lean + swing * 16.0, 104)]
    L.d.line([(cx + lean + 2, 70), bk[0], bk[1]],
             fill=with_a(darken(c["pants"], 0.7)), width=9)
    L.d.ellipse([bk[1][0] - 7, 100, bk[1][0] + 7, 110],
                fill=with_a(darken(c["robe"], 0.5)))
    # the front leg
    ft = [(cx - swing * 14.0, 72), (cx - swing * 24.0, 92),
          (cx - swing * 20.0, 102)]
    L.d.line([(cx + 2, 70), ft[0], ft[1]],
             fill=with_a(c["pants"]), width=10)
    L.d.ellipse([ft[1][0] - 8, 98, ft[1][0] + 8, 108],
                fill=with_a(darken(c["robe"], 0.62)))
    # the torso (a leaning robe)
    torso = [(cx - 12 + lean * 0.4, 34 + lift * 2), (cx + 12 + lean * 0.4, 34 + lift * 2),
             (cx + 15, 72), (cx - 15, 72)]
    L.d.polygon(torso, fill=with_a(c["robe"]))
    L.d.polygon([(cx - 12 + lean * 0.4, 34), (cx - 2, 34), (cx + 1, 72),
                 (cx - 15, 72)], fill=with_a(lighten(c["robe"], 0.86)))
    L.d.polygon(torso, outline=(30, 20, 16, 255), width=3)
    # the back arm
    L.d.line([(cx + 4 + lean * 0.5, 42), (cx + 14 + swing * 10.0, 56),
              (cx + 16 + swing * 16.0, 66)],
             fill=with_a(dark), width=7)
    # the head
    draw_grad_ellipse(L.d, cx + lean, head_y, 13, 13,
                      lighten(c["head"], 0.9), c["head"],
                      outline=(30, 20, 16, 255), w=3)
    # the hair/hat identity
    if c["skin"] in ("soldier", "bazooka"):
        L.d.pieslice([cx + lean - 15, head_y - 14, cx + lean + 15, head_y + 10],
                     180, 360, fill=with_a(c["hair"]))
        L.d.rectangle([cx + lean - 16, head_y - 4, cx + lean + 16, head_y - 1],
                      fill=with_a(darken(c["hair"], 0.8)))
    elif c["skin"] == "police":
        L.d.pieslice([cx + lean - 15, head_y - 12, cx + lean + 15, head_y + 8],
                     180, 360, fill=with_a((40, 52, 100)))
        L.d.rectangle([cx + lean - 8, head_y - 14, cx + lean + 2, head_y - 10],
                      fill=with_a((30, 38, 80)))
    elif c["skin"] in ("polar1", "polar2"):
        L.d.pieslice([cx + lean - 16, head_y - 16, cx + lean + 16, head_y + 6],
                     170, 380, fill=with_a(lighten(c["robe"], 0.6)))
    if c["skin"] == "bazooka":
        # the tube rides the shoulder
        L.d.line([(cx - 2 + lean * 0.4, 40), (cx - 30 + lean * 0.4, 34)],
                 fill=(96, 104, 78, 255), width=8)
    if c["skin"] == "arab":
        L.d.pieslice([cx + lean - 15, head_y - 16, cx + lean + 15, head_y + 12],
                     180, 360, fill=with_a(c["hair"]))
    elif c["skin"] == "punk":
        L.d.polygon([(cx + lean - 14, head_y - 6), (cx + lean + 2, head_y - 26),
                     (cx + lean + 12, head_y - 4)], fill=with_a(c["hair"]))
    elif c["skin"] == "woman":
        L.d.pieslice([cx + lean - 16, head_y - 18, cx + lean + 16, head_y + 8],
                     160, 380, fill=with_a(c["hair"]))
        L.d.line([(cx + lean - 14, head_y + 2), (cx + lean - 20, head_y + 18)],
                 fill=with_a(c["hair"]), width=6)
    else:
        L.d.pieslice([cx + lean - 14, head_y - 16, cx + lean + 14, head_y + 6],
                     190, 355, fill=with_a(c["hair"]))
    # the face dot (the eye)
    L.d.ellipse([cx + lean - 8, head_y - 3, cx + lean - 4, head_y + 1],
                fill=(30, 20, 16, 255))
    # the front arm (pumps opposite the legs)
    L.d.line([(cx + 2 + lean * 0.5, 44), (cx - 8 - swing * 10.0, 58),
              (cx - 12 - swing * 16.0, 68)],
             fill=with_a(c["head"]), width=7)
    im = outline_im(L.im, (26, 16, 12, 255), 2)
    return im.crop(im.getbbox())


# =============================================================== THE ANIMALS
# the teacher's roster: camel, tiger, puma, polar bear, penguin, mole,
# lizard, yeti - painterly side-view walkers, facing LEFT.
def _quad(L, body_box, leg_ph, cols, leg_len, leg_w, tail_fn=None):
    """a four-legged walker: body ellipse + 4 swinging legs"""
    bx, by, rx, ry = body_box
    top, bot, leg = cols
    draw_grad_ellipse(L.d, bx, by, rx, ry, top, bot,
                      outline=(30, 20, 16, 255), w=4)
    for i, phase in enumerate((-0.9, 0.9, 2.2, -2.2)):
        lx = bx + (rx - 6) * (1 if i % 2 else -1) * 0.72
        sw = math.sin(leg_ph + phase) * 8.0
        up = max(0.0, math.cos(leg_ph + phase)) * 5.0
        L.d.line([(lx, by + ry * 0.5),
                  (lx + sw * 0.6, by + ry * 0.5 + leg_len * 0.5 - up),
                  (lx + sw, by + ry * 0.5 + leg_len - up)],
                 fill=with_a(darken(leg, 0.8)), width=leg_w)
        L.d.ellipse([lx + sw - leg_w * 0.7, by + ry * 0.5 + leg_len - up - leg_w * 0.5,
                     lx + sw + leg_w * 0.7, by + ry * 0.5 + leg_len - up + leg_w * 0.5],
                    fill=with_a(darken(leg, 0.6)))
    if tail_fn is not None:
        tail_fn(L, bx, by, rx, ry)


ANIMALS = ["camel", "tiger", "puma", "bear", "penguin", "yeti"]
ANIM_FRAMES = {"camel": 5, "tiger": 3, "puma": 3, "bear": 7, "penguin": 6,
               "yeti": 6}


def animal_frame(kind, i):
    n = ANIM_FRAMES[kind]
    ph = math.tau * i / n
    r = rng_for("animal-" + kind)
    if kind == "camel":
        L = Layer(150, 110)
        _quad(L, (72, 44, 40, 24), ph,
              ((206, 158, 96), (172, 124, 66), (150, 106, 54)), 34, 9,
              tail_fn=lambda L, bx, by, rx, ry: L.d.line(
                  [(bx + rx - 4, by - 4), (bx + rx + 14, by - 14)],
                  fill=(150, 106, 54, 255), width=6))
        # the humps + the long neck + the head
        draw_grad_ellipse(L.d, 58, 24, 18, 13, (222, 178, 112),
                          (190, 142, 82), outline=(30, 20, 16, 255), w=3)
        draw_grad_ellipse(L.d, 88, 26, 16, 12, (226, 182, 116),
                          (192, 146, 86), outline=(30, 20, 16, 255), w=3)
        L.d.line([(40, 40), (26, 18), (18, 14)], fill=(190, 142, 82, 255),
                 width=11)
        draw_grad_ellipse(L.d, 16, 14, 12, 8, (216, 170, 106), (180, 134, 74),
                          outline=(30, 20, 16, 255), w=3)
        L.d.ellipse([8, 10, 13, 15], fill=(30, 20, 16, 255))
        L.d.polygon([(12, 6), (8, -2), (18, 4)], fill=(146, 102, 52, 255))
    elif kind in ("tiger", "puma"):
        col = ((236, 150, 54), (196, 108, 34), (160, 90, 28)) if kind == "tiger" \
                else ((70, 66, 68), (48, 44, 48), (34, 32, 36))
        L = Layer(150, 96)
        _quad(L, (70, 46, 44, 20), ph, col, 26, 8,
              tail_fn=lambda L, bx, by, rx, ry: L.d.line(
                  [(bx - rx + 6, by - 6), (bx - rx - 26, by - 24 + math.sin(ph) * 4)],
                  fill=col[2] + (255,), width=7))
        L.d.line([(36, 34), (22, 24)], fill=col[0] + (255,), width=12)
        draw_grad_ellipse(L.d, 18, 22, 14, 10, lighten(col[0], 0.85), col[1],
                          outline=(30, 20, 16, 255), w=3)
        L.d.polygon([(8, 16), (4, 4), (14, 10)], fill=col[2] + (255,))
        L.d.polygon([(22, 12), (20, 2), (28, 8)], fill=col[2] + (255,))
        L.d.ellipse([8, 18, 13, 23], fill=(250, 240, 120, 255))
        if kind == "tiger":
            for s in range(4):
                L.d.line([(44 + s * 16, 34 + (s % 2) * 8),
                          (54 + s * 16, 50 + (s % 2) * 6)],
                         fill=(40, 26, 18, 255), width=3)
    elif kind == "bear":
        L = Layer(170, 110)
        _quad(L, (82, 48, 52, 26), ph,
              ((244, 240, 230), (216, 210, 196), (196, 188, 172)), 30, 12,
              tail_fn=lambda L, bx, by, rx, ry: draw_ellipse(
                  L.d, bx - rx + 4, by - 8, 10, 8, (226, 220, 206, 255),
                  outline=(30, 20, 16, 255), width=3))
        L.d.line([(48, 40), (34, 26)], fill=(234, 230, 218, 255), width=16)
        draw_grad_ellipse(L.d, 28, 24, 16, 12, (250, 246, 236), (222, 216, 202),
                          outline=(30, 20, 16, 255), w=3)
        L.d.ellipse([16, 20, 21, 25], fill=(30, 20, 16, 255))
        L.d.ellipse([20, 30, 34, 38], fill=(210, 200, 182, 255))
        L.d.polygon([(14, 16), (10, 4), (22, 12)], fill=(226, 220, 206, 255))
    elif kind == "penguin":
        L = Layer(90, 110)
        bob = math.sin(ph) * 2.5
        draw_grad_ellipse(L.d, 46, 52 + bob, 24, 34, (40, 46, 58), (24, 28, 38),
                          outline=(30, 20, 16, 255), w=4)
        L.d.polygon([(30, 44 + bob), (46, 84 + bob), (62, 44 + bob)],
                    fill=(238, 240, 236, 255))
        L.d.ellipse([28, 18 + bob, 64, 46 + bob], fill=(30, 34, 44, 255),
                    outline=(30, 20, 16, 255), width=3)
        L.d.polygon([(34, 30 + bob), (20, 34 + bob), (34, 38 + bob)],
                    fill=(240, 170, 60, 255))
        L.d.ellipse([38, 24 + bob, 44, 30 + bob], fill=(250, 250, 250, 255))
        L.d.ellipse([40, 26 + bob, 44, 30 + bob], fill=(20, 20, 20, 255))
        for s, sgn in ((0, -1), (1, 1)):
            fl = math.sin(ph + s * math.pi) * 8.0
            L.d.ellipse([46 + sgn * 26 - 5 + fl, 46 + bob, 51 + sgn * 26 + fl, 70 + bob],
                        fill=(28, 32, 42, 255))
        for s in range(2):
            lx = 40 + s * 12
            sw = math.sin(ph + s * math.pi) * 6.0
            L.d.line([(lx, 84 + bob), (lx + sw, 100 + bob)],
                     fill=(240, 170, 60, 255), width=6)
    elif kind == "yeti":
        L = Layer(120, 120)
        bob = math.sin(ph) * 2.0
        draw_grad_ellipse(L.d, 60, 62 + bob, 30, 36, (238, 240, 244),
                          (196, 202, 214), outline=(30, 20, 16, 255), w=4)
        draw_grad_ellipse(L.d, 60, 26 + bob, 20, 16, (246, 248, 250),
                          (210, 214, 222), outline=(30, 20, 16, 255), w=3)
        L.d.ellipse([50, 22 + bob, 58, 30 + bob], fill=(40, 40, 50, 255))
        L.d.ellipse([64, 22 + bob, 72, 30 + bob], fill=(40, 40, 50, 255))
        L.d.ellipse([56, 34 + bob, 66, 42 + bob], fill=(90, 70, 70, 255))
        # the long arms swing
        for s, sgn in ((0, -1), (1, 1)):
            sw = math.sin(ph + s * math.pi) * 10.0
            L.d.line([(60 + sgn * 26, 44 + bob), (60 + sgn * 32 + sw, 76 + bob),
                      (60 + sgn * 30 + sw * 1.2, 92 + bob)],
                     fill=(216, 220, 230, 255), width=12)
        for s in range(2):
            lx = 50 + s * 20
            sw = math.sin(ph + s * math.pi) * 7.0
            L.d.line([(lx, 92 + bob), (lx + sw, 112 + bob)],
                     fill=(200, 206, 218, 255), width=12)
    im = outline_im(L.im, (26, 16, 12, 255), 3)
    grain(im, kind + str(i))
    return im.crop(im.getbbox())


GROUND_ANIMALS = {"lizard": 6, "mole": 4}


def ground_frame(kind, i):
    n = GROUND_ANIMALS[kind]
    ph = math.tau * i / n
    if kind == "lizard":
        L = Layer(110, 70)
        wob = math.sin(ph * 2) * 3.0
        draw_grad_ellipse(L.d, 58, 36 + wob * 0.3, 34, 13,
                          (120, 190, 80), (70, 130, 52),
                          outline=(30, 20, 16, 255), w=3)
        L.d.line([(28, 34), (10, 26 + wob)], fill=(96, 156, 66, 255), width=4)
        draw_grad_ellipse(L.d, 96, 30, 12, 8, (140, 206, 96), (84, 142, 60),
                          outline=(30, 20, 16, 255), w=3)
        L.d.ellipse([100, 26, 104, 30], fill=(250, 220, 70, 255))
        for s in range(4):
            lx = 44 + s * 14
            sw = math.sin(ph + s * math.pi * 0.9) * 5.0
            L.d.line([(lx, 44), (lx + sw, 58 + (s % 2) * 3)],
                     fill=(70, 126, 52, 255), width=5)
    else:  # mole
        L = Layer(90, 66)
        waddle = math.sin(ph) * 2.0
        draw_grad_ellipse(L.d, 46, 36 + waddle, 26, 18,
                          (72, 62, 58), (44, 38, 36),
                          outline=(30, 20, 16, 255), w=3)
        draw_grad_ellipse(L.d, 74, 30 + waddle, 12, 10,
                          (86, 74, 68), (54, 46, 42),
                          outline=(30, 20, 16, 255), w=3)
        L.d.ellipse([80, 26 + waddle, 85, 31 + waddle],
                    fill=(250, 210, 90, 255))
        L.d.polygon([(60, 18 + waddle), (66, 6 + waddle), (72, 18 + waddle)],
                    fill=(60, 50, 46, 255))
        for s in range(2):
            lx = 36 + s * 18
            sw = math.sin(ph + s * math.pi) * 5.0
            L.d.line([(lx, 50 + waddle), (lx + sw, 60 + waddle)],
                     fill=(44, 38, 36, 255), width=6)
    im = outline_im(L.im, (26, 16, 12, 255), 2)
    return im.crop(im.getbbox())


# =============================================================== THE MACHINES
# the teacher's war on wheels: chunky side-view machines (facing LEFT),
# rotors/props/legs animate by frame.
def _wheels(L, seats, r, ph, col=(36, 34, 38), hub=(150, 150, 158)):
    for sx, sy in seats:
        rot = ph * 2.0
        L.d.ellipse([sx - r, sy - r, sx + r, sy + r], fill=col + (255,),
                    outline=(20, 16, 18, 255), width=3)
        for k in range(4):
            a = rot + math.tau * k / 4
            L.d.line([(sx - math.cos(a) * r * 0.7, sy - math.sin(a) * r * 0.7),
                      (sx + math.cos(a) * r * 0.7, sy + math.sin(a) * r * 0.7)],
                     fill=hub + (255,), width=2)


VEHICLES = {
    "bird": 8,
    "car": 5, "police_car": 3, "truck": 2, "dozer": 3, "tank": 3, "btr": 9,
    "mech": 21, "heli": 12, "heli_assault": 4, "jet": 13, "plane": 12,
    "ufo": 5, "ufojet": 41,
}


def vehicle_frame(kind, i):
    n = VEHICLES[kind]
    ph = math.tau * i / n
    r = rng_for("veh-" + kind)
    if kind == "bird":
        # the snack-flyer: 8 flap frames (wings up -> down), LEFT-native
        L = Layer(90, 70)
        flap = math.sin(ph)
        L.d.ellipse([40, 38, 58, 54], fill=(52, 50, 56, 255))
        L.d.ellipse([36, 34, 50, 46], fill=(64, 60, 68, 255))
        L.d.polygon([(38, 38), (30, 34), (36, 44)], fill=(240, 170, 60, 255))
        L.d.ellipse([36, 36, 41, 41], fill=(250, 230, 120, 255))
        wy = 36 - flap * 14.0
        L.d.polygon([(46, 38), (70, wy), (58, 44)], fill=(70, 66, 76, 255))
        L.d.polygon([(44, 44), (68, 58 + flap * 10.0), (54, 50)],
                    fill=(56, 52, 62, 255))
        L.d.polygon([(42, 48), (34, 60), (48, 52)], fill=(52, 50, 56, 255))
    elif kind == "car":
        L = Layer(150, 90)
        vgrad(L.d, (20, 40, 132, 62), (200, 70, 60), (150, 44, 40))
        L.d.polygon([(20, 46), (44, 16), (96, 14), (126, 44)],
                    fill=(214, 84, 70, 255), outline=(30, 20, 16, 255))
        L.d.polygon([(50, 20), (88, 19), (104, 42), (42, 43)],
                    fill=(150, 200, 230, 255), outline=(30, 20, 16, 255))
        L.d.polygon([(20, 40), (132, 40), (132, 62), (20, 62)],
                    outline=(30, 20, 16, 255))
        _wheels(L, [(46, 64), (106, 64)], 14, ph)
    elif kind == "police_car":
        L = Layer(150, 90)
        vgrad(L.d, (20, 44, 132, 62), (60, 70, 160), (36, 42, 110))
        L.d.polygon([(20, 48), (44, 20), (96, 18), (126, 46)],
                    fill=(70, 82, 170, 255), outline=(30, 20, 16, 255))
        L.d.polygon([(50, 24), (88, 23), (104, 44), (42, 45)],
                    fill=(160, 190, 225, 255), outline=(30, 20, 16, 255))
        L.d.rectangle([(58, 8), (92, 20)], fill=(230, 230, 236, 255))
        flash = (255, 80, 60) if i % 2 == 0 else (80, 120, 255)
        L.d.ellipse([64, 4, 76, 12], fill=flash + (255,))
        _wheels(L, [(46, 64), (106, 64)], 14, ph)
    elif kind == "truck":
        L = Layer(180, 100)
        vgrad(L.d, (16, 40, 120, 70), (90, 110, 130), (60, 76, 94))
        L.d.rectangle([(110, 14), (166, 44)], fill=(120, 140, 160, 255),
                      outline=(30, 20, 16, 255))
        L.d.polygon([(96, 26), (122, 26), (122, 52), (96, 52)],
                    fill=(140, 160, 178, 255), outline=(30, 20, 16, 255))
        L.d.rectangle([(16, 40), (120, 70)], outline=(30, 20, 16, 255))
        _wheels(L, [(40, 74), (70, 74), (130, 74)], 15, ph)
    elif kind == "dozer":
        L = Layer(160, 100)
        vgrad(L.d, (28, 44, 120, 72), (222, 150, 54), (170, 108, 34))
        L.d.rounded_rectangle([(26, 48), (118, 80)], radius=12,
                              fill=(60, 56, 54, 255),
                              outline=(20, 16, 18, 255))
        for k in range(5):
            off = (ph * 30 + k * 12) % 60
            L.d.line([(30 + off, 52), (30 + off, 76)],
                     fill=(96, 92, 90, 255), width=3)
        L.d.rectangle([(40, 20), (96, 48)], fill=(228, 158, 60, 255),
                      outline=(30, 20, 16, 255))
        L.d.polygon([(8, 56), (30, 44), (30, 72), (8, 66)],
                    fill=(150, 150, 156, 255), outline=(30, 20, 16, 255))
        L.d.line([(104, 30), (140, 20)], fill=(120, 118, 122, 255), width=8)
    elif kind == "tank":
        L = Layer(180, 100)
        tread_y = 66
        L.d.rounded_rectangle([(22, tread_y - 14), (150, tread_y + 12)],
                              radius=14, fill=(52, 52, 50, 255),
                              outline=(20, 16, 18, 255))
        for k in range(7):
            off = (ph * 36 + k * 20) % 128
            L.d.line([(24 + off, tread_y - 8), (24 + off, tread_y + 6)],
                     fill=(96, 94, 88, 255), width=3)
        vgrad(L.d, (36, 36, 128, 60), (110, 128, 88), (76, 92, 60))
        L.d.polygon([(120, 40), (146, 32), (146, 52), (120, 54)],
                    fill=(96, 112, 76, 255), outline=(30, 20, 16, 255))
        L.d.ellipse([58, 32, 92, 58], fill=(104, 120, 82, 255),
                    outline=(30, 20, 16, 255), width=3)
        L.d.line([(80, 44), (12, 36)], fill=(70, 84, 56, 255), width=9)
    elif kind == "btr":
        L = Layer(200, 100)
        vgrad(L.d, (22, 40, 176, 68), (128, 138, 108), (88, 98, 72))
        L.d.polygon([(22, 62), (52, 38), (150, 36), (176, 60), (176, 68), (22, 68)],
                    fill=(132, 142, 112, 255), outline=(30, 20, 16, 255))
        L.d.polygon([(76, 38), (104, 26), (120, 38)],
                    fill=(112, 122, 94, 255), outline=(30, 20, 16, 255))
        L.d.line([(112, 32), (52, 26)], fill=(70, 80, 58, 255), width=6)
        _wheels(L, [(48, 72), (82, 72), (116, 72), (150, 72)], 13, ph)
    elif kind == "mech":
        L = Layer(150, 160)
        bob = math.sin(ph) * 3.0
        # the legs (a 6-pose walk cycled over 21 frames)
        lp = math.tau * (i % 6) / 6.0
        for s, sgn in ((0, -1), (1, 1)):
            sw = math.sin(lp + s * math.pi) * 16.0
            L.d.line([(72 + sgn * 12, 96 + bob), (72 + sgn * 16 + sw, 122),
                      (72 + sgn * 12 + sw * 1.2, 146)],
                     fill=(96, 100, 112, 255), width=13)
            L.d.ellipse([64 + sgn * 12 + sw * 1.2 - 12, 138,
                         88 + sgn * 12 + sw * 1.2, 154],
                        fill=(72, 76, 86, 255), outline=(20, 16, 18, 255))
        # the hull
        vgrad(L.d, (40, 44 + bob, 112, 100 + bob), (196, 158, 60),
              (140, 106, 36))
        L.d.rounded_rectangle([(40, 44 + bob), (112, 100 + bob)], radius=12,
                              fill=(188, 150, 58, 255),
                              outline=(30, 20, 16, 255))
        L.d.rectangle([(52, 58 + bob), (100, 66 + bob)],
                      fill=(226, 190, 90, 255))
        # the cockpit + the arm cannon
        L.d.ellipse([56, 24 + bob, 96, 52 + bob], fill=(90, 96, 110, 255),
                    outline=(30, 20, 16, 255), width=3)
        L.d.ellipse([66, 30 + bob, 86, 46 + bob], fill=(120, 220, 250, 255))
        L.d.line([(48, 70 + bob), (10, 62 + bob)], fill=(110, 114, 124, 255),
                 width=11)
        glow = 0.5 + 0.5 * math.sin(ph * 2)
        L.d.ellipse([2, 56 + bob, 16, 70 + bob],
                    fill=(255, int(160 + 60 * glow), 60, 255))
    elif kind in ("heli", "heli_assault"):
        L = Layer(180, 130)
        body_col = (110, 140, 160) if kind == "heli" else (96, 110, 96)
        bob = math.sin(ph * 2) * 3.0
        draw_grad_ellipse(L.d, 84, 62 + bob, 52, 24, lighten(body_col, 0.85),
                          darken(body_col, 0.8), outline=(30, 20, 16, 255), w=4)
        L.d.polygon([(126, 56 + bob), (168, 50 + bob), (168, 60 + bob),
                     (126, 68 + bob)], fill=darken(body_col, 0.85) + (255,),
                    outline=(30, 20, 16, 255))
        L.d.ellipse([(46, 52 + bob), (86, 76 + bob)], fill=(170, 210, 230, 255),
                    outline=(30, 20, 16, 255), width=3)
        L.d.line([(140, 46 + bob), (140, 74 + bob)], fill=(90, 90, 96, 255),
                 width=4)
        # the rotor: angles sweep across the frame count
        ra = ph * 2.0
        cy2 = 30 + bob
        L.d.line([(84, cy2), (84, 44 + bob)], fill=(80, 80, 86, 255), width=5)
        for k in range(3):
            a = ra + math.tau * k / 3
            L.d.line([(84 - math.cos(a) * 66, cy2 - math.sin(a) * 7),
                      (84 + math.cos(a) * 66, cy2 + math.sin(a) * 7)],
                     fill=(70, 70, 78, 220), width=5)
        if kind == "heli_assault":
            L.d.line([(60, 88 + bob), (48, 104 + bob)],
                     fill=(70, 76, 66, 255), width=6)
            L.d.ellipse([40, 100 + bob, 56, 112 + bob],
                        fill=(50, 54, 48, 255))
    elif kind == "jet":
        L = Layer(190, 90)
        burn = 0.5 + 0.5 * math.sin(ph * 3)
        L.d.polygon([(12, 44), (60, 30), (150, 34), (178, 44), (150, 56),
                     (60, 58)], fill=(88, 100, 122, 255),
                    outline=(30, 20, 16, 255))
        L.d.polygon([(60, 34), (36, 12), (74, 30)], fill=(70, 80, 100, 255),
                    outline=(30, 20, 16, 255))
        L.d.polygon([(70, 56), (52, 78), (92, 58)], fill=(70, 80, 100, 255),
                    outline=(30, 20, 16, 255))
        L.d.ellipse([(118, 36), (140, 52)], fill=(150, 200, 230, 255),
                    outline=(30, 20, 16, 255), width=2)
        L.d.polygon([(178, 40), (188 + burn * 14, 44), (178, 48)],
                    fill=(255, int(170 + 60 * burn), 70, 230))
    elif kind == "plane":
        L = Layer(190, 100)
        L.d.polygon([(14, 54), (54, 40), (158, 42), (180, 52), (156, 62),
                     (54, 64)], fill=(206, 200, 188, 255),
                    outline=(30, 20, 16, 255))
        L.d.polygon([(84, 42), (66, 10), (104, 40)], fill=(190, 184, 172, 255),
                    outline=(30, 20, 16, 255))
        L.d.polygon([(88, 62), (72, 90), (108, 64)], fill=(190, 184, 172, 255),
                    outline=(30, 20, 16, 255))
        L.d.polygon([(24, 52), (2, 44), (24, 60)], fill=(170, 164, 152, 255))
        L.d.polygon([(120, 44), (136, 40), (136, 60), (120, 62)],
                    fill=(150, 200, 230, 255))
        pa = ph * 2.5
        for k in range(3):
            a = pa + math.tau * k / 3
            L.d.line([(184 - math.cos(a) * 4, 52 - math.sin(a) * 26),
                      (184 + math.cos(a) * 4, 52 + math.sin(a) * 26)],
                     fill=(90, 88, 84, 210), width=4)
    elif kind == "ufo":
        L = Layer(150, 90)
        pulse = 0.5 + 0.5 * math.sin(ph * 2)
        L.d.ellipse([(35, 26), (115, 52)], fill=(150, 170, 200, 255),
                    outline=(30, 20, 16, 255), width=3)
        L.d.ellipse([(56, 12), (94, 34)], fill=(190, 220, 240, 255),
                    outline=(30, 20, 16, 255), width=3)
        glow_a = int(120 + 100 * pulse)
        L.d.ellipse([(28, 40), (122, 64)], fill=(120, 240, 220, glow_a))
        for k in range(5):
            lx = 44 + k * 15
            on = (i + k) % 2 == 0
            L.d.ellipse([(lx - 3, 50), (lx + 3, 58)],
                        fill=((255, 240, 130) if on else (110, 110, 90)) + (255,))
    else:  # ufojet - the saucer-fighter hybrid, 41 frames of thrust pulse
        L = Layer(170, 100)
        t = i / 41.0
        pulse = 0.5 + 0.5 * math.sin(ph * 4)
        L.d.polygon([(16, 52), (52, 34), (120, 32), (156, 50), (120, 64),
                     (52, 66)], fill=(120, 130, 160, 255),
                    outline=(30, 20, 16, 255))
        L.d.ellipse([(64, 20), (104, 42)], fill=(170, 230, 250, 255),
                    outline=(30, 20, 16, 255), width=3)
        L.d.ellipse([(28, 42), (142, 62)], fill=(110, 240, 220, int(90 + 110 * pulse)))
        for k in range(3):
            ex = 150 + k * 4
            ea = int(150 + 90 * pulse) - k * 40
            L.d.polygon([(150, 46 - k * 2), (ex + 12 + pulse * 8, 50),
                         (150, 56 + k * 2)],
                        fill=(140, 240, 255, max(40, ea)))
    im = outline_im(L.im, (26, 16, 12, 255), 3)
    if kind in ("jet", "plane", "ufojet"):
        im = im.transpose(Image.FLIP_LEFT_RIGHT)   # LEFT-native, the law
    grain(im, kind + str(i))
    return im.crop(im.getbbox())


# ================================================================== THE SHOTS
SHOTS = {"bullet": 2, "drone_ball": 3, "rocket": 2, "tank_bullet": 1,
         "ufo_ball": 2}


def shot_frame(kind, i):
    n = SHOTS[kind]
    ph = math.tau * i / n
    if kind == "bullet":
        L = Layer(34, 16)
        L.d.rounded_rectangle([(2, 4), (24, 12)], radius=4,
                              fill=(240, 200, 90, 255),
                              outline=(30, 20, 16, 255))
        L.d.polygon([(24, 4), (33, 8), (24, 12)], fill=(250, 226, 140, 255))
    elif kind == "tank_bullet":
        L = Layer(30, 22)
        L.d.ellipse([(3, 4), (24, 20)], fill=(80, 84, 92, 255),
                    outline=(20, 16, 18, 255), width=2)
        L.d.ellipse([(8, 7), (18, 14)], fill=(130, 134, 142, 255))
    elif kind == "rocket":
        L = Layer(44, 20)
        fl = 0.5 + 0.5 * math.sin(ph * 3)
        L.d.rounded_rectangle([(10, 6), (32, 14)], radius=4,
                              fill=(210, 90, 60, 255),
                              outline=(30, 20, 16, 255))
        L.d.polygon([(32, 6), (42, 10), (32, 14)], fill=(240, 130, 80, 255))
        L.d.polygon([(2, 8), (10, 4), (10, 16)],
                    fill=(255, int(180 + 60 * fl), 60, 230))
    else:  # the energy balls
        col = (140, 240, 140) if kind == "drone_ball" else (150, 200, 255)
        L = Layer(28, 28)
        pulse = 0.6 + 0.4 * math.sin(ph)
        L.d.ellipse([(4, 4), (24, 24)], fill=col + (90,))
        L.d.ellipse([(7, 7), (21, 21)], fill=col + (255,))
        L.d.ellipse([(10, 9), (16, 14)], fill=(250, 250, 250, 230))
        if pulse > 0.85:
            L.d.ellipse([(1, 1), (27, 27)], outline=col + (140,), width=2)
    return L.im.crop(L.im.getbbox())


# ============================================================= THE EXPLOSIONS
def expl_frame(i):
    """24 frames: the core flashes white-hot, eats into orange smoke,
    then the ring and the ash fly"""
    n = 24
    t = i / (n - 1)
    S = 190
    L = Layer(S, S)
    cx, cy = S / 2, S / 2
    r0 = 12 + 70 * min(1.0, t * 2.2)
    r = r0 * (1.0 + 0.3 * max(0.0, t - 0.5))
    # the fireball: 3 layered blobs with jitter
    rr = rng_for("expl-shape%d" % i)
    for layer_i, (rad_f, col, a) in enumerate((
            (1.00, (250, 240, 180), 235),
            (0.78, (250, 160, 60), 225),
            (0.55, (214, 84, 34), 210))):
        if t > 0.75 and layer_i == 0:
            continue
        fade = 1.0 if t < 0.6 else max(0.0, 1.0 - (t - 0.6) * 2.4)
        pts = ellipse_pts(cx, cy, r * rad_f * (0.9 + 0.2 * rr.random()),
                          r * rad_f * (0.9 + 0.2 * rr.random()), n=14)
        pts = [(px + rr.uniform(-5, 5) * (1 + t), py + rr.uniform(-5, 5) * (1 + t))
               for px, py in pts]
        L.d.polygon(pts, fill=with_a(darken(col, 1.0), int(a * fade)))
    # the smoke ring on the tail frames
    if t > 0.45:
        sa = max(0.0, (t - 0.45) * 1.4) * 160
        L.d.arc([cx - r * 1.3, cy - r * 1.3, cx + r * 1.3, cy + r * 1.3],
                0, 360, fill=(96, 84, 78, int(sa)), width=9)
    # the spark flecks
    sp = rng_for("expl-spark%d" % i)
    if t < 0.7:
        for _ in range(8):
            a = sp.uniform(0, math.tau)
            dd = r * (1.1 + sp.random() * 0.7)
            L.d.ellipse([cx + math.cos(a) * dd - 3, cy + math.sin(a) * dd - 3,
                         cx + math.cos(a) * dd + 3, cy + math.sin(a) * dd + 3],
                        fill=(255, 230, 140, 200))
    return L.im


# ================================================================= THE PLACES
# five worlds, the teacher's roster: DUNES, THE ICE, THE CITY, THE JUNGLE,
# THE KINGDOM. Each: sky (the big sky), far (the parallax skyline),
# dirt (the underground strata), road (the surface strip), the two bounds.
PLACES_DEF = [
    {"id": "desert", "sky": ((116, 190, 232), (238, 214, 160)),
     "far": (206, 168, 104), "dirt": ((168, 122, 68), (120, 84, 44)),
     "road": (222, 186, 116), "night": False, "sun": (255, 236, 170)},
    {"id": "polar", "sky": ((150, 196, 228), (222, 240, 248)),
     "far": (188, 216, 232), "dirt": ((150, 178, 196), (104, 128, 148)),
     "road": (236, 246, 250), "night": False, "sun": (255, 250, 230)},
    {"id": "city", "sky": ((250, 176, 118), (252, 224, 168)),
     "far": (120, 108, 128), "dirt": ((118, 106, 112), (76, 68, 74)),
     "road": (128, 122, 128), "night": False, "sun": (255, 214, 150)},
    {"id": "jungle", "sky": ((130, 208, 224), (214, 240, 202)),
     "far": (52, 122, 62), "dirt": ((122, 92, 58), (84, 62, 38)),
     "road": (96, 158, 76), "night": False, "sun": (250, 246, 210)},
    {"id": "medieval", "sky": ((96, 116, 190), (222, 190, 160)),
     "far": (108, 96, 120), "dirt": ((116, 96, 78), (78, 62, 48)),
     "road": (148, 128, 100), "night": False, "sun": (255, 232, 190)},
]

SKY_W, SKY_H = 960, 1350   # the world's real sky band (SURFACE_Y)
FAR_W, FAR_H = 1600, 480
DIRT_W, DIRT_H = 960, 420
ROAD_W, ROAD_H = 960, 70


def place_sky(p, i):
    r = rng_for("sky-" + p["id"])
    L = Layer(SKY_W, SKY_H)
    vgrad(L.d, (0, 0, SKY_W, SKY_H), p["sky"][0], p["sky"][1])
    # the sun with its bloom
    sx, sy = SKY_W * (0.68 + 0.1 * (i % 3)), SKY_H * 0.26
    for rad, a in ((150, 40), (95, 80), (56, 230)):
        L.d.ellipse([sx - rad, sy - rad, sx + rad, sy + rad],
                    fill=with_a(p["sun"], a))
    L.d.ellipse([sx - 34, sy - 34, sx + 34, sy + 34],
                fill=with_a(lighten(p["sun"], 0.95), 255))
    # the clouds
    for _ in range(7):
        cx, cy = r.uniform(0, SKY_W), r.uniform(30, SKY_H * 0.5)
        cw = r.uniform(60, 160)
        col = lighten(p["sky"][1], 0.86)
        for ox, oy, f in ((0, 0, 1.0), (-cw * 0.42, 6, 0.62),
                          (cw * 0.44, 5, 0.66), (cw * 0.12, -14, 0.55)):
            rr = cw * 0.30 * f
            L.d.ellipse([cx + ox - rr, cy + oy - rr * 0.7,
                         cx + ox + rr, cy + oy + rr * 0.7],
                        fill=with_a(col, 210))
    grain(L.im, "sky-" + p["id"], 6, 0.02)
    return L.im


def place_far(p, i):
    """the parallax skyline: each world its own grammar, 3 depth bands"""
    r = rng_for("far-" + p["id"])
    L = Layer(FAR_W, FAR_H)
    base = p["far"]
    vgrad(L.d, (0, 0, FAR_W, FAR_H), mix(p["sky"][1], base, 0.55),
          mix(base, (20, 16, 20), 0.25))
    ground_y = FAR_H - 40
    if p["id"] == "desert":
        for bi, (f, col) in enumerate(((1.0, mix(base, p["sky"][1], 0.5)),
                                       (0.8, mix(base, (30, 20, 14), 0.18)),
                                       (0.62, darken(base, 0.72)))):
            x = -r.uniform(0, 200)
            while x < FAR_W:
                w = r.uniform(120, 300) * f
                h = r.uniform(60, 170) * f
                L.d.polygon([(x, ground_y), (x + w * 0.18, ground_y - h),
                             (x + w * 0.5, ground_y - h * 1.12),
                             (x + w * 0.82, ground_y - h),
                             (x + w, ground_y)],
                            fill=with_a(col, 255))
                x += w * r.uniform(0.5, 0.8)
    elif p["id"] == "polar":
        for bi, f in enumerate((1.0, 0.8, 0.62)):
            col = mix(base, (240, 250, 255), 0.25 - bi * 0.12) \
                    if bi == 0 else darken(base, 1.0 - bi * 0.14)
            x = -r.uniform(0, 200)
            while x < FAR_W:
                w = r.uniform(150, 340) * f
                h = r.uniform(90, 220) * f
                L.d.polygon([(x, ground_y), (x + w * 0.5, ground_y - h),
                             (x + w, ground_y)], fill=with_a(col, 255))
                L.d.polygon([(x + w * 0.38, ground_y - h * 0.66),
                             (x + w * 0.5, ground_y - h),
                             (x + w * 0.6, ground_y - h * 0.66)],
                            fill=with_a(lighten(col, 0.8), 255))
                x += w * r.uniform(0.55, 0.85)
    elif p["id"] == "city":
        for bi, f in enumerate((1.0, 0.82, 0.66)):
            col = lighten(base, 0.9 - bi * 0.18)
            x = -r.uniform(0, 120)
            while x < FAR_W:
                w = r.uniform(70, 150) * f
                h = r.uniform(120, 300) * f
                L.d.rectangle([x, ground_y - h, x + w, ground_y],
                              fill=with_a(col, 255))
                # the lit windows
                for wy in range(int(ground_y - h) + 14, int(ground_y) - 10, 26):
                    for wx in range(int(x) + 8, int(x + w) - 8, 22):
                        if r.random() < 0.5:
                            L.d.rectangle([wx, wy, wx + 8, wy + 10],
                                          fill=with_a((250, 226, 150), 200))
                x += w + r.uniform(14, 40)
    elif p["id"] == "jungle":
        for bi, f in enumerate((1.0, 0.82, 0.64)):
            col = mix(base, (24, 60, 30), bi * 0.22)
            x = -r.uniform(0, 160)
            while x < FAR_W:
                w = r.uniform(90, 190) * f
                h = r.uniform(100, 230) * f
                L.d.polygon([(x, ground_y), (x + w * 0.5, ground_y - h),
                             (x + w, ground_y)], fill=with_a(col, 255))
                for k in range(3):
                    cx2 = x + w * (0.3 + 0.2 * k)
                    rr = w * 0.34
                    L.d.ellipse([cx2 - rr, ground_y - h - rr * 0.7,
                                 cx2 + rr, ground_y - h + rr * 0.5],
                                fill=with_a(mix(col, (30, 80, 34), 0.3), 255))
                x += w * r.uniform(0.6, 0.9)
    else:  # medieval
        for bi, f in enumerate((1.0, 0.82, 0.66)):
            col = mix(base, (44, 36, 56), bi * 0.2)
            x = -r.uniform(0, 160)
            while x < FAR_W:
                kind = r.random()
                if kind < 0.25:
                    # a tower with a flag
                    w, h = 46 * f, r.uniform(150, 240) * f
                    L.d.rectangle([x, ground_y - h, x + w, ground_y],
                                  fill=with_a(col, 255))
                    L.d.polygon([(x - 6, ground_y - h), (x + w / 2, ground_y - h - 34 * f),
                                 (x + w + 6, ground_y - h)],
                                fill=with_a(darken(col, 0.8), 255))
                    L.d.line([(x + w / 2, ground_y - h - 34 * f),
                              (x + w / 2, ground_y - h - 60 * f)],
                             fill=with_a((60, 48, 40), 255), width=3)
                    L.d.polygon([(x + w / 2, ground_y - h - 60 * f),
                                 (x + w / 2 + 26 * f, ground_y - h - 52 * f),
                                 (x + w / 2, ground_y - h - 44 * f)],
                                fill=with_a((200, 70, 60), 255))
                elif kind < 0.6:
                    # a hill with a wall
                    w, h = r.uniform(180, 300) * f, r.uniform(60, 120) * f
                    L.d.polygon([(x, ground_y), (x + w * 0.5, ground_y - h),
                                 (x + w, ground_y)], fill=with_a(col, 255))
                    L.d.rectangle([x + w * 0.2, ground_y - h * 0.8,
                                   x + w * 0.8, ground_y - h * 0.55],
                                  fill=with_a(darken(col, 0.82), 255))
                else:
                    w, h = r.uniform(120, 220) * f, r.uniform(40, 90) * f
                    L.d.polygon([(x, ground_y), (x + w * 0.5, ground_y - h),
                                 (x + w, ground_y)], fill=with_a(col, 255))
                x += w * r.uniform(0.5, 0.8)
    grain(L.im, "far-" + p["id"], 7, 0.02)
    return L.im


def place_dirt(p, i):
    """the underground: strata that darken with depth + buried bones"""
    r = rng_for("dirt-" + p["id"])
    L = Layer(DIRT_W, DIRT_H)
    top, bot = p["dirt"]
    vgrad(L.d, (0, 0, DIRT_W, DIRT_H), top, bot)
    # the strata bands
    y = 30
    while y < DIRT_H:
        band_h = r.uniform(24, 60)
        col = mix(top, bot, min(1.0, y / DIRT_H))
        L.d.line([(0, y), (DIRT_W, y)], fill=with_a(darken(col, 0.82), 130),
                 width=3)
        y += band_h
    # the stones + the roots/city pipes/snow chunks by theme
    for _ in range(60):
        x, yy = r.uniform(10, DIRT_W - 10), r.uniform(20, DIRT_H - 10)
        rr = r.uniform(4, 14)
        col = darken(mix(top, bot, yy / DIRT_H), 0.7)
        L.d.ellipse([x - rr, yy - rr * 0.7, x + rr, yy + rr * 0.7],
                    fill=with_a(col, 200), outline=with_a(darken(col, 0.7), 120))
    if p["id"] == "jungle":
        for _ in range(10):
            x = r.uniform(0, DIRT_W)
            L.d.line([(x, 0), (x + r.uniform(-60, 60), DIRT_H)],
                     fill=with_a((90, 66, 38), 150), width=r.randint(4, 9))
    if p["id"] == "city":
        for _ in range(8):
            yy = r.uniform(40, DIRT_H - 20)
            L.d.line([(0, yy), (DIRT_W, yy)],
                     fill=with_a((150, 150, 160), 130), width=6)
    grain(L.im, "dirt-" + p["id"], 9, 0.03)
    return L.im


def place_road(p, i):
    """the surface strip the world walks on"""
    r = rng_for("road-" + p["id"])
    L = Layer(ROAD_W, ROAD_H)
    base = p["road"]
    vgrad(L.d, (0, 0, ROAD_W, ROAD_H), lighten(base, 0.9), darken(base, 0.82))
    L.d.line([(0, 4), (ROAD_W, 4)], fill=with_a(lighten(base, 0.96), 255),
             width=5)
    if p["id"] == "city":
        for x in range(0, ROAD_W, 90):
            L.d.rectangle([x + 20, ROAD_H * 0.45, x + 66, ROAD_H * 0.55],
                          fill=with_a((240, 232, 190), 170))
    else:
        for _ in range(70):
            x, yy = r.uniform(0, ROAD_W), r.uniform(10, ROAD_H - 8)
            col = mix(base, (40, 80, 40) if p["id"] in ("jungle", "medieval")
                      else (150, 120, 70), 0.4)
            L.d.ellipse([x - 3, yy - 2, x + 3, yy + 2],
                        fill=with_a(col, 160))
    grain(L.im, "road-" + p["id"], 6, 0.02)
    return L.im


def place_bounds(p, side):
    """the world's edge cliff (left/right)"""
    r = rng_for("bound-" + p["id"] + side)
    Wc, Hc = 120, 700
    L = Layer(Wc, Hc)
    top, bot = p["dirt"]
    if side == "l":
        pts = [(0, 0), (70, 0), (96, 90), (58, 210), (104, 330),
               (66, 470), (98, 600), (60, Hc), (0, Hc)]
    else:
        pts = [(Wc, 0), (Wc - 70, 0), (Wc - 96, 90), (Wc - 58, 210),
               (Wc - 104, 330), (Wc - 66, 470), (Wc - 98, 600),
               (Wc - 60, Hc), (Wc, Hc)]
    L.d.polygon(pts, fill=with_a(mix(top, bot, 0.5), 255),
                outline=(28, 18, 14, 255))
    for _ in range(10):
        x, yy = r.uniform(10, Wc - 20), r.uniform(20, Hc - 20)
        rr = r.uniform(5, 12)
        L.d.ellipse([x - rr, yy - rr * 0.7, x + rr, yy + rr * 0.7],
                    fill=with_a(darken(bot, 0.75), 210))
    return outline_im(L.im, (24, 14, 10, 255), 3).crop(L.im.getbbox())


def dec_tomb():
    L = Layer(120, 90)
    vgrad(L.d, (24, 18, 96, 84), (188, 178, 158), (128, 118, 100))
    L.d.rounded_rectangle([(24, 18), (96, 84)], radius=14,
                          fill=(172, 162, 142, 255), outline=(30, 22, 16, 255))
    L.d.line([(60, 28), (60, 74)], fill=(96, 86, 70, 255), width=6)
    L.d.line([(42, 42), (78, 42)], fill=(96, 86, 70, 255), width=6)
    return outline_im(L.im, (24, 14, 10, 255), 2).crop(L.im.getbbox())


def dec_bones():
    L = Layer(130, 60)
    bone = (226, 218, 196, 255)
    L.d.rounded_rectangle([(10, 24), (118, 36)], radius=6, fill=bone,
                          outline=(30, 22, 16, 255))
    for x in (10, 118):
        L.d.ellipse([x - 8, 16, x + 8, 44], fill=bone,
                    outline=(30, 22, 16, 255))
    for i, xx in enumerate((34, 62, 90)):
        L.d.ellipse([xx - 7, 8 + (i % 2) * 8, xx + 7, 24 + (i % 2) * 8],
                    fill=bone, outline=(30, 22, 16, 255))
    return outline_im(L.im, (24, 14, 10, 255), 2).crop(L.im.getbbox())


# =============================================================== THE POWS
POWS = ["speed", "shield", "magnet", "size", "ghost", "frenzy"]
POW_COL = {"speed": (90, 200, 250), "shield": (120, 220, 130),
           "magnet": (240, 130, 90), "size": (250, 200, 80),
           "ghost": (170, 140, 240), "frenzy": (250, 90, 110)}


def pow_icon(kind):
    S = 96
    L = Layer(S, S)
    col = POW_COL[kind]
    dark = darken(col, 0.62)
    L.d.ellipse([4, 4, S - 4, S - 4], fill=with_a(dark, 255),
                outline=(24, 16, 12, 255), width=4)
    L.d.ellipse([8, 8, S - 8, S - 8], fill=with_a(col, 255))
    cx = S / 2
    if kind == "speed":
        L.d.polygon([(cx - 22, 26), (cx + 26, 48), (cx - 22, 70),
                     (cx - 6, 48)], fill=(250, 252, 255, 255))
    elif kind == "shield":
        L.d.polygon([(cx, 20), (cx + 24, 32), (cx + 20, 60), (cx, 76),
                     (cx - 20, 60), (cx - 24, 32)], fill=(240, 252, 244, 255),
                    outline=(30, 50, 30, 255))
    elif kind == "magnet":
        L.d.arc([cx - 24, cx - 24, cx + 24, cx + 24], 180, 360,
                fill=(250, 240, 230, 255), width=13)
        L.d.line([(cx - 24, cx), (cx - 24, cx + 16)], fill=(250, 60, 60, 255),
                 width=13)
        L.d.line([(cx + 24, cx), (cx + 24, cx + 16)], fill=(70, 90, 250, 255),
                 width=13)
    elif kind == "size":
        for sgn, oy in ((1, -14), (-1, 14)):
            L.d.polygon([(cx - 18 * sgn, 48 + oy - 8), (cx + 18 * sgn, 48 + oy),
                         (cx - 18 * sgn, 48 + oy + 8)],
                        fill=(250, 252, 255, 255))
    elif kind == "ghost":
        L.d.pieslice([cx - 24, 16, cx + 24, 64], 180, 360,
                     fill=(240, 240, 255, 235))
        L.d.rectangle([cx - 24, 40, cx + 24, 64], fill=(240, 240, 255, 235))
        for k in range(4):
            L.d.ellipse([cx - 24 + k * 12, 60, cx - 12 + k * 12, 72],
                        fill=(240, 240, 255, 235))
        L.d.ellipse([cx - 14, 34, cx - 6, 44], fill=(60, 50, 90, 255))
        L.d.ellipse([cx + 6, 34, cx + 14, 44], fill=(60, 50, 90, 255))
    else:  # frenzy
        L.d.polygon([(cx, 18), (cx + 8, 40), (cx + 30, 44), (cx + 12, 58),
                     (cx + 18, 80), (cx, 66), (cx - 18, 80), (cx - 12, 58),
                     (cx - 30, 44), (cx - 8, 40)], fill=(255, 244, 200, 255))
    return outline_im(L.im, (24, 16, 12, 255), 2)


# ================================================================== EXTRAS
def coin_sprite():
    S = 56
    L = Layer(S, S)
    L.d.ellipse([3, 3, S - 3, S - 3], fill=(196, 132, 40, 255),
                outline=(30, 20, 12, 255), width=3)
    L.d.ellipse([7, 7, S - 7, S - 7], fill=(250, 196, 72, 255))
    L.d.ellipse([13, 11, S - 20, S - 24], fill=(255, 228, 140, 255))
    f = font(24)
    L.d.text((S * 0.32, S * 0.24), "W", font=f, fill=(150, 92, 24, 255))
    return outline_im(L.im, (30, 20, 12, 255), 2)


def dot_sprite():
    S = 22
    L = Layer(S, S)
    L.d.ellipse([2, 2, S - 2, S - 2], fill=(255, 214, 90, 255),
                outline=(120, 80, 20, 255), width=2)
    return L.im


# ================================================================ THE THUMB
def thumb():
    Wc, Hc = 960, 640
    L = Layer(Wc, Hc)
    desert = PLACES_DEF[0]
    sky = place_sky(desert, 0).resize((Wc, int(SKY_H * Wc / SKY_W)))
    L.im.alpha_composite(sky, (0, 0))
    far = place_far(desert, 0).resize((Wc, int(FAR_H * Wc / FAR_W)))
    L.im.alpha_composite(far, (0, Hc - far.height - 120))
    # the dirt cut
    dirt = place_dirt(desert, 0).resize((Wc, 300))
    L.im.alpha_composite(dirt, (0, Hc - 300))
    # the surface bite: a crater where the worm bursts
    L.d.ellipse([300, Hc - 320, 700, Hc - 180],
                fill=with_a(darken(desert["dirt"][0], 0.8), 255))
    # THE WORM bursting, mouth open
    head = worm_head(WORMS[0], True)
    body = worm_body(WORMS[0])
    sc = 1.6
    h2 = head.resize((int(head.width * sc), int(head.height * sc)))
    b2 = body.resize((int(body.width * sc * 0.9), int(body.height * sc * 0.9)))
    L.im.alpha_composite(b2, (330, Hc - 320))
    L.im.alpha_composite(h2, (420, Hc - 560))
    # a runner fleeing
    hum = human_frame(HUMANS[1], 3)
    h3 = hum.resize((int(hum.width * 1.4), int(hum.height * 1.4)))
    L.im.alpha_composite(h3, (760, Hc - 300))
    # the title
    f = font(74)
    L.d.text((48, 36), "DEADLY WORM", font=f, fill=(250, 240, 220, 255),
             stroke_width=8, stroke_fill=(30, 18, 12, 255))
    os.makedirs(THUMB_OUT, exist_ok=True)
    L.im.convert("RGB").save(THUMB_OUT + "/deathworm.png")
    print("thumb written")
    return L.im


# ================================================================== MONTAGE
def montage(paths, cols, cell, out_name):
    rows = (len(paths) + cols - 1) // cols
    M = Image.new("RGBA", (cols * cell[0], rows * cell[1]), (34, 28, 24, 255))
    for i, p in enumerate(paths):
        try:
            im = Image.open(OUT + "/" + p)
        except Exception:
            continue
        im.thumbnail((cell[0] - 8, cell[1] - 8))
        M.alpha_composite(im, ((i % cols) * cell[0] + 4,
                               (i // cols) * cell[1] + 4))
    M.save("/home/z/my-project/study_out/ours_montage_" + out_name)
    print("montage:", out_name)


# ==================================================================== MAIN
def main(argv):
    fams = argv or ["worms", "humans", "animals", "ground", "vehicles",
                    "shots", "fx", "places", "pows", "shop", "extras",
                    "thumb"]
    if "worms" in fams:
        for w in WORMS:
            finish(worm_head(w, False), "worms/%s_head.png" % w["id"])
            finish(worm_head(w, True), "worms/%s_head_open.png" % w["id"])
            finish(worm_body(w), "worms/%s_body_0.png" % w["id"])
            finish(worm_tail(w), "worms/%s_tail.png" % w["id"])
            finish(worm_preview(w), "worms/%s_preview.png" % w["id"])
        print("worms: 50 sprites")
    if "humans" in fams:
        for c in HUMANS:
            for i in range(10):
                finish(human_frame(c, i),
                       "things/humans/%s_%02d.png" % (c["skin"], i))
        print("humans: 80 sprites")
    if "animals" in fams:
        for kind in ANIMALS:
            for i in range(ANIM_FRAMES[kind]):
                finish(animal_frame(kind, i),
                       "things/animals/%s_%02d.png" % (kind, i))
        print("animals:", sum(ANIM_FRAMES.values()), "sprites")
    if "ground" in fams:
        for kind, n in GROUND_ANIMALS.items():
            for i in range(n):
                finish(ground_frame(kind, i),
                       "things/ground/%s_%02d.png" % (kind, i))
        print("ground:", sum(GROUND_ANIMALS.values()), "sprites")
    if "vehicles" in fams:
        for kind, n in VEHICLES.items():
            for i in range(n):
                finish(vehicle_frame(kind, i),
                       "things/vehicles/%s_%02d.png" % (kind, i))
        print("vehicles:", sum(VEHICLES.values()), "sprites")
    if "shots" in fams:
        for kind, n in SHOTS.items():
            for i in range(n):
                finish(shot_frame(kind, i),
                       "things/shots/%s_%02d.png" % (kind, i))
        print("shots:", sum(SHOTS.values()), "sprites")
    if "fx" in fams:
        for i in range(24):
            expl_frame(i).save(OUT + "/things/fx/expl_%02d.png" % i)
        print("fx: 24 sprites")
    if "places" in fams:
        for i, p in enumerate(PLACES_DEF):
            place_sky(p, i).save(OUT + "/places/%s_sky.png" % p["id"])
            place_far(p, i).save(OUT + "/places/%s_far.png" % p["id"])
            place_dirt(p, i).save(OUT + "/places/%s_dirt.png" % p["id"])
            place_road(p, i).save(OUT + "/places/%s_road.png" % p["id"])
            place_bounds(p, "l").save(OUT + "/places/%s_bound_l.png" % p["id"])
            place_bounds(p, "r").save(OUT + "/places/%s_bound_r.png" % p["id"])
            print("place:", p["id"])
        dec_tomb().save(OUT + "/places/dec_tomb.png")
        dec_bones().save(OUT + "/places/dec_bones.png")
    if "pows" in fams:
        for k in POWS:
            pow_icon(k).save(OUT + "/pows/%s.png" % k)
        print("pows: 6")
    if "shop" in fams:
        # the place shop cards: the far strip + the name
        for i, p in enumerate(PLACES_DEF):
            card = place_far(p, i).resize((512, 154)).convert("RGBA")
            C = Layer(512, 320)
            C.im.alpha_composite(card, (0, 30))
            C.d.rectangle([0, 200, 512, 320],
                          fill=with_a(darken(p["dirt"][1], 0.9), 255))
            f = font(44)
            C.d.text((256, 232), p["id"].upper(), font=f,
                     fill=(250, 240, 220, 255), anchor="mm",
                     stroke_width=5, stroke_fill=(30, 18, 12, 255))
            C.im.save(OUT + "/shop/%s.png" % p["id"])
        print("shop: 5 cards")
    if "extras" in fams:
        coin_sprite().save(OUT + "/coin.png")
        dot_sprite().save(OUT + "/dot.png")
        print("extras: coin + dot")
    if "thumb" in fams:
        thumb()
    # the eye-pass montages
    montage(["worms/%s_preview.png" % w["id"] for w in WORMS], 5,
            (320, 210), "worms.png")
    montage(["things/humans/%s_%02d.png" % (c["skin"], i)
             for c in HUMANS for i in (0, 3, 6)], 8, (120, 130), "humans.png")
    montage(["things/animals/%s_%02d.png" % (k, i)
             for k in ANIMALS for i in range(0, ANIM_FRAMES[k],
                                             max(1, ANIM_FRAMES[k] // 3))]
            + ["things/ground/%s_00.png" % k for k in GROUND_ANIMALS],
            7, (170, 130), "animals.png")
    montage(["things/vehicles/%s_00.png" % k for k in VEHICLES]
            + ["things/vehicles/%s_%02d.png" % (k, VEHICLES[k] // 2)
               for k in VEHICLES], 5, (210, 150), "vehicles.png")
    montage(["things/fx/expl_%02d.png" % i for i in range(0, 24, 3)], 8,
            (120, 120), "fx.png")
    montage(["places/%s_sky.png" % p["id"] for p in PLACES_DEF], 3,
            (330, 190), "skies.png")
    montage(["places/%s_far.png" % p["id"] for p in PLACES_DEF], 3,
            (400, 130), "fars.png")


if __name__ == "__main__":
    import sys
    main(sys.argv[1:])
