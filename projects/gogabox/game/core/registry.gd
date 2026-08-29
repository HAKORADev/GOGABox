class_name GameReg
extends RefCounted
## The game list. Adding a game = add one entry here + a <id>.gd in
## game/games/ + a thumbnail assets/thumbs/<id>.png. Nothing else.

const GAMES := [
        {
                "id": "snake", "title": "Snake", "tag": "the classic, hungry",
                "script": "res://game/games/snake.gd",
                "thumb": "res://assets/thumbs/snake.png",
                "orientation": "portrait", "dim": "2d",
                "price": 0, "fee": 10, "shop": true,
                "hot": true,
                "ach": [
                        {"id": "score_30", "title": "Snack Time", "desc": "Score 30 in one run"},
                        {"id": "score_60", "title": "Long Boi", "desc": "Score 60 in one run"},
                        {"id": "score_100", "title": "Anaconda", "desc": "Score 100 in one run"},
                        {"id": "coins_100", "title": "Coin Collector", "desc": "Grab 100 GOGACoins total"},
                ],
        },
        {
                "id": "rally", "title": "Pong Rally", "tag": "don't blink",
                "script": "res://game/games/rally.gd",
                "thumb": "res://assets/thumbs/rally.png",
                "orientation": "portrait", "dim": "2d",
                "price": 150, "fee": 8, "shop": false,
                "hot": false,
                "reveal": {"kind": "chain"},   # shows after the previous game was bought AND played
                "ach": [
                        {"id": "rally_15", "title": "Warm-Up", "desc": "Rally 15 returns"},
                        {"id": "rally_30", "title": "Wall of Paddle", "desc": "Rally 30 returns"},
                        {"id": "score_50", "title": "Table Legend", "desc": "Score 50 in one run"},
                ],
        },
        {
                "id": "lanes", "title": "Geometry Flash", "tag": "dodge the grid",
                "script": "res://game/games/lanes.gd",
                "thumb": "res://assets/thumbs/lanes.png",
                "orientation": "portrait", "dim": "2d",
                "price": 200, "fee": 10, "shop": false,
                "hot": true,
                "reveal": {"kind": "chain"},
                "ach": [
                        {"id": "score_500", "title": "Lane Rookie", "desc": "Score 500"},
                        {"id": "score_1500", "title": "Grid Ghost", "desc": "Score 1500"},
                        {"id": "dodge_200", "title": "Untouchable", "desc": "Dodge 200 blocks total"},
                ],
        },
        {
                "id": "slasher", "title": "Fruit Slasher", "tag": "swipe everything",
                "script": "res://game/games/slasher.gd",
                "thumb": "res://assets/thumbs/slasher.png",
                "orientation": "landscape", "dim": "2d",
                "price": 250, "fee": 15, "shop": false,
                "hot": true,
                "reveal": {"kind": "chain"},
                "ach": [
                        {"id": "combo_5", "title": "Fruit Ninja Moves", "desc": "Slash 5 fruits in one swipe"},
                        {"id": "score_300", "title": "Sharp Blade", "desc": "Score 300 in one run"},
                        {"id": "slash_100", "title": "Juice Bar", "desc": "Slash 100 fruits total"},
                ],
        },
        {
                "id": "hopper", "title": "Snowy Tower", "tag": "climb till you slip",
                "script": "res://game/games/hopper.gd",
                "thumb": "res://assets/thumbs/hopper.png",
                "orientation": "portrait", "dim": "2d",
                "price": 300, "fee": 12, "shop": false,
                "hot": false,
                "reveal": {"kind": "chain"},
                "ach": [
                        {"id": "height_500", "title": "Frosty Start", "desc": "Climb 500"},
                        {"id": "height_1500", "title": "Cloud Toucher", "desc": "Climb 1500"},
                        {"id": "hops_50", "title": "Bunny Boots", "desc": "Jump 50 times total"},
                ],
        },
        {
                "id": "merge", "title": "2048", "tag": "swipe and double",
                "script": "res://game/games/merge2048.gd",
                "thumb": "res://assets/thumbs/merge.png",
                "orientation": "portrait", "dim": "2d",
                "price": 400, "fee": 15, "shop": false,
                "hot": false,
                "reveal": {"kind": "chain"},
                "ach": [
                        {"id": "tile_256", "title": "Getting Warm", "desc": "Create the 256 tile"},
                        {"id": "tile_512", "title": "Halfway Hero", "desc": "Create the 512 tile"},
                        {"id": "tile_2048", "title": "The Real 2048", "desc": "Create the 2048 tile"},
                ],
        },

        # ---- the workshop (not built yet, but ALREADY in the feed as
        # mystery/locked teasers so the box keeps growing. Reveal kinds:
        #   orders  - complete quest lines to reveal
        #   inbox   - reveal after N minutes of total in-box play time
        #   real    - reveal after N real-world hours (local notification)
        # appear_after = owned games needed before the teaser even shows.
        # needs_games = owned games required to BUY once revealed.
        {"id": "dario", "title": "Dario", "tag": "platformer port", "coming_soon": true,
                "thumb": "res://assets/thumbs/dario.png",
                "reveal": {"kind": "orders", "appear_after": 1, "price": 350, "needs_games": 0,
                        "orders": [
                                {"type": "spend_in", "game": "snake", "amount": 120},
                                {"type": "plays", "game": "snake", "count": 3},
                        ]}},
        {"id": "hen", "title": "Hen Invaders", "tag": "1P shooter port", "coming_soon": true,
                "thumb": "res://assets/thumbs/hen.png",
                "reveal": {"kind": "inbox", "appear_after": 1, "price": 350, "needs_games": 0,
                        "minutes": 20}},
        {"id": "spud", "title": "Cosmic Spud", "tag": "wave shooter port", "coming_soon": true,
                "thumb": "res://assets/thumbs/spud.png",
                "reveal": {"kind": "real", "appear_after": 1, "price": 350, "needs_games": 0,
                        "hours": 24}},
        {"id": "maze", "title": "Escape The Maze", "tag": "procedural maze port", "coming_soon": true,
                "thumb": "res://assets/thumbs/maze.png",
                "reveal": {"kind": "orders", "appear_after": 2, "price": 400, "needs_games": 2,
                        "orders": [
                                {"type": "beat_best", "game": "rally"},
                                {"type": "earn_in", "game": "lanes", "amount": 150},
                        ]}},
        {"id": "matcher", "title": "Matcher", "tag": "match-3 port", "coming_soon": true,
                "thumb": "res://assets/thumbs/matcher.png",
                "reveal": {"kind": "inbox", "appear_after": 2, "price": 400, "needs_games": 0,
                        "minutes": 45}},
        {"id": "xo", "title": "XO Ladder", "tag": "AI streaks port", "coming_soon": true,
                "thumb": "res://assets/thumbs/xo.png",
                "reveal": {"kind": "orders", "appear_after": 3, "price": 450, "needs_games": 3,
                        "orders": [
                                {"type": "plays", "game": "hopper", "count": 5},
                                {"type": "beat_best", "game": "slasher"},
                        ]}},
        {"id": "keys", "title": "Key Singer", "tag": "rhythm rework", "coming_soon": true,
                "thumb": "res://assets/thumbs/keys.png",
                "reveal": {"kind": "real", "appear_after": 3, "price": 450, "needs_games": 0,
                        "hours": 72}},
        {"id": "poptd", "title": "Pop TD", "tag": "tower defense port", "coming_soon": true,
                "thumb": "res://assets/thumbs/poptd.png",
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
