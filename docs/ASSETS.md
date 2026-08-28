# ASSETS — sources, licenses, re-fetching

Every project carries an `assets.manifest.json` that documents **where each
file came from, its license, and how to re-download it**. Assets are vendored
(committed) so builds never depend on the network.

## Re-download on a fresh machine

```bash
python3 tools/sync-assets.py            # all projects
python3 tools/sync-assets.py jellyjump  # one project
```

- kenney.nl zips are auto-resolved by scraping the asset page for its current
  `/media/pages/.../*.zip` link (their URLs contain rotating hashes).
- OpenGameArt sources use direct file URLs.
- Missing files are restored; existing files are never overwritten.

## Verified sources (checked Aug 2026)

### Kenney (kenney.nl) — all CC0 1.0

| pack | page | used for |
|---|---|---|
| Interface Sounds | https://kenney.nl/assets/interface-sounds | UI click / confirm / error / buy |
| Music Jingles | https://kenney.nl/assets/music-jingles | win + daily-reward jingles (8-Bit set) |
| Digital Audio | https://kenney.nl/assets/digital-audio | spare arcade blips (not used yet) |

Kenney's classic 2D platformer pack ("Platformer Pack Redux") lives on
OpenGameArt as **Platformer Art Deluxe** (the kenney.nl catalog restructured
in 2025-2026; the new "Platformer Kit" is 3D):

| pack | page | used for |
|---|---|---|
| Platformer Art Deluxe | https://opengameart.org/content/platformer-art-deluxe | aliens (p1/p2/p3), grass/stone/dirt tiles, coin, springboard, hills bg, HUD coin |

Direct zip: https://opengameart.org/sites/default/files/platformerGraphicsDeluxe_Updated.zip

### Godot Asset Library — plugins & templates (reach + fetch)

- https://godotengine.org/asset-library — search + direct download
  (each asset page has a downloadable zip; licenses vary, check per asset).
- Useful proven add-ons for future games (MIT/CC0 unless noted):
  *Phantom Camera* (camera rigs), *Dialogue Manager*, *SimpleGrassTextured*.
  Verify license + Godot 4.x compatibility before vendoring.

### Other reachable sources

- https://opengameart.org — huge CC0/CC-BY catalog, direct file URLs.
- https://kenney.nl/assets — full CC0 catalog (page-scrapable zips).
- https://freesound.org — CC0 filter available (needs account for some downloads).
- https://pixabay.com/sound-effects — CC0-like license, direct downloads.

> Rule of thumb for this repo: **CC0 only**, record everything in the
> manifest, prefer sources with stable direct URLs, and vendor the files —
> never hot-link at runtime.

## Project conventions

- `projects/<g>/assets/sprites|audio/...` — vendored files.
- `projects/<g>/assets.manifest.json` — the audit trail (schema 2: sources
  have `id`; `files` map project-relative paths → `{source, origin}`).
- Generated audio lives in `assets/audio/synth/` and is produced by
  `projects/<g>/tools/gen_sfx.py` (numpy; deterministic output).
- Icons: `icon.svg` is the master; `tools/rasterize_icons.gd` renders the
  launcher PNGs referenced by the export presets (needs one
  `godot --headless --import` first).
