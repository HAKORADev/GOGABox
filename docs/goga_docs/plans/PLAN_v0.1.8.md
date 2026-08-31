# PLAN_v0.1.8.md — THE SNAKE MAKEOVER

Owner directive (asleep at 4 AM, tests in the morning): make snake SMOOTH —
minimal-but-amazing look, particles, satisfying SFX, its own music, the
blue→milk body gradient, no grid, full screen, both orientations. Docs rule
this version: GDDs become journals (see gogames_ideas/README.md).

- [x] DOCS FIRST (owner ordered):
  - [x] gogames_ideas/README.md — journal-style GDD rule + game-name naming
  - [x] snake.md GDD born (journal entries: the before + the v0.1.8 contract)
  - [x] FUTURE_GAMES.md +4 (tower stacking clipped, balloon connect,
        circle connect, knetwalk-like)
  - [x] AGENTS.md §6 — the version rule (+0.0.1 per build, patch-same-build
        on explicit owner say, weird jumps get "fuck you")
- [ ] Audio (tools/scripts, house-generated):
  - [ ] snake_theme.wav — warm minimal loop, seamless, Music bus
  - [ ] snake_eat / snake_die / snake_start SFX
- [ ] snake.gd rewrite:
  - [ ] full-screen field (under HUD, above banner strip), portrait +
        landscape, mode chosen at load ("orientation": "auto" in registry +
        host_node auto handling)
  - [ ] smooth trail body (no grid), hold-left/right-half steering, capped
        turn rate
  - [ ] thin start → longer + wider with apples, width capped
  - [ ] blue→milk gradient along the body, gradient stretches with length;
        skins = palettes over the same system (classic/lava/ice/gold)
  - [ ] head with eyes (+ × eyes on death), forked tongue flicks (+ near-apple)
  - [ ] apple: pop-in with ring, breathing idle, burst on eat (NO alpha fade);
        coin same language, same +1 rules
  - [ ] particles: eat burst, coin sparkle, death puff (house tween-mote style)
  - [ ] death = ONLY the snake blinks red (world untouched), then finish_run
  - [ ] "TAP ANYWHERE TO START" ready state; snake idles until tapped
  - [ ] snake music starts with the run, stops at death (box theme stays
        box-only; menu restores it on close)
- [ ] registry: snake desc/controls rewritten for the new feel
- [ ] flow_test: boot + economy contracts intact, auto-orientation headless
      fallback asserted, ALL PASS + geometry probe
- [ ] version 0.1.8 / base 30270 (arm32 30271, arm64 30272), build both ABIs,
      cert == house chain, APKs backed up, push, CI green
