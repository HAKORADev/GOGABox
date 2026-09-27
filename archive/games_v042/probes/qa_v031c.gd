extends Node
## qa_v031c (patch III) - the visual QA: the LOADER's real 3:2 thumb frame,
## the slasher regression, and CURSED DARIO in LANDSCAPE (the owner plays
## landscape): the new zoomed framing, the alive spikes, the mover ride,
## the rhino's windup, the hunting bat, the death quote bubble, the night
## arena and the Witcher at her map cell.
##   DISPLAY=:99 godot --path . res://tests/qa_v031c.tscn

const OUT := "/home/z/my-project/download/qa_v031c/"

func _shot(path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	print("[qa] ", path)

func _unlock(g: GogaGame) -> void:
	g._pair_down(g._intro_pair)
	g._intro_pair = []
	g._locked = false

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	Box.reset_all()
	Box.dev_set_cheat("all_owned", 1)
	# LANDSCAPE window - dario is a landscape game (the owner's view)
	get_window().size = Vector2i(1706, 960)
	await get_tree().create_timer(0.3).timeout

	# ================= THE LOADER (the 3:2 thumb frame fix) ==========
	var ld: CanvasLayer = load("res://game/core/loader.gd").new()
	ld.layer = 30
	add_child(ld)
	ld._run(GameReg.get_game("dario"))
	await get_tree().create_timer(0.8).timeout
	await _shot(OUT + "01_loader_thumb.png")
	ld.queue_free()
	await get_tree().create_timer(0.5).timeout

	# ================= FRUIT SLASHER (regression) ====================
	var s: GogaGame = load("res://game/games/slasher/slasher.gd").new()
	s.game_id = "slasher"
	add_child(s)
	await get_tree().create_timer(0.5).timeout
	s._orient_choice("horizontal")
	s._start_run()
	await get_tree().create_timer(1.2).timeout
	await _shot(OUT + "02_slasher_run.png")
	s.queue_free()

	# ================= CURSED DARIO (landscape) ======================
	var d: GogaGame = load("res://game/games/dario/dario.gd").new()
	d.game_id = "dario"
	add_child(d)
	await get_tree().create_timer(0.8).timeout
	await _shot(OUT + "03_dario_intro_box.png")
	_unlock(d)
	await get_tree().create_timer(0.5).timeout
	# level 1 day: the ZOOMED world, the forest pinned to the ground line,
	# the trophy ON the grass at the far end
	d._bubble_say("DARIO: ...where am I? The sky is wrong.", 30.0)
	d._cam_follow()
	d._bg_tick()
	await _shot(OUT + "04_dario_landscape_day.png")
	# park Dario next to the trophy to see the CUP LAW
	d.p_node.position = Vector2(125.0 * 80.0, 12.0 * 80.0)
	d._cam_follow()
	d._bg_tick()
	await get_tree().create_timer(0.2).timeout
	await _shot(OUT + "05_dario_trophy_ground.png")

	# the ALIVE SPIKES: level 2, Dario walking at the spike field
	d._load_level(1)
	_unlock(d)
	d._bubble_say("DARIO: The woods repeat...", 30.0)
	d.p_node.position = Vector2(53.0 * 80.0, 13.0 * 80.0)
	d._cam_follow()
	d._bg_tick()
	await get_tree().create_timer(0.3).timeout
	await _shot(OUT + "06_dario_spikes.png")

	# the MOVER RIDE: level 3, Dario standing on the plank
	d._load_level(2)
	_unlock(d)
	if d.movers.size() > 0:
		var mn: Node2D = d.movers[0]["node"]
		d.p_node.position = Vector2(mn.position.x,
				mn.position.y - 9.0 - float(d.p_size.y) / 2.0)
		d._bubble_say("DARIO: These floating stones... nothing here obeys.", 30.0)
	d._cam_follow()
	d._bg_tick()
	await get_tree().create_timer(0.25).timeout
	await _shot(OUT + "07_dario_mover_ride.png")

	# THE RHINO + THE BAT: level 4, the windup flash + the hunt
	d._load_level(3)
	_unlock(d)
	d._spawn_enemy("blocker", Vector2i(20, 12))
	var rh: Dictionary = d.enemies[d.enemies.size() - 1]
	var rn: Node2D = rh["node"]
	rn.position.y = 14.0 * 80.0 - float(rh["h"]) / 2.0 - 2.0
	d._spawn_enemy("fly", Vector2i(17, 5))
	d.p_node.position = rn.position + Vector2(230.0, 0.0)
	# force the windup for the shot
	rh["state"] = "windup"
	rh["st_t"] = 0.4
	for i in 10:
		d._enemies_tick(1.0 / 60.0)
	d._cam_follow()
	d._bg_tick()
	await get_tree().create_timer(0.2).timeout
	await _shot(OUT + "08_dario_rhino_windup.png")

	# THE SMOOTH DEATH + THE QUOTE: die and catch the bubble
	d._lvl_score0 = 150
	d.set_score(150)
	d._die()
	await get_tree().create_timer(1.25).timeout
	await _shot(OUT + "09_dario_death_quote.png")

	# the NIGHT ARENA: the tall ghost ladder + the Witcher at her cell
	Box.equip_item("dario", "theme", "night")
	d._apply_theme()
	d.level_i = 9
	d._load_level(9)
	_unlock(d)
	d._start_boss(Vector2i(24, 4))
	d.p_node.position = Vector2(12.0 * 80.0, 12.5 * 80.0)
	await get_tree().create_timer(0.9).timeout
	d._cam_follow()
	d._bg_tick()
	await _shot(OUT + "10_dario_arena_night.png")
	print("[qa] done")
	get_tree().quit(0)

func _ready() -> void:
	_run.call_deferred()
