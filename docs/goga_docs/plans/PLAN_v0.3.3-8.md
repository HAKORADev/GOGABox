# PLAN v0.3.3-8 — the matcher deadlock law (the owner's one-line addendum)

The owner, on the way to v034: "in matcher game, make when there is no valid
matches, make it as a lose/end instead of shuffling".

## The law
- THE DEADLOCK LAW: the free rescue shuffle after a settle is DEAD. A locked
  board is a LOSS in the mode's own language:
  - challenge = the ROUND FAIL (the -500 law, a life, the sweep theatre, a
    fresh legal round; 0 lives = the run ends "the board locked ...")
  - every other mode (peace, butterflies, ice, mine, jelly, icecrash, drop)
    = the run ends ("the board locked - no valid matches")
- THE DEADLOCK BACKSTOP: a fresh pour can never spawn a locked board —
  quiet palette rerolls in _deal_board until a legal move exists (no VFX,
  no sound; the player never sees it). The no-shuffle loss only ever
  punishes a REAL mid-game lock.
- THE SHOP SHUFFLE STAYS: the bought shuffle power is the PRE-EMPTIVE tool —
  the player sees the board dying, pays 1 charge, reshuffles. It keeps its
  full-palette fallback guarantee.

## Status
- [x] matcher.gd: _resolve_loop after-care — the shuffle rescue replaced by
      the deadlock law (challenge round-fail branch + run-end branch)
- [x] matcher.gd: _deal_board backstop (quiet legal-pour guarantee)
- [x] matcher_probe v0.3.3-8: the checker battery re-pointed (a life paid,
      -500 paid, the fresh round poured legal) — 211 checks, 0 fails
- [x] flow_test + invaders + slasher + dario + dash + tower + snake + xo +
      pong + merge probes ALL PASS
- [x] GDD (gogames_ideas/matcher.md): the deadlock law + the peace law
      re-written
- [x] version_name 0.3.3-8, version_code_base 30460 (config/projects.json)
- [ ] push + CI green (the delivery; NO release — the release law)
