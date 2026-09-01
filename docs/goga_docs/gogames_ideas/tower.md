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
