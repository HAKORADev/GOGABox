extends Node
## Persistent game state: coins, best score, skins, daily streak, settings.
## Saved as JSON at user://save.json.

signal coins_changed(total: int)
signal skin_changed(skin_id: String)

const SAVE_PATH := "user://save.json"
const DAILY_BASE := 50
const DAILY_STEP := 25
const DAILY_CAP := 200

## Catalog order = shop order. prefix selects the sprite set, tint is the
## modulate applied on top (used by the two recolored variants).
const SKINS := [
	{"id": "mint", "name": "Mint", "price": 0, "prefix": "player_mint", "tint": Color(1, 1, 1)},
	{"id": "sky", "name": "Sky", "price": 150, "prefix": "player_sky", "tint": Color(1, 1, 1)},
	{"id": "bubblegum", "name": "Bubblegum", "price": 300, "prefix": "player_bubblegum", "tint": Color(1, 1, 1)},
	{"id": "gold", "name": "Gold", "price": 700, "prefix": "player_mint", "tint": Color(1.25, 0.98, 0.35)},
	{"id": "cosmic", "name": "Cosmic", "price": 1200, "prefix": "player_sky", "tint": Color(0.78, 0.6, 1.3)},
]

var data := {
	"coins": 0,
	"best": 0,
	"runs": 0,
	"owned": ["mint"],
	"skin": "mint",
	"daily_streak": 0,
	"last_daily": "",
	"sound": true,
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
		data["owned"] = ["mint"]

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

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

func best() -> int:
	return int(data["best"])

func submit_score(score: int) -> bool:
	if score > int(data["best"]):
		data["best"] = score
		save()
		return true
	return false

# ---------------------------------------------------------------- skins

func skin() -> Dictionary:
	for s in SKINS:
		if s["id"] == data["skin"]:
			return s
	return SKINS[0]

func owns(id: String) -> bool:
	return id in (data["owned"] as Array)

func buy_skin(id: String) -> bool:
	var found: Dictionary = {}
	for s in SKINS:
		if s["id"] == id:
			found = s
	if found.is_empty() or owns(id):
		return false
	if not try_spend(int(found["price"])):
		return false
	(data["owned"] as Array).append(id)
	equip_skin(id)
	return true

func equip_skin(id: String) -> void:
	if not owns(id):
		return
	data["skin"] = id
	save()
	skin_changed.emit(id)

# ---------------------------------------------------------------- daily reward

static func today_key() -> String:
	return Time.get_date_string_from_system()

static func yesterday_key() -> String:
	var t := Time.get_unix_time_from_system() - 86400.0
	var d := Time.get_datetime_dict_from_unix_time(int(t))
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]

func can_claim_daily() -> bool:
	return String(data["last_daily"]) != today_key()

func daily_streak() -> int:
	return int(data["daily_streak"])

func daily_preview() -> int:
	var streak := daily_streak() + 1 if String(data["last_daily"]) == yesterday_key() else 1
	return mini(DAILY_BASE + (streak - 1) * DAILY_STEP, DAILY_CAP)

## Claims today's reward. Returns the amount (0 if already claimed).
## Consecutive days raise the reward; missing a day resets the streak.
func claim_daily() -> int:
	if not can_claim_daily():
		return 0
	var streak := 1
	if String(data["last_daily"]) == yesterday_key():
		streak = daily_streak() + 1
	var reward := mini(DAILY_BASE + (streak - 1) * DAILY_STEP, DAILY_CAP)
	data["daily_streak"] = streak
	data["last_daily"] = today_key()
	add_coins(reward)
	return reward
