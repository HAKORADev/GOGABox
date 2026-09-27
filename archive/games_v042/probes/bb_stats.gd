extends Node
## bb_stats - the static level ladder's numbers (no shop): cols x rows,
## wall frac, bricks, hits, the fair bank, the brick px - the fit's data.

func _ready() -> void:
        var BB: GDScript = load("res://game/games/brickbreaker/brickbreaker.gd")
        var rng := RandomNumberGenerator.new()
        print("lv | cols x rows | wall | bricks | hits | bank | bw")
        for lv in range(1, 41, 2):
                rng.seed = 31337 + lv
                var ld: Dictionary = BB.gen_level(lv, rng)
                var wall: float = float(ld["wall"])
                var full_w := 1852.0
                var aw := full_w * wall
                var bw := aw / float(ld["cols"])
                var bank: float = BB.timer_for(int(ld["breakable"]),
                                int(ld["hits"]), aw, 800.0, 560.0, lv, false)
                print("L%-2d | %2dx%-2d | %.2f | %4d | %4d | %4.0fs | %.0fpx"
                                % [lv, ld["cols"], ld["rows"], wall,
                                ld["breakable"], ld["hits"], bank, bw])
        get_tree().quit(0)
