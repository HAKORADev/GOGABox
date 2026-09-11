extends Node
## rec_chess - THE AUTOMATED GAMEPLAY RIG, chess chapter. Boots the REAL
## game, probe-reset, and plays REAL plies through the game's own
## _apply_move door at a human-visible cadence while the CPU answers
## through its real think loop. The film shows the new W-D-L cards next
## to the score and the vertical two-line trays.

var g: GogaGame = null
var beat := 0.0
var plies := 0
var stop_plies := 70

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        g = load("res://game/games/chess/chess.gd").new()
        g.game_id = "chess"
        # v0.3.8-8: the rig films ONE table - RIG_ORIENT=vertical films the
        # tall war, the default keeps the classic landscape
        var rig_orient := OS.get_environment("RIG_ORIENT")
        g.start_orientation = rig_orient if rig_orient != "" else "horizontal"
        # v0.3.8-8: the rig decides the design from the REAL window px (the
        # bare boot skips the menu governor - a 1080x1920 window needs this
        # or the canvas stays landscape)
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        g.probe_reset(3)

func _process(dt: float) -> void:
        if g == null:
                return
        g.probe_step(dt)
        beat += dt
        if beat < 1.0:
                return
        beat = 0.0
        if g.state == "play":
                var mv: Array = g.legal_moves(g.st)
                if mv.is_empty():
                        get_tree().quit(0)
                        return
                g._apply_move(mv[plies % mv.size()], true)
                plies += 1
                if plies >= stop_plies:
                        await get_tree().create_timer(2.0).timeout
                        get_tree().quit(0)
