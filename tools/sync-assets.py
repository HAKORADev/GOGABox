#!/usr/bin/env python3
"""Fetch + vendor external assets declared in a project's assets.manifest.json.

Usage (from repo root):
    python3 tools/sync-assets.py              # every project
    python3 tools/sync-assets.py gogabox     # one project

Behavior:
- Downloads every source pack (zip) into .cache/assets/ and extracts it.
  * kenney.nl sources are resolved automatically: the page HTML is scraped
    for the current /media/pages/.../<file>.zip link.
- Copies any missing destination file from its extracted origin.
  Files that already exist are left untouched (local edits win).
- "generated" files are produced by project-local tools (e.g. gen_sfx.py).

Everything the game needs is committed to the repo; this script is the
re-download path for a fresh machine (or after an asset purge).
"""
import json
import re
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSET_CACHE = ROOT / ".cache" / "assets"


def sh(*args: str) -> None:
    subprocess.run(args, check=True)


def fetch(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"  downloading {url}")
    req = urllib.request.Request(url, headers={"User-Agent": "arsenal-sync/1.0"})
    with urllib.request.urlopen(req, timeout=120) as r, open(dest, "wb") as f:
        shutil.copyfileobj(r, f)


def kenney_zip_url(page_url: str) -> str:
    html = urllib.request.urlopen(
        urllib.request.Request(page_url, headers={"User-Agent": "arsenal-sync/1.0"}),
        timeout=60,
    ).read().decode("utf-8", "replace")
    m = re.search(r'(/media/pages/assets/[^"]+?\.zip)', html)
    if not m:
        raise RuntimeError(f"no zip link found on {page_url} - see docs/ASSETS.md")
    return "https://kenney.nl" + m.group(1)


def slugify(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def main() -> int:
    keys = sys.argv[1:] or sorted(
        p.name for p in (ROOT / "projects").iterdir() if p.is_dir()
    )
    for key in keys:
        manifest_path = ROOT / "projects" / key / "assets.manifest.json"
        if not manifest_path.exists():
            continue
        manifest = json.loads(manifest_path.read_text())
        proj = ROOT / "projects" / key
        print(f"[{key}] syncing assets -> {proj}")

        sources = {}
        for src in manifest["sources"]:
            sid = src.get("id") or slugify(src["name"])
            sources[sid] = src
            extract_dir = ASSET_CACHE / "extracted" / sid
            zip_path = ASSET_CACHE / f"{sid}.zip"
            if extract_dir.exists() and any(extract_dir.iterdir()):
                print(f"  cached: {sid}")
                continue
            url = src.get("zip")
            if not url and "kenney.nl/assets/" in src.get("url", ""):
                url = kenney_zip_url(src["url"])
            if not url:
                print(f"  ! no automatic download for {sid} - fetch manually "
                      f"from {src.get('url')} (see docs/ASSETS.md)")
                continue
            fetch(url, zip_path)
            extract_dir.mkdir(parents=True, exist_ok=True)
            sh("unzip", "-qo", str(zip_path), "-d", str(extract_dir))

        copied = skipped = 0
        for dest, meta in manifest["files"].items():
            dest_path = proj / dest
            if dest_path.exists():
                skipped += 1
                continue
            dest_path.parent.mkdir(parents=True, exist_ok=True)
            origin = meta.get("origin", "")
            if meta.get("source") == "generated":
                tool = meta.get("tool")
                if tool and (proj / tool).exists():
                    print(f"  generating {dest} via {tool}")
                    subprocess.run([sys.executable, str(proj / tool)],
                                   check=True, cwd=proj)
                else:
                    print(f"  ! {dest} is generated but missing (tool: {tool})")
                continue
            src_dir = ASSET_CACHE / "extracted" / meta["source"]
            src_file = src_dir / origin
            if src_file.exists():
                shutil.copy2(src_file, dest_path)
                copied += 1
            else:
                print(f"  ! missing origin for {dest}: {src_file}")
        print(f"  done: {copied} copied, {skipped} already present")
    return 0


if __name__ == "__main__":
    sys.exit(main())
