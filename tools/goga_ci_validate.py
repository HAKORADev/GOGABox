#!/usr/bin/env python3
"""goga CI: validate the REPOS.txt registry + the committed GOGAs tree.

Used by .github/workflows/goga-registry.yml (the two-step publish: a PR
adds one repo line, this script fetches the repo's raw source.json +
game indexes and refuses anything that does not wear the contract) and
by goga-packages.yml (the committed packages must keep validating).

The strict law mirrors the box's validator (game/core/goga_core.gd) -
the local flow IS the remote flow, the CI is the same contract on a
different machine.
"""
import json, sys, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = "https://raw.githubusercontent.com"
OFFICIAL = ["HAKORADev/GOGABox"]
TIERS = {"official", "community", "hobbyist"}
DATA_MIN = ["data/logic", "data/audio/sfx", "data/audio/music",
            "data/visuals/shaders", "data/visuals/assets"]
REQ_INDEX = ["id", "game_id", "title", "version", "age", "genres", "os",
             "runs", "thumb"]

def fetch(url: str, timeout: int = 30):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "GOGABox-CI"})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.loads(r.read().decode("utf-8"))
    except Exception as e:
        return {"__err__": str(e)}

def parse_id(pid: str):
    s = str(pid)
    if not s.startswith("gogabox_github-"):
        return None
    rest = s[len("gogabox_github-"):]
    if "_" not in rest:
        return None
    tier = rest.rsplit("_", 1)[1]
    if tier not in TIERS:
        return None
    head = rest.rsplit("_", 1)[0]
    if "_" not in head:
        return None
    user, slug = head.split("_", 1)
    if not user or not slug or "." not in slug:
        return None
    return {"user": user, "slug": slug, "tier": tier}

def validate_game_index(idx: dict, source_repo: str):
    errs = []
    for k in REQ_INDEX:
        if k not in idx:
            errs.append(f"index misses \"{k}\"")
    pid = parse_id(idx.get("id", ""))
    if pid is None:
        errs.append(f"the id \"{idx.get('id')}\" does not wear the scheme")
    if not idx.get("game_id"):
        errs.append("no game_id (the box's short key)")
    runs = idx.get("runs") or {}
    if not runs:
        errs.append("runs is empty")
    for plat, r in runs.items():
        kind = r.get("kind", "godot_embedded")
        if kind not in ("godot_embedded", "native", "web"):
            errs.append(f"runs.{plat}: unknown kind {kind}")
        key = {"godot_embedded": "pck", "native": "bin", "web": "entry"}[kind]
        if not r.get(key):
            errs.append(f"runs.{plat}: no {key}")
    if not idx.get("files"):
        errs.append("no files manifest (the downloader fetches through it)")
    return errs

def validate_repo(repo: str, branch="main"):
    """fetch + validate one source repo; returns (errors, game_count)"""
    src = fetch(f"{RAW}/{repo}/{branch}/GOGAs/discover/index/source.json")
    if "__err__" in src:
        return [f"source.json: {src['__err__']}"], 0
    errs = []
    games = src.get("games", [])
    for g in games:
        rel = g.get("index", "")
        if not rel:
            errs.append("a games[] entry without its index path")
            continue
        idx = fetch(f"{RAW}/{repo}/{branch}/{rel}")
        if "__err__" in idx:
            errs.append(f"{rel}: {idx['__err__']}")
            continue
        for e in validate_game_index(idx, repo):
            errs.append(f"{rel}: {e}")
    return errs, len(games)

def validate_local_tree():
    """the committed GOGAs/ tree keeps wearing the contract"""
    errs = []
    games_root = ROOT / "GOGAs" / "games"
    if not games_root.exists():
        return ["the repo carries no GOGAs/games tree"]
    n = 0
    for pkg in sorted(games_root.glob("gogabox_github-*")):
        n += 1
        idx_path = pkg / "index" / "index.json"
        if not idx_path.exists():
            errs.append(f"{pkg.name}: no index/index.json")
            continue
        idx = json.loads(idx_path.read_text(encoding="utf-8"))
        for e in validate_game_index(idx, "local"):
            errs.append(f"{pkg.name}: {e}")
        # the files manifest: every listed file exists
        for f in idx.get("files", []):
            if not (pkg / f.get("path", "")).exists():
                errs.append(f"{pkg.name}: manifest file missing {f.get('path')}")
        # the data minimums
        for rel in DATA_MIN:
            d = pkg / rel
            if not d.is_dir() or not any(d.iterdir()):
                errs.append(f"{pkg.name}: {rel}/ missing or empty")
        if not (pkg / "save").is_dir():
            errs.append(f"{pkg.name}: save/ missing")
        if not (pkg / "discover" / "page.json").is_file():
            errs.append(f"{pkg.name}: discover/page.json missing")
    if n == 0:
        errs.append("no packages under GOGAs/games/")
    # the official source manifest parses + lists them
    src_path = ROOT / "GOGAs" / "discover" / "index" / "source.json"
    if not src_path.exists():
        errs.append("no GOGAs/discover/index/source.json")
    else:
        src = json.loads(src_path.read_text(encoding="utf-8"))
        if len(src.get("games", [])) != n:
            errs.append("source.json's games list does not match the tree")
    return errs

def repos_txt_lines() -> list:
    p = ROOT / "GOGAs" / "discover" / "REPOS.txt"
    if not p.exists():
        return []
    out = []
    for line in p.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if s and not s.startswith("#"):
            out.append(s)
    return out

def main() -> int:
    mode = sys.argv[1] if len(sys.argv) > 1 else "tree"
    fails = 0
    if mode in ("tree", "all"):
        errs = validate_local_tree()
        for e in errs:
            print(f"FAIL: {e}")
        fails += len(errs)
        print(f"local tree: {len(validate_local_tree()) == 0 and 'OK' or 'see above'}")
    if mode in ("repos", "all"):
        for repo in repos_txt_lines():
            print(f"checking {repo} ...")
            errs, n = validate_repo(repo)
            for e in errs:
                print(f"FAIL: {repo}: {e}")
            fails += len(errs)
            if not errs:
                print(f"  OK ({n} game(s))")
        # the added-repo mode (CI passes the repo refs explicitly)
        for repo in sys.argv[2:]:
            print(f"checking (added) {repo} ...")
            errs, n = validate_repo(repo)
            for e in errs:
                print(f"FAIL: {repo}: {e}")
            fails += len(errs)
            if not errs:
                print(f"  OK ({n} game(s))")
    if fails:
        print(f"RESULT: {fails} failure(s)")
        return 1
    print("RESULT: ALL VALID")
    return 0

if __name__ == "__main__":
    sys.exit(main())
