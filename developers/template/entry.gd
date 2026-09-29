extends GameBase
## TEMPLATE - "Pop the Dots", the smallest complete GOGABox game.
##
## Copy this folder, rename it, make it yours, then build the pack:
##
##     python3 tools/make_game.py developers/template my_first_game
##
## Start GOGABox - the game is in the feed. Read developers/GAMES.md for
## the full folder + game.json contract, GOGACOINS.md for the economy
## doors, LAN.md for local multiplayer.
##
## The three overrides below are the whole GameBase contract:
##   _goga_setup  build your world (runs once, the entry fee is already taken)
##   _goga_tick   per-frame logic
##   _goga_input  raw input events (AFTER TouchKit has seen them)
## GameBase already gave you: the HUD (score + coins), the pause sheet,
## the game-over sheet, the scale rule, the touch kit (tk).

const ROUND_SECONDS := 30.0
const DOT_LIFE := 2.2          # seconds a dot stays alive

var _time_left := ROUND_SECONDS
var _clock: Label
var _dots: Array = []          # [{pos: Vector2, r: float, born: float}]
var _world: Control

func _goga_setup() -> void:
        # The canvas is the box's own design space - read it LIVE so any
        # phone aspect works (the scale rule grows the canvas, never distorts).
        var vp := get_viewport_rect().size
        _world = Control.new()
        _world.position = Vector2.ZERO
        _world.size = vp
        _world.draw.connect(_paint)
        add_child(_world)

        _clock = Label.new()
        _clock.position = Vector2(24, 120)
        _clock.add_theme_font_size_override("font_size", 40)
        _world.add_child(_clock)

        # taps land here - one signal, both platforms (mouse included)
        tk.tapped.connect(_on_tap)
        _spawn_dot()

func _goga_tick(delta: float) -> void:
        _time_left -= delta
        _clock.text = "%ds  -  pop the dots!" % int(maxf(0.0, _time_left))
        if _time_left <= 0.0:
                # THE one exit: finish_run banks score + coins into the box
                # (best/last/plays, the game-over sheet, everything).
                finish_run(score)
                return
        var now := Time.get_ticks_msec() / 1000.0
        var alive := false
        for d in _dots:
                if now - float(d["born"]) < DOT_LIFE:
                        alive = true
        if not alive:
                _spawn_dot()   # exactly one dot waits on screen, always
        _world.queue_redraw()

func _on_tap(pos: Vector2) -> void:
        for d in _dots:
                if pos.distance_to(d["pos"]) <= float(d["r"]):
                        _dots.erase(d)
                        add_score(1)
                        # an in-world GOGACoin every 5th dot (add_run_coins
                        # IS the box wallet - it pays out at finish_run)
                        if score % 5 == 0:
                                add_run_coins(1)
                        _spawn_dot()
                        return
        # a miss costs 3 seconds - misses have a price, like any arcade
        _time_left = maxf(1.0, _time_left - 3.0)

func _spawn_dot() -> void:
        var vp := get_viewport_rect().size
        _dots.append({
                "pos": Vector2(randf_range(90, vp.x - 90),
                                randf_range(220, vp.y - 90)),
                "r": randf_range(34, 58),
                "born": Time.get_ticks_msec() / 1000.0,
        })
        _world.queue_redraw()

## The world paints itself - no sprite sheet needed for a game like this.
func _paint() -> void:
        var now := Time.get_ticks_msec() / 1000.0
        for d in _dots:
                var age := now - float(d["born"])
                var t := clampf(age / DOT_LIFE, 0.0, 1.0)
                var col := Color(0.98, 0.62, 0.1).lerp(Color(0.55, 0.2, 0.1), t)
                _world.draw_circle(d["pos"], float(d["r"]) * (1.0 - 0.25 * t), col)
                _world.draw_circle(d["pos"], float(d["r"]) * (1.0 - 0.25 * t),
                                col.darkened(0.2), false, 3.0)
