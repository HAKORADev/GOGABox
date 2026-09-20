extends Node
## v041 DEV SHEET REOPEN PROBE - the owner: "when i tried to open the dev
## cheats menu again, everytime i open it, it restarts the app". The rig
## opens the sheet, closes it, and opens it again - twice - watching for
## any script error. Exit 0 = the seat survives the reopen family.

var menu: Node2D

func _ready() -> void:
        Box.dev_set_cheat("code", 1)
        menu = Node2D.new()
        menu.set_script(load("res://game/menu/menu.gd"))
        add_child(menu)
        await get_tree().process_frame
        await get_tree().process_frame
        for round_i in 3:
                menu.call("_open_dev_sheet")
                await get_tree().process_frame
                await get_tree().process_frame
                if not menu.call("has_open_overlay"):
                        print("PROBE_FAIL - open round %d left no sheet" % round_i)
                        return _done()
                # flip a switch while we are in there (the owner's exact flow:
                # he toggled, closed, and came back for the extras he missed)
                var scroll: BoxScroll = menu.find_children("*", "BoxScroll",
                                true, false)[0]
                if scroll.get_child_count() > 0:
                        var v: VBoxContainer = scroll.get_child(0)
                        for c in v.get_children():
                                if c is Button:
                                        (c as Button).pressed.emit()
                                        break
                await get_tree().process_frame
                menu.call("_close_sheet")
                await get_tree().process_frame
                await get_tree().process_frame
                if menu.call("has_open_overlay"):
                        print("PROBE_FAIL - close round %d left a sheet" % round_i)
                        return _done()
        print("DEV_REOPEN_OK")
        _done()

func _done() -> void:
        Box.reset_all()
        get_tree().quit(0)
