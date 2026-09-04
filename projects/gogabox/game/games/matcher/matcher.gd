extends GogaGame
## MATCHER - v0.3.3 PATCH 2, the smooth one. Every motion tweens (the owner:
## "the game is not smooth and has weird instant animations that is totally
## uncanny"), the specials are a SHADER ON THE GEM ITSELF (the owner: "i want
## it to be like a shader on the asset, not a weird VFX that is even not
## synced with the thing movement"), the coin drops like any normal gem and
## auto-collects at the bottom, the powers buy with the GLOBAL GOGACoins, and
## the three Bejeweled-Classic modes follow the owner's specs: Diamond Mine
## rows push up from the bottom every 25s (+25s per cleared row, 60s start),
## Ice Storm grows vertical ice columns (3-segment horizontal melts, full
## vertical destroys, more lines with progression, top = lost), Butterflies
## rise with real animations and the SPIDER hunts the nearest one.
##
## THE OWNER LAWS this file obeys:
##  - "every single thing will be 1 score point, and the bonus will be /300"
##  - "make powerups be based on global GOGACoins and not round-balance"
##  - the shop: "CLEARLY A BUTTON AT THE TOP CALLED SHOP IN EVERY SINGLE GAME"
##    (never a row inside the optionals)
##  - "make it drop down like any normal thing ... when it is in the bottom,
##    it should be auto collected"
##  - "make a lose here takes -500 score points ... only in challenge mode"
##  - PEACE = the snake peace: 0 bonus, 0 coins, no power-ups, END in pause
##  - happy + welcoming atmosphere, vertical-only view, banner strip seated

const COLS := 8
const ROWS := 8
const COLORS := 5

## skins: base gem art per skin. The SPECIALS are a shader on the gem sprite
## (skin-safe by construction - the shader works on any texture). The donut
## skin wears the owner's Match_3_Template donuts + checker cells + backdrop.
const SKINS := {
        "gem": {"name": "Gem Vault", "price": 0,
                "tex": ["res://assets/games/matcher/gems/gem_0.png",
                        "res://assets/games/matcher/gems/gem_1.png",
                        "res://assets/games/matcher/gems/gem_2.png",
                        "res://assets/games/matcher/gems/gem_3.png",
                        "res://assets/games/matcher/gems/gem_4.png"]},
        "candy": {"name": "Candy Shop", "price": 220,
                "tex": ["res://assets/games/matcher/gems/candy_0.png",
                        "res://assets/games/matcher/gems/candy_1.png",
                        "res://assets/games/matcher/gems/candy_2.png",
                        "res://assets/games/matcher/gems/candy_3.png",
                        "res://assets/games/matcher/gems/candy_4.png"]},
        "donut": {"name": "Donut Den", "price": 280,
                "tex": ["res://assets/games/matcher/gems/donut_0.png",
                        "res://assets/games/matcher/gems/donut_1.png",
                        "res://assets/games/matcher/gems/donut_2.png",
                        "res://assets/games/matcher/gems/donut_3.png",
                        "res://assets/games/matcher/gems/donut_4.png"],
                "bg": "res://assets/games/matcher/bg/bg_donut.png",
                "cell": ["res://assets/games/matcher/bg/cell_donut_light.png",
                        "res://assets/games/matcher/bg/cell_donut_dark.png"]},
}
const SKIN_ORDER := ["gem", "candy", "donut"]

## the five modes (Bejeweled Classic shelf, renamed per the owner)
const MODES := {
        "challenge": {"name": "CHALLENGE", "price": 0,
                "card": "res://assets/games/matcher/modes/card_challenge.png",
                "line": "the python matcher, reborn fair"},
        "peace": {"name": "PEACE", "price": 120,
                "card": "res://assets/games/matcher/modes/card_peace.png",
                "line": "zen - no fail, no coins, no rush"},
        "butterflies": {"name": "BUTTERFLIES", "price": 180,
                "card": "res://assets/games/matcher/modes/card_butterflies.png",
                "line": "save them before the spider dines"},
        "ice": {"name": "ICE STORM", "price": 240,
                "card": "res://assets/games/matcher/modes/card_ice.png",
                "line": "melt the rising frost or freeze"},
        "mine": {"name": "DIAMOND MINE", "price": 300,
                "card": "res://assets/games/matcher/modes/card_mine.png",
                "line": "dig deep, beat the clock"},
}
const MODE_ORDER := ["challenge", "peace", "butterflies", "ice", "mine"]

## the bought power-ups (unlock once with the wallet; in-play stock pays the
## GLOBAL GOGACoins - the owner: "make powerups be based on global GOGACoins
## and not round-balance"). Cap 3 per run, the gray-out law stays.
const POWERS := {
        "shuffle": {"name": "Shuffle", "price": 100, "refill": 30,
                "icon": "res://assets/games/matcher/power/p_shuffle.png",
                "desc": "reshuffle the whole board"},
        "line": {"name": "Line Blast", "price": 150, "refill": 45,
                "icon": "res://assets/games/matcher/power/p_line.png",
                "desc": "tap a gem: its row and column blow"},
        "bomb": {"name": "Gem Bomb", "price": 200, "refill": 60,
                "icon": "res://assets/games/matcher/power/p_bomb.png",
                "desc": "tap any cell: a 3x3 blast"},
        "vapor": {"name": "Color Vapor", "price": 260, "refill": 80,
                "icon": "res://assets/games/matcher/power/p_vapor.png",
                "desc": "tap a gem: its whole color vanishes"},
}
const POWER_ORDER := ["shuffle", "line", "bomb", "vapor"]
const POWER_MAX := 3

const COIN_EVERY := 30.0        # the owner's rhythm - from last COLLECTED
const RUN_CLOCK := 300.0        # challenge: the real life of a run
# DIAMOND MINE - the owner's Bejeweled-Classic spec: "each specific like 25
# seconds it makes another row and clearing a row gives extra 25 seconds and
# the round starts with 60 seconds and some times it make two rows"
const MINE_CLOCK := 60.0        # the dig clock starts at 60s
const MINE_ROW_TIME := 25.0     # a new earth row every 25s...
const MINE_ROW_BONUS := 25.0    # ...and a cleared row pays +25s
const MINE_DOUBLE := 0.25       # ...sometimes two rows at once

# ------------------------------------------------------------ state
var skin := "gem"
var mode := "challenge"
var phase := "pick"             # pick -> play (over = the base's flag)
var busy := false               # a resolve/cascade is on the rails
var grid := []                  # ROWS x COLS of cell dicts
var cell_px := 112.0
var board_o := Vector2.ZERO     # board origin (top-left cell corner)

var cascade := 0
var hinted := []                # the two hint cells (pulse)
var idle_clock := 0.0

## mode state
var run_clock := RUN_CLOCK
var round_no := 0
var round_goal := 60
var round_bank := 0             # score banked into the current round
var round_clock := 0.0
var round_time := 60.0
var round_start := 0
var twist := ""                 # "" | "drought" | "rush"
var drought_color := -1
var rush_left := 0.0
var pace := 1                   # butterflies: rows per move
var pace_clock := 45.0
var frost := [0, 0, 0, 0, 0, 0, 0, 0]  # ice: segments per column (bottom-up)
var frost_clock := 8.0
var frost_gap := 8.0
var frost_ticks := 0            # progression: every 4th spawn joins a 2nd line
var temp := 0.0                 # the temperature gauge (0..1)
var melt_chain := 0.0           # consecutive melts within 3s
var melt_plan := {}             # col -> "3" | "all" (built from the wave groups)
var dig_clock := MINE_CLOCK
var mine_rise_clock := MINE_ROW_TIME   # the 25s earth-row clock
var depth := 0                  # earth rows cleared (meters descended)
var earth_top := ROWS           # mine: the first earth row (ROWS = no earth)
var earth := []                 # earth rows: earth[r] = [{tr, node, tr_spr}]

## the coin
var coin_clock := COIN_EVERY
var coin_cell := Vector2i(-1, -1)
var _coin_refill_pending := false

## powers
var charges := {"shuffle": 0, "line": 0, "bomb": 0, "vapor": 0}
var power_used := {"shuffle": 0, "line": 0, "bomb": 0, "vapor": 0}
var armed := ""

## fx pools
var pops := []                  # burst particles {pos, vel, life, max, r, col}
var rings := []                 # shock rings {pos, r, life, max, col, w}
var beams := []                 # star beams {a, b, life, max}
var zaps := []                  # hypercube arcs {a, b, life, max}
var floaters := []              # score texts {pos, txt, life, max, col, size}

## ui refs
var world: Node2D
var bg_spr: Sprite2D
var rail: Control               # the power-up rail (BoxScroll)
var rail_slots := {}            # power id -> {btn, dots, price}
var chip_mode: Label
var chip_info: Label
var chip_info2: Label
var pick_open := false
var first_moment := true        # the boot optionals owns the first tap
var armed_cursor: Sprite2D
var spider: Sprite2D            # butterflies: the hunter on the top rail
var spider_tw: Tween
var wallet_chip: PanelContainer # the buy popup's live full-balance chip

var tex_gem: Array = []
var _tex := {}                  # lazily loaded aux textures


func _skin_textures() -> Array:
        var out := []
        for p in SKINS[skin]["tex"]:
                out.append(load(p))
        return out


func _t(key: String) -> Texture2D:
        if not _tex.has(key):
                var paths := {
                        "coin": "res://assets/ui/coin.png",
                        "cell": "res://assets/games/matcher/bg/cell.png",
                        "cell_donut0": "res://assets/games/matcher/bg/cell_donut_light.png",
                        "cell_donut1": "res://assets/games/matcher/bg/cell_donut_dark.png",
                        "plate": "res://assets/games/matcher/bg/plate.png",
                        "banner": "res://assets/games/matcher/fx/banner.png",
                        "wing": "res://assets/games/matcher/modes/butterfly.png",
                        "spider": "res://assets/games/matcher/modes/spider.png",
                        "ice1": "res://assets/games/matcher/modes/ice_1.png",
                        "ice2": "res://assets/games/matcher/modes/ice_2.png",
                        "ice3": "res://assets/games/matcher/modes/ice_3.png",
                        "earth": "res://assets/games/matcher/modes/earth.png",
                        "gold": "res://assets/games/matcher/modes/gold.png",
                        "diamond": "res://assets/games/matcher/modes/diamond.png",
                        "artifact": "res://assets/games/matcher/modes/artifact.png",
                        "exp0": "res://assets/games/matcher/fx/explosion_0.png",
                        "exp1": "res://assets/games/matcher/fx/explosion_1.png",
                        "exp2": "res://assets/games/matcher/fx/explosion_2.png",
                        "exp3": "res://assets/games/matcher/fx/explosion_3.png",
                        "exp4": "res://assets/games/matcher/fx/explosion_4.png",
                        "exp5": "res://assets/games/matcher/fx/explosion_5.png",
                        "exp6": "res://assets/games/matcher/fx/explosion_6.png",
                        "exp7": "res://assets/games/matcher/fx/explosion_7.png",
                }
                _tex[key] = load(paths[key])
        return _tex[key]

## the specials shader - one material per cell, ON the gem sprite (the owner:
## "like a shader on the asset")
var _special_shader: Shader

func _special_mat(kind: String) -> ShaderMaterial:
        if _special_shader == null:
                _special_shader = load("res://assets/games/matcher/specials/special.gdshader")
        var m := ShaderMaterial.new()
        m.shader = _special_shader
        m.set_shader_parameter("special",
                        1 if kind == "flame" else (2 if kind == "star" else 3))
        return m


## v0.3.3-p2 THE WING BAKE: a butterfly's wings are COMPOSED INTO its own
## texture (gem art + the monarch sheet) - the sprite moves as one thing,
## so nothing can ever desync or overlap again (the owner's "flies corrupt
## the line and overlap things" bug died with the separate overlay node).
var _wing_bake := {}     # (skin|color) -> ImageTexture

func _cell_texture(color: int, wing: bool) -> Texture2D:
        var base: Texture2D = tex_gem[color % tex_gem.size()]
        if not wing:
                return base
        var key := "%s|%d" % [skin, color]
        if _wing_bake.has(key):
                return _wing_bake[key]
        var img: Image = base.get_image()
        if img == null:
                return base
        if img.is_compressed():
                img.decompress()
        img.convert(Image.FORMAT_RGBA8)
        var wing_img: Image = (_t("wing") as Texture2D).get_image()
        if wing_img != null:
                if wing_img.is_compressed():
                        wing_img.decompress()
                wing_img.convert(Image.FORMAT_RGBA8)
                # scale the wing sheet onto the gem square, centered
                var size := img.get_width()
                var wimg := Image.create(size, size, false, Image.FORMAT_RGBA8)
                wimg.fill(Color(0, 0, 0, 0))
                var scale_f := float(size) / float(wing_img.get_width()) * 1.15
                var dw := int(wing_img.get_width() * scale_f)
                var dh := int(wing_img.get_height() * scale_f)
                wing_img.resize(dw, dh, Image.INTERPOLATE_LANCZOS)
                var ox := (size - dw) / 2
                var oy := (size - dh) / 2
                wimg.blend_rect(wing_img, Rect2i(0, 0, dw, dh), Vector2i(ox, oy))
                img.blend_rect(wimg, Rect2i(0, 0, size, size), Vector2i(0, 0))
        var tex := ImageTexture.create_from_image(img)
        _wing_bake[key] = tex
        return tex


func _retexture_cell(r: int, c: int) -> void:
        var cell: Dictionary = grid[r][c]
        if cell.is_empty() or not is_instance_valid(cell.get("node")):
                return
        var n: Sprite2D = cell["node"]
        if _is_coin(cell):
                n.texture = _t("coin")
                return
        n.texture = _cell_texture(int(cell["color"]), bool(cell.get("wing", false)))
        _dress_special(r, c)


## THE TOP BANNER (v0.3.3-p2, the owner: a lose/round message "appears inside
## the grid and not somewhere at the top as example"): the template's ribbon
## rides just under the HUD, slides in, fades out. Every mode event speaks
## here - never inside the grid again.
func _banner(txt: String, good := true) -> void:
        var root := _overlay_root_ref()
        var holder := Control.new()
        holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
        holder.set_anchors_preset(Control.PRESET_TOP_WIDE)
        holder.offset_top = 186.0
        holder.offset_bottom = 306.0
        root.add_child(holder)
        var ribbon := TextureRect.new()
        ribbon.texture = _t("banner")
        ribbon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ribbon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ribbon.set_anchors_preset(Control.PRESET_FULL_RECT)
        ribbon.offset_left = 190.0
        ribbon.offset_right = -190.0
        ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        ribbon.modulate = Color(1, 1, 1, 0.0)
        holder.add_child(ribbon)
        var l := Arc.fit_label(txt, 30, Arc.INK, 620)
        l.set_anchors_preset(Control.PRESET_FULL_RECT)
        l.offset_bottom = -18.0
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        l.modulate.a = 0.0
        holder.add_child(l)
        var tw := holder.create_tween()
        tw.set_parallel(true)
        tw.tween_property(ribbon, "modulate:a", 1.0, 0.22)
        tw.tween_property(l, "modulate:a", 1.0, 0.22)
        tw.chain().tween_interval(1.15)
        tw.chain().tween_property(holder, "modulate:a", 0.0, 0.3)
        tw.chain().tween_callback(holder.queue_free)


# ================================================================ setup
## THE UNFREEZE LAW (the invaders defend-freeze class): the picker and the
## power sheets pause the whole tree. If the host tears the game down while
## a sheet lives (quit from the box, the run-end flow), the tree would stay
## paused FOREVER - the box frozen under a dead game. Exiting always thaws.
func _exit_tree() -> void:
        get_tree().paused = false


func _goga_setup() -> void:
        skin = String(Box.get_progress(game_id, "skin", "gem"))
        if not SKINS.has(skin):
                skin = "gem"
        tex_gem = _skin_textures()
        bonus_div_override = 300       # the owner: "the bonus will be /300"
        if mode == "peace":
                score_bonus_enabled = false
                pause_end_run = true
        var vp := get_viewport_rect().size
        cell_px = floorf(minf((vp.x - 88.0) / float(COLS), (vp.y * 0.42) / float(ROWS)))
        world = Node2D.new()
        add_child(world)
        _build_background(vp)
        _build_board_plate()
        _build_hud_extras()
        _build_spider()
        _build_rail()
        _ready_input()
        # THE UNIVERSAL SHOP BUTTON (the owner: "the shop IS CLEARLY A BUTTON
        # AT THE TOP CALLED SHOP IN EVERY SINGLE GAME") - the optionals sheet
        # never sells again
        add_hud_button("SHOP", func(): _shop_open())
        Jukebox.music("res://assets/audio/music/matcher_happy.mp3")
        _pick_open(true)


func _build_background(vp: Vector2) -> void:
        var path := "res://assets/games/matcher/bg/bg_day.png"
        if mode == "peace":
                path = "res://assets/games/matcher/bg/bg_peace.png"
        # the donut skin wears its own template backdrop
        if skin == "donut" and mode != "peace" and SKINS[skin].has("bg"):
                path = String(SKINS[skin]["bg"])
        bg_spr = Sprite2D.new()
        bg_spr.texture = load(path)
        var ts := Vector2(vp.x / bg_spr.texture.get_width(), vp.y / bg_spr.texture.get_height())
        bg_spr.scale = Vector2.ONE * maxf(ts.x, ts.y)
        bg_spr.position = vp / 2.0
        bg_spr.z_index = -20
        world.add_child(bg_spr)


func _board_pixel() -> Vector2:
        return Vector2(COLS, ROWS) * cell_px


func _cell_pos(r: int, c: int) -> Vector2:
        return board_o + Vector2(float(c) + 0.5, float(r) + 0.5) * cell_px


func _pos_to_cell(p: Vector2) -> Vector2i:
        var f := (p - board_o) / cell_px
        var c := int(floorf(f.x))
        var r := int(floorf(f.y))
        if r < 0 or c < 0 or r >= ROWS or c >= COLS:
                return Vector2i(-1, -1)
        return Vector2i(r, c)


func _build_board_plate() -> void:
        var vp := get_viewport_rect().size
        var bp := _board_pixel()
        board_o = Vector2((vp.x - bp.x) * 0.5, clampf(vp.y * 0.30, 330.0, vp.y - bp.y - banner_bottom() - 300.0))
        var plate := Sprite2D.new()
        plate.texture = _t("plate")
        plate.centered = false
        plate.position = board_o - Vector2(12, 12)
        plate.scale = Vector2.ONE * cell_px / 120.0
        plate.z_index = -10
        world.add_child(plate)
        var checker: Array = []
        if SKINS[skin].has("cell"):
                checker.append(load(String(SKINS[skin]["cell"][0])))
                checker.append(load(String(SKINS[skin]["cell"][1])))
        for r in ROWS:
                for c in COLS:
                        var cell := Sprite2D.new()
                        cell.texture = _t("cell") if checker.is_empty() \
                                        else checker[(r + c) % 2]
                        cell.centered = false
                        cell.position = board_o + Vector2(c, r) * cell_px
                        cell.scale = Vector2.ONE * cell_px / 120.0
                        cell.z_index = -8
                        world.add_child(cell)


func _build_hud_extras() -> void:
        # v0.3.3-p2 THE NOTCH LAW (the owner: "move the widgets under the
        # GOGACoins row ... they behind the physical front camera, make it go
        # down"): the top bar sits LOWER (clears the camera cutout) and the
        # mode chips get their OWN second row under it
        if _hud_row != null and is_instance_valid(_hud_row):
                _hud_row.offset_top = 44.0
                _hud_row.offset_bottom = 108.0
        var row2 := HBoxContainer.new()
        row2.set_anchors_preset(Control.PRESET_TOP_WIDE)
        row2.offset_left = 14
        row2.offset_right = -14
        row2.offset_top = 116.0
        row2.offset_bottom = 170.0
        row2.alignment = BoxContainer.ALIGNMENT_CENTER
        row2.add_theme_constant_override("separation", 10)
        row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hud.add_child(row2)
        var cm := Arc.chip("", "", Color(0, 0, 0, 0.4), 22, Arc.CARD)
        var ci := Arc.chip("", "", Color(0, 0, 0, 0.4), 22, Arc.CARD)
        var ci2 := Arc.chip("", "", Color(0, 0, 0, 0.4), 22, Arc.CARD)
        row2.add_child(cm)
        row2.add_child(ci)
        row2.add_child(ci2)
        chip_mode = cm.get_child(0).get_child(cm.get_child(0).get_child_count() - 1)
        chip_info = ci.get_child(0).get_child(ci.get_child(0).get_child_count() - 1)
        chip_info2 = ci2.get_child(0).get_child(ci2.get_child(0).get_child_count() - 1)
        _refresh_hud()


func _build_spider() -> void:
        if spider != null and is_instance_valid(spider):
                spider.queue_free()
        spider = null
        if mode != "butterflies":
                return
        var sp := Sprite2D.new()
        sp.texture = _t("spider")
        sp.position = Vector2(board_o.x + _board_pixel().x * 0.5, board_o.y - 92)
        sp.scale = Vector2.ONE * (cell_px / 160.0) * 1.3
        sp.z_index = 12
        world.add_child(sp)
        spider = sp


# ================================================================ the optionals
## THE OPTIONALS SCREEN (v0.3.3-p2 THE UNIVERSAL SHAPE): one scrollable
## sheet, one IMAGE box per mood, the skins row - and NO SHOP ROW (the
## owner: "it should not has the shop there, the shop IS CLEARLY A BUTTON AT
## THE TOP CALLED SHOP IN EVERY SINGLE GAME"). It rides the base sheet
## stack, never pauses the tree (the phase gates the play), so the HUD back
## button and the Android back CLOSE it - the owner's dead-back report.

func _pick_open(first := false) -> void:
        if pick_open:
                return
        pick_open = true
        var sheet := sheet_push(0.0, "pick")
        var title := Arc.fit_label("OPTIONALS - THE MOOD SHELF", 34, Arc.HOT, 560)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(title)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(620, clampf(vp.y * 0.5, 340.0, 700.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 10)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        var grid := GridContainer.new()
        grid.columns = 2
        grid.add_theme_constant_override("h_separation", 12)
        grid.add_theme_constant_override("v_separation", 12)
        grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        box.add_child(grid)
        for id in MODE_ORDER:
                grid.add_child(_pick_card(id))
        var st := Arc.fit_label("THE SKINS - THE GEMS YOU MATCH WITH", 20, Arc.HOT, 560)
        st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(st)
        var skinrow := HBoxContainer.new()
        skinrow.alignment = BoxContainer.ALIGNMENT_CENTER
        skinrow.add_theme_constant_override("separation", 10)
        skinrow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        box.add_child(skinrow)
        for sid in SKIN_ORDER:
                skinrow.add_child(_skin_chip(sid))
        var cb := Arc.button("TO THE BOARD" if first_moment else "CLOSE",
                        Vector2(0, 78), 26, Arc.GOOD, func():
                        var go := first_moment and phase != "play"
                        _pick_close()
                        if go:
                                _start_mode(mode))
        cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        box.add_child(cb)
        _pick_finish(sc)


func _pick_finish(sc: BoxScroll) -> void:
        # THE TAPPABLE LAW: BoxScroll owns taps inside scrolls - an
        # unregistered button never fires (the old picker's dead taps)
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))


func _pick_card(id: String) -> Button:
        var m: Dictionary = MODES[id]
        var owned: bool = int(m["price"]) == 0 or Box.item_owned(game_id, "modes", id)
        var on: bool = mode == id and owned
        var b := Button.new()
        b.custom_minimum_size = Vector2(292, 214)
        var sb := Arc.panel_style(Arc.CARD if owned else Color(0.86, 0.82, 0.74, 0.96), 20, 6)
        if on:
                sb.set_border_width_all(4)
                sb.border_color = Arc.GOOD
        b.add_theme_stylebox_override("normal", sb)
        var sbp := sb.duplicate() as StyleBoxFlat
        sbp.bg_color = sbp.bg_color.darkened(0.05)
        b.add_theme_stylebox_override("pressed", sbp)
        var v := VBoxContainer.new()
        v.set_anchors_preset(Control.PRESET_FULL_RECT)
        v.offset_left = 10
        v.offset_right = -10
        v.offset_top = 10
        v.offset_bottom = -8
        v.mouse_filter = Control.MOUSE_FILTER_IGNORE
        v.add_theme_constant_override("separation", 4)
        b.add_child(v)
        var art := TextureRect.new()
        art.texture = load(String(m["card"]))
        art.custom_minimum_size = Vector2(260, 112)
        art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        art.mouse_filter = Control.MOUSE_FILTER_IGNORE
        if not owned:
                art.modulate = Color(1, 1, 1, 0.5)
        v.add_child(art)
        var l := Arc.fit_label(String(m["name"]), 24, Arc.INK, 272)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        v.add_child(l)
        if owned:
                var st := Arc.fit_label("PICKED - TAP TO PLAY" if on else "TAP TO PLAY",
                                16, Color("2c8a44"), 272)
                st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                st.mouse_filter = Control.MOUSE_FILTER_IGNORE
                v.add_child(st)
                # THE START LAW (the owner: "whenever I select something, the
                # game does not start"): an owned mood ALWAYS starts on tap -
                # the picked card included
                b.pressed.connect(func():
                                Jukebox.sfx("confirm", -4.0)
                                _pick_close()
                                _start_mode(id))
        else:
                var chip := Arc.chip(str(int(m["price"])), "res://assets/ui/coin.png",
                                Color(0, 0, 0, 0.5), 16, Arc.COIN)
                chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
                chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
                v.add_child(chip)
                # THE SNAKE LAW: a locked box's tap opens the shop
                b.pressed.connect(func(): _shop_open())
        return b


func _skin_chip(sid: String) -> Button:
        var s: Dictionary = SKINS[sid]
        var owned: bool = int(s["price"]) == 0 or Box.skin_owned(game_id, sid)
        var on := skin == sid and owned
        var b := Button.new()
        b.custom_minimum_size = Vector2(290, 84)
        var sb := Arc.panel_style(Arc.CARD_2 if owned else Color(0.85, 0.8, 0.72, 0.95), 16, 4)
        if on:
                sb.set_border_width_all(3)
                sb.border_color = Arc.GOOD
        b.add_theme_stylebox_override("normal", sb)
        var sbp := sb.duplicate() as StyleBoxFlat
        sbp.bg_color = sbp.bg_color.darkened(0.05)
        b.add_theme_stylebox_override("pressed", sbp)
        var h := HBoxContainer.new()
        h.set_anchors_preset(Control.PRESET_FULL_RECT)
        h.offset_left = 12
        h.offset_right = -12
        h.mouse_filter = Control.MOUSE_FILTER_IGNORE
        h.add_theme_constant_override("separation", 10)
        b.add_child(h)
        var ic := TextureRect.new()
        ic.texture = load(String(s["tex"][0]))
        ic.custom_minimum_size = Vector2(52, 52)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        h.add_child(ic)
        var txt := String(s["name"]).to_upper()
        if on:
                txt += "  - ON"
        elif owned:
                txt += "  - TAP TO WEAR"
        else:
                txt += "  %d" % int(s["price"])
        var l := Arc.fit_label(txt, 17, Arc.INK, 210)
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        h.add_child(l)
        if on:
                b.disabled = true
        elif owned:
                b.pressed.connect(func(): _pick_equip_skin(sid))
        else:
                b.pressed.connect(func(): _shop_open())
        return b


func _pick_equip_skin(sid: String) -> void:
        Box.equip_skin(game_id, sid)
        skin = sid
        _refresh_board_skin()
        Jukebox.sfx("confirm", -3.0)
        _pick_rebuild()


## the stack-safe rebuild: the live optionals pops, a fresh one pushes
func _pick_rebuild() -> void:
        _pick_down()
        _pick_open(false)


func _pick_close() -> void:
        _pick_down()


func _pick_down() -> void:
        if not pick_open:
                return
        pick_open = false
        sheet_pop()


## the base closed a sheet for us (the back button) - keep the flags honest
func _goga_sheet_popped(id: String) -> void:
        match id:
                "pick":
                        pick_open = false
                "power":
                        wallet_chip = null


# ================================================================ the shop
## THE SHOP (v0.3.3-p2): the HUD's top SHOP button is its only door. It
## pushes ON TOP of whatever is live (the optionals stays beneath it and
## comes back on close - the stack owns the layering), never pauses the
## tree, and every rebuild is pop-then-push (no orphan dims). Every price
## is paid from the FULL GOGABox wallet.

func _shop_open() -> void:
        var sheet := sheet_push(0.0, "shop")
        var title := Arc.fit_label("MATCHER SHOP", 34, Arc.INK, 560)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(title)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(620, clampf(vp.y * 0.5, 340.0, 700.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        var sec := Arc.fit_label("THE MOODS - BUY ONE, PICK IT IN OPTIONALS", 20, Arc.HOT, 560)
        sec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(sec)
        for id in MODE_ORDER:
                box.add_child(_shop_mode_row(id))
        var sec2 := Arc.fit_label("THE SKINS", 20, Arc.HOT, 560)
        sec2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(sec2)
        box.add_child(_shop_skin_row("candy"))
        box.add_child(_shop_skin_row("donut"))
        var sec3 := Arc.fit_label("THE POWERS - UNLOCK ONCE, STOCK IN PLAY", 20, Arc.HOT, 560)
        sec3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(sec3)
        for pid in POWER_ORDER:
                box.add_child(_shop_power_row(pid))
        var cb := Arc.button("CLOSE", Vector2(0, 74), 24, Arc.GOOD, func(): _shop_close())
        cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        box.add_child(cb)
        _pick_finish(sc)


## the stack-safe rebuild: the live shop pops, a fresh one pushes
func _shop_rebuild() -> void:
        _shop_down()
        _shop_open()


func _shop_mode_row(id: String) -> Control:
        var m: Dictionary = MODES[id]
        if int(m["price"]) == 0 or Box.item_owned(game_id, "modes", id):
                var l := Arc.fit_label("%s  -  OWNED" % String(m["name"]).to_upper(),
                                20, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        var b := Arc.coin_button("%s  -  %d" % [String(m["name"]).to_upper(), int(m["price"])],
                        Vector2(0, 64), 22, Color("8a4ab8"), func():
                        if Box.buy_item(game_id, "modes", id, int(m["price"])):
                                Jukebox.sfx("m_goal", -4.0)
                                Arc.confetti(_overlay_root_ref(), get_viewport_rect().size / 2.0, 30)
                        else:
                                Jukebox.sfx("error", -6.0)
                                _toast_show("need %d more coins" %
                                                (int(m["price"]) - Box.coins()))
                        _shop_rebuild())
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        if Box.coins() < int(m["price"]):
                b.disabled = true
        return b


func _shop_skin_row(sid: String) -> Control:
        var s: Dictionary = SKINS[sid]
        if Box.skin_owned(game_id, sid) or int(s["price"]) == 0:
                var l := Arc.fit_label("%s  -  OWNED (WEAR IT IN OPTIONALS)" % String(s["name"]).to_upper(),
                                20, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        var b := Arc.coin_button("%s  -  %d" % [String(s["name"]).to_upper(), int(s["price"])],
                        Vector2(0, 64), 22, Color("c45a9a"), func():
                        if Box.buy_skin(game_id, sid, int(s["price"])):
                                skin = sid
                                _refresh_board_skin()
                                Jukebox.sfx("m_goal", -4.0)
                                Arc.confetti(_overlay_root_ref(), get_viewport_rect().size / 2.0, 30)
                        else:
                                Jukebox.sfx("error", -6.0)
                                _toast_show("need %d more coins" %
                                                (int(s["price"]) - Box.coins()))
                        _shop_rebuild())
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        if Box.coins() < int(s["price"]):
                b.disabled = true
        return b


func _shop_power_row(pid: String) -> Control:
        var p: Dictionary = POWERS[pid]
        if Box.item_owned(game_id, "power", pid):
                var l := Arc.fit_label("%s  -  OWNED" % String(p["name"]).to_upper(),
                                20, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        var b := Arc.coin_button("%s  -  %d" % [String(p["name"]).to_upper(), int(p["price"])],
                        Vector2(0, 64), 22, Color("4a7ab8"), func():
                        if Box.buy_item(game_id, "power", pid, int(p["price"])):
                                Jukebox.sfx("m_goal", -4.0)
                                Arc.confetti(_overlay_root_ref(), get_viewport_rect().size / 2.0, 30)
                                _refresh_rail()
                        else:
                                Jukebox.sfx("error", -6.0)
                                _toast_show("need %d more coins" %
                                                (int(p["price"]) - Box.coins()))
                        _shop_rebuild())
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        if Box.coins() < int(p["price"]):
                b.disabled = true
        return b


func _shop_close() -> void:
        _shop_down()


func _shop_down() -> void:
        sheet_pop()


func _refresh_board_skin() -> void:
        tex_gem = _skin_textures()
        # THE EMPTY-BOARD LAW (v0.3.3-p1): the optionals lives BEFORE the
        # first deal - a skin bought there must not index an unborn grid
        # (the old index error killed the callback mid-sheet and the paused
        # tree froze the app = the owner's "the app crashed")
        for r in ROWS:
                if grid.size() <= r:
                        return
                for c in COLS:
                        if grid[r].size() <= c:
                                continue
                        if _in_earth(r):
                                continue
                        var cell: Dictionary = grid[r][c]
                        if cell.is_empty() or int(cell.get("color", -1)) < 0:
                                continue
                        var n: Sprite2D = cell["node"]
                        n.texture = _cell_texture(int(cell["color"]), bool(cell.get("wing", false)))


# ================================================================ mode start
func _start_mode(id: String) -> void:
        mode = id
        first_moment = false
        phase = "play"
        chip_mode.text = String(MODES[id]["name"])
        run_clock = RUN_CLOCK
        round_no = 0
        pace = 1
        pace_clock = 45.0
        frost = [0, 0, 0, 0, 0, 0, 0, 0]
        frost_clock = 7.0
        frost_gap = 7.0
        temp = 0.0
        frost_ticks = 0
        melt_plan = {}
        dig_clock = MINE_CLOCK
        mine_rise_clock = MINE_ROW_TIME
        depth = 0
        earth_top = ROWS
        coin_clock = COIN_EVERY
        coin_cell = Vector2i(-1, -1)
        charges = {"shuffle": 0, "line": 0, "bomb": 0, "vapor": 0}
        power_used = {"shuffle": 0, "line": 0, "bomb": 0, "vapor": 0}
        armed = ""
        if mode == "peace":
                score_bonus_enabled = false
                pause_end_run = true
                Jukebox.music("res://assets/audio/music/matcher_peace.wav")
        else:
                score_bonus_enabled = true
                pause_end_run = false
                Jukebox.music("res://assets/audio/music/matcher_happy.mp3")
        _deal_board()
        if mode == "challenge":
                # THE FIRST ROUND LAW: round 1 rolls BEFORE the first tick - the old
                # deal started round_clock at 0 and every run ate an instant -500 gong
                round_no = 1
                _roll_round()
        # v0.3.3-p2: the spider only ever lived on the boot screen's mode - a
        # butterflies run started from the picker had NONE (the owner's "there
        # is no spider?")
        _build_spider()
        _refresh_rail()
        _refresh_hud()


func _first_tick_guard() -> bool:
        return phase == "play" and not over


## the gem spawn - mode-aware weights (the challenge drought twist bends one
## color rare; never to zero - a starved board is the OLD static machine)
func _roll_color() -> int:
        var weights := []
        for i in COLORS:
                var w := 1.0
                if twist == "drought" and i == drought_color:
                        w = 0.25
                weights.append(w)
        var total := 0.0
        for w in weights:
                total += w
        var roll := randf() * total
        for i in COLORS:
                roll -= weights[i]
                if roll <= 0.0:
                        return i
        return COLORS - 1


func _new_cell(r: int, c: int, from_y := -1.0) -> Dictionary:
        var col := _roll_color()
        var n := Sprite2D.new()
        n.texture = tex_gem[col % tex_gem.size()]
        var target := _cell_pos(r, c)
        n.position = Vector2(target.x, target.y if from_y < 0.0 else from_y)
        n.scale = Vector2.ONE * cell_px / 100.0
        n.z_index = 2
        world.add_child(n)
        return {"color": col, "special": "", "wing": false, "node": n}


func _deal_board() -> void:
        # clear any old nodes
        for r in ROWS:
                for c in COLS:
                        if grid.size() > r and grid[r].size() > c and not grid[r][c].is_empty():
                                var old: Dictionary = grid[r][c]
                                if is_instance_valid(old.get("node")):
                                        old["node"].queue_free()
        grid = []
        for r in ROWS:
                var row := []
                for c in COLS:
                        row.append({})
                grid.append(row)
        earth = []
        if mode == "mine":
                earth_top = ROWS - 1          # ONE earth row waits at the bottom
                earth.resize(ROWS)
                _lay_earth_row(earth_top, 1.0)
        for r in ROWS:
                if _in_earth(r):
                        continue
                for c in COLS:
                        var cell := _new_cell(r, c, _cell_pos(r, c).y - 420.0)
                        grid[r][c] = cell
        # kill the dealt-in matches quietly (reroll the offending cells)
        var guard := 0
        while not _find_matches().is_empty() and guard < 200:
                guard += 1
                for g in _find_matches():
                        for key in g["cells"]:
                                var r := int(key) / COLS
                                var c := int(key) % COLS
                                var cell: Dictionary = grid[r][c]
                                if is_instance_valid(cell.get("node")):
                                        cell["node"].texture = tex_gem[0]
                                cell["color"] = _roll_color()
                                if is_instance_valid(cell.get("node")):
                                        cell["node"].texture = tex_gem[int(cell["color"])]
        if mode == "ice":
                for i in 3:
                        frost[randi() % COLS] = 1
                _refresh_ice()
        if mode == "butterflies":
                for c in [1, 4, 6]:
                        _hatch_butterfly(ROWS - 1, c)
        _deal_animate()


func _deal_animate() -> void:
        for r in ROWS:
                for c in COLS:
                        if _in_earth(r):
                                continue
                        var cell: Dictionary = grid[r][c]
                        if cell.is_empty():
                                continue
                        var n: Sprite2D = cell["node"]
                        var target := _cell_pos(r, c)
                        var tw := n.create_tween()
                        tw.tween_property(n, "position", target, 0.3 + 0.02 * float(r)) \
                                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _in_earth(r: int) -> bool:
        # v0.3.3-p2 THE MINE PUSHES FROM THE BOTTOM (the owner's Bejeweled
        # Classic spec): the earth band grows UPWARD from the bottom row -
        # earth_top = the first earth row, ROWS = no earth at all
        return mode == "mine" and r >= earth_top


# ================================================================ the model
## cell kinds: every playable cell holds a gem dict. A coin cell replaces
## the gem (color -1). The mine's earth band lives OUTSIDE the grid.

func _is_coin(cell: Dictionary) -> bool:
        return int(cell.get("color", -1)) == -1 and cell.has("coin")


func _playable(r: int, c: int) -> bool:
        if c < 0 or c >= COLS or r < 0 or r >= ROWS:
                return false
        return not _in_earth(r)


func _color_at(r: int, c: int) -> int:
        if not _playable(r, c):
                return -2
        var cell: Dictionary = grid[r][c]
        if cell.is_empty() or _is_coin(cell):
                return -1
        return int(cell["color"])


## scan for matches. Returns a list of groups:
##   {cells: {key:int -> true}, dir: "h"|"v", len: int, cross: Vector2i or (-1,-1)}
## The cross is the L/T/+ intersection point (the star gem's birthplace).
func _find_matches() -> Array:
        var runs := []
        # rows
        for r in ROWS:
                if _in_earth(r):
                        continue
                var c := 0
                while c < COLS:
                        var col := _color_at(r, c)
                        if col < 0:
                                c += 1
                                continue
                        var e := c
                        while e + 1 < COLS and _color_at(r, e + 1) == col:
                                e += 1
                        if e - c + 1 >= 3:
                                var cells := {}
                                for k in range(c, e + 1):
                                        cells[r * COLS + k] = true
                                runs.append({"cells": cells, "dir": "h", "len": e - c + 1,
                                                "color": col, "cross": Vector2i(-1, -1)})
                        c = e + 1
        # cols
        for c in COLS:
                var r := 0
                while r < ROWS:
                        if _in_earth(r):
                                r += 1
                                continue
                        var col := _color_at(r, c)
                        if col < 0:
                                r += 1
                                continue
                        var e := r
                        while e + 1 < ROWS and not _in_earth(e + 1) and _color_at(e + 1, c) == col:
                                e += 1
                        if e - r + 1 >= 3:
                                var cells := {}
                                for k in range(r, e + 1):
                                        cells[k * COLS + c] = true
                                runs.append({"cells": cells, "dir": "v", "len": e - r + 1,
                                                "color": col, "cross": Vector2i(-1, -1)})
                        r = e + 1
        if runs.is_empty():
                return []
        # merge overlapping runs into groups; a cross of an h and a v run of the
        # same color = the star shape
        var groups := []
        var used := []
        for i in runs.size():
                if used.has(i):
                        continue
                var g: Dictionary = runs[i].duplicate()
                g["cells"] = (runs[i]["cells"] as Dictionary).duplicate()
                used.append(i)
                for j in range(i + 1, runs.size()):
                        if used.has(j):
                                continue
                        var o: Dictionary = runs[j]
                        if int(o["color"]) != int(g["color"]):
                                continue
                        var share := false
                        for key in o["cells"]:
                                if (g["cells"] as Dictionary).has(key):
                                        share = true
                                        break
                        if not share:
                                continue
                        used.append(j)
                        for key in o["cells"]:
                                g["cells"][key] = true
                        g["len"] = int(g["len"]) + int(o["len"])
                        if String(o["dir"]) != String(g["dir"]):
                                # the intersection cell: the shared key
                                for key in o["cells"]:
                                        if (runs[i]["cells"] as Dictionary).has(key):
                                                g["cross"] = Vector2i(int(key) / COLS, int(key) % COLS)
                groups.append(g)
        return groups


## any legal swap on the board? (the deadlock check - brute force, 8x8 is
## nothing for a probe fuzz to churn)
func _has_valid_move() -> bool:
        for r in ROWS:
                for c in COLS:
                        if not _playable(r, c) or grid[r][c].is_empty():
                                continue
                        for d in [Vector2i(0, 1), Vector2i(1, 0)]:
                                var r2: int = r + d.x
                                var c2: int = c + d.y
                                if not _playable(r2, c2) or grid[r2][c2].is_empty():
                                        continue
                                if _is_coin(grid[r][c]) or _is_coin(grid[r2][c2]):
                                        continue
                                # hypercube swap is ALWAYS legal (it detonates on contact)
                                if String(grid[r][c].get("special", "")) == "hyper" \
                                                or String(grid[r2][c2].get("special", "")) == "hyper":
                                        return true
                                _swap_model(r, c, r2, c2)
                                var ok := not _find_matches().is_empty()
                                _swap_model(r, c, r2, c2)
                                if ok:
                                        return true
        return false


func _find_a_move() -> Array:
        for r in ROWS:
                for c in COLS:
                        if not _playable(r, c) or grid[r][c].is_empty():
                                continue
                        for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
                                var r2: int = r + d.x
                                var c2: int = c + d.y
                                if not _playable(r2, c2) or grid[r2][c2].is_empty():
                                        continue
                                if _is_coin(grid[r][c]) or _is_coin(grid[r2][c2]):
                                        continue
                                if String(grid[r][c].get("special", "")) == "hyper" \
                                                or String(grid[r2][c2].get("special", "")) == "hyper":
                                        return [Vector2i(r, c), Vector2i(r2, c2)]
                                _swap_model(r, c, r2, c2)
                                var ok := not _find_matches().is_empty()
                                _swap_model(r, c, r2, c2)
                                if ok:
                                        return [Vector2i(r, c), Vector2i(r2, c2)]
        return []


func _swap_model(r1: int, c1: int, r2: int, c2: int) -> void:
        var a: Dictionary = grid[r1][c1]
        grid[r1][c1] = grid[r2][c2]
        grid[r2][c2] = a


# ================================================================ input
var sel := Vector2i(-1, -1)

func _goga_input(_event: InputEvent) -> void:
        pass


func _ready_input() -> void:
        tk.tapped.connect(func(p): _tap(p))
        tk.dragged.connect(func(from, to): _drag(from, to))


func _tap(p: Vector2) -> void:
        if phase != "play" or busy or over or paused or pick_open \
                        or sheet_open_count() > 0:
                return
        idle_clock = 0.0
        var cellp := _pos_to_cell(p)
        if armed != "":
                _fire_power(cellp)
                return
        if cellp.x < 0:
                _select(Vector2i(-1, -1))
                return
        if mode == "mine" and _in_earth(cellp.x):
                return
        _select(cellp)


func _drag(from: Vector2, to: Vector2) -> void:
        if phase != "play" or busy or over or paused or pick_open \
                        or sheet_open_count() > 0:
                return
        if armed != "":
                return
        idle_clock = 0.0
        var a := _pos_to_cell(from)
        if a.x < 0:
                return
        var d := to - from
        if d.length() < cell_px * 0.35:
                return
        var dir := Vector2i(0, 0)
        if absf(d.x) > absf(d.y):
                dir = Vector2i(0, 1 if d.x > 0 else -1)
        else:
                dir = Vector2i(1 if d.y > 0 else -1, 0)
        var b := a + dir
        if not _playable(b.x, b.y):
                return
        sel = Vector2i(-1, -1)
        _try_swap(a, b)


func _select(cellp: Vector2i) -> void:
        if cellp.x < 0:
                sel = Vector2i(-1, -1)
                _paint_selection()
                return
        if sel.x < 0:
                sel = cellp
                Jukebox.sfx("click", -10.0)
        elif sel == cellp:
                sel = Vector2i(-1, -1)
        else:
                var d := Vector2i(absf(sel.x - cellp.x), absf(sel.y - cellp.y))
                var adjacent: bool = d.x + d.y == 1
                var a := sel
                sel = Vector2i(-1, -1)
                if adjacent:
                        _try_swap(a, cellp)
                else:
                        sel = cellp
                        Jukebox.sfx("click", -10.0)
        _paint_selection()


func _paint_selection() -> void:
        for r in ROWS:
                for c in COLS:
                        if grid.size() <= r or grid[r].size() <= c:
                                continue
                        var cell: Dictionary = grid[r][c]
                        if cell.is_empty() or not is_instance_valid(cell.get("node")):
                                continue
                        var n: Sprite2D = cell["node"]
                        if sel == Vector2i(r, c):
                                n.modulate = Color(1.25, 1.25, 1.1)
                        else:
                                n.modulate = Color.WHITE


func _try_swap(a: Vector2i, b: Vector2i) -> void:
        if busy or not _playable(a.x, a.y) or not _playable(b.x, b.y):
                return
        var ca: Dictionary = grid[a.x][a.y]
        var cb: Dictionary = grid[b.x][b.y]
        if ca.is_empty() or cb.is_empty():
                return
        if _is_coin(ca) or _is_coin(cb):
                Jukebox.sfx("error", -12.0)
                _bump(a)
                _bump(b)
                return
        var special_a := String(ca.get("special", ""))
        var special_b := String(cb.get("special", ""))
        if special_a == "hyper" or special_b == "hyper":
                _do_hyper_swap(a, b)
                return
        busy = true
        _swap_model(a.x, a.y, b.x, b.y)
        await _animate_swap(a, b)
        if _find_matches().is_empty():
                # the rubber-band law: an illegal swap goes back with a soft thud
                _swap_model(a.x, a.y, b.x, b.y)
                await _animate_swap(a, b)
                Jukebox.sfx("error", -14.0)
                _bump(a)
                _bump(b)
                busy = false
                return
        Jukebox.sfx("m_swap", -8.0)
        moves_made += 1
        if mode == "butterflies":
                _rise_butterflies()
        await _resolve_loop(a, b)
        busy = false


func _bump(cellp: Vector2i) -> void:
        var cell: Dictionary = grid[cellp.x][cellp.y]
        if cell.is_empty() or not is_instance_valid(cell.get("node")):
                return
        var n: Sprite2D = cell["node"]
        # v0.3.3-p2 (the owner's "it weirdly got too huge"): the bump rides
        # the sprite's OWN scale - a coin no longer inflates to gem size
        var base: Vector2 = n.scale
        var tw := n.create_tween()
        tw.tween_property(n, "scale", base * 1.12, 0.07)
        tw.tween_property(n, "scale", base, 0.1)


func _animate_swap(a: Vector2i, b: Vector2i) -> void:
        # the tween-await law: one timer, never finished-after-the-fact
        var moved := 0
        for pair in [[a, b], [b, a]]:
                var cell: Dictionary = grid[pair[0].x][pair[0].y]
                if cell.is_empty() or not is_instance_valid(cell.get("node")):
                        continue
                var n: Sprite2D = cell["node"]
                moved += 1
                var tw := n.create_tween()
                tw.tween_property(n, "position", _cell_pos(pair[0].x, pair[0].y), 0.16) \
                                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        if moved > 0:
                await get_tree().create_timer(0.18, false).timeout


var moves_made := 0

# ================================================================ resolve loop
## THE RESOLVE LAW: match wave -> specials born -> pops -> gravity -> refill
## -> re-scan, until the board is quiet. THE MUTATION LAW: every list a pop
## loop walks is duplicated first (cells vanish inside their own funeral).

## the crown table: which special each match group births. The SWAP CELL
## wins the crown (the gem the player touched wears the special), an L/T
## cross births at the cross, otherwise the run's middle. Pure - the probe
## reads it without playing the wave.
func _birth_kinds(groups: Array, swap_a: Vector2i, swap_b: Vector2i) -> Array:
        var born := []
        for g in groups:
                var cells: Dictionary = g["cells"]
                var birth := Vector2i(-1, -1)
                if g["cross"].x >= 0 and cells.has(g["cross"].y * COLS + g["cross"].x):
                        birth = g["cross"]
                elif swap_a.x >= 0 and cells.has(swap_a.y * COLS + swap_a.x):
                        birth = swap_a
                elif swap_b.x >= 0 and cells.has(swap_b.y * COLS + swap_b.x):
                        birth = swap_b
                else:
                        var keys := cells.keys()
                        birth = Vector2i(int(keys[keys.size() / 2]) / COLS, int(keys[keys.size() / 2]) % COLS)
                var kind := ""
                if g["cross"].x >= 0:
                        kind = "star"       # the L / T / + shape
                elif int(g["len"]) >= 5:
                        kind = "hyper"      # five in a line
                elif int(g["len"]) == 4:
                        kind = "flame"      # four in a line
                if kind != "" and birth.x >= 0:
                        born.append({"r": birth.x, "c": birth.y, "kind": kind,
                                        "color": int(g["color"])})
        return born


func _resolve_loop(swap_a := Vector2i(-1, -1), swap_b := Vector2i(-1, -1)) -> void:
        cascade = 0
        while true:
                if over:
                        return
                var groups := _find_matches()
                if groups.is_empty():
                        break
                cascade += 1
                # 1 - the specials this wave births (the swap cell wins the crown)
                var born := _birth_kinds(groups, swap_a, swap_b)   # [{r, c, kind, color}]
                if mode == "ice":
                        _plan_melt(groups)      # the horizontal-3 / vertical-all law
                var pop := {}
                for g in groups:
                        for key in g["cells"]:
                                pop[key] = true
                for b in born:
                        pop.erase(int(b["r"]) * COLS + int(b["c"]))   # keys are r*COLS+c
                # 2 - the detonation queue: specials caught INSIDE a match explode
                var queue := []
                for key in pop.keys():
                        var r := int(key) / COLS
                        var c := int(key) % COLS
                        var sp := String(grid[r][c].get("special", ""))
                        if sp != "":
                                queue.append({"r": r, "c": c, "kind": sp})
                # 3 - detonate (chain: blasts can ignite more specials)
                var detonated := {}
                while not queue.is_empty():
                        var it: Dictionary = queue.pop_front()
                        var dkey: int = int(it["r"]) * COLS + int(it["c"])
                        if detonated.has(dkey):
                                continue
                        detonated[dkey] = true
                        var extra := _blast_cells(String(it["kind"]), int(it["r"]), int(it["c"]))
                        for key in extra:
                                if not pop.has(key):
                                        pop[key] = true
                                        var r := int(key) / COLS
                                        var c := int(key) % COLS
                                        if _playable(r, c) and not grid[r][c].is_empty():
                                                var sp2 := String(grid[r][c].get("special", ""))
                                                if sp2 != "" and not detonated.has(key):
                                                        queue.append({"r": r, "c": c, "kind": sp2})
                # 4 - pop the wave (fx, score, mode counters)
                await _pop_cells(pop, born)
                # 5 - the combo praise
                if cascade >= 2 and mode != "peace":
                        _combo_banner(cascade)
                swap_a = Vector2i(-1, -1)
                swap_b = Vector2i(-1, -1)
                # 6 - gravity + refill + settle
                await _gravity()
        # quiet board: the after-care
        _collect_bottom_coins()
        if mode == "mine":
                _mine_row_check()
        if not _has_valid_move():
                await _shuffle_board(true)
        idle_clock = 0.0
        _paint_selection()


## what a special detonation covers (in keys)
func _blast_cells(kind: String, r: int, c: int) -> Array:
        var out := {}
        match kind:
                "flame":
                        for dr in range(-1, 2):
                                for dc in range(-1, 2):
                                        var rr := r + dr
                                        var cc := c + dc
                                        if _playable(rr, cc):
                                                out[rr * COLS + cc] = true
                "star":
                        for cc in COLS:
                                if _playable(r, cc):
                                        out[r * COLS + cc] = true
                        for rr in ROWS:
                                if _playable(rr, c):
                                        out[rr * COLS + c] = true
        return out.keys()


func _pop_cells(pop: Dictionary, born: Array) -> void:
        if pop.is_empty() and born.is_empty():
                return
        var count := 0
        var rush := rush_left > 0.0
        for key in pop.keys():
                var r := int(key) / COLS
                var c := int(key) % COLS
                if not _playable(r, c):
                        continue
                var cell: Dictionary = grid[r][c]
                if cell.is_empty():
                        continue
                # the coin is NEVER destroyed by pops - it just loses its seat below
                if _is_coin(cell):
                        continue
                count += 1
                var col := int(cell["color"])
                var p := _cell_pos(r, c)
                _gem_pop_fx(p, col)
                if bool(cell.get("wing", false)):
                        # a butterfly collected: +2 mode bonus on top of its gem point
                        if mode == "butterflies":
                                add_score(2)
                                achievement_count("butterflies", 1)
                                Jukebox.sfx("m_flutter", -6.0, randf_range(0.9, 1.15))
                if rush:
                        add_score(1)        # the gold rush twist: pops pay double
                # v0.3.3-p2 THE POP LAW: the model frees the seat INSTANTLY,
                # the sprite shrinks away for a beat - no teleporting vanish
                if is_instance_valid(cell.get("node")):
                        var n: Sprite2D = cell["node"]
                        var tw := n.create_tween()
                        tw.set_parallel(true)
                        tw.tween_property(n, "scale", Vector2.ONE * 0.02, 0.09) \
                                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                        tw.tween_property(n, "modulate:a", 0.0, 0.09)
                        tw.chain().tween_callback(n.queue_free)
                grid[r][c] = {}
        if count > 0:
                add_score(count)
                achievement_count("matched", count)
                # the pitch-laddered pop chorus (cascade climbs the scale)
                var base_pop: String = ["pop_1", "pop_2", "pop_3", "pop_4"][randi() % 4]
                Jukebox.sfx(base_pop, -8.0)
                # the ice law: a match over iced columns melts them
                if mode == "ice":
                        _melt_under(pop)
                # the mine law: the wave drills the matched columns upward
                if mode == "mine":
                        _mine_dig(pop)
        if cascade > 1:
                achievement_max("best_cascade", cascade)
        # 4-match -> flame, L/T -> star, 5-match -> hyper (the overlay law: the
        # special is a VFX ON TOP of the base gem - skins never break it)
        for b in born:
                var cell: Dictionary = grid[int(b["r"])][int(b["c"])]
                if cell.is_empty() or _is_coin(cell):
                        continue
                cell["special"] = String(b["kind"])
                _dress_special(int(b["r"]), int(b["c"]))
                Jukebox.sfx("m_special", -6.0, 1.0 + 0.05 * born.find(b))
                # the gem wears it with a little arrival pop
                if is_instance_valid(cell.get("node")):
                        var bn: Sprite2D = cell["node"]
                        var btw := bn.create_tween()
                        btw.tween_property(bn, "scale", Vector2.ONE * cell_px / 100.0 * 1.22, 0.1) \
                                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                        btw.tween_property(bn, "scale", Vector2.ONE * cell_px / 100.0, 0.12)
                if String(b["kind"]) == "hyper":
                        achievement_count("hypers", 1)
                var p := _cell_pos(int(b["r"]), int(b["c"]))
                _float_text(p, {"flame": "FLAME!", "star": "STAR!", "hyper": "HYPERCUBE!"}[String(b["kind"])],
                                Color(1, 0.9, 0.4))
        # the star detonations draw beams, flames draw rings - already pooled
        await get_tree().create_timer(0.16, false).timeout


func _dress_special(r: int, c: int) -> void:
        # v0.3.3-p2 THE SHADER-ON-THE-ASSET LAW (the owner): the special is
        # the gem's own material - it rides every swap, fall and cascade in
        # perfect sync, on ANY skin's texture. No overlay to desync.
        var cell: Dictionary = grid[r][c]
        if cell.is_empty() or not is_instance_valid(cell.get("node")):
                return
        var kind := String(cell.get("special", ""))
        var n: Sprite2D = cell["node"]
        if kind == "":
                n.material = null
                return
        n.material = _special_mat(kind)


func _gem_pop_fx(p: Vector2, col: int) -> void:
        var cols := [Color("6ec0eb"), Color("e84c60"), Color("6ec878"), Color("f5c446"), Color("c478dc")]
        var c: Color = cols[clampi(col, 0, 4)]
        for i in 7:
                var dir := Vector2.from_angle(randf() * TAU) * randf_range(90.0, 260.0)
                pops.append({"pos": p, "vel": dir, "life": randf_range(0.3, 0.55),
                                "max": 0.55, "r": randf_range(5.0, 12.0), "col": c})
        rings.append({"pos": p, "r": 8.0, "life": 0.3, "max": 0.3, "col": Color(c, 0.8), "w": 5.0})


func _float_text(p: Vector2, txt: String, col: Color, size := 30) -> void:
        floaters.append({"pos": p, "txt": txt, "life": 0.9, "max": 0.9, "col": col, "size": size})


func _combo_banner(n: int) -> void:
        var words := ["", "", "SWEET!", "SUPER!", "EXQUISITE!", "SPECTACULAR!", "UNREAL!"]
        var w: String = words[mini(n, words.size() - 1)]
        var vp := get_viewport_rect().size
        _float_text(Vector2(vp.x / 2.0, board_o.y - 60.0), w, Color(1, 0.85, 0.35), 40 + 4 * n)
        # v0.3.3-p2: the pentatonic marimba ladder (the owner: "the combo SFXs
        # are the most weirdest ones")
        var step := clampi(n, 2, 7)
        Jukebox.sfx("m_combo_%d" % step, -6.0)


# ================================================================ hypercube
## the hypercube's crown law: swap it with ANY gem (no match needed) and
## every gem of that color zaps off the board. Two hypers = the full wipe.
func _do_hyper_swap(a: Vector2i, b: Vector2i) -> void:
        busy = true
        var ca: Dictionary = grid[a.x][a.y]
        var cb: Dictionary = grid[b.x][b.y]
        var hyper_at := a if String(ca.get("special", "")) == "hyper" else b
        var other_at := b if hyper_at == a else a
        var other: Dictionary = grid[other_at.x][other_at.y]
        var pop := {}
        var both := String(ca.get("special", "")) == "hyper" and String(cb.get("special", "")) == "hyper"
        if both:
                for r in ROWS:
                        for c in COLS:
                                if _playable(r, c) and not grid[r][c].is_empty() and not _is_coin(grid[r][c]):
                                        pop[r * COLS + c] = true
                _float_text(_cell_pos(hyper_at.x, hyper_at.y), "SUPERNOVA!", Color(1, 0.6, 0.9), 46)
        else:
                var col := int(other.get("color", 0))
                for r in ROWS:
                        for c in COLS:
                                if _playable(r, c) and not grid[r][c].is_empty() \
                                                and not _is_coin(grid[r][c]) and int(grid[r][c].get("color", -9)) == col:
                                        pop[r * COLS + c] = true
                pop[hyper_at.y * COLS + hyper_at.x] = true
        moves_made += 1
        Jukebox.sfx("m_hyper", -3.0)
        # the lightning arcs
        var hp := _cell_pos(hyper_at.x, hyper_at.y)
        for key in pop.keys():
                var r := int(key) / COLS
                var c := int(key) % COLS
                zaps.append({"a": hp, "b": _cell_pos(r, c), "life": 0.3, "max": 0.3})
        if mode == "butterflies":
                _rise_butterflies()
        await _resolve_loop()
        busy = false


# ================================================================ gravity
func _gravity() -> void:
        var movers := []
        for c in COLS:
                var write := ROWS - 1
                for r in range(ROWS - 1, -1, -1):
                        if _in_earth(r):
                                continue
                        var cell: Dictionary = grid[r][c]
                        if cell.is_empty():
                                continue
                        if r != write:
                                grid[write][c] = cell
                                grid[r][c] = {}
                                movers.append({"node": cell["node"], "to": _cell_pos(write, c)})
                        write -= 1
                # refill the top
                var spawn_i := 0
                for r in range(write, -1, -1):
                        if _in_earth(r):
                                continue
                        var cell := _new_cell(r, c, board_o.y - cell_px - float(spawn_i) * cell_px * 0.4)
                        spawn_i += 1
                        grid[r][c] = cell
                        movers.append({"node": cell["node"], "to": _cell_pos(r, c)})
        # THE TWEEN-AWAIT LAW (the probe caught it): NEVER await finished on
        # a tween that may already be done - a short tween finishes while the
        # longer ones are awaited and that await hangs forever. ONE timer
        # sized to the longest fall moves the whole wave.
        var max_dur := 0.09
        for m in movers:
                var n: Sprite2D = m["node"]
                var dist: float = absf(n.position.y - (m["to"] as Vector2).y)
                var dur := clampf(dist / 2600.0, 0.08, 0.34)
                max_dur = maxf(max_dur, dur)
                var tw := n.create_tween()
                tw.tween_property(n, "position", m["to"], dur) \
                                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        if not movers.is_empty():
                await get_tree().create_timer(max_dur + 0.02, false).timeout
        await get_tree().create_timer(0.05, false).timeout


# ================================================================ the coin
## THE COIN LAW (the owner): every 30s AFTER the last coin was COLLECTED,
## a GOGACoin materializes in a real cell (it never matches, it never
## breaks). Clear under it and it falls like everything else; when it lands
## in the bottom row it drops out of the board and is earned.
func _spawn_coin() -> void:
        var candidates := []
        for r in ROWS - 1:
                for c in COLS:
                        if not _playable(r, c) or grid[r][c].is_empty():
                                continue
                        var cell: Dictionary = grid[r][c]
                        if _is_coin(cell) or String(cell.get("special", "")) == "hyper":
                                continue
                        candidates.append(Vector2i(r, c))
        if candidates.is_empty():
                return
        var at: Vector2i = candidates[randi() % candidates.size()]
        var cell: Dictionary = grid[at.x][at.y]
        # the gem that lived here poofs away (a real seat changes hands)
        if is_instance_valid(cell.get("node")):
                var old_n: Sprite2D = cell["node"]
                var tw0 := old_n.create_tween()
                tw0.set_parallel(true)
                tw0.tween_property(old_n, "scale", Vector2.ONE * 0.02, 0.12)
                tw0.tween_property(old_n, "modulate:a", 0.0, 0.12)
                tw0.chain().tween_callback(old_n.queue_free)
        # the coin DROPS IN from above the board - a normal falling thing
        var n := Sprite2D.new()
        n.texture = _t("coin")
        n.scale = Vector2.ONE * cell_px * 0.8 / 192.0
        var target := _cell_pos(at.x, at.y)
        n.position = Vector2(target.x, board_o.y - cell_px * 0.8)
        n.z_index = 3
        world.add_child(n)
        var tw := n.create_tween()
        tw.tween_property(n, "position", target, 0.32) \
                        .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
        grid[at.x][at.y] = {"color": -1, "coin": true, "node": n}
        coin_cell = at
        coin_clock = -1.0        # ticking stops while a coin lives on the board
        Jukebox.sfx("m_special", -10.0, 1.35)
        _float_text(Vector2(target.x, target.y - cell_px * 0.7), "GOGACOIN!", Color(1, 0.85, 0.3), 26)


func _collect_bottom_coins() -> void:
        if coin_cell.x < 0:
                return
        # THE MUTATION LAW: collect from a duplicate pass
        for c in COLS:
                var cell: Dictionary = grid[ROWS - 1][c]
                if cell.is_empty() or not _is_coin(cell):
                        continue
                _collect_coin_at(Vector2i(ROWS - 1, c))
                return


## one coin earned: +1 run coin, the fly-to-HUD theatre, the seat refills
func _collect_coin_at(at: Vector2i) -> void:
        var cell: Dictionary = grid[at.x][at.y]
        if cell.is_empty() or not _is_coin(cell):
                return
        add_run_coins(1)
        achievement_count("coins_taken", 1)
        Jukebox.sfx("m_coin", -4.0)
        _ring_fx(_cell_pos(at.x, at.y), Color(1, 0.85, 0.3))
        _float_text(_cell_pos(at.x, at.y), "+1", Color(1, 0.85, 0.3), 32)
        _coin_fly_to_hud(_cell_pos(at.x, at.y))
        if is_instance_valid(cell.get("node")):
                (cell["node"] as Sprite2D).queue_free()
        grid[at.x][at.y] = {}
        coin_cell = Vector2i(-1, -1)
        coin_clock = COIN_EVERY    # the owner: from the last COLLECTED
        # THE REFILL LAW (the owner's "the place of it stayed empty" bug):
        # the emptied seat is filled by the very next gravity wave
        _auto_refill()


## the auto-collect tick (the owner: "when it is in the bottom, it should be
## auto collected and not waiting for me to tap it")
func _auto_coin_watch() -> void:
        if coin_cell.x != ROWS - 1 or busy or over or phase != "play":
                return
        _collect_coin_at(coin_cell)


## a gravity wave with no resolve loop attached (the coin's seat refill)
func _auto_refill() -> void:
        _coin_refill_pending = true


func _coin_fly_to_hud(from: Vector2) -> void:
        var vp := get_viewport_rect().size
        var fly := Sprite2D.new()
        fly.texture = _t("coin")
        fly.scale = Vector2.ONE * cell_px * 0.5 / 192.0
        fly.position = from
        fly.z_index = 30
        world.add_child(fly)
        var tw := fly.create_tween()
        tw.tween_property(fly, "position", Vector2(vp.x - 70.0, 44.0), 0.5) \
                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        tw.parallel().tween_property(fly, "scale", Vector2.ONE * 0.16, 0.5)
        tw.tween_callback(fly.queue_free)


# ================================================================ shuffle
func _shuffle_board(silent := false) -> void:
        # collect every movable gem color, re-deal until a legal move exists and
        # the board wakes up quiet (no instant matches)
        var cells := []
        for r in ROWS:
                for c in COLS:
                        if not _playable(r, c) or grid[r][c].is_empty():
                                continue
                        var cell: Dictionary = grid[r][c]
                        if _is_coin(cell):
                                continue
                        cells.append(Vector2i(r, c))
        if cells.size() < 4:
                return
        var guard := 0
        while guard < 60:
                guard += 1
                var colors := []
                for cellp in cells:
                        colors.append(int(grid[cellp.x][cellp.y]["color"]))
                colors.shuffle()
                for i in cells.size():
                        grid[cells[i].x][cells[i].y]["color"] = colors[i]
                if not _find_matches().is_empty():
                        continue
                if _has_valid_move():
                        break
        if not _has_valid_move():
                # a pathological pool (a starved board) - re-deal with the FULL
                # palette; any instant matches cascade free, the board wakes up
                for cellp in cells:
                        var col2 := _roll_color()
                        grid[cellp.x][cellp.y]["color"] = col2
                        if is_instance_valid(grid[cellp.x][cellp.y].get("node")):
                                (grid[cellp.x][cellp.y]["node"] as Sprite2D).texture = tex_gem[col2 % tex_gem.size()]
                        grid[cellp.x][cellp.y]["special"] = ""
        if not silent:
                Jukebox.sfx("m_shuffle", -4.0)
                _ring_fx(_cell_pos(ROWS / 2, COLS / 2), Color(1, 1, 1, 0.7))
                _float_text(_cell_pos(ROWS / 2, COLS / 2), "SHUFFLE!", Color(1, 1, 1), 38)
        for cellp in cells:
                var cell: Dictionary = grid[cellp.x][cellp.y]
                if is_instance_valid(cell.get("node")):
                        (cell["node"] as Sprite2D).texture = tex_gem[int(cell["color"]) % tex_gem.size()]
        # v0.3.3-p2: butterflies retexture after a shuffle (their wings ride
        # their own texture now, so a new color just gets a new bake)
        if mode == "butterflies":
                for r in ROWS:
                        for c in COLS:
                                var cell: Dictionary = grid[r][c]
                                if cell.is_empty():
                                        continue
                                if bool(cell.get("wing", false)):
                                        _retexture_cell(r, c)
        # re-dress specials: an overlay whose host changed color stays (specials
        # keep their own identity), flame/star keep working on any color


func _ring_fx(p: Vector2, col: Color) -> void:
        rings.append({"pos": p, "r": 14.0, "life": 0.4, "max": 0.4, "col": col, "w": 7.0})


# ================================================================ the tick
func _goga_tick(delta: float) -> void:
        if phase != "play" or over:
                return
        _tick_fx(delta)
        _tick_idle(delta)
        # the mode clocks (the base gates pause before this runs)
        if mode != "peace":
                _tick_coin(delta)
                _auto_coin_watch()          # the bottom-row coin earns itself
        else:
                peace_secs += delta
        if _coin_refill_pending and not busy:
                _coin_refill_pending = false
                _gravity()                  # fire-and-forget: the seat refills
        match mode:
                "challenge":
                        _tick_challenge(delta)
                "butterflies":
                        _tick_butterflies(delta)
                        _tick_butterfly_hatch_timer(delta)
                "ice":
                        _tick_ice(delta)
                "mine":
                        _tick_mine(delta)
        _refresh_hud()


func _tick_idle(delta: float) -> void:
        if busy:
                idle_clock = 0.0
                return
        idle_clock += delta
        if idle_clock >= 5.0 and hinted.is_empty():
                var mv := _find_a_move()
                if not mv.is_empty():
                        hinted = mv
                        for cellp in mv:
                                var cell: Dictionary = grid[cellp.x][cellp.y]
                                if cell.is_empty() or not is_instance_valid(cell.get("node")):
                                        continue
                                var n: Sprite2D = cell["node"]
                                var tw := n.create_tween().set_loops(2)
                                tw.tween_property(n, "modulate", Color(1.4, 1.4, 1.2), 0.4)
                                tw.tween_property(n, "modulate", Color.WHITE, 0.4)


func _tick_coin(delta: float) -> void:
        if coin_cell.x >= 0 or busy:
                return
        coin_clock -= delta
        if coin_clock <= 0.0:
                _spawn_coin()
                if coin_cell.x < 0:
                        coin_clock = 2.0    # no seat right now - try again soon


func _tick_challenge(delta: float) -> void:
        run_clock -= delta
        round_clock -= delta
        rush_left = maxf(0.0, rush_left - delta)
        round_bank = score - round_start
        if round_clock <= 0.0:
                # THE ROUND FAILED - the owner's law: -500 score, only in challenge
                set_score(maxi(0, score - 500))
                round_no += 1
                Jukebox.sfx("m_gong", -4.0)
                _banner("ROUND LOST  -500", false)
                _roll_round()
        elif round_bank >= round_goal:
                round_no += 1
                Jukebox.sfx("m_goal", -4.0)
                Arc.confetti(_overlay_root_ref(), Vector2(get_viewport_rect().size.x / 2.0, board_o.y), 34)
                _banner("ROUND %d CLEAR!" % (round_no - 1), true)
                _roll_round()
        if run_clock <= 0.0:
                _finish_run("time up - the run banks")


func _roll_round() -> void:
        round_no = maxi(1, round_no)
        round_goal = 40 + round_no * 6 + randi() % 21
        round_time = 45.0 + randf() * 25.0
        round_clock = round_time
        round_bank = 0
        round_start = score
        var roll := randf()
        if roll < 0.25:
                twist = "drought"
                drought_color = randi() % COLORS
        elif roll < 0.5:
                twist = "rush"
                rush_left = 10.0
        else:
                twist = ""


func _tick_butterflies(delta: float) -> void:
        pace_clock -= delta
        if pace_clock <= 0.0:
                pace_clock = 45.0
                pace += 1
                _banner("THEY HURRY!", false)


func _rise_butterflies() -> void:
        # v0.3.3-p2 THE RISE ANIMATION LAW (the owner: "flies are corrupting
        # the line and it's instant with no animations and makes huge
        # glitches like overlapping things"): the MODEL swaps first, then
        # EVERY displaced node tweens to its new home together - nothing
        # teleports, nothing overlaps. A butterfly reaching the top row is
        # caught by the spider after the wave lands.
        for step in pace:
                var movers := []          # [{node, to}]
                var wings := []
                for r in ROWS:
                        for c in COLS:
                                var cell: Dictionary = grid[r][c]
                                if not cell.is_empty() and bool(cell.get("wing", false)):
                                        wings.append(Vector2i(r, c))
                wings.sort()            # top rows first - the topmost flies first
                for wcell in wings:
                        var r: int = wcell.x
                        var c: int = wcell.y
                        var cell: Dictionary = grid[r][c]
                        if cell.is_empty() or not bool(cell.get("wing", false)):
                                continue        # it was swept up by an earlier mover
                        if r == 0:
                                continue        # it waits at the top - the spider watches
                        # swap with whatever sits above (a coin holds it back)
                        _swap_model(r, c, r - 1, c)
                        var above: Dictionary = grid[r - 1][c]
                        if is_instance_valid(above.get("node")):
                                movers.append({"node": above["node"],
                                                "to": _cell_pos(r - 1, c)})
                        var below: Dictionary = grid[r][c]
                        if not below.is_empty() and is_instance_valid(below.get("node")):
                                movers.append({"node": below["node"],
                                                "to": _cell_pos(r, c)})
                # one wave, one duration - every mover lands together
                var max_dur := 0.0
                for m in movers:
                        var n: Sprite2D = m["node"]
                        var dist: float = absf(n.position.y - (m["to"] as Vector2).y)
                        var dur: float = clampf(dist / 2200.0, 0.12, 0.22)
                        max_dur = maxf(max_dur, dur)
                        var tw: Tween
                        if n.get_meta("rise_tw", 0):
                                var prev: Tween = n.get_meta("rise_tw")
                                if prev != null and prev.is_valid():
                                        prev.kill()
                        tw = n.create_tween()
                        n.set_meta("rise_tw", tw)
                        tw.tween_property(n, "position", m["to"], dur) \
                                        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
                if not movers.is_empty():
                        await get_tree().create_timer(max_dur + 0.02, false).timeout
        # the spider checks the sky: any butterfly ON the top row gets grabbed
        for c in COLS:
                var cell: Dictionary = grid[0][c]
                if not cell.is_empty() and bool(cell.get("wing", false)):
                        await _spider_grabs(Vector2i(0, c))
                        return
        _spider_hunt()


## THE SPIDER (the owner: "it should exist and looks toward the nearest
## butterfly to grab it then the game ends"): it glides along the top rail
## toward the highest butterfly, and when one lands on the top row it sweeps
## over, shrinks it away, and the run ends.
func _spider_hunt() -> void:
        if spider == null or not is_instance_valid(spider):
                return
        var best := Vector2i(-1, -1)
        for r in ROWS:
                for c in COLS:
                        var cell: Dictionary = grid[r][c]
                        if not cell.is_empty() and bool(cell.get("wing", false)):
                                best = Vector2i(r, c)
                                break
                if best.x >= 0:
                        break
        if best.x < 0:
                return
        var want_x := _cell_pos(0, best.y).x
        if spider_tw != null and spider_tw.is_valid():
                spider_tw.kill()
        spider_tw = spider.create_tween()
        spider_tw.tween_property(spider, "position:x", want_x, 0.45) \
                        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _spider_grabs(at: Vector2i) -> void:
        if spider == null or not is_instance_valid(spider):
                _finish_run("the spider dined")
                return
        var cell: Dictionary = grid[at.x][at.y]
        var target := _cell_pos(at.x, at.y)
        if spider_tw != null and spider_tw.is_valid():
                spider_tw.kill()
        var tw := spider.create_tween()
        tw.tween_property(spider, "position", target + Vector2(0, -cell_px * 0.5), 0.4) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
        await tw.finished
        # the grab: the butterfly shrinks INTO the spider
        if is_instance_valid(cell.get("node")):
                var n: Sprite2D = cell["node"]
                var gt := n.create_tween()
                gt.set_parallel(true)
                gt.tween_property(n, "position", spider.position, 0.22) \
                                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                gt.tween_property(n, "scale", Vector2.ONE * 0.02, 0.22)
                gt.chain().tween_callback(n.queue_free)
        grid[at.x][at.y] = {}
        var pulse := spider.create_tween()
        pulse.tween_property(spider, "scale", spider.scale * 1.25, 0.12)
        pulse.tween_property(spider, "scale", spider.scale, 0.14)
        Jukebox.sfx("m_gulp", -2.0)
        Jukebox.sfx("m_spider", -4.0)
        _ring_fx(spider.position, Color(0.7, 0.5, 0.9))
        _banner("THE SPIDER DINED!", false)
        await get_tree().create_timer(0.35, false).timeout
        _finish_run("the spider dined")


func _hatch_butterfly(r: int, c: int) -> void:
        if not _playable(r, c) or grid[r][c].is_empty():
                return
        var cell: Dictionary = grid[r][c]
        if _is_coin(cell):
                return
        cell["wing"] = true
        # v0.3.3-p2: the wings are BAKED into the gem's own texture - they
        # move with the sprite forever, nothing can desync or overlap
        _retexture_cell(r, c)
        var n: Sprite2D = cell["node"]
        if is_instance_valid(n):
                var base: Vector2 = n.scale
                n.scale = base * 0.2
                var tw := n.create_tween()
                tw.tween_property(n, "scale", base, 0.3) \
                                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        Jukebox.sfx("m_flutter", -8.0)


var peace_secs := 0.0
var hatch_clock := 6.0

func _tick_butterfly_hatch_timer(delta: float) -> void:
        hatch_clock -= delta
        if hatch_clock <= 0.0:
                hatch_clock = 7.0
                _tick_butterfly_hatch()


## new butterflies hatch on the bottom row as the board thins
func _tick_butterfly_hatch() -> void:
        if mode != "butterflies" or busy:
                return
        var count := 0
        for r in ROWS:
                for c in COLS:
                        var cell: Dictionary = grid[r][c]
                        if not cell.is_empty() and bool(cell.get("wing", false)):
                                count += 1
        if count == 0 and randf() < 0.4:
                var c := randi() % COLS
                _hatch_butterfly(ROWS - 1, c)


func _tick_ice(delta: float) -> void:
        # v0.3.3-p2 THE ICE STORM LAW (the owner's Bejeweled Classic spec):
        # vertical ice columns grow from the bottom; a column reaching the
        # top is LOST; progression keeps spawning more iced lines
        frost_clock -= delta
        if frost_clock <= 0.0:
                frost_clock = frost_gap
                frost_gap = maxf(4.0, frost_gap - 0.1)
                frost_ticks += 1
                var col := randi() % COLS
                _ice_grow(col)
                if frost_ticks % 4 == 0:
                        # the progression: a second line joins in
                        var c2 := randi() % COLS
                        if c2 != col:
                                _ice_grow(c2)
                _refresh_ice()
                Jukebox.sfx("m_freeze", -10.0)
                _check_ice_over()
        melt_chain = maxf(0.0, melt_chain - delta)
        if melt_chain <= 0.0:
                temp = maxf(0.0, temp - delta * 0.4)


func _ice_grow(c: int) -> void:
        if int(frost[c]) < ROWS:
                frost[c] = int(frost[c]) + 1


## v0.3.3-p2 THE MELT PLAN (the owner: "hitting that line with horizontal
## moves takes only like 3 areas of it and hitting it completely vertical
## destroys it completely"): built from the wave's real groups - a horizontal
## group touching an iced column eats 3 segments of it, a vertical group in
## the column wipes the whole line. Vertical wins when both touch.
func _plan_melt(groups: Array) -> void:
        melt_plan = {}
        for g in groups:
                var cells: Dictionary = g["cells"]
                var is_v: bool = String(g["dir"]) == "v"
                var cols := {}
                for key in cells.keys():
                        cols[int(key) % COLS] = true
                if is_v:
                        for c in cols.keys():
                                melt_plan[int(c)] = "all"
                else:
                        for c in cols.keys():
                                if int(frost[int(c)]) > 0 and not melt_plan.has(int(c)):
                                        melt_plan[int(c)] = "3"


func _melt_under(pop: Dictionary) -> void:
        for c in melt_plan.keys():
                var ci := int(c)
                var lvl := int(frost[ci])
                if lvl <= 0:
                        continue
                var took: int = lvl if String(melt_plan[c]) == "all" else mini(3, lvl)
                frost[ci] = maxi(0, lvl - took)
                add_score(5 * took)       # the melt bonus, per segment
                achievement_count("melted", took)
                Jukebox.sfx("m_melt", -6.0, randf_range(0.9, 1.2))
                _ring_fx(_cell_pos(ROWS - 1 - (lvl - 1), ci), Color(0.75, 0.9, 1.0))
                melt_chain = 3.0
                temp = minf(1.0, temp + 0.20 * float(took))
                if temp >= 1.0:
                        temp = 0.0
                        add_score(10)
                        _float_text(_cell_pos(ROWS - 1, ci), "HOT HANDS! +10", Color(1, 0.6, 0.3), 30)
        melt_plan = {}
        _refresh_ice()
        _check_ice_over()


func _refresh_ice() -> void:
        # the ice visuals: each segment = one iced cell sprite on the column's
        # bottom cells; new segments slide in, melted ones fade out (no more
        # instant pops - the owner's smoothness law)
        for c in COLS:
                var lvl := int(frost[c])
                for r in ROWS:
                        var cell: Dictionary = grid[r][c]
                        if cell.is_empty():
                                continue
                        var depth_from_bottom := (ROWS - 1) - r
                        var want := clampi(lvl - depth_from_bottom, 0, 3)
                        var key := "ice_ov%d" % depth_from_bottom
                        var have: Sprite2D = cell.get(key) if cell.get(key) != null else null
                        if want > 0 and have == null:
                                var ov := Sprite2D.new()
                                ov.texture = _t("ice%d" % want)
                                ov.position = _cell_pos(r, c) + Vector2(0, -26.0)
                                ov.scale = Vector2.ONE * cell_px / 120.0
                                ov.modulate.a = 0.0
                                ov.z_index = 6
                                world.add_child(ov)
                                cell[key] = ov
                                var tw := ov.create_tween().set_parallel(true)
                                tw.tween_property(ov, "position", _cell_pos(r, c), 0.22) \
                                                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                                tw.tween_property(ov, "modulate:a", 1.0, 0.18)
                        elif want == 0 and have != null:
                                cell[key] = null
                                var tw2 := have.create_tween()
                                tw2.tween_property(have, "modulate:a", 0.0, 0.16)
                                tw2.tween_callback(have.queue_free)
                        elif want > 0 and have != null:
                                have.texture = _t("ice%d" % want)


func _check_ice_over() -> void:
        for c in COLS:
                if int(frost[c]) >= ROWS:
                        Jukebox.sfx("m_gong", -4.0)
                        _banner("THE ICE REACHED THE TOP!", false)
                        _finish_run("the ice reached the top")


# ================================================================ the mine
## v0.3.3-p2 THE DIAMOND MINE, the owner's Bejeweled Classic spec:
##   - the round starts with 60 seconds
##   - every 25 seconds a NEW EARTH ROW rises from the bottom (sometimes two)
##   - clearing a full earth row (digging all 8 of its cells) gives +25s
##   - matches in the row sitting ON the earth dig the earth below them
##   - the earth reaching the top buries the run

func _tick_mine(delta: float) -> void:
        dig_clock -= delta
        if dig_clock <= 0.0:
                _banner("TIME UP!", false)
                _finish_run("the dig clock ran dry")
                return
        mine_rise_clock -= delta
        if mine_rise_clock <= 0.0:
                mine_rise_clock = MINE_ROW_TIME
                var rows := 1
                if randf() < MINE_DOUBLE:
                        rows = 2         # "some times it make two rows"
                for i in rows:
                        _mine_rise()


## one earth row rises from the bottom: the band's top moves UP one row and
## the new cells slide in from under the board (never an instant appear)
func _mine_rise() -> void:
        if earth_top <= 0:
                return
        earth_top -= 1
        earth.resize(ROWS)
        _lay_earth_row(earth_top, 1.0)
        # a coin buried by the rise is LOST (the clock restarts - never a
        # free earn)
        if coin_cell.x >= 0 and coin_cell.x >= earth_top:
                coin_cell = Vector2i(-1, -1)
                coin_clock = COIN_EVERY
        # the gems that were in that row are gone (buried under the new dirt)
        for c in COLS:
                var old: Dictionary = grid[earth_top][c]
                if not old.is_empty() and is_instance_valid(old.get("node")):
                        (old["node"] as Sprite2D).queue_free()
                grid[earth_top][c] = {}
                var row: Array = earth[earth_top]
                var e: Dictionary = row[c]
                if e.has("node") and is_instance_valid(e["node"]):
                        var n: Sprite2D = e["node"]
                        n.position.y += cell_px      # start one row BELOW home
                        var tw := n.create_tween()
                        tw.tween_property(n, "position:y",
                                        _cell_pos(earth_top, c).y, 0.3) \
                                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                        if n.has_meta("tr_spr"):
                                var sp: Sprite2D = n.get_meta("tr_spr")
                                if is_instance_valid(sp):
                                        sp.position.y += cell_px
                                        var tw2 := sp.create_tween()
                                        tw2.tween_property(sp, "position:y",
                                                        _cell_pos(earth_top, c).y, 0.3) \
                                                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        Jukebox.sfx("m_freeze", -8.0, 0.7)
        _banner("THE EARTH RISES!", false)
        _refresh_hud()
        if earth_top <= 0:
                _banner("BURIED!", false)
                _finish_run("buried by the earth")


## fills one earth row with treasure cells (density grows with depth)
func _lay_earth_row(r: int, density: float) -> void:
        earth[r] = []
        for c in COLS:
                var tr := ""
                var roll := randf()
                if roll < 0.10 * density:
                        tr = "artifact"
                elif roll < 0.26 * density:
                        tr = "diamond"
                elif roll < 0.52 * density:
                        tr = "gold"
                var e := {"tr": tr}
                e["node"] = _earth_sprite(r, c, tr)
                earth[r].append(e)


func _earth_sprite(r: int, c: int, tr: String) -> Sprite2D:
        var n := Sprite2D.new()
        n.texture = _t("earth")
        n.position = _cell_pos(r, c)
        n.scale = Vector2.ONE * cell_px / 120.0
        n.z_index = 2
        world.add_child(n)
        if tr != "":
                var s := Sprite2D.new()
                s.texture = _t(tr)
                s.position = _cell_pos(r, c)
                s.scale = Vector2.ONE * cell_px * 0.62 / 110.0
                s.z_index = 3
                s.modulate = Color(1, 1, 1, 0.9)
                world.add_child(s)
                n.set_meta("tr_spr", s)
        return n


## a match wave drills the columns whose MATCHED CELLS sit directly on the
## earth: the TOP earth cell of each such column breaks (match against the
## dirt to dig - the Bejeweled Classic feel)
func _mine_dig(pop: Dictionary) -> void:
        if earth_top >= ROWS:
                return
        var cols := {}
        for key in pop.keys():
                var r := int(key) / COLS
                var c := int(key) % COLS
                if r == earth_top - 1:
                        cols[c] = true
        for ci in cols.keys():
                var c := int(ci)
                var row: Array = earth[earth_top]
                if row.size() <= c:
                        continue
                var e: Dictionary = row[c]
                if e.is_empty() or not e.has("node") \
                                or not is_instance_valid(e["node"]):
                        continue
                var n: Sprite2D = e["node"]
                _gem_pop_fx(n.position, 2)
                if n.has_meta("tr_spr"):
                        var s: Sprite2D = n.get_meta("tr_spr")
                        if is_instance_valid(s):
                                var tr := String(e.get("tr", ""))
                                var pay: int = int({"gold": 10, "diamond": 25, "artifact": 60}.get(tr, 0))
                                add_score(int(pay))
                                _float_text(s.position, "+%d" % int(pay), Color(1, 0.85, 0.35), 30)
                                Jukebox.sfx("m_" + tr, -4.0)
                                _coin_fly_to_hud(s.position)
                                s.queue_free()
                var tw := n.create_tween()
                tw.tween_property(n, "scale", Vector2.ONE * 0.02, 0.12)
                tw.tween_callback(n.queue_free)
                row[c] = {}
                Jukebox.sfx("m_dig", -5.0, randf_range(0.9, 1.15))
        _mine_row_check()


## the top earth row fully dug -> the whole band SINKS one row (+25s, the
## owner: "clearing a row gives extra 25 seconds") and the board breathes
func _mine_row_check() -> void:
        if earth_top >= ROWS:
                return
        var row: Array = earth[earth_top]
        for c in COLS:
                var e: Dictionary = row[c] if c < row.size() else {}
                if not e.is_empty() and e.has("node") \
                                and is_instance_valid(e["node"]):
                        return          # cells still standing
        # the row is clear: the band sinks with a smooth drop
        depth += 1
        dig_clock += MINE_ROW_BONUS
        Jukebox.sfx("m_descend", -3.0)
        achievement_max("depth", depth)
        _banner("ROW CLEARED!  +%ds" % int(MINE_ROW_BONUS), true)
        var cleared := earth_top
        earth_top += 1
        for r in range(cleared, ROWS):
                if earth[r] == null:
                        continue
                for c in COLS:
                        if c >= earth[r].size():
                                continue
                        var e2: Dictionary = earth[r][c]
                        if e2.is_empty() or not e2.has("node") \
                                        or not is_instance_valid(e2["node"]):
                                continue
                        var n: Sprite2D = e2["node"]
                        var target := _cell_pos(r, c).y
                        var tw := n.create_tween()
                        tw.tween_property(n, "position:y", target, 0.26) \
                                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                        if n.has_meta("tr_spr"):
                                var sp: Sprite2D = n.get_meta("tr_spr")
                                if is_instance_valid(sp):
                                        var tw2 := sp.create_tween()
                                        tw2.tween_property(sp, "position:y", target, 0.26) \
                                                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        _refresh_hud()


# ================================================================ finish
func _finish_run(reason: String) -> void:
        if over:
                return
        _banner(reason, false)
        if mode == "challenge":
                achievement_max("challenge_best", score)
        if mode == "peace":
                achievement_count("peace_secs", int(peace_secs))
        achievement_count("runs_done", 1)
        check_achievements()
        Jukebox.stop_music()
        finish_run(score)


# ================================================================ the power rail
## THE CANDY-CRUSH LAYER: four tap powers, unlocked once with the wallet,
## stocked in-play up to 3 each, refilled with the ROUND balance (the coins
## this run collected from the board) - never the box wallet mid-run.
func _build_rail() -> void:
        var vp := get_viewport_rect().size
        rail = Control.new()
        rail.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
        rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var banner := banner_bottom()
        rail.offset_top = -(banner + 150.0)
        rail.offset_bottom = -banner
        _overlay_root_ref().add_child(rail)
        var row := HBoxContainer.new()
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        row.add_theme_constant_override("separation", 14)
        row.set_anchors_preset(Control.PRESET_FULL_RECT)
        row.offset_top = 6
        row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        rail.add_child(row)
        for pid in POWER_ORDER:
                row.add_child(_rail_slot(pid))
        if mode == "peace":
                rail.visible = false        # the owner: peace wears nothing


func _rail_slot(pid: String) -> Button:
        var p: Dictionary = POWERS[pid]
        var b := Button.new()
        b.custom_minimum_size = Vector2(120, 132)
        var sb := Arc.panel_style(Arc.CARD, 20, 6)
        b.add_theme_stylebox_override("normal", sb)
        var sbp := sb.duplicate() as StyleBoxFlat
        sbp.bg_color = sbp.bg_color.darkened(0.07)
        b.add_theme_stylebox_override("pressed", sbp)
        var v := VBoxContainer.new()
        v.set_anchors_preset(Control.PRESET_FULL_RECT)
        v.offset_top = 6
        v.offset_bottom = -4
        v.mouse_filter = Control.MOUSE_FILTER_IGNORE
        v.add_theme_constant_override("separation", 0)
        b.add_child(v)
        var ic := TextureRect.new()
        ic.texture = load(String(p["icon"]))
        ic.custom_minimum_size = Vector2(58, 58)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        v.add_child(ic)
        var dots := Arc.fit_label("", 17, Color("2c8a44"), 112)
        dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
        v.add_child(dots)
        var price := Arc.fit_label("", 15, Color(0.5, 0.4, 0.25), 112)
        price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        price.mouse_filter = Control.MOUSE_FILTER_IGNORE
        v.add_child(price)
        rail_slots[pid] = {"btn": b, "dots": dots, "price": price}
        b.pressed.connect(func(): _rail_tap(pid))
        return b


func _refresh_rail() -> void:
        if rail == null:
                return
        for pid in POWER_ORDER:
                var slot: Dictionary = rail_slots[pid]
                var n := int(charges[pid])
                var owned: bool = Box.item_owned(game_id, "power", pid)
                var dots: Label = slot["dots"]
                var price: Label = slot["price"]
                var btn: Button = slot["btn"]
                var spent_out: bool = owned and n <= 0 and int(power_used[pid]) >= POWER_MAX
                if spent_out:
                        # THE GRAY-OUT LAW (the owner): all 3 used this run ->
                        # the slot goes gray and dead until the next run
                        dots.text = "SPENT"
                        dots.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
                        price.text = "next run"
                        btn.disabled = true
                else:
                        btn.disabled = false
                        if not owned:
                                dots.text = "LOCKED"
                                dots.add_theme_color_override("font_color", Color(0.55, 0.42, 0.3))
                                price.text = "%d GOGACoins" % int(POWERS[pid]["price"])
                        elif n > 0:
                                dots.text = "%d/3" % n
                                dots.add_theme_color_override("font_color", Color("2c8a44"))
                                price.text = String(POWERS[pid]["name"]).to_upper()
                        else:
                                dots.text = "EMPTY"
                                dots.add_theme_color_override("font_color", Color(0.62, 0.5, 0.36))
                                price.text = "%d GOGACoins" % int(POWERS[pid]["refill"])
                var sb := btn.get_theme_stylebox("normal") as StyleBoxFlat
                if spent_out:
                        sb.set_border_width_all(0)
                        btn.modulate = Color(1, 1, 1, 0.45)
                else:
                        btn.modulate = Color(1, 1, 1, 1)
                        if armed == pid:
                                sb.set_border_width_all(4)
                                sb.border_color = Arc.ACCENT
                        elif n > 0 and owned:
                                sb.set_border_width_all(2)
                                sb.border_color = Arc.GOOD
                        else:
                                sb.set_border_width_all(0)


func _rail_tap(pid: String) -> void:
        if phase != "play" or over or pick_open or mode == "peace" \
                        or sheet_open_count() > 0:
                return
        var owned: bool = Box.item_owned(game_id, "power", pid)
        var n := int(charges[pid])
        if not owned:
                _power_sheet(pid)
                return
        if armed == pid:
                armed = ""
                _set_armed_cursor(false)
                _refresh_rail()
                return
        if n <= 0:
                # THE BUY POPUP: empty -> the quantity arrows ask how many
                # (max 3 - used), the full balance is shown, the round pays
                if int(power_used[pid]) >= POWER_MAX:
                        return              # grayed on the rail anyway
                _power_sheet(pid)
                return
        if pid == "shuffle":
                charges[pid] = n - 1
                power_used[pid] = int(power_used[pid]) + 1
                _refresh_rail()
                await _shuffle_board(false)
                await _resolve_after_power()
                return
        armed = pid
        Jukebox.sfx("m_arm", -6.0)
        _set_armed_cursor(true)
        _refresh_rail()
        _toast_show("tap the board - %s" % String(POWERS[pid]["name"]).to_upper())


func _set_armed_cursor(on: bool) -> void:
        if on and armed_cursor == null:
                armed_cursor = Sprite2D.new()
                armed_cursor.texture = _t("star")
                armed_cursor.scale = Vector2.ONE * cell_px * 1.5 / 120.0
                armed_cursor.z_index = 40
                armed_cursor.modulate = Color(1, 0.85, 0.4, 0.85)
                world.add_child(armed_cursor)
                var tw := armed_cursor.create_tween().set_loops()
                tw.tween_property(armed_cursor, "rotation", 0.5, 1.2)
                tw.tween_property(armed_cursor, "rotation", -0.5, 1.2)
        elif not on and armed_cursor != null and is_instance_valid(armed_cursor):
                armed_cursor.queue_free()
                armed_cursor = null


func _fire_power(cellp: Vector2i) -> void:
        var pid := armed
        if pid == "" or cellp.x < 0 or busy:
                return
        if pid != "shuffle" and not _playable(cellp.x, cellp.y):
                return
        var n := int(charges[pid])
        if n <= 0:
                armed = ""
                _set_armed_cursor(false)
                _refresh_rail()
                return
        # THE VAPOR LAW (v0.3.3-p2, the owner's "sound only, no effect" bug):
        # vapor aims at a COLOR - an empty seat or the coin is a rejected aim,
        # the charge STAYS, the cursor stays armed
        if pid == "vapor":
                var vc := _color_at(cellp.x, cellp.y)
                if vc < 0:
                        Jukebox.sfx("error", -10.0)
                        _toast_show("tap a gem - the vapor needs a color")
                        return
        charges[pid] = n - 1
        power_used[pid] = int(power_used[pid]) + 1
        armed = ""
        _set_armed_cursor(false)
        _refresh_rail()
        busy = true
        var pop := {}
        match pid:
                "line":
                        for c in COLS:
                                if _playable(cellp.x, c):
                                        pop[cellp.x * COLS + c] = true
                        for r in ROWS:
                                if _playable(r, cellp.y):
                                        pop[r * COLS + cellp.y] = true
                        beams.append({"a": _cell_pos(cellp.x, 0),
                                        "b": _cell_pos(cellp.x, COLS - 1), "life": 0.3, "max": 0.3})
                        beams.append({"a": _cell_pos(0, cellp.y),
                                        "b": _cell_pos(ROWS - 1, cellp.y), "life": 0.3, "max": 0.3})
                        Jukebox.sfx("m_star", -4.0)
                "bomb":
                        var extra := _blast_cells("flame", cellp.x, cellp.y)
                        for key in extra:
                                pop[key] = true
                        Jukebox.sfx("m_flame", -4.0)
                "vapor":
                        var col := _color_at(cellp.x, cellp.y)
                        for r in ROWS:
                                for c in COLS:
                                        if _playable(r, c) and not grid[r][c].is_empty() \
                                                        and not _is_coin(grid[r][c]) and _color_at(r, c) == col:
                                                pop[r * COLS + c] = true
                                                # the vapour wave is VISIBLE: every
                                                # doomed gem flashes before it pops
                                                var vn: Sprite2D = grid[r][c].get("node")
                                                if is_instance_valid(vn):
                                                        var vt := vn.create_tween()
                                                        vt.tween_property(vn, "modulate",
                                                                        Color(1.6, 0.6, 1.8), 0.16)
                        pop[cellp.y * COLS + cellp.x] = true
                        Jukebox.sfx("m_hyper", -5.0)
        achievement_count("powers_used", 1)
        await _resolve_from_pop(pop)
        busy = false


## the powers and the shuffle resolve through the same loop the swaps use
func _resolve_from_pop(pop: Dictionary) -> void:
        if pop.is_empty():
                return
        cascade = 0
        cascade += 1
        var queue := []
        for key in pop.keys():
                var r := int(key) / COLS
                var c := int(key) % COLS
                if _playable(r, c) and not grid[r][c].is_empty():
                        var sp := String(grid[r][c].get("special", ""))
                        if sp != "":
                                queue.append({"r": r, "c": c, "kind": sp})
        var detonated := {}
        while not queue.is_empty():
                var it: Dictionary = queue.pop_front()
                var dkey := int(it["r"]) * COLS + int(it["c"])
                if detonated.has(dkey):
                        continue
                detonated[dkey] = true
                var extra := _blast_cells(String(it["kind"]), int(it["r"]), int(it["c"]))
                for key in extra:
                        if not pop.has(key):
                                pop[key] = true
                                var r := int(key) / COLS
                                var c := int(key) % COLS
                                if _playable(r, c) and not grid[r][c].is_empty():
                                        var sp2 := String(grid[r][c].get("special", ""))
                                        if sp2 != "" and not detonated.has(key):
                                                queue.append({"r": r, "c": c, "kind": sp2})
        if mode == "ice":
                # the power blasts melt like horizontal matches (3 per column)
                var pcols := {}
                for key in pop.keys():
                        pcols[int(key) % COLS] = true
                var pg: Array = []
                for c in pcols.keys():
                        var cc := {}
                        for r in ROWS:
                                cc[r * COLS + int(c)] = true
                        pg.append({"cells": cc, "dir": "h", "color": 0,
                                        "cross": Vector2i(-1, -1)})
                _plan_melt(pg)
        await _pop_cells(pop, [])
        while true:
                if over:
                        return
                var groups := _find_matches()
                if groups.is_empty():
                        break
                cascade += 1
                var pop2 := {}
                for g in groups:
                        for key in g["cells"]:
                                pop2[key] = true
                await _pop_cells(pop2, [])
                if cascade >= 2:
                        _combo_banner(cascade)
                await _gravity()
        await _gravity()
        _collect_bottom_coins()
        if mode == "mine":
                _mine_row_check()
        if not _has_valid_move():
                await _shuffle_board(true)


func _resolve_after_power() -> void:
        await _resolve_from_pop({})


# ------------------------------------------------ the power sheets
## THE BUY POPUP (v0.3.3-p1, the owner: "when the power is empty, user will
## click and it will show the buying menu for it and will ask for number
## with arrows start from 1 to 3 with dynamic updates like only 2 if
## already 1 used, and gray out the power if the user used all 3 already,
## make it in that buying pop-up shows the GOGABox full balance"):
##  - not owned  -> the wallet UNLOCK button (the full balance pays once)
##  - empty      -> the quantity arrows 1..(3 - used), the total updates
##                  live, the ROUND balance pays, BOTH balances are shown
##  - 3 spent    -> the rail slot itself grays out; the popup never opens
func _power_sheet(pid: String) -> void:
        var sheet := sheet_push(0.0, "power")
        var p: Dictionary = POWERS[pid]
        var t := Arc.fit_label(String(p["name"]).to_upper(), 36, Arc.INK, 560)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var d := Arc.fit_label(String(p["desc"]), 22, Color(0.45, 0.38, 0.28), 560)
        d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(d)
        # THE GLOBAL WALLET LAW (v0.3.3-p2, the owner: "make powerups be based
        # on global GOGACoins and not round-balance"): the popup shows the
        # FULL GOGABox balance and the buy pays it. The round balance is a
        # scoreboard, never a wallet.
        wallet_chip = Arc.coin_chip()
        wallet_chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet_chip)
        var owned: bool = Box.item_owned(game_id, "power", pid)
        if not owned:
                var buy := Arc.button("UNLOCK  -  %d GOGACoins" % int(p["price"]),
                                Vector2(560, 84), 24, Arc.GOOD, func():
                                if Box.spend(int(p["price"])):
                                        Box.buy_item(game_id, "power", pid, 0)
                                        Jukebox.sfx("m_goal", -4.0)
                                        Arc.confetti(_overlay_root_ref(), get_viewport_rect().size / 2.0, 30)
                                        _power_sheet_close()
                                        _refresh_rail()
                                else:
                                        Jukebox.sfx("error", -6.0)
                                        _toast_show("need %d more GOGACoins" % (int(p["price"]) - Box.coins())))
                sheet.add_child(buy)
        else:
                var n := int(charges[pid])
                var used := int(power_used[pid])
                var max_buy: int = POWER_MAX - used - n
                if max_buy <= 0:
                        var done := Arc.fit_label("all %d spent this run - the next run restocks"
                                        % POWER_MAX, 24, Color("2c8a44"), 560)
                        done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        sheet.add_child(done)
                else:
                        # THE ARROWS: - / qty / + , the total rides the qty and
                        # the cap is dynamic (the owner: "arrows start from 1 to
                        # 3 with dynamic updates like only 2 if already 1 used")
                        # (a Dictionary box: GDScript lambdas capture by VALUE -
                        # a plain int would mutate only the handler's own copy)
                        var qty_box := {"n": 1}
                        var row := HBoxContainer.new()
                        row.alignment = BoxContainer.ALIGNMENT_CENTER
                        row.add_theme_constant_override("separation", 14)
                        sheet.add_child(row)
                        var minus := Arc.button("-", Vector2(96, 84), 40, Arc.CARD_2, func(): pass)
                        var qlabel := Arc.fit_label("1", 40, Arc.INK, 90)
                        qlabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        var plus := Arc.button("+", Vector2(96, 84), 40, Arc.CARD_2, func(): pass)
                        row.add_child(minus)
                        row.add_child(qlabel)
                        row.add_child(plus)
                        var total := Arc.fit_label("", 26, Arc.HOT, 560)
                        total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        sheet.add_child(total)
                        var stock := Arc.fit_label("", 20, Color(0.55, 0.45, 0.3), 560)
                        stock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        sheet.add_child(stock)
                        var repaint := func():
                                var q: int = int(qty_box["n"])
                                qlabel.text = str(q)
                                total.text = "BUY %d  -  %d GOGACoins" % [q, q * int(p["refill"])]
                                stock.text = "stocked %d/3  -  %d used this run" % [n + used, used]
                                if wallet_chip != null and is_instance_valid(wallet_chip):
                                        (wallet_chip.get_child(0).get_child(
                                                wallet_chip.get_child(0).get_child_count() - 1)
                                                as Label).text = Box.coins_display()
                                minus.disabled = q <= 1
                                plus.disabled = q >= max_buy
                        minus.pressed.connect(func():
                                qty_box["n"] = maxi(1, int(qty_box["n"]) - 1)
                                repaint.call())
                        plus.pressed.connect(func():
                                qty_box["n"] = mini(max_buy, int(qty_box["n"]) + 1)
                                repaint.call())
                        repaint.call()
                        var buyb := Arc.button("BUY", Vector2(560, 84), 28, Arc.ACCENT, func():
                                var cost: int = int(qty_box["n"]) * int(p["refill"])
                                if Box.spend(cost):
                                        charges[pid] = int(charges[pid]) + int(qty_box["n"])
                                        Jukebox.sfx("m_refill", -4.0)
                                        _power_sheet_close()
                                        _refresh_rail()
                                else:
                                        Jukebox.sfx("error", -6.0)
                                        _toast_show("need %d more GOGACoins" % (cost - Box.coins())))
                        sheet.add_child(buyb)
        var close := Arc.button("CLOSE", Vector2(460, 74), 26, Arc.CARD_2, func(): _power_sheet_close())
        sheet.add_child(close)
        Arc.fit_sheet(sheet, 1)


func _power_sheet_close() -> void:
        sheet_pop()
        wallet_chip = null


# ================================================================ hud
func _refresh_hud() -> void:
        if chip_info == null:
                return
        match mode:
                "challenge":
                        var secs := int(ceilf(round_clock))
                        chip_info.text = "goal %d/%d  %ds" % [round_bank, round_goal, secs]
                        chip_info2.text = "run %ds  r%d" % [int(ceilf(run_clock)), round_no]
                        chip_info2.add_theme_color_override("font_color",
                                Color("d84a3a") if run_clock < 30.0 else Color("35210f"))
                "peace":
                        chip_info.text = "breathe"
                        chip_info2.text = "%ds" % int(peace_secs)
                "butterflies":
                        chip_info.text = "saved %d" % int(Box.counter(game_id, "butterflies"))
                        chip_info2.text = "pace x%d" % pace
                "ice":
                        chip_info.text = "heat %d%%" % int(temp * 100.0)
                        var worst := 0
                        for f in frost:
                                worst = maxi(worst, int(f))
                        chip_info2.text = "ice %d/8" % worst
                        chip_info2.add_theme_color_override("font_color",
                                Color("1c6ea8") if worst >= 6 else Color("35210f"))
                "mine":
                        chip_info.text = "%dm  ice-line %ds" % [depth, int(ceilf(mine_rise_clock))]
                        chip_info2.text = "%ds" % int(ceilf(dig_clock))
                        chip_info2.add_theme_color_override("font_color",
                                Color("d84a3a") if dig_clock < 15.0 else Color("35210f"))


# ================================================================ fx tick
func _tick_fx(delta: float) -> void:
        # the queue draw - one pass over the pooled fx
        for p in pops:
                p["life"] -= delta
                p["pos"] += p["vel"] * delta
                p["vel"].y += 900.0 * delta
        pops = pops.filter(func(p): return float(p["life"]) > 0.0)
        for r in rings:
                r["life"] -= delta
                r["r"] += 260.0 * delta
        rings = rings.filter(func(r): return float(r["life"]) > 0.0)
        for b in beams:
                b["life"] -= delta
        beams = beams.filter(func(b): return float(b["life"]) > 0.0)
        for z in zaps:
                z["life"] -= delta
        zaps = zaps.filter(func(z): return float(z["life"]) > 0.0)
        for f in floaters:
                f["life"] -= delta
                f["pos"].y -= 46.0 * delta
        floaters = floaters.filter(func(f): return float(f["life"]) > 0.0)
        queue_redraw()


func _draw() -> void:
        if world == null:
                return
        for p in pops:
                var a: float = float(p["life"]) / float(p["max"])
                draw_circle(p["pos"], float(p["r"]) * (0.5 + 0.5 * a), Color(p["col"], a))
        for r in rings:
                var a2: float = float(r["life"]) / float(r["max"])
                draw_arc(r["pos"], float(r["r"]), 0.0, TAU, 40, Color(r["col"], a2), float(r["w"]), true)
        for b in beams:
                var a3: float = float(b["life"]) / float(b["max"])
                draw_line(b["a"], b["b"], Color(1.0, 0.95, 0.7, a3 * 0.9), 14.0 * a3 + 2.0)
        for z in zaps:
                var a4: float = float(z["life"]) / float(z["max"])
                # a jagged arc: 5 segments with a wobble
                var prev: Vector2 = z["a"]
                for i in range(1, 6):
                        var t := float(i) / 5.0
                        var pt: Vector2 = (z["a"] as Vector2).lerp(z["b"], t)
                        if i < 5:
                                pt += Vector2(randf_range(-16, 16), randf_range(-16, 16))
                        draw_line(prev, pt, Color(0.8, 0.9, 1.0, a4), 5.0 * a4 + 1.5)
                        prev = pt
        for f in floaters:
                var a5: float = float(f["life"]) / float(f["max"])
                var font := ThemeDB.fallback_font
                draw_string(font, f["pos"] + Vector2(2, 2), String(f["txt"]),
                                HORIZONTAL_ALIGNMENT_CENTER, 460, int(f["size"]), Color(0, 0, 0, a5 * 0.5))
                draw_string(font, f["pos"], String(f["txt"]), HORIZONTAL_ALIGNMENT_CENTER,
                                460, int(f["size"]), Color(f["col"], a5))


