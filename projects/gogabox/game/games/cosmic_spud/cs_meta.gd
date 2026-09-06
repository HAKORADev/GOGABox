class_name CSMeta
extends RefCounted
## COSMIC SPUD - the persistent ledger (the owner's economy law: everything
## is bought AND sold for the game's own COSMIC COINS; XP banks into the
## character level that gates shops + the tree).
## Lives inside the box save under games.cosmic_spud.progress.cs - one
## dictionary, saved through Box.set_progress (the box's own save law).

const KEY := "cs"

var d := {}

static func load_meta() -> CSMeta:
        var m := CSMeta.new()
        m.d = Box.get_progress("cosmic_spud", KEY, {})
        m._heal()
        return m

func _heal() -> void:
        # the defaults merge - a fresh install or an old save both land here
        var base := {
                "coins": 150,               # starting cosmic coins
                "char_xp": 0,
                "char_level": 1,
                "owned_weapons": CSData.START_WEAPONS.duplicate(),
                "loadout": CSData.START_WEAPONS.duplicate(),   # the 3 equipped ids
                "owned_allies": [],
                "owned_themes": ["desert"],
                "theme": "desert",
                "night": false,
                "tree": {},                 # node id -> true
                "starts_played": [],        # the six-pack achievement
                "best_wave": 0,
                "best_score": 0,
                "kills": 0,
                "merges": 0,
                "banked_total": 0,
                "runs": 0,
                "gogacoins": 0,             # the every-5th-wave riders, lifetime
                "skills": {},               # THE SKILLS (v0.3.4-3): id -> true
                "skill_spent": 0,           # the spent skill points
                "seen_kinds": [],           # THE FIRST-GLANCE LAW (v0.3.5)
        }
        for k in base:
                if not d.has(k):
                        d[k] = base[k]

func save() -> void:
        Box.set_progress("cosmic_spud", KEY, d)

## THE FIRST-GLANCE LAW (v0.3.5): each special enemy's hint banner speaks
## ONCE per save - the first encounter explains itself, then never nags.
func seen_kind(kind: String) -> bool:
        return kind in (d.get("seen_kinds", []) as Array)

func mark_seen_kind(kind: String) -> void:
        var arr: Array = d.get("seen_kinds", [])
        if not arr.has(kind):
                arr.append(kind)
        d["seen_kinds"] = arr
        save()

# ------------------------------------------------------------------ wallet
func coins() -> int:
        return int(d["coins"])

func earn(v: int) -> void:
        if v <= 0:
                return
        d["coins"] = int(d["coins"]) + v
        d["banked_total"] = int(d["banked_total"]) + v
        save()

func spend(v: int) -> bool:
        if coins() < v:
                return false
        d["coins"] = int(d["coins"]) - v
        save()
        return true

# -------------------------------------------------------------- character
func char_xp() -> int:
        return int(d["char_xp"])

func char_level() -> int:
        return int(d["char_level"])

func char_next() -> int:
        return CSData.xp_for_char_level(char_level())

## XP banks 100% (the GDD's dual-duty law). Returns the levels gained.
func bank_char_xp(v: int) -> int:
        if v <= 0:
                return 0
        d["char_xp"] = char_xp() + v
        var gained := 0
        while char_xp() >= char_next():
                d["char_xp"] = char_xp() - char_next()
                d["char_level"] = char_level() + 1
                gained += 1
        if gained > 0:
                save()
        return gained

func tier_cap() -> int:
        return CSData.tier_cap_for(char_level())

# ---------------------------------------------------------------- ownership
func own_weapon(wid: String) -> void:
        if not (d["owned_weapons"] as Array).has(wid):
                (d["owned_weapons"] as Array).append(wid)
                save()

func has_weapon(wid: String) -> bool:
        return (d["owned_weapons"] as Array).has(wid)

func weapon_count(wid: String) -> int:
        # owned copies of one weapon kind (for merges): tracked as tier entries
        # loadout = [[wid, tier], ...] of EQUIPPED; armory = [[wid, tier], ...]
        var n := 0
        for e in armory():
                if e[0] == wid:
                        n += 1
        return n

func armory() -> Array:
        # every owned weapon INSTANCE as [wid, tier] (multi-copies for merging)
        if not d.has("armory"):
                var arr := []
                for wid in d["owned_weapons"]:
                        arr.append([wid, 1])
                d["armory"] = arr
        return d["armory"]

func add_armory(wid: String, tier: int) -> void:
        armory().append([wid, tier])
        if not has_weapon(wid):
                own_weapon(wid)
        save()

func remove_armory(wid: String, tier: int) -> bool:
        for i in armory().size():
                var e: Array = armory()[i]
                if e[0] == wid and int(e[1]) == tier:
                        armory().remove_at(i)
                        save()
                        return true
        return false

func count_armory(wid: String, tier: int) -> int:
        var n := 0
        for e in armory():
                if e[0] == wid and int(e[1]) == tier:
                        n += 1
        return n

func loadout() -> Array:
        if (d["loadout"] as Array).is_empty():
                d["loadout"] = CSData.START_WEAPONS.duplicate()
        return d["loadout"]

func set_loadout(arr: Array) -> void:
        d["loadout"] = arr
        save()

func own_ally(aid: String) -> void:
        if not (d["owned_allies"] as Array).has(aid):
                (d["owned_allies"] as Array).append(aid)
                save()

func has_ally(aid: String) -> bool:
        return (d["owned_allies"] as Array).has(aid)

func own_theme(tid: String) -> void:
        if not (d["owned_themes"] as Array).has(tid):
                (d["owned_themes"] as Array).append(tid)
                save()

func has_theme(tid: String) -> bool:
        return (d["owned_themes"] as Array).has(tid)

func set_theme(tid: String, night: bool) -> void:
        d["theme"] = tid
        d["night"] = night
        save()

func theme() -> String:
        return String(d["theme"])

func is_night() -> bool:
        return bool(d["night"])

# --------------------------------------------------------------------- tree
func tree_has(nid: String) -> bool:
        return bool((d["tree"] as Dictionary).get(nid, false))

func tree_can_buy(nid: String) -> bool:
        var n: Dictionary = CSData.TREE[nid]
        if tree_has(nid):
                return false
        if n["need"] != "" and not tree_has(String(n["need"])):
                return false
        if char_level() < int(n["clv"]):
                return false
        return coins() >= int(n["cost"])

func tree_buy(nid: String) -> bool:
        if not tree_can_buy(nid):
                return false
        if not spend(int(CSData.TREE[nid]["cost"])):
                return false
        (d["tree"] as Dictionary)[nid] = true
        save()
        return true

func tree_node(nid: String) -> bool:
        # the read helpers the run uses
        return tree_has(nid)

## v0.3.4-4 THE SHOP LIST LAW: the universal THE SHOP sells the LAB nodes
## (WEAPON LAB = the merging, FOUNDRY) for REAL GOGACoins - the box wallet
## paid first (Box.spend in the caller), this just flips the same flag the
## cosmic-coin tree writes, so the run reads one source of truth.
func gogabuy_node(nid: String) -> bool:
        if not (CSData.TREE.has(nid)):
                return false
        (d["tree"] as Dictionary)[nid] = true
        save()
        return true

func merging_learned() -> bool:
        return tree_has("l3")

func weapon_slots() -> int:
        var n := 4
        if tree_has("o3"):
                n += 1
        if tree_has("l5"):
                n += 1
        return n

func ally_slots() -> int:
        return 3 if tree_has("l1") else 2

func merge_discount() -> float:
        return 0.75 if tree_has("l4") else 1.0

func shop_discount() -> float:
        return 0.9 if tree_has("u4") else 1.0

# ------------------------------------------------------------------ skills
## THE SKILLS LAW (v0.3.4-3, the owner: "skills should be earned from each
## 100 kill as a point" + "why are coins and skills currently saved per
## different game rounds"): the points are LIFETIME - banked kills plus the
## live run's kills, one point per 100, minus the spent ones. They NEVER
## reset with a round.
func skill_points_free(live_kills := 0) -> int:
        var earned := int(floor(float(int(d["kills"]) + int(live_kills)) / 100.0))
        return earned - int(d.get("skill_spent", 0))

func has_skill(sid: String) -> bool:
        return bool((d.get("skills", {}) as Dictionary).get(sid, false))

func buy_skill(sid: String, live_kills := 0) -> bool:
        if not CSData.SKILLS.has(sid) or has_skill(sid):
                return false
        var cost := int(CSData.SKILLS[sid]["cost"])
        if skill_points_free(live_kills) < cost:
                return false
        if not d.has("skills"):
                d["skills"] = {}
        (d["skills"] as Dictionary)[sid] = true
        d["skill_spent"] = int(d.get("skill_spent", 0)) + cost
        save()
        return true

# ------------------------------------------------------------- run results
func record_run(wave: int, sc: int, kills: int, merges: int, start_id: String) -> void:
        d["runs"] = int(d["runs"]) + 1
        d["best_wave"] = maxi(int(d["best_wave"]), wave)
        d["best_score"] = maxi(int(d["best_score"]), sc)
        d["kills"] = int(d["kills"]) + kills
        d["merges"] = int(d["merges"]) + merges
        if not (d["starts_played"] as Array).has(start_id):
                (d["starts_played"] as Array).append(start_id)
        save()
        Box.bump_counter("cosmic_spud", "kills", kills)
        Box.bump_counter("cosmic_spud", "runs", 1)
        if wave > 0:
                Box.max_counter("cosmic_spud", "wave_best", wave)
                Box.max_counter("cosmic_spud", "score_best", sc)
