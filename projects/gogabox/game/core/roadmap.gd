class_name Roadmap
extends RefCounted
## The feed-reveal brain. The box does NOT show every game at once - it grows:
##
##   HIDDEN  -> not rendered at all
##   MYSTERY -> black tile "?????" (orders to complete, or a countdown)
##   GATED   -> visible + faded + lock: revealed, but you must own more games
##   SOON    -> visible workshop game: conditions met, script still baking
##   LOCKED  -> visible + purchasable with GOGACoins (+ New! badge until tapped)
##   OWNED   -> in the library
##
## Conditions are declarative in registry.gd ("reveal" dict):
##   kind: chain | orders | inbox (minutes) | real (hours)
##   appear_after: owned games needed before the teaser shows at all
##   needs_games:  owned games required to BUY once revealed
##   Order progress (spend_in / earn_in / plays / beat_best / ach_in /
##   ach_exact) is computed live from Box stats, so nothing extra to persist
##   except baselines + timestamps.

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
                return "HIDDEN" if String(rv.get("kind", "chain")) == "chain" else "MYSTERY"
        # revealed: workshop games stay SOON, real games check extra gate
        if int(rv.get("needs_games", 0)) > Box.owned_count():
                return "GATED"
        if g.get("coming_soon", false):
                return "SOON"
        return "LOCKED"

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
        return 0

static func _order_goal(o: Dictionary) -> int:
        match String(o["type"]):
                "spend_in", "earn_in": return int(o["amount"])
                "plays": return int(o["count"])
                "beat_best": return 1
                "ach_in": return int(o["count"])
                "ach_exact": return 1
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
        var gt := String(GameReg.get_game(String(o["game"])).get("title", o["game"]))
        match String(o["type"]):
                "spend_in": return "spend %d coins in %s" % [int(o["amount"]), gt]
                "earn_in": return "earn %d coins in %s" % [int(o["amount"]), gt]
                "plays": return "play %d rounds of %s" % [int(o["count"]), gt]
                "beat_best": return "beat your high score in %s" % gt
                "ach_in": return "earn %d achievements in %s" % [int(o["count"]), gt]
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
static func window_text(id: String) -> String:
        var g := GameReg.get_game(id)
        if g.has("hours"):
                return "playable %02d:00-%02d:00" % [int(g["hours"]["from"]), int(g["hours"]["to"])]
        if g.has("blocked_hours"):
                return "rests %02d:00-%02d:00" % [int(g["blocked_hours"]["from"]), int(g["blocked_hours"]["to"])]
        return ""

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
                if (prev == "HIDDEN" or prev == "MYSTERY" or prev == "GATED") \
                                and (st == "GATED" or st == "SOON" or st == "LOCKED"):
                        # a teaser just resolved into something tangible -> celebrate
                        Notify.cancel(_notify_id(id))
                        Notify.play_kind_sfx("game_ready")   # in-app ping
                        Box.reveal_changed.emit(id)
                        # ...and its badge upgrades to UNLOCKED! (green)
                        if not Box.is_seen(id):
                                Box.set_badge(id, "unlocked")
                _heal_badge(id, st)
        Box.save()

## v0.0.7 migration: saves from before the badge system have seen=false games
## sitting in visible states with no badge. Derive the level from the state
## once; tap-to-clear then works exactly like fresh badges.
static func _heal_badge(id: String, st: String) -> void:
        if Box.is_seen(id) or Box.badge(id) != "":
                return
        match st:
                "MYSTERY": Box.set_badge(id, "new")
                "LOCKED", "GATED", "SOON": Box.set_badge(id, "unlocked")

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
## day, reshuffled at midnight. v0.0.8: the pool is EVERYTHING visible in the
## box (owned + locked + gated + soon + mystery teasers) - "if someone does
## not know what to pick, they pick from here". Owned-only made the carousel
#  a one-game strip (and the arrows looked dead).
static func daily_picks() -> Array:
        var d := Time.get_date_dict_from_system()
        var seed_text := "%s-%s-%s-gogabox" % [d["year"], d["month"], d["day"]]
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(seed_text)
        var pool := []
        for g in GameReg.GAMES:
                var id := String(g["id"])
                if state(id) == "HIDDEN":
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
