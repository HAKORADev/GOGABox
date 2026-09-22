#!/usr/bin/env python3
"""v041-2 - the TOWER BALL logo (assets/games/towerball/logo.png).
Casual look: warm stacked wordmark + a tiny helix-and-ball mark.
No text laws apply inside the game (the intro art may carry words -
the no-baked-text law is the THUMBNAIL law only)."""
from PIL import Image, ImageDraw, ImageFont

W, H = 620, 420
img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(img)


def font(sz):
    for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
              "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"]:
        try:
            return ImageFont.truetype(p, sz)
        except Exception:
            pass
    return ImageFont.load_default()


# the helix mark: three ring arcs + Balldozer on top
cx, cy = W // 2, 96
for i, ry in enumerate([64, 42, 20]):
    box = [cx - 74, cy + ry - 22, cx + 74, cy + ry + 46]
    d.arc(box, start=15, end=165, fill=(48, 32, 20, 255), width=14)
# the ball
d.ellipse([cx - 26, cy - 118, cx + 26, cy - 66], fill=(226, 89, 63, 255))
d.ellipse([cx - 16, cy - 108, cx - 2, cy - 94], fill=(30, 20, 16, 255))
d.ellipse([cx + 2, cy - 108, cx + 16, cy - 94], fill=(30, 20, 16, 255))

# the wordmark: TOWER / BALL stacked, warm casual
f1 = font(96)
f2 = font(120)
t1 = "TOWER"
t2 = "BALL"
w1 = d.textlength(t1, font=f1)
w2 = d.textlength(t2, font=f2)
# soft outline + fill
for txt, f, y in [(t1, f1, 178), (t2, f2, 268)]:
    w = d.textlength(txt, font=f)
    x = (W - w) / 2
    for dx, dy in [(-6, 0), (6, 0), (0, -6), (0, 6), (-4, -4), (4, 4),
                   (-4, 4), (4, -4)]:
        d.text((x + dx, y + dy), txt, font=f, fill=(120, 60, 20, 255))
    d.text((x, y), txt, font=f, fill=(255, 244, 214, 255))
# the underline swoosh
d.rounded_rectangle([W / 2 - 130, 384, W / 2 + 130, 400], radius=8,
                    fill=(247, 178, 103, 255))

img.save("projects/gogabox/assets/games/towerball/logo.png")
print("logo written")
