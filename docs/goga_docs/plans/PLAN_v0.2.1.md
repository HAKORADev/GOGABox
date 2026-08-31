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
