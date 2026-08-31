#!/usr/bin/env python3
"""v0.2.1 thumbnails - BOX FIX: every locked/soon game wears its FINAL
thumbnail (hen, spud, maze, matcher, keys, poptd - the generic ? files are
dead), and the SNAKE thumbnail gets its war-era dramatic scene in versions
so the owner can pick. 960x640, no baked text (THUMBNAILS.md rule).
Re-runnable: same code -> same bytes."""

import math
import os

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(PROJ, "assets", "thumbs")

from PIL import Image, ImageDraw, ImageFilter  # noqa: E402

W, H = 960, 640


def _canvas(bg):
    img = Image.new("RGB", (W, H), bg)
    return img, ImageDraw.Draw(img)


def _save(img, name):
    img.save(os.path.join(OUT, name + ".png"))
    print("assets/thumbs/%s.png" % name)


def _snake_body(d, pts, w0, c_head, c_tail, outline=(20, 14, 8)):
    """A smooth tapered ribbon snake from center points (the game's own
    language: one part, gradient, dark outline, rounded closed tail)."""
    def norm(p, q):
        dx, dy = q[0] - p[0], q[1] - p[1]
        L = max(0.001, math.hypot(dx, dy))
        return -dy / L, dx / L
    left, right = [], []
    n = len(pts)
    for i, (x, y) in enumerate(pts):
        a = pts[max(0, i - 1)]
        b = pts[min(n - 1, i + 1)]
        nx, ny = norm(a, b)
        t = i / max(1, n - 1)
        w = w0 * (1.0 - 0.55 * t)
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    poly = left + right[::-1]
    d.line(poly + [poly[0]], fill=outline, width=7)
    # gradient fill: segments tail->head, tail is lighter milk
    for i in range(n - 1):
        t = i / max(1, n - 1)
        col = tuple(int(c_tail[k] + (c_head[k] - c_tail[k]) * (1 - t))
                    for k in range(3))
        seg = [left[i], left[i + 1], right[i + 1], right[i]]
        d.polygon(seg, fill=col)
    # head disc + eyes
    hx, hy = pts[0]
    d.ellipse([hx - w0 * 1.1, hy - w0 * 1.1, hx + w0 * 1.1, hy + w0 * 1.1],
              fill=outline)
    d.ellipse([hx - w0, hy - w0, hx + w0, hy + w0], fill=c_head)
    return (hx, hy, w0)


def _eyes(d, head, dirdeg, scale=1.0, ink=(30, 22, 12)):
    hx, hy, w = head
    a = math.radians(dirdeg)
    for s in (-1, 1):
        ex = hx + math.cos(a) * w * 0.38 + math.cos(a + math.pi / 2) * w * 0.5 * s
        ey = hy + math.sin(a) * w * 0.38 + math.sin(a + math.pi / 2) * w * 0.5 * s
        r = w * 0.34 * scale
        d.ellipse([ex - r, ey - r, ex + r, ey + r], fill=(253, 250, 242))
        r2 = r * 0.5
        d.ellipse([ex - r2 + math.cos(a) * r * 0.3,
                   ey - r2 + math.sin(a) * r * 0.3,
                   ex + r2 + math.cos(a) * r * 0.3,
                   ey + r2 + math.sin(a) * r * 0.3], fill=ink)


def _apple(d, at, r=26):
    x, y = at
    d.ellipse([x - r, y - r, x + r, y + r], fill=(150, 40, 30))
    d.ellipse([x - r * 0.94, y - r * 0.9, x + r * 0.94, y + r * 0.9],
              fill=(232, 87, 74))
    d.ellipse([x - r * 0.5, y - r * 0.55, x - r * 0.1, y - r * 0.15],
              fill=(255, 220, 200))
    d.line([x, y - r, x + 4, y - r - 10], fill=(122, 74, 30), width=5)
    d.ellipse([x + 2, y - r - 16, x + 22, y - r - 4], fill=(88, 196, 112))


def _coin(d, at, r=17):
    x, y = at
    d.ellipse([x - r, y - r, x + r, y + r], fill=(140, 96, 20))
    d.ellipse([x - r * 0.86, y - r * 0.86, x + r * 0.86, y + r * 0.86],
              fill=(255, 201, 60))
    d.text((x - 6, y - 11), "G", fill=(200, 140, 30))


# ------------------------------------------------------------- teaser finals

def hen():
    img, d = _canvas((24, 30, 48))
    # moonlit sky bands
    for i in range(5):
        y = 40 + i * 30
        d.line([0, y, W, y], fill=(30, 38, 60), width=8)
    d.ellipse([790, 40, 900, 150], fill=(238, 244, 255))
    # three rows of hens
    for row in range(3):
        for col in range(6):
            x = 90 + col * 150 + (30 if row % 2 else 0)
            y = 110 + row * 120
            d.ellipse([x - 42, y - 30, x + 42, y + 34], fill=(250, 246, 238))
            d.ellipse([x - 42, y - 6, x + 42, y + 34], fill=(232, 222, 205))
            d.ellipse([x + 26, y - 44, x + 52, y - 20], fill=(250, 246, 238))
            d.ellipse([x + 34, y - 52, x + 46, y - 40], fill=(226, 60, 50))
            d.polygon([(x + 50, y - 32), (x + 68, y - 26), (x + 50, y - 22)],
                      fill=(255, 170, 40))
            d.ellipse([x + 34, y - 36, x + 44, y - 26], fill=(30, 26, 22))
            d.ellipse([x - 20, y + 2, x + 4, y + 18], fill=(255, 200, 90))
    # the ship + bullets
    d.polygon([(430, 590), (530, 590), (505, 520), (455, 520)],
              fill=(120, 200, 235))
    d.ellipse([440, 560, 520, 610], fill=(90, 160, 200))
    for bx in (470, 490):
        d.rectangle([bx - 3, 400, bx + 3, 500], fill=(255, 220, 90))
    _save(img, "hen")


def spud():
    img, d = _canvas((16, 12, 34))
    for i in range(70):
        x = (i * 137) % W
        y = (i * 331) % H
        r = 1 + (i % 3)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(220, 224, 255))
    # the cosmic spud: big potato with craters + a hero band
    cx, cy = 480, 320
    d.ellipse([cx - 150, cy - 190, cx + 150, cy + 190], fill=(150, 108, 62))
    d.ellipse([cx - 138, cy - 178, cx + 138, cy + 178], fill=(186, 138, 84))
    for ox, oy, r in ((-60, -60, 26), (50, 40, 34), (-20, 100, 20),
                      (80, -90, 16)):
        d.ellipse([cx + ox - r, cy + oy - r, cx + ox + r, cy + oy + r],
                  fill=(150, 108, 62))
    # hero goggles + jet flame
    d.rectangle([cx - 120, cy - 60, cx + 120, cy - 10], fill=(70, 80, 110))
    for gx in (cx - 70, cx + 10):
        d.ellipse([gx, cy - 58, gx + 60, cy - 12], fill=(120, 200, 235))
        d.ellipse([gx + 12, cy - 48, gx + 48, cy - 22], fill=(30, 40, 70))
    d.polygon([(cx - 60, cy + 190), (cx + 60, cy + 190), (cx, cy + 260)],
              fill=(255, 160, 60))
    d.polygon([(cx - 34, cy + 190), (cx + 34, cy + 190), (cx, cy + 232)],
              fill=(255, 220, 120))
    # a chased alien
    d.ellipse([140, 120, 230, 190], fill=(140, 90, 200))
    d.line([150, 120, 165, 90], fill=(140, 90, 200), width=8)
    d.line([210, 120, 225, 90], fill=(140, 90, 200), width=8)
    d.ellipse([160, 140, 182, 162], fill=(255, 255, 255))
    d.ellipse([192, 140, 214, 162], fill=(255, 255, 255))
    _save(img, "spud")


def maze():
    img, d = _canvas((26, 34, 26))
    cell = 64
    # hedge maze walls
    walls = [
        (2, 0, 2, 7), (4, 1, 4, 5), (6, 2, 6, 8), (8, 0, 8, 4),
        (10, 3, 10, 8), (3, 3, 5, 3), (7, 6, 9, 6), (5, 8, 8, 8),
        (1, 6, 3, 6), (9, 1, 11, 1), (12, 0, 12, 6), (0, 9, 6, 9),
    ]
    for x0, y0, x1, y1 in walls:
        for c in range(x0, x1 + 1):
            d.rectangle([c * cell + 6, y0 * cell + 6,
                         c * cell + cell - 6, y0 * cell + cell - 6],
                        fill=(60, 110, 58))
        if x1 > x0:
            for c in range(x0, x1 + 1):
                d.rectangle([c * cell + 6, y0 * cell + 6,
                             c * cell + cell - 6, y0 * cell + cell - 6],
                            fill=(60, 110, 58))
        for r in range(y0, y1 + 1):
            d.rectangle([x0 * cell + 6, r * cell + 6,
                         x0 * cell + cell - 6, r * cell + cell - 6],
                        fill=(60, 110, 58))
    # torch-lit explorer
    px, py = 3 * cell + 32, 4 * cell + 32
    for rr in range(120, 20, -18):
        d.ellipse([px - rr, py - rr, px + rr, py + rr],
                  fill=(70 + (120 - rr), 60 + (100 - rr), 30))
    d.ellipse([px - 20, py - 20, px + 20, py + 20], fill=(255, 220, 120))
    d.ellipse([px - 13, py - 13, px + 13, py + 13], fill=(255, 250, 210))
    # the exit glow
    ex, ey = 12 * cell + 32, 8 * cell + 32
    d.ellipse([ex - 30, ey - 30, ex + 30, ey + 30], fill=(120, 220, 140))
    d.ellipse([ex - 18, ey - 18, ex + 18, ey + 18], fill=(190, 255, 200))
    _save(img, "maze")


def matcher():
    img, d = _canvas((30, 26, 44))
    cols = [(232, 87, 74), (255, 176, 32), (88, 196, 112), (90, 160, 220),
            (170, 110, 220)]
    x0, y0, cs, gap = 130, 52, 88, 8
    rnd = 12345
    for r in range(6):
        for c in range(8):
            rnd = (rnd * 1103515245 + 12345) // 65536 % 32768
            col = cols[rnd % len(cols)]
            x, y = x0 + c * (cs + gap), y0 + r * (cs + gap)
            d.rounded_rectangle([x, y, x + cs, y + cs], radius=18,
                                fill=tuple(int(k * 0.6) for k in col))
            d.rounded_rectangle([x + 5, y + 5, x + cs - 5, y + cs - 5],
                                radius=14, fill=col)
            d.ellipse([x + 14, y + 12, x + 34, y + 30], fill=(255, 255, 255))
    # the swap pair: two gems ringed
    for (gx, gy) in [(x0 + 2 * (cs + gap), y0 + 2 * (cs + gap)),
                     (x0 + 3 * (cs + gap), y0 + 2 * (cs + gap))]:
        d.rounded_rectangle([gx - 6, gy - 6, gx + cs + 6, gy + cs + 6],
                            radius=22, outline=(255, 244, 200), width=6)
    _save(img, "matcher")


def keys():
    img, d = _canvas((22, 18, 36))
    # stage glow lines
    for i in range(6):
        y = 80 + i * 90
        d.line([0, y, W, y], fill=(34, 30, 52), width=10)
    # four key lanes with hit bars
    lane_w = 150
    for i in range(4):
        x = 130 + i * (lane_w + 40)
        d.rounded_rectangle([x, 90, x + lane_w, 560], radius=20,
                            fill=(38, 34, 56))
        d.rounded_rectangle([x + 10, 470, x + lane_w - 10, 550], radius=16,
                            fill=(70, 64, 100))
        col = [(232, 87, 74), (255, 176, 32), (88, 196, 112),
               (90, 160, 220)][i]
        d.rounded_rectangle([x + 10, 470, x + lane_w - 10, 550], radius=16,
                            fill=col)
    # falling notes
    notes = [(150, 180, 0), (340, 300, 1), (640, 150, 2), (830, 380, 3),
             (340, 60, 1), (640, 420, 2)]
    for x, y, k in notes:
        col = [(232, 87, 74), (255, 176, 32), (88, 196, 112),
               (90, 160, 220)][k]
        d.rounded_rectangle([x, y, x + lane_w - 20, y + 46], radius=14,
                            fill=col)
        d.ellipse([x + 14, y + 8, x + 34, y + 26], fill=(255, 255, 255))
    # a hit spark on the green lane
    d.ellipse([610, 430, 750, 560], outline=(255, 244, 200), width=8)
    _save(img, "keys")


def poptd():
    img, d = _canvas((34, 46, 34))
    # winding dirt path
    pts = [(-20, 120), (200, 140), (320, 300), (520, 340), (660, 500),
           (980, 520)]
    for i in range(len(pts) - 1):
        d.line([pts[i], pts[i + 1]], fill=(150, 120, 80), width=90)
    for i in range(len(pts) - 1):
        d.line([pts[i], pts[i + 1]], fill=(176, 144, 98), width=70)
    # turrets
    for tx, ty in [(250, 240), (560, 200), (600, 430)]:
        d.ellipse([tx - 44, ty - 44, tx + 44, ty + 44], fill=(90, 96, 90))
        d.ellipse([tx - 34, ty - 34, tx + 34, ty + 34], fill=(130, 140, 128))
        d.rectangle([tx - 7, ty - 70, tx + 7, ty - 20], fill=(60, 64, 60))
    # the bloon wave + a pop
    for i, col in enumerate([(232, 72, 72), (255, 176, 32), (90, 160, 220),
                             (232, 72, 72), (88, 196, 112)]):
        bx, by = 700 + (i % 3) * 70, 140 + (i // 3) * 90
        d.line([bx, by + 34, bx, by + 60], fill=(60, 50, 40), width=4)
        d.ellipse([bx - 32, by - 40, bx + 32, by + 40], fill=col)
        d.ellipse([bx - 20, by - 30, bx - 4, by - 14], fill=(255, 255, 255))
    px, py = 500, 420
    for a in range(8):
        ang = math.tau * a / 8
        d.line([px, py, px + math.cos(ang) * 46, py + math.sin(ang) * 46],
               fill=(255, 230, 150), width=7)
    d.ellipse([px - 26, py - 26, px + 26, py + 26], fill=(255, 230, 150))
    _save(img, "poptd")


# ------------------------------------------------------------- snake versions

def _field_bg():
    """The classic cream place (the game's real palette)."""
    img, d = _canvas((246, 231, 205))
    for i in range(7):
        x = (i * 197) % W
        y = (i * 271) % H
        d.ellipse([x - 40, y - 40, x + 40, y + 40], fill=(236, 217, 180))
    # the tan wall frame
    d.rounded_rectangle([14, 14, W - 14, H - 14], radius=46,
                        outline=(217, 195, 154), width=9)
    return img, d


def snake_v1():
    """VERSION A - the siege: three enemies at three sides, the user snake
    darting in from the left, one apple in the middle (classic place)."""
    img, d = _field_bg()

    def body(pts, w0, head_c, tail_c, dirdeg, eyes=True):
        h = _snake_body(d, pts, w0, head_c, tail_c)
        if eyes:
            _eyes(d, h, dirdeg)
        return h

    def curve(p0, p1, p2, n=16):
        pts = []
        for i in range(n + 1):
            t = i / n
            x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
            y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
            pts.append((x, y))
        return pts

    # green from the top, heading down
    body(curve((520, 60), (500, 190), (430, 300)), 30, (63, 174, 92),
         (216, 240, 220), 115)
    # ember from the right, curling
    body(curve((910, 380), (740, 420), (620, 350)), 28, (232, 99, 42),
         (255, 233, 201), 190)
    # violet from the bottom
    body(curve((300, 600), (360, 480), (450, 420)), 28, (138, 86, 200),
         (232, 220, 248), 285)
    # the user: blue, darting right at the apple
    body(curve((70, 330), (200, 300), (330, 330)), 32, (63, 127, 212),
         (250, 243, 227), 8)
    _apple(d, (400, 330), 30)
    _coin(d, (700, 200))
    _save(img, "snake_v1")


def snake_v2():
    """VERSION B - the chase: one long user snake racing the green rival to
    the apple, the pack right behind (dramatic diagonal)."""
    img, d = _field_bg()

    def curve(p0, p1, p2, n=16):
        pts = []
        for i in range(n + 1):
            t = i / n
            x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
            y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
            pts.append((x, y))
        return pts

    # the user snake: LONG, from bottom-left sweeping to the apple
    pts = []
    for i in range(22):
        t = i / 21
        x = 60 + t * 620
        y = 520 - 300 * t + 60 * math.sin(t * 5.2)
        pts.append((x, y))
    h = _snake_body(d, pts, 34, (63, 127, 212), (250, 243, 227))
    _eyes(d, h, -22)
    # the green rival: a neck behind the apple
    h2 = _snake_body(d, curve((900, 90), (760, 180), (640, 220)), 30,
                     (63, 174, 92), (216, 240, 220))
    _eyes(d, h2, 165)
    # violet + ember in the far back
    _snake_body(d, curve((920, 560), (760, 560), (660, 500)), 26,
                (138, 86, 200), (232, 220, 248))
    _snake_body(d, curve((500, 90), (420, 170), (330, 190)), 24,
                (232, 99, 42), (255, 233, 201))
    _apple(d, (560, 240), 30)
    _coin(d, (170, 190))
    _save(img, "snake_v2")


def snake_v3():
    """VERSION C - the moment before: the user head an inch from the apple,
    the green rival's open charge mirrored across the field."""
    img, d = _field_bg()

    def curve(p0, p1, p2, n=16):
        pts = []
        for i in range(n + 1):
            t = i / n
            x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
            y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
            pts.append((x, y))
        return pts

    # user: BIG in the foreground, lunging right
    pts = [(140 + i * 58, 400 + 46 * math.sin(i * 0.9)) for i in range(9)]
    h = _snake_body(d, pts, 44, (63, 127, 212), (250, 243, 227))
    _eyes(d, h, 0, 1.25)
    # tongue!
    hx, hy, w = h
    d.line([hx + w, hy, hx + w * 2.3, hy], fill=(232, 64, 47), width=7)
    _apple(d, (hx + w * 3.1, hy), 36)
    # green: charging from the top-right corner
    h2 = _snake_body(d, curve((940, 60), (760, 120), (620, 150)), 34,
                     (63, 174, 92), (216, 240, 220))
    _eyes(d, h2, 187, 1.1)
    # the pack far behind
    _snake_body(d, curve((900, 600), (740, 580), (620, 560)), 26,
                (138, 86, 200), (232, 220, 248))
    _snake_body(d, curve((60, 90), (170, 150), (280, 160)), 26,
                (232, 99, 42), (255, 233, 201))
    _coin(d, (860, 320))
    _save(img, "snake_v3")


if __name__ == "__main__":
    hen()
    spud()
    maze()
    matcher()
    keys()
    poptd()
    snake_v1()
    snake_v2()
    snake_v3()
