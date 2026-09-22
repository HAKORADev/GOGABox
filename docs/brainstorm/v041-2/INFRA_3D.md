# v041-2 — THE 3D INFRA (the groundwork the owner ordered)

"before you make the game itself, make sure that GOGABox infra and game
loader will handle a 3D scene" + "work on the infra too, so any future
3D game will work"

## THE PROVEN FACTS (probe_3d on the shipping renderer, gl_compatibility)

1. a Node3D world can live UNDER the Node2D host (no tree errors)
2. Camera3D + meshes + DirectionalLight3D shadows render (real screenshot)
3. 2D CanvasLayers (HUD, loader, sheets, popups) paint ABOVE the 3D world

## THE ARCHITECTURE (what actually changes)

### 1. game_base3d.gd — `class_name GogaGame3D extends Node3D`
The 3D twin of GogaGame (game_base.gd). Same contract, every var/signal/
method the host and the box chrome touch:
- signals: request_finish, request_quit, request_orientation_reload
- vars: game_id, score, run_coins, over, paused, pause_end_run,
  score_bonus_enabled, bonus_div_override, tk, start_orientation
- HUD: _build_hud (the top bar), set_score, add_score, add_run_coins,
  add_hud_button, add_hud_chip, set_hud_score_prefix, chip refs
- sheets: sheet_push/sheet_pop/sheet_open_count/_goga_sheet_popped,
  _back_pressed, the pause sheet, ensure_pause_for_box
- tap anywhere: tap_anywhere_start/stop/waiting (the universal overlay)
- achievements: achievement_count/max, check_achievements (the rule table)
- toasts, the box story, the game cursor seat, TouchKit wiring
- orientation_settled hook
WHY A COPY: game_base.gd is welded into 25 shipped 2D games (extends
GogaGame = Node2D). GDScript has no multiple inheritance, so a shared
base would force a base-type change across the whole shelf - the risk
the box never takes. The twin is isolated, zero-risk, and wears THE TWIN
LAW header: infra changes to one twin must be mirrored to the other.

### 2. game_coin3d.gd — `class_name Coin3D extends Node3D`
The 3D GOGACoin default (the coin.png of the 3D games):
- gold body: cylinder + rim ridges + the embossed face, StandardMaterial3D
  (metallic gold), the GOGA "G" face ring
- the pickup laws from the 2D coin: fade-in scale ramp (~0.35s), breathing
  pop, warm halo (billboard quad, additive), spin
- `collected()` API: pop + fly-up + fade for the pickup moment
- SCALE LAW: `design_px` helper - the caller states the on-screen size in
  design px at the play depth; Coin3D sizes the mesh so the projected
  diameter matches (2D coin.png rides at ~64 design px in the games)

### 3. host_node.gd — the dimension branch
- `var game: GogaGame` -> `var game: Node` (duck-typed: both twins carry
  the same contract; GDScript resolves dynamically)
- the brown bg CanvasLayer(-1) is a 2D thing: 2D renders ABOVE 3D, so for
  a "dim": "3d" game the bg is SKIPPED (the 3D world brings its own
  environment/sky). 2D games unchanged.
- everything else (loader, orientation, the design governor, sheets,
  finish flow) is already dimension-blind: CanvasLayers and Controls.

### 4. registry.gd — the dim field becomes real
Every entry already wears `"dim": "2d"`; nothing read it until now.
towerball wears `"dim": "3d"` + `"orientation": "auto"`. The host reads
dim at _ready (the bg branch). Future 3D games: set dim 3d + extend
GogaGame3D. THE 3D SEAT LAW for AGENTS.md.

### 5. the MSAA seat (quality law)
GogaGame3D._ready: `get_viewport().msaa_3d = MSAA_2X`; _exit_tree
restores the previous value. 2D games unaffected (msaa_3d only touches
3D rendering), the box menu never sees it (restored).

### 6. the loader (unchanged, proven)
Loader is a CanvasLayer(30) - it rides above the 3D world. The thumb
frame, the scan bar, the script + assets preload - all dimension-blind.

## THE INPUT TRUTH (the owner: "controls in 3D will not be different
than 2D in the GOGABox-side")
TouchKit + the box key translation (WASD->arrows, gamepad->arrows/keys,
ESC->back) all work unchanged - the game receives the SAME events a 2D
game receives. The 3D game maps screen-space events into its world
(rays, or design-space X for the paddle) - the box never learns 3D.
