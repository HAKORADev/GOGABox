extends Node
## menu_shot - boots the REAL main scene, waits for the feed, screenshots.
func _ready() -> void:
        var ps: PackedScene = load("res://main.tscn")
        var m: Node = ps.instantiate()
        add_child(m)
        await get_tree().create_timer(2.0).timeout
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/menu_shot.png")
        print("[qa] menu shot")
        get_tree().quit(0)
