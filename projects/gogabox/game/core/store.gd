extends Node
## Box — the one save/wallet/progress/achievement brain for ALL GOGABox games.
## Games NEVER touch this directly; they go through GogaGame helpers.

signal coins_changed(total: int)
signal game_unlocked(id: String)
signal reveal_changed(id: String)   # a game's feed state changed (mystery->locked...)
signal batteries_changed
signal battery_round_ready          # v0.1.2: an extra ROUND just became affordable

const SAVE_PATH := "user://gogabox.json"
const START_COINS := 150
const BATTERY_STEP := 300          # one GOGABattery per 5 minutes
const BOX_BATTERY_CAP := 50        # global box pool (recharges only while CLOSED)

var data := {}

func _ready() -> void:
        _load()
        # v0.1.1: cold start after the process was killed - credit the time
        # the box spent CLOSED (same math as APPLICATION_RESUMED; idempotent).
        _credit_offline()

# ------------------------------------------------------------- persistence

func _defaults() -> Dictionary:
        return {
                "coins": START_COINS,
                "owned": ["snake"],           # snake is the free starter game
                "settings": {"music": 0.8, "sfx": 0.9},
                "runs_since_interstitial": 0,
                "games": {},                  # per-game: best/last/plays/counters/ach/progress
                "meta": {},                   # box-wide: reveal bookkeeping, last_play, ...
                "favorites": [],              # favorited game ids (heart in the pre-play menu)
                # v0.1.1 THE BOX BANK CHARGES ONLY WHILE GOGABOX IS CLOSED
                # (owner rule, replaces the v0.0.7 "charges ALWAYS" model):
                #   ts  = unix moment the charging window OPENED (app paused /
                #         process died). 0 while the app is open.
                #   rem = closed-seconds already banked toward the next +1
                #         (carries the remainder between sessions).
                "box_batteries": {"count": BOX_BATTERY_CAP, "ts": 0, "rem": 0},
                "game_batteries": {},         # id -> {"count": n, "ts": unix} (refill always)
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
        if not (data["favorites"] is Array):
                data["favorites"] = []
        _migrate_box_pool()

## v0.1.1: the box bank charges ONLY while the app is CLOSED (owner rule -
## "the GOGABox battery bank still charges even inside the app... i have
## never said that"). The v0.0.7 always-on ts pool is migrated: its pending
## regen state was already paid out on reads, so the clock just resets here.
func _migrate_box_pool() -> void:
        var now := int(Time.get_unix_time_from_system())
        var v: Variant = data.get("box_batteries", BOX_BATTERY_CAP)
        if not (v is Dictionary):
                var count := clampi(int(v), 0, BOX_BATTERY_CAP)
                data["box_batteries"] = {"count": count, "ts": now, "rem": 0}
                save()
                return
        var p: Dictionary = v
        p["ts"] = int(p.get("ts", 0))
        if not (p.get("rem", 0) is int):
                p["rem"] = int(float(p.get("rem", 0)))
        # pre-v0.1.1 saves carry no "rem" - start the offline clock clean
        if not p.has("rem"):
                p["rem"] = 0
                p["ts"] = now
                save()

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
        _slot(id)["badge"] = ""      # any badge dies with the first tap
        save()

# ------------------------------------------------------------- favorites (v0.0.9)
## The heart in the pre-play menu. Favorites are a box-level list (NOT a
## per-game slot) so the FAVORITES feed in search can read it in one call.
func is_favorite(id: String) -> bool:
        return (data["favorites"] as Array).has(id)

func set_favorite(id: String, on: bool) -> void:
        var arr := data["favorites"] as Array
        if on and not arr.has(id):
                arr.append(id)
                save()
        elif not on and arr.has(id):
                arr.erase(id)
                save()

# --------------------------------------------------- feed badges (v0.0.7)
## Two-level badge per game tile (owner rule):
##   "new"      - the teaser just APPEARED (orange NEW!)
##   "unlocked" - it resolved into a real buyable tile (green UNLOCKED!)
##   ""         - tapped / seen: no badge
## Roadmap.tick() sets + upgrades levels; mark_seen() clears.
func badge(id: String) -> String:
        return String(_slot(id).get("badge", ""))

func set_badge(id: String, level: String) -> void:
        if badge(id) == level:
                return
        _slot(id)["badge"] = level
        save()

# ------------------------------------------------------------- GOGABatteries

## Global pool. v0.1.1 OWNER RULE: this bank is a REAL battery bank - it
## charges ONLY while GOGABox is closed, NEVER while the app is open. Reads
## are pure (no lazy regen, no save): charging happens exclusively in
## _credit_offline(), when the app comes back (resume / cold start).
func box_batteries() -> int:
        var p: Dictionary = data["box_batteries"]
        return clampi(int(p.get("count", BOX_BATTERY_CAP)), 0, BOX_BATTERY_CAP)

## Convert the closed window (now - ts, plus any banked remainder) into
## batteries. Called on APPLICATION_RESUMED and on cold start. Idempotent:
## the window is stamped shut (ts = now) on every credit.
func _credit_offline() -> void:
        var p: Dictionary = data["box_batteries"]
        var stamp := int(p.get("ts", 0))
        var now := int(Time.get_unix_time_from_system())
        if stamp <= 0:
                p["ts"] = 0          # open right now - no charging window
                return
        var away := now - stamp
        p["ts"] = 0                  # window shut: we are (back) in the app
        if away <= 0:
                return
        var total := int(p.get("rem", 0)) + away
        var add := total / BATTERY_STEP
        p["rem"] = total % BATTERY_STEP
        if add > 0:
                var before := int(p.get("count", 0))
                p["count"] = clampi(before + add, 0, BOX_BATTERY_CAP)
                save()
                batteries_changed.emit()
                # v0.1.2 OWNER RULE: ping "a round became ready", not "full" -
                # here the BANK crossed one round's worth while we were away
                if before < _round_need() and int(p["count"]) >= _round_need():
                        _battery_round_sfx()

## Closed time still needed for the next +1 (0 when full). CONSTANT while
## the app is open (the bank only moves while closed) - the battery sheet
## prints it as "away time", which is exactly what it is.
func box_regen_in() -> int:
        if box_batteries() >= BOX_BATTERY_CAP:
                return 0
        var p: Dictionary = data["box_batteries"]
        return BATTERY_STEP - (int(p.get("rem", 0)) % BATTERY_STEP)

func box_battery_cap() -> int:
        return BOX_BATTERY_CAP

## Write access used by spends/refills/tests (the offline clock is NOT
## touched: spending batteries while open has no effect on charging).
func set_box_batteries(n: int) -> void:
        data["box_batteries"]["count"] = clampi(n, 0, BOX_BATTERY_CAP)
        save()
        batteries_changed.emit()

## Per-game pool: fully modular per game (registry `charges`):
##   per_round      batteries one play costs
##   capacity       pool size
##   regen_minutes  minutes for +1 (this game's own rhythm)
## Refills in AND out of the box. Returns {} when the game has no charges.
func game_battery(id: String) -> Dictionary:
        var g := GameReg.get_game(id)
        if g.is_empty() or not g.has("charges"):
                return {}
        var cap := int(g["charges"].get("capacity", 10))
        var step := maxi(60, int(g["charges"].get("regen_minutes", 5)) * 60)
        var pools: Dictionary = data["game_batteries"]
        var now := int(Time.get_unix_time_from_system())
        if not pools.has(id):
                pools[id] = {"count": cap, "ts": now}
        var p: Dictionary = pools[id]
        var count := int(p["count"])
        if count < cap:
                var elapsed := now - int(p.get("ts", now))
                var regen := elapsed / step
                if regen > 0:
                        var before := count
                        count = mini(cap, count + regen)
                        p["ts"] = now - (elapsed % step)
                        p["count"] = count
                        save()
                        # v0.1.2 OWNER RULE: the in-app sound is "batteries for
                        # a ROUND recharged" - the pool just crossed one round's
                        # worth (below per_round before, at/above it now). The
                        # old pool-is-full ping is GONE ("instead", owner).
                        var need := int(g["charges"].get("per_round", 2))
                        if before < need and count >= need:
                                _battery_round_sfx()
        var regen_in := 0
        if count < cap:
                regen_in = step - ((now - int(p.get("ts", now))) % step)
        return {"count": count, "cap": cap, "step": step,
                "per_round": int(g["charges"].get("per_round", 2)), "regen_in": regen_in}

## Spend one round: takes from BOTH the game pool AND the box bank (owner
## rule). False (and nothing spent) unless both can afford it.
func consume_round_batteries(id: String) -> bool:
        var b := game_battery(id)
        if b.is_empty():
                return true   # game plays without charges
        var need := int(b["per_round"])
        if int(b["count"]) < need or box_batteries() < need:
                return false
        data["game_batteries"][id]["count"] = int(b["count"]) - need
        set_box_batteries(box_batteries() - need)
        _sync_battery_notifications()
        return true

## Emergency refill: pour from the global box bank into a game pool - ONE
## ROUND worth per tap (owner rule). The game pool's capacity is a hard
## ceiling (it can never grow past cap - no extra batteries), and the tap
## never moves more than the box bank holds. Returns the number of batteries
## transferred (0 = nothing to move).
func refill_game_from_box(id: String) -> int:
        var b := game_battery(id)
        if b.is_empty():
                return 0
        var want := mini(int(b["per_round"]), int(b["cap"]) - int(b["count"]))
        var move := mini(want, box_batteries())
        if move <= 0:
                return 0
        data["game_batteries"][id]["count"] = int(b["count"]) + move
        set_box_batteries(box_batteries() - move)
        _sync_battery_notifications()
        return move

## v0.1.1: pause OPENS the charging window (the box starts "charging on the
## shelf"); resume / cold start banks the closed time. The pause stamp also
## feeds the "while you were away" notification schedule.
func _notification(what: int) -> void:
        if what == NOTIFICATION_APPLICATION_PAUSED:
                data["box_batteries"]["ts"] = int(Time.get_unix_time_from_system())
                meta()["closed_ts"] = int(data["box_batteries"]["ts"])
                save()
                _schedule_battery_notifications()
        elif what == NOTIFICATION_APPLICATION_RESUMED:
                _credit_offline()      # credit the closed time right away
                _cancel_battery_notifications()

## v0.1.2 menu-tick helper: read every owned charged game's pool so lazy
## regen (and the round-ready ping) happens LIVE while the player sits in
## the box - not only when a sheet or pre-play page happens to read it.
## Pure reads at steady state (no save, no signal unless regen moved a pool).
func poll_game_batteries() -> void:
        for g in GameReg.playable():
                var id := String(g["id"])
                if owns_game(id):
                        game_battery(id)

## In-app "a round just became ready" ping (v0.1.2 owner rule - REPLACES the
## old pool-is-full ping: "can you update so it be batteries-for-a-round
## recharged instead?"). Cooldown keeps regen reads from spamming the sound.
func _battery_round_sfx() -> void:
        var now := int(Time.get_unix_time_from_system())
        if now - int(meta().get("batt_ping_at", 0)) < 90:
                return
        meta()["batt_ping_at"] = now
        save()
        battery_round_ready.emit()
        Notify.play_kind_sfx("battery_full")

## One round's cost on the GLOBAL side: the fattest per_round among owned
## charged games (a round spends it from the game pool AND the bank).
func _round_need() -> int:
        var need := 0
        for g in GameReg.playable():
                if not owns_game(String(g["id"])):
                        continue
                var ch: Dictionary = g.get("charges", {})
                if ch.is_empty():
                        continue
                need = maxi(need, int(ch.get("per_round", 2)))
        return need if need > 0 else 2

func _battery_notify_id(key: String) -> int:
        var h := 0
        for c in key:
                h = (h * 31 + c.unicode_at(0)) % 100000
        return 200000 + h

## Schedule "batteries full" pings for the box pool and every owned charged
## game that is not full (fired by the native alarm while the app is closed).
## Both use the "battery_full" kind -> its own Android channel + custom SFX.
func _schedule_battery_notifications() -> void:
        var gb := box_batteries()
        if gb < BOX_BATTERY_CAP:
                var secs := (BOX_BATTERY_CAP - gb) * BATTERY_STEP - int(data["box_batteries"].get("rem", 0))
                Notify.schedule(_battery_notify_id("box"), "GOGABatteries",
                        "Your GOGABatteries are fully charged - %d/%d!" % [BOX_BATTERY_CAP, BOX_BATTERY_CAP],
                        maxi(60, secs), "battery_full")
        for g in GameReg.playable():
                var id := String(g["id"])
                if not owns_game(id):
                        continue
                var b := game_battery(id)
                if b.is_empty() or int(b["count"]) >= int(b["cap"]):
                        continue
                var secs2 := (int(b["cap"]) - int(b["count"])) * int(b["step"])
                Notify.schedule(_battery_notify_id("g_" + id), "GOGABatteries",
                        "%s batteries are full - back to it!" % String(g["title"]),
                        maxi(60, secs2), "battery_full")

func _cancel_battery_notifications() -> void:
        Notify.cancel(_battery_notify_id("box"))
        for g in GameReg.playable():
                Notify.cancel(_battery_notify_id("g_" + String(g["id"])))

## Keep scheduled pings in sync after pools change while the app is open.
func _sync_battery_notifications() -> void:
        # cheap approach: cancel + reschedule only if we are not the foreground
        # payer - while open the alarms would fire inside the session, which is
        # pointless, so just cancel them; they get re-armed on the next pause.
        _cancel_battery_notifications()

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
                        "seen": false, "badge": "", "last_ts": 0,
                }
        return data["games"][id]

func stat(id: String, key: String) -> int:
        return int(_slot(id).get(key, 0))

func record_run(id: String, score: int) -> Dictionary:
        var s := _slot(id)
        s["last"] = score
        s["plays"] = int(s["plays"]) + 1
        s["last_ts"] = int(Time.get_unix_time_from_system())   # last-played lists
        var new_best := score > int(s["best"])
        if new_best:
                s["best"] = score
        save()
        return {"new_best": new_best, "best": int(s["best"])}

## Unix time of the most recent run (0 = never played).
func last_played_at(id: String) -> int:
        return int(_slot(id).get("last_ts", 0))

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
        # a game progress wipe does NOT touch the favorite mark (that is a
        # library opinion, not a run stat)
        data["games"][id] = {
                "best": 0, "last": 0, "plays": 0,
                "time": 0.0, "spent": 0, "earned": 0,
                "counters": {}, "ach": {}, "progress": {},
                "skins": {"owned": [], "on": ""},
                "seen": true, "badge": "",    # badges stay cleared across a wipe
                "last_ts": 0,
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

## How many trophies this game has granted (achievement mystery orders).
func ach_count(id: String) -> int:
        return (_slot(id)["ach"] as Dictionary).size()

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
