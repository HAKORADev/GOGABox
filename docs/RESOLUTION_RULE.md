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

## 4. "The app uses its own resolution" (owner question, answered v0.0.9)

The box renders **720x1280 LOGICAL units**; `canvas_items` + `expand`
stretches them to whatever room the device has (16:9 -> exactly 720x1280,
20:9 -> 720x1600 portrait). Text and vector drawing are rasterized at the
device's REAL resolution by the engine - they are always sharp.

What read as "small internal resolution" on a 1080x2400 phone was:
1. **1x raster art** (icons/thumbs drawn for a 720-wide canvas, then
   upscaled ~1.5x by the stretch -> soft). Fix: re-rendered the small UI
   icons at 2x and the thumbs at 1.5x source density (same on-screen
   logical size, sharper sampling).
2. **The battery chip bug** - a 0-min-width Button wrapping an overflowing
   panel painted OVER the GOGACoin chip and the search icon in the box
   menu top bar. That was a LAYOUT bug, not a resolution one. Fixed by
   measuring the chip and giving the button its real width (v0.0.9).

DECISION (v0.0.9, SUPERSEDED by §5 below): the logical layout stayed
720-based. Rewriting every coordinate/font/asset to a 1080 base would buy
nothing the engine does not already do (text renders at native res) and
would risk regression across ~4000 lines of UI code. Sharpness comes from
hi-res art; placement comes from anchors; the ROOM comes from `expand`.

## 5. THE DENSITY RULE (v0.1.0 — owner relitigated it, and was right)

Owner, after v0.0.9: "make the app scale/resolution bigger so things look
smaller... using the phone native resolution could fix most of the annoying
stuff... make it accurately." He was correct: the v0.0.9 answer ("720 base
is free because text renders sharp") was true for SHARPNESS and false for
LAYOUT ROOM. The geometry probe (tests/geometry_probe.gd) proved the 720
logical width left the top bar 764px wide (gear icon off-screen) and the
carousel row 764px wide (top-picks right arrow off-screen) — the exact bugs
reported from the device.

**The rule now** (main.gd `_apply_density`, runs before the menu builds):

```
content_scale_factor = 720 / clamp(device_short_side_px, 840, 1152)
```

- 1080x2400 phone -> factor 0.667 -> **1080x2400 logical viewport** (native
  room; everything physically smaller; text still rasterized sharp).
- 1440p flagships -> capped at 0.625 (logical 1152) so UI stays readable.
- Small devices -> floored at 0.857 (logical 840): the measured UI needs
  ~796 logical px; below that the gear icon and right arrow hang off-screen
  (probe config A). 840 leaves ~40px headroom.
- Headless tests: the virtual window is 720x1280 -> the floor applies ->
  tests see 840x1493. fit_sheet-style checks must read the REAL viewport
  (`get_viewport_rect()`), never hardcode 720x1280 (flow_test does this).
- Banner safe area is no longer a constant: `menu.gd _banner_safe_px()`
  converts the native 52dp banner into logical px via real dpi and the
  px-per-logical ratio.

Verification tool: `godot --headless --path projects/gogabox -s
res://tests/geometry_probe.gd` — boots the real main scene at floor/phone/
cap logical viewports and FAILS on any control outside the viewport. Run it
before shipping any layout change.
