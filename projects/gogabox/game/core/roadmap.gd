class_name Roadmap
extends RefCounted
## The feed-reveal brain. The box does NOT show every game at once - it grows:
##
##   HIDDEN   -> not rendered at all
##   MYSTERY  -> black tile "?????" (orders to complete, or a countdown)
##   CHARGING -> visible + faded + capacity meter: pour GOGACharges to unlock
##               the BUY (v0.1.4)
##   GATED    -> visible + faded + lock: revealed, but you must own more games
##   SOON     -> visible workshop game: conditions met, script still baking
##   LOCKED   -> visible + purchasable with GOGACoins (+ New! badge until tapped)
##   OWNED    -> in the library
##
## Conditions are declarative in registry.gd ("reveal" dict):
##   kind: chain | orders | inbox (minutes) | real (hours) | direct
##   appear_after: owned games needed before the teaser shows at all
##   needs_games:  owned games required to BUY once revealed
##   charge_unlock: GOGACharges to pour in (pre-play button) before the buy
##   Order progress (spend_in / earn_in / plays / beat_best / ach_in /
##   ach_exact / spend_charges) is computed live from Box stats.
##
## v0.1.4 THE MYSTERY QUEUE (owner brainstorm): at most MYSTERY_CAP mysteries
## exist AT ONCE. The queue is the catalog order of mystery-able teasers
## (orders / inbox / real) that are eligible (appear_after met) and not yet
## resolved - literally "a list inside the code". Everyone past the cap stays
## HIDDEN: inexistent, untracked, unrendered - until an earlier mystery
## resolves and the queue slides up one slot.

const MYSTERY_CAP := 4

# ---------------------------------------------------------------- states

static func state(id: String) -> String:
        var g := GameReg.get_game(id)
        if g.is_empty():
                return "HIDDEN"
        if Box.owns_game(id):
                return "OWNED"
        var rv: Dictionary = g.get("reveal", {})
        if rv.is_empty():
                return "LOCKED"
        # appear_after gate: teaser not even shown yet
        var after := int(rv.get("appear_after", 0))
        if after > 0 and Box.owned_count() < after:
                return "HIDDEN"
        # condition gate (orders / timers); chain games stay fully hidden
        if not _condition_done(id, rv):
                var kind := String(rv.get("kind", "chain"))
                if kind == "chain":
                        return "HIDDEN"
                # v0.1.4: past the mystery queue cap = inexistent completely
                if _mystery_rank(id) >= MYSTERY_CAP:
                        return "HIDDEN"
                return "MYSTERY"
        # revealed: the GOGACharges meter first (v0.1.4), then the games gate
        var cu := int(g.get("charge_unlock", 0))
        if cu > 0 and Box.charges_in(id) < cu:
                return "CHARGING"
        if int(rv.get("needs_games", 0)) > Box.owned_count():
                return "GATED"
        if g.get("coming_soon", false):
                return "SOON"
        return "LOCKED"

## Position of `id` in the mystery queue: the catalog order of mystery-able
## teasers (orders / inbox / real) that are eligible and still unresolved.
## The caller guarantees `id` itself is unresolved; it never counts itself.
static func _mystery_rank(id: String) -> int:
        var rank := 0
        for g in GameReg.GAMES:
                var gid := String(g["id"])
                if gid == id:
                        return rank
                var rv: Dictionary = g.get("reveal", {})
                var kind := String(rv.get("kind", ""))
                if not (kind == "orders" or kind == "inbox" or kind == "real"):
                        continue
                if Box.owns_game(gid) or _condition_done(gid, rv):
                        continue   # resolved - its queue slot is free
                var after := int(rv.get("appear_after", 0))
                if after > 0 and Box.owned_count() < after:
                        continue   # not eligible yet - takes no slot
                rank += 1
        return -1

## True once the reveal condition (not the games-owned gate) is satisfied.
static func _condition_done(id: String, rv: Dictionary) -> bool:
        match String(rv.get("kind", "chain")):
                "chain":
                        var idx := GameReg.playable_index(id)
                        if idx <= 0:
                                return true
                        var prev: Dictionary = GameReg.playable()[idx - 1]
                        var pid := String(prev["id"])
                        return Box.owns_game(pid) and Box.stat(pid, "plays") > 0
                "inbox":
                        return Box.total_time() >= float(rv.get("minutes", 30)) * 60.0
                "real":
                        var seen := _seen_at(id)
                        return seen > 0 and Time.get_unix_time_from_system() >= seen + float(rv.get("hours", 24)) * 3600.0
                "orders":
                        for o in rv.get("orders", []):
                                if int(_order_value(o)) < _order_goal(o):
                                        return false
                        return true
                "direct":
                        return true   # no conditions: appears as a locked/gated tile right away
        return true

# ---------------------------------------------------------------- orders

## Progress toward one order line.
static func _order_value(o: Dictionary) -> int:
        match String(o["type"]):
                "spend_in": return Box.spent_in(String(o["game"]))
                "earn_in": return Box.earned_in(String(o["game"]))
                "plays": return Box.stat(String(o["game"]), "plays")
                "beat_best":
                        var gid := String(o["game"])
                        var base := int(Box.get_progress("__roadmap__", "base_" + gid, 0))
                        var best := Box.stat(gid, "best")
                        return best if best > base else 0
                "ach_in": return Box.ach_count(String(o["game"]))
                "ach_exact": return 1 if Box.has_achievement(String(o["game"]), String(o["ach"])) else 0
                "spend_charges": return Box.charges_spent()   # v0.1.4
        return 0

static func _order_goal(o: Dictionary) -> int:
        match String(o["type"]):
                "spend_in", "earn_in": return int(o["amount"])
                "plays": return int(o["count"])
                "beat_best": return 1
                "ach_in": return int(o["count"])
                "ach_exact": return 1
                "spend_charges": return int(o["amount"])
        return 1

static func order_lines(id: String) -> Array:
        ## [{text, done, value, goal}]
        var rv: Dictionary = GameReg.get_game(id).get("reveal", {})
        var out := []
        for o in rv.get("orders", []):
                var v := mini(int(_order_value(o)), _order_goal(o))
                out.append({
                        "text": _order_text(o), "done": v >= _order_goal(o),
                        "value": v, "goal": _order_goal(o),
                })
        return out

static func _order_text(o: Dictionary) -> String:
        match String(o["type"]):
                "spend_charges":
                        return "spend %d GOGACharges" % int(o["amount"])
        var gt := String(GameReg.get_game(String(o.get("game", ""))).get("title", o.get("game", "")))
        match String(o["type"]):
                "spend_in": return "spend %d coins in %s" % [int(o["amount"]), gt]
                "earn_in": return "earn %d coins in %s" % [int(o["amount"]), gt]
                "plays": return "play %d rounds of %s" % [int(o["count"]), gt]
                "beat_best": return "beat your high score in %s" % gt
                "ach_in": return "earn %d achievements in %s" % [int(o["count"]), gt]
                "spend_charges": return "spend %d GOGACharges" % int(o["amount"])
                "ach_exact":
                        var title := String(o["ach"])
                        for a in GameReg.get_game(String(o["game"])).get("ach", []):
                                if String(a["id"]) == String(o["ach"]):
                                        title = String(a["title"])
                        return "unlock the '%s' trophy in %s" % [title, gt]
        return "??"

## Seconds left on a timed mystery (0 when not timed / already done).
static func time_left(id: String) -> float:
        var rv: Dictionary = GameReg.get_game(id).get("reveal", {})
        if String(rv.get("kind", "")) != "real":
                return 0.0
        var seen := _seen_at(id)
        if seen <= 0:
                return float(rv.get("hours", 24)) * 3600.0
        return maxf(0.0, seen + float(rv.get("hours", 24)) * 3600.0 - Time.get_unix_time_from_system())

static func inbox_left(id: String) -> float:
        var rv: Dictionary = GameReg.get_game(id).get("reveal", {})
        if String(rv.get("kind", "")) != "inbox":
                return 0.0
        return maxf(0.0, float(rv.get("minutes", 30)) * 60.0 - Box.total_time())

## THE one playability answer (v0.1.1): entry fee vs wallet, BOTH battery
## pools (a charged round drinks from the game pool AND the box bank), the
## time-of-day window, and the DAILY limits (v0.1.4). The pre-play page's
## PLAY button and the feed's "ready to play" chip both read THIS, so the
## chip can never promise a button that won't open (and the button can never
## ignore a dry box bank - that mismatch shipped in v0.0.9..v0.1.0).
static func can_play_now(id: String) -> bool:
        var g := GameReg.get_game(id)
        if g.is_empty() or g.get("coming_soon", false) or not Box.owns_game(id):
                return false
        if not window_ok(id):
                return false
        # v0.1.4: a reached daily cap (rounds or playtime) blocks play
        if not Box.daily_ok(id):
                return false
        var fee := int(g.get("fee", 0))
        # v0.1.4 snake partial-pay: the starter is playable at ANY wallet -
        # a thin wallet just pays every coin it has. v0.1.5: read as the
        # registry's shared entry policy (Box.pays_partial_fee), so any
        # future game wearing the key behaves identically.
        var can_pay := fee <= 0 or Box.pays_partial_fee(id) or Box.coins() >= fee
        if not can_pay:
                return false
        var b := Box.game_battery(id)
        if not b.is_empty():
                var need := int(b["per_round"])
                if int(b["count"]) < need or Box.box_batteries() < need:
                        return false
        return true

# ------------------------------------------------------- play-time windows

## Inside a "from".."to" local-hour window (wrap-safe).
static func _hour_in(h: int, from_h: int, to_h: int) -> bool:
        if from_h == to_h:
                return true
        if from_h < to_h:
                return h >= from_h and h < to_h
        return h >= from_h or h < to_h   # overnight window

## Can this game be played RIGHT NOW (time-of-day rules)?
static func window_ok(id: String) -> bool:
        var g := GameReg.get_game(id)
        var h := int(Time.get_time_dict_from_system()["hour"])
        if g.has("hours"):
                if not _hour_in(h, int(g["hours"]["from"]), int(g["hours"]["to"])):
                        return false
        if g.has("blocked_hours"):
                if _hour_in(h, int(g["blocked_hours"]["from"]), int(g["blocked_hours"]["to"])):
                        return false
        return true

## Human hint for the restriction ("" when the game has none).
## v0.1.4: AM/PM wording (owner: "shows unlocks at nn AM/PM").
static func window_text(id: String) -> String:
        var g := GameReg.get_game(id)
        if g.has("hours"):
                return "playable %s - %s" % [fmt_hour(int(g["hours"]["from"])),
                                fmt_hour(int(g["hours"]["to"]))]
        if g.has("blocked_hours"):
                return "rests %s - %s" % [fmt_hour(int(g["blocked_hours"]["from"])),
                                fmt_hour(int(g["blocked_hours"]["to"]))]
        return ""

## v0.1.4 LIVE WINDOW STATE: unix time of the moment this game's time window
## next opens (0 = playable right now / no window rules). The pre-play page
## prints "unlocks at %s" from it and re-checks it every second.
static func next_unlock_at(id: String) -> int:
        if window_ok(id):
                return 0
        var g := GameReg.get_game(id)
        var target := -1
        if g.has("hours"):
                target = int(g["hours"]["from"])
        elif g.has("blocked_hours"):
                target = int(g["blocked_hours"]["to"])
        if target < 0:
                return 0
        var t := Time.get_time_dict_from_system()
        var now_secs := int(t["hour"]) * 3600 + int(t["minute"]) * 60 + int(t["second"])
        var wait := target * 3600 - now_secs
        if wait <= 0:
                wait += 86400   # that hour already passed today -> tomorrow
        return int(Time.get_unix_time_from_system()) + wait

## 24h -> "12 AM" / "1 PM" / "4 PM" (owner wording: "nn AM/PM").
static func fmt_hour(h: int) -> String:
        var hh := ((h % 24) + 24) % 24
        var disp := hh % 12
        if disp == 0:
                disp = 12
        return "%d %s" % [disp, "AM" if hh < 12 else "PM"]

## v0.1.4 THE DAILY LIMIT LINE for the pre-play page ("" = no caps):
## "today 2/6 rounds - 9/15 min". Live: the playtime half ticks with play.
static func daily_text(id: String) -> String:
        var u := Box.daily_usage(id)
        var parts := []
        if int(u["rounds_cap"]) > 0:
                parts.append("%d/%d rounds" % [int(u["rounds"]), int(u["rounds_cap"])])
        if int(u["mins_cap"]) > 0:
                parts.append("%d/%d min" % [int(float(u["secs"]) / 60.0), int(u["mins_cap"])])
        return " - ".join(parts)

# ------------------------------------------------------------ bookkeeping

static func _seen_at(id: String) -> int:
        return int(Box.meta().get("seen_at_" + id, 0))

## Evaluate every game, persist transitions, fire notifications.
## Call on menu refresh + a slow timer + after runs/unlocks.
static func tick() -> void:
        var now := int(Time.get_unix_time_from_system())
        for g in GameReg.GAMES:
                var id := String(g["id"])
                var st := state(id)
                var key := "state_" + id
                var prev := String(Box.meta().get(key, ""))
                if st == prev:
                        _heal_badge(id, st)     # v0.0.7: self-heal old saves
                        continue
                Box.meta()[key] = st
                if prev == "" or (prev == "HIDDEN" and st != "HIDDEN"):
                        # first time this teaser is visible: stamp time, baseline orders
                        if st == "MYSTERY":
                                Box.meta()["seen_at_" + id] = now
                                _stamp_order_baselines(id)
                                _schedule_reveal_notification(id, g)
                        # v0.0.7 two-level badge: first appearance = NEW!
                        # (OWNED games never badge - the starter must not wear
                        # a permanent ribbon)
                        if st != "OWNED" and not Box.is_seen(id) and Box.badge(id) == "":
                                Box.set_badge(id, "new")
                # "" counts as a fresh save seeing the teaser resolve directly
                # (e.g. save-meta wipe): the upgrade must still land.
                # v0.1.4: CHARGING -> GATED/SOON/LOCKED also celebrates (the
                # capacity meter just filled).
                if (prev == "" or prev == "HIDDEN" or prev == "MYSTERY" or prev == "GATED" \
                                or prev == "CHARGING") \
                                and (st == "GATED" or st == "SOON" or st == "LOCKED"):
                        # a teaser just resolved into something tangible -> celebrate
                        Notify.cancel(_notify_id(id))
                        Notify.play_kind_sfx("game_ready")   # in-app ping
                        Box.reveal_changed.emit(id)
                        # v0.0.9 owner rule: the green UNLOCKED! badge belongs to
                        # BUYABLE tiles ONLY (it used to smear onto gated/soon
                        # tiles - "unlock badge appears to whatever game appears")
                        if st == "LOCKED" and not Box.is_seen(id):
                                Box.set_badge(id, "unlocked")
                _heal_badge(id, st)
        Box.save()

## v0.0.7 migration: saves from before the badge system have seen=false games
## sitting in visible states with no badge. Derive the level from the state
## once; tap-to-clear then works exactly like fresh badges.
## v0.0.9 rule set: NEW! = "this tile just appeared" (any teaser state);
## UNLOCKED! = "this tile is buyable" (LOCKED only).
static func _heal_badge(id: String, st: String) -> void:
        if Box.is_seen(id) or Box.badge(id) != "":
                return
        match st:
                "MYSTERY", "GATED", "SOON", "CHARGING": Box.set_badge(id, "new")
                "LOCKED": Box.set_badge(id, "unlocked")

## Baselines are already stamped when a teaser first appears; nothing to do
## for ach_in / ach_exact (they read live trophy counts).
static func _stamp_order_baselines(id: String) -> void:
        var rv: Dictionary = GameReg.get_game(id).get("reveal", {})
        for o in rv.get("orders", []):
                if String(o["type"]) != "beat_best":
                        continue
                var gid := String(o["game"])
                var key := "base_" + gid
                if int(Box.get_progress("__roadmap__", key, -1)) < 0:
                        Box.set_progress("__roadmap__", key, Box.stat(gid, "best"))

static func _notify_id(id: String) -> int:
        # stable small ints for the native alarm manager
        var h := 0
        for c in id:
                h = (h * 31 + c.unicode_at(0)) % 100000
        return 1000 + h

static func _schedule_reveal_notification(id: String, g: Dictionary) -> void:
        var rv: Dictionary = g.get("reveal", {})
        if String(rv.get("kind", "")) != "real":
                return
        var delay := float(rv.get("hours", 24)) * 3600.0
        Notify.schedule(_notify_id(id), "GOGABox",
                        "%s finished baking in the workshop - come see!" % String(g["title"]),
                        int(delay), "game_ready")

# ------------------------------------------------------------ daily picks

## The feed has no real "hot" metric (everything is local), so the owner
## redefined it: up to 5 games picked by a daily seed - the same handful all
## day, reshuffled at midnight. v0.0.9 owner rule: the picks pool is OWNED
## games only - mystery boxes in "today's picks" read as a joke ("kind of
## funny but wrong"), and the strip must suggest what to PLAY tonight.
static func daily_picks() -> Array:
        var d := Time.get_date_dict_from_system()
        var seed_text := "%s-%s-%s-gogabox" % [d["year"], d["month"], d["day"]]
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(seed_text)
        var pool := []
        for g in GameReg.GAMES:
                if not Box.owns_game(String(g["id"])):
                        continue
                pool.append(g)
        # Fisher-Yates with the day's rng
        for i in range(pool.size() - 1, 0, -1):
                var j := rng.randi_range(0, i)
                var tmp = pool[i]
                pool[i] = pool[j]
                pool[j] = tmp
        return pool.slice(0, mini(5, pool.size()))

# ------------------------------------------------------------------ format

## v0.1.1 THE OWNER FEED ORDER (replaces raw registry order, which interleaved
## states "uncannily" - an owned game buried between black boxes): OWNED
## games first (oldest unlock first - the save's owned[] append order), then
## the revealed charging/locked/gated/soon tiles (catalog order = the box's
## growth order), then the mysteries (catalog order). HIDDEN games never
## appear. [ {g, st, bucket, ord} ]
static func feed_rows() -> Array:
        var owned_idx := {}
        var i := 0
        for oid in (Box.data["owned"] as Array):
                owned_idx[String(oid)] = i
                i += 1
        var reg_idx := {}
        for k in GameReg.GAMES.size():
                reg_idx[String(GameReg.GAMES[k]["id"])] = k
        var rows: Array = []
        for g in GameReg.GAMES:
                var id := String(g["id"])
                var st := state(id)
                if st == "HIDDEN":
                        continue
                var bucket := 0 if st == "OWNED" else (2 if st == "MYSTERY" else 1)
                var ord := int(owned_idx.get(id, 100000)) if bucket == 0 \
                                else int(reg_idx.get(id, 100000))
                rows.append({"g": g, "st": st, "bucket": bucket, "ord": ord})
        rows.sort_custom(func(a, b):
                if int(a["bucket"]) != int(b["bucket"]):
                        return int(a["bucket"]) < int(b["bucket"])
                return int(a["ord"]) < int(b["ord"]))
        return rows

static func fmt_clock(seconds: float) -> String:
        var s := int(maxf(0.0, seconds))
        if s >= 86400:
                return "%dd %dh" % [s / 86400, (s % 86400) / 3600]
        if s >= 3600:
                return "%dh %dm" % [s / 3600, (s % 3600) / 60]
        return "%dm %02ds" % [s / 60, s % 60]

static func fmt_time(seconds: float) -> String:
        var s := int(seconds)
        return "%d:%02d" % [s / 60, s % 60]
