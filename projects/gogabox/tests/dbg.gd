extends Node
var G: GogaGame
func _ready() -> void:
        Box.reset_all()
        Box.dev_set_cheat("gogacoins", 0)
        Box.earn(900)
        G = load("res://game/games/hopper/hopper.gd").new()
        G.game_id = "hopper"
        add_child(G)
        await get_tree().process_frame
        await get_tree().process_frame
        if not Box.skin_owned("hopper", "square"):
                Box.buy_skin("hopper", "square", 0)
        Box.equip_skin("hopper", "square")
        G.char_id = "square"
        G.phase = "run"
        for i in 60:
                G._set_axis(1.0)
                G._goga_tick(1.0 / 60.0)
                if i % 15 == 0:
                        print("i=", i, " vx=", G.vx, " grounded=", G.grounded,
                                        " move_dir=", G.move_dir, " flip_phase=", G.flip_phase,
                                        " rot=", G.tumble_rot, " phase=", G.phase,
                                        " cube=", G._cube_body(), " over=", G.over)
        get_tree().quit(0)
