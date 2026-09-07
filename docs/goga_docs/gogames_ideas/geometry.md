# GEOMETRY FLASH — the owner's GDD, v0.3.6 (from the owner's message + drawing)

> The real Geometry Flash. Not a GD clone: GD ships pre-made levels; this is
> an **endless world generator** with the neon-filled GD feel. The PGB
> v1.3.8 pygame sketch is the grandfather; this is the rebirth.
> Asset study: Geometry Dash Lite 2.2.147 (APKPure, `tools/study/` first real
> mission) — THE USAGE LAW in force: study only, everything redesigned.

## 1. THE FEEL (owner's words, locked)

- **Neon that feels FILLED.** No empty outlines: every shape gets a real
  inner fill (gradient body + lit edges), GD-style dark body + bright
  structure lines, but recast in our neon identity. Gentle glow, never a
  mess — "the glow make it gentle and amazing".
- **No faces on the square for now.**
- **Cool VFX + melodic SFX** — "the SFXs are the most important stuff".
  Music matches the same feeling (energetic, satisfying, melodic).
- Dynamic everything: the jump is an ANIMATION, not a state (below).

## 2. SCREEN + LAYOUT (the owner's drawing = law)

Horizontal-only (`"orientation": "landscape"`, design 1920x1080 EXPAND).
Opens with **"TAP ANYWHERE TO START"** over a live idle world.

Vertical stack (design y, top→bottom):

| strip | surface y | notes |
|---|---|---|
| ROOF strip | 300 | solid ceiling; you stand UNDER it when gravity is up |
| line 3 | ~460 | platform segment (1 cell thick) |
| line 2 | ~620 | platform segment |
| line 1 | ~780 | platform segment — jump apex clears it "by a little distance" |
| GROUND strip | 940 | the default floor |

- Gaps between lines ≈ 160 design px ≈ 2 cells; the square (84 px) travels
  through them. **Jump apex ≈ 200 px** — higher than the next line by a
  little, so you can land ON a line or clip its underside while rising.
- The square's **default standpoint is BEFORE center** (x ≈ 0.32 * width) —
  after every push it drifts back there, never to center (reaction time).
- Use every pixel horizontally: obstacles ride all 3 lines + both strips.

## 3. THE RUN

- **Touch = jump.** That is the whole verb (plus what the mechanic does).
- **Golden orbits**: +1 score each, spawned in lines/arcs/waves in the open
  lanes. Twinkle anim (starAnim study), pitch-ladder pickup blip.
- **Every 10 score → world speed x1.1.** HUD shows both: score chip +
  "x1.00" speed chip + the mechanic chip next to them.
- **GOGACoin**: the first one waits 30-50 s from run start, then each next
  spawns 30/35/40/45/50 s after the last APPEAR (random pick). Floats at a
  reachable height; collect = real GOGACoins.
- **Pusher blocks** sit in the road ON the ground AND the roof: hitting one
  is not death — it HOLDS YOU BACK (shoves you left while overlapping). You
  can still jump; survive the overlap and you drift back to the standpoint.
  Pushed past the left screen edge = death ("out-of-screen from a block").
- **Pits**: the ground AND the roof have opened stretches. Fall into one =
  death (both gravities — the roof pits matter in flip modes).
- **Floating hazards** ride the line lanes. Touch = death. No enemies:
  **"the enemy here is just the wrong timing"**.
- Death (any): burst VFX + the run ends through the standard finish_run.

## 4. THE THREE MECHANICS (the surprise engine)

A hidden scheduler picks the next mechanic + its duration secretly:
duration ∈ {10, 20, 30, 40 s} random, next mechanic random (never the same
twice in a row). The swap lands mid-run with a flash + chime — the player
only learns from the **mechanic chip** next to the widgets:

| chip | mechanic | verb |
|---|---|---|
| ◯ + ↑ | **NORMAL** | tap = jump; gravity down; classic |
| ↑ ↓ (apart) | **FLIP** | tap ANYWHERE, ANYTIME = gravity inverts; you sail up/up/up, stick to the roof, tap again to drop back through the lanes |
| ↑⇵↓ (linked) | **STICKY** | tap ON a surface = jump + gravity flips WITH the leap — you arc off and stick to the far side; mid-air taps do nothing |

All three share the world; the generator weights hazards for the active
mechanic (roof content only matters when you can get there — and in FLIP/
STICKY you can, always).

## 5. THE SHOP

- **SKINS (5)** — the square's fill/edge identity (first owned free).
- **THEMES (3)** — the world's palette + VFX tint (first active free):
  each theme recolors bg, strips, lines, hazards, orbits' halo.
- **TAILS (6)** — none (default) / neon / fire / rainbow / gold / match
  (match = the square's own color). Buy once → toggle ON/OFF forever.
- No powerups (owner: skip for now). No enemies.

## 6. THE GENERATOR (endless, chunk-based, fair)

- Chunks of patterns stitched by a seeded rng; weights tighten with speed
  level: wider pits, longer pusher trains, tighter lane gaps, more hazards.
- THE FAIRNESS LAWS: every pit is jumpable at the current speed; solid
  landing ≥ 2 cells after any pit; a pusher never shares its cell-window
  with a pit or a hazard; orbit arcs always clear their pit; the first
  ~6 seconds are a calm runway (learn the feel before the first threat).
- Orbit patterns: straight lanes, arcs over pits, waves riding the line
  gaps, zigzags that teach the next mechanic's verb.

## 7. LAWS FROM THE OWNER (verbatim, binding)

- "a jump should rotate the body by 90 degree in a smooth way depending on
  the distance of the next surface colliding so it be a dynamic animation
  with dynamic VFX that changes based on distance and time"
- "the jump should be higher than the first platform line by a little
  distance so the square can jump to it or even hit it's bottom part"
- "the square if survived, will try to return to the center but before the
  center by a good distance so the user has time to realize what appeared"
- "both what comes next or when are hidden from the user so it feels
  surprising and fun"
- "tweak the algorithm ofc to be cool and the VFXs/SFXs are the most
  important stuff here"
- Test headless AND visual; collisions + movement solid before ship.

## 8. SHIP SHAPE

- Registry: the `geometry` SOON teaser graduates (landscape, price 350,
  needs_games 2 reveal kept, fee 10, coin_div 4, banner on).
- Achievements: score_100 / score_300 one-run + orbits + flips + triple.
- Thumbnail 960x640 composed from the real assets; guide = controls lines.
- version 0.3.6 / code base 30670. NO release (the law). Probes + QA rigs
  green, APKs built, pushed, CI watched.
