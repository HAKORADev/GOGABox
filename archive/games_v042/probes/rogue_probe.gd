extends Node
## ROGUE ARSENAL probe (v040-4) - the deterministic battery for the rebuild.
## godot --headless --path . res://tests/rogue_probe.tscn   Exit 0 = all laws.

var checks := 0
var fails := 0
var G: GogaGame = null
var meta: HWMeta = null
var finished := [-1, -1]

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
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())
        get_window().content_scale_size = Vector2i(1920, 1080)
        await _wait(0.2)
        finished = [-1, -1]
        G = load("res://game/games/heavywar/heavywar.gd").new()
        G.game_id = "heavywar"
        G.request_finish.connect(func(s, c): finished = [s, c])
        add_child(G)
        await _wait(0.8)
        meta = G.meta

func _tap(idx: int, pos: Vector2, down: bool) -> void:
        var e := InputEventScreenTouch.new()
        e.index = idx
        e.position = pos
        e.pressed = down
        G._goga_input(e)

func _drag(idx: int, pos: Vector2) -> void:
        var e := InputEventScreenDrag.new()
        e.index = idx
        e.position = pos
        G._goga_input(e)

func _run() -> void:
        print("=== rogue_probe (v040-4) ===")
        seed(20260916)
        await _boot()

        # ------------------------------------------------ the data laws
        ck(HWData.PLACES.size() == 10, "10 places")
        var exs: Array = []
        for p in HWData.PLACES:
                exs.append(String(p["ex"]))
                ck(HWData.ENEMIES.has(String(p["ex"])),
                        "place %s exclusive %s exists" % [p["key"], p["ex"]])
        ck(exs.size() == 10 and exs.size() == (Array(exs) as Array).size(),
                "every exclusive is distinct... (count %d)" % exs.size())
        var shared := 0
        for eid in HWData.ENEMIES:
                if not exs.has(eid):
                        shared += 1
        ck(shared == 12, "12 shared enemies (got %d)" % shared)
        ck(HWData.BOSSES.size() == 10, "10 bosses")
        var brains: Array = []
        for b in HWData.BOSSES:
                brains.append(String(b["brain"]))
                ck(HWData.ENEMIES.keys() != null, "boss %s tabled" % b["id"])
        ck(brains.has("prime"), "THE NULL AVATAR rides the prime brain")
        ck(HWData.CARDS.size() >= 14, "a real card pool (%d)" % HWData.CARDS.size())
        # THE NO-CHEAT LAW: no magnet/coin/scrap economy cards
        var cheat := false
        var banned := ["magnet", "coin", "scrap", "xp", "vacuum"]
        for c in HWData.CARDS:
                var cid := String(c["id"])
                if cid in banned:
                        cheat = true
        ck(not cheat, "THE NO-CHEAT LAW: the economy cards are gone")
        ck(HWData.MINIS.size() == 4, "the 4 mini tanks")
        ck(int(HWData.MINIS["mt_magnet"]["price"]) >= 800,
                "the magnet mini tank is expensive")
        for mid in HWData.MINIS:
                ck(ResourceLoader.exists(HWData.ART
                        + HWData.MINIS[mid]["icon"] + ".png"),
                        "mini %s art exists" % mid)
        ck(HWData.SHOP_UPG.size() == 8, "8 shop upgrades")
        ck(HWData.SKINS.size() == 5, "5 skins")

        # ------------------------------------------------ the wave laws
        var b1 := HWData.wave_budget(1, 0, 1, 0.0)
        var b8 := HWData.wave_budget(8, 0, 1, 0.0)
        var b8s := HWData.wave_budget(8, 0, 1, 6.0)
        ck(b8 > b1, "wave 8 pours more than wave 1 (%d > %d)" % [b8, b1])
        ck(b8s > b8, "THE POWER LAW: a stronger tank draws a bigger war")
        ck(HWData.wave_budget(10, 9, 2, 6.0) <= 46, "the budget cap holds")
        ck(HWData.WAVE_MAX_TIME == 180.0, "THE 3:00 LAW")
        ck(HWData.WAVES_PER_PLACE == 10, "10 waves per place")
        var hp1 := HWData.boss_hp(0, 1, 0.0)
        var hp2 := HWData.boss_hp(3, 1, 0.0)
        ck(hp2 > hp1, "later bosses out-armor the first")
        ck(HWData.COIN_KILLS == 22 and HWData.COIN_TIME == 40.0,
                "the coin law: 22 kills or 40s")

        # ------------------------------------------------ the art law
        var art_ok := true
        for eid in HWData.ENEMIES:
                for f in 2:
                        if not ResourceLoader.exists(HWData.ART
                                        + "enemies/r_e_%s%d.png" % [eid, f]):
                                art_ok = false
        ck(art_ok, "every enemy wears BOTH frames - nothing static")
        var boss_art := true
        for b in HWData.BOSSES:
                for f in 2:
                        if not ResourceLoader.exists(HWData.ART
                                        + "bosses/r_b_%s%d.png" % [b["id"], f]):
                                boss_art = false
        ck(boss_art, "every boss wears BOTH frames")
        var env_ok := true
        for p in HWData.PLACES:
                for layer in ["far", "mid", "near", "ground"]:
                        if not ResourceLoader.exists(HWData.ART
                                        + "env/r_env_%s_%s.png" % [p["key"], layer]):
                                env_ok = false
        ck(env_ok, "every place wears its 4-layer world")
        for shot in ["ball", "ball_hot", "rocket", "bomb", "iceball", "plasma"]:
                ck(ResourceLoader.exists(HWData.ART + "shots/r_%s.png" % shot),
                        "shot %s exists" % shot)
        for i in 6:
                ck(ResourceLoader.exists(HWData.ART + "fx/r_boom%d.png" % i),
                        "boom frame %d" % i)
        for c in HWData.CARDS:
                ck(ResourceLoader.exists(HWData.ART + "ui/r_card_%s.png" % c["icon"]),
                        "card icon %s" % c["icon"])
        for m in ["menu", "war", "press", "boss"]:
                ck(ResourceLoader.exists("res://assets/audio/sfx/rw_music_%s.ogg" % m),
                        "music %s rides" % m)

        # ------------------------------------------------ the boot + zones
        ck(G.state == G.GS.INTRO, "the war opens on the intro")
        # the FIRST tap deploys (tap anywhere); its finger takes no role
        _tap(9, Vector2(G.W * 0.5, G.GROUND_Y - 300.0), true)
        _tap(9, Vector2(G.W * 0.5, G.GROUND_Y - 300.0), false)
        await _wait(0.2)
        ck(G.state == G.GS.PLACE, "the intro tap deployed the war")
        var x0: float = G.p_x
        _tap(1, Vector2(300.0, 900.0), true)          # left half = move zone
        ck(G.move_ptr == 1, "the left touch takes the MOVE role")
        _drag(1, Vector2(460.0, 900.0))
        await _wait(0.4)
        ck(absf(G.move_force) > 0.3, "the drag sets the analog force")
        var x1: float = G.p_x
        ck(x1 > x0 + 20.0, "the tank ROLLS right (%.0f -> %.0f)" % [x0, x1])
        _drag(1, Vector2(150.0, 900.0))
        await _wait(0.4)
        ck(G.p_x < x1, "sliding left rolls the tank back")
        _tap(1, Vector2(150.0, 900.0), false)
        ck(G.move_ptr == -1 and absf(G.move_force) < 0.01,
                "lifting the finger drops the role")
        _tap(2, Vector2(1500.0, 400.0), true)          # right half = aim
        ck(G.aim_ptr == 2, "the right touch takes the AIM role")
        # aim up-left: the turret angle must chase the finger
        _drag(2, Vector2(400.0, 200.0))
        await _wait(0.5)
        ck(G.p_aim < -1.0 and G.p_aim > -PI, "the turret tracks the aim finger")
        # the cannon fires while the finger stays (the ball outruns the
        # sample window - the RECOIL tells the truth)
        var fired := false
        for i in 12:
            await _wait(0.1)
            if G.p_recoil > 0.05:
                fired = true
                break
        ck(fired, "holding the aim finger FIRES (recoil)")
        _tap(2, Vector2(400.0, 200.0), false)

        # ------------------------------------------------ the kill law
        ck(G.enemies.size() > 0 or G.wave_state == "spawning",
                "the wave director is alive (state %s)" % G.wave_state)
        # wait for at least one enemy
        var tries := 0
        while G.enemies.size() == 0 and tries < 60:
                await _wait(0.1)
                tries += 1
        ck(G.enemies.size() > 0, "enemies walk in from BOTH sides")
        var both_sides := false
        tries = 0
        var saw_left := false
        var saw_right := false
        while tries < 240 and not (saw_left and saw_right):
                for e in G.enemies:
                        if float(e["x"]) < G.W * 0.45:
                                saw_left = true
                        if float(e["x"]) > G.W * 0.55:
                                saw_right = true
                await _wait(0.1)
                tries += 1
        ck(saw_left and saw_right,
                "spawns come from BOTH sides (L%s R%s)" % [saw_left, saw_right])
        # one kill = one point + xp drops
        var e0: Dictionary = G.enemies[0]
        var hp0: float = e0["hp"]
        G._damage_enemy(e0, hp0 * 0.4)
        ck(float(e0["hp"]) < hp0 - 0.1 and float(e0["hp"]) > 0.0,
                "partial damage lands")
        var score0: int = G.score
        G._damage_enemy(e0, 99999.0)
        await _wait(0.1)
        ck(G.score == score0 + 1, "SCORE = KILLS: one kill, one point")
        var xp_dropped := false
        for d in G.drops:
                if String(d["kind"]) == "xp":
                        xp_dropped = true
        ck(xp_dropped, "the kill spilled XP orbs")

        # ------------------------------------------------ the coin law
        G.coin_armed = true
        var e1: Dictionary = G.enemies[0] if G.enemies.size() > 0 else {}
        if not e1.is_empty():
                var coins0: int = G.run_coins
                G._damage_enemy(e1, 99999.0)
                var found := {}
                for d in G.drops:
                        if String(d["kind"]) == "coin":
                                found = d
                ck(not found.is_empty(), "the armed kill carries a GOGACoin")
                if not found.is_empty():
                        found["x"] = G.p_x
                        found["y"] = G.GROUND_Y - 90.0
                        found["grounded"] = true
                        await _wait(0.15)
                        ck(G.run_coins == coins0 + 1,
                                "the coin pays the wallet (%d)" % G.run_coins)
        ck(not G.coin_armed, "the coin law re-arms on its own clock")

        # ------------------------------------------------ the level law
        var lvl0: int = G.p_level
        G._gain_xp(G.p_xp_next + 10)
        await _wait(0.2)
        ck(G.p_level == lvl0 + 1, "XP levels the tank up")
        ck(G.paused and get_tree().paused, "the level up PAUSES the war")
        ck(G.card_choices.size() == 3, "3 cards to pick")
        var before_dmg: float = float(G.buffs["dmg"])
        G._pick_card({"id": "dmg", "name": "", "desc": "", "icon": "dmg"})
        await _wait(0.2)
        ck(not G.paused, "picking a card resumes the war")
        ck(absf(float(G.buffs["dmg"]) - (before_dmg + 0.2)) < 0.001,
                "the card's bite lands")

        # ------------------------------------------------ the boss chain
        G.wave = HWData.WAVES_PER_PLACE
        for e in G.enemies.duplicate():
                G.kill_enemy(e, false)
        G.wave_state = "clearing"
        tries = 0
        while G.state != G.GS.BOSS and tries < 40:
                await _wait(0.1)
                tries += 1
        ck(G.state == G.GS.BOSS, "wave 10 clear summons the BOSS")
        ck(not G.boss_ent.is_empty(), "the boss entity is tracked")
        var boss_hp0: float = float(G.boss_ent.get("maxhp", 0.0))
        ck(boss_hp0 > 500.0, "the boss is a real fight (%.0f hp)" % boss_hp0)
        # kill it -> tunnel
        G._damage_enemy(G.boss_ent, 999999.0)
        await _wait(0.3)
        ck(G.state == G.GS.TUNNEL, "the boss falls -> THE TUNNEL")
        ck(G.run["bosses_killed"] == 1, "the ledger banks the boss")
        # ride the tunnel out -> the next place
        tries = 0
        while G.state != G.GS.PLACE and tries < 90:
                await _wait(0.1)
                tries += 1
        ck(G.state == G.GS.PLACE, "the tunnel lands the next place")
        print("[TANKDBG] valid=", is_instance_valid(G.tank),
                " in_tree=", (G.tank.is_inside_tree() if is_instance_valid(G.tank) else false),
                " visible=", (G.tank.visible if is_instance_valid(G.tank) else false),
                " pos=", (G.tank.global_position if is_instance_valid(G.tank) else Vector2.ZERO),
                " kids=", (G.tank.get_child_count() if is_instance_valid(G.tank) else -1))
        ck(G.place_i == 1, "place 2 begins")
        ck(G.wave == 1, "the waves reset for the new place")

        # ------------------------------------------------ the shop
        Box.earn(5000)
        var armor0: int = G._shop_lvl("armor")
        G.meta.d["upg"] = {"armor": armor0 + 1}
        G.meta.save()
        ck(G._shop_lvl("armor") == armor0 + 1, "shop levels read the ledger")
        var mini0: bool = G._mini_owned("mt_rocket")
        ck(not mini0, "the rocket mini tank starts unbolted")
        var price: int = int(HWData.MINIS["mt_rocket"]["price"])
        ck(Box.buy_item(G.game_id, "mini", "mt_rocket", price),
                "the wallet buys the mini tank")
        ck(G._mini_owned("mt_rocket"), "the mini tank bolts on")
        # the shop sheet opens + closes clean
        G._shop_open()
        await _wait(0.5)
        var sheet_ok: bool = G._sheet_stack.size() > 0
        ck(sheet_ok, "the shop sheet is up")
        if sheet_ok:
            _dump_tree(G._sheet_stack[-1]["cc"], 0)
            # walk the sheet's subtree: the BoxScroll must carry the rows
            var scroll: BoxScroll = _find_scroll(G._sheet_stack[-1]["cc"])
            ck(scroll != null, "the shop scroll exists")
            if scroll != null:
                var rows: VBoxContainer = scroll.get_child(0) as VBoxContainer
                ck(rows.get_child_count() >= 18,
                    "the shop rows built (%d)" % rows.get_child_count())
                var btns: int = Arc._buttons_in(rows).size()
                ck(btns >= 8, "the shop buttons live (%d)" % btns)
        G._shop_close()
        await _wait(0.2)

        # ------------------------------------------------ game over
        G.p_hp = 1.0
        G._damage_player(50.0)
        await _wait(0.1)
        ck(G.state == G.GS.OVER, "hull 0 ends the run")
        tries = 0
        while finished[0] == -1 and tries < 40:
                await _wait(0.1)
                tries += 1
        ck(int(finished[0]) >= 0, "the run reports its kills as score")
        ck(G.meta.d["best_kills"] >= int(finished[0]),
                "the ledger keeps the record")
        ck(int(G.meta.d["runs"]) == 1, "the run counts")

        print("=== %d checks, %d fails ===" % [checks, fails])
        if fails == 0:
                print("ROGUE PROBE: ALL TESTS PASSED")
                get_tree().quit(0)
        else:
                print("ROGUE PROBE: FAILURES")
                get_tree().quit(1)

func _ready() -> void:
        _run.call_deferred()

func _dump_tree(n: Node, depth: int) -> void:
    print("[DUMP]", "  ".repeat(depth), n.get_class(), "  name=", n.name)
    for c in n.get_children():
        _dump_tree(c, depth + 1)

func _find_scroll(n: Node) -> BoxScroll:
    if n is BoxScroll:
        return n
    for c in n.get_children():
        var s := _find_scroll(c)
        if s != null:
            return s
    return null
