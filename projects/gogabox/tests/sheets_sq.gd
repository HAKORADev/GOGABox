extends Node
## sheets_sq - photographs the SQUARES shop + options sheets (the
## sheets_probe law) for the visual review.

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        Box.earn(9000)
        var SQ: GDScript = load("res://game/games/squares/squares.gd")
        var g: GogaGame = SQ.new()
        g.game_id = "squares"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        if g.ready_ui != null and is_instance_valid(g.ready_ui):
                g.ready_ui.visible = false
        # THE SHOP
        g._shop_open()
        await get_tree().process_frame
        await get_tree().process_frame
        var img: Image = get_viewport().get_texture().get_image()
        if img != null:
                img.save_png("/tmp/film393/shop.png")
                print("shop shot saved")
        g.sheet_pop()
        await get_tree().process_frame
        await get_tree().process_frame
        # THE OPTIONS
        g._options_open()
        await get_tree().process_frame
        await get_tree().process_frame
        var img2: Image = get_viewport().get_texture().get_image()
        if img2 != null:
                img2.save_png("/tmp/film393/options.png")
                print("options shot saved")
        get_tree().quit(0)
