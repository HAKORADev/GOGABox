#!/usr/bin/env python3
"""fetch_asset.py - download free game assets from the "complex" stores that a
plain curl cannot handle (JS modals, client-side zips, API keys).

    python3 tools/study/fetch_asset.py quaternius <pack page url> [-o OUTDIR]
    python3 tools/study/fetch_asset.py ambientcg <asset id or query> [-o OUTDIR]
    python3 tools/study/fetch_asset.py polyhaven <asset url>     # prints the recipe
    python3 tools/study/fetch_asset.py godotshaders <shader url> # prints the recipe

Live-verified 2026-09-07 (details in docs/DECOMPILATION.md):

  quaternius    the pack page's "Just give me the Download" button opens a
                GOOGLE DRIVE FOLDER - folders are listable through
                drive.google.com/embeddedfolderview?id=<id> and files are
                fetchable through drive.usercontent.google.com. The tool walks
                subfolders (Blends/ FBX/ OBJ/ ...), downloads everything and
                records it. CC0.
  ambientcg     API v2 search -> direct zip endpoint. Already proven in
                docs/ASSETS.md; kept here so the study flow has one entry.
  polyhaven     NOT scriptable: files{} vanished from the info API, the old
                dl host 404s, and the site builds the zip CLIENT-SIDE with
                zip.js (we watched it). Use a real browser once, vendor the
                zip, record it in assets.manifest.json.
  godotshaders  the site's WAF answers 454/455 to non-browser agents. Open the
                page in a browser, copy the shader source by hand.
"""

import argparse
import json
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def log(m: str) -> None:
    print(m, flush=True)


def http_get(url: str, timeout: int = 30, referer: str | None = None) -> tuple[bytes, int, str]:
    req = urllib.request.Request(url, headers={
        "User-Agent": UA, **({"Referer": referer} if referer else {})})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read(), r.status, r.geturl()


# ------------------------------------------------------------------ drive

def drive_list(folder_id: str, depth: int = 0, seen: set | None = None) -> list[dict]:
    """List a google drive folder via embeddedfolderview (no api key needed)."""
    if seen is None:
        seen = set()
    if folder_id in seen or depth > 4:
        return []
    seen.add(folder_id)
    url = f"https://drive.google.com/embeddedfolderview?id={folder_id}#list"
    body, _, _ = http_get(url)
    html = body.decode("utf-8", errors="replace")
    entries = []
    blocks = re.findall(
        r'<a href="https://drive\.google\.com/(?:file/d/|drive/folders/)'
        r'([a-zA-Z0-9_-]+)"[^>]*>.*?flip-entry-title">([^<]*)</div>',
        html, re.S)
    # the view alternates file/folder blocks; identify folders by the link shape
    folders = re.findall(r'href="https://drive\.google\.com/drive/folders/([a-zA-Z0-9_-]+)"[^>]*>.*?'
                         r'flip-entry-title">([^<]*)</div>', html, re.S)
    file_ids = [fid for fid in re.findall(r'href="https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)"', html)]
    titles = re.findall(r'flip-entry-title">([^<]*)</div>', html)
    # pair ids with titles in order of appearance
    id_order = re.findall(r'https://drive\.google\.com/(file/d|drive/folders)/([a-zA-Z0-9_-]+)', html)
    for i, (kind, fid) in enumerate(id_order):
        title = titles[i] if i < len(titles) else fid
        if kind == "drive/folders":
            entries.append({"kind": "folder", "id": fid, "name": title,
                            "children": drive_list(fid, depth + 1, seen)})
        else:
            entries.append({"kind": "file", "id": fid, "name": title})
    return entries


def drive_download(file_id: str, dest: Path, timeout: int = 120) -> int:
    url = (f"https://drive.usercontent.google.com/download?id={file_id}"
           f"&export=download&confirm=t")
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    n = 0
    with urllib.request.urlopen(req, timeout=timeout) as r:
        ct = r.headers.get("Content-Type", "")
        if "text/html" in ct:
            raise RuntimeError("drive returned an html page (virus-scan wall or bad id)")
        with open(dest, "wb") as f:
            while True:
                chunk = r.read(1 << 20)
                if not chunk:
                    break
                f.write(chunk)
                n += len(chunk)
    return n


def flatten(entries: list[dict], prefix: str = "") -> list[tuple[str, dict]]:
    out = []
    for e in entries:
        if e["kind"] == "file":
            out.append((prefix + e["name"], e))
        else:
            out += flatten(e.get("children", []), prefix + e["name"] + "/")
    return out


# ------------------------------------------------------------------ stores

def do_quaternius(pack_url: str, out: Path, timeout: int) -> None:
    body, _, _ = http_get(pack_url, timeout)
    html = body.decode("utf-8", errors="replace")
    m = re.search(r"drive\.google\.com/drive/folders/([a-zA-Z0-9_-]+)", html)
    if not m:
        raise SystemExit("quaternius: no drive folder on the pack page")
    fid = m.group(1)
    log(f"[drive folder] {fid}")
    entries = drive_list(fid)
    files = flatten(entries)
    log(f"[tree] {len(files)} files")
    out.mkdir(parents=True, exist_ok=True)
    saved = []
    for rel, e in files:
        dest = out / re.sub(r"[^a-zA-Z0-9./_ -]", "_", rel)
        if dest.exists() and dest.stat().st_size > 0:
            log(f"  = {rel} (cached)")
            continue
        try:
            dest.parent.mkdir(parents=True, exist_ok=True)
            n = drive_download(e["id"], dest, timeout)
            log(f"  + {rel} ({n:,} B)")
            saved.append({"path": str(dest), "bytes": n, "drive_id": e["id"]})
        except Exception as ex:  # noqa: BLE001
            log(f"  ! {rel}: {ex}")
    (out / "QUATERNIUS_REPORT.json").write_text(json.dumps(
        {"pack": pack_url, "folder": fid, "files": saved}, indent=2))
    log(f"[done] {out} ({len(saved)} new files)")


def do_ambientcg(query: str, out: Path, timeout: int) -> None:
    if re.fullmatch(r"[A-Za-z0-9]+", query) and not query.startswith("http"):
        asset_id = query
    else:
        api = ("https://ambientcg.com/api/v2/full_json?q="
               + urllib.parse.quote(query) + "&limit=1")
        body, _, _ = http_get(api, timeout)
        d = json.loads(body)
        found = d.get("foundAssets", [])
        if not found:
            raise SystemExit("ambientcg: no match")
        asset_id = found[0]["assetId"]
    url = f"https://ambientcg.com/get?file={asset_id}_1K-JPG.zip"
    out.mkdir(parents=True, exist_ok=True)
    dest = out / f"{asset_id}_1K-JPG.zip"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r, open(dest, "wb") as f:
        f.write(r.read())
    log(f"[done] {dest} ({dest.stat().st_size:,} B) - CC0")


def print_recipe(name: str, url: str) -> None:
    log(f"[{name}] not scriptable - do this once in a real browser:")
    if name == "polyhaven":
        log("  1. open " + url)
        log("  2. pick a resolution, click Download - the zip is assembled")
        log("     client-side (zip.js), so there is no direct file url to grab.")
        log("  3. move the zip into the project, add it to assets.manifest.json.")
        log("  everything there is CC0.")
    else:
        log("  1. open " + url + " in a browser (the WAF answers 454/455 to bots)")
        log("  2. copy the shader source from the page")
        log("  3. check the per-shader license (mostly MIT/CC0) before vendoring")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("store", choices=["quaternius", "ambientcg", "polyhaven", "godotshaders"])
    ap.add_argument("target", help="pack page url / asset id / query")
    ap.add_argument("-o", "--out", default=None)
    ap.add_argument("--timeout", type=int, default=120)
    args = ap.parse_args()

    if args.store == "quaternius":
        out = Path(args.out) if args.out else Path("study_out/assets/quaternius")
        do_quaternius(args.target, out, args.timeout)
    elif args.store == "ambientcg":
        out = Path(args.out) if args.out else Path("study_out/assets/ambientcg")
        do_ambientcg(args.target, out, args.timeout)
    else:
        print_recipe(args.store, args.target)


if __name__ == "__main__":
    main()
