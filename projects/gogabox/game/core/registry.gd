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
                "id": "slasher", "title": "Fruit Slasher", "tag": "swipe everything",
                "script": "res://game/games/slasher/slasher.gd",
                "thumb": "res://assets/thumbs/slasher.png",
                "orientation": "landscape", "dim": "2d",
                "coin_div": 20, "price": 250, "fee": 15, "shop": false,
                "reveal": {"kind": "chain"},
                "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},
                "banner": true,   # v0.2.6: the bottom strip is dead space here
                "daily_minutes": 20,   # v0.1.4: 20 play-minutes a day
                "desc": "Fruits fly, your finger is the blade. Slash combos for juice, avoid the bombs - one wrong swipe slices the run short.",
                "controls": ["swipe across fruits to slice them", "multi-slices in one swipe = combo", "never touch the bombs"],
                "genres": {"main": ["action", "arcade"], "sub": ["hacknslash", "singleplayer"]},
                "age": "everyone",
                "ach": [
                        {"id": "combo_5", "title": "Fruit Ninja Moves", "desc": "Slash 5 fruits in one swipe"},
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
                "id": "dario", "title": "Dario", "tag": "run, jump, stomp",
                "script": "res://game/games/dario/dario.gd",
                "thumb": "res://assets/thumbs/dario.png",
                "orientation": "landscape", "dim": "2d",
                "coin_div": 60, "price": 350, "fee": 12, "shop": false,
                "reveal": {"kind": "chain"},
                "banner": true,   # v0.2.6: the JUMP button lifts above the strip
                "desc": "A proper little platformer - run, jump, stomp. Three levels of pits, walkers and coins, and a flag at the end of each.",
                "controls": ["hold the left / right half to walk", "JUMP button (or swipe up) to jump", "land on walkers to squash them (+5)", "touch a walker sideways or fall into a pit and the run ends", "reach the flag to clear the level"],
                "genres": {"main": ["adventure", "arcade"], "sub": ["platformer", "retro", "singleplayer"]},
                "age": "everyone",
                "ach": [
                        {"id": "stomp_25", "title": "Big Boot", "desc": "Squash 25 walkers total"},
                        {"id": "clear_all", "title": "Flag Bearer", "desc": "Clear all three levels in one run"},
                        {"id": "score_100", "title": "Coin Mountain", "desc": "Score 100 in one run"},
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
        {"id": "hen", "title": "Hen Invaders", "tag": "1P shooter port", "coming_soon": true,
                "thumb": "res://assets/thumbs/hen.png",
                "desc": "The sky is full of angry hens. Shoot them down, wave after wave.",
                "genres": {"main": ["shooter", "arcade"], "sub": ["retro", "singleplayer"]},
                "age": "everyone",
                "reveal": {"kind": "inbox", "appear_after": 1, "price": 350, "needs_games": 0,
                        "minutes": 20}},
        {"id": "spud", "title": "Cosmic Spud", "tag": "wave shooter port", "coming_soon": true,
                "thumb": "res://assets/thumbs/spud.png",
                "desc": "One potato against the galaxy. Hold the line, spud.",
                "genres": {"main": ["shooter", "sci-fi"], "sub": ["singleplayer", "survival"]},
                "age": "teens",
                "reveal": {"kind": "real", "appear_after": 1, "price": 350, "needs_games": 0,
                        "hours": 24}},
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
        # v0.1.4 LOCKED WITHOUT BEING A MYSTERY (owner brainstorm): matcher
        # shows up right away as a visible tile, never a black box - pour 100
        # GOGACharges into it (pre-play button + capacity meter) and own 3
        # games, and its spot is fully unlocked.
        {"id": "matcher", "title": "Matcher", "tag": "match-3 port", "coming_soon": true,
                "thumb": "res://assets/thumbs/matcher.png",
                "desc": "Swap, match, cascade. The calm one you play for hours.",
                "genres": {"main": ["puzzle", "casual"], "sub": ["minimal", "singleplayer"]},
                "age": "everyone",
                "charge_unlock": 100,
                "reveal": {"kind": "direct", "appear_after": 0, "price": 400, "needs_games": 3}},
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
