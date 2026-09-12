extends Node
## menu_shot_sq - boots the REAL main scene with a FULL save (every game
## owned), scrolls to the SOON shelf, photographs the feed: the SQUARES
## tile in the owned block + the next five teasers in the workshop.

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        Box.earn(50000)
        for gid in GameReg.playable():
                Box.unlock_game(String(gid["id"]), 0)
        var ps: PackedScene = load("res://main.tscn")
        var m: Node = ps.instantiate()
        add_child(m)
        await get_tree().create_timer(2.0).timeout
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        if img != null:
                img.save_png("/tmp/film393/menu_top.png")
                print("[qa] menu top saved")
        # walk to the feed's tail (the SOON shelf): a REAL finger -
        # press, drag the whole run, lift
        await get_tree().create_timer(0.3).timeout
        var tp := InputEventScreenTouch.new()
        tp.position = Vector2(540, 1500)
        tp.pressed = true
        Input.parse_input_event(tp)
        await get_tree().create_timer(0.05).timeout
        for i in 40:
                var d := InputEventScreenDrag.new()
                d.position = Vector2(540, 1500 - i * 120)
                d.relative = Vector2(0, -120)
                Input.parse_input_event(d)
                await get_tree().create_timer(0.03).timeout
        var tr := InputEventScreenTouch.new()
        tr.position = Vector2(540, 300)
        tr.pressed = false
        Input.parse_input_event(tr)
        await get_tree().create_timer(0.8).timeout
        await get_tree().process_frame
        await get_tree().process_frame
        var img2 := get_viewport().get_texture().get_image()
        if img2 != null:
                img2.save_png("/tmp/film393/menu_tail.png")
                print("[qa] menu tail saved")
        get_tree().quit(0)
