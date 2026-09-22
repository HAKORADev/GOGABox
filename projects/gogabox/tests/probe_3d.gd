extends Node
## v041-2 feasibility probe (NOT shipped): verify the 3D integration facts
## on the exact rig the box ships on (gl_compatibility + llvmpipe under Xvfb):
##   F1 a Node3D world can live under a Node2D parent (the host_node shape)
##   F2 Camera3D + meshes + DirectionalLight3D shadows actually render
##   F3 a 2D CanvasLayer HUD paints ON TOP of the 3D world
## Run: xvfb-run -a godot --path . res://tests/probe_3d.tscn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# --- the host shape: Node2D parent
	var host := Node2D.new()
	add_child(host)
	# --- the 3D world as a child of the Node2D host
	var world := Node3D.new()
	host.add_child(world)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 6, 10)
	cam.rotation_degrees = Vector3(-30, 0, 0)
	world.add_child(cam)
	cam.current = true
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.5, 0.7, 0.9)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.8)
	e.ambient_light_energy = 0.6
	env.environment = e
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	world.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor_mesh.mesh = plane
	world.add_child(floor_mesh)
	var ball := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	ball.mesh = sph
	ball.position = Vector3(0, 1.6, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.3, 0.2)
	mat.roughness = 0.4
	ball.material_override = mat
	world.add_child(ball)
	# box so the shadow lands on the floor
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3, 2, 3)
	box.mesh = bm
	box.position = Vector3(4, 1, -2)
	world.add_child(box)
	# --- the HUD CanvasLayer over the 3D
	var hud := CanvasLayer.new()
	hud.layer = 10
	var lbl := Label.new()
	lbl.text = "HUD OVER 3D"
	lbl.position = Vector2(40, 40)
	lbl.add_theme_font_size_override("font_size", 48)
	lbl.add_theme_color_override("font_color", Color.YELLOW)
	hud.add_child(lbl)
	add_child(hud)
	await _shoot(ball)
	print("[probe_3d] done")
	get_tree().quit(0)

func _shoot(ball: Node3D) -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/probe_3d")
	for i in 8:
		await get_tree().process_frame
		ball.rotate_y(0.1)
		if i == 6:
			var img := get_viewport().get_texture().get_image()
			img.save_png("/tmp/probe_3d/f1_world.png")
			print("[probe_3d] f1 world shot size=", img.get_size())
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/probe_3d/f2_last.png")
