class_name GogaGame
extends Node2D
## Base class for EVERY GOGABox game. The GameHost instantiates the game's
## script, takes the entry fee, calls _goga_setup(), and the game plays until
## it calls finish_run(...) (or the player pauses out via the host chrome).
##
## Games get for free: HUD top bar (back, score, coins), pause sheet, run-end
## flow (coins → save → rewarded double → interstitial pacing → menu),
## TouchKit wiring, achievement helpers, sfx helpers.

signal request_finish(score: int, coins_earned: int)
signal request_quit

var game_id := ""
var score := 0
var run_coins := 0
var over := false
var paused := false
var tk: TouchKit

var _hud: CanvasLayer
var _score_label: Label
var _coins_label: Label
var _overlay_root: Control
var _toast: Dictionary
var _ach_clock := 0.0
var _hud_row: HBoxContainer   # the top bar (v0.0.8: game buttons live IN it)
var _flow_btns := 0           # game buttons inserted after the back button
# v0.0.9: live "score bonus S/D = B" line (modular - Arc.bonus_ratio_text)
var _bonus_label: Label
var _bonus_div := 0

func _ready() -> void:
        tk = TouchKit.new()
        add_child(tk)
        _build_hud()
        _build_bonus_line()
        _toast = Arc.toast_overlay(_overlay_root)
        _goga_setup()

# --------------------------------------------------- override these 3

func _goga_setup() -> void:
        pass  # build your world here; the entry fee is already taken

func _goga_tick(_delta: float) -> void:
        pass  # per-frame logic if you don't want to use _process

func _goga_input(_event: InputEvent) -> void:
        pass  # raw events AFTER tk.feed() has seen them

# --------------------------------------------------- host-provided services

func set_score(v: int) -> void:
        score = v
        _score_label.text = str(v)
        _update_bonus_line()

func add_score(v: int) -> void:
        set_score(score + v)

## In-world GOGACoin pickups go through here (they ARE GOGACoins).
func add_run_coins(v: int) -> void:
        run_coins += v
        _coins_label.text = str(run_coins)

## End the run. Host handles economy, saves, ads, and the UI.
func finish_run(final_score: int, final_coins := -1) -> void:
        if over:
                return
        over = true
        run_coins = final_coins if final_coins >= 0 else run_coins
        request_finish.emit(final_score, run_coins)

func quit_to_box() -> void:
        request_quit.emit()

# --------------------------------------------------- achievements / counters

func achievement_count(key: String, amount: int) -> void:
        Box.bump_counter(game_id, key, amount)

func achievement_max(key: String, value: int) -> void:
        Box.max_counter(game_id, key, value)

## Check this game's achievements; awards the SHARED popup (Achiever) with
## sound + confetti and returns count of new ones. Safe to call often.
func check_achievements() -> int:
        var g := GameReg.get_game(game_id)
        var new_count := 0
        for a in g.get("ach", []):
                var ok := false
                match String(a["id"]):
                        "score_30": ok = score >= 30
                        "score_60": ok = score >= 60
                        "score_100": ok = score >= 100
                        "score_50": ok = score >= 50
                        "score_300": ok = score >= 300
                        "score_500": ok = score >= 500
                        "score_1500": ok = score >= 1500
                        "rally_15": ok = Box.counter(game_id, "max_rally") >= 15
                        "rally_30": ok = Box.counter(game_id, "max_rally") >= 30
                        "combo_5": ok = Box.counter(game_id, "best_combo") >= 5
                        "slash_100": ok = Box.counter(game_id, "slashed") >= 100
                        "dodge_200": ok = Box.counter(game_id, "dodged") >= 200
                        "height_500": ok = Box.counter(game_id, "max_height") >= 500
                        "height_1500": ok = Box.counter(game_id, "max_height") >= 1500
                        "hops_50": ok = Box.counter(game_id, "hops") >= 50
                        "coins_100": ok = Box.counter(game_id, "coins_taken") >= 100
                        "tile_256": ok = Box.counter(game_id, "max_tile") >= 256
                        "tile_512": ok = Box.counter(game_id, "max_tile") >= 512
                        "tile_2048": ok = Box.counter(game_id, "max_tile") >= 2048
                if ok and Box.grant_achievement(game_id, String(a["id"])):
                        new_count += 1
                        Achiever.award(game_id, a)
        return new_count

# --------------------------------------------------- toasts

func _toast_show(msg: String) -> void:
        Arc.toast(_toast, msg)

# --------------------------------------------------- pause (host chrome)

func _build_hud() -> void:
        _hud = CanvasLayer.new()
        add_child(_hud)
        _overlay_root = Control.new()
        _overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
        _overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hud.add_child(_overlay_root)

        var top := HBoxContainer.new()
        # v0.0.8 THE OVERLAP FIX: the bar must span the full width. Under a
        # CanvasLayer it had no anchors, so its width collapsed to its minimum
        # and the spacer did nothing - score/coins sat in the left half, right
        # where the floating SHOP button landed ("shop overlaps the coins
        # widget, score under the shop button"). TOP_WIDE + offsets: back on
        # the left, game buttons in the flow, score/coins on the TRUE right.
        top.set_anchors_preset(Control.PRESET_TOP_WIDE)
        top.offset_left = 14
        top.offset_right = -14
        top.offset_top = 12
        top.offset_bottom = 76
        top.add_theme_constant_override("separation", 10)
        _hud.add_child(top)
        _hud_row = top

        var back := Arc.button("<", Vector2(64, 64), 30, Color(0.16, 0.10, 0.05, 0.85),
                func(): _pause_open())
        top.add_child(back)

        var mid := Control.new()
        mid.custom_minimum_size = Vector2(0, 64)
        mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        top.add_child(mid)

        var score_panel := Arc.chip("0", "", Color(0, 0, 0, 0.4), 30, Arc.CARD)
        _score_label = score_panel.get_child(0).get_child(score_panel.get_child(0).get_child_count() - 1)
        _score_label.text = "0"
        top.add_child(score_panel)

        var coins_panel := Arc.chip("0", "res://assets/ui/coin.png", Color(0, 0, 0, 0.4), 30, Arc.COIN)
        _coins_label = coins_panel.get_child(0).get_child(coins_panel.get_child(0).get_child_count() - 1)
        _coins_label.text = "0"
        top.add_child(coins_panel)

## v0.0.9 owner rule ("show the score bonus ratio so users who are
## interested to know, know"): every game prints the LIVE ratio under the
## top bar, right under the score chip. Text comes from ONE helper
## (Arc.bonus_ratio_text) so the dead menu and any future screen match.
func _build_bonus_line() -> void:
        _bonus_div = int(GameReg.get_game(game_id).get("coin_div", 100))
        if _bonus_div <= 0:
                return
        _bonus_label = Arc.label("", 16, Color(1, 1, 1, 0.5), false)
        _bonus_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
        _bonus_label.offset_left = 20
        _bonus_label.offset_right = -20
        _bonus_label.offset_top = 82
        _bonus_label.offset_bottom = 104
        _bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        _overlay_root.add_child(_bonus_label)
        _update_bonus_line()

func _update_bonus_line() -> void:
        if _bonus_label == null or not is_instance_valid(_bonus_label):
                return
        _bonus_label.text = "" if score <= 0 \
                        else "score bonus " + Arc.bonus_ratio_text(score, _bonus_div)

func set_hud_score_prefix(prefix: String) -> void:
        _score_label.text = prefix + " " + str(score)

## Games with shops call this during _goga_setup() to get a HUD button.
## BUTTON SAFETY SYSTEM v0.0.8: buttons join the top bar BETWEEN the back
## button and the spacer - they stack side by side in normal flow, can never
## overlap each other or the right-aligned score/coins chips, and the bar
## wraps nothing off-screen (the old floating fixed-position layout put SHOP
## right on top of the score chip).
func add_hud_button(txt: String, cb: Callable) -> void:
        if _hud_row == null or not is_instance_valid(_hud_row):
                return
        var b := Arc.button(txt, Vector2(96, 56), 20, Color(0.16, 0.10, 0.05, 0.85), cb)
        _hud_row.add_child(b)
        # children: [back, spacer, score, coins] -> insert right after back,
        # keeping every previously added game button in order
        _hud_row.move_child(b, 1 + _flow_btns)
        _flow_btns += 1

func _score_label_ref() -> Label:
        return _score_label

func _coins_label_ref() -> Label:
        return _coins_label

## host-facing refs
func _overlay_root_ref() -> Control:
        return _overlay_root

func _toast_ref() -> Dictionary:
        return _toast

func _pause_open() -> void:
        if over or paused:
                return
        paused = true
        get_tree().paused = true
        var sheet := Arc.sheet(_overlay_root, 0.0)
        sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
        var g := GameReg.get_game(game_id)
        var title := Arc.label(String(g.get("title", game_id)), 44, Arc.INK)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(title)
        sheet.add_child(Arc.button("RESUME", Vector2(460, 84), 30, Arc.GOOD, func():
                _pause_close()))
        sheet.add_child(Arc.button("QUIT TO BOX", Vector2(460, 84), 26, Arc.BAD, func():
                get_tree().paused = false
                quit_to_box()))
        Arc.fit_sheet(sheet, 2)     # RESUME + QUIT pinned, content clamped

func _pause_close() -> void:
        get_tree().paused = false
        paused = false
        # remove the sheet (last 2 children added: dim + center container)
        var kids := _overlay_root.get_children()
        for i in range(maxi(0, kids.size() - 2), kids.size()):
                kids[i].queue_free()

# --------------------------------------------------- unified input plumbing

func _unhandled_input(event: InputEvent) -> void:
        if over:
                return
        tk.feed(event)
        _goga_input(event)

func _process(delta: float) -> void:
        if over or paused:
                return
        _goga_tick(delta)
        # live achievement sweep every ~3s so the shared popup fires mid-run
        _ach_clock += delta
        if _ach_clock >= 3.0:
                _ach_clock = 0.0
                check_achievements()
