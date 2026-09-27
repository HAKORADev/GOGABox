extends SceneTree
## v043 parse gate: compile EVERY .gd in the project in project context
## (autoloads present) and report failures. Exit 0 = all green.

func _init() -> void:
        var bad: Array = []
        var count := 0
        for path in _gd_files("res://game"):
                count += 1
                var s: Script = load(path)
                if s == null:
                        bad.append(path + " (load failed)")
                        continue
                if not s.can_instantiate() and not s is GDScript:
                        continue
                # a reload forces a full compile; reloadable() filters tools
                if s is GDScript and (s as GDScript).reloadable():
                        var err := (s as GDScript).reload()
                        if err != OK:
                                bad.append(path + " (reload err %d)" % err)
        for path in _gd_files("res://tests"):
                count += 1
                var s2: Script = load(path)
                if s2 == null:
                        bad.append(path + " (load failed)")
        print("PARSEGATE: %d scripts checked" % count)
        if bad.is_empty():
                print("PARSEGATE: ALL CLEAN")
                quit(0)
        else:
                for b in bad:
                        print("PARSEGATE FAIL: " + b)
                quit(1)

func _gd_files(dir_path: String) -> PackedStringArray:
        var out: PackedStringArray = []
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
