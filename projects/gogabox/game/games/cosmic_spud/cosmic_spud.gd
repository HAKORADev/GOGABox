extends GogaGame
## COSMIC SPUD (v0.3.4-4) - the Brotato-competitor, PATCH 4.
## THE GDD: docs/goga_docs/gogames_ideas/cosmic_spud.md + cosmic_spud_patch4.md.
## PATCH 4 LAWS (the owner's played-again report):
##   THE NO-SHOOT-VFX LAW: every shooting flicker/light is DEAD - the muzzle
##   flash, the wobbly aim laser. The gun speaks through its sound alone.
##   THE UNIVERSAL WIDGET LAW: the HUD GOGACoins widget IS the universal
##   Arc.chip + coin.png every game wears - and it counts the coins
##   COLLECTED THIS RUN (starts 0), never the wallet total.
##   THE SHOP LIST LAW: the HUD SHOP button opens THE SHOP - the universal
##   GOGACoins LIST (the invaders/matcher shape): THE PLACES, THE GUNS
##   (they join every wave market), THE LAB (the merging, learned forever),
##   THE CREW (they join the deploy list). The cosmic-coin store is THE
##   ARMORY again; the wave market stays the break's own flow.
##   THE COIN-ICON PRICE LAW: a GOGACoins price is NEVER spelled out - the
##   label + THE coin icon (optionals theme cards, the armory themes tab).
##   THE HONEST METERS LAW: the HP/XP/wave/boss fills are custom-drawn plain
##   Controls (a Container resets a child's manual size whenever a sibling's
##   minimum size changes - the probe-proven root cause of the dead meters).
##   HP moves for each HP with a continuous green->yellow->red; the XP bar
##   shows the true run_xp / xp-needed ratio and animates both ways.
## PATCH 3 LAWS:
##   THE HUD LAW: the empty chrome chips are GONE - the game wears its own
##   SCORE, KILLS, COSMIC COINS and GOGACoins widgets (black boxes).
##   THE SILENCE LAW: the gogacoin never announces itself - no banners, no
##   CARRIER! chip, no fanfare sfx. Silent is cool.
##   THE SHARED CONTACT LAW: colliding damages BOTH sides - the enemy's
##   attack hurts you, your potato RAMS it back - and EVERY contact tick
##   speaks (sfx + numbers + dust). No more silent grinding.
##   THE BREAK CHAIN: draft -> THE WAVE MARKET (items/weapons/allies, the
##   5-slot HOLD DECK, the reroll lives HERE only) -> THE MERGE BENCH (its
##   own menu) -> THE STATS MENU (level-up points, costs 1-3) -> THE SKILLS
##   MENU (1 point per 100 kills, ten unique skills) -> next wave.
##   THE WOW PASS: camera shake, the low-HP vignette, pickup sparkles.

const ARENA := Rect2(0, 0, 2400, 1350)
const ARENA_MARGIN := 90.0        # the ground paints past the bounds
const PLAYER_SPD := 210.0
const PLAYER_R := 22.0
const STICK_DEAD := 8.0
const STICK_MAX := 70.0
const IFRAME := 0.6
const MAGNET_BASE := 150.0
const CONTACT_KNOCK := 190.0    # v0.3.8-3: the ram shoves the body away
                                # (px/s, decays - the stalemate killer)

# ===================================================== THE GAME'S OWN COLORS
## the owner's design language: a gray field, BLACK inner boxes, text in
## white/green/red/blue/yellow only.
const CS_BG := Color(0.41, 0.42, 0.44)          # the gray field
const CS_BOX := Color(0.05, 0.05, 0.065)        # the black inner boxes
const CS_BOX2 := Color(0.1, 0.1, 0.12)          # the lighter black (hover)
const CS_EDGE := Color(0.18, 0.18, 0.21)        # the box edges
const CS_WHITE := Color(0.93, 0.94, 0.95)
const CS_GREEN := Color(0.44, 0.88, 0.5)
const CS_RED := Color(0.96, 0.38, 0.35)
const CS_BLUE := Color(0.46, 0.68, 1.0)
const CS_YELLOW := Color(1.0, 0.83, 0.3)

var meta: CSMeta
var world: Node2D
var ground_layer: Node2D         # the repaintable dress (grounds + props)
var fx: Node2D                   # the _draw overlay (rings, auras, beams)
var cam: Camera2D

var phase := "boot"               # boot | play | break | dead
var _boot_hint := ""              # the door speaks here (THE BACK LAW)
var theme_id := "desert"
var night := false
var start_id := "soldier"

# the run's numbers
var run_wave := 1
var wave_clock := 0.0
var wave_spawning := true
var run_xp := 0
var run_level := 1
var run_ccoins := 0               # in-run cosmic coins (bank at the end)
var run_kills := 0
var run_merges := 0
var pending_levels := 0
var second_wind_used := false
var boss_alive := false

# the player
var p_pos := Vector2(1200, 675)
var p_hp := 100.0
var p_max_hp := 100.0
var p_aim := 0.0
var p_iframe := 0.0
var p_walk := 0.0
var p_node: Sprite2D
var stats := {}                   # the live stat block (see _base_stats)
# THE INFO LAW (v0.3.4-5): the run's stat truth - the base snapshot + the
# up/down ledgers every delta files into (see _apply_stat)
var stat_base := {}
var stat_up := {}
var stat_down := {}

# the entities
var enemies: Array = []
var bullets: Array = []
var ebullets: Array = []
var pickups: Array = []
var allies: Array = []
var props: Array = []             # [{c: Vector2, r: float}] the solid decor
var zones: Array = []             # gravity wells / telegraphs
var weapons_run: Array = []       # [{id, tier, cd}]

# the stick (TRULY invisible - no ghost node exists at all)
var stick_active := false
var stick_origin := Vector2.ZERO
var stick_vec := Vector2.ZERO

# THE GOGACOIN RIDER (every 5th wave) - THE SILENCE LAW: it glints, it
# drops, it pays. Nothing announces it, ever.
var goga_pending := false         # the wave owes a coin carrier
var goga_carry := false           # a living carrier rolled into the next wave
var goga_carrier_alive := false

# THE SHOP's live state (the offers roll once per break)
var shop_offers_w: Array = []     # [{wid, tier, rar, price, sold, held}]
var shop_offers_i: Array = []     # [{iid, rar, price, sold, held}]
var shop_rerolls := 0
var shop_free_reroll := false     # u3 FATE REROLL: one free market shuffle
var market_tab := "items"         # the wave market's tab
var _break_in_market := false     # the break chain is inside the market

# hud widgets (all CS-styled)
# v0.3.4-4 THE HONEST METERS LAW: the fills are NO LONGER ColorRects inside
# PanelContainers - a Container resets a child's manual size whenever a
# sibling's minimum size changes (probe-proven: 298 -> 100 -> 298), which is
# exactly what the HP bar's own number label did to its fill every frame.
# Every meter is now a custom-drawn plain Control no container can touch.
var hp_meter: Control
var hp_txt: Label
var arm_txt: Label
var xp_meter: Control
var sp_meter: Control        # v0.3.8-3 THE SKILL POINT METER (the owner's
                             # item 2: "there is no skill points meter... do
                             # another meter for the skill points so user
                             # knows when the point will come")
var sp_txt: Label
var lvl_txt: Label
var wave_txt: Label
var wave_meter: Control
var kill_txt: Label               # the KILLS widget (the owner's two)
var score_txt: Label              # the SCORE widget (the owner's two)
var cc_txt: Label                 # the cosmic coins widget
var gg_txt: Label                 # the GOGACoins widget - the UNIVERSAL chip,
                                  # counting the coins COLLECTED THIS RUN
var boss_bar: Control
var boss_meter: Control
var boss_txt: Label
# the displayed (animated) ratios - the meters MOVE toward their truth
var _hp_disp := 1.0
var _xp_disp := 0.0
var _sp_disp := 0.0
var _wave_disp := 0.0
var _boss_disp := 1.0
var slot_row: HBoxContainer
var _slot_widgets: Array = []     # [{box, cd, tier_txt}]
var _tex: Dictionary = {}
var _hud_built := false

# THE WOW PASS
var _shake := 0.0                 # the camera shake energy (decays)

# THE SKILLS (the meta perks, wired in the run)
var p_shield_up := false          # SHATTERED SHIELD: one hit, then gone
var p_shield_cd := 0.0            # the reform timer (the level's reform law)
var p_shield_charges := 0         # v0.3.8-2: L5 wears TWO charges
var _static_cd := 0.0             # STATIC BURST clock
var _adrenaline := 0.0            # ADRENALINE ROOT burst timer

# ================================================================ textures
func _t(key: String) -> Texture2D:
        if not _tex.has(key):
                var base := "res://assets/games/cosmic_spud/"
                var paths := {
                        "xp": base + "pickups/xp.png", "coin": base + "pickups/coin.png",
                        "heart": base + "pickups/heart.png",
                        "gogacoin": "res://assets/ui/coin.png",
                        "rock": base + "props/rock.png", "skull": base + "props/skull.png",
                        "crate": base + "props/crate.png", "barrel": base + "props/barrel.png",
                        "tree": base + "props/tree.png", "bench": base + "props/bench.png",
                        "fence": base + "props/fence.png", "shrub": base + "props/shrub.png",
                        "ferris": base + "props/ferris.png",
                        "crystal1": base + "props/crystal_1.png",
                        "crystal2": base + "props/crystal_2.png",
                        "crystal3": base + "props/crystal_3.png",
                        "circle": base + "fx/circle.png", "circle_soft": base + "fx/circle_soft.png",
                        "smoke": base + "fx/smoke.png", "star": base + "fx/star.png",
                        "flare": base + "fx/flare.png", "light": base + "fx/light.png",
                        "muzzle": base + "fx/muzzle.png", "dirt": base + "fx/dirt.png",
                        "fire": base + "fx/fire.png", "flame": base + "fx/flame.png",
                }
                for sid in CSData.START_ORDER:
                        for k in 4:
                                paths["hero_" + sid + "_f" + str(k)] = \
                                                base + "hero/hero_" + sid + "_f" + str(k) + ".png"
                for eid in CSData.ENEMIES:
                        paths[String(CSData.ENEMIES[eid]["tex"])] = \
                                        base + "enemies/" + String(CSData.ENEMIES[eid]["tex"]) + ".png"
                for bid in CSData.BOSSES:
                        paths[String(CSData.BOSSES[bid]["tex"])] = \
                                        base + "enemies/" + String(CSData.BOSSES[bid]["tex"]) + ".png"
                for wid in CSData.WEAPON_ORDER:
                        paths["icon_" + wid] = base + "weapons/icon_" + wid + ".png"
                        paths["gun_" + wid] = base + "weapons/gun_" + wid + ".png"
                for proj in ["bolt", "pellet", "slug", "lance", "bomb", "shard",
                                "rail", "spit", "orb", "boomerang", "tracer",
                                "bottle"]:
                        paths["proj_" + proj] = base + "bullets/" + proj + ".png"
                # v0.3.5-5 THE ALLY TRUTH (the crash law): the allies wore tex
                # keys that were NEVER registered here - the engineer's drop-in
                # deploy hit `_t("orbiter")` and the missing dictionary key
                # killed the run before the first wave (the owner: "selecting
                # the engineer and tap drop-in makes the app crash"). Every
                # ally texture registers now; the art lives with the enemies'
                # sheets it was recomposed from.
                # v0.3.8-4 THE WALK FRAMES: each ally wears the hero's own
                # 4-frame waddle (ally_<id>_f0..f3, the v038p4 potato crew)
                for aid in CSData.ALLY_ORDER:
                        paths[String(CSData.ALLIES[aid]["tex"])] = \
                                        base + "allies/" + String(CSData.ALLIES[aid]["tex"]) + ".png"
                        for k in 4:
                                paths["ally_%s_f%d" % [aid, k]] = \
                                                base + "allies/ally_%s_f%d.png" % [aid, k]
                _tex[key] = load(paths[key])
        return _tex[key]

# ===================================================== THE CSUI (the kit)
## the game's own UI kit. NOTHING here touches the box's ui_kit.
## THE BIG TEXT LAW (v0.3.4-5, the owner: "the game overall text is too small,
## it needs to get like 75% bigger with proper UI handling"): ONE multiplier
## feeds every CSUI helper - the text grows, the buttons grow with it, and
## the TEXT-FIT measurements stay truthful (they scale through the same door).
const FS := 1.75

func _fs(sz: int) -> int:
        return maxi(8, int(round(float(sz) * FS)))

func _cs_box_style(edge := CS_EDGE, bg := CS_BOX) -> StyleBoxFlat:
        var st := StyleBoxFlat.new()
        st.bg_color = bg
        st.border_color = edge
        st.set_border_width_all(2)
        st.corner_radius_top_left = 8
        st.corner_radius_top_right = 8
        st.corner_radius_bottom_left = 8
        st.corner_radius_bottom_right = 8
        st.content_margin_left = 8
        st.content_margin_right = 8
        st.content_margin_top = 6
        st.content_margin_bottom = 6
        return st

func _cs_panel_style() -> StyleBoxFlat:
        # the gray FIELD the boxes sit on
        var st := StyleBoxFlat.new()
        st.bg_color = CS_BG
        st.border_color = CS_EDGE
        st.set_border_width_all(2)
        st.corner_radius_top_left = 12
        st.corner_radius_top_right = 12
        st.corner_radius_bottom_left = 12
        st.corner_radius_bottom_right = 12
        st.content_margin_left = 10
        st.content_margin_right = 10
        st.content_margin_top = 8
        st.content_margin_bottom = 10
        return st

## THE CS FONT (v0.3.4-2): the game wears Kenney_Mini explicitly - the CSUI
## measures what it renders, so the font must be a FACT, not a fallback.
var _font_cs: Font = null

func _cs_font() -> Font:
        if _font_cs == null:
                _font_cs = load("res://assets/fonts/Kenney_Mini.ttf")
        return _font_cs

## THE TEXT-FIT LAW (v0.3.4-2, the owner: "the text is out-of-box, make the
## box dynamically fit the text"): no CSUI box may GUESS its size. Measure
## the real string with the real font, then size the box to the measurement.
func _cs_text_w(txt: String, sz: int) -> float:
        return _cs_font().get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(sz)).x

func _cs_text_h(txt: String, sz: int, w: float) -> float:
        return _cs_font().get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT,
                        w, _fs(sz), -1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
                        | TextServer.BREAK_ADAPTIVE).y

## a label that steps its own font size down until it fits max_w
func _cs_fit_label(txt: String, sz: int, col: Color, max_w: float,
                min_sz := 8) -> Label:
        var s := sz
        while s > min_sz and _cs_text_w(txt, s) > max_w:
                s -= 1
        return _cs_label(txt, s, col)

## THE HUG LAW (v0.3.4-2): a sheet's scroll area HUGS its content - a tall
## empty gray void under three cards is slop. The scroll grows to the shelf's
## measured minimum, capped at the viewport fraction so big shelves still scroll.
## v0.3.4-3: the SECOND PASS - autowrap labels only know their real wrapped
## height one frame after layout, so the hug re-fits then (the measured
## ghost void under the market/stats/skills shelves is dead).
func _fit_scroll(scroll: ScrollContainer, shelf: Control, frac: float) -> void:
        var cap: float = get_viewport_rect().size.y * frac
        scroll.custom_minimum_size.y = clampf(
                        shelf.get_combined_minimum_size().y + 8.0, 120.0, cap)
        _fit_scroll_second_pass(scroll, shelf, cap)

func _fit_scroll_second_pass(scroll: ScrollContainer, shelf: Control,
                cap: float) -> void:
        await get_tree().process_frame
        if scroll == null or not is_instance_valid(scroll) \
                        or shelf == null or not is_instance_valid(shelf):
                return
        scroll.custom_minimum_size.y = clampf(
                        shelf.get_combined_minimum_size().y + 8.0, 120.0, cap)

# ==========================================================================
# v0.3.8-2 THE SCROLL TRUTH (the owner: "in shop, if i tried to scroll while
# from a button, ummm, it prevents me, make it scrollable like the other
# games"): every CS sheet shelf scrolls on the box's own BoxScroll now - the
# raw-touch scroll the menu/info wear (the info sheet had it since v0.3.5-1;
# the other sheets kept the plain ScrollContainer whose emulated-mouse drag
# died the moment the finger landed ON a button). BoxScroll scrolls from raw
# ScreenTouch/ScreenDrag that ALWAYS fire, even over buttons, and dispatches
# taps itself - so every Button inside goes mouse_filter IGNORE and registers
# as a tappable (the emitter honors `disabled`: SOLD/NEED/MAXED never fire).
func _cs_scroll() -> BoxScroll:
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.process_mode = Node.PROCESS_MODE_ALWAYS
        sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
        return sc

func _cs_shelf(sc: BoxScroll) -> VBoxContainer:
        var shelf := VBoxContainer.new()
        shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        shelf.add_theme_constant_override("separation", 6)
        sc.add_child(shelf)
        return shelf

func _cs_scroll_taps(sc: BoxScroll) -> void:
        var stack := [sc]
        while not stack.is_empty():
                var n: Node = stack.pop_back()
                if n is BaseButton:
                        var b := n as BaseButton
                        b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        sc.register_tappable(b, func():
                                if b.disabled:
                                        return
                                b.pressed.emit())
                for c in n.get_children():
                        stack.append(c)

func _cs_label(txt: String, sz: int, col: Color, parent: Node = null) -> Label:
        var l := Label.new()
        l.text = txt
        l.add_theme_font_override("font", _cs_font())
        l.add_theme_font_size_override("font_size", _fs(sz))
        l.add_theme_color_override("font_color", col)
        if parent != null:
                parent.add_child(l)
        return l

## v0.3.8-4 THE OUTLINE LAW (the owner: "update the XP meter text and
## skills meter to have black out lines, for better contrast"): every HUD
## label that floats over the field wears a black rim - the read never
## depends on what the arena paints under it.
func _cs_outline(l: Label, px := 4) -> void:
        l.add_theme_constant_override("outline_size", _fs(px))
        l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))

func _cs_button(txt: String, sz: int, col: Color, cb: Callable) -> Button:
        var b := Button.new()
        b.text = txt
        b.add_theme_font_override("font", _cs_font())
        b.add_theme_font_size_override("font_size", _fs(sz))
        b.add_theme_color_override("font_color", col)
        b.add_theme_color_override("font_hover_color", col.lightened(0.25))
        b.add_theme_color_override("font_pressed_color", col.darkened(0.2))
        b.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.58))
        b.add_theme_stylebox_override("normal", _cs_box_style())
        var hov := _cs_box_style(CS_EDGE, CS_BOX2)
        b.add_theme_stylebox_override("hover", hov)
        var pr := _cs_box_style(CS_YELLOW.darkened(0.2), CS_BOX)
        b.add_theme_stylebox_override("pressed", pr)
        var dis := _cs_box_style(Color(0.13, 0.13, 0.15), Color(0.08, 0.08, 0.09))
        b.add_theme_stylebox_override("disabled", dis)
        b.pressed.connect(cb)
        return b

## v0.3.4-4 THE COIN-ICON PRICE LAW (the owner: "when the theme not bought,
## it says buy nn GOGACOINS, instead of gogacoins, it should show the coin
## icon because this is how the design is"): a GOGACoins price is NEVER
## spelled out in words - the label + THE coin.png icon, the universal
## Arc.coin_button design wearing the CS face.
func _cs_coin_button(txt: String, sz: int, col: Color, cb: Callable) -> Button:
        var b := _cs_button("", sz, col, cb)
        var h := HBoxContainer.new()
        h.set_anchors_preset(Control.PRESET_FULL_RECT)
        h.alignment = BoxContainer.ALIGNMENT_CENTER
        h.add_theme_constant_override("separation", 8)
        h.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var l := _cs_label(txt, sz, col)
        h.add_child(l)
        var c := TextureRect.new()
        c.texture = load("res://assets/ui/coin.png")
        c.custom_minimum_size = Vector2(_fs(sz) + 10, _fs(sz) + 10)
        c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        c.mouse_filter = Control.MOUSE_FILTER_IGNORE
        h.add_child(c)
        b.add_child(h)
        return b

func _cs_black_box(parent: Node, min_size: Vector2) -> PanelContainer:
        var p := PanelContainer.new()
        p.add_theme_stylebox_override("panel", _cs_box_style())
        p.custom_minimum_size = min_size
        parent.add_child(p)
        return p

func _cs_title_bar(box: VBoxContainer, title: String, col: Color) -> void:
        var bar := _cs_black_box(box, Vector2(0, 40))
        var h := HBoxContainer.new()
        bar.add_child(h)
        var t := _cs_label(title, 20, col)
        t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        h.add_child(t)

# ============================================== THE CS SHEETS (the stack)
## the game's own modal system - a dim + a gray panel wearing black boxes.
## The base game sheets are NOT used for this game's screens anymore.
var cs_sheets: Array = []         # [{dim, panel, box, id}]

func sheet_open_count() -> int:
        return cs_sheets.size()

func _cs_open(title: String, build: Callable, col: Color = CS_YELLOW,
                closable := true, id := "cs") -> VBoxContainer:
        get_tree().paused = true
        paused = true
        var root := _overlay_root_ref()
        var vp := get_viewport_rect().size
        var dim := ColorRect.new()
        dim.color = Color(0, 0, 0, 0.52)
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        dim.mouse_filter = Control.MOUSE_FILTER_STOP
        ## THE SHEET LIFE LAW (v0.3.4-2 - THE owner-report killer): every CS
        ## sheet PAUSES the tree, and a paused tree eats every tap aimed at a
        ## PAUSABLE control - the NIGHT chip, DROP IN, THE ARMORY, the X, all
        ## dead on device while the same taps worked headless. The box's own
        ## sheet_push has dressed its chain PROCESS_MODE_ALWAYS since
        ## v0.3.3-p2; the CS kit now wears the same crown.
        dim.process_mode = Node.PROCESS_MODE_ALWAYS
        root.add_child(dim)
        var center := CenterContainer.new()
        center.set_anchors_preset(Control.PRESET_FULL_RECT)
        center.offset_top = 112.0   # the sheet clears the box's top bar
        center.mouse_filter = Control.MOUSE_FILTER_IGNORE
        dim.add_child(center)
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel", _cs_panel_style())
        panel.custom_minimum_size = Vector2(vp.x * 0.96, 0)   # the height hugs the content
        center.add_child(panel)
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 6)
        panel.add_child(box)
        # the title bar with the X
        var bar := PanelContainer.new()
        bar.add_theme_stylebox_override("panel", _cs_box_style(CS_EDGE, CS_BOX))
        box.add_child(bar)
        var bh := HBoxContainer.new()
        bar.add_child(bh)
        var tl := _cs_label(title, 19, col)
        tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        bh.add_child(tl)
        if closable:
                var x := _cs_button("X", 16, CS_RED, func(): _cs_close_top())
                bh.add_child(x)
        var sheet := {"dim": dim, "panel": panel, "box": box, "id": id,
                        "closable": closable}
        cs_sheets.append(sheet)
        build.call(box)
        return box

func _cs_close_top() -> void:
        if cs_sheets.is_empty():
                # THE RESUME LAW's self-heal: a stranded break (no sheet at
                # all) comes back to the market on the very next close/back
                _resume_break()
                return
        _cs_pop_top()
        if cs_sheets.is_empty():
                # THE RESUME LAW (v0.3.4-5): the X / CLOSE buttons carry the same
                # safety the Android back always had - a break that lost its
                # last sheet falls back to the market, never stranded.
                _resume_break()
        elif String(cs_sheets.back()["id"]) == "door":
                _door_reveal_refresh()
        Jukebox.sfx("ui_click", -10.0)

## the RAW pop: the break-chain steps use this (each step opens the next
## sheet itself - no resume, no door refresh, no double-opens)
func _cs_pop_top() -> void:
        if cs_sheets.is_empty():
                return
        var s: Dictionary = cs_sheets.pop_back()
        (s["dim"] as Control).queue_free()
        if cs_sheets.is_empty():
                get_tree().paused = false
                paused = false

## THE FRESH DOOR LAW (v0.3.4-5, the owner: "i bought the other theme and
## closed shop, the optionals menu still tells me to buy the place - it
## should get updated"): whenever a close reveals THE DOOR, the door
## rebuilds from LIVE state - a purchase under any sheet can never leave
## a stale card on it.
func _door_reveal_refresh() -> void:
        if phase != "boot" or cs_sheets.is_empty():
                return
        _cs_reopen(func(): _optionals_open())

func _cs_close_all() -> void:
        while not cs_sheets.is_empty():
                var s: Dictionary = cs_sheets.pop_back()
                (s["dim"] as Control).queue_free()
        get_tree().paused = false
        paused = false

## the old name lives on (the probe + any old callers)
func _close_all_sheets() -> void:
        _cs_close_all()

func _cs_reopen(build: Callable) -> void:
        # pop the top sheet and rebuild it (the live-state refresh)
        # v0.3.8-4 THE SCROLL SEAT LAW (the owner: "in the shop, if i buy
        # something from the bottom, the shop menu refreshes and returns me
        # to the top... make it just let me in my place while updating the
        # list normally"): the rebuild CAPTURES the old sheet's scroll
        # offset and seats the rebuilt one back at it (the pop-siege law).
        var want := -1
        if not cs_sheets.is_empty():
                var s: Dictionary = cs_sheets.pop_back()
                var old_sc := _cs_find_scroll(s["dim"])
                if old_sc != null:
                        want = int(old_sc.scroll_vertical)
                (s["dim"] as Control).queue_free()
                if cs_sheets.is_empty():
                        get_tree().paused = false
                        paused = false
        build.call()
        if want >= 0:
                _cs_restore_scroll(want)

func _cs_find_scroll(root: Node) -> BoxScroll:
        if root is BoxScroll:
                return root
        for c in root.get_children():
                var f := _cs_find_scroll(c)
                if f != null:
                        return f
        return null

func _cs_restore_scroll(want: int) -> void:
        # the offset only sticks once the rebuilt sheet has laid out twice
        await get_tree().process_frame
        await get_tree().process_frame
        if cs_sheets.is_empty():
                return
        var sc := _cs_find_scroll((cs_sheets.back() as Dictionary)["dim"])
        if sc != null:
                sc.scroll_vertical = want

## THE BACK LAW (v0.3.4-2 - THE DOOR): the HUD "<" and the Android back both
## land here. Over a RUNNING game a CS sheet closes first, else the box pause
## takes it (the same behavior as every other game). During the BOOT the
## optionals is THE DOOR - back may never close it (the owner: closing it
## froze the game with no way back in). An armory/tree sheet over the door
## closes and the door shows again; the door itself just speaks.
func _back_pressed() -> void:
        if phase == "boot":
                if cs_sheets.size() > 1:
                        _cs_close_top()
                elif not cs_sheets.is_empty():
                        _boot_hint = "the door is locked - pick a start, then DROP IN"
                        _cs_reopen(func(): _optionals_open())
                else:
                        _optionals_open()
                return
        if not cs_sheets.is_empty():
                _cs_close_top()
                # THE BREAK LAW (v0.3.4-3): a break that lost its sheet falls
                # back to the market - the chain can never strand the player
                _resume_break()
                return
        if phase == "break":
                _market_open()
                return
        super._back_pressed()

# ================================================================ setup
func _exit_tree() -> void:
        if meta != null and run_ccoins != meta.coins():
                _cc_sync()    # THE PURSE LAW: no exit without a checkpoint
        get_tree().paused = false     # THE UNFREEZE LAW

func _goga_setup() -> void:
        meta = CSMeta.load_meta()
        # v0.3.8-2 THE PURSE LAW: the wallet opens where the last session left it
        run_ccoins = meta.coins()
        theme_id = meta.theme()
        night = meta.is_night()
        start_id = String(meta.d.get("last_start", "soldier"))
        if not CSData.STARTS.has(start_id):
                start_id = "soldier"
        bonus_div_override = 200      # THE OWNER'S KILL-BONUS LAW (/200)
        world = Node2D.new()
        add_child(world)
        _apply_ambience()
        _build_ground()
        _build_camera()
        fx = FxLayer.new()
        fx.game = self
        world.add_child(fx)
        _build_player()
        _build_hud()
        add_hud_button("INFO", func(): _info_open())
        add_hud_button("SHOP", func(): _shop_button())
        # v0.3.8-3 THE TREE RETIRES: the top-bar TREE button is dead (the
        # owner: "remove the tree button, it's useless, it was from old
        # system but now it is the skills system anyway"). The SKILLS menu
        # owns the meta upgrades now; the old tree flags stay as data the
        # run still reads (slots, second wind, the lab) - bought in the shop.
        var theme: Dictionary = CSData.THEMES[theme_id]
        Jukebox.music(theme["night_music"] if night else theme["day_music"])
        _optionals_open()

# ------------------------------------------------------------------ ground
func _build_ground() -> void:
        if ground_layer != null and is_instance_valid(ground_layer):
                ground_layer.queue_free()
        ground_layer = Node2D.new()
        ground_layer.z_index = -30
        world.add_child(ground_layer)
        var theme: Dictionary = CSData.THEMES[theme_id]
        var tex_path: String = theme["night"] if night else theme["day"]
        var gt: Texture2D = load(tex_path)
        var gw := gt.get_width()
        var gh := gt.get_height()
        for gy in range(-1, int((ARENA.size.y + ARENA_MARGIN * 2) / gh) + 1):
                for gx in range(-1, int((ARENA.size.x + ARENA_MARGIN * 2) / gw) + 1):
                        var cell := Sprite2D.new()
                        cell.texture = gt
                        cell.centered = false
                        cell.position = Vector2(gx * gw, gy * gh) - Vector2(ARENA_MARGIN, ARENA_MARGIN)
                        ground_layer.add_child(cell)
        # the park's dead ferris wheel watches from the top edge
        if theme_id == "park":
                var ferris := Sprite2D.new()
                ferris.texture = _t("ferris")
                ferris.position = Vector2(ARENA.size.x * 0.72, -30)
                ferris.modulate = Color(1, 1, 1, 0.55)
                ground_layer.add_child(ferris)
        _scatter_props(theme)
        _apply_ambience()

func _scatter_props(theme: Dictionary) -> void:
        props.clear()
        var rng := RandomNumberGenerator.new()
        rng.seed = int(hash(theme_id) + (911 if night else 313))  # per-theme+time
        var kinds: Array = theme["night_props"] if night else theme["props"]
        if night:
                kinds = kinds.duplicate()
                kinds.append_array(["crystal1", "crystal2"])  # the zip's crystals glow at night
        var n := 30
        for i in n:
                var k: String = kinds[rng.randi() % kinds.size()]
                var tex: Texture2D = _t(k) if k in ["rock", "skull", "crate", "barrel",
                                "tree", "bench", "fence", "shrub", "ferris",
                                "crystal1", "crystal2", "crystal3"] else _t(String(k))
                var spr := Sprite2D.new()
                spr.texture = tex
                spr.position = Vector2(rng.randf_range(60, ARENA.size.x - 60),
                                rng.randf_range(60, ARENA.size.y - 60))
                spr.scale = Vector2.ONE * rng.randf_range(0.8, 1.5)
                spr.rotation = rng.randf_range(-0.2, 0.2)
                spr.z_index = -5
                ground_layer.add_child(spr)
                # big props are SOLID: a soft circle the units slide around
                var r := tex.get_width() * spr.scale.x * 0.35
                if k in ["rock", "crate", "tree", "barrel", "crystal1", "crystal2", "crystal3"]:
                        props.append({"c": spr.position, "r": r})

## the day/night ambience: the tint finally APPLIED (v0.3.4 computed it
## and dropped it on the floor - the patch-1 audit)
func _apply_ambience() -> void:
        var theme: Dictionary = CSData.THEMES[theme_id]
        world.modulate = theme["tint_night"] if night else theme["tint_day"]

## the theme flip repaints the dress in place - the run is never rebooted
func _retheme(tid: String, nite: bool) -> void:
        theme_id = tid
        night = nite
        meta.set_theme(theme_id, night)
        _build_ground()
        var theme: Dictionary = CSData.THEMES[theme_id]
        Jukebox.music(theme["night_music"] if night else theme["day_music"])

# ------------------------------------------------------------------ camera
func _build_camera() -> void:
        cam = Camera2D.new()
        cam.position = p_pos
        add_child(cam)          # v0.3.8-4: IN the tree first - make_current
        cam.make_current()      # errors "!is_inside_tree()" the other order
        _apply_cam_zoom()

## THE ZOOM LAW: on huge logical viewports the camera zooms OUT so the
## visible world never exceeds ~1700x1000 - the view must never fit the
## whole ground (the camera law's guarantee, at any resolution).
func _apply_cam_zoom() -> void:
        var view := get_viewport_rect().size
        var z: float = maxf(maxf(1.0, view.x / 1700.0), view.y / 1000.0)
        cam.zoom = Vector2.ONE * z

func _cam_half() -> Vector2:
        return get_viewport_rect().size * 0.5 / (cam.zoom if cam != null else Vector2.ONE)

func _cam_clamp_pos(target: Vector2) -> Vector2:
        # the camera law: clamp to the arena + margin so the view NEVER fits the
        # whole ground - the edges always hold more world
        var half := _cam_half()
        var lo := Vector2(ARENA.position.x - ARENA_MARGIN, ARENA.position.y - ARENA_MARGIN) + half
        var hi := Vector2(ARENA.end.x + ARENA_MARGIN, ARENA.end.y + ARENA_MARGIN) - half
        if lo.x > hi.x:
                var mx := (ARENA.position.x + ARENA.end.x) * 0.5
                lo.x = mx
                hi.x = mx
        if lo.y > hi.y:
                var my := (ARENA.position.y + ARENA.end.y) * 0.5
                lo.y = my
                hi.y = my
        return Vector2(clampf(target.x, lo.x, hi.x), clampf(target.y, lo.y, hi.y))

# ------------------------------------------------------------------ player
func _build_player() -> void:
        p_pos = ARENA.get_center()
        p_node = Sprite2D.new()
        p_node.texture = _t("hero_" + start_id + "_f0")
        p_node.z_index = 10
        world.add_child(p_node)
        stats = _base_stats()
        p_max_hp = _max_hp()
        p_hp = p_max_hp
        _rebuild_weapons()

func _rebuild_weapons() -> void:
        weapons_run.clear()
        for wid in meta.loadout():
                weapons_run.append({"id": wid, "tier": 1, "cd": 0.0})
        _rebuild_slots()

# ================================================================ the stats
## the live stat block: START base x tree meta x run drafts x level picks.
## PATCH 1: LUCK and DODGE join the block (the Brotato mouthfuls).
func _base_stats() -> Dictionary:
        var s: Dictionary = CSData.STARTS[start_id]
        var st := {
                "dmg_m": float(s["dmg"]), "spd_m": float(s["spd"]),
                "aspeed_m": float(s["aspeed"]), "range_m": float(s["range"]),
                "armor": int(s["armor"]), "crit": float(s["crit"]),
                "regen": float(s["regen"]), "magnet": 1.0,
                "proj_add": 0, "pierce_add": 0, "pierce_all": 0, "lifesteal": 0.0,
                "burn_hit": start_id == "pyro", "chill_hit": start_id == "frostbite",
                "ally_dmg": 1.0, "contact_cut": 1.0,
                "crit_mult": 2.0, "coin_m": 1.0,
                "luck": float(s.get("luck", 0.0)),
                "dodge": float(s.get("dodge", 0.0)),
        }
        if start_id == "soldier":
                st["dmg_m"] += 0.10
        if start_id == "brawler":
                st["contact_cut"] = 0.8
        if start_id == "engineer":
                st["ally_dmg"] = 1.25
        # THE TREE (meta perks)
        if meta.tree_node("o1"):
                st["dmg_m"] += 0.08
        if meta.tree_node("o2"):
                st["dmg_m"] += 0.08
        if meta.tree_node("o4"):
                st["crit"] += 0.10
        if meta.tree_node("o5"):
                st["crit_mult"] = 3.0
        if meta.tree_node("d1"):
                st["hp_bonus"] = 20.0
        if meta.tree_node("d2"):
                st["armor"] += 2
        if meta.tree_node("d3"):
                st["regen"] += 1.0
        if meta.tree_node("u1"):
                st["magnet"] += 0.30
        if meta.tree_node("u2"):
                st["coin_m"] += 0.10
        if meta.tree_node("l2"):
                st["ally_dmg"] += 0.25
        # THE SKILLS (the meta perks, v0.3.4-3) - v0.3.8-2: the LEVEL tables
        # (skill_num reads the row for the owned level; level 0 never reads)
        var gut_lv := meta.skill_level("golden_gut")
        if gut_lv > 0:
                st["coin_m"] += float(CSData.skill_num("golden_gut", "coin", gut_lv, 0.25))
        var mag_lv := meta.skill_level("magnetic_skin")
        if mag_lv > 0:
                st["magnet"] += float(CSData.skill_num("magnetic_skin", "magnet", mag_lv, 0.6))
                st["luck"] += float(CSData.skill_num("magnetic_skin", "luck", mag_lv, 0.0))
        return st

func _max_hp() -> float:
        var base: float = float(CSData.STARTS[start_id]["hp"])
        var bonus := 0.0
        if meta.tree_node("d1"):
                bonus += 20.0
        # the run's accumulated +max_hp (drafts + level picks live in stats.hp_add)
        bonus += float(stats.get("hp_add", 0.0))
        return base + bonus

# ================================================================ the tick
func _goga_tick(delta: float) -> void:
        if phase != "play" and phase != "break":
                return
        _tick_player(delta)
        _tick_skills(delta)
        _tick_weapons(delta)
        _tick_allies(delta)
        _tick_bullets(delta)
        _tick_ebullets(delta)
        _tick_enemies(delta)
        _tick_zones(delta)
        _tick_pickups(delta)
        _tick_waves(delta)
        _tick_fx(delta)
        _tick_camera(delta)
        fx.queue_redraw()
        _refresh_hud()
        # THE PURSE LAW heartbeat: the wallet checkpoints every 5s so a crash
        # or an app kill never eats more than five seconds of coins
        _cc_clock += delta
        if _cc_clock >= 5.0:
                _cc_clock = 0.0
                _cc_sync()

func _tick_player(delta: float) -> void:
        # the regen law
        if p_hp < p_max_hp and stats["regen"] > 0:
                p_hp = minf(p_max_hp, p_hp + stats["regen"] * delta)
        if p_iframe > 0:
                p_iframe -= delta
        var moving := false
        # the stick move
        if stick_active and stick_vec.length() > 0.01:
                var v := stick_vec * PLAYER_SPD * float(stats["spd_m"])
                # v0.3.8-2: ADRENALINE ROOT L5 - the legs join the rev (+25%)
                if _adrenaline > 0.0 and meta.has_skill("adrenaline"):
                        v *= float(CSData.skill_num("adrenaline", "spd",
                                        meta.skill_level("adrenaline"), 1.0))
                p_pos += v * delta
                p_walk += delta * 10.0
                moving = true
        else:
                p_walk = 0.0
        # solid props: slide out of the circles
        for pr in props:
                var d: Vector2 = p_pos - pr["c"]
                var dist := d.length()
                var rmin: float = float(pr["r"]) + PLAYER_R
                if dist < rmin and dist > 0.01:
                        p_pos = pr["c"] + d.normalized() * rmin
        p_pos.x = clampf(p_pos.x, ARENA.position.x + PLAYER_R, ARENA.end.x - PLAYER_R)
        p_pos.y = clampf(p_pos.y, ARENA.position.y + PLAYER_R, ARENA.end.y - PLAYER_R)
        # THE WALK THEATRE: the legs answer the stick, the body never rotates
        # (Brotato's body faces the camera; the GUN does the aiming)
        var frame := 0
        if moving:
                frame = int(p_walk * 4.0) % 4
        p_node.texture = _t("hero_" + start_id + "_f" + str(frame))
        p_node.flip_h = absf(fposmod(p_aim + PI, TAU) - PI) > PI * 0.5
        p_node.position = p_pos + Vector2(0, sin(p_walk * TAU) * 1.5)
        var flash := 1.0 if p_iframe <= 0 else (0.5 + 0.5 * absf(sin(p_iframe * 30.0)))
        p_node.modulate = Color(1, flash, flash)

func _tick_camera(delta: float) -> void:
        var target := _cam_clamp_pos(p_pos)
        cam.position = cam.position.lerp(target, clampf(8.0 * delta, 0.0, 1.0))
        # THE WOW PASS: the shake decays fast and rides the clamped position
        if _shake > 0.01:
                _shake = maxf(0.0, _shake - 24.0 * delta)
                cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
        else:
                cam.offset = Vector2.ZERO

# ================================================================ the stick
func _goga_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch or event is InputEventMouseButton:
                var pressed: bool = event.pressed if event is InputEventScreenTouch \
                                else (event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
                var p := (event as InputEventScreenTouch).position \
                                if event is InputEventScreenTouch else (event as InputEventMouseButton).position
                if pressed and not stick_active:
                        # THE INVISIBLE STICK is born under ANY finger, anywhere.
                        # NOTHING renders - not a ring, not a knob, not a whisper.
                        if sheet_open_count() == 0 and not over and phase == "play":
                                stick_active = true
                                stick_origin = p
                                stick_vec = Vector2.ZERO
                elif not pressed and stick_active:
                        stick_active = false
                        stick_vec = Vector2.ZERO
        elif event is InputEventScreenDrag or event is InputEventMouseMotion:
                var p2 := (event as InputEventScreenDrag).position \
                                if event is InputEventScreenDrag else (event as InputEventMouseMotion).position
                if stick_active:
                        var d := p2 - stick_origin
                        if d.length() < STICK_DEAD:
                                stick_vec = Vector2.ZERO
                        else:
                                stick_vec = d.limit_length(STICK_MAX) / STICK_MAX

# ================================================================ the HUD
## THE GAME'S OWN WIDGETS: black boxes, colored text. HP green/red, XP blue,
## wave yellow, KILLS red, coins yellow, boss red. The money widget wears
## the NEW cosmic coin (a potato embossed in gold - never the gogacoin).
## v0.3.4-3 THE HUD LAW: the box chrome chips die WHOLE (hiding only their
## labels left an EMPTY chip floating next to the coin chip - the owner's
## report), and the game builds its own SCORE + KILLS + GOGACoins widgets.
func _build_hud() -> void:
        if _hud_built:
                return
        _hud_built = true
        # the box chrome FIRST (its canvas layer + overlay root + back button),
        # then the game's own widgets on top - the box labels hide after
        super._build_hud()
        # THE TOP BUTTONS LAW (v0.3.4-5, the owner: "first time it let me open
        # the shop from the top button, but now it's not"): the box's top bar
        # (the "<" back + the SHOP button) processes while the CS sheets
        # pause the tree - the top buttons answer EVERY time now, over every
        # sheet. The BACK LAW still guards the door.
        if _hud_row != null and is_instance_valid(_hud_row):
                _hud_row.process_mode = Node.PROCESS_MODE_ALWAYS
        # THE CHIP LAW: the whole chrome chips vanish (score chip + coin chip)
        var sc_chip := _score_chip_ref()
        var cc_chip := _coins_chip_ref()
        if sc_chip != null and is_instance_valid(sc_chip):
                sc_chip.visible = false
        if cc_chip != null and is_instance_valid(cc_chip):
                cc_chip.visible = false
        if _hud_row != null and is_instance_valid(_hud_row):
                _hud_row.offset_top = 44.0
                _hud_row.offset_bottom = 104.0
        var root := _overlay_root_ref()
        # ---- the left stack (HP / XP / wave)
        var left := VBoxContainer.new()
        left.position = Vector2(12, 116)
        left.custom_minimum_size = Vector2(300, 0)
        left.add_theme_constant_override("separation", 4)
        root.add_child(left)
        # THE HONEST METERS LAW: plain-Control meters + free-floating labels.
        # HP: the fill MOVES for each HP (animated approach) and its color
        # runs a continuous green -> yellow -> red by the true ratio.
        hp_meter = _cs_meter(300, 34, CS_GREEN)
        left.add_child(hp_meter)
        hp_meter.get_meta("set_ratio").call(1.0, CS_GREEN)   # full at boot
        hp_txt = _cs_label("", 12, CS_WHITE)
        _cs_outline(hp_txt)
        hp_meter.add_child(hp_txt)
        var sub := HBoxContainer.new()
        sub.add_theme_constant_override("separation", 12)
        left.add_child(sub)
        arm_txt = _cs_label("ARM 0", 12, CS_BLUE)
        _cs_outline(arm_txt)
        sub.add_child(arm_txt)
        lvl_txt = _cs_label("LV 1", 12, CS_BLUE)
        lvl_txt.custom_minimum_size = Vector2(64, 0)
        _cs_outline(lvl_txt)
        sub.add_child(lvl_txt)
        # the XP bar (blue, honest: run_xp / xp needed for the next level)
        xp_meter = _cs_meter(300, 14, CS_BLUE)
        left.add_child(xp_meter)
        # v0.3.8-4 THE SKILL PTS LABEL (the owner: "the text of skill points
        # meter is in the bar itself and the bar looks like it has no place
        # to breath... make the text just show SKILL PTS nn... a better way
        # is to be current/100 so it shows like 50/100"): the label leaves
        # the bar for its OWN line above it, and the text is the honest
        # current/100 count. Black outlined - it floats over the field now.
        sp_txt = _cs_label("SKILL PTS 0/100", 12, CS_YELLOW)
        _cs_outline(sp_txt)
        sp_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        left.add_child(sp_txt)
        # v0.3.8-3 THE SKILL POINT METER: the twin of the XP bar - it fills
        # with the KILLS that feed the next SKILL POINT (one per 100 kills,
        # lifetime + this run). Gold, because a point is a promise.
        sp_meter = _cs_meter(300, 12, CS_YELLOW)
        left.add_child(sp_meter)
        # the wave box with its time bar
        var wave_box := _cs_black_box(left, Vector2(300, 42))
        var wv := VBoxContainer.new()
        wave_box.add_child(wv)
        wave_txt = _cs_label("WAVE 1", 12, CS_YELLOW)
        wv.add_child(wave_txt)
        wave_meter = _cs_meter(280, 6, Color(1.0, 0.62, 0.26))
        wv.add_child(wave_meter)
        # ---- THE RIGHT STACK (the owner's two live here): cosmic coins,
        # SCORE, KILLS, GOGACoins - one black box each, big enough to read
        var right := VBoxContainer.new()
        right.position = Vector2(get_viewport_rect().size.x - 266, 116)
        right.custom_minimum_size = Vector2(250, 0)
        right.add_theme_constant_override("separation", 4)
        root.add_child(right)
        # the cosmic coins (THE BIG WIDGET - the owner: "the cosmic coins
        # widget is small too")
        var cc := _cs_black_box(right, Vector2(250, 46))
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 6)
        cc.add_child(h)
        h.add_child(_cs_icon(_t("coin"), 24))
        cc_txt = _cs_label("0", 18, CS_YELLOW)
        h.add_child(cc_txt)
        # SCORE (yellow) + KILLS (red) - the two the owner named
        var sc_box := _cs_black_box(right, Vector2(250, 40))
        var h3 := HBoxContainer.new()
        h3.add_theme_constant_override("separation", 6)
        sc_box.add_child(h3)
        h3.add_child(_cs_icon(_t("star"), 18))
        score_txt = _cs_label("SCORE 0", 15, CS_YELLOW)
        h3.add_child(score_txt)
        var kl_box := _cs_black_box(right, Vector2(250, 40))
        var h4 := HBoxContainer.new()
        h4.add_theme_constant_override("separation", 6)
        kl_box.add_child(h4)
        h4.add_child(_cs_icon(_t("skull"), 18))
        kill_txt = _cs_label("KILLS 0", 15, CS_RED)
        h4.add_child(kill_txt)
        # THE GOGACoins widget (v0.3.4-4 THE UNIVERSAL WIDGET LAW, the
        # owner: "the widget you made for gogacoins is not the right widget
        # that is universally used in gogabox, also i see you made a mistake
        # where you even made the GOGAcoins widget to show total coins
        # instead of the collected"): the widget IS Arc.chip + coin.png -
        # the exact universal chip every game's HUD wears - and it counts
        # the coins COLLECTED THIS RUN (starts 0, ticks on pickup), never
        # the wallet total. The total lives in the shop header, where it
        # belongs. SILENCE LAW unchanged: it never announces itself.
        var gg_chip := Arc.chip("0", "res://assets/ui/coin.png", Color(0, 0, 0, 0.4), 24, Arc.COIN)
        right.add_child(gg_chip)
        # the label is the LAST child of the chip's HBox (the same accessor
        # game_base._build_hud uses for its own score/coins chips)
        var gg_h: HBoxContainer = gg_chip.get_child(0)
        gg_txt = gg_h.get_child(gg_h.get_child_count() - 1) as Label
        gg_txt.text = "0"
        # ---- the boss bar (top center)
        boss_bar = _cs_black_box(root, Vector2(430, 28))
        boss_bar.position = Vector2((get_viewport_rect().size.x - 430) * 0.5, 116)
        boss_meter = _cs_meter(430, 28, CS_RED)
        boss_bar.add_child(boss_meter)
        boss_txt = _cs_label("", 11, CS_WHITE)
        boss_bar.add_child(boss_txt)
        boss_bar.visible = false
        # ---- the weapon slots (bottom left)
        slot_row = HBoxContainer.new()
        slot_row.position = Vector2(12, get_viewport_rect().size.y - 66)
        slot_row.add_theme_constant_override("separation", 6)
        root.add_child(slot_row)
        _rebuild_slots()

## a fixed-size icon TextureRect for the HUD rows
func _cs_icon(tex: Texture2D, px: int) -> TextureRect:
        var ic := TextureRect.new()
        ic.texture = tex
        ic.custom_minimum_size = Vector2(px, px)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        return ic

## v0.3.4-4 THE HONEST METERS LAW - the one-true-meter.
## A PLAIN Control (never a PanelContainer child: a Container resets a
## child's manual geometry whenever a sibling's minimum size changes - the
## probe-proven root cause of the dead meters). The meter draws its own
## trough, fill and rim; the fill's width and color are driven by
## set_ratio. The HP bar passes its LIVE color (green -> yellow -> red);
## every meter animates toward its true ratio in _refresh_hud, so a hit,
## a heal, an XP gem or a boss slam visibly MOVES the bar.
func _cs_meter(w: float, h: float, col: Color) -> Control:
        var c := Control.new()
        c.custom_minimum_size = Vector2(w, h)
        c.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var st := {"r": 0.0, "col": col}
        c.draw.connect(func():
                var ww: float = c.size.x
                var hh: float = c.size.y
                # the trough
                c.draw_rect(Rect2(0, 0, ww, hh), Color(0, 0, 0, 0.62))
                # the fill (2px inset, never negative)
                var r: float = st["r"]
                if r > 0.001:
                        c.draw_rect(Rect2(2, 2, maxf(0.0, (ww - 4.0) * r), hh - 4.0),
                                        st["col"])
                # the rim
                c.draw_rect(Rect2(0, 0, ww, hh), Color(0.08, 0.06, 0.04, 0.9), false, 2.0))
        c.set_meta("set_ratio", func(r: float, col2: Variant = null) -> void:
                st["r"] = clampf(r, 0.0, 1.0)
                if col2 != null:
                        st["col"] = col2
                c.queue_redraw())
        c.set_meta("state", st)     # probe-readable: the live fill + color
        return c

## the HP meter's continuous green -> yellow -> red, the owner's "color goes
## dynamically from green to red in a better way"
func _hp_color(r: float) -> Color:
        var yellow := Color(1.0, 0.82, 0.15)
        if r > 0.5:
                return CS_GREEN.lerp(yellow, (1.0 - r) * 2.0)
        return yellow.lerp(CS_RED, 1.0 - r * 2.0)

func _rebuild_slots() -> void:
        if slot_row == null or not is_instance_valid(slot_row):
                return
        for w in _slot_widgets:
                (w["box"] as Control).queue_free()
        _slot_widgets.clear()
        for wr in weapons_run:
                var box := PanelContainer.new()
                box.add_theme_stylebox_override("panel", _cs_box_style())
                box.custom_minimum_size = Vector2(60, 60)
                slot_row.add_child(box)
                var vb := VBoxContainer.new()
                vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
                box.add_child(vb)
                var ic := TextureRect.new()
                ic.texture = _t("icon_" + String(wr["id"]))
                ic.custom_minimum_size = Vector2(52, 40)
                ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                vb.add_child(ic)
                var tt := _cs_label("T%d" % int(wr["tier"]), 10, CS_YELLOW)
                tt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                vb.add_child(tt)
                var cd := ColorRect.new()
                cd.color = Color(0, 0, 0, 0.55)
                cd.position = Vector2(2, 2)
                cd.size = Vector2(0, 54)
                box.add_child(cd)
                _slot_widgets.append({"box": box, "cd": cd, "id": wr["id"]})

func _refresh_hud() -> void:
        # THE HONEST METERS LAW: every meter animates toward its true ratio
        # (the lerp step is per-tick at 60fps - a full swing settles in
        # ~0.2s, so each HP point, gem or boss slam visibly MOVES the bar).
        var _step := 0.28
        if hp_meter != null and is_instance_valid(hp_meter):
                var f := clampf(p_hp / p_max_hp, 0.0, 1.0)
                _hp_disp = lerpf(_hp_disp, f, _step)
                if absf(_hp_disp - f) < 0.004:
                        _hp_disp = f
                var col := _hp_color(f) if f > 0.0 else CS_RED
                hp_meter.get_meta("set_ratio").call(_hp_disp, col)
                hp_txt.text = "%d / %d" % [int(ceilf(p_hp)), int(p_max_hp)]
                hp_txt.position = Vector2((300.0 - hp_txt.size.x) * 0.5, 4.0)
        if xp_meter != null and is_instance_valid(xp_meter):
                # THE HONEST XP LAW: the true ratio of THIS level's progress;
                # a level-up drains the bar and it refills with every gem
                var need := maxi(1, CSData.xp_for_run_level(run_level))
                var xr := clampf(float(run_xp) / float(need), 0.0, 1.0)
                _xp_disp = lerpf(_xp_disp, xr, _step)
                if absf(_xp_disp - xr) < 0.004:
                        _xp_disp = xr
                xp_meter.get_meta("set_ratio").call(_xp_disp)
        if sp_meter != null and is_instance_valid(sp_meter):
                # THE SKILL POINT METER: the true distance to the NEXT point
                # (the lifetime kills + this run's kills, one point per 100)
                var live: int = int(meta.d["kills"]) + run_kills
                var into := live % CSData.SKILL_PT_KILLS
                var spr := clampf(float(into) / float(CSData.SKILL_PT_KILLS), 0.0, 1.0)
                _sp_disp = lerpf(_sp_disp, spr, _step)
                if absf(_sp_disp - spr) < 0.004:
                        _sp_disp = spr
                sp_meter.get_meta("set_ratio").call(_sp_disp)
                var free := meta.skill_points_free(run_kills)
                # v0.3.8-4: the label left the bar - OWN line above it, the
                # honest current/100 count (the owner: "current/100 so it
                # shows like 50/100 and will be more helpful")
                sp_txt.text = "SKILL PTS %d/%d" % [into, CSData.SKILL_PT_KILLS]
                if free > 0:
                        sp_txt.text += "  +%d" % free
        if arm_txt != null:
                arm_txt.text = "ARM %d" % int(stats.get("armor", 0))
                lvl_txt.text = "LV %d" % run_level
                kill_txt.text = "KILLS %d" % run_kills
        if wave_txt != null:
                wave_txt.text = ("BOSS WAVE - SLAY IT" if boss_alive
                                else "WAVE %d" % run_wave)
                wave_txt.add_theme_color_override("font_color", CS_RED if boss_alive else CS_YELLOW)
                var total := CSData.BOSS_WAVE_SECS if (run_wave % CSData.BOSS_CYCLE == 0) \
                                else CSData.WAVE_SECS
                var wr := clampf(wave_clock / maxf(0.01, float(total)), 0.0, 1.0)
                _wave_disp = lerpf(_wave_disp, wr, _step)
                wave_meter.get_meta("set_ratio").call(_wave_disp)
        if cc_txt != null:
                cc_txt.text = str(run_ccoins)
        if score_txt != null:
                score_txt.text = "SCORE %d" % score
        if kill_txt != null:
                kill_txt.text = "KILLS %d" % run_kills
        if gg_txt != null:
                # THE UNIVERSAL WIDGET LAW: the chip counts the coins
                # COLLECTED THIS RUN (add_run_coins banks them at finish) -
                # never the wallet total
                gg_txt.text = str(run_coins)
        if boss_meter != null and is_instance_valid(boss_meter):
                var found := false
                for e in enemies:
                        if e.get("boss", false):
                                found = true
                                boss_bar.visible = true
                                var br := clampf(float(e["hp"]) / float(e["max_hp"]), 0.0, 1.0)
                                _boss_disp = lerpf(_boss_disp, br, _step)
                                boss_meter.get_meta("set_ratio").call(_boss_disp)
                                boss_txt.text = "%s  %d%%" % [e["name"], int(100.0 * float(e["hp"]) / float(e["max_hp"]))]
                                boss_txt.position = Vector2((430.0 - boss_txt.size.x) * 0.5, 1.0)
                                break
                if not found:
                        boss_bar.visible = false
                        _boss_disp = 1.0
        # the slot cooldown fills
        for i in _slot_widgets.size():
                if i >= weapons_run.size():
                        break
                var wd: Dictionary = CSData.WEAPONS[weapons_run[i]["id"]]
                var mult: Dictionary = CSData.tier_mult(int(weapons_run[i]["tier"]))
                var full: float = float(wd["cad"]) * float(mult["cad"])
                var left2: float = maxf(0.0, float(weapons_run[i]["cd"]))
                (_slot_widgets[i]["cd"] as ColorRect).size.y = 42.0 * clampf(left2 / maxf(0.01, full), 0.0, 1.0)

# ================================================================ weapons
func _tick_weapons(delta: float) -> void:
        # aim: the best target for the FIRST weapon sets Spudnik's facing
        p_aim = _aim_angle()
        var aspeed: float = float(stats["aspeed_m"])
        # THE ADRENALINE ROOT: a dodge revs the guns (the level's own rev)
        if _adrenaline > 0.0:
                aspeed *= float(CSData.skill_num("adrenaline", "aspeed",
                                meta.skill_level("adrenaline"), 1.8))
        # THE SPLIT SIGHT (v0.3.9-5, the owner: "when there is more than one
        # weapon, make each one shoots another enemy based on distance and
        # range ... making multi-targets as a skill with upgrades so it
        # specifies how many weapons can be used to shoot different enemies
        # and the rest will remain one at a time"): the first N slots each
        # CLAIM their own prey (greedy, slot order, each inside ITS range);
        # the remaining weapons all hunt the one best target together.
        var split_n := 0
        if meta.has_skill("split_sight"):
                split_n = int(CSData.skill_num("split_sight", "guns",
                                meta.skill_level("split_sight"), 2))
        var claimed: Array = []
        for i in weapons_run.size():
                var w: Dictionary = weapons_run[i]
                w["target"] = null
                if i < split_n:
                        var tgt: Variant = _pick_target(_weapon_range(w), claimed)
                        if tgt != null:
                                claimed.append(tgt)
                                w["target"] = tgt
        for w in weapons_run:
                # THE HEAVY KICK: the barrel cools every tick it doesn't fire
                if float(w.get("heat", 0.0)) > 0.0:
                        w["heat"] = maxf(0.0, float(w["heat"])
                                        - CSData.KICK_COOL * delta)
                w["cd"] -= delta * aspeed
                if w["cd"] <= 0.0:
                        if _fire_weapon(w):
                                var mult: Dictionary = CSData.tier_mult(int(w["tier"]))
                                w["cd"] = float(CSData.WEAPONS[w["id"]]["cad"]) * float(mult["cad"])
                        else:
                                w["cd"] = 0.05   # nothing in range - retry soon

## the effective range of one holstered weapon (the kick/target helpers)
func _weapon_range(w: Dictionary) -> float:
        var wd: Dictionary = CSData.WEAPONS[w["id"]]
        return float(wd["rng"]) * float(stats["range_m"]) \
                        * float(CSData.tier_mult(int(w["tier"])).get("rng", 1.0))

func _aim_angle() -> float:
        var best := p_aim
        var best_score := -1.0
        for e in enemies:
                var d: Vector2 = e["pos"] - p_pos
                var dist2 := d.length_squared()
                if dist2 > 810000.0:      # 900^2 - the aim's horizon
                        continue
                var pr := 1.0
                if e.get("boss", false):
                        pr = 3.0
                elif e.get("elite", false):
                        pr = 2.0
                var sc := pr * 810000.0 - dist2
                if sc > best_score:
                        best_score = sc
                        best = d.angle()
        return best

func _fire_weapon(w: Dictionary) -> bool:
        var wid: String = w["id"]
        var wd: Dictionary = CSData.WEAPONS[wid]
        var tier: int = int(w["tier"])
        var mult := CSData.tier_mult(tier)
        var rng: float = float(wd["rng"]) * float(stats["range_m"]) \
                        * float(mult.get("rng", 1.0))
        var count: int = int(wd["count"]) + int(mult["count"]) + int(stats["proj_add"])
        # THE SPLIT SIGHT: a split slot fires at its OWN claimed prey while
        # it lives and stays (near) in range - a dead or fled claim falls
        # back to the shared best target
        var target: Variant = w.get("target", null)
        if target != null and (target.get("dead", false)
                        or (target["pos"] - p_pos).length() > rng * 1.2):
                target = null
        if target == null:
                target = _pick_target(rng)
        if target == null:
                return false
        var te: Dictionary = target
        var base_a: float = (te["pos"] - p_pos).angle()
        # THE HEAVY KICK (v0.3.9-5): the shot walks out of line by a
        # specific angle as the barrel heats - "slightly out of line by
        # specific angle from shot to shot ... after rapid firing like a
        # real thing". Slow fire keeps it microscopic; spamming shakes it.
        var kick_heat := 0.0
        var kick_spec: Dictionary = CSData.HEAVY_KICK.get(wid, {})
        if not kick_spec.is_empty():
                kick_heat = clampf(float(w.get("heat", 0.0)) + CSData.KICK_HEAT,
                                0.0, 1.0)
                w["heat"] = kick_heat
                base_a += randf_range(-1.0, 1.0) * float(kick_spec["kick"]) \
                                * pow(kick_heat, 1.5)
        var shot_name: String = wd["shot"]
        var pierce: int = int(wd["pierce"]) + int(stats.get("pierce_add", 0))
        if int(stats["pierce_all"]) > 0:
                pierce = 99
        var base_dmg: float = float(wd["dmg"]) * float(mult["dmg"]) * float(stats["dmg_m"])
        # THE STARCH RAGE: the level's own threshold and rage (v0.3.8-2)
        if meta.has_skill("starch_rage"):
                var sr_lv := meta.skill_level("starch_rage")
                if p_hp < p_max_hp * float(CSData.skill_num("starch_rage", "thresh", sr_lv, 0.35)):
                        base_dmg *= float(CSData.skill_num("starch_rage", "rage", sr_lv, 1.4))
        # THE MELEE LAW (v0.3.4-5): THE PEEL CLEAVER - one fast arc chop, the
        # whole swing bites everything inside. No bullet: the arc IS it.
        if bool(wd.get("melee", false)):
                var arc: float = float(wd.get("arc", 2.1))
                for e in enemies.duplicate():
                        if e.get("dead", false):
                                continue
                        var dv: Vector2 = e["pos"] - p_pos
                        if dv.length() > rng + float(e["size"]) * 0.4:
                                continue
                        if absf(angle_difference(base_a, dv.angle())) > arc * 0.5:
                                continue
                        # v0.3.8-3 THE SHIELD TRUTH: the cleaver CHEWS the
                        # shell - the swing bites the outermost alive layer
                        # area at the swing's own angle; a fully-open path
                        # (no alive area on the outermost layer there)
                        # reaches the body.
                        if e.get("shield", null) != null \
                                        and _melee_chew_shield(e, base_a, base_dmg):
                                continue
                        _hurt_enemy(e, base_dmg, false)
                _slash_fx(base_a, rng, arc)
                Jukebox.sfx(shot_name, -6.0, randf_range(0.94, 1.06))
                # THE TWIN TAIL answers with a backhand swing
                if meta.has_skill("twin_tail"):
                        var tt_m := meta.skill_level("twin_tail")
                        _slash_fx(base_a + PI, rng * float(CSData.skill_num(
                                        "twin_tail", "melee_r", tt_m, 0.6)), arc)
                return true
        for i in count:
                var a := base_a
                if count > 1:
                        a += (float(i) - float(count - 1) * 0.5) * float(wd["spread"])
                var dmg: float = base_dmg
                var kind: String = wd["proj"]
                if kind == "strike":
                        # the orbital lands where the barrel points it - the
                        # kick walks the LANDING SPOT, not the angle
                        var land: Vector2 = te["pos"]
                        if kick_heat > 0.0:
                                land += Vector2.from_angle(
                                                randf_range(0.0, TAU)) \
                                                * float(kick_spec["kick"]) \
                                                * pow(kick_heat, 1.5) \
                                                * maxf(140.0,
                                                (te["pos"] - p_pos).length()) \
                                                * 0.5
                        _orbital_strike(land, dmg, float(wd.get("aoe", 60.0)))
                        continue
                _spawn_bullet(p_pos + Vector2.from_angle(a) * 26.0, a, wd, dmg, pierce, tier)
        # v0.3.4-4 THE NO-SHOOT-VFX LAW (the owner: "remove the shooting
        # flickers/lights or whatever VFX you did, it's ugly anyway"): the
        # muzzle flash is DEAD - the patch-3 FLASH LAW with it. The gun speaks
        # through its sound alone; no lights, no flickers, no candles.
        # THE TWIN TAIL: the ghost gun answers every volley backwards at the
        # level's own fraction (L4+ it PIERCES like its twin)
        if meta.has_skill("twin_tail"):
                var tt_lv := meta.skill_level("twin_tail")
                _spawn_bullet(p_pos + Vector2.from_angle(base_a + PI) * 26.0,
                                base_a + PI, wd, base_dmg * float(CSData.skill_num(
                                        "twin_tail", "frac", tt_lv, 0.4)),
                                int(CSData.skill_num("twin_tail", "pierce", tt_lv, 0)), tier)
        return true

func _pick_target(rng: float, exclude: Array = []) -> Variant:
        var best: Variant = null
        var best_score := -1.0
        var rng2 := rng * rng
        for e in enemies:
                if e.get("dead", false) or exclude.has(e):
                        continue
                var d: Vector2 = e["pos"] - p_pos
                var dist2 := d.length_squared()
                if dist2 > rng2:
                        continue
                var pr := 1.0
                if e.get("boss", false):
                        pr = 3.0
                elif e.get("elite", false):
                        pr = 2.0
                var sc := pr * 810000.0 - dist2
                if sc > best_score:
                        best_score = sc
                        best = e
        return best

func _spawn_bullet(pos: Vector2, a: float, wd: Dictionary, dmg: float,
                pierce: int, tier: int) -> void:
        var kind: String = wd["proj"]
        var spr := Sprite2D.new()
        spr.texture = _t("proj_" + kind)
        spr.position = pos
        spr.rotation = a
        spr.z_index = 6
        world.add_child(spr)
        var b := {
                "pos": pos, "a": a, "spd": float(wd["pspd"]), "dmg": dmg,
                "pierce": pierce, "hit": {}, "range_left": float(wd["rng"])
                                * float(stats["range_m"]) * float(CSData.tier_mult(tier).get("rng", 1.0)),
                "aoe": float(wd.get("aoe", 0.0)), "burn": bool(wd.get("burn", false))
                                or bool(stats["burn_hit"]),
                "chill": float(wd.get("chill", 0.0)), "kind": kind,
                "node": spr, "turn": false, "tier": tier,
                # v0.3.7-1 THE MOLOTOV: the bottle carries its fire pool spec
                "pool": float(wd.get("pool", 0.0)),
                "pool_r": float(wd.get("pool_r", 0.0)),
        }
        if kind == "boomerang":
                b["home"] = null
        bullets.append(b)

func _orbital_strike(at: Vector2, dmg: float, aoe: float) -> void:
        zones.append({"kind": "strike", "pos": at, "t": 0.55, "max": 0.55,
                "dmg": dmg, "aoe": aoe})
        Jukebox.sfx("cs_flash", -8.0)

# ================================================================ allies
## v0.3.5-5 THE ALLY VARIETY LAW (the owner: "make sure that existing
## allies are differ, like some with the character, some go fight around,
## some have auras? some have cool weapons ... make sure they are not too
## cool from the start because there is upgrades and allies usually do
## not die"): every ally has its own job - the drone orbits and shoots,
## the turret plants and sweeps, the guard carries a PROTECTIVE AURA (the
## damage you take inside its ring shrinks), the medic heals with a
## visible pulse, the bomber kamikaze-dives, the scout marks AND plinks a
## weak pea-shooter dart. Level 1 stays humble.
## v0.3.8-3 THE ROSTER FACES (the owner: "all are same visual thing, no
## single different color at all"): the tint trick is DEAD - it reused
## ENEMY textures under near-white modulates, so six jobs shared four
## faces. Every ally owns its DRAWN face now (tools/v038p3_allies.py):
## the teal rotor drone, the orange hard-hat turret, the shield guard,
## the red-cross medic, the fuse bomber, the goggled scout.
const ALLY_TINTS := {
        "drone": Color(1.0, 1.0, 1.0), "turret": Color(1.0, 1.0, 1.0),
        "guard": Color(1.0, 1.0, 1.0), "medic": Color(1.0, 1.0, 1.0),
        "bomber": Color(1.0, 1.0, 1.0), "scout": Color(1.0, 1.0, 1.0),
}
const GUARD_AURA := 130.0       # the guard's protective ring, px

func _deploy_ally(aid: String, level: int) -> void:
        var ad: Dictionary = CSData.ALLIES[aid]
        var spr := Sprite2D.new()
        # v0.3.8-4 THE ALIVE CREW: the sprite wears the 4-frame waddle now
        spr.texture = _t("ally_%s_f0" % aid)
        spr.scale = Vector2.ONE * 0.7
        spr.modulate = ALLY_TINTS.get(aid, Color(0.82, 1.0, 0.9))
        spr.z_index = 8
        world.add_child(spr)
        allies.append({"id": aid, "level": level, "pos": p_pos
                        + Vector2.from_angle(randf() * TAU) * 50.0, "node": spr,
                        "cd": 0.0, "state": "", "t": 0.0,
                        "anim": randf() * TAU, "ppos": p_pos})

## v0.3.8-4 THE ALIVE CREW THEATER (the owner: "they are still feel like a
## static image that someone drags it to follow me, give it moving
## animation like the character or enemies and the left-right looking,
## make it feel like a real thing"): every ally now walks the potato walk -
## the hero's 4-frame waddle driven by REAL movement, the flip facing the
## job (the aim when working, the travel when walking), the squash-and-
## stretch wobble, the drone's hover bob. Same laws the enemies wear.
func _ally_theater(a: Dictionary, delta: float) -> void:
        var nd: Sprite2D = a["node"]
        if nd == null or not is_instance_valid(nd):
                return
        var moved: Vector2 = (a["pos"] as Vector2) - (a["ppos"] as Vector2)
        var spd: float = moved.length() / maxf(0.0001, delta)
        var walking: bool = spd > 9.0
        a["anim"] = float(a["anim"]) + delta * (3.4 + clampf(spd, 0.0, 240.0) * 0.022)
        var aid: String = a["id"]
        var hovering := aid == "drone"
        var frame := 0
        if hovering or walking:
                frame = int(float(a["anim"]) * 4.0) % 4
        nd.texture = _t("ally_%s_f%d" % [aid, frame])
        # the flip faces the JOB: a remembered aim while working, the travel
        # direction while walking (the left-right looking the owner asked for)
        var face := 0.0
        # the remembered aim decays - the flip returns to the travel face
        if a.get("face_x", 0.0) != 0.0:
                a["face_x"] = move_toward(float(a["face_x"]), 0.0, delta * 90.0)
                face = float(a["face_x"])
        elif absf(moved.x) > 0.5:
                face = moved.x
        else:
                face = (a["pos"] as Vector2).x - p_pos.x
        if absf(face) > 2.0:
                nd.flip_h = face < 0.0
        var base_s := 0.7
        var wob := 0.06 * sin(float(a["anim"]) * TAU)
        nd.scale = Vector2(base_s * (1.0 + wob), base_s * (1.0 - wob))
        var hover_dy := 0.0
        if hovering:
                hover_dy = sin(float(a["anim"]) * 2.2) * 4.0
        nd.position = (a["pos"] as Vector2) + Vector2(0, hover_dy)
        a["ppos"] = a["pos"]

func _ally_cap() -> int:
        return meta.ally_slots()

func _tick_allies(delta: float) -> void:
        # v0.3.7-1 THE LEVEL SIGNATURES (the owner, item 19: "make sure
        # their abilities really differ and upgrading them is really deep"):
        # every ally's L2/L3 adds a BEHAVIOR, not just a number -
        #   drone   L2 twin shot            L3 piercing rounds
        #           L4 faster spin (0.4s)   L5 TRIPLE VOLLEY
        #   turret  L2 faster sweep         L3 explosive shells
        #           L4 hunger (0.22s)       L5 bigger booms (64px)
        #   guard   L2 wider aura           L3 the aura slows the swarm
        #           L4+ the ring keeps growing with the level
        #   medic   L2 stronger care        L3 the pulse turns fiery - it
        #             also SEARS enemies that crowd you (burn dps)
        #           L5 the care ring WIDENS (150px)
        #   bomber  L2 bigger blast         L3 the dive leaves a FIRE POOL
        #           L4 eager (6.5s dives)   L5 quick rebuild (3s) + biggest
        #   scout   L2 deeper marks (+30%)  L3 a three-dart burst
        #           L4 deepest marks (+40%) L5 FIVE-DART STORM
        for a in allies:
                var aid: String = a["id"]
                var lv: int = int(a["level"])
                a["t"] += delta
                match aid:
                        "drone":
                                var ang: float = float(a["t"]) * 1.6
                                a["pos"] = p_pos + Vector2.from_angle(ang) * 62.0
                                a["cd"] -= delta * float(stats["ally_dmg"])
                                if a["cd"] <= 0.0 and not enemies.is_empty():
                                        a["cd"] = 0.5 if lv < 4 else 0.4
                                        var tgt: Variant = _nearest_enemy(a["pos"], 520.0)
                                        if tgt != null:
                                                _ally_face_target(a, tgt)
                                                var dir: Vector2 = tgt["pos"] - a["pos"]
                                                var barrels := 1
                                                if lv >= 2:
                                                        barrels += 1
                                                if lv >= 5:
                                                        barrels += 1
                                                for bi in barrels:
                                                        _ally_bullet(a["pos"],
                                                                        dir.angle() + 0.14 * float(bi),
                                                                        4.0 + 2.0 * lv * float(stats["ally_dmg"]),
                                                                        1 if lv >= 3 else 0)
                        "turret":
                                if a["pos"].distance_to(p_pos) > 260.0:
                                        a["state"] = "move"
                                if a["state"] == "move":
                                        a["pos"] = a["pos"].move_toward(p_pos
                                                        + Vector2.from_angle(a["t"]) * 70.0, 190.0 * delta)
                                        if a["pos"].distance_to(p_pos) < 160.0:
                                                a["state"] = ""
                                a["cd"] -= delta * float(stats["ally_dmg"])
                                if a["cd"] <= 0.0:
                                        a["cd"] = 0.42 if lv < 2 else (0.28 if lv < 4 else 0.22)
                                        var tgt2: Variant = _nearest_enemy(a["pos"], 440.0)
                                        if tgt2 != null:
                                                _ally_face_target(a, tgt2)
                                                var d2: Vector2 = tgt2["pos"] - a["pos"]
                                                _ally_bullet(a["pos"], d2.angle(),
                                                                6.0 + 3.0 * lv * float(stats["ally_dmg"]),
                                                                1 if lv >= 3 else 0)
                                                if lv >= 3:
                                                        # THE EXPLOSIVE SHELLS: a small
                                                        # boom on the first body (L5 booms BIG)
                                                        _boom_at(tgt2["pos"],
                                                                        (64.0 if lv >= 5 else 46.0),
                                                                        (4.0 + 3.0 * lv) * 0.6
                                                                        * float(stats["ally_dmg"]), false)
                        "guard":
                                var aura_r: float = GUARD_AURA * (1.0 + 0.15 * float(lv - 1))
                                var threat := Vector2.ZERO
                                var tn := 0
                                for e in enemies:
                                        if e["pos"].distance_to(p_pos) < aura_r:
                                                threat += e["pos"]
                                                tn += 1
                                                # L3: THE DREAD AURA - the swarm inside
                                                # slows (they wade through the guard's
                                                # presence)
                                                if lv >= 3:
                                                        e["chill_t"] = maxf(float(e.get("chill_t", 0.0)), 0.2)
                                if tn > 0:
                                        a["pos"] = a["pos"].lerp(p_pos + (threat / float(tn) - p_pos).normalized() * 40.0,
                                                        6.0 * delta)
                                else:
                                        a["pos"] = a["pos"].lerp(p_pos + Vector2(40, 40), 4.0 * delta)
                                # THE GUARD AURA: the ring breathes so the
                                # potato can read where the shield stands
                                a["cd"] -= delta
                                if a["cd"] <= 0.0:
                                        a["cd"] = 2.5
                                        _rings.append({"pos": a["pos"], "r": aura_r,
                                                        "t": 0.55, "max": 0.55,
                                                        "col": Color(0.55, 1.0, 0.7, 0.5), "w": 4.0})
                        "medic":
                                a["pos"] = a["pos"].lerp(p_pos + Vector2(-40, -40), 4.0 * delta)
                                p_hp = minf(p_max_hp, p_hp + (2.0 + lv \
                                                + (1.5 if lv >= 2 else 0.0)) * delta)
                                # L3: THE SEARING CARE - enemies crowding the
                                # patient catch fire (the medic's flame of life);
                                # L5 the care ring WIDENS to 150px
                                if lv >= 3:
                                        var sear_r := 110.0 if lv < 5 else 150.0
                                        for e in enemies:
                                                if e["pos"].distance_to(p_pos) < sear_r:
                                                        e["burn_t"] = maxf(float(e.get("burn_t", 0.0)), 1.0)
                                                        e["burn_dps"] = maxf(float(e.get("burn_dps", 0.0)), 3.0)
                                # the heal PULSES so the care reads
                                a["cd"] -= delta
                                if a["cd"] <= 0.0:
                                        a["cd"] = 2.0
                                        _rings.append({"pos": a["pos"], "r": 40.0,
                                                        "t": 0.4, "max": 0.4,
                                                        "col": Color(0.5, 1.0, 0.6, 0.6), "w": 3.0})
                        "bomber":
                                a["cd"] -= delta
                                if a["state"] == "dive":
                                        var dtgt: Dictionary = a["target"]
                                        if dtgt == null or not is_instance_valid(dtgt.get("node")) \
                                                        or dtgt.get("dead", false):
                                                a["state"] = ""
                                                a["t"] = 0.0
                                        else:
                                                a["pos"] = a["pos"].move_toward(dtgt["pos"], 420.0 * delta)
                                                if a["pos"].distance_to(dtgt["pos"]) < 26.0:
                                                        var blast := 70.0
                                                        if lv >= 5:
                                                                blast = 120.0
                                                        elif lv >= 2:
                                                                blast = 96.0
                                                        _boom_at(a["pos"], blast,
                                                                        (14.0 + 6.0 * lv)
                                                                        * float(stats["ally_dmg"]), true)
                                                        # L3: THE SCORCHED DIVE - the crash
                                                        # site burns behind the blast
                                                        if lv >= 3:
                                                                _fire_pool(a["pos"], 14.0, 80.0, 2.5)
                                                        a["node"].visible = false
                                                        a["state"] = "dead"
                                                        a["t"] = 0.0
                                elif a["state"] == "dead":
                                        if a["t"] >= (3.0 if lv >= 5 else 5.0):
                                                a["state"] = ""
                                                a["pos"] = p_pos
                                                a["node"].visible = true
                                elif a["cd"] <= 0.0 and not enemies.is_empty():
                                        var tgt3: Variant = _nearest_enemy(a["pos"], 400.0)
                                        if tgt3 != null:
                                                a["state"] = "dive"
                                                a["target"] = tgt3
                                                a["cd"] = 8.0 if lv < 4 else 6.5
                                elif a["state"] == "":
                                        a["pos"] = a["pos"].lerp(p_pos + Vector2(50, -50), 3.0 * delta)
                        "scout":
                                a["pos"] = a["pos"].lerp(p_pos + Vector2(0, 60), 3.0 * delta)
                                var mark_potency := 0.15
                                if lv >= 4:
                                        mark_potency = 0.40
                                elif lv >= 2:
                                        mark_potency = 0.30
                                for e in enemies:
                                        if e["pos"].distance_to(p_pos) < 300.0:
                                                e["marked"] = true
                                                e["mark_m"] = maxf(float(e.get("mark_m", 0.15)),
                                                                mark_potency)
                                # THE SCOUT'S PEA SHOOTER (v0.3.5-5): the
                                # spotter fights around with a weak dart gun
                                # (L3 triple burst, L5 the five-dart storm)
                                a["cd"] -= delta * float(stats["ally_dmg"])
                                if a["cd"] <= 0.0:
                                        a["cd"] = 1.8
                                        var tgt4: Variant = _nearest_enemy(a["pos"], 360.0)
                                        if tgt4 != null:
                                                _ally_face_target(a, tgt4)
                                                var d4: Vector2 = tgt4["pos"] - a["pos"]
                                                var shots := 1
                                                if lv >= 5:
                                                        shots = 5
                                                elif lv >= 3:
                                                        shots = 3
                                                for si in shots:
                                                        _ally_bullet(a["pos"], d4.angle() + 0.09 * (float(si) - float(shots - 1) * 0.5),
                                                                        3.0 + 1.5 * float(lv), 0)
                a["node"].position = a["pos"]
        # v0.3.8-4: the crew theater rides AFTER the tick (the node sync
        # stays honest; the frames, flip and wobble live in one place)
        for a in allies:
                _ally_theater(a, delta)

## remembers which way an ally's JOB points this tick (the flip eats it)
func _ally_face_target(a: Dictionary, tgt: Variant) -> void:
        if tgt != null:
                a["face_x"] = float((tgt["pos"] as Vector2).x - (a["pos"] as Vector2).x)

func _nearest_enemy(from: Vector2, rng: float) -> Variant:
        var best: Variant = null
        var bd := rng * rng           # v0.3.8-3: squared - no sqrt per body
        for e in enemies:
                var d2: float = (e["pos"] as Vector2).distance_squared_to(from)
                if d2 < bd:
                        bd = d2
                        best = e
        return best

func _ally_bullet(pos: Vector2, a: float, dmg: float, pierce := 0) -> void:
        var spr := Sprite2D.new()
        spr.texture = _t("proj_bolt")
        spr.modulate = Color(0.7, 1, 0.85)
        spr.position = pos
        spr.rotation = a
        spr.z_index = 6
        world.add_child(spr)
        # v0.3.7-1: the drone's L3 piercing rounds ride the pierce param
        bullets.append({"pos": pos, "a": a, "spd": 620.0, "dmg": dmg, "pierce": pierce,
                "hit": {}, "range_left": 420.0, "aoe": 0.0, "burn": false, "chill": 0.0,
                "kind": "bolt", "node": spr, "turn": false, "tier": 1})

# ================================================================ bullets
func _tick_bullets(delta: float) -> void:
        var dead := []
        for b in bullets:
                if b["kind"] == "boomerang":
                        _tick_boomerang(b, delta, dead)
                        continue
                var step: Vector2 = Vector2.from_angle(b["a"]) * float(b["spd"]) * delta
                b["pos"] += step
                b["range_left"] -= step.length()
                b["node"].position = b["pos"]
                if b["kind"] == "orb":
                        # THE GRAVITY WELL: drags enemies while it flies
                        for e in enemies:
                                if e["pos"].distance_to(b["pos"]) < 140.0:
                                        e["pos"] = e["pos"].move_toward(b["pos"], 160.0 * delta)
                if b["range_left"] <= 0.0:
                        if float(b.get("pool", 0.0)) > 0.0:
                                # v0.3.7-1: the bottle lands - the fire pool spreads
                                _fire_pool(b["pos"], float(b["dmg"]),
                                                float(b["pool_r"]), float(b["pool"]))
                        elif float(b["aoe"]) > 0.0:
                                _boom_at(b["pos"], float(b["aoe"]), float(b["dmg"]), false)
                        dead.append(b)
                        continue
                for e in enemies:
                        var key: int = e["uid"]
                        if b["hit"].has(key):
                                continue
                        var hit_r: float = float(e["size"]) * 0.5 * float(e.get("scale_m", 1.0)) + 6.0
                        # v0.3.8-3 THE SHIELD TRUTH: the shield eats the bullet
                        # FIRST, at the shield's own radii - the old code only
                        # checked the rings inside the body's hit radius, so
                        # the carve never ran and the shield could never break
                        # (the owner: "the shield is impossible to break").
                        var reach: float = hit_r
                        if e.get("shield", null) != null:
                                reach = _shield_reach(e)
                        var d2: float = (e["pos"] as Vector2).distance_squared_to(b["pos"])
                        if d2 > reach * reach:
                                continue
                        if e.get("shield", null) != null:
                                var res: int = _shield_block(e, b, float(b["dmg"]))
                                if res == 1 or res == 2:
                                        b["hit"][key] = true
                                        continue     # the orbit kept the bullet
                                # res 0 / 3: past the shield or not there yet
                        if d2 > hit_r * hit_r:
                                continue
                        b["hit"][key] = true
                        var dmg: float = float(b["dmg"])
                        if e.get("marked", false):
                                # v0.3.7-1: the scout's L2 signature deepens the mark
                                dmg *= 1.0 + float(e.get("mark_m", 0.15))
                        if e.get("chill_t", 0.0) > 0.0:
                                dmg *= 1.10
                        dmg *= float(e.get("hurt_m", 1.0))
                        var crit := randf() < float(stats["crit"])
                        if crit:
                                dmg *= float(stats["crit_mult"])
                                Jukebox.sfx("cs_crit", -8.0, 1.2)
                        _hurt_enemy(e, dmg, crit)
                        if b["burn"]:
                                # v0.3.7-1 THE REAL BURN: the DOT scales with the
                                # hit that lit it (the owner: "continuous damage
                                # for specified seconds" - the FLAME TATER is a
                                # flamethrower now, not a match)
                                e["burn_t"] = 3.0
                                e["burn_dps"] = maxf(float(e.get("burn_dps", 0.0)),
                                                float(b["dmg"]) * 0.45)
                        if float(b.get("pool", 0.0)) > 0.0:
                                # the bottle SHATTERS on the first body it meets
                                _fire_pool(b["pos"], float(b["dmg"]),
                                                float(b["pool_r"]), float(b["pool"]))
                                b["range_left"] = 0.0   # it dies this frame
                        if float(b["chill"]) > 0.0:
                                e["chill_t"] = float(b["chill"])
                        if float(b["aoe"]) > 0.0:
                                _boom_at(b["pos"], float(b["aoe"]), float(b["dmg"]) * 0.6, false)
                                dead.append(b)
                                break
                        if int(b["pierce"]) <= 0:
                                dead.append(b)
                                break
                        b["pierce"] = int(b["pierce"]) - 1
        for b2 in dead:
                b2["node"].queue_free()
                bullets.erase(b2)

func _tick_boomerang(b: Dictionary, delta: float, dead: Array) -> void:
        if not b["turn"]:
                var step: Vector2 = Vector2.from_angle(b["a"]) * float(b["spd"]) * delta
                b["pos"] += step
                b["range_left"] -= step.length()
                if b["range_left"] <= 0.0:
                        b["turn"] = true
                        b["hit"] = {}       # the return trip hits again
        else:
                var to_p: Vector2 = p_pos - b["pos"]
                if to_p.length() < 18.0:
                        dead.append(b)
                        return
                b["pos"] += to_p.normalized() * float(b["spd"]) * delta
        b["node"].position = b["pos"]
        b["node"].rotation += 14.0 * delta
        for e in enemies:
                var key: int = e["uid"]
                if b["hit"].has(key):
                        continue
                if e["pos"].distance_to(b["pos"]) < float(e["size"]) * 0.5 + 8.0:
                        b["hit"][key] = true
                        _hurt_enemy(e, float(b["dmg"]), false)

# ================================================================ enemies
var _uid := 0

func _spawn_enemy(kind: String, pos: Vector2, elite := false) -> Dictionary:
        var ed: Dictionary = CSData.ENEMIES[kind]
        var hp: float = float(ed["hp"]) * CSData.hp_scale(run_wave)
        var spd: float = float(ed["spd"]) * CSData.spd_scale(run_wave)
        var dmg: float = float(ed["dmg"]) * CSData.dmg_scale(run_wave)
        var scale_m := 1.0
        var affix := ""
        if elite:
                var keys := CSData.ELITE_AFFIX.keys()
                affix = keys[randi() % keys.size()]
                var ax: Dictionary = CSData.ELITE_AFFIX[affix]
                hp *= 1.6 * float(ax.get("hp", 1.0))
                spd *= float(ax.get("spd", 1.0))
                dmg *= 1.3 * float(ax.get("dmg", 1.0))
                scale_m = float(ax.get("scale", 1.35))
        var spr := Sprite2D.new()
        spr.texture = _t(String(ed["tex"]))
        spr.scale = Vector2.ONE * scale_m
        spr.position = pos
        spr.z_index = 5
        world.add_child(spr)
        _uid += 1
        var e := {
                "uid": _uid, "kind": kind, "name": String(ed["name"]),
                "hp": hp, "max_hp": hp, "spd": spd, "dmg": dmg,
                "size": float(ed["size"]), "pos": pos, "node": spr,
                "scale_m": scale_m, "elite": elite, "affix": affix,
                "xp": int(ed["xp"]), "score": int(ed["score"]),
                "burn_t": 0.0, "burn_tick": 0.0, "chill_t": 0.0,
                "marked": false, "hurt_m": 1.0, "flash": 0.0,
                "shoot_cd": randf_range(0.0, 1.0), "state": "walk", "st": 0.0,
                "boss": false, "gen": 0, "anim": randf() * TAU, "goga": false,
        }
        if kind == "warden":
                _wardens_alive += 1
        if affix == "armored":
                e["hurt_m"] = CSData.ELITE_AFFIX["armored"]["hurt"]
        # v0.3.8-3 THE SHIELD TRUTH: the trishield wears the shatter orbit
        # (unbreakable spinning fragments) + the layer shell (damageable
        # areas, deeper color = higher level)
        if kind == "trishield":
                e["shield"] = _mk_shield(CSData.TRISHIELD_SHARDS,
                                _trishield_layers(run_wave), CSData.TRISHIELD_AREAS,
                                run_wave)
        # THE SPECIAL-KEY LAW (v0.3.4-5 root-cause fix): the enemy dict carries
        # its OWN aura/ward/heal numbers - v0.3.4 left them only in the data
        # table, so the wraith's aura NEVER drew (e.get("aura", 0.0) was
        # always 0 - the owner only ever saw the ring baked into the art)
        # and the warden's guard had nothing to read.
        for special in ["aura", "aura_dps", "ward", "heal"]:
                if ed.has(special):
                        e[special] = float(ed[special])
        enemies.append(e)
        # THE FIRST-GLANCE LAW (v0.3.4-5): the first time a special enemy
        # shows up, one hint banner speaks its truth - once per save.
        if String(ed.get("hint", "")) != "" and not meta.seen_kind(kind):
                meta.mark_seen_kind(kind)
                _banner(String(ed["hint"]), true)
        # the spawn poof (they ARRIVE, they never blink in)
        _rings.append({"pos": pos, "r": float(e["size"]) * 1.6, "t": 0.3, "max": 0.3,
                "col": Color(0.9, 0.4, 0.4), "w": 3.0})
        return e

## THE GOGACOIN RIDER: one random enemy of the milestone wave swallows the
## box's real gogacoin. It glints, it dies, it pays.
func _plant_goga_carrier() -> void:
        if goga_carrier_alive or enemies.is_empty():
                return
        var cands := []
        for x in enemies:
                if not x.get("boss", false) and not x.get("goga", false):
                        cands.append(x)
        if cands.is_empty():
                return
        var e: Dictionary = cands[randi() % cands.size()]
        e["goga"] = true
        goga_carrier_alive = true
        goga_pending = false
        # THE SILENCE LAW: the coin never announces itself - the glint only

func _mk_rings(radii: Array) -> Array:
        # (retired v0.3.8-3 - THE SHIELD TRUTH owns the orbit now)
        return []

# ============================================ THE SHIELD TRUTH (v0.3.8-3)
## THE ALWAYS-A-WAY LAW: the shards are UNBREAKABLE but never cover the
## circle - their spans never fill their own orbit, and the three spin at
## different speeds (some backwards), so a way through is always opening.
## The layer shell is the COMPLETE shield: each layer cut into AREAS; a
## hit lowers the area's LEVEL by the damage taken (in shield units)
## until the area is GONE - a window in that layer. Deeper color = a
## higher level (the owner's own law, from the older game).
const SHIELD_BAND := 7.0          # a shield orbit's hit thickness (+/-)
const SHELL_LV_COLS := [
        Color(0.62, 0.86, 1.0),          # level 1 - pale ice
        Color(0.45, 0.76, 1.0),          # level 2
        Color(0.30, 0.64, 0.98),         # level 3
        Color(0.20, 0.52, 0.95),         # level 4
        Color(0.12, 0.40, 0.88),         # level 5 - the deep cut
]

func _mk_shield(shards: Array, layers: Array, areas_n: int, wave: int) -> Dictionary:
        var arr_shards := []
        for sd in shards:
                arr_shards.append({"r": float(sd["r"]), "span": float(sd["span"]),
                                "spd": float(sd["spd"]), "rot": randf() * TAU})
        # the shield unit scales with the wave so the shell stays a real
        # wall late (one unit = one LEVEL of an area)
        var unit: float = clampf(8.0 * CSData.hp_scale(wave) / CSData.hp_scale(7),
                        8.0, 30.0)
        var arr_layers := []
        for ld in layers:
                var lv: int = mini(5, int(ld["lv"]))
                var areas := []
                for i in areas_n:
                        areas.append({"hp": float(lv), "max": float(lv)})
                arr_layers.append({"r": float(ld["r"]), "areas": areas, "lv": lv})
        return {"shards": arr_shards, "layers": arr_layers, "unit": unit}

## the trishield's shell deepens with the waves (the PRISM wears the full
## five - the PRISM_LAYERS table IS levels 1..5)
func _trishield_layers(wave: int) -> Array:
        var deep: int = mini(2, int(maxi(0, wave - 7) / 10))
        var out: Array = []
        for ld in CSData.TRISHIELD_LAYERS:
                out.append({"r": ld["r"], "lv": mini(5, int(ld["lv"]) + deep)})
        return out

## the farthest orbit this shield owns (+ the band) - a bullet only needs
## the shield's opinion once it crosses this line
func _shield_reach(e: Dictionary) -> float:
        var sh: Dictionary = e["shield"]
        var reach: float = 0.0
        for sd in sh["shards"]:
                reach = maxf(reach, float(sd["r"]))
        for ld in sh["layers"]:
                reach = maxf(reach, float(ld["r"]))
        return reach + SHIELD_BAND

## THE SHIELD READ: what stands between this bullet and the body?
##   0 = nothing at this distance, 1 = a shard blocked it (unbreakable),
##   2 = a shell area ate the hit (its level dropped),
##   3 = through every window - the body is naked from here.
func _shield_block(e: Dictionary, b: Dictionary, dmg: float) -> int:
        var sh: Dictionary = e["shield"]
        var d: float = b["pos"].distance_to(e["pos"])
        var ang: float = (b["pos"] - e["pos"]).angle()
        for sd in sh["shards"]:
                if absf(d - float(sd["r"])) > SHIELD_BAND:
                        continue
                # the shard's arc runs [0, span] in its own rotating frame
                var local := fposmod(ang - float(sd["rot"]), TAU)
                if local <= float(sd["span"]):
                        return 1
        for ld in sh["layers"]:
                if absf(d - float(ld["r"])) > SHIELD_BAND:
                        continue
                var areas: Array = ld["areas"]
                var n := areas.size()
                var w: float = TAU / float(n)
                var idx: int = int(fposmod(ang, TAU) / w) % n
                var area: Dictionary = areas[idx]
                if float(area["hp"]) > 0.0:
                        _chip_shield_area(e, ld, idx, dmg, b["pos"])
                        return 2
                # a window - the bullet flies inward to the next layer
        var layers: Array = sh["layers"]
        var inner_r: float = float(layers[layers.size() - 1]["r"])
        if d < inner_r - SHIELD_BAND:
                return 3
        return 0

## one hit on a shell area: the damage (in shield units) lowers the
## area's level; at zero the cut is REMOVED - the window is open.
func _chip_shield_area(e: Dictionary, ld: Dictionary, idx: int, dmg: float,
                at: Vector2) -> void:
        var sh: Dictionary = e["shield"]
        var area: Dictionary = ld["areas"][idx]
        var was := ceili(float(area["hp"]))
        area["hp"] = maxf(0.0, float(area["hp"]) - maxf(1.0,
                        dmg / float(sh["unit"])))
        var now := ceili(float(area["hp"]))
        Jukebox.sfx("cs_shield_crack", -9.0, 1.05 + 0.1 * float(now))
        _burst(at, [Color(0.62, 0.88, 1.0), Color(0.88, 0.97, 1.0)], 3)
        if now < was:
                _rings.append({"pos": e["pos"], "r": float(ld["r"]),
                                "t": 0.25, "max": 0.25,
                                "col": Color(0.55, 0.85, 1.0), "w": 2.5})
        if now <= 0:
                # THE WINDOW LAW: the cut is gone - the layer has a hole
                Jukebox.sfx("cs_shield_crack", -5.0, 0.72)
                _rings.append({"pos": e["pos"], "r": float(ld["r"]) + 8.0,
                                "t": 0.4, "max": 0.4,
                                "col": Color(0.75, 0.95, 1.0), "w": 4.0})

func _tick_shield(e: Dictionary, delta: float) -> void:
        for sd in e["shield"]["shards"]:
                sd["rot"] = fposmod(float(sd["rot"]) + float(sd["spd"]) * delta,
                                TAU)

## THE MELEE CHEW: the swing bites the outermost alive shell area at the
## swing's angle. Returns true when the shell ATE the swing (no body hit);
## false when the path to the body stands open (every layer windowed there
## - the shards never block the cleaver, the gaps are everywhere).
func _melee_chew_shield(e: Dictionary, swing_a: float, dmg: float) -> bool:
        var sh: Dictionary = e["shield"]
        var layers: Array = sh["layers"]
        if layers.is_empty():
                return false
        var outer: Dictionary = layers[0]   # the data is outer-first
        var areas: Array = outer["areas"]
        var n := areas.size()
        var w: float = TAU / float(n)
        var idx: int = int(fposmod(swing_a, TAU) / w) % n
        if float(areas[idx]["hp"]) <= 0.0:
                return false    # the window is here - the body takes it
        var at: Vector2 = e["pos"] + Vector2.from_angle(swing_a) * float(outer["r"])
        _chip_shield_area(e, outer, idx, dmg, at)
        return true

func _tick_enemies(delta: float) -> void:
        var to_kill := []
        for e in enemies:
                if e.get("dead", false):
                        continue
                e["st"] += delta
                # statuses
                if e["burn_t"] > 0.0:
                        e["burn_t"] -= delta
                        e["burn_tick"] -= delta
                        if e["burn_tick"] <= 0.0:
                                e["burn_tick"] = 0.5
                                # v0.3.7-1: the DOT reads the burn's own dps now
                                _hurt_enemy(e, maxf(1.0,
                                                float(e.get("burn_dps", 2.0)) * 0.5),
                                                false, true)
                                # the fire really burns - a flame mote peels off
                                _parts.append({"pos": e["pos"] \
                                                + Vector2(randf_range(-8, 8), -6),
                                                "vel": Vector2(randf_range(-20, 20), -randf_range(60, 140)),
                                                "t": 0.4, "max": 0.4,
                                                "col": Color(1.0, 0.55, 0.15),
                                                "size": randf_range(3.0, 6.0), "tex": ""})
                if e["chill_t"] > 0.0:
                        e["chill_t"] -= delta
                # v0.3.8-2: the chill STRENGTH is per-enemy now (the frost
                # aura's level owns it - 0.7 base, down to 0.54 at L5; the
                # frost weapon keeps the plain 0.8 default)
                var slow: float = float(e.get("chill_m", 0.8)) \
                                if e["chill_t"] > 0.0 else 1.0
                var spd: float = float(e["spd"]) * slow
                var to_p: Vector2 = p_pos - e["pos"]
                var dist: float = to_p.length()
                var kind: String = e["kind"]
                var moved := false
                # ===== the per-kind AI =====
                # v0.3.8-3 THE KNOCK DECAY: a contact ram SHOVES the body
                # away - the shove rides out here (before the node sync)
                if e.get("knock", Vector2.ZERO) != Vector2.ZERO:
                        e["pos"] += (e["knock"] as Vector2) * delta
                        e["knock"] = (e["knock"] as Vector2).move_toward(
                                        Vector2.ZERO, 1100.0 * delta)
                if e.get("boss", false):
                        _boss_ai(e, delta, to_p, dist)
                        moved = true
                elif kind == "spitter":
                        var keep: float = 260.0
                        var want: Vector2 = to_p.normalized()
                        if dist > keep + 40.0:
                                e["pos"] += want * spd * delta
                                moved = true
                        elif dist < keep - 40.0:
                                e["pos"] -= want * spd * delta
                                moved = true
                        else:
                                e["pos"] += want.orthogonal() * spd * 0.6 * delta
                                moved = true
                        e["shoot_cd"] -= delta
                        if e["shoot_cd"] <= 0.0:
                                e["shoot_cd"] = 2.2
                                _enemy_bullet(e["pos"], to_p.angle(), float(e["dmg"]))
                elif kind == "charger":
                        if e["state"] == "walk":
                                e["pos"] += to_p.normalized() * spd * delta
                                moved = true
                                if dist < 300.0:
                                        e["state"] = "wind"
                                        e["st"] = 0.0
                        elif e["state"] == "wind":
                                if e["st"] >= 0.6:
                                        e["state"] = "dash"
                                        e["st"] = 0.0
                                        e["dash_dir"] = to_p.normalized()
                        elif e["state"] == "dash":
                                e["pos"] += Vector2(e["dash_dir"]) * spd * 3.0 * delta
                                moved = true
                                if e["st"] >= 0.5:
                                        e["state"] = "rest"
                                        e["st"] = 0.0
                        elif e["state"] == "rest":
                                if e["st"] >= 0.8:
                                        e["state"] = "walk"
                elif kind == "orbiter":
                        if e["state"] == "walk":
                                var ang: float = (e["pos"] - p_pos).angle() + 1.9 * delta
                                e["pos"] = p_pos + Vector2.from_angle(ang) * 180.0
                                moved = true
                                if e["st"] > randf_range(3.0, 5.0):
                                        e["state"] = "dive"
                                        e["st"] = 0.0
                        elif e["state"] == "dive":
                                e["pos"] += to_p.normalized() * spd * 2.4 * delta
                                moved = true
                                if dist < 26.0 or e["st"] > 1.6:
                                        e["state"] = "walk"
                                        e["st"] = 0.0
                elif kind == "boomling":
                        if dist < 90.0 and e["state"] != "fuse":
                                e["state"] = "fuse"
                                e["st"] = 0.0
                        if e["state"] == "fuse":
                                spd = 0.0
                                if e["st"] >= 0.7:
                                        _boom_at(e["pos"], 60.0, 25.0 * CSData.dmg_scale(run_wave), true)
                                        to_kill.append(e)
                                        continue
                        else:
                                e["pos"] += to_p.normalized() * spd * delta
                                moved = true
                else:
                        # the chase law (the python base)
                        e["pos"] += to_p.normalized() * spd * delta
                        moved = true
                # ===== THE NODE-SYNC LAW (the patch-1 headline: the sprite
                # FOLLOWS the body every tick - v0.3.4 left it at the spawn) =====
                var nd: Sprite2D = e["node"]
                nd.position = e["pos"]
                # the walk theatre: a waddle squash + a lean + the flip
                if moved and spd > 0.1:
                        e["anim"] += delta * (4.0 + spd * 0.022)
                var base_s: float = float(e.get("scale_m", 1.0))
                var wob := 0.05 * sin(e["anim"] * TAU)
                nd.scale = Vector2(base_s * (1.0 + wob), base_s * (1.0 - wob))
                if to_p.x != 0.0:
                        nd.flip_h = to_p.x < 0.0
                # ===== the auras =====
                if kind == "wraith" or e.get("aura", 0.0) > 0.0:
                        if dist < float(e.get("aura", 250.0)) and p_iframe <= 0.0:
                                e["aura_tick"] = float(e.get("aura_tick", 0.0)) - delta
                                if e["aura_tick"] <= 0.0:
                                        e["aura_tick"] = 1.0
                                        _hurt_player(float(e.get("aura_dps", 15.0)), e)
                                        # THE WRAITH TRUTH LAW (v0.3.4-5): the tick
                                        # SPEAKS - a violet pulse rides the ring
                                        # (the owner felt damage with no feedback)
                                        _rings.append({"pos": e["pos"],
                                                        "r": float(e.get("aura", 250.0)),
                                                        "t": 0.4, "max": 0.4,
                                                        "col": Color(0.8, 0.4, 1.0), "w": 5.0})
                if kind == "mender":
                        e["heal_tick"] = float(e.get("heal_tick", 0.0)) - delta
                        if e["heal_tick"] <= 0.0:
                                e["heal_tick"] = 0.5
                                for o in enemies:
                                        if o == e or o.get("dead", false):
                                                continue
                                        if o["pos"].distance_to(e["pos"]) < 500.0:
                                                o["hp"] = minf(float(o["max_hp"]), float(o["hp"]) + 10.0)
                                                _heal_flash(o)
                if e.get("shield", null) != null:
                        _tick_shield(e, delta)
                # ===== THE SHARED CONTACT LAW (v0.3.4-3): colliding damages
                # BOTH sides and EVERY tick speaks - the old splatter law
                # (remaining HP as damage, then silent iframes) is DEAD.
                # v0.3.8-3 THE STALEMATE LAW (the owner: "some enemies when
                # collide... the enemy stays stuck following me in a weird
                # way... at least it should have been already died"): the
                # collision is a FIGHT now - the ram bites harder every
                # wave, the body that survives gets KNOCKED back so it can
                # never grind at the player's heels, and no body overlaps
                # the potato: they press on the rim, never inside it.
                var touch_r: float = float(e["size"]) * 0.5 * float(e.get("scale_m", 1.0)) + PLAYER_R - 6.0
                if e.get("boss", false):
                        touch_r = float(e["size"]) * 0.5 + PLAYER_R - 10.0
                if dist < touch_r:
                        # THE RIM TRUTH: the enemy presses against the
                        # potato's rim - never inside it (the walk-through
                        # and the weird heel-hugging are the same bug)
                        var away: Vector2 = to_p.normalized()
                        e["pos"] = e["pos"] - away * (touch_r - dist)
                        e["touch_cd"] = float(e.get("touch_cd", 0.0)) - delta
                        if e["touch_cd"] <= 0.0:
                                e["touch_cd"] = 0.55
                                e["knock"] = away * CONTACT_KNOCK
                                _contact_hit(e)
                                # the ram may have splattered the enemy -
                                # never touch the corpse again this tick
                                if e.get("dead", false):
                                        continue
                # the flash decay
                if e["flash"] > 0.0:
                        e["flash"] -= delta
                # v0.3.7-1 THE CHARRED LAW ("fire really burn their skins"):
                # a burning enemy wears its char - dark, still smoking
                if e.get("burn_t", 0.0) > 0.0:
                        nd.modulate = Color(0.42, 0.30, 0.24)
                elif e["flash"] > 0.0:
                        nd.modulate = Color(3, 3, 3)
                elif e.get("goga", false):
                        nd.modulate = Color(1.25, 1.2, 0.8)
                else:
                        nd.modulate = Color(1, 1, 1)
                    # the gogacoin glint
                if e.get("goga", false) and e["flash"] <= 0.0:
                        nd.modulate = Color(1.25, 1.2, 0.8)
        # the flocking separation (the python law: 100px, force (1-d/100)*0.5)
        # v0.3.8-3 THE SQUARED GUARD: the far pairs pay length_squared only -
        # the sqrt runs for the close pairs alone (the 80x80 walk drops its
        # 6400 sqrts to ~the near-neighbour count)
        if enemies.size() <= 80:
                for i in enemies.size():
                        var a: Dictionary = enemies[i]
                        if a.get("dead", false) or a.get("boss", false):
                                continue
                        var push := Vector2.ZERO
                        var apos: Vector2 = a["pos"]
                        for j in enemies.size():
                                if i == j:
                                        continue
                                var b: Dictionary = enemies[j]
                                var dd: Vector2 = apos - (b["pos"] as Vector2)
                                var dl2 := dd.length_squared()
                                if dl2 < 10000.0 and dl2 > 0.01:
                                        var dl := sqrt(dl2)
                                        push += dd * ((100.0 - dl) / (100.0 * dl))
                        apos += push * 0.5 * 60.0 * delta
                        apos += Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3)) * 60.0 * delta
                        a["pos"] = apos
                        # THE NODE-SYNC LAW holds even after the flock nudge
                        (a["node"] as Sprite2D).position = apos
        for e2 in to_kill:
                # a contact-splattered carrier still coughs up its coin
                if e2.get("goga", false):
                        goga_carrier_alive = false
                        _drop_pickup("gogacoin", e2["pos"], 1)
                        e2["goga"] = false
                _kill_enemy(e2, false)
        # the milestone owes its carrier - plant it on the living swarm
        if goga_pending and phase == "play":
                _plant_goga_carrier()

func _enemy_bullet(pos: Vector2, a: float, dmg: float) -> void:
        var spr := Sprite2D.new()
        spr.texture = _t("proj_spit")
        spr.position = pos
        spr.rotation = a
        spr.z_index = 6
        world.add_child(spr)
        ebullets.append({"pos": pos, "a": a, "spd": 300.0, "dmg": dmg,
                "node": spr, "life": 3.0})

func _tick_ebullets(delta: float) -> void:
        var dead := []
        for b in ebullets:
                b["pos"] += Vector2.from_angle(b["a"]) * float(b["spd"]) * delta
                b["life"] -= delta
                b["node"].position = b["pos"]
                if b["life"] <= 0.0:
                        dead.append(b)
                        continue
                # THE GHOST ROUND (the meta skill): a shot that hits Spudnik
                # PASSES THROUGH, poisoned against its own masters - the
                # level's own fraction strikes the enemies behind, and the
                # L3+ turned shot drills through more than one body.
                if b.get("ghosted", false):
                        for e in enemies:
                                if e.get("dead", false):
                                        continue
                                if e["pos"].distance_to(b["pos"]) < float(e["size"]) * 0.5 + 8.0:
                                        _hurt_enemy(e, float(b["dmg"]) * float(b["ghost_frac"]))
                                        b["ghost_left"] = int(b.get("ghost_left", 0)) - 1
                                        if int(b["ghost_left"]) <= 0:
                                                dead.append(b)
                                        break
                        continue     # a turned shot never re-hits the body
                if b["pos"].distance_to(p_pos) < PLAYER_R + 6.0:
                        _hurt_player(float(b["dmg"]), null)
                        if meta.has_skill("ghost_round"):
                                var gh_lv := meta.skill_level("ghost_round")
                                b["ghosted"] = true
                                b["ghost_frac"] = float(CSData.skill_num("ghost_round",
                                                "frac", gh_lv, 0.5))
                                b["ghost_left"] = 1 + int(CSData.skill_num("ghost_round",
                                                "pierce", gh_lv, 0))
                                b["life"] = minf(float(b["life"]), 2.0)
                                b["node"].modulate = Color(0.6, 1.0, 0.7, 0.9)
                                continue     # the shot flies on, turned
                        dead.append(b)
                        continue
        for b2 in dead:
                b2["node"].queue_free()
                ebullets.erase(b2)

## THE SKILLS TICK (v0.3.4-3): the meta perks live in the run loop.
func _tick_skills(delta: float) -> void:
        if phase != "play":
                return
        # the shield reform clock (the level's reform law)
        if meta.has_skill("shattered_shield") and not p_shield_up:
                p_shield_cd -= delta
                if p_shield_cd <= 0.0:
                        p_shield_up = true
                        p_shield_charges = int(CSData.skill_num("shattered_shield",
                                        "charges", meta.skill_level("shattered_shield"), 1))
                        _sparkle(p_pos, Color(0.5, 0.85, 1.0))
        # THE ADRENALINE ROOT decays
        if _adrenaline > 0.0:
                _adrenaline = maxf(0.0, _adrenaline - delta)
        if meta.has_skill("leech_aura"):
                var lee_lv := meta.skill_level("leech_aura")
                var lee_r: float = float(CSData.skill_num("leech_aura", "radius", lee_lv, 140.0))
                var lee_dps: float = float(CSData.skill_num("leech_aura", "dps", lee_lv, 2.0))
                var lee_cap: int = int(CSData.skill_num("leech_aura", "cap", lee_lv, 3))
                var near := 0
                for e in enemies:
                        if e.get("dead", false) or near >= lee_cap:
                                continue
                        if e["pos"].distance_to(p_pos) < lee_r:
                                near += 1
                                p_hp = minf(p_max_hp, p_hp + lee_dps * delta)
        if meta.has_skill("frost_aura"):
                var fr_lv := meta.skill_level("frost_aura")
                var fr_r: float = float(CSData.skill_num("frost_aura", "radius", fr_lv, 170.0))
                var fr_slow: float = float(CSData.skill_num("frost_aura", "slow", fr_lv, 0.70))
                for e2 in enemies:
                        if not e2.get("dead", false) and e2["pos"].distance_to(p_pos) < fr_r:
                                e2["chill_t"] = maxf(float(e2.get("chill_t", 0.0)), 0.2)
                                # v0.3.8-2: the level's OWN freeze strength rides along
                                e2["chill_m"] = minf(float(e2.get("chill_m", 1.0)), fr_slow)
        if meta.has_skill("static_burst"):
                var st_lv := meta.skill_level("static_burst")
                _static_cd -= delta
                if _static_cd <= 0.0 and not enemies.is_empty():
                        _static_cd = float(CSData.skill_num("static_burst", "period", st_lv, 6.0))
                        var st_n: int = int(CSData.skill_num("static_burst", "targets", st_lv, 3))
                        var st_m: float = float(CSData.skill_num("static_burst", "dmg_m", st_lv, 1.0))
                        var st_chill: float = float(CSData.skill_num("static_burst", "chill", st_lv, 0.0))
                        var targets: Array = enemies.duplicate()
                        targets.sort_custom(func(x, y):
                                return x["pos"].distance_squared_to(p_pos) \
                                                < y["pos"].distance_squared_to(p_pos))
                        var zapped := 0
                        for t in targets:
                                if zapped >= st_n:
                                        break
                                if t["pos"].distance_to(p_pos) > 320.0:
                                        break
                                _hurt_enemy(t, (12.0 + float(run_wave) * 2.0) * st_m)
                                if st_chill > 0.0:
                                        t["chill_t"] = maxf(float(t.get("chill_t", 0.0)), st_chill)
                                _rings.append({"pos": t["pos"], "r": 26.0, "t": 0.25,
                                        "max": 0.25, "col": CS_BLUE, "w": 3.0})
                                zapped += 1
                        if zapped > 0:
                                Jukebox.sfx("cs_flash", -6.0, 1.3)

func _boss_ai(e: Dictionary, delta: float, to_p: Vector2, dist: float) -> void:
        var b: Dictionary = e["bdata"]
        if b.get("self_mend", 0.0) > 0.0:
                e["hp"] = minf(float(e["max_hp"]), float(e["hp"]) + float(b["self_mend"]) * delta)
        if b.get("burst", false) and e["state"] != "burst":
                e["burst_cd"] = float(e.get("burst_cd", 3.0)) - delta
                if e["burst_cd"] <= 0.0:
                        e["burst_cd"] = 4.0
                        e["state"] = "burst"
                        e["st"] = 0.0
                        var n := 14
                        for i in n:
                                _enemy_bullet(e["pos"], float(i) / float(n) * TAU, float(e["dmg"]) * 0.6)
                        Jukebox.sfx("cs_boom", -8.0, 0.8)
        if b.get("slam", false):
                e["slam_cd"] = float(e.get("slam_cd", 3.5)) - delta
                if e["slam_cd"] <= 0.0 and dist < 260.0:
                        e["slam_cd"] = 5.0
                        zones.append({"kind": "slam", "pos": p_pos, "t": 0.8, "max": 0.8,
                                "dmg": float(e["dmg"]), "aoe": 120.0})
        if b.get("charge", false) or b.get("triple_charge", false):
                e["charge_cd"] = float(e.get("charge_cd", 2.0)) - delta
                if e["state"] == "walk" and e["charge_cd"] <= 0.0 and dist < 500.0:
                        e["state"] = "wind"
                        e["st"] = 0.0
                        e["charges_left"] = 3 if b.get("triple_charge", false) else 1
                elif e["state"] == "wind":
                        e["spd_m"] = 0.0
                        if e["st"] >= 0.55:
                                e["state"] = "dash"
                                e["st"] = 0.0
                                e["dash_dir"] = to_p.normalized()
                elif e["state"] == "dash":
                        e["pos"] += Vector2(e["dash_dir"]) * float(e["spd"]) * 3.4 * delta
                        if e["st"] >= 0.45:
                                e["charges_left"] = int(e.get("charges_left", 1)) - 1
                                e["tp_count"] = int(e.get("tp_count", 0)) + 1
                                if int(e.get("teleport", 0)) > 0 \
                                                and e["tp_count"] % int(e["teleport"]) == 0:
                                        e["pos"] = p_pos - to_p.normalized() * 140.0
                                if int(e["charges_left"]) > 0:
                                        e["state"] = "wind"
                                        e["st"] = 0.4
                                else:
                                        e["state"] = "walk"
                                        e["charge_cd"] = 3.2
        if b.get("summon", "") != "":
                e["summon_cd"] = float(e.get("summon_cd", 8.0)) - delta
                var hp_frac := float(e["hp"]) / float(e["max_hp"])
                if e["summon_cd"] <= 0.0 and (hp_frac < 0.66 or hp_frac < 0.33):
                        e["summon_cd"] = 9.0
                        for i in int(b["summon_n"]):
                                _spawn_enemy(String(b["summon"]), e["pos"]
                                                + Vector2.from_angle(randf() * TAU) * 70.0)
                        Jukebox.sfx("cs_boss_roar", -4.0)
        if e["state"] != "dash" and e["state"] != "wind":
                e["pos"] += to_p.normalized() * float(e["spd"]) * delta
        if e.get("aura", 0.0) > 0.0 and dist < float(e["aura"]) and p_iframe <= 0.0:
                e["aura_tick"] = float(e.get("aura_tick", 0.0)) - delta
                if e["aura_tick"] <= 0.0:
                        e["aura_tick"] = 1.0
                        _hurt_player(float(e["aura_dps"]), e)

func _spawn_boss(wave: int) -> void:
        var cycle := int((wave - 1) / CSData.BOSS_CYCLE)   # 0-based
        var bid: String = CSData.BOSS_ORDER[cycle % CSData.BOSS_ORDER.size()]
        var bd: Dictionary = CSData.BOSSES[bid]
        var m := pow(CSData.BOSS_CYCLE_MULT, float(cycle))
        var e := _spawn_enemy("blab", p_pos + Vector2(0, -420), false)
        e["kind"] = bid
        e["name"] = String(bd["name"])
        e["hp"] = float(bd["hp"]) * m
        e["max_hp"] = e["hp"]
        e["spd"] = float(bd["spd"])
        e["dmg"] = float(bd["dmg"]) * m
        e["size"] = float(bd["size"])
        e["xp"] = int(bd["xp"])
        e["score"] = int(bd["score"]) + cycle * CSData.BOSS_CYCLE_SCORE
        e["coins_drop"] = int(ceil(float(bd["coins"]) * m))
        e["boss"] = true
        e["bdata"] = bd
        e["node"].texture = _t(String(bd["tex"]))
        e["node"].scale = Vector2.ONE * 1.6
        e["scale_m"] = 1.6
        if bd.get("shield", false):
                e["shield"] = _mk_shield(CSData.PRISM_SHARDS, CSData.PRISM_LAYERS,
                                CSData.PRISM_AREAS, wave)
        boss_alive = true
        Jukebox.sfx("cs_boss_roar", -2.0)
        Jukebox.music("res://assets/audio/music/cs_boss.ogg")
        _banner("%s ARRIVES!" % String(bd["name"]), false)

## THE WARDEN's guard (v0.3.4-5): 0.5 while `e` stands inside a living
## warden's gold ring - the warden never wards itself.
## v0.3.8-3 THE WARDEN CACHE: the scan only runs while a warden LIVES -
## the count rides the spawn/kill paths, so the common case is one int
## compare instead of an O(n) walk per hit.
var _wardens_alive := 0

func _ward_cut(e: Dictionary) -> float:
        if _wardens_alive <= 0:
                return 1.0
        for w in enemies:
                if w == e or w.get("dead", false):
                        continue
                if String(w.get("kind", "")) != "warden":
                        continue
                if e["pos"].distance_to(w["pos"]) < float(w.get("ward", 0.0)):
                        return 0.5
        return 1.0

# ================================================================ damage
func _hurt_enemy(e: Dictionary, dmg: float, crit := false, silent := false) -> void:
        if e.get("dead", false):
                return
        dmg *= _ward_cut(e)
        e["hp"] = float(e["hp"]) - dmg
        e["flash"] = 0.06
        # v0.3.7-1 THE BLOOD LAW (the extra round: "if there is blood..."):
        # every real hit sprays - the DoT ticks stay quiet (silent)
        if not silent:
                _burst(e["pos"], [Color(0.62, 0.11, 0.09), Color(0.45, 0.08, 0.07)],
                                2 + (2 if crit else 0))
        if not silent:
                _dmg_number(e["pos"], dmg, crit)
        if float(stats["lifesteal"]) > 0.0 and not silent:
                p_hp = minf(p_max_hp, p_hp + dmg * float(stats["lifesteal"]))
        if e["hp"] <= 0.0:
                _kill_enemy(e, true)

func _kill_enemy(e: Dictionary, drops: bool) -> void:
        if e.get("dead", false):
                return
        e["dead"] = true
        if String(e.get("kind", "")) == "warden":
                _wardens_alive = maxi(0, _wardens_alive - 1)
        run_kills += 1
        var sc := int(e["score"])
        if e.get("elite", false):
                sc += CSData.ELITE_SCORE
        add_score(sc)
        _death_burst(e)
        Jukebox.sfx("cs_kill_big" if e.get("boss", false) else "cs_hit", -7.0,
                        randf_range(0.8, 1.3) if not e.get("boss", false) else 0.7)
        if drops:
                _drop_pickup("xp", e["pos"], int(e["xp"]) * 2)
                var coin_m: float = float(stats["coin_m"])
                var luck: float = float(stats.get("luck", 0.0))
                # THE GOGACOIN RIDER drops first (the owner's new feature)
                if e.get("goga", false):
                        goga_carrier_alive = false
                        _drop_pickup("gogacoin", e["pos"], 1)
                        # THE SILENCE LAW: no banner - the glint was the tell
                if e.get("coins_drop", 0) > 0:
                        for i in int(e["coins_drop"]):
                                _drop_pickup("coin", e["pos"] + Vector2.from_angle(randf() * TAU) * 20.0,
                                                maxi(1, int(round(coin_m))))
                elif e.get("elite", false):
                        for i in randi_range(3, 6):
                                _drop_pickup("coin", e["pos"] + Vector2.from_angle(randf() * TAU) * 20.0,
                                                maxi(1, int(round(coin_m))))
                elif randf() < 0.08 * (1.0 + luck):
                        _drop_pickup("coin", e["pos"], maxi(1, int(round(1 * coin_m))))
                if randf() < 0.06 * (1.0 + luck):
                        _drop_pickup("heart", e["pos"], 15)
                var kind: String = e["kind"]
                if kind == "brood":
                        for i in 2:
                                _spawn_enemy("minion", e["pos"] + Vector2(-20 + i * 40, 10))
                elif kind == "splitter":
                        var gen: int = int(e.get("gen", 0))
                        if gen < 2:
                                for i in 2:
                                        var s := _spawn_enemy("splitter", e["pos"]
                                                        + Vector2.from_angle(randf() * TAU) * 24.0)
                                        s["hp"] = float(e["max_hp"]) * 0.3
                                        s["max_hp"] = s["hp"]
                                        s["spd"] = float(s["spd"]) * 1.10
                                        s["gen"] = gen + 1
                                        s["size"] = float(s["size"]) * 0.75
                                        s["node"].scale = Vector2.ONE * 0.75
        if e.get("boss", false):
                boss_alive = false
                Jukebox.sfx("cs_boom_big", -2.0)
                _shake = 10.0
                var th: Dictionary = CSData.THEMES[theme_id]
                Jukebox.music(th["night_music"] if night else th["day_music"])
        enemies.erase(e)
        e["node"].queue_free()

func _hurt_player(dmg: float, src: Variant, contact := false) -> void:
        if over or phase != "play":
                return
        # THE SHARED CONTACT LAW: a contact tick NEVER hides behind the long
        # iframe - an ongoing collision always lands its damage AND its
        # feedback (the owner's "still get hit with no feedback" bug). It
        # only takes the SHORT guard so five bodies can't land on one frame.
        if not contact and p_iframe > 0.0:
                return
        # THE SHATTERED SHIELD (the meta skill): one hit is eaten whole and
        # the shield shatters into blue dust, reforming on the level's own
        # clock. v0.3.8-2: L4's shatter BURSTS (25 dmg in 150px), L5 wears
        # TWO charges.
        if p_shield_up and meta.has_skill("shattered_shield"):
                var sh_lv := meta.skill_level("shattered_shield")
                p_shield_charges -= 1
                p_shield_up = p_shield_charges > 0
                p_shield_cd = float(CSData.skill_num("shattered_shield",
                                "reform", sh_lv, 12.0))
                var sh_burst: float = float(CSData.skill_num("shattered_shield",
                                "burst", sh_lv, 0.0))
                if sh_burst > 0.0:
                        _boom_at(p_pos, 150.0, sh_burst, false)
                _rings.append({"pos": p_pos, "r": 46.0, "t": 0.4, "max": 0.4,
                        "col": Color(0.45, 0.8, 1.0), "w": 5.0})
                _sparkle(p_pos, Color(0.5, 0.85, 1.0))
                Jukebox.sfx("cs_shield_crack", -3.0, 0.8)
                _dmg_number(p_pos, 0.0, false, CS_BLUE)
                _floaters[_floaters.size() - 1]["txt"] = "BLOCKED!"
                return
        # THE DODGE LAW (patch 1): a real chance to no-hit, capped at 60%
        var dodge := clampf(float(stats.get("dodge", 0.0)), 0.0, 0.6)
        if dodge > 0.0 and randf() < dodge:
                _dmg_number(p_pos, 0.0, false, CS_BLUE)
                _floaters[_floaters.size() - 1]["txt"] = "DODGE!"
                Jukebox.sfx("cs_flash", -12.0, 1.6)
                # THE ADRENALINE ROOT: a dodge revs the guns (the level's own
                # duration) - L3+ heals, L5+ speeds the legs
                if meta.has_skill("adrenaline"):
                        var ad_lv := meta.skill_level("adrenaline")
                        _adrenaline = float(CSData.skill_num("adrenaline", "dur", ad_lv, 2.0))
                        var ad_heal: float = float(CSData.skill_num("adrenaline", "heal", ad_lv, 0.0))
                        if ad_heal > 0.0:
                                p_hp = minf(p_max_hp, p_hp + ad_heal)
                return
        # THE GUARD AURA (v0.3.5-5 THE ALLY VARIETY LAW): a deployed GUARD
        # SPUD hardens the potato inside its ring - the incoming damage
        # shrinks before armor. The BEST guard's ring counts once; two
        # guards never stack the shield (allies do not die, upgrades exist,
        # level 1 stays humble: 12% at lv1, 20% at lv3).
        var guard_cut := 0.0
        for a in allies:
                if String(a["id"]) != "guard":
                        continue
                if p_pos.distance_to(a["pos"]) > GUARD_AURA:
                        continue
                guard_cut = maxf(guard_cut, 0.12 + 0.04 * float(int(a["level"]) - 1))
        if guard_cut > 0.0:
                dmg *= 1.0 - guard_cut
        var actual: float = maxf(1.0, dmg - float(stats["armor"]))
        p_hp -= actual
        p_iframe = 0.28 if contact else IFRAME
        _dmg_number(p_pos, actual, false, Color(1, 0.5, 0.5))
        Jukebox.sfx("cs_hurt", -4.0)
        _shake = maxf(_shake, 5.0)
        if src != null and src is Dictionary and (src as Dictionary).get("affix", "") == "vampiric":
                var s: Dictionary = src
                s["hp"] = minf(float(s["max_hp"]), float(s["hp"]) + actual * 0.2)
        if p_hp <= 0.0:
                if meta.tree_node("d4") and not second_wind_used:
                        second_wind_used = true
                        p_hp = p_max_hp * 0.5
                        _banner("SECOND WIND!", false)
                        Jukebox.sfx("cs_levelup", -2.0)
                        _boom_at(p_pos, 260.0, 40.0, true)
                        return
                _die()

## THE SHARED CONTACT LAW (v0.3.4-3): one tick of an ongoing collision.
## The enemy ATTACKS the potato; the potato RAMS back. Both sides wear
## their numbers, the thud speaks, the dust flies - every single tick.
## v0.3.8-3 THE RAM TRUTH (the owner: "at least it should have been
## already died"): the ram scales with the waves now - trash bodies
## splatter on the rim in a tick or two, tanks feel the grind but the
## knock never lets them pin the potato.
func _contact_hit(e: Dictionary) -> void:
        var hit_at: Vector2 = (p_pos + e["pos"]) * 0.5
        # ---- the enemy's attack (armor + dodge + contact_cut apply)
        _hurt_player(float(e["dmg"]) * float(stats["contact_cut"]), e, true)
        if p_hp <= 0.0 or over:
                return
        # ---- THE RAM: the potato shoves back (the wave-scaled floor or
        # 8% of the enemy's max HP, +3 flat, +1 per armor point; bosses
        # take half)
        var ram: float = maxf(float(e["max_hp"]) * 0.08,
                        18.0 + float(run_wave) * 1.6) + 3.0 + float(stats["armor"])
        if e.get("boss", false):
                ram *= 0.5
        _hurt_enemy(e, ram)
        # the dust + the thud
        for i in 6:
                var a := randf() * TAU
                _parts.append({"pos": hit_at, "vel": Vector2.from_angle(a) * randf_range(60.0, 180.0),
                        "t": 0.25, "max": 0.25, "col": Color(0.85, 0.78, 0.6),
                        "size": randf_range(2.5, 5.0), "tex": ""})
        _rings.append({"pos": hit_at, "r": 22.0, "t": 0.22, "max": 0.22,
                "col": Color(1, 0.75, 0.45), "w": 3.0})
        Jukebox.sfx("cs_hit", -8.0, randf_range(0.55, 0.7))
        _shake = maxf(_shake, 3.0)

# ================================================================ pickups
## v0.3.5-6 THE EXPIRE LAW (the owner: "dropped stuff do not expire, I
## mean XP, CC, LP and more, they never vanish, giving them a time to
## fade out if not collected will make the game more better"): every
## world drop lives PICKUP_LIFE seconds, blinks through its last
## PICKUP_FADE seconds and vanishes. The GOGACoin is the exception - it
## waits forever like the trophy it is.
const PICKUP_LIFE := 14.0
const PICKUP_FADE := 3.5

func _drop_pickup(kind: String, pos: Vector2, v: int) -> void:
        var spr := Sprite2D.new()
        spr.texture = _t(kind)
        spr.position = pos
        if kind == "gogacoin":
                # THE COIN SIZE LAW (v0.3.4-3, the owner: "the gogacoins
                # appear in the game are very very weirdly HUGE"): the box's
                # big ui coin art lands in the world at pickup scale.
                spr.scale = Vector2.ONE * 0.16
        spr.z_index = 4
        world.add_child(spr)
        pickups.append({"kind": kind, "v": v, "pos": pos, "node": spr,
                        "bob": randf() * TAU,
                        "life": PICKUP_LIFE if kind != "gogacoin" else -1.0})

func _tick_pickups(delta: float) -> void:
        var dead := []
        var magnet: float = MAGNET_BASE * float(stats["magnet"])
        if meta.has_skill("magnetic_skin"):
                magnet *= float(CSData.skill_num("magnetic_skin", "reach",
                                meta.skill_level("magnetic_skin"), 1.6))
        for pk in pickups:
                pk["bob"] += delta * 4.0
                pk["node"].position = pk["pos"] + Vector2(0, sin(pk["bob"]) * 3.0)
                # v0.3.5-6 THE EXPIRE LAW: the drop's own clock - blink and
                # fade through the last window, then vanish un-collected
                if float(pk.get("life", -1.0)) > 0.0:
                        pk["life"] = float(pk["life"]) - delta
                        var lf := float(pk["life"])
                        if lf <= 0.0:
                                dead.append(pk)
                                continue
                        if lf < PICKUP_FADE:
                                var fk := lf / PICKUP_FADE
                                (pk["node"] as Sprite2D).modulate.a = clampf(
                                                fk * (0.55 + 0.45 * absf(sin(lf * 9.0))),
                                                0.0, 1.0)
                var to_p: Vector2 = p_pos - pk["pos"]
                var d := to_p.length()
                if String(pk["kind"]) == "gogacoin":
                        pass    # the gogacoin waits like a trophy - no magnet chase
                elif d < magnet:
                        pk["pos"] += to_p.normalized() * 340.0 * delta
                if d < PLAYER_R + 12.0:
                        match String(pk["kind"]):
                                "xp":
                                        run_xp += int(pk["v"])
                                        Jukebox.sfx("cs_xp", -10.0, randf_range(0.95, 1.1))
                                        while run_xp >= CSData.xp_for_run_level(run_level):
                                                run_xp -= CSData.xp_for_run_level(run_level)
                                                run_level += 1
                                                pending_levels += 1
                                                # v0.3.8-2 THE STAT POINTS LAW: every
                                                # level mints a LIFETIME point -
                                                # banked even if the run dies this second
                                                meta.mint_stat_pts(1)
                                                # THE WOW PASS: the level-up burst
                                                _rings.append({"pos": p_pos, "r": 70.0,
                                                        "t": 0.5, "max": 0.5,
                                                        "col": CS_BLUE, "w": 5.0})
                                        # THE BREAK CHAIN LAW (v0.3.4-3): a
                                        # level-up NEVER interrupts the wave -
                                        # the STATS menu waits for the break.
                                "coin":
                                        _cc_earn(int(pk["v"]))
                                        Jukebox.sfx("cs_coin", -8.0)
                                        _sparkle(pk["pos"], CS_YELLOW)
                                "heart":
                                        var heal := float(pk["v"])
                                        if meta.has_skill("magnetic_skin"):
                                                heal *= float(CSData.skill_num("magnetic_skin",
                                                                "hearts", meta.skill_level("magnetic_skin"), 1.5))
                                        p_hp = minf(p_max_hp, p_hp + heal)
                                        Jukebox.sfx("cs_heal", -6.0)
                                        _sparkle(pk["pos"], CS_GREEN)
                                "gogacoin":
                                        # THE REAL GOGACOIN: +1 to the GOGABox
                                        # wallet. THE SILENCE LAW: nothing
                                        # announces it - the counter ticks.
                                        add_run_coins(1)
                                        meta.d["gogacoins"] = int(meta.d.get("gogacoins", 0)) + 1
                                        meta.save()
                        dead.append(pk)
        for pk2 in dead:
                pk2["node"].queue_free()
                pickups.erase(pk2)

## a little burst of glitter where something good happened
func _sparkle(pos: Vector2, col: Color) -> void:
        for i in 5:
                var a := randf() * TAU
                _parts.append({"pos": pos, "vel": Vector2.from_angle(a) * randf_range(40.0, 130.0),
                        "t": 0.3, "max": 0.3, "col": col,
                        "size": randf_range(2.0, 4.0), "tex": ""})

func _tick_zones(delta: float) -> void:
        var dead := []
        for z in zones:
                z["t"] -= delta
                if String(z.get("kind", "")) == "pool":
                        # v0.3.7-1 THE FIRE POOL TICK: everything inside burns -
                        # a tick every 0.4s + the burn DOT keeps smoking after
                        z["tick"] = float(z.get("tick", 0.0)) - delta
                        if z["tick"] <= 0.0:
                                z["tick"] = 0.4
                                for e in enemies.duplicate():
                                        if e.get("dead", false):
                                                continue
                                        if e["pos"].distance_to(z["pos"]) \
                                                        < float(z["aoe"]) + float(e["size"]) * 0.5:
                                                _hurt_enemy(e, float(z["dps"]) * 0.4, false, true)
                                                e["burn_t"] = maxf(float(e.get("burn_t", 0.0)), 1.2)
                                                e["burn_dps"] = maxf(float(e.get("burn_dps", 0.0)),
                                                                float(z["dps"]) * 0.4)
                        continue
                if z["t"] <= 0.0:
                        if z["kind"] == "strike":
                                _boom_at(z["pos"], float(z["aoe"]), float(z["dmg"]), true)
                        elif z["kind"] == "slam":
                                if p_pos.distance_to(z["pos"]) < float(z["aoe"]):
                                        _hurt_player(float(z["dmg"]), null)
                                _boom_at(z["pos"], float(z["aoe"]), 0.0, false)
                        dead.append(z)
        for z2 in dead:
                zones.erase(z2)

## v0.3.7-1 THE MOLOTOV'S LANDING: the bottle shatters - a fire pool burns
## where it lands for `dur` seconds, damaging everything that comes close
## (the owner: "when throwed, leaves fire for specified seconds that deals
## damage to enemies come close to it").
func _fire_pool(at: Vector2, dps: float, r: float, dur: float) -> void:
        zones.append({"kind": "pool", "pos": at, "t": dur, "max": dur,
                "dps": dps, "aoe": r, "tick": 0.0})
        Jukebox.sfx("cs_burn", -4.0, 0.9)

## the explosion law: damages enemies (and the player when `hits_player`).
## v0.3.7-1 THE FALLOFF LAW (the owner, item 19: "a bomb that makes radius
## damage and the further the radius the lower the damage gets"): the
## damage scales linearly from 100% at the center to 35% at the rim.
## v0.3.7-1 THE GIB LAW (the extra round): a bomb kill is a GIB - the
## enemy bursts into physical skin chunks + a blood stain hits the ground.
func _boom_at(pos: Vector2, r: float, dmg: float, hits_player: bool) -> void:
        for e in enemies.duplicate():
                var d: float = e["pos"].distance_to(pos)
                if d < r + float(e["size"]) * 0.5:
                        var falloff: float = lerpf(1.0, 0.35,
                                        clampf(d / maxf(1.0, r), 0.0, 1.0))
                        var was_alive: bool = not e.get("dead", false)
                        _hurt_enemy(e, dmg * falloff)
                        if was_alive and e.get("dead", false):
                                _gib_enemy(e)
        if hits_player and p_pos.distance_to(pos) < r + PLAYER_R:
                _hurt_player(dmg * 0.8, null)
        _shockwave(pos, r)
        Jukebox.sfx("cs_boom", -4.0)
        _shake = maxf(_shake, 4.0)

## v0.3.7-1 THE GIB: 5-8 potato-skin chunks with real gravity + spin, a
## red mist, and a stain where the enemy stood. The teens rating owns it.
func _gib_enemy(e: Dictionary) -> void:
        var n := 5 + (3 if e.get("elite", false) else 0)
        for i in n:
                var a := randf() * TAU
                _parts.append({"pos": e["pos"] \
                                + Vector2.from_angle(a) * randf_range(0.0, float(e["size"]) * 0.4),
                                "vel": Vector2.from_angle(a) * randf_range(120.0, 340.0) \
                                                + Vector2(0, -randf_range(80.0, 240.0)),
                                "t": randf_range(0.55, 0.95), "max": 0.95,
                                "col": Color(0.86, 0.72, 0.42) if i % 2 == 0 \
                                                else Color(0.55, 0.10, 0.08),
                                "size": randf_range(4.0, 9.0), "tex": "", "g": 900.0})
        _stains.append({"pos": e["pos"] + Vector2(0, float(e["size"]) * 0.3),
                        "r": float(e["size"]) * randf_range(0.9, 1.4), "t": 7.0,
                        "max": 7.0})
        while _stains.size() > 40:
                _stains.pop_front()
        _burst(e["pos"], [Color(0.55, 0.10, 0.08), Color(0.72, 0.14, 0.10)], 8)

# ================================================================ waves
func _tick_waves(delta: float) -> void:
        if phase != "play":
                return
        wave_clock -= delta
        _spawn_stream(delta)
        if wave_clock <= 0.0 and not boss_alive:
                _wave_clear()

var _spawn_clock := 0.0
var _burst_clock := 0.0

func _begin_wave(w: int) -> void:
        run_wave = w
        phase = "play"
        var boss_wave := w % CSData.BOSS_CYCLE == 0
        wave_clock = CSData.BOSS_WAVE_SECS if boss_wave else CSData.WAVE_SECS
        _spawn_clock = 0.0
        _burst_clock = 2.0
        # THE GOGACOIN RIDER: every 5th wave owes one coin carrier (a living
        # carrier from the previous wave keeps the debt alive)
        goga_pending = goga_carry or (w % 5 == 0)
        goga_carry = false
        if boss_wave:
                _spawn_boss(w)
                wave_spawning = true
        else:
                Jukebox.sfx("cs_wave_horn", -4.0)
                _banner("WAVE %d" % w, true)

func _spawn_stream(delta: float) -> void:
        _spawn_clock -= delta
        _burst_clock -= delta
        if _spawn_clock <= 0.0:
                _spawn_clock = CSData.spawn_interval(run_wave)
                _spawn_one()
        if _burst_clock <= 0.0:
                _burst_clock = 5.0
                _spawn_burst(CSData.burst_size(run_wave))

func _spawn_one() -> void:
        var pool := CSData.pool_for_wave(run_wave)
        var kind: String = pool[randi() % pool.size()]
        # LUCK: the elites answer to the clover too
        var elite_p := CSData.elite_chance(run_wave) * (1.0 + float(stats.get("luck", 0.0)) * 0.6)
        _spawn_enemy(kind, _spawn_pos(), randf() < elite_p)

func _spawn_burst(n: int) -> void:
        for i in n:
                _spawn_one()

func _spawn_pos() -> Vector2:
        var a := randf() * TAU
        var r := randf_range(620.0, 780.0)
        var p := p_pos + Vector2.from_angle(a) * r
        return Vector2(clampf(p.x, ARENA.position.x - 80.0, ARENA.end.x + 80.0),
                        clampf(p.y, ARENA.position.y - 80.0, ARENA.end.y + 80.0))

# ================================================== THE COIN PURSE (v0.3.8-2)
## THE PURSE LAW (the owner: "make coins be persistent"): ONE cosmic wallet
## for the whole game, forever. The run's counter IS the saved balance -
## a wave-clear bonus, a coin pickup, a sale all land in the same purse the
## armory and the tree spend from, and a death or a QUIT TO BOX banks
## NOTHING because the coins were already home. _cc_sync() checkpoints the
## save at breaks, buys, death, quit and a 5s heartbeat.
var _cc_clock := 0.0

func _cc_earn(v: int) -> void:
        if v <= 0:
                return
        run_ccoins += v
        meta.d["coins"] = run_ccoins

func _cc_spend(v: int) -> bool:
        if run_ccoins < v:
                return false
        run_ccoins -= v
        meta.d["coins"] = run_ccoins
        return true

func _cc_sync() -> void:
        meta.d["coins"] = run_ccoins
        meta.save()

## after a META-side spend/earn (the tree, the armory helpers) - the purse
## mirror reads the truth back
func _cc_pull() -> void:
        run_ccoins = meta.coins()

func _wave_clear() -> void:
        # a living carrier re-hides its coin in the NEXT wave's swarm
        if goga_carrier_alive:
                goga_carrier_alive = false
                goga_carry = true
        for e in enemies.duplicate():
                _drop_pickup("xp", e["pos"], int(e["xp"]) * 2)
                e["node"].queue_free()
                enemies.erase(e)
        for b in ebullets:
                b["node"].queue_free()
        ebullets.clear()
        for b2 in bullets:
                b2["node"].queue_free()
        bullets.clear()
        p_hp = minf(p_max_hp, p_hp + CSData.WAVE_HEAL)
        var bonus := maxi(1, int(round((CSData.WAVE_COINS + 2 * run_wave)
                        * float(stats["coin_m"]))))
        _cc_earn(bonus)
        _cc_sync()
        phase = "break"
        _banner("WAVE %d CLEAR  +%d CC" % [run_wave, bonus], true)
        Jukebox.sfx("cs_levelup", -4.0)
        run_wave += 1
        _wave_break_open()

# ================================================================ the breaks
## THE BREAK CHAIN (v0.3.4-3, the owner: "we will have shop menu, stats
## menu, skills menu... splitting merge menu to be as another menu instead
## of in shop, put it after shop"):
##   clear -> the WAVE DRAFT (pick 1 of 3, NO reroll - the reroll lives in
##   the market) -> THE WAVE MARKET (items/weapons/allies + the HOLD DECK)
##   -> THE MERGE BENCH (its own menu) -> THE STATS MENU (the level-ups)
##   -> THE SKILLS MENU (when points wait) -> the next wave.
var _draft_cards: Array = []

func _wave_break_open() -> void:
        _break_in_market = false
        shop_rerolls = 0
        shop_free_reroll = meta.tree_has("u3")
        market_tab = "items"
        _roll_shop_offers()
        _wave_draft_open()

## every CONTINUE in the chain lands on one of these - each step closes its
## own sheet first, so the stack never grows and the chain never strands
func _chain_after_draft() -> void:
        _cs_pop_top()
        _market_open()

func _chain_after_market() -> void:
        _cs_pop_top()
        _merge_menu_open()

func _chain_after_merge() -> void:
        _cs_pop_top()
        # v0.3.8-2: the tracks ride LIFETIME points now - banked points from
        # older runs wait here just like fresh ones
        if meta.stat_pts() > 0:
                _stats_menu_open()
                return
        _chain_after_stats()

func _chain_after_stats() -> void:
        _cs_pop_top()
        if meta.skill_points_free(run_kills) > 0:
                _skills_menu_open()
                return
        _chain_after_skills()

func _chain_after_skills() -> void:
        _cs_close_all()
        _begin_wave(run_wave)

## the break fell out of a sheet (a universal shop visit closed over it) -
## the market is the break's hub, so back it comes
func _resume_break() -> void:
        if phase == "break" and cs_sheets.is_empty():
                _market_open()

# ------------------------------------------------------------- wave draft
func _wave_draft_open() -> void:
        _draft_cards = _roll_wave_drafts(3)
        # closable=false: a closed draft used to strand the break with no
        # sheet - the SKIP button is the way out
        _cs_open("WAVE %d CLEARED" % (run_wave - 1), func(box: VBoxContainer):
                _build_draft(box), CS_YELLOW, false, "draft")

func _roll_wave_drafts(n: int) -> Array:
        # weighted pick without repeats
        var pool := []
        for d in CSData.WAVE_DRAFTS:
                pool.append({"d": d, "w": int(d["w"])})
        var out := []
        for i in n:
                var total := 0
                for p in pool:
                        total += int(p["w"])
                var r := randi() % total
                for p in pool:
                        r -= int(p["w"])
                        if r < 0:
                                out.append(p["d"])
                                pool.erase(p)
                                break
        return out

func _build_draft(box: VBoxContainer) -> void:
        var sub := _cs_label("every card GIVES something - most TAKE something back",
                        13, CS_WHITE)
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(sub)
        var row := HBoxContainer.new()
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        row.add_theme_constant_override("separation", 12)
        box.add_child(row)
        for d in _draft_cards:
                row.add_child(_draft_card(d))
        var actions := HBoxContainer.new()
        actions.alignment = BoxContainer.ALIGNMENT_CENTER
        actions.add_theme_constant_override("separation", 14)
        box.add_child(actions)
        # THE REROLL IS GONE from the drafts (the owner: "a re-roll should be
        # for shop items") - the market owns it now
        actions.add_child(_cs_button("SKIP - take nothing", 14, CS_WHITE,
                        func(): _chain_after_draft()))

func _draft_card(d: Dictionary) -> Button:
        var b := Button.new()
        var risky: bool = not (d["down"] as Dictionary).is_empty()
        var st := _cs_box_style(CS_GREEN if not risky else CS_RED, CS_BOX)
        st.corner_radius_top_left = 12
        st.corner_radius_top_right = 12
        st.corner_radius_bottom_left = 12
        st.corner_radius_bottom_right = 12
        b.add_theme_stylebox_override("normal", st)
        var hov := _cs_box_style(CS_YELLOW if not risky else CS_RED, CS_BOX2)
        b.add_theme_stylebox_override("hover", hov)
        var vb := VBoxContainer.new()
        vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.set_anchors_preset(Control.PRESET_FULL_RECT)
        vb.offset_left = 8
        vb.offset_top = 10
        vb.offset_right = -8
        b.add_child(vb)
        var up_txt := String(d["t"])
        var up := _cs_fit_label(up_txt, 17, CS_GREEN, 224.0)
        up.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(up)
        var dn_txt := String(d["d"])
        var dn := _cs_label(dn_txt, 13, CS_RED if risky else CS_WHITE)
        dn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        dn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        vb.add_child(dn)
        ## THE TEXT-FIT LAW: the card grows to its wrapped description
        var dn_h := _cs_text_h(dn_txt, 13, 224.0)
        b.custom_minimum_size = Vector2(240, maxf(130.0, 10.0 + 24.0 + 4.0 + dn_h + 14.0))
        b.pressed.connect(func():
                _apply_draft(d)
                Jukebox.sfx("cs_draft", -4.0)
                _chain_after_draft())
        return b

func _apply_draft(d: Dictionary) -> void:
        for k in d["up"]:
                _apply_stat(String(k), d["up"][k])
        for k2 in d["down"]:
                _apply_stat(String(k2), d["down"][k2])

## the ledger's key map: _apply_stat speaks the draft/item tongue ("dmg"),
## the INFO rows read the live stat block's keys ("dmg_m")
const STAT_LEDGER_KEY := {"dmg": "dmg_m", "spd": "spd_m", "aspeed": "aspeed_m",
        "range": "range_m", "armor": "armor", "regen": "regen", "crit": "crit",
        "luck": "luck", "dodge": "dodge", "magnet": "magnet",
        "lifesteal": "lifesteal", "pierce_all": "pierce_all",
        "coin": "coin_m", "pierce": "pierce_add",
        "hp": "hp_add", "proj": "proj_add"}

func _apply_stat(k: String, v: Variant) -> void:
        # THE INFO LAW: every delta files under the up or the down ledger
        var bk: String = String(STAT_LEDGER_KEY.get(k, k))
        var book: Dictionary = stat_up if float(v) >= 0.0 else stat_down
        book[bk] = float(book.get(bk, 0.0)) + absf(float(v))
        match k:
                "dmg": stats["dmg_m"] = float(stats["dmg_m"]) + float(v)
                "spd": stats["spd_m"] = float(stats["spd_m"]) + float(v)
                "aspeed": stats["aspeed_m"] = float(stats["aspeed_m"]) + float(v)
                "range": stats["range_m"] = float(stats["range_m"]) + float(v)
                "armor": stats["armor"] = int(stats["armor"]) + int(v)
                "regen": stats["regen"] = float(stats["regen"]) + float(v)
                "crit": stats["crit"] = float(stats["crit"]) + float(v)
                "luck": stats["luck"] = float(stats.get("luck", 0.0)) + float(v)
                "dodge": stats["dodge"] = float(stats.get("dodge", 0.0)) + float(v)
                "magnet": stats["magnet"] = float(stats["magnet"]) + float(v)
                "lifesteal": stats["lifesteal"] = float(stats["lifesteal"]) + float(v)
                "pierce_all": stats["pierce_all"] = int(stats["pierce_all"]) + int(v)
                "pierce": stats["pierce_add"] = int(stats["pierce_add"]) + int(v)
                "coin": stats["coin_m"] = float(stats["coin_m"]) + float(v)
                "hp":
                        stats["hp_add"] = float(stats.get("hp_add", 0.0)) + float(v)
                        p_max_hp = _max_hp()
                        p_hp = clampf(p_hp + maxf(0.0, float(v)), 1.0, p_max_hp)
                "proj": stats["proj_add"] = int(stats["proj_add"]) + int(v)

# ------------------------------------------------------------ STATS menu
## THE STAT TRACKS (v0.3.8-2, the owner: "make stats be persistent with
## their upgrades like the skills... 5 upgrades each one with higher points
## and gives extra stuff"): one STAT POINT mints per run level-up, LIFETIME.
## The fourteen tracks each wear FIVE levels with climbing costs and bundled
## extras on levels 3 and 5 - every bought level rides EVERY run from now on
## (baked into the base at _start_run). The sheet is closable=false in the
## break chain (the DONE button walks it); from the door it wears a BACK.
func _stats_menu_open() -> void:
        _cs_open("THE STAT TRACKS", func(box: VBoxContainer):
                _build_stats_menu(box), CS_BLUE, phase != "break", "stats")

func _build_stats_menu(box: VBoxContainer) -> void:
        var head := _cs_label("%d STAT POINTS  -  one per level-up, they NEVER reset" \
                        % meta.stat_pts(), 15, CS_BLUE)
        head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(head)
        # THE BIG-UI LAW + THE SCROLL TRUTH: a BoxScroll shelf, nothing cramped
        var scroll := _cs_scroll()
        scroll.custom_minimum_size = Vector2(0, get_viewport_rect().size.y * 0.42)
        box.add_child(scroll)
        var shelf := _cs_shelf(scroll)
        var grid := GridContainer.new()
        grid.columns = 3
        grid.add_theme_constant_override("h_separation", 8)
        grid.add_theme_constant_override("v_separation", 8)
        grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        shelf.add_child(grid)
        for p in CSData.STAT_TRACKS:
                var pk: Dictionary = p
                grid.add_child(_stat_track_card(pk))
        _cs_scroll_taps(scroll)
        _fit_scroll(scroll, shelf, 0.44)
        var actions := HBoxContainer.new()
        actions.alignment = BoxContainer.ALIGNMENT_CENTER
        actions.add_theme_constant_override("separation", 14)
        box.add_child(actions)
        if phase == "break":
                actions.add_child(_cs_button("DONE - TO THE SKILLS >", 16, CS_GREEN,
                                func(): _chain_after_stats()))
        else:
                actions.add_child(_cs_button("BACK", 14, CS_WHITE, func():
                        _cs_close_top()))

## the LV pips: five dots, the owned ones lit - the track's face
func _cs_lv_pips(owned: int, col: Color) -> String:
        var s := ""
        for i in 5:
                s += "*" if i < owned else "."
        return "LV %s %d/5" % [s, owned]

func _stat_track_card(tr: Dictionary) -> PanelContainer:
        var tid := String(tr["id"])
        var owned := meta.track_level(tid)
        var maxed := owned >= 5
        var ladder: Array = tr["ladder"]
        var cost := int(ladder[owned]) if not maxed else 0
        var broke := meta.stat_pts() < cost
        # what THIS purchase pays for: the level's own gain + its extras
        var gains := [String(tr["d"])]
        if not maxed:
                var nxt := owned + 1
                for stp in (tr.get("steps", {}) as Dictionary).get(nxt, []):
                        gains.append("and " + String(stp[2]))
                if nxt == 5 and tr.has("final"):
                        gains.append(String(tr["final"]["d"]))
        var lines := [String(tr["d"]), _cs_lv_pips(owned, CS_BLUE)]
        var card := _shop_card(String(tr["t"]), CS_BLUE if owned > 0 else CS_WHITE,
                        lines, CS_BLUE if owned > 0 else CS_EDGE,
                        "MAXED" if maxed else ("BUY %d PTS" % cost
                                if not broke else "NEED %d PTS" % cost),
                        CS_YELLOW, func(): _buy_track(tr), not maxed and not broke)
        # the NEXT line rides under the button (the card body stays tight)
        if not maxed:
                var nxt_lbl := _cs_label("next: " + " + ".join(PackedStringArray(gains)),
                                10, CS_GREEN)
                nxt_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                nxt_lbl.custom_minimum_size = Vector2(206, 0)
                card.get_child(0).add_child(nxt_lbl)
        return card

func _buy_track(tr: Dictionary) -> void:
        var tid := String(tr["id"])
        var owned := meta.track_level(tid)
        if owned >= 5:
                return
        var cost := int(tr["ladder"][owned])
        if not meta.spend_stat_pts(cost):
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough points (%d left)" % meta.stat_pts())
                return
        meta.set_track_level(tid, owned + 1)
        _apply_stat(String(tr["k"]), tr["v"])
        for stp in (tr.get("steps", {}) as Dictionary).get(owned + 1, []):
                _apply_stat(String(stp[0]), stp[1])
        if owned + 1 == 5 and tr.has("final"):
                var fin: Dictionary = tr["final"]
                _apply_stat(String(fin["k"]), fin["v"])
        Jukebox.sfx("cs_levelup", -4.0)
        _cs_reopen(func(): _stats_menu_open())

# ----------------------------------------------------------- SKILLS menu
## THE SKILLS MENU (v0.3.4-3, the owner: "skills should be earned from each
## 100 kill as a point, skills should be unique... a real high cool-factor").
## The points are LIFETIME - they never reset with a round.
## v0.3.8-2 THE SKILL DEPTHS: every skill wears FIVE levels now - buying an
## owned skill RAISES it up the ladder, the costs climb, the cards show the
## LV pips and the next level's own law.
func _skills_menu_open() -> void:
        _cs_open("THE SKILLS", func(box: VBoxContainer): _build_skills_menu(box),
                        CS_GREEN, false, "skills")

func _build_skills_menu(box: VBoxContainer) -> void:
        var free := meta.skill_points_free(run_kills)
        var head := _cs_label("%d SKILL POINTS  -  one point per 100 kills, they NEVER reset" \
                        % free, 15, CS_GREEN)
        head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(head)
        var scroll := _cs_scroll()
        scroll.custom_minimum_size = Vector2(0, get_viewport_rect().size.y * 0.42)
        box.add_child(scroll)
        var shelf := _cs_shelf(scroll)
        var grid := GridContainer.new()
        grid.columns = 2
        grid.add_theme_constant_override("h_separation", 8)
        grid.add_theme_constant_override("v_separation", 8)
        grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        shelf.add_child(grid)
        for sid in CSData.SKILL_ORDER:
                var sid_s: String = sid
                grid.add_child(_skill_card(sid_s, free))
        _cs_scroll_taps(scroll)
        _fit_scroll(scroll, shelf, 0.44)
        var actions := HBoxContainer.new()
        actions.alignment = BoxContainer.ALIGNMENT_CENTER
        actions.add_theme_constant_override("separation", 14)
        box.add_child(actions)
        if phase == "break":
                actions.add_child(_cs_button("CONTINUE - TO WAVE %d >" % run_wave,
                                16, CS_GREEN, func(): _chain_after_skills()))
        else:
                actions.add_child(_cs_button("BACK", 14, CS_WHITE, func():
                        _cs_close_top()))

func _skill_card(sid: String, free: int) -> PanelContainer:
        var sk: Dictionary = CSData.SKILLS[sid]
        var owned := meta.skill_level(sid)
        var maxed := owned >= 5
        var cost := 0 if maxed else CSData.skill_level_cost(sid, owned + 1)
        var can := not maxed and free >= cost
        # line 1: the CURRENT level's law (level 0 -> the base desc),
        # line 2: the pips, line 3: the NEXT level's promise
        var lines := [CSData.skill_lv_line(sid, owned),
                _cs_lv_pips(owned, CS_GREEN)]
        if not maxed:
                lines.append("next: " + CSData.skill_lv_line(sid, owned + 1))
        var btn_txt := "MAXED" if maxed else \
                ("BUY %d %s" % [cost, "PT" if cost == 1 else "PTS"] if owned == 0
                        else "RAISE %d PTS" % cost)
        return _shop_card(String(sk["name"]), CS_GREEN if owned > 0 else CS_WHITE,
                        lines, CS_GREEN if owned > 0 else CS_EDGE,
                        btn_txt, CS_GREEN, func(): _buy_skill(sid, free),
                        can or (owned > 0 and maxed))

func _buy_skill(sid: String, free: int) -> void:
        if meta.buy_skill(sid, run_kills):
                Jukebox.sfx("cs_levelup", -3.0, 1.1)
                _cs_reopen(func(): _skills_menu_open())
        else:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough skill points")

# ========================================================= THE WAVE MARKET
## THE BREAK'S STORE (v0.3.4-3, the owner: "make shop has items, weapons,
## allies... a re-roll should be for shop items... in brotato there was like
## extra-deck-style in the shop where the user can save up to 5 things for
## later, not affected by rerolls"): three tabs - ITEMS / WEAPONS / ALLIES -
## the REROLL lives here (u3's free shuffle first), and THE HOLD DECK pins
## up to 5 offers across rerolls, THIS market visit only, never saved.
func _shop_button() -> void:
        # v0.3.4-4 THE SHOP LIST LAW (the owner: the button must open the
        # same universal GOGACoins LIST every other game opens - themes,
        # weapons, the merging - NOT the game's own cosmic-coin store):
        # THE SHOP opens at ANY phase; the wave market is the break's own
        # flow and opens itself.
        _shop_open()

func _market_open() -> void:
        _break_in_market = true
        _cs_open("THE WAVE MARKET", func(box: VBoxContainer): _build_market(box),
                        CS_YELLOW, false, "market")

func _roll_shop_offers(keep_held := false) -> void:
        # 4 weapon offers + 3 item offers, luck-weighted rarities.
        # THE HOLD DECK: when keep_held, the HELD offers survive untouched.
        var luck := float(stats.get("luck", 0.0))
        var kept_w: Array = []
        var kept_i: Array = []
        if keep_held:
                for o in shop_offers_w:
                        if bool(o["held"]):
                                kept_w.append(o)
                for o2 in shop_offers_i:
                        if bool(o2["held"]):
                                kept_i.append(o2)
        shop_offers_w.clear()
        var used := {}
        var wneed := 4
        # v0.3.4-4 THE SHOP LIST LAW: THE SHOP's GOGACoins guns join the wave
        # loot - owning one plants its offer FIRST, every roll, held deck
        # space permitting (the same law the invaders shop runs on).
        for gid in CSData.SHOP_GUNS:
            if shop_offers_w.size() >= wneed - kept_w.size():
                break
            if Box.item_owned(game_id, "guns", gid) and not used.has(gid):
                used[gid] = true
                var grar := CSData.roll_rarity(luck)
                var gprice := int(round(CSData.weapon_price(gid, 1)
                                * CSData.RARITIES[grar]["pm"] * meta.shop_discount()))
                shop_offers_w.append({"wid": gid, "tier": 1, "rar": grar,
                        "price": gprice, "sold": false, "held": false})
        var owned_n := meta.armory().size()
        for k in wneed - shop_offers_w.size():
                var wid := _pick_offer_weapon(used)
                used[wid] = true
                var rar := CSData.roll_rarity(luck)
                var tier := 1
                if meta.char_level() >= 4 and k >= 2 and randf() < 0.35:
                        tier = 2
                var price := int(round(CSData.weapon_price(wid, tier)
                                * CSData.RARITIES[rar]["pm"] * meta.shop_discount()))
                shop_offers_w.append({"wid": wid, "tier": tier, "rar": rar,
                        "price": price, "sold": false, "held": false})
        shop_offers_i.clear()
        var iused := {}
        var tries := 0
        # v0.3.8-2 THE HONEST ROLL: the old `for k in 3` + `k -= 1` dedup was
        # DEAD code (a GDScript loop var never rewinds its sequence) - a
        # duplicate roll left the shelf SHORT forever. A real while-roll now
        # guarantees three DISTINCT offers.
        while shop_offers_i.size() < 3 and tries < 40:
                tries += 1
                var iid: String = CSData.ITEM_ORDER[randi() % CSData.ITEM_ORDER.size()]
                if iused.has(iid):
                        continue
                iused[iid] = true
                var rar2 := CSData.roll_rarity(luck)
                var it: Dictionary = CSData.ITEMS[iid]
                var base_p := int(it.get("price", 30))
                var price2 := int(round(base_p * float(CSData.RARITIES[rar2]["pm"])
                                + run_wave * 1.5))
                shop_offers_i.append({"iid": iid, "rar": rar2, "price": price2,
                        "sold": false, "held": false})
        # the pins return on top of the fresh shelf
        shop_offers_w = kept_w + shop_offers_w.slice(0, maxi(0, 4 - kept_w.size()))
        shop_offers_i = kept_i + shop_offers_i.slice(0, maxi(0, 3 - kept_i.size()))

func _pick_offer_weapon(used: Dictionary) -> String:
        # prefer owned kinds (the Brotato copy-buy), fall wide otherwise
        var owned := []
        for inst in meta.armory():
                if not used.has(inst[0]) and not owned.has(inst[0]):
                        owned.append(inst[0])
        if not owned.is_empty() and randf() < 0.6:
                return owned[randi() % owned.size()]
        for _try in 20:
                var wid: String = CSData.WEAPON_ORDER[randi() % CSData.WEAPON_ORDER.size()]
                if not used.has(wid):
                        return wid
        return CSData.WEAPON_ORDER[0]

func _stat_chips_row(box: VBoxContainer) -> void:
        var row := HBoxContainer.new()
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        row.add_theme_constant_override("separation", 6)
        box.add_child(row)
        var chips := [
                ["DMG +%d%%" % int(round((float(stats["dmg_m"]) - 1.0) * 100)), CS_GREEN],
                ["SPD %d%%" % int(round(float(stats["spd_m"]) * 100)), CS_WHITE],
                ["ASPD %d%%" % int(round(float(stats["aspeed_m"]) * 100)), CS_WHITE],
                ["CRIT %d%%" % int(round(float(stats["crit"]) * 100)), CS_YELLOW],
                ["ARM %d" % int(stats["armor"]), CS_BLUE],
                ["LUCK %d%%" % int(round(float(stats.get("luck", 0.0)) * 100)), CS_GREEN],
                ["DODGE %d%%" % int(round(float(stats.get("dodge", 0.0)) * 100)), CS_BLUE],
        ]
        for c in chips:
                var l := _cs_label(String(c[0]), 11, c[1])
                l.add_theme_stylebox_override("normal", _cs_box_style())
                var pc := PanelContainer.new()
                pc.add_theme_stylebox_override("panel", _cs_box_style())
                pc.add_child(l)
                row.add_child(pc)

func _shop_card(title: String, title_col: Color, body_lines: Array,
                border: Color, btn_txt: String, btn_col: Color,
                cb: Callable, enabled := true, extra_txt := "",
                extra_cb := Callable(), extra_col := CS_BLUE,
                coin_price := false) -> PanelContainer:
        var card := PanelContainer.new()
        var st := _cs_box_style(border, CS_BOX)
        st.corner_radius_top_left = 10
        st.corner_radius_top_right = 10
        st.corner_radius_bottom_left = 10
        st.corner_radius_bottom_right = 10
        card.add_theme_stylebox_override("panel", st)
        card.custom_minimum_size = Vector2(206, 0)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 2)
        card.add_child(vb)
        var nm := _cs_label(title, 14, title_col)
        nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        vb.add_child(nm)
        for ln in body_lines:
                var l2 := _cs_label(String(ln), 11, CS_WHITE)
                l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                vb.add_child(l2)
        var buy := _cs_coin_button(btn_txt, 13, btn_col, cb) if coin_price \
                        else _cs_button(btn_txt, 13, btn_col, cb)
        buy.disabled = not enabled
        vb.add_child(buy)
        if extra_txt != "":
                var ex := _cs_button(extra_txt, 11, extra_col, extra_cb)
                vb.add_child(ex)
        return card

func _cards_row(box: VBoxContainer, cards: Array) -> void:
        var row := HBoxContainer.new()
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        row.add_theme_constant_override("separation", 8)
        box.add_child(row)
        for c in cards:
                row.add_child(c)

func _section(box: VBoxContainer, txt: String) -> void:
        var l := _cs_label(txt, 12, CS_BLUE)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(l)

func _build_market(box: VBoxContainer) -> void:
        # the header: the fat balance + the wave info + the HOLD DECK chip
        var head := HBoxContainer.new()
        head.alignment = BoxContainer.ALIGNMENT_CENTER
        head.add_theme_constant_override("separation", 8)
        box.add_child(head)
        var ccbox := _cs_black_box(head, Vector2(160, 36))
        var hh := HBoxContainer.new()
        ccbox.add_child(hh)
        hh.add_child(_cs_icon(_t("coin"), 24))
        hh.add_child(_cs_label(str(run_ccoins), 18, CS_YELLOW))
        var held_box := _cs_black_box(head, Vector2(120, 36))
        held_box.add_child(_cs_label("HELD %d/5" % _held_count(), 13, CS_BLUE))
        var boss_next: bool = (run_wave % CSData.BOSS_CYCLE) == 0
        _cs_label("wave %d cleared - next: %sWAVE %d - LV %d" % [run_wave - 1,
                ("BOSS " if boss_next else ""), run_wave, run_level],
                13, CS_RED if boss_next else CS_WHITE, head)
        _stat_chips_row(box)
        # the tabs: ITEMS / WEAPONS / ALLIES (the owner's three)
        var tabs := HBoxContainer.new()
        tabs.alignment = BoxContainer.ALIGNMENT_CENTER
        tabs.add_theme_constant_override("separation", 6)
        box.add_child(tabs)
        for tab in ["items", "weapons", "allies"]:
                var t_s: String = tab
                var b := _cs_button(t_s.to_upper(), 13,
                                CS_YELLOW if market_tab == t_s else CS_WHITE, func():
                        market_tab = t_s
                        _cs_reopen(func(): _market_open()))
                tabs.add_child(b)
        # THE BIG-UI LAW + THE SCROLL TRUTH: the shelf scrolls BOTH ways, on
        # raw touch, even when the finger starts ON a card's button
        var scroll := _cs_scroll()
        scroll.custom_minimum_size = Vector2(0, get_viewport_rect().size.y * 0.42)
        box.add_child(scroll)
        var shelf := _cs_shelf(scroll)
        match market_tab:
                "items": _market_items(shelf)
                "weapons": _market_weapons(shelf)
                "allies": _market_allies(shelf)
        _cs_scroll_taps(scroll)
        _fit_scroll(scroll, shelf, 0.44)
        # ---- the actions: THE REROLL + the chain's next step
        var actions := HBoxContainer.new()
        actions.alignment = BoxContainer.ALIGNMENT_CENTER
        actions.add_theme_constant_override("separation", 16)
        box.add_child(actions)
        var rc := CSData.shop_reroll_cost(shop_rerolls)
        actions.add_child(_cs_button("REROLL OFFERS - %s" % ("FREE" if shop_free_reroll
                        else "%d CC" % rc), 14, CS_BLUE, func(): _reroll_market()))
        actions.add_child(_cs_button("TO THE MERGE BENCH >", 15, CS_GREEN, func():
                _chain_after_market()))

func _market_items(shelf: VBoxContainer) -> void:
        _section(shelf, "ITEMS")
        var icards := []
        for o2 in shop_offers_i:
            var off2: Dictionary = o2
            if off2["sold"] and not bool(off2["held"]):
                    icards.append(_shop_card("SOLD", Color(0.5, 0.5, 0.55), ["gone"],
                                    CS_EDGE, "-", CS_WHITE, func(): pass, false))
                    continue
            var iid: String = off2["iid"]
            var it: Dictionary = CSData.ITEMS[iid]
            var rar2: String = off2["rar"]
            var rarc2: Color = CSData.RARITIES[rar2]["col"]
            var lines2 := [String(CSData.RARITIES[rar2]["name"]), String(it["desc"])]
            var can2 := run_ccoins >= int(off2["price"])
            icards.append(_shop_card(String(it["name"]), CS_YELLOW if off2["held"] else rarc2,
                            lines2, CS_YELLOW if off2["held"] else rarc2,
                            "SOLD" if off2["sold"] else "BUY %d CC" % int(off2["price"]),
                            CS_YELLOW, func(): _shop_buy_item(off2), can2 and not off2["sold"],
                            "UNHOLD" if off2["held"] else "HOLD",
                            func(): _toggle_hold(off2), CS_BLUE))
        _cards_row(shelf, icards)
        _section(shelf, "SUPPLIES")
        var scards := []
        for cid in CSData.CONSUMABLES:
            var cid_s: String = cid
            var cd: Dictionary = CSData.CONSUMABLES[cid_s]
            var price := int(round(int(cd["price"]) * meta.shop_discount()))
            var can3 := run_ccoins >= price
            scards.append(_shop_card(String(cd["name"]), CS_WHITE,
                            [String(cd["desc"])], CS_EDGE, "BUY %d CC" % price, CS_YELLOW,
                            func(): _shop_buy_supply(cid_s, price), can3))
        _cards_row(shelf, scards)

## THE TIER RANGE LAW's face (v0.3.4-5): ONE honest stat line - the EFFECTIVE
## dmg / cadence / range of this weapon at this tier. Melee says "melee".
## v0.3.8-4 THE DIRECT SHOTS LAW (the owner: "i thought you made the
## presentation to say it like 0.5/s so it means a shot after each 500ms so
## there is 2 shots per second, if like this, the user will do the math by
## itself so it will be more confusing, just make it direct shot/s is much
## cooler"): the cadence speaks SHOTS PER SECOND - the interval never shows.
func _weapon_stat_line(wid: String, tier: int) -> String:
        var wd: Dictionary = CSData.WEAPONS[wid]
        var mult: Dictionary = CSData.tier_mult(tier)
        var rng_v: float = float(wd["rng"]) * float(mult.get("rng", 1.0))
        var tail := " (melee)" if bool(wd.get("melee", false)) else ""
        var cad: float = maxf(0.02, float(wd["cad"]) * float(mult["cad"]))
        return "%d dmg / %.1f/s / rng %d%s" % [
                int(float(wd["dmg"]) * float(mult["dmg"])),
                1.0 / cad, int(rng_v), tail]

func _market_weapons(shelf: VBoxContainer) -> void:
        _section(shelf, "WEAPON OFFERS")
        var wcards := []
        for o in shop_offers_w:
            var off: Dictionary = o
            if off["sold"] and not bool(off["held"]):
                    wcards.append(_shop_card("SOLD", Color(0.5, 0.5, 0.55),
                                    ["come back next wave"], CS_EDGE, "-", CS_WHITE,
                                    func(): pass, false))
                    continue
            var wid: String = off["wid"]
            var wd: Dictionary = CSData.WEAPONS[wid]
            var rar: String = off["rar"]
            var rarc: Color = CSData.RARITIES[rar]["col"]
            var lines := [
                    "T%d - %s" % [int(off["tier"]), String(CSData.RARITIES[rar]["name"])],
                    _weapon_stat_line(String(off["wid"]), int(off["tier"])),
                    String(CSData.RARITIES[rar]["blurb"]),
            ]
            var can: bool = run_ccoins >= int(off["price"]) and weapons_run.size() < meta.weapon_slots() \
                            and int(off["tier"]) <= meta.tier_cap() and not bool(off["sold"])
            wcards.append(_shop_card(String(wd["name"]),
                            CS_YELLOW if off["held"] else rarc, lines,
                            CS_YELLOW if off["held"] else rarc,
                            "SOLD" if off["sold"] else "BUY %d CC" % int(off["price"]),
                            CS_YELLOW, func(): _shop_buy_weapon(off), can,
                            "UNHOLD" if off["held"] else "HOLD",
                            func(): _toggle_hold(off), CS_BLUE))
        _cards_row(shelf, wcards)
        _section(shelf, "YOUR LOADOUT")
        var lcards := []
        for wr in weapons_run:
            var wr_d: Dictionary = wr
            var wid2: String = wr_d["id"]
            var refund := int(CSData.sell_price(CSData.weapon_price(wid2, int(wr_d["tier"]))))
            var keep := weapons_run.size() > 1
            lcards.append(_shop_card("%s T%d" % [String(CSData.WEAPONS[wid2]["name"]), int(wr_d["tier"])],
                            CS_WHITE, [_weapon_stat_line(wid2, int(wr_d["tier"])), "equipped now"],
                            CS_EDGE, "SELL +%d CC" % refund, CS_RED, func():
                            _shop_sell_weapon(wr_d, refund), keep))
        _cards_row(shelf, lcards)

func _market_allies(shelf: VBoxContainer) -> void:
        _section(shelf, "ALLIES")
        if (meta.d["owned_allies"] as Array).is_empty():
                var note := _cs_label("no allies yet - the ARMORY sells them (cosmic coins), THE CREW joins via THE SHOP (GOGACoins)",
                                12, CS_WHITE)
                note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                shelf.add_child(note)
                return
        var acards := []
        for aid in meta.d["owned_allies"]:
            var aid_s: String = aid
            var deployed := _allies_deployed(aid_s)
            var at_cap := allies.size() >= _ally_cap() and deployed == 0
            var lines3 := [String(CSData.ALLIES[aid_s]["desc"])]
            var can4 := false
            var price3 := 0
            if deployed == 0:
                    # THE ROSTER LAW: the deploy lands AT the persistent level
                    var plv := maxi(1, meta.ally_level(aid_s))
                    price3 = int(round(CSData.ally_level_price(aid_s, plv)
                                    * meta.shop_discount()))
                    lines3.append("deploys at LV %d" % plv)
                    can4 = run_ccoins >= price3 and not at_cap
            elif deployed >= CSData.ALLY_MAX_LEVEL:
                    lines3.append("LV %d - the roster's peak" % deployed)
            else:
                    price3 = int(round(CSData.ally_level_price(aid_s, deployed + 1)
                                    * meta.shop_discount()))
                    lines3.append("LV %d -> %d (this run)" % [deployed, deployed + 1])
                    can4 = run_ccoins >= price3
            acards.append(_shop_card(String(CSData.ALLIES[aid_s]["name"]), CS_GREEN, lines3,
                            CS_GREEN, ("DEPLOY %d CC" % price3) if deployed == 0
                            else (("RAISE %d CC" % price3) if deployed < CSData.ALLY_MAX_LEVEL
                            else "LV %d" % deployed),
                            CS_YELLOW, func(): _shop_buy_ally(aid_s, price3), can4))
        _cards_row(shelf, acards)

## THE HOLD DECK (the Brotato law): 5 pins, this market visit only
func _held_count() -> int:
        var n := 0
        for o in shop_offers_w:
                if bool(o["held"]):
                        n += 1
        for o2 in shop_offers_i:
                if bool(o2["held"]):
                        n += 1
        return n

func _toggle_hold(off: Dictionary) -> void:
        if bool(off["held"]):
                off["held"] = false    # removable, always, for free
        else:
                if _held_count() >= 5:
                        Jukebox.sfx("cs_error", -6.0)
                        _toast_show("the deck holds five - unhold something first")
                        return
                off["held"] = true
        Jukebox.sfx("cs_draft", -8.0, 1.3)
        _cs_reopen(func(): _market_open())

## THE REROLL (the owner: it lives HERE): u3's free shuffle first, then the
## climbing price. HELD offers survive; everything else re-rolls.
func _reroll_market() -> void:
        var rc := CSData.shop_reroll_cost(shop_rerolls)
        if shop_free_reroll:
                shop_free_reroll = false
        elif _cc_spend(rc):
                shop_rerolls += 1
        else:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough coins")
                return
        _cc_sync()
        _roll_shop_offers(true)
        Jukebox.sfx("cs_draft", -6.0, 1.2)
        _cs_reopen(func(): _market_open())

# --------------------------------------------------------- THE MERGE BENCH
## ITS OWN MENU (v0.3.4-3, the owner: "splitting merge menu to be as another
## menu instead of in shop, put it after shop")
func _merge_menu_open() -> void:
        _cs_open("THE MERGE BENCH", func(box: VBoxContainer): _build_merge_menu(box),
                        CS_YELLOW, false, "merge")

func _build_merge_menu(box: VBoxContainer) -> void:
        var scroll := _cs_scroll()
        scroll.custom_minimum_size = Vector2(0, get_viewport_rect().size.y * 0.4)
        box.add_child(scroll)
        var shelf := _cs_shelf(scroll)
        if not meta.merging_learned():
                var locked := _cs_label(
                                "LOCKED - the WEAPON LAB (skill tree, LAB branch) teaches merging",
                                13, CS_RED)
                locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                shelf.add_child(locked)
        else:
                var pairs := _merge_pairs()
                if pairs.is_empty():
                        var none := _cs_label(
                                        "no pairs on the bench (two same weapons, same tier)",
                                        13, CS_WHITE)
                        none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        shelf.add_child(none)
                for pr in pairs:
                    var pr_d: Dictionary = pr
                    var cost := int(round(float(pr_d["cost"]) * meta.merge_discount()))
                    var tcap_ok := meta.tier_cap() >= int(pr_d["tier"]) + 1
                    var can5 := run_ccoins >= cost and tcap_ok
                    var why := "" if tcap_ok else " (LV %d gates T%d)" % [meta.char_level(), int(pr_d["tier"]) + 1]
                    var card := _shop_card("MERGE: " + String(CSData.WEAPONS[pr_d["wid"]]["name"]),
                                    CS_YELLOW,
                                    ["T%d + T%d -> T%d" % [int(pr_d["tier"]), int(pr_d["tier"]), int(pr_d["tier"]) + 1],
                                     _weapon_stat_line(String(pr_d["wid"]), int(pr_d["tier"]) + 1),
                                     "two copies consumed" + why],
                                    CS_YELLOW, "MERGE %d CC" % cost, CS_YELLOW, func():
                                    _wave_buy_merge(pr_d, cost), can5)
                    _cards_row(shelf, [card])
        _cs_scroll_taps(scroll)
        _fit_scroll(scroll, shelf, 0.42)
        var actions := HBoxContainer.new()
        actions.alignment = BoxContainer.ALIGNMENT_CENTER
        actions.add_theme_constant_override("separation", 14)
        box.add_child(actions)
        actions.add_child(_cs_button("CONTINUE >", 16, CS_GREEN, func():
                _chain_after_merge()))

func _shop_buy_weapon(off: Dictionary) -> void:
        var price := int(off["price"])
        if run_ccoins < price:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough coins")
                return
        if int(off["tier"]) > meta.tier_cap():
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("SPUDNIK level %d gates T%d" % [meta.char_level(), int(off["tier"])])
                return
        if weapons_run.size() >= meta.weapon_slots():
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("the holster is full (%d slots)" % meta.weapon_slots())
                return
        _cc_spend(price)
        _cc_sync()
        meta.add_armory(String(off["wid"]), int(off["tier"]))
        weapons_run.append({"id": String(off["wid"]), "tier": int(off["tier"]), "cd": 0.0})
        off["sold"] = true
        Jukebox.sfx("cs_buy", -4.0)
        _rebuild_slots()
        # THE RIGHT-SHEET LAW (v0.3.4-5): a market buy rebuilds THE MARKET -
        # the patch-4 rename pointed these at the universal shop and a buy
        # hijacked the whole break.
        _cs_reopen(func(): _market_open())

func _shop_buy_item(off: Dictionary) -> void:
        var price := int(off["price"])
        if run_ccoins < price:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough coins")
                return
        _cc_spend(price)
        _cc_sync()
        var it: Dictionary = CSData.ITEMS[String(off["iid"])]
        _apply_stat(String(it["stat"]), it["v"])
        off["sold"] = true
        Jukebox.sfx("cs_buy", -4.0)
        _cs_reopen(func(): _market_open())

func _shop_buy_supply(cid: String, price: int) -> void:
        if run_ccoins < price:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough coins")
                return
        _cc_spend(price)
        _cc_sync()
        match cid:
                "heal30": p_hp = minf(p_max_hp, p_hp + 30.0)
                "plate": _apply_stat("armor", 1)
                "crate":
                        for e in enemies.duplicate():
                                _hurt_enemy(e, 60.0)
                        _shockwave(p_pos, 900.0)
        Jukebox.sfx("cs_buy", -4.0)
        _cs_reopen(func(): _market_open())

func _allies_deployed(aid: String) -> int:
        var n := 0
        for a in allies:
                if a["id"] == aid:
                        n += 1
        return n

func _shop_buy_ally(aid: String, price: int) -> void:
        if run_ccoins < price:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough coins")
                return
        var deployed := _allies_deployed(aid)
        if deployed == 0 and allies.size() >= _ally_cap():
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("the leash is full (%d allies)" % _ally_cap())
                return
        _cc_spend(price)
        _cc_sync()
        if deployed == 0:
                # THE ROSTER LAW: the ally deploys AT its persistent level
                _deploy_ally(aid, maxi(1, meta.ally_level(aid)))
        else:
                for a in allies:
                        if a["id"] == aid and int(a["level"]) < CSData.ALLY_MAX_LEVEL:
                                a["level"] = int(a["level"]) + 1
                                break
        Jukebox.sfx("cs_buy", -4.0)
        _cs_reopen(func(): _market_open())

func _wave_buy_merge(pr: Dictionary, cost: int) -> void:
        var wid: String = pr["wid"]
        var tier: int = int(pr["tier"])
        if meta.tier_cap() < tier + 1:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("SPUDNIK level %d gates T%d" % [meta.char_level(), tier + 1])
                return
        if run_ccoins < cost:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough coins")
                return
        if meta.count_armory(wid, tier) < 2:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("the bench needs two T%d copies" % tier)
                return
        meta.remove_armory(wid, tier)
        meta.remove_armory(wid, tier)
        _cc_spend(cost)
        _cc_sync()
        meta.add_armory(wid, tier + 1)
        run_merges += 1
        for w in weapons_run:
                if w["id"] == wid and int(w["tier"]) == tier:
                        w["tier"] = tier + 1
                        break
        Jukebox.sfx("cs_levelup", -3.0)
        _banner("MERGED! %s T%d" % [CSData.WEAPONS[wid]["name"], tier + 1], false)
        _rebuild_slots()
        # THE RIGHT-SHEET LAW: the merge lives on the MERGE BENCH - the bench
        # rebuilds, the chain never loses its sheet.
        _cs_reopen(func(): _merge_menu_open())

func _shop_sell_weapon(wr: Dictionary, refund: int) -> void:
        if weapons_run.size() <= 1:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("SPUDNIK drops in armed - the last gun stays")
                return
        weapons_run.erase(wr)
        meta.remove_armory(String(wr["id"]), int(wr["tier"]))
        _cc_earn(refund)
        _cc_sync()
        Jukebox.sfx("cs_sell", -6.0)
        _rebuild_slots()
        _cs_reopen(func(): _market_open())

func _merge_pairs() -> Array:
        # two same weapons, same tier -> the next tier at half price (the law)
        var out := []
        for wid in CSData.WEAPON_ORDER:
                for tier in [1, 2]:
                        if meta.count_armory(wid, tier) >= 2:
                                out.append({"wid": wid, "tier": tier,
                                        "cost": CSData.merge_price(wid, tier)})
        return out

# ============================================================== THE SHOP
## v0.3.4-4 THE SHOP LIST LAW (the owner: "the shop button opens the game
## shop which is not what i said it should do, as you see in all other
## games, shop button opens a list that lets you buy things that costs real
## GOGAcoins like the themes or weapons or the merging and other stuff i
## described tons of times"): THE SHOP is the UNIVERSAL GOGACoins list -
## the invaders/matcher shape: the Arc.coin_chip wallet header, plain
## Arc.coin_button rows (label + price + THE coin icon), a CLOSE. The HUD
## button opens it at ANY phase. Four shelves, every price REAL GOGACoins:
##   THE PLACES - the worlds (desert free-default, park 400)
##   THE GUNS   - owning one puts its offer in EVERY wave market
##   THE LAB    - the merging (WEAPON LAB) + FOUNDRY, learned forever
##   THE CREW   - owning one lists it in the deploy rows forever
## The cosmic-coin store is THE ARMORY again (_armory_open, the tree's
## button); the wave market stays the break's own flow.
var _armory_tab := "weapons"

func _shop_open() -> void:
        _cs_open("THE SHOP", func(box: VBoxContainer): _build_shop(box), CS_YELLOW,
                        true, "shop")

## the stack-safe rebuild: the live shop pops, a fresh one pushes
func _shop_rebuild() -> void:
        _cs_reopen(func(): _shop_open())

## the old name lives on (the probe + old callers): the four-tab
## cosmic-coin store, THE ARMORY
func _armory_open() -> void:
        _cs_open("THE ARMORY", func(box: VBoxContainer): _build_armory(box),
                        CS_YELLOW, false, "armory")

func _build_shop(box: VBoxContainer) -> void:
        # the universal wallet header - the full GOGABox wallet
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        box.add_child(wallet)
        var scroll := _cs_scroll()
        scroll.custom_minimum_size = Vector2(0, get_viewport_rect().size.y * 0.44)
        box.add_child(scroll)
        var shelf := _cs_shelf(scroll)
        _shop_section(shelf, "THE PLACES")
        for tid in CSData.THEME_ORDER:
                shelf.add_child(_shop_theme_row(tid))
        _shop_section(shelf, "THE GUNS")
        for wid in CSData.SHOP_GUNS:
                shelf.add_child(_shop_gun_row(wid))
        _shop_section(shelf, "THE LAB")
        shelf.add_child(_shop_lab_row("l3", "WEAPON LAB", 800,
                        "two same weapons, same tier, merge one tier up"))
        shelf.add_child(_shop_lab_row("l4", "FOUNDRY", 500,
                        "every merge costs 25% less"))
        _shop_section(shelf, "THE CREW")
        for aid in CSData.ALLY_ORDER:
                shelf.add_child(_shop_crew_row(aid))
        _cs_scroll_taps(scroll)
        _fit_scroll(scroll, shelf, 0.5)
        var actions := HBoxContainer.new()
        actions.alignment = BoxContainer.ALIGNMENT_CENTER
        box.add_child(actions)
        var cb := Arc.button("CLOSE", Vector2(0, 108), _fs(24), Arc.GOOD,
                        func(): _cs_close_top())
        cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        actions.add_child(cb)

## a small yellow shelf caption inside the universal list
func _shop_section(shelf: VBoxContainer, txt: String) -> void:
        var l := Arc.fit_label(txt, _fs(20), Arc.HOT, 1000)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        shelf.add_child(l)

## the owned row of the universal list (matcher/invaders green line)
func _shop_row_owned(txt: String) -> Control:
        var l := Arc.fit_label(txt, _fs(20), Color("58c470"), 1000)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        return l

## one universal price row: an Arc.coin_button, disabled while broke
func _shop_price_row(txt: String, price: int, col: Color, cb: Callable) -> Button:
        var b := Arc.coin_button(txt, Vector2(0, 96), _fs(22), col, cb)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        if Box.coins() < price:
                b.disabled = true
        return b

func _shop_theme_row(tid: String) -> Control:
        var th: Dictionary = CSData.THEMES[tid]
        var price := int(th["gogacoins"])
        if meta.has_theme(tid) or price == 0:
                return _shop_row_owned("%s  -  %s" % [String(th["name"]).to_upper(),
                                "WORN NOW" if theme_id == tid else "OWNED"])
        return _shop_price_row("%s  -  %d" % [String(th["name"]).to_upper(), price],
                        price, Color("c47a2a"), func(): _shop_buy_theme(tid, price))

func _shop_buy_theme(tid: String, price: int) -> void:
        # idempotent-safe: an already-Box-owned place never pays twice - it
        # just syncs the game's own ownership
        # v0.3.5-6 THE BUY-ONLY LAW (the owner: "when I buy a place, it's
        # auto-playing it replacing the one I am currently in which is bad,
        # it should just buy it without applying it"): the shop only OWNS
        # the place - the worn one stays on; equipping happens in the
        # armory (tap the owned place there to wear it).
        if not Box.item_owned(game_id, "theme", tid) \
                        and not Box.buy_item(game_id, "theme", tid, price):
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("need %d more GOGACoins" % maxi(0, price - Box.coins()))
                return
        meta.own_theme(tid)
        Jukebox.sfx("cs_buy", -4.0)
        Arc.confetti(_overlay_root_ref(), get_viewport_rect().size / 2.0, 30)
        _toast_show("%s owned - equip it from the ARMORY" \
                        % String(CSData.THEMES[tid]["name"]).to_upper())
        _shop_rebuild()

func _shop_gun_row(wid: String) -> Control:
        var wd: Dictionary = CSData.WEAPONS[wid]
        var price: int = int(CSData.SHOP_GUNS[wid])
        if Box.item_owned(game_id, "guns", wid):
                return _shop_row_owned("%s  -  IN THE MARKET"
                                % String(wd["name"]).to_upper())
        return _shop_price_row("%s  -  %d" % [String(wd["name"]).to_upper(), price],
                        price, Color("8a4ab8"), func(): _shop_buy_gun(wid, price))

func _shop_buy_gun(wid: String, price: int) -> void:
        if not Box.buy_item(game_id, "guns", wid, price):
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("need %d more GOGACoins" % maxi(0, price - Box.coins()))
                return
        Jukebox.sfx("cs_buy", -4.0)
        Arc.confetti(_overlay_root_ref(), get_viewport_rect().size / 2.0, 30)
        _shop_rebuild()

func _shop_lab_row(nid: String, nm: String, price: int, desc: String) -> Control:
        if meta.tree_node(nid):
                return _shop_row_owned("%s  -  LEARNED" % nm)
        return _shop_price_row("%s  -  %d" % [nm, price], price, Color("2a8a5a"),
                        func(): _shop_buy_lab(nid, price))

func _shop_buy_lab(nid: String, price: int) -> void:
        if not Box.spend(price):
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("need %d more GOGACoins" % maxi(0, price - Box.coins()))
                return
        meta.gogabuy_node(nid)
        Jukebox.sfx("cs_buy", -4.0)
        Arc.confetti(_overlay_root_ref(), get_viewport_rect().size / 2.0, 30)
        _shop_rebuild()

func _shop_crew_row(aid: String) -> Control:
        var ad: Dictionary = CSData.ALLIES[aid]
        var price: int = int(CSData.SHOP_CREW[aid])
        if meta.has_ally(aid):
                return _shop_row_owned("%s  -  DEPLOYABLE LV %d" %
                                [String(ad["name"]).to_upper(), meta.ally_level(aid)])
        return _shop_price_row("%s  -  %d" % [String(ad["name"]).to_upper(), price],
                        price, Color("4a5ab8"), func(): _shop_buy_crew(aid, price))

func _shop_buy_crew(aid: String, price: int) -> void:
        # idempotent-safe: box-owned crew just syncs the deploy list
        if not Box.item_owned(game_id, "crew", aid) \
                        and not Box.buy_item(game_id, "crew", aid, price):
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("need %d more GOGACoins" % maxi(0, price - Box.coins()))
                return
        meta.own_ally(aid)
        Jukebox.sfx("cs_buy", -4.0)
        Arc.confetti(_overlay_root_ref(), get_viewport_rect().size / 2.0, 30)
        _shop_rebuild()

func _build_armory(box: VBoxContainer) -> void:
        # the wallet header - the GOGACoins chip is ALWAYS visible now
        var head := HBoxContainer.new()
        head.alignment = BoxContainer.ALIGNMENT_CENTER
        head.add_theme_constant_override("separation", 8)
        box.add_child(head)
        var ccbox := _cs_black_box(head, Vector2(170, 36))
        var hh := HBoxContainer.new()
        ccbox.add_child(hh)
        hh.add_child(_cs_icon(_t("coin"), 24))
        hh.add_child(_cs_label(str(meta.coins()), 18, CS_YELLOW))
        var gcbox := _cs_black_box(head, Vector2(210, 36))
        var gh := HBoxContainer.new()
        gcbox.add_child(gh)
        gh.add_child(_cs_icon(_t("gogacoin"), 22))
        gh.add_child(_cs_label("%d GOGACoins" % Box.coins(), 14, CS_GREEN))
        _cs_label("SPUDNIK LV %d - tier cap T%d" % [meta.char_level(), meta.tier_cap()],
                        13, CS_BLUE, head)
        # the tabs
        var tabs := HBoxContainer.new()
        tabs.alignment = BoxContainer.ALIGNMENT_CENTER
        tabs.add_theme_constant_override("separation", 6)
        box.add_child(tabs)
        for tab in ["weapons", "allies", "themes", "loadout"]:
                var t_s: String = tab
                var lbl := "PLACES" if t_s == "themes" else t_s.to_upper()
                var b := _cs_button(lbl, 13,
                                CS_YELLOW if _armory_tab == t_s else CS_WHITE, func():
                        _armory_tab = t_s
                        # THE ARMORY TABS LAW (v0.3.4-5): a tab rebuilds THE
                        # ARMORY - the patch-4 copy-paste sent it to THE SHOP
                        # and hijacked the sheet.
                        _cs_reopen(func(): _armory_open()))
                tabs.add_child(b)
        # the shelf scroll (both axes, THE BIG-UI LAW + THE SCROLL TRUTH)
        var scroll := _cs_scroll()
        scroll.custom_minimum_size = Vector2(0, get_viewport_rect().size.y * 0.46)
        box.add_child(scroll)
        var shelf := _cs_shelf(scroll)
        match _armory_tab:
                "weapons": _armory_weapons(shelf)
                "allies": _armory_allies(shelf)
                "themes": _armory_themes(shelf)
                "loadout": _armory_loadout(shelf)
        _cs_scroll_taps(scroll)
        _fit_scroll(scroll, shelf, 0.48)
        # the actions
        var actions := HBoxContainer.new()
        actions.alignment = BoxContainer.ALIGNMENT_CENTER
        actions.add_theme_constant_override("separation", 14)
        box.add_child(actions)
        actions.add_child(_cs_button("BACK", 14, CS_WHITE, func():
                # the RESUME + FRESH DOOR laws live inside _cs_close_top now:
                # the close resumes a stranded break and refreshes the door.
                _cs_close_top()))

func _armory_weapons(shelf: VBoxContainer) -> void:
        var note := _cs_label("every weapon starts T1 - own all 13, merge copies to climb tiers",
                        11, CS_WHITE)
        note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        shelf.add_child(note)
        var rows := []
        for wid in CSData.WEAPON_ORDER:
            var wid_s: String = wid
            var wd: Dictionary = CSData.WEAPONS[wid_s]
            var owned := meta.has_weapon(wid_s)
            var price := CSData.weapon_price(wid_s, 1)
            var lines := [
                    _weapon_stat_line(wid_s, 1),
                    ("%d copies owned" % meta.weapon_count(wid_s)) if owned else "high price - the one-by-one law",
            ]
            var can := not owned and meta.coins() >= price
            rows.append(_shop_card(String(wd["name"]),
                            CS_GREEN if owned else CS_YELLOW, lines,
                            CS_GREEN if owned else CS_EDGE,
                            "OWNED" if owned else "BUY %d CC" % price,
                            CS_GREEN if owned else CS_YELLOW, func():
                            _armory_buy_weapon(wid_s, price), can))
        _cards_grid(shelf, rows, 3)

func _cards_grid(shelf: VBoxContainer, cards: Array, cols: int) -> void:
        var grid := GridContainer.new()
        grid.columns = cols
        grid.add_theme_constant_override("h_separation", 8)
        grid.add_theme_constant_override("v_separation", 8)
        grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        shelf.add_child(grid)
        for c in cards:
                grid.add_child(c)

func _armory_buy_weapon(wid: String, price: int) -> void:
        if meta.has_weapon(wid):
                return
        if not _cc_spend(price):
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough coins")
                return
        meta.add_armory(wid, 1)
        _cc_sync()
        Jukebox.sfx("cs_buy", -4.0)
        _cs_reopen(func(): _armory_open())

func _armory_allies(shelf: VBoxContainer) -> void:
        var note := _cs_label("allies cost the MOST on purpose - they deploy in the wave shop. A raise is FOREVER (the roster law)",
                        11, CS_WHITE)
        note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        shelf.add_child(note)
        var rows := []
        for aid in CSData.ALLY_ORDER:
            var aid_s: String = aid
            var ad: Dictionary = CSData.ALLIES[aid_s]
            var owned := meta.has_ally(aid_s)
            var price: int = int(ad["price"])
            var lv := meta.ally_level(aid_s)
            if not owned:
                    var can := meta.coins() >= price
                    rows.append(_shop_card(String(ad["name"]), CS_YELLOW,
                                    [String(ad["desc"])], CS_EDGE,
                                    "BUY %d CC" % price, CS_YELLOW, func():
                                    _armory_buy_ally(aid_s, price), can))
            else:
                    # THE ROSTER LAW: the raise rows - what the NEXT level means
                    var lines := [String(ad["desc"]), _cs_lv_pips(lv, CS_GREEN)]
                    var btn_txt := "LV %d - MAXED" % lv
                    var can2 := false
                    if lv < CSData.ALLY_MAX_LEVEL:
                            lines.append("next: " + String((ad["lvs"] as Array)[lv]))
                            var rp := CSData.ally_raise_price(aid_s, lv + 1)
                            btn_txt = "RAISE TO LV %d - %d CC" % [lv + 1, rp]
                            can2 = meta.coins() >= rp
                    rows.append(_shop_card(String(ad["name"]), CS_GREEN, lines,
                                    CS_GREEN, btn_txt, CS_YELLOW, func():
                                    _armory_raise_ally(aid_s), can2 or
                                    lv >= CSData.ALLY_MAX_LEVEL))
        _cards_grid(shelf, rows, 3)

func _armory_buy_ally(aid: String, price: int) -> void:
        if meta.has_ally(aid):
                return
        if not _cc_spend(price):
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough coins")
                return
        meta.own_ally(aid)
        _cc_sync()
        Jukebox.sfx("cs_buy", -4.0)
        _cs_reopen(func(): _armory_open())

## v0.3.8-2 THE ROSTER LAW: the armory raises an owned ally's PERSISTENT
## level for cosmic coins - the wave shop then deploys AT that level.
func _armory_raise_ally(aid: String) -> void:
        var lv := meta.ally_level(aid)
        if lv < 1 or lv >= CSData.ALLY_MAX_LEVEL:
                return
        var price := CSData.ally_raise_price(aid, lv + 1)
        if not _cc_spend(price):
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough coins")
                return
        meta.raise_ally(aid)
        _cc_sync()
        Jukebox.sfx("cs_levelup", -3.0)
        _banner("%s raised to LV %d" % [String(CSData.ALLIES[aid]["name"]), lv + 1], true)
        _cs_reopen(func(): _armory_open())

func _armory_themes(shelf: VBoxContainer) -> void:
        ## THE ECONOMY BORDER LAW (v0.3.4-2): PLACES cost GOGACOINS - the box
        ## wallet, exactly like the matcher skins - while guns, allies and
        ## everything in-run cost cosmic coins. The tab says both sides.
        var note := _cs_label("places cost GOGACOINS (your GOGABox wallet) - guns, allies and everything in-run cost cosmic coins",
                        11, CS_WHITE)
        note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        shelf.add_child(note)
        var rows := []
        for tid in CSData.THEME_ORDER:
            var tid_s: String = tid
            var th: Dictionary = CSData.THEMES[tid_s]
            var owned := meta.has_theme(tid_s)
            var price: int = int(th["gogacoins"])
            var on := theme_id == tid_s
            var lines := ["day + night variants"]
            if on:
                    lines.append("WORN NOW")
            # v0.3.5-6 THE BUY-ONLY LAW: the shop no longer wears - an
            # OWNED place equips here for free (tap = wear), only an
            # unowned one needs the wallet
            var can := owned or Box.coins() >= price
            rows.append(_shop_card(String(th["name"]), CS_YELLOW if on else (CS_GREEN if owned else CS_WHITE),
                            lines, CS_YELLOW if on else (CS_GREEN if owned else CS_EDGE),
                            "WORN" if on else ("WEAR" if owned else "BUY %d" % price),
                            CS_GREEN if on else CS_YELLOW, func():
                            _armory_buy_theme(tid_s, price), not on and can, "", Callable(), CS_BLUE,
                            not on and not owned))
        _cards_grid(shelf, rows, 2)

func _armory_buy_theme(tid: String, price: int) -> void:
        if meta.has_theme(tid):
                _retheme(tid, night)
                _cs_reopen(func(): _armory_open())
                return
        ## the box wallet pays (Box.spend), the box records the place
        if not Box.spend(price):
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("need %d more GOGACoins" % maxi(0, price - Box.coins()))
                return
        Box.buy_item(game_id, "theme", tid, 0)
        meta.own_theme(tid)
        _retheme(tid, night)
        Jukebox.sfx("cs_buy", -4.0)
        if phase == "boot":
                _cs_reopen(func(): _optionals_open())
        else:
                _cs_reopen(func(): _armory_open())

func _armory_loadout(shelf: VBoxContainer) -> void:
        var info := _cs_label("the guns SPUDNIK drops in with (tap to toggle) - %d/%d slots" \
                        % [meta.loadout().size(), meta.weapon_slots()], 11, CS_WHITE)
        info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        shelf.add_child(info)
        var rows := []
        for inst in meta.armory():
            var inst_d: Array = inst
            var wid: String = inst_d[0]
            var tier: int = int(inst_d[1])
            var lo := meta.loadout()
            var on: bool = lo.has(wid)
            rows.append(_shop_card("%s T%d" % [String(CSData.WEAPONS[wid]["name"]), tier],
                            CS_YELLOW if on else CS_WHITE,
                            [_weapon_stat_line(wid, tier), "equipped" if on else "benched"],
                            CS_GREEN if on else CS_EDGE,
                            "UNEQUIP" if on else "EQUIP",
                            CS_BLUE, func(): _armory_toggle(wid, tier)))
        _cards_grid(shelf, rows, 4)
        # the duplicate SELL bench (the 40% law, outside the run)
        var dup_note := _cs_label("SELL a duplicate copy (refunds 40% of its tier price)", 11, CS_WHITE)
        dup_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        shelf.add_child(dup_note)
        var srows := []
        for inst2 in meta.armory():
            var inst2_d: Array = inst2
            var wid2: String = inst2_d[0]
            var tier2: int = int(inst2_d[1])
            if meta.count_armory(wid2, tier2) < 2:
                    continue
            var refund := CSData.sell_price(CSData.weapon_price(wid2, tier2))
            srows.append(_shop_card("%s T%d x%d" % [String(CSData.WEAPONS[wid2]["name"]), tier2,
                            meta.count_armory(wid2, tier2)], CS_RED,
                            ["a duplicate copy"], CS_EDGE, "SELL +%d CC" % refund, CS_RED,
                            func(): _armory_sell(wid2, tier2, refund)))
        if srows.is_empty():
                var none := _cs_label("no duplicates on the shelf", 11, CS_WHITE)
                none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                shelf.add_child(none)
        else:
                _cards_grid(shelf, srows, 4)

func _armory_toggle(wid: String, _tier: int) -> void:
        var l2 := meta.loadout()
        if l2.has(wid):
                if l2.size() <= 1:
                        _toast_show("SPUDNIK drops in armed")
                        return
                l2.erase(wid)
        elif l2.size() < meta.weapon_slots():
                l2.append(wid)
        else:
                _toast_show("the holster is full (%d slots)" % meta.weapon_slots())
                return
        meta.set_loadout(l2)
        _rebuild_weapons()
        _cs_reopen(func(): _armory_open())

func _armory_sell(wid: String, tier: int, refund: int) -> void:
        if meta.count_armory(wid, tier) < 2:
                return
        meta.remove_armory(wid, tier)
        _cc_earn(refund)
        _cc_sync()
        Jukebox.sfx("cs_sell", -6.0)
        _cs_reopen(func(): _armory_open())

# ================================================================== INFO
## THE INFO LAW (v0.3.4-5, the owner: "put another button in the top left and
## call it info... show the whole status for real, like luck = nn% and
## damage = nn... as a list"): the run's own truth sheet. The header carries
## what was collected; every stat wears his exact five-line shape.
const INFO_STATS := [
        ["dmg_m", "DAMAGE", true], ["aspeed_m", "ATTACK SPEED", true],
        ["spd_m", "MOVE SPEED", true], ["range_m", "RANGE", true],
        ["crit", "CRIT CHANCE", true], ["armor", "ARMOR", false],
        ["regen", "REGEN", false], ["luck", "LUCK", true],
        ["dodge", "DODGE", true], ["hp_add", "BONUS HP", false],
        ["lifesteal", "LIFESTEAL", true],
]

func _info_open() -> void:
        _cs_open("RUN INFO", func(box: VBoxContainer): _build_info(box),
                        CS_BLUE, true, "info")

## the pure model (the probe reads it): one block per stat, the owner's
## exact shape - line 0 the name, then base / up / down / result.
## v0.3.5-6 THE CLEAR MATH LAW (the owner: "the info menu shows weird
## stuff in the decrease line, shows -nn% ... and with (+nn%) that is
## written with red color, I am not sure what is the thing in the () but
## make the math clearer"): the contradictory percent-of-base notes are
## DEAD. The stat is a straight ledger - result = base + up - down - and
## the result line now SHOWS that exact equation in the stat's own unit:
##   result: 137%  (130% + 30% - 23%)
func _info_stat_rows() -> Array:
        var rows := []
        for def in INFO_STATS:
                var k: String = def[0]
                var is_pct: bool = bool(def[2])
                var base: float = float(stat_base.get(k, 0.0))
                var up: float = float(stat_up.get(k, 0.0))
                var down: float = float(stat_down.get(k, 0.0))
                var live_v: float = float(stats.get(k, base))
                var fmt := func(v: float) -> String:
                        if is_pct:
                                return "%d%%" % int(round(v * 100.0))
                        return String.num(v, 1)
                var eq := ""
                if absf(up) > 0.0001 or absf(down) > 0.0001:
                        eq = "  (%s + %s - %s)" % [fmt.call(base),
                                        fmt.call(up), fmt.call(down)]
                rows.append({
                        "key": k,
                        "name": String(def[1]),
                        "base": fmt.call(base), "up": fmt.call(up),
                        "down": fmt.call(down), "result": fmt.call(live_v),
                        "eq": eq,
                })
        return rows

func _build_info(box: VBoxContainer) -> void:
        var head := _cs_black_box(box, Vector2(0, 0))
        var hv := VBoxContainer.new()
        head.add_child(hv)
        var h1 := _cs_label("WAVE %d   KILLS %d   SCORE %d" \
                        % [run_wave, run_kills, score], 14, CS_YELLOW)
        var h2 := _cs_label("the vault: %d cosmic coins  -  %d XP  -  LV %d" \
                        % [run_ccoins, run_xp, run_level], 13, CS_GREEN)
        h1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        h2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        hv.add_child(h1)
        hv.add_child(h2)
        # THE DIRECT SCROLL LAW (v0.3.5-1, the owner: "the info menu is not
        # directly scrollable, there is a sidebar but i want to scroll up-down
        # directly normally"): the raw-touch BoxScroll owns the drag - the
        # finger scrolls the sheet ANYWHERE, the scrollbar-sidebar is dead
        var scroll := BoxScroll.new()
        scroll.game_safe = true
        scroll.process_mode = Node.PROCESS_MODE_ALWAYS
        scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        scroll.custom_minimum_size = Vector2(0, get_viewport_rect().size.y * 0.5)
        box.add_child(scroll)
        var shelf := VBoxContainer.new()
        shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        shelf.add_theme_constant_override("separation", 6)
        scroll.add_child(shelf)
        for r in _info_stat_rows():
                var b := _cs_black_box(shelf, Vector2(560, 0))
                var vb := VBoxContainer.new()
                vb.add_theme_constant_override("separation", 1)
                b.add_child(vb)
                var lines: Array = [
                        "%s:" % String(r["name"]),
                        "base: %s" % String(r["base"]),
                        "up: +%s" % String(r["up"]),
                        "down: -%s" % String(r["down"]),
                        "result: %s%s" % [String(r["result"]), String(r["eq"])],
                ]
                var first := true
                for ln in lines:
                        var col := CS_WHITE
                        if first:
                                col = CS_YELLOW
                        elif String(ln).begins_with("up"):
                                col = CS_GREEN
                        elif String(ln).begins_with("down"):
                                col = CS_RED
                        var l := _cs_label(String(ln), 12, col)
                        if first:
                                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        vb.add_child(l)
                        first = false
        # the BoxScroll owns the height: the shelf hugs its content, the
        # scroll clamps at half the viewport (the _fit_scroll ghost pass
        # was a ScrollContainer law - the raw-touch scroll needs no second pass)
        await get_tree().process_frame
        if is_instance_valid(scroll) and is_instance_valid(shelf):
                scroll.custom_minimum_size.y = clampf(
                                shelf.get_combined_minimum_size().y + 8.0, 120.0,
                                get_viewport_rect().size.y * 0.58)

# ============================================================== OPTIONALS
## THE BOOT SCREEN, REBORN (the owner: the old one was FUCKING WEIRD):
## the 6 start cards wear the NEW potato art, the themes are two cards with
## real DAY/NIGHT chips, THE ARMORY + THE TREE + DROP IN.
func _optionals_open() -> void:
        ## closable=false: THE DOOR (v0.3.4-2, the owner: "why could someone
        ## close the important window?") - no X, and the back law guards it.
        _cs_open("COSMIC SPUD", func(box: VBoxContainer): _build_optionals(box),
                        CS_YELLOW, false, "door")

func _build_optionals(box: VBoxContainer) -> void:
        var sub := _cs_label("pick one of the six starts", 12, CS_WHITE)
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(sub)
        if not _boot_hint.is_empty():
                var hint := _cs_label(_boot_hint, 12, CS_RED)
                hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                box.add_child(hint)
        # the six start cards (2 rows x 3) - THE SCROLL TRUTH: the door
        # scrolls on raw touch too, even over the big start cards
        var scroll := _cs_scroll()
        scroll.custom_minimum_size = Vector2(0, get_viewport_rect().size.y * 0.5)
        box.add_child(scroll)
        var shelf := _cs_shelf(scroll)
        shelf.add_theme_constant_override("separation", 8)
        var grid := GridContainer.new()
        # THE BIG TEXT LAW's door handling (v0.3.4-5): two across - three big
        # cards overflow the portrait door, two fill it with room to read
        grid.columns = 2
        grid.add_theme_constant_override("h_separation", 10)
        grid.add_theme_constant_override("v_separation", 10)
        grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        shelf.add_child(grid)
        for sid in CSData.START_ORDER:
                grid.add_child(_start_card(sid))
        # the themes: two cards with DAY / NIGHT chips
        var tsec := _cs_label("THE GROUNDS", 12, CS_BLUE)
        tsec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        shelf.add_child(tsec)
        var trow := HBoxContainer.new()
        trow.alignment = BoxContainer.ALIGNMENT_CENTER
        trow.add_theme_constant_override("separation", 10)
        shelf.add_child(trow)
        for tid in CSData.THEME_ORDER:
                trow.add_child(_theme_card(tid))
        # the wallet line - BOTH currencies, named (THE ECONOMY BORDER LAW)
        var info := _cs_label("LV %d   -   %d cosmic coins   -   tier cap T%d   -   %d GOGACoins" \
                        % [meta.char_level(), meta.coins(), meta.tier_cap(), Box.coins()], 14, CS_YELLOW)
        info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        shelf.add_child(info)
        _cs_scroll_taps(scroll)
        _fit_scroll(scroll, shelf, 0.5)
        # the actions
        var actions := HBoxContainer.new()
        actions.alignment = BoxContainer.ALIGNMENT_CENTER
        actions.add_theme_constant_override("separation", 14)
        box.add_child(actions)
        # v0.3.4-4 THE SHOP LIST LAW: every SHOP button in the game opens
        # the universal GOGACoins list; the cosmic-coin store is THE ARMORY
        # and wears its own name again.
        actions.add_child(_cs_button("SHOP", 15, CS_YELLOW, func(): _shop_open()))
        actions.add_child(_cs_button("ARMORY", 15, CS_YELLOW, func(): _armory_open()))
        # v0.3.8-2: the STAT TRACKS wear their own door button - the lifetime
        # upgrades are reachable outside the break chain too
        actions.add_child(_cs_button("STATS", 15, CS_BLUE, func(): _stats_menu_open()))
        actions.add_child(_cs_button("SKILLS", 15, CS_GREEN, func(): _skills_menu_open()))
        actions.add_child(_cs_button("DROP IN", 18, CS_GREEN, func(): _start_run()))

func _start_card(sid: String) -> Button:
        var s: Dictionary = CSData.STARTS[sid]
        var b := Button.new()
        var picked: bool = sid == start_id
        var st := _cs_box_style(CS_YELLOW if picked else CS_EDGE, CS_BOX)
        st.corner_radius_top_left = 12
        st.corner_radius_top_right = 12
        st.corner_radius_bottom_left = 12
        st.corner_radius_bottom_right = 12
        b.add_theme_stylebox_override("normal", st)
        var hov := _cs_box_style(CS_GREEN if not picked else CS_YELLOW, CS_BOX2)
        b.add_theme_stylebox_override("hover", hov)
        var vb := VBoxContainer.new()
        vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.set_anchors_preset(Control.PRESET_FULL_RECT)
        vb.add_theme_constant_override("separation", 1)
        vb.offset_left = 8
        vb.offset_top = 6
        vb.offset_right = -8
        b.add_child(vb)
        var hrow := HBoxContainer.new()
        hrow.alignment = BoxContainer.ALIGNMENT_CENTER
        hrow.add_theme_constant_override("separation", 8)
        vb.add_child(hrow)
        var art := TextureRect.new()
        art.texture = _t("hero_" + sid + "_f0")
        art.custom_minimum_size = Vector2(64, 64)
        art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        hrow.add_child(art)
        ## THE TEXT-FIT LAW: the card is MEASURED, never guessed. The stats
        ## lines set the width floor, the wrapped perk sets the height floor -
        ## the box grows to fit the text, so nothing can spill out again.
        var stats_txt := "HP %d  DMG %d%%  SPD %d%%\nASPD %d%%  RNG %d%%  ARM %d  LUCK %d%%  DODGE %d%%" % [
                int(s["hp"]), int(s["dmg"] * 100), int(s["spd"] * 100),
                int(s["aspeed"] * 100), int(s["range"] * 100), int(s["armor"]),
                int(round(float(s.get("luck", 0.0)) * 100)), int(round(float(s.get("dodge", 0.0)) * 100))]
        var w1 := _cs_text_w(stats_txt.split("\n")[0], 12)
        var w2 := _cs_text_w(stats_txt.split("\n")[1], 12)
        var stats_w: float = maxf(w1, w2)
        var cw: float = maxf(stats_w, 250.0)
        var nm := _cs_fit_label(String(s["name"]), 16, s["tint"], maxf(90.0, cw - 74.0))
        nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        hrow.add_child(nm)
        var st_txt := _cs_label(stats_txt, 12, CS_WHITE)
        st_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(st_txt)
        var perk_txt := String(s["perk"])
        var pk := _cs_label(perk_txt, 12, CS_GREEN)
        pk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        pk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        pk.custom_minimum_size = Vector2(cw, 0)
        pk.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        vb.add_child(pk)
        var perk_h := _cs_text_h(perk_txt, 12, cw)
        var stats_h := _cs_text_h(stats_txt, 12, cw)
        var name_w := _cs_text_w(String(s["name"]), 16)
        var tag_h := 17.0 if picked else 0.0
        if picked:
                var tag := _cs_label("PICKED", 11, CS_YELLOW)
                tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                vb.add_child(tag)
        # 6 top offset + 64 art + 3 separations + bottom air + stylebox margins
        var min_h := 6.0 + 64.0 + 3.0 + stats_h + perk_h + tag_h + 8.0 + 12.0
        var min_w: float = maxf(262.0, maxf(stats_w + 34.0, 74.0 + name_w + 26.0))
        b.custom_minimum_size = Vector2(min_w, maxf(168.0, min_h))
        b.pressed.connect(func():
                start_id = sid
                meta.d["last_start"] = sid
                meta.save()
                Jukebox.sfx("cs_draft", -8.0)
                _cs_reopen(func(): _optionals_open()))
        return b

func _theme_card(tid: String) -> PanelContainer:
        var th: Dictionary = CSData.THEMES[tid]
        var owned := meta.has_theme(tid)
        var worn := theme_id == tid
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel",
                        _cs_box_style(CS_YELLOW if worn else (CS_GREEN if owned else CS_EDGE), CS_BOX))
        card.custom_minimum_size = Vector2(340, 124)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 4)
        card.add_child(vb)
        var nm := _cs_fit_label(String(th["name"]) + ("  WORN" if worn else ""), 15,
                        CS_YELLOW if worn else CS_WHITE, 300.0)
        nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(nm)
        var chips := HBoxContainer.new()
        chips.alignment = BoxContainer.ALIGNMENT_CENTER
        chips.add_theme_constant_override("separation", 8)
        vb.add_child(chips)
        if owned:
                var day_b := _cs_button("DAY", 12, CS_WHITE if not (worn and not night) else CS_YELLOW,
                                func(): _retheme(tid, false); _cs_reopen(func(): _optionals_open()))
                var nite_b := _cs_button("NIGHT", 12, CS_WHITE if not (worn and night) else CS_YELLOW,
                                func(): _retheme(tid, true); _cs_reopen(func(): _optionals_open()))
                chips.add_child(day_b)
                chips.add_child(nite_b)
        else:
                ## v0.3.4-4 THE COIN-ICON PRICE LAW: the price wears THE coin
                ## icon (the universal design), never the spelled-out words.
                var price: int = int(th["gogacoins"])
                var buy_b := _cs_coin_button("BUY %d" % price, 12, CS_YELLOW,
                                func(): _armory_buy_theme(tid, price))
                chips.add_child(buy_b)
        return card

func _start_run() -> void:
        _boot_hint = ""
        _cs_close_all()
        _start_id_persist()
        run_wave = 1
        run_xp = 0
        run_level = 1
        run_kills = 0
        run_merges = 0
        pending_levels = 0
        second_wind_used = false
        boss_alive = false
        goga_pending = false
        goga_carry = false
        goga_carrier_alive = false
        enemies.clear()
        bullets.clear()
        ebullets.clear()
        pickups.clear()
        allies.clear()
        zones.clear()
        # the skills + run state reset (the meta perks wake up fresh)
        p_shield_up = meta.has_skill("shattered_shield")
        p_shield_charges = int(CSData.skill_num("shattered_shield", "charges",
                        meta.skill_level("shattered_shield"), 1)) if p_shield_up else 0
        p_shield_cd = 0.0
        _static_cd = 6.0
        _adrenaline = 0.0
        stats = _base_stats()
        # v0.3.8-2 THE STAT TRACKS: every owned lifetime level rides the run's
        # BASE - applied through _apply_stat, then the ledgers clean and the
        # snapshot takes it as base (the INFO sheet reads them as base, the
        # run's own picks still file up/down on top)
        for tr in CSData.STAT_TRACKS:
                var tr_d: Dictionary = tr
                var owned_lv := meta.track_level(String(tr_d["id"]))
                for lv in range(1, owned_lv + 1):
                        _apply_stat(String(tr_d["k"]), tr_d["v"])
                        for stp in (tr_d.get("steps", {}) as Dictionary).get(lv, []):
                                _apply_stat(String(stp[0]), stp[1])
                        if lv == 5 and tr_d.has("final"):
                                var fin: Dictionary = tr_d["final"]
                                _apply_stat(String(fin["k"]), fin["v"])
        # THE INFO LAW: the snapshot + clean ledgers for this run
        stat_base = {
                "dmg_m": float(stats["dmg_m"]), "spd_m": float(stats["spd_m"]),
                "aspeed_m": float(stats["aspeed_m"]), "range_m": float(stats["range_m"]),
                "armor": float(stats["armor"]), "crit": float(stats["crit"]),
                "regen": float(stats["regen"]), "luck": float(stats["luck"]),
                "dodge": float(stats["dodge"]), "hp_add": float(stats.get("hp_add", 0.0)),
                "lifesteal": float(stats["lifesteal"]),
        }
        stat_up.clear()
        stat_down.clear()
        p_max_hp = _max_hp()
        p_hp = p_max_hp
        p_pos = ARENA.get_center()
        p_node.texture = _t("hero_" + start_id + "_f0")
        cam.position = _cam_clamp_pos(p_pos)
        _rebuild_weapons()
        # THE VARIED HOLSTER LAW (v0.3.4-5, the owner: "it is weird how all
        # types of characters starts with same weapons"): the start's
        # signature gun rides slot 1 (when owned).
        var sig: String = String(CSData.START_SIG.get(start_id, ""))
        var lo := meta.loadout()
        if sig != "" and lo.has(sig) and String(lo[0]) != sig:
                lo.erase(sig)
                lo.push_front(sig)
                meta.set_loadout(lo)
                _rebuild_weapons()
        if start_id == "engineer":
                # THE ROSTER LAW: the free drop-in drone flies at its level
                _deploy_ally("drone", maxi(1, meta.ally_level("drone")))
        _begin_wave(1)

func _start_id_persist() -> void:
        meta.d["last_start"] = start_id
        meta.save()

# =================================================================== tree
## v0.3.8-3 THE TREE RETIRES WHOLE: the sheet and its buttons are dead.
## The SKILLS system (the 5-level skill depths) is the meta upgrade home
## now, and the wave market + the armory own the cosmic-coin spending.
## The tree's OWNED FLAGS remain the run's data (weapon slots o3/l5, the
## second wind d4, the free reroll u3, the discounts, the lab l1-l5) -
## they read through meta.tree_node exactly as before and they are bought
## through THE SHOP's lab rows (gogabuy_node) as they always were.

# =================================================================== death
func _die() -> void:
        if over or phase == "dead":
                return
        phase = "dead"
        Jukebox.sfx("cs_death", -2.0)
        # v0.3.8-2 THE PURSE LAW: the coins were already home the whole run -
        # death only checkpoints the save (the old meta.earn bank line is dead:
        # it would DOUBLE-CREDIT the persistent purse)
        _cc_sync()
        var gained := meta.bank_char_xp(int(run_kills * 2 + run_wave * 8))
        meta.record_run(run_wave - 1, score, run_kills, run_merges, start_id)
        achievement_max("cs_kills", int(meta.d["kills"]))
        achievement_max("cs_wave", run_wave - 1)
        achievement_max("cs_score", score)
        if run_merges > 0:
                achievement_count("cs_merge", run_merges)
        achievement_count("cs_runs", 1)
        check_achievements()
        _finish_cs(gained)

func _finish_cs(gained_levels: int) -> void:
        var msg := "wave %d  -  %d kills  -  the vault holds %d CC" % [run_wave - 1, run_kills, run_ccoins]
        if gained_levels > 0:
                msg += "  -  SPUDNIK leveled up x%d!" % gained_levels
        _banner(msg, false)
        # the box death menu takes it from here (the /200 bonus rides coin_div;
        # the gogacoins ride add_run_coins -> the wallet)
        finish_run(score, run_coins)

# =================================================================== the banner
func _banner(txt: String, good := true) -> void:
        var root := _overlay_root_ref()
        var holder := Control.new()
        holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
        holder.set_anchors_preset(Control.PRESET_TOP_WIDE)
        holder.offset_top = 170.0
        holder.offset_bottom = 252.0
        root.add_child(holder)
        var l := Label.new()
        l.text = txt
        l.add_theme_font_size_override("font_size", _fs(15))
        l.add_theme_color_override("font_color", CS_YELLOW if good else CS_RED)
        l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
        l.add_theme_constant_override("shadow_offset_x", 2)
        l.add_theme_constant_override("shadow_offset_y", 2)
        l.set_anchors_preset(Control.PRESET_FULL_RECT)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        holder.add_child(l)
        l.pivot_offset = Vector2(l.size.x * 0.5, l.size.y * 0.5)
        l.scale = Vector2.ONE * 0.6
        var tw := l.create_tween()
        tw.tween_property(l, "scale", Vector2.ONE, 0.22) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.tween_interval(1.5)
        tw.tween_property(holder, "modulate:a", 0.0, 0.3)
        tw.tween_callback(holder.queue_free)

# ==================================================================== FX
class FxLayer extends Node2D:
        var game: Node
        func _draw() -> void:
                # the layer passes ITSELF: every draw_* call in _draw_fx must
                # land on the node whose _draw is running (the GDScript
                # receiver trap - self there is the GAME, not this layer)
                game._draw_fx(self)

var _floaters: Array = []    # {pos, txt, col, t, max, size}
var _rings: Array = []       # {pos, r, max, t, col, w}
var _parts: Array = []       # {pos, vel, t, max, col, size, tex}
# v0.3.7-1 the gore ledger: blood stains fade on the ground (40 max)
var _stains: Array = []      # [{pos, r, t, max}]
var _slashes: Array = []     # THE MELEE LAW: {pos, a, rng, arc, t, max}

# the auras (under everything)
## v0.3.8-3 THE SHAPED-ONCE LAW: the elite affix tag pre-shapes its TextLine
## once per affix - the old draw_string re-shaped the same word every frame
## for every elite (text shaping is the most expensive 2D call there is).
var _affix_lines := {}

func _affix_line(affix: String) -> TextLine:
        if not _affix_lines.has(affix):
                var tl := TextLine.new()
                tl.text = String(affix).to_upper()
                tl.font = ThemeDB.fallback_font
                tl.font_size = _fs(7)
                tl.width = 80.0
                tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                _affix_lines[affix] = tl
        return _affix_lines[affix]

func _draw_fx(L: CanvasItem) -> void:
        # v0.3.8-3: ONE clock read per frame (the breathe pulses used to call
        # Time.get_ticks_msec() per enemy - now the whole draw shares it)
        var now_ms := Time.get_ticks_msec()
        # the auras (under everything)
        for e in enemies:
                if e.get("dead", false):
                        continue
                if e.get("aura", 0.0) > 0.0:
                        var breathe := 0.5 + 0.14 * sin(now_ms / 260.0)
                        # THE WRAITH TRUTH LAW (v0.3.4-5): the ring READS - a fat
                        # breathing violet field, never a whisper
                        L.draw_circle(e["pos"], float(e["aura"]),
                                        Color(0.72, 0.42, 1.0, 0.15 * breathe))
                        L.draw_arc(e["pos"], float(e["aura"]), 0, TAU, 32,
                                        Color(0.78, 0.45, 1.0, 0.6), 3.5)
                        L.draw_arc(e["pos"], float(e["aura"]) - 8.0, 0, TAU, 24,
                                        Color(0.78, 0.45, 1.0, 0.25), 2.0)
                # THE HEALER IN THE OPEN LAW (v0.3.4-5): the mender's 500px
                # heal field draws - green cross care, visible care
                if String(e.get("kind", "")) == "mender":
                        var hb := 0.5 + 0.12 * sin(now_ms / 320.0)
                        L.draw_circle(e["pos"], float(e.get("heal", 500.0)),
                                        Color(0.35, 1.0, 0.5, 0.07 * hb))
                        L.draw_arc(e["pos"], float(e.get("heal", 500.0)), 0, TAU, 36,
                                        Color(0.4, 1.0, 0.55, 0.5), 3.0)
                # THE WARDEN LAW (v0.3.4-5): the gold half-damage field draws
                if float(e.get("ward", 0.0)) > 0.0:
                        var wb := 0.5 + 0.13 * sin(now_ms / 280.0)
                        L.draw_circle(e["pos"], float(e["ward"]),
                                        Color(1.0, 0.78, 0.2, 0.09 * wb))
                        L.draw_arc(e["pos"], float(e["ward"]), 0, TAU, 32,
                                        Color(1.0, 0.8, 0.25, 0.55), 3.0)
                        L.draw_arc(e["pos"], float(e["ward"]) - 9.0, 0, TAU, 24,
                                        Color(1.0, 0.85, 0.35, 0.28), 5.0)
                if e.get("marked", false):
                        L.draw_arc(e["pos"], float(e["size"]) * 0.7, 0, TAU, 16,
                                        Color(1, 0.9, 0.3, 0.5), 2.0)
                # the HP bar under a damaged enemy
                if e["hp"] < e["max_hp"]:
                        var w: float = 34.0 * float(e.get("scale_m", 1.0))
                        var yy: float = e["pos"].y - float(e["size"]) * float(e.get("scale_m", 1.0)) - 10.0
                        L.draw_rect(Rect2(e["pos"].x - w * 0.5, yy, w, 4), Color(0, 0, 0, 0.55))
                        L.draw_rect(Rect2(e["pos"].x - w * 0.5, yy, w * clampf(float(e["hp"]) / float(e["max_hp"]), 0, 1), 4),
                                        CS_RED)
                # the shield orbits (the signature: shards + the shell)
                if e.get("shield", null) != null:
                        _draw_shield(e, L)
                # the elite ring + tag (v0.3.8-3: the tag rides a pre-shaped
                # TextLine - draw_string re-shaped its text every frame)
                if e.get("elite", false):
                        L.draw_arc(e["pos"], float(e["size"]) * 0.62 * float(e.get("scale_m", 1.0)),
                                        0, TAU, 20, Color(0.8, 0.4, 1.0, 0.8), 2.5)
                        var tl := _affix_line(String(e["affix"]))
                        tl.draw(L, e["pos"] + Vector2(-40, -float(e["size"]) - 18),
                                        Color(0.9, 0.6, 1.0))
                # THE CARRIER'S GLINT (the gogacoin rider marks its host)
                if e.get("goga", false):
                        var g := 0.5 + 0.5 * absf(sin(now_ms / 200.0))
                        L.draw_arc(e["pos"], float(e["size"]) * 0.7 * (1.0 + 0.08 * g), 0, TAU, 16,
                                        Color(1.0, 0.85, 0.3, 0.5 + 0.3 * g), 2.0)
                # the charger telegraph
                if e.get("state", "") == "wind" and e.get("dash_dir", null) != null:
                        var dd: Vector2 = e["dash_dir"]
                        L.draw_line(e["pos"], e["pos"] + dd * 240.0, Color(1, 0.4, 0.3, 0.5), 3.0)
        # the skills' own fields (drawn under everything)
        if phase == "play" or phase == "break":
                if meta.has_skill("frost_aura"):
                        var breathe_f := 0.5 + 0.12 * sin(Time.get_ticks_msec() / 300.0)
                        L.draw_circle(p_pos, 170.0, Color(0.5, 0.8, 1.0, 0.07 * breathe_f))
                        L.draw_arc(p_pos, 170.0, 0, TAU, 48, Color(0.55, 0.85, 1.0, 0.4), 2.0)
                if meta.has_skill("leech_aura"):
                        var breathe_l := 0.5 + 0.12 * sin(Time.get_ticks_msec() / 240.0)
                        L.draw_circle(p_pos, 140.0, Color(0.85, 0.3, 0.45, 0.06 * breathe_l))
                        L.draw_arc(p_pos, 140.0, 0, TAU, 48, Color(0.9, 0.35, 0.5, 0.35), 2.0)
                # THE SHATTERED SHIELD: the ready ring (a thin blue halo)
                if p_shield_up and meta.has_skill("shattered_shield"):
                        L.draw_arc(p_pos, 30.0, 0, TAU, 32, Color(0.5, 0.85, 1.0, 0.75), 2.5)
        # the zones (strike telegraphs / slams)
        for z in zones:
                var f := 1.0 - float(z["t"]) / float(z["max"])
                if String(z.get("kind", "")) == "pool":
                        # v0.3.7-1 THE FIRE POOL: the molotov's burning ground
                        var flicker := 0.8 + 0.2 * sin(now_ms / 70.0
                                        + z["pos"].x * 0.1)
                        L.draw_circle(z["pos"], float(z["aoe"]),
                                        Color(0.95, 0.35, 0.08, 0.16 * flicker))
                        L.draw_circle(z["pos"], float(z["aoe"]) * 0.6,
                                        Color(1.0, 0.62, 0.15, 0.20 * flicker))
                        L.draw_arc(z["pos"], float(z["aoe"]), 0, TAU, 32,
                                        Color(1.0, 0.45, 0.12, 0.55 * flicker), 3.0)
                        continue
                L.draw_arc(z["pos"], float(z["aoe"]) * (0.4 + 0.6 * f), 0, TAU, 40,
                                        Color(1, 0.6, 0.2, 0.7), 3.0)
                L.draw_circle(z["pos"], float(z["aoe"]) * f, Color(1, 0.6, 0.2, 0.10))
        # v0.3.7-1: the blood stains (under the auras' noise, over the ground)
        for s in _stains:
                var sa := clampf(float(s["t"]) / float(s["max"]), 0.0, 1.0)
                L.draw_circle(s["pos"], float(s["r"]),
                                Color(0.42, 0.07, 0.06, 0.30 * sa))
        # the aim line (a subtle laser sight)
        # v0.3.4-4 THE NO-SHOOT-VFX LAW: the wobbly aim laser line is dead
        # too (it flickered every frame - the same ugly family). The gun's
        # own rotation already says where the bullets go.
        # THE WOW PASS: the low-HP pulse (a red edge breathing on the screen)
        if phase == "play" and p_hp < p_max_hp * 0.3:
                var pulse := 0.5 + 0.5 * absf(sin(now_ms / 260.0))
                var ctr: Vector2 = cam.get_screen_center_position()
                var rad: float = _cam_half().length() * 1.05
                L.draw_arc(ctr, rad, 0, TAU, 64,
                                Color(0.9, 0.15, 0.12, 0.08 + 0.14 * pulse), rad * 0.22)
        # the melee swings (THE MELEE LAW): a bright arc sweeping across
        for s in _slashes:
                var sa: float = float(s["t"]) / float(s["max"])
                var sweep: float = float(s["arc"]) * 0.5 * (1.0 - sa)
                var a0: float = float(s["a"]) - sweep
                L.draw_arc(s["pos"], float(s["rng"]) * (0.8 + 0.2 * sa),
                                a0 - 0.45, a0 + 0.45, 14,
                                Color(1.0, 0.96, 0.8, 0.85 * sa), 10.0)
                L.draw_arc(s["pos"], float(s["rng"]) * (0.55 + 0.3 * sa),
                                float(s["a"]) - float(s["arc"]) * 0.5,
                                float(s["a"]) + float(s["arc"]) * 0.5, 20,
                                Color(1.0, 0.9, 0.55, 0.35 * sa), 4.0)
        # the aim sight (THE AIM SIGHT LAW, v0.3.4-5): the aim aid is back,
        # PROPER - a calm straight line along the aim to the first gun's
        # real reach. Steady alpha (never flickers), a soft brighter core,
        # a small end dot. The ugly wobbly laser stays dead.
        if phase == "play" and not weapons_run.is_empty():
                var wid0: String = String(weapons_run[0]["id"])
                var sight_rng: float = float(CSData.WEAPONS[wid0]["rng"]) \
                                * float(stats["range_m"]) \
                                * float(CSData.tier_mult(int(weapons_run[0]["tier"])).get("rng", 1.0))
                var sdir := Vector2.from_angle(p_aim)
                L.draw_line(p_pos + sdir * 34.0, p_pos + sdir * sight_rng,
                                Color(1.0, 0.95, 0.78, 0.22), 2.0)
                L.draw_line(p_pos + sdir * 34.0,
                                p_pos + sdir * minf(sight_rng, 210.0),
                                Color(1.0, 0.97, 0.85, 0.4), 3.0)
                L.draw_circle(p_pos + sdir * sight_rng, 4.5,
                                Color(1.0, 0.95, 0.78, 0.5))
        # the gun (rotates with the aim, flips upright when aiming left)
        if p_node != null and is_instance_valid(p_node) and not weapons_run.is_empty():
                var wid: String = String(weapons_run[0]["id"])
                var gt: Texture2D = _t("gun_" + wid)
                var flip: bool = absf(fposmod(p_aim + PI, TAU) - PI) > PI * 0.5
                L.draw_set_transform(p_pos, p_aim, Vector2(1, -1 if flip else 1))
                L.draw_texture(gt, Vector2(12, -5) - Vector2(0, gt.get_height() * 0.5))
                L.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        # the particles + rings + floaters (v0.3.4-4: the rotated-texture
        # branch died with THE NO-SHOOT-VFX LAW - the muzzle was its only user)
        for p in _parts:
                var a := float(p["t"]) / float(p["max"])
                if p.get("tex", "") != "":
                        L.draw_texture(_t(String(p["tex"])), p["pos"] - Vector2(16, 16),
                                        Color(1, 1, 1, a))
                else:
                        L.draw_circle(p["pos"], float(p["size"]) * a, Color(p["col"], a))
        for r in _rings:
                var ra := float(r["t"]) / float(r["max"])
                L.draw_circle(r["pos"], float(r["r"]) * (1.0 - ra * 0.4),
                                Color(r["col"], 0.25 * ra))
                L.draw_arc(r["pos"], float(r["r"]) * (1.2 - ra * 0.8), 0, TAU, 40,
                                Color(r["col"], ra), float(r["w"]))
        for f2 in _floaters:
                var fa := float(f2["t"]) / float(f2["max"])
                L.draw_string(ThemeDB.fallback_font, f2["pos"], f2["txt"],
                                HORIZONTAL_ALIGNMENT_CENTER, -1, int(f2["size"]),
                                Color(f2["col"], fa))

func _draw_shield(e: Dictionary, L: CanvasItem) -> void:
        var sh: Dictionary = e["shield"]
        # ---- THE LAYER SHELL: each alive area draws its arc in its LEVEL's
        # color (deeper = higher); a broken area draws only a faint ghost so
        # the window reads as an open door. The CUT ticks mark the areas.
        for ld in sh["layers"]:
                var areas: Array = ld["areas"]
                var n := areas.size()
                var w: float = TAU / float(n)
                var r: float = float(ld["r"])
                for i in n:
                        var area: Dictionary = areas[i]
                        var a0: float = float(i) * w
                        var a1: float = a0 + w
                        if float(area["hp"]) <= 0.0:
                                # the window: a whisper of where the cut was
                                L.draw_arc(e["pos"], r, a0 + 0.03, a1 - 0.03, 8,
                                                Color(0.7, 0.9, 1.0, 0.10), 2.0)
                                continue
                        var lv: int = clampi(ceili(float(area["hp"])), 1, 5)
                        var col: Color = SHELL_LV_COLS[clampi(lv - 1, 0, 4)]
                        L.draw_arc(e["pos"], r, a0 + 0.035, a1 - 0.035,
                                        maxi(4, int(w / 0.09)), col, 5.0)
                        # the level's inner echo (a second rim, one shade in)
                        L.draw_arc(e["pos"], r - 3.5, a0 + 0.06, a1 - 0.06,
                                        maxi(4, int(w / 0.12)),
                                        Color(col.r, col.g, col.b, 0.4), 2.0)
                # the cut ticks: the specified cuts between the areas
                for i in n:
                        var ca: float = float(i) * w
                        var p0: Vector2 = e["pos"] + Vector2.from_angle(ca) * (r - 5.0)
                        var p1: Vector2 = e["pos"] + Vector2.from_angle(ca) * (r + 5.0)
                        L.draw_line(p0, p1, Color(1, 1, 1, 0.4), 2.0)
        # ---- THE SHATTER ORBIT: the unbreakable fragments - fat cold arcs
        # with a bright core, each spinning its own way
        for sd in sh["shards"]:
                var r2: float = float(sd["r"])
                var rot: float = float(sd["rot"])
                var span: float = float(sd["span"])
                var segs := maxi(6, int(span / 0.09))
                L.draw_arc(e["pos"], r2, rot, rot + span, segs,
                                Color(0.36, 0.78, 1.0, 0.9), 7.0)
                L.draw_arc(e["pos"], r2 - 2.5, rot + 0.03, rot + span - 0.03, segs,
                                Color(0.85, 0.97, 1.0, 0.75), 2.0)
                # the fragment's end teeth (the shattered edge reads)
                for te in [rot, rot + span]:
                        var tp: Vector2 = e["pos"] + Vector2.from_angle(te) * r2
                        L.draw_circle(tp, 3.4, Color(0.55, 0.88, 1.0, 0.95))

# ------------------------------------------------------------ fx helpers
func _dmg_number(pos: Vector2, v: float, crit: bool, col := Color(1, 1, 1)) -> void:
        _floaters.append({"pos": pos + Vector2(randf_range(-10, 10), -18),
                "txt": ("%d!" % int(round(v))) + (" CRIT" if crit else ""),
                "col": CS_YELLOW if crit else col,
                "t": 0.7, "max": 0.7, "size": _fs(10) if crit else _fs(8)})

func _shockwave(pos: Vector2, r: float) -> void:
        _rings.append({"pos": pos, "r": r, "t": 0.42, "max": 0.42,
                "col": Color(1, 0.7, 0.35), "w": 6.0})

## v0.3.7-1 THE MIST: a quick multi-color particle spray (the gore law's
## blood, the gib's dust). One helper so every hit paints the same way.
func _burst(pos: Vector2, cols: Array, n: int) -> void:
        for i in n:
                var a := randf() * TAU
                _parts.append({"pos": pos, "vel": Vector2.from_angle(a)
                                * randf_range(70.0, 230.0),
                        "t": randf_range(0.25, 0.5), "max": 0.5,
                        "col": cols[i % cols.size()],
                        "size": randf_range(2.0, 5.0), "tex": ""})

func _death_burst(e: Dictionary) -> void:
        var n := 12 + (8 if e.get("boss", false) else 0)
        for i in n:
                var a := randf() * TAU
                var sp := randf_range(60.0, 260.0)
                _parts.append({"pos": e["pos"], "vel": Vector2.from_angle(a) * sp,
                        "t": 0.5, "max": 0.5, "col": Color(1, 0.55, 0.3),
                        "size": randf_range(3.0, 7.0), "tex": ""})
        _rings.append({"pos": e["pos"], "r": float(e["size"]), "t": 0.3,
                "max": 0.3, "col": Color(1, 0.6, 0.4), "w": 4.0})

func _heal_flash(e: Dictionary) -> void:
        _parts.append({"pos": e["pos"] + Vector2(randf_range(-14, 14), -10),
                "vel": Vector2(0, -60), "t": 0.4, "max": 0.4,
                "col": Color(0.5, 1, 0.6), "size": 5.0, "tex": ""})

## THE MELEE LAW's swing theatre: a bright arc that sweeps once and dies.
func _slash_fx(a: float, rng: float, arc: float) -> void:
        _slashes.append({"pos": p_pos, "a": a, "rng": rng, "arc": arc,
                "t": 0.22, "max": 0.22})

func _tick_fx(delta: float) -> void:
        # v0.3.8-3 THE FLOOD CAPS: a packed screen used to grow the fx arrays
        # unbounded (every hit sprays, every crit floats) - the draw cost
        # climbed with the swarm. Hard caps, oldest dies first: the show
        # stays identical in the calm and holds the line in the flood.
        while _parts.size() > 260:
                _parts.pop_front()
        while _floaters.size() > 30:
                _floaters.pop_front()
        while _rings.size() > 50:
                _rings.pop_front()
        while _stains.size() > 70:
                _stains.pop_front()
        var dead := []
        for p in _parts:
                p["t"] -= delta
                if p["t"] <= 0.0:
                        dead.append(p)
                        continue
                p["pos"] += Vector2(p["vel"]) * delta
                # v0.3.7-1: gibs carry real gravity (the chunk falls and bounces
                # once - "bombing makes enemies into pieces")
                if p.has("g"):
                        p["vel"] = Vector2(p["vel"]) + Vector2(0, float(p["g"]) * delta)
                p["vel"] = Vector2(p["vel"]) * 0.92
        for p2 in dead:
                _parts.erase(p2)
        # v0.3.7-1: the blood stains fade out of the arena
        var dead_s := []
        for s in _stains:
                s["t"] = float(s["t"]) - delta
                if float(s["t"]) <= 0.0:
                        dead_s.append(s)
        for s2 in dead_s:
                _stains.erase(s2)
        var dead2 := []
        for r in _rings:
                r["t"] -= delta
                if r["t"] <= 0.0:
                        dead2.append(r)
        for r2 in dead2:
                _rings.erase(r2)
        var dead4 := []
        for s2 in _slashes:
                s2["t"] -= delta
                if s2["t"] <= 0.0:
                        dead4.append(s2)
        for s3 in dead4:
                _slashes.erase(s3)
        var dead3 := []
        for f in _floaters:
                f["t"] -= delta
                f["pos"].y -= 40.0 * delta
                if f["t"] <= 0.0:
                        dead3.append(f)
        for f3 in dead3:
                _floaters.erase(f3)



