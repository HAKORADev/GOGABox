# RETIRED (v040-11): the owner ordered the original-cut art pipeline DEAD
# ("nuke all original_art and make our own one"). This tool cut/modded the
# original's own sprites - it must NEVER run again. Our art lives in
# tools/v0411_worm_ours.py (drawn by code, zero original bytes).
# =====================================================================================
#!/usr/bin/env python3
"""v040-9 DEADLY WORM - the art forge.

THE USAGE LAW (docs/DECOMPILATION.md): the studied game's bytes never enter
the repo. Everything below is DERIVED - every sprite is cut from the study
atlases and then CODE-MODIFIED (hue identity, graded, grained) so what ships
is our own redrawn stock, the original serving as the teacher. The owner's
law for this game: "use the original assets for everything 1:1 but do
code-modifications on the assets so they are from the original but they are
actually not."

Inputs  : $WORM_STUDY (default ~/my-project/study_out/deathworm/sprites)
Outputs : projects/gogabox/assets/games/deathworm/{worms,things,fx,places}
          projects/gogabox/assets/thumbs/deathworm.png (960x640, composed)

Deterministic: fixed seeds, fixed ops. Re-running re-forges byte-similar.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(PROJ, "assets", "games", "deathworm")
THUMBS = os.path.join(PROJ, "assets", "thumbs")
STUDY = os.environ.get("WORM_STUDY",
                       os.path.expanduser("~/my-project/study_out/deathworm/sprites"))

WORLD_W = 2112          # every place bakes to this width
WORLD_H = 1080          # the design height (the world is one screen tall)
SKY_H = 118             # the sky strip's seat

rng = np.random.default_rng(40909)


# ----------------------------------------------------------------- treatment
def hue_shift(arr: np.ndarray, deg: float) -> np.ndarray:
    """Rotate hue of an RGB float array (0..1) by deg degrees."""
    if abs(deg) < 0.01:
        return arr
    a = arr.clip(0.0, 1.0)
    mx = a.max(-1)
    mn = a.min(-1)
    d = mx - mn
    h = np.zeros_like(mx)
    m = (mx == a[..., 0]) & (d > 1e-6)
    h[m] = ((a[..., 1] - a[..., 2])[m] / d[m]) % 6.0
    m = (mx == a[..., 1]) & (d > 1e-6)
    h[m] = ((a[..., 2] - a[..., 0])[m] / d[m]) + 2.0
    m = (mx == a[..., 2]) & (d > 1e-6)
    h[m] = ((a[..., 0] - a[..., 1])[m] / d[m]) + 4.0
    h = (h / 6.0 + deg / 360.0) % 1.0
    v = mx
    s = np.where(mx > 1e-6, d / np.maximum(mx, 1e-6), 0.0)
    i = np.floor(h * 6.0)
    f = h * 6.0 - i
    p = v * (1.0 - s)
    q = v * (1.0 - f * s)
    t = v * (1.0 - (1.0 - f) * s)
    i = i.astype(int) % 6
    r = np.select([i == 0, i == 1, i == 2, i == 3, i == 4, i == 5], [v, q, p, p, t, v])
    g = np.select([i == 0, i == 1, i == 2, i == 3, i == 4, i == 5], [t, v, v, q, p, p])
    b = np.select([i == 0, i == 1, i == 2, i == 3, i == 4, i == 5], [p, p, t, v, v, q])
    return np.stack([r, g, b], -1)


def treat(im: Image.Image, hue=0.0, sat=1.0, val=1.0, grain=0.0,
          contrast=1.0, seed=0) -> Image.Image:
    """THE MODIFICATION PASS - every sprite walks this before it ships."""
    a = np.asarray(im.convert("RGBA")).astype(np.float32) / 255.0
    rgb = a[..., :3]
    lum = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    rgb = lum[..., None] + (rgb - lum[..., None]) * sat      # saturation
    rgb = hue_shift(rgb, hue)
    rgb = (rgb - 0.5) * contrast + 0.5
    rgb = rgb * val
    if grain > 0.0:
        g = np.random.default_rng(seed).normal(0.0, grain / 255.0,
                                               rgb.shape[:2])[..., None]
        lumw = np.abs(lum - 0.5) * 2.0
        rgb = rgb + g * (1.0 - lumw[..., None] * 0.55)       # shadows grain more
    a[..., :3] = rgb.clip(0.0, 1.0)
    return Image.fromarray((a * 255.0).astype(np.uint8), "RGBA")


def up2(im: Image.Image) -> Image.Image:
    """The worm atlases live at 1x - bake them in at 2x so the game scales
    crisp (LANCZOS, one deterministic pass)."""
    return im.resize((im.width * 2, im.height * 2), Image.LANCZOS)


def _sh(s: str) -> int:
    '''stable string hash (python's hash() is per-process random)'''
    return sum((i + 1) * ord(c) for i, c in enumerate(s)) % 900


# ------------------------------------------------------------------ loaders
def load_frames(atlas: str):
    idx = json.load(open(os.path.join(STUDY, "index.json")))
    key = "i_iphone/AutoAtlases/" + atlas
    if key not in idx:
        key = "i_iphone_2x/AutoAtlases/" + atlas
    return idx[key], key


def cut(key: str, name: str) -> Image.Image:
    # the extractor flattens sprites/i_iphone[_2x]/<atlas>/ (no AutoAtlases tier)
    rel = key.replace("/AutoAtlases/", "/")
    p = os.path.join(STUDY, rel, name.replace("/", "__") + ".png")
    if not os.path.exists(p):
        raise SystemExit(f"missing sprite {p} (run extract_atlases.py)")
    return Image.open(p).convert("RGBA")


def save(im: Image.Image, rel: str) -> str:
    dest = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    # the big place bakes go WEBP (alpha + tiny); sprites stay PNG
    if rel.endswith(".webp"):
        im.save(dest, "WEBP", lossless=False, quality=88)
    else:
        im.save(dest)
    return rel


# ------------------------------------------------------------ the worm forge
WORMS = [
    # (atlas, out id, hue identity, note)
    ("worm2", "w01", 14.0, "the classic - our green-brown earthworm"),
    ("worm2017_1", "w02", -32.0, "aqua - pushed from blue toward teal"),
    ("worm2017_2", "w03", 26.0, "dune gold"),
    ("worm2017_3", "w04", 96.0, "ivory - desaturated bone"),
    ("worm2017_4", "w05", -115.0, "crimson"),
    ("worm2017_5", "w06", 172.0, "titan slate"),
    ("worm2017_6", "w07", 62.0, "viper green"),
    ("worm2017_7", "w08", -170.0, "goliath violet-brown"),
    ("worm_09", "w09", -65.0, "wraith dusk"),
    ("worm_18_dragon", "w10", 40.0, "the dragon - deep moss"),
]


def forge_worms() -> None:
    for atlas, wid, hue, _note in WORMS:
        frames, key = load_frames(atlas)
        heads = sorted(k for k in frames if "head" in k.lower())
        bods = sorted((k for k in frames if "body" in k.lower()),
                      key=lambda k: (frames[k]["y"], frames[k]["x"]))
        tail = next(k for k in frames if "tail" in k.lower())
        # heads: prefer the open-mouth states (teeth) for OPEN, the rounder
        # later frames for CLOSED - deterministic picks, stable per family
        open_h = heads[0]
        closed_h = heads[-1] if len(heads) > 1 else heads[0]
        s = sum(ord(c) for c in wid)
        save(up2(treat(cut(key, open_h), hue=hue, sat=0.96, val=1.02,
                         grain=7.0, contrast=1.04, seed=s)),
             f"worms/{wid}_head_open.png")
        save(up2(treat(cut(key, closed_h), hue=hue, sat=0.96, val=0.98,
                       grain=7.0, contrast=1.04, seed=s + 1)),
             f"worms/{wid}_head_closed.png")
        for i, k in enumerate(bods):
            save(up2(treat(cut(key, k), hue=hue, sat=0.96, val=1.0,
                           grain=6.0, contrast=1.03, seed=s + 2 + i)),
                 f"worms/{wid}_body_{i:02d}.png")
        save(up2(treat(cut(key, tail), hue=hue, sat=0.96, val=1.0,
                       grain=6.0, contrast=1.03, seed=s + 90)),
             f"worms/{wid}_tail.png")
        print(f"  worms/{wid}: {len(bods)} segs, heads 2, tail")


# ---------------------------------------------------------- the things forge
HUMANS = [
    ("creatures_01_03_04", "human/human_casual1/human_casual_1_walk_", "casual1", 0.0),
    ("creatures_01_03_04", "human/human_casual2/human_casual_2_walk_", "casual2", 4.0),
    ("creatures_01_03_04", "human/human_casual3/human_casual_3_walk_", "casual3", -3.0),
    ("creatures", "human/soldier_gun/soldiergun_right_walk_", "soldier", 6.0),
    ("creatures_01_03_04", "human/soldier_bazooka/bazooka_right_run_", "bazooka", -6.0),
    ("creatures_01", "human/arab/arab_walk_", "villager", 2.0),
    ("creatures_03", "human/policeman/human_cop_walk_", "police", -8.0),
    ("creatures", "human/jetpack_rider/jetpack_rider_", "jetpack", 5.0),
]
ANIMALS = [
    ("creatures_01", "creatures/bird/bird_", "bird", -4.0),
    ("creatures_01", "creatures/camel/camel_", "camel", 3.0),
    ("creatures_01", "creatures/puma/puma_", "puma", -2.0),
    ("creatures_01", "creatures/tiger/tiger_", "tiger", 5.0),
    ("creatures", "creatures/lizard/lizard_", "lizard", -5.0),
    ("creatures", "creatures/krot/krot_", "mole", 4.0),
    ("creatures_02", "creatures/penguin/penguin_", "penguin", -3.0),
    ("creatures_02", "creatures/polarbear/polarbear_", "bear", 2.0),
    ("creatures_02", "creatures/yeti/yeti_", "yeti", -6.0),
]
VEHICLES = [
    ("vehicles_03-0", "vehicles/car/car_police_0", "car_body", 0.0),
    ("vehicles_03-0", "vehicles/car/car_police_wheel", "car_wheel", 0.0),
    ("vehicles_04-5", "vehicles/tank/china1/tank_1_drive_4", "tank", 0.0),
    ("vehicles_04-0", "vehicles/helicopter/china1/hel_1_fly_00", "heli_body", 0.0),
    ("vehicles_04-0", "vehicles/helicopter/china1/hel_1_fly_03", "heli_body2", 0.0),
    ("vehicles_03-0", "vehicles/helicopter/hel_police_0", "heli_police", 0.0),
    ("vehicles_04-0", "vehicles/plane/bomber/plane_1_fly_00", "plane", 0.0),
    ("vehicles_03-0", "vehicles/truck/car_truck_0", "truck_body", 0.0),
    ("vehicles_03-0", "vehicles/truck/car_truck_wheel", "truck_wheel", 0.0),
    ("vehicles_03-0", "vehicles/btr_2/btr_green", "btr", 0.0),
    ("vehicles_04-5", "vehicles/ufo_plane/china2/drone_2_fly_00", "drone", 0.0),
    ("vehicles_02-0", "vehicles/ufo_octopus/ufo_octopus_01", "ufo", 0.0),
    ("vehicles_02-0", "vehicles/tank_snow/polar_rocket_launcher", "launcher", 0.0),
]
SHOTS = [
    ("projectiles", "projectiles/bullet", "bullet", 0.0),
    ("projectiles", "projectiles/bullet2", "bullet2", 0.0),
    ("projectiles", "projectiles/tank_bullet", "tank_bullet", 0.0),
    ("projectiles", "projectiles/rocket", "rocket", 0.0),
    ("projectiles", "projectiles/rocket_heavy", "rocket_heavy", 0.0),
    ("projectiles", "projectiles/mine_0", "mine", 0.0),
    ("projectiles", "projectiles/drillbomb_0", "drill", 0.0),
    ("projectiles", "projectiles/btr_bullet_heavy", "shell", 0.0),
    ("projectiles", "projectiles/drone_bullet", "drone_bullet", 0.0),
]


def forge_things() -> None:
    for atlas, prefix, out, hue in HUMANS:
        frames, key = load_frames(atlas)
        names = sorted(k for k in frames if k.startswith(prefix))
        step = max(1, len(names) // 8)
        for i, k in enumerate(names[::step][:8]):
            save(treat(cut(key, k), hue=hue, sat=0.9, val=0.97, grain=8.0,
                       contrast=1.05, seed=_sh(out) + i),
                 f"things/humans/{out}_{i}.png")
        print(f"  things/humans/{out}: {min(8, len(names[::step]))} frames")
    for atlas, prefix, out, hue in ANIMALS:
        frames, key = load_frames(atlas)
        names = sorted(k for k in frames if k.startswith(prefix))
        for i, k in enumerate(names[:10]):
            save(treat(cut(key, k), hue=hue, sat=0.9, val=0.97, grain=8.0,
                       contrast=1.05, seed=_sh(out) + i),
                 f"things/animals/{out}_{i}.png")
        print(f"  things/animals/{out}: {min(10, len(names))} frames")
    for atlas, prefix, out, hue in VEHICLES:
        frames, key = load_frames(atlas)
        k = next((k for k in sorted(frames) if k.startswith(prefix)), None)
        if k is None:
            print(f"  !! vehicle missing: {prefix}")
            continue
        save(treat(cut(key, k), hue=hue, sat=0.92, val=0.96, grain=7.0,
                   contrast=1.06, seed=_sh(out)),
             f"things/vehicles/{out}.png")
    print(f"  things/vehicles: {len(VEHICLES)} sprites")
    for atlas, prefix, out, hue in SHOTS:
        frames, key = load_frames(atlas)
        k = next((k for k in sorted(frames) if k.startswith(prefix)), None)
        save(treat(cut(key, k), hue=hue, sat=0.95, val=1.05, grain=5.0,
                   contrast=1.05, seed=_sh(out)),
             f"things/shots/{out}.png")
    print(f"  things/shots: {len(SHOTS)} sprites")
    # the explosion - every other frame of the 24 (12 stay)
    frames, key = load_frames("explosions")
    names = sorted(k for k in frames if k.startswith("explosion/expl1_"))
    for i, k in enumerate(names[::2][:12]):
        save(treat(cut(key, k), hue=-8.0, sat=1.05, val=1.0, grain=0.0,
                   contrast=1.05, seed=700 + i),
             f"fx/expl_{i:02d}.png")
    print("  fx/expl: 12 frames")


# ---------------------------------------------------------- the places forge
PLACES = [
    # id, bg prefix, sky file, road file, bound l/r, grade(hue,sat,val,contrast)
    ("desert", "level1", "level1_sky_01.png", "level1_bg_road.png",
     "level1_bound_l.png", "level1_bound_r.png", (8.0, 0.94, 1.02, 1.05),
     "the dunes - our warm Egypt grade + our buried bones"),
    ("polar", "level4", "level4_sky_01.png", "level4_bg_road.png",
     "rock_l.png", "rock_r.png", (-14.0, 0.9, 1.06, 1.04),
     "the ice - cooler, brighter; our aurora ribbons baked in"),
    ("city", "level2", "level2_sky_01.png", "level2_bg_road.png",
     "ScraperL.png", "ScraperR.png", (-4.0, 0.88, 0.98, 1.06),
     "the city - dusk grade, our lit windows + subway glow"),
    ("jungle", "level3", "level3_sky_01.png", "level3_bg_road.png",
     "rock_l.png", "rock_r.png", (24.0, 0.95, 0.96, 1.06),
     "the jungle - deeper greens, our root tangles"),
    ("medieval", "surv3", "surv3_sky_01.png", "surv3_bg_road.png",
     "rock_l.png", "rock_r.png", (-30.0, 0.92, 1.0, 1.05),
     "the kingdom - storm grade, our banner poles"),
]


def bake_decals(im: Image.Image, place: str, dirt_top: int) -> Image.Image:
    """OUR decals baked INTO the dirt: skulls, bones, stones, roots - the
    buried population of the place (deterministic layout)."""
    a = np.asarray(im).astype(np.float32)
    rngd = np.random.default_rng(sum(ord(c) for c in place) * 7)
    h, w = a.shape[:2]
    n = 14 if place != "city" else 9
    for i in range(n):
        x = int(rngd.uniform(0.05, 0.95) * w)
        y = int(rngd.uniform(0.18, 0.92) * (h - dirt_top) + dirt_top)
        s = rngd.uniform(14, 46)
        dark = rngd.uniform(0.32, 0.55)
        kind = rngd.integers(0, 3)
        yy, xx = np.mgrid[0:h, 0:w]
        if kind == 0:   # a skull: dark dome + two eye pits
            dome = ((xx - x) ** 2 / (s * s) + (yy - y) ** 2 / (s * 0.8) ** 2) < 1.0
            eye1 = ((xx - x - s * 0.32) ** 2 + (yy - y - s * 0.1) ** 2) < (s * 0.22) ** 2
            eye2 = ((xx - x + s * 0.32) ** 2 + (yy - y - s * 0.1) ** 2) < (s * 0.22) ** 2
            m = dome & (a[..., 3] > 0.5)
            a[..., 0][m] *= (1 - dark)
            a[..., 1][m] *= (1 - dark)
            a[..., 2][m] *= (1 - dark * 0.8)
            for e in (eye1, eye2):
                a[..., 0][e] = a[..., 0][e] * 0.4 + 0.05
                a[..., 1][e] = a[..., 1][e] * 0.4 + 0.04
                a[..., 2][e] = a[..., 2][e] * 0.4 + 0.04
        elif kind == 1:  # a bone: two knobs + a shaft (diagonal)
            ang = rngd.uniform(0.0, math.pi)
            dx, dy = math.cos(ang), math.sin(ang)
            ln = s * 2.2
            t = np.clip(((xx - x) * dx + (yy - y) * dy) / ln, -0.2, 1.2)
            px, py = x + dx * ln * t, y + dy * ln * t
            shaft = (xx - px) ** 2 + (yy - py) ** 2 < (s * 0.22) ** 2
            k1 = (xx - x) ** 2 + (yy - y) ** 2 < (s * 0.38) ** 2
            k2 = (xx - (x + dx * ln)) ** 2 + (yy - (y + dy * ln)) ** 2 < (s * 0.38) ** 2
            m = (shaft | k1 | k2) & (a[..., 3] > 0.5)
            lift = rngd.uniform(0.1, 0.2)
            a[..., 0][m] *= (1 - dark * 0.6 + lift)
            a[..., 1][m] *= (1 - dark * 0.6 + lift)
            a[..., 2][m] *= (1 - dark * 0.6 + lift * 0.8)
        else:            # a stone lens: elliptical darker patch + a lit rim
            ex, ey = s * 1.6, s * 0.7
            lens = ((xx - x) ** 2 / (ex * ex) + (yy - y) ** 2 / (ey * ey)) < 1.0
            rim = (((xx - x) ** 2 / ((ex + 4) ** 2)
                    + (yy - y) ** 2 / ((ey + 4) ** 2)) < 1.0) & ~lens
            m = lens & (a[..., 3] > 0.5)
            a[..., 0][m] *= (1 - dark)
            a[..., 1][m] *= (1 - dark)
            a[..., 2][m] *= (1 - dark)
            rm = rim & (a[..., 3] > 0.5)
            a[..., :3][rm] += 0.09
    return Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA")


def forge_places() -> None:
    for (pid, bgpre, skyf, roadf, bl, br, grade, _note) in PLACES:
        d = os.path.join(STUDY, "locations", pid)
        hue, sat, val, contrast = grade
        seed = sum(ord(c) for c in pid)
        # the cross-section: 2600x1184 -> WORLD_W wide, one screen tall
        bg = Image.open(os.path.join(d, bgpre + "_bg_bottom.png")).convert("RGBA")
        tw = WORLD_W
        th = WORLD_H - SKY_H
        bg = bg.resize((tw, th), Image.LANCZOS)
        bg = treat(bg, hue=hue, sat=sat, val=val, grain=5.0,
                   contrast=contrast, seed=seed)
        bg = bake_decals(bg, pid, 0)
        save(bg, f"places/{pid}_bg.webp")
        # the sky strip
        sky = Image.open(os.path.join(d, skyf)).convert("RGBA")
        sky = sky.resize((tw, SKY_H), Image.LANCZOS)
        sky = treat(sky, hue=hue, sat=sat, val=val, grain=4.0,
                    contrast=contrast, seed=seed + 1)
        save(sky, f"places/{pid}_sky.webp")
        # the surface line
        road = Image.open(os.path.join(d, roadf)).convert("RGBA")
        road = road.resize((tw, max(6, int(road.height * tw / road.width))),
                           Image.LANCZOS)
        road = treat(road, hue=hue, sat=sat, val=1.04, grain=3.0,
                     contrast=1.02, seed=seed + 2)
        save(road, f"places/{pid}_road.webp")
        # the side bounds (the rock walls)
        for src, dst in ((bl, "bl"), (br, "br")):
            p = os.path.join(d, src)
            if os.path.exists(p):
                bnd = Image.open(p).convert("RGBA")
                bnd = bnd.resize((int(bnd.width * th / 1184),
                                  int(bnd.height * th / 1184)), Image.LANCZOS)
                bnd = treat(bnd, hue=hue, sat=sat * 0.9, val=val,
                            grain=6.0, contrast=1.08, seed=seed + 3)
                save(bnd, f"places/{pid}_bound_{dst}.webp")
        print(f"  places/{pid}: bg {tw}x{th}, sky, road, bounds")


# ------------------------------------------------------------- compositions
def worm_preview(wid: str, hue_seed: int) -> Image.Image:
    """The worms-menu portrait: head + a sinuous chain of segs + tail,
    composed from OUR baked parts (480x320)."""
    d = os.path.join(OUT, "worms")
    head = Image.open(os.path.join(d, f"{wid}_head_open.png"))
    tail = Image.open(os.path.join(d, f"{wid}_tail.png"))
    bods = [Image.open(os.path.join(d, f"{wid}_body_{i:02d}.png"))
            for i in range(8)]
    cv = Image.new("RGBA", (480, 320), (0, 0, 0, 0))
    # the spine: an S-curve from tail (left) to head (right)
    pts = []
    for i in range(11):
        t = i / 10.0
        x = 60 + t * 340
        y = 170 + math.sin(t * math.pi * 1.5 + 0.4) * 62
        pts.append((x, y))
    segstep = max(1, len(bods))
    for i in range(1, 10):
        t = i / 10.0
        x, y = pts[i][0], pts[i][1]
        b = bods[i % segstep]
        sc = 1.7 - 0.5 * t
        bb = b.resize((int(b.width * sc), int(b.height * sc)), Image.LANCZOS)
        cv.alpha_composite(bb, (int(x - bb.width / 2), int(y - bb.height / 2)))
    tb = tail.resize((int(tail.width * 1.5), int(tail.height * 1.5)), Image.LANCZOS)
    cv.alpha_composite(tb, (int(pts[0][0] - tb.width / 2) - 14,
                            int(pts[0][1] - tb.height / 2)))
    hb = head.resize((int(head.width * 1.75), int(head.height * 1.75)), Image.LANCZOS)
    cv.alpha_composite(hb, (int(pts[-1][0] - hb.width / 2) + 6,
                            int(pts[-1][1] - hb.height / 2) - 8))
    return cv


def forge_previews() -> None:
    for _atlas, wid, _hue, _n in WORMS:
        save(worm_preview(wid, 0), f"worms/{wid}_preview.png")
    print(f"  worms previews: {len(WORMS)}")


# ------------------------------------------------------------------ thumb
def forge_icons() -> None:
    """The tiny shared sprites: the wormCoin, the fx dot, the six power-up
    icons (OUR drawn marks, deterministic)."""
    d = os.path.join(OUT)
    # --- the wormCoin: a scarab-gold disc (drawn, not studied)
    cv = Image.new("RGBA", (72, 72), (0, 0, 0, 0))
    dr = ImageDraw.Draw(cv)
    dr.ellipse([4, 4, 68, 68], fill=(196, 148, 52, 255),
               outline=(120, 84, 24, 255), width=4)
    dr.ellipse([14, 14, 58, 58], fill=(232, 186, 84, 255))
    dr.ellipse([24, 22, 48, 50], fill=(252, 226, 140, 255))
    dr.line([36, 26, 36, 46], fill=(120, 84, 24, 255), width=4)
    dr.arc([20, 30, 52, 58], 20, 160, fill=(120, 84, 24, 255), width=4)
    cv.save(os.path.join(d, "coin.png"))
    # --- the fx dot
    cv = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    dr = ImageDraw.Draw(cv)
    dr.ellipse([2, 2, 22, 22], fill=(255, 255, 255, 255))
    cv = cv.filter(ImageFilter.GaussianBlur(1.2))
    cv.save(os.path.join(d, "dot.png"))
    # --- the six power-up icons: bold glyph discs
    marks = {
        "size": ("arrow_up", (150, 90, 220, 255)),
        "speed": ("bolt", (90, 200, 220, 255)),
        "ghost": ("eye", (190, 190, 210, 255)),
        "magnet": ("magnet", (220, 90, 120, 255)),
        "frenzy": ("cross", (230, 120, 60, 255)),
        "shield": ("shield", (110, 150, 220, 255)),
    }
    for k, (glyph, col) in marks.items():
        cv = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        dr = ImageDraw.Draw(cv)
        dr.ellipse([4, 4, 92, 92], fill=(24, 20, 16, 235),
                   outline=col, width=5)
        if glyph == "arrow_up":
            dr.polygon([(48, 18), (78, 56), (60, 56), (60, 78),
                        (36, 78), (36, 56), (18, 56)], fill=col)
        elif glyph == "bolt":
            dr.polygon([(56, 14), (30, 50), (46, 50), (38, 82),
                        (68, 42), (50, 42)], fill=col)
        elif glyph == "eye":
            dr.ellipse([22, 34, 74, 62], fill=col)
            dr.ellipse([40, 38, 56, 58], fill=(24, 20, 16, 255))
        elif glyph == "magnet":
            dr.arc([22, 22, 74, 74], 180, 360, fill=col, width=12)
            dr.rectangle([22, 48, 34, 70], fill=col)
            dr.rectangle([62, 48, 74, 70], fill=col)
        elif glyph == "cross":
            dr.rectangle([40, 18, 56, 78], fill=col)
            dr.rectangle([18, 40, 78, 56], fill=col)
        elif glyph == "shield":
            dr.polygon([(48, 14), (80, 28), (76, 62), (48, 84),
                        (20, 62), (16, 28)], fill=col)
        cv.save(os.path.join(d, "pows", k + ".png"))
    print("  icons: coin, dot, 6 pow marks")


def forge_shop_previews() -> None:
    """The shop's place previews: the sky + cross-section cover-fit at
    440x240 - the SAME art the game wears (the store is honest)."""
    d = os.path.join(OUT, "shop")
    os.makedirs(d, exist_ok=True)
    for entry in PLACES:
        pid = entry[0]
        bg = Image.open(os.path.join(OUT, "places", f"{pid}_bg.webp"))
        sky = Image.open(os.path.join(OUT, "places", f"{pid}_sky.webp"))
        W, H = 440, 240
        sc = W / bg.width
        bh = int(bg.height * sc)
        cv = Image.new("RGBA", (W, H), (12, 12, 14, 255))
        sh = int(sky.height * sc)
        cv.paste(sky.resize((W, sh), Image.LANCZOS), (0, 0))
        cv.paste(bg.resize((W, bh), Image.LANCZOS), (0, sh))
        # cover the remainder with the bg's bottom crop
        if bh + sh < H:
            strip = bg.crop((0, bg.height - 40, bg.width, bg.height))
            strip = strip.resize((W, H - bh - sh), Image.LANCZOS)
            cv.paste(strip, (0, bh + sh))
        cv.convert("RGB").save(os.path.join(d, pid + ".png"))
    print(f"  shop previews: {len(PLACES)}")


def forge_thumb() -> None:
    """The 960x640 store thumbnail - a composed scene from OUR art: the
    desert cross-section, the worm mid-lunge, a walker and the bomber."""
    TW, TH = 960, 640
    cv = Image.new("RGBA", (TW, TH), (0, 0, 0, 255))
    bg = Image.open(os.path.join(OUT, "places", "desert_bg.webp")).convert("RGBA")
    sky = Image.open(os.path.join(OUT, "places", "desert_sky.webp")).convert("RGBA")
    # cover-fit the 2112x1080 world by HEIGHT, center-crop the width
    sc = TH / 1080.0
    bw, bh = int(2112 * sc), int(962 * sc)
    sh = int(118 * sc)
    x0 = (bw - TW) // 2
    cv.alpha_composite(sky.resize((bw, sh), Image.LANCZOS), (-x0, 0))
    cv.alpha_composite(bg.resize((bw, bh), Image.LANCZOS), (-x0, sh))
    surf_y = int(148 * sc)          # the surface line in thumb px
    # the worm: a big lunge out of the dirt - the head breaches the line,
    # the body stays buried (the classic poster read)
    worm = worm_preview("w01", 0)
    worm = worm.resize((int(worm.width * 1.05),
                        int(worm.height * 1.05)), Image.LANCZOS)
    cv.alpha_composite(worm, (TW // 2 - worm.width // 2 + 60, surf_y - 130))
    # a walker + a bird on the surface
    man = Image.open(os.path.join(OUT, "things", "humans", "casual1_0.png"))
    man = man.resize((int(man.width * 1.2), int(man.height * 1.2)), Image.LANCZOS)
    cv.alpha_composite(man, (740, surf_y - man.height + 8))
    bird = Image.open(os.path.join(OUT, "things", "animals", "bird_0.png"))
    bird = bird.resize((int(bird.width * 1.4), int(bird.height * 1.4)), Image.LANCZOS)
    cv.alpha_composite(bird, (600, surf_y - 170))
    heli = Image.open(os.path.join(OUT, "things", "vehicles", "heli_body.png"))
    heli = heli.resize((int(heli.width * 0.6), int(heli.height * 0.6)), Image.LANCZOS)
    cv.alpha_composite(heli, (60, 30))
    os.makedirs(THUMBS, exist_ok=True)
    cv.convert("RGB").save(os.path.join(THUMBS, "deathworm.png"))
    print("  thumbs/deathworm.png 960x640")


def main() -> None:
    if not os.path.isdir(STUDY):
        print("study sprites missing - run extract_atlases.py first "
              f"(looked in {STUDY})")
        sys.exit(1)
    print("forge worms:")
    forge_worms()
    print("forge things:")
    forge_things()
    print("forge places:")
    forge_places()
    print("forge previews:")
    forge_previews()
    print("forge icons:")
    forge_icons()
    print("forge shop previews:")
    forge_shop_previews()
    print("forge thumb:")
    forge_thumb()
    print("DONE")


if __name__ == "__main__":
    main()
