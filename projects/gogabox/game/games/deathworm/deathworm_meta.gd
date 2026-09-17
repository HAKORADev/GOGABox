class_name DWMeta
extends RefCounted
## DEADLY WORM - the survival ledger (v040-9). The wormCoins wallet, the ten
## worms' levels, the owned places and the unlocked power-ups live here.
## Layout follows HWMeta/RBMeta: Box save under games.deathworm.progress.dw.
##
## THE TOP-UP FRAMEWORK (v040-8): the registry declares deadlyworm's
## currency = WORMCOINS, 1 GOGACoin = 5 wormCoins; the box reads/writes the
## wallet through the two static calls below - a top-up lands exactly where
## the runs bank their drops.

const KEY := "dw"
const GAME := "deathworm"

var d := {}

static func load_meta() -> DWMeta:
        var m := DWMeta.new()
        m.d = Box.get_progress(GAME, KEY, {})
        m._heal()
        return m

func _heal() -> void:
        var base := {
                "worm": "w01",            # the selected worm id
                "levels": {},             # id -> {"lvl": n, "xp": n}
                "owned": ["w01"],         # the worm unlock chain
                "wormcoins": 0,
                "total_wormcoins": 0,
                "eaten_total": 0,
                "eaten_humans": 0,
                "eaten_animals": 0,
                "eaten_ground": 0,
                "vehicles": 0,
                "place": "desert",
                "places": ["desert"],     # owned places (the 4 cost GOGACoins)
                "pows": [],               # unlocked power-up kinds
                "runs": 0,
                "best_score": 0,
                "best_time": 0.0,
        }
        for k in base:
                if not d.has(k):
                        d[k] = base[k]
        if not (d["levels"] is Dictionary):
                d["levels"] = {}
        if not (d["owned"] is Array):
                d["owned"] = ["w01"]
        if not (d["places"] is Array):
                d["places"] = ["desert"]
        if not (d["pows"] is Array):
                d["pows"] = []

func save() -> void:
        Box.set_progress(GAME, KEY, d)

# ------------------------------------------------------------ the wallet
func coins() -> int:
        return int(d["wormcoins"])

func add_coins(n: int) -> void:
        if n <= 0:
                return
        d["wormcoins"] = int(d["wormcoins"]) + n
        d["total_wormcoins"] = int(d["total_wormcoins"]) + n
        save()

func spend_coins(n: int) -> bool:
        if int(d["wormcoins"]) < n or n < 0:
                return false
        d["wormcoins"] = int(d["wormcoins"]) - n
        save()
        return true

# --------------------------------------------------------- worm progress
func lvl(id: String) -> int:
        return int((d["levels"] as Dictionary).get(id, {}).get("lvl", 1))

func xp(id: String) -> int:
        return int((d["levels"] as Dictionary).get(id, {}).get("xp", 0))

func set_level(id: String, level: int, xp_v: int) -> void:
        (d["levels"] as Dictionary)[id] = {"lvl": level, "xp": xp_v}
        save()

func owns(id: String) -> bool:
        return (d["owned"] as Array).has(id)

func unlock_worm(id: String) -> void:
        if not (d["owned"] as Array).has(id):
                (d["owned"] as Array).append(id)
                save()

# ------------------------------------------------------------- the places
func place() -> String:
        return String(d["place"])

func set_place(p: String) -> void:
        d["place"] = p
        save()

func owns_place(p: String) -> bool:
        return (d["places"] as Array).has(p)

func unlock_place(p: String) -> void:
        if not (d["places"] as Array).has(p):
                (d["places"] as Array).append(p)
                save()

# ------------------------------------------------------------ power-ups
func owns_pow(k: String) -> bool:
        return (d["pows"] as Array).has(k)

func unlock_pow(k: String) -> void:
        if not (d["pows"] as Array).has(k):
                (d["pows"] as Array).append(k)
                save()

# -------------------------------------------------------------- records
func record_run(score: int, seconds: float, humans: int, animals: int,
                ground: int, vehicles: int) -> void:
        d["runs"] = int(d["runs"]) + 1
        d["best_score"] = maxi(int(d["best_score"]), score)
        d["best_time"] = maxf(float(d["best_time"]), seconds)
        d["eaten_total"] = int(d["eaten_total"]) + humans + animals + ground
        d["eaten_humans"] = int(d["eaten_humans"]) + humans
        d["eaten_animals"] = int(d["eaten_animals"]) + animals
        d["eaten_ground"] = int(d["eaten_ground"]) + ground
        d["vehicles"] = int(d["vehicles"]) + vehicles
        save()
        Box.bump_counter(GAME, "dw_runs", 1)
        Box.bump_counter(GAME, "dw_eaten", humans + animals + ground)
        Box.bump_counter(GAME, "dw_humans", humans)
        Box.bump_counter(GAME, "dw_animals", animals)
        Box.bump_counter(GAME, "dw_ground", ground)
        Box.bump_counter(GAME, "dw_vehicles", vehicles)
        Box.max_counter(GAME, "dw_score", score)
        Box.max_counter(GAME, "dw_time", int(seconds))
        Box.max_counter(GAME, "dw_worms_owned", (d["owned"] as Array).size())
        Box.max_counter(GAME, "dw_places_owned", (d["places"] as Array).size())

# ------------------------------------------- THE TOP-UP FRAMEWORK (v040-8)
## The two static calls the box's GameCoin reads/writes. The wallet is the
## game's own store - a top-up settles exactly where the drops land.
static func coin_balance() -> int:
        return load_meta().coins()

static func coin_add(n: int) -> void:
        if n <= 0:
                return
        load_meta().add_coins(n)
