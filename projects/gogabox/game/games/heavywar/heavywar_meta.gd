class_name HWMeta
extends RefCounted
## HEAVY WAR: ROGUE ARSENAL - the run ledger (v040-5). The SCRAP BANK and
## the scrap shop upgrades live here (the HTML prototype's localStorage is
## the law: scrap / totalScrap / upgrades). The records + the once-ever
## lore law ride along. Lives in Box save under games.heavywar.progress.hw.

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
                # v040-5 THE SCRAP BANK (the HTML save law)
                "scrap": 0,
                "total_scrap": 0,
                "upg": {},
        }
        for k in base:
                if not d.has(k):
                        d[k] = base[k]
        if not (d["upg"] is Dictionary):
                d["upg"] = {}

func save() -> void:
        Box.set_progress(GAME, KEY, d)

# ------------------------------------------------------------ the scrap bank
func scrap() -> int:
        return int(d["scrap"])

func total_scrap() -> int:
        return int(d["total_scrap"])

func bank_scrap(n: int) -> void:
        if n <= 0:
                return
        d["scrap"] = int(d["scrap"]) + n
        d["total_scrap"] = int(d["total_scrap"]) + n
        save()

func spend_scrap(n: int) -> bool:
        if int(d["scrap"]) < n or n < 0:
                return false
        d["scrap"] = int(d["scrap"]) - n
        save()
        return true

# ----------------------------------------------------------------- upgrades
func upg_lvl(id: String) -> int:
        return int((d["upg"] as Dictionary).get(id, 0))

func set_upg(id: String, lvl: int) -> void:
        (d["upg"] as Dictionary)[id] = lvl
        save()

# ------------------------------------------------------------------ records
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

# ------------------------------------------- THE TOP-UP FRAMEWORK (v040-8)
## The two static calls the box's GameCoin reads/writes (declared in the
## registry: heavywar's currency = SCRAP, 1 GOGACoin = 5 scrap). A top-up
## lands in the SAME store the SCRAP SHOP spends.
static func coin_balance() -> int:
        var m := load_meta()
        return m.scrap()

static func coin_add(n: int) -> void:
        if n <= 0:
                return
        var m := load_meta()
        m.bank_scrap(n)
