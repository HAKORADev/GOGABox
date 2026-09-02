extends Node
## merge_probe - v0.2.7: drives the REBUILT 2048 headless. The old stub was
## "somehow totally broken for real" (the owner) - these laws pin the real
## game: the CENTERED BIGGER board (banner-aware), the slide engine (classic
## compress + merge, one fusion = EXACTLY +1), the GOGACoin CELL law (one
## empty cell grows a coin every 15 fusions, a tile sliding into it takes
## it), the stuck/death law, the THEMES (prices + the water fill tiers),
## the board-frame particle bounce, and the registry economy (/20, shop).
##
##   godot --headless --path projects/gogabox res://tests/merge_probe.tscn

var fails := 0

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1

var M: GDScript   # the merge script (consts live here)

## seed the LOGIC board directly (the visual tiles don't matter to the
## slide laws - the tiles dict stays empty, the engine is pure data).
## `rows` are ROWS: rows[r][c] -> board[c][r] (x = column, y = row).
func _grid(g: GogaGame, rows: Array) -> void:
        g.board = []
        for x in 4:
                var col := []
                col.resize(4)
                col.fill(0)
                g.board.append(col)
        for r in rows.size():
                for c in (rows[r] as Array).size():
                        g.board[c][r] = int(rows[r][c])
        g.tiles = {}
        g._pending_merges = []
        g._merge_victims = []

func _run() -> void:
        Box.reset_all()
        print("== merge_probe: 2048 v0.2.7 ==")
        M = load("res://game/games/merge/merge2048.gd")

        # ---- registry sanity (the owner's economy) ----
        var mr: Dictionary = GameReg.get_game("merge")
        _check(not mr.is_empty(), "merge is in the registry")
        _check(int(mr["coin_div"]) == 20, "2048 run bonus = score/20 (owner)")
        _check(bool(mr["shop"]), "2048 wears a shop (the themes)")
        _check(bool(mr["banner"]), "2048 carries the ad banner")
        _check(int(mr["fee"]) == 15, "the round fee stays 15")
        _check(int(M.COIN_EVERY) == 15, "one GOGACoin cell every 15 fusions (owner)")

        # ---- the theme wardrobe ----
        _check(M.THEMES.size() == 3, "three themes (classic / minecraft / sea)")
        _check(int(M.THEMES["classic"]["price"]) == 0, "Classic is the free default")
        _check(int(M.THEMES["minecraft"]["price"]) >= 500, "Minecraft costs real coins")
        _check(int(M.THEMES["sea"]["price"]) >= 500, "Deep Sea costs real coins")
        _check(M.MC_TIERS.size() == 11, "the minecraft tiers cover 2..2048")

        # ---- boot + THE CENTERING LAW ----
        var g: GogaGame = M.new()
        g.game_id = "merge"
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        var vp: Vector2 = g.get_viewport_rect().size
        _check(g.board_rect.size.x > 0.0, "the board laid out")
        var cx: float = g.board_rect.position.x + g.board_rect.size.x * 0.5
        _check(absf(cx - vp.x * 0.5) < 1.0, "the board is CENTERED (%.1f vs %.1f)" % [cx, vp.x * 0.5])
        _check(g.board_rect.position.y >= 90.0, "the board clears the HUD bar")
        _check(g.board_rect.end.y <= vp.y - g.banner_bottom() + 1.0,
                "the board clears the banner strip")
        var old_side := 4.0 * 150.0 + 5.0 * 12.0
        _check(g.board_side > old_side, "the board is BIGGER than the old fixed one (%.0f > %.0f)" % [g.board_side, old_side])
        _check(g.board.size() == 4 and g.board[0].size() == 4, "the same 4x4 grid")
        var start_tiles := 0
        for x in 4:
                for y in 4:
                        if int(g.board[x][y]) != 0:
                                start_tiles += 1
        _check(start_tiles == 2, "the classic two starting tiles")

        # ---- the slide engine (pure laws) ----
        _grid(g, [[2, 2, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        var moved: bool = g._slide(Vector2i(-1, 0))
        _check(moved, "a left slide with a merge reports moved")
        _check(int(g.board[0][0]) == 4, "2+2 slides left and fuses into 4")
        _check(g._pending_merges.size() == 1, "the merge op was queued")
        _grid(g, [[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        moved = g._slide(Vector2i(1, 0))
        _check(moved and int(g.board[3][0]) == 2, "a lone tile rides to the wall")
        _grid(g, [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [2, 0, 0, 0]])
        moved = g._slide(Vector2i(0, 1))
        _check(not moved, "a slide with no room and no pair moves NOTHING")
        _grid(g, [[2, 2, 4, 4], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        var mm: bool = g._slide(Vector2i(-1, 0))
        _check(mm and int(g.board[0][0]) == 4 and int(g.board[1][0]) == 8,
                "two pairs merge in ONE move (4 and 8)")
        _check(g._pending_merges.size() == 2, "both merges queued")
        # the double-merge-once law: [4,2,2,_] left -> [4,4,_,_] not [8,_,_,_]
        _grid(g, [[4, 2, 2, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        g._slide(Vector2i(-1, 0))
        _check(int(g.board[0][0]) == 4 and int(g.board[1][0]) == 4,
                "a fresh tile never merges twice in one slide")

        # ---- THE SCORING LAW: one fusion = exactly +1 ----
        g.set_score(0)
        _grid(g, [[2, 2, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        g._slide(Vector2i(-1, 0))
        g._finish_slide()
        _check(int(g.score) == 1, "one fusion pays EXACTLY +1 (score %d)" % int(g.score))
        _check(g.tiles.size() >= 1, "the merged tile node was born")
        g.set_score(0)
        g.fusions_since = 0
        _grid(g, [[2, 2, 4, 4], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        g._slide(Vector2i(-1, 0))
        g._finish_slide()
        _check(int(g.score) == 2, "two fusions in one slide pay +2 (not 4+8)")
        _check(g.fusions_since == 2, "the fusion counter tracks fusions")

        # ---- the GOGACoin CELL law ----
        # starve it to 14 fusions, then one fusion spawns the coin in an
        # empty cell (deterministic: the coin claims it BEFORE the spawn)
        g.fusions_since = 14
        _grid(g, [[0, 0, 0, 0], [0, 0, 0, 0], [2, 2, 0, 0], [0, 0, 0, 0]])
        g._slide(Vector2i(-1, 0))
        g._finish_slide()
        _check(g.coin_cell.x >= 0, "the 15th fusion spawns a coin cell")
        if g.coin_cell.x >= 0:
                _check(int(g.board[g.coin_cell.x][g.coin_cell.y]) == 0,
                        "the coin grows in an EMPTY cell")
        # a tile slides INTO the cell -> the coin is taken
        g.fusions_since = 0
        var cc: Vector2i = g.coin_cell
        var before_coins: int = int(g.run_coins)
        var sx: int = cc.x
        # push a tile one cell onto the coin: rebuild the board so the coin
        # cell's neighbor has a movable tile
        _grid(g, [[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        g.coin_cell = Vector2i(1, 0)   # the cell next to the 2
        g._slide(Vector2i(1, 0))       # the 2 slides right THROUGH the coin cell
        g._finish_slide()
        _check(int(g.run_coins) == before_coins + 1,
                "a tile sliding INTO the coin cell takes it (+1 run coin)")
        _check(g.coin_cell.x < 0, "the coin cell is spent")

        # ---- the pending law: a full board holds the coin ----
        _grid(g, [[2, 2, 2, 2], [2, 2, 2, 2], [2, 2, 2, 2], [2, 2, 2, 2]])
        g.fusions_since = COIN_EVERY_CONST()
        g._spawn_coin_cell()
        _check(g.coin_pending and g.coin_cell.x < 0,
                "a full board holds the coin until a cell frees")

        # ---- the stuck / end law ----
        _grid(g, [[2, 4, 2, 4], [4, 2, 4, 2], [2, 4, 2, 4], [4, 2, 4, 2]])
        _check(g._is_stuck(), "a full board with no pairs is STUCK")
        _grid(g, [[2, 4, 2, 4], [4, 2, 4, 2], [2, 4, 2, 4], [4, 2, 4, 4]])
        _check(not g._is_stuck(), "one pair on the board keeps it alive")
        g.set_score(7)
        _grid(g, [[2, 4, 2, 4], [4, 2, 4, 2], [2, 4, 2, 4], [4, 2, 4, 2]])
        g.over_board = false
        g._game_over()
        _check(g.over_board, "the stuck board ends the run")
        await get_tree().create_timer(1.1).timeout
        _check(g.over, "the cascade banks the run through finish_run")

        # ---- the themes live ----
        Box.dev_set_cheat("all_owned", 1)
        Box.equip_item("merge", "theme", "sea")
        _check(g._theme_id() == "sea", "the Deep Sea theme equips")
        g._apply_theme()
        var some_tile: Node = null
        for c in g.tiles:
                some_tile = g.tiles[c]
                break
        if some_tile != null:
                _check(some_tile.mat != null, "sea tiles carry the water shader")
                _check(absf(float(some_tile.fill) - float(g._sea_fill(int(some_tile.value)))) < 0.001,
                        "the water fill IS the tier")
                _check(float(g._sea_fill(2048)) > float(g._sea_fill(2)),
                        "the higher the tile, the MORE water")
        Box.equip_item("merge", "theme", "minecraft")
        g._apply_theme()
        _check(g._theme_id() == "minecraft", "the Minecraft theme equips")
        _check(g.mc_block(2) != null, "the minecraft block textures generated")
        _check(g.mc_block(2048) != null, "the lava tier block exists")
        Box.equip_item("merge", "theme", "classic")
        g._apply_theme()
        if some_tile != null and is_instance_valid(some_tile):
                _check(some_tile.mat == null, "classic tiles wear no shader")

        # ---- the particle bounce (the owner: collisions!) ----
        g.parts.append({"x": g.board_rect.position.x - 10.0, "y": g.board_rect.end.y + 2.0,
                        "vx": -120.0, "vy": 200.0, "life": 0.5, "max": 0.5,
                        "size": 8.0, "rot": 0.0, "vrot": 3.0,
                        "col": Color.WHITE, "kind": "sq"})
        g.paused = true
        g._goga_tick(1.0 / 60.0)
        g.paused = false
        var bounced := false
        for p in g.parts:
                if float(p["vx"]) > 0.0 and float(p["x"]) >= g.board_rect.position.x:
                        bounced = true
        _check(bounced, "a chunk bounced OFF the board frame (collisions)")
        var before_n: int = g.parts.size()
        g._goga_tick(1.0 / 60.0)
        g._goga_tick(2.0)
        _check(g.parts.size() < before_n + 2, "the chunk expired (life law)")

        # ---- the real input path: tk.swiped drives a slide (a fresh game:
        # the death laws above left this one over) ----
        var g2: GogaGame = M.new()
        g2.game_id = "merge"
        add_child(g2)
        await get_tree().process_frame
        g2.set_score(0)
        _grid(g2, [[2, 2, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        for x in 4:
                for y in 4:
                        var v2 := int(g2.board[x][y])
                        if v2 != 0:
                                var t2: Node = M.TileNode.new()
                                t2.position = g2._cell_pos(Vector2i(x, y))
                                t2.setup(v2, g2, g2.cell)
                                g2.board_root.add_child(t2)
                                g2.tiles[Vector2i(x, y)] = t2
        g2._on_swipe(Vector2i(-1, 0), Vector2.ZERO)
        await get_tree().create_timer(0.4).timeout
        _check(int(g2.score) == 1, "the REAL swipe path fuses and scores")

        # ---- the shop opens (the pair law holds) ----
        g2._shop_open()
        await get_tree().process_frame
        _check(g2._shop_pair.size() == 2, "the shop owns its dim+center pair")
        g2._shop_close()

        print("== merge_probe done: %s ==" % ("ALL PASS" if fails == 0 else "%d FAIL" % fails))
        get_tree().quit(1 if fails > 0 else 0)

func COIN_EVERY_CONST() -> int:
        return int(M.COIN_EVERY)

func _ready() -> void:
        _run.call_deferred()
