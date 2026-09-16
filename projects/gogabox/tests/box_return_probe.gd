extends Node
## v040-5 BOX RETURN PROBE - the owner's "closing a game returns you a
## little up" worked to the bone. The v040-3 probe passed with a +-340px
## tolerance - the owner's eye is not that forgiving. This probe:
##   * scrolls the feed to MISALIGNED offsets (a tile half under the top
##     edge - the real-world case the 40px anchor law lost),
##   * snapshots + closes through the REAL host path,
##   * requires the return to be EXACT (+-2px) on the scroll value AND on
##     the anchor tile's screen offset,
##   * repeats with the strip lists CHANGED (a play recorded mid-run) -
##     the anchor tile must hold the same screen spot regardless.

var menu: Node2D
var step := 0
var t := 0.0
var out_dir := "/tmp/boxreturn"
var cases: Array = []
var case_i := 0
var saved_v := -1
var saved_off := -1.0
var saved_tile := -1
var fail_count := 0

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

func _feed() -> BoxScroll:
        return menu.get("_feed_scroll")

func _grid() -> GridContainer:
        return menu.get("_grid")

## the tile that owns the top edge (the straddler) + its screen offset
func _anchor() -> Array:
        var fs := _feed()
        var feed_top := fs.get_global_rect().position.y
        var best_i := -1
        var best_y := -1e12
        var first_i := -1
        var first_y := 0.0
        var idx := 0
        for c in _grid().get_children():
                if c is Control and (c as Control).is_visible_in_tree():
                        var y := (c as Control).get_global_rect().position.y
                        if first_i == -1 and y > feed_top:
                                first_i = idx
                                first_y = y - feed_top
                        if y <= feed_top and y > best_y:
                                best_y = y
                                best_i = idx
                idx += 1
        if best_i != -1:
                return [best_i, best_y - feed_top]
        return [first_i, first_y]

func _process(delta: float) -> void:
        t += delta
        if t < 1.4 and step == 0:
                return
        if step == 0:
                step = 1
                _run()

func _run() -> void:
        var fs := _feed()
        # the scroll range the rig ACTUALLY has - the cases ride it, always
        # misaligned with the 326px tile pitch (never a clean row boundary)
        var sb := fs.get_v_scroll_bar()
        var mx := maxf(60.0, sb.max_value - sb.page)
        cases = [roundf(mx * 0.23) + 7.0, roundf(mx * 0.41) + 3.0,
                roundf(mx * 0.57) + 11.0, roundf(mx * 0.73) + 5.0,
                mx - 13.0, mx - 1.0]
        for target in cases:
                # a settled scroll at an arbitrary (misaligned) offset
                fs.scroll_vertical = int(target)
                await _settle()
                var v := fs.scroll_vertical
                var a: Array = _anchor()
                saved_v = v
                saved_tile = int(a[0])
                saved_off = float(a[1])
                print("PROBE case_v=", v, " tile=", saved_tile, " off=%.1f" % saved_off)
                # LAUNCH + CLOSE through the real host path (snake: fast)
                var ok := GameHost.launch(self, "snake")
                if not ok:
                        print("PROBE_VERDICT exact=false reason=launch_failed")
                        get_tree().quit(1)
                        return
                await get_tree().create_timer(0.9).timeout
                var host: Node = GameHost.active_host
                if host != null and host.has_method("_quit_to_menu"):
                        host.call("_quit_to_menu")
                await get_tree().create_timer(1.1).timeout
                var v2 := fs.scroll_vertical
                var a2: Array = _anchor()
                var dv := absi(v2 - saved_v)
                var doff := absf(float(a2[1]) - saved_off)
                var tile_ok: bool = int(a2[0]) == saved_tile
                var good: bool = dv <= 2 and doff <= 2.0 and tile_ok
                if not good:
                        fail_count += 1
                print("PROBE case_result restored_v=", v2, " dv=", dv,
                        " tile=", int(a2[0]), " doff=%.1f" % doff,
                        " good=", good)
                await _settle()
        # ---- second pass: the strip lists CHANGE (a run recorded) while the
        # owner is inside the game - the anchor tile must hold its spot ----
        var target2 := 1073.0
        fs.scroll_vertical = int(target2)
        await _settle()
        var v3 := fs.scroll_vertical
        var a3: Array = _anchor()
        saved_v = v3
        saved_tile = int(a3[0])
        saved_off = float(a3[1])
        # the run that happened inside the game: plays + last-played change
        Box.record_run("snake", 421)
        Box.record_run("pong", 12)
        var ok2 := GameHost.launch(self, "snake")
        await get_tree().create_timer(0.9).timeout
        var host2: Node = GameHost.active_host
        if host2 != null and host2.has_method("_quit_to_menu"):
                host2.call("_quit_to_menu")
        await get_tree().create_timer(1.1).timeout
        var v4 := fs.scroll_vertical
        var a4: Array = _anchor()
        var dv2 := absi(v4 - saved_v)
        var doff2 := absf(float(a4[1]) - saved_off)
        var good2: bool = dv2 <= 2 and doff2 <= 2.0
        if not good2:
                fail_count += 1
        print("PROBE changed_lists restored_v=", v4, " dv=", dv2,
                " doff=%.1f" % doff2, " good=", good2)
        print("PROBE_VERDICT exact=", fail_count == 0, " fails=", fail_count)
        print("PROBE_DONE")
        get_tree().quit(0 if fail_count == 0 else 1)

func _settle() -> void:
        for i in 6:
                await get_tree().process_frame
