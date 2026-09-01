extends Node
## qa_devcrash - the v0.2.3 patch QA: the owner's "dev cheats crash after
## each option toggle". Fires the REAL pressed-signal path on the switch
## rows several times (the old build rebuilt the sheet inside the tap and
## died); the new rows must note the flip in place and keep the sheet. Then
## screenshots the new sheet (DONE / RESTART BOX, no optionals) and closes.

func _ready() -> void:
        var ps: PackedScene = load("res://main.tscn")
        var m: Node = ps.instantiate()
        add_child(m)
        await get_tree().create_timer(2.0).timeout
        await get_tree().process_frame
        var menu: Node = m.get_node("Menu")
        var fails := 0
        for round_i in range(4):
                menu._open_dev_sheet()
                await get_tree().create_timer(0.3).timeout
                await get_tree().process_frame
                var root_ctrl: Control = menu._root
                var kids := root_ctrl.get_children()
                var center: Control = kids[kids.size() - 1]
                var names := ["ALL_OWNED", "GOGACOINS", "BATTERY", "CODE"]
                var btn := _find_button(center, names[round_i % names.size()])
                print("[qa] round %d row found: %s (%s)" % [round_i,
                                btn != null, btn.text if btn != null else "-"])
                if btn == null:
                        fails += 1
                        break
                var before: String = btn.text
                btn.pressed.emit()   # the REAL toggle path
                await get_tree().create_timer(0.2).timeout
                await get_tree().process_frame
                if not menu._sheet_open:
                        print("[qa] FAIL: the sheet rebuilt/vanished on toggle")
                        fails += 1
                        break
                print("[qa] round %d survived: %s -> %s" % [round_i,
                                before, btn.text])
        # the new sheet pieces
        var ok_done := _find_button(menu._root, "DONE") != null
        var ok_rst := _find_button(menu._root, "RESTART BOX") != null
        var ok_old := _find_button(menu._root, "SNAKE - ") == null
        print("[qa] DONE=%s RESTART=%s optionals-gone=%s" %
                        [ok_done, ok_rst, ok_old])
        if not (ok_done and ok_rst and ok_old):
                fails += 1
        await get_tree().create_timer(0.3).timeout
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/qa_dev_sheet2.png")
        print("[qa] dev sheet shot")
        menu._close_sheet()
        await get_tree().create_timer(0.3).timeout
        await get_tree().process_frame
        img = get_viewport().get_texture().get_image()
        img.save_png("/tmp/qa_feed_after_close.png")
        print("[qa] feed after close shot (dirty=%s)" % menu._dev_dirty)
        print("=== qa_devcrash %s ===" % ("PASS" if fails == 0 else "FAIL"))
        get_tree().quit(1 if fails > 0 else 0)

func _find_button(n: Node, prefix: String) -> Button:
        if n is Button and String((n as Button).text).begins_with(prefix):
                return n as Button
        for c in n.get_children():
                var r := _find_button(c, prefix)
                if r != null:
                        return r
        return null
