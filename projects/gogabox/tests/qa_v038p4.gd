extends Node
## qa_v038p4 - the v0.3.8-4 rigs: THE POP PAY LAW (the coin at the pop
## moment), THE LIVE MENU (the fitted rows + the ring that redraws), THE
## SKILL PTS METER (n/100 above the bar, outlined), THE ALIVE CREW (the
## walk frames + the flip), THE SCROLL SEAT (the shop stays where you
## were), THE SERPENTINE (the Loop Games snake rows), THE BIG ROOM (the
## spread + the big hint).
## Rigs (QA_RIG env):
##  pop_pay   - POP SIEGE: a bloon pays its popcoin the moment it pops
##  pop_menu  - POP SIEGE: the selected folk's menu (the fitted stat rows,
##              the AUTO/MANUAL seat) + the ring LIVE after an upgrade
##  cs_hud    - COSMIC SPUD: the SKILL PTS 62/100 label above the gold bar
##  cs_allies - COSMIC SPUD: the six crew walking (two snaps: frames+flip)
##  cs_scroll - COSMIC SPUD: the shop scrolled to the bottom, a buy, and
##              the view STAYS at the bottom
##  domino    - DOMINO: a 19-tile serpentine snake, the W-D-L strip, the
##              BONEYARD label, the big hand
##  dom_spread- DOMINO: the stuck spread + the big TAP A TILE TO DRAW hint
##
##  QA_RIG=<rig> godot --path . res://tests/qa_v038p4.tscn

var frames := 0
var rig_id := ""

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "pop_pay"
        rig_id = rig
        DirAccess.make_dir_recursive_absolute("/tmp/qa_v038p4")
        # the registry's own design shapes: pop siege + cosmic spud are pinned
        # landscape, domino is portrait - the rig obeys the host's lock
        match rig_id:
                "domino", "dom_spread":
                        get_window().size = Vector2i(720, 1280)
                _:
                        get_window().size = Vector2i(1920, 1080)
        # THE HOST'S OWN LAW: the real app re-applies the ScaleRule (the menu
        # governor does it per-frame) - without it the canvas stretched to
        # 3413x1920 and the window sliced the panel (a rig lie, not the game)
        ScaleRule.apply(get_window())
        match rig_id:
                "pop_pay", "pop_menu":
                        await _ps_rig(rig_id)
                "cs_hud", "cs_allies", "cs_scroll":
                        await _cs_rig(rig_id)
                "domino", "dom_spread":
                        await _dom_rig(rig_id)
        print("[qa_v038p4] rig %s done: %d frames" % [rig_id, frames])
        get_tree().quit(0)

func _settle(n: int) -> void:
        for i in n:
                await get_tree().process_frame

func _snap(tag: String) -> void:
        await _settle(3)
        var img := get_viewport().get_texture().get_image()
        var path := "/tmp/qa_v038p4/%s_%s_%03d.png" % [tag, rig_id, frames]
        img.save_png(path)
        frames += 1

# ---------------------------------------------------------------- pop siege
func _ps_rig(rig: String) -> void:
        var G: GogaGame = load("res://game/games/pop_siege/pop_siege.gd").new()
        G.game_id = "pop_siege"
        add_child(G)
        for i in 40:
                await get_tree().process_frame
        # press START: the siege marches (the gate's dim + the ready phase
        # would freeze the paint the rigs are here to watch)
        G._start_ready()
        await _settle(6)
        match rig:
                "pop_pay":
                        # the purse and the wave line first
                        await _snap("pay_before")
                        G._spawn_bloon("red", 0)
                        await _settle(6)
                        await _snap("pay_alive")
                        # one LongEye-sized 8-dmg hit on a 1-layer red: ONE popcoin,
                        # the float text at the pop moment (the v3 law in the flesh)
                        var b: Dictionary = G.bloons[-1]
                        G._hurt_bloon(b, 8.0, PDData.SHARP, null)
                        await _settle(2)
                        await _snap("pay_moment")
                        await _settle(10)
                        await _snap("pay_after")
                "pop_menu":
                        # a darty on the field, selected: the menu with the fitted
                        # stat rows + the range ring
                        G.coins = 3000
                        var cell := Vector2i(-1, -1)
                        for c in range(18):
                                for r in range(10):
                                        if G._buildable(Vector2i(c, r)):
                                                cell = Vector2i(c, r)
                                                break
                                if cell.x >= 0:
                                        break
                        G._place_folk("darty", cell)
                        var f: Dictionary = G.folk[-1]
                        G._select_folk(f)
                        await _settle(8)
                        await _snap("menu_a")
                        # the upgrade: the ring REDRAWS LIVE (no re-tap), the delta
                        # row speaks honest shots/s
                        G._do_upgrade(f)
                        await _settle(8)
                        await _snap("menu_b_upgraded")
                        G._do_upgrade(f)
                        await _settle(8)
                        await _snap("menu_c_gearless")

# ------------------------------------------------------------- cosmic spud
func _cs_rig(rig: String) -> void:
        var G: GogaGame = load("res://game/games/cosmic_spud/cosmic_spud.gd").new()
        G.game_id = "cosmic_spud"
        add_child(G)
        for i in 40:
                await get_tree().process_frame
        var meta: CSMeta = G.meta
        match rig:
                "cs_hud":
                        G._start_run()
                        await _settle(30)
                        G.run_kills = 62
                        G._refresh_hud()
                        await _settle(10)
                        await _snap("hud_a")
                        G.run_kills = 100
                        G._refresh_hud()
                        await _settle(10)
                        await _snap("hud_b_full")
                "cs_allies":
                        G._start_run()
                        await _settle(20)
                        for aid in ["drone", "turret", "guard", "medic", "bomber", "scout"]:
                                G._deploy_ally(aid, 1)
                        # jobs for the crew: the flips face the work
                        G._spawn_enemy("blab", G.p_pos + Vector2(280, -50))
                        G._spawn_enemy("sprinter", G.p_pos + Vector2(-260, 70))
                        await _settle(14)
                        await _snap("crew_a")
                        await _settle(26)
                        await _snap("crew_b")
                        await _settle(26)
                        await _snap("crew_c")
                "cs_scroll":
                        Box.earn(50000)
                        G._start_run()
                        await _settle(30)
                        G._shop_button()
                        await _settle(20)
                        # find the shop's scroll and sink to the bottom (THE CREW rows)
                        var dim: Control = (G.cs_sheets.back() as Dictionary)["dim"]
                        var sc: BoxScroll = G._cs_find_scroll(dim)
                        if sc != null:
                                sc.scroll_vertical = 100000
                        await _settle(8)
                        await _snap("shop_bottom")
                        # a bottom purchase: the crew row - the sheet rebuilds and the
                        # scroll SEAT must survive (the pop-siege law)
                        var price: int = int(CSData.SHOP_CREW["drone"])
                        G._shop_buy_crew("drone", price)
                        await _settle(14)
                        await _snap("shop_after_buy")

# ----------------------------------------------------------------- domino
func _dom_rig(rig: String) -> void:
        var G: GogaGame = load("res://game/games/domino/domino.gd").new()
        G.game_id = "domino"
        G.start_orientation = "vertical"   # v0.3.8-8: ask suppressed on the rig
        add_child(G)
        for i in 40:
                await get_tree().process_frame
        match rig:
                "domino":
                        G._new_round()
                        G.state = "deal"
                        for i in 28:
                                await get_tree().process_frame
                        await _settle(120)
                        # a real 19-tile pip-valid snake: doubles and runs mixed so
                        # the serpentine packs rows the way the Loop Games table does
                        var chain: Array = [[6, 6], [6, 4], [4, 2], [2, 2], [2, 5],
                                        [5, 5], [5, 0], [0, 3], [3, 3], [3, 1], [1, 1],
                                        [1, 6], [6, 0], [0, 0], [0, 2], [2, 4], [4, 4],
                                        [4, 6], [6, 3]]
                        G.chain.clear()
                        for c in chain:
                                G.chain.append({"a": c[0], "b": c[1], "fl": false,
                                                "who": 1, "landed": true})
                        G.hand_p = [[6, 6], [5, 2], [4, 1]]
                        G._relayout()
                        await _settle(10)
                        await _snap("snake_a")
                        # the wide catch: the drop seats near the ends (the candidate
                        # rings paint on the open ends)
                        await _settle(20)
                        await _snap("snake_b")
                "dom_spread":
                        G._new_round()
                        G.state = "deal"
                        for i in 28:
                                await get_tree().process_frame
                        await _settle(120)
                        # STUCK: the boneyard spreads face-down with the big hint
                        G.state = "stuck"
                        G.spread = true
                        G._relayout()
                        await _settle(10)
                        await _snap("spread_a")
                        await _settle(20)
                        await _snap("spread_b")
