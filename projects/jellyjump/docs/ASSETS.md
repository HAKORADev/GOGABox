# JellyJump — assets (this game's concrete sources)

> Repo-wide asset **policy**, manifest schema and re-download tooling live in
> the general guide: [docs/ASSETS.md](../../../docs/ASSETS.md). This file only
> records which concrete packs *this* game uses.

Everything is vendored under `assets/` and audited in
[`../assets.manifest.json`](../assets.manifest.json).
Re-fetch on a fresh machine:

```bash
python3 tools/sync-assets.py jellyjump
```

## Verified sources (checked Aug 2026)

### Kenney (kenney.nl) — all CC0 1.0

| pack | page | used for |
|---|---|---|
| Interface Sounds | https://kenney.nl/assets/interface-sounds | UI click / confirm / error / buy |
| Music Jingles | https://kenney.nl/assets/music-jingles | win + daily-reward jingles (8-Bit set) |
| Digital Audio | https://kenney.nl/assets/digital-audio | spare arcade blips (not used yet) |

Kenney's classic 2D platformer pack ("Platformer Pack Redux") lives on
OpenGameArt as **Platformer Art Deluxe** (the kenney.nl catalog restructured
in 2025–2026; the new "Platformer Kit" is 3D):

| pack | page | used for |
|---|---|---|
| Platformer Art Deluxe | https://opengameart.org/content/platformer-art-deluxe | aliens (p1/p2/p3), grass/stone/dirt tiles, coin, springboard, hills bg, HUD coin |

Direct zip: https://opengameart.org/sites/default/files/platformerGraphicsDeluxe_Updated.zip

## Generated in-repo (no external source)

- `assets/audio/synth/*` — produced by `tools/gen_sfx.py` (numpy,
  deterministic output; safe to regenerate anytime).
- Launcher icon PNGs — rendered from `icon.svg` by `tools/rasterize_icons.gd`
  (run one `godot --headless --import` first).
