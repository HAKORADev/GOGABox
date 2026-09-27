extends Node
## qa_v038p5 - the v0.3.8-5 Xvfb shot driver (the parlor room + the wow
## table). Rigs (QA_RIG env):
##   domino_play   - the tile classic mid-war: honest driven tiles, the
##                   wow body art, the snake with its elbow, the fan
##   domino_spread - the same + the TWO-ROW yard fan held open (the
##                   owner's mini fix, verified live)
##   chess_board   - the parlor room mid-war: driven honest moves (trades
##                   feed the graveyard trays), goals row, green/old squares
##   chess_open    - the parlor room at the opening position
##   chess_first   - dump the tree + shot right after the probe reset
##
##  QA_RIG=<rig> xvfb-run -a godot --path . res://tests/qa_v038p5.tscn

var G: GogaGame
var _drive: RefCounted = null
var _t := 0.0

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "domino_play"
        var portrait := rig.begins_with("domino")
        get_window().size = Vector2i(1080, 1920) if portrait \
                        else Vector2i(1920, 1080)
        ScaleRule.apply(get_window())
        seed(7)
        RenderingServer.set_default_clear_color(Color.RED)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        Box.dev_set_cheat("gogacoins", 0)
        Box.earn(5000)
        var script := "res://game/games/domino/domino.gd" if portrait \
                        else "res://game/games/chess/chess.gd"
        G = load(script).new()
        G.game_id = "domino" if portrait else "chess"
        G.start_orientation = "vertical" if portrait else "horizontal"  # v0.3.8-8: ask suppressed
        add_child(G)
        _drive = load("res://dev/thumb_capture/drives/%s_drive.gd"
                        % ("domino" if portrait else "chess")).new()
        _drive.game = G
        # the bisect rig: hide whole branches to find the white painter
        var hide := OS.get_environment("QA_HIDE")
        if hide == "hud":
                for c in G.get_children():
                        if c is CanvasLayer:
                                (c as CanvasLayer).visible = false
        elif hide == "world":
                G.world.visible = false
        elif hide == "bgl":
                G.bg_l.visible = false
        elif hide == "board":
                G.board_l.visible = false
        elif hide == "piece":
                G.piece_l.visible = false
        elif hide == "fx":
                G.fx_l.visible = false
        await _wait(1.0)
        if portrait:
                # walk the honest flow: the drive taps the ready gate itself
                for i in int(13.0 * 60.0):
                        _t += 1.0 / 60.0
                        _drive.tick(_t)
                        await get_tree().process_frame
                        if rig == "domino_spread" and absf(_t - 8.0) < 0.008:
                                G.spread = true
                                G._relayout()
                        if rig == "domino_spread" and absf(_t - 10.2) < 0.008:
                                G.spread = false
                                G._relayout()
                        # v0.3.8-5 R2 THE HOLE RIG: the fan opens, slot 3 is TAKEN
                        # (its own hole stays), the face flies to the hand - the shot
                        # proves the exact-tap law: the hole sits where the tile left
                        if rig == "domino_hole" and absf(_t - 8.0) < 0.008:
                                G.spread = true
                                G._relayout()
                        if rig == "domino_hole" and absf(_t - 10.2) < 0.008:
                                G._player_take(3)
                        if rig == "domino_hole" and absf(_t - 10.6) < 0.008:
                                G.spread = true
                                G._relayout()
        else:
                G.probe_reset(11)
                G.paused = false
                G.get_tree().paused = false
                await _settle(4)
                if rig == "chess_first":
                        _dump(G, 0)
                        var img0 := get_viewport().get_texture().get_image()
                        img0.save_png("user://qa_v038p5_chess_first.png")
                        print("QA SHOT SAVED: user://qa_v038p5_chess_first.png")
                        get_tree().quit(0)
                for i in int(12.0 * 60.0):
                        _t += 1.0 / 60.0
                        _drive.tick(_t)
                        await get_tree().process_frame
        for i in 8:
                await get_tree().process_frame
        var shot := "user://qa_v038p5_%s.png" % rig
        var img := get_viewport().get_texture().get_image()
        img.save_png(shot)
        print("QA SHOT SAVED: ", shot)
        get_tree().quit(0)

func _dump(n: Node, d: int) -> void:
        if d > 4:
                return
        var info := ""
        if n is CanvasItem:
                info = " vis=%s z=%d" % [(n as CanvasItem).visible,
                                (n as CanvasItem).z_index]
        print("%s%s %s%s" % ["  ".repeat(d), n.get_class(), n.name, info])
        for c in n.get_children():
                _dump(c, d + 1)

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _settle(frames: int) -> void:
        for i in frames:
                await get_tree().process_frame
