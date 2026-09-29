#!/usr/bin/env python3
"""rebuild_gogas - ONE-OFF (v044-1 THE PACK CONTENTS LAW).

The v044 packs carried staged copies of the box's core. PackedData
outranks the real files once a pack mounts, so a pack with the core
inside SHADOWS the box's own code for the whole session - the box's own
laws could silently never run inside its own games. The packs are
rebuilt now carrying ONLY the game's files (scripts, assets, audio);
the box provides the core.

Sources: git HEAD still holds archive/games_v042 (the deletion is not
committed) - the scripts, assets and audio come from there, the name
files (game.json) and thumbs come from the CURRENT GOGAs tree (they
carry the v044 os/age/reveal truth).
"""
import json, re, shutil, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import make_game as MG

GOGAS = ROOT / "GOGAs"
ARCHIVE = Path("/tmp/goga_src/archive/games_v042")
WORK = Path("/tmp/rebuild_src")

RES_RE = re.compile(r'res://[A-Za-z0-9_\-\.\/]+')
STR_RE = re.compile(r'"([^"\n]{1,80})"')


def audio_stems() -> dict:
    out = {}
    for kind in ("music", "sfx"):
        d = ARCHIVE / "audio" / kind
        if d.is_dir():
            for p in d.iterdir():
                out[p.stem] = str(p.relative_to(ARCHIVE / "audio"))
    return out


def build_src(gid: str, stems: dict) -> Path:
    src = WORK / gid
    if src.exists():
        shutil.rmtree(src)
    src.mkdir(parents=True)
    # the name file + thumb ride from the CURRENT tree (the v044 truth)
    cur = GOGAS / "games" / gid
    shutil.copy2(cur / "game.json", src / "game.json")
    if (cur / "thumb.png").exists():
        shutil.copy2(cur / "thumb.png", src / "thumb.png")
    # scripts at the src root -> res://game/games/<id>/
    for p in (ARCHIVE / "scripts" / gid).glob("*.gd"):
        shutil.copy2(p, src / p.name)
    # the game's own assets -> res://assets/games/<id>/
    ga = ARCHIVE / "assets" / gid
    if ga.is_dir():
        shutil.copytree(ga, src / "assets")
    # audio: res://assets/audio literals + bare stems named in the scripts
    texts = [p.read_text(encoding="utf-8", errors="replace")
             for p in src.glob("*.gd")]
    blobs = "\n".join(texts)
    wanted = set()
    for m in RES_RE.finditer(blobs):
        lit = m.group(0)
        if "/assets/audio/" in lit:
            wanted.add(lit.split("/assets/audio/", 1)[1])
    for m in STR_RE.finditer(blobs):
        stem = m.group(1)
        if stem in stems:
            wanted.add(stems[stem])
    for rel in sorted(wanted):
        s = ARCHIVE / "audio" / rel
        if s.is_file():
            out = src / "audio" / rel
            out.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(s, out)
    return src


def stage_borrows(dest: Path, gid: str) -> None:
    """Cross-game asset borrows (invaders wears lanes' ships) AND a game's
    own files that live outside the two mapped seats (geometry keeps its
    shaders at res://game/games/geometry/fx/): any missing res literal
    naming a game seat pulls the file from the archive to the SAME path.
    Everything lands under the game seats - nothing of the box's."""
    blobs = "\n".join(p.read_text(encoding="utf-8", errors="replace")
                      for p in (dest / "game" / "games" / gid).rglob("*.gd"))
    for lit in sorted(set(RES_RE.findall(blobs))):
        m = re.match(r'res://(game/games/([a-z0-9_]+)/([A-Za-z0-9_\-\.\/]+))$', lit)
        if m:
            name = m.group(3)
            if (dest / m.group(1)).exists():
                continue
            for base in (ARCHIVE / "assets" / m.group(2),
                         ARCHIVE / "scripts" / m.group(2)):
                s = base / name
                if s.is_file():
                    out = dest / m.group(1)
                    out.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(s, out)
                    break
            continue
        m = re.match(r'res://(assets/games/([a-z0-9_]+)/([A-Za-z0-9_\-\.\/]+))$', lit)
        if m:
            if (dest / m.group(1)).exists():
                continue
            s = ARCHIVE / "assets" / m.group(2) / m.group(3)
            if s.is_file():
                out = dest / m.group(1)
                out.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(s, out)


def main() -> int:
    ids = sorted(p.name for p in (GOGAS / "games").iterdir() if p.is_dir())
    if len(sys.argv) > 1:
        ids = sys.argv[1:]
    subprocess.run(["git", "archive", "HEAD", "archive/games_v042"], cwd=ROOT,
                   check=True, stdout=open("/tmp/goga_src.tar", "wb"))
    shutil.rmtree("/tmp/goga_src", ignore_errors=True)
    Path("/tmp/goga_src").mkdir(parents=True)
    subprocess.run(["tar", "xf", "/tmp/goga_src.tar", "-C", "/tmp/goga_src"],
                   check=True)
    WORK.mkdir(parents=True, exist_ok=True)
    if not MG.GODOT.exists():
        raise SystemExit("no godot - run tools/bootstrap.sh")
    stems = audio_stems()
    total_before = total_after = 0
    for gid in ids:
        old = (GOGAS / "games" / gid / "game.pck").stat().st_size
        src = build_src(gid, stems)
        staged = MG.stage(src, gid, pre_audit=lambda dest: stage_borrows(dest, gid))
        pck = MG.export_pack(staged)
        root = MG.assemble(src, gid, pck)
        shutil.rmtree(staged, ignore_errors=True)
        new = (root / "game.pck").stat().st_size
        total_before += old
        total_after += new
        print("   %-16s %6.1f MB -> %6.1f MB" %
              (gid, old / 1e6, new / 1e6))
    print("TOTAL: %.1f MB -> %.1f MB" % (total_before / 1e6, total_after / 1e6))
    return 0


if __name__ == "__main__":
    sys.exit(main())
