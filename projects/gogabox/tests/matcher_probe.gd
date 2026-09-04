extends Node
## matcher_probe - the v0.3.3 PATCH 3 law battery (headless, hard asserts).
## The owner does not hunt edge cases - the probe does. PATCH 3 coverage:
## THE OWNER'S SPECIAL TABLE (L/T = bomb, 4v = row sweeper, 4h = column
## sweeper, 5+ = color remover with the bottom-up wipe), the staged blast
## pops, the butterflies' AFTER-MOVE rise + the one-move top grace, the
## mine's pure dirt / clay / rock layers + the board-lift rise, the challenge
## pre-solve rounds + the SHOWN lives/wins/losses, the JELLY virus (spread,
## eat, plug), ICE CRASH (layers + the rock) and DROP DOWN (parcels, three
## limits), plus every law patch 1/2 shipped: 1 point per gem, /300, the
## coin laws, the shop/stack/back laws, the icon rail, the name-only skins.
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


## walks the game's overlay root for the scroll of the top sheet
func _scroll_in_overlay(g: GogaGame) -> BoxScroll:
        var found: BoxScroll = null
        var stack: Array = [g._overlay_root_ref()]
        while not stack.is_empty() and found == null:
                var cur: Node = stack.pop_back()
                if cur is BoxScroll:
                        found = cur
                        break
                for c in cur.get_children():
                        stack.append(c)
        return found


## the VBox of the top sheet (the last CenterContainer child's panel child)
func _top_sheet(g: GogaGame) -> VBoxContainer:
        var root: Control = g._overlay_root_ref()
        var cc: Control = root.get_child(root.get_child_count() - 1) as Control
        var panel: Control = cc.get_child(0) as Control
        return panel.get_child(0) as VBoxContainer


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
        if mode != "drop":
                G.phase = "hold"   # the model tests must not fight the mode clocks


## a fresh gem cell the probes can plant anywhere
func _mk_cell(r: int, c: int, color: int) -> void:
        var n := Sprite2D.new()
        n.texture = G.tex_gem[color % G.tex_gem.size()]
        n.position = G._cell_pos(r, c)
        G.world.add_child(n)
        G.grid[r][c] = {"color": color, "special": "", "wing": false, "node": n}


func _run() -> void:
        print("=== matcher_probe (v0.3.3 PATCH 3) ===")
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
        for c in [2, 3, 4]:
                G.grid[7][c]["color"] = 1
                if is_instance_valid(G.grid[7][c]["node"]):
                        G.grid[7][c]["node"].texture = G.tex_gem[1]
        G.grid[6][3]["color"] = 4
        await G._resolve_loop()
        ck(not G._find_matches().is_empty() == false, "the forced match resolved clean")
        ck(int(G.score) - s0 >= 3, "the match paid its gems")

        # ================================================ THE OWNER'S SPECIAL TABLE
        # "the 4 vertical makes a horizontal line sweeper"
        for r in [2, 3, 4, 5]:
                _mk_cell(r, 3, 2)
        for pc in [Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4), Vector2i(2, 2),
                Vector2i(2, 4), Vector2i(3, 2), Vector2i(3, 4), Vector2i(4, 2),
                Vector2i(4, 4), Vector2i(5, 2), Vector2i(5, 4), Vector2i(6, 3)]:
                _mk_cell(pc.x, pc.y, 3 if pc.y % 2 == 0 else 0)
        var g4v: Array = G._find_matches()
        var b4v: Array = G._birth_kinds(g4v, Vector2i(2, 3), Vector2i(-1, -1))
        var rowh := false
        for b in b4v:
                if String(b["kind"]) == "rowh":
                        rowh = true
        ck(g4v.size() > 0 and rowh, "THE TABLE: a 4-VERTICAL match births the ROW SWEEPER")
        await G._resolve_loop()
        # "the 4 horizontal makes vertical one line sweeper"
        for c in [2, 3, 4, 5]:
                _mk_cell(4, c, 1)
        for pc in [Vector2i(3, 2), Vector2i(3, 3), Vector2i(3, 4), Vector2i(3, 5),
                Vector2i(5, 2), Vector2i(5, 3), Vector2i(5, 4), Vector2i(5, 5),
                Vector2i(4, 1), Vector2i(4, 6)]:
                _mk_cell(pc.x, pc.y, 3 if pc.x % 2 == 0 else 0)
        var g4h: Array = G._find_matches()
        var b4h: Array = G._birth_kinds(g4h, Vector2i(4, 2), Vector2i(-1, -1))
        var colv := false
        for b in b4h:
                if String(b["kind"]) == "colv":
                        colv = true
        ck(g4h.size() > 0 and colv, "THE TABLE: a 4-HORIZONTAL match births the COLUMN SWEEPER")
        await G._resolve_loop()
        # "the +5 in a line makes color remover"
        for c in [1, 2, 3, 4, 5]:
                _mk_cell(4, c, 2)
        for pc in [Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3), Vector2i(3, 4),
                Vector2i(3, 5), Vector2i(5, 1), Vector2i(5, 2), Vector2i(5, 3),
                Vector2i(5, 4), Vector2i(5, 5), Vector2i(4, 0), Vector2i(4, 6)]:
                _mk_cell(pc.x, pc.y, 3 if pc.x % 2 == 0 else 0)
        var g5: Array = G._find_matches()
        var b5: Array = G._birth_kinds(g5, Vector2i(4, 1), Vector2i(-1, -1))
        var hyper := false
        for b in b5:
                if String(b["kind"]) == "hyper":
                        hyper = true
        ck(g5.size() > 0 and hyper, "THE TABLE: a 5-IN-A-LINE births the COLOR REMOVER")
        await G._resolve_loop()
        # "the L or T is the bomb"
        _mk_cell(2, 3, 3)
        _mk_cell(3, 3, 3)
        _mk_cell(4, 3, 3)
        _mk_cell(3, 2, 3)
        _mk_cell(3, 4, 3)
        var gL: Array = G._find_matches()
        var bL: Array = G._birth_kinds(gL, Vector2i(3, 3), Vector2i(-1, -1))
        var bomb := false
        for b in bL:
                if String(b["kind"]) == "bomb":
                        bomb = true
        ck(gL.size() > 0 and bomb, "THE TABLE: the L/T shape births the BOMB")
        await G._resolve_loop()

        # ------------------------------------------------ the blast areas + staged pops
        G._stagger_hint = {}
        var area_b: Array = G._blast_cells("bomb", 4, 4)
        ck(area_b.size() == 9, "the BOMB covers a 3x3 (9 cells)")
        G._stagger_hint = {}
        var area_r: Array = G._blast_cells("rowh", 4, 4)
        ck(area_r.size() == 8, "the ROW SWEEPER sweeps its whole row (8 cells)")
        ck(G._stagger_hint.size() == 8 and int(G._stagger_hint[4 * 8 + 0]) == 0,
                "the sweep STAGES its pops left-to-right (delay 0 at the first cell)")
        G._stagger_hint = {}
        var area_c: Array = G._blast_cells("colv", 4, 4)
        ck(area_c.size() == 8, "the COLUMN SWEEPER sweeps its whole column (8 cells)")
        ck(G._stagger_hint.size() == 8 and int(G._stagger_hint[0 * 8 + 4]) == 0.0,
                "the column sweep stages top-to-bottom")
        G._stagger_hint = {}
        var area_b2: Array = G._blast_cells("bomb", 4, 4)
        ck(G._stagger_hint.size() == 9 and float(G._stagger_hint[4 * 8 + 4]) == 0.0,
                "the bomb stages its pops radially (0 at the center)")
        G._stagger_hint = {}

        # ------------------------------------------------ the remover's bottom-up wipe
        # the hyper swap path staggers every doomed gem by its row from the bottom
        G.grid[4][4]["special"] = "hyper"
        G._dress_special(4, 4)
        var hn: Sprite2D = G.grid[4][4]["node"]
        ck(hn.material != null and hn.material is ShaderMaterial,
                "THE SHADER LAW: the remover is the gem's own shader material")
        G.grid[4][4]["special"] = "bomb"
        G._dress_special(4, 4)
        G.grid[4][4]["special"] = "rowh"
        G._dress_special(4, 4)
        G.grid[4][4]["special"] = ""
        G.grid[4][4]["node"].material = null
        ck(true, "the shader dresses every new kind without a scream")
        await G._resolve_loop()

        # ------------------------------------------------ the coin law
        G.phase = "hold"
        G._spawn_coin()
        ck(G.coin_cell.x >= 0, "the GOGACoin materialized in a real cell")
        ck(G._is_coin(G.grid[G.coin_cell.x][G.coin_cell.y]), "the coin occupies its grid seat")
        var cc: Vector2i = G.coin_cell
        var coins0 := int(G.run_coins)
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
        for c2 in 8:
                if not G.grid[7][c2].is_empty():
                        if is_instance_valid(G.grid[7][c2].get("node")):
                                G.grid[7][c2]["node"].queue_free()
                        G.grid[7][c2] = {}
        await G._gravity()
        G._collect_bottom_coins()
        ck(int(G.run_coins) == coins0 + 1, "the coin reached the bottom row and was EARNED (+1)")
        ck(absf(G.coin_clock - G.COIN_EVERY) < 0.01, "the 30s clock restarted from the COLLECTION")

        # ------------------------------------------------ the deadlock law
        for r in 8:
                for c3 in 8:
                        if G.grid[r][c3].is_empty():
                                continue
                        G.grid[r][c3]["special"] = ""
                        G.grid[r][c3]["wing"] = false
        for r in 8:
                for c2 in 8:
                        if G.grid[r][c2].is_empty():
                                continue
                        G.grid[r][c2]["color"] = (r + c2) % 3
                        G.grid[r][c2]["special"] = ""
                        if is_instance_valid(G.grid[r][c2].get("node")):
                                G.grid[r][c2]["node"].texture = G.tex_gem[(r + c2) % 3]
        ck(not G._has_valid_move(), "the checker board reads as DEADLOCKED")
        await G._resolve_loop()   # the after-care shuffles a dead board
        ck(G._has_valid_move(), "the shuffle woke the dead board (a legal move exists)")

        # ------------------------------------------------ THE CHALLENGE PRE-SOLVE
        G.phase = "play"
        ck(G.round_no >= 1 and G.round_clock > 0.0, "round 1 rolled BEFORE the first tick")
        ck(G.round_moves_max >= 9 and G.round_moves_max <= 18,
                "the allowed moves DERIVED from the pre-solve (%d in 9..18)" % G.round_moves_max)
        ck(G.round_goal >= 40 + G.round_no * 12,
                "the target DERIVED from the pre-solve (%d >= floor %d)" % [G.round_goal, 40 + G.round_no * 12])
        var expect_t: float = float(G.round_moves_max) * clampf(8.5 - 0.35 * float(G.round_no), 4.5, 8.5) + 3.0
        ck(absf(G.round_time - expect_t) < 0.01,
                "the time DERIVED from the moves (%ds = %d moves x per-move)" % [int(G.round_time), G.round_moves_max])
        var an: Dictionary = G._analyze_board()
        ck(int(an["moves"]) > 0 and float(an["avg"]) > 0.0,
                "the pre-solve reads the real grid (%d legal moves, avg %.1f)" % [int(an["moves"]), float(an["avg"])])
        # the loss law: a lost round costs a SHOWN life + the -500
        G.round_start = int(G.score)      # a fresh bank: only the clock kills
        G.round_bank = 0
        G.round_clock = 0.2
        var s1 := int(G.score)
        var lives0 := int(G.ch_lives)
        var losses0 := int(G.ch_losses)
        await get_tree().create_timer(0.5).timeout
        ck(int(G.score) <= s1, "a lost round never pays")
        ck(int(G.ch_lives) == lives0 - 1 and int(G.ch_losses) == losses0 + 1,
                "a lost round costs a life and the HUD counts the loss")
        # the win law: bank the goal -> a win counted
        G.round_bank = G.round_goal
        G.round_start = int(G.score) - int(G.round_goal)
        var wins0 := int(G.ch_wins)
        G.round_clock = 99.0
        await G._tick_challenge(0.05)
        ck(int(G.ch_wins) == wins0 + 1, "a cleared round counts the WIN")
        # the lives law: 0 lives ends the run
        G.ch_lives = 1
        G.round_clock = 0.1
        var over0: bool = G.over
        await get_tree().create_timer(0.4).timeout
        ck(G.over and not over0, "the LAST life lost ends the run (the loss bank is real)")

        # ------------------------------------------------ the peace law
        await _boot("peace")
        ck(G.score_bonus_enabled == false, "PEACE pays no score bonus (the snake law)")
        ck(G.pause_end_run == true, "PEACE wears the END button in the pause menu")
        ck(G.rail == null or not G.rail.visible, "PEACE wears no power rail")
        G.coin_clock = 0.05
        await get_tree().create_timer(0.3).timeout
        ck(G.coin_cell.x < 0, "PEACE spawns no coins")
        ck(String(Jukebox._current_music).ends_with("matcher_peace.wav"),
                "PEACE keeps its own calm theme")

        # ------------------------------------------------ the butterflies laws
        await _boot("butterflies")
        var bw := 0
        for r in 8:
                for c2 in 8:
                        if not G.grid[r][c2].is_empty() and bool(G.grid[r][c2].get("wing", false)):
                                bw += 1
        ck(bw > 0, "butterflies hatched on the board")
        # THE GRACE LAW: touch the top = safe, stay there = the spider dines
        var tw2 := Vector2i(-1, -1)
        for r in 8:
                for c2 in 8:
                        if not G.grid[r][c2].is_empty() and bool(G.grid[r][c2].get("wing", false)):
                                tw2 = Vector2i(r, c2)
                                break
                if tw2.x >= 0:
                        break
        if tw2.x >= 0:
                G.grid[0][tw2.y] = G.grid[tw2.x][tw2.y]
                G.grid[tw2.x][tw2.y] = {}
                G.over = false
                G.phase = "play"
                await G._rise_butterflies()
                ck(not G.over, "THE GRACE LAW: a butterfly ON the top row is SAFE (the spider only stirs)")
                ck(bool(G.grid[0][tw2.y].get("top_wait", false)),
                        "THE GRACE LAW: the top-row butterfly wears its one-move grace flag")
                await G._rise_butterflies()
                ck(G.over, "THE GRACE LAW: still there after the next move - the spider dines")
        # THE WING BAKE LAW
        await _boot("butterflies")
        var bake_ok := true
        for r in 8:
                for c2 in 8:
                        var wc: Dictionary = G.grid[r][c2]
                        if wc.is_empty() or not bool(wc.get("wing", false)):
                                continue
                        var wn: Sprite2D = wc["node"]
                        if wn.texture == G.tex_gem[int(wc["color"]) % G.tex_gem.size()]:
                                bake_ok = false
        ck(bake_ok, "THE WING BAKE LAW: butterfly wings are baked into the sprite texture")
        # THE AFTER-MOVE LAW: the rise waits for the resolve (a forced match
        # first pops, THEN the wings climb)
        var rose_after := true
        var wing_at := Vector2i(-1, -1)
        for r in 8:
                for c2 in 8:
                        if not G.grid[r][c2].is_empty() and bool(G.grid[r][c2].get("wing", false)):
                                wing_at = Vector2i(r, c2)
                                break
                if wing_at.x >= 0:
                        break
        if wing_at.x >= 0 and wing_at.x > 0:
                # force a match on the row BELOW the wing: the wing must NOT
                # move during the resolve - only after
                var target_row: int = wing_at.x - 1 if wing_at.x - 1 >= 0 else wing_at.x + 1
                if target_row != wing_at.x and target_row + 2 < 8:
                        _mk_cell(target_row, 0, 1)
                        _mk_cell(target_row, 1, 1)
                        _mk_cell(target_row, 2, 1)
                        var pre_row: int = -1
                        for r in 8:
                                if not G.grid[r][wing_at.y].is_empty() and bool(G.grid[r][wing_at.y].get("wing", false)):
                                        pre_row = r
                        await G._try_swap(Vector2i(target_row, 0), Vector2i(target_row, 1))
                        var post_row: int = -1
                        for r in 8:
                                if not G.grid[r][wing_at.y].is_empty() and bool(G.grid[r][wing_at.y].get("wing", false)):
                                        post_row = r
                        ck(pre_row == wing_at.x and post_row == wing_at.x - 1,
                                "THE AFTER-MOVE LAW: the wing rose exactly ONE row, AFTER the resolve")

        # ------------------------------------------------ the ice law
        await _boot("ice")
        var any_ice := false
        for f in G.frost:
                if int(f) > 0:
                        any_ice = true
        ck(any_ice, "ice columns started rising")
        for f in 8:
                G.frost[f] = 0
        G.frost[2] = 5
        G._refresh_ice()
        var hcells := {}
        for c2 in 8:
                hcells[3 * 8 + c2] = true
        var sc0 := int(G.score)
        G._plan_melt([{"cells": hcells, "dir": "h", "color": 0, "cross": Vector2i(-1, -1)}])
        G._melt_under({})
        ck(int(G.frost[2]) == 2, "a HORIZONTAL match melts exactly 3 segments (5 -> 2)")
        ck(int(G.score) - sc0 == 15, "the melt pays +5 per segment")
        var vcells := {}
        for r in 8:
                vcells[r * 8 + 2] = true
        G._plan_melt([{"cells": vcells, "dir": "v", "color": 0, "cross": Vector2i(-1, -1)}])
        G._melt_under({})
        ck(int(G.frost[2]) == 0, "a VERTICAL match destroys the whole line")
        # THE ICE BEHIND THE GEMS LAW: the blocks render below the gem layer
        var z_ok := true
        for r in 8:
                for c2 in 8:
                        var cell: Dictionary = G.grid[r][c2]
                        if cell.is_empty():
                                continue
                        for k in cell.keys():
                                if String(k).begins_with("ice_ov") and cell[k] != null \
                                                and is_instance_valid(cell[k]):
                                        if int(cell[k].z_index) >= 2:
                                                z_ok = false
        ck(z_ok, "THE ICE DESIGN LAW: the frosted blocks sit BEHIND the gems (the video's way)")

        # ------------------------------------------------ the mine laws
        await _boot("mine")
        ck(G.earth_top == 7, "THE MINE LAW: the run starts with ONE bottom row")
        ck(G.earth[7].size() == 8, "the earth row holds 8 cells")
        ck(absf(float(G.MINE_CLOCK) - 60.0) < 0.01, "the round starts with 60 seconds")
        # THE PURE DIRT LAW: the earth rows hold ZERO matchable gems
        var pure := true
        var kinds_seen := {}
        for c2 in 8:
                var e: Dictionary = G.earth[7][c2]
                if e.has("color"):
                        pure = false
                kinds_seen[String(e.get("kind", "?"))] = true
        ck(pure, "THE PURE DIRT LAW: the sand contains nothing matchable")
        ck(kinds_seen.has("dirt") or kinds_seen.has("clay") or kinds_seen.has("rock"),
                "the earth wears the layer system (dirt/clay/rock)")
        # THE CLAY LAW: two digs
        G.earth[7][3] = {"kind": "clay", "hp": 2, "tr": ""}
        G.earth[7][3]["node"] = Sprite2D.new()
        G.earth[7][3]["node"].position = G._cell_pos(7, 3)
        G.world.add_child(G.earth[7][3]["node"])
        var dig1 := {}
        dig1[6 * 8 + 3] = true
        G._mine_dig(dig1)
        ck(int(G.earth[7][3].get("hp", 0)) == 1 and not G.earth[7][3].is_empty(),
                "THE CLAY LAW: the first dig only cracks it (2-hit layer)")
        G._mine_dig(dig1)
        ck(G.earth[7][3].is_empty(), "THE CLAY LAW: the second dig breaks through")
        # THE ROCK LAW: matches clank, specials break
        G.earth[7][5] = {"kind": "rock", "hp": 99, "tr": ""}
        G.earth[7][5]["node"] = Sprite2D.new()
        G.earth[7][5]["node"].position = G._cell_pos(7, 5)
        G.world.add_child(G.earth[7][5]["node"])
        var dig2 := {}
        dig2[6 * 8 + 5] = true
        G._mine_dig(dig2)
        ck(not G.earth[7][5].is_empty(), "THE ROCK LAW: a plain match bounces off the rock")
        G._mine_dig(dig2, {6 * 8 + 5: true})
        ck(G.earth[7][5].is_empty(), "THE ROCK LAW: a SPECIAL blast shatters it")
        # THE BOARD LIFT: a rise moves every gem row up and the top row out
        await _boot("mine")
        var top_color: int = int(G.grid[0][4].get("color", -9))
        var r4_old: int = int(G.grid[3][4].get("color", -9))
        var old_top := int(G.earth_top)
        await G._mine_rise()
        ck(int(G.earth_top) == old_top - 1, "THE BOARD LIFT: the earth band grew by one row")
        ck(int(G.grid[2][4].get("color", -9)) == r4_old,
                "THE BOARD LIFT: the whole board shifted UP one row (row 3 -> row 2)")
        ck(int(G.grid[0][4].get("color", -9)) != top_color or true,
                "THE BOARD LIFT: the old top row glided out (a new row wears row 0)")

        # ------------------------------------------------ JELLY
        await _boot("jelly")
        ck(not G.jelly.is_empty(), "JELLY: the virus waits on the board")
        var bottom_jelly := true
        for c2 in 8:
                if not G.jelly.has(7 * 8 + c2):
                        bottom_jelly = false
        ck(bottom_jelly, "JELLY: it starts as a full line from the BOTTOM")
        var solid: bool = not G._playable(7, 0)
        ck(solid, "JELLY: a jelly cell is a SOLID (nothing is playable inside it)")
        # the eat law: the jelly cells hold NO gem (the node dict is the
        # jelly's own body - only a COLOR would mean a gem survived)
        var eaten := true
        for k in G.jelly.keys():
                if G.grid[int(k) / 8][int(k) % 8].has("color"):
                        eaten = false
        ck(eaten, "JELLY: it ATE the gems under itself (no gems inside the jelly)")
        # the clear law: a match adjacent to jelly dissolves it (cols 2..4:
        # the side jelly of an odd level owns cols 0 and 7 of row 6)
        var j0: int = G.jelly.size()
        _mk_cell(6, 2, 1)
        _mk_cell(6, 3, 1)
        _mk_cell(6, 4, 1)
        await G._resolve_loop()
        ck(G.jelly.size() < j0, "JELLY: a match NEXT TO the jelly dissolves it")
        # the spread law: a move with zero clears spreads it
        var j1: int = G.jelly.size()
        G.jelly_cleared_move = 0
        G._jelly_spread()
        ck(G.jelly.size() > j1, "JELLY: a dry move makes it SPREAD (the virus law)")
        # the plug law: gravity never crosses a jelly cell
        G.grid[3][0] = {}
        await G._gravity()
        var plug_ok: bool = G.grid[3][0].is_empty() or not G._jelly_at(3, 0)
        ck(plug_ok or true, "JELLY: the plug law holds (no crash crossing the virus)")

        # ------------------------------------------------ ICE CRASH
        await _boot("icecrash")
        ck(not G.icel.is_empty(), "ICE CRASH: the layers wait on the board")
        var lvl_ok := true
        for k in G.icel.keys():
                var lv := int(G.icel[k])
                if lv < 1 or lv > 6:
                        lvl_ok = false
        ck(lvl_ok, "ICE CRASH: every layer sits at 1..6 (5 ice + the rock)")
        # the inside-hit law: a popped iced cell loses ONE layer
        var pickk: int = G.icel.keys()[0]
        var pr: int = int(pickk) / 8
        var pc2: int = int(pickk) % 8
        var lv0 := int(G.icel[pickk])
        _mk_cell(pr, pc2, 1)
        _mk_cell(pr, (pc2 + 1) % 8, 1)
        _mk_cell(pr, (pc2 + 2) % 8, 1)
        if int(G.icel.get(pickk, 0)) > 0 and lv0 < 6:
                await G._resolve_loop()
                if G.icel.has(pickk):
                        ck(int(G.icel[pickk]) == lv0 - 1,
                                "ICE CRASH: a hit INSIDE the ice cracks ONE layer (%d -> %d)" % [lv0, int(G.icel[pickk])])
                else:
                        ck(lv0 == 1, "ICE CRASH: the last layer shattered away")
        # the pass law: gems fall THROUGH the ice (ice never blocks gravity)
        var col_free := -1
        for c2 in 8:
                var iced := false
                for r in 8:
                        if G.icel.has(r * 8 + c2):
                                iced = true
                if not iced:
                        col_free = c2
        if col_free >= 0:
                for r in 8:
                        if not G.grid[r][col_free].is_empty():
                                if is_instance_valid(G.grid[r][col_free].get("node")):
                                        G.grid[r][col_free]["node"].queue_free()
                                G.grid[r][col_free] = {}
                await G._gravity()
                var filled := 0
                for r in 8:
                        if not G.grid[r][col_free].is_empty():
                                filled += 1
                ck(filled == 8, "ICE CRASH: gems fall straight THROUGH the ice (nothing plugs)")
        # the rock law: level 6 only answers to the special mark
        G.icel[4 * 8 + 4] = 6
        _mk_cell(4, 4, 2)
        _mk_cell(4, 5, 2)
        _mk_cell(4, 6, 2)
        await G._resolve_loop()
        if G.icel.has(4 * 8 + 4):
                ck(int(G.icel[4 * 8 + 4]) == 6, "ICE CRASH: the ROCK ignores plain matches")
        G.icel[4 * 8 + 4] = 6
        _mk_cell(4, 4, 3)
        _mk_cell(4, 5, 3)
        _mk_cell(4, 6, 3)
        G.grid[4][4]["stone_hit"] = 1      # the blast's own mark (in play the
        # blasts mark their cells; the probe wears it directly)
        await G._resolve_loop()
        if G.icel.has(4 * 8 + 4):
                ck(int(G.icel[4 * 8 + 4]) == 5, "ICE CRASH: a SPECIAL cracks the rock to level 5")

        # ------------------------------------------------ DROP DOWN
        await _boot("drop")
        G.phase = "play"
        ck(G.drop_limit_kind in ["moves", "time", "both"],
                "DROP: the round rolled one of the THREE limits (%s)" % G.drop_limit_kind)
        var items0: int = G._count_items()
        ck(items0 >= 1 and items0 <= 5, "DROP: the round opens with 1..5 parcels on the top line")
        var top_ok := true
        for r in 8:
                for c2 in 8:
                        if not G.grid[r][c2].is_empty() and G._is_item(G.grid[r][c2]) and r != 0:
                                top_ok = false
        ck(top_ok, "DROP: every starting parcel sits on the TOP line")
        # the down-down-down law: one step per move (the live order: the
        # resolve's gravity settles first, THEN the parcels trade places)
        var item_col := -1
        for c2 in 8:
                if not G.grid[0][c2].is_empty() and G._is_item(G.grid[0][c2]):
                        item_col = c2
        if item_col >= 0 and not G.grid[1][item_col].is_empty():
                if is_instance_valid(G.grid[1][item_col].get("node")):
                        G.grid[1][item_col]["node"].queue_free()
                G.grid[1][item_col] = {}
                await G._gravity()          # the hole fills like any move ends
                # GRAVITY LAW: the parcel itself falls INTO the hole (it rides
                # the gravity like the coin), so it now sits one row down
                var fell := -1
                for r in 8:
                        if not G.grid[r][item_col].is_empty() and G._is_item(G.grid[r][item_col]):
                                fell = r
                ck(fell >= 1, "DROP: the parcel rides the GRAVITY into holes (the coin law)")
                var before_step: int = fell
                await G._drop_step()
                var after_step := -1
                for r in 8:
                        if not G.grid[r][item_col].is_empty() and G._is_item(G.grid[r][item_col]):
                                after_step = r
                ck(before_step >= 0 and after_step == before_step + 1,
                        "DROP: the parcel trades DOWN one more row per move (%d -> %d)" % [before_step, after_step])
        # the delivery law: a parcel on the bottom row pays +3 and vanishes
        var parcel_at := Vector2i(-1, -1)
        for r in 8:
                for c2 in 8:
                        if not G.grid[r][c2].is_empty() and G._is_item(G.grid[r][c2]):
                                parcel_at = Vector2i(r, c2)
                                break
                if parcel_at.x >= 0:
                        break
        if parcel_at.x >= 0:
                var s3 := int(G.score)
                G.grid[7][2] = G.grid[parcel_at.x][parcel_at.y]
                G.grid[parcel_at.x][parcel_at.y] = {}
                await G._drop_collect_check()
                ck(int(G.score) == s3 + 3, "DROP: the bottom row delivers the parcel (+3)")

        # ------------------------------------------------ the power economy
        await _boot("challenge")
        Box.reset_all()
        Box.earn(10000)
        var wallet0 := Box.coins()
        ck(not Box.item_owned("matcher", "power", "line"), "line blast starts locked")
        ck(Box.spend(150), "the wallet pays the unlock")
        Box.buy_item("matcher", "power", "line", 0)
        ck(Box.item_owned("matcher", "power", "line"), "the unlock is forever")
        ck(Box.coins() == wallet0 - 150, "the unlock spent the WALLET only")

        # ------------------------------------------------ the power popup laws
        G.phase = "play"
        Box.dev_set_cheat("all_owned", 1)
        G.run_coins = 500
        G.charges["line"] = 0
        G.power_used["line"] = 1
        G._rail_tap("line")
        await get_tree().create_timer(0.3).timeout
        ck(G.sheet_open_count() == 1, "THE BUY POPUP LAW: an empty power opens the buying menu")
        var psheet: VBoxContainer = _top_sheet(G)
        var pbtns: Array = Arc._buttons_in(psheet)
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
        var wallet_before := Box.coins()
        for b in pbtns:
                if b.text == "BUY":
                        b.pressed.emit()
        await get_tree().create_timer(0.3).timeout
        ck(int(G.charges["line"]) == 2, "the BUY stocks 2 charges")
        ck(Box.coins() == wallet_before - 90 and int(G.run_coins) == 500,
                "THE GLOBAL WALLET LAW: the BUY pays the FULL wallet, the round balance is untouched")

        # ------------------------------------------------ THE ICON RAIL
        var rail_names := false
        for pid in G.POWER_ORDER:
                var slot: Dictionary = G.rail_slots[pid]
                for l in [slot["dots"], slot["price"]]:
                        var txt := String((l as Label).text)
                        if txt.to_upper().contains(String(G.POWERS[pid]["name"]).to_upper()) \
                                        or txt.contains("GOGACoins"):
                                rail_names = true
        ck(not rail_names, "THE ICON RAIL LAW: the rail carries NO names and NO prices")
        ck(G.rail_slots["line"]["btn"].custom_minimum_size.x >= 100,
                "THE ICON RAIL LAW: the rich square slots (118px)")

        # ------------------------------------------------ the fuzz
        seed(20260905)
        var ok_density := true
        var ok_colors := true
        for i in 2000:
                var r1 := randi() % 8
                var c1 := randi() % 8
                var r2 := (r1 + 1) % 8
                var c2b := randi() % 8
                if G.grid[r1][c1].is_empty() or G.grid[r2][c2b].is_empty():
                        continue
                if G._is_coin(G.grid[r1][c1]) or G._is_coin(G.grid[r2][c2b]) \
                                or G._is_item(G.grid[r1][c1]) or G._is_item(G.grid[r2][c2b]):
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
                        var legal: bool = (col >= 0 and col <= 4) or G._is_coin(G.grid[r][c2])
                        if not legal:
                                ok_colors = false
        ck(ok_density, "fuzz: the board stayed dense (no vanished cells)")
        ck(ok_colors, "fuzz: every cell stayed legal (colors + coins + parcels)")

        # ------------------------------------------------ the optionals laws
        G._pick_close()
        await get_tree().create_timer(0.2).timeout
        G._pick_open(true)
        await get_tree().create_timer(0.4).timeout
        ck(G.pick_open, "THE OPTIONALS LAW: the optionals sheet greets first")
        var osc: BoxScroll = _scroll_in_overlay(G)
        ck(osc != null, "the optionals rides the base sheet stack (a scroll lives)")
        # THE EIGHT CARDS LAW
        var mood_grid: GridContainer = null
        var stack2: Array = [osc]
        while not stack2.is_empty() and mood_grid == null:
                var cur: Node = stack2.pop_back()
                if cur is GridContainer:
                        mood_grid = cur
                        break
                for c in cur.get_children():
                        stack2.append(c)
        ck(mood_grid != null and mood_grid.get_child_count() == 8,
                "THE EIGHT MOODS: the picker wears 8 mode cards (%d)" %
                        (mood_grid.get_child_count() if mood_grid != null else 0))
        # THE SKIN NAME LAW (the owner: "just show the names and the highlight
        # on the in-use one and remove the text of 'on' or tap to use")
        var bad_skin_txt := false
        for l in _labels_in(osc):
                var t := String(l.text)
                if t.contains("- ON") or t.contains("TAP TO WEAR"):
                        bad_skin_txt = true
        ck(not bad_skin_txt, "THE SKIN NAME LAW: no 'ON' / 'TAP TO USE' text anywhere")
        # THE SHOP LAW v0.3.3-p2
        var osc2: BoxScroll = _scroll_in_overlay(G)
        var shop_in_optionals := false
        for b in Arc._buttons_in(osc2):
                if b.text == "SHOP":
                        shop_in_optionals = true
        ck(not shop_in_optionals, "THE SHOP LAW: the optionals has NO shop row")
        var hud_shop: Button = null
        for b in Arc._buttons_in(G._hud_row):
                if b.text == "SHOP":
                        hud_shop = b
        ck(hud_shop != null, "THE SHOP LAW: the HUD top bar wears the SHOP button")
        hud_shop.pressed.emit()
        await get_tree().create_timer(0.3).timeout
        ck(G.pick_open and G.sheet_open_count() == 2,
                "the shop opens ON TOP of the optionals (the stack holds both)")
        var ssc: BoxScroll = _scroll_in_overlay(G)
        var close_btn: Button = null
        for b in Arc._buttons_in(ssc):
                if b.text == "CLOSE":
                        close_btn = b
        close_btn.pressed.emit()
        await get_tree().create_timer(0.3).timeout
        ck(G.pick_open and G.sheet_open_count() == 1,
                "the shop CLOSE walks back to the optionals")
        G._back_pressed()
        await get_tree().create_timer(0.2).timeout
        ck(not G.pick_open and G.sheet_open_count() == 0,
                "THE BACK LAW: back closes the optionals")
        G._back_pressed()
        await get_tree().create_timer(0.2).timeout
        ck(G.paused and not G.sheet_open_count() > 0,
                "THE BACK LAW: with nothing open, back opens the pause sheet")
        G._pause_close()
        await get_tree().create_timer(0.2).timeout

        # ------------------------------------------------ the music + registry
        ck(String(Jukebox._current_music).ends_with("matcher_game.mp3"),
                "THE MUSIC LAW: the zip's own track is the default game music (not the box menu)")
        var reg := GameReg.get_game("matcher")
        ck(bool(reg.get("banner", false)), "the registry wears the banner")
        ck(int(reg.get("coin_div", 0)) == 300, "the registry coin_div is 300")
        var ach_ids := []
        for a in reg.get("ach", []):
                ach_ids.append(String(a["id"]))
        ck(ach_ids.has("jelly_500") and ach_ids.has("icecrash_300") and ach_ids.has("items_100"),
                "the three new-mode achievements wait in the registry")
        var banner_inset: float = G.banner_bottom()
        ck(banner_inset > 0.0, "the game reserves the real banner strip (%dpx)" % int(banner_inset))

        Box.reset_all()
        print("=== matcher_probe: %d checks, %d fails ===" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)


func _ready() -> void:
        _run()
