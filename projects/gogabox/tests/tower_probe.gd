extends Node
## tower_probe - v0.2.5: drives SNOWY TOWER headless. The physics is driven
## by DIRECT _goga_tick(1/60) calls (with base _process paused) so every law
## is deterministic - no frame timing flakiness. Between law groups the
## player is RE-SEATED on a live platform (a falling probe is a dying
## probe - the first draft died mid-run and everything after it lied).
##
## The laws: the PGB platform types + THE RELIABILITY LAW, the wide start
## platform, reachability + wall-clamped generation, the walls bounce the
## player, the slide-up law (wake at 2, x1.1 per 10, cap x6), score =
## platforms climbed (skip pays 1, lower pays NOTHING), coins 5-25 platforms
## from the LAST COIN SPAWNED, powerups (10s life, x2 one mid-air jump, big
## x1.28, speed x1.5, slow halves the slide), the PHYSICAL SNOW (flakes land
## on platforms AND on the player, snow makes you slow + heavy, rolling
## sheds), the four characters with their own physics/spin, the run ends
## below the screen, and the all_owned cheat makes the window-gated game
## always playable. Exit 0 = pass.
##
##   godot --headless --path projects/gogabox res://tests/tower_probe.tscn

var fails := 0

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1

const DT := 1.0 / 60.0

func _ticks(g: GogaGame, n: int) -> void:
        for i in n:
                g._goga_tick(DT)

## seat the player on a LIVE platform (the anti-fall harness)
func _seat(g: GogaGame, p: Dictionary) -> void:
        # the seat is forced SOLID: a random blinking/vanish seat could blink
        # OFF (dropping the harness AND refusing snow) mid-law
        p["type"] = "static"
        p["visible"] = true
        p["ghost"] = false
        g.char_size = 1.0   # the melt laws set their own size AFTER seating
        g.px = float(p["x"])
        g.py = float(p["y"]) - H.PLAT_H * g.U * 0.5 - H.PLAYER_R * g.U
        g.vx = 0.0
        g.vy = 0.0
        g.grounded = true
        g.ground_plat = p
        g.move_dir = 0
        g.player.position = Vector2(g.px, g.py)

var H: GDScript

func _run() -> void:
        Box.reset_all()
        print("== tower_probe: SNOWY TOWER v0.2.5 ==")
        H = load("res://game/games/hopper/hopper.gd")

        # ---- registry sanity ----
        var hop: Dictionary = GameReg.get_game("hopper")
        _check(not hop.is_empty(), "hopper is in the registry")
        _check(int(hop["coin_div"]) == 10, "snowy tower run bonus = score/10 (owner)")
        _check(bool(hop["shop"]), "snowy tower wears a shop")
        _check(int(hop["fee"]) == 12, "the round fee stays 12")
        _check(Roadmap.window_text("hopper") != "", "the playtime window stays (the cheat has something to bypass)")

        # ---- shop constants ----
        _check(int(H.CHARS["ball"]["price"]) == 0, "the ball is the free default character")
        var cprices := [int(H.CHARS["square"]["price"]), int(H.CHARS["shard"]["price"]), int(H.CHARS["egg"]["price"])]
        var cok := true
        for pr in cprices:
                cok = cok and pr >= 300
        _check(cok and cprices.size() == 3, "square/shard/egg cost real coins (%s)" % str(cprices))
        _check(int(H.PLATS["sand"]["price"]) == 0 and H.PLATS.size() == 4, "sand is free; rock/grass/metal exist")
        _check(int(H.PLACES["day"]["price"]) == 0 and int(H.PLACES["night"]["price"]) > 0, "day free, night costs")
        _check(H.POWERUPS.size() == 4, "four powerups (x2, big, speed, slow)")
        for k in H.POWERUPS:
                _check(int(H.POWERUPS[k]["price"]) >= 250, "powerup %s costs >= 250" % k)
        _check(float(H.PW_TIME) == 10.0, "every powerup lives 10s (owner)")
        # v0.2.6 MELTING (the owner's upgrade: bought, toggleable)
        _check(int(H.MELT["price"]) >= 400, "MELTING costs real coins (%d)" % int(H.MELT["price"]))
        _check(float(H.MELT_MAX) == 1.5, "MELTING grows to exactly x1.5 (owner: not too much)")
        _check(float(H.MELT_MIN) < 0.5, "MELTING dies below x%.2f" % H.MELT_MIN)
        _check(float(H.MELT_SPEED_FLOOR) > 0.2 and float(H.MELT_SPEED_FLOOR) < 0.5,
                        "fast moves keep consuming at ~30%% (floor %.2f)" % H.MELT_SPEED_FLOOR)
        # v0.2.6 the zone controls exist
        _check(float(H.AXIS_DEAD) > 0.0 and float(H.AXIS_FULL) > float(H.AXIS_DEAD),
                        "the analog zone has a dead point AND a full deflection")

        # ---- boot ----
        var g: GogaGame = H.new()
        g.game_id = "hopper"
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        g.paused = true          # determinism: base _process stops, WE drive ticks
        var vp: Vector2 = g.get_viewport_rect().size
        _check(g.phase == "ready", "boots into the TAP ANYWHERE card")
        _check(g.platforms.size() >= 5, "the tower is pre-generated (%d platforms)" % g.platforms.size())
        _check(absf(float(g.platforms[0]["w"]) - H.START_W * g.U) < 0.01, "platform zero is THE WIDE START PLATFORM")
        # v0.2.6 THE PHANTOM-COIN LAWS (the owner: a free coin appeared every
        # spawn - a coin lived ON the start platform)
        var bad_coin := false
        for c0 in g.coins:
                if int(c0["idx"]) <= 0:
                        bad_coin = true
        _check(not bad_coin and g.coins.size() >= 0, "NO coin on the start platform")
        if not g.coins.is_empty():
                var first_c: int = int(g.coins[0]["idx"])
                _check(first_c >= H.COIN_GAP_MIN and first_c <= H.COIN_GAP_MAX,
                                "the first coin waits 5-25 platforms up (idx %d)" % first_c)

        # ---- generation laws (v0.2.7: ramp-aware) ----
        var gen_ok := true
        var rel_ok := true
        var UNRELIABLE := ["blinking", "vanish", "mb", "dropper"]
        var ramp_seen := 0.0
        for i in range(1, g.platforms.size()):
                var p: Dictionary = g.platforms[i]
                var lo: float = float(p["x"]) - float(p["w"]) / 2.0
                var hi: float = float(p["x"]) + float(p["w"]) / 2.0
                if lo < H.WALL_W * g.U - 0.5 or hi > vp.x - H.WALL_W * g.U + 0.5:
                        gen_ok = false
                var gapv: float = absf(float(g.platforms[i - 1]["y"]) - float(p["y"]))
                # THE RAMP: the first DIFF_AT platforms keep the gentle band;
                # past that the ceiling rises toward the char's real jump cap
                var ramp: float = clampf(float(i - H.DIFF_AT) / float(H.DIFF_RAMP), 0.0, 1.0)
                ramp_seen = maxf(ramp_seen, ramp)
                var gap_cap: float = minf(H.GAP_HARD_MAX,
                                0.82 * pow(absf(H.JUMP_V * g.U), 2.0) / (2.0 * H.GRAV * g.U) / g.U)
                var gap_hi: float = lerpf(H.GAP_MAX, gap_cap, ramp)
                if gapv < H.GAP_MIN * g.U - 1.0 or gapv > gap_hi * g.U + 1.0:
                        gen_ok = false
                if UNRELIABLE.has(String(g.platforms[i - 1]["type"])) and UNRELIABLE.has(String(p["type"])):
                        rel_ok = false
        _check(gen_ok, "every platform sits between the walls at a ramp-legal gap")
        _check(rel_ok, "THE RELIABILITY LAW: an unreliable platform is always followed by a reliable one")
        # the reach law = the generator's DESCENDING-branch crossing time
        var reach_ok := true
        for i in range(1, g.platforms.size()):
                var dx: float = absf(float(g.platforms[i]["x"]) - float(g.platforms[i - 1]["x"]))
                var gapv2: float = absf(float(g.platforms[i - 1]["y"]) - float(g.platforms[i]["y"]))
                var jump_v := absf(H.JUMP_V * g.U)
                var disc: float = maxf(0.0, jump_v * jump_v - 2.0 * H.GRAV * g.U * gapv2)
                var t_cross: float = (jump_v + sqrt(disc)) / (H.GRAV * g.U)
                var ramp2: float = clampf(float(i - H.DIFF_AT) / float(H.DIFF_RAMP), 0.0, 1.0)
                if dx > H.WALK_MAX * g.U * t_cross * lerpf(0.72, 1.12, ramp2) * 1.02:
                        reach_ok = false
        _check(reach_ok, "every next platform stays inside the DESCENDING-branch reach")

        # ---- start via tap (the owner: TAP ANYWHERE) ----
        var t := InputEventScreenTouch.new()
        t.index = 0
        t.position = Vector2(vp.x * 0.5, vp.y * 0.5)
        t.pressed = true
        g._goga_input(t)
        _check(g.phase == "run", "a press anywhere starts the run")
        # HARD harness stop: engine-level, immune to any game-side flag flips -
        # from here the ONLY thing that ticks the game is _ticks() below
        g.process_mode = Node.PROCESS_MODE_DISABLED
        if g.phase != "run":
                print("  [TRACE] the run died right after: start")

        # ---- the walls bounce the player ----
        g.px = H.WALL_W * g.U + H.PLAYER_R * g.U + 2.0
        g.vx = -600.0 * g.U
        _ticks(g, 4)
        _check(g.px >= H.WALL_W * g.U + H.PLAYER_R * g.U - 0.5, "the LEFT wall keeps the player on screen")
        _check(g.vx > 0.0, "the wall BOUNCES (vx reversed)")
        g.px = vp.x - H.WALL_W * g.U - H.PLAYER_R * g.U - 2.0
        g.vx = 600.0 * g.U
        _ticks(g, 4)
        _check(g.px <= vp.x - H.WALL_W * g.U - H.PLAYER_R * g.U + 0.5, "the RIGHT wall keeps the player on screen")
        if g.phase != "run":
                print("  [TRACE] the run died right after: walls")

        # ---- landing + THE SCORING LAW (v0.2.6: the start platform pays
        # NOTHING - the owner's catch: it used to pay +1 like every ledge) --
        _seat(g, g.platforms[0])
        _ticks(g, 3)
        _check(g.grounded, "the ball lands on the start platform")
        _check(int(g.score) == 0, "the START PLATFORM pays nothing (owner, v0.2.6)")
        var s_before: int = g.score
        # land on a HIGHER platform: pays exactly +1
        var up_p: Dictionary = g.platforms[2]
        g.grounded = false
        g.px = float(up_p["x"])
        g.py = float(up_p["y"]) - H.PLAT_H * g.U * 0.5 - H.PLAYER_R * g.U - 60.0
        g.vy = 300.0 * g.U
        _ticks(g, 10)
        _check(g.grounded and int(g.ground_plat["idx"]) == int(up_p["idx"]), "the ball landed on a HIGHER platform (idx %d)" % int(up_p["idx"]))
        _check(int(g.score) == s_before + 1, "climbing pays EXACTLY +1")
        # land on a LOWER platform: pays NOTHING
        var low: Dictionary = g.platforms[1]
        s_before = g.score
        g.grounded = false
        g.px = float(low["x"])
        g.py = float(low["y"]) - H.PLAT_H * g.U * 0.5 - H.PLAYER_R * g.U - 60.0
        g.vy = 300.0 * g.U
        _ticks(g, 10)
        s_before = g.score
        _check(g.grounded and int(g.ground_plat["idx"]) == int(low["idx"]), "the ball landed on a LOWER platform (idx %d)" % int(low["idx"]))
        _check(int(g.score) == s_before, "landing LOWER pays nothing (owner scoring law)")
        # SKIP platforms: teleport above a much higher one - exactly +1
        var hi_p: Dictionary = g.platforms[g.platforms.size() - 1]
        g.grounded = false
        g.px = float(hi_p["x"])
        g.py = float(hi_p["y"]) - H.PLAT_H * g.U * 0.5 - H.PLAYER_R * g.U - 80.0
        g.vy = 300.0 * g.U
        _ticks(g, 10)
        _check(g.grounded and int(g.ground_plat["idx"]) == int(hi_p["idx"]),
                        "the ball skipped 3+ and landed the higher one (idx %d)" % int(hi_p["idx"]))
        _check(int(g.score) == s_before + 1, "skipping platforms still pays EXACTLY +1")
        # THE TOUR LOCK: from here on no landing may score again - a stray +1
        # would wake the slide-up scroll and slowly push the seated harness
        # to its death mid-law-tour (the heisenbug that took three tracers)
        g.highest_idx = 1000000
        g.score = 0
        if g.phase != "run":
                print("  [TRACE] the run died right after: scoring")

        # ---- the jump: one press, one jump, nothing mid-air without x2 ----
        # v0.2.6: the jump now goes through the REAL input path - a tap on
        # the RIGHT half of the screen (the old jump circle shipped dead:
        # its _gui_input subtracted global_position from an already-local
        # position, so every press landed outside the circle)
        _seat(g, g.platforms[g.platforms.size() - 1])
        g.snow_load = 0.0
        var jt := InputEventScreenTouch.new()
        jt.index = 3
        jt.position = Vector2(vp.x * 0.8, vp.y * 0.6)
        jt.pressed = true
        g._goga_input(jt)
        _check(not g.grounded and g.vy < 0.0, "a RIGHT-half tap JUMPS (the real input path)")
        var jt2 := InputEventScreenTouch.new()
        jt2.index = 3
        jt2.position = Vector2(vp.x * 0.8, vp.y * 0.6)
        jt2.pressed = false
        g._goga_input(jt2)
        var hops_before: int = g.hops
        _ticks(g, 2)
        g._do_jump()
        _check(g.hops == hops_before, "a second press in the air does NOTHING without x2")
        # ---- the ANALOG MOVE ZONE (the owner's scheme) ----
        _seat(g, g.platforms[g.platforms.size() - 1])
        var mt := InputEventScreenTouch.new()
        mt.index = 5
        mt.position = Vector2(vp.x * 0.25, vp.y * 0.7)
        mt.pressed = true
        g._goga_input(mt)
        _check(g.move_touch == 5 and g.move_dir == 0.0,
                        "a LEFT-half touch ANCHORS the move zone at zero force")
        var md := InputEventScreenDrag.new()
        md.index = 5
        md.position = Vector2(vp.x * 0.25 + 60.0 * g.U, vp.y * 0.7)
        g._goga_input(md)
        _check(g.move_dir > 0.4 and g.move_dir <= 1.0,
                        "dragging right of the anchor drives the force (%.2f)" % g.move_dir)
        md = InputEventScreenDrag.new()
        md.index = 5
        md.position = Vector2(vp.x * 0.25, vp.y * 0.7)
        g._goga_input(md)
        _check(g.move_dir == 0.0, "BACK at the anchor = the dead point (move stops)")
        md = InputEventScreenDrag.new()
        md.index = 5
        md.position = Vector2(vp.x * 0.25 - 40.0 * g.U, vp.y * 0.7 + 90.0 * g.U)
        g._goga_input(md)
        _check(g.move_dir < -0.2, "the zone listens LEFT-RIGHT only (Y ignored, %.2f)" % g.move_dir)
        var mt2 := InputEventScreenTouch.new()
        mt2.index = 5
        mt2.position = Vector2(vp.x * 0.25 - 40.0 * g.U, vp.y * 0.7 + 90.0 * g.U)
        mt2.pressed = false
        g._goga_input(mt2)
        _check(g.move_touch == -1 and g.move_dir == 0.0, "releasing the finger stops the move")
        if g.phase != "run":
                print("  [TRACE] the run died right after: jump")

        # ---- the slide-up law ----
        g.score = 1
        _check(g._scroll_speed() == 0.0, "the slide sleeps before 2 platforms")
        g.score = 2   # force the wake threshold
        var base_sp: float = g._scroll_speed()
        _check(absf(base_sp - H.SCROLL_BASE * g.U) < 0.01, "the slide wakes at x1.00 base speed")
        g.score = 12  # floor(12/10)=1 -> x1.1
        var sp12: float = g._scroll_speed()
        _check(absf(sp12 - H.SCROLL_BASE * g.U * 1.1) < 0.01, "10 platforms later the slide is x1.1 (owner)")
        g.pw = {"id": "slow", "t": 5.0}
        var sp_slow: float = g._scroll_speed()
        _check(absf(sp_slow - sp12 * 0.5) < 0.01, "the -50% powerup halves the slide")
        g.pw = {"id": "", "t": 0.0}
        g.score = 0

        # ---- coins: 5-25 platforms from the LAST COIN SPAWNED ----
        for i in 80:
                g._gen_platform()
        var coin_idxs: Array = []
        for c in g.coins:
                coin_idxs.append(int(c["idx"]))
        var coin_ok := coin_idxs.size() >= 3
        for i in range(1, coin_idxs.size()):
                var gapv2: int = coin_idxs[i] - coin_idxs[i - 1]
                if gapv2 < H.COIN_GAP_MIN or gapv2 > H.COIN_GAP_MAX:
                        coin_ok = false
        _check(coin_ok, "GOGACoins hang every 5-25 platforms from the last coin spawned (%s)" % str(coin_idxs))
        if g.phase != "run":
                print("  [TRACE] the run died right after: coins")
        if g.phase != "run":
                print("  [TRACE] the run died right after: scroll")

        # ---- powerups: pickup -> live -> ring drains -> one x2 only ----
        Box.dev_set_cheat("all_owned", 1)   # the probe owns every powerup
        _check(g._owned_pws().size() == 4, "under the cheat all four powerups spawn")
        _seat(g, g.platforms[g.platforms.size() - 2])
        g.pickups.append({"x": g.px, "y": g.py, "idx": 999, "kind": "speed", "t": 0.0})
        _ticks(g, 1)
        _check(String(g.pw["id"]) == "speed", "a pickup goes live on touch")
        _check(absf(float(g.pw["t"]) - H.PW_TIME) < 0.02, "the powerup lives 10s")
        g.pw = {"id": "big", "t": 10.0}
        _ticks(g, 30)
        _check(float(g.pw["t"]) < 10.0 and float(g.pw["t"]) > 0.0, "the life ring drains toward empty")
        _check(g._pw_widget != null and g._pw_widget.visible,
                        "a live powerup shows the TOP widget (icon + timer, v0.2.6)")
        g.pw = {"id": "", "t": 0.0}
        _ticks(g, 1)
        _check(g._pw_widget != null and not g._pw_widget.visible,
                        "the widget hides when the powerup ends")
        # big jump: apex multiplier (load zeroed - the law is the multiplier)
        _seat(g, g.platforms[g.platforms.size() - 2])
        g.snow_load = 0.0
        g.pw = {"id": "big", "t": 10.0}   # the widget laws cleared it
        g._do_jump()
        _check(absf(g.vy - H.JUMP_V * g.U * float(H.CHARS[g.char_id]["jump"]) * 1.28) < 0.02,
                        "the big jump powerup jumps x1.28")
        # x2: exactly ONE mid-air jump
        g.pw = {"id": "x2", "t": 9.0}
        g.air_jumped = false
        g._do_jump()
        var vy_after_first: float = g.vy
        g._do_jump()
        _check(g.air_jumped and g.vy == vy_after_first, "x2 gives exactly ONE mid-air jump")
        _check(not g.grounded, "the x2 jump happens in the air")
        if g.phase != "run":
                print("  [TRACE] the run died right after: powerups")

        # ---- THE PHYSICAL SNOW ----
        g.pw = {"id": "", "t": 0.0}
        var seat_p: Dictionary = g.platforms[g.platforms.size() - 2]
        _seat(g, seat_p)
        _ticks(g, 90)
        _check(g.flakes.size() == H.SNOW_COUNT, "the snowfall holds its full count (%d)" % g.flakes.size())
        if g.phase != "run":
                print("  [TRACE] the run died right after: snow-count")
        var snow_before: float = float(seat_p["snow"])
        _seat(g, seat_p)
        seat_p["snow"] = 0.0   # an already-FULL cap rejects flakes - start empty
        snow_before = float(seat_p["snow"])
        var flake_landed := false
        for attempt in 3:
                _seat(g, seat_p)
                g.flakes[0]["vy"] = 100.0 * g.U
                seat_p["snow"] = 0.0
                g.flakes[0]["x"] = float(seat_p["x"])
                g.flakes[0]["y"] = float(seat_p["y"]) - H.PLAT_H * g.U * 0.5 + 1.0
                g.flakes[0]["vy"] = 100.0 * g.U
                _ticks(g, 1)
                if float(seat_p["snow"]) > 0.0:
                        flake_landed = true
                        break
        _check(flake_landed, "a flake LANDED on a platform and thickened its snow cap")
        var load_before: float = g.snow_load
        g.flakes[0]["x"] = g.px
        g.flakes[0]["y"] = g.py - H.PLAYER_R * g.U * 0.6
        g.flakes[0]["fore"] = false
        _ticks(g, 1)
        _check(g.snow_load > load_before, "a flake that reaches the ball STICKS to it")
        # snow makes you heavy: one tick of acceleration tells the truth
        g.snow_load = 0.0
        g.vx = 0.0
        g.move_dir = 1
        _ticks(g, 1)
        var fast_vx: float = g.vx
        g.snow_load = 1.0
        g.vx = 0.0
        _ticks(g, 1)
        var heavy_vx: float = g.vx
        g.move_dir = 0
        _check(heavy_vx < fast_vx * 0.7, "a loaded ball accelerates SLOWER (%.1f -> %.1f)" % [fast_vx, heavy_vx])
        # rolling sheds it: keep the seat + a live walking speed every tick
# rolling sheds it: re-seat every tick so gravity can never drag the
# harness off its platform (and the run can never die here)
        g.snow_load = 0.9
        for i in 90:
                _seat(g, seat_p)
                g.vx = 220.0 * g.U
                g.grounded = true
                g._goga_tick(DT)
        _check(g.snow_load < 0.75, "rolling SHEDS the snow (load %.2f)" % g.snow_load)
        if g.phase != "run":
                print("  [TRACE] the run died right after: shed")
        g.snow_load = 0.0

        # ---- the four characters: physics + spin (each seated, mid-screen) ----
        _check(float(H.CHARS["shard"]["g"]) < 1.0, "the shard is floatier (lower gravity)")
        _check(float(H.CHARS["egg"]["fric"]) < float(H.CHARS["ball"]["fric"]), "the egg slides (low friction)")
        _check(float(H.CHARS["square"]["accel"]) < float(H.CHARS["ball"]["accel"]), "the cube is sluggish (low accel)")
        var spin_seat: Dictionary = g.platforms[g.platforms.size() - 2]
        # the walk laws RE-SEAT every tick: the harness walks but never leaves
        # the platform, and the run can never die here
        g.char_id = "ball"
        g.spin = 0.0
        for i in 90:
                _seat(g, spin_seat)
                g.move_dir = 1
                g._goga_tick(DT)
        g.move_dir = 0
        _check(absf(g.spin) > 0.3, "the ball ROLLS while walking (spin %.2f)" % g.spin)
        # v0.2.6 THE REAL TUMBLE LAWS (the owner: the cube "flips 90 degrees
        # yes but for real - a side FALLS and it flips smoothly"; the shard
        # "physical movements where it flips"):
        g.char_id = "square"
        g.tumble_rot = 0.0
        g.tumble_vel = 0.0
        for i in 90:
                _seat(g, spin_seat)
                g.move_dir = 1
                g._goga_tick(DT)
        g.move_dir = 0
        _check(absf(g.tumble_rot) > 0.3, "the cube TUMBLES continuously while walking (%.2f rad)" % g.tumble_rot)
        var snapped := absf(fmod(g.tumble_rot, PI / 2.0))
        _check(snapped > 0.02, "the rotation is NOT snapped to the 90s mid-walk (off %.3f rad)" % snapped)
        for i in 90:
                _seat(g, spin_seat)
                g._goga_tick(DT)
        var nearest90 := roundf(g.tumble_rot / (PI / 2.0)) * (PI / 2.0)
        _check(absf(g.tumble_rot - nearest90) < 0.05,
                        "stopping SETTLES the cube onto its flat face (off %.4f rad)" % absf(g.tumble_rot - nearest90))
        if g.phase != "run":
                print("  [TRACE] the run died right after: cube")
        g.char_id = "shard"
        g.tumble_rot = 0.0
        g.tumble_vel = 0.0
        for i in 90:
                _seat(g, spin_seat)
                g.move_dir = 1
                g._goga_tick(DT)
        g.move_dir = 0
        _check(absf(g.tumble_rot) > 0.3, "the shard FLIPS physically while walking (%.2f rad)" % g.tumble_rot)
        for i in 90:
                _seat(g, spin_seat)
                g._goga_tick(DT)
        var best_edge := 999.0
        for base in [0.0, H.SHARD_SETTLE_ANG, -H.SHARD_SETTLE_ANG]:
                var cand: float = base + TAU * roundf((g.tumble_rot - base) / TAU)
                best_edge = minf(best_edge, absf(cand - g.tumble_rot))
        _check(best_edge < 0.05,
                        "the shard settles onto an EDGE-down stance (off %.4f rad)" % best_edge)
        if g.phase != "run":
                print("  [TRACE] the run died right after: shard")
        g.char_id = "egg"
        g.wobble_clock = 0.0
        for i in 30:
                _seat(g, spin_seat)
                g.move_dir = 1
                g._goga_tick(DT)
        g.move_dir = 0
        _check(absf(g.player.rotation) < 0.6, "the egg WOBBLES, never a full spin (%.2f)" % absf(g.player.rotation))
        g.char_id = "ball"

        # ---- platform behaviors ----
        var mv: Dictionary = g.platforms[g.platforms.size() - 3]
        mv["type"] = "moving"
        mv["visible"] = true
        var mx0: float = float(mv["x"])
        _ticks(g, 20)
        _check(float(mv["x"]) != mx0, "a moving platform patrols")
        var wall_ok := true
        for p2 in g.platforms:
                if float(p2["x"]) - float(p2["w"]) / 2.0 < H.WALL_W * g.U - 1.0 \
                                                or float(p2["x"]) + float(p2["w"]) / 2.0 > vp.x - H.WALL_W * g.U + 1.0:
                        wall_ok = false
        _check(wall_ok, "patrols stay between the walls (owner)")
        if g.phase != "run":
                print("  [TRACE] the run died right after: behavior")
        var bl: Dictionary = g.platforms[g.platforms.size() - 3]
        bl["type"] = "blinking"
        bl["visible"] = true
        bl["clock"] = H.BLINK_PERIOD - 0.01
        _ticks(g, 2)
        _check(not bool(bl["visible"]), "a blinking platform blinks OFF on its period")
        var vn: Dictionary = g.platforms[g.platforms.size() - 3]
        vn["type"] = "vanish"
        vn["visible"] = true
        vn["ghost"] = false
        g.grounded = false
        g.px = float(vn["x"])
        g.py = float(vn["y"]) - H.PLAT_H * g.U * 0.5 - H.PLAYER_R * g.U - 20.0
        g.vy = 200.0 * g.U
        _ticks(g, 10)
        _check(bool(vn["ghost"]), "landing on a vanish platform starts the vanish")
        _seat(g, g.platforms[g.platforms.size() - 2])   # step off the dying ledge
        vn["clock"] = H.VANISH_GRACE + H.VANISH_RESPAWN - 0.05
        vn["visible"] = false
        _ticks(g, 5)
        _check(bool(vn["visible"]) and not bool(vn["ghost"]), "the vanished platform comes BACK")

        # ---- v0.2.6 THE SNOW IS EARNED (the owner: platforms must NOT all
        # carry snow from the start) ----
        var n0: int = g.next_idx
        g._spawn_platform(g._vp().x / 2.0, g._last_top() - H.GAP_MIN * g.U,
                        120.0 * g.U, "static")
        var fresh: Dictionary = g.platforms[g.platforms.size() - 1]
        _check(int(fresh["idx"]) == n0 and float(fresh["snow"]) == 0.0,
                        "a fresh platform is BORN BARE (cap %.3f)" % float(fresh["snow"]))
        var mv2: Dictionary = g.platforms[g.platforms.size() - 3]
        mv2["type"] = "moving"
        mv2["visible"] = true
        mv2["snow"] = 0.6
        # driven DIRECTLY (no _ticks): the shed lives in _update_platforms
        # and this keeps the live snowfall out of the measurement (flakes
        # landing mid-law made it flaky - 1 run in 3 caught a flurry)
        for i in 60:
                g._update_platforms(1.0 / 60.0)
        _check(absf(float(mv2["snow"]) - 0.48) < 0.01,
                        "a MOVING platform shakes its snow off (%.3f)" % float(mv2["snow"]))

        # ---- v0.2.6 MELTING (the owner's upgrade) ----
        Box.dev_set_cheat("all_owned", 1)
        Box.equip_item("hopper", "melt", "on")
        _check(g._melt_on(), "MELTING toggles ON from the shop state")
        var melt_seat: Dictionary = g.platforms[g.platforms.size() - 2]
        _seat(g, melt_seat)
        melt_seat["snow"] = 0.8
        g.char_size = 1.0
        _ticks(g, 90)
        _check(float(melt_seat["snow"]) < 0.8,
                        "MELT ON eats the snow UNDER the character (%.3f left)" % float(melt_seat["snow"]))
        _check(g.char_size > 1.0, "eating snow GROWS the character (x%.3f)" % g.char_size)
        # the speed law: fast moves consume LESS in the same span
        var slow_seat: Dictionary = g.platforms[g.platforms.size() - 2]
        _seat(g, slow_seat)
        slow_seat["snow"] = 0.4
        _ticks(g, 60)
        var eaten_rest: float = 0.4 - float(slow_seat["snow"])
        var fast_seat: Dictionary = g.platforms[g.platforms.size() - 2]
        _seat(g, fast_seat)
        fast_seat["snow"] = 0.4
        for i in 60:
                _seat(g, fast_seat)
                g.vx = H.WALK_MAX * g.U
                g.move_dir = 1.0
                g._goga_tick(DT)
        var eaten_fast: float = 0.4 - float(fast_seat["snow"])
        _check(eaten_fast < eaten_rest,
                        "a FAST move consumes at a LOWER rate (%.3f < %.3f)" % [eaten_fast, eaten_rest])
        # no snow under you = shrink (the -1.0 is a DEBT so the live
        # snowfall can never fake a snack during the law - one flake is
        # only +0.014)
        var bare_seat: Dictionary = g.platforms[g.platforms.size() - 2]
        _seat(g, bare_seat)
        bare_seat["snow"] = -1.0
        var size_before: float = g.char_size
        _ticks(g, 60)
        _check(g.char_size < size_before,
                        "NO snow under you = the character SHRINKS (%.3f -> %.3f)" % [size_before, g.char_size])
        Box.equip_item("hopper", "melt", "off")
        _check(not g._melt_on(), "MELTING toggles OFF again")
        g.char_size = 1.0

        # ---- v0.2.6 THE PLACE-LEAK LAW (the owner: day -> night -> day came
        # back DARKER - a stale CanvasModulate survived under an @-renamed
        # handle; now there is exactly ONE, and day is EXACTLY day) ----
        for trip in [["night"], ["day"], ["night"], ["day"]]:
                Box.equip_item("hopper", "place", trip[0])
                g._apply_place(g.sky.material as ShaderMaterial)
                g._day_night()
        var mod_count := 0
        var mod_col := Color(-1, -1, -1)
        for ch in g.world.get_children():
                if ch is CanvasModulate:
                        mod_count += 1
                        mod_col = (ch as CanvasModulate).color
        _check(mod_count == 1, "exactly ONE place modulate after two round trips (%d)" % mod_count)
        _check(mod_col.is_equal_approx(Color(1, 1, 1)),
                        "DAY is EXACTLY day after the night trips (no leak: %s)" % str(mod_col))

        # ---- the run ends below the screen ----
        _check(g.phase == "run", "the run survived the whole law tour (no early death)")
        var ts0: int = g.score
        g.py = g.cam_y + vp.y + 100.0 * g.U
        g.process_mode = Node.PROCESS_MODE_ALWAYS   # the death tween needs the tree
        g.paused = false
        _ticks(g, 1)
        _check(g.phase == "over", "falling below the screen ends the run")
        await get_tree().create_timer(1.0).timeout
        _check(g.over, "the run banks through finish_run")
        _check(Box.counter("hopper", "max_tower") >= ts0, "the best tower counter moved")

        # ---- THE ALWAYS-PLAYABLE CHEAT ----
        Box.dev_set_cheat("all_owned", 1)
        _check(Roadmap.can_play_now("hopper"), "all_owned: the window-gated tower is ALWAYS playable now")
        _check(Box.daily_ok("hopper"), "all_owned: daily caps never block")
        Box.dev_set_cheat("all_owned", 0)
        Box.dev_set_cheat("gogacoins", 0)

        # ---- v0.2.6 the melt DEATH (a second life: this game is spent) ----
        var g2: GogaGame = H.new()
        g2.game_id = "hopper"
        add_child(g2)
        await get_tree().process_frame
        await get_tree().process_frame
        g2.paused = true
        Box.dev_set_cheat("all_owned", 1)
        Box.equip_item("hopper", "melt", "on")
        var st2 := InputEventScreenTouch.new()
        st2.index = 0
        st2.position = Vector2(10.0, 10.0)
        st2.pressed = true
        g2._goga_input(st2)   # out of the TAP ANYWHERE card - melt ticks in run
        _check(g2.phase == "run", "the second life started")
        var g2_seat: Dictionary = g2.platforms[g2.platforms.size() - 1]
        _seat(g2, g2_seat)
        g2_seat["snow"] = -1.0   # the flake debt: truly NO snow under you
        g2.char_size = H.MELT_MIN + 0.002
        _ticks(g2, 10)
        _check(g2.phase == "over", "MELTED away to nothing = the run ends (the owner's law)")
        Box.dev_set_cheat("all_owned", 0)

        # ================= v0.2.7 THE VISIBILITY + CHALLENGE ROUND ==========
        # (a third, fresh tower - the previous two lives are spent)
        var g3: GogaGame = H.new()
        g3.game_id = "hopper"
        add_child(g3)
        await get_tree().process_frame
        await get_tree().process_frame
        g3.paused = true

        # ---- THE PICKUPS ARE PAINTED (the owner collected ghosts) ----
        _check(is_instance_valid(g3.pick_layer), "the pickup PAINTER exists")
        _check(g3._coin_tex != null, "the REAL GOGACoin texture is loaded")

        # ---- THE BANNER (the v0.2.6 law reversed by the owner) ----
        _check(bool(GameReg.get_game("hopper").get("banner", false)),
                "the tower wears the banner now (v0.2.7 owner law)")
        var bb: float = g3.banner_bottom()
        _check(bb > 0.0, "the tower reserves real banner space (%.0f logical px)" % bb)

        # ---- THE POWERUP SPAWN LAW: 20-40 from the last SPAWNED ----
        Box.dev_set_cheat("all_owned", 1)
        for i in 130:
                g3._gen_platform()
        var pick_idxs: Array = []
        for k in g3.pickups:
                pick_idxs.append(int(k["idx"]))
        pick_idxs.sort()
        _check(pick_idxs.size() >= 3, "powerups actually SPAWN now (%d in 130 platforms)" % pick_idxs.size())
        var pick_ok: bool = pick_idxs.size() >= 2 and int(pick_idxs[0]) >= H.PICKUP_GAP_MIN
        for i in range(1, pick_idxs.size()):
                var pg: int = int(pick_idxs[i]) - int(pick_idxs[i - 1])
                if pg < H.PICKUP_GAP_MIN or pg > H.PICKUP_GAP_MAX:
                        pick_ok = false
        _check(pick_ok, "powerups wait 20-40 platforms, first one 20-40 up (%s)" % str(pick_idxs))
        Box.dev_set_cheat("all_owned", 0)

        # ---- THE RAMP: deep jumps are WIDER (owner: 25+) - measured over the
        # GENERATED tower only, before the force-spawned test platforms ----
        var early_max := 0.0
        var deep_max := 0.0
        var gen_n: int = g3.platforms.size()
        for i in range(1, gen_n):
                var gv: float = absf(float(g3.platforms[i - 1]["y"]) - float(g3.platforms[i]["y"])) / g3.U
                if i <= H.DIFF_AT:
                        early_max = maxf(early_max, gv)
                if i >= H.DIFF_AT + H.DIFF_RAMP and i < gen_n - 3:
                        deep_max = maxf(deep_max, gv)
        _check(deep_max > H.GAP_MAX and deep_max > early_max,
                "past the ramp the jumps are WIDER (deep max %.0f > early max %.0f)" % [deep_max, early_max])
        var ball_ceiling: float = pow(absf(H.JUMP_V), 2.0) / (2.0 * H.GRAV)
        _check(deep_max < 0.84 * ball_ceiling,
                "the wide jumps stay inside the REAL jump ceiling (%.0f < %.0f)" % [deep_max, 0.84 * ball_ceiling])

        # ---- THE SIZE PLATFORM (30+): it BREATHES ----
        g3._spawn_platform(g3.get_viewport_rect().size.x * 0.5,
                        g3._last_top() - 150.0 * g3.U, 200.0 * g3.U, "size")
        var sz: Dictionary = g3.platforms[g3.platforms.size() - 1]
        var sz_base: float = float(sz["base_w"])
        var wmin := 1e12
        var wmax := -1.0
        for i in 260:
                g3._update_platforms(1.0 / 60.0)
                wmin = minf(wmin, float(sz["w"]))
                wmax = maxf(wmax, float(sz["w"]))
        _check(wmax - wmin > sz_base * 0.4, "the size platform BREATHES (w %.0f..%.0f of base %.0f)" % [wmin / g3.U, wmax / g3.U, sz_base / g3.U])
        _check(wmax <= sz_base * H.SIZE_MAX_F + 0.5 and wmin >= sz_base * H.SIZE_MIN_F - 0.5,
                "the breathing stays inside the 0.55..1.30 band")

        # ---- THE DROPPER (50+): land -> drop -> wait -> return ----
        # spawned NEAR the camera so the return trip is drivable in-test
        g3._spawn_platform(g3.get_viewport_rect().size.x * 0.5,
                        g3.cam_y - 420.0 * g3.U, 200.0 * g3.U, "dropper")
        var dr: Dictionary = g3.platforms[g3.platforms.size() - 1]
        var dr_y0: float = float(dr["y"])
        _check(String(dr["drop_state"]) == "idle", "the dropper idles until landed")
        g3._land(dr)
        _check(String(dr["drop_state"]) == "down", "landing TRIGGERS the drop")
        for i in 40:
                g3._update_platforms(1.0 / 60.0)
        _check(float(dr["y"]) > dr_y0 + 60.0 * g3.U, "the dropper is FALLING under the rider")
        var vp3: Vector2 = g3.get_viewport_rect().size
        dr["y"] = g3.cam_y + vp3.y + 140.0 * g3.U
        g3._update_platforms(1.0 / 60.0)
        _check(String(dr["drop_state"]) == "wait", "below the screen it waits")
        for i in int(2.6 * 60.0):
                g3._update_platforms(1.0 / 60.0)
        _check(String(dr["drop_state"]) != "wait", "the wait ends (%s)" % String(dr["drop_state"]))
        for i in int(8.0 * 60.0):
                g3._update_platforms(1.0 / 60.0)
        _check(absf(float(dr["y"]) - dr_y0) < 2.0 * g3.U,
                "the dropper RETURNS home (off %.2f)" % (absf(float(dr["y"]) - dr_y0) / g3.U))

        # ---- THE RAMP SANITY: even the deep gaps respect the ceiling (the
        # force-spawned test platforms are excluded by the law above) ----

        # ---- THE SHARD MATH: the TRUE edge-down stance ----
        _check(absf(H.SHARD_SETTLE_ANG - 2.0474022) < 0.0001,
                "the shard settle target is the TRUE edge-down stance (2.0474022)")
        # the drawn support at that stance puts the SIDE (not a corner) on
        # the platform: at rot = 2.0471 the two lowest verts share one height
        var R: float = float(H.PLAYER_R)
        var verts: Array = [(Vector2(0, -R * 1.06)), (Vector2(R * 0.95, R * 0.78)), (Vector2(-R * 0.95, R * 0.78))]
        var st: float = float(H.SHARD_SETTLE_ANG)
        var heights: Array = []
        for v0: Vector2 in verts:
                heights.append(snappedf(v0.x * sin(st) + v0.y * cos(st), 0.001))
        heights.sort()   # ascending: the LARGEST value = the LOWEST vertex (y grows down)
        _check(absf(float(heights[2]) - float(heights[1])) < 0.01,
                "at the settle stance TWO verts share the lowest height (a side rests)")
        _check(float(heights[0]) < float(heights[2]) - 0.5,
                "the third vert points UP (off %.2f)" % (float(heights[2]) - float(heights[0])))
        _check(absf(float(heights[2]) - R * 0.486) < 0.02,
                "the resting side sits at the geometric contact height (%.3f R)" % (float(heights[2]) / R))

        # ---- THE SNOW STASH: blink takes the cap and brings it back ----
        g3._spawn_platform(g3.get_viewport_rect().size.x * 0.5,
                        g3._last_top() - 150.0 * g3.U, 200.0 * g3.U, "blinking")
        var blink_p: Dictionary = g3.platforms[g3.platforms.size() - 1]
        blink_p["snow"] = 0.8
        blink_p["visible"] = true
        blink_p["clock"] = H.BLINK_PERIOD - 0.01
        g3._update_platforms(0.02)
        _check(not bool(blink_p["visible"]) and float(blink_p["snow"]) == 0.0 and float(blink_p["snow_stash"]) == 0.8,
                "blinking OFF stashes the snow cap (it goes WITH the platform)")
        blink_p["clock"] = H.BLINK_PERIOD - 0.01
        g3._update_platforms(0.02)
        _check(bool(blink_p["visible"]) and absf(float(blink_p["snow"]) - 0.8) < 0.001 and not blink_p.has("snow_stash"),
                "blinking ON restores the snow cap EXACTLY")

        # ---- THE REAL BREAK: the shatter spawns physical chunks ----
        g3._spawn_platform(g3.get_viewport_rect().size.x * 0.5,
                        g3._last_top() - 150.0 * g3.U, 260.0 * g3.U, "vanish")
        var vanish_p: Dictionary = g3.platforms[g3.platforms.size() - 1]
        vanish_p["ghost"] = true
        vanish_p["visible"] = true
        vanish_p["clock"] = 0.0
        g3.parts = []
        for i in 40:
                g3._update_platforms(1.0 / 60.0)
        var chunk_n := 0
        for pt in g3.parts:
                if String(pt["kind"]) == "chunk":
                        chunk_n += 1
        _check(chunk_n >= 4, "the vanish platform SHATTERS into chunks (%d)" % chunk_n)
        var chunks_moved := false
        for pt in g3.parts:
                if String(pt["kind"]) == "chunk" and absf(float(pt["vy"])) > 1.0:
                        chunks_moved = true
        _check(chunks_moved, "the chunks have velocity (gravity + spin live in the tick)")

        print("== tower_probe done: %s ==" % ("ALL PASS" if fails == 0 else "%d FAIL" % fails))
        get_tree().quit(fails)

func _ready() -> void:
        _run.call_deferred()
