extends Object
## BOARD LUDO auto-pilot for the thumbnail capture (attract mode).
## v0.3.9-13: the drive picks the mode (the v0.3.9-13 flow law), taps the
## gate, then rolls and plays the first legal move for the user - the rig
## walks the real round: the hop walk, the arrows, the landings, the
## tactical rivals thinking in their trays.

var game: GogaGame

func segments() -> Array:
        return []

func tick(t: float) -> void:
        if game == null or not is_instance_valid(game):
                return
        # the ask: seat the 1v1 table once
        if String(game.state) == "ready":
                game._pick_mode(1)
                return
        # the gate: tap anywhere
        if String(game.state) == "gate":
                game._gate_down()
                game._new_round()
                return
        # live play: roll, then take the first legal move
        if String(game.state) == "roll_wait" \
                        and game._is_user_army(int(game.turn_army)):
                game.probe_roll()
        elif String(game.state) == "picking" \
                        and game._is_user_army(int(game.turn_army)):
                if not game.legal.is_empty():
                        var m: Dictionary = game.legal[0]
                        game._start_move(int(m["piece"]), int(m["np"]))
