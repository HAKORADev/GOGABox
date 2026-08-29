# THE RESOLUTION RULE (read before touching ANY game layout)

> This document exists because the same bug shipped TWICE (Jelly Jump, then
> GOGABox v0.0.1 games): content laid out for a fixed 720x1280 screen looked
> fine in the editor and on 16:9 devices, but on modern 20:9 phones the
> bottom of the screen simply "did not exist" — games hugged the top and the
> bottom died, or content slid under the banner. NEVER AGAIN.

## 1. Why it happens

- GOGABox stretches with `canvas_items` + aspect `expand`.
- `expand` GROWS the 720x1280 base to match the device aspect:
  - 16:9 phone  -> viewport 720x1280 (what the editor shows)
  - 20:9 phone  -> viewport **720x1600** (portrait) / **1600x720** (landscape)
- Any Node2D game content positioned in absolute coordinates (y=96, board
  1152 tall, ...) is laid out for 1280. On a 1600-tall viewport it hugs the
  top and leaves ~320 dead pixels at the bottom. The HUD, anchored to the
  real viewport, drifts away from the game field.
- Same class of bug: a CenterContainer substitute built with anchors at 0.5
  but WITHOUT centering offsets (the loading screen appeared bottom-right).

## 2. The rules (enforced by review + flow tests)

1. **Read the real viewport**: every layout decision starts from
   `get_viewport_rect().size` — never from the constant 720x1280.
2. **Backgrounds and overlays**: always `PRESET_FULL_RECT` anchors (they
   cover whatever the viewport grew into). Host `bg`, game HUD, sheets,
   loaders: full-rect, no fixed sizes.
3. **Centering**: use `CenterContainer` (full-rect) for any centered block.
   Anchoring to 0.5 alone is NOT centering — it pins the TOP-LEFT corner.
4. **Playfields** may be designed for 720x1280, but must be positioned from
   the real viewport (e.g. snake centers its board: `ORIGIN.y = (vp.y -
   board_h)/2`). If a future game truly needs a fixed stage, the HOST must
   offset the stage by `((W-base_w)/2, (H-base_h)/2)` — one place, central.
5. **Banner safe area**: box UI reserves 78px at the bottom
   (`menu.gd BANNER_SAFE`). Games hide the banner during play
   (`Ads.banner_hide()` on launch, `banner_show()` back in the menu).
6. **Test matrix**: before shipping, headless-run the flow test AND eyeball
   the game on a 20:9 profile (emulator) — the editor window is 16:9 and
   will happily hide this class of bug.
7. When in doubt: the viewport is a ROOM, not a PICTURE. Build for the room.

## 3. Fixed instances (history)

- Jelly Jump v1.0.2 — menu content cropped by fixed positions (fixed).
- GOGABox v0.0.1 menu — fixed 800px scroll box + no banner reserve (fixed
  in v0.0.2 with anchor layout).
- GOGABox v0.0.2 games — snake board top-glued on 20:9 (fixed in v0.0.3 by
  rule 4); loading screen off-center (fixed by rule 3).
