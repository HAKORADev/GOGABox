extends SceneTree
## Rasterize icon.svg -> launcher icon PNGs for the export presets.
## Run after `godot --headless --import`:
##   godot --headless --script res://tools/rasterize_icons.gd

func _initialize() -> void:
	var tex: Texture2D = load("res://icon.svg")
	if tex == null:
		push_error("icon.svg not importable")
		quit(1)
		return
	var img: Image = tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute("res://icons")

	# main launcher icon 192x192
	var main := img.duplicate()
	main.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	main.save_png("res://icons/main_192x192.png")

	# adaptive foreground 432x432: blob at ~66% safe zone, transparent padding
	var fg := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	fg.fill(Color(0, 0, 0, 0))
	var inner := img.duplicate()
	inner.resize(285, 285, Image.INTERPOLATE_LANCZOS)
	fg.blend_rect(inner, Rect2i(0, 0, 285, 285), Vector2i((432 - 285) / 2, (432 - 285) / 2))
	fg.save_png("res://icons/adaptive_foreground_432x432.png")

	# adaptive background 432x432: solid navy
	var bg := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	bg.fill(Color("1b2a4a"))
	bg.save_png("res://icons/adaptive_background_432x432.png")

	print("icons written to res://icons/")
	quit(0)
