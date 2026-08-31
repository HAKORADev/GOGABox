# PLAN_v0.2.0 — THE SNAKE MIRROR WORLD (owner's v0.1.9 test-feedback round)

Owner tested the v0.1.9 war build on device and came back with a numbered list.
This plan tracks every item. English-only rule in force. Version 0.1.9 →
**0.2.0** (owner said "make the v0.2.0"; the +0.0.1/+10 rule agrees), base
code **30290** (arm32 30291, arm64 30292).

## THE LIST (owner's numbering, verbatim intent)

1. **Wall wrap is broken three ways.** The snake "vanished and appeared the
   other side" (the trail is TRIMMED AT the last wrap break, so the whole
   body teleports); self-eat is impossible (history past the break is gone);
   and a 30° crossing DRIFTS the same offset every pass (10 → 20 → 30...:
   the break's fake `+SAMPLE_STEP` arc corrupts the path length).
   **Fix = MIRROR WRAP (owner's own spec):** exit the top wall at 80/100 →
   enter the bottom wall at 20/100 (along-wall coordinate mirrors, heading
   preserved). Trail keeps BOTH sides of every break with the true traveled
   distance stored on the break point — arc accounting exact, tail follows
   the head THROUGH the wall (mirrored continuation stubs paint outside the
   wall), collisions test portal images so eating yourself THROUGH a wall is
   possible again.
1.75. **Steering = MOUSE, not a stick.** The head is driven by the finger's
   MOTION: swipe direction sets the target heading, swipe speed sets the
   turn urgency; slow drags = fine control, resting finger = straight.
   Still screen-space (left stays left upside down), still capped by the
   bend budget (no spin exploit), deadzone kills jitter.
2. **Tail not closed.** The ribbon's tail cap gets rebuilt as a proper
   rounded cap (arc around the tip tangent) and the collapse makes it moot
   for corpses.
3. **Shop = fixed smaller size, always scrolling inside.** No more
   grow-to-fit-then-maybe-scroll: the shop panel is a FIXED height
   (~62% of the screen), content scrolls in a BoxScroll, wallet + CLOSE
   pinned below.
4. **Nothing spawns before the run.** Enemies/fruit/coin/bugs/obstacles/
   power timing only exist once the tap starts the run (same moment the
   player snake "appears"). Optionals toggles in the mode menu SAVE A PREF
   and touch nothing — no world reloads on selection changes.
5. **THE DEAD END (worst bug).** Locked optional → shop → close = the mode
   menu never comes back (the shop cleanup freed the overlay and nothing
   rebuilt it; the game sat frozen forever). `_shop_close()` now RESTORES
   the phase screen (orient / mode / ready card / nothing when running).
6. **Fruit art re-craft.** Every painter redrawn with real shapes, shading,
   stems/highlights — banana first (it was the worst). Rendered to a QA
   contact sheet and LOOKED at (the owner: "take a look at them").
7. **Position select = universal reload.** Same position picked → do
   nothing. Different → the game is UNLOADED AND RELOADED in the new
   position through a UNIVERSAL host path (`request_orientation_reload` on
   GogaGame + handling in host_node) any future vertical/horizontal game
   reuses. The reloaded instance skips the already-answered ask (lands on
   the mode menu), keeps the paid session (no second fee, no second play
   count).
8. **NO-WALLS arrows are dead.** The chevrons go away; the dashed green
   border is the whole announcement.
9. **PEACE — a STYLE, not a mode.** Sits ABOVE classic/no-walls and runs
   with either. Peace locks enemies, bugs, obstacles and power-ups, keeps
   fruits, spawns NO GOGACoins and zeroes the score bonus (the payout
   path reads the new `GogaGame.score_bonus_enabled` flag — modular for
   every future game). The snake cannot die on itself in peace (phases
   through).
10. **SNAKE-EATER bites YOU too.** While wearing eater, self-collision is
    not death: the body is bitten off at the contact point and that length
    is LOST (`bite_back` on SnakeBody).
+ **Death = COLLAPSE.** The tail races into the head (length → 0, fast but
  readable), x-eyes, red pulse, final burst — dramatic, then the dead menu.
+ **Width is symmetric.** Width is DERIVED from target length now: bites,
  bugs and curses shrink the body fatter→thinner exactly the reverse of
  apples (owner: "make its body smaller too the same way it got bigger").
+ **Speed by score.** Each 10 points = ×1.1 (score multiplier), shown
  next to the score as `x1.23`; two NEW permanent power fruits: SPRINT
  (+50% forever) and SLOG (−50% forever), own weights/cooldowns/auras
  (the rhythm law holds). Effective speed multiplier lives in the HUD.
+ **Enemy chips honest.** Dead enemy chips are REMOVED (not grayed), each
  chip shows score AND its speed multiplier.
+ **PLACES.** Shop section + optionals box: DAY GARDEN (green grass, sun
  with rays, soft shadows) and NIGHT GARDEN (dark garden, moon halo, stars,
  the Snake3D fireflies ported: wandering + layered blinking + additive
  glow). Night garden costs GOGACoins; the place is chosen before the run
  and re-themes the field, deco, walls and ambience.
+ **AI survives.** Rollout-based survival (candidate headings scored by a
  short arc rollout: clearance vs walls/obstacles/every body — wrap-aware
  via portal images), panic layer, food seek only when safe. Noose kept
  but gated behind safety.

## Order of work

1. docs (this plan + journal) → 2. snake_body.gd (mirror wrap, trail
   breaks, derived width, bite_back, collapse) → 3. snake_ai.gd (rollout
   brain) → 4. snake_fruits.gd (new powers + painters) → 5. snake.gd
   (phases/spawn-on-start/peace/shop/places/HUD/controls) → 6. universal
   orientation reload (game_base + host_node) → 7. SFX (portal, collapse)
   → 8. tests (flow_test, snake_probe, geometry, QA) → 9. fruit/place
   visual QA via Xvfb + iterate → 10. build both ABIs → 11. push + CI.
