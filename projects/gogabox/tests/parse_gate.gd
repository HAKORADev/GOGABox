extends Node

## v043 parse gate - compiles EVERY .gd in the project IN GAME CONTEXT
## (a scene boot: autoloads present, class_name registry alive - the same
## compile world the shipped binary lives in). A --script/SceneTree run
## CANNOT do this job: autoload singletons do not exist there, so every
## script that names Box/GOGA/LAN reads as "identifier not found" - a
## false alarm that masked the real goga_update.gd inference break.
##
## The gate's own boot is already the first check: reaching _ready means
## main.gd + the menu chain + every autoload compiled clean.
## Exit 0 = all green. Run: godot --headless --path . res://tests/parse_gate.tscn

func _ready() -> void:
        var bad: Array = []
        var count := 0
        for path in _gd_files("res://game") + _gd_files("res://addons") \
                        + _gd_files("res://tests"):
                count += 1
                var s: Script = load(path)
                if s == null:
                        bad.append(path + " (load failed)")
                        continue
                if s is GDScript and not (s as GDScript).can_instantiate():
                        bad.append(path + " (compile failed)")
        print("PARSEGATE: %d scripts checked (game context, autoloads live)" % count)
        if bad.is_empty():
                print("PARSEGATE: ALL CLEAN")
                get_tree().quit(0)
        else:
                for b in bad:
                        print("PARSEGATE FAIL: " + b)
                get_tree().quit(1)

func _gd_files(dir_path: String) -> PackedStringArray:
        var out := PackedStringArray()
        var da := DirAccess.open(dir_path)
        if da == null:
                return out
        da.list_dir_begin()
        var name := da.get_next()
        while name != "":
                var full := dir_path + "/" + name
                if da.current_is_dir() and not name.begins_with("."):
                        out.append_array(_gd_files(full))
                elif name.ends_with(".gd"):
                        out.append(full)
                name = da.get_next()
        da.list_dir_end()
        return out
