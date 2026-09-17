extends Node
## dw_film - the DEADLY WORM visual verification rig (the Xvfb film law):
## boots the REAL game, photographs the intro sheet, taps to start, drives
## REAL swipes and dashes, photographs the surface hunt, the dive (the
## silhouette + the trail), the worms menu and the shop. The stills land
## in /tmp/dw_film for the eye pass.

var g: GogaGame = null
var T := 0.0
var beat := 0
var out_dir := "/tmp/dw_film"

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute(out_dir)
        Box.reset_all()
        var DW: GDScript = load("res://game/games/deathworm/deathworm.gd")
        g = DW.new()
        g.game_id = "deathworm"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().create_timer(0.6).timeout
        _snap("01_intro")

func _snap(name: String) -> void:
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [out_dir, name])
        print("dw_film: snapped %s" % name)

func _touch(pos: Vector2, down: bool) -> void:
        var e := InputEventScreenTouch.new()
        e.index = 0
        e.position = pos
        e.pressed = down
        g._goga_input(e)

func _drag(pos: Vector2) -> void:
        var e := InputEventScreenDrag.new()
        e.index = 0
        e.position = pos
        g._goga_input(e)

func _process(delta: float) -> void:
        if g == null:
                return
        T += delta
        match beat:
                0:
                        if T >= 0.8:
                                beat = 2
                                g._start_run()   # the tap-anywhere law
                2:
                        # the surface hunt: the worm starts deep - steer UP
                        # to the line and cruise it (the readable shot)
                        if T >= 1.6:
                                beat = 3
                                _touch(Vector2(300, 700), true)
                                _snap("02_hunt_start")
                3:
                        if T < 3.2:
                                _drag(Vector2(420, 260))
                        if T >= 4.4:
                                beat = 4
                                _snap("03_surface_hunt")
                4:
                        # the dive: drag down (the camera follows, the
                        # silhouette + the trail show)
                        if T >= 4.6:
                                beat = 5
                                _drag(Vector2(430, 860))
                5:
                        if T >= 7.0:
                                beat = 6
                                _snap("04_underground")
                6:
                        # a dash (right zone tap)
                        if T >= 7.3:
                                beat = 7
                                _touch(Vector2(1700, 540), true)
                7:
                        if T >= 7.45:
                                beat = 8
                                _touch(Vector2(1700, 540), false)
                8:
                        if T >= 8.4:
                                beat = 9
                                _snap("05_dash")
                                # open the WORMS menu (the top bar button)
                                g._open_worms()
                9:
                        if T >= 8.55:
                                beat = 10
                                pass
                10:
                        if T >= 8.6:
                                beat = 11
                                _snap("06_worms_menu")
                                g.sheet_pop()
                                g._worms_open = false
                11:
                        if T >= 9.4:
                                beat = 15
                                g._open_shop()
                15:
                        if T >= 10.8:
                                beat = 16
                                _snap("07_shop")
                                g.sheet_pop()
                                g._shop_open = false
                16:
                        if T >= 12.0:
                                _snap("08_back_to_run")
                                print("dw_film: DONE")
                                get_tree().quit(0)
