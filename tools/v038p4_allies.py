#!/usr/bin/env python3
"""
v0.3.8-4 THE ALIVE CREW - the six allies redrawn as REAL potato crew mates
in the hero art's own language (the owner's round on the v0.3.8-3 faces:
"they are bad... they still feel like a static image that someone drags it
to follow me, give it moving animation like the character or enemies and
the left-right looking, make it feel like a real thing rather than a
...shitty something").

Each ally = a lumpy potato body (the hero's own silhouette recipe: blob +
dimples + dark outline + warm glow + big eyes + boots) wearing its JOB's
gear, x 4 WALK FRAMES (f0 left leg forward / f1 passing / f2 right leg
forward / f3 passing) so the field animation can drive them exactly like
the hero's 4-frame waddle.

Outputs (assets/games/cosmic_spud/allies/):
  ally_<id>_f0..f3.png   the 96px walk frames (the field crew)
  ally_<id>.png          the f0 frame (the compat portrait key)
  /tmp/allies_v038p4_sheet.png  the contact sheet (eyeball pass)
"""
import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter

OUT = ("/home/z/my-project/GOGABox/projects/gogabox/"
       "assets/games/cosmic_spud/allies")
os.makedirs(OUT, exist_ok=True)

SS = 4                     # supersample
CAN = 96                   # final canvas
C = CAN * SS               # working canvas 384

# ---------------------------------------------------------------- palette
# (sampled off the hero frames)
BODY      = (183, 145, 97, 255)
BODY_HI   = (212, 174, 122, 255)
BODY_LO   = (150, 113, 70, 255)
BODY_DK   = (128, 94, 56, 255)
OUTLINE   = (36, 24, 22, 255)
GLOW      = (255, 196, 84)
BOOT      = (94, 62, 40, 255)
BOOT_DK   = (66, 42, 27, 255)
EYE_W     = (252, 250, 246, 255)
EYE_P     = (32, 26, 30, 255)
MOUTH     = (72, 46, 38, 255)


def blob_points(cx, cy, rx, ry, seed, lumps=7, wobble=0.055):
    """a lumpy potato silhouette - FIXED per seed so all 4 frames share it"""
    rnd = random.Random(seed)
    harm = [(rnd.uniform(0.4, 1.0), rnd.uniform(0, math.tau), 2),
            (rnd.uniform(0.2, 0.6), rnd.uniform(0, math.tau), 3),
            (rnd.uniform(0.1, 0.35), rnd.uniform(0, math.tau), 5)]
    pts = []
    for i in range(72):
        a = math.tau * i / 72.0
        r = 1.0
        for amp, ph, k in harm:
            r += amp * wobble * math.sin(k * a + ph)
        pts.append((cx + math.cos(a) * rx * r, cy + math.sin(a) * ry * r))
    return pts


def shade_body(img, pts, seed):
    """gradient base + light band + shadow band + dimples (the hero recipe)"""
    lay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    d.polygon(pts, fill=BODY)
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    w, h = x1 - x0, y1 - y0
    # the light: top-left band
    hi = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(hi).ellipse([x0 + w * 0.06, y0 + h * 0.02,
                                x0 + w * 0.72, y0 + h * 0.55], fill=BODY_HI)
    lay = Image.composite(Image.alpha_composite(lay, hi), lay, mask)
    # the shadow: bottom-right band
    lo = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(lo).ellipse([x0 + w * 0.30, y0 + h * 0.48,
                                x1 + w * 0.06, y1 + h * 0.06], fill=BODY_LO)
    lay = Image.composite(Image.alpha_composite(lay, lo), lay, mask)
    lo2 = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(lo2).ellipse([x0 + w * 0.46, y0 + h * 0.66,
                                 x1 + w * 0.02, y1 + h * 0.10], fill=BODY_DK)
    lay = Image.composite(Image.alpha_composite(lay, lo2), lay, mask)
    # the dimples (potato eyes of the tuber, fixed per seed)
    rnd = random.Random(seed + 99)
    dim = Image.new("RGBA", img.size, (0, 0, 0, 0))
    dd = ImageDraw.Draw(dim)
    for _ in range(5):
        ex = rnd.uniform(x0 + w * 0.14, x1 - w * 0.14)
        ey = rnd.uniform(y0 + h * 0.16, y1 - h * 0.30)
        er = rnd.uniform(w * 0.028, w * 0.05)
        dd.ellipse([ex - er, ey - er * 0.7, ex + er, ey + er * 0.7],
                   fill=(*BODY_DK[:3], 110))
    lay = Image.composite(Image.alpha_composite(lay, dim), lay, mask)
    img.alpha_composite(lay)


def outline_body(img, pts):
    """the dark rim, 7px at SS scale"""
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    ring = mask.filter(ImageFilter.MaxFilter(2 * 7 + 1))
    ring = Image.composite(Image.new("L", img.size, 0), ring, mask)
    lay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    lay.paste(OUTLINE, (0, 0), ring)
    img.alpha_composite(lay)


def glow_body(img, pts):
    """the warm cosmic halo under everything (the hero's signature)"""
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(pts, fill=210)
    big = mask.filter(ImageFilter.MaxFilter(2 * 22 + 1))
    big = big.filter(ImageFilter.GaussianBlur(16))
    lay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    lay.paste((*GLOW, 200), (0, 0), big)
    img.alpha_composite(lay)


def eye(img, x, y, r, look=0.0, lid=0.0):
    d = ImageDraw.Draw(img)
    # white
    d.ellipse([x - r, y - r * 1.12, x + r, y + r * 1.12], fill=EYE_W,
              outline=(*OUTLINE[:3], 255), width=SS)
    # pupil (looks toward `look` in [-1..1])
    pr = r * 0.46
    px, py = x + look * r * 0.34, y + r * 0.12
    d.ellipse([px - pr, py - pr * 1.08, px + pr, py + pr * 1.08], fill=EYE_P)
    d.ellipse([px - pr * 0.42 - pr * 0.18, py - pr * 0.62,
               px - pr * 0.18, py - pr * 0.28], fill=(255, 255, 255, 235))
    if lid > 0:  # a calm upper lid (kind faces)
        d.arc([x - r, y - r * 1.3, x + r, y + r * 1.15], 180, 360,
              fill=(*OUTLINE[:3], 255), width=int(SS * (1.5 + lid)))


def brow(img, x, y, w, tilt, mood="flat"):
    d = ImageDraw.Draw(img)
    if mood == "angry":       # inner ends down
        p = [(x - w, y + tilt * 0.4), (x - w * 0.1, y - tilt),
             (x + w * 0.1, y - tilt * 1.06), (x + w, y + tilt * 0.34)]
    elif mood == "kind":      # a soft arc
        d.arc([x - w, y - tilt * 1.4, x + w, y + tilt * 1.1],
              200, 340, fill=(*OUTLINE[:3], 255), width=int(SS * 2.2))
        return
    elif mood == "wild":      # a zigzag
        p = [(x - w, y), (x - w * 0.5, y - tilt), (x, y + tilt * 0.3),
             (x + w * 0.5, y - tilt), (x + w, y)]
        d.line(p, fill=(*OUTLINE[:3], 255), width=int(SS * 2.4), joint="curve")
        return
    else:                     # flat determined
        p = [(x - w, y - tilt * 0.2), (x + w, y + tilt * 0.5)]
    d.line(p, fill=(*OUTLINE[:3], 255), width=int(SS * 2.6), joint="curve")


def mouth_bar(img, x, y, w, h, smirk=0.0):
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([x - w, y - h, x + w, y + h], radius=h,
                        fill=MOUTH)
    d.rounded_rectangle([x - w + SS, y - h + SS, x + w - SS, y - h + SS * 2.4],
                        radius=SS, fill=(255, 255, 255, 60))


def hand(img, x, y, r=17):
    d = ImageDraw.Draw(img)
    d.ellipse([x - r, y - r, x + r, y + r], fill=BODY_HI,
              outline=(*OUTLINE[:3], 255), width=int(SS * 2.4))


def arm(img, x0, y0, x1, y1):
    d = ImageDraw.Draw(img)
    d.line([(x0, y0), (x1, y1)], fill=BODY_LO, width=int(SS * 11))
    d.line([(x0, y0), (x1, y1)], fill=(*OUTLINE[:3], 200), width=int(SS * 13))
    d.line([(x0, y0), (x1, y1)], fill=BODY_LO, width=int(SS * 9))


def boot(img, x, y, w, h):
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([x - w, y - h, x + w, y + h * 0.3], radius=w * 0.42,
                        fill=BOOT, outline=BOOT_DK, width=int(SS * 1.6))


def shadow(img, cx, cy, rx, alpha=70):
    d = ImageDraw.Draw(img)
    d.ellipse([cx - rx, cy - rx * 0.26, cx + rx, cy + rx * 0.26],
              fill=(10, 8, 8, alpha))


# ---------------------------------------------------------------- frames
BODY_RX = 84.0
BODY_RY = 74.0
BODY_CY = 186.0


def body_frame(aid, fi, pose):
    """one supersampled frame; pose = dict of leg lift / body dy / extras"""
    img = Image.new("RGBA", (C, C), (0, 0, 0, 0))
    dy = pose.get("dy", 0.0)
    pts = blob_points(C * 0.5, BODY_CY + dy, BODY_RX, BODY_RY, seed=hash(aid) & 0xffff)
    cx = C * 0.5
    # ground shadow + boots UNDER the body
    shadow(img, cx, C * 0.885, 58)
    lift = pose.get("legL", 0.0), pose.get("legR", 0.0)
    if not pose.get("hover", False):
        boot(img, cx - 50, C * 0.762 - lift[0], 25, 32)
        boot(img, cx + 42, C * 0.735 - lift[1], 25, 30)
    glow_body(img, pts)
    shade_body(img, pts, seed=hash(aid) & 0xffff)
    # face zone
    fx, fy = cx, BODY_CY + dy - BODY_RY * 0.28
    draw_face(img, aid, fx, fy, pose)
    draw_gear(img, aid, fx, fy, fi, pose)
    outline_body(img, pts)
    return img


def draw_face(img, aid, fx, fy, pose):
    look = pose.get("look", 0.0)
    r = 25.0
    if aid in ("drone", "scout"):
        eye(img, fx - 30, fy - 6, r * 0.94, look)
        eye(img, fx + 30, fy - 6, r * 0.94, look)
    else:
        eye(img, fx - 31, fy - 6, r, look)
        eye(img, fx + 31, fy - 6, r, look)
    mood = {"drone": "kind", "turret": "angry", "guard": "flat",
            "medic": "kind", "bomber": "wild", "scout": "flat"}[aid]
    bt = {"drone": 3.0, "turret": 7.5, "guard": 6.0,
          "medic": 2.0, "bomber": 6.0, "scout": 5.0}[aid]
    brow(img, fx, fy - 34, 17, bt, mood)
    brow(img, fx, fy - 34, 17, bt, mood) if False else None
    # (brows are drawn per-eye by the helper's geometry)
    mouth_bar(img, fx, fy + 40, 14, 4.5)


def draw_gear(img, aid, fx, fy, fi, pose):
    d = ImageDraw.Draw(img)
    cx = C * 0.5
    dy = pose.get("dy", 0.0)
    by = BODY_CY + dy
    if aid == "drone":
        # the rotor beanie: a pole + two spinning blades (angle per frame)
        pole = (cx, by - BODY_RY - 26, cx, by - BODY_RY + 6)
        d.line(pole, fill=(120, 116, 128, 255), width=int(SS * 6))
        d.ellipse([cx - 26, by - BODY_RY - 12, cx + 26, by - BODY_RY + 8],
                  fill=(58, 148, 140, 255), outline=(*OUTLINE[:3], 255),
                  width=int(SS * 3))
        ang = fi * math.pi / 4.0
        bx, byy = cx, by - BODY_RY - 26
        for s in (1, -1):
            ex = bx + math.cos(ang) * 62 * s
            ey = byy + math.sin(ang) * 13 * s
            d.line([(bx, byy), (ex, ey)], fill=(72, 168, 158, 255),
                   width=int(SS * 8))
        d.ellipse([bx - 9, byy - 9, bx + 9, byy + 9], fill=(84, 170, 160, 255),
                  outline=(*OUTLINE[:3], 255), width=int(SS * 2))
        # aviator goggles parked on the forehead
        d.rounded_rectangle([fx - 46, fy - 62, fx + 46, fy - 40], radius=10,
                            fill=(70, 66, 78, 255))
        d.ellipse([fx - 38, fy - 60, fx - 8, fy - 42], fill=(196, 214, 210, 255),
                  outline=(*OUTLINE[:3], 255), width=int(SS * 2))
        d.ellipse([fx + 8, fy - 60, fx + 38, fy - 42], fill=(196, 214, 210, 255),
                  outline=(*OUTLINE[:3], 255), width=int(SS * 2))
        # the teal scarf
        d.rounded_rectangle([fx - 50, by + 52, fx + 50, by + 72], radius=12,
                            fill=(58, 148, 140, 255),
                            outline=(*OUTLINE[:3], 255), width=int(SS * 2))
        # hover puff under the body
        ph = 40 + 10 * math.sin(fi * math.pi / 2)
        d.ellipse([cx - ph, C * 0.88 - 8, cx + ph, C * 0.88 + 10],
                  fill=(220, 228, 232, 90))
    elif aid == "turret":
        # the orange hard hat
        d.chord([fx - 52, fy - 74, fx + 52, fy + 6], 180, 360,
                fill=(226, 124, 48, 255), outline=(*OUTLINE[:3], 255),
                width=int(SS * 3))
        d.rounded_rectangle([fx - 62, fy - 14, fx + 62, fy + 2], radius=9,
                            fill=(196, 104, 38, 255),
                            outline=(*OUTLINE[:3], 255), width=int(SS * 3))
        d.line([(fx, fy - 74), (fx, fy - 88)], fill=(120, 62, 26, 255),
               width=int(SS * 7))
        # the fat cannon over the right shoulder
        sh = 3 if fi % 2 == 0 else 0   # recoil frames
        arm(img, fx + 30, by + 20, fx + 62, fy - 6 + sh)
        d.rounded_rectangle([fx + 40, fy - 34 + sh, fx + 106, fy - 8 + sh],
                            radius=12, fill=(112, 110, 122, 255),
                            outline=(*OUTLINE[:3], 255), width=int(SS * 3))
        d.rounded_rectangle([fx + 98, fy - 42 + sh, fx + 112, fy + 0 + sh],
                            radius=7, fill=(88, 86, 98, 255),
                            outline=(*OUTLINE[:3], 255), width=int(SS * 3))
        d.ellipse([fx + 104, fy - 33 + sh, fx + 112, fy - 9 + sh],
                  fill=(30, 28, 34, 255))
        d.ellipse([fx + 34, fy - 36 + sh, fx + 58, fy - 6 + sh],
                  fill=(144, 142, 152, 255), outline=(*OUTLINE[:3], 255),
                  width=int(SS * 2))
        hand(img, fx + 58, fy + 2 + sh, 14)
    elif aid == "guard":
        # the green bandana
        d.chord([fx - 50, fy - 66, fx + 50, fy - 6], 180, 360,
                fill=(72, 138, 72, 255), outline=(*OUTLINE[:3], 255),
                width=int(SS * 3))
        d.polygon([(fx + 34, fy - 40), (fx + 76, fy - 30), (fx + 40, fy - 16)],
                  fill=(56, 112, 56, 255), outline=(*OUTLINE[:3], 255))
        # the big round shield on the left side
        sx, sy = fx - 80, by + 12
        d.ellipse([sx - 42, sy - 54, sx + 42, sy + 54],
                  fill=(148, 154, 168, 255), outline=(*OUTLINE[:3], 255),
                  width=int(SS * 4))
        d.ellipse([sx - 32, sy - 42, sx + 32, sy + 42],
                  fill=(176, 182, 194, 255))
        d.ellipse([sx - 24, sy - 33, sx + 24, sy + 33],
                  outline=(96, 102, 116, 255), width=int(SS * 4))
        d.ellipse([sx - 12, sy - 12, sx + 12, sy + 12], fill=(226, 186, 52, 255),
                  outline=(*OUTLINE[:3], 255), width=int(SS * 2))
        arm(img, fx - 52, by + 10, sx + 24, sy)
        hand(img, fx + 66, by + 34, 16)
    elif aid == "medic":
        # the white cap with the red cross
        d.chord([fx - 50, fy - 70, fx + 50, fy - 2], 180, 360,
                fill=(238, 236, 230, 255), outline=(*OUTLINE[:3], 255),
                width=int(SS * 3))
        d.rectangle([fx - 10, fy - 58, fx + 10, fy - 24], fill=(212, 60, 52, 255))
        d.rectangle([fx - 30, fy - 51, fx + 30, fy - 31], fill=(212, 60, 52, 255))
        # the satchel strap + bag with a cross
        d.line([(fx - 40, fy + 30), (fx + 66, by + 52)],
               fill=(150, 108, 66, 255), width=int(SS * 7))
        d.rounded_rectangle([fx + 52, by + 40, fx + 104, by + 76], radius=10,
                            fill=(200, 158, 100, 255),
                            outline=(*OUTLINE[:3], 255), width=int(SS * 3))
        d.rectangle([fx + 72, by + 48, fx + 84, by + 70], fill=(212, 60, 52, 255))
        d.rectangle([fx + 65, by + 55, fx + 91, by + 63], fill=(212, 60, 52, 255))
        hand(img, fx - 74, by + 36, 16)
    elif aid == "bomber":
        # soot smudges
        d.ellipse([fx - 66, fy + 8, fx - 44, fy + 26], fill=(70, 58, 54, 140))
        d.ellipse([fx + 40, fy + 16, fx + 60, fy + 32], fill=(70, 58, 54, 120))
        # the hugged bomb (jiggles with the walk)
        jig = (2.2 if fi in (1, 3) else 0.0) * pose.get("dir", 1.0)
        bx, byy = cx + 100 + jig, by + 26 + jig
        arm(img, fx + 40, by + 34, bx - 22, byy + 2)
        hand(img, bx - 20, byy + 4, 15)
        d.ellipse([bx - 30, byy - 10, bx + 30, byy + 38],
                  fill=(38, 34, 40, 255), outline=(*OUTLINE[:3], 255),
                  width=int(SS * 3))
        d.ellipse([bx - 22, byy - 2, bx - 2, byy + 16], fill=(66, 60, 70, 255))
        d.rounded_rectangle([bx - 8, byy - 20, bx + 8, byy - 6], radius=5,
                            fill=(96, 92, 104, 255),
                            outline=(*OUTLINE[:3], 255), width=int(SS * 2))
        # the lit fuse + spark (a curl UP off the cap, always in the open)
        d.arc([bx - 10, byy - 44, bx + 20, byy - 12], 280, 90,
              fill=(154, 122, 78, 255), width=int(SS * 4))
        sp = 4.5 + 3.0 * (fi % 2)
        d.ellipse([bx + 13 - sp, byy - 46 - sp, bx + 13 + sp, byy - 46 + sp],
                  fill=(255, 176, 60, 255))
        d.ellipse([bx + 13 - sp * 0.5, byy - 46 - sp * 0.5,
                   bx + 13 + sp * 0.5, byy - 46 + sp * 0.5],
                  fill=(255, 244, 200, 255))
    elif aid == "scout":
        # the yellow forward cap: dome rides the head top, band under it
        d.chord([fx - 46, fy - 78, fx + 46, fy - 18], 180, 360,
                fill=(226, 186, 52, 255), outline=(*OUTLINE[:3], 255),
                width=int(SS * 3))
        d.rounded_rectangle([fx - 52, fy - 42, fx + 52, fy - 24], radius=8,
                            fill=(206, 166, 44, 255),
                            outline=(*OUTLINE[:3], 255), width=int(SS * 3))
        # the dart rides the right hand (arm reaches out of the silhouette)
        bob = (2.0 if fi in (1, 3) else -2.0)
        hx, hy = fx + 82, by + 12 + bob
        arm(img, fx + 44, by + 32, hx - 14, hy + 4)
        d.line([(hx - 30, hy), (hx + 24, hy)], fill=(154, 112, 70, 255),
               width=int(SS * 7))
        d.polygon([(hx + 24, hy - 11), (hx + 46, hy), (hx + 24, hy + 11)],
                  fill=(172, 172, 182, 255), outline=(*OUTLINE[:3], 255))
        d.line([(hx - 30, hy - 10), (hx - 18, hy - 10)], fill=(224, 92, 72, 255),
               width=int(SS * 4))
        hand(img, hx - 22, hy + 8, 15)


LEG_L = [16.0, 5.0, -7.0, 8.0]
LEG_R = [-7.0, 8.0, 16.0, 5.0]
DY    = [2.0, -3.0, 2.0, -3.0]


def make(aid, hover=False):
    frames = []
    for fi in range(4):
        pose = {"legL": 0.0, "legR": 0.0, "dy": DY[fi], "look": 0.0,
                "hover": hover, "dir": 1.0}
        if not hover:
            pose["legL"] = LEG_L[fi]
            pose["legR"] = LEG_R[fi]
        img = body_frame(aid, fi, pose)
        frames.append(img)
        p = os.path.join(OUT, "ally_%s_f%d.png" % (aid, fi))
        img.resize((CAN, CAN), Image.LANCZOS).save(p)
    # the compat portrait = f0
    frames[0].resize((CAN, CAN), Image.LANCZOS).save(
            os.path.join(OUT, "ally_%s.png" % aid))
    return frames


order = ["bomber", "drone", "guard", "medic", "scout", "turret"]
made = {}
for aid in order:
    made[aid] = make(aid, hover=(aid == "drone"))

# the contact sheet (2 rows x 3 allies, frames in a row) - the eyeball pass
sheet = Image.new("RGBA", (4 * 104 + 16, 6 * 104 + 16), (44, 42, 50, 255))
for r, aid in enumerate(order):
    for fi in range(4):
        im = Image.open(os.path.join(OUT, "ally_%s_f%d.png" % (aid, fi)))
        sheet.alpha_composite(im, (8 + fi * 104, 8 + r * 104))
sheet.save("/tmp/allies_v038p4_sheet.png")
print("allies drawn:", order)
