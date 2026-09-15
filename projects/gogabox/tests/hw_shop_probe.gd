extends Node
## v040-3 SHOP EYE CHECK: open the shop + armory sheets and still them.
var G
func _ready() -> void:
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())
        G = load("res://game/games/heavywar/heavywar.gd").new()
        G.game_id = "heavywar"
        add_child(G)
        _run.call_deferred()
func _shot(name: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        get_viewport().get_texture().get_image().save_png(
                "/tmp/film/%s.png" % name)
        print("SHOP_SHOT ", name)
func _run() -> void:
        await _wait(1.0)
        G._start_place()
        await _wait(0.3)
        G._shop_open()
        await _wait(0.5)
        await _shot("shop_sheet")
        G._shop_close()
        await _wait(0.2)
        G._enter_armory()
        await _wait(0.5)
        await _shot("armory_sheet")
        get_tree().quit(0)
func _wait(t: float) -> void:
        await get_tree().create_timer(t).timeout
