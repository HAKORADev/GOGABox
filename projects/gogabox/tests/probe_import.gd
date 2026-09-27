extends SceneTree

func _init() -> void:
        var lab := "user://probe_lab2"
        _wipe(lab)
        var G: GDScript = load("res://game/core/goga_core.gd")
        var goga: Node = G.new()
        root.add_child(goga)
        goga.set_home(lab.path_join("home"))
        var pkg_a := lab.path_join("pkg_a")
        var pkg_b := lab.path_join("pkg_b")
        _build(pkg_a, "gogabox_github-TESTER_test.good.001_official", "goodgame", "1.0.0")
        _build(pkg_b, "gogabox_github-TESTER_test.second.001_official", "secondgame", "2.0.0")
        var r1: Dictionary = goga.import_path(pkg_a)
        print("r1: ", JSON.stringify(r1))
        var parent := lab.path_join("many")
        DirAccess.make_dir_recursive_absolute(parent)
        _copy_tree(pkg_a, parent.path_join("whatever_folder_name"))
        _copy_tree(pkg_b, parent.path_join("another_name"))
        print("root check w: ", FileAccess.file_exists(parent.path_join("whatever_folder_name/index/index.json")))
        print("root check a: ", FileAccess.file_exists(parent.path_join("another_name/index/index.json")))
        var roots: Array = goga._roots_under(parent)
        print("roots under parent: ", roots)
        var r2: Dictionary = goga.import_path(parent)
        print("r2: ", JSON.stringify(r2))
        _wipe(lab)
        quit(0)

func _build(root: String, pkg_id: String, game_id: String, version: String) -> void:
        for d in ["index", "game", "discover", "save",
                        "game/pc", "game/android", "discover/media",
                        "data/logic", "data/audio/sfx", "data/audio/music",
                        "data/visuals/shaders", "data/visuals/assets"]:
                DirAccess.make_dir_recursive_absolute(root.path_join(d))
        var index := {"schema": 1, "id": pkg_id, "game_id": game_id,
                "title": "GOOD GAME", "version": version, "age": 3,
                "content": [], "genres": {"main": ["arcade"], "sub": []},
                "os": ["android", "pc"],
                "runs": {"pc": {"kind": "godot_embedded", "pck": "game/pc/goga.pck",
                        "script": "res://game/games/%s/%s.gd" % [game_id, game_id]}},
                "thumb": "discover/media/thumb.png",
                "fee": 0, "price": 0, "coin_div": 10}
        var f := FileAccess.open(root.path_join("index/index.json"), FileAccess.WRITE)
        f.store_string(JSON.stringify(index))
        f.close()
        for p in ["game/pc/goga.pck", "game/android/goga.pck", "discover/page.json",
                        "discover/media/thumb.png", "data/logic/tuning.json",
                        "data/audio/sfx/click.ogg", "data/audio/music/loop.ogg",
                        "data/visuals/shaders/tint.gdshader", "data/visuals/assets/board.png"]:
                var fw := FileAccess.open(root.path_join(p), FileAccess.WRITE)
                fw.store_string("x")
                fw.close()

func _copy_tree(src: String, dst: String) -> void:
        DirAccess.make_dir_recursive_absolute(dst)
        var da := DirAccess.open(src)
        if da == null:
                print("COPY: cannot open src ", src)
                return
        da.list_dir_begin()
        var n := da.get_next()
        while n != "":
                var s := src.path_join(n)
                var d := dst.path_join(n)
                if da.current_is_dir():
                        _copy_tree(s, d)
                else:
                        var err := da.copy(s, d)
                        if err != OK:
                                print("COPY FAIL %s -> %s err %d" % [s, d, err])
                n = da.get_next()
        da.list_dir_end()

func _wipe(path: String) -> void:
        if DirAccess.dir_exists_absolute(path):
                var da := DirAccess.open(path)
                if da != null:
                        da.list_dir_begin()
                        var n := da.get_next()
                        while n != "":
                                var full := path.path_join(n)
                                if da.current_is_dir():
                                        _wipe(full)
                                else:
                                        da.remove(n)
                                n = da.get_next()
                        da.list_dir_end()
                DirAccess.remove_absolute(path)
