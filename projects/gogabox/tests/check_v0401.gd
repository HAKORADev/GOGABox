# Check-only runner: loads the patched scripts with full project context
# and reports parse errors (the CI's godot does the real build later).
extends SceneTree

func _init() -> void:
	var targets := [
		"res://game/games/snl/snl.gd",
		"res://game/core/registry.gd",
		"res://game/core/roadmap.gd",
		"res://game/games/heavywar/heavywar.gd",
		"res://game/games/heavywar/heavywar_data.gd",
		"res://game/games/heavywar/heavywar_meta.gd",
	]
	var bad := 0
	for t in targets:
		var s: Script = load(t)
		if s == null:
			print("FAIL load: ", t)
			bad += 1
		elif not s.can_instantiate() and s.get_instance_base_type() == "":
			print("FAIL instantiate: ", t)
			bad += 1
		else:
			print("OK: ", t)
	print("CHECKED ", targets.size(), " bad=", bad)
	quit(1 if bad > 0 else 0)
