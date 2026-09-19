# GOLD MINER — PROGRESS (v040-15)

The owner's GDD laws -> implemented -> verified. One line per law.

## Round 1 — the build (SHIPPED)

- [x] Repo recovered to origin/main 9b08480 (v040-14 base; the sandbox
      reset wiped the previous session's uncommitted forge work — redone
      from the study locker up)
- [x] STUDY: goldminertom mirrored whole (c2runtime.js, data.js, 98
      sprites, 18 sound pairs); object inventory + claw atlas decoded;
      montages eyed (the vision law); the LIVE game played in a browser
      for the palette + the swing truth (portrait layout confirmed)
- [x] GDD written (gold_miner.md) + the plan
- [x] FORGE ART (tools/v0415_miner_art.py): 54 files — the claw open +
      code-built closed (prong rotation, hub preserved, component
      cleanup), 5 rig skins, 5 vein skins x golds/rocks, the bomb cut
      from its ring, the glowing coin, the dust pair, 4 blast frames,
      the portrait ground stack, the wordmark; 3 eye-pass iterations
- [x] FORGE AUDIO (tools/v0415_miner_sfx.py): 18 sfx + the music bed —
      DIFFERENT SFX per thing (gold S/M/L, rock S/M/L, bomb, coin)
- [x] GAME CODE (goldminer.gd + miner_data.gd): the swing/launch/grab/
      reel loop, the weight law, bombs = lives + the 260px blast, the
      clear law, the every-50 glowing-gold law with the next-level edge
      case, the dust trails, hearts/score/coins widgets, the 5+5 shop
      (stay-open, shelf laws), END in the pause sheet, tap-anywhere
      intro, the once-ever Tom lore card
- [x] GENERATOR: pure + 6 profiles + the fairness validator (600 grounds
      in 284ms, all profiles live)
- [x] REGISTRY: goldminer graduated (portrait, coin_div 30, fee 8, shop,
      banner, 8 achievements, the guide carries the words); the NEXT
      FIVE teasers parked (knife, maskrush, stickbridge, bubbleshot,
      towertrim)
- [x] PROBE: miner_probe 28/28 (generator battery, assets, points 1/2/3
      + 2/4/6, weight law, the throw laws, the coin law + edge case, the
      bomb laws, the run law)
- [x] FILM: gm_film 9 shots eyed — caught + killed: the intro's STOP
      ColorRect eating the emulated finger (a real-device bug), the mud-
      splat clumps (dropped), the frozen puff lifecycle (replaced with
      self-killing tweens), the too-black dust (lightened)
- [x] SIM: gm_sim bot — 5 sim-minutes = 6 grounds, 34 banked, died to
      bombs (the naive bot doesn't dodge) — the curve is alive
- [x] flow_test: ALL TESTS PASSED (29 playable / 5 teasers / order)
- [x] BOOKKEEPING: games_done marks the last 5 done; FUTURE_GAMES wears
      the zuma + gold miner graduations + the twenty-first dump
      (brawl-stars-like, full orbit) + the SOON shelf note
- [x] SHIP: 0.4.0-15 / 31250 in BOTH config spots (the VERSION LAW);
      commit + push + CI
