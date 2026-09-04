#!/usr/bin/env python3
"""v0.3.3 PATCH 3 - MATCHER assets.
Imports the owner's Match_3_Template zip art (cells + backdrop + pop frames +
richer donuts) as the DEFAULT board look, and bakes the new-mode art (jelly,
ice-crash layers, drop parcel, mine clay/rock layers, ice-storm v2 blocks),
the richer power icons, three new mode cards and a fresh thumbnail.
Deterministic PIL only. All template art is the owner's upload (project use).
"""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageOps

ROOT = "/home/z/my-project/repo/GOGABox/projects/gogabox/assets/games/matcher"
ZIP = "/home/z/my-project/asset_trials/m3t/sprites"
A = ROOT


def zpath(folder):
    import glob
    fs = sorted(glob.glob(os.path.join(ZIP, folder, "*.png")))
    return fs


def save(im, rel):
    p = os.path.join(A, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    im.save(p)
    print("wrote", rel, im.size)


# ---------------------------------------------------------------- template imports
# 1) the default board CELLS: the template's own checker pair (good contrast)
pf_light = Image.open(zpath("spr_play_field_light")[0]).convert("RGBA")
pf_dark = Image.open(zpath("spr_play_field_dark")[0]).convert("RGBA")
save(pf_light.resize((120, 120), Image.LANCZOS), "bg/cell_tpl_light.png")
save(pf_dark.resize((120, 120), Image.LANCZOS), "bg/cell_tpl_dark.png")

# 2) the default BACKDROP: the template background, cover-cropped 1080x1920
bg = Image.open(zpath("spr_background")[0]).convert("RGBA")
w, h = bg.size
s = max(1080 / w, 1920 / h)
bg2 = bg.resize((int(w * s + 0.5), int(h * s + 0.5)), Image.LANCZOS)
x = (bg2.width - 1080) // 2
y = (bg2.height - 1920) // 2
save(bg2.crop((x, y, x + 1080, y + 1920)), "bg/bg_tpl.png")

# 3) the pop FX frames (8 donut-pop frames) -> gem pop animation sheet frames
pops = zpath("spr_effect_pieces")
for i, f in enumerate(pops[:8]):
    im = Image.open(f).convert("RGBA").resize((120, 120), Image.LANCZOS)
    save(im, "fx/popfx_%d.png" % i)

# 4) the RICHER donuts (objective tokens) upgrade the donut skin gems
#    base color order: 0 blue, 1 red, 2 green, 3 yellow, 4 purple
toks = zpath("spr_objective_tokens")
# identify each token's dominant hue and map to the 5 base colors
import colorsys
def hue_of(im):
    im2 = im.convert("RGBA").resize((32, 32))
    px = [p for p in im2.getdata() if p[3] > 200]
    r = sum(p[0] for p in px) / max(1, len(px))
    g = sum(p[1] for p in px) / max(1, len(px))
    b = sum(p[2] for p in px) / max(1, len(px))
    hh, ss, vv = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return hh * 360, ss

want = {"blue": 0, "red": 1, "green": 2, "yellow": 3, "purple": 4}
def which(hh, ss):
    if ss < 0.25:
        return None
    if hh < 18 or hh >= 330: return "red"
    if 18 <= hh < 45: return "orange?"  # orange reads as red-family; treat as red
    if 45 <= hh < 75: return "yellow"
    if 75 <= hh < 170: return "green"
    if 170 <= hh < 260: return "blue"
    return "purple"

used = {}
for f in toks:
    im = Image.open(f).convert("RGBA")
    hh, ss = hue_of(im)
    name = which(hh, ss)
    if name in want and name not in used:
        used[name] = f

for name, idx in want.items():
    if name in used:
        im = Image.open(used[name]).convert("RGBA").resize((100, 100), Image.LANCZOS)
        save(im, "gems/donut_%d.png" % idx)
    else:
        print("WARN no token for", name)

# ---------------------------------------------------------------- new-mode art
def rr(draw, box, rad, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=rad, fill=fill, outline=outline, width=width)


# --- JELLY block: glossy wobbly candy square, translucent magenta
def jelly():
    S = 120
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    body = (236, 84, 168)
    # wobbly rounded body
    d.ellipse((8, 18, 112, 108), fill=body + (205,))
    d.ellipse((2, 30, 118, 100), fill=body + (205,))
    # darker base (depth)
    d.ellipse((14, 62, 106, 106), fill=(180, 44, 128, 215))
    # gloss
    gl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dg = ImageDraw.Draw(gl)
    dg.ellipse((22, 26, 62, 52), fill=(255, 255, 255, 170))
    dg.ellipse((70, 34, 88, 46), fill=(255, 255, 255, 120))
    gl = gl.filter(ImageFilter.GaussianBlur(4))
    im.alpha_composite(gl)
    # rim
    d2 = ImageDraw.Draw(im)
    d2.ellipse((8, 18, 112, 108), outline=(255, 190, 230, 220), width=3)
    im.save(os.path.join(A, "modes/jelly.png"))
    print("wrote modes/jelly.png")


jelly()


# --- ICE CRASH layers 1..6 (5 ice + rock), full-cell blocks with growing cracks
def icecrash():
    tints = {
        1: (196, 232, 250, 215),
        2: (140, 200, 240, 225),
        3: (84, 156, 220, 232),
        4: (70, 106, 200, 238),
        5: (226, 244, 255, 245),
    }
    S = 120
    for lvl, col in tints.items():
        im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        rr(d, (6, 6, 114, 114), 14, col)
        # inner shading (composited, not replaced - PIL replaces pixels)
        shade = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ds = ImageDraw.Draw(shade)
        rr(ds, (14, 14, 106, 106), 10, (255, 255, 255, 46))
        im.alpha_composite(shade)
        # cracks grow with level
        rnd = 12345 + lvl * 977
        import random
        r2 = random.Random(rnd)
        crack = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        dc = ImageDraw.Draw(crack)
        for k in range(lvl * 2):
            x0, y0 = r2.randint(16, 104), r2.randint(16, 104)
            pts = [(x0, y0)]
            for s2 in range(3):
                x0 += r2.randint(-22, 22)
                y0 += r2.randint(-22, 22)
                pts.append((x0, y0))
            dc.line(pts, fill=(255, 255, 255, 160), width=2)
        im.alpha_composite(crack)
        # gloss
        gl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        dg = ImageDraw.Draw(gl)
        dg.polygon([(18, 12), (66, 12), (34, 52), (12, 34)], fill=(255, 255, 255, 90))
        im.alpha_composite(gl)
        rr(ImageDraw.Draw(im), (6, 6, 114, 114), 14, None, (255, 255, 255, 190), 3)
        im.save(os.path.join(A, "modes/icec_%d.png" % lvl))
        print("wrote modes/icec_%d.png" % lvl)
    # level 6 = THE ROCK: gray boulder with heavy cracks + ice rim
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rr(d, (6, 6, 114, 114), 16, (96, 104, 118, 255))
    rr(d, (12, 12, 108, 108), 12, (128, 136, 150, 255))
    import random
    r2 = random.Random(777)
    for k in range(14):
        x0, y0 = r2.randint(14, 106), r2.randint(14, 106)
        d.line([(x0, y0), (x0 + r2.randint(-26, 26), y0 + r2.randint(-26, 26))],
               fill=(58, 64, 76, 220), width=3)
    d.ellipse((20, 18, 52, 44), fill=(160, 168, 182, 200))
    rr(d, (6, 6, 114, 114), 16, None, (210, 226, 240, 230), 4)
    im.save(os.path.join(A, "modes/icec_6.png"))
    print("wrote modes/icec_6.png")


icecrash()


# --- DROP-DOWN item: the gem parcel (crate banded with the 5 base gem colors)
def parcel():
    S = 120
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    band_cols = [(110, 192, 235), (232, 76, 96), (110, 200, 120), (245, 196, 70), (196, 120, 220)]
    # crate body
    rr(d, (12, 22, 108, 104), 16, (122, 84, 44, 255))
    rr(d, (18, 28, 102, 98), 12, (168, 118, 62, 255))
    # 5 color bands
    bw = 84 / 5
    for i, c in enumerate(band_cols):
        x0 = 22 + int(i * bw)
        rr(d, (x0, 34, x0 + int(bw) - 4, 56), 6, c + (255,))
    # rope
    d.rectangle((20, 62, 100, 70), fill=(96, 62, 30, 255))
    # gem glyph
    d.polygon([(60, 70), (78, 82), (60, 96), (42, 82)], fill=(240, 250, 255, 255))
    d.polygon([(60, 70), (78, 82), (60, 84)], fill=(180, 220, 250, 255))
    # gloss + rim
    gl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dg = ImageDraw.Draw(gl)
    dg.ellipse((26, 24, 70, 42), fill=(255, 255, 255, 120))
    im.alpha_composite(gl)
    rr(d, (12, 22, 108, 104), 16, None, (70, 44, 18, 255), 4)
    # sparkle
    d.polygon([(88, 12), (92, 20), (100, 24), (92, 28), (88, 36), (84, 28), (76, 24), (84, 20)],
              fill=(255, 255, 220, 230))
    im.save(os.path.join(A, "modes/item_parcel.png"))
    print("wrote modes/item_parcel.png")


parcel()


# --- MINE layers: clay (2-hit) and rock (special-only), 120px dirt-framed
def earth_layers():
    base = Image.open(os.path.join(A, "modes/earth.png")).convert("RGBA")
    # clay: re-tint base toward red-brown + crack lines
    cl = base.copy()
    px = cl.load()
    for y in range(cl.height):
        for x in range(cl.width):
            r, g, b, a2 = px[x, y]
            if a2 > 0:
                px[x, y] = (min(255, int(r * 1.12) + 14), int(g * 0.82), int(b * 0.74), a2)
    d = ImageDraw.Draw(cl)
    import random
    r2 = random.Random(42)
    for k in range(6):
        x0, y0 = r2.randint(14, 100), r2.randint(14, 100)
        d.line([(x0, y0), (x0 + r2.randint(-18, 18), y0 + r2.randint(-14, 14))],
               fill=(70, 30, 20, 200), width=2)
    cl.save(os.path.join(A, "modes/earth_clay.png"))
    print("wrote modes/earth_clay.png")
    # rock: gray boulder sitting in the dirt frame
    rk = base.copy()
    d2 = ImageDraw.Draw(rk)
    d2.ellipse((18, 18, 102, 102), fill=(104, 110, 122, 255))
    d2.ellipse((26, 24, 76, 62), fill=(136, 142, 154, 255))
    r3 = random.Random(99)
    for k in range(8):
        x0, y0 = r3.randint(24, 96), r3.randint(24, 96)
        d2.line([(x0, y0), (x0 + r3.randint(-16, 16), y0 + r3.randint(-16, 16))],
                fill=(62, 66, 76, 230), width=3)
    d2.ellipse((18, 18, 102, 102), outline=(58, 62, 72, 255), width=4)
    rk.save(os.path.join(A, "modes/earth_rock.png"))
    print("wrote modes/earth_rock.png")


earth_layers()


# --- ICE STORM v2 blocks: full-cell frosted panels; top segment wears the snow cap
def ice_blocks():
    S = 120
    import random
    r2 = random.Random(7)
    # mid block
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rr(d, (2, 2, 118, 118), 10, (108, 176, 226, 216))
    inner = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    di = ImageDraw.Draw(inner)
    rr(di, (10, 10, 110, 110), 8, (170, 220, 248, 140))
    im.alpha_composite(inner)
    crack = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dc = ImageDraw.Draw(crack)
    for k in range(9):
        x0, y0 = r2.randint(12, 104), r2.randint(12, 104)
        dc.line([(x0, y0), (x0 + r2.randint(-20, 20), y0 + r2.randint(-20, 20))],
                fill=(228, 246, 255, 120), width=2)
    im.alpha_composite(crack)
    gl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dg = ImageDraw.Draw(gl)
    dg.polygon([(14, 8), (58, 8), (30, 44), (8, 26)], fill=(255, 255, 255, 80))
    im.alpha_composite(gl)
    rr(d, (2, 2, 118, 118), 10, None, (235, 250, 255, 200), 3)
    im.save(os.path.join(A, "modes/ice_block.png"))
    print("wrote modes/ice_block.png")
    # top block with the snow cap (bumpy white ridge on the top edge)
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rr(d, (2, 14, 118, 118), 10, (108, 176, 226, 216))
    inner = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    di = ImageDraw.Draw(inner)
    rr(di, (10, 22, 110, 110), 8, (170, 220, 248, 140))
    im.alpha_composite(inner)
    crack = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dc = ImageDraw.Draw(crack)
    for k in range(9):
        x0, y0 = r2.randint(12, 104), r2.randint(24, 108)
        dc.line([(x0, y0), (x0 + r2.randint(-20, 20), y0 + r2.randint(-20, 20))],
                fill=(228, 246, 255, 120), width=2)
    im.alpha_composite(crack)
    # the cap
    d.ellipse((-8, 0, 40, 30), fill=(244, 252, 255, 255))
    d.ellipse((24, -6, 76, 30), fill=(244, 252, 255, 255))
    d.ellipse((66, 0, 116, 30), fill=(244, 252, 255, 255))
    d.rectangle((0, 14, 120, 22), fill=(244, 252, 255, 255))
    gl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dg = ImageDraw.Draw(gl)
    dg.polygon([(14, 22), (58, 22), (30, 58), (8, 40)], fill=(255, 255, 255, 80))
    im.alpha_composite(gl)
    rr(d, (2, 14, 118, 118), 10, None, (235, 250, 255, 220), 3)
    im.save(os.path.join(A, "modes/ice_block_top.png"))
    print("wrote modes/ice_block_top.png")


ice_blocks()


# --- richer POWER icons (132px, gold-rimmed round buttons + glyph + gloss)
def power_icons():
    S = 132
    specs = {
        "p_shuffle": {"ring": (86, 156, 220), "glyph": "shuffle"},
        "p_line": {"ring": (240, 170, 60), "glyph": "line"},
        "p_bomb": {"ring": (226, 92, 84), "glyph": "bomb"},
        "p_vapor": {"ring": (186, 96, 216), "glyph": "vapor"},
    }
    import random
    for name, sp in specs.items():
        im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        c = sp["ring"]
        # outer gold rim + body
        d.ellipse((6, 6, 126, 126), fill=(212, 168, 72, 255))
        d.ellipse((12, 12, 120, 120), fill=c + (255,))
        d.ellipse((20, 20, 112, 112), fill=tuple(min(255, int(v * 1.18)) for v in c[:3]) + (255,))
        # glyph
        g = ImageDraw.Draw(im)
        if sp["glyph"] == "shuffle":
            pts = [(38, 88), (58, 44), (94, 44)]
            g.line([(34, 92), (58, 48), (76, 84), (98, 44)], fill=(255, 255, 255, 240), width=9, joint="curve")
            g.polygon([(96, 30), (112, 46), (92, 56)], fill=(255, 255, 255, 240))
            g.polygon([(30, 78), (46, 94), (26, 104)], fill=(255, 255, 255, 240))
        elif sp["glyph"] == "line":
            g.rectangle((28, 58, 104, 74), fill=(255, 255, 255, 240))
            g.rectangle((58, 28, 74, 104), fill=(255, 255, 220, 200))
        elif sp["glyph"] == "bomb":
            g.ellipse((38, 44, 92, 98), fill=(40, 36, 44, 255))
            g.rectangle((60, 28, 70, 48), fill=(120, 90, 40, 255))
            # fuse spark
            g.polygon([(74, 18), (80, 30), (68, 28)], fill=(255, 220, 120, 255))
            g.ellipse((48, 54, 62, 66), fill=(255, 255, 255, 70))
        elif sp["glyph"] == "vapor":
            for i, y0 in enumerate((30, 54, 78)):
                g.arc((34, y0, 98, y0 + 30), 200, 340, fill=(255, 255, 255, 235), width=9)
        # gloss
        gl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        dg = ImageDraw.Draw(gl)
        dg.ellipse((22, 16, 84, 46), fill=(255, 255, 255, 130))
        im.alpha_composite(gl)
        im.save(os.path.join(A, "power/%s.png" % name))
        print("wrote power/%s.png" % name)


power_icons()


# --- 3 new mode cards (460x240, the existing card format)
def card(fname, sky, art_fn, title):
    im = Image.new("RGBA", (460, 240), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rr(d, (4, 4, 456, 236), 22, sky)
    # soft vignette
    vg = Image.new("RGBA", (460, 240), (0, 0, 0, 0))
    dvg = ImageDraw.Draw(vg)
    dvg.ellipse((-80, 120, 540, 420), fill=(0, 0, 0, 60))
    im.alpha_composite(vg)
    art_fn(d, im)
    t = Image.new("RGBA", (460, 240), (0, 0, 0, 0))
    dt = ImageDraw.Draw(t)
    dt.rectangle((0, 176, 460, 240), fill=(0, 0, 0, 130))
    im.alpha_composite(t)
    d2 = ImageDraw.Draw(im)
    d2.text((230, 208), title, anchor="mm", fill=(255, 244, 214))
    im.save(os.path.join(A, "modes/%s" % fname))
    print("wrote modes/%s" % fname)


def jelly_art(d, im):
    r = Image.open(os.path.join(A, "modes/jelly.png")).resize((96, 96))
    for i, x in enumerate((96, 196, 296)):
        im.alpha_composite(r, (x, 66 if i == 1 else 84))
    r2 = Image.open(os.path.join(A, "gems/gem_0.png")).resize((56, 56))
    im.alpha_composite(r2, (150, 44))


def icecrash_art(d, im):
    for i, lvl in enumerate((2, 3, 4, 5)):
        r = Image.open(os.path.join(A, "modes/icec_%d.png" % lvl)).resize((84, 84))
        im.alpha_composite(r, (86 + i * 76, 78 + (8 if i % 2 else 0)))


def drop_art(d, im):
    r = Image.open(os.path.join(A, "modes/item_parcel.png")).resize((92, 92))
    im.alpha_composite(r, (184, 64))
    g = Image.open(os.path.join(A, "gems/gem_2.png")).resize((52, 52))
    im.alpha_composite(g, (120, 96))
    g2 = Image.open(os.path.join(A, "gems/gem_1.png")).resize((52, 52))
    im.alpha_composite(g2, (296, 96))


card("card_jelly.png", (94, 60, 110, 255), jelly_art, "JELLY")
card("card_icecrash.png", (52, 84, 130, 255), icecrash_art, "ICE CRASH")
card("card_drop.png", (150, 104, 52, 255), drop_art, "DROP DOWN")
print("PHASE A art done")
