extends Node
## Persistent state: coins, skins, endless level progress, settings.
## Saved as JSON at user://save.json. Mirrors the jellyjump pattern.

signal coins_changed(total: int)
signal skin_changed(skin_id: String)

const SAVE_PATH := "user://save.json"

## Catalog order = shop order.
const SKINS := [
        {"id": "candy", "name": "Candy Shop", "price": 0},
        {"id": "gems", "name": "Gem Vault", "price": 400},
        {"id": "fruits", "name": "Retro Fruits", "price": 900},
        {"id": "neon", "name": "Neon Arcade", "price": 1500},
]

var data := {
        "coins": 0,
        "level": 1,          # next level to play (endless: no cap)
        "best_level": 0,
        "owned": ["candy"],
        "skin": "candy",
        "sound": true,
        "music": true,
}

func _ready() -> void:
        load_save()

# ---------------------------------------------------------------- save/load

func load_save() -> void:
        if not FileAccess.file_exists(SAVE_PATH):
                return
        var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
        if f == null:
                return
        var parsed: Variant = JSON.parse_string(f.get_as_text())
        if parsed is Dictionary:
                for k in parsed:
                        data[k] = parsed[k]
        if not (data["owned"] is Array) or (data["owned"] as Array).is_empty():
                data["owned"] = ["candy"]

func save() -> void:
        var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
        if f:
                f.store_string(JSON.stringify(data))

## Wipe to defaults (used by tests and a hypothetical "reset progress").
func reset() -> void:
        data = {
                "coins": 0,
                "level": 1,
                "best_level": 0,
                "owned": ["candy"],
                "skin": "candy",
                "sound": true,
                "music": true,
        }
        save()

# ---------------------------------------------------------------- economy

func coins() -> int:
        return int(data["coins"])

func add_coins(amount: int) -> void:
        data["coins"] = int(data["coins"]) + amount
        save()
        coins_changed.emit(coins())

func try_spend(amount: int) -> bool:
        if int(data["coins"]) < amount:
                return false
        data["coins"] = int(data["coins"]) - amount
        save()
        coins_changed.emit(coins())
        return true

# ---------------------------------------------------------------- progress

func level() -> int:
        return int(data["level"])

func complete_level(won_level: int, score: int, stars: int) -> void:
        # endless: finishing a level always unlocks the next one
        if won_level >= int(data["level"]):
                data["level"] = won_level + 1
        if won_level > int(data["best_level"]):
                data["best_level"] = won_level
        save()

# ---------------------------------------------------------------- skins

func skin() -> String:
        return String(data["skin"])

func owned() -> Array:
        return data["owned"]

func owns(id: String) -> bool:
        return data["owned"].has(id)

func equip(id: String) -> void:
        if owns(id):
                data["skin"] = id
                save()
                skin_changed.emit(id)

func buy(id: String, price: int) -> bool:
        if owns(id) or not try_spend(price):
                return false
        data["owned"].append(id)
        data["skin"] = id
        save()
        skin_changed.emit(id)
        return true

# ---------------------------------------------------------------- settings

func toggle_sound() -> void:
        data["sound"] = not data["sound"]
        save()

func toggle_music() -> void:
        data["music"] = not data["music"]
        save()
