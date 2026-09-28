#!/usr/bin/env python3
"""v043 pass 3 - THE WEB PILOT: GOGA ORBIT, the three.js game that proves
the web runner end to end (the owner's order: "try to make a three.js web
game and make it in the app").

Assembles the package into GOGAs/games/<pkg id>/ as the FIFTH official
pilot:
  game/web/     index.html + main.js + three.min.js (vendored MIT) +
                goga_bridge.js (the SDK bridge, copied from sdk/web/)
  index/        index.json (kind: web, entry game/web/index.html) +
                versions.json (the ledger)
  discover/     page.json + the generated thumbnail
  data/         the open-data minimums as REAL files the game family uses
  save/         the portable-save seat (README.md, the law's proof)

No Godot export - a web game ships plain files. The pck law does not
apply; the runner serves the folder over localhost and the in-app
surface loads it. The catalog regenerates through v043_package's
write_catalog (one voice for the whole GOGAs/discover catalog).
"""
import json, shutil, sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from v043_package import write_catalog, _gen_board_png  # noqa: E402

GOGAS = ROOT / "GOGAS_X"  # placeholder so imports above resolve GOGAS only
GOGAS = ROOT / "GOGAs"
WEB = ROOT / "packaging" / "orbit" / "web"
PKG_ID = "gogabox_github-HAKORADev_hakora.orbit.005_official"

ABOUT = ("this table drives the game through the web SDK bridge - the "
         "packed default wins only when the file is absent or broken\n")


def build() -> Path:
    root = GOGAS / "games" / PKG_ID
    if root.exists():
        shutil.rmtree(root)
    for d in ["index", "discover/media", "save", "game/web",
              "data/logic", "data/audio/sfx", "data/audio/music",
              "data/visuals/shaders", "data/visuals/assets"]:
        (root / d).mkdir(parents=True, exist_ok=True)
    # ---- the runnable: plain web files ----
    for f in ["index.html", "main.js", "three.min.js", "goga_bridge.js"]:
        shutil.copy2(WEB / f, root / "game" / "web" / f)
    # ---- the data minimums (real files, the open-data law) ----
    (root / "data" / "logic" / "tuning.json").write_text(json.dumps({
        "_about": ABOUT + "orbit's lane tuning - edit and the game obeys",
        "table": {
            "lane_radius": 22.0, "start_speed": 0.55, "speed_max_bonus": 1.4,
            "gold_bonus": 25, "score_per_sec": 6, "steer": 0.012,
            "rock_count": 14, "gold_count": 6,
        }}, indent=2) + "\n", encoding="utf-8")
    (root / "data" / "visuals" / "shaders" / "vignette.gdshader").write_text(
        'shader_type canvas_item;\n// the open-data law: replaceable at data/visuals/shaders/\n'
        'void fragment() {\n\tfloat d = distance(UV, vec2(0.5));\n'
        '\tCOLOR = vec4(0.0, 0.0, 0.0, smoothstep(0.55, 0.95, d) * 0.35);\n}\n')
    _gen_board_png(root / "data" / "visuals" / "assets" / "board_bg.png",
                   root / "discover" / "media" / "thumb.png")
    (root / "data" / "audio" / "sfx" / "README.txt").write_text(
        "the web pilot's events are synthesized in-page (WebAudio); drop "
        "real sfx files here and the bridge serves them to any modder.\n")
    (root / "data" / "audio" / "music" / "README.txt").write_text(
        "the web pilot loops the in-page ambience; real music files land "
        "here through the same modding door.\n")
    (root / "save" / "README.md").write_text(
        "# save/ - the portable save seat\n\n"
        "The web pilot writes its best-run record here through the SDK "
        "bridge (GOGA.saveWrite) - carried with the package, never in "
        "app-data bloat.\n")
    # ---- the thumbnail (drawn: the lane + the ship + the gold) ----
    _draw_thumb(root / "discover" / "media" / "thumb.png")
    # ---- index.json + the ledger ----
    files = [{"path": f.relative_to(root).as_posix(),
              "sha256": __import__("hashlib").sha1(f.read_bytes()).hexdigest()}
             for f in sorted(root.rglob("*")) if f.is_file()]
    size = sum(f.stat().st_size for f in root.rglob("*") if f.is_file())
    entry = {
        "schema": 1,
        "id": PKG_ID,
        "game_id": "orbit",
        "title": "GOGA ORBIT",
        "tag": "the web pilot - three.js in the box",
        "version": "1.0.0",
        "age": 3,
        "content": [],
        "genres": {"main": ["arcade"], "sub": ["minimal", "retro"]},
        "os": ["android", "pc"],
        "runs": {
            "android": {"kind": "web", "entry": "game/web/index.html"},
            "pc": {"kind": "web", "entry": "game/web/index.html"},
        },
        "thumb": "discover/media/thumb.png",
        "desc": ("A three.js game running INSIDE the box: drag to steer the "
                 "dart around the orbit lane, catch the gold, dodge the "
                 "rocks. Served by the box's own localhost seat, bridged "
                 "through window.GOGA - the web kind, proven end to end."),
        "fee": 0, "price": 0, "coin_div": 10,
        "updated": date.today().isoformat(),
        "versions_count": 1,
        "size_bytes": size,
        "files": files,
    }
    (root / "index" / "index.json").write_text(
        json.dumps(entry, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (root / "index" / "versions.json").write_text(json.dumps({
        "schema": 1,
        "versions": [{"version": "1.0.0", "updated": date.today().isoformat(),
                      "notes": "GOGA ORBIT initial package release"}],
    }, indent=2) + "\n", encoding="utf-8")
    # ---- the discover page ----
    page = {"title": "GOGA ORBIT",
            "desc": entry["desc"],
            "media": [{"kind": "thumb", "file": "media/thumb.png"}],
            "entry": {"fee": 0, "price": 0}}
    (root / "discover" / "page.json").write_text(
        json.dumps(page, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return root


def _draw_thumb(dest: Path) -> None:
    from PIL import Image, ImageDraw
    w, h = 512, 512
    img = Image.new("RGB", (w, h), (11, 13, 22))
    d = ImageDraw.Draw(img)
    # the lane
    d.ellipse([w//2-170, h//2-170, w//2+170, h//2+170],
              outline=(58, 44, 24), width=10)
    # the posts
    import math
    for i in range(24):
        a = i / 24 * math.tau
        x = w//2 + math.cos(a) * 170
        y = h//2 + math.sin(a) * 170
        d.ellipse([x-4, y-4, x+4, y+4],
                  fill=(245, 197, 107) if i % 3 == 0 else (81, 64, 42))
    # the planet core
    d.ellipse([w//2-70, h//2-70, w//2+70, h//2+70], fill=(42, 53, 80))
    d.polygon([(w//2+170, h//2-8), (w//2+140, h//2-24), (w//2+146, h//2+8)],
              fill=(245, 197, 107))
    d.ellipse([w//2+228, h//2+40, w//2+244, h//2+56], fill=(255, 215, 107))
    d.ellipse([w//2-240, h//2-180, w//2-224, h//2-164], fill=(138, 144, 184))
    dest.parent.mkdir(parents=True, exist_ok=True)
    img.save(dest, "PNG")


if __name__ == "__main__":
    root = build()
    write_catalog()
    print(f"web pilot: {root}")
