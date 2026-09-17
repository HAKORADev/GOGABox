class_name GameCoin
extends RefCounted
## THE TOP-UP FRAMEWORK (v040-8) - the box's modular in-game-currency law.
##
## A game joins the top-up system by DECLARING itself - no game ids live
## in the menu code (the owner: "update GOGABox infra to has something
## like framework or something so it modular like making something in
## code that makes spotting games that have in-game-currency easier than
## hardcoding each game id").
##
## THE DECLARATION (a registry entry gains two optional fields):
##   "currency": {"name": "SCRAP", "rate": 5.0, "tint": Color}
##       - name    : the currency's display name
##       - rate    : how many of the game's coins ONE GOGACoin is worth
##       - tint    : the currency's chip color in the menus
##   "coin_api": "res://game/games/heavywar/heavywar_meta.gd"
##       - a script carrying the TWO STATIC CALLS the box reads/writes:
##             static func coin_balance() -> int
##             static func coin_add(n: int) -> void
##
## Every wallet write here lands in the SAME store the game reads - a
## top-up is the game's own currency from the moment it settles.

## Every currency-carrying game in registry order: [{id, title, thumb,
## currency{name,rate,tint}, api(script)}]. Games without the declaration
## never appear (THE GAME PICKER LAW).
static func games() -> Array:
        var out: Array = []
        for g in GameReg.GAMES:
                var cur: Dictionary = g.get("currency", {})
                if cur.is_empty():
                        continue
                var api_path := String(g.get("coin_api", ""))
                if api_path == "" or not ResourceLoader.exists(api_path):
                        continue
                out.append({
                        "id": String(g["id"]),
                        "title": String(g["title"]),
                        "thumb": String(g.get("thumb", "")),
                        "name": String(cur.get("name", "COINS")),
                        "rate": float(cur.get("rate", 1.0)),
                        "tint": cur.get("tint", Arc.COIN),
                        "api": load(api_path),
                })
        return out

## is this game a currency carrier?
static func carries(id: String) -> bool:
        for g in games():
                if String(g["id"]) == id:
                        return true
        return false

## the carrier's record (or {})
static func record(id: String) -> Dictionary:
        for g in games():
                if String(g["id"]) == id:
                        return g
        return {}

## the game's live balance (0 when the game is not a carrier)
static func balance(id: String) -> int:
        var r := record(id)
        if r.is_empty() or not r["api"].has_method("coin_balance"):
                return 0
        return int(r["api"].coin_balance())

## add converted coins to the game's wallet (THE SETTLE LAW's game side)
static func add(id: String, n: int) -> void:
        if n <= 0:
                return
        var r := record(id)
        if r.is_empty() or not r["api"].has_method("coin_add"):
                return
        r["api"].coin_add(n)

## the exchange rate (game coins per ONE GOGACoin)
static func rate(id: String) -> float:
        return float(record(id).get("rate", 1.0))

## THE AMOUNT LAW's math: the conversion floors at whole game-coins
## ("no rounding games beyond the rate's own three decimals")
static func convert(n_coins: int, rate_v: float) -> int:
        if n_coins <= 0 or rate_v <= 0.0:
                return 0
        return int(floor(float(n_coins) * rate_v * 1000.0 + 0.5) / 1000.0)
