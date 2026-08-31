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
##            turn-based/slow games only - never fast action)
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
                "id": "lanes", "title": "Geometry Flash", "tag": "dodge the grid",
                "script": "res://game/games/lanes/lanes.gd",
                "thumb": "res://assets/thumbs/lanes.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 100, "price": 200, "fee": 10, "shop": false,
                "reveal": {"kind": "chain"},
                "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},
                "blocked_hours": {"from": 1, "to": 8},
                # v0.1.4: BOTH daily caps on one game (owner: "some games may
                # have limited rounds and limited time btw")
                "daily_rounds": 6, "daily_minutes": 15,
                "desc": "Three lanes, one ship, a wall of falling blocks. Swap lanes at the last moment - the grid only gets faster.",
                "controls": ["tap left / right side to swap lanes", "survive as long as possible", "the grid speeds up over time"],
                "genres": {"main": ["action", "arcade"], "sub": ["retro", "singleplayer"]},
                "age": "everyone",
                "ach": [
                        {"id": "score_500", "title": "Lane Rookie", "desc": "Score 500"},
                        {"id": "score_1500", "title": "Grid Ghost", "desc": "Score 1500"},
                        {"id": "dodge_200", "title": "Untouchable", "desc": "Dodge 200 blocks total"},
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
                "id": "hopper", "title": "Snowy Tower", "tag": "climb till you slip",
                "script": "res://game/games/hopper/hopper.gd",
                "thumb": "res://assets/thumbs/hopper.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 60, "price": 300, "fee": 12, "shop": false,
                "reveal": {"kind": "chain"},
                "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},
                "hours": {"from": 16, "to": 22},
                "desc": "Hop up an endless snowy tower of icy platforms. The camera never waits - climb fast or freeze at the bottom.",
                "controls": ["tap / hold sides to hop between platforms", "height is score", "fall below the screen and the run ends"],
                "genres": {"main": ["arcade", "adventure"], "sub": ["platformer", "singleplayer"]},
                "age": "everyone",
                "ach": [
                        {"id": "height_500", "title": "Frosty Start", "desc": "Climb 500"},
                        {"id": "height_1500", "title": "Cloud Toucher", "desc": "Climb 1500"},
                        {"id": "hops_50", "title": "Bunny Boots", "desc": "Jump 50 times total"},
                ],
        },
        {
                "id": "merge", "title": "2048", "tag": "swipe and double",
                "script": "res://game/games/merge/merge2048.gd",
                "thumb": "res://assets/thumbs/merge.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 150, "price": 400, "fee": 15, "shop": false,
                "banner": true,   # turn-based: banner is safe here
                "reveal": {"kind": "chain"},
                "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},
                "daily_rounds": 8,   # v0.1.4: 8 rounds a day
                "desc": "Swipe to slide the tiles. Equal numbers merge and double. Reach 2048 before the board fills up - the classic brain cooker.",
                "controls": ["swipe to slide all tiles", "equal tiles merge and double", "the run ends when no move is left"],
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
                "id": "xo", "title": "XO Ladder", "tag": "climb the machine",
                "script": "res://game/games/xo/xo.gd",
                "thumb": "res://assets/thumbs/xo.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 150, "price": 450, "fee": 10, "shop": false,
                "banner": true,   # turn-based: banner is safe here
                "reveal": {"kind": "chain"},
                "desc": "Tic-tac-toe against a climbing AI ladder. Ten rungs from sloppy to perfect - win to climb, lose and you slip. Cash out any time.",
                "controls": ["tap a cell to place your X", "win to climb one rung, lose and you slip one", "rung 10 never loses - how far can you get?", "CASH OUT banks the run and keeps your rung"],
                "genres": {"main": ["strategy", "puzzle"], "sub": ["turnbased", "competitive", "singleplayer"]},
                "age": "everyone",
                "ach": [
                        {"id": "rung_5", "title": "Halfway Up", "desc": "Reach rung 5"},
                        {"id": "rung_top", "title": "Ladder Legend", "desc": "Reach rung 10"},
                        {"id": "streak_3", "title": "On Fire", "desc": "Win 3 in a row"},
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
