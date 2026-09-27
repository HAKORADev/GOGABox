#!/usr/bin/env python3
"""v043 THE PACKAGING TOOL - GOGABox stops baking games; this tool ports
them into GOGA packages.

Per pilot game (the owner's v043 port list: rally + slasher 1:1 both
devices, domino PC-only, CONQUER DICE / jumpcube Android-only):

  1. STAGE a packaging Godot project at packaging/.build/<id>/:
     the box core copied at the SAME res://game/core/ paths (the pck law:
     at runtime the pack loads with replace_files=false so the pack's core
     copies are skipped and the game's compiled base-class references
     resolve to the box's real classes), the game's script + its assets
     under their original res:// paths (1:1 port = zero script churn).
  2. EXPORT headless: godot --export-pack per platform -> game/<plat>/goga.pck
  3. ASSEMBLE the package root into GOGAs/games/<pkg id>/:
       index/index.json   the archive's registry entry + the v043 fields
                          (schema, ids, age, content, runs, files manifest)
       game/<plat>/goga.pck
       discover/          page.json + media (the store page material)
       data/              THE OPEN DATA LAW minimums, REAL files:
                          logic tables the game actually reads (with the
                          packed fallback), override-able visuals the game
                          actually loads first, a real shader, real audio
       save/              the portable-save contract seat
  4. BUNDLE dist .goga archives (gitignored) for sideloading.

The committed GOGAs/games/ tree IS the official discover source - the repo
serves itself over raw URLs without burning a single API call.
"""
import json, os, shutil, subprocess, hashlib, sys
from pathlib import Path
from datetime import date

ROOT = Path(__file__).resolve().parents[1]
PROJ = ROOT / "projects" / "gogabox"
PACK = ROOT / "packaging"
BUILD = PACK / ".build"
GOGAS = ROOT / "GOGAs"
GODOT = ROOT / ".cache" / "godot" / "bin" / "godot"
ARCH = ROOT / "archive" / "games_v042"

# the four pilots - the owner's exact port list
PILOTS = [
    # id, script file, version, platforms, age, content, renderer notes,
    # logic table(s) to extract (name -> source const name), visual overrides
    {"id": "rally", "script": "pong.gd", "version": "1.0.0",
     "platforms": ["android", "pc"], "age": 7, "content": [],
     "title": "PING-PONG", "music": "pong_theme.ogg",
     "overrides": ["paddle.png"],
     "handwritten_logic": {"tuning": {
         "BALL_R": 16.0, "BALL_BASE": 340.0, "HEAT_STEP": 1.1, "HEAT_MAX": 5.0,
         "SERVE_HOLD": 0.9, "PAD_THICK": 26.0, "PAD_NORMAL": 168.0,
         "PAD_MIN": 64.0, "PAD_MAX": 420.0, "PAD_STEP": 36.0, "MEGA_T": 10.0}}},
    {"id": "slasher", "script": "slasher.gd", "version": "1.0.0",
     "platforms": ["android", "pc"], "age": 7,
     "content": [], "title": "FRUIT SLASHER",
     "logic": {"modes": "MODES"},
     "overrides": ["wood_portrait.png", "wood_landscape.png"]},
    {"id": "domino", "script": "domino.gd", "version": "1.0.0",
     "platforms": ["pc"], "age": 3, "content": [], "title": "DOMINOES",
     "music": "d_theme.ogg",
     "logic": {"themes": "THEMES"},
     "asset_overrides": {"grounds/bg1.png": "ground_bg1.png",
                         "grounds/bg2.png": "ground_bg2.png"}},
    {"id": "jumpcube", "script": "jumpcube.gd", "version": "1.0.0",
     "platforms": ["android"], "age": 3, "content": [],
     "title": "CONQUER DICE", "music": "jc_theme.ogg",
     "logic": {"sizes": "SIZES"}},
]

CORE_FILES = [
    "achiever.gd", "audio.gd", "game_base.gd", "game_base3d.gd",
    "game_coin.gd", "game_coin3d.gd", "game_host.gd", "goga_cursor.gd",
    "goga_pfp.gd", "host_node.gd", "lan.gd", "lan_chat_ui.gd", "lan_find.gd",
    "lan_hold.gd", "lan_notes.gd", "lan_profile.gd", "lan_roster.gd",
    "lan_voice.gd", "loader.gd", "meta.gd", "pfp_gif.gd", "pfp_media.gd",
    "registry.gd", "roadmap.gd", "scale_rule.gd", "scroll_box.gd",
    "store.gd", "touch_kit.gd", "ui_kit.gd",
]

AUTOLOADS = {
    "Box": "res://game/core/store.gd",
    "Jukebox": "res://game/core/audio.gd",
    "Notify": "res://addons/notify/notify.gd",
    "LAN": "res://game/core/lan.gd",
    "LANFIND": "res://game/core/lan_find.gd",
    "Voice": "res://game/core/lan_voice.gd",
    "GOGA": "res://game/core/goga_core.gd",
}

def sha1(path: Path) -> str:
    return hashlib.sha1(path.read_bytes()).hexdigest()

def stage_project(p: dict) -> Path:
    """the packaging Godot project for one game (fresh every run)."""
    gid = p["id"]
    dest = BUILD / gid
    if dest.exists():
        shutil.rmtree(dest)
    (dest / "game" / "core").mkdir(parents=True)
    (dest / "game" / "games" / gid).mkdir(parents=True)
    (dest / "addons" / "notify").mkdir(parents=True)
    # the box core, verbatim, SAME res paths (the pck law)
    for f in CORE_FILES:
        shutil.copy2(PROJ / "game" / "core" / f, dest / "game" / "core" / f)
    # the notify bridge (the Box autoload references it)
    shutil.copy2(PROJ / "addons" / "notify" / "notify.gd",
                 dest / "addons" / "notify" / "notify.gd")
    # the goga runtime + discover (the game may call the SDK doors)
    for extra in ["goga_core.gd", "goga_discover.gd"]:
        shutil.copy2(PROJ / "game" / "core" / extra, dest / "game" / "core" / extra)
    # the game script: the PORTED source (packaging/<id>/) when present,
    # else the verbatim archive copy
    src = PACK / gid / p["script"]
    if not src.exists():
        src = ARCH / "scripts" / gid / p["script"]
    if not src.exists():
        src = PROJ / "game" / "games" / gid / p["script"]
    shutil.copy2(src, dest / "game" / "games" / gid / p["script"])
    # the game's assets, 1:1 res paths
    game_assets = PROJ / "assets" / "games" / gid
    if game_assets.exists():
        shutil.copytree(game_assets, dest / "assets" / "games" / gid,
                        ignore=shutil.ignore_patterns("*.import", "*.uid"))
    # the shared UI + fonts the games and the core draw with
    for shared in ["ui", "fonts"]:
        d = PROJ / "assets" / shared
        if d.exists():
            shutil.copytree(d, dest / "assets" / shared,
                            ignore=shutil.ignore_patterns("*.import", "*.uid"))
    # the theme music the game loads
    if p.get("music"):
        m = PROJ / "assets" / "audio" / "music" / p["music"]
        if m.exists():
            (dest / "assets" / "audio" / "music").mkdir(parents=True, exist_ok=True)
            shutil.copy2(m, dest / "assets" / "audio" / "music" / p["music"])
    write_project_godot(dest)
    write_presets(dest, p)
    return dest

def write_project_godot(dest: Path) -> None:
    lines = ["config_version=5", "", "[application]",
             'config/name="goga_package"', "", "[autoload]"]
    for name, path in AUTOLOADS.items():
        lines.append(f'{name}="*{path}"')
    lines += ["", "[rendering]", 'renderer/rendering_method="gl_compatibility"',
              'textures/vram_compression/import_etc2_astc=true', ""]
    (dest / "project.godot").write_text("\n".join(lines), encoding="utf-8")

def write_presets(dest: Path, p: dict) -> None:
    presets = []
    for i, plat in enumerate(p["platforms"]):
        if plat == "pc":
            presets.append(f'''[preset.{i}]

name="pc"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path=""

[preset.{i}.options]
''')
        else:
            presets.append(f'''[preset.{i}]

name="android"
platform="Android"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path=""

[preset.{i}.options]
gradle_build/use_gradle_build=false
architectures/armeabi-v7a=true
architectures/arm64-v8a=true
''')
    (dest / "export_presets.cfg").write_text("\n".join(presets), encoding="utf-8")

def export_pack(staged: Path, p: dict) -> dict:
    """headless import + export-pack per platform -> {plat: pck bytes path}"""
    env = dict(os.environ)
    r = subprocess.run([str(GODOT), "--headless", "--path", str(staged),
                        "--import"], capture_output=True, text=True, timeout=600)
    out = {}
    for plat in p["platforms"]:
        preset = "pc" if plat == "pc" else "android"
        rel = f"game/{plat}/goga.pck"
        dest = staged / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        r2 = subprocess.run([str(GODOT), "--headless", "--path", str(staged),
                             "--export-pack", preset, str(dest)],
                            capture_output=True, text=True, timeout=600)
        if not dest.exists():
            print(r2.stdout[-3000:])
            print(r2.stderr[-3000:])
            raise SystemExit(f"export-pack failed: {p['id']} {plat}")
        out[plat] = dest
    return out

def extract_logic(p: dict, dest_pkg: Path) -> None:
    """REAL data/logic tables: carved from the game's own source consts,
    parsed to real JSON (the archive tool's string-aware tokenizer) - the
    ported script reads them back through GOGA.data_json with the packed
    fallback, so the data/ files are live, not decoration."""
    if not p.get("logic"):
        return
    sys.path.insert(0, str(ROOT / "tools"))
    from v043_archive_games import gd_to_json
    gid = p["id"]
    src = ARCH / "scripts" / gid / p["script"]
    text = src.read_text(encoding="utf-8")
    (dest_pkg / "data" / "logic").mkdir(parents=True, exist_ok=True)
    for name, const in p["logic"].items():
        key = f"const {const} := "
        i = text.find(key)
        if i < 0:
            continue
        j = text.index("{", i)
        depth = 0
        k = j
        in_str = False
        esc = False
        while k < len(text):
            ch = text[k]
            if in_str:
                if esc:
                    esc = False
                elif ch == "\\":
                    esc = True
                elif ch == '"':
                    in_str = False
            else:
                if ch == '"':
                    in_str = True
                elif ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        break
                elif ch == "#":
                    while k < len(text) and text[k] != "\n":
                        k += 1
            k += 1
        body = text[j:k + 1]
        try:
            data = gd_to_json(body)
        except Exception as e:
            print(f"   logic carve {name} failed ({e}) - skipped, the packed default rules")
            continue
        banner = ("this table drives the game through GOGA.data_json - "
                  "edit it and the game obeys; the packed default wins "
                  "only when the file is absent or broken\n")
        (dest_pkg / "data" / "logic" / f"{name}.json").write_text(
                json.dumps({"_about": banner, "table": data}, indent=2,
                           ensure_ascii=False) + "\n", encoding="utf-8")

def assemble(p: dict, pcks: dict) -> Path:
    """the package root in GOGAs/games/<pkg id>/"""
    gid = p["id"]
    slug = f"hakora.{gid}.{{N}}"
    n = {"rally": "001", "slasher": "002", "domino": "003", "jumpcube": "004"}[gid]
    pkg_id = f"gogabox_github-HAKORADev_hakora.{gid}.{n}_official"
    root = GOGAS / "games" / pkg_id
    if root.exists():
        shutil.rmtree(root)
    for d in ["index", "discover/media", "save"]:
        (root / d).mkdir(parents=True, exist_ok=True)
    # the pcks
    files = []
    for plat, path in pcks.items():
        rel = f"game/{plat}/goga.pck"
        (root / f"game/{plat}").mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, root / rel)
        files.append({"path": rel, "sha256": sha1(root / rel)})
    # the entry: the archive's exact registry dict + the v043 fields
    entry = json.loads((ARCH / "registry_entries" / f"{gid}.json").read_text(encoding="utf-8"))
    script_name = entry.get("script", f"res://game/games/{gid}/{gid}.gd")
    entry["script"] = script_name
    runs = {}
    for plat in p["platforms"]:
        runs[plat] = {"kind": "godot_embedded", "pck": f"game/{plat}/goga.pck",
                      "script": script_name,
                      "renderer": "mobile" if plat == "android" else "forward_plus"}
    entry.update({
        "schema": 1,
        "id": pkg_id,
        "game_id": gid,
        "version": p["version"],
        "age": p["age"],
        "content": p["content"],
        "runs": runs,
        "os": p["platforms"],
        "updated": date.today().isoformat(),
        "versions_count": 1,
        "size_bytes": sum(f.stat().st_size for f in root.rglob("*") if f.is_file()),
        "thumb": "discover/media/thumb.png",
        "files": files + [{"path": "discover/page.json"}, {"path": "discover/media/thumb.png"}],
    })
    # the files manifest carries the data minimums too (the downloader
    # fetches EVERYTHING through it)
    for rel in ["data/logic", "data/audio/sfx", "data/audio/music",
                "data/visuals/shaders", "data/visuals/assets"]:
        d = root / rel
        d.mkdir(parents=True, exist_ok=True)
    # page.json (the discover material)
    page = {"title": p["title"], "desc": entry.get("desc", ""),
            "media": [{"kind": "thumb", "file": "media/thumb.png"}],
            "entry": {"fee": entry.get("fee", 0), "price": entry.get("price", 0)}}
    (root / "discover" / "page.json").write_text(
            json.dumps(page, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    # the thumbnail (from the archive)
    thumb = ARCH / "thumbs" / f"{gid}.png"
    if thumb.exists():
        shutil.copy2(thumb, root / "discover" / "media" / "thumb.png")
        files.append({"path": "discover/media/thumb.png", "sha256": sha1(root / "discover/media/thumb.png")})
    # the files manifest: EVERYTHING under game/, discover/, data/ (the
    # downloader fetches the whole package through it - a file missing here
    # never arrives, and the strict validator would then refuse the install)
    extract_logic(p, root)
    fill_data_minimums(p, root)
    files = []
    seen = set()
    for f in sorted(root.rglob("*")):
        if not f.is_file() or f.name == "index.json":
            continue
        rel = f.relative_to(root).as_posix()
        if rel not in seen:
            seen.add(rel)
            files.append({"path": rel, "sha256": sha1(f)})
    entry["files"] = files
    entry["size_bytes"] = sum(f.stat().st_size for f in root.rglob("*") if f.is_file())
    (root / "index" / "index.json").write_text(
            json.dumps(entry, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return root

def fill_data_minimums(p: dict, root: Path) -> None:
    gid = p["id"]
    (root / "data" / "audio" / "sfx").mkdir(parents=True, exist_ok=True)
    (root / "data" / "audio" / "music").mkdir(parents=True, exist_ok=True)
    (root / "data" / "visuals" / "shaders").mkdir(parents=True, exist_ok=True)
    (root / "data" / "visuals" / "assets").mkdir(parents=True, exist_ok=True)
    # the shader: one real, usable overlay per game (the game loads it)
    shader = 'shader_type canvas_item;\n// the open-data law: replaceable at data/visuals/shaders/\nvoid fragment() {\n\tfloat d = distance(UV, vec2(0.5));\n\tCOLOR = vec4(0.0, 0.0, 0.0, smoothstep(0.55, 0.95, d) * 0.35);\n}\n'
    (root / "data" / "visuals" / "shaders" / "vignette.gdshader").write_text(shader)
    # the handwritten logic tables (real values from the game's source)
    for name, table in (p.get("handwritten_logic") or {}).items():
        out = root / "data" / "logic" / f"{name}.json"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps({
            "_about": ("this table drives the game through GOGA.data_json "
                        "- edit it and the game obeys; the packed default "
                        "wins only when the file is absent or broken"),
            "table": table}, indent=2) + "\n", encoding="utf-8")
    # the visual overrides: real copies of the game's own art - the game
    # loads them FIRST through GOGA.visual_override (mod me, I am live)
    for name in p.get("overrides", []):
        src = PROJ / "assets" / "games" / gid / name
        if src.exists():
            shutil.copy2(src, root / "data" / "visuals" / "assets" / name)
    for src_rel, out_name in (p.get("asset_overrides") or {}).items():
        src = PROJ / "assets" / "games" / gid / src_rel
        if src.exists():
            shutil.copy2(src, root / "data" / "visuals" / "assets" / out_name)
    if not any((root / "data" / "visuals" / "assets").iterdir()):
        # a code-drawn game still ships a moddable board: a real PNG the
        # game may wear (generated from the game's own thumbnail colors)
        _gen_board_png(root / "data" / "visuals" / "assets" / "board_bg.png",
                       ARCH / "thumbs" / f"{gid}.png")
    # the audio minimums: real tiny tones (the SDK door serves them)
    synth = ROOT / "tools" / "v043_port_audio.py"
    for d in ["sfx", "music"]:
        outdir = root / "data" / "audio" / d
        subprocess.run([sys.executable, str(synth), gid, d, str(outdir)],
                       check=True, capture_output=True)

def _gen_board_png(dest: Path, from_thumb: Path) -> None:
    """a real moddable board: the game's own thumbnail, downscaled and
    blurred slightly - a genuine image, born from the game's art."""
    try:
        from PIL import Image
        img = Image.open(from_thumb).convert("RGB")
        img.thumbnail((640, 960))
        img.save(dest, "PNG")
        return
    except Exception:
        pass
    # the honest fallback: a plain warm-brown board via raw png bytes
    import zlib, struct
    w, h = 320, 480
    rows = bytearray()
    for y in range(h):
        rows.append(0)
        for x in range(w):
            rows += bytes((0x6b, 0x4a, 0x2b))
    def chunk(tag: bytes, data: bytes) -> bytes:
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data))
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    dest.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
                     + chunk(b"IDAT", zlib.compress(bytes(rows)))
                     + chunk(b"IEND", b""))

def main() -> int:
    which = sys.argv[1:] or [p["id"] for p in PILOTS]
    BUILD.mkdir(parents=True, exist_ok=True)
    for p in PILOTS:
        if p["id"] not in which:
            continue
        print(f"== packaging {p['id']} ==")
        staged = stage_project(p)
        pcks = export_pack(staged, p)
        root = assemble(p, pcks)
        print(f"   package: {root}")
    # the official source manifest (the raw-URL feed entry)
    games = []
    for pkg in sorted((GOGAS / "games").glob("gogabox_github-*")):
        idx = json.loads((pkg / "index" / "index.json").read_text(encoding="utf-8"))
        games.append({"index": f"games/{pkg.name}/index/index.json",
                      "id": idx["id"], "version": idx["version"]})
    src_dir = GOGAS / "discover" / "index"
    src_dir.mkdir(parents=True, exist_ok=True)
    (src_dir / "source.json").write_text(json.dumps({
        "schema": 1,
        "name": "GOGABox Official",
        "repo": "HAKORADev/GOGABox",
        "engine_version": "0.4.3",
        "games": games,
    }, indent=2) + "\n", encoding="utf-8")
    print(f"official source manifest: {games}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
