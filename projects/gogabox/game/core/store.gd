extends Node
## Box — the one save/wallet/progress/achievement brain for ALL GOGABox games.
## Games NEVER touch this directly; they go through GogaGame helpers.

signal coins_changed(total: int)
signal game_unlocked(id: String)
signal reveal_changed(id: String)   # a game's feed state changed (mystery->locked...)

const SAVE_PATH := "user://gogabox.json"
const START_COINS := 150

var data := {}

func _ready() -> void:
        _load()

# ------------------------------------------------------------- persistence

func _defaults() -> Dictionary:
        return {
                "coins": START_COINS,
                "owned": ["snake"],           # snake is the free starter game
                "settings": {"music": 0.8, "sfx": 0.9},
                "runs_since_interstitial": 0,
                "games": {},                  # per-game: best/last/plays/counters/ach/progress
                "meta": {},                   # box-wide: reveal bookkeeping, last_play, ...
        }

func _load() -> void:
        data = _defaults()
        if not FileAccess.file_exists(SAVE_PATH):
                return
        var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
        if f == null:
                return
        var parsed: Variant = JSON.parse_string(f.get_as_text())
        if parsed is Dictionary:
                _merge(data, parsed)
        if not (data["owned"] is Array):
                data["owned"] = ["snake"]
        if not (data["owned"] as Array).has("snake"):
                (data["owned"] as Array).append("snake")

func _merge(base: Dictionary, over: Dictionary) -> void:
        for k in over:
                if over[k] is Dictionary and base.get(k) is Dictionary:
                        _merge(base[k], over[k])
                else:
                        base[k] = over[k]

func save() -> void:
        var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
        if f:
                f.store_string(JSON.stringify(data))

func reset_all() -> void:
        data = _defaults()
        save()
        coins_changed.emit(coins())

# ------------------------------------------------------- box-wide bookkeeping

func meta() -> Dictionary:
        return data["meta"]

func owned_count() -> int:
        return (data["owned"] as Array).size()

## Total seconds played across ALL games ("in-box time").
func total_time() -> float:
        var t := 0.0
        for id in data["games"]:
                t += float(_slot(String(id)).get("time", 0.0))
        return t

func add_time(id: String, seconds: float) -> void:
        if seconds <= 0.0:
                return
        _slot(id)["time"] = float(_slot(id).get("time", 0.0)) + seconds
        meta()["last_play"] = int(Time.get_unix_time_from_system())
        save()

func spent_in(id: String) -> int:
        return int(_slot(id).get("spent", 0))

func add_spent(id: String, amount: int) -> void:
        if amount <= 0:
                return
        _slot(id)["spent"] = spent_in(id) + amount
        save()

func earned_in(id: String) -> int:
        return int(_slot(id).get("earned", 0))

func add_earned(id: String, amount: int) -> void:
        if amount <= 0:
                return
        _slot(id)["earned"] = earned_in(id) + amount
        save()

## "New!" badge on freshly revealed games - cleared on first tap.
func is_seen(id: String) -> bool:
        return bool(_slot(id).get("seen", false))

func mark_seen(id: String) -> void:
        _slot(id)["seen"] = true
        save()

# ------------------------------------------------------------------ wallet

func coins() -> int:
        return int(data["coins"])

func earn(amount: int) -> void:
        if amount <= 0:
                return
        data["coins"] = int(data["coins"]) + amount
        save()
        coins_changed.emit(coins())

func spend(amount: int) -> bool:
        if coins() < amount:
                return false
        data["coins"] = int(data["coins"]) - amount
        save()
        coins_changed.emit(coins())
        return true

# ------------------------------------------------------------------ unlocks

func owns_game(id: String) -> bool:
        return (data["owned"] as Array).has(id)

func unlock_game(id: String, price: int) -> bool:
        if owns_game(id) or not spend(price):
                return false
        (data["owned"] as Array).append(id)
        save()
        game_unlocked.emit(id)
        return true

## Anti-softlock: the cheapest fee across owned, playable games.
func cheapest_owned_fee() -> int:
        var best := -1
        for g in GameReg.GAMES:
                if g.get("coming_soon", false):
                        continue
                if not owns_game(String(g["id"])):
                        continue
                var fee := int(g["fee"])
                if best < 0 or fee < best:
                        best = fee
        return best

# ------------------------------------------------------------- per-game stats

func _slot(id: String) -> Dictionary:
        if not data["games"].has(id):
                data["games"][id] = {
                        "best": 0, "last": 0, "plays": 0,
                        "time": 0.0, "spent": 0, "earned": 0,
                        "counters": {}, "ach": {}, "progress": {}, "skins": {"owned": [], "on": ""},
                        "seen": false,
                }
        return data["games"][id]

func stat(id: String, key: String) -> int:
        return int(_slot(id).get(key, 0))

func record_run(id: String, score: int) -> Dictionary:
        var s := _slot(id)
        s["last"] = score
        s["plays"] = int(s["plays"]) + 1
        var new_best := score > int(s["best"])
        if new_best:
                s["best"] = score
        save()
        return {"new_best": new_best, "best": int(s["best"])}

## Games report named counters (apples eaten, fruits slashed...).
func bump_counter(id: String, key: String, amount: int) -> void:
        var c: Dictionary = _slot(id)["counters"]
        c[key] = int(c.get(key, 0)) + amount
        save()

func max_counter(id: String, key: String, value: int) -> void:
        var c: Dictionary = _slot(id)["counters"]
        if int(c.get(key, 0)) < value:
                c[key] = value
                save()

func counter(id: String, key: String) -> int:
        return int(_slot(id)["counters"].get(key, 0))

func set_progress(id: String, key: String, value: Variant) -> void:
        _slot(id)["progress"][key] = value
        save()

func get_progress(id: String, key: String, def: Variant = null) -> Variant:
        return _slot(id)["progress"].get(key, def)

func reset_game(id: String) -> void:
        data["games"][id] = {
                "best": 0, "last": 0, "plays": 0,
                "time": 0.0, "spent": 0, "earned": 0,
                "counters": {}, "ach": {}, "progress": {},
                "skins": {"owned": [], "on": ""},
                "seen": true,    # keep the New! badge cleared across a wipe
        }
        save()

# ------------------------------------------------------------- achievements

## Returns true the first time this achievement flips (so callers can toast).
func grant_achievement(id: String, ach_id: String) -> bool:
        var a: Dictionary = _slot(id)["ach"]
        if a.has(ach_id):
                return false
        a[ach_id] = true
        save()
        return true

func has_achievement(id: String, ach_id: String) -> bool:
        return _slot(id)["ach"].has(ach_id)

# ------------------------------------------------------------- skins (per game)

func skin_owned(game_id: String, skin_id: String) -> bool:
        return (_slot(game_id)["skins"]["owned"] as Array).has(skin_id)

func skin_on(game_id: String) -> String:
        return String(_slot(game_id)["skins"]["on"])

func buy_skin(game_id: String, skin_id: String, price: int) -> bool:
        if skin_owned(game_id, skin_id) or not spend(price):
                return false
        (_slot(game_id)["skins"]["owned"] as Array).append(skin_id)
        _slot(game_id)["skins"]["on"] = skin_id
        add_spent(game_id, price)
        save()
        return true

func equip_skin(game_id: String, skin_id: String) -> void:
        if skin_owned(game_id, skin_id):
                _slot(game_id)["skins"]["on"] = skin_id
                save()

# ------------------------------------------------------------- settings / pacing

func music_volume() -> float:
        return float(data["settings"]["music"])

func sfx_volume() -> float:
        return float(data["settings"]["sfx"])

func set_music_volume(v: float) -> void:
        data["settings"]["music"] = clampf(v, 0.0, 1.0)
        save()

func set_sfx_volume(v: float) -> void:
        data["settings"]["sfx"] = clampf(v, 0.0, 1.0)
        save()

## Interstitial pacing owned by the Box: call after every run.
func should_show_interstitial(every: int) -> bool:
        data["runs_since_interstitial"] = int(data["runs_since_interstitial"]) + 1
        var show := int(data["runs_since_interstitial"]) >= every
        if show:
                data["runs_since_interstitial"] = 0
        save()
        return show
