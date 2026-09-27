extends SceneTree
func _init() -> void:
        var G: GDScript = load("res://game/core/goga_core.gd")
        var goga: Node = G.new()
        root.add_child(goga)
        goga.set_home("user://probe_rig_home")
        var repo_root := ProjectSettings.globalize_path("res://").path_join("../..")
        for pkg in ["gogabox_github-HAKORADev_hakora.rally.001_official",
                        "gogabox_github-HAKORADev_hakora.slasher.002_official",
                        "gogabox_github-HAKORADev_hakora.domino.003_official",
                        "gogabox_github-HAKORADev_hakora.jumpcube.004_official"]:
                var src: String = repo_root.path_join("GOGAs/games").path_join(pkg)
                var v: Dictionary = goga.validate_root(src)
                print(pkg.get_file().substr(30), " valid=", v["ok"], " ", v["errors"] if not v["ok"] else "")
        quit(0)
