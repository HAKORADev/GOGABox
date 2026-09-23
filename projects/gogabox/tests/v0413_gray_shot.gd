extends Node
## v041-3 r2 THE EYE PASS: the gray-on-square-thumb verdict. Boots the REAL
## menu with rally owned + its daily rounds burned - the tile must read
## daily-dead with the gray sitting EXACTLY on the SQUARE thumbnail (no
## curve anywhere), next to live tiles for the contrast.
func _ready() -> void:
        Box.unlock_game("rally", 0)
        for i in 8:
                Box.record_started("rally")
        var ps: PackedScene = load("res://main.tscn")
        var m: Node = ps.instantiate()
        add_child(m)
        await get_tree().create_timer(3.0).timeout
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/gray_shot.png")
        print("[qa] gray shot saved")
        get_tree().quit(0)
