#!/usr/bin/env python3
"""v0.2.1a patch art - the missing place_classic.png optionals icon.

The v0.2.1 round brought the milk CLASSIC place back as the default, but
only day/night had icons from v0.2.0 - the optionals PLACE box tried to
load place_classic.png and rendered a blank (probe: "Resource file not
found: res://assets/ui/place_classic.png"). Same 96x96 language as the
day/night pair: rounded card, banded background, one landmark.

Re-runnable: same code -> same bytes."""

import math
import os

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(PROJ, "assets", "ui")

from PIL import Image, ImageDraw  # noqa: E402


def place_classic():
    """THE CLASSIC (the milk place): the cream field with its tan wall
    frame and the soft deco blobs - home as the snake knows it."""
    S = 96
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # the cream field + the milk sky band
    d.rounded_rectangle([6, 6, 90, 90], radius=14, fill=(246, 231, 205, 255))
    d.rounded_rectangle([6, 6, 90, 40], radius=14, fill=(250, 240, 221, 255))
    d.rectangle([6, 30, 90, 46], fill=(250, 240, 221, 255))
    # soft deco blobs (the field's own dressing)
    for x, y, r in ((24, 58, 8), (66, 52, 10), (44, 78, 7)):
        d.ellipse([x - r, y - r, x + r, y + r], fill=(236, 217, 180, 255))
    # the tan wall frame (the classic's rounded deadly wall)
    d.rounded_rectangle([10, 10, 86, 86], radius=11,
                        outline=(217, 195, 154, 255), width=4)
    # a tiny apple in the middle - home
    d.ellipse([41, 38, 59, 56], fill=(232, 87, 74, 255))
    d.ellipse([44, 41, 50, 47], fill=(255, 220, 200, 230))
    d.line([50, 38, 52, 32], fill=(122, 74, 30, 255), width=3)
    d.ellipse([52, 26, 60, 33], fill=(88, 196, 112, 255))
    # a snake-friendly highlight arc (the wrap-friendly no-walls wink)
    for i in range(10):
        a = math.pi * (0.15 + 0.07 * i)
        x = 48 + math.cos(a) * 30
        y = 48 - math.sin(a) * 30
        d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=(250, 240, 221, 160))
    img.save(os.path.join(UI, "place_classic.png"))
    print("assets/ui/place_classic.png")


if __name__ == "__main__":
    place_classic()
