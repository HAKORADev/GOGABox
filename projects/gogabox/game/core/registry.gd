class_name GameReg
extends RefCounted
## The game list. Adding a game = add one entry here + a <id>.gd in
## game/games/<id>/<id>.gd (each game = its own folder = its own room)
## + a thumbnail assets/thumbs/<id>.png. Nothing else.
##
## Metadata carried per game (consumed by the help screen + search filters):
##   desc     one-liner shown in the ?-guide list
##   controls how to play lines (guide sheet)
##   genres   {"main": [<=3], "sub": [<=3]}   (GameBox-compatible limits)
##   age      "everyone" | "kids" | "teens"
##   charges  {"per_round": n, "capacity": n, "regen_minutes": m}  GOGABatteries (omit = free play)
##   banner   true -> this game's own view carries the ad banner (opt-in;
##            v0.2.6 THE OWNER LAW: every game wears one except the snowy
##            tower - its controls live at the bottom; games reserve the
##            strip with the shared banner_safe_px helper)
##   hours    {"from": h, "to": h}  playable only inside the window (local time)
##   blocked_hours {"from": h, "to": h}     NOT playable inside the window
##   reveal   {"kind": "chain"|"orders"|"inbox"|"real"|"direct", ...}
##
## v0.1.5 THE SHARED UNLOCK VOCABULARY (the owner's "make it a GOGABox
## shared system" rule): EVERY way a game gets owned / played is a
## declarative registry key - a future game picks a COMBINATION, the box
## code reads the keys and never learns a new game by name. Nothing here
## replaced an older path; each version ADDED a key:
##   price + shop        buy with GOGACoins (the original path)
##   reveal.*             how the tile appears (chain/orders/inbox/real/direct)
##   reveal.needs_games  must own N games before the buy resolves
##   charge_unlock       GOGACharges meter to pour in (100/200 tiers) pre-buy
##   entry.partial_pay   thin wallet pays min(fee, ALL coins) at entry/retry
##   hours/blocked_hours time-of-day windows (live "unlocks at nn AM/PM")
##   daily_rounds / daily_minutes  per-day caps, 12AM 00:00 lazy reset
##   charges             per-game GOGABattery pool (per_round/capacity/regen)

const GAMES := [
        {
                "id": "snake", "title": "Snake", "tag": "the classic, silky",
                "script": "res://game/games/snake/snake.gd",
                "thumb": "res://assets/thumbs/snake.png",
                # v0.1.8: BOTH orientations - the mode is chosen once, when
                # the game loads, from how the phone is held right then.
                "orientation": "auto", "dim": "2d",
                "coin_div": 2, "price": 0, "fee": 10, "shop": true,
                "banner": true,
                # v0.1.5 SHARED ENTRY POLICY (was the v0.1.4 snake-only
                # hardcode): partial_pay = a thin wallet pays min(fee, ALL
                # its coins) at entry AND retry, empty wallet plays free.
                # Declarative now - any future game just wears the same key.
                "entry": {"partial_pay": true},
                "desc": "The classic gone to war - steer a smooth one-part snake with mouse-style swipes, pick your position and place (classic milk, day garden, night garden), choose PEACE or the war, and outsmart AI snakes that hunt, encircle and steal coins. Death folds the whole body into the head.",
                "controls": ["touch anywhere and SWIPE - the head bends where your finger moves; swipe speed = turn sharpness, resting finger = straight",
                        "each fruit = 1 point, +length (width follows, both ways); the speed grows x1.1 every 10 points - watch the x1.00 chip",
                        "NO-WALLS mode wraps edge to edge as a straight line - exit at 80, enter at 80, same heading; you CAN bite yourself",
                        "PEACE style: fruits only, no coins, no score bonus, and you can never die on yourself",
                        "power fruits wear auras: slower, faster, ghost, magnet, golden, wither, SPRINT/SLOG (+/-50% speed FOREVER), snake-eater - it bites tails AND your own body costs length, not the run",
                        "PLACES live in the shop: classic is free, the day garden (sun + shadows) and the night garden (moon, stars and tiny flies) cost GOGACoins",
                        "bugs steal the fruit and bite (never death); obstacles kill everyone; big enemies try to wrap around you - the run only ends when YOU die"],
                "genres": {"main": ["arcade"], "sub": ["retro", "singleplayer", "survival"]},
                "age": "everyone",
                "ach": [
                        {"id": "score_30", "title": "Snack Time", "desc": "Score 30 in one run"},
                        {"id": "score_60", "title": "Long Boi", "desc": "Score 60 in one run"},
                        {"id": "score_100", "title": "Anaconda", "desc": "Score 100 in one run"},
                        {"id": "coins_100", "title": "Coin Collector", "desc": "Grab 100 GOGACoins total"},
                ],
        },
        {
                "id": "rally", "title": "PONG", "tag": "goals win",
                "script": "res://game/games/rally/pong.gd",
                "thumb": "res://assets/thumbs/rally.png",
                "orientation": "auto", "dim": "2d",
                "coin_div": 4, "price": 150, "fee": 8, "shop": true,
                "reveal": {"kind": "chain"},
                "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},
                "banner": true,   # v0.2.6: the court insets above the banner
                "daily_rounds": 6,   # v0.1.4: 6 rounds a day, resets 12AM 00:00
                "desc": "Real pong now: goals pay points, every hit heats the ball x1.1 until it burns red, coins and powerups ride the court, and the extra walls hunt YOU. The pause menu's END banks the run.",
                "controls": ["hold anywhere - your platform follows the finger along its axis", "a goal for you +1, a goal on you -1", "every hit heats the ball x1.1 until the next serve", "END in the pause menu banks the earnings"],
                "genres": {"main": ["arcade", "sports"], "sub": ["retro", "competitive", "singleplayer"]},
                "age": "everyone",
                "ach": [
                        {"id": "rally_15", "title": "Warm-Up", "desc": "Return the ball 15 times in one run"},
                        {"id": "rally_30", "title": "Wall of Paddle", "desc": "Return the ball 30 times in one run"},
                        {"id": "score_50", "title": "Table Legend", "desc": "Score 50 in one run"},
                ],
        },
        {
                # v0.2.3 patch RENAME (owner: "the current game called
                # geometry flash is not like my geometry flash game, rename
                # it to space dodge, we will work on it later"): same game,
                # same id, same thumb - the name is honest now. The REAL
                # Geometry Flash returns to the workshop below as a SOON
                # teaser + the parking lot doc.
                # v0.2.4 THE REDESIGN (owner: "renaming it again to space
                # dash will be better for my plans" + the full GDD): the
                # lane-dodger with falling blocks is GONE - Space Dash is a
                # tons-of-enemies shooter now: kills are score, four
                # weapons, loot from wrecks, hearts, per-weapon power
                # ladders, kill-driven difficulty, skins/spaces/weapons
                # shop. Real Kenney hulls only (owner: no code ships). The
                # id stays `lanes`; the journal lives in
                # docs/goga_docs/gogames_ideas/dash.md.
                # SAME-VERSION PATCH (owner: score bonus /50, shop prices
                # "for real"): coin_div 20 -> 50, the whole shop ladder
                # re-priced (skins 1200-5500, weapons 2500-4500, shield
                # 3000, spaces 1500/2000).
                "id": "lanes", "title": "Space Dash", "tag": "kill the sky",
                "script": "res://game/games/lanes/lanes.gd",
                "thumb": "res://assets/thumbs/lanes.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 50, "price": 200, "fee": 20, "shop": true,
                "reveal": {"kind": "chain"},
                "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},
                "banner": true,   # v0.2.6: the bottom strip is dead space here
                "blocked_hours": {"from": 1, "to": 8},
                "daily_rounds": 6, "daily_minutes": 15,
                "desc": "Five lanes, a sky FULL of enemy ships, four weapons. Kills are score, wrecks drop loot, and the war only gets harder the more you kill. Buy ships, weapons and spaces in the shop.",
                "controls": [
                        "tap the LEFT / RIGHT EDGE to move one lane that way - the walls block you",
                        "press the MIDDLE of the screen to shoot - rapid taps and holding both fire",
                        "kills are score: every wreck pops +nn, and the deep sky only gets meaner the more you kill",
                        "wrecks drop loot: a GOGACoin every 5-10 kills, power points for the held weapon, weapon + shield items once bought in the shop",
                        "3 hearts; +1 heart per 1000 score; a crash costs -500 score and one heart - the last death ends the run",
                        "yellow beams upgrade into more beams; the red laser pierces whole columns (2s live / 0.5s cd); thunder chains ship to ship (5s live / 2s cd); the bomb launcher blasts a radius (2s cd)",
                        "weapon power ladders 0/1/3/6/10/15/20 PER weapon - dying drops the held weapon 3 rungs",
                        "some ships wear shield bubbles; shatter carriers spin invulnerable shards - shoot the gap that faces you; rare UFO elites fire shotguns",
                        "the shop sells ship skins, the laser/thunder/bomb weapons (they join the loot), the shield power, and 3 spaces - no options menu, just fly"],
                "genres": {"main": ["action", "arcade", "shooter"], "sub": ["retro", "singleplayer", "survival"]},
                "age": "everyone",
                "ach": [
                        {"id": "score_500", "title": "Blooded Wings", "desc": "Score 500 in one run"},
                        {"id": "score_1500", "title": "Sky Reaper", "desc": "Score 1500 in one run"},
                        {"id": "kills_100", "title": "Century Hawk", "desc": "Kill 100 ships in one run"},
                        {"id": "kills_300", "title": "Ace of Aces", "desc": "Kill 300 ships in one run"},
                        {"id": "dash_max", "title": "Fully Armed", "desc": "Max a weapon's power (20)"},
                ],
        },
        {
                # v0.2.9 THE REWORK (the owner: "currently it's too bad"):
                # the position ask (each position = different physics), the
                # real slicing (the fruit splits along YOUR cut), the hearts,
                # the +N/-N reader, the vegetable shop, /15.
                "id": "slasher", "title": "Fruit Slasher", "tag": "swipe everything",
                "script": "res://game/games/slasher/slasher.gd",
                "thumb": "res://assets/thumbs/slasher.png",
                "orientation": "auto", "dim": "2d",
                "coin_div": 15, "price": 250, "fee": 15, "shop": true,
                "reveal": {"kind": "chain"},
                "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},
                "banner": true,   # v0.2.6: the bottom strip is dead space here
                "daily_minutes": 20,   # v0.1.4: 20 play-minutes a day
                "desc": "Fruit fly, your finger is the blade - for real: the fruit splits along YOUR cut and the halves tumble. Choose your position first - portrait tosses from below, landscape lobs across. Every fruit +1, every fall -2, three hearts, and a slashed bomb takes one. A GOGACoin rides by every 20 seconds. The shop sells the vegetable basket.",
                "controls": [
                        "pick a position - portrait and landscape throw differently",
                        "swipe THROUGH a fruit to cut it where your finger crossed: +1",
                        "a fruit that falls unsliced costs -2 - the score never goes below 0",
                        "three hearts; slash a bomb and one bursts - lose all three and the run ends",
                        "cut several fruits in one fast swipe and the top reads +1 +2 +3; falls flush as one -N",
                        "a GOGACoin flies by every 20 seconds - slash it like a fruit",
                        "the shop's vegetable basket (1500) adds a fruits/vegetables toggle in the options",
                ],
                "genres": {"main": ["action", "arcade"], "sub": ["hacknslash", "singleplayer"]},
                "age": "everyone",
                "ach": [
                        {"id": "hearts_full", "title": "Untouchable", "desc": "End a run with all three hearts"},
                        {"id": "score_300", "title": "Sharp Blade", "desc": "Score 300 in one run"},
                        {"id": "slash_100", "title": "Juice Bar", "desc": "Slash 100 fruits total"},
                ],
        },
        {
                # v0.2.5 THE REDESIGN (owner GDD, whole contract - the PGB
                # v1.3.8 platform types live again, but everything around
                # them grew up): the tap-hop doodle clone is GONE. Snowy
                # Tower is now a REAL climber: 5 platform types from the
                # python original (static/moving/blinking/disappearing/
                # moving_blinking + the reliability law), TWO walls that
                # keep platforms AND player on screen, the scroll starts
                # lazy and climbs x1.1 per 10 platforms (the slide-up law),
                # PHYSICAL snow that lands on platforms and loads the ball
                # down (slow + heavy, sheds as you roll), arrows + a jump
                # circle (the ball ROLLS as it walks), score = platforms
                # climbed (skip 3 land the 4th = +1, lower landings = 0),
                # GOGACoins every 5-25 platforms counted from the last coin
                # ON SCREEN, run-end bonus score/10 (registry coin_div).
                # SHOP: 4 powerups that spawn in runs (x2 double jump / up
                # arrow big jump / >> speed / -50% slow slide, 10s each,
                # the life ring lives inside the jump button), 4 characters
                # (ball / square / triangle / egg - different physics,
                # different spin, different snow reaction), 4 platform
                # skins (sand free + rock/metal/grass - shader-cut, not
                # color swaps), and the NIGHT place (day/night really feel
                # different). Everything drawn in code - designed palette,
                # no random colors (the owner's v1.3.8 lesson). The journal
                # is docs/goga_docs/gogames_ideas/tower.md.
                "id": "hopper", "title": "Snowy Tower", "tag": "climb till you slip",
                "script": "res://game/games/hopper/hopper.gd",
                "thumb": "res://assets/thumbs/hopper.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 10, "price": 300, "fee": 12, "shop": true,
                "reveal": {"kind": "chain"},
                "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},
                "banner": true,   # v0.2.7: the owner REVERSED the v0.2.6 law -
                                  # the tower wears the banner like every game
                "hours": {"from": 16, "to": 22},
                "desc": "Climb an endless tower of icy platforms while real snow falls, lands and piles up. Eat the snow with MELTING to grow - or shrink away where it's bare. Seven platform kinds, two walls, a scroll that never waits, and jumps that widen the higher you get.",
                "controls": [
                        "touch the LEFT half of the screen and SLIDE your finger: that is the movement - the further from where you touched, the faster and harder, back to your touch point = stop (left-right only)",
                        "tap the RIGHT half of the screen to JUMP - one tap, one jump",
                        "score is platforms climbed: land higher than ever for +1, skipping platforms still pays 1, landing lower pays nothing - the start platform pays nothing",
                        "the scroll starts after 2 platforms and climbs x1.1 every 10 - falling below the screen ends the run",
                        "snow falls for REAL: platforms start bare and catch it flake by flake (moving platforms shake it off), and flakes that reach YOU make you slow and heavy - roll to shed it",
                        "MELTING (shop, toggle): ON, you eat the snow under you and GROW (max x1.5); moving fast eats slower; where there is no snow you SHRINK until the run ends - a real risk",
                        "powerups bought in the shop spawn on platforms: x2 double jump, up arrow big jump, >> speed, -50% slow slide - each 10s, shown in the widget on top with its timer",
                        "GOGACoins hang between platforms (real, visible, fading in) - one every 5-25 platforms from the last coin on screen; powerups now wait 20-40 platforms apart",
                        "after platform 25 the jumps WIDEN toward your real jump ceiling - build speed, time the leap",
                        "past 30 a new kind joins: SIZE platforms that breathe wide and small; past 50: DROPPERS that drop away when you land on them, wait, then rise back - jump off in time",
                        "vanish platforms crack (jagged, growing cracks) and SHATTER into chunks; blinking platforms take their snow with them when they blink",
                        "the shop sells characters (ball/square/triangle/egg, each its own physics and its own real tumbling), platform skins (sand/rock/metal/grass), the night place, the powerups and MELTING"],
                "genres": {"main": ["arcade", "adventure"], "sub": ["platformer", "singleplayer"]},
                "age": "everyone",
                "ach": [
                        {"id": "tower_30", "title": "Warming Up", "desc": "Climb 30 platforms in one run"},
                        {"id": "tower_80", "title": "Above the Clouds", "desc": "Climb 80 platforms in one run"},
                        {"id": "tower_150", "title": "The Stratosphere", "desc": "Climb 150 platforms in one run"},
                        {"id": "hops_50", "title": "Bunny Boots", "desc": "Jump 50 times total"},
                ],
        },
        {
                "id": "merge", "title": "2048", "tag": "swipe and double",
                "script": "res://game/games/merge/merge2048.gd",
                "thumb": "res://assets/thumbs/merge.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 20, "price": 400, "fee": 15, "shop": true,
                "banner": true,   # turn-based: banner is safe here
                "reveal": {"kind": "chain"},
                "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},
                "daily_rounds": 8,   # v0.1.4: 8 rounds a day
                "desc": "The classic brain cooker, rebuilt: a big centered board on warm paper, tiles that really slide and splash. Every fusion pays +1, and every 15 fusions a GOGACoin grows on the board - slide a tile onto it to take it. The OPTIONS sell bigger boards (6x6 and 8x8) and three themes: Classic, Minecraft and a Deep Sea whose water answers every real move.",
                "controls": [
                        "swipe the finger in ANY direction - every tile slides that way, equal tiles merge and double",
                        "each successful fusion is worth exactly +1 score",
                        "after every 15 fusions a GOGACoin grows in an empty cell - slide any tile INTO it to collect (a tile that lands there takes it, even mid-merge)",
                        "the OPTIONS sell the bigger boards: 6 x 6 (bonus /80) and 8 x 8 (bonus /160) - bought once, switching starts a fresh board",
                        "the SHOP sells themes: Minecraft (block tiles, lava-glow numbers, stone + lava sounds) and Deep Sea (glass cells with real water - it moves ONLY when the tile really moves)",
                        "big tiles pulse the board gold; reach 2048 and the run keeps going",
                        "the run ends when no move is left - plan the corners",
                ],
                "genres": {"main": ["puzzle", "casual"], "sub": ["minimal", "turnbased", "singleplayer"]},
                "age": "everyone",
                "ach": [
                        {"id": "tile_256", "title": "Getting Warm", "desc": "Create the 256 tile"},
                        {"id": "tile_512", "title": "Halfway Hero", "desc": "Create the 512 tile"},
                        {"id": "tile_2048", "title": "The Real 2048", "desc": "Create the 2048 tile"},
                ],
        },
        {
                # v0.3.1 CURSED DARIO - the rebuild with lore (dario.md):
                # ten levels, the Witcher finale, the shot from behind.
                "id": "dario", "title": "Cursed Dario", "tag": "escape the curse",
                "script": "res://game/games/dario/dario.gd",
                "thumb": "res://assets/thumbs/dario.png",
                "orientation": "landscape", "dim": "2d",
                "coin_div": 10, "price": 350, "fee": 100, "shop": true,
                "reveal": {"kind": "chain"},
                "banner": true,   # the ground rises above the strip
                "desc": "Dario fell into this world through a Witcher's curse. Ten TALL levels of stomp, dodge and deja vu to the end line - where SHE waits. Crush the Witcher (20 stomps, dodge her curses) and escape... probably. A mario-like with ? crates (the GOGACoins live inside them), timed ghost platforms, hunting bats, a charging rhino, a shop (the night sky, three powerups), 3 lives and a story that remembers you.",
                "controls": [
                        "hold the LEFT half of the screen and slide to walk left/right",
                        "tap the RIGHT side to jump - land on enemies to stomp them",
                        "every enemy kind pays its own points (5 to 25); snails and turtles patrol small lanes, the rhino chases and SPRINT-CHARGES when it faces you - jump it, dodge it, stomp it; the bat HUNTS you",
                        "the spiky turtle kills ONLY while its spikes are OUT (it flashes before they come out)",
                        "bump ? crates from below: a GOGACoin pops out (5 a level), a powerup - or nothing at all; POWER JUMP is exactly twice the jump",
                        "fire burns the lingerer, spikes hurt the toucher, moving platforms carry, and GHOST platforms appear and vanish - time your climb",
                        "3 lives - a death restarts the level: -100 score and everything you grabbed in that attempt is gone",
                        "the shop sells the night sky (wear it or take it off) and the powerups: STRONG FOOT, THE SHIELD, POWER JUMP",
                        "grab every trophy. Beat the Witcher. Escape. (You won't.)",
                ],
                "genres": {"main": ["adventure", "arcade"], "sub": ["platformer", "story", "singleplayer"]},
                "age": "everyone",
                "ach": [
                        {"id": "stomp_100", "title": "Heel of the Hero", "desc": "Stomp 100 enemies total"},
                        {"id": "witcher_slain", "title": "Witcher Slayer", "desc": "Crush the Witcher"},
                        {"id": "clear_10", "title": "The Escape That Wasn't", "desc": "Clear all ten levels in one run"},
                ],
        },
        {
                # v0.2.8 THE SKETCH REMAKE (the owner: "rename it to just XO
                # without the word ladder and remake it"). No ladder, no cash
                # out, no difficulty menu - one adaptive sketch opponent.
                "id": "xo", "title": "XO", "tag": "sketch showdown",
                "script": "res://game/games/xo/xo.gd",
                "thumb": "res://assets/thumbs/xo.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 2, "price": 450, "fee": 10, "shop": false,
                "banner": true,   # turn-based: banner is safe here
                "reveal": {"kind": "chain"},
                "desc": "Sketchbook tic-tac-toe: paper, ink and one adaptive opponent. It wears four profiles (The Wall, The Trickster, The Rusher, The Sage), remembers your last two rounds and stops falling for your patterns. Every win pays +1, every loss costs -1, a GOGACoin lands on the board after every 3 rounds - mark its cell first to take it.",
                "controls": [
                        "tap a cell to draw your X - the red pencil",
                        "win = +1 score, loss = -1, draw = 0 (run bonus /2)",
                        "the CPU is hard to beat but never perfect - it adapts to your patterns for 2 rounds, then forgets",
                        "after every 3 rounds a GOGACoin grows in an empty cell - mark that cell FIRST and it is yours (the CPU can take it too)",
                        "the bank is in the pause sheet: END ends the run and pays",
                ],
                "genres": {"main": ["strategy", "puzzle"], "sub": ["turnbased", "competitive", "singleplayer"]},
                "age": "everyone",
                "ach": [
                        {"id": "wins_10", "title": "Pencil Pusher", "desc": "Win 10 rounds"},
                        {"id": "wins_40", "title": "Sketch Master", "desc": "Win 40 rounds"},
                        {"id": "streak_5", "title": "Unstoppable", "desc": "Win 5 rounds in a row"},
                ],
        },

        {
                # v0.3.3 MATCHER - the happy one, GRADUATED from its v0.1.4
                # teaser (the owner's own ritual is honored: pour 100 charges,
                # own 3 games, 400 coins - the tile was never a mystery).
                # Five modes, the specials earned by matching, the bought
                # power-ups on the ROUND balance, the board-riding GOGACoin.
                "id": "matcher", "title": "Matcher", "tag": "the happy gem wall",
                "script": "res://game/games/matcher/matcher.gd",
                "thumb": "res://assets/thumbs/matcher.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 300, "price": 400, "fee": 10, "shop": true,
                "banner": true,   # the rail seats itself above the strip
                "charge_unlock": 100,
                "reveal": {"kind": "direct", "appear_after": 0, "price": 400, "needs_games": 3},
                "desc": "The happy one - an endless gem wall with EIGHT moods: CHALLENGE (rounds derived from a real pre-solve of the grid, lives and wins/losses on the HUD), PEACE (zen, nothing can hurt you), BUTTERFLIES (they rise AFTER your move - one grace at the top, then the spider dines), ICE STORM (frosted blocks rise behind the gems), DIAMOND MINE (pure dirt, clay and rock layers, dig deep), JELLY (the sweet virus - eat it before it spreads), ICE CRASH (layered ice 1-5 plus the rock only specials crack) and DROP DOWN (bring the parcels home against moves, time or both). THE SPECIALS: an L or T makes the BOMB, a vertical 4 makes the ROW SWEEPER, a horizontal 4 makes the COLUMN SWEEPER and 5 in a line makes the COLOR REMOVER - swap it with anything and its color wipes out bottom-to-up. Powers buy with the GLOBAL GOGACoins; escort the GOGACoin to the bottom row and it is yours.",
                "controls": [
                        "tap two adjacent gems to swap, or drag a gem toward its neighbor - 3+ of a kind pops, everything = 1 score point",
                        "THE SPECIALS: L/T = BOMB (3x3 crater) - 4 vertical = ROW SWEEPER (its whole row) - 4 horizontal = COLUMN SWEEPER (its whole column) - 5 in a line = COLOR REMOVER (swap it with any gem: that color wipes bottom-to-up)",
                        "a GOGACoin materializes on the board 30s after your last one - clear beneath it so it falls to the bottom row and drops out earned",
                        "the bottom rail is ICON ONLY: gray = locked, lit pips = stocked, the name and the prices live in the buy popup - powers pay the FULL GOGABox balance",
                        "CHALLENGE: every round is derived from a pre-solve of YOUR grid - target, moves and time all come from the math; you carry 5 lives and the HUD shows your wins, losses and lives left; a lost round costs 500",
                        "PEACE: no fail, no coins, no power-ups, the END button lives in the pause menu",
                        "BUTTERFLIES: they rise AFTER each move resolves - a butterfly that touches the top gets ONE move of grace (the spider stirs), then it dines",
                        "ICE STORM: frosted blocks rise BEHIND the gems - a horizontal match melts 3 segments, a vertical match destroys the column, a full column ends the run",
                        "DIAMOND MINE: a new pure-dirt row lifts the board every 25s (the top row glides away) - dirt digs in one match, clay in two, ROCK only specials crack; clear a row for +25s",
                        "JELLY: the connected virus starts at the bottom, eats gems and blocks every fall - matches next to it dissolve it, a move with no jelly cleared makes it SPREAD; clear the grid on limited moves",
                        "ICE CRASH: layered ice 1-5 (gems fall straight through it) - hits INSIDE the ice crack one layer, level 6 is a ROCK only specials crack; no damage this move = it spreads",
                        "DROP DOWN: parcels enter at the top line and trade places downward every move - deliver them all before the moves, the clock or both run out (each round rolls one of the three limits)",
                ],
                "genres": {"main": ["puzzle", "casual"], "sub": ["match3", "singleplayer", "relax"]},
                "age": "everyone",
                "ach": [
                        {"id": "match_300", "title": "Gem Fresh", "desc": "Match 300 gems total"},
                        {"id": "match_3000", "title": "Gem Hoard", "desc": "Match 3000 gems total"},
                        {"id": "hyper_1", "title": "Light Touch", "desc": "Create a color remover"},
                        {"id": "cascade_4", "title": "Sweet Tooth", "desc": "Chain a x4 cascade"},
                        {"id": "butter_100", "title": "Moth Keeper", "desc": "Save 100 butterflies total"},
                        {"id": "ice_25", "title": "Ice Breaker", "desc": "Melt 25 ice layers total"},
                        {"id": "depth_20", "title": "Deep Dig", "desc": "Descend to 20m in one mine"},
                        {"id": "peace_300", "title": "Calm Mind", "desc": "Breathe 5 minutes in one peace run"},
                        {"id": "challenge_1500", "title": "Challenge Chest", "desc": "Finish a challenge run over 1500"},
                        {"id": "jelly_500", "title": "Jelly Wipe", "desc": "Dissolve 500 jelly cells total"},
                        {"id": "icecrash_300", "title": "Shattermind", "desc": "Crack 300 ice-crash layers total"},
                        {"id": "items_100", "title": "Parcel Master", "desc": "Deliver 100 parcels total"},
                ],
        },

        {
                # v0.3.2 SPACE INVADERS - the hen workshop teaser, renamed and
                # graduated (the owner's tour: Neptune -> ... -> the Sun, then
                # the Hideout; one war with Space Dash, nobody ever dies).
                "id": "invaders", "title": "Space Invaders", "tag": "hold the solar system",
                "script": "res://game/games/invaders/invaders.gd",
                "thumb": "res://assets/thumbs/invaders.png",
                "orientation": "landscape", "dim": "2d",
                "coin_div": 500, "price": 350, "fee": 100, "shop": true,
                "banner": true,
                "reveal": {"kind": "chain"},
                "desc": "The aliens reached our solar system. Fly the Protector from Neptune inward to the Sun and into their Hideout: ten worlds, ten waves each, a named boss over every one - and three of them will run and come back for the finale. Rent the SSDS crew with DEFEND, buy Thunder or the Bomb Launcher, chase THE INVADER down. Small scores, a big war, and a line that never breaks while you hold it.",
                "controls": [
                        "left half of the screen: slide to fly - the ship steers with you",
                        "right half: tap or HOLD to fire (every crew ship fires something of its own)",
                        "enemies pay +1/+2/+3, bosses +25 to +200; a heart loss costs -500 score",
                        "one enemy past the bottom reaches the solar system - the run is lost. Intercept the divers",
                        "a GOGACoin drifts in every 2-10 waves, a weapon point every 1-2 waves; your ship's own icon feeds its weapon ladder (5 levels, damage = the level)",
                        "DEFEND rents a crew ship for 10 waves - one hit ends its shift, and it never touches your loot",
                        "the shop sells Thunder (an electric beam that chains around itself) and the Bomb Launcher (no ammo, contact fuse only) - the Stage Themes pack paints every world",
                        "bosses 3, 6 and 9 escape at low health and return for the Hideout gauntlet; THE INVADER never truly dies - and neither does the war",
                ],
                "genres": {"main": ["shooter", "arcade"], "sub": ["retro", "singleplayer"]},
                "age": "everyone",
                "ach": [
                        {"id": "score_2000", "title": "Solar Shield", "desc": "Score 2000 in one run"},
                        {"id": "kill_500", "title": "Star Sweep", "desc": "Destroy 500 enemies total"},
                        {"id": "clear_tour", "title": "The Long War", "desc": "Finish the full tour"},
                        {"id": "boss_all", "title": "Duke Hunter", "desc": "Meet all three runaway keepers"},
                        {"id": "defend_3", "title": "Crew Trust", "desc": "Call 3 defenders total"},
                ],
        },

        # ---- the workshop (not built yet, but ALREADY in the feed as teasers so
        # the box keeps growing. Kinds:
        #   orders - quest lines to reveal          (black box ?????)
        #   inbox  - total box play time to reveal  (black box ?????)
        #   real   - real-world hours to reveal     (black box + local notification)
        #   direct - no conditions beyond appear_after: shows up as a LOCKED/GATED
        #            tile right away (name + thumb visible, never a mystery)
        # appear_after = owned games needed before the teaser even shows.
        # needs_games = owned games required to BUY once revealed.
        # charge_unlock = GOGACharges to pour in via the pre-play button before
        #                 the game resolves further (v0.1.4: 100 or 200).
        # daily_rounds / daily_minutes = per-day play caps on real games,
        #                 reset at 12AM 00:00 (v0.1.4).
        # v0.1.4 THE MYSTERY QUEUE: only the first 4 mystery-able teasers
        # (catalog order) exist at once - the rest stay inexistent until a
        # queue slot frees (Roadmap.MYSTERY_CAP).
        # ---- v0.3.4 COSMIC SPUD graduated from the v0.1.x teaser into the
        # REAL game (the Brotato-competitor): the rogue-like top-down shooter
        # with the camera law, the 6 starts, 12 enemies, bosses every 10
        # waves, the drafts with teeth, the XP tree, merging, allies, themes
        # and the cosmic-coin economy. The kill bonus is /200 (the owner's
        # law). The old "real 24h hours" teaser ritual retires with it.
        {
                "id": "cosmic_spud", "title": "Cosmic Spud", "tag": "the potato vs the swarm",
                "script": "res://game/games/cosmic_spud/cosmic_spud.gd",
                "thumb": "res://assets/thumbs/spud.png",
                "orientation": "landscape", "dim": "2d",
                "coin_div": 200, "price": 500, "fee": 50, "shop": true,
                "banner": true,
                "reveal": {"kind": "direct", "appear_after": 0, "price": 500, "needs_games": 3},
                "desc": "THE BROTATO-COMPETITOR: SPUDNIK the potato cosmonaut drops into a ground bigger than the screen - the camera follows, the world keeps going. SIX starts (Soldier/Ranger/Brawler/Engineer/Pyro/Frostbite), TWELVE enemies with real teeth (the aura wraith burns a zone, the mender heals the horde, the TRI-SHIELD wears three rotating crackable rings), elites with affixes and a boss every 10 waves (THE HEAP, THE PRISM MATRIARCH, SPUD REAPER). Waves end into a choose-one-of-three draft that GIVES and TAKES; XP levels open pure tree picks. The GogaShop sells 12 weapons (start with 3, merge copies into higher tiers for half the next price), 6 allies (the highest prices, they deploy in the wave shop) and two themes - DECAYED DESERT and ABANDONED PARK - each with a day and a night face. Everything is bought and sold for COSMIC COINS; kills are the score; XP banks into SPUDNIK's level and gates the tiers. Endless. The swarm never stops growing.",
                "controls": [
                        "touch ANYWHERE and drag: the invisible analog stick is born under your finger - SPUDNIK walks where you pull",
                        "the weapons shoot by themselves at the best target (bosses first, elites next, then the closest) - you only move",
                        "kills are the score: blabs +1, most +2, elites +3, bosses +50 to +100; the GOGABox bonus pays /200 at the end",
                        "every wave ends into a DRAFT: choose one of three cards - each gives a buff, most take something back (or skip)",
                        "XP gems level the run: every level offers three pure tree picks; XP also banks into SPUDNIK's character level, which gates weapon tiers, allies and tree nodes",
                        "the wave shop spends in-run coins: weapons, supplies, ally deploys and (with the WEAPON LAB) merges at half the next tier's price",
                        "the GogaShop (between runs) sells the 9 other weapons one by one, the 6 allies at the highest prices, and the ABANDONED PARK theme - both themes wear a day and a night face",
                        "the skill tree unlocks one node at a time for cosmic coins - OFFENSE, DEFENSE, UTILITY and the LAB that teaches WEAPON MERGING",
                        "the tri-shield's rings only break where you crack them - carve a window through all three rings to reach the core",
                ],
                "genres": {"main": ["shooter", "roguelite"], "sub": ["survival", "singleplayer"]},
                "age": "teens",
                "ach": [
                        {"id": "cs_kills", "title": "Swatter", "desc": "Defeat 500 enemies total"},
                        {"id": "cs_wave", "title": "Wave Rider", "desc": "Reach wave 20 in one run"},
                        {"id": "cs_score", "title": "Spud Legend", "desc": "Score 400 in one run"},
                        {"id": "cs_merge", "title": "Weapon Smith", "desc": "Perform 5 weapon merges total"},
                        {"id": "cs_runs", "title": "Drop In", "desc": "Finish 10 runs"},
                ],
        },


        {"id": "maze", "title": "Escape The Maze", "tag": "procedural maze port", "coming_soon": true,
                "thumb": "res://assets/thumbs/maze.png",
                "desc": "Every maze is generated fresh. Find the exit before you lose your mind.",
                "genres": {"main": ["puzzle", "adventure"], "sub": ["procedural", "minimal"]},
                "age": "everyone",
                "reveal": {"kind": "orders", "appear_after": 2, "price": 400, "needs_games": 2,
                        "orders": [
                                {"type": "beat_best", "game": "rally"},
                                {"type": "earn_in", "game": "lanes", "amount": 150},
                                {"type": "spend_charges", "amount": 50},   # v0.1.4 GOGACharges order
                        ]}},
        # (matcher graduated into a REAL game above - its v0.1.4 direct tile
        # + 100-charge meter ride along with it)
        {"id": "keys", "title": "Key Singer", "tag": "rhythm rework", "coming_soon": true,
                "thumb": "res://assets/thumbs/keys.png",
                "desc": "Hit the keys on the beat. The better your timing, the louder the song.",
                "genres": {"main": ["music", "arcade"], "sub": ["rhythm", "singleplayer"]},
                "age": "everyone",
                "charge_unlock": 200,
                "reveal": {"kind": "direct", "appear_after": 2, "price": 450, "needs_games": 4}},
        {"id": "poptd", "title": "Pop TD", "tag": "tower defense port", "coming_soon": true,
                "thumb": "res://assets/thumbs/poptd.png",
                "desc": "Place towers, pop the waves, defend the base. Classic TD energy.",
                "genres": {"main": ["strategy", "action"], "sub": ["tower-defense", "singleplayer"]},
                "age": "everyone",
                "reveal": {"kind": "orders", "appear_after": 4, "price": 500, "needs_games": 4,
                        "orders": [
                                {"type": "spend_in", "game": "merge", "amount": 200},
                                {"type": "plays", "game": "lanes", "count": 10},
                        ]}},
        # v0.2.3 patch (owner: "add a game called geometry flash put it as
        # 'soon' because the current one will be a new game instead of the
        # geometry flash game i planned for"): the REAL Geometry Flash takes
        # its name back and waits in the workshop as a SOON tile - direct
        # reveal, visible right away, never a mystery. Its dodge-game
        # namesake grew up and is SPACE DASH now (v0.2.4).
        {"id": "geometry", "title": "Geometry Flash", "tag": "the real one", "coming_soon": true,
                "thumb": "res://assets/thumbs/soon.png",
                "desc": "The owner's own Geometry Flash - the name the lane-dodger borrowed until it grew into Space Dash. The real thing is still to come.",
                "genres": {"main": ["action", "arcade"], "sub": ["rhythm", "singleplayer"]},
                "age": "everyone",
                "reveal": {"kind": "direct", "appear_after": 0, "price": 350,
                        "needs_games": 2}},
]

static func get_game(id: String) -> Dictionary:
        for g in GAMES:
                if String(g["id"]) == id:
                        return g
        return {}

static func playable() -> Array:
        var out := []
        for g in GAMES:
                if not g.get("coming_soon", false):
                        out.append(g)
        return out

static func workshop() -> Array:
        var out := []
        for g in GAMES:
                if g.get("coming_soon", false):
                        out.append(g)
        return out

static func playable_index(id: String) -> int:
        var i := 0
        for g in playable():
                if String(g["id"]) == id:
                        return i
                i += 1
        return -1
