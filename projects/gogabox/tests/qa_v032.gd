extends Node
## qa_v032 - the visual QA for SPACE INVADERS: the ready card, the Neptune
## formation fight, the thunder beam, the RING DUKE boss, the defender wing,
## the breach dialogue and the Hideout finale sky.
##   DISPLAY=:99 godot --path . res://tests/qa_v032.tscn

const OUT := "/home/z/my-project/download/qa_v032/"

func _shot(path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	print("[qa] ", path)

var G: GogaGame

func _boot_game() -> void:
	G = load("res://game/games/invaders/invaders.gd").new()
	G.game_id = "invaders"
	add_child(G)
	await get_tree().create_timer(0.5).timeout

func _kill_game() -> void:
	if G != null and is_instance_valid(G):
		G.queue_free()
	G = null
	await get_tree().create_timer(0.4).timeout

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	Box.reset_all()
	Box.dev_set_cheat("all_owned", 1)
	get_window().size = Vector2i(1706, 960)
	await get_tree().create_timer(0.3).timeout

	# 1 - the ready card
	await _boot_game()
	await _shot(OUT + "01_ready_card.png")

	# 2 - the Neptune formation fight
	G._press(Vector2(400, 800), 0)
	await get_tree().create_timer(0.3).timeout
	G._dialog_dismiss()
	await get_tree().create_timer(0.3).timeout
	G._dialog_dismiss()
	await get_tree().create_timer(2.2).timeout
	G.firing = true
	await get_tree().create_timer(1.2).timeout
	await _shot(OUT + "02_neptune_fight.png")

	# 3 - the thunder beam chain
	G.firing = false
	G.weapon = "thunder"
	G.fire_cd = 0.0
	G._cast_thunder()
	await get_tree().create_timer(0.25).timeout
	await _shot(OUT + "03_thunder_beam.png")

	# 4 - the defender wing (ember flying beside azure)
	Box.earn(5000)
	G._defender_call("ember")
	G.firing = true
	await get_tree().create_timer(1.0).timeout
	await _shot(OUT + "04_defender_wing.png")
	G.firing = false

	# 5 - the RING DUKE boss fight
	G._dialog_dismiss()
	await get_tree().create_timer(0.2).timeout
	G.stage = 2
	G.wave = 10
	G._start_boss_wave()
	G._dialog_dismiss()
	await get_tree().create_timer(2.6).timeout
	G._dialog_dismiss()
	await get_tree().create_timer(2.0).timeout
	await _shot(OUT + "05_boss_duke.png")

	# 6 - the breach dialogue
	if not G.boss.is_empty() and is_instance_valid(G.boss.get("node")):
		G.boss["hp"] = 1
		G._hit_boss(99, G.boss["node"].position)
	await get_tree().create_timer(0.6).timeout
	var diver := Sprite2D.new()
	G._summon_kind("diver", Vector2(200, 200))
	await get_tree().create_timer(0.3).timeout
	await _shot(OUT + "06_boss_down.png")

	# 7 - the hideout finale sky (the themes pack on)
	G.queue_free()
	G = null
	await get_tree().create_timer(0.4).timeout
	Box.buy_item("invaders", "theme", "pack", 0)
	await _boot_game()
	G.themes_on = true
	G._apply_stage_sky(9, true)
	G._press(Vector2(400, 800), 0)
	await get_tree().create_timer(0.3).timeout
	G._dialog_dismiss()
	await get_tree().create_timer(0.3).timeout
	G._dialog_dismiss()
	await get_tree().create_timer(1.6).timeout
	await _shot(OUT + "07_hideout_sky.png")

	print("[qa] done")
	get_tree().quit(0)

func _ready() -> void:
	print("=== qa_v032: SPACE INVADERS ===")
	_run()
