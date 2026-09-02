# PLAN v0.2.6 - SNOWY TOWER: THE OWNER VERDICT ROUND

The owner playtested v0.2.5 and sent the verdict: the jump button is dead,
the backgrounds are bad, the night leaks into the day, the characters move
"weird", the snow is fake, and a free coin appears at spawn. Plus one NEW
thing to buy (MELTING), the box-wide banner-ad slot law, and the owner's own
control scheme. "make sure to work more way better this time!"

## The owner's list -> the fix contract

1. **JUMP DEAD** -> root cause: `TowerJumpBtn._gui_input` subtracted
   `global_position` from a touch position that `_gui_input` ALREADY
   delivers in local coordinates - the point landed far outside the circle,
   every press was swallowed. The old buttons die anyway (see 7), so the
   bug dies with them; the probe now drives the REAL input path.
2. **BAD BACKGROUNDS** -> the mountains + tree lines are DELETED. Clean
   day: gradient + small corner sun (snake-sized) + drifting clouds.
   Clean night: deep gradient + small crescent moon + star-like lights
   (shader dust + glints) + drifting night sparks (particles). The aurora
   and the shader cloud band are gone.
3. **NIGHT LEAKS INTO DAY** -> root cause: `_day_night()` re-added a
   CanvasModulate and freed the old one by NAME; on the second switch the
   new node got an `@`-renamed handle (same-frame name collision), so the
   third switch's `get_node_or_null` MISSED - the night tint survived
   forever. Fix: ONE CanvasModulate held in a member var, color swapped,
   never re-added. Probed.
4. **CHARACTERS MOVE WEIRD** -> real tumbling: the square rotates
   CONTINUOUSLY around its leading corner arc (no more 90-degree snaps)
   with support-height compensation (a side FALLS, the face slaps down),
   and eases to the nearest flat face when you stop. The triangle flips
   the same physical way and settles to its edge-down orientations. In the
   air the spin keeps its inertia and decays. Slap SFX on the face-down.
5. **START PLATFORM / PHANTOM COIN** -> root cause: `next_coin_idx`
   started at 0, so a coin spawned ON the start platform right where the
   ball spawns (the free coin), and `highest_idx = -1` paid +1 for landing
   on the start platform. Fix: `highest_idx = 0` (start pays nothing) and
   the first coin waits 5-25 platforms up, never on the start platform.
6. **FAKE SNOW** -> platforms spawn BARE and fill slowly (flake->cap rate
   retuned), the cap is drawn as real LUMPY accumulation (not a flat
   slab), flakes pop a landing poof, moving platforms shake their snow
   off, blink-off platforms drop theirs. The ball laws stay.
7. **THE OWNER'S CONTROLS** -> arrows + jump circle DELETED. LEFT half of
   the screen = analog move: the first touch anchors, dragging left/right
   from the anchor drives speed AND force proportionally (dead zone at the
   anchor = stop; left-right only, Y ignored; tracked by touch index).
   RIGHT half = tap to jump (one tap one jump, x2 = the mid-air tap).
8. **POWERUP UI** -> the life ring inside the jump circle is GONE. A
   widget on TOP: glyph + name + seconds + a draining bar. While MELT mode
   is ON the widget also shows the live size.
9. **MELTING (new, bought)** -> a shop item (price 500): toggled ON/OFF.
   ON: the character consumes the snow UNDER it over time; moving fast
   consumes at a reduced rate (down to ~30% - "the faster the move the
   higher the consumption time and lower the consumption rate") and the
   character GROWS (max x1.5). Standing where there is no snow (or being
   airborne) SHRINKS it until it dies at x0.42. Its own risk/reward loop
   against the slow-filling snow caps.
10. **BANNER ADS** -> registry `banner: true` for rally (pong), lanes
    (space dash), slasher, dario (snake/merge/xo already wear it). The
    shared `banner_safe_px()` helper lands in the game base; pong insets
    its court bottom (both orientations), dario lifts its JUMP button.
    Snowy Tower stays banner-free (the owner: controls live at the bottom).
11. **SUN/MOON TOO BIG** -> the orb shrinks to the snake game's size law
    (core ~34 logical px + tight halo), radii computed from the real
    viewport and fed as uniforms (the old UV-space orb was stretched
    weird on portrait - part of the "weird sun").
12. **GUIDE + THUMBNAIL** -> the registry guide lines rewritten for the
    zones/melt/snow; `tools/thumb_composer.py::scene_hopper` redrawn to
    the new look (the v0.2.5 round updated the guide but forgot the thumb).

## Also in this version

- SFX: `tools/v026_sfx.py` adds tower_melt (warm fizz), tower_slap (the
  face-down slap), tower_puff (the melt death). Deterministic, committed.
- Tests: tower_probe grows the v0.2.6 laws (start-plate silence, first-coin
  distance, zone input, analog dead point, melt physics + melt death,
  bare-then-snowy accumulation, moving-sheds, tumble + settle, the place
  leak probe, the widget); flow_test grows the banner flags + melt shop
  laws. qa_tower re-shot under Xvfb BEFORE shipping (owner rule).
- Version 0.2.6 (base 30350: arm32 30351, arm64 30352).

## Ship checklist

- [x] hopper.gd: controls / widget / melt / snow / tumble / sky / leak / coins
- [x] bg_sky.gdshader: clean sky, small orb, star lights
- [x] registry.gd: banner flags + hopper guide
- [x] game_base.gd: shared banner_safe_px
- [x] pong.gd court inset + dario.gd JUMP lift
- [x] v026_sfx.py + 3 new wavs
- [x] thumb_composer scene_hopper + thumbs/hopper.png regenerated
- [x] tower_probe + flow_test ALL PASS (pong/snake/dash probes green too)
- [x] Xvfb qa_tower shots verified by eye (caught: square stars, ball-snow,
      stretched orb, widget overflow - all fixed and re-shot)
- [x] version bump 0.2.6 (base 30350) + dual-ABI build + cert check + backups
- [x] push main + CI green + worklog
