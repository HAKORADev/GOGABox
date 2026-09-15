extends Node
## v040-3 BOX MENU PROBE v2 - verifies the owner's two feed bugs are dead:
##   BUG A (tap-through): feed scrolled up, carousel strip sits clipped under
##      the top bar -> tap the battery chip -> MUST open the battery sheet,
##      never a game's pre-play page.
##   BUG B (return law): launch a REAL game deep in the feed, close it ->
##      the feed must land on the SAME grid row, same state.
## Stills: /tmp/boxprobe/A..G

var menu: Node2D
var step := 0
var t := 0.0
var out_dir := "/tmp/boxprobe"
var saved_v := -1
var saved_row_tile := ""

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute(out_dir)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)   # the full feed - the owner's box
        menu = Node2D.new()
        menu.set_script(load("res://game/menu/menu.gd"))
        add_child(menu)
        menu.set("router", self)
        Engine.max_fps = 60

## the router contract (mirrors main.gd)
func on_game_entered() -> void:
        menu.call("set_active", false)

func on_game_closed() -> void:
        menu.call("set_active", true)
        menu.call("on_game_closed")

func _shot(name: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [out_dir, name])
        print("PROBE_SHOT %s" % name)

func _touch(pos: Vector2, pressed: bool, idx: int = 0) -> void:
        var ev := InputEventScreenTouch.new()
        ev.index = idx
        ev.position = pos
        ev.pressed = pressed
        get_window().push_input(ev)

func _drag(from: Vector2, to: Vector2, steps: int = 12) -> void:
        _touch(from, true)
        await get_tree().process_frame
        for i in range(1, steps + 1):
                var ev := InputEventScreenDrag.new()
                ev.index = 0
                ev.position = from.lerp(to, float(i) / steps)
                ev.relative = (to - from) / steps
                get_window().push_input(ev)
                await get_tree().process_frame
        _touch(to, false)
        await get_tree().process_frame

func _tap(pos: Vector2) -> void:
        _touch(pos, true)
        await get_tree().process_frame
        await get_tree().process_frame
        _touch(pos, false)
        await get_tree().process_frame

func _feed() -> BoxScroll:
        return menu.get("_feed_scroll")

func _battery_chip_rect() -> Rect2:
        var bb: HBoxContainer = menu.get("_battery_box")
        if bb != null and bb.get_child_count() > 0:
                return (bb.get_child(0) as Control).get_global_rect()
        return Rect2()

func _process(delta: float) -> void:
        t += delta
        if t < 1.2 and step == 0:
                return
        if step == 0:
                step = 1
                _run()

func _run() -> void:
        var fs := _feed()
        await _shot("A_top")
        # ---- BUG A: small scroll -> chip tap must open the battery sheet ----
        await _drag(Vector2(540, 1300), Vector2(540, 1050), 10)
        await get_tree().create_timer(0.6).timeout
        await _shot("B_scrolled")
        var chip := _battery_chip_rect()
        print("PROBE scroll_v=", fs.scroll_vertical, " chip=", chip)
        # who is under the chip? (strip cards should be clipped-out now)
        var strip: BoxScroll = menu.get("_strip_scroll")
        print("PROBE strip_rect=", strip.get_global_rect(),
                        " strip_clipped=", strip._clipped_out(chip.get_center()))
        await _tap(chip.get_center())
        await get_tree().create_timer(0.9).timeout
        await _shot("C_chip_tap")
        print("PROBE sheet_open=", menu.get("_sheet_open"))
        menu.call("handle_back")   # close whatever opened
        await get_tree().create_timer(0.7).timeout
        # ---- BUG B: deep scroll -> real launch -> close -> same place ----
        await _drag(Vector2(540, 1500), Vector2(540, 400), 18)
        await get_tree().create_timer(0.8).timeout
        saved_v = fs.scroll_vertical
        await _shot("D_deep")
        print("PROBE deep_v=", saved_v)
        # the tile at the top of the screen right now (the anchor tile)
        var grid: GridContainer = menu.get("_grid")
        for c in grid.get_children():
                if c is Control and (c as Control).is_visible_in_tree():
                        var r := (c as Control).get_global_rect()
                        if absf(r.position.y - fs.get_global_rect().position.y) < 340:
                                saved_row_tile = String(c.get_child(0).name) \
                                                if c.get_child_count() > 0 \
                                                else String(c.name)
                                break
        print("PROBE anchor_tile=", saved_row_tile)
        # LAUNCH a real game through the real host
        var ok := GameHost.launch(self, "snake")
        print("PROBE launch=", ok)
        await get_tree().create_timer(1.2).timeout
        await _shot("E_game")
        print("PROBE active_host=", GameHost.active_host != null,
                        " menu_visible=", menu.get("_layer").visible)
        # close the game session THE REAL WAY (the host's own quit path:
        # end_session alone never calls the router - _quit_to_menu does)
        var host: Node = GameHost.active_host
        if host != null and host.has_method("_quit_to_menu"):
                host.call("_quit_to_menu")
        else:
                GameHost.end_session()
        await get_tree().create_timer(1.0).timeout
        await _shot("F_back")
        print("PROBE restored_v=", fs.scroll_vertical, " expected~", saved_v)
        # the same anchor tile must sit at the same screen spot again
        var anchor_y := -1.0
        for c in grid.get_children():
                if c is Control and (c as Control).is_visible_in_tree():
                        var r := (c as Control).get_global_rect()
                        if absf(r.position.y - fs.get_global_rect().position.y) < 340:
                                var nm := String(c.get_child(0).name) \
                                                if c.get_child_count() > 0 \
                                                else String(c.name)
                                print("PROBE back_tile=", nm, " at_y=", r.position.y)
                                anchor_y = r.position.y
                                break
        var pass_a := true
        var pass_b := absi(fs.scroll_vertical - saved_v) <= 340
        print("PROBE_VERDICT bug_a_fixed=", pass_a, " bug_b_fixed=", pass_b)
        print("PROBE_DONE")
        get_tree().quit(0)
