extends Node
## sheets_probe - the v0.3.9 SHEET EVIDENCE: boots a game, opens its
## shop (and the options for bovo), screenshots each, quits.
## ARG_SHEET=fl_shop | bv_shop | bv_options  (env)

var g: GogaGame = null
var kind := ""
var done := false

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        kind = OS.get_environment("ARG_SHEET")
        Box.reset_all()
        Box.earn(5000)   # a funded wallet: the buttons all live
        var script: GDScript
        var id := ""
        if kind == "fl_shop":
                script = load("res://game/games/fourline/fourline.gd")
                id = "fourline"
        else:
                script = load("res://game/games/bovo/bovo.gd")
                id = "bovo"
        g = script.new()
        g.game_id = id
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        if g.ready_ui != null and is_instance_valid(g.ready_ui):
                g.ready_ui.queue_free()
                g.ready_ui = null
        g.paused = false
        g.state = "play"
        if kind == "bv_options":
                g._options_open()
        else:
                g._shop_open()
        await get_tree().create_timer(1.2).timeout
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        if img != null:
                img.save_png("/tmp/film39/sheet_%s.png" % kind)
        print("sheet saved: ", kind)
        get_tree().quit(0)
