# BRICK BREAKER — GDD (v0.3.9-7)

Graduated from the BRICK STORM teaser (registry id `brickbreaker`, the
owner's rename law: "brick breaker is a genre and not a trademark name").
The owner's own spec, verbatim-shaped into laws. Landscape only.

## THE OWNER'S LAWS (binding, from the v0.3.9-7 message)

- **THE RENAME LAW**: "first, rename it to brick breaker". The teaser
  BRICK STORM ships as BRICK BREAKER.
- **THE HORIZONTAL LAW**: "the game is horizontal only for now (for extra
  space for more bricks)" - orientation `landscape`, like dot eater.
- **THE INFINITY LAW**: "it must be infinity ... infinite levels with
  different sizes and structures ofc". And: "the game will offer
  different levels always so it feels fantastic and always different ...
  not just a weak design that look like 'another level = extra line of
  bricks with the latest line requires more hits'". A pattern generator
  with REAL archetypes, mirrored layouts, growing HP/ice/decor - never
  one shape reshuffled.
- **THE HEART LAW**: "3 hearts, one extra heart for each 1000 brick
  points". Life is lost only when ALL balls are out ("note that life
  point taken only when all balls are out"). Hearts never reset.
- **THE POINT LAW**: "a point is calculated as hits on one brick, some
  bricks may take 3 or even 10 hits, the one that took 3 hits give 3
  brick points while the one took 10 gives 10". Points = damage dealt,
  awarded as it lands (each hit pays 1; metal pays 2). A frozen brick's
  ice layer takes the extra hit first and that hit pays too.
- **THE SCORE LAW**: "score will be based on levels, each level cleared
  gives 1 score point, score bonus is /3" - registry coin_div 3, the dot
  eater shape. Brick points are NOT score (the hearts' currency).
- **THE COIN LAW**: "a gogacoin will appear after each 300 bricks, not
  brick points, real [bricks] broken, in one of the bricks" - every 300th
  break promotes a random alive brick into the coin carrier (a golden
  shine); breaking it pays the GOGACoin.
- **THE GATE LAW**: "the game will start with the 'tap anywhere to start'
  no optionals menu...yet". The silent gate (dot eater's shape). The shop
  still sells - that is merchandise, not options.
- **THE PING-PONG CONTROL LAW**: "the controls will be like the game ping
  pong exactly, with the same smooth 'platform follows finger' thing" -
  hold anywhere, the paddle glues to the finger's X with smoothing.
- **THE FAIR TIMER LAW**: "what makes brick breaker a good challenging
  game rather than long-time tactical game is having a timer that puts
  you to the limits, a timer that is logically possible to beat but not
  too easy to achieve from spamming ball at bricks. The algorithm should
  calculate size of level, numbers of bricks, number of required hits,
  any powerups pre-calculated and...that's it, so it stay fair". Time
  out = a heart lost + a fresh timer. A ball out keeps the clock running.
- **THE DROP LAW**: "2% of bricks have powerups and each one appears
  after 40% of bricks broken - it appears at the 40%th brick and drops
  from it". The first carrier is FORCED at the 40% mark (promoted when
  the mark is crossed), the rest ride the 2% spread. Drops fall; catch
  them with the paddle.
- **THE SHOP-MAKES-DROPS LAW**: "each powerup should be bought from the
  shop for a good price so it really be able to appear in the game" -
  only OWNED powerups join the drop pool. Own nothing, nothing drops.
- **THE BUNDLE LAW**: "the two-sided ones that make big/small slow/fast
  should be as one bundle, will be more cool" - PADDLE (wide/small),
  SPEED (fast/slow), SIZE (big/small) sell as three bundle rows.
- **THE CAP LAW**: paddle grows with no ceiling "except the walls" and
  shrinks to a hard floor (never invisible); ball speed x5 the ceiling
  with a hard slowness floor; ball size x0.25..x5 "with a size limit".
- **THE RESET LAW**: "powerups get reset after each level (life points do
  not reset per levels ofc)" and "make sure losing life resets the level
  powerups ofc". Metal/fire wear 15-second timers; the two-sided effects
  last the level (until a reset).
- **THE VISUAL LAW**: "speed be ball>> but size be ball but two up arrows
  and the multiplier" - the effect chips wear a mini ball icon: speed =
  ball + >> arrows + xN; size = ball + double arrows + xN; paddle wears
  its own mini paddle icon.
- **THE NO-WEAPON LAW**: "some brick breaker games add a powerup that is
  basically giving the platform a weapon to shoot the bricks, this
  eliminate the wow-factor for me btw so i do not want it". NEVER.
- **THE FROZEN LAW**: "frozen bricks ... the frozen layer is external
  layer that takes extra hit to reveal what is the brick under it".
- **THE DECOR LAW**: "decor platforms ... unbreakable ones that set there
  to make the design more different and make the game more tactical
  where user could try to make the ball bounce from one to the other".
- **THE THEME LAW**: 5 themes, "a default theme could be sky-blue with
  fat joyful tone, also the neon one should be a theme" - and every theme
  REDRAWS the bricks its own way (fat rounded gloss / glow outlines /
  twin-stroke flat / stone bevel / candy pastel), not just the palette.
- **THE SKIN LAW**: 5 paddle skins + 5 ball skins, first of each free.
- **THE FX LAW**: "brick breaker relies on audio feedback yes, but i want
  it to have both audio and visual cool designs" - crack lines grow per
  hit on fat bricks, break = fade + particles, ice = crystalline shards,
  fire/metal wear their own tone + trail, bricks fade in LINE BY LINE
  from top to bottom at every level intro, powerups/win sounds everywhere.
- **THE OWNER'S ASSETS**: the owner uploaded a brick-breaker asset pack
  (the Drive zip): 10 SFX/music + brick/ball/bat/boundary art. The audio
  is vendored verbatim (renamed bb_*), the sprites feed the thumbnail and
  the palette study; the game art itself stays code-drawn (the box law).

## THE ECONOMY

price 450 (the teaser's), fee 8, coin_div 3 (score bonus /3), shop true,
banner true, landscape, free play (no charges/daily caps - the endless
ladder is the game). Achievements: the tiered ladder (levels per run,
brick points per run, total bricks, coins, plays).

## THE TIMER FORMULA (the fairness core)

    hits   = sum(1 + ice + hp) over breakable bricks
    bricks = breakable count
    trip   = 2 * arena_h / ball_speed            (one paddle round trip)
    hpc    = clamp(cols * 0.5, 4, 12)            (hits per crossing, est)
    time   = 8 + 0.32 * bricks + (hits / hpc) * trip / 0.55
    time  *= level_mercy(level)                  (1.12 -> 1.0, level 8+)
    clamp  [30, 300] seconds

Tuned against the headless auto-player simulation (the qa rig plays real
levels with a tracking paddle and the formula must sit ABOVE the median
sim time and BELOW the p90 + mercy band - "logically possible to beat,
not too easy to spam").

## THE PATTERN GENERATOR (the infinity core)

Level = grid (cols 9..17, rows 5..11, growing) + archetype + seeded
params, LEFT/RIGHT MIRRORED (the pacman symmetry law - mirrored reads
designed, random noise reads broken):

- archetypes: FILLED WALL, PYRAMID, ARCH + PILLARS, CHECKER, FORTRESS
  (shell + core), RAIN COLUMNS, THE RING, ZIGZAG BANDS, THE TWIN TOWERS,
  THE DIAMOND, TUNNELS (decor corridors)
- hp band grows with the level (1-1 .. 2-9), ice chance climbs then caps
- decor (steel) pieces come from the archetype (pillars, ring walls,
  tunnel shells) - they never seal the play field (floodfill-verified)
- every level is validated: breakable count > 0, the ball can REACH every
  breakable brick (open-cell floodfill), the serve lane is clear

## THE v0.3.9-8 REPAIRS (the owner's first test-report round)

The owner played v039-7 and filed the report; this round wears all of it.

1. THE SMALL BRICK (the scale law): the grid is native-small now -
   cols 25..43, rows 11..19, a L1 brick ~47px wide (the old one was
   ~205px = 4.4x bigger) with a MASS CAP that thins any level past 260
   bricks (the worn-wall sprinkle). "3-5 times smaller, so you can put
   way more bricks."
2. THE WALL LAW: every level seeds its own ARENA WIDTH FRACTION
   (0.56..1.0 of the view, a climb + a wobble) - the walls MOVE per
   level, small courts and big courts, the paddle and the frame follow.
3. THE LAUNCH LAW: the serve WAITS - the ball rides the paddle; holding
   dips the platform and charges (0.75s to full); the release smacks
   the ball up to +55% faster and the boost decays to base over ~2.4s.
   A quick tap is a plain launch.
4. THE REVIVE LAW: a life lost SHATTERS the platform (its own crumb
   burst), the flicker rebuilds it (~0.9s), then the stall serve waits
   for the launch. (hearts never reset)
5. THE CONTACT LAW (the 2-hit bug): the old rig could penetrate TWO
   bricks in a seam, bounce out of one, and the next substep re-damage
   the other - a 2-hit body died to one contact. The cure: a per-ball
   damage cooldown (45ms) + the bounce resolves against the DEEPEST
   penetration cell. The qa wears a live reproduction rig now.
6. THE FIRE LAW: the burn is a NUMBER - x3 damage per brick per pass
   (the burned map: one burn per brick per pass), NOT the old
   melt-everything full burn.
7. THE OVERRIDE LAW: fire and metal are ONE state - the newest catch
   wins, the other burns out on the spot.
8. THE SURPRISE LAW: carrier bricks (powerups AND coins) look NORMAL -
   no circle, no shine. The drops and the pops are the reveal.
9. THE COIN DROP: the coin pops out of its brick as a proper-scale
   golden body, falls with gravity and spin; the paddle's catch is the
   sparkle; the grant rode the break (the economy never changes).
10. THE SKY'S PURE GRADIENT: the sky theme draws NO grid lines
    (the shader's line_str uniform; the other flat pages keep a
    whisper).
11. THE HONEST ROUNDED BRICK: the rounded-rect helper is ONE polygon
    now (the old rect+circles composite double-blended under alpha and
    read as square edges), and the fat shadow is rounded with it.
12. THE BREAK FADE: the dying brick SHRINKS into its center while it
    fades (the old one zoomed IN - the owner: "it should get smaller").
13. THE SCREEN-SPACE GATE: the gate lives in the HUD CanvasLayer now -
    the old gate anchored to a game-root Control whose rect some hosts
    never size, and the label landed off-screen bottom-right.
14. THE GENERATOR, retuned for the small grid: the running-bond wall
    (was a solid slab), 2x2 checker, the thinned arch/rain/towers, two
    NEW archetypes (the BUBBLES polka clusters, the CROWN with three
    spikes), the hp band climbs slower (1-1 .. 2-8, the 10-hit bodies
    still exist late), the fair timer wears work units
    (8 + 0.45/brick + 0.60/hit, the trip scale keeps the slow-ball
    fairness, mercy 1.40/1.20/1.0, clamp 40..540) - calibrated against
    the auto-paddle sim at the new scale.
15. THE DOT EATER'S COIN (the pacman round): the GogaCoin after each 3
    mazes was placed and eaten but NEVER DRAWN - it wears the real
    coin icon now (the gold pulse like the rush orb).
