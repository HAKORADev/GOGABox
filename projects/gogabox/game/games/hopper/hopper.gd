extends GogaGame
## SNOWY TOWER (v0.2.6) - the tap-hop doodle clone grew up into a REAL
## climber. Built from the owner's GDD + the PGB v1.3.8 reference
## (Python_Game_Box_PGB/src/python/v1.3.8/snowy_tower.py). The journal is
## docs/goga_docs/gogames_ideas/tower.md.
##
## Owner contract:
##   - the PGB platform types live again: static / moving / blinking /
##     disappearing / moving_blinking + THE RELIABILITY LAW (an unreliable
##     platform is always followed by a reliable one) + the start platform
##   - TWO WALLS: platforms AND the player never leave the screen; the
##     walls are drawn, they bounce the player, they bound every patrol
##   - the slide-up law: the scroll wakes after 2 platforms and climbs
##     x1.1 for every 10 platforms (the PGB 1.1 ** (score // 10) law)
##   - score = PLATFORMS CLIMBED: landing on a higher platform than ever
##     pays exactly +1 (skip 3 and land the 4th = +1); landing on anything
##     at or below your best pays NOTHING
##   - PHYSICAL SNOW: flakes fall for real, LAND on platforms (the snow
##     cap grows) and ON THE PLAYER (you get slow and heavy) - rolling
##     sheds it; the owner's star mechanic, tuned hard
##   - v0.2.6 CONTROLS (the owner's own scheme): the LEFT half of the
##     screen is an ANALOG move zone - the first touch anchors, dragging
##     left/right of the anchor drives the speed AND the force (back to
##     the anchor = the dead point = stop; Y is ignored, tracked by touch
##     index); the RIGHT half is TAP TO JUMP (one tap one jump, the x2
##     mid-air tap). The old arrows + jump circle are GONE (their
##     _gui_input local-position math was the dead jump button).
##   - v0.2.6 MELTING (a shop item, toggle ON/OFF): the character consumes
##     the snow UNDER it over time and GROWS (max x1.5 - the owner: "not
##     too much"); moving fast consumes at a reduced rate (down to ~30%);
##     no snow under it and it SHRINKS until it dies. A real risk loop
##     against the slowly-filling snow caps.
##   - v0.2.6 POWERUP UI: a widget ON TOP (glyph + name + seconds + a
##     draining bar) - the life ring inside the jump button died with it.
##   - v0.2.6 CLEAN SKIES: the mountains/trees/aurora are gone; day is a
##     calm gradient + a SMALL corner sun + drifting clouds; night is a
##     deep gradient + a small crescent moon + star-like lights (shader
##     dust + glints) + drifting night sparks (particles).
##   - v0.2.7 THE VISIBILITY ROUND (the owner played it and the pickups were
##     GHOSTS): coins and powerup pickups were NEVER DRAWN - the arrays fed
##     collection logic only, so the owner "magically collected" invisible
##     coins. Both wear the snake law now (the REAL coin.png asset) with a
##     fade-in (the owner: "appear like the other games, but with fade
##     effect so it feels smooth"), a glow halo, and a bob.
##   - v0.2.7 POWERUP SPAWNS: next_pick_idx was born 0 and the old
##     `next_idx > 4` guard skipped the branch at idx 0..4, so the match
##     `next_idx == next_pick_idx` could NEVER fire again - not one powerup
##     could ever spawn in any run, ever. The owner's law now: one RANDOM
##     powerup every 20-40 platforms counted from the LAST SPAWNED
##     (on-screen) powerup, not the last collected.
##   - v0.2.7 BANNER: the v0.2.6 "no banner in the tower" law is REVERSED by
##     the owner - the tower wears the banner like every other game, and the
##     fall-death line insets above the strip.
##   - v0.2.7 THE EMPTY WIDGET: the melt chip sat between the speed chip and
##     the coins chip FOREVER EMPTY (it was built unconditionally). It hides
##     itself while MELTING is off; the powerup widget moved top-LEFT next
##     to the score (the owner: "make it to the left next to score").
##   - v0.2.7 THE BREAK: the vanish crack was three static lines. Now the
##     cracks are jagged, deterministic per platform, they LENGTHEN and
##     WIDEN with the grace clock, chips pop off while it cracks, and the
##     platform SHATTERS into physical chunks (gravity + spin + fade, sized
##     by the platform's own width).
##   - v0.2.7 BLINK SNOW: the cap stashes itself when the platform goes
##     invisible and comes back with it - snow appears and disappears WITH
##     the platform (the owner's own fix).
##   - v0.2.7 THE SHARD MATH FIX: the old settle target (+-1.094 rad) put a
##     SIDE ON TOP - the triangle "rested" balancing on one corner, hoisted
##     by the support law (the owner: "it's not landing on its sides"). The
##     true edge-down stance is +-(pi - phi), phi = atan2(edge_h, edge_w)
##     = 2.0471 rad; the tumble pivots over the ACTUAL lowest vertex.
##   - v0.2.7 TWO NEW PLATFORM KINDS (the owner's challenge picks):
##     SIZE platforms (30+) breathe wide<->small smoothly, and DROPPER
##     platforms (50+) drop out of the screen when you land on them, wait,
##     then rise back. The reliability law covers both (dropper is
##     unreliable; size is solid).
##   - v0.2.7 THE RAMP (owner: "after 25 platforms start making jumps wider
##     so there is real challenge and timing"): past platform 25 the gaps
##     ramp toward the character's REAL jump ceiling and the horizontal
##     spread widens under a descending-branch reach law (the time a rising
##     jump crosses a higher platform on the way DOWN).
##   - GOGACoins hang in the air: one every 5-25 platforms counted from
##     the last coin ON SCREEN (not the last collected - coins can fall
##     off the bottom for real here); the FIRST coin waits 5-25 platforms
##     up - the start platform never spawns a coin and never pays score
##     (the owner's phantom-coin + start-score catches).
##   - run-end bonus = score/10 (registry coin_div)
##   - shop: 4 powerups that SPAWN in runs (x2 double jump / big jump /
##     speed / -50% slow slide - 10s each), 4 characters (ball/square/
##     triangle/egg - each its own physics + REAL tumbling: a side FALLS
##     and the face slaps down), 4 platform skins (sand free +
##     rock/grass/metal - shader-cut materials), 2 places (day + NIGHT)
##     and MELTING.
##   - NO random colors (the owner's v1.3.8 lesson): one designed palette,
##     every decoration deterministic per platform index
##   - everything drawn in code (no vendored sprites needed); tested
##     visually via Xvfb before shipping (the owner's rule)
##
## Probe contract: phase/score/platforms/pw/flakes state is public,
## rng.seed is settable, _set_move/_set_axis/_do_jump drive the controls
## directly, char_size is probeable for the MELTING laws.

const DIR := "res://assets/games/hopper/"

# ---------------- layout + physics (all scaled by U = width/720) ----------
const WALL_W := 34.0                 # the two walls' thickness
const PLAYER_R := 30.0               # the ball's radius
const GRAV := 2500.0
const JUMP_V := -1080.0
const WALK_MAX := 360.0              # max horizontal speed
const ACCEL := 2200.0                # ground acceleration
const AIR_ACCEL := 1350.0
const GROUND_FRICTION := 2600.0      # decel with no input
const AIR_DRAG := 260.0
const WALL_BOUNCE := 0.45            # vx keeps 45% reversed into the wall

# ---------------- the owner's zone controls (v0.2.6) ----------------------
const AXIS_DEAD := 12.0              # px (x U) - the dead point at the anchor
const AXIS_FULL := 110.0             # px (x U) - full deflection = full force

# ---------------- REAL TUMBLING (v0.2.6: a side FALLS, no look-snaps) -----
## v0.2.7 THE SHARD MATH FIX: the shard's verts are (0,-1.06R),
## (+-0.95R, 0.78R) - each slanted side makes phi = atan2(1.84, 0.95) =
## 1.0945 rad with the horizontal. The OLD settle target was phi itself,
## which lays that side on TOP (the triangle balanced on a corner - the
## owner's "not landing on its sides"). Resting ON the side needs the side
## FLAT ON THE GROUND: rotation = +-(pi - phi) = +-2.0471 rad.
const SHARD_SETTLE_ANG := 2.0474022  # rad - the TRUE edge-down stance (pi - atan2(1.84,0.95), exact)
const SETTLE_RATE := 10.0            # the ease rate to the flat face (1/s)

# ---------------- the slide-up law ----------------------------------------
const SCROLL_BASE := 55.0            # px/s (x U) once it wakes
const SCROLL_WAKE_AT := 2            # platforms climbed before it wakes
const SCROLL_STEP := 10              # every 10 platforms...
const SCROLL_MULT := 1.1             # ...x1.1 (owner)
const SCROLL_CAP := 6.0              # never past x6 (playability)

# ---------------- platform generation -------------------------------------
const PLAT_H := 22.0
const GAP_MIN := 115.0
const GAP_MAX := 170.0
const W_MIN := 95.0
const W_MAX := 255.0
const START_W := 320.0               # the wide start platform (PGB law)

## PGB v1.3.8 TYPE WEIGHTS + THE RELIABILITY LAW: after an unreliable type
## the next platform is ALWAYS reliable. Weights shift with score (static
## decays) but the law never bends. v0.2.7: "size" (30+) is solid and joins
## the RELIABLE set; "dropper" (50+) betrays you when you land and is
## UNRELIABLE (the next platform is always safe).
const PTYPES := {"static": 40, "moving": 25, "blinking": 15, "vanish": 10, "mb": 10,
                "size": 11, "dropper": 9}
const RELIABLE := ["static", "moving", "size"]
const MOVE_SPD_MIN := 55.0
const MOVE_SPD_MAX := 115.0
const BLINK_PERIOD := 1.1            # s, visible<->ghost
const VANISH_GRACE := 0.55           # s standing on it before it drops
const VANISH_RESPAWN := 2.2          # s until it returns

# ---------------- v0.2.7 the two NEW kinds (the owner's challenge) --------
const SIZE_AT := 30                  # size platforms join at platform 30
const SIZE_MIN_F := 0.55             # the width breathes 0.55x .. 1.30x
const SIZE_MAX_F := 1.30
const SIZE_PERIOD := 3.4             # s per full wide<->small cycle
const DROP_AT := 50                  # dropper platforms join at platform 50
const DROP_ACCEL := 1500.0           # px/s^2 (x U) once triggered
const DROP_MAX := 920.0              # px/s (x U) terminal drop speed
const DROP_WAIT := 2.4               # s below the screen before it returns
const DROP_RISE := 300.0             # px/s (x U) return speed

# ---------------- v0.2.7 the difficulty ramp (owner: 25+) -----------------
const DIFF_AT := 25                  # past this platform the jumps widen
const DIFF_RAMP := 90                # ...reaching full hardness over 90 more
const GAP_HARD_MAX := 205.0          # the absolute ceiling (reach-checked)

# ---------------- scoring / coins / pickups --------------------------------
const COIN_GAP_MIN := 5              # owner: coins every 5-25 platforms...
const COIN_GAP_MAX := 25             # ...counted from the last coin ON SCREEN
## v0.2.7 THE OWNER'S PICKUP LAW: "spawn one random powerup between 20-40
## platforms based on last on-screen powerup (not based on collected)" -
## the counter runs from the last SPAWNED pickup (it may fall off the
## bottom uncollected), and the first one waits 20-40 platforms up.
const PICKUP_GAP_MIN := 20
const PICKUP_GAP_MAX := 40

# ---------------- the four powerups (10s each, owner spec) ----------------
const PW_TIME := 10.0
const POWERUPS := {
        "x2":    {"name": "Double Jump", "price": 250, "glyph": "x2",
                        "desc": "one extra jump in the air"},
        "big":   {"name": "Big Jump", "price": 250, "glyph": "^",
                        "desc": "jumps 28% higher"},
        "speed": {"name": "Speed Moves", "price": 300, "glyph": ">>",
                        "desc": "walk 50% faster"},
        "slow":  {"name": "Slow Slide", "price": 350, "glyph": "-50%",
                        "desc": "the tower slides 50% slower"},
}

# ---------------- MELTING (v0.2.6, the owner's upgrade) -------------------
## Toggle it ON: the character consumes the snow UNDER it and GROWS (max
## x1.5). No snow under it -> it shrinks until it dies. Moving fast
## consumes at a reduced rate (the owner: "the faster the move the higher
## the consumption time and lower the consumption rate" - ~30% at full
## speed).
const MELT := {"name": "Melting", "price": 500,
                "desc": "eat the snow under you to grow - no snow, you shrink"}
const MELT_BASE := 0.16              # snow/s consumed standing still
const MELT_SPEED_FLOOR := 0.30       # the consumption-rate floor at full speed
const MELT_GROW := 0.38              # size gained per snow point eaten
const MELT_MAX := 1.5                # the owner: x1.5, "not too much"
const MELT_MIN := 0.42               # below this the character is gone
const MELT_SHRINK := 0.045           # size/s lost with no snow under you

# ---------------- the four characters (physics per GDD) -------------------
## g/accel/fric/jump multiply the base physics; snow_in = how fast snow
## sticks; shed_roll = snow shed per second while rolling; shed_land =
## fraction of snow that pops off on a landing.
const CHARS := {
        "ball":   {"name": "Snowball", "price": 0, "g": 1.0, "accel": 1.0,
                        "fric": 1.0, "jump": 1.0, "snow_in": 1.0, "shed_roll": 1.0,
                        "shed_land": 0.35, "desc": "the classic roller"},
        "square": {"name": "Ice Cube", "price": 400, "g": 1.05, "accel": 0.82,
                        "fric": 1.6, "jump": 0.94, "snow_in": 1.15, "shed_roll": 0.35,
                        "shed_land": 0.6, "desc": "tumbles corner over corner"},
        "shard":  {"name": "Shard", "price": 600, "g": 0.82, "accel": 1.18,
                        "fric": 0.55, "jump": 1.06, "snow_in": 0.45, "shed_roll": 2.2,
                        "shed_land": 0.5, "desc": "glass-light, snow barely sticks"},
        "egg":    {"name": "Eggy", "price": 800, "g": 0.95, "accel": 0.9,
                        "fric": 0.3, "jump": 1.0, "snow_in": 1.5, "shed_roll": 0.6,
                        "shed_land": 0.25, "desc": "slides forever, snow loves it"},
}

# ---------------- platform skins (real materials, not color swaps) --------
const PLATS := {
        "sand":  {"name": "Sandy Ledge", "price": 0},
        "rock":  {"name": "Rock Ledge", "price": 300},
        "grass": {"name": "Grass Ledge", "price": 300},
        "metal": {"name": "Steel Ledge", "price": 450},
}

# ---------------- places (day/night really feel different) ----------------
const PLACES := {
        "day":   {"name": "Morning Slope", "price": 0},
        "night": {"name": "Night Slope", "price": 400},
}

# ---------------- THE DESIGNED PALETTE (owner: no random colors) ----------
const PAL := {
        "day": {
                "top": Color("6fb9e8"), "hor": Color("e3f2fb"),
                "orb": Color("fff3c8"), "mountain": Color("b7d3e8"),
                "mountain2": Color("9dbfdf"), "tree": Color("7fa8b8"),
                "cloud": Color(1, 1, 1, 0.85), "wall": Color("7d9fbe"),
                "wall_hi": Color("e8f4fb"), "modulate": Color(1, 1, 1),
                "snow": Color(1, 1, 1, 0.95),
        },
        "night": {
                "top": Color("0a1a38"), "hor": Color("1d3a66"),
                "orb": Color("f2eed8"), "mountain": Color("1d3050"),
                "mountain2": Color("16283f"), "tree": Color("14283a"),
                "cloud": Color(0.75, 0.82, 1.0, 0.20), "wall": Color("16263c"),
                "wall_hi": Color("35507a"), "modulate": Color(0.78, 0.84, 1.0),
                "snow": Color(0.88, 0.94, 1.0, 0.95),
        },
}

# ---------------- state ----------------------------------------------------
var phase := "ready"                 # ready | run | over
var world: Node2D
var sky: ColorRect
var fx: Node2D                       # the VFX painter
var snow_layer: Node2D               # the falling-snow painter
var cloud_layer: Node2D              # the drifting clouds (screen space)
var spark_layer: Node2D              # night sparks (screen space particles)
var walls_layer: Node2D              # the screen-frame walls
var clouds: Array = []               # drifting cloud puffs
var plat_layer: Node2D               # ALL platforms, one draw pass
var U := 1.0                         # resolution unit (vp.x / 720)
var cam_y := 0.0                     # world y of the screen top (<= 0 up)
var scroll_now := 0.0                # live slide speed (px/s)
var shake := 0.0

var player: Node2D                   # drawn by _draw_player
var px := 0.0
var py := 0.0                        # world coords (y grows DOWN)
var vx := 0.0
var vy := 0.0
var grounded := false
var ground_plat := {}                # the platform dict we stand on
var air_jumped := false              # used the x2 mid-air jump
var char_id := "ball"
var char_size := 1.0                 # the MELTING size (x0.42..x1.5)
var snow_load := 0.0                 # 0..1 - the snow the ball carries
var spin := 0.0                      # the rolling spin (radians)
var tumble_rot := 0.0                # the cube/shard tumble angle (rad)
var tumble_vel := 0.0                # its angular velocity (rad/s)
var settle_hit := false              # the face-down slap latch
var wobble_clock := 0.0

var platforms: Array = []            # dicts: see _spawn_platform
var next_idx := 0                    # next platform index to spawn
var highest_idx := -1                # the best platform ever landed on
var coins: Array = []                # {x, y, idx, t}
var next_coin_idx := 0               # spawn a coin on this platform index
var pickups: Array = []              # {x, y, idx, kind, t}
var next_pick_idx := 0
var pick_layer: Node2D               # coins + pickups PAINTED (v0.2.7)
var _coin_tex: Texture2D             # the REAL GOGACoin (the snake law)
var flakes: Array = []               # the physical snowfall
var pw := {"id": "", "t": 0.0}       # the live powerup (10s life)

var move_dir := 0.0                  # -1..1 ANALOG from the left zone (v0.2.6)
var move_touch := -1                 # the tracked move-zone touch index
var move_anchor := Vector2.ZERO      # where the move touch landed
var jump_touches := {}               # right-zone touch indices held this press
var mouse_move := false              # the mouse fallback drives the left zone
var hops := 0                        # NOTE: score lives in the base class
var wall_flash := {"l": 0.0, "r": 0.0}
var rng := RandomNumberGenerator.new()
var _speed_chip: Label               # the live slide-speed chip
var _pw_widget: Control = null       # the TOP powerup widget (v0.2.6)
var _pw_glyph: Label = null
var _pw_time_l: Label = null
var _pw_bar: ColorRect = null
var _pw_bar_w := 280.0
var _melt_chip: Label = null         # the live MELT size readout
var _place_mod: CanvasModulate = null  # THE one place modulate (the leak law)
var sparks: Array = []               # night sparks (the particle half)
var _shop_pair: Array = []           # THE PAIR LAW: the shop owns its pair
var _shop_from := "ready"
var _ready_card: Control = null
var _time := 0.0

# ============================================================ setup / build

func _goga_setup() -> void:
        rng.randomize()
        var vp := get_viewport_rect().size
        U = vp.x / 720.0
        char_id = _char_id()

        world = Node2D.new()
        add_child(world)

        # --- the sky (v0.2.6: ONE clean shader - gradient + small orb +
        # star lights; the mountains/trees/aurora are GONE) ---
        sky = ColorRect.new()
        sky.size = vp
        sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var mat := ShaderMaterial.new()
        mat.shader = load(DIR + "bg_sky.gdshader")
        _apply_place(mat)
        sky.material = mat
        sky.z_index = -30
        add_child(sky)   # SCREEN space: the sky never scrolls wholesale

        # --- the drifting clouds (screen space, weak world anchor) ---
        cloud_layer = Node2D.new()
        cloud_layer.z_index = -18
        cloud_layer.draw.connect(_draw_clouds)
        add_child(cloud_layer)
        # --- the night sparks (particles; the owner's star-like lights
        # also live as PARTICLES, not just shader math) ---
        spark_layer = Node2D.new()
        spark_layer.z_index = -17
        spark_layer.draw.connect(_draw_sparks)
        add_child(spark_layer)
        for i in 12:
                sparks.append({"x": rng.randf_range(0.08, 0.92), "y": rng.randf_range(0.06, 0.60),
                                "ph": rng.randf() * TAU, "spd": rng.randf_range(0.4, 1.1),
                                "r": rng.randf_range(1.2, 2.6) * U})
        # --- the two walls: a screen-space frame ABOVE the world ---
        walls_layer = Node2D.new()
        walls_layer.z_index = 9
        walls_layer.draw.connect(_draw_walls)
        add_child(walls_layer)

        # --- drifting cloud puffs (world-anchored, weak parallax) ---
        for i in 7:
                clouds.append({"x": rng.randf_range(0, vp.x), "y": rng.randf_range(-vp.y, vp.y),
                                "w": rng.randf_range(100, 210) * U, "spd": rng.randf_range(6, 20) * U,
                                "a": rng.randf_range(0.5, 1.0)})

        plat_layer = Node2D.new()
        plat_layer.z_index = -2
        plat_layer.draw.connect(_draw_platforms)
        world.add_child(plat_layer)

        # --- v0.2.7 the pickup PAINTER: coins + powerups were invisible
        # ghosts (collection logic only, no draw) - the owner played a run
        # and "magically collected" coins. They paint ABOVE the platforms
        # and UNDER the player now, coin.png + fade-in + bob.
        _coin_tex = load("res://assets/ui/coin.png")
        pick_layer = Node2D.new()
        pick_layer.z_index = 3
        pick_layer.draw.connect(_draw_pickups)
        world.add_child(pick_layer)

        # --- coins + pickups live in plain Node2D holders ---
        snow_layer = Node2D.new()
        snow_layer.z_index = 6
        snow_layer.draw.connect(_draw_snow)
        world.add_child(snow_layer)

        fx = Node2D.new()
        fx.z_index = 8
        fx.draw.connect(_draw_fx)
        world.add_child(fx)

        _build_player()
        _build_world_start()
        _build_pw_widget()
        add_hud_button("SHOP", func(): _shop_open())
        _speed_chip = add_hud_chip("x1.00")
        _melt_chip = add_hud_chip("")
        if _melt_chip != null:
                _melt_chip.text = ""
                # v0.2.7 THE EMPTY WIDGET FIX: the chip sat between the speed
                # chip and the coins chip FOREVER EMPTY. Its whole panel
                # hides while MELTING is off (a hidden child takes no slot).
                var mc_panel := _melt_chip.get_parent().get_parent() as Control
                if mc_panel != null:
                        mc_panel.visible = _melt_on()
        set_hud_score_prefix("TOWER")
        set_score(0)
        _day_night()
        Jukebox.music("res://assets/audio/music/tower_theme.wav")
        _show_ready_card()

func _apply_place(mat: ShaderMaterial) -> void:
        var pid := _place_id()
        var p: Dictionary = PAL[pid]
        var vp := _vp()
        mat.set_shader_parameter("top_col", p["top"])
        mat.set_shader_parameter("hor_col", p["hor"])
        mat.set_shader_parameter("orb_col", p["orb"])
        mat.set_shader_parameter("orb_kind", 1.0 if pid == "day" else 2.0)
        mat.set_shader_parameter("star_amt", 0.0 if pid == "day" else 1.0)
        # v0.2.6 THE SMALL ORB LAW (the owner: "make them smaller like the
        # ones in the snake game"): a ~34 logical px core + a tight halo,
        # computed from the REAL viewport - the old UV-space orb stretched
        # weird on portrait (part of the "weird sun").
        mat.set_shader_parameter("orb_r", 34.0 / maxf(1.0, vp.y))
        mat.set_shader_parameter("glow_r", 78.0 / maxf(1.0, vp.y))
        mat.set_shader_parameter("aspect", vp.x / maxf(1.0, vp.y))
        if spark_layer != null and is_instance_valid(spark_layer):
                spark_layer.queue_redraw()

func _place_id() -> String:
        var on := Box.item_on(game_id, "place")
        return on if PLACES.has(on) else "day"

func _char_id() -> String:
        var on := Box.skin_on(game_id)
        return on if CHARS.has(on) else "ball"

func _plat_id() -> String:
        var on := Box.item_on(game_id, "plat")
        return on if PLATS.has(on) else "sand"

func _pal() -> Dictionary:
        return PAL[_place_id()]

## The day/night FEELING (owner: "make day and night really give different
## feeling than just different backgrounds"): the world itself wears the
## place - a cool moonlit modulate at night, warm noon at day.
## v0.2.6 THE ONE-MODULATE LAW (the owner's leak catch: day -> night -> day
## came back DARKER): the old code re-added a CanvasModulate and freed the
## old one by NAME - on the second switch Godot @-renamed the new node
## (same-frame name collision with the not-yet-freed old one), so the
## third switch's lookup MISSED and the night tint survived forever under
## its renamed handle. ONE CanvasModulate lives in a member var now and
## only its COLOR is swapped - there is nothing left to leak.
func _day_night() -> void:
        if _place_mod == null or not is_instance_valid(_place_mod):
                _place_mod = CanvasModulate.new()
                _place_mod.name = "place_modulate"
                world.add_child(_place_mod)
        _place_mod.color = _pal()["modulate"]

# ============================================================ world building

func _build_player() -> void:
        player = Node2D.new()
        player.z_index = 5
        player.draw.connect(_draw_player)
        world.add_child(player)
        px = _vp().x / 2.0
        py = _vp().y - 240.0 * U
        player.position = Vector2(px, py)

func _build_world_start() -> void:
        var vp := _vp()
        # THE START PLATFORM (PGB law): one wide static ledge right under the
        # player, centered. It pays NO score and spawns NO coin (v0.2.6:
        # highest_idx starts AT the start platform; the first coin waits
        # 5-25 platforms up - the phantom free coin is dead).
        highest_idx = 0
        next_coin_idx = rng.randi_range(COIN_GAP_MIN, COIN_GAP_MAX)
        # v0.2.7: the first POWERUP also waits the owner's 20-40 platforms up
        # (next_pick_idx used to be born 0, which - with the old broken guard
        # - meant NEVER, and with the new guard would mean platform 1)
        next_pick_idx = rng.randi_range(PICKUP_GAP_MIN, PICKUP_GAP_MAX)
        _spawn_platform(vp.x / 2.0, vp.y - 160.0 * U, START_W * U, "static")
        # prefill the climb (reachability-checked, reliability-ruled)
        var top := cam_y - vp.y * 0.9
        while _last_top() > top:
                _gen_platform()
        for i in 30:
                _spawn_snowflake()

func _last_top() -> float:
        return float(platforms[platforms.size() - 1]["y"])

## The generator: reachability-checked like the PGB (the new platform must
## sit inside the horizontal reach of the previous one under the jump arc),
## wall-clamped (owner walls), type = weighted PGB set + the reliability law.
## v0.2.7 THE RAMP: the first DIFF_AT platforms keep the gentle gaps; past
## that the gap ramps toward the character's REAL jump ceiling (never past
## it - every jump stays possible, just demanding) and the horizontal
## spread widens. The reach law uses the DESCENDING branch: a landing above
## happens when the rising jump CROSSES the target top while falling,
## t = (v + sqrt(v^2 - 2 g h)) / g - so wide gaps really demand a full-speed
## run + a late, well-timed leap (the owner's "real challenge and timing").
func _gen_platform() -> void:
        var vp := _vp()
        var prev: Dictionary = platforms[platforms.size() - 1]
        var jump_v := absf(JUMP_V * U * float(_char()["jump"]))
        var grav := GRAV * U
        var rise_max := jump_v * jump_v / (2.0 * grav)   # the char's real ceiling (px)
        var ramp := clampf(float(next_idx - DIFF_AT) / float(DIFF_RAMP), 0.0, 1.0)
        var gap_cap := minf(GAP_HARD_MAX, 0.82 * rise_max / U)   # px (logical)
        var gap_hi := lerpf(GAP_MAX, gap_cap, ramp)
        var gap_lo := lerpf(GAP_MIN, GAP_MIN + maxf(0.0, gap_cap - GAP_MAX) * 0.35, ramp)
        if gap_hi < gap_lo:
                gap_hi = gap_lo
        var gap := rng.randf_range(gap_lo, gap_hi) * U
        var w := rng.randf_range(W_MIN, W_MAX) * U
        # horizontal reach under the arc (descending-branch crossing time)
        var h := clampf(gap / U, 10.0, rise_max * 0.98 / U) * U
        var disc: float = maxf(0.0, jump_v * jump_v - 2.0 * grav * h)
        var t_cross := (jump_v + sqrt(disc)) / grav
        var reach := WALK_MAX * U * t_cross * lerpf(0.72, 1.12, ramp)
        var lo: float = maxf(WALL_W * U + w / 2.0 + 4.0 * U, float(prev["x"]) - reach)
        var hi: float = minf(vp.x - WALL_W * U - w / 2.0 - 4.0 * U, float(prev["x"]) + reach)
        if hi < lo:
                var mid := clampf(float(prev["x"]), lo, hi)
                lo = mid
                hi = mid
        var x := rng.randf_range(lo, hi)
        var ptype := _pick_type()
        _spawn_platform(x, _last_top() - gap, w, ptype)

func _pick_type() -> String:
        var prev_unreliable: bool = platforms.size() > 0 \
                        and not RELIABLE.has(String(platforms[platforms.size() - 1]["type"]))
        if prev_unreliable:
                return RELIABLE[rng.randi() % RELIABLE.size()]
        # the weights shift as the tower climbs: static decays, movers grow;
        # v0.2.7 the two NEW kinds join at their owner-picked depths
        var shift := minf(20.0, float(score) * 0.35)
        var weights := {"static": maxf(14.0, 40.0 - shift), "moving": 25.0 + shift * 0.4,
                        "blinking": 15.0, "vanish": 10.0, "mb": 10.0}
        if next_idx >= SIZE_AT:
                weights["size"] = 11.0
        if next_idx >= DROP_AT:
                weights["dropper"] = 9.0
        var total := 0.0
        for k in weights:
                total += weights[k]
        var r := rng.randf() * total
        for k in weights:
                r -= weights[k]
                if r <= 0.0:
                        return k
        return "static"

## Platform dict + node bookkeeping. All platforms live in ONE painter
## (plat_layer._draw), so a platform is pure data. v0.2.7 fields: base_w
## (size platforms breathe around it), y0 (the dropper's home height),
## drop_v/drop_state (the dropper), dy (per-frame y motion, the rider rides
## it like dx).
func _spawn_platform(x: float, y: float, w: float, ptype: String) -> void:
        var p := {"idx": next_idx, "x": x, "y": y, "w": w, "type": ptype,
                        "snow": 0.0, "visible": true, "clock": 0.0, "ghost": false,
                        "dir": 1.0 if rng.randf() < 0.5 else -1.0,
                        "spd": rng.randf_range(MOVE_SPD_MIN, MOVE_SPD_MAX) * U,
                        "dx": 0.0, "dy": 0.0,
                        "base_w": w, "y0": y,
                        "drop_v": 0.0, "drop_state": "idle"}
        if ptype == "size":
                p["clock"] = rng.randf() * SIZE_PERIOD   # de-phased breathing
        if ptype == "moving" or ptype == "mb":
                p["spd"] = rng.randf_range(MOVE_SPD_MIN, MOVE_SPD_MAX) * U \
                                * (1.0 + minf(0.6, float(next_idx) * 0.004))
        platforms.append(p)
        # coins: 5-25 platforms from the LAST COIN SPAWNED (owner law);
        # NEVER on the start platform (v0.2.6: the phantom free coin the
        # owner kept collecting lived exactly here - next_coin_idx used to
        # start at 0, right where the ball spawns)
        if next_idx == next_coin_idx and next_idx > 0:
                coins.append({"x": x, "y": y - 64.0 * U, "idx": next_idx, "t": 0.0})
                next_coin_idx = next_idx + rng.randi_range(COIN_GAP_MIN, COIN_GAP_MAX)
        # v0.2.7 POWERUPS (the owner's law): one RANDOM powerup every 20-40
        # platforms counted from the LAST SPAWNED pickup. THE OLD BUG lived
        # here: next_pick_idx was born 0 and the `next_idx > 4` guard skipped
        # the branch at idx 0..4, so next_pick_idx stayed 0 FOREVER and
        # `next_idx == next_pick_idx` never matched again - no run could ever
        # spawn a single powerup. The counter now advances with >= and the
        # first pickup waits 20-40 platforms up. Unowned shelves still
        # advance the counter (a buy mid-run joins the next window).
        if next_idx >= next_pick_idx and next_idx > 0:
                var kinds := _owned_pws()
                # ANY platform hosts the pickup (the owner's law is the
                # SPACING - 20-40, no exceptions; a powerup may float over a
                # breaking ledge, that is a gift, not a bug)
                if not kinds.is_empty():
                        pickups.append({"x": x, "y": y - 106.0 * U, "idx": next_idx,
                                        "kind": kinds[rng.randi() % kinds.size()], "t": 0.0})
                next_pick_idx = next_idx + rng.randi_range(PICKUP_GAP_MIN, PICKUP_GAP_MAX)
        next_idx += 1

func _owned_pws() -> Array:
        var out := []
        for k in POWERUPS:
                if Box.item_owned(game_id, "pw", k):
                        out.append(k)
        return out

func _char() -> Dictionary:
        return CHARS[char_id]

## the EFFECTIVE body radius: the base radius scaled by the MELTING size -
## every gameplay touch (walls, landings, catchment) uses this.
func _pr() -> float:
        return PLAYER_R * U * char_size

func _vp() -> Vector2:
        return get_viewport_rect().size

# ============================================================ the run

## The slide-up law (owner): wakes after 2 platforms, x1.1 per 10.
func _scroll_speed() -> float:
        if phase != "run" or score < SCROLL_WAKE_AT:
                return 0.0
        var mult := pow(SCROLL_MULT, float(score / SCROLL_STEP))
        mult = minf(mult, SCROLL_CAP)
        if pw["id"] == "slow":
                mult *= 0.5
        return SCROLL_BASE * U * mult

func _goga_tick(delta: float) -> void:
        _time += delta
        if shake > 0.0:
                shake = maxf(0.0, shake - delta * 3.0)
        if phase != "run":
                _update_clouds(delta)
                _update_snow(delta)
                _update_fx(delta)
                queue_redraw_all()
                return
        var vp := _vp()

        # ---- the slide-up: the camera RISES on its own, pushing the player
        # toward the bottom of the screen. Falling below = end of round.
        scroll_now = _scroll_speed()
        cam_y -= scroll_now * delta

        # ---- the powerup life (10s) ----
        if pw["id"] != "":
                pw["t"] -= delta
                if pw["t"] <= 0.0:
                        pw = {"id": "", "t": 0.0}
                        Jukebox.sfx("tower_pw_end", -10.0)
                        _fx_ring(Vector2(px, py), Color(0.7, 0.75, 0.9, 0.5), 30.0)

        # ---- player physics (per-character modifiers) ----
        # v0.2.6 ANALOG: move_dir is a FORCE now (-1..1 from the left zone) -
        # the target speed is proportional to the finger's deflection from
        # its anchor, so speed AND force really differ (the owner's scheme).
        var c := _char()
        var g := GRAV * U * float(c["g"])
        var accel := (ACCEL if grounded else AIR_ACCEL) * U * float(c["accel"])
        var fric := GROUND_FRICTION * U * float(c["fric"])
        var drag := AIR_DRAG * U
        var vmax := WALK_MAX * U * (1.5 if pw["id"] == "speed" else 1.0) \
                        * (1.0 - 0.25 * snow_load)
        accel *= (1.0 - 0.45 * snow_load)      # the snow makes you heavy
        var want := move_dir
        if absf(want) > 0.001:
                vx = move_toward(vx, want * vmax, accel * delta)
        else:
                var dec := (fric if grounded else drag) * delta
                vx = move_toward(vx, 0.0, dec)
        vy += g * delta
        px += vx * delta
        py += vy * delta
        player.position = Vector2(px, py)   # the sprite IS the body (always)
        player.scale = Vector2.ONE * char_size   # MELTING lives visibly

        # ---- THE WALLS: the player can never leave the screen (owner) ----
        var wl := WALL_W * U + _pr()
        if px < wl:
                px = wl
                if vx < 0:
                        vx = -vx * WALL_BOUNCE
                        wall_flash["l"] = 0.22
                        if absf(vx) > 40.0 * U:
                                Jukebox.sfx("tower_wall", -14.0)
                                _fx_poof(Vector2(px - _pr() * 0.7, py), 4, 0.6)
        if px > vp.x - wl:
                px = vp.x - wl
                if vx > 0:
                        vx = -vx * WALL_BOUNCE
                        wall_flash["r"] = 0.22
                        if absf(vx) > 40.0 * U:
                                Jukebox.sfx("tower_wall", -14.0)
                                _fx_poof(Vector2(px + _pr() * 0.7, py), 4, 0.6)
        wall_flash["l"] = maxf(0.0, float(wall_flash["l"]) - delta)
        wall_flash["r"] = maxf(0.0, float(wall_flash["r"]) - delta)

        # ---- platforms: patrol / blink / vanish, carry the rider ----
        _update_platforms(delta)
        _update_landings(delta)

        # ---- the spin laws per character (owner: each its own way) ----
        _update_spin(delta)
        _update_support(delta)

        # ---- coins + powerup pickups ----
        _update_pickables(delta)

        # ---- THE PHYSICAL SNOW (the star mechanic) ----
        _update_snow(delta)
        _update_fx(delta)

        # ---- MELTING (v0.2.6): eat the snow under you, or shrink away ----
        if _melt_on():
                _update_melt(delta)

        _refresh_pw_ui()
        # ---- score bookkeeping: climb achievements (best tower) ----
        achievement_max("max_tower", score)
        achievement_max("max_height", int(maxf(0.0, (vp.y - 240.0 * U) - py)))
        if _speed_chip != null and is_instance_valid(_speed_chip):
                _speed_chip.text = "x%.2f" % (scroll_now / (SCROLL_BASE * U)) \
                                if scroll_now > 0.0 else "idle"

        # ---- camera: follows the player upward + the slide pushes it ----
        var target := minf(cam_y, py - vp.y * 0.55)
        cam_y = lerpf(cam_y, target, 1.0 - pow(0.0015, delta))
        world.position.y = -cam_y - (6.0 * U * shake * sin(_time * 61.0))
        if sky != null and sky.material is ShaderMaterial:
                (sky.material as ShaderMaterial).set_shader_parameter(
                        "shift", -cam_y * 0.00004)
                (sky.material as ShaderMaterial).set_shader_parameter(
                        "time_s", _time)

        # ---- cull below, spawn above ----
        _cull_and_spawn()

        # ---- fell below the screen = end of round (owner) ----
        # v0.2.7: the tower wears the BANNER now - the fall line insets above
        # the strip so the player is never hidden behind it while dying.
        if py - cam_y > vp.y - banner_bottom() + 70.0 * U:
                _die()

        _update_clouds(delta)
        queue_redraw_all()

func queue_redraw_all() -> void:
        player.queue_redraw()
        plat_layer.queue_redraw()
        pick_layer.queue_redraw()
        snow_layer.queue_redraw()
        fx.queue_redraw()
        cloud_layer.queue_redraw()
        spark_layer.queue_redraw()
        walls_layer.queue_redraw()

# ------------------------------------------------------------- platforms

func _update_platforms(delta: float) -> void:
        var vp := _vp()
        for p in platforms:
                var vis: bool = bool(p["visible"])
                var was_x: float = float(p["x"])
                var was_y: float = float(p["y"])
                var t := String(p["type"])
                # NOTE: "mb" does BOTH halves - a match would eat the second one
                if t == "moving" or t == "mb":
                        if vis:
                                var nx: float = float(p["x"]) + float(p["spd"]) * float(p["dir"]) * delta
                                var lo := WALL_W * U + float(p["w"]) / 2.0 + 2.0 * U
                                var hi := vp.x - WALL_W * U - float(p["w"]) / 2.0 - 2.0 * U
                                if nx < lo:
                                        nx = lo
                                        p["dir"] = 1.0
                                elif nx > hi:
                                        nx = hi
                                        p["dir"] = -1.0
                                p["x"] = nx
                                # a MOVING platform shakes its snow off (v0.2.6:
                                # the caps are earned, and motion un-earns them)
                                p["snow"] = maxf(0.0, float(p["snow"]) - SNOW_MOVE_SHED * delta)
                if t == "size" and vis:
                        # v0.2.7 THE SIZE PLATFORM (30+): the width breathes
                        # wide<->small SMOOTHLY (a sine on its own clock), the
                        # snow cap follows the drawn width automatically. The
                        # walls stay honest at the widest point.
                        p["clock"] = float(p["clock"]) + delta
                        var ph := float(p["clock"]) * TAU / SIZE_PERIOD
                        var f := SIZE_MIN_F + (SIZE_MAX_F - SIZE_MIN_F) * (0.5 + 0.5 * sin(ph))
                        var nw: float = minf(float(p["base_w"]) * f,
                                        vp.x - 2.0 * (WALL_W * U + 3.0 * U))
                        p["w"] = nw
                if t == "dropper":
                        # v0.2.7 THE DROPPER (50+): landing on it triggers a
                        # DROP - it accelerates down out of the screen, waits,
                        # then rises back home. The rider rides it down (the
                        # dy carry below) - jump off in time.
                        match String(p["drop_state"]):
                                "down":
                                        p["drop_v"] = minf(float(p["drop_v"]) + DROP_ACCEL * U * delta, DROP_MAX * U)
                                        p["y"] += float(p["drop_v"]) * delta
                                        if float(p["y"]) - cam_y > vp.y + 130.0 * U:
                                                p["drop_state"] = "wait"
                                                p["clock"] = 0.0
                                                p["visible"] = false
                                "wait":
                                        p["clock"] = float(p["clock"]) + delta
                                        if float(p["clock"]) >= DROP_WAIT:
                                                p["drop_state"] = "up"
                                                p["visible"] = true
                                "up":
                                        p["y"] -= DROP_RISE * U * delta
                                        if float(p["y"]) <= float(p["y0"]):
                                                p["y"] = float(p["y0"])
                                                p["drop_state"] = "idle"
                                                p["drop_v"] = 0.0
                if t == "blinking" or t == "mb":
                        p["clock"] = float(p["clock"]) + delta
                        if float(p["clock"]) >= BLINK_PERIOD:
                                p["clock"] = 0.0
                                p["visible"] = not vis
                        # v0.2.7 THE SNOW STASH (the owner's fix): the cap
                        # disappears and reappears WITH the platform - going
                        # ghost stashes it, coming back restores it. Nothing
                        # sheds, nothing floats.
                        if not bool(p["visible"]) and not p.has("snow_stash"):
                                p["snow_stash"] = float(p["snow"])
                                p["snow"] = 0.0
                        elif bool(p["visible"]) and p.has("snow_stash"):
                                p["snow"] = float(p["snow_stash"])
                                p.erase("snow_stash")
                if t == "vanish" and bool(p["ghost"]):
                        # cracking grace, then gone for VANISH_RESPAWN, then back
                        p["clock"] = float(p["clock"]) + delta
                        if bool(p["visible"]) and float(p["clock"]) >= VANISH_GRACE:
                                p["visible"] = false
                                _shatter_platform(p)     # v0.2.7 THE REAL BREAK
                        if float(p["clock"]) >= VANISH_GRACE + VANISH_RESPAWN:
                                p["ghost"] = false
                                p["visible"] = true
                                p["clock"] = 0.0
                        elif bool(p["visible"]):
                                # chips pop off WHILE it cracks (dynamic, not static)
                                if rng.randf() < 9.0 * delta:
                                        var cw: float = float(p["w"])
                                        parts.append({"x": float(p["x"]) + rng.randf_range(-cw * 0.45, cw * 0.45),
                                                        "y": float(p["y"]),
                                                        "vx": rng.randf_range(-40.0, 40.0) * U,
                                                        "vy": rng.randf_range(-60.0, 10.0) * U,
                                                        "life": 0.5, "max": 0.5,
                                                        "w": rng.randf_range(4.0, 9.0) * U,
                                                        "h": rng.randf_range(3.0, 6.0) * U,
                                                        "rot": rng.randf_range(-0.5, 0.5),
                                                        "vrot": rng.randf_range(-6.0, 6.0),
                                                        "col": _plat_chip_col(), "kind": "chunk"})
                p["dx"] = float(p["x"]) - was_x
                p["dy"] = float(p["y"]) - was_y
        # the rider rides (moving platforms carry the player, droppers drop them)
        if grounded and not ground_plat.is_empty():
                px += float(ground_plat.get("dx", 0.0))
                py += float(ground_plat.get("dy", 0.0))

## v0.2.7 THE REAL BREAK: the platform shatters into physical chunks -
## 4-6+ pieces sized by the platform's OWN width, each with gravity, spin
## and a fade (the owner: "static and not dynamic based on the platform").
func _shatter_platform(p: Dictionary) -> void:
        var w: float = float(p["w"])
        var n := 4 + int(w / (85.0 * U))
        for i in n:
                var cx: float = float(p["x"]) - w * 0.5 + (float(i) + 0.5) * w / float(n)
                parts.append({"x": cx, "y": float(p["y"]),
                                "vx": rng.randf_range(-95.0, 95.0) * U,
                                "vy": rng.randf_range(-200.0, -30.0) * U,
                                "life": rng.randf_range(0.55, 0.9), "max": 0.9,
                                "w": w / float(n) * rng.randf_range(0.5, 0.92),
                                "h": PLAT_H * U * rng.randf_range(0.45, 0.95),
                                "rot": 0.0, "vrot": rng.randf_range(-8.0, 8.0),
                                "col": _plat_chip_col(), "kind": "chunk"})
        Jukebox.sfx("tower_break", -6.0, 1.0 + rng.randf() * 0.1)
        shake = maxf(shake, 0.4)

## the chip color follows the equipped platform skin (the break belongs to
## the platform, not to a generic gray)
func _plat_chip_col() -> Color:
        match _plat_id():
                "rock":
                        return Color("8a93a8")
                "grass":
                        return Color("8a6a46")
                "metal":
                        return Color("9aa4b2")
        return Color("c9a86a")   # sand

func _update_landings(delta: float) -> void:
        var vp := _vp()
        if vy > 0.0:
                for p in platforms:
                        if String(p["type"]) == "vanish" and bool(p["ghost"]):
                                continue
                        if String(p["type"]) in ["blinking", "mb"] and not bool(p["visible"]):
                                continue
                        var top: float = float(p["y"]) - PLAT_H * U * 0.5 - _pr()
                        # SWEPT landing: the feet CROSSED the top this frame -
                        # fps-proof (a slow frame can never tunnel through)
                        var prev_y: float = py - vy * delta
                        if prev_y <= top + 6.0 * U and py >= top \
                                        and absf(px - float(p["x"])) < float(p["w"]) / 2.0 + _pr() * 0.55:
                                _land(p)
                                break
        elif grounded:
                # still standing? (platform vanished / walked off / carried away)
                var still: bool = ground_plat != null and not ground_plat.is_empty() \
                                and bool(ground_plat.get("visible", true)) \
                                and not (String(ground_plat.get("type", "")) == "vanish" and bool(ground_plat.get("ghost", false))) \
                                and absf(px - float(ground_plat.get("x", -99999))) < float(ground_plat.get("w", 0)) / 2.0 + _pr() * 0.55 \
                                and absf(py - (float(ground_plat.get("y", 0)) - PLAT_H * U * 0.5 - _pr())) < 8.0 * U
                if not still:
                        grounded = false
                        ground_plat = {}

## THE SCORING LAW (owner): land higher than EVER = +1 (skipping platforms
## still pays exactly 1); land at or below the best = nothing.
func _land(p: Dictionary) -> void:
        var c := _char()
        py = float(p["y"]) - PLAT_H * U * 0.5 - _pr()
        vy = 0.0
        var was_air := not grounded
        grounded = true
        ground_plat = p
        if was_air:
                vx *= 0.55
                Jukebox.sfx("tower_land", -13.0, 1.0 + rng.randf() * 0.12)
                _fx_poof(Vector2(px, py + _pr() * 0.8), 6, 0.8)
                # the snow pops off on impact (per character)
                var shed: float = float(c["shed_land"])
                if snow_load > 0.02 and shed > 0.0:
                        _fx_poof(Vector2(px, py + _pr()), 8, 1.2)
                snow_load = maxf(0.0, snow_load - snow_load * shed)
                # vanish platforms start dying under your feet
                if String(p["type"]) == "vanish" and not bool(p["ghost"]):
                        p["ghost"] = true
                        p["clock"] = 0.0
                        p["visible"] = true
                        Jukebox.sfx("tower_crack", -10.0)
                # v0.2.7 THE DROPPER: landing triggers the drop (the owner:
                # "they go down when the character lands on them")
                if String(p["type"]) == "dropper" and String(p["drop_state"]) == "idle":
                        p["drop_state"] = "down"
                        p["drop_v"] = 40.0 * U
                        Jukebox.sfx("tower_crack", -12.0, 0.85)
                        _fx_poof(Vector2(px, py + _pr() * 0.6), 6, 0.9)
        if int(p["idx"]) > highest_idx:
                highest_idx = int(p["idx"])
                add_score(1)
                _fx_pop(Vector2(px, py - 60.0 * U), "+1")
                check_achievements()

# ------------------------------------------------------------- jump

func _do_jump() -> void:
        if phase != "run":
                return
        var c := _char()
        if grounded:
                var jv: float = JUMP_V * U * float(c["jump"]) \
                                * (1.28 if pw["id"] == "big" else 1.0) \
                                * (1.0 - 0.12 * snow_load)
                vy = jv
                grounded = false
                ground_plat = {}
                air_jumped = false
                hops += 1
                achievement_count("hops", 1)
                Jukebox.sfx("tower_jump", -8.0, 1.0 + rng.randf() * 0.08)
                _fx_poof(Vector2(px, py + _pr() * 0.7), 7, 1.0)
        elif pw["id"] == "x2" and not air_jumped:
                # THE x2: one extra jump in the air (owner powerup)
                air_jumped = true
                vy = JUMP_V * U * float(c["jump"]) * 0.92
                hops += 1
                achievement_count("hops", 1)
                Jukebox.sfx("tower_jump", -8.0, 1.22)
                _fx_ring(Vector2(px, py + _pr()), Color(1, 1, 1, 0.7), 26.0)
                _fx_poof(Vector2(px, py + _pr()), 6, 1.0)

func _set_move(dir: int) -> void:
        move_dir = clampf(float(dir), -1.0, 1.0)

## the ANALOG axis from the left zone (v0.2.6): the finger's X offset from
## its anchor is the force - a dead point at the anchor (the owner: "really
## differ the speed and force and returning the finger to the middle really
## act like dead-point/stopping movement"), full deflection = full force,
## left-right only (Y never matters).
func _set_axis(dx_px: float) -> void:
        var dead := AXIS_DEAD * U
        var full := AXIS_FULL * U
        var a := 0.0
        if absf(dx_px) > dead:
                a = clampf((absf(dx_px) - dead) / maxf(1.0, full - dead), 0.0, 1.0)
        move_dir = signf(dx_px) * a

# ------------------------------------------------------------- coins / pickups

func _update_pickables(delta: float) -> void:
        # coins: collect on touch, bob forever
        for c in coins.duplicate():
                c["t"] = float(c["t"]) + delta
                var cy: float = float(c["y"]) + sin(float(c["t"]) * 3.2) * 7.0 * U
                if absf(px - float(c["x"])) < _pr() + 26.0 * U \
                                and absf(py - cy) < _pr() + 26.0 * U:
                        coins.erase(c)
                        add_run_coins(1)
                        Jukebox.sfx("tower_coin", -6.0, 1.0 + rng.randf() * 0.1)
                        _fx_ring(Vector2(float(c["x"]), cy), Color(1.0, 0.85, 0.3, 0.9), 34.0)
                        _fx_poof(Vector2(float(c["x"]), cy), 6, 1.0)
        # pickups: touch = the powerup goes live (a second one replaces it)
        for k in pickups.duplicate():
                k["t"] = float(k["t"]) + delta
                if absf(px - float(k["x"])) < _pr() + 30.0 * U \
                                and absf(py - float(k["y"])) < _pr() + 30.0 * U:
                        pickups.erase(k)
                        var kind := String(k["kind"])
                        var replaced := String(pw["id"]) != "" and String(pw["id"]) != kind
                        pw = {"id": kind, "t": PW_TIME}
                        air_jumped = false
                        Jukebox.sfx("tower_pw", -4.0)
                        _fx_ring(Vector2(float(k["x"]), float(k["y"])), Color(0.6, 0.9, 1.0, 0.9), 46.0)
                        _fx_pop(Vector2(float(k["x"]), float(k["y"]) - 50.0 * U),
                                        POWERUPS[kind]["glyph"] if kind != "x2" else "x2!")
                        if replaced:
                                _toast_show("%s takes over" % POWERUPS[kind]["name"])

func _cull_and_spawn() -> void:
        var vp := _vp()
        # platforms / coins / pickups below the screen die (their coins may be
        # gone forever - the spacing already counted them, owner note).
        # v0.2.7: a DROPPER mid-cycle is exempt while its HOME is still in
        # reach - it has to survive its trip below the screen to come back.
        platforms = platforms.filter(func(p):
                if String(p["type"]) == "dropper" and String(p.get("drop_state", "idle")) != "idle":
                        return float(p.get("y0", p["y"])) - cam_y < vp.y + 160.0 * U
                var alive: bool = float(p["y"]) - cam_y < vp.y + 160.0 * U
                return alive)
        coins = coins.filter(func(c):
                return float(c["y"]) - cam_y < vp.y + 120.0 * U)
        pickups = pickups.filter(func(k):
                return float(k["y"]) - cam_y < vp.y + 120.0 * U)
        while _last_top() > cam_y - 120.0:
                _gen_platform()

func _die(reason := "fall") -> void:
        if phase != "run":
                return
        phase = "over"
        move_dir = 0.0
        move_touch = -1
        jump_touches.clear()
        if reason == "melted":
                Jukebox.sfx("tower_puff", -4.0)
                _fx_pop(Vector2(px, py - 50.0 * U), "MELTED")
        else:
                Jukebox.sfx("tower_fall", -3.0)
        shake = 1.0
        _fx_burst(Vector2(px, minf(py, cam_y + _vp().y - 40.0 * U)))
        achievement_max("max_tower", score)
        check_achievements()
        var tw := create_tween()
        tw.tween_property(world, "modulate", Color(0.75, 0.82, 1.0, 0.5), 0.45)
        tw.tween_callback(func(): finish_run(score))

# ------------------------------------------------------------- the SPIN LAWS
## Owner: every character spins its OWN way while it moves.

func _update_spin(delta: float) -> void:
        var c := _char()
        match char_id:
                "ball":
                        # the classic roller: the ball ROLLS - it goes upside down
                        if grounded and absf(vx) > 12.0 * U:
                                spin += (vx / _pr()) * delta
                        else:
                                spin += (vx * 0.3 / _pr()) * delta
                        player.rotation = spin
                "square":
                        # v0.2.6 REAL TUMBLING (the owner: "physical movements
                        # where it flips and the side falls", the cube "flips
                        # 90 degrees yes but for real"): the body pivots over
                        # its leading corner/edge - the rotation is CONTINUOUS
                        # and driven by the walk arc (theta = v / r), never a
                        # look-snap; _update_support lifts the body so the
                        # falling side RIDES the platform, and when you stop
                        # the body eases onto the nearest flat face and SLAPS
                        # it (a soft thud + a little dust).
                        # v0.2.7: the owner confirmed the cube - UNTOUCHED.
                        var pivot_r: float = _pr() * 1.41
                        if grounded and absf(vx) > 14.0 * U:
                                tumble_vel = vx / pivot_r
                        else:
                                # inertia: the spin decays in the air / on stop
                                tumble_vel = move_toward(tumble_vel, 0.0, 3.2 * delta)
                        tumble_rot += tumble_vel * delta
                        if grounded and absf(vx) <= 14.0 * U and absf(tumble_vel) < 0.6:
                                _tumble_settle(delta)
                        else:
                                settle_hit = false
                        player.rotation = tumble_rot
                "shard":
                        # v0.2.7 THE SHARD FIX: same tumble language as the
                        # cube, but the pivot radius is the ACTUAL lowest
                        # vertex distance (the triangle's three corners are at
                        # 1.06R and 1.23R - a fixed radius made it skate), and
                        # the settle targets are the TRUE flat-side stances
                        # (0 and +-2.0471 rad) - it lands ON its sides now.
                        var R_l := PLAYER_R * U * char_size
                        var pv := _lowest_shard_vert(R_l)
                        var pivot_r: float = maxf(8.0 * U, float(pv["d"]))
                        if grounded and absf(vx) > 14.0 * U:
                                tumble_vel = vx / pivot_r
                        else:
                                tumble_vel = move_toward(tumble_vel, 0.0, 3.2 * delta)
                        tumble_rot += tumble_vel * delta
                        if grounded and absf(vx) <= 14.0 * U and absf(tumble_vel) < 0.6:
                                _tumble_settle(delta)
                        else:
                                settle_hit = false
                        player.rotation = tumble_rot
                "egg":
                        # the egg WOBBLES: never a full spin, always lands back up
                        wobble_clock += delta * (9.0 if absf(vx) > 20.0 * U else 3.0)
                        player.rotation = sin(wobble_clock) * 0.32 * clampf(absf(vx) / (WALK_MAX * U), 0.15, 1.0) * signf(vx if vx != 0.0 else 1.0)

## the settle: ease the body onto its nearest FLAT face (the cube: any
## 90-degree stance, the shard: one of its three edge-down stances) and
## slap it down when it arrives.
func _tumble_settle(delta: float) -> void:
        var target := 0.0
        if char_id == "square":
                target = roundf(tumble_rot / (PI / 2.0)) * (PI / 2.0)
        else:
                var best := 999.0
                for base in [0.0, SHARD_SETTLE_ANG, -SHARD_SETTLE_ANG]:
                        var cand: float = base + TAU * roundf((tumble_rot - base) / TAU)
                        if absf(cand - tumble_rot) < best:
                                best = absf(cand - tumble_rot)
                                target = cand
        var prev := tumble_rot
        tumble_rot = lerpf(tumble_rot, target, 1.0 - pow(0.0004, delta))
        if not settle_hit and absf(tumble_rot - target) < 0.035 \
                        and absf(prev - target) >= 0.035:
                settle_hit = true
                Jukebox.sfx("tower_slap", -16.0, 1.0 + rng.randf() * 0.1)
                _fx_poof(Vector2(px + signf(target - prev + 0.001) * _pr() * 0.7,
                                py + _pr() * 0.7), 3, 0.55)

## the SUPPORT LAW (the physical half of the tumble): the drawn body is
## lifted so its lowest corner/vertex RIDES the platform while it flips -
## this is what makes a side FALL instead of sink through. Pure draw
## space: the physics body (px/py) never changes.
## v0.2.7: the shard's geometry lives in ONE helper (shared by the pivot,
## the support and the settle math) - the three verts of _draw_player.
func _shard_verts(R: float) -> Array:
        return [Vector2(0, -R * 1.06), Vector2(R * 0.95, R * 0.78),
                        Vector2(-R * 0.95, R * 0.78)]

## which shard vertex points lowest at the current tumble angle - and how
## far from the body center it sits (the REAL pivot radius, it changes as
## the triangle rolls over corners of different length)
func _lowest_shard_vert(R: float) -> Dictionary:
        var best_v := Vector2.ZERO
        var best_d := 0.0
        var best_y := -1e9
        for v0: Vector2 in _shard_verts(R):
                var wy: float = v0.x * sin(tumble_rot) + v0.y * cos(tumble_rot)
                if wy > best_y:
                        best_y = wy
                        best_v = v0
                        best_d = v0.length()
        return {"v": best_v, "d": best_d, "y": best_y}

func _update_support(_delta: float) -> void:
        if not (char_id == "square" or char_id == "shard"):
                return
        var R := PLAYER_R * U * char_size
        var ext := 0.0     # the lowest body point below the center, now
        var ext0 := 0.0    # ... at the resting stance
        if char_id == "square":
                var h := R * 0.92
                var th: float = fmod(absf(tumble_rot), PI / 2.0)
                ext = h * (cos(th) + sin(th))
                ext0 = h
        else:
                for v0: Vector2 in _shard_verts(R):
                        ext = maxf(ext, v0.x * sin(tumble_rot) + v0.y * cos(tumble_rot))
                ext0 = R * 0.78
        player.position.y = py - (ext - ext0)

# ============================================================ MELTING (v0.2.6)

func _melt_on() -> bool:
        return Box.item_owned(game_id, "melt", "melt") \
                        and Box.item_on(game_id, "melt") == "on"

## The owner's loop: ON = eat the snow UNDER you (by time AND movement; a
## fast move eats at a LOWER rate - down to ~30% - so it takes longer:
## "the faster the move the higher the consumption time and lower the
## consumption rate") and GROW toward x1.5 ("not too much"). NO snow
## under you (bare platform or air) = shrink until the run ends.
func _update_melt(delta: float) -> void:
        var under: float = 0.0
        if grounded and not ground_plat.is_empty():
                under = maxf(0.0, float(ground_plat.get("snow", 0.0)))
        if under > 0.004:
                var spd_norm := clampf(absf(vx) / maxf(1.0, WALK_MAX * U), 0.0, 1.0)
                var rate: float = MELT_BASE * (1.0 - (1.0 - MELT_SPEED_FLOOR) * spd_norm)
                var take: float = minf(under, rate * delta)
                ground_plat["snow"] = under - take
                var before := char_size
                char_size = minf(MELT_MAX, char_size + take * MELT_GROW)
                if rng.randf() < 6.0 * delta:
                        _fx_melt_drip()
                if before < MELT_MAX and char_size >= MELT_MAX:
                        _fx_pop(Vector2(px, py - _pr() - 26.0 * U), "MAX")
        else:
                char_size -= MELT_SHRINK * delta
                if rng.randf() < 4.0 * delta:
                        _fx_poof(Vector2(px + rng.randf_range(-10.0, 10.0) * U,
                                        py + _pr() * 0.4), 1, 0.5)
                if char_size <= MELT_MIN:
                        char_size = MELT_MIN
                        _die("melted")

func _fx_melt_drip() -> void:
        parts.append({"x": px + rng.randf_range(-_pr() * 0.5, _pr() * 0.5),
                        "y": py + _pr() * 0.5, "vx": rng.randf_range(-16.0, 16.0) * U,
                        "vy": rng.randf_range(40.0, 90.0) * U,
                        "life": 0.5, "max": 0.5, "r": rng.randf_range(2.0, 3.6) * U,
                        "col": Color("bfe8f2"), "kind": "snow"})

# ------------------------------------------------------------- THE SNOW
## Real flakes fall (world space), LAND on platforms (the snow cap grows)
## and on the PLAYER (slow + heavy). Rolling sheds it. The owner's star
## mechanic - every number here is a tuned law, not a decoration.

const SNOW_COUNT := 110
const SNOW_CAP_MAX := 1.0
const SNOW_ON_PLAT := 0.014        # a landed flake thickens the cap by this
                                   # (slow fill - platforms start BARE and
                                   # EARN their snow, the v0.2.6 owner law)
const SNOW_ON_PLAYER := 0.035      # a flake that hits you sticks by this
const SHED_ROLL := 0.35            # load/s shed while rolling (x char)
const SHED_AIR := 0.05             # load/s shed airborne (the wind shakes it)
const SNOW_MOVE_SHED := 0.12      # cap/s a MOVING platform shakes off
# (v0.2.7: no ghost-shed any more - blinking platforms STASH their cap and
# restore it when they come back, the snow appears/disappears WITH them)

func _spawn_snowflake() -> void:
        var vp := _vp()
        flakes.append({"x": rng.randf_range(WALL_W * U + 4.0, vp.x - WALL_W * U - 4.0),
                        "y": cam_y - rng.randf_range(10.0, 60.0) * U,
                        "vy": rng.randf_range(46.0, 150.0) * U,
                        "ph": rng.randf() * TAU,
                        "sz": rng.randf_range(1.6, 4.6) * U,
                        "fore": rng.randf() < 0.14})

func _snow_wind() -> float:
        return sin(_time * 0.32) * 30.0 * U + sin(_time * 0.13 + 1.7) * 16.0 * U

func _update_snow(delta: float) -> void:
        var vp := _vp()
        var wind := _snow_wind()
        var c := _char()
        while flakes.size() < SNOW_COUNT:
                _spawn_snowflake()
        for f in flakes:
                # flake physics: gravity-ish fall + the global wind sway
                f["y"] += float(f["vy"]) * delta
                f["x"] += (wind + sin(_time * 1.7 + float(f["ph"])) * 14.0 * U) * delta \
                                * (1.6 if bool(f["fore"]) else 1.0)
                # a flake that lands on a PLATFORM thickens its snow cap
                var landed := false
                for p in platforms:
                        if String(p["type"]) == "vanish" and bool(p["ghost"]):
                                continue
                        if String(p["type"]) in ["blinking", "mb"] and not bool(p["visible"]):
                                continue
                        var top: float = float(p["y"]) - PLAT_H * U * 0.5
                        var sy: float = float(f["y"])
                        if sy >= top and sy <= top + 10.0 * U + float(f["vy"]) * delta \
                                        and absf(float(f["x"]) - float(p["x"])) < float(p["w"]) / 2.0 \
                                        and float(p["snow"]) < SNOW_CAP_MAX:
                                p["snow"] = minf(SNOW_CAP_MAX, float(p["snow"]) + SNOW_ON_PLAT)
                                landed = true
                                # the flake lands FOR REAL: a little poof at
                                # the impact spot (v0.2.6)
                                if rng.randf() < 0.30:
                                        _fx_poof(Vector2(float(f["x"]), top), 1, 0.4)
                                break
                if not landed and bool(f["fore"]) == false:
                        # a flake that lands on the TOP of you sticks (slow +
                        # heavy) - the catchment is the ball's upper cap,
                        # not its whole column
                        if absf(float(f["x"]) - px) < _pr() * 0.8 \
                                        and float(f["y"]) > py - _pr() - 6.0 * U \
                                        and float(f["y"]) < py - _pr() * 0.2:
                                snow_load = minf(1.0, snow_load + SNOW_ON_PLAYER * float(c["snow_in"]))
                                landed = true
                # recycle at the bottom (or on landing)
                if landed or float(f["y"]) - cam_y > vp.y + 12.0:
                        f["x"] = rng.randf_range(WALL_W * U + 4.0, vp.x - WALL_W * U - 4.0)
                        f["y"] = cam_y - rng.randf_range(6.0, 40.0) * U
        # SHEDDING: rolling shakes it off, the air dries you slowly
        if grounded and absf(vx) > 60.0 * U:
                var before := snow_load
                snow_load = maxf(0.0, snow_load - SHED_ROLL * float(c["shed_roll"]) * delta)
                if before > 0.05 and rng.randf() < 10.0 * delta:
                        _fx_shed()
        elif not grounded:
                snow_load = maxf(0.0, snow_load - SHED_AIR * delta)

# ------------------------------------------------------------- clouds / fx

func _update_clouds(delta: float) -> void:
        var vp := _vp()
        for cl in clouds:
                cl["x"] = float(cl["x"]) - float(cl["spd"]) * delta
                if float(cl["x"]) + float(cl["w"]) < 0.0:
                        cl["x"] = vp.x + float(cl["w"]) * 0.2
                        cl["y"] = cam_y + rng.randf_range(-vp.y * 0.9, vp.y * 0.5)

var parts: Array = []               # {x,y,vx,vy,life,max,r,col,kind}
var pops: Array = []                # {x,y,life,txt}

func _fx_poof(at: Vector2, n: int, scale: float) -> void:
        for i in n:
                parts.append({"x": at.x, "y": at.y,
                                "vx": rng.randf_range(-70.0, 70.0) * U * scale,
                                "vy": rng.randf_range(-110.0, -20.0) * U * scale,
                                "life": rng.randf_range(0.3, 0.55), "max": 0.55,
                                "r": rng.randf_range(2.5, 5.5) * U * scale,
                                "col": _pal()["snow"], "kind": "snow"})
        if parts.size() > 240:
                parts = parts.slice(parts.size() - 240)

func _fx_shed() -> void:
        _fx_poof(Vector2(px - signf(vx) * _pr() * 0.6, py + _pr() * 0.5), 2, 0.7)

func _fx_ring(at: Vector2, col: Color, r: float) -> void:
        parts.append({"x": at.x, "y": at.y, "vx": 0.0, "vy": 0.0, "life": 0.4,
                        "max": 0.4, "r": r * U, "col": col, "kind": "ring"})

func _fx_burst(at: Vector2) -> void:
        for i in 22:
                parts.append({"x": at.x, "y": at.y,
                                "vx": rng.randf_range(-320.0, 320.0) * U,
                                "vy": rng.randf_range(-420.0, 60.0) * U,
                                "life": rng.randf_range(0.5, 0.9), "max": 0.9,
                                "r": rng.randf_range(3.0, 7.0) * U,
                                "col": _pal()["snow"], "kind": "snow"})

func _fx_pop(at: Vector2, txt: String) -> void:
        pops.append({"x": at.x, "y": at.y, "life": 0.8, "txt": txt})

func _update_fx(delta: float) -> void:
        for p in parts.duplicate():
                p["life"] = float(p["life"]) - delta
                if String(p["kind"]) == "snow":
                        p["x"] = float(p["x"]) + float(p["vx"]) * delta
                        p["y"] = float(p["y"]) + float(p["vy"]) * delta
                        p["vy"] = float(p["vy"]) + 900.0 * U * delta
                elif String(p["kind"]) == "chunk":
                        # v0.2.7 the physical break chunks: gravity + spin
                        p["x"] = float(p["x"]) + float(p["vx"]) * delta
                        p["y"] = float(p["y"]) + float(p["vy"]) * delta
                        p["vy"] = float(p["vy"]) + 1500.0 * U * delta
                        p["vx"] = float(p["vx"]) * (1.0 - 0.6 * delta)
                        p["rot"] = float(p["rot"]) + float(p["vrot"]) * delta
                if float(p["life"]) <= 0.0:
                        parts.erase(p)
        for p in pops.duplicate():
                p["life"] = float(p["life"]) - delta
                p["y"] = float(p["y"]) - 60.0 * U * delta
                if float(p["life"]) <= 0.0:
                        pops.erase(p)
        fx.queue_redraw()
        snow_layer.queue_redraw()

# ============================================================ painting

func _hashf(n: int, salt: float = 0.0) -> float:
        return fmod(absf(sin(float(n) * 127.1 + salt * 311.7)) * 43758.5453, 1.0)

func _draw_platforms() -> void:
        var skin := _plat_id()
        for p in platforms:
                var sy: float = float(p["y"]) - 0.0   # plat_layer lives IN world
                var sx: float = float(p["x"])
                var w: float = float(p["w"])
                var h: float = PLAT_H * U
                if not bool(p["visible"]):
                        # the ghost outline (blinking-off / vanished) - a fair hint
                        if bool(p["ghost"]) or String(p["type"]) in ["blinking", "mb"]:
                                plat_layer.draw_rect(Rect2(sx - w / 2.0, sy - h / 2.0, w, h),
                                                Color(1, 1, 1, 0.10), false, 2.0 * U)
                        continue
                var idx: int = int(p["idx"])
                var left := sx - w / 2.0
                var top := sy - h / 2.0
                var body := Rect2(left, top, w, h)
                match skin:
                        "sand":
                                plat_layer.draw_rect(body, Color("c9a86a"))
                                plat_layer.draw_rect(Rect2(left, top, w, h * 0.42), Color("e3c98d"))
                                plat_layer.draw_rect(Rect2(left, top + h * 0.8, w, h * 0.2), Color("a8874f"))
                                # deterministic grains (owner: no random look)
                                var grains := int(w / (16.0 * U))
                                for i in grains:
                                        var gx := left + _hashf(idx, float(i)) * w
                                        var gy := top + (0.2 + _hashf(idx, float(i) + 7.3) * 0.7) * h
                                        plat_layer.draw_rect(Rect2(gx, gy, 2.2 * U, 2.2 * U), Color("8f6f3e"))
                        "rock":
                                plat_layer.draw_rect(body, Color("8a93a8"))
                                plat_layer.draw_rect(Rect2(left, top, w, h * 0.34), Color("a8b2c4"))
                                plat_layer.draw_rect(Rect2(left, top + h * 0.75, w, h * 0.25), Color("6a7386"))
                                # facets + a crack
                                var facets := maxi(2, int(w / (70.0 * U)))
                                for i in facets:
                                        var fx0 := left + (float(i) + _hashf(idx, float(i)) * 0.5) * w / float(facets)
                                        var fy := top + h * (0.3 + _hashf(idx, float(i) + 3.1) * 0.4)
                                        var pts := PackedVector2Array([Vector2(fx0, fy), Vector2(fx0 + 16.0 * U, fy + 5.0 * U), Vector2(fx0 + 8.0 * U, fy + h * 0.5)])
                                        plat_layer.draw_colored_polygon(pts, Color("767f94"))
                                plat_layer.draw_line(Vector2(left + w * 0.3, top + 2.0 * U), Vector2(left + w * 0.42, top + h - 2.0 * U), Color("5d6578"), 1.6 * U)
                        "grass":
                                plat_layer.draw_rect(body, Color("8a6a46"))                       # soil
                                plat_layer.draw_rect(Rect2(left, top, w, h * 0.45), Color("6fae5c"))
                                plat_layer.draw_rect(Rect2(left, top, w, h * 0.16), Color("8cc975"))
                                var blades := int(w / (12.0 * U))
                                for i in blades:
                                        var bx := left + (float(i) + 0.3) * w / float(blades)
                                        var bh := (4.0 + _hashf(idx, float(i)) * 6.0) * U
                                        var pts := PackedVector2Array([Vector2(bx, top + 1.0), Vector2(bx + 2.6 * U, top - bh), Vector2(bx + 5.2 * U, top + 1.0)])
                                        plat_layer.draw_colored_polygon(pts, Color("8cc975"))
                                if _hashf(idx, 9.1) > 0.55:   # one deterministic flower
                                        var flx := left + w * (0.2 + _hashf(idx, 4.4) * 0.6)
                                        plat_layer.draw_circle(Vector2(flx, top - 2.0 * U), 3.4 * U, Color("f0d0e0"))
                        "metal":
                                plat_layer.draw_rect(body, Color("9aa4b2"))
                                plat_layer.draw_rect(Rect2(left, top, w, h * 0.3), Color("c8d2de"))
                                plat_layer.draw_rect(Rect2(left, top + h * 0.55, w, h * 0.45), Color("707a8a"))
                                plat_layer.draw_rect(Rect2(left + 6.0 * U, top + h * 0.46, w - 12.0 * U, 1.6 * U), Color("b8c2ce"))
                                var rivets := maxi(2, int(w / (64.0 * U)))
                                for i in rivets:
                                        var rx := left + (float(i) + 0.5) * w / float(rivets)
                                        plat_layer.draw_circle(Vector2(rx, top + h * 0.28), 3.0 * U, Color("5d6575"))
                                        plat_layer.draw_circle(Vector2(rx, top + h * 0.78), 3.0 * U, Color("5d6575"))
                # THE SNOW CAP (v0.2.6: real ACCUMULATION, not a flat slab) -
                # a chain of deterministic lumps that grows with what landed;
                # a fresh platform is BARE and earns every lump
                var cap: float = float(p["snow"])
                if cap > 0.02:
                        var n := 3 + int(cap * 4.0)
                        var ln := w / float(n)
                        for i in n:
                                var lx: float = left + (float(i) + 0.5) * ln
                                var rr: float = ln * (0.52 + 0.20 * _hashf(idx, float(i))) \
                                                * (0.45 + 0.55 * cap)
                                # a FLAT WIDE dome (an ellipse via the draw
                                # transform) - snow settles, it does not roll
                                # into balls (the v0.2.6 QA eyeball fix)
                                plat_layer.draw_set_transform(
                                                Vector2(lx, top + 1.0 * U), 0.0,
                                                Vector2(1.0 + 0.6 * _hashf(idx, float(i) + 3.3), 0.58))
                                plat_layer.draw_circle(Vector2.ZERO, rr, _pal()["snow"])
                        plat_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                        plat_layer.draw_rect(Rect2(left, top - 1.0 * U, w, 2.0 * U),
                                        _pal()["snow"])
                # v0.2.7 THE CRACK PREVIEW: jagged, deterministic per platform,
                # each crack a CHAIN of segments that lengthens AND widens with
                # the grace clock (the old 3 static lines read as decoration)
                if String(p["type"]) == "vanish" and bool(p["ghost"]) and bool(p["visible"]):
                        var frac: float = clampf(float(p["clock"]) / VANISH_GRACE, 0.0, 1.0)
                        var segs := 5
                        for ci in 3:
                                var ang := TAU * (float(ci) / 3.0) + _hashf(idx, float(ci)) * 1.7
                                var dirv := Vector2(cos(ang), sin(ang) * 0.42 + 0.18).normalized()
                                var cur := Vector2(sx + (_hashf(idx, float(ci) + 11.0) - 0.5) * w * 0.5, sy)
                                var steps := 1 + int(frac * float(segs))
                                for si in steps:
                                        var seg_len: float = w * 0.085 * (0.7 + _hashf(idx, float(ci * 7 + si)) * 0.7)
                                        var nxt := cur + dirv * seg_len
                                        nxt.y += (_hashf(idx, float(ci * 5 + si)) - 0.5) * 7.0 * U
                                        nxt.x = clampf(nxt.x, left + 2.0 * U, left + w - 2.0 * U)
                                        var cc := Color("2e2620").lightened(0.18 * _hashf(idx, float(si) + ci))
                                        plat_layer.draw_line(cur, nxt, cc, (1.3 + 2.2 * frac) * U)
                                        # a fork now and then (a real fracture network)
                                        if si > 0 and si < steps - 1 and _hashf(idx, float(ci * 9 + si)) > 0.6:
                                                var fv := dirv.rotated(0.9 * signf(_hashf(idx, float(ci + si)) - 0.5))
                                                plat_layer.draw_line(nxt, nxt + fv * seg_len * 0.55,
                                                                cc * Color(1, 1, 1, 0.8), 1.1 * U)
                                        cur = nxt
                # v0.2.7 the new kinds wear a small carved mark so the player
                # can PLAN: the dropper a down-chevron, the size platforms
                # outward arrows (both deterministic, subtle)
                if String(p["type"]) == "dropper":
                        var mc := Color(0, 0, 0, 0.30)
                        var my := sy + 1.0 * U
                        plat_layer.draw_line(Vector2(sx - 7.0 * U, my - 3.0 * U), Vector2(sx, my + 3.0 * U), mc, 2.2 * U)
                        plat_layer.draw_line(Vector2(sx + 7.0 * U, my - 3.0 * U), Vector2(sx, my + 3.0 * U), mc, 2.2 * U)
                if String(p["type"]) == "size":
                        var ac := Color(0, 0, 0, 0.26)
                        var ay := sy
                        plat_layer.draw_line(Vector2(left + 6.0 * U, ay), Vector2(left + 13.0 * U, ay - 4.0 * U), ac, 2.0 * U)
                        plat_layer.draw_line(Vector2(left + 6.0 * U, ay), Vector2(left + 13.0 * U, ay + 4.0 * U), ac, 2.0 * U)
                        plat_layer.draw_line(Vector2(left + w - 6.0 * U, ay), Vector2(left + w - 13.0 * U, ay - 4.0 * U), ac, 2.0 * U)
                        plat_layer.draw_line(Vector2(left + w - 6.0 * U, ay), Vector2(left + w - 13.0 * U, ay + 4.0 * U), ac, 2.0 * U)

func _draw_walls() -> void:
        # walls live in SCREEN space (they are the screen's frame) - drawn by
        # the game node itself (it is a Node2D in the world's parent, so its
        # local space = screen space)
        var vp := _vp()
        var w := WALL_W * U
        var p := _pal()
        for side in [0, 1]:
                var x := 0.0 if side == 0 else vp.x - w
                var col: Color = p["wall"]
                var flash: float = float(wall_flash["l" if side == 0 else "r"])
                var base := Rect2(x, 0, w, vp.y)
                walls_layer.draw_rect(base, col)
                # the bright INNER edge faces the play field (reads as ice)
                var edge_x := x + w - 5.0 * U if side == 0 else x
                walls_layer.draw_rect(Rect2(edge_x, 0, 5.0 * U, vp.y), p["wall_hi"])
                # icy streaks (deterministic, scroll SLOWLY with the camera)
                var rows := int(vp.y / (90.0 * U)) + 2
                var off := fmod(-cam_y * 0.12, 90.0 * U)
                for i in rows:
                        var yy := float(i) * 90.0 * U + off - 90.0 * U
                        var hh := (18.0 + _hashf(i, float(side) + 1.0) * 40.0) * U
                        walls_layer.draw_rect(Rect2(x + 4.0 * U, yy, w - 8.0 * U, hh), Color(1, 1, 1, 0.10))
                if flash > 0.0:
                        walls_layer.draw_rect(base, Color(1, 1, 1, flash * 1.4))

func _draw_clouds() -> void:
        # the drifting clouds (world y -> screen y), soft and few - the
        # owner's clean day
        var p := _pal()
        for cl in clouds:
                var cy2: float = float(cl["y"]) - cam_y
                var cw2: float = float(cl["w"])
                var col2: Color = p["cloud"]
                col2.a *= float(cl["a"])
                for i in 4:
                        var px2: float = float(cl["x"]) + (0.15 + 0.25 * float(i)) * cw2
                        var py2 := cy2 + (0.5 if i == 0 or i == 3 else 0.35) * cw2 * 0.3
                        var pr := cw2 * (0.16 + 0.07 * float(1 - (i % 2)))
                        cloud_layer.draw_circle(Vector2(px2, py2), pr, col2)

func _draw_sparks() -> void:
        # NIGHT SPARKS (v0.2.6): the particle half of the star-like lights -
        # a dozen slow glows that wander and breathe, only at night.
        if _place_id() != "night":
                return
        var vp := _vp()
        var t := _time
        for s in sparks:
                var bx: float = float(s["x"]) * vp.x
                var by: float = float(s["y"]) * vp.y
                var ph: float = float(s["ph"])
                var px3 := bx + sin(t * 0.23 * float(s["spd"]) + ph) * 26.0 * U
                var py3 := by + cos(t * 0.31 * float(s["spd"]) + ph * 1.7) * 18.0 * U
                var br := 0.5 + 0.5 * sin(t * float(s["spd"]) * 1.4 + ph * 3.1)
                if br < 0.12:
                        continue
                spark_layer.draw_circle(Vector2(px3, py3), float(s["r"]) * (1.0 + br),
                                Color(0.85, 0.92, 1.0, 0.5 * br))
                spark_layer.draw_circle(Vector2(px3, py3), float(s["r"]) * 2.6,
                                Color(0.7, 0.85, 1.0, 0.10 * br))

func _draw_snow() -> void:
        var p := _pal()
        for f in flakes:
                var col: Color = p["snow"]
                if bool(f["fore"]):
                        col.a = 0.55
                        snow_layer.draw_circle(Vector2(float(f["x"]), float(f["y"])), float(f["sz"]) * 1.7, col)
                else:
                        col.a = 0.75 + 0.25 * _hashf(int(float(f["ph"]) * 100.0), 3.0)
                        snow_layer.draw_circle(Vector2(float(f["x"]), float(f["y"])), float(f["sz"]), col)

## v0.2.7 THE PICKUP PAINTER - the round that made coins REAL. Coins and
## powerups were never drawn (the owner "magically collected" them). The
## coin wears the snake law (the REAL coin.png asset, a breathing pop) with
## the owner's FADE-IN; the powerup is a glass capsule with its glyph.
func _draw_pickups() -> void:
        var font := ThemeDB.fallback_font
        for c in coins:
                var t: float = float(c["t"])
                var fade: float = clampf(t / 0.35, 0.0, 1.0)          # THE FADE LAW
                var cy: float = float(c["y"]) + sin(t * 3.2) * 7.0 * U   # = the collect law
                var pos := Vector2(float(c["x"]), cy)
                pick_layer.draw_circle(pos, 30.0 * U, Color(1.0, 0.85, 0.3, 0.14 * fade))
                if _coin_tex != null:
                        var s: float = 46.0 * U / float(_coin_tex.get_width())
                        var pop: float = 1.0 + 0.07 * sin(t * 4.4)      # the snake breathing
                        pick_layer.draw_set_transform(pos, 0.0,
                                        Vector2(s * pop * fade, s / maxf(0.05, pop) * fade))
                        pick_layer.draw_texture(_coin_tex, -_coin_tex.get_size() / 2.0,
                                        Color(1, 1, 1, fade))
                        pick_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        for k in pickups:
                var t2: float = float(k["t"])
                var fade2: float = clampf(t2 / 0.35, 0.0, 1.0)
                var pos2 := Vector2(float(k["x"]),
                                float(k["y"]) + sin(t2 * 2.6) * 6.0 * U)
                var kind := String(k["kind"])
                var col2 := Color("4ac2e8")
                if kind == "big":
                        col2 = Color("f0b040")
                elif kind == "speed":
                        col2 = Color("58c470")
                elif kind == "slow":
                        col2 = Color("8a7ae8")
                var rr: float = 30.0 * U * (0.55 + 0.45 * fade2)
                pick_layer.draw_circle(pos2, rr + 9.0 * U,
                                Color(col2.r, col2.g, col2.b, 0.16 * fade2))
                pick_layer.draw_circle(pos2, rr, Color(0.06, 0.12, 0.20, 0.86 * fade2))
                pick_layer.draw_arc(pos2, rr, 0.0, TAU, 26,
                                Color(col2.r, col2.g, col2.b, fade2), 2.6 * U)
                pick_layer.draw_string(font, pos2 + Vector2(-rr, rr * 0.36),
                                POWERUPS[kind]["glyph"], HORIZONTAL_ALIGNMENT_CENTER,
                                rr * 2.0, int(24 * U), Color(1, 1, 1, fade2))

func _draw_fx() -> void:
        var font := ThemeDB.fallback_font
        for pt in parts:
                var a: float = clampf(float(pt["life"]) / float(pt["max"]), 0.0, 1.0)
                var col: Color = pt["col"]
                col.a *= a
                if String(pt["kind"]) == "ring":
                        fx.draw_arc(Vector2(float(pt["x"]), float(pt["y"])),
                                        float(pt["r"]) * (1.4 - a * 0.4), 0.0, TAU, 26, col, 3.0 * U)
                elif String(pt["kind"]) == "chunk":
                        # v0.2.7 the spinning break chunk (physical, fades out)
                        fx.draw_set_transform(Vector2(float(pt["x"]), float(pt["y"])),
                                        float(pt["rot"]), Vector2.ONE)
                        var cw: float = float(pt["w"])
                        var ch: float = float(pt["h"])
                        fx.draw_rect(Rect2(-cw * 0.5, -ch * 0.5, cw, ch), col)
                        var hi := col.lightened(0.25)
                        hi.a = col.a
                        fx.draw_rect(Rect2(-cw * 0.5, -ch * 0.5, cw, ch * 0.4), hi)
                        fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                else:
                        fx.draw_circle(Vector2(float(pt["x"]), float(pt["y"])), float(pt["r"]) * (0.6 + 0.4 * a), col)
        for pp in pops:
                var pa: float = clampf(float(pp["life"]) / 0.8, 0.0, 1.0)
                var col := Color(1, 1, 1, pa)
                fx.draw_string(font, Vector2(float(pp["x"]) - 40.0 * U, float(pp["y"])),
                                String(pp["txt"]), HORIZONTAL_ALIGNMENT_CENTER, 80.0 * U,
                                int(30 * U), col)

# ============================================================ the characters

func _draw_player() -> void:
        var R := PLAYER_R * U
        var load_f := snow_load
        var body: Color = _pal()["snow"]
        # every character keeps its EYES and loses the mouth (owner rule)
        match char_id:
                "ball":
                        # the snowball: white ball, a cool shaded bottom, snow rim
                        player.draw_circle(Vector2.ZERO, R, Color("8fa9bd"))
                        player.draw_circle(Vector2.ZERO, R - 3.0 * U, Color("dfe9f2"))
                        player.draw_circle(Vector2(0, R * 0.18), R * 0.86, body)
                        player.draw_circle(Vector2(-R * 0.28, -R * 0.3), R * 0.4, Color(1, 1, 1, 0.55))
                        if load_f > 0.03:
                                player.draw_arc(Vector2.ZERO, R * (0.86 + 0.12 * load_f),
                                                0.0, TAU, 30, Color(1, 1, 1, 0.85), (1.5 + 5.0 * load_f) * U)
                "square":
                        # the ice cube: rounded square of glass with an inner shine
                        var r := Rect2(-R * 0.92, -R * 0.92, R * 1.84, R * 1.84)
                        player.draw_rect(r, Color("bfe0ef"))
                        player.draw_rect(Rect2(r.position + Vector2(4, 4) * U, r.size - Vector2(8, 8) * U), Color("d8f0fa"))
                        player.draw_rect(Rect2(-R * 0.6, -R * 0.62, R * 0.5, R * 0.42), Color(1, 1, 1, 0.5))
                        if load_f > 0.03:
                                player.draw_rect(Rect2(-R * 0.98, -R * 0.98 - (2.0 + 5.0 * load_f) * U, R * 1.96, (3.0 + 5.0 * load_f) * U), Color(1, 1, 1, 0.9))
                "shard":
                        # the shard: a glassy triangle with a facet highlight
                        var pts := PackedVector2Array([Vector2(0, -R * 1.06), Vector2(R * 0.95, R * 0.78), Vector2(-R * 0.95, R * 0.78)])
                        player.draw_colored_polygon(pts, Color("a8dce8"))
                        var pts2 := PackedVector2Array([Vector2(0, -R * 1.06), Vector2(R * 0.95, R * 0.78), Vector2(R * 0.2, R * 0.78)])
                        player.draw_colored_polygon(pts2, Color("c8ecf4"))
                        if load_f > 0.03:
                                player.draw_arc(Vector2.ZERO, R * 0.95, PI, TAU, 16, Color(1, 1, 1, 0.8), (1.2 + 3.0 * load_f) * U)
                "egg":
                        # the egg: a cream ellipse that wobbles, snow sticks to it
                        player.draw_circle(Vector2.ZERO, R, Color("f2ead8"))
                        var pts := PackedVector2Array()
                        for i in 24:
                                var a := TAU * float(i) / 24.0
                                pts.append(Vector2(cos(a) * R * 0.88, sin(a) * R * 1.06))
                        player.draw_colored_polygon(pts, Color("f8f2e4"))
                        player.draw_circle(Vector2(-R * 0.3, -R * 0.42), R * 0.34, Color(1, 1, 1, 0.6))
                        if load_f > 0.03:
                                player.draw_arc(Vector2.ZERO, R * 1.02, 0.0, TAU, 30, Color(1, 1, 1, 0.85), (1.2 + 4.5 * load_f) * U)
        # THE EYES (all characters) - they look where you move
        var look := clampf(vx / (WALK_MAX * U), -1.0, 1.0) * R * 0.22
        var eye_y := -R * 0.18
        for s: float in [-1.0, 1.0]:
                var ex: float = s * R * 0.34 + look * 0.6
                player.draw_circle(Vector2(ex, eye_y), R * 0.2, Color.WHITE)
                player.draw_circle(Vector2(ex + look * 0.5, eye_y + R * 0.03), R * 0.1, Color("1a2430"))

# ============================================================ the controls
## v0.2.6 - THE OWNER'S OWN SCHEME, no buttons at all:
##   LEFT HALF  = the ANALOG move zone: the first touch lands anywhere
##                there and becomes the anchor; the finger's X offset from
##                it is the move force (dead point at the anchor, full
##                force at AXIS_FULL, left-right only, Y is ignored).
##   RIGHT HALF = TAP TO JUMP (one tap one jump; with x2 live, the mid-air
##                tap is the second jump). Multi-touch safe: the move zone
##                tracks ITS touch index, jump taps count their own.
## The old arrows + jump circle are gone - the circle shipped with a DEAD
## _gui_input (touch positions arrive LOCAL there; the old code subtracted
## global_position a second time, so every press landed far outside the
## circle and the jump button never worked). The probe drives the REAL
## input path now.

func _build_pw_widget() -> void:
        # the powerup widget ON TOP (the owner: "just put them in a widget
        # on top with the icon and the timer"): glyph + name + seconds and
        # a thin bar that drains over the 10s. The melt size rides the HUD
        # chip row next to the score.
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel",
                        Arc.panel_style(Color(0.05, 0.10, 0.18, 0.82), 18))
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 4)
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 8)
        _pw_glyph = Arc.label("", 24, Color("4ac2e8"))
        h.add_child(_pw_glyph)
        _pw_time_l = Arc.label("", 22, Color(0.9, 0.96, 1.0))
        h.add_child(_pw_time_l)
        v.add_child(h)
        var bar_holder := Control.new()
        bar_holder.custom_minimum_size = Vector2(_pw_bar_w, 5)
        _pw_bar = ColorRect.new()
        _pw_bar.color = Color("4ac2e8")
        _pw_bar.size = Vector2(_pw_bar_w, 5)
        bar_holder.add_child(_pw_bar)
        v.add_child(bar_holder)
        panel.add_child(v)
        # v0.2.7 THE OWNER'S SPOT: "make it to the left next to score" - the
        # widget sits top-LEFT under the HUD bar (it used to hover top-center).
        panel.anchor_left = 0.0
        panel.anchor_right = 0.0
        panel.anchor_top = 0.0
        panel.offset_left = 12.0
        panel.offset_right = 12.0 + _pw_bar_w + 36.0
        panel.offset_top = 92.0
        panel.visible = false
        panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
        panel.clip_contents = true
        _overlay_root_ref().add_child(panel)
        _pw_widget = panel

func _refresh_pw_ui() -> void:
        if _pw_widget == null or not is_instance_valid(_pw_widget):
                return
        var live := String(pw["id"])
        if live != "" and float(pw["t"]) > 0.0:
                _pw_widget.visible = true
                var col := Color("4ac2e8")
                if live == "big":
                        col = Color("f0b040")
                elif live == "speed":
                        col = Color("58c470")
                elif live == "slow":
                        col = Color("8a7ae8")
                _pw_glyph.text = "%s  %s" % [POWERUPS[live]["glyph"], POWERUPS[live]["name"]]
                _pw_glyph.add_theme_color_override("font_color", col)
                _pw_time_l.text = "%.1fs" % maxf(0.0, float(pw["t"]))
                _pw_bar.color = col
                var bar_w: float = _pw_bar_w
                if _pw_bar.get_parent() is Control:
                        bar_w = maxf(40.0, (_pw_bar.get_parent() as Control).size.x)
                _pw_bar.size = Vector2(bar_w * clampf(float(pw["t"]) / PW_TIME, 0.0, 1.0), 5)
        else:
                _pw_widget.visible = false
        # the MELT readout: its whole PANEL hides while melting is off (the
        # owner's empty-widget catch - it sat between speed and coins forever
        # blank; a hidden child takes no layout slot)
        if _melt_chip != null and is_instance_valid(_melt_chip):
                var mc_panel := _melt_chip.get_parent().get_parent() as Control
                if _melt_on():
                        if mc_panel != null:
                                mc_panel.visible = true
                        var starving: bool = grounded \
                                        and float(ground_plat.get("snow", 0.0)) <= 0.004
                        _melt_chip.text = "MELT x%.2f" % char_size
                        _melt_chip.add_theme_color_override("font_color",
                                        Color("7ab8e8") if starving else Color("f0b040"))
                else:
                        if mc_panel != null:
                                mc_panel.visible = false
                        _melt_chip.text = ""

## the raw input path (unhandled events): THE ZONES. NOTE: positions in the
## raw path are VIEWPORT coordinates (this is exactly why the old jump
## button died - inside _gui_input they are already LOCAL).
func _zone_input(e: InputEvent) -> void:
        var vp := _vp()
        if e is InputEventScreenTouch:
                var t := e as InputEventScreenTouch
                if t.pressed:
                        if t.position.x < vp.x * 0.5:
                                if move_touch == -1:
                                        move_touch = t.index
                                        move_anchor = t.position
                                        move_dir = 0.0
                        else:
                                jump_touches[t.index] = true
                                _do_jump()
                else:
                        if t.index == move_touch:
                                move_touch = -1
                                move_dir = 0.0
                        jump_touches.erase(t.index)
        elif e is InputEventScreenDrag:
                var d := e as InputEventScreenDrag
                if d.index == move_touch:
                        _set_axis(d.position.x - move_anchor.x)
        elif e is InputEventMouseButton \
                        and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
                # the desktop fallback (Xvfb QA + mouse play): the mouse IS
                # one finger - hold-drag on the left half drives the axis.
                var m := e as InputEventMouseButton
                if m.pressed:
                        if m.position.x < vp.x * 0.5:
                                if move_touch == -1:
                                        move_touch = 100
                                        move_anchor = m.position
                                        move_dir = 0.0
                                        mouse_move = true
                        else:
                                _do_jump()
                else:
                        if move_touch == 100 and mouse_move:
                                move_touch = -1
                                move_dir = 0.0
                                mouse_move = false
        elif e is InputEventMouseMotion and mouse_move:
                var mm := e as InputEventMouseMotion
                _set_axis(mm.position.x - move_anchor.x)

# ============================================================ ready / start

func _show_ready_card() -> void:
        phase = "ready"
        _shop_pair_down()
        var root := _overlay_root_ref()
        if _ready_card != null and is_instance_valid(_ready_card):
                _ready_card.queue_free()
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel",
                        Arc.panel_style(Color(0.05, 0.10, 0.18, 0.86), 24))
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 6)
        var t := Arc.label("TAP ANYWHERE TO START", 40, Color(0.85, 0.95, 1.0))
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        var s := Arc.label("touch LEFT + slide to move  -  tap RIGHT to jump  -  land HIGHER for +1  -  grab the coins + powerups", 18,
                        Color(0.85, 0.92, 1.0), false)
        s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        v.add_child(t)
        v.add_child(s)
        panel.add_child(v)
        cc.add_child(panel)
        root.add_child(cc)
        _ready_card = cc

## tap anywhere starts (the HUD buttons consume their own touches, so a
## shop press never starts the run - the dash law); once RUNNING the
## input IS the zones (the owner's v0.2.6 scheme). NOTE: no paused check -
## the probe harness (and the in-run shop's STOP dim) both guard the zones
## their own way; pause only stops the TICK, not the input plumbing.
func _goga_input(event: InputEvent) -> void:
        if over:
                return
        if phase == "ready":
                if event is InputEventScreenTouch \
                                and (event as InputEventScreenTouch).pressed:
                        _start()
                elif event is InputEventMouseButton \
                                and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT \
                                and (event as InputEventMouseButton).pressed:
                        _start()
                return
        if phase == "run":
                _zone_input(event)

func _start() -> void:
        if phase != "ready":
                return
        phase = "run"
        Jukebox.sfx("confirm", -6.0)
        if _ready_card != null and is_instance_valid(_ready_card):
                var cc := _ready_card
                _ready_card = null
                var tw := cc.create_tween()
                tw.tween_property(cc, "modulate:a", 0.0, 0.22)
                tw.tween_callback(cc.queue_free)

# ============================================================ the shop
## Same bones as the Space Dash shop (THE PAIR LAW - the sheet owns its
## dim+center pair and frees exactly that): CHARACTERS (skins), PLATFORM
## SKINS, PLACES (day/night), POWERUPS (they spawn in runs once bought).

func _shop_open() -> void:
        _shop_from = phase
        if phase == "run":
                paused = true
                get_tree().paused = true
        _shop_pair_down()
        var root := _overlay_root_ref()
        var sheet := Arc.sheet(root, 0.0)
        sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
        var kids := root.get_children()
        _shop_pair = [kids[kids.size() - 2], kids[kids.size() - 1]]
        var t := Arc.label("SNOWY TOWER SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := _vp()
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 300.0, 640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        box.add_child(_shop_label("CHARACTERS - each its own physics + spin"))
        for id in CHARS:
                box.add_child(_char_row(id))
        box.add_child(_shop_label("PLATFORM SKINS - real materials"))
        for id in PLATS:
                box.add_child(_plat_row(id))
        box.add_child(_shop_label("PLACES - day and night really differ"))
        for id in PLACES:
                box.add_child(_place_row(id))
        box.add_child(_shop_label("POWERUPS - they spawn in your runs"))
        for id in POWERUPS:
                box.add_child(_pw_row(id))
        box.add_child(_shop_label("MELTING - eat the snow under you, or shrink"))
        box.add_child(_melt_row())
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): _shop_close()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _shop_label(txt: String) -> Label:
        return Arc.fit_label(txt, 24, Arc.HOT, 560)

func _price_btn(txt: String, price: int, col: Color, cb: Callable) -> Button:
        var b := Arc.coin_button("%s  %d" % [txt, price], Vector2(560, 64), 22, col, cb)
        if Box.coins() < price:
                b.disabled = true
        return b

func _char_row(id: String) -> Control:
        var c: Dictionary = CHARS[id]
        var owned := Box.skin_owned(game_id, id) or int(c["price"]) == 0
        var on: bool = Box.skin_on(game_id) == id \
                        or (int(c["price"]) == 0 and Box.skin_on(game_id) == "")
        if on:
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"], c["desc"]], 22,
                                Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s - EQUIP" % c["name"],
                                Vector2(560, 60), 22, Color("4a5ab8"), func():
                                                Box.equip_skin(game_id, id)
                                                char_id = id
                                                Jukebox.sfx("confirm", -4.0)
                                                player.queue_redraw()
                                                _shop_open())
        return _price_btn(c["name"], int(c["price"]), Color("4a5ab8"), func():
                        if Box.buy_skin(game_id, id, int(c["price"])):
                                        char_id = id
                                        Jukebox.sfx("buy")
                                        player.queue_redraw()
                        _shop_open())

func _plat_row(id: String) -> Control:
        var pl: Dictionary = PLATS[id]
        var owned := Box.item_owned(game_id, "plat", id) or int(pl["price"]) == 0
        var on := _plat_id() == id \
                        or (int(pl["price"]) == 0 and Box.item_on(game_id, "plat") == "")
        if on:
                var l := Arc.fit_label("%s  (ON)" % pl["name"], 22, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button(pl["name"] + "  - EQUIP", Vector2(560, 60), 22,
                                Color("8a6a3a"), func():
                                                Box.equip_item(game_id, "plat", id)
                                                Jukebox.sfx("confirm", -4.0)
                                                plat_layer.queue_redraw()
                                                _shop_open())
        return _price_btn(pl["name"], int(pl["price"]), Color("8a6a3a"), func():
                        if Box.buy_item(game_id, "plat", id, int(pl["price"])):
                                        Jukebox.sfx("buy")
                                        plat_layer.queue_redraw()
                        _shop_open())

func _place_row(id: String) -> Control:
        var pl: Dictionary = PLACES[id]
        var owned := Box.item_owned(game_id, "place", id) or int(pl["price"]) == 0
        var on := _place_id() == id \
                        or (int(pl["price"]) == 0 and Box.item_on(game_id, "place") == "")
        if on:
                var l := Arc.fit_label("%s  (ON)" % pl["name"], 22, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button(pl["name"] + "  - EQUIP", Vector2(560, 60), 22,
                                Color("2a7a68"), func():
                                                Box.equip_item(game_id, "place", id)
                                                _apply_place(sky.material as ShaderMaterial)
                                                _day_night()
                                                Jukebox.sfx("confirm", -4.0)
                                                _shop_open())
        return _price_btn(pl["name"], int(pl["price"]), Color("2a7a68"), func():
                        if Box.buy_item(game_id, "place", id, int(pl["price"])):
                                        Jukebox.sfx("buy")
                                        _apply_place(sky.material as ShaderMaterial)
                                        _day_night()
                        _shop_open())

func _pw_row(id: String) -> Control:
        var w: Dictionary = POWERUPS[id]
        if Box.item_owned(game_id, "pw", id):
                var l := Arc.fit_label("%s  - SPAWNS IN RUNS" % w["name"], 22,
                                Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        return _price_btn(w["name"], int(w["price"]), Color("8a4ab8"), func():
                        if Box.buy_item(game_id, "pw", id, int(w["price"])):
                                        Jukebox.sfx("buy")
                        _shop_open())

## MELTING (v0.2.6): buy once, then it is a toggle - ON eats the snow
## under the character and grows it, OFF is the plain game.
func _melt_row() -> Control:
        if not Box.item_owned(game_id, "melt", "melt"):
                return _price_btn(MELT["name"], int(MELT["price"]), Color("c46a3a"), func():
                                if Box.buy_item(game_id, "melt", "melt", int(MELT["price"])):
                                                Box.equip_item(game_id, "melt", "on")
                                                Jukebox.sfx("buy")
                                _shop_open())
        if _melt_on():
                return Arc.button("%s  -  TURN OFF" % MELT["name"], Vector2(560, 60), 22,
                                Color("7a5a3a"), func():
                                                Box.equip_item(game_id, "melt", "off")
                                                Jukebox.sfx("confirm", -4.0)
                                                _shop_open())
        return Arc.button("%s  -  TURN ON" % MELT["name"], Vector2(560, 60), 22,
                        Color("c46a3a"), func():
                                        Box.equip_item(game_id, "melt", "on")
                                        Jukebox.sfx("confirm", -4.0)
                                        _shop_open())

func _shop_pair_down() -> void:
        for n in _shop_pair:
                if n != null and is_instance_valid(n):
                        n.queue_free()
        _shop_pair = []

func _shop_close() -> void:
        _shop_pair_down()
        if _shop_from == "run":
                get_tree().paused = false
                paused = false
        else:
                _show_ready_card()






