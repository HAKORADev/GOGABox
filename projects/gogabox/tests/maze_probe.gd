extends Node
## maze_probe - MAZE ESCAPER's headless law battery (v0.3.7).
## Every law from the GDD is asserted here: the REAL maze texture, the
## random ends, the scale cap, the time budget, the coin law, the finder
## economy, the swipe queue + the dynamic speed, the escape flow.

var checks := 0
var fails := 0
var G: GogaGame

func ck(cond: bool, what: String) -> void:
        checks += 1
        if cond:
                print("[PASS] ", what)
        else:
                fails += 1
                print("[FAIL] ", what)

func _vp() -> Vector2:
        return get_viewport().get_visible_rect().size

## The maze's texture stats: reachable cells + dead ends.
func _stats() -> Dictionary:
        var dead := 0
        var total: int = G.cols * G.rows
        for r in G.rows:
                for c in G.cols:
                        var walls: int = 0
                        for k in ["t", "b", "l", "r"]:
                                if G.cells[r][c][k]:
                                        walls += 1
                        if walls == 3:
                                dead += 1
        var reach: int = G.dist_map.size()
        return {"dead": dead, "total": total, "reach": reach}

func _run() -> void:
        print("=== maze_probe ===")
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        Box.dev_set_cheat("gogacoins", 0)
        Box.earn(5000)
        G = load("res://game/games/maze/maze.gd").new()
        G.game_id = "maze"
        add_child(G)
        await get_tree().create_timer(1.0).timeout

        # ------------------------------------------------ the REAL maze law
        var texture_ok := true
        var connect_ok := true
        var sol_ok := true
        for s in range(12):
                G.probe_reset(1000 + s)
                var st := _stats()
                if st["reach"] != st["total"]:
                        connect_ok = false     # the UST: every cell is live
                if float(st["dead"]) / float(st["total"]) < 0.16:
                        texture_ok = false     # a real maze has honest dead ends
                if G.solution.size() < 2:
                        sol_ok = false
        ck(connect_ok, "THE REAL MAZE LAW: every cell is woven into the tree (12 seeds)")
        ck(texture_ok, "THE REAL MAZE LAW: the corridors branch - honest dead ends (>=16%)")
        ck(sol_ok, "THE REAL MAZE LAW: every map carries a real solution")
        # the anti-python law: the solution is a THREAD, not the whole maze
        G.probe_reset(77)
        var sol_len: int = G.solution.size()
        var manhattan: int = absf(G.end_cell.x - G.start_cell.x) as int \
                + absf(G.end_cell.y - G.start_cell.y) as int
        ck(sol_len >= maxi(6, manhattan),
                "THE REAL MAZE LAW: the route winds (path %d >= manhattan %d)" % [sol_len, manhattan])

        # --------------------------------------------- the random ends law
        var starts := {}
        var ends := {}
        for s in range(10):
                G.probe_reset(2000 + s)
                starts[Vector2i(G.start_cell)] = true
                ends[Vector2i(G.end_cell)] = true
        ck(starts.size() >= 3 and ends.size() >= 4,
                "THE RANDOM ENDS LAW: starts (%d) and exits (%d) roll every map" % [starts.size(), ends.size()])
        var far_ok := true
        for s in range(8):
                G.probe_reset(3000 + s)
                var maxd := 0
                for k in G.dist_map:
                        maxd = maxi(maxd, int(G.dist_map[k]))
                if int(G.dist_map[G.end_cell]) < int(maxd * 0.6):
                        far_ok = false
        ck(far_ok, "THE RANDOM ENDS LAW: the exit always lives in the far band")

        # ---------------------------------------------------- the scale law
        G.probe_reset(41)
        var base_cols: int = G.cols
        G.map_i = 6
        G._new_map()
        ck(G.cols > base_cols, "THE SCALE LAW: the mazes grow with the maps")
        var cell_ok: bool = G.cell_px >= G.MIN_CELL * G.us - 0.5
        ck(cell_ok, "THE SCALE LAW: the cell never breaks the floor")
        var fits: bool = G.board.x >= 0.0 \
                and G.board.x + G.cell_px * G.cols <= G._vp().x + 1.0 \
                and G.board.y >= 0.0 and G.board.y + G.cell_px * G.rows <= G._vp().y + 1.0
        ck(fits, "THE SCALE LAW: the board fits the screen")
        # the CAP: a huge map index clamps the grid at the min cell
        G.map_i = 90
        G._new_map()
        var capped: bool = G.cell_px <= G.MIN_CELL * G.us + 0.5 \
                and G.board.x + G.cell_px * G.cols <= G._vp().x + 2.0 \
                and G.board.y + G.cell_px * G.rows <= G._vp().y + 2.0
        ck(capped, "THE SCALE LAW: the grid caps at the limit (map 90 still fits)")
        G.map_i = 0
        G._new_map()

        # ---------------------------------------------------- the time law
        var time_ok := true
        for s in range(8):
                G.probe_reset(4000 + s)
                var want: float = clampf(10.0 + G.solution.size() * 0.8, 24.0, 99.0)
                if absf(G.round_time - want) > 0.01:
                        time_ok = false
        ck(time_ok, "THE TIME LAW: the budget reads the map's real length (10 + 0.8/cell)")
        G.probe_reset(55)
        G.time_left = 0.005
        G.paused = false
        G.probe_step(1.0 / 60.0)
        ck(G.over_gate, "THE TIME LAW: the timeout ends the run")

        # ---------------------------------------------------- the coin law
        var coin_ok := true
        var coin_seen := 0
        for s in range(10):
                G.probe_reset(5000 + s)
                G.map_i = 4                     # the 5th map
                G._new_map()
                if G.coin.is_empty():
                        coin_ok = false
                        continue
                coin_seen += 1
                var on_path := false
                for p in G.solution:
                        if p == G.coin["cell"]:
                                on_path = true
                var near: int = int(G._cell_path_dist(G.coin["cell"]))
                if on_path or near < 1 or near > 2:
                        coin_ok = false
        ck(coin_ok and coin_seen == 10,
                "THE COIN LAW: every 5th map the coin waits 1-2 steps OFF the route (%d/10)" % coin_seen)
        G.probe_reset(5100)
        G.map_i = 3
        G._new_map()
        ck(G.coin.is_empty(), "THE COIN LAW: the other maps stay clean")

        # -------------------------------------------------- the finder law
        G.probe_reset(61)
        ck(G._finder_charges() == 0, "THE FINDER LAW: no escapes, no charges")
        G.map_i = 2
        ck(G._finder_charges() == 1, "THE FINDER LAW: +1 charge per 2 maps")
        G.map_i = 5
        ck(G._finder_charges() == 2, "THE FINDER LAW: 5 maps = 2 charges")
        G.finder_used = 1
        ck(G._finder_charges() == 1, "THE FINDER LAW: a tap spends a charge")
        G.finder_used = 0
        G.finder_left = G.FINDER_DUR
        var route: Array = G._finder_route()
        ck(route.size() >= 1 and route.size() <= 8,
                "THE FINDER LAW: the route lights up to %d cells (%d)" % [8, route.size()])
        var route_ok := true
        for cell in route:
                var on_sol := false
                for p in G.solution:
                        if p == cell:
                                on_sol = true
                if not on_sol:
                        route_ok = false
        ck(route_ok, "THE FINDER LAW: the lit cells ride the true solution")

        # --------------------------------------------- the swipe + speed law
        G.probe_reset(71)
        var wall_dir := Vector2i.ZERO
        var sc := Vector2i(G.start_cell)
        # find ANY wall of the start cell
        for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
                var key: String = "t" if d == Vector2i(0, -1) else ("b" if d == Vector2i(0, 1) \
                        else ("l" if d == Vector2i(-1, 0) else "r"))
                if G.cells[sc.y][sc.x][key]:
                        wall_dir = d
                        break
        var x0: float = G.player["x"]
        G._swipe_dir(wall_dir)
        for i in 12:
                G.probe_step(1.0 / 60.0)
        ck(absf(G.player["x"] - x0) < 0.5 and not G.moving,
                "THE SWIPE LAW: a wall eats the input, the square stays")
        # the speed law: a deeper queue moves faster
        G.probe_reset(72)
        var route0: Array = G._bfs_path(G.cells, G.start_cell, G.end_cell,
                G.cols, G.rows)
        var s0: Vector2i = G.start_cell
        G._swipe_dir(Vector2i(route0[1].x - s0.x, route0[1].y - s0.y))
        var dur1: float = G.move_dur
        # the deeper-queue ride: the next VALID route steps queued behind the
        # running move (a blind same-direction chain just eats walls)
        G._swipe_dir(Vector2i(route0[2].x - route0[1].x, route0[2].y - route0[1].y))
        G._swipe_dir(Vector2i(route0[3].x - route0[2].x, route0[3].y - route0[2].y))
        ck(G.queue.size() == 2, "THE SWIPE LAW: the inputs queue up")
        for i in 90:
                G.probe_step(1.0 / 60.0)
                if G.queue.size() <= 1 and G.moving:
                        break          # the SECOND move rides the deeper queue
        ck(G.move_dur < dur1,
                "THE SPEED LAW: the queue speeds the animation up (%.3f -> %.3f)" % [dur1, G.move_dur])
        for i in 240:
                G.probe_step(1.0 / 60.0)
        ck(not G.moving and G.queue.is_empty(),
                "THE SWIPE LAW: the queue drains step by step")

        # -------------------------------------------------- the escape flow
        G.probe_reset(81)
        var esc_ok := true
        G.time_left = 999.0            # the drive ignores the clock
        for maps in 3:
                var guard := 0
                while guard < 4000:
                        guard += 1
                        if G.score >= maps + 1:
                                break   # THE MAP ESCAPED - the next one woven
                        if not G.moving and G.queue.is_empty():
                                var from := Vector2i(G.player["c"], G.player["r"])
                                var route2: Array = G._bfs_path(G.cells, from,
                                        G.end_cell, G.cols, G.rows)
                                if route2.size() < 2:
                                        esc_ok = false
                                        break
                                var nxt: Vector2i = route2[1]
                                G._swipe_dir(Vector2i(nxt.x - from.x, nxt.y - from.y))
                        G.probe_step(1.0 / 60.0)
                        G.time_left = 999.0     # keep the clock out of the drive
                if G.score != maps + 1:
                        print("  .. drive stopped: map=%d score=%d guard=%d moving=%s q=%d at=%s end=%s over=%s" %
                                [G.map_i, G.score, guard, str(G.moving), G.queue.size(),
                                str(Vector2i(G.player["c"], G.player["r"])), str(G.end_cell), str(G.over_gate)])
                        esc_ok = false
                        break
        ck(esc_ok and G.score == 3 and G.map_i == 3,
                "THE ESCAPE LAW: driving the route escapes - 3 maps, +3 score, map 4 woven")
        # the coin collect pays the run's wallet (the payout lands at finish)
        G.probe_reset(91)
        G.map_i = 4
        G._new_map()
        if not G.coin.is_empty():
                var cc: Vector2i = G.coin["cell"]
                G.player["c"] = cc.x
                G.player["r"] = cc.y
                var rc0: int = G.run_coins
                G._arrived()
                ck(G.run_coins == rc0 + 1 and G.coin.is_empty(),
                        "THE COIN LAW: the coin pays a real run GOGACoin")
        else:
                ck(false, "THE COIN LAW: the coin map had no coin")

        # ------------------------------------------------- the registry law
        var mg: Dictionary = GameReg.get_game("maze")
        ck(not mg.is_empty() and int(mg["coin_div"]) == 3 \
                and String(mg["orientation"]) == "landscape",
                "THE REGISTRY LAW: Maze Escaper is playable - landscape, score /3")
        ck(G.SKINS.size() == 5 and G.THEMES.size() == 3,
                "THE SHOP LAW: 5 square skins / 3 maze themes / the finder")

        print("RESULT: %d checks, %d failures" % [checks, fails])
        print("RESULT: %s" % ("ALL LAWS HOLD" if fails == 0 else "LAWS BROKEN"))
        get_tree().quit(0 if fails == 0 else 1)

func _ready() -> void:
        _run()
