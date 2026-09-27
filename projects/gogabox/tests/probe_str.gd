extends Node
func _ready() -> void:
        var e := GameReg.get_game("rally")
        print("entry age type: ", typeof(e.get("age")), " value: ", e.get("age"))
        var id_v: Variant = e["id"]
        print("id type: ", typeof(id_v))
        # probe each suspicious call
        print("str(age) = ", str(e.get("age", 3)))
        var s1: String = str(e.get("age", 3))
        print("Roadmap.state(String(id))...")
        var st := Roadmap.state(String(e["id"]))
        print("state=", st)
        print("normalize...")
        var mains := (e.get("genres", {}).get("main", []) as Array).map(func(t): return Meta.normalize_tag(String(t)))
        print("mains=", mains)
        get_tree().quit(0)
