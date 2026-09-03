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

## v0.3.0 — the Fruit Slasher classic set (provenance)

- `assets/games/slasher/classic/` — the classic fruit-ninja clone art
  (apple/banana/basaha/peach/sandia whole + two cut halves each, boom,
  flash glint, smoke) and `background.jpg` (the wood board): downloaded
  from github.com/ChineseDron/fruit-ninja (`release/images/`, the
  classic html5 clone set, 427 stars). The repo carries NO license file;
  the set is the widely-mirrored clone art used by countless tutorial
  ports. GOGABox is a personal non-commercial project — if this ever
  goes commercial, replace the set (the hunt log: Kenney = JS-gated,
  OGA 2d-fruits = pixel art CC0, OGA fruit-and-vegetables = CC-BY-SA
  sample, jaredly/fruit-ninja-assets = crayon style no-license,
  WayToSucceed pack = flat style with halves, reviewed).
- `wood_portrait.png` / `wood_landscape.png` — composed from that
  background.jpg (mirrored tiling + vignette), tools inline in the
  session log.

## v0.3.1 patch II — the Cursed Dario overhaul (provenance)

The owner judged the v0.3.1 painted set "trash" and ordered a hard hunt
("try hard because this is the most critical step in this whole game").
Hunted via GitHub mirror search (the itch.io / kenney.nl storefronts stay
JS-gated to bots), reviewed with contact sheets, and vendored:

- `assets/games/dario/` — **Pixel Adventure** by Pixel Frog
  (pixelfrog-assets.itch.io/pixel-adventure-1). The itch page licenses it
  free for commercial and non-commercial use; vendored from the public
  mirror `github.com/marpor/PixelAdventure` (its README calls the set
  public domain). In the game: Pink Man (idle/run/jump/fall/hit), Snail,
  Bat, Plant (+bullet), Rino, the spiky Turtle (REAL spikes-in /
  spikes-out frames), Ghost (the Witcher's base), terrain tiles (grass /
  dirt / bricks + the studded mover deck), crates (the ? overlay is
  painted on), spikes, fire, falling platforms, the End trophy, the
  trunk bullet (recolored purple = the curse bolt).
- `assets/games/dario/bg_far.png` / `bg_mid.png` — **Sunny Land** by
  Ansimuz (ansimuz.itch.io/sunny-land-pixel-art), licensed free for
  commercial and non-commercial use; vendored from the public mirror
  `github.com/Kevin1321/DA_Module_12_SunnyLand` (the forest background +
  middleground parallax layers).
- The Witcher = the PA Ghost recolored cursed-lavender with a pixel
  witch hat baked on (`tools/v031b_dario_art.py` — the whole compose is
  reproducible from that script).
- The GOGACoin keeps its own `item_coin.png` (the Box-wide currency
  identity). All sliced/pre-scaled nearest-neighbor only; the hunt
  review sheets live in the session log (`hunt/r1..r8`).
- The synthesized dario voices (v031_sfx) are unchanged; the slasher
  whoosh family was REMOVED by owner law (silence is the slash).

## v0.3.2 — Space Invaders (provenance)

- `assets/games/invaders/ship_*.png` (the 7 SSDS hulls) — **derived from the
  same Kenney Space Shooter Redux + Extension hulls the box already vendored
  for Space Dash** (CC0; see the `kenney-space-shooter-redux` /
  `kenney-space-shooter-extension` sources in
  `projects/gogabox/assets.manifest.json`). The owner's own call: "edit some
  ships and change their size and colors" — hue-shift, recolor, cockpit glow
  and gun-pod mounts are applied by `tools/v032_invaders_art.py`.
- Everything else under `assets/games/invaders/` (11 enemy kinds, 10 bosses,
  11 planet plates, all projectiles/VFX/items) is **painted from scratch** by
  `tools/v032_invaders_art.py` (PIL, deterministic, 4x supersample) in the
  box's own flat-alien style — CC0-clean, no third-party source.
- The planet plates carry REAL-WORLD data in their design (the owner's law):
  Neptune's 2,100 km/h wind streaks + dark storm, Uranus's 98°-tilt vertical
  ring, Saturn's ring band, Jupiter's bands + Great Red Spot, Mars's dust
  veils + two moons, Earth's cloud swirls + the Moon, Venus's 465° sulfur
  deck, Mercury's 430°/-180° day-night split, the Sun's 5,500° flare loops,
  and the Hideout's reactor-veined megastructure.
- All `inv_*` voices + the two music loops (`inv_tour`, `inv_finale`) are
  synthesized by `tools/v032_invaders_sfx.py` (numpy, deterministic) — no
  samples, no licenses to carry.

## v0.3.2 PATCH I — the owner playtest round (provenance updates)

- **THE SHIPS ARE THE DASH SHIPS, LITERALLY**: the divergent
  `assets/games/invaders/ship_*.png` copies were DELETED; the engine now
  loads the Space Dash hulls straight from `assets/games/lanes/`
  (ship_blue/orange/green/veteran/phantom/horn/titan — the same Kenney CC0
  files Space Dash flies). One universe, one fleet. The Mimic boss is the
  Azure hull's recolored evil twin by design (lore).
- `assets/games/invaders/en_*.png` (11 kinds) — **derived from the Space Dash
  enemy hulls** (`enemy_grunt/grunt2/runner/shooter/splitter/tank/shielded/
  shatter/ufo_red/ufo_green/ufo_yellow`), gentle per-kind hue tints + 1.6x
  upscale, by `tools/v032b_patch_art.py`. The family stays obvious on purpose.
- `assets/games/invaders/boss_*.png` (10) — **big layered originals** (340..560
  px, nose-down, armor plates + glowing cores + per-boss signature structures)
  repainted by `tools/v032b_patch_art.py` + `tools/v032b_boss_fix.py`.
- **THE SKY IS SPACE DASH'S SKY, LITERALLY** (patch II): the painted bg
  plates were DELETED. The tour wears the same `bg_space.gdshader` Space Dash
  flies (deep base + additive nebulae + two twinkling parallax starfields +
  the near drifting star sprites), tinted PER PLANET through the shader's four
  palette uniforms - the real-world data lives in the PALETTE (Neptune's storm
  blues, the Sun's burn, the Hideout's void violet). Without the Stage Themes
  pack the tour wears Space Dash's own Deep Blue; buying the pack lerps each
  world's palette in over ~1.5s. The owner: the sky must be "the space dash
  BGs designs" - now it is, byte for byte.
