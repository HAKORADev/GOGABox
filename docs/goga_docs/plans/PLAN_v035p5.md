# PLAN v0.3.5-5 — PATCH 6: THE MULTI-GAME ROUND

The owner's report while planning (four games at once): matcher's shared
resolve bug + the drop-down redesign + the special-combo table, cosmic
spud's engineer crash + flat allies, snowy tower's untestable powerups,
fruit slasher's too-realistic cuts. Version 0.3.5-5 / 30650 (arm32 30651 /
arm64 30652). No release (the law).

## MATCHER (v0.3.3-8)

- **THE PREFILL RESOLVE LAW** — the root cause of "matches do not match
  until I do a move" + "the coin leaves its seat empty until a move":
  `_resolve_loop` scanned matches FIRST and broke on a quiet board, so its
  gravity NEVER ran. A `prefill` flag now runs one gravity wave before the
  first scan; `_coin_refill_run` and every parcel delivery ride it.
- **THE DROP STREAM LAW** — the mode is butterflies-like now: a hatch clock
  pours 1..3 parcels on its own beat (gap 6.5s shrinking to 1.6s, quicker
  every level), every round rolls a quota (climbs to the owner's 100) and
  a limit (time / moves / BOTH), and beating the quota before the limit
  rolls the next round. Budgets: ~2.1 moves / ~7.2s per parcel at round 1,
  tightening per level — hard, never impossible (probe-checked).
- **THE TOP-LINE STAY LAW** — a stuck parcel climbs one row per strike and
  PARKS on the top line; parking never ends anything. The run ends only
  when the NEXT parcel arrives and every top seat is a parked parcel (THE
  ENTRANCE JAM) — never from a parcel sitting at the top from its first
  moment. The old two-climbs kill is dead.
- **THE CLEAN ENTRANCE** — a mid-round spawn only ever takes an EMPTY top
  seat (it never deletes a live gem; the round-open lay alone quietly
  reclaims the not-yet-seen pour gems).
- **THE SHAPE LAW** — jelly + ice crash lay one of SEVEN shapes (blob,
  twins, pyramid, side columns, plus, stairs, band), connected, bottom-
  heavy, sized by level. One flat line forever is dead. (A fuzz test caught
  the first walker stepping DIAGONALLY — independent row/column picks —
  fixed to one direction per step.)
- **THE MINE SHAKE LAW** — the earth rise rolls 1, 2 or 3 rows (2 and 3
  likelier with depth, capped 0.34/0.18), and the rise clock tightens with
  depth (25s → 16s floor).
- **THE COMBO TABLE** — special + special on a swap fires without a match:
  sweeper+sweeper = two rows / two columns / the plus; bomb+bomb = a 4x4
  crater (the new `bomb4` blast); bomb+sweeper = THREE sweeps of the
  sweeper's kind; remover+sweeper = the whole color drafted as random-axis
  sweepers, all executed; remover+bomb = that color all bombs, all
  executed; remover+remover stays the SUPERNOVA.
- **THE EXECUTION TRUTH** — a blast that touches a special EXECUTES it in
  every path. The only shield that holds is THE BORN-MATCH SHIELD: a
  special born in the current wave is untouchable and the hit NEVER spends
  its charge (the owner's "ofc" law).
- Valid-move/hint finders count adjacent special pairs as moves (a combo
  is a move; no more dead boards with specials on the field).

## COSMIC SPUD (v0.3.5-5)

- **THE ALLY TRUTH (the crash)** — `_t()` never registered the ally
  textures: the engineer's drop-in deploy hit `_t("orbiter")`, the missing
  dictionary key killed the run before the first wave. Every ally texture
  registers now.
- **THE TARGET NULL LAW** — `_nearest_enemy` returns null when every enemy
  is out of range; the allies assigned it straight into typed Dictionary
  vars (a script-error storm on every empty board state). All four callers
  take a Variant now.
- **THE ALLY VARIETY LAW** — every ally wears its own tint and job: the
  guard carries a PROTECTIVE AURA (inside its 130px ring the damage you
  take shrinks 12% + 4%/level, the best ring only — never stacking), the
  medic pulses visible care, the scout plinks a weak pea-dart (3 + 1.5/lv)
  while it marks. Level 1 stays humble (upgrades exist; allies never die).

## SNOWY TOWER (v0.3.5-5)

- **THE x2 RELANDING LAW** — the audit found the real "x2 feels dead"
  bug: `air_jumped` reset only on a fresh ground jump, so double-jump →
  land → walk off a ledge → press jump was silently dead. Every landing
  refunds the air jump now.
- Every powerup path probe-validated: pickup → live, 10s life + widget,
  big x1.28, speed x1.5 (the walk cap, measured airborne), slow halves
  the slide, exactly one mid-air jump + the relanding refund.

## FRUIT SLASHER (v0.3.5-5)

- **THE CASUAL CUT LAW** — fruit hitboxes grew past their own drawn edge
  (circles 0.42 → 0.55 of the drawn width, capsules fat 0.40/0.42) so
  reaching the OUTER HALF of a fruit is a cut — the focus moves from
  perfect center-line surgery to not letting anything drop whole. The
  bomb stays honest (0.44 + the graze) so accidental detonations do not
  multiply with the generosity.

## VERIFICATION

- matcher_probe **241 checks 0 fails** (the prefill, the stream, the jam,
  the clean entrance, the STAY battery, the combo table with pop-count
  proofs on painted quiet boards, the execution truth, the born shield
  keeping its charge, the shape connectivity fuzz, the mine roll), cs_probe
  **197/0** (the ally truth + the engineer drop-in + the guard aura math +
  the scout's cycle), tower_probe ALL PASS (the powerup battery incl. the
  relanding), slasher_probe ALL PASS (the casual cut battery), pd_probe
  9487/0, flow_test ALL PASS, merge/dario/dash/invaders/pong ALL PASS.
- Xvfb rigs (`qa_v035p5.gd`, eyeballed): drop (5 parcels parked + the
  quota chips), jelly (the shaped blob), combo (the double sweep mid-wave,
  score exactly 16), prefill (the board refilled full), cs (the engineer's
  run alive: drone + the guard's green aura ring), tower (the x2 widget +
  the pickup capsule), slash (the apple cut, halves + juice mid-air).
