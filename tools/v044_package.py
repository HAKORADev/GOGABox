#!/usr/bin/env python3
"""v044 THE PACKER - every archived game becomes a GAME FOLDER.

    GOGAs/games/<id>/   folder = the game's id
      game.json         the name file (the archive's exact registry entry
                        minus the machinery, plus os/age/content truth)
      game.pck          THE ONE ENTRY - one platform-neutral pack per game
      thumb.png         the tile art

The staging rig (the pck law, unchanged from v043): the box core copies at
the SAME res://game/core/ paths so the compiled base-class references
resolve to the box's real classes at runtime (replace_files=false skips the
pack's core copies), the game's scripts + assets at their original res
paths, one headless import, one export-pack.

Audio: the game's own music + sfx ride the pack - every res://assets/audio
literal in the game's scripts plus every bare string literal that names an
archived audio stem. The Jukebox resolves mounted-pack audio at call time.

An AUDIT walks every res:// literal in the staged scripts: anything missing
from the stage is copied from the box project when it exists there, and a
missing path aborts the build by name - a pack never ships half-referenced.
"""
import json, os, re, shutil, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJ = ROOT / "projects" / "gogabox"
ARCH = ROOT / "archive" / "games_v042"
BUILD = ROOT / "packaging" / ".build"
GOGAS = ROOT / "GOGAs"
GODOT = ROOT / ".cache" / "godot" / "bin" / "godot"

# the v044 platform truth (the owner's port list + the age decisions)
OVERRIDES = {
    "domino": {"os": ["pc"]},
    "jumpcube": {"os": ["android"]},
    "rally": {"age": 7},
    "slasher": {"age": 7},
}

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
STR_RE = re.compile(r'"([^"\n]{1,80})"')


def scripts_of(gid: str):
    d = ARCH / "scripts" / gid
    return sorted(p for p in d.glob("*.gd"))


CLASS_RE = re.compile(r'^class_name\s+(\w+)', re.M)
WORD_RE = re.compile(r'\b([A-Z]\w+)\b')


def bridge_game_classes(game_dir: Path) -> None:
    """THE CLASS BRIDGE (v044): a pack's class_names never reach the box's
    global class cache, so `var meta: DWMeta` in a mounted script degrades
    to Variant and every `:=` inference on it dies at parse time (the
    deathworm class of failures - invisible in v043 because the pilots were
    single-script games). The bridge is mechanical: every script that names
    a sibling class gets a local `const C := preload("<path>")` - the const
    is a real type in annotations, expressions and .new() calls, with zero
    hand edits to the game's code."""
    files = sorted(game_dir.glob("*.gd"))
    classes: dict = {}
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
                # THE DECLARER: the box runtime cannot resolve the script's
                # own class_name either - the static self-factory goes
                # untyped and constructs through new(); the declarer's own
                # factory call sites drop the := inference (an untyped
                # return can never feed :=)
                txt = re.sub(r'static func (\w+)\(\) -> %s:' % cname,
                             r'static func \1():', txt)
                txt = re.sub(r'var (\w+) := %s\.new\(\)' % cname,
                             r'var \1 := new()', txt)
                txt = re.sub(r'var (\w+) := load_meta\(\)',
                             r'var \1 = load_meta()', txt)
                txt = re.sub(r'var (\w+) := _load_meta\(\)',
                             r'var \1 = _load_meta()', txt)
                continue
            body = CLASS_RE.sub("", txt, count=1)
            if not re.search(r'\b%s\b' % re.escape(cname), body):
                continue
            # rel from the STAGING ROOT (res://game/games/<gid>/<file>.gd)
            rel = "res://" + cfile.relative_to(
                    game_dir.parents[2]).as_posix()
            need.append((cname, rel))
        if not need and txt == orig:
            continue
        if need:
            lines = txt.split("\n")
            insert_at = 0
            for i, ln in enumerate(lines):
                if ln.startswith("class_name "):
                    insert_at = i + 1
                    continue   # keep scanning: extends usually follows
                if ln.startswith("extends "):
                    insert_at = i + 1
                    break
                if ln.strip() == "" and i < 4:
                    continue
                break
            # a header comment marks the bridge (never silent magic)
            block = ["# v044 THE CLASS BRIDGE: the pack's classes are not in the",
                     "# box's global cache - these consts carry them locally."]
            for cname, rel in need:
                block.append('const %s := preload("%s")' % (cname, rel))
            lines[insert_at:insert_at] = block
            txt = "\n".join(lines)
        f.write_text(txt, encoding="utf-8")


def archive_audio_stems() -> dict:
    """stem -> relative path under archive/games_v042/audio/."""
    out = {}
    for kind in ("music", "sfx"):
        for p in (ARCH / "audio" / kind).iterdir():
            out[p.stem] = str(p.relative_to(ARCH / "audio"))
    return out


def stage(gid: str, audio_stems: dict) -> Path:
    dest = BUILD / gid
    if dest.exists():
        shutil.rmtree(dest)
    (dest / "game" / "core").mkdir(parents=True)
    (dest / "game" / "games" / gid).mkdir(parents=True)
    (dest / "addons" / "notify").mkdir(parents=True)
    # the box core, verbatim, SAME res paths (the pck law)
    for f in CORE_FILES:
        shutil.copy2(PROJ / "game" / "core" / f, dest / "game" / "core" / f)
    shutil.copy2(PROJ / "addons" / "notify" / "notify.gd",
                 dest / "addons" / "notify" / "notify.gd")
    # the game's scripts, original paths
    for src in scripts_of(gid):
        shutil.copy2(src, dest / "game" / "games" / gid / src.name)
    bridge_game_classes(dest / "game" / "games" / gid)
    # the game's assets, 1:1 res paths (code-drawn games have none)
    game_assets = ARCH / "assets" / gid
    if game_assets.exists():
        shutil.copytree(game_assets, dest / "assets" / "games" / gid)
    # CROSS-GAME ASSET BORROWS (invaders wears lanes' ships and stars):
    # any literal naming another game's asset folder drags that folder in
    blobs0 = "\n".join(p.read_text(encoding="utf-8", errors="replace")
                       for p in scripts_of(gid))
    for other in set(re.findall(r'res://assets/games/([a-z0-9_]+)/', blobs0)):
        if other == gid:
            continue
        src_other = ARCH / "assets" / other
        if src_other.exists():
            shutil.copytree(src_other, dest / "assets" / "games" / other)
    # the shared UI + fonts the core draws with
    for shared in ("ui", "fonts"):
        d = PROJ / "assets" / shared
        shutil.copytree(d, dest / "assets" / shared,
                        ignore=shutil.ignore_patterns("*.uid"))
    # the game's own audio: res:// refs + bare stems named in the scripts
    texts = [p.read_text(encoding="utf-8", errors="replace")
             for p in scripts_of(gid)]
    blobs = "\n".join(texts)
    wanted = set()
    for m in RES_RE.finditer(blobs):
        lit = m.group(0)
        if "/assets/audio/" in lit:
            rel = lit.split("/assets/audio/", 1)[1]
            wanted.add(rel)
    for m in STR_RE.finditer(blobs):
        stem = m.group(1)
        if stem in audio_stems:
            wanted.add(audio_stems[stem])
    for rel in sorted(wanted):
        src = ARCH / "audio" / rel
        if not src.is_file():
            continue   # the box keep-set serves the shared names
        out = dest / "assets" / "audio" / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, out)
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
        'exclude_filter=""\nexport_path=""\n\n[preset.0.options]\n',
        encoding="utf-8")

    # ---- THE AUDIT: every res:// literal that names a COMPLETE file path
    # must exist in the stage (dynamic prefixes like ".../phone_" + name are
    # not files - they resolve at runtime against the box or the pack).
    FILE_RE = re.compile(
        r'res://[A-Za-z0-9_\-\.\/]+\.(png|ogg|wav|mp3|ttf|gdshader|gd|svg|json|txt|import)$')
    have = set()
    for p in dest.rglob("*"):
        if p.is_file():
            have.add("res://" + str(p.relative_to(dest)))
    missing = set()
    for lit in sorted(set(RES_RE.findall(blobs))):
        if not FILE_RE.match(lit):
            continue
        if lit in have:
            continue
        if lit.endswith(".import"):
            continue
        # a box-project file or folder? copy it into the stage and move on
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
        # an archived game's file (a cross-game borrow - brickbreaker wears
        # geometry's shader, marble wears geometry's glow)? the archive
        # carries game scripts AND game assets at the same res paths
        m = re.match(r"game/games/([a-z0-9_]+)/(.+)$", rel)
        if m:
            arch_file = ARCH / "scripts" / m.group(1) / m.group(2)
            if arch_file.exists():
                out = dest / rel
                out.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(arch_file, out)
                continue
        m = re.match(r"assets/games/([a-z0-9_]+)/(.+)$", rel)
        if m:
            arch_file = ARCH / "assets" / m.group(1) / m.group(2)
            if arch_file.exists():
                out = dest / rel
                out.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(arch_file, out)
                continue
        # the game's own audio is SOFT: a missing file is an honest no-op
        # (the Jukebox resolves at call time; games carry their own
        # fallbacks) - never a hard failure
        if "/assets/audio/" in lit:
            continue
        missing.add(lit)
    if missing:
        raise SystemExit("AUDIT FAILED for %s - missing paths:\n  %s"
                         % (gid, "\n  ".join(sorted(missing))))
    return dest


def export_pack(staged: Path) -> Path:
    env = dict(os.environ)
    subprocess.run([str(GODOT), "--headless", "--path", str(staged), "--import"],
                   capture_output=True, text=True, timeout=900)
    dest = staged / "game.pck"
    r = subprocess.run([str(GODOT), "--headless", "--path", str(staged),
                        "--export-pack", "pack", str(dest)],
                       capture_output=True, text=True, timeout=900)
    if not dest.exists():
        print(r.stdout[-3000:])
        print(r.stderr[-3000:])
        raise SystemExit("export-pack failed: %s" % staged.name)
    return dest


def thumb_of(gid: str) -> Path:
    """the archive's thumb for a game - the registry entry names it (the
    historical names wander: cosmic_spud's tile lives at spud.png)."""
    reg = json.loads((ARCH / "registry_entries" / f"{gid}.json")
                     .read_text(encoding="utf-8"))
    t = reg.get("thumb", "")
    if t:
        name = Path(t).name
        p = ARCH / "thumbs" / name
        if p.exists():
            return p
    return ARCH / "thumbs" / f"{gid}.png"


def assemble(gid: str, pck: Path) -> Path:
    root = GOGAS / "games" / gid
    if root.exists():
        shutil.rmtree(root)
    root.mkdir(parents=True)
    shutil.copy2(pck, root / "game.pck")
    entry = json.loads((ARCH / "registry_entries" / f"{gid}.json")
                       .read_text(encoding="utf-8"))
    entry.pop("id", None)
    entry["script"] = "res://game/games/%s/%s.gd" % (gid, entry_script(gid))
    entry["thumb"] = "thumb.png"
    entry["version"] = "1.0.0"
    entry.setdefault("age", 3)
    entry.setdefault("content", [])
    entry.setdefault("os", ["android", "pc"])
    for k, v in OVERRIDES.get(gid, {}).items():
        entry[k] = v
    (root / "game.json").write_text(
        json.dumps(entry, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8")
    thumb = thumb_of(gid)
    if thumb.exists():
        shutil.copy2(thumb, root / "thumb.png")
    return root


def entry_script(gid: str) -> str:
    """the game's main script name (rally's main script is pong.gd)."""
    reg = json.loads((ARCH / "registry_entries" / f"{gid}.json")
                     .read_text(encoding="utf-8"))
    return Path(reg.get("script", "res://game/games/%s/%s.gd" % (gid, gid))
                ).stem


def main() -> int:
    which = sys.argv[1:]
    all_ids = sorted(p.name for p in (ARCH / "scripts").iterdir()
                     if p.is_dir())
    if which:
        # allow "all"
        ids = all_ids if which == ["all"] else which
    else:
        ids = all_ids
    if not GODOT.exists():
        raise SystemExit("no godot at %s - run tools/bootstrap.sh" % GODOT)
    # the old platform-era tree dies here (the pilots, the discover catalog)
    for old in (GOGAS / "games").glob("gogabox_github-*"):
        shutil.rmtree(old)
    if (GOGAS / "discover").exists():
        shutil.rmtree(GOGAS / "discover")
    BUILD.mkdir(parents=True, exist_ok=True)
    audio_stems = archive_audio_stems()
    for gid in ids:
        if not (ARCH / "scripts" / gid).is_dir():
            raise SystemExit("no archived scripts for '%s'" % gid)
        print("== packaging %s ==" % gid)
        staged = stage(gid, audio_stems)
        pck = export_pack(staged)
        root = assemble(gid, pck)
        mb = (root / "game.pck").stat().st_size / 1e6
        print("   %s  (%.1f MB pack)" % (root, mb))
    return 0


if __name__ == "__main__":
    sys.exit(main())
