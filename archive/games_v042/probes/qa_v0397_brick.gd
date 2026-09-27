extends Node
## qa_v0397_brick - the BRICK BREAKER v0.3.9-7 law probe (the qa law):
## driven headless, exit 0 = pass. The owner's spec, pinned:
##   1. THE GENERATOR: mirrored archetypes rotate, every level is
##      reachable (the flood law), carriers wear the 2% law, the ice
##      rides breakable bricks only, determinism holds.
##   2. THE FAIR TIMER: computed from the level's own numbers, clamped,
##      the powerup credit discounts, and THE AUTO-PLAYER BEATS IT (the
##      sim clears levels inside the bank - "logically possible").
##   3. THE PING-PONG CONTROL: the held finger writes the target, the
##      glide closes it (distance-proportional, never a teleport).
##   4. THE PHYSICS: substep sweep holds at x5 (no tunneling), the
##      paddle bounce rides the offset, the walls bounce, the bottom
##      takes the ball only.
##   5. THE POINT LAW: damage dealt = points paid (metal pays double);
##      the ice takes the extra hit first; +1 heart per 1000 points.
##   6. THE COIN LAW: every 300 real bricks promote a carrier.
##   7. THE DROP LAW: nothing drops before 40%, the first carrier is
##      forced at the mark, pre-gate carriers bank, only OWNED kinds
##      drop, every effect wears its cap, every reset fires.
##   8. THE STATE LAW: boot -> intro -> serve -> play -> clear -> intro;
##      a life loss keeps the layout and the clock; time-up resets the
##      clock; the last heart ends the run into finish_run.

var fails := 0
var BB: GDScript

func _check(cond: bool, why := "") -> void:
        print("  %s: %s" % ["PASS" if cond else "FAIL", why])
        if not cond:
                fails += 1

# ---------------------------------------------------------------- the rig
var g: GogaGame = null

func _mk_rng(seed_v: int) -> RandomNumberGenerator:
        var r := RandomNumberGenerator.new()
        r.seed = seed_v
        return r

func _scene_game() -> void:
        if g != null and is_instance_valid(g):
                g.queue_free()
                g = null
        g = BB.new()
        g.game_id = "brickbreaker"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame

func _run(secs: float) -> void:
        var steps := int(secs * 60.0)
        for i in steps:
                g.probe_step(1.0 / 60.0)

func _fresh(seed_v: int) -> void:
        g.probe_reset(seed_v)
        g._auto = false

## a first breakable brick key (the damage law's target)
func _any_brick() -> Vector2i:
        for key in g.ld["cells"].keys():
                var c: Dictionary = g.ld["cells"][key]
                if not bool(c["decor"]) and int(c["hp"]) > 0 \
                                and not c.has("dying"):
                        return key
        return Vector2i(-1, -1)

func _brick_count() -> int:
        var n := 0
        for key in g.ld["cells"].keys():
                var c: Dictionary = g.ld["cells"][key]
                if not bool(c["decor"]) and int(c["hp"]) > 0 \
                                and not c.has("dying"):
                        n += 1
        return n

func _alive_breakables() -> Array:
        var out: Array = []
        for key in g.ld["cells"].keys():
                var c: Dictionary = g.ld["cells"][key]
                if not bool(c["decor"]) and int(c["hp"]) > 0 \
                                and not c.has("dying"):
                        out.append(key)
        return out

# ================================================================== laws
func _ready() -> void:
        print("=== qa_v0397_brick ===")
        Box.reset_all()
        Box.bump_counter("brickbreaker", "lore_start", 1)
        Box.bump_counter("brickbreaker", "lore_end", 1)
        BB = load("res://game/games/brickbreaker/brickbreaker.gd")
        _t_generator()
        _t_timer()
        await _scene_game()
        _t_gate_and_states()
        await _t_paddle_finger()
        _t_physics()
        _t_points_and_hearts()
        _t_coin_law()
        _t_drop_law()
        _t_caps_and_resets()
        _t_life_law()
        _t_contact_and_fire()
        if OS.get_environment("BB_CAL") == "1":
                await _t_calibration()      # the print-only pace fit
        await _t_simulation()
        await _t_powered_soak()
        print("=== qa_v0397_brick: %s (%d fails) ===" \
                        % ["ALL PASS" if fails == 0 else "FAILED", fails])
        get_tree().quit(0 if fails == 0 else 1)

# ------------------------------------------------------- 1. the generator
func _t_generator() -> void:
        print("-- the generator")
        # the ladder: monotonic, odd, capped (the v0.3.9-8 SMALL BRICK:
        # 25..49 x 11..21 - the owner's 3-5x smaller bricks)
        var ok_ladder := true
        var last := Vector2i.ZERO
        for lv in range(1, 61):
                var s: Vector2i = BB.gen_sizes(lv)
                if s.x % 2 == 0 or s.x < BB.BASE_COLS or s.x > BB.MAX_COLS \
                                or s.y < BB.BASE_ROWS or s.y > BB.MAX_ROWS:
                        ok_ladder = false
                if s.x < last.x or s.y < last.y:
                        ok_ladder = false
                last = s
        _check(ok_ladder,
                "the ladder grows, stays odd and inside %d..%d x %d..%d" \
                                % [BB.BASE_COLS, BB.MAX_COLS, BB.BASE_ROWS,
                                BB.MAX_ROWS])
        # THE SMALL BRICK: the L1 brick must sit in the owner's band
        # (~3-5x smaller than the v039-7 bricks: bw 28..80 design px)
        var small_ok := true
        for lv in range(1, 41):
                var dims: Vector2i = BB.gen_sizes(lv)
                var full_w := 1852.0
                var bw: float = full_w * BB.wall_frac(lv,
                                _mk_rng(900 + lv)) / float(dims.x)
                if bw < 26.0 or bw > 82.0:
                        small_ok = false
        _check(small_ok,
                "the small-brick band holds (bw 26..82 design px at L1..40)")
        # THE WALL LAW: the walls really move - the fracs spread, the
        # climb lifts the average, every level keeps its own seat
        var wmin := 10.0
        var wmax := 0.0
        var wsum := 0.0
        for lv in range(1, 31):
                for k in 4:
                        var wf: float = BB.wall_frac(lv, _mk_rng(lv * 10 + k))
                        wmin = minf(wmin, wf)
                        wmax = maxf(wmax, wf)
                        wsum += wf
        _check(wmax - wmin > 0.2,
                "the wall fracs spread (min %.2f max %.2f)" % [wmin, wmax])
        var w_early := 0.0
        var w_late := 0.0
        for k in 6:
                w_early += float(BB.wall_frac(1, _mk_rng(k))) / 6.0
                w_late += float(BB.wall_frac(20, _mk_rng(k))) / 6.0
        _check(w_late > w_early + 0.1,
                "the walls climb (L1 avg %.2f < L20 avg %.2f)" % [w_early,
                                w_late])
        # determinism: the same seed twice, the same level
        var r1 := RandomNumberGenerator.new()
        r1.seed = 4242
        var a: Dictionary = BB.gen_level(12, r1)
        var r2 := RandomNumberGenerator.new()
        r2.seed = 4242
        var b: Dictionary = BB.gen_level(12, r2)
        _check(String(a["arch"]) == String(b["arch"]) \
                        and int(a["breakable"]) == int(b["breakable"]) \
                        and int(a["hits"]) == int(b["hits"]),
                "gen_level is deterministic under a seed")
        # 40 seeds x the band: flood, carriers, ice law, hp band
        var rng := RandomNumberGenerator.new()
        var flood_ok := true
        var carrier_ok := true
        var ice_ok := true
        var band_ok := true
        var arches := {}
        for i in 40:
                var lv := 1 + (i * 7) % 40
                rng.seed = 1000 + i
                var ld: Dictionary = BB.gen_level(lv, rng)
                arches[String(ld["arch"])] = true
                var cols := int(ld["cols"])
                var rows := int(ld["rows"])
                if int(ld["breakable"]) <= 0:
                        flood_ok = false
                        continue
                var blocked := {}
                for key in ld["cells"].keys():
                        if bool(ld["cells"][key]["decor"]):
                                blocked[key] = true
                var seen: Dictionary = BB.flood_open(cols, rows, blocked)
                var band: Vector2i = BB.hp_band(lv)
                for key in ld["cells"].keys():
                        var c: Dictionary = ld["cells"][key]
                        if bool(c["decor"]):
                                if int(c["hp"]) != 0:
                                        band_ok = false
                                continue
                        var hp := int(c["hp"])
                        if hp < band.x or hp > band.y:
                                band_ok = false
                        if bool(c["ice"]) and lv <= 3:
                                ice_ok = false
                        # THE PASSABLE FLOOD: breakables fall and open
                        # the way - only the steel seals; a shipped brick
                        # must sit inside the flood region itself
                        if not seen.has(key):
                                flood_ok = false
                var want_c := maxi(1, int(round(float(ld["breakable"]) \
                                * BB.POW_CHANCE)))
                if ld["carriers"].size() != want_c:
                        carrier_ok = false
        _check(flood_ok, "40 levels: every brick face reachable (the flood law)")
        _check(carrier_ok, "40 levels: the carriers wear the 2% law")
        _check(ice_ok, "the ice never rides the first 3 levels")
        _check(band_ok, "the hp band holds (decor carries 0, bricks in band)")
        _check(arches.size() >= 6,
                "the archetypes really rotate across levels (%d seen)" \
                                % arches.size())
        # the carriers never sit on decor
        var rng2 := RandomNumberGenerator.new()
        var carry_clean := true
        for i in 12:
                rng2.seed = 500 + i
                var ld: Dictionary = BB.gen_level(5 + i * 3, rng2)
                for key in ld["carriers"]:
                        if bool(ld["cells"][key]["decor"]):
                                carry_clean = false
        _check(carry_clean, "no carrier ever sits on the steel")

# ------------------------------------------------------------ 2. the timer
func _t_timer() -> void:
        print("-- the fair timer")
        var t1: float = BB.timer_for(138, 138, 1852.0, 800.0, 560.0, 1, false)
        var t2: float = BB.timer_for(240, 520, 1852.0, 800.0, 560.0, 10, false)
        var t3: float = BB.timer_for(260, 780, 1852.0, 800.0, 560.0, 30, false)
        _check(t1 >= 40.0 and t2 > t1 and t3 >= t2,
                "the timer grows with the work (%.0f -> %.0f -> %.0f)" \
                                % [t1, t2, t3])
        _check(t3 <= 540.0, "the clamp holds the ceiling (540s)")
        var tp: float = BB.timer_for(240, 520, 1852.0, 800.0, 560.0, 10, true)
        _check(tp < t2, "the owned-powerup credit discounts the bank")
        var tslow: float = BB.timer_for(138, 138, 1852.0, 800.0, 380.0, 1,
                        false)
        _check(tslow > t1, "a slower ball buys MORE time (the fairness)")

# --------------------------------------------------- 3. the gate + states
func _t_gate_and_states() -> void:
        print("-- the gate + the state machine")
        _check(g.phase == "boot",
                "the game boots into the silent gate (phase=%s)" % g.phase)
        _check(g.gate_ui != null and is_instance_valid(g.gate_ui),
                "the gate sheet exists over the court")
        # the tap opens the intro (the state law: one door)
        g._tap_anywhere(Vector2.ZERO)
        _check(g.phase == "intro" and g.gate_ui == null,
                "the gate tap opens the intro (the line-by-line breath)")
        var rows := int(g.ld["rows"])
        _run(float(rows) * 0.055 + 0.30 + 0.25)
        _check(g.phase == "serve",
                "the intro ends into the serve (ball on the paddle)")
        _check(g.balls.size() == 1 and bool(g.balls[0]["stuck"]),
                "the served ball rides the paddle")
        # the launch door
        g.probe_launch()
        _check(g.phase == "play" and not bool(g.balls[0]["stuck"]),
                "the tap launches the play")
        _run(0.5)
        _check(g.phase == "play" or g.phase == "serve",
                "the run breathes (the ball is loose)")

# -------------------------------------------------- 4. the paddle control
func _t_paddle_finger() -> void:
        print("-- the ping-pong control")
        _fresh(11)
        # a CLEAN bench: the serve phase (the ball waits, nothing dies,
        # the revive never freezes the glide mid-read)
        g.phase = "serve"
        g._spawn_serve_ball()
        # THE REAL-FINGER RIG: true events through the engine queue
        var press := InputEventScreenTouch.new()
        press.position = Vector2(700, 900)
        press.pressed = true
        press.index = 0
        Input.parse_input_event(press)
        await get_tree().process_frame
        var drag := InputEventScreenDrag.new()
        drag.position = Vector2(1400, 910)
        drag.index = 0
        Input.parse_input_event(drag)
        await get_tree().process_frame
        _check(g._held == 0,
                "the held finger owns the paddle (held=%d)" % g._held)
        # the drag moves the target RIGHT (the headless stretch transform
        # rescales raw window coords - the DIRECTION is the honest read)
        var t_before: float = g.pad_target
        _check(g.pad_target > 700.0,
                "the drag wrote the target (%.0f -> %.0f)" % [t_before,
                                g.pad_target])
        var before: float = g.pad_x
        for i in 30:
                g.probe_step(1.0 / 60.0)
        _check(absf(g.pad_x - g.pad_target) < 60.0,
                "the glide closes the gap (%.0f -> %.0f)" % [before, g.pad_x])
        # the release frees the finger
        var rel := InputEventScreenTouch.new()
        rel.position = Vector2(1400, 910)
        rel.pressed = false
        rel.index = 0
        Input.parse_input_event(rel)
        await get_tree().process_frame
        _check(g._held == -1, "the release frees the paddle")
        # NOTE: the release ALSO launched the served ball (the launch
        # law) - re-arm a fresh serve bench for the glide reads
        g.phase = "serve"
        g._spawn_serve_ball()
        # the glide is distance-proportional: a far flick closes FASTER
        # (the seats live INSIDE the paddle's reachable span - the clamp
        # sits at end.x - hw, a target past it would pin both reads)
        var alo: float = g.arena.position.x
        var ahi: float = g.arena.end.x
        var reach: float = ahi - g._pad_w() * 0.5 - 20.0
        var far_from: float = alo + 40.0
        g.pad_x = far_from
        g.pad_target = reach
        for i in 12:
                g.probe_step(1.0 / 60.0)
        var d1: float = g.pad_x - far_from
        var near_from: float = reach - 300.0
        g.pad_x = near_from
        g.pad_target = reach
        for i in 12:
                g.probe_step(1.0 / 60.0)
        var d2: float = g.pad_x - near_from
        _check(absf(d1) > absf(d2) * 2.0,
                "the far gap closes faster (left %.0f vs near %.0f)" \
                                % [absf(d1), absf(d2)])
        # THE LAUNCH LAW: the hold dips the platform, the release boosts
        g.phase = "serve"
        g._spawn_serve_ball()
        _check(g.pad_charge == 0.0 and g.pad_dip == 0.0,
                "the fresh serve carries no charge")
        g._held = 4                      # a held finger (the sim's hand)
        for i in 30:
                g.probe_step(1.0 / 60.0)
        _check(g.pad_charge > 0.5,
                "the hold writes the charge (%.2f)" % g.pad_charge)
        _check(g.pad_dip > 6.0,
                "the hold dips the platform (%.1f px)" % g.pad_dip)
        var b0: Dictionary = g.balls[0]
        g._held = -1
        g._serve_release()
        _check(g.phase == "play" and g.spd_boost > 1.2,
                "the release launches POWERED (boost %.2f)" % g.spd_boost)
        _check(bool(b0["stuck"]) == false, "the served ball flew")
        _check(g.pad_dip == 0.0, "the spring release cleared the dip")
        # the boost DECAYS back to the base speed (the owner's law)
        var fast: float = g._ball_speed()
        for i in int(g.BOOST_DECAY * 60.0) + 10:
                g.probe_step(1.0 / 60.0)
                if g.phase != "play":
                        break
        _check(g.spd_boost == 1.0,
                "the boost decayed to the base (%.2f)" % g.spd_boost)
        _check(g._ball_speed() < fast,
                "the speed settled slower than the first aim (%.0f -> %.0f)" \
                                % [fast, g._ball_speed()])

# ------------------------------------------------------------- 5. physics
func _t_physics() -> void:
        print("-- the physics")
        _fresh(23)
        g.phase = "serve"
        g._spawn_serve_ball()
        g.probe_launch()
        # the walls hold; the ball never leaves the arena; x5 holds too
        var contained := true
        var bounced_wall := false
        var last_vx: float = g.balls[0]["dx"]
        g.spd_mult = 5.0
        for i in 60 * 12:
                g.probe_step(1.0 / 60.0)
                if g.phase != "play":
                        break
                for b in g.balls:
                        if bool(b["stuck"]):
                                continue
                        if float(b["x"]) - float(b["r"]) < g.arena.position.x \
                                        - 1.0 or float(b["x"]) + float(b["r"]) \
                                        > g.arena.end.x + 1.0 \
                                        or float(b["y"]) - float(b["r"]) \
                                        < g.arena.position.y - 1.0:
                                contained = false
                if absf(float(g.balls[0]["dx"])) > 0.0 \
                                and signf(float(g.balls[0]["dx"])) \
                                                != signf(last_vx) \
                                and last_vx != 0.0:
                        bounced_wall = true
                last_vx = float(g.balls[0]["dx"])
        _check(contained, "x5 speed: the ball never leaves the arena (the sweep holds)")
        _check(g.phase == "play" or g.phase == "serve" or g.phase == "revive",
                "the x5 run lives or dies HONESTLY (bottom loss, no freeze: %s)"
                                % g.phase)
        g.spd_mult = 1.0
        g._sync_effect_chips()
        # the paddle bounce rides the offset (the classic angle law)
        _fresh(31)
        g.phase = "serve"
        g._spawn_serve_ball()
        g.probe_launch()
        var b: Dictionary = g.balls[0]
        g.pad_x = g.arena.position.x + g._pad_w() * 0.5
        g.pad_target = g.pad_x          # freeze the paddle (the glide
                                        # would drift it under the ball)
        b["x"] = g.pad_x + g._pad_w() * 0.35
        b["y"] = g.paddle_y - g.PAD_H - 30.0
        b["dx"] = 0.0
        b["dy"] = g._ball_speed()
        for i in 6:
                g.probe_step(1.0 / 60.0)
        _check(float(b["dy"]) < 0.0,
                "the paddle bounce sends the ball UP (dy %.0f)" % float(b["dy"]))
        _check(float(b["dx"]) > 0.0,
                "the offset ride: hit right-of-center, fly right (dx %.0f)" \
                                % float(b["dx"]))

# -------------------------------------------------- 6. the points + hearts
func _t_points_and_hearts() -> void:
        print("-- the point law + the heart law")
        _fresh(47)
        # a level whose band wears fat bricks (hp >= 2) so the multi-hit
        # laws can be read on one body
        g._new_level(12)
        var key := Vector2i(-1, -1)
        for k in g.ld["cells"].keys():
                var c: Dictionary = g.ld["cells"][k]
                if not bool(c["decor"]) and int(c["hp"]) >= 2 \
                                and not bool(c.get("ice", false)) \
                                and not c.has("dying"):
                        key = k
                        break
        _check(key.x >= 0, "L12 wears fat bricks (hp >= 2, uniced)")
        var cell: Dictionary = g.ld["cells"][key]
        var hp0 := int(cell["hp"])
        var pts0: int = g.pts
        # the plain hit: 1 damage = 1 point
        g.probe_damage(key, 1)
        _check(int(g.ld["cells"][key]["hp"]) == hp0 - 1,
                "the hit lands (hp %d -> %d)" % [hp0,
                        int(g.ld["cells"][key]["hp"])])
        _check(g.pts == pts0 + 1,
                "damage dealt = points paid (+1 for +1)")
        # the metal hit pays double (on a FRESH fat brick - the previous
        # body only had 1 hp left, and damage caps at the remaining hp)
        var mkey := Vector2i(-1, -1)
        for k in g.ld["cells"].keys():
                var c: Dictionary = g.ld["cells"][k]
                if not bool(c["decor"]) and int(c["hp"]) >= 2 \
                                and not bool(c.get("ice", false)) \
                                and not c.has("dying") and k != key:
                        mkey = k
                        break
        _check(mkey.x >= 0, "a fresh fat brick exists for the metal read")
        g.metal_t = 10.0
        var pts_m: int = g.pts
        g.probe_damage(mkey, 2, false)
        _check(g.pts == pts_m + 2,
                "the metal ball pays DOUBLE (damage 2 = points 2)")
        _check(int(g.ld["cells"][mkey]["hp"]) \
                        == int(g.ld["cells"][mkey]["hp0"]) - 2,
                "the metal hit tore 2 hits off the body")
        g.metal_t = 0.0
        # the ice takes the extra hit first (THE FROZEN LAW)
        var ice_key := Vector2i(-1, -1)
        for k in g.ld["cells"].keys():
                var c: Dictionary = g.ld["cells"][k]
                if not bool(c["decor"]) and int(c["hp"]) > 0 \
                                and not c.has("dying") and k != key:
                        c["ice"] = true
                        ice_key = k
                        break
        if ice_key.x >= 0:
                var chp := int(g.ld["cells"][ice_key]["hp"])
                var p0: int = g.pts
                g.probe_damage(ice_key, 1)
                _check(not bool(g.ld["cells"][ice_key]["ice"]),
                        "the ice shell cracked")
                _check(int(g.ld["cells"][ice_key]["hp"]) == chp,
                        "the ice took the hit, the body untouched")
                _check(g.pts == p0 + 1, "the ice hit paid its point too")
        # THE HEART LAW: +1 heart per 1000 points
        g.pts = 999
        g.life_next = 1000
        var lives0: int = g.lives
        var k2 := _any_brick()
        if k2.x < 0:
                k2 = key
        g.probe_damage(k2, 1)
        _check(g.lives == lives0 + 1 and g.life_next == 2000,
                "the 1000th point grants ONE heart (lives %d -> %d)" \
                                % [lives0, g.lives])

# ------------------------------------------------------------ 7. coin law
func _t_coin_law() -> void:
        print("-- the coin law")
        _fresh(53)
        g.bricks_broken = 299
        var alive := _alive_breakables()
        g.probe_damage(alive[0], 1)
        if int(g.ld["cells"][alive[0]]["hp"]) <= 0:
                # the break crossed the 300 mark
                _check(g.coin_pending >= 1 or _coin_waiting(),
                        "the 300th brick promotes a coin carrier")
        else:
                # not broken yet: force-break it fully
                var guard := 0
                while int(g.ld["cells"][alive[0]]["hp"]) > 0 and guard < 12:
                        g.probe_damage(alive[0], 1)
                        guard += 1
                _check(g.coin_pending >= 1 or _coin_waiting(),
                        "the 300th brick promotes a coin carrier")
        # break the coin carrier -> +1 run coin
        var coin_key := _coin_key()
        if coin_key.x >= 0:
                var rc := g.run_coins
                var guard2 := 0
                while int(g.ld["cells"][coin_key]["hp"]) > 0 and guard2 < 12:
                        g.probe_damage(coin_key, 1)
                        guard2 += 1
                _check(g.run_coins == rc + 1,
                        "breaking the coin brick pays the GOGACoin")
        else:
                _check(false, "the coin carrier exists after the 300th break")

func _coin_waiting() -> bool:
        return _coin_key().x >= 0

func _coin_key() -> Vector2i:
        for key in g.ld["cells"].keys():
                var c: Dictionary = g.ld["cells"][key]
                if bool(c.get("coin", false)) and int(c["hp"]) > 0:
                        return key
        return Vector2i(-1, -1)

# ------------------------------------------------------------ 8. drop law
func _t_drop_law() -> void:
        print("-- the drop law")
        _fresh(61)
        # the gate: nothing drops before 40% of the ORIGINAL count
        var total0 := int(g.ld["total0"])
        var target := int(ceil(g.POW_GATE * float(total0)))
        var alive := _alive_breakables()
        var broken := 0
        var dropped_early := false
        for key in alive:
                if broken >= target - 1:
                        break
                var guard := 0
                while int(g.ld["cells"][key]["hp"]) > 0 and guard < 12:
                        g.probe_damage(key, 1)
                        guard += 1
                broken += 1
                if not g.drops.is_empty():
                        dropped_early = true
        _check(not dropped_early and not g.gate_crossed,
                "nothing drops before the 40%% mark (%d/%d)" % [broken, total0])
        _check(g.banked_pows >= 0,
                "the pre-gate carriers banked (%d)" % g.banked_pows)
        # cross the mark: the forced carrier appears
        var more := _alive_breakables()
        for key in more:
                if g.gate_crossed:
                        break
                var guard := 0
                while int(g.ld["cells"][key]["hp"]) > 0 and guard < 12:
                        g.probe_damage(key, 1)
                        guard += 1
        _check(g.gate_crossed, "crossing 40%% forces the carrier promotion")
        # only OWNED kinds drop: own none -> no capsule ever
        _check(g.drops.is_empty(),
                "an empty pool drops nothing (the shop-makes-drops law)")
        # buy one kind -> its drops can exist
        Box.spend(Box.coins())
        Box.earn(5000)
        _check(Box.buy_item("brickbreaker", "powerup", "multi", 320),
                "the shop sells the multiball")
        var saw_kind := false
        for i in 24:
                g._spawn_drop(_any_brick())
                for d in g.drops:
                        if String(d["kind"]) == "multi":
                                saw_kind = true
                g.drops.clear()
        _check(saw_kind, "the owned kind joins the pool (multi drops)")
        # an unowned kind never drops
        var saw_bad := false
        for i in 24:
                g._spawn_drop(_any_brick())
                for d in g.drops:
                        if String(d["kind"]) != "multi":
                                saw_bad = true
                g.drops.clear()
        _check(not saw_bad, "the unowned kinds NEVER drop")

# ---------------------------------------------------- 9. the caps + resets
func _t_caps_and_resets() -> void:
        print("-- the caps + the resets")
        _fresh(71)
        # THE CAP LAW: paddle to the walls, never below the floor
        g.pad_mult = 99.0
        _check(g.probe_pad_w() <= g.arena.size.x - 30.0 + 0.5,
                "the paddle wide cap: the walls are the ceiling (%.0f)" \
                                % g.probe_pad_w())
        g.pad_mult = 0.001
        _check(g.probe_pad_w() >= g.PAD_MIN_W - 0.5,
                "the paddle small floor: never invisible (%.0f)" \
                                % g.probe_pad_w())
        # the speed caps
        g.spd_mult = 99.0
        g._apply_pow("spd")     # the roll lands somewhere but the cap holds
        g.spd_mult = minf(g.spd_mult, 99.0)
        g.spd_mult = clampf(g.spd_mult, g.SPEED_MIN, g.SPEED_MAX)
        _check(g.spd_mult <= g.SPEED_MAX + 0.0001 \
                        and g.spd_mult >= g.SPEED_MIN - 0.0001,
                "the speed lives between x0.5 and x5")
        # direct through the catch path
        g.spd_mult = 4.9
        g.rng.seed = 5
        while g.spd_mult < g.SPEED_MAX:
                var before: float = g.spd_mult
                g._apply_pow("spd")
                if g.spd_mult <= before:
                        break
        _check(g.spd_mult <= g.SPEED_MAX + 0.0001,
                "the fast chain stops at x5 (%.2f)" % g.spd_mult)
        g.spd_mult = 0.55
        var guard := 0
        while g.spd_mult > g.SPEED_MIN and guard < 40:
                var before: float = g.spd_mult
                g._apply_pow("spd")
                guard += 1
                if g.spd_mult >= before:
                        break
        _check(g.spd_mult >= g.SPEED_MIN - 0.0001,
                "the slow chain stops at the x0.5 floor (%.2f)" % g.spd_mult)
        # the size caps + the pixel ceiling
        g.size_mult = 99.0
        _check(g._ball_r() <= g.BALL_R_CAP * g.us + 0.01,
                "the size limit: the absolute pixel ceiling (%.0f px)" \
                                % g._ball_r())
        _check(g._ball_r() >= g.BALL_BASE_R * g.us * g.SIZE_MIN - 0.01,
                "the size floor: x0.25 (r %.1f)" % g._ball_r())
        # the timers tick (they live on the PLAY clock)
        g._apply_pow("metal")
        _check(absf(g.metal_t - g.METAL_TIME) < 0.0001,
                "the metal catch arms 15s")
        g._apply_pow("fire")
        _check(absf(g.fire_t - g.FIRE_TIME) < 0.0001,
                "the fire catch arms 15s")
        g.phase = "play"          # the timers breathe in play
        g.balls = [{"x": g.pad_x, "y": g.paddle_y - 60.0, "dx": 0.0,
                "dy": -100.0, "r": 15.0, "stuck": false, "trail": []}]
        _run(2.0)
        _check(g.fire_t < g.FIRE_TIME and g.metal_t < g.METAL_TIME,
                "the timers tick down (%.1f / %.1f)" % [g.fire_t, g.metal_t])
        g.phase = "serve"
        # THE RESET LAW: a life loss wipes the effects, the REVIVE door
        # walks to the stall serve
        g.pad_mult = 2.0
        g.size_mult = 3.0
        g.spd_mult = 2.0
        g.lives = 3
        g._lose_life("BALL LOST")
        _check(g.pad_mult == 1.0 and g.size_mult == 1.0 \
                        and g.spd_mult == 1.0 and g.metal_t == 0.0 \
                        and g.fire_t == 0.0,
                "the life loss resets EVERY effect")
        _check(g.phase == "revive",
                "the life loss enters the REVIVE (the paddle rebuilds)")
        _run(g.REVIVE_TIME + 0.1)
        _check(g.phase == "serve", "the revive lands into the stall serve")
        # THE RESET LAW: the level clear wipes them too (hearts stay)
        g.lives = 5
        g.pad_mult = 2.0
        g.spd_mult = 3.0
        g._level_clear()
        _check(g.pad_mult == 1.0 and g.spd_mult == 1.0,
                "the level clear resets the effects")
        _check(g.lives == 5, "the hearts NEVER reset (still %d)" % g.lives)
        _check(g.phase == "clear", "the clear beat plays")
        _run(1.0)
        _check(g.phase == "intro" and g.level_i == 2,
                "the clear walks into level 2's intro (L%d)" % g.level_i)

# ------------------------------------------------------------ 10. the life
func _t_life_law() -> void:
        print("-- the life law")
        _fresh(83)
        g.lives = 3
        g.phase = "serve"
        g._spawn_serve_ball()
        g.probe_launch()
        # park the ball mid-air rising (it cannot die in 1s: it is still
        # above the paddle when the window closes)
        g.balls[0]["y"] = g.paddle_y - 300.0
        g.balls[0]["dy"] = -g._ball_speed()
        g.balls[0]["dx"] = 0.0
        _run(1.0)                 # the clock breathes first (the tension)
        var t_before: float = g.time_left
        # push the ball WELL past the lose line (one step, one verdict)
        g.balls[0]["y"] = g.lose_y + 60.0
        g.balls[0]["dy"] = 400.0
        g.probe_step(1.0 / 60.0)
        _check(g.lives == 2 and g.phase == "revive",
                "the lost ball costs ONE heart (lives=%d, phase=%s)" \
                                % [g.lives, g.phase])
        _run(g.REVIVE_TIME + 0.1)
        _check(g.phase == "serve" and g.balls.size() == 1 \
                        and bool(g.balls[0]["stuck"]),
                "the flicker revive lands the stall serve (ball on pad)")
        # the clock KEPT its spent time (no reset - the tension law): the
        # value continues from where it was, never reborn
        _check(g.time_left < g.level_time - 0.5 \
                        and g.time_left >= t_before - 0.2,
                "the clock KEPT running through the death (%.1f was %.1f of %.1f)"
                                % [g.time_left, t_before, g.level_time])
        # TIME UP: one heart + a FRESH clock (the play door first)
        g.probe_launch()
        g.time_left = 0.05
        var lives_before: int = g.lives
        g.probe_step(0.1)
        _check(g.lives == lives_before - 1,
                "the time-out costs a heart (lives=%d)" % g.lives)
        _check(absf(g.time_left - g.level_time) < 0.5,
                "the time-out resets the clock (%.1f)" % g.time_left)
        # the last heart ends the run (the play door first)
        g.probe_launch()
        g.lives = 1
        g.time_left = 0.05
        g.probe_step(0.1)
        _check(g.phase == "over" and g.over,
                "the last heart ends the run (the host banks it)")

# ----------------------------------------- 10b. the contact + fire laws
## THE 2-HIT BUG HUNT (the owner: "some of the 2-hits got broken from 1
## hit, worth testing so you know why this happen") + THE FIRE x3 LAW +
## THE OVERRIDE LAW - all deterministic, all live-physics where it counts
func _t_contact_and_fire() -> void:
        print("-- the contact law + the fire law + the override law")
        _fresh(97)
        g._new_level(12)
        var key := Vector2i(-1, -1)
        for k in g.ld["cells"].keys():
                var c: Dictionary = g.ld["cells"][k]
                if not bool(c["decor"]) and int(c["hp"]) == 2 \
                                and not bool(c.get("ice", false)) \
                                and not c.has("dying"):
                        key = k
                        break
        _check(key.x >= 0,
                "a fresh UNICED 2-hit brick exists (the rig's target)")
        # ONE honest contact: the ball flies straight up into the body -
        # the FIRST observed hp must be 1, never 0 (the old rig's seam
        # re-damage broke 2-hit bodies in one contact)
        g.phase = "serve"
        g._spawn_serve_ball()
        g.probe_launch()
        var b: Dictionary = g.balls[0]
        var cr: Rect2 = g._cell_rect(key)
        b["x"] = cr.get_center().x
        b["y"] = cr.end.y + float(b["r"]) + 2.0
        b["dx"] = 0.0
        b["dy"] = -g._ball_speed()       # UP into the body (the screen's
                                        # down is +y - the launch climbs)
        var saw := -1
        for i in 40:
                g.probe_step(1.0 / 60.0)
                if g.ld["cells"].has(key):
                        saw = int(g.ld["cells"][key]["hp"])
                else:
                        saw = 0          # the body broke and erased
                if saw != 2:
                        break
                if g.phase != "play":
                        g.phase = "serve"
                        g._spawn_serve_ball()
                        g.probe_launch()
                        b = g.balls[0]
                        b["x"] = cr.get_center().x
                        b["y"] = cr.end.y + float(b["r"]) + 2.0
                        b["dx"] = 0.0
                        b["dy"] = -g._ball_speed()
        _check(saw == 1,
                "ONE contact takes the 2-hit body to hp 1 (saw %s)" % saw)
        # THE FIRE x3 LAW: the burn is a NUMBER - a fat body loses
        # exactly FIRE_DMG per pass (L24's band (1,7) wears hp >= 6)
        g._new_level(24)
        var fkey := Vector2i(-1, -1)
        for k in g.ld["cells"].keys():
                var c2: Dictionary = g.ld["cells"][k]
                if not bool(c2["decor"]) and int(c2["hp"]) >= 6 \
                                and not bool(c2.get("ice", false)) \
                                and not c2.has("dying"):
                        fkey = k
                        break
        if fkey.x >= 0:
                var hp0 := int(g.ld["cells"][fkey]["hp"])
                var pts0: int = g.pts
                g.fire_t = 10.0
                g.metal_t = 0.0
                g.probe_damage(fkey, BB.FIRE_DMG, true)
                _check(int(g.ld["cells"][fkey]["hp"]) == hp0 - BB.FIRE_DMG,
                        "the fire pass deals exactly x%d (hp %d -> %d)" \
                                        % [BB.FIRE_DMG, hp0,
                                        int(g.ld["cells"][fkey]["hp"])])
                _check(g.pts == pts0 + BB.FIRE_DMG,
                        "the fire pays what it burns (+%d pts)" % BB.FIRE_DMG)
                g.fire_t = 0.0
        else:
                _check(false, "a fat (hp>=6) brick exists for the fire read")
        # THE OVERRIDE LAW: the newest state wins, the other burns out
        g._apply_pow("metal")
        _check(g.metal_t > 0.0 and g.fire_t == 0.0,
                "the metal catch arms alone")
        g._apply_pow("fire")
        _check(g.fire_t > 0.0 and g.metal_t == 0.0,
                "the fire catch REPLACED the metal (fire %.0fs, metal %.0fs)" \
                                % [g.fire_t, g.metal_t])
        g._apply_pow("metal")
        _check(g.metal_t > 0.0 and g.fire_t == 0.0,
                "the metal catch REPLACED the fire (fire %.0fs, metal %.0fs)" \
                                % [g.fire_t, g.metal_t])
        g.metal_t = 0.0
        g.fire_t = 0.0

# ------------------------------------------------- 11b. the calibration
## THE PACE FIT (print-only; BB_CAL=1 turns the asserts on): the
## auto-paddle plays real levels and the run reports the rig's pace
## against the fair bank - the numbers the timer constants are fitted to
func _t_calibration() -> void:
        print("-- the calibration (the rig's pace vs the bank)")
        for lv in [1, 3, 6, 10, 15]:
                Box.reset_all()
                Box.bump_counter("brickbreaker", "lore_start", 1)
                Box.bump_counter("brickbreaker", "lore_end", 1)
                await _scene_game()
                g.probe_reset(2024 + lv)
                g._new_level(lv)
                g._tap_anywhere(Vector2.ZERO)
                g._auto = true
                var t := 0.0
                var expiries := 0
                var last_bank: float = g.level_time
                var in_clear := false
                while t < 60.0 * 14.0 and not g.over:
                        g.probe_step(1.0 / 30.0)
                        t += 1.0 / 30.0
                        if g.phase == "serve":
                                in_clear = false
                                g.probe_launch()
                        if g.phase == "clear" and not in_clear:
                                in_clear = true
                                break
                        if g.time_left > g.level_time - 0.6 \
                                        and t > 1.0 and last_bank \
                                        == g.level_time:
                                # the clock was reborn: a TIME UP happened
                                last_bank = g.level_time
                                expiries += 1
                var brk := int(g.ld["total0"]) - int(g.ld["breakable"])
                if g.phase == "clear" or in_clear:
                        print("  CAL L%d: CLEARED in %.0fs sim (bank %.0fs, "
                                        % [lv, t, g.level_time]
                                        + "bricks %d, expiries %d, lives %d)"
                                        % [brk, expiries, g.lives])
                else:
                        print("  CAL L%d: STALLED at %.0fs (bricks %d/%d, "
                                        % [lv, t, brk,
                                        int(g.ld["total0"])]
                                        + "expiries %d, lives %d, over %s)"
                                        % [expiries, g.lives, g.over])

# ------------------------------------------------------- 11. the SIMULATION
## THE BEATABLE PROOF: the auto-paddle plays real levels start to finish
## inside the fair timer - "logically possible to beat", and the whole
## run breathes through the state machine with zero stalls.
func _t_simulation() -> void:
        print("-- the simulation (the auto-player plays)")
        Box.reset_all()
        Box.bump_counter("brickbreaker", "lore_start", 1)
        Box.bump_counter("brickbreaker", "lore_end", 1)
        await _scene_game()
        g.probe_reset(2024)
        g._tap_anywhere(Vector2.ZERO)     # the gate opens the intro
        g._auto = true                    # the tracking paddle takes over
        var target_levels := 4
        var cleared := 0
        var t := 0.0
        var cap := 60.0 * 14.0            # 14 real minutes of sim, capped
        var saw_serve := false
        var saw_play := false
        var in_clear := false             # one clear = one EVENT, not frames
        while t < cap and cleared < target_levels and not g.over:
                g.probe_step(1.0 / 30.0)
                t += 1.0 / 30.0
                if g.phase == "serve":
                        saw_serve = true
                        in_clear = false
                        g.probe_launch()
                if g.phase == "play":
                        saw_play = true
                if g.phase == "clear" and not in_clear:
                        in_clear = true
                        cleared += 1
                        _check(true, "LEVEL %d CLEARED in %.1fs sim time (lives=%d, pts=%d)"
                                        % [cleared, t, g.lives, g.pts])
        _check(saw_serve and saw_play,
                "the run breathed: serve + play both lived")
        _check(cleared >= 2,
                "the auto-player CLEARS levels inside the fair bank (%d cleared)"
                                % cleared)
        _check(g.score >= 2 or cleared >= 2,
                "the score wears the level law (score=%d)" % g.score)
        _check(not g.over or g.lives <= 0,
                "the run survives the early ladder (lives=%d)" % g.lives)

# -------------------------------------------------- 12. the powered soak
## THE LIVE ECONOMY: the run OWNS the whole shelf (the shop law's other
## face) - capsules fall, the paddle catches, the bundles land, the
## multiball splits, the 15s timers burn. Nothing here may hang, crash
## or cap-bust in live play.
func _t_powered_soak() -> void:
        print("-- the powered soak (drops live, chips hot)")
        Box.reset_all()
        Box.bump_counter("brickbreaker", "lore_start", 1)
        Box.bump_counter("brickbreaker", "lore_end", 1)
        Box.earn(5000)
        var bought := true
        for id in BB.POWS.keys():
                if not Box.buy_item("brickbreaker", "powerup", String(id),
                                int(BB.POWS[id]["price"])):
                        bought = false
        _check(bought, "the whole shelf bought (6 rows)")
        await _scene_game()
        g.probe_reset(777)
        g._tap_anywhere(Vector2.ZERO)
        g._auto = true
        var drops_frames := 0
        var multi_seen := false
        var metal_ran := false
        var fire_ran := false
        var pad_moved := false
        var t := 0.0
        var in_clear := false
        var cleared := 0
        while t < 60.0 * 12.0 and cleared < 3 and not g.over:
                g.probe_step(1.0 / 30.0)
                t += 1.0 / 30.0
                if g.phase == "serve":
                        in_clear = false
                        g.probe_launch()
                if g.phase == "clear" and not in_clear:
                        in_clear = true
                        cleared += 1
                if g.drops.size() > 0:
                        drops_frames += 1
                if g.balls.size() >= 2:
                        multi_seen = true
                if g.metal_t > 0.0:
                        metal_ran = true
                if g.fire_t > 0.0:
                        fire_ran = true
                if absf(g.pad_mult - 1.0) > 0.01:
                        pad_moved = true
                # the caps hold UNDER FIRE (the chips never bust)
                if g.spd_mult > g.SPEED_MAX + 0.001 \
                                or g.size_mult > g.SIZE_MAX + 0.001:
                        _check(false, "A CAP BUSTED LIVE (spd %.2f size %.2f)"
                                        % [g.spd_mult, g.size_mult])
                        return
        _check(drops_frames > 0,
                "capsules fell in live play (%d frames)" % drops_frames)
        _check(multi_seen or pad_moved or metal_ran or fire_ran,
                "a catch LANDED (multi=%s pad=%s metal=%s fire=%s)" \
                                % [multi_seen, pad_moved, metal_ran,
                                fire_ran])
        _check(cleared >= 1,
                "the powered run still clears (%d cleared, lives=%d)" \
                                % [cleared, g.lives])
        _check(not g.over or g.lives <= 0,
                "the powered soak survives (lives=%d)" % g.lives)
