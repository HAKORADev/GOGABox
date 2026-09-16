#!/usr/bin/env python3
"""ROCK BREAKER thumbnail (v040-7) - 960x640, a photograph of the game:
one composed in-game frame from the film rig (the deep-heat flood - hot
rocks with their 1.20K / 1.40K damage faces, the golden star, the
mystery carrier, the two-wheeled cannon), cropped clean.
THE CHROMA-CUTOUT LAW: never re-draw, crop the render.
"""
from PIL import Image, ImageEnhance

FILMS = "/home/z/my-project/gogabox/films/v040-7"
OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/thumbs/rockbreaker.png"
W, H = 960, 640

bg = Image.open(f"{FILMS}/thumb_frame.png").convert("RGBA")
# the action cluster + the cannon: the window wraps the flood's lower
# band (the golden, the mystery, the K-rocks and the two-wheeled ride)
img = bg.crop((60, 1115, 1020, 1755)).resize((W, H), Image.LANCZOS)

img = img.convert("RGB")
img = ImageEnhance.Color(img).enhance(1.08)
img = ImageEnhance.Contrast(img).enhance(1.07)
img = ImageEnhance.Brightness(img).enhance(1.03)
img.save(OUT)
print("thumbnail written:", OUT)
