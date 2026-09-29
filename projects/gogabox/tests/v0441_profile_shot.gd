extends Node
## v044-1 diagnostic: the profile sheet wraps in a BoxScroll now (the
## scrollable-form law) - count the wrapped scrolls + shoot it.
func _ready() -> void:
        Box.data["settings"]["pc_position"] = "landscape"   # the short canvas shape
        ScaleRule.pc_position = "landscape"
        GOGA.set_home("user://eye_rig")
        GOGA.reload_entries()
        Box.seed_starter()
        var ps: PackedScene = load("res://main.tscn")
        var m: Node = ps.instantiate()
        add_child(m)
        await get_tree().create_timer(2.0).timeout
        var menu: Node = m.get_node_or_null("Menu")
        menu.call("_open_profile")
        await get_tree().create_timer(1.0).timeout
        var pair: Array = menu.get("_sheet_pair")
        var scrolls: Array = []
        if pair.size() > 1 and pair[1] != null:
                scrolls = (pair[1] as Control).find_children("*", "BoxScroll", true, false)
        print("PROFILE_SCROLLS: ", scrolls.size())
        var pair2: Array = menu.get("_sheet_pair")
        if pair2.size() > 1 and pair2[1] != null:
                var panel: Control = pair2[1]
                var vb: Control = panel.get_child(0) if panel.get_child_count() > 0 else null
                if vb != null:
                        var need: float = vb.get_combined_minimum_size().y + 60.0
                        var avail: float = panel.get_viewport_rect().size.y * 0.94
                        print("PROFILE_FIT: need=%.0f avail=%.0f panel_h=%.0f" % [need, avail, panel.size.y])
        if scrolls.size() > 0:
                var sc: BoxScroll = scrolls[0]
                var inner: Control = sc.get_child(0) if sc.get_child_count() > 0 else null
                var content_h := inner.get_combined_minimum_size().y if inner != null else 0.0
                print("PROFILE_SCROLL content min height: %.0f / view height: %.0f" % [content_h, sc.size.y])
                print("PROFILE_SCROLLABLE: ", content_h > sc.size.y)
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/v0441_profile.png")
        print("SHOT saved")
        get_tree().quit(0)
