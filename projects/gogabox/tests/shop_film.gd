extends Node
## shop_film - photographs the SQUARES shop vs FOURLINE's shop (the
## sheets_sq law) - the owner's "too wide buttons while content is
## smaller" round: measure, compare, fix.

func _shot(path: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img: Image = get_viewport().get_texture().get_image()
        if img != null:
                img.save_png(path)
                print("saved ", path)

func _boot(id: String) -> GogaGame:
        Box.reset_all()
        Box.earn(9000)
        var S: GDScript = load("res://game/games/%s/%s.gd" % [id, id])
        var g: GogaGame = S.new()
        g.game_id = id
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        if g.get("ready_ui") != null and is_instance_valid(g.get("ready_ui")):
                g.ready_ui.visible = false
        return g

func _ready() -> void:
        var sq: GogaGame = await _boot("squares")
        sq._shop_open()
        await _shot("/tmp/film395/sq_shop.png")
        sq.sheet_pop()
        await get_tree().process_frame
        sq.queue_free()
        var fl: GogaGame = await _boot("fourline")
        fl._shop_open()
        await _shot("/tmp/film395/fl_shop.png")
        fl.sheet_pop()
        await get_tree().process_frame
        var pm: GogaGame = await _boot("pacman")
        pm._shop_open()
        await _shot("/tmp/film395/pm_shop.png")
        pm.sheet_pop()
        get_tree().quit(0)
