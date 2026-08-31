# PLAN v0.1.7 — THE MAKER UPDATE (programmable thumbnails + the games begin)

Owner directive (v0.1.7 chat): the v0.1.6 captured thumbnails lost to
hand-drawn ones; thumbnail making becomes PROGRAMMABLE (spec-driven) so
the owner can pose shots by sentence; docs must record that automated
capture is no longer recommended; and — the main dish — START WORKING ON
GAMES.

## 1. The programmable thumbnail maker ✅

- [x] `projects/gogabox/tools/thumb_composer.py` — the composer:
      960x640 canvas, real-asset stamps, radial glow, fade_below
      (the matcher recipe), vignette, SOON tiles, CLI
      (`--game/--all/--out/--sheet/--compare`), fully deterministic
      (re-runs pixel-identical, verified by hash).
- [x] The owner's example sentence IS a spec:
      `SNAKE_SPEC = dict(length=9, path=[("L",5),("U",3)], apple=("ahead",3))`
      — tail up to 9, straight left then straight up, apple 3 steps ahead.
- [x] All 6 pre-existing real games recomposed at 960x640 (snake, rally,
      lanes, slasher, hopper, merge) — the 480x320 legacy scenes DELETED
      from derive_assets.py; thumbs() now delegates to the composer.
- [x] Before/after proof sheets for the owner (download/).
- [x] Dario sprite set added to derive_assets (hero idle/jump, walker,
      brick, ground, flag) — the composer stamps them.

## 2. The games (start of the games era) ✅

- [x] **Dario** — a proper little platformer (landscape): run/jump/stomp,
      3 hand-built levels (validated by scripts/dario_levels.py: jumpable
      pits, aligned pit columns, patrol room, reachable ledges), coins,
      walkers, flag goal, JUMP button + swipe-up, hold-halves steering.
      Achievements: Big Boot (25 stomps), Flag Bearer (all 3 levels),
      Coin Mountain (score 100).
- [x] **XO Ladder** — tic-tac-toe vs a 10-rung AI (portrait, banner-safe):
      bottom rung blunders 55%, top rung is a full-depth minimax machine
      that NEVER loses (proven by perfect-vs-perfect test games); win to
      climb, lose to slip, rung persists via Box counters, CASH OUT banks
      the run. Achievements: Halfway Up (rung 5), Ladder Legend (rung 10),
      On Fire (streak 3).
- [x] Registry: both playable (chain reveal: merge -> dario -> xo, teaser
      prices kept), workshop shrinks 8 -> 6, SOON tiles regenerated.
- [x] game_base check_achievements: stomp_25/clear_all/rung_5/rung_top/
      streak_3 branches.
- [x] Tests: counts, extended-chain roadmap suite, mystery-queue rework
      (hen/spud/maze/poptd - the cap is exactly full now), xo AI sanity
      suite (winner_of, win/block/corner answers, perfect draws, beatable
      rung 1), dario+xo boot through the real host. flow_test ALL PASS +
      geometry probe PASS.

## 3. Docs (the capture detour is recorded, not repeated) ✅

- [x] docs/THUMBNAILS.md rewritten: composer = THE way (rules, spec
      vocabulary, primitives, design bar, CLI); the capture pipeline
      demoted to PARKED with the owner's call quoted.
- [x] docs/ADDING_A_GAME.md thumb step -> composer.
- [x] ideas/THUMBNAILS.md: v0.1.7 resolution appended (owner reversal).

## 4. Ship ✅

- [x] Version 0.1.7 / code base 30260 (arm64 30262, arm32 30261).
- [x] flow_test ALL PASS, geometry probe PASS, both-ABI build, push, CI.
