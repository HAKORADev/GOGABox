extends Node
func _ready() -> void:
        var BVO: GDScript = load("res://game/games/bovo/bovo.gd")
        var n := 8
        var b2 := []
        for i in n * n:
                b2.append(0)
        for j in 4:
                b2[BVO.idx(1 + j, 1, n)] = 2
        var rng := RandomNumberGenerator.new()
        rng.seed = 99
        var misses := 0
        for t in 40:
                if rng.randf() < 0.09:
                        misses += 1
        print("raw misses out of 40: ", misses)
        var rng2 := RandomNumberGenerator.new()
        rng2.seed = 99
        var miss2 := 0
        for t in 40:
                var mv: int = BVO.cpu_pick(b2, n, "wall", [], rng2)
                if mv != 1 and mv != 41:
                        miss2 += 1
        print("behavior misses out of 40: ", miss2)
        var wall: Dictionary = BVO.PROFILES["wall"]
        print("wall miss_win = ", wall["miss_win"])
        get_tree().quit(0)
