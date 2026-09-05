# PLAN v0.3.3-7 — the owner's patch-6 test report, item by item

> The tracking law: every item below is checked off only when its code +
> probe check land. The owner: "do this patch fast fast, i will not test
> it ... then later test v034 on top of the patch you will do" - so the
> probe battery IS the QA this round. Jelly, ice storm, butterflies and
> diamond mine: the owner says they are GOOD - untouched.

## A. the coin (the collect-to-match gap)
- [x] **A1. THE COIN-REFILL RESOLVE LAW.** The owner: "the coin when
      dropped and collected, if there is a legal match that should be
      matched, it does not". ROOT CAUSE: `_collect_coin_at` refilled the
      emptied seat with a fire-and-forget `_gravity()` (the
      `_coin_refill_pending` tick branch) - no scan, no resolve. The
      refill's fresh matches just SAT on the board. FIX: the pending
      refill now rides the unified `_resolve_loop` (scan -> pop ->
      gravity -> re-scan, cascades + births included) behind the busy
      guard, exactly like every other wave.

## B. drop-down (the "always lose" rise rule)
- [x] **B1. THE TOP-LINE LAW.** The owner: "if goes up two times it is
      marked end of turn, it should be like that only if they are at the
      top line and not every time". The two-climbs game-over now fires
      ONLY when a parcel's second strike catches it ON the top row -
      mid-board strikes keep climbing it with the red warning.
- [x] **B2. THE FIRST-DESCENT ARM.** The owner: "they are always starts
      at first line, so make a logical check that only toggles the
      two-ups rule if they first dropped at least a grid down from their
      original first line so it does not be like an always lose". A
      parcel carries a `dropped` flag set by its FIRST real descent;
      until then its strikes arm nothing (a fresh top-line parcel can
      never end the run).

## C. powers (the aiming + the remover laws)
- [x] **C1. THE DISCARD LAW.** The owner: "the powerup when selected and
      aimed to an illegal grid, it should be discarded and not waiting
      for a valid grid to be tapped". An aim that cannot fire (outside
      the board, an unplayable solid, the vapor's no-color seats: empty
      / coin / parcel) now DROPS the arm - cursor, hint, sound - with an
      error toast. The charge is NOT spent (the power never fired).
- [x] **C2. THE REMOVER IS CONSUMED.** The owner: "it does the effect,
      but the special does not get removed and it stays with the VFX but
      acts like normal gem". ROOT CAUSE: `_do_hyper_swap` pushed the
      remover's pop seat with a TRANSPOSED key (`c * COLS + r`) - the
      seat never popped, the model shed `special` but the node kept the
      shader: a naked gem wearing ghost VFX. FIX: the real key
      (`r * COLS + c`), the remover's shield stripped (its job is done -
      no shield saves a fired remover) and the node undressed.
- [x] **C3. THE DOUBLE REMOVER.** The owner: "i tried to mix color
      remover special with the powerup and the powerup removed the
      original gem type behind that special, while i said it should work
      like double-remover which do 1 damage and clears the grid from any
      gems". The vapor aimed AT a remover special now goes SUPERNOVA:
      every gem pops (any color), the remover is consumed, and
      `_nova_damage()` lands the 1 damage on every damageable layer -
      the same law the remover+remover swap obeys.
- [x] **C4. THE VAPOR AIM-SEAT KEY.** The vapor's own `pop[cellp.y *
      COLS + cellp.x]` carried the same transposed-key disease (it could
      pop a random transposed seat). The aim seat joins through its real
      key.

## D. ship
- [x] **D1. matcher_probe v7**: A1 forces a 7-line through the collect's
      refill and demands the resolve; B re-points the risky-parcel
      battery (birth-line strikes arm nothing, armed strikes kill only
      on the top line, mid-board strikes never kill); C discards arms on
      every illegal aim with the charge intact, proves the fired remover
      leaves no ghost and the vapor-on-remover clears the whole board.
- [x] **D2. flow_test + the other probes still green.**
- [x] **D3. version_name `0.3.3-7`, version_code_base +10; push, watch
      CI green, NO release (the release law).**

## SHIP RECORD (filled at the end)
- matcher_probe v7: **209 checks, 0 fails** (deterministic - the probe
  seeds the global rng; a new `_wait_idle` helper waits out the async
  resolve chains instead of racing them with fixed sleeps)
- flow_test: ALL TESTS PASSED - invaders_probe: ALL LAWS PASS -
  slasher_probe: ALL PASS
- Probe notes: the ICE v6 drop check gained a pinned `front_clock` (the
  tick's live rise once grew a tile mid-resolve: 6 - 3 = 3); the coin
  battery re-points after the collect's wave (the probe's own `_tap`
  law checks stay)
- version_name 0.3.3-7 / version_code_base 30450 (arm64 30452, arm32 30451)
- NO release - push + CI green is the delivery (the release law)
