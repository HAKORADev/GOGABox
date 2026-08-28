# GOGABox assets

- Audit file: `assets.manifest.json` (sources, licenses, re-fetch commands).
- Pipeline: `python3 tools/derive_assets.py` — idempotent, deterministic:
  - re-downloads the Kenney Fonts zip (CC0) when missing,
  - re-copies CC0 audio vendored in candyrush (Kenney Interface Sounds /
    Music Jingles, OpenGameArt pops + loop),
  - re-draws every sprite/icon/thumbnail with PIL,
  - re-synthesizes hop/land sfx with numpy.
- Policy: CC0-only, vendored, no runtime downloads. Same rule as the rest of
  the arsenal (see `docs/ASSETS.md` at repo root).
- Thumbnails: 480x320 per game, drawn from the actual game sprites so menu
  tiles always match the real art. SOON tiles are generated from the registry.
