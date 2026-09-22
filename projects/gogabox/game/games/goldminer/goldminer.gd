extends GogaGame
## GOLD MINER (v040-15) - the goldminer teaser seat graduated (the rename
## law). An endless timing miner: the claw swings on its rope like a
## pendulum, TAP releases it along the current angle, whatever it bites is
## reeled home; every gold cleared loads the next ground, bombs are the
## lives (3 touches = the run ends, each touch blasts its surroundings).
## The owner's GDD worked into laws (docs/goga_docs/gogames_ideas/gold_miner.md):
## endless like the slasher, algorithmic grounds with profiles, S/M/L gold
## 1/2/3 + rock 2/4/6, the /30 score bonus (coin_div 30), 5+5 skins with
## single bombs, hearts + score + GOGACoins widgets, the END button in the
## pause sheet, the every-50 glowing-gold coin law with the next-level edge
## case, the darker-dust drag trails, the different SFX per thing.
## v041 THE OWNER'S REPORT ROUND: the intro shows NO game pieces (the rig
## ghost kill - the rig, rope and claw seat in only when the run starts,
## the go rides the universal tap-anywhere overlay), the rig's wheels sit
## EXACTLY on the measured surface line (MinerData.SURFACE_Y), the claw's
## whole trip clamps to the REAL viewport room (the walls law - nothing
## flies out of resolution), rocks pay NEGATIVE (-2/-4/-6, score_for) and
## float their tax at the winch while gold floats its + (the float text
## law - a negative total pays no coin bonus and never lowers the best),
## and the grounds grew real traps (every big gold's aim lane is guarded).

const A := "res://assets/games/goldminer/"
const DESIGN := Vector2(1080, 1920)          # the box portrait design space

# ---------------------------------------------------------------- feel laws
const SWING_DEG := 72.0          # the pendulum's reach from straight down
const SWING_PERIOD := 2.2        # seconds per full left-right breath
const ROPE_OUT := 980.0          # the launch payout speed (px/s)
const ROPE_IDLE := 64.0          # the claw's hanging distance from the hub
const GRAB_TIME := 0.14          # the claw closing beat
const BLAST_R := 260.0           # the bomb's kill radius
const DUST_EVERY := 90.0         # px of rope travel per drag puff
const BLAST_TIME := 0.5
const CLEAR_TIME := 0.9

# ---------------------------------------------------------------- state
var phase := "boot"              # boot | intro | swing | fly | grab | reel | blast | clear
var level := 1
var lives := 3
var things_banked := 0           # the every-50 coin law's counter
var coin_pending := false        # the 50th thing ended the level -> next ground
var rng := RandomNumberGenerator.new()

# world
var world: Node2D
var ORIGIN := Vector2.ZERO
var items: Array = []            # {kind, size?, pos, r, spr, coin, dying}
var golds_left := 0
var rig: Sprite2D
var rope_draw: Node2D
var claw_spr: Sprite2D
var dust_layer: Node2D
var fx_layer: Node2D
var blasts: Array = []           # the running explosion anims

# the rope math (design space)
var anchor := Vector2(540, MinerData.ANCHOR_Y)
# v041-1 THE TIMED GROUND LAW (the owner: "make the game timed... use the
# gold, the rocks, distance and sorting and the time of the thing thrown
# takes from top to bottom to calculate everything so you make the time to
# calculate as collecting all golds with 60% of gold... the rocks sorting
# is actually tricky so it will be more fun"): every ground computes its
# own clock from the REAL field - each gold's round trip (the swing's
# payout speed down, its own reel weight back) is priced in seconds, the
# golds are sorted by value-per-second, and the clock is the time of
# collecting the cheapest 60% of the total gold value. The rocks and the
# distances make the honest budget tight - the long-term win feels like
# gambling, exactly as ordered.
var ground_time := 0.0
var ground_clock := 0.0
var time_lbl: Label
var swing_phase := 0.0
var rope_len := ROPE_IDLE
var claw_dir := Vector2(0, 1)
var grab_t := 0.0
var carried: Dictionary = {}     # the reeled item (ref into items)
var dust_travel := 0.0
var clear_t := 0.0
var shake_t := 0.0
var reel_snd_t := 0.0

# hud
var lives_lbl: Label
var ready_ui: Control = null
var tap_cooldown := 0.0

## THE ROPE: one honest line from the winch hub to the claw, redrawn every
## tick (the living layer law: time-driven art rides the heartbeat)
class RopeDraw extends Node2D:
        var game: Node = null
        func _draw() -> void:
                if game == null:
                        return
                var from: Vector2 = game.anchor
                var to: Vector2 = game.anchor + game.claw_dir * game.rope_len
                draw_line(from, to, Color(0.42, 0.35, 0.27, 0.95), 6.0)
                draw_circle(from, 7.0, Color(0.27, 0.22, 0.17, 0.95))

# ---------------------------------------------------------------- textures
var _tex_cache: Dictionary = {}

func _t(p: String) -> Texture2D:
        if not _tex_cache.has(p):
                _tex_cache[p] = load(A + p)
        return _tex_cache[p]

## the skin laws: the rig wears the MINER skin, the items wear the VEIN
## skin, bombs are ONE (never skinned - the owner's law)
func _rig_tex() -> Texture2D:
        var on := Box.item_on(game_id, "skin_miner")
        for s in MinerData.MINER_SKINS:
                if s["id"] == on:
                        return _t("rig_%s.png" % on)
        return _t("rig_classic.png")

func _vein() -> String:
        var on := Box.item_on(game_id, "skin_vein")
        for s in MinerData.VEIN_SKINS:
                if s["id"] == on:
                        return on
        return "classic"

func _item_tex(kind: String) -> Texture2D:
        if kind == "bomb":
                return _t("bomb.png")
        if kind == "coin":
                return _t("coin.png")
        # forge naming: <family>_<vein>_<size>.png (gold_classic_s.png)
        var parts := kind.split("_")
        return _t("%s_%s_%s.png" % [parts[0], _vein(), parts[1]])

# ---------------------------------------------------------------- setup
func _goga_setup() -> void:
        rng.randomize()
        pause_end_run = true      # THE END LAW: the pause sheet banks the run
        lives_lbl = add_hud_chip("x3", "res://assets/ui/heart.png")
        # v041-1 THE TIMED GROUND: the live clock rides the HUD
        time_lbl = add_hud_chip("0:00")
        add_hud_button("SHOP", func(): _shop_open())
        _layout()
        _goga_tk_ready()
        _build_world()
        _build_intro()
        Jukebox.music("res://assets/audio/music/gm_music.ogg")
        check_achievements()

func _layout() -> void:
        var vp := get_viewport_rect().size
        ORIGIN = Vector2((vp.x - DESIGN.x) * 0.5, (vp.y - DESIGN.y) * 0.5)

func _goga_tk_ready() -> void:
        if tk == null:
                return
        tk.tapped.connect(_on_tap)

# ---------------------------------------------------------------- intro
func _build_intro() -> void:
        phase = "intro"
        ready_ui = Control.new()
        ready_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        ready_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _overlay_root_ref().add_child(ready_ui)
        var dim := ColorRect.new()
        dim.color = Color(0.05, 0.03, 0.08, 0.42)
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        # THE TAP-THROUGH LAW: every child of the intro overlay ignores the
        # mouse - a STOP ColorRect eats the emulated finger and the intro
        # never dismisses on a real screen (the film caught it)
        dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
        ready_ui.add_child(dim)
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        ready_ui.add_child(cc)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 18)
        vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        cc.add_child(vb)
        var logo := TextureRect.new()
        logo.texture = _t("logo.png")
        logo.custom_minimum_size = Vector2(560, 560.0 * 211.0 / 390.0)
        logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(logo)
        var tap := Arc.label("TAP ANYWHERE TO START", 44, Color(1, 1, 1))
        tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        tap.add_theme_color_override("font_outline_color", Color(0, 0, 0))
        tap.add_theme_constant_override("outline_size", 12)
        tap.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(tap)
        # THE TAP-ANYWHERE LAW (v0.4.1): the universal full-screen overlay
        # owns the go - any tap OR any key fires it, from any pixel. The
        # game's own raw intro paths are gone (one door, everywhere).
        tap_anywhere_start(_intro_start, "")
        # THE NO-HELPER LAW: no info line under the tap prompt - the how-to
        # lives in the guide (it already does), never here
        if not bool(Box.counter(game_id, "lore_start")) \
                        and DisplayServer.get_name() != "headless":
                Box.bump_counter(game_id, "lore_start", 1)
                box_story_show("TOM THE MINER",
                        "Howdy, partner! This claim's rich - gold tucked in "
                        + "the dirt from here to bedrock. My claw never "
                        + "stops swinging; drop it at the right beat and it "
                        + "hauls up whatever it bites. Mind the bombs - "
                        + "three of those and the dig is done.",
                        func(): pass, "DIG", Color(0.9, 0.7, 0.25))

## the universal overlay's go (it owns the tap AND the keyboard paths)
func _intro_start() -> void:
        Jukebox.sfx("gm_start", -2.0)
        _intro_go()

func _intro_go() -> void:
        if ready_ui != null and is_instance_valid(ready_ui):
                ready_ui.queue_free()
                ready_ui = null
        tap_anywhere_stop()
        tap_cooldown = 0.35     # the start tap's release must not fire a throw
        _new_run()

# ---------------------------------------------------------------- world
func _build_world() -> void:
        world = Node2D.new()
        world.position = ORIGIN
        add_child(world)
        var surf := Sprite2D.new()
        surf.texture = _t("bg_surface.png")
        surf.centered = false
        world.add_child(surf)
        var field := Sprite2D.new()
        field.texture = _t("bg_field.png")
        field.centered = false
        field.position = Vector2(0, 360)
        world.add_child(field)
        var bed := Sprite2D.new()
        bed.texture = _t("bg_bedrock.png")
        bed.centered = false
        bed.position = Vector2(0, 1820 - 190)
        world.add_child(bed)
        var bed2 := Sprite2D.new()
        bed2.texture = _t("bg_bedrock.png")
        bed2.centered = false
        bed2.position = Vector2(0, 1820)
        world.add_child(bed2)
        var items_layer := Node2D.new()
        world.add_child(items_layer)
        world.set_meta("items_layer", items_layer)
        dust_layer = Node2D.new()
        world.add_child(dust_layer)
        fx_layer = Node2D.new()
        world.add_child(fx_layer)
        rope_draw = RopeDraw.new()
        rope_draw.game = self
        world.add_child(rope_draw)
        rig = Sprite2D.new()
        rig.texture = _rig_tex()
        rig.centered = false
        rig.scale = Vector2(MinerData.RIG_SCALE, MinerData.RIG_SCALE)
        world.add_child(rig)
        claw_spr = Sprite2D.new()
        claw_spr.texture = _t("claw_open.png")
        claw_spr.offset = Vector2(31.0 - 27.5, 24.0 - 16.0)   # hub seats the rope
        world.add_child(claw_spr)
        # THE INTRO GHOST LAW (v041): the intro shows the dirt only - the
        # rig, the rope and the claw seat IN when the run starts (the rig
        # used to float at the default (0,0) through the whole intro - the
        # owner's "mining ghost in the sky" catch)
        rig.visible = false
        rope_draw.visible = false
        claw_spr.visible = false

## the rig rides its OWN random spot each RUN (the owner's "the character
## position should differ from game to game" law); the generator gets the
## same anchor so every gold stays reachable. THE SURFACE LAW (v041): the
## seat math lives in MinerData - the hub Y lands the wheels' contact row
## (RIG_BASE_Y) exactly on the measured surface line (SURFACE_Y).
func _seat_rig() -> void:
        anchor = Vector2(rng.randf_range(240.0, 840.0), MinerData.ANCHOR_Y)
        rig.position = anchor - MinerData.RIG_HUB * MinerData.RIG_SCALE
        rig.visible = true
        rope_draw.visible = true
        claw_spr.visible = true

## the wheels' world Y - the probe's surface check reads this
func rig_base_y() -> float:
        return rig.position.y + MinerData.RIG_BASE_Y * MinerData.RIG_SCALE

func _new_run() -> void:
        level = 1
        lives = 3
        things_banked = 0
        coin_pending = false
        set_score(0)
        _lives_hud()
        _seat_rig()
        _populate()

func _lives_hud() -> void:
        if lives_lbl != null:
                lives_lbl.text = "x%d" % lives

## THE GROUND GENERATOR (MinerData, pure) -> sprites that grow in.
## Items kind map: gold_s/m/l, rock_s/m/l (s2 = the alt pebble shape),
## bomb, coin (the glowing gold - the GOGACoin carrier).
func _populate() -> void:
        for it in items:
                if it["spr"] != null and is_instance_valid(it["spr"]):
                        it["spr"].queue_free()
        items.clear()
        phase = "swing"
        var raw: Array = MinerData.generate(level, rng, anchor)
        var layer: Node2D = world.get_meta("items_layer")
        var delay := 0.0
        for d in raw:
                var it := {
                        "kind": String(d["kind"]), "pos": d["pos"], "r": d["r"],
                        "coin": false, "dying": false, "spr": null, "v": "",
                }
                var spr := Sprite2D.new()
                spr.texture = _item_tex(it["kind"])
                if it["kind"] == "rock_s" and rng.randf() < 0.5:
                        spr.texture = _t("rock_%s_s2.png" % _vein())
                        it["v"] = "s2"
                spr.position = it["pos"]
                layer.add_child(spr)
                it["spr"] = spr
                items.append(it)
                spr.scale = Vector2(0.1, 0.1)
                var tw := spr.create_tween()
                tw.tween_interval(delay)
                tw.tween_property(spr, "scale", Vector2(1, 1), 0.22) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                delay += 0.045
        if coin_pending:
                coin_pending = false
                _seed_coin()
        golds_left = 0
        for it in items:
                if String(it["kind"]).begins_with("gold"):
                        golds_left += 1
        _price_ground_clock()

## v041-1: the clock builder - see THE TIMED GROUND LAW at ground_time.
func _price_ground_clock() -> void:
        var priced: Array = []
        var total_value := 0
        for it in items:
                var kind := String(it["kind"])
                if not kind.begins_with("gold"):
                        continue
                var val := int(MinerData.POINTS.get(kind, 0))
                if val <= 0:
                        continue
                total_value += val
                var dist: float = anchor.distance_to(it["pos"])
                # the honest round trip: payout at ROPE_OUT, the reel home at
                # the thing's OWN weight speed (the heavy gold crawls), plus
                # the claw's closing beat
                var trip: float = dist / ROPE_OUT \
                                + dist / float(MinerData.REEL_SPEED.get(kind, 900.0)) \
                                + GRAB_TIME
                priced.append({"v": val, "t": trip})
        var target := float(total_value) * 0.6
        # the greedy fill: the cheapest-to-take golds first
        priced.sort_custom(func(a, b): return float(a["v"]) / float(a["t"]) \
                        > float(b["v"]) / float(b["t"]))
        var acc := 0.0
        var got := 0.0
        for p in priced:
                got += float(p["v"])
                acc += float(p["t"])
                if got >= target:
                        break
        # the swing/aim overhead rides on top; a floor keeps tiny fields sane
        ground_time = maxf(20.0, ceilf(acc + 8.0))
        ground_clock = ground_time
        if time_lbl != null:
                time_lbl.text = _clock_text(ground_clock)

func _clock_text(t: float) -> String:
        var s := int(maxf(0.0, ceilf(t)))
        return "%d:%02d" % [s / 60, s % 60]
func _seed_coin() -> void:
        var golds: Array = []
        for it in items:
                if String(it["kind"]).begins_with("gold"):
                        golds.append(it)
        if golds.is_empty():
                coin_pending = true     # the ground refuses - carry forward
                return
        var pick: Dictionary = golds[rng.randi_range(0, golds.size() - 1)]
        _make_coin_carrier(pick)

func _make_coin_carrier(it: Dictionary) -> void:
        it["coin"] = true
        var spr: Sprite2D = it["spr"]
        spr.texture = _t("coin.png")
        var glow := Sprite2D.new()
        glow.texture = _t("coin.png")
        glow.scale = Vector2(1.45, 1.45)
        glow.modulate = Color(1, 1, 1, 0.45)
        spr.add_child(glow)
        var tw := glow.create_tween().set_loops()
        tw.tween_property(glow, "modulate:a", 0.85, 0.5)
        tw.tween_property(glow, "modulate:a", 0.35, 0.5)
        it["glow"] = glow

# ---------------------------------------------------------------- the room
## THE RESOLUTION RULE: the room is REAL - the visible canvas rect
## translated into world space (the world draws at ORIGIN inside it).
## Never a hardcoded 1080x1920: the box stretches canvas_items EXPAND,
## the room grows with the device.
func _room() -> Rect2:
        return Rect2(-ORIGIN, get_viewport_rect().size)

## THE WALLS LAW (v041): the longest rope the claw may pay out along dir
## so the whole trip stays inside the room - the claw can never exit the
## screen or bite a ground that lives out of resolution. The margin covers
## the claw sprite's own half (~31px) plus the heaviest load's grip
## (r * 0.55 + 16 -> ~60px); the carried load's own body is clamped in
## _seat_claw. dir must be normalized.
func _wall_rope_len(dir: Vector2, room: Rect2) -> float:
        var m := 94.0
        var best := MinerData.ROPE_MAX
        if dir.x < -0.0001:
                best = minf(best, (room.position.x + m - anchor.x) / dir.x)
        elif dir.x > 0.0001:
                best = minf(best, (room.end.x - m - anchor.x) / dir.x)
        if dir.y > 0.0001:
                best = minf(best, (room.end.y - m - anchor.y) / dir.y)
        elif dir.y < -0.0001:
                best = minf(best, (room.position.y + m - anchor.y) / dir.y)
        return maxf(0.0, best)

# ================================================================ the loop
func _goga_tick(delta: float) -> void:
        if tap_cooldown > 0.0:
                tap_cooldown -= delta
        if shake_t > 0.0:
                shake_t -= delta
                world.position = ORIGIN + Vector2(
                        rng.randf_range(-14, 14), rng.randf_range(-14, 14)) \
                        * clampf(shake_t / 0.4, 0.0, 1.0)
                if shake_t <= 0.0:
                        world.position = ORIGIN
        _tick_blasts(delta)
        # v041-1 THE TIMED GROUND: the clock burns during play. v041-1 r6
        # THE TIME-UP LAW (the owner: "when time ends, make it just loads
        # the next ground, not end the game, game ends only when lives are
        # 0"): 0 = the ground is OVER, not the run - the next ground loads
        # (the clear flow verbatim), the clock re-prices there, and the
        # run only dies at 0 lives (the bomb law, untouched).
        if phase == "swing" or phase == "fly" or phase == "grab" \
                        or phase == "reel":
                ground_clock -= delta
                if time_lbl != null:
                        time_lbl.text = _clock_text(ground_clock)
                if ground_clock <= 0.0:
                        ground_clock = 0.0
                        if time_lbl != null:
                                time_lbl.text = "0:00"
                        _time_up_next_ground()
        match phase:
                "swing":
                        swing_phase += delta * TAU / SWING_PERIOD
                        var a := deg_to_rad(SWING_DEG) * sin(swing_phase)
                        claw_dir = Vector2(sin(a), cos(a))
                        rope_len = ROPE_IDLE
                        _seat_claw()
                "fly":
                        _tick_rope_sound(delta)
                        var prev := rope_len
                        var wall := _wall_rope_len(claw_dir, _room())
                        rope_len = minf(rope_len + ROPE_OUT * delta, wall)
                        _seat_claw()
                        _fly_hit(prev)
                        if phase == "fly" and rope_len >= wall - 0.01:
                                phase = "reel"  # the wall: the claw turns home
                "grab":
                        grab_t -= delta
                        if grab_t <= 0.0:
                                phase = "reel"
                "reel":
                        _tick_rope_sound(delta)
                        var kind := "none"
                        if not carried.is_empty():
                                kind = String(carried["kind"])
                        var spd: float = MinerData.REEL_SPEED[kind]
                        var step: float = minf(spd * delta, rope_len - ROPE_IDLE)
                        rope_len -= step
                        dust_travel += step
                        if not carried.is_empty() and dust_travel >= DUST_EVERY:
                                dust_travel = 0.0
                                _spawn_dust()
                        _seat_claw()
                        if rope_len <= ROPE_IDLE + 0.5:
                                _bank()
                "clear":
                        clear_t -= delta
                        if clear_t <= 0.0:
                                level += 1
                                achievement_max("gm_level", level)
                                _populate()
                "blast":
                        clear_t -= delta
                        if clear_t <= 0.0:
                                phase = "reel"   # the empty claw crawls home
        rope_draw.queue_redraw()

func _seat_claw() -> void:
        var tip := anchor + claw_dir * rope_len
        claw_spr.position = tip
        claw_spr.rotation = Vector2(0, 1).angle_to(claw_dir)
        if not carried.is_empty():
                var spr: Sprite2D = carried["spr"]
                if spr != null and is_instance_valid(spr):
                        var grip: float = float(carried["r"]) * 0.55 + 16.0
                        var p := tip + claw_dir * grip
                        # THE WALLS LAW: the load rides inside too - its own
                        # radius never crosses the room's edge
                        var r := float(carried["r"])
                        var room := _room()
                        p.x = clampf(p.x, room.position.x + r, room.end.x - r)
                        p.y = clampf(p.y, room.position.y + r, room.end.y - r)
                        spr.position = p
                        spr.rotation = claw_spr.rotation

func _fly_hit(prev_len: float) -> void:
        # THE SUBSTEPPED SWEEP LAW: a 980px/s claw steps ~32px per frame -
        # sample the segment so nothing tunnels through (law 36's law)
        var steps := 4
        for i in steps:
                var l := lerpf(prev_len, rope_len, float(i + 1) / steps)
                var p := anchor + claw_dir * l
                for it in items:
                        if bool(it["dying"]):
                                continue
                        if p.distance_to(it["pos"]) <= float(it["r"]) + 14.0:
                                _grab(it)
                                return

func _grab(it: Dictionary) -> void:
        carried = it
        if String(it["kind"]) == "bomb":
                _bomb_hit(it)
                return
        Jukebox.sfx("gm_grab", -4.0)
        claw_spr.texture = _t("claw_closed.png")
        claw_spr.offset = Vector2(16.0 - 16.0, 17.0 - 8.0)
        grab_t = GRAB_TIME
        phase = "grab"

func _bomb_hit(it: Dictionary) -> void:
        Jukebox.sfx("gm_bomb_hit", 0.0)
        lives -= 1
        _lives_hud()
        _spawn_blast(it["pos"])
        carried = {}
        claw_spr.texture = _t("claw_open.png")
        claw_spr.offset = Vector2(31.0 - 27.5, 24.0 - 16.0)
        # THE BLAST LAW: everything in the radius dies with it - gold or
        # rock (a destroyed gold still counts toward clearing the ground);
        # the GOGACoin is magic, blasts never eat it
        for other in items:
                if bool(other["dying"]) or other == it:
                        continue
                if String(other["kind"]) == "coin":
                        continue
                if other["pos"].distance_to(it["pos"]) <= BLAST_R:
                        _destroy_item(other)
        it["dying"] = true
        var spr: Sprite2D = it["spr"]
        if spr != null and is_instance_valid(spr):
                spr.queue_free()
        items.erase(it)
        _check_cleared()
        if lives <= 0:
                _run_over()
                return
        shake_t = 0.4
        phase = "blast"
        clear_t = BLAST_TIME

func _spawn_blast(pos: Vector2) -> void:
        var frames: Array = []
        for i in 4:
                frames.append(_t("fx_explode_%d.png" % i))
        var anim := {"frames": frames, "t": 0.0, "pos": pos, "spr": null}
        var spr := Sprite2D.new()
        spr.texture = frames[0]
        spr.position = pos
        spr.scale = Vector2(1.6, 1.6)
        fx_layer.add_child(spr)
        anim["spr"] = spr
        blasts.append(anim)
        Jukebox.sfx("gm_blast", 0.0)

## the blasts tick by wall time; a finished anim LEAVES the array (the old
## -99 sentinel lingered forever and re-ticked inside manual tickers - the
## sim drove two ticks into one frame and indexed frames[-1099])
func _tick_blasts(delta: float) -> void:
        for i in range(blasts.size() - 1, -1, -1):
                var b: Dictionary = blasts[i]
                b["t"] += delta
                var idx := int(b["t"] / 0.09)
                var spr: Sprite2D = b["spr"]
                if idx >= 4:
                        if spr != null and is_instance_valid(spr):
                                spr.queue_free()
                        blasts.remove_at(i)
                        continue
                if spr != null and is_instance_valid(spr):
                        spr.texture = b["frames"][idx]

func _spawn_dust() -> void:
        if carried.is_empty():
                return
        var spr: Sprite2D = carried["spr"]
        if spr == null or not is_instance_valid(spr):
                return
        var tex := "dust.png" if rng.randf() < 0.45 else "dust_dark.png"
        var puff := Sprite2D.new()
        puff.texture = _t(tex)
        var sc := clampf(float(carried["r"]) / 44.0, 0.55, 1.5) * 0.7
        puff.scale = Vector2(sc, sc) * rng.randf_range(0.7, 1.15)
        puff.position = spr.position + Vector2(rng.randf_range(-14, 14),
                rng.randf_range(0, 16)) + claw_dir * 6.0
        # THE DARKER-DUST LAW: a translucent dark puff that falls, fades,
        # and frees ITSELF (engine-driven - no manual lifecycle to freeze)
        puff.modulate = Color(0.5, 0.4, 0.3, 0.55)
        dust_layer.add_child(puff)
        var tw := puff.create_tween()
        tw.set_parallel(true)
        tw.tween_property(puff, "position:y",
                puff.position.y + rng.randf_range(22.0, 60.0), 0.55)
        tw.tween_property(puff, "modulate:a", 0.0, 0.55).set_delay(0.08)
        tw.chain().tween_callback(puff.queue_free)

func _tick_rope_sound(delta: float) -> void:
        reel_snd_t -= delta
        if reel_snd_t <= 0.0:
                reel_snd_t = 0.42
                Jukebox.sfx("gm_reel", -9.0)

## THE FLOAT TEXT LAW (v041): every banked thing speaks its price at the
## winch - gold floats its + in the gold ink, a rock floats its NEGATIVE
## tax in the red ink (the rock prices law made visible; the score chip
## carries the running total, negative included).
func _float_pts(pts: int) -> void:
        if pts == 0:
                return
        var lbl := Arc.label("%+d" % pts, 52,
                Color(1, 0.85, 0.3) if pts > 0 else Color(1, 0.45, 0.35))
        lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0))
        lbl.add_theme_constant_override("outline_size", 12)
        lbl.size = Vector2(240, 70)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lbl.z_index = 30
        lbl.position = anchor + Vector2(-120, 150)
        fx_layer.add_child(lbl)
        # the darker-dust law's lifecycle: the floater rises, fades and
        # frees ITSELF (engine-driven - no manual cleanup to freeze)
        var tw := lbl.create_tween().set_parallel(true)
        tw.tween_property(lbl, "position:y", lbl.position.y - 120.0, 0.9) \
                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        tw.tween_property(lbl, "modulate:a", 0.0, 0.55).set_delay(0.35)
        tw.chain().tween_callback(lbl.queue_free)

## the bank: whatever the claw brought home pays here (score + counters +
## the thing's OWN voice - the different-SFX law)
func _bank() -> void:
        phase = "swing"
        claw_spr.texture = _t("claw_open.png")
        claw_spr.offset = Vector2(31.0 - 27.5, 24.0 - 16.0)
        if carried.is_empty():
                Jukebox.sfx("gm_empty", -6.0)
                _check_cleared()    # the blast's last gold clears on the way home
                return
        var kind := String(carried["kind"])
        var pts: int = MinerData.score_for(kind)     # rocks pay NEGATIVE (v041)
        # v041-1 THE SCORE FLOOR LAW (the owner: "make score be only 0 as
        # minimum, so decreasing should always be 0 as minimum because -2 or
        # -24 has no meaning"): the tax still floats red, the total never
        # reads below zero.
        set_score(maxi(score + pts, 0))
        _float_pts(pts)
        achievement_count("golds_taken" if kind.begins_with("gold") else "rocks_taken", 1)
        if bool(carried["coin"]):
                add_run_coins(1)
                achievement_count("coins_taken", 1)
                Jukebox.sfx("gm_coin", 0.0)
        else:
                Jukebox.sfx("gm_%s" % kind, -2.0,
                        rng.randf_range(0.96, 1.05))
        var spr: Sprite2D = carried["spr"]
        if spr != null and is_instance_valid(spr):
                spr.queue_free()
        items.erase(carried)
        carried = {}
        things_banked += 1
        if things_banked % 50 == 0:
                # THE EVERY-50 LAW: a glowing gold joins the remaining golds,
                # or rides the next ground if this one just ended
                _grant_coin()
        _check_cleared()

func _grant_coin() -> void:
        var golds: Array = []
        for it in items:
                if String(it["kind"]).begins_with("gold") \
                                and not bool(it["coin"]):
                        golds.append(it)
        if golds.is_empty():
                coin_pending = true
                return
        _make_coin_carrier(golds[rng.randi_range(0, golds.size() - 1)])
        game_toast("GLOWING GOLD!")

func _destroy_item(it: Dictionary) -> void:
        it["dying"] = true
        var spr: Sprite2D = it["spr"]
        if spr != null and is_instance_valid(spr):
                var tw := spr.create_tween()
                tw.tween_property(spr, "scale", Vector2(0.05, 0.05), 0.18)
                tw.tween_callback(spr.queue_free)
        if String(it["kind"]).begins_with("gold"):
                golds_left -= 1
        items.erase(it)

func _check_cleared() -> void:
        golds_left = 0
        for it in items:
                if String(it["kind"]).begins_with("gold"):
                        golds_left += 1
        if golds_left <= 0 and (phase == "swing" or phase == "reel" \
                        or phase == "blast"):
                # THE CLEAR LAW: every gold taken (or blasted) -> next ground
                Jukebox.sfx("gm_clear", -2.0)
                game_toast("GROUND %d CLEARED!" % level)
                phase = "clear"
                clear_t = CLEAR_TIME

func _run_over() -> void:
        phase = "over"
        Jukebox.sfx("gm_over", 0.0)
        achievement_max("gm_level", level)
        finish_run(score)

## v041-1 r6 THE TIME-UP LAW: the clock hit zero - the ground ends the
## way a cleared ground does (the next one loads, the run lives on). The
## claw drops whatever it holds (nothing banks from a dead ground - the
## honest hand, the score floor law unaffected) and the clear flow's own
## transition takes over from here (level += 1 -> _populate -> the clock
## re-prices).
func _time_up_next_ground() -> void:
        if not carried.is_empty():
                var spr: Sprite2D = carried["spr"]
                if spr != null and is_instance_valid(spr):
                        spr.queue_free()
                items.erase(carried)
                carried = {}
        claw_spr.texture = _t("claw_open.png")
        claw_spr.offset = Vector2(31.0 - 27.5, 24.0 - 16.0)
        phase = "clear"
        clear_t = CLEAR_TIME
        Jukebox.sfx("gm_clear", -2.0)
        game_toast("TIME'S UP - NEXT GROUND")

# ---------------------------------------------------------------- input
func _on_tap(_pos: Vector2) -> void:
        if over or tap_cooldown > 0.0:
                return
        match phase:
                "swing":
                        Jukebox.sfx("gm_launch", -4.0)
                        carried = {}
                        dust_travel = 0.0
                        phase = "fly"
                "fly", "grab", "reel", "blast", "clear", "intro":
                        pass    # one throw at a time - the timing is the game

func _goga_input(event: InputEvent) -> void:
        if over:
                return
        if event is InputEventKey and (event as InputEventKey).pressed \
                        and not (event as InputEventKey).echo:
                # THE PC LAW (the windows return): SPACE works every tap -
                # the claw release. The intro go rides the universal
                # tap-anywhere overlay (any key fires it there).
                if event.is_action_pressed("ui_accept"):
                        _on_tap(Vector2.ZERO)
                return

# ---------------------------------------------------------------- the shop
func _shop_open() -> void:
        if over:
                return
        Jukebox.sfx("gm_click", -6.0)
        var sheet := sheet_push(0.0, "shop")
        var t := Arc.label("GOLD MINER SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 320.0, 640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        box.add_child(Arc.fit_label("MINER SKINS", 24, Arc.HOT, 560))
        for s in MinerData.MINER_SKINS:
                box.add_child(_skin_row("skin_miner", s,
                        func(): rig.texture = _rig_tex()))
        box.add_child(Arc.fit_label("VEIN SKINS", 24, Arc.HOT, 560))
        for s in MinerData.VEIN_SKINS:
                box.add_child(_skin_row("skin_vein", s,
                        func(): _reskin_items()))
        var back := Arc.button("CLOSE", Vector2(560, 72), 26, Arc.GOOD,
                func(): sheet_pop())
        sheet.add_child(back)
        # THE TAP LAW: a BoxScroll swallows raw touches - every button
        # inside registers as a tappable
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

## the vein skin applies LIVE: every gold and rock on the ground re-inks
## (the coin carrier keeps its glow - the coin is magic)
func _reskin_items() -> void:
        for it in items:
                var spr: Sprite2D = it["spr"]
                if spr == null or not is_instance_valid(spr):
                        continue
                var k := String(it["kind"])
                if k == "rock_s":
                        spr.texture = _t("rock_%s_%s.png" % [_vein(),
                                "s2" if String(it["v"]) == "s2" else "s"])
                elif k.begins_with("gold") or k.begins_with("rock"):
                        if bool(it["coin"]):
                                continue
                        spr.texture = _item_tex(k)

## THE SHELF LAWS: the ON row, no dash-talk, one color; buys refresh the
## sheet IN PLACE (the stay-open law); the shop SELLS, the game APPLIES.
func _skin_row(cat: String, s: Dictionary, apply: Callable) -> Control:
        var id := String(s["id"])
        var price := int(s["price"])
        var owned := Box.item_owned(game_id, cat, id) or price == 0
        var on: bool = Box.item_on(game_id, cat) == id \
                or (price == 0 and Box.item_on(game_id, cat) == "")
        if on:
                return Arc.on_row("%s  (ON)" % s["name"])
        if owned:
                return Arc.button(s["name"], Vector2(560, 60), 22, Arc.ACCENT,
                        func():
                                Box.equip_item(game_id, cat, id)
                                Jukebox.sfx("gm_buy", -4.0)
                                apply.call()
                                _shop_reopen())
        var b := Arc.coin_button("%s  %d" % [s["name"], price],
                        Vector2(560, 64), 22, Arc.ACCENT, func():
                                if Box.buy_item(game_id, cat, id, price):
                                        Jukebox.sfx("gm_buy")
                                        Box.equip_item(game_id, cat, id)
                                        apply.call()
                                _shop_reopen())
        if Box.coins() < price:
                b.disabled = true
        return b

func _shop_reopen() -> void:
        sheet_pop()
        _shop_open()

func _goga_sheet_popped(id: String) -> void:
        pass
