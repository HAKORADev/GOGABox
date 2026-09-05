# PLAN v0.3.3 PATCH 6 — the owner's patch-5 test report, item by item

> THE OWNER'S LAW this round: "use the docs folder for its purpose, write
> plans and brainstorms and track your work instead of forgetting and
> hallucinating from your own." This file IS the tracking sheet — every
> item below is checked off only when its code + probe check land.
> Version naming (NEW LAW): patches are REAL numbers — `v0.3.3-6` — a
> build with no patch is plain `v0.3.3`. No "PATCH N" words anywhere.

## A. naming / docs
- [x] **A1. version_name** `0.3.3 PATCH 2` -> `0.3.3-6` in config/projects.json
      (this is where the APK's "PATCH 2" words came from — build.sh prints
      `GOGABox-v<version_name>-<abi>.apk` verbatim). version_code_base +10.
- [x] **A2. docs/AGENTS.md version law** rewritten: patches ride the SAME
      base version as a REAL suffix (`0.3.3-1`, `0.3.3-2`, ...); no patch =
      plain `0.3.3`; the artifact name shows exactly that, nothing else.
- [x] **A3. this plan file** updated as items land (the tracking law).

## B. matcher — the board core (the "needs remake" suspicions, root-caused)
- [x] **B1. MINE ROW-LIFT ALIASING (the ghost/overlap bug).** `_mine_rise`
      did `grid[r-1] = grid[r]` in a loop — the two BOTTOM rows ended up as
      THE SAME ARRAY (rows 6 and 7 shared one). Every later write fell
      through both, nodes animated twice to two seats, gems "disappeared"
      and "kept overlapping over and over". Fix: rebuild the lifted rows as
      DISTINCT arrays + a fresh empty bottom row.
- [x] **B2. POWER RESOLVE NEVER RE-SCANS (the "bomb/remover then matches
      stop matching" + "vapor: one match matched everything" bugs).**
      `_resolve_from_pop` scanned matches BEFORE gravity and never after —
      the refill's fresh matches stayed on the board unresolved until the
      next move (then everything fired at once). Fix: unify with the swap
      path — pop -> gravity -> re-scan loop, exactly like `_resolve_loop`.
- [x] **B3. CASCADE CHAIN LAW (powers).** the power path's cascade waves
      never detonated specials caught inside them; the swap path did.
      The unified loop carries the detonation queue every wave.
- [x] **B4. VAPOR/REMOVER EXECUTE SPECIALS.** a special removed by the
      vapor power or the color remover EXECUTES (its blast joins the wave).
      Covered by B2/B3's queue; probe asserts it.
- [x] **B5. THE NEWBORN SHIELD.** a special born in a 4/5-match got eaten
      by the very blast the match's OTHER special fired ("it eats the new
      special"). Newborns: immune during their birth wave, then survive
      exactly ONE later hit (shield flash), die on the second.
- [x] **B6. THE CC SPAWN LAW (the "over-the-board weird fall").** fresh
      gems no longer pre-exist hanging over the board: every refill gem
      APPEARS from behind the top line (bottom-to-up rise + fade in at the
      line) and drops into its seat; per-column one-by-one stagger.
- [x] **B7. THE REAL EMPTY START.** the round opens on a truly EMPTY grid;
      the gems pour in one by one from behind the top line (no half
      pre-filled sky stack — that was the old deal's fake).

## C. matcher — coins (the real law this time)
- [x] **C1. tap-to-collect is DEAD** (the owner: "i never said let them be
      tap-to-collect at all"). The collect bug (tap + refill ate a match)
      dies with it.
- [x] **C2. THE COIN IS SWAPPABLE.** gem <-> coin swap is legal (the coin
      moves like any piece, never matches itself); the owner's exact case
      [gem][coin][gem][gem] — swap the left gem WITH the coin, the three
      gems line up. The patch-5 "hop over the coin" is deleted.
- [x] **C3. THE COIN RIDES THE REFILL QUEUE.** no more random-seat
      materialization: when the 30s clock runs out the coin WAITS QUEUED;
      the next match's refill drops it in from the top like a gem.
- [x] **C4. items keep their un-swappable law** (drop-down parcels: the
      owner confirmed that part is CORRECT — only the coin changes).

## D. matcher — sweeper shader (FINAL fix, the owner counted 3 misses)
- [x] **D1. vertical sweeper (column) wears VERTICAL stripes; horizontal
      sweeper (row) wears HORIZONTAL stripes.** Patch 5 traded the bodies
      the wrong way — trade them back, colors ride along (row = cyan
      horizontal bands, column = magenta vertical bands), probe asserts the
      band AXES this time (UV.y bands in kind 2, UV.x bands in kind 3).

## E. ice storm (three issues)
- [x] **E1. horizontal match touching the ice line drops the ice 3 grids**
      (a matched gem standing inside the ice or right on top of its line).
      Currently horizontal does nothing at all.
- [x] **E2. vertical match DESTROYS the column's ice for real** — state AND
      visuals from one registry (the overlays lived inside CELL DICTS and
      leaked on every pop: "grids still iced and never be destroyed", and a
      new front re-applied over the ghosts). Rebuild on `_ice_nodes` (the
      patch-4 ice-crash registry pattern).
- [x] **E3. THE SECOND LAYER.** a column that ices to the top does NOT end
      the run anymore: a SECOND layer forms on it and rises SLOWER; THAT
      one reaching the top ends the game.

## F. jelly
- [x] **F1. physical grid-filling actually works**: the real CC law — an
      empty seat whose ABOVE is solid pulls a gem diagonally from the side
      (no corner cuts), then that side refills from the top. Plus the
      perch-slide kept. (The p5 slide only fired when a gem's own below was
      the plug — with bottom-anchored jelly rows that never happens.)
- [x] **F2. every match on top of jelly destroys ITS jellies** (the owner:
      3 matches on jellies killed 1). Probe: three separate matches over a
      jelly row = three jellies gone.

## G. drop down
- [x] **G1. the rise rule actually ends the run.** ROOT CAUSE: after every
      resolve, `_mode_aftercare` wiped `rose = 0` unconditionally — the
      counter could never reach 2. The climb check alone owns the flag now.
- [x] **G2. powers capture parcel rows too** (`_fire_power` never called
      `_drop_capture_rows` — a power move compared rows against the wrong
      move).

## H. UI / feel
- [x] **H1. the armed-power hint floats ABOVE the power rail** (matcher's
      own hint label pinned over the rail — the shared bottom toast sat on
      top of the slots).
- [x] **H2. UNREAL!/SWEET! text fits the screen** — the floaters were drawn
      in a box whose LEFT edge was the anchor (center 230px right of the
      anchor -> "UNRE" on-screen, "AL" off). Center the box on the anchor,
      clamp inside the viewport, cap the size.
- [x] **H3. challenge losing is a SHOW**: the grid clears bottom-to-top
      line by line, then the board re-fills (the physical pour), then the
      next round rolls.

## I. menus (the back law)
- [x] **I1. matcher: back on the FIRST-MOMENT optionals does nothing** —
      it is the root screen; popping it stranded a boardless game ("unable
      to run because it removed the menu"). In-play optionals still closes
      back into the live board.
- [x] **I2. dario audit: the intro sheet pop left `_locked = true`** (same
      family: back eats the sheet, the game stays dead). Reset the lock
      when the base pops the intro. Invaders audited: no first-moment
      sheet, safe.

## J. tests + ship
- [x] **J1. matcher_probe v6**: every law above gets a hard check; old
      checks re-pointed (shader axes, coin swap law, no tap-collect).
- [x] **J2. flow_test + geometry_probe still green; Xvfb QA shots** of the
      spawn emerge, the armed hint, the second ice layer.
- [x] **J3. push as `0.3.3-6`, watch CI green, NO release** (the release
      law), FUTURE_GAMES untouched this round.

## SHIP RECORD (filled at the end)
- matcher_probe v6: **188 checks, 0 fails** (deterministic - the probe
  seeds the global rng, a pass is a pass forever)
- flow_test: ALL TESTS PASSED - invaders_probe: ALL LAWS PASS -
  slasher_probe: ALL PASS - geometry_probe: probe PASS
- Xvfb QA (tests/qa_v033p6.gd): spawn (the gems emerging from behind the
  top line, one by one), hint (TAP THE BOARD - GEM BOMB floating above the
  rail), ice2 (the second layer live, the HUD tag on), sweep (the loss
  theatre mid-clear with the next pour already queueing)
- version_name 0.3.3-6 / version_code_base 30440 (arm64 30442, arm32 30441)
- NO release - push + CI green is the delivery (the release law)
