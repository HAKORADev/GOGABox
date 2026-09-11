extends Node
## /tmp probe: measure CPU wr/lr vs random for both games (seeded).

func _ready() -> void:
        var rng := RandomNumberGenerator.new()
        var FL: GDScript = load("res://game/games/fourline/fourline.gd")
        var BVO: GDScript = load("res://game/games/bovo/bovo.gd")
        # --- fourline
        for seed_v in [39, 40, 41]:
                rng.seed = seed_v
                var wins := 0
                var losses := 0
                var draws := 0
                var games := 200
                for g in games:
                        var bb := []
                        for i in 56:
                                bb.append(0)
                        var pr: String = FL.PROFILES.keys()[g % FL.PROFILES.size()]
                        var mover := 1 if g % 2 == 0 else 2
                        var res := 0
                        for step in 56:
                                var w0: int = FL.winner_of(bb)
                                if w0 != 0:
                                        res = w0
                                        break
                                if mover == 1:
                                        var opts := []
                                        for c in FL.COLS:
                                                if FL.drop_row(bb, c) >= 0:
                                                        opts.append(c)
                                        if opts.is_empty():
                                                res = 3
                                                break
                                        var c1: int = opts[rng.randi() % opts.size()]
                                        bb[FL.idx(c1, FL.drop_row(bb, c1))] = 1
                                else:
                                        var mv: int = FL.cpu_pick(bb, pr, [], rng)
                                        if mv < 0:
                                                res = 3
                                                break
                                        bb[FL.idx(mv, FL.drop_row(bb, mv))] = 2
                                var w: int = FL.winner_of(bb)
                                if w != 0:
                                        res = w
                                        break
                                mover = 2 if mover == 1 else 1
                        if res == 2:
                                wins += 1
                        elif res == 1:
                                losses += 1
                        else:
                                draws += 1
                print("FL seed=%d wr=%.3f lr=%.3f dr=%.3f" % [seed_v,
                                float(wins) / games, float(losses) / games,
                                float(draws) / games])
        # --- bovo
        var n := 8
        for seed_v in [39, 40, 41]:
                rng.seed = seed_v
                var wins := 0
                var losses := 0
                var draws := 0
                var games := 120
                for g in games:
                        var bb := []
                        for i in n * n:
                                bb.append(0)
                        var pr: String = BVO.PROFILES.keys()[g % BVO.PROFILES.size()]
                        var mover := 1 if g % 2 == 0 else 2
                        var res := 0
                        for step in n * n:
                                var w0: int = BVO.winner_of(bb, n)
                                if w0 != 0:
                                        res = w0
                                        break
                                if mover == 1:
                                        var empties := []
                                        for i in n * n:
                                                if int(bb[i]) == 0:
                                                        empties.append(i)
                                        if empties.is_empty():
                                                res = 3
                                                break
                                        bb[empties[rng.randi() % empties.size()]] = 1
                                else:
                                        var mv: int = BVO.cpu_pick(bb, n, pr, [], rng)
                                        if mv < 0:
                                                res = 3
                                                break
                                        bb[mv] = 2
                                var w: int = BVO.winner_of(bb, n)
                                if w != 0:
                                        res = w
                                        break
                                mover = 2 if mover == 1 else 1
                        if res == 2:
                                wins += 1
                        elif res == 1:
                                losses += 1
                        else:
                                draws += 1
                print("BV seed=%d wr=%.3f lr=%.3f dr=%.3f" % [seed_v,
                                float(wins) / games, float(losses) / games,
                                float(draws) / games])
        get_tree().quit(0)
