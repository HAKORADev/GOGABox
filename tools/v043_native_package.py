#!/usr/bin/env python3
"""v043 pass 3 - THE NATIVE PACKAGER: turn ANY folder holding a normal
game (a .exe, its data files) into a .goga package (the owner's order:
"try to find a delisted pc game, as example zuma deluxe ... then likely
download it from archive org and make a bundling/packaging for a native
normal game").

The native kind is the Steam model: the box LAUNCHES the game as a child
process and the game talks back over the SDK bridge (localhost:31442,
sdk/native/goga_sdk.h). The game itself needs zero changes - the bridge
is optional (a game that never links the SDK still runs; it just cannot
talk back).

Usage:
  python3 tools/v043_native_package.py \
      --id gogabox_github-<you>_zuma.deluxe.001_hobbyist \
      --title "ZUMA DELUXE" --tag "the PopCap classic" \
      --bin "game/pc/Zuma.exe" \
      --age 7 --desc "..." \
      [--source <folder with the game's files>] \
      [--out dist/zuma_deluxe.goga]

  - every file under --source lands under game/pc/ (or the layout the
    --bin path implies), the whole folder ships as-is
  - index/ + discover/ + data/ + save/ are generated around it (the
    strict validator's contract; the data minimums get honest seeded
    files - the game ignores them until a modder wires them)
  - the output is a .goga (zip) ready for IMPORT PACKAGE or a local
    GOGAs/games/ drop

THE LAW: only package games you legally own and may use. The platform's
line (MODDING.md): cracking not-ours and distribution-you-do-not-own are
the two doors that stay closed. A delisted game you bought still belongs
to its publisher - keep the package private.
"""
import argparse, hashlib, json, sys, zipfile
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

ABOUT = ("seeded by the native packager - the game ignores these until a "
         "modder wires them through the SDK/bridge; edit freely\n")

TINY_WAV = (b"RIFF$\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00"
            b"\x44\xac\x00\x00\x88X\x01\x00\x02\x00\x10\x00\x04\x00"
            b"data\x04\x00\x00\x00\x00\x00\x00\x00")
TINY_PNG = bytes.fromhex(
        "89504e470d0a1a0a0000000d4948445200000001000000010806000000"
        "1f15c4890000000d49444154789c6260f8cfc000000301010018dd8d"
        "b00000000049454e44ae426082")
SHADER = ('shader_type canvas_item;\n// seeded by the native packager\n'
          'void fragment() {\n\tfloat d = distance(UV, vec2(0.5));\n'
          '\tCOLOR = vec4(0.0, 0.0, 0.0, smoothstep(0.55, 0.95, d) * 0.35);\n}\n')


def sha1(p: Path) -> str:
    return hashlib.sha1(p.read_bytes()).hexdigest()


def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--id", required=True,
                    help="the long id: gogabox_github-<user>_<ns>.<name>.<n>_<tier>")
    ap.add_argument("--title", required=True)
    ap.add_argument("--tag", default="a native game in the box")
    ap.add_argument("--desc", default="A native game packaged for GOGABox.")
    ap.add_argument("--bin", required=True,
                    help="where the game's binary lands inside the package, "
                         "e.g. game/pc/Zuma.exe (its folder tree ships as-is)")
    ap.add_argument("--age", type=int, default=7)
    ap.add_argument("--source", required=True,
                    help="the folder holding the game's own files (copied "
                         "WHOLE under the bin's directory)")
    ap.add_argument("--out", required=True, help="the .goga to write")
    ap.add_argument("--orientation", default="landscape",
                    choices=["landscape", "portrait"])
    return ap.parse_args()


def validate_id(pid: str) -> str:
    ok = (pid.startswith("gogabox_github-") and pid.count("_") >= 2
          and pid.rsplit("_", 1)[1] in ("official", "community", "hobbyist"))
    if not ok:
        raise SystemExit("the id must wear gogabox_github-<user>_<ns>.<name>.<n>_<tier>")
    return pid


def main() -> int:
    a = parse_args()
    pkg_id = validate_id(a.id)
    bin_rel = a.bin.strip("/")
    if not bin_rel.startswith("game/"):
        raise SystemExit("--bin must land under game/ (e.g. game/pc/Zuma.exe)")
    src = Path(a.source).resolve()
    if not src.is_dir():
        raise SystemExit(f"no source folder: {src}")

    build = ROOT / "packaging" / ".build" / "native" / Path(pkg_id).name
    if build.exists():
        import shutil
        shutil.rmtree(build)
    pkg = build / pkg_id
    bin_dir = pkg / Path(bin_rel).parent
    bin_dir.mkdir(parents=True, exist_ok=True)
    if not (pkg / "index").exists():
        (pkg / "index").mkdir(parents=True)

    # ---- the game's own files, whole, under the bin's folder ----
    import shutil
    for item in src.rglob("*"):
        rel = item.relative_to(src)
        if item.is_dir():
            continue
        dest = bin_dir / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(item, dest)
    if not (pkg / bin_rel).exists():
        raise SystemExit(f"the binary did not arrive: {bin_rel}")

    # ---- the contract around it ----
    (pkg / "save").mkdir(exist_ok=True)
    (pkg / "save" / "README.md").write_text(
        "# save/ - the portable save seat\n\n"
        "A native game's saves land here through the SDK bridge "
        "(goga_save_write - libs/clients/<client>/ for standalone doors) "
        "or beside the exe when the game is old-school. Carried with the "
        "package, never in app-data bloat.\n", encoding="utf-8")
    for d in ["data/logic", "data/audio/sfx", "data/audio/music",
              "data/visuals/shaders", "data/visuals/assets"]:
        (pkg / d).mkdir(parents=True, exist_ok=True)
    (pkg / "data" / "logic" / "native_seed.json").write_text(json.dumps({
        "_about": ABOUT, "table": {"note": "wire me through the bridge"}},
        indent=2) + "\n", encoding="utf-8")
    (pkg / "data" / "audio" / "sfx" / "seed.wav").write_bytes(TINY_WAV)
    (pkg / "data" / "audio" / "music" / "seed.wav").write_bytes(TINY_WAV)
    (pkg / "data" / "visuals" / "shaders" / "vignette.gdshader").write_text(SHADER)
    (pkg / "data" / "visuals" / "assets" / "seed.png").write_bytes(TINY_PNG)
    (pkg / "discover" / "media").mkdir(parents=True, exist_ok=True)
    (pkg / "discover" / "media" / "thumb.png").write_bytes(TINY_PNG)

    files = [{"path": f.relative_to(pkg).as_posix(), "sha256": sha1(f)}
             for f in sorted(pkg.rglob("*")) if f.is_file()]
    size = sum(f.stat().st_size for f in pkg.rglob("*") if f.is_file())
    entry = {
        "schema": 1,
        "id": pkg_id,
        "game_id": pkg_id.rsplit("_", 1)[0].rsplit(".", 2)[-2].lower()
                   .replace("-", "_"),
        "title": a.title,
        "tag": a.tag,
        "version": "1.0.0",
        "age": max(3, a.age),
        "content": [],
        "genres": {"main": ["arcade"], "sub": []},
        "os": ["pc"],
        "runs": {
            "pc": {"kind": "native", "bin": bin_rel,
                   "renderer": "native_window"},
        },
        "orientation": a.orientation,
        "thumb": "discover/media/thumb.png",
        "desc": a.desc,
        "fee": 0, "price": 0, "coin_div": 10,
        "updated": date.today().isoformat(),
        "versions_count": 1,
        "size_bytes": size,
        "files": files,
    }
    (pkg / "index" / "index.json").write_text(
        json.dumps(entry, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (pkg / "index" / "versions.json").write_text(json.dumps({
        "schema": 1,
        "versions": [{"version": "1.0.0", "updated": date.today().isoformat(),
                      "notes": f"{a.title} packaged by tools/v043_native_package.py"}],
    }, indent=2) + "\n", encoding="utf-8")
    (pkg / "discover" / "page.json").write_text(json.dumps({
        "title": a.title, "desc": a.desc,
        "media": [{"kind": "thumb", "file": "media/thumb.png"}],
        "entry": {"fee": 0, "price": 0},
    }, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    # ---- the .goga (zip; one root inside) ----
    out = Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for f in sorted(pkg.rglob("*")):
            if f.is_file():
                z.write(f, Path(pkg_id) / f.relative_to(pkg).as_posix())
    print(f"native package: {out} ({out.stat().st_size} bytes zipped)")
    print(f"  game_id: {entry['game_id']}  bin: {bin_rel}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
