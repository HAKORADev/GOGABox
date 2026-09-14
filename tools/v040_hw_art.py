#!/usr/bin/env python3
"""HEAVY WAR art tool (v040) - paints EVERY sprite slot the sim reads.

THE USAGE LAW: 100% original art drawn from geometric primitives in our
toy-military style (flat fills, 2px dark outline, top-left light). Sizes
match the sim's requests at 2x for crispness. Zero traced/copied bytes.

Output: projects/gogabox/assets/games/heavywar/spr_<name>.png
The game's _art_sprite() auto-loads these - the sim never changes.
"""
import math, os
from PIL import Image, ImageDraw, ImageFilter

OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/games/heavywar"
os.makedirs(OUT, exist_ok=True)

INK = (26, 21, 18, 255)          # the universal outline
GLASS = (154, 210, 232, 255)
GLASS_HI = (214, 240, 250, 255)
RUST = (168, 64, 46, 255)        # the faction
RUST_D = (122, 44, 32, 255)
RUST_L = (206, 102, 70, 255)
PANEL = (90, 42, 34, 255)
OLIVE = (90, 110, 58, 255)       # the player
OLIVE_D = (62, 78, 42, 255)
OLIVE_L = (138, 160, 90, 255)
METAL = (122, 122, 134, 255)
METAL_D = (86, 86, 96, 255)
METAL_L = (168, 168, 180, 255)
WOOD = (200, 147, 60, 255)
WOOD_D = (150, 106, 40, 255)
FIRE_Y = (255, 210, 60, 255)
FIRE_O = (255, 122, 26, 255)
FIRE_R = (232, 87, 74, 255)
WHITE = (245, 245, 245, 255)
GREY_B = (106, 106, 114, 255)    # armored bomb

def canvas(w, h):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)

def poly(d, pts, fill, outline=INK, ow=3):
    d.polygon(pts, fill=fill, outline=outline, width=ow)

def ell(d, box, fill, outline=INK, ow=3):
    d.ellipse(box, fill=fill, outline=outline, width=ow)

def rrect(d, box, r, fill, outline=INK, ow=3):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=ow)

def line(d, a, b, fill, w=3):
    d.line([a, b], fill=fill, width=w)

def save(img, name):
    img.save(f"{OUT}/spr_{name}.png")
    print("spr_" + name, img.size)

def shade_path(pts, dy=-2, dx=2, lift=26):
    """a lighter inner path for the top-left light"""
    return [(x + dx, y + dy) for x, y in pts]

def fin(d, x, y, w, h, fill, flip=False):
    pts = [(x, y), (x + (w if not flip else -w), y + h * 0.4), (x, y + h)]
    poly(d, pts, fill)

# ============================================================ the player
def tank(skin="olive"):
    body_c, dark, lite = {
        "olive": (OLIVE, OLIVE_D, OLIVE_L), "desert": ((198, 164, 92, 255), (150, 120, 60, 255), (226, 198, 130, 255)),
        "arctic": ((150, 178, 196, 255), (104, 132, 152, 255), (200, 222, 236, 255)),
        "navy": ((70, 90, 130, 255), (48, 62, 92, 255), (110, 134, 178, 255)),
        "crimson": ((156, 54, 44, 255), (110, 36, 30, 255), (200, 92, 74, 255)),
        "gold": ((212, 172, 60, 255), (160, 126, 36, 255), (244, 212, 110, 255)),
    }[skin]
    img, d = canvas(192, 120)
    # treads
    rrect(d, (10, 74, 182, 110), 16, dark)
    for i in range(6):
        x = 22 + i * 26
        ell(d, (x, 82, x + 16, 102), (40, 34, 28, 255))
    # hull
    rrect(d, (24, 48, 168, 82), 10, body_c)
    poly(d, [(30, 52), (60, 38), (140, 38), (162, 52)], lite)
    # turret
    rrect(d, (66, 24, 128, 54), 8, body_c)
    ell(d, (78, 28, 116, 44), lite)
    # barrel
    rrect(d, (122, 30, 182, 42), 4, dark)
    rrect(d, (172, 26, 184, 46), 3, dark)
    # hatch + star
    ell(d, (88, 14, 106, 30), dark)
    star(d, 52, 62, 9, (232, 220, 174, 255))
    save(img, "tank" if skin == "olive" else "tank_" + skin)

def star(d, cx, cy, r, fill):
    pts = []
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((cx + math.cos(ang) * rr, cy + math.sin(ang) * rr))
    d.polygon(pts, fill=fill)

def heli():
    img, d = canvas(240, 92)
    # the friend: round gold body, big window, skids
    ell(d, (40, 22, 190, 78), (232, 184, 60, 255))
    ell(d, (56, 30, 118, 62), GLASS)
    ell(d, (64, 34, 92, 50), GLASS_HI)
    poly(d, [(180, 40), (222, 30), (222, 62), (180, 60)], (196, 148, 44, 255))
    rrect(d, (60, 76, 170, 86), 4, (150, 106, 40, 255))
    line(d, (90, 70), (90, 78), INK, 3)
    line(d, (140, 70), (140, 78), INK, 3)
    # rotor
    rrect(d, (108, 8, 122, 20), 3, (90, 70, 30, 255))
    poly(d, [(20, 12), (210, 12), (196, 4), (34, 4)], (120, 96, 44, 255))
    # the box hook
    line(d, (150, 78), (150, 88), INK, 4)
    save(img, "heli")

def crate():
    img, d = canvas(80, 80)
    rrect(d, (6, 6, 74, 74), 6, WOOD)
    rrect(d, (6, 6, 74, 74), 6, WOOD, INK, 4)
    line(d, (6, 40), (74, 40), WOOD_D, 5)
    line(d, (40, 6), (40, 74), WOOD_D, 5)
    for p in [(10, 10), (70, 10), (10, 70), (70, 70)]:
        ell(d, (p[0] - 3, p[1] - 3, p[0] + 3, p[1] + 3), WOOD_D)
    save(img, "crate")

# ============================================================ shells/bombs
def shell():
    img, d = canvas(20, 52)
    rrect(d, (7, 12, 13, 44), 3, (255, 224, 138, 255))
    ell(d, (5, 4, 15, 16), WHITE)
    save(img, "shell")

def bomb(kind):
    img, d = canvas(2 * 18, 2 * 26)
    body, tip = WHITE, METAL
    band = None
    if kind == "guided":
        body, tip = (232, 130, 110, 255), FIRE_R
    if kind == "armored":
        body, tip = GREY_B, METAL_D
    if kind == "frag":
        body, tip = FIRE_Y, (200, 150, 30, 255)
        band = FIRE_O
    if kind == "atom":
        body, tip = (170, 220, 110, 255), (90, 150, 60, 255)
    # teardrop body + fins
    ell(d, (10, 14, 26, 40), body)
    poly(d, [(18, 4), (24, 16), (12, 16)], tip)
    poly(d, [(10, 36), (4, 50), (14, 42)], METAL_D)
    poly(d, [(26, 36), (32, 50), (22, 42)], METAL_D)
    if band:
        rrect(d, (10, 24, 26, 30), 2, band)
    if kind == "atom":
        ell(d, (15, 22, 21, 28), (240, 250, 200, 255))
    save(img, "bomb_" + kind)

def dumb():
    img, d = canvas(36, 52)
    poly(d, [(18, 4), (26, 18), (26, 40), (10, 40), (10, 18)], WHITE)
    poly(d, [(10, 40), (2, 50), (10, 46)], METAL_D)
    poly(d, [(26, 40), (34, 50), (26, 46)], METAL_D)
    ell(d, (12, 14, 24, 24), (220, 224, 228, 255))
    save(img, "bomb_dumb")

def eshot(kind):
    img, d = canvas(30, 30)
    if kind == "bullet":
        ell(d, (8, 8, 22, 22), FIRE_O)
        ell(d, (11, 11, 19, 19), FIRE_Y)
    elif kind == "missile":
        img, d = canvas(60, 26)
        rrect(d, (6, 8, 48, 18), 5, (216, 76, 42, 255))
        poly(d, [(48, 8), (58, 13), (48, 18)], FIRE_R)
        poly(d, [(12, 8), (4, 2), (12, 14)], METAL_D)
        poly(d, [(12, 18), (4, 24), (12, 12)], METAL_D)
        ell(d, (8, 10, 16, 16), FIRE_Y)
    elif kind == "rpg":
        img, d = canvas(60, 34)
        rrect(d, (8, 12, 46, 22), 5, GREY_B)
        poly(d, [(46, 10), (58, 17), (46, 24)], FIRE_R)
        poly(d, [(14, 12), (4, 4), (14, 20)], METAL_D)
        ell(d, (40, 14, 48, 20), FIRE_Y)
    elif kind == "fraglet":
        ell(d, (8, 8, 22, 22), FIRE_Y)
        ell(d, (12, 12, 18, 18), WHITE)
    save(img, "eshot_" + kind)

# ============================================================ explosions
def boom():
    S = 240
    img, d = canvas(S, S)
    cx = cy = S // 2
    # outer soft glow
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((10, 10, S - 10, S - 10), fill=FIRE_O[:3] + (120,))
    glow = glow.filter(ImageFilter.GaussianBlur(14))
    img.alpha_composite(glow)
    d = ImageDraw.Draw(img)
    # ragged fireball
    pts = []
    for i in range(14):
        ang = i * 2 * math.pi / 14
        r = 62 + (12 if i % 2 else 0) + (i * 7 % 13)
        pts.append((cx + math.cos(ang) * r, cy + math.sin(ang) * r))
    poly(d, pts, FIRE_O, INK, 3)
    pts2 = [(x * 0.72 + cx * 0.28, y * 0.72 + cy * 0.28) for x, y in pts]
    poly(d, pts2, FIRE_Y, None)
    ell(d, (cx - 30, cy - 30, cx + 30, cy + 30), WHITE)
    save(img, "boom")

def ring():
    S = 160
    img, d = canvas(S, S)
    ell(d, (14, 14, S - 14, S - 14), (0, 0, 0, 0))
    d.ellipse((14, 14, S - 14, S - 14), outline=(140, 200, 255, 255), width=10)
    d.ellipse((34, 34, S - 34, S - 34), outline=(220, 244, 255, 200), width=6)
    save(img, "ring")

def mush():
    img, d = canvas(360, 260)
    # stem
    poly(d, [(150, 130), (210, 130), (228, 250), (132, 250)], (232, 220, 180, 255))
    # cap
    ell(d, (60, 20, 300, 150), (255, 236, 150, 255))
    ell(d, (100, 40, 260, 120), (255, 250, 220, 255))
    # skirt
    ell(d, (44, 100, 316, 170), (250, 210, 110, 255))
    d.rectangle((44, 128, 316, 150), fill=(0, 0, 0, 0))
    ell(d, (52, 120, 308, 168), (250, 210, 110, 255))
    save(img, "mush")

# ============================================================ the enemies
def plane_scout():
    img, d = canvas(168, 60)
    poly(d, [(10, 30), (60, 14), (140, 22), (158, 30), (140, 38), (60, 46)], RUST)
    poly(d, [(16, 28), (60, 18), (130, 24), (130, 30), (16, 30)], RUST_L)
    poly(d, [(58, 16), (74, 2), (88, 16)], (140, 52, 38, 255))   # wing up
    poly(d, [(58, 44), (74, 58), (88, 44)], (140, 52, 38, 255))
    ell(d, (116, 20, 140, 38), GLASS)
    ell(d, (120, 23, 130, 32), GLASS_HI)
    ell(d, (146, 26, 158, 34), (40, 32, 28, 255))                # prop hub
    save(img, "enemy_scout")

def plane_dart():
    img, d = canvas(160, 60)
    poly(d, [(8, 30), (70, 18), (150, 26), (150, 34), (70, 42)], RUST_D)
    poly(d, [(14, 29), (70, 21), (140, 27), (14, 30)], (160, 66, 48, 255))
    poly(d, [(60, 18), (76, 4), (92, 20)], (90, 34, 26, 255))
    poly(d, [(60, 42), (76, 56), (92, 40)], (90, 34, 26, 255))
    ell(d, (128, 22, 148, 38), GLASS)
    save(img, "enemy_dart")

def plane_raider():
    img, d = canvas(240, 88)
    poly(d, [(10, 44), (50, 26), (190, 26), (228, 44), (190, 60), (50, 60)], RUST)
    poly(d, [(20, 42), (56, 30), (180, 30), (180, 42)], RUST_L)
    ell(d, (150, 32, 186, 52), GLASS)
    rrect(d, (80, 14, 108, 30), 5, RUST_D)      # engine nacelles
    rrect(d, (80, 58, 108, 74), 5, RUST_D)
    fin(d, 18, 26, 26, 18, RUST_D)
    fin(d, 18, 60, 26, 18, RUST_D, flip=True)
    save(img, "enemy_raider")

def plane_lynx():
    img, d = canvas(160, 56)
    poly(d, [(8, 28), (80, 14), (152, 28), (80, 42)], (110, 120, 70, 255))  # camo green
    poly(d, [(16, 27), (80, 18), (140, 27)], (140, 150, 92, 255))
    poly(d, [(70, 16), (86, 4), (100, 18)], (80, 88, 52, 255))
    poly(d, [(70, 40), (86, 52), (100, 38)], (80, 88, 52, 255))
    poly(d, [(120, 24), (140, 12), (140, 30)], (80, 88, 52, 255))  # canard
    ell(d, (124, 22, 142, 34), GLASS)
    save(img, "enemy_lynx")

def komet():
    img, d = canvas(88, 168)
    rrect(d, (30, 20, 58, 130), 12, (170, 176, 186, 255))
    poly(d, [(30, 60), (8, 96), (30, 88)], METAL_D)
    poly(d, [(58, 60), (80, 96), (58, 88)], METAL_D)
    poly(d, [(36, 4), (52, 4), (58, 24), (30, 24)], FIRE_R)
    poly(d, [(38, 130), (50, 130), (58, 160), (30, 160)], FIRE_O)
    ell(d, (38, 30, 50, 44), GLASS)
    save(img, "enemy_komet")

def skimmer():
    img, d = canvas(208, 52)
    poly(d, [(8, 26), (70, 16), (190, 22), (200, 30), (190, 36), (70, 38)], METAL)
    poly(d, [(16, 25), (70, 19), (180, 24)], METAL_L)
    poly(d, [(96, 16), (130, 4), (130, 20)], METAL_D)
    poly(d, [(96, 38), (130, 48), (130, 32)], METAL_D)
    ell(d, (160, 22, 184, 32), FIRE_R)
    save(img, "enemy_skimmer")

def plane_fang():
    img, d = canvas(200, 68)
    poly(d, [(6, 34), (100, 20), (194, 34), (100, 48)], (146, 96, 52, 255))  # brown delta
    poly(d, [(16, 33), (100, 24), (180, 33)], (178, 122, 68, 255))
    poly(d, [(80, 22), (100, 6), (120, 22)], (110, 70, 36, 255))
    ell(d, (128, 26, 152, 40), GLASS)
    save(img, "enemy_fang")

def plane_talon():
    img, d = canvas(220, 72)
    poly(d, [(6, 36), (110, 20), (214, 36), (110, 52)], (90, 110, 58, 255))
    poly(d, [(16, 35), (110, 24), (196, 35)], (120, 142, 78, 255))
    poly(d, [(84, 22), (110, 4), (136, 22)], (64, 80, 40, 255))
    ell(d, (140, 28, 168, 44), GLASS)
    rrect(d, (60, 46, 90, 58), 4, RUST_D)   # bomb rack
    save(img, "enemy_talon")

def wasp():
    img, d = canvas(176, 120)
    poly(d, [(30, 20), (120, 40), (168, 84), (140, 84), (66, 56), (30, 44)], RUST)  # diving pose
    poly(d, [(40, 24), (110, 42), (66, 50), (40, 38)], RUST_L)
    poly(d, [(30, 20), (8, 6), (34, 34)], RUST_D)
    ell(d, (120, 48, 150, 70), GLASS)
    ell(d, (128, 54, 142, 64), GLASS_HI)
    save(img, "enemy_wasp")

def copter_body(w, h, body, dark, lite, big=False):
    img, d = canvas(w, h)
    bw, bh = w, h
    # hull
    rrect(d, (int(w*0.18), int(h*0.34), int(w*0.86), int(h*0.78)), 12, body)
    poly(d, [(int(w*0.18), int(h*0.4)), (int(w*0.4), int(h*0.34)), (int(w*0.4), int(h*0.5))], lite)
    # tail
    poly(d, [(int(w*0.8), int(h*0.42)), (int(w*0.98), int(h*0.3)), (int(w*0.98), int(h*0.5)), (int(w*0.8), int(h*0.62))], dark)
    poly(d, [(int(w*0.94), int(h*0.24)), (int(w*1.0), int(h*0.3)), (int(w*0.94), int(h*0.42))], dark)
    # cockpit
    ell(d, (int(w*0.2), int(h*0.4), int(w*0.42), int(h*0.66)), GLASS)
    ell(d, (int(w*0.24), int(h*0.44), int(w*0.32), int(h*0.56)), GLASS_HI)
    # mast + rotor
    rrect(d, (int(w*0.44), int(h*0.1), int(w*0.5), int(h*0.36)), 3, dark)
    rrect(d, (int(w*0.08), int(h*0.04), int(w*0.86), int(h*0.12)), 4, dark)
    # skids / weapon stubs
    rrect(d, (int(w*0.26), int(h*0.82), int(w*0.7), int(h*0.9)), 4, dark)
    if big:
        rrect(d, (int(w*0.5), int(h*0.66), int(w*0.66), int(h*0.8)), 4, dark)
    return img, d

def hornet():
    img, d = copter_body(184, 80, RUST, RUST_D, RUST_L)
    save(img, "enemy_hornet")

def viper():
    img, d = copter_body(192, 100, (146, 88, 44, 255), (104, 60, 28, 255), (180, 120, 66, 255))
    rrect(d, (70, 78, 130, 92), 4, (104, 60, 28, 255))
    save(img, "enemy_viper")

def mammoth():
    img, d = copter_body(224, 108, (94, 112, 62, 255), (62, 76, 40, 255), (130, 150, 88, 255), big=True)
    rrect(d, (30, 6, 200, 18), 4, (62, 76, 40, 255))
    save(img, "enemy_mammoth")

def mirror():
    img, d = canvas(200, 66)
    poly(d, [(56, 33), (110, 20), (194, 30), (194, 40), (110, 46)], METAL)
    poly(d, [(64, 32), (110, 24), (180, 30)], METAL_L)
    ell(d, (150, 24, 172, 40), GLASS)
    poly(d, [(120, 18), (140, 4), (148, 22)], METAL_D)
    poly(d, [(120, 48), (140, 62), (148, 44)], METAL_D)
    # THE FRONT SHIELD panel
    rrect(d, (4, 10, 52, 56), 8, (88, 168, 232, 255))
    rrect(d, (10, 16, 46, 50), 6, (150, 210, 250, 255))
    save(img, "enemy_mirror")

def technical():
    img, d = canvas(184, 100)
    rrect(d, (12, 52, 172, 74), 6, (110, 96, 60, 255))
    rrect(d, (20, 26, 74, 56), 6, (140, 122, 76, 255))     # cab
    rrect(d, (26, 32, 66, 48), 4, GLASS)
    rrect(d, (84, 34, 160, 56), 4, (90, 78, 48, 255))      # rocket bed
    for i in range(3):
        rrect(d, (92 + i * 22, 24, 108 + i * 22, 44), 6, RUST_D)
        ell(d, (96 + i * 22, 26, 104 + i * 22, 34), FIRE_R)
    for x in (36, 84, 132):
        ell(d, (x - 12, 66, x + 12, 94), (40, 34, 28, 255))
        ell(d, (x - 5, 73, x + 5, 87), METAL_D)
    save(img, "enemy_technical")

def plane_carpet():
    img, d = canvas(300, 96)
    poly(d, [(8, 48), (60, 28), (240, 28), (292, 48), (240, 68), (60, 68)], RUST)
    poly(d, [(20, 46), (66, 32), (230, 32), (230, 46)], RUST_L)
    for x in (70, 120, 170, 220):
        rrect(d, (x, 14, x + 30, 30), 6, RUST_D)
        ell(d, (x + 22, 18, x + 30, 26), (40, 32, 28, 255))
        rrect(d, (x, 66, x + 30, 82), 6, RUST_D)
    ell(d, (196, 34, 234, 56), GLASS)
    save(img, "enemy_carpet")

def orbital():
    img, d = canvas(192, 200)
    rrect(d, (66, 60, 126, 150), 10, METAL)
    rrect(d, (76, 76, 116, 96), 4, FIRE_R)                  # the laser eye
    poly(d, [(10, 80), (66, 66), (66, 140), (10, 126)], (70, 110, 170, 255))
    poly(d, [(182, 80), (126, 66), (126, 140), (182, 126)], (70, 110, 170, 255))
    for i in range(4):
        line(d, (16, 88 + i * 12), (62, 78 + i * 12), (40, 70, 120, 255), 3)
        line(d, (176, 88 + i * 12), (130, 78 + i * 12), (40, 70, 120, 255), 3)
    rrect(d, (86, 20, 106, 60), 4, METAL_D)
    rrect(d, (60, 8, 132, 24), 4, METAL_D)
    save(img, "enemy_orbital")

def grinder():
    img, d = canvas(184, 112)
    rrect(d, (12, 66, 172, 96), 12, (70, 74, 82, 255))
    for i in range(5):
        ell(d, (22 + i * 30, 72, 50 + i * 30, 94), (40, 34, 28, 255))
    rrect(d, (30, 40, 130, 70), 8, RUST)
    rrect(d, (96, 18, 148, 48), 8, RUST_D)                  # turret
    rrect(d, (140, 26, 182, 36), 4, (40, 34, 28, 255))      # barrel (aims back-left? faces left)
    poly(d, [(30, 44), (12, 40), (12, 52), (30, 56)], (40, 34, 28, 255))
    save(img, "enemy_grinder")

def plowman():
    img, d = canvas(224, 112)
    rrect(d, (40, 40, 180, 78), 10, (198, 150, 60, 255))
    rrect(d, (60, 16, 120, 46), 8, (160, 118, 44, 255))     # cab
    rrect(d, (66, 22, 96, 40), 4, GLASS)
    # THE PLOW (faces left)
    poly(d, [(6, 20), (40, 34), (40, 88), (6, 96)], METAL_L)
    poly(d, [(6, 20), (40, 34), (40, 46), (12, 34)], METAL)
    for x in (66, 134):
        ell(d, (x - 14, 70, x + 14, 100), (40, 34, 28, 255))
        ell(d, (x - 6, 78, x + 6, 92), METAL_D)
    rrect(d, (150, 30, 190, 52), 6, (160, 118, 44, 255))    # exhaust
    save(img, "enemy_plowman")

def atomault():
    img, d = canvas(380, 150)
    poly(d, [(10, 75), (70, 45), (310, 45), (370, 75), (310, 105), (70, 105)], (120, 130, 76, 255))
    poly(d, [(24, 72), (76, 50), (300, 50), (300, 72)], (150, 162, 100, 255))
    for x in (110, 190):
        rrect(d, (x, 26, x + 44, 48), 8, (86, 96, 54, 255))
        ell(d, (x + 34, 30, x + 44, 40), (40, 34, 28, 255))
    ell(d, (240, 54, 290, 82), GLASS)
    rrect(d, (160, 88, 220, 112), 6, (60, 70, 40, 255))     # bomb bay
    ell(d, (176, 92, 204, 108), (170, 220, 110, 255))
    star(d, 90, 80, 10, (232, 220, 174, 255))
    save(img, "enemy_atomault")

def zeppelin():
    img, d = canvas(560, 160)
    ell(d, (12, 24, 548, 124), (146, 92, 96, 255))
    ell(d, (48, 40, 300, 104), (180, 118, 120, 255))
    poly(d, [(470, 44), (548, 10), (548, 60)], (110, 66, 70, 255))
    poly(d, [(470, 104), (548, 138), (548, 88)], (110, 66, 70, 255))
    rrect(d, (220, 116, 330, 142), 8, PANEL)                # gondola
    for x in (240, 270, 300):
        rrect(d, (x, 122, x + 16, 134), 3, GLASS)
    rrect(d, (120, 66, 170, 82), 4, (110, 66, 70, 255))     # bomb racks
    rrect(d, (350, 66, 400, 82), 4, (110, 66, 70, 255))
    star(d, 250, 74, 14, (60, 36, 38, 255))
    save(img, "enemy_zeppelin")

# ============================================================ the bosses
def boss_gunship():
    img, d = copter_body(600, 240, (110, 44, 40, 255), (74, 28, 26, 255), (150, 70, 58, 255), big=True)
    # twin rotors
    rrect(d, (60, 10, 540, 26), 6, (40, 22, 20, 255))
    rrect(d, (270, 30, 330, 100), 10, (74, 28, 26, 255))
    # turret ball under the nose
    ell(d, (110, 170, 210, 236), (74, 28, 26, 255))
    rrect(d, (140, 200, 180, 232), 4, (30, 18, 16, 255))
    # missile pod
    rrect(d, (330, 180, 470, 224), 8, (50, 24, 22, 255))
    for i in range(3):
        ell(d, (350 + i * 36, 192, 372 + i * 36, 212), (30, 18, 16, 255))
    save(img, "boss_gunship")

def boss_dreadnought():
    img, d = canvas(960, 320)
    poly(d, [(10, 200), (120, 150), (840, 150), (950, 200), (840, 250), (120, 250)], (100, 100, 112, 255))
    poly(d, [(30, 196), (130, 158), (830, 158), (830, 196)], (140, 140, 152, 255))
    # superstructure
    rrect(d, (400, 90, 600, 156), 10, (120, 120, 132, 255))
    rrect(d, (460, 50, 560, 96), 8, (100, 100, 112, 255))
    # 4 turrets x barrel
    for x in (150, 290, 640, 780):
        rrect(d, (x, 120, x + 70, 158), 8, (80, 80, 90, 255))
        rrect(d, (x + 8, 132, x + 62, 148), 4, (50, 50, 58, 255))
        line(d, (x + 10, 140), (x - 46, 140), (50, 50, 58, 255), 10)
    # launcher
    rrect(d, (452, 20, 568, 56), 6, (70, 70, 80, 255))
    for i in range(4):
        ell(d, (466 + i * 26, 30, 482 + i * 26, 46), (30, 30, 36, 255))
    save(img, "boss_dreadnought")

def boss_skystealer():
    img, d = canvas(720, 420)
    ell(d, (40, 30, 680, 230), (96, 60, 110, 255))
    ell(d, (100, 60, 420, 196), (130, 84, 140, 255))
    poly(d, [(560, 60), (690, 16), (690, 120)], (70, 42, 78, 255))
    poly(d, [(560, 200), (690, 246), (690, 140)], (70, 42, 78, 255))
    # THE DISH tractor beam
    poly(d, [(300, 220), (420, 220), (450, 290), (270, 290)], (80, 80, 92, 255))
    ell(d, (300, 270, 420, 330), (150, 200, 255, 255))
    ell(d, (326, 288, 394, 320), (210, 240, 255, 255))
    star(d, 350, 130, 24, (60, 36, 62, 255))
    save(img, "boss_skystealer")

def boss_wreckball():
    img, d = canvas(640, 480)
    # walker body
    rrect(d, (240, 60, 560, 240), 22, (120, 96, 52, 255))
    rrect(d, (280, 100, 480, 180), 14, (156, 128, 72, 255))
    rrect(d, (250, 240, 330, 380), 12, (90, 70, 38, 255))
    rrect(d, (470, 240, 550, 380), 12, (90, 70, 38, 255))
    rrect(d, (236, 370, 344, 400), 8, (60, 46, 26, 255))
    rrect(d, (456, 370, 564, 400), 8, (60, 46, 26, 255))
    # the arm + chain + BALL (faces left)
    line(d, (250, 120), (140, 190), (70, 56, 32, 255), 14)
    for i in range(6):
        ell(d, (146 + i * 18 - 6, 186 + i * 10 - 5, 158 + i * 18 - 6, 198 + i * 10 - 5), (50, 50, 56, 255))
    ell(d, (60, 280, 200, 420), (86, 86, 96, 255))
    ell(d, (86, 304, 140, 360), (130, 130, 142, 255))
    save(img, "boss_wreckball")

def boss_warhead():
    img, d = canvas(460, 500)
    ell(d, (30, 60, 430, 440), (150, 62, 48, 255))
    ell(d, (80, 100, 300, 300), (190, 92, 68, 255))
    # brow + eyes
    rrect(d, (110, 170, 350, 210), 12, (100, 40, 32, 255))
    ell(d, (140, 220, 220, 290), (250, 220, 90, 255))
    ell(d, (280, 220, 360, 290), (250, 220, 90, 255))
    ell(d, (165, 235, 200, 272), (40, 20, 16, 255))
    ell(d, (305, 235, 340, 272), (40, 20, 16, 255))
    # gritted mouth
    rrect(d, (140, 330, 330, 390), 10, (100, 40, 32, 255))
    for i in range(5):
        line(d, (165 + i * 35, 332), (165 + i * 35, 388), (240, 230, 210, 255), 8)
    # launcher cheeks
    rrect(d, (10, 240, 80, 330), 10, (100, 40, 32, 255))
    rrect(d, (380, 240, 450, 330), 10, (100, 40, 32, 255))
    save(img, "boss_warhead")

def boss_kongo():
    img, d = canvas(540, 540)
    body = (110, 74, 52, 255)
    body_l = (146, 102, 70, 255)
    ell(d, (90, 140, 450, 500), body)                       # torso
    ell(d, (60, 220, 190, 420), body)                       # left arm
    ell(d, (350, 220, 480, 420), body)                      # right arm
    ell(d, (110, 400, 260, 530), (84, 56, 40, 255))         # legs
    ell(d, (280, 400, 430, 530), (84, 56, 40, 255))
    ell(d, (150, 40, 390, 240), body)                       # head
    poly(d, [(190, 60), (250, 20), (290, 60)], body_l)      # crest
    ell(d, (190, 110, 250, 170), (250, 220, 90, 255))
    ell(d, (290, 110, 350, 170), (250, 220, 90, 255))
    ell(d, (205, 125, 238, 155), (40, 20, 16, 255))
    ell(d, (305, 125, 338, 155), (40, 20, 16, 255))
    rrect(d, (200, 190, 340, 230), 10, (60, 38, 28, 255))   # mouth
    save(img, "boss_kongo")

def boss_eyebot():
    img, d = canvas(420, 400)
    ell(d, (60, 40, 360, 300), (120, 110, 130, 255))        # body
    ell(d, (110, 70, 310, 260), (200, 196, 210, 255))       # eye white
    ell(d, (150, 100, 270, 230), (90, 140, 220, 255))       # iris
    ell(d, (175, 125, 245, 205), (30, 30, 40, 255))         # pupil
    ell(d, (185, 135, 215, 165), (240, 244, 250, 255))      # glint
    # the HAND pod
    rrect(d, (160, 300, 260, 380), 14, (90, 84, 100, 255))
    for ang in range(5):
        a = ang * 2 * math.pi / 5 - math.pi / 2
        ell(d, (209 + math.cos(a) * 52 - 16, 340 + math.sin(a) * 52 - 16,
                209 + math.cos(a) * 52 + 16, 340 + math.sin(a) * 52 + 16),
                (130, 124, 140, 255))
    save(img, "boss_eyebot")

def boss_mechworm():
    img, d = canvas(1000, 240)
    # head segment (faces left)
    ell(d, (20, 60, 260, 220), (110, 116, 70, 255))
    ell(d, (50, 90, 180, 190), (146, 152, 94, 255))
    poly(d, [(40, 80), (110, 60), (110, 100)], (80, 86, 50, 255))
    ell(d, (70, 110, 130, 160), FIRE_R)                     # mouth light
    ell(d, (88, 122, 112, 148), (250, 210, 110, 255))
    # ribs
    for i in range(5):
        x = 260 + i * 140
        ell(d, (x, 80 + (i % 2) * 12, x + 150, 200 + (i % 2) * 12), (96, 102, 62, 255))
        ell(d, (x + 24, 104 + (i % 2) * 12, x + 122, 182 + (i % 2) * 12), (128, 134, 84, 255))
    save(img, "boss_mechworm")

def boss_warbot():
    img, d = canvas(480, 560)
    metal = (110, 114, 126, 255)
    dark = (78, 82, 92, 255)
    lite = (150, 154, 166, 255)
    rrect(d, (140, 40, 340, 300), 24, metal)                # torso
    rrect(d, (170, 80, 310, 160), 12, dark)
    ell(d, (200, 96, 280, 144), FIRE_R)                     # eye visor
    ell(d, (214, 104, 250, 136), (255, 160, 120, 255))
    rrect(d, (220, 300, 260, 380), 10, dark)                # waist
    rrect(d, (150, 370, 220, 540), 16, metal)               # legs
    rrect(d, (260, 370, 330, 540), 16, metal)
    rrect(d, (140, 510, 240, 550), 8, dark)
    rrect(d, (250, 510, 350, 550), 8, dark)
    rrect(d, (40, 60, 150, 300), 18, metal)                 # left arm (shield arm)
    rrect(d, (330, 90, 440, 260), 18, metal)                # launcher arm
    for i in range(3):
        ell(d, (350, 120 + i * 42, 420, 150 + i * 42), dark)
    save(img, "boss_warbot")

def boss_secretfist():
    img, d = canvas(720, 460)
    # a hovering fortress cluster around a core
    poly(d, [(120, 300), (600, 300), (660, 420), (60, 420)], (100, 44, 40, 255))
    ell(d, (200, 120, 520, 330), (140, 60, 52, 255))
    ell(d, (270, 160, 450, 300), (90, 36, 32, 255))
    ell(d, (300, 185, 420, 280), FIRE_R)                    # the core
    ell(d, (325, 205, 395, 262), (255, 180, 120, 255))
    ell(d, (342, 218, 378, 248), (255, 240, 200, 255))
    rrect(d, (80, 250, 180, 310), 10, (70, 30, 28, 255))    # small launcher
    rrect(d, (540, 250, 640, 310), 10, (70, 30, 28, 255))   # big launcher
    rrect(d, (300, 320, 420, 360), 8, (70, 30, 28, 255))    # turret deck
    line(d, (360, 330), (300, 290), (40, 20, 18, 255), 12)
    save(img, "boss_secretfist")

if __name__ == "__main__":
    tank(); [tank(s) for s in ["desert", "arctic", "navy", "crimson", "gold"]]
    heli(); crate(); shell(); dumb()
    for k in ["guided", "armored", "frag", "atom"]:
        bomb(k)
    for k in ["bullet", "missile", "rpg", "fraglet"]:
        eshot(k)
    boom(); ring(); mush()
    plane_scout(); plane_dart(); plane_raider(); plane_lynx(); komet()
    skimmer(); plane_fang(); plane_talon(); wasp(); hornet(); mirror()
    technical(); plane_carpet(); viper(); mammoth(); orbital(); grinder()
    plowman(); atomault(); zeppelin()
    boss_gunship(); boss_dreadnought(); boss_skystealer(); boss_wreckball()
    boss_warhead(); boss_kongo(); boss_eyebot(); boss_mechworm()
    boss_warbot(); boss_secretfist()
    print("ALL SPRITES PAINTED ->", OUT)

# ============================================================ the places
# palettes mirror HWData.PLACES (ours; keep the two in sync)
PLACE_PAL = {
    "frostkrai": ((191, 227, 255), (156, 200, 232), (232, 244, 251), (185, 206, 222), "snow"),
    "gulfgate": ((143, 212, 232), (93, 168, 184), (232, 220, 174), (201, 185, 136), "coast"),
    "oilreach": ((242, 196, 106), (176, 138, 74), (110, 82, 48), (85, 64, 42), "oil"),
    "nukeflats": ((168, 200, 122), (122, 154, 88), (106, 122, 74), (79, 92, 56), "nuke"),
    "vinebelt": ((122, 184, 90), (74, 138, 62), (62, 110, 48), (47, 84, 38), "jungle"),
    "gloomkeep": ((58, 46, 88), (42, 32, 68), (44, 36, 64), (32, 26, 48), "gothic"),
    "ashfall": ((138, 122, 114), (106, 90, 82), (74, 64, 56), (56, 48, 42), "ash"),
    "dunefort": ((242, 180, 106), (208, 154, 82), (224, 184, 120), (200, 156, 88), "dune"),
    "steelcrown": ((106, 138, 200), (74, 106, 168), (90, 98, 114), (68, 76, 90), "city"),
    "ironhold": ((122, 52, 52), (84, 36, 36), (58, 40, 40), (44, 31, 31), "hq"),
}

def _hill(d, w, base_y, hgt, span, fill, seed=1):
    pts = [(0, base_y)]
    x = 0
    i = 0
    while x < w:
        x += span * (0.7 + ((i * 7 + seed * 13) % 10) / 18.0)
        y = base_y - hgt * (0.4 + ((i * 11 + seed * 7) % 10) / 14.0)
        pts.append((min(x, w), y))
        i += 1
    pts += [(w, base_y), (w, base_y + 400), (0, base_y + 400)]
    d.polygon(pts, fill=fill)

def _tower(d, x, base_y, w, h, fill):
    d.rectangle((x, base_y - h, x + w, base_y), fill=fill)
    d.rectangle((x + w // 4, base_y - h - w // 2, x + w - w // 4, base_y - h), fill=fill)

def place_bg(pid):
    sky_c, far_c, gnd_c, road_c, theme = PLACE_PAL[pid]
    W, H = 1920, 600
    img, d = canvas(W, H)
    dark = tuple(max(0, c - 34) for c in far_c[:3]) + (255,)
    lit = tuple(min(255, c + 22) for c in far_c[:3]) + (255,)
    base = H - 120
    if theme == "snow":
        _hill(d, W, base, 200, 340, far_c)
        _hill(d, W, base + 50, 150, 260, dark, seed=2)
        for x in range(60, W, 240):                     # pines
            h = 90 + (x * 7 % 50)
            poly(d, [(x, base - h + 40), (x + 26, base + 50), (x - 26, base + 50)], dark)
    elif theme == "coast":
        _hill(d, W, base, 110, 300, far_c)
        for x in range(40, W, 200):                     # waves
            for i in range(3):
                d.arc((x, base - 30 + i * 26, x + 120, base + 10 + i * 26), 200, 340, fill=lit, width=6)
        _tower(d, 300, base, 34, 190, lit)              # lighthouse
        poly(d, [(280, base - 190), (354, base - 190), (334, base - 230), (300, base - 230)], dark)
    elif theme == "oil":
        _hill(d, W, base, 90, 420, far_c)
        for x in range(80, W, 300):                     # derricks
            poly(d, [(x, base), (x + 30, base - 170), (x + 60, base)], dark)
            line(d, (x + 30, base - 170), (x + 30, base - 210), dark, 6)
            ell(d, (x + 18, base - 222, x + 42, base - 198), lit)
        for x in range(200, W, 340):                    # tanks
            ell(d, (x, base - 60, x + 130, base + 10), dark)
    elif theme == "nuke":
        _hill(d, W, base, 70, 460, far_c)
        for x in range(120, W, 380):                    # cooling towers
            poly(d, [(x, base), (x + 26, base - 190), (x + 86, base - 190), (x + 112, base)], dark)
        for x in range(60, W, 380):
            d.rectangle((x, base - 70, x + 40, base), fill=lit)
    elif theme == "jungle":
        _hill(d, W, base, 130, 300, far_c)
        _hill(d, W, base + 60, 90, 220, dark, seed=5)
        for x in range(50, W, 170):                     # palms
            h = 80 + (x * 3 % 60)
            line(d, (x, base + 40), (x + 8, base + 40 - h), dark, 10)
            for ang in range(5):
                a = -math.pi / 2 + (ang - 2) * 0.5
                d.line([(x + 8, base + 40 - h),
                        (x + 8 + math.cos(a) * 46, base + 40 - h + math.sin(a) * 30)],
                       fill=dark, width=8)
    elif theme == "gothic":
        _hill(d, W, base, 160, 260, far_c)
        for x in range(140, W, 420):                    # castles
            _tower(d, x, base, 44, 240, dark)
            poly(d, [(x - 6, base - 240), (x + 22, base - 292), (x + 50, base - 240)], dark)
            _tower(d, x + 60, base, 34, 180, dark)
        for x in range(60, W, 170):                     # pines
            h = 100 + (x * 5 % 40)
            poly(d, [(x, base - h + 60), (x + 22, base + 40), (x - 22, base + 40)], dark)
    elif theme == "ash":
        _hill(d, W, base, 80, 380, far_c)
        for x in range(60, W, 250):                     # ruined shells
            h = 130 + (x * 7 % 80)
            d.rectangle((x, base - h, x + 110, base), fill=dark)
            step = 26
            for i in range(h // step):                  # broken tops
                if (x + i * 13) % 3:
                    d.rectangle((x + (i * 17) % 70, base - h + i * step,
                                 x + 70 + (i * 11) % 40, base - h + i * step + 12), fill=(0, 0, 0, 0))
            for wy in range(base - h + 24, base - 16, 40):
                for wx in range(x + 14, x + 96, 34):
                    d.rectangle((wx, wy, wx + 14, wy + 20), fill=lit)
    elif theme == "dune":
        _hill(d, W, base + 20, 120, 300, far_c)
        _hill(d, W, base + 70, 70, 240, dark, seed=9)
        for x in range(200, W, 520):                    # the fort
            d.rectangle((x, base - 150, x + 200, base + 10), fill=dark)
            for i in range(5):
                d.rectangle((x + i * 42, base - 176, x + 26 + i * 42, base - 150), fill=dark)
    elif theme == "city":
        for x in range(20, W, 130):
            h = 170 + (x * 13 % 190)
            _tower(d, x, base + 20, 80 + (x * 7 % 40), h, far_c if x % 260 < 130 else dark)
            for wy in range(base + 20 - h + 18, base - 6, 34):
                for wx in range(x + 10, x + 70, 26):
                    if (wx * wy) % 5:
                        d.rectangle((wx, wy, wx + 12, wy + 16), fill=lit)
    else:  # hq
        _hill(d, W, base, 90, 400, far_c)
        d.rectangle((240, base - 220, 700, base + 20), fill=dark)      # the wall
        for x in range(260, 700, 90):
            _tower(d, x, base, 40, 260, dark)
        _tower(d, 860, base, 60, 200, lit)              # radar
        d.line([(890, base - 200), (960, base - 300)], fill=lit, width=10)
    save(img, "bg_" + pid)

def place_ground(pid):
    sky_c, far_c, gnd_c, road_c, theme = PLACE_PAL[pid]
    W, H = 1280, 120
    img, d = canvas(W, H)
    d.rectangle((0, 0, W, 52), fill=gnd_c)
    d.rectangle((0, 52, W, H), fill=road_c)
    dark = tuple(max(0, c - 30) for c in gnd_c[:3]) + (255,)
    lit = tuple(min(255, c + 26) for c in gnd_c[:3]) + (255,)
    for x in range(0, W, 64):                            # ground tufts
        h = 8 + (x * 7 % 18)
        poly(d, [(x + 8, 52), (x + 16, 52 - h), (x + 24, 52)], dark)
        if (x * 13) % 5 == 0:
            poly(d, [(x + 36, 52), (x + 42, 52 - h + 4), (x + 50, 52)], lit)
    for x in range(0, W, 128):                           # road dashes
        d.rectangle((x + 20, 82, x + 76, 92), fill=lit)
    save(img, "ground_" + pid)

if os.environ.get("HW_PLACES", "1") == "1":
    for pid in PLACE_PAL:
        place_bg(pid)
        place_ground(pid)
    print("ALL PLACE LAYERS PAINTED")
