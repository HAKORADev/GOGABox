# ASSETS — policy, manifest, source catalogs

GOGABox carries an `assets.manifest.json` that documents **where each file
came from, its license, and how to re-download it**. Assets are vendored
(committed) so builds never depend on the network.

Which concrete packs GOGABox actually uses is recorded in
`projects/gogabox/assets.manifest.json` (machine-auditable) and summarized
in the GOGABox section below.

## Policy

- **CC0 only.** No attribution required, safe for commercial apps.
- **Vendor everything** (commit the files); never hot-link at runtime.
- Record every file in `projects/gogabox/assets.manifest.json` (schema 2:
  sources have `id`; `files` maps project-relative paths → `{source, origin}`).
- Prefer sources with stable direct URLs.

## Re-download on a fresh machine

```bash
python3 tools/sync-assets.py gogabox
```

- kenney.nl zips are auto-resolved by scraping the asset page for its current
  `/media/pages/.../*.zip` link (their URLs contain rotating hashes).
- OpenGameArt sources use direct file URLs.
- Missing files are restored; existing files are never overwritten.

## GOGABox asset pipeline (per-project summary)

- Pipeline: `python3 projects/gogabox/tools/derive_assets.py` — idempotent,
  deterministic: re-downloads the Kenney Fonts zip (CC0) when missing,
  re-copies CC0 audio (Kenney Interface Sounds / Music Jingles, OpenGameArt
  pops + loop), re-draws every sprite/icon/thumbnail with PIL, re-synthesizes
  hop/land SFX with numpy.
- Thumbnails: 480x320 per game, drawn from the actual game sprites so menu
  tiles always match the real art. SOON tiles are generated from the registry.

## Store trials — one asset downloaded per store (checked 2026-08-30)

Owner asked to try each candidate asset store once and record what works.
Download samples were pulled to a scratch dir (NOT vendored — they are
trials, not project assets). Script: sandbox `scripts/asset_trials.py`.

| store | verdict | what worked / what blocked |
|---|---|---|
| **ambientCG** | ✅ WORKS (scriptable) | API v2 `full_json` search → direct zip `ambientcg.com/get?file=<id>_1K-JPG.zip`. Got CC0 `Wood095` 1K JPG (3.8 MB). Best-in-class: stable URLs, CC0, no account. |
| **GameArt2D.com** | ✅ WORKS (scriptable) | Free pack pages expose direct `.zip` links. Got the free platformer tileset (16 MB). Free section is CC0-like; check each pack's license note. |
| **Google Fonts** | ✅ WORKS (scriptable) | `raw.githubusercontent.com/google/fonts/main/ofl/<family>/...ttf`. Got Pacifico Regular (321 KB, OFL — attribution-in-file, fine for an app). Thousands of families, stable GitHub mirror. |
| **Poly Haven** | ⚠️ PARTIAL | API `assets` + `info` reachable, but `info` no longer exposes `files` and the old `dl.polyhaven.org` paths 404 — direct file URLs are gone from the public API. Thumbnail CDN (`cdn.polyhaven.com`) downloads fine. Real texture/model downloads currently need the website (browser) or their Blender addon. CC0 throughout. |
| **Quaternius** | ❌ browser-only | Pack pages load, but the download button is a JS modal (`href="#inline"`) routing through itch.io — no direct zip URL to script. Manual download in a browser works; packs are CC0. |
| **Shadertoy** | ❌ needs key | API (`/api/v1/shaders`) and even the media CDN answer 403 without an API key. A free key exists in your Shadertoy profile settings — with it, shader sources are fetchable (`/api/v1/shaders/<id>?key=...`). |
| **Godot Shaders** | ❌ blocked from bots | Site/WAF answers HTTP 454/455 to non-browser agents. The shader source is printed on each page in a browser; copy it manually. Licenses per-shader (mostly MIT/CC0 — check the page). |

Practical takeaway for GOGABox: **ambientCG + GameArt2D + Google Fonts** can
be piped straight into `tools/sync-assets.py`-style vendoring. **Poly Haven /
Quaternius / Godot Shaders / Shadertoy** assets can still be used — fetch
them in a browser once, commit them, record them in the manifest (the vendored
build never needs the network anyway).

## Other proven catalogs

### Kenney — kenney.nl/assets

Full catalog is CC0 1.0. Zips are page-scrapable (the sync tool handles the
rotating URLs). Note: their catalog was restructured in 2025–2026 — some
classic 2D packs (e.g. "Platformer Pack Redux") now live on OpenGameArt
mirrors instead; check the manifest for resolved links.

### OpenGameArt — opengameart.org

Huge CC0/CC-BY catalog with direct file URLs. Watch the license per asset —
not everything there is CC0; filter before vendoring.

### Godot Asset Library — godotengine.org/asset-library

Search + direct download (each asset page has a zip). Licenses vary per
asset — verify license **and** Godot 4.x compatibility before vendoring.
Proven add-ons for future games (MIT/CC0 unless noted): *Phantom Camera*
(camera rigs), *Dialogue Manager*, *SimpleGrassTextured*.

### Audio

- https://freesound.org — CC0 filter available (account needed for some downloads).
- https://pixabay.com/sound-effects — CC0-like license, direct downloads.

## Conventions

- `projects/gogabox/assets/sprites|audio/...` — vendored files.
- `projects/gogabox/assets.manifest.json` — the audit trail.
- Generated audio (synth SFX) lives in `assets/audio/synth/` and must be
  reproducible by a committed script (deterministic output only).
- Icons: `icon.svg` is the master; a per-project `tools/rasterize_icons.gd`
  renders the launcher PNGs referenced by the export presets (needs one
  `godot --headless --import` first).
