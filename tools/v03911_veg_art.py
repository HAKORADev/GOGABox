#!/usr/bin/env python3
"""v03911_veg_art.py - THE VEGGIE SHELF REDRAW (fruit slasher).

The owner's v0.3.9-11 round: the vegetables "look too poor compared to
the fruits one", the "internal cuts on the vegetable is faked because
it makes it two small vegs", the scale is inaccurate. This tool:

  1. REDRAWS all six vegetables in the fruit set's own language
     (clean silhouette, dark outline, soft radial shading, one honest
     specular) at 2x supersampling - corn and pepper are redrawn
     wholesale (the old husk read like a green M, the pepper read like
     a pumpkin).
  2. Bakes REAL cut halves (v_<name>_h1/h2): the veg's own silhouette
     cut at its content center, the exposed face wearing the true
     flesh (tomato jelly + seeds, carrot core, broccoli pale stem,
     corn milk, pepper ribs) - the generic wedge-squash slice is dead.

Re-derive: python3 tools/v03911_veg_art.py <out_dir>
"""
import math
import sys
import pathlib
from PIL import Image, ImageDraw, ImageFilter

S = 2                       # supersample (draw 512, ship 256)
CANVAS = 256
DRAW = CANVAS * S
CONTENT = 230               # the content box inside the 256 canvas
OUTLINE = (0.16, 0.12, 0.07)


def C(hexs, a=255):
    hexs = hexs.lstrip("#")
    return (int(hexs[0:2], 16), int(hexs[2:4], 16), int(hexs[4:6], 16), a)


def shade_col(c, k):
    """k>0 lighten toward white, k<0 darken."""
    r, g, b = c[:3]
    if k >= 0:
        return (int(r + (255 - r) * k), int(g + (255 - g) * k),
                int(b + (255 - b) * k), 255)
    return (int(r * (1 + k)), int(g * (1 + k)), int(b * (1 + k)), 255)


def radial_shade(size, base, top_light=0.34, edge_dark=0.30,
                 cx=0.44, cy=0.36, rr=0.78):
    """A soft radial gradient image in the base color (light at cx,cy)."""
    w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    icx, icy = int(w * cx), int(h * cy)
    rmax = math.hypot(w, h) * rr
    for y in range(h):
        for x in range(w):
            d = math.hypot(x - icx, y - icy) / rmax
            d = min(1.0, d)
            if d < 0.55:
                k = top_light * (1.0 - d / 0.55)
            else:
                k = -edge_dark * ((d - 0.55) / 0.45)
            px[x, y] = shade_col(base, k)
    return img


def finish(mask_img, body_rgba, outline_col, outline_w=5):
    """Outline from the mask + body + downscale to the canvas."""
    big = mask_img.size[0]
    a = mask_img.split()[0]
    ring = a.filter(ImageFilter.MaxFilter(outline_w * S)) \
        if False else None
    # stroke: dilate - mask
    from PIL import ImageChops
    dil = a.filter(ImageFilter.MaxFilter(outline_w * 2 * S + 1))
    stroke = ImageChops.subtract(dil, a)
    out = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    stroke_img = Image.new("RGBA", (big, big), outline_col)
    out.paste(stroke_img, (0, 0), stroke)
    out.paste(body_rgba, (0, 0), body_rgba)
    return out.resize((CANVAS, CANVAS), Image.LANCZOS)


def fit(mask):
    """Trim to the content box and center it in the canvas (2x space)."""
    bbox = mask.getchannel("A").getbbox()
    side = max(bbox[2] - bbox[0], bbox[3] - bbox[1])
    canvas = Image.new("RGBA", (DRAW, DRAW), (0, 0, 0, 0))
    canvas.paste(mask, ((DRAW - side) // 2 - bbox[0],
                        (DRAW - side) // 2 - bbox[1]), mask)
    return canvas


def ellipse_layer(draw_size, spec):
    """spec: list of (box, color) - a quick composed shape layer."""
    img = Image.new("RGBA", (draw_size, draw_size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for box, col in spec:
        d.ellipse(box, fill=col)
    return img


def spec_mark(img, box, a=150):
    """The honest specular: one soft white streak."""
    w = int((box[2] - box[0]) * 0.5)
    h = int((box[3] - box[1]) * 0.5)
    mark = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(mark)
    d.ellipse(box, fill=(255, 255, 255, a))
    d.ellipse((box[0] + w // 3, box[1] + h // 3,
               box[2] - w // 3, box[3] - h // 3), fill=(255, 255, 255, a // 2))
    mark = mark.filter(ImageFilter.GaussianBlur(6 * S))
    out = img.copy()
    out.alpha_composite(mark)
    return out


# ------------------------------------------------------------ the vegs

def carrot():
    big = DRAW
    mask = Image.new("L", (big, big), 0)
    dm = ImageDraw.Draw(mask)
    # the root: a tapered cone, slightly curved
    top_y = int(big * 0.30)
    tip_y = int(big * 0.94)
    cx = int(big * 0.50)
    w_top = int(big * 0.17)
    dm.polygon([(cx - w_top, top_y), (cx + w_top, top_y),
                (cx + int(w_top * 0.28), tip_y),
                (cx, tip_y + int(big * 0.012)),
                (cx - int(w_top * 0.10), tip_y)], fill=255)
    body = radial_shade((big, big), C("f07822"), top_light=0.30,
                        edge_dark=0.26, cx=0.42, cy=0.40, rr=0.75)
    body.putalpha(mask)
    d = ImageDraw.Draw(body)
    # the ridges (the carrot's honest rings)
    for i, fy in enumerate([0.44, 0.56, 0.68, 0.80]):
        y = int(big * fy)
        ww = w_top * (1.0 - (fy - 0.30) / 0.66)
        d.arc((cx - ww, y - int(big * 0.02), cx + ww,
               y + int(big * 0.055)), 200, 340,
              fill=shade_col(C("f07822"), -0.30), width=3 * S)
    # the greens: five feathered leaves
    leaf = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    dl = ImageDraw.Draw(leaf)
    for i, (ang, ln) in enumerate([(-58, 0.20), (-30, 0.26), (0, 0.30),
                                   (28, 0.26), (56, 0.20)]):
        a = math.radians(ang - 90)
        x1 = cx + math.cos(a) * big * 0.045
        y1 = top_y - big * 0.01
        x2 = cx + math.cos(a) * big * ln
        y2 = top_y - big * 0.01 - abs(math.sin(a)) * big * ln * 1.7
        dl.line((x1, y1, x2, y2), fill=C("3f8f3f"), width=int(9 * S))
        dl.line((x1, y1, x2, y2), fill=C("63b544"), width=int(4 * S))
    body.alpha_composite(leaf)
    return finish(mask.convert("RGBA"), body, C("5a3410"), 5)


def tomato():
    big = DRAW
    mask = Image.new("L", (big, big), 0)
    dm = ImageDraw.Draw(mask)
    dm.ellipse((big * 0.13, big * 0.24, big * 0.87, big * 0.96), fill=255)
    body = radial_shade((big, big), C("e63c30"), top_light=0.38,
                        edge_dark=0.28, cx=0.42, cy=0.42, rr=0.72)
    body.putalpha(mask)
    d = ImageDraw.Draw(body)
    # the calyx: five soft green stars
    calyx = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    dc = ImageDraw.Draw(calyx)
    ccy = big * 0.28
    for i in range(5):
        a = math.radians(-90 + (i - 2) * 38)
        x2 = big * 0.5 + math.cos(a) * big * 0.14
        y2 = ccy - math.sin(a) * big * 0.10 + big * 0.03
        dc.polygon([(big * 0.5, ccy), (x2, y2),
                    (big * 0.5 + math.cos(a + 1.35) * big * 0.03,
                     ccy + big * 0.035)], fill=C("3e8f46"))
    dc.ellipse((big * 0.44, ccy - big * 0.03, big * 0.56, ccy + big * 0.04),
               fill=C("4fa356"))
    body.alpha_composite(calyx)
    body = spec_mark(body, (big * 0.28, big * 0.42, big * 0.42,
                            big * 0.54))
    return finish(mask.convert("RGBA"), body, C("4a140c"), 5)


def eggplant():
    big = DRAW
    mask = Image.new("L", (big, big), 0)
    dm = ImageDraw.Draw(mask)
    dm.ellipse((big * 0.30, big * 0.34, big * 0.70, big * 0.96), fill=255)
    dm.ellipse((big * 0.36, big * 0.16, big * 0.64, big * 0.62), fill=255)
    body = radial_shade((big, big), C("5d2a8f"), top_light=0.34,
                        edge_dark=0.30, cx=0.40, cy=0.44, rr=0.74)
    body.putalpha(mask)
    d = ImageDraw.Draw(body)
    # the calyx cap: three pointed leaves over the shoulder
    cap = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    dc = ImageDraw.Draw(cap)
    cy = big * 0.30
    for i, (dx, dy) in enumerate([(-0.13, 0.06), (0.0, 0.0), (0.13, 0.06)]):
        dc.polygon([(big * 0.5 + big * dx - big * 0.05, cy + big * dy),
                    (big * 0.5 + big * dx, cy - big * 0.10 + big * dy),
                    (big * 0.5 + big * dx + big * 0.05, cy + big * dy)],
                   fill=C("4c8f3c"))
    dc.ellipse((big * 0.36, cy - big * 0.02, big * 0.64, cy + big * 0.07),
               fill=C("579f45"))
    body.alpha_composite(cap)
    body = spec_mark(body, (big * 0.40, big * 0.44, big * 0.50,
                            big * 0.66), a=130)
    return finish(mask.convert("RGBA"), body, C("22103a"), 5)


def broccoli():
    big = DRAW
    mask = Image.new("L", (big, big), 0)
    dm = ImageDraw.Draw(mask)
    # the stem
    dm.rounded_rectangle((big * 0.42, big * 0.62, big * 0.58, big * 0.94),
                         radius=big * 0.05, fill=255)
    # the crown: clustered bumps
    import random
    rnd = random.Random(11)
    for i in range(9):
        a = math.pi * (i / 8.0)
        bx = big * 0.5 - math.cos(a) * big * 0.24
        by = big * 0.44 - math.sin(a) * big * 0.16
        r = big * (0.10 + 0.035 * rnd.random())
        dm.ellipse((bx - r, by - r, bx + r, by + r), fill=255)
    dm.ellipse((big * 0.24, big * 0.30, big * 0.76, big * 0.72), fill=255)
    body = radial_shade((big, big), C("3e7d32"), top_light=0.32,
                        edge_dark=0.26, cx=0.42, cy=0.34, rr=0.8)
    body.putalpha(mask)
    d = ImageDraw.Draw(body)
    # the stem wears its own pale green
    stem = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    ds = ImageDraw.Draw(stem)
    ds.rounded_rectangle((big * 0.42, big * 0.62, big * 0.58, big * 0.94),
                         radius=big * 0.05, fill=C("b9d48a"))
    ds.rounded_rectangle((big * 0.45, big * 0.62, big * 0.50, big * 0.94),
                         radius=big * 0.03, fill=C("d3e7ab"))
    body.alpha_composite(stem)
    # the floret texture: dark dots on the crown
    rnd2 = random.Random(7)
    for i in range(46):
        x = big * (0.26 + 0.48 * rnd2.random())
        y = big * (0.28 + 0.36 * rnd2.random())
        if mask.getpixel((int(x), int(y))) > 0 and y < big * 0.66:
            r = big * 0.012
            d.ellipse((x - r, y - r, x + r, y + r),
                      fill=shade_col(C("3e7d32"), -0.34))
    return finish(mask.convert("RGBA"), body, C("1d3a14"), 5)


def corn():
    big = DRAW
    mask = Image.new("L", (big, big), 0)
    dm = ImageDraw.Draw(mask)
    # the cob: a fat rounded column
    dm.rounded_rectangle((big * 0.36, big * 0.16, big * 0.64, big * 0.88),
                         radius=big * 0.13, fill=255)
    body = radial_shade((big, big), C("f2c53d"), top_light=0.30,
                        edge_dark=0.24, cx=0.40, cy=0.36, rr=0.8)
    body.putalpha(mask)
    d = ImageDraw.Draw(body)
    # the kernels: an honest grid of plump rows (light + dark faces)
    for gy in range(7):
        y = big * (0.185 + gy * 0.098)
        row_off = big * 0.045 if gy % 2 else 0.0
        for gx in range(3):
            x = big * 0.415 + gx * big * 0.082 + row_off
            r = big * 0.030
            d.ellipse((x - r, y - r, x + r, y + r),
                      fill=shade_col(C("f2c53d"), 0.24))
            d.arc((x - r, y - r, x + r, y + r), 20, 200,
                  fill=shade_col(C("d8a520"), 0.0), width=2 * S)
    # the husk: two leaves peeling down at the sides + a small tuft
    husk = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    dh = ImageDraw.Draw(husk)
    for sgn in (-1, 1):
        x0 = big * 0.5 + sgn * big * 0.06
        dh.polygon([(x0, big * 0.26),
                    (x0 + sgn * big * 0.17, big * 0.52),
                    (x0 + sgn * big * 0.15, big * 0.86),
                    (x0 + sgn * big * 0.02, big * 0.62),
                    (x0 - sgn * big * 0.015, big * 0.34)],
                   fill=C("5ea345"))
        dh.polygon([(x0, big * 0.30),
                    (x0 + sgn * big * 0.10, big * 0.55),
                    (x0 + sgn * big * 0.05, big * 0.72)],
                   fill=C("7cbf5b"))
    dh.polygon([(big * 0.47, big * 0.18), (big * 0.53, big * 0.18),
                (big * 0.51, big * 0.06), (big * 0.49, big * 0.06)],
               fill=C("6cb050"))
    body.alpha_composite(husk)
    return finish(mask.convert("RGBA"), body, C("4a3410"), 5)


def pepper():
    big = DRAW
    mask = Image.new("L", (big, big), 0)
    dm = ImageDraw.Draw(mask)
    # the bell: three vertical lobes, squared shoulders, flat-ish base
    dm.ellipse((big * 0.20, big * 0.30, big * 0.80, big * 0.92), fill=255)
    dm.ellipse((big * 0.12, big * 0.36, big * 0.46, big * 0.88), fill=255)
    dm.ellipse((big * 0.54, big * 0.36, big * 0.88, big * 0.88), fill=255)
    dm.rounded_rectangle((big * 0.16, big * 0.34, big * 0.84, big * 0.74),
                         radius=big * 0.10, fill=255)
    body = radial_shade((big, big), C("3f9a3e"), top_light=0.30,
                        edge_dark=0.30, cx=0.42, cy=0.34, rr=0.78)
    body.putalpha(mask)
    d = ImageDraw.Draw(body)
    # the creases: two long vertical curves between the lobes
    for fx in (0.40, 0.60):
        pts = []
        for i in range(9):
            t = i / 8.0
            y = big * (0.38 + 0.50 * t)
            bow = math.sin(t * math.pi) * big * 0.02
            x = big * fx + bow * (-1 if fx < 0.5 else 1)
            pts.append((x, y))
        d.line(pts, fill=shade_col(C("3f9a3e"), -0.26), width=4 * S,
               joint="curve")
    # the stem block
    cap = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    dc = ImageDraw.Draw(cap)
    dc.rounded_rectangle((big * 0.455, big * 0.14, big * 0.545,
                          big * 0.36), radius=big * 0.035,
                         fill=C("4c7a30"))
    dc.ellipse((big * 0.38, big * 0.24, big * 0.62, big * 0.37),
               fill=C("57944a"))
    body.alpha_composite(cap)
    body = spec_mark(body, (big * 0.26, big * 0.40, big * 0.38,
                            big * 0.55))
    return finish(mask.convert("RGBA"), body, C("12330f"), 5)


# ------------------------------------------------------- the cut faces

FLESH = {
    "carrot": {"face": C("ffc37a"), "core": C("ffe3ae"), "rim": C("e07414"),
               "top": 0.30},
    "tomato": {"face": C("ff7a6e"), "core": C("ffd0a6"), "rim": C("d8352a"),
               "top": 0.20},
    "eggplant": {"face": C("f2ecd2"), "core": C("fbf7e6"), "rim": C("5d2a8f"),
                 "top": 0.24},
    "broccoli": {"face": C("cfe8a8"), "core": C("e4f2c8"), "rim": C("3e7d32"),
                 "top": 0.12},
    "corn": {"face": C("ffe9a3"), "core": C("fff3c8"), "rim": C("d8a520"),
             "top": 0.16},
    "pepper": {"face": C("f4f0d8"), "core": C("fdfbef"), "rim": C("2f7a2e"),
               "top": 0.26},
}


def half(name, src, side):
    """side -1 = LEFT half (face on its right edge), +1 = RIGHT half.

    THE REAL CUT: the exposed face is clipped to the veg's own
    silhouette, the old outline is erased along the cut (a real cut
    has no skin on the face), and the rim line only rides where the
    veg actually is.
    """
    from PIL import ImageChops
    w, h = src.size
    bbox = src.getchannel("A").getbbox()
    cut = (bbox[0] + bbox[2]) // 2
    whole_a = src.split()[3]
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    f = FLESH[name]
    band = max(6 * S, int((bbox[2] - bbox[0]) * 0.14))
    top_y = bbox[1] + int((bbox[3] - bbox[1]) * f.get("top", 0.0))
    if side < 0:
        piece = src.crop((0, 0, cut, h))
        out.paste(piece, (0, 0), piece)
    else:
        piece = src.crop((cut, 0, w, h))
        out.paste(piece, (cut, 0), piece)
    # erase the piece's skin along the cut (the face replaces it)
    erase = Image.new("L", (w, h), 0)
    de = ImageDraw.Draw(erase)
    ex0 = cut - band if side < 0 else cut
    de.rectangle((ex0, top_y, ex0 + band, bbox[3] + 2), fill=255)
    out.putalpha(ImageChops.subtract(out.split()[3], erase))
    # the face: flesh band clipped to the WHOLE silhouette
    face = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    df = ImageDraw.Draw(face)
    fx0 = cut - band if side < 0 else cut
    df.rectangle((fx0, top_y, fx0 + band, bbox[3]),
                 fill=f["face"])
    cx0 = cut - band // 2 if side < 0 else cut
    df.rectangle((cx0, top_y, cx0 + band // 2, bbox[3]),
                 fill=f["core"])
    face.putalpha(ImageChops.multiply(face.split()[3], whole_a))
    out.alpha_composite(face)
    # the rim: only where the veg lives
    rim = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dr = ImageDraw.Draw(rim)
    dr.line((cut, top_y, cut, bbox[3]), fill=f["rim"], width=2 * S)
    rim.putalpha(ImageChops.multiply(rim.split()[3], whole_a))
    out.alpha_composite(rim)
    return out


def ImageChops_multiply(a, b):
    from PIL import ImageChops
    return ImageChops.multiply(a, b)


NAMES = ["carrot", "tomato", "eggplant", "broccoli", "corn", "pepper"]
MAKERS = {"carrot": carrot, "tomato": tomato, "eggplant": eggplant,
          "broccoli": broccoli, "corn": corn, "pepper": pepper}


def main():
    out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1
                       else "projects/gogabox/assets/games/slasher")
    for n in NAMES:
        whole = MAKERS[n]()
        whole.save(out / f"v_{n}.png")
        half(n, whole, -1).save(out / f"v_{n}_h1.png")
        half(n, whole, +1).save(out / f"v_{n}_h2.png")
        print("  drew", n)


if __name__ == "__main__":
    main()
