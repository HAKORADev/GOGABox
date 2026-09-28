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

def validate_ledger(ledger_path: Path, pkg_name: str, version: str):
    """v043 pass 3 THE VERSION LEDGER: index/versions.json - one entry per
    released version, newest last; the VERSIONS sort's data."""
    if not ledger_path.exists():
        return [f"{pkg_name}: no index/versions.json - the version ledger"]
    try:
        led = json.loads(ledger_path.read_text(encoding="utf-8"))
    except Exception as e:
        return [f"{pkg_name}: index/versions.json is not JSON ({e})"]
    vs = led.get("versions")
    if not isinstance(vs, list) or not vs:
        return [f"{pkg_name}: index/versions.json carries no versions[]"]
    errs = []
    for v in vs:
        if not isinstance(v, dict) or not v.get("version"):
            errs.append(f"{pkg_name}: a ledger entry without its version")
    versions = [str(v.get("version")) for v in vs if isinstance(v, dict)]
    if str(version) not in versions:
        errs.append(f"{pkg_name}: the ledger does not name the index version {version}")
    return errs

def validate_catalog_tree():
    """v043 pass 3 THE CATALOG (schema 2): the per-tier files parse, the
    official rows match the tree, community.json and REPOS.txt agree."""
    errs = []
    cat = ROOT / "GOGAs" / "discover" / "index"
    src_path = cat / "source.json"
    if not src_path.exists():
        return ["no GOGAs/discover/index/source.json"]
    src = json.loads(src_path.read_text(encoding="utf-8"))
    if int(src.get("schema", 1)) < 2:
        errs.append("source.json is still schema 1 - run tools/v043_package.py (the catalog rebuild)")
        return errs
    tiers = src.get("tiers") or {}
    for t in ("official", "community", "hobbyist"):
        rel = tiers.get(t)
        if not rel:
            errs.append(f"source.json's tier map misses \"{t}\"")
            continue
        # the tier map paths are RELATIVE TO THE CATALOG FOLDER (the files
        # sit beside source.json); the game index paths INSIDE the tier
        # files are repo-relative (they point into games/)
        p = cat / rel
        if not p.exists():
            errs.append(f"the tier file {rel} does not exist")
            continue
        tf = json.loads(p.read_text(encoding="utf-8"))
        if t == "community":
            # the community directory must agree with REPOS.txt (the two
            # files are one register - a PR touches both, CI keeps lockstep)
            registered = set(repos_txt_lines())
            listed = {str(s.get("repo", "")) for s in tf.get("sources", [])
                      if s.get("repo")}
            if registered != listed:
                errs.append("community.json does not match REPOS.txt - "
                            f"register={sorted(registered)} catalog={sorted(listed)}")
    # the official rows name every package in the tree
    off_rel = tiers.get("official", "")
    off_path = ROOT / "GOGAs" / off_rel if off_rel else None
    if off_path and off_path.exists():
        off = json.loads(off_path.read_text(encoding="utf-8"))
        listed_ids = set()
        for g in off.get("games", []):
            listed_ids.add(str(g.get("id", "")))
            ip = ROOT / "GOGAs" / str(g.get("index", ""))
            if not ip.exists():
                errs.append(f"official.json names a game the tree does not carry: {g.get('index')}")
        for pkg in sorted((ROOT / "GOGAs" / "games").glob("gogabox_github-*")):
            idx = json.loads((pkg / "index" / "index.json").read_text(encoding="utf-8"))
            if idx.get("id") not in listed_ids:
                errs.append(f"official.json does not list {pkg.name}")
    return errs

def _games_of_source(src: dict, repo: str, branch: str):
    """the source's game rows - schema 2 (the tier map) or schema 1
    (the inline games array). Returns (games, errs)."""
    if int(src.get("schema", 1)) >= 2 and isinstance(src.get("tiers"), dict):
        errs = []
        games = []
        for t in ("official", "hobbyist"):
            rel = src["tiers"].get(t, "")
            if not rel:
                continue
            tf = fetch(f"{RAW}/{repo}/{branch}/{rel}")
            if "__err__" in tf:
                errs.append(f"tier file {rel}: {tf['__err__']}")
                continue
            games += tf.get("games", [])
        return games, errs
    return src.get("games", []), []

def validate_repo(repo: str, branch="main"):
    """fetch + validate one source repo; returns (errors, game_count)"""
    src = fetch(f"{RAW}/{repo}/{branch}/GOGAs/discover/index/source.json")
    if "__err__" in src:
        return [f"source.json: {src['__err__']}"], 0
    errs = []
    games, gerrs = _games_of_source(src, repo, branch)
    errs += gerrs
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
        # v043 pass 3: the version ledger (index/ is a real folder)
        idx = json.loads(idx_path.read_text(encoding="utf-8"))
        errs += validate_ledger(pkg / "index" / "versions.json", pkg.name,
                                idx.get("version", ""))
    if n == 0:
        errs.append("no packages under GOGAs/games/")
    # the catalog (schema 2): per-tier files + the tree agreement
    errs += validate_catalog_tree()
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
