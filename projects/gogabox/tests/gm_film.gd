extends Node
## gm_film - THE EVIDENCE RIG (the vision law: boot the real thing and LOOK
## at it). Runs GOLD MINER on the Xvfb window at 1080x1920 (the portrait
## design), drives REAL finger events through the engine queue, and
## photographs every beat:
##   01 the intro (logo + tap anywhere)   05 the bomb blast (lives drop)
##   02 the ground (rig + swing + items)  06 the clear -> next ground
##   03 the launch (claw flying)          07 the shop (the 5 + 5 shelf)
##   04 the reel (the grab + the dust)    08 the pause sheet (the END row)

var g: GogaGame = null
var shots := 0

func _snap(tag: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        var path := "/tmp/gm_film_%s.png" % tag
        img.save_png(path)
        shots += 1
        print("FILM: %s" % path)

func _tap(at: Vector2) -> void:
        var ev := InputEventScreenTouch.new()
        ev.position = at
        ev.pressed = true
        ev.index = 0
        Input.parse_input_event(ev)
        await get_tree().process_frame
        var ev2 := InputEventScreenTouch.new()
        ev2.position = at
        ev2.pressed = false
        ev2.index = 0
        Input.parse_input_event(ev2)
        await get_tree().process_frame

func _ready() -> void:
        Box.reset_all()
        Box.bump_counter("goldminer", "lore_start", 1)
        var GM: GDScript = load("res://game/games/goldminer/goldminer.gd")
        g = GM.new()
        g.game_id = "goldminer"
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().create_timer(0.5).timeout
        await _snap("01_intro")
        # the start tap -> the run
        await _tap(Vector2(540, 1500))
        await get_tree().create_timer(0.8).timeout
        await _snap("02_ground")
        # a real mid-swing launch: tap the field, photograph the flight
        var thrown := false
        for i in 40:
                if g.phase == "swing":
                        await _tap(Vector2(540, 1200))
                        thrown = true
                        break
                await get_tree().create_timer(0.05).timeout
        await get_tree().create_timer(0.22).timeout
        if thrown:
                await _snap("03_launch")
        var guard0 := 0
        while g.phase != "swing" and guard0 < 400:
                await get_tree().create_timer(0.05).timeout
                guard0 += 1
        # THE REEL: deterministic aim at the nearest gold (the free swing
        # cannot promise the line - the beat is forced, the pipeline is real)
        var gold: Dictionary = {}
        var best_d := 1e9
        for it in g.items:
                if String(it["kind"]).begins_with("gold"):
                        var dd: float = it["pos"].distance_to(g.anchor)
                        if dd < best_d:
                                best_d = dd
                                gold = it
        var reeled := false
        if not gold.is_empty():
                g.claw_dir = (gold["pos"] - g.anchor).normalized()
                g.phase = "fly"
                var guard1 := 0
                while guard1 < 600:
                        if g.phase == "reel" and not g.carried.is_empty():
                                reeled = true
                                break
                        if g.phase == "swing":
                                break
                        await get_tree().create_timer(0.02).timeout
                        guard1 += 1
        if reeled:
                await get_tree().create_timer(0.3).timeout
                await _snap("04_reel")
        var guard := 0
        while g.phase != "swing" and guard < 400:
                await get_tree().create_timer(0.05).timeout
                guard += 1
        # THE BLAST: seat a bomb on the line and THROW INTO IT (deterministic
        # aim - the blast itself rides the real pipeline)
        var bomb := {"kind": "bomb", "pos": g.anchor + Vector2(0, 700),
                "r": 40.0, "spr": null, "coin": false, "dying": false, "v": ""}
        var spr := Sprite2D.new()
        spr.texture = load("res://assets/games/goldminer/bomb.png")
        spr.position = bomb["pos"]
        (g.world.get_meta("items_layer") as Node2D).add_child(spr)
        bomb["spr"] = spr
        g.items.append(bomb)
        var lives0: int = g.lives
        g.claw_dir = (bomb["pos"] - g.anchor).normalized()
        g.phase = "fly"
        await get_tree().create_timer(0.55).timeout
        await _snap("05_blast")
        print("FILM: bomb lives %d -> %d" % [lives0, g.lives])
        guard = 0
        while g.phase != "swing" and guard < 400:
                await get_tree().create_timer(0.05).timeout
                guard += 1
        # THE CLEAR: wipe the golds, watch the next ground grow in
        var golds: Array = []
        for it in g.items:
                if String(it["kind"]).begins_with("gold"):
                        golds.append(it)
        for it in golds:
                g._destroy_item(it)
        g._check_cleared()
        await get_tree().create_timer(0.45).timeout
        await _snap("06_clear")
        await get_tree().create_timer(1.0).timeout
        await _snap("06b_next_ground")
        # THE SHOP: the 5 + 5 shelf
        g._shop_open()
        await get_tree().create_timer(0.4).timeout
        await _snap("07_shop")
        g.sheet_pop()
        await get_tree().create_timer(0.2).timeout
        # THE PAUSE SHEET: the END row (the owner's endless law)
        g._back_pressed()
        await get_tree().create_timer(0.4).timeout
        await _snap("08_pause")
        print("FILM DONE: %d shots" % shots)
        get_tree().quit(0)
