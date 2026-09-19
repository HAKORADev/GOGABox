extends GogaGame
## DEADLY WORM (v040-10) - the survival cross-section, rebuilt on the REAL
## study assets (tools/v0410_worm_art.py) and the REAL world law.
##
## THE OWNER'S V040-10 REPORT, WORKED TO THE BONE:
##   * THE WORLD LAW: "the original has too big underground and big sky
##     with too wide place, a place is likely x3-x4 the screen width...
##     camera follows worm" - the world is 3.2 screens wide, the sky 1.25
##     screens tall above the line, the dirt 1.4 screens tall below it,
##     and the camera follows the worm on BOTH axes (the original's own
##     deserts: bounds -1300..1300 wide, sky to -1184, dirt to +500).
##   * THE FULL-SCREEN LAW: W/H seat from the LIVE viewport (the box's
##     stretch law) - no brown fallback bars, ever.
##   * THE SPAWN LAW: everything spawns COMPLETELY off-camera and
##     despawns (record + sprite freed) once far outside it.
##   * THE FACING LAW: things art faces LEFT natively (flip when moving
##     right), the worm faces RIGHT (it rotates by its heading) - the
##     chronic backwards-body bug dies here for good.
##   * THE SCALE LAW (measured off the real gameplay video): humans
##     ~6.5% of the screen height, the worm head ~11%, the surface line
##     rides the upper-middle band, the underground worm is a DARK
##     SILHOUETTE dragging a dirt trail.
##   * THE ANIM LAW: humans wear their REAL 10-frame run cycles and the
##     step follows the speed (a sprinting human runs its legs faster).
##   * THE COIN LAW's honesty: collected wormCoins FREE their sprite
##     (v040-9's stuck coins), and a +1 chip pulse says where it went.
##   * THE TEN LEVELS: every worm caps at 10 levels; the curve is ~6x
##     slower ("i maxed the worm in two plays").
##   * THE BUTTON LAW: SHOP sits directly after BACK, WORMS after it.
##   * THE POWER-UP LAW: bought with real GOGACoins (the box coin).
##   * THE PLACE LAW: switching applies to the NEXT round (the active
##     run keeps its place).
##   * THE MUSIC LAW: every place has its own looping bed.

const S := "res://assets/games/deathworm/"

# ------------------------------------------------------------ the ten worms
# size  = the draw + hitbox scale (the original's 0.8..2.0 band)
# speed = x the base crawl (px/s at scale 1)
# power = bite damage per hit (vehicles' HP and the specials read it)
# hp    = the fixed health pool (never heals, the owner's law)
# maxlvl= 10 LEVELS for every worm (the owner: "worms should be 10
#         levels and not 5"); a maxed worm is EXACTLY x1.5 base
# price = wormCoins to unlock (0 = the starter); the chain gates it
const WORMS := [
        {"id": "w01", "name": "THE WORM", "size": 1.0, "speed": 1.0,
                "power": 1.0, "hp": 100, "maxlvl": 10, "price": 0,
                "special": "roar",
                "line": "the classic desert earthworm - balanced"},
        {"id": "w02", "name": "AQUA", "size": 0.9, "speed": 1.15,
                "power": 0.9, "hp": 90, "maxlvl": 10, "price": 250,
                "special": "surge",
                "line": "quick, light, fragile - a hunter's worm"},
        {"id": "w03", "name": "DUNE", "size": 1.1, "speed": 0.95,
                "power": 1.1, "hp": 115, "maxlvl": 10, "price": 600,
                "special": "geyser",
                "line": "heavy sand reaver, hits like a landslide"},
        {"id": "w04", "name": "IVORY", "size": 0.85, "speed": 1.25,
                "power": 0.95, "hp": 95, "maxlvl": 10, "price": 1100,
                "special": "ghost",
                "line": "the pale sprinter - hard to catch, hard to hit"},
        {"id": "w05", "name": "CRIMSON", "size": 1.0, "speed": 1.05,
                "power": 1.3, "hp": 105, "maxlvl": 10, "price": 1800,
                "special": "frenzy",
                "line": "the red bite - teeth sharper than the rest"},
        {"id": "w06", "name": "TITAN", "size": 1.4, "speed": 0.85,
                "power": 1.2, "hp": 145, "maxlvl": 10, "price": 2800,
                "special": "quake",
                "line": "the ground shakes where it swims"},
        {"id": "w07", "name": "VIPER", "size": 0.8, "speed": 1.35,
                "power": 1.0, "hp": 85, "maxlvl": 10, "price": 4200,
                "special": "venom",
                "line": "thin, fast, poisonous"},
        {"id": "w08", "name": "GOLIATH", "size": 1.5, "speed": 0.9,
                "power": 1.45, "hp": 160, "maxlvl": 10, "price": 6500,
                "special": "devour",
                "line": "the pit with a mouth"},
        {"id": "w09", "name": "WRAITH", "size": 0.95, "speed": 1.2,
                "power": 1.15, "hp": 100, "maxlvl": 10, "price": 9500,
                "special": "voidpull",
                "line": "the dusk crawler - the world bends toward it"},
        {"id": "w10", "name": "DRAGON", "size": 1.3, "speed": 1.1,
                "power": 1.6, "hp": 150, "maxlvl": 10, "price": 14000,
                "special": "firebreath",
                "line": "the last worm - it breathes what it hunts"},
]
const GROW_TOTAL := 1.5          # a maxed worm is x1.5 its base stats

# ------------------------------------------------------------ the five places
# Every place carries EXCLUSIVE things (the owner: "not just different
# views"): grip bends the steering, enemy_mult scales the foe speed,
# bullet_mult the shot speed, roots the underground crawl, loot the animal
# points, sparks/torches are baked hazards, spawn_tilt shifts the spawn
# table (machines/cops vs animals).
const PLACES := {
        "desert": {"name": "THE DUNES", "price": 0, "grip": 1.0,
                "enemy_mult": 1.0, "bullet_mult": 1.0, "roots": 1.0,
                "loot": 1.0, "hazard": "", "spawn_tilt": "",
                "note": "the classic hunt - balanced ground, balanced war"},
        "polar": {"name": "THE ICE", "price": 600, "grip": 0.78,
                "enemy_mult": 0.88, "bullet_mult": 1.0, "roots": 1.0,
                "loot": 1.0, "hazard": "snow", "spawn_tilt": "cold",
                "note": "frozen soil - the worm drifts, the cold slows the prey"},
        "city": {"name": "THE CITY", "price": 800, "grip": 1.0,
                "enemy_mult": 1.06, "bullet_mult": 1.25, "roots": 1.0,
                "loot": 1.0, "hazard": "sparks", "spawn_tilt": "machines",
                "note": "machines over meat - the subway rails bite the tail"},
        "jungle": {"name": "THE JUNGLE", "price": 700, "grip": 1.0,
                "enemy_mult": 1.0, "bullet_mult": 1.0, "roots": 0.85,
                "loot": 1.5, "hazard": "", "spawn_tilt": "meat",
                "note": "roots drag the dive, but every animal pays half more"},
        "medieval": {"name": "THE KINGDOM", "price": 900, "grip": 1.0,
                "enemy_mult": 1.08, "bullet_mult": 1.2, "roots": 1.0,
                "loot": 1.0, "hazard": "torches", "spawn_tilt": "war",
                "note": "stonier soil, faster arrows, burning posts on the wall"},
}

# ------------------------------------------------------------ the power-ups
# v040-10: bought FIRST with real GOGACOINS (the box coin - the owner:
# "the powerups should be bought using real GOGACoins and not the
# wormCoin"), then they spawn in-run every 60..120s among the unlocked.
const POWS := [
        {"k": "size", "name": "MEGAWORM", "price": 40, "dur": 25.0,
                "line": "grow x1.6 - eat the big ones whole"},
        {"k": "speed", "name": "ADRENALINE", "price": 40, "dur": 25.0,
                "line": "crawl x1.7 - the world crawls past you"},
        {"k": "ghost", "name": "GHOST SKIN", "price": 60, "dur": 8.0,
                "line": "nothing can touch you for a breath"},
        {"k": "magnet", "name": "HUNGER CALL", "price": 60, "dur": 10.0,
                "line": "the prey walks toward the mouth"},
        {"k": "frenzy", "name": "FRENZY", "price": 90, "dur": 25.0,
                "line": "the dash recovers twice as fast"},
        {"k": "shield", "name": "STONE SCALE", "price": 90, "dur": 0.0,
                "line": "the next hit that would hurt - doesn't"},
]

# ------------------------------------------------------------ the menu table
# points per thing (the owner's law: humans 1, land animals 3, ground
# animals 1 per 3; vehicles are destroyed, never eaten, and pay their own)
const POINTS := {
        "human": 1, "animal": 3, "ground": 1,          # ground pays per 3
        "car": 2, "truck": 3, "tank": 5, "btr": 4, "heli": 4,
        "plane": 5, "drone": 2, "ufo": 6, "launcher": 5,
}
# v040-12 THE HUNT LAW (the owner: "make humans give 1 HP and animals give
# 2 HP and under ground animals give 0.5 HP, the game will feel more fun")
# - eating FEEDS the worm's health now (capped at the max pool).
const HEAL := {
        "human": 1.0, "animal": 2.0, "ground": 0.5, "bird": 0.5,
}
# vehicle structural HP - v040-12 THE MASS LAW (the owner: "a tank can get
# up to 3-4 hits to get destroyed, same logic for other vehicles, depending
# on speed"): bites to break, by the machine's real toughness. Birds are
# EDIBLE, not vehicles - the mouth eats them out of the air.
const VEH_HP := {
        "car": 2, "truck": 3, "tank": 4, "btr": 3, "heli": 2,
        "plane": 2, "drone": 1, "ufo": 5, "launcher": 3,
}

# ------------------------------------------------------------ the world law
# THE LIVE CANVAS: W/H seat from the viewport in _goga_setup (the box's
# stretch law EXPANDS the design on any phone - the full-screen law).
var W := 1920.0
var H := 1080.0
var WORLD_W := 6144.0            # x3.2 the design width (the owner's band)
var SKY_H := 1350.0              # the sky: 1.25 screens above the line
var DIRT_H := 1512.0             # the dirt: 1.4 screens below the line
var SURFACE_Y := 1350.0          # the line the world pivots on (= SKY_H)

const BASE_SPEED := 340.0        # px/s at scale 1 underground
const AIR_G := 1500.0            # gravity above the surface
const TURN_RATE := 3.4           # rad/s at grip 1.0
# v040-12: the crust band widened - the worm cruising JUST under the line
# (head.y = SURFACE_Y + 10..50) is what "riding the surface" really is;
# the old 26px band missed most of the cruise and the mud-eating decay
# never engaged (the owner: "the mud eating is not working").
const LINE_BAND := 55.0          # the surface-line slowdown band
const LINE_SLOW := 0.62          #   the original's crawl-at-the-line law
const CAMP_MAX := 5.0            # v040-11 THE CAMPING LAW: seconds of
                                 #   continuous crust-riding until the
                                 #   crawl decays to a near-stop (x0.05)
const SEG_COUNT := 14            # the drawn chain (head + 14 + tail)
const EAT_R := 1.0               # mouth radius in head-widths
const SPECIAL_AT := 100          # one charge per 100 points
const SPECIAL_MAX := 2
# THE SCALE LAW v040-12 (the owner: "in original, worms were not that big,
# i mean currently i am playing with first worm, and it is too huge, in
# original they be much smaller, they still be fast as small worms, but
# they are also much weaker"): the head drops from 118 to 78 - the first
# worm reads ~7% of the screen (a whisker over the humans' 6.5%), the
# original's own ratio, and the whole chain follows the girth law.
const HEAD_H := 78.0             # the head draw height at scale 1
# THE FALL LAW v040-12 (the owner: "if fell on something, the gravity
# force is much higher than jumping to it bottom-to-top, like real life"):
# a bite delivered while FALLING onto the prey hits 2.5x; a bite rising
# from below lands at 0.7x; level bites at 1.0.
const FALL_DMG_MULT := 2.5
const RISE_DMG_MULT := 0.7

# ------------------------------------------------------------ run state
var meta: DWMeta
var state := "intro"             # intro / play / dead
var place_id := "desert"
var worm_i := 0                  # index into WORMS
var worm_d := {}                 # the live worm record (base + level mults)
var run_t := 0.0
var rng := RandomNumberGenerator.new()

# the worm's body: p[0] is the head, p[SEG_COUNT] the tail seat
var pts: Array[Vector2] = []
var vel := Vector2.ZERO
var heading := 0.0               # the head's travel angle (rad)
var mouth_open := true
var dash_t := 0.0                # dash time left
var dash_cd := 0.0               # dash cooldown left
var special_charges := 0
var special_score_base := 0      # the score the next charge counts from
var p_hp := 100.0
var p_hp_max := 100.0
var p_scale := 1.0
var p_speed := 1.0
var p_power := 1.0
var invuln_t := 0.0
var ghost_t := 0.0
var shield_on := false
var hit_cd := 0.0

# the run's books
var eaten_humans := 0
var eaten_animals := 0
var eaten_ground := 0
var ground_run := 0              # the per-3 counter for ground animals
var vehicles := 0
var eaten_all := 0               # every 10th edible drops a wormCoin
var wormcoins_run := 0

# world entities
var things: Array = []           # edibles + vehicles [{kind, x, y, ...}]
var shots: Array = []            # enemy shots
var coins_drops: Array = []      # the wormCoin drops
var pows_live: Array = []        # the power-up pickups
var fx: Array = []               # dirt/blood/sparks
var trail: Array = []            # the underground dirt trail [{x,y,t}]
var camp_t := 0.0                # v040-11: the crust-grind clock
# v040-11 THE TUNNEL PALETTES: the eaten-mud colors per place (core = the
# bitten dark, rim = the fresh-eaten lip)
const TUNNEL_COL := {
        "desert": {"core": Color(0.30, 0.20, 0.10), "rim": Color(0.58, 0.44, 0.24)},
        "polar": {"core": Color(0.22, 0.32, 0.44), "rim": Color(0.62, 0.76, 0.86)},
        "city": {"core": Color(0.20, 0.18, 0.20), "rim": Color(0.46, 0.44, 0.48)},
        "jungle": {"core": Color(0.13, 0.20, 0.10), "rim": Color(0.38, 0.52, 0.26)},
        "medieval": {"core": Color(0.26, 0.20, 0.16), "rim": Color(0.54, 0.45, 0.35)},
}
var cam_x := 0.0
var cam_y := 0.0
var spawn_t := 2.0
var pow_t := 0.0

# input (the hidden analog + the tap zones)
var move_ptr := -1
var move_vec := Vector2.ZERO
var steer_mag := 0.0

# drawing
var world: Node2D
var far_draw: Node2D
var tunnel_draw: Node2D
var ent_draw: Node2D
var worm_draw: Node2D
var fx_draw: Node2D
var worm_sprites: Array = []     # the chain's Sprite2Ds
var hp_lbl: Label = null
var wc_lbl: Label = null
var dash_chip: PanelContainer = null
var dash_arc: Line2D = null
var dash_lbl: Label = null
var sp_chip: PanelContainer = null
var sp_lbl: Label = null
var pow_chips := {}              # kind -> {panel, label}
var banners: Array = []          # [{msg, t, col}]
var shake := 0.0
var flash := 0.0

# the audit probe seat (qa probes read these)
var probe := false

# ===================================================================== setup
func _goga_setup() -> void:
        rng.randomize()
        meta = DWMeta.load_meta()
        # THE LIVE CANVAS LAW: the design seat is the REAL viewport - the
        # game owns every pixel of the screen (no brown bars, ever)
        var vp := get_viewport_rect().size
        W = vp.x
        H = vp.y
        WORLD_W = W * 3.2
        SKY_H = H * 1.25
        DIRT_H = H * 1.4
        SURFACE_Y = SKY_H
        # the deferred place law: the saved place applies NOW (the start of
        # a fresh round is the next round)
        place_id = meta.place()
        if not meta.owns_place(place_id):
                place_id = "desert"
        worm_i = 0
        for i in WORMS.size():
                if String(WORMS[i]["id"]) == String(meta.d.get("worm", "w01")):
                        worm_i = i
        _apply_worm()
        _build_world()
        _build_hud_extra()
        _reset_run()
        _goga_intro()

func _apply_worm() -> void:
        var w: Dictionary = WORMS[worm_i]
        var lvl := meta.lvl(String(w["id"]))
        var mult := pow(GROW_TOTAL, float(lvl - 1) / float(maxi(1, int(w["maxlvl"]) - 1)))
        worm_d = {
                "i": worm_i, "id": String(w["id"]), "name": String(w["name"]),
                "special": String(w["special"]),
                "size": float(w["size"]) * mult,
                "speed": float(w["speed"]) * mult,
                "power": float(w["power"]) * mult,
                "hp": float(w["hp"]) * mult,
                "lvl": lvl, "maxlvl": int(w["maxlvl"]),
        }

## the run's numbers reset (a fresh hunt)
func _reset_run() -> void:
        # the old run's sprites die with their records
        for th in things:
                if th.get("spr") != null and is_instance_valid(th["spr"]):
                        th["spr"].queue_free()
        for s in shots:
                if s.get("spr") != null and is_instance_valid(s["spr"]):
                        s["spr"].queue_free()
        for c in coins_drops:
                if c.get("spr") != null and is_instance_valid(c["spr"]):
                        c["spr"].queue_free()
        for pw in pows_live:
                if pw.get("spr") != null and is_instance_valid(pw["spr"]):
                        pw["spr"].queue_free()
        for f in fx:
                if is_instance_valid(f["spr"]):
                        f["spr"].queue_free()
        run_t = 0.0
        score = 0
        eaten_humans = 0
        eaten_animals = 0
        eaten_ground = 0
        ground_run = 0
        vehicles = 0
        eaten_all = 0
        wormcoins_run = 0
        special_charges = 0
        special_score_base = 0
        dash_t = 0.0
        dash_cd = 0.0
        invuln_t = 0.0
        ghost_t = 0.0
        shield_on = false
        hit_cd = 0.0
        p_scale = float(worm_d["size"])
        p_speed = float(worm_d["speed"])
        p_power = float(worm_d["power"])
        p_hp_max = float(worm_d["hp"])
        p_hp = p_hp_max
        heading = PI
        vel = Vector2(-BASE_SPEED * p_speed, 0.0)
        things.clear()
        shots.clear()
        coins_drops.clear()
        pows_live.clear()
        fx.clear()
        trail.clear()
        camp_t = 0.0
        spawn_t = 2.2
        pow_t = rng.randf_range(24.0, 40.0)
        cam_x = clampf(WORLD_W * 0.5 - W * 0.5, 0.0, maxf(0.0, WORLD_W - W))
        cam_y = clampf(SURFACE_Y - H * 0.6, 0.0, SURFACE_Y + DIRT_H - H)
        # the chain spawns mid-world underground
        var hx := WORLD_W * 0.5
        var hy := SURFACE_Y + H * 0.25
        pts.clear()
        for i in SEG_COUNT + 2:
                pts.append(Vector2(hx + float(i) * 26.0, hy))
        _seed_things()
        set_score(0)
        # the camera seats ITSELF before the first frame (the intro opens
        # on the horizon, not the top of the sky)
        if world != null and is_instance_valid(world):
                world.position = Vector2(-cam_x, -cam_y)
                if far_draw != null:
                        far_draw.position.x = cam_x * 0.14

## the place's bed - every place sings its own loop (the music law)
func _music_track() -> String:
        match place_id:
                "polar":
                        return "res://assets/audio/sfx/dw_music_ice.ogg"
                "city":
                        return "res://assets/audio/sfx/dw_music_city.ogg"
                "jungle":
                        return "res://assets/audio/sfx/dw_music_jungle.ogg"
                "medieval":
                        return "res://assets/audio/sfx/dw_music_kingdom.ogg"
                _:
                        return "res://assets/audio/sfx/dw_music_desert.ogg"

func _goga_intro() -> void:
        state = "intro"
        Jukebox.music(_music_track())
        _show_intro_sheet()

## THE LAYERED WORLD (the original's stack): the tiled sky, the far
## parallax strip, the tiled dirt, the surface road, the edge bounds and
## the buried decals - all REAL study layers, code-modified into ours.
func _build_world() -> void:
        world = Node2D.new()
        add_child(world)
        var p: Dictionary = PLACES[place_id]
        # ---- THE SKY: tiled to the sky's full height (1.25 screens)
        var sky_tex: Texture2D = load(S + "places/%s_sky.png" % place_id)
        var sh := float(sky_tex.get_height())
        var sky := Node2D.new()
        sky.name = "sky"
        # v040-11 THE FULL-SKY LAW: the sky texture STRETCHES to the whole
        # sky band (SURFACE_Y) - a short texture never leaves brown void
        # above the horizon (the film caught it: 540px of sky over a 1350px
        # sky band = the brown bar the owner banned in v040-9).
        var sky_k := SURFACE_Y / float(sky_tex.get_height())
        var n_sky := int(ceil(WORLD_W / (float(sky_tex.get_width()) \
                * minf(1.0, sky_k)))) + 1
        for i in n_sky:
                var sp := Sprite2D.new()
                sp.texture = sky_tex
                sp.centered = false
                sp.scale = Vector2(maxf(1.0, sky_k), sky_k)
                sp.position = Vector2(float(i) * float(sky_tex.get_width())
                        * maxf(1.0, sky_k), 0.0)
                sky.add_child(sp)
        world.add_child(sky)
        # ---- THE FAR STRIP: the original's own surface-props skyline
        # (tents, palms, sphinx, pyramids, ruins) rides just above the
        # road at its true scale - the horizon's jewelry row
        far_draw = Node2D.new()
        far_draw.name = "far"
        var far_tex: Texture2D = load(S + "places/%s_far.png" % place_id)
        var fh := float(far_tex.get_height())
        var fk := (H * 0.115) / fh
        var fw := float(far_tex.get_width()) * fk
        var n_far := int(ceil(WORLD_W / fw)) + 1
        for i in n_far:
                var sp2 := Sprite2D.new()
                sp2.texture = far_tex
                sp2.centered = false
                sp2.scale = Vector2.ONE * fk
                sp2.position = Vector2(float(i) * fw,
                        SURFACE_Y - fh * fk + 12.0)
                far_draw.add_child(sp2)
        world.add_child(far_draw)
        # ---- THE DIRT: v040-12 THE ONE-PIECE LAW (the owner: "the under
        # ground design is inaccurate, you used something like grid or
        # repeating them, the correct design from you should be one big
        # design for the whole place ground as one piece"): each place's
        # underground is ONE unique baked cross-section - strata, hollows,
        # roots, veins, bones - stretched to the world's real size. The
        # same-dirt-repeated-7-times look is dead.
        var dirt_tex: Texture2D = load(S + "places/%s_dirt_big.png"
                % place_id)
        var dirt := Sprite2D.new()
        dirt.texture = dirt_tex
        dirt.centered = false
        dirt.scale = Vector2(WORLD_W / float(dirt_tex.get_width()),
                DIRT_H / float(dirt_tex.get_height()))
        dirt.position = Vector2(0.0, SURFACE_Y)
        world.add_child(dirt)
        # ---- THE BURIED DECALS: the study's own tomb + bones, planted
        # at deterministic seats (our own dirt keeps the original's dead)
        var decs := ["places/dec_tomb.png", "places/dec_bones.png"]
        var dseed := rng.randi()
        for i in 7:
                var dpath: String = decs[i % decs.size()]
                if not ResourceLoader.exists(S + dpath):
                        continue
                var dc := Sprite2D.new()
                dc.texture = load(S + dpath)
                dc.rotation = float((dseed + i * 37) % 20 - 10) * 0.02
                var dk := rng.randf_range(0.5, 0.9)
                dc.scale = Vector2.ONE * dk
                dc.position = Vector2(
                        fposmod(float(dseed) * (float(i) + 1.3), WORLD_W),
                        SURFACE_Y + DIRT_H * rng.randf_range(0.3, 0.85))
                dc.modulate = Color(0.85, 0.82, 0.78, 1.0)
                world.add_child(dc)
        # ---- THE TUNNEL LAYER (v040-12 THE VISIBLE TUNNEL LAW): the
        # mud-eaten marks lived on the GAME node's _draw - which paints
        # UNDER the world's opaque dirt tiles (children draw over their
        # parent), so the trail was INVISIBLE the whole time (the owner:
        # "the dust trail is not working at all"). The tunnel now paints
        # on its own layer INSIDE the world, right on top of the dirt.
        tunnel_draw = Node2D.new()
        tunnel_draw.name = "tunnel"
        tunnel_draw.draw.connect(_draw_tunnel)
        world.add_child(tunnel_draw)
        # ---- THE ROAD: the surface line strip, tiled
        var road_tex: Texture2D = load(S + "places/%s_road.png" % place_id)
        var n_road := int(ceil(WORLD_W / float(road_tex.get_width()))) + 1
        var road := Node2D.new()
        for i in n_road:
                var sp4 := Sprite2D.new()
                sp4.texture = road_tex
                sp4.centered = false
                sp4.position = Vector2(
                        float(i) * float(road_tex.get_width()),
                        SURFACE_Y - float(road_tex.get_height()) * 0.5)
                road.add_child(sp4)
        world.add_child(road)
        # ---- THE BOUNDS: the level's edge walls (the original's own).
        # v040-12 THE FULL-HEIGHT WALL LAW (the owner: "walls should cover
        # from the bottom of the ground to the top of the sky with proper
        # look") + THE OCCLUDER LAW ("the things that spawn and move
        # through it should be hidden, i mean it should be on-top of them
        # accurately"): the walls span the WHOLE world height and ride a
        # node ABOVE the entities - anything sliding through an edge is
        # swallowed by the wall art, exactly like the original.
        var walls_top := Node2D.new()
        walls_top.name = "walls_top"
        for side in 2:
                var bnd := Sprite2D.new()
                bnd.texture = load(S + "places/%s_bound_%s.png"
                        % [place_id, "l" if side == 0 else "r"])
                bnd.centered = false
                bnd.flip_h = side == 1
                var bw := float(bnd.texture.get_width())
                var bh := float(bnd.texture.get_height())
                var bk := (SKY_H + DIRT_H) / bh
                bnd.scale = Vector2.ONE * bk
                bnd.position = Vector2(
                        (-bw * bk * 0.4) if side == 0
                        else (WORLD_W - bw * bk * 0.6),
                        0.0)
                bnd.name = "bound_" + ("l" if side == 0 else "r")
                walls_top.add_child(bnd)
        ent_draw = Node2D.new()
        world.add_child(ent_draw)
        worm_draw = Node2D.new()
        world.add_child(worm_draw)
        # THE OCCLUDER SEAT: the walls join the world ABOVE the worm and
        # the entities - they paint over anything that slides through them
        world.add_child(walls_top)
        fx_draw = Node2D.new()
        world.add_child(fx_draw)
        _build_worm_sprites()

## the chain's sprites: closed head, segments, tail - the REAL DragonBones
## parts (each worm's own skin), the head faces RIGHT (the rotation law)
func _build_worm_sprites() -> void:
        for s in worm_sprites:
                if is_instance_valid(s):
                        s.queue_free()
        worm_sprites.clear()
        var id := String(worm_d["id"])
        for i in SEG_COUNT + 2:
                var sp := Sprite2D.new()
                if i == 0:
                        sp.texture = load(S + "worms/%s_head.png" % id)
                elif i == SEG_COUNT + 1:
                        sp.texture = load(S + "worms/%s_tail.png" % id)
                else:
                        sp.texture = load(S + "worms/%s_body_%d.png"
                                % [id, (i - 1) % _seg_count_of(id)])
                sp.z_index = 20 - i
                worm_draw.add_child(sp)
                worm_sprites.append(sp)

## how many baked segment frames this worm carries (1..3)
func _seg_count_of(id: String) -> int:
        var n := 1
        while n < 3 and ResourceLoader.exists(
                        S + "worms/%s_body_%d.png" % [id, n]):
                n += 1
        return n

# =============================================================== the level math
## the worm's next level costs points eaten with it - v040-10's curve is
## ~6x the v040-9 one ("levelling up is too fast i maxed the worm in two
## plays"). Ten levels: 55 * lvl^1.5 a level, ~6.1K points to max.
func xp_need(lvl: int) -> int:
        return int(round(55.0 * pow(float(lvl), 1.5)))

## the next worm's stats preview (the worms menu's "next level" numbers)
func stats_at(w_i: int, lvl: int) -> Dictionary:
        var w: Dictionary = WORMS[w_i]
        var mult := pow(GROW_TOTAL, float(lvl - 1) / float(maxi(1, int(w["maxlvl"]) - 1)))
        return {
                "size": float(w["size"]) * mult,
                "speed": float(w["speed"]) * mult,
                "power": float(w["power"]) * mult,
                "hp": float(w["hp"]) * mult,
        }

# ==================================================================== spawning
## a calm opening: a few walkers so the first seconds already hunt
func _seed_things() -> void:
        for i in 3:
                _spawn_walker(true)
        _spawn_vehicle("car", true)

func _intensity() -> float:
        return 1.0 + run_t / 42.0

## THE CAMERA WINDOW (design px): everything spawns OUTSIDE it, everything
## despawns well beyond it - "the spawn area should be out of screen
## completely" + "when thing move out, it's body" dies
func _cam_rect() -> Rect2:
        return Rect2(cam_x, cam_y, W, H)

func _spawn_roll() -> void:
        # the table: [kind, weight] - the tilt shifts the mix per place
        var tilt := String(PLACES[place_id]["spawn_tilt"])
        var t := [{"k": "human", "w": 30}, {"k": "soldier", "w": 12},
                {"k": "bazooka", "w": 6}, {"k": "bird", "w": 10},
                {"k": "animal", "w": 12}, {"k": "car", "w": 6},
                {"k": "truck", "w": 4}, {"k": "tank", "w": 5},
                {"k": "heli", "w": 6}, {"k": "plane", "w": 3},
                {"k": "ground", "w": 14}, {"k": "ufo", "w": 2},
                {"k": "drone", "w": 3}]
        if tilt == "machines":
                t[6]["w"] += 6
                t[7]["w"] += 8
                t[9]["w"] += 4
                t[4]["w"] = 4
        elif tilt == "meat":
                t[4]["w"] += 12
                t[10]["w"] += 8
        elif tilt == "war":
                t[1]["w"] += 10
                t[2]["w"] += 6
                t[7]["w"] += 6
        elif tilt == "cold":
                t[4]["w"] += 6          # penguins, bears, yetis
        var total := 0
        for e in t:
                total += int(e["w"])
        var roll := rng.randi_range(1, total)
        var pick := "human"
        for e in t:
                roll -= int(e["w"])
                if roll <= 0:
                        pick = String(e["k"])
                        break
        match pick:
                "human": _spawn_walker(false)
                "soldier": _spawn_walker(false, "soldier")
                "bazooka": _spawn_walker(false, "bazooka")
                "bird": _spawn_flyer("bird")
                "heli": _spawn_flyer("heli")
                "plane": _spawn_flyer("plane")
                "drone": _spawn_flyer("drone")
                "ufo": _spawn_flyer("ufo")
                "ground": _spawn_digger()
                "animal": _spawn_animal()
                _: _spawn_vehicle(pick, false)

## a surface human - the REAL run cycles (10-frame runs from the study).
## THE OFF-SCREEN LAW: the spawn seat rides JUST outside the camera
## window on the x axis, never inside it.
func _spawn_walker(calm: bool, force := "") -> void:
        var kind := force
        if kind == "":
                var humans := ["casual1", "casual2", "casual3", "arab",
                        "woman", "punk"]
                if place_id == "city":
                        humans = ["police", "police", "casual1", "casual2",
                                "woman"]
                elif place_id == "jungle":
                        humans = ["jungle1", "jungle2", "casual1"]
                elif place_id == "polar":
                        humans = ["polar1", "polar2", "casual1"]
                elif place_id == "medieval":
                        humans = ["arab", "punk", "woman"]
                kind = humans[rng.randi_range(0, humans.size() - 1)]
        var from_right := rng.randf() < 0.5
        var x := (cam_x + W + 90.0) if from_right else (cam_x - 90.0)
        var fr := walk_frames(kind)
        if fr.is_empty():
                fr = walk_frames("casual1")
        things.append({
                "kind": "human", "skin": kind, "x": x,
                "y": _surf_seat("human"),
                "vx": (rng.randf_range(52.0, 110.0)
                        * (-1.0 if from_right else 1.0)
                        * float(PLACES[place_id]["enemy_mult"])),
                "fr": fr, "fi": rng.randi_range(0, fr.size() - 1),
                "ft": 0.0, "alive": true, "flee": 0.0,
        })

## the walk frames: the study's real runs, cached per skin
var _fr_cache := {}
func walk_frames(skin: String) -> Array:
        if _fr_cache.has(skin):
                return _fr_cache[skin]
        var out: Array = []
        var i := 0
        while i < 24:
                var p := S + "things/humans/%s_%02d.png" % [skin, i]
                if not ResourceLoader.exists(p):
                        break
                out.append(load(p))
                i += 1
        _fr_cache[skin] = out
        return out

## an air thing: bird / heli / plane / drone / ufo - the REAL fly cycles
## (the heli's rotor and the planes' props are IN the frames)
func _spawn_flyer(kind: String) -> void:
        var from_right := rng.randf() < 0.5
        var x := (cam_x + W + 120.0) if from_right else (cam_x - 120.0)
        var y := 0.0
        var vx := 0.0
        match kind:
                "bird":
                        y = SURFACE_Y - rng.randf_range(160.0, SKY_H * 0.55)
                        vx = rng.randf_range(150.0, 230.0)
                "heli":
                        y = SURFACE_Y - rng.randf_range(200.0, SKY_H * 0.62)
                        vx = rng.randf_range(90.0, 130.0)
                "plane":
                        y = SURFACE_Y - rng.randf_range(260.0, SKY_H * 0.72)
                        vx = rng.randf_range(260.0, 330.0)
                "drone":
                        y = SURFACE_Y - rng.randf_range(160.0, SKY_H * 0.5)
                        vx = rng.randf_range(60.0, 100.0)
                "ufo":
                        y = SURFACE_Y - rng.randf_range(220.0, SKY_H * 0.66)
                        vx = rng.randf_range(70.0, 110.0)
        vx *= (-1.0 if from_right else 1.0) * float(PLACES[place_id]["enemy_mult"])
        things.append({
                "kind": kind, "x": x, "y": y, "vx": vx, "vy": 0.0,
                "hp": int(VEH_HP.get(kind, 1)), "alive": true,
                "shoot_t": rng.randf_range(1.2, 3.0) / _intensity(),
                "bob": rng.randf_range(0.0, TAU),
                "frame": 0.0,
        })

## a ground vehicle: car / truck / tank / btr / launcher (tanks+shoot)
func _spawn_vehicle(kind: String, calm: bool) -> void:
        var from_right := rng.randf() < 0.5
        var x := (cam_x + W + 140.0) if from_right else (cam_x - 140.0)
        var spd := 0.0
        match kind:
                "car": spd = rng.randf_range(150.0, 200.0)
                "truck": spd = rng.randf_range(90.0, 130.0)
                "tank": spd = rng.randf_range(50.0, 80.0)
                "btr": spd = rng.randf_range(80.0, 120.0)
                "launcher": spd = rng.randf_range(60.0, 90.0)
        spd *= float(PLACES[place_id]["enemy_mult"])
        things.append({
                "kind": kind, "x": x, "y": _surf_seat(kind),
                "vx": spd * (-1.0 if from_right else 1.0),
                "hp": int(VEH_HP[kind]), "alive": true,
                "shoot_t": rng.randf_range(2.0, 4.5), "wheel_t": 0.0,
                "bob": 0.0, "frame": 0.0,
        })

## a land animal on the surface line - the place's own cast wearing its
## REAL run frames (the v040-9 latent crash: "animal" rolls fell into
## the vehicle spawner and died on the missing table key)
func _spawn_animal() -> void:
        var skin := _animal_skin()
        var from_right := rng.randf() < 0.5
        var x := (cam_x + W + 110.0) if from_right else (cam_x - 110.0)
        things.append({
                "kind": "animal", "skin": skin, "x": x,
                "y": _surf_seat("animal"),
                "vx": rng.randf_range(80.0, 150.0)
                        * (-1.0 if from_right else 1.0)
                        * float(PLACES[place_id]["enemy_mult"]),
                "alive": true, "ft": 0.0, "frame": 0.0,
        })

## the underground animals (the mole and the lizard) - the owner's
## "ground animals under the ground" - they pay 1 per 3
func _spawn_digger() -> void:
        var kind := "mole" if rng.randf() < 0.55 else "lizard"
        var from_right := rng.randf() < 0.5
        var x := (cam_x + W + 100.0) if from_right else (cam_x - 100.0)
        var y := rng.randf_range(SURFACE_Y + 120.0,
                SURFACE_Y + DIRT_H - 90.0)
        things.append({
                "kind": "ground", "skin": kind, "x": x, "y": y,
                "vx": rng.randf_range(70.0, 120.0)
                        * (-1.0 if from_right else 1.0),
                "vy": 0.0, "alive": true, "wob": rng.randf_range(0.0, TAU),
                "frame": 0.0,
        })

# ================================================================ the tick
func _process(delta: float) -> void:
        if paused or over:
                return
        if state == "play":
                run_t += delta
                _tick_worm(delta)
                _tick_things(delta)
                _tick_shots(delta)
                _tick_drops(delta)
                _tick_pows(delta)
                _tick_spawn(delta)
                _tick_fx(delta)
                _tick_hud()
                _tick_camera(delta)
                _place_flavor(delta)
                if p_hp <= 0.0:
                        _die()
        _tick_banners(delta)
        if fx_draw != null:
                fx_draw.queue_redraw()
        if ent_draw != null:
                ent_draw.queue_redraw()
        if tunnel_draw != null and not trail.is_empty():
                tunnel_draw.queue_redraw()

## THE WORM PHYSICS - the heart. The head drives, the chain follows.
func _tick_worm(delta: float) -> void:
        var grip := float(PLACES[place_id]["grip"])
        var on_line := absf(pts[0].y - SURFACE_Y) < LINE_BAND
        var underground := pts[0].y > SURFACE_Y + 4.0
        # the steering: the hidden analog bends the heading (the original's
        # control feel); the grip scales it (ice drifts)
        var turn := TURN_RATE * grip * delta
        if steer_mag > 0.0 and move_vec.length() > 0.08:
                var want := move_vec.angle()
                var d := wrapf(want - heading, -PI, PI)
                heading += clampf(d, -turn, turn)
                vel = vel.rotated(clampf(d, -turn, turn) * 0.4)
        # the speed: base * worm speed, the surface line drags (the law),
        # the dash bursts, the jungle roots drag underground
        var base := BASE_SPEED * p_speed
        if pts[0].y < SURFACE_Y - 10.0:
                base *= 0.86                      # air is freer but lighter
        # v040-11 THE SURFACE CAMPING LAW (the owner: "the original has
        # the eating ground surface speed slow-down-till-stop - it exists
        # to prevent players from living on the surface and eating every
        # single thing"): riding the crust crawls (LINE_SLOW) AND keeps
        # decaying toward a near-stop the longer the worm grinds along it;
        # a dive underground washes the grind off, and the dash scours it
        # in one burst.
        if on_line and dash_t <= 0.0:
                camp_t = minf(CAMP_MAX, camp_t + delta)
        else:
                camp_t = maxf(0.0, camp_t - delta * 2.2)
        if on_line:
                var grind := lerpf(1.0, 0.05, camp_t / CAMP_MAX)
                base *= LINE_SLOW * grind         # the original's law, both halves
        if underground and float(PLACES[place_id]["roots"]) < 1.0:
                base *= float(PLACES[place_id]["roots"])
        if dash_t > 0.0:
                base *= 2.6
                camp_t = 0.0
        var dir := Vector2(cos(heading), sin(heading))
        if pts[0].y < SURFACE_Y - 10.0:
                # air: gravity owns the body, heading follows velocity
                vel.y += AIR_G * delta
                vel.x = vel.x * (1.0 - 0.25 * delta)
                vel = vel.limit_length(base * 1.9)
                heading = vel.angle()
        else:
                vel = vel.lerp(dir * base, 1.0 - pow(0.02, delta))
                vel = vel.limit_length(base)
        var head := pts[0] + vel * delta
        # the world's bounds (wide, not endless - the rock walls hold)
        var r := _head_r()
        head.x = clampf(head.x, r + 70.0, WORLD_W - r - 70.0)
        if head.y < 40.0 + r:
                head.y = 40.0 + r
                vel.y = maxf(vel.y, 40.0)
        if head.y > SURFACE_Y + DIRT_H - r * 0.4:
                head.y = SURFACE_Y + DIRT_H - r * 0.4
                vel.y = minf(vel.y, -40.0)
        pts[0] = head
        # the chain: each node follows the one before (the swim)
        var seg_gap := _seg_gap()
        for i in range(1, pts.size()):
                var prev: Vector2 = pts[i - 1]
                var cur: Vector2 = pts[i]
                var dv := cur - prev
                var dl := dv.length()
                if dl > seg_gap:
                        pts[i] = prev + dv / dl * seg_gap
                elif dl < seg_gap * 0.5:
                        pts[i] = prev - dv.normalized() * seg_gap * 0.5
        # the mouth: open when moving fast or when prey is near
        mouth_open = vel.length() > base * 0.5 or _prey_near()
        # the clocks
        if dash_t > 0.0:
                dash_t -= delta
                if rng.randf() < 0.6:
                        _push_fx("dirt", pts[0].x, pts[0].y,
                                rng.randf_range(-40.0, 40.0),
                                rng.randf_range(-60.0, -10.0), 0.5)
        if dash_cd > 0.0:
                dash_cd -= delta
        if invuln_t > 0.0:
                invuln_t -= delta
        if ghost_t > 0.0:
                ghost_t -= delta
        if hit_cd > 0.0:
                hit_cd -= delta
        # THE MUD-EATEN TUNNEL (v040-11, the owner: "the original has a
        # cool thing for the underground where the worm leaves marks like
        # it ATE the mud, in proper way and different coloring and VFXs
        # based on place"): the tunnel lives 6s, wears the PLACE'S OWN
        # dirt colors, and carries its own deterministic flecks.
        if underground:
                trail.append({"x": pts[0].x, "y": pts[0].y, "t": 6.0,
                        "s": rng.randf()})
                if trail.size() > 260:
                        trail.pop_front()
        for tr in trail:
                tr["t"] -= delta
        trail = trail.filter(func(t): return float(t["t"]) > 0.0)
        _place_worm_sprites(underground)
        _eat_check()

func _head_r() -> float:
        return HEAD_H * 0.42 * p_scale

## the chain's seat: half a head-width per node (the real anatomy's law
## - the segments overlap into one continuous body)
func _seg_gap() -> float:
        return HEAD_H * 0.5 * p_scale

## is anything edible close enough to lunge at?
func _prey_near() -> bool:
        var out_r := _head_r() * (EAT_R + 1.6)
        for th in things:
                if not bool(th["alive"]):
                        continue
                var k := String(th["kind"])
                if k == "human" or k == "animal" or k == "ground":
                        if Vector2(float(th["x"]), float(th["y"])).distance_to(pts[0]) < out_r:
                                return true
        return false

## paint the chain: each node rides its point, rotated by its travel.
## THE FACING LAW: the worm art faces RIGHT; the chain rotates by its
## heading and flips V (never H) when traveling left - the back stays up.
## THE SILHOUETTE LAW: the deeper the worm swims, the darker it goes (the
## original's underground read).
func _place_worm_sprites(underground: bool) -> void:
        var id := String(worm_d["id"])
        var depth_dark := 0.0
        if underground:
                depth_dark = clampf((pts[0].y - SURFACE_Y)
                        / (H * 0.22), 0.0, 1.0) * 0.82
        var ghost_a := 0.62 if ghost_t > 0.0 else 1.0
        for i in worm_sprites.size():
                var sp: Sprite2D = worm_sprites[i]
                # the chain lives INSIDE world (world itself translates by
                # the camera) - the paint is the raw world seat; subtracting
                # the camera here doubled the offset and threw the worm off
                # every moved screen (the v040-9 render bug, hidden then by
                # the tiny 192px camera range)
                sp.position = Vector2(pts[i].x, pts[i].y)
                var ang := heading
                if i > 0:
                        ang = (pts[i - 1] - pts[i]).angle()
                sp.rotation = ang
                # v040-12 THE NO-FLIP LAW (the owner: "worm body when switch
                # sides, the worm head and body parts really get flipped
                # instantly, it actually should not, it is ok for a worm to
                # be upside down ofc"): the chain ROTATES continuously and
                # nothing mirrors - crossing the vertical just leaves the
                # worm upside down for a beat, like a real swimmer.
                # THE GIRTH LAW (the video's own read): every piece draws
                # at the worm's girth - the head at HEAD_H, the body a
                # breath slimmer, the tail tapered - whatever the source
                # part's native size was
                var tex: Texture2D = sp.texture
                var target_h := HEAD_H * p_scale
                if i == worm_sprites.size() - 1:
                        target_h *= 0.6
                elif i > 0:
                        target_h *= 0.92
                var k := target_h / maxf(1.0, float(tex.get_height()))
                sp.scale = Vector2.ONE * k
                var dark := 1.0 - depth_dark
                sp.modulate = Color(dark, dark, dark * 1.04, ghost_a)
                if i == 0:
                        # closed = the plain head; open = the open variant
                        var want_path: String
                        if mouth_open:
                                want_path = S + "worms/%s_head_open.png" % id
                        else:
                                want_path = S + "worms/%s_head.png" % id
                        if sp.texture.resource_path != want_path:
                                sp.texture = load(want_path)

## THE MOUTH LAW v040-12 - overlap = eat (edibles) or bite (vehicles):
## THE SURFACE GATE: the mouth must be OUT of the dirt to eat the surface
## world (the owner: "the people/vehicles on the surface are actually under
## the surface... i could eat everything without going out of the ground")
## - the head's tip must break the line for humans/animals/birds.
func _eat_check() -> void:
        var hr := _head_r() * EAT_R
        var mouth := pts[0] + Vector2(cos(heading), sin(heading)) * hr * 0.4
        var mouth_out := mouth.y < SURFACE_Y + _head_r() * 0.15
        # THE FALL LAW: the bite's real force - falling onto prey weighs
        # 2.5x, rising from below only 0.7x (like real life - the gravity
        # axis decides, wherever the worm is)
        var bite_mult := 1.0
        if vel.y > 140.0:
                bite_mult = FALL_DMG_MULT
        elif vel.y < -140.0:
                bite_mult = RISE_DMG_MULT
        for th in things:
                if not bool(th["alive"]):
                        continue
                var k := String(th["kind"])
                var tp := Vector2(float(th["x"]), float(th["y"]))
                var rad := _thing_r(th)
                if mouth.distance_to(tp) > hr + rad:
                        continue
                if k == "human":
                        if not mouth_out:
                                continue
                        th["alive"] = false
                        eaten_humans += 1
                        _eaten_book(POINTS["human"], "human", tp)
                elif k == "animal":
                        if not mouth_out:
                                continue
                        th["alive"] = false
                        eaten_animals += 1
                        _eaten_book(int(POINTS["animal"]
                                * float(PLACES[place_id]["loot"])), "animal", tp)
                elif k == "ground":
                        th["alive"] = false
                        eaten_ground += 1
                        ground_run += 1
                        # v040-12: EVERY digger heals its 0.5 - the per-3
                        # gate only gates the SCORE payout
                        p_hp = minf(p_hp_max, p_hp + float(HEAL["ground"]))
                        if ground_run >= 3:
                                ground_run -= 3
                                _eaten_book(POINTS["ground"], "ground", tp)
                        else:
                                _push_fx("gut", tp.x, tp.y, 0.0, -30.0, 0.4)
                elif k == "bird":
                        # the bird is a SNACK - snapped out of the air
                        th["alive"] = false
                        eaten_animals += 1
                        _eaten_book(1, "animal", tp)
                elif VEH_HP.has(k):
                        # vehicles are BITTEN, not eaten - the bite's own
                        # force (the FALL LAW) breaks them
                        th["hp"] = int(th["hp"]) \
                                - maxi(1, int(round(p_power * bite_mult)))
                        _push_fx("spark", tp.x, tp.y, 0.0, -40.0, 0.35)
                        Jukebox.sfx("dw_bite", -8.0,
                                rng.randf_range(0.9, 1.15))
                        if int(th["hp"]) <= 0:
                                th["alive"] = false
                                vehicles += 1
                                _eaten_book(int(POINTS[k]), "vehicle", tp)
                                _explode(tp, 1.2)

## THE REAL BITE (the owner: "make it bite for real, currently things get
## vanished when eaten, not realistic enough"): the prey tears into gibs
## and blood spray at the mouth - nothing just pops out of existence.
func _bite_fx(at: Vector2) -> void:
        for i in 6:
                var a := rng.randf_range(0.0, TAU)
                var spd := rng.randf_range(70.0, 260.0)
                _push_fx("gib", at.x, at.y, cos(a) * spd,
                        sin(a) * spd - 120.0, rng.randf_range(0.4, 0.8))
        for i in 4:
                _push_fx("blood", at.x, at.y,
                        rng.randf_range(-90.0, 90.0),
                        rng.randf_range(-160.0, -40.0), 0.6)
        Jukebox.sfx("dw_chomp", -4.0, rng.randf_range(0.9, 1.2))

## the shared book: points, THE HUNT LAW's heal, the coin law (every 10th
## edible), the charge law
func _eaten_book(points: int, cat: String, at: Vector2) -> void:
        if points > 0:
                add_score(points)
                _gain_xp(points)
        # v040-12 THE HUNT LAW: eating feeds the worm - humans 1 HP,
        # animals 2, underground animals 0.5 (the ground's 0.5 heals at
        # the bite site - the per-3 score gate must not gate the heal)
        if HEAL.has(cat) and cat != "ground":
                p_hp = minf(p_hp_max, p_hp + float(HEAL[cat]))
        _bite_fx(at)
        if cat != "vehicle":
                eaten_all += 1
                if eaten_all % 10 == 0:
                        # THE COIN LAW: every 10 eaten drops a wormCoin
                        coins_drops.append({
                                "x": at.x, "y": at.y - 20.0, "t": 0.0,
                        })
        # THE CHARGE LAW: one special charge per 100 points
        while score - special_score_base >= SPECIAL_AT:
                special_score_base += SPECIAL_AT
                if special_charges < SPECIAL_MAX:
                        special_charges += 1
                        _banner("SPECIAL READY", Color("ffd76a"))
                        Jukebox.sfx("dw_power", -6.0)

## eating feeds the worm's persistent level (x1.5 at max)
func _gain_xp(points: int) -> void:
        var id := String(worm_d["id"])
        var lvl := int(worm_d["lvl"])
        var need := xp_need(lvl)
        var xp_now := meta.xp(id) + points
        while xp_now >= need and lvl < int(worm_d["maxlvl"]):
                xp_now -= need
                lvl += 1
                need = xp_need(lvl)
                _banner("%s REACHED LVL %d" % [String(worm_d["name"]), lvl],
                        Color("ffd76a"))
                Jukebox.sfx("dw_level", -4.0)
                # the stats grow LIVE (the owner: x1.5 while it levels up)
                _apply_worm_live(lvl)
        meta.set_level(id, lvl, xp_now)
        worm_d["lvl"] = lvl

func _apply_worm_live(lvl: int) -> void:
        var w: Dictionary = WORMS[worm_i]
        var mult := pow(GROW_TOTAL, float(lvl - 1) / float(maxi(1, int(w["maxlvl"]) - 1)))
        var hp_was := p_hp / maxf(1.0, p_hp_max)
        p_scale = float(w["size"]) * mult
        p_speed = float(w["speed"]) * mult
        p_power = float(w["power"]) * mult
        p_hp_max = float(w["hp"]) * mult
        p_hp = p_hp_max * hp_was

# ================================================================ the things
func _thing_r(th: Dictionary) -> float:
        match String(th["kind"]):
                "human": return 22.0
                "animal": return 30.0
                "ground": return 24.0
                "car": return 52.0
                "truck": return 70.0
                "tank": return 96.0
                "btr": return 70.0
                "heli": return 92.0
                "plane": return 96.0
                "drone": return 60.0
                "ufo": return 52.0
                "launcher": return 62.0
        return 30.0

## THE SURFACE SEAT (v040-12): feet ON the line - the old constant +34/+38
## offsets buried everything waist-deep into the dirt (the owner: "the
## people/vehicles on the surface, they are actually under the surface,
## they literally overlapping with the surface top and the under ground").
func _surf_seat(kind: String) -> float:
        var half := H * 0.085 * 0.5
        match kind:
                "human":
                        half = H * 0.065 * 0.5
                "animal":
                        half = H * 0.085 * 0.5
                "tank":
                        half = H * 0.1 * 0.5
                "heli", "plane":
                        half = H * 0.1 * 0.5
        # a hair sunk into the crust - standing ON the ground, not on stilts
        return SURFACE_Y - half + half * 0.18

func _tick_things(delta: float) -> void:
        var im := _intensity()
        var cam := _cam_rect()
        for th in things:
                if not bool(th["alive"]):
                        if th.get("spr") != null and is_instance_valid(th["spr"]):
                                th["spr"].queue_free()
                        th["spr"] = null
                        continue
                var k := String(th["kind"])
                var tp := Vector2(float(th["x"]), float(th["y"]))
                match k:
                        "human":
                                # walkers stroll; they FLEE when the worm
                                # surfaces close (the original's panic);
                                # THE ANIM LAW: the legs keep pace with the
                                # body - the step shortens as the speed grows
                                var wp := pts[0]
                                if wp.y > SURFACE_Y - 30.0 \
                                                and wp.distance_to(tp) < 340.0:
                                        var away := (tp - wp).normalized()
                                        th["x"] = float(th["x"]) \
                                                + away.x * 150.0 * delta
                                        th["flee"] = 0.6
                                th["x"] = float(th["x"]) \
                                        + float(th["vx"]) * delta
                                var spd := absf(float(th["vx"]))
                                var fleeing: bool = float(th.get("flee", 0.0)) > 0.0
                                var step := 0.09 * (68.0 / maxf(20.0, spd))
                                if fleeing:
                                        step *= 0.7
                                th["ft"] = float(th["ft"]) + delta
                                if float(th["ft"]) > step:
                                        th["ft"] = 0.0
                                        var fr: Array = th["fr"]
                                        th["fi"] = (int(th["fi"]) + 1) \
                                                % fr.size()
                                th["y"] = _surf_seat("human")
                        "animal":
                                # land animals wander the surface line -
                                # the REAL run frames, pace-matched
                                th["x"] = float(th["x"]) \
                                        + float(th["vx"]) * delta
                                if rng.randf() < 0.004:
                                        th["vx"] = -float(th["vx"])
                                th["ft"] = float(th.get("ft", 0.0)) + delta
                                var aspd := absf(float(th["vx"]))
                                if float(th["ft"]) > 0.085 \
                                                * (110.0 / maxf(30.0, aspd)):
                                        th["ft"] = 0.0
                                        th["frame"] = float(int(
                                                float(th.get("frame", 0.0))
                                                + 1.0))
                                th["y"] = _surf_seat("animal")
                        "ground":
                                # diggers roam the underground, wobbling
                                th["x"] = float(th["x"]) \
                                        + float(th["vx"]) * delta
                                th["y"] = float(th["y"]) \
                                        + sin(run_t * 2.2
                                        + float(th["wob"])) * 18.0 * delta
                                th["ft"] = float(th.get("ft", 0.0)) + delta
                                if float(th["ft"]) > 0.16:
                                        th["ft"] = 0.0
                                        th["frame"] = float(int(
                                                float(th.get("frame", 0.0))
                                                + 1.0))
                        "ufo", "drone":
                                th["x"] = float(th["x"]) \
                                        + float(th["vx"]) * delta
                                th["y"] = float(th["y"]) \
                                        + sin(run_t * 2.0
                                        + float(th["bob"])) * 14.0 * delta
                                th["ft"] = float(th.get("ft", 0.0)) + delta
                                if float(th["ft"]) > 0.14:
                                        th["ft"] = 0.0
                                        th["frame"] = float(int(
                                                float(th.get("frame", 0.0))
                                                + 1.0))
                        "bird":
                                th["x"] = float(th["x"]) \
                                        + float(th["vx"]) * delta
                                th["ft"] = float(th.get("ft", 0.0)) + delta
                                if float(th["ft"]) > 0.12:
                                        th["ft"] = 0.0
                                        th["frame"] = float(int(
                                                float(th.get("frame", 0.0))
                                                + 1.0))
                        "heli", "plane":
                                th["x"] = float(th["x"]) \
                                        + float(th["vx"]) * delta
                                # THE FLY CYCLE: the rotor/prop is IN the
                                # real frames - the step rides the speed
                                th["ft"] = float(th.get("ft", 0.0)) + delta
                                var fspd := absf(float(th["vx"]))
                                if float(th["ft"]) > 0.05 \
                                                * (300.0 / maxf(60.0, fspd)):
                                        th["ft"] = 0.0
                                        th["frame"] = float(int(
                                                float(th.get("frame", 0.0))
                                                + 1.0))
                                th["shoot_t"] = float(th["shoot_t"]) - delta
                                if float(th["shoot_t"]) <= 0.0 \
                                                and _surfaced_near(tp, 900.0):
                                        th["shoot_t"] = rng.randf_range(
                                                1.6, 3.2) / im
                                        _shoot(tp, "heli" if k == "heli"
                                                else "bullet")
                        "car", "truck":
                                # v040-12 THE CIVILIAN LAW (the owner: "a
                                # normal vehicle, normal car, and weirdly
                                # shots bullets? illogical"): civilians
                                # NEVER shoot - they just drive (and flee
                                # is the walker's business)
                                th["x"] = float(th["x"]) \
                                        + float(th["vx"]) * delta
                                th["wheel_t"] = float(th.get("wheel_t", 0.0)) \
                                        + absf(float(th["vx"])) * delta
                        "btr", "launcher", "tank":
                                th["x"] = float(th["x"]) \
                                        + float(th["vx"]) * delta
                                th["wheel_t"] = float(th.get("wheel_t", 0.0)) \
                                        + absf(float(th["vx"])) * delta
                                th["shoot_t"] = float(th["shoot_t"]) - delta
                                if float(th["shoot_t"]) <= 0.0 \
                                                and _surfaced_near(tp, 860.0):
                                        th["shoot_t"] = rng.randf_range(
                                                2.2, 4.5) / im
                                        _shoot(tp, "tank" if k == "tank"
                                                else ("rocket"
                                                if k == "launcher"
                                                else "bullet"))
                # THE DESPAWN LAW: far off the camera on BOTH axes - the
                # record dies and the sprite dies with it
                if not cam.grow(520.0).has_point(Vector2(float(th["x"]),
                        float(th["y"]))):
                        if th.get("spr") != null and is_instance_valid(th["spr"]):
                                th["spr"].queue_free()
                        th["alive"] = false
                        continue
                _paint_thing(th)
        things = things.filter(func(t): return bool(t["alive"]))

## does the worm threaten the shooters? v040-12 THE LINE-OF-SIGHT LAW
## (the owner: "the shooters shoot me under ground like as they are seeing
## me from under ground? that's wrong"): a shooter only opens fire when
## the worm is actually SURFACED - the dirt hides you completely.
func _surfaced_near(at: Vector2, dist: float) -> bool:
        return pts[0].y < SURFACE_Y + _head_r() * 0.8 \
                and pts[0].distance_to(at) < dist

func _paint_thing(th: Dictionary) -> void:
        var k := String(th["kind"])
        var sp: Sprite2D = th.get("spr")
        if sp == null or not is_instance_valid(sp):
                sp = Sprite2D.new()
                ent_draw.add_child(sp)
                th["spr"] = sp
        # THE FACING LAW: things art faces LEFT natively - flip when the
        # body moves right. One law for every family, no exceptions.
        var moving_right: bool = float(th["vx"]) > 0.0
        var frames: Array = []
        var fi := 0
        match k:
                "human":
                        frames = th["fr"]
                        fi = int(th["fi"]) % maxi(1, frames.size())
                "animal", "ground":
                        var skin := String(th.get("skin",
                                _animal_skin() if k == "animal" else "mole"))
                        var key := "animals/%s" % skin if k == "animal" \
                                else "ground/%s" % skin
                        frames = _family_frames(key)
                        fi = int(float(th.get("frame", 0.0))) \
                                % maxi(1, frames.size())
                "bird":
                        # v040-11: the bird had NO paint branch and no art -
                        # it flew INVISIBLE (the v040-10 latent bug). Our
                        # own 8-frame flap cycle now carries it.
                        frames = _family_frames("vehicles/bird")
                        fi = int(float(th.get("frame", 0.0))) \
                                % maxi(1, frames.size())
                "heli":
                        frames = _family_frames("vehicles/heli")
                        fi = int(float(th.get("frame", 0.0))) \
                                % maxi(1, frames.size())
                "plane":
                        frames = _family_frames("vehicles/plane")
                        fi = int(float(th.get("frame", 0.0))) \
                                % maxi(1, frames.size())
                "drone":
                        frames = _family_frames("shots/drone_ball")
                        fi = int(float(th.get("frame", 0.0))) \
                                % maxi(1, frames.size())
                "ufo":
                        frames = _family_frames("vehicles/ufo")
                        fi = int(float(th.get("frame", 0.0))) \
                                % maxi(1, frames.size())
                "car":
                        frames = _family_frames("vehicles/car")
                        fi = 0
                "truck":
                        frames = _family_frames("vehicles/truck")
                        fi = 0
                "tank":
                        frames = _family_frames("vehicles/tank")
                        fi = 0
                "btr":
                        frames = _family_frames("vehicles/btr")
                        fi = 0
                "launcher":
                        frames = _family_frames("vehicles/mech")
                        fi = int(float(th.get("wheel_t", 0.0)) / 0.18) \
                                % maxi(1, frames.size())
        if frames.is_empty():
                sp.visible = false
                return
        sp.visible = true
        var tex: Texture2D = frames[fi]
        if sp.texture != tex:
                sp.texture = tex
        sp.flip_h = moving_right
        # THE SCALE LAW (the video's own numbers): the humans ~6.5% of the
        # screen height (their raw art is ~68px tall at the 1080 design);
        # everything else seats by its kind's true size.
        var tk := 1.0
        match k:
                "human": tk = H * 0.065 / maxf(1.0, float(tex.get_height()))
                "bird": tk = H * 0.042 / maxf(1.0, float(tex.get_height()))
                "animal": tk = H * 0.085 / maxf(1.0, float(tex.get_height()))
                "ground": tk = H * 0.055 / maxf(1.0, float(tex.get_height()))
                "car", "truck", "btr", "launcher":
                        tk = H * 0.085 / maxf(1.0, float(tex.get_height()))
                "tank": tk = H * 0.1 / maxf(1.0, float(tex.get_height()))
                "heli": tk = H * 0.11 / maxf(1.0, float(tex.get_height()))
                "plane": tk = H * 0.1 / maxf(1.0, float(tex.get_height()))
                "drone": tk = H * 0.05 / maxf(1.0, float(tex.get_height()))
                "ufo": tk = H * 0.09 / maxf(1.0, float(tex.get_height()))
        sp.scale = Vector2.ONE * tk
        sp.position = Vector2(float(th["x"]), float(th["y"]))

## the frame cache: every family's real cycle, loaded once
var _fam_cache := {}
func _family_frames(rel: String) -> Array:
        if _fam_cache.has(rel):
                return _fam_cache[rel]
        var out: Array = []
        var i := 0
        while i < 48:
                var p := S + "things/%s_%02d.png" % [rel, i]
                if not ResourceLoader.exists(p):
                        break
                out.append(load(p))
                i += 1
        _fam_cache[rel] = out
        return out

## the land-animal cast shifts with the place (the owner: exclusive casts)
func _animal_skin() -> String:
        var skins: Array = ["camel", "puma", "tiger"]
        match place_id:
                "polar": skins = ["penguin", "bear", "yeti"]
                "jungle": skins = ["puma", "tiger", "camel"]
                "city": skins = ["puma", "camel"]
                "medieval": skins = ["camel", "puma"]
        return String(skins[rng.randi_range(0, skins.size() - 1)])

# ================================================================= the shots
func _shoot(at: Vector2, kind: String) -> void:
        var dir := (pts[0] - at).normalized()
        var spd := 620.0 * float(PLACES[place_id]["bullet_mult"])
        if kind == "rocket":
                spd = 420.0
        shots.append({
                "kind": kind, "x": at.x, "y": at.y - 10.0,
                "vx": dir.x * spd, "vy": dir.y * spd, "t": 0.0,
                "ft": 0.0,
        })
        Jukebox.sfx("dw_shot", -14.0, rng.randf_range(0.9, 1.1))

func _tick_shots(delta: float) -> void:
        var cam := _cam_rect()
        for s in shots:
                s["x"] = float(s["x"]) + float(s["vx"]) * delta
                s["y"] = float(s["y"]) + float(s["vy"]) * delta
                s["t"] = float(s["t"]) + delta
                s["ft"] = float(s.get("ft", 0.0)) + delta
                var sp: Sprite2D = s.get("spr")
                if sp == null or not is_instance_valid(sp):
                        sp = Sprite2D.new()
                        var s_kind := String(s["kind"])
                        var path: String = "things/shots/%s_00.png" \
                                % ("rocket" if s_kind == "rocket"
                                else ("tank_bullet" if s_kind == "tank"
                                else "bullet"))
                        sp.texture = load(S + path)
                        ent_draw.add_child(sp)
                        s["spr"] = sp
                # v040-12 THE TRUE ANGLE LAW (the owner: "the bullets shotted
                # by anything are static, and made horizontal, they actually
                # should be angled toward the worm from where it was the
                # moment the shot got out"): the sprite rides its REAL
                # velocity angle - the art faces RIGHT, no magic quarter
                # turn - and the 2-frame cycle keeps it alive in the air.
                var vdir := Vector2(float(s["vx"]), float(s["vy"]))
                sp.rotation = vdir.angle()
                var base_path: String = (sp.texture as Texture2D) \
                        .resource_path
                var alt_i := int(float(s["ft"]) / 0.07) % 2
                var alt_path := base_path.replace("_00.png",
                        "_%02d.png" % alt_i)
                if alt_i > 0 and ResourceLoader.exists(alt_path) \
                                and sp.texture.resource_path != alt_path:
                        sp.texture = load(alt_path)
                sp.position = Vector2(float(s["x"]), float(s["y"]))
                # the hit: bullets only bite the SURFACED worm (dirt is
                # armor - deep under the line nothing reaches you)
                var p := pts[0]
                var surfaced := p.y < SURFACE_Y + _head_r() * 0.6
                var sp2 := Vector2(float(s["x"]), float(s["y"]))
                if surfaced and sp2.distance_to(p) < _head_r():
                        s["t"] = 99.0
                        _hurt(_shot_dmg(String(s["kind"])), sp2)
                if float(s["t"]) > 4.0 or not cam.grow(340.0).has_point(sp2):
                        if sp != null and is_instance_valid(sp):
                                sp.queue_free()
                        s["kind"] = "dead"
        shots = shots.filter(func(s): return String(s["kind"]) != "dead")

func _shot_dmg(kind: String) -> float:
        match kind:
                "rocket": return 11.0
                "tank": return 9.0
                _: return 5.0

## THE DAMAGE - one funnel: ghost forgives, shield forgives once, invuln
## rides, the dirt below the line is armor
func _hurt(dmg: float, at: Vector2) -> void:
        if ghost_t > 0.0 or invuln_t > 0.0:
                return
        if shield_on:
                shield_on = false
                invuln_t = 1.0
                _banner("THE STONE SCALE HELD", Color("9ad8ff"))
                Jukebox.sfx("dw_power", -6.0)
                return
        if hit_cd > 0.0:
                return
        hit_cd = 0.18
        p_hp = maxf(0.0, p_hp - dmg)
        flash = 0.5
        shake = maxf(shake, 7.0)
        invuln_t = 0.7
        _push_fx("blood", at.x, at.y, rng.randf_range(-60.0, 60.0),
                -80.0, 0.6)
        Jukebox.sfx("dw_hurt", -5.0, rng.randf_range(0.9, 1.1))

# ================================================================= the drops
var _coin_tex_cache: Texture2D = null
func _coin_tex() -> Texture2D:
        if _coin_tex_cache == null:
                _coin_tex_cache = load(S + "coin.png")
        return _coin_tex_cache

## THE DROP LAW v040-11 (the owner, on the original: "coins were
## spawning a little up and not forward - this makes collecting them
## requires really going to them; they vanish after 10 seconds if not
## collected with proper flickering and fade-out"): NO chase-magnet
## anymore - a coin sits where it popped up (a little UP, never thrown
## forward) and the worm's head must really come take it. Unclaimed
## coins live 10s: they blink, then fade, then they are gone.
const COIN_LIFE_S := 10.0
func _tick_drops(delta: float) -> void:
        var cam := _cam_rect()
        var got := false
        for c in coins_drops:
                c["t"] = float(c["t"]) + delta
                var cp := Vector2(float(c["x"]), float(c["y"]))
                if cp.distance_to(pts[0]) < _head_r() + 22.0:
                        # COLLECTED: bank it, pulse the wallet, kill BOTH
                        # the record and the sprite - the stuck-coin bug
                        # died here
                        c["t"] = 99.0
                        got = true
                        wormcoins_run += 1
                        meta.add_coins(1)
                        _push_fx("coin", float(c["x"]), float(c["y"]),
                                0.0, -70.0, 0.5)
                        Jukebox.sfx("dw_coin", -6.0,
                                rng.randf_range(0.95, 1.1))
                        if c.get("spr") != null \
                                        and is_instance_valid(c["spr"]):
                                c["spr"].queue_free()
                        c["spr"] = null
                        continue
                var sp: Sprite2D = c.get("spr")
                if sp == null or not is_instance_valid(sp):
                        sp = Sprite2D.new()
                        sp.texture = _coin_tex()
                        ent_draw.add_child(sp)
                        c["spr"] = sp
                # the little UP hop on birth (never forward): the coin
                # rises ~30px then rests - the original's pop
                var hop := clampf(float(c["t"]) / 0.35, 0.0, 1.0)
                sp.position = Vector2(float(c["x"]),
                        float(c["y"]) - sin(hop * PI) * 30.0)
                sp.scale = Vector2.ONE * (1.0 + sin(c["t"] * 6.0) * 0.12)
                # v040-11 the 10s clock: blink after 7s, fade the tail
                var left := COIN_LIFE_S - float(c["t"])
                if left < 3.0:
                        var blink := 1.0 if fmod(float(c["t"]), 0.24) < 0.12 \
                                        else 0.35
                        sp.modulate = Color(1, 1, 1, blink)
                if left < 1.0:
                        sp.modulate.a = maxf(0.0, left)
                # a drop nobody takes still dies when FAR off the camera
                # (gone for good - the world does not carry it)
                if not cam.grow(900.0).has_point(cp):
                        c["t"] = 99.0
                if float(c["t"]) >= COIN_LIFE_S:
                        c["t"] = 99.0
                if float(c["t"]) >= 99.0:
                        if is_instance_valid(sp):
                                sp.queue_free()
                        c["spr"] = null
                        continue
        if got and wc_lbl != null:
                wc_lbl.scale = Vector2.ONE * 1.25   # the +1 pulse
        coins_drops = coins_drops.filter(func(c): return float(c["t"]) < 90.0)

# ============================================================== the power-ups
func _tick_pows(delta: float) -> void:
        var cam := _cam_rect()
        # the spawn clock: one every 60..120s, a random UNLOCKED kind
        pow_t -= delta
        if pow_t <= 0.0:
                pow_t = rng.randf_range(60.0, 120.0)
                var pool: Array = []
                for p in POWS:
                        if meta.owns_pow(String(p["k"])):
                                pool.append(p)
                if not pool.is_empty():
                        var pk: Dictionary = pool[rng.randi_range(0,
                                pool.size() - 1)]
                        var from_right := rng.randf() < 0.5
                        pows_live.append({
                                "k": String(pk["k"]),
                                "x": cam_x + (W + 90.0 if from_right
                                        else -90.0),
                                "y": rng.randf_range(
                                        SURFACE_Y - SKY_H * 0.5,
                                        SURFACE_Y - 60.0),
                                "vx": rng.randf_range(70.0, 110.0)
                                        * (-1.0 if from_right else 1.0),
                                "t": 0.0,
                        })
                        Jukebox.sfx("dw_fly", -10.0)
        for pw in pows_live:
                pw["x"] = float(pw["x"]) + float(pw["vx"]) * delta
                pw["y"] = float(pw["y"]) + sin(pw["t"] * 3.0) * 10.0 * delta
                pw["t"] = float(pw["t"]) + delta
                var sp: Sprite2D = pw.get("spr")
                if sp == null or not is_instance_valid(sp):
                        sp = Sprite2D.new()
                        sp.texture = load(S + "pows/%s.png" % String(pw["k"]))
                        ent_draw.add_child(sp)
                        pw["spr"] = sp
                sp.position = Vector2(float(pw["x"]), float(pw["y"]))
                sp.scale = Vector2.ONE * (1.0 + sin(pw["t"] * 5.0) * 0.1)
                var pp := Vector2(float(pw["x"]), float(pw["y"]))
                if pp.distance_to(pts[0]) < _head_r() + 34.0:
                        pw["t"] = 99.0
                        _grab_pow(String(pw["k"]))
                if float(pw["t"]) > 30.0 or not cam.grow(300.0).has_point(pp):
                        if sp != null and is_instance_valid(sp):
                                sp.queue_free()
                        pw["k"] = "gone"
        pows_live = pows_live.filter(func(p): return String(p["k"]) != "gone")

func _grab_pow(k: String) -> void:
        var dur := 0.0
        for p in POWS:
                if String(p["k"]) == k:
                        dur = float(p["dur"])
        match k:
                "size": p_scale = float(worm_d["size"]) * 1.6
                "speed": p_speed = float(worm_d["speed"]) * 1.7
                "ghost": ghost_t = dur
                "frenzy": dash_cd = 0.0
                "shield": shield_on = true
        if dur > 0.0:
                buffs[k] = dur
        _banner("%s!" % _pow_name(k), Color("9ad8ff"))
        Jukebox.sfx("dw_power", -4.0)

func _pow_name(k: String) -> String:
        for p in POWS:
                if String(p["k"]) == k:
                        return String(p["name"])
        return k.to_upper()

# the live buff clocks (the HUD chips read this)
var buffs := {}

# ============================================================= the spawn law
func _tick_spawn(delta: float) -> void:
        # the buff clocks drain
        for k in buffs.keys():
                buffs[k] = float(buffs[k]) - delta
                if float(buffs[k]) <= 0.0:
                        match k:
                                "size": p_scale = float(worm_d["size"])
                                "speed": p_speed = float(worm_d["speed"])
                        buffs.erase(k)
        spawn_t -= delta
        if spawn_t <= 0.0:
                # the pour quickens forever, never rests
                spawn_t = clampf(3.4 / _intensity(), 0.55, 3.4)
                _spawn_roll()
        # the magnet pull (the HUNGER CALL + the WRAITH's VOID PULL)
        if float(buffs.get("magnet", 0.0)) > 0.0 \
                        or float(buffs.get("void_active", 0.0)) > 0.0:
                var pull := 180.0 if float(buffs.get("magnet", 0.0)) > 0.0 \
                        else 300.0
                for th in things:
                        if String(th["kind"]) == "human" \
                                        or String(th["kind"]) == "animal":
                                var tp := Vector2(float(th["x"]),
                                        float(th["y"]))
                                if tp.distance_to(pts[0]) < 620.0:
                                        var dir := (pts[0] - tp).normalized()
                                        th["x"] = float(th["x"]) \
                                                + dir.x * pull * delta

# ==================================================================== the fx
func _push_fx(kind: String, x: float, y: float, vx: float, vy: float,
                life: float) -> void:
        var sp := Sprite2D.new()
        sp.texture = _dot_tex()
        match kind:
                "blood": sp.modulate = Color(0.75, 0.1, 0.12, 0.85)
                "dirt": sp.modulate = Color(0.42, 0.3, 0.18, 0.8)
                "spark": sp.modulate = Color(1.0, 0.85, 0.4, 0.9)
                "gut": sp.modulate = Color(0.5, 0.55, 0.3, 0.7)
                "coin": sp.modulate = Color(1.0, 0.8, 0.25, 0.95)
                "snow": sp.modulate = Color(0.95, 0.97, 1.0, 0.75)
                # v040-12 THE REAL BITE: torn chunks (bigger, darker red)
                "gib": sp.modulate = Color(0.62, 0.08, 0.1, 0.95)
                _: sp.modulate = Color(0.8, 0.8, 0.8, 0.7)
        sp.position = Vector2(x, y)
        sp.scale = Vector2.ONE * rng.randf_range(0.5, 1.3)
        if kind == "coin":
                sp.scale = Vector2.ONE * 2.2
        if kind == "gib":
                sp.scale = Vector2.ONE * rng.randf_range(1.6, 3.0)
        if kind == "snow":
                sp.scale = Vector2.ONE * rng.randf_range(0.35, 0.8)
        fx_draw.add_child(sp)
        fx.append({"spr": sp, "vx": vx, "vy": vy, "t": 0.0, "life": life,
                "k": kind})

var _dot_tex_cache: Texture2D = null
func _dot_tex() -> Texture2D:
        if _dot_tex_cache == null:
                _dot_tex_cache = load(S + "dot.png")
        return _dot_tex_cache

## THE REAL EXPLOSIONS: the study's own 24-frame blast, code-modified
func _explode(at: Vector2, sc: float) -> void:
        var sp := Sprite2D.new()
        sp.texture = load(S + "things/fx/expl_00.png")
        sp.position = Vector2(at.x, at.y)
        sp.scale = Vector2.ONE * sc
        fx_draw.add_child(sp)
        fx.append({"spr": sp, "vx": 0.0, "vy": 0.0, "t": 0.0,
                "life": 0.72, "boom": true})
        shake = maxf(shake, 10.0)
        Jukebox.sfx("dw_boom", -6.0, rng.randf_range(0.9, 1.1))

func _tick_fx(delta: float) -> void:
        for f in fx:
                f["t"] = float(f["t"]) + delta
                var sp: Sprite2D = f["spr"]
                if not is_instance_valid(sp):
                        continue
                if f.has("boom"):
                        # the explosion rides its 24 real frames
                        var fi := int(float(f["t"])
                                / (float(f["life"]) / 24.0))
                        if fi > 23:
                                sp.visible = false
                        else:
                                sp.texture = load(S
                                        + "things/fx/expl_%02d.png" % fi)
                        continue
                var fk := String(f.get("k", ""))
                if fk == "snow":
                        # v040-12 THE PHYSICAL SNOW LAW (the owner: "snow
                        # effect in ice place weirdly looks golden and
                        # illogically the VFX reach the under ground... it
                        # is screen effect and not physical-based one"):
                        # a real flake - constant fall, no gravity, it dies
                        # AT the surface line (the ground stops it)
                        sp.position.x += float(f["vx"]) * delta
                        sp.position.y += float(f["vy"]) * delta
                        if sp.position.y >= SURFACE_Y - 4.0:
                                f["t"] = float(f["life"]) + 1.0
                        continue
                f["vy"] = float(f["vy"]) + 380.0 * delta
                sp.position.x += float(f["vx"]) * delta
                sp.position.y += float(f["vy"]) * delta
                var k := float(f["t"]) / float(f["life"])
                sp.modulate.a = maxf(0.0, 0.85 * (1.0 - k))
                sp.scale = sp.scale * (1.0 - 0.9 * delta)
        var dead: Array = []
        for f in fx:
                if float(f["t"]) >= float(f["life"]):
                        dead.append(f)
        for f in dead:
                if is_instance_valid(f["spr"]):
                        f["spr"].queue_free()
        fx = fx.filter(func(f): return float(f["t"]) < float(f["life"]))

# ============================================================== camera + hud
## THE CAMERA LAW: both axes follow the head with a soft lag, clamped to
## the world. The surface line rides the upper-middle band (the video's
## own framing), the dives and the jumps pull the view with the worm.
func _tick_camera(_delta: float) -> void:
        var want_x := clampf(pts[0].x - W * 0.5, 0.0, maxf(0.0, WORLD_W - W))
        cam_x = lerpf(cam_x, want_x, 0.08)
        var want_y := clampf(pts[0].y - H * 0.55, 0.0,
                maxf(0.0, SURFACE_Y + DIRT_H - H))
        cam_y = lerpf(cam_y, want_y, 0.06)
        world.position = Vector2(-cam_x, -cam_y)
        # THE PARALLAX: the props strip rides almost with the world (it
        # sits ON the road's horizon - the drift is subtle)
        if far_draw != null:
                far_draw.position.x = cam_x * 0.86

## the place's EXCLUSIVE life: the hazards + the ambience (the owner's
## "places are not just different views" law)
func _place_flavor(delta: float) -> void:
        match String(PLACES[place_id]["hazard"]):
                "snow":
                        # v040-12: flakes spawn ONLY in the sky above the
                        # line and die at it (the physical snow law)
                        if rng.randf() < 0.5:
                                var sy := minf(cam_y
                                        + rng.randf_range(-20.0, 80.0),
                                        SURFACE_Y - 60.0)
                                if sy < SURFACE_Y - 20.0:
                                        _push_fx("snow", cam_x
                                                + rng.randf_range(0.0, W),
                                                sy,
                                                rng.randf_range(-30.0, 30.0),
                                                rng.randf_range(60.0, 130.0),
                                                6.0)
                "sparks":
                        # the subway strip bites the tail at the bottom
                        if pts[0].y > SURFACE_Y + DIRT_H - 60.0:
                                _hurt(6.0 * delta * 3.0, pts[0])
                "torches":
                        # the wall torches burn the surfaced worm
                        if pts[0].y < SURFACE_Y + 20.0:
                                for tx in [WORLD_W * 0.12, WORLD_W * 0.5,
                                        WORLD_W * 0.88]:
                                        if absf(pts[0].x - tx) < 70.0:
                                                _hurt(4.0 * delta * 3.0,
                                                        pts[0])
                _:
                        pass

## the top bar: SHOP directly after BACK (the owner's seat law), WORMS
## after it, then the health % and the wormCoins wallet with its icon
func _build_hud_extra() -> void:
        add_hud_button("SHOP", _open_shop)
        add_hud_button("WORMS", _open_worms)
        hp_lbl = add_hud_chip("100%")
        wc_lbl = add_hud_chip("0", S + "coin.png")
        _build_widgets()

## v040-11 THE TOP-BAR WIDGET LAW + v040-12 THE GEOMETRY WIDGET LAW: the
## DASH cooldown and the SPECIAL charge are CHIPS IN THE TOP BAR, right
## after WORMS - one line each, nothing stacked; the power-ups wear the
## geometry format (icon: nn) in the same bar.
func _build_widgets() -> void:
        # v040-11 THE WIDGET SEAT LAW (the owner: "put them at the top left
        # after worms button and make them horizontal and not word on each
        # other, like this: 'special: name nn' 'dash: ready/ dash:
        # count_down'"): the two chips ride the TOP BAR ITSELF, right after
        # the WORMS button, one line each - the old stacked panels died.
        dash_chip = Arc.chip("DASH: READY", "", Color(0, 0, 0, 0.4), 19,
                Arc.CARD)
        _hud_row.add_child(dash_chip)
        _hud_row.move_child(dash_chip, 3)   # back, SHOP, WORMS, DASH
        dash_lbl = dash_chip.get_child(0).get_child(
                dash_chip.get_child(0).get_child_count() - 1)
        sp_chip = Arc.chip("SPECIAL: -", "", Color(0, 0, 0, 0.4), 19,
                Arc.CARD)
        _hud_row.add_child(sp_chip)
        _hud_row.move_child(sp_chip, 4)     # ...then SPECIAL
        sp_lbl = sp_chip.get_child(0).get_child(
                sp_chip.get_child(0).get_child_count() - 1)
        # ---- the power chips: v040-12 THE GEOMETRY WIDGET LAW (the
        # owner: "the powerup widget is wrong, in games like geometry flash
        # or snowy tower, powerup widget is at top left showing 'icon: nn'")
        # - each active power rides the TOP BAR as an icon + countdown
        # chip, exactly the geometry format, seated before the score chips.
        for i in POWS.size():
                var p: Dictionary = POWS[i]
                var kind := String(p["k"])
                var panel := PanelContainer.new()
                panel.add_theme_stylebox_override("panel",
                        Arc.panel_style(Color(0, 0, 0, 0.4), 18))
                panel.visible = false
                var hb := HBoxContainer.new()
                hb.add_theme_constant_override("separation", 4)
                var ic := TextureRect.new()
                ic.texture = load(S + "pows/%s.png" % kind)
                ic.custom_minimum_size = Vector2(40, 40)
                ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
                hb.add_child(ic)
                var lbl := Arc.label("10", 20, Color(1, 1, 1, 0.95))
                hb.add_child(lbl)
                panel.add_child(hb)
                _hud_row.add_child(panel)
                _hud_row.move_child(panel, _hud_row.get_child_count() - 2)
                pow_chips[kind] = {"panel": panel, "label": lbl}

func _tick_hud() -> void:
        if hp_lbl != null:
                hp_lbl.text = "%d%%" % int(round(100.0 * p_hp
                        / maxf(1.0, p_hp_max)))
        if wc_lbl != null:
                # v040-11 THE HONEST COIN CHIP (the owner: "the coins widget
                # shows total coins instead of collected this round - make it
                # shows only the collected, total coins be in the worms menu
                # only"): the run chip counts THIS ROUND's pickups.
                wc_lbl.text = str(wormcoins_run)
                wc_lbl.scale = wc_lbl.scale.lerp(Vector2.ONE, 0.12)
        # the dash chip lives its cooldown (the horizontal top-bar format)
        if dash_lbl != null:
                if dash_cd > 0.0:
                        dash_lbl.text = "DASH: %.1f" % dash_cd
                else:
                        dash_lbl.text = "DASH: READY"
        if sp_lbl != null:
                var names := {"roar": "ROAR", "surge": "SURGE",
                        "geyser": "GEYSER", "ghost": "GHOST DIVE",
                        "frenzy": "BLOOD FRENZY", "quake": "QUAKE",
                        "venom": "VENOM SPIT", "devour": "DEVOUR",
                        "voidpull": "VOID PULL", "firebreath": "FIRE BREATH"}
                var nm: String = names.get(String(worm_d["special"]), "?")
                sp_lbl.text = "SPECIAL: %s x%d" % [nm, special_charges]
        # the power chips tick their countdowns (the geometry law)
        for k in pow_chips:
                var seat: Dictionary = pow_chips[k]
                var on: bool = float(buffs.get(k, 0.0)) > 0.0 \
                        or (k == "shield" and shield_on)
                seat["panel"].visible = on
                if on and float(buffs.get(k, 0.0)) > 0.0:
                        seat["label"].text = "%ds" \
                                % int(ceil(float(buffs[k])))
                elif k == "shield" and shield_on:
                        seat["label"].text = "1"

func _dash_cd_max() -> float:
        var w: Dictionary = WORMS[worm_i]
        var base := 3.2 / maxf(0.5, float(w["speed"]))
        if float(buffs.get("frenzy", 0.0)) > 0.0:
                base *= 0.5
        return base

func _dash_len() -> float:
        var w: Dictionary = WORMS[worm_i]
        return 0.42 + 0.06 * float(w["size"])

# ================================================================= banners
func _banner(msg: String, col := Color.WHITE) -> void:
        banners.append({"msg": msg, "t": 2.2, "col": col})
        if banners.size() > 3:
                banners.pop_front()

func _tick_banners(delta: float) -> void:
        for b in banners:
                b["t"] = float(b["t"]) - delta
        banners = banners.filter(func(b): return float(b["t"]) > 0.0)
        queue_redraw()

## THE MUD-EATEN TUNNEL (v040-12 THE VISIBLE TUNNEL LAW): painted on the
## tunnel_draw layer INSIDE the world (world coordinates - the layer's
## parent already carries the camera), ABOVE the dirt, BELOW the worm.
## Each mark is a bitten pocket of the place's own dirt - a dark core,
## a lighter eaten rim riding the top, and the crumb flecks.
func _draw_tunnel() -> void:
        if tunnel_draw == null:
                return
        var tcol: Dictionary = TUNNEL_COL.get(place_id,
                TUNNEL_COL["desert"])
        var hr := _head_r()
        for tr in trail:
                var life := clampf(float(tr["t"]) / 6.0, 0.0, 1.0)
                var a := life * 0.72
                var p := Vector2(float(tr["x"]), float(tr["y"]))
                var rr := hr * (0.40 + 0.10 * life)
                tunnel_draw.draw_circle(p, rr, Color(tcol["core"], a))
                # the eaten rim: a light lip on the pocket's upper edge
                tunnel_draw.draw_arc(p + Vector2(0.0, -rr * 0.28),
                        rr * 0.82, PI + 0.35, TAU - 0.35, 10,
                        Color(tcol["rim"], a * 0.8), hr * 0.09)
                # the crumb flecks (deterministic per mark)
                var seedv := float(tr.get("s", 0.5))
                for fi in 3:
                        var fa := TAU * (seedv * 7.3 + float(fi) * 2.4)
                        var fd := rr * (0.55 + 0.4 * fmod(seedv * 13.1
                                + float(fi) * 0.37, 1.0))
                        tunnel_draw.draw_circle(
                                p + Vector2(cos(fa), sin(fa)) * fd,
                                maxf(1.5, hr * 0.05),
                                Color(tcol["rim"], a * 0.55))

## the game's own canvas paints the banners + the hurt flash (the world
## layers live inside `world`, the tunnel on its own layer there)
func _draw() -> void:
        var vp := get_viewport_rect().size
        if flash > 0.0:
                draw_rect(Rect2(Vector2.ZERO, vp),
                        Color(0.7, 0.1, 0.1, 0.28 * flash))
        var y := vp.y * 0.34
        for b in banners:
                var a := clampf(float(b["t"]) / 0.4, 0.0, 1.0)
                var fnt := ThemeDB.fallback_font
                var fs := 46
                var ts := fnt.get_string_size(String(b["msg"]),
                        HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
                var pos := Vector2(vp.x * 0.5 - ts.x * 0.5, y)
                var st := Vector2(3.0, 3.0)
                draw_string_outline(fnt, pos + st, String(b["msg"]),
                        HORIZONTAL_ALIGNMENT_CENTER, -1, fs, 6,
                        Color(0, 0, 0, 0.75 * a))
                draw_string(fnt, pos, String(b["msg"]),
                        HORIZONTAL_ALIGNMENT_CENTER, -1, fs,
                        Color(b["col"], a))
                y += 62.0

# ================================================================== input
## THE ZONES (the owner's law): LEFT half = the hidden analog, RIGHT half =
## TAP to dash, the MIDDLE strip = TAP for the special
func _goga_input(event: InputEvent) -> void:
        if state != "play":
                return
        if event is InputEventKey:
                # THE PC LAW (the windows return): the ARROW keys bend the
                # heading (the hidden analog's keyboard twin), SPACE dashes
                var k := event as InputEventKey
                if k.pressed and not k.echo:
                        if k.is_action("ui_accept"):
                                _do_dash()
                        elif k.is_action("ui_left"):
                                move_vec = Vector2(-1, 0)
                                steer_mag = 0.9
                        elif k.is_action("ui_right"):
                                move_vec = Vector2(1, 0)
                                steer_mag = 0.9
                        elif k.is_action("ui_up"):
                                move_vec = Vector2(0, -1)
                                steer_mag = 0.9
                        elif k.is_action("ui_down"):
                                move_vec = Vector2(0, 1)
                                steer_mag = 0.9
                else:
                        move_vec = Vector2.ZERO
                        steer_mag = 0.0
                return
        var split_l := W * 0.32
        var split_r := W * 0.68
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                var p := _to_design(t.position)
                if t.pressed:
                        if p.x < split_l:
                                move_ptr = t.index
                                move_anchor = p
                                move_vec = Vector2.ZERO
                                steer_mag = 0.0
                        elif p.x > split_r:
                                _do_dash()
                        else:
                                _do_special()
                else:
                        if t.index == move_ptr:
                                move_ptr = -1
                                move_vec = Vector2.ZERO
                                steer_mag = 0.0
        elif event is InputEventScreenDrag:
                var d := event as InputEventScreenDrag
                if d.index == move_ptr:
                        # THE HIDDEN ANALOG: the drag vector from the press
                        # point IS the steering stick (the original's feel)
                        var rel := (_to_design(d.position) - move_anchor) / 110.0
                        if rel.length() > 1.0:
                                rel = rel.normalized()
                        move_vec = rel
                        steer_mag = rel.length()

var move_anchor := Vector2.ZERO

func _to_design(screen_p: Vector2) -> Vector2:
        var vp := get_viewport_rect().size
        return Vector2(screen_p.x * W / vp.x, screen_p.y * H / vp.y)

## THE DASH: the right-side tap - a burst with the worm's own cooldown
func _do_dash() -> void:
        if dash_cd > 0.0 or dash_t > 0.0:
                Jukebox.sfx("dw_click", -12.0)
                return
        dash_t = _dash_len()
        dash_cd = _dash_cd_max()
        Jukebox.sfx("dw_dash", -4.0, rng.randf_range(0.95, 1.1))

## THE SPECIAL: the middle tap - one charge per 100 points, unique per worm
func _do_special() -> void:
        if special_charges <= 0:
                Jukebox.sfx("dw_click", -12.0)
                return
        special_charges -= 1
        var sp := String(worm_d["special"])
        var hp := pts[0]
        match sp:
                "roar":
                        _stun_surface(2.5)
                        shake = 12.0
                        _banner("ROAR!", Color("ffd76a"))
                "surge":
                        p_speed = float(worm_d["speed"]) * 1.8
                        buffs["speed"] = 5.0
                        _banner("SURGE!", Color("9ad8ff"))
                "geyser":
                        _blast(Vector2(hp.x, SURFACE_Y + 20.0), 460.0, 3.0)
                        shake = 14.0
                        _banner("GEYSER!", Color("ffd76a"))
                "ghost":
                        ghost_t = 4.0
                        _banner("GHOST DIVE!", Color("9ad8ff"))
                "frenzy":
                        _frenzy_bites()
                        _banner("BLOOD FRENZY!", Color("ff9a7a"))
                "quake":
                        _stun_surface(3.0)
                        _blast_all_vehicles(1.5)
                        shake = 18.0
                        _banner("QUAKE!", Color("ffd76a"))
                "venom":
                        _venom_spit()
                        _banner("VENOM!", Color("9aff9a"))
                "devour":
                        _devour_blast(300.0 * p_scale)
                        _banner("DEVOUR!", Color("ff9aff"))
                "voidpull":
                        _void_pull(4.0)
                        _banner("VOID PULL!", Color("c09aff"))
                "firebreath":
                        _fire_breath()
                        _banner("FIRE BREATH!", Color("ff7a4a"))
        Jukebox.sfx("dw_special", -2.0)

## every walker + animal on the surface near the worm freezes in panic
func _stun_surface(t: float) -> void:
        for th in things:
                if String(th["kind"]) == "human" \
                                or String(th["kind"]) == "animal":
                        th["flee"] = t
                        th["stun"] = t

## an AOE burst at a point: kills humans/animals, cracks vehicles
func _blast(at: Vector2, radius: float, dmg: float) -> void:
        _explode(at, 2.2)
        for th in things:
                if not bool(th["alive"]):
                        continue
                var tp := Vector2(float(th["x"]), float(th["y"]))
                if tp.distance_to(at) > radius:
                        continue
                var k := String(th["kind"])
                if k == "human":
                        th["alive"] = false
                        eaten_humans += 1
                        _eaten_book(POINTS["human"], "human", tp)
                elif k == "animal":
                        th["alive"] = false
                        eaten_animals += 1
                        _eaten_book(int(POINTS["animal"]
                                * float(PLACES[place_id]["loot"])), "animal", tp)
                elif VEH_HP.has(k):
                        th["hp"] = int(th["hp"]) - int(dmg * p_power)
                        if int(th["hp"]) <= 0:
                                th["alive"] = false
                                vehicles += 1
                                _eaten_book(int(POINTS[k]), "vehicle", tp)
                                _explode(tp, 1.2)

## the crimson's blood frenzy: every surface thing near the head is devoured
func _frenzy_bites() -> void:
        var at := pts[0]
        for th in things:
                if not bool(th["alive"]):
                        continue
                var tp := Vector2(float(th["x"]), float(th["y"]))
                if tp.distance_to(at) < 420.0 * p_scale:
                        var k := String(th["kind"])
                        if k == "human" or k == "animal":
                                th["alive"] = false
                                if k == "human":
                                        eaten_humans += 1
                                        _eaten_book(POINTS["human"], "human", tp)
                                else:
                                        eaten_animals += 1
                                        _eaten_book(int(POINTS["animal"]
                                                * float(PLACES[place_id]["loot"])),
                                                "animal", tp)

## the viper's venom: poisons the nearest walkers - they pop one by one
func _venom_spit() -> void:
        var victims: Array = []
        for th in things:
                if bool(th["alive"]) and String(th["kind"]) == "human":
                        victims.append(th)
        victims.sort_custom(func(a, b):
                var pa := Vector2(float(a["x"]), float(a["y"]))
                var pb := Vector2(float(b["x"]), float(b["y"]))
                return pa.distance_to(pts[0]) < pb.distance_to(pts[0]))
        for i in mini(5, victims.size()):
                var th: Dictionary = victims[i]
                th["alive"] = false
                var tp := Vector2(float(th["x"]), float(th["y"]))
                eaten_humans += 1
                _eaten_book(POINTS["human"], "human", tp)
                _push_fx("gut", tp.x, tp.y, 0.0, -50.0, 0.6)

## the goliath's devour: everything edible in the radius is swallowed whole
func _devour_blast(radius: float) -> void:
        for th in things:
                if not bool(th["alive"]):
                        continue
                var tp := Vector2(float(th["x"]), float(th["y"]))
                if tp.distance_to(pts[0]) > radius:
                        continue
                var k := String(th["kind"])
                if k == "human" or k == "animal" or k == "ground":
                        th["alive"] = false
                        if k == "human":
                                eaten_humans += 1
                                _eaten_book(POINTS["human"], "human", tp)
                        elif k == "animal":
                                eaten_animals += 1
                                _eaten_book(int(POINTS["animal"]
                                        * float(PLACES[place_id]["loot"])),
                                        "animal", tp)
                        else:
                                eaten_ground += 1
                                ground_run += 1
                                if ground_run >= 3:
                                        ground_run -= 3
                                        _eaten_book(POINTS["ground"],
                                                "ground", tp)

## the wraith's void pull: the surface world drags toward the worm
func _void_pull(t: float) -> void:
        buffs["void_active"] = t

## the dragon's fire breath: a cone of destruction along the heading
func _fire_breath() -> void:
        var dir := Vector2(cos(heading), sin(heading))
        for th in things:
                if not bool(th["alive"]):
                        continue
                var tp := Vector2(float(th["x"]), float(th["y"]))
                var rel := tp - pts[0]
                if rel.length() > 640.0:
                        continue
                if absf(wrapf(rel.angle() - dir.angle(), -PI, PI)) > 0.7:
                        continue
                var k := String(th["kind"])
                if k == "human" or k == "animal" or k == "ground":
                        th["alive"] = false
                        if k == "human":
                                eaten_humans += 1
                                _eaten_book(POINTS["human"], "human", tp)
                        elif k == "animal":
                                eaten_animals += 1
                                _eaten_book(int(POINTS["animal"]
                                        * float(PLACES[place_id]["loot"])),
                                        "animal", tp)
                        else:
                                eaten_ground += 1
                                ground_run += 1
                                if ground_run >= 3:
                                        ground_run -= 3
                                        _eaten_book(POINTS["ground"],
                                                "ground", tp)
                        _push_fx("spark", tp.x, tp.y, 0.0, -60.0, 0.5)
                elif VEH_HP.has(k):
                        th["hp"] = int(th["hp"]) - int(2.0 * p_power)
                        if int(th["hp"]) <= 0:
                                th["alive"] = false
                                vehicles += 1
                                _eaten_book(int(POINTS[k]), "vehicle", tp)
                                _explode(tp, 1.2)
        for i in 26:
                _push_fx("spark", pts[0].x + dir.x * rng.randf_range(60.0,
                        620.0), pts[0].y + dir.y * rng.randf_range(60.0,
                        620.0), dir.x * 200.0, -40.0, 0.7)

## the titan's quake also cracks every live vehicle on screen
func _blast_all_vehicles(dmg: float) -> void:
        for th in things:
                if not bool(th["alive"]):
                        continue
                var k := String(th["kind"])
                if VEH_HP.has(k):
                        th["hp"] = int(th["hp"]) - int(dmg * p_power)
                        var tp := Vector2(float(th["x"]), float(th["y"]))
                        if int(th["hp"]) <= 0:
                                th["alive"] = false
                                vehicles += 1
                                _eaten_book(int(POINTS[k]), "vehicle", tp)
                                _explode(tp, 1.2)

# ================================================================ the sheets
## the TAP ANYWHERE TO START sheet (the owner's law: the game opens on it;
## v040-10: the title text is OUTLINED for the contrast law)
var _intro_pair: Array = []
func _show_intro_sheet() -> void:
        if not _intro_pair.is_empty():
                return
        state = "intro"
        var vb := sheet_push(0.0, "intro")
        var dim: Control = _sheet_stack.back()["dim"]
        dim.gui_input.connect(func(ev: InputEvent):
                if ev is InputEventScreenTouch and ev.pressed:
                        _start_run())
        var cc: Control = _sheet_stack.back()["cc"]
        cc.gui_input.connect(func(ev: InputEvent):
                if ev is InputEventScreenTouch and ev.pressed:
                        _start_run())
        var sp := TextureRect.new()
        sp.texture = load(S + "worms/%s_head_open.png" % String(worm_d["id"]))
        sp.custom_minimum_size = Vector2(0, 220)
        sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        vb.add_child(sp)
        var t := Label.new()
        t.text = String(worm_d["name"]) + "  -  " + String(PLACES[place_id]["name"])
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        t.add_theme_font_size_override("font_size", 34)
        t.add_theme_color_override("font_color", Color(1, 1, 1))
        t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
        t.add_theme_constant_override("outline_size", 10)
        vb.add_child(t)
        var t2 := Label.new()
        t2.text = "TAP ANYWHERE TO START"
        t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        t2.add_theme_font_size_override("font_size", 52)
        t2.add_theme_color_override("font_color", Color(1, 1, 1))
        t2.add_theme_color_override("font_outline_color", Color(0, 0, 0))
        t2.add_theme_constant_override("outline_size", 14)
        vb.add_child(t2)
        # v040-11 THE CLEAN START LAW (the owner: "remove the extra details
        # of controls and wormcoins note, if they not exist in the guide,
        # put them there"): the intro wears the worm, its name, and the
        # tap-to-start only - the controls and the coin law live in the
        # registry desc/controls (the guide), where they already were.
        _intro_pair = [_sheet_stack.back()["dim"], _sheet_stack.back()["cc"]]

func _start_run() -> void:
        if state != "intro":
                return
        state = "play"
        sheet_pop()
        _intro_pair = []
        Jukebox.music(_music_track())
        Jukebox.sfx("dw_roar", -4.0)

func _goga_sheet_popped(id: String) -> void:
        if id == "intro":
                _intro_pair = []
                if state == "intro":
                        state = "play"

# ---------------------------------------------------------------- the menus
var _worms_open := false
var _shop_open := false

func _open_worms() -> void:
        if _worms_open or state == "dead":
                return
        _worms_open = true
        var vb := sheet_push(0.0, "worms", 940.0)
        _worms_vb = vb
        _fill_worms_menu(vb)

## THE WORMS MENU (the owner: "a cool menu showing an image of the worm
## with the details and shows the current level and next level and the
## remaining") - the real numbers live here, the % stays in the run
func _fill_worms_menu(vb: VBoxContainer, scroll := true) -> void:
        for c in vb.get_children():
                vb.remove_child(c)
                c.queue_free()
        var title := Label.new()
        title.text = "THE WORMS"
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        title.add_theme_font_size_override("font_size", 40)
        title.add_theme_color_override("font_color", Color(0.32, 0.2, 0.1))
        vb.add_child(title)
        var wc := Label.new()
        wc.text = "your wormCoins: %d" % meta.coins()
        wc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        wc.add_theme_font_size_override("font_size", 26)
        wc.modulate = Color("ffd76a")
        vb.add_child(wc)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.custom_minimum_size = Vector2(880, 640)
        vb.add_child(sc)
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        for i in WORMS.size():
                box.add_child(_worm_row(i))
        var close := Arc.button("BACK", Vector2(240, 64), 28,
                Color(0.3, 0.18, 0.1), func():
                        sheet_pop()
                        _worms_open = false)
        var cc := HBoxContainer.new()
        cc.alignment = BoxContainer.ALIGNMENT_CENTER
        cc.add_child(close)
        vb.add_child(cc)
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _worm_row(i: int) -> Control:
        var w: Dictionary = WORMS[i]
        var id := String(w["id"])
        var owned := meta.owns(id)
        var lvl := meta.lvl(id)
        var maxed := lvl >= int(w["maxlvl"])
        var prev_id := String(WORMS[maxi(0, i - 1)]["id"])
        var chain_ok := i == 0 or (meta.owns(prev_id)
                and meta.lvl(prev_id) >= int(WORMS[maxi(0, i - 1)]["maxlvl"]))
        var row := PanelContainer.new()
        var st := StyleBoxFlat.new()
        st.bg_color = Color(0.12, 0.08, 0.05, 0.85) if owned \
                else Color(0.08, 0.07, 0.09, 0.9)
        st.set_corner_radius_all(16)
        st.set_content_margin_all(12)
        row.add_theme_stylebox_override("panel", st)
        var hb := HBoxContainer.new()
        hb.add_theme_constant_override("separation", 14)
        row.add_child(hb)
        var pic := TextureRect.new()
        pic.texture = load(S + "worms/%s_preview.png" % id)
        pic.custom_minimum_size = Vector2(200, 132)
        pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        if not owned:
                pic.modulate = Color(0.45, 0.45, 0.5, 0.8)
        hb.add_child(pic)
        var mid := VBoxContainer.new()
        mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hb.add_child(mid)
        var nm := Label.new()
        nm.text = "%s%s" % [String(w["name"]),
                "" if owned else "  (LOCKED)"]
        nm.add_theme_font_size_override("font_size", 28)
        mid.add_child(nm)
        var line := Label.new()
        line.text = String(w["line"])
        line.add_theme_font_size_override("font_size", 20)
        line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        line.custom_minimum_size = Vector2(300, 0)
        line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line.modulate = Color(1, 1, 1, 0.65)
        mid.add_child(line)
        if owned:
                var cur := stats_at(i, lvl)
                var nxt := stats_at(i, mini(lvl + 1, int(w["maxlvl"])))
                var lv := Label.new()
                lv.text = "LVL %d/%d" % [lvl, int(w["maxlvl"])]
                lv.add_theme_font_size_override("font_size", 24)
                lv.modulate = Color("ffd76a") if not maxed \
                        else Color("9aff9a")
                mid.add_child(lv)
                var stat := Label.new()
                stat.text = "size %.2f  speed %.2f  power %.2f  hp %d" \
                        % [float(cur["size"]), float(cur["speed"]),
                        float(cur["power"]), int(round(float(cur["hp"])))]
                stat.add_theme_font_size_override("font_size", 20)
                stat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                mid.add_child(stat)
                if not maxed:
                        var nx := Label.new()
                        nx.text = "next: size %.2f  speed %.2f  power %.2f  hp %d   -   %d pts left" \
                                % [float(nxt["size"]), float(nxt["speed"]),
                                float(nxt["power"]),
                                int(round(float(nxt["hp"]))),
                                maxi(0, xp_need(lvl) - meta.xp(id))]
                        nx.add_theme_font_size_override("font_size", 20)
                        nx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                        nx.modulate = Color(1, 1, 1, 0.75)
                        mid.add_child(nx)
                else:
                        var mx := Label.new()
                        mx.text = "MAXED - the chain opens the next worm"
                        mx.add_theme_font_size_override("font_size", 20)
                        mx.modulate = Color("9aff9a")
                        mid.add_child(mx)
        else:
                var lk := Label.new()
                if chain_ok:
                        lk.text = "unlock for %d wormCoins" % int(w["price"])
                else:
                        lk.text = "max out %s first" \
                                % String(WORMS[maxi(0, i - 1)]["name"])
                lk.add_theme_font_size_override("font_size", 22)
                lk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                lk.custom_minimum_size = Vector2(300, 0)
                lk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                lk.modulate = Color(1, 1, 1, 0.8)
                mid.add_child(lk)
        # the action button
        var act := Arc.button("RIDE" if owned and i != worm_i
                else ("IN USE" if i == worm_i else "UNLOCK"),
                Vector2(168, 60), 22,
                Color(0.35, 0.22, 0.1) if owned else Color(0.2, 0.25, 0.14),
                func(): _worm_action(i, chain_ok))
        if (owned and i == worm_i) or (not owned and
                        (not chain_ok or meta.coins() < int(w["price"]))):
                Arc.gray_out_button(act)
        hb.add_child(act)
        return row

## v040-10 THE ROUND LAW: an owned worm switch mid-run applies to the NEXT
## round - the active hunt is never corrupted by a body swap
func _worm_action(i: int, chain_ok: bool) -> void:
        var w: Dictionary = WORMS[i]
        var id := String(w["id"])
        if meta.owns(id):
                if i != worm_i:
                        meta.d["worm"] = id
                        meta.save()
                        if state == "intro":
                                # between rounds: the swap is safe now
                                worm_i = i
                                _apply_worm()
                                _build_worm_sprites()
                                _reset_run()
                                _banner("%s RIDES" % String(w["name"]),
                                        Color("ffd76a"))
                        else:
                                _banner("%s rides NEXT ROUND"
                                        % String(w["name"]), Color("ffd76a"))
                        # THE STAY-OPEN LAW: the menu refreshes in place
                        if _worms_vb != null and is_instance_valid(_worms_vb):
                                _fill_worms_menu(_worms_vb)
                return
        if not chain_ok:
                game_toast("max out the previous worm first")
                Jukebox.sfx("dw_click", -8.0)
                return
        if not meta.spend_coins(int(w["price"])):
                game_toast("not enough wormCoins")
                Jukebox.sfx("dw_click", -8.0)
                return
        meta.unlock_worm(id)
        meta.d["worm"] = id
        meta.save()
        Jukebox.sfx("dw_unlock", -2.0)
        _banner("%s UNLOCKED" % String(w["name"]), Color("ffd76a"))
        if state == "intro":
                worm_i = i
                _apply_worm()
                _build_worm_sprites()
                _reset_run()
        # THE STAY-OPEN LAW: the unlock refreshes the rows in place
        if _worms_vb != null and is_instance_valid(_worms_vb):
                _fill_worms_menu(_worms_vb)

func _open_shop() -> void:
        if _shop_open or state == "dead":
                return
        _shop_open = true
        var vb := sheet_push(0.0, "shop", 940.0)
        _shop_vb = vb
        _fill_shop(vb)

# v040-14 THE STAY-OPEN LAW (the owner: "when something get bought, do not
# make it quit shop by itself, close button is there for this thing"):
# every purchase/visit refreshes the sheet IN PLACE - the sheet only ever
# closes through its own BACK / X button
var _shop_vb: VBoxContainer = null
var _worms_vb: VBoxContainer = null

## THE SHOP: the PLACES (real GOGACoins, the coin icon law, the dry-wallet
## gray-out law) + the POWER-UPS (also real GOGACoins - the owner's
## v040-10 law) - one currency, the box's own
func _fill_shop(vb: VBoxContainer) -> void:
        for c in vb.get_children():
                vb.remove_child(c)
                c.queue_free()
        var title := Label.new()
        title.text = "THE SHOP"
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        title.add_theme_font_size_override("font_size", 40)
        title.add_theme_color_override("font_color", Color(0.32, 0.2, 0.1))
        vb.add_child(title)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.custom_minimum_size = Vector2(880, 660)
        vb.add_child(sc)
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        var ph := Label.new()
        ph.text = "PLACES  -  GOGACoins"
        ph.add_theme_font_size_override("font_size", 26)
        ph.modulate = Color("ffd76a")
        box.add_child(ph)
        for pid in PLACES:
                box.add_child(_place_row(pid))
        var ph2 := Label.new()
        ph2.text = "POWER-UPS  -  GOGACoins"
        ph2.add_theme_font_size_override("font_size", 26)
        ph2.modulate = Color("ffd76a")
        box.add_child(ph2)
        for p in POWS:
                box.add_child(_pow_row(p))
        var close := Arc.button("BACK", Vector2(240, 64), 28,
                Color(0.3, 0.18, 0.1), func():
                        sheet_pop()
                        _shop_open = false)
        var cc := HBoxContainer.new()
        cc.alignment = BoxContainer.ALIGNMENT_CENTER
        cc.add_child(close)
        box.add_child(cc)
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _place_row(pid: String) -> Control:
        var p: Dictionary = PLACES[pid]
        var owned := meta.owns_place(pid)
        var active := pid == place_id
        var row := PanelContainer.new()
        var st := StyleBoxFlat.new()
        st.bg_color = Color(0.12, 0.08, 0.05, 0.85) if owned \
                else Color(0.08, 0.07, 0.09, 0.9)
        st.set_corner_radius_all(16)
        st.set_content_margin_all(10)
        row.add_theme_stylebox_override("panel", st)
        var hb := HBoxContainer.new()
        hb.add_theme_constant_override("separation", 12)
        row.add_child(hb)
        var pic := TextureRect.new()
        pic.texture = load(S + "shop/%s.png" % pid)
        pic.custom_minimum_size = Vector2(196, 108)
        pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        if not owned:
                pic.modulate = Color(0.45, 0.45, 0.5, 0.8)
        hb.add_child(pic)
        var mid := VBoxContainer.new()
        mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hb.add_child(mid)
        var nm := Label.new()
        nm.text = "%s%s" % [String(p["name"]), "  (HERE)" if active else ""]
        nm.add_theme_font_size_override("font_size", 26)
        mid.add_child(nm)
        var note := Label.new()
        note.text = String(p["note"])
        note.add_theme_font_size_override("font_size", 20)
        note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        note.custom_minimum_size = Vector2(280, 0)
        note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        note.modulate = Color(1, 1, 1, 0.7)
        mid.add_child(note)
        var act: Button
        if owned:
                act = Arc.button("VISIT" if not active else "IN USE",
                        Vector2(190, 62), 24, Color(0.35, 0.22, 0.1),
                        func(): _visit_place(pid))
                if active:
                        Arc.gray_out_button(act)
        else:
                act = Arc.coin_button("%d" % int(p["price"]),
                        Vector2(190, 62), 24, Color(0.2, 0.25, 0.14),
                        func(): _buy_place(pid))
                if Box.coins() < int(p["price"]):
                        Arc.gray_out_button(act)
        hb.add_child(act)
        return row

## v040-10 THE NEXT-ROUND LAW (the owner: "switching to be applied for the
## next round and not the active one"): mid-run a visit only ARMS the
## place - the world rebuilds when the round ends (or right away when
## nobody is hunting yet)
func _visit_place(pid: String) -> void:
        meta.set_place(pid)
        if state == "intro":
                place_id = pid
                _rebuild_place()
                _banner("%s" % String(PLACES[pid]["name"]), Color("9ad8ff"))
                # THE STAY-OPEN LAW: the shop refreshes, it never quits itself
                if _shop_vb != null and is_instance_valid(_shop_vb):
                        _fill_shop(_shop_vb)
        else:
                _banner("%s NEXT ROUND" % String(PLACES[pid]["name"]),
                        Color("9ad8ff"))
                game_toast("%s opens on your next round"
                        % String(PLACES[pid]["name"]))
                if _shop_vb != null and is_instance_valid(_shop_vb):
                        _fill_shop(_shop_vb)

func _buy_place(pid: String) -> void:
        var price := int(PLACES[pid]["price"])
        if not Box.spend(price):
                game_toast("not enough GOGACoins")
                Jukebox.sfx("dw_click", -8.0)
                return
        meta.unlock_place(pid)
        meta.set_place(pid)
        Jukebox.sfx("dw_unlock", -2.0)
        _banner("WELCOME TO %s" % String(PLACES[pid]["name"]),
                Color("9ad8ff"))
        if state == "intro":
                place_id = pid
                _rebuild_place()
        else:
                game_toast("%s opens on your next round"
                        % String(PLACES[pid]["name"]))
        # THE STAY-OPEN LAW: the buy refreshes the rows in place
        if _shop_vb != null and is_instance_valid(_shop_vb):
                _fill_shop(_shop_vb)

## the world's full rebuild for a new place (fresh sky/dirt/far/bounds)
func _rebuild_place() -> void:
        if world != null and is_instance_valid(world):
                world.queue_free()
        _fr_cache.clear()
        _fam_cache.clear()
        _build_world()

func _pow_row(p: Dictionary) -> Control:
        var k := String(p["k"])
        var owned := meta.owns_pow(k)
        var row := PanelContainer.new()
        var st := StyleBoxFlat.new()
        st.bg_color = Color(0.12, 0.08, 0.05, 0.85) if owned \
                else Color(0.08, 0.07, 0.09, 0.9)
        st.set_corner_radius_all(16)
        st.set_content_margin_all(10)
        row.add_theme_stylebox_override("panel", st)
        var hb := HBoxContainer.new()
        hb.add_theme_constant_override("separation", 12)
        row.add_child(hb)
        var pic := TextureRect.new()
        pic.texture = load(S + "pows/%s.png" % k)
        pic.custom_minimum_size = Vector2(96, 96)
        pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        hb.add_child(pic)
        var mid := VBoxContainer.new()
        mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hb.add_child(mid)
        var nm := Label.new()
        nm.text = String(p["name"])
        nm.add_theme_font_size_override("font_size", 26)
        mid.add_child(nm)
        var note := Label.new()
        note.text = String(p["line"])
        note.add_theme_font_size_override("font_size", 20)
        note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        note.custom_minimum_size = Vector2(280, 0)
        note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        note.modulate = Color(1, 1, 1, 0.7)
        mid.add_child(note)
        var act: Button
        if owned:
                act = Arc.button("OWNED", Vector2(190, 62), 24,
                        Color(0.25, 0.2, 0.12), func(): pass)
                Arc.gray_out_button(act)
        else:
                # THE REAL COIN LAW (v040-10): power-ups price in
                # GOGACoins - the box's own coin, the coin icon on the
                # button, the dry wallet gray-out
                act = Arc.coin_button("%d" % int(p["price"]),
                        Vector2(190, 62), 24, Color(0.2, 0.25, 0.14),
                        func(): _buy_pow(k))
                if Box.coins() < int(p["price"]):
                        Arc.gray_out_button(act)
        hb.add_child(act)
        return row

func _buy_pow(k: String) -> void:
        var price := 0
        for p in POWS:
                if String(p["k"]) == k:
                        price = int(p["price"])
        if not Box.spend(price):
                game_toast("not enough GOGACoins")
                Jukebox.sfx("dw_click", -8.0)
                return
        meta.unlock_pow(k)
        Jukebox.sfx("dw_unlock", -2.0)
        game_toast("%s unlocked - it can drop in your runs now"
                % _pow_name(k))
        # THE STAY-OPEN LAW: the buy refreshes the rows in place
        if _shop_vb != null and is_instance_valid(_shop_vb):
                _fill_shop(_shop_vb)

# ==================================================================== death
func _die() -> void:
        if state == "dead":
                return
        state = "dead"
        Jukebox.sfx("dw_die", -2.0)
        shake = 16.0
        _explode(pts[0], 2.4)
        meta.record_run(score, run_t, eaten_humans, eaten_animals,
                eaten_ground, vehicles)
        # the /500 gate bonus is the HOST's math (coin_div) - the game never
        # double-pays it. The wormCoins banked live during the run.
        finish_run(score, 0)
