extends Node
## v041-1 r2 probe: DEADLY WORM - THE ANYWHERE LAW (the owner: "tap
## anywhere screen is not actually anywhere"). The intro's tap door must
## answer on ANY pixel - the corners, the center, the content column -
## through the REAL input dispatch (parse_input_event -> Node._input),
## not a rigged direct call. The old per-control gui_input hooks were a
## dead-zone map (the dim-close law ate the dim taps, the content column
## had no handler at all).

const DW := "res://game/games/deathworm/deathworm.gd"
const POSITIONS := [
        ["corner_tl", Vector2(6, 6)],
        ["center", Vector2(540, 960)],
        ["corner_br", Vector2(1074, 1914)],
        ["content_left", Vector2(120, 1500)],
]

var g: GogaGame = null

func _ready() -> void:
        Box.reset_all()
        var win := get_window()
        ScaleRule.apply(win)
        var ft := win.get_final_transform()
        print("PROBE dw window=%s ft_scale=%s" % [
                        DisplayServer.window_get_size(), ft.get_scale()])
        var fails := 0
        for p in POSITIONS:
                var ok := await _one(true, ft * (p[1] as Vector2))
                print("PROBE dw_anywhere %s %s" % [p[0], "OK" if ok else "FAIL"])
                if not ok:
                        fails += 1
        # THE PC SEAT: a real left CLICK answers anywhere too
        var okm := await _one(false, ft * Vector2(6, 6))
        print("PROBE dw_anywhere mouse_click %s" % ("OK" if okm else "FAIL"))
        if not okm:
                fails += 1
        print("PROBE dw_anywhere_RESULT %s" % ("ALL OK" if fails == 0
                        else "%d FAILS" % fails))
        get_tree().quit()

## One boot + one tap. `touch` picks the seat (ScreenTouch vs MouseButton
## pressed - the game's two doors). The run must leave "intro".
func _one(touch: bool, window_pos: Vector2) -> bool:
        var DWL: GDScript = load(DW)
        g = DWL.new()
        g.game_id = "deathworm"
        add_child(g)
        var t := 0.0
        while t < 4.0 and g.state != "intro":
                await get_tree().process_frame
                t += get_process_delta_time()
        if g.state != "intro":
                print("PROBE dw boot never reached the intro")
                return false
        var ev: InputEvent
        if touch:
                var st := InputEventScreenTouch.new()
                st.index = 0
                st.pressed = true
                st.position = window_pos
                ev = st
        else:
                var mb := InputEventMouseButton.new()
                mb.button_index = MOUSE_BUTTON_LEFT
                mb.pressed = true
                mb.position = window_pos
                ev = mb
        Input.parse_input_event(ev)
        await get_tree().process_frame
        await get_tree().process_frame
        var started: bool = g.state != "intro"
        # hygiene: release the seat, then free the game so the next leg's
        # tap can never double-start a zombie
        var rel: InputEvent
        if touch:
                var st2 := InputEventScreenTouch.new()
                st2.index = 0
                st2.pressed = false
                st2.position = window_pos
                rel = st2
        else:
                var mb2 := InputEventMouseButton.new()
                mb2.button_index = MOUSE_BUTTON_LEFT
                mb2.pressed = false
                mb2.position = window_pos
                rel = mb2
        Input.parse_input_event(rel)
        await get_tree().process_frame
        g.queue_free()
        await get_tree().process_frame
        await get_tree().process_frame
        return started
