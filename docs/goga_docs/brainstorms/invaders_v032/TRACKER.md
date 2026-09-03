# INVADERS v0.3.2 — REBUILD TRACKER (agent's own file)

> Context: v0.3.2 was fully built in a sandbox session that died BEFORE the push
> (commit 5506c88, APKs 30421/30422 - both lost). The owner supplied a fresh
> token; the owner law for THIS rebuild: PUSH ONLY WHEN THE FULL TASK IS DONE.
> Repo state at rebuild start: fa9c60b (v0.3.1 PATCH III).

## THE OWNER'S SPEC (digest - the full contract)

1. Game = **Space Invaders** (id `invaders`), graduates the `hen` workshop teaser (rename).
2. **10 stages, 10 waves each; wave 10 = stage boss; stage 10 boss = THE INVADER (final boss).**
   Stages get stronger + more enemy types per stage.
3. **Horizontal** (landscape). Waves (designed), not infinite spawner.
4. Tour: **Neptune → Uranus → Saturn → Jupiter → Mars → Earth → Venus → Mercury → Sun → Hideout**
   (latest planet to first, then the sun = 9; 10th = the aliens' hideout).
   Each stage background matches its planet's real-world data/atmosphere.
5. Scores: enemies **+1/+2/+3** (small), bosses **+25..+200** (final boss +200).
6. **3 hearts; a heart loss takes −500 score; score bonus ÷500; a new heart every +1000 score.**
7. Controls (snowy tower / cursed dario scheme): **left screen half = move,
   right half = shoot / hold-to-fire.** Multi-touch by index.
8. **No shields** for the user ship. No AI rocket system (the PGB ad-rocket thing stays dead).
9. Shop = **ships 2-in-1**: the 7 SSDS crew ships buyable at HIGH prices, each with its
   exclusive weapon (weapons NOT separately buyable). No mid-run switching.
   Optionals menu (pre-run) = select the ship to start with.
10. The 7 crew + exclusive weapons + tail colors:
    - **Ember** (orange ship, orange tail): red small beams (classic red). Upgrade = MORE beams,
      wider spread (not one direct range).
    - **Azure** (blue, THE PROTECTOR - default, blue tail): blue small balls, yellow-weapon
      speed/cool-downs. Upgrade = more balls, small angle.
    - **Verdant** (green, green tail): green snake-like weaving beams, slow, pass through
      ships dealing damage over time (pierce DPS). Upgrade = more sneaky beams, taller.
    - **Veteran** (bright red, bright-red tail): sound weapon - arch-like open-circle waves.
      Upgrade = bigger + stronger.
    - **Phantom** (normal red, red tail): machine gun, rapid, small damage. Good vs groups.
    - **Hornet** (white, white tail): fire that SPREADS across enemies; upgrade = spreads
      more, more damage, burns longer.
    - **Titan** (deep red, deep-red tail): intense missile **1 per 5 s**, same damage to
      EVERY enemy. Upgrade = more damage.
11. Weapon power: **each power level = extra damage (1 → 2 → 5 ladder)**; power points
    spawn **1 per 1-2 waves**; death takes **3 power levels worth of points** (lanes law).
    Continuous weapons = damage is hits/sec; pierce falloff: the further the hit, the lower
    the damage, floor 1, never 0. Radius weapons (thunder/bomb) = each radius line / chain
    order deals less: 6 → 5 → 4 ... floor 1.
12. Weapon item icons exist and are collectible, **but a weapon item only spawns when the
    current ship is the one the weapon needs** (they feed the power ladder of that weapon).
13. Reworked **Thunder**: sends an ELECTRIC BEAM UP, the beam then affects nearby enemies
    (chain around the beam) - not the lanes "strike nearby" design.
    Reworked **Bomb Launcher**: no ammo limit, detonates ONLY on touching something.
    (These two live in the loot pool like lanes - general items, not ship-exclusive.)
14. Shop item: **Stage Themes pack (high price)** - when bought, every stage wears its own
    color theme; themes cross-fade smoothly on stage change.
15. Spawning: **GOGACoin 2-10 waves after the last one**; weapon point 1 per 1-2 waves;
    powers/coins/items logic same as Space Dash (drifting pickups, magnet-less, floor exit
    = gone).
16. **DEFEND button** (next to SHOP): rent an SSDS defender (any crew ship except the
    user's current) for **10 waves**, GOGACoins pricing, ONE defender at a time, each ship
    callable once per run, defender arrives with **level-3 weapon**, defender **dies to one
    hit**, is **invisible to items** (user takes everything), can overlap the user ship
    (user drawn on top). Call + end dialogues (caller line, called reply) and death line,
    **3 variants each**.
17. **Boss law:** bosses #3, #6, #9 are NOT killed - at low HP they RUN with a lore popup,
    then "recruit" with the final boss. Finale gauntlet in stage 10: boss #3 → strong wave →
    #3+#6 → stronger wave → #3+#6+#9 (finished for real) → THE INVADER descends.
18. Each boss: own special moves/shots, own SFX + VFX + names.
19. **Lore pop-ups** from the Protector: each new stage, boss start, boss end - up to 3
    variants per situation. First dialogue references Space Dash (same universe): the
    protector has been holding the line so the aliens never reach our solar system.
    Ending: the Invader RUNS, the protector chases off-screen, end dialogue with END
    button: the invaders may not be out yet - they are always somewhere nearby.
    (Nobody dies - the loop can replay forever.)
20. **Breach law:** a single enemy passing the bottom = dialogue "an enemy reached our
    solar system and now we are in big danger" + END → death menu.
21. Pop-ups: **alpha panels, white text** - translucent enough not to block the view,
    opaque enough to read.
22. Stages have names; **every wave starts with a centered wave title**; stage themes
    change smoothly.
23. **No position/orientation ask, no optional screens at boot - always "TAP ANYWHERE TO
    PLAY".** Optionals menu exists for ship selection.
24. Ships/enemies: smooth animations - drift, steer, feel real. Enemy design inspired by
    Chicken Invaders archetypes (waves, formations, divers) reskinned as ALIENS.
25. PGB v1.3.8 hen invaders = formation/AI reference only. Its grid formations inform
    the wave director; the rocket system is dropped.
26. Music: 2 loops (tour theme + finale/hideout theme). 20+ SFX voices.

## BUILD ORDER (owner-ordered)

- [x] PASS A: tracker (this file) + GDD (docs/goga_docs/gogames_ideas/invaders.md)
- [x] PASS B: assets - ships (7 crew + variants), enemies (many types), 10 bosses,
      10 planet backgrounds (real data), projectiles/VFX, items, pickups
- [x] PASS C: SFX - 20+ voices + 2 music loops
- [x] PASS D: engine - game/games/invaders/invaders.gd (extends GogaGame, landscape)
- [x] PASS E: integration - registry (graduate hen), game_base ach match, flow_test,
      probe tests/invaders_probe.tscn
- [x] PASS F: thumbnail (thumb_composer), Xvfb QA shots
- [ ] PASS G: all suites green; version 0.3.2 (base 30412); build APKs
- [ ] PASS H: ONE push (owner law) + GitHub Release with the APKs + worklog catch-up

## HARD LAWS (flow_test trip-wires from recon)

- New playable entry goes at the END of the playable block (after xo) in registry GAMES.
- flow_test: playable count 8→9, workshop 7→6, mystery queue hen→out (spud/maze/poptd),
  badge/inbox laws at :548/:592, all_owned teaser law :1514, banner list :365.
- New ach ids MUST get a match branch in game_base.gd check_achievements().
- Probe pattern: direct instantiate, Box.reset_all(), _check(), RESULT line, quit(0/1).
- Thumb 960×640, no baked text. SFX naming prefix: `inv_*`.
- Landscape design 1920×1080 (ScaleRule.DESIGN_LANDSCAPE); read get_viewport_rect() live.
- Every push = ONE push at the end (owner law). Local commits per pass are fine.

# v0.3.2 PATCH I — THE OWNER PLAYTEST ROUND (every snapshot complaint)

The owner tested build 666a3f7 on device and posted 11 snapshots + a fix list.
This patch answers every line of it. Work order per the owner: snapshots first,
then the slasher fix, then the invaders.

- [x] THE SLASHER FIX, FOR REAL: the bug was never the geometry - TouchKit
      emitted anchor->current CHORDS, so a drawn loop swept its own interior.
      touch_kit.gd now emits true polyline segments (prev sample -> current);
      slasher's stale 14px floor dropped to 2px (slow fingers still cut).
      The probe NOW FEEDS THE REAL TOUCHKIT (the old probe called _on_drag
      directly and never saw the bug). Loop-around: no cut. Slow crossing: cut.
- [x] The blue circle / planet object: GONE - backgrounds repainted as pure
      atmosphere (gradient + mood + stars). No objects, no text on the sky.
- [x] The Neptune FACTS popups: GONE - "real world data" lives in the sky
      palette only; the player reads lore.
- [x] The SHIPS button in-game: the stale APK had it; the flow is now
      OPTIONALS-FIRST (the game opens on the crew picker), and the in-game
      HUD carries only SHOP + DEFEND.
- [x] Optionals follows the snake standard: image boxes (the real hull PNG),
      name, state, price chip, green border on the ship on duty.
- [x] The ships ARE the Space Dash ships (the Lanes PNGs, loaded live) -
      player, crew, and the enemies (dash enemy hulls, tinted, 1.6x).
- [x] Dialogues follow Cursed Dario: big moments = scrollable CARD sheet that
      PAUSES the war (stage arrivals, boss meet/kill, escapes, breach, the
      ending); quick radio = alpha white-text bubbles riding ABOVE the
      speaker (dario's follow law, flip-below when cramped).
- [x] Titan: one missile per 5s, contact fuse, SAME 2+level damage to EVERY
      enemy - plus THE REAL BUG: the blast loops iterated `enemies` while
      kills erased from it, SKIPPING everyone after the first kill (the
      owner's "titan does not follow the description"). Every blast loop now
      walks a COPY (missiles, bombs, thunder, arcs, burns). Dense-field
      regression added to the probe.
- [x] Controls: the left half is an ANALOG AXIS now (snowy-tower law: dead
      zone + full at 110px, drift + bank), the right half fires/holds - the
      ship no longer chases the finger around the sky.
- [x] The defender AIMS at the nearest threat (enemies AND the boss - the old
      code idled through boss fights), leans into the shot, and rents its OWN
      weapon flavor (Titan rents the 5s missile, Veteran the arcs).
- [x] Defend menu: image boxes; YOUR SHIP pinned gray; FLEW THIS RUN gray;
      while a defender flies, EVERY hull grays with the waves-left header.
      Rows expand to the sheet width - no more clipped wide buttons.
- [x] SIX power levels (the space dash depth), 6 HUD pips.
- [x] Hearts read "x 3" then the heart shape (the owner's law).
- [x] Boss health = a small alpha % chip riding UNDER the body (z-above,
      anchored to the sprite's real bottom) - the full-width bar is dead.
- [x] Flow: optionals screen FIRST, then TAP ANYWHERE (no controls help -
      it lives in the guide).
- [x] The shop sells the crew as 2-in-1 (hull + weapon, flies NEXT run -
      never mid-run) + weapons + the themes pack; dash-style sections.
- [x] Bosses repainted big (340..560px layered originals); the Mimic is the
      Azure hull's evil twin.
- [x] PATCH II (the owner's second look at the QA shots):
      * THE SKY = the bg_space.gdshader Space Dash literally flies, wearing
        per-planet palettes (themes pack lerps them ~1.5s; without it, Dash's
        own Deep Blue). The painted plates are deleted. No snowball stars,
        no scratch lines - the hashed twinkle starfields + nebulae + the near
        drifting star sprites, exactly the dash design.
      * THE WAVE STRUCTURE: the formation box scales with the viewport now
        (x 0.9-1.55x, y 0.9-1.3x) - no more clumped stacks on wide screens;
        the drift margins scale too.
      * THE "S nn W nn" TOUR WIDGET is back, riding the HUD next to the
        weapon pips.
- [x] Thumbnail recomposed from the new look. Suites: ALL GREEN (flow_test +
      dash/slasher/xo/merge/dario/snake/tower/pong/geometry/invaders probes).
