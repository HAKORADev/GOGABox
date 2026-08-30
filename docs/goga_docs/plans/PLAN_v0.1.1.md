# PLAN v0.1.1 — the universal resolution + owner feedback round

Owner feedback after testing v0.1.0 on the FHD phone. Every item below is
implemented in this build. English-only rule in force.

## 1. Universal resolution (the big one)
- [x] ONE internal design per orientation: 1080x2400 portrait / 2400x1080
  landscape (owner phone FHD = the universal one; other devices scale).
- [x] stretch canvas_items + aspect KEEP (letterbox bars in box brown).
- [x] density rule deleted; menu._apply_base + host_node._apply_orientation
  swap the two pre-set designs — rotation switches DESIGN, never scale.
- [x] structurally kills "landscape phone opened a portrait game and it
  rendered with the old orientation's resolution, too small".
- [x] geometry_probe rewritten: probes BOTH designs, nothing else.
- [x] RESOLUTION_RULE.md section 6 documents the final rule.

## 2. Wording + chips
- [x] "UNLOCKED!" badge -> "AVAILABLE!" (it means buyable; you still have to
  purchase the game — "unlocked" was misleading).
- [x] OWNED tiles: "ready to play" ONLY when the pre-play PLAY button would
  really open (new oracle Roadmap.can_play_now: fee + game pool + BOX BANK +
  time window — the button itself was also blind to the box bank, fixed).
- [x] "best nn" moved to the tile's RIGHT edge, all owned games incl. snake
  (it used to REPLACE the ready chip in the same left slot).
- [x] snake never wears "ready to play" (it is always ready by design).

## 3. Layout / feel
- [x] battery chip moved LEFT in the box top bar (right after the logo,
  away from the GOGACoin chip).
- [x] GOGABox wordmark regenerated — the G was clipped by the asset canvas
  since v0.0.1; new logo.png has real padding on every side (scripts/v011_art.py).
- [x] tile/carousel game titles auto-shrink to fit their card (Arc.fit_label)
  — long names can never spill anymore (pre-play page stays scrollable).
- [x] feed order (owner spec): owned (oldest unlock first) -> locked/soon
  (catalog order) -> mysteries (catalog order). Roadmap.feed_rows().

## 4. Owner brainstorm (verbatim in BRAINSTORM.md)
- [x] weird drifting strip effect removed from the box menu.
- [x] striped background now scrolls slowly DOWN instead.
- [x] splash = logo only (in-app + boot splash), flat box brown behind.

## 5. Bugs / design flaws
- [x] box menu music kept looping inside every game scene — box theme is
  now BOX-ONLY: stopped on game enter, resumed on return (main.gd router).
- [x] GOGABattery bank charged while the app was OPEN ("it says open and
  closed and i have never said that") — charges ONLY while GOGABox is
  closed now ({count, ts, rem} offline model, honest "away time" labels,
  save migration, notification schedule uses the same math).
- [x] banners took forever to appear in the box menu — banner now PRELOADS
  at SDK init (hidden), so the post-splash reveal is a visibility flip;
  no double-load while a preload is in flight; startup preloads survive
  the not-yet-wanted state.

## 6. Version
- [x] 0.1.1 / code base 30200 (arm32 30201, arm64 30202), same release
  keystore as every build since v0.0.7 (overwrite-install safe).
