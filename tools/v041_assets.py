#!/usr/bin/env python3
"""v041 asset forge - the owner's icon + pointer + tag icons.

1. THE ICON LAW: regenerate icons/icon.ico from the canonical face
   (icons/main_512x512.png) with LANCZOS at every Windows size (16..256,
   24 included) - and main.gd now pins the RUNTIME window icon to the same
   face, so the taskbar / task manager / window icon can never be a
   different rendering of the mark again (the owner's report).
2. THE GOGACURSOR: golden pixelated arrow, brown outlines, normal + the
   click/hold frame (assets/ui/goga_cursor.png / goga_cursor_press.png).
3. THE TAG ICONS: os_android / os_pc / ctrl_touch / ctrl_mkb / ctrl_pad -
   white glyphs with the box-brown outline, the genre/sub tag language.
"""
from PIL import Image, ImageDraw
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "projects", "gogabox")
META = os.path.join(ROOT, "assets", "meta")
UI = os.path.join(ROOT, "assets", "ui")
ICONS = os.path.join(ROOT, "icons")

BROWN = (120, 70, 10, 255)
WHITE = (255, 255, 255, 255)
GOLD = (255, 201, 60, 255)
OUTLINE = (58, 34, 8, 255)


def regen_ico():
    src = Image.open(os.path.join(ICONS, "main_512x512.png")).convert("RGBA")
    sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64),
             (128, 128), (256, 256)]
    frames = []
    for s in sizes:
        f = src.resize(s, Image.LANCZOS)
        # a 1px sharpening pass keeps the small frames readable
        frames.append(f)
    base = frames[-1]
    base.save(os.path.join(ICONS, "icon.ico"),
              format="ICO", sizes=[f.size for f in frames],
              append_images=frames[:-1])
    print("icon.ico regenerated:", [f.size for f in frames])


def _pixel_arrow(scale=3):
    """The classic pointer on a pixel grid, golden + brown outline."""
    grid = [
        "X................",
        "XX...............",
        "XoX..............",
        "XooX.............",
        "XoooX............",
        "XooooX...........",
        "XoooooX..........",
        "XooooooX.........",
        "XoooooooX........",
        "XooooooooX.......",
        "XoooooxoooX......",
        "Xooox..xooX......",
        "Xoxx...xooX......",
        "Xx......xooX.....",
        ".........xooX....",
        ".........xooX....",
        "..........xooX...",
        "..........xooX...",
        "...........xooX..",
        "...........xxX...",
        "............X....",
        "..................",
    ]
    w = max(len(r) for r in grid) * scale
    h = len(grid) * scale
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for y, row in enumerate(grid):
        for x, c in enumerate(row):
            if c == " ":
                continue
            col = GOLD if c == "X" else (GOLD if c == "o" else OUTLINE)
            if c == "o":
                col = tuple(min(255, int(GOLD[i] * 0.88)) for i in range(3)) \
                                + (255,)
            d.rectangle([x * scale, y * scale, x * scale + scale - 1,
                         y * scale + scale - 1], fill=col)
    return im


def forge_cursor():
    arrow = _pixel_arrow(3)  # 54x66-ish
    arrow = arrow.resize((48, 48), Image.NEAREST)
    # trim to content + 2px border so the tip sits at (1,1)
    bbox = arrow.getbbox()
    arrow = arrow.crop((bbox[0], bbox[1],
                        min(48, bbox[0] + 42), min(48, bbox[1] + 42)))
    canvas = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    canvas.paste(arrow, (2, 2), arrow)
    canvas.save(os.path.join(UI, "goga_cursor.png"))
    # the click/hold frame: the same arrow + a press ring at the tip
    pr = canvas.copy()
    d = ImageDraw.Draw(pr)
    d.ellipse([0, 0, 12, 12], outline=OUTLINE, width=3)
    d.ellipse([2, 2, 10, 10], fill=GOLD)
    pr.save(os.path.join(UI, "goga_cursor_press.png"))
    print("goga_cursor.png + goga_cursor_press.png forged")


def _icon_base():
    im = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def _outline_shape(d, pts, width=6, fill=WHITE):
    d.polygon(pts, fill=fill, outline=BROWN, width=width)


def icon_os_android():
    im, d = _icon_base()
    # phone body (rounded rect) + screen line + home dot
    d.rounded_rectangle([30, 12, 66, 84], radius=8, fill=WHITE,
                        outline=BROWN, width=5)
    d.line([38, 26, 58, 26], fill=BROWN, width=5)
    d.ellipse([44, 70, 52, 78], fill=BROWN)
    im.save(os.path.join(META, "os_android.png"))
    print("os_android.png")


def icon_os_pc():
    im, d = _icon_base()
    d.rounded_rectangle([12, 20, 84, 62], radius=6, fill=WHITE,
                        outline=BROWN, width=5)
    d.rectangle([20, 28, 76, 54], fill=BROWN)
    d.line([48, 62, 48, 74], fill=BROWN, width=6)
    d.line([32, 78, 64, 78], fill=BROWN, width=7)
    im.save(os.path.join(META, "os_pc.png"))
    print("os_pc.png")


def icon_ctrl_touch():
    im, d = _icon_base()
    # the pointing hand: index finger + three knuckles + palm
    d.rounded_rectangle([40, 10, 54, 52], radius=7, fill=WHITE,
                        outline=BROWN, width=5)
    d.rounded_rectangle([56, 28, 68, 50], radius=6, fill=WHITE,
                        outline=BROWN, width=4)
    d.rounded_rectangle([70, 34, 82, 54], radius=6, fill=WHITE,
                        outline=BROWN, width=4)
    d.rounded_rectangle([30, 44, 80, 86], radius=12, fill=WHITE,
                        outline=BROWN, width=5)
    im.save(os.path.join(META, "ctrl_touch.png"))
    print("ctrl_touch.png")


def icon_ctrl_mkb():
    im, d = _icon_base()
    # keyboard + mouse
    d.rounded_rectangle([8, 44, 66, 80], radius=6, fill=WHITE,
                        outline=BROWN, width=5)
    for y in (54, 66):
        for x in range(16, 60, 12):
            d.rectangle([x, y, x + 7, y + 6], fill=BROWN)
    # the mouse beside it
    d.rounded_rectangle([70, 14, 90, 48], radius=10, fill=WHITE,
                        outline=BROWN, width=5)
    d.line([80, 16, 80, 30], fill=BROWN, width=4)
    d.line([62, 26, 66, 26], fill=BROWN, width=4)
    im.save(os.path.join(META, "ctrl_mkb.png"))
    print("ctrl_mkb.png")


def icon_ctrl_pad():
    im, d = _icon_base()
    # gamepad body + d-pad + two face buttons
    d.rounded_rectangle([10, 30, 86, 72], radius=18, fill=WHITE,
                        outline=BROWN, width=5)
    d.rectangle([24, 44, 44, 50], fill=BROWN)   # dpad bar
    d.rectangle([30, 38, 38, 56], fill=BROWN)   # dpad bar
    d.ellipse([62, 40, 72, 50], fill=BROWN)
    d.ellipse([70, 50, 80, 60], fill=BROWN)
    im.save(os.path.join(META, "ctrl_pad.png"))
    print("ctrl_pad.png")


if __name__ == "__main__":
    os.makedirs(META, exist_ok=True)
    regen_ico()
    forge_cursor()
    icon_os_android()
    icon_os_pc()
    icon_ctrl_touch()
    icon_ctrl_mkb()
    icon_ctrl_pad()
    print("v041 assets done")
