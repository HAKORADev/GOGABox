extends SceneTree
## v040-11 THE SCROLL LAW VERIFIER: does a same-frame scroll restore survive
## the rebuild's first sort? (the design decision behind the continuity law)
## Builds a ScrollContainer with tall content, scrolls it, rebuilds children,
## restores same-frame, waits a frame, reads back.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_ctrl := Control.new()
	root_ctrl.size = Vector2(600, 800)
	get_root().add_child(root_ctrl)
	await process_frame

	var sc := ScrollContainer.new()
	sc.size = Vector2(600, 800)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	root_ctrl.add_child(sc)
	await process_frame

	var fill := func(box: VBoxContainer, tag: String) -> void:
		for i in 60:
			var l := Label.new()
			l.text = "%s row %d" % [tag, i]
			l.custom_minimum_size = Vector2(560, 40)
			box.add_child(l)

	var v1 := VBoxContainer.new()
	sc.add_child(v1)
	fill.call(v1, "old")
	await process_frame
	await process_frame

	# scroll down like a user
	sc.scroll_vertical = 700
	await process_frame
	print("SET  scroll_vertical=", sc.scroll_vertical)

	# THE REBUILD: free old children, add new ones, restore SAME FRAME
	var want := sc.scroll_vertical
	for c in v1.get_children():
		v1.remove_child(c)
		c.queue_free()
	var v2 := VBoxContainer.new()
	sc.remove_child(v1)
	v1.queue_free()
	sc.add_child(v2)
	fill.call(v2, "new")
	sc.scroll_vertical = want          # the same-frame restore

	await process_frame
	print("SAME-FRAME-RESTORE scroll_vertical=", sc.scroll_vertical, " (want ", want, ")")
	await process_frame
	print("AFTER-2ND-FRAME     scroll_vertical=", sc.scroll_vertical, " (want ", want, ")")

	var ok := int(sc.scroll_vertical) == int(want)
	print("VERDICT: ", "SAME-FRAME RESTORE WORKS" if ok else "SAME-FRAME FAILS - need the 2-frame dance")
	quit(0 if ok else 1)
