extends Node
## rec_squares - the AUTOMATED GAMEPLAY RIG (the rec_domino law): boots the
## REAL SQUARES, plays REAL lines through the game's own doors at a
## human-visible cadence - press, drag, release through _goga_input (THE
## REAL-FINGER RIG law for the hold phases) - two full rounds, then quits.
## The Xvfb rig films it. RIG_D=6/8 films the bigger boards.

var g: GogaGame = null
var beat := 0.0
var round_i := 0
var rounds_to_play := 2
var done := false
var hold := -1.0
var pending_release := false
var release_at := Vector2.ZERO

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        var SQ: GDScript = load("res://game/games/squares/squares.gd")
        g = SQ.new()
        g.game_id = "squares"
        var rig_d := OS.get_environment("RIG_D")
        if rig_d != "":
                g.size_id = rig_d
                g.dots_n = int(rig_d)
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        # RIG_D lands AFTER the boot: _goga_setup (inside add_child)
        # resets size_id to "4"/the equipped size and would clobber any
        # pre-set (the rig filmed 4x4 forever while wearing the 6/8 ask)
        if rig_d != "":
                g._apply_size(rig_d)
        _soft_reset(11)

func _soft_reset(seed_v: int) -> void:
        if g.ready_ui != null and is_instance_valid(g.ready_ui):
                g.ready_ui.queue_free()
                g.ready_ui = null
        g.rounds = 0
        g.done_rounds = 0
        g.wins = 0
        g.losses = 0
        g.draws = 0
        g.score = 0
        g.set_score(0)
        g.run_coins = 0
        g.mem = []
        g.profile_i = 0
        g.paused = true
        g._rng.seed = seed_v
        g._layout(g.get_viewport_rect().size)
        g._new_round()

func _process(dt: float) -> void:
        if g == null or done:
                return
        g.probe_step(dt)
        # a pending finger lift lands one beat after its press (the hold)
        if pending_release:
                hold += dt
                if hold >= 0.45:
                        pending_release = false
                        var ev := InputEventScreenTouch.new()
                        ev.position = release_at
                        ev.pressed = false
                        g._goga_input(ev)
                return
        beat += dt
        if beat < 1.25:
                return
        if g.state == "round_over":
                # THE BREATH LAW: the verdict lives on film
                if hold < 0.0:
                        hold = 0.0
                        round_i += 1
                        if round_i >= rounds_to_play:
                                done = true
                                await get_tree().create_timer(2.4).timeout
                                get_tree().quit(0)
                                return
                hold += dt
                if hold < 2.3:
                        return
                hold = -1.0
                beat = 0.0
                _soft_reset(23 + round_i)
                return
        if g.state != "play" or g.turn != 1:
                return
        beat = 0.0
        # a REAL ply through the true pipeline: press near an undrawn safe
        # edge, drag onto it, release (the standby rides the finger)
        var safe: Array = g.safe_edges(g.edges, g.dots_n)
        if safe.is_empty():
                for i in g.edges.size():
                        if int(g.edges[i]) == 0:
                                safe.append(i)
                                break
        if safe.is_empty():
                return
        var e: int = safe[randi() % safe.size()]
        var seg: Array = g._edge_seg(e)
        var mid: Vector2 = (seg[0] + seg[1]) * 0.5
        var ev := InputEventScreenTouch.new()
        ev.position = mid
        ev.pressed = true
        g._goga_input(ev)
        release_at = mid
        pending_release = true
        hold = 0.0
