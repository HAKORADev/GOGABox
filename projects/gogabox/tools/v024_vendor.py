#!/usr/bin/env python3
"""v0.2.4 SPACE DASH - vendor the chosen CC0 sprites into the repo.

Owner law: NO code-generated ships. Everything below is Kenney CC0 art
(Space Shooter Redux via OpenGameArt mirror + Space Shooter Extension via
OpenGameArt + Particle Pack via kenney.nl). Recolors (yellow beam, white
thunder bolt) are deterministic HSV/level transforms of CC0 sources and
inherit CC0.

Also writes a pick map to stdout for the assets.manifest.json update.
"""
import colorsys
import shutil
from pathlib import Path

from PIL import Image

# repo paths: the packs land in .cache/assets/extracted/<source_id> via
# tools/sync-assets.py; this script then trims/recolors/copies the picks.
ROOT = Path(__file__).resolve().parents[3] / ".cache" / "assets" / "extracted"
REDUX = ROOT / "kenney-space-shooter-redux" / "PNG"
EXT = ROOT / "kenney-space-shooter-extension" / "PNG" / "Sprites"
PART = ROOT / "kenney-particle-pack" / "PNG (Transparent)"
OUT = Path(__file__).resolve().parents[1] / "assets" / "games" / "lanes"

COPY = {
    # ---- player ship skins (7 distinct hulls) ----
    "ship_orange.png": REDUX / "playerShip1_orange.png",
    "ship_blue.png": REDUX / "playerShip2_blue.png",
    "ship_green.png": REDUX / "playerShip3_green.png",
    "ship_veteran.png": EXT / "Ships/spaceShips_001.png",
    "ship_phantom.png": EXT / "Ships/spaceShips_004.png",
    "ship_titan.png": EXT / "Ships/spaceShips_007.png",
    "ship_horn.png": EXT / "Ships/spaceShips_009.png",
    # ---- enemy hulls (nose-down sprites) ----
    "enemy_grunt.png": REDUX / "Enemies/enemyBlack1.png",
    "enemy_grunt2.png": REDUX / "Enemies/enemyBlue2.png",
    "enemy_runner.png": REDUX / "Enemies/enemyGreen3.png",
    "enemy_shooter.png": REDUX / "Enemies/enemyBlue1.png",
    "enemy_splitter.png": REDUX / "Enemies/enemyRed4.png",
    "enemy_tank.png": REDUX / "Enemies/enemyBlack5.png",
    "enemy_shielded.png": REDUX / "Enemies/enemyGreen1.png",
    "enemy_shatter.png": REDUX / "Enemies/enemyRed3.png",
    "enemy_ufo_red.png": REDUX / "ufoRed.png",
    "enemy_ufo_green.png": REDUX / "ufoGreen.png",
    "enemy_ufo_yellow.png": REDUX / "ufoYellow.png",
    # ---- projectiles / items ----
    "laser_red_bolt.png": REDUX / "Lasers/laserRed04.png",
    "enemy_bolt.png": REDUX / "Lasers/laserRed07.png",
    "bomb.png": EXT / "Missiles/spaceMissiles_021.png",
    "item_power.png": REDUX / "Power-ups/pill_blue.png",
    "item_shield.png": REDUX / "Effects/shield1.png",
    "item_laser.png": REDUX / "Power-ups/powerupRed.png",
    "item_thunder.png": REDUX / "Power-ups/bold_silver.png",
    "item_bomb.png": EXT / "Missiles/spaceMissiles_025.png",
    # ---- animated shield bubble (3 frames) ----
    "shield_1.png": REDUX / "Effects/shield1.png",
    "shield_2.png": REDUX / "Effects/shield2.png",
    "shield_3.png": REDUX / "Effects/shield3.png",
    # ---- glow / spark / smoke workhorses (tintable white) ----
    "fx_flare.png": PART / "flare_01.png",
    "fx_spark.png": PART / "spark_04.png",
    "fx_smoke.png": PART / "smoke_04.png",
    "fx_star.png": PART / "star_04.png",
    "speedline.png": REDUX / "Effects/speed.png",
}


def trim(im: Image.Image) -> Image.Image:
    bb = im.getchannel("A").getbbox()
    return im.crop(bb) if bb else im


def recolor_yellow(im: Image.Image) -> Image.Image:
    """Green bolt -> yellow: rotate hue of saturated pixels -50 deg."""
    im = im.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s > 0.15:  # only tinted pixels; whites stay white
                h = (h - 50.0 / 360.0) % 1.0
            r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255), a)
    return im


def recolor_white(im: Image.Image) -> Image.Image:
    """Blue bolt -> thunder white: desaturate + lift, keep alpha."""
    im = im.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            v = min(255, int(max(r, g, b) * 1.15 + 40))
            px[x, y] = (v, v, v, a)
    return im


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, src in COPY.items():
        if not src.exists():
            print(f"MISSING SOURCE: {src}")
            continue
        im = trim(Image.open(src).convert("RGBA"))
        if name == "laser_yellow.png":
            im = recolor_yellow(im)
        elif name == "laser_thunder.png":
            im = recolor_white(im)
        im.save(OUT / name)
        print(f"{name}  <-  {src.relative_to(ROOT)}  {im.size}")
    # yellow + thunder bolts are recolors of green/blue sources
    for name, src, fn in [
        ("laser_yellow.png", REDUX / "Lasers/laserGreen04.png", recolor_yellow),
        ("laser_thunder.png", REDUX / "Lasers/laserBlue04.png", recolor_white),
    ]:
        im = trim(fn(Image.open(src).convert("RGBA")))
        im.save(OUT / name)
        print(f"{name}  <-  {src.relative_to(ROOT)} (recolor)  {im.size}")
    # engine flame animation: every other frame of fire00..19 (10 frames)
    for i in range(0, 20, 2):
        src = REDUX / f"Effects/fire{i:02d}.png"
        im = trim(Image.open(src).convert("RGBA"))
        im.save(OUT / f"fire_{i:02d}.png")
    print(f"fire_XX.png x{len(range(0, 20, 2))}  <-  Effects/fire00-19 (odd frames)")
    print(f"\nvendored into {OUT}")


if __name__ == "__main__":
    main()
