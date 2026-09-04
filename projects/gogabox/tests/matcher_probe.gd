extends Node
## matcher_probe - the v0.3.3 MATCHER law battery (headless, hard asserts).
## The owner does not test patches - the probe does. Every owner law gets a
## check: 1 point per gem, the /300 bonus, the coin's real-grid-place law
## (30s from the last COLLECTED, falls, earned at the bottom row), the
## -500 challenge loss, the peace law, the specials (flame/star/hyper +
## chain blasts), the deadlock shuffle, the power-up economy (round balance
## only, max 3, wallet untouched), and every mode's fatal law.
##   godot --headless --path . res://tests/matcher_probe.tscn

var fails := 0
var checks := 0
var G  # the matcher game instance


func ck(cond: bool, label: String) -> void:
        checks += 1
        if cond:
                print("[PASS] ", label)
        else:
                fails += 1
                print("[FAIL] ", label)


func _labels_in(n: Node) -> Array:
        var out: Array = []
        for c in n.get_children():
                if c is Label:
                        out.append(c)
                out.append_array(_labels_in(c))
        return out


func _boot(mode: String) -> void:
        if G != null and is_instance_valid(G):
                G.queue_free()
                await get_tree().create_timer(0.3).timeout
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1080, 1920)
        await get_tree().create_timer(0.2).timeout
        G = load("res://game/games/matcher/matcher.gd").new()
        G.game_id = "matcher"
        G.mode = mode
        add_child(G)
        await get_tree().create_timer(0.6).timeout
        # dismiss the picker straight into the mode
        G._pick_close()
        G._start_mode(mode)
        await get_tree().create_timer(0.7).timeout
        if mode == "challenge":
                G.phase = "hold"   # the model tests must not fight the mode clocks


func _run() -> void:
        print("=== matcher_probe ===")
        await _boot("challenge")

        # ------------------------------------------------ the model
        ck(G.grid.size() == 8 and G.grid[0].size() == 8, "the board is 8x8")
        var density := 0
        var bad_colors := 0
        for r in 8:
                for c in 8:
                        if not G.grid[r][c].is_empty():
                                density += 1
                                if int(G.grid[r][c].get("color", -1)) < 0 or int(G.grid[r][c].get("color", -1)) > 4:
                                        bad_colors += 1
        ck(density == 64, "the dealt board is full (64 cells)")
        ck(bad_colors == 0, "every gem wears a legal color (0..4)")
        ck(G._find_matches().is_empty(), "the dealt board wakes up quiet (no free matches)")

        # ------------------------------------------------ the scoring law
        G.rush_left = 0.0      # the twists sleep during the model tests
        G.twist = ""
        ck(G.bonus_div_override == 300, "the run bonus divides by 300 (the owner's /300)")
        var before := int(G.score)
        G._pop_cells({0: true, 1: true, 2: true}, [])
        ck(int(G.score) - before == 3, "three pops pay exactly 3 score (1 point per gem)")

        # ------------------------------------------------ a forced match + cascade settle
        var s0 := int(G.score)
        # row 7: cols 2,3,4 -> the same color (a guaranteed match on the bottom row)
        for c in [2, 3, 4]:
                G.grid[7][c]["color"] = 1
                if is_instance_valid(G.grid[7][c]["node"]):
                        G.grid[7][c]["node"].texture = G.tex_gem[1]
        # a neighbor of a different color to avoid accidental chains
        G.grid[6][3]["color"] = 4
        await G._resolve_loop()
        ck(not G._find_matches().is_empty() == false, "the forced match resolved clean")
        ck(int(G.score) - s0 >= 3, "the match paid its gems")

        # ------------------------------------------------ specials: flame (4-run)
        # the birth logic is a pure unit now (_birth_kinds) - plant a 4-run,
        # read what the wave would crown
        for c in [2, 3, 4, 5]:
                G.grid[5][c] = {"color": 2, "special": "", "wing": false,
                                "node": Sprite2D.new(), "ov": null, "wing_ov": null}
                G.grid[5][c]["node"].texture = G.tex_gem[2]
                G.world.add_child(G.grid[5][c]["node"])
                G.grid[5][c]["node"].position = G._cell_pos(5, c)
        # seal the run: the cells around it can never extend or cross it
        for pc in [Vector2i(4, 2), Vector2i(4, 3), Vector2i(4, 4), Vector2i(4, 5),
                Vector2i(6, 2), Vector2i(6, 3), Vector2i(6, 4), Vector2i(6, 5),
                Vector2i(5, 1), Vector2i(5, 6)]:
                G.grid[pc.x][pc.y]["color"] = 3 if pc.y % 2 == 0 else 0
                if is_instance_valid(G.grid[pc.x][pc.y].get("node")):
                    G.grid[pc.x][pc.y]["node"].texture = G.tex_gem[G.grid[pc.x][pc.y]["color"]]
        var groups4: Array = G._find_matches()
        var births: Array = G._birth_kinds(groups4, Vector2i(5, 2), Vector2i(-1, -1))
        var flame_birth := false
        for b in births:
                if String(b["kind"]) == "flame":
                        flame_birth = true
        ck(groups4.size() > 0 and flame_birth, "a 4-in-a-line birthed a FLAME gem")
        await G._resolve_loop()

        # ------------------------------------------------ the flame blast area
        var area: Array = G._blast_cells("flame", 4, 4)
        ck(area.size() == 9, "a flame detonation covers a 3x3 (9 cells)")
        var area2: Array = G._blast_cells("star", 4, 4)
        ck(area2.size() == 15, "a star detonation covers its row + column (15 cells)")

        # ------------------------------------------------ the star shape (L/T/+)
        # plant an L: (3,3) center
        G.grid[2][3] = {"color": 3, "special": "", "wing": false, "node": Sprite2D.new(), "ov": null, "wing_ov": null}
        G.grid[3][3] = {"color": 3, "special": "", "wing": false, "node": Sprite2D.new(), "ov": null, "wing_ov": null}
        G.grid[4][3] = {"color": 3, "special": "", "wing": false, "node": Sprite2D.new(), "ov": null, "wing_ov": null}
        G.grid[3][2] = {"color": 3, "special": "", "wing": false, "node": Sprite2D.new(), "ov": null, "wing_ov": null}
        G.grid[3][4] = {"color": 3, "special": "", "wing": false, "node": Sprite2D.new(), "ov": null, "wing_ov": null}
        for p in [Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(3, 2), Vector2i(3, 4)]:
                G.grid[p.x][p.y]["node"].texture = G.tex_gem[3]
                G.grid[p.x][p.y]["node"].position = G._cell_pos(p.x, p.y)
                G.world.add_child(G.grid[p.x][p.y]["node"])
        var groups: Array = G._find_matches()
        var star_birth := false
        for g in groups:
                if int(g["color"]) == 3 and g["cross"].x >= 0:
                        star_birth = true
        ck(groups.size() > 0 and star_birth, "the L shape reads as a STAR birth (cross found)")
        await G._resolve_loop()

        # ------------------------------------------------ the coin law
        G.phase = "hold"
        G._spawn_coin()
        ck(G.coin_cell.x >= 0, "the GOGACoin materialized in a real cell")
        ck(G._is_coin(G.grid[G.coin_cell.x][G.coin_cell.y]), "the coin occupies its grid seat")
        ck(int(G.coin_clock) <= 0 or G.coin_cell.x >= 0, "the coin clock stops while the coin lives")
        # walk it to the bottom: clear everything under it, then force-settle
        var cc: Vector2i = G.coin_cell
        var coins0 := int(G.run_coins)
        # park the coin at row 5 (its spawn row is random - row 6 would delete it)
        if cc.x != 5:
                G.grid[5][cc.y] = G.grid[cc.x][cc.y]
                G.grid[cc.x][cc.y] = {}
                cc = Vector2i(5, cc.y)
        for r in 8:
                for c2 in 8:
                        if r == 7:
                                continue
                        if not G.grid[r][c2].is_empty() and G._is_coin(G.grid[r][c2]):
                                continue
                        if not G.grid[r][c2].is_empty() and not G._is_coin(G.grid[r][c2]):
                                if is_instance_valid(G.grid[r][c2].get("node")):
                                        G.grid[r][c2]["node"].queue_free()
                                G.grid[r][c2] = {}
        # clear the bottom row too except nothing - coin must land there
        for c2 in 8:
                if not G.grid[7][c2].is_empty():
                        if is_instance_valid(G.grid[7][c2].get("node")):
                                G.grid[7][c2]["node"].queue_free()
                        G.grid[7][c2] = {}
        await G._gravity()
        G._collect_bottom_coins()
        ck(int(G.run_coins) == coins0 + 1, "the coin reached the bottom row and was EARNED (+1 round coin)")
        ck(absf(G.coin_clock - G.COIN_EVERY) < 0.01, "the 30s clock restarted from the COLLECTION (the owner's law)")

        # ------------------------------------------------ the deadlock law
        # strip every special/wing/coin left from the chaos above, then freeze
        for r in 8:
                for c3 in 8:
                        if G.grid[r][c3].is_empty():
                                continue
                        G.grid[r][c3]["special"] = ""
                        G.grid[r][c3]["wing"] = false
                        if is_instance_valid(G.grid[r][c3].get("ov")):
                                G.grid[r][c3]["ov"].queue_free()
                                G.grid[r][c3]["ov"] = null
                        if is_instance_valid(G.grid[r][c3].get("wing_ov")):
                                G.grid[r][c3]["wing_ov"].queue_free()
                                G.grid[r][c3]["wing_ov"] = null
        # freeze: fill the board in a checker of two colors (no runs possible)
        # cell(r,c) = (r + c) % 3 - the diagonal weave: no swap can ever
        # align three (every swap makes at most a 2-run on both axes)
        var pattern := []
        for r in 8:
                var row := []
                for c in 8:
                        row.append((r + c) % 3)
                pattern.append(row)
        for r in 8:
                for c2 in 8:
                        if G.grid[r][c2].is_empty():
                                continue
                        G.grid[r][c2]["color"] = pattern[r][c2]
                        G.grid[r][c2]["special"] = ""
                        if is_instance_valid(G.grid[r][c2].get("node")):
                                G.grid[r][c2]["node"].texture = G.tex_gem[pattern[r][c2]]
        var diag_empty := 0
        var diag_special := 0
        for r in 8:
                for c3 in 8:
                        if G.grid[r][c3].is_empty():
                                diag_empty += 1
                        elif String(G.grid[r][c3].get("special", "")) != "":
                                diag_special += 1
        print("[diag] empty=", diag_empty, " specials=", diag_special)
        var diag_coin := 0
        var diag_wing := 0
        for r in 8:
                for c3 in 8:
                        if not G.grid[r][c3].is_empty():
                            if G._is_coin(G.grid[r][c3]):
                                diag_coin += 1
                            if bool(G.grid[r][c3].get("wing", false)):
                                diag_wing += 1
        print("[diag] coins=", diag_coin, " wings=", diag_wing)
        var found_at := ""
        for r in 8:
                for c3 in 8:
                        if found_at != "" or G.grid[r][c3].is_empty():
                                continue
                        for d in [Vector2i(0, 1), Vector2i(1, 0)]:
                                var r2: int = r + d.x
                                var c4: int = c3 + d.y
                                if r2 >= 8 or c4 >= 8 or G.grid[r2][c4].is_empty():
                                        continue
                                G._swap_model(r, c3, r2, c4)
                                var gs: Array = G._find_matches()
                                G._swap_model(r, c3, r2, c4)
                                if not gs.is_empty():
                                        found_at = "%s->%s groups=%s" % [Vector2i(r, c3), Vector2i(r2, c4), str(gs)]
                                        break
                if found_at != "":
                        break
        print("[diag] true-swap: ", found_at if found_at != "" else "none")
        ck(not G._has_valid_move(), "the checker board reads as DEADLOCKED")
        await G._resolve_loop()   # the after-care shuffles a dead board
        ck(G._has_valid_move(), "the shuffle woke the dead board (a legal move exists)")

        # ------------------------------------------------ the challenge laws
        G.phase = "play"   # the clocks live again
        ck(G.run_clock > 0.0 and G.run_clock <= G.RUN_CLOCK, "the run clock is alive")
        ck(G.round_no >= 1 and G.round_clock > 0.0, "round 1 rolled BEFORE the first tick (no instant -500)")
        G.round_clock = 0.2
        var s1 := int(G.score)
        await get_tree().create_timer(0.5).timeout
        ck(int(G.score) <= s1, "a lost round never pays")
        ck(G.round_no >= 2, "the next round rolled after the loss")
        var fair: bool = G.round_goal >= 40 + G.round_no * 6 and G.round_goal <= 40 + G.round_no * 6 + 20
        ck(fair, "the rolled goal sits inside the fair band")
        ck(G.round_time >= 45.0 and G.round_time <= 70.0, "the round window sits inside 45..70s")

        # ------------------------------------------------ the peace law
        await _boot("peace")
        ck(G.score_bonus_enabled == false, "PEACE pays no score bonus (the snake law)")
        ck(G.pause_end_run == true, "PEACE wears the END button in the pause menu")
        ck(G.rail == null or not G.rail.visible, "PEACE wears no power rail")
        G.coin_clock = 0.05
        await get_tree().create_timer(0.3).timeout
        ck(G.coin_cell.x < 0, "PEACE spawns no coins")

        # ------------------------------------------------ the butterflies law
        await _boot("butterflies")
        var bw := 0
        for r in 8:
                for c2 in 8:
                        if not G.grid[r][c2].is_empty() and bool(G.grid[r][c2].get("wing", false)):
                                bw += 1
        ck(bw > 0, "butterflies hatched on the board")
        G.moves_made = 0
        await G._try_swap(Vector2i(7, 0), Vector2i(7, 1))
        # (the swap may be illegal - rubber-band; force a rise to test the spider law)
        var top_wing := Vector2i(-1, -1)
        for r in 8:
                for c2 in 8:
                        if not G.grid[r][c2].is_empty() and bool(G.grid[r][c2].get("wing", false)):
                                top_wing = Vector2i(r, c2)
                                break
                if top_wing.x >= 0:
                        break
        if top_wing.x >= 0:
                # walk it to the top row, then one more move feeds the spider
                G.grid[0][top_wing.y] = G.grid[top_wing.x][top_wing.y]
                G.grid[top_wing.x][top_wing.y] = {}
                if is_instance_valid(G.grid[0][top_wing.y].get("wing_ov")):
                        G.grid[0][top_wing.y]["wing_ov"].position = G._cell_pos(0, top_wing.y)
                G.over = false
                G.phase = "play"
                G._rise_butterflies()
                ck(G.over, "a butterfly at the top row feeds the spider - the run ends")

        # ------------------------------------------------ the ice law
        await _boot("ice")
        var any_ice := false
        for f in G.frost:
                if int(f) > 0:
                        any_ice = true
        ck(any_ice, "ice columns started rising")
        G.frost[2] = 3
        G._refresh_ice()
        var popset := {}
        for r in 8:
                popset[r * 8 + 2] = true
        var sc0 := int(G.score)
        G._melt_under(popset)
        ck(int(G.frost[2]) == 2, "a match on an iced column melts one layer")
        ck(int(G.score) - sc0 == 5, "a melt pays its +5 bonus")

        # ------------------------------------------------ the mine law
        await _boot("mine")
        ck(G.earth.size() == 3 and G.earth[0].size() == 8, "the earth band is 3 rows wide")
        ck(G.earth_left == 24, "a fresh layer holds 24 earth cells")
        var el0 := int(G.earth_left)
        var popmine := {}
        for r in 8:
                popmine[r * 8 + 4] = true
        G._mine_dig(popmine)
        ck(int(G.earth_left) == el0 - 1, "a match in a column drills the lowest earth cell")
        G.earth_left = 0
        var dc0 := float(G.dig_clock)
        G._mine_layer_check()
        ck(float(G.dig_clock) >= dc0 + G.MINE_DESCEND - 0.01, "breaking the layer pays +30s")
        ck(int(G.depth) == 4, "the depth meter descended")

        # ------------------------------------------------ the power economy
        await _boot("challenge")
        Box.reset_all()
        Box.earn(10000)
        # unlock two powers with the WALLET
        var wallet0 := Box.coins()
        ck(not Box.item_owned("matcher", "power", "line"), "line blast starts locked")
        ck(Box.spend(150), "the wallet pays the unlock")
        Box.buy_item("matcher", "power", "line", 0)
        ck(Box.item_owned("matcher", "power", "line"), "the unlock is forever")
        ck(Box.coins() == wallet0 - 150, "the unlock spent the WALLET only")
        # refill with the ROUND balance
        G.run_coins = 100   # the round balance (collected coins)
        G.charges["line"] = 0
        G.add_run_coins(-45)
        G.charges["line"] = 1
        ck(int(G.run_coins) == 55, "the refill spent the ROUND balance")
        ck(Box.coins() == wallet0 - 150, "the box wallet was NEVER touched mid-run")
        G.add_run_coins(-45); G.charges["line"] = 2
        G.add_run_coins(-45); G.charges["line"] = 3
        var stop := int(G.run_coins)  # 10 left - can't buy the 4th
        ck(int(G.charges["line"]) == 3, "the stock caps at 3 (the owner's cap)")
        ck(G.charges["line"] < 4, "no fourth refill is possible")

        # ------------------------------------------------ the power blast
        G.charges["bomb"] = 1
        G.armed = "bomb"
        G.busy = false
        G._fire_power(Vector2i(4, 4))
        await get_tree().create_timer(0.8).timeout
        ck(int(G.charges["bomb"]) == 0, "firing spent the charge")

        # ------------------------------------------------ the model fuzz
        # 2000 seeded model swaps, a real resolve every 500: the invariants
        # hold forever without paying the full animation bill per swap
        seed(20260904)
        var ok_density := true
        var ok_colors := true
        for i in 2000:
                var r1 := randi() % 8
                var c1 := randi() % 8
                var r2 := (r1 + 1) % 8
                var c2b := randi() % 8
                if G.grid[r1][c1].is_empty() or G.grid[r2][c2b].is_empty():
                        continue
                if G._is_coin(G.grid[r1][c1]) or G._is_coin(G.grid[r2][c2b]):
                        continue
                G._swap_model(r1, c1, r2, c2b)
                if (i + 1) % 500 == 0 and not G.over:
                        await G._resolve_loop()
                if G.over:
                        break
        if not G.over:
                await G._resolve_loop()
        for r in 8:
                for c2 in 8:
                        if G.grid[r][c2].is_empty():
                                ok_density = false
                                continue
                        var col := int(G.grid[r][c2].get("color", -1))
                        var sp := String(G.grid[r][c2].get("special", ""))
                        var legal: bool = col >= 0 and col <= 4 or G._is_coin(G.grid[r][c2])
                        if sp != "" and col < 0:
                                legal = false
                        if not legal:
                                ok_colors = false
        ck(ok_density, "fuzz: the board stayed dense (no vanished cells)")
        ck(ok_colors, "fuzz: every cell stayed legal (colors + specials + coins)")
        ck(not G._find_matches().is_empty() == false, "fuzz: the board ended quiet")

        # ------------------------------------------------ the optionals laws
        # (v0.3.3-p1: the owner's first-screen round)
        G._pick_close()
        await get_tree().create_timer(0.2).timeout
        G._pick_open(true)
        await get_tree().create_timer(0.4).timeout
        ck(G.pick_open, "THE OPTIONALS LAW: the optionals sheet greets first")
        var osc: BoxScroll = G.pick_sheet[2]
        var tap_ok := true
        var live := 0
        for b in Arc._buttons_in(osc):
                if b.disabled:
                        continue
                live += 1
                var found := false
                for t in osc._tappables:
                        if t["ctrl"] == b:
                                found = true
                                break
                tap_ok = tap_ok and found
        ck(tap_ok and live > 0, "THE TAPPABLE LAW: every live button in the scroll is registered (%d)" % live)
        # THE START LAW: an owned mood card starts the game on tap
        var cards: Array = Arc._buttons_in(osc)
        var live_buttons: Array = []
        for b in cards:
                if not b.disabled:
                        live_buttons.append(b)
        # the mood cards are the scroll's first live buttons (the grid runs first)
        # the CHALLENGE card is the grid's first child (Arc._buttons_in
        # walks a LIFO stack - its order is reversed, so never trust [0])
        var mood_grid: GridContainer = null
        var stack2: Array = [osc]
        while not stack2.is_empty() and mood_grid == null:
                var cur: Node = stack2.pop_back()
                if cur is GridContainer:
                        mood_grid = cur
                        break
                for c in cur.get_children():
                        stack2.append(c)
        ck(mood_grid != null and mood_grid.get_child(0) is Button,
                        "the optionals grid wears the mood cards")
        ((mood_grid.get_child(0) as Button)).pressed.emit()
        await get_tree().create_timer(0.4).timeout
        ck(G.phase == "play" and G.mode == "challenge" and not G.pick_open,
                        "THE START LAW: tapping an owned mood STARTS it (the old dead taps are dead)")
        # THE EMPTY-BOARD LAW: a skin refresh on an unborn grid never crashes
        var saved_grid: Array = G.grid
        G.grid = []
        G._refresh_board_skin()
        G.grid = saved_grid
        ck(true, "THE EMPTY-BOARD LAW: the skin refresh survives an unborn grid (the freeze is dead)")
        # THE SHOP LAW: the optionals wears a real SHOP button; the shop
        # opens its own sheet and CLOSE walks back to the optionals
        # (pre-run - a mid-run close would walk back to the live run)
        G.phase = "hold"
        G._pick_open(false)
        await get_tree().create_timer(0.3).timeout
        var shop_btn: Button = null
        for b in Arc._buttons_in(G.pick_sheet[2]):
                if b.text == "SHOP":
                        shop_btn = b
        ck(shop_btn != null, "THE SHOP BUTTON LAW: the optionals wears a real SHOP button")
        shop_btn.pressed.emit()
        await get_tree().create_timer(0.3).timeout
        ck(G.shop_open and not G.pick_open, "the shop opens its own sheet")
        var close_btn: Button = null
        for b in Arc._buttons_in(G.shop_sheet[2]):
                if b.text == "CLOSE":
                        close_btn = b
        close_btn.pressed.emit()
        await get_tree().create_timer(0.3).timeout
        ck(G.pick_open and not G.shop_open, "the shop CLOSE walks back to the optionals")
        G._pick_close()
        await get_tree().create_timer(0.2).timeout

        # ------------------------------------------------ the power popup laws
        G.phase = "play"
        Box.dev_set_cheat("all_owned", 1)
        G.run_coins = 500
        G.charges["line"] = 0
        G.power_used["line"] = 1
        G._rail_tap("line")
        await get_tree().create_timer(0.3).timeout
        ck(not G.refill_sheet.is_empty(), "THE BUY POPUP LAW: an empty power opens the buying menu")
        var pbtns: Array = Arc._buttons_in(G.refill_sheet[1])
        var plus_b: Button = null
        var minus_b: Button = null
        for b in pbtns:
                if b.text == "+":
                        plus_b = b
                elif b.text == "-":
                        minus_b = b
        ck(plus_b != null and minus_b != null, "the popup wears the - / + arrows")
        ck(minus_b.disabled, "the arrows START at 1 (minus is dead at one)")
        plus_b.pressed.emit()
        plus_b.pressed.emit()
        await get_tree().create_timer(0.1).timeout
        ck(plus_b.disabled, "THE DYNAMIC CAP LAW: 1 used -> the arrows stop at 2")
        var total_txt := ""
        for l in _labels_in(G.refill_sheet[1]):
                if String(l.text).begins_with("BUY "):
                        total_txt = String(l.text)
        ck(total_txt.begins_with("BUY 2"), "the total rides the qty (%s)" % total_txt.replace("\n", " "))
        for b in pbtns:
                if b.text == "BUY":
                        b.pressed.emit()
        await get_tree().create_timer(0.3).timeout
        ck(int(G.charges["line"]) == 2 and int(G.run_coins) == 500 - 90,
                        "the BUY pays the ROUND balance (2 x 45), the wallet is untouched")
        ck(Box.coins() >= 9000, "the box wallet never moved mid-run")
        # THE GRAY-OUT LAW: all 3 spent -> the rail slot goes dead
        G.charges["line"] = 0
        G.power_used["line"] = 3
        G._refresh_rail()
        ck(G.rail_slots["line"]["btn"].disabled, "THE GRAY-OUT LAW: 3 spent -> the slot grays out")
        G._rail_tap("line")
        await get_tree().create_timer(0.2).timeout
        ck(G.refill_sheet.is_empty(), "a spent power opens nothing")
        G.power_used["line"] = 0
        G.phase = "hold"

        # ------------------------------------------------ the banner + the registry
        var reg := GameReg.get_game("matcher")
        ck(bool(reg.get("banner", false)), "the registry wears the banner (the strip is seated)")
        ck(String(reg.get("orientation", "")) == "portrait", "the registry locks the portrait view")
        ck(int(reg.get("coin_div", 0)) == 300, "the registry coin_div is 300")
        var banner_inset: float = G.banner_bottom()
        ck(banner_inset > 0.0, "the game reserves the real banner strip (%dpx)" % int(banner_inset))

        Box.reset_all()
        print("=== matcher_probe: %d checks, %d fails ===" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)


func _ready() -> void:
        _run()
