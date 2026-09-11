extends Node
## rec_domino - the AUTOMATED GAMEPLAY RIG (the owner: "really play the
## games and run them for real with automated gameplays and record video
## and take the data from it"). Boots the REAL domino game, plays REAL
## plies through the game's own placement / draw / pass doors at a
## human-visible cadence, two full rounds, then quits. The Xvfb rig
## films it with x11grab.

var g: GogaGame = null
var beat := 0.0
var round_i := 0
var rounds_to_play := 2
var done := false
var dump_t := 3.0

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        var DOM: GDScript = load("res://game/games/domino/domino.gd")
        g = DOM.new()
        g.game_id = "domino"
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        _soft_reset(11)

## probe_reset's reset law WITHOUT the deal fast-forward - the film must
## SEE the deal flights
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
        g.state = "play"
        g.spread = false
        g.yard_rects = []
        g.paused = true
        g._rng.seed = seed_v
        g._new_round()
        g.state = "deal"

func _process(dt: float) -> void:
        if g == null or done:
                return
        g.probe_step(dt)
        beat += dt
        if beat < 1.1:
                return
        dump_t += dt
        if dump_t > 4.0:
                dump_t = 0.0
                var dump := ""
                for t3 in g.chain:
                        dump += "(%.0f,%.0f,v=%s,f=%s|%s) " % [float(t3.get("px", -1)),
                                        float(t3.get("py", -1)), str(t3.get("pv", "?")),
                                        int(t3.get("a", -1)), int(t3.get("b", -1))]
                var rts := ""
                for cr in g.chain_rects:
                        rts += "%.0fx%.0f " % [(cr["rect"] as Rect2).size.x,
                                        (cr["rect"] as Rect2).size.y]
                print("[poses] ", dump, "| rects: ", rts)
        if g.state == "round_over":
                round_i += 1
                if round_i >= rounds_to_play:
                        done = true
                        await get_tree().create_timer(2.0).timeout
                        get_tree().quit(0)
                        return
                beat = 0.0
                _soft_reset(23 + round_i)
                return
        if g.state != "play" or g.turn != g.P:
                return
        beat = 0.0
        var e: Vector2i = g.ends(g.chain)
        var opts: Array = g.playable(g.hand_p, e.x, e.y)
        if g.opening:
                var hi := 0
                for i in g.hand_p.size():
                        if g._is_opener(i):
                                hi = i
                                break
                g._place(g.P, hi, 2)
        elif opts.is_empty():
                if g.deck.size() > 0:
                        g._draw_tile(g.P)
                else:
                        g._pass(g.P)
        else:
                var i2: int = opts[0]
                var cp: int = g.can_play(g.hand_p[i2], e.x, e.y)
                g._place(g.P, i2, 1 if (cp & 1) != 0 else 2)
