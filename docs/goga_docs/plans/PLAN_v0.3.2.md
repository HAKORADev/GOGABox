# PLAN v0.3.2 - SPACE INVADERS (the rebuild)

Version 0.3.2, build codes base 30412 (arm32 30413, arm64 30414).

> This version was BUILT ONCE before and died with an unpushed sandbox
> (commit 5506c88, APKs 30421/30422 - never reached the owner). The rebuild
> follows the owner's law for this round: PUSH ONLY WHEN THE FULL TASK IS
> DONE. The owner's full contract lives in
> `docs/goga_docs/gogames_ideas/invaders.md` and the agent tracker at
> `docs/goga_docs/brainstorms/invaders_v032/TRACKER.md`.

## THE OWNER'S CONTRACT (digest of the brief)

- Hen Invaders graduates as **Space Invaders** (the rename law), horizontal.
- 10 stages x 10 waves; wave 10 = the stage boss; stage 10 = THE HIDEOUT and
  THE INVADER. Tour: Neptune -> Uranus -> Saturn -> Jupiter -> Mars -> Earth
  -> Venus -> Mercury -> the Sun, then the Hideout; every background carries
  its planet's real-world data.
- Enemies +1/+2/+3; bosses +25..+200; 3 hearts; a heart loss = -500 score;
  the run bonus is /500; a new heart every +1000.
- Left half moves, right half fires (the dario/tower scheme, multi-touch).
- The SSDS crew ships are the shop (2-in-1 hull + exclusive weapon; no
  mid-run switch); optionals picks the starter; weapon item icons only spawn
  for the ship that needs them; thunder/bomb join the loot pool when bought.
- Power: level = damage (1..5); points 1 per 1-2 waves; death -3 rungs;
  continuous weapons = hits/sec with pierce falloff (floor 1); radius
  weapons decay one point per ring/hop (6 -> 5 -> 4..., floor 1).
- Thunder REWORK: an electric beam UP that chains around itself.
  Bomb Launcher REWORK: no ammo limit, contact fuse only.
- Stage Themes pack (6000): per-world skies, smooth cross-fade.
- DEFEND: rent a crew ship for 10 waves; one hit ends its shift; invisible
  to items; overlap allowed (the protector draws on top); 3 radio variants
  per moment per ship.
- Bosses 3/6/9 escape at 20% and return for the finale gauntlet
  (#3 -> wave -> #3+#6 -> wave -> #3+#6+#9 -> THE INVADER). Nobody dies;
  the ending loops back to Space Dash.
- Alpha pop-ups with white text everywhere; wave titles at the center;
  "TAP ANYWHERE TO PLAY"; no rocket system; smooth drift/steer motion;
  dynamic per-ship colored tails.

## SHIPPED

- [x] PASS A: tracker + GDD (invaders.md) - the full contract preserved
- [x] PASS B: 64 assets (tools/v032_invaders_art.py): 7 crew hulls from the
      Kenney sets (the owner's edit call), 11 enemies, 10 bosses, 11 planet
      plates (real data), projectiles/VFX/items; provenance in ASSETS.md +
      the manifest
- [x] PASS C: 27 inv_* voices + inv_tour + inv_finale
      (tools/v032_invaders_sfx.py)
- [x] PASS D: game/games/invaders/invaders.gd (~2.6k lines): the wave
      director (7 formation patterns), the 11-kind roster (dive/blink/burn/
      split/splitter/weave laws), 10 bosses with named specials (volley,
      shardring with the seam law, dustdash, mimicbeam, acidrain, craters,
      prominence, heatwave, voidflower, blink, elitecall...), the gauntlet
      chain, the breach law, the alpha-dialogue queue (intro/stage/boss/
      escape/radio tables), DEFEND with the radio, the shop (thunder/bomb/
      themes) + optionals ship picker, the dynamic tails, the sfx wiring
- [x] PASS E: registry (hen -> invaders at the END of the playable chain),
      game_base ach match (+5 ids), flow_test (9 playable / 6 teasers, the
      spud/maze/poptd queue, the invaders chain + banner + all_owned laws),
      tests/invaders_probe.tscn (60+ law checks)
- [x] PASS F: assets/thumbs/invaders.png via thumb_composer (scene_invaders),
      Xvfb qa_v032 (7 shots: ready card, the fight, the thunder beam, the
      defender wing, the duke, the breach, the Hideout sky)
- [x] ALL SUITES GREEN: flow_test + invaders/dash/slasher/xo/merge/dario/
      snake/tower/geometry probes
- [x] version 0.3.2 (base 30412); build + ONE push + the release

## THE LESSON (why this file exists twice)

v0.3.2's first build was complete and died unpushed. This rebuild was built
with the owner's push law in force - one push, at the very end - and the
tracker (brainstorms/invaders_v032/TRACKER.md) holds every owner requirement
so no future reset can eat the SPEC again. The spec survives on GitHub even
when the sandbox does not.
