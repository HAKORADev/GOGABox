#!/usr/bin/env python3
"""v040-10 DEADLY WORM - the REAL-ASSET forge (the owner's mandate).

"collect the correct assets accurately and see the sprite sheets of each
thing and code-modify them like different details and colors and like
that and make it really our own."

The study sprites (tools/v0410_worm_study.py, from the official APK under
THE USAGE LAW) are cut ONE-TO-ONE: the real worm heads (DragonBones
skins), the real human run cycles (10-frame runs), the real rotor/fly
animation of helicopters and planes, the real animals, the real
explosions, the real place layers (road tile, sky tiles, mountain far,
bound walls, dirt). Every piece is then CODE-MODIFIED into ours: hue
identity per family, graded, grained - the counts match the original
(exactly as many heli frames as the original's heli fly cycle has, etc).

THE FACING LAW (baked here, enforced in-game): THINGS are cut to face
LEFT natively (the game flips when moving right). The WORM is cut to
face RIGHT natively (the chain rotates by its heading).

Inputs : $WORM_STUDY (~/my-project/study_out/deathworm/sprites)
         + study_out/deathworm/locations/<place>/
Outputs: projects/gogabox/assets/games/deathworm/{worms,things,fx,places}
         projects/gogabox/assets/games/rockbreaker/world/rockcoin.png
         projects/gogabox/assets/thumbs/deathworm.png
"""
import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(PROJ, "assets", "games", "deathworm")
THUMBS = os.path.join(PROJ, "assets", "thumbs")
RB = os.path.join(PROJ, "assets", "games", "rockbreaker")
STUDY = os.environ.get("WORM_STUDY",
                       os.path.expanduser(
                       "~/my-project/study_out/deathworm/sprites"))
LOCS = os.path.expanduser("~/my-project/study_out/deathworm/locations")

rng = np.random.default_rng(40107)


def log(m):
    print(m, flush=True)


def ensure(p):
    os.makedirs(p, exist_ok=True)
    return p


# ----------------------------------------------------------------- the mods
def hue_shift_img(im: Image.Image, deg: float, sat: float = 1.0,
                  bright: float = 1.0, grain: float = 0.0) -> Image.Image:
    """the code-mod: hue identity + grade + grain (always-on)."""
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    arr = np.asarray(im, np.float32) / 255.0
    rgb, a = arr[..., :3], arr[..., 3:]
    mx = rgb.max(-1)
    mn = rgb.min(-1)
    d = mx - mn
    h = np.zeros_like(mx)
    m = (mx == rgb[..., 0]) & (d > 1e-6)
    h[m] = ((rgb[..., 1] - rgb[..., 2])[m] / d[m]) % 6.0
    m = (mx == rgb[..., 1]) & (d > 1e-6)
    h[m] = ((rgb[..., 2] - rgb[..., 0])[m] / d[m]) + 2.0
    m = (mx == rgb[..., 2]) & (d > 1e-6)
    h[m] = ((rgb[..., 0] - rgb[..., 1])[m] / d[m]) + 4.0
    h = (h / 6.0 + deg / 360.0) % 1.0
    v = mx * bright
    s = np.where(mx > 1e-6, d / np.maximum(mx, 1e-6), 0.0) * sat
    i = np.floor(h * 6.0)
    f = h * 6.0 - i
    p = v * (1.0 - s)
    q = v * (1.0 - f * s)
    t = v * (1.0 - (1.0 - f) * s)
    i = i.astype(int) % 6
    out = np.zeros_like(rgb)
    for k, (aa, bb, cc) in enumerate([(v, t, p), (q, v, p), (p, v, t),
                                      (p, q, v), (t, p, v), (v, p, q)]):
        mk = i == k
        out[..., 0][mk] = aa[mk]
        out[..., 1][mk] = bb[mk]
        out[..., 2][mk] = cc[mk]
    if grain > 0.0:
        n = rng.normal(0.0, grain, out.shape[:2])[..., None]
        out = out + n * (a[..., 0:1] > 0.05)
    out = np.clip(out, 0.0, 1.0)
    return Image.fromarray(
        (np.dstack([out, a]) * 255.0).astype(np.uint8), "RGBA")


def trim(im: Image.Image, pad: int = 2) -> Image.Image:
    bbox = im.getbbox()
    if bbox is None:
        return im
    x0, y0, x1, y1 = bbox
    return im.crop((max(0, x0 - pad), max(0, y0 - pad),
                    min(im.width, x1 + pad), min(im.height, y1 + pad)))


def save(im: Image.Image, rel: str) -> str:
    p = os.path.join(OUT, rel)
    ensure(os.path.dirname(p))
    im.save(p)
    return rel


# ----------------------------------------------------------------- the worms
# skin -> (hue deg, the part pick table). The heads face UP-RIGHT in the
# DragonBones pages; the cut rotates to native RIGHT.
WORM_SKINS = {
    "w01": ("worm2019_main_view", 0.0),
    "w02": ("worm_19_view", 150.0),
    "w03": ("worm_dune_view", 18.0),
    "w04": ("worm2019_star_view_animation", 0.0),
    "w05": ("worm2019_3_view", -12.0),
    "w06": ("worm2019_4_view", 32.0),
    "w07": ("worm2019_5_view", 96.0),
    "w08": ("worm2019_robo_view", 0.0),
    "w09": ("worm_16_view", 162.0),
    "w10": ("worm_22_view", -28.0),
}


def skin_parts(skin: str) -> dict:
    """part name -> RGBA image, from the study cut. Most skins name their
    SubTextures '<skin>/<part>' (the path doubles the prefix); some name
    them '<other>/<part>' - try the double prefix, fall back to single."""
    out = {}
    pre2 = f"dbskin_{skin}_{skin}_"
    pre1 = f"dbskin_{skin}_"
    for f in os.listdir(STUDY):
        if not f.endswith(".png") or not f.startswith(pre1):
            continue
        part = f[len(pre2):-4] if f.startswith(pre2) else f[len(pre1):-4]
        out[part] = Image.open(os.path.join(STUDY, f)).convert("RGBA")
    return out


def orient_right(im: Image.Image) -> Image.Image:
    """the DB parts author facing RIGHT natively (verified by eye) -
    the cut keeps the authored orientation."""
    return im


def pick_big(parts: dict, prefix, skip: tuple = ()) -> Image.Image:
    cands = [p for p in parts if p.startswith(tuple(prefix))
             and not any(s in p for s in skip)]
    if not cands:
        return None
    cands.sort(key=lambda p: parts[p].width * parts[p].height, reverse=True)
    return parts[cands[0]]


# per-skin explicit part picks (verified by eye on the raw pages):
# (head, open variant, [bodies], accent-to-composite or None)
WORM_PARTS = {
    "w01": ("head", "TOOTH", ["body"], "tooth_2"),
    "w02": ("head_1", "head_2", ["body"], None),
    "w03": ("mouth_1", "mouth_7", ["body"], None),
    "w04": ("worm_1_for_animation_worm_1_6",
            "worm_1_for_animation_worm_1_5",
            ["worm_1_for_animation_worm_1_4"], None),
    "w05": ("head_6", "head_12", ["body_1", "body_7", "body_10"], None),
    "w06": ("head_3", "mouth_3", ["body"], None),
    "w07": ("mouth_1", "mouth_2", ["body_1", "body_5", "body_3"], None),
    "w08": ("head_12", "head_8", ["body_1", "body_9", "body_4"], "eye_R"),
    "w09": ("head_1", "head_3", ["body_9", "body_1", "body_3"], None),
    "w10": ("body", "BODYX", ["body"], "tooth_1"),
}


def forge_worm(wid: str, skin: str, hue: float) -> None:
    parts = skin_parts(skin)
    if not parts:
        log(f"! {wid}: no parts for {skin}")
        return
    head_n, open_n, body_ns, accent_n = WORM_PARTS[wid]
    if head_n not in parts:
        log(f"! {wid}: part {head_n} missing in {skin}")
        return
    head = parts[head_n]

    def comp(base: Image.Image, acc: Image.Image) -> Image.Image:
        """the accent rides the head's right (mouth) edge - the jaw's
        teeth / the eye, composed then trimmed"""
        out = base.copy()
        a = acc.resize((max(1, int(base.width * 0.52)),
                        max(1, int(base.height * 0.4))))
        out.alpha_composite(a, (int(base.width * 0.52),
                                int(base.height * 0.30)))
        return out

    if open_n == "TOOTH" and accent_n and accent_n in parts:
        open_m = comp(head, parts[accent_n])
        accent = None
    elif open_n == "BODYX":
        open_m = hue_shift_img(trim(head), hue + 10.0, 1.14, 1.07, 0.05)
        accent = parts[accent_n] if accent_n in parts else None
    else:
        open_m = parts.get(open_n, head)
        accent = parts.get(accent_n) if accent_n else None
    body = parts.get(body_ns[0], head)
    b2 = parts.get(body_ns[1]) if len(body_ns) > 1 else None
    b3 = parts.get(body_ns[2]) if len(body_ns) > 2 else None

    # ---- CUT + MOD (native RIGHT facing, no rotation) ----
    def norm(im, extra_hue=0.0, gr=0.05):
        if im is None:
            return None
        return hue_shift_img(trim(im), hue + extra_hue, 1.06, 1.02, gr)

    h_closed = norm(head)
    if accent is not None and open_n != "BODYX":
        h_closed = comp(norm(head), norm(accent))
    h_open = norm(open_m) if open_m is not None else h_closed
    if h_closed is None or h_open is None:
        log(f"! {wid}: unusable parts for {skin} - skipped")
        return
    save(h_closed, f"worms/{wid}_head.png")
    save(h_open, f"worms/{wid}_head_open.png")
    bodies = [norm(body), norm(b2, 14.0), norm(b3, -14.0)]
    bodies = [b for b in bodies if b is not None]
    for i, b in enumerate(bodies[:3]):
        save(b, f"worms/{wid}_body_{i}.png")
    # the tail: the last body, tapered 62% -> 30%
    tb = bodies[-1].copy()
    tw = max(8, int(tb.width * 0.62))
    th = max(8, int(tb.height * 0.58))
    tail = tb.resize((tw, th))
    save(tail, f"worms/{wid}_tail.png")
    # the preview: head + 3 bodies chained, on a transparent 460x240 card
    pv = Image.new("RGBA", (460, 240), (0, 0, 0, 0))
    x = 8
    hh = h_closed.height
    k = min(1.0, 200.0 / max(1, hh))
    hp = h_closed.resize((max(1, int(h_closed.width * k)),
                          max(1, int(h_closed.height * k))))
    pv.paste(hp, (x, 120 - hp.height // 2), hp)
    x += hp.width - 6
    for i in range(3):
        b = bodies[i % len(bodies)]
        bk = min(1.0, 150.0 / max(1, b.height))
        bp = b.resize((max(1, int(b.width * bk)), max(1, int(b.height * bk))))
        if x + bp.width > 452:
            break
        pv.paste(bp, (x, 120 - bp.height // 2), bp)
        x += bp.width - 10
    save(pv, f"worms/{wid}_preview.png")
    log(f"worm {wid} <- {skin}: head {h_closed.size}, "
        f"{len(bodies)} bodies")


# ----------------------------------------------------------------- the things
# family -> (study prefix, native facing fix, hue, frame sort)
def cut_family(prefix: str, dest: str, hue: float, native_left: bool,
               take: int = 99, grain: float = 0.04) -> int:
    files = [f for f in os.listdir(STUDY)
             if f.startswith(prefix) and f.endswith(".png")]
    # natural sort by the trailing number
    def key(f):
        base = f[:-4]
        num = "".join(ch for ch in base[len(prefix):] if ch.isdigit())
        return int(num) if num else 0
    files.sort(key=key)
    n = 0
    for f in files[:take]:
        im = Image.open(os.path.join(STUDY, f)).convert("RGBA")
        im = trim(im)
        if not native_left:
            im = im.transpose(Image.FLIP_LEFT_RIGHT)
        im = hue_shift_img(im, hue, 1.05, 1.0, grain)
        save(im, f"things/{dest}_{n:02d}.png")
        n += 1
    return n


def forge_things() -> None:
    # ---- humans (native LEFT runs - the atlas runs face left) ----
    humans = [
        ("human_human_casual1_human_casual_1_run", "casual1", 0.0),
        ("human_human_casual2_human_casual_2_run", "casual2", 8.0),
        ("human_human_casual3_human_casual_3_run", "casual3", -8.0),
        ("human_arab_arab_run", "arab", 6.0),
        ("human_policeman_human_policeman_run", "police", 0.0),
        ("human_human_jungle_human_jungle_run", "jungle1", 0.0),
        ("human_human_jungle2_human_jungle2_run", "jungle2", 10.0),
        ("human_human_woman_human_woman_run", "woman", 0.0),
        ("human_human_punk_human_punk_run", "punk", 0.0),
        ("human_human_polar_human_polar_run", "polar1", 0.0),
        ("human_human_polar2_human_polar2_run", "polar2", 8.0),
    ]
    for prefix, name, hue in humans:
        n = cut_family(prefix, f"humans/{name}", hue, native_left=True)
        log(f"humans {name}: {n} frames")
    # the armed runs: soldier gun + bazooka (two uniforms each)
    for i, pref in enumerate(["human_soldier_gun_human_soldier_gun_run",
                              "human_soldier_bazooka_human_soldier_bazooka_run"]):
        n = cut_family(pref, f"humans/{"soldier" if i == 0 else "bazooka"}",
                       0.0, True)
        log(f"humans soldier/bazooka: {n}")
    # ---- animals (the atlas runs face RIGHT -> flip to LEFT) ----
    animals = [
        ("creatures_camel_camel_right_run", "camel", 0.0),
        ("creatures_puma_puma_right_run", "puma", 0.0),
        ("creatures_tiger_tiger_right_run", "tiger", 0.0),
        ("creatures_polarbear_polarbear_right_run", "bear", 0.0),
        ("creatures_penguin_penguin_walk", "penguin", 0.0),
        ("creatures_yeti_yeti_run", "yeti", 0.0),
    ]
    for prefix, name, hue in animals:
        n = cut_family(prefix, f"animals/{name}", hue, native_left=False)
        log(f"animals {name}: {n} frames")
    # ---- the underground cast (moles + lizards, native as authored) ----
    for pref, name in [("creatures_krot_krot", "mole"),
                       ("creatures_lizard_lizard", "lizard")]:
        n = cut_family(pref, f"ground/{name}", 0.0, native_left=False)
        log(f"ground {name}: {n}")
    # ---- vehicles: heli fly cycles (the rotor IS in the frames) -
    # the original has exactly these five attack helicopters
    for pref, name in [("vehicles_helicopter_china1_hel_1_fly", "heli"),
                      ("vehicles_helicopter_hel_assault", "heli_assault")]:
        n = cut_family(pref, f"vehicles/{name}", 0.0, native_left=True)
        log(f"{name}: {n} frames")
    n = cut_family("vehicles_plane_bomber_plane_1_fly", "vehicles/plane",
                   0.0, native_left=True)
    log(f"plane: {n} frames")
    n = cut_family("vehicles_plane_fighter1_plane_2_fly", "vehicles/jet",
                   0.0, native_left=True)
    log(f"jet: {n} frames")
    # ground machines: the car run + the truck + tanks + btr + launcher
    n = cut_family("vehicles_car_car1_", "vehicles/car", 0.0,
                   native_left=False)
    log(f"car: {n}")
    n = cut_family("vehicles_car_car_police_", "vehicles/police_car", 0.0,
                   native_left=False)
    log(f"police car: {n}")
    n = cut_family("vehicles_tank_tank_", "vehicles/tank", 0.0,
                   native_left=False)
    log(f"tank: {n}")
    n = cut_family("vehicles_btr_2_btr_", "vehicles/btr", 0.0,
                   native_left=False)
    log(f"btr: {n}")
    n = cut_family("vehicles_truck_car_truck_", "vehicles/truck", 0.0,
                   native_left=False)
    log(f"truck: {n}")
    # the rocket launcher + the mech + the dozer (multi-frame walks)
    for pref, name in [("vehicles_walking_mech_walking_mech_", "mech"),
                       ("vehicles_bulldozer_bulldozer_", "dozer")]:
        n = cut_family(pref, f"vehicles/{name}", 0.0, native_left=False)
        log(f"{name}: {n}")
    # ---- shots ----
    for pref, name in [("projectiles_bullet", "bullet"),
                       ("projectiles_rocket", "rocket"),
                       ("projectiles_tank_b", "tank_bullet"),
                       ("projectiles_ufo_bu", "ufo_ball"),
                       ("projectiles_dron", "drone_ball")]:
        n = cut_family(pref, f"shots/{name}", 0.0, native_left=False)
        log(f"shot {name}: {n}")
    # ---- the explosion family (the real 24-frame bake) ----
    n = cut_family("explosion_expl1_", "fx/expl", 0.0, native_left=False)
    log(f"explosions: {n}")
    # ---- the ufos ----
    n = cut_family("vehicles_ufo_ufo_", "vehicles/ufo", 0.0, native_left=True)
    log(f"ufo: {n}")
    n = cut_family("vehicles_ufo_plane_", "vehicles/ufojet", 0.0,
                   native_left=True)
    log(f"ufojet: {n}")


# ------------------------------------------------------------------ the places
# five places, the REAL layer stack: dirt tile + road tile + sky tile +
# the far strip (the original's own mountains/skylines) + the bound walls
PLACES = [
    # (our id, study loc dir, layer prefix, hue, the far crop band)
    ("desert", "desert", "level1", 0.0),
    ("polar", "polar", "level4", 0.0),
    ("city", "city", "level2", 0.0),
    ("jungle", "jungle", "level3", 0.0),
    ("medieval", "medieval", "surv3", 0.0),
]


def load_pair(loc: str, name: str) -> Image.Image:
    c = os.path.join(LOCS, loc, name + ".jpg")
    m = os.path.join(LOCS, loc, name + "_a.jpg")
    img = Image.open(c).convert("RGB")
    if os.path.exists(m):
        mk = Image.open(m).convert("L")
        if mk.size != img.size:
            mk = mk.resize(img.size, Image.NEAREST)
        arr = np.dstack([np.asarray(img, np.uint8),
                         np.asarray(mk, np.uint8)])
        return Image.fromarray(arr, "RGBA")
    return img.convert("RGBA")


def make_tileable(im: Image.Image) -> Image.Image:
    """mirror-blend the seam so the tile repeats without a hard line."""
    w, h = im.size
    band = min(48, h // 6)
    top = im.crop((0, 0, w, band)).transpose(Image.FLIP_TOP_BOTTOM)
    mask = Image.linear_gradient("L").resize((w, band)).transpose(
        Image.FLIP_TOP_BOTTOM)
    im.paste(top, (0, 0), mask)
    return im


def forge_places() -> None:
    for pid, loc, prefix, hue in PLACES:
        d = ensure(os.path.join(OUT, "places"))
        # ---- THE DIRT TILE: sample the cross-section's belly, mod, tile
        bg = load_pair(loc, f"{prefix}_bg_bottom")
        w, h = bg.size
        # the dirt band sits ~120..760px below the surface in the original
        y0 = min(h - 700, 140)
        patch = bg.crop((int(w * 0.18), y0, int(w * 0.18) + 640, y0 + 640))
        patch = make_tileable(patch)
        patch = hue_shift_img(patch, hue, 1.05, 1.12, 0.045)
        patch.save(os.path.join(d, f"{pid}_dirt.png"))
        # ---- THE ROAD (the surface line tile) ----
        road = load_pair(loc, f"{prefix}_bg_road")
        road = hue_shift_img(road, hue, 1.05, 1.0, 0.02)
        road.save(os.path.join(d, f"{pid}_road.png"))
        # ---- THE FULL SKY (the original's own layout config: sky_back is
        # the deep blue base, sky_03 the far clouds, sky_02 the near
        # clouds) - one 2048-wide tile that covers the whole sky height
        base = load_pair(loc, f"{prefix}_sky_back")
        base = hue_shift_img(base, hue, 1.03, 1.0, 0.015)
        SW, SHH = 2048, 1300
        sky = Image.new("RGBA", (SW, SHH), (0, 0, 0, 0))
        # the base: sky_back mirrored side by side, bottom-aligned, and
        # its top edge extended upward (the deep sky keeps going up)
        bk = SHH / base.height
        b2 = base.resize((max(1, int(base.width * bk)), SHH))
        sky.paste(b2, (0, 0))
        sky.paste(b2.transpose(Image.FLIP_LEFT_RIGHT), (b2.width, 0))
        # the cloud layers ride their seats: far clouds high, near low
        for i, seat in ((3, 0.42), (2, 0.62)):
            pth = os.path.join(LOCS, loc, f"{prefix}_sky_{i:02d}.jpg")
            if not os.path.exists(pth):
                continue
            lay = load_pair(loc, f"{prefix}_sky_{i:02d}")
            lay = hue_shift_img(lay, hue, 1.02, 1.0, 0.01)
            lk = SW / lay.width
            l2 = lay.resize((SW, max(1, int(lay.height * lk))))
            y = int(SHH * seat)
            sky.alpha_composite(l2, (0, y))
        make_tileable(sky).save(os.path.join(d, f"{pid}_sky.png"))
        # ---- THE FAR STRIP: sky_01 is the ORIGINAL's own surface-props
        # skyline (tents, palms, sphinx, pyramids, ruins) - it rides just
        # above the road, doubled wide for the parallax seat
        props = load_pair(loc, f"{prefix}_sky_01")
        props = hue_shift_img(props, hue, 1.04, 1.0, 0.02)
        wide = Image.new("RGBA", (props.width * 2, props.height),
                         (0, 0, 0, 0))
        wide.paste(props, (0, 0), props)
        wide.paste(props.transpose(Image.FLIP_LEFT_RIGHT),
                   (props.width, 0), props.transpose(Image.FLIP_LEFT_RIGHT))
        wide.save(os.path.join(d, f"{pid}_far.png"))
        # ---- THE BOUNDS (the level's edge rock walls; the city wears
        # its skyscraper edges - ScraperL/R) ----
        for side in ("l", "r"):
            cands = ([f"{prefix}_bound_{side}", f"rock_{side}"]
                     if pid != "city" else
                     [f"{prefix}_bound_{side}", f"Scraper{'L' if side == 'l' else 'R'}",
                      f"rock_{side}"])
            name = next((c for c in cands if os.path.exists(
                os.path.join(LOCS, loc, c + ".jpg"))), None)
            if name is None:
                log(f"! {pid}: no bound {side}")
                continue
            b = load_pair(loc, name)
            b = hue_shift_img(b, hue, 1.03, 0.97, 0.03)
            b.save(os.path.join(d, f"{pid}_bound_{side}.png"))
        log(f"place {pid}: dirt {patch.size}, sky {sky.size}, "
            f"far {wide.size}")
    # the DECALS: the desert cross-section's own tomb + skeleton, cut and
    # re-planted in our dirt (the study's own decorations)
    bg = load_pair("desert", "level1_bg_bottom")
    tomb = bg.crop((2135, 820, 2330, 970))       # the buried tomb
    save(trim(hue_shift_img(tomb, 0, 1.0, 0.95, 0.02)), "places/dec_tomb.png")
    sk = bg.crop((280, 620, 420, 900))           # the wall skeleton
    save(trim(hue_shift_img(sk, 0, 1.0, 0.95, 0.02)), "places/dec_bones.png")
    # ---- the SHOP previews: sky over far over dirt, one 320x200 per place
    for pid, loc, prefix, hue in PLACES:
        card = Image.new("RGBA", (320, 200), (0, 0, 0, 0))
        sky = Image.open(os.path.join(OUT, f"places/{pid}_sky.png"))
        far = Image.open(os.path.join(OUT, f"places/{pid}_far.png"))
        dirt = Image.open(os.path.join(OUT, f"places/{pid}_dirt.png"))
        sy = 112
        s2 = sky.resize((int(sky.width * sy / sky.height), sy))
        for x in range(0, 320, s2.width):
            card.paste(s2, (x, sy - s2.height), s2)
        fk = 96.0 / far.height
        f2 = far.resize((max(1, int(far.width * fk)), 96))
        card.paste(f2, (320 - f2.width, sy - 92), f2)
        d2 = dirt.resize((320, 200 - sy))
        for x in range(0, 320, d2.width):
            card.paste(d2, (x, sy), d2)
        road = Image.open(os.path.join(OUT, f"places/{pid}_road.png"))
        rk = road.resize((320, 8))
        card.paste(rk, (0, sy - 4), rk)
        save(card, f"shop/{pid}.png")
    log("shop previews: 5")


def pad_stack(sky: Image.Image, lay: Image.Image) -> Image.Image:
    if sky.height == 0:
        return lay.copy()
    w = min(sky.width, lay.width)
    out = Image.new("RGBA", (w, sky.height + lay.height), (0, 0, 0, 0))
    out.paste(sky.crop((0, 0, w, sky.height)), (0, 0))
    out.paste(lay.crop((0, 0, w, lay.height)), (0, sky.height),
              lay.crop((0, 0, w, lay.height)))
    return out


# ----------------------------------------------------------------- the extras
def forge_extras() -> None:
    # the wormCoin: the original's coin orb re-cut with OUR G
    d = ensure(os.path.join(OUT))
    coin = Image.new("RGBA", (72, 72), (0, 0, 0, 0))
    dr = ImageDraw.Draw(coin)
    dr.ellipse((4, 4, 68, 68), fill=(232, 176, 60, 255),
               outline=(120, 78, 18, 255), width=4)
    dr.ellipse((14, 14, 58, 58), fill=(248, 204, 96, 255))
    f = None
    try:
        from PIL import ImageFont
        f = ImageFont.truetype(os.path.join(
            PROJ, "..", "assets", "fonts", "Kenney_Mini.ttf"), 34)
    except Exception:
        f = ImageFont.load_default()
    dr.text((36, 34), "W", font=f, fill=(120, 78, 18, 255), anchor="mm")
    coin.save(os.path.join(d, "coin.png"))
    # the rockbreaker's rockCoin chip icon (the top-bar chip wears it)
    rbd = ensure(os.path.join(RB, "world"))
    rc = coin.resize((64, 64))
    dr2 = ImageDraw.Draw(rc)
    dr2.text((32, 32), "R", font=f, fill=(60, 44, 20, 255), anchor="mm")
    rc.save(os.path.join(rbd, "rockcoin.png"))
    # the dot (fx particle) stays from v040-9
    dot = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    dd = ImageDraw.Draw(dot)
    dd.ellipse((6, 6, 26, 26), fill=(255, 255, 255, 255))
    dot.save(os.path.join(d, "dot.png"))
    log("extras: coin + rockcoin + dot")


def forge_thumbnail() -> None:
    """960x640: the worm bursting from the dunes under the pyramids."""
    W, H = 960, 640
    im = Image.new("RGBA", (W, H))
    # the sky + far from the desert bake
    sky = Image.open(os.path.join(OUT, "places/desert_sky.png")).convert(
        "RGBA")
    far = Image.open(os.path.join(OUT, "places/desert_far.png")).convert(
        "RGBA")
    dirt = Image.open(os.path.join(OUT, "places/desert_dirt.png")).convert(
        "RGBA")
    road = Image.open(os.path.join(OUT, "places/desert_road.png")).convert(
        "RGBA")
    surf_y = 400
    # the sky fills the top
    sy = Image.new("RGBA", (W, surf_y))
    for x in range(0, W, sky.width):
        sy.paste(sky, (x, max(0, surf_y - sky.height)), sky)
    im.paste(sy.crop((0, 0, W, surf_y)), (0, 0))
    # the far strip rides just above the line
    fs = far.resize((int(far.width * surf_y * 0.42 / far.height),),
                    Image.LANCZOS) if False else far
    fk = surf_y * 0.5 / fs.height
    fs2 = fs.resize((max(1, int(fs.width * fk)), max(1, int(fs.height * fk))))
    im.paste(fs2, (W - fs2.width - 30, surf_y - fs2.height + 6), fs2)
    # the dirt body
    dy = H - surf_y
    dt = Image.new("RGBA", (W, dy))
    for x in range(0, W, dirt.width):
        for y in range(0, dy, dirt.height):
            dt.paste(dirt, (x, y))
    im.paste(dt, (0, surf_y))
    # the road line
    rk = road.resize((W, max(6, int(road.height * 1.4))))
    im.paste(rk, (0, surf_y - rk.height // 2), rk)
    # THE WORM bursting out of the dirt, head up-right, jaw open
    head = Image.open(os.path.join(OUT, "worms/w01_head_open.png")).convert(
        "RGBA")
    body = Image.open(os.path.join(OUT, "worms/w01_body_0.png")).convert(
        "RGBA")
    target_h = 190
    k = target_h / max(1, head.height)
    head2 = head.resize((max(1, int(head.width * k)), target_h))
    bx, by = W * 0.42 - 60, surf_y - 66
    im.paste(head2, (int(bx), int(by)), head2)
    seg = body
    sk2 = target_h * 0.8 / max(1, seg.height)
    seg2 = seg.resize((max(1, int(seg.width * sk2)), max(1, int(seg.height * sk2))))
    for i in range(4):
        x = int(bx) - 26 - int(i * seg2.width * 0.72)
        y = int(by) + 44 + i * 30
        if y > H - 20:
            break
        seg3 = seg2.rotate(28 + i * 16, expand=True,
                           resample=Image.BICUBIC)
        im.paste(seg3, (x, y), seg3)
    # a little dust burst at the breach
    dust = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dd = ImageDraw.Draw(dust)
    for i in range(26):
        a = rng.uniform(math.pi * 1.05, math.pi * 1.95)
        r = rng.uniform(60, 190)
        x = W * 0.42 + math.cos(a) * r
        y = surf_y + 6 - math.sin(a) * r * 0.45
        rr = rng.uniform(4, 14)
        dd.ellipse((x - rr, y - rr, x + rr, y + rr),
                   fill=(214, 178, 128, rng.integers(90, 170)))
    im.alpha_composite(dust)
    im.convert("RGB").save(os.path.join(THUMBS, "deathworm.png"), quality=92)
    log("thumbnail: 960x640")


def main() -> None:
    ensure(OUT)
    ensure(THUMBS)
    for wid, (skin, hue) in WORM_SKINS.items():
        forge_worm(wid, skin, hue)
    forge_things()
    forge_places()
    forge_extras()
    forge_thumbnail()
    log("FORGE DONE")


if __name__ == "__main__":
    main()
