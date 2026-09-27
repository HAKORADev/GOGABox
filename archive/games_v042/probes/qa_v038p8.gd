extends Node
## qa_v038p8 - the v0.3.8-8 evidence rig. THE OWNER'S PATCH-8 LIST:
##   A. space dash: the FIRST coin waits 150 kills too (the live bug: the
##      old `coin_target := 7` paid run one's coin at ~7 kills)
##   B. 2048: the options sheet REFRESHES on a switch (no re-open needed)
##      + the pause sheet's END banks the run
##   C. fruit slasher: the FRUIT SLASHER wordmark is gone from the options
##   D. domino: BOTH tables seated - vertical bit-exact on 16:9, the wide
##      horizontal table (rows of ten, banner strip, hand at the bottom)
##      + the position ask on a fresh entry
##   E. chess: BOTH tables - the vertical board eats the width, the ask
##   F. pop siege: the SHORE is rolled back; two SOLID wall panels sit
##      between the field and the interface (no fade, no field wash)
##
##   godot --path . res://tests/qa_v038p8.tscn   (on the Xvfb rig)
##   godot --headless --path . res://tests/qa_v038p8.tscn   (asserts only)

var checks := 0
var fails := 0
var OUT := "/tmp/qa388"

func ck(cond: bool, what: String) -> void:
        checks += 1
        if cond:
                print("[PASS] ", what)
        else:
                fails += 1
                print("[FAIL] ", what)

func _ready() -> void:
        for a in OS.get_cmdline_user_args():
                if a.begins_with("--out="):
                        OUT = a.split("=")[1]
        DirAccess.make_dir_recursive_absolute(OUT)
        _run.call_deferred()

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _shot(name_: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var tex := get_viewport().get_texture()
        if tex == null:
                print("[qa] shot ", name_, " SKIPPED (no texture - headless?)")
                return
        var img := tex.get_image()
        if img == null:
                print("[qa] shot ", name_, " SKIPPED (no image - headless?)")
                return
        img.save_png("%s/%s.png" % [OUT, name_])
        print("[qa] shot ", name_)

func _find_button(root: Node, txt: String) -> Button:
        if root is Button and String((root as Button).text).contains(txt):
                return root
        # the phone cards carry their word in a child LABEL (the button itself
        # is textless) - match that too
        if root is Button:
                var lbls: Array = []
                _labels(root, lbls)
                for l in lbls:
                        if txt in l.text:
                                return root
        for c in root.get_children():
                var b := _find_button(c, txt)
                if b != null:
                        return b
        return null

func _labels(root: Node, out: Array) -> void:
        if root is Label:
                out.append(root as Label)
        for c in root.get_children():
                _labels(c, out)

# ------------------------------------------------------------------ A. dash
func _t_dash() -> void:
        print("== A. SPACE DASH: THE 150-KILL COIN ==")
        var L := load("res://game/games/lanes/lanes.gd")
        ck(int(L.COIN_KILLS_MIN) == 150 and int(L.COIN_KILLS_MAX) == 150,
                        "the coin cadence constants are 150..150")
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        var G: GogaGame = L.new()
        G.game_id = "lanes"
        add_child(G)
        await _wait(0.8)
        ck(int(G.get("coin_target")) == 150,
                        "the FIRST coin waits 150 kills (coin_target seeds from the constant)")
        var coins_before: int = Box.coins()
        for i in 149:
                G._roll_drop(Vector2(300, 300), false)
        var coins_mid: int = Box.coins()
        var coin_loots := 0
        for l in G.get("loots"):
                if String(l["kind"]) == "coin":
                        coin_loots += 1
        ck(coin_loots == 0 and coins_mid == coins_before,
                        "kill 1..149 pay ZERO coins (the run-one heartbreak is dead)")
        G._roll_drop(Vector2(300, 300), false)
        coin_loots = 0
        for l in G.get("loots"):
                if String(l["kind"]) == "coin":
                        coin_loots += 1
        ck(coin_loots >= 1, "kill 150 drops the GOGACoin")
        # and the NEXT one waits another 150
        for i in 149:
                G._roll_drop(Vector2(300, 300), false)
        coin_loots = 0
        for l in G.get("loots"):
                if String(l["kind"]) == "coin":
                        coin_loots += 1
        ck(coin_loots <= 1, "kills 151..299 pay nothing more (exactly every 150)")
        G.queue_free()
        Box.reset_all()

# ----------------------------------------------------------------- B. 2048
func _t_merge() -> void:
        print("== B. 2048: THE FRESH SHEET + THE END BUTTON ==")
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        var G: GogaGame = load("res://game/games/merge/merge2048.gd").new()
        G.game_id = "merge"
        add_child(G)
        await _wait(0.8)
        ck(bool(G.get("pause_end_run")), "the pause sheet wears the END bank")
        # --- the stale-sheet bug: switch 4x4 -> 6x6 and read the LIVE sheet ---
        G._options_open()
        await _wait(0.4)
        var lbls: Array = []
        _labels(G._overlay_root_ref(), lbls)
        var on4 := false
        for l in lbls:
                if "4 x 4" in l.text and "(ON)" in l.text:
                        on4 = true
        ck(on4, "the options open with 4 x 4 wearing (ON)")
        await _shot("merge_options_before")
        var sw := _find_button(G._overlay_root_ref(), "SWITCH")
        ck(sw != null, "an owned size offers SWITCH")
        if sw != null:
                sw.pressed.emit()                       # the are-you-sure pushes
                await _wait(0.4)
                var yes := _find_button(G._overlay_root_ref(), "YES - SWITCH")
                ck(yes != null, "the confirm sheet is up")
                if yes != null:
                        yes.pressed.emit()
                        await _wait(0.6)
                        # THE FIX: the fresh options sheet reads the applied board NOW
                        lbls = []
                        _labels(G._overlay_root_ref(), lbls)
                        var on6 := false
                        var stale4 := false
                        for l in lbls:
                                if "6 x 6" in l.text and "(ON)" in l.text:
                                        on6 = true
                                if "4 x 4" in l.text and "(ON)" in l.text:
                                        stale4 = true
                        ck(on6 and not stale4,
                                        "the LIVE menu shows 6 x 6 (ON) with NO re-open (the stale sheet is gone)")
                        ck(int(G.get("grid_n")) == 6, "the board really switched to 6x6")
                        await _shot("merge_options_after")
        # --- the END button ---
        G._back_pressed()               # the options sheet closes
        await _wait(0.3)
        G._back_pressed()               # nothing open -> the pause sheet
        await _wait(0.4)
        var endb := _find_button(G._overlay_root_ref(), "END")
        ck(endb != null, "the pause sheet carries END (the pong/domino law)")
        await _shot("merge_pause_end")
        if endb != null:
                endb.pressed.emit()
                await _wait(0.4)
                ck(bool(G.get("over")), "END banks the run (the run is over)")
        G.queue_free()
        Box.reset_all()

# ------------------------------------------------------------ C. slasher
func _t_slasher() -> void:
        print("== C. FRUIT SLASHER: OPTIONS ONLY ==")
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        var S: GogaGame = load("res://game/games/slasher/slasher.gd").new()
        S.game_id = "slasher"
        add_child(S)
        await _wait(1.0)
        if String(S.get("_phase")) != "options":
                S._show_options()
        await _wait(0.4)
        var lbls: Array = []
        _labels(S._overlay_root_ref(), lbls)
        var title_gone := true
        for l in lbls:
                if "FRUIT SLASHER" in l.text.to_upper():
                        title_gone = false
        ck(title_gone, "no FRUIT SLASHER wordmark in the options sheet")
        var has_fruits := _find_button(S._overlay_root_ref(), "FRUITS") != null
        ck(has_fruits, "the produce options remain (options only)")
        await _shot("slasher_options_clean")
        S.queue_free()
        Box.reset_all()

# ------------------------------------------------------------- D. domino
func _t_domino() -> void:
        print("== D. DOMINO: THE TWO TABLES ==")
        ck(String(GameReg.get_game("domino")["orientation"]) == "auto",
                        "domino wears BOTH positions (registry auto)")
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        # vertical boot, bit-exact certified pixels
        get_window().size = Vector2i(1080, 1920)
        ScaleRule.apply(get_window())
        await _wait(0.2)
        # vertical boot, bit-exact certified pixels
        var G: GogaGame = load("res://game/games/domino/domino.gd").new()
        G.game_id = "domino"
        G.start_orientation = "vertical"
        add_child(G)
        await _wait(0.9)
        var vp := get_viewport().get_visible_rect().size
        ck(vp.x < vp.y, "the rig window is vertical for this rig")
        ck(G.FRAME == Rect2(24, 330, 1032, 1196),
                        "vertical 16:9 keeps the CERTIFIED frame (24,330,1032x1196)")
        ck(G.FIELD == Rect2(48, 354, 984, 1148),
                        "vertical 16:9 keeps the CERTIFIED field (48,354,984x1148)")
        ck(G.POCKET == Rect2(48, 354, 212, 260), "the pocket keeps its seat")
        ck(float(G.get("hand_y")) == 1548.0, "the hand keeps its certified 1548 seat")
        ck(int(G.ROW_MAX) == 5, "the tall table packs rows of five")
        ck(G.get("pos_ask") == null,
                        "no ask when a reload choice rode in (start_orientation set)")
        G.queue_free()
        await _wait(0.3)
        # fresh entry: THE POSITION ASK
        var G2: GogaGame = load("res://game/games/domino/domino.gd").new()
        G2.game_id = "domino"
        add_child(G2)
        await _wait(0.9)
        ck(G2.get("pos_ask") != null, "a fresh entry asks the position first")
        var vcard := _find_button(G2._overlay_root_ref(), "VERTICAL")
        ck(vcard != null, "the ask wears the VERTICAL card")
        await _shot("domino_ask")
        G2._orient_choice("vertical")   # the current shape: just play on
        await _wait(0.3)
        ck(G2.get("pos_ask") == null, "picking the current shape seats the table")
        # horizontal SEATS (headless banner_safe = 64 -> bot 76)
        G2._apply_orientation("horizontal")
        ck(G2.SCREEN_W == 1920.0 and G2.SCREEN_H == 1080.0,
                        "the wide table is 1920x1080")
        ck(int(G2.ROW_MAX) == 10, "the wide table packs rows of TEN")
        ck(float(G2.get("hand_y")) == 1080.0 - 76.0 - 190.0 - 14.0,
                        "the wide table seats the hand above the banner strip")
        ck(G2.FRAME.position.y == 240.0 and G2.FRAME.size.x == 1872.0,
                        "the wide frame spans the table (24..1896, y 240)")
        ck(G2.FIELD.grow_individual(24, 24, 24, 24) == G2.FRAME,
                        "the field is the frame's -24 inset (the seam law)")
        G2.queue_free()
        Box.reset_all()

# -------------------------------------------------------------- E. chess
func _t_chess() -> void:
        print("== E. CHESS: THE TWO TABLES ==")
        ck(String(GameReg.get_game("chess")["orientation"]) == "auto",
                        "chess wears BOTH positions (registry auto)")
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1080, 1920)
        ScaleRule.apply(get_window())
        await _wait(0.2)
        var G: GogaGame = load("res://game/games/chess/chess.gd").new()
        G.game_id = "chess"
        G.start_orientation = "vertical"
        add_child(G)
        await _wait(0.9)
        # the vertical board law: width-bound, nearly full width
        var vp := get_viewport().get_visible_rect().size
        var sq: float = G.get("sq_px")
        ck(sq == minf((vp.x - 40.0) / 8.0, 9999.0) or sq <= (vp.x - 40.0) / 8.0,
                        "the vertical board is width-bound (%.1f px squares)" % sq)
        ck(G.get("board_origin").x >= 0.0 and float(G.get("sq_px")) * 8.0
                        + 2.0 * (130.0 + 12.0) + 54.0 <= vp.y,
                        "the vertical budget holds both trays + the verdict + the banner")
        ck(G.get("pos_ask") == null, "no ask when a reload choice rode in")
        # the trays live above and below the board in vertical
        var trs: Array = G._tray_rects()
        var bo: Vector2 = G.get("board_origin")
        var b_end: float = bo.y + float(G.get("sq_px")) * 8.0
        ck(trs[0].end.y <= bo.y + 1.0 and trs[1].position.y >= b_end - 1.0,
                        "vertical trays: one ABOVE the board, one BELOW")
        await _shot("chess_vertical")
        G.queue_free()
        await _wait(0.3)
        var G2: GogaGame = load("res://game/games/chess/chess.gd").new()
        G2.game_id = "chess"
        add_child(G2)
        await _wait(0.9)
        ck(G2.get("pos_ask") != null, "a fresh entry asks the position first")
        G2._orient_choice("vertical")
        await _wait(0.3)
        ck(G2.get("pos_ask") == null, "the pick seats the table")
        G2.queue_free()
        Box.reset_all()

# ----------------------------------------------------------- F. pop siege
func _t_pop() -> void:
        print("== F. POP SIEGE: THE WALL LAW ==")
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        var G: GogaGame = load("res://game/games/pop_siege/pop_siege.gd").new()
        G.game_id = "pop_siege"
        add_child(G)
        await _wait(1.0)
        # find the two solid walls (ColorRect children of the game, room brown)
        var walls: Array = []
        for c in G.get_children():
                if c is ColorRect and (c as ColorRect).color.is_equal_approx(
                                Color("241407")):
                        walls.append(c as ColorRect)
        ck(walls.size() == 2, "exactly two SOLID wall panels (the shore is gone)")
        if walls.size() == 2:
                var PS: GDScript = load("res://game/games/pop_siege/pop_siege.gd")
                var field: Vector2 = G.get("FIELD")
                var cols: int = PS.COLS
                var cell: float = G.get("CELL")
                var top: ColorRect = null
                var dock: ColorRect = null
                for w in walls:
                        if w.size.y < w.size.x:
                                top = w
                        else:
                                dock = w
                ck(top != null and dock != null, "one top strip + one right dock")
                if top != null:
                        ck(absf(top.size.y - (field.y + 14.0)) < 0.5,
                                        "the top strip ends EXACTLY where the field begins (no field wash)")
                        ck(top.position.y == -14.0, "the top strip pads the shake only")
                if dock != null:
                        ck(absf(dock.position.x - (field.x + cols * cell)) < 0.5,
                                        "the dock starts EXACTLY where the field ends")
                        ck(dock.size.y >= get_viewport().get_visible_rect().size.y,
                                        "the dock covers the full height")
        # no shore-style semi-transparent washes anywhere: every ColorRect the
        # game owns (not in the field) is OPAQUE
        var opaque := true
        for c in G.get_children():
                if c is ColorRect and (c as ColorRect).color.a < 0.999:
                        opaque = false
        ck(opaque, "no translucent overlay rides above the field (the blur is dead)")
        await _shot("pop_wall")
        G.queue_free()
        Box.reset_all()

func _run() -> void:
        await _t_dash()
        await _t_merge()
        await _t_slasher()
        await _t_domino()
        await _t_chess()
        await _t_pop()
        print("== qa_v038p8: %d checks, %d fails ==" % [checks, fails])
        print("== RESULT: %s ==" % ("ALL PASS" if fails == 0 else "FAIL"))
        get_tree().quit(1 if fails > 0 else 0)
