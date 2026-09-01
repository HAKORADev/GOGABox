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

	# ---- generation laws ----
	var gen_ok := true
	var rel_ok := true
	var UNRELIABLE := ["blinking", "vanish", "mb"]
	for i in range(1, g.platforms.size()):
		var p: Dictionary = g.platforms[i]
		var lo: float = float(p["x"]) - float(p["w"]) / 2.0
		var hi: float = float(p["x"]) + float(p["w"]) / 2.0
		if lo < H.WALL_W * g.U - 0.5 or hi > vp.x - H.WALL_W * g.U + 0.5:
			gen_ok = false
		var gapv: float = absf(float(g.platforms[i - 1]["y"]) - float(p["y"]))
		if gapv < H.GAP_MIN * g.U - 1.0 or gapv > H.GAP_MAX * g.U + 1.0:
			gen_ok = false
		if UNRELIABLE.has(String(g.platforms[i - 1]["type"])) and UNRELIABLE.has(String(p["type"])):
			rel_ok = false
	_check(gen_ok, "every platform sits between the walls at a legal gap")
	_check(rel_ok, "THE RELIABILITY LAW: an unreliable platform is always followed by a reliable one")
	var reach_ok := true
	for i in range(1, g.platforms.size()):
		var dx: float = absf(float(g.platforms[i]["x"]) - float(g.platforms[i - 1]["x"]))
		if dx > H.WALK_MAX * g.U * (absf(H.JUMP_V * g.U) / (H.GRAV * g.U)) * 1.2:
			reach_ok = false
	_check(reach_ok, "every next platform stays inside the jump arc's reach")

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

	# ---- landing + THE SCORING LAW ----
	_seat(g, g.platforms[0])
	_ticks(g, 3)
	_check(g.grounded, "the ball lands on the start platform")
	_check(int(g.score) == 1, "the first landing pays +1 (highest ever)")
	# land on a LOWER platform: pays NOTHING
	var low: Dictionary = g.platforms[2]
	g.grounded = false
	g.px = float(low["x"])
	g.py = float(low["y"]) - H.PLAT_H * g.U * 0.5 - H.PLAYER_R * g.U - 60.0
	g.vy = 300.0 * g.U
	_ticks(g, 10)
	var s_before: int = g.score
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
	_seat(g, g.platforms[g.platforms.size() - 1])
	g.snow_load = 0.0
	g._do_jump()
	_check(not g.grounded and g.vy < 0.0, "the jump circle jumps (one press, one jump)")
	var hops_before: int = g.hops
	_ticks(g, 2)
	g._do_jump()
	_check(g.hops == hops_before, "a second press in the air does NOTHING without x2")
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
	# big jump: apex multiplier (load zeroed - the law is the multiplier)
	_seat(g, g.platforms[g.platforms.size() - 2])
	g.snow_load = 0.0
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
	g.char_id = "square"
	g.tumble_rot = 0.0
	g.tumble_acc = 0.0
	for i in 150:
		_seat(g, spin_seat)
		g.move_dir = 1
		g._goga_tick(DT)
	g.move_dir = 0
	var quarter_turns := absf(g.tumble_rot) / (PI / 2.0)
	_check(absf(quarter_turns - roundf(quarter_turns)) < 0.01 and absf(g.tumble_rot) > 0.1,
			"the cube tumbles in EXACT 90-degree steps (%.2f turns)" % quarter_turns)
	if g.phase != "run":
		print("  [TRACE] the run died right after: cube")
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

	print("== tower_probe done: %s ==" % ("ALL PASS" if fails == 0 else "%d FAIL" % fails))
	get_tree().quit(fails)

func _ready() -> void:
	_run.call_deferred()
