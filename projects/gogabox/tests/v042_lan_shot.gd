extends Node
## v042_lan_shot — THE EYE PASS (law 32) for the LAN round's new UI.
## Boots the REAL main scene under a REAL window, opens every new surface,
## and photographs each: the drawn LAN button, the two-option menu, the
## profile sheet, the LAN join sheet, the live session sheet, the pre-play
## LAN tags + live line, and the in-game LAN waiting room.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute("/tmp/v042_shots")
	print("=== v042 LAN EYE PASS ===")
	LanProfile.set_player_name("TESTER")
	LanProfile.save()
	print("RIG NAME CHECK: '", LanProfile.player_name(), "'")
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
	menu.call("_open_multiplayer_menu")
	await _wait(0.5)
	await _shot("2_mp_menu")
	menu.call("_close_sheet")
	menu.call("_open_profile")
	await _wait(0.5)
	await _shot("3_profile")
	menu.call("_close_sheet")
	menu.call("_open_lan")
	await _wait(0.5)
	await _shot("4_lan_join")
	var lan := get_node_or_null("/root/LAN")
	if lan != null:
		var err: String = lan.host_session()
		print("host session: '%s' addr=%s code=%s" % [err, lan.host_addr, lan.room_code])
	menu.call("_close_sheet")
	menu.call("_open_lan")
	await _wait(0.6)
	await _shot("5_lan_session")
	# the pre-play page (the LAN tags + the live line under a live session)
	# v042: a 2-seat session so the live line speaks; then scroll the page
	# down to the LAN rows
	if lan != null and lan.session_active():
		lan._add_local_seat(0)
	menu.call("_close_sheet")
	menu.call("_open_game_page", GameReg.get_game("snl"))
	await _wait(0.7)
	_scroll_page(menu)
	await _wait(0.4)
	await _shot("6_game_page")
	menu.call("_close_sheet")
	# the LAN waiting room inside a real game boot
	if lan != null and lan.session_active():
		var router := Node2D.new()
		add_child(router)
		var gh := load("res://game/core/game_host.gd")
		var ok: bool = gh.call("launch", router, "snl")
		print("snl launch: %s" % ok)
		await _wait(4.5)
		await _shot("7_lan_hold")
	print("=== EYE PASS DONE ===")
	get_tree().quit(0)

func _scroll_page(menu: Node) -> void:
	# walk the live sheet for its BoxScroll and push it to the LAN rows
	var stack := [menu]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is BoxScroll:
			(n as BoxScroll).scroll_vertical = 1400
			return
		for c in n.get_children():
			stack.append(c)

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
	img.save_png("/tmp/v042_shots/%s.png" % name_v)
	print("shot: %s" % name_v)
