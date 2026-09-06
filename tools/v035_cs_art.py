#!/usr/bin/env python3
"""v0.3.5 patch art - THE WRAITH TRUTH + THE WARDEN + THE PEEL CLEAVER.

Regenerates:
  enemies/wraith.png      - the tattered ghost WITHOUT the pale ring baked
                            behind it (the owner: "that was a circle in the
                            enemy asset itself... fix that too")
  enemies/warden.png      - THE WARDEN, the gold half-damage aura totem
  weapons/gun_cleaver.png - the melee cleaver (the 48x22 gun family)
  weapons/icon_cleaver.png- the 56x56 icon

The engine family style (v034p1's law): silhouette -> vertical gradient ->
shadow band -> dark outline -> rim light, 4x supersampled then boxed down.
"""
from PIL import Image, ImageDraw, ImageFilter
import math, os

ROOT = os.path.join(os.path.dirname(__file__), "..",
                    "projects", "gogabox", "assets", "games", "cosmic_spud")
S = 4  # supersample


def canvas(w, h):
    return Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))


def shade_sil(img, base, dark, light, outline=(24, 20, 30)):
    """multiply-shade toward the bottom (details survive) + rim light that
    hugs the body + the dark outline"""
    w, h = img.size
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        mul = 1.0 - 0.34 * t          # the bottom sinks toward the dark
        for x in range(w):
            p = px[x, y]
            if p[3] > 0:
                px[x, y] = (int(p[0] * mul), int(p[1] * mul), int(p[2] * mul), p[3])
    mask = img.split()[3]
    # the dark outline (dilate alpha, paint behind)
    a = mask.filter(ImageFilter.MaxFilter(5))
    edge = Image.new("RGBA", img.size, outline + (255,))
    outline_layer = Image.composite(edge, Image.new("RGBA", img.size, (0, 0, 0, 0)), a)
    body = Image.new("RGBA", img.size, (0, 0, 0, 0))
    body.paste(img, (0, 0), img)
    out = Image.alpha_composite(outline_layer, body)
    # the rim light: an arc CLIPPED to the body mask (it hugs, never floats)
    rl = Image.new("RGBA", img.size, (0, 0, 0, 0))
    rd = ImageDraw.Draw(rl)
    rd.arc([S * 3, S * 3, img.size[0] - S * 3, img.size[1] - S * 3],
           150, 340, fill=(255, 255, 255, 110), width=S + 1)
    body_a = mask.filter(ImageFilter.MaxFilter(3))
    rl.putalpha(Image.composite(rl.split()[3], Image.new("L", img.size, 0), body_a))
    out = Image.alpha_composite(out, rl)
    return out


def save(img, path, final_size):
    img = img.resize(final_size, Image.LANCZOS)
    full = os.path.join(ROOT, path)
    img.save(full)
    print("saved", path, img.size)


# ---------------------------------------------------------------- WRAITH
# the tattered ghost: NO ring behind it this time - the aura is the game's
# own draw, the asset carries only the creature.
img = canvas(56, 56)
d = ImageDraw.Draw(img)
# the tail wisps first (behind the body)
d.polygon([(20 * S, 40 * S), (14 * S, 52 * S), (24 * S, 46 * S)], fill=(150, 96, 220, 235))
d.polygon([(34 * S, 40 * S), (40 * S, 52 * S), (30 * S, 46 * S)], fill=(150, 96, 220, 235))
# the body: a rounded ghost sheet
d.ellipse([10 * S, 6 * S, 46 * S, 42 * S], fill=(168, 108, 240, 235))
d.polygon([(10 * S, 30 * S), (46 * S, 30 * S), (42 * S, 48 * S), (34 * S, 42 * S),
           (28 * S, 50 * S), (20 * S, 42 * S), (14 * S, 48 * S)],
          fill=(168, 108, 240, 235))
# the inner light face
d.ellipse([16 * S, 12 * S, 40 * S, 34 * S], fill=(196, 140, 255, 235))
# the eyes (void ovals with white glints)
for ex in (22, 34):
    d.ellipse([(ex - 3) * S, 18 * S, (ex + 3) * S, 26 * S], fill=(255, 255, 255, 255))
    d.ellipse([(ex - 1) * S, 21 * S, (ex + 2) * S, 25 * S], fill=(60, 20, 90, 255))
# the little mouth
d.ellipse([25 * S, 30 * S, 31 * S, 34 * S], fill=(60, 20, 90, 255))
img = shade_sil(img, (168, 108, 240), (120, 70, 190), (214, 170, 255))
save(img, "enemies/wraith.png", (96, 96))

# ---------------------------------------------------------------- WARDEN
# the gold totem turtle: a stone dome shell with a rune, a small head
img = canvas(56, 56)
d = ImageDraw.Draw(img)
# feet
for fx in (16, 36):
    d.ellipse([(fx - 5) * S, 44 * S, (fx + 5) * S, 52 * S], fill=(150, 110, 40, 255))
# the shell dome
d.ellipse([8 * S, 10 * S, 48 * S, 46 * S], fill=(232, 186, 74, 255))
# the shell bands (the totem grooves)
for yy in (20, 30):
    d.line([(12 * S, yy * S), (44 * S, yy * S)], fill=(190, 140, 44, 255), width=2 * S)
# the rune (the half-shield mark: a shield split down the middle)
d.polygon([(28 * S, 16 * S), (36 * S, 20 * S), (36 * S, 28 * S), (28 * S, 32 * S)],
          fill=(255, 232, 150, 255))
d.polygon([(28 * S, 16 * S), (20 * S, 20 * S), (20 * S, 28 * S), (28 * S, 32 * S)],
          fill=(120, 84, 24, 255))
# the head (small, peeking top-right)
d.ellipse([38 * S, 6 * S, 50 * S, 18 * S], fill=(240, 200, 96, 255))
d.ellipse([44 * S, 9 * S, 47 * S, 12 * S], fill=(40, 28, 10, 255))
img = shade_sil(img, (232, 186, 74), (168, 122, 38), (255, 232, 150))
save(img, "enemies/warden.png", (96, 96))

# ---------------------------------------------------------------- CLEAVER
# the 48x22 gun family: handle + the broad peel-cleaver blade
img = canvas(48, 22)
d = ImageDraw.Draw(img)
# the handle (grip, at the left like every gun)
d.rounded_rectangle([2 * S, 9 * S, 16 * S, 13 * S], radius=2 * S,
                    fill=(90, 62, 40, 255))
d.ellipse([13 * S, 8 * S, 17 * S, 14 * S], fill=(120, 86, 56, 255))
# the blade (a wide cleaver with a blunt back and a hole)
d.polygon([(16 * S, 5 * S), (44 * S, 4 * S), (46 * S, 14 * S), (20 * S, 16 * S),
           (16 * S, 13 * S)], fill=(206, 214, 224, 255))
# the sharpened edge (the bright bottom line)
d.line([(18 * S, 15 * S), (45 * S, 13 * S)], fill=(240, 246, 252, 255), width=S + 1)
# the maker's hole
d.ellipse([19 * S, 7 * S, 23 * S, 11 * S], fill=(90, 98, 110, 255))
# the peel etch (a tiny potato stamp on the blade)
d.ellipse([30 * S, 7 * S, 38 * S, 12 * S], outline=(150, 158, 170, 255), width=S)
save(img, "weapons/gun_cleaver.png", (48, 22))

# the 56x56 icon: the cleaver diagonal on the family badge
img = canvas(56, 56)
d = ImageDraw.Draw(img)
d.rounded_rectangle([4 * S, 4 * S, 52 * S, 52 * S], radius=8 * S,
                    fill=(28, 26, 32, 255), outline=(70, 64, 80, 255), width=2 * S)
# the mini cleaver, rotated -45: draw straight then rotate the layer
blade = canvas(40, 18)
bd = ImageDraw.Draw(blade)
bd.rounded_rectangle([1 * S, 7 * S, 11 * S, 11 * S], radius=S, fill=(120, 86, 56, 255))
bd.polygon([(11 * S, 3 * S), (34 * S, 2 * S), (36 * S, 12 * S), (14 * S, 13 * S)],
           fill=(206, 214, 224, 255))
bd.line([(13 * S, 12 * S), (35 * S, 11 * S)], fill=(240, 246, 252, 255), width=S + 1)
bd.ellipse([14 * S, 5 * S, 18 * S, 9 * S], fill=(90, 98, 110, 255))
blade = blade.rotate(-38, expand=True, resample=Image.BICUBIC)
img.paste(blade, (6 * S, 8 * S), blade)
save(img, "weapons/icon_cleaver.png", (56, 56))

print("done")
