#!/usr/bin/env python3
"""v041-1 THE GOGACURSOR FORGE (owner redesign).

  "+" at the center with a dot/ball in the center of the +, then a circle
  closing the + all edges; everything internally golden with brown outlines;
  the outlines-outlines are black and the internal in-lines go bright gold
  to normal golden ("it's called shading i guess"). Plus the click/hold
  effect frame.

THE STROKE-PASS LAW: every element (ring, arms, ball) is drawn as a STROKE,
and the passes run in outline order - all blacks, all browns, all golds, all
bright in-lines - so no element's outline can chop another's body.
Hotspot = exact center. press frame: ring tightens, ball swells, brightens.
"""
from PIL import Image, ImageDraw
import math, os

OUT = os.path.join(os.path.dirname(__file__), "..", "projects", "gogabox", "assets", "ui")
S = 4                      # supersample
BASE = 52                  # logical px (the OS cursor footprint)
PX = BASE * S              # working canvas
C = PX / 2.0

GOLD_BODY = (222, 168, 58)     # normal golden
GOLD_BRIGHT = (255, 216, 110)  # bright gold (the in-line shade)
BROWN = (107, 68, 19)          # the brown outlines
BLACK = (26, 14, 4)            # the outlines-outlines


def forge(path, press):
    img = Image.new("RGBA", (PX, PX), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    k = 1.18 if press else 1.0
    body = tuple(min(255, int(c * k)) for c in GOLD_BODY)
    bright = tuple(min(255, int(c * min(k, 1.08))) for c in GOLD_BRIGHT)
    rr = (PX * 0.44) * (0.93 if press else 1.0)     # ring centerline radius
    ring_w = 5.0 * S                                # ring stroke width
    arm_w = 4.2 * S                                 # arm stroke width
    ball_r = (5.4 * (1.25 if press else 1.0)) * S
    ri = rr - ring_w / 2.0                          # ring bore radius
    arm_len = ri + ring_w * 0.18                    # arms kiss the ring's body

    def circ(radius, width, color):
        d.ellipse([C - radius, C - radius, C + radius, C + radius],
                  outline=color, width=int(width))

    # ---- PASS 1: the blacks (the outlines-outlines) ----
    circ(rr, ring_w + 2.4, BLACK)
    for ang in (0, 90, 180, 270):
        a = math.radians(ang)
        p1 = (C + math.cos(a) * ball_r * 0.55, C + math.sin(a) * ball_r * 0.55)
        p2 = (C + math.cos(a) * arm_len, C + math.sin(a) * arm_len)
        d.line([p1, p2], fill=BLACK, width=int(arm_w + 2.4))
    d.ellipse([C - ball_r - 1.2, C - ball_r - 1.2, C + ball_r + 1.2, C + ball_r + 1.2],
              outline=BLACK, width=int(2.4))

    # ---- PASS 2: the browns ----
    circ(rr, ring_w + 1.0, BROWN)
    for ang in (0, 90, 180, 270):
        a = math.radians(ang)
        p1 = (C + math.cos(a) * ball_r * 0.55, C + math.sin(a) * ball_r * 0.55)
        p2 = (C + math.cos(a) * arm_len, C + math.sin(a) * arm_len)
        d.line([p1, p2], fill=BROWN, width=int(arm_w + 1.0))
    d.ellipse([C - ball_r - 0.5, C - ball_r - 0.5, C + ball_r + 0.5, C + ball_r + 0.5],
              outline=BROWN, width=int(1.0))

    # ---- PASS 3: the golds (the body) ----
    circ(rr, ring_w - 1.0, body)
    for ang in (0, 90, 180, 270):
        a = math.radians(ang)
        p1 = (C + math.cos(a) * ball_r * 0.6, C + math.sin(a) * ball_r * 0.6)
        p2 = (C + math.cos(a) * (arm_len - 0.6), C + math.sin(a) * (arm_len - 0.6))
        d.line([p1, p2], fill=body, width=int(arm_w - 0.8))

    # ---- PASS 4: the bright in-lines (the shading) ----
    circ(ri - 1.4 * S, 1.3 * S, bright)     # bright line hugging the ring bore
    for ang in (0, 90, 180, 270):
        a = math.radians(ang)
        p1 = (C + math.cos(a) * (ball_r + 1.2 * S), C + math.sin(a) * (ball_r + 1.2 * S))
        p2 = (C + math.cos(a) * (arm_len - 1.8 * S), C + math.sin(a) * (arm_len - 1.8 * S))
        d.line([p1, p2], fill=bright, width=int(1.3 * S))

    # ---- PASS 5: the ball ----
    d.ellipse([C - ball_r, C - ball_r, C + ball_r, C + ball_r], fill=body)
    d.ellipse([C - ball_r * 0.62, C - ball_r * 0.62, C + ball_r * 0.62, C + ball_r * 0.62],
              fill=bright)

    img = img.resize((BASE, BASE), Image.LANCZOS)
    img.save(path)
    print("forged", path, img.size)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    forge(os.path.join(OUT, "goga_cursor.png"), press=False)
    forge(os.path.join(OUT, "goga_cursor_press.png"), press=True)
