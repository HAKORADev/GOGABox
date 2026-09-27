extends Node
## rec_bovo - the AUTOMATED GAMEPLAY RIG (the rec_domino law): boots the
## REAL five in row, plays REAL stones through the game's own doors at a
## human-visible cadence, two full rounds, then quits. The Xvfb rig
## films it with x11grab. RIG_N=10/12 films the bigger boards.

var g: GogaGame = null
var beat := 0.0
var round_i := 0
var rounds_to_play := 2
var done := false
var hold := -1.0

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        var BVO: GDScript = load("res://game/games/bovo/bovo.gd")
        g = BVO.new()
        g.game_id = "bovo"
        var rig_n := OS.get_environment("RIG_N")
        if rig_n != "":
                g.size_id = rig_n
                g.grid_n = int(rig_n)
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
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
        g.state = "play"
        g.turn = 1

func _process(dt: float) -> void:
        if g == null or done:
                return
        g.probe_step(dt)
        beat += dt
        if beat < 1.25:
                return
        if g.state == "round_over":
                # THE BREATH LAW (see rec_fourline)
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
        # a REAL ply through the game's own door: a candidate point near
        # the action (the game's own near-law), never a taken point
        var cands: Array = g.candidate_cells(g.board, g.grid_n)
        if cands.is_empty():
                return
        var i: int = cands[randi() % cands.size()]
        g._place(i, 1)
