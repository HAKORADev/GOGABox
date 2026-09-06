# PLAN v0.3.5 — POP SIEGE (the next-version game, the owner's GDD round)

**Version:** 0.3.5 / version_code_base 30600 (arm32 30601, arm64 30602).
**Game:** POP SIEGE — the bloon siege (landscape TD, 30 maps, 10 folk, gears, synergies).
**Status:** DONE - one commit, CI pending, no release (the law). pd_probe 2298/0, flow_test ALL PASS, every old probe green, 4 Xvfb rigs eyeballed (field/menu/maps/night).

## Sources (all studied, all modified - nothing as-is; provenance in the GDD)
- PGB v1.3.8 Pop_TD.py - the bloon layer truth + wave syntax (2318 lines).
- Gamesnacks ENDLESS SIEGE - scraped for real (Phaser build, 7 atlases + audio sprites,
  CDN endlessseige.h5games.usercontent.goog): the grade/level stat arrays, the >> menu,
  the drag green/red feedback, glue intensity/duration + the grade-3 teleport homage,
  the resist/vulnerable matrix, sell + retarget. Art: 900 frames sliced (archer/cannon/
  crystal tiers, 24 obstacles, cells, FX) - RECOLORS + recompositions only.
- GameMaker Tower_Defense_Template.zip (owner-provided, free): trees, fences, graves,
  rocks, house, HUD counters, sfx - map props + audio bases.
- The internet: CC0 sweeps + synthesized everything else (the repo way).

## Build checklist
- [x] GDD: docs/goga_docs/gogames_ideas/pop_siege.md (12 sections, the laws)
- [x] tools/v035_pop_art.py - bloons x13, folk x10 x3 gears + portraits, props
      (ES recolors + template + fresh), PopCoin (yellow, darker bloon inside),
      8 synergy badges, 12 ground grains, 30 map thumbs, FX sprites
- [x] tools/v035_pop_sfx.py - the pop ladder + the set + the music loop
- [x] game/games/pop_siege/pd_data.gd - BLOONS, FOLK (3 gear tables each),
      SYNERGIES x8, MAPS x30 (waypoints, blocked, props, palettes, prices), waves
- [x] game/games/pop_siege/pd_meta.gd - owned maps/folk, best waves, d/n picks
- [x] game/games/pop_siege/pop_siege.gd - grid, placement (green/red drag), paths,
      bloons + children, 10 folk AI, projectiles, burn/freeze/glue/stun, upgrade
      menu (the >> law), gear jumps, synergies + badges, waves + rider, shop shelves,
      optionals + the 2x15 sheet, day/night, victory/lose, achievements
- [x] shaders: pop ring, burn, frost, glue, boom, chain, aura, water, night, gearup
- [x] registry entry + thumb 960x640 + projects.json 0.3.5/30600 + README/AGENTS tables
- [x] tests/pd_probe.gd - the laws as checks (maps valid, bloon rbe, gear tables,
      synergy matrix, wave bands, economy, upgrade math, a full simulated run)
- [x] flow_test + every old probe green; qa_v035 Xvfb shots eyeballed
- [x] push, CI green, NO release (the law)
