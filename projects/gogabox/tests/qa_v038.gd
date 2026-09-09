extends Node
## qa_v038 - the v0.3.8 Xvfb shot driver (the owner's "many visual tests"
## law). Rigs (QA_RIG env):
##  dom_ready  - DOMINO: the tap-anywhere gate on the tavern felt
##  dom_mid    - DOMINO: a live chain with the end glows + a lifted tile
##  dom_shop   - DOMINO: the direct shop sheet (tiles + tables)
##  dom_gate   - DOMINO: the gate-truth rig (live round -> shop round-trip:
##               no gate over the game, live boneyard label, felt toast)
##  chs_ready  - CHECKMATE: the tap-anywhere gate on the walnut board
##  chs_mid    - CHECKMATE: legal-move dots + the last-move tint + a check
##  chs_shop   - CHECKMATE: the direct shop sheet (pieces + boards)
##  chs_gate   - CHECKMATE: the gate-truth rig (live opening -> shop
##               round-trip: no gate over the game)
##
##  QA_RIG=<rig> xvfb-run -a godot --path . res://tests/qa_v038.tscn

var G: GogaGame

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "dom_mid"
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        Box.dev_set_cheat("gogacoins", 0)
        Box.earn(20000)
        if rig.begins_with("dom"):
                await _dom(rig)
        elif rig.begins_with("chs"):
                await _chs(rig)
        await _settle(7)
        var shot := "user://qa_v038_%s.png" % rig
        var img := get_viewport().get_texture().get_image()
        img.save_png(shot)
        print("[qa_v038] saved ", shot)
        get_tree().quit(0)

func _settle(frames: int) -> void:
        for i in frames:
                await get_tree().process_frame

func _boot(id: String, w: int, h: int) -> void:
        get_window().size = Vector2i(w, h)
        ScaleRule.apply(get_window())
        G = load(GameReg.get_game(id)["script"]).new()
        G.game_id = id
        add_child(G)
        await _settle(4)

# ---------------------------------------------------------------- domino
func _dom(rig: String) -> void:
        await _boot("domino", 720, 1280)
        if rig == "dom_ready":
                await _settle(4)
                return
        if rig == "dom_shop":
                G.state = "ready"
                G._shop_open()
                await _settle(6)
                return
        if rig == "dom_gate":
                # THE GATE TRUTH RIG: a LIVE round, then a mid-play shop
                # round-trip - the gate must stay dead, the boneyard label
                # must read the real count, and the toast must sit on the
                # felt above the hand (v0.3.8 fixes)
                G.probe_reset(7)
                var g1 := 0
                while G.state != "play" and G.state != "cpu_wait" \
                                and g1 < 900:
                        g1 += 1
                        G.probe_step(1.0 / 60.0)
                var g2 := 0
                while G.state == "cpu_wait" and g2 < 900:
                        g2 += 1
                        G.probe_step(1.0 / 60.0)
                G._shop_open()
                await _settle(5)
                G.sheet_pop()
                await _settle(5)
                if G.state == "play" and G.turn == G.P:
                        G.game_toast("THE CPU HOLDS THE OPENER")
                await _settle(3)
                return
        # dom_mid: deal, build a chain, lift a tile that fits an end
        G.probe_reset(23)
        var DOM: GDScript = load("res://game/games/domino/domino.gd")
        # the opener plays (whoever holds it)
        var guard := 0
        while G.state != "play" and guard < 600:
                guard += 1
                G.probe_step(1.0 / 60.0)
        if G.turn == G.P:
                for i in G.hand_p.size():
                        if G._is_opener(i):
                                G._place(G.P, i, 2)
                                break
        var guard2 := 0
        while G.state == "cpu_wait" and guard2 < 600:
                guard2 += 1
                G.probe_step(1.0 / 60.0)
        # the player lays two more honest tiles so the chain reads
        for k in 2:
                if G.state != "play" or G.turn != G.P:
                        break
                var e: Vector2i = G.ends(G.chain)
                var opts: Array = G.playable(G.hand_p, e.x, e.y)
                if opts.is_empty():
                        break
                var i2: int = opts[0]
                var cp: int = G.can_play(G.hand_p[i2], e.x, e.y)
                G._place(G.P, i2, 1 if (cp & 1) != 0 else 2)
                var guard3 := 0
                while G.state == "cpu_wait" and guard3 < 600:
                        guard3 += 1
                        G.probe_step(1.0 / 60.0)
        # lift a fitting tile: the ends glow
        if G.state == "play" and G.turn == G.P:
                var e2: Vector2i = G.ends(G.chain)
                var opts2: Array = G.playable(G.hand_p, e2.x, e2.y)
                if not opts2.is_empty():
                        G.sel = int(opts2[opts2.size() - 1])
        await _settle(6)

# --------------------------------------------------------------- chess
func _chs(rig: String) -> void:
        await _boot("chess", 1600, 720)
        if rig == "chs_ready":
                await _settle(4)
                return
        if rig == "chs_gate":
                # THE GATE TRUTH RIG: a live opening, then a mid-play shop
                # round-trip - the gate must stay dead over the game
                G.probe_reset(3)
                var CH: GDScript = load("res://game/games/chess/chess.gd")
                for mv in ["e2e4", "e7e5"]:
                        var m: Dictionary = {}
                        for mm in CH.legal_moves(G.st):
                                if CH.coord_of(mm) == mv:
                                        m = mm
                        if not m.is_empty():
                                G._apply_move(m, true)
                        var gg := 0
                        while G.state == "cpu_wait" and gg < 900:
                                gg += 1
                                G.probe_step(1.0 / 60.0)
                G._shop_open()
                await _settle(5)
                G.sheet_pop()
                await _settle(5)
                return
        if rig == "chs_shop":
                G.state = "ready"
                G._shop_open()
                await _settle(6)
                return
        # chs_mid: a real opening, then the CPU answers; select a piece
        G.probe_reset(3)
        var CH: GDScript = load("res://game/games/chess/chess.gd")
        for mv in ["e2e4", "e7e5", "g1f3"]:
                var m: Dictionary = {}
                for mm in CH.legal_moves(G.st):
                        if CH.coord_of(mm) == mv:
                                m = mm
                if not m.is_empty():
                        G._apply_move(m, true)
                var guard := 0
                while G.state == "cpu_wait" and guard < 900:
                        guard += 1
                        G.probe_step(1.0 / 60.0)
        # select the queen-side knight: the dots + rings read
        if G.state == "play":
                var sq := -1
                for i in 64:
                        if int(G.st["b"][i]) == 2 and i / 8 == 0:
                                sq = i
                if sq >= 0:
                        G._press(G._sq_rect(sq).get_center())
        await _settle(6)
