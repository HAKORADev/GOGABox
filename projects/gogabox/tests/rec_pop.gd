extends Node
## rec_pop - THE AUTOMATED GAMEPLAY RIG, pop siege chapter. Boots the
## REAL game, starts the real flow, deploys a real LongEye through the
## game's own _place_folk door, hands it a big honest buff through the
## game's own dmg_f stat, and lets the REAL tick loop fight real waves.
## The film shows the SHOT LAW live: one shot pours through a whole
## chain and banks ONE +nn.

var g: GogaGame = null
var t := 0.0
var deployed := false
var stop := 78.0
var next_send := 10.0
var sends := 0
var last_coins := 0

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        var PS: GDScript = load("res://game/games/pop_siege/pop_siege.gd")
        g = PS.new()
        g.game_id = "pop_siege"
        add_child(g)
        await get_tree().create_timer(0.8).timeout
        g._start_ready()

func _process(dt: float) -> void:
        t += dt
        if g == null:
                return
        if not deployed and t > 2.0:
                deployed = true
                # a funded wallet (the film must not trip the broke doors)
                g.coins = 5000
                # any sheet the boot flow left up pops now - a sheet pauses
                # the siege (THE SHEET PAUSE LAW) and the film freezes
                while g.sheet_open_count() > 0:
                        g.sheet_pop()
                # the real deploy door: a LongEye mid-field, then the game's
                # own buff stat makes its shots pour through chains
                g._place_folk("longeye", Vector2i(5, 3))
                g._place_folk("zappy", Vector2i(3, 2))
                for f in g.folk:
                        if String(f["fid"]) == "longeye":
                                f["buffs"]["dmg_f"] = 200.0
                        elif String(f["fid"]) == "zappy":
                                f["buffs"]["dmg_f"] = 120.0
                # THE FIRST WAVE LAW: the owner calls wave 1 with the SEND
                # button - the rig presses the same door
                print("[rec_pop] pre-send phase=", g.phase, " over=", g.over,
                                " folk=", g.folk.size())
                g._next_wave_pressed()
                print("[rec_pop] post-send phase=", g.phase, " wave_n=", g.wave_n,
                                " q=", g.spawn_q.size())
        # THE STACK LAW (a real door: mid-roll sends APPEND the next wave):
        # the rig stacks waves so the film shows a real siege, not one bloon
        # trickling in - the buffed LongEye eats crowds and the +nn rain shows
        if t > next_send and sends < 4 and not g.over:
                sends += 1
                next_send = t + 12.0
                g._next_wave_pressed()
        # THE DATA TRAIL: every popcoin bank the run pays, straight from
        # the live run (the owner: "take the data from it")
        var cnow := int(g.coins)
        if cnow != last_coins:
                if cnow > last_coins:
                        print("[pop-bank] +2 BANK: +%d n coins total %d | wave %d | %d bloons | t %.1f"
                                        % [cnow - last_coins, cnow, g.wave_n,
                                        g.bloons.size(), t])
                last_coins = cnow
        if t > stop:
                print("[rec_pop] done t=", t, " coins=", g.coins,
                                " wave_n=", g.wave_n, " bloons=", g.bloons.size())
                get_tree().quit(0)
