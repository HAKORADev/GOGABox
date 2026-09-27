extends Node
const OUT := "/home/z/my-project/download/qa_v029/"
func _shot(path: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        get_viewport().get_texture().get_image().save_png(path)
        print("[qa] ", path)
func _run() -> void:
        DirAccess.make_dir_recursive_absolute(OUT)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        var x: GogaGame = load("res://game/games/xo/xo.gd").new()
        x.game_id = "xo"
        add_child(x)
        await get_tree().create_timer(0.5).timeout
        x.board = [1, 0, 2, 0, 1, 0, 0, 0, 2]
        x._place(0, x.X)
        x._place(2, x.O)
        await get_tree().create_timer(0.12).timeout
        x._place(4, x.X)
        x._place(8, x.O)
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "01_xo_marks_v29.png")
        print("[qa] done")
        get_tree().quit(0)
func _ready() -> void:
        _run.call_deferred()
