class_name HWMeta
extends RefCounted
## HEAVY WAR: ROGUE ARSENAL - the run ledger (v040-4). The boss-point
## armory is gone (the shop carries progression now); this keeps the
## records + the once-ever lore law. Lives in Box save under
## games.heavywar.progress.hw.

const KEY := "hw"
const GAME := "heavywar"

var d := {}

static func load_meta() -> HWMeta:
	var m := HWMeta.new()
	m.d = Box.get_progress(GAME, KEY, {})
	m._heal()
	return m

func _heal() -> void:
	var base := {
		"best_kills": 0,
		"best_place": 0,
		"best_loop": 1,
		"best_bosses": 0,
		"kills": 0,
		"boss_kills": 0,
		"runs": 0,
		"lore_seen": false,
	}
	for k in base:
		if not d.has(k):
			d[k] = base[k]

func save() -> void:
	Box.set_progress(GAME, KEY, d)

func record_run(kills: int, places: int, loops: int, bosses: int) -> void:
	d["runs"] = int(d["runs"]) + 1
	d["best_kills"] = maxi(int(d["best_kills"]), kills)
	d["best_place"] = maxi(int(d["best_place"]), places)
	d["best_loop"] = maxi(int(d["best_loop"]), loops)
	d["best_bosses"] = maxi(int(d["best_bosses"]), bosses)
	d["kills"] = int(d["kills"]) + kills
	save()
	Box.bump_counter(GAME, "hw_kills", kills)
	Box.bump_counter(GAME, "hw_runs", 1)
	Box.bump_counter(GAME, "hw_boss_bank", bosses)
	Box.max_counter(GAME, "hw_score", kills)
	Box.max_counter(GAME, "hw_places", places)
	Box.max_counter(GAME, "hw_bosses_run", bosses)

func see_lore() -> void:
	if bool(d["lore_seen"]):
		return
	d["lore_seen"] = true
	save()
	Box.bump_counter(GAME, "hw_lore", 1)
