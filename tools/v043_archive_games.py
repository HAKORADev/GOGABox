#!/usr/bin/env python3
"""v043 THE ARCHIVE TOOL - save the original current games in the repo somewhere.

The owner's order: "save the original current games in the repo somewhere,
then develop the full sdk..." - the binary goes EMPTY (zero baked games)
and every v042-era game lands in archive/games_v042/, whole and revivable:
  - scripts/           the exact game .gd sources (one folder per id)
  - assets/            the exact per-game asset folders
  - thumbs/            the exact thumbnails
  - registry_entries/  each game's registry dict as JSON (revival seed)
  - README.md          the mapping + the revival recipe
Git history keeps everything too - this folder makes the split FINDABLE.
"""
import json, re, shutil, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJ = ROOT / "projects" / "gogabox"
ARCH = ROOT / "archive" / "games_v042"

def main() -> int:
    reg = PROJ / "game" / "core" / "registry.gd"
    text = reg.read_text(encoding="utf-8")
    # carve the GAMES const body: from 'const GAMES := [' to the line ']' at
    # column 0 that closes it (the file wears one such const).
    start = text.index("const GAMES := [")
    body_start = text.index("[", start)
    # the const closes with ']' at COLUMN 0 ('\n]\n'); entry-internal ']'
    # closers are always indented, so the column-0 match is unambiguous.
    end = text.index("\n]\n", body_start)
    body = text[body_start:end + 2]
    entries = parse_entries(body)
    print(f"parsed {len(entries)} registry entries")
    if len(entries) < 20:
        print("ERROR: expected the full v042 registry (25 games), aborting")
        return 1

    (ARCH / "scripts").mkdir(parents=True, exist_ok=True)
    (ARCH / "assets").mkdir(parents=True, exist_ok=True)
    (ARCH / "thumbs").mkdir(parents=True, exist_ok=True)
    (ARCH / "registry_entries").mkdir(parents=True, exist_ok=True)

    moved = []
    for e in entries:
        gid = e["id"]
        (ARCH / "registry_entries" / f"{gid}.json").write_text(
                json.dumps(e, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        # the script(s): the entry's "script" res path lives in
        # projects/gogabox/game/games/<id>/
        src_dir = PROJ / "game" / "games" / gid
        if src_dir.exists():
            dst = ARCH / "scripts" / gid
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(src_dir, dst,
                            ignore=shutil.ignore_patterns("*.uid"))
        # per-game assets
        a_dir = PROJ / "assets" / "games" / gid
        if a_dir.exists():
            dst = ARCH / "assets" / gid
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(a_dir, dst,
                            ignore=shutil.ignore_patterns("*.import", "*.uid"))
        # thumbnail (the entry's own path wins; the id match is the fallback)
        thumb = (PROJ / "assets" / "thumbs" / f"{gid}.png")
        if thumb.exists():
            shutil.copy2(thumb, ARCH / "thumbs" / f"{gid}.png")
        moved.append(gid)
    print(f"archived {len(moved)} games: {' '.join(moved)}")
    return 0

def parse_entries(body: str):
    """Walk the GDScript dict-literal array and balance-brace each entry."""
    entries = []
    depth = 0
    cur = ""
    in_str = False
    esc = False
    i = 0
    while i < len(body):
        ch = body[i]
        if in_str:
            cur += ch
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
            i += 1
            continue
        if ch == '"':
            in_str = True
            cur += ch
        elif ch == "#":
            # a comment outside a string: skip the whole line (a comment
            # carrying quotes or braces would desync the balancer)
            while i < len(body) and body[i] != "\n":
                i += 1
            continue
        elif ch == "{":
            depth += 1
            cur += ch
        elif ch == "}":
            depth -= 1
            cur += ch
            if depth == 0:
                try:
                    entries.append(gd_to_json(cur))
                except json.JSONDecodeError as e:
                    head = cur[:400].replace("\n", " | ")
                    raise SystemExit(
                            f"ENTRY #{len(entries)} ({head}...) failed: {e}")
                cur = ""
        elif depth == 0:
            pass  # commas/whitespace between entries
        else:
            cur += ch
        i += 1
    return entries

def gd_to_json(s: str):
    """One registry dict literal (with GDScript comments) -> python dict.

    v043 note: the old regex-ify approach rewrote 'comma word colon'
    patterns INSIDE strings ("cooker, rebuilt: ...") and died - this is a
    real string-aware tokenizer instead.
    """
    val, idx = _parse_value(s, _skip_ws(s, 0))
    return val

def _skip_ws(s: str, i: int) -> int:
    n = len(s)
    while i < n:
        ch = s[i]
        if ch in " \t\r\n,":
            i += 1
        elif ch == "#":
            while i < n and s[i] != "\n":
                i += 1
        else:
            break
    return i

def _parse_string(s: str, i: int):
    # s[i] == '"'
    i += 1
    out = []
    while i < len(s):
        ch = s[i]
        if ch == "\\":
            nxt = s[i + 1] if i + 1 < len(s) else ""
            out.append({"n": "\n", "t": "\t", "r": "\r", '"': '"',
                        "\\": "\\", "'": "'"}.get(nxt, nxt))
            i += 2
            continue
        if ch == '"':
            return "".join(out), i + 1
        out.append(ch)
        i += 1
    raise ValueError("unterminated string")

def _parse_value(s: str, i: int):
    i = _skip_ws(s, i)
    ch = s[i]
    if ch == "{":
        i += 1
        obj = {}
        while True:
            i = _skip_ws(s, i)
            if s[i] == "}":
                return obj, i + 1
            # the key: bare GDScript identifier or a quoted string
            if s[i] == '"':
                key, i = _parse_string(s, i)
            else:
                j = i
                while i < len(s) and (s[i].isalnum() or s[i] == "_"):
                    i += 1
                key = s[j:i]
            i = _skip_ws(s, i)
            if i < len(s) and s[i] == "=" and s[i + 1] == "=":
                i += 2   # GDScript dict allows ':=' too
            i = _skip_ws(s, i)
            if i < len(s) and s[i] == ":":
                i += 1
            val, i = _parse_value(s, i)
            obj[key] = val
    if ch == "[":
        i += 1
        arr = []
        while True:
            i = _skip_ws(s, i)
            if s[i] == "]":
                return arr, i + 1
            val, i = _parse_value(s, i)
            arr.append(val)
    if ch == '"':
        return _parse_string(s, i)
    j = i
    while i < len(s) and s[i] not in ",}]\n#":
        i += 1
    tok = s[j:i].strip()
    if tok in ("true", "false"):
        return tok == "true", i
    if tok in ("null",):
        return None, i
    try:
        return int(tok), i
    except ValueError:
        pass
    try:
        return float(tok), i
    except ValueError:
        return tok, i

if __name__ == "__main__":
    sys.exit(main())
