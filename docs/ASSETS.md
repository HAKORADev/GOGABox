# ASSETS — policy, manifest, source catalogs (general)

Every project carries an `assets.manifest.json` that documents **where each
file came from, its license, and how to re-download it**. Assets are vendored
(committed) so builds never depend on the network.

This guide is **general** — any project in this repo. Which concrete packs
each game actually uses is recorded next to the game:
`projects/<game>/docs/ASSETS.md` (plus the machine-auditable
`projects/<game>/assets.manifest.json`).

## Policy

- **CC0 only.** No attribution required, safe for commercial apps.
- **Vendor everything** (commit the files); never hot-link at runtime.
- Record every file in the project's `assets.manifest.json` (schema 2:
  sources have `id`; `files` maps project-relative paths → `{source, origin}`).
- Prefer sources with stable direct URLs.

## Re-download on a fresh machine

```bash
python3 tools/sync-assets.py            # all projects
python3 tools/sync-assets.py jellyjump  # one project
```

- kenney.nl zips are auto-resolved by scraping the asset page for its current
  `/media/pages/.../*.zip` link (their URLs contain rotating hashes).
- OpenGameArt sources use direct file URLs.
- Missing files are restored; existing files are never overwritten.

## Source catalogs (reachable, checked Aug 2026)

### Kenney — kenney.nl/assets

Full catalog is CC0 1.0. Zips are page-scrapable (the sync tool handles the
rotating URLs). Note: their catalog was restructured in 2025–2026 — some
classic 2D packs (e.g. "Platformer Pack Redux") now live on OpenGameArt
mirrors instead; check `projects/<game>/docs/ASSETS.md` for resolved links.

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

- `projects/<game>/assets/sprites|audio/...` — vendored files.
- `projects/<game>/assets.manifest.json` — the audit trail.
- Generated audio (synth SFX) lives in `assets/audio/synth/` and must be
  reproducible by a committed per-project script (see the game's
  `tools/gen_sfx.py` pattern — deterministic output only).
- Icons: `icon.svg` is the master; a per-project `tools/rasterize_icons.gd`
  renders the launcher PNGs referenced by the export presets (needs one
  `godot --headless --import` first).
- When you add a game-specific source (pack tables, resolved URLs), put it
  in `projects/<game>/docs/ASSETS.md` — not here.
