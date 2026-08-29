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

const GAMES := [
        {
                "id": "snake", "title": "Snake", "tag": "the classic, hungry",
                "script": "res://game/games/snake/snake.gd",
                "thumb": "res://assets/thumbs/snake.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 10, "price": 0, "fee": 10, "shop": true,
                "hot": true, "banner": true,
                "desc": "Steer the snake, eat apples, grab GOGACoins. Every apple makes you longer and faster - walls and your own tail end the run.",
                "controls": ["swipe anywhere to steer", "grab the spinning coin for +5 GOGACoins", "the run ends when you bite yourself or a wall"],
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
                "id": "rally", "title": "Pong Rally", "tag": "don't blink",
                "script": "res://game/games/rally/rally.gd",
                "thumb": "res://assets/thumbs/rally.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 4, "price": 150, "fee": 8, "shop": false,
                "hot": false,
                "reveal": {"kind": "chain"},
                "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},
                "desc": "Endless pong rally against a machine that never gets tired. Every return speeds it up - how long can you keep the ball alive?",
                "controls": ["drag your finger to move the paddle", "every return adds speed", "missing the ball ends the rally"],
                "genres": {"main": ["arcade", "sports"], "sub": ["retro", "competitive", "singleplayer"]},
                "age": "everyone",
                "ach": [
                        {"id": "rally_15", "title": "Warm-Up", "desc": "Rally 15 returns"},
                        {"id": "rally_30", "title": "Wall of Paddle", "desc": "Rally 30 returns"},
                        {"id": "score_50", "title": "Table Legend", "desc": "Score 50 in one run"},
                ],
        },
        {
                "id": "lanes", "title": "Geometry Flash", "tag": "dodge the grid",
                "script": "res://game/games/lanes/lanes.gd",
                "thumb": "res://assets/thumbs/lanes.png",
                "orientation": "portrait", "dim": "2d",
                "coin_div": 100, "price": 200, "fee": 10, "shop": false,
                "hot": true,
                "reveal": {"kind": "chain"},
                "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},
                "blocked_hours": {"from": 1, "to": 8},
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
                "hot": true,
                "reveal": {"kind": "chain"},
                "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},
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
                "hot": false,
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
                "hot": false, "banner": true,   # turn-based: banner is safe here
                "reveal": {"kind": "chain"},
                "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},
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

        # ---- the workshop (not built yet, but ALREADY in the feed as teasers so
        # the box keeps growing. Kinds:
        #   orders - quest lines to reveal          (black box ?????)
        #   inbox  - total box play time to reveal  (black box ?????)
        #   real   - real-world hours to reveal     (black box + local notification)
        #   direct - no conditions beyond appear_after: shows up as a LOCKED/GATED
        #            tile right away (name + thumb visible, never a mystery)
        # appear_after = owned games needed before the teaser even shows.
        # needs_games = owned games required to BUY once revealed.
        {"id": "dario", "title": "Dario", "tag": "platformer port", "coming_soon": true,
                "thumb": "res://assets/thumbs/dario.png",
                "desc": "A proper little platformer - run, jump, stomp.",
                "genres": {"main": ["adventure", "arcade"], "sub": ["platformer", "retro"]},
                "age": "everyone",
                "reveal": {"kind": "orders", "appear_after": 1, "price": 350, "needs_games": 0,
                        "orders": [
                                {"type": "spend_in", "game": "snake", "amount": 120},
                                {"type": "plays", "game": "snake", "count": 3},
                        ]}},
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
                        ]}},
        {"id": "matcher", "title": "Matcher", "tag": "match-3 port", "coming_soon": true,
                "thumb": "res://assets/thumbs/matcher.png",
                "desc": "Swap, match, cascade. The calm one you play for hours.",
                "genres": {"main": ["puzzle", "casual"], "sub": ["minimal", "singleplayer"]},
                "age": "everyone",
                "reveal": {"kind": "direct", "appear_after": 2, "price": 400, "needs_games": 3}},
        {"id": "xo", "title": "XO Ladder", "tag": "AI streaks port", "coming_soon": true,
                "thumb": "res://assets/thumbs/xo.png",
                "desc": "Tic-tac-toe against a climbing AI ladder. It learns. It wins.",
                "genres": {"main": ["strategy", "puzzle"], "sub": ["turnbased", "competitive"]},
                "age": "everyone",
                "reveal": {"kind": "orders", "appear_after": 3, "price": 450, "needs_games": 3,
                        "orders": [
                                {"type": "plays", "game": "hopper", "count": 5},
                                {"type": "beat_best", "game": "slasher"},
                        ]}},
        {"id": "keys", "title": "Key Singer", "tag": "rhythm rework", "coming_soon": true,
                "thumb": "res://assets/thumbs/keys.png",
                "desc": "Hit the keys on the beat. The better your timing, the louder the song.",
                "genres": {"main": ["music", "arcade"], "sub": ["rhythm", "singleplayer"]},
                "age": "everyone",
                "reveal": {"kind": "direct", "appear_after": 3, "price": 450, "needs_games": 4}},
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

static func hot() -> Array:
        var out := []
        for g in playable():
                if g.get("hot", false):
                        out.append(g)
        return out
