extends Node
## POP SIEGE probe (v0.3.5-2) - the deterministic battery.
## Runs headless: godot --headless --path . res://tests/pd_probe.tscn
## Exit 0 = all laws hold.

var checks := 0
var fails := 0
var G: GogaGame = null
var meta: PDMeta = null

func ck(cond: bool, what: String) -> void:
        checks += 1
        if cond:
                print("[PASS] ", what)
        else:
                fails += 1
                print("[FAIL] ", what)

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _boot() -> void:
        if G != null and is_instance_valid(G):
                G.queue_free()
                await _wait(0.3)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1920, 1080)
        await _wait(0.2)
        G = load("res://game/games/pop_siege/pop_siege.gd").new()
        G.game_id = "pop_siege"
        process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(G)
        await _wait(1.0)
        meta = G.meta

func _run() -> void:
        print("=== pd_probe (v0.3.5-2) ===")
        seed(20260907)
        rng_seed()
        await _boot()

        # ------------------------------------------------------- the map laws
        var maps := PDData.maps()
        ck(maps.size() == 30, "THE 30 MAPS LAW: exactly thirty sieges")
        var free_maps := 0
        var seen_ids := {}
        for m in maps:
                ck(not seen_ids.has(m["id"]), "unique map id " + str(m["id"]))
                seen_ids[m["id"]] = true
                ck((m["paths"] as Array).size() >= 1, m["id"] + " has a path")
                ck((m.get("road_cells", []) as Array).size() >= 10, m["id"] + " THE GRID LAW: the roads are CELLS")
                ck(ResourceLoader.exists("res://assets/games/pop_siege/bakes/%s.webp" % m["id"]),
                        m["id"] + " wears its painted board")
                for pts in m["paths"]:
                        var x0 := float(pts[0][0])
                        var y0 := float(pts[0][1])
                        ck(x0 < 0.0 or x0 > 17.0 or y0 < 0.0 or y0 > 9.0, m["id"] + " spawns off the edge")
                        ck(int(pts[-1][0]) == int(m["heart"][0]) and int(pts[-1][1]) == int(m["heart"][1]),
                                m["id"] + " ends at the heart")
                        for ci in range(0, (pts as Array).size(), 4):
                                var c = pts[ci]
                                ck(float(c[1]) >= -2.5 and float(c[1]) < 12.5 and float(c[0]) >= -2.5 and float(c[0]) <= 20.5,
                                        m["id"] + " in bounds")
                        ck((pts as Array).size() >= 14, m["id"] + " THE SMOOTH LAW: a dense march, not cell hops")
                        var breaks := 0
                        for i in range(2, (pts as Array).size()):
                                var d1 := Vector2(float(pts[i - 1][0]) - float(pts[i - 2][0]), float(pts[i - 1][1]) - float(pts[i - 2][1]))
                                var d2 := Vector2(float(pts[i][0]) - float(pts[i - 1][0]), float(pts[i][1]) - float(pts[i - 1][1]))
                                if d1.length() > 0.01 and d2.length() > 0.01:
                                        if absf(d1.angle_to(d2)) > deg_to_rad(55.0):
                                                breaks += 1
                        ck(breaks == 0, m["id"] + " THE NO-HARD-TURN LAW: the road never kinks")
                for pts in m["paths"]:
                        ck(int(pts[-1][0]) == int(m["paths"][0][-1][0]) and int(pts[-1][1]) == int(m["paths"][0][-1][1]),
                                m["id"] + " all roads meet at the heart")
                # the grid truth: road cells + water + props never collide
                var road := {}
                for rc in m["road_cells"]:
                        road[Vector2i(int(rc[0]), int(rc[1]))] = true
                road[Vector2i(m["heart"][0], m["heart"][1])] = true
                for bcell in m["blocked"]:
                        ck(ResourceLoader.exists("res://assets/games/pop_siege/props/%s.png" % bcell[2]),
                                m["id"] + " prop art " + str(bcell[2]) + " shipped")
                        ck(not road.has(Vector2i(bcell[0], bcell[1])), m["id"] + " prop " + str(bcell[2]) + " off the road")
                for wcell in m.get("water", []):
                        ck(not road.has(Vector2i(int(wcell[0]), int(wcell[1]))), m["id"] + " water off the road")
                if int(m["price"]) == 0:
                        free_maps += 1
        ck(free_maps == 3, "THE FREE TRIO LAW (maps): exactly three free maps")
        for mid in PDData.FREE_MAPS:
                ck(seen_ids.has(mid), "free map " + mid + " exists")
        for m in maps:
                ck(ResourceLoader.exists("res://assets/games/pop_siege/thumbs/%s.png" % m["id"]), m["id"] + " day thumb")
                ck(ResourceLoader.exists("res://assets/games/pop_siege/thumbs/%s_n.png" % m["id"]), m["id"] + " night thumb")

        # ------------------------------------------------- the door laws (p4)
        var multi := 0
        for m in maps:
                var mode := String(m.get("wave_mode", "solo"))
                ck(mode in ["solo", "rand"], m["id"] + " wears a legal wave_mode")
                var n_paths: int = (m["paths"] as Array).size()
                if mode != "solo":
                        multi += 1
                        ck(n_paths >= 2, m["id"] + " THE DOORS LAW: multi-mode means multiple doors")
                # THE ONE-GRID LAW: the spawn head sits EXACTLY one cell out
                for pts in m["paths"]:
                        var x0 := float(pts[0][0])
                        var y0 := float(pts[0][1])
                        var overshoot: float = maxf(maxf(-x0, x0 - 18.0), maxf(-y0, y0 - 10.0))
                        ck(overshoot > 0.0 and overshoot <= 1.1,
                                m["id"] + " THE ONE-GRID LAW: the door is one grid away (%.2f)" % overshoot)
                # THE PAINT TRUTH: every on-board walk point rounds INTO a road cell
                var roadset := {}
                for rc in m["road_cells"]:
                        roadset[Vector2i(int(rc[0]), int(rc[1]))] = true
                var off_road := 0
                for pts in m["paths"]:
                        for c in pts:
                                if c[0] >= 0.0 and c[0] < 18.0 and c[1] >= 0.0 and c[1] < 10.0:
                                        if not roadset.has(Vector2i(int(floorf(float(c[0]))), int(floorf(float(c[1]))))):
                                                off_road += 1
                ck(off_road == 0, m["id"] + " THE ROAD TRUTH: the walk never leaves the painted cells")
                # THE FILLET LAW (v0.3.5-4): the march line is GRID-PERFECT -
                # every on-board sample rides within half a cell of a road-cell
                # center (straight runs sit ON the center lines, corner fillets
                # stay inside the corner cell). The old chaikin drift reached
                # ~0.7 - the owner's "the visual pathway is another pathway".
                var worst := 0.0
                for pts in m["paths"]:
                        for c in pts:
                                if c[0] >= 0.0 and c[0] < 18.0 and c[1] >= 0.0 and c[1] < 10.0:
                                        var cc := Vector2(floorf(float(c[0])) + 0.5, floorf(float(c[1])) + 0.5)
                                        worst = maxf(worst, cc.distance_to(Vector2(float(c[0]), float(c[1]))))
                        for i in range(1, (pts as Array).size()):
                                var gap: float = Vector2(float(pts[i][0]), float(pts[i][1])).distance_to(Vector2(float(pts[i - 1][0]), float(pts[i - 1][1])))
                                ck(gap <= 0.55, m["id"] + " THE SAMPLE DENSITY: no gaps the eye can bridge (%.2f)" % gap)
                ck(worst <= 0.51, m["id"] + " THE FILLET LAW: the march rides the centers (worst %.2f)" % worst)
                # v0.3.5-6 THE CENTERLINE TRUTH: path coords are CELL-CENTER
                # coords - every path's walk-in point IS the house's seat
                # (the old runtime's extra +0.5 marched every bloon half a
                # cell off the painted road - the owner's "visualized out of
                # the center, each direction shifts weirder")
                var housec: Vector2 = Vector2(float(m["heart"][0]) + 0.5, float(m["heart"][1]) + 0.5)
                var house_ok := true
                for pts2 in m["paths"]:
                        var lp: Array = (pts2 as Array)[-1]
                        if absf(float(lp[0]) - housec.x) > 0.01 or absf(float(lp[1]) - housec.y) > 0.01:
                                house_ok = false
                ck(house_ok, m["id"] + " THE CENTERLINE TRUTH: every walk-in lands ON the house")
        ck(multi >= 6, "THE DOORS ROSTER: at least six multi-start maps (got %d)" % multi)
        # THE SCORE ICON LAW: the drawing fills its canvas (the clipped look is dead)
        var ic_img: Image = (load("res://assets/games/pop_siege/ui/ic_pops.png") as Texture2D).get_image()
        ic_img.convert(Image.FORMAT_RGBA8)
        var ic_bb := ic_img.get_used_rect()
        ck(ic_bb.size.x >= ic_img.get_width() * 0.72 and ic_bb.size.y >= ic_img.get_height() * 0.72,
                "THE SCORE ICON LAW: the bloon fills the canvas (%dx%d of %dx%d)" % [ic_bb.size.x, ic_bb.size.y, ic_img.get_width(), ic_img.get_height()])

        # ----------------------------------------------------- the bloon laws
        ck(PDData.rbe("red") == 1, "red rbe 1")
        ck(PDData.rbe("blue") == 2, "blue rbe 2")
        ck(PDData.rbe("ceramic") == 104, "ceramic rbe 104 (the honest chain)")
        ck(PDData.rbe("moab") == 616, "moab rbe 616")
        ck(PDData.rbe("brutus") == 1932, "brutus rbe 1932")
        ck(PDData.rbe("gargantua") == 8396, "gargantua rbe (the third tier)")
        ck(PDData.rbe("titan") == 25792, "titan rbe (the fourth tier)")
        ck(PDData.BLOONS.size() == 15, "THE FULL ROSTER: 15 bloon kinds")
        for k in PDData.BLOONS:
                var def: Dictionary = PDData.BLOONS[k]
                if k != "red":
                        ck((def["kids"] as Array).size() > 0, k + " has children")
        # THE WHEEL LAW: every level costs +1 more to crack, the total is the pyramid
        ck(PDData.crack_hp("red", 1) == 1.0, "red 001 cracks for 1")
        ck(PDData.crack_hp("black", 1) == 1.0, "black 001 cracks for 1")
        ck(PDData.crack_hp("black", 2) == 2.0, "black 002 cracks for 2")
        ck(PDData.crack_hp("black", 3) == 3.0, "black 003 cracks for 3")
        ck(absf(PDData.body_hp("black", 3) - 6.0) < 0.01, "black 003 = 1+2+3 overall")
        ck(absf(PDData.crack_hp("ceramic", 2) - 11.0) < 0.01, "ceramic 002 cracks for 11")
        ck(PDData.threat("red", 1, []) == 1, "a red leak costs 1")
        ck(PDData.threat("black", 2, ["blue"]) == 15, "the threat counts levels + strips")
        # THE ARMOR LAW: one class per shell
        ck(PDData.armor_allows(PDData.ARMOR_METAL, PDData.FIRE), "metal fears fire")
        ck(not PDData.armor_allows(PDData.ARMOR_METAL, PDData.SHARP), "metal shrugs sharp")
        ck(not PDData.armor_allows(PDData.ARMOR_METAL, PDData.EXPLOSION), "metal shrugs boom")
        ck(PDData.armor_allows(PDData.ARMOR_ROCK, PDData.EXPLOSION), "rock fears bombs")
        ck(not PDData.armor_allows(PDData.ARMOR_ROCK, PDData.FIRE), "rock shrugs fire")
        ck(PDData.dmg_vs("lead", PDData.SHARP, 5.0) == 0.0, "THE LEAD LAW: sharp is blocked")
        ck(PDData.dmg_vs("lead", PDData.FIRE, 5.0) == 5.0, "fire cracks lead")
        ck(PDData.dmg_vs("black", PDData.EXPLOSION, 5.0) == 0.0, "black shrugs off explosion")
        ck(PDData.dmg_vs("white", PDData.ICE, 5.0) == 0.0, "white shrugs off ice")
        ck(PDData.dmg_vs("brutus", PDData.SHARP, 10.0) == 5.0, "THE BRUTUS LAW: sharp takes half")
        ck(PDData.dmg_vs("titan", PDData.SHARP, 10.0) == 5.0, "titan halves sharp too")

        # ------------------------------------------------------ the folk laws
        ck(PDData.FOLK.size() == 10, "THE TEN: ten folk")
        ck(PDData.FREE_FOLK.size() == 3, "THE FREE TRIO LAW (folk)")
        for fid in PDData.FREE_FOLK:
                ck(int(PDData.FOLK[fid]["goga"]) == 0, "free folk " + fid + " costs nothing")
        for fid in PDData.FOLK:
                var fdef: Dictionary = PDData.FOLK[fid]
                ck((fdef["gears"] as Array).size() == 3, fid + " has 3 gears")
                for gi in 3:
                        var g: Dictionary = fdef["gears"][gi]
                        ck(g.has("dmg") and g.has("rate") and g.has("rng"), fid + " gear %d speaks dmg/rate/rng" % (gi + 1))
                # THE PRICE LAW: the gear-ups are the VERY expensive door
                ck(PDData.up_cost(fid, 5) > PDData.up_cost(fid, 2), fid + " upgrade price scales")
                ck(PDData.gear_cost(fid, 2) > PDData.up_cost(fid, 10) * 3, fid + " the gear jump dwarfs the level ladder")
                ck(PDData.gear_cost(fid, 2) > PDData.gear_cost(fid, 1), fid + " the gear-3 door costs more than gear-2")
                ck(int(PDData.FOLK[fid]["place"]) >= 200, fid + " wears the honest field price")
                # THE RANGE LAW: EVERY gadget range is finite (the endless-range
                # disease is dead - the sniper's reach is long but honest)
                for gi2 in 3:
                        var r: float = PDData.stat(fid, gi2 + 1, 1, "rng")
                        ck(r < 9.0, "%s gear %d range is finite (%.1f cells)" % [fid, gi2 + 1, r])
                ck(PDData.stat(fid, 1, 1, "dmg") == 0.0 or PDData.stat(fid, 1, 10, "dmg") > PDData.stat(fid, 1, 1, "dmg"), fid + " damage grows by level")
                ck(PDData.stat(fid, 1, 1, "rate") == 0.0 or PDData.stat(fid, 1, 10, "rate") < PDData.stat(fid, 1, 1, "rate"), fid + " rate gets faster")
                var first_key: String = PDData.rows_for(fid)[0][1]
                ck(PDData.next_stat(fid, 1, 10, first_key) == 0.0, fid + " THE >> LAW: max level shows no next")
                ck(PDData.next_stat(fid, 1, 5, first_key) > 0.0, fid + " THE >> LAW: mid level has a next")

        # ------------------------------------------- the head truth (p3)
        # THE ART TRUTH v2: MEASURED from the drawn heads (the owner's round:
        # the darty cross aimed 90 degrees off its own darts)
        ck(absf(PDData.head_offset("darty")) < 0.01, "darty's crossbow points RIGHT (offset 0) - the 90-degree lie is dead")
        ck(absf(PDData.head_offset("longeye") - PI) < 0.01, "longeye's tip points LEFT (offset PI)")
        # v0.3.5-6 THE FACE-IT LAW (the owner: "bomber looks with it's butt"):
        # the atlas mortars are muzzle-RIGHT - the g3 cannon's firing opening
        # is plainly on its right end, so the aim offset is 0
        ck(absf(PDData.head_offset("boomba")) < 0.01, "boomba's muzzle points RIGHT at the aim (offset 0 - the butt-first round is dead)")
        ck(PDData.head_static("kaching") and PDData.head_static("marshal"), "the bank and the drum never spin")
        for fid2 in ["darty", "boomba", "pyra", "boomo", "gloop", "kolda", "longeye", "zappy"]:
                ck(PDData.muzzle(fid2) > 0.1, fid2 + " THE MUZZLE LAW: the shot leaves from the business end")

        # -------------------------------------------------- the synergy laws
        ck(PDData.SYNERGIES.size() == 8, "THE EIGHT PACTS")

        # ------------------------------------------------------ the wave laws
        ck(int(PDData.START_COINS) == 650, "THE PURSE LAW: 650 PopCoins at drop in")
        ck(int(PDData.START_LIVES) == 100, "THE LIVES LAW: 100")
        ck(int(PDData.BONUS_DIV) == 1000, "THE /1000 LAW")
        ck(int(PDData.RIDER_EVERY) == 10, "THE RIDER LAW: every 10 waves")
        ck(int(PDData.VICTORY_WAVE) == 40, "THE SIEGE BREAKS at 40")
        ck(PDData.fatigue_for(41) > 1.0 and PDData.fatigue_for(40) == 1.0, "the endless fatigue starts past 40")
        # THE DIFFICULTY BANDS: the wheel turns, the strips wrap, the armor lands
        ck(int(PDData.wave_mods(9)["lv_max"]) == 1, "wave 9 wears no color levels yet")
        ck(int(PDData.wave_mods(12)["lv_max"]) >= 2, "wave 12 turns the wheel")
        ck(int(PDData.wave_mods(30)["lv_max"]) > int(PDData.wave_mods(15)["lv_max"]), "the wheel turns faster deeper")
        ck(int(PDData.wave_mods(12)["strips_max"]) == 0, "wave 12 wears no strips yet")
        ck(int(PDData.wave_mods(16)["strips_max"]) >= 1, "wave 16 wraps the first strips")
        ck(int(PDData.wave_mods(45)["strips_max"]) == 10, "THE STRIP CAP: ten bands on a balloon")
        ck(int(PDData.wave_mods(19)["blimp_strips_max"]) == 0, "wave 19 blimps wear no strips yet")
        ck(int(PDData.wave_mods(40)["blimp_strips_max"]) >= 20, "the blimps wrap dozens of strips")
        ck(int(PDData.wave_mods(50)["blimp_strips_max"]) == 50, "THE BLIMP CAP: fifty strips")
        ck(float(PDData.wave_mods(21)["metal"]) == 0.0, "wave 21 wears no metal yet")
        ck(float(PDData.wave_mods(24)["metal"]) > 0.0, "wave 24 lands metal")
        ck(float(PDData.wave_mods(24)["rock"]) == 0.0, "wave 24 wears no rock yet")
        ck(float(PDData.wave_mods(28)["rock"]) > 0.0, "wave 28 lands rock")
        var g1 := PDData.wave_groups(1, 1)
        var all_red := true
        for grp in g1:
                if grp["kind"] != "red":
                        all_red = false
        ck(all_red, "wave 1 marches reds only")
        var g10 := PDData.wave_groups(10, 1)
        var has_moab := false
        for grp in g10:
                if grp["kind"] == "moab":
                        has_moab = true
        ck(has_moab, "wave 10 brings the first MOAB")
        var g40 := PDData.wave_groups(40, 1)
        var has_titan := false
        for grp in g40:
                if grp["kind"] == "titan":
                        has_titan = true
        ck(has_titan, "wave 40 brings THE TITAN")
        ck(PDData.wave_budget(20, 1) > PDData.wave_budget(19, 1), "the budget climbs")
        ck(PDData.wave_budget(5, 2) > PDData.wave_budget(5, 1), "stars multiply the budget")
        for w in [5, 12, 26, 33, 44]:
                for grp in PDData.wave_groups(w, 2):
                        ck(int(grp["count"]) >= 1 and float(grp["spacing"]) > 0.0,
                                "wave %d group sane (%s)" % [w, grp["kind"]])
                        ck(PDData.unlock_band(grp["kind"]) <= w, "wave %d spawns only unlocked kinds" % w)

        # ------------------------------------------------------- the LIVE sim
        await _boot()
        ck(G.phase == "ready", "THE START LAW: the run opens in the READY gate")
        ck(G.ready_box != null and is_instance_valid(G.ready_box), "the ready card waits over the field")
        ck(G.wave_lbl is Label, "the countdown line is a PLAIN LABEL (never tappable)")
        # THE A/M TRUTH LAW: the button paints the RESTORED mode on boot
        meta.set_auto_waves(false)
        G.queue_free()
        await _wait(0.3)
        G = load("res://game/games/pop_siege/pop_siege.gd").new()
        G.game_id = "pop_siege"
        add_child(G)
        await _wait(0.8)
        ck(not G.auto_waves, "the ledger said MANUAL - the run opens MANUAL")
        var am_btn: Button = G.chips["am_btn"]
        ck(String(am_btn.text) == "MANUAL", "THE A/M TRUTH LAW: the button SHOWS the restored mode (the desync is dead)")
        meta.set_auto_waves(true)
        G.queue_free()
        await _wait(0.3)
        G = load("res://game/games/pop_siege/pop_siege.gd").new()
        G.game_id = "pop_siege"
        add_child(G)
        await _wait(0.8)
        ck(G.auto_waves and String((G.chips["am_btn"] as Button).text) == "AUTO", "AUTO restores + paints AUTO")
        G._start_ready()
        await _wait(0.2)
        ck(G.phase == "idle" and G.ready_box == null, "START opens the siege")
        ck(G.coins == 650 and G.lives == 100, "the purse and the lives drop in honest")
        # THE FIRST WAVE LAW: no timer - even AUTO waits for the SEND tap
        var wn0: int = G.wave_n
        for i in 240:
                G._goga_tick(0.05)
        ck(G.wave_n == wn0 and G.phase == "idle", "THE FIRST WAVE LAW: AUTO never rolls wave 1 by the clock")
        ck(String(G.wave_lbl.text).contains("FIRST"), "the label calls for the first send")
        ck(G.next_btn != null and is_instance_valid(G.next_btn) and G.next_btn.visible, "the SEND WAVE button waits")
        ck(G.speed_mult == 1, "speed starts x1")
        G._toggle_speed()
        ck(G.speed_mult == 2, "THE SPEED LAW: x1 -> x2")
        G._toggle_speed()
        ck(G.speed_mult == 3, "THE SPEED LAW: x2 -> x3")
        G._toggle_speed()
        ck(G.speed_mult == 1, "THE SPEED LAW: x3 -> x1 (three steps, no more)")
        ck(G._hud_row.get_child_count() >= 2, "the HUD wears the flow buttons")
        var has_pause_btn := false
        for c in G._hud_row.get_children():
                if c is Button and String((c as Button).text) == "PAUSE":
                        has_pause_btn = true
        ck(not has_pause_btn, "THE PAUSE BUTTON IS DEAD (back does that job)")

        # the placement law: buildable vs blocked
        var ok_cell := Vector2i(-1, -1)
        var road_cell := Vector2i(-1, -1)
        var block_cell := Vector2i(-1, -1)
        for c in range(18):
                for r in range(10):
                        var v := Vector2i(c, r)
                        if ok_cell.x < 0 and G._buildable(v):
                                ok_cell = v
                        if road_cell.x < 0 and not G._buildable(v):
                                for rc in G.map["road_cells"]:
                                        if Vector2i(int(rc[0]), int(rc[1])) == v:
                                                road_cell = v
                        if block_cell.x < 0 and not G._buildable(v):
                                for bc in G.map["blocked"]:
                                        if Vector2i(int(bc[0]), int(bc[1])) == v:
                                                block_cell = v
        ck(ok_cell.x >= 0 and road_cell.x >= 0 and block_cell.x >= 0, "the map offers grass, road and props")
        ck(G._buildable(ok_cell), "grass builds")
        ck(not G._buildable(road_cell), "THE ROAD LAW: no towers on the road")
        ck(not G._buildable(block_cell), "THE BLOCKED LAW: props refuse towers")

        # THE DRAG LAW: press a card, drag to the grass, release = placed
        var c0 := int(G.coins)
        G._card_press = "darty"
        G._card_press_pos = Vector2(1200, 900)
        G._begin_card_drag()
        ck(G.selected_place == "darty", "the card drag picks the folk up")
        var drop_world: Vector2 = G._cell_pos(ok_cell.x, ok_cell.y)
        var ev := InputEventScreenTouch.new()
        ev.position = drop_world
        ev.pressed = false
        G._card_drag = true
        G._placing_drag = true
        G._goga_input(ev)
        ck(G.folk.size() == 1 and int(G.coins) == c0 - int(PDData.FOLK["darty"]["place"]),
                "THE DRAG LAW: the release places and charges the purse")
        ck(G._card_press == "" and not G._card_drag, "the drag state clears")
        # THE RANGE LAW: the placed darty wears a finite honest ring
        var darty: Dictionary = G.folk[0]
        G._select_folk(darty)
        ck(float(darty["eff_rng"]) <= 4.0 * G.CELL, "THE RANGE LAW: darty's ring is finite")
        G._place_folk("boomo", ok_cell + Vector2i(1, 0))
        G._place_folk("pyra", ok_cell + Vector2i(0, 1))
        G._place_folk("kolda", ok_cell + Vector2i(1, 1))
        G._place_folk("marshal", ok_cell + Vector2i(2, 0))
        ck(G.folk.size() == 5, "five folk on the field")
        # THE PIVOT LAW v2: aiming heads spin IN PLACE on the mount (the
        # orbiting crossbow is dead) - offset ZERO, seated above the base
        var darty_head: Sprite2D = darty["head"]
        ck(darty_head.offset == Vector2.ZERO, "THE PIVOT LAW v2: darty's crossbow rotates around its own center")
        ck(darty_head.position.y < 0.0, "the head seats on the mount above the base")
        var marshal_f: Dictionary = G.folk[4]
        var marshal_head: Sprite2D = marshal_f["head"]
        var rot0: float = marshal_head.rotation
        marshal_f["aim_t"] = 1.0
        marshal_f["aim_at"] = Vector2(0, 0)
        G._tick_folk(0.016)
        ck(absf(marshal_head.rotation - rot0) < 0.001, "the drum NEVER spins (the static head law)")
        for f in G.folk:
                var lim: float = 9.0 * G.CELL
                if String(f["fid"]) == "kaching":
                        lim = 0.5 * G.CELL
                ck(float(f["eff_rng"]) <= lim, String(f["fid"]) + " THE RANGE TRUTH: eff_rng = cells x CELL")
        var boomo: Dictionary = G.folk[1]
        var pyra: Dictionary = G.folk[2]
        ck(float(darty["buffs"]["rate_f"]) >= 1.15, "THE RALLY: darty runs at least 15% faster")
        ck(float(boomo["buffs"]["rate_f"]) >= 1.15 and (boomo["badges"] as Array).size() >= 1, "THE RALLY is mutual (badge on)")
        ck(not bool(pyra["flags"].get("thermal", false)), "thermal shock gated behind Pyra gear 2")
        pyra["gear"] = 2
        G._recompute_auras()
        ck(bool(pyra["flags"].get("thermal", false)), "THERMAL SHOCK opens at gear 2")

        # the upgrade law + THE MAX LAW
        G.coins = 99999
        var lvl0: int = darty["lvl"]
        G.selected_folk = darty
        G._build_menu()
        var inv0: int = int(darty["invested"])
        G._do_upgrade(darty)
        ck(int(darty["lvl"]) == lvl0 + 1, "UPGRADE raises the level")
        ck(int(darty["invested"]) == inv0 + PDData.up_cost("darty", lvl0), "the investment ledger tracks the price")
        var spent := 99999 - int(G.coins)
        ck(spent == PDData.up_cost("darty", lvl0), "THE PRICE LAW: the menu price is the real price")
        darty["lvl"] = 10
        G._build_menu()
        var up_btn: Button = G.menu_box.get_meta("up_btn", null)
        ck(up_btn == null or not is_instance_valid(up_btn), "THE MAX LAW: no UPGRADE button at level 10")
        var gb_btn: Button = G.menu_box.get_meta("gear_btn", null)
        ck(gb_btn != null and is_instance_valid(gb_btn), "the GEAR UP door waits at max level")
        var gear0: int = darty["gear"]
        G._do_gearup(darty)
        ck(int(darty["gear"]) == gear0 + 1 and int(darty["lvl"]) == 1, "GEAR UP jumps the gear and resets the level")
        ck((darty["head"] as Sprite2D).texture.resource_path.contains("_head_g2"), "THE GEAR LAW: the head REPAINTS")
        # THE GRAY LAW: a broke purse grays the doors
        G.coins = 0
        G.selected_folk = darty
        G._build_menu()
        G._paint_menu_afford()
        var up2: Button = G.menu_box.get_meta("up_btn", null)
        ck(up2 != null and up2.modulate.r < 0.9, "THE GRAY LAW: the upgrade door grays when broke")
        darty["lvl"] = 10
        G._build_menu()
        G._paint_menu_afford()
        var gb2: Button = G.menu_box.get_meta("gear_btn", null)
        ck(gb2 != null and gb2.modulate.r < 0.9, "THE GRAY LAW: the gear door grays when broke")
        # THE SELL LAW: 70% of everything invested
        G.coins = 500
        var sell_back := int(float(boomo["invested"]) * PDData.SELL_RATIO)
        G._do_sell(boomo)
        ck(G.folk.size() == 4 and int(G.coins) == 500 + sell_back, "THE SELL LAW pays 70% of the investment")

        # the combat truth: THE POP PAY LAW v2 (a popcoin per damage)
        G.coins = 5000
        var score0: int = G.score
        var coins_c0: int = int(G.coins)
        G._spawn_bloon("red", 0)
        var red: Dictionary = G.bloons[-1]
        ck(G.bloons.size() == 1, "a red spawns")
        # THE SINGLE FILE LAW + THE OFF-STAGE LAW (p3)
        ck(absf(float(red["lane"])) < 0.01, "THE SINGLE FILE LAW: no side lane - one honest row")
        ck(not red["spr"].visible, "THE OFF-STAGE LAW: the spawn waits INVISIBLE behind the map line")
        red["dist"] = 2.5 * G.CELL
        G._move_bloons(0.016)
        ck(red["spr"].visible, "the march carries it INTO the field - it appears")
        G._hurt_bloon(red, 1.0, PDData.SHARP, null)
        ck(G.bloons.is_empty(), "the red pops")
        ck(G.score == score0 + 1, "THE POPS LAW (v0.3.8-3): one pop = one point - the POPS chip counts pops, not money")
        ck(int(G.coins) == coins_c0 + 1, "THE POP PAY LAW v3 (v0.3.8-4): one layer = one popcoin - the overkill pays nothing")
        # THE POP PAY LAW v3 IN THE FLESH (the owner's own examples): a
        # LONGEYE-sized 8-dmg bullet on a 1-layer bloon pays ONE coin, and a
        # 5-layer wheel finished in one big hit pays exactly FIVE
        G.coins = 5000
        var over_coins0: int = int(G.coins)
        G._spawn_bloon("red", 0)
        var red8: Dictionary = G.bloons[-1]
        G._hurt_bloon(red8, 8.0, PDData.SHARP, null)
        ck(int(G.coins) == over_coins0 + 1, "THE 8-DMG TRUTH: Longeye pops a 1-layer red and banks ONE popcoin (was 8)")
        G._spawn_bloon("black", 0, 5)
        var bk5: Dictionary = G.bloons[-1]
        G._hurt_bloon(bk5, 20.0, PDData.SHARP, null)
        ck((not G.bloons.has(bk5)) and int(G.coins) == over_coins0 + 6,
                "THE 5-LAYER TRUTH: one big hit through the whole wheel pays 5 (4 cracks + the body)")
        # THE WHEEL LADDER: a black 003 eats 1+2+3
        G._spawn_bloon("black", 0, 3)
        var bk: Dictionary = G.bloons[-1]
        ck(int(bk["lv"]) == 3 and absf(float(bk["hp"]) - 3.0) < 0.01, "black 003 spawns on the outer ring (3 to crack)")
        G._hurt_bloon(bk, 3.0, PDData.SHARP, null)
        ck(G.bloons.has(bk) and int(bk["lv"]) == 2 and absf(float(bk["hp"]) - 2.0) < 0.01, "the crack rolls to black 002 (2 to crack)")
        G._hurt_bloon(bk, 2.0, PDData.SHARP, null)
        ck(int(bk["lv"]) == 1 and absf(float(bk["hp"]) - 1.0) < 0.01, "then black 001 (1 to crack)")
        var wheel_coins: int = int(G.coins)
        G._hurt_bloon(bk, 1.0, PDData.SHARP, null)
        ck(G.bloons.is_empty() or not G.bloons.has(bk), "black 003 pops after the full pyramid")
        ck(int(G.coins) == wheel_coins + 1, "the last ring pays its popcoin")
        # THE ARMOR LAW in the flesh
        G._spawn_bloon("red", 0, 1, [], PDData.ARMOR_METAL, 3.0)
        var met: Dictionary = G.bloons[-1]
        var met_hp: float = float(met["hp"])
        var met_ok: bool = G._hurt_bloon(met, 5.0, PDData.SHARP, null, true)
        ck((not met_ok) and absf(float(met["hp"]) - met_hp) < 0.01 and float(met["armor_hp"]) > 2.0,
                "sharp CLINKS off the metal (the body never felt it)")
        # THE PAY TRUTH (v0.3.8-3): the shell earns what it ATE - a 10-dmg
        # fire shell meeting 1.5 armor points pays 1.5, never 10
        G._spawn_bloon("red", 0, 1, [], PDData.ARMOR_METAL, 1.5)
        var met2: Dictionary = G.bloons[-1]
        var pay_c0: int = int(G.coins)
        G._hurt_bloon(met2, 10.0, PDData.FIRE, null, true)
        ck(int(G.coins) == pay_c0 + 1,   # 1.5 armor eaten -> 1 whole coin
                "THE PAY TRUTH: the armor pays only the damage it actually ate")
        G._hurt_bloon(met, 3.0, PDData.FIRE, null, true)
        ck(float(met["armor_hp"]) <= 0.01, "fire strips the metal shell")
        var met_body := float(met["hp"])
        G._hurt_bloon(met, 99.0, PDData.SHARP, null, true)
        ck(not G.bloons.has(met), "the bare body pops to sharp once the shell is gone")
        ck(met_body <= 1.01, "the body under the shell was the honest red")
        for bb in G.bloons.duplicate():
                G._bloon_free(bb)
        # the chain: a blue pops into two reds
        G._spawn_bloon("blue", 0)
        var blue: Dictionary = G.bloons[-1]
        G._hurt_bloon(blue, 1.0, PDData.SHARP, null)
        ck(G.bloons.size() == 2 and G.bloons[0]["kind"] == "red", "the blue releases its children")
        # THE STRIPS LAW in the flesh: a striped red hides a blue
        G._spawn_bloon("red", 0, 1, ["blue"])
        var st: Dictionary = G.bloons[-1]
        G._hurt_bloon(st, 1.0, PDData.SHARP, null)
        var kinds_now := {}
        for bb in G.bloons:
                kinds_now[bb["kind"]] = true
        ck(kinds_now.has("blue"), "the strip releases the hidden blue")
        for bb in G.bloons.duplicate():
                G._bloon_free(bb)
        # ceramic: 10 hits (the points law)
        G._spawn_bloon("ceramic", 0)
        var cer: Dictionary = G.bloons[-1]
        var hits := 0
        while not G.bloons.is_empty() and (G.bloons[-1] as Dictionary)["id"] == cer["id"] and hits < 20:
                G._hurt_bloon(cer, 1.0, PDData.SHARP, null)
                hits += 1
        ck(hits == 10, "THE CERAMIC LAW: ten hits to break the body - the pop pays its layer")
        # the leak law (the threat: levels + strips)
        var lives0: int = G.lives
        G.lives = 5000
        G._spawn_bloon("blue", 0)
        var leaker: Dictionary = G.bloons[-1]
        leaker["dist"] = float(G._paths_px[0]["total"]) + 1.0
        G._move_bloons(0.016)
        ck(G.lives == 4998, "the leak takes the threat (blue = 2)")
        G.lives = lives0
        # THE RIDER LAW
        var coins_before_rider: int = G.run_coins
        G._spawn_bloon("red", 0)
        var rider: Dictionary = G.bloons[-1]
        rider["rider"] = true
        G._hurt_bloon(rider, 1.0, PDData.SHARP, null)
        ck(G.run_coins == coins_before_rider + 1, "THE RIDER: the hidden GOGACoin banks")
        # burn + glue states
        G._spawn_bloon("rainbow", 0)
        var rb: Dictionary = G.bloons[-1]
        rb["burn_dps"] = 2.0
        rb["burn_t"] = 3.0
        var rb_hp: float = rb["hp"]
        G._move_bloons(0.5)
        ck(float(rb["hp"]) < rb_hp or G.bloons.has(rb) == false, "the burn ticks")

        # THE MUZZLE LAW in the flesh: darty's dart LEAVES from the bow tip
        G.coins = 5000
        for b2 in G.bloons.duplicate():
                G._bloon_free(b2)
        G._spawn_bloon("red", 0)
        var tgt: Dictionary = G.bloons[-1]
        tgt["dist"] = 0.5
        G._move_bloons(0.016)
        var n_bullets0: int = G.bullets.size()
        darty["cd"] = 0.0
        darty["aim_t"] = 0.0
        G._tick_folk(0.016)
        ck(G.bullets.size() > n_bullets0, "the darty fired")
        var shot: Dictionary = {}
        for b2 in G.bullets:
                if (b2 as Dictionary).get("src", null) == darty:
                        shot = b2
        ck(not shot.is_empty(), "the dart is in the air")
        if not shot.is_empty():
                var muzzle_dist: float = (shot["pos"] as Vector2).distance_to(darty["pos"])
                var want_m: float = PDData.muzzle("darty") * G.CELL
                ck(absf(muzzle_dist - want_m) < G.CELL * 0.2,
                        "THE MUZZLE LAW: the dart spawns at the bow tip (%.0fpx ~= %.0fpx)" % [muzzle_dist, want_m])
        for b2 in G.bullets.duplicate():
                G.bullets.erase(b2)
        # THE BOOM TRUTH: the bomber's explosion draws at blast scale (the
        # old math drew it at one pixel - the owner's "weak VFX")
        var fx0: int = G.fx_layer.get_child_count()
        G._boom_fx(Vector2.ZERO, 1.0)
        var boom_px := 0.0
        for c in G.fx_layer.get_children():
                if c is Sprite2D:
                        boom_px = maxf(boom_px, (c as Sprite2D).scale.x * 128.0)
        ck(boom_px > G.CELL * 1.5, "THE BOOM TRUTH: a 1-cell blast paints a %.0fpx fireball" % boom_px)
        for c in G.fx_layer.get_children().slice(fx0):
                c.queue_free()
        G.fx_layer.queue_redraw()
        # THE SHELL TRUTH (v0.3.5-4): the bomber's bomb DIES at its blast -
        # the old shell kept flying past the target for seconds (the owner's
        # "the ball floats in the sky somehow")
        for b in G.bullets.duplicate():
                G.bullets.erase(b)
        var fake_folk: Dictionary = {"pos": Vector2(200, 200), "fid": "boomba", "gear": 1,
                "lvl": 1, "buffs": {"blast_f": 1.0}, "flags": {}}
        G._shell_spawn(fake_folk, Vector2(320, 240), 3.0, 1.7, {"frags": 0, "stun": 0.0, "moab_bonus": 0.0})
        ck(G.bullets.size() == 1, "the shell flies")
        for i in 30:
                G._tick_bullets(0.05)
        ck(G.bullets.is_empty(), "THE SHELL TRUTH: the bomb is GONE the moment it blasts (nothing floats)")

        # the wave flow (spawner): the SEND call + THE STACK LAW
        for b in G.bloons.duplicate():
                G._bloon_free(b)
        var coins0: int = int(G.coins)
        G._next_wave_pressed()
        ck(G.phase == "spawn" and G.wave_n == 1, "THE SEND LAW: wave 1 opens by the button")
        ck(int(G.coins) == coins0, "the first send pays NO early bonus (there was no timer to beat)")
        var q0: int = G.spawn_q.size()
        G._queue_wave()
        ck(G.wave_n == 2 and G.spawn_q.size() > 0 and G.phase == "spawn", "THE STACK LAW: the next wave joins a running one")
        var entry_w := true
        for s in G.spawn_q:
                if not (s as Dictionary).has("w"):
                        entry_w = false
        ck(entry_w and int(G.spawn_q[0]["w"]) >= 1, "every spawn entry carries its wave's difficulty bands")
        var end_coins: int = int(G.coins)
        G._end_wave()
        ck(int(G.coins) == end_coins, "THE POP PAY LAW: the wave end adds NO flat pay")
        for i in 4000:
                G._goga_tick(0.05)
                if G.phase == "idle":
                        break
        ck(G.phase == "idle", "the stacked waves resolve")
        ck(G.wave_kinds.size() >= 2, "both waves marched")

        # THE RANDOM DOORS LAW in the flesh: every wave rolls its own crew -
        # wave 1 from ONE door, the crew GROWS with the wave, every 5th wave
        # bursts from ALL of them, and the subsets are random
        var rot_map: Dictionary = PDData.map_by_id("mirage_x")
        ck(rot_map["wave_mode"] == "rand" and (rot_map["paths"] as Array).size() == 3,
                "mirage_x wears the 3-door random law")
        G.map = rot_map
        G._build_paths()
        G.wave_n = 0
        G.phase = "idle"
        G.spawn_q.clear()
        G._queue_wave()      # wave 1
        var pis := {}
        for s in G.spawn_q:
                pis[int(s["pi"])] = true
        ck(pis.size() == 1, "THE RANDOM DOORS LAW: wave 1 marches from ONE door")
        ck(int(pis.keys()[0]) in [0, 1, 2], "the door exists")
        # the crew grows: the picker never lies about its size or its members
        var w5: Array = G._pick_doors(5, 3)
        ck(w5.size() == 3, "every 5th wave bursts from ALL the doors")
        var sizes := {}
        for trial in 60:
                G.rng.randomize()
                var crew: Array = G._pick_doors(2, 3)
                ck(crew.size() >= 1 and crew.size() <= 3, "the crew respects the door count")
                var uniq := {}
                for d in crew:
                        uniq[int(d)] = true
                        ck(int(d) in [0, 1, 2], "every door is a real door")
                ck(uniq.size() == crew.size(), "the crew never repeats a door")
                sizes[crew.size()] = true
        ck(sizes.size() >= 2, "THE RANDOM LAW: the wave-2 crew genuinely varies (sizes %s)" % [sizes.keys()])
        var one_only := true
        for trial in 40:
                G.rng.randomize()
                if G._pick_doors(1, 3).size() != 1:
                        one_only = false
        ck(one_only, "the opening wave ALWAYS marches from one door")
        G.spawn_q.clear()               # the doors test queued mirage spawns -
        G.phase = "idle"                # they never outlive their map
        for b in G.bloons.duplicate():
                G._bloon_free(b)
        G.map = PDData.map_by_id(meta.current_map())
        G._build_paths()

        # THE REFRESH LAW: a buy refreshes the SAME window (the stacking
        # shop-windows disease is dead)
        G._shop_open()
        await _wait(0.3)
        ck(G.sheet_open_count() == 1, "the shop opens as one window")
        G._shop_refresh()
        await _wait(0.3)
        ck(G.sheet_open_count() == 1, "THE REFRESH LAW: the refresh never stacks a second window")
        G.sheet_pop()
        await _wait(0.3)
        G._maps_open()
        await _wait(0.3)
        G._maps_refresh()
        await _wait(0.3)
        ck(G.sheet_open_count() == 1, "THE REFRESH LAW: maps rides the same law")
        # THE TOAST LAW: ONE overlay, newest wins, alive above the pause
        var layers_before: int = _count_class(G, "CanvasLayer")
        G.game_toast("FIRST!")
        G.game_toast("SECOND WINS")
        await _wait(0.1)
        ck(_count_class(G, "CanvasLayer") == layers_before, "THE TOAST LAW: toasts never spawn new overlays")
        ck(G._toast["label"].text == "SECOND WINS", "THE NEWEST WINS: the old toast died, the newest speaks")
        ck(G._toast["layer"].process_mode == Node.PROCESS_MODE_ALWAYS, "THE TOAST LAW: the toast lives ABOVE the pause (fades inside the shop)")
        G.sheet_pop()
        await _wait(0.3)
        # THE SCROLL TRUTH (v0.3.5-4): a buy down the list keeps the list AT
        # the buy - the refreshed shop never jumps back to the top
        G._shop_open()
        await _wait(0.4)
        var shop_sc: BoxScroll = G._find_box_scroll((G._sheet_stack.back() as Dictionary)["cc"])
        ck(shop_sc != null, "THE SCROLL TRUTH: the shop scroll is findable")
        if shop_sc != null:
                shop_sc.scroll_vertical = 500
                await _wait(0.1)
                G._shop_refresh()
                await _wait(0.4)
                ck(G.sheet_open_count() == 1, "THE SCROLL TRUTH: the refresh stays one window")
                var sc2: BoxScroll = G._find_box_scroll((G._sheet_stack.back() as Dictionary)["cc"])
                ck(sc2 != null and int(sc2.scroll_vertical) >= 480,
                        "THE SCROLL TRUTH: the shop reopens AT the buy (scroll %s ~= 500)" % (str(int(sc2.scroll_vertical)) if sc2 != null else "?"))
        G.sheet_pop()
        await _wait(0.3)

        # THE MAPS WALL + THE CLOSE LAW + THE SHEET PAUSE LAW
        G._maps_open()
        await _wait(0.4)
        ck(get_tree().paused, "THE SHEET PAUSE LAW: the maps sheet freezes the siege")
        var grid: GridContainer = _find_grid(G)
        ck(grid != null and grid.columns == 2, "THE MAPS LAW: two vertical columns")
        if grid != null:
                ck(grid.get_child_count() == 30, "THE MAPS LAW: thirty map cards")
        ck(_count_class(G, "BoxScroll") >= 1, "THE DIRECT SCROLL LAW: the wall wears a BoxScroll")
        ck(_find_close(G), "THE CLOSE LAW: the maps sheet wears its own X")
        G.sheet_pop()
        await _wait(0.3)
        ck(not get_tree().paused, "the sheet pop resumes the siege")
        G._shop_open()
        await _wait(0.4)
        ck(get_tree().paused, "the shop freezes the siege too")
        ck(_count_labels(G, "THE FOLK") >= 1, "the shop opens with the folk shelf")
        ck(_count_class(G, "BoxScroll") >= 1, "THE SHOP SCROLL LAW: BoxScroll under the rows")
        ck(_find_close(G), "THE CLOSE LAW: the shop sheet wears its own X")
        G.sheet_pop()
        await _wait(0.3)
        ck(not get_tree().paused, "the shop pop resumes")
        # THE DEATH MENU LAW: game over must REACH finish_run (the dead menu)
        var over_fired := {"v": false}
        G.request_finish.connect(func(_s: int, _c: int): over_fired["v"] = true)
        G._maps_open()
        await _wait(0.2)
        G._game_over()
        await _wait(0.2)
        ck(over_fired["v"], "THE DEATH MENU LAW: game over FIRES request_finish (the menu surfaces)")
        ck(not get_tree().paused and G.over, "the death flow closed every sheet and handed the run over")

        print("=== pd_probe: ", checks, " checks, ", fails, " fails ===")
        if fails > 0:
                print("PROBE FAILED")
                get_tree().quit(1)
        else:
                print("ALL LAWS HOLD")
                get_tree().quit(0)

func _find_grid(root: Node) -> GridContainer:
        for c in root.get_children():
                if c is GridContainer and c.columns == 2 and c.get_child_count() >= 25:
                        return c
                var deep := _find_grid(c)
                if deep != null:
                        return deep
        return null

func _find_close(root: Node) -> bool:
        for c in root.get_children():
                if c is Button and String((c as Button).text) == "X":
                        return true
                if _find_close(c):
                        return true
        return false

func _count_class(root: Node, klass: String) -> int:
        var n := 0
        for c in root.get_children():
                if (klass == "BoxScroll" and c is BoxScroll) or c.get_class() == klass:
                        n += 1
                n += _count_class(c, klass)
        return n

func _count_labels(root: Node, frag: String) -> int:
        var n := 0
        for c in root.get_children():
                if c is Label and String(c.text).contains(frag):
                        n += 1
                n += _count_labels(c, frag)
        return n

func rng_seed() -> void:
        seed(20260907)

# the run entry
func _ready() -> void:
        _run()
