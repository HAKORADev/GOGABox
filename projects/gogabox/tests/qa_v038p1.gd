extends Node
## qa_v038p1 - THE OWNER'S RECORDING RIG: automated gameplays, recorded
## frame by frame so they can be WATCHED before shipping (the owner:
## "automate gameplays and record them then watch them before and after").
## Rigs (QA_RIG env):
##  bot_domino - a full honest domino round, bot vs CPU, ~30 frames
##  bot_chess  - a real chess war, bot vs CPU with captures, ~30 frames
##  bot_black  - the same but the USER takes BLACK (the seat law: user at
##               the bottom, the CPU opens)
##  feed       - the REAL menu with a 10-game save: owned first, mysteries
##               mid-grid, the SOON teasers LAST (the old sort, alive)
##  dom_mid    - the new domino frame: score right, CPU backs top-center,
##               the snake starting at the ground's center
##  dom_spread - the yard spread up: tap-a-tile manual draw
##  chs_mid    - the new chess frame: vertical score strip, dead tray,
##               the TURN KING glowing
##  chs_pick   - the optionals color shelf (the matcher design)
##
##  QA_RIG=<rig> xvfb-run -a godot --path . res://tests/qa_v038p1.tscn

var G: GogaGame
var frames := 0
var rig_id := ""

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "bot_domino"
        rig_id = rig
        if rig == "feed":
                await _feed()
        elif rig == "maze_coin":
                await _maze_coin()
        elif rig.begins_with("bot_domino"):
                await _bot_domino()
        elif rig == "bot_chess":
                await _bot_chess(false)
        elif rig == "bot_black":
                await _bot_chess(true)
        elif rig.begins_with("dom"):
                await _dom(rig)
        elif rig.begins_with("chs"):
                await _chs(rig)
        print("[qa_v038p1] rig %s done: %d frames" % [rig_id, frames])
        get_tree().quit(0)

func _settle(n: int) -> void:
        for i in n:
                await get_tree().process_frame

func _snap(tag: String) -> void:
        await _settle(2)
        var img := get_viewport().get_texture().get_image()
        var path := "/tmp/qa_v038p1/%s_%03d.png" % [tag, frames]
        img.save_png(path)
        frames += 1

## drive the REAL tree for dt seconds (the visuals animate while we shoot)
func _step(seconds: float, snap_every := 0.0, tag := "") -> void:
        var t := 0.0
        while t < seconds:
                G.probe_step(1.0 / 60.0)
                t += 1.0 / 60.0
                if snap_every > 0.0 and fmod(t, snap_every) < 1.0 / 60.0:
                        await _snap(tag)

func _boot(id: String, w: int, h: int) -> void:
        get_window().size = Vector2i(w, h)
        ScaleRule.apply(get_window())
        G = load(GameReg.get_game(id)["script"]).new()
        G.game_id = id
        add_child(G)
        await _settle(4)
        print("[qa] vp=", G.get_viewport_rect().size, " window=", get_window().size,
                " board_rect=", G.board_rect if "board_rect" in G else "n/a")

# ------------------------------------------------------------- maze coin
func _maze_coin() -> void:
        DirAccess.make_dir_recursive_absolute("/tmp/qa_v038p1")
        await _boot("maze", 720, 1280)
        G.probe_reset(4)
        # jump to a grown map: the cell has shrunk hard - the coin must
        # wear the SAME fit law (the owner's patch-1 report)
        G.map_i = 12
        G._new_map()
        while G.coin.is_empty():
                G.map_i += 1
                G._new_map()
        await _settle(10)
        await _snap("maze_coin")

# ------------------------------------------------------------- domino bot
func _bot_domino() -> void:
        DirAccess.make_dir_recursive_absolute("/tmp/qa_v038p1")
        await _boot("domino", 720, 1280)
        G.probe_reset(11)
        var guard := 0
        while G.state != "play" and guard < 900:
                guard += 1
                G.probe_step(1.0 / 60.0)
        await _snap("bot_domino")
        var plies := 0
        while G.state != "round_over" and plies < 120 and guard < 30000:
                guard += 1
                plies += 1
                if G.state == "cpu_wait":
                        G.probe_step(1.0 / 60.0)
                        continue
                if G.turn != G.P or G.state != "play":
                        continue
                # THE OPENER: the glowing tile plays
                if G.opening:
                        for i in G.hand_p.size():
                                if G._is_opener(i):
                                        G._place(G.P, i, 2)
                                        break
                else:
                        var e: Vector2i = G.ends(G.chain)
                        var opts: Array = G.playable(G.hand_p, e.x, e.y)
                        if opts.is_empty():
                                # THE MANUAL YARD: spread up, tap a tile
                                if G.deck.size() > 0:
                                        await _snap("bot_domino")
                                        var pick: int = G.deck.size() / 2
                                        G._player_take(pick)
                                else:
                                        G._pass(G.P)
                        else:
                                var i2: int = opts[randi() % opts.size()]
                                var cp: int = G.can_play(G.hand_p[i2], e.x, e.y)
                                G._place(G.P, i2, 1 if (cp & 1) != 0 else 2)
                await _step(0.12)
                if plies % 3 == 0:
                        await _snap("bot_domino")
        await _snap("bot_domino")

# -------------------------------------------------------------- chess bot
func _bot_chess(user_black: bool) -> void:
        DirAccess.make_dir_recursive_absolute("/tmp/qa_v038p1")
        await _boot("chess", 1600, 720)
        G.probe_reset(5)
        if user_black:
                G.player_white = false
                G.color_override = ""
        var CH: GDScript = load("res://game/games/chess/chess.gd")
        var tag := "bot_black" if user_black else "bot_chess"
        await _snap(tag)
        var plies := 0
        var guard := 0
        while G.state != "round_over" and plies < 70 and guard < 40000:
                guard += 1
                if G.state == "cpu_wait":
                        G.probe_step(1.0 / 60.0)
                        continue
                if G.state != "play":
                        break
                var moves: Array = CH.legal_moves(G.st)
                if moves.is_empty():
                        break
                # the bot's taste: captures first, then any legal move
                var pick: Dictionary = {}
                for m in moves:
                        if int(m["promo"]) > 0 and int(m["promo"]) != 5:
                                continue
                        if int(G.st["b"][m["t"]]) != 0 or m["flag"] == "ep":
                                pick = m
                                break
                if pick.is_empty():
                        pick = moves[randi() % moves.size()]
                G._apply_move(pick, true)
                plies += 1
                await _step(0.1)
                if plies % 2 == 0:
                        await _snap(tag)
        await _snap(tag)

# ------------------------------------------------------------- the feed
func _feed() -> void:
        DirAccess.make_dir_recursive_absolute("/tmp/qa_v038p1")
        # a 10-game save: the mysteries ride the ladder, fourline is SOON
        Box.reset_all()
        Box.dev_set_cheat("gogacoins", 0)
        Box.earn(20000)
        Box.record_started("snake")
        for gid in ["rally", "lanes", "slasher", "hopper", "merge", "dario",
                "xo", "invaders", "matcher"]:
                Box.unlock_game(gid, 0)
        Box.record_started("rally")
        Roadmap.tick()
        var ps: PackedScene = load("res://main.tscn")
        var m: Node = ps.instantiate()
        add_child(m)
        await _settle(30)
        await _snap("feed")
        # scroll to the tail: the mysteries -> the SOON teasers LAST
        var stack: Array = [m]
        var sc: BoxScroll = null
        while not stack.is_empty() and sc == null:
                var n: Node = stack.pop_front()
                for c in n.get_children():
                        if c is BoxScroll:
                                sc = c
                                break
                        stack.append(c)
        if sc != null:
                sc.scroll_vertical = 100000
                await _settle(20)
                await _snap("feed")
                print("[qa_v038p1] feed tail shot saved")
        else:
                print("[qa_v038p1] NO BoxScroll found")

# ------------------------------------------------------- the still rigs
func _dom(rig: String) -> void:
        DirAccess.make_dir_recursive_absolute("/tmp/qa_v038p1")
        await _boot("domino", 720, 1280)
        if rig == "dom_ready":
                await _settle(6)
                await _snap(rig)
                return
        G.probe_reset(23)
        var guard := 0
        while G.state != "play" and guard < 900:
                guard += 1
                G.probe_step(1.0 / 60.0)
        if G.turn == G.P:
                for i in G.hand_p.size():
                        if G._is_opener(i):
                                G._place(G.P, i, 2)
                                break
        var g2 := 0
        while G.state == "cpu_wait" and g2 < 900:
                g2 += 1
                G.probe_step(1.0 / 60.0)
        for k in 3:
                if G.state != "play" or G.turn != G.P:
                        break
                var e: Vector2i = G.ends(G.chain)
                var opts: Array = G.playable(G.hand_p, e.x, e.y)
                if opts.is_empty():
                        break
                var i2: int = opts[opts.size() - 1]
                var cp: int = G.can_play(G.hand_p[i2], e.x, e.y)
                G._place(G.P, i2, 1 if (cp & 1) != 0 else 2)
                var g3 := 0
                while G.state == "cpu_wait" and g3 < 900:
                        g3 += 1
                        G.probe_step(1.0 / 60.0)
        if rig == "dom_spread":
                # show the manual yard: the fan up (the stuck door's face)
                G.sel = -1
                G.spread = true
                G._relayout()
                await _settle(8)
                await _snap(rig)
                return
        # lift a fitting tile: the ends glow
        if G.state == "play" and G.turn == G.P:
                var e2: Vector2i = G.ends(G.chain)
                var opts2: Array = G.playable(G.hand_p, e2.x, e2.y)
                if not opts2.is_empty():
                        G.sel = int(opts2[opts2.size() - 1])
        await _settle(8)
        await _snap(rig)

func _chs(rig: String) -> void:
        DirAccess.make_dir_recursive_absolute("/tmp/qa_v038p1")
        await _boot("chess", 1600, 720)
        if rig == "chs_ready":
                await _settle(6)
                await _snap(rig)
                return
        if rig == "chs_pick":
                G.state = "ready"
                G._pick_open(true)
                await _settle(8)
                await _snap(rig)
                return
        G.probe_reset(3)
        var CH: GDScript = load("res://game/games/chess/chess.gd")
        for mv in ["e2e4", "e7e5", "g1f3", "b8c6", "f1b5"]:
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
        if rig == "chs_mid":
                if G.state == "play":
                        var sq := -1
                        for i in 64:
                                if int(G.st["b"][i]) == 2 and i / 8 == 0:
                                        sq = i
                        if sq >= 0:
                                G._press(G._sq_rect(sq).get_center())
                await _settle(8)
                await _snap(rig)
