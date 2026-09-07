#!/usr/bin/env python3
"""fetch_apkpure.py - download an APK or XAPK from APKPure, scriptable.

    python3 tools/study/fetch_apkpure.py <package or apkpure page url>
        [--flavor apk|xapk|auto] [-o OUTDIR] [--timeout S]

The website (apkpure.com) sits behind Cloudflare Turnstile and strips itself
for headless browsers - page scraping is dead. But the APKPure android app
(package com.apkpure.aegon) pulls files straight from the download edge
(d.apkpure.com) with its own client UA, and THAT endpoint does not check for
a browser. Verified 2026-09-07 (see docs/DECOMPILATION.md):

    GET https://d.apkpure.com/b/APK/<package>?version=latest
        User-Agent: AEGON/3.20.20        -> plain .apk  (200, application/vnd.android.package-archive)
    GET https://d.apkpure.com/b/XAPK/<package>?version=latest
        User-Agent: AEGON/3.20.20        -> .xapk       (200, application/xapk-package-archive)

An XAPK is just a ZIP: <package>.apk + manifest.json + usually the .obb
expansion file(s). Everything lands in OUTDIR/<package>/ with a REPORT.json.

Flavors:
    apk   plain .apk (smaller, but big games ship without their expansion data)
    xapk  the bundle (base apk + obb + split config apks) - preferred for study
    auto  try xapk first, fall back to apk (default)
"""

import argparse
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

APKPURE_UA = "AEGON/3.20.20"
CHUNK = 1 << 20  # 1 MB


def log(msg: str) -> None:
    print(msg, flush=True)


def package_from_arg(arg: str) -> str:
    """Accept a bare package, or an apkpure page url .../<slug>/<package>."""
    if re.fullmatch(r"[a-zA-Z][a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)+", arg):
        return arg
    m = re.search(r"/([a-zA-Z][a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)+)/?(?:\?|#|$)", arg)
    if m:
        return m.group(1)
    raise SystemExit(f"cannot read a package name out of: {arg}")


def download(url: str, dest: Path, timeout: int) -> dict:
    req = urllib.request.Request(url, headers={
        "User-Agent": APKPURE_UA,
        "x-requested-with": "com.apkpure.aegon",
        "Accept": "*/*",
    })
    with urllib.request.urlopen(req, timeout=timeout) as r:
        ctype = r.headers.get("Content-Type", "")
        total = int(r.headers.get("Content-Length") or 0)
        tmp = dest.with_suffix(dest.suffix + ".part")
        done = 0
        with open(tmp, "wb") as f:
            while True:
                chunk = r.read(CHUNK)
                if not chunk:
                    break
                f.write(chunk)
                done += len(chunk)
                if total and done % (50 * CHUNK) < CHUNK:
                    log(f"  .. {done / 1e6:8.1f} / {total / 1e6:.1f} MB")
        tmp.rename(dest)
        return {"file": dest.name, "bytes": done, "content_type": ctype,
                "final_url": r.geturl()}


def sniff(path: Path) -> str:
    with open(path, "rb") as f:
        head = f.read(4)
    if head[:2] == b"PK":
        return "zip"  # apk and xapk are both zip containers
    if head[:3] == b"\x7fELF":
        return "elf"
    if head[:5] == b"<?xml" or head[:4] == b"<htm":
        return "html-error"
    return "unknown"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("package", help="android package id or apkpure page url")
    ap.add_argument("--flavor", choices=["apk", "xapk", "auto"], default="auto")
    ap.add_argument("-o", "--out", default="study_out/apk",
                    help="output dir (default ./study_out/apk)")
    ap.add_argument("--timeout", type=int, default=120)
    args = ap.parse_args()

    pkg = package_from_arg(args.package)
    out = Path(args.out) / pkg
    out.mkdir(parents=True, exist_ok=True)

    flavors = [args.flavor] if args.flavor != "auto" else ["xapk", "apk"]
    got = None
    # the edge load-balances nodes that disagree: same url can 403/404 then 302
    # on a retry, so every flavor gets a few real attempts
    for flavor in flavors:
        url = f"https://d.apkpure.com/b/{flavor.upper()}/{pkg}?version=latest"
        ext = "xapk" if flavor == "xapk" else "apk"
        dest = out / f"{pkg}.{ext}"
        info = None
        for attempt in range(1, 5):
            log(f"[fetch] {flavor}: {url}" + (f" (try {attempt})" if attempt > 1 else ""))
            try:
                info = download(url, dest, args.timeout)
                break
            except Exception as e:  # noqa: BLE001
                log(f"  ! {e}")
                time.sleep(1.5)
        if not info:
            continue
        kind = sniff(dest)
        log(f"  = {dest.name}: {info['bytes']:,} B, type={info['content_type']}, zip-sig={kind}")
        if kind == "zip":
            got = {"flavor": flavor, **info}
            break
        dest.unlink(missing_ok=True)
        log(f"  ! not a zip (got {kind}); endpoint may be blocked or package missing")

    if not got:
        raise SystemExit("no download succeeded")

    report = {
        "package": pkg,
        "source": "apkpure",
        "flavor": got["flavor"],
        "file": got["file"],
        "bytes": got["bytes"],
        "content_type": got["content_type"],
        "endpoint": got["final_url"].split("?")[0],
    }
    (out / "REPORT.json").write_text(json.dumps(report, indent=2))
    log(f"[done] {out / got['file']} ({got['bytes']:,} B)")


if __name__ == "__main__":
    main()
