#!/usr/bin/env python3
"""fetch_webgame.py - download a playable HTML5 web game (files + assets) from the
big casual portals into a local folder, plus a REPORT.json describing what was got.

    python3 tools/study/fetch_webgame.py <game page url or portal:s Slug> [-o OUTDIR]
        [--max-assets N] [--max-bytes MB] [--timeout S] [--any-host] [--list-only]

Verified adapters (tested 2026-09-07, see docs/DECOMPILATION.md for the full matrix):

  gamesnacks.com   server-rendered page -> <iframe id="game-iframe"> src is the game
                   root on <slug>.h5games.usercontent.goog/v/<token>/ (Google's CDN).
                   Plain HTTP, no auth. NOTE: slugs are portal-owned and sometimes
                   misspelled (e.g. Endless Siege = /games/endlessseige).
  crazygames.com   game page embeds the real build URL:
                   https://<slug>.game-files.crazygames.com/<slug>/<version>/index.html
                   (plain S3 bucket; a wrong path answers NoSuchKey, not 403).
  poki.com         3-hop: page JSON "file":{"content":"//games.poki.com/<build>/<name>"}
                   -> fetch that wrapper -> it embeds
                   "gameUri":"https://<uuid>.gdn.poki.com/<uuid>/index.html"
                   -> that is the real game root. All plain HTTP.
  msn.com          NOT scripted: the catalog API needs app-auth headers and the SPA
                   strips itself for headless browsers. Open the game once in a real
                   browser, copy the game <iframe> src from DevTools, then pass that
                   URL here as a generic entry point (the crawler handles the files).
  anything else    generic mode: pass the game's index.html/iframe URL directly.

The crawler stays on the game's own host(s), follows HTML src/href links and
string literals inside JS/CSS, and skips SDK/analytics/ads hosts. The result
folder is a static copy of the game - open its index.html (some games need a
local web server because of fetch()/wasm pathing: python3 -m http.server).

Output layout:
    OUTDIR/<site>_<slug>/            the game files, paths preserved
    OUTDIR/<site>_<slug>/REPORT.json site, source url, base, engine hints, inventory
"""

import argparse
import json
import posixpath
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

# hosts that are SDK/analytics, never game content
SKIP_HOST_PARTS = (
    "sdk.crazygames.com", "sdks.gamesnacks.com", "game-cdn.poki.com",
    "sdk.poki.com", "api.poki.com", "t.poki.io", "mp.gamesnacks.com",
    "www.googletagmanager.com", "googleads.g.doubleclick.net", "adsbygoogle",
    "securepubads", "c.bing.com", "c.msn.com", "sb.scorecardresearch.com",
    "browser.events.data.msn.com", "analytics", "clarity.ms", "ads.",
    "privacy-mgmt.com", "fonts.googleapis.com", "fonts.gstatic.com",
)

ASSET_EXTS = (
    ".html", ".htm", ".js", ".mjs", ".css", ".json", ".xml", ".txt",
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".bmp", ".ico", ".ktx", ".pvr",
    ".mp3", ".ogg", ".wav", ".m4a", ".aac", ".opus", ".weba",
    ".mp4", ".webm", ".m4v",
    ".wasm", ".data", ".bin", ".mem", ".unityweb", ".pck", ".aty", ".atlas", ".fnt",
    ".zip", ".br", ".gz", ".plist", ".ttf", ".otf", ".woff", ".woff2", ".csv", ".tsv",
    ".c3runtime", ".skel", ".atlas.txt", ".obj", ".gltf", ".glb",
)

ENGINE_MARKERS = {
    "unity": ("unityweb", "libunity", "unity.js", "unityinstance", "createunityinstance",
              "data.unity3d", "build.loader"),
    "godot": (".pck", "godot", "gdc_"),
    "gamemaker": ("gamemaker", "gml", "aty", "audiogroup"),
    "construct": ("c3runtime", "construct", "c2runtime"),
    "cocos": ("cocos", "cc.game", "settings.js", "src/settings"),
    "playcanvas": ("playcanvas", "__loading__", "__start__", "config.json"),
    "phaser": ("phaser",),
    "pixi": ("pixi",),
    "babylon": ("babylon",),
    "three": ("three.js", "three.module"),
}


def log(msg: str) -> None:
    print(msg, flush=True)


def http_get(url: str, timeout: int, referer: str | None = None) -> tuple[bytes, int, str]:
    """GET a URL. Returns (body, status, final_url). Raises on network errors."""
    req = urllib.request.Request(url, headers={
        "User-Agent": UA,
        "Accept": "*/*",
        **({"Referer": referer} if referer else {}),
    })
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read(), r.status, r.geturl()


def url_host(u: str) -> str:
    return urllib.parse.urlparse(u).netloc.lower()


def url_dir(u: str) -> str:
    p = urllib.parse.urlparse(u).path
    d = posixpath.dirname(p)
    return d + "/" if d else "/"


def resolve(base_url: str, ref: str) -> str | None:
    """Resolve a possibly-relative reference against base_url. None if not fetchable content."""
    ref = ref.strip().strip("\"'")
    if not ref or ref.startswith(("data:", "blob:", "javascript:", "#", "about:", "mailto:")):
        return None
    try:
        absu = urllib.parse.urljoin(base_url, ref)
    except ValueError:
        return None
    u = urllib.parse.urlparse(absu)
    if u.scheme not in ("http", "https"):
        return None
    path = u.path.lower()
    if not any(path.endswith(ext) for ext in ASSET_EXTS):
        return None
    return absu


def allowed_host(u: str, game_hosts: set[str], any_host: bool) -> bool:
    h = url_host(u)
    if any(part in h for part in SKIP_HOST_PARTS):
        return False
    if any_host:
        return True
    if h in game_hosts:
        return True
    # same-site family: e.g. <slug>.game-files.crazygames.com <-> crazygames.com
    for gh in game_hosts:
        gh_parts = gh.split(".")
        h_parts = h.split(".")
        if len(gh_parts) >= 2 and len(h_parts) >= 2 and gh_parts[-2:] == h_parts[-2:]:
            # register subdomains of the same registrable domain as allowed
            game_hosts.add(h)
            return True
    return False


def local_name(base_url: str, asset_url: str) -> Path:
    """Map an asset URL to a relative local path under the game root."""
    b = urllib.parse.urlparse(base_url)
    a = urllib.parse.urlparse(asset_url)
    if a.netloc and a.netloc != b.netloc:
        # cross-host asset: park it under _external/<host>/ to keep the copy honest
        return Path("_external") / a.netloc / a.path.lstrip("/")
    # the game root itself (with or without trailing slash) IS index.html
    if a.path.rstrip("/") == b.path.rstrip("/") and a.netloc == b.netloc:
        return Path("index.html")
    rel = a.path.lstrip("/") or "index.html"
    rel = posixpath.normpath(rel)
    if rel.startswith(".."):
        rel = rel.lstrip("./")
    p = Path(rel)
    if a.path in ("", "/") or rel in ("", "."):
        p = Path("index.html")
    return p


CODE_WORDS = {"this", "window", "document", "self", "globalthis", "location",
              "console", "array", "object", "json", "math", "string", "number",
              "promise", "event", "e", "t", "i", "a", "s", "o", "r", "n", "l",
              "c", "d", "u", "g", "h", "f", "p", "m", "b", "k", "v", "w", "x", "y"}


def plausible_path(ref: str) -> bool:
    """Reject JS code fragments that merely end in something.data etc."""
    if any(ch in ref for ch in ' =,;(){}[]<>"\'\n\t\\'):
        return False
    first = ref.split("/")[0].split(".")[0].lower()
    if first in CODE_WORDS and "/" not in ref:
        return False
    if first in CODE_WORDS and ref.count("/") <= 1 and ref.endswith((".data", ".key", ".value")):
        return False
    return True


def extract_refs(text: str, base_url: str, game_root: str | None = None) -> set[str]:
    """Pull every fetchable reference out of HTML/JS/CSS text.

    game_root: engines like Phaser/Construct/GameMaker build asset paths at
    runtime against the game ROOT, not against the bundle's own folder - so
    relative refs from non-root files are resolved against BOTH.
    """
    refs: set[str] = set()
    candidates: list[str] = []
    # html attributes
    for m in re.finditer(r'(?:src|href|data-src|data-href)\s*=\s*["\']([^"\']+)["\']', text, re.I):
        candidates.append(m.group(1))
    # quoted string literals in JS/CSS that look like paths
    for m in re.finditer(r'["\'(]([^"\'()]{4,300})["\')]', text):
        candidates.append(m.group(1))
    # json-style escapes inside js (\u002F etc appear in some portals)
    if "\\u002f" in text.lower():
        try:
            dec = text.encode().decode("unicode_escape", errors="replace")
            for m in re.finditer(r'(?:src|href|url|path|file|uri)\s*[:=]\s*["\']([^"\']+)["\']', dec, re.I):
                candidates.append(m.group(1))
        except Exception:
            pass
    for raw in candidates:
        if not plausible_path(raw):
            continue
        r = resolve(base_url, raw)
        if r:
            refs.add(r)
        if game_root and not raw.lower().startswith(("http://", "https://", "//")):
            r2 = resolve(game_root, raw)
            if r2:
                refs.add(r2)
    return refs


def detect_engines(text: str) -> list[str]:
    low = text.lower()
    return [name for name, marks in ENGINE_MARKERS.items() if any(m in low for m in marks)]


# ---------------------------------------------------------------- adapters

def adapt_gamesnacks(page_url: str, timeout: int) -> tuple[str, str]:
    """game page -> (game_root_url, final_source_url)"""
    body, _, final = http_get(page_url, timeout)
    html = body.decode("utf-8", errors="replace")
    m = re.search(r'<iframe[^>]*id="game-iframe"[^>]*>', html) or \
        re.search(r'<iframe[^>]*class="[^"]*kTZXGd[^"]*"[^>]*>', html)
    if m:
        tag = m.group(0)
        s = re.search(r'src="([^"]+)"', tag)
        if s:
            return urllib.parse.urljoin(final, s.group(1)), final
    # fallback: any h5games.usercontent.goog root on the page
    m = re.search(r'https://[a-z0-9-]+\.h5games\.usercontent\.goog/v/[a-z0-9]+/', html)
    if m:
        return m.group(0), final
    raise SystemExit("gamesnacks: could not find the game iframe on " + page_url)


def adapt_crazygames(page_url: str, timeout: int) -> tuple[str, str]:
    body, _, final = http_get(page_url, timeout)
    html = body.decode("utf-8", errors="replace")
    m = re.search(r'https://([a-z0-9-]+)\.game-files\.crazygames\.com'
                  r'/([a-z0-9-]+)/([a-z0-9]+)/index\.html', html)
    if m:
        return m.group(0), final
    # embed page variant: the slug route is /embed/<slug>
    slug = urllib.parse.urlparse(page_url).path.rstrip("/").split("/")[-1]
    embed = f"https://www.crazygames.com/embed/{slug}"
    body2, _, _ = http_get(embed, timeout, referer=page_url)
    m = re.search(r'https://([a-z0-9-]+)\.game-files\.crazygames\.com'
                  r'/([a-z0-9-]+)/([a-z0-9]+)/index\.html',
                  body2.decode("utf-8", errors="replace"))
    if m:
        return m.group(0), final
    raise SystemExit("crazygames: no game-files build url on page (site layout may have changed)")


def adapt_poki(page_url: str, timeout: int) -> tuple[str, str]:
    body, _, final = http_get(page_url, timeout)
    html = body.decode("utf-8", errors="replace")
    # page JSON: "file":{"content":"\u002F\u002Fgames.poki.com\u002F<build>\u002F<name>"...
    m = re.search(r'"file"\s*:\s*\{[^}]*"content"\s*:\s*"([^"]+)"', html)
    if not m:
        raise SystemExit("poki: no file.content in page json")
    wrapper_path = m.group(1).encode().decode("unicode_escape", errors="replace")
    wrapper_url = urllib.parse.urljoin("https://poki.com/", wrapper_path)
    wbody, _, _ = http_get(wrapper_url, timeout, referer=page_url)
    whtml = wbody.decode("utf-8", errors="replace")
    g = re.search(r'gameUri\\?"\s*:\s*\\?"(https:[^"\\]+/index\.html)', whtml) or \
        re.search(r'gameUri"\s*:\s*"(https:[^"]+/index\.html)', whtml)
    if g:
        return g.group(1), final
    raise SystemExit("poki: wrapper at %s had no gameUri (site layout may have changed)" % wrapper_url)


ADAPTERS = {
    "gamesnacks.com": adapt_gamesnacks,
    "crazygames.com": adapt_crazygames,
    "poki.com": adapt_poki,
}


def pick_adapter(page_url: str):
    host = url_host(page_url)
    for dom, fn in ADAPTERS.items():
        if host == dom or host.endswith("." + dom):
            return fn
    return None


# ---------------------------------------------------------------- crawler

def crawl_urls(urls: list[str], base_url: str, out: Path, max_assets: int,
               max_bytes: int, timeout: int, any_host: bool) -> dict:
    """Download an explicit list of URLs (browser network log) under the game root.
    Used when a game builds asset paths at runtime (string concatenation) so a
    static crawl cannot see them: play the game once with a capture, feed the
    request list here. See docs/DECOMPILATION.md, the browser-assisted flow."""
    saved: list[dict] = []
    saved_paths: set[str] = set()
    total = 0
    for url in urls:
        if len(saved) >= max_assets or total >= max_bytes:
            break
        try:
            body, status, final_url = http_get(url, timeout)
        except Exception as e:  # noqa: BLE001
            log(f"  ! {url[:110]} -> {e}")
            continue
        if status != 200:
            log(f"  ! {url[:110]} -> HTTP {status}")
            continue
        total += len(body)
        rel = local_name(base_url, final_url)
        if str(rel) in saved_paths:
            continue
        saved_paths.add(str(rel))
        if url_host(final_url) != url_host(base_url):
            rel = Path("_external") / url_host(final_url) / rel
        if not list_only_mode:
            (out / rel).parent.mkdir(parents=True, exist_ok=True)
            (out / rel).write_bytes(body)
        saved.append({"path": str(rel), "url": final_url, "bytes": len(body)})
        log(f"  + {str(rel)[:100]} ({len(body):,} B)")
    return {"files": saved, "total_bytes": total, "engine_hints": [],
            "hosts": sorted({url_host(u) for u in urls})}


list_only_mode = False


def crawl(base_url: str, out: Path, max_assets: int, max_bytes: int, timeout: int,
          any_host: bool, list_only: bool) -> dict:
    # a game root must resolve like a directory, or relative refs break
    if not urllib.parse.urlparse(base_url).path.endswith("/") and \
            not Path(urllib.parse.urlparse(base_url).path).suffix:
        base_url = base_url + "/"
    game_hosts = {url_host(base_url)}
    queue: list[tuple[str, str]] = [(base_url, "index.html")]
    seen: set[str] = set()
    saved: list[dict] = []
    saved_paths: set[str] = set()
    total = 0
    engines_hint: set[str] = set()

    while queue and len(saved) < max_assets and total < max_bytes:
        url, _ = queue.pop(0)
        if url in seen:
            continue
        seen.add(url)
        try:
            body, status, final_url = http_get(url, timeout, referer=base_url)
        except Exception as e:  # noqa: BLE001 - log and keep going
            log(f"  ! {url[:110]} -> {e}")
            continue
        if status != 200:
            log(f"  ! {url[:110]} -> HTTP {status}")
            continue
        total += len(body)
        rel = local_name(base_url, final_url)
        if str(rel) in saved_paths:
            continue  # same file reached under a different url spelling
        saved_paths.add(str(rel))
        is_html = rel.suffix in (".html", ".htm") or b"<html" in body[:8192].lower()
        looks_text = (is_html or rel.suffix in (".js", ".mjs", ".css", ".json",
                                                ".xml", ".txt", "") or not rel.suffix)
        # engine sniffing
        if is_html or rel.suffix in (".js", ".json", ".mjs"):
            snippet = body[:400_000].decode("utf-8", errors="replace")
            engines_hint.update(detect_engines(snippet))
        if not list_only:
            (out / rel).parent.mkdir(parents=True, exist_ok=True)
            (out / rel).write_bytes(body)
        saved.append({"path": str(rel), "url": final_url, "bytes": len(body)})
        log(f"  + {str(rel)[:100]} ({len(body):,} B)")

        # harvest new references from text-ish payloads
        if looks_text:
            text = body[:2_000_000].decode("utf-8", errors="replace")
            ref_base = final_url if final_url.endswith("/") or \
                Path(urllib.parse.urlparse(final_url).path).suffix else final_url + "/"
            root = base_url if url_dir(final_url) != url_dir(base_url) else None
            for ref in extract_refs(text, ref_base, root):
                if ref in seen or len(saved) + len(queue) >= max_assets:
                    continue
                if not allowed_host(ref, game_hosts, any_host):
                    continue
                if str(local_name(base_url, ref)) in saved_paths:
                    continue
                queue.append((ref, ""))

    return {
        "files": saved,
        "total_bytes": total,
        "engine_hints": sorted(engines_hint),
        "hosts": sorted(game_hosts),
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("url", help="game page url (portal) or game index/iframe url (generic)")
    ap.add_argument("-o", "--out", default="study_out", help="output root dir (default ./study_out)")
    ap.add_argument("--max-assets", type=int, default=4000)
    ap.add_argument("--max-bytes", type=int, default=1200, help="cap in MB (default 1200)")
    ap.add_argument("--timeout", type=int, default=30)
    ap.add_argument("--any-host", action="store_true",
                    help="also fetch assets from other hosts (still skips sdk/ads)")
    ap.add_argument("--list-only", action="store_true", help="discover files, save nothing")
    ap.add_argument("--urls-file", default="",
                    help="text file with one URL per line (browser network log) - "
                         "downloads those files under the game root; the positional "
                         "url is still used to name/base the folder")
    ap.add_argument("--name", default="", help="override output folder name")
    args = ap.parse_args()

    url = args.url
    adapter = pick_adapter(url)
    if adapter:
        log(f"[adapter] {url_host(url)}")
        base, source = adapter(url, args.timeout)
    else:
        log("[adapter] generic (treat as game root; pass an iframe src for portal pages)")
        base, source = url, url
    if not base.endswith("/") and base.lower().endswith(".html"):
        pass  # crawler resolves relative refs against the file path itself
    log(f"[game root] {base}")

    host = url_host(url)
    slug = [p for p in urllib.parse.urlparse(url).path.split("/") if p]
    name = args.name or (f"{host.split('.')[0]}_{slug[-1] if slug else 'game'}")
    out = Path(args.out) / re.sub(r"[^a-zA-Z0-9._-]", "_", name)
    out.mkdir(parents=True, exist_ok=True)

    log(f"[crawl] -> {out}")
    if args.urls_file:
        list_only_mode = args.list_only
        urls = [l.strip() for l in Path(args.urls_file).read_text().splitlines()
                if l.strip() and not l.strip().startswith("#")]
        result = crawl_urls(urls, base, out, args.max_assets,
                            args.max_bytes * 1024 * 1024, args.timeout, args.any_host)
    else:
        result = crawl(base, out, args.max_assets, args.max_bytes * 1024 * 1024,
                       args.timeout, args.any_host, args.list_only)

    report = {
        "site": host,
        "source_url": url,
        "game_root": base,
        "output_dir": str(out),
        "files_count": len(result["files"]),
        "total_bytes": result["total_bytes"],
        "engine_hints": result["engine_hints"],
        "game_hosts": result["hosts"],
        "files": result["files"],
    }
    (out / "REPORT.json").write_text(json.dumps(report, indent=2))
    log(f"[done] {len(result['files'])} files, {result['total_bytes']:,} bytes, "
        f"engines={result['engine_hints']}")
    log(f"[open] cd {out} && python3 -m http.server 8000  (then open http://localhost:8000)")


if __name__ == "__main__":
    main()
