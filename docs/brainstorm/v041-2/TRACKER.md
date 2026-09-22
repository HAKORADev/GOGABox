# v041-2 — TOWER BALL — the tracker (dev-only, self-facing)

The owner's order (kept in spirit, the full text lives in the chat):
- the 3D groundwork FIRST: "before you make the game itself, make sure that
  GOGABox infra and game loader will handle a 3D scene" + "work on the infra
  too, so any future 3D game will work"
- the game: stack ball + neon tower, ONE game, TWO modes ("ball" + "platform"),
  3D, non-themed, casual known look (NOT neon), cool shadows, high quality
- rounds with ends like gold miner / brick breaker: length 150..900 by the
  150-300-450-600-750-900 ladder; crash with no lives ends the run; each win
  +1 score; score bonus /5 (coin_div 5)
- GOGACoin after every 6 rounds, legal area, can be MISSED, both modes,
  accurate scale, a 3D default coin for all future 3D games
- skins: breakable-things + ball, 5 each, first default, rest GOGACoins
- fire ball super move after a long streak ("spam-like")
- touch + keyboard+mouse; vertical AND horizontal ("this game will come with
  vertical and horizontal to test both scenes")
- "tap anywhere to start" accurate (the universal law) + mode selection as
  THE OPTIONALS MENU
- thumbnail, achievements, requirements/orders, rate-limits, guide, entry
  = my work, accurately
- the character is BALLDOZER (no lore popup - "the game is literally
  geometrics, no lore")
- version: v041-2 (NOT another v041-1 round) - config 0.4.1-2 / code 31410

## THE FEASIBILITY (proven before any code)

probe_3d (Xvfb + llvmpipe, gl_compatibility - the shipping renderer):
- F1 HOLDS: a Node3D world lives under the Node2D host (no tree errors)
- F2 HOLDS: Camera3D + meshes + DirectionalLight3D SHADOWS render
  (screenshot /tmp/probe_3d/f1_world.png - the ball's shadow on the floor)
- F3 HOLDS: 2D HUD CanvasLayer paints ON TOP of the 3D world
=> the architecture: the host stays Node2D; the 3D game is a Node3D child;
   ALL existing 2D chrome (loader, HUD, sheets, popups, toasts) renders
   above the 3D world for free. Zero risk to the 25 shipped games.

## THE WORK ORDER

- [x] 1. repo verified (cc3309cf = v041-1 r7, clean)
- [x] 2. infra study (host_node, game_base, loader, store, registry,
         snake orientation ask, goldminer shop/rounds, THUMBNAILS, AGENTS laws)
- [x] 3. 3D feasibility probe (the three facts above)
- [x] 4. brainstorm files (this folder)
- [x] 5. INFRA: game_base3d.gd (GogaGame3D - the 3D twin), game_coin3d.gd
         (Coin3D - the 3D GOGACoin default), host_node dim=="3d" branch
         (skip the brown bg; widen `var game` typing), registry dim field
- [x] 6. AUDIO: tools/v0412_sfx.py (bounce/break/fire/crash/win/coin/serve
         + a 32s casual loop)
- [x] 7. GAME: towerball_data.gd (pure algorithms, probe-able) +
         towerball.gd (both modes, both orientations, skins, shop,
         optionals menu, fire ball, coins, lives, rounds)
- [x] 8. REGISTRY: towerball entry (dim 3d, orientation auto, coin_div 5,
         ach table, controls, controls_pc, genres, reveal)
- [x] 9. THUMB: capture rig (real 3D renders, law 44) -> 960x640 compose
- [x] 10. TESTS: tests/towerball_probe.gd (pure laws) + flow_test extension
- [x] 11. QA FILM: both modes x both orientations under Xvfb, EYEBALL
- [x] 12. DOCS: AGENTS.md laws, games_done.md, FUTURE_GAMES.md graduation,
         gogames_ideas/towerball.md GDD, journal
- [x] 13. CONFIG: 0.4.1-2 / 31410 (+exe preset stamp)
- [ ] 14. commit, push, CI, deliver (Windows exe + both APKs + changelog)

## THE LAWS THIS GAME RIDES (already in the box)

- THE TAP-ANYWHERE LAW (v0.4.1): one universal overlay, tap OR key fires
- THE POSITION RELOAD: request_orientation_reload + start_orientation
- THE SHEET STACK / BACK LAW / DIM-CLOSE LAW
- THE SHELF LAWS (shop rows: ON row, stay-open, the shop SELLS the game
  APPLIES)
- THE RULE TABLE (achievements are registry data)
- THE ALWAYS-PLAYABLE CHEAT, batteries, daily caps - all host-side already
- THE THUMBNAIL CAPTURE LAW (law 44)
- THE COMFORT LAW (60fps in-game)
- THE PLATFORM LAW (os both + controls_pc)


## THE SHIP NOTE (what the sim + the eyeball caught before the push)

- the quiet (crash) shatter never advanced top_row - the torn disc
  rebuilt itself and a held dive could chain-crash: the disc gives way
  on EVERY path now
- the ghost contact plane above the victory disc snap-caught the ball
  forever - THE ROUND WIN WAS UNREACHABLE until the contact gates on
  top_row < round_len (the finish is now the designed free-fall onto
  gold)
- Arc.confetti got a CanvasLayer parent (typed Control) - the overlay
  root itself is the seat
- the ball mesh never followed the physics in ball mode (the write-once
  seat bug the thumb rig caught)
- the hard blocks were born "absent" (breaks[] duplicated the birth
  data) - THE PRESENCE LAW: all blocks stand at birth
- the landscape camera hid the stack under the top disc (the 54 floor)
- the platform field read flat (the -0.09 rad tilt)
