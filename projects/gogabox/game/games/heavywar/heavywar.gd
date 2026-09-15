extends GogaGame
## HEAVY WAR (v040-2) - the rogue-like horizontal tank siege, REBUILT on the
## original's own laws. Every number in play was read out of the source
## game's data files (waves.xml / craft.xml / levels.xml / bosses.xml) and
## every pixel is the original's own (composed color + mask luminance).
##
## THE V040-2 TRUTHS (each one answers the owner's report):
##  * the world wears the source's real four-plane stack - sky painting,
##    far strip, mid strip, ground band - anchored to one ground line,
##    every layer at TRUE 2.25x (no mixed factors, no opaque rectangles
##    eating the sky);
##  * the props are BAKED to their planes at the source's own offsets
##    (they ride their plane's speed and repeat with its period, exactly
##    like the source's baked strips - no more clumps popping in);
##  * the arm picks the gun.png cell the source picked: 24 angle columns
##    x FIVE gun-power tier rows, fractionally interpolated (buttery);
##  * the aim cursor is the source's own red reticle (target1-8, animated);
##  * shells/bombs/missiles pick PRE-RENDERED rotation frames - the source
##    never rotated a sprite, the strips carry every angle;
##  * impacts wear the source's VFX: the 20-frame explosion, craters
##    stamped on the road, smoke, sparks, debris, the shield bubble +
##    zap, the tank flash - "proper VFXs for the shots when they land";
##  * the waves are the source's OWN 19 levels verbatim, consumed by
##    distance the way the source consumed them;
##  * collectables ride ONLY the white friend helicopter's crates;
##  * the six upgrades are the source's own six weapon systems;
##  * the empty original top-bar widgets are GONE - our own top bar
##    carries lives / shields / nukes chips with the original icons.

## THE LIVE CANVAS LAW (the owner's v040 empty-area report died here):
## the box's stretch law EXPANDS the canvas on any phone (a 20:9 window
## gives 2400x1080 design px), so the world reads the LIVE viewport -
## never a hardcoded 16:9 corner.
var W := 1920.0
var H := 1080.0
const SC := HWData.SC                     # 2.25 - the one true scale
const GROUND_H := 60.0 * SC               # 135 - the source's own band
var GROUND_Y := 945.0                     # the ground line (H - GROUND_H)
var ROAD_Y := 1007.0                      # where the bombs meet the road
var TANK_Y := 1023.0                      # the tank's ride height
const FAR_H := 300.0 * SC                 # 675 - the far/mid strip height

# THE PLANE LAW (the source's own parallax order): sky crawls, the far
# strip walks, the mid strip jogs, the ground carries the war.
const PLANE_SKY := 0.055
const PLANE_FAR := 0.28
const PLANE_MID := 0.45
const PLANE_GROUND := 1.0
const WORLD_SPEED := HWData.GROUND_SPEED  # ~155 px/s of true ground

# THE THREE-ZONE TOUCH LAW (the GDD): bottom = steer, center = aim + fire,
# top = nuke. A finger takes its role at touchdown and keeps it until
# lift - leaving the zone never stops the role (the owner's exact wording).
var Z_STEER_Y := 720.0
var Z_NUKE_Y := 360.0

const ART := "res://assets/games/heavywar/"
const SRC_ART := "res://assets/games/hwsrc/"

# THE PLACE -> ORIGINAL LAYERS MAP (the owner's as-is law):
# our ten places wear the original's real sky / far / mid / ground art.
const ORIG_BG := {
        "frostkrai": "frigistan", "gulfgate": "blastnya",
        "oilreach": "petrovakia", "nukeflats": "dictastroika",
        "vinebelt": "zamblamia", "gloomkeep": "tankylvania",
        "ashfall": "vodkavania", "dunefort": "antagonistan",
        "steelcrown": "killingrad", "ironhold": "redstarhq",
}

enum GS { INTRO, PLACE, CALM, TUNNEL, BOSS, ARMORY, OVER }

# ------------------------------------------------------------- run state
var state: int = GS.INTRO
var meta: HWMeta
var run := {}                    # the run ledger (see _run_reset)
var place: Dictionary = {}       # the live place table
var place_queue: Array = []      # shuffled place indices for this run
var t_state := 0.0               # seconds in the current state

# nodes
var world: Node2D                # the scrolling stage (parallax + road)
var tank: Node2D
var heli: Node2D                 # the friend helicopter
var ent_layer: Node2D            # enemies + bosses
var shot_layer: Node2D           # shells, bombs, missiles, debris
var fx_layer: Node2D             # explosions, rings, texts
var war_layer: CanvasLayer       # the boss bar + the danger sign

# pools (dictionaries - the house way)
var enemies: Array = []          # {id, n, hp, maxhp, kind, wpn, t, ...}
var shots: Array = []            # shells {n, vel, dmg, tier}
var ebombs: Array = []           # enemy fire {n, vel, kind, dmg, ...}
var drops: Array = []            # crates + powerup orbs {n, kind, ...}
var fx: Array = []               # {n, t, life, kind}
var decals: Array = []           # ground craters {n, t}
var debris: Array = []           # tumbling chunks {n, vel, spin}

# input (true multi-touch: the kit is single-pointer, the war is not)
var steer_ptr := -1
var steer_target_x := 0.0
var aim_ptr := -1
var aim_pos := Vector2(960.0, 380.0)
var nuke_ptrs := {}              # legacy tap detector (kept for probes)

# the world scroll + the place props (the Anims law, as-is art)
var scroll_x := 0.0              # GROUND px scrolled since the run began
var props: Array = []            # plane-locked props
var prop_spawned := {}           # plane -> sets already walked out
var gun_tier := 0                # the arm's in-run power tier 0..4
var gun_tier_t := 0.0            # pickup blink timer

# hud chip refs (our own top bar)
var chips := {}

func _goga_setup() -> void:
        # THE CANVAS LAW: fit the design to the real window, then read it
        ScaleRule.apply(get_window())
        var vp := get_viewport_rect().size
        W = maxf(960.0, vp.x)
        H = maxf(540.0, vp.y)
        GROUND_Y = H - GROUND_H
        ROAD_Y = GROUND_Y + 62.0
        TANK_Y = GROUND_Y + 78.0
        Z_NUKE_Y = H / 3.0
        Z_STEER_Y = H * 2.0 / 3.0
        meta = HWMeta.load_meta()
        game_id = "heavywar"
        pause_end_run = false
        _run_reset()
        _build_world()
        _build_chips()
        add_hud_button("SHOP", func(): _shop_open())
        _apply_skin()
        _enter_intro()

# =================================================================
# THE RUN LEDGER
# =================================================================
func _run_reset() -> void:
        var shuf := []
        for i in HWData.PLACES.size():
                shuf.append(i)
        shuf.shuffle()
        run = {
                "place_i": 0,            # index into place_queue
                "places_done": 0,        # places fully survived
                "bosses_met": 0,
                "lives": HWData.LIVES_MAX,
                "shields": 0,            # sphere layers (max 3)
                "shield_hp": [],         # per-layer hits left
                "nukes": HWData.start_nukes(),
                "laser_parts": 0,        # components collected this run
                "laser_on": 0.0,         # >0 = the megabeam is burning
                "iframes": 0.0,
                "fire_cd": 0.0,
                "score_life_mark": 0,    # the last score mark that paid a life
                "supply_t": HWData.SUPPLY_PERIOD * 0.5,
                "coin_due": 3,           # the every-3-places coin law
                "kills": 0,
                "calm_t": 0.0,
        }
        gun_tier = 0
        scroll_x = 0.0

# =================================================================
# THE WORLD - the source's own four-plane stack + the tank + the friend
# =================================================================
func _build_world() -> void:
        world = Node2D.new()
        add_child(world)
        ent_layer = Node2D.new()
        add_child(ent_layer)
        shot_layer = Node2D.new()
        add_child(shot_layer)
        fx_layer = Node2D.new()
        add_child(fx_layer)

        # THE FOUR REAL PLANES: z law guarantees the source's stacking -
        # sky behind far behind mid behind ground; each plane's own props
        # ride BETWEEN its neighbours (4->-35, 3->-25, 2->-15, 1->-5).
        world.set_meta("sky", _mk_layer(-40))
        world.set_meta("far", _mk_layer(-30))
        world.set_meta("mid", _mk_layer(-20))
        world.set_meta("ground", _mk_layer(-10))
        var props_l := Node2D.new()
        world.add_child(props_l)
        world.set_meta("props", props_l)
        _dress_place(0)

        tank = Node2D.new()
        tank.position = Vector2(W * 0.35, TANK_Y)
        tank.z_index = 5
        add_child(tank)
        var skin := _skin_node()
        tank.add_child(skin)
        tank.set_meta("body", skin.get_meta("body"))
        tank.set_meta("turret", skin.get_meta("turret"))
        tank.set_meta("skin", "olive")

        heli = Node2D.new()
        heli.visible = false
        heli.z_index = 8
        add_child(heli)

        # THE AIM CURSOR: the source's own red reticle, animated, riding
        # the aim finger (the owner: "the original game has proper one")
        var aim_cur := Node2D.new()
        aim_cur.z_index = 90
        aim_cur.visible = false
        var amat := CanvasItemMaterial.new()
        amat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        var aspr := Sprite2D.new()
        aspr.texture = _src_tex("sprites/target1.png")
        aspr.material = amat
        aim_cur.add_child(aspr)
        aim_cur.set_meta("spr", aspr)
        aim_cur.set_meta("t", 0.0)
        add_child(aim_cur)
        world.set_meta("aim_cursor", aim_cur)

## a leaf pair that leapfrogs by the texture's own period; the region
## repeat makes ONE sprite tile the whole visible band
func _mk_layer(z: int) -> Dictionary:
        var holder := Node2D.new()
        holder.z_index = z
        world.add_child(holder)
        return {"node": holder, "scroll": 0.0, "off": 0.0, "period": 1.0,
                "leaves": []}

func _src_tex(rel: String) -> Texture2D:
        var p := SRC_ART + rel
        if ResourceLoader.exists(p):
                return load(p)
        return null

## fill a layer with the tiling texture at the TRUE scale: the tile width
## is the original's own width x SC, the band bottom sits at bottom_y
func _layer_fill(l: Dictionary, tex: Texture2D, tile_w: float,
        band_h: float, bottom_y: float) -> void:
        var holder: Node2D = l["node"]
        for c in holder.get_children():
                c.queue_free()
        l["leaves"] = []
        l["off"] = 0.0
        l["period"] = tile_w
        if tex == null:
                var r := ColorRect.new()
                r.color = Color(0.08, 0.08, 0.08)
                r.size = Vector2(tile_w + 4.0, band_h)
                r.position = Vector2(0, bottom_y - band_h)
                holder.add_child(r)
                l["leaves"].append(r)
                return
        var ts: Vector2 = tex.get_size()
        var sc: float = tile_w / ts.x        # = SC for the true-width tiles
        var draw_h: float = ts.y * sc
        # the sky stretches its own band to cover any canvas height (the
        # ground line rules the rest; the sky is the give)
        var sy := sc
        var top_y := bottom_y - draw_h
        if band_h >= H - 1.0:
                sy = H / ts.y
                top_y = bottom_y - ts.y * sy
        for k in 3:
                var sp := Sprite2D.new()
                sp.texture = tex
                sp.centered = false
                sp.scale = Vector2(sc, sy)
                sp.position = Vector2(float(k) * tile_w, top_y)
                holder.add_child(sp)
                l["leaves"].append(sp)

func _layer_roll(l: Dictionary, dx: float) -> void:
        var period: float = float(l["period"])
        l["off"] = fmod(float(l["off"]) + dx, period)
        var x: float = -float(l["off"])
        var leaves: Array = l.get("leaves", [])
        for k in leaves.size():
                var leaf: CanvasItem = leaves[k]
                if is_instance_valid(leaf):
                        leaf.position.x = x if k == 0 else x + period

## THE PLACE DRESSING - the original's real layers, composed + true-scaled
func _dress_place(pi: int) -> void:
        place = HWData.PLACES[pi if pi < HWData.PLACES.size() else 0]
        var oid := String(ORIG_BG.get(String(place["id"]), "frigistan"))
        var dir := "backgrounds/"
        # SKY: the source's full 640x480 painting, tiled at true scale
        var sky: Dictionary = world.get_meta("sky")
        _layer_fill(sky, _src_tex(dir + oid + "_sky.jpg"), 640.0 * SC, H, H)
        # FAR: the composed mountain strip (960x300 + its mask = alpha)
        var far: Dictionary = world.get_meta("far")
        _layer_fill(far, _src_tex(dir + oid + "_bg.png"), 960.0 * SC,
                FAR_H, GROUND_Y)
        # MID: the composed near ridge, anchored on the same ground line
        var mid: Dictionary = world.get_meta("mid")
        _layer_fill(mid, _src_tex(dir + oid + "_bg2.png"), 960.0 * SC,
                FAR_H, GROUND_Y)
        # GROUND: the source's own 640x60 band the tank rides
        var gnd: Dictionary = world.get_meta("ground")
        _layer_fill(gnd, _src_tex(dir + oid + "_ground.png"), 640.0 * SC,
                GROUND_H, H)
        _props_reset()

# ------------------------------------------------------------- THE PROPS
## THE BAKED-STRIP LAW: a prop belongs to its PLANE - it holds its slot
## on the plane and repeats with the plane's own period (sky/ground tile
## every 640 original px, the far/mid strips every 960). When the plane's
## scroll walks far enough, the next set enters on the right - the source's
## own rhythm, no clumps, no popping.
const PLANE_PERIOD := {3: 960.0, 2: 960.0, 1: 640.0}

func _props_reset() -> void:
        var pl: Node2D = world.get_meta("props")
        for c in pl.get_children():
                c.queue_free()
        props.clear()
        prop_spawned = {3: 0, 2: 0, 1: 0}

func _plane_off(plane: int) -> float:
        match plane:
                3: return float(world.get_meta("far")["off"])
                2: return float(world.get_meta("mid")["off"])
                _: return float(world.get_meta("ground")["off"])

func _props_tick(dt: float, ground_dx: float) -> void:
        var pl: Node2D = world.get_meta("props")
        # walk each plane's set frontier: spawn the next set when the
        # plane's own scroll opened the room for it
        for plane in [3, 2, 1]:
                var period: float = float(PLANE_PERIOD[plane]) * SC
                var off := _plane_off(plane)
                var speed_f: float = {3: PLANE_FAR, 2: PLANE_MID,
                        1: PLANE_GROUND}[plane]
                var need: int = int((off + W + 400.0) / period) + 1
                while int(prop_spawned[plane]) < need:
                        _props_spawn_set(plane, int(prop_spawned[plane]),
                                period, speed_f)
                        prop_spawned[plane] = int(prop_spawned[plane]) + 1
        var dead: Array = []
        for p in props:
                var n: Sprite2D = p["n"]
                if not is_instance_valid(n):
                        dead.append(p)
                        continue
                # the prop holds its slot: the plane's own delta + drift
                n.position.x -= p["dx"] * dt
                if int(p["frames"]) > 1 and float(p["fps"]) > 0.0:
                        p["t"] = float(p["t"]) + dt
                        var adv := int(p["t"] * float(p["fps"]))
                        p["t"] = float(p["t"]) - float(adv) / float(p["fps"])
                        var f := int(p["frame"]) + adv
                        var fr := int(p["frames"])
                        if String(p["type"]) == "pingpong":
                                var cyc := f % (fr * 2 - 2)
                                p["frame"] = cyc if cyc < fr \
                                        else (fr * 2 - 2 - cyc)
                        else:
                                p["frame"] = f % fr
                        n.frame = int(p["frame"])
                if n.position.x < -600.0:
                        dead.append(p)
        for p in dead:
                props.erase(p)
                if is_instance_valid(p["n"]):
                        (p["n"] as Sprite2D).queue_free()

## one set = every non-rare prop of the place for ONE plane period, at
## the source's own offsets; rare props join every third set
func _props_spawn_set(plane: int, set_i: int, period: float,
        speed_f: float) -> void:
        var pl: Node2D = world.get_meta("props")
        var off := _plane_off(plane)
        for r in HWProps.PROPS:
                if int(r["plane"]) != plane:
                        continue
                if String(r["p"]) != String(place["id"]):
                        continue
                if bool(r["rare"]) and set_i % 3 != 1:
                        continue
                var tex := load(String(r["tex"])) as Texture2D
                if tex == null:
                        continue
                var n := Sprite2D.new()
                n.texture = tex
                var frames := int(r["frames"])
                var ts: Vector2 = tex.get_size()
                if frames > 1:
                        n.hframes = frames
                        n.frame = 0
                        ts.x = ts.x / float(frames)
                n.scale = Vector2(SC, SC)
                var slot: float = set_i * period \
                        + float(r["offset"]) * SC
                n.position = Vector2(slot - off, float(r["y"]) * SC)
                n.z_index = {4: -35, 3: -25, 2: -15, 1: -5}[plane]
                pl.add_child(n)
                props.append({"n": n, "frames": frames,
                        "fps": float(r["speed"]) * 100.0,
                        "type": String(r["type"]),
                        "dx": WORLD_SPEED * speed_f
                                + float(r["mx"]) * 100.0 * SC,
                        "t": 0.0, "frame": 0})

## THE SKIN SLOT: olive is the base sprite; the shop's skins are the
## recolored tanks the art tool painted. One rebuild point, live-swappable.
func _skin_id() -> String:
        var s := Box.skin_on(game_id)
        return "olive" if s.is_empty() else s

func _skin_node() -> Node2D:
        # THE REAL ATOMIC TANK (as-is): the 10-frame drive strip + the
        # 24x5 arm strip (angle columns x GUN POWER tier rows).
        var root := Node2D.new()
        var body := Sprite2D.new()
        body.texture = _src_tex("sprites/tank.png")
        body.hframes = 10
        body.frame = 0
        body.scale = Vector2(SC, SC)
        root.add_child(body)
        root.set_meta("body", body)
        var turret := Sprite2D.new()
        turret.texture = _src_tex("sprites/gun.png")
        turret.hframes = 24
        turret.vframes = 5
        turret.frame = 12            # col 12 (up) of row 0 (tier 0)
        turret.scale = Vector2(SC, SC)
        # the arm pivots on the tank's turret ring (the cell's hub)
        turret.position = Vector2(0, -34.0)
        root.add_child(turret)
        root.set_meta("turret", turret)
        var shadow := Sprite2D.new()
        shadow.texture = _src_tex("sprites/tankshadow.png")
        shadow.scale = Vector2(SC, SC)
        shadow.position = Vector2(0, 62.0)
        shadow.z_index = -1
        root.add_child(shadow)
        return root

## THE SKIN LAW (v040-1): the original tank is the body; the shop's
## skins are modulate tints on it (reversible, the pixels stay as-is).
func _apply_skin() -> void:
        if tank == null or not is_instance_valid(tank):
                return
        var sid := _skin_id()
        tank.set_meta("skin", sid)
        var body: Sprite2D = tank.get_meta("body")
        var tints := {
                "olive": Color(1, 1, 1), "desert": Color(0.95, 0.82, 0.55),
                "arctic": Color(0.82, 0.92, 1.0), "navy": Color(0.55, 0.68, 0.95),
                "crimson": Color(1.0, 0.5, 0.45), "gold": Color(1.0, 0.85, 0.3),
        }
        body.modulate = tints.get(sid, Color(1, 1, 1))

# =================================================================
# THE ART INDIRECTION (v040-2): every id points at the COMPOSED original
# texture with its TRUE frame count (the strips were counted by eye and
# by seam - no more squeezed cells, no more raw masks, no white boxes).
const SRC_SPRITES := {
        "enemy_scout": {"p": "sprites/propfighter.png", "hf": 4},
        "enemy_dart": {"p": "sprites/smalljet.png"},
        "enemy_raider": {"p": "sprites/bomber.png"},
        "enemy_lynx": {"p": "sprites/jetfighter.png"},
        "enemy_komet": {"p": "sprites/bigmissile.png", "hf": 3},
        "enemy_skimmer": {"p": "sprites/cruise.png", "hf": 8},
        "enemy_fang": {"p": "sprites/deltajet.png"},
        "enemy_talon": {"p": "sprites/deltabomber.png"},
        "enemy_wasp": {"p": "sprites/smallcopter.png", "hf": 5},
        "enemy_hornet": {"p": "sprites/medcopter.png", "hf": 7},
        "enemy_mirror": {"p": "sprites/deflector.png"},
        "enemy_strafer": {"p": "sprites/strafer.png", "hf": 10},
        "enemy_technical": {"p": "sprites/truck.png", "hf": 10},
        "enemy_carpet": {"p": "sprites/bigbomber.png"},
        "enemy_viper": {"p": "sprites/bigcopter.png", "hf": 9},
        "enemy_mammoth": {"p": "sprites/bigcopter.png", "hf": 9},
        "enemy_fortress": {"p": "sprites/superbomber.png"},
        "enemy_orbital": {"p": "sprites/satellite.png", "hf": 10},
        "enemy_grinder": {"p": "sprites/enemytank.png", "hf": 10},
        "enemy_plowman": {"p": "sprites/dozer.png", "hf": 10},
        "enemy_atomault": {"p": "sprites/fatbomber.png"},
        "enemy_zeppelin": {"p": "sprites/blimp.png"},
        "boss_gunship": {"p": "bosses/hugecopter/hugecopter.png"},
        "boss_gunship_turret": {"p": "bosses/hugecopter/turret.png"},
        "boss_gunship_launcher": {"p": "bosses/hugecopter/launcher.png"},
        "boss_dreadnought": {"p": "bosses/battleship/main.png"},
        "boss_dreadnought_t1": {"p": "bosses/battleship/gun.png"},
        "boss_dreadnought_t4": {"p": "bosses/battleship/gun.png"},
        "boss_dreadnought_launcher": {"p": "bosses/battleship/hull.png"},
        "boss_skystealer": {"p": "bosses/rainer/Rainer.png"},
        "boss_wreckball": {"p": "bosses/wrecker/body.png"},
        "boss_warhead": {"p": "bosses/head/head.png"},
        "boss_kongo": {"p": "bosses/ape/ape.png"},
        "boss_eyebot": {"p": "bosses/eye/eye.png"},
        "boss_eyebot_hand": {"p": "bosses/eye/hand.png"},
        "boss_mechworm": {"p": "bosses/worm/head.png"},
        "boss_mechworm_turret": {"p": "bosses/worm/turret.png"},
        "boss_warbot": {"p": "bosses/robot/body.png"},
        "boss_warbot_arm": {"p": "bosses/robot/arms.png"},
        "boss_warbot_launcher": {"p": "bosses/robot/launchers.png"},
        "boss_secretfist": {"p": "bosses/finalboss/body1.png"},
        # THE SHELL: bullets.png = 5 gun-power tier rows x 21 angle cols
        # of 24x12 cells - the tier row follows the arm's tier.
        "shell": {"p": "sprites/bullets.png", "cell": [24, 12],
                "cols": 21, "rows": 5, "angle_cols": true},
        # the rotation strips: the source picked angle frames, never spun
        "eshot_bullet": {"p": "sprites/enemygun.png", "hf": 10, "vf": 2,
                "rot": 20},
        "eshot_missile": {"p": "sprites/missile.png", "hf": 20, "rot": 20},
        "eshot_rpg": {"p": "sprites/rpg.png", "hf": 10, "rot": 10},
        "eshot_hellfire": {"p": "sprites/hellfire.png", "hf": 21, "rot": 21},
        "eshot_headmissile": {"p": "sprites/headmissile.png", "hf": 20,
                "rot": 20},
        "eshot_meteor": {"p": "sprites/meteorite.png", "hf": 10},
        "eshot_boulder": {"p": "sprites/boulder.png", "hf": 5},
        "eshot_barrel": {"p": "sprites/crates.png", "region": [72, 0, 36, 36]},
        "eshot_ball": {"p": "bosses/wrecker/ball.png"},
        "bomb_dumb": {"p": "sprites/dumbbomb.png", "hf": 10, "rot": 10},
        "bomb_guided": {"p": "sprites/lgb.png", "hf": 21, "rot": 21},
        "bomb_armored": {"p": "sprites/ironbomb.png", "hf": 10, "rot": 10},
        "bomb_frag": {"p": "sprites/fragbomb.png", "hf": 10, "rot": 10},
        "bomb_atom": {"p": "sprites/fatboy.png", "hf": 10, "rot": 10},
        # THE IMPACT FAMILY (the source's own VFX, composed)
        "boom": {"p": "sprites/explosion.png", "hf": 20},
        "crater": {"p": "sprites/crater.png", "hf": 5},
        "smoke": {"p": "sprites/smoke.png"},
        "dust": {"p": "sprites/sanddust.png"},
        "debris": {"p": "sprites/bigdebris.png", "hf": 6},
        "spark": {"p": "sprites/spark.png", "hf": 10},
        "casing": {"p": "sprites/casing.png"},
        "muzzle": {"p": "sprites/muzzleflash.png", "hf": 5},
        "tankflash": {"p": "sprites/tankflash.png"},
        "shieldbubble": {"p": "sprites/shield.jpg", "hf": 10, "add": true},
        "shieldzap": {"p": "sprites/shieldzap.png", "hf": 10, "add": true},
        "orb": {"p": "sprites/orb.png", "hf": 2},
        "tankflame": {"p": "sprites/tankflame.png", "hf": 20},
        "mushsmoke": {"p": "sprites/mushsmoke.png", "hf": 3},
        "mushfire": {"p": "sprites/mushfire.jpg", "hf": 3, "add": true},
        "nukeflash": {"p": "sprites/nukebg.jpg", "add": true},
        "danger": {"p": "sprites/danger.png"},
        "beamfire": {"p": "sprites/beamfire.png", "hf": 5},
        # the cyan megabeam: lasers.png = 21 frames of 80x40, 3 rows
        "megabeam": {"p": "sprites/lasers.png", "cell": [80, 40],
                "cols": 21, "rows": 3},
        "crate": {"p": "sprites/crates.png", "hf": 4},
        "heli": {"p": "sprites/pupcopter.png"},
        "helirotor": {"p": "sprites/puprotor.png", "hf": 7},
}

func _art_sprite(art_id: String, size: Vector2, tint: Color) -> Node2D:
        var holder := Node2D.new()
        var m: Dictionary = SRC_SPRITES.get(art_id, {})
        var tex: Texture2D = null
        if not m.is_empty():
                tex = _src_tex(String(m["p"]))
        if tex != null:
                # THE BLEND LAW: the source's black-plate sprites (the
                # shield dome, the zap, the mushroom fire) burn additively
                # - the material rides the SPRITE, holders never inherit.
                var amat: CanvasItemMaterial = null
                if bool(m.get("add", false)):
                        amat = CanvasItemMaterial.new()
                        amat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
                if m.has("region"):
                        var r: Array = m["region"]
                        var sp := Sprite2D.new()
                        sp.texture = tex
                        sp.material = amat
                        sp.region_enabled = true
                        sp.region_rect = Rect2(r[0], r[1], r[2], r[3])
                        sp.scale = size / Vector2(r[2], r[3])
                        holder.add_child(sp)
                        return holder
                if m.has("cell"):
                        # the grid sheets (shell / megabeam): one cell out
                        var c: Array = m["cell"]
                        var sp3 := Sprite2D.new()
                        sp3.texture = tex
                        sp3.material = amat
                        sp3.hframes = int(m["cols"])
                        sp3.vframes = int(m["rows"])
                        sp3.frame = 0
                        sp3.scale = size / Vector2(c[0], c[1])
                        holder.add_child(sp3)
                        holder.set_meta("spr", sp3)
                        holder.set_meta("grid", m)
                        return holder
                var hf: int = int(m.get("hf", 1))
                var vf: int = int(m.get("vf", 1))
                var cell: Vector2 = tex.get_size()
                if hf > 1:
                        cell.x = cell.x / float(hf)
                if vf > 1:
                        cell.y = cell.y / float(vf)
                var sp2 := Sprite2D.new()
                sp2.texture = tex
                sp2.material = amat
                sp2.hframes = hf
                sp2.vframes = vf
                sp2.frame = 0
                sp2.scale = size / cell
                holder.add_child(sp2)
                holder.set_meta("spr", sp2)
                holder.set_meta("rot", int(m.get("rot", 0)))
                return holder
        # the honest fallback (unmapped ids only)
        var r2 := ColorRect.new()
        r2.color = tint
        r2.size = size
        r2.position = -size / 2.0
        holder.add_child(r2)
        var rim := ReferenceRect.new()
        rim.border_color = tint.darkened(0.4)
        rim.border_width = 3.0
        rim.editor_only = false
        rim.size = size
        rim.position = -size / 2.0
        holder.add_child(rim)
        return holder

## the source's rotation law: the strip carries every angle pre-rendered;
## pick the frame whose angle matches the velocity (never rotate the node)
func _set_rot_frame(n: Node2D, vel: Vector2) -> void:
        var total := int(n.get_meta("rot", 0))
        if total <= 0:
                return
        var deg := rad_to_deg(vel.angle())
        # the strips draw frame 0 pointing RIGHT, sweeping a full circle
        var f := int(round((deg + 360.0) / 360.0 * float(total))) % total
        var spr: Sprite2D = n.get_meta("spr", null)
        if spr != null:
                spr.frame = f
                spr.rotation = 0.0

## the shell's own law: bullets.png 21 angle columns x the tier row
func _set_shell_frame(n: Node2D, vel: Vector2, tier: int) -> void:
        var spr: Sprite2D = n.get_meta("spr", null)
        if spr == null:
                return
        var to := vel.angle()
        var t: float = (to + PI) / PI          # 0 = left .. 1 = right
        var col := clampi(int(round(t * 20.0)), 0, 20)
        spr.frame = col + clampi(tier, 0, 4) * 21

# =================================================================
# OUR OWN TOP BAR - the lives / shields / nukes chips (the original's
# icons; the empty source widgets are GONE, the owner's law)
# =================================================================
func _build_chips() -> void:
        war_layer = CanvasLayer.new()
        war_layer.layer = 5
        add_child(war_layer)
        chips["lives"] = add_hud_chip("x%d" % int(run["lives"]),
                SRC_ART + "sprites/pup_12.png")
        chips["shields"] = add_hud_chip("x0",
                SRC_ART + "sprites/pup_02.png")
        chips["nukes"] = add_hud_chip("x%d" % int(run["nukes"]),
                SRC_ART + "sprites/pup_01.png")
        _chips_refresh()

func _chips_refresh() -> void:
        if chips.is_empty():
                return
        if is_instance_valid(chips["lives"]) and chips["lives"] is Label:
                (chips["lives"] as Label).text = "x%d" % int(run["lives"])
        if is_instance_valid(chips["shields"]) and chips["shields"] is Label:
                (chips["shields"] as Label).text = "x%d" % int(run["shields"])
        if is_instance_valid(chips["nukes"]) and chips["nukes"] is Label:
                (chips["nukes"] as Label).text = "x%d" % int(run["nukes"])

## the boss bar + THE DANGER sign (the source's own warning plate)
var boss_bar: ProgressBar = null
var boss_lbl: Label = null

func _danger_sign() -> void:
        var d := TextureRect.new()
        d.texture = _src_tex("sprites/danger.png")
        d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        d.size = Vector2(220, 181)
        d.position = Vector2(W * 0.5 - 110, H * 0.32)
        d.pivot_offset = d.size * 0.5
        d.scale = Vector2(0.2, 0.2)
        d.rotation = -0.25
        war_layer.add_child(d)
        fx.append({"n": d, "t": 0.0, "life": 1.4, "kind": "danger"})
        Jukebox.sfx("hws_alert", -4.0)

func _boss_bar_show(title: String) -> void:
        if boss_bar != null and is_instance_valid(boss_bar):
                boss_bar.queue_free()
        boss_bar = ProgressBar.new()
        boss_bar.show_percentage = false
        boss_bar.custom_minimum_size = Vector2(W * 0.5, 22)
        boss_bar.position = Vector2(W * 0.25, 100.0)
        boss_bar.max_value = 1.0
        boss_bar.value = 1.0
        boss_bar.modulate = Color("e8574a")
        war_layer.add_child(boss_bar)
        boss_lbl = Arc.label(title, 20, Arc.CARD)
        boss_lbl.position = Vector2(W * 0.25, 74.0)
        war_layer.add_child(boss_lbl)

func _boss_bar_set() -> void:
        if boss_bar == null or not is_instance_valid(boss_bar):
                return
        boss_bar.value = float(boss["hp"]) / float(boss["maxhp"])
        if boss_lbl != null:
                boss_lbl.text = "%s  x%d" % [
                        String(HWData.BOSSES[boss["id"]]["name"]),
                        1 + int(boss["cb"])]

# =================================================================
# THE THREE ZONES - true multi-touch (the kit is single-pointer)
# =================================================================
func _goga_input(event: InputEvent) -> void:
        if state == GS.INTRO:
                if (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
                                or event is InputEventMouseButton:
                        _start_place()
                return
        if state == GS.ARMORY or state == GS.OVER:
                return
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                _touch(t.index, t.position, t.pressed)
        elif event is InputEventScreenDrag:
                var d := event as InputEventScreenDrag
                if d.index == aim_ptr:
                        aim_pos = d.position
                elif d.index == steer_ptr:
                        steer_target_x = d.position.x
        elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
                var mb := event as InputEventMouseButton
                _touch(-1, mb.position, mb.pressed)

## THE THREE ZONES (the owner's final wording): bottom = STEER (the tank
## glides to the finger), center = AIM + FIRE (the finger IS the aim
## point), top = THE NUKE. A finger keeps its role until it lifts.
func _touch(idx: int, pos: Vector2, down: bool) -> void:
        if down:
                if pos.y < Z_NUKE_Y:
                        if not _nuke_debounce():
                                _nuke_ms = Time.get_ticks_msec()
                                _nuke()
                elif pos.y < Z_STEER_Y:
                        if aim_ptr == -1:
                                aim_ptr = idx
                                aim_pos = pos
                else:
                        if steer_ptr == -1:
                                steer_ptr = idx
                                steer_target_x = pos.x
        else:
                if idx == aim_ptr:
                        aim_ptr = -1
                elif idx == steer_ptr:
                        steer_ptr = -1

var _nuke_ms := 0
func _nuke_debounce() -> bool:
        return Time.get_ticks_msec() - _nuke_ms < 120

## THE PADDLE LAW (the owner: "the tank will move toward the finger,
## using similar logic of moving like ping pong game")
func _steer_glide(dt: float) -> void:
        if steer_ptr == -1 or not (state in [GS.PLACE, GS.CALM, GS.BOSS]):
                return
        var max_step: float = HWData.engine_speed(meta.level_of("speed")) * dt
        var d: float = clampf(steer_target_x - tank.position.x,
                -max_step, max_step)
        tank.position.x = clampf(tank.position.x + d, 90.0, W - 90.0)
        var body: Sprite2D = tank.get_meta("body")
        var moving := absf(steer_target_x - tank.position.x) > 4.0
        tank.set_meta("anim_t", float(tank.get_meta("anim_t", 0.0)) + dt)
        var fps := 12.0 if moving else 4.0
        if float(tank.get_meta("anim_t")) > 1.0 / fps:
                tank.set_meta("anim_t", 0.0)
                body.frame = (body.frame + 1) % 10

# =================================================================
# THE GUN - the arm tracks the finger in TRUE cells + fractional glide
# =================================================================
func _arm_pivot() -> Vector2:
        return tank.position + Vector2(0, -34.0)

## the 24 columns sweep RIGHT (col 0) -> UP (col 12) -> LEFT (col 23);
## aiming below the horizon clamps to the ends. Returns the float column.
func _turret_col_f() -> float:
        var to := aim_pos - _arm_pivot()
        if to.length() < 8.0:
                return 12.0
        var a := to.angle()                    # 0 right, -PI/2 up, PI left
        var t: float = 0.0
        if a >= 0.0:
                t = 1.0 if a <= PI * 0.5 else 0.0   # below horizon
        else:
                t = (-a) / PI * 2.0            # up = 0.5, right = 1
        if a > PI * 0.5:
                t = 0.0
        return clampf(t * 23.0, 0.0, 23.0)

## smoothness law: the integer cell carries the pose, the fraction rotates
## the sprite the remaining slice (<= 3.9 degrees) - butter, not steps
func _turret_apply() -> void:
        var turret: Sprite2D = tank.get_meta("turret")
        var col_f := _turret_col_f()
        var col := int(floor(col_f))
        var frac := col_f - float(col)
        turret.frame = col + clampi(gun_tier, 0, 4) * 24
        # the strip sweeps right->up->left = COUNTER-clockwise = negative
        # rotation in Godot; the fraction continues the sweep
        turret.rotation = -frac * (PI / 23.0)
        # the pickup blink: the arm flashes white when the tier climbs
        if gun_tier_t > 0.0:
                turret.modulate = Color(1.6, 1.6, 1.2) \
                        if fmod(gun_tier_t, 0.14) > 0.07 else Color(1, 1, 1)
        else:
                turret.modulate = Color(1, 1, 1)

func _muzzle_pos() -> Vector2:
        var col_f := _turret_col_f()
        var t := col_f / 23.0                  # 0 left .. 1 right
        var ang: float = lerpf(PI, 0.0, t)     # PI left .. 0 right
        return _arm_pivot() + Vector2(cos(ang) * 92.0,
                -sin(ang) * 92.0)

func _fire() -> void:
        if run["fire_cd"] > 0.0:
                return
        run["fire_cd"] = 0.34                  # the source's steady stream
        var muzzle := _muzzle_pos()
        var v := (aim_pos - muzzle).normalized() * 1500.0
        var n := _art_sprite("shell", Vector2(54, 27), Color("ffffff"))
        n.position = muzzle
        shot_layer.add_child(n)
        _set_shell_frame(n, v, gun_tier)
        shots.append({"n": n, "vel": v,
                "dmg": HWData.shell_dmg(gun_tier), "life": 2.2})
        # THE MUZZLE FLASH: the source's own 5-frame star
        var fl := _art_sprite("muzzle", Vector2(90, 90), Color("ffffff"))
        fl.position = muzzle + v.normalized() * 20.0
        fl.rotation = v.angle()
        shot_layer.add_child(fl)
        fx.append({"n": fl, "t": 0.0, "life": 0.1, "kind": "flash"})
        # the casing pops out under the arm
        var cs := _art_sprite("casing", Vector2(16, 16), Color("ffe08a"))
        cs.position = muzzle + Vector2(0, 10)
        shot_layer.add_child(cs)
        debris.append({"n": cs, "vel": Vector2(randf_range(-80, 160),
                randf_range(-420, -260)), "spin": randf_range(-14, 14),
                "grav": 1400.0, "t": 0.0, "life": 0.9})
        Jukebox.sfx("hws_tankfire%d" % (1 + randi() % 4), -8.0,
                randf_range(0.94, 1.06))

# =================================================================
# THE SKY DIRECTOR - THE ORIGINAL'S OWN WAVES (waves.xml verbatim):
# a wave carries its length in ORIGINAL ground px; the scroll consumes
# it; the wave's craft spawn across that walk, interleaved. When the
# level's waves are served the next level steps in (19 levels, then the
# loop continues with heavier metal).
# =================================================================
var _lvl_i := 0                 # the current waves.xml level (0-based)
var _wave_i := 0                # the current wave inside the level
var _wave_px := 0.0             # original px left in the live wave
var _wave_plan: Array = []      # [{id, at_px}] sorted by at_px
var _lap := 0                   # how many times the 19 levels looped

func _wave_hp_mul() -> float:
        return 1.0 + 0.10 * float(_lvl_i) + 0.35 * float(_lap)

func _director_tick(dt: float) -> void:
        if state != GS.PLACE:
                return
        var dx := WORLD_SPEED * dt             # ground px this frame
        var orig_dx := dx / SC                 # original px this frame
        if _wave_plan.is_empty():
                _wave_breather(dt)
                return
        _wave_px -= orig_dx
        while not _wave_plan.is_empty() \
                        and float(_wave_plan[0]["at_px"]) >= _wave_px:
                var u: Dictionary = _wave_plan.pop_front()
                _spawn_enemy(String(u["id"]))

var _breath_t := 0.0
func _wave_breather(dt: float) -> void:
        _breath_t -= dt
        if _breath_t > 0.0:
                return
        _roll_wave()

func _roll_wave() -> void:
        var lvl_waves := _level_waves()
        if _wave_i >= lvl_waves.size():
                _lvl_i += 1
                if _lvl_i >= 19:
                        _lvl_i = 10     # the loop re-enters at level 11
                        _lap += 1
                _wave_i = 0
                lvl_waves = _level_waves()
        var w: Dictionary = lvl_waves[_wave_i]
        _wave_i += 1
        _wave_px = float(w["len"])
        _wave_plan.clear()
        # each craft's qty spreads across the wave's walk, interleaved by
        # phase (the source's own spread - craft stream, not clump)
        var k := 0
        for ul in w["u"]:
                var eid: String = ul[0]
                var qty := int(ul[1])
                for i in qty:
                        var frac: float = (float(i) + 0.5) / float(qty)
                        var at: float = _wave_px * (1.0 - frac) \
                                + float(k % 3) * 6.0
                        _wave_plan.append({"id": eid, "at_px": at})
                        k += 1
        _wave_plan.sort_custom(func(a, b): return float(a["at_px"]) \
                > float(b["at_px"]))
        _breath_t = 2.4                        # the calm between waves

func _level_waves() -> Array:
        # the place's own pressure: the level rows ride the global cursor
        var start := _lvl_i * 100
        var out: Array = []
        var in_lvl := false
        for w in HWData.WAVES_XML:
                if w.has("lvl"):
                        in_lvl = int(w["lvl"]) == _lvl_i
                        continue
        # WAVES_XML is flat; slice it by the same lens the tool wrote
        return HWData.waves_for_level(_lvl_i)

# =================================================================
# THE ENEMIES - spawn + brains
# =================================================================
func _spawn_enemy(eid: String, at_x := -1.0, at_y := -1.0) -> void:
        var d: Dictionary = HWData.ENEMIES[eid]
        var sc_mul := 1.0
        if eid == "mammoth":
                sc_mul = 1.45          # the elite big copter (same pixels)
        var n := _art_sprite("enemy_" + eid,
                Vector2(d["w"], d["h"]) * sc_mul, Color("a8402e"))
        var w: float = d["w"] * sc_mul
        var h: float = d["h"] * sc_mul
        # THE ENTRY LAW (the owner: "it shows its head then its butt"):
        # spawn FULLY off the edge and let the body glide in, clipped -
        # never the whole body at once.
        var x: float = at_x if at_x >= 0.0 else W + w * 0.5 + 30.0
        var y := at_y
        if y < 0:
                match String(d["kind"]):
                        "ground":
                                y = ROAD_Y - 6.0
                        "sea":
                                y = H - 210.0
                        "ballistic":
                                y = -h * 0.5 - 40.0
                        _:
                                y = randf_range(190.0, GROUND_Y - 220.0)
        n.position = Vector2(x, y)
        ent_layer.add_child(n)
        var hp := maxi(1, int(round(float(d["hp"]) * _wave_hp_mul())))
        enemies.append({
                "id": eid, "n": n, "hp": hp, "maxhp": hp,
                "w": w, "h": h,
                "kind": String(d["kind"]), "wpn": d["weapon"],
                "spd": float(d["spd"]) * (1.0 + 0.03 * _lvl_i),
                "t": randf() * TAU, "y0": y,
                "fire_t": float(d["weapon"].get("cd",
                        d["weapon"].get("gun",
                        d["weapon"].get("missile", 2.0)))),
                "pts": int(d["pts"]),
        })

func _enemies_tick(dt: float) -> void:
        var dead: Array = []
        for e in enemies:
                var n: Node2D = e["n"]
                var sp: float = e["spd"]
                e["t"] += dt
                match String(e["kind"]):
                        "sine":
                                n.position.x -= sp * dt
                                n.position.y = float(e["y0"]) \
                                        + sin(e["t"] * 2.2) * 60.0
                        "line":
                                n.position.x -= sp * dt
                        "sea":
                                n.position.x -= sp * dt
                                n.position.y = float(e["y0"]) \
                                        + sin(e["t"] * 6.0) * 8.0
                        "ballistic":
                                n.position.y += sp * dt
                                n.position.x -= 40.0 * dt
                        "hover":
                                n.position.x -= sp * dt * 0.35
                                n.position.y = float(e["y0"]) \
                                        + sin(e["t"] * 1.6) * 50.0
                                if n.position.x < W * 0.72:
                                        n.position.x += sp * dt * 0.30
                        "swoop":
                                # dive at the tank, climb back, dive again
                                var want_y: float = TANK_Y - 90.0 \
                                        if sin(e["t"] * 0.9) > 0.0 else 260.0
                                n.position.x -= sp * dt * 0.7
                                n.position.y = move_toward(n.position.y,
                                        want_y, sp * dt * 0.9)
                        "ground", "plow":
                                n.position.x -= sp * dt
                        "guard":
                                n.position.x -= sp * dt
                                e["guard"] = fmod(e["t"], 4.0) < 2.6
                        "orbit":
                                n.position.x = W * 0.86 \
                                        + sin(e["t"] * 0.5) * 120.0
                                n.position.y = 160.0 + cos(e["t"] * 0.4) * 40.0
                _enemy_weapons(e, dt)
                if n.position.x < -320.0 or n.position.y > H + 160.0:
                        dead.append(e)
        for e in dead:
                _enemy_free(e)

func _enemy_free(e: Dictionary) -> void:
        enemies.erase(e)
        (e["n"] as Node2D).queue_free()

## THE WEAPONS - bombs fall, guns bite, missiles chase
func _enemy_weapons(e: Dictionary, dt: float) -> void:
        var wpn: Dictionary = e["wpn"]
        if wpn.is_empty():
                return
        e["fire_t"] -= dt
        if float(e["fire_t"]) > 0.0:
                return
        var n: Node2D = e["n"]
        if n.position.x > W - 60.0:
                e["fire_t"] = 0.4
                return
        if wpn.has("gun"):
                e["fire_t"] = float(wpn["gun"])
                _enemy_shot(n.position + Vector2(-e["w"] * 0.3, e["h"] * 0.2),
                        (tank.position - n.position).normalized() * 620.0,
                        "bullet")
                Jukebox.sfx("hws_enemyfire", -14.0, randf_range(0.9, 1.1))
        elif wpn.has("bomb"):
                var kind: String = wpn["bomb"]
                e["fire_t"] = float(wpn["cd"]) * randf_range(0.8, 1.2)
                _drop_bomb(n.position + Vector2(0, e["h"] * 0.4), kind)
        elif wpn.has("carpet"):
                e["fire_t"] = float(wpn["cd"])
                for i in 5:
                        _drop_bomb(n.position
                                + Vector2(20.0 * i - 40.0, e["h"] * 0.4),
                                String(wpn["carpet"]))
        elif wpn.has("missile"):
                e["fire_t"] = float(wpn["missile"])
                _enemy_shot(n.position + Vector2(-e["w"] * 0.3, 0),
                        Vector2(-420.0, 0), "hellfire")
                Jukebox.sfx("hws_missile", -12.0)
        elif wpn.has("rpg"):
                e["fire_t"] = float(wpn["rpg"])
                _enemy_shot(n.position + Vector2(-e["w"] * 0.4, -e["h"] * 0.3),
                        Vector2(-560.0, -380.0), "rpg")
                Jukebox.sfx("hws_enemyfire", -12.0, 0.8)
        elif wpn.has("laser"):
                e["fire_t"] = float(wpn["laser"])
                _orbital_laser(n.position)

func _drop_bomb(at: Vector2, kind: String) -> void:
        var size := Vector2(26, 26)
        match kind:
                "guided":
                        size = Vector2(30, 30)
                "armored":
                        size = Vector2(30, 30)
                "atom":
                        size = Vector2(60, 60)
        var n := _art_sprite("bomb_" + kind, size, Color("f2f2f2"))
        n.position = at
        shot_layer.add_child(n)
        _set_rot_frame(n, Vector2(-60.0, 300.0))
        ebombs.append({"n": n, "vel": Vector2(-60.0, 120.0), "kind": kind,
                "grav": 620.0, "hp": 2 if kind == "armored" else 1,
                "armed": false})
        if kind == "guided":
                ebombs[-1]["guided"] = true
        if kind == "frag":
                ebombs[-1]["frag"] = true
        if kind == "atom":
                ebombs[-1]["atom"] = true
        Jukebox.sfx("hws_bombfall", -14.0, randf_range(0.9, 1.1))

func _enemy_shot(at: Vector2, vel: Vector2, kind: String) -> void:
        var size := Vector2(36, 22)
        match kind:
                "hellfire":
                        size = Vector2(30, 30)
                "rpg":
                        size = Vector2(30, 30)
                "meteor":
                        size = Vector2(40, 40)
                "boulder":
                        size = Vector2(58, 58)
                "ball":
                        size = Vector2(90, 90)
        var n := _art_sprite("eshot_" + kind, size, Color("ff8a3c"))
        n.position = at
        shot_layer.add_child(n)
        _set_rot_frame(n, vel)
        var grav := 0.0
        match kind:
                "rpg":
                        grav = 500.0
                "fraglet":
                        grav = 420.0
                "meteor":
                        grav = 420.0
                "ball":
                        grav = 900.0
                "boulder":
                        grav = 460.0
                "barrel":
                        grav = 520.0
        ebombs.append({"n": n, "vel": vel, "kind": kind, "grav": grav,
                "hp": 1, "armed": true})
        if kind == "hellfire":
                ebombs[-1]["homing"] = true

func _orbital_laser(at: Vector2) -> void:
        # the satellite's sky laser: a warning line then a burn column
        var col := ColorRect.new()
        col.color = Color(1.0, 0.35, 0.2, 0.0)
        col.size = Vector2(46, tank.position.y - at.y)
        col.position = Vector2(tank.position.x - 23.0, at.y)
        fx_layer.add_child(col)
        fx.append({"n": col, "t": 0.0, "life": 0.55, "kind": "oburn",
                "hit_at": 0.28})
        Jukebox.sfx("hws_satlaser", -8.0)

# =================================================================
# THE SHELLS + THE HITS
# =================================================================
func _shots_tick(dt: float) -> void:
        var dead: Array = []
        for s in shots:
                var n: Node2D = s["n"]
                # THE HOMING LAW: the shells seek the nearest craft
                var lv := meta.level_of("homing")
                if lv > 0 and not enemies.is_empty():
                        var want := _nearest_dir(n.position)
                        if want != Vector2.ZERO:
                                var v: Vector2 = s["vel"]
                                var ang := v.normalized().slerp(
                                        want, clampf(
                                        HWData.homing_turn(lv) * dt,
                                        0.0, 1.0))
                                s["vel"] = ang.normalized() * v.length()
                                _set_shell_frame(n, s["vel"],
                                        int(s.get("tier", 0)))
                n.position += (s["vel"] as Vector2) * dt
                s["life"] = float(s["life"]) - dt
                if n.position.y < -40.0 or n.position.x < -60.0 \
                                or n.position.x > W + 60.0 \
                                or float(s["life"]) <= 0.0:
                        dead.append(s)
                        continue
                var hit: Dictionary = _shell_hit(n.position, int(s["dmg"]))
                if not hit.is_empty():
                        _flak_burst(n.position)
                        dead.append(s)
        for s in dead:
                shots.erase(s)
                (s["n"] as Node2D).queue_free()

func _nearest_dir(at: Vector2) -> Vector2:
        var best := Vector2.ZERO
        var best_d := 1e9
        for e in enemies:
                var d: float = (e["n"] as Node2D).position.distance_to(at)
                if d < best_d:
                        best_d = d
                        best = ((e["n"] as Node2D).position - at).normalized()
        return best

## THE FLAK LAW: "every shell bursts into flak" - fragments + the flash
func _flak_burst(at: Vector2) -> void:
        var lv := meta.level_of("flak")
        if lv <= 0:
                return
        var frags := HWData.flak_frags(lv)
        var flash := _art_sprite("spark", Vector2(60, 60), Color("ffd23c"))
        flash.position = at
        shot_layer.add_child(flash)
        fx.append({"n": flash, "t": 0.0, "life": 0.22, "kind": "spark"})
        for i in frags:
                var v := Vector2.from_angle(randf() * TAU) \
                        * randf_range(240.0, 420.0)
                var f := _art_sprite("shell", Vector2(30, 15),
                        Color("ffffff"))
                f.position = at
                shot_layer.add_child(f)
                _set_shell_frame(f, v, 0)
                shots.append({"n": f, "vel": v, "dmg": 1, "life": 0.5})
        Jukebox.sfx("hws_flak", -14.0, randf_range(0.9, 1.1))

## one shell vs the roster: enemies first, then boss parts
func _shell_hit(at: Vector2, dmg: int) -> Dictionary:
        for e in enemies:
                var n: Node2D = e["n"]
                if absf(n.position.x - at.x) < e["w"] * 0.5 + 6.0 \
                                and absf(n.position.y - at.y) < e["h"] * 0.5 + 6.0:
                        _spark_at(at)
                        _damage_enemy(e, dmg)
                        return e
        if boss != null and is_instance_valid(boss["n"]):
                var parts: Array = boss["parts"]
                if parts.is_empty():
                        var bn: Node2D = boss["n"]
                        if absf(bn.position.x - at.x) < 170.0 \
                                        and absf(bn.position.y - at.y) < 96.0:
                                boss["hp"] = int(boss["hp"]) - dmg
                                _spark_at(at)
                                _boss_bar_set()
                                return {"boss": true}
                        return {}
                for p in parts:
                        var pn: Node2D = p["n"]
                        if absf(pn.position.x - at.x) < p["w"] * 0.5 + 8.0 \
                                        and absf(pn.position.y - at.y) \
                                        < p["h"] * 0.5 + 8.0:
                                _spark_at(at)
                                _boss_damage_part(p, float(dmg))
                                return {"boss": true}
        return {}

## THE SPARK: the source's own impact star (10-frame fade)
func _spark_at(at: Vector2) -> void:
        var sp := _art_sprite("spark", Vector2(40, 40), Color("ffd9a0"))
        sp.position = at
        fx_layer.add_child(sp)
        fx.append({"n": sp, "t": 0.0, "life": 0.28, "kind": "spark"})

func _damage_enemy(e: Dictionary, dmg: int) -> void:
        # MIRROR law: the front shield eats everything while it is up
        if String(e["kind"]) == "guard" and bool(e["guard"]) \
                        and (e["n"] as Node2D).position.x > tank.position.x:
                _fx_ring((e["n"] as Node2D).position, Color("58a8e8"),
                        20.0, 0.2)
                Jukebox.sfx("hws_orbhit", -12.0, 1.3)
                return
        # PLOWMAN law: the plow is armor - shots from the left bounce
        if String(e["kind"]) == "plow" \
                        and (e["n"] as Node2D).position.x > tank.position.x:
                _fx_ring((e["n"] as Node2D).position
                        + Vector2(-e["w"] * 0.4, 0), Color("ffb020"),
                        18.0, 0.2)
                Jukebox.sfx("hws_deflect", -12.0, 0.9)
                return
        e["hp"] = int(e["hp"]) - dmg
        if int(e["hp"]) <= 0:
                _kill_enemy(e)

func _kill_enemy(e: Dictionary) -> void:
        var n: Node2D = e["n"]
        var big: float = clampf(float(e["w"]) / 160.0, 0.7, 2.2)
        _fx_boom(n.position, big)
        _debris_shower(n.position, 2 + int(big * 2.0))
        _pay_score(int(e["pts"]), n.position)
        run["kills"] += 1
        achievement_count("hw_kill_bank", 1)
        Jukebox.sfx("hws_smallexplode" if big < 1.4 else "hws_bigexplode",
                -6.0, randf_range(0.85, 1.15))
        _enemy_free(e)

## THE DEBRIS: tumbling chunks from the source's own 6-frame sheet
func _debris_shower(at: Vector2, count: int) -> void:
        for i in count:
                var d := _art_sprite("debris", Vector2(52, 52),
                        Color("8a8a92"))
                d.position = at
                shot_layer.add_child(d)
                debris.append({"n": d,
                        "vel": Vector2(randf_range(-320, 320),
                                randf_range(-520, -140)),
                        "spin": randf_range(-9.0, 9.0), "grav": 1200.0,
                        "t": 0.0, "life": randf_range(0.8, 1.4)})

## THE SCORE LAW: kills pay; every 1000 pays a life back (max 3)
func _pay_score(pts: int, at: Vector2) -> void:
        add_score(pts)
        achievement_max("hw_score", score)
        if run["lives"] < HWData.LIVES_MAX \
                        and score - int(run["score_life_mark"]) \
                        >= HWData.LIFE_PER_SCORE:
                run["score_life_mark"] = score
                run["lives"] += 1
                _fx_text(at, "+1 LIFE", Color("58c470"))
                _chips_refresh()

# =================================================================
# THE ENEMY FIRE vs THE TANK - with the source's own impact VFX
# =================================================================
func _ebombs_tick(dt: float) -> void:
        var dead: Array = []
        for b in ebombs:
                var n: Node2D = b["n"]
                if b.has("homing"):
                        var want := (tank.position - n.position) \
                                .normalized() * 420.0
                        b["vel"] = ((b["vel"] as Vector2).lerp(want,
                                1.4 * dt))
                        _set_rot_frame(n, b["vel"])
                if b.has("guided"):
                        (b as Dictionary)["vel"] = Vector2(
                                (b["vel"] as Vector2).x,
                                (b["vel"] as Vector2).y + 900.0 * dt)
                else:
                        (b as Dictionary)["vel"] = Vector2(
                                (b["vel"] as Vector2).x,
                                (b["vel"] as Vector2).y
                                + float(b["grav"]) * dt)
                n.position += (b["vel"] as Vector2) * dt
                # the bombs' fall pose: nose-down along the velocity
                if b.has("guided") or String(b["kind"]).begins_with("bomb") \
                                or String(b["kind"]) in ["meteor", "boulder"]:
                        var spr: Sprite2D = n.get_meta("spr", null)
                        if spr != null and int(n.get_meta("rot", 0)) > 0:
                                _set_rot_frame(n, b["vel"])
                if b.has("frag") and n.position.y > ROAD_Y - 120.0 \
                                and not bool(b["armed"]):
                        b["armed"] = true
                        for i in 3:
                                _enemy_shot(n.position,
                                        Vector2(randf_range(-260, 260),
                                        randf_range(-460, -260)), "bullet")
                        _ground_impact(n.position, 0.7)
                        dead.append(b)
                        continue
                if n.position.y > ROAD_Y or n.position.x < -60.0 \
                                or n.position.x > W + 80.0:
                        match String(b["kind"]):
                                "atom":
                                        _nuke_blast_at(n.position.x, 0.6)
                                "ball":
                                        _fx_ring(Vector2(n.position.x,
                                                ROAD_Y), Color("ffb020"),
                                                120.0, 0.45)
                                        _ground_impact(n.position, 1.6)
                                        Jukebox.sfx("hws_bigexplode", -4.0,
                                                0.85)
                                        if absf(tank.position.x
                                                - n.position.x) < 150.0:
                                                _hurt_tank(tank.position)
                                "meteor", "boulder", "barrel":
                                        _ground_impact(n.position, 0.8)
                                _:
                                        _ground_impact(n.position, 0.6)
                        dead.append(b)
                        continue
                if _hits_tank(n.position):
                        if b.has("atom"):
                                _nuke_blast_at(n.position.x, 0.6)
                        dead.append(b)
        for b in dead:
                ebombs.erase(b)
                (b["n"] as Node2D).queue_free()

## THE GROUND IMPACT LAW (the owner: "proper VFXs for the shots when they
## land on ground"): the 20-frame explosion + a crater stamped on the
## road + smoke rising + the screen shake on the big ones
var _shake := 0.0
func _ground_impact(at: Vector2, power: float) -> void:
        _fx_boom(Vector2(at.x, ROAD_Y - 10.0), power)
        _crater_stamp(Vector2(at.x, ROAD_Y + randf_range(6.0, 40.0)), power)
        var sm := _art_sprite("smoke", Vector2(56, 56) * power,
                Color("9a9a9a"))
        sm.position = Vector2(at.x, ROAD_Y - 30.0)
        fx_layer.add_child(sm)
        fx.append({"n": sm, "t": 0.0, "life": 0.8, "kind": "smoke",
                "rise": 60.0})
        if power >= 1.2:
                _shake = maxf(_shake, 0.35 * power)
        Jukebox.sfx("hws_smallexplode", -10.0, randf_range(0.95, 1.15))

func _crater_stamp(at: Vector2, power: float) -> void:
        var c := _art_sprite("crater", Vector2(90.0 * power, 45.0 * power),
                Color(0.5, 0.45, 0.4, 0.9))
        c.position = at
        c.z_index = 1
        fx_layer.add_child(c)
        decals.append({"n": c, "t": 0.0})
        while decals.size() > 12:
                var old: Dictionary = decals.pop_front()
                if is_instance_valid(old["n"]):
                        (old["n"] as Node2D).queue_free()

func _decals_tick(dt: float) -> void:
        var dead: Array = []
        for d in decals:
                d["t"] = float(d["t"]) + dt
                if float(d["t"]) > 9.0:
                        dead.append(d)
                elif is_instance_valid(d["n"]):
                        (d["n"] as Node2D).modulate.a = clampf(
                                (9.0 - float(d["t"])) / 3.0, 0.0, 1.0)
        for d in dead:
                decals.erase(d)
                if is_instance_valid(d["n"]):
                        (d["n"] as Node2D).queue_free()

func _debris_tick(dt: float) -> void:
        var dead: Array = []
        for d in debris:
                var n: Node2D = d["n"]
                d["t"] = float(d["t"]) + dt
                d["vel"] = Vector2((d["vel"] as Vector2).x,
                        (d["vel"] as Vector2).y + float(d["grav"]) * dt)
                n.position += (d["vel"] as Vector2) * dt
                n.rotation += float(d["spin"]) * dt
                var spr: Sprite2D = n.get_meta("spr", null)
                if spr != null and spr.hframes > 1:
                        spr.frame = int(float(d["t"]) * 14.0) % spr.hframes
                if float(d["t"]) >= float(d["life"]) \
                                or n.position.y > ROAD_Y + 30.0:
                        dead.append(d)
        for d in dead:
                debris.erase(d)
                (d["n"] as Node2D).queue_free()

func _hits_tank(at: Vector2) -> bool:
        if state == GS.TUNNEL:
                return false
        if absf(at.x - tank.position.x) < 52.0 \
                        and absf(at.y - TANK_Y) < 40.0:
                _hurt_tank(at)
                return true
        return false

## THE TANK LAW: the deflector spheres eat hits layer by layer, then each
## hit takes ONE life - and drops the gun power one tier (the source's
## own punishment). The iframes gate lives HERE.
func _hurt_tank(at: Vector2) -> void:
        if float(run["iframes"]) > 0.0 or state == GS.TUNNEL:
                return
        if not (run["shield_hp"] as Array).is_empty():
                var arr: Array = run["shield_hp"]
                var last: Dictionary = arr[-1]
                last["hp"] = int(last["hp"]) - 1
                if int(last["hp"]) <= 0:
                        arr.pop_back()
                        run["shields"] = arr.size()
                        Jukebox.sfx("hws_shielddown", -6.0)
                run["iframes"] = 0.7
                _zap_shield()
                Jukebox.sfx("hws_orbhit", -8.0)
                _chips_refresh()
                return
        run["lives"] = int(run["lives"]) - 1
        gun_tier = maxi(0, gun_tier - 1)
        run["iframes"] = 1.4
        _tank_hit_flash()
        _fx_text(tank.position + Vector2(0, -90), "-1 LIFE",
                Color("e8574a"))
        Jukebox.sfx("hws_bullethit", -2.0)
        Jukebox.sfx("hws_tankexplode", -4.0, randf_range(0.95, 1.1))
        _chips_refresh()
        if int(run["lives"]) <= 0:
                _run_over()

## THE TANK HIT FLASH: the source's own big white splash + a small boom
func _tank_hit_flash() -> void:
        var fl := _art_sprite("tankflash", Vector2(220, 165),
                Color("ffffff"))
        fl.position = tank.position + Vector2(0, -30)
        fx_layer.add_child(fl)
        fx.append({"n": fl, "t": 0.0, "life": 0.22, "kind": "flash"})
        _fx_boom(tank.position + Vector2(0, -10), 1.1)
        _shake = 0.5

## THE SHIELD BUBBLE: the source's own dome + the zap on the bite
var shield_bubble: Node2D = null

func _shield_bubble() -> void:
        var on: bool = not (run["shield_hp"] as Array).is_empty()
        if on and shield_bubble == null:
                shield_bubble = _art_sprite("shieldbubble",
                        Vector2(150, 132), Color("bcd8ff"))
                shield_bubble.position = tank.position + Vector2(0, -18)
                tank.add_child(shield_bubble)
        elif not on and shield_bubble != null:
                shield_bubble.queue_free()
                shield_bubble = null
        elif on:
                shield_bubble.position = Vector2(0, -18)
                var spr: Sprite2D = shield_bubble.get_meta("spr", null)
                if spr != null:
                        spr.frame = int(Time.get_ticks_msec() * 0.012) % 10

func _zap_shield() -> void:
        var z := _art_sprite("shieldzap", Vector2(180, 158),
                Color("dff0ff"))
        z.position = Vector2(0, -18)
        tank.add_child(z)
        fx.append({"n": z, "t": 0.0, "life": 0.45, "kind": "zap"})

## THE DEFLECTOR SPHERES: the orbiting balls (the source's own shield)
var spheres: Array = []

func _spheres_tick(dt: float) -> void:
        var want: int = int(run["shields"])
        while spheres.size() < want:
                var o := _art_sprite("orb", Vector2(56, 56),
                        Color("b0f0e0"))
                ent_layer.add_child(o)
                spheres.append({"n": o, "ph": spheres.size() * TAU / 3.0})
        while spheres.size() > want:
                var s: Dictionary = spheres.pop_back()
                (s["n"] as Node2D).queue_free()
        var t := Time.get_ticks_msec() * 0.001
        for s in spheres:
                var n: Node2D = s["n"]
                n.position = tank.position + Vector2(
                        cos(t * 2.6 + float(s["ph"])) * 110.0,
                        sin(t * 2.6 + float(s["ph"])) * 60.0 - 30.0)

# =================================================================
# THE NUKE - the top zone's gift
# =================================================================
func _nuke() -> void:
        if int(run["nukes"]) <= 0 or state == GS.TUNNEL:
                return
        _nuke_ms = Time.get_ticks_msec()
        run["nukes"] -= 1
        _chips_refresh()
        _nuke_blast_at(tank.position.x + 260.0, 0.5)
        Jukebox.sfx("hws_nukeblast", 0.0)

## everything inside the blast width dies (the boss body only bleeds)
func _nuke_blast_at(cx: float, width_frac: float) -> void:
        var half := W * width_frac * 0.5
        # THE WHITE-OUT + the fire column + the smoke mushroom
        var wipe := _art_sprite("nukeflash", Vector2(W, H), Color("ffffff"))
        wipe.position = Vector2(W * 0.5, H * 0.5)
        fx_layer.add_child(wipe)
        fx.append({"n": wipe, "t": 0.0, "life": 0.5, "kind": "flash"})
        var fire := _art_sprite("mushfire", Vector2(half * 1.6, half * 1.6),
                Color("fff0b0"))
        fire.position = Vector2(cx, ROAD_Y - half * 0.7)
        fx_layer.add_child(fire)
        fx.append({"n": fire, "t": 0.0, "life": 1.4, "kind": "mush"})
        var sm := _art_sprite("mushsmoke", Vector2(half * 1.4, half * 1.4),
                Color("fff0e0"))
        sm.position = Vector2(cx, ROAD_Y - half * 0.6)
        fx_layer.add_child(sm)
        fx.append({"n": sm, "t": 0.0, "life": 1.8, "kind": "mush"})
        _crater_stamp(Vector2(cx, ROAD_Y + 20.0), 2.2)
        _shake = 0.9
        var dead: Array = []
        for e in enemies:
                if absf((e["n"] as Node2D).position.x - cx) \
                                <= half + e["w"] * 0.4:
                        dead.append(e)
        for e in dead:
                _kill_enemy(e)
        var bdead: Array = []
        for b in ebombs:
                if absf((b["n"] as Node2D).position.x - cx) <= half:
                        bdead.append(b)
        for b in bdead:
                ebombs.erase(b)
                (b["n"] as Node2D).queue_free()
        if boss != null:
                _boss_damage_part({"n": boss["n"], "w": 120.0, "h": 120.0,
                        "hp": 1, "core": true}, 40)

# =================================================================
# THE FRIEND - the white helicopter's crates (the source's own law:
# "Don't shoot the white helicopters! They are your allies")
# =================================================================
func _heli_tick(dt: float) -> void:
        if heli.visible:
                var h := heli
                h.position.x -= 210.0 * dt
                h.position.y = 260.0 + sin(h.position.x * 0.01) * 26.0
                var rot: Sprite2D = h.get_meta("rotor", null)
                if rot != null:
                        rot.frame = int(Time.get_ticks_msec() * 0.05) % 7
                if h.position.x < -200.0:
                        h.visible = false
                return
        run["supply_t"] -= dt
        if float(run["supply_t"]) <= 0.0:
                run["supply_t"] = HWData.SUPPLY_PERIOD * randf_range(0.85, 1.15)
                _heli_pass("supply")

## the every-3-places coin law: the coin crate rides its own pass
func _heli_check_coin() -> void:
        if run["places_done"] >= int(run["coin_due"]):
                run["coin_due"] = int(run["coin_due"]) + 3
                _heli_pass("coin")

func _heli_pass(mode: String) -> void:
        heli.visible = true
        heli.position = Vector2(W + 160.0, 260.0)
        for c in heli.get_children():
                c.queue_free()
        var body := _art_sprite("heli", Vector2(270, 99), Color("ffffff"))
        heli.add_child(body)
        var rot := _art_sprite("helirotor", Vector2(248, 56),
                Color("d0d0d0"))
        rot.position = Vector2(0, -58)
        heli.add_child(rot)
        heli.set_meta("rotor", rot)
        heli.set_meta("mode", mode)
        # crate chain: supply = 2 crates; coin = 1 fat crate
        var crates := 2 if mode == "supply" else 1
        for i in crates:
                var kind := mode if mode == "coin" else _roll_drop()
                var rec: Dictionary = {}
                for d in HWData.DROPS:
                        if String(d["kind"]) == kind:
                                rec = d
                                break
                var crate_i: int = int(rec.get("crate", 0))
                var n := _art_sprite("crate", Vector2(72, 72),
                        Color("c8933c"))
                var spr: Sprite2D = n.get_meta("spr", null)
                if spr != null:
                        spr.frame = crate_i
                n.position = heli.position + Vector2(60.0 * (i + 1), 80.0)
                shot_layer.add_child(n)
                drops.append({"n": n, "kind": kind, "icon": String(
                        rec.get("icon", "pup_05")),
                        "phase": "fall", "vy": 60.0,
                        "life": 14.0, "t": 0.0})
        Jukebox.sfx("hws_pupcopter", -10.0)

func _roll_drop() -> String:
        var caps := {
                "shield": run["shields"] < HWData.SHIELD_MAX,
                "nuke": run["nukes"] < HWData.NUKES_MAX,
                "laser": Box.item_owned(game_id, "rig", "laser")
                        and int(run["laser_parts"]) < HWData.laser_need(),
                "life": run["lives"] < HWData.LIVES_MAX,
                "gunpower": gun_tier < HWData.GUN_TIERS - 1,
                "speedup": true,
                "coin": true,
        }
        var total := 0
        for d in HWData.DROPS:
                if bool(caps[String(d["kind"])]):
                        total += int(d["w"])
        if total == 0:
                return "coin"
        var r := randi() % total
        for d in HWData.DROPS:
                if not bool(caps[String(d["kind"])]):
                        continue
                r -= int(d["w"])
                if r < 0:
                        return String(d["kind"])
        return "coin"

## THE DROP LAW: the crate falls, lands on the road, POPS into the
## source's own powerup orb, the orb bounces along the road left until
## the tank eats it (the original's loop)
func _drops_tick(dt: float) -> void:
        var dead: Array = []
        for c in drops:
                var n: Node2D = c["n"]
                c["t"] = float(c["t"]) + dt
                match String(c["phase"]):
                        "fall":
                                c["vy"] = float(c["vy"]) + 700.0 * dt
                                n.position.y += float(c["vy"]) * dt
                                n.position.x -= 210.0 * dt * 0.4
                                if n.position.y >= ROAD_Y:
                                        n.position.y = ROAD_Y
                                        c["phase"] = "pop"
                                        c["t"] = 0.0
                        "pop":
                                if float(c["t"]) > 0.35:
                                        _orb_pop(n.position,
                                                String(c["kind"]),
                                                String(c["icon"]))
                                        dead.append(c)
                        "orb":
                                # bounce along the road, riding it left
                                c["vy"] = float(c["vy"]) + 1500.0 * dt
                                n.position.y += float(c["vy"]) * dt
                                n.position.x -= 60.0 * dt
                                if n.position.y > ROAD_Y - 10.0:
                                        n.position.y = ROAD_Y - 10.0
                                        c["vy"] = -520.0
                                c["life"] = float(c["life"]) - dt
                                if float(c["life"]) <= 0.0:
                                        dead.append(c)
                                        continue
                                if absf(n.position.x - tank.position.x) \
                                                < 80.0 and absf(
                                        n.position.y - TANK_Y) < 90.0:
                                        _collect(String(c["kind"]))
                                        dead.append(c)
        for c in dead:
                drops.erase(c)
                (c["n"] as Node2D).queue_free()

func _orb_pop(at: Vector2, kind: String, icon: String) -> void:
        var o := Sprite2D.new()
        o.texture = _src_tex("sprites/" + icon + ".png")
        o.scale = Vector2(SC, SC)
        o.position = at + Vector2(0, -20)
        shot_layer.add_child(o)
        drops.append({"n": o, "kind": kind, "phase": "orb", "vy": -520.0,
                "life": 12.0, "t": 0.0})
        Jukebox.sfx("hws_powerup", -10.0)

func _collect(kind: String) -> void:
        match kind:
                "shield":
                        if run["shields"] < HWData.SHIELD_MAX:
                                run["shields"] = int(run["shields"]) + 1
                                (run["shield_hp"] as Array).append(
                                        {"hp": HWData.armor_layer_hp(
                                        meta.level_of("shield"))})
                                _fx_text(tank.position + Vector2(0, -100),
                                        "SHIELD UP", Color("58a8e8"))
                                Jukebox.sfx("hws_shieldup", -6.0)
                "nuke":
                        if run["nukes"] < HWData.NUKES_MAX:
                                run["nukes"] = int(run["nukes"]) + 1
                                _fx_text(tank.position + Vector2(0, -100),
                                        "NUKE ACQUIRED", Color("e8574a"))
                "gunpower":
                        if gun_tier < HWData.GUN_TIERS - 1:
                                gun_tier += 1
                                gun_tier_t = 1.2
                                _fx_text(tank.position + Vector2(0, -100),
                                        "GUN POWER UP", Color("8ae85a"))
                                Jukebox.sfx("hws_gunpowerup", -6.0)
                "speedup":
                        run["iframes"] = maxf(float(run["iframes"]), 0.2)
                        _fx_text(tank.position + Vector2(0, -100),
                                "SPEED INCREASED", Color("ffffff"))
                        Jukebox.sfx("hws_speedup", -6.0)
                "laser":
                        run["laser_parts"] = int(run["laser_parts"]) + 1
                        var need: int = HWData.laser_need()
                        if int(run["laser_parts"]) >= need:
                                run["laser_parts"] = 0
                                run["laser_on"] = HWData.laser_burn(
                                        meta.level_of("laser"))
                                _fx_text(tank.position + Vector2(0, -100),
                                        "MEGALASER!", Color("40e8ff"))
                                Jukebox.sfx("hws_megalaser_start", 0.0)
                        else:
                                _fx_text(tank.position + Vector2(0, -100),
                                        "MEGALASER %d/%d" % [
                                        int(run["laser_parts"]), need],
                                        Color("40b0ff"))
                                Jukebox.sfx("hws_megaup%d" % clampi(
                                        int(run["laser_parts"]), 1, 4), -6.0)
                "life":
                        if run["lives"] < HWData.LIVES_MAX:
                                run["lives"] = int(run["lives"]) + 1
                                _fx_text(tank.position + Vector2(0, -100),
                                        "+1 LIFE", Color("58c470"))
                "coin":
                        add_run_coins(HWData.COIN_DROP)
                        _fx_text(tank.position + Vector2(0, -100),
                                "+%d COINS" % HWData.COIN_DROP, Arc.COIN)
        _chips_refresh()
        if kind != "shield" and kind != "laser":
                Jukebox.sfx("hws_powerup", -6.0, randf_range(0.95, 1.05))

## THE MEGABEAM: the source's own cyan column (lasers.png frames) with
## the beamfire bursts where it burns - a wall of light ahead of the tank
func _laser_tick(dt: float) -> void:
        if float(run["laser_on"]) <= 0.0:
                if _laser_col != null and is_instance_valid(_laser_col):
                        _laser_col.visible = false
                return
        run["laser_on"] = float(run["laser_on"]) - dt
        var beam_x := tank.position.x + 120.0
        var dead: Array = []
        for e in enemies:
                var n: Node2D = e["n"]
                if absf(n.position.x - beam_x) < 70.0:
                        e["hp"] = int(e["hp"]) - 260 * dt
                        if int(e["hp"]) <= 0:
                                dead.append(e)
        for e in dead:
                _kill_enemy(e)
        if boss != null:
                for p in boss["parts"]:
                        var pn: Node2D = p["n"]
                        if absf(pn.position.x - beam_x) < 80.0 \
                                        and bool(p.get("vuln", true)):
                                _boss_damage_part(p, 300.0 * dt)
        _laser_draw(beam_x)

var _laser_col: Node2D = null
func _laser_draw(beam_x: float) -> void:
        if _laser_col == null or not is_instance_valid(_laser_col):
                _laser_col = Node2D.new()
                # the source's beams draw HORIZONTAL (they fired sideways):
                # rotated upright they stack into the burning column
                var seg_h := 80.0 * SC * 0.62
                var segs := int(ceil(GROUND_Y / seg_h)) + 2
                for i in segs:
                        var sp := Sprite2D.new()
                        sp.texture = _src_tex("sprites/lasers.png")
                        var bm := CanvasItemMaterial.new()
                        bm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
                        sp.material = bm
                        sp.hframes = 21
                        sp.vframes = 3
                        sp.frame = i % 21          # the burn ripple rides
                        sp.rotation = -PI / 2.0    # horizontal art -> column
                        sp.scale = Vector2(SC * 1.6, SC * 1.6)
                        sp.position = Vector2(0, -i * seg_h)
                        _laser_col.add_child(sp)
                fx_layer.add_child(_laser_col)
        _laser_col.visible = true
        _laser_col.position = Vector2(beam_x, GROUND_Y)
        var k := int(Time.get_ticks_msec() * 0.02) % 21
        for i in _laser_col.get_child_count():
                var sp := _laser_col.get_child(i) as Sprite2D
                sp.frame = (k + i) % 21
        if randf() < 0.3:
                var bf := _art_sprite("beamfire", Vector2(110, 110),
                        Color("ffffff"))
                bf.position = Vector2(beam_x + randf_range(-30, 30),
                        randf_range(200.0, ROAD_Y))
                fx_layer.add_child(bf)
                fx.append({"n": bf, "t": 0.0, "life": 0.24,
                        "kind": "spark"})

# =================================================================
# THE PLACES + THE TUNNELS - shuffle law, calm zones, no spawns.
# THE PLACE CLOCK: the source's own lengths in ORIGINAL ground px,
# consumed by the world's own scroll (no more free-running timers).
# =================================================================
func _place_len_px() -> float:
        return float(place.get("len_orig", 12000.0)) * SC

var place_px_left := 0.0

func _enter_intro() -> void:
        # THE LOVE THEME (as-is): the original's own menu-and-war song
        Jukebox.music("res://assets/audio/music/hws_lovetheme.ogg")
        state = GS.INTRO
        var pi: int = place_queue_placeholder()
        _dress_place(pi)
        _chips_refresh()

## THE SHUFFLE LAW: every lap through the ten places reshuffles.
func _ensure_queue() -> void:
        if place_queue.is_empty() or run["place_i"] >= place_queue.size():
                var shuf := []
                for i in HWData.PLACES.size():
                        shuf.append(i)
                shuf.shuffle()
                place_queue = shuf
                run["place_i"] = 0

func place_queue_placeholder() -> int:
        _ensure_queue()
        return int(place_queue[0])

func _start_place() -> void:
        _ensure_queue()
        _dress_place(int(place_queue[run["place_i"] % place_queue.size()]))
        place_px_left = _place_len_px()
        _lvl_i = mini(18, run["places_done"])
        _wave_i = 0
        _lap = 0
        state = GS.PLACE
        t_state = 0.0
        _breath_t = 1.6                        # the get-ready breath
        _wave_plan.clear()
        _wave_px = 0.0
        _chips_refresh()
        Jukebox.sfx("hws_v_getready", -4.0)

func _place_tick(dt: float) -> void:
        _director_tick(dt)
        place_px_left -= WORLD_SPEED * dt
        if place_px_left <= 0.0:
                _enter_tunnel()

func _maybe_place_done() -> bool:
        if state == GS.PLACE and place_px_left <= 0.0:
                _enter_tunnel()
                return true
        return false

func _enter_tunnel() -> void:
        state = GS.TUNNEL
        t_state = 0.0
        run["places_done"] += 1
        run["place_i"] += 1
        _heli_check_coin()
        # THE CALM LAW: every hostile clears before the mouth
        for e in enemies:
                (e["n"] as Node2D).queue_free()
        enemies.clear()
        for b in ebombs:
                (b["n"] as Node2D).queue_free()
        ebombs.clear()
        for c in drops:
                (c["n"] as Node2D).queue_free()
        drops.clear()
        _wave_plan.clear()
        _wave_px = 0.0
        var tunnel := ColorRect.new()
        tunnel.color = Color(0.06, 0.05, 0.05, 0.0)
        tunnel.size = Vector2(W, H)
        fx_layer.add_child(tunnel)
        fx.append({"n": tunnel, "t": 0.0, "life": 4.6, "kind": "tunnel"})
        Jukebox.sfx("hws_swoosh", -6.0)

func _tunnel_tick(dt: float) -> void:
        t_state += dt
        tank.position.x = move_toward(tank.position.x, W * 0.5, 500.0 * dt)
        if t_state >= 4.6:
                _after_tunnel()

func _after_tunnel() -> void:
        tank.position.x = W * 0.35
        var next_i: int = int(place_queue[run["place_i"] % place_queue.size()])
        _dress_place(next_i)
        # THE BOSS CADENCE: every 5 survived places the face returns
        if run["places_done"] % HWData.BOSS_PLACES == 0:
                _enter_boss()
        else:
                state = GS.CALM
                t_state = 0.0
                run["calm_t"] = 4.0
                _chips_refresh()

func _calm_tick(dt: float) -> void:
        t_state += dt
        run["calm_t"] = float(run["calm_t"]) - dt
        if float(run["calm_t"]) <= 0.0:
                _start_place_fresh()

func _start_place_fresh() -> void:
        place_px_left = _place_len_px()
        _lvl_i = mini(18, run["places_done"])
        _wave_i = 0
        _lap = 0
        state = GS.PLACE
        t_state = 0.0
        _breath_t = 1.2
        _wave_plan.clear()
        _wave_px = 0.0
        _chips_refresh()

# =================================================================
# THE BOSS - every 5 places; THE SOURCE'S OWN FIGHT BRAINS ride the
# XML numbers (Level1 armor for the first meeting, Level2 + compounding
# for the comebacks - the source's own escalation).
# =================================================================
var boss = null                  # {n, hp, maxhp, parts: [], fire_t} or null

func _enter_boss() -> void:
        state = GS.BOSS
        t_state = 0.0
        run["bosses_met"] += 1
        var st: Dictionary = HWData.boss_stats(run["bosses_met"] - 1)
        var n := _art_sprite("boss_" + String(st["id"]), Vector2(430, 230),
                Color("702828"))
        n.position = Vector2(W + 300.0, 280.0)
        ent_layer.add_child(n)
        var parts: Array = []
        var bd: Dictionary = HWData.BOSSES[String(st["id"])]
        var fm: float = st["fire_mul"]
        var anchors := _boss_anchors(String(st["id"]))
        for pid in bd["parts"]:
                var pd: Dictionary = bd["parts"][pid]
                if pid == "params" or int(pd.get("hp", 0)) <= 0:
                        continue
                var pn := _art_sprite("boss_%s_%s" % [String(st["id"]), pid],
                        Vector2(120, 80), Color("382828"))
                pn.position = n.position + Vector2(anchors.get(pid,
                        Vector2.ZERO))
                ent_layer.add_child(pn)
                parts.append({"id": pid, "n": pn, "w": 110.0, "h": 70.0,
                        "hp": int(ceil(int(pd["hp"]) * st["hp_mul"])),
                        "fire": float(pd.get("fire", 0.0)) * fm, "fire_t": 1.0,
                        "vuln": true, "anchor": anchors.get(pid,
                        Vector2.ZERO)})
        boss = {"n": n, "id": String(st["id"]), "hp": int(st["hp"]),
                "maxhp": int(st["hp"]), "parts": parts,
                "fire_t": 1.6 * fm, "spd_mul": st["spd_mul"],
                "cb": int(st["comeback"]), "entered": false}
        _boss_bar_show(String(bd["name"]))
        _danger_sign()
        Jukebox.sfx("hws_v_danger", 0.0)
        _chips_refresh()

## the parts sit at FIXED anchors on the body (the source's own layout),
## not random scatter - the owner's "mis-coded assets" report dies here
func _boss_anchors(id: String) -> Dictionary:
        match id:
                "gunship":
                        return {"turret": Vector2(-30, 30),
                                "launcher": Vector2(70, 44)}
                "dreadnought":
                        return {"t1": Vector2(-140, 60), "t2": Vector2(-60, 74),
                                "t3": Vector2(40, 74), "t4": Vector2(120, 60),
                                "launcher": Vector2(0, 40)}
                "eyebot":
                        return {"hand": Vector2(110, 90)}
                "mechworm":
                        return {"turret": Vector2(0, 40)}
                "warbot":
                        return {"arm": Vector2(-90, 60),
                                "launcher": Vector2(80, 70)}
                _:
                        return {}

func _boss_tick(dt: float) -> void:
        if boss == null:
                return
        var n: Node2D = boss["n"]
        if not bool(boss["entered"]):
                n.position.x = move_toward(n.position.x, W * 0.72,
                        220.0 * dt)
                if n.position.x <= W * 0.72 + 1.0:
                        boss["entered"] = true
                _boss_parts_follow()
                return
        t_state += dt
        match String(boss["id"]):
                "gunship":
                        _brain_gunship(n, dt)
                "dreadnought":
                        _brain_dreadnought(n, dt)
                "skystealer":
                        _brain_skystealer(n, dt)
                "wreckball":
                        _brain_wreckball(n, dt)
                "warhead":
                        _brain_warhead(n, dt)
                "kongo":
                        _brain_kongo(n, dt)
                "eyebot":
                        _brain_eyebot(n, dt)
                "mechworm":
                        _brain_mechworm(n, dt)
                "warbot":
                        _brain_warbot(n, dt)
                "secretfist":
                        _brain_secretfist(n, dt)
        _boss_parts_follow()
        if (boss["parts"] as Array).is_empty():
                boss["vuln"] = true

func _boss_parts_follow() -> void:
        if boss == null:
                return
        var n: Node2D = boss["n"]
        for p in boss["parts"]:
                var pn: Node2D = p["n"]
                pn.position = n.position + Vector2(p["anchor"])

## parts fire their aimed missile volley on their own clocks
func _parts_fire_missiles(dt: float) -> void:
        for p in boss["parts"]:
                if float(p.get("fire", 0.0)) <= 0.0:
                        continue
                p["fire_t"] = float(p["fire_t"]) - dt
                if float(p["fire_t"]) <= 0.0:
                        p["fire_t"] = float(p["fire"])
                        _enemy_shot((p["n"] as Node2D).position,
                                (tank.position - (p["n"] as Node2D).position)
                                        .normalized() * 620.0, "hellfire")
                        Jukebox.sfx("hws_missile", -14.0)

## aimed gun burst from a world position
func _boss_burst(at: Vector2, count: int, spread := 0.22, spd := 600.0) -> void:
        for i in count:
                var a := (tank.position - at).angle() \
                        + randf_range(-spread, spread)
                _enemy_shot(at, Vector2.from_angle(a) * spd, "bullet")
        Jukebox.sfx("hws_enemyfire", -10.0)

func _brain_gunship(n: Node2D, dt: float) -> void:
        _boss_hover(n, t_state)
        _parts_fire_missiles(dt)
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 2.2 * float(boss["spd_mul"])
                _boss_burst(n.position + Vector2(0, 90), 5, 0.3)

func _brain_dreadnought(n: Node2D, dt: float) -> void:
        var dir := 1.0 if sin(t_state * 0.22) > 0.0 else -1.0
        n.position.x = clampf(n.position.x + dir * 120.0 * dt,
                W * 0.34, W - 240.0)
        n.position.y = 340.0 + sin(t_state * 0.7) * 26.0
        _parts_fire_missiles(dt)
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 2.6 * float(boss["spd_mul"])
                for p in boss["parts"]:
                        if String(p["id"]).begins_with("t"):
                                _boss_burst((p["n"] as Node2D).position, 3,
                                        0.16, 660.0)

func _brain_skystealer(n: Node2D, dt: float) -> void:
        _boss_hover(n, t_state, 0.6, 130.0)
        var cycle := fmod(t_state, 14.0)
        var dipping := cycle > 6.0 and cycle < 12.0
        n.position.y += (40.0 if dipping else -30.0) * dt
        n.position.y = clampf(n.position.y, 200.0, 420.0)
        if dipping and int(boss.get("dip_sfx", 0)) == 0:
                boss["dip_sfx"] = 1
                Jukebox.sfx("hws_tractorbeam", -6.0)
        elif not dipping:
                boss["dip_sfx"] = 0
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if dipping and float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 0.55 / float(boss["spd_mul"])
                var mx := randf_range(80.0, W - 80.0)
                _enemy_shot(Vector2(mx, n.position.y + 140.0),
                        Vector2(0, 160.0), "meteor")
                Jukebox.sfx("hws_meteor", -12.0)
        elif not dipping:
                boss["fire_t"] = minf(float(boss["fire_t"]), 0.4)

func _brain_wreckball(n: Node2D, dt: float) -> void:
        _boss_hover(n, t_state, 0.62, 240.0)
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 2.8 * float(boss["spd_mul"])
                _enemy_shot(Vector2(tank.position.x, 60.0),
                        Vector2(0, 900.0), "ball")
                Jukebox.sfx("hws_chain", -6.0)

func _brain_warhead(n: Node2D, dt: float) -> void:
        _boss_hover(n, t_state, 0.78, 90.0)
        _parts_fire_missiles(dt)
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 0.09 / float(boss["spd_mul"])
                var phase := fmod(t_state, 7.0)
                if phase > 5.2:
                        n.position.x -= 900.0 * dt
                        if randf() < 0.5:
                                _drop_bomb(Vector2(n.position.x - 60.0,
                                        n.position.y + 60.0), "dumb")
                        if n.position.x < 200.0:
                                n.position.x = W + 160.0
                else:
                        _boss_hover(n, t_state, 0.78, 90.0)

func _brain_kongo(n: Node2D, dt: float) -> void:
        var phase := fmod(t_state, 9.0)
        if phase < 6.0:
                _boss_hover(n, t_state, 0.72, 180.0)
                boss["fire_t"] = float(boss["fire_t"]) - dt
                if float(boss["fire_t"]) <= 0.0:
                        boss["fire_t"] = 1.5 / float(boss["spd_mul"])
                        _enemy_shot(n.position + Vector2(-60, 40),
                                Vector2(-520.0, -260.0), "barrel")
        else:
                var lp := (phase - 6.0) / 3.0
                var sx := n.position.x if not boss.has("leap_x") \
                        else float(boss["leap_x"])
                if lp < 0.05:
                        boss["leap_x"] = n.position.x
                        sx = n.position.x
                n.position.x = lerpf(sx, tank.position.x,
                        minf(lp * 1.6, 1.0))
                n.position.y = 500.0 - sin(lp * PI) * 380.0
                if lp >= 0.98:
                        boss.erase("leap_x")
                        _ground_impact(Vector2(n.position.x, ROAD_Y), 1.8)
                        Jukebox.sfx("hws_earthquake", -2.0, 0.8)
                        if absf(tank.position.x - n.position.x) < 200.0:
                                _hurt_tank(tank.position)

func _brain_eyebot(n: Node2D, dt: float) -> void:
        _boss_hover(n, t_state, 0.74, 150.0)
        _parts_fire_missiles(dt)
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 1.4 / float(boss["spd_mul"])
                _boss_burst(n.position + Vector2(0, 40), 4, 0.12, 700.0)

func _brain_mechworm(n: Node2D, dt: float) -> void:
        var cycle := fmod(t_state, 10.0)
        if cycle < 5.0:
                _boss_hover(n, t_state, 0.7, 220.0)
                boss["fire_t"] = float(boss["fire_t"]) - dt
                if float(boss["fire_t"]) <= 0.0:
                        boss["fire_t"] = 0.7 / float(boss["spd_mul"])
                        var bx := tank.position.x + randf_range(-160, 160)
                        _enemy_shot(Vector2(bx, 40.0), Vector2(0, 520.0),
                                "boulder")
        else:
                var lp := (cycle - 5.0) / 5.0
                n.position.x = lerpf(n.position.x, tank.position.x, 2.4 * dt)
                n.position.y = ROAD_Y + 120.0 - sin(lp * PI) * 560.0
                if lp >= 0.9 and lp < 0.95:
                        _ground_impact(Vector2(n.position.x, ROAD_Y), 1.2)

func _brain_warbot(n: Node2D, dt: float) -> void:
        _boss_hover(n, t_state, 0.66, 260.0)
        _parts_fire_missiles(dt)
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 3.2 / float(boss["spd_mul"])
                var col := ColorRect.new()
                col.color = Color(1.0, 0.3, 0.25, 0.0)
                col.size = Vector2(60, tank.position.y - n.position.y)
                col.position = Vector2(tank.position.x - 30.0, n.position.y)
                fx_layer.add_child(col)
                fx.append({"n": col, "t": 0.0, "life": 0.8, "kind": "oburn",
                        "hit_at": 0.45})
                Jukebox.sfx("hws_robotlaser", -6.0, 0.8)

func _brain_secretfist(n: Node2D, dt: float) -> void:
        _boss_hover(n, t_state, 0.5, 150.0)
        _parts_fire_missiles(dt)
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 1.9 / float(boss["spd_mul"])
                var pick := randi() % 3
                if pick == 0:
                        _drop_bomb(Vector2(tank.position.x,
                                n.position.y + 80.0), "atom")
                elif pick == 1:
                        _boss_burst(n.position + Vector2(0, 60), 6, 0.4,
                                640.0)
                else:
                        var col := ColorRect.new()
                        col.color = Color(1.0, 0.35, 0.2, 0.0)
                        col.size = Vector2(70, tank.position.y - n.position.y)
                        col.position = Vector2(tank.position.x - 35.0,
                                n.position.y)
                        fx_layer.add_child(col)
                        fx.append({"n": col, "t": 0.0, "life": 0.7,
                                "kind": "oburn", "hit_at": 0.4})

## the shared hover: a lazy figure the bodies ride
func _boss_hover(n: Node2D, t: float, cx := 0.72, amp := 200.0) -> void:
        n.position.x = W * cx + sin(t * 0.5) * amp
        n.position.y = 280.0 + sin(t * 0.8) * 70.0

func _boss_damage_part(p: Dictionary, dmg: float) -> void:
        if bool(p.get("core", false)):
                boss["hp"] = int(boss["hp"]) - int(ceil(dmg))
        else:
                p["hp"] = int(p["hp"]) - int(ceil(dmg))
                if int(p["hp"]) <= 0:
                        _fx_boom((p["n"] as Node2D).position, 1.6)
                        _debris_shower((p["n"] as Node2D).position, 3)
                        (p["n"] as Node2D).queue_free()
                        (boss["parts"] as Array).erase(p)
                        Jukebox.sfx("hws_smallexplode", -2.0, 0.8)
        _boss_bar_set()

func _boss_die() -> void:
        _pay_score(int(HWData.BOSSES[boss["id"]].get("score", 100)),
                (boss["n"] as Node2D).position)
        _fx_boom((boss["n"] as Node2D).position, 3.0)
        _debris_shower((boss["n"] as Node2D).position, 8)
        Jukebox.sfx("hws_bossblast", 2.0)
        for p in boss["parts"]:
                (p["n"] as Node2D).queue_free()
        boss["n"].queue_free()
        boss = null
        if boss_bar != null and is_instance_valid(boss_bar):
                boss_bar.queue_free()
                boss_bar = null
        if boss_lbl != null and is_instance_valid(boss_lbl):
                boss_lbl.queue_free()
                boss_lbl = null
        meta.mint_pts(1)
        achievement_max("hw_bosses_run", run["bosses_met"])
        achievement_count("hw_boss_bank", 1)
        _enter_armory()

# =================================================================
# THE ARMORY - after every boss: spend or rebalance (permanent).
# THE ORIGINAL'S SIX WEAPON SYSTEMS with their own bubble icons.
# =================================================================
func _enter_armory() -> void:
        state = GS.ARMORY
        var vb := sheet_push(0.0, "armory")
        var title := Arc.label("THE ARMORY", 40, Arc.ACCENT)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(title)
        var free_lbl := Arc.label("", 26, Arc.CARD)
        free_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(free_lbl)
        var rows := VBoxContainer.new()
        vb.add_child(rows)
        for sid in HWData.UPGRADES:
                var u: Dictionary = HWData.UPGRADES[sid]
                var row := HBoxContainer.new()
                var ico := TextureRect.new()
                ico.texture = _src_tex("sprites/%s.png" % u["icon"])
                ico.custom_minimum_size = Vector2(64, 64)
                ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                row.add_child(ico)
                var nm := Arc.label(String(u["name"]), 24, Arc.INK)
                nm.custom_minimum_size = Vector2(240, 0)
                row.add_child(nm)
                var lv_lbl := Arc.label("LV %d" % meta.level_of(sid), 24,
                        Arc.ACCENT)
                lv_lbl.custom_minimum_size = Vector2(120, 0)
                row.add_child(lv_lbl)
                var plus := Arc.button("+", Vector2(72, 56), 28, Arc.GOOD,
                        func(): _armory_change(sid, 1, free_lbl, rows))
                row.add_child(plus)
                var minus := Arc.button("-", Vector2(72, 56), 28, Arc.BAD,
                        func(): _armory_change(sid, -1, free_lbl, rows))
                row.add_child(minus)
                if not meta.stat_open(sid):
                        Arc.gray_out_button(plus)
                        Arc.gray_out_button(minus)
                        var lock := Arc.label("SHOP", 18, Arc.BAD)
                        row.add_child(lock)
                rows.add_child(row)
        _armory_free_text(free_lbl)
        vb.add_child(Arc.button("BACK TO THE WAR", Vector2(560, 84), 28,
                Arc.GOOD, func():
                        sheet_pop()
                        _armory_closed()))
        Arc.fit_sheet(vb, 1)

func _armory_free_text(free_lbl: Label) -> void:
        free_lbl.text = "FREE POINTS: %d   (banked %d)" % [meta.pts_free(),
                meta.pts_banked()]

func _armory_change(sid: String, dir: int, free_lbl: Label,
        rows: VBoxContainer) -> void:
        if dir > 0:
                meta.raise(sid)
        else:
                meta.lower(sid)
        _armory_free_text(free_lbl)
        var i := 0
        for sid2 in HWData.UPGRADES:
                var row: HBoxContainer = rows.get_child(i)
                (row.get_child(2) as Label).text = "LV %d" \
                        % meta.level_of(sid2)
                i += 1
        Jukebox.sfx("hws_buttondown", -8.0)

func _armory_closed() -> void:
        state = GS.CALM
        t_state = 0.0
        run["calm_t"] = 3.0
        _chips_refresh()

# =================================================================
# THE OVER - the run ends where the tank dies
# =================================================================
func _run_over() -> void:
        state = GS.OVER
        meta.record_run(run["places_done"], run["bosses_met"], score,
                run["kills"])
        check_achievements()
        _fx_boom(tank.position, 3.0)
        _debris_shower(tank.position, 10)
        Jukebox.sfx("hws_v_gameover", 0.0)
        await get_tree().create_timer(1.4).timeout
        finish_run(score)

# =================================================================
# THE FX - explosions, rings, texts, the tunnel veil
# =================================================================
func _fx_boom(at: Vector2, scale_f: float) -> void:
        var n := _art_sprite("boom", Vector2(200, 200) * scale_f,
                Color("ffffff"))
        n.position = at
        fx_layer.add_child(n)
        fx.append({"n": n, "t": 0.0, "life": 0.8, "kind": "boom"})

func _fx_ring(at: Vector2, tint: Color, r: float, life: float) -> void:
        var n := _art_sprite("orb", Vector2(r * 2.0, r * 2.0), tint)
        n.position = at
        fx_layer.add_child(n)
        fx.append({"n": n, "t": 0.0, "life": life, "kind": "ring"})

func _fx_text(at: Vector2, msg: String, tint: Color) -> void:
        var l := Arc.label(msg, 30, tint)
        l.position = at + Vector2(-90, -40)
        fx_layer.add_child(l)
        fx.append({"n": l, "t": 0.0, "life": 1.1, "kind": "text"})

func _fx_tick(dt: float) -> void:
        var dead: Array = []
        for f in fx:
                f["t"] = float(f["t"]) + dt
                var t: float = float(f["t"])
                var life: float = float(f["life"])
                var n: Node = f["n"]
                if not is_instance_valid(n):
                        dead.append(f)
                        continue
                match String(f["kind"]):
                        "flash":
                                (n as CanvasItem).modulate.a = 1.0 - t / life
                        "boom":
                                (n as Node2D).scale = Vector2.ONE \
                                        .lerp(Vector2(1.25, 1.25), t / life)
                                var spr: Sprite2D = (n as Node2D) \
                                        .get_meta("spr", null)
                                if spr != null:
                                        spr.frame = mini(int(t / life * 20.0),
                                                19)
                                (n as CanvasItem).modulate.a = \
                                        1.0 - pow(t / life, 2.0)
                        "ring":
                                (n as Node2D).scale = Vector2.ONE.lerp(
                                        Vector2(1.5, 1.5), t / life)
                                (n as CanvasItem).modulate.a = 1.0 - t / life
                        "spark":
                                var spr2: Sprite2D = (n as Node2D) \
                                        .get_meta("spr", null)
                                if spr2 != null and spr2.hframes > 1:
                                        spr2.frame = mini(
                                                int(t / life * 10.0), 9)
                                (n as CanvasItem).modulate.a = 1.0 - t / life
                        "smoke":
                                (n as Node2D).position.y \
                                        -= float(f.get("rise", 40.0)) * dt
                                (n as Node2D).scale = (n as Node2D).scale \
                                        .lerp(Vector2(1.6, 1.6), dt * 1.2)
                                (n as CanvasItem).modulate.a = 1.0 - t / life
                        "mush":
                                (n as Node2D).scale = Vector2(0.4, 0.4) \
                                        .lerp(Vector2.ONE, minf(t / 0.5, 1.0))
                                var spr3: Sprite2D = (n as Node2D) \
                                        .get_meta("spr", null)
                                if spr3 != null and spr3.hframes > 1:
                                        spr3.frame = mini(
                                                int(t / life * 3.0), 2)
                                (n as CanvasItem).modulate.a = clampf(
                                        1.4 - t / life, 0.0, 1.0)
                        "text":
                                (n as Node2D).position.y -= 46.0 * dt
                                (n as CanvasItem).modulate.a = 1.0 - t / life
                        "zap":
                                var spr4: Sprite2D = (n as Node2D) \
                                        .get_meta("spr", null)
                                if spr4 != null:
                                        spr4.frame = mini(
                                                int(t / life * 10.0), 9)
                                (n as CanvasItem).modulate.a = 1.0 - t / life
                        "danger":
                                var k := t / life
                                (n as Control).scale = Vector2.ONE \
                                        .lerp(Vector2(1.15, 1.15),
                                        minf(t * 6.0, 1.0))
                                (n as CanvasItem).modulate.a = \
                                        1.0 if k < 0.75 else (1.0 - k) / 0.25
                        "oburn":
                                var hit_at: float = float(f.get("hit_at", 0.0))
                                var prev := t - dt
                                (n as ColorRect).color.a = \
                                        (0.75 - t / life) if t > hit_at \
                                        else 0.25
                                if prev < hit_at and t >= hit_at:
                                        if absf((n as ColorRect).position.x
                                                + 23.0 - tank.position.x) \
                                                < 60.0:
                                                _hurt_tank(tank.position)
                        "tunnel":
                                var kk := t / life
                                (n as ColorRect).color.a = sin(kk * PI) * 0.96
                if t >= life:
                        dead.append(f)
        for f in dead:
                fx.erase(f)
                if is_instance_valid(f["n"]):
                        (f["n"] as Node).queue_free()

# =================================================================
# THE TICK
# =================================================================
func _goga_tick(dt: float) -> void:
        match state:
                GS.INTRO:
                        pass
                GS.PLACE:
                        _place_tick(dt)
                GS.CALM:
                        _calm_tick(dt)
                GS.TUNNEL:
                        _tunnel_tick(dt)
                GS.BOSS:
                        _boss_tick(dt)
                GS.ARMORY, GS.OVER:
                        pass
        _maybe_place_done()
        if state in [GS.PLACE, GS.CALM, GS.BOSS]:
                _enemies_tick(dt)
                _heli_tick(dt)
                _drops_tick(dt)
                _laser_tick(dt)
                _spheres_tick(dt)
                _shield_bubble()
        if state in [GS.PLACE, GS.CALM, GS.BOSS, GS.TUNNEL]:
                _shots_tick(dt)
                _ebombs_tick(dt)
        _decals_tick(dt)
        _debris_tick(dt)
        run["fire_cd"] = maxf(0.0, float(run["fire_cd"]) - dt)
        run["iframes"] = maxf(0.0, float(run["iframes"]) - dt)
        gun_tier_t = maxf(0.0, gun_tier_t - dt)
        if aim_ptr != -1 and float(run["fire_cd"]) <= 0.0 \
                        and state in [GS.PLACE, GS.CALM, GS.BOSS]:
                _fire()
        _steer_glide(dt)
        _turret_apply()
        # the aim reticle rides the finger, animating its 8 frames
        var aim_cur: Node2D = world.get_meta("aim_cursor")
        aim_cur.visible = aim_ptr != -1
        if aim_ptr != -1:
                aim_cur.position = aim_pos
                aim_cur.set_meta("t", float(aim_cur.get_meta("t", 0.0)) + dt)
                var fi := int(float(aim_cur.get_meta("t")) * 12.0) % 8 + 1
                var spr: Sprite2D = aim_cur.get_meta("spr")
                var tex := _src_tex("sprites/target%d.png" % fi)
                if tex != null:
                        spr.texture = tex
                spr.scale = Vector2(SC, SC)
        # the world scroll: the planes crawl at the source's own factors
        var dx := WORLD_SPEED * dt
        scroll_x += dx
        _layer_roll(world.get_meta("sky"), dx * PLANE_SKY)
        _layer_roll(world.get_meta("far"), dx * PLANE_FAR)
        _layer_roll(world.get_meta("mid"), dx * PLANE_MID)
        _layer_roll(world.get_meta("ground"), dx * PLANE_GROUND)
        _props_tick(dt, dx)
        # the tank's iframes blink
        tank.modulate.a = 0.45 if (fmod(run["iframes"], 0.16) > 0.08
                and float(run["iframes"]) > 0.0) else 1.0
        # the screen shake (the big impacts)
        if _shake > 0.0:
                _shake = maxf(0.0, _shake - dt * 1.6)
                var off := Vector2(randf_range(-1, 1), randf_range(-1, 1)) \
                        * _shake * 26.0
                world.position = off
                ent_layer.position = off
                shot_layer.position = off
                fx_layer.position = off
        else:
                world.position = Vector2.ZERO
                ent_layer.position = Vector2.ZERO
                shot_layer.position = Vector2.ZERO
                fx_layer.position = Vector2.ZERO
        _fx_tick(dt)
        if boss != null and int(boss["hp"]) <= 0:
                _boss_die()

# =================================================================
# THE SHOP - skins + the four locked systems + THE LASER. THE SHEET
# STACK LAW: the shop rides sheet_push/sheet_pop so the back button
# and the Android back both close it, the pair dies exactly.
# =================================================================
func _shop_open() -> void:
        if state in [GS.PLACE, GS.CALM, GS.BOSS, GS.TUNNEL] and not paused:
                paused = true
                get_tree().paused = true
        var vb := sheet_push(0.0, "shop")
        var t := Arc.label("HEAVY WAR SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        vb.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 300.0, 640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        box.add_child(_shop_lbl("TANK SKINS"))
        for id in HWData.SKINS:
                box.add_child(_shop_skin_row(id))
        box.add_child(_shop_lbl("WEAPON SYSTEMS"))
        for sid in HWData.UPGRADES:
                if bool(HWData.UPGRADES[sid]["open"]):
                        continue
                box.add_child(_shop_stat_row(sid))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): _shop_close()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _shop_close() -> void:
        sheet_pop()

func _shop_reopen() -> void:
        if not _sheet_stack.is_empty() \
                        and String(_sheet_stack[-1].get("id", "")) == "shop":
                sheet_pop()
                _shop_open()

func _shop_lbl(txt: String) -> Label:
        return Arc.fit_label(txt, 24, Arc.HOT, 560)

func _shop_price_btn(txt: String, price: int, cb: Callable) -> Button:
        var b := Arc.coin_button("%s  %d" % [txt, price], Vector2(560, 64),
                22, Arc.ACCENT, cb)
        if Box.coins() < price:
                b.disabled = true
        return b

func _shop_skin_row(id: String) -> Control:
        var sk: Dictionary = HWData.SKINS[id]
        var owned := Box.skin_owned(game_id, id) or int(sk["price"]) == 0
        var on := Box.skin_on(game_id) == id \
                or (int(sk["price"]) == 0 and Box.skin_on(game_id) == "")
        if on:
                var l := Arc.fit_label("%s  (ON)" % sk["name"], 22,
                        Arc.GOOD, 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button(String(sk["name"]), Vector2(560, 60), 22,
                        Arc.ACCENT, func():
                                Box.equip_skin(game_id, id)
                                Jukebox.sfx("hws_powerup", -4.0)
                                _apply_skin()
                                _shop_reopen())
        return _shop_price_btn(String(sk["name"]), int(sk["price"]), func():
                if Box.buy_skin(game_id, id, int(sk["price"])):
                        Jukebox.sfx("hws_star", -4.0)
                        _apply_skin()
                _shop_reopen())

func _shop_stat_row(sid: String) -> Control:
        var u: Dictionary = HWData.UPGRADES[sid]
        if meta.stat_open(sid):
                var l := Arc.fit_label("%s  - IN THE ARMORY" % u["name"], 22,
                        Arc.GOOD, 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        return _shop_price_btn(String(u["name"]), int(u["shop_price"]),
                func():
                        if Box.buy_item(game_id, "upg", sid,
                                int(u["shop_price"])):
                                Jukebox.sfx("hws_powerup", -4.0)
                        _shop_reopen())

## the shop's state sync through the back law (and the CLOSE button)
func _goga_sheet_popped(id: String) -> void:
        if id == "armory" and state == GS.ARMORY:
                _armory_closed()
        elif id == "shop":
                if paused:
                        paused = false
                        get_tree().paused = false
                _apply_skin()
                _chips_refresh()
                Jukebox.sfx("hws_buttondown", -6.0)
