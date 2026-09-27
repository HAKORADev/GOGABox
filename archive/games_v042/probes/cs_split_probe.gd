extends Node
## cs_split_probe (v0.3.9-5) - THE SPLIT SIGHT + THE HEAVY KICK battery:
## two weapons + two enemies + the skill ON -> the slots claim DIFFERENT
## prey; the skill OFF -> both hunt one target. The kick: cannon shots
## walk out of line as the heat climbs, and cool back down.

var fails := 0
var G: GogaGame = null

func ck(cond: bool, what: String) -> void:
        print("  %s: %s" % ["PASS" if cond else "FAIL", what])
        if not cond:
                fails += 1

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1920, 1080)
        await get_tree().create_timer(0.2).timeout
        G = load("res://game/games/cosmic_spud/cosmic_spud.gd").new()
        G.game_id = "cosmic_spud"
        add_child(G)
        await get_tree().create_timer(1.0).timeout
        print("=== cs_split_probe ===")
        await _run()

func _run() -> void:
        var CSData: GDScript = load("res://game/games/cosmic_spud/cs_data.gd")
        # ---- THE SPLIT SIGHT: skill OFF -> every gun hunts ONE prey
        G.weapons_run = [{"id": "smg", "tier": 1, "cd": 0.0},
                        {"id": "rifle", "tier": 1, "cd": 0.0}]
        G.enemies = []
        var e1: Dictionary = G._spawn_enemy("blab", G.p_pos + Vector2(180, 0))
        var e2: Dictionary = G._spawn_enemy("blab", G.p_pos + Vector2(0, 220))
        G._tick_weapons(0.001)
        var t1: Variant = G.weapons_run[0].get("target")
        var t2: Variant = G.weapons_run[1].get("target")
        ck(t1 == null and t2 == null,
                "no skill: the slots claim nobody (the shared best path)")
        # ---- the skill ON at level 1 (2 guns): DISTINCT claims
        G.meta.d["skills"] = {"split_sight": 1}
        G._tick_weapons(0.001)
        t1 = G.weapons_run[0].get("target")
        t2 = G.weapons_run[1].get("target")
        ck(t1 != null and t2 != null and t1 != t2,
                "SPLIT SIGHT L1: two weapons claim two DIFFERENT enemies")
        # the nearest-first law: slot 1 (smg, 300px range 300) takes the
        # close one when it can
        ck(t1 == e1 or t2 == e1,
                "the close enemy is one of the two claims")
        # ---- L5 with 2 guns: both still split (the cap is the gun count)
        G.meta.d["skills"] = {"split_sight": 5}
        G._tick_weapons(0.001)
        t1 = G.weapons_run[0].get("target")
        t2 = G.weapons_run[1].get("target")
        ck(t1 != t2, "SPLIT SIGHT L5: the split holds")
        # ---- one enemy only: slot 0 claims it, slot 1 finds nothing to
        # split and falls back to the SHARED best at fire time
        G.enemies = [e1]
        G._tick_weapons(0.001)
        t1 = G.weapons_run[0].get("target")
        t2 = G.weapons_run[1].get("target")
        ck(t1 == e1 and (t2 == null or t2 == e1),
                "one prey left: both guns hunt it together")
        ck(G._fire_weapon(G.weapons_run[1]),
                "the fallback slot fires the shared prey on demand")
        # ---- THE HEAVY KICK: the cannon's heat climbs and cools
        G.enemies = [e1]
        G.weapons_run = [{"id": "cannon", "tier": 1, "cd": 0.0}]
        var w: Dictionary = G.weapons_run[0]
        var shots := 0
        var angles: Array = []
        for i in 6:
                w["cd"] = 0.0
                var straight: float = (e1["pos"] - G.p_pos).angle()
                G._fire_weapon(w)
                angles.append(G.bullets[G.bullets.size() - 1]["a"] - straight)
                shots += 1
        var heat_at := float(w["heat"])
        ck(shots == 6 and heat_at > 0.55,
                "the rapid cannon heats up (%.2f after %d shots)" % [heat_at, shots])
        var walked := false
        for a in angles:
                if absf(float(a)) > 0.0005:
                        walked = true
        ck(walked, "the heavy shots walk OUT OF LINE shot to shot")
        # the cool: a second of NO FIRING sheds the heat (move the prey
        # out of range first so the tick fires nothing)
        e1["pos"] = G.p_pos + Vector2(4000, 0)
        G._tick_weapons(1.0)
        ck(float(w["heat"]) < heat_at - 0.25,
                "the barrel cools when the firing stops (%.2f)" % float(w["heat"]))
        # the smg (not heavy) never heats
        G.weapons_run = [{"id": "smg", "tier": 1, "cd": 0.0}]
        G._fire_weapon(G.weapons_run[0])
        ck(float(G.weapons_run[0].get("heat", 0.0)) == 0.0,
                "the light guns keep their line (no kick)")
        print("=== cs_split_probe: %s ===" % ("PASS" if fails == 0
                        else "%d FAILS" % fails))
        get_tree().quit(0 if fails == 0 else 1)
