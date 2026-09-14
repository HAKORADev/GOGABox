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
        # 6s of honest place-1 combat: hold fire, wiggle the tank
        tap(2, Vector2(1700, 900), true)
        for i in 6:
                drag(1, Vector2(240 + (i % 2) * 260, 900))
                await _wait(0.4)
                drag(1, Vector2(480 - (i % 2) * 200, 900))
                await _wait(0.4)
        # the nuke show
        tap(3, Vector2(960, 540), true)
        tap(3, Vector2(960, 540), false)
        await _wait(2.0)
        # skip to the tunnel (the veil + the calm)
        G.t_state = float(G.place["len"]) + 0.1
        await _wait(4.0)
        # the next place fights on
        tap(2, Vector2(1700, 900), true)
        for i in 4:
                drag(1, Vector2(300 + (i % 2) * 300, 900))
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
        await _wait(6.5)
        get_tree().quit(0)
