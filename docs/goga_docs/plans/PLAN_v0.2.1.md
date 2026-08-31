# PLAN_v0.2.1 — THE STRAIGHT LINE (owner's v0.2.0 test verdict)

Eleven snake items, two box items, the thumbnail + guide refresh, and the
owner's dev cheats. Version 0.2.1, base code **30300**.

## SNAKE
1. Shop WIDER (buttons 560, label fits 596).
2. The milk place is BACK as the default "CLASSIC"; day garden becomes a
   150-coin unlock, night stays 250; unowned places migrate back to classic.
3. THE COLLAPSE BUG: the stale `_bp_dirty` cache - length_px shrank while
   body_points() served the frozen full-length sample array, so the body
   went THIN and a sliver raced tail-to-head (exactly the owner's report).
   Now the collapse re-dirties every frame AND folds the width into the
   head; enemies fold + set dying=false so corpses VANISH (item 11).
4. The field IS the screen - no letterbox aspect anywhere; the position
   ask rotates + reloads, the field uses the full resolution.
5. PEACE FLICKER: the ribbon was ONE self-intersecting polygon and Godot's
   triangulation breaks on self-overlap (fill vanished, naked outline).
   The ribbon is CONVEX PIECES now - a quad per step + joint discs + a
   closed tail-cap disc. Overlap just overpaints; flicker is impossible.
6. Eater bites get THE CUT: motes rain along the removed arc + a ring.
7. Banana: drawn re-centered, per-fruit HIT circle (offset + radius) and
   its own flat wide shadow - data-driven in SnakeFruits.HIT.
8. THE WRAP (his clarification - study first): torus translation, NOT a
   mirror. Exit at 80 -> enter at 80, heading preserved; the probe now
   proves the heading survives EXACTLY and successive wall entries obey
   the constant-delta law (-W*tan(angle)). Stubs are translated runs
   adjacent to real breaks - the phantom flicker lines are dead.
9. The tail cap is closed BY CONSTRUCTION (tip disc, banana-edge joints).
10. Optionals box labels use the menu-title fit trick (fit_label).
11. = 3 + the corpse fix.

## BOX
1. Locked non-mystery games wear their FINAL thumbnails - hen / spud /
   maze / matcher / keys / poptd crafted as real scene art (the generic ?
   files are dead); mysteries stay black boxes (owner's own rule).
2. The top-picks card is SMALLER (252x186) - the covered art no longer
   crops the top out of frame.

## MORE
- SNAKE THUMBNAIL: three programmatic versions composed (siege / chase /
  the moment before); V1 is the owner's literal spec (3 enemies + the user
  snake, each at a side, one apple) and ships as the final thumb.
- The ? guide (desc + controls) rewritten for v0.2.1 mechanics.
- DEV CHEATS (owner-only): five taps on the wordmark opens the sheet -
  owned / all_owned / gogacoins / battery. ALL default 0 = defaults and
  stay off. gogacoins shows the plain 0 in the UI while the LOGIC reads
  an extreme value and the real wallet is untouched; battery reads 10K.
  A games index lists every registry game with its state.

## PATCH (v0.2.1a - same version, same codes, owner review round)

The owner kept playing the v0.2.1 build and filed three defects; this
patch fixes them WITHOUT a version bump (still 0.2.1 / base 30300).

## SNAKE
1. THE POSITION DETECTOR (the reported hang): the ask highlighted the
   SAVED PREF, so a window/pref mismatch (rotation-locked portrait while
   the save said horizontal) lit the wrong card, tapping the true current
   shape emitted a reload the host answered with "same position, do
   nothing" - a soft-dead tap - and tapping the lit card kept the field
   vertical. THE LAW NOW: the ask listens to the CURRENT RESOLUTION ONLY
   (owner's own prescription) - the highlight is the live window shape,
   every tap is judged against a fresh window read at tap time (same =
   proceed, other = reload), the pref is remembered but decides NOTHING.
   Host hardening: the early-out verifies the real window too, a stale
   bookkeeping resyncs instead of eating the tap, and a REFUSED rotation
   (capped wait expired) settles the ask in the kept shape via the new
   universal GogaGame.orientation_settled() - no reload into a lie, no
   path can leave the ask hanging. Probe laws: stale pref never wins the
   highlight, tap-current proceeds, tap-other asks, settle resolves.
2. THE PEACE STACK (z-order): ribbon pieces painted head-first, so at a
   self-crossing the OLDER loops painted LAST and rode OVER the fresh
   body. PAINTER LAW now: draw order = time order - tail cap first,
   quads walk tail -> head, older portal-runs paint before the head run;
   at a crossing the NEWER loop paints LAST and sits on top, the way a
   real snake stacks. Probe proves first-piece = tail cap, last-piece =
   the head; Xvfb ring shots read naturally.
3. THE THUMBNAIL SIEGE re-programmed: the scenes fed the ribbon tail-first
   (pts[0] = the wall end), so every head pressed a wall and stared AWAY
   from the apple. All three versions are authored head-first now (head
   at the apple, eyes locked on it, tail back at its wall, closed tip
   caps added); V1 (the literal siege) ships as snake.png.
4. FOUND BY THE REVIEW ROUND: place_classic.png never existed (the
   classic place came back in v0.2.1 but only day/night had icons) - the
   optionals PLACE box rendered a blank in the DEFAULT state. Drawn in
   the v0.2.0 icon language (tools/v021a_assets.py).
