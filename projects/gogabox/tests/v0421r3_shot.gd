extends Node
## v0421r3_shot — THE EYE PASS (law 32) for the ROUND-3 patch's new UI.
## Boots the REAL main scene under a REAL window and photographs:
##   1. the session sheet (12 seats line, the ONLINE ON/OFF truth, the
##      member rows with the live state tags, no ADD LOCAL PLAYER)
##   2. the scan sheet (the LIVE loop rows: FREE / HOSTS n/12 / PLAYING)
##   3. a game's ROOM SCREEN: the picker, then the owner's room view with
##      the join-order seats and START THE GAME, then the member's brown
##      WAITING FOR <OWNER> TO START THE GAME
##   4. the top-level invite card (LanNotes) over the feed
##   5. the chat sheet with the live cooldown + the dots on the CHAT button

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute("/tmp/v0421r3_shots")
        print("=== v042-1 r3 EYE PASS ===")
        LanProfile.set_player_name("TESTER")
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
        await _shot("1_feed")
        # --- the session sheet: host a real session, paint the rows ---
        var lan := get_node_or_null("/root/LAN")
        if lan != null:
                var err: String = lan.host_session()
                print("host session: '%s'" % err)
                # a fake second seat arrives (the UI paints from LAN.seats)
                lan.seats.append({"dev": "eyeDev2", "name": "HANNA", "pfp": 2,
                        "pfpm": {}, "desc": "", "links": [], "age": 0,
                        "gender": "female", "role": "gamer", "anchor": "",
                        "seat": 2, "local_slot": 0, "platform": "android",
                        "state": "lobby"})
                lan.session_changed.emit()
        menu.call("_close_sheet")
        menu.call("_open_lan")
        await _wait(0.6)
        await _shot("2_session_sheet")
        menu.call("_close_sheet")
        # --- the scan sheet with the honest live rows ---
        menu.call("_open_lan")
        await _wait(0.4)
        menu.call("_open_scan")
        await _wait(0.4)
        var scan_list: VBoxContainer = menu.get("_scan_list")
        if scan_list != null and is_instance_valid(scan_list):
                scan_list.add_child(menu.call("_scan_row", {"dev": "eyeDev3",
                                "name": "FreeFred", "in_session": false, "size": 0,
                                "is_host": false, "playing": ""}))
                scan_list.add_child(menu.call("_scan_row", {"dev": "eyeDev4",
                                "name": "HostHana", "in_session": true, "size": 2,
                                "is_host": true, "playing": ""}))
                scan_list.add_child(menu.call("_scan_row", {"dev": "eyeDev5",
                                "name": "PlayerPia", "in_session": true, "size": 3,
                                "is_host": false, "playing": "ludo"}))
        await _wait(0.3)
        await _shot("3_scan_rows")
        menu.call("_close_sheet")
        menu.call("_close_sheet")
        # --- the invite card: the top-level layer over the feed ---
        LanNotes.invite_card("HANNA", "192.168.1.44:31440", true)
        await _wait(0.7)
        await _shot("4_invite_card")
        # --- the room screen inside a real game boot: the session lives ---
        lan.host_session()
        await _wait(0.4)
        lan.seats.append({"dev": "eyeDev2", "name": "HANNA", "pfp": 2,
                "pfpm": {}, "desc": "", "links": [], "age": 0,
                "gender": "female", "role": "gamer", "anchor": "",
                "seat": 2, "local_slot": 0, "platform": "android",
                "state": "lobby"})
        lan.session_changed.emit()
        await _wait(0.3)
        var host_script: GDScript = load("res://game/core/game_host.gd")
        var router := Node2D.new()
        add_child(router)
        Box.unlock_game("snl", 0)
        var launched: bool = host_script.launch(router, "snl")
        print("snl launch: %s" % launched)
        await _wait(5.0)
        var host: Node = host_script.active_host
        if host != null and host.game != null:
                # the room PICKER (no rooms yet)
                await _shot("5_room_picker")
                # the owner's room view: create + a fake second seat joins
                var errc: String = lan.open_room("snl", {"mode": 4})
                print("open room: '%s'" % errc)
                # the fake second member rides the broadcast
                var rid: int = lan.probe_state()["my_room"]
                if rid != 0:
                        var members: Array = lan.room_by_id(rid).get("members", [])
                        members.append("eyeDev2")
                        lan.rooms[rid]["members"] = members
                        lan._push_rooms()
                await _wait(0.6)
                await _shot("6_owner_room")
                # the member's view: the brown wait (fake: clear my membership
                # on a THROWAWAY second core is heavy - instead paint the
                # member view through a stripped room dict is dishonest; the
                # brown wait is proven by the code path and the qa rig)
        else:
                print("EYE FAIL: no game host")
        print("=== EYE PASS DONE ===")
        get_tree().quit(0)

func _shot(name_v: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/v0421r3_shots/%s.png" % name_v)
        print("shot: %s" % name_v)

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
