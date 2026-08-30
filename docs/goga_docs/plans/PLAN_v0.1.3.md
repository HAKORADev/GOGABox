# PLAN v0.1.3 — THE RESOLUTION & SCALE SYSTEM (owner: "fix it, do the work")

Status: DONE. Every item below is implemented, test-verified, built and
pushed. Source of truth for the rule itself: docs/RESOLUTION_RULE.md section 8
+ game/core/scale_rule.gd.

## 1. The owner evidence (three device screenshots, v0.1.2)

- `opened_as_vertical.jpg` — portrait boot LETTERBOXED: the 16:9 design
  letterboxed with black bars top/bottom on the taller FHD+ panel.
- `opened_as_horizontal.jpg` — landscape boot showed the PORTRAIT design
  dead-center with black side bars: the design decision missed the real
  window state and nothing re-decided it.
- `opened_as_vertical_then_switched_in_app_to_horizontal_then_returned_to_vertical.jpg`
  — the rotation ping-pong left a squashed hybrid layout floating in black.

Owner contract: "work hard on the resolution handler and scaling system to
manage the aspect ratios and resolutions for the phone window while keeping
internal resolution the same for the app" — fill the window, keep the design.

## 2. What shipped (all checked)

- [x] **ScaleRule** (`game/core/scale_rule.gd`): the ONE source of truth —
  the two fixed designs (1080x1920 / 1920x1080), `want_for()` (real window
  px -> design), `apply()` (idempotent governor primitive),
  `scale_of()` (real px per design px), `safe_insets_design()` (OS cutout /
  status / gesture insets as design px).
- [x] **aspect EXPAND** (project.godot): the design is the MINIMUM canvas;
  the engine grows it to cover ANY window edge-to-edge. Letterbox bars are
  RETIRED (owner: "you said letterboxed and i have never said that").
- [x] **The governor** (`main._process` -> `menu.apply_resolution()`):
  per-frame re-decide from real window px while no game runs; a missed
  rotation signal self-corrects within one frame. size_changed hook kept
  for same-frame swaps.
- [x] **Safe-area margins** (`menu._apply_safe_margins`): notch/status/
  gesture insets padded per side into the page margins (landscape phones
  wear the notch on a SIDE); banner_safe recomputed per design swap.
- [x] **host_node**: `_apply_orientation` uses ScaleRule constants;
  `_restore()` decides from the REAL window px (the blind portrait pin is
  gone — no flash, no stuck design).
- [x] **Background shader**: pattern space = the LIVE canvas (`canvas`
  uniform, `menu._bg_canvas_update`) — 45° stripes at the measured period
  on every phone at any expansion; sheen sweep spans the real canvas height.
- [x] **Battery ping REVERTED to FULL** (owner final call, v0.1.2's
  round-ping retired): in-app SFX fires when a pool charges back to
  COMPLETELY FULL (game pools + the box bank on resume credit). Signal
  renamed `battery_full_reached`; `_round_need()` deleted (dead).
- [x] **Tests**: flow_test battery rules rewritten (full-pool ping once,
  no repeat while full, silent below full, bank fills -> ping); restore
  check = ScaleRule-honest. geometry_probe rebuilt: 15-window aspect
  matrix + end-to-end EXPAND verification + rotation ping-pong.

## 3. Verification results (this build)

- flow_test: ALL SUITES PASS (incl. "batteries: pools, consumption, refill").
- geometry_probe: PASS — matrix 15/15, design applied at both orientations,
  visible canvas == EXPAND math, FIT on every step of the ping-pong.

## 4. Why the v0.1.2 landscape fix failed on device (the honest post-mortem)

v0.1.2 decided from real window px but the decision only RAN when a signal
happened to fire (`size_changed`, `set_active(true)`) — and Android surface
timing fired neither reliably at boot-in-landscape, leaving the portrait
design letterboxed (screenshot 2), while the KEEP aspect made every non-16:9
window look broken (screenshot 1) and the design swap race on double
rotation left the landscape design in a portrait window (screenshot 3).
v0.1.3 removes the dependence on timing entirely: EXPAND cannot show bars,
and the governor re-decides every frame — the bug class is dead, not patched.

## 5. Version

- versionName 0.1.3, versionCode base 30220 (arm64 30222, arm32 30221).
- Cert chain unchanged (SHA-256 6db87aca...), overwrite-install safe.
