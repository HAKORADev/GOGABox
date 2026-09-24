extends Node
## v0421r2_shot — THE EYE PASS (law 32) for the ROUND-2 patch's new UI.
## Boots the REAL main scene under a REAL window and photographs: the
## reworked icon (circle + arch + plus), the reworked placeholder face
## (the icon's shape, yellow, big), the r2 link row (3 lines + domain
## hint), the scan sheet's honest rows, and the name gate.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute("/tmp/v0421r2_shots")
	print("=== v042-1 r2 EYE PASS ===")
	LanProfile.set_player_name("TESTER")
	LanProfile.data()["desc"] = "i build tiny wars and i tell you all about them here so the line wraps around"
	LanProfile.data()["links"] = [
		"https://docs.google.com/spreadsheets/d/1abc/edit#gid=0",
		"github.com/HAKORADev/GOGABox",
		"not a link at all"]
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
	await _shot("1_feed_icon")
	menu.call("_open_profile")
	await _wait(0.6)
	await _shot("2_profile_placeholder")
	menu.call("_close_sheet")
	menu.call("_open_profile_view", menu.call("_my_showcase_seat"))
	await _wait(0.5)
	await _shot("3_visitor_links")
	menu.call("_close_sheet")
	# the scan sheet with honest rows (fake peers painted through the
	# real _scan_row builder)
	menu.call("_open_lan")
	await _wait(0.4)
	var lan := get_node_or_null("/root/LAN")
	if lan != null:
		var err: String = lan.host_session()
		print("host session: '%s'" % err)
	menu.call("_close_sheet")
	menu.call("_open_lan")
	await _wait(0.4)
	menu.call("_open_scan")
	await _wait(0.4)
	var scan_list: VBoxContainer = menu.get("_scan_list")
	if scan_list != null and is_instance_valid(scan_list):
		scan_list.add_child(menu.call("_scan_row", {"dev": "eyeDev1",
				"name": "FreeFred", "in_session": false, "size": 0,
				"is_host": false}))
		scan_list.add_child(menu.call("_scan_row", {"dev": "eyeDev2",
				"name": "HostHana", "in_session": true, "size": 2,
				"is_host": true}))
	await _wait(0.3)
	await _shot("4_scan_rows")
	menu.call("_close_sheet")
	# the join sheet with the r2 name field + gates
	menu.call("_close_sheet")
	menu.call("_open_lan")
	await _wait(0.5)
	await _shot("5_join_name_gate")
	menu.call("_close_sheet")
	print("=== EYE PASS DONE ===")
	get_tree().quit(0)

func _shot(name_v: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/v0421r2_shots/%s.png" % name_v)
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
