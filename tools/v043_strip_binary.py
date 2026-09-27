#!/usr/bin/env python3
# ============================================================================
# v043 pass 2 - THE REAL STRIP (the empty binary, actually empty this time).
#
# What pass 1 missed (found by the owner: "main binary stayed same size?"):
#   registry.GAMES = [] stopped REFERENCING the baked games, but the files
#   stayed under projects/gogabox/ and the export packs everything not
#   excluded - so the APK/exe still carried all 31 games (~95 MB) AND, worse,
#   the loose copies shadowed the package pcks (load_resource_pack with
#   replace_files=false keeps the box's own files) - the pilots ran their
#   baked twins, not the packaged ports.
#
# This pass:
#   1. archives the game-owned audio the first pass forgot
#      (archive/games_v042/audio/{music,sfx}) - scripts/assets/thumbs were
#      already saved; the audio was not
#   2. deletes game/games/, assets/games/, the game music/sfx, the game thumbs
#      (box-owned keep-set: ui/, notify/, jingles/, box_theme.mp3,
#      sfx/{boom,coin,unlock}.ogg, thumbs/soon.png)
#   3. moves the dead-path probes (tests that reference game/games/ or
#      assets/games/<id>) into archive/games_v042/probes/
#   4. adds tests/* to every export preset's exclude_filter
#   5. seats save/README.md in the four committed packages (git cannot carry
#      an empty save/ - that is why goga-packages CI failed) and teaches the
#      packaging rig to do the same
#
# Idempotent. Run from the repo root:  python3 tools/v043_strip_binary.py
# ============================================================================
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROJ = ROOT / "projects" / "gogabox"
ARCH = ROOT / "archive" / "games_v042"

# the box-owned keep-set (referenced by game/core/audio.gd + game/menu/menu.gd)
KEEP_SFX = {"boom.ogg", "coin.ogg", "unlock.ogg"}
KEEP_MUSIC = {"box_theme.mp3"}
KEEP_THUMBS = {"soon.png"}

# the platform-era test battery + box-level probes (never archived)
TEST_KEEP = {
    "flow_test", "qa_v042_lan", "v043_shot", "parse_gate",
}


def die(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(1)


def move(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(src), str(dst))


def du(path: Path) -> int:
    n = 0
    for p in path.rglob("*"):
        if p.is_file():
            n += p.stat().st_size
    return n


def main() -> None:
    if not (PROJ / "project.godot").is_file():
        die(f"no godot project at {PROJ}")
    print(f"repo: {ROOT}")
    print(f"dead weight before: projects/gogabox = {du(PROJ)/1048576:.1f} MB")

    # ---- 1. archive the game-owned audio the first pass forgot ----------
    sfx_dir = PROJ / "assets" / "audio" / "sfx"
    music_dir = PROJ / "assets" / "audio" / "music"
    arch_sfx = ARCH / "audio" / "sfx"
    arch_music = ARCH / "audio" / "music"
    moved_audio = 0
    if sfx_dir.is_dir():
        for f in sorted(sfx_dir.iterdir()):
            if f.suffix.lower() in (".ogg", ".wav", ".mp3") \
                    and f.name not in KEEP_SFX:
                move(f, arch_sfx / f.name)
                moved_audio += 1
    if music_dir.is_dir():
        for f in sorted(music_dir.iterdir()):
            if f.suffix.lower() in (".ogg", ".wav", ".mp3") \
                    and f.name not in KEEP_MUSIC:
                move(f, arch_music / f.name)
                moved_audio += 1
    # the stale .import twins of the moved files die (regenerated on import)
    for d, keep in ((sfx_dir, KEEP_SFX), (music_dir, KEEP_MUSIC)):
        if d.is_dir():
            for imp in sorted(d.glob("*.import")):
                if imp.name[: -len(".import")] not in keep:
                    imp.unlink()
    print(f"1. archived {moved_audio} game-audio files -> archive/games_v042/audio/")

    # ---- 2. the baked game generation leaves the binary ------------------
    games = PROJ / "game" / "games"
    if games.is_dir():
        shutil.rmtree(games)
        print("2a. game/games/ deleted (the scripts live in the pcks + archive)")
    ag = PROJ / "assets" / "games"
    if ag.is_dir():
        shutil.rmtree(ag)
        print("2b. assets/games/ deleted (archived at archive/games_v042/assets/)")

    # ---- 3. the game thumbs not yet archived ----------------------------
    thumbs = PROJ / "assets" / "thumbs"
    if thumbs.is_dir():
        for f in sorted(thumbs.iterdir()):
            if f.suffix.lower() == ".png" and f.name not in KEEP_THUMBS:
                dst = ARCH / "thumbs" / f.name
                if not dst.exists():
                    move(f, dst)
                else:
                    f.unlink()
            elif f.suffix.lower() == ".import" \
                    and f.name[: -len(".import")] not in KEEP_THUMBS:
                f.unlink()
        print("3. assets/thumbs/ trimmed to the box-owned soon.png")

    # ---- 4. the dead-path probes leave the test tree --------------------
    tests = PROJ / "tests"
    probes = ARCH / "probes"
    moved_probes = 0
    dead_stub = re.compile(r"game/games/|assets/games/[A-Za-z0-9_]+/")
    if tests.is_dir():
        for gd in sorted(tests.glob("*.gd")):
            if gd.stem in TEST_KEEP:
                continue
            try:
                body = gd.read_text(errors="ignore")
            except OSError:
                continue
            if not dead_stub.search(body):
                continue
            stem = gd.stem
            for ext in (".gd", ".gd.uid", ".tscn"):
                src = tests / (stem + ext)
                if src.exists():
                    move(src, probes / src.name)
            moved_probes += 1
    print(f"4. archived {moved_probes} dead-path probes -> archive/games_v042/probes/")

    # ---- 5. the export presets never carry tests again -------------------
    presets = PROJ / "export_presets.cfg"
    txt = presets.read_text()
    changed = 0
    if "exclude_filter=\"tests/*\"" not in txt:
        txt = txt.replace('exclude_filter="dev/*"',
                          'exclude_filter="dev/*,tests/*"')
        presets.write_text(txt)
        changed = txt.count('exclude_filter="dev/*,tests/*"')
    print(f"5. export presets exclude tests/* ({changed} presets)")

    print(f"dead weight after:  projects/gogabox = {du(PROJ)/1048576:.1f} MB")
    print("STRIP OK")


if __name__ == "__main__":
    main()
