class_name HWMeta
extends RefCounted
## HEAVY WAR - the persistent armory ledger. Bosses bank points forever,
## the after-boss menu allocates them across the six stats, the shop unlocks
## the four locked stats + the laser rig, skins ride the box's skin shelf.
## Lives inside the box save under games.heavywar.progress.hw (CSMeta shape).

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
                "pts": 0,                  # banked upgrade points (1 per boss)
                "alloc": {},               # stat id -> level 0..5
                "best_places": 0,
                "best_bosses": 0,
                "best_score": 0,
                "kills": 0,
                "runs": 0,
                "lore_seen": false,
        }
        for k in base:
                if not d.has(k):
                        d[k] = base[k]

func save() -> void:
        Box.set_progress(GAME, KEY, d)

# ------------------------------------------------------------------- points
func pts_banked() -> int:
        return int(d["pts"])

func mint_pts(n: int) -> void:
        if n <= 0:
                return
        d["pts"] = pts_banked() + n
        save()

## free points = banked minus what the allocations currently hold
func pts_free() -> int:
        var used := 0
        for k in d["alloc"]:
                used += int(d["alloc"][k])
        return pts_banked() - used

func level_of(stat: String) -> int:
        return int((d["alloc"] as Dictionary).get(stat, 0))

## the armory menu's two moves. Both refuse to break the laws:
## 0 <= level <= 5, the stat must be OWNED (open or shop-unlocked),
## and an increase needs a free point.
func raise(stat: String) -> bool:
        if not stat_open(stat):
                return false
        var lv := level_of(stat)
        if lv >= HWData.UPG_MAX or pts_free() < 1:
                return false
        d["alloc"][stat] = lv + 1
        save()
        return true

func lower(stat: String) -> bool:
        var lv := level_of(stat)
        if lv < 1:
                return false
        d["alloc"][stat] = lv - 1
        save()
        return true

## a stat is assignable when it was born open OR the shop unlocked it
func stat_open(stat: String) -> bool:
        if bool(HWData.UPGRADES[stat]["open"]):
                return true
        return Box.item_owned(GAME, "upg", stat)

# -------------------------------------------------------------- run results
func record_run(places: int, bosses: int, sc: int, kills: int) -> void:
        d["runs"] = int(d["runs"]) + 1
        d["best_places"] = maxi(int(d["best_places"]), places)
        d["best_bosses"] = maxi(int(d["best_bosses"]), bosses)
        d["best_score"] = maxi(int(d["best_score"]), sc)
        d["kills"] = int(d["kills"]) + kills
        save()
        Box.bump_counter(GAME, "hw_kills", kills)
        Box.bump_counter(GAME, "hw_runs", 1)
        Box.max_counter(GAME, "hw_score", sc)
        Box.max_counter(GAME, "hw_places", places)
        Box.max_counter(GAME, "hw_bosses_run", bosses)

## the once-ever law for the intro lore card
func see_lore() -> void:
        if bool(d["lore_seen"]):
                return
        d["lore_seen"] = true
        save()
        Box.bump_counter(GAME, "hw_lore", 1)
