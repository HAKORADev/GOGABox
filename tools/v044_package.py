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
    # the game's assets, 1:1 res paths (code-drawn games have none)
    game_assets = ARCH / "assets" / gid
    if game_assets.exists():
        shutil.copytree(game_assets, dest / "assets" / "games" / gid)
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
    thumb = ARCH / "thumbs" / f"{gid}.png"
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
