extends Node
## v041-3 r2 THE EYE PASS #2: the button out-of-resolution verdict. One
## sheet, one deliberate zoo: a normal 560 row, a 2000-px monster, a
## narrow long-text button, a long coin row - the sheet must open at the
## 82% base with >=5% free per side and every button inside it (long
## lines wrap taller, never wider).
func _ready() -> void:
        var root := Control.new()
        root.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(root)
        var vb := Arc.sheet(root, 0.0)
        vb.add_child(Arc.label("THE WIDTH ZOO", 34, Arc.INK))
        vb.add_child(Arc.button("PLAY", Vector2(560, 64), 28, Arc.ACCENT))
        vb.add_child(Arc.button("A MONSTER ROW", Vector2(2000, 84), 30, Arc.HOT))
        vb.add_child(Arc.button("THIS IS A VERY LONG SHOP BUTTON TEXT THAT CANNOT FIT",
                        Vector2(300, 64), 30, Color("2f7a46")))
        vb.add_child(Arc.coin_button("UNLOCK THE GOLDEN ARMOR AND IT KEEPS GOING "
                        + "WELL PAST EVERY STEPPED-DOWN SIZE THE LADDER CAN OFFER",
                        Vector2(2000, 64), 26, Color("8a6a20")))
        await get_tree().create_timer(0.5).timeout
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/sheet_shot.png")
        print("[qa] sheet shot saved")
        get_tree().quit(0)
