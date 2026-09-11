extends Node
## qa_v039rig - THE REAL-FINGER RIG (v0.3.9-1): the owner reported BOTH
## new games' controls as "like they are not existing" - the qa_v039
## probe calls _goga_input directly, but THIS rig drives the TRUE engine
## pipeline (Input.parse_input_event -> _unhandled_input -> tk.feed ->
## _goga_input) on the Xvfb rig, photographs every law with the GPU, and
## exits 0 = pass. The stills double as the owner's evidence sheet.

var fails := 0
var dir := "/tmp/film39"

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute(dir)
        print("=== qa_v039rig ===")
        # QA_RIG_PHASES filters the session (the Xvfb screen must match the
        # window: "fl,bv,chess" on a 1080x1920 screen, "domino" on a 2400x1080)
        var only := OS.get_environment("QA_RIG_PHASES")
        if only == "" or only.contains("fl"):
                await _fourline()
        if only == "" or only.contains("bv"):
                await _bovo()
        if only == "" or only.contains("domino"):
                await _domino_wide()
        if only == "" or only.contains("chess"):
                await _chess_tray()
        print("=== qa_v039rig RESULT: %s ===" % ("ALL PASS" if fails == 0
                        else "%d FAILURES" % fails))
        get_tree().quit(1 if fails > 0 else 0)

func _ck(cond: bool, why: String) -> void:
        print("  %s: %s" % ["PASS" if cond else "FAIL", why])
        if not cond:
                fails += 1

func _wait(t: float) -> void:
        await get_tree().create_timer(t).timeout

func _shot(name: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img: Image = get_viewport().get_texture().get_image()
        if img != null:
                img.save_png("%s/%s.png" % [dir, name])
        else:
                print("  SKIP shot %s (headless renders nothing)" % name)

func _touch(pos: Vector2, down: bool) -> void:
        var ev := InputEventScreenTouch.new()
        ev.position = pos
        ev.pressed = down
        ev.index = 0
        Input.parse_input_event(ev)

func _drag(pos: Vector2) -> void:
        var ev := InputEventScreenDrag.new()
        ev.position = pos
        ev.index = 0
        Input.parse_input_event(ev)

## scroll the topmost sheet's shelf (the sizes section sits below the
## fold in a fresh shop)
func _scroll_sheet(amount: float) -> void:
        var overlays: Array = []
        _collect(get_viewport(), overlays)
        for n in overlays:
                if n is ScrollContainer:
                        n.scroll_vertical = int(amount)
                        return

func _collect(root: Node, out: Array) -> void:
        out.append(root)
        for c in root.get_children():
                _collect(c, out)

func _boot(id: String, orientation := "") -> GogaGame:
        var g: GogaGame = load("res://game/games/%s/%s.gd" % [id, id]).new()
        g.game_id = id
        if orientation != "":
                g.start_orientation = orientation
        ScaleRule.apply(get_window())
        add_child(g)
        await _wait(0.3)
        return g

# ------------------------------------------------------- A. four in line
func _fourline() -> void:
        print("== A. FOUR IN LINE: the real finger ==")
        Box.reset_all()
        get_window().size = Vector2i(1080, 1920)
        ScaleRule.apply(get_window())
        await _wait(0.2)
        var g: GogaGame = await _boot("fourline")
        await _wait(0.6)
        await _shot("fl_gate")
        # the gate tap: a REAL event through the engine
        _touch(Vector2(540, 1500), true)
        _touch(Vector2(540, 1500), false)
        await _wait(0.35)
        _ck(g.state == "play",
                        "fl: a REAL gate tap started the round (state=%s)" % g.state)
        # THE DRAG-AND-DROP LAW: hold on col 2, slide to col 5 (the pong
        # follow), the ghost rides + the rail lights, release drops
        var fy: float = g.board_origin.y + 60.0
        _touch(Vector2(g.board_origin.x + 2.5 * g.cell, fy), true)
        await _wait(0.25)
        _drag(Vector2(g.board_origin.x + 5.5 * g.cell, fy))
        await _wait(0.3)
        _ck(g.aim_col == 5, "fl: the ghost follows the drag (aim_col=%d)"
                        % g.aim_col)
        await _shot("fl_drag")
        _touch(Vector2(g.board_origin.x + 5.5 * g.cell, fy), false)
        await _wait(1.1)
        _ck(int(g.board[g.idx(5, g.ROWS - 1)]) == 1,
                        "fl: the released disc dropped in the dragged column")
        await _shot("fl_dropped")
        # the finger leaves the board: the ghost must fade (aim_col clears)
        _touch(Vector2(g.board_origin.x + 5.5 * g.cell, fy), true)
        await _wait(0.2)
        _drag(Vector2(30.0, fy))
        await _wait(0.3)
        _ck(g.aim_col == -1, "fl: a finger off the board clears the aim")
        _touch(Vector2(30.0, fy), false)
        await _wait(1.6)
        await _shot("fl_mid")
        g.queue_free()
        await _wait(0.3)

# ------------------------------------------------------------ B. bovo
func _bovo() -> void:
        print("== B. FIVE IN ROW: the real finger + the sheets ==")
        Box.reset_all()
        get_window().size = Vector2i(1080, 1920)
        ScaleRule.apply(get_window())
        await _wait(0.2)
        var g: GogaGame = await _boot("bovo")
        await _wait(0.6)
        _touch(Vector2(540, 1500), true)
        _touch(Vector2(540, 1500), false)
        await _wait(0.35)
        _ck(g.state == "play",
                        "bv: a REAL gate tap started the round (state=%s)" % g.state)
        # tap an intersection: the drag previews the ghost, the tap places
        var pm: Vector2 = g._point_mid(g.idx(3, 3, g.grid_n))
        _drag(pm)
        await _wait(0.3)
        _ck(g.aim_i == g.idx(3, 3, g.grid_n),
                        "bv: the ghost rides the finger's point")
        await _shot("bv_ghost")
        _touch(pm, true)
        _touch(pm, false)
        await _wait(0.5)
        _ck(int(g.board[g.idx(3, 3, g.grid_n)]) == 1,
                        "bv: the tap placed the stone")
        await _shot("bv_placed")
        # THE HUD SEAT LAW: SHOP next to back, OPTIONS to its right
        var row := g._hud_row
        var texts: Array = []
        for c in row.get_children():
                        if c is Button:
                                        texts.append(String(c.text))
        var si: int = texts.find("SHOP")
        var oi: int = texts.find("OPTIONS")
        _ck(si >= 0 and oi == si + 1,
                        "bv: the HUD reads SHOP then OPTIONS to its right (%s)" % str(texts))
        # THE BUY LAW on film: buy the 10x10 (the wallet only), then the
        # shop row reads OWNED and points at the options
        Box.earn(9000)
        _ck(Box.buy_item("bovo", "size", "10", 1800), "bv: the 10x10 bought")
        _ck(g.grid_n == 8, "bv: the buy never touched the live board")
        g._shop_open()
        await _wait(0.6)
        await _shot("bv_shop_owned")
        # scroll the shelf to the BOARD SIZES section (the OWNED law reads
        # on film too)
        _scroll_sheet(900)
        await _wait(0.5)
        await _shot("bv_shop_sizes")
        g.sheet_pop()
        await _wait(0.4)
        g._options_open()
        await _wait(0.6)
        await _shot("bv_options")
        g.sheet_pop()
        await _wait(0.4)
        g.queue_free()
        await _wait(0.3)

# ------------------------------------------------------ C. domino wide
func _domino_wide() -> void:
        print("== C. DOMINO: the wide table eats the canvas ==")
        Box.reset_all()
        get_window().size = Vector2i(2400, 1080)
        ScaleRule.apply(get_window())
        await _wait(0.3)
        var g: GogaGame = await _boot("domino", "horizontal")
        await _wait(0.9)
        _ck(float(g.SCREEN_W) >= 2400.0,
                        "domino: SCREEN_W ate the wide canvas (%d)" % int(g.SCREEN_W))
        await _shot("domino_wide")
        g.queue_free()
        await _wait(0.3)

# ------------------------------------------------------- D. chess tray
func _chess_tray() -> void:
        print("== D. CHESS: the portrait graveyard reads ==")
        Box.reset_all()
        get_window().size = Vector2i(1080, 1920)
        ScaleRule.apply(get_window())
        await _wait(0.2)
        var g: GogaGame = await _boot("chess", "vertical")
        await _wait(0.7)
        for k in 6:
                        g.cap_w.append(5)
                        g.cap_b.append(5)
        g.fx_l.queue_redraw()
        await _wait(0.4)
        var slot: Rect2 = g._tray_slot(0, 0)
        _ck(slot.size.x >= 40.0,
                        "chess: the tray icons read at %dpx (was 8)" % int(slot.size.x))
        await _shot("chess_tray")
        g.queue_free()
        await _wait(0.2)
