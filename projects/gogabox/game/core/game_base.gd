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
## v0.2.0 THE UNIVERSAL POSITION RELOAD (owner rule): a game that asks for
## vertical/horizontal emits this with "vertical" or "horizontal"; the host
## UNLOADS and RELOADS the game in that position (same paid session - no
## second fee, no second play count). Any future game with position-specific
## play reuses exactly this path.
signal request_orientation_reload(orient: String)

var game_id := ""
var score := 0
var run_coins := 0
var over := false
var paused := false
## v0.2.2: a game with NO natural death (pong) sets this - the pause sheet
## gains an END button, the ONLY way to bank the run's earnings.
var pause_end_run := false
## v0.2.3: games with pause_end_run can further HIDE the END row per state
## (pong shows END only while the run is live - pausing from the position
## ask or the optionals screen must not offer the dead menu). Override
## this; the default keeps the base behavior.
func _goga_pause_end_ok() -> bool:
        return true
var tk: TouchKit
## Set by the host BEFORE the game enters the tree when the game was
## reloaded for a picked orientation - the ask screens can skip themselves.
var start_orientation := ""

## v0.2.1a: the host could NOT switch to the asked position (the window
## refused the sensor override). The ask resolves into the position the
## window actually kept - games with a position ask override this
## (snake returns to its mode menu in the current shape).
func orientation_settled() -> void:
        pass

## v0.2.0 PEACE rule, modular: a game style can zero the score->coins
## bonus (peace play gives up the bonus by design). The host reads this
## one flag - no game names in the economy.
var score_bonus_enabled := true

var _hud: CanvasLayer
var _score_label: Label
var _coins_label: Label
var _overlay_root: Control
var _toast: Dictionary
var _ach_clock := 0.0
var _hud_row: HBoxContainer   # the top bar (v0.0.8: game buttons live IN it)
var _flow_btns := 0           # game buttons inserted after the back button
# v0.1.0 owner rule: the score-bonus ratio lives in the DEAD MENU only -
# the in-game HUD line from v0.0.9 is gone (Arc.bonus_ratio_text stays,
# host_node.gd still prints "pickups = N - score bonus = S/D = B").

func _ready() -> void:
        tk = TouchKit.new()
        add_child(tk)
        _build_hud()
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
                        # v0.1.7 - dario
                        "stomp_25": ok = Box.counter(game_id, "stomped") >= 25
                        "clear_all": ok = Box.counter(game_id, "levels_done") >= 3
                        # v0.1.7 - xo
                        "rung_5": ok = Box.counter(game_id, "rung") >= 5
                        "rung_top": ok = Box.counter(game_id, "rung") >= 10
                        "streak_3": ok = Box.counter(game_id, "streak") >= 3
                        # v0.2.4 - space dash (kills + the max power rung)
                        "kills_100": ok = Box.counter(game_id, "kills") >= 100
                        "kills_300": ok = Box.counter(game_id, "kills") >= 300
                        "dash_max": ok = Box.counter(game_id, "max_power") >= 20
                        # v0.2.5 - snowy tower (platforms climbed in one run)
                        "tower_30": ok = Box.counter(game_id, "max_tower") >= 30
                        "tower_80": ok = Box.counter(game_id, "max_tower") >= 80
                        "tower_150": ok = Box.counter(game_id, "max_tower") >= 150
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
## interested to know, know") - REWORKED v0.1.0: the ratio is NOT printed
## inside every game anymore (owner: "not for each game in-game scene, i said
## dead menu only"). ONE helper, Arc.bonus_ratio_text, renders it in the
## death menu (host_node.gd) - and nowhere else.

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

## A live-updating HUD chip inserted next to the score (the speed chip
## today, anything tomorrow). Returns the inner Label - write .text to it.
func add_hud_chip(txt: String, icon_path := "") -> Label:
        if _hud_row == null or not is_instance_valid(_hud_row):
                return null
        var chip := Arc.chip(txt, icon_path, Color(0, 0, 0, 0.4), 22, Arc.CARD)
        _hud_row.add_child(chip)
        # sits right before the coins chip (children: back..score, chip, coins)
        _hud_row.move_child(chip, _hud_row.get_child_count() - 2)
        return chip.get_child(0).get_child(chip.get_child(0).get_child_count() - 1)

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
        var end_ok := pause_end_run and _goga_pause_end_ok()
        if end_ok:
                sheet.add_child(Arc.button("END", Vector2(460, 84), 30, Arc.ACCENT, func():
                        _pause_close()
                        finish_run(score)))
        sheet.add_child(Arc.button("QUIT TO BOX", Vector2(460, 84), 26, Arc.BAD, func():
                get_tree().paused = false
                quit_to_box()))
        Arc.fit_sheet(sheet, 3 if end_ok else 2)     # pinned rows, content clamped

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
