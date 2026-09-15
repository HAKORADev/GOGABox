extends Node
## the lineup: every SRC_SPRITES id drawn at a grid position with its
## real _art_sprite sizes - the film catches whoever wears a black box.

func _ready() -> void:
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())
        var bg := ColorRect.new()
        bg.color = Color(0.2, 0.45, 0.25)
        bg.size = Vector2(1920, 1080)
        add_child(bg)
        var G: GogaGame = load("res://game/games/heavywar/heavywar.gd").new()
        G.game_id = "heavywar"
        add_child(G)
        await get_tree().create_timer(0.8, true).timeout
        var ids: Array = G.SRC_SPRITES.keys()
        var col := 0
        var row := 0
        for id in ids:
                var holder: Node2D = G._art_sprite(String(id),
                        Vector2(120, 80), Color(1, 1, 1, 0.4))
                holder.position = Vector2(90 + col * 165, 130 + row * 150)
                add_child(holder)
                var l := Label.new()
                l.text = String(id).replace("enemy_", "").replace("boss_", "*")
                l.position = holder.position + Vector2(-60, 52)
                l.add_theme_font_size_override("font_size", 15)
                add_child(l)
                col += 1
                if col >= 11:
                        col = 0
                        row += 1
        await get_tree().create_timer(6.0, true).timeout
        get_tree().quit(0)
