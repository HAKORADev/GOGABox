extends Node
## v0421_shot — THE EYE PASS (law 32) for the FIRST LAN PATCH's new UI.
## Boots the REAL main scene under a REAL window and photographs: the new
## SVG LAN button, the reworked profile sheet (the ONE placeholder face,
## the age select, the showcase), the visitor view with real links, the
## add-by-details + scan sheets, and the in-game chat sheet.

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute("/tmp/v0421_shots")
        print("=== v042-1 EYE PASS ===")
        LanProfile.set_player_name("TESTER")
        LanProfile.data()["desc"] = "i build tiny wars"
        LanProfile.data()["links"] = ["github.com/HAKORADev", "not a link at all"]
        LanProfile.data()["age"] = 99
        LanProfile.save()
        Box.earn(100000)
        Box.unlock_game("snl", 0)
        var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
        add_child(main)
        await _wait(5.0)
        var menu := _find_menu(main)
        if menu == null:
                print("EYE FAIL: no menu found")
                get_tree().quit(1)
                return
        await _shot("1_feed_new_button")
        menu.call("_open_profile")
        await _wait(0.5)
        await _shot("2_profile_new")
        menu.call("_open_age_select")
        await _wait(0.4)
        await _shot("3_age_select")
        menu.call("_close_sheet")
        menu.call("_open_profile_view", menu.call("_my_showcase_seat"))
        await _wait(0.4)
        await _shot("4_showcase_visitor_view")
        menu.call("_close_sheet")
        menu.call("_open_lan")
        await _wait(0.5)
        await _shot("5_lan_join")
        var lan := get_node_or_null("/root/LAN")
        if lan != null:
                var err: String = lan.host_session()
                print("host session: '%s'" % err)
        menu.call("_close_sheet")
        menu.call("_open_lan")
        await _wait(0.5)
        menu.call("_open_scan")
        await _wait(1.8)
        await _shot("6_scan_sheet")
        menu.call("_close_sheet")
        # the in-game chat seat: a live snl LAN boot with 2 seats
        if lan != null and lan.session_active():
                lan._add_local_seat(0)
                menu.call("_close_sheet")
                var router := Node2D.new()
                add_child(router)
                var gh := load("res://game/core/game_host.gd")
                var ok: bool = gh.call("launch", router, "snl")
                print("snl launch: %s" % ok)
                await _wait(3.0)
                await _shot("7_snllan_boot")
                # the chat sheet over the live game
                # the chat sheet needs the GAME node (sheet_push lives there)
                var game_node := _find_game(router)
                print("chat game node: %s" % (game_node != null))
                var chat := load("res://game/core/lan_chat_ui.gd")
                if game_node != null:
                        chat.call("open", game_node)
                await _wait(0.6)
                LAN.send_chat("first blood")
                await _wait(0.4)
                await _shot("8_chat_sheet")
        print("=== EYE PASS DONE ===")
        get_tree().quit(0)

func _find_game(root: Node) -> Node:
        var stack := [root]
        while not stack.is_empty():
                var n: Node = stack.pop_back()
                if "lan_active" in n and n.has_method("sheet_push"):
                        return n
                for c in n.get_children():
                        stack.append(c)
        return null

func _find_menu(root: Node) -> Node:
        if root.get_script() != null \
                        and String((root.get_script() as Script).resource_path).ends_with("menu.gd"):
                return root
        for c in root.get_children():
                var m := _find_menu(c)
                if m != null:
                        return m
        return null

func _wait(sec: float) -> void:
        var t := 0.0
        while t < sec:
                await get_tree().process_frame
                t += get_process_delta_time()

func _shot(name_v: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/v0421_shots/%s.png" % name_v)
        print("shot: %s" % name_v)
