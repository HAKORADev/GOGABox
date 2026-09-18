extends Node
## v040-12 THE DW THUMBNAIL SHOOT - the owner: "making another one by
## doing in-game footage + programmed modifications will be much better".
## Boots the REAL game, sets up a dramatic composition (the worm bursting
## out of the crust under a fleeing walker), shoots RAW FOOTAGE frames,
## then the composer (tools/v0412_dw_thumb.py) grades, crops and titles
## them into the box thumbnail. The stills land in /tmp/dw_thumb.

var g: GogaGame = null
var T := 0.0
var beat := 0
var out_dir := "/tmp/dw_thumb"

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

func _snap(name: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [out_dir, name])
        print("dw_thumb: snapped %s" % name)

func _touch(pos: Vector2, down: bool) -> void:
        var e := InputEventScreenTouch.new()
        e.index = 0
        e.position = pos
        e.pressed = down
        g._goga_input(e)

func _process(delta: float) -> void:
        if g == null:
                return
        T += delta
        match beat:
                0:
                        if T >= 0.8:
                                beat = 1
                                g._start_run()
                1:
                        # stage the hunt: park the worm under the crust,
                        # seat prey on the line right above the head
                        if T >= 0.8:
                                beat = 2
                                g.pts[0] = Vector2(g.WORLD_W * 0.5,
                                        g.SURFACE_Y - 40.0)
                                for i in range(1, g.pts.size()):
                                        g.pts[i] = g.pts[0] \
                                                + Vector2(float(i) * 30.0,
                                                60.0 + float(i) * 8.0)
                                g.heading = -PI * 0.5
                                g.vel = Vector2(0.0, -620.0)
                                g.things.append({"kind": "human",
                                        "skin": "casual1",
                                        "x": g.pts[0].x + 30.0,
                                        "y": g._surf_seat("human"),
                                        "vx": -60.0, "fr": g.walk_frames(
                                        "casual1"), "fi": 0, "ft": 0.0,
                                        "alive": true, "flee": 0.0})
                                g.things.append({"kind": "animal",
                                        "skin": "camel",
                                        "x": g.pts[0].x + 260.0,
                                        "y": g._surf_seat("animal"),
                                        "vx": -80.0, "alive": true,
                                        "ft": 0.0, "frame": 0.0})
                2:
                        # the burst: let the mouth break the crust, then
                        # shoot the money frames
                        if T >= 1.05:
                                beat = 3
                                _snap("01_burst")
                3:
                        if T >= 1.25:
                                beat = 4
                                _snap("02_burst_high")
                4:
                        # the surface lunge with the mouth open
                        if T >= 1.9:
                                beat = 5
                                g.pts[0] = Vector2(g.pts[0].x,
                                        g.SURFACE_Y - 20.0)
                                g.heading = -0.35
                                g.vel = Vector2(360.0, -160.0)
                                g.mouth_open = true
                        if T >= 2.1:
                                beat = 6
                                _snap("03_lunge")
                6:
                        if T >= 2.4:
                                _snap("04_lunge_late")
                                print("dw_thumb: DONE")
                                get_tree().quit()
