# PLAN v0.1.9 — THE SNAKE GOES TO WAR (+ box fixes)

Owner directive order: **box fixes first → snake fixes → snake additions.**
Reference study: HAKORADev/Python_Game_Box_PGB — the 2D python snake (grid,
A* AI, temp obstacles) and Snake3D (the web game the owner spent a week on;
its powers system IS the spec source: golden/immortal/growth/speed/slow/black,
20% power chance, weighted spread, 10s board expiry, bugs = -10 length -10
score WITHOUT death, wrap via open sides, BFS+flood-fill CPU brain).

## A. Box fixes (do first)
- [x] "NOT PLAYED YET" lie: quitting a run mid-turn never counted a play
  (`Box.record_run` only fired at finish). FIX: `Box.record_started(id)`
  (plays +1, daily round +1, last_ts) called by the host the moment the game
  instance exists; `record_run` keeps score/best/last only.
- [x] LEAST PLAYED went empty: it EXCLUDED everything already in the LAST
  PLAYED strip (a 2-game box = empty list). FIX: always list all owned+played,
  sorted fewest-plays first, oldest-play tie-break, max 10.
- [x] SOON tile "?" tail too short (owner: "add more blocks... like a real ?").
  FIX: scene_soon extends the glyph tail block-by-block; regenerate the 6
  workshop thumbs + proof sheet.
- [x] Battery-full is a bare SFX. FIX: popup in the Achiever style
  ("BATTERY FULL! - <game> batteries are fully charged") - the signal now
  carries WHICH pool filled (box bank = the bank itself).
- [x] Snake shop lets you "buy" with a dry wallet (just errors) and prints
  naked numbers ("120" - 120 WHAT?). FIX: gray-out unaffordable (disabled),
  every price wears the GOGACoin icon. RULE → docs/AGENTS.md §6.

## B. Snake fixes
- [x] Start speed 430 -> 300 (owner: "it has to be a little slower than that").
- [x] One-part body: the circle-chain is DEAD. The body is ONE smooth ribbon
  polygon (smoothed trail path -> per-vertex width + per-vertex gradient
  colors via draw_polygon) + a soft outline pass. No beads. TOO smooth.
- [x] Controls: hold-half taps are DEAD. New input = an INVISIBLE ANALOG
  WHEEL: touch anywhere -> that point is the wheel center; drag = stick;
  stick angle = the head's TARGET heading in absolute screen space
  (drag left = head aims screen-left EVEN when the head is upside-down);
  capped turn rate does the actual bending; release keeps the heading.
  Works identically in both orientations (screen-space by construction).
- [x] Orientation is ASKED, not sensed: before tap-to-start, a select screen
  (VERTICAL / HORIZONTAL cards with phone-position art) OVERWRITES the
  auto choice. The field is rebuilt as a letterboxed rect of the chosen
  aspect (9:16-ish / 16:9-ish) - the base for future position-specific play.
- [x] Eat particles match the eaten thing (apple = REDS, not blue).

## C. Snake additions
- [x] MODE select (after the position select): CLASSIC (walls) / NO-WALLS
  (wrap edge-to-edge). No-walls is OPEN FROM START.
- [x] OPTIONALS strip (left-right scrollable boxes inside the mode menu):
  ENEMY (open from start, 1 green snake), POWER-UPS / BUGS / OBSTACLES
  (shop unlocks), FRUITS (selector: apple only / all owned / a specific one).
  Locked optionals wear a lock + price and tap through to the shop.
- [x] ENEMY AI (green, smooth, same physics): value-based target choice -
  coin = 1.0, apple = 0.5 (two apples = one coin), score-boost makes apples
  profitable again; probes ahead to not die; wrap-aware in no-walls.
  BIG-brain: when clearly longer than the player it tries to WRAP AROUND
  the player's head (orbit-and-tighten). Dies permanently for the round
  (no respawn); the run ends only when the USER dies.
- [x] ENEMIES PACK (shop, THE most expensive item): up to 10 enemies at
  once, each its own color (green base + 9 pack colors), count picked from
  the optionals ENEMY box. Unlocks the SNAKE-EATER power.
- [x] POWER FRUITS (one shop unlock): the powers live in special fruits
  with distinct auras - all different spawn weights, spawn cooldowns and
  durations (owner: never uniform randomness):
    SLOWER x0.72 speed 12s - FASTER x1.45 8s - GHOST (phase through bodies
    + obstacles; edges still kill) 7s - MAGNET (coins fly to you from far)
    10s - GOLDEN (apples score x3 while active) 10s - WITHER (POWER-DOWN:
    fruits SHRINK you instead of growing) 8s - SNAKE-EATER (pack only:
    bite enemy TAILS ONLY on contact: enemy loses segments, you grow) 10s.
  Powers apply to the AI too - symmetric, and each power CHANGES the AI:
    vs player-GHOST encirclement is pointless (goes farming);
    vs player-SNAKE-EATER it fears the head and keeps distance;
    when IT is FASTER it hunts (cuts the player off);
    when IT is SLOWER it farms the far side;
    vs player-MAGNET it contests coins harder;
    vs WITHER-cursed player it gets aggressive.
- [x] BUGS (shop unlock): wander the field, occasionally STEAL the current
  fruit (it respawns elsewhere), and hitting one costs length + score but
  NEVER kills (the Snake3D lesson: BUG_PENALTY without death).
- [x] OBSTACLES (shop unlock): 2-4 solid rounded blocks per round, placed
  with a spawn-safe zone, deadly to BOTH snakes, work in both modes.
- [x] FRUITS (per-fruit shop items): banana, cherry, orange, grapes,
  strawberry, pear, lemon, peach, watermelon, pineapple - hand-painted
  vector art in the game's own draw language; eat particles match the fruit.
  Owned fruits feed the optionals FRUITS selector (randomize the edible).
- [x] SHOP REWORK: scrollable sheet with labeled sections in order:
  SKINS / FRUITS / POWER-UPS / BUGS / OBSTACLES / ENEMIES. Every price with
  the coin icon; unaffordable = grayed out + dead.
- [x] HUD: active-power chips (icon + shrinking timer bar) and enemy score
  chips (one per enemy, its color).
- [x] SFX: power_good (bright chime), power_bad (wobble down), tail_bite
  (crunch), bug_hit (squish) - synthesized, re-runnable script.
- [x] Persist: mode + optional toggles + fruit selection in Box progress.

## D. Tests + ship
- [x] flow_test: record_started semantics (plays on start), snake shop items
  API, least-played list no longer excludes, battery popup signal carries title.
- [x] snake_probe: extended - orientation select flow, mode select, wheel
  steering smoke, wrap in no-walls, enemy spawn/hunt/eat, power effects,
  bug hit, obstacle death, fruit variants paint pass, snake-eater bite.
- [x] Version: 0.1.9, base 30280 (arm32 30281, arm64 30282).
- [x] Build both APKs, push, CI green.
