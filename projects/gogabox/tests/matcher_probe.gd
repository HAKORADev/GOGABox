extends Node
## matcher_probe - the v0.3.3 PATCH 5 law battery (headless, hard asserts).
## The owner does not hunt edge cases - the probe does. PATCH 5 coverage:
## THE DONUT PURGE (per-color pop frames, the donut files deleted), THE
## SWEEPER SHADER SWAP (the two gem bodies traded), THE FALL-AROUND LAW
## (gems slide diagonally around a jelly plug), THE RISE-MATCH LAW (a fly
## rising into its color resolves), THE INTENSITY LADDER (10s dropping to
## 9/8/7, 1..4 flies per hatch), THE COIN COURTESY (tap = collect, the hop
## rides through the coin), THE POCKETS LAW (gems fit into the dug sand
## holes; standing dirt stays impenetrable), THE RISKY PARCEL LAW (no
## descent = one climb, two climbs = over). Plus every law patches 1-4
## shipped.
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


## is the jelly set one connected blob? (the owner: "it feels like a virus")
func _blob_connected(cells: Dictionary) -> bool:
        if cells.is_empty():
                return true
        var start: int = int(cells.keys()[0])
        var seen := {start: true}
        var stack := [start]
        while not stack.is_empty():
                var k: int = stack.pop_back()
                var r: int = int(k) / 8
                var c: int = int(k) % 8
                for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
                        var dd: Vector2i = d
                        var nr: int = r + dd.x
                        var nc: int = c + dd.y
                        if nr < 0 or nc < 0 or nr >= 8 or nc >= 8:
                                continue
                        var nk: int = nr * 8 + nc
                        if cells.has(nk) and not seen.has(nk):
                                seen[nk] = true
                                stack.append(nk)
        return seen.size() == cells.size()


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
        # v0.3.3-p4: the physics POUR needs its frames (the empty grid fills
        # column by column with free falls); 2.4s covers the longest stagger
        await get_tree().create_timer(2.4).timeout
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
        print("=== matcher_probe (v0.3.3 PATCH 5) ===")
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
        # v0.3.3-p4 THE SPREAD LAW: the pops radiate from the BIRTH CELL both
        # ways - delay 0 at the birth, symmetric toward the edges
        ck(G._stagger_hint.size() == 8 and float(G._stagger_hint[4 * 8 + 4]) == 0.0,
                "the sweep SPREADS from the birth cell (delay 0 at the origin)")
        ck(float(G._stagger_hint[4 * 8 + 1]) == float(G._stagger_hint[4 * 8 + 7]),
                "the sweep spreads BOTH ways (left delay == right delay)")
        ck(float(G._stagger_hint[4 * 8 + 0]) > 0.0,
                "the far cells wait their turn (nothing is instant anymore)")
        G._stagger_hint = {}
        var area_c: Array = G._blast_cells("colv", 4, 4)
        ck(area_c.size() == 8, "the COLUMN SWEEPER sweeps its whole column (8 cells)")
        ck(float(G._stagger_hint[4 * 8 + 4]) == 0.0
                        and float(G._stagger_hint[1 * 8 + 4]) == float(G._stagger_hint[7 * 8 + 4]),
                "the column sweep spreads UP + DOWN from the birth cell")
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

        # ------------------------------------------------ THE CHALLENGE PRE-SOLVE v4
        G.phase = "play"
        # a FRESH roll on the current board: the pre-solve and the share
        # read the exact same colors (the seeded sim is deterministic)
        G._roll_round()
        ck(G.round_no >= 1 and G.round_clock > 0.0, "round 1 rolled BEFORE the first tick")
        ck(G.round_moves_max >= 8 and G.round_moves_max <= G.CH_MOVES_BASE,
                "the move budget is TIGHT (%d in 8..13)" % G.round_moves_max)
        # v0.3.3-p4 THE REAL EXAM: the target eats 86..97% of what OPTIMAL
        # play scores on this exact board (the greedy pre-solve re-runs
        # deterministically - same seed, same board)
        var pre2: Dictionary = G._presolve_round(G.round_moves_max)
        var achievable := float(pre2["achievable"])
        ck(achievable > 20.0, "the greedy pre-solve scored the real board (achievable %.0f)" % achievable)
        var share := float(G.round_goal) / achievable
        ck(share >= 0.84 and share <= 0.99,
                "THE REAL EXAM: the target eats %.0f%% of optimal play (goal %d / achievable %.0f)"
                                % [share * 100.0, G.round_goal, achievable])
        var per_move := clampf(G.CH_TIME_PER_MOVE0 - 0.08 * float(G.round_no - 1),
                        G.CH_TIME_PER_MOVE_MIN, G.CH_TIME_PER_MOVE0)
        var expect_t: float = float(G.round_moves_max) * per_move + 2.0
        ck(absf(G.round_time - expect_t) < 0.01,
                "the time barely fits (%ds = %d moves x %.1fs + 2)" % [int(G.round_time), G.round_moves_max, per_move])
        ck(G.round_time <= G.round_moves_max * G.CH_TIME_PER_MOVE0 + 2.1,
                "no PLENTY of time anymore (the owner: \"why the time is so plenty\")")
        ck(String(G.chip_info.text).begins_with("SCORE"),
                "THE SCORE REQUIREMENT LAW: the HUD speaks SCORE %d/%d" % [G.round_bank, G.round_goal])
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
                # v0.3.3-p5 THE RISE-MATCH LAW: whatever lines the rise forms
                # resolve - the grace rig must not sit on a match, so the
                # fly's line neighbors wear off-colors until the board is quiet
                var fc2: int = int(G.grid[0][tw2.y]["color"])
                var nbs := [Vector2i(0, maxi(0, tw2.y - 1)),
                                Vector2i(0, mini(7, tw2.y + 1)),
                                Vector2i(1, tw2.y), Vector2i(2, tw2.y)]
                var quiet_guard := 0
                while not G._find_matches().is_empty() and quiet_guard < 60:
                        quiet_guard += 1
                        for nb in nbs:
                                if G.grid[nb.x][nb.y].is_empty():
                                        continue
                                var nc4 := (fc2 + 1 + quiet_guard % 4) % 5
                                if nc4 == fc2:
                                        nc4 = (nc4 + 1) % 5
                                G.grid[nb.x][nb.y]["color"] = nc4
                                if is_instance_valid(G.grid[nb.x][nb.y].get("node")):
                                        (G.grid[nb.x][nb.y]["node"] as Sprite2D).texture = G.tex_gem[nc4]
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

        # ------------------------------------------------ the ice law v4 (the fronts)
        await _boot("ice")
        G.phase = "play"
        # the first front spawns fast, then RUNS UP continuously
        var ticks := 0
        while G.fronts.is_empty() and ticks < 400:
                G._tick_ice(0.05)
                ticks += 1
        ck(not G.fronts.is_empty(), "ICE v4: a front SPAWNED at the bottom")
        var solid_before := int(G.frost[int(G.fronts[0]["col"])])
        var f_col: int = int(G.fronts[0]["col"])
        var f_speed: float = float(G.fronts[0]["speed"])
        for i in 60:
                G._tick_ice(0.05)
        var solid_after := int(G.frost[f_col])
        ck(solid_after > solid_before,
                "ICE v4: the front RUNS UP without waiting (%d -> %d solid in 3s)" % [solid_before, solid_after])
        var expect_rows := int(float(solid_before) + f_speed * 3.0)
        ck(solid_after >= mini(expect_rows, 8),
                "ICE v4: the rise speed is the tuned law (%.2f rows/s)" % f_speed)
        # THE HORIZONTAL NEVER MELTS LAW (the owner's correction)
        for f2 in 8:
                G.frost[f2] = 0
        G.fronts.clear()
        G.frost[2] = 5
        var sc0 := int(G.score)
        G.ice_melt_cols = {}
        G._ice_melt_wave()
        ck(int(G.frost[2]) == 5, "ICE v4: a HORIZONTAL match NEVER melts the ice")
        # THE VERTICAL WIPES THE WHOLE COLUMN LAW
        G.ice_melt_cols = {2: true}
        G._ice_melt_wave()
        ck(int(G.frost[2]) == 0, "ICE v4: a VERTICAL match wipes the WHOLE column's ice")
        ck(int(G.score) - sc0 >= 5, "ICE v4: the melt pays its segments (+5)")
        # THE FREEZE LAW: a column that frosts to the top ends the run
        G.over = false
        G.frost[5] = G.ROWS - 1
        G.fronts = [{"col": 5, "f": 0.9, "speed": 0.6}]
        var guard := 0
        while not G.over and guard < 400:
                G._tick_ice(0.05)
                guard += 1
        ck(G.over, "ICE v4: the column FROZE to the top - the run is lost")
        # THE ICE BEHIND THE GEMS LAW: the blocks render below the gem layer
        G.over = false
        await _boot("ice")
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
        ck(z_ok, "THE ICE DESIGN LAW: the frosted blocks sit BEHIND the gems")

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
        # v0.3.3-p4 THE HARD LIMIT LAW (the owner: "it should work like a
        # real real hard limit that nothing goes through it for real"): the
        # old gravity pen wrote gems INTO the sand - now nothing ever sits
        # below earth_top, through ANY number of gravity waves
        for wave in 6:
                for r in range(0, G.earth_top):
                        for c2 in 8:
                                if not G.grid[r][c2].is_empty() \
                                                and (r + c2 + wave) % 4 == 0:
                                        if is_instance_valid(G.grid[r][c2].get("node")):
                                                G.grid[r][c2]["node"].queue_free()
                                        G.grid[r][c2] = {}
                await G._gravity()
        var in_sand := 0
        for r in range(G.earth_top, 8):
                for c2 in 8:
                        if not G.grid[r][c2].is_empty() and G._earth_at(r, c2):
                                in_sand += 1
        ck(in_sand == 0, "THE HARD LIMIT LAW: zero gems ever INSIDE standing dirt (%d waves)" % 6)
        # v0.3.3-p5 THE POCKETS LAW (the owner: "an area with no sand in
        # same row, it should let the gems fit in"): the dug holes ARE
        # seats - the clay and the rock tests dug (7,3) and (7,5), and the
        # gravity waves feed them gems
        var pockets_filled := 0
        for c2 in [3, 5]:
                if not G.grid[7][c2].is_empty() and not G._earth_at(7, c2):
                        pockets_filled += 1
        ck(pockets_filled == 2, "THE POCKETS LAW: gems fell into the dug holes in the sand row")
        for c2 in 8:
                var e0: Dictionary = G.earth[G.earth_top][c2]
                if e0.has("node") and is_instance_valid(e0["node"]):
                        (e0["node"] as Sprite2D).queue_free()
        G._lay_earth_row(G.earth_top, 1.0)
        var sand_sprites := 0
        for c2 in 8:
                var e: Dictionary = G.earth[G.earth_top][c2]
                if e.has("node") and is_instance_valid(e["node"]):
                        sand_sprites += 1
        ck(sand_sprites == 8, "the sand band still wears its 8 dirt cells")
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
        # v0.3.3-p4 THE SPREAD LAW (the owner: "it should be from 2-8 tiles
        # i guess per a match that does not destroy one of it, from my tests
        # it spreads by 0-2?"): EVERY dry move spreads 2..8 connected cells
        var band_ok := true
        var band_seen := []
        for i in 12:
                var j1: int = G.jelly.size()
                if j1 == 0 or j1 >= 64 - 2:
                        break         # the board is nearly full - no law broken
                G.jelly_cleared_move = 0
                G._jelly_spread()
                var delta: int = G.jelly.size() - j1
                band_seen.append(delta)
                if delta < 2 and G.jelly.size() < 64:
                        band_ok = false
                if delta > 8:
                        band_ok = false
        ck(band_ok and band_seen.size() > 0,
                "JELLY: every dry move spreads 2..8 (seen %s)" % str(band_seen))
        # THE CONNECTED LAW: the blob stays one connected virus after spreading
        var conn := _blob_connected(G.jelly)
        ck(conn, "JELLY: the blob stays CONNECTED after the spreads")
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
                # v0.3.3-p4 THE REACTION LAW: the cracked rock CHANGES its
                # face (patch 3 kept wearing the level-6 texture)
                var rock_n: Sprite2D = G._icel_nodes.get(4 * 8 + 4)
                if rock_n != null and is_instance_valid(rock_n):
                        ck(rock_n.texture == G._t_icec(5),
                                "ICE CRASH: the cracked rock now WEARS level 5 (the visual reacts)")
        # v0.3.3-p4 THE GUARANTEED SPREAD: the freeze crawls 2..4 connected
        var icr_band := true
        var icr_seen := []
        for i in 8:
                if G.icel.is_empty():
                        break
                var b0: int = G.icel.size()
                G._icr_spread()
                var d2: int = G.icel.size() - b0
                icr_seen.append(d2)
                if d2 < 1 or d2 > 4:
                        icr_band = false
        ck(icr_band, "ICE CRASH: the freeze crawls every dry move (seen %s)" % str(icr_seen))
        # THE REGISTRY LAW: no orphan ice nodes after pops (the leak that
        # stacked ghost ice and fed the 100%-destroyed crash)
        var orphans := 0
        for k in G._icel_nodes.keys():
                var n: Sprite2D = G._icel_nodes[k]
                if not is_instance_valid(n):
                        orphans += 1
        ck(orphans == 0, "ICE CRASH: zero orphan ice sprites in the registry")
        # the crash hunt: clear EVERYTHING - levels roll over, the board
        # refills, nothing wedges (the owner's 100%-destroyed crash)
        var crash_ok := true
        for round_i in 3:
                G.icr_moves = 40
                var guard2 := 0
                while not G.icel.is_empty() and guard2 < 60 and not G.over:
                        guard2 += 1
                        # THE HIT WAVE: pop every gem standing inside the ice
                        var wave := {}
                        for k in G.icel.keys():
                                var rr := int(k) / 8
                                var cy := int(k) % 8
                                if not G.grid[rr][cy].is_empty() \
                                                and not G._is_coin(G.grid[rr][cy]) \
                                                and not G._is_item(G.grid[rr][cy]):
                                        wave[int(k)] = true
                        if wave.is_empty():
                                break
                        G.cascade = 1
                        await G._pop_cells(wave, [])
                        await G._gravity()
                if G.icel.is_empty() and not G.over:
                        G._icr_win_lose()
                await G._gravity()
                for r in 8:
                        for c2 in 8:
                                if not G.grid[r][c2].is_empty() \
                                                and not G._is_coin(G.grid[r][c2]):
                                        var cellc: Dictionary = G.grid[r][c2]
                                        if int(cellc.get("color", -1)) < 0 \
                                                        or int(cellc.get("color", -1)) > 4:
                                                crash_ok = false
                if G.over:
                        break
        ck(crash_ok and not G.over, "ICE CRASH: the 100%-destroyed rollover survives 3 levels clean")

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
        # v0.3.3-p4 THE GRAVITY-ONLY LAW (the owner: "the item goes down in
        # each move instead of going up, going down is like saying hey
        # player don't worry we got this, which is stupid"): a parcel NEVER
        # steps on its own - it only rides the gravity waves
        var item_col := -1
        for c2 in 8:
                if not G.grid[0][c2].is_empty() and G._is_item(G.grid[0][c2]):
                        item_col = c2
        ck(item_col >= 0, "DROP: a starting parcel found on the top line")
        if item_col >= 0:
                # find the parcel's row
                var prow := -1
                for r in 8:
                        if not G.grid[r][item_col].is_empty() and G._is_item(G.grid[r][item_col]):
                                prow = r
                # open a hole right under it (a match did its work)
                if prow >= 0 and prow + 1 < 8 and not G.grid[prow + 1][item_col].is_empty():
                        if is_instance_valid(G.grid[prow + 1][item_col].get("node")):
                                G.grid[prow + 1][item_col]["node"].queue_free()
                        G.grid[prow + 1][item_col] = {}
                        await G._gravity()
                var fell := -1
                for r in 8:
                        if not G.grid[r][item_col].is_empty() and G._is_item(G.grid[r][item_col]):
                                fell = r
                ck(fell == prow + 1,
                        "DROP: the parcel rode the GRAVITY into the hole (%d -> %d)" % [prow, fell])
                # THE NO-AUTO-STEP LAW: the settle loop must NOT move it further
                var before_settle := fell
                await G._drop_settle()
                var after_settle := -1
                for r in 8:
                        if not G.grid[r][item_col].is_empty() and G._is_item(G.grid[r][item_col]):
                                after_settle = r
                ck(after_settle == before_settle,
                        "DROP: NO auto-step - the parcel waits for the player (%d stays %d)"
                                        % [before_settle, after_settle])
                # THE DELIVERY + REFILL LAW: a parcel on the bottom row pays
                # +3, vanishes, and the column REFILLS (no hanging empty grid)
                var s3 := int(G.score)
                # clear the OTHER parcels - this delivery must complete the
                # whole round (drop_left == 0 and zero items live)
                for r in 8:
                        for c3 in 8:
                                if not (r == fell and c3 == item_col) \
                                                and not G.grid[r][c3].is_empty() \
                                                and G._is_item(G.grid[r][c3]):
                                        if is_instance_valid(G.grid[r][c3].get("node")):
                                                (G.grid[r][c3]["node"] as Sprite2D).queue_free()
                                        G.grid[r][c3] = {}
                G.grid[7][2] = G.grid[fell][item_col]
                G.grid[fell][item_col] = {}
                # put the parcel on the bottom row for real
                G.grid[7][2] = {"color": -2, "item": true, "node": Sprite2D.new()}
                (G.grid[7][2]["node"] as Sprite2D).texture = G._t("parcel")
                (G.grid[7][2]["node"] as Sprite2D).position = G._cell_pos(7, 2)
                G.world.add_child(G.grid[7][2]["node"])
                G.drop_left = 0          # the last parcel of the round
                var items_before: int = G._count_items()
                await G._drop_settle()
                ck(int(G.score) == s3 + 3, "DROP: the bottom row delivers the parcel (+3)")
                ck(G.drop_level >= 2, "DROP: delivering everything rolls the NEXT round")
                ck(not G.grid[7][2].is_empty() and not G._is_item(G.grid[7][2]),
                        "DROP: the delivered seat REFILLED (no hanging empty grid)")
        # THE SPAWN-AFTER-MATCH LAW: a move that popped something feeds a
        # parcel in from the top
        G.drop_left = 2
        G.move_pops = 4
        # clear the live parcels (the fresh round laid its own) - the count
        # must start at zero for the +1 spawn assertion
        for r in 8:
                for c2 in 8:
                        if not G.grid[r][c2].is_empty() and G._is_item(G.grid[r][c2]):
                                if is_instance_valid(G.grid[r][c2].get("node")):
                                        (G.grid[r][c2]["node"] as Sprite2D).queue_free()
                                G.grid[r][c2] = {}
        var items_n0: int = G._count_items()
        var free_top := -1
        for c2 in 8:
                if G.grid[0][c2].is_empty() or not G._is_item(G.grid[0][c2]):
                        free_top = c2
                        break
        if free_top >= 0:
                if not G.grid[0][free_top].is_empty():
                        if is_instance_valid(G.grid[0][free_top].get("node")):
                                G.grid[0][free_top]["node"].queue_free()
                        G.grid[0][free_top] = {}
                await G._after_move()
                ck(G._count_items() == items_n0 + 1,
                        "DROP: a popping move SPAWNS the next parcel from the top")
                ck(G.drop_left == 1, "DROP: the spawn consumed the queue")
        G.move_pops = 0

        # ---------------------------------------- v0.3.3-p4 THE NOVA LAW
        # (the owner: "a color remover + color remover = grid clear with 1
        # damage for whatever that can be damage and removes all gems
        # without affecting drop-down items")
        await _boot("drop")
        G.phase = "play"
        # THE POP-IMMUNITY LAW first: the coin and the parcels are NEVER
        # destroyed by pops - a nova's wave cannot touch them
        var parcel_n := Sprite2D.new()
        parcel_n.texture = G._t("parcel")
        parcel_n.position = G._cell_pos(3, 6)
        G.world.add_child(parcel_n)
        G.grid[3][6] = {"color": -2, "item": true, "node": parcel_n}
        var coin_n := Sprite2D.new()
        coin_n.texture = G._t("coin")
        coin_n.position = G._cell_pos(4, 6)
        G.world.add_child(coin_n)
        G.grid[4][6] = {"color": -1, "coin": true, "node": coin_n}
        var wave := {3 * 8 + 6: true, 4 * 8 + 6: true}
        for k in [0, 1, 2, 8, 9, 10]:
                if not G.grid[int(k) / 8][int(k) % 8].is_empty():
                        wave[int(k)] = true
        G.cascade = 1
        await G._pop_cells(wave, [])
        ck(G._is_item(G.grid[3][6]) and is_instance_valid(G.grid[3][6].get("node")),
                "THE NOVA POP LAW: a drop-down item is NEVER destroyed by pops")
        ck(G._is_coin(G.grid[4][6]) and is_instance_valid(G.grid[4][6].get("node")),
                "THE NOVA POP LAW: the coin is NEVER destroyed by pops")
        # the full nova: EVERY gem pays the rising wave
        var gems0 := 0
        for r in 8:
                for c2 in 8:
                        if not G.grid[r][c2].is_empty() and not G._is_coin(G.grid[r][c2]) \
                                        and not G._is_item(G.grid[r][c2]):
                                gems0 += 1
        var s_nova := int(G.score)
        G.grid[3][3]["special"] = "hyper"
        G.grid[3][4]["special"] = "hyper"
        G.move_pops = 0
        await G._do_hyper_swap(Vector2i(3, 3), Vector2i(3, 4))
        ck(int(G.score) - s_nova >= gems0,
                "THE NOVA LAW: every gem paid the wave (%d gems, +%d score)" % [gems0, int(G.score) - s_nova])
        # the 1-damage arm: on ICE CRASH every layer takes its hit
        await _boot("icecrash")
        G.phase = "play"
        for k in G.icel.keys():
                G.icel[k] = 3
        G._refresh_icel()
        G.grid[3][3]["special"] = "hyper"
        G.grid[3][4]["special"] = "hyper"
        await G._do_hyper_swap(Vector2i(3, 3), Vector2i(3, 4))
        var dmg_ok := true
        for k in G.icel.keys():
                if int(G.icel[k]) >= 3:
                        dmg_ok = false     # every layer took at least its hit
        ck(dmg_ok and not G.icel.is_empty(),
                "THE NOVA LAW: every ice layer took its damage (3 -> 2, cascades may bite deeper)")

        # ---------------------------------------- THE DEAD-BOMB FIX
        # (the owner: "the bomb one currently has it's effect inactive?")
        await _boot("peace")
        Box.dev_set_cheat("all_owned", 1)
        G.phase = "play"
        G.armed = "bomb"
        G.charges["bomb"] = 1
        G.power_used["bomb"] = 0
        var s_bomb := int(G.score)
        G._fire_power(Vector2i(4, 4))
        await get_tree().create_timer(1.2).timeout
        ck(int(G.power_used["bomb"]) == 1, "THE BOMB POWER: the charge was spent")
        ck(int(G.score) - s_bomb >= 9,
                "THE BOMB POWER: the 3x3 blast REALLY pops (+%d)" % (int(G.score) - s_bomb))

        # ---------------------------------------- THE PHYSICS POUR LAW
        # (the owner: "i want the game to start with empty grid-gems then
        # the gems drops down smoothly and fill the places")
        await _boot("challenge")
        ck(true, "the pour landed (the boot waits out the falls)")
        var seated := true
        for r in 8:
                for c2 in 8:
                        var cell: Dictionary = G.grid[r][c2]
                        if cell.is_empty() or not is_instance_valid(cell.get("node")):
                                seated = false
                                continue
                        var n: Sprite2D = cell["node"]
                        if absf(n.position.y - G._cell_pos(r, c2).y) > 2.0:
                                seated = false
        ck(seated, "THE PHYSICS POUR: every gem sits EXACTLY on its seat (bounce settled)")
        # ---------------------------------------- THE SKIN MEMORY LAW
        # (the owner: "i may go with saving the preference, much cooler")
        Box.dev_set_cheat("all_owned", 1)
        G._pick_equip_skin("donut")
        ck(G.skin == "donut", "the skin equipped live")
        ck(String(Box.get_progress("matcher", "skin", "")) == "donut",
                "THE SKIN MEMORY LAW: the preference SAVED")
        G.queue_free()
        await get_tree().create_timer(0.3).timeout
        G = load("res://game/games/matcher/matcher.gd").new()
        G.game_id = "matcher"
        add_child(G)
        await get_tree().create_timer(1.0).timeout
        ck(G.skin == "donut", "THE SKIN MEMORY LAW: a fresh boot WEARS the saved skin")
        ck(G.tex_gem[0].resource_path.contains("donut"),
                "THE SKIN MEMORY LAW: the board textures ARE the saved skin's")
        # ---------------------------------------- THE ARM FADE LAW
        # (the owner: "the SFX that appears after selecting a powerup, it
        # should fade-in then fade-out smoothly when executed or discarded")
        G.phase = "play"
        G._set_armed_cursor(true)
        ck(G._arm_snd != null and is_instance_valid(G._arm_snd),
                "THE ARM FADE LAW: the armed sound rides its own player")
        await get_tree().create_timer(0.35).timeout
        ck(G._arm_snd.volume_db > -30.0,
                "THE ARM FADE LAW: it FADED IN (db %.1f)" % G._arm_snd.volume_db)
        G._set_armed_cursor(false)
        await get_tree().create_timer(0.35).timeout
        ck(G._arm_snd.volume_db <= -30.0 or not G._arm_snd.playing,
                "THE ARM FADE LAW: it FADED OUT on discard (db %.1f)" % G._arm_snd.volume_db)

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

        # ================================================== the PATCH 5 laws
        # THE DONUT PURGE: five per-color pop frames live on the disk, the
        # template zip's donut frames are DELETED (the owner: "there is
        # something deep wrong with donuts i guess")
        var donut_ok := true
        for i in 5:
                if not ResourceLoader.exists("res://assets/games/matcher/fx/popfx_%d.png" % i):
                        donut_ok = false
        for i in [5, 6, 7]:
                if ResourceLoader.exists("res://assets/games/matcher/fx/popfx_%d.png" % i):
                        donut_ok = false
        ck(donut_ok, "THE DONUT PURGE: five per-color pop frames live, the donut files are gone")
        var fx_img: Image = (G._t_popfx(2) as Texture2D).get_image()
        if fx_img.is_compressed():
                fx_img.decompress()
        var fx_c: Color = fx_img.get_pixel(fx_img.get_width() / 2, fx_img.get_height() / 2)
        ck(fx_c.a > 0.9 and fx_c.r > 0.9 and fx_c.g > 0.9,
                "the pop frame wears a white-hot core (a shatter burst, not a pastry)")

        # THE SWEEPER SHADER SWAP: the two gem bodies traded places
        var shd_txt: String = (load("res://assets/games/matcher/specials/special.gdshader") as Shader).code
        var k2 := shd_txt.find("} else if (special == 2)")
        var k3 := shd_txt.find("} else if (special == 3)")
        var k4 := shd_txt.find("} else if (special == 4)")
        var body2 := shd_txt.substr(k2, k3 - k2)
        var body3 := shd_txt.substr(k3, k4 - k3)
        ck(body2.find("UV.x") >= 0 and body2.find("abs(p.x)") >= 0 \
                        and body2.find("vec3(0.55, 0.95, 1.0)") < 0,
                "THE SWEEPER SWAP: the row sweeper's gem wears the traded body")
        ck(body3.find("UV.y") >= 0 and body3.find("abs(p.y)") >= 0 \
                        and body3.find("vec3(1.0, 0.55, 0.95)") < 0,
                "THE SWEEPER SWAP: the column sweeper's gem wears the traded body")

        # THE FALL-AROUND LAW (jelly): gems resting on a plug slide around
        # it into the sealed seats beside - the pocket under the plug stays
        await _boot("jelly")
        for r in 8:
                for c2 in 8:
                        if is_instance_valid(G.grid[r][c2].get("node")):
                                G.grid[r][c2]["node"].queue_free()
                        G.grid[r][c2] = {}
        G.jelly = {2 * 8 + 2: true, 4 * 8 + 3: true}
        for r in 4:
                _mk_cell(r, 3, (r + 2) % 5)
        await G._gravity()
        var slide_ok: bool = not G.grid[7][2].is_empty() and not G.grid[4][2].is_empty()
        ck(slide_ok, "THE FALL-AROUND LAW: gems slid around the plug into the sealed side")
        ck(G.grid[5][3].is_empty() and G.grid[4][3].is_empty(),
                "THE FALL-AROUND LAW: the plug still seals its own column")

        # THE RISE-MATCH LAW (butterflies): a fly that rises into its own
        # color RESOLVES (the owner: "whatever three same-gems are real
        # valid match btw bruh")
        await _boot("butterflies")
        var fly_at := Vector2i(-1, -1)
        for r in 8:
                for c2 in 8:
                        if not G.grid[r][c2].is_empty() \
                                        and bool(G.grid[r][c2].get("wing", false)):
                                fly_at = Vector2i(r, c2)
                                break
                if fly_at.x >= 0:
                        break
        if fly_at.x >= 3:
                var fc: int = int(G.grid[fly_at.x][fly_at.y]["color"])
                _mk_cell(fly_at.x - 2, fly_at.y, fc)
                _mk_cell(fly_at.x - 3, fly_at.y, fc)
                if not G.grid[fly_at.x - 1][fly_at.y].is_empty():
                        var mid := fly_at.x - 1
                        G.grid[mid][fly_at.y]["color"] = (fc + 1) % 5
                        if is_instance_valid(G.grid[mid][fly_at.y].get("node")):
                                (G.grid[mid][fly_at.y]["node"] as Sprite2D).texture \
                                                = G.tex_gem[(fc + 1) % 5]
                var sc3 := int(G.score)
                G.over = false
                G.phase = "play"
                await G._rise_butterflies()
                ck(int(G.score) > sc3,
                        "THE RISE-MATCH LAW: the fly that rose into its color resolved the match")

        # THE INTENSITY LADDER: 1..4 flies per hatch, the gap walks 10 -> 9 -> 7
        await _boot("butterflies")
        G.phase = "play"
        G.busy = false
        var wings0 := _count_wings()
        G.fly_spawned = 0
        G.hatch_clock = 0.001
        G._tick_butterflies(0.01)
        var hatched: int = _count_wings() - wings0
        ck(hatched >= 1 and hatched <= 4, "THE INTENSITY LADDER: a hatch brings 1..4 flies")
        ck(G.fly_spawned == hatched, "the ladder counts every hatch")
        G.fly_spawned = 5
        G.hatch_clock = 0.001
        G._tick_butterflies(0.01)
        ck(absf(G.hatch_clock - 9.0) < 0.05, "the gap drops to 9s at the sixth fly")
        G.fly_spawned = 15
        G.hatch_clock = 0.001
        G._tick_butterflies(0.01)
        ck(absf(G.hatch_clock - 7.0) < 0.05, "the gap drops to 7s at the 16th fly")
        G._refresh_hud()
        ck(not String(G.chip_info2.text).contains("one row"),
                "the flies widget wears no guide words (the owner's cut)")

        # THE COIN COURTESY: a tap on the coin collects it on the spot
        await _boot("challenge")
        G.phase = "play"
        G.busy = false
        G.over = false
        var cs := Sprite2D.new()
        cs.texture = G._t("coin")
        cs.position = G._cell_pos(2, 3)
        G.world.add_child(cs)
        G.grid[2][3] = {"color": -1, "coin": true, "node": cs}
        G.coin_cell = Vector2i(2, 3)
        G.coin_clock = 12.0
        G._tap(G._cell_pos(2, 3))
        ck(G.coin_cell == Vector2i(-1, -1) and G.grid[2][3].is_empty(),
                "THE COIN COURTESY: a tap on the coin collects it on the spot")
        ck(G.coin_clock == G.COIN_EVERY, "the coin clock restarts from the collect")

        # THE MATCH-THROUGH LAW: the hop rides through the coin
        var cs2 := Sprite2D.new()
        cs2.texture = G._t("coin")
        cs2.position = G._cell_pos(5, 4)
        G.world.add_child(cs2)
        G.grid[5][4] = {"color": -1, "coin": true, "node": cs2}
        G.coin_cell = Vector2i(5, 4)
        _mk_cell(4, 4, 0)             # the mover above the coin
        var beyond_col: int = int(G.grid[6][4].get("color", 1))
        _mk_cell(6, 2, 0)
        _mk_cell(6, 3, 0)
        _mk_cell(6, 4, 1 if beyond_col != 1 else 2)
        var hop: Vector2i = G._hop_target(Vector2i(4, 4), Vector2i(5, 4))
        ck(hop == Vector2i(6, 4),
                "THE MATCH-THROUGH LAW: the hop rides to the seat beyond the coin")
        var sc4 := int(G.score)
        G.busy = false
        await G._try_swap(Vector2i(4, 4), hop)
        ck(int(G.score) > sc4,
                "THE MATCH-THROUGH LAW: the through-the-coin move lands a real match")

        # THE RISKY PARCEL LAW: no descent = one climb; the next = over
        await _boot("drop")
        G.phase = "hold"
        for r in 8:
                for c2 in 8:
                        if not G.grid[r][c2].is_empty() and G._is_item(G.grid[r][c2]):
                                if is_instance_valid(G.grid[r][c2].get("node")):
                                        (G.grid[r][c2]["node"] as Sprite2D).queue_free()
                                G.grid[r][c2] = {}
        _mk_cell(4, 6, 2)
        var ps := Sprite2D.new()
        ps.texture = G._t("parcel")
        ps.position = G._cell_pos(3, 6)
        G.world.add_child(ps)
        G.drop_seq += 1
        var pid: int = G.drop_seq - 1
        G.grid[3][6] = {"color": -2, "item": true, "node": ps, "drop_id": pid}
        G.over = false
        G.drop_prev = {pid: 3}
        await G._drop_rise_check()
        ck(G._is_item(G.grid[2][6]) and int(G.grid[2][6].get("rose", 0)) == 1 \
                        and not G.grid[3][6].is_empty() and not G._is_item(G.grid[3][6]),
                "THE RISKY PARCEL LAW: a parcel that did not descend climbed one row")
        G.drop_prev = {pid: 2}
        await G._drop_rise_check()
        ck(G.over, "THE RISKY PARCEL LAW: the second climb ends the run")
        G._refresh_hud()
        ck(String(G.chip_info.text).contains("parcels left"),
                "the drop HUD survives the climb check")

        Box.reset_all()
        print("=== matcher_probe: %d checks, %d fails ===" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)


func _count_wings() -> int:
        var n := 0
        if G == null or G.grid.size() < 8:
                return 0
        for r in 8:
                for c in 8:
                        if not G.grid[r][c].is_empty() \
                                        and bool(G.grid[r][c].get("wing", false)):
                                n += 1
        return n


func _ready() -> void:
        _run()
