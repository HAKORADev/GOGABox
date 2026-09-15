extends Node
## HEAVY WAR film scene - a scripted demo run for the visual rig.
## Boots the game, taps to start, then plays like a player: drags the tank,
## holds fire, drops a nuke, skips ahead to the tunnel and a boss.
## Film rig: tools/v038p6_film.sh res://tests/hw_film.tscn <secs> <out> 1920x1080x24 1920x1080

var G: GogaGame = null
var t := 0.0
var act := 0

func _wait(sec: float) -> void:
        await get_tree().create_timer(sec, true).timeout

func tap(idx: int, pos: Vector2, down: bool) -> void:
        var e := InputEventScreenTouch.new()
        e.index = idx
        e.position = pos
        e.pressed = down
        G._goga_input(e)

func drag(idx: int, pos: Vector2) -> void:
        var e := InputEventScreenDrag.new()
        e.index = idx
        e.position = pos
        G._goga_input(e)

func _ready() -> void:
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())    # the landscape design law (host duty)
        Box.dev_set_cheat("all_owned", 1)
        G = load("res://game/games/heavywar/heavywar.gd").new()
        G.game_id = "heavywar"
        add_child(G)
        await _wait(1.2)
        tap(0, Vector2(960, 540), true)     # THE TAP: anywhere starts the war
        tap(0, Vector2(960, 540), false)
        _play.call_deferred()

func _play() -> void:
        # 6s of honest place-1 combat: the aim finger holds the center,
        # the steer finger glides the tank along the bottom, the gun
        # tracks the nearest enemy like a real thumb would
        tap(2, Vector2(1500, 540), true)     # the AIM + FIRE finger (center)
        tap(1, Vector2(500, 950), true)      # the STEER finger (bottom)
        for i in 12:
                drag(1, Vector2(240.0 + (i % 2) * 420.0, 950))
                if not G.enemies.is_empty():
                        drag(2, G.enemies[0]["n"].position)
                await _wait(0.5)
        # the nuke show (the top zone)
        tap(3, Vector2(960, 200), true)
        tap(3, Vector2(960, 200), false)
        await _wait(2.0)
        # skip to the tunnel (the veil + the calm)
        G.t_state = float(G.place["len"]) + 0.1
        await _wait(4.0)
        # the next place fights on
        for i in 6:
                drag(1, Vector2(300.0 + (i % 2) * 380.0, 950))
                if not G.enemies.is_empty():
                        drag(2, G.enemies[0]["n"].position)
                await _wait(0.5)
        # force the 5-place cadence: straight to the boss face
        G.run["places_done"] = 4
        G.run["place_i"] = 4
        G._ensure_queue()
        G._enter_tunnel()
        await _wait(5.0)
        # the boss fight with the laser charged for the megabeam shot
        G.run["laser_parts"] = 99
        G._collect("laser")
        for i in 8:
                if not G.enemies.is_empty():
                        drag(2, G.enemies[0]["n"].position)
                elif boss_alive():
                        drag(2, Vector2(1400, 320))
                await _wait(0.8)
        get_tree().quit(0)

func boss_alive() -> bool:
        return G.boss != null and is_instance_valid(G.boss["n"])
