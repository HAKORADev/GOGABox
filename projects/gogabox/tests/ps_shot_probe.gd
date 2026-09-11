extends Node
## ps_shot_probe - THE SHOT LAW probe (v0.3.8-5 round 2, the owner's math):
## "a shot worth 10 damage points and a bloon worth 3 damage points: the shot
## pops the whole 3 and gives the popcoins at once as +nn. A bloon stronger
## than the weapon: each shot pops layers worth the damage dealt."
## Runs headless: godot --headless --path . res://tests/ps_shot_probe.tscn
## Exit 0 = the law holds.

var checks := 0
var fails := 0
var G: GogaGame = null

func ck(cond: bool, what: String) -> void:
        checks += 1
        if cond:
                print("[PASS] ", what)
        else:
                fails += 1
                print("[FAIL] ", what)

func _fake_src() -> Dictionary:
        return {"fid": "probe", "buffs": {}, "inflicted": 0.0}

## the honest chain: how many layers a full family tree hides (the pop total
## when one shot pours through all of it) - moab: 1 + 4 + 8 + 16 + ...
func _chain_layers(kind: String, depth := 0) -> int:
        if depth > 12:
                return 0
        var total := 1
        for k in PDData.BLOONS[kind]["kids"]:
                total += _chain_layers(String(k), depth + 1)
        return total

## the honest chain HP: the damage the WHOLE tree absorbs before it is gone
func _chain_hp(kind: String, depth := 0) -> int:
        if depth > 12:
                return 0
        var total := int(PDData.body_hp(kind, 1))
        for k in PDData.BLOONS[kind]["kids"]:
                total += _chain_hp(String(k), depth + 1)
        return total

func _mk_bloon(kind: String, lv: int) -> Dictionary:
        G.bloons.clear()
        G._spawn_bloon(kind, 0, lv)
        var b: Dictionary = G.bloons[G.bloons.size() - 1]
        b["lv"] = lv
        b["max_hp"] = PDData.body_hp(kind, lv)
        b["hp"] = b["max_hp"]
        return b

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        get_window().size = Vector2i(1280, 720)
        G = load("res://game/games/pop_siege/pop_siege.gd").new()
        G.game_id = "pop_siege"
        add_child(G)
        await get_tree().create_timer(0.8).timeout
        G._start_ready()
        await get_tree().create_timer(0.2).timeout

        # ------------------------------------------------ the owner's example x3
        # 8 dmg vs a 2-ring red: ONE shot, the whole wheel gone, +2 at once.
        var b := _mk_bloon("red", 2)
        var c0: int = G.coins
        var src := _fake_src()
        var alive: bool = G._hurt_bloon(b, 8.0, PDData.SHARP, src)
        ck(not alive == false or true, "call returns") # _hurt_bloon true = the hit landed
        ck(int(b.get("hp", 0.0)) <= 0 or not G.bloons.has(b), "8dmg vs 2 rings: bloon DEAD in one shot")
        ck(G.coins - c0 == 2, "8dmg vs 2 rings: exactly +2 popcoins at once (got %d)" % (G.coins - c0))
        ck(G.bloons.is_empty(), "no children left behind (a red has none)")

        # 10 dmg vs a 3-ring red: ONE shot, +3 at once.
        b = _mk_bloon("red", 3)
        c0 = G.coins
        src = _fake_src()
        G._hurt_bloon(b, 10.0, PDData.SHARP, src)
        ck(G.coins - c0 == 3, "10dmg vs 3 rings: exactly +3 at once (got %d)" % (G.coins - c0))
        ck(G.bloons.is_empty(), "3-ring wheel gone in one shot")

        # stronger bloon: 3 dmg vs a 5-ring red: survives, -3 rings, +3 NOW.
        b = _mk_bloon("red", 5)
        c0 = G.coins
        src = _fake_src()
        G._hurt_bloon(b, 3.0, PDData.SHARP, src)
        ck(G.bloons.has(b), "3dmg vs 5 rings: bloon still standing")
        ck(int(b["lv"]) == 2, "3dmg vs 5 rings: wheel at 2 rings left (got %d)" % int(b["lv"]))
        ck(G.coins - c0 == 3, "3dmg vs 5 rings: +3 paid the moment it landed (got %d)" % (G.coins - c0))
        # finishing blow: 3 dmg vs 2 rings: dies, +2.
        c0 = G.coins
        src = _fake_src()
        G._hurt_bloon(b, 3.0, PDData.SHARP, src)
        ck(not G.bloons.has(b), "finisher: dead in the next shot")
        ck(G.coins - c0 == 2, "finisher: +2 at once (got %d)" % (G.coins - c0))

        # 1 dmg per shot on a 2-ring red: pays 1 then 1 (per-shot law).
        b = _mk_bloon("red", 2)
        c0 = G.coins
        src = _fake_src()
        G._hurt_bloon(b, 1.0, PDData.SHARP, src)
        ck(int(b["lv"]) == 1, "1dmg vs 2 rings: down to 1 ring")
        ck(G.coins - c0 == 1, "1dmg vs 2 rings: +1 this shot (got %d)" % (G.coins - c0))
        c0 = G.coins
        src = _fake_src()
        G._hurt_bloon(b, 1.0, PDData.SHARP, src)
        ck(not G.bloons.has(b), "1dmg finisher: dead")
        ck(G.coins - c0 == 1, "1dmg finisher: +1 (got %d)" % (G.coins - c0))

        # overkill never invents coins: 50 dmg vs 1 ring pays exactly +1.
        b = _mk_bloon("red", 1)
        c0 = G.coins
        src = _fake_src()
        G._hurt_bloon(b, 50.0, PDData.SHARP, src)
        ck(G.coins - c0 == 1, "50dmg vs 1 ring: +1 only, overkill pays nothing (got %d)" % (G.coins - c0))
        ck(int(src["inflicted"]) == 1, "50dmg vs 1 ring: inflicted = 1 DEALT, not 50 raw (got %d)" % int(src["inflicted"]))

        # -------------------------------------------------- v0.3.8-6 THE FLOW LAW
        # THE CHAIN WIPE: 8 dmg vs a blue (1 layer + 2 reds inside) erases the
        # WHOLE chain in ONE shot - the leftover pours through the pop.
        b = _mk_bloon("blue", 1)
        c0 = G.coins
        src = _fake_src()
        G._hurt_bloon(b, 8.0, PDData.SHARP, src)
        ck(G.bloons.is_empty(), "FLOW: 8dmg vs blue = blue + its 2 reds ALL gone in one shot")
        ck(G.coins - c0 == 3, "FLOW: chain wipe pays +3 at once (blue+red+red, got %d)" % (G.coins - c0))
        ck(int(src["inflicted"]) == 3, "FLOW: inflicted = 3 absorbed (was 8 raw x collided), got %d" % int(src["inflicted"]))

        # PARTIAL FLOW: 2 dmg vs a blue eats the blue and ONE red - the second
        # red stands with its honest hp, +2 for the two layers that emptied.
        b = _mk_bloon("blue", 1)
        c0 = G.coins
        src = _fake_src()
        G._hurt_bloon(b, 2.0, PDData.SHARP, src)
        ck(G.bloons.size() == 1, "FLOW: 2dmg vs blue leaves exactly the last red standing (got %d bloons)" % G.bloons.size())
        ck(G.coins - c0 == 2, "FLOW: 2 layers emptied = +2 at once (got %d)" % (G.coins - c0))
        if G.bloons.size() == 1:
                var last_red: Dictionary = G.bloons[0]
                ck(float(last_red["hp"]) == 1.0, "FLOW: the standing red keeps its FULL fresh hp (got %s)" % str(last_red["hp"]))
        ck(int(src["inflicted"]) == 2, "FLOW: inflicted = 2 absorbed (got %s)" % str(src["inflicted"]))

        # FRACTIONAL FLOW: 1.5 dmg vs a blue - the blue dies, the first red is
        # BITTEN to half, the second red untouched. Water flows, nothing invented.
        b = _mk_bloon("blue", 1)
        c0 = G.coins
        src = _fake_src()
        G._hurt_bloon(b, 1.5, PDData.SHARP, src)
        ck(G.coins - c0 == 1, "FLOW: 1.5dmg vs blue = only the blue layer emptied, +1 (got %d)" % (G.coins - c0))
        ck(G.bloons.size() == 2, "FLOW: both reds still marching (got %d)" % G.bloons.size())
        if G.bloons.size() == 2:
                var r1: Dictionary = G.bloons[0]
                var r2: Dictionary = G.bloons[1]
                ck(abs(float(r1["hp"]) - 0.5) < 0.001, "FLOW: first red bitten to 0.5 hp (got %s)" % str(r1["hp"]))
                ck(float(r2["hp"]) == 1.0, "FLOW: second red untouched (got %s)" % str(r2["hp"]))
        ck(abs(float(src["inflicted"]) - 1.5) < 0.001, "FLOW: inflicted = 1.5 exactly dealt (got %s)" % str(src["inflicted"]))

        # THE DEEP CHAIN: one 5000-dmg shot vs a moab erases the ENTIRE family
        # tree in ONE shot - the water pours through every generation. THE LAW:
        # every layer the shot emptied pays at once, overkill past the last
        # layer pays zero, inflicted counts what the chain actually ATE.
        b = _mk_bloon("moab", 1)
        c0 = G.coins
        src = _fake_src()
        # the honest expectation: the whole moab family tree = count the chain
        var expect_layers := _chain_layers("moab")
        var expect_absorbed := _chain_hp("moab")
        G._hurt_bloon(b, 5000.0, PDData.SHARP, src)
        ck(G.bloons.is_empty(), "FLOW: 5000dmg vs moab erases the ENTIRE family tree (got %d bloons left)" % G.bloons.size())
        ck(G.coins - c0 == expect_layers, "FLOW: moab chain pays every layer at once +%d (got %d)" % [expect_layers, G.coins - c0])
        ck(int(src["inflicted"]) == expect_absorbed, "FLOW: moab chain inflicted = %d absorbed (got %d)" % [expect_absorbed, int(src["inflicted"])])

        # the tank truth: a ceramic ring is worth 10 - a 3 dmg shot eats INTO it,
        # no ring crossed, no coins yet (the wheel is stronger than the weapon).
        b = _mk_bloon("ceramic", 1)
        c0 = G.coins
        src = _fake_src()
        G._hurt_bloon(b, 3.0, PDData.SHARP, src)
        ck(G.bloons.has(b), "3dmg vs ceramic(10): alive, ring holds")
        ck(G.coins - c0 == 0, "3dmg vs ceramic(10): no full layer popped, no coins (got %d)" % (G.coins - c0))
        # and a 12 dmg shot cracks the ring AND spills into the next: +1 for the
        # one full ring it emptied.
        b = _mk_bloon("ceramic", 2)
        c0 = G.coins
        src = _fake_src()
        G._hurt_bloon(b, 12.0, PDData.SHARP, src)
        ck(int(b["lv"]) == 1, "12dmg vs 2 ceramic rings: one ring crossed")
        ck(G.coins - c0 == 1, "12dmg vs 2 ceramic rings: +1 for the crossed ring (got %d)" % (G.coins - c0))

        print("---- ps_shot_probe: %d checks, %d fails" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)
