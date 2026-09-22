extends Node
## v041-1 r5 THE DRAW-ERROR HUNT, round 2: walk EVERY playable game
## (launch -> story dismiss -> 2s live -> pause beat -> quit) under a
## real GL context; the owner's godot.log draw_circle error prints to
## stderr the moment its path runs. Also beats the menu sheets once.

const GAMES := [
        "snake", "rally", "lanes", "slasher", "hopper", "merge", "dario",
        "xo", "matcher", "invaders", "cosmic_spud", "pop_siege", "geometry",
        "maze", "domino", "chess", "fourline", "bovo", "squares", "pacman",
        "brickbreaker", "jumpcube", "ludo", "snl", "heavywar", "rockbreaker",
        "deathworm", "marble", "goldminer",
]

var _main: Node

func _ready() -> void:
        Box.dev_set_cheat("all_owned", 1)
        _main = load("res://main.tscn").instantiate()
        add_child(_main)
        await get_tree().create_timer(3.2).timeout
        for gid in GAMES:
                print("PROBE: launching ", gid)
                GameHost.launch(_main, gid)
                await get_tree().create_timer(1.8).timeout
                var host: Node = GameHost.active_host
                if host != null and host.get("game") != null:
                        var game: Node = host.get("game")
                        if game.has_method("box_story_dismiss"):
                                game.call("box_story_dismiss")
                        if host.has_method("request_pause"):
                                host.call("request_pause")
                                await get_tree().create_timer(0.4).timeout
                                if game.has_method("_pause_close"):
                                        game.call("_pause_close")
                        await get_tree().create_timer(1.2).timeout
                GameHost.end_session()
                await get_tree().create_timer(0.8).timeout
        print("PROBE_OK")
        get_tree().quit(0)
