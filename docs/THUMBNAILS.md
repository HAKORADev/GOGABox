# THUMBNAILS — how every GOGABox thumbnail is made

**Read this before touching any `assets/thumbs/*.png`.** This is the
operational playbook (approved by the owner in the v0.1.6 + v0.1.7
chats). The rules-history lives in
`docs/goga_docs/ideas/THUMBNAILS.md`.

## 1. THE LOCKED RULES (owner-approved — never drift)

| # | Rule |
|---|------|
| R1 | **Every thumbnail is 960x640.** Real games, SOON tiles, mystery, future 3D — one canvas. |
| R2 | **Real-game thumbs carry NO baked text** — no title, no description. The feed tile already shows the name. |
| R3 | **If text is ever required** (owner says so for a specific game): use that **game's own font** when it has one; only fall back to the box font (Kenney) when it doesn't. |
| R4 | **SOON + mystery keep their own design** (striped "?" + title + SOON at 960x640; the mystery tile art `assets/ui/mystery.png` is untouched). |
| R5 | **The method must scale to 3D games** (composition, not pixel tricks). |
| R6 | **No video previews. Ever.** "Let the player just play the game." Don't re-raise. |
| R7 | **The tooling stays out of the shipped build** (`tools/*.py` are non-resource files; `dev/` is export-excluded via `exclude_filter="dev/*"`). |
| R8 | The owner may order, per game, at any time: a fully manual design, or any hybrid, with or without text. The composer must allow all of that. |

## 2. THE WAY (v0.1.7): the programmable composer

```
tools/thumb_composer.py        <- THE maker (owner call, Aug 2026)
  spec dict per game     ->    Scene() primitives    ->    960x640 PNG
  ("pose the snake")           (real game assets)          (deterministic)
```

Every thumbnail is a **posed scene in code**. The heart of the system is
the per-game SPEC — plain dicts the dev re-tunes in seconds when the owner
says, verbatim: *"make the snake appear with tail to be up to 9 and
straight to left then straight to up before apple by 3 steps"* →

```python
SNAKE_SPEC = dict(
    board=(9, 7),                 # cols x rows of the poster board
    cell=84,                      # px per cell
    length=9,                     # "tail to be up to 9"
    path=[("L", 5), ("U", 3)],    # "straight to left then straight to up"
    apple=("ahead", 3),           # "before apple by 3 steps"
    coin=(7, 2),                  # stage a GOGACoin in the open space
)
```

That sentence IS the spec. Direction runs (`L R U D` + length) start at
the TAIL; the head is the end of the path and faces the last run; the
apple sits `("ahead", n)` cells beyond the head **and is included in the
fit box** (a pose that cannot fit its board raises a clear error instead
of clipping).

### The primitives (`Scene`)

- `backdrop(top, bottom)` / `solid(rgb)` — the base layer.
- `rect / line / ellipse / polygon` — shapes on the working layer.
- `stamp(img_or_path, cx, cy, scale, rot, alpha)` — **real game sprites**
  from `assets/games/<id>/`, center-anchored (the only honest art source).
- `glow(cx, cy, r, rgb, alpha)` — true radial halo (key objects pop).
- `fade_below(alpha)` — the owner's matcher recipe: *"make the grid, fade
  the image out a little, composite 3 candies on top"* — everything drawn
  so far fades to `alpha`, a fresh layer opens.
- `vignette()` / `text()` — finish + SOON/opt-in text only (rule R2).
- `grid_dir_rotation(fx, fy)` — rotate an UP-facing sprite to face `fx,fy`.

### CLI

```bash
python3 projects/gogabox/tools/thumb_composer.py --game snake --out /tmp/x.png
python3 projects/gogabox/tools/thumb_composer.py --all          # install all thumbs
python3 projects/gogabox/tools/thumb_composer.py --sheet /tmp/sheet.png
python3 projects/gogabox/tools/thumb_composer.py --compare OLD_DIR /tmp/cmp.png
```

`--all` writes straight into `assets/thumbs/` — the same contract
`derive_assets.py thumbs()` delegates to, so a full asset re-derive can
never regress the thumbs (the old inline 480x320 scenes are deleted).

### Design bar (what "better" means here)

- **One glanceable story per thumb**: snake about-to-eat, ball just
  smashed, X one cell from the winning row, hero mid-leap over a pit.
- The objective item glows; everything else stays calm.
- Real assets only — if the game has no sprite for it, draw it into
  `derive_assets.py` (see `dario_sprites()`) and stamp that.
- Check the sheet at TILE size (480x320 preview) — that's how it ships.
- Always produce a before/after sheet for the owner (`--compare`).

## 3. PARKED (v0.1.6): the real-gameplay capture pipeline

**Owner call (v0.1.7 chat, Aug 2026): automated capturing is NOT
recommended at this point** — the captured frames lost to hand-designed
scenes ("the gameplay capturing is not that good yet, i still prefer the
hand-drawn one"), and games will keep changing, so crafting final shots
is premature anyway. The harness stays in the repo because it WORKS and
because it is half of the video-dream infrastructure — but do not extend
it for thumbnails now.

What exists if it ever comes back:
- `projects/gogabox/dev/thumb_capture/` — `capture.tscn` (native-res
  offscreen render via Xvfb + GL), `drives/<id>_drive.gd` (per-game
  auto-pilot), `post.py` (focus crop + 960x640 + contact sheets).
- `exclude_filter="dev/*"` keeps it out of every APK.
- Traps survived there (documented for archaeologists): headless cannot
  render (needs Xvfb + opengl3), `finish_run()` sets `over=true`,
  snake's `_new_snake()` leaks sprites, llvmpipe ~20fps tunnels fast balls.

## 4. STATUS (v0.1.7)

| Game | Thumb | How |
|------|-------|-----|
| snake | 960x640 COMPOSED | the owner's literal pose spec (9-long L, apple 3 ahead) + staged coin |
| rally | 960x640 COMPOSED | court spec: paddles, net, ball just smashed off the player |
| lanes | 960x640 COMPOSED | near-miss spec: block nose-down above the ship |
| slasher | 960x640 COMPOSED | fruit arc + blade trail + bomb spec |
| hopper | 960x640 COMPOSED | climb spec: zigzag platforms, player mid-air |
| merge | 960x640 COMPOSED | board spec: real 4x4 grid, 1024 snake pattern |
| dario | 960x640 COMPOSED | leap spec: hero over the pit, coins, walker, flag |
| xo | 960x640 COMPOSED | board + ladder spec: near-win row, marker on rung 6 |
| 6x SOON tiles | 960x640 generated | `SOON_NAMES` in the composer (shrinks as games ship) |
| mystery | unchanged (tile art) | rule R4 — never touched |

Adding a NEW game: registry entry + a scene function in the composer +
its SPEC dict (or a SOON placeholder until the game is playable). See
`docs/ADDING_A_GAME.md`.
