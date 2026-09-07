#!/usr/bin/env python3
"""v0.3.5-6 POP SIEGE art pass (the owner's round):
- marshal + kaching heads REDRAWN rich (the owner: "Marichal and kaching
  looks somehow low quality, they need proper modification for their heads")
  - the war drum: golden standards, lacquered stave shell, double rims with
    bolts, Z-rope tension, crossed mallets, twin-tail banner; the gear ladder
    reads steel -> brass -> gold
  - the bank vault: a real round safe (riveted ring, spoke wheel, dial,
    keyhole) on a mound of coins + ingots; the gear ladder grows the gold
- ALL face chips REBUILT cover-fill (the owner: "the design of characters/
  weapons icons is bad ... pyra and boomo are good, make the others like
  that"): the head's content is trimmed and ZOOMED to fill the disc the way
  pyra/boomo already do - no more tiny floating objects in empty circles
(boomba's butt-facing is a code fix: pd_data head_offset PI -> 0)
"""
import math
from PIL import Image, ImageDraw

ADIR = "/home/z/my-project/repo/GOGABox/projects/gogabox/assets/games/pop_siege"
INK = (45, 30, 20, 255)


def save(im, rel):
    im.save(f"{ADIR}/{rel}")
    print("wrote", rel, im.size)


def outlined(im, width=2, color=INK):
    """a clean 1px-feel ink contour around the alpha shape (the house style)"""
    a = im.split()[3].point(lambda v: 255 if v >= 40 else 0)
    from PIL import ImageFilter
    big = a.filter(ImageFilter.MaxFilter(width * 2 + 1))
    ring = Image.new("RGBA", im.size, color)
    ring.putalpha(big)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.alpha_composite(ring)
    out.alpha_composite(im)
    return out


def vgrad(w, h, stops):
    """vertical gradient image; stops = [(y0frac, (r,g,b)), ...]"""
    im = Image.new("RGB", (1, h))
    px = im.load()
    for y in range(h):
        t = y / max(1, h - 1)
        for i in range(len(stops) - 1):
            t0, c0 = stops[i]
            t1, c1 = stops[i + 1]
            if t0 <= t <= t1:
                k = (t - t0) / max(1e-6, t1 - t0)
                px[0, y] = tuple(int(c0[j] + (c1[j] - c0[j]) * k) for j in range(3))
                break
    return im.resize((w, h))


# ---------------------------------------------------------------- marshal
def draw_drum(gear):
    """marshal head v2: a war drum on golden standards with crossed mallets
    and a twin-tail banner. Gear ladder: steel -> brass -> gold."""
    S = 3
    W, H = 80 * S, 70 * S
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tier = [((150, 158, 172), (96, 104, 122)),      # g1 steel
            ((212, 168, 74), (164, 118, 40)),       # g2 brass
            ((250, 206, 84), (204, 148, 34))][gear - 1]  # g3 gold
    rim_hi, rim_lo = tier
    shell_a = (176 + gear * 8, 44 + gear * 8, 52, 255)
    shell_b = (222 + gear * 6, 88 + gear * 8, 78, 255)
    cream = (246, 230, 200, 255)
    ink = (60, 22, 22, 255)

    cx = W // 2
    # -- the golden standards (side posts) with finials
    for sx in (14 * S, W - 14 * S):
        d.rounded_rectangle([sx - 3 * S, 16 * S, sx + 3 * S, 56 * S], 3 * S,
                            fill=rim_hi, outline=ink, width=S)
        d.rectangle([sx - 5 * S, 54 * S, sx + 5 * S, 58 * S], fill=rim_lo, outline=ink, width=S)
        d.ellipse([sx - 5 * S, 9 * S, sx + 5 * S, 19 * S], fill=rim_hi, outline=ink, width=S)
        d.ellipse([sx - 2 * S, 12 * S, sx + 1 * S, 15 * S], fill=(255, 250, 220, 255))
    # -- the drum shell (barrel: wider middle), lacquer gradient
    shell = vgrad(52 * S, 34 * S, [(0.0, shell_a[:3]), (0.45, shell_b[:3]), (1.0, shell_a[:3])]).convert("RGBA")
    smask = Image.new("L", shell.size, 0)
    sd = ImageDraw.Draw(smask)
    sd.polygon([(0, 6 * S), (6 * S, 0), (46 * S, 0), (52 * S, 6 * S),
                (52 * S, 28 * S), (46 * S, 34 * S), (6 * S, 34 * S), (0, 28 * S)], fill=255)
    im.paste(shell, (cx - 26 * S, 22 * S), smask)
    d = ImageDraw.Draw(im)
    d.polygon([(cx - 26 * S, 22 * S + 6 * S), (cx - 20 * S, 22 * S), (cx + 20 * S, 22 * S),
               (cx + 26 * S, 22 * S + 6 * S), (cx + 26 * S, 22 * S + 28 * S),
               (cx + 20 * S, 22 * S + 34 * S), (cx - 20 * S, 22 * S + 34 * S),
               (cx - 26 * S, 22 * S + 28 * S)], outline=ink, width=2 * S)
    # stave shading
    for i in range(1, 8):
        x = cx - 26 * S + i * 6 * S + (2 * S if i % 2 else 0)
        d.line([x, 23 * S, x, 22 * S + 33 * S], fill=(120, 26, 30, 90), width=S)
    # -- the skin (top membrane) with a sheen
    d.ellipse([cx - 21 * S, 16 * S, cx + 21 * S, 34 * S], fill=cream, outline=ink, width=2 * S)
    d.arc([cx - 16 * S, 18 * S, cx + 12 * S, 32 * S], 200, 320, fill=(255, 255, 255, 210), width=2 * S)
    # -- the bottom rim (double metal band + bolts)
    d.rounded_rectangle([cx - 24 * S, 50 * S, cx + 24 * S, 56 * S], 3 * S,
                        fill=rim_hi, outline=ink, width=S)
    d.line([cx - 23 * S, 53 * S, cx + 23 * S, 53 * S], fill=rim_lo, width=S)
    for i in range(7):
        bx = cx - 21 * S + i * 7 * S
        d.ellipse([bx - S, 52 * S, bx + S, 54 * S], fill=(30, 20, 16, 255))
    # -- Z rope tension (front lacing)
    rope = (240, 226, 190, 255)
    for i in range(4):
        x0 = cx - 18 * S + i * 10 * S
        d.line([x0, 36 * S, x0 + 8 * S, 42 * S], fill=rope, width=S)
        d.line([x0 + 8 * S, 42 * S, x0, 48 * S], fill=rope, width=S)
    # -- crossed mallets with banded grips
    mgrip = (122, 80, 40, 255)
    d.line([cx - 20 * S, 8 * S, cx + 8 * S, 24 * S], fill=mgrip, width=3 * S)
    d.line([cx + 20 * S, 8 * S, cx - 8 * S, 24 * S], fill=mgrip, width=3 * S)
    for hx in (cx - 20 * S, cx + 20 * S):
        d.ellipse([hx - 5 * S, 3 * S, hx + 5 * S, 13 * S], fill=cream, outline=ink, width=S)
    # -- the twin-tail banner on a short pole
    bx = cx + (16 if gear >= 2 else 18) * S
    d.line([bx, 2 * S, bx, 20 * S], fill=ink, width=S)
    d.ellipse([bx - 2 * S, 0, bx + 2 * S, 4 * S], fill=rim_hi, outline=ink, width=S)
    flagc = (250, 206, 84, 255) if gear >= 3 else (232, 92, 84, 255)
    d.polygon([(bx, 4 * S), (bx + 13 * S, 8 * S), (bx, 13 * S)], fill=flagc, outline=ink)
    d.polygon([(bx, 13 * S), (bx + 11 * S, 17 * S), (bx, 21 * S)],
              fill=(214 + gear * 8, 70 + gear * 8, 60, 255), outline=ink)
    if gear >= 3:
        d.ellipse([cx - 3 * S, 24 * S, cx + 3 * S, 30 * S], fill=(255, 244, 180, 255), outline=ink, width=S)
    im = im.resize((W // S, H // S), Image.LANCZOS)
    return outlined(im, 2)


# ---------------------------------------------------------------- kaching
def draw_vault(gear):
    """kaching head v2: a round bank safe on a mound of gold. Gear ladder
    grows the pile and trims the safe gold."""
    S = 3
    W, H = 82 * S, 70 * S
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ink = (96, 64, 8, 255)
    gold = (250, 190, 40, 255)
    gold_hi = (255, 228, 120, 255)
    gold_lo = (214, 150, 22, 255)
    steel_hi, steel_lo = (172, 182, 198), (108, 116, 134)
    if gear >= 2:
        steel_hi, steel_lo = (222, 190, 110), (172, 134, 54)
    cx = W // 2
    # -- the coin mound (staggered stacks) + ingots at the feet
    stacks = [0, 1] if gear == 1 else ([0, 1, 2] if gear == 2 else [0, 1, 2, 3])
    for si, sc in enumerate(stacks):
        sx = cx + (-22 + si * 14) * S
        for c in range(sc + 1):
            y = (44 - c * 7) * S
            d.ellipse([sx - 9 * S, y, sx + 9 * S, y + 8 * S], fill=gold, outline=ink, width=S)
            d.ellipse([sx - 6 * S, y + 1 * S, sx + 6 * S, y + 5 * S], outline=gold_lo, width=S)
    for ix in (-1, 1):
        x0 = cx + ix * 26 * S
        d.polygon([(x0 - 7 * S, 56 * S), (x0 - 5 * S, 50 * S), (x0 + 5 * S, 50 * S),
                   (x0 + 7 * S, 56 * S)], fill=gold_hi if ix < 0 else gold, outline=ink)
        d.line([x0 - 5 * S, 52 * S, x0 + 5 * S, 52 * S], fill=(255, 246, 200, 220), width=S)
    # -- the safe body: riveted ring + door plate
    d.ellipse([cx - 26 * S, 6 * S, cx + 26 * S, 58 * S], fill=steel_lo + (255,), outline=ink, width=2 * S)
    d.ellipse([cx - 22 * S, 10 * S, cx + 22 * S, 54 * S], fill=steel_hi + (255,), outline=ink, width=S)
    d.ellipse([cx - 17 * S, 15 * S, cx + 17 * S, 49 * S],
              fill=(126, 136, 154, 255) if gear == 1 else (150, 124, 66, 255), outline=ink, width=S)
    # rivets around the ring
    for a in range(12):
        ang = a * math.pi / 6.0
        rx = cx + math.cos(ang) * 24 * S
        ry = 32 * S + math.sin(ang) * 24 * S
        d.ellipse([rx - S, ry - S, rx + S, ry + S], fill=(60, 66, 80, 255) if gear == 1 else (120, 88, 30, 255))
    # -- the spoke handle wheel
    d.ellipse([cx - 10 * S, 22 * S, cx + 10 * S, 42 * S], outline=(70, 76, 92, 255) if gear == 1 else ink, width=2 * S)
    for a in range(6):
        ang = a * math.pi / 3.0 + 0.3
        d.line([cx, 32 * S, cx + math.cos(ang) * 9 * S, 32 * S + math.sin(ang) * 9 * S],
               fill=(70, 76, 92, 255) if gear == 1 else ink, width=S)
    d.ellipse([cx - 3 * S, 29 * S, cx + 3 * S, 35 * S], fill=gold_hi, outline=ink, width=S)
    # -- dial arc (top) + keyhole (bottom)
    d.arc([cx - 13 * S, 19 * S, cx + 13 * S, 45 * S], 205, 335,
          fill=(255, 246, 200, 230) if gear >= 2 else (208, 216, 230, 255), width=2 * S)
    d.ellipse([cx - 2 * S, 43 * S, cx + 2 * S, 47 * S], fill=(40, 34, 28, 255))
    d.polygon([(cx - 1 * S, 45 * S), (cx + 1 * S, 45 * S), (cx + 2 * S, 49 * S), (cx - 2 * S, 49 * S)],
              fill=(40, 34, 28, 255))
    # -- the coin slot wedge on top + g2/g3 gem
    d.polygon([(cx - 6 * S, 5 * S), (cx + 6 * S, 5 * S), (cx + 4 * S, 1 * S), (cx - 4 * S, 1 * S)],
              fill=gold_lo, outline=ink)
    if gear >= 3:
        d.ellipse([cx - 4 * S, 12 * S, cx + 4 * S, 20 * S], fill=(255, 244, 180, 255), outline=ink, width=S)
        d.ellipse([cx - 2 * S, 14 * S, cx, 16 * S], fill=(255, 255, 255, 255))
    im = im.resize((W // S, H // S), Image.LANCZOS)
    return outlined(im, 2)


# ---------------------------------------------------------------- chips
def rebuild_chips():
    """every folk's face chip: the g1 head's content TRIMMED and ZOOMED to
    COVER the disc (pyra/boomo's law - the icon is the head, big and bold),
    circle-masked with the ink ring + a soft bottom shade for depth."""
    import os
    for f in sorted(os.listdir(f"{ADIR}/folk")):
        if not f.endswith("_face.png"):
            continue
        fid = f[: -len("_face.png")]
        head = Image.open(f"{ADIR}/folk/{fid}_head_g1.png").convert("RGBA")
        bb = head.getbbox()
        if bb:
            head = head.crop(bb)
        D = 72
        Z = 4
        # COVER: the SMALLER content dimension fills the disc
        k = max(D / head.width, D / head.height) * 1.04
        w, h = max(D + 2, int(round(head.width * k))), max(D + 2, int(round(head.height * k)))
        big = head.resize((w * Z // 4, h * Z // 4), Image.LANCZOS)
        # center on the content, then center-crop to D
        ox = (big.width - D) // 2
        oy = (big.height - D) // 2
        chip = big.crop((ox, oy, ox + D, oy + D)).resize((D, D), Image.LANCZOS)
        # the soft bottom-inner shade (the chip sits in a socket)
        shade = Image.new("L", (D, D), 0)
        ImageDraw.Draw(shade).ellipse([-D // 3, D // 2, D + D // 3, D + D // 2], fill=70)
        dark = Image.new("RGBA", (D, D), (20, 12, 8, 255))
        dark.putalpha(shade)
        chip.alpha_composite(dark)
        # circle mask
        mask = Image.new("L", (D * Z, D * Z), 0)
        ImageDraw.Draw(mask).ellipse([8, 8, D * Z - 8, D * Z - 8], fill=255)
        mask = mask.resize((D, D), Image.LANCZOS)
        out = Image.new("RGBA", (D, D), (0, 0, 0, 0))
        out.paste(chip, (0, 0), mask)
        ring = Image.new("RGBA", (D, D), (0, 0, 0, 0))
        ImageDraw.Draw(ring).ellipse([1, 1, D - 2, D - 2], outline=INK, width=max(2, D // 26))
        out.alpha_composite(ring)
        save(out, f"folk/{fid}_face.png")


if __name__ == "__main__":
    for g in (1, 2, 3):
        save(draw_drum(g), f"folk/marshal_head_g{g}.png")
        save(draw_vault(g), f"folk/kaching_head_g{g}.png")
    rebuild_chips()
