#!/usr/bin/env python3
"""v0.2.3 art - two owner calls:

1. THE PHONE CARDS LOSE THE SNAKE: the vertical/horizontal position-select
   art carried a tiny blue wiggle "on the screen" - a leftover from when
   the card was born for the snake (owner: "i recommend you to update it
   and remove that snake-like line, keeping it the phone only makes it
   more universal-ish"). Same phone, same motion arcs, EMPTY screen.
2. THE SOON ? IS BACK: coming_soon tiles keep the workshop's purple
   question-mark thumbnail (owner: "i just forgot to include soon titles
   to keep their thumbnail the 'soon' purple question mark, return it!").
   Drawn once as assets/thumbs/soon.png in the exact scene_soon language
   (purple diagonals + the real ? glyph), 960x640 universal canvas.

Re-runnable: same code -> same bytes."""

import os
import sys

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(PROJ, "assets", "ui")
THUMBS = os.path.join(PROJ, "assets", "thumbs")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PIL import Image, ImageDraw  # noqa: E402
from thumb_composer import scene_soon  # noqa: E402  (the ? glyph workshop)

DARK = (24, 14, 7, 255)
CARD = (255, 243, 220, 255)


def _phone_card(size, landscape):
    """The v0.1.9 phone glyph, MINUS the snake wiggle: body, screen, home
    dot, motion arcs. The screen stays empty so the card is universal."""
    S = size
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    w, h = (S * 0.52, S * 0.86) if not landscape else (S * 0.86, S * 0.52)
    x0, y0 = (S - w) / 2, (S - h) / 2
    # motion arcs behind the phone
    for k, r in enumerate((0.62, 0.78)):
        box = [S / 2 - S * r, S / 2 - S * r, S / 2 + S * r, S / 2 + S * r]
        a0 = -35 if not landscape else 55
        a1 = 35 if not landscape else 125
        d.arc(box, a0, a1, fill=(122, 108, 180, 160), width=int(S * 0.035))
        d.arc(box, a0 + 180, a1 + 180, fill=(122, 108, 180, 160),
              width=int(S * 0.035))
    # body
    d.rounded_rectangle([x0, y0, x0 + w, y0 + h], radius=S * 0.09,
                        fill=DARK, outline=CARD, width=max(4, int(S * 0.035)))
    # screen (plain - no snake, no game marks)
    m = S * 0.055
    d.rounded_rectangle([x0 + m, y0 + m, x0 + w - m, y0 + h - m],
                        radius=S * 0.05, fill=(246, 231, 205, 255))
    # home dot
    dot = S * 0.02
    d.ellipse([S / 2 - dot, (y0 + h - m * 0.5) - dot,
               S / 2 + dot, (y0 + h - m * 0.5) + dot], fill=CARD)
    return img


def phone_icons():
    _phone_card(320, False).save(os.path.join(UI, "phone_vertical.png"))
    print("assets/ui/phone_vertical.png (snake line removed)")
    _phone_card(320, True).save(os.path.join(UI, "phone_horizontal.png"))
    print("assets/ui/phone_horizontal.png (snake line removed)")


def soon_thumb():
    img = scene_soon("WORKSHOP")
    img.save(os.path.join(THUMBS, "soon.png"))
    print("assets/thumbs/soon.png (the purple ? for every coming_soon tile)")


if __name__ == "__main__":
    phone_icons()
    soon_thumb()
