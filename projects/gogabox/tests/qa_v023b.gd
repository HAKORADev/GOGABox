extends Node
## qa_v023b - the v0.2.3 patch QA sheet: boots the REAL main scene, opens
## the DEV CHEATS sheet (five taps simulated through _open_dev_sheet), and
## screenshots it; then the SOON page (the purple ? header) screenshots too.

func _ready() -> void:
        var ps: PackedScene = load("res://main.tscn")
        var m: Node = ps.instantiate()
        add_child(m)
        await get_tree().create_timer(2.0).timeout
        await get_tree().process_frame
        # walk into the menu node (main -> Menu)
        var menu: Node = m.get_node("Menu")
        # 1. the DEV CHEATS sheet with the GAME OPTIONALS section
        menu._open_dev_sheet()
        await get_tree().create_timer(0.4).timeout
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/qa_dev_sheet.png")
        print("[qa] dev sheet shot")
        menu._close_sheet()
        # 2. a SOON page - the purple ? must be in the header now
        var soon_g: Dictionary = {}
        for g in GameReg.GAMES:
                if bool(g.get("coming_soon", false)):
                        soon_g = g
                        break
        if not soon_g.is_empty():
                menu._open_soon_page(soon_g)
                await get_tree().create_timer(0.4).timeout
                await get_tree().process_frame
                img = get_viewport().get_texture().get_image()
                img.save_png("/tmp/qa_soon_page.png")
                print("[qa] soon page shot")
                menu._close_sheet()
        get_tree().quit(0)
