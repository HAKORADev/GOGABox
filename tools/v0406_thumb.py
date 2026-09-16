#!/usr/bin/env python3
"""HEAVY WAR thumbnail (v040-6) - 960x640, a photograph of the game:
one composed in-game frame from the film rig (full-loadout tank firing
from the new layered hull, the war machines inbound, the smooth sky),
cropped clean. THE CHROMA-CUTOUT LAW: never re-draw, crop the render.
"""
from PIL import Image, ImageEnhance

FILMS = "/home/z/my-project/gogabox/films/v040-6"
OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/thumbs/heavywar.png"
W, H = 960, 640

bg = Image.open(f"{FILMS}/thumb_frame.png").convert("RGBA")
img = bg.crop((400, 280, 1460, 986)).resize((W, H), Image.LANCZOS)

img = img.convert("RGB")
img = ImageEnhance.Color(img).enhance(1.07)
img = ImageEnhance.Contrast(img).enhance(1.06)
img = ImageEnhance.Brightness(img).enhance(1.02)
img.save(OUT)
print("thumbnail written:", OUT)
