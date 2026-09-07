extends Node
## qa_v035p5 - the PATCH-6 Xvfb shot driver for the MULTI-GAME round.
## Rigs (QA_RIG env):
##   drop    - MATCHER drop down: the stream pouring parcels + the quota chips
##   jelly   - MATCHER jelly: the rolled SHAPE (never one flat line)
##   combo   - MATCHER: the DOUBLE SWEEP mid-action (bars + combo words)
##   prefill - MATCHER: the collected coin's seat REFILLED by itself
##   cs      - COSMIC SPUD: the engineer's drop-in ALIVE (drone + guard aura)
##   tower   - SNOWY TOWER: a live x2 + the widget + a pickup on screen
##   slash   - FRUIT SLASHER: the generous cut - halves flying mid-air
##   DISPLAY=:95 QA_RIG=drop godot --path . res://tests/qa_v035p5.tscn

var G: GogaGame

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1280, 720)
        ScaleRule.apply(get_window())
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "drop"
        match rig:
                "drop", "jelly", "combo", "prefill":
                        G = load("res://game/games/matcher/matcher.gd").new()
                        G.game_id = "matcher"
                "cs":
                        G = load("res://game/games/cosmic_spud/cosmic_spud.gd").new()
                        G.game_id = "cosmic_spud"
                "tower":
                        G = load("res://game/games/hopper/hopper.gd").new()
                        G.game_id = "hopper"
                "slash":
                        G = load("res://game/games/slasher/slasher.gd").new()
                        G.game_id = "slasher"
        add_child(G)
        await get_tree().create_timer(1.0).timeout
        match rig:
                "drop":
                        G._pick_close()
                        G._start_mode("drop")
                        await _wait(0.5)
                        # v0.3.5-6: the stream is MATCH-DRIVEN now - the
                        # opening lay already parked 2..4 parcels on the
                        # board; a hand-fed queue shows the drip
                        G.drop_total = 20
                        G.drop_spawned = 0
                        G.drop_queue = 2
                        if not G.grid[0][3].is_empty() and \
                                        is_instance_valid(G.grid[0][3].get("node")):
                                G.grid[0][3]["node"].queue_free()
                        G.grid[0][3] = {}
                        await _wait(1.2)
                "jelly":
                        G._pick_close()
                        G._start_mode("jelly")
                        await _wait(1.8)       # the pour + the shape refresh
                "combo":
                        G._pick_close()
                        G._start_mode("peace")
                        await _wait(0.3)
                        G.phase = "hold"
                        for r in 8:
                                for c in 8:
                                        if is_instance_valid(G.grid[r][c].get("node")):
                                                G.grid[r][c]["node"].queue_free()
                                        G.grid[r][c] = {}
                        for r in 8:
                                for c in 8:
                                        _mk(G, r, c, (c + 2 * r) % 5)
                        G.grid[3][3]["special"] = "rowh"
                        G.grid[4][3]["special"] = "rowh"
                        G._dress_special(3, 3)
                        G._dress_special(4, 3)
                        G.busy = false
                        G._try_swap(Vector2i(3, 3), Vector2i(4, 3))
                        await _wait(0.30)      # mid-sweep: bars + words live
                "prefill":
                        G._pick_close()
                        G._start_mode("peace")
                        await _wait(0.3)
                        G.phase = "hold"
                        # the coin collected leaves a seat - the prefill fills it
                        G.coin_clock = 0.0
                        G._tick_coin(0.016)
                        G.coin_queued = true
                        G.coin_col = 3
                        G.busy = true
                        await G._resolve_loop(Vector2i(-1, -1), Vector2i(-1, -1), {}, true)
                        G.busy = false
                        G.phase = "play"       # the physics falls only tick in play
                        await _wait(1.8)       # the pour completes - the seat reads FULL
                "cs":
                        G.start_id = "engineer"
                        G._start_run()
                        await _wait(0.4)
                        G._deploy_ally("guard", 1)
                        await _wait(2.6)       # the guard's aura breathes once
                "tower":
                        G.phase = "run"
                        G.pw = {"id": "x2", "t": 7.0}
                        G.pickups.append({"x": G.px + 120.0 * G.U, "y": G.py - 40.0 * G.U,
                                        "idx": 999, "kind": "big", "t": 0.0})
                        await _wait(0.5)
                "slash":
                        G._start_run()
                        await _wait(0.4)
                        G._launch("apple", Vector2(G.get_viewport_rect().size.x * 0.5,
                                        G.get_viewport_rect().size.y * 0.45))
                        await _wait(0.35)
                        for it in G.items.duplicate():
                                if String(it["kind"]) == "apple":
                                        var p: Vector2 = it["node"].position
                                        G._on_drag(p + Vector2(-140, 90), p + Vector2(140, -90))
                                        break
                        await _wait(0.12)      # the halves fly
        for i in 10:
                await get_tree().process_frame
        var shot := "user://qa_v035p5_%s.png" % rig
        var img := get_viewport().get_texture().get_image()
        img.save_png(shot)
        print("QA SHOT SAVED: ", shot)
        get_tree().quit(0)


func _mk(g: GogaGame, r: int, c: int, color: int) -> void:
        var n := Sprite2D.new()
        n.texture = g.tex_gem[color % g.tex_gem.size()]
        n.position = g._cell_pos(r, c)
        g.world.add_child(n)
        g.grid[r][c] = {"color": color, "special": "", "wing": false, "node": n}


func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout
