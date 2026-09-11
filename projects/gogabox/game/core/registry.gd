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
                "ach": [
    {"id": "score_t1", "title": "Snack Time", "desc": "Score 30 in one run", "tier": 1, "rule": {"k": "score", "v": 30}},
    {"id": "score_t2", "title": "Long Boi", "desc": "Score 100 in one run", "tier": 2, "rule": {"k": "score", "v": 100}},
    {"id": "score_t3", "title": "Anaconda", "desc": "Score 300 in one run", "tier": 3, "rule": {"k": "score", "v": 300}},
    {"id": "score_t4", "title": "The Floor Is Gone", "desc": "Score 600 in one run", "tier": 4, "rule": {"k": "score", "v": 600}},
    {"id": "apples_t1", "title": "Fruit Hoarder", "desc": "Eat 50 fruits total", "tier": 1, "rule": {"k": "cnt", "key": "apples", "v": 50}},
    {"id": "apples_t2", "title": "Orchard Wiper", "desc": "Eat 500 fruits total", "tier": 2, "rule": {"k": "cnt", "key": "apples", "v": 500}},
    {"id": "apples_t3", "title": "The Garden's End", "desc": "Eat 5000 fruits total", "tier": 3, "rule": {"k": "cnt", "key": "apples", "v": 5000}},
    {"id": "coins_t1", "title": "Coin Collector", "desc": "Grab 100 GOGACoins total", "tier": 1, "rule": {"k": "cnt", "key": "coins_taken", "v": 100}},
    {"id": "coins_t2", "title": "Coin Dragon", "desc": "Grab 1000 GOGACoins total", "tier": 2, "rule": {"k": "cnt", "key": "coins_taken", "v": 1000}},
    {"id": "coins_t3", "title": "The Golden Coil", "desc": "Grab 5000 GOGACoins total", "tier": 3, "rule": {"k": "cnt", "key": "coins_taken", "v": 5000}},
    {"id": "len_t1", "title": "Half a Hundred", "desc": "Reach a body of 60", "tier": 1, "rule": {"k": "max", "key": "length", "v": 60}},
    {"id": "len_t2", "title": "River Snake", "desc": "Reach a body of 140", "tier": 2, "rule": {"k": "max", "key": "length", "v": 140}},
    {"id": "len_t3", "title": "The World Coil", "desc": "Reach a body of 260", "tier": 3, "rule": {"k": "max", "key": "length", "v": 260}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 10 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 10}},
    {"id": "plays_t2", "title": "The Resident", "desc": "Play 100 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 100}},
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
                "ach": [
    {"id": "rally_t1", "title": "Warm-Up", "desc": "Return the ball 15 times in one run", "tier": 1, "rule": {"k": "max", "key": "max_rally", "v": 15}},
    {"id": "rally_t2", "title": "Wall of Paddle", "desc": "Return the ball 40 times in one run", "tier": 2, "rule": {"k": "max", "key": "max_rally", "v": 40}},
    {"id": "rally_t3", "title": "Table Legend", "desc": "Return the ball 100 times in one run", "tier": 3, "rule": {"k": "max", "key": "max_rally", "v": 100}},
    {"id": "rally_t4", "title": "The Forever Rally", "desc": "Return the ball 200 times in one run", "tier": 4, "rule": {"k": "max", "key": "max_rally", "v": 200}},
    {"id": "score_t1", "title": "First Blood", "desc": "Score 50 in one run", "tier": 1, "rule": {"k": "score", "v": 50}},
    {"id": "score_t2", "title": "Smash Artist", "desc": "Score 150 in one run", "tier": 2, "rule": {"k": "score", "v": 150}},
    {"id": "score_t3", "title": "Court Legend", "desc": "Score 400 in one run", "tier": 3, "rule": {"k": "score", "v": 400}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 10 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 10}},
    {"id": "plays_t2", "title": "The Regular's Regular", "desc": "Play 50 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 50}},
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
                # v0.3.8-7 (owner: "score bonus /500"): coin_div 50 -> 500 -
                # the run-end bonus is a long-game reward now, riding the
                # 200-kill coin cadence.
                "id": "lanes", "title": "Space Dash", "tag": "kill the sky",
                "script": "res://game/games/lanes/lanes.gd",
                "thumb": "res://assets/thumbs/lanes.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 500, "price": 200, "fee": 20, "shop": true,
                "reveal": {"kind": "orders", "appear_after": 0,
        "orders": [{"type": "plays", "game": "rally", "count": 3},
                {"type": "beat_best", "game": "rally"}],
        "needs_games": 2},
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
                "ach": [
    {"id": "score_t1", "title": "Blooded Wings", "desc": "Score 500 in one run", "tier": 1, "rule": {"k": "score", "v": 500}},
    {"id": "score_t2", "title": "Sky Reaper", "desc": "Score 1500 in one run", "tier": 2, "rule": {"k": "score", "v": 1500}},
    {"id": "score_t3", "title": "Storm Born", "desc": "Score 4000 in one run", "tier": 3, "rule": {"k": "score", "v": 4000}},
    {"id": "score_t4", "title": "The Sky Is Mine", "desc": "Score 10000 in one run", "tier": 4, "rule": {"k": "score", "v": 10000}},
    {"id": "kills_t1", "title": "Century Hawk", "desc": "Kill 60 ships in one run", "tier": 1, "rule": {"k": "max", "key": "best_kills", "v": 60}},
    {"id": "kills_t2", "title": "Ace of Aces", "desc": "Kill 150 ships in one run", "tier": 2, "rule": {"k": "max", "key": "best_kills", "v": 150}},
    {"id": "kills_t3", "title": "Death of the Sky", "desc": "Kill 300 ships in one run", "tier": 3, "rule": {"k": "max", "key": "best_kills", "v": 300}},
    {"id": "kills_tot", "title": "War Economy", "desc": "Kill 3000 ships total", "tier": 2, "rule": {"k": "cnt", "key": "kills", "v": 3000}},
    {"id": "power_t1", "title": "Fully Armed", "desc": "Max a weapon's power (20)", "tier": 3, "rule": {"k": "max", "key": "max_power", "v": 20}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 10 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 10}},
    {"id": "plays_t2", "title": "Sky Veteran", "desc": "Play 50 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 50}},
],
        },
        {
                # v0.2.9 THE REWORK (the owner: "currently it's too bad"):
                # the position ask (each position = different physics), the
                # real slicing (the fruit splits along YOUR cut), the hearts,
                # the +N/-N reader, the vegetable shop, /15.
                # v0.3.8-7 (owner: "make score bonus be /30 instead of /15"):
                # coin_div 15 -> 30.
                "id": "slasher", "title": "Fruit Slasher", "tag": "swipe everything",
                "script": "res://game/games/slasher/slasher.gd",
                "thumb": "res://assets/thumbs/slasher.png",
                "orientation": "auto", "dim": "2d",
                "coin_div": 30, "price": 250, "fee": 15, "shop": true,
                "reveal": {"kind": "orders", "appear_after": 1,
        "orders": [{"type": "spend_in", "game": "lanes", "amount": 120},
                {"type": "plays", "game": "rally", "count": 5}],
        "needs_games": 3},
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
                "ach": [
    {"id": "score_t1", "title": "Sharp Blade", "desc": "Score 300 in one run", "tier": 1, "rule": {"k": "max", "key": "max_score", "v": 300}},
    {"id": "score_t2", "title": "Juice Storm", "desc": "Score 800 in one run", "tier": 2, "rule": {"k": "max", "key": "max_score", "v": 800}},
    {"id": "score_t3", "title": "The Blade Saint", "desc": "Score 2000 in one run", "tier": 3, "rule": {"k": "max", "key": "max_score", "v": 2000}},
    {"id": "slash_t1", "title": "Juice Bar", "desc": "Slash 100 fruits total", "tier": 1, "rule": {"k": "cnt", "key": "slashed", "v": 100}},
    {"id": "slash_t2", "title": "Fruit Hurricane", "desc": "Slash 1000 fruits total", "tier": 2, "rule": {"k": "cnt", "key": "slashed", "v": 1000}},
    {"id": "slash_t3", "title": "The Orchard Falls", "desc": "Slash 5000 fruits total", "tier": 3, "rule": {"k": "cnt", "key": "slashed", "v": 5000}},
    {"id": "hearts_t1", "title": "Untouchable", "desc": "End a run with all three hearts", "tier": 2, "rule": {"k": "max", "key": "hearts_kept", "v": 3}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 10 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 10}},
    {"id": "plays_t2", "title": "Blade Regular", "desc": "Play 60 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 60}},
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
                "ach": [
    {"id": "tower_t1", "title": "Warming Up", "desc": "Climb 30 platforms in one run", "tier": 1, "rule": {"k": "max", "key": "max_tower", "v": 30}},
    {"id": "tower_t2", "title": "Above the Clouds", "desc": "Climb 80 platforms in one run", "tier": 2, "rule": {"k": "max", "key": "max_tower", "v": 80}},
    {"id": "tower_t3", "title": "The Stratosphere", "desc": "Climb 150 platforms in one run", "tier": 3, "rule": {"k": "max", "key": "max_tower", "v": 150}},
    {"id": "tower_t4", "title": "The Edge of the Sky", "desc": "Climb 300 platforms in one run", "tier": 4, "rule": {"k": "max", "key": "max_tower", "v": 300}},
    {"id": "hops_t1", "title": "Bunny Boots", "desc": "Jump 50 times total", "tier": 1, "rule": {"k": "cnt", "key": "hops", "v": 50}},
    {"id": "hops_t2", "title": "Spring Legs", "desc": "Jump 500 times total", "tier": 2, "rule": {"k": "cnt", "key": "hops", "v": 500}},
    {"id": "hops_t3", "title": "The Thousand Knees", "desc": "Jump 5000 times total", "tier": 3, "rule": {"k": "cnt", "key": "hops", "v": 5000}},
    {"id": "height_t1", "title": "Where Birds Rest", "desc": "Climb 500 height in one run", "tier": 1, "rule": {"k": "max", "key": "max_height", "v": 500}},
    {"id": "height_t2", "title": "Thin Air", "desc": "Climb 1500 height in one run", "tier": 2, "rule": {"k": "max", "key": "max_height", "v": 1500}},
    {"id": "height_t3", "title": "The Quiet Zone", "desc": "Climb 3000 height in one run", "tier": 3, "rule": {"k": "max", "key": "max_height", "v": 3000}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 10 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 10}},
    {"id": "plays_t2", "title": "The Mountain's Own", "desc": "Play 60 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 60}},
],
        },
        {
                # v0.3.8-7 (owner: "the original ... score be /100"):
                # coin_div 20 -> 100 for the 4x4; the 6x6/8x8 wear their own
                # x4/x12 overrides in the game's SIZES table (/400, /1200).
                "id": "merge", "title": "2048", "tag": "swipe and double",
                "script": "res://game/games/merge/merge2048.gd",
                "thumb": "res://assets/thumbs/merge.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 100, "price": 400, "fee": 15, "shop": true,
                "banner": true,   # turn-based: banner is safe here
                "reveal": {"kind": "orders", "appear_after": 2,
        "orders": [{"type": "earn_in", "game": "hopper", "amount": 120},
                {"type": "spend_in", "game": "slasher", "amount": 150}],
        "needs_games": 5},
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
                "ach": [
    {"id": "tile_t1", "title": "Getting Warm", "desc": "Create the 256 tile", "tier": 1, "rule": {"k": "max", "key": "max_tile", "v": 256}},
    {"id": "tile_t2", "title": "Halfway Hero", "desc": "Create the 512 tile", "tier": 2, "rule": {"k": "max", "key": "max_tile", "v": 512}},
    {"id": "tile_t3", "title": "The Cold One", "desc": "Create the 1024 tile", "tier": 3, "rule": {"k": "max", "key": "max_tile", "v": 1024}},
    {"id": "tile_t4", "title": "The Real 2048", "desc": "Create the 2048 tile", "tier": 4, "rule": {"k": "max", "key": "max_tile", "v": 2048}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 10 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 10}},
    {"id": "plays_t2", "title": "Doubler", "desc": "Play 40 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 40}},
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
                "reveal": {"kind": "orders", "appear_after": 3,
        "orders": [{"type": "plays", "game": "merge", "count": 4},
                {"type": "ach_in", "game": "merge", "count": 2}],
        "needs_games": 6},
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
                "ach": [
    {"id": "stomp_t1", "title": "Heel of the Hero", "desc": "Stomp 25 enemies total", "tier": 1, "rule": {"k": "cnt", "key": "stomped", "v": 25}},
    {"id": "stomp_t2", "title": "Boot Camp", "desc": "Stomp 100 enemies total", "tier": 2, "rule": {"k": "cnt", "key": "stomped", "v": 100}},
    {"id": "stomp_t3", "title": "The Stomp Dynasty", "desc": "Stomp 400 enemies total", "tier": 3, "rule": {"k": "cnt", "key": "stomped", "v": 400}},
    {"id": "witcher_t1", "title": "Witcher Slayer", "desc": "Crush the Witcher", "tier": 2, "rule": {"k": "max", "key": "witcher", "v": 1}},
    {"id": "clear_t1", "title": "The Escape That Wasn't", "desc": "Clear all ten levels in one run", "tier": 3, "rule": {"k": "max", "key": "levels_done", "v": 10}},
    {"id": "score_t1", "title": "Curse Runner", "desc": "Score 2000 in one run", "tier": 2, "rule": {"k": "max", "key": "max_score", "v": 2000}},
    {"id": "score_t2", "title": "The Curse Breaker", "desc": "Score 6000 in one run", "tier": 3, "rule": {"k": "max", "key": "max_score", "v": 6000}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 10 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 10}},
    {"id": "plays_t2", "title": "Cursed Regular", "desc": "Play 30 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 30}},
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
                "reveal": {"kind": "inbox", "minutes": 45,
        "appear_after": 4, "needs_games": 7},
                "desc": "Sketchbook tic-tac-toe: paper, ink and one adaptive opponent. It wears four profiles (The Wall, The Trickster, The Rusher, The Sage), remembers your last two rounds and stops falling for your patterns. Every win pays +1, every loss costs -1, a GOGACoin lands on the board after every 3 rounds - mark its cell first to take it.",
                "controls": [
                        "tap a cell to draw your X - the red pencil",
                        "win = +1 score, loss = -1, draw = 0 (run bonus /2)",
                        "the CPU is hard to beat but never perfect - it adapts to your patterns for 2 rounds, then forgets",
                        "after every 3 rounds a GOGACoin grows in an empty cell - mark that cell FIRST and it is yours (the CPU can take it too)",
                        "the bank is in the pause sheet: END ends the run and pays",
                ],
                "genres": {"main": ["strategy", "puzzle"], "sub": ["turnbased", "competitive", "singleplayer"]},
                "ach": [
    {"id": "wins_t1", "title": "Pencil Pusher", "desc": "Win 10 rounds", "tier": 1, "rule": {"k": "cnt", "key": "wins", "v": 10}},
    {"id": "wins_t2", "title": "Sketch Master", "desc": "Win 40 rounds", "tier": 2, "rule": {"k": "cnt", "key": "wins", "v": 40}},
    {"id": "wins_t3", "title": "The Graphite Hand", "desc": "Win 120 rounds", "tier": 3, "rule": {"k": "cnt", "key": "wins", "v": 120}},
    {"id": "streak_t1", "title": "Unstoppable", "desc": "Win 5 rounds in a row", "tier": 2, "rule": {"k": "max", "key": "streak", "v": 5}},
    {"id": "streak_t2", "title": "The Machine", "desc": "Win 10 rounds in a row", "tier": 3, "rule": {"k": "max", "key": "streak", "v": 10}},
    {"id": "plays_t1", "title": "Doodler", "desc": "Play 15 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 15}},
    {"id": "plays_t2", "title": "The Page's Owner", "desc": "Play 60 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 60}},
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
                "charge_unlock": 150,
                "reveal": {"kind": "orders", "appear_after": 6,
        "orders": [{"type": "plays", "game": "invaders", "count": 5},
                {"type": "spend_charges", "amount": 60}],
        "needs_games": 9},
                "desc": "The happy one - an endless gem wall with EIGHT moods: CHALLENGE (rounds derived from a real pre-solve of the grid, lives and wins/losses on the HUD), PEACE (zen, nothing can hurt you), BUTTERFLIES (they rise AFTER your move - one grace at the top, then the spider dines), ICE STORM (frosted blocks rise behind the gems), DIAMOND MINE (pure dirt, clay and rock layers, dig deep), JELLY (the sweet virus - eat it before it spreads), ICE CRASH (layered ice 1-5 plus the rock only specials crack) and DROP DOWN (the parcels pour in on their own stream - out-deliver the quota before moves, time or both eat you). THE SPECIALS: an L or T makes the BOMB, a vertical 4 makes the ROW SWEEPER, a horizontal 4 makes the COLUMN SWEEPER and 5 in a line makes the COLOR REMOVER - swap it with anything and its color wipes out bottom-to-up, and special + special fires the COMBOS (double sweeps, the plus, the 4x4, triple sweeps, the color armies). Powers buy with the GLOBAL GOGACoins; escort the GOGACoin to the bottom row and it is yours.",
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
                        "DROP DOWN: the parcels pour in on their own hatch clock and ride the gravity waves - deliver the round's quota before the moves, the clock or both run out (each round rolls the limit fresh; a stuck parcel climbs and parks on the top line, and the next parcel with every top seat parked ends the run)",
                ],
                "genres": {"main": ["puzzle", "casual"], "sub": ["match3", "singleplayer", "relax"]},
                "ach": [
    {"id": "match_t1", "title": "Gem Fresh", "desc": "Match 300 gems total", "tier": 1, "rule": {"k": "cnt", "key": "matched", "v": 300}},
    {"id": "match_t2", "title": "Gem Hoard", "desc": "Match 3000 gems total", "tier": 2, "rule": {"k": "cnt", "key": "matched", "v": 3000}},
    {"id": "match_t3", "title": "The Gem Sea", "desc": "Match 15000 gems total", "tier": 3, "rule": {"k": "cnt", "key": "matched", "v": 15000}},
    {"id": "cascade_t1", "title": "Sweet Tooth", "desc": "Chain a x4 cascade", "tier": 2, "rule": {"k": "max", "key": "best_cascade", "v": 4}},
    {"id": "cascade_t2", "title": "The Long Chain", "desc": "Chain a x6 cascade", "tier": 3, "rule": {"k": "max", "key": "best_cascade", "v": 6}},
    {"id": "cascade_t3", "title": "Gravity's Friend", "desc": "Chain a x8 cascade", "tier": 4, "rule": {"k": "max", "key": "best_cascade", "v": 8}},
    {"id": "hyper_t1", "title": "Light Touch", "desc": "Create a color remover", "tier": 1, "rule": {"k": "cnt", "key": "hypers", "v": 1}},
    {"id": "hyper_t2", "title": "Remover's Hand", "desc": "Create 10 color removers", "tier": 2, "rule": {"k": "cnt", "key": "hypers", "v": 10}},
    {"id": "depth_t1", "title": "Deep Dig", "desc": "Descend to 20m in one mine", "tier": 1, "rule": {"k": "max", "key": "depth", "v": 20}},
    {"id": "depth_t2", "title": "The Bottom", "desc": "Descend to 50m in one mine", "tier": 3, "rule": {"k": "max", "key": "depth", "v": 50}},
    {"id": "butter_t1", "title": "Moth Keeper", "desc": "Save 100 butterflies total", "tier": 1, "rule": {"k": "cnt", "key": "butterflies", "v": 100}},
    {"id": "butter_t2", "title": "The Butterfly Friend", "desc": "Save 500 butterflies total", "tier": 2, "rule": {"k": "cnt", "key": "butterflies", "v": 500}},
    {"id": "ice_t1", "title": "Ice Breaker", "desc": "Melt 25 ice layers total", "tier": 1, "rule": {"k": "cnt", "key": "melted", "v": 25}},
    {"id": "ice_t2", "title": "The Thaw", "desc": "Melt 250 ice layers total", "tier": 2, "rule": {"k": "cnt", "key": "melted", "v": 250}},
    {"id": "icecrash_t1", "title": "Shattermind", "desc": "Crack 300 ice-crash layers total", "tier": 2, "rule": {"k": "cnt", "key": "icr_layers", "v": 300}},
    {"id": "jelly_t1", "title": "Jelly Wipe", "desc": "Dissolve 500 jelly cells total", "tier": 2, "rule": {"k": "cnt", "key": "jelly_cells", "v": 500}},
    {"id": "items_t1", "title": "Parcel Master", "desc": "Deliver 100 parcels total", "tier": 2, "rule": {"k": "cnt", "key": "items", "v": 100}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 10 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 10}},
    {"id": "plays_t2", "title": "Wall Regular", "desc": "Play 50 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 50}},
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
                "reveal": {"kind": "orders", "appear_after": 5,
        "orders": [{"type": "spend_in", "game": "dario", "amount": 200},
                {"type": "plays", "game": "xo", "count": 6}],
        "needs_games": 8},
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
                "ach": [
    {"id": "score_t1", "title": "Solar Shield", "desc": "Score 2000 in one run", "tier": 1, "rule": {"k": "max", "key": "max_score", "v": 2000}},
    {"id": "score_t2", "title": "Star Breaker", "desc": "Score 6000 in one run", "tier": 2, "rule": {"k": "max", "key": "max_score", "v": 6000}},
    {"id": "score_t3", "title": "The System's Fist", "desc": "Score 15000 in one run", "tier": 3, "rule": {"k": "max", "key": "max_score", "v": 15000}},
    {"id": "kills_t1", "title": "Star Sweep", "desc": "Destroy 500 enemies total", "tier": 1, "rule": {"k": "cnt", "key": "kills", "v": 500}},
    {"id": "kills_t2", "title": "Void Cleaner", "desc": "Destroy 2000 enemies total", "tier": 2, "rule": {"k": "cnt", "key": "kills", "v": 2000}},
    {"id": "kills_t3", "title": "The Long War's Toll", "desc": "Destroy 6000 enemies total", "tier": 3, "rule": {"k": "cnt", "key": "kills", "v": 6000}},
    {"id": "tour_t1", "title": "The Long War", "desc": "Finish the full tour", "tier": 3, "rule": {"k": "cnt", "key": "tour_done", "v": 1}},
    {"id": "boss_t1", "title": "Duke Hunter", "desc": "Meet all three runaway keepers", "tier": 2, "rule": {"k": "cnt", "key": "bosses_met", "v": 3}},
    {"id": "defend_t1", "title": "Crew Trust", "desc": "Call 3 defenders total", "tier": 1, "rule": {"k": "cnt", "key": "defenders_called", "v": 3}},
    {"id": "stage_t1", "title": "Deep Patrol", "desc": "Reach stage 12", "tier": 2, "rule": {"k": "max", "key": "max_stage", "v": 12}},
    {"id": "stage_t2", "title": "The Far Orbit", "desc": "Reach stage 24", "tier": 3, "rule": {"k": "max", "key": "max_stage", "v": 24}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 8 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 8}},
    {"id": "plays_t2", "title": "Watch Commander", "desc": "Play 40 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 40}},
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
                "charge_unlock": 400,
                "reveal": {"kind": "direct", "appear_after": 10,
        "needs_games": 13},
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
                "ach": [
    {"id": "kills_t1", "title": "Swatter", "desc": "Defeat 500 enemies total", "tier": 1, "rule": {"k": "max", "key": "kills", "v": 500}},
    {"id": "kills_t2", "title": "Swarm Thinner", "desc": "Defeat 2000 enemies total", "tier": 2, "rule": {"k": "max", "key": "kills", "v": 2000}},
    {"id": "kills_t3", "title": "The Swarm's End", "desc": "Defeat 6000 enemies total", "tier": 3, "rule": {"k": "max", "key": "kills", "v": 6000}},
    {"id": "wave_t1", "title": "Wave Rider", "desc": "Reach wave 20 in one run", "tier": 1, "rule": {"k": "max", "key": "cs_wave", "v": 20}},
    {"id": "wave_t2", "title": "The Storm Surfer", "desc": "Reach wave 40 in one run", "tier": 3, "rule": {"k": "max", "key": "cs_wave", "v": 40}},
    {"id": "score_t1", "title": "Spud Legend", "desc": "Score 400 in one run", "tier": 1, "rule": {"k": "max", "key": "cs_score", "v": 400}},
    {"id": "score_t2", "title": "Spud Immortal", "desc": "Score 1000 in one run", "tier": 2, "rule": {"k": "max", "key": "cs_score", "v": 1000}},
    {"id": "score_t3", "title": "The Golden Harvest", "desc": "Score 2500 in one run", "tier": 3, "rule": {"k": "max", "key": "cs_score", "v": 2500}},
    {"id": "merge_t1", "title": "Weapon Smith", "desc": "Perform 5 weapon merges total", "tier": 1, "rule": {"k": "cnt", "key": "cs_merge", "v": 5}},
    {"id": "merge_t2", "title": "The Forge Master", "desc": "Perform 20 weapon merges total", "tier": 2, "rule": {"k": "cnt", "key": "cs_merge", "v": 20}},
    {"id": "runs_t1", "title": "Drop In", "desc": "Finish 10 runs", "tier": 1, "rule": {"k": "cnt", "key": "cs_runs", "v": 10}},
    {"id": "runs_t2", "title": "The Veteran Spud", "desc": "Finish 50 runs", "tier": 2, "rule": {"k": "cnt", "key": "cs_runs", "v": 50}},
],
        },


        # (matcher graduated into a REAL game above - its v0.1.4 direct tile
        # + 100-charge meter ride along with it)
                # v0.3.5 POP SIEGE - graduated from the old "Pop TD" SOON teaser (the
        # owner's PGB port grew up into the real thing). The bloon siege:
        # 30 maps (day + night bundled), 10 folk x 3 gears x 10 upgrades,
        # the in-range pacts, PopCoins, and a GOGACoin hiding in a bloon
        # every 10 waves. The owner's graduation ritual honored (matcher
        # style): direct reveal, 100 charges, 3 games, 400 coins.
        {
                "id": "pop_siege", "title": "Pop Siege", "tag": "the bloon siege",
                "script": "res://game/games/pop_siege/pop_siege.gd",
                "thumb": "res://assets/thumbs/pop_siege.png",
                "orientation": "landscape", "dim": "2d",
                "coin_div": 1000, "price": 400, "fee": 10, "shop": true,
                "banner": true,   # the field ends above the strip
                "charge_unlock": 250,
                "reveal": {"kind": "direct", "appear_after": 7,
        "needs_games": 10},
                "desc": "The bloons march the winding roads and the gadgets hold the line. 30 handcrafted maps (each with its own day and night), 10 gadgets with 3 gears and 10 upgrades each, pacts between neighbors, fire traps, eternal flames, THE FLUX that teleports bloons back, and every 10 waves a GOGACoin hides inside a bloon. Every hit is a point; the run bonus is score /1000.",
                "controls": [
                        "tap START, then pick a folk card by tap or DRAG it onto green grass (red cells are road, water or blocked) - press the card, pull, release: the ghost rides the finger",
                        "the range ring shows while placing and while a gadget is selected - every ring is finite and honest",
                        "tap a placed gadget to open its panel: every stat row shows its value >> what the next upgrade adds",
                        "10 levels per gear; at 10 the GEAR UP button jumps it to the next gear (new power, new look); broke doors gray out",
                        "gadgets near each other earn PACTS - small badges appear over the buffed gadget",
                        "TARGET cycles FIRST / LAST / STRONG / CLOSE; SELL pays back 70% of everything invested",
                        "the pink SEND WAVE button calls every wave - wave 1 never runs on a timer; calling mid-roll stacks the next wave",
                        "AUTO / MANUAL owns the between-waves clock (wave 1 is always manual); the speed chip cycles x1 x2 x3",
                        "multi-door maps roll the siege: EVERY WAVE ROLLS ITS OWN RANDOM DOORS - the crew grows with the wave (one door, then two, then three) and every 5th wave bursts from ALL of them",
                        "MAPS opens the 30-map wall (every map wears day and night); the SHOP sells folk and maps for GOGACoins; a buy refreshes the SAME window, both close with X",
                        "bloons wear COLOR LEVELS (each ring takes +1 more), hidden STRIPS (each band hides a bloon) and ARMOR: metal fears fire, rock fears bombs",
                        "bloons march single file, one honest row on the road center; nothing shows before the map line",
                ],
                "genres": {"main": ["strategy", "action"], "sub": ["tower-defense", "singleplayer"]},
                "ach": [
    {"id": "pop_t1", "title": "Pop Authority", "desc": "Pop 1000 bloon layers in one run", "tier": 1, "rule": {"k": "max", "key": "pops_run", "v": 1000}},
    {"id": "pop_t2", "title": "The Pop Storm", "desc": "Pop 10000 bloon layers in one run", "tier": 2, "rule": {"k": "max", "key": "pops_run", "v": 10000}},
    {"id": "moab_t1", "title": "The Big One", "desc": "Ground a blimp", "tier": 2, "rule": {"k": "max", "key": "moab_kills", "v": 1}},
    {"id": "moab_t2", "title": "Blimp Season", "desc": "Ground 10 blimps total", "tier": 3, "rule": {"k": "max", "key": "moab_kills", "v": 10}},
    {"id": "wave_t1", "title": "Half the Siege", "desc": "Reach wave 25 on any map", "tier": 1, "rule": {"k": "max", "key": "wave_best", "v": 25}},
    {"id": "wave_t2", "title": "The Siege Breaker", "desc": "Reach wave 50 on any map", "tier": 3, "rule": {"k": "max", "key": "wave_best", "v": 50}},
    {"id": "gear_t1", "title": "Full Gear", "desc": "Push a folk to gear 3", "tier": 2, "rule": {"k": "max", "key": "gears3", "v": 1}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 8 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 8}},
    {"id": "plays_t2", "title": "The Siege Regular", "desc": "Play 40 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 40}},
],
        },


        # (the old "Pop TD" teaser graduated into POP SIEGE above - the PGB
        # port is real now)
        # v0.2.3 patch: the teaser waited in the workshop; v0.3.6 THE
        # GRADUATION: the REAL Geometry Flash ships - the endless neon
        # side-scroller (the PGB v1.3.8 sketch reborn, the GD Lite study
        # recast into original filled-neon art). Its dodge-game namesake
        # grew up and is SPACE DASH (v0.2.4).
        {"id": "geometry", "title": "Geometry Flash", "tag": "the real one",
                "script": "res://game/games/geometry/geometry.gd",
                "thumb": "res://assets/thumbs/geometry.png",
                "orientation": "landscape", "dim": "2d",
                # v0.3.6-3 THE /50 TRUTH (the owner's patch-1 ask, finally
                # landed): score bonus /50 = coin_div 50. The patch-1 round
                # misread it as the in-game speed step - that is back to /10.
                "coin_div": 50, "price": 350, "fee": 10, "shop": true,
                "banner": true,
                "reveal": {"kind": "orders", "appear_after": 8,
        "orders": [{"type": "ach_in", "game": "pop_siege", "count": 2},
                {"type": "spend_in", "game": "matcher", "amount": 200}],
        "needs_games": 11},
                "desc": "The owner's own Geometry Flash: an ENDLESS neon world - no pre-made levels, the generator is the level. One square, one verb (tap = jump) and three hidden verbs it wears: NORMAL hops, FLIP taps gravity to the roof and back, STICK changes gravity only when you TOUCH the other floor - each 10/20/30/40 secret seconds. Golden orbits pay the score, every 10 speeds the world x1.1, and the world is FULL: block staircases up and down, pyramids, twin towers, small triple spikes, saws and floating threats fill the lanes. Blocks shove (they never kill), pits and wrong timing do. Buy POWER-UPS and they spawn in your runs: rocket jumps, a slower world, an extra life. The SFX sing.",
                "controls": ["TAP ANYWHERE TO START - then touch = jump, the square spins its 90 degrees over the real flight",
                        "golden orbits = +1 score each; every 10 the world runs x1.1 faster - watch the x1.00 chip",
                        "the chip next to the score is the LIVE MECHANIC: circle+arrow = jump, split arrows = tap ANYTIME flips gravity to the roof and back, linked arrows = gravity changes only when you TOUCH the ground or the roof (climb the lines to reach the roof!)",
                        "spikes live on the ground, the lines, the roof and FLOAT between the lanes - most are small triple rows you hop, the big triangle is a rare wall",
                        "the world is BUILT: block staircases climb up and down, pyramids, twin towers and bridges fill the lanes - every block top is a real surface (the square lands its 90 and jumps again)",
                        "blocks in the road SHOVE you back (jump over them or ride and escape); pushed off-screen ends the run",
                        "holes open in the ground AND the roof - fall in one and the run ends",
                        "the GOGACoin appears every 30-50s (never at the start) - catch it for real coins",
                        "POWER-UPS you buy spawn in your runs, 10s each: ROCKET JUMP (x1.5 hops + the burn), SLOW WORLD (everything runs 50% slower), EXTRA LIFE (the most expensive - pits bounce you, off-screen re-enters you, spikes pass through)",
                        "the shop wears 5 skins, 3 world themes, TAILS (neon/fire/rainbow/gold/match - they stream BEHIND you) and the powers"],
                "genres": {"main": ["action", "arcade"], "sub": ["rhythm", "singleplayer", "endless"]},
                "ach": [
    {"id": "score_t1", "title": "Flash 100", "desc": "Score 100 in one run", "tier": 1, "rule": {"k": "max", "key": "max_score", "v": 100}},
    {"id": "score_t2", "title": "Speed Demon", "desc": "Score 300 in one run", "tier": 2, "rule": {"k": "max", "key": "max_score", "v": 300}},
    {"id": "score_t3", "title": "Neon Ghost", "desc": "Score 1000 in one run", "tier": 3, "rule": {"k": "max", "key": "max_score", "v": 1000}},
    {"id": "score_t4", "title": "The Matrix Runner", "desc": "Score 2500 in one run", "tier": 4, "rule": {"k": "max", "key": "max_score", "v": 2500}},
    {"id": "orbit_t1", "title": "Orbit Hunter", "desc": "Collect 500 golden orbits total", "tier": 1, "rule": {"k": "cnt", "key": "orbits", "v": 500}},
    {"id": "orbit_t2", "title": "The Orbit Lord", "desc": "Collect 2500 golden orbits total", "tier": 2, "rule": {"k": "cnt", "key": "orbits", "v": 2500}},
    {"id": "flip_t1", "title": "Gravity Adept", "desc": "Flip gravity 250 times total", "tier": 1, "rule": {"k": "cnt", "key": "flips", "v": 250}},
    {"id": "flip_t2", "title": "The World Upside Down", "desc": "Flip gravity 1000 times total", "tier": 2, "rule": {"k": "cnt", "key": "flips", "v": 1000}},
    {"id": "triple_t1", "title": "Triple Threat", "desc": "Survive all 3 mechanics in one run", "tier": 2, "rule": {"k": "cnt", "key": "triple", "v": 1}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 8 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 8}},
    {"id": "plays_t2", "title": "The Loop's Regular", "desc": "Play 40 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 40}},
],
        },
        {"id": "maze", "title": "Maze Escaper", "tag": "the matrix escapee",
                "script": "res://game/games/maze/maze.gd",
                "thumb": "res://assets/thumbs/maze.png",
                "orientation": "landscape", "dim": "2d",
                # v0.3.7 THE OWNED LAW: the score bonus is /3 (the owner's
                # number for the escaper). The old "Escape The Maze" SOON
                # teaser graduated into the real thing (the ritual honored).
                "coin_div": 3, "price": 350, "fee": 10, "shop": true,
                "banner": true,
                "reveal": {"kind": "orders", "appear_after": 9,
        "orders": [{"type": "earn_in", "game": "geometry", "amount": 200},
                {"type": "plays", "game": "pop_siege", "count": 4}],
        "needs_games": 12},
                "desc": "Geoquare's own puzzle: an endless neon maze woven fresh every map - a REAL labyrinth (branching corridors, honest dead ends - never one path with noise). The start and the exit roll EVERY map, so there is nothing to memorize: read the walls, pick the route, swipe grid by grid. The queue animates and SPEEDS UP as your inputs pile up. Time and scale are the only enemies - the clock is tight, the mazes grow, the cell shrinks. A GOGACoin waits one step off the route every 5th map, and the PATH FINDER earns one charge every 2 maps to light the way when the walls win. One map = one point.",
                "controls": ["TAP ANYWHERE TO START - then SWIPE: one swipe moves one cell, keep swiping and the square flows",
                        "reach the glowing portal before the clock runs out - every map solved = +1 score",
                        "the start and the exit move every map - read the maze fresh each time",
                        "a GOGACoin waits just off the route every 5th map - a small detour for real coins",
                        "the PATH FINDER (shop) earns one charge every 2 maps - tap its button next to the score to light the next 8 cells",
                        "the mazes grow as you escape - the cell shrinks to fit until the limit"],
                "genres": {"main": ["puzzle", "arcade"], "sub": ["maze", "singleplayer", "endless"]},
                "ach": [
    {"id": "maps_t1", "title": "Escape Artist", "desc": "Escape 10 mazes in one run", "tier": 1, "rule": {"k": "max", "key": "max_maps", "v": 10}},
    {"id": "maps_t2", "title": "Wall Reader", "desc": "Escape 30 mazes in one run", "tier": 2, "rule": {"k": "max", "key": "max_maps", "v": 30}},
    {"id": "maps_t3", "title": "The Cartographer", "desc": "Escape 60 mazes in one run", "tier": 3, "rule": {"k": "max", "key": "max_maps", "v": 60}},
    {"id": "esc_t1", "title": "Loop Breaker", "desc": "Escape 100 mazes total", "tier": 1, "rule": {"k": "cnt", "key": "escapes", "v": 100}},
    {"id": "esc_t2", "title": "Matrix Free", "desc": "Escape 300 mazes total", "tier": 2, "rule": {"k": "cnt", "key": "escapes", "v": 300}},
    {"id": "esc_t3", "title": "No Walls Hold Me", "desc": "Escape 1000 mazes total", "tier": 3, "rule": {"k": "cnt", "key": "escapes", "v": 1000}},
    {"id": "finder_t1", "title": "Cheater", "desc": "Use the path finder 25 times", "tier": 1, "rule": {"k": "cnt", "key": "finder_used", "v": 25}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 8 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 8}},
    {"id": "plays_t2", "title": "The Maze Walker", "desc": "Play 40 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 40}},
],
        },        {"id": "domino", "title": "DOMINO", "tag": "the tile classic",
                "script": "res://game/games/domino/domino.gd",
                "thumb": "res://assets/thumbs/domino.png",
                # v0.3.8-8 THE TWO TABLES (owner: "giving it position selection
                # menu first and add horizontal support will be cooler"): BOTH
                # positions - the ask picks the table, vertical stays the
                # certified layout, horizontal is the new wide table
                "orientation": "auto", "dim": "2d",
                # v0.3.8 THE GRADUATION: the SOON teaser is the real game
                # (the ritual honored). THE OWNER'S ECONOMY: win +1 / lose
                # -1 / draw 0 (the xo shape), run bonus /2, a GOGACoin
                # after each 3rd round on a legal end spot - whoever puts
                # a domino there takes it, the CPU races you.
                "coin_div": 2, "price": 500, "fee": 10, "shop": true,
                "banner": true,
                "reveal": {"kind": "direct", "appear_after": 7, "price": 500,
                        "needs_games": 8},
                "desc": "the tile classic, played straight: seven tiles each, the highest double opens, match the ends and empty your hand. Draw from the boneyard when the ends starve you; both stuck means the lighter hand wins. Tap a tile then a glowing end, or drag it there - the ends glow only where your tile truly fits. A GOGACoin lands on the table after every 3rd round and the next domino on its spot takes it, yours or the CPU's. Win +1, lose -1, a blocked tie draws.",
                "controls": ["TAP ANYWHERE TO START - the deal flies 7 tiles to you, 7 to the CPU, 14 wait in the boneyard",
                        "choose your position first - the table stands TALL (vertical) or lies WIDE (horizontal)",
                        "the highest double OPENS (no doubles = the heaviest tile) - the glowing tile plays on touch",
                        "tap a tile to lift it, then tap a glowing end - or DRAG it there; ends glow green only where the tile truly fits, no fit = no glow",
                        "a second tap on a selected tile plays it when only ONE end fits; stuck? the BONEYARD SPREADS face-down across the felt - TAP the tile you take (the fan re-fans until something fits), a dry yard means PASS",
                        "both players stuck = BLOCKED - the lighter hand (fewer pips) wins, even pips draw",
                        "a GOGACoin appears after every 3rd round on a play spot - the next domino placed THERE takes it, the CPU included",
                        "the shop wears 5 tile sets and 4 table felts - everything past BONE and TAVERN is bought"],
                "genres": {"main": ["strategy", "casual"], "sub": ["turnbased", "competitive", "singleplayer"]},
                "ach": [
    {"id": "score_t1", "title": "First Chain", "desc": "Score 5 in one run", "tier": 1, "rule": {"k": "max", "key": "max_score", "v": 5}},
    {"id": "score_t2", "title": "Tile Sharp", "desc": "Score 15 in one run", "tier": 2, "rule": {"k": "max", "key": "max_score", "v": 15}},
    {"id": "score_t3", "title": "The Long Table", "desc": "Score 40 in one run", "tier": 3, "rule": {"k": "max", "key": "max_score", "v": 40}},
    {"id": "score_t4", "title": "The Chain Lord", "desc": "Score 100 in one run", "tier": 4, "rule": {"k": "max", "key": "max_score", "v": 100}},
    {"id": "wins_t1", "title": "Domino!", "desc": "Win 10 rounds total", "tier": 1, "rule": {"k": "cnt", "key": "wins", "v": 10}},
    {"id": "wins_t2", "title": "Table Regular", "desc": "Win 50 rounds total", "tier": 2, "rule": {"k": "cnt", "key": "wins", "v": 50}},
    {"id": "wins_t3", "title": "The Bone King", "desc": "Win 200 rounds total", "tier": 3, "rule": {"k": "cnt", "key": "wins", "v": 200}},
    {"id": "coins_t1", "title": "Coin Snatcher", "desc": "Take 25 GOGACoins total", "tier": 1, "rule": {"k": "cnt", "key": "coins_taken", "v": 25}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 8 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 8}},
    {"id": "plays_t2", "title": "The Table's Resident", "desc": "Play 40 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 40}},
],
        },
        {"id": "chess", "title": "CHECKMATE", "tag": "the old war",
                "script": "res://game/games/chess/chess.gd",
                "thumb": "res://assets/thumbs/chess.png",
                # v0.3.8-8 THE VERTICAL WAR (owner: "in chess, things will look
                # better in vertical mode, make sure to tweak the interface
                # properly"): BOTH positions - the ask picks, vertical grows
                # the board to nearly the full width, landscape stays as built
                "orientation": "auto", "dim": "2d",
                # v0.3.8 THE GRADUATION: the SOON teaser is the real game
                # (the ritual honored). THE OWNER'S ECONOMY: win +1 / lose
                # -1 / draw 0, run bonus /1, a GOGACoin each 3 minutes on
                # a reachable square - whoever lands on it takes it.
                "coin_div": 1, "price": 700, "fee": 10, "shop": true,
                "banner": true,
                "reveal": {"kind": "direct", "appear_after": 8, "price": 700,
                        "needs_games": 9},
                "desc": "the old war, played by the book: every piece moves by the law, castling, en passant, promotion, check, checkmate, stalemate, the 50-move rule, repetition and bare kings are all real. The CPU wears SIX hidden personalities - each with its own opening book (the Jobava London lives here) and its own honest mistakes - and it adapts to your openings for two rounds. Highlights show every legal move, the last move and every check. Win +1, lose -1, a draw pays nothing.",
                "controls": ["TAP ANYWHERE TO START - the OPTIONALS shelf opens: pick WHITE or BLACK for the first war (white by default); after that the loser takes WHITE next, a draw swaps colors; a mid-play pick from the OPTIONALS button rides the next opener",
                        "choose your position first - the war stands TALL (vertical) or lies WIDE (horizontal)",
                        "tap a piece to see its legal moves - dots walk there, rings take; tap again to play, or DRAG the piece",
                        "castling moves the king two squares (all the real conditions hold), pawns promote through the picker - underpromotion included",
                        "a checked king glows red; checkmate, stalemate, the 50-move rule, threefold repetition and bare kings all end the round by the book",
                        "a GOGACoin appears every 3 minutes on a reachable square - the next piece to land there takes it, the CPU races you",
                        "the shop wears 4 piece sets and 4 boards - everything past CLASSIC and WALNUT is bought"],
                "genres": {"main": ["strategy", "puzzle"], "sub": ["turnbased", "competitive", "singleplayer"]},
                "ach": [
    {"id": "score_t1", "title": "First Blood", "desc": "Score 3 in one run", "tier": 1, "rule": {"k": "max", "key": "max_score", "v": 3}},
    {"id": "score_t2", "title": "War Chest", "desc": "Score 10 in one run", "tier": 2, "rule": {"k": "max", "key": "max_score", "v": 10}},
    {"id": "score_t3", "title": "Grand Table", "desc": "Score 25 in one run", "tier": 3, "rule": {"k": "max", "key": "max_score", "v": 25}},
    {"id": "score_t4", "title": "The Old War's Master", "desc": "Score 50 in one run", "tier": 4, "rule": {"k": "max", "key": "max_score", "v": 50}},
    {"id": "wins_t1", "title": "Mated", "desc": "Win 10 rounds total", "tier": 1, "rule": {"k": "cnt", "key": "wins", "v": 10}},
    {"id": "wins_t2", "title": "The Quiet Executioner", "desc": "Win 50 rounds total", "tier": 2, "rule": {"k": "cnt", "key": "wins", "v": 50}},
    {"id": "cap_t1", "title": "Collector", "desc": "Capture 100 pieces total", "tier": 1, "rule": {"k": "cnt", "key": "captures", "v": 100}},
    {"id": "cap_t2", "title": "The Battlefield Sweep", "desc": "Capture 500 pieces total", "tier": 2, "rule": {"k": "cnt", "key": "captures", "v": 500}},
    {"id": "coins_t1", "title": "Coin Snatcher", "desc": "Take 25 GOGACoins total", "tier": 1, "rule": {"k": "cnt", "key": "coins_taken", "v": 25}},
    {"id": "plays_t1", "title": "Regular", "desc": "Play 8 rounds", "tier": 1, "rule": {"k": "stat", "key": "plays", "v": 8}},
    {"id": "plays_t2", "title": "The War's Resident", "desc": "Play 40 rounds", "tier": 2, "rule": {"k": "stat", "key": "plays", "v": 40}},
],
        },
        {"id": "fourline", "title": "FOUR IN LINE", "tag": "drop and connect", "coming_soon": true,
            "orientation": "auto", "dim": "2d",
            "price": 450, "fee": 8,
            "reveal": {"kind": "direct", "appear_after": 9, "needs_games": 10},
            "desc": "drop the discs, make four - the workshop version is baking"},
        {"id": "bovo", "title": "FIVE LINES", "tag": "five in a row", "coming_soon": true,
            "orientation": "auto", "dim": "2d",
            "price": 450, "fee": 8,
            "reveal": {"kind": "direct", "appear_after": 10, "needs_games": 11},
            "desc": "five in a row on an endless sketch grid - the workshop version is baking"},
        {"id": "dots", "title": "DOTS", "tag": "close the boxes", "coming_soon": true,
            "orientation": "auto", "dim": "2d",
            "price": 450, "fee": 8,
            "reveal": {"kind": "direct", "appear_after": 11, "needs_games": 12},
            "desc": "draw lines between dots, close boxes, take the board - the workshop version is baking"},

]

static func get_game(id: String) -> Dictionary:
        for g in GAMES:
                if String(g["id"]) == id:
                        return g
        return {}

static func playable() -> Array:
        var out := []
        for g in GAMES:
                if g.get("coming_soon", false):
                        continue
                out.append(g)
        return out

static func workshop() -> Array:
        var out := []
        for g in GAMES:
                if not g.get("coming_soon", false):
                        continue
                out.append(g)
        return out

static func playable_index(id: String) -> int:
        var i := 0
        for g in playable():
                if String(g["id"]) == id:
                        return i
                i += 1
        return -1
