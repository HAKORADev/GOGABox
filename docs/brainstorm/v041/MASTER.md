# v041 — THE BIG PATCH (the owner's mixed report worked to the bone)

> Source: the owner's Windows-first test report (v040-17 build) — game bugs,
> PC build issues, and the v040-14/15 reports all at once. Version law: this
> is **v041** (config 0.4.1), NOT a v040 patch. After it: LAN = v042.
>
> Every item here gets a numbered entry in the final report to the owner.

## 1. THE BOX — WINDOWS / SCALING (the infra round)

- [ ] **1.1 THE DESIGN FOLLOWS THE CONTENT LAW** — root kill of the vertical
  fullscreen corruption. The design (portrait/landscape) is decided by the
  CONTENT (menu orientation, game orientation), never by the window aspect.
  In fullscreen on a 16:9 monitor the portrait menu kept getting force-fed
  the LANDSCAPE design by the governor (ScaleRule.apply reads window px) —
  that is the owner's "vertical fullscreen is currently horizontal but tries
  to look like vertical", the mis-targeted clicks, and the clickable black
  sides (the canvas expanded over the whole monitor). Phones keep the old
  window-px rule (the window IS the screen).
- [ ] **1.2 PC = KEEP + BOX-BROWN, everywhere** — on PC the stretch aspect is
  ALWAYS KEEP (the vertical slice law generalized): windowed windows are
  reshaped by re_window to match the design, fullscreen/off-aspect windows
  get brown bars — never black, never stretched, and bar clicks land outside
  the canvas (dead, like they should be).
- [ ] **1.3 THE EDGE VEIL LAW (the Spotify-like theming)** — when bars exist,
  the app edge wears a soft inner shadow so the app feels like it FLOATS
  above the brown sides. No per-pixel dominant-color theming (the owner:
  "spotify takes the most used color... but here it will be bad").
- [ ] **1.4 THE FULLSCREEN RECALC LAW** — fullscreen flips re-apply the design
  on a fresh frame (never mid-transition), the stretched→fullscreen→restore
  scale bug dies with the content-driven design.
- [ ] **1.5 THE SHARPNESS LAW** — canvas default filter = Linear Mipmap +
  mipmaps generated on the 2D raster art (thumbs, icons, sprites): PC
  windows render the 1080x1920 design downscaled (0.66-0.75) and the mips
  kill the jagged edges (XO thumb, snake thumb) and the cloud-ish sampling.
- [ ] **1.6 DYNAMIC SCALE (the FSR law)** — settings Graphics toggle, OFF by
  default, no restart: a full-frame FSR1-RCAS sharpening pass (the honest
  part of FSR that works on 2D, all GPUs — AMD/NVIDIA/Intel; FSR4.1 itself
  is RDNA4 ML tech that cannot ride a 2D GL app).
- [ ] **1.7 THE ICON LAW** — a real multi-size .ico (16-256) built from the
  logo, wired as the windows native icon: taskbar / task manager / window
  all wear the SAME face.
- [ ] **1.8 F10 + THE POSITION TOGGLE** — F10 flips the MENU position
  (vertical/horizontal), main menu only (never in-game), also a row in
  Screen settings, persisted.
- [ ] **1.9 THE ESC LAW** — ESC = the phone back button, 1:1 (pause game →
  close sheet → leave box).
- [ ] **1.10 THE ARROW LAWS** — Up/Down scroll the feed; at the top,
  Left/Right scroll the picks row; Tab+Left/Right switch the picks LIST
  (TODAY'S PICKS → LAST PLAYED → ...); arrows keep working in games.
- [ ] **1.11 THE FOCUS NUKE** — buttons never take keyboard focus; Tab and
  arrows can never walk between buttons (the unwanted focus ring family).
- [ ] **1.12 THE GAMEPAD SEAT** — dpad = arrows, A/B/X/Y = keys 1-4, Start =
  ESC; wired and advertised for 4 games (snake, rally, invaders,
  brickbreaker) to start; the box never breaks without a pad.
- [ ] **1.13 THE GOGACURSOR** — golden pixelated cursor, brown outlines,
  click/hold frame; toggle in Screen settings; games with their own cursor
  (Heavy War's reticle) own the pointer; box sheets (pause/shop) always
  bring a pointer back.
- [ ] **1.14 THE UNFOCUS PAUSE LAW** — app loses focus (both platforms):
  in-game → the pause sheet opens + master bus mutes; menu → mute only.
  Coming back keeps the pause up — the player presses RESUME (prepare to
  return, no half-second freeze-then-jump).
- [ ] **1.15 THE SPLASH FLICKER KILL** — the v010-era feed-flick: the whole
  splash root (opaque veil INCLUDED) faded in over 0.3s, so the feed
  showed through for those frames. The veil is now opaque from frame zero;
  only the logo fades.
- [ ] **1.16 THE DOOMSCROLL LAW** — the old 64-78px banner reserve at the
  feed's bottom is reclaimed (feed runs to the last pixel) and the bottom
  wears a dark-brown bottom-up shade + subtle side fades (both platforms).
- [ ] **1.17 THE SETTINGS REWORK (AAA shape)** — SETTINGS = [AUDIO] (music +
  sfx sliders), [SCREEN & GRAPHICS] (PC only; Screen: fullscreen + position,
  Graphics: Dynamic Scale + GOGACursor), [CONTROLS] (PC only; the GOGABox
  keys listed with their use), then RESET ALL PROGRESS over CLOSE as now.
- [ ] **1.18 PLATFORM TAGS BACK** — the os tag rides every pre-play page
  header again (it lived in search + guide only).
- [ ] **1.19 THE CONTROLS TAGS** — per-game control-scheme chips (touch /
  mouse+keyboard / gamepad) with icons in the tag-icon style, on the
  pre-play page + guide.
- [ ] **1.20 THE GUIDE REWORK** — HOW TO PLAY first (universal wording), then
  CONTROLS split into TOUCH / GAMEPAD / MOUSE+KEYBOARD with the new icons —
  never platform-branded (a phone can get a gamepad).
- [ ] **1.21 THE TAP-ANYWHERE LAW** — one universal full-screen tap overlay
  in game_base; every intro ("tap anywhere to start") covers the WHOLE
  screen (marble needed a middle-bottom click before, both platforms).

## 2. MARBLE POPPER (v040-14 report)

- [ ] 2.1 thumbnail = a code-programmed in-game capture
- [ ] 2.2 tap anywhere uses the universal overlay (2.1's law)
- [ ] 2.3 PC: RMB switches the shot, LMB fires, the idol follows the cursor
- [ ] 2.4 ghost-chain preview = a moving sparkle line, never real marbles
- [ ] 2.5 the jaw/hole layering: marbles ride OVER the jaw; jaw under the
  mouth arch, head over — the current jaw-over-hole render is wrong
- [ ] 2.6 THE POP-BACK LAW: after a pop, the part TOWARD the hole rolls BACK
  to meet the rear part (faster), the rear stays; rolling marbles keep
  their colors
- [ ] 2.7 the rolling looks like rolling: marbles rotate along the path
  direction (up-down over the chain), not the left-right self-spin
- [ ] 2.8 THE LIVING INSERT: the shot physically slides in — the forward
  part is pushed one spacing over time while the shot sneaks in; nothing
  teleports
- [ ] 2.9 pop VFX wears each popped marble's color
- [ ] 2.10 powerup marbles: icon in the center only, normal fixed color,
  match-popped like any marble (no rainbow any-shot magnet)
- [ ] 2.11 VAPOR: a majestic marble — the hit removes the chain with a
  staggered dissolve (matcher-style), never an instant clear
- [ ] 2.12 the shooter never loads an extinct color: when a color leaves the
  level, the loaded/next marbles re-roll into existing colors on the fly
- [ ] 2.13 the dev cheats sheet re-opens without restarting the app

## 3. GOLD MINER (v040-15 report)

- [ ] 3.1 thumbnail = a code-programmed in-game capture (no more mud shot)
- [ ] 3.2 the "tap anywhere" intro shows NO floating miner in the sky
- [ ] 3.3 the miner rig stands ON the land surface (not sunk)
- [ ] 3.4 nothing crosses the screen edges — the swing/field clamps to the
  visible walls (no reeling things from out-of-resolution ground)
- [ ] 3.5 rocks pay NEGATIVE: -2/-4/-6 by size (gold stays +1/+2/+3)
- [ ] 3.6 rocks ARE traps: generator places them as real danger around gold
  (bombs included), not decoration

## 4. THE SMALL-GAMES ROUND

- [ ] 4.1 Fruit Slasher — slash particles no longer flash at the top-left
- [ ] 4.2 DOMINO — the 0/0 (double) tile sits PERPENDICULAR to the line
- [ ] 4.3 Heavy War — PC: arrows drive the tank, the mouse aims and shoots
- [ ] 4.4 Cosmic Spud — arrows drive the ship; the belly bars and head
  bubbles are gone
- [ ] 4.5 Space Invaders — PC: the ship follows the cursor, LMB shoots
- [ ] 4.6 THE FIXED STEERING LAW — finger-steering games (brick breaker,
  pong, snowy tower, space invaders) run FIXED per-game speeds under
  keyboard arrows (binary keys can never fake force detection)

## 5. SNAKE — SURVIVAL MODE (from the pending todo; spec = the owner's words)

- [ ] 5.1 built per the pending.md laws (submode, open/closed walls, big
  land + camera, feast, 5+ gate, no bugs/obstacles, slowdown, huge growth,
  parts scoring, bonus /100) — pending.md updated: only LAN stays pending

## 6. HOUSEKEEPING

- [ ] 6.1 version v041 everywhere (config/projects.json both spots, exe
  preset stamp, any in-app print)
- [ ] 6.2 probes + flow_test green; window_probe extended for the new laws
- [ ] 6.3 thumbnails captured for marble + goldminer (and fourline check)
- [ ] 6.4 docs truth: RESOLUTION_RULE + AGENTS.md + CI.md wear the new laws
- [ ] 6.5 CI stays 0-warnings (Node 24 majors + ubuntu-24.04 already pinned
  in v040-17 — verify the workflow files)
- [ ] 6.6 push; both builds green; the owner gets the numbered report
