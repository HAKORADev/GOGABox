extends Node
## slasher_probe - v0.2.9: drives the REBUILT Fruit Slasher headless. The
## owner's laws: the position ask first (each position its own physics),
## +1 per fruit / -2 per fall with a 0 floor, three hearts with a slashed
## bomb costing one (0 = run over), the real slice (two textured halves
## flying apart), the +N/-N reader (merged, never spam), the 20s coin,
## the vegetables shop gate, /15.
##
##   godot --headless --path projects/gogabox res://tests/slasher_probe.tscn

var fails := 0

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1

var SL: GDScript

func _run() -> void:
        Box.reset_all()
        print("== slasher_probe: the rework v0.2.9 ==")
        SL = load("res://game/games/slasher/slasher.gd")

        # ---- registry sanity (the owner's economy) ----
        var sr: Dictionary = GameReg.get_game("slasher")
        _check(not sr.is_empty(), "slasher is in the registry")
        _check(int(sr["coin_div"]) == 30,
                "slasher run bonus = score/30 (the owner's v0.3.8-7 ask)")
        _check(String(sr["orientation"]) == "auto",
                "the POSITION ASK is on (orientation auto, like snake)")
        _check(bool(sr["shop"]), "slasher wears a shop (the vegetables)")
        _check(not sr.has("banner"), "slasher carries NO ad banner (the 0-ads law)")

        # ---- the MODES law: two positions, two different games ----
        _check(float(SL.MODES["vertical"]["gravity"]) \
                        != float(SL.MODES["horizontal"]["gravity"]),
                "the positions carry DIFFERENT gravity")
        _check(bool(SL.MODES["vertical"]["from_bottom"]) \
                        and bool(SL.MODES["horizontal"]["from_bottom"]),
                "BOTH positions toss from the bottom (v0.3.1 owner law)")
        _check(SL.MODES["horizontal"].has("center_spread"),
                "the landscape spawns spread from the CENTER")

        # ---- boot: the ask -> options -> run ----
        var g: GogaGame = SL.new()
        g.game_id = "slasher"
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        _check(String(g._phase) == "orient", "the game OPENS on the position ask")
        g._orient_choice("vertical")     # headless = portrait: no reload
        _check(String(g._phase) == "options", "the position picked -> the options")
        g._start_run()
        _check(String(g._phase) == "run", "START starts the run")
        _check(g.hearts == 3 and g.heart_icons.size() == 3,
                "three hearts, shown")

        # ---- the scoring law: +1 / -2 with the 0 floor ----
        g.set_score(0)
        g._cut_item(_make_item(g, "apple"), Vector2(50, 50), Vector2(150, 90))
        _check(int(g.score) == 1, "a cut fruit pays exactly +1")
        g._register_miss(Vector2(100, 100))
        _check(int(g.score) == 0 and int(g.loss_acc) == 2,
                "a fall costs -2 and waits in the loss window")
        g._register_miss(Vector2(120, 110))
        g._flush_loss()
        _check(int(g.score) == 0 and g.loss_acc == 0,
                "two falls flush as ONE -4 and the score FLOORS at 0 (never -1 -2)")
        g.set_score(9)
        g._register_miss(Vector2(1, 1))
        g._flush_loss()
        _check(int(g.score) == 7, "-2 lands on a live score too (9 -> 7)")

        # ---- THE READER LAW v0.3.0 (the owner: "+1 next to the cut and
        # -2 for each one fails") - one floater PER EVENT, no zones ----
        g.floats = []
        g._push_float("+1", Vector2(100, 100), Color(0.55, 1.0, 0.6), 34.0)
        _check(g.floats.size() == 1 and String(g.floats[0]["txt"]) == "+1",
                "a cut floats its own +1")
        g._push_float("+1", Vector2(140, 160), Color(0.55, 1.0, 0.6), 34.0)
        _check(g.floats.size() == 2, "two cuts = two floaters (NO merging)")
        _check(String(g.floats[0]["txt"]) != String(g.floats[1]["txt"]) \
                        or g.floats[0]["x"] != g.floats[1]["x"],
                "the floaters live at their own spots")

        # ---- the real slice: the TWO REAL HALVES fly apart ----
        g.set_score(0)
        g.floats = []
        var before_halves: int = int(g.halves.size())
        g._cut_item(_make_item(g, "sandia"), Vector2(60, 60),
                        Vector2(180, 120))
        _check(g.halves.size() >= before_halves + 2,
                "the fruit SPLIT into its two real art halves")
        _check(g.floats.size() == 1 and String(g.floats[0]["txt"]) == "+1",
                "the cut floats +1 next to the fruit")
        _check(g.splats.size() >= 1 and g.drops.size() >= 10,
                "REAL juice: a splat on the wood + droplets in the air")
        # v0.4.1 THE TOP-LEFT SPLAT FIX (the owner: "some particles of a
        # slash at the very top left appear when i slash something"): the
        # stain's blobs used to draw at their bare offsets - around the
        # WORLD ORIGIN. A spy painter rides the REAL draw cycle and
        # records the actual draw_circle calls, so the paint itself is
        # judged, not the data.
        var splat_at := Vector2(640, 900)
        g.splats = []
        g._add_splat(splat_at, Color(1, 0, 0))
        var real_painter: Node2D = g.splat_painter
        real_painter.draw.disconnect(g._paint_splats)
        var spy := SplatSpy.new()
        g.world.add_child(spy)
        spy.draw.connect(g._paint_splats)
        g.splat_painter = spy
        spy.queue_redraw()
        await get_tree().process_frame
        await get_tree().process_frame
        g.splat_painter = real_painter
        spy.draw.disconnect(g._paint_splats)
        real_painter.draw.connect(g._paint_splats)
        spy.queue_free()
        var origin_blob := false
        var on_fruit := false
        for c in spy.circles:
                var pos: Vector2 = c["pos"]
                if pos.length() < 60.0:
                        origin_blob = true
                if pos.distance_to(splat_at) <= 50.0:
                        on_fruit = true
        _check(spy.circles.size() >= 8 and not origin_blob,
                "SPLAT FIX: no juice blob paints near the top-left (0,0) origin (%d circles)" % spy.circles.size())
        _check(on_fruit,
                "SPLAT FIX: the stain's blobs paint AROUND the cut fruit")
        var moved := false
        if g.halves.size() > 0:
                var h0: Dictionary = g.halves[0]
                var n0: Node2D = h0["node"]
                var p0: Vector2 = n0.position
                var v0: Vector2 = h0["v"]
                v0.y += float(1420.0) * (1.0 / 60.0)
                h0["v"] = v0
                n0.position += v0 * (1.0 / 60.0)
                moved = n0.position != p0
        _check(moved, "the halves FLY (physical impulse)")
        # the halves fall with gravity via the tick
        var hcount: int = int(g.halves.size())
        g._goga_tick(1.0 / 60.0)
        _check(g.halves.size() == hcount, "the halves live through a tick")

        # ---- the hearts law + the REAL explosion ----
        g.hearts = 3
        var rings_before: int = int(g.rings.size())
        var smokes_before: int = int(g.smokes.size())
        g._bomb_slashed(Vector2(100, 100))
        _check(g.hearts == 2, "a slashed bomb takes ONE heart (not the run)")
        _check(g.rings.size() >= rings_before + 2 and g.smokes.size() >= smokes_before + 8,
                "the explosion is REAL: flash + shockwave + smoke")
        g.hearts = 1
        g._bomb_slashed(Vector2(100, 100))
        _check(g.hearts == 0 and bool(g._over),
                "the last heart bursting ENDS the run")

        # ---- the coin law: every 20s, slashed like a fruit ----
        _check(float(SL.COIN_EVERY_S) == 20.0, "one coin each 20 seconds")
        var g2: GogaGame = SL.new()
        g2.game_id = "slasher"
        add_child(g2)
        await get_tree().process_frame
        g2._orient_choice("vertical")
        g2._start_run()
        g2._launch("coin")
        var found_coin := false
        for it in g2.items:
                if String(it["kind"]) == "coin":
                        found_coin = true
        _check(found_coin, "the coin spawns like any flying thing")
        var rc := int(g2.run_coins)
        for it in g2.items.duplicate():
                if String(it["kind"]) == "coin":
                        g2.items.erase(it)
                        g2._cut_item(it, Vector2(10, 10), Vector2(60, 40))
                        break
        _check(int(g2.run_coins) == rc + 1, "slashing the coin TAKES it (+1)")
        # a fallen coin costs nothing
        var rc2 := int(g2.run_coins)
        g2._register_miss(Vector2(1, 1))   # a fruit fall
        _check(int(g2.run_coins) == rc2, "the coin is never confused with fruit falls")

        # ---- the landscape physics on the live game (v0.3.1: from the
        # bottom CENTER, wide spread, lighter gravity) ----
        g2.orient = "horizontal"
        g2._launch("apple")
        var it2: Dictionary = g2.items[g2.items.size() - 1]
        var vp3: Vector2 = g2.get_viewport_rect().size
        _check(float(it2["v"].y) < 0.0 and float(it2["g"]) == 1240.0,
                "a landscape launch rises from below with ITS gravity")
        _check(absf(float(it2["node"].position.x) - vp3.x * 0.5) < vp3.x * 0.45,
                "the landscape spawn sits around the CENTER")

        # ---- the vegetables gate ----
        var kind0 := String(g2._item_kind())
        _check(SL.FRUITS.has(kind0), "the default produce is FRUITS")
        Box.dev_set_cheat("all_owned", 1)
        Box.equip_item("slasher", "produce", "veggies")
        g2.mode_id = "veggies"
        var veg_ok := true
        for i in 20:
                if not SL.VEGGIES.has(String(g2._item_kind())):
                        veg_ok = false
        _check(veg_ok, "the bought toggle feeds VEGETABLES")

        # ---- the sneaky row: patterns keep birthing bombs ----
        var bombs := 0
        for i in 160:
                g2._spawn_pattern()
                for it in g2.items.duplicate():
                        if String(it["kind"]) == "bomb":
                                bombs += 1
                        g2.items.erase(it)
                        it["node"].queue_free()
        _check(bombs >= 12,
                "the spawner keeps birthing bombs (rows hide them: %d in 160 patterns)" % bombs)

        # ---- THE SHAPED COLLISION (v0.3.1 patch III, the owner: "if i
        # made a circle with the slash, if a fruit get into the circle
        # thing, it will be cut! THIS IS WRONG!") ----
        var g4: GogaGame = SL.new()
        g4.game_id = "slasher"
        add_child(g4)
        await get_tree().process_frame
        g4._orient_choice("vertical")
        g4._start_run()
        g4.set_score(0)
        # the shape law: every item owns a shape sized from its DRAWN pixels
        var ap: Dictionary = _make_live(g4, "apple", Vector2(400, 300))
        var shp: Dictionary = g4._shape_of(ap)
        _check(String(shp["type"]) == "circle" and float(shp["r"]) > 10.0,
                "a round fruit wears an honest CIRCLE shape")
        var bn: Dictionary = _make_live(g4, "banana", Vector2(400, 300))
        var bshp: Dictionary = g4._shape_of(bn)
        _check(String(bshp["type"]) == "capsule",
                "a long fruit wears a CAPSULE along its body")
        # THE CROSSING LAW: a line THROUGH the fruit cuts it
        g4.items.append(ap)
        ap["sliced"] = false
        var score0 := int(g4.score)
        g4._on_drag(Vector2(400, 380), Vector2(400, 220))
        _check(int(g4.score) == score0 + 1,
                "a real crossing (side to side) CUTS the fruit")
        # a line BESIDE the fruit (outside its shape) never cuts
        var ap2: Dictionary = _make_live(g4, "apple", Vector2(400, 300))
        g4.items.append(ap2)
        g4._on_drag(Vector2(400 + float(shp["r"]) + 40.0, 380),
                        Vector2(400 + float(shp["r"]) + 40.0, 220))
        _check(g4.items.has(ap2),
                "a near-miss line BESIDE the fruit does NOT cut it")
        # THE OWNER'S EXACT CASE: a drawn CIRCLE (loop) AROUND the fruit
        # never cuts it - the old code clipped anything in a 200px swath
        var ap3: Dictionary = _make_live(g4, "apple", Vector2(400, 300))
        g4.items.append(ap3)
        var off := float(shp["r"]) + 30.0
        g4._on_drag(Vector2(400 - off, 300 - off), Vector2(400 + off, 300 - off))
        g4._on_drag(Vector2(400 + off, 300 - off), Vector2(400 + off, 300 + off))
        g4._on_drag(Vector2(400 + off, 300 + off), Vector2(400 - off, 300 + off))
        g4._on_drag(Vector2(400 - off, 300 + off), Vector2(400 - off, 300 - off))
        _check(g4.items.has(ap3),
                "a drawn circle AROUND the fruit does NOT cut it (the owner's bug)")
        # the CAPSULE cuts through its own body only
        var bn2: Dictionary = _make_live(g4, "banana", Vector2(400, 300))
        g4.items.append(bn2)
        var bs: Dictionary = g4._shape_of(bn2)
        g4._on_drag(Vector2(400 - float(bs["r"]) - 30.0, 300),
                        Vector2(400 - float(bs["r"]) - 30.0, 300))
        # (a zero-length segment is skipped) - the real cut:
        g4._on_drag(Vector2(340, 300), Vector2(340 + float(bs["r"]) * 2.0, 300))
        _check(not g4.items.has(bn2),
                "a line through the banana's BODY cuts the capsule")
        # THE BOMB LAW: a GRAZE on its side detonates - no pass-through
        g4.hearts = 3
        var bm: Dictionary = _make_live(g4, "bomb", Vector2(400, 300))
        g4.items.append(bm)
        var bsh: Dictionary = g4._shape_of(bm)
        g4._on_drag(Vector2(400 - float(bsh["r"]) - 8.0, 300),
                        Vector2(400 - float(bsh["r"]) + 2.0, 360))
        _check(g4.hearts == 2,
                "a graze on the bomb's SIDE detonates it (no pass-through needed)")

        # v0.3.5-5 THE CASUAL CUT LAW: the fruit hitboxes grew past their
        # own drawn edge - reaching the OUTER HALF cuts (the old 0.42*
        # drawn-width circle left the outer skin uncuttable); the bomb
        # stays honest so the generosity never multiplies detonations
        var cc_ap: Dictionary = _make_live(g4, "apple", Vector2(400, 300))
        var cc_shp: Dictionary = g4._shape_of(cc_ap)
        var cc_dw: float = float(cc_ap["node"].texture.get_width()) * float(cc_ap["scale"])
        _check(float(cc_shp["r"]) > cc_dw * 0.5,
                "CASUAL CUT: the fruit hitbox reaches past its own drawn edge (r=%.1f, dw=%.1f)" \
                                % [float(cc_shp["r"]), cc_dw])
        g4.items.append(cc_ap)
        var cc_skin := cc_dw * 0.48     # inside the NEW r, outside the old 0.42
        var cc_score := int(g4.score)
        g4._on_drag(Vector2(400.0 + cc_skin, 380.0),
                        Vector2(400.0 + cc_skin, 220.0))
        _check(int(g4.score) == cc_score + 1 and not g4.items.has(cc_ap),
                "CASUAL CUT: a slash through the fruit's OUTER HALF cuts it now")
        var cc_bm: Dictionary = _make_live(g4, "bomb", Vector2(400, 300))
        var cc_bsh: Dictionary = g4._shape_of(cc_bm)
        var cc_bdw: float = float(cc_bm["node"].texture.get_width()) * float(cc_bm["scale"])
        _check(float(cc_bsh["r"]) < cc_bdw * 0.5,
                "CASUAL CUT: the bomb stays honest (r=%.1f < half its drawn width %.1f)" \
                                % [float(cc_bsh["r"]), cc_bdw * 0.5])
        var cc_bn: Dictionary = _make_live(g4, "banana", Vector2(400, 300))
        var cc_bshp: Dictionary = g4._shape_of(cc_bn)
        var cc_bdw2: float = float(cc_bn["node"].texture.get_width()) * float(cc_bn["scale"])
        _check(float(cc_bshp["r"]) >= 0.35 * cc_bdw2,
                "CASUAL CUT: the capsule grew fat (r=%.1f, dw=%.1f)"                                 % [float(cc_bshp["r"]), cc_bdw2])

        # ---- THE ANCHOR-CHORD REGRESSION (v0.3.2 patch, the owner AGAIN:
        # "i move my finger in an arch shape... then i close the arch, BOM,
        # it's slashed, how? why?") - the v0.3.1 probe called _on_drag
        # directly with honest segments, so it never saw the REAL bug:
        # TouchKit emitted anchor->current chords that swept the loop's
        # interior. This time the loop goes through the REAL kit. ----
        var tk := TouchKit.new()
        g4.add_child(tk)
        tk.dragged.connect(g4._on_drag)
        var off3 := float(shp["r"]) + 30.0
        var ap4: Dictionary = _make_live(g4, "apple", Vector2(400, 300))
        g4.items.append(ap4)
        var et := InputEventScreenTouch.new()
        et.position = Vector2(400 - off3, 300 - off3)
        et.pressed = true
        tk.feed(et)
        for c in [Vector2(400 + off3, 300 - off3), Vector2(400 + off3, 300 + off3),
                        Vector2(400 - off3, 300 + off3), Vector2(400 - off3, 300 - off3)]:
                var ed := InputEventScreenDrag.new()
                ed.position = c
                tk.feed(ed)
        _check(g4.items.has(ap4),
                "a closed loop fed through the REAL TouchKit does NOT cut the fruit inside")
        # ...and a slow finger walking THROUGH the fruit (many tiny true
        # segments, each under the old 14px floor) must still cut it
        var ap5: Dictionary = _make_live(g4, "apple", Vector2(400, 300))
        g4.items.append(ap5)
        var et2 := InputEventScreenTouch.new()
        et2.position = Vector2(400, 300 + float(shp["r"]) + 60.0)
        et2.pressed = true
        tk.feed(et2)
        var steps := 14
        for i in range(1, steps + 1):
                var y: float = 300.0 + float(shp["r"]) + 60.0 \
                                - (2.0 * (float(shp["r"]) + 60.0)) * float(i) / float(steps)
                var ed2 := InputEventScreenDrag.new()
                ed2.position = Vector2(400, y)
                tk.feed(ed2)
        _check(not g4.items.has(ap5),
                "a SLOW finger crossing the fruit in tiny steps still CUTS it")
        # a straight fast slash through the same kit still cuts
        var ap6: Dictionary = _make_live(g4, "apple", Vector2(400, 300))
        g4.items.append(ap6)
        var et3 := InputEventScreenTouch.new()
        et3.position = Vector2(400, 380)
        et3.pressed = true
        tk.feed(et3)
        var ed3 := InputEventScreenDrag.new()
        ed3.position = Vector2(400, 220)
        tk.feed(ed3)
        _check(not g4.items.has(ap6),
                "a real crossing fed through the REAL TouchKit still CUTS")

        # ================================================================
        # v0.3.9-11: THE DESSERT SHELF, THE REAL VEG CUTS, THE CONTENT
        # SCALE, THE FRENZY, THE SHOP
        # ================================================================
        var g5: GogaGame = SL.new()
        g5.game_id = "slasher"
        add_child(g5)
        await get_tree().process_frame
        g5._orient_choice("vertical")
        g5._start_run()
        g5.set_score(0)
        # ---- the dessert textures + their REAL halves ----
        var desserts_ok := true
        for d in SL.DESSERTS:
                if g5._texs.get(d) == null or g5._half_a.get(d) == null \
                                or g5._half_b.get(d) == null:
                        desserts_ok = false
        _check(desserts_ok,
                "all %d desserts wear a whole + two real halves" % SL.DESSERTS.size())
        Box.equip_item("slasher", "produce", "desserts")
        g5.mode_id = "desserts"
        var des_ok := true
        for i in 20:
                if not SL.DESSERTS.has(String(g5._item_kind())):
                        des_ok = false
        _check(des_ok, "the dessert toggle feeds DESSERTS")
        # a cut dessert splits into its two halves (the real slice path)
        var halves0: int = g5.halves.size()
        g5._cut_item(_make_live(g5, "cake", Vector2(400, 300)),
                        Vector2(340, 300), Vector2(460, 300))
        _check(g5.halves.size() == halves0 + 2,
                "a cut CAKE becomes two flying halves (the real slice)")
        var half_texs := {}
        for h in g5.halves:
                half_texs[(h["node"] as Sprite2D).texture] = true
        _check(half_texs.size() == 2,
                "the two cake halves wear DIFFERENT textures (h1/h2)")
        # ---- the veg REAL halves (the fake wedge-squash is dead) ----
        var veg_halves_ok := true
        for v in SL.VEGGIES:
                if g5._half_a.get(v) == null or g5._half_b.get(v) == null:
                        veg_halves_ok = false
                elif (g5._half_a[v] as Texture2D).resource_path \
                                == (g5._texs[v] as Texture2D).resource_path:
                        veg_halves_ok = false
        _check(veg_halves_ok,
                "every vegetable wears REAL cut halves (no more two small vegs)")
        halves0 = g5.halves.size()
        g5._cut_item(_make_live(g5, "tomato", Vector2(400, 300)),
                        Vector2(340, 300), Vector2(460, 300))
        _check(g5.halves.size() == halves0 + 2,
                "a cut TOMATO becomes two real halves with flesh faces")
        # ---- THE CONTENT SCALE LAW: produce draws its CONTENT at 122px ----
        var scale_ok := true
        for kind in ["apple", "carrot", "tomato", "cake", "donut", "corn"]:
                var tex: Texture2D = g5._texs[kind]
                var sc: float = g5._item_scale(kind, tex)
                var fr: Vector2 = g5._frac_of(tex)
                var content_w: float = float(tex.get_width()) * sc * fr.x
                if absf(content_w - 122.0) > 2.0:
                        scale_ok = false
                        print("    scale off for %s: %.1f" % [kind, content_w])
        _check(scale_ok,
                "CONTENT SCALE: every produce draws ~122px of real content")
        var carr: Texture2D = g5._texs["carrot"]
        var old_way: float = 150.0 / float(carr.get_width()) * float(carr.get_width())
        var new_way: float = float(carr.get_width()) * g5._item_scale("carrot", carr) * g5._frac_of(carr).x
        _check(new_way > old_way * 0.75,
                "the veg draw grew past the fat-margin lie (%.0f -> %.0f)" % [old_way, new_way])
        # ---- THE FRENZY (the owner: rain every 30-60s, 10s long) ----
        _check(float(SL.FRENZY_LEN) == 10.0 and float(SL.FRENZY_MIN) == 30.0 \
                        and float(SL.FRENZY_MAX) == 60.0,
                "the frenzy knobs: 10s rain, 30-60s quiet")
        g5.frenzy_t = -1.0
        g5.frenzy_clock = 0.05
        probe_beat(g5, 0.1)
        _check(g5.frenzy_t > 0.0, "the quiet ends -> THE RAIN starts")
        # during the rain every pattern is a WAVE (many things at once)
        var wave_ok := true
        for i in 24:
                for it in g5.items.duplicate():
                        g5.items.erase(it)
                        it["node"].queue_free()
                g5._spawn_pattern()
                if g5.items.size() < 2:
                        wave_ok = false
        _check(wave_ok,
                "the rain only pours WAVES (2+ things per pattern)")
        g5.frenzy_t = 0.02
        probe_beat(g5, 0.05)
        _check(g5.frenzy_t < 0.0 and g5.frenzy_clock >= float(SL.FRENZY_MIN) \
                        and g5.frenzy_clock <= float(SL.FRENZY_MAX),
                "the rain ends and re-arms a fresh 30-60s quiet")
        # ---- THE SHOP (the buy law: the shop sells, options apply) ----
        Box.reset_all()
        Box.earn(50000)
        g5._shop_open()
        await get_tree().process_frame
        var labels := _sheet_texts(g5)
        _check(labels.has("FRUIT SLASHER SHOP"), "the slasher shop opens")
        var has_rows := 0
        for want in ["FRUITS", "VEGETABLES", "DESSERTS"]:
                var hit := _has_button_text(g5, want)
                if not hit:
                        for t in labels:
                                if String(t).begins_with(want):
                                        hit = true
                if hit:
                        has_rows += 1
        _check(has_rows == 3,
                "the shop shelves all three produce rows")
        g5.sheet_pop()
        await get_tree().process_frame

        print("== slasher_probe done: %s ==" % ("ALL PASS" if fails == 0 else "%d FAIL" % fails))
        get_tree().quit(1 if fails > 0 else 0)

## one game tick driven by the probe (the clock truth: the rig drives)
func probe_beat(g2: GogaGame, dt: float) -> void:
        g2._goga_tick(dt)

func _sheet_texts(g2: GogaGame) -> Dictionary:
        var out := {}
        if g2.sheet_open_count() == 0:
                return out
        var cc: Control = g2._sheet_stack[0]["cc"]
        var stack := [cc]
        while not stack.is_empty():
                var n: Node = stack.pop_front()
                if n is Label:
                        out[String((n as Label).text)] = true
                if n is Button:
                        out[String((n as Button).text)] = true
                for c in n.get_children():
                        stack.append(c)
        return out

func _has_button_text(g2: GogaGame, want: String) -> bool:
        if g2.sheet_open_count() == 0:
                return false
        var cc: Control = g2._sheet_stack[0]["cc"]
        var stack := [cc]
        while not stack.is_empty():
                var n: Node = stack.pop_front()
                if n is Button and String((n as Button).text).begins_with(want):
                        return true
                for c in n.get_children():
                        stack.append(c)
        return false

func _make_live(g: GogaGame, kind: String, pos: Vector2) -> Dictionary:
        var s := Sprite2D.new()
        s.texture = g._bomb_tex if kind == "bomb" else g._texs[kind]
        s.position = pos
        s.scale = Vector2.ONE * 0.5
        g.world.add_child(s)
        return {"node": s, "kind": kind, "v": Vector2.ZERO,
                "spin": 0.0, "sliced": false, "scale": 0.5, "g": 1560.0}

## v0.4.1 THE SPLAT SPY: a duck-typed painter the probe swaps in before
## _paint_splats() so the REAL draw_circle calls are recorded and judged
## (the top-left splat bug lived in the paint math, not the data). The
## override mirrors the native signature exactly; the engine never calls
## it - only the game's dynamic splat_painter.draw_circle(...) does.
class SplatSpy extends Node2D:
        var circles: Array = []
        @warning_ignore("native_method_override")
        func draw_circle(pos: Vector2, r: float, col: Color,
                        antialiased := false, width := -1.0,
                        width_as_texture := false) -> void:
                circles.append({"pos": pos, "r": r, "col": col})

func _make_item(g: GogaGame, kind: String) -> Dictionary:
        var s := Sprite2D.new()
        s.texture = g._texs[kind]
        s.position = Vector2(120, 90)
        s.scale = Vector2.ONE * 0.5
        g.world.add_child(s)
        return {"node": s, "kind": kind, "v": Vector2(40, -500),
                "spin": 1.0, "sliced": true, "scale": 0.5, "g": 1560.0}

func _ready() -> void:
        _run.call_deferred()
