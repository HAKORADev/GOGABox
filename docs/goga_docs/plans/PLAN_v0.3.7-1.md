# PLAN v0.3.7-1 — THE BIG PATCH (the owner's 22-item round + the extras)

The report covered v0.3.6-4 and v0.3.7 at once. One massive patch, the
owner's own words: "all of these stuff in one patch, feels massive, take
your time doing everything accurately and test it carefully and manually
and do many visual tests".

## THE GAME FIXES (items 1-17)

1. **SNOWY TOWER THE REAL FLIP LAW** — the square (and every body wearing
   the GEOMETRIC style) no longer tumbles like a wheel: it PIVOTS over its
   leading edge in discrete 90-degree flips, a side falls, the next face
   slaps down (thud + dust), the center rides the real pivot arc (draw
   space lift). In the air it tumbles free; the landing settles onto the
   nearest flat face.
2. **THE INNER-SQUARE FIT LAW** — the geometric platforms' motif squares
   stood taller than the platforms and hung out of them; they are centered
   and capped inside the block now.
3. **THE CUBE-FIRST LAW** — GEOMETRIC stays closed until the GEOQUARE
   square is owned; while the style is worn the character shelf is CLOSED
   (the matrix cube wears every body).
4. **THE COIN TRUTH LAW** — the golden-orbit coin is dead; GOGACoins stay
   the REAL GOGACoin asset in every style.
5. **THE x2 TRUTH LAW** — the air jump used to launch WEAKER than the
   ground jump (0.92x), so quick double-taps read as dead; the air jump
   hits full strength +2% and the widget states READY/USED.
6. **THE OVERLAP FIX (geometry flash)** — `_chunk_mixed`'s L1 deck's last
   two blocks sat inside the ground 2x2 pair; every shape owns its x-space
   now (the deck moved past the pair, the chunk widened).
7. **THE ENDLESS WAIT LAW** — the ready gate scrolls the world but the
   generator stopped: after ~30s of lore-reading the ground ENDED and a
   start dropped the square into the void. The wait feeds its own floor:
   flat ground + roof extend forever, zero threats.
8. **THE BLUE CIRCLE IS DEAD** — the tap_ring sprite is gone from the gate.
9. **THE BEHIND LAW** — the ready gate hides while the lore speaks (it
   used to paint OVER the dialogue box); the maze shop got the same fix
   (the visual QA caught it there too).
10. **THE RICH WORLD DECKS** — six new chunks (GATE, VALLEY, WAVE,
    ISLANDS, HIGHWAY, TOWERS) + a richer calm breath + a wider pool: the
    in-betweens carry real ups and downs, and the repetition window is
    gone.
11. **THE REAL MAP SHOT** — the maze thumbnail is an in-game capture now:
    the capture harness drives a LATE map (map 24) with the PATH FINDER
    live, then the neon finisher (saturate + bloom + vignette) makes it
    cooler. `dev/thumb_capture/maze_finish.py` + `drives/maze_drive.gd`.
12. **THE TAILS** — the Geometry Flash ribbon shelf travels to BOTH shops
    (maze + snowy tower): same six tails, same prices. The tower ribbon
    wears in GEOMETRIC; the maze ribbon follows the square.
13. **THE CLEAN GATE** — the maze's how-to subline is gone (the guide
    owns the teaching).
14. **THE SHY FINDER** — 4 cells ahead (was 8), and the marks CASCADE in
    one by one (0.12s apart).
15. **THE CONTROLS RESURRECTION** — THE HEADLINE BUG: TouchKit's `swiped`
    signal carries TWO arguments and maze's `_swipe_dir` declared ONE —
    every swipe died inside the signal call ("Method expected 1 argument
    (s), but called with 2"). The instrumented probe caught the ERROR
    verbatim; `tests/maze_touch_probe.gd` now drives the REAL touch path
    (press → drag → release through Input.parse_input_event) and holds
    7/7. One signature - the whole game came alive.
16. **THE SHOP BUTTON** — the maze shop was fully built and its opener
    never wired; the SHOP button takes its seat in the HUD row.
17. **THE NO-TELEPORT LAW (pong)** — the finger writes a TARGET now; the
    pad GLIDES to it at a speed proportional to the gap (x14/s, clamped)
    - responsive, never a jump. The owner's own design.

## THE NEW CONTENT (items 18-20)

18. **SNAKE THE ENDLESS MODE** — the third play mode, 1500 (the priciest
    thing on the snake shelf), gated behind owning it AND 3+ selected
    snakes. A x3.2 wall-less world with a following camera, the pack
    spawns 1.2-1.8 screens away, the fruit spawns 1.5-2.0 screen
    diagonals out (the owner's numbers) and the FRUIT COMPASS ARROW
    rides the top strip pointing at it, sliding with the bearing.
19. **COSMIC SPUD THE ARSENAL** — the MOLOTOV PEEL (a thrown bottle that
    leaves a burning pool for 3.4s - the fire damages everything that
    comes close), the FALLOFF LAW (bombs deal 100% at the center to 35%
    at the rim), the REAL BURN (the DOT scales with the hit that lit it -
    the FLAME TATER is a flamethrower now) and the LEVEL SIGNATURES:
    every ally's L2/L3 adds a behavior, not a number (drone twin shot /
    pierce, turret faster sweep / explosive shells, guard wider aura /
    the dread slow, medic stronger care / the searing care, bomber bigger
    blast / the scorched dive, scout deeper marks / the triple burst).
    **THE GORE** (the teens round): blood sprays on every real hit, bombs
    GIB enemies into gravity-borne skin chunks, blood stains fade on the
    ground, fire really burns (the charred modulate + flame motes).
20. **KEY SINGER RETIRED** - the owner's call ("not a real game... remove
    it"). The first 5 FUTURE_GAMES.md names park as SOON teasers: DOMINO,
    CHECKMATE, FOUR IN LINE, FIVE LINES, DOTS (names change later; the
    reveals sit at appear_after 7-11 / needs 8-12).

## THE BOX LAWS (items 21-22 + the extras)

21. **THE LADDER** - the reveal rework: snake is the only level 0; every
    next rung depends on the games before it, escalating to cosmic spud
    at level 13. The vocabulary mixes per rung - chains (rally L1,
    hopper L4), order mysteries with CONNECTED cross-game orders (lanes
    needs pong played + beaten; slasher needs lanes spend + pong plays;
    merge needs hopper earn + slasher spend; dario needs merge plays +
    merge trophies; invaders needs dario spend + xo plays; geometry needs
    pop siege trophies + matcher spend; maze needs geometry earn + pop
    siege plays), an inbox timer (xo at 45 min), charge meters
    (matcher 150 + orders, pop siege 250, cosmic spud 400) and
    needs_games that climbs 2..13. The mysteries surface a few rungs
    early (appear_after = level - 3) so the player always sees WHAT is
    coming and WHAT it wants.
22. **THE HONEST BADGE LAW** - a tile that was never hidden does not
    celebrate: a fresh save badges NOTHING (the shelf is furniture, not
    news). NEW! belongs to a real appearance (HIDDEN -> anything), the
    green UNLOCKED! to a real resolution. The self-heal can never
    re-smear a badge onto the furniture.

### THE ACHIEVEMENTS OVERHAUL (the extra round)
- THE RULE TABLE: the conditions live in the registry now - each entry
  carries `{"tier", "rule": {"k": "score"|"cnt"|"max"|"stat", "key",
  "v"}}` and game_base evaluates them all. THREE OLD TROPHIES WERE DEAD
  (jelly/icecrash/parcels never joined the old match table; peace and
  challenge counted counters nobody bumped) - data cannot rot like that.
- THE TIERS: bronze/silver/gold/platinum ride the entry and color the
  popup. Every game wears a real ladder now (5-19 trophies, escalated
  thresholds, the testing-era easy ones retired).
- THE FINDER TROPHY LIVES: maze bumps `finder_used` now (the old
  "Cheater" had no counter site - dead).

### THE AGE RATING SYSTEM (the extra round)
- The +3..+21 ladder with the owner's full descriptions AS CODE COMMENTS
  in registry.gd (the agreement's future brick). The box SHIPS AS +9:
  `GameReg.BOX_MAX_AGE` filters the shelf - anything stricter is hidden
  completely (playable + workshop + the feed).
- Every game re-tagged; cosmic spud wears +9 (the owner: "even shadow
  fight is +7 and we are just going to add some effects, make it +9 so
  it not get removed").
- THE "!" DOOR in settings: first knock = the AGREEMENT (placeholder
  text - the real one ships later; DISAGREE does nothing on purpose -
  "it will remain closed anyway and gated"), then the AGE RATES sheet:
  the whole ladder + the +9 shipping truth + the ILLEGAL row, visible
  and GATED. (The search-keyword drama was rolled back by the owner
  himself: "FUCK THAT" - only the honest door remains.)

### GOGAds - THE IN-HOUSE ADS (the extra round)
- `game/core/gogads.gd` (autoload): the three sources - BAKED (the
  owner's index at assets/gogads/index.json + media), DEV (runtime
  register_dev_ad: tags + media + link + text; THE SHARED SYSTEM - dev
  ads serve other games that define no break of their own), LINK (the
  device browser fetches the page/video itself).
- THE BREAK: a game calls `GOGAds.maybe_interstitial(game_id, "start"|
  "end")`; the registry entry configures it:
  `"gogads": {"end": {"frequency": 3, "total": 6, "tags": [...]}}` -
  frequency = every Nth event, total = the daily cap (resets 12AM).
- THE SPEC: tags (English lists in code) + subs (violence/horror/
  gambling/adult/illegal/general families) + the LEVEL 0..3 WTF-ometer
  (an ad wears one level or a range; a break reads a window).
- THE PLAYER: full-screen, portrait + landscape, 10s..10min, skippable
  after 10s, a tap PAUSES and shows the bottom go-to link bar (the
  owner sets the text). Desktop never crashes (no media = a styled
  GOGAds card).
- The host wires the START break (after the game joins) and the END
  break (at finish). Snake carries the first sample break.

## THE DOCS (the extra round)
- FUTURE_GAMES.md: the zombie-hunter-inspired vertical rogue-like joins
  the parking lot (gamesnacks study; alien-shooter energy, NOT a
  horizontal spud sibling) + the dated ship notes.
- The stale md sweep: the graduates' notes marked shipped, no detail
  lost (the journal style: dated addenda, never silent edits).

## Tests
- flow_test ALL PASS (the ladder, the badges, the meters, the feed, the
  registry 14 playable + 5 teasers).
- probe_v037p1 180/0 (the new systems: the ladder, the honest badge, the
  tiered rules, the age wall, GOGAds, the flip law, the tails, the
  endless mode).
- maze_touch_probe 7/7 (the REAL input path - the resurrection proof).
- maze_probe 28/0, tower/gf/cs/pong probes ALL PASS.
- THE VISUAL QA (Xvfb, the owner's "many visual tests"): 10 rigs -
  tower_geo (the squares fit + the real coin), tower_tail (the ribbon),
  gf_mixed (no overlap), gf_ready (no blue circle), gf_lore (the gate
  behind), maze_shop (the button + the tails shelf + the BEHIND fix),
  maze_tail, maze_finder (the cascade), snake_endless (the camera + the
  compass), cs_gore (the arena flow). Found + fixed the maze sheet
  z-order bug.

## Version
- projects.json: 0.3.7-1 / version_code_base 30810 (arm32 30811, arm64
  30812) - THE PATCH NAMING LAW honored (a real patch number, never
  "PATCH N" words).
- NO release (the law) - push, CI green, the owner tests everything.
