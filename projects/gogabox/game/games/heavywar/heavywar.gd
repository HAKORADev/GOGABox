extends GogaGame
## HEAVY WAR (v040-6) - the survival rogue-like, THE OWNER'S TEST REPORT
## WORKED TO THE BONE. Every visual is CODE-DRAWN (smooth steel, no pixel
## art). The name is HEAVY WAR - no subtitle, no "rogue arsenal".
##   * THE SHOP SPLIT: the SCRAP SHOP is the war's proper shop (8 honest
##     items, paid in scrap, the real prices) and the normal GOGABox SHOP
##     is back in its own place (skins, GOGACoins, LOCKED until bought).
##   * THE TANK LAYOUT LAW: the GROUND layer is wide enough for every
##     wheel, the BOTTOM layer is the SAME width and the rockets live IN
##     it, only the UPPER layer is smaller - the MGs ride its shoulders.
##   * THE COIN LAW: a real GOGACoin drops after every 500 kills; bosses
##     pay 5 direct. No timer, no cheap 25-kill coins.
##   * THE HUD LAW: score (with a DESIGNED plane icon) right, the top-left
##     carries hull / weapons / LVL+XP / the REMAINING widget (time +
##     enemies) in bigger outlined text; the scrap counter is a proper
##     widget with its icon; NO bottom coin text, NO bank text in the HUD.
##   * THE BOSS LAW: the WARNING siren, a dramatic ENTRANCE (the opposite
##     side, fast, with escorts), SHIELD phases at 66%/33%, harder bites.
##     The Dust Reaver fix: the sidewinder now ARRIVES (it used to slide
##     off the world edge forever).
##   * THE TUNNEL LAW: the tunnel is part of the world - a portal rides
##     in, the tank DRIVES THROUGH it (rock ceiling, ribs, lights, a calm
##     coin trail), and the drive ends in the next place's daylight.
##   * THE CONTROLS LAW: on a touch screen the emulated mouse is IGNORED -
##     moving can never aim again. The aim is the right-half finger only.

enum GS { INTRO, MENU, PLACE, BOSS, TUNNEL, OVER }

const MUSIC_MENU := "res://assets/audio/sfx/rw_music_menu.ogg"
const MUSIC_WAR := "res://assets/audio/sfx/rw_music_war.ogg"
const MUSIC_PRESS := "res://assets/audio/sfx/rw_music_press.ogg"
const MUSIC_BOSS := "res://assets/audio/sfx/rw_music_boss.ogg"

# the HTML prototype's THEME (dark gray metal, no rainbow)
const THEME := {
        "bg": Color(0.039, 0.043, 0.051, 0.94),
        "panel": Color(0.086, 0.094, 0.11, 0.95),
        "panel_hi": Color(0.133, 0.145, 0.169, 0.98),
        "border": Color(0.353, 0.373, 0.412, 0.55),
        "border_hi": Color(0.667, 0.698, 0.745, 0.95),
        "text": Color("d8dce2"),
        "dim": Color("848a94"),
        "mute": Color("565c66"),
        "cost": Color("c8a86a"),
        "cost_no": Color("8a5555"),
        "good": Color("7fa87f"),
        "bad": Color("b87070"),
        "accent": Color("9aa8b8"),
        "accent_hi": Color("e0e6ee"),
        "hp": Color("7ac088"),
        "hp_low": Color("c88860"),
        "hp_crit": Color("c06060"),
        "shield": Color("78b8d8"),
        "xp": Color("a8a0d8"),
        "scrap": Color("c8a86a"),
}

# ------------------------------------------------------------ live canvas
var W := 1920.0
var H := 1080.0
var GROUND_Y := 984.0

# ------------------------------------------------------------- run state
var state: int = GS.INTRO
var meta: HWMeta
var run := {}
var place_i := 0              # 0-based place index (the real counter)
var wave := 1
var loop := 1
var t_state := 0.0

# draw nodes (the whole war is code-drawn)
var world: Node2D
var sky_node: Polygon2D
var sun_node: Node2D
var env_draw: Node2D          # 3 silhouette planes + ground + decals
var ent_draw: Node2D          # enemies + bosses
var shot_draw: Node2D         # shots / eshots / rockets / drops
var tank_draw: Node2D         # the tank (wheels, hull, pods, MGs, turret)
var fx_draw: Node2D           # additive particles
var hud_draw: Control

# pools (dict entities; every pixel is drawn by the nodes above)
var enemies: Array = []
var shots: Array = []
var eshots: Array = []
var rockets: Array = []
var drops: Array = []
var fx: Array = []
var decals: Array = []
var boss_ent: Dictionary = {}
var laser_beams: Array = []   # the shadow lancers' live beams

# player numbers
var p_hp := 100.0
var p_hp_max := 100.0
var p_shield := 0.0
var p_scrap := 0              # scrap carried THIS run (banks at the end)
var p_xp := 0
var p_level := 1
var p_xp_next := 60
var p_x := 960.0
var p_aim := -PI / 2
var p_invuln := 0.0
var p_recoil := 0.0
var p_wheel_spin := 0.0
var mg_flash := 0.0
var rk_flash := 0.0
var buffs := {}
var level_up_queue := 0

# weapons cadence
var cd_main := 0.0
var cd_mg := 0.0
var cd_rk := 0.0

# wave director (v040-8 THE WAVE LAW: each wave rolls its own kind -
# "kills" ends on the kill quota, "time" ends on the clock, "both" needs
# BOTH; the clocks grow as the waves climb)
var wave_state := "idle"       # idle/spawning/clearing/boss
var wave_kind := "kills"
var wave_quota := 0            # the kills the wave demands
var wave_quota_done := 0
var wave_duration := 60.0      # the time-limited waves' clock
var drip_t := 0.0              # the time-kind's steady pour clock
var spawn_list: Array = []
var spawn_t := 0.0
var wave_clock := 0.0
var overbudget := 0
var banner := ""
var banner_t := 0.0
var shake := 0.0
var flash := 0.0
var damage_flash := 0.0

# the coin law (v040-6: the kill count is the whole law - no timer)
var coin_kills := 0

# input (the hopper law: roles at touchdown, kept until lift)
var move_ptr := -1
var move_anchor := 0.0
var move_force := 0.0
var _kb_dir := 0   # THE PC LAW: the arrows' own steering lane (the windows return)
var aim_ptr := -1
var aim_pos := Vector2(960.0, 400.0)
var mouse_aim := false
var touch_ui := false          # a real touch screen: the emulated mouse is dead

# parallax scroll
var scroll_x := 0.0

# v040-8: the top-bar scrap chip's label + the tank scale law
var scrap_lbl: Label = null
const TANK_S := 0.34          # THE TANK SCALE: everything about the tank
                              # is drawn 1/3 (the owner: "scale it down by
                              # 3 times will make it good")

func _goga_setup() -> void:
        ScaleRule.apply(get_window())
        var vp := get_viewport_rect().size
        W = maxf(960.0, vp.x)
        H = maxf(540.0, vp.y)
        GROUND_Y = H - HWData.GROUND_H
        meta = HWMeta.load_meta()
        game_id = "heavywar"
        pause_end_run = false
        # THE CONTROLS LAW: on a touch device Godot ALSO delivers emulated
        # mouse events for the first finger - the v040-5 bug where MOVING
        # (a left-half finger) also steered the aim came from exactly that.
        # A touch screen never reads the mouse again; desktop rigs keep it.
        touch_ui = DisplayServer.is_touchscreen_available() \
                or OS.has_feature("mobile") or OS.has_feature("android")
        set_score(0)
        _run_reset()
        _build_world()
        _build_hw_hud()
        # v040-8 THE SHOP SEAT LAW: the GOGABox SHOP is an IN-GAME top-bar
        # button (top left, the usual seat) - it left the main menu (the
        # menu is DEPLOY + SCRAP SHOP only).
        add_hud_button("SHOP", func(): _box_shop_open())
        # THE SCRAP WIDGET (the pop siege law): a chip in the TOP BAR next
        # to the score/coins widgets - the bottom-left canvas widget is dead.
        scrap_lbl = add_hud_chip("0")
        _scrap_icon_in_chip()
        # THE SCORE ICON LAW: the warbird rides INSIDE the box score chip
        # (the pop siege icon law) - the separate kills panel is dead.
        _score_icon_in_chip()
        _enter_intro()

# =================================================================
# THE RUN LEDGER
# =================================================================
func _run_reset() -> void:
        place_i = 0
        wave = 1
        loop = 1
        run = {"places_done": 0, "bosses_met": 0, "bosses_killed": 0}
        p_hp_max = 100.0 + _shop_lvl("armor") * 20
        p_hp = p_hp_max
        p_shield = 0.0
        p_scrap = 0
        p_xp = 0
        p_level = 1
        p_xp_next = 60
        p_x = W / 2.0
        p_aim = -PI / 2
        p_invuln = 0.0
        p_recoil = 0.0
        mg_flash = 0.0
        rk_flash = 0.0
        buffs = {"dmg": 0.0, "rate": 0.0, "speed": 0.0, "pierce": 0,
                "explosive": 0, "lifesteal": 0.0, "multi": 0, "dr": 0.0,
                "cd": 1.0, "crit": 0.0, "bounce": 0, "slow": 0.0}
        level_up_queue = 0
        coin_kills = 0
        wave_state = "idle"
        spawn_list = []
        enemies = []
        shots = []
        eshots = []
        rockets = []
        drops = []
        fx = []
        decals = []
        laser_beams = []
        boss_ent = {}
        shake = 0.0
        flash = 0.0
        damage_flash = 0.0

# ------------------------------------------------------- the scrap shop math
func _shop_lvl(id: String) -> int:
        return meta.upg_lvl(id)

## the machine guns per side: 0 until bought, then 1 + rack levels
func _mg_lvl() -> int:
        return 0 if _shop_lvl("mg") <= 0 else 1 + _shop_lvl("mg_rack")

## the rocket pods per side: 0 until bought, then 1 + rack levels
func _rk_lvl() -> int:
        return 0 if _shop_lvl("rockets") <= 0 else 1 + _shop_lvl("rocket_rack")

## the total shop power the enemy scaling reads (every level bought)
func _shop_spent() -> int:
        var n := 0
        for it in HWData.SHOP_ITEMS:
                n += _shop_lvl(String(it["id"]))
        return n

func _diff() -> float:
        return HWData.diff(place_i, p_level, loop, _shop_spent())

# =================================================================
# THE WORLD - sky gradient, sun, 3 code-drawn silhouette planes,
# a code-drawn ground band. Windows sit in strict grids, never overlapped.
# =================================================================
func _build_world() -> void:
        world = Node2D.new()
        add_child(world)
        _sky_node()
        env_draw = Node2D.new()
        env_draw.draw.connect(_draw_env)
        world.add_child(env_draw)
        ent_draw = Node2D.new()
        ent_draw.draw.connect(_draw_enemies)
        world.add_child(ent_draw)
        shot_draw = Node2D.new()
        shot_draw.draw.connect(_draw_shots)
        world.add_child(shot_draw)
        tank_draw = Node2D.new()
        tank_draw.draw.connect(_draw_tank)
        tank_draw.z_index = 50
        world.add_child(tank_draw)
        var fx_mat := CanvasItemMaterial.new()
        fx_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        fx_draw = Node2D.new()
        fx_draw.material = fx_mat
        fx_draw.draw.connect(_draw_fx)
        fx_draw.z_index = 60
        world.add_child(fx_draw)

func _sky_node() -> void:
        var pl: Dictionary = HWData.PLACES[place_i % 10]
        if sky_node != null and is_instance_valid(sky_node):
                sky_node.queue_free()
                sun_node.queue_free()
        sky_node = Polygon2D.new()
        sky_node.polygon = PackedVector2Array([Vector2(-40, -40),
                Vector2(W + 40, -40), Vector2(W + 40, GROUND_Y + 40),
                Vector2(-40, GROUND_Y + 40)])
        sky_node.vertex_colors = PackedColorArray([pl["sky_top"],
                pl["sky_top"], pl["sky_bot"], pl["sky_bot"]])
        world.add_child(sky_node)
        world.move_child(sky_node, 0)
        sun_node = Node2D.new()
        sun_node.draw.connect(_draw_sun_moon)
        sun_node.draw.connect(_draw_stars)
        sun_node.draw.connect(_draw_clouds)
        world.add_child(sun_node)
        world.move_child(sun_node, 1)

## THE SKY LAW (v040-6): a real celestial body - the bright places get a
## layered sun with soft rays, the dark places a crescent moon. No more
## flat circles.
func _draw_sun_moon() -> void:
        var pl: Dictionary = HWData.PLACES[place_i % 10]
        var c: Vector2 = Vector2(W * 0.76, GROUND_Y * 0.26)
        var sun: Color = pl["sun"]
        if bool(pl.get("moon", false)):
                # THE MOON: a pale disc with a crescent bite + a cold halo
                var moon := Color(0.86, 0.9, 0.98)
                sun_node.draw_circle(c, 150.0, Color(moon, 0.05))
                sun_node.draw_circle(c, 96.0, Color(moon, 0.10))
                sun_node.draw_circle(c, 52.0, Color(moon, 0.34))
                sun_node.draw_circle(c, 34.0, Color(moon, 0.92))
                var bite := c + Vector2(14, -9)
                sun_node.draw_circle(bite, 29.0, Color(pl["sky_top"], 0.94))
                sun_node.draw_circle(c + Vector2(-10, 8), 5.0,
                        Color(moon, 0.30))
                sun_node.draw_circle(c + Vector2(6, 16), 3.4,
                        Color(moon, 0.24))
        else:
                # THE SUN: halo, corona, soft rotating rays, the core
                var t := t_state * 0.05
                for r in 3:
                        sun_node.draw_circle(c, 240.0 - float(r) * 58.0,
                                Color(sun, 0.08))
                for i in 12:
                        var a := t + TAU * float(i) / 12.0
                        var l0 := c + Vector2.from_angle(a) * 84.0
                        var l1 := c + Vector2.from_angle(a) * (128.0
                                + 14.0 * sin(t_state * 1.4 + float(i)))
                        sun_node.draw_line(l0, l1, Color(sun, 0.16), 7.0,
                                true)
                sun_node.draw_circle(c, 74.0, Color(sun, 0.30))
                sun_node.draw_circle(c, 48.0, Color(sun, 0.62))
                sun_node.draw_circle(c, 34.0, Color(sun, 0.96))
                sun_node.draw_circle(c + Vector2(-7, -7), 22.0,
                        Color(1, 1, 1, 0.20))

## THE STAR FIELD: the dark places carry a twinkling field (deterministic,
## two depths, never scrolled away - the sky is a dome).
func _draw_stars() -> void:
        var pl: Dictionary = HWData.PLACES[place_i % 10]
        if not bool(pl.get("stars", false)):
                return
        for i in 64:
                var sx := fposmod(float(i) * 173.13, W + 40.0) - 20.0
                var sy := fposmod(float(i) * 311.7, GROUND_Y * 0.82)
                var tw := 0.35 + 0.30 * sin(t_state * (1.2 + fposmod(
                        float(i) * 7.3, 2.2)) + float(i))
                var sr := 1.4 + fposmod(float(i) * 5.1, 1.6)
                sun_node.draw_circle(Vector2(sx, sy), sr,
                        Color(1, 1, 1, tw * 0.8))
        # one slow shooting star every ~9s (a moment, not a fountain)
        var cyc := fposmod(t_state, 9.0)
        if cyc < 0.9:
                var k := cyc / 0.9
                var p0 := Vector2(W * 0.18 + float(int(t_state / 9.0) % 5)
                        * 60.0, GROUND_Y * 0.14)
                var tail := Vector2(90, 34)
                sun_node.draw_line(p0 + tail * k, p0 + tail * k - tail * 0.3,
                        Color(1, 1, 1, 0.5 * (1.0 - k)), 2.0, true)

## THE CLOUD LAW: soft drifting banks - two depths, puffy circle clusters,
## tinted by the place. They ride the far parallax and TILE forever.
func _draw_clouds() -> void:
        var pl: Dictionary = HWData.PLACES[place_i % 10]
        var cc: Color = pl.get("clouds", Color(1, 1, 1))
        var periods := [860.0, 1180.0]
        var speeds := [0.07, 0.12]
        for li in 2:
                var period: float = periods[li]
                # v040-11 THE SHAPE ANCHOR LAW: the seed rides the ABSOLUTE
                # world slot, never the wrapped loop slot - the old re-key at
                # every wrap made every cloud morph into its neighbor and
                # back (the owner's "uncanny as hell").
                var base_off: float = scroll_x * float(speeds[li])
                var off := fposmod(base_off, period)
                var k_abs0 := int(floor(base_off / period))
                var k := 0
                var x := -off
                while x < W + period:
                        var kk := k + k_abs0
                        var hy := 60.0 + hpos(kk * 3 + li * 17) * 180.0
                        var cw := 90.0 + hpos(kk + li * 7) * 120.0
                        var a := 0.16 + 0.08 * hpos(kk * 5 + li)
                        _cloud_puff(Vector2(x, hy), cw, Color(cc, a))
                        x += period
                        k += 1

func _cloud_puff(c: Vector2, wdt: float, col: Color) -> void:
        var puffs := [
                [Vector2(0, 0), 0.52], [Vector2(-wdt * 0.42, wdt * 0.10), 0.36],
                [Vector2(wdt * 0.40, wdt * 0.08), 0.38],
                [Vector2(wdt * 0.16, -wdt * 0.16), 0.34],
                [Vector2(-wdt * 0.14, -wdt * 0.12), 0.30],
        ]
        for pf in puffs:
                sun_node.draw_circle(c + (pf[0] as Vector2), wdt * float(pf[1]),
                        col)

## the parallax silhouettes. layer 0 = far, 1 = mid, 2 = near.
## every shape is seeded so the plane TILES: k-th shape rides at
## x = k*period - off (the v040-3 leaf law - the world never runs out).
func _draw_env() -> void:
        var pl: Dictionary = HWData.PLACES[place_i % 10]
        var planes := [
                {"spd": HWData.PLANE_FAR, "period": 460.0, "base": Color(pl["sky_bot"], 0.42)},
                {"spd": HWData.PLANE_MID, "period": 560.0, "base": Color(pl["sky_bot"], 0.66)},
                {"spd": HWData.PLANE_NEAR, "period": 700.0, "base": Color(pl["sky_bot"], 0.92)},
        ]
        # distant haze band above the ground
        env_draw.draw_rect(Rect2(-40, GROUND_Y - 190, W + 80, 190),
                Color(pl["sky_bot"], 0.30))
        for li in planes.size():
                var plane: Dictionary = planes[li]
                # v040-11 THE SHAPE ANCHOR LAW: the seed rides the ABSOLUTE
                # world slot - when off wraps a period, the loop slots re-key
                # but the world slots do not, so every silhouette keeps its
                # shape while it slides (the shape-shifting props are dead).
                var base_off := scroll_x * float(plane["spd"])
                var off := fposmod(base_off, float(plane["period"]))
                var k_abs0 := int(floor(base_off / float(plane["period"])))
                var k := 0
                var x := -off
                while x < W + float(plane["period"]):
                        _env_shape(String(pl["key"]), li, k + k_abs0, x,
                                plane["base"])
                        x += float(plane["period"])
                        k += 1
        _draw_ground(pl)
        _draw_decals()

func _env_shape(key: String, li: int, k: int, x: float, base: Color) -> void:
        # deterministic per (key, layer, ABSOLUTE world slot - v040-11)
        var edge := base.darkened(0.25)
        var lit := base.lightened(0.12)
        match key:
                "iron":
                        _factory(li, k, x, base, edge, lit)
                "mesa":
                        _mesa(li, k, x, base, edge, lit)
                "tundra":
                        _iceberg(li, k, x, base, edge, lit)
                "volcano":
                        _volcano(li, k, x, base, edge, lit)
                "swamp":
                        _swamp_tree(li, k, x, base, edge, lit)
                "crystal":
                        _crystal(li, k, x, base, edge, lit)
                "sky":
                        _sky_island(li, k, x, base, edge, lit)
                "trench":
                        _trench_rock(li, k, x, base, edge, lit)
                "neon":
                        _neon_tower(li, k, x, base, edge, lit)
                "void":
                        _void_shard(li, k, x, base, edge, lit)

## a building silhouette with a STRICT window grid (rows never overlap -
## the window pitch is derived from the building height, the owner's fix)
func _building(x: float, w: float, hgt: float, base: Color, edge: Color,
                rows: int, cols: int, win_col: Color) -> void:
        var top := GROUND_Y - hgt
        env_draw.draw_rect(Rect2(x - w * 0.5, top, w, hgt), base)
        env_draw.draw_rect(Rect2(x - w * 0.5, top, w, 4), edge)
        var m := 10.0
        var gw := (w - m * 2.0) / maxf(1.0, float(cols))
        var gh := (hgt - m * 2.0 - 14.0) / maxf(1.0, float(rows))
        var ww := gw * 0.5
        var wh := minf(gh * 0.5, 9.0)
        for r in rows:
                for c in cols:
                        if fposmod(float(r * 7 + c * 13 + int(w)), 10.0) < 3.5:
                                continue   # some windows are dark
                        var wx := x - w * 0.5 + m + float(c) * gw + (gw - ww) * 0.5
                        var wy := top + m + float(r) * gh + (gh - wh) * 0.5
                        env_draw.draw_rect(Rect2(wx, wy, ww, wh), win_col)

func _factory(li: int, k: int, x: float, base: Color, edge: Color,
                _lit: Color) -> void:
        var scale := 0.45 + 0.28 * float(li)
        var hgt := (110.0 + hpos(k) * 90.0) * scale
        var w := (150.0 + hpos(k + 5) * 70.0) * scale
        _building(x, w, hgt, base, edge, 3 + li, 3 + (k % 3), Color(1, 1, 1, 0.10))
        # stacks
        var sw := 18.0 * scale
        env_draw.draw_rect(Rect2(x + w * 0.22, GROUND_Y - hgt - 70.0 * scale,
                sw, 70.0 * scale), base)
        env_draw.draw_rect(Rect2(x + w * 0.22 - 4.0, GROUND_Y - hgt - 78.0 * scale,
                sw + 8.0, 10.0), edge)

func _mesa(li: int, k: int, x: float, base: Color, edge: Color,
                _lit: Color) -> void:
        var scale := 0.45 + 0.28 * float(li)
        var hgt := (80.0 + hpos(k) * 90.0) * scale
        var w := (240.0 + hpos(k + 3) * 90.0) * scale
        var top := GROUND_Y - hgt
        var pts := PackedVector2Array([
                Vector2(x - w * 0.5, GROUND_Y),
                Vector2(x - w * 0.30, top + hgt * 0.30),
                Vector2(x - w * 0.16, top),
                Vector2(x + w * 0.16, top),
                Vector2(x + w * 0.32, top + hgt * 0.26),
                Vector2(x + w * 0.5, GROUND_Y),
        ])
        env_draw.draw_colored_polygon(pts, base)
        env_draw.draw_colored_polygon(PackedVector2Array([
                Vector2(x - w * 0.30, top + hgt * 0.30),
                Vector2(x - w * 0.16, top),
                Vector2(x + w * 0.16, top),
                Vector2(x + w * 0.05, top + hgt * 0.34),
        ]), edge)

func _iceberg(li: int, k: int, x: float, base: Color, _edge: Color,
                lit: Color) -> void:
        var scale := 0.45 + 0.28 * float(li)
        var hgt := (90.0 + hpos(k) * 100.0) * scale
        var w := (150.0 + hpos(k + 2) * 80.0) * scale
        var top := GROUND_Y - hgt
        env_draw.draw_colored_polygon(PackedVector2Array([
                Vector2(x - w * 0.5, GROUND_Y), Vector2(x - w * 0.22, top),
                Vector2(x + w * 0.1, top + hgt * 0.18),
                Vector2(x + w * 0.5, GROUND_Y),
        ]), base)
        env_draw.draw_colored_polygon(PackedVector2Array([
                Vector2(x - w * 0.22, top), Vector2(x + w * 0.1, top + hgt * 0.18),
                Vector2(x - w * 0.04, top + hgt * 0.34),
        ]), lit)

func _volcano(li: int, k: int, x: float, base: Color, edge: Color,
                _lit: Color) -> void:
        var scale := 0.45 + 0.28 * float(li)
        var hgt := (110.0 + hpos(k) * 80.0) * scale
        var w := (260.0 + hpos(k + 4) * 80.0) * scale
        var top := GROUND_Y - hgt
        env_draw.draw_colored_polygon(PackedVector2Array([
                Vector2(x - w * 0.5, GROUND_Y), Vector2(x - w * 0.10, top),
                Vector2(x + w * 0.10, top), Vector2(x + w * 0.5, GROUND_Y),
        ]), base)
        # the lava throat + glow
        env_draw.draw_colored_polygon(PackedVector2Array([
                Vector2(x - w * 0.10, top), Vector2(x + w * 0.10, top),
                Vector2(x + w * 0.05, top + 60.0 * scale),
                Vector2(x - w * 0.05, top + 60.0 * scale),
        ]), Color(1.0, 0.35, 0.08, 0.8))
        env_draw.draw_circle(Vector2(x, top + 8.0), 50.0 * scale,
                Color(1.0, 0.4, 0.1, 0.10))

func _swamp_tree(li: int, k: int, x: float, base: Color, edge: Color,
                _lit: Color) -> void:
        var scale := 0.5 + 0.3 * float(li)
        var hgt := (130.0 + hpos(k) * 70.0) * scale
        env_draw.draw_line(Vector2(x, GROUND_Y), Vector2(x, GROUND_Y - hgt),
                base, 9.0 * scale)
        env_draw.draw_line(Vector2(x, GROUND_Y - hgt * 0.62),
                Vector2(x - 34.0 * scale, GROUND_Y - hgt * 0.86), base, 6.0 * scale)
        env_draw.draw_line(Vector2(x, GROUND_Y - hgt * 0.74),
                Vector2(x + 40.0 * scale, GROUND_Y - hgt * 0.95), base, 6.0 * scale)
        env_draw.draw_circle(Vector2(x + 40.0 * scale, GROUND_Y - hgt * 0.95),
                16.0 * scale, edge)

func _crystal(li: int, k: int, x: float, base: Color, edge: Color,
                lit: Color) -> void:
        var scale := 0.45 + 0.28 * float(li)
        var hgt := (90.0 + hpos(k) * 110.0) * scale
        var w := (46.0 + hpos(k + 6) * 30.0) * scale
        var top := GROUND_Y - hgt
        env_draw.draw_colored_polygon(PackedVector2Array([
                Vector2(x - w * 0.5, GROUND_Y), Vector2(x - w * 0.22, top + hgt * 0.2),
                Vector2(x, top), Vector2(x + w * 0.26, top + hgt * 0.26),
                Vector2(x + w * 0.5, GROUND_Y),
        ]), base)
        env_draw.draw_colored_polygon(PackedVector2Array([
                Vector2(x - w * 0.22, top + hgt * 0.2), Vector2(x, top),
                Vector2(x + w * 0.05, top + hgt * 0.4),
        ]), lit)
        env_draw.draw_circle(Vector2(x, top + hgt * 0.3), w * 0.9,
                Color(pl_accent(), 0.06))

func _sky_island(li: int, k: int, x: float, base: Color, edge: Color,
                lit: Color) -> void:
        var scale := 0.45 + 0.28 * float(li)
        var w := (180.0 + hpos(k) * 90.0) * scale
        var y := GROUND_Y - (120.0 + hpos(k + 2) * 130.0) * scale
        env_draw.draw_colored_polygon(PackedVector2Array([
                Vector2(x - w * 0.5, y), Vector2(x + w * 0.5, y),
                Vector2(x + w * 0.3, y + 26.0 * scale),
                Vector2(x - w * 0.1, y + 40.0 * scale),
                Vector2(x - w * 0.34, y + 22.0 * scale),
        ]), base)
        env_draw.draw_rect(Rect2(x - w * 0.5, y - 12.0 * scale, w, 12.0 * scale), lit)
        env_draw.draw_colored_polygon(PackedVector2Array([
                Vector2(x - w * 0.34, y + 22.0 * scale),
                Vector2(x - w * 0.1, y + 40.0 * scale),
                Vector2(x - w * 0.22, y + 58.0 * scale),
        ]), edge)

func _trench_rock(li: int, k: int, x: float, base: Color, edge: Color,
                _lit: Color) -> void:
        var scale := 0.5 + 0.3 * float(li)
        var hgt := (90.0 + hpos(k) * 110.0) * scale
        env_draw.draw_colored_polygon(PackedVector2Array([
                Vector2(x - 70.0 * scale, GROUND_Y),
                Vector2(x - 30.0 * scale, GROUND_Y - hgt * 0.7),
                Vector2(x + 14.0 * scale, GROUND_Y - hgt),
                Vector2(x + 50.0 * scale, GROUND_Y - hgt * 0.4),
                Vector2(x + 80.0 * scale, GROUND_Y),
        ]), base)
        env_draw.draw_circle(Vector2(x + 10.0 * scale, GROUND_Y - hgt - 8.0),
                7.0 * scale, Color(pl_accent(), 0.5))

func _neon_tower(li: int, k: int, x: float, base: Color, edge: Color,
                _lit: Color) -> void:
        var scale := 0.45 + 0.28 * float(li)
        var hgt := (140.0 + hpos(k) * 120.0) * scale
        var w := (90.0 + hpos(k + 5) * 50.0) * scale
        _building(x, w, hgt, base, edge, 5 + li, 2 + (k % 2), Color(pl_accent(), 0.28))
        env_draw.draw_line(Vector2(x, GROUND_Y - hgt),
                Vector2(x, GROUND_Y - hgt - 30.0 * scale), edge, 4.0)
        env_draw.draw_circle(Vector2(x, GROUND_Y - hgt - 34.0 * scale),
                5.0 * scale, Color(pl_accent(), 0.8))

func _void_shard(li: int, k: int, x: float, base: Color, _edge: Color,
                lit: Color) -> void:
        var scale := 0.45 + 0.28 * float(li)
        var hgt := (100.0 + hpos(k) * 110.0) * scale
        var y := GROUND_Y
        var w := (40.0 + hpos(k + 3) * 30.0) * scale
        var wob := sin(scroll_x * 0.004 + float(k) * 1.7) * 8.0
        env_draw.draw_colored_polygon(PackedVector2Array([
                Vector2(x - w, y), Vector2(x - w * 0.3, y - hgt * 0.6 + wob),
                Vector2(x, y - hgt + wob), Vector2(x + w * 0.4, y - hgt * 0.5 - wob),
                Vector2(x + w, y),
        ]), base)
        env_draw.draw_circle(Vector2(x, y - hgt * 0.55 + wob), w * 0.5,
                Color(pl_accent(), 0.16))
        env_draw.draw_colored_polygon(PackedVector2Array([
                Vector2(x - w * 0.3, y - hgt * 0.6 + wob), Vector2(x, y - hgt + wob),
                Vector2(x + w * 0.05, y - hgt * 0.62 + wob),
        ]), lit)

func hpos(k: int) -> float:
        return fposmod(sin(float(k) * 12.9898) * 43758.5453, 1.0)

func pl_accent() -> Color:
        return HWData.PLACES[place_i % 10]["accent"]

func _draw_ground(pl: Dictionary) -> void:
        # the road band: face + darker body + the accent edge + speckle
        env_draw.draw_rect(Rect2(-40, GROUND_Y, W + 80, H - GROUND_Y + 40),
                pl["ground"])
        env_draw.draw_rect(Rect2(-40, GROUND_Y, W + 80, 7), pl["ground_top"])
        env_draw.draw_rect(Rect2(-40, GROUND_Y + 7, W + 80, 3),
                Color(pl["ground_top"], 0.4))
        # lane dashes ride the scroll
        var step := 240.0
        var off := fposmod(scroll_x, step)
        var x := -off
        while x < W + step:
                env_draw.draw_rect(Rect2(x, GROUND_Y + 52, 110, 7),
                        Color(1, 1, 1, 0.10))
                x += step
        # speckle texture (deterministic)
        for i in 90:
                var sx := fposmod(float(i) * 137.51 - scroll_x * 0.9, W + 60.0) - 30.0
                var sy := GROUND_Y + 14.0 + fposmod(float(i) * 71.3,
                        H - GROUND_Y - 18.0)
                env_draw.draw_rect(Rect2(sx, sy, 3.0 + float(i % 3) * 2.0,
                        2.0 + float(i % 2)), Color(0, 0, 0, 0.20))

func _draw_decals() -> void:
        for d in decals:
                var dd: Dictionary = d
                var a: float = clampf(1.0 - float(dd["t"]) / 14.0, 0.0, 1.0) * 0.5
                env_draw.draw_circle(Vector2(float(dd["x"]), GROUND_Y - 3.0),
                        float(dd["r"]), Color(0, 0, 0, a))

# =================================================================
# THE TANK - code-drawn layered steel, the owner's own layout:
#   wheels (3 + shop, SPINNING, always visible) -> bottom hull ->
#   ROCKET PODS on the OUTER hull edges -> mid hull -> MG BARRELS on the
#   shoulders (UP ONLY) -> top hull -> turret base -> a TALL turret tower
#   -> the main cannon (the ONLY thing that follows the aim). The cannon
#   pivot rides ABOVE the MG barrels: a 180-degree swing never overlaps.
# =================================================================
func _skin() -> Dictionary:
        var sid := Box.skin_on(game_id)
        if sid == "" or not HWData.SKIN_COLORS.has(sid):
                sid = "olive"
        return HWData.SKIN_COLORS[sid]

func _apply_skin() -> void:
        if tank_draw != null and is_instance_valid(tank_draw):
                tank_draw.queue_redraw()

func _wheel_xs() -> Array:
        var total := 3 + _shop_lvl("wheels")     # 3..8
        var span := 340.0
        var out := []
        for i in total:
                var t := 0.5 if total == 1 else float(i) / float(total - 1)
                out.append(-span * 0.5 + t * span)
        return out

## THE POD LAW (v040-6, the owner's drawing): the rockets live IN the
## BOTTOM layer - the launch cells sit on the bottom slab's face, one
## cluster per side, 1..4 per side.
func _pod_xs() -> Array:
        var n := _rk_lvl()
        var out := []
        for i in n:
                var offx := 112.0 + float(i) * 21.0
                out.append(-offx)
                out.append(offx)
        return out

## THE MG LAW: the machine guns ride the UPPER layer's shoulders (the
## upper layer is the SMALL one), inboard of the bottom layer's pods.
func _mg_xs() -> Array:
        var n := _mg_lvl()
        var out := []
        for i in n:
                var offx := 56.0 + float(i) * 15.0
                out.append(-offx)
                out.append(offx)
        return out

func _tank_origin() -> Vector2:
        return Vector2(p_x, GROUND_Y)

func _tank_blink() -> bool:
        return p_invuln > 0.0 and fmod(p_invuln, 0.066) > 0.033

func _draw_tank() -> void:
        if state == GS.OVER:
                return
        var sk: Dictionary = _skin()
        var edge: Color = sk["edge"]
        var lo: Color = sk["lo"]
        var mid: Color = sk["mid"]
        var hi: Color = sk["hi"]
        var band: Color = sk["band"]
        var blink := _tank_blink()
        var alpha := 0.45 if blink else 1.0
        tank_draw.modulate = Color(1, 1, 1, alpha)
        # v040-8 THE TANK SCALE: the whole machine draws through a 1/3
        # transform in LOCAL coordinates - every proportion survives, the
        # size obeys the owner's law
        var org := _tank_origin()
        tank_draw.draw_set_transform(org + Vector2(0, -4.0 * TANK_S), 0.0,
                Vector2(TANK_S, TANK_S * 0.2))
        tank_draw.draw_circle(Vector2(0, 0), 200.0,
                Color(0, 0, 0, 0.34 * alpha))
        tank_draw.draw_set_transform(org, 0.0, Vector2(TANK_S, TANK_S))
        var o := Vector2.ZERO

        # ---------- WHEELS (big, visible, spinning) ----------
        for wx in _wheel_xs():
                var wc := o + Vector2(float(wx), -22.0)
                tank_draw.draw_circle(wc, 28.0, edge)
                tank_draw.draw_circle(wc, 24.0, mid)
                tank_draw.draw_circle(wc, 14.0, lo)
                tank_draw.draw_circle(wc, 8.0, hi)
                for spk in 4:
                        var a := p_wheel_spin + float(spk) * TAU / 4.0
                        tank_draw.draw_line(wc,
                                wc + Vector2(cos(a), sin(a)) * 20.0, hi, 2.8)
                tank_draw.draw_circle(wc - Vector2(1.5, 1.5), 2.6, hi)

        # ---------- GROUND LAYER (the WIDE one - it fits every wheel) ----------
        _steel_slab(o, Rect2(-192, -78, 384, 36), lo, lo.darkened(0.3), edge, band, 9)
        # ---------- BOTTOM LAYER (SAME width - the rockets live IN it) ----------
        _steel_slab(o, Rect2(-192, -134, 384, 56), mid, lo, edge, band, 9)
        tank_draw.draw_rect(Rect2(o.x - 186, o.y - 114, 372, 4), Color(band, 0.45))
        # the rocket cells: armoured launcher boxes sunk into the slab face
        for i in _pod_xs().size():
                var px: float = float(_pod_xs()[i])
                _rocket_pod(o + Vector2(px, -106), -0.06 if px < 0.0 else 0.06,
                        rk_flash)
        # ---------- UPPER LAYER (the SMALL deck - the MGs' floor) ----------
        _steel_slab(o, Rect2(-122, -172, 244, 38), mid, lo.darkened(0.15), edge, band, 6)
        # ---------- MG BARRELS (shoulders, UP ONLY) ----------
        for i in _mg_xs().size():
                var mx: float = float(_mg_xs()[i])
                _mg_barrel(o + Vector2(mx, -172), -0.07 if mx < 0.0 else 0.07,
                        mg_flash)
        # ---------- TURRET BASE (seated ON the deck, no gap) ----------
        _trap(o + Vector2(0, -170), o + Vector2(0, -200), 116.0, 96.0, lo, edge)
        # ---------- TURRET TOWER (tall, tapered, banded) ----------
        var tw0 := o + Vector2(0, -200)
        var tw1 := o + Vector2(0, -310)
        _trap(tw0, tw1, 94.0, 66.0, mid, edge)
        for by in [226.0, 256.0, 284.0]:
                var wdt: float = 94.0 - (float(by) - 200.0) * 0.26
                tank_draw.draw_rect(Rect2(o.x - wdt * 0.5, o.y - by - 3.0, wdt, 5.0), edge)
        tank_draw.draw_rect(Rect2(o.x - 31.0, o.y - 308.0, 62.0, 3.0),
                Color(band, 0.55))
        # view slits on the tower + a commander's hatch light
        tank_draw.draw_rect(Rect2(o.x - 19.0, o.y - 246.0, 38.0, 6.0), Color(0.04, 0.05, 0.07))
        tank_draw.draw_circle(o + Vector2(0, -304), 9.0, Color(band, 0.7))
        # ---------- MAIN CANNON (the aim follower, from the tower top) ----------
        var pivot := o + Vector2(0, -284)
        _main_cannon(pivot, p_aim, sk)
        # ---------- SHIELD BUBBLE ----------
        if p_shield > 0.0:
                var pulse := 0.55 + sin(t_state * 9.0) * 0.14
                var sc := o + Vector2(0, -178)
                tank_draw.draw_circle(sc, 235.0,
                        Color(THEME["shield"], 0.10 * pulse))
                tank_draw.draw_arc(sc, 235.0, 0, TAU, 48,
                        Color(THEME["shield"], 0.55 * pulse), 3.0)
        tank_draw.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _steel_slab(o: Vector2, r: Rect2, top_c: Color, bot_c: Color,
                edge: Color, band: Color, rivets: int) -> void:
        # a steel slab: vertical gradient (two stacked polys), edge, rivets
        # r is TANK-LOCAL; o is the tank origin (world)
        r.position += o
        var half := r.position.y + r.size.y * 0.5
        var top_pts := PackedVector2Array([
                Vector2(r.position.x, r.position.y),
                Vector2(r.position.x + r.size.x, r.position.y),
                Vector2(r.position.x + r.size.x, half),
                Vector2(r.position.x, half)])
        var bot_pts := PackedVector2Array([
                Vector2(r.position.x, half),
                Vector2(r.position.x + r.size.x, half),
                Vector2(r.position.x + r.size.x, r.position.y + r.size.y),
                Vector2(r.position.x, r.position.y + r.size.y)])
        tank_draw.draw_colored_polygon(top_pts, top_c)
        tank_draw.draw_colored_polygon(bot_pts, bot_c)
        tank_draw.draw_rect(r, edge, false, 2.4)
        tank_draw.draw_rect(Rect2(r.position.x + 3, r.position.y + 2,
                r.size.x - 6, 2.0), Color(band, 0.5))
        for i in rivets:
                var rx := r.position.x + r.size.x * (float(i) + 0.5) / float(rivets)
                tank_draw.draw_circle(Vector2(rx, r.position.y + r.size.y * 0.5),
                        2.2, Color(edge, 0.9))

func _trap(p0: Vector2, p1: Vector2, w0: float, w1: float, col: Color,
                edge: Color) -> void:
        var pts := PackedVector2Array([
                Vector2(p0.x - w0 * 0.5, p0.y), Vector2(p0.x + w0 * 0.5, p0.y),
                Vector2(p1.x + w1 * 0.5, p1.y), Vector2(p1.x - w1 * 0.5, p1.y)])
        tank_draw.draw_colored_polygon(pts, col)
        tank_draw.draw_polyline(pts + PackedVector2Array([pts[0]]), edge, 2.4)

func _rocket_pod(at: Vector2, splay: float, flash_v: float) -> void:
        # a launch CELL sunk into the bottom slab: an armoured box with two
        # tube mouths and a rocket nose peeking out, aimed up-and-out
        var sk: Dictionary = _skin()
        tank_draw.draw_rect(Rect2(at.x - 15.0, at.y - 26.0, 30.0, 40.0),
                sk["edge"])   # the cell housing
        tank_draw.draw_rect(Rect2(at.x - 12.0, at.y - 23.0, 24.0, 34.0),
                sk["lo"])
        var up := Vector2(sin(splay), -1.0).normalized()
        for tcol in 2:
                var mouth := at + Vector2(-5.5 + float(tcol) * 11.0, -20.0)
                tank_draw.draw_circle(mouth, 4.6, Color(0.03, 0.03, 0.05))
                tank_draw.draw_circle(mouth + up * 1.4, 3.4, sk["mid"])
                # the rocket's red nose resting in the tube
                tank_draw.draw_circle(mouth + up * 3.4, 2.2, Color("a03030"))
        var tip := at + up * 26.0
        if flash_v > 0.15:
                tank_draw.draw_circle(tip, 12.0 + flash_v * 10.0,
                        Color(1.0, 0.72, 0.32, flash_v * 0.75))

func _mg_barrel(at: Vector2, splay: float, flash_v: float) -> void:
        # a machine gun: cooling rings, open muzzle, UP ONLY
        var up := Vector2(sin(splay), -1.0).normalized()
        tank_draw.draw_line(at, at + up * 40.0, _skin()["edge"], 12.0)
        tank_draw.draw_line(at, at + up * 40.0, _skin()["hi"], 7.0)
        for rgl in 4:
                tank_draw.draw_line(at + up * (7.0 + float(rgl) * 7.0) + Vector2(-4, 0),
                        at + up * (7.0 + float(rgl) * 7.0) + Vector2(4, 0),
                        _skin()["edge"], 1.6)
        tank_draw.draw_circle(at + up * 40.0, 3.6, Color(0, 0, 0, 0.9))
        if flash_v > 0.15:
                tank_draw.draw_circle(at + up * 44.0, 5.0 + flash_v * 6.0,
                        Color(1.0, 0.86, 0.55, flash_v * 0.85))

func _main_cannon(pivot: Vector2, aim: float, sk: Dictionary) -> void:
        var rec := p_recoil * 10.0
        # the breech
        tank_draw.draw_circle(pivot, 31.0, sk["edge"])
        tank_draw.draw_circle(pivot, 26.0, sk["mid"])
        tank_draw.draw_circle(pivot, 14.0, sk["hi"])
        tank_draw.draw_circle(pivot - Vector2(4, 4), 5.0, sk["band"])
        var dir := Vector2.from_angle(aim)
        var side := Vector2(dir.y, -dir.x)
        # the barrel: a thick polygon with rings + a real muzzle brake
        var b0 := pivot + dir * (18.0 - rec)
        var b1 := b0 + dir * 108.0
        var poly := PackedVector2Array([
                b0 + side * 11.0, b1 + side * 11.0, b1 - side * 11.0, b0 - side * 11.0])
        tank_draw.draw_colored_polygon(poly, sk["hi"])
        tank_draw.draw_polyline(poly + PackedVector2Array([poly[0]]),
                sk["edge"], 2.4)
        tank_draw.draw_colored_polygon(PackedVector2Array([
                b0, b1, b1 - side * 4.5, b0 - side * 4.5]), sk["mid"])
        for rr in [34.0, 64.0]:
                tank_draw.draw_line(b0 + dir * rr - side * 11.0,
                        b0 + dir * rr + side * 11.0, sk["edge"], 3.8)
        # muzzle brake
        var m0 := pivot + dir * (118.0 - rec)
        var m1 := pivot + dir * (140.0 - rec)
        tank_draw.draw_colored_polygon(PackedVector2Array([
                m0 + side * 15.0, m1 + side * 15.0, m1 - side * 15.0,
                m0 - side * 15.0]), sk["mid"])
        tank_draw.draw_polyline(PackedVector2Array([
                m0 + side * 15.0, m1 + side * 15.0, m1 - side * 15.0,
                m0 - side * 15.0, m0 + side * 15.0]), sk["edge"], 2.4)
        tank_draw.draw_line(m0 + dir * 5.0 - side * 15.0,
                m0 + dir * 5.0 + side * 15.0, sk["edge"], 3.4)
        tank_draw.draw_line(m0 + dir * 16.0 - side * 15.0,
                m0 + dir * 16.0 + side * 15.0, sk["edge"], 3.4)
        # muzzle glow while firing
        if p_recoil > 0.3:
                var mg0 := pivot + dir * (140.0 - rec)
                tank_draw.draw_circle(mg0, 10.0 + p_recoil * 10.0,
                        Color(1.0, 0.75, 0.35, p_recoil * 0.65))

# =================================================================
# THE CONTROLS (Snowy Tower law): LEFT HALF = the analog move zone -
# the first touch anchors, the X offset from the anchor is the force,
# Y ignored. RIGHT HALF = AIM + FIRE - the finger IS the aim point and
# the crosshair shows it. A finger takes its role at touchdown and
# keeps it until lift.
# =================================================================
func _goga_input(event: InputEvent) -> void:
        if state == GS.OVER or paused:
                return
        if event is InputEventScreenTouch:
                var e := event as InputEventScreenTouch
                if e.pressed:
                        _touch_down(e.index, e.position)
                else:
                        _touch_up(e.index)
        elif event is InputEventScreenDrag:
                var d := event as InputEventScreenDrag
                if d.index == move_ptr:
                        move_force = clampf((d.position.x - move_anchor) / 150.0,
                                -1.0, 1.0)
                elif d.index == aim_ptr:
                        aim_pos = d.position
        elif event is InputEventKey:
                # THE PC LAW (the windows return): LEFT/RIGHT steer the tank
                # (the mouse keeps the aim + the cannon fire)
                var k := event as InputEventKey
                if k.pressed and not k.echo:
                        if k.is_action("ui_left"):
                                _kb_dir = -1
                        elif k.is_action("ui_right"):
                                _kb_dir = 1
                elif not k.pressed:
                        if _kb_dir != 0 and (k.is_action("ui_left") \
                                        or k.is_action("ui_right")):
                                _kb_dir = 0
        elif event is InputEventMouseButton:
                # THE CONTROLS LAW: a touch screen's emulated mouse is DEAD
                # (it was the moving-also-aims bug: the first finger IS a
                # synthetic mouse press). Desktop rigs keep the mouse.
                if touch_ui:
                        return
                var m := event as InputEventMouseButton
                mouse_aim = m.pressed
                if m.pressed:
                        if state == GS.INTRO:
                                _intro_tap()
                        elif state == GS.MENU:
                                _menu_tap(m.position)
                        else:
                                aim_pos = m.position
                elif state == GS.PLACE or state == GS.BOSS:
                        pass
        elif event is InputEventMouseMotion:
                if touch_ui:
                        return
                if mouse_aim:
                        aim_pos = (event as InputEventMouseMotion).position

func _touch_down(idx: int, pos: Vector2) -> void:
        if state == GS.INTRO:
                _intro_tap()
                return
        if state == GS.MENU:
                _menu_tap(pos)   # the menu buttons own their taps
                return
        if pos.x < W * 0.5:
                if move_ptr == -1:
                        move_ptr = idx
                        move_anchor = pos.x
                        move_force = 0.0
        else:
                if aim_ptr == -1:
                        aim_ptr = idx
                        aim_pos = pos

func _touch_up(idx: int) -> void:
        if idx == move_ptr:
                move_ptr = -1
                move_force = 0.0
        elif idx == aim_ptr:
                aim_ptr = -1

## the back law: the cards sheet NEVER closes on back (the owner: a level
## card must be chosen, not dismissed)
func _back_pressed() -> void:
        if over:
                return
        if not _sheet_stack.is_empty():
                if String(_sheet_stack[-1].get("id", "")) == "cards":
                        return
                sheet_pop()
                return
        _pause_open()

# =================================================================
# THE STATE FLOW: intro -> menu (deploy / scrap shop) -> place
# (10 waves) -> boss -> tunnel -> next place
# =================================================================
func _enter_intro() -> void:
        state = GS.INTRO
        t_state = 0.0
        Jukebox.music(MUSIC_MENU)
        if not bool(meta.d["lore_seen"]):
                meta.see_lore()

## the owner's menu law: tap anywhere -> the menu with DEPLOY + SCRAP SHOP
## + the scrap total. No controls text here - the guide owns that.
func _intro_tap() -> void:
        state = GS.MENU
        t_state = 0.0
        Jukebox.sfx("rw_click", -6.0)

func _start_place() -> void:
        state = GS.PLACE
        t_state = 0.0
        wave_state = "idle"
        wave_clock = 0.0
        Jukebox.music(MUSIC_WAR)
        _banner(String(HWData.PLACES[place_i % 10]["name"])
                + ("  II" if place_i >= 10 else ""), 2.4)

func _goga_tick(delta: float) -> void:
        if paused or state == GS.OVER:
                return
        # the top-bar scrap chip lives (the pop siege chip law)
        if scrap_lbl != null and is_instance_valid(scrap_lbl):
                var sv := str(p_scrap)
                if scrap_lbl.text != sv:
                        scrap_lbl.text = sv
        t_state += delta
        banner_t = maxf(0.0, banner_t - delta)
        p_recoil = maxf(0.0, p_recoil - delta * 8.0)
        mg_flash = maxf(0.0, mg_flash - delta * 7.0)
        rk_flash = maxf(0.0, rk_flash - delta * 6.0)
        shake = maxf(0.0, shake - delta * 42.0)
        flash = maxf(0.0, flash - delta * 2.4)
        damage_flash = maxf(0.0, damage_flash - delta * 1.8)
        if p_invuln > 0.0:
                p_invuln -= delta
        match state:
                GS.INTRO, GS.MENU:
                        _tick_world_scroll(delta, 0.6)
                GS.PLACE:
                        _tick_place(delta)
                GS.BOSS:
                        _tick_boss(delta)
                GS.TUNNEL:
                        _tick_tunnel(delta)
        _update_player(delta)
        _update_shots(delta)
        _update_eshots(delta)
        _update_rockets(delta)
        _update_enemies(delta)
        _update_drops(delta)
        _update_fx(delta)
        for d in decals:
                d["t"] = float(d["t"]) + delta
        while decals.size() > 0 and float(decals[0]["t"]) > 14.0:
                decals.pop_front()
        if hud_draw != null:
                hud_draw.queue_redraw()
        for n in [env_draw, ent_draw, shot_draw, tank_draw, fx_draw]:
                if n != null and is_instance_valid(n):
                        n.queue_redraw()

func _tick_world_scroll(delta: float, mul: float) -> void:
        scroll_x += HWData.WORLD_SPEED * mul * delta
        # world drifts even when the tank idles - the war never stops moving

func _banner(txt: String, dur: float) -> void:
        banner = txt
        banner_t = dur

# ------------------------------------------------------------------ waves
## v040-8 THE WAVE LAW: a wave rolls ONE of three kinds. KILLS: the wave
## ends when the quota is killed (a leaver never counts - a replacement
## spawns). TIME: survive the clock. BOTH: the clock AND the quota. The
## clocks grow as the waves climb (no more 3:00 from wave one).
func _tick_place(delta: float) -> void:
        _tick_world_scroll(delta, 1.0 + move_force * 0.0)
        wave_clock += delta
        match wave_state:
                "idle":
                        _wave_start()
                "spawning":
                        spawn_t += delta
                        var guard := 0
                        while spawn_list.size() > 0 \
                                        and float(spawn_list[0]) <= spawn_t and guard < 60:
                                spawn_list.pop_front()
                                _spawn_enemy()
                                guard += 1
                        # the TIME kind pours on a steady drip the whole clock
                        if wave_kind == "time":
                                drip_t -= delta
                                if drip_t <= 0.0:
                                        drip_t = HWData.wave_interval(wave,
                                                _diff()) * randf_range(0.8, 1.25)
                                        _spawn_enemy()
                        if spawn_list.is_empty() and wave_kind != "time":
                                wave_state = "clearing"
                        if wave_clock >= wave_duration and wave_kind == "time":
                                # the TIME kind's clock ran out: the wave wraps
                                spawn_list.clear()
                                _wave_wrap()
                "clearing":
                        # BOTH keeps a slow drip until the quota is met
                        if wave_kind == "both" and wave_quota_done < wave_quota:
                                drip_t -= delta
                                if drip_t <= 0.0:
                                        drip_t = maxf(1.6, HWData.wave_interval(
                                                wave, _diff()) * 2.0)
                                        if enemies.size() < 60:
                                                _spawn_enemy()
                        var quota_ok := wave_quota_done >= wave_quota
                        var clock_ok := wave_clock >= wave_duration
                        var done := false
                        match wave_kind:
                                "kills":
                                        done = quota_ok
                                "both":
                                        # v040-10 THE EITHER LAW (the owner:
                                        # "if one target done then it should
                                        # end") - the wave dies the MOMENT
                                        # either the quota or the clock is
                                        # met; waiting for both was the bug.
                                        done = quota_ok or clock_ok
                                _:
                                        done = true
                        if done:
                                # a clock-out (quota unmet) sends the
                                # survivors home - the retreat law
                                if not quota_ok and clock_ok:
                                        _retreat_survivors()
                                _wave_end()
                        elif wave_clock >= wave_duration + 45.0:
                                # the runaway brake: a wave can not stall forever
                                _wave_end()
                "boss":
                        pass
        # the press music rides the back half of the place
        if wave >= 6 and wave_state != "boss":
                Jukebox.music(MUSIC_PRESS)

## the TIME kind's clock ended: survivors retreat, the wave wraps
func _wave_wrap() -> void:
        _retreat_survivors()
        _wave_end()

## THE RETREAT (v040-8): a time/both wave that hits its clock sends its
## survivors home - they turn around and LEAVE (they never count as
## kills, they never come back)
func _retreat_survivors() -> void:
        for e in enemies:
                var d: Dictionary = e
                if String(d.get("kind", "")) == "boss":
                        continue
                d["leaving"] = true
                d["dir"] = -1.0 if float(d["x"]) > W * 0.5 else 1.0
                d["weapon"] = "none"

func _wave_end() -> void:
        if wave >= HWData.WAVES_PER_PLACE:
                _retreat_survivors()
                _spawn_boss()
        else:
                wave += 1
                wave_state = "idle"
                _banner("WAVE %d / %d" % [wave, HWData.WAVES_PER_PLACE], 1.6)
                p_hp = minf(p_hp_max, p_hp + 6.0)
                Jukebox.sfx("rw_clear", -6.0)

func _wave_start() -> void:
        # THE ROLL: every wave draws its own kind (kills 4 / time 3 / both 3)
        var roll := randi() % 10
        wave_kind = "kills" if roll < 4 else ("time" if roll < 7 else "both")
        wave_quota = HWData.wave_quota(wave, place_i, loop)
        wave_quota_done = 0
        wave_duration = HWData.wave_time(wave, place_i, loop)
        wave_clock = 0.0
        overbudget = 0
        spawn_t = 0.0
        drip_t = 0.0
        var iv := HWData.wave_interval(wave, _diff())
        spawn_list = []
        if wave_kind == "time":
                pass                                  # the drip pours it live
        else:
                # the quota (all of it, or the BOTH share) rides the list
                var n := wave_quota if wave_kind == "kills" \
                        else int(ceil(wave_quota * 0.7))
                var tt := 0.0
                for i in n:
                        tt += iv * randf_range(0.7, 1.3)
                        spawn_list.append(tt)
        wave_state = "spawning"
        var kind_txt: String = {"kills": "DESTROY %d", "time": "SURVIVE %d:%02d",
                "both": "DESTROY %d  IN  %d:%02d"}[wave_kind]
        var kind_arg: Array
        match wave_kind:
                "kills":
                        kind_arg = [wave_quota]
                "time":
                        kind_arg = [int(wave_duration) / 60,
                                int(wave_duration) % 60]
                "both":
                        kind_arg = [wave_quota, int(wave_duration) / 60,
                                int(wave_duration) % 60]
        _banner("WAVE %d / %d  -  " % [wave, HWData.WAVES_PER_PLACE]
                + (kind_txt % kind_arg), 2.2)
        Jukebox.sfx("rw_wave", -6.0)

# ------------------------------------------------------------------ spawns
func _spawn_enemy(kind := "") -> void:
        if enemies.size() >= 90:
                return
        var pool := HWData.pool_for(place_i)
        if kind == "":
                kind = String(pool[randi() % pool.size()])
        var def: Dictionary = HWData.ENEMIES[kind]
        var df := _diff()
        var hp := int(round(float(def["hp"]) * (1.0 + df * 0.62)))
        var spd := float(def["speed"]) * (1.0 + df * 0.045)
        var from_left := randf() < 0.5
        var e := {
                "kind": kind, "hp": hp, "maxhp": hp, "size": float(def["size"]),
                "speed": spd, "dir": -1 if not from_left else 1,
                "x": (-140.0) if from_left else (W + 140.0),
                "y": randf_range(90.0, maxf(200.0, GROUND_Y - 260.0)),
                "base_y": 0.0, "t": randf() * 10.0, "phase": randf() * TAU,
                "hit": 0.0,
                "shield": float(def.get("shield", 0)),
                "max_shield": float(def.get("shield", 0)),
                "move": String(def["move"]), "weapon": String(def["weapon"]),
                "shoot_t": randf_range(0.9, 2.2), "ground": def["move"] in ["ground", "static"],
                "chill": 0.0, "hover_x": randf_range(W * 0.2, W * 0.8),
                "diving": false, "laser_t": 0.0, "laser_on": false,
                "stage": "approach", "loiter_t": 0.0, "ang": 0.0,
        }
        if String(def["move"]) == "dive":
                e["ang"] = 0.0 if int(e["dir"]) > 0 else PI
        e["base_y"] = e["y"]
        if e["move"] == "static":
                e["x"] = randf_range(W * 0.2, W * 0.8)
                e["y"] = GROUND_Y - e["size"] * 0.55
                e["base_y"] = e["y"]
        if e["move"] == "ground":
                e["y"] = GROUND_Y - e["size"] * 0.5
                e["base_y"] = e["y"]
        if e["move"] == "shadow":
                e["y"] = randf_range(120.0, 220.0)
                e["base_y"] = e["y"]
        # THE SHIELD LAW (the owner: "enemies get shields and like that"):
        # from place 3 on, ordinary machines start arriving shielded - the
        # war grows armor as the tank grows power.
        if place_i >= 2 and float(e["shield"]) <= 0.0 \
                        and randf() < minf(0.32, 0.06 + float(place_i) * 0.035):
                e["shield"] = 10.0 + df * 5.0
                e["max_shield"] = float(e["shield"])
        enemies.append(e)

func _enemy_dead_cleanup(e: Dictionary) -> void:
        enemies.erase(e)

# ------------------------------------------------------------ enemy moves
func _update_enemies(delta: float) -> void:
        var dead: Array = []
        for e in enemies.duplicate():
                var d: Dictionary = e
                # THE BOSS BRANCH: the boss rides its own brain + visuals
                if String(d.get("kind", "")) == "boss":
                        _update_boss(d, delta)
                        continue
                d["t"] += delta
                if d["hit"] > 0.0:
                        d["hit"] -= delta
                if d["chill"] > 0.0:
                        d["chill"] -= delta
                var spd: float = d["speed"] * (0.5 if d["chill"] > 0.0 else 1.0)
                # THE RETREAT / LEAVE (v040-8): a leaver turns ONCE and goes
                # - it never comes back, it never shoots again
                if bool(d.get("leaving", false)):
                        d["x"] += float(d["dir"]) * spd * 1.6 * delta
                        d["y"] = float(d["base_y"]) \
                                + sin(d["t"] * 1.7) * 10.0
                        if d["x"] < -380.0 or d["x"] > W + 380.0:
                                dead.append(d)
                        continue
                match String(d["move"]):
                        "straight":
                                d["x"] += d["dir"] * spd * delta
                                d["y"] = d["base_y"] + sin(d["t"] * 2.4 + d["phase"]) * 14.0
                        "rush":
                                # THE RAIDER: it crosses the field fast and
                                # low, jinking - you will not catch it, you
                                # must kill it before it is gone
                                d["x"] += d["dir"] * spd * delta
                                d["y"] = d["base_y"] + sin(d["t"] * 5.2
                                        + d["phase"]) * 26.0
                        "sine":
                                d["x"] += d["dir"] * spd * delta
                                d["y"] = d["base_y"] + sin(d["t"] * 1.8 + d["phase"]) * 30.0
                        "hover":
                                # THE TWO-STATE LAW (v040-8): a station machine
                                # APPROACHES its hover point, LOITERS there
                                # shooting for a while, then LEAVES for good -
                                # it never ping-pongs across the sky (the
                                # owner: "make it two behavior states")
                                var stage := String(d.get("stage", "approach"))
                                match stage:
                                        "approach":
                                                d["x"] += signf(float(d["hover_x"]) \
                                                        - float(d["x"])) * spd * delta
                                                if absf(d["x"] \
                                                                - float(d["hover_x"])) <= 24.0:
                                                        d["stage"] = "loiter"
                                                        d["arrived"] = true
                                                        d["loiter_t"] = \
                                                                randf_range(6.0, 9.5)
                                        "loiter":
                                                d["loiter_t"] = float(d.get(
                                                        "loiter_t", 7.0)) - delta
                                                if float(d["loiter_t"]) <= 0.0:
                                                        d["stage"] = "leave"
                                                        d["weapon"] = "none"
                                                        d["laser_on"] = false
                                                        d["dir"] = -1 \
                                                                if float(d["x"]) < W * 0.5 else 1
                                        "leave":
                                                d["x"] += float(d["dir"]) \
                                                        * spd * 1.55 * delta
                                d["y"] = d["base_y"] + sin(d["t"] * 1.7) * 14.0
                        "dive":
                                if not bool(d["diving"]) and absf(d["x"] - p_x) < 340.0:
                                        d["diving"] = true
                                        var ang := atan2((GROUND_Y - 90.0 * TANK_S) \
                                                - float(d["y"]), p_x - float(d["x"]))
                                        d["vx"] = cos(ang) * 380.0
                                        d["vy"] = sin(ang) * 380.0
                                if bool(d["diving"]):
                                        d["x"] += float(d.get("vx", 0.0)) * delta
                                        d["y"] += float(d.get("vy", 0.0)) * delta
                                else:
                                        d["x"] += d["dir"] * spd * delta
                                        d["y"] = d["base_y"] + sin(d["t"] * 3.0) * 20.0
                        "ground":
                                d["x"] += d["dir"] * spd * delta
                        "static":
                                pass
                        "shadow":
                                # the SHADOW LANCER: the same two-state law -
                                # it haunts above the tank, then leaves
                                var sstage := String(d.get("stage", "approach"))
                                match sstage:
                                        "approach":
                                                d["x"] += d["dir"] * spd * delta
                                                if (d["dir"] > 0 and d["x"] >= p_x - 60.0) \
                                                                or (d["dir"] < 0 \
                                                                and d["x"] <= p_x + 60.0):
                                                        d["stage"] = "loiter"
                                                        d["arrived"] = true
                                                        d["loiter_t"] = \
                                                                randf_range(6.5, 9.0)
                                        "loiter":
                                                var dx := p_x - float(d["x"])
                                                d["x"] += clampf(dx, -spd * 0.62,
                                                        spd * 0.62) * delta
                                                d["loiter_t"] = float(d.get(
                                                        "loiter_t", 7.0)) - delta
                                                if float(d["loiter_t"]) <= 0.0:
                                                        d["stage"] = "leave"
                                                        d["weapon"] = "none"
                                                        d["laser_on"] = false
                                                        d["dir"] = -1 \
                                                                if float(d["x"]) < W * 0.5 else 1
                                        "leave":
                                                d["x"] += float(d["dir"]) \
                                                        * spd * 1.5 * delta
                                d["y"] = d["base_y"] + sin(d["t"] * 1.3) * 12.0
                # THE DIVE ANGLE (v040-8): the suicidal machines FACE the
                # dive - their nose lerps smoothly into the fall
                if String(d["move"]) == "dive":
                        var want := 0.0 if float(d["dir"]) > 0.0 else PI
                        if bool(d["diving"]):
                                want = atan2(float(d.get("vy", 0.0)),
                                        float(d.get("vx", 1.0)))
                        d["ang"] = lerp_angle(float(d.get("ang", want)),
                                want, minf(1.0, delta * 6.5))
                # weapons
                if String(d["weapon"]) != "none" and p_invuln <= 0.0:
                        var can := true
                        if String(d["move"]) in ["hover", "shadow"] \
                                        and not bool(d.get("arrived", false)):
                                can = false
                        if String(d.get("stage", "")) == "leave":
                                can = false          # a leaver never shoots
                        if can:
                                d["shoot_t"] -= delta
                                if float(d["shoot_t"]) <= 0.0:
                                        d["shoot_t"] = randf_range(1.1, 2.4) \
                                                * maxf(0.55, 1.0 - _diff() * 0.03)
                                        _enemy_fire(d)
                # THE RAIDER's rocket rain rides its own fast clock
                if String(d["weapon"]) == "rocketdrop":
                        d["drop_t"] = float(d.get("drop_t", 0.0)) - delta
                        if float(d["drop_t"]) <= 0.0:
                                d["drop_t"] = 0.85
                                _eshot(Vector2(d["x"], d["y"] + 18.0),
                                        Vector2(d["dir"] * 120.0, 90.0), 12.0,
                                        "missile")
                                Jukebox.sfx("rw_rocket", -14.0)
                # the shadow lancer's beam also burns on its own clock
                if String(d["weapon"]) == "laser":
                        d["laser_t"] -= delta
                        d["laser_on"] = float(d["laser_t"]) > 0.0 \
                                and absf(float(d["x"]) - p_x) < 90.0
                        if bool(d["laser_on"]):
                                d["laser_tick"] = float(d.get("laser_tick", 0.0)) + delta
                                if float(d["laser_tick"]) >= 0.5:
                                        d["laser_tick"] = 0.0
                                        if absf(float(d["x"]) - p_x) < 90.0:
                                                _damage_player(7.0)
                # kamikaze ground hit
                if String(d["move"]) == "dive" and bool(d["diving"]) \
                                and d["y"] > GROUND_Y - 30.0:
                        _explode(d["x"], GROUND_Y - 20.0, 0.9)
                        if absf(d["x"] - p_x) < 110.0 * TANK_S:
                                _damage_player(14.0)
                        kill_enemy(d, false)
                        dead.append(d)
                        continue
                if d["x"] < -360.0 or d["x"] > W + 360.0:
                        dead.append(d)
                        continue
        for d in dead:
                _enemy_dead_cleanup(d)
                # THE LEAVER LAW (v040-8): an enemy that leaves the screen
                # alive NEVER counts toward the wave - a replacement spawns
                # so the quota stays honest and reachable (the owner: "it
                # should not get counted and it should spawn another one")
                if state == GS.PLACE and wave_state in ["spawning", "clearing"] \
                                and wave_quota_done < wave_quota \
                                and not bool(d.get("leaving", false)) \
                                and String(d.get("kind", "")) != "boss" \
                                and enemies.size() < 70:
                        _spawn_enemy()

func _enemy_fire(e: Dictionary) -> void:
        var src := Vector2(e["x"], e["y"] + e["size"] * 0.2)
        var tgt := Vector2(p_x, GROUND_Y - 100.0 * TANK_S)
        var ang := (tgt - src).angle()
        var col: Color = HWData.PLACES[place_i % 10]["accent"]
        match String(e["weapon"]):
                "aimed":
                        _eshot(src, Vector2.from_angle(ang) * 380.0, 11.0, "plasma")
                        Jukebox.sfx("rw_eshot", -10.0)
                "spread":
                        for i in 3:
                                _eshot(src, Vector2.from_angle(ang + (i - 1) * 0.17) * 350.0,
                                        11.0, "plasma")
                        Jukebox.sfx("rw_eshot", -9.0)
                "homing":
                        _eshot(src, Vector2(e["dir"] * 160.0, 70.0), 13.0, "missile")
                        Jukebox.sfx("rw_rocket", -12.0)
                "bomb":
                        var b := {"x": e["x"], "y": e["y"] + e["size"] * 0.4,
                                "vx": e["dir"] * 40.0, "vy": 40.0, "dmg": 16.0, "t": 0.0}
                        _eshot_common(b, "bomb")
                        Jukebox.sfx("rw_eshot", -12.0)
                "arc":
                        _eshot(src, Vector2((tgt.x - src.x) * 0.8, -320.0), 13.0, "plasma")
                        Jukebox.sfx("rw_eshot", -10.0)
                "bigbomb":
                        # THE CARPET BOMBER: a fat bomb with a BIG blast radius
                        var b2 := {"x": e["x"], "y": e["y"] + e["size"] * 0.4,
                                "vx": e["dir"] * 30.0, "vy": 50.0, "dmg": 26.0, "t": 0.0}
                        _eshot_common(b2, "bigbomb")
                        Jukebox.sfx("rw_eshot", -8.0)
                "cluster":
                        # THE SHRED BOMBER: the bomb bursts into shreds mid-air
                        var b3 := {"x": e["x"], "y": e["y"] + e["size"] * 0.4,
                                "vx": e["dir"] * 30.0, "vy": 60.0, "dmg": 10.0, "t": 0.0,
                                "burst_h": randf_range(GROUND_Y - 380.0, GROUND_Y - 260.0)}
                        _eshot_common(b3, "cluster")
                        Jukebox.sfx("rw_eshot", -10.0)
                "laser":
                        # THE SHADOW LANCER: the lens opens, the beam burns down
                        e["laser_t"] = 1.6
                        Jukebox.sfx("rw_laser", -8.0)

# ------------------------------------------------------------------ bosses
## THE BOSS LAW (v040-6): the WARNING siren, a DRAMATIC entrance (some
## come from the OPPOSITE side, fast; some dive from the sky) with escort
## planes, SHIELD phases at 66% / 33% that summon more escorts, and
## harder bites. THE DUST REAVER FIX: the sidewinder entrance used to
## slide it to the RIGHT from beyond the right edge - it never arrived
## and the fight never started. Every entrance now walks TOWARD the
## field.
func _spawn_boss() -> void:
        wave_state = "boss"
        run["bosses_met"] = int(run["bosses_met"]) + 1
        var def: Dictionary = HWData.BOSSES[place_i % 10]
        var hp := HWData.boss_hp(place_i, loop)
        var brain := String(def["brain"])
        # the entrance seat: the opposite side, fast, or the sky
        var ex := W + 300.0
        var ey := 210.0
        var evx := -140.0
        var evy := 0.0
        match brain:
                "flyer":
                        ex = -300.0; ey = 210.0; evx = 560.0   # opposite side dash
                "dropship":
                        ex = W * 0.62; ey = -300.0; evy = 300.0   # the sky dive
                "sidewinder":
                        ex = -280.0; ey = 230.0; evx = 500.0   # THE FIX: arrives
                "fortress":
                        ex = W + 340.0; ey = 200.0; evx = -120.0
                "weaver":
                        ex = -260.0; ey = 200.0; evx = 420.0
                "prime":
                        ex = W * 0.6; ey = -320.0; evy = 260.0
        var b := {
                "kind": "boss", "boss_id": String(def["id"]),
                "name": String(def["name"]), "brain": brain,
                "hp": float(hp), "maxhp": float(hp), "size": float(def["size"]),
                "x": ex, "y": ey, "base_y": ey, "t": 0.0,
                # v040-11 THE FACING LAW (the owner's standing order - the
                # first boss flew left-to-right wearing a LEFT-facing body,
                # again): a boss faces its REAL travel. Entrance velocity
                # seeds it; _update_boss keeps following the actual motion.
                "dir": 1 if evx > 0.0 else -1, "hit": 0.0,
                "arrived": false, "vx": evx, "vy": evy,
                "weapon_t": 1.6, "weapon_cycle": 0, "spawn_t": 5.0,
                "enraged": false, "chill": 0.0, "dash_dir": -1,
                "shield": 0.0, "shield_breaks": 0,
                "scrap": 60 + place_i * 10, "xp": 60,
        }
        enemies.append(b)
        boss_ent = b
        state = GS.BOSS
        Jukebox.music(MUSIC_BOSS)
        _banner("WARNING  -  " + String(b["name"]), 2.6)
        Jukebox.sfx("rw_boss_warn", -4.0)
        # the escort wing: the boss never comes alone
        var n_esc := 2 + (place_i % 3)
        for i in n_esc:
                _spawn_enemy("fighter" if i % 2 == 0 else "scout")

func _tick_boss(delta: float) -> void:
        _tick_world_scroll(delta, 0.4)
        # the boss ENT is the clock: minions may live on, the fight ends when
        # the boss itself is gone from the pool
        if not boss_ent.is_empty() and enemies.has(boss_ent):
                return
        boss_ent = {}
        # boss down -> the place falls
        run["bosses_killed"] = int(run["bosses_killed"]) + 1
        _enter_tunnel()

func _boss_fire(b: Dictionary, ang: float, spd: float, dmg: float) -> void:
        _eshot(Vector2(b["x"], b["y"]) + Vector2.from_angle(ang) * b["size"] * 0.3,
                Vector2.from_angle(ang) * spd, dmg, "plasma")

func _update_boss(b: Dictionary, delta: float) -> void:
        b["t"] += delta
        if float(b.get("hit", 0.0)) > 0.0:
                b["hit"] = float(b["hit"]) - delta
        var enraged: bool = float(b["hp"]) < float(b["maxhp"]) * 0.4
        b["enraged"] = enraged
        var rage := 0.72 if enraged else 1.0
        # v040-11 THE FACING LAW, live half: the boss's facing follows its
        # REAL horizontal motion every tick - entrance, hover drift, the
        # sidewinder's wall-to-wall dash. A 30px/s dead-band keeps the sine
        # hovers from jittering at their turn-around points.
        var face_x0 := float(b["x"])
        # THE SHIELD PHASES: at 66% and 33% the boss slams a shield up and
        # calls its wing - the fight has acts, not a flat health bar
        var breaks := int(b.get("shield_breaks", 0))
        if bool(b.get("arrived", false)) and breaks < 2:
                var frac := float(b["hp"]) / float(b["maxhp"])
                var next_gate := 0.66 if breaks == 0 else 0.33
                if frac <= next_gate and float(b.get("shield", 0.0)) <= 0.0:
                        b["shield"] = float(b["maxhp"]) * 0.13
                        b["shield_breaks"] = breaks + 1
                        _banner(String(b["name"]) + "  -  SHIELDS UP", 1.6)
                        Jukebox.sfx("rw_shieldhit", -2.0)
                        for i in 2 + int(b["shield_breaks"]):
                                _spawn_enemy("kamikaze" if i % 2 == 0 else "fighter")
        match String(b["brain"]):
                "flyer":
                        if not bool(b["arrived"]):
                                b["x"] += b["vx"] * delta
                                b["y"] = 210.0 + sin(b["t"] * 2.2) * 46.0
                                if b["x"] >= W - 340.0:
                                        b["arrived"] = true
                        else:
                                b["y"] = 200.0 + sin(b["t"] * 1.1) * 40.0
                                b["x"] += sin(b["t"] * 0.5) * 70.0 * delta
                "dropship":
                        if not bool(b["arrived"]):
                                b["y"] += b["vy"] * delta
                                if b["y"] >= 200.0:
                                        b["arrived"] = true
                        else:
                                b["y"] = 200.0 + sin(b["t"] * 0.9) * 24.0
                                b["x"] += sin(b["t"] * 0.7) * 90.0 * delta
                "sidewinder":
                        if not bool(b["arrived"]):
                                # THE FIX: it slides IN from the opposite side
                                b["x"] += b["vx"] * delta
                                if b["x"] >= W - 240.0:
                                        b["arrived"] = true
                        else:
                                b["x"] += b["dash_dir"] * (420.0 if enraged else 330.0) * delta
                                if b["x"] < 190.0:
                                        b["x"] = 190.0
                                        b["dash_dir"] = 1
                                elif b["x"] > W - 190.0:
                                        b["x"] = W - 190.0
                                        b["dash_dir"] = -1
                                b["y"] = 230.0 + sin(b["t"] * 1.5) * 20.0
                "fortress":
                        if not bool(b["arrived"]):
                                b["x"] += b["vx"] * delta
                                if b["x"] <= W - 300.0:
                                        b["arrived"] = true
                        else:
                                b["y"] = 190.0 + sin(b["t"] * 0.6) * 22.0
                "weaver":
                        if not bool(b["arrived"]):
                                b["x"] += b["vx"] * delta
                                if b["x"] >= W * 0.62:
                                        b["arrived"] = true
                        else:
                                b["x"] += sin(b["t"] * 0.9) * 240.0 * delta
                                b["y"] = 180.0 + sin(b["t"] * 1.3) * 60.0
                "prime":
                        if not bool(b["arrived"]):
                                b["y"] += b["vy"] * delta
                                if b["y"] >= 190.0:
                                        b["arrived"] = true
                        else:
                                b["y"] = 190.0 + sin(b["t"] * 1.2) * 44.0
                                b["x"] += sin(b["t"] * 0.55) * 80.0 * delta
        var face_v := (float(b["x"]) - face_x0) / maxf(0.0001, delta)
        if absf(face_v) > 30.0:
                b["dir"] = 1 if face_v > 0.0 else -1
        if not bool(b["arrived"]):
                return
        # weapons
        b["weapon_t"] -= delta / maxf(0.55, rage)
        if b["weapon_t"] <= 0.0:
                b["weapon_t"] = 1.15 if not enraged else 0.82
                _boss_attack(b, enraged)
        # minion pressure
        b["spawn_t"] -= delta
        if b["spawn_t"] <= 0.0:
                b["spawn_t"] = 4.6 if not enraged else 3.0
                _spawn_enemy()

func _boss_attack(b: Dictionary, enraged: bool) -> void:
        var aim := atan2((GROUND_Y - 100.0 * TANK_S) - float(b["y"]), p_x - float(b["x"]))
        var cycle := int(b["weapon_cycle"])
        b["weapon_cycle"] = cycle + 1
        var n := 9 if enraged else 7
        match String(b["brain"]):
                "flyer":
                        match cycle % 4:
                                0:
                                        for i in n:
                                                _boss_fire(b, aim + (i - n / 2.0) * 0.13, 380.0, 11.0)
                                1:
                                        for i in 5:
                                                _boss_fire(b, aim + randf_range(-0.06, 0.06), 460.0, 9.0)
                                2:
                                        for i in 3:
                                                _eshot(Vector2(b["x"] + (i - 1) * 50.0, b["y"] + 30.0),
                                                        Vector2(randf_range(-120, 120), 160.0), 14.0, "missile")
                                3:
                                        _eshot(Vector2(b["x"], b["y"] + 40.0),
                                                Vector2((p_x - b["x"]) * 0.5, 120.0), 20.0, "bigbomb")
                "dropship":
                        match cycle % 4:
                                0:
                                        for i in 9:
                                                _boss_fire(b, PI / 2 - 0.7 + i * 0.16, 320.0, 11.0)
                                1:
                                        for i in 3:
                                                _eshot(Vector2(b["x"] + (i - 1) * 60.0, b["y"] + 40.0),
                                                        Vector2(0, 60.0), 15.0, "bomb")
                                2:
                                        for i in 3:
                                                _boss_fire(b, aim + (i - 1) * 0.2, 420.0, 11.0)
                                3:
                                        for i in 2:
                                                _eshot(Vector2(b["x"] + (i - 1) * 90.0, b["y"] + 40.0),
                                                        Vector2(randf_range(-40, 40), 70.0), 24.0, "bigbomb")
                "sidewinder":
                        match cycle % 3:
                                0:
                                        for i in 3:
                                                _boss_fire(b, aim + (i - 1) * 0.08, 560.0, 8.0)
                                1:
                                        for i in 5:
                                                _boss_fire(b, aim + (i - 2) * 0.15, 430.0, 9.0)
                                2:
                                        for r in 2:
                                                for i in 4:
                                                        _boss_fire(b, aim + (i - 1.5) * 0.24 + float(r) * 0.12,
                                                                380.0 + float(r) * 120.0, 8.0)
                "fortress":
                        match cycle % 3:
                                0:
                                        var m := 20 if enraged else 14
                                        for i in m:
                                                _boss_fire(b, TAU * i / m + b["t"] * 0.5, 280.0, 10.0)
                                1:
                                        for i in 11:
                                                _boss_fire(b, aim + (i - 5) * 0.075, 440.0, 10.0)
                                2:
                                        for i in 4:
                                                _eshot(Vector2(b["x"] + (i - 1.5) * 70.0, b["y"] + 50.0),
                                                        Vector2(0, 60.0), 15.0, "bomb")
                "weaver":
                        match cycle % 4:
                                0:
                                        for i in 5:
                                                _boss_fire(b, aim + (i - 2) * 0.16, 400.0, 10.0)
                                1:
                                        for i in 2:
                                                _spawn_enemy()
                                2:
                                        for i in 3:
                                                _eshot(Vector2(b["x"], b["y"]),
                                                        Vector2((p_x - b["x"]) * 0.4 + float(i - 1) * 60.0,
                                                                -260.0), 13.0, "missile")
                                3:
                                        var m2 := 10
                                        for i in m2:
                                                _boss_fire(b, TAU * i / m2 - b["t"] * 0.7, 300.0, 9.0)
                "prime":
                        match cycle % 5:
                                0:
                                        for i in 11:
                                                _boss_fire(b, aim + (i - 5) * 0.12, 420.0, 11.0)
                                1:
                                        var m := 22
                                        for i in m:
                                                _boss_fire(b, TAU * i / m + b["t"] * 0.5, 300.0, 10.0)
                                2:
                                        for i in 4:
                                                _eshot(Vector2(b["x"], b["y"] + 30.0),
                                                        Vector2(randf_range(-160, 160), 180.0), 14.0, "missile")
                                3:
                                        for i in 3:
                                                _spawn_enemy()
                                4:
                                        for i in 3:
                                                _eshot(Vector2(b["x"] + (i - 1) * 70.0, b["y"] + 40.0),
                                                        Vector2(0, 80.0), 26.0, "bigbomb")
        Jukebox.sfx("rw_eshot", -7.0)

# =================================================================
# THE PLAYER - aim-following cannon, locked weapons, the crosshair aim
# =================================================================
func _update_player(delta: float) -> void:
        if state in [GS.INTRO, GS.MENU, GS.TUNNEL, GS.OVER]:
                # the tank still rolls through the tunnel (the drive law)
                if state == GS.TUNNEL:
                        var tspd := 240.0 * (1.0 + _shop_lvl("wheels") * 0.12)
                        p_x = clampf(p_x + (move_force if _kb_dir == 0 else float(_kb_dir)) * tspd * delta + 30.0 * delta,
                                220.0, W - 220.0)
                        p_wheel_spin += delta * 15.0
                _tank_pose(delta)
                return
        # move: the analog force from the LEFT zone, or the keyboard lane
        var kb_force := move_force if _kb_dir == 0 else float(_kb_dir)
        var spd := 240.0 * (1.0 + _shop_lvl("wheels") * 0.12) \
                * (1.0 + float(buffs["speed"]))
        p_x = clampf(p_x + kb_force * spd * delta, 110.0, W - 110.0)
        if absf(kb_force) > 0.02:
                p_wheel_spin += kb_force * delta * 11.0
        # aim: the RIGHT zone finger, else dead ahead (the pivot rides the
        # tower top - SCALED with the tank since v040-8)
        var pivot := Vector2(p_x, GROUND_Y - 284.0 * TANK_S)
        if aim_ptr != -1 or mouse_aim:
                var a := (aim_pos - pivot).angle()
                if a > -0.06 and a < PI / 2:
                        a = -0.06
                elif a >= PI / 2 or a < -PI + 0.06:
                        a = -PI + 0.06
                p_aim = lerp_angle(p_aim, a, 1.0 - pow(0.0001, delta))
        else:
                p_aim = lerp_angle(p_aim, -PI / 2, 1.0 - pow(0.001, delta))
        # cadence
        var cd_mul := float(buffs["cd"]) * pow(0.90, _shop_lvl("reload"))
        cd_main -= delta
        cd_mg -= delta
        cd_rk -= delta
        var fire := aim_ptr != -1 or mouse_aim
        if fire and cd_main <= 0.0:
                _fire_main()
                cd_main = maxf(0.09, 0.62 - (_shop_lvl("cannon") + 1) * 0.025) \
                        * cd_mul / (1.0 + float(buffs["rate"]))
        if _mg_lvl() > 0 and cd_mg <= 0.0:
                _fire_mg()
                cd_mg = maxf(0.04, 0.14 - float(_mg_lvl()) * 0.008) \
                        * cd_mul / (1.0 + float(buffs["rate"]))
        if _rk_lvl() > 0 and cd_rk <= 0.0:
                _fire_rockets()
                cd_rk = maxf(0.4, 1.8 - float(_rk_lvl()) * 0.15) * cd_mul
        _tank_pose(delta)

func _tank_pose(delta: float) -> void:
        pass   # the tank is drawn from the live numbers; nothing to pose

# ---------------------------------------------------------------- weapons
## the HTML cannon law: (16 + (1+cannon)*4) * (1 + cards + cannon*0.22)
func _main_dmg() -> float:
        var c := _shop_lvl("cannon")
        return (16.0 + float(1 + c) * 4.0) \
                * (1.0 + float(buffs["dmg"]) + float(c) * 0.22)

func _fire_main() -> void:
        var pivot := Vector2(p_x, GROUND_Y - 284.0 * TANK_S)
        var n := 1 + int(buffs["multi"])
        for i in n:
                var a := p_aim + (i - (n - 1) / 2.0) * 0.09 + randf_range(-0.008, 0.008)
                var crit := randf() < float(buffs["crit"])
                var s := {
                        "x": pivot.x + cos(p_aim) * 44.0,
                        "y": pivot.y + sin(p_aim) * 44.0,
                        "vx": cos(a) * 1250.0, "vy": sin(a) * 1250.0,
                        "dmg": _main_dmg() * (2.0 if crit else 1.0),
                        "crit": crit, "pierce": int(buffs["pierce"]),
                        "explosive": int(buffs["explosive"]), "t": 0.0, "kind": "ball",
                        "trail": [],
                }
                shots.append(s)
        p_recoil = 1.0
        shake = minf(shake + 0.7, 5.0)
        Jukebox.sfx("rw_cannon", -4.0)
        _muzzle(pivot + Vector2.from_angle(p_aim) * 45.0)

## THE MG LAW: the barrels point UP ONLY - a fixed small splay outward,
## never the aim. The rack levels add one more barrel per side.
func _fire_mg() -> void:
        var xs := _mg_xs()
        var dmg := 3.2 * (1.0 + float(_shop_lvl("mg_rack")) * 0.15) \
                * (1.0 + float(buffs["dmg"]))
        for mx in xs:
                var bx := p_x + float(mx) * TANK_S
                var by := GROUND_Y - 208.0 * TANK_S
                var a := -PI / 2 + (0.10 if float(mx) < 0.0 else -0.10) \
                        + randf_range(-0.035, 0.035)
                shots.append({
                        "x": bx, "y": by,
                        "vx": cos(a) * 1650.0, "vy": sin(a) * 1650.0,
                        "dmg": dmg, "pierce": 0, "explosive": 0, "t": 0.0,
                        "kind": "mg", "trail": [],
                })
        mg_flash = 1.0
        Jukebox.sfx("rw_mg", -8.0, randf_range(0.94, 1.08))

## THE ROCKET LAW: one rocket per CELL, launch up out of the bottom layer,
## then home - and EVERY rocket picks a DIFFERENT target (round-robin over
## the living enemies, the owner's "each single rocket follows different").
func _fire_rockets() -> void:
        var xs := _pod_xs()
        var dmg := 23.0 * (1.0 + float(_shop_lvl("rocket_rack")) * 0.15) \
                * (1.0 + float(buffs["dmg"]))
        var rk_spd_mul := 1.0 + float(_shop_lvl("rocket_rack")) * 0.06
        var alive := enemies.duplicate()
        alive.shuffle()
        for i in xs.size():
                var rx := p_x + float(xs[i]) * TANK_S
                var by := GROUND_Y - 124.0 * TANK_S
                var tgt: Dictionary = {}
                if not alive.is_empty():
                        tgt = alive[i % alive.size()]
                _launch_rocket(Vector2(rx, by), dmg, 2.4, tgt, rk_spd_mul,
                        130.0 * signf(float(xs[i])))
        rk_flash = 1.0
        Jukebox.sfx("rw_rocket", -8.0)

func _launch_rocket(src: Vector2, dmg: float, homing: float,
                target: Dictionary = {}, spd_mul := 1.0, vx0 := 0.0) -> void:
        if rockets.size() >= 40:
                return
        rockets.append({
                "x": src.x, "y": src.y, "vx": vx0 + randf_range(-40, 40),
                "vy": -320.0,
                "dmg": dmg, "homing": homing, "target": target, "t": 0.0,
                "launch": 0.35, "spd_mul": spd_mul,
        })

# ------------------------------------------------------------- shots tick
func _update_shots(delta: float) -> void:
        var dead: Array = []
        for s in shots:
                var d: Dictionary = s
                d["t"] += delta
                d["x"] += d["vx"] * delta
                d["y"] += d["vy"] * delta
                (d["trail"] as Array).append(Vector2(d["x"], d["y"]))
                if (d["trail"] as Array).size() > 7:
                        (d["trail"] as Array).pop_front()
                # off-screen + ground
                if d["x"] < -100.0 or d["x"] > W + 100.0 or d["y"] < -140.0:
                        dead.append(d)
                        continue
                if d["kind"] != "mg" and d["y"] > GROUND_Y - 6.0:
                        _impact(d, Vector2(d["x"], GROUND_Y - 6.0), {})
                        dead.append(d)
                        continue
                # hits
                var hit_e: Dictionary = {}
                for e in enemies:
                        var dd: Dictionary = e
                        var dx: float = d["x"] - float(dd["x"])
                        var dy: float = d["y"] - float(dd["y"])
                        var rad: float = float(dd["size"]) * 0.5 + 14.0
                        if dx * dx + dy * dy < rad * rad:
                                hit_e = dd
                                break
                if not hit_e.is_empty():
                        var stop := _impact(d, Vector2(d["x"], d["y"]), hit_e)
                        if stop or int(d["pierce"]) <= 0:
                                dead.append(d)
                        else:
                                d["pierce"] = int(d["pierce"]) - 1
        for d in dead:
                shots.erase(d)

## returns true when the shot must die
func _impact(d: Dictionary, at: Vector2, hit_e: Dictionary) -> bool:
        var stopped := true
        if hit_e != null and not hit_e.is_empty():
                var dmg: float = d["dmg"]
                if bool(d.get("crit", false)):
                        _sparks(at, Color(1.0, 0.7, 0.3), 10)
                if float(buffs["slow"]) > 0.0 and d["kind"] != "ice":
                        hit_e["chill"] = maxf(float(hit_e.get("chill", 0.0)), 1.2)
                _damage_enemy(hit_e, dmg)
                if float(buffs["lifesteal"]) > 0.0:
                        p_hp = minf(p_hp_max, p_hp + dmg * float(buffs["lifesteal"]))
                if int(d.get("explosive", 0)) > 0:
                        _explode(at.x, at.y, 0.8)
                        for e in enemies.duplicate():
                                var ee: Dictionary = e
                                if ee == hit_e:
                                        continue
                                var dx: float = float(ee["x"]) - at.x
                                var dy: float = float(ee["y"]) - at.y
                                if dx * dx + dy * dy < 130.0 * 130.0:
                                        _damage_enemy(ee, dmg * 0.5)
                # the ricochet card: hop to a second target
                if int(buffs["bounce"]) > 0 and not bool(d.get("bounced", false)):
                        d["bounced"] = true
                        var best: Dictionary = {}
                        var bd := 1e9
                        for e in enemies:
                                var ee: Dictionary = e
                                if ee == hit_e:
                                        continue
                                var dx: float = float(ee["x"]) - at.x
                                var dy: float = float(ee["y"]) - at.y
                                var dist := dx * dx + dy * dy
                                if dist < bd:
                                        bd = dist
                                        best = ee
                        if not best.is_empty() and bd < 520.0 * 520.0:
                                var dirv := Vector2(float(best["x"]) - at.x,
                                        float(best["y"]) - at.y).normalized()
                                d["vx"] = dirv.x * 1100.0
                                d["vy"] = dirv.y * 1100.0
                                stopped = false
        else:
                _explode(at.x, at.y, 0.5)
                _decal(at.x)
        return stopped

func _update_eshots(delta: float) -> void:
        var dead: Array = []
        for s in eshots:
                var d: Dictionary = s
                d["t"] += delta
                if float(d.get("homing", 0.0)) > 0.0:
                        var ang := (Vector2(p_x, GROUND_Y - 90.0 * TANK_S)
                                - Vector2(d["x"], d["y"])).angle()
                        var cur := Vector2(d["vx"], d["vy"]).angle()
                        var na := cur + clampf(angle_difference(cur, ang),
                                -float(d["homing"]) * delta, float(d["homing"]) * delta)
                        var spd := Vector2(d["vx"], d["vy"]).length()
                        d["vx"] = cos(na) * spd
                        d["vy"] = sin(na) * spd
                if d["kind"] == "bomb" or d["kind"] == "bigbomb" \
                                or d["kind"] == "cluster" or d["kind"] == "shred":
                        d["vy"] += 420.0 * delta
                d["x"] += d["vx"] * delta
                d["y"] += d["vy"] * delta
                # THE CLUSTER BURST: the bomb tears open into shreds mid-air
                if d["kind"] == "cluster" and d["y"] >= float(d.get("burst_h", -1e9)):
                        _burst_shreds(Vector2(d["x"], d["y"]), 7, 6.0)
                        Jukebox.sfx("rw_shred", -6.0)
                        dead.append(d)
                        continue
                if d["x"] < -120.0 or d["x"] > W + 120.0 or d["y"] < -160.0 \
                                or d["y"] > H + 120.0:
                        dead.append(d)
                        continue
                if d["y"] > GROUND_Y - 8.0:
                        # THE BIG BOMB: a wide, hungry blast
                        if d["kind"] == "bigbomb":
                                _explode(d["x"], GROUND_Y - 14.0, 1.7)
                                _decal_big(d["x"])
                                shake = minf(shake + 7.0, 15.0)
                                Jukebox.sfx("rw_boom_big", -4.0)
                                var dist: float = absf(d["x"] - p_x)
                                if dist < 175.0 * TANK_S:
                                        _damage_player(roundf(22.0 * (1.0 - dist / (175.0 * TANK_S))) + 6.0)
                        elif d["kind"] == "bomb":
                                _explode(d["x"], GROUND_Y - 8.0, 0.75)
                                if absf(d["x"] - p_x) < 110.0 * TANK_S:
                                        _damage_player(float(d["dmg"]))
                        else:
                                _explode(d["x"], GROUND_Y - 8.0, 0.5)
                        dead.append(d)
                        continue
                # tank hitbox (v040-8: scaled with the tank) - the wide hull
                # slabs + the tall turret column
                if (absf(d["x"] - p_x) < 188.0 * TANK_S \
                                and d["y"] > GROUND_Y - 140.0 * TANK_S) \
                                or (absf(d["x"] - p_x) < 62.0 * TANK_S \
                                and d["y"] > GROUND_Y - 316.0 * TANK_S):
                        _damage_player(float(d["dmg"]))
                        _explode(d["x"], d["y"], 0.5)
                        dead.append(d)
        for d in dead:
                eshots.erase(d)

## the falling shrapnel: pops out of a point, falls, may hit the tank
func _burst_shreds(at: Vector2, n: int, dmg: float) -> void:
        for i in n:
                if eshots.size() >= 240:
                        return
                eshots.append({
                        "x": at.x + randf_range(-14, 14), "y": at.y,
                        "vx": randf_range(-320, 320), "vy": randf_range(-260, 60),
                        "dmg": dmg, "t": 0.0, "kind": "shred",
                        "rot": randf() * TAU, "vr": randf_range(-9, 9),
                })
        _explode(at.x, at.y, 0.55)

func _update_rockets(delta: float) -> void:
        var dead: Array = []
        for s in rockets:
                var r: Dictionary = s
                r["t"] += delta
                if r["t"] < float(r["launch"]):
                        r["vy"] -= 260.0 * delta
                        if r["vy"] < -600.0:
                                r["vy"] = -600.0
                else:
                        if (r["target"] == null or (r["target"] as Dictionary).is_empty() \
                                        or float((r["target"] as Dictionary).get("hp", 0.0)) <= 0.0 \
                                        or not enemies.has(r["target"])):
                                r["target"] = _nearest_enemy(float(r["x"]), float(r["y"]))
                        var tgt: Dictionary = r["target"]
                        if not tgt.is_empty():
                                var des := (Vector2(tgt["x"], tgt["y"])
                                        - Vector2(r["x"], r["y"])).angle()
                                var cur := Vector2(r["vx"], r["vy"]).angle()
                                var na := cur + clampf(angle_difference(cur, des),
                                        -float(r["homing"]) * delta, float(r["homing"]) * delta)
                                var spd := minf(900.0 * float(r.get("spd_mul", 1.0)),
                                        Vector2(r["vx"], r["vy"]).length() + 500.0 * delta)
                                r["vx"] = cos(na) * spd
                                r["vy"] = sin(na) * spd
                        else:
                                r["vy"] -= 200.0 * delta
                r["x"] += r["vx"] * delta
                r["y"] += r["vy"] * delta
                # the exhaust
                if randf() < 0.6:
                        _puff(Vector2(r["x"], r["y"]) - Vector2(r["vx"], r["vy"]).normalized() * 14.0)
                if r["x"] < -140.0 or r["x"] > W + 140.0 or r["y"] < -160.0:
                        dead.append(r)
                        continue
                var hit_e: Dictionary = {}
                for e in enemies:
                        var ee: Dictionary = e
                        var dx: float = r["x"] - float(ee["x"])
                        var dy: float = r["y"] - float(ee["y"])
                        var rad: float = float(ee["size"]) * 0.5 + 16.0
                        if dx * dx + dy * dy < rad * rad:
                                hit_e = ee
                                break
                if not hit_e.is_empty():
                        _damage_enemy(hit_e, float(r["dmg"]))
                        _explode(r["x"], r["y"], 0.9)
                        Jukebox.sfx("rw_boom_small", -8.0)
                        dead.append(r)
        for d in dead:
                rockets.erase(d)

func _nearest_enemy(x: float, y: float) -> Dictionary:
        var best: Dictionary = {}
        var bd := 1e18
        for e in enemies:
                var ee: Dictionary = e
                var dx: float = float(ee["x"]) - x
                var dy: float = float(ee["y"]) - y
                var dist := dx * dx + dy * dy
                if dist < bd:
                        bd = dist
                        best = ee
        return best

func _eshot_common(b: Dictionary, kind: String) -> void:
        b["kind"] = kind
        eshots.append(b)

func _eshot(pos: Vector2, vel: Vector2, dmg: float, kind: String) -> void:
        if eshots.size() >= 240:
                return
        var b := {"x": pos.x, "y": pos.y, "vx": vel.x, "vy": vel.y,
                "dmg": dmg, "t": 0.0, "homing": 2.2 if kind == "missile" else 0.0}
        _eshot_common(b, kind)

# ------------------------------------------------------------ damage/kill
func _damage_enemy(e: Dictionary, dmg: float) -> void:
        if e.is_empty() or dmg <= 0.0:
                return
        if float(e.get("shield", 0.0)) > 0.0:
                var sh := float(e["shield"]) - dmg
                if sh < 0.0:
                        e["shield"] = 0.0
                        e["hp"] = float(e["hp"]) + sh
                else:
                        e["shield"] = sh
        else:
                e["hp"] = float(e["hp"]) - dmg
        e["hit"] = 0.09
        if float(e["hp"]) <= 0.0:
                kill_enemy(e, true)

func kill_enemy(e: Dictionary, pay: bool) -> void:
        var is_boss: bool = String(e.get("kind", "")) == "boss"
        enemies.erase(e)
        if not pay:
                return
        # SCORE = KILLS (the owner's law): one kill, one point
        set_score(score + 1)
        coin_kills += 1
        # THE HONEST QUOTA (v040-8): only a real kill moves the wave's
        # kill count - a leaver never counts (a replacement keeps the
        # field full instead)
        if not is_boss and state == GS.PLACE \
                        and wave_state in ["spawning", "clearing"]:
                wave_quota_done += 1
        # XP ORBS: one orb = ONE point (the owner's law). No +XP cheats.
        var def: Dictionary = HWData.ENEMIES.get(String(e["kind"]), {})
        var xp_base: int = int(def.get("xp", 8)) if not is_boss \
                else int(e.get("xp", 60))
        var orbs := maxi(1, xp_base)
        for i in orbs:
                _drop(Vector2(e["x"], e["y"]), "xp", 1)
        # SCRAP: one piece = ONE scrap (the owner's law). No +scrap cheats.
        var scrap_base: int = int(def.get("scrap", 4)) if not is_boss \
                else int(e.get("scrap", 60))
        var pieces := maxi(1, scrap_base)
        if is_boss:
                # the boss's salvage rains down across the death chain
                for i in 7:
                        var t2 := get_tree().create_timer(0.13 * float(i))
                        var per := maxi(1, pieces / 7)
                        t2.timeout.connect(func():
                                if state in [GS.OVER]:
                                        return
                                for j in per:
                                        _drop(Vector2(float(e["x"]) + randf_range(-70, 70),
                                                float(e["y"]) + randf_range(-50, 50)), "scrap", 1))
        else:
                for i in pieces:
                        _drop(Vector2(e["x"] + randf_range(-16, 16),
                                e["y"] + randf_range(-10, 10)), "scrap", 1)
        # THE GOGACOIN LAW (v040-6): every 500th kill carries a REAL coin;
        # bosses pay 5 direct. No timer, no cheap arms.
        if is_boss:
                add_run_coins(HWData.BOSS_COINS)
                _fx_boom_chain(e["x"], e["y"])
                Jukebox.sfx("rw_boss_die", -2.0)
                _banner("BOSS DOWN  +" + str(HWData.BOSS_COINS) + " GOGACOINS", 2.0)
        elif coin_kills >= HWData.COIN_KILLS:
                coin_kills = 0
                _drop(Vector2(e["x"], e["y"]), "coin", 1)
        # SHREDS: heavy machines burst into falling shrapnel that may hit
        if not is_boss and int(def.get("shreds", 0)) > 0:
                _burst_shreds(Vector2(e["x"], e["y"]), int(def["shreds"]), 5.0)
                Jukebox.sfx("rw_shred", -9.0)
        if String(e.get("kind", "")) == "splitter":
                for i in 2:
                        _spawn_enemy("swarm")
        if is_boss:
                shake = minf(shake + 22.0, 24.0)
                flash = 0.6
        else:
                shake = minf(shake + 4.0, 24.0)
                _explode(e["x"], e["y"], 0.8)
                _sparks(Vector2(e["x"], e["y"]), Color(1, 1, 1), 8)
                Jukebox.sfx("rw_boom_small", -9.0)

func _damage_player(dmg: float) -> void:
        if p_invuln > 0.0 or state == GS.OVER:
                return
        var d := dmg * (1.0 - float(buffs["dr"]))
        if p_shield > 0.0:
                p_shield -= d
                if p_shield < 0.0:
                        p_hp += p_shield
                        p_shield = 0.0
                Jukebox.sfx("rw_shieldhit", -6.0)
        else:
                p_hp -= d
                Jukebox.sfx("rw_hurt", -4.0)
        p_invuln = 0.25
        damage_flash = minf(damage_flash + 0.55, 0.85)
        shake = minf(shake + 7.0, 16.0)
        if p_hp <= 0.0:
                p_hp = 0.0
                _game_over()

# ------------------------------------------------------------- pickups
func _magnet_radius() -> float:
        # the pickup pull grows with the level only - the magnet coil is
        # dead (the owner's no-cheat law)
        return minf(420.0, 160.0 + float(p_level) * 10.0)

func _drop(pos: Vector2, kind: String, value: int) -> void:
        if drops.size() >= 220:
                return
        drops.append({
                "x": pos.x, "y": pos.y, "vx": randf_range(-90, 90),
                "vy": randf_range(-220, -90), "kind": kind, "value": value,
                "t": randf() * 10.0, "life": 30.0, "grounded": false,
                "seed": randf() * 1000.0,
        })

func _update_drops(delta: float) -> void:
        var dead: Array = []
        var mag := _magnet_radius()
        var center := Vector2(p_x, GROUND_Y - 120.0 * TANK_S)
        for p in drops:
                var d: Dictionary = p
                d["t"] += delta
                d["life"] -= delta
                if d["life"] <= 0.0:
                        dead.append(d)
                        continue
                if not bool(d["grounded"]):
                        d["vy"] += 620.0 * delta
                        d["x"] += d["vx"] * delta
                        d["y"] += d["vy"] * delta
                        d["vx"] *= (1.0 - 1.4 * delta)
                        if d["y"] >= GROUND_Y - 16.0:
                                d["y"] = GROUND_Y - 16.0
                                d["vy"] = -float(d["vy"]) * 0.35
                                d["vx"] *= 0.55
                                if absf(float(d["vy"])) < 40.0:
                                        d["grounded"] = true
                                        d["vy"] = 0.0
                var dist := center.distance_to(Vector2(d["x"], d["y"]))
                if bool(d["grounded"]) and dist < mag:
                        var t := clampf((mag - dist) / mag, 0.0, 1.0)
                        var pull := (260.0 + t * 900.0) * delta
                        var dirv := (center - Vector2(d["x"], d["y"])).normalized()
                        d["x"] += dirv.x * pull
                        d["y"] += dirv.y * pull
                if dist < 34.0:
                        match String(d["kind"]):
                                "xp":
                                        _gain_xp(int(d["value"]))
                                        Jukebox.sfx("rw_pick_xp", -10.0,
                                                randf_range(0.9, 1.15))
                                "scrap":
                                        p_scrap += int(d["value"])
                                        Jukebox.sfx("rw_pick_scrap", -8.0,
                                                randf_range(0.92, 1.1))
                                "coin":
                                        add_run_coins(1)
                                        Jukebox.sfx("rw_pick_coin", -6.0)
                        _spark_ring(Vector2(d["x"], d["y"]),
                                THEME["xp"] if String(d["kind"]) == "xp"
                                else THEME["scrap"], 4)
                        dead.append(d)
                        continue
        for d in dead:
                drops.erase(d)

func _gain_xp(n: int) -> void:
        p_xp += n
        var guard := 0
        while p_xp >= p_xp_next and guard < 50:
                p_xp -= p_xp_next
                p_level += 1
                p_xp_next = maxi(20, int(round(float(p_xp_next) * 1.35)))
                level_up_queue += 1
                guard += 1
        if level_up_queue > 0 and state in [GS.PLACE, GS.BOSS] and not paused:
                _open_cards()

# ---------------------------------------------------------------- cards
var card_choices: Array = []

func _open_cards() -> void:
        if state == GS.OVER or card_choices.size() > 0:
                return
        var pool := HWData.CARDS.duplicate()
        pool.shuffle()
        card_choices = pool.slice(0, 3)
        paused = true
        get_tree().paused = true
        var vb := sheet_push(0.0, "cards")
        var t := Arc.label("LEVEL %d  -  CHOOSE ONE" % p_level, 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        var sub := Arc.label("tap a card - the choice is final", 18,
                Color("6a4a28"), false)
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(sub)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 12)
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        vb.add_child(row)
        # THE TAP LAW (the owner: "tapping on one does nothing"): this sheet
        # has NO BoxScroll, so TouchKit's emulated mouse clicks the Buttons
        # directly - the v040-4 killer was mouse_filter = IGNORE (the taps
        # landed on NOTHING). Leave every card a real, clickable Button.
        for c in card_choices:
                var cd: Dictionary = c
                var b := _card_button(cd)
                row.add_child(b)
        Jukebox.sfx("rw_levelup", -4.0)

func _card_button(cd: Dictionary) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(300, 320)
        var sb := Arc.panel_style(Arc.CARD, 22)
        sb.shadow_color = Color(0, 0, 0, 0.4)
        sb.shadow_size = 8
        b.add_theme_stylebox_override("normal", sb)
        b.add_theme_stylebox_override("hover", Arc.panel_style(Arc.CARD_2, 22))
        b.add_theme_stylebox_override("pressed", Arc.panel_style(Arc.CARD_2, 22))
        var v := VBoxContainer.new()
        v.set_anchors_preset(Control.PRESET_FULL_RECT)
        v.offset_top = 18
        v.offset_bottom = -14
        v.add_theme_constant_override("separation", 10)
        b.add_child(v)
        # THE CARD ICON: code-drawn (smooth steel, the theme), never a sprite
        var ic := Control.new()
        ic.custom_minimum_size = Vector2(0, 120)
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        ic.draw.connect(func():
                _draw_card_icon(ic, String(cd["icon"]), ic.size * 0.5))
        ic.resized.connect(func(): ic.queue_redraw())
        v.add_child(ic)
        var name_l := Arc.label(String(cd["name"]), 24, Arc.INK)
        name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        v.add_child(name_l)
        var desc := Arc.label(String(cd["desc"]), 18, Color("6a4a28"), false)
        desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        v.add_child(desc)
        b.pressed.connect(func(): _pick_card(cd))
        return b

## the code-drawn card icons: steel-gray shapes, one glyph per card
func _draw_card_icon(c: Control, id: String, at: Vector2) -> void:
        var bg := Color(0.05, 0.06, 0.08)
        var steel := THEME["accent"]
        var hot := Color("d8b060")
        c.draw_circle(at, 52.0, steel)
        c.draw_circle(at, 43.0, bg)
        match id:
                "dmg":
                        for a in 8:
                                var dv := Vector2.from_angle(TAU * a / 8.0)
                                c.draw_line(at + dv * 14.0, at + dv * 32.0, hot, 4.0)
                        c.draw_circle(at, 10.0, hot)
                "rate":
                        c.draw_colored_polygon(PackedVector2Array([
                                at + Vector2(6, -30), at + Vector2(-14, 4),
                                at + Vector2(-1, 4), at + Vector2(-6, 30),
                                at + Vector2(14, -4), at + Vector2(1, -4)]), hot)
                "speed":
                        c.draw_arc(at, 26.0, 0, TAU, 32, steel, 5.0)
                        for w in 3:
                                var wa := TAU * float(w) / 3.0
                                c.draw_line(at, at + Vector2.from_angle(wa) * 24.0, steel, 3.0)
                        c.draw_circle(at, 6.0, hot)
                "hull":
                        c.draw_rect(Rect2(at - Vector2(24, 20), Vector2(48, 40)),
                                steel)
                        c.draw_rect(Rect2(at - Vector2(16, 12), Vector2(32, 24)), bg)
                        c.draw_circle(at, 6.0, hot)
                "heal":
                        c.draw_rect(Rect2(at - Vector2(7, 26), Vector2(14, 52)), hot)
                        c.draw_rect(Rect2(at - Vector2(26, 7), Vector2(52, 14)), hot)
                "pierce":
                        c.draw_line(at + Vector2(-26, 0), at + Vector2(22, 0), hot, 5.0)
                        c.draw_colored_polygon(PackedVector2Array([
                                at + Vector2(32, 0), at + Vector2(16, -10),
                                at + Vector2(16, 10)]), hot)
                "boom":
                        c.draw_circle(at + Vector2(0, 6), 18.0, steel)
                        c.draw_line(at + Vector2(2, -12), at + Vector2(12, -26), hot, 4.0)
                        c.draw_circle(at + Vector2(15, -29), 5.0, hot)
                "leech":
                        c.draw_colored_polygon(PackedVector2Array([
                                at + Vector2(0, 28), at + Vector2(-16, -2),
                                at + Vector2(-8, -18), at + Vector2(0, -6),
                                at + Vector2(8, -18), at + Vector2(16, -2)]), hot)
                "multi":
                        for s in 3:
                                c.draw_circle(at + Vector2(float(s - 1) * 20.0, 0),
                                        8.0, hot)
                "armor":
                        c.draw_colored_polygon(PackedVector2Array([
                                at + Vector2(0, -28), at + Vector2(24, -16),
                                at + Vector2(24, 8), at + Vector2(0, 28),
                                at + Vector2(-24, 8), at + Vector2(-24, -16)]), steel)
                        c.draw_colored_polygon(PackedVector2Array([
                                at + Vector2(0, -18), at + Vector2(15, -10),
                                at + Vector2(15, 6), at + Vector2(0, 18),
                                at + Vector2(-15, 6), at + Vector2(-15, -10)]), bg)
                "cd":
                        c.draw_arc(at, 26.0, 0, TAU, 32, steel, 5.0)
                        c.draw_line(at, at + Vector2(0, -16), steel, 4.0)
                        c.draw_line(at, at + Vector2(11, 5), hot, 4.0)
                "shield":
                        c.draw_arc(at, 26.0, 0, TAU, 32, Color("78b8d8"), 5.0)
                        c.draw_arc(at, 17.0, 0, TAU, 32, Color("78b8d8", 0.5), 3.0)
                "crit":
                        for st in 5:
                                var sa := -PI / 2.0 + TAU * float(st) / 5.0
                                var s2 := Vector2.from_angle(sa)
                                c.draw_line(at + s2 * 6.0, at + s2 * 26.0, hot, 5.0)
                                c.draw_line(at + s2.rotated(0.2) * 6.0,
                                        at + s2.rotated(0.2) * 20.0, hot, 3.0)
                                c.draw_line(at + s2.rotated(-0.2) * 6.0,
                                        at + s2.rotated(-0.2) * 20.0, hot, 3.0)
                "bounce":
                        c.draw_polyline(PackedVector2Array([
                                at + Vector2(-26, 18), at + Vector2(-8, -16),
                                at + Vector2(8, 16), at + Vector2(26, -18)]), hot, 5.0)
                "slow":
                        for sn in 6:
                                var sa := TAU * float(sn) / 6.0
                                c.draw_line(at, at + Vector2.from_angle(sa) * 26.0,
                                        Color("9fd0e8"), 4.0)
                                c.draw_line(at + Vector2.from_angle(sa) * 16.0,
                                        at + Vector2.from_angle(sa) * 26.0
                                        + Vector2.from_angle(sa + PI / 2) * 6.0,
                                        Color("9fd0e8"), 3.0)
                _:
                        c.draw_circle(at, 20.0, steel)

func _pick_card(cd: Dictionary) -> void:
        match String(cd["id"]):
                "dmg": buffs["dmg"] = float(buffs["dmg"]) + 0.20
                "rate": buffs["rate"] = float(buffs["rate"]) + 0.18
                "speed": buffs["speed"] = float(buffs["speed"]) + 0.15
                "hull":
                        p_hp_max += 25.0
                        p_hp = minf(p_hp_max, p_hp + 25.0)
                "heal": p_hp = p_hp_max
                "pierce": buffs["pierce"] = int(buffs["pierce"]) + 1
                "explosive": buffs["explosive"] = int(buffs["explosive"]) + 1
                "lifesteal": buffs["lifesteal"] = float(buffs["lifesteal"]) + 0.03
                "multi": buffs["multi"] = int(buffs["multi"]) + 1
                "armor": buffs["dr"] = minf(0.65, float(buffs["dr"]) + 0.15)
                "cd": buffs["cd"] = float(buffs["cd"]) * 0.85
                "shield": p_shield = minf(120.0, p_shield + 40.0)
                "crit": buffs["crit"] = float(buffs["crit"]) + 0.10
                "bounce": buffs["bounce"] = 1
                "slow": buffs["slow"] = 1.0
        Jukebox.sfx("rw_card", -4.0)
        card_choices = []
        sheet_pop()

func _goga_sheet_popped(id: String) -> void:
        if id == "cards":
                card_choices = []
                # the queue: another level-up may still be waiting
                paused = false
                get_tree().paused = false
                if level_up_queue > 0:
                        level_up_queue -= 1
                        if level_up_queue > 0 and state in [GS.PLACE, GS.BOSS]:
                                _open_cards()
                # the ticker accrues again exactly here
        elif id == "shop":
                if paused:
                        paused = false
                        get_tree().paused = false
                _apply_skin()
        elif id == "boxshop":
                # v040-11 THE UNPAUSE LAW (the owner's freeze): the GOGABox
                # shop pauses the tree mid-run like any other sheet - its
                # close MUST lift that pause too. (The missing branch left
                # the tree paused forever: the frozen game.) The raw-tap
                # leak that could start a run behind the shop is dead in
                # the base's SHEET INPUT LAW.
                if paused:
                        paused = false
                        get_tree().paused = false
                _apply_skin()

# --------------------------------------------------------------- tunnel
# THE TUNNEL LAW (v040-6): NO teleport. The tunnel is part of the world -
# a concrete PORTAL rides in from the right (the world's own scroll), the
# tank DRIVES THROUGH it under a rock ceiling with ribs and lights and a
# calm coin trail, the place swaps BEHIND the walls, and the drive ends
# in the next place's daylight. (The Zombie Tsunami law: the world is
# connected - you see the mouth, you drive it, you come out the other
# side.)
var tunnel := {}
var tunnel_node: Node2D

func _enter_tunnel() -> void:
        state = GS.TUNNEL
        # v040-10 THE PLAIN PASSAGE LAW (the owner: "it should be part of
        # place to make you go from-to normally and not like the current
        # weird AISlop thing"): NO portal mouth, NO pillar show, NO lamp
        # glow - the road simply runs UNDER the place's own rock overpass,
        # the same rock the world is made of, and comes out in daylight.
        tunnel = {"t": 0.0, "phase": "inside", "inside_t": 0.0,
                "out_t": 0.0, "swapped": false, "coin_t": 0.0}
        enemies.clear()
        eshots.clear()
        boss_ent = {}
        Jukebox.sfx("rw_tunnel", -6.0)
        _banner("THE TUNNEL AHEAD", 1.8)
        if tunnel_node == null or not is_instance_valid(tunnel_node):
                tunnel_node = Node2D.new()
                tunnel_node.z_index = 40
                tunnel_node.draw.connect(_draw_tunnel)
                add_child(tunnel_node)

func _end_tunnel() -> void:
        tunnel = {}
        if tunnel_node != null and is_instance_valid(tunnel_node):
                tunnel_node.queue_free()
        tunnel_node = null
        _start_place()

func _draw_tunnel() -> void:
        if tunnel.is_empty() or tunnel_node == null:
                return
        var t: Dictionary = tunnel
        var phase := String(t["phase"])
        # the overpass rock wears the PLACE'S OWN stone colors - it is part
        # of the place, not a stage prop
        var pc: Dictionary = HWData.PLACES[place_i % 10]
        var rock := Color(pc["ground"])
        var rock_hi := Color(pc["ground_top"])
        var rock_lo := Color(pc["ground"].darkened(0.45))
        # ---- INSIDE / OUT: the rock ceiling closes over the world ----
        var opening := 0.0
        if phase == "out":
                opening = clampf(float(t["out_t"]) / 0.7, 0.0, 1.0)
        var ceil_bot: float = lerpf(GROUND_Y - 96.0, -80.0, opening)
        # the rock body (covers the sky; the road stays open)
        tunnel_node.draw_rect(Rect2(-40, -40, W + 80, ceil_bot + 40.0),
                Color(rock.r * 0.55, rock.g * 0.55, rock.b * 0.55, 0.99))
        # the jagged rock edge riding the world scroll (the place's stone)
        var step := 96.0
        var off := fposmod(scroll_x, step)
        var pts := PackedVector2Array()
        pts.append(Vector2(-40, ceil_bot - 42.0))
        var x := -off
        while x < W + step:
                var jag := 26.0 + sin(x * 0.045 + scroll_x * 0.01) * 14.0
                pts.append(Vector2(x, ceil_bot - jag))
                x += step
        pts.append(Vector2(W + 40, ceil_bot - 42.0))
        tunnel_node.draw_colored_polygon(pts, rock)
        for i in range(1, pts.size() - 1):
                tunnel_node.draw_line(pts[i], pts[i + 1], rock_hi, 4.0)
        # steel ribs every 300px - the tunnel's honest bones, dim and quiet
        var ro := fposmod(scroll_x, 300.0)
        var rx := -ro
        while rx < W + 300.0:
                tunnel_node.draw_line(Vector2(rx, -40),
                        Vector2(rx, ceil_bot - 30.0),
                        Color(0.18, 0.19, 0.22, 0.55), 6.0)
                rx += 300.0
        # the day's light spills in from the far end while the walls close
        var spill: float = clampf((float(t["inside_t"]) - 2.2) / 1.2,
                0.0, 1.0) if phase == "inside" else 0.0
        if spill > 0.0:
                tunnel_node.draw_rect(Rect2(W - 300.0 * spill, -40,
                        300.0 * spill + 40.0, ceil_bot + 40.0),
                        Color(HWData.PLACES[(place_i + 1) % 10]["sky_bot"],
                                0.5 * spill))

func _tick_tunnel(delta: float) -> void:
        var t: Dictionary = tunnel
        t["t"] += delta
        match String(t["phase"]):
                "inside":
                        _tick_world_scroll(delta, 2.6)
                        t["inside_t"] = float(t["inside_t"]) + delta
                        # the calm coin trail pays the drive
                        t["coin_t"] = float(t["coin_t"]) - delta
                        if float(t["coin_t"]) <= 0.0:
                                t["coin_t"] = 0.55
                                for i in 3:
                                        _drop(Vector2(W + 60.0 + float(i) * 46.0,
                                                GROUND_Y - 88.0), "coin", 1)
                        # the place swaps BEHIND the walls
                        if not bool(t["swapped"]) and float(t["inside_t"]) >= 1.9:
                                t["swapped"] = true
                                place_i += 1
                                if place_i % 10 == 0 and place_i > 0:
                                        loop += 1
                                wave = 1
                                drops.clear()
                                _sky_node()
                        if float(t["inside_t"]) >= 3.4:
                                t["phase"] = "out"
                                t["out_t"] = 0.0
                "out":
                        _tick_world_scroll(delta, 2.2)
                        t["out_t"] = float(t["out_t"]) + delta
                        if float(t["out_t"]) >= 0.8:
                                _end_tunnel()
        if tunnel_node != null and is_instance_valid(tunnel_node):
                tunnel_node.queue_redraw()

# -------------------------------------------------------------------- fx
# THE SMOOTH LAW: everything is a soft additive circle, never a sprite.
func _fx_push(p: Dictionary) -> void:
        if fx.size() >= 500:
                return
        fx.append(p)

func _explode(x: float, y: float, sc: float) -> void:
        # the shockwave + the fireball + the embers
        _fx_push({"kind": "wave", "x": x, "y": y, "t": 0.0,
                "life": 0.30, "r0": 6.0, "r1": 90.0 * sc})
        _fx_push({"kind": "fire", "x": x, "y": y, "t": 0.0,
                "life": 0.34, "r": 46.0 * sc})
        for i in int(7.0 * sc):
                var a := randf() * TAU
                var s := randf_range(60, 300) * sc
                _fx_push({"kind": "ember", "x": x, "y": y,
                        "vx": cos(a) * s, "vy": sin(a) * s - 60.0 * sc,
                        "t": 0.0, "life": randf_range(0.3, 0.75),
                        "r": randf_range(2.5, 5.5) * sc,
                        "col": Color(1.0, randf_range(0.5, 0.8), 0.25)})
        for i in int(3.0 * sc):
                _fx_push({"kind": "smoke", "x": x + randf_range(-14, 14),
                        "y": y + randf_range(-10, 10),
                        "vx": randf_range(-40, 40), "vy": randf_range(-90, -30),
                        "t": 0.0, "life": randf_range(0.5, 1.0),
                        "r": randf_range(12, 24) * sc})

func _muzzle(at: Vector2) -> void:
        _fx_push({"kind": "fire", "x": at.x, "y": at.y, "t": 0.0,
                "life": 0.10, "r": 26.0})
        _sparks(at, Color(1.0, 0.87, 0.4), 6)

func _sparks(at: Vector2, col: Color, n: int) -> void:
        for i in n:
                var a := randf() * TAU
                var s := randf_range(50, 240)
                _fx_push({"kind": "ember", "x": at.x, "y": at.y,
                        "vx": cos(a) * s, "vy": sin(a) * s,
                        "t": 0.0, "life": randf_range(0.12, 0.3),
                        "r": randf_range(1.8, 3.6), "col": col})

func _spark_ring(at: Vector2, col: Color, n: int) -> void:
        for i in n:
                var a := TAU * float(i) / float(n) + randf() * 0.6
                _fx_push({"kind": "ember", "x": at.x, "y": at.y,
                        "vx": cos(a) * randf_range(50, 160),
                        "vy": sin(a) * randf_range(50, 160),
                        "t": 0.0, "life": 0.28, "r": 2.8, "col": col})

func _puff(at: Vector2) -> void:
        _fx_push({"kind": "puff", "x": at.x, "y": at.y,
                "vx": randf_range(-20, 20), "vy": randf_range(-10, 30),
                "t": 0.0, "life": 0.32, "r": randf_range(4, 8)})

func _fx_boom_chain(x: float, y: float) -> void:
        for i in 6:
                var t2 := get_tree().create_timer(0.13 * i)
                t2.timeout.connect(func():
                        if state != GS.OVER:
                                _explode(x + randf_range(-90, 90),
                                        y + randf_range(-60, 60), 1.1))

func _update_fx(delta: float) -> void:
        var dead: Array = []
        for f in fx:
                var d: Dictionary = f
                d["t"] += delta
                if d.has("vx"):
                        d["x"] = float(d["x"]) + float(d["vx"]) * delta
                        d["y"] = float(d["y"]) + float(d["vy"]) * delta
                if String(d["kind"]) == "ember":
                        d["vy"] = float(d["vy"]) + 240.0 * delta
                if float(d["t"]) >= float(d["life"]):
                        dead.append(d)
        for d in dead:
                fx.erase(d)

func _decal(x: float) -> void:
        if decals.size() > 26:
                decals.pop_front()
        decals.append({"x": x, "t": 0.0, "r": randf_range(16, 26)})

func _decal_big(x: float) -> void:
        if decals.size() > 26:
                decals.pop_front()
        decals.append({"x": x, "t": 0.0, "r": randf_range(46, 62)})

# =================================================================
# THE ENTITY RENDER - every enemy, boss, shot and drop is CODE-DRAWN.
# Shapes face +x (nose right) and mirror by dir. Steel colors with one
# accent per kind; a hit flashes the whole shape white.
# =================================================================
func _flashed(e: Dictionary, base: Color) -> Color:
        return Color(6, 6, 6) if float(e.get("hit", 0.0)) > 0.0 else base

func _epts(e: Dictionary, pts: Array) -> PackedVector2Array:
        # enemy-local points -> world, mirrored by dir; a rotated machine
        # (the diving kamikaze) turns its nose toward e["ang"] - the mirror
        # keeps the base facing, the rotation adds only the DELTA past it,
        # so the body never flips upside down mid-turn
        var out := PackedVector2Array()
        var has_rot: bool = e.has("ang") and String(e.get("move", "")) == "dive"
        var dir := float(e["dir"])
        var base := 0.0 if dir > 0.0 else PI
        var delta_a := angle_difference(base, float(e.get("ang", base))) \
                if has_rot else 0.0
        for p in pts:
                var v := Vector2(float(p[0]) * dir, float(p[1]))
                if has_rot:
                        v = v.rotated(delta_a)
                out.append(Vector2(float(e["x"]), float(e["y"])) + v)
        return out

func _epoly(e: Dictionary, pts: Array, col: Color) -> void:
        ent_draw.draw_colored_polygon(_epts(e, pts), _flashed(e, col))

func _eoutline(e: Dictionary, pts: Array, col: Color, w := 2.0) -> void:
        var pp := _epts(e, pts)
        pp.append(pp[0])
        ent_draw.draw_polyline(pp, _flashed(e, col), w)

func _ecirc(e: Dictionary, dx: float, dy: float, r: float, col: Color) -> void:
        ent_draw.draw_circle(Vector2(float(e["x"]) + dx * float(e["dir"]),
                float(e["y"]) + dy), r, _flashed(e, col))

func _draw_enemies() -> void:
        if state == GS.TUNNEL:
                return   # the tunnel drive is a calm road - no enemies
        for e in enemies:
                var d: Dictionary = e
                if String(d.get("kind", "")) == "boss":
                        _draw_boss(d)
                        continue
                _draw_enemy_kind(d)
                _draw_health_bar(d)
        # the shadow lancers' beams
        for e in enemies:
                var d: Dictionary = e
                if String(d.get("weapon", "")) == "laser" and bool(d.get("laser_on", false)):
                        var lx: float = float(d["x"])
                        var a := 0.55 + sin(d["t"] * 20.0) * 0.2
                        ent_draw.draw_line(Vector2(lx, float(d["y"]) + 20.0),
                                Vector2(lx, GROUND_Y), Color(1.0, 0.4, 0.3, a), 10.0)
                        ent_draw.draw_line(Vector2(lx, float(d["y"]) + 20.0),
                                Vector2(lx, GROUND_Y), Color(1.0, 0.85, 0.6, a), 3.0)
                        ent_draw.draw_circle(Vector2(lx, GROUND_Y - 4.0),
                                16.0 + sin(d["t"] * 14.0) * 4.0, Color(1.0, 0.5, 0.3, 0.5))

func _draw_health_bar(e: Dictionary) -> void:
        if float(e["hp"]) >= float(e["maxhp"]):
                return
        var w := float(e["size"]) * 1.4
        var x := float(e["x"]) - w * 0.5
        var y := float(e["y"]) - float(e["size"]) - 16.0
        ent_draw.draw_rect(Rect2(x - 1, y - 1, w + 2, 7), Color(0, 0, 0, 0.65))
        var pct := clampf(float(e["hp"]) / float(e["maxhp"]), 0.0, 1.0)
        var col := Color("8ec894") if pct > 0.5 \
                else (Color("c8b068") if pct > 0.25 else Color("b87070"))
        ent_draw.draw_rect(Rect2(x, y, w * pct, 5), col)
        if float(e.get("shield", 0.0)) > 0.0:
                ent_draw.draw_arc(Vector2(e["x"], e["y"]), float(e["size"]) * 1.15,
                        0, TAU, 32, Color(THEME["shield"], 0.7), 2.5)

func _draw_enemy_kind(e: Dictionary) -> void:
        match String(e["kind"]):
                "scout":
                        # a hornet-dart: two-tone wings, a hot canopy, a
                        # twin exhaust that flickers
                        var eng := 0.5 + 0.5 * sin(e["t"] * 26.0)
                        _epoly(e, [[2, -5], [-10, -20], [-26, -20], [-19, -4]], Color("551410"))
                        _epoly(e, [[2, 5], [-10, 20], [-26, 20], [-19, 4]], Color("551410"))
                        _epoly(e, [[26, 0], [10, -10], [-14, -9], [-26, 0], [-14, 9], [10, 10]], Color("c04a38"))
                        _epoly(e, [[22, 0], [8, -4], [-8, -3], [-8, 3], [8, 4]], Color("e0785a"))
                        _eoutline(e, [[26, 0], [10, -10], [-14, -9], [-26, 0], [-14, 9], [10, 10]], Color("2a0808"), 2.0)
                        _ecirc(e, 8, -1, 5.0, Color("8fd8ff"))
                        _ecirc(e, -26, 0, 3.0 + eng * 2.0, Color(1.0, 0.62, 0.25, 0.85))
                "fighter":
                        # a swept warbird: layered steel, wing stripes, a
                        # glowing intake
                        var eng2 := 0.5 + 0.5 * sin(e["t"] * 20.0)
                        _epoly(e, [[4, -6], [-14, -30], [-34, -30], [-25, -6]], Color("12283c"))
                        _epoly(e, [[4, 6], [-14, 30], [-34, 30], [-25, 6]], Color("12283c"))
                        _epoly(e, [[36, 0], [16, -11], [-8, -10], [-32, -7], [-32, 7], [-8, 10], [16, 11]], Color("2c5a8a"))
                        _epoly(e, [[30, 0], [12, -5], [-10, -4], [-10, 4], [12, 5]], Color("4a7aa8"))
                        _eoutline(e, [[36, 0], [16, -11], [-8, -10], [-32, -7], [-32, 7], [-8, 10], [16, 11]], Color("03101d"), 2.0)
                        _ecirc(e, 15, -2, 7.0, Color("a0e8ff"))
                        _epoly(e, [[-6, -8], [2, -8], [2, -5], [-6, -5]], Color("6ab0d8"))
                        _epoly(e, [[-6, 8], [2, 8], [2, 5], [-6, 5]], Color("6ab0d8"))
                        _ecirc(e, -32, 0, 3.6 + eng2 * 2.4, Color(1.0, 0.66, 0.3, 0.85))
                "bomber":
                        # a twin-engine heavy: engine nacelles, a bomb-bay
                        # seam, a lit cockpit
                        _epoly(e, [[2, -8], [-16, -38], [-42, -38], [-30, -8]], Color("3a1408"))
                        _epoly(e, [[2, 8], [-16, 38], [-42, 38], [-30, 8]], Color("3a1408"))
                        _epoly(e, [[50, 0], [28, -16], [-2, -15], [-48, -12], [-52, 0], [-48, 12], [-2, 15], [28, 16]], Color("8a3a1a"))
                        _epoly(e, [[42, 0], [24, -8], [-4, -7], [-4, 7], [24, 8]], Color("a85a30"))
                        _eoutline(e, [[50, 0], [28, -16], [-2, -15], [-48, -12], [-52, 0], [-48, 12], [-2, 15], [28, 16]], Color("1a0603"), 2.4)
                        _ecirc(e, 25, -3, 9.0, Color("ffddaa"))
                        _ecirc(e, 27, 0, 4.0, Color("5a5a5a"))
                        _epoly(e, [[-8, 8], [18, 8], [18, 12], [-8, 12]], Color("140a06"))
                        _ecirc(e, -30, -14, 5.0, Color("2a2a2a"))
                        _ecirc(e, -30, 14, 5.0, Color("2a2a2a"))
                "heli":
                        _epoly(e, [[-48, -4], [-6, -8], [-6, 8], [-48, 4]], Color("5a3010"))
                        _ecirc(e, 0, 0, 27.0, Color("b05a1c"))
                        _eoutline(e, [[24, -12], [-20, -14], [-26, 0], [-20, 14], [24, 12]], Color("2a0c02"), 2.4)
                        _ecirc(e, 14, -2, 10.0, Color("9fe4ff"))
                        # the rotor: a spinning blade pair
                        var ra := fmod(e["t"] * 26.0, TAU)
                        var rlen := 44.0 * absf(sin(ra))
                        ent_draw.draw_line(
                                Vector2(float(e["x"]) - rlen, float(e["y"]) - 30.0),
                                Vector2(float(e["x"]) + rlen, float(e["y"]) - 30.0),
                                Color(0.12, 0.12, 0.12, 0.9), 5.0)
                "kamikaze":
                        # THE SUICIDE DART: a bomb with fins, a blinking
                        # armed light, and a dive trail it wears with pride
                        if bool(e.get("diving", false)):
                                ent_draw.draw_circle(Vector2(e["x"], e["y"]), 26.0,
                                        Color(1.0, 0.4, 0.2, 0.2))
                        var armed := fmod(e["t"], 0.4) < 0.2
                        _epoly(e, [[28, 0], [6, -12], [-20, -9], [-24, 0], [-20, 9], [6, 12]], Color("8a1a5a"))
                        _epoly(e, [[20, 0], [6, -5], [-10, -4], [-10, 4], [6, 5]], Color("b83a80"))
                        _eoutline(e, [[28, 0], [6, -12], [-20, -9], [-24, 0], [-20, 9], [6, 12]], Color("1a0410"), 2.0)
                        _epoly(e, [[-16, -3], [-9, -3], [-9, 3], [-16, 3]], Color("ffdd00"))
                        _ecirc(e, 10, 0, 3.4,
                                Color(1.0, 0.3, 0.2, 0.95) if armed else Color(0.4, 0.1, 0.1))
                "raider":
                        # THE ROCKET RUNNER: a needle-thin interceptor with
                        # a hot afterburner, rain tanks under its wings -
                        # faster than anything else in the sky
                        var burn := 0.6 + 0.4 * sin(e["t"] * 34.0)
                        _epoly(e, [[0, -4], [-14, -24], [-30, -22], [-20, -4]], Color("5a2410"))
                        _epoly(e, [[0, 4], [-14, 24], [-30, 22], [-20, 4]], Color("5a2410"))
                        _epoly(e, [[34, 0], [16, -8], [-16, -7], [-30, 0], [-16, 7], [16, 8]], Color("b86228"))
                        _epoly(e, [[28, 0], [12, -3.4], [-12, -2.6], [-12, 2.6], [12, 3.4]], Color("e09048"))
                        _eoutline(e, [[34, 0], [16, -8], [-16, -7], [-30, 0], [-16, 7], [16, 8]], Color("2a1004"), 2.0)
                        _ecirc(e, 12, -1, 4.6, Color("ffd9a0"))
                        # the rain tanks: little rockets under each wing
                        for rt in 2:
                                var ry := -16.0 + float(rt) * 32.0
                                _epoly(e, [[-2, ry], [-8, ry - 3], [-16, ry - 3],
                                        [-16, ry + 3], [-8, ry + 3]], Color("8a3020"))
                        # the afterburner
                        _epoly(e, [[-30, -3], [-30 - 14.0 * burn, 0], [-30, 3]],
                                Color(1.0, 0.62, 0.2, 0.8))
                        _ecirc(e, -31, 0, 4.0 + burn * 3.0, Color(1.0, 0.8, 0.35, 0.9))
                "gunship":
                        _epoly(e, [[6, -9], [-8, -46], [-42, -46], [-32, -9]], Color("2a2a1e"))
                        _epoly(e, [[6, 9], [-8, 46], [-42, 46], [-32, 9]], Color("2a2a1e"))
                        _epoly(e, [[58, 0], [36, -20], [-4, -19], [-54, -15], [-60, 0], [-54, 15], [-4, 19], [36, 20]], Color("4a4a3a"))
                        _eoutline(e, [[58, 0], [36, -20], [-4, -19], [-54, -15], [-60, 0], [-54, 15], [-4, 19], [36, 20]], Color("0a0a06"), 2.6)
                        _ecirc(e, 29, -3, 10.0, Color("ffcc88"))
                        _epoly(e, [[10, -30], [24, -34], [24, -26], [12, -24]], Color("22221a"))
                        _epoly(e, [[10, 30], [24, 34], [24, 26], [12, 24]], Color("22221a"))
                "shielded":
                        _epoly(e, [[28, 0], [10, -15], [-24, -13], [-30, 0], [-24, 13], [10, 15]], Color("4a7aa0"))
                        _eoutline(e, [[28, 0], [10, -15], [-24, -13], [-30, 0], [-24, 13], [10, 15]], Color("04121e"), 2.2)
                        _ecirc(e, 2, -2, 6.0, Color("c8f0ff"))
                "splitter":
                        _ecirc(e, 0, 0, 21.0, Color("7a1a9a"))
                        _eoutline(e, [[21, 0], [15, -15], [0, -21], [-15, -15], [-21, 0], [-15, 15], [0, 21], [15, 15]], Color("3a0a4a"), 2.2)
                        _ecirc(e, 0, 0, 9.0, Color("b060d0"))
                "missile":
                        _epoly(e, [[30, -2], [22, -15], [-22, -15], [-28, 0], [-22, 15], [22, 15], [30, 2]], Color("8a3a5a"))
                        _eoutline(e, [[30, -2], [22, -15], [-22, -15], [-28, 0], [-22, 15], [22, 15], [30, 2]], Color("1a0410"), 2.2)
                        _epoly(e, [[-6, -21], [14, -21], [14, -14], [-6, -14]], Color("1a0410"))
                        _epoly(e, [[-6, 21], [14, 21], [14, 14], [-6, 14]], Color("1a0410"))
                        var eng := 0.5 + 0.5 * sin(e["t"] * 22.0)
                        _ecirc(e, -30, 0, 5.0 + eng * 3.0, Color(1.0, 0.6, 0.3, 0.85))
                "swarm":
                        _ecirc(e, 0, 0, float(e["size"]) * 0.55, Color("88ff44"))
                        _eoutline(e, [[10, 0], [5, -9], [-5, -9], [-10, 0], [-5, 9], [5, 9]], Color("2a5a10"), 1.6)
                "gtank":
                        ent_draw.draw_circle(Vector2(float(e["x"]), GROUND_Y + 2.0),
                                float(e["size"]) * 0.7, Color(0, 0, 0, 0.35))
                        _epoly(e, [[-float(e["size"]) * 0.8, float(e["size"]) * 0.25],
                                [float(e["size"]) * 0.8, float(e["size"]) * 0.25],
                                [float(e["size"]) * 0.8, -float(e["size"]) * 0.2],
                                [-float(e["size"]) * 0.8, -float(e["size"]) * 0.2]], Color("141414"))
                        _epoly(e, [[-float(e["size"]) * 0.7, -float(e["size"]) * 0.2],
                                [float(e["size"]) * 0.7, -float(e["size"]) * 0.2],
                                [float(e["size"]) * 0.6, -float(e["size"]) * 0.62],
                                [-float(e["size"]) * 0.6, -float(e["size"]) * 0.62]], Color("3a3a3a"))
                        _epoly(e, [[-float(e["size"]) * 0.32, -float(e["size"]) * 0.62],
                                [float(e["size"]) * 0.32, -float(e["size"]) * 0.62],
                                [float(e["size"]) * 0.26, -float(e["size"]) * 0.95],
                                [-float(e["size"]) * 0.26, -float(e["size"]) * 0.95]], Color("5a5a50"))
                        _eoutline(e, [[float(e["size"]) * 0.3, -float(e["size"]) * 0.78],
                                [float(e["size"]) * 1.2, -float(e["size"]) * 0.78]], Color("1a1a1a"), 5.0)
                "turret":
                        ent_draw.draw_circle(Vector2(float(e["x"]), GROUND_Y + 2.0),
                                float(e["size"]) * 0.7, Color(0, 0, 0, 0.35))
                        _ecirc(e, 0, 0, float(e["size"]) * 0.85, Color("1a1a1a"))
                        var ta := atan2((GROUND_Y - 120.0 * TANK_S) - float(e["y"]),
                                p_x - float(e["x"]))
                        if float(e["dir"]) < 0.0:
                                ta = PI - ta
                        ent_draw.draw_line(Vector2(e["x"], e["y"]),
                                Vector2(float(e["x"]) + cos(ta) * float(e["size"]) * 1.1 * float(e["dir"]),
                                        float(e["y"]) + sin(ta) * float(e["size"]) * 1.1),
                                Color("5a5a50"), 10.0)
                        _ecirc(e, 0, 0, float(e["size"]) * 0.4, Color("5a5a50"))
                "carpet":
                        # THE CARPET BOMBER: a fat flying wing + bay doors
                        _epoly(e, [[10, -10], [-30, -52], [-64, -46], [-70, 0], [-64, 46], [-30, 52], [10, 10]], Color("3a3428"))
                        _epoly(e, [[62, 0], [36, -18], [-6, -17], [-52, -13], [-58, 0], [-52, 13], [-6, 17], [36, 18]], Color("6a5c40"))
                        _eoutline(e, [[62, 0], [36, -18], [-6, -17], [-52, -13], [-58, 0], [-52, 13], [-6, 17], [36, 18]], Color("141008"), 2.6)
                        _ecirc(e, 30, -3, 10.0, Color("ffddaa"))
                        _epoly(e, [[-16, 16], [26, 16], [26, 22], [-16, 22]], Color("0e0c08"))
                        _ecirc(e, -58, 0, 7.0, Color(1.0, 0.6, 0.25, 0.7))
                "shredder":
                        # THE SHRED BOMBER: a spiky shell that screams danger
                        _epoly(e, [[30, 0], [12, -16], [-20, -14], [-32, 0], [-20, 14], [12, 16]], Color("5a4a20"))
                        for si in 5:
                                var sa := -0.9 + float(si) * 0.45
                                _epoly(e, [[cos(sa) * 30.0, sin(sa) * 30.0],
                                        [cos(sa) * 40.0, sin(sa) * 40.0],
                                        [cos(sa + 0.14) * 28.0, sin(sa + 0.14) * 28.0]], Color("8a7434"))
                        _eoutline(e, [[30, 0], [12, -16], [-20, -14], [-32, 0], [-20, 14], [12, 16]], Color("1c1404"), 2.2)
                        _ecirc(e, 4, -2, 7.0, Color("ffefb0"))
                "laserd":
                        # THE SHADOW LANCER: a hooded drone with a burning lens
                        _epoly(e, [[26, 0], [8, -18], [-24, -14], [-34, 0], [-24, 14], [8, 18]], Color("2a2438"))
                        _eoutline(e, [[26, 0], [8, -18], [-24, -14], [-34, 0], [-24, 14], [8, 18]], Color("0c0a14"), 2.2)
                        _ecirc(e, 6, -2, 6.0, Color("c8b8ff"))
                        var lens := 0.5 + 0.5 * sin(e["t"] * 8.0)
                        _ecirc(e, 0, 16, 5.0 + lens * 3.0, Color(1.0, 0.45, 0.35, 0.9))
                "hauler":
                        _epoly(e, [[8, -8], [-20, -40], [-46, -34], [-52, 0], [-46, 34], [-20, 40], [8, 8]], Color("2e3828"))
                        _epoly(e, [[50, 0], [30, -15], [-4, -14], [-46, -11], [-52, 0], [-46, 11], [-4, 14], [30, 15]], Color("4e5e42"))
                        _eoutline(e, [[50, 0], [30, -15], [-4, -14], [-46, -11], [-52, 0], [-46, 11], [-4, 14], [30, 15]], Color("0e140a"), 2.4)
                        _ecirc(e, 24, -3, 9.0, Color("e8ffe0"))
                        _epoly(e, [[-14, 13], [22, 13], [22, 19], [-14, 19]], Color("0a0e06"))
                "dustdevil":
                        var sw := sin(e["t"] * 9.0)
                        _epoly(e, [[26, 0], [6, -14 + sw * 4.0], [-18, -10 - sw * 4.0], [-28, 0], [-18, 10 + sw * 4.0], [6, 14 - sw * 4.0]], Color("9a6a3a"))
                        _eoutline(e, [[26, 0], [6, -14 + sw * 4.0], [-18, -10 - sw * 4.0], [-28, 0], [-18, 10 + sw * 4.0], [6, 14 - sw * 4.0]], Color("3a2408"), 2.0)
                        _ecirc(e, 2, 0, 6.0, Color("ffd9a0"))
                "frostmoth":
                        _epoly(e, [[4, -6], [-18, -32], [-36, -26], [-24, -4]], Color("1e3a52"))
                        _epoly(e, [[4, 6], [-18, 32], [-36, 26], [-24, 4]], Color("1e3a52"))
                        _epoly(e, [[30, 0], [12, -10], [-12, -9], [-28, 0], [-12, 9], [12, 10]], Color("7ab0d0"))
                        _eoutline(e, [[30, 0], [12, -10], [-12, -9], [-28, 0], [-12, 9], [12, 10]], Color("081826"), 2.0)
                        _ecirc(e, 8, -1, 6.0, Color("e8f8ff"))
                "cinderbat":
                        var fw := sin(e["t"] * 16.0) * 8.0
                        _epoly(e, [[16, 0], [-4, -18 - fw], [-22, -8], [-14, 0], [-22, 8], [-4, 18 + fw]], Color("4a1408"))
                        _ecirc(e, 4, 0, 7.0, Color("ff7030"))
                        _eoutline(e, [[16, 0], [-4, -18 - fw], [-22, -8], [-14, 0], [-22, 8], [-4, 18 + fw]], Color("1a0402"), 1.8)
                "sporewasp":
                        _epoly(e, [[24, 0], [8, -10], [-14, -8], [-24, 0], [-14, 8], [8, 10]], Color("5a7a20"))
                        _epoly(e, [[0, -8], [-16, -26], [-26, -20], [-10, -4]], Color("3a5214"))
                        _epoly(e, [[0, 8], [-16, 26], [-26, 20], [-10, 4]], Color("3a5214"))
                        _eoutline(e, [[24, 0], [8, -10], [-14, -8], [-24, 0], [-14, 8], [8, 10]], Color("142004"), 2.0)
                        var buzz := 0.5 + 0.5 * sin(e["t"] * 30.0)
                        _ecirc(e, -26, 0, 4.0 + buzz * 2.0, Color("c8ff60", 0.7))
                "shardray":
                        _epoly(e, [[34, 0], [12, -14], [-18, -10], [-34, 0], [-18, 10], [12, 14]], Color("5a3a7a"))
                        _epoly(e, [[6, -12], [-14, -30], [-28, -24], [-8, -8]], Color("442a60"))
                        _epoly(e, [[6, 12], [-14, 30], [-28, 24], [-8, 8]], Color("442a60"))
                        _eoutline(e, [[34, 0], [12, -14], [-18, -10], [-34, 0], [-18, 10], [12, 14]], Color("180826"), 2.2)
                        _ecirc(e, 6, -2, 6.0, Color("e0b0ff"))
                "cloudray":
                        _epoly(e, [[40, 0], [18, -14], [-14, -12], [-36, -6], [-36, 6], [-14, 12], [18, 14]], Color("7a8aa8"))
                        _epoly(e, [[8, -12], [-12, -28], [-30, -20], [-6, -8]], Color("5a6a88"))
                        _epoly(e, [[8, 12], [-12, 28], [-30, 20], [-6, 8]], Color("5a6a88"))
                        _eoutline(e, [[40, 0], [18, -14], [-14, -12], [-36, -6], [-36, 6], [-14, 12], [18, 14]], Color("18202e"), 2.2)
                        _ecirc(e, 12, -2, 7.0, Color("fff0a0"))
                "deptheel":
                        var und := sin(e["t"] * 6.0) * 6.0
                        _epoly(e, [[44, 0], [26, -10], [-2, -9 - und * 0.3], [-30, -6 + und], [-44, 0], [-30, 6 + und], [-2, 9 - und * 0.3], [26, 10]], Color("2a4a5e"))
                        _eoutline(e, [[44, 0], [26, -10], [-2, -9 - und * 0.3], [-30, -6 + und], [-44, 0], [-30, 6 + und], [-2, 9 - und * 0.3], [26, 10]], Color("06121a"), 2.2)
                        _epoly(e, [[30, -3], [40, -8], [40, 8], [30, 3]], Color("0e2230"))
                        _ecirc(e, 8, -2, 5.0, Color("a0e8ff"))
                "holodrone":
                        var ho := 0.6 + 0.4 * sin(e["t"] * 5.0)
                        _ecirc(e, 0, 0, float(e["size"]) * 0.6, Color("3a7a8a", 0.35 + ho * 0.2))
                        _epoly(e, [[22, 0], [6, -13], [-18, -10], [-26, 0], [-18, 10], [6, 13]], Color("58b8c8"))
                        _eoutline(e, [[22, 0], [6, -13], [-18, -10], [-26, 0], [-18, 10], [6, 13]], Color("0e2a30"), 1.8)
                        _ecirc(e, 0, 0, 5.0, Color("d8ffff"))
                "voidmaw":
                        _ecirc(e, 0, 0, float(e["size"]) * 0.5, Color("1a0a2e"))
                        _eoutline(e, [[26, 0], [18, -18], [0, -26], [-18, -18], [-26, 0], [-18, 18], [0, 26], [18, 18]], Color("aa44ff"), 2.6)
                        _ecirc(e, 0, 0, 10.0, Color("2a0a4a"))
                        _ecirc(e, 0, 0, 5.0, Color("e0b0ff"))
                        for ti in 6:
                                var ta2: float = float(e["t"]) * 2.0 + float(ti) * TAU / 6.0
                                ent_draw.draw_circle(Vector2(
                                        float(e["x"]) + cos(ta2) * float(e["size"]) * 0.75,
                                        float(e["y"]) + sin(ta2) * float(e["size"]) * 0.75),
                                        3.0, Color("aa44ff", 0.7))
                _:
                        _ecirc(e, 0, 0, float(e["size"]) * 0.5, Color("888888"))

func _draw_boss(b: Dictionary) -> void:
        var acc: Color = HWData.PLACES[place_i % 10]["accent"]
        var c1 := _flashed(b, Color("3a2030"))
        var c2 := _flashed(b, Color("5a3a4a"))
        var c3 := _flashed(b, Color("201018"))
        var s := float(b["size"])
        var x := float(b["x"])
        var y := float(b["y"])
        # enraged: the aura burns
        if bool(b.get("enraged", false)):
                ent_draw.draw_circle(Vector2(x, y), s * 1.25,
                        Color(acc, 0.10 + 0.05 * sin(b["t"] * 8.0)))
        match String(b["brain"]):
                "flyer":
                        _bpoly(b, [[10, -14], [-40, -70], [-90, -70], [-70, -14]], c1)
                        _bpoly(b, [[10, 14], [-40, 70], [-90, 70], [-70, 14]], c1)
                        _bpoly(b, [[92, 0], [62, -30], [0, -30], [-80, -22], [-88, 0], [-80, 22], [0, 30], [62, 30]], c2)
                        _boutline(b, [[92, 0], [62, -30], [0, -30], [-80, -22], [-88, 0], [-80, 22], [0, 30], [62, 30]], Color("0a0210"), 3.0)
                        _bpoly(b, [[-80, -54], [-54, -54], [-54, -38], [-80, -38]], c3)
                        _bpoly(b, [[-80, 38], [-54, 38], [-54, 54], [-80, 54]], c3)
                        _ecirc(b, 46, -4, 17.0, Color("a0e8ff"))
                        _ecirc(b, -84, -46, 8.0, Color(acc, 0.85))
                        _ecirc(b, -84, 46, 8.0, Color(acc, 0.85))
                "dropship":
                        _bpoly(b, [[-120, -50], [120, -50], [120, 40], [-120, 40]], c1)
                        _boutline(b, [[-120, -50], [120, -50], [120, 40], [-120, 40], [-120, -50]], Color("0a0210"), 3.0)
                        _bpoly(b, [[-95, -76], [-65, -76], [-65, -50], [-95, -50]], c3)
                        _bpoly(b, [[65, -76], [95, -76], [95, -50], [65, -50]], c3)
                        _ecirc(b, -80, -62, 8.0, Color(acc, 0.85))
                        _ecirc(b, 80, -62, 8.0, Color(acc, 0.85))
                        _bpoly(b, [[-118, -14], [118, -14], [118, 14], [-118, 14]], c2)
                        _bpoly(b, [[-46, -30], [46, -30], [46, -12], [-46, -12]], Color("a0e8ff"))
                        _bpoly(b, [[-55, 26], [55, 26], [55, 38], [-55, 38]], Color(0, 0, 0, 0.75))
                "sidewinder":
                        _bpoly(b, [[80, 0], [30, -22], [-40, -16], [-70, 0], [-40, 16], [30, 22]], c1)
                        _boutline(b, [[80, 0], [30, -22], [-40, -16], [-70, 0], [-40, 16], [30, 22]], Color("0a0210"), 2.6)
                        _bpoly(b, [[60, 0], [36, -10], [20, 0], [36, 10]], Color("a0e8ff"))
                        _bpoly(b, [[10, -10], [-15, -36], [-35, -30], [-20, -10]], c2)
                        _bpoly(b, [[10, 10], [-15, 36], [-35, 30], [-20, 10]], c2)
                        _ecirc(b, -70, 0, 10.0, Color(acc, 0.9))
                "fortress":
                        _bpoly(b, [[-140, -80], [140, -80], [140, 60], [-140, 60]], c1)
                        _boutline(b, [[-140, -80], [140, -80], [140, 60], [-140, 60], [-140, -80]], Color("0a0210"), 3.0)
                        _bpoly(b, [[-110, -100], [110, -100], [110, -74], [-110, -74]], c2)
                        _bpoly(b, [[-160, -30], [-130, -30], [-130, -12], [-160, -12]], c3)
                        _bpoly(b, [[130, -30], [160, -30], [160, -12], [130, -12]], c3)
                        _bpoly(b, [[-22, -70], [22, -70], [22, -30], [-22, -30]], c3)
                        ent_draw.draw_circle(Vector2(x, y), 40.0, Color(acc, 0.35))
                        _ecirc(b, 0, 0, 8.0 + sin(b["t"] * 5.0) * 2.0, Color(1, 1, 1, 0.9))
                        for i in 8:
                                var a2 := float(i) / 8.0 * TAU
                                _ecirc(b, cos(a2) * 70.0, sin(a2) * 55.0, 3.0, Color("888888"))
                "weaver":
                        _bpoly(b, [[70, 0], [40, -34], [-20, -40], [-70, -18], [-70, 18], [-20, 40], [40, 34]], c1)
                        _boutline(b, [[70, 0], [40, -34], [-20, -40], [-70, -18], [-70, 18], [-20, 40], [40, 34]], Color("0a0210"), 3.0)
                        for wi in 4:
                                var wa: float = float(b["t"]) * 3.0 + float(wi) * TAU / 4.0
                                _bpoly(b, [[-10, -14], [-10, 14], [-40, 10], [-40, -10]], c2)
                                ent_draw.draw_circle(Vector2(
                                        float(b["x"]) - 30.0 + cos(wa) * 14.0,
                                        float(b["y"]) + sin(wa) * (34.0 + float(wi) * 8.0)),
                                        7.0, Color(acc, 0.7))
                        _ecirc(b, 40, 0, 15.0, Color("c0f0ff"))
                "prime":
                        _bpoly(b, [[15, -20], [-50, -80], [-110, -80], [-80, -20]], c1)
                        _bpoly(b, [[15, 20], [-50, 80], [-110, 80], [-80, 20]], c1)
                        _bpoly(b, [[110, 0], [70, -36], [0, -36], [-90, -26], [-98, 0], [-90, 26], [0, 36], [70, 36]], c2)
                        _boutline(b, [[110, 0], [70, -36], [0, -36], [-90, -26], [-98, 0], [-90, 26], [0, 36], [70, 36]], Color("0a0210"), 3.0)
                        _ecirc(b, 50, -4, 20.0, Color("c0f0ff"))
                        _bpoly(b, [[-88, -70], [-66, -70], [-66, -56], [-88, -56]], c3)
                        _bpoly(b, [[-88, 56], [-66, 56], [-66, 70], [-88, 70]], c3)
                        _ecirc(b, -92, 0, 12.0, Color(acc, 0.85))
                        # THE CROWN: the prime's spikes
                        for ci in 5:
                                _bpoly(b, [[float(ci) * 22.0 - 50.0, -40.0],
                                        [float(ci) * 22.0 - 44.0, -58.0],
                                        [float(ci) * 22.0 - 38.0, -40.0]], Color("c060c0", 0.8))
                _:
                        _ecirc(b, 0, 0, s * 0.5, c2)

func _bpoly(b: Dictionary, pts: Array, col: Color) -> void:
        ent_draw.draw_colored_polygon(_epts(b, pts), _flashed(b, col))

func _boutline(b: Dictionary, pts: Array, col: Color, w := 2.6) -> void:
        _eoutline(b, pts, col, w)

# ------------------------------------------------------- shots & drops
func _draw_shots() -> void:
        if state == GS.TUNNEL:
                # the tunnel drive: the coin trail still shines
                _draw_drops()
                return
        # MY shots: shells = glowing orb + tail, MG = tracer line
        for s in shots:
                var d: Dictionary = s
                var pos := Vector2(d["x"], d["y"])
                var ang := Vector2(d["vx"], d["vy"]).angle()
                if String(d["kind"]) == "mg":
                        var n := Vector2.from_angle(ang)
                        var t0 := pos - n * 30.0
                        shot_draw.draw_line(t0, pos, Color(0.9, 0.94, 1.0, 0.85), 2.6)
                        shot_draw.draw_circle(pos, 1.8, Color(1, 1, 1))
                else:
                        var n2 := Vector2.from_angle(ang)
                        shot_draw.draw_line(pos - n2 * 34.0, pos,
                                Color(1.0, 0.55, 0.16, 0.0), 1.0)
                        # layered trail
                        shot_draw.draw_line(pos - n2 * 30.0, pos,
                                Color(1.0, 0.8, 0.35, 0.55), 6.0)
                        shot_draw.draw_line(pos - n2 * 16.0, pos,
                                Color(1.0, 0.94, 0.7, 0.9), 7.0)
                        shot_draw.draw_circle(pos, 6.0, Color(1.0, 0.86, 0.5, 0.95))
                        shot_draw.draw_circle(pos, 3.4, Color(1, 1, 0.92))
        # rockets
        for r in rockets:
                var rd: Dictionary = r
                var pos2 := Vector2(rd["x"], rd["y"])
                var ang2 := Vector2(rd["vx"], rd["vy"]).angle() + PI / 2
                shot_draw.draw_circle(pos2 + Vector2(0, 0), 15.0,
                        Color(1.0, 0.6, 0.2, 0.12))
                var pts := PackedVector2Array()
                for pp in [[0, -16], [4, -6], [4, 12], [-4, 12], [-4, -6]]:
                        pts.append(pos2 + Vector2(pp[0], pp[1]).rotated(ang2))
                shot_draw.draw_colored_polygon(pts, Color("8a8e96"))
                var nose := PackedVector2Array()
                for pp in [[0, -22], [4.5, -14], [-4.5, -14]]:
                        nose.append(pos2 + Vector2(pp[0], pp[1]).rotated(ang2))
                shot_draw.draw_colored_polygon(nose, Color("a03030"))
        # enemy shots
        for s in eshots:
                var d2: Dictionary = s
                var p2 := Vector2(d2["x"], d2["y"])
                match String(d2["kind"]):
                        "plasma":
                                shot_draw.draw_circle(p2, 11.0, Color(1.0, 0.94, 0.72, 0.25))
                                shot_draw.draw_circle(p2, 6.5, Color(1.0, 0.8, 0.3, 0.9))
                                shot_draw.draw_circle(p2, 3.0, Color(1, 0.98, 0.9))
                        "missile":
                                var ma := Vector2(d2["vx"], d2["vy"]).angle() + PI / 2
                                var mpts := PackedVector2Array()
                                for pp in [[0, -13], [4, -4], [4, 10], [-4, 10], [-4, -4]]:
                                        mpts.append(p2 + Vector2(pp[0], pp[1]).rotated(ma))
                                shot_draw.draw_colored_polygon(mpts, Color("2a2a30"))
                                shot_draw.draw_circle(p2 - Vector2(0, 14).rotated(ma),
                                        5.0 + randf() * 2.0, Color(1.0, 0.55, 0.25, 0.85))
                        "bomb":
                                var ba := Vector2(d2["vx"], d2["vy"]).angle() - PI / 2
                                var bpts := PackedVector2Array()
                                for pp in [[0, -12], [7, -4], [7, 8], [-7, 8], [-7, -4]]:
                                        bpts.append(p2 + Vector2(pp[0], pp[1]).rotated(ba))
                                shot_draw.draw_colored_polygon(bpts, Color("2c2f36"))
                                if fmod(d2["t"], 0.2) > 0.1:
                                        shot_draw.draw_circle(p2 + Vector2(0, -11).rotated(ba),
                                                2.4, Color(1.0, 0.24, 0.24))
                        "bigbomb":
                                var bba := Vector2(d2["vx"], d2["vy"]).angle() - PI / 2
                                var bbpts := PackedVector2Array()
                                for pp in [[0, -20], [12, -8], [12, 14], [-12, 14], [-12, -8]]:
                                        bbpts.append(p2 + Vector2(pp[0], pp[1]).rotated(bba))
                                shot_draw.draw_colored_polygon(bbpts, Color("23262c"))
                                shot_draw.draw_circle(p2 + Vector2(0, -18).rotated(bba),
                                        4.0, Color(1.0, 0.2, 0.2) if fmod(d2["t"], 0.24) > 0.12
                                        else Color(0.4, 0.1, 0.1))
                        "cluster":
                                var cba := Vector2(d2["vx"], d2["vy"]).angle() - PI / 2
                                var cbpts := PackedVector2Array()
                                for pp in [[0, -14], [9, -6], [9, 10], [-9, 10], [-9, -6]]:
                                        cbpts.append(p2 + Vector2(pp[0], pp[1]).rotated(cba))
                                shot_draw.draw_colored_polygon(cbpts, Color("5a4a20"))
                                shot_draw.draw_circle(p2, 3.0,
                                        Color(1.0, 0.9, 0.4) if fmod(d2["t"], 0.16) > 0.08
                                        else Color(0.5, 0.4, 0.1))
                        "shred":
                                var sr: float = float(d2.get("rot", 0.0)) \
                                        + float(d2.get("vr", 0.0)) * float(d2["t"])
                                var spts := PackedVector2Array()
                                for pp in [[0, -9], [7, 6], [-7, 6]]:
                                        spts.append(p2 + Vector2(pp[0], pp[1]).rotated(sr))
                                shot_draw.draw_colored_polygon(spts, Color("9aa2ae"))
                                shot_draw.draw_polyline(spts + PackedVector2Array([spts[0]]),
                                        Color("3a3e46"), 1.4)
        _draw_drops()

## THE DROPS: xp orbs / scrap cogs / the REAL GOGACoin (gold disc, dark
## rim, the box's own G - the owner: "it should really drop and look
## like a gogacoin normally").
func _draw_drops() -> void:
        for p in drops:
                var d3: Dictionary = p
                var flick: bool = float(d3["life"]) < 3.0 \
                        and fmod(float(d3["life"]), 0.3) <= 0.12
                if flick:
                        continue
                var p3 := Vector2(d3["x"], d3["y"]) + Vector2(0, sin(d3["t"] * 4.0) * 2.0)
                match String(d3["kind"]):
                        "xp":
                                var pulse := 1.0 + sin(d3["t"] * 6.0 + float(d3["seed"])) * 0.12
                                shot_draw.draw_circle(p3, 16.0 * pulse,
                                        Color(THEME["xp"], 0.22))
                                shot_draw.draw_circle(p3, 7.0 * pulse, Color("c0b8e8"))
                                shot_draw.draw_circle(p3 + Vector2(-2, -2), 2.8,
                                        Color("e8e2ff"))
                        "scrap":
                                var spin := absf(cos(d3["t"] * 4.0 + float(d3["seed"]))) \
                                        * 0.7 + 0.3
                                # a brass scrap cog: gear ring + hole + shine
                                var gear := PackedVector2Array()
                                for gi in 8:
                                        var ga := float(gi) / 8.0 * TAU
                                        gear.append(p3 + Vector2(cos(ga) * 14.0 * spin,
                                                sin(ga) * 14.0))
                                        gear.append(p3 + Vector2(cos(ga + 0.2) * 10.0 * spin,
                                                sin(ga + 0.2) * 10.0))
                                shot_draw.draw_circle(p3, 18.0, Color(1.0, 0.84, 0.4, 0.16))
                                shot_draw.draw_colored_polygon(gear, Color("c8a86a"))
                                shot_draw.draw_circle(p3, 5.5 * spin, Color("6a5228"))
                                shot_draw.draw_circle(p3 + Vector2(-4, -4) * spin,
                                        3.4, Color("f0dc9c"))
                        "coin":
                                # THE GOGACOIN: rim, face, the blocky G, a shine
                                var ca := fmod(d3["t"] * 2.6, TAU)
                                var squash: float = 0.35 + 0.65 * absf(cos(ca))
                                var bob := sin(d3["t"] * 5.0) * 2.0
                                var cc := p3 + Vector2(0, bob)
                                shot_draw.draw_set_transform(cc, 0.0,
                                        Vector2(squash, 1.0))
                                shot_draw.draw_circle(Vector2.ZERO, 15.0,
                                        Color(1.0, 0.84, 0.3, 0.28))
                                shot_draw.draw_circle(Vector2.ZERO, 12.5,
                                        Color("b8860b"))
                                shot_draw.draw_circle(Vector2.ZERO, 10.0,
                                        Color("f0c040"))
                                shot_draw.draw_circle(Vector2(0, 0), 7.4,
                                        Color("d8a018"))
                                # the G glyph: block strokes, the box's mark
                                var gcol := Color("8a6508")
                                shot_draw.draw_rect(Rect2(-4.6, -5.2, 9.2, 2.6), gcol)
                                shot_draw.draw_rect(Rect2(-4.6, -5.2, 2.6, 10.4), gcol)
                                shot_draw.draw_rect(Rect2(-4.6, 2.6, 9.2, 2.6), gcol)
                                shot_draw.draw_rect(Rect2(2.0, 0.2, 2.6, 5.0), gcol)
                                shot_draw.draw_rect(Rect2(-0.6, 0.2, 2.6, 2.6), gcol)
                                shot_draw.draw_circle(Vector2(-3.5, -4.0), 1.8,
                                        Color(1, 1, 1, 0.55))
                                shot_draw.draw_set_transform(Vector2.ZERO, 0.0,
                                        Vector2(1, 1))

func _draw_fx() -> void:
        for f in fx:
                var d: Dictionary = f
                var life_t := clampf(float(d["t"]) / float(d["life"]), 0.0, 1.0)
                var a := 1.0 - life_t
                var pos := Vector2(d["x"], d["y"])
                match String(d["kind"]):
                        "wave":
                                var r := lerpf(float(d["r0"]), float(d["r1"]), life_t)
                                fx_draw.draw_circle(pos, r, Color(1.0, 0.85, 0.5, 0.35 * a))
                                fx_draw.draw_arc(pos, r, 0, TAU, 32,
                                        Color(1.0, 0.9, 0.6, 0.8 * a), 3.0)
                        "fire":
                                fx_draw.draw_circle(pos, float(d["r"]) * (0.6 + life_t * 0.7),
                                        Color(1.0, 0.6, 0.2, 0.55 * a))
                                fx_draw.draw_circle(pos, float(d["r"]) * (0.35 + life_t * 0.4),
                                        Color(1.0, 0.85, 0.4, 0.7 * a))
                        "ember":
                                fx_draw.draw_circle(pos, float(d["r"]) * (0.4 + a * 0.8),
                                        Color(d.get("col", Color(1.0, 0.7, 0.3)), a))
                        "smoke":
                                fx_draw.draw_circle(pos,
                                        float(d["r"]) * (0.5 + life_t * 0.9),
                                        Color(0.25, 0.25, 0.27, 0.22 * a))
                        "puff":
                                fx_draw.draw_circle(pos, float(d["r"]),
                                        Color(0.85, 0.7, 0.45, 0.4 * a))

# =================================================================
# THE SHOPS (v040-6, THE SPLIT): the SCRAP SHOP is the war's proper shop -
# 8 honest items, scrap prices, the edge cases (MAX can not be re-bought,
# LOCKED needs its unlock, no funds refuses the buy). The normal GOGABox
# SHOP is back in its own place: the coin wallet chip, the tank skins with
# the GOGACoin icon prices, LOCKED until bought (the owner: "GOGABox-shop
# things before get bought, they are locked").
# =================================================================
func _shop_open() -> void:
        if state in [GS.PLACE, GS.BOSS, GS.TUNNEL] and not paused:
                paused = true
                get_tree().paused = true
        var vb := sheet_push(0.0, "shop")
        var t := Arc.label("SCRAP SHOP", 36, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        # the scrap wallet rides the sheet like every real shop's wallet
        var wallet := Arc.chip("SCRAPS  %d" % meta.scrap(), "", THEME["panel"], 24,
                THEME["cost"])
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        vb.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(620, clampf(vp.y * 0.56, 320.0, 660.0))
        vb.add_child(sc)
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        for it in HWData.SHOP_ITEMS:
                box.add_child(_shop_scrap_row(it))
        var close_b := Arc.button("BACK", Vector2(560, 70), 24, Arc.ACCENT,
                func(): sheet_pop())
        var cc := HBoxContainer.new()
        cc.alignment = BoxContainer.ALIGNMENT_CENTER
        cc.add_child(close_b)
        box.add_child(cc)
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _shop_lbl(txt: String) -> Label:
        return Arc.fit_label(txt, 24, Arc.HOT, 600)

## one scrap-shop row: name + level pips + desc + the honest state:
## MAX (green) / LOCKED (dim, needs X) / the cost (gold, or rust when broke)
func _shop_scrap_row(it: Dictionary) -> Control:
        var id := String(it["id"])
        var lvl := _shop_lvl(id)
        var is_unlock := bool(it.get("unlock", false))
        var maxed: bool = lvl >= int(it.get("max", 1)) if not is_unlock \
                else lvl >= 1
        var locked: bool = it.has("requires") and _shop_lvl(String(it["requires"])) <= 0
        # v040-10 THE KEY GATE: the weapons' own unlock rows (and their
        # racks) stay sealed until the GOGACoin SHOP's key for that weapon
        # is bought - the two-key law
        var key_id := ""
        if id == "rockets" or id == "rocket_rack":
                key_id = "rockets"
        elif id == "mg" or id == "mg_rack":
                key_id = "mg"
        var key_needed: bool = key_id != "" and not meta.goga_ok(key_id)
        var row := PanelContainer.new()
        var sb := StyleBoxFlat.new()
        sb.bg_color = THEME["panel"]
        sb.set_corner_radius_all(10)
        sb.border_color = THEME["good"] if maxed else THEME["border"]
        sb.set_border_width_all(2 if maxed else 1)
        sb.content_margin_left = 14
        sb.content_margin_right = 14
        sb.content_margin_top = 8
        sb.content_margin_bottom = 8
        row.add_theme_stylebox_override("panel", sb)
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 4)
        row.add_child(v)
        var top := HBoxContainer.new()
        top.add_theme_constant_override("separation", 10)
        v.add_child(top)
        var name_l := Arc.label(String(it["name"]), 22,
                THEME["text"] if not locked else THEME["mute"])
        name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        top.add_child(name_l)
        # the level pips
        if not is_unlock:
                var pips := HBoxContainer.new()
                pips.add_theme_constant_override("separation", 4)
                for k in int(it.get("max", 1)):
                        var pip := ColorRect.new()
                        pip.custom_minimum_size = Vector2(16, 8)
                        pip.color = THEME["accent"] if k < lvl \
                                else Color(0.47, 0.5, 0.55, 0.18)
                        pips.add_child(pip)
                top.add_child(pips)
        else:
                var st := Arc.label("INSTALLED" if lvl > 0 else "-", 18,
                        THEME["good"] if lvl > 0 else THEME["mute"])
                top.add_child(st)
        var desc := Arc.label(String(it["desc"]), 16,
                THEME["dim"] if not locked else THEME["mute"], false)
        v.add_child(desc)
        if maxed:
                var ml := Arc.label("MAX", 22, THEME["good"])
                ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
                v.add_child(ml)
        elif key_needed:
                var kn := Arc.label("LOCKED - buy the %s KEY in the SHOP "
                        % String(GOGA_KEYS[key_id]["name"]), 17, THEME["cost_no"])
                kn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
                v.add_child(kn)
        elif locked:
                var req := String(HWData.shop_item(String(it["requires"])).get("name",
                        String(it["requires"])))
                var ll := Arc.label("LOCKED - needs %s" % req, 17, THEME["cost_no"])
                ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
                v.add_child(ll)
        else:
                var cost := HWData.shop_cost(it, lvl)
                var can := meta.scrap() >= cost and not key_needed
                var bl := Arc.button("BUY   %d scrap" % cost, Vector2(600, 54), 20,
                        THEME["cost"] if can else THEME["cost_no"], Callable())
                bl.disabled = not can
                bl.pressed.connect(func():
                        if maxed or key_needed or meta.scrap() < cost:
                                Jukebox.sfx("rw_no", -6.0)
                                return
                        if meta.spend_scrap(cost):
                                meta.set_upg(id, lvl + 1)
                                Jukebox.sfx("rw_buy", -4.0)
                        _shop_reopen())
                v.add_child(bl)
        return row

func _shop_reopen() -> void:
        if not _sheet_stack.is_empty() \
                        and String(_sheet_stack[-1].get("id", "")) == "shop":
                sheet_pop()
                _shop_open()

func _box_shop_reopen() -> void:
        if not _sheet_stack.is_empty() \
                        and String(_sheet_stack[-1].get("id", "")) == "boxshop":
                sheet_pop()
                _box_shop_open()

## THE NORMAL GOGABOX SHOP (the owner: "re-put the normal gogabox shop in
## it's place"): the box's own shelf - the coin wallet chip on top, the
## tank skins priced in GOGACoins (the coin icon ON the price, the law),
## every unowned item plainly LOCKED until bought, ONE action color.
func _box_shop_open() -> void:
        if state in [GS.PLACE, GS.BOSS, GS.TUNNEL] and not paused:
                paused = true
                get_tree().paused = true
        var vb := sheet_push(0.0, "boxshop")
        var t := Arc.label("SHOP", 36, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        vb.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(620, clampf(vp.y * 0.56, 300.0, 620.0))
        vb.add_child(sc)
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        box.add_child(_shop_lbl("TANK SKINS"))
        for id in HWData.SKINS:
                box.add_child(_shop_skin_row(id))
        # v040-10 THE TWO-KEY LAW (the owner: "you misunderstood it and
        # putted the scrap shop upgrades in it but for GOGACoins... i meant
        # two expensive upgrades one to unlock rockets weapon to be able to
        # be bought/upgraded in scrap shop and the other for machine
        # guns"): the GOGACoin shelf sells EXACTLY TWO keys - the rockets
        # key and the machine-guns key. Nothing else. A key opens that
        # weapon's rows in the SCRAP SHOP; the scrap still pays for the
        # pods and the racks.
        box.add_child(_shop_lbl("WEAPON KEYS"))
        box.add_child(_shop_goga_key_row("rockets"))
        box.add_child(_shop_goga_key_row("mg"))
        var close_b := Arc.button("CLOSE", Vector2(560, 70), 24, Arc.ACCENT,
                func(): sheet_pop())
        var cc := HBoxContainer.new()
        cc.alignment = BoxContainer.ALIGNMENT_CENTER
        cc.add_child(close_b)
        box.add_child(cc)
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

## one GOGACoin KEY row (v040-10): expensive, one-shot, permanent -
## "UNLOCK ROCKETS" / "UNLOCK MACHINE GUNS"; owned rows read INSTALLED
const GOGA_KEYS := {
        "rockets": {"name": "ROCKET SYSTEMS", "price": 1200,
                "line": "the key that lets the SCRAP SHOP sell you the "
                + "ROCKET PODS and their racks"},
        "mg": {"name": "MACHINE GUN SYSTEMS", "price": 1500,
                "line": "the key that lets the SCRAP SHOP sell you the "
                + "MG BARRELS and their racks"},
}

func _shop_goga_key_row(id: String) -> Control:
        var k: Dictionary = GOGA_KEYS[id]
        var owned := meta.goga_ok(id)
        var row := PanelContainer.new()
        var sb := StyleBoxFlat.new()
        sb.bg_color = THEME["panel"]
        sb.set_corner_radius_all(10)
        sb.border_color = THEME["good"] if owned else THEME["border"]
        sb.set_border_width_all(2 if owned else 1)
        sb.content_margin_left = 14
        sb.content_margin_right = 14
        sb.content_margin_top = 8
        sb.content_margin_bottom = 8
        row.add_theme_stylebox_override("panel", sb)
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 4)
        row.add_child(v)
        var top := HBoxContainer.new()
        top.add_theme_constant_override("separation", 10)
        v.add_child(top)
        var name_l := Arc.label(String(k["name"]), 22,
                THEME["text"] if not owned else THEME["good"])
        name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        top.add_child(name_l)
        var st := Arc.label("OWNED" if owned else "LOCKED", 18,
                THEME["good"] if owned else THEME["mute"])
        top.add_child(st)
        var desc := Arc.label(String(k["line"]), 16, THEME["dim"], false)
        v.add_child(desc)
        if owned:
                var ml := Arc.label("OPEN IN THE SCRAP SHOP", 18, THEME["good"])
                ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
                v.add_child(ml)
        else:
                var price := int(k["price"])
                var bl := Arc.coin_button("UNLOCK  %d" % price,
                        Vector2(600, 54), 20, Arc.ACCENT, func():
                                if Box.spend(price):
                                        meta.set_goga(id)
                                        Jukebox.sfx("rw_buy", -4.0)
                                        _banner("%s UNLOCKED - the SCRAP SHOP "
                                                + "sells them now"
                                                % String(k["name"]), 2.4)
                                _box_shop_reopen())
                if Box.coins() < price:
                        bl.disabled = true   # a dry wallet never buys
                v.add_child(bl)
        return row

func _shop_skin_row(id: String) -> Control:
        var sk: Dictionary = HWData.SKINS[id]
        var owned := Box.skin_owned(game_id, id) or int(sk["price"]) == 0
        var on := Box.skin_on(game_id) == id \
                or (int(sk["price"]) == 0 and Box.skin_on(game_id) == "")
        # THE ON ROW LAW: the equipped skin keeps its full-size row
        if on:
                return Arc.on_row("%s  (ON)" % sk["name"], Vector2(600, 64), 22)
        # owned but not equipped: one tap equips
        if owned:
                return Arc.button(String(sk["name"]), Vector2(600, 62), 22,
                        Arc.ACCENT, func():
                                Box.equip_skin(game_id, id)
                                Jukebox.sfx("rw_click", -4.0)
                                _apply_skin()
                                _box_shop_reopen())
        # LOCKED until bought: a padlock row + the coin-icon price
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 2)
        var lock_row := HBoxContainer.new()
        lock_row.alignment = BoxContainer.ALIGNMENT_CENTER
        lock_row.add_theme_constant_override("separation", 8)
        var lock_c := Control.new()
        lock_c.custom_minimum_size = Vector2(20, 20)
        lock_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
        lock_c.draw.connect(func():
                var s: float = minf(lock_c.size.x, lock_c.size.y)
                var k: float = s / 20.0
                var body := Rect2(Vector2(4 * k, 9 * k), Vector2(12 * k, 9 * k))
                lock_c.draw_rect(body, Color("6a7488"))
                lock_c.draw_arc(Vector2(10 * k, 9 * k), 4 * k, PI, TAU, 12,
                        Color("6a7488"), 2.2 * k)
                lock_c.draw_circle(Vector2(10 * k, 13 * k), 1.8 * k,
                        Color(0.02, 0.02, 0.03)))
        lock_row.add_child(lock_c)
        var lk := Arc.label("LOCKED", 18, THEME["mute"])
        lock_row.add_child(lk)
        v.add_child(lock_row)
        var b := Arc.coin_button("BUY  %s  %d" % [sk["name"], int(sk["price"])],
                Vector2(600, 60), 20, Arc.ACCENT, func():
                        if Box.buy_skin(game_id, id, int(sk["price"])):
                                Jukebox.sfx("rw_buy", -4.0)
                                _apply_skin()
                        _box_shop_reopen())
        if Box.coins() < int(sk["price"]):
                b.disabled = true   # a dry wallet never buys (the box law)
        v.add_child(b)
        return v

# =================================================================
# THE HUD (v040-6) - everything canvas-drawn with outlined text:
# the top-left GAME WIDGET (hull + weapons + LVL/XP + the REMAINING pair),
# the top-right score with the DESIGNED plane icon, the scrap widget with
# its icon (the brick breaker / pop siege law). NO kills widget, NO bottom
# coin text, NO bank text in the HUD (the bank lives in the shops).
# =================================================================

func _build_hw_hud() -> void:
        hud_draw = Control.new()
        hud_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
        hud_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
        hud_draw.draw.connect(_draw_hud)
        _overlay_root_ref().add_child(hud_draw)

## THE CHIP ICON LAW (the pop siege way, v040-8): an icon Control rides
## INSIDE a top-bar chip's HBox (index 0) and paints itself.
func _chip_icon(chip: Control, px: float, paint: Callable) -> void:
        if chip == null or not is_instance_valid(chip):
                return
        var h := chip.get_child(0)
        if h == null or not is_instance_valid(h) or (h as Control).get_child_count() == 0:
                return
        var ic := Control.new()
        ic.custom_minimum_size = Vector2(px, px)
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        ic.draw.connect(func():
                paint.call(ic, Vector2(px * 0.5, px * 0.5)))
        (h as Control).add_child(ic)
        (h as Control).move_child(ic, 0)

## the warbird inside the SCORE chip
func _score_icon_in_chip() -> void:
        _chip_icon(_score_chip_ref(), 34, func(cv: Control, c: Vector2):
                _paint_plane(cv, c))

## the brass cog inside the SCRAP chip (the chip that owns scrap_lbl)
func _scrap_icon_in_chip() -> void:
        if scrap_lbl == null or not is_instance_valid(scrap_lbl):
                return
        var chip := (scrap_lbl.get_parent().get_parent() as Control)
        _chip_icon(chip, 30, func(cv: Control, c: Vector2):
                _paint_scrap(cv, c))

## the warbird (canvas parameterized - it serves the HUD and the chip)
func _paint_plane(cv: Control, c: Vector2) -> void:
        var body := THEME["accent"]
        var dark := Color(0.06, 0.07, 0.09)
        var glass := Color("bfe8ff")
        var s := 0.62
        var P := func(v: Vector2) -> Vector2:
                return c + v * s
        cv.draw_colored_polygon(PackedVector2Array([
                P.call(Vector2(2, 0)), P.call(Vector2(-6, -22)),
                P.call(Vector2(-13, -22)), P.call(Vector2(-12, 0)),
                P.call(Vector2(-13, 22)), P.call(Vector2(-6, 22)),
                P.call(Vector2(2, 0))]), dark)
        cv.draw_colored_polygon(PackedVector2Array([
                P.call(Vector2(-14, 0)), P.call(Vector2(-22, -12)),
                P.call(Vector2(-25, -12)), P.call(Vector2(-20, 0)),
                P.call(Vector2(-25, 12)), P.call(Vector2(-22, 12)),
                P.call(Vector2(-14, 0))]), dark)
        cv.draw_colored_polygon(PackedVector2Array([
                P.call(Vector2(26, 0)), P.call(Vector2(10, -6)),
                P.call(Vector2(-12, -5)), P.call(Vector2(-20, -2)),
                P.call(Vector2(-20, 2)), P.call(Vector2(-12, 5)),
                P.call(Vector2(10, 6)),
        ]), body)
        cv.draw_colored_polygon(PackedVector2Array([
                P.call(Vector2(14, -1)), P.call(Vector2(8, -4)),
                P.call(Vector2(2, -4)), P.call(Vector2(2, 2)),
                P.call(Vector2(12, 2)),
        ]), glass)
        cv.draw_circle(P.call(Vector2(24, 0)), 2.2 * s, Color(1, 1, 1, 0.9))

## the brass cog (canvas parameterized)
func _paint_scrap(cv: Control, c: Vector2) -> void:
        var gear := PackedVector2Array()
        for gi in 8:
                var ga := float(gi) / 8.0 * TAU
                gear.append(c + Vector2(cos(ga) * 13.0, sin(ga) * 13.0))
                gear.append(c + Vector2(cos(ga + 0.22) * 8.8,
                        sin(ga + 0.22) * 8.8))
        cv.draw_colored_polygon(gear, Color("c8a86a"))
        cv.draw_circle(c, 5.4, Color("504028"))
        cv.draw_circle(c + Vector2(-3.4, -3.4), 2.6, Color("f0dc9c"))

## THE OUTLINED TEXT LAW (the owner: "bigger text and better contrast,
## like giving the text a black outlines"): every HUD string wears a hard
## black outline under its fill - readable over any sky, never huge.
func _htxt(pos: Vector2, txt: String, fsize: int, col: Color,
                align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
        hud_draw.draw_string_outline(Arc.font_ui(), pos, txt, align, width,
                fsize, 6, Color(0, 0, 0, 0.9))
        hud_draw.draw_string(Arc.font_ui(), pos, txt, align, width, fsize, col)

## THE REMAINING WIDGET (v040-8): the wave's own limiter - the clock for
## the time kinds, the honest kill count for the kill kinds. A leaver
## never shrinks the kill count (the quota only moves on a real kill).
func _remaining_secs() -> float:
        return maxf(0.0, wave_duration - wave_clock)

func _remaining_enemies() -> int:
        if wave_kind == "time":
                return enemies.size()      # info only - the clock decides
        return maxi(0, wave_quota - wave_quota_done)

func _draw_hud() -> void:
        if state == GS.INTRO:
                _draw_intro()
                return
        if state == GS.MENU:
                _draw_menu()
                return
        var x := 14.0
        var y := 76.0
        # ================= THE TOP-LEFT GAME WIDGET =================
        # one panel: hull, the weapon slots, LVL + XP, the REMAINING pair
        var w := 372.0
        var pw := w + 24
        var ph := 258.0
        hud_draw.draw_rect(Rect2(x - 6, y - 8, pw, ph), Color(0.02, 0.024, 0.03, 0.62))
        hud_draw.draw_rect(Rect2(x - 6, y - 8, pw, ph), THEME["border"], false, 1.5)
        # ---------- HULL ----------
        var pct := clampf(p_hp / p_hp_max, 0.0, 1.0)
        var col: Color = THEME["hp"] if pct > 0.5 \
                else (THEME["hp_low"] if pct > 0.25 else THEME["hp_crit"])
        hud_draw.draw_rect(Rect2(x, y, w, 22), Color(0, 0, 0, 0.55))
        hud_draw.draw_rect(Rect2(x, y, maxf(2.0, w * pct), 22), col)
        hud_draw.draw_rect(Rect2(x, y, w, 22), THEME["border"], false, 1.0)
        _htxt(Vector2(x + 6, y + 17), "HULL", 14, THEME["text"])
        _htxt(Vector2(x + 4, y + 17), "%d / %d" % [ceili(p_hp), int(p_hp_max)],
                14, THEME["text"], HORIZONTAL_ALIGNMENT_RIGHT, w - 10)
        var ry := y + 30.0
        if p_shield > 0.0:
                hud_draw.draw_rect(Rect2(x, ry, w * clampf(p_shield / 120.0, 0, 1), 7),
                        THEME["shield"])
                ry += 12.0
        # ---------- the weapon slots ----------
        _weapon_pips("MAIN", Vector2(x, ry + 4), 1 + _shop_lvl("cannon"), 8, true)
        _weapon_pips("MG", Vector2(x, ry + 26), _mg_lvl(), 4, _mg_lvl() > 0)
        _weapon_pips("RKT", Vector2(x, ry + 48), _rk_lvl(), 4, _rk_lvl() > 0)
        # ---------- LVL + XP ----------
        var ly := ry + 74.0
        _htxt(Vector2(x, ly + 20), "LVL %d" % p_level, 26, THEME["accent_hi"])
        _htxt(Vector2(x + 118, ly + 18), "XP  %d / %d" % [p_xp, p_xp_next],
                18, THEME["text"])
        hud_draw.draw_rect(Rect2(x + 118, ly + 26, w - 122, 7), Color(0, 0, 0, 0.55))
        hud_draw.draw_rect(Rect2(x + 118, ly + 26, maxf(0.0,
                (w - 122) * clampf(float(p_xp) / float(p_xp_next), 0, 1)), 7),
                THEME["xp"])
        # ---------- THE REMAINING WIDGET: the wave's own limiter ----------
        # THE WAVE LAW (v040-8): a wave is KILLS-limited, TIME-limited or
        # BOTH - the widget shows exactly what the wave asks for, and the
        # WAVE row lives here now (the old top-right panel is dead).
        var my := ly + 46.0
        var kind := String(wave_kind)
        if state == GS.PLACE and (kind == "time" or kind == "both"):
                _draw_clock_icon(Vector2(x + 16, my + 16))
                var rem := _remaining_secs()
                var time_txt := "%d:%02d" % [int(rem) / 60, int(rem) % 60]
                var tcol: Color = Color(1.0, 0.62, 0.4) if rem <= 10.0 \
                        else THEME["text"]
                _htxt(Vector2(x + 40, my + 25), time_txt, 22, tcol)
        if state == GS.PLACE and (kind == "kills" or kind == "both"):
                var jx := x + 168.0
                if kind == "kills":
                        jx = x + 40.0
                _draw_jet_icon(Vector2(jx + 16, my + 14), 0.62, Color("d88878"))
                _htxt(Vector2(jx + 40, my + 25), "x %d" % _remaining_enemies(),
                        22, THEME["text"])
        if state == GS.PLACE:
                _htxt(Vector2(x, my + 62), "WAVE %d / %d  -  %s" % [wave,
                        HWData.WAVES_PER_PLACE,
                        String(HWData.PLACES[place_i % 10]["name"])],
                        15, THEME["dim"])
        # ---------- the boss bar (with its shield overlay) ----------
        for e in enemies:
                var d: Dictionary = e
                if String(d.get("kind", "")) == "boss":
                        var bw := minf(W - 420.0, 640.0)
                        var bx := W / 2.0 - bw / 2.0
                        hud_draw.draw_rect(Rect2(bx - 4, 78, bw + 8, 24),
                                Color(0, 0, 0, 0.75))
                        hud_draw.draw_rect(Rect2(bx, 82, bw * clampf(
                                float(d["hp"]) / float(d["maxhp"]), 0, 1), 14),
                                Color("b85060"))
                        if float(d.get("shield", 0.0)) > 0.0:
                                hud_draw.draw_rect(Rect2(bx, 82, bw * clampf(
                                        float(d["shield"]) / float(d["maxhp"]), 0, 1), 14),
                                Color(THEME["shield"], 0.8))
                        hud_draw.draw_rect(Rect2(bx - 4, 78, bw + 8, 24),
                                THEME["border"], false, 1.0)
                        _htxt(Vector2(0, 72),
                                String(d["name"])
                                + ("  -  ENRAGED" if bool(d.get("enraged", false)) else "")
                                + ("  -  SHIELDS UP" if float(d.get("shield", 0.0)) > 0.0 else ""),
                                15, THEME["text"], HORIZONTAL_ALIGNMENT_CENTER, W)
        # ---------- the banner ----------
        if banner_t > 0.0 and banner != "":
                var a := minf(1.0, banner_t / 0.4)
                hud_draw.draw_string_outline(Arc.font_ui(), Vector2(4, H * 0.2 + 4),
                        banner, HORIZONTAL_ALIGNMENT_CENTER, W, 46, 10,
                        Color(0, 0, 0, 0.9 * a))
                hud_draw.draw_string(Arc.font_ui(), Vector2(0, H * 0.2), banner,
                        HORIZONTAL_ALIGNMENT_CENTER, W, 46,
                        Color(THEME["accent_hi"], a))
        # ---------- the damage vignette + the flash ----------
        if damage_flash > 0.0:
                hud_draw.draw_rect(Rect2(0, 0, W, H),
                        Color(0.78, 0.24, 0.24, damage_flash * 0.35))
        if flash > 0.0:
                hud_draw.draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, flash))
        # ---------- THE AIM CURSOR ----------
        if aim_ptr != -1 or mouse_aim:
                _draw_crosshair(aim_pos)

func _weapon_pips(name_txt: String, at: Vector2, n: int, maxn: int,
                unlocked: bool) -> void:
        _htxt(at + Vector2(0, 12), name_txt, 13,
                THEME["dim"] if unlocked else THEME["mute"])
        var px := at.x + 56.0
        if not unlocked:
                _htxt(Vector2(px, at.y + 12), "locked - the SCRAP SHOP sells it",
                        13, THEME["mute"])
                return
        for i in maxn:
                var r := Rect2(px + float(i) * 18.0, at.y, 12, 13)
                hud_draw.draw_rect(r, THEME["accent"] if i < n
                        else Color(0.47, 0.5, 0.55, 0.18))
                hud_draw.draw_rect(r, THEME["border"], false, 1.0)

## THE SCORE ICON (the owner: "design an icon for it, not the shitty way"):
## a real warbird - swept wings, a tailfin, a canopy, a hard outline.
## (v040-8: it lives INSIDE the box score chip - _paint_plane paints it.)

## a small jet glyph for the REMAINING widget (enemies left)
func _draw_jet_icon(c: Vector2, s: float, col: Color) -> void:
        hud_draw.draw_colored_polygon(PackedVector2Array([
                c + Vector2(16 * s, 0), c + Vector2(-2 * s, -11 * s),
                c + Vector2(-7 * s, -11 * s), c + Vector2(-4 * s, 0),
                c + Vector2(-7 * s, 11 * s), c + Vector2(-2 * s, 11 * s),
        ]), col)

## the clock glyph for the REMAINING widget (time left)
func _draw_clock_icon(c: Vector2) -> void:
        hud_draw.draw_circle(c, 12.0, Color(0.02, 0.024, 0.03, 0.8))
        hud_draw.draw_arc(c, 12.0, 0, TAU, 24, THEME["accent"], 2.4)
        var ma := t_state * 1.6 - PI / 2.0
        hud_draw.draw_line(c, c + Vector2(cos(ma), sin(ma)) * 7.6,
                THEME["text"], 2.2)
        var ha := -PI * 0.35
        hud_draw.draw_line(c, c + Vector2(cos(ha), sin(ha)) * 4.8,
                THEME["text"], 2.2)

## the scrap icon: a brass cog with a hard edge
## (v040-8: it lives inside the top-bar scrap chip - _paint_scrap paints it.)

## THE AIM CURSOR: ring + ticks + dot, the HTML crosshair, theme white
func _draw_crosshair(at: Vector2) -> void:
        var c: Color = THEME["accent_hi"]
        hud_draw.draw_arc(at, 14.0, 0, TAU, 40, c, 1.8)
        for t in [[-24, -9], [9, 24]]:
                hud_draw.draw_line(Vector2(at.x + float(t[0]), at.y),
                        Vector2(at.x + float(t[1]), at.y), c, 1.8)
                hud_draw.draw_line(Vector2(at.x, at.y + float(t[0])),
                        Vector2(at.x, at.y + float(t[1])), c, 1.8)
        hud_draw.draw_circle(at, 1.8, c)

## THE INTRO: the world + "TAP ANYWHERE TO START". The name is HEAVY WAR -
## nothing else (the owner: "it shows rogue arsenal which i do not want").
func _draw_intro() -> void:
        var a := 0.7 + sin(t_state * 3.0) * 0.3
        hud_draw.draw_string_outline(Arc.font_ui(), Vector2(3, H * 0.48 + 3),
                "HEAVY WAR", HORIZONTAL_ALIGNMENT_CENTER, W, 68, 12,
                Color(0, 0, 0, 0.85 * a))
        hud_draw.draw_string(Arc.font_ui(), Vector2(0, H * 0.48),
                "HEAVY WAR", HORIZONTAL_ALIGNMENT_CENTER, W, 68,
                Color(THEME["accent_hi"], a))
        hud_draw.draw_string_outline(Arc.font_ui(), Vector2(0, H * 0.72 + 2),
                "TAP ANYWHERE TO START", HORIZONTAL_ALIGNMENT_CENTER, W, 38, 8,
                Color(0, 0, 0, 0.8 * a))
        hud_draw.draw_string(Arc.font_ui(), Vector2(0, H * 0.72),
                "TAP ANYWHERE TO START", HORIZONTAL_ALIGNMENT_CENTER, W, 38,
                Color(1, 1, 1, a))

## THE MENU (v040-8): DEPLOY + SCRAP SHOP + the best line. The GOGABox
## SHOP left the menu - it is an IN-GAME top-bar button now (the usual
## seat), the menu stays lean.
func _draw_menu() -> void:
        hud_draw.draw_rect(Rect2(0, 0, W, H), Color(0.016, 0.02, 0.027, 0.72))
        hud_draw.draw_string_outline(Arc.font_ui(), Vector2(0, H * 0.24 + 3),
                "HEAVY WAR", HORIZONTAL_ALIGNMENT_CENTER, W, 76, 12,
                Color(0, 0, 0, 0.9))
        hud_draw.draw_string(Arc.font_ui(), Vector2(0, H * 0.24),
                "HEAVY WAR", HORIZONTAL_ALIGNMENT_CENTER, W, 76, THEME["accent_hi"])
        var by := H * 0.42
        var bw := 460.0
        var bh := 88.0
        _menu_button(Rect2(W / 2 - bw / 2.0, by, bw, bh), "DEPLOY", true)
        _menu_button(Rect2(W / 2 - bw / 2.0, by + bh + 20.0, bw, bh),
                "SCRAP SHOP   %d" % meta.scrap(), false)
        hud_draw.draw_string_outline(Arc.font_ui(), Vector2(0, H - 28),
                "BEST: PLACE %d   -   SCORE %d   -   TOTAL SCRAP %d"
                        % [int(meta.d["best_place"]), int(meta.d["best_kills"]),
                        meta.total_scrap()],
                HORIZONTAL_ALIGNMENT_CENTER, W, 17, 6, Color(0, 0, 0, 0.8))
        hud_draw.draw_string(Arc.font_ui(), Vector2(0, H - 28),
                "BEST: PLACE %d   -   SCORE %d   -   TOTAL SCRAP %d"
                        % [int(meta.d["best_place"]), int(meta.d["best_kills"]),
                        meta.total_scrap()],
                HORIZONTAL_ALIGNMENT_CENTER, W, 17, THEME["text"])

func _menu_button(r: Rect2, label: String, primary: bool) -> void:
        hud_draw.draw_rect(r, THEME["panel"])
        hud_draw.draw_rect(r, THEME["border_hi"] if primary else THEME["border"],
                false, 2.5 if primary else 1.5)
        hud_draw.draw_string_outline(Arc.font_ui(), r.position + Vector2(0,
                r.size.y * 0.64), label, HORIZONTAL_ALIGNMENT_CENTER,
                r.size.x, 30, 6, Color(0, 0, 0, 0.7))
        hud_draw.draw_string(Arc.font_ui(), r.position + Vector2(0,
                r.size.y * 0.64), label, HORIZONTAL_ALIGNMENT_CENTER,
                r.size.x, 30, THEME["cost"] if primary else THEME["text"])

## the menu buttons own their taps - the input law routes taps here when
## the state is MENU
func _menu_tap(pos: Vector2) -> void:
        var by := H * 0.42
        var bw := 460.0
        var bh := 88.0
        var b1 := Rect2(W / 2 - bw / 2.0, by, bw, bh)
        var b2 := Rect2(W / 2 - bw / 2.0, by + bh + 20.0, bw, bh)
        if b1.has_point(pos):
                Jukebox.sfx("rw_click", -4.0)
                _run_start()
        elif b2.has_point(pos):
                Jukebox.sfx("rw_click", -4.0)
                _shop_open()

func _run_start() -> void:
        _run_reset()
        set_score(0)
        _start_place()

# ------------------------------------------------------------------- over
func _game_over() -> void:
        if state == GS.OVER:
                return
        state = GS.OVER
        if not tunnel.is_empty():
                tunnel = {}
                if tunnel_node != null and is_instance_valid(tunnel_node):
                        tunnel_node.queue_free()
                tunnel_node = null
        Jukebox.stop_music()
        Jukebox.sfx("rw_gameover", -2.0)
        _explode(p_x, GROUND_Y - 55.0, 1.8)
        _explode(p_x - 24.0, GROUND_Y - 42.0, 1.3)
        # THE SCRAP BANK: the carried scrap + everything still on the ground
        # banks for the SCRAP SHOP (the HTML gameOver law)
        var banked := p_scrap
        for p in drops:
                var d: Dictionary = p
                if String(d["kind"]) == "scrap":
                        banked += int(d["value"])
        drops.clear()
        meta.bank_scrap(banked)
        meta.record_run(score, place_i + 1, loop, int(run["bosses_killed"]))
        check_achievements()
        # the hull burns before the sheet lands
        var tw := get_tree().create_timer(1.4)
        tw.timeout.connect(func():
                finish_run(score, int(run_coins)))
