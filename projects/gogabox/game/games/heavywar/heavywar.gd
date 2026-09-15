extends GogaGame
## HEAVY WAR (v040) - the rogue-like horizontal tank siege.
## One endless run through ALL the places, shuffled every run, joined by
## tunnels with calm zones. A friend helicopter drops shields / nukes /
## laser parts / lives / GOGACoin. A boss every 5 places pays 1 permanent
## upgrade point and opens the armory. Kills are the score. 3 lives, 3
## shields, 3 nukes. Left swipe = roll, right hold = fire, middle tap = nuke.
##
## Build passes live in docs/goga_docs/gogames_ideas/heavywar/02_PLAN.md;
## this file grows system by system, each with its qa phase.

const W := 1920.0
const H := 1080.0
const ROAD_Y := 985.0            # the road line the tank rides
const TANK_Y := 950.0
const WAR_Y := 96.0              # the war room strip (under the host top bar)

# THE THREE-ZONE TOUCH LAW (the GDD): left third = move swipe,
# right third = shoot hold, the proper dead middle = nuke tap.
const Z_MOVE := 640.0
const Z_SHOOT := 1280.0

const ART := "res://assets/games/heavywar/"
const SRC_ART := "res://assets/games/hwsrc/"

# THE PLACE -> ORIGINAL LAYERS MAP (the owner's as-is law, v040-1):
# our ten places wear the original's real sky / slab / far / ground art.
const ORIG_BG := {
        "frostkrai": "frigistan", "gulfgate": "blastnya",
        "oilreach": "petrovakia", "nukeflats": "dictastroika",
        "vinebelt": "zamblamia", "gloomkeep": "tankylvania",
        "ashfall": "vodkavania", "dunefort": "antagonistan",
        "steelcrown": "killingrad", "ironhold": "redstarhq",
}
# THE PLANE LAW (the original Anims.xml header): sky crawls slowest,
# the ground carries the war. The props ride the same factors.
const PLANE_SKY := 0.055
const PLANE_FAR := 0.28
const PLANE_BG := 0.45
const PLANE_GROUND := 1.0
const WORLD_SPEED := 300.0        # ground px per second
const GROUND_H := 180.0

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
var war_layer: CanvasLayer       # the war room widgets

# pools (dictionaries - the house way)
var enemies: Array = []          # {id, n: Node2D, hp, maxhp, kind, wpn, t, x0, y0, seed, shield_up...}
var shots: Array = []            # shells {n, vel, dmg}
var ebombs: Array = []           # enemy fire {n, vel, kind, dmg, armored}
var drops: Array = []            # crates {n, kind}
var fx: Array = []               # {n, t, life, kind}

# input (true multi-touch: the kit is single-pointer, the war is not)
# THE THREE-ZONE TOUCH LAW (the owner's v040-1 redesign): a finger takes
# its role from where it TOUCHED DOWN and keeps it until it LIFTS -
# leaving the zone never stops the role, only lifting the finger does.
# top third = THE NUKE, center = AIM + FIRE, bottom = STEER.
var steer_ptr := -1
var steer_target_x := 0.0
var aim_ptr := -1
var aim_pos := Vector2(960.0, 380.0)
var nuke_ptrs := {}              # legacy tap detector (kept for probes)

# the world scroll + the place props (the Anims law, as-is art)
var scroll_x := 0.0
var props: Array = []            # {n, frames, fps, type, mx, t, frame}
var prop_set_i := 0
var prop_gap_px := 0.0
const PROPS_GAP := 2400.0        # ground px between prop sets

# war room widget refs
var wg := {}                     # lives/shields/nukes/laser/place labels + bars

func _goga_setup() -> void:
        meta = HWMeta.load_meta()
        game_id = "heavywar"
        pause_end_run = false
        _run_reset()
        _build_world()
        _build_war_room()
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
                "shields": 0,            # layers (max 3)
                "shield_hp": [],         # per-layer hits left
                "nukes": HWData.aegis_start_nukes(meta.level_of("aegis")),
                "laser_parts": 0,        # components collected this run
                "laser_on": 0.0,         # >0 = the megabeam is burning
                "iframes": 0.0,
                "fire_cd": 0.0,
                "score_life_mark": 0,    # the last score mark that paid a life
                "supply_t": HWData.SUPPLY_PERIOD * 0.6,  # first pass sooner
                "coin_due": 3,           # the every-3-places coin law
                "kills": 0,
                "calm_t": 0.0,
        }
        run["shield_hp"] = []

# =================================================================
# THE WORLD - parallax sky/far/near/road + the tank + the friend
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

        # THE FOUR REAL PLANES (the original's own stack): sky fills the
        # screen, the haze slab sits behind the far strip, the ground band
        # carries the tank. Props ride the planes too.
        world.set_meta("sky", _mk_layer(PLANE_SKY))
        world.set_meta("slab", _mk_layer(PLANE_BG))
        world.set_meta("far", _mk_layer(PLANE_FAR))
        world.set_meta("ground", _mk_layer(PLANE_GROUND))
        var props_l := Node2D.new()
        world.add_child(props_l)
        world.set_meta("props", props_l)
        _dress_place(0)

        tank = Node2D.new()
        tank.position = Vector2(W * 0.35, TANK_Y)
        add_child(tank)
        var skin := _skin_node()
        tank.add_child(skin)
        # the body + the arm live where the tick and the skin swap read them
        tank.set_meta("body", skin.get_meta("body"))
        tank.set_meta("turret", skin.get_meta("turret"))
        tank.set_meta("skin", "olive")

        heli = Node2D.new()
        heli.visible = false
        add_child(heli)

        var aim_cur := Sprite2D.new()
        aim_cur.texture = _src_tex("sprites/cursor_pointer.png")
        aim_cur.scale = Vector2(1.7, 1.7)
        aim_cur.visible = false
        aim_cur.z_index = 90
        add_child(aim_cur)
        world.set_meta("aim_cursor", aim_cur)

## a leaf pair that leapfrogs by the texture's own period; the region
## repeat makes ONE sprite tile the whole visible band
func _mk_layer(scroll: float) -> Dictionary:
        var holder := Node2D.new()
        world.add_child(holder)
        return {"node": holder, "a": null, "b": null, "scroll": scroll,
                "off": 0.0, "period": W + 4.0, "h": 0.0}

func _src_tex(rel: String) -> Texture2D:
        var p := SRC_ART + rel
        if ResourceLoader.exists(p):
                return load(p)
        return null

## fill a layer with a tiling texture: band_h is the visible height,
## anchored to the band's bottom; scale x = tile_w / tex width; the
## vertical scale keeps the texture's own aspect (the sky stretches,
## see _dress_place).
func _layer_fill(l: Dictionary, tex: Texture2D, tile_w: float,
        band_h: float, y: float, stretch := false) -> void:
        var holder: Node2D = l["node"]
        for c in holder.get_children():
                c.queue_free()
        l["a"] = null
        l["b"] = null
        l["leaves"] = []
        l["h"] = band_h
        holder.position.y = y
        if tex == null:
                var r := ColorRect.new()
                r.color = Color(0.08, 0.08, 0.08)
                r.size = Vector2(W + 4.0, band_h)
                holder.add_child(r)
                l["leaves"].append(r)
                l["period"] = W + 4.0
                return
        var ts: Vector2 = tex.get_size()
        var sc: float = tile_w / ts.x
        var draw_h: float = ts.y * sc
        if stretch:
                draw_h = band_h
        l["period"] = tile_w
        for k in 2:
                var sp := Sprite2D.new()
                sp.texture = tex
                sp.centered = false
                sp.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
                sp.region_enabled = true
                sp.region_rect = Rect2(0, 0, ts.x, minf(band_h / sc, ts.y))
                if stretch:
                        sp.region_rect = Rect2(0, 0, ts.x, ts.y)
                sp.scale = Vector2(sc, band_h / (sp.region_rect.size.y * sc) \
                        if stretch else sc)
                sp.position = Vector2(float(k) * tile_w,
                        band_h - sp.region_rect.size.y * sp.scale.y)
                holder.add_child(sp)
                l["leaves"].append(sp)

func _layer_roll(l: Dictionary, _speed: float, dx: float) -> void:
        var period: float = float(l.get("period", W + 4.0))
        l["off"] = fmod(float(l["off"]) + dx * float(l["scroll"]), period)
        var x: float = -float(l["off"])
        var leaves: Array = l.get("leaves", [])
        for k in leaves.size():
                var leaf: CanvasItem = leaves[k]
                if is_instance_valid(leaf):
                        leaf.position.x = x if k == 0 else x + period

## THE PLACE DRESSING - the original's real layers, as-is
func _dress_place(pi: int) -> void:
        place = HWData.PLACES[pi if pi < HWData.PLACES.size() else 0]
        var oid := String(ORIG_BG.get(String(place["id"]), "frigistan"))
        var dir := "backgrounds/"
        # SKY: full screen, the whole 640x480 sky stretched once
        var sky: Dictionary = world.get_meta("sky")
        _layer_fill(sky, _src_tex(dir + oid + "_sky.jpg"), W, H, 0.0, true)
        # SLAB: the haze wall the far strip sits on
        var slab: Dictionary = world.get_meta("slab")
        var slab_tex: Texture2D = _src_tex(dir + oid + "_bg2.png")
        if slab_tex == null:
                slab_tex = _src_tex(dir + oid + "_bg2_.png")
        _layer_fill(slab, slab_tex, W, 560.0, H - GROUND_H - 560.0)
        # FAR: the painted strip (mountains / towers / walls) - the
        # COMPOSED plain names first (real color + real alpha), the
        # masks never (the _.png twins are white silhouettes)
        var far: Dictionary = world.get_meta("far")
        var far_tex: Texture2D = _src_tex(dir + oid + "_bg.png")
        if far_tex == null:
                far_tex = _src_tex(dir + oid + "_bg.jpg")
        if far_tex == null:
                far_tex = _src_tex(dir + oid + "_bg_.png")
        _layer_fill(far, far_tex, W, 640.0, H - GROUND_H - 640.0)
        # GROUND: the speckled band the tank rides
        var gnd: Dictionary = world.get_meta("ground")
        var g_tex: Texture2D = _src_tex(dir + oid + "_ground.png")
        if g_tex == null:
                g_tex = _src_tex(dir + oid + "_ground.jpg")
        if g_tex == null:
                g_tex = _src_tex(dir + oid + "_ground_.png")
        _layer_fill(gnd, g_tex, W, GROUND_H, H - GROUND_H)
        _props_reset()

# ------------------------------------------------------------- THE PROPS
func _props_reset() -> void:
        var pl: Node2D = world.get_meta("props")
        for c in pl.get_children():
                c.queue_free()
        props.clear()
        prop_set_i = 0
        prop_gap_px = 600.0            # the first set arrives soon

## one set = every non-rare prop of the place, at the original's scaled
## offsets; rare props join every third set (the Anims rare law)
func _props_spawn_set() -> void:
        var pl: Node2D = world.get_meta("props")
        prop_set_i += 1
        var y_sc := H / 480.0
        for r in HWProps.PROPS:
                if String(r["p"]) != String(place["id"]):
                        continue
                if bool(r["rare"]) and prop_set_i % 3 != 1:
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
                        n.region_enabled = false
                        ts.x = ts.x / float(frames)
                n.scale = Vector2(2.4, 2.4)
                var px: float = W + 200.0 \
                        + float(r["offset"]) * (W / 640.0) * 0.55
                var py: float = float(r["y"]) * y_sc
                n.position = Vector2(px, py)
                var plane := int(r["plane"])
                n.z_index = {4: -6, 3: -5, 2: -4, 1: 2}.get(plane, 0)
                pl.add_child(n)
                props.append({"n": n, "frames": frames,
                        "fps": float(r["speed"]) * 100.0,
                        "type": String(r["type"]),
                        "mx": float(r["mx"]) * 100.0,
                        "plane": float(r["plane"]) / 4.0 * 0.8 + 0.2,
                        "t": 0.0, "frame": 0})

func _props_tick(dt: float, ground_dx: float) -> void:
        # the gap counts GROUND pixels; when it empties a set spawns
        prop_gap_px -= absf(ground_dx)
        if prop_gap_px <= 0.0:
                prop_gap_px = PROPS_GAP
                _props_spawn_set()
        var dead: Array = []
        for p in props:
                var n: Sprite2D = p["n"]
                n.position.x -= (WORLD_SPEED * float(p["plane"])
                        + float(p["mx"])) * dt
                if int(p["frames"]) > 1 and float(p["fps"]) > 0.0:
                        p["t"] = float(p["t"]) + dt
                        var adv := int(p["t"] * float(p["fps"]))
                        p["t"] = float(p["t"]) - float(adv) / float(p["fps"])
                        var f := int(p["frame"]) + adv
                        var fr := int(p["frames"])
                        if String(p["type"]) == "pingpong":
                                var cyc := f % (fr * 2 - 2)
                                p["frame"] = cyc if cyc < fr else (fr * 2 - 2 - cyc)
                        else:
                                p["frame"] = f % fr
                        n.frame = int(p["frame"])
                if n.position.x < -500.0:
                        dead.append(p)
        for p in dead:
                props.erase(p)
                (p["n"] as Sprite2D).queue_free()

## THE SKIN SLOT: olive is the base sprite; the shop's skins are the
## recolored tanks the art tool painted. One rebuild point, live-swappable.
func _skin_id() -> String:
        var s := Box.skin_on(game_id)
        return "olive" if s.is_empty() else s

func _skin_node() -> Node2D:
        # THE REAL ATOMIC TANK (as-is): the 10-frame strip + the 24x5
        # turret arm. Shop skins = modulate tints (reversible, the art
        # stays the original's pixels).
        var root := Node2D.new()
        var body := Sprite2D.new()
        body.texture = _src_tex("sprites/tank.png")
        body.hframes = 10
        body.frame = 0
        body.scale = Vector2(2.3, 2.3)
        body.position = Vector2(0, 14)
        root.add_child(body)
        root.set_meta("body", body)
        var turret := Sprite2D.new()
        turret.texture = _src_tex("sprites/gun.png")
        turret.hframes = 24
        turret.vframes = 5
        turret.frame = 12
        turret.scale = Vector2(2.3, 2.3)
        turret.position = Vector2(0, -6)
        root.add_child(turret)
        root.set_meta("turret", turret)
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

## THE ART INDIRECTION: real texture when the art pass has painted it,
## an honest colored slab when it has not. One point of swap, forever.
## THE AS-IS SPRITE MAP (the owner's v040-1 law): our art ids point at
## the ORIGINAL textures - strips carry their real frame counts, the
## odd ones wear a region. The fallback below stays honest for anything
## unmapped.
const SRC_SPRITES := {
        "enemy_scout": {"p": "sprites/propfighter.png", "hf": 4},
        "enemy_dart": {"p": "sprites/smalljet.png"},
        "enemy_raider": {"p": "sprites/bomber.png"},
        "enemy_lynx": {"p": "sprites/jetfighter.png"},
        "enemy_komet": {"p": "sprites/bigmissile.png",
                "region": [0, 0, 88, 200]},
        "enemy_skimmer": {"p": "sprites/cruise.png", "hf": 8},
        "enemy_fang": {"p": "sprites/deltajet.png"},
        "enemy_talon": {"p": "sprites/deltabomber.png"},
        "enemy_wasp": {"p": "sprites/smallcopter.png", "hf": 5},
        "enemy_hornet": {"p": "sprites/medcopter.png", "hf": 7},
        "enemy_mirror": {"p": "sprites/deflector.png"},
        "enemy_technical": {"p": "sprites/truck.png", "hf": 10},
        "enemy_carpet": {"p": "sprites/bigbomber.png"},
        "enemy_viper": {"p": "sprites/bigcopter.png", "hf": 9},
        "enemy_mammoth": {"p": "sprites/hugecopter.png"},
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
        "boss_dreadnought_t2": {"p": "bosses/battleship/gun.png"},
        "boss_dreadnought_t3": {"p": "bosses/battleship/gun.png"},
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
        "shell": {"p": "sprites/bullets.png", "region": [434, 40, 60, 40]},
        "eshot_bullet": {"p": "sprites/bullets.png", "region": [434, 0, 60, 40]},
        "eshot_missile": {"p": "sprites/missile.png", "hf": 10},
        "eshot_rpg": {"p": "sprites/rocket.png", "hf": 21},
        "eshot_fraglet": {"p": "sprites/fragbomb.png",
                "region": [0, 0, 30, 30]},
        "eshot_meteor": {"p": "sprites/rock.png"},
        "eshot_boulder": {"p": "sprites/rock.png"},
        "eshot_barrel": {"p": "sprites/crates.png", "region": [72, 0, 36, 36]},
        "eshot_ball": {"p": "bosses/wrecker/ball.png"},
        "bomb_dumb": {"p": "sprites/dumbbomb.png", "hf": 10},
        "bomb_guided": {"p": "sprites/lgb.png", "hf": 21},
        "bomb_armored": {"p": "sprites/ironbomb.png", "hf": 10},
        "bomb_frag": {"p": "sprites/fragbomb.png", "hf": 10},
        "bomb_atom": {"p": "sprites/fatboy.png", "hf": 10},
        "boom": {"p": "sprites/explosion_.png", "hf": 20},
        "mush": {"p": "sprites/mushsmoke.png", "hf": 3},
        "crate": {"p": "sprites/crates.png", "region": [0, 0, 36, 36]},
        "heli": {"p": "sprites/pupcopter.png"},
        "nukeflash": {"p": "sprites/nukebg.jpg"},
}

func _art_sprite(art_id: String, size: Vector2, tint: Color) -> Node2D:
        var holder := Node2D.new()
        var m: Dictionary = SRC_SPRITES.get(art_id, {})
        var tex: Texture2D = null
        if not m.is_empty():
                tex = _src_tex(String(m["p"]))
        if tex != null:
                if m.has("region"):
                        var r: Array = m["region"]
                        var sp := Sprite2D.new()
                        sp.texture = tex
                        sp.region_enabled = true
                        sp.region_rect = Rect2(r[0], r[1], r[2], r[3])
                        sp.scale = size / Vector2(r[2], r[3])
                        holder.add_child(sp)
                        return holder
                var hf: int = int(m.get("hf", 1))
                var cell: Vector2 = tex.get_size()
                if hf > 1:
                        cell.x = cell.x / float(hf)
                var sp2 := Sprite2D.new()
                sp2.texture = tex
                sp2.hframes = hf
                sp2.frame = 0
                sp2.scale = size / cell
                holder.add_child(sp2)
                holder.set_meta("spr", sp2)
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

# =================================================================
# THE WAR ROOM - the accurate widget strip (the GDD's design law)
# =================================================================
func _build_war_room() -> void:
        war_layer = CanvasLayer.new()
        war_layer.layer = 5
        add_child(war_layer)
        # THE ORIGINAL'S STATUS BAR (as-is): the metal strip under the
        # host top bar - the widgets read out of its recessed slots
        var sb := TextureRect.new()
        sb.texture = _src_tex("sprites/statusbar.png")
        sb.stretch_mode = TextureRect.STRETCH_SCALE
        sb.size = Vector2(W, 84.0)
        sb.position = Vector2(0, WAR_Y - 84.0)
        war_layer.add_child(sb)
        var bar := PanelContainer.new()
        var st := StyleBoxFlat.new()
        st.bg_color = Color(0.08, 0.06, 0.04, 0.72)
        st.set_corner_radius_all(14)
        bar.add_theme_stylebox_override("panel", st)
        bar.position = Vector2(14, 86)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 14)
        bar.add_child(row)
        war_layer.add_child(bar)

        wg["lives"] = _war_pips(row, HWData.LIVES_MAX, Color("58c470"))
        wg["shields"] = _war_pips(row, HWData.SHIELD_MAX, Color("58a8e8"))
        wg["nukes"] = _war_pips(row, HWData.NUKES_MAX, Color("e8574a"))
        var laser_box := VBoxContainer.new()
        var laser_lbl := Arc.label("LASER", 15, Arc.CARD)
        var laser_bar := ProgressBar.new()
        laser_bar.custom_minimum_size = Vector2(110, 14)
        laser_bar.show_percentage = false
        laser_bar.max_value = 1.0
        laser_bar.value = 0.0
        laser_bar.modulate = Color("ffb020")
        laser_box.add_child(laser_lbl)
        laser_box.add_child(laser_bar)
        row.add_child(laser_box)
        wg["laser"] = laser_bar
        var place_lbl := Arc.label("", 22, Arc.CARD)
        row.add_child(place_lbl)
        wg["place"] = place_lbl
        _war_refresh()

func _war_pips(row: HBoxContainer, n: int, tint: Color) -> Dictionary:
        var box := VBoxContainer.new()
        var lbl := Arc.label("", 15, Arc.CARD)
        var pips := HBoxContainer.new()
        pips.add_theme_constant_override("separation", 4)
        box.add_child(lbl)
        box.add_child(pips)
        row.add_child(box)
        var arr := []
        for i in n:
                var pip := ColorRect.new()
                pip.custom_minimum_size = Vector2(26, 16)
                pip.color = Color(tint, 0.18)
                pips.add_child(pip)
                arr.append(pip)
        return {"label": lbl, "pips": arr, "tint": tint}

func _war_refresh() -> void:
        _pips_set(wg["lives"], run["lives"], "LIVES")
        _pips_set(wg["shields"], run["shields"], "SHIELD")
        _pips_set(wg["nukes"], run["nukes"], "NUKES")
        var need: int = HWData.aegis_laser_need(meta.level_of("aegis"))
        var owned: bool = Box.item_owned(game_id, "rig", "laser")
        (wg["laser"] as ProgressBar).value = \
                (float(run["laser_parts"]) / float(need)) if owned else 0.0
        var ptag := "PLACE %d" % (run["places_done"] + 1)
        if state == GS.BOSS:
                ptag = "BOSS"
        elif state == GS.TUNNEL:
                ptag = "TUNNEL"
        (wg["place"] as Label).text = "%s  -  %s" % [ptag,
                String(place.get("name", ""))]

func _pips_set(w: Dictionary, v: int, title: String) -> void:
        (w["label"] as Label).text = title
        var pips: Array = w["pips"]
        for i in pips.size():
                var pip: ColorRect = pips[i]
                pip.color = (w["tint"] as Color) if i < v \
                        else Color(w["tint"], 0.18)

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

## THE THREE ZONES (the owner's v040-1 law, final wording):
## "steering is the bottom... the aim part will be for the center, and
## also leaving center will not stop shooting or aiming, only removing
## finger, the top area be for the nuclear weapon".
func _touch(idx: int, pos: Vector2, down: bool) -> void:
        if down:
                if pos.y < H / 3.0:
                        # THE NUKE - on press, debounced (the mouse twin guard)
                        if not _nuke_debounce():
                                _nuke_ms = Time.get_ticks_msec()
                                _nuke()
                elif pos.y < H * 2.0 / 3.0:
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
## true when a nuke already fired within 120ms (the emulation twin)
func _nuke_debounce() -> bool:
        var now := Time.get_ticks_msec()
        if now - _nuke_ms < 120:
                return true
        return false

## THE PADDLE LAW (the owner: "the tank will move toward the finger,
## using similar logic of moving like ping pong game"): the tank glides
## toward the steering finger, distance-proportional, never a teleport.
func _steer_glide(dt: float) -> void:
        if steer_ptr == -1 or not (state in [GS.PLACE, GS.CALM, GS.BOSS]):
                return
        var max_step: float = HWData.engine_speed(meta.level_of("engine")) * dt
        var d: float = clampf(steer_target_x - tank.position.x,
                -max_step, max_step)
        tank.position.x = clampf(tank.position.x + d, 70.0, W - 70.0)
        # the drive anim rolls while the tank actually moves
        var body: Sprite2D = tank.get_meta("body")
        var moving := absf(steer_target_x - tank.position.x) > 4.0
        tank.set_meta("anim_t", float(tank.get_meta("anim_t", 0.0)) + dt)
        var fps := 9.0 if moving else 3.0
        if float(tank.get_meta("anim_t")) > 1.0 / fps:
                tank.set_meta("anim_t", 0.0)
                body.frame = (body.frame + 1) % 10

# =================================================================
# THE GUN - streams fan with CANNONS; damage = SHELLS; cd = RELOAD
# =================================================================
## the aim point rules the gun: the turret arm tracks the finger and the
## shells fly straight THROUGH it (the owner: "it aims where the shots
## will exactly go")
func _muzzle_pos() -> Vector2:
        var turret: Sprite2D = tank.get_meta("turret")
        var ang := _turret_angle()
        return tank.position + Vector2(0, -6) \
                + Vector2.from_angle(ang) * 66.0

## the 24-frame arm strip sweeps LEFT -> UP -> RIGHT (cols 0..23);
## aiming below the horizon clamps to the ends
func _turret_angle() -> float:
        var to := aim_pos - (tank.position + Vector2(0, -6))
        var a := to.angle()
        # Godot: right = 0, up = -PI/2, left = PI. The strip covers
        # PI (left) .. -PI/2 (up) .. 0 (right) = the upper half circle.
        if a > 0.0:
                # below the horizon: clamp to the nearer end
                return PI if a < PI * 0.5 else 0.0
        return a

func _turret_frame() -> int:
        var a := _turret_angle()
        # sweep PI -> 2PI mapped onto cols 0..23 (left .. up .. right)
        var t: float = (a - PI) / PI
        if t < 0.0:
                t += 2.0
        return clampi(int(round(t * 23.0)), 0, 23)

func _fire() -> void:
        if run["fire_cd"] > 0.0:
                return
        run["fire_cd"] = HWData.reload_cd(meta.level_of("reload"))
        var streams := HWData.cannon_streams(meta.level_of("cannons"))
        var dmg := HWData.shell_dmg(meta.level_of("shells"))
        var muzzle := _muzzle_pos()
        var base_ang := (aim_pos - muzzle).angle()
        for i in streams:
                var spread: float = (float(i) - float(streams - 1) * 0.5) * 0.055
                var v := Vector2.from_angle(base_ang + spread) * 1500.0
                var n := _art_sprite("shell", Vector2(12, 28), Color("ffe08a"))
                n.position = muzzle
                n.rotation = v.angle()
                shot_layer.add_child(n)
                shots.append({"n": n, "vel": v, "dmg": dmg})
        # the muzzle flash: the original's own flash frame
        var fl := Sprite2D.new()
        fl.texture = _src_tex("sprites/tankflash.png")
        fl.position = muzzle
        fl.rotation = base_ang + PI * 0.5
        fl.scale = Vector2(0.8, 0.8)
        shot_layer.add_child(fl)
        fx.append({"n": fl, "t": 0.0, "life": 0.09, "kind": "flash"})
        Jukebox.sfx("hws_tankfire%d" % (1 + randi() % 4), -8.0,
                randf_range(0.94, 1.06))

# =================================================================
# THE SKY - the spawn director (waves per tier, place exclusives)
# =================================================================
func _tier() -> int:
        return clampi(1 + run["places_done"] / 2, 1, 5)

var _wave_units: Array = []      # queued spawns [{id, at}]
var _wave_t := 0.0

func _director_tick(dt: float) -> void:
        # THE CALM LAW, structural: the director only breathes in a PLACE
        if state != GS.PLACE:
                return
        _wave_t += dt
        if _wave_units.is_empty():
                _roll_wave()
                # breathing room between waves
                _wave_t = -2.2
                return
        while not _wave_units.is_empty() and _wave_t >= float(_wave_units[0]["at"]):
                var u: Dictionary = _wave_units.pop_front()
                _spawn_enemy(String(u["id"]))
        # the clock moves only while the screen serves the wave
        _wave_t += 0.0

func _roll_wave() -> void:
        var tier := _tier()
        var pool: Array = HWData.WAVES[tier]
        var rec: Dictionary = pool[randi() % pool.size()]
        _wave_units.clear()
        _wave_t = 0.0
        # exclusives ride in: the place's own specials join the pressure
        var unit_lists: Array = rec["u"].duplicate()
        if randf() < 0.30:
                var ex: Array = place["exclusive"]
                var pick: String = ex[randi() % ex.size()]
                var qty := 1 + (randi() % 2)
                unit_lists.append([pick, qty, 4.0])
        for ul in unit_lists:
                var eid: String = ul[0]
                var count: int = int(ul[1])
                var gap: float = float(ul[2])
                for i in count:
                        _wave_units.append({"id": eid, "at": _wave_t})
                        _wave_t += gap * randf_range(0.8, 1.2)
        _wave_units.sort_custom(func(a, b): return float(a["at"]) < float(b["at"]))

# =================================================================
# THE ENEMIES - spawn + brains
# =================================================================
func _spawn_enemy(eid: String, at_x := -1.0, at_y := -1.0) -> void:
        var d: Dictionary = HWData.ENEMIES[eid]
        var n := _art_sprite("enemy_" + eid, Vector2(d["w"], d["h"]), Color("a8402e"))
        var x: float = at_x if at_x >= 0.0 else W + float(d["w"])
        var y := at_y
        if y < 0:
                match String(d["kind"]):
                        "ground":
                                y = ROAD_Y + 8.0
                        "sea":
                                y = H - 210.0
                        "ballistic":
                                y = -60.0
                        _:
                                y = randf_range(180.0, H - 330.0)
        n.position = Vector2(x, y)
        ent_layer.add_child(n)
        var hp := _scale_hp(int(d["hp"]))
        enemies.append({
                "id": eid, "n": n, "hp": hp, "maxhp": hp,
                "kind": String(d["kind"]), "wpn": d["weapon"],
                "spd": float(d["spd"]) * _spd_mul(), "t": randf() * TAU,
                "w": float(d["w"]), "h": float(d["h"]),
                "x0": x, "y0": y, "fire_t": float(d["weapon"].get("cd", d["weapon"].get("gun", 2.0))),
                "guard": false, "pts": int(d["pts"]),
        })

func _scale_hp(base: int) -> int:
        # the run escalates: later places field tougher metal (study law)
        var k: float = 1.0 + 0.18 * float(run["places_done"])
        return maxi(1, int(round(base * k)))

func _spd_mul() -> float:
        return 1.0 + 0.03 * run["places_done"]

func _enemies_tick(dt: float) -> void:
        var dead: Array = []
        for e in enemies:
                var n: Node2D = e["n"]
                var sp: float = e["spd"]
                e["t"] += dt
                match String(e["kind"]):
                        "sine":
                                n.position.x -= sp * dt
                                n.position.y = float(e["y0"]) + sin(e["t"] * 2.2) * 60.0
                        "line":
                                n.position.x -= sp * dt
                        "sea":
                                n.position.x -= sp * dt
                                n.position.y = float(e["y0"]) + sin(e["t"] * 6.0) * 8.0
                        "ballistic":
                                n.position.y += sp * dt
                                n.position.x -= 40.0 * dt
                        "hover":
                                n.position.x -= sp * dt * 0.35
                                n.position.y = float(e["y0"]) + sin(e["t"] * 1.6) * 50.0
                                if n.position.x < W * 0.72:
                                        n.position.x += sp * dt * 0.30
                        "swoop":
                                # dive at the tank, climb back, dive again
                                var want_y: float = TANK_Y - 90.0 \
                                        if sin(e["t"] * 0.9) > 0.0 else 260.0
                                n.position.x -= sp * dt * 0.7
                                n.position.y = move_toward(n.position.y, want_y, sp * dt * 0.9)
                        "ground", "plow":
                                n.position.x -= sp * dt
                        "guard":
                                n.position.x -= sp * dt
                                e["guard"] = fmod(e["t"], 4.0) < 2.6
                        "orbit":
                                n.position.x = W * 0.86 + sin(e["t"] * 0.5) * 120.0
                                n.position.y = 150.0 + cos(e["t"] * 0.4) * 40.0
                _enemy_weapons(e, dt)
                # the honest gates: gone left or gone down = gone
                if n.position.x < -260.0 or n.position.y > H + 140.0:
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
        if n.position.x > W - 40.0:
                e["fire_t"] = 0.4
                return
        if wpn.has("gun"):
                e["fire_t"] = float(wpn["gun"])
                _enemy_shot(n.position + Vector2(-e["w"] * 0.3, e["h"] * 0.2),
                        (tank.position - n.position).normalized() * 620.0, "bullet")
        elif wpn.has("bomb"):
                var kind: String = wpn["bomb"]
                e["fire_t"] = float(wpn["cd"]) * randf_range(0.8, 1.2)
                _drop_bomb(n.position + Vector2(0, e["h"] * 0.4), kind)
        elif wpn.has("carpet"):
                e["fire_t"] = float(wpn["cd"])
                for i in 5:
                        _drop_bomb(n.position + Vector2(20.0 * i - 40.0, e["h"] * 0.4),
                                String(wpn["carpet"]))
        elif wpn.has("missile"):
                e["fire_t"] = float(wpn["missile"])
                _enemy_shot(n.position + Vector2(-e["w"] * 0.3, 0),
                        Vector2(-320.0, 0), "missile")
        elif wpn.has("rpg"):
                e["fire_t"] = float(wpn["rpg"])
                var v := Vector2(-560.0, -380.0)
                _enemy_shot(n.position + Vector2(-e["w"] * 0.4, -e["h"] * 0.3), v, "rpg")
        elif wpn.has("laser"):
                e["fire_t"] = float(wpn["laser"])
                _orbital_laser(n.position)

func _drop_bomb(at: Vector2, kind: String) -> void:
        var size := Vector2(14, 22)
        var tint := Color("f2f2f2")
        match kind:
                "guided":
                        tint = Color("e8574a")
                "armored":
                        tint = Color("6a6a72")
                        size = Vector2(18, 26)
                "frag":
                        tint = Color("ffd23c")
                "atom":
                        tint = Color("9ae84a")
                        size = Vector2(30, 40)
        var n := _art_sprite("bomb_" + kind, size, tint)
        n.position = at
        shot_layer.add_child(n)
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
        var n := _art_sprite("eshot_" + kind,
                Vector2(14, 14) if kind != "missile" else Vector2(30, 12),
                Color("ff8a3c") if kind != "missile" else Color("d84c2a"))
        n.position = at
        n.rotation = vel.angle()
        shot_layer.add_child(n)
        # the family gravities: bullets fly flat, the heavies fall
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
        ebombs.append({"n": n, "vel": vel, "kind": kind, "grav": grav, "hp": 1,
                "armed": true})
        if kind == "missile":
                ebombs[-1]["homing"] = true

func _orbital_laser(at: Vector2) -> void:
        # the satellite's sky laser: a warning line then a burn column
        var col := ColorRect.new()
        col.color = Color(1.0, 0.35, 0.2, 0.0)
        col.size = Vector2(46, tank.position.y - at.y)
        col.position = Vector2(tank.position.x - 23.0, at.y)
        fx_layer.add_child(col)
        fx.append({"n": col, "t": 0.0, "life": 0.55, "kind": "oburn", "hit_at": 0.28})

# =================================================================
# THE SHELLS + THE HITS
# =================================================================
func _shots_tick(dt: float) -> void:
        var dead: Array = []
        for s in shots:
                var n: Node2D = s["n"]
                n.position += (s["vel"] as Vector2) * dt
                if n.position.y < -40.0:
                        dead.append(s)
                        continue
                var hit: Dictionary = _shell_hit(n.position, int(s["dmg"]))
                if not hit.is_empty():
                        dead.append(s)
        for s in dead:
                shots.erase(s)
                (s["n"] as Node2D).queue_free()

## one shell vs the roster: enemies first, then boss parts. Returns the
## victim (or {} when the shell flies on).
func _shell_hit(at: Vector2, dmg: int) -> Dictionary:
        for e in enemies:
                var n: Node2D = e["n"]
                if absf(n.position.x - at.x) < e["w"] * 0.5 + 6.0 \
                                and absf(n.position.y - at.y) < e["h"] * 0.5 + 6.0:
                        _damage_enemy(e, dmg)
                        return e
        if boss != null and is_instance_valid(boss["n"]):
                var parts: Array = boss["parts"]
                if parts.is_empty():
                        # the body exposed: shells bite the core now
                        var bn: Node2D = boss["n"]
                        if absf(bn.position.x - at.x) < 170.0 \
                                        and absf(bn.position.y - at.y) < 96.0:
                                boss["hp"] = int(boss["hp"]) - dmg
                                _boss_bar_set()
                                return {"boss": true}
                        return {}
                for p in parts:
                        var pn: Node2D = p["n"]
                        if absf(pn.position.x - at.x) < p["w"] * 0.5 + 8.0 \
                                        and absf(pn.position.y - at.y) < p["h"] * 0.5 + 8.0:
                                _boss_damage_part(p, float(dmg))
                                return {"boss": true}
        return {}

func _damage_enemy(e: Dictionary, dmg: int) -> void:
        # MIRROR law: the front shield eats everything while it is up
        if String(e["kind"]) == "guard" and bool(e["guard"]) \
                        and (e["n"] as Node2D).position.x > tank.position.x:
                _fx_ring((e["n"] as Node2D).position, Color("58a8e8"), 20.0, 0.2)
                Jukebox.sfx("hws_orbhit", -12.0, 1.3)
                return
        # PLOWMAN law: the plow is armor - shots from the left bounce
        if String(e["kind"]) == "plow" \
                        and (e["n"] as Node2D).position.x > tank.position.x:
                _fx_ring((e["n"] as Node2D).position + Vector2(-e["w"] * 0.4, 0),
                        Color("ffb020"), 18.0, 0.2)
                Jukebox.sfx("hws_orbhit", -12.0, 0.9)
                return
        e["hp"] = int(e["hp"]) - dmg
        if int(e["hp"]) <= 0:
                _kill_enemy(e)

func _kill_enemy(e: Dictionary) -> void:
        var n: Node2D = e["n"]
        _fx_boom(n.position, 1.0 + float(e["w"]) / 160.0)
        _pay_score(int(e["pts"]), n.position)
        run["kills"] += 1
        achievement_count("hw_kill_bank", 1)
        Jukebox.sfx("hws_smallexplode", -6.0, randf_range(0.85, 1.15))
        _enemy_free(e)

## THE SCORE LAW: kills pay; every 1000 pays a life back (max 3)
func _pay_score(pts: int, at: Vector2) -> void:
        add_score(pts)
        achievement_max("hw_score", score)
        if run["lives"] < HWData.LIVES_MAX \
                        and score - int(run["score_life_mark"]) >= HWData.LIFE_PER_SCORE:
                run["score_life_mark"] = score
                run["lives"] += 1
                _fx_text(at, "+1 LIFE", Color("58c470"))
                _war_refresh()

# =================================================================
# THE ENEMY FIRE vs THE TANK
# =================================================================
func _ebombs_tick(dt: float) -> void:
        var dead: Array = []
        for b in ebombs:
                var n: Node2D = b["n"]
                if b.has("homing"):
                        var want := (tank.position - n.position).normalized() * 420.0
                        b["vel"] = ((b["vel"] as Vector2).lerp(want, 1.4 * dt))
                if b.has("guided"):
                        (b as Dictionary)["vel"] = Vector2(
                                (b["vel"] as Vector2).x,
                                (b["vel"] as Vector2).y + 900.0 * dt)
                else:
                        (b as Dictionary)["vel"] = Vector2(
                                (b["vel"] as Vector2).x,
                                (b["vel"] as Vector2).y + float(b["grav"]) * dt)
                n.position += (b["vel"] as Vector2) * dt
                if b.has("frag") and n.position.y > ROAD_Y - 120.0 and not bool(b["armed"]):
                        b["armed"] = true
                        for i in 3:
                                _enemy_shot(n.position,
                                        Vector2(randf_range(-260, 260), randf_range(-460, -260)),
                                        "fraglet")
                        dead.append(b)
                        _fx_boom(n.position, 0.7)
                        continue
                if n.position.y > ROAD_Y + 20.0 or n.position.x < -60.0 \
                                or n.position.x > W + 80.0:
                        match String(b["kind"]):
                                "atom":
                                        _nuke_blast_at(n.position.x, 0.6)
                                "ball":
                                        _fx_ring(Vector2(n.position.x, ROAD_Y),
                                                Color("ffb020"), 120.0, 0.45)
                                        Jukebox.sfx("hws_bigexplode", -4.0, 0.85)
                                        if absf(tank.position.x - n.position.x) < 150.0:
                                                _hurt_tank(tank.position)
                                "meteor", "boulder", "barrel":
                                        _fx_boom(Vector2(n.position.x, ROAD_Y), 0.8)
                                        Jukebox.sfx("hws_smallexplode", -8.0, 1.1)
                        dead.append(b)
                        continue
                if _hits_tank(n.position):
                        if b.has("atom"):
                                _nuke_blast_at(n.position.x, 0.6)
                        dead.append(b)
        for b in dead:
                ebombs.erase(b)
                (b["n"] as Node2D).queue_free()

func _hits_tank(at: Vector2) -> bool:
        if state == GS.TUNNEL:
                return false
        if absf(at.x - tank.position.x) < 44.0 and absf(at.y - TANK_Y) < 34.0:
                _hurt_tank(at)
                return true
        return false

## THE TANK LAW: shields eat hits layer by layer (each layer takes
## ARMOR-level hits), then each hit takes ONE life. 3 lives, no more.
## The iframe gate lives HERE (defense in depth - any caller obeys).
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
                run["iframes"] = 0.7
                _fx_ring(tank.position, Color("58a8e8"), 60.0, 0.35)
                Jukebox.sfx("hws_deflect", -8.0)
                _war_refresh()
                return
        run["lives"] = int(run["lives"]) - 1
        run["iframes"] = 1.4
        _fx_boom(tank.position, 1.4)
        _fx_text(tank.position + Vector2(0, -70), "-1 LIFE", Color("e8574a"))
        Jukebox.sfx("hws_bullethit", -2.0)
        _war_refresh()
        if int(run["lives"]) <= 0:
                _run_over()

# =================================================================
# THE NUKE - the middle zone's gift
# =================================================================
func _nuke() -> void:
        if int(run["nukes"]) <= 0 or state == GS.TUNNEL:
                return
        _nuke_ms = Time.get_ticks_msec()
        run["nukes"] -= 1
        _war_refresh()
        _nuke_blast_at(tank.position.x + 240.0, HWData.aegis_blast_w(meta.level_of("aegis")))
        Jukebox.sfx("hws_nukeblast", 0.0)

## everything inside the blast width dies (the boss parts too, but the
## boss body only bleeds - the nuke is not a boss-killer)
func _nuke_blast_at(cx: float, width_frac: float) -> void:
        var half := W * width_frac * 0.5
        _fx_nukeflash(Vector2(cx, ROAD_Y - 200.0), half)
        var dead: Array = []
        for e in enemies:
                if absf((e["n"] as Node2D).position.x - cx) <= half + e["w"] * 0.4:
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
# THE FRIEND - the helicopter's crates
# =================================================================
func _heli_tick(dt: float) -> void:
        if heli.visible:
                var h := heli
                h.position.x -= 260.0 * dt
                h.position.y = 240.0 + sin(h.position.x * 0.01) * 26.0
                if h.position.x < -160.0:
                        h.visible = false
                        # the pass ends with its crate chain already falling
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
        heli.position = Vector2(W + 140.0, 240.0)
        for c in heli.get_children():
                c.queue_free()
        var body := _art_sprite("heli", Vector2(120, 46), Color("e8b83c"))
        heli.add_child(body)
        heli.set_meta("mode", mode)
        # crate chain: supply = 2 crates; coin = 1 fat crate
        var crates := 2 if mode == "supply" else 1
        for i in crates:
                var kind := mode if mode == "coin" else _roll_drop()
                var n := _art_sprite("crate", Vector2(40, 40), Color("c8933c"))
                n.position = heli.position + Vector2(30.0 * (i + 1), 60.0)
                shot_layer.add_child(n)
                drops.append({"n": n, "kind": kind, "fall": 120.0 + 30.0 * i,
                        "landed": false, "life": 14.0})
        Jukebox.sfx("hws_pupcopter", -10.0)

func _roll_drop() -> String:
        var caps := {
                "shield": run["shields"] < HWData.SHIELD_MAX,
                "nuke": run["nukes"] < HWData.NUKES_MAX,
                "laser": Box.item_owned(game_id, "rig", "laser")
                        and int(run["laser_parts"]) < HWData.aegis_laser_need(meta.level_of("aegis")),
                "life": run["lives"] < HWData.LIVES_MAX,
                "coin": true,           # coins always welcome
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

func _drops_tick(dt: float) -> void:
        var dead: Array = []
        for c in drops:
                var n: Node2D = c["n"]
                if not bool(c["landed"]):
                        n.position.y += float(c["fall"]) * dt
                        n.position.x -= 260.0 * dt * 0.4
                        if n.position.y >= ROAD_Y - 10.0:
                                c["landed"] = true
                                n.position.y = ROAD_Y - 10.0
                else:
                        n.position.x -= 40.0 * dt   # rides the road left
                        c["life"] = float(c["life"]) - dt
                        if float(c["life"]) <= 0.0:
                                dead.append(c)
                                continue
                if absf(n.position.x - tank.position.x) < 52.0 \
                                and absf(n.position.y - TANK_Y) < 60.0:
                        _collect(String(c["kind"]))
                        dead.append(c)
        for c in dead:
                drops.erase(c)
                (c["n"] as Node2D).queue_free()

func _collect(kind: String) -> void:
        match kind:
                "shield":
                        if run["shields"] < HWData.SHIELD_MAX:
                                run["shields"] = int(run["shields"]) + 1
                                (run["shield_hp"] as Array).append(
                                        {"hp": HWData.armor_layer_hp(meta.level_of("armor"))})
                                _fx_text(tank.position + Vector2(0, -80), "+SHIELD",
                                        Color("58a8e8"))
                "nuke":
                        if run["nukes"] < HWData.NUKES_MAX:
                                run["nukes"] = int(run["nukes"]) + 1
                                _fx_text(tank.position + Vector2(0, -80), "+NUKE",
                                        Color("e8574a"))
                "laser":
                        run["laser_parts"] = int(run["laser_parts"]) + 1
                        var need: int = HWData.aegis_laser_need(meta.level_of("aegis"))
                        if int(run["laser_parts"]) >= need:
                                run["laser_parts"] = 0
                                run["laser_on"] = HWData.LASER_BURN
                                _fx_text(tank.position + Vector2(0, -80), "LASER!",
                                        Color("ffb020"))
                                Jukebox.sfx("hws_megalaser_start", 0.0)
                        else:
                                _fx_text(tank.position + Vector2(0, -80), "+PART",
                                        Color("ffb020"))
                "life":
                        if run["lives"] < HWData.LIVES_MAX:
                                run["lives"] = int(run["lives"]) + 1
                                _fx_text(tank.position + Vector2(0, -80), "+1 LIFE",
                                        Color("58c470"))
                "coin":
                        add_run_coins(HWData.COIN_DROP)
                        _fx_text(tank.position + Vector2(0, -80),
                                "+%d COINS" % HWData.COIN_DROP, Arc.COIN)
        _war_refresh()
        Jukebox.sfx("hws_powerup", -6.0, randf_range(0.95, 1.05))

## THE MEGABEAM: burning while laser_on > 0 - a wall of light ahead of
## the tank that erases everything it touches
func _laser_tick(dt: float) -> void:
        if float(run["laser_on"]) <= 0.0:
                return
        run["laser_on"] = float(run["laser_on"]) - dt
        var beam_x := tank.position.x + 70.0
        var dead: Array = []
        for e in enemies:
                var n: Node2D = e["n"]
                if absf(n.position.x - beam_x) < 60.0:
                        e["hp"] = int(e["hp"]) - 260 * dt
                        if int(e["hp"]) <= 0:
                                dead.append(e)
        for e in dead:
                _kill_enemy(e)
        if boss != null:
                for p in boss["parts"]:
                        var pn: Node2D = p["n"]
                        if absf(pn.position.x - beam_x) < 70.0 and bool(p.get("vuln", true)):
                                _boss_damage_part(p, 300.0 * dt)
        var col: ColorRect = _laser_beam_node()
        col.position = Vector2(beam_x - 34.0, 0)
        col.size = Vector2(68, TANK_Y - 20.0)
        col.color = Color(1.0, 0.75, 0.2, 0.55 + 0.2 * sin(Time.get_ticks_msec() * 0.04))

var _laser_col: ColorRect = null
func _laser_beam_node() -> ColorRect:
        if _laser_col == null or not is_instance_valid(_laser_col):
                _laser_col = ColorRect.new()
                _laser_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
                fx_layer.add_child(_laser_col)
        _laser_col.visible = float(run["laser_on"]) > 0.0
        return _laser_col

# =================================================================
# THE PLACES + THE TUNNELS - shuffle law, calm zones, no spawns
# =================================================================
func _enter_intro() -> void:
        # THE LOVE THEME (as-is): the original's own menu-and-war song
        Jukebox.music("res://assets/audio/music/hws_lovetheme.ogg")
        state = GS.INTRO
        var pi: int = place_queue_placeholder()
        _dress_place(pi)
        _war_refresh()

## pass 1: the queue lives in run[] - first place is queue[0].
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
        state = GS.PLACE
        t_state = 0.0
        _roll_wave()
        _war_refresh()
        Jukebox.sfx("hws_v_getready", -4.0)

## the place's clock: when its pressure is served -> the tunnel
func _place_tick(dt: float) -> void:
        _director_tick(dt)
        var served: float = float(place.get("len", 180.0))
        t_state += dt
        if t_state >= served:
                _enter_tunnel()

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
        # the wave queue dies too - a leftover volley would pop the moment
        # the next place opened (the calm must be CALM)
        _wave_units.clear()
        _wave_t = 0.0
        var tunnel := ColorRect.new()
        tunnel.color = Color(0.06, 0.05, 0.05, 0.0)
        tunnel.size = Vector2(W, H)
        fx_layer.add_child(tunnel)
        fx.append({"n": tunnel, "t": 0.0, "life": 4.6, "kind": "tunnel"})
        _war_refresh()
        Jukebox.sfx("hws_swoosh", -6.0)

func _tunnel_tick(dt: float) -> void:
        t_state += dt
        # the tank rolls through: half in, the world swaps, half out
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
                _war_refresh()

func _calm_tick(dt: float) -> void:
        t_state += dt
        run["calm_t"] = float(run["calm_t"]) - dt
        if float(run["calm_t"]) <= 0.0:
                state = GS.PLACE
                t_state = 0.0
                _roll_wave()
                _war_refresh()

# =================================================================
# THE BOSS - every 5 places; pass 7 gives each face its real brain.
# Pass 1 ships the honest skeleton: a gunship-shaped gun platform.
# =================================================================
var boss = null                  # {n, hp, maxhp, parts: [], fire_t} or null
var boss_bar: ProgressBar = null

func _enter_boss() -> void:
        state = GS.BOSS
        t_state = 0.0
        run["bosses_met"] += 1
        var st: Dictionary = HWData.boss_stats(run["bosses_met"] - 1)
        var n := _art_sprite("boss_" + String(st["id"]), Vector2(360, 200),
                Color("702828"))
        n.position = Vector2(W + 260.0, 280.0)
        ent_layer.add_child(n)
        var parts: Array = []
        var bd: Dictionary = HWData.BOSSES[String(st["id"])]
        var fm: float = st["fire_mul"]
        for pid in bd["parts"]:
                var pd: Dictionary = bd["parts"][pid]
                if pid == "params" or int(pd.get("hp", 0)) <= 0:
                        continue
                var pn := _art_sprite("boss_%s_%s" % [String(st["id"]), pid],
                        Vector2(90, 60), Color("382828"))
                pn.position = n.position + Vector2(randf_range(-120, 120),
                        randf_range(60, 130))
                ent_layer.add_child(pn)
                parts.append({"id": pid, "n": pn, "w": 90.0, "h": 60.0,
                        "hp": int(ceil(int(pd["hp"]) * st["hp_mul"])),
                        "fire": float(pd.get("fire", 0.0)) * fm, "fire_t": 1.0,
                        "vuln": true})
        boss = {"n": n, "id": String(st["id"]), "hp": int(st["hp"]),
                "maxhp": int(st["hp"]), "parts": parts,
                "fire_t": 1.6 * fm, "spd_mul": st["spd_mul"],
                "cb": int(st["comeback"]), "entered": false}
        _boss_bar_show(String(HWData.BOSSES[String(st["id"])]["name"]))
        Jukebox.sfx("hws_v_danger", 0.0)
        _war_refresh()

func _boss_tick(dt: float) -> void:
        if boss == null:
                return
        var n: Node2D = boss["n"]
        if not bool(boss["entered"]):
                n.position.x = move_toward(n.position.x, W * 0.72, 220.0 * dt)
                if n.position.x <= W * 0.72 + 1.0:
                        boss["entered"] = true
                _boss_parts_follow()
                return
        t_state += dt
        # THE FACES: each kind drives its own fight brain (pass 3).
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
        # the vuln law: when every part is dead the body bleeds from shells
        if (boss["parts"] as Array).is_empty():
                boss["vuln"] = true

func _boss_parts_follow() -> void:
        if boss == null:
                return
        var n: Node2D = boss["n"]
        var now := Time.get_ticks_msec() * 0.001
        for p in boss["parts"]:
                var pn: Node2D = p["n"]
                pn.position = n.position + Vector2(
                        sin(now * 1.7 + pn.position.x * 0.01) * 100.0,
                        95.0 + cos(now * 1.3 + pn.position.y * 0.01) * 32.0)

# =====================================================
# THE TEN BRAINS - each face fights its own war.
# Numbers ride the comeback multipliers already baked into the parts.
# =====================================================
## the shared hover: a lazy figure the bodies ride
func _boss_hover(n: Node2D, t: float, cx := 0.72, amp := 200.0) -> void:
        n.position.x = W * cx + sin(t * 0.5) * amp
        n.position.y = 280.0 + sin(t * 0.8) * 70.0

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
                                        .normalized() * 620.0, "missile")

## aimed gun burst from a world position
func _boss_burst(at: Vector2, count: int, spread := 0.22, spd := 600.0) -> void:
        for i in count:
                var a := (tank.position - at).angle() \
                        + randf_range(-spread, spread)
                _enemy_shot(at, Vector2.from_angle(a) * spd, "bullet")

func _brain_gunship(n: Node2D, dt: float) -> void:
        _boss_hover(n, t_state)
        _parts_fire_missiles(dt)
        # the turret sprays a fan of bullets at the tank
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 2.2 * float(boss["spd_mul"])
                _boss_burst(n.position + Vector2(0, 90), 5, 0.3)

func _brain_dreadnought(n: Node2D, dt: float) -> void:
        # the hull crawls one way, then the other, guns in sequence
        var dir := 1.0 if sin(t_state * 0.22) > 0.0 else -1.0
        n.position.x = clampf(n.position.x + dir * 120.0 * dt, W * 0.34, W - 240.0)
        n.position.y = 340.0 + sin(t_state * 0.7) * 26.0
        _parts_fire_missiles(dt)   # the launcher only (its fire > 0)
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 2.6 * float(boss["spd_mul"])
                for p in boss["parts"]:
                        if String(p["id"]).begins_with("t"):
                                _boss_burst((p["n"] as Node2D).position, 3, 0.16, 660.0)

func _brain_skystealer(n: Node2D, dt: float) -> void:
        _boss_hover(n, t_state, 0.6, 130.0)
        # THE TRACTOR CYCLE: the dish dips, rains meteors, retracts
        var cycle := fmod(t_state, 14.0)
        var dipping := cycle > 6.0 and cycle < 12.0
        n.position.y += (40.0 if dipping else -30.0) * dt
        n.position.y = clampf(n.position.y, 200.0, 420.0)
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if dipping and float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 0.55 / float(boss["spd_mul"])
                var mx := randf_range(80.0, W - 80.0)
                _enemy_shot(Vector2(mx, n.position.y + 140.0),
                        Vector2(0, 160.0), "meteor")
        elif not dipping:
                boss["fire_t"] = minf(float(boss["fire_t"]), 0.4)

func _brain_wreckball(n: Node2D, dt: float) -> void:
        # the walker strides and swings the ball on its chain
        _boss_hover(n, t_state, 0.62, 240.0)
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 2.8 * float(boss["spd_mul"])
                # the ball slams down at the tank's x
                _enemy_shot(Vector2(tank.position.x, 60.0),
                        Vector2(0, 900.0), "ball")

func _brain_warhead(n: Node2D, dt: float) -> void:
        _boss_hover(n, t_state, 0.78, 90.0)
        _parts_fire_missiles(dt)
        # THE CHARGE: every ~6s it lunges across, bombing the whole road
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
        # the ape: throws, then leaps and STOMPS a shockwave
        var phase := fmod(t_state, 9.0)
        if phase < 6.0:
                _boss_hover(n, t_state, 0.72, 180.0)
                boss["fire_t"] = float(boss["fire_t"]) - dt
                if float(boss["fire_t"]) <= 0.0:
                        boss["fire_t"] = 1.5 / float(boss["spd_mul"])
                        _enemy_shot(n.position + Vector2(-60, 40),
                                Vector2(-520.0, -260.0), "barrel")
        else:
                # the leap: arc to the tank and slam
                var lp := (phase - 6.0) / 3.0
                var sx := n.position.x if not boss.has("leap_x") \
                        else float(boss["leap_x"])
                if lp < 0.05:
                        boss["leap_x"] = n.position.x
                        sx = n.position.x
                n.position.x = lerpf(sx, tank.position.x, minf(lp * 1.6, 1.0))
                n.position.y = 500.0 - sin(lp * PI) * 380.0
                if lp >= 0.98:
                        boss.erase("leap_x")
                        _fx_ring(Vector2(n.position.x, ROAD_Y - 20.0),
                                Color("ffb020"), 140.0, 0.5)
                        Jukebox.sfx("hws_bigexplode", -2.0, 0.8)
                        if absf(tank.position.x - n.position.x) < 200.0:
                                _hurt_tank(tank.position)

func _brain_eyebot(n: Node2D, dt: float) -> void:
        _boss_hover(n, t_state, 0.74, 150.0)
        # the hand pod spits; the eye sweeps a bolt
        _parts_fire_missiles(dt)
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 1.4 / float(boss["spd_mul"])
                _boss_burst(n.position + Vector2(0, 40), 4, 0.12, 700.0)

func _brain_mechworm(n: Node2D, dt: float) -> void:
        # dives under, tunnels, bursts up under the tank, spits boulders
        var cycle := fmod(t_state, 10.0)
        if cycle < 5.0:
                _boss_hover(n, t_state, 0.7, 220.0)
                boss["fire_t"] = float(boss["fire_t"]) - dt
                if float(boss["fire_t"]) <= 0.0:
                        boss["fire_t"] = 0.7 / float(boss["spd_mul"])
                        var bx := tank.position.x + randf_range(-160, 160)
                        _enemy_shot(Vector2(bx, 40.0), Vector2(0, 520.0), "boulder")
        else:
                # submerged: a sand ripple chases the tank, then the breach
                var lp := (cycle - 5.0) / 5.0
                n.position.x = lerpf(n.position.x, tank.position.x, 2.4 * dt)
                n.position.y = ROAD_Y + 120.0 - sin(lp * PI) * 560.0
                if lp >= 0.9 and lp < 0.95:
                        _fx_ring(Vector2(n.position.x, ROAD_Y),
                                Color(0.7, 0.6, 0.4, 0.8), 90.0, 0.4)

func _brain_warbot(n: Node2D, dt: float) -> void:
        # strafes, missiles from the pod, then THE EYE BEAM telegraphed
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
                Jukebox.sfx("hws_megalaser_start", -6.0, 0.8)

func _brain_secretfist(n: Node2D, dt: float) -> void:
        # the final fist: everything at once, slower rhythm
        _boss_hover(n, t_state, 0.5, 150.0)
        _parts_fire_missiles(dt)
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 1.9 / float(boss["spd_mul"])
                var pick := randi() % 3
                if pick == 0:
                        _drop_bomb(Vector2(tank.position.x, n.position.y + 80.0),
                                "atom")
                elif pick == 1:
                        _boss_burst(n.position + Vector2(0, 60), 6, 0.4, 640.0)
                else:
                        var col := ColorRect.new()
                        col.color = Color(1.0, 0.35, 0.2, 0.0)
                        col.size = Vector2(70, tank.position.y - n.position.y)
                        col.position = Vector2(tank.position.x - 35.0, n.position.y)
                        fx_layer.add_child(col)
                        fx.append({"n": col, "t": 0.0, "life": 0.7,
                                "kind": "oburn", "hit_at": 0.4})

func _boss_damage_part(p: Dictionary, dmg: float) -> void:
        if bool(p.get("core", false)):
                # the body itself: only bleeds a little from nukes
                boss["hp"] = int(boss["hp"]) - int(ceil(dmg))
        else:
                p["hp"] = int(p["hp"]) - int(ceil(dmg))
                if int(p["hp"]) <= 0:
                        _fx_boom((p["n"] as Node2D).position, 1.6)
                        (p["n"] as Node2D).queue_free()
                        (boss["parts"] as Array).erase(p)
                        Jukebox.sfx("hws_smallexplode", -2.0, 0.8)
        if boss != null and (boss["parts"] as Array).is_empty():
                # body exposed: shells now hit the body
                pass
        _boss_bar_set()

func _boss_bar_show(title: String) -> void:
        if boss_bar != null and is_instance_valid(boss_bar):
                boss_bar.queue_free()
        boss_bar = ProgressBar.new()
        boss_bar.show_percentage = false
        boss_bar.custom_minimum_size = Vector2(W * 0.5, 22)
        boss_bar.position = Vector2(W * 0.25, WAR_Y + 44.0)
        boss_bar.max_value = 1.0
        boss_bar.value = 1.0
        boss_bar.modulate = Color("e8574a")
        war_layer.add_child(boss_bar)
        var lbl := Arc.label(title, 20, Arc.CARD)
        lbl.position = Vector2(W * 0.25, WAR_Y + 20.0)
        war_layer.add_child(lbl)
        boss_bar.set_meta("lbl", lbl)

func _boss_bar_set() -> void:
        if boss_bar == null or not is_instance_valid(boss_bar):
                return
        var frac: float = float(boss["hp"]) / float(boss["maxhp"])
        boss_bar.value = frac
        var lbl: Label = boss_bar.get_meta("lbl")
        lbl.text = "%s  x%d" % [String(HWData.BOSSES[boss["id"]]["name"]),
                1 + int(boss["cb"])]

func _boss_die() -> void:
        _pay_score(100, (boss["n"] as Node2D).position)
        _fx_boom((boss["n"] as Node2D).position, 3.0)
        Jukebox.sfx("hws_bossblast", 2.0)
        for p in boss["parts"]:
                (p["n"] as Node2D).queue_free()
        boss["n"].queue_free()
        boss = null
        if boss_bar != null and is_instance_valid(boss_bar):
                boss_bar.queue_free()
                boss_bar = null
        meta.mint_pts(1)
        achievement_max("hw_bosses_run", run["bosses_met"])
        achievement_count("hw_boss_bank", 1)
        _enter_armory()

# =================================================================
# THE ARMORY - after every boss: spend or rebalance (permanent)
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
                var nm := Arc.label(String(u["name"]), 24, Arc.INK)
                nm.custom_minimum_size = Vector2(280, 0)
                row.add_child(nm)
                var lv_lbl := Arc.label("LV %d" % meta.level_of(sid), 24, Arc.ACCENT)
                lv_lbl.custom_minimum_size = Vector2(140, 0)
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
        vb.add_child(Arc.button("BACK TO THE WAR", Vector2(560, 84), 28, Arc.GOOD,
                func():
                        sheet_pop()
                        _armory_closed()))
        Arc.fit_sheet(vb, 1)

func _armory_free_text(free_lbl: Label) -> void:
        free_lbl.text = "FREE POINTS: %d   (banked %d)" % [meta.pts_free(),
                meta.pts_banked()]

func _armory_change(sid: String, dir: int, free_lbl: Label, rows: VBoxContainer) -> void:
        if dir > 0:
                meta.raise(sid)
        else:
                meta.lower(sid)
        _armory_free_text(free_lbl)
        # refresh the level labels in place
        var i := 0
        for sid2 in HWData.UPGRADES:
                var row: HBoxContainer = rows.get_child(i)
                (row.get_child(1) as Label).text = "LV %d" % meta.level_of(sid2)
                i += 1
        Jukebox.sfx("hws_buttondown", -8.0)

func _armory_closed() -> void:
        state = GS.CALM
        t_state = 0.0
        run["calm_t"] = 3.0
        _war_refresh()

# =================================================================
# THE OVER - the run ends where the tank dies
# =================================================================
func _run_over() -> void:
        state = GS.OVER
        meta.record_run(run["places_done"], run["bosses_met"], score, run["kills"])
        check_achievements()
        _fx_boom(tank.position, 3.0)
        Jukebox.sfx("hws_v_gameover", 0.0)
        await get_tree().create_timer(1.4).timeout
        finish_run(score)

# =================================================================
# THE FX - explosions, rings, texts, the tunnel veil
# =================================================================
func _fx_boom(at: Vector2, scale_f: float) -> void:
        var n := _art_sprite("boom", Vector2(120, 120) * scale_f, Color("ffaa3c"))
        n.position = at
        fx_layer.add_child(n)
        fx.append({"n": n, "t": 0.0, "life": 0.5, "kind": "boom"})

func _fx_ring(at: Vector2, tint: Color, r: float, life: float) -> void:
        var n := _art_sprite("ring", Vector2(r * 2.0, r * 2.0), tint)
        n.position = at
        fx_layer.add_child(n)
        fx.append({"n": n, "t": 0.0, "life": life, "kind": "ring"})

func _fx_nukeflash(at: Vector2, half: float) -> void:
        # the original's white-out wipe + the smoke column riding it
        var wipe := TextureRect.new()
        wipe.texture = _src_tex("sprites/nukebg.jpg")
        wipe.stretch_mode = TextureRect.STRETCH_SCALE
        wipe.size = Vector2(W, H)
        fx_layer.add_child(wipe)
        fx.append({"n": wipe, "t": 0.0, "life": 0.5, "kind": "flash"})
        var n := _art_sprite("mush", Vector2(half * 2.2, half * 1.6),
                Color("fff0b0"))
        n.position = at
        fx_layer.add_child(n)
        fx.append({"n": n, "t": 0.0, "life": 1.6, "kind": "mush"})

func _fx_text(at: Vector2, msg: String, tint: Color) -> void:
        var l := Arc.label(msg, 30, tint)
        l.position = at + Vector2(-60, -40)
        fx_layer.add_child(l)
        fx.append({"n": l, "t": 0.0, "life": 1.1, "kind": "text"})

func _fx_tick(dt: float) -> void:
        var dead: Array = []
        for f in fx:
                f["t"] = float(f["t"]) + dt
                var t: float = float(f["t"])
                var life: float = float(f["life"])
                var n: Node = f["n"]
                match String(f["kind"]):
                        "flash":
                                if n is CanvasItem:
                                        (n as CanvasItem).modulate.a \
                                                = 1.0 - t / life
                        "boom", "ring":
                                if n is Node2D:
                                        (n as Node2D).scale = Vector2.ONE \
                                                .lerp(Vector2(1.4, 1.4), t / life)
                                        var spr: Sprite2D = (n as Node2D) \
                                                .get_meta("spr", null)
                                        if spr != null and spr.hframes > 1:
                                                spr.frame = mini(int(t / life \
                                                        * float(spr.hframes)),
                                                        spr.hframes - 1)
                                if n is CanvasItem:
                                        (n as CanvasItem).modulate.a = 1.0 - t / life
                        "mush":
                                if n is Node2D:
                                        (n as Node2D).scale = Vector2(0.4, 0.4) \
                                                .lerp(Vector2.ONE, minf(t / 0.5, 1.0))
                                        var spr2: Sprite2D = (n as Node2D) \
                                                .get_meta("spr", null)
                                        if spr2 != null and spr2.hframes > 1:
                                                spr2.frame = mini(int(t / life \
                                                        * float(spr2.hframes)),
                                                        spr2.hframes - 1)
                                if n is CanvasItem:
                                        (n as CanvasItem).modulate.a = clampf(
                                                1.4 - t / life, 0.0, 1.0)
                        "text":
                                if n is Node2D:
                                        (n as Node2D).position.y -= 46.0 * dt
                                if n is CanvasItem:
                                        (n as CanvasItem).modulate.a = 1.0 - t / life
                        "oburn":
                                if n is ColorRect:
                                        var hit_at: float = float(f.get("hit_at", 0.0))
                                        var prev := t - dt
                                        (n as ColorRect).color.a = (0.75 - t / life) \
                                                if t > hit_at else 0.25
                                        if prev < hit_at and t >= hit_at:
                                                if absf((n as ColorRect).position.x
                                                        + 23.0 - tank.position.x) < 60.0:
                                                        _hurt_tank(tank.position)
                        "tunnel":
                                var k := t / life
                                var a := sin(k * PI)
                                if n is ColorRect:
                                        (n as ColorRect).color.a = a * 0.96
                                        (n as ColorRect).color.v = 0.0
                if t >= life:
                        dead.append(f)
        for f in dead:
                fx.erase(f)
                (f["n"] as Node).queue_free()
        if _laser_col != null and is_instance_valid(_laser_col) \
                        and float(run["laser_on"]) <= 0.0:
                _laser_col.visible = false

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
        if state in [GS.PLACE, GS.CALM, GS.BOSS]:
                _enemies_tick(dt)
                _heli_tick(dt)
                _drops_tick(dt)
                _laser_tick(dt)
        if state in [GS.PLACE, GS.CALM, GS.BOSS, GS.TUNNEL]:
                _shots_tick(dt)
                _ebombs_tick(dt)
        run["fire_cd"] = maxf(0.0, float(run["fire_cd"]) - dt)
        run["iframes"] = maxf(0.0, float(run["iframes"]) - dt)
        if aim_ptr != -1 and float(run["fire_cd"]) <= 0.0 \
                        and state in [GS.PLACE, GS.CALM, GS.BOSS]:
                _fire()
        _steer_glide(dt)
        # the turret arm tracks the aim finger; the aim cursor rides it
        var turret: Sprite2D = tank.get_meta("turret")
        turret.frame = _turret_frame()
        var aim_cur: Sprite2D = world.get_meta("aim_cursor")
        aim_cur.visible = aim_ptr != -1
        aim_cur.position = aim_pos
        # the turret frame also tracks when only steering moves the tank
        # the planes crawl at the world speed - the ground carries the war
        scroll_x += WORLD_SPEED * PLANE_GROUND * dt
        _layer_roll(world.get_meta("sky"), 0.0, WORLD_SPEED * dt)
        _layer_roll(world.get_meta("slab"), 0.0, WORLD_SPEED * dt)
        _layer_roll(world.get_meta("far"), 0.0, WORLD_SPEED * dt)
        _layer_roll(world.get_meta("ground"), 0.0, WORLD_SPEED * dt)
        _props_tick(dt, WORLD_SPEED * PLANE_GROUND * dt)
        # the tank's iframes blink
        tank.modulate.a = 0.45 if (fmod(run["iframes"], 0.16) > 0.08
                and float(run["iframes"]) > 0.0) else 1.0
        _fx_tick(dt)
        # the boss dies when its hp does (checked here: parts AND body)
        if boss != null and int(boss["hp"]) <= 0:
                _boss_die()

# =================================================================
# THE SHOP - skins + the four locked stats + THE LASER. THE SHEET STACK
# LAW (v0.3.3-p2 doctrine): the shop rides sheet_push/sheet_pop so the
# back button and the Android back both close it, the pair dies exactly,
# and the state hears the pop. No optionals menu exists (the GDD).
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
        vb.add_child(sc)
        # ---- TANK SKINS ----
        box.add_child(_shop_lbl("TANK SKINS"))
        for id in HWData.SKINS:
                box.add_child(_shop_skin_row(id))
        # ---- THE ARMORY LOCKS ----
        box.add_child(_shop_lbl("ARMORY UNLOCKS"))
        for sid in HWData.UPGRADES:
                if bool(HWData.UPGRADES[sid]["open"]):
                        continue
                box.add_child(_shop_stat_row(sid))
        # ---- THE LASER ----
        box.add_child(_shop_lbl("THE SECRET WEAPON"))
        box.add_child(_shop_laser_row())
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): _shop_close()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

## both exits (the CLOSE button and the back path) land here through
## sheet_pop -> _goga_sheet_popped
func _shop_close() -> void:
        sheet_pop()

func _shop_reopen() -> void:
        # a rebuy refreshes the SAME window (the house refresh law)
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
        return _shop_price_btn(String(u["name"]), int(u["shop_price"]), func():
                if Box.buy_item(game_id, "upg", sid, int(u["shop_price"])):
                        Jukebox.sfx("hws_powerup", -4.0)
                _shop_reopen())

func _shop_laser_row() -> Control:
        if Box.item_owned(game_id, "rig", "laser"):
                var l := Arc.fit_label("THE LASER  - IN THE WAR", 22,
                        Arc.GOOD, 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        return _shop_price_btn("THE LASER", HWData.LASER_PRICE, func():
                if Box.buy_item(game_id, "rig", "laser", HWData.LASER_PRICE):
                        Jukebox.sfx("hws_megalaser_start", -2.0)
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
                _war_refresh()
                Jukebox.sfx("hws_buttondown", -6.0)
