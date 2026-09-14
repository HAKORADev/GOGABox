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
var move_ptr := -1
var move_last_x := 0.0
var shoot_ptr := -1
var nuke_ptrs := {}              # index -> start pos (tap detector)

# war room widget refs
var wg := {}                     # lives/shields/nukes/laser/place labels + bars

func _goga_setup() -> void:
        meta = HWMeta.load_meta()
        game_id = "heavywar"
        pause_end_run = false
        _run_reset()
        _build_world()
        _build_war_room()
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

        # parallax layers - ColorRect gradients + silhouette bands now;
        # the art pass swaps in real textures through the same slots
        world.set_meta("sky", _mk_layer(H - 140.0, 0.0))
        world.set_meta("far", _mk_layer(150.0, 0.12))
        world.set_meta("near", _mk_layer(120.0, 0.3))
        world.set_meta("ground", _mk_layer(H - 140.0 - 95.0, 1.0))
        world.set_meta("road", _mk_layer(52.0, 1.0))
        _dress_place(0)

        tank = Node2D.new()
        tank.position = Vector2(W * 0.35, TANK_Y)
        add_child(tank)
        var body := _art_sprite("tank", Vector2(96, 60), Color("5a6e3a"))
        tank.add_child(body)
        tank.set_meta("skin", "olive")

        heli = Node2D.new()
        heli.visible = false
        add_child(heli)

func _mk_layer(h: float, scroll: float) -> Dictionary:
        # each layer: two wide rects leapfrogging for an endless scroll
        var holder := Node2D.new()
        world.add_child(holder)
        var a := ColorRect.new()
        a.size = Vector2(W + 4.0, h)
        a.position = Vector2(0, 0)
        var b := ColorRect.new()
        b.size = Vector2(W + 4.0, h)
        b.position = Vector2(W + 4.0, 0)
        holder.add_child(a)
        holder.add_child(b)
        return {"node": holder, "a": a, "b": b, "h": h, "scroll": scroll, "off": 0.0}

func _layer_roll(l: Dictionary, speed: float, dx: float) -> void:
        l["off"] = fmod(l["off"] + dx * float(l["scroll"]), W + 4.0)
        var x: float = -float(l["off"])
        (l["a"] as ColorRect).position.x = x
        (l["b"] as ColorRect).position.x = x + W + 4.0

## paint the parallax slots with the place's palette (the art pass drops
## real textures into these same slots - the sim never changes)
func _dress_place(pi: int) -> void:
        place = HWData.PLACES[pi if pi < HWData.PLACES.size() else 0]
        var sky: Dictionary = world.get_meta("sky")
        # cheap vertical gradient without a shader file: a top band + the body
        (sky["a"] as ColorRect).color = place["sky"][0]
        (sky["a"] as ColorRect).size = Vector2(W + 4.0, 200)
        (sky["a"] as ColorRect).position = Vector2(0, 0)
        (sky["b"] as ColorRect).color = place["sky"][1]
        (sky["b"] as ColorRect).size = Vector2(W + 4.0, sky["h"] - 200.0)
        (sky["b"] as ColorRect).position = Vector2(0, 200)
        var far: Dictionary = world.get_meta("far")
        (far["a"] as ColorRect).color = place["far"]
        (far["b"] as ColorRect).color = place["far"]
        var near: Dictionary = world.get_meta("near")
        (near["a"] as ColorRect).color = place["near"]
        (near["b"] as ColorRect).color = place["near"]
        var gnd: Dictionary = world.get_meta("ground")
        (gnd["a"] as ColorRect).color = place["ground"]
        (gnd["b"] as ColorRect).color = place["ground"]
        var road: Dictionary = world.get_meta("road")
        (road["a"] as ColorRect).color = place["road"]
        (road["b"] as ColorRect).color = place["road"]
        _layout_layers()

func _layout_layers() -> void:
        var sky: Dictionary = world.get_meta("sky")
        (sky["node"] as Node2D).position.y = 0
        var far: Dictionary = world.get_meta("far")
        (far["node"] as Node2D).position.y = H - 140.0 - far["h"] - 130.0
        var near: Dictionary = world.get_meta("near")
        (near["node"] as Node2D).position.y = H - 140.0 - near["h"] - 20.0
        var gnd: Dictionary = world.get_meta("ground")
        (gnd["node"] as Node2D).position.y = H - 140.0
        var road: Dictionary = world.get_meta("road")
        (road["node"] as Node2D).position.y = ROAD_Y - 14.0

## THE ART INDIRECTION: real texture when the art pass has painted it,
## an honest colored slab when it has not. One point of swap, forever.
func _art_sprite(art_id: String, size: Vector2, tint: Color) -> Node2D:
        var holder := Node2D.new()
        var path := ART + "spr_" + art_id + ".png"
        if ResourceLoader.exists(path):
                var sp := Sprite2D.new()
                sp.texture = load(path)
                var tex_size: Vector2 = sp.texture.get_size()
                sp.scale = size / tex_size
                holder.add_child(sp)
        else:
                var r := ColorRect.new()
                r.color = tint
                r.size = size
                r.position = -size / 2.0
                holder.add_child(r)
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
                if d.index == move_ptr:
                        _move_tank(d.position.x - move_last_x)
                        move_last_x = d.position.x
        elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
                var mb := event as InputEventMouseButton
                _touch(-1, mb.position, mb.pressed)

func _touch(idx: int, pos: Vector2, down: bool) -> void:
        if down:
                if pos.x < Z_MOVE:
                        if move_ptr == -1:
                                move_ptr = idx
                                move_last_x = pos.x
                elif pos.x > Z_SHOOT:
                        if shoot_ptr == -1:
                                shoot_ptr = idx
                                _fire()
                else:
                        # the mouse emulation double-path guard: a real finger
                        # AND its synthetic mouse twin land in the same frame
                        if not _nuke_debounce():
                                nuke_ptrs[idx] = pos
        else:
                if idx == move_ptr:
                        move_ptr = -1
                elif idx == shoot_ptr:
                        shoot_ptr = -1
                elif nuke_ptrs.has(idx):
                        var p0: Vector2 = nuke_ptrs[idx]
                        nuke_ptrs.erase(idx)
                        if pos.distance_to(p0) <= 18.0 and not _nuke_debounce():
                                _nuke()

var _nuke_ms := 0
## true when a nuke already fired within 120ms (the emulation twin)
func _nuke_debounce() -> bool:
        var now := Time.get_ticks_msec()
        if now - _nuke_ms < 120:
                return true
        return false

func _move_tank(dx: float) -> void:
        tank.position.x = clampf(tank.position.x + dx * 1.7, 60.0, W - 60.0)

# =================================================================
# THE GUN - streams fan with CANNONS; damage = SHELLS; cd = RELOAD
# =================================================================
func _fire() -> void:
        if run["fire_cd"] > 0.0:
                return
        run["fire_cd"] = HWData.reload_cd(meta.level_of("reload"))
        var streams := HWData.cannon_streams(meta.level_of("cannons"))
        var dmg := HWData.shell_dmg(meta.level_of("shells"))
        for i in streams:
                var spread: float = (float(i) - float(streams - 1) * 0.5) * 0.10
                var n := _art_sprite("shell", Vector2(10, 26), Color("ffe08a"))
                n.position = tank.position + Vector2(0, -34)
                n.rotation = spread
                shot_layer.add_child(n)
                shots.append({"n": n, "vel": Vector2(sin(spread), -cos(spread)) * 1500.0,
                        "dmg": dmg})
        Jukebox.sfx("hw_fire", -8.0, randf_range(0.94, 1.06))

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
        Jukebox.sfx("hw_bombfall", -14.0, randf_range(0.9, 1.1))

func _enemy_shot(at: Vector2, vel: Vector2, kind: String) -> void:
        var n := _art_sprite("eshot_" + kind,
                Vector2(14, 14) if kind != "missile" else Vector2(30, 12),
                Color("ff8a3c") if kind != "missile" else Color("d84c2a"))
        n.position = at
        n.rotation = vel.angle()
        shot_layer.add_child(n)
        ebombs.append({"n": n, "vel": vel, "kind": kind, "grav": 0.0, "hp": 1,
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
                Jukebox.sfx("hw_rico", -12.0, 1.3)
                return
        # PLOWMAN law: the plow is armor - shots from the left bounce
        if String(e["kind"]) == "plow" \
                        and (e["n"] as Node2D).position.x > tank.position.x:
                _fx_ring((e["n"] as Node2D).position + Vector2(-e["w"] * 0.4, 0),
                        Color("ffb020"), 18.0, 0.2)
                Jukebox.sfx("hw_rico", -12.0, 0.9)
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
        Jukebox.sfx("hw_boom", -6.0, randf_range(0.85, 1.15))
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
                        if b.has("atom"):
                                _nuke_blast_at(n.position.x, 0.6)
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
                Jukebox.sfx("hw_shieldhit", -8.0)
                _war_refresh()
                return
        run["lives"] = int(run["lives"]) - 1
        run["iframes"] = 1.4
        _fx_boom(tank.position, 1.4)
        _fx_text(tank.position + Vector2(0, -70), "-1 LIFE", Color("e8574a"))
        Jukebox.sfx("hw_tankhit", -2.0)
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
        Jukebox.sfx("hw_nuke", 0.0)

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
        Jukebox.sfx("hw_heli", -10.0)

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
                                Jukebox.sfx("hw_lasergo", 0.0)
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
        Jukebox.sfx("hw_pickup", -6.0, randf_range(0.95, 1.05))

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
        Jukebox.sfx("hw_start", -4.0)

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
        Jukebox.sfx("hw_tunnel", -6.0)

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
                        "fire": float(pd["fire"]) * fm, "fire_t": 1.0,
                        "vuln": true})
        boss = {"n": n, "id": String(st["id"]), "hp": int(st["hp"]),
                "maxhp": int(st["hp"]), "parts": parts,
                "fire_t": 1.6 * fm, "spd_mul": st["spd_mul"],
                "cb": int(st["comeback"]), "entered": false}
        _boss_bar_show(String(HWData.BOSSES[String(st["id"])]["name"]))
        Jukebox.sfx("hw_bossgo", 0.0)
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
        # the skeleton fight: hover + aimed volleys from the parts
        n.position.x = W * 0.72 + sin(t_state * 0.5) * 220.0
        n.position.y = 280.0 + sin(t_state * 0.8) * 70.0
        _boss_parts_follow()
        boss["fire_t"] = float(boss["fire_t"]) - dt
        if float(boss["fire_t"]) <= 0.0:
                boss["fire_t"] = 1.6 * float(boss["spd_mul"])
                for p in boss["parts"]:
                        var pn: Node2D = p["n"]
                        _enemy_shot(pn.position,
                                (tank.position - pn.position).normalized() * 560.0,
                                "bullet")
        for p in boss["parts"]:
                p["fire_t"] = float(p["fire_t"]) - dt
                if float(p["fire_t"]) <= 0.0:
                        p["fire_t"] = float(p["fire"])
                        _enemy_shot((p["n"] as Node2D).position,
                                (tank.position - (p["n"] as Node2D).position)
                                        .normalized() * 620.0, "missile")

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
                        Jukebox.sfx("hw_boom", -2.0, 0.8)
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
        Jukebox.sfx("hw_bossdie", 2.0)
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
        Jukebox.sfx("hw_click", -8.0)

func _armory_closed() -> void:
        state = GS.CALM
        t_state = 0.0
        run["calm_t"] = 3.0
        _war_refresh()

## THE BACK LAW sync: the HUD/Android back path pops the sheet through the
## base - hear it here so the state never desyncs from the stack
func _goga_sheet_popped(id: String) -> void:
        if id == "armory" and state == GS.ARMORY:
                _armory_closed()

# =================================================================
# THE OVER - the run ends where the tank dies
# =================================================================
func _run_over() -> void:
        state = GS.OVER
        meta.record_run(run["places_done"], run["bosses_met"], score, run["kills"])
        check_achievements()
        _fx_boom(tank.position, 3.0)
        Jukebox.sfx("hw_gameover", 0.0)
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
        var n := _art_sprite("mush", Vector2(half * 2.2, half * 1.6), Color("fff0b0"))
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
                        "boom", "ring":
                                if n is Node2D:
                                        (n as Node2D).scale = Vector2.ONE \
                                                .lerp(Vector2(1.4, 1.4), t / life)
                                if n is CanvasItem:
                                        (n as CanvasItem).modulate.a = 1.0 - t / life
                        "mush":
                                if n is Node2D:
                                        (n as Node2D).scale = Vector2(0.4, 0.4) \
                                                .lerp(Vector2.ONE, minf(t / 0.5, 1.0))
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
        if shoot_ptr != -1 and float(run["fire_cd"]) <= 0.0 \
                        and state in [GS.PLACE, GS.CALM, GS.BOSS]:
                _fire()
        # the road never sleeps - the world scrolls even in the calm
        _layer_roll(world.get_meta("far"), 0.0, 46.0 * dt)
        _layer_roll(world.get_meta("near"), 0.0, 110.0 * dt)
        _layer_roll(world.get_meta("ground"), 0.0, 300.0 * dt)
        _layer_roll(world.get_meta("road"), 0.0, 420.0 * dt)
        # the tank's iframes blink
        tank.modulate.a = 0.45 if (fmod(run["iframes"], 0.16) > 0.08
                and float(run["iframes"]) > 0.0) else 1.0
        _fx_tick(dt)
        # the boss dies when its hp does (checked here: parts AND body)
        if boss != null and int(boss["hp"]) <= 0:
                _boss_die()
