#!/usr/bin/env python3
"""make_game - ANY Godot game folder becomes a GOGABox game folder.

    python3 tools/make_game.py <source-folder> [--id <game-id>]

The source folder is YOUR game:

    my_game/
      game.json     optional - the name file (title, age, fee, genres...);
                    missing keys get honest defaults
      entry.gd      the main script (extends GameBase) - the default entry
                    when game.json carries no "script"
      ...           your assets in any layout, referenced by res:// literals

The output is the shipping shape, written straight into GOGAs/games/<id>/:

    GOGAs/games/<id>/
      game.json     the name file (yours, defaults filled in)
      game.pck      THE ONE ENTRY - one platform-neutral pack
      thumb.png     the feed tile (copy your 960x640 png in, or add one later)

What the tool does:

  1. stages a build project around your folder: the box core at its real
     res:// paths (that is what lets your script extend GameBase), the
     box's shared UI + fonts, and your files under
     res://game/games/<id>/ (a top-level assets/ folder lands at
     res://assets/games/<id>/, a top-level audio/ folder at
     res://assets/audio/)
  2. bridges sibling classes (a pack's class_names never reach the box's
     global class cache - the bridge preloads them locally so typed
     annotations never die at parse)
  3. THE AUDIT: every res:// file literal in your scripts must exist in
     the stage - missing art/audio aborts the build BY NAME. Box-project
     files are carried in automatically; audio is the one soft seat (the
     Jukebox no-ops a missing stream)
  4. imports + exports the one game.pck, assembles the folder

THE PACK CONTENTS LAW: the pack carries YOUR files only - the box core,
the shared UI/fonts and the addons stay OUT (they were only staged so
the export could compile). A pack that carried the box's core would
SHADOW the box's own code the moment it mounts (PackedData outranks the
real files), and every future box fix would silently never run inside
that game. The box provides the core; the pack provides the game.

Requires the pinned toolchain: tools/bootstrap.sh once, then this works.
"""
import argparse, json, os, re, shutil, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJ = ROOT / "projects" / "gogabox"
GOGAS = ROOT / "GOGAs"
BUILD = ROOT / "packaging" / ".build"
GODOT = ROOT / ".cache" / "godot" / "bin" / "godot"

CORE_FILES = [
    "achiever.gd", "audio.gd", "game_base.gd", "game_base3d.gd",
    "game_coin.gd", "game_coin3d.gd", "game_host.gd", "goga_core.gd",
    "goga_cursor.gd", "goga_pfp.gd", "host_node.gd", "lan.gd",
    "lan_chat_ui.gd", "lan_find.gd", "lan_hold.gd", "lan_notes.gd",
    "lan_profile.gd", "lan_roster.gd", "lan_voice.gd", "loader.gd",
    "meta.gd", "pfp_gif.gd", "pfp_media.gd", "registry.gd", "roadmap.gd",
    "scale_rule.gd", "scroll_box.gd", "store.gd", "touch_kit.gd",
    "ui_kit.gd",
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

RES_RE = re.compile(r'res://[A-Za-z0-9_\-\.\/]+')
CLASS_RE = re.compile(r'^class_name\s+(\w+)', re.M)

AUDIT_FILE_RE = re.compile(
    r'res://[A-Za-z0-9_\-\.\/]+\.(png|ogg|wav|mp3|ttf|gdshader|gd|svg|json|txt|import)$')

# the honest defaults a bare game.json grows
DEFAULTS = {
    "age": 3,
    "content": [],
    "os": ["android", "pc"],
    "fee": 0,
    "price": 0,
}


def read_json(p: Path) -> dict:
    if not p.exists():
        return {}
    try:
        v = json.loads(p.read_text(encoding="utf-8"))
        return v if isinstance(v, dict) else {}
    except json.JSONDecodeError as e:
        raise SystemExit("BROKEN JSON %s: %s" % (p, e))


def bridge_classes(game_dir: Path) -> None:
    """THE CLASS BRIDGE (v044, carried): each sibling class a script names
    gets a local `const C := preload("<res path>")` - the const is a real
    type in annotations and .new() calls, with zero hand edits."""
    files = sorted(game_dir.rglob("*.gd"))
    classes = {}
    for f in files:
        m = CLASS_RE.search(f.read_text(encoding="utf-8", errors="replace"))
        if m:
            classes[m.group(1)] = f
    if not classes:
        return
    for f in files:
        txt = f.read_text(encoding="utf-8", errors="replace")
        orig = txt
        mine = CLASS_RE.search(txt)
        need = []
        for cname, cfile in classes.items():
            if mine and mine.group(1) == cname:
                continue
            body = CLASS_RE.sub("", txt, count=1)
            if not re.search(r'\b%s\b' % re.escape(cname), body):
                continue
            rel = "res://" + cfile.relative_to(game_dir.parents[2]).as_posix()
            need.append((cname, rel))
        if not need:
            continue
        lines = txt.split("\n")
        insert_at = 0
        for i, ln in enumerate(lines):
            if ln.startswith("class_name "):
                insert_at = i + 1
                continue
            if ln.startswith("extends "):
                insert_at = i + 1
                break
            if ln.strip() == "" and i < 4:
                continue
            break
        block = ["# THE CLASS BRIDGE: the pack's classes are not in the",
                 "# box's global cache - these consts carry them locally."]
        for cname, rel in need:
            block.append('const %s := preload("%s")' % (cname, rel))
        lines[insert_at:insert_at] = block
        f.write_text("\n".join(lines), encoding="utf-8")


def stage(src: Path, gid: str, pre_audit=None) -> Path:
    dest = BUILD / gid
    if dest.exists():
        shutil.rmtree(dest)
    (dest / "game" / "core").mkdir(parents=True)
    (dest / "game" / "games" / gid).mkdir(parents=True)
    (dest / "addons" / "notify").mkdir(parents=True)
    for f in CORE_FILES:
        shutil.copy2(PROJ / "game" / "core" / f, dest / "game" / "core" / f)
    shutil.copy2(PROJ / "addons" / "notify" / "notify.gd",
                 dest / "addons" / "notify" / "notify.gd")
    for shared in ("ui", "fonts"):
        shutil.copytree(PROJ / "assets" / shared, dest / "assets" / shared,
                        ignore=shutil.ignore_patterns("*.uid"))
    # YOUR files, whole, under the game's res seat. THE MAPPING:
    #   <src>/<file>      -> res://game/games/<id>/<file>   (scripts + anything)
    #   <src>/assets/     -> res://assets/games/<id>/       (your art, the box's
    #                        res://assets/games/<id>/... literals resolve here)
    #   <src>/audio/      -> res://assets/audio/            (your music + sfx,
    #                        res://assets/audio/... literals resolve here)
    # game.json never enters the pack (it is the name file beside it).
    for p in src.rglob("*"):
        if not p.is_file() or p.name == "game.json":
            continue
        rel = p.relative_to(src)
        top = rel.parts[0]
        if top == "assets":
            out_rel = Path("assets") / "games" / gid / rel.relative_to("assets")
        elif top == "audio":
            out_rel = Path("assets") / "audio" / rel.relative_to("audio")
        else:
            out_rel = Path("game") / "games" / gid / rel
        out = dest / out_rel
        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(p, out)
    bridge_classes(dest / "game" / "games" / gid)
    if pre_audit is not None:
        pre_audit(dest)   # cross-game borrows land before the audit walks

    texts = [p.read_text(encoding="utf-8", errors="replace")
             for p in (dest / "game" / "games" / gid).rglob("*.gd")]
    blobs = "\n".join(texts)

    (dest / "project.godot").write_text(
        'config_version=5\n\n[application]\nconfig/name="goga_game"\n\n'
        "[autoload]\n"
        + "".join(f'{k}="*{v}"\n' for k, v in AUTOLOADS.items())
        + '\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
          "textures/vram_compression/import_etc2_astc=true\n",
        encoding="utf-8")
    (dest / "export_presets.cfg").write_text(
        '[preset.0]\n\nname="pack"\nplatform="Windows Desktop"\n'
        'runnable=true\nexport_filter="all_resources"\ninclude_filter=""\n'
        'exclude_filter="game/core/*,addons/*,assets/ui/*,assets/fonts/*"\n'
        'export_path=""\n\n[preset.0.options]\n',
        encoding="utf-8")

    # ---- THE AUDIT: every complete res:// file literal must exist in the
    # stage; box-project files are carried in automatically; audio is soft.
    have = set()
    for p in dest.rglob("*"):
        if p.is_file():
            have.add("res://" + str(p.relative_to(dest)))
    missing = set()
    for lit in sorted(set(RES_RE.findall(blobs))):
        if not AUDIT_FILE_RE.match(lit) or lit.endswith(".import"):
            continue
        if lit in have:
            continue
        rel = lit[len("res://"):]
        box_file = PROJ / rel
        if box_file.is_dir():
            out = dest / rel
            if not out.exists():
                shutil.copytree(box_file, out,
                                ignore=shutil.ignore_patterns("*.uid"))
            continue
        if box_file.exists():
            out = dest / rel
            out.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(box_file, out)
            continue
        if "/assets/audio/" in lit:
            continue   # the soft seat - the Jukebox resolves at call time
        missing.add(lit)
    if missing:
        raise SystemExit("AUDIT FAILED for %s - missing paths:\n  %s"
                         % (gid, "\n  ".join(sorted(missing))))
    return dest


def export_pack(staged: Path) -> Path:
    env = dict(os.environ)
    subprocess.run([str(GODOT), "--headless", "--path", str(staged), "--import"],
                   capture_output=True, text=True, timeout=900)
    # THE PACK CONTENTS LAW, second door: the autoload declarations force
    # their scripts into EVERY export (they bypass the exclude filter), and
    # a pack carrying res://game/core/store.gd etc. shadows the box's OWN
    # autoloads the moment it mounts. The import needed them (the class
    # cache + the game scripts compile against the real types); the export
    # does not - strip the block before packing.
    pg = staged / "project.godot"
    lines = pg.read_text(encoding="utf-8").splitlines(keepends=True)
    out, skip = [], False
    for ln in lines:
        if ln.strip() == "[autoload]":
            skip = True
            continue
        if skip and ln.startswith("["):
            skip = False
        if not skip:
            out.append(ln)
    pg.write_text("".join(out), encoding="utf-8")
    dest = staged / "game.pck"
    r = subprocess.run([str(GODOT), "--headless", "--path", str(staged),
                        "--export-pack", "pack", str(dest)],
                       capture_output=True, text=True, timeout=900)
    if not dest.exists():
        print(r.stdout[-3000:])
        print(r.stderr[-3000:])
        raise SystemExit("export-pack failed: %s" % staged.name)
    return dest


def assemble(src: Path, gid: str, pck: Path) -> Path:
    root = GOGAS / "games" / gid
    if root.exists():
        shutil.rmtree(root)
    root.mkdir(parents=True)
    shutil.copy2(pck, root / "game.pck")
    entry = read_json(src / "game.json")
    # the id IS the folder; the title lives in game.json
    entry.setdefault("title", gid.replace("_", " ").upper())
    entry.setdefault("script", "res://game/games/%s/entry.gd" % gid)
    entry.setdefault("thumb", "thumb.png")
    entry.setdefault("version", "1.0.0")
    for k, v in DEFAULTS.items():
        entry.setdefault(k, v)
    (root / "game.json").write_text(
        json.dumps(entry, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8")
    thumb = src / "thumb.png"
    if thumb.exists():
        shutil.copy2(thumb, root / "thumb.png")
    return root


def main() -> int:
    ap = argparse.ArgumentParser(description="build a GOGABox game folder")
    ap.add_argument("src", help="your game folder (entry.gd + game.json + assets)")
    ap.add_argument("--id", dest="gid", default="",
                    help="the game id (default: the folder's name)")
    args = ap.parse_args()
    src = Path(args.src).resolve()
    if not src.is_dir():
        raise SystemExit("not a folder: %s" % src)
    gid = re.sub(r'[^a-z0-9_]', '_', args.gid or src.name.lower())
    if not gid or gid[0].isdigit():
        gid = "g_" + gid
    scripts = list(src.rglob("*.gd"))
    if not scripts:
        raise SystemExit("no .gd script in %s - the game needs at least "
                         "entry.gd (extends GameBase)" % src)
    if not GODOT.exists():
        raise SystemExit("no godot at %s - run tools/bootstrap.sh" % GODOT)
    print("== make_game: %s (id: %s) ==" % (src, gid))
    staged = stage(src, gid)
    pck = export_pack(staged)
    root = assemble(src, gid, pck)
    shutil.rmtree(staged, ignore_errors=True)
    mb = (root / "game.pck").stat().st_size / 1e6
    print("   %s  (%.1f MB pack)" % (root, mb))
    print("   done - start GOGABox and the game is in the feed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
