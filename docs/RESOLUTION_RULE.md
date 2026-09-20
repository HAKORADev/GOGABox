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
5. **Bottom inset (reclaimed)**: the old 52dp ad-banner reservation is
   retired (THE 0-ADS LAW) — `banner_bottom()` reads 0.0 and every layout
   reclaims the strip. The menu's own safe-area math stays for the OS
   gesture bar.
6. **THE VERTICAL SLICE LAW (desktop)**: on PC a portrait design renders
   KEEP-aspect in the window's middle and the letterbox is painted the box
   brown (`ScaleRule.apply_vertical_slice`); landscape keeps EXPAND.
7. **Test matrix**: before shipping, headless-run the flow test AND eyeball
   the game on a 20:9 profile (emulator) — the editor window is 16:9 and
   will happily hide this class of bug.
8. When in doubt: the viewport is a ROOM, not a PICTURE. Build for the room.

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

## 6. THE UNIVERSAL RESOLUTION (v0.1.1 — the density rule was also replaced)

The v0.1.0 density rule derived the logical viewport from the DEVICE
(`720 / clamp(short_side)`). The owner relitigated it again and was right
once more: per-device math means every device sees a slightly different
ROOM, and rotation bugs fall out of it ("if the phone was horizontal and
opened a vertical game, the game hard-switches the phone BUT uses the same
old orientation resolution - it appears too small"). Working on unknown
sets of resolutions would keep biting later.

**The rule now** (owner's phone FHD is THE design; everyone else scales):

```
project.godot:  viewport 1080x2400, stretch canvas_items, aspect KEEP
portrait  design: 1080x2400   (menu, portrait games)
landscape design: 2400x1080   (landscape games, rotated menu)
runtime:      content_scale_size swaps between the two on rotation
              (menu._apply_base / host_node._apply_orientation) - nothing
              else is per-device anywhere anymore.
letterboxing: non-20:9 devices get bars painted in the box brown
              (rendering/environment/defaults/default_clear_color).
```

- The owner's 1080x2400 phone renders the design 1:1 (scale 1.0).
- Every other device gets the SAME design scaled up or down. One design =
  one layout math = games are designed once, forever.
- The v0.1.0 `_apply_density()` is DELETED. `_banner_safe_px()` still
  converts the native 52dp banner to logical px, now via the true KEEP
  scale `min(win.x/vp.x, win.y/vp.y)`.
- Verification: geometry_probe boots the REAL scene at BOTH designs and
  fails on any control outside the design viewport. flow_test asserts the
  portrait design is restored after every game closes.

## 7. THE UNIVERSAL FHD RESOLUTION (v0.1.2 — 16:9/9:16 designs + the landscape fix)

Owner feedback after testing v0.1.1 on the FHD+ phone:

- LANDSCAPE WAS CORRUPTED: "it just uses the vertical resolution and shows
  it in vertical area at the middle and the sides are black". Root cause
  found in code: `menu._apply_base()` decided the orientation from
  `_root.size` — but `_root` lives in DESIGN space. Once the portrait
  design was applied, its rect was 1080x2400-shaped FOREVER, so the
  `s.x > s.y` check could never flip, and the engine letterboxed the
  portrait design dead-center on the landscape window. (The reverse
  rotation looked "fixed" only because portrait was already the design.)
- The fixes, structural:
  1. The decision reads the REAL WINDOW PIXELS (`DisplayServer.window_get_size()`),
     never design space.
  2. A plain rotation never fires `_root.resized` (the visible rect does
     not change until the design swaps) — so the menu also hooks
     `get_window().size_changed`, which DOES fire on the device.
  3. `menu.set_active(true)` re-decides the design when a game ends (the
     host's `_restore()` pins portrait blindly; a landscape-held phone
     must get the landscape design immediately).
- NEW DESIGN SIZES (owner): 1080x1920 portrait / 1920x1080 landscape —
  9:16 / 16:9. The owner's FHD+ panel renders them at exactly 1:1 native
  pixels; UI elements stay physically identical on 16:9 and 20:9 phones
  ("not too much small while still giving us better space").
- Aspect-ratio safety (owner: "handle different phones aspect ratios so
  things do not go out of screen ... and still the same in different
  phones"): stretch canvas_items + aspect KEEP — every phone sees the
  SAME logical room; taller/wider screens get letterbox bars painted in
  the box brown. Nothing can ever lay out off-screen.
- Verification: geometry_probe no longer pins the design itself — it sets
  `menu.orientation_override` and lets the REAL `_apply_base` code apply
  the design, then fails if the visible rect is not exactly the design or
  any control pokes out. This is the exact regression that was broken.

## 8. THE RESOLUTION & SCALE RULE (v0.1.3 — EXPAND fills the window, ScaleRule is law)

The owner tested v0.1.2 on the FHD+ phone and shipped back three screenshots:
portrait opened LETTERBOXED (black bars top/bottom), landscape opened showing
the PORTRAIT design dead-center with black sides, and a vertical -> horizontal
-> vertical switch left a squashed hybrid floating in black. Verdict: "work
hard on the resolution handler and scaling system to manage the aspect ratios
and resolutions for the phone window while keeping internal resolution the
same for the app" — and NO letterbox bars ("you said letterboxed and i have
never said that").

The v0.1.3 system (game/core/scale_rule.gd is the single source of truth):

1. INTERNAL RESOLUTION IS FIXED: 1080x1920 portrait / 1920x1080 landscape
   (9:16 / 16:9). Two constants, used by menu, host_node, tests - nothing
   else in the codebase may hardcode a design size.
2. THE WINDOW IS ALWAYS FILLED: project.godot stretch = canvas_items +
   aspect EXPAND. The engine scales by min(win/design) and GROWS the canvas
   in the spare direction - extra phone aspect becomes extra canvas in
   design px. No bars on ANY device, nothing distorted, ever. (KEEP and its
   letterbox bars are RETIRED - the owner explicitly rejected them.)
3. THE DESIGN FOLLOWS THE REAL WINDOW PIXELS: ScaleRule.want_for() decides
   portrait vs landscape from DisplayServer.window_get_size() - never from
   design-space state (that was the v0.1.1 stuck-portrait root cause).
4. THE GOVERNOR: main._process calls menu.apply_resolution() EVERY FRAME
   while no game is running. Steady state = one Vector2i compare; a missed
   signal (boot-in-landscape races, system rotations, resume-after-kill)
   self-corrects within one frame. get_window().size_changed stays hooked
   for same-frame swaps. "Stuck in the wrong design" is structurally
   impossible.
5. SAFE AREA: with the canvas reaching every edge, OS insets (notch, status
   bar, gesture bar) are converted to design px (ScaleRule.safe_insets_design,
   via the real stretch scale) and padded into the menu page margins per
   SIDE - landscape phones wear the notch on a side.
6. GAMES: host_node._apply_orientation pins the game's design from the same
   two constants; _restore() decides from the REAL window px (no blind
   portrait pin). Games read the real viewport W/H, so the extra canvas on
   tall phones is just more playing field.
7. THE CODE-DRAWN BACKGROUND: bg_stripe.gdshader's pattern space is the
   LIVE canvas (its `canvas` uniform = the background rect in design px,
   menu._bg_canvas_update) - stripes stay 45 degrees at the measured period
   on every phone, whichever way the canvas expanded.
8. BANNER MARGIN: _banner_safe_px() recomputes on every design swap (the
   real stretch scale of THIS orientation + device).

Verification (tests/geometry_probe.gd, rewritten v0.1.3):
- LAYER 1 - the aspect matrix: 15 realistic window sizes (16:9, 19.5:9,
  20:9, 4:3 tablets, iPhones, degenerate/garbage) -> correct design decision.
- LAYER 2 - end-to-end: the REAL scene, the REAL _apply_base; asserts the
  design applied, the visible rect equals the EXPAND math (catches any
  regression back to KEEP), and no visible Control pokes outside.
- LAYER 3 - rotation ping-pong: landscape -> portrait -> landscape ->
  portrait on one live scene (the owner's third screenshot regression).

## THE PC WINDOW LAWS (v0.4.0-17 - the owner's first Windows test round)

The owner's order: "it should be internally 1:1 internal horizontal/vertical
resolutions, 1280x720 or even 4K, all should work, make pressing F11 or
alt+enter go full screen or return windowed ... make it in vertical games to
re-window itself to have no empty sides ... make in windows build, the
settings menu has toggles of full screen or windowed."

9. THE 1:1 LAW: stretch `canvas_items` renders at the REAL window
   resolution on every size - 720p, FHD, 4K. The design constants are a
   logical canvas, never an upscale target; the PC window laws just pick a
   good window SHAPE. Any window size the user makes already renders 1:1.
10. THE RE-WINDOW LAW (ScaleRule.re_window): in WINDOWED mode the window
    reshapes itself to the content - portrait content (the box menu,
    portrait games) gets a 9:16 window (~90% of the screen height), landscape
    games a 16:9 window (~80% of the width), centered on the screen. The
    vertical slice (rule 2's phone history) stays as the FALLBACK for any
    off-aspect shape the user drags the window into: brown bars, never
    black, never stretched. Hooked at: boot (main._ready, the persisted
    choice), game launch (host_node._apply_orientation), back-to-menu
    (host_node._restore). Fullscreen: the kind is remembered, the monitor
    is left alone.
11. THE FULLSCREEN LAW: F11 or Alt+Enter anywhere (main._input, PC only,
    no echo), or the SETTINGS sheet toggle (Windows builds only - phones
    never see the row; the stay-open law rebuilds the sheet in place).
    Toggling persists through Box settings (`pc_fullscreen`) and re-applies
    at boot. Fullscreen is a monitor - it cannot reshape - so portrait
    content wears the vertical slice with the box brown sides there.

Verification (tests/window_probe.gd - run under Xvfb, NOT --headless:
headless has no window and every law no-ops by design): the REAL main.gd
boots, the window must open portrait ~9:16; re_window landscape/portrait
reshape + stay inside the screen + remember the kind; the fullscreen toggle
flips the mode, persists in the Box settings, and returning to windowed
re-windows to the content; the content scale stays glued to the design.

## 9. THE DESIGN FOLLOWS THE CONTENT (v0.4.1 - the vertical-fullscreen kill)

The owner's mixed report proved the v0.4.0-17 fullscreen seat broken: in
fullscreen on a 16:9 monitor the portrait menu got the LANDSCAPE design
(want_for read the monitor's landscape pixels), which painted the
sideways-hybrid, mis-aimed every click, and left "black sides" that were
really the EXPAND canvas reaching past the content WITH live clicks inside.

The law now: **on a desktop the design is picked by WHAT IS SHOWING** - the
menu's own position choice (`ScaleRule.pc_position`, F10 / the settings
row) or the game's orientation - never by the window's aspect. The phone
rule is unchanged (the window IS the screen; rotation is physical).

## 10. THE PC STRETCH LAW: KEEP EVERYWHERE

On a desktop EVERY design renders KEEP-aspect (`ScaleRule.apply_pc`):
windowed, re_window reshapes the window to the design (no bars at all);
fullscreen or any dragged shape, the bars wear the box brown. EXPAND is a
phone law - a desktop canvas can never outgrow its content again, so bar
clicks land outside the canvas and die (the owner's clickable-sides bug).

## 11. THE EDGE VEIL (the Spotify-like theming, done honestly)

When the brown bars exist, the app's own edge wears a soft inward shadow
(main.gd `_build_edge_veil`, visible only when `ScaleRule.bars_visible`) -
the box floats above the sides. NOT per-pixel dominant-color theming (the
owner pre-rejected that read for this app).

## 12. THE SHARPNESS LAW (the jagged/cloud kill)

The PC windows render the 1080x1920 design downscaled (a 900px-tall
monitor shows it at ~0.6-0.75); linear sampling without mips aliased the
raster art into the jagged thumbnails and the cloud-ish wash (the same art
is clean on the FHD+ phone because it samples 1:1). The law: project.godot
canvas filter = Linear Mipmap + tools/v041_mipmaps.py generates mips on
the 2D art (2089 textures). Vector UI/text are unaffected (always sharp).

## 13. DYNAMIC SCALE (the FSR law)

The owner asked for FSR4.1; the honest answer: FSR 4 is AMD RDNA4 ML tech
that cannot ride a 2D GL app, and FSR 2/3 are temporal 3D passes. The
FidelityFX piece that fits is the SPATIAL SHARPENING pass (game/core/
rcas.gdshader, CAS math from the same family) - one shader over the whole
final frame, every GPU (AMD/NVIDIA/Intel), no restart, OFF by default.
Settings > Screen & Graphics > DYNAMIC SCALE.
