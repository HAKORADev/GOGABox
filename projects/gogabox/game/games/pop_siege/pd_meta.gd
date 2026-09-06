class_name PDMeta
extends RefCounted
## POP SIEGE - the persistent ledger. Lives inside the box save under
## games.pop_siege.progress.ps - one dictionary, saved through Box.set_progress
## (the box's own save law, the CSMeta pattern).

const KEY := "ps"

var d := {}

static func load_meta() -> PDMeta:
        var m := PDMeta.new()
        m.d = Box.get_progress("pop_siege", KEY, {})
        m._heal()
        return m

func _heal() -> void:
        var base := {
                "owned_folk": PDData.FREE_FOLK.duplicate(),   # the free trio
                "owned_maps": PDData.FREE_MAPS.duplicate(),   # the free three maps
                "dn": {},                 # map id -> true(night)/false(day), remembered
                "current_map": PDData.FREE_MAPS[0],
                "best_wave": {},          # map id -> best wave reached
                "best_score": 0,
                "pops": 0,                # lifetime bloons popped (layers)
                "moabs": 0,               # lifetime blimps grounded
                "gears3": 0,              # lifetime gear-3 jumps
                "runs": 0,
                "riders": 0,              # gogacoins collected from carriers, lifetime
                "seen_blimp": false,      # the first-glance hints
                "seen_multipath": false,
                "auto": true,             # the A/M law (remembered)
        }
        for k in base:
                if not d.has(k):
                        d[k] = base[k]
        # never lose the free trio
        for fid in PDData.FREE_FOLK:
                if not (d["owned_folk"] as Array).has(fid):
                        (d["owned_folk"] as Array).append(fid)
        for mid in PDData.FREE_MAPS:
                if not (d["owned_maps"] as Array).has(mid):
                        (d["owned_maps"] as Array).append(mid)

func save() -> void:
        Box.set_progress("pop_siege", KEY, d)

# ---------------------------------------------------------------- ownership
func has_folk(fid: String) -> bool:
        return (d["owned_folk"] as Array).has(fid)

func own_folk(fid: String) -> void:
        if not has_folk(fid):
                (d["owned_folk"] as Array).append(fid)
                save()

## THE ONE-SOURCE LAW (the CS gogabuy pattern): the universal GOGACoins shop
## pays from the box wallet and flips the same flag the game reads.
func gogabuy_folk(fid: String) -> bool:
        own_folk(fid)
        return true

func has_map(mid: String) -> bool:
        return (d["owned_maps"] as Array).has(mid)

func own_map(mid: String) -> void:
        if not has_map(mid):
                (d["owned_maps"] as Array).append(mid)
                save()

func gogabuy_map(mid: String) -> bool:
        own_map(mid)
        return true

# ------------------------------------------------------------------ current
func current_map() -> String:
        if not has_map(String(d["current_map"])):
                d["current_map"] = PDData.FREE_MAPS[0]
        return String(d["current_map"])

func set_current_map(mid: String) -> void:
        d["current_map"] = mid
        save()

func is_night(mid: String) -> bool:
        return bool((d["dn"] as Dictionary).get(mid, false))

func set_night(mid: String, nite: bool) -> void:
        (d["dn"] as Dictionary)[mid] = nite
        save()

# ------------------------------------------------------------------ records
func best_wave(mid: String) -> int:
        return int((d["best_wave"] as Dictionary).get(mid, 0))

func record_run(mid: String, wave: int, sc: int, pops: int, blimps: int, g3jumps: int, riders: int) -> void:
        d["runs"] = int(d["runs"]) + 1
        var bw: Dictionary = d["best_wave"]
        bw[mid] = maxi(int(bw.get(mid, 0)), wave)
        d["best_score"] = maxi(int(d["best_score"]), sc)
        d["pops"] = int(d["pops"]) + pops
        d["moabs"] = int(d["moabs"]) + blimps
        d["gears3"] = int(d["gears3"]) + g3jumps
        d["riders"] = int(d["riders"]) + riders
        save()
        Box.bump_counter("pop_siege", "pops", pops)
        Box.bump_counter("pop_siege", "runs", 1)
        if wave > 0:
                Box.max_counter("pop_siege", "wave_best", wave)
                Box.max_counter("pop_siege", "score_best", sc)

# ------------------------------------------------------------------- hints
func seen_blimp() -> bool:
        return bool(d["seen_blimp"])

# ------------------------------------------------------------------ the A/M
func auto_waves() -> bool:
        return bool(d.get("auto", true))

func set_auto_waves(a: bool) -> void:
        d["auto"] = a
        save()

func mark_blimp() -> void:
        d["seen_blimp"] = true
        save()

func seen_multipath() -> bool:
        return bool(d["seen_multipath"])

func mark_multipath() -> void:
        d["seen_multipath"] = true
        save()
