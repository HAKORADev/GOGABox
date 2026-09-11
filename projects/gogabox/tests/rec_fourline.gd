extends Node
## rec_fourline - the AUTOMATED GAMEPLAY RIG (the rec_domino law): boots
## the REAL four in line, plays REAL plies through the game's own doors
## at a human-visible cadence, two full rounds, then quits. The Xvfb rig
## films it with x11grab.

var g: GogaGame = null
var beat := 0.0
var round_i := 0
var rounds_to_play := 2
var done := false
var hold := -1.0

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        var FL: GDScript = load("res://game/games/fourline/fourline.gd")
        g = FL.new()
        g.game_id = "fourline"
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
        g._new_round()
        g.state = "play"
        g.turn = 1

func _process(dt: float) -> void:
        if g == null or done:
                return
        g.probe_step(dt)
        beat += dt
        if beat < 1.35:
                return
        if g.state == "round_over":
                # THE BREATH LAW: the round-over screen lives its full 2s
                # (the strike draws, the verdict reads) BEFORE the rig
                # resets or quits - the old same-tick reset froze the
                # strike at t=0 and the film never saw it
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
        # a REAL ply through the game's own door: pick a sensible column
        # (the middle-ish legal ones), let the drop physics play out
        var opts := []
        for c in g.COLS:
                if g.drop_row(g.board, c) >= 0:
                        opts.append(c)
        if opts.is_empty():
                return
        var col: int = opts[randi() % mini(3, opts.size()) + (opts.size() - mini(3, opts.size())) / 1]
        col = opts[randi() % opts.size()]
        g._drop_disc(col, 1)
        Jukebox.sfx("fl_tap", -6.0)
