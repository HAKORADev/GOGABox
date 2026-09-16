#!/usr/bin/env python3
# ============================================================================
# v040-4 HEAVY WAR: ROGUE ARSENAL - the art pipeline.
# EVERY pixel is OUR OWN (the owner: "you will remove all original assets
# too, you will make all your own things"). The old composed PopCap sprites
# (assets/games/heavywar/*, assets/games/hwsrc/**) die this commit.
#
# THE HOUSE PIXEL LOOK: chunky shapes, dark outline, 3-tone ramp, top rim
# light, one accent glow. Native resolution, NEAREST x4 upscale.
#
# Sections (run with a section arg to iterate fast):
#   python3 tools/v0404_rogue_art.py tank      -> the tank family
#   python3 tools/v0404_rogue_art.py enemies   -> 22 enemy types x 2 frames
#   python3 tools/v0404_rogue_art.py bosses    -> 10 bosses x 2 frames
#   python3 tools/v0404_rogue_art.py places    -> 10 environments
#   python3 tools/v0404_rogue_art.py bits      -> shots/pickups/vfx/icons
#   python3 tools/v0404_rogue_art.py thumb     -> the feed thumbnail
#   python3 tools/v0404_rogue_art.py all
# ============================================================================
import math, os, random, sys
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..",
                   "projects/gogabox/assets/games/heavywar")

# ----------------------------------------------------------------- helpers
def out_dirs():
    for d in ["", "enemies", "bosses", "env", "shots", "fx", "ui"]:
        os.makedirs(os.path.join(OUT, d), exist_ok=True)

def up4(img):
    return img.resize((img.width * 4, img.height * 4), Image.NEAREST)

def save(img, rel):
    p = os.path.join(OUT, rel)
    up4(img).save(p)
    print("wrote", rel, up4(img).size)

def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def dimg(img):
    return ImageDraw.Draw(img)

def shade(c, f):
    return (max(0, min(255, int(c[0] * f))),
            max(0, min(255, int(c[1] * f))),
            max(0, min(255, int(c[2] * f))),
            c[3] if len(c) > 3 else 255)

def ramp(base, n=4, lo=0.45, hi=1.28):
    """dark -> light shades of base"""
    return [shade(base, lo + (hi - lo) * i / max(1, n - 1)) for i in range(n)]

OL = (16, 14, 20, 255)          # the outline ink

def outline(img, col=OL, alpha_thresh=40):
    """1px dark outline around the alpha shape (the house look).
    Reads neighbors from a FROZEN snapshot - reading the live buffer made
    the outline cascade and flood-fill the whole canvas opaque."""
    w, h = img.size
    src = img.load()
    o = canvas(w + 2, h + 2)
    dst = o.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = src[x, y]
            if a > alpha_thresh:
                dst[x + 1, y + 1] = (r, g, b, a)
    frozen = o.copy().load()   # the truth snapshot for neighbor checks
    od = dimg(o)
    for y in range(h + 2):
        for x in range(w + 2):
            if dst[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w + 2 and 0 <= ny < h + 2 \
                            and frozen[nx, ny][3] > alpha_thresh:
                        od.point((x, y), fill=col)
                        break
    return o

def rim(img, col=(255, 255, 255, 150), alpha_thresh=40):
    """1px light rim along the TOP edges (sun from above)."""
    w, h = img.size
    src = img.load()
    out = img.copy()
    dst = out.load()
    for y in range(1, h):
        for x in range(w):
            if src[x, y][3] > alpha_thresh and src[x, y - 1][3] <= alpha_thresh:
                dst[x, y] = col
    return out

def px_ellipse(d, box, fill):
    d.ellipse(box, fill=fill)

def gl(d, cx, cy, r, col, steps=3):
    """cheap glow: concentric fading discs."""
    for i in range(steps, 0, -1):
        f = 0.10 + 0.14 * (steps - i)
        c = (col[0], col[1], col[2], int(255 * f / i))
        px_ellipse(d, [cx - r * i // steps, cy - r * i // steps,
                       cx + r * i // steps, cy + r * i // steps], fill=c)

def wobble_pts(base_pts, t, amp=1):
    return base_pts

# ------------------------------------------------------------ place tables
# THE 10 PLACES (the owner: 10 places, exclusives + shared pools).
# skyTop/skyBot drive the engine's gradient; pal drives the sprites.
PLACES = [
    dict(key="iron",   name="IRON WASTELAND",
         skyTop=(11, 13, 22), skyBot=(90, 58, 34), sun=(255, 119, 51),
         far=(26, 22, 34), mid=(36, 28, 24), near=(46, 32, 24),
         ground=(16, 10, 6), groundTop=(58, 38, 26), accent=(255, 136, 68)),
    dict(key="mesa",   name="SCORCHED MESA",
         skyTop=(42, 24, 40), skyBot=(224, 138, 68), sun=(255, 208, 106),
         far=(58, 26, 24), mid=(90, 40, 32), near=(122, 52, 40),
         ground=(64, 32, 26), groundTop=(138, 80, 48), accent=(255, 176, 96)),
    dict(key="tundra", name="FROZEN TUNDRA",
         skyTop=(8, 24, 44), skyBot=(136, 170, 204), sun=(240, 248, 255),
         far=(26, 58, 90), mid=(42, 74, 106), near=(58, 90, 122),
         ground=(74, 106, 136), groundTop=(160, 192, 224), accent=(136, 221, 255)),
    dict(key="volcano", name="VOLCANIC CORE",
         skyTop=(26, 4, 4), skyBot=(122, 42, 10), sun=(255, 68, 0),
         far=(26, 5, 5), mid=(42, 8, 8), near=(58, 10, 8),
         ground=(16, 4, 4), groundTop=(255, 68, 0), accent=(255, 102, 34)),
    dict(key="swamp",  name="TOXIC SWAMP",
         skyTop=(8, 24, 15), skyBot=(74, 106, 64), sun=(136, 255, 68),
         far=(10, 24, 16), mid=(16, 42, 24), near=(24, 58, 32),
         ground=(14, 26, 10), groundTop=(74, 106, 32), accent=(136, 238, 68)),
    dict(key="crystal", name="CRYSTAL CAVERNS",
         skyTop=(24, 8, 42), skyBot=(90, 58, 122), sun=(221, 136, 255),
         far=(24, 8, 48), mid=(40, 16, 72), near=(58, 26, 90),
         ground=(30, 12, 56), groundTop=(136, 68, 204), accent=(204, 102, 255)),
    dict(key="sky",    name="SKY ARCHIPELAGO",
         skyTop=(74, 122, 184), skyBot=(221, 238, 255), sun=(255, 245, 204),
         far=(51, 74, 102), mid=(90, 119, 170), near=(138, 170, 221),
         ground=(58, 90, 58), groundTop=(136, 187, 136), accent=(255, 240, 136)),
    dict(key="trench", name="ABYSSAL TRENCH",
         skyTop=(2, 14, 24), skyBot=(14, 58, 90), sun=(68, 170, 221),
         far=(2, 14, 26), mid=(6, 24, 40), near=(10, 32, 56),
         ground=(2, 6, 12), groundTop=(26, 68, 102), accent=(68, 238, 255)),
    dict(key="neon",   name="NEON SPRAWL",
         skyTop=(8, 2, 26), skyBot=(58, 10, 90), sun=(255, 68, 170),
         far=(5, 2, 16), mid=(10, 5, 24), near=(26, 10, 42),
         ground=(4, 2, 14), groundTop=(255, 34, 136), accent=(255, 68, 204)),
    dict(key="void",   name="THE VOID",
         skyTop=(0, 0, 0), skyBot=(32, 8, 72), sun=(255, 255, 255),
         far=(5, 0, 16), mid=(10, 4, 32), near=(26, 10, 42),
         ground=(3, 0, 10), groundTop=(102, 51, 204), accent=(170, 68, 255)),
]

# ============================================================================
# PART 1 - THE TANK (the owner's redesign: ONE big hull part, the weapons
# bolted on the visible flank; side view, facing RIGHT)
# ============================================================================

TANK_PAL = dict(
    steel=(96, 104, 116), steelD=(58, 62, 72), steelL=(140, 148, 160),
    olive=(108, 118, 76), oliveD=(66, 72, 48), oliveL=(146, 156, 106),
    track=(44, 44, 50), trackL=(84, 84, 94), hub=(120, 126, 138),
    accent=(255, 176, 64), dark=(30, 32, 38),
)

def draw_track(d, x, y, w, h, pal):
    """track skirt: dark band + wheels + road wheels"""
    d.rounded_rectangle([x, y, x + w, y + h], radius=h // 2, fill=pal["track"],
                        outline=OL, width=2)
    # wheels
    n = 5
    for i in range(n):
        cx = x + 8 + i * (w - 16) // (n - 1)
        cy = y + h // 2
        d.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=pal["trackL"],
                  outline=OL, width=2)
        d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=pal["hub"])

def draw_hull(base_pal, w=150, h=46):
    """THE ONE BIG TANK PART: single armored slab, sloped glacis, engine
    deck, tow hooks. Side view facing right."""
    img = canvas(w, h + 32)
    d = dimg(img)
    y0 = 28  # room for the track below
    body = base_pal["steel"]
    # ---- tracks (under everything)
    draw_track(d, 4, y0 + h - 12, w - 8, 16, base_pal)
    # ---- main slab
    d.polygon([(2, y0 + 12), (10, y0 + 2), (w - 14, y0 + 2), (w - 2, y0 + 14),
               (w - 2, y0 + h - 14), (w - 10, y0 + h - 2), (10, y0 + h - 2),
               (2, y0 + h - 12)], fill=body)
    # bevel: top light band, bottom dark band
    d.polygon([(10, y0 + 2), (w - 14, y0 + 2), (w - 11, y0 + 7), (13, y0 + 7)],
              fill=base_pal["steelL"])
    d.polygon([(2, y0 + h - 12), (10, y0 + h - 2), (w - 10, y0 + h - 2),
               (w - 2, y0 + h - 14), (w - 2, y0 + h - 18), (8, y0 + h - 18),
               (2, y0 + h - 8)], fill=base_pal["steelD"])
    # sloped glacis at the nose
    d.polygon([(w - 14, y0 + 2), (w - 2, y0 + 14), (w - 2, y0 + h - 14),
               (w - 14, y0 + h - 2), (w - 20, y0 + 6), (w - 20, y0 + h - 6)],
              fill=shade(body, 0.92))
    d.line([(w - 20, y0 + 6), (w - 20, y0 + h - 6)], fill=base_pal["steelD"])
    # panel seams + rivets
    for sx in (34, 66, 98):
        d.line([(sx, y0 + 6), (sx, y0 + h - 8)], fill=base_pal["steelD"])
    for rx in (26, 52, 78, 104):
        for ry in (y0 + 9, y0 + h - 12):
            d.point((rx, ry), fill=base_pal["steelD"])
            d.point((rx + 1, ry), fill=base_pal["steelL"])
    # engine deck at the rear (exhaust grills)
    d.rectangle([4, y0 + 6, 22, y0 + h - 10], fill=base_pal["steelD"])
    for gy in range(y0 + 8, y0 + h - 10, 4):
        d.line([(6, gy), (20, gy)], fill=base_pal["steel"])
    # tow hooks front
    d.rectangle([w - 12, y0 + h - 12, w - 6, y0 + h - 8], fill=OL)
    # flank hardpoints: 4 bolt bosses where the mini tanks mount
    for hx in (44, 74, 104, 128):
        d.ellipse([hx - 3, y0 + h // 2 - 3, hx + 3, y0 + h // 2 + 3],
                  fill=base_pal["steelD"], outline=OL)
    # accent stripe
    d.rectangle([28, y0 + 4, w - 24, y0 + 6], fill=base_pal["accent"])
    return img

def draw_turret(pal, w=58, h=34):
    img = canvas(w, h)
    d = dimg(img)
    # low-dome turret with mantlet
    d.polygon([(4, h - 6), (10, 8), (w - 18, 4), (w - 4, h - 6)],
              fill=pal["steel"])
    d.polygon([(10, 8), (w - 18, 4), (w - 16, 9), (13, 12)],
              fill=pal["steelL"])
    d.polygon([(4, h - 6), (w - 4, h - 6), (w - 6, h - 2), (6, h - 2)],
              fill=pal["steelD"])
    d.polygon([(w - 18, 4), (w - 4, h - 6), (w - 12, h - 6), (w - 20, 10)],
              fill=pal["steelD"])  # mantlet wedge
    # hatch + periscope
    d.ellipse([16, 6, 30, 16], fill=pal["steelD"], outline=OL)
    d.rectangle([32, 2, 37, 8], fill=pal["steelD"], outline=OL)
    # stowage box on the back
    d.rectangle([0, h - 16, 10, h - 4], fill=pal["steelD"], outline=OL)
    return img

def draw_barrel(pal, w=86, h=18):
    """points RIGHT at angle 0; symmetric top/bottom so left aim never
    looks upside-down. Muzzle brake at the end."""
    img = canvas(w, h)
    d = dimg(img)
    cy = h // 2
    d.rounded_rectangle([0, cy - 4, w - 12, cy + 4], radius=3,
                        fill=pal["steel"], outline=OL, width=2)
    d.rectangle([w - 14, cy - 7, w - 2, cy + 7], fill=pal["steelD"],
                outline=OL, width=2)
    d.rectangle([w - 10, cy - 8, w - 7, cy + 8], fill=OL)
    d.rectangle([w - 4, cy - 8, w - 2, cy + 8], fill=OL)
    d.line([(2, cy - 3), (w - 14, cy - 3)], fill=pal["steelL"])
    d.rectangle([0, cy - 6, 8, cy + 6], fill=pal["steelD"], outline=OL, width=2)
    return img

# ------------------------------------------------------------ mini tanks
def mt_rocket(pal):
    img = canvas(38, 30)
    d = dimg(img)
    d.rounded_rectangle([2, 8, 34, 24], radius=4, fill=pal["steelD"],
                        outline=OL, width=2)
    for i, rx in enumerate((8, 18, 28)):
        d.rectangle([rx, 4, rx + 6, 12], fill=pal["steel"], outline=OL)
        d.polygon([(rx, 4), (rx + 3, 0), (rx + 6, 4)], fill=(178, 44, 44))
        d.rectangle([rx, 9, rx + 6, 10], fill=pal["accent"])
    return img

def mt_mg(pal):
    img = canvas(38, 30)
    d = dimg(img)
    d.rounded_rectangle([4, 14, 30, 24], radius=3, fill=pal["steelD"],
                        outline=OL, width=2)
    # two barrels pointing right-up (the aim-able mount)
    d.line([(8, 16), (34, 2)], fill=pal["steel"], width=4)
    d.line([(14, 19), (36, 8)], fill=pal["steel"], width=4)
    d.line([(8, 16), (34, 2)], fill=OL, width=1)
    d.line([(14, 19), (36, 8)], fill=OL, width=1)
    d.rectangle([4, 12, 12, 18], fill=pal["steel"], outline=OL)
    d.rectangle([26, 22, 32, 26], fill=pal["steelD"], outline=OL)
    return img

def mt_ice(pal):
    img = canvas(38, 30)
    d = dimg(img)
    d.rounded_rectangle([4, 12, 32, 26], radius=4, fill=(88, 148, 180),
                        outline=OL, width=2)
    d.rounded_rectangle([4, 12, 32, 18], radius=3, fill=(140, 196, 224))
    # mortar tube up
    d.rounded_rectangle([14, 0, 24, 14], radius=2, fill=(108, 168, 200),
                        outline=OL, width=2)
    d.ellipse([16, 0, 22, 5], fill=(210, 240, 255))
    d.polygon([(6, 12), (10, 6), (14, 12)], fill=(210, 240, 255))
    d.polygon([(24, 12), (28, 6), (32, 12)], fill=(210, 240, 255))
    return img

def mt_magnet(pal):
    img = canvas(38, 30)
    d = dimg(img)
    d.rounded_rectangle([4, 14, 32, 26], radius=4, fill=pal["steelD"],
                        outline=OL, width=2)
    # horseshoe magnet
    d.arc([10, 0, 30, 20], start=180, end=360, fill=(200, 60, 60), width=6)
    d.rectangle([10, 10, 16, 16], fill=(230, 230, 240), outline=OL)
    d.rectangle([24, 10, 30, 16], fill=(60, 60, 70), outline=OL)
    return img

def build_tank():
    out_dirs()
    base = TANK_PAL
    hull = rim(outline(draw_hull(base)))
    save(hull, "r_tank_hull.png")
    save(outline(draw_turret(base)), "r_tank_turret.png")
    save(outline(draw_barrel(base)), "r_tank_barrel.png")
    save(outline(mt_rocket(base)), "r_mt_rocket.png")
    save(outline(mt_mg(base)), "r_mt_mg.png")
    save(outline(mt_ice(base)), "r_mt_ice.png")
    save(outline(mt_magnet(base)), "r_mt_magnet.png")
    # ---------------- skins: palette-swapped hull+turret (real designs)
    skins = dict(
        olive=dict(base, steel=(108, 118, 76), steelD=(66, 72, 48),
                   steelL=(146, 156, 106), accent=(255, 176, 64)),
        dune=dict(base, steel=(168, 138, 92), steelD=(112, 90, 58),
                  steelL=(202, 174, 124), accent=(110, 80, 40)),
        frost=dict(base, steel=(150, 176, 196), steelD=(96, 118, 140),
                   steelL=(196, 218, 236), accent=(60, 140, 200)),
        night=dict(base, steel=(70, 74, 92), steelD=(44, 46, 60),
                   steelL=(104, 110, 132), accent=(120, 220, 255)),
        magma=dict(base, steel=(120, 74, 60), steelD=(78, 46, 38),
                   steelL=(160, 106, 84), accent=(255, 110, 40)),
    )
    for sid, pal in skins.items():
        save(rim(outline(draw_hull(pal))), f"r_skin_{sid}_hull.png")
        save(outline(draw_turret(pal)), f"r_skin_{sid}_turret.png")

# ============================================================================
# PART 2 - THE ENEMIES. Facing LEFT (right-spawned fly toward the tank;
# the engine flips for left-spawned). TWO frames each - nothing static.
# Chassis helpers + compact per-type fns; the place palette tints them.
# ============================================================================

def glass(d, cx, cy, rx, ry, col=(168, 224, 255)):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col, outline=OL)
    d.ellipse([cx - rx + 1, cy - ry + 1, cx - rx + 1 + max(1, rx // 2),
               cy], fill=shade(col, 1.25))

def wing(d, pts, pal):
    d.polygon(pts, fill=pal["dark"], outline=None)
    d.polygon([(pts[0][0], pts[0][1] + 2)] + pts[1:], fill=pal["mid"])
    d.line(pts + [pts[0]], fill=OL, width=2)

def exhaust(d, x, y, col, f):
    r = 3 + f
    gl(d, x, y, r + 3, col, 2)
    d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 240, 190))

def plane_chassis(d, w, h, pal, f, sweep=6, twin=False, big=False):
    """generic raider plane facing LEFT; f flips the bank."""
    cy = h // 2
    wingLift = -3 + f * 6           # bank wobble between frames
    # far wing (behind fuselage)
    wing(d, [(w - 18, cy - 2), (w - 18 + sweep, cy - 2 - h // 2 + wingLift),
             (w - 6, cy - 2 - h // 2 + wingLift), (w - 2, cy - 4)], pal)
    # tail fin
    d.polygon([(w - 6, cy - 2), (w - 2, cy - h // 2 - 2 + wingLift // 2),
               (w - 12, cy - 3)], fill=pal["mid"])
    # fuselage
    d.polygon([(0, cy), (6, cy - h // 3), (w - 10, cy - h // 3 + 1),
               (w - 1, cy), (w - 10, cy + h // 3 - 1), (6, cy + h // 3)],
              fill=pal["light"])
    d.polygon([(0, cy), (6, cy + h // 3), (w - 10, cy + h // 3 - 1),
               (w - 1, cy)], fill=pal["base"])
    d.line([(0, cy), (6, cy - h // 3)], fill=OL, width=2)
    d.line([(0, cy), (6, cy + h // 3)], fill=OL, width=2)
    d.line([(6, cy - h // 3), (w - 10, cy - h // 3 + 1)], fill=OL, width=2)
    d.line([(w - 10, cy - h // 3 + 1), (w - 1, cy)], fill=OL, width=2)
    d.line([(w - 10, cy + h // 3 - 1), (w - 1, cy)], fill=OL, width=2)
    d.line([(6, cy + h // 3), (0, cy)], fill=OL, width=2)
    # near wing
    wing(d, [(w - 18, cy + 1), (w - 18 + sweep, cy + h // 2 - 2 + wingLift),
             (w - 6, cy + h // 2 - 2 + wingLift), (w - 2, cy + 3)], pal)
    # canopy
    glass(d, w // 3, cy - 1, max(3, w // 9), max(2, h // 7))
    if twin:
        for ey in (cy - h // 3, cy + h // 3):
            exhaust(d, w - 8, ey + 1, pal["accent"], f)
    else:
        exhaust(d, w - 7, cy, pal["accent"], f)
    # nose gun
    d.line([(0, cy), (-4 + f, cy)], fill=OL, width=2)

def heli_chassis(d, w, h, pal, f):
    cy = h // 2 + 2
    # tail boom
    d.polygon([(w - 8, cy - 2), (w - 1, cy - 6), (w - 1, cy + 2),
               (w - 10, cy + 3)], fill=pal["base"])
    d.polygon([(w - 4, cy - 8), (w - 1, cy - 2), (w - 8, cy - 4)],
              fill=pal["mid"])
    # cabin (round nose to the LEFT)
    d.ellipse([2, cy - h // 3, w - 10, cy + h // 3], fill=pal["light"])
    d.chord([2, cy - h // 3, w - 10, cy + h // 3], 90, 270, fill=pal["base"])
    d.ellipse([2, cy - h // 3, w - 10, cy + h // 3], outline=OL, width=2)
    glass(d, 10, cy - 1, 5, h // 5)
    # skids
    d.line([(6, cy + h // 3 + 2), (w - 14, cy + h // 3 + 2)], fill=OL, width=2)
    d.line([(10, cy + h // 3), (8, cy + h // 3 + 2)], fill=OL, width=2)
    d.line([(w - 16, cy + h // 3), (w - 18, cy + h // 3 + 2)], fill=OL)
    # rotor: angle differs per frame (spinning!)
    rx, ry = (w - 12) // 2, cy - h // 3 - 2
    d.line([(rx, cy - h // 3 - 6), (rx, cy - h // 3)], fill=OL, width=2)
    rot = 0.35 if f == 0 else 1.15
    bx = int(math.cos(rot) * (w // 2 - 4))
    by = int(abs(math.sin(rot)) * 3)
    d.line([(rx - bx, cy - h // 3 - 6 + by), (rx + bx, cy - h // 3 - 6 - by)],
           fill=(40, 40, 46), width=3)
    exhaust(d, w - 3, cy - 6, pal["accent"], f)

def build_enemies():
    out_dirs()
    RAIDER = dict(base=(150, 62, 54), mid=(108, 44, 40), light=(184, 88, 72),
                  dark=(64, 26, 24), accent=(255, 150, 80))
    STEEL = dict(base=(110, 118, 130), mid=(76, 82, 94), light=(148, 156, 168),
                 dark=(46, 50, 60), accent=(150, 220, 255))

    def P(pal, f):
        return dict(base=pal["base"], mid=pal["mid"], light=pal["light"],
                    dark=pal["dark"], accent=pal["accent"])

    specs = {}
    # ---------------- shared 12
    def _scout(d, w, h, f):
        cy = h // 2
        lift = -2 + f * 4
        # swept wings (quads with real area)
        for s in (-1, 1):
            d.polygon([(w - 8, cy), (2, cy + s * (h // 2 + 3 + lift)),
                       (10, cy + s * (h // 2 + 5 + lift)), (w - 14, cy + 2)],
                      fill=(150, 58, 46), outline=OL)
        # slim dart fuselage
        d.polygon([(0, cy), (6, cy - 3), (w - 5, cy - 3), (w - 1, cy),
                   (w - 5, cy + 3), (6, cy + 3)], fill=(184, 88, 72))
        d.line([(0, cy), (6, cy - 3)], fill=OL, width=2)
        d.line([(6, cy - 3), (w - 5, cy - 3)], fill=OL, width=2)
        d.line([(w - 5, cy - 3), (w - 1, cy)], fill=OL, width=2)
        d.line([(w - 5, cy + 3), (w - 1, cy)], fill=OL, width=2)
        d.line([(6, cy + 3), (0, cy)], fill=OL, width=2)
        d.ellipse([w - 8, cy - 2, w - 4, cy + 2], fill=(168, 224, 255))
        exhaust(d, w - 3, cy, (255, 150, 80), f)
    specs["scout"] = (26, 14, _scout)
    specs["fighter"] = (34, 18, lambda d, w, h, f: plane_chassis(d, w, h, STEEL, f, sweep=6))
    def _bomber(d, w, h, f):
        pal = dict(base=(140, 84, 44), mid=(98, 58, 30), light=(176, 112, 62),
                   dark=(58, 34, 18), accent=(255, 170, 90))
        plane_chassis(d, w, h, pal, f, sweep=8, twin=True, big=True)
        # bomb bay
        d.rectangle([w // 3, h - 5, w // 3 + 8, h - 2], fill=(40, 26, 14),
                    outline=OL)
    specs["bomber"] = (46, 24, _bomber)
    specs["heli"] = (36, 22, lambda d, w, h, f: heli_chassis(d, w, h,
            dict(base=(150, 90, 40), mid=(104, 60, 26), light=(186, 120, 60),
                 dark=(60, 34, 14), accent=(255, 190, 90)), f))
    def _kam(d, w, h, f):
        pal = dict(base=(178, 52, 92), mid=(126, 34, 62), light=(214, 84, 124),
                   dark=(70, 16, 38), accent=(255, 220, 120))
        cy = h // 2 + 2
        lift = -2 + f * 4
        # delta wings (quads)
        for s in (-1, 1):
            d.polygon([(w - 6, cy), (12, cy + s * (h // 2 + 4 + lift)),
                       (18, cy + s * (h // 2 + 6 + lift)), (w - 10, cy + 2)],
                      fill=pal["mid"], outline=OL)
        # slim body
        d.polygon([(0, cy), (8, cy - 4), (w - 6, cy - 3), (w - 1, cy),
                   (w - 6, cy + 3), (8, cy + 4)], fill=pal["light"])
        d.line([(0, cy), (8, cy - 4)], fill=OL, width=2)
        d.line([(8, cy - 4), (w - 6, cy - 3)], fill=OL, width=2)
        d.line([(w - 6, cy - 3), (w - 1, cy)], fill=OL, width=2)
        d.line([(w - 6, cy + 3), (w - 1, cy)], fill=OL, width=2)
        d.line([(8, cy + 4), (0, cy)], fill=OL, width=2)
        # warhead tip
        d.polygon([(0, cy), (7, cy - 4), (7, cy + 4)], fill=(255, 220, 60))
        exhaust(d, w - 3, cy, pal["accent"], f)
    specs["kamikaze"] = (24, 12, _kam)
    def _gun(d, w, h, f):
        pal = dict(base=(96, 104, 78), mid=(64, 70, 50), light=(130, 140, 106),
                   dark=(38, 42, 30), accent=(255, 210, 120))
        plane_chassis(d, w, h, pal, f, sweep=9, twin=True, big=True)
        d.line([(4, h // 2 + 4), (12, h // 2 + 8)], fill=OL, width=3)
    specs["gunship"] = (44, 22, _gun)
    def _shield(d, w, h, f):
        pal = dict(base=(86, 130, 168), mid=(58, 92, 126), light=(120, 164, 202),
                   dark=(34, 52, 74), accent=(136, 221, 255))
        plane_chassis(d, w - 8, h, pal, f, sweep=5)
        # shield dome arc
        d.arc([-6, -4, w - 2, h + 4], start=200, end=340,
              fill=(150, 220, 255), width=3)
    specs["shielded"] = (32, 18, _shield)
    def _split(d, w, h, f):
        pal = dict(base=(150, 74, 176), mid=(104, 46, 126), light=(190, 108, 214),
                   dark=(64, 22, 80), accent=(230, 150, 255))
        r = w // 2
        wob = 1 if f == 0 else -1
        d.ellipse([2 + wob, 3, 2 + w, 3 + h], fill=pal["base"])
        d.chord([2 + wob, 3, 2 + w, 3 + h], 180, 360, fill=pal["light"])
        d.ellipse([2 + wob, 3, 2 + w, 3 + h], outline=OL, width=2)
        # the split seam
        d.line([(2 + w // 2 + wob, 3), (2 + w // 2 + wob, 3 + h)],
               fill=pal["dark"], width=2)
        d.ellipse([2 + w // 2 - 3, 3 + h // 2 - 3, 2 + w // 2 + 3,
                   3 + h // 2 + 3], fill=pal["accent"], outline=OL)
    specs["splitter"] = (26, 24, _split)
    def _missile(d, w, h, f):
        pal = dict(base=(168, 76, 104), mid=(120, 50, 72), light=(200, 106, 136),
                   dark=(64, 24, 40), accent=(255, 120, 90))
        cy = h // 2
        d.polygon([(0, cy), (6, cy - 5), (w - 8, cy - 6), (w - 1, cy),
                   (w - 8, cy + 6), (6, cy + 5)], fill=pal["light"])
        d.line([(0, cy), (6, cy - 5)], fill=OL, width=2)
        d.line([(6, cy - 5), (w - 8, cy - 6)], fill=OL, width=2)
        d.line([(w - 8, cy - 6), (w - 1, cy)], fill=OL, width=2)
        d.line([(w - 8, cy + 6), (w - 1, cy)], fill=OL, width=2)
        d.line([(6, cy + 5), (0, cy)], fill=OL, width=2)
        d.polygon([(2, cy - 5), (8, cy - h + 2), (12, cy - 5)],
                  fill=pal["mid"], outline=OL)
        d.polygon([(2, cy + 5), (8, cy + h - 2), (12, cy + 5)],
                  fill=pal["mid"], outline=OL)
        glass(d, w - 8, cy, 3, 3)
        exhaust(d, 2, cy, pal["accent"], f)
    specs["missile"] = (30, 16, _missile)
    def _swarm(d, w, h, f):
        pal = dict(base=(150, 200, 80), mid=(104, 146, 52), light=(190, 232, 116),
                   dark=(52, 74, 26), accent=(220, 255, 140))
        wob = 1 if f == 0 else -1
        cx, cy = w // 2, h // 2
        d.ellipse([cx - 5, cy - 4 + wob, cx + 5, cy + 5 + wob],
                  fill=pal["light"], outline=OL, width=2)
        for s in (-1, 1):
            d.line([(cx, cy + s * 2), (cx - s * 7, cy + s * 6 + wob)],
                   fill=pal["mid"], width=2)
        d.ellipse([cx - 1, cy - 1 + wob, cx + 2, cy + 2 + wob],
                  fill=pal["accent"])
    specs["swarm"] = (16, 12, _swarm)
    def _gtank(d, w, h, f):
        pal = dict(base=(122, 86, 66), mid=(84, 58, 44), light=(156, 116, 90),
                   dark=(44, 30, 24), accent=(255, 160, 80))
        cy = h // 2
        d.rounded_rectangle([2, cy + 2, w - 2, h - 2], radius=3,
                            fill=pal["dark"], outline=OL, width=2)
        for i in range(4):
            d.ellipse([6 + i * (w - 16) // 4, cy + 4,
                       12 + i * (w - 16) // 4, h - 4], fill=pal["mid"])
        d.polygon([(6, cy + 2), (12, cy - 6), (w - 12, cy - 6), (w - 6, cy + 2)],
                  fill=pal["light"])
        d.line([(6, cy + 2), (12, cy - 6)], fill=OL, width=2)
        d.line([(12, cy - 6), (w - 12, cy - 6)], fill=OL, width=2)
        d.line([(w - 12, cy - 6), (w - 6, cy + 2)], fill=OL, width=2)
        # barrel points left
        a = -8 + f * 4
        d.line([(14, cy - 3), (-6, cy - 3 + a)], fill=OL, width=4)
        d.line([(14, cy - 3), (-6, cy - 3 + a)], fill=pal["mid"], width=2)
    specs["gtank"] = (40, 24, _gtank)
    def _turret(d, w, h, f):
        pal = dict(base=(120, 124, 116), mid=(84, 88, 82), light=(152, 158, 148),
                   dark=(44, 46, 42), accent=(255, 170, 90))
        cx, cy = w // 2, h // 2 + 2
        d.polygon([(cx - 12, h - 2), (cx - 8, cy - 4), (cx + 8, cy - 4),
                   (cx + 12, h - 2)], fill=pal["mid"])
        d.line([(cx - 12, h - 2), (cx - 8, cy - 4)], fill=OL, width=2)
        d.line([(cx - 8, cy - 4), (cx + 8, cy - 4)], fill=OL, width=2)
        d.line([(cx + 8, cy - 4), (cx + 12, h - 2)], fill=OL, width=2)
        d.ellipse([cx - 8, cy - 9, cx + 8, cy + 5], fill=pal["light"],
                  outline=OL, width=2)
        a = -6 + f * 5
        d.line([(cx, cy - 2), (cx - 16, cy - 2 + a)], fill=OL, width=4)
        d.line([(cx, cy - 2), (cx - 16, cy - 2 + a)], fill=pal["mid"], width=2)
    specs["turret"] = (30, 22, _turret)

    # ---------------- place exclusives (palette rides the place)
    EX = [
        ("hauler",    "iron",    40, 26),
        ("dustdevil", "mesa",    26, 30),
        ("frostmoth", "tundra",  34, 22),
        ("cinderbat", "volcano", 30, 20),
        ("sporewasp", "swamp",   28, 18),
        ("shardray",  "crystal", 36, 20),
        ("cloudray",  "sky",     40, 20),
        ("deptheel",  "trench",  44, 16),
        ("holodrone", "neon",    26, 24),
        ("voidmaw",   "void",    32, 28),
    ]
    def place_pal(pl):
        a = pl["accent"]
        m = shade(a, 0.62)
        return dict(base=shade(a, 0.82), mid=m, light=shade(a, 1.05),
                    dark=shade(a, 0.38), accent=a)

    def _hauler(d, w, h, f):
        pal = place_pal(PLACES[0])
        heli_chassis(d, w, h, pal, f)
        # cargo claw under
        d.line([(w // 2 - 2, h - 4), (w // 2 - 2, h + 2)], fill=OL, width=2)
        d.rectangle([w // 2 - 6, h + 2, w // 2 + 4, h + 5],
                    fill=pal["mid"], outline=OL)
    def _dustdevil(d, w, h, f):
        pal = place_pal(PLACES[1])
        cx, cy = w // 2, h // 2
        for i, r in enumerate((12, 9, 6)):
            off = (f * 2 - 1) * (i + 1)
            d.ellipse([cx - r + off, cy - r, cx + r + off, cy + r],
                      outline=pal["light"], width=2)
        d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=pal["accent"])
    def _frostmoth(d, w, h, f):
        pal = place_pal(PLACES[2])
        cy = h // 2
        lift = -3 + f * 5
        # big icy wings: quads, pale blue with white frost face
        for s in (-1, 1):
            d.polygon([(w - 12, cy), (4, cy + s * (h // 2 + 4 + lift)),
                       (12, cy + s * (h // 2 + 7 + lift)), (w - 16, cy + 2)],
                      fill=(120, 170, 210), outline=OL)
            d.polygon([(w - 14, cy + s), (10, cy + s * (h // 2 + lift)),
                       (16, cy + s * (h // 2 + 3 + lift)), (w - 18, cy + s * 2)],
                      fill=(210, 236, 252))
        d.ellipse([w - 16, cy - 5, w - 2, cy + 5], fill=(90, 130, 170),
                  outline=OL, width=2)
        d.ellipse([w - 13, cy - 3, w - 5, cy + 3], fill=(210, 236, 252))
        d.ellipse([w - 11, cy - 1, w - 8, cy + 2], fill=pal["accent"])
    def _cinderbat(d, w, h, f):
        pal = place_pal(PLACES[3])
        cy = h // 2
        lift = -3 + f * 6
        # big membrance wings with bone struts (bright on dark body)
        wing_col = (255, 120, 50)
        for s in (-1, 1):
            d.polygon([(w - 14, cy), (w - 18, cy + s * 3),
                       (2, cy + s * (h // 2 + lift)),
                       (w - 22, cy + s * 2)], fill=(70, 16, 10))
            d.polygon([(w - 14, cy), (6, cy + s * (h // 2 + lift)),
                       (w - 18, cy + s * 2)], fill=wing_col)
            d.line([(w - 14, cy), (6, cy + s * (h // 2 + lift))],
                   fill=OL, width=2)
            d.line([(w - 18, cy + s * (h // 2 + lift)), (w - 20, cy + s * 2)],
                   fill=(70, 16, 10), width=2)
        # chunky body
        d.ellipse([w - 20, cy - 5, w - 2, cy + 5], fill=(60, 12, 8),
                  outline=OL, width=2)
        d.ellipse([w - 17, cy - 3, w - 5, cy + 3], fill=wing_col)
        d.ellipse([w - 13, cy - 1, w - 9, cy + 2], fill=(255, 220, 140))
    def _sporewasp(d, w, h, f):
        pal = place_pal(PLACES[4])
        cy = h // 2
        # abdomen with stinger
        d.ellipse([w // 2 - 2, cy - 6, w - 2, cy + 6], fill=pal["base"],
                  outline=OL, width=2)
        for sx in (w // 2 + 4, w // 2 + 10, w // 2 + 16):
            d.line([(sx, cy - 5), (sx, cy + 5)], fill=pal["dark"], width=2)
        d.polygon([(w - 4, cy - 2), (w + 4, cy), (w - 4, cy + 2)],
                  fill=(200, 255, 120))
        # thorax + head
        d.ellipse([w // 2 - 12, cy - 5, w // 2 + 2, cy + 5],
                  fill=pal["light"], outline=OL, width=2)
        d.ellipse([w // 2 - 17, cy - 4, w // 2 - 8, cy + 4],
                  fill=pal["dark"], outline=OL)
        d.ellipse([w // 2 - 15, cy - 2, w // 2 - 12, cy + 1],
                  fill=pal["accent"])
        wingLift = -2 + f * 3
        d.ellipse([w // 2 - 10, cy - 12 + wingLift, w // 2 + 2, cy - 4 + wingLift],
                  fill=(225, 245, 205), outline=OL)
        d.ellipse([w // 2 - 6, cy + 4 - wingLift, w // 2 + 6, cy + 12 - wingLift],
                  fill=(225, 245, 205), outline=OL)
    def _shardray(d, w, h, f):
        pal = place_pal(PLACES[5])
        cy = h // 2
        lift = -3 + f * 5
        d.polygon([(0, cy), (w // 2, cy - 5), (w - 4, cy), (w // 2, cy + 5)],
                  fill=pal["light"])
        d.line([(0, cy), (w // 2, cy - 5)], fill=OL, width=2)
        d.line([(w // 2, cy - 5), (w - 4, cy)], fill=OL, width=2)
        d.line([(w // 2, cy + 5), (w - 4, cy)], fill=OL, width=2)
        d.line([(0, cy), (w // 2, cy + 5)], fill=OL, width=2)
        for s in (-1, 1):
            d.polygon([(w - 12, cy), (w - 18, cy + s * (h + lift)),
                       (w - 26, cy + s * 3)], fill=pal["base"], outline=OL)
        d.ellipse([w - 8, cy - 2, w - 2, cy + 2], fill=pal["accent"])
    def _cloudray(d, w, h, f):
        pal = place_pal(PLACES[6])
        cy = h // 2
        lift = -2 + f * 4
        d.polygon([(0, cy), (8, cy - 4), (w - 10, cy - 5), (w - 1, cy),
                   (w - 10, cy + 5), (8, cy + 4)], fill=pal["light"])
        for x, y in [(0, cy), (8, cy - 4), (w - 10, cy - 5), (w - 1, cy),
                     (w - 10, cy + 5), (8, cy + 4)]:
            pass
        for a, b in [((0, cy), (8, cy - 4)), ((8, cy - 4), (w - 10, cy - 5)),
                     ((w - 10, cy - 5), (w - 1, cy)),
                     ((w - 1, cy), (w - 10, cy + 5)),
                     ((w - 10, cy + 5), (8, cy + 4)), ((8, cy + 4), (0, cy))]:
            d.line([a, b], fill=OL, width=2)
        for s in (-1, 1):
            d.polygon([(w - 16, cy), (w - 22, cy + s * (h // 2 + lift)),
                       (w - 30, cy + s * 2)], fill=pal["base"], outline=OL)
        glass(d, w - 12, cy, 3, 2)
    def _deptheel(d, w, h, f):
        pal = place_pal(PLACES[7])
        cy = h // 2
        pts = []
        for i in range(7):
            x = 4 + i * (w - 10) // 6
            y = cy + int(math.sin(i * 1.1 + f * math.pi) * 4)
            pts.append((x, y))
        for i in range(len(pts) - 1):
            d.line([pts[i], pts[i + 1]], fill=pal["base"], width=6)
            d.line([pts[i], pts[i + 1]], fill=pal["mid"], width=2)
        for x, y in pts:
            d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=pal["light"])
        hx, hy = pts[-1]
        d.ellipse([hx - 5, hy - 5, hx + 5, hy + 5], fill=pal["light"],
                  outline=OL, width=2)
        d.ellipse([hx - 7, hy - 3, hx - 4, hy - 1], fill=pal["accent"])
        d.polygon([(hx - 2, hy + 3), (hx - 6, hy + 6), (hx + 1, hy + 6)],
                  fill=(255, 255, 255))
    def _holodrone(d, w, h, f):
        pal = place_pal(PLACES[8])
        cx, cy = w // 2, h // 2
        r = 9
        spin = f * 2
        d.polygon([(cx - r, cy - r + spin), (cx + r, cy - r - spin),
                   (cx + r, cy + r - spin), (cx - r, cy + r + spin)],
                  fill=(*pal["base"][:3], 150), outline=pal["light"])
        d.line([(cx - r, cy - r + spin), (cx + r, cy + r - spin)],
               fill=pal["light"])
        d.line([(cx - r, cy + r + spin), (cx + r, cy - r - spin)],
               fill=pal["light"])
        d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=pal["accent"])
    def _voidmaw(d, w, h, f):
        pal = place_pal(PLACES[9])
        cx, cy = w // 2, h // 2
        r = 11 + f
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(20, 6, 40),
                  outline=pal["light"], width=2)
        d.ellipse([cx - r + 3, cy - r + 3, cx + r - 3, cy + r - 3],
                  outline=pal["mid"])
        # the maw: teeth ring
        for i in range(8):
            a = i * math.pi / 4 + f * 0.4
            tx, ty = cx + int(math.cos(a) * (r - 4)), cy + int(math.sin(a) * (r - 4))
            d.polygon([(tx - 1, ty - 1), (tx + 2, ty), (tx - 1, ty + 2)],
                      fill=(240, 240, 255))
        d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=pal["accent"])
    ex_fns = dict(hauler=_hauler, dustdevil=_dustdevil, frostmoth=_frostmoth,
                  cinderbat=_cinderbat, sporewasp=_sporewasp,
                  shardray=_shardray, cloudray=_cloudray, deptheel=_deptheel,
                  holodrone=_holodrone, voidmaw=_voidmaw)
    for name, pkey, w, h in EX:
        pl = next(p for p in PLACES if p["key"] == pkey)
        specs[name] = (w, h, (lambda fn, pl_: (lambda d, ww, hh, f:
                fn(d, ww, hh, f)))(ex_fns[name], pl))

    for name, (w, h, fn) in specs.items():
        for f in (0, 1):
            img = canvas(w + 10, h + 14)
            d = dimg(img)
            fn(d, w, h, f)
            save(outline(img), f"enemies/r_e_{name}{f}.png")

# ============================================================================
# PART 3 - THE 10 BOSSES (the owner: "work hard on the designs"). Facing
# LEFT. 2 frames each. Each one is a MULTI-PART machine with plates, glows
# and weapon pods - silhouettes must read at 350+ design px.
# ============================================================================

def plates(d, pts, col, hi, lo):
    d.polygon(pts, fill=col)
    d.line(pts + [pts[0]], fill=OL, width=2)
    # top bevel
    d.line([pts[0], pts[1]], fill=hi, width=2)
    d.line([pts[-1], pts[0]], fill=lo, width=2)

def rivets(d, cx, cy, rx, ry, n, col=(210, 216, 226)):
    for i in range(n):
        a = i * TAU2 / n
        d.ellipse([cx + int(math.cos(a) * rx) - 1, cy + int(math.sin(a) * ry) - 1,
                   cx + int(math.cos(a) * rx) + 1, cy + int(math.sin(a) * ry) + 1],
                  fill=col)

TAU2 = math.pi * 2

def pod_gun(d, x, y, col, len_=14, dirx=-1):
    d.rounded_rectangle([x - 3, y - 3, x + 3, y + 3], radius=2, fill=col,
                        outline=OL)
    d.line([(x, y), (x + dirx * len_, y)], fill=OL, width=4)
    d.line([(x, y), (x + dirx * len_, y)], fill=(50, 52, 60), width=2)

def boss_common(img, glow_col, f):
    """engine glow flicker per frame"""
    return img

def build_bosses():
    out_dirs()

    def finish(img, name):
        for f in (0, 1):
            save(outline(img), f"bosses/r_b_{name}{f}.png")
            # frame B: cheap livelong shimmer - shift accent pixels is enough
            # (real frame differences are drawn per-boss below)

    # ---- 01 SCRAP COLOSSUS (IRON WASTELAND) - flying scrap fortress
    def colossus(f):
        w, h = 104, 64
        img = canvas(w, h)
        d = dimg(img)
        cy = h // 2
        tilt = f  # hover bob baked into frames
        # wings (scrap slabs)
        for s in (-1, 1):
            plates(d, [(34, cy + s * 6), (6, cy + s * 24 + tilt),
                       (2, cy + s * 30 + tilt), (30, cy + s * 12)],
                   (88, 70, 56), (128, 104, 82), (54, 42, 34))
        # fuselage: armored barge
        plates(d, [(4, cy), (16, cy - 16), (58, cy - 20 - tilt),
                   (86, cy - 10), (100, cy), (86, cy + 12),
                   (58, cy + 20 - tilt), (16, cy + 16)],
               (116, 94, 74), (156, 128, 100), (66, 52, 40))
        # scrap plating lines
        d.line([(30, cy - 16), (30, cy + 16)], fill=(66, 52, 40), width=2)
        d.line([(56, cy - 18), (56, cy + 18)], fill=(66, 52, 40), width=2)
        rivets(d, 42, cy, 10, 14, 6)
        rivets(d, 72, cy, 10, 9, 5)
        # bridge + eye
        d.rectangle([78, cy - 12, 92, cy - 4], fill=(88, 70, 56), outline=OL)
        d.ellipse([82, cy - 4, 92, cy + 4], fill=(255, 120, 50), outline=OL)
        d.ellipse([85, cy - 2, 88, cy + 1], fill=(255, 230, 180))
        # gun pods under
        pod_gun(d, 44, cy + 18 - tilt, (70, 56, 44), 12)
        pod_gun(d, 68, cy + 14 - tilt, (70, 56, 44), 12)
        # engine glows
        for s in (-1, 1):
            gl(d, 6, cy + s * 27 + tilt, 5 + f, (255, 150, 60), 2)
        return img

    # ---- 02 DUST REAVER (SCORCHED MESA) - the sidewinder dart
    def reaver(f):
        w, h = 96, 44
        img = canvas(w, h)
        d = dimg(img)
        cy = h // 2
        lift = -2 + f * 4
        # big swept wings
        for s in (-1, 1):
            plates(d, [(66, cy), (20, cy + s * (h // 2 + lift)),
                       (30, cy + s * (h // 2 + 4 + lift)), (72, cy + s * 3)],
                   (172, 96, 52), (216, 132, 76), (108, 58, 30))
        # fuselage: needle
        plates(d, [(0, cy), (14, cy - 6), (64, cy - 8), (92, cy - 2),
                   (92, cy + 2), (64, cy + 8), (14, cy + 6)],
               (196, 116, 60), (232, 152, 88), (120, 66, 32))
        # canopy
        glass(d, 30, cy - 1, 8, 4)
        # tail blades
        for s in (-1, 1):
            plates(d, [(90, cy), (80, cy + s * (h // 2 - 2 + lift)),
                       (84, cy + s * (h // 2 + lift)), (92, cy + s * 2)],
                   (172, 96, 52), (216, 132, 76), (108, 58, 30))
        # twin guns at nose
        d.line([(0, cy - 2), (-8, cy - 2)], fill=OL, width=3)
        d.line([(0, cy + 2), (-8, cy + 2)], fill=OL, width=3)
        gl(d, 90, cy, 5 + f, (255, 190, 90), 2)
        return img

    # ---- 03 GLACIER TITAN (FROZEN TUNDRA) - armored dropship
    def titan(f):
        w, h = 108, 62
        img = canvas(w, h)
        d = dimg(img)
        cy = h // 2
        tilt = f
        # rotor pods on top
        for rx in (30, 78):
            d.rectangle([rx - 8, cy - 26, rx + 8, cy - 14],
                        fill=(96, 124, 150), outline=OL)
            rot = 0.4 + f * 1.1
            bx = int(math.cos(rot) * 12)
            d.line([(rx - bx, cy - 28), (rx + bx, cy - 28)],
                   fill=(210, 236, 252), width=3)
        # main hull: armored wedge
        plates(d, [(6, cy), (22, cy - 14), (78, cy - 16 - tilt),
                   (100, cy - 4), (100, cy + 6), (78, cy + 16 - tilt),
                   (22, cy + 14)],
               (120, 152, 178), (168, 200, 224), (70, 94, 118))
        rivets(d, 50, cy, 20, 10, 8)
        # ice plating
        d.polygon([(34, cy - 12), (52, cy - 12 - tilt), (52, cy + 12 - tilt),
                   (34, cy + 12)], fill=(168, 200, 224), outline=OL)
        # cockpit
        glass(d, 88, cy - 2, 8, 5)
        # bomb bay (open, icy glow)
        d.rectangle([38, cy + 12, 62, cy + 18], fill=(30, 44, 60), outline=OL)
        gl(d, 50, cy + 16, 4 + f, (150, 220, 255), 2)
        # side cannons
        pod_gun(d, 24, cy + 12, (96, 124, 150), 14)
        pod_gun(d, 24, cy - 12, (96, 124, 150), 14)
        gl(d, 8, cy, 5 + f, (150, 220, 255), 2)
        return img

    # ---- 04 MAGMA HEART (VOLCANIC CORE) - floating forge fortress
    def magma(f):
        w, h = 100, 72
        img = canvas(w, h)
        d = dimg(img)
        cx, cy = w // 2, h // 2
        puls = f
        # outer obsidian ring
        d.ellipse([cx - 48, cy - 34, cx + 48, cy + 34], fill=(46, 20, 16),
                  outline=OL)
        d.ellipse([cx - 40, cy - 27, cx + 40, cy + 27], outline=(90, 40, 30),
                  width=2)
        rivets(d, cx, cy, 44, 30, 10, (120, 70, 50))
        # magma core
        gl(d, cx, cy, 20 + puls * 3, (255, 90, 20), 3)
        d.ellipse([cx - 16, cy - 14, cx + 16, cy + 14], fill=(255, 120, 30),
                  outline=OL)
        d.ellipse([cx - 8, cy - 7, cx + 8, cy + 7], fill=(255, 220, 120))
        # cracks to the rim
        for i in range(6):
            a = i * TAU2 / 6 + 0.3
            d.line([(cx + int(math.cos(a) * 16), cy + int(math.sin(a) * 12)),
                    (cx + int(math.cos(a) * 42), cy + int(math.sin(a) * 28))],
                   fill=(255, 90, 20), width=2)
        # obsidian shoulder pods
        for s in (-1, 1):
            d.polygon([(cx - 30, cy + s * 22), (cx - 46, cy + s * 30),
                       (cx - 34, cy + s * 34), (cx - 22, cy + s * 26)],
                      fill=(60, 26, 20), outline=OL)
        pod_gun(d, cx + 34, cy - 26, (60, 26, 20), 12)
        pod_gun(d, cx + 34, cy + 26, (60, 26, 20), 12)
        return img

    # ---- 05 SPORE MOTHER (TOXIC SWAMP) - hive flyer
    def sporemother(f):
        w, h = 96, 60
        img = canvas(w, h)
        d = dimg(img)
        cx, cy = w // 2, h // 2
        lift = -2 + f * 4
        # membrane wings (big, veined)
        for s in (-1, 1):
            d.polygon([(cx + 4, cy), (10, cy + s * (h // 2 + 4 + lift)),
                       (2, cy + s * (h // 2 - 2 + lift)), (cx - 12, cy + s * 6)],
                      fill=(96, 146, 70), outline=OL)
            d.polygon([(cx, cy + s * 2), (18, cy + s * (h // 2 + lift)),
                       (cx - 8, cy + s * 8)], fill=(146, 196, 106))
            d.line([(cx, cy), (14, cy + s * (h // 2 - 2 + lift))],
                   fill=(60, 90, 40), width=2)
        # bloated abdomen (segmented)
        d.ellipse([cx - 10, cy - 16, cx + 42, cy + 16], fill=(120, 170, 86),
                  outline=OL)
        for i, sx in enumerate((6, 16, 26)):
            d.arc([cx + sx - 6, cy - 15, cx + sx + 6, cy + 15], 60, 300,
                  fill=(70, 104, 44), width=3)
        # pods on the back
        for px in (18, 32):
            d.ellipse([cx + px - 4, cy - 20, cx + px + 4, cy - 12],
                      fill=(190, 232, 130), outline=OL)
        # head + mandibles
        d.ellipse([cx - 24, cy - 8, cx - 6, cy + 8], fill=(70, 104, 44),
                  outline=OL)
        d.ellipse([cx - 21, cy - 4, cx - 16, cy + 1], fill=(220, 255, 140))
        for s in (-1, 1):
            d.polygon([(cx - 26, cy + s * 4), (cx - 36, cy + s * 8),
                       (cx - 25, cy + s * 8)], fill=(220, 255, 140), outline=OL)
        gl(d, cx + 44, cy, 4 + f, (190, 255, 120), 2)
        return img

    # ---- 06 PRISM WARDEN (CRYSTAL CAVERNS) - floating crystal construct
    def prism(f):
        w, h = 88, 76
        img = canvas(w, h)
        d = dimg(img)
        cx, cy = w // 2, h // 2
        rot = f * 3
        # outer crystal shards orbiting
        for i in range(6):
            a = i * TAU2 / 6 + rot
            sx, sy = cx + int(math.cos(a) * 34), cy + int(math.sin(a) * 30)
            sz = 7 + (i % 2) * 3
            d.polygon([(sx, sy - sz), (sx + sz - 2, sy), (sx, sy + sz),
                       (sx - sz + 2, sy)], fill=(150, 88, 214), outline=OL)
            d.polygon([(sx, sy - sz), (sx + sz - 2, sy), (sx, sy)],
                      fill=(210, 150, 255))
        # central prism (tall diamond)
        plates(d, [(cx, cy - 30), (cx + 18, cy - 8), (cx + 14, cy + 22),
                   (cx, cy + 34), (cx - 14, cy + 22), (cx - 18, cy - 8)],
               (120, 62, 180), (190, 120, 255), (70, 34, 110))
        # inner light
        gl(d, cx, cy - 2, 8 + f * 2, (220, 150, 255), 3)
        d.line([(cx, cy - 26), (cx, cy + 28)], fill=(230, 180, 255), width=2)
        # floating shards under
        for sx in (cx - 22, cx + 22):
            d.polygon([(sx, cy + 26), (sx + 5, cy + 34), (sx, cy + 42),
                       (sx - 5, cy + 34)], fill=(150, 88, 214), outline=OL)
        return img

    # ---- 07 STORM CARRIER (SKY ARCHIPELAGO) - broad wing carrier
    def carrier(f):
        w, h = 116, 52
        img = canvas(w, h)
        d = dimg(img)
        cy = h // 2
        lift = -2 + f * 4
        # huge wings
        for s in (-1, 1):
            plates(d, [(76, cy - 2), (14, cy + s * (h // 2 + 6 + lift)),
                       (4, cy + s * (h // 2 + 2 + lift)), (70, cy + s * 4)],
                   (150, 170, 196), (196, 214, 236), (96, 112, 134))
        # hull: wide fuselage
        plates(d, [(0, cy), (12, cy - 9), (84, cy - 11 - tilt0(f)),
                   (108, cy - 3), (108, cy + 3), (84, cy + 11 - tilt0(f)),
                   (12, cy + 9)],
               (170, 188, 212), (214, 228, 246), (110, 124, 146))
        rivets(d, 60, cy, 24, 6, 7, (240, 246, 252))
        # deck stripe
        d.rectangle([16, cy - 2, 86, cy + 2], fill=(240, 246, 252))
        d.line([(16, cy), (86, cy)], fill=(150, 170, 196), width=1)
        # cockpit
        glass(d, 100, cy - 2, 6, 4)
        # under pods + props
        for px in (30, 56, 82):
            d.rounded_rectangle([px - 4, cy + 8, px + 4, cy + 16], radius=2,
                                fill=(150, 170, 196), outline=OL)
            rot = 0.5 + f * 1.2
            bx = int(math.cos(rot) * 8)
            d.line([(px - bx, cy + 18), (px + bx, cy + 18)],
                   fill=(240, 246, 252), width=2)
        gl(d, 4, cy, 4 + f, (255, 240, 170), 2)
        return img

    def tilt0(f):
        return f  # hover bob helper

    # ---- 08 ABYSS LEVIATHAN (ABYSSAL TRENCH) - segmented serpent
    def leviathan(f):
        w, h = 120, 44
        img = canvas(w, h)
        d = dimg(img)
        cy = h // 2
        # body segments (tail to head), sine wave phase differs per frame
        segs = []
        for i in range(9):
            x = 6 + i * 13
            y = cy + int(math.sin(i * 0.8 + f * math.pi) * 6)
            segs.append((x, y, 10 - abs(i - 8) * 0 + (4 if i < 3 else 0)))
        for i in range(len(segs) - 1, -1, -1):
            x, y, r = segs[i][0], segs[i][1], segs[i][2]
            rr = 5 + (i * 8) // 9
            col = (30, 70, 110) if i % 2 == 0 else (38, 86, 132)
            d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=col, outline=OL)
            d.ellipse([x - rr + 2, y - rr + 2, x + rr - 2, y],
                      fill=(52, 110, 164))
            # dorsal fin spikes
            if i % 2 == 0:
                d.polygon([(x, y - rr), (x + 3, y - rr - 6), (x + 5, y - rr)],
                          fill=(68, 238, 255), outline=OL)
        # head
        hx, hy = segs[-1][0] + 12, segs[-1][1]
        d.polygon([(hx - 8, hy - 8), (hx + 14, hy - 4), (hx + 18, hy),
                   (hx + 14, hy + 4), (hx - 8, hy + 8)], fill=(44, 96, 146),
                  outline=OL)
        d.ellipse([hx + 4, hy - 4, hx + 12, hy + 2], fill=(68, 238, 255))
        # jaw teeth
        for k in range(4):
            d.polygon([(hx - 4 + k * 5, hy + 4), (hx - 2 + k * 5, hy + 9),
                       (hx + 1 + k * 5, hy + 4)], fill=(240, 250, 255))
        gl(d, hx - 10, hy, 4 + f, (68, 238, 255), 2)
        return img

    # ---- 09 GRID SOVEREIGN (NEON SPRAWL) - the cyber prism
    def sovereign(f):
        w, h = 96, 68
        img = canvas(w, h)
        d = dimg(img)
        cx, cy = w // 2, h // 2
        spin = f * 3
        # hexagonal core body
        hexpts = [(cx + int(math.cos(a + spin * 0.1) * 30),
                   cy + int(math.sin(a + spin * 0.1) * 26))
                  for a in [i * TAU2 / 6 for i in range(6)]]
        d.polygon(hexpts, fill=(30, 10, 52), outline=(255, 68, 204))
        for p0, p1 in zip(hexpts, hexpts[1:] + hexpts[:1]):
            d.line([p0, p1], fill=(255, 68, 204), width=2)
        # inner triangle core
        tri = [(cx + int(math.cos(a + spin * 0.2) * 14),
                cy + int(math.sin(a + spin * 0.2) * 12))
               for a in [i * TAU2 / 3 for i in range(3)]]
        d.polygon(tri, fill=(90, 20, 70), outline=(255, 140, 220))
        gl(d, cx, cy, 7 + f * 2, (255, 68, 204), 3)
        # data wing bars left/right
        for s in (-1, 1):
            for k in range(3):
                bx = cx + s * (36 + k * 8)
                by = cy - 12 + k * 12 + (f if k % 2 else -f)
                d.rectangle([bx - 3, by - 8, bx + 3, by + 8],
                            fill=(52, 18, 80), outline=(255, 68, 204))
                d.rectangle([bx - 1, by - 6, bx + 1, by + 6],
                            fill=(255, 120, 220))
        # antenna
        d.line([(cx, cy - 26), (cx, cy - 34)], fill=(255, 68, 204), width=2)
        d.ellipse([cx - 2, cy - 37, cx + 2, cy - 33], fill=(255, 220, 240))
        return img

    # ---- 10 THE NULL AVATAR (THE VOID) - the prime
    def avatar(f):
        w, h = 110, 74
        img = canvas(w, h)
        d = dimg(img)
        cx, cy = w // 2, h // 2
        tilt = f
        # void wings (energy sheets)
        for s in (-1, 1):
            d.polygon([(cx + 8, cy), (12, cy + s * (h // 2 + 2 + tilt)),
                       (2, cy + s * (h // 2 - 4 + tilt)), (cx - 14, cy + s * 10)],
                      fill=(36, 12, 66), outline=(120, 60, 200))
            d.polygon([(cx + 2, cy + s * 4), (22, cy + s * (h // 2 + tilt)),
                       (cx - 10, cy + s * 8)], fill=(70, 28, 120))
        # armored core hull
        plates(d, [(cx - 40, cy), (cx - 24, cy - 14), (cx + 16, cy - 16 - tilt),
                   (cx + 44, cy - 4), (cx + 50, cy), (cx + 44, cy + 6),
                   (cx + 16, cy + 16 - tilt), (cx - 24, cy + 14)],
               (48, 20, 88), (96, 48, 160), (26, 10, 50))
        rivets(d, cx - 6, cy, 18, 9, 8, (150, 100, 220))
        # the three eyes of the null
        for ex, er in ((cx + 26, 6), (cx + 2, 4), (cx - 18, 3)):
            gl(d, ex, cy - 2, er + 2 + f, (200, 120, 255), 2)
            d.ellipse([ex - er, cy - 2 - er, ex + er, cy - 2 + er],
                      fill=(240, 220, 255), outline=OL)
            d.ellipse([ex - 1, cy - 3, ex + 1, cy - 1], fill=(40, 10, 80))
        # crown spikes
        for k in range(5):
            sx = cx - 20 + k * 10
            d.polygon([(sx - 3, cy - 16 - tilt), (sx, cy - 26 - tilt - f * 2),
                       (sx + 3, cy - 16 - tilt)], fill=(170, 68, 255),
                      outline=OL)
        # under cannons
        pod_gun(d, cx - 20, cy + 14 - tilt, (48, 20, 88), 14)
        pod_gun(d, cx + 14, cy + 16 - tilt, (48, 20, 88), 14)
        gl(d, cx - 42, cy, 5 + f, (170, 68, 255), 2)
        return img

    bosses = [("colossus", colossus), ("reaver", reaver), ("titan", titan),
              ("magma", magma), ("sporemother", sporemother),
              ("prism", prism), ("carrier", carrier),
              ("leviathan", leviathan), ("sovereign", sovereign),
              ("avatar", avatar)]
    for name, fn in bosses:
        for f in (0, 1):
            save(outline(fn(f)), f"bosses/r_b_{name}{f}.png")


# ============================================================================
# PART 4 - THE PLACES: 3 seamless silhouette strips (far/mid/near) + ground
# tile per place. 480x180 native (x4 = 1920x720 design). Wrapped on X.
# ============================================================================

def bake_strip(w, h, draw_fn, base_col, seed):
    img = Image.new("RGBA", (w, h), (*base_col, 255))
    d = ImageDraw.Draw(img)
    rng = random.Random(seed)
    draw_fn(d, w, h, rng)
    # wrap seams: copy left 24px onto the right edge blended
    return img

def fill_to_bottom(d, pts, w, h, col):
    d.polygon(pts + [(pts[-1][0], h), (pts[0][0], h)], fill=col)

def shape_factory(d, x, base, s, col, lit, rng, glow):
    bw = int(rng.randint(30, 60) * s)
    bh = int(rng.randint(40, 110) * s)
    d.rectangle([x, base - bh, x + bw, base], fill=col, outline=None)
    d.rectangle([x, base - bh, x + 4, base], fill=shade(col, 1.25))
    # chimney
    cx = x + bw // 2
    ch = int(rng.randint(20, 46) * s)
    d.rectangle([cx - 4, base - bh - ch, cx + 4, base - bh], fill=col)
    d.rectangle([cx - 4, base - bh - ch, cx + 4, base - bh + 3], fill=lit)
    # glow windows
    for _ in range(rng.randint(2, 6)):
        wx = x + rng.randint(4, bw - 8)
        wy = base - rng.randint(8, bh - 6)
        d.rectangle([wx, wy, wx + 3, wy + 4], fill=glow)

def shape_mesa(d, x, base, s, col, lit, rng, glow):
    w2 = int(rng.randint(50, 110) * s)
    h2 = int(rng.randint(30, 80) * s)
    d.polygon([(x, base), (x + w2 * 0.18, base - h2), (x + w2 * 0.8, base - h2),
               (x + w2, base)], fill=col)
    d.polygon([(x + w2 * 0.18, base - h2), (x + w2 * 0.8, base - h2),
               (x + w2 * 0.72, base - h2 + 10), (x + w2 * 0.26, base - h2 + 10)],
              fill=lit)
    # cactus
    if rng.random() < 0.5:
        cxx = x + w2 + rng.randint(6, 20)
        cch = rng.randint(10, 22)
        d.rectangle([cxx, base - cch, cxx + 4, base], fill=shade(col, 0.8))
        d.rectangle([cxx - 4, base - cch + 6, cxx, base - cch + 12],
                    fill=shade(col, 0.8))

def shape_iceberg(d, x, base, s, col, lit, rng, glow):
    w2 = int(rng.randint(40, 90) * s)
    h2 = int(rng.randint(40, 100) * s)
    d.polygon([(x, base), (x + w2 * 0.3, base - h2), (x + w2 * 0.55, base - h2 * 0.8),
               (x + w2 * 0.75, base - h2 * 0.95), (x + w2, base)], fill=col)
    d.polygon([(x + w2 * 0.3, base - h2), (x + w2 * 0.55, base - h2 * 0.8),
               (x + w2 * 0.5, base - h2 * 0.5), (x + w2 * 0.38, base - h2 * 0.6)],
              fill=lit)

def shape_volcano(d, x, base, s, col, lit, rng, glow):
    w2 = int(rng.randint(70, 130) * s)
    h2 = int(rng.randint(50, 110) * s)
    d.polygon([(x, base), (x + w2 * 0.42, base - h2), (x + w2 * 0.58, base - h2),
               (x + w2, base)], fill=col)
    # lava vein
    d.line([(x + w2 // 2, base - h2), (x + w2 // 2 - 6, base - h2 // 2),
            (x + w2 // 2 + 2, base)], fill=glow, width=3)
    d.ellipse([x + w2 // 2 - 8, base - h2 - 4, x + w2 // 2 + 8, base - h2 + 4],
              fill=glow)

def shape_tree(d, x, base, s, col, lit, rng, glow):
    tch = int(rng.randint(40, 90) * s)
    d.line([(x, base), (x, base - tch)], fill=shade(col, 0.85), width=5)
    for _ in range(4):
        a = rng.uniform(0.5, 2.6)
        ln = rng.randint(12, 30)
        d.line([(x, base - rng.randint(tch // 3, tch)),
                (x + int(math.cos(a) * ln), base - rng.randint(tch // 3, tch) - int(math.sin(a) * ln))],
               fill=shade(col, 0.9), width=3)
    d.ellipse([x - int(14 * s), base - tch - int(12 * s), x + int(14 * s), base - tch + int(12 * s)], fill=col)

def shape_crystal(d, x, base, s, col, lit, rng, glow):
    w2 = int(rng.randint(14, 34) * s)
    h2 = int(rng.randint(40, 120) * s)
    pts = [(x, base), (x + w2 * 0.3, base - h2 * 0.85), (x + w2 * 0.5, base - h2),
           (x + w2 * 0.7, base - h2 * 0.8), (x + w2, base)]
    d.polygon(pts, fill=col)
    d.polygon([(x + w2 * 0.3, base - h2 * 0.85), (x + w2 * 0.5, base - h2),
               (x + w2 * 0.55, base - h2 * 0.5), (x + w2 * 0.4, base - h2 * 0.45)],
              fill=lit)
    gl(d, x + w2 // 2, base - h2 // 2, 5, glow, 2)

def shape_island(d, x, base, s, col, lit, rng, glow):
    w2 = int(rng.randint(50, 100) * s)
    top = int(rng.randint(40, 90) * s)
    d.polygon([(x, base), (x + w2 * 0.2, base - top), (x + w2 * 0.8, base - top),
               (x + w2, base), (x + w2 * 0.7, base + 14), (x + w2 * 0.3, base + 14)],
              fill=col)
    d.rectangle([x + w2 * 0.2, base - top - 6, x + w2 * 0.8, base - top],
                fill=lit)  # grass lip
    if rng.random() < 0.6:  # waterfall
        wx = x + w2 // 2
        d.rectangle([wx - 2, base + 10, wx + 2, min(180, base + 40)],
                    fill=(190, 220, 250))

def shape_rock(d, x, base, s, col, lit, rng, glow):
    w2 = int(rng.randint(30, 70) * s)
    h2 = int(rng.randint(30, 80) * s)
    pts = [(x, base)]
    n = rng.randint(4, 6)
    for i in range(n):
        a = math.pi - i * math.pi / (n - 1)
        pts.append((x + w2 // 2 + int(math.cos(a) * w2 // 2),
                    base - int(math.sin(a) * h2)))
    pts.append((x + w2, base))
    d.polygon(pts, fill=col)
    d.line([pts[1], pts[2]], fill=lit, width=2)
    if rng.random() < 0.4:
        gl(d, x + w2 // 2, base - h2 // 3, 4, glow, 2)

def shape_tower(d, x, base, s, col, lit, rng, glow):
    bw = int(rng.randint(24, 46) * s)
    bh = int(rng.randint(60, 150) * s)
    d.rectangle([x, base - bh, x + bw, base], fill=col)
    d.rectangle([x, base - bh, x + 4, base], fill=lit)
    # neon windows grid
    for wy in range(base - bh + 8, base - 6, 12):
        for wx in range(x + 6, x + bw - 6, 10):
            if rng.random() < 0.45:
                d.rectangle([wx, wy, wx + 4, wy + 5], fill=glow)
    if rng.random() < 0.4:  # antenna
        d.line([(x + bw // 2, base - bh), (x + bw // 2, base - bh - 16)],
               fill=glow, width=2)

def shape_voidrock(d, x, base, s, col, lit, rng, glow):
    w2 = int(rng.randint(26, 60) * s)
    h2 = int(rng.randint(20, 46) * s)
    cy = base - rng.randint(20, 80)
    d.ellipse([x, cy - h2 // 2, x + w2, cy + h2 // 2], fill=col)
    d.ellipse([x + 4, cy - h2 // 2, x + w2 - 4, cy], fill=lit)
    # floating debris + portal glow
    if rng.random() < 0.5:
        gl(d, x + w2 // 2, cy, 6, glow, 2)
    dy = cy + rng.randint(10, 26)
    d.ellipse([x + w2 // 2 - 3, dy - 3, x + w2 // 2 + 3, dy + 3], fill=glow)

BIO_SHAPES = dict(
    iron=shape_factory, mesa=shape_mesa, tundra=shape_iceberg,
    volcano=shape_volcano, swamp=shape_tree, crystal=shape_crystal,
    sky=shape_island, trench=shape_rock, neon=shape_tower,
    void=shape_voidrock)

def build_places():
    out_dirs()
    SW, SH = 480, 180
    for pl in PLACES:
        key = pl["key"]
        fn = BIO_SHAPES[key]
        for layer, lcol in (("far", pl["far"]), ("mid", pl["mid"]),
                            ("near", pl["near"])):
            dens = {"far": 6, "mid": 6, "near": 7}[layer]
            scale = {"far": 2.1, "mid": 1.4, "near": 0.8}[layer]
            baseoff = {"far": 4, "mid": 3, "near": 2}[layer]
            def draw(d, w, h, rng, fn=fn, lcol=lcol, dens=dens, scale=scale,
                     pl=pl, layer=layer, baseoff=baseoff):
                base = h - baseoff
                col = tuple(int(c * (1.0 if layer == "near" else 0.96))
                            for c in lcol)
                lit = shade(col, 1.4)
                xs = sorted(rng.randint(-40, w) for _ in range(dens))
                for x in xs:
                    if key == "sky":
                        fn(d, x, base - rng.randint(10, 40), scale, col, lit,
                           rng, pl["accent"])
                    else:
                        fn(d, x, base, scale, col, lit, rng, pl["accent"])
                # thin ground mass under the silhouettes (strip is otherwise
                # TRANSPARENT - the engine pastes it over the sky gradient)
                d.rectangle([0, base, w, h], fill=col)
            img = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
            dd = ImageDraw.Draw(img)
            rng = random.Random(hash(key + layer) & 0xffff)
            draw(dd, SW, SH, rng)
            save(img, f"env/r_env_{key}_{layer}.png")
        # ---- ground tile 480x18 (x4 = 1920x72)
        gw, gh = 480, 18
        gimg = Image.new("RGBA", (gw, gh), (*pl["ground"], 255))
        gd = ImageDraw.Draw(gimg)
        rng = random.Random(hash(key + "g") & 0xffff)
        gd.rectangle([0, 0, gw, 2], fill=pl["groundTop"])
        gd.rectangle([0, 2, gw, 3], fill=shade(pl["ground"], 1.5))
        for _ in range(60):
            gx = rng.randint(0, gw)
            gy = rng.randint(5, gh - 2)
            gd.rectangle([gx, gy, gx + rng.randint(1, 4), gy + 1],
                         fill=shade(pl["ground"], rng.uniform(0.7, 1.4)))
        for _ in range(8):
            gx = rng.randint(0, gw)
            gd.rectangle([gx, 4, gx + rng.randint(2, 6), gh],
                         fill=shade(pl["ground"], 0.75))
        save(gimg, f"env/r_env_{key}_ground.png")



# ============================================================================
# PART 5 - BITS: shots, pickups, vfx, card icons, tank decals
# ============================================================================

def build_bits():
    out_dirs()
    # ---- the REAL cannonball (the owner: "canon does not shot real balls")
    ball = canvas(16, 16)
    d = dimg(ball)
    d.ellipse([1, 1, 15, 15], fill=(52, 54, 62), outline=OL)
    d.ellipse([3, 3, 11, 11], fill=(76, 78, 90))
    d.ellipse([4, 4, 8, 8], fill=(150, 156, 170))
    save(outline(ball), "shots/r_ball.png")
    # ball hot (just fired - glowing ring)
    hot = canvas(18, 18)
    d = dimg(hot)
    gl(d, 9, 9, 8, (255, 190, 90), 2)
    d.ellipse([3, 3, 15, 15], fill=(52, 54, 62), outline=OL)
    d.ellipse([5, 5, 11, 11], fill=(120, 110, 110))
    save(hot, "shots/r_ball_hot.png")
    # enemy plasma (engine tints per place accent - base warm)
    for nm, col in (("plasma", (255, 170, 70)), ("heavy", (255, 110, 90)),
                    ("ice", (170, 225, 255)), ("boss", (255, 120, 200))):
        p = canvas(14, 14)
        d = dimg(p)
        gl(d, 7, 7, 6, col, 2)
        d.ellipse([3, 3, 11, 11], fill=col, outline=OL)
        d.ellipse([5, 5, 8, 8], fill=(255, 250, 220))
        save(p, f"shots/r_{nm}.png")
    # rocket (player, points UP; engine rotates)
    rk = canvas(12, 26)
    d = dimg(rk)
    d.polygon([(2, 8), (6, 0), (10, 8), (10, 20), (2, 20)], fill=(190, 196, 208),
              outline=OL)
    d.polygon([(2, 8), (6, 0), (10, 8)], fill=(178, 44, 44))
    d.rectangle([2, 12, 10, 14], fill=(255, 176, 64))
    d.polygon([(2, 20), (0, 25), (2, 23)], fill=(120, 126, 140), outline=OL)
    d.polygon([(10, 20), (12, 25), (10, 23)], fill=(120, 126, 140), outline=OL)
    save(outline(rk), "shots/r_rocket.png")
    # enemy missile (points UP; engine rotates to velocity)
    em = canvas(10, 22)
    d = dimg(em)
    d.polygon([(1, 6), (5, 0), (9, 6), (9, 16), (1, 16)], fill=(200, 90, 110),
              outline=OL)
    d.polygon([(1, 16), (0, 21), (3, 18)], fill=(130, 60, 76), outline=OL)
    d.polygon([(9, 16), (10, 21), (7, 18)], fill=(130, 60, 76), outline=OL)
    save(outline(em), "shots/r_emissile.png")
    # bomb (drops)
    bo = canvas(12, 18)
    d = dimg(bo)
    d.ellipse([1, 2, 11, 15], fill=(62, 66, 76), outline=OL)
    d.ellipse([3, 4, 7, 9], fill=(110, 116, 130))
    d.rectangle([4, 0, 8, 4], fill=(90, 94, 106), outline=OL)
    d.polygon([(2, 14), (0, 18), (4, 16)], fill=(90, 94, 106), outline=OL)
    d.polygon([(10, 14), (12, 18), (8, 16)], fill=(90, 94, 106), outline=OL)
    save(outline(bo), "shots/r_bomb.png")
    # ice ball
    ib = canvas(14, 14)
    d = dimg(ib)
    d.ellipse([1, 1, 13, 13], fill=(160, 215, 245), outline=OL)
    d.ellipse([3, 3, 9, 9], fill=(220, 245, 255))
    d.line([(7, 2), (4, 7), (8, 11)], fill=(110, 170, 205))
    save(outline(ib), "shots/r_iceball.png")
    # ---- pickups: XP orb (2) + gogacoin (4)
    for f in (0, 1):
        o = canvas(12, 12)
        d = dimg(o)
        r = 4 + f
        gl(d, 6, 6, r + 2, (170, 160, 255), 2)
        d.ellipse([6 - r, 6 - r, 6 + r, 6 + r], fill=(200, 194, 255), outline=OL)
        d.ellipse([6 - r + 1, 6 - r + 1, 6, 6], fill=(238, 234, 255))
        save(o, f"fx/r_xp{f}.png")
    for f in range(4):
        c = canvas(14, 14)
        d = dimg(c)
        sx = (1.0, 0.66, 0.22, 0.66)[f]
        w2 = max(1, int(5 * sx))
        d.ellipse([7 - w2, 2, 7 + w2, 12], fill=(232, 190, 74), outline=OL)
        if f in (0, 1):
            d.ellipse([7 - w2 + 1, 3, 7 + w2 - 1, 11], fill=(248, 216, 110))
            d.ellipse([7 - w2 + 1, 3, 7, 8], fill=(255, 240, 170))
            if f == 0:
                d.rectangle([6, 5, 8, 9], fill=(190, 140, 40))
        save(c, f"fx/r_coin{f}.png")
    # ---- VFX frames: explosion 6, smoke 4, muzzle 2, ice shatter 3
    for i in range(6):
        t = i / 5.0
        s = int(6 + 26 * t)
        e = canvas(64, 64)
        d = dimg(e)
        if i < 4:
            gl(d, 32, 32, s, (255, 170, 60), 3)
            d.ellipse([32 - s // 2, 32 - s // 2, 32 + s // 2, 32 + s // 2],
                      fill=(255, 220, 120))
            d.ellipse([32 - s // 3, 32 - s // 3, 32 + s // 3, 32 + s // 3],
                      fill=(255, 250, 210))
        # debris specks
        rng = random.Random(i)
        for _ in range(10):
            a = rng.uniform(0, TAU2)
            r = s * rng.uniform(0.7, 1.25)
            x, y = 32 + int(math.cos(a) * r), 32 + int(math.sin(a) * r)
            d.ellipse([x - 2, y - 2, x + 2, y + 2],
                      fill=(255, 140 + rng.randint(0, 60), 40, 220))
        e.putalpha(e.getchannel("A").point(lambda v: int(v * (1.0 - t * 0.55))))
        save(e, f"fx/r_boom{i}.png")
    for i in range(4):
        s = 8 + i * 7
        sm = canvas(64, 64)
        d = dimg(sm)
        col = (120, 122, 132, int(200 - i * 45))
        d.ellipse([32 - s, 32 - s // 2, 32 + s, 32 + s // 2 + i * 2], fill=col)
        d.ellipse([32 - s // 2, 32 - s - i * 4, 32 + s // 2, 32 - s // 4],
                  fill=col)
        sm.putalpha(sm.getchannel("A").point(lambda v: int(v * (1.0 - i * 0.2))))
        save(sm, f"fx/r_smoke{i}.png")
    for i in range(2):
        mf = canvas(28, 28)
        d = dimg(mf)
        gl(d, 14, 14, 12 - i * 3, (255, 220, 120), 3)
        d.polygon([(0, 14), (10, 8 - i * 2), (14, 14), (10, 20 + i * 2)],
                  fill=(255, 240, 180))
        save(mf, f"fx/r_muzzle{i}.png")
    for i in range(3):
        sh = canvas(24, 24)
        d = dimg(sh)
        rng = random.Random(i + 40)
        for _ in range(5 + i * 2):
            x, y = rng.randint(4, 20), rng.randint(4, 20)
            ln = rng.randint(4, 9)
            a = rng.uniform(0, TAU2)
            d.line([(x, y), (x + int(math.cos(a) * ln), y + int(math.sin(a) * ln))],
                   fill=(190, 235, 255), width=2)
        sh.putalpha(sh.getchannel("A").point(lambda v: int(v * (1.0 - i * 0.3))))
        save(sh, f"fx/r_icehit{i}.png")
    # ---- card icons (24x24 native) - the XP card glyphs
    icons = dict(
        dmg=lambda d: d.polygon([(12, 2), (17, 12), (12, 22), (7, 12)],
                                fill=(255, 120, 70), outline=OL),
        rate=lambda d: (d.ellipse([4, 4, 20, 20], outline=(255, 210, 90), width=3),
                        d.line([(12, 12), (19, 5)], fill=(255, 210, 90), width=3)),
        speed=lambda d: [d.polygon([(3, 8), (12, 4), (12, 12)], fill=(140, 220, 140), outline=OL),
                         d.polygon([(3, 16), (12, 12), (12, 20)], fill=(140, 220, 140), outline=OL),
                         d.polygon([(12, 6), (21, 12), (12, 18)], fill=(190, 250, 190), outline=OL)],
        hull=lambda d: (d.rounded_rectangle([4, 8, 20, 17], radius=3, fill=(150, 158, 172), outline=OL),
                        d.rectangle([6, 5, 12, 8], fill=(110, 118, 132), outline=OL)),
        heal=lambda d: (d.rectangle([10, 4, 14, 20], fill=(130, 220, 140), outline=OL),
                        d.rectangle([4, 10, 20, 14], fill=(130, 220, 140), outline=OL)),
        pierce=lambda d: (d.line([(4, 12), (20, 12)], fill=(220, 226, 240), width=4),
                          d.polygon([(16, 7), (22, 12), (16, 17)], fill=(220, 226, 240), outline=OL)),
        boom=lambda d: (d.ellipse([6, 6, 18, 18], fill=(255, 150, 60), outline=OL),
                        d.ellipse([9, 9, 15, 15], fill=(255, 230, 150))),
        leech=lambda d: (d.ellipse([5, 5, 19, 19], fill=(190, 70, 100), outline=OL),
                         d.rectangle([11, 8, 13, 16], fill=(255, 220, 230))),
        multi=lambda d: [d.polygon([(6, 5), (9, 12), (3, 12)], fill=(150, 200, 255), outline=OL),
                         d.polygon([(12, 3), (15, 12), (9, 12)], fill=(190, 220, 255), outline=OL),
                         d.polygon([(18, 5), (21, 12), (15, 12)], fill=(150, 200, 255), outline=OL)],
        armor=lambda d: d.polygon([(12, 3), (20, 7), (18, 17), (12, 21), (6, 17), (4, 7)],
                                  fill=(150, 190, 220), outline=OL),
        cd=lambda d: (d.arc([5, 5, 19, 19], 30, 300, fill=(170, 180, 255), width=3),
                      d.polygon([(17, 3), (21, 8), (15, 9)], fill=(170, 180, 255), outline=OL)),
        shield=lambda d: (d.arc([4, 6, 20, 22], 180, 360, fill=(120, 190, 230), width=3),
                          d.line([(4, 14), (20, 14)], fill=(120, 190, 230), width=2)),
        crit=lambda d: (d.ellipse([5, 8, 13, 16], fill=(255, 210, 90), outline=OL),
                        d.polygon([(13, 6), (19, 12), (13, 18)], fill=(255, 160, 70), outline=OL)),
        bounce=lambda d: [d.line([(4, 18), (10, 10)], fill=(200, 170, 255), width=3),
                          d.line([(10, 10), (16, 16)], fill=(200, 170, 255), width=3),
                          d.line([(16, 16), (21, 6)], fill=(230, 210, 255), width=3)],
        slow=lambda d: (d.polygon([(12, 3), (19, 16), (5, 16)], fill=(170, 225, 255), outline=OL),
                        d.rectangle([9, 16, 15, 19], fill=(140, 195, 230), outline=OL)),
    )
    for nm, fn in icons.items():
        ic = canvas(24, 24)
        d = dimg(ic)
        fn(d)
        save(outline(ic), f"ui/r_card_{nm}.png")

# ============================================================================
# PART 6 - the feed thumbnail
# ============================================================================

def build_thumb():
    import sys as _s
    _s.path.insert(0, "tools")
    # 512x384 like the other thumbs? check existing
    import os
    old = "/home/z/my-project/gogabox/projects/gogabox/assets/thumbs/heavywar.png"
    size = (512, 384)
    if os.path.exists(old):
        size = Image.open(old).size
    W, H = size
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    pl = PLACES[0]
    top, bot = pl["skyTop"], pl["skyBot"]
    for yy in range(H):
        t = yy / H
        d.line([(0, yy), (W, yy)],
               fill=(int(top[0] * (1 - t) + bot[0] * t),
                     int(top[1] * (1 - t) + bot[1] * t),
                     int(top[2] * (1 - t) + bot[2] * t)))
    # far layer strip
    far = Image.open(f"{OUT}/env/r_env_iron_far.png").convert("RGBA")
    far = far.resize((W, int(far.height * W / far.width)))
    img.paste(far, (0, H - 90 - far.height), far)
    g = Image.open(f"{OUT}/env/r_env_iron_ground.png").convert("RGBA")
    g = g.resize((W, int(g.height * W / g.width)))
    img.paste(g, (0, H - g.height), g)
    # boss silhouette in the sky
    b = Image.open(f"{OUT}/bosses/r_b_avatar0.png").convert("RGBA")
    bw = int(W * 0.42)
    b = b.resize((bw, int(b.height * bw / b.width)))
    img.paste(b, (int(W * 0.52), int(H * 0.10)), b)
    # two enemies
    for i, e in enumerate(("fighter", "swarm")):
        es = Image.open(f"{OUT}/enemies/r_e_{e}0.png").convert("RGBA")
        ew = int(W * (0.16 if i == 0 else 0.09))
        es = es.resize((ew, int(es.height * ew / es.width)))
        es = es.transpose(Image.FLIP_LEFT_RIGHT)
        img.paste(es, (int(W * (0.18 + 0.3 * i)), int(H * (0.22 + 0.1 * i))), es)
    # the tank, big, front and center
    hull = Image.open(f"{OUT}/r_skin_olive_hull.png").convert("RGBA")
    tw = int(W * 0.44)
    hull = hull.resize((tw, int(hull.height * tw / hull.width)))
    tur = Image.open(f"{OUT}/r_skin_olive_turret.png").convert("RGBA")
    tur = tur.resize((int(tw * 0.42), int(tur.height * tw * 0.42 / tur.width)))
    bar = Image.open(f"{OUT}/r_tank_barrel.png").convert("RGBA")
    bar = bar.resize((int(tw * 0.55), int(bar.height * tw * 0.55 / bar.width)))
    ty = H - g.height - hull.height + int(hull.height * 0.18)
    txc = int(W * 0.34)
    # barrel rotated up-left toward the boss
    bar = bar.rotate(38, expand=True, resample=Image.NEAREST)
    img.paste(bar, (txc + tw // 2 - int(tw * 0.30), ty - int(tw * 0.16)), bar)
    img.paste(tur, (txc + tw // 2 - tur.width // 2, ty - tur.height + 8), tur)
    img.paste(hull, (txc, ty), hull)
    # title
    d = ImageDraw.Draw(img)
    try:
        from PIL import ImageFont
        fnt = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 54)
    except Exception:
        fnt = None
    txt = "HEAVY WAR"
    d.text((W // 2, int(H * 0.13)), txt, fill=(255, 240, 220),
           font=fnt, anchor="mm", stroke_width=6, stroke_fill=(20, 12, 8))
    dst = "/home/z/my-project/gogabox/projects/gogabox/assets/thumbs/heavywar.png"
    img.save(dst)
    print("wrote thumb", dst, img.size)


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what in ("tank", "all"):
        build_tank()
    if what in ("enemies", "all"):
        build_enemies()
    if what in ("bosses", "all"):
        build_bosses()
    if what in ("places", "all"):
        build_places()
    if what in ("bits", "all"):
        build_bits()
    if what in ("thumb", "all"):
        build_thumb()
    print("done:", what)
