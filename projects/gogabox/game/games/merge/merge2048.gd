extends GogaGame
## 2048 - v0.2.8 THE VERDICT ROUND II. The owner played the v0.2.7 rebuild
## and ruled on five things:
##   1. "the classic theme background is blue, i guess you misunderstood
##      me when i said deep blue i just meant for the sea theme" - Classic
##      wears the WARM PAPER of the real 2048 palette now (cream, warm
##      dust, soft vignette); the deep blue belongs to Deep Sea alone.
##   2. "when collected it never disappear until another coin appear" -
##      the coin canvas item kept the stale painting because the layer
##      only redrawed while a coin was ALIVE. It redraws on the take and
##      every tick now - the coin is GONE the frame it is collected.
##   3. the sea water was "just animations based on movement even if
##      there is no movement... a weird wave and not real physical-based
##      water" - REBUILT: a per-tile spring driven by the tile's ACTUAL
##      motion (its real position deltas -> container acceleration),
##      damped settle, tilt + energy fed to the shader. No movement =
##      NO water movement, and the weird time-wave is dead - the surface
##      is a natural meniscus that only moves when the tile truly moves.
##   4. "add an options menu shows 4x4 normal and 6x6 and 8x8, make the
##      others be bought first for high prices, make 6x6 score bonus be
##      /80 and 8x8 /160" - the OPTIONS sheet sells the boards (6x6 and
##      8x8 are shop items), and the run bonus follows the board through
##      a MODULAR per-game override (host_node reads bonus_div_override;
##      no game names in the economy). Switching the size starts a
##      fresh board.
##   5. the thumbnail's empty square wore a "+1" whose Kenney "1" glyph
##      reads as "41" - the pop is gone from the thumb, and the scene
##      wears the new warm classic look.
## (v0.2.7 history: the owner called the old stub "somehow totally broken
## for real" - hardcoded corner board, teleporting tiles, merge-value-sum
## score, auto coins. The rebuild: the centered board, tiles that keep
## their identity and tween, +1 per fusion, the coin cell every 15
## fusions, the theme shop.)
##
## Owner contract (v0.2.7, still law):
##   - the grid CENTERED and BIGGER (viewport-computed, aware of the
##     banner strip)
##   - controls = swipe the finger in ANY direction (TouchKit.swiped) +
##     a board nudge so every accepted swipe is FELT
##   - each successful fusion worth EXACTLY 1 score point
##   - after every 15 fusions, one empty cell grows a REAL GOGACoin
##     (coin.png, fade-in, bob, glint) - slide any tile INTO that cell
##     to take it; if the board is full when it falls due, it waits
##   - animations and effects: real slides, merges pop + ring +
##     square-chunk particles that bounce off the board frame, floating
##     +1, golden pulses, the gray cascade end, the 2048 burst
##   - SHOP themes: Classic (free) / Minecraft (800) / Deep Sea (650)
##   - the run ends when no move is left (the classic law)
##   - banner: the board sits above the strip (registry banner true)
##
## Probe contract: board/tiles/_slide/coin state is public, _load_grid
## seeds a board directly, theme ids + prices are consts.

const COIN_EVERY := 15               # owner: one GOGACoin cell per 15 fusions
const WIN_TILE := 2048
const SLIDE_TIME := 0.11             # s - the tween + lock window
const MERGE_POP := 1.24

## THE BOARD SIZES (owner v0.2.8): 4x4 is the free normal game, 6x6 and
## 8x8 are SHOP items bought for real prices first. The run bonus follows
## the board: /20 (the registry default, div 0 = use it), /80, /160.
const SIZES := {
                "4": {"name": "4 x 4", "price": 0, "div": 0,
                                "desc": "normal - the classic board, bonus /20"},
                "6": {"name": "6 x 6", "price": 1800, "div": 80,
                                "desc": "bigger board - score bonus /80"},
                "8": {"name": "8 x 8", "price": 3600, "div": 160,
                                "desc": "the monster board - score bonus /160"},
}

const THEMES := {
                "classic": {"name": "Classic", "price": 0,
                                "desc": "the warm paper board - the real 2048 feel"},
                "minecraft": {"name": "Minecraft", "price": 800,
                                "desc": "stone backdrop, block tiles, lava-glow numbers - thuds + embers"},
                "sea": {"name": "Deep Sea", "price": 650,
                                "desc": "glass cells with REAL water inside - the water answers the tile's true motion"},
}

## the classic tier ramp (the 2048 law: warm and readable)
const CLASSIC_TILE := {
        2: Color("efe6d8"), 4: Color("edd9b0"), 8: Color("f2b179"),
        16: Color("f59563"), 32: Color("f67c5f"), 64: Color("f65e3b"),
        128: Color("edcf72"), 256: Color("edcc61"), 512: Color("edc850"),
        1024: Color("edc53f"), 2048: Color("edc22e"),
}
const MC_TIERS := {
        2: Color("5d9c3c"), 4: Color("8a6a46"), 8: Color("a8824e"),
        16: Color("8a8f96"), 32: Color("c8cdd4"), 64: Color("c0714a"),
        128: Color("e8c14a"), 256: Color("c4402e"), 512: Color("4ac2c8"),
        1024: Color("3cc860"), 2048: Color("f08a1a"),
}

# ---------------- state ----------------------------------------------------
var board: Array = []                # grid[x][y] ints (0 = empty)
var grid_n := 4                      # THE BOARD SIZE (4 normal / 6 / 8)
var size_id := "4"                   # the equipped size key (SIZES)
var tiles := {}                      # Vector2i -> TileNode
var animating := false
var over_board := false              # no more moves (the run is finishing)

var cell := 120.0                    # computed in _layout_board
var gap := 12.0
var board_side := 528.0
var board_rect := Rect2()            # the frame rect (screen coords)
var board_root: Node2D               # tiles + the swipe nudge live here
var bg_layer: Node2D
var board_layer: Node2D
var coin_layer: Node2D
var fx_layer: Node2D

var coin_cell := Vector2i(-1, -1)    # the GOGACoin cell (an EMPTY cell)
var coin_t := 0.0                    # its fade-in clock
var coin_pending := false            # board was full when it fell due
var fusions_since := 0               # fusions since the last coin cell

var parts: Array = []                # square-chunk particles (they bounce)
var pops: Array = []                 # floating +1 texts
var sparkles: Array = []             # coin-collection sparkles
var won := false                     # the 2048 burst fired once

var _merge_victims: Array = []       # nodes waiting to be freed at pop time
var _mc_stone: Texture2D             # minecraft generated blocks
var _mc_dirt: Texture2D
var _mc_blocks := {}                 # value -> Texture2D
var _sea_time := 0.0
var _time := 0.0
var _rng := RandomNumberGenerator.new()
var _shop_pair: Array = []
var _confirm_pair: Array = []        # the are-you-sure pair (the size law)
var _options_pair: Array = []        # the OPTIONS sheet owns its pair too

# the water physics constants (v0.2.8 THE REAL MOTION LAW). The surface is
# a damped spring per tile; the container acceleration comes from the
# tile's REAL position deltas each frame. No motion -> no force -> calm.
const W_K := 49.0            # spring stiffness (sqrt = 7 rad/s ~ 1.1 Hz)
const W_C := 1.9             # damping (a few natural swings, then calm)
const W_ACC_K := 0.00034     # container acceleration -> surface force
const W_ACC_MAX := 150000.0  # px/s^2 clamp (a slide's ease spikes)

# ============================================================ setup / layout

func _goga_setup() -> void:
        _rng.randomize()
        tk.swiped.connect(_on_swipe)
        var vp := get_viewport_rect().size
        bg_layer = Node2D.new()
        bg_layer.z_index = -10
        bg_layer.texture_filter = Node2D.TEXTURE_FILTER_NEAREST   # crisp blocks
        bg_layer.draw.connect(_draw_bg)
        add_child(bg_layer)
        board_layer = Node2D.new()
        board_layer.z_index = -5
        board_layer.texture_filter = Node2D.TEXTURE_FILTER_NEAREST
        board_layer.draw.connect(_draw_board)
        add_child(board_layer)
        coin_layer = Node2D.new()
        coin_layer.z_index = -3
        coin_layer.draw.connect(_draw_coin_cell)
        add_child(coin_layer)
        board_root = Node2D.new()
        board_root.z_index = 0
        add_child(board_root)
        fx_layer = Node2D.new()
        fx_layer.z_index = 5
        fx_layer.draw.connect(_draw_fx)
        add_child(fx_layer)
        _layout_board()
        _make_mc_textures()
        _load_size()
        board = []
        for x in grid_n:
                var col := []
                col.resize(grid_n)
                col.fill(0)
                board.append(col)
        set_hud_score_prefix("FUSIONS")
        add_hud_button("SHOP", func(): _shop_open())
        add_hud_button("OPTIONS", func(): _options_open())
        set_score(0)
        _spawn_random()
        _spawn_random()
        Jukebox.sfx("confirm", -14.0)

## THE SIZE LAW (owner v0.2.8): the equipped board size decides grid_n and
## the run bonus. div 0 = use the registry coin_div (4x4 stays /20).
func _load_size() -> void:
        var on := Box.item_on(game_id, "size")
        size_id = on if SIZES.has(on) else "4"
        grid_n = int(size_id)
        var div := int(SIZES[size_id]["div"])
        bonus_div_override = div if div > 0 else -1

func _size_div() -> int:
        var div := int(SIZES[size_id]["div"])
        return div if div > 0 else int(GameReg.get_game(game_id).get("coin_div", 100))

## a size change REBUILDS the run (the honest board: fresh tiles, fresh
## score - no mixing 6x6 earnings into a 4x4 run).
func _apply_size(id: String) -> void:
        size_id = id
        grid_n = int(id)
        var div := int(SIZES[id]["div"])
        bonus_div_override = div if div > 0 else -1
        for c in tiles:
                var t: TileNode = tiles[c]
                if is_instance_valid(t):
                        t.queue_free()
        tiles = {}
        for p in _merge_victims:
                if is_instance_valid(p):
                        p.queue_free()
        _merge_victims = []
        _pending_merges = []
        coin_cell = Vector2i(-1, -1)
        coin_pending = false
        fusions_since = 0
        won = false
        over_board = false
        animating = false
        _layout_board()
        board = []
        for x in grid_n:
                var col := []
                col.resize(grid_n)
                col.fill(0)
                board.append(col)
        set_score(0)
        _spawn_random()
        _spawn_random()
        bg_layer.queue_redraw()
        board_layer.queue_redraw()
        coin_layer.queue_redraw()
        Jukebox.sfx("confirm", -6.0)

## THE CENTERING LAW (owner: "the same grid, but centered and more
## bigger"): the board is the biggest square of the CURRENT size that fits
## between the HUD bar and the banner strip, centered both ways.
func _layout_board() -> void:
        var vp := get_viewport_rect().size
        var top_pad := 104.0
        var bottom_pad := banner_bottom() + 16.0
        var avail := vp.y - top_pad - bottom_pad
        var side: float = minf(vp.x - 26.0, avail)
        side = maxf(side, 260.0)
        gap = side * 0.026
        cell = (side - gap * float(grid_n + 1)) / float(grid_n)
        board_side = cell * float(grid_n) + gap * float(grid_n + 1)
        var bx := (vp.x - board_side) * 0.5
        var by := top_pad + maxf(0.0, (avail - board_side) * 0.5)
        board_rect = Rect2(bx, by, board_side, board_side)

func _cell_pos(c: Vector2i) -> Vector2:
        return Vector2(board_rect.position.x + gap + float(c.x) * (cell + gap) + cell * 0.5,
                        board_rect.position.y + gap + float(c.y) * (cell + gap) + cell * 0.5)

func _theme_id() -> String:
        var on := Box.item_on(game_id, "theme")
        return on if THEMES.has(on) else "classic"

func _theme_price(id: String) -> int:
        return int(THEMES[id]["price"]) if THEMES.has(id) else 0

# ============================================================ the tile node
## One node per tile, born once, KEPT while it slides (the old stub freed
## the source and respawned at the destination - nothing ever animated).
## The face is drawn by the node itself per theme; the number is a child
## Label (children never inherit this node's water material).

class TileNode:
        extends Node2D
        var value := 0
        var face := 0.0
        var game: Node = null
        var lab: Label = null
        var mat: ShaderMaterial = null      # sea only
        var fill := 0.35                     # sea: the water level IS the tier
        # --- v0.2.8 THE REAL MOTION WATER: a damped surface spring per
        # tile, fed by this node's ACTUAL position deltas (the container
        # acceleration). Nothing here is fed by the swipe direction; a
        # tile that never moves never excites its water.
        var w_off := 0.0                     # surface tilt (+ = higher right)
        var w_vel := 0.0                     # its velocity (the splash kick)
        var w_energy := 0.0                  # ripple/foam fuel (decays calm)
        var last_pos := Vector2.INF          # measured each sea tick
        var last_vel := 0.0
        var acc_s := 0.0                     # low-passed container accel
        var born_pop := false

        func setup(v: int, g: Node, size: float) -> void:
                value = v
                game = g
                face = size
                if lab == null:
                        lab = Arc.label("", 40, Color.WHITE)
                        lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
                        lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        add_child(lab)
                lab.position = Vector2(-face * 0.5, -face * 0.5)
                lab.size = Vector2(face, face)
                lab.text = str(v)          # THE NUMBER (v0.2.7 QA catch: the
                                           # rebuilt node never set it - the
                                           # board rendered numberless)
                var theme: String = game._theme_id()
                mat = null
                var digits: int = str(v).length()
                var fs: float = face * (0.44 if digits == 1 else 0.40 if digits == 2 \
                                else 0.32 if digits == 3 else 0.26)
                lab.add_theme_font_size_override("font_size", int(fs))
                if theme == "sea":
                        lab.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0))
                        lab.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
                        lab.add_theme_constant_override("shadow_offset_x", 2)
                        lab.add_theme_constant_override("shadow_offset_y", 2)
                        lab.position.y = -face * 0.5 - face * 0.06   # the water is below
                        var sh: Shader = game._water_shader()
                        mat = ShaderMaterial.new()
                        mat.shader = sh
                        fill = game._sea_fill(v)
                        mat.set_shader_parameter("fill", fill)
                        mat.set_shader_parameter("rect_px", face)
                        mat.set_shader_parameter("radius_px", face * 0.14)
                        mat.set_shader_parameter("time_s", game._sea_time)
                        mat.set_shader_parameter("tilt", w_off)
                        mat.set_shader_parameter("energy", w_energy)
                        last_pos = position                # the motion watch starts NOW
                        material = mat
                else:
                        material = null
                        if theme == "minecraft":
                                var lava: bool = v >= 128
                                lab.add_theme_color_override("font_color",
                                                Color(1.0, 0.86, 0.55) if lava else Color(0.96, 0.96, 0.94))
                                lab.add_theme_color_override("font_shadow_color", Color(0.08, 0.06, 0.04, 0.85))
                                lab.add_theme_constant_override("shadow_offset_x", 3)
                                lab.add_theme_constant_override("shadow_offset_y", 3)
                        else:
                                var bgc: Color = game.tile_color(v)
                                var light: bool = v <= 4 or v >= 128
                                lab.add_theme_color_override("font_color",
                                                Color("6b5d4e") if light else Color(0.99, 0.97, 0.92))
                                lab.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
                        texture_filter = TEXTURE_FILTER_NEAREST if theme == "minecraft" \
                                        else TEXTURE_FILTER_PARENT_NODE
                queue_redraw()

        func _draw() -> void:
                var theme: String = game._theme_id()
                var h := face
                var r := Rect2(-h * 0.5, -h * 0.5, h, h)
                if theme == "sea":
                        # the water shader colors this rect (UV space)
                        draw_rect(Rect2(-h * 0.5, -h * 0.5, h, h), Color.WHITE)
                        return
                if theme == "minecraft":
                        var tex: Texture2D = game.mc_block(value)
                        if tex != null:
                                draw_texture_rect(tex, r, false)
                        else:
                                draw_rect(r, Color("8a8f96"))
                        # hot tiers glow like lava (breathing, hot overlay)
                        if value >= 128:
                                var pulse: float = 0.5 + 0.5 * sin(game._time * 3.1 + float(value) * 0.7)
                                var glow := Color(1.0, 0.50, 0.10, 0.34 + 0.30 * pulse)
                                if value >= 1024:
                                        glow = Color(1.0, 0.38, 0.06, 0.40 + 0.32 * pulse)
                                draw_rect(r.grow(2.0), glow)
                                # the hot core (breathes from the center)
                                var core := r.grow(-face * 0.16)
                                draw_rect(core, Color(1.0, 0.62, 0.14, 0.10 + 0.16 * pulse))
                                draw_rect(r, Color(0, 0, 0, 0.35), false, 2.0)
                        return
                # classic: the warm rounded face + a soft top bevel
                var bgc: Color = game.tile_color(value)
                var sb := Arc.panel_style(bgc, int(h * 0.13))
                draw_style_box(sb, r)
                var bev := bgc.lightened(0.10)
                bev.a = 0.55
                draw_rect(Rect2(-h * 0.5 + h * 0.06, -h * 0.5 + h * 0.06,
                                h * 0.88, h * 0.16), bev)

# ============================================================ painting: bg

func _draw_bg() -> void:
        var vp := get_viewport_rect().size
        var theme := _theme_id()
        if theme == "minecraft":
                # the stone-block wall (tiled, nearest - real pixels)
                if _mc_stone != null:
                        bg_layer.draw_texture_rect(_mc_stone, Rect2(Vector2.ZERO, vp), false)
                        # a soft darkening so the board pops
                        bg_layer.draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.24))
                return
        if theme == "sea":
                # the deep: a vertical gradient + slow caustic glints
                var pts := PackedVector2Array([Vector2(0, 0), Vector2(vp.x, 0),
                                Vector2(vp.x, vp.y), Vector2(0, vp.y)])
                var cols := PackedColorArray([Color("0d2c50"), Color("0d2c50"),
                                Color("071a33"), Color("071a33")])
                bg_layer.draw_polygon(pts, cols)
                for i in 26:
                        var ph := float(i) * 2.399
                        var cx: float = fmod(absf(sin(ph * 1.7) * 137.0), 1.0) * vp.x
                        var cy: float = fmod(absf(sin(ph * 0.61 + 2.0) * 251.0), 1.0) * vp.y
                        var br: float = 0.5 + 0.5 * sin(_sea_time * (0.6 + 0.13 * float(i % 5)) + ph)
                        if br < 0.25:
                                continue
                        var rr: float = (5.0 + 9.0 * _hashf(i, 3.1))
                        bg_layer.draw_arc(Vector2(cx, cy), rr, 0.0, TAU, 14,
                                        Color(0.55, 0.8, 1.0, 0.05 * br), 1.6)
                return
        # classic: THE WARM PAPER (owner v0.2.8: "the classic theme
        # background is blue, i guess you misunderstood me when i said deep
        # blue i just meant for the sea theme - for classic, make the
        # background really suitable"). The real 2048 palette IS warm: the
        # cream page, a whisper of warm dust, a soft corner vignette - the
        # beige tiles sit on their natural paper.
        bg_layer.draw_rect(Rect2(Vector2.ZERO, vp), Color("efe7d8"))
        var gr := board_rect.grow(board_side * 0.55)
        bg_layer.draw_rect(gr, Color(1.0, 0.98, 0.92, 0.5))
        # the vignette: four soft warm-brown edges (drawn as rings so it
        # stays a rectangle shading, not a blob)
        for i in 3:
                var a := 0.05 - 0.013 * float(i)
                bg_layer.draw_rect(Rect2(Vector2.ZERO, vp).grow(-float(i) * 26.0),
                                Color(0.42, 0.34, 0.24, a), false,
                                30.0 + float(i) * 16.0)
        for i in 12:
                var ph := float(i) * 2.91
                var cx: float = fmod(absf(sin(ph * 2.13) * 173.0), 1.0) * vp.x
                var cy: float = fmod(absf(sin(ph * 0.77 + 1.3) * 311.0), 1.0) * vp.y
                var drift: float = sin(_time * 0.22 + ph) * 9.0
                bg_layer.draw_circle(Vector2(cx + drift, cy + drift * 0.6),
                                1.6 + _hashf(i, 7.7) * 2.2, Color(0.55, 0.45, 0.3, 0.07))

func _draw_board() -> void:
        var theme := _theme_id()
        var frame := board_rect.grow(gap * 0.6)
        if theme == "minecraft":
                if _mc_stone != null:
                        board_layer.draw_texture_rect(_mc_stone, frame, false)
                        board_layer.draw_rect(frame, Color(0, 0, 0, 0.22))
        elif theme == "sea":
                board_layer.draw_rect(frame, Color("0a2240"))
                board_layer.draw_rect(frame, Color(0.45, 0.72, 0.95, 0.30), false, 2.0)
        else:
                var sb := Arc.panel_style(Color("b9a99a"), int(gap * 2.4))
                draw_style_box_on(board_layer, sb, frame)
        for x in grid_n:
                for y in grid_n:
                        var hole := Rect2(board_rect.position.x + gap + float(x) * (cell + gap),
                                        board_rect.position.y + gap + float(y) * (cell + gap),
                                        cell, cell)
                        if theme == "minecraft":
                                if _mc_dirt != null:
                                        board_layer.draw_texture_rect(_mc_dirt, hole, false)
                                        board_layer.draw_rect(hole, Color(0, 0, 0, 0.18))
                        elif theme == "sea":
                                board_layer.draw_rect(hole.grow(-2.0), Color("10325a"))
                                board_layer.draw_rect(hole.grow(-2.0),
                                                Color(0.4, 0.66, 0.9, 0.16), false, 1.6)
                        else:
                                var hb := Arc.panel_style(Color("cdc1b4"), int(cell * 0.10))
                                draw_style_box_on(board_layer, hb, hole)

## Node2D has draw_style_box (CanvasItem) - this shim keeps the call sites
## honest about WHICH canvas item paints.
func draw_style_box_on(ci: CanvasItem, sb: StyleBox, r: Rect2) -> void:
        ci.draw_style_box(sb, r)

func tile_color(v: int) -> Color:
        return CLASSIC_TILE.get(v, Color("3c3a32"))

func _sea_fill(v: int) -> float:
        if v <= 1:
                return 0.0
        return clampf(0.22 + (log(float(v)) / log(2.0) - 1.0) * 0.105, 0.22, 0.95)

var _water_sh: Shader = null
func _water_shader() -> Shader:
        if _water_sh == null:
                _water_sh = load("res://assets/games/merge/water_tile.gdshader")
        return _water_sh

# ============================================================ minecraft art

func _hashf(n: float, salt: float = 0.0) -> float:
        return fmod(absf(sin(n * 127.1 + salt * 311.7)) * 43758.5453, 1.0)

## the generated blocks: deterministic pixel noise + a 1px mortar border +
## a top highlight (the owner: "background and grid be like minecraft
## blocks") - no vendored art needed, and every tile looks the same twice.
func _make_mc_textures() -> void:
        _mc_stone = _make_block_tex(Color("7e838b"), Color("5b6067"), 16)
        _mc_dirt = _make_block_tex(Color("8a6a46"), Color("6a4f34"), 16)
        for v in MC_TIERS:
                _mc_blocks[v] = _make_block_tex(MC_TIERS[v], MC_TIERS[v].darkened(0.38), 8)

func _make_block_tex(base: Color, mortar: Color, bpx: int) -> ImageTexture:
        var size := 64
        var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
        for y in size:
                for x in size:
                        var bi := float((x / bpx) * 7 + (y / bpx) * 13)
                        var shade: float = (_hashf(bi, float(bpx)) - 0.5) * 0.20
                        var grain: float = (_hashf(float(x) * 1.3, float(y) * 0.7) - 0.5) * 0.12
                        var c := base.lightened(shade + grain)
                        # a top-left highlight + a bottom-right shade (blocky depth)
                        if x % bpx == 1 and y % bpx > 0 and y % bpx < bpx:
                                c = c.lightened(0.16)
                        if (y % bpx == bpx - 1 or x % bpx == bpx - 1) and y % bpx != 0 and x % bpx != 0:
                                c = c.darkened(0.16)
                        if x % bpx == 0 or y % bpx == 0:
                                c = mortar
                        img.set_pixel(x, y, c)
        return ImageTexture.create_from_image(img)

func mc_block(v: int) -> Texture2D:
        return _mc_blocks.get(v)

# ============================================================ the run

## THE SLIDE ENGINE (the classic law, with the PGB move-list shape): every
## tile walks as far as it can; the first equal, not-yet-merged neighbor
## eats it. The board updates INSTANTLY; the visuals tween after.
func _slide(dirv: Vector2i) -> bool:
        var moved := false
        var merges: Array = []
        var moves: Array = []
        var xs: Array = []
        var ys: Array = []
        for i in grid_n:
                xs.append(i)
                ys.append(i)
        if dirv.x > 0:
                xs.reverse()
        if dirv.y > 0:
                ys.reverse()
        var nb := []
        for x in grid_n:
                var col := []
                col.resize(grid_n)
                col.fill(0)
                nb.append(col)
        var merged := {}
        for x in xs:
                for y in ys:
                        var v := int(board[x][y])
                        if v == 0:
                                continue
                        var cx: int = x
                        var cy: int = y
                        while true:
                                var nx: int = cx + dirv.x
                                var ny: int = cy + dirv.y
                                if nx < 0 or nx >= grid_n or ny < 0 or ny >= grid_n:
                                        break
                                var nv := int(nb[nx][ny])
                                if nv == 0:
                                        cx = nx
                                        cy = ny
                                        continue
                                if nv == v and not merged.has(Vector2i(nx, ny)):
                                        cx = nx
                                        cy = ny
                                break
                        var dest := Vector2i(cx, cy)
                        if int(nb[cx][cy]) == v and not merged.has(dest):
                                nb[cx][cy] = v * 2
                                merged[dest] = true
                                merges.append({"at": dest, "value": v * 2})
                                moves.append({"from": Vector2i(x, y), "to": dest})
                                moved = true
                        elif int(nb[cx][cy]) == 0:
                                nb[cx][cy] = v
                                if cx != x or cy != y:
                                        moved = true
                                moves.append({"from": Vector2i(x, y), "to": dest})
        board = nb
        _pending_merges = merges
        if moved:
                _apply_moves(moves, merges, dirv)
                _sweep_coin(dirv, moves)
        return moved

## THE SWEEP LAW: a tile sliding THROUGH the coin cell takes it - the coin
## rides the slide just like a real coin on a table swept by a hand. A tile
## that lands on it counts too (its path ends there). This is what makes
## the coin feel physical instead of a cell-locked trap.
func _sweep_coin(dirv: Vector2i, moves: Array) -> void:
        if coin_cell.x < 0:
                return
        for m in moves:
                var from: Vector2i = m["from"]
                var to: Vector2i = m["to"]
                if dirv.x != 0:
                        if from.y == coin_cell.y \
                                        and minf(float(from.x), float(to.x)) <= float(coin_cell.x) \
                                        and float(coin_cell.x) <= maxf(float(from.x), float(to.x)):
                                _take_coin_cell()
                                return
                else:
                        if from.x == coin_cell.x \
                                        and minf(float(from.y), float(to.y)) <= float(coin_cell.y) \
                                        and float(coin_cell.y) <= maxf(float(from.y), float(to.y)):
                                _take_coin_cell()
                                return

func _take_coin_cell() -> void:
        add_run_coins(1)
        Jukebox.sfx("coin", -4.0)
        sparkles.append({"x": _cell_pos(coin_cell).x, "y": _cell_pos(coin_cell).y,
                        "life": 0.6, "max": 0.6})
        coin_cell = Vector2i(-1, -1)
        # THE VANISH LAW (owner v0.2.8: "when collected it never disappear
        # until another coin appear"): the coin canvas item kept the stale
        # painting because nothing asked it to repaint while EMPTY. One
        # explicit redraw erases it the same frame it is taken.
        coin_layer.queue_redraw()

var _pending_merges: Array = []

## THE REAL ANIMATION: every tile node KEEPS its identity and tweens to its
## destination (the old stub freed the source and respawned a fresh node -
## everything teleported). Merge destinations are left empty here; the
## doubled tile is born at pop time from the victims.
func _apply_moves(moves: Array, merges: Array, dirv: Vector2i) -> void:
        var merge_dests := {}
        for mg in merges:
                merge_dests[mg["at"]] = true
        var consumed := {}
        for m in moves:
                consumed[m["from"]] = true
        var new_tiles := {}
        for c in tiles:
                if not consumed.has(c) and not merge_dests.has(c):
                        new_tiles[c] = tiles[c]
                elif not consumed.has(c) and merge_dests.has(c):
                        _merge_victims.append(tiles[c])
        for m in moves:
                var t: TileNode = tiles.get(m["from"])
                if t == null:
                        continue
                var dest: Vector2i = m["to"]
                if merge_dests.has(dest):
                        _merge_victims.append(t)
                else:
                        new_tiles[dest] = t
                var tw := t.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
                tw.tween_property(t, "position", _cell_pos(dest), SLIDE_TIME)
                # (v0.2.8: NOTHING is fed to the water here. The sea tick
                # watches each tile's REAL position every frame - the ride's
                # acceleration is the force. A tile that does not move
                # (from == to) never excites its water: the owner's law -
                # "if a square is at the left edge and i swiped to left, i
                # will still see the water moves which is unreal".)
        tiles = new_tiles

func _finish_slide() -> void:
        # 1. the merges pop: victims free ONCE, the doubled tiles are BORN
        for vic in _merge_victims:
                if is_instance_valid(vic):
                        vic.queue_free()
        _merge_victims = []
        var gained := 0
        for mg in _pending_merges:
                var at: Vector2i = mg["at"]
                var v: int = mg["value"]
                var t := TileNode.new()
                t.position = _cell_pos(at)
                t.setup(v, self, cell)
                t.scale = Vector2.ONE * 0.4
                board_root.add_child(t)
                tiles[at] = t
                var tw := t.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                tw.tween_property(t, "scale", Vector2.ONE, 0.17)
                gained += 1
                add_score(1)                             # THE OWNER'S LAW: 1 point per fusion
                pops.append({"x": t.position.x, "y": t.position.y - cell * 0.4,
                                "life": 0.7, "txt": "+1"})
                _spawn_merge_parts(t.position, _part_col(v), 7 + mini(6, v / 128))
                Jukebox.sfx(_merge_sfx(v), -6.0, 0.85 + 0.03 * log(float(v)) / log(2.0))
                if v >= 128:
                        _pulse_board(t.position, v)
                if _theme_id() == "sea" and t.mat != null:
                        # THE SPLASH: a fresh doubled tile drops into the
                        # cell - the spring gets a real velocity kick (the
                        # energy it carries decays; the surface settles)
                        t.w_vel = _rng.randf_range(-3.2, 3.2)
                        t.w_energy = 1.5
                achievement_max("max_tile", v)
                if v >= WIN_TILE and not won:
                        won = true
                        _win_burst(t.position)
        _merge_victims = []
        _pending_merges = []
        if gained > 0:
                check_achievements()
                fusions_since += gained
        # 2. the coin cell law (the owner): every 15 fusions one EMPTY cell
        # grows a coin - it claims its cell BEFORE the fresh tile spawns, so
        # the reward can never be squeezed out by the 90/10 spawn
        if coin_cell.x >= 0 and int(board[coin_cell.x][coin_cell.y]) != 0:
                _take_coin_cell()                        # a tile landed dead on it
        if coin_pending and coin_cell.x < 0:
                coin_pending = false
                fusions_since = COIN_EVERY               # a cell freed - pay the wait
        if fusions_since >= COIN_EVERY and coin_cell.x < 0:
                fusions_since = 0
                _spawn_coin_cell()
        # 3. a fresh tile joins (the classic 90/10)
        _spawn_random()
        # 4. the end law: no moves left = the run is over
        if _is_stuck():
                _game_over()

func _spawn_coin_cell() -> void:
        var empty: Array[Vector2i] = []
        for x in grid_n:
                for y in grid_n:
                        if int(board[x][y]) == 0 and not Vector2i(x, y) == coin_cell:
                                empty.append(Vector2i(x, y))
        if empty.is_empty():
                coin_pending = true                      # the board is full - it waits
                return
        coin_cell = empty[_rng.randi() % empty.size()]
        coin_t = 0.0
        coin_layer.queue_redraw()

func _spawn_random() -> void:
        var empty: Array[Vector2i] = []
        for x in grid_n:
                for y in grid_n:
                        # v0.2.8 catch: the fresh spawn must NEVER land on
                        # the coin cell - the coin owns its cell until a
                        # slide really sweeps it (a collision here let the
                        # 90/10 swallow the reward and auto-collect it)
                        if int(board[x][y]) == 0 and Vector2i(x, y) != coin_cell:
                                empty.append(Vector2i(x, y))
        if empty.is_empty():
                return
        var c: Vector2i = empty[_rng.randi() % empty.size()]
        var v := 2 if _rng.randf() < 0.9 else 4
        board[c.x][c.y] = v
        var t := TileNode.new()
        t.position = _cell_pos(c)
        t.setup(v, self, cell)
        board_root.add_child(t)
        tiles[c] = t
        t.scale = Vector2.ZERO
        var tw := t.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.tween_property(t, "scale", Vector2.ONE, 0.15)
        _spawn_merge_parts(t.position, _part_col(v), 4)

## no empty cell AND no equal neighbors = stuck (the classic end law)
func _is_stuck() -> bool:
        for x in grid_n:
                for y in grid_n:
                        var v := int(board[x][y])
                        if v == 0:
                                return false
                        if x + 1 < grid_n and int(board[x + 1][y]) == v:
                                return false
                        if y + 1 < grid_n and int(board[x][y + 1]) == v:
                                return false
        return true

func _game_over() -> void:
        if over_board or over:
                return
        over_board = true
        animating = true
        Jukebox.sfx("lose", -2.0)
        # the gray cascade: rows fade out one after another (the old stub
        # just jumped to the dead menu - no moment, no theatre)
        var row := 0
        for y in grid_n:
                for x in grid_n:
                        var t: TileNode = tiles.get(Vector2i(x, y))
                        if t == null or not is_instance_valid(t):
                                continue
                        var tw := t.create_tween()
                        tw.tween_interval(0.05 * float(row))
                        tw.tween_property(t, "modulate", Color(0.62, 0.64, 0.72), 0.16)
                row += 1
        var tw2 := create_tween()
        tw2.tween_interval(0.05 * float(row) + 0.35)
        tw2.tween_callback(func():
                        animating = false
                        check_achievements()
                        finish_run(score))

func _win_burst(at: Vector2) -> void:
        Jukebox.sfx("achievement", -2.0)
        pops.append({"x": at.x, "y": at.y - cell * 0.7, "life": 1.4, "txt": "2048!"})
        for i in 30:
                var ang := TAU * float(i) / 30.0
                parts.append({"x": at.x, "y": at.y,
                                "vx": cos(ang) * _rng.randf_range(180.0, 420.0),
                                "vy": sin(ang) * _rng.randf_range(180.0, 420.0) - 120.0,
                                "life": _rng.randf_range(0.7, 1.1), "max": 1.1,
                                "size": _rng.randf_range(6.0, 13.0), "rot": 0.0,
                                "vrot": _rng.randf_range(-9.0, 9.0),
                                "col": Color("edc22e"), "kind": "sq"})

# ============================================================ fx

func _part_col(v: int) -> Color:
        match _theme_id():
                "minecraft":
                        return MC_TIERS.get(v, Color("8a8f96"))
                "sea":
                        return Color(0.45, 0.75, 0.98)
        return CLASSIC_TILE.get(v, Color("8a7a66"))

func _spawn_merge_parts(at: Vector2, col: Color, n: int) -> void:
        for i in n:
                parts.append({"x": at.x + _rng.randf_range(-cell * 0.2, cell * 0.2),
                                "y": at.y + _rng.randf_range(-cell * 0.2, cell * 0.2),
                                "vx": _rng.randf_range(-300.0, 300.0),
                                "vy": _rng.randf_range(-380.0, 30.0),
                                "life": _rng.randf_range(0.45, 0.85), "max": 0.85,
                                "size": _rng.randf_range(cell * 0.045, cell * 0.10),
                                "rot": _rng.randf_range(-0.4, 0.4),
                                "vrot": _rng.randf_range(-10.0, 10.0),
                                "col": col, "kind": "sq"})
        if parts.size() > 260:
                parts = parts.slice(parts.size() - 260)

func _update_fx(delta: float) -> void:
        # the chunks have REAL collisions: they bounce off the board frame
        # (the PGB pymunk spirit, without the physics engine)
        var inner := board_rect.grow(gap * 0.5)
        for p in parts.duplicate():
                p["life"] = float(p["life"]) - delta
                p["x"] = float(p["x"]) + float(p["vx"]) * delta
                p["y"] = float(p["y"]) + float(p["vy"]) * delta
                p["vy"] = float(p["vy"]) + 1350.0 * delta
                p["rot"] = float(p["rot"]) + float(p["vrot"]) * delta
                if p["x"] < inner.position.x:
                        p["x"] = inner.position.x
                        p["vx"] = absf(float(p["vx"])) * 0.55
                elif p["x"] > inner.end.x:
                        p["x"] = inner.end.x
                        p["vx"] = -absf(float(p["vx"])) * 0.55
                if p["y"] > inner.end.y:
                        p["y"] = inner.end.y
                        p["vy"] = -absf(float(p["vy"])) * 0.48
                        p["vx"] = float(p["vx"]) * 0.8
                if float(p["life"]) <= 0.0:
                        parts.erase(p)
        for p in pops.duplicate():
                p["life"] = float(p["life"]) - delta
                p["y"] = float(p["y"]) - 46.0 * delta
                if float(p["life"]) <= 0.0:
                        pops.erase(p)
        for s in sparkles.duplicate():
                s["life"] = float(s["life"]) - delta
                if float(s["life"]) <= 0.0:
                        sparkles.erase(s)
        coin_t += delta
        fx_layer.queue_redraw()

func _pulse_board(at: Vector2, v: int) -> void:
        # the golden board pulse for the big tiles (the PGB board-glow law)
        var col := Color("edc22e") if _theme_id() == "classic" else _part_col(v)
        sparkles.append({"x": at.x, "y": at.y, "life": 0.5, "max": 0.5, "big": true,
                        "col": col})

func _draw_fx() -> void:
        var font := ThemeDB.fallback_font
        for p in parts:
                var a: float = clampf(float(p["life"]) / float(p["max"]), 0.0, 1.0)
                var col: Color = p["col"]
                col.a = minf(col.a, 1.0) * a
                fx_layer.draw_set_transform(Vector2(float(p["x"]), float(p["y"])),
                                float(p["rot"]), Vector2.ONE)
                var s: float = float(p["size"])
                fx_layer.draw_rect(Rect2(-s * 0.5, -s * 0.5, s, s), col)
                fx_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        for pp in pops:
                var pa: float = clampf(float(pp["life"]) / 0.7, 0.0, 1.0)
                fx_layer.draw_string(font, Vector2(float(pp["x"]) - cell * 0.5, float(pp["y"])),
                                String(pp["txt"]), HORIZONTAL_ALIGNMENT_CENTER, cell,
                                int(cell * 0.24), Color(1, 1, 1, pa))
        for s in sparkles:
                var sa: float = clampf(float(s["life"]) / float(s["max"]), 0.0, 1.0)
                var rr: float = cell * (0.3 + 0.55 * (1.0 - sa)) if s.has("big") \
                                else cell * 0.5 * (1.2 - sa * 0.5)
                var col: Color = s.get("col", Color(1.0, 0.85, 0.3))
                col.a = sa * 0.8
                fx_layer.draw_arc(Vector2(float(s["x"]), float(s["y"])), rr, 0.0, TAU, 26, col, 3.0)

## the GOGACoin cell (the owner: "make the GOGACoin appear like the other
## games, but with fade effect") - the REAL coin.png, fading in, breathing,
## glinting, sitting in an EMPTY cell until a tile slides onto it.
func _draw_coin_cell() -> void:
        if coin_cell.x < 0:
                return
        var tex: Texture2D = load("res://assets/ui/coin.png")
        if tex == null:
                return
        var pos := _cell_pos(coin_cell)
        pos.y += sin(coin_t * 3.4) * cell * 0.04
        var fade: float = clampf(coin_t / 0.35, 0.0, 1.0)
        coin_layer.draw_circle(pos, cell * 0.42, Color(1.0, 0.85, 0.3, 0.12 * fade))
        var s: float = cell * 0.62 / float(tex.get_width())
        var pop: float = 1.0 + 0.08 * sin(coin_t * 4.6)
        coin_layer.draw_set_transform(pos, 0.0, Vector2(s * pop * fade, s / maxf(0.05, pop) * fade))
        coin_layer.draw_texture(tex, -Vector2(tex.get_width(), tex.get_height()) / 2.0,
                        Color(1, 1, 1, fade))
        coin_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        # the glint sweeps around the coin so it reads as TAKE ME
        var ga: float = coin_t * 2.4
        coin_layer.draw_arc(pos, cell * 0.36, ga, ga + 1.1, 32,
                        Color(1, 1, 1, 0.55 * fade), 2.4)

# ============================================================ tick / input

func _goga_tick(delta: float) -> void:
        _time += delta
        var theme := _theme_id()
        if theme == "sea":
                # THE REAL MOTION WATER (v0.2.8): every tile's surface is a
                # damped spring. The ONLY force is the tile's ACTUAL
                # acceleration, measured from its real position deltas -
                # a slide's ease, a merge pop, nothing else. No motion =
                # no force = the water sits calm (the owner: the old
                # direction-fed wave was "unreal").
                _sea_time += delta
                for t in tiles.values():
                        if not (t is TileNode):
                                continue
                        if t.last_pos == Vector2.INF:
                                t.last_pos = t.position      # born this frame
                        var rel: float = (t.position.x - t.last_pos.x) / maxf(delta, 0.0001)
                        t.last_pos = t.position
                        var acc: float = (rel - t.last_vel) / maxf(delta, 0.0001)
                        t.last_vel = rel
                        acc = clampf(acc, -W_ACC_MAX, W_ACC_MAX)
                        t.acc_s = lerpf(t.acc_s, acc, 0.5)
                        # the spring: natural frequency ~1.1 Hz, a few swings,
                        # then calm (W_K / W_C / W_ACC_K in the consts)
                        t.w_vel += (-W_K * t.w_off - W_C * t.w_vel
                                        - W_ACC_K * t.acc_s) * delta
                        t.w_off += t.w_vel * delta
                        t.w_off = clampf(t.w_off, -0.85, 0.85)
                        t.w_energy = maxf(t.w_energy - delta * 2.1,
                                        minf(absf(t.w_vel) * 0.55 + absf(t.w_off), 1.2))
                        if t.mat != null:
                                t.mat.set_shader_parameter("time_s", _sea_time)
                                t.mat.set_shader_parameter("tilt", float(t.w_off))
                                t.mat.set_shader_parameter("energy", float(t.w_energy))
                bg_layer.queue_redraw()          # the caustics drift
                coin_layer.queue_redraw()        # the coin breathes AND erases
        elif theme == "minecraft":
                # the lava tiles breathe + occasionally throw an ember
                for t in tiles.values():
                        if t is TileNode and t.value >= 128:
                                t.queue_redraw()
                                if _rng.randf() < 1.4 * delta:
                                        parts.append({"x": t.position.x + _rng.randf_range(-cell * 0.3, cell * 0.3),
                                                        "y": t.position.y - cell * 0.4,
                                                        "vx": _rng.randf_range(-24.0, 24.0),
                                                        "vy": _rng.randf_range(-130.0, -60.0),
                                                        "life": _rng.randf_range(0.5, 0.9), "max": 0.9,
                                                        "size": _rng.randf_range(cell * 0.03, cell * 0.06),
                                                        "rot": 0.0, "vrot": _rng.randf_range(-4.0, 4.0),
                                                        "col": Color(1.0, 0.6, 0.12), "kind": "sq"})
                bg_layer.queue_redraw()
        else:
                bg_layer.queue_redraw()          # the classic dust drifts
        coin_layer.queue_redraw()        # ALWAYS: spawn, bob, glint, ERASE
        _update_fx(delta)

func _goga_input(_event: InputEvent) -> void:
        pass   # the swipes arrive through tk.swiped

## swipe ANY direction moves the board (the owner's control law). A board
## nudge sells the hit; a deny wobble sells the wall.
func _on_swipe(dirv: Vector2i, _pos: Vector2) -> void:
        if over or paused or animating or over_board:
                return
        var moved := _slide(dirv)
        if not moved:
                var tw := create_tween()
                tw.tween_property(board_root, "position",
                                Vector2(float(dirv.x), float(dirv.y)) * 4.0, 0.04)
                tw.tween_property(board_root, "position", Vector2.ZERO, 0.09)
                return
        animating = true
        Jukebox.sfx(_slide_sfx(), -14.0, 1.0 + _rng.randf() * 0.06)
        var nudge := Vector2(float(dirv.x), float(dirv.y)) * 5.0
        var tw2 := board_root.create_tween()
        tw2.tween_property(board_root, "position", nudge, 0.045)
        tw2.tween_property(board_root, "position", Vector2.ZERO, 0.07)
        await get_tree().create_timer(SLIDE_TIME + 0.02).timeout
        _finish_slide()
        animating = false

# ============================================================ the sounds
## the themes sound different (the owner: "different SFXs and VFXs too")

func _slide_sfx() -> String:
        match _theme_id():
                "minecraft":
                        return "m_thud"
                "sea":
                        return "m_slosh"
        return "m_slide"

func _merge_sfx(v: int) -> String:
        match _theme_id():
                "minecraft":
                        return "m_lava" if v >= 128 else "m_stone"
                "sea":
                        return "m_splash"
        return "m_pop"

# ============================================================ the shop
## Same bones as the tower shop (THE PAIR LAW - the sheet owns its exact
## dim+center pair). One shelf: THEMES.

func _shop_open() -> void:
        _shop_pair_down()
        var root := _overlay_root_ref()
        var sheet := Arc.sheet(root, 0.0)
        sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
        var kids := root.get_children()
        _shop_pair = [kids[kids.size() - 2], kids[kids.size() - 1]]
        var t := Arc.label("2048 SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 300.0, 640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        box.add_child(_shop_label("THEMES - a whole new feel, sounds included"))
        for id in THEMES:
                box.add_child(_theme_row(id))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): _shop_close()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _shop_label(txt: String) -> Label:
        return Arc.fit_label(txt, 24, Arc.HOT, 560)

func _theme_row(id: String) -> Control:
        var th: Dictionary = THEMES[id]
        var owned := Box.item_owned(game_id, "theme", id) or _theme_price(id) == 0
        var on := _theme_id() == id \
                        or (_theme_price(id) == 0 and Box.item_on(game_id, "theme") == "")
        # the name + desc live on a WRAPPED label line (long descs never fit a
        # single sheet line - the v0.2.7 QA eyeball caught the clip)
        var head := Arc.label("%s%s - %s" % [th["name"], "  (ON)" if on else "",
                        th["desc"]], 19,
                        Color("58c470") if on else Arc.INK, false)
        head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        head.custom_minimum_size = Vector2(560, 0)
        head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 2)
        v.add_child(head)
        if on:
                return v
        if owned:
                v.add_child(Arc.button("EQUIP", Vector2(560, 56), 22,
                                Color("4a5ab8"), func():
                                                Box.equip_item(game_id, "theme", id)
                                                Jukebox.sfx("confirm", -4.0)
                                                _apply_theme()
                                                _shop_open()))
                return v
        var b := Arc.coin_button("BUY  %d" % _theme_price(id),
                        Vector2(560, 56), 22, Color("4a5ab8"), func():
                                        if Box.buy_item(game_id, "theme", id, _theme_price(id)):
                                                Jukebox.sfx("buy")
                                                _apply_theme()
                                        _shop_open())
        if Box.coins() < _theme_price(id):
                b.disabled = true
        v.add_child(b)
        return v

func _shop_pair_down() -> void:
        for n in _shop_pair:
                if n != null and is_instance_valid(n):
                        n.queue_free()
        _shop_pair = []

func _shop_close() -> void:
        _shop_pair_down()

## a theme change repaints EVERYTHING: the backdrop, the frame, the holes
## and every living tile (water materials in, pixel blocks out, and back)
func _apply_theme() -> void:
        bg_layer.queue_redraw()
        board_layer.queue_redraw()
        for c in tiles:
                var t: TileNode = tiles[c]
                if is_instance_valid(t):
                        t.setup(t.value, self, cell)
        coin_layer.queue_redraw()

# ============================================================ the options
## THE BOARD SIZES (owner v0.2.8): "add an options menu shows 4x4 normal
## and 6x6 and 8x8, make the others be bought first for high prices, make
## 6x6 score bonus be /80 and 8x8 /160". Same sheet bones as the shop
## (THE PAIR LAW - its own exact dim+center pair). Equipping a different
## size starts a FRESH board with that size.

func _options_open() -> void:
        _options_pair_down()
        var root := _overlay_root_ref()
        var sheet := Arc.sheet(root, 0.0)
        sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
        var kids := root.get_children()
        _options_pair = [kids[kids.size() - 2], kids[kids.size() - 1]]
        var t := Arc.label("2048 OPTIONS", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var hint := Arc.fit_label("a bigger board holds a bigger game - "
                + "switching starts a fresh board", 19, Arc.HOT, 560)
        hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(hint)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.46, 260.0, 540.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        for id in SIZES:
                box.add_child(_size_row(id))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): _options_close()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _size_row(id: String) -> Control:
        var sz: Dictionary = SIZES[id]
        var owned := Box.item_owned(game_id, "size", id) or int(sz["price"]) == 0
        var on := size_id == id
        var head := Arc.label("%s%s - %s" % [sz["name"], "  (ON)" if on else "",
                        sz["desc"]], 19,
                        Color("58c470") if on else Arc.INK, false)
        head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        head.custom_minimum_size = Vector2(560, 0)
        head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 2)
        v.add_child(head)
        if on:
                return v
        if owned:
                # THE ARE-YOU-SURE LAW (v0.3.3-p1, the owner): changing the
                # grid size wipes the run - it asks first now
                v.add_child(Arc.button("SWITCH", Vector2(560, 56), 22,
                                Color("4a5ab8"), func(): _size_confirm(id, false)))
                return v
        var b := Arc.coin_button("BUY  %d" % int(sz["price"]),
                        Vector2(560, 56), 22, Color("4a5ab8"), func():
                                        if Box.buy_item(game_id, "size", id, int(sz["price"])):
                                                Jukebox.sfx("buy")
                                                _size_confirm(id, true)
                                        else:
                                                _options_open())
        if Box.coins() < int(sz["price"]):
                b.disabled = true
        v.add_child(b)
        return v

## THE ARE-YOU-SURE SHEET (v0.3.3-p1): YES applies the new board (the run
## starts fresh), NO walks back - a bought size that is refused re-equips
## the old one so the store and the board always tell the same truth.
func _size_confirm(id: String, bought: bool) -> void:
        _confirm_pair_down()
        var root := _overlay_root_ref()
        var sheet := Arc.sheet(root, 0.0)
        sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
        var kids := root.get_children()
        _confirm_pair = [kids[kids.size() - 2], kids[kids.size() - 1]]
        var sz: Dictionary = SIZES[id]
        var t := Arc.label("SWITCH TO %s?" % String(sz["name"]).to_upper(), 32, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var w := Arc.fit_label("switching starts a fresh board -\nthe current run is wiped",
                        22, Arc.HOT, 560)
        w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(w)
        sheet.add_child(Arc.button("YES - SWITCH", Vector2(560, 84), 28, Arc.GOOD, func():
                        _confirm_pair_down()
                        Box.equip_item(game_id, "size", id)
                        Jukebox.sfx("confirm", -4.0)
                        _apply_size(id)
                        _options_open()))
        sheet.add_child(Arc.button("NO", Vector2(560, 74), 26, Arc.BAD, func():
                        _confirm_pair_down()
                        if bought:
                                Box.equip_item(game_id, "size", size_id)
                        _options_open()))


func _confirm_pair_down() -> void:
        for n in _confirm_pair:
                if n != null and is_instance_valid(n):
                        n.queue_free()
        _confirm_pair = []


func _options_pair_down() -> void:
        for n in _options_pair:
                if n != null and is_instance_valid(n):
                        n.queue_free()
        _options_pair = []

func _options_close() -> void:
        _options_pair_down()
