extends Node
func _ready() -> void:
        Box.reset_all()
        Box.earn(9000)
        var PM: GDScript = load("res://game/games/pacman/pacman.gd")
        var g: GogaGame = PM.new()
        g.game_id = "pacman"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        g._shop_open()
        await get_tree().process_frame
        await get_tree().process_frame
        _walk(g._overlay_root_ref(), 0)
        get_tree().quit(0)

func _walk(n: Node, depth: int) -> void:
        if n is Control and (n is Button or n is BoxScroll or n is PanelContainer):
                var c := n as Control
                print("%s%s [%s] pos=%s size=%s min=%s" % ["  ".repeat(depth),
                        n.get_class(), n.name if n.name != "" else "?",
                        c.global_position, c.size, c.custom_minimum_size])
        if n is BoxScroll or (n is Button and n.get_child_count() > 0):
                for ch in n.get_children():
                        _walk(ch, depth + 1)
                return
        if n is Button:
                return
        for ch in n.get_children():
                _walk(ch, depth + 1)
