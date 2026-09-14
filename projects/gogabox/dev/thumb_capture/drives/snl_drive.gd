extends Object
## SNAKES & LADDERS auto-pilot for the thumbnail capture (attract mode).
## v0.3.9-13: the drive picks the mode (the v0.3.9-13 flow law: the ask
## opens the game), taps the gate, then rolls for the user whenever the
## waiting die seats itself - the rig plays the REAL round: the walks,
## the ladder rides, the snake falls, the wide badges breathing.

var game: GogaGame

func segments() -> Array:
        return []

func tick(t: float) -> void:
        if game == null or not is_instance_valid(game):
                return
        # the ask: seat the 2-player table once
        if String(game.state) == "ready":
                game._pick_mode(2)
                return
        # the gate: tap anywhere
        if String(game.state) == "gate":
                game._gate_down()
                game._new_round()
                return
        # live play: roll for the user whenever the die waits
        if String(game.state) == "roll_wait" and int(game.turn) == 1:
                game.probe_roll()
