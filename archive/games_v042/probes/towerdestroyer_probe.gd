extends Node
## towerdestroyer_probe (v041-3) - THE LAWS OF THE FOUR-SEAT TOWER, nothing
## ships blind. The pure data (pacing, slots, the black landing law, the
## coin law, the CPU minds) over seeds, then the REAL host boot + the
## simulated play: the crew flow, the fire, the hit laws, the point law,
## the CPU death removing the seat accurately, the human death banking.
## Run: godot --headless --path . res://tests/towerdestroyer_probe.tscn

var ok := 0
var fails := 0

func _check(cond: bool, why: String) -> void:
        if cond:
                ok += 1
        else:
                fails += 1
                print("  FAIL: " + why)

func _ready() -> void:
        var TD: GDScript = load("res://game/games/towerdestroyer/towerdestroyer_data.gd")
        var rng := RandomNumberGenerator.new()

        # ---- the geometry constants (1u = 20 design px)
        _check(absf(float(TD.R_OUT) - 15.0) < 0.001, "R_OUT 15")
        _check(absf(float(TD.PITCH) - 5.5) < 0.001, "the pitch 5.5")
        _check(absf(float(TD.MUZZLE_Y) - 1.2) < 0.001, "the muzzle line 1.2")
        _check((TD.SEAT_ANGLES as Array).size() == 4, "four ground seats")
        for i in 4:
                var a: float = TD.SEAT_ANGLES[i]
                var covered := false
                for j in 4:
                        if i != j:
                                var d := absf(fposmod(a - float(TD.SEAT_ANGLES[j]) + PI, TAU) - PI)
                                if absf(d - PI * 0.5) < 0.001:
                                        covered = true
                _check(covered, "seat %d sits 90 degrees from a sibling" % i)

        # ---- the slot lottery over 400 seeds: bands close, content guaranteed
        var min_colored := 99
        var black_seen := 0
        var gap_seen := 0
        for s in 400:
                rng.seed = s
                var slots: Array = TD.build_slots(s % 120, rng)
                var colored := 0
                for sl in slots:
                        match String(sl["kind"]):
                                "colored": colored += 1
                                "black": black_seen += 1
                                "gap": gap_seen += 1
                min_colored = mini(min_colored, colored)
        _check(min_colored >= 4, "every platform carries >= 4 colored slots")
        _check(black_seen > 0 and gap_seen > 0, "black and gap slots both occur")

        # ---- hp grows with the depth and caps at 3
        _check(int(TD.segment_hp(0, 0.0)) == 1, "depth 0 wears hp 1")
        _check(int(TD.segment_hp(200, 0.0)) == 3, "deep platforms wear hp 3")
        _check(int(TD.segment_hp(19, 0.95)) == 3, "the tough roll adds a hit")

        # ---- slot_at: a partition law (every angle/rotation maps in range)
        var n := 11
        for r in 250:
                var rot := float(r) * 0.137
                var a := float(r) * 0.311
                var idx := int(TD.slot_at(a, rot, n))
                _check(idx >= 0 and idx < n, "slot_at in range")
        # and the seat read: a slot found by slot_at is the SAME slot twice
        var idx_a := int(TD.slot_at(1.0, 0.4, n))
        var idx_b := int(TD.slot_at(1.0, 0.4, n))
        _check(idx_a == idx_b, "the slot read is deterministic")

        # ---- THE BLACK LANDING LAW: exact, per seat
        var slots := []
        for i in 8:
                slots.append({"kind": "colored", "hp": 1})
        slots[0] = {"kind": "black"}
        slots[4] = {"kind": "gap"}
        # rot 0: the black owns the arc around angle 0
        _check(bool(TD.seat_killed(slots, 0.0, 0.0)), "black over the seat kills")
        _check(not bool(TD.seat_killed(slots, 0.0, PI)), "colored forgives")
        _check(not bool(TD.seat_killed(slots, PI, 0.0)),
                "the tower's rotation decides which seat the black lands on")
        _check(not bool(TD.seat_killed(slots, 0.0, PI * 1.0)), "the far seat lives")

        # ---- the speeds: different, growing, capped
        var seen := {}
        for s in 200:
                var sp: float = TD.platform_speed(1.0, float(s) / 200.0)
                seen[snappedf(sp, 0.01)] = true
        _check(seen.size() > 60, "the speed band is honestly wide")
        _check(float(TD.speed_base(0)) > 0.9 and float(TD.speed_base(500))
                > float(TD.speed_base(0)), "the base grows with the wreckage")
        _check(float(TD.speed_base(100000)) <= float(TD.SPEED_CAP), "the cap holds")

        # ---- the spin: both directions, readable speeds
        var neg := false
        var pos := false
        for s in 50:
                var sp: float = TD.spin_speed(0.5, 0.0 if s % 2 == 0 else 1.0)
                if sp < 0: neg = true
                else: pos = true
                if absf(sp) > float(TD.SPIN_MAX) + 0.001:
                        _check(false, "spin out of band")
        _check(neg and pos, "the tower spins both ways")

        # ---- the coin law: 200 exactly, every 200, never between
        for bad in [0, 1, 150, 199, 201, 399]:
                _check(not bool(TD.coin_due(bad)), "no coin at %d" % bad)
        for good in [200, 400, 600]:
                _check(bool(TD.coin_due(good)), "coin due at %d" % good)
        var cs := int(TD.coin_slot([{"kind": "black"}, {"kind": "colored", "hp": 1},
                {"kind": "gap"}, {"kind": "colored", "hp": 2}], rng))
        _check(cs == 1 or cs == 3, "the coin rides a COLORED slot only")

        # ---- the CPU minds: bounded, distinct, disciplined
        var leads := []
        var discs := []
        for s in 80:
                rng.seed = 1000 + s
                var p: Dictionary = TD.cpu_personality(rng)
                leads.append(float(p["detection_lead"]))
                discs.append(float(p["discipline"]))
                _check(float(p["reaction"]) >= 0.1 and float(p["reaction"]) <= 0.4,
                        "reaction inside the human band")
        _check(leads.max() - leads.min() > 0.2, "the CPUs do not share one eye")
        _check(discs.max() <= 0.96 and discs.min() >= 0.6, "discipline bounded")
        # the trigger truth table
        var p0: Dictionary = {"detection_lead": 0.5, "reaction": 0.1,
                "burst_len": 3, "burst_pause": 0.3, "discipline": 0.9}
        _check(bool(TD.cpu_wants_fire(p0, 0.3, 1.0, false, true, 0.0)),
                "an incoming colored segment pulls the trigger")
        _check(not bool(TD.cpu_wants_fire(p0, 5.0, 1.0, false, true, 0.0)),
                "a far platform waits (the detection lead)")
        _check(not bool(TD.cpu_wants_fire(p0, 0.3, 1.0, true, true, 0.0)),
                "black over the seat holds the fire (disciplined)")
        _check(bool(TD.cpu_wants_fire(p0, 0.3, 1.0, true, true, 0.999)),
                "the mistake roll fires into the armor (human)")

        print("[td probe] pure laws: %d ok, %d fails" % [ok, fails])
        _sim_play.call_deferred()

func _sim_play() -> void:
        var TD: GDScript = load("res://game/games/towerdestroyer/towerdestroyer_data.gd")
        var rng := RandomNumberGenerator.new()
        rng.seed = 7
        var GH: GDScript = load("res://game/core/game_host.gd")
        Box.reset_all()
        Box.earn(100000)
        Box.unlock_game("towerdestroyer", 0)
        var router := Node2D.new()
        add_child(router)
        _check(bool(GH.launch(router, "towerdestroyer")), "the game launches")
        # the loader is slower than 2s on the td asset set - POLL, never race
        var host: Node = null
        for i in 60:
                await get_tree().create_timer(0.25).timeout
                host = GH.active_host
                if host != null and is_instance_valid(host) and host.game != null:
                        break
        _check(host != null and host.game != null, "the host + the game live")
        if host == null or host.game == null:
                _finish()
                return
        var game: Node = host.game
        _check(String(game.get("phase")) == "players", "the crew ask is FIRST")
        # THE BACK LAW: back on the ask never closes it
        var stack_before: int = game.call("sheet_open_count")
        game.call("_back_pressed")
        await get_tree().create_timer(0.2).timeout
        _check(String(game.get("phase")) == "players", "back never closes the ask")
        _check(int(game.call("sheet_open_count")) == stack_before,
                "the ask sheet stayed")
        # the crew pick -> the ready card -> the run
        game.call("_pick_players", 4)
        await get_tree().create_timer(0.3).timeout
        _check(String(game.get("phase")) == "ready", "the ready card follows")
        game.call("_ready_go")
        await get_tree().create_timer(1.0).timeout
        _check(String(game.get("phase")) == "run", "the run started")
        # FREEZE THE TOWER for the exam: the live pacing must never decide the
        # probe's verdicts (the rig's own timing keeps running under its feet -
        # law 20: drain, then judge). Lift it too: the fire check needs a long
        # flight band so the balls LIVE at sampling time.
        var plats: Array = game.get("plats")
        for i in plats.size():
                var pp: Dictionary = plats[i]
                pp["speed"] = 0.0
                pp["y"] = 40.0 + float(i) * float(TD.PITCH)
        var seats: Array = game.get("seats")
        _check(seats.size() == 4, "the full crew sits (4 seats)")
        _check(not bool(seats[0]["is_cpu"]), "seat 0 is the human")
        var cpus := 0
        for s in seats:
                if bool(s["is_cpu"]):
                        cpus += 1
        _check(cpus == 3, "3 CPU gunners")
        # the four seats: correct world angles
        for i in seats.size():
                var s: Dictionary = seats[i]
                _check(absf(float(s["angle"]) - float(TD.SEAT_ANGLES[i])) < 0.001,
                        "seat %d wears its side" % i)
        # the tower is alive and fed
        _check(plats.size() >= int(TD.ALIVE_AHEAD) - 1, "the tower is fed")
        # THE FIRE: holding spawns balls
        game.set("holding", true)
        await get_tree().create_timer(0.5).timeout
        var balls: Array = game.get("balls")
        _check(balls.size() >= 2, "holding fires balls")
        game.set("holding", false)
        # DRAIN the air before the exam (law 20) - no stray ball may vote
        await get_tree().create_timer(1.6).timeout
        # THE HIT + POINT LAWS: a known platform with EXACTLY one breakable
        # segment covering the human's seat - one ball, one platform, one point
        var p: Dictionary = plats[0]
        p["y"] = 3.0           # the LOWEST band: just above the muzzle, below
                                # every other frozen platform - the first band
                                # the balls meet
        p["speed"] = 0.0       # hold it still for the exam
        p["spin"] = 0.0        # and unspinning - a rotating exam moves its slot
        p["rot"] = 0.0         # slot 0 covers world angle 0 = the human's seat
        var exam_slots: Array = []
        # TWO slots of arc PI: the spawn jitter (+-0.02 rad) wraps negative
        # angles to the last slot (fposmod) - with two half-circle slots every
        # volley ball kills slot 0 or slot 1, so the destroy is deterministic
        exam_slots.append({"kind": "colored", "hp": 1})
        exam_slots.append({"kind": "colored", "hp": 1})
        p["slots"] = exam_slots
        p["coin_slot"] = -1
        p["coin"] = null
        # rebuild the node meshes honestly
        if p["node"] != null and is_instance_valid(p["node"]):
                (p["node"] as Node3D).queue_free()
        game.call("_build_platform_node", p)
        var score_before: int = game.get("score")
        # fire a volley up the human's seat: the spawn jitter wraps negative
        # angles to the last slot (fposmod), so the volley covers every slot -
        # every ball dies inside the exam band, each killing its segment
        var human: Dictionary = seats[0]
        for i in 12:
                game.call("_fire_ball", human)
        await get_tree().create_timer(1.6).timeout
        _check(int(game.get("score")) == score_before + 1,
                "THE POINT LAW: the last hit banks +1")
        _check(int(game.get("run_destroyed")) == 1, "the run clock ticked")
        # THE COIN LAW, LIVE: the carrier spawns 2 platforms after 200
        game.set("run_destroyed", int(TD.COIN_AT))
        game.set("pending_coin", 2)
        game.call("_spawn_platform")     # pending 1
        game.call("_spawn_platform")     # pending 0 - the carrier
        var carrier := {}
        for pp in game.get("plats"):
                if int(pp["coin_slot"]) >= 0:
                        carrier = pp
        _check(not carrier.is_empty(), "the coin boarded a platform")
        _check(String((carrier.get("slots", [{}]) as Array)[int(carrier["coin_slot"])]["kind"]) \
                == "colored", "the coin rides a colored slot")
        # THE BLACK LAW, LIVE: a CPU dies under black, the human lives
        p = plats[0]
        p["y"] = float(TD.MUZZLE_Y) + 0.1
        p["speed"] = 100.0     # land it this tick
        var n2: int = (p["slots"] as Array).size()
        var arc := float(TD.slot_arc(n2))
        for i in n2:
                (p["slots"][i] as Dictionary)["kind"] = "gap"
        # black over seat 1's angle (PI/2): the slot index under that angle
        var seat1_angle: float = seats[1]["angle"]
        var rot := 0.0
        var idx1 := int(TD.slot_at(seat1_angle, rot, n2))
        (p["slots"][idx1] as Dictionary)["kind"] = "black"
        p["rot"] = rot
        p["spin"] = 0.0
        var cpu1_tag: Control = seats[1]["tag"]
        _check(cpu1_tag != null and is_instance_valid(cpu1_tag),
                "the CPU tag rides before death")
        await get_tree().create_timer(0.5).timeout
        _check(not bool(seats[1]["alive"]), "THE BLACK LAW: the CPU under black died")
        _check(bool(seats[0]["alive"]) and bool(seats[2]["alive"]),
                "the seats under gaps live")
        _check(String(game.get("phase")) == "run", "a CPU death never ends the run")
        var dead_tag_gone: bool = seats[1]["tag"] == null
        _check(dead_tag_gone, "the dead CPU's tag was removed accurately")
        # THE HUMAN DEATH: black over seat 0 banks the run
        var p3: Variant = null
        for pp in game.get("plats"):
                if float(pp["y"]) > float(TD.MUZZLE_Y) + 0.5:
                        p3 = pp
                        break
        if p3 != null:
                p3["y"] = float(TD.MUZZLE_Y) + 0.1
                p3["speed"] = 100.0
                var n3: int = (p3["slots"] as Array).size()
                for i in n3:
                        (p3["slots"][i] as Dictionary)["kind"] = "gap"
                var idx0 := int(TD.slot_at(0.0, 0.0, n3))
                (p3["slots"][idx0] as Dictionary)["kind"] = "black"
                p3["rot"] = 0.0
                p3["spin"] = 0.0
                await get_tree().create_timer(0.5).timeout
                _check(not bool(seats[0]["alive"]), "the human under black died")
                _check(bool(game.get("over")), "ONE black landing ends the run")
                await get_tree().create_timer(0.8).timeout
                _check(bool(game.get("over")), "the run banks (over stays)")
        # the /100 law lives through the host's own banker
        _check(int(host.call("_score_to_coins", 250)) == 2,
                "the host banks score/100 (250 -> 2)")
        host._quit_to_menu()
        await get_tree().create_timer(0.3).timeout
        _finish()

func _finish() -> void:
        print("[td probe] RESULT: %d ok, %d fails" % [ok, fails])
        get_tree().quit(0 if fails == 0 else 1)
