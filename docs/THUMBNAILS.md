# THUMBNAILS — how every GOGABox thumbnail is made

**Read this before touching any `assets/thumbs/*.png`.** This is the
operational playbook (written for the dev, approved by the owner in the
v0.1.6 chat). The rules-history lives in
`docs/goga_docs/ideas/THUMBNAILS.md`.

The pipeline lives in `projects/gogabox/dev/thumb_capture/` and is
**EXCLUDED from every export preset** (`exclude_filter="dev/*"`) — the
capture tooling never ships to players; only the finished PNGs ship.

---

## 1. THE LOCKED RULES (owner-approved — never drift)

| # | Rule |
|---|------|
| R1 | **Every thumbnail is 960x640.** Real games, SOON tiles, mystery, future 3D — one canvas. |
| R2 | **Real-game thumbs carry NO baked text** — no title, no description. The feed tile already shows the name. |
| R3 | **If text is ever required** (owner says so for a specific game): use that **game's own font** when it has one; only fall back to the box font (Kenney) when it doesn't. |
| R4 | **SOON + mystery keep their own design** (striped "?" + title + SOON at 960x640; the mystery tile art `assets/ui/mystery.png` is untouched). |
| R5 | **Real games run at their NATIVE design resolution** (portrait 1080x1920, landscape 1920x1080) and the chosen frame is **downscaled** to 960x640 — never render the game scaled. |
| R6 | **No video previews. Ever.** The dynamic/AI-played idea is explicitly shelved — "let the player just play the game." Don't re-raise it. |
| R7 | **The tooling stays out of the shipped build** (see the exclude above). |
| R8 | The owner may order, per game, at any time: a fully manual design, or a capture + on-top edit, with or without text. The pipeline must allow all of that. |

## 2. THE PIPELINE (capture -> review -> install)

```
 drive (auto-pilot)   capture (real engine render)   post (crop+resize)   vision review   install
 <id>_drive.gd  -->   capture.tscn (native res)  -->  post.py  -->  (human/AI picks)  -->  assets/thumbs/<id>.png
```

### Step 1 — write the drive: `dev/thumb_capture/drives/<id>_drive.gd`

A drive is the game's **attract mode**: a tiny auto-pilot that plays the
real game honestly so frames look like someone is playing. API:

```gdscript
extends Object
var game: GogaGame          # the live game node (typed by convention)
func segments() -> Array:   # OPTIONAL - multi-scene/level games
    return [{"name": "lava_room", "at": 12.0}]   # tags frames: <id>_t0012.0_lava_room.png
func tick(t: float) -> void:                     # called every frame
    ...poke the game's public state (steer, move paddle, swipe)...
```

Drive-writing rules of thumb (all learned the hard way — see §4):
- Play honestly but photogenically: chase the objective, keep a little
  tracking error so poses look human.
- **Auto-restart on death** or a long run ends in frozen frames. A dead run
  routes through `finish_run()` which sets `game.over = true` — your
  restart MUST clear `game.over = false` or the game freezes forever.
- Restart helpers must clean up what the game's own re-init leaks (snake's
  `_new_snake()` never frees old segment sprites — free them yourself).
- Poster composition in the drive is ALLOWED and owner-approved (his
  matcher example: "make the grid, fade it, add 3 candies on top"): center
  boards, zoom the game node (`game.scale`), stage courts (reposition
  paddles), then let the real game run. Real assets, real physics, staged
  framing. Document what you staged in the drive header.
- **Guard the harness renderer**: the capture sandbox renders at ~20fps
  (llvmpipe). Fast projectiles can tunnel through bounce windows — clamp
  speeds and rescue escaped balls in the drive (see rally_drive).

### Step 2 — capture (real engine, native resolution)

```bash
# from the repo root (Xvfb + GL renderer; headless cannot render frames):
Xvfb :99 -screen 0 1920x2200x24 -nolisten tcp &
DISPLAY=:99 .cache/godot/bin/godot --rendering-driver opengl3 \
  --path projects/gogabox res://dev/thumb_capture/capture.tscn ++ \
  --game=snake --time=40 --every=0.5 --seed=7 --out=/tmp/thumbs_raw
```

- `--game` any registry id, or `all`
- `--time` total sim seconds (**modifiable by design** — 20, 40, whatever)
- `--every` seconds between candidate frames (default 0.5)
- `--seed` reproducible runs — seed-hunt for photogenic runs
- `--out` ABSOLUTE output dir; frames land as `<id>_t00031.5[_segment].png`
- `--hud` keep the in-game HUD (default: hidden for the poster look)
- `--w`/`--h` override native size (rare — rule R5 says native)

### Step 3 — post: `dev/thumb_capture/post.py`

```bash
cd projects/gogabox/dev/thumb_capture
python3 post.py --raw /tmp/thumbs_raw --out /tmp/cooked --game snake --focus 0.5
# focus = which 3:2 band of the native frame (0=top, 1=bottom); sweep it:
python3 post.py --raw ... --out ... --all-focus 0.3,0.45,0.6
# emit a final:
python3 post.py --raw ... --out ... --focus 0.5 \
    --pick snake_t00031.5.png --final-name snake_FINAL.png
```

Native portrait 1080x1920 -> full-width 1080x720 band -> LANCZOS 960x640.
Native landscape 1920x1080 -> 1620x1080 side-crop -> 960x640.

### Step 4 — the vision review (the "review it over and over" pass)

Build/contact-sheet it (`post.py` writes `_sheet.png` per game), then LOOK
at the candidates and pick the winner by these criteria:
- instant readability of the genre at tile size,
- the game's real assets in motion (a long snake, a ball ON a paddle),
- a storytelling beat (about-to-eat, about-to-return),
- no HUD chrome, no death-red tint, no frozen/duplicate ghosts,
- the objective item visible (apple/coin/ball).

Run multiple seeds (`--seed`) and pick the best run — this is cheap and it
is the single biggest quality lever. Winning recipes so far: snake = 40s
run, last-third frames, seed 3; rally = staged court + contact-moment
frames.

### Step 5 — install + prove

```bash
cp /tmp/final_candidates/<id>_FINAL.png projects/gogabox/assets/thumbs/<id>.png
```
Always produce a before/after sheet (old vs new side by side) and keep it
for the owner — quality bar: "make sure the thumbnails will look really
better". v0.1.6 proof: `download/thumbs_before_after.png`.

## 3. OPTIONAL POST-DESIGN (owner-approved, per game, opt-in only)

For games whose raw play reads boring (owner's example: **matcher** — a
flat grid is dull), compose on top of a captured frame with PIL:
1. `frame = capture.pick(...)` — the real grid mid-play,
2. fade it (`Image.blend(frame, dim, alpha≈0.35)`),
3. paste 2-4 real game sprites (from `assets/games/<id>/`) large and
   arranged with intent,
4. optional text per R3 (game font first: `assets/games/<id>/font*.ttf`,
   else Kenney) — with the same drop-shadow style the old titles used.
Everything stays in `post.py`'s spirit: real capture as the base, design
on top, never fake screenshots.

## 4. TRAPS ALREADY SURVIVED (do not rediscover them)

- **headless cannot render** — `--headless` gives dummy frames. Use Xvfb +
  `--rendering-driver opengl3` (llvmpipe). Raw `Xvfb :99` + `DISPLAY=`
  (xauth is missing in the sandbox, so `xvfb-run` fails).
- **`finish_run()` sets `over=true`** and `_process` stops ticking — attract
  restarts must clear it.
- **snake `_new_snake()` leaks sprites** — free `_nodes` sprites before
  re-initializing or ghosts pile up.
- **llvmpipe ~20fps + ramping ball = tunneling** through paddle bounce
  windows; cap speeds and rescue escaped balls in the drive.
- **game boards may spawn left-aligned** (device-agnostic code) — center
  them in the drive for the poster.
- **the preset patcher is line-preserving** — `exclude_filter="dev/*"`
  survives `build.sh`.

## 5. STATUS (v0.1.6)

| Game | Thumb | How |
|------|-------|-----|
| snake | 960x640 CAPTURED | 40s run, seed 3, focus 0.5, long-snake-about-to-eat |
| rally | 960x640 CAPTURED | staged court, 30s seed 9, focus 0.583, ball-on-paddle contact |
| lanes / slasher / hopper / merge | legacy 720x480 hand-drawn | pending capture drives (same pipeline) |
| 8x SOON tiles | 960x640 generated | `derive_assets.py _thumbs_soon()` |
| mystery | unchanged (tile art) | rule R4 — never touched |

Adding a NEW game: registry entry + `assets/thumbs/<id>.png` — either a
capture run with a drive (preferred) or a SOON-style placeholder until the
game is playable. See also `docs/ADDING_A_GAME.md`.
