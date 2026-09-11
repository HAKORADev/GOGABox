extends SceneTree
## debug the 28-tile snake case for the v0.3.8-6 static ground

func _init() -> void:
        var DOM: GDScript = load("res://game/games/domino/domino.gd")
        var g: GogaGame = DOM.new()
        g.game_id = "domino"
        root.add_child(g)
        await process_frame
        await process_frame
        g.probe_reset(3)
        # fast-forward the deal
        for i in 400:
                g.probe_step(1.0 / 60.0)
                if g.state != "deal":
                        break
        g.chain.clear()
        for c in DOM.full_deck():
                g.chain.append({"a": int(c[0]), "b": int(c[1]), "fl": false,
                        "who": 1, "landed": true})
        g._relayout()
        g._settle_glide()
        print("board_rect=", g.board_rect, " fit=", g._fit_scale)
        var worst := 0
        for i in g.chain_rects.size():
                var rw: Rect2 = g.chain_rects[i]["rect"]
                if not g.board_rect.grow(2.0).encloses(rw):
                        print("OUTSIDE #%d %s" % [i, rw])
                        worst += 1
                for j in range(i + 1, g.chain_rects.size()):
                        if rw.grow(-0.6).intersects(
                                        (g.chain_rects[j]["rect"] as Rect2).grow(-0.6)):
                                print("OVERLAP #%d %s vs #%d %s" % [i, rw, j,
                                        g.chain_rects[j]["rect"]])
                                worst += 1
                                if worst > 6:
                                        break
                if worst > 6:
                        break
        print("worst count: ", worst)
        quit(0)
