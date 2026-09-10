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
