# SNOWY TOWER — the v0.2.5 journal

The owner's doodle-jump-shaped port grew up. The GDD arrived in one message
while the box was still riding the zero-bug Space Dash high, with the PGB
reference attached: "this repo (Python_Game_Box_PGB) v1.3.8 see the game
there. the current game is little good".

## THE OWNER CONTRACT (kept verbatim in spirit)

- the PGB platform types come home: static / moving / blinking /
  disappearing / moving_blinking, the START platform, and the slide-up
  logic — one score point for each platform you go up, BUT:
- THE SCORING CATCH: "if the ball jumped and like skipped 3 platforms and
  landed on the 4th, make it give 1 score point and if the ball landed on
  the lower ones, give nothing!" — score = landings ABOVE your best, +1
  each, skipping still pays exactly 1, lower pays nothing
- TWO WALLS: "they will work to prevent platforms from going out of screen
  and player too"
- the slide climbs x1.1 for each 10 platforms (the PGB 1.1 ** (score // 10)
  law, kept exactly)
- "remove the snow ball mouth, keep it with eyes and make it look better"
- "make the background really moves in a cool way" — two parallax layers
  (mountains 0.16, trees 0.38) + drifting clouds + a sky shader whose sun
  and moon ride their own slower parallax
- THE STAR MECHANIC — physical snow: "make it rain snow that is physical
  and lands on platforms and the ball get slowed-down and like heavy from
  colliding with it, will be visually cool and fun" — flakes fall with
  wind, LAND on platforms (the white cap grows) and on the TOP of the ball
  (you accelerate slower and jump weaker); rolling sheds it, landing pops
  a chunk off
- CONTROLS: "at the bottom left, make two arrows, at the bottom right,
  make a circle, arrows to go left-right and circle to jump one jump,
  when moving while on platform, make the circle spin so it goes upside
  down" — the ball ROLLS while it walks
- GOGACoins "spawn between 5-25 platforms counted from last coin
  on-screen, not based on last collected, because it may go out of screen
  for real here"
- "make score bonus be /10" — registry coin_div 10
- FOUR POWERUPS from the shop that spawn in runs, 10 seconds each: x2
  double jump, up-arrow big jump, >> speed, and (the addendum) "-50%" slow
  slide; "make the UI of powerups to be visualized inside the jumping
  circle ... the circle will have a life circle, i mean time circle that
  is a color goes from full to empty after 10 seconds"
- SHOP: 4 characters — "i guess we could make different snow balls? like
  square and triangle with different ways of spinning? will be funny!" +
  "maybe an egg skin too, each one with different physics and different
  look and different reaction to falling snows"; platform skins "default
  sand and another one as rock and another as metal and another as grass,
  but these will need harder designing work to make sure a rock isn't
  just a color setting"; "you could make day and night really give
  different feeling than just different backgrounds"
- THE LESSON: "my v1.3.8 python snowy tower game have bad design, the
  colors are too random, do not fall into same mistake!" — ONE designed
  palette, every decoration deterministic per platform index
- THE PROCESS: "i recommend you to test the visuals before shipping, like
  visualize the code shape you working on" — the Xvfb QA round is law now

## WHAT SHIPPED

- hopper.gd rebuilt end to end (~1500 lines, everything drawn in code):
  the PGB generator (weighted types + THE RELIABILITY LAW: an unreliable
  platform is always followed by a reliable one), reachability-checked
  placement under the real jump arc, wall-clamped patrols
- the slide-up law: sleeps before 2 platforms, then SCROLL_BASE * 1.1 ^
  (score/10), capped at x6 for playability, halved by the -50% powerup
- the physical snowfall: 110 flakes, global wind, per-platform snow caps,
  the ball's top-cap catchment (a flake only sticks where snow actually
  lands), per-character stick/shed multipliers
- the four characters: Snowball (rolls), Ice Cube (tumbles in exact
  90-degree steps, sluggish, sheds on landing), Shard (glass-light,
  floaty, snow barely sticks), Eggy (wobbles, slides forever, snow loves
  it) — eyes for everyone, mouth for NOBODY
- the four platform skins drawn as materials, not color swaps: sand
  (grains), rock (facets + a crack), grass (blades + one flower), steel
  (brushed band + rivets) — the snow cap lands on ALL of them
- the places: Morning Slope (day) and Night Slope (night = palette +
  moonlit world modulate + stars + TWO aurora ribbons + crescent moon in
  the shader — "really give different feeling")
- the controls: two hold-arrows + the jump circle with the powerup life
  ring INSIDE it (owner UI law), powerup glyph under the chevron
- shop: characters (0/400/600/800), platform skins (0/300/300/450),
  places (0/400), powerups (250/250/300/350)
- audio: 8 designed SFX (jump poof, snow-crunch land, music-box coin,
  sparkle arpeggio, fade chirp, icy wall thud, ice cracks, the
  slide-whistle fall) + a 32s winter music-box theme
  (tools/v025_sfx.py — committed this time)
- the box: all_owned is now THE ALWAYS-PLAYABLE CHEAT (owner: "ignores
  all limits and make the games always playable even if there is no
  enough coins/batteries/playtime-window and like that") — windows,
  daily caps, fees and both battery pools all flatten under it; the
  pre-play page shows PLAY FREE and the game-over sheet's PLAY AGAIN can
  never be blocked either
- FUTURE_GAMES.md: "tap the frog" joins the study shelf
- tests: tower_probe (50+ laws, 12/12 stable — the harness seats the
  player on forced-solid platforms and re-seats every tick of the walk
  laws), flow_test grew the /10 + shop-shape + price-floor + cheat laws,
  Xvfb QA: 14 shots (day run, snow load, powerup ring, coin+pickup, 3
  characters, 3 skins, night, shop)

## THE BUGS THE PROBE CAUGHT BEFORE THEY SHIPPED

- the sprite never followed the body (player.position was write-once) —
  the ball froze mid-air while its logical self climbed
- the landing check was a fixed window (miss one frame, fall through
  forever — the QA's slow Xvfb frames exposed it) → SWEPT landing
- snow stuck to the ball's whole column (fresh snow outpaced shedding) →
  the catchment is now the ball's TOP cap only
- a probe-only lesson written down for the future: a seated test harness
  dies silently the moment its platform type can blink — force the seat
  solid and re-seat every tick

## THE v0.2.6 VERDICT ROUND (the owner playtested v0.2.5)

The owner came back with a list — and the list was right. Every line,
root-caused and fixed:

- THE DEAD JUMP BUTTON: the jump circle's `_gui_input` subtracted
  `global_position` from a touch position that is ALREADY local — every
  press landed far outside the circle. The probe had driven `_do_jump()`
  directly, so the real input path was never tested. The buttons died
  anyway (below); the probe now drives the REAL input path.
- THE OWNER'S OWN CONTROLS replaced them: LEFT half = an analog move
  zone (the first touch anchors; the finger's X offset from the anchor is
  the FORCE — a dead point back at the anchor, full force at ~110px,
  left-right only, Y ignored, tracked by touch index). RIGHT half = tap
  to jump. Multi-touch safe.
- THE BACKGROUNDS: the mountains + tree lines + aurora are GONE. Day is
  a calm gradient + a SMALL round corner sun (the snake game's size law,
  radii computed from the real viewport — the old UV orb stretched weird
  on portrait) + drifting clouds. Night is a deep gradient + a small
  crescent moon + ROUND star lights (dust + breathing glints — the first
  draft drew square blocks: a `step` fills the whole grid cell, the fix
  is a point distance inside the cell) + drifting night sparks.
- THE NIGHT LEAK: day → night → day came back DARKER. `_day_night()`
  re-added a CanvasModulate and freed the old one by NAME; on the second
  switch Godot @-renamed the new node (same-frame name collision with
  the not-yet-freed old one), so the third switch's lookup MISSED and
  the night tint survived forever under its renamed handle. ONE
  CanvasModulate in a member var now; only its color swaps. Probed +
  shot (day after night is exactly day).
- REAL TUMBLING: the cube rotated in instant 90° snaps ("just updating
  its look this weird way" — the owner). Now the cube and the shard
  pivot CONTINUOUSLY over their leading corner/edge (θ = v / r), a
  support-height law lifts the drawn body so the falling side RIDES the
  platform, and stopping eases the body onto its nearest flat face with
  a soft SLAP (new tower_slap.wav). Inertia decays in the air.
- THE START PLATFORM paid +1 and a PHANTOM COIN spawned right on it
  (`next_coin_idx` started at 0 — the coin sat exactly where the ball
  spawns and was collected at run start). Start platform pays NOTHING
  (`highest_idx` starts AT it), the first coin waits 5-25 platforms up.
- THE FAKE SNOW: the caps filled so fast every platform looked
  pre-snowed. Platforms are BORN BARE now, fill flake by flake (retuned
  rate), the cap draws as flat wide domes that grow (the eyeball rounds:
  circles read as balls; squares are wrong; flat ellipses read as snow),
  moving platforms shake their snow off, blink-off platforms drop theirs.
- MELTING (the owner's v0.2.6 upgrade): a shop item (500), toggled ON/OFF.
  ON: the character eats the snow UNDER it and grows toward x1.5 (hard
  cap — "not too much"); moving fast eats at a lower rate (down to ~30%
  — "the faster the move the higher the consumption time and lower the
  consumption rate"); no snow under it and it SHRINKS until the run ends
  at x0.42 (tower_melt.wav drips, tower_puff.wav death, a live MELT
  chip in the HUD). Its own risk loop against the slow-filling caps.
- THE POWERUP WIDGET ON TOP: glyph + name + seconds + a draining bar
  (the life ring inside the jump button died with the button).
- BANNERS: every game wears the ad banner now EXCEPT the tower (the
  owner: its controls live at the bottom) — pong insets its court in
  both orientations, dario lifts its JUMP button, the shared
  `banner_safe_px()` helper moved into the game base.
- SFX: tower_melt / tower_slap / tower_puff join (tools/v026_sfx.py).
- tests: tower_probe grew the v0.2.6 laws (start silence, first-coin
  distance, the REAL input path — right-half tap jumps, the analog zone
  anchors/dead-point/Y-ignoring, melt grow/eat/speed-floor/shrink/death,
  born-bare + moving-sheds, tumble continuity + settle, the one-modulate
  leak law, the widget); flow_test grew the banner law + melt constants.
  ALL PASS. Xvfb QA re-shot 16 and eyeballed BEFORE shipping (the
  owner's rule) — it caught the square stars, the ball-snow and the
  stretched orb, none of which any headless law would catch.

## v0.2.7 — THE VISIBILITY ROUND + the challenge picks (owner verdict II)

The owner played v0.2.6 on the phone. The tower's bones held (controls,
snow, melt) but the pickups were GHOSTS and the game was too easy. The
round:

- THE COINS WERE NEVER DRAWN. The arrays fed collection logic only — the
  owner "magically collected" invisible coins. The pickup painter landed
  (pick_layer): the REAL coin.png (the snake law) + the owner's FADE-IN
  (~0.35s alpha+scale ramp) + breathing pop + a warm halo; powerup pickups
  paint their glass capsule + glyph with the same fade law. (The v0.2.6 QA
  shot 06 parked a coin and eyeballed nothing — the lesson: an eyeball shot
  of an EMPTY spot proves nothing; the shot must show the thing.)
- THE POWERUP SPAWN BUG: next_pick_idx was born 0 and the old
  `next_idx > 4` guard skipped the branch at idx 0..4 — the counter froze
  at 0 and NO powerup could ever spawn in ANY run, ever. The owner's new
  law: one RANDOM powerup every 20-40 platforms counted from the last
  SPAWNED (on-screen) one; the first waits 20-40 up.
- THE EMPTY WIDGET: the melt chip sat between speed and coins forever
  blank; its whole panel hides while MELTING is off, and the powerup
  widget moved TOP-LEFT next to the score (the owner's spot).
- THE BANNER LAW REVERSED: the tower wears the banner like every game
  (the owner's call); the fall-death line insets above the strip.
- THE BREAK: jagged deterministic cracks that lengthen + widen with the
  grace clock, chips popping off while it cracks, then the platform
  SHATTERS into 4-6+ physical chunks (gravity, spin, fade, sized by the
  platform's own width, colored by the equipped skin). tower_break.wav.
- BLINK SNOW: the cap STASHES when the platform goes invisible and comes
  back with it — snow appears and disappears WITH the platform (the
  owner's own fix; no more shed-while-ghost drift).
- THE SHARD MATH FIX: the old settle target (+-1.094 rad) laid a SIDE ON
  TOP — the triangle balanced on one corner ("not landing on its sides").
  The true edge-down stance is +-(pi - phi) = +-2.0474022 rad; the pivot
  radius is now the ACTUAL lowest-vertex distance; the probe proves two
  verts share the lowest height at the settle stance (a side rests).
- TWO NEW KINDS: SIZE platforms (30+) breathe wide<->small smoothly
  (0.55..1.30 of base width, de-phased clocks, wall-clamped, reliable);
  DROPPER platforms (50+) drop away under you when you land (accelerating
  to x920), wait below the screen, then rise home — the rider rides the
  dy (jump off in time); unreliable (the next platform is always safe).
  Both wear a small carved mark so the player can plan.
- THE RAMP (owner: "after 25 platforms start making jumps wider"): the
  vertical gap lerps toward min(205, 82% of the char's real jump ceiling)
  over the next 90 platforms, and the horizontal spread widens under the
  DESCENDING-branch reach law t = (v + sqrt(v^2 - 2gh)) / g — wide jumps
  demand a full-speed run + a late leap. Every jump stays possible.
- tests: tower_probe grew the v0.2.7 laws (pickup spacing, painter +
  coin texture, banner, size breathing band, dropper drop/wait/return,
  the ramp bounds, the shard geometry, the snow stash, the shatter);
  flow_test's banner law reversed (EVERY game carries one). ALL PASS.
  Xvfb QA (qa_v027) eyeballed before shipping: visible coins, top-left
  widget, mid-air chunks, breathing width, chevron drop, the true side.
