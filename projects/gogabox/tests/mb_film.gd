extends Node
## mb_film - the MARBLE POPPER visual verification rig (the Xvfb film law):
## boots the REAL game, photographs the intro, the path preview, live play
## with shots landing, the coin + pow carriers, both stages of the levels
## menu, the shop, the twin / slider / twin-path shooter modes, the cleared
## and lost cards, and a challenge wave. Stills land in /tmp/mb_film.

var g: GogaGame = null
var T := 0.0
var beat := 0
var out_dir := "/tmp/mb_film"

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute(out_dir)
        Box.reset_all()
        # grant the powers so the carriers can spawn (the shop law)
        for p in ["back", "bomb", "speed", "vapor", "rainbow", "lightning"]:
                Box.buy_item("marble", "power", p, 0)
        var MB: GDScript = load("res://game/games/marble/marble.gd")
        g = MB.new()
        g.game_id = "marble"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().create_timer(0.7).timeout
        _snap("01_intro")

func _snap(name: String) -> void:
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [out_dir, name])
        print("mb_film: snapped %s" % name)

func _tap(pos: Vector2) -> void:
        var down := InputEventScreenTouch.new()
        down.index = 0
        down.position = pos
        down.pressed = true
        g.tk.feed(down)
        var up := InputEventScreenTouch.new()
        up.index = 0
        up.position = pos
        up.pressed = false
        g.tk.feed(up)

func _origin() -> Vector2:
        return g.ORIGIN

func _chain_point(cp, d: float) -> Vector2:
        return cp.pos_at(d) + _origin()

func _process(delta: float) -> void:
        if g == null:
                return
        T += delta
        match beat:
                0:
                        if T >= 1.0:
                                # the first-run story card owns the screen - dismiss it
                                # (a real player taps PLAY), then the tap-anywhere law
                                g.box_story_dismiss()
                                await get_tree().create_timer(0.4).timeout
                                _tap(Vector2(540, 960))     # the tap-anywhere law
                                T = 0.0
                                beat = 1
                1:
                        # the path preview rolls
                        if T >= 0.7 and not has_meta("snapped02"):
                                set_meta("snapped02", true)
                                _snap("02_preview")
                        if T >= 1.8:
                                beat = 2
                                T = 0.0
                2:
                        # live play: the chain rolls in - photograph the early hunt
                        if T >= 2.2:
                                _snap("03_play_early")
                                beat = 3
                                T = 0.0
                3:
                        # shoot AT the chain front (a real insert attempt)
                        if T >= 0.2 and T < 2.0 and int(T * 10.0) % 5 == 0:
                                var cp = g.chains[0]
                                if cp.marbles.size() > 2:
                                        var front = cp.marbles.back()
                                        _tap(_chain_point(cp, float(front["d"]) + 30.0))
                        if T >= 2.4:
                                _snap("04_after_shots")
                                # force the coin + a pow carrier for the carrier shot
                                g.waves_since_coin = MarbleData.COIN_WAVES
                                g.coin_pending = true
                                g.pow_clock = 0.2
                                beat = 4
                                T = 0.0
                4:
                        if T >= 2.6:
                                _snap("05_carriers")
                                beat = 5
                                T = 0.0
                5:
                        # the LEVELS menu: places stage then levels stage
                        if T >= 0.2:
                                g._levels_open()
                                T = -99.0
                        if T >= -98.0 and T < -97.0:
                                T = -97.0
                                await get_tree().create_timer(0.3).timeout
                                _snap("06_levels_places")
                                g._levels_stage_levels(0)
                                await get_tree().create_timer(0.3).timeout
                                _snap("07_levels_levels")
                                g.sheet_pop()
                                g.sheet_pop()
                                beat = 6
                                T = 0.0
                6:
                        # the shop
                        if T >= 0.2:
                                g._shop_open()
                                T = -99.0
                        if T >= -98.0 and T < -97.0:
                                T = -97.0
                                await get_tree().create_timer(0.3).timeout
                                _snap("08_shop")
                                g.sheet_pop()
                                beat = 7
                                T = 0.0
                7:
                        # the twin-shooter level
                        if T >= 0.2:
                                g._pick_level(7, false)
                                T = -99.0
                        if T >= -98.0 and T < -97.0:
                                T = -97.0
                                await get_tree().create_timer(2.2).timeout
                                _snap("09_twin_spots")
                                # tap the OTHER spot (the swap fade law)
                                var other: Vector2 = g.twin_b + _origin()
                                _tap(other)
                                await get_tree().create_timer(0.6).timeout
                                _snap("10_twin_swapped")
                                beat = 8
                                T = 0.0
                8:
                        # the slider level: drag the totem along the bottom
                        if T >= 0.2:
                                g._pick_level(5, false)
                                T = -99.0
                        if T >= -98.0 and T < -97.0:
                                T = -97.0
                                await get_tree().create_timer(2.2).timeout
                                var down := InputEventScreenTouch.new()
                                down.index = 0
                                down.position = g.shooter.position + _origin()
                                down.pressed = true
                                g.tk.feed(down)
                                for k in 6:
                                        var dr := InputEventScreenDrag.new()
                                        dr.index = 0
                                        dr.position = g.shooter.position + _origin() + Vector2(60.0 * (k + 1), 0)
                                        g.tk.feed(dr)
                                var up := InputEventScreenTouch.new()
                                up.index = 0
                                up.position = g.shooter.position + _origin() + Vector2(360, 0)
                                up.pressed = false
                                g.tk.feed(up)
                                await get_tree().create_timer(0.3).timeout
                                _snap("11_slider_moved")
                                beat = 9
                                T = 0.0
                9:
                        # the twin-path level
                        if T >= 0.2:
                                g._pick_level(5, false)
                                T = -99.0
                        if T >= -98.0 and T < -97.0:
                                T = -97.0
                                await get_tree().create_timer(2.2).timeout
                                _snap("12_twin_paths")
                                beat = 10
                                T = 0.0
                10:
                        # the cleared card: pop everything (the quota spent)
                        if T >= 0.2:
                                var cp = g.chains[0]
                                cp.marbles.clear()
                                cp.spawned = cp.quota
                                T = -99.0
                        if T >= -98.0 and T < -97.0:
                                T = -97.0
                                await get_tree().create_timer(0.5).timeout
                                _snap("13_cleared_card")
                                beat = 11
                                T = 0.0
                11:
                        # the lost card: feed the idol
                        if T >= 0.2:
                                g._close_card()
                                g._start_level(0, false, 1)
                                T = -99.0
                        if T >= -98.0 and T < -97.0:
                                T = -97.0
                                await get_tree().create_timer(2.0).timeout
                                var cp = g.chains[0]
                                for i in 40:
                                        g._goga_tick(1.0 / 60.0)
                                if not cp.marbles.is_empty():
                                        var front = cp.marbles.back()
                                        front["d"] = cp.length + 1.0
                                await get_tree().create_timer(1.6).timeout
                                _snap("14_lost_card")
                                beat = 12
                                T = 0.0
                12:
                        # the challenge wave banner
                        if T >= 0.2:
                                g._close_card()
                                g._pick_level(0, true)
                                T = -99.0
                        if T >= -98.0 and T < -97.0:
                                T = -97.0
                                await get_tree().create_timer(2.0).timeout
                                _snap("15_challenge")
                                beat = 13
                                T = 0.0
                13:
                        # THE 20:9 SCALING EYE PASS: a taller window, same design
                        if T >= 0.3:
                                get_window().size = Vector2i(720, 1600)
                                await get_tree().create_timer(0.5).timeout
                                ScaleRule.apply(get_window())
                                await get_tree().create_timer(0.5).timeout
                                g._start_level(0, false, 1)
                                await get_tree().create_timer(2.4).timeout
                                _snap("16_tall_scale")
                                print("mb_film: DONE")
                                get_tree().quit(0)
