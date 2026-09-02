# CURSED DARIO — the v0.3.1 journal (born)

The owner's verdict on the old dario: "it's broken, and even my PGB v1.3.8
dario game is the worst design ever". So the whole game is rebuilt from
the lore out. THE LORE CAME FIRST:

> Dario fell into this world from a Witcher's curse. The goal of the game
> is to ESCAPE. Ten levels, and the last mission before the end line is
> the Witcher herself: crush her by stepping on her head ~20 times while
> she shoots curses. Beat her: +100 score, and Dario runs to the open
> ground and escapes... except a shot comes from BEHIND, from the Witcher.
> He never escaped. On replays the start dialogue and the story pop-ups
> change — Dario is cursed in this world forever, he has deja vu, he talks
> like he knows this place, like he is living in a dream.

## THE OWNER'S CONTRACT (v0.3.1)

- a simple MARIO-LIKE — no shooting for Dario; jumping on enemies kills
- 10 designed levels; the 10th is the Witcher fight
- the entry is EXPENSIVE: 100 coins per play (registry fee 100)
- run bonus /10 (registry coin_div 10)
- enemies: ground walkers, flyers, shooters; different score per kind;
  some have shields, some take 1-3 hits; spike enemies that are only
  stompable at the right timing; burning platforms that hurt Dario if he
  lingers
- "?" blocks and bricks: one may hold a GOGACoin (up to 5 per level), a
  powerup, or nothing — the block area shows EMPTY if the powerups are
  not bought from the shop
- POWERUPS (shop items, real prices): STRONG FOOT (double stomp damage
  until the level ends or death), SHIELD (absorbs one hit or shot — not
  falls), POWER JUMP (x2 jump height until the level ends or death)
- 3 lives; a death restarts the same level and costs -200 score
- buyable NIGHT theme (the game shop): different sky colors, a moon
  instead of a sun
- moving platforms + tricky enemy placements
- CONTROLS like the snowy tower: the left screen half walks (left/right),
  the right side jumps
- a dialogue box at level 1; a 10-second story pop-up over Dario at every
  level start; different lines at each level end; the Witcher gets her
  own unique line; replays shuffle the cursed variants
- banner ads in a position that suits BOTH phone positions
- the thumb + the guide + the lore (this file)

## THE STORY BEATS (the pop-up script)

- L1 start: the fall + the confusion. L1 end: the world is wrong.
- L2..L9: the curse tightens — the woods repeat, the signs are familiar,
  the Witcher's laughter behind the trees, dario's deja vu grows.
- L10 start (unique): SHE is waiting on the open field. "YOU WILL NEVER
  LEAVE, LITTLE HERO."
- L10 win: +100, the escape runs... the shot from behind. The replay
  dialogue pool: deja-vu lines ("this place... I have seen it before",
  "the trees repeat", "am I dreaming?", "she always shoots last").

## THE BUILD NOTES

- level data: tile strings per level (10 maps) in the game file
- physics: hand-rolled AABB on a tile grid (no engine physics) — the
  same style as the snowy tower's controls
- the camera: horizontal scroll following Dario, clamped per level
- the HUD: hearts-lives (3), the score, the level plate, the banner
  reserve at the bottom (both positions)
- achievements: the Witcher slain (once), 10 levels cleared in one run,
  100 enemies stomped total

## v0.3.1 — WHAT SHIPPED

- the registry: Cursed Dario, fee 100, bonus /10, shop on, the lore desc
- ten hand-authored tile maps (12 rows), hand-rolled AABB physics, the
  snowy-tower controls, the camera with the banner-aware clamp
- the roster: snail (+10, patrol), fly (+15, sine), spitter (+20, aimed
  bolts), blocker (+25, 3 stomps, mad face when hurt), spiky (+30, the
  spikes cycle — stompable only while down), THE WITCHER (+100, hp 20,
  aimed double curses, the unique taunt)
- the ? blocks: the per-level loot cycle with max 5 coin boxes; power
  boxes live only when their powerup is OWNED (else the box art is the
  EMPTY one — "the area of spawn will show empty"); bumping a block
  with a powerup grants it for the level (strong foot / shield / jump)
- the shop: the night theme 800, STRONG FOOT 1000, THE SHIELD 1200,
  POWER JUMP 1000
- the story engine: the first-play script per level (start + end), the
  cursed replay pools (deja vu lines), the Witcher's unique line, the
  ending (the escape run -> the shot from behind -> ENDING_SHOT)
- the art: the CC0 Kenney Platformer Art Deluxe (OGA) vendored (the
  license is in the pack) + the painted pieces in the same flat style
  (tools/v031_dario_art.py) + 12 voices (tools/v031_sfx.py)

## v0.3.1 PATCH II - the owner playtest round (this is the law now)

- the shop overlay BUG: closing freed only the sheet's center - the DIM
  (mouse_filter STOP) stayed and ate every tap. THE PAIR LAW (merge2048's
  _shop_pair) is now dario law: capture dim+center at open, drop BOTH at
  close, and a buy rebuilds the sheet EXACTLY ONCE (the old tail stacked
  copies of the sheet).
- the movement BUG: TouchKit tracks ONE press - holding LEFT + tapping
  RIGHT replaced the press and walking died on the first jump. Dario now
  reads raw ScreenTouch BY INDEX: the first left-half touch owns the
  analog walk anchor, any right-half press edge jumps. Two real thumbs.
- the theme toggle: an owned night sky wears a WEAR THE NIGHT / WEAR THE
  DAY switch (Box.unequip_item added for it).
- the score table rebalanced: snail 5, fly 10, spitter 15, blocker 20,
  spiky 25, the Witcher 100 (the owner: "why did the weakest give me
  10?").
- the dialogue: the game OPENS with the scrollable story square (THE
  CURSE) + DONE; replays get the deja-vu variant. Story pop-ups are now
  WHITE bubbles with BLACK text riding OVER DARIO'S HEAD.
- the coins live INSIDE the ? crates (max 5 a level) and POP OUT on the
  bump - no free-floating coins anywhere.
- THE WORLD: continuous ground (no gaps, no floating grass), every
  shelf/mover/ghost a 2-tile jump, every crate bump-reachable, the goal
  trophy snaps onto the ground. Level 10 = the compact arena with the
  GHOST PLATFORM LADDER (2.1s on / 1.5s off, offset phases, blink
  warning) - the owner's own timed-climb design to her head.
- the boss: she haunts her summoning ground (swing around her base, not
  a hardcoded x), appear->idle frames, mercy iframes after every stomp
  (no bounce-into-hurt chain).
- THE ART: Pixel Adventure by Pixel Frog + Sunny Land parallax forest
  (both free for commercial + non-commercial; mirrors + provenance in
  docs/ASSETS.md). The Witcher is the Ghost recolored + a baked pixel
  witch hat; the spikes are REAL frames now (spikes-out = deadly).
- the sky is screen-space (the old world-space sky scrolled away with
  the camera) and samples its color from the forest art; below the
  ground is dark soil.
