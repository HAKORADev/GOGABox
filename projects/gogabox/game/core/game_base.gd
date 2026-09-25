class_name GogaGame
extends Node2D
## Base class for EVERY GOGABox game. The GameHost instantiates the game's
## script, takes the entry fee, calls _goga_setup(), and the game plays until
## it calls finish_run(...) (or the player pauses out via the host chrome).
##
## Games get for free: HUD top bar (back, score, coins), pause sheet, run-end
## flow (coins → save → menu), TouchKit wiring, achievement helpers, sfx
## helpers.

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

## v042 THE LAN SEAT: the host sets lan_hold BEFORE the game enters the
## tree (the boot wears the waiting room instead of the mode asks); the
## base routes the LAN signals into the game's duck-typed lan_* methods.
var lan_hold := false
var lan_active := false
var lan_seed := 0
var lan_seats: Array = []
var lan_params: Dictionary = {}     # r3: the room owner's config (mode/position/size)
var _lan_hold_ui: LanHold = null
var _lan_routed := false
var _chat_btn: Button = null

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
## v0.2.8 MODULAR MODE BONUS: a game whose run bonus depends on a MODE
## (2048's board sizes: /20, /80, /160) sets this BEFORE finishing; -1
## means "use the registry coin_div". The host reads this one var - no
## game names in the economy.
var bonus_div_override := -1

var _hud: CanvasLayer
var _score_label: Label
var _coins_label: Label
var _score_prefix := ""           # v040-14: the widget's word survives set_score
var _overlay_root: Control
var _toast: Dictionary
var _ach_clock := 0.0
var _hud_row: HBoxContainer   # the top bar (v0.0.8: game buttons live IN it)
var _flow_btns := 0           # game buttons inserted after the back button
# v0.3.3-p2 THE SHEET STACK + BACK LAW: every game-owned modal sheet goes
# through sheet_push/sheet_pop - exact dim+center pairs, the newest on top.
# The HUD back button AND the Android back button both walk this stack:
# a sheet open -> close the top sheet; nothing open -> the pause sheet.
# This is the cure for the whole "back does nothing / the game hangs" family
# (the old per-game pair juggling removed the WRONG dim+center pair and left
# invisible dims eating every tap).
var _sheet_stack: Array = []  # [{dim: Control, cc: Control}]
var _pause_pair: Array = []   # [dim, cc] of the live pause sheet
# v0.1.0 owner rule: the score-bonus ratio lives in the DEAD MENU only -
# the in-game HUD line from v0.0.9 is gone (Arc.bonus_ratio_text stays,
# host_node.gd still prints "pickups = N - score bonus = S/D = B").

func _ready() -> void:
        tk = TouchKit.new()
        add_child(tk)
        _build_hud()
        # THE TOAST LAW (v0.3.5-3): the game owns ONE overlay forever and it
        # lives ABOVE the pause - a buy inside a paused shop must still fade.
        # It is a SIBLING of the HUD (top level, layer 100) - a layer nested
        # under the HUD's own canvas let the shop's sheet paint over it.
        _toast = Arc.toast_overlay(self)
        _toast["layer"].process_mode = Node.PROCESS_MODE_ALWAYS
        _goga_setup()

## THE TOAST LAW: every game toast goes through HERE - one layer, one label,
## the newest toast kills the old tween (no hanging stacks, no overlap).
func game_toast(msg: String) -> void:
        Arc.toast(_toast, msg)

# --------------------------------------------------- override these 3

func _goga_setup() -> void:
        pass  # build your world here; the entry fee is already taken

func _goga_tick(_delta: float) -> void:
        pass  # per-frame logic if you don't want to use _process

func _goga_input(_event: InputEvent) -> void:
        pass  # raw events AFTER tk.feed() has seen them

# ------------------------------------- v041-1 r7 THE GAME CURSOR SEAT
## THE OWNER'S ORDER: a game's custom cursor must live over its own HUD
## buttons and sheets too ("the cursor can be used here too, i mean the
## custom in-game one"), and a game can make a DIFFERENT one for clicking
## - "as same as it can do one for the GOGABox-related menus" (the box
## cursor's held state, game-side). The images ride the OS-composited
## hardware cursor (GogaCursorLib's game seat): it cannot be covered by
## any Control, cannot lag, cannot vanish with the render path. Phones:
## no pointer, the seat is a no-op (games keep drawing their touch aim).
const GogaCursorLib := preload("res://game/core/goga_cursor.gd")
var _game_cur_armed := false
# v041-2 r3 THE SEAT TOKEN LAW: the token returned by game_arm is the ONLY
# key that disarms - a queued-free game's stale token is a no-op, so the
# replayed game's seat and the box arrow survive the deferred corpse.
var _game_seat_token := -1

## Arm this game's own cursor. `normal` is the everyday image, `click`
## (optional) swaps in while the LEFT button is held. Hotspot is the
## pixel inside the image that IS the pointer (a reticle: its center).
func game_cursor_arm(normal: Texture2D, click: Texture2D = null,
                hotspot := Vector2.ZERO) -> void:
        if not ScaleRule.is_pc() or normal == null:
                return
        _game_seat_token = GogaCursorLib.game_arm(normal, click, hotspot)
        _game_cur_armed = _game_seat_token >= 0

## Hand the pointer back (the box cursor returns on the game-closed road;
## a game may also call this itself when it wants the OS arrow back).
func game_cursor_disarm() -> void:
        if not _game_cur_armed:
                return
        _game_cur_armed = false
        GogaCursorLib.game_disarm(_game_seat_token)
        _game_seat_token = -1

## v041-2 r2 THE SEAT DEATH LAW (the owner's leak report: the Heavy War
## cursor "appears now in GOGABox in all other games and even GOGABox main
## menu when i click them"). The game seat is a STATIC in GogaCursorLib -
## it outlived the game node that armed it. v041-2 r3 THE TOKEN AMENDMENT:
## _exit_tree fires DEFERRED (queue_free) - on the replay/reload paths the
## NEXT seat is already armed by then, and the corpse's disarm must never
## touch it. The token law makes the stale corpse a no-op; the LIVE seat
## hands the pointer back to the box cursor the same frame it dies.
func _exit_tree() -> void:
        _lan_unroute()
        if _game_cur_armed:
                _game_cur_armed = false
                GogaCursorLib.game_disarm(_game_seat_token)
                _game_seat_token = -1

## THE CLICK SWAP: an `_input` observer, NOT _unhandled_input - a press
## that lands on a HUD Button dies at the GUI stage and never reaches the
## unhandled lane, and THAT press is exactly the one the click cursor must
## wear. This never consumes: it only mirrors the LMB state into the seat.
func _input(event: InputEvent) -> void:
        # v042-1 THE CHAT SHORTCUT (PC): Ctrl+T opens/closes the session
        # chat - the owner's "for PC it can be shortcut" seat
        if event is InputEventKey and (event as InputEventKey).pressed \
                        and not (event as InputEventKey).echo \
                        and (event as InputEventKey).keycode == KEY_T \
                        and (event as InputEventKey).ctrl_pressed \
                        and lan_active:
                get_viewport().set_input_as_handled()
                LanChatUi.open(self)
                return
        if not _game_cur_armed:
                return
        if event is InputEventMouseButton \
                        and (event as InputEventMouseButton).button_index \
                        == MOUSE_BUTTON_LEFT and ScaleRule.is_pc():
                GogaCursorLib.set_held((event as InputEventMouseButton).pressed)


# --------------------------------------------------- host-provided services

func set_score(v: int) -> void:
        score = v
        # null-safe: probes boot games without the host chrome
        if _score_label != null:
                _score_label.text = _score_prefix + str(v)

func add_score(v: int) -> void:
        set_score(score + v)

## In-world GOGACoin pickups go through here (they ARE GOGACoins).
func add_run_coins(v: int) -> void:
        run_coins += v
        if _coins_label != null:
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

# --------------------------------------------------- the sheet stack (v0.3.3-p2)

## THE one way a game opens a modal sheet. Returns the inner VBox to fill.
## The exact dim+center pair is captured and tracked (with the caller's id);
## the sheet chain gets PROCESS_MODE_ALWAYS so it stays alive even while the
## tree is paused, and BoxScroll's topmost law hands every tap above it to
## THIS sheet.
func sheet_push(sheet_height := 0.0, id := "", sheet_width := -1.0) -> VBoxContainer:
        var root := _overlay_root_ref()
        # v0.4.1 THE POINTER LAW: a box sheet (shop, pause, anything) must
        # always have something to aim with - a game that hid or took the
        # OS cursor hands it back while the sheet owns the screen.
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        # v040-11: publish this sheet's id - the Arc.fit_sheet pass that wraps
        # the sheet's content hands it to the BoxScroll (the CONTINUITY LAW:
        # the list remembers its own offset across the buy-refresh cycle).
        Arc.pending_key = id
        var vb := Arc.sheet(root, sheet_height, sheet_width)
        var kids := root.get_children()
        var dim: Control = kids[kids.size() - 2]
        var cc: Control = kids[kids.size() - 1]
        dim.process_mode = Node.PROCESS_MODE_ALWAYS
        cc.process_mode = Node.PROCESS_MODE_ALWAYS
        # v041-1 THE DIM-CLOSE LAW (the menu seat wears the same): a click
        # on the dim closes the TOP sheet - a near-miss on a shop or an
        # options sheet can never feel like a dead button again.
        dim.gui_input.connect(func(ev: InputEvent):
                if ev is InputEventMouseButton \
                                and (ev as InputEventMouseButton).pressed \
                                and (ev as InputEventMouseButton).button_index \
                                == MOUSE_BUTTON_LEFT:
                        sheet_pop())
        _sheet_stack.append({"dim": dim, "cc": cc, "id": id})
        # v041-2 r2 THE BIRTH GRACE: a sheet opened from inside a press handler
        # (a HUD button, a TouchKit tap, anything) shares that physical click
        # with the same-frame emulated touch - a button under the pointer can
        # be born already pressed and activate on the release (Tower Ball's
        # optionals skipped themselves; the owner: "immediately starts"). One
        # full-rect shield eats every pointer event on the sheet's birth frame,
        # then dies. No UI underneath can self-press; nothing else changes.
        # v041-2 r3 THE SHIELD DEATH LAWS (the owner: "the game itself even
        # the shop in it and everything, does not listen to any inputs at
        # all" + "in heavy war XP-level cards selection, mouse clicks aren't
        # recognized"): TWO r2 bugs made the shield an IMMORTAL full-rect
        # click-eater over EVERY sheet_push sheet since r2:
        #   (1) ready was connected AFTER add_child - the parent was already
        #       in the tree, so ready fired synchronously INSIDE add_child,
        #       BEFORE the connect: the kill-tween was NEVER created and the
        #       shield outlived every sheet (proven by
        #       tests/pause_input_probe.gd A2-A5 on a REAL Xvfb window);
        #   (2) the tween was bound to a node that inherits the tree pause -
        #       a sheet opened under get_tree().paused = true (the heavy war
        #       level cards pause BEFORE sheet_push) could never run it.
        # THE LAWS NOW: ready is connected BEFORE the add; the shield is
        # PROCESS_MODE_ALWAYS; the tween is TWEEN_PAUSE_PROCESS. The shield
        # dies 0.05s after birth in every state, and the sheet below (dim+cc
        # are ALWAYS) takes every click from then on.
        var shield := Control.new()
        shield.name = "SheetBirthShield"
        shield.set_anchors_preset(Control.PRESET_FULL_RECT)
        shield.mouse_filter = Control.MOUSE_FILTER_STOP
        shield.process_mode = Node.PROCESS_MODE_ALWAYS
        shield.ready.connect(func():
                var tw := shield.create_tween()
                tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
                tw.tween_interval(0.05)
                tw.tween_callback(func():
                        if shield != null and is_instance_valid(shield):
                                shield.queue_free()))
        root.add_child(shield)
        root.move_child(shield, root.get_child_count() - 1)
        return vb

## Close the top sheet - its EXACT pair dies (never a neighbor, never a
## sheet that opened after it). The game hears WHICH sheet died through
## _goga_sheet_popped so its own state flags never desync.
func sheet_pop() -> void:
        if _sheet_stack.is_empty():
                return
        var s: Dictionary = _sheet_stack.pop_back()
        # v040-11 THE CONTINUITY LAW: write the dying sheet's list offsets
        # BEFORE the deferred frees - a same-frame rebuild of the same sheet
        # id then restores them (the global top-jump nuke).
        for k in [s["dim"], s["cc"]]:
                if k != null and is_instance_valid(k):
                        for sc in (k as Control).find_children("*", "BoxScroll", true, false):
                                (sc as BoxScroll).remember()
        for k in [s["dim"], s["cc"]]:
                if k != null and is_instance_valid(k):
                        k.queue_free()
        _goga_sheet_popped(String(s.get("id", "")))

## the game's state sync when the BASE closed a sheet for it (the back
## button path) - match the id, flip the matching flag
func _goga_sheet_popped(_id: String) -> void:
        pass

func sheet_open_count() -> int:
        return _sheet_stack.size()

## THE BACK LAW - the HUD "<" button and the Android back button both land
## here. Top sheet open -> close it. Pause sheet open -> resume. Nothing
## open -> the pause sheet. One behavior in every game, every screen.
func _back_pressed() -> void:
        if over:
                return
        if not _pause_pair.is_empty():
                _pause_close()
                return
        if not _sheet_stack.is_empty():
                sheet_pop()
                return
        _pause_open()

# --------------------------------------------------- achievements / counters

func achievement_count(key: String, amount: int) -> void:
        Box.bump_counter(game_id, key, amount)

func achievement_max(key: String, value: int) -> void:
        Box.max_counter(game_id, key, value)

## Check this game's achievements; awards the SHARED popup (Achiever) with
## sound + confetti and returns count of new ones. Safe to call often.
## v0.3.7-1 THE RULE TABLE (the owner's achievements overhaul): the
## conditions live IN THE REGISTRY now - each ach entry carries a
## "rule": {"k": "score"|"cnt"|"max"|"stat", "key": "...", "v": N} and
## this evaluator reads them all. No more hardcoded id matches (three old
## trophies - jelly/icecrash/parcels - were DEAD because their ids never
## joined the old match table; data cannot rot like that). Tiers ride the
## entry (1-4) and color the popup.
func check_achievements() -> int:
        var g := GameReg.get_game(game_id)
        var new_count := 0
        for a in g.get("ach", []):
                var ok := _ach_rule_ok(a.get("rule", {}) as Dictionary)
                if ok and Box.grant_achievement(game_id, String(a["id"])):
                        new_count += 1
                        Achiever.award(game_id, a)
        return new_count

## The one rule evaluator: score = this run's score, cnt/max = the game's
## counter store (bump_counter accumulates, max_counter peaks - both read
## the same value), stat = the box stat block (plays/best/last).
func _ach_rule_ok(r: Dictionary) -> bool:
        if r.is_empty():
                return false
        var v := int(r.get("v", 0))
        match String(r.get("k", "")):
                "score":
                        return score >= v
                "cnt", "max":
                        return Box.counter(game_id, String(r.get("key", ""))) >= v
                "stat":
                        return Box.stat(game_id, String(r.get("key", "plays"))) >= v
        return false

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
                func(): _back_pressed())
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
        _score_prefix = prefix + " "     # re-applied on EVERY set_score now
        if _score_label != null:
                _score_label.text = _score_prefix + str(score)

## v0.2.6 (RETIRED, the 0-ADS LAW): this computed the 52dp Unity banner
## strip's logical height. No banner exists anymore, but the helper stays
## because the menu bottom-margin math and a few row offsets still call it.
func banner_safe_px() -> float:
        var dpi := DisplayServer.screen_get_dpi()
        var win := DisplayServer.window_get_size()
        var vp := get_viewport_rect().size
        if win.x <= 0 or win.y <= 0 or vp.x <= 0.0 or vp.y <= 0.0:
                return 64.0
        var px_per_logical := minf(float(win.x) / vp.x, float(win.y) / vp.y)
        var phys := 52.0 * dpi / 160.0 + 12.0
        return maxf(64.0, ceilf(phys / maxf(0.05, px_per_logical)))

## THE 0-ADS LAW (the owner's open-source round): there is no ad banner
## anymore - the 52dp strip is reclaimed by every game's own layout (this
## used to reserve space for the Unity banner view). The helper stays so
## the 25+ layout call sites read ONE truth.
func banner_bottom() -> float:
        return 0.0

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

## v041-2 r2 THE TWIN MIRROR: a custom control in the top bar, left of the
## score chip (see game_base3d's law).
func add_hud_widget(c: Control) -> void:
        if _hud_row == null or not is_instance_valid(_hud_row):
                return
        _hud_row.add_child(c)
        _hud_row.move_child(c, _hud_row.get_child_count() - 2)

func _score_label_ref() -> Label:
        return _score_label

func _coins_label_ref() -> Label:
        return _coins_label

## v0.3.4-3 THE CHIP LAWS: games that draw their OWN widgets (the CS face)
## can hide the whole chrome chips - hiding only the labels left EMPTY
## panels floating in the top bar (the owner's "empty widget next to the
## gogacoins widget" report).
func _score_chip_ref() -> Control:
        if _score_label == null or _score_label.get_parent() == null:
                return null
        return _score_label.get_parent().get_parent() as Control

func _coins_chip_ref() -> Control:
        if _coins_label == null or _coins_label.get_parent() == null:
                return null
        return _coins_label.get_parent().get_parent() as Control

## host-facing refs
func _overlay_root_ref() -> Control:
        return _overlay_root

func _toast_ref() -> Dictionary:
        return _toast

func _pause_open() -> void:
        if over or paused or not _pause_pair.is_empty():
                return
        paused = true
        get_tree().paused = true
        # v0.4.1 THE POINTER LAW: the pause sheet must have something to
        # aim with, even in a game that hid the cursor for its own play.
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        var sheet := Arc.sheet(_overlay_root, 0.0)
        # v0.3.3-p2: ALWAYS rides the DIM (the sheet's true root) - the whole
        # branch processes while the tree is paused, and the dim itself can
        # still eat the taps that miss the panel
        var kids := _overlay_root.get_children()
        var dim: Control = kids[kids.size() - 2]
        var cc: Control = kids[kids.size() - 1]
        dim.process_mode = Node.PROCESS_MODE_ALWAYS
        cc.process_mode = Node.PROCESS_MODE_ALWAYS
        _pause_pair = [dim, cc]
        # v041-1 THE DIM-CLOSE LAW: a click on the pause dim = RESUME (the
        # universal outside-click, same as the menu sheets)
        dim.gui_input.connect(func(ev: InputEvent):
                if ev is InputEventMouseButton \
                                and (ev as InputEventMouseButton).pressed \
                                and (ev as InputEventMouseButton).button_index \
                                == MOUSE_BUTTON_LEFT:
                        _pause_close())
        _pause_fill(sheet)
        Arc.fit_sheet(sheet, 3 if (_pause_end_ok_live()) else 2)

## the pause sheet's fill (split from _pause_open so the MULTIPLAYER
## roster can swap the content IN PLACE - the roster rides the same
## paused pair, no stacking, no processing traps)
func _pause_end_ok_live() -> bool:
        return pause_end_run and _goga_pause_end_ok()

func _pause_fill(sheet: VBoxContainer) -> void:
        var g := GameReg.get_game(game_id)
        var title := Arc.label(String(g.get("title", game_id)), 44, Arc.INK)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(title)
        sheet.add_child(Arc.button("RESUME", Vector2(460, 84), 30, Arc.GOOD, func():
                _pause_close()))
        # v042-1 THE PAUSE ROSTER (the owner: "in the pause menu, add
        # button called multiplayer, in it, show each player number and
        # who is the player behind it, in a proper well-designed way") -
        # the voice toggles ride the same sheet
        if lan_active and not LAN.seats.is_empty():
                sheet.add_child(Arc.button("MULTIPLAYER", Vector2(460, 84), 30,
                                Arc.ACCENT, func(): _pause_roster()))
        var end_ok := pause_end_run and _goga_pause_end_ok()
        if end_ok:
                sheet.add_child(Arc.button("END", Vector2(460, 84), 30, Arc.ACCENT, func():
                        _pause_close()
                        finish_run(score)))
        sheet.add_child(Arc.button("QUIT TO BOX", Vector2(460, 84), 26, Arc.BAD, func():
                _pause_close()
                quit_to_box()))

## swap the pause sheet's content for THE ROSTER (the seats + the voice
## law's two-layer toggles); BACK rebuilds the pause fill in place
func _pause_roster() -> void:
        if _pause_pair.is_empty():
                return
        var cc: Control = _pause_pair[1]
        if cc == null or not is_instance_valid(cc):
                return
        var sheet: VBoxContainer = (cc.get_child(0) as PanelContainer).get_child(0)
        for c in sheet.get_children():
                sheet.remove_child(c)
                c.queue_free()
        LanRoster.build(sheet, self)
        sheet.add_child(Arc.button("BACK", Vector2(460, 70), 26,
                        Color(0.42, 0.30, 0.16), func(): _pause_rebuild()))
        Arc.fit_sheet(sheet, 1)

func _pause_rebuild() -> void:
        if _pause_pair.is_empty():
                return
        var cc: Control = _pause_pair[1]
        if cc == null or not is_instance_valid(cc):
                return
        var sheet: VBoxContainer = (cc.get_child(0) as PanelContainer).get_child(0)
        for c in sheet.get_children():
                sheet.remove_child(c)
                c.queue_free()
        _pause_fill(sheet)
        Arc.fit_sheet(sheet, 3 if _pause_end_ok_live() else 2)

func _pause_close() -> void:
        get_tree().paused = false
        paused = false
        # v0.3.3-p2: the EXACT tracked pair dies (the old "last 2 children"
        # removal freed a LATER sheet's pair instead and left invisible dims
        # eating every tap - the hang family)
        for k in _pause_pair:
                if k != null and is_instance_valid(k):
                        k.queue_free()
        _pause_pair = []

# --------------------------------------------------- unified input plumbing

## v0.4.1 THE UNFOCUS PAUSE LAW: the box lost focus mid-run (the player
## tabbed away / grabbed their phone) - main.gd asks the game to sit on
## the SAME pause sheet the back button opens, so returning never means a
## half-second freeze-then-jump; the player resumes when ready. Sheets and
## story cards already own the screen stay as they are.
func ensure_pause_for_box() -> void:
        if over or paused or not _pause_pair.is_empty():
                return
        if not _sheet_stack.is_empty() or box_story_open():
                return
        _pause_open()

# ============================================== v0.4.1 THE TAP-ANYWHERE LAW
## ONE universal full-screen intro tap - the owner: "tap anywhere to start
## actually is not really anywhere, i had to click in the middle of the
## screen slightly toward the bottom... which also means tap anywhere
## screen is not universal in the internal infra which is bad". The
## overlay covers EVERY pixel, eats the press through the GUI stage (so
## the raw path can never start a run behind a sheet), and takes itself
## down the moment it fires. The note label is optional - games with
## their own intro art pass "".

var _tap_start: Dictionary = {}   # {node: Control, cb: Callable}

func tap_anywhere_start(cb: Callable, note := "TAP ANYWHERE TO START") -> void:
        tap_anywhere_stop()
        var root := _overlay_root_ref()
        var ov := Control.new()
        ov.name = "TapAnywhere"
        ov.set_anchors_preset(Control.PRESET_FULL_RECT)
        ov.mouse_filter = Control.MOUSE_FILTER_STOP
        # v041-2 r2 THE TAP LAW (the owner: "make sure that you will make the
        # 'tap anywhere to start' accurately"). The overlay fired on the PRESS
        # before - with emulate_touch_from_mouse the SAME physical click also
        # delivers an emulated ScreenTouch, and whatever UI the callback built
        # (a sheet, a menu) received that emulated press + the physical release
        # in the same breath: Tower Ball's PLAY button activated itself and the
        # owner "immediately started" with no mode/position selection. A TAP is
        # press + RELEASE - the callback fires on the release now, when every
        # press of this gesture is already dead.
        ov.gui_input.connect(func(ev: InputEvent):
                if ev is InputEventScreenTouch \
                                and not (ev as InputEventScreenTouch).pressed:
                        _fire_tap_start()
                elif ev is InputEventMouseButton \
                                and not (ev as InputEventMouseButton).pressed:
                        _fire_tap_start())
        if note != "":
                var lbl := Arc.label(note, 32, Arc.ACCENT, true)
                lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
                lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
                lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
                lbl.position.y -= 190.0
                lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
                ov.add_child(lbl)
                var pl := lbl.create_tween().set_loops()
                pl.tween_property(lbl, "modulate:a", 0.45, 0.7) \
                                .set_trans(Tween.TRANS_SINE)
                pl.tween_property(lbl, "modulate:a", 1.0, 0.7) \
                                .set_trans(Tween.TRANS_SINE)
        root.add_child(ov)
        root.move_child(ov, root.get_child_count() - 1)
        _tap_start = {"node": ov, "cb": cb}

func tap_anywhere_stop() -> void:
        if _tap_start.has("node") and is_instance_valid(_tap_start["node"]):
                _tap_start["node"].queue_free()
        _tap_start = {}

func tap_anywhere_waiting() -> bool:
        return not _tap_start.is_empty()

func _fire_tap_start() -> void:
        if _tap_start.is_empty():
                return
        var cb: Callable = _tap_start["cb"]
        tap_anywhere_stop()
        if cb.is_valid():
                cb.call()

func _unhandled_input(event: InputEvent) -> void:
        if over:
                return
        # v040-11 THE SHEET INPUT LAW (the owner's heavy war freeze): raw
        # touches leaked PAST a sheet's dim (the GUI stage eats the emulated
        # mouse, but the raw ScreenTouch still arrived here) - a stray tap on
        # the intro screen STARTED A RUN BEHIND the open box shop, the next
        # shop open then paused the tree, and its close had no unpause branch:
        # the frozen game. Law: while one of MY sheets (or the pause pair, or
        # the story card) owns the screen, the game hears NOTHING raw.
        if not _sheet_stack.is_empty() or not _pause_pair.is_empty() \
                                or box_story_open() or _lan_hold_ui != null:
                return
        # v0.4.1: a keyboard press also fires the universal intro tap (a PC
        # player's hands are on the keys - "tap anywhere" means ANYWHERE).
        if not _tap_start.is_empty() and event is InputEventKey \
                        and (event as InputEventKey).pressed:
                _fire_tap_start()
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

# ============================================== THE LAN SEAT (v042; r3 ROOMS)
## The system owns the room screen; the game only answers the routed
## calls (lan_match_start / lan_act / lan_snap / lan_prog / lan_end /
## lan_solo - duck-typed, both twins carry the same surface). The match
## params (the room owner's config) ride LAN.match_params -> lan_params.

func lan_hold_begin() -> void:
        if _lan_hold_ui != null:
                return
        lan_active = true
        _lan_hold_ui = LanHold.mount(self, game_id)
        _lan_hold_ui.cancelled.connect(_lan_hold_cancelled)
        _lan_route()

func lan_hold_close() -> void:
        if _lan_hold_ui != null:
                _lan_hold_ui.queue_free()
                _lan_hold_ui = null

func lan_hold_end_solo() -> void:
        ## The no-session fallback (pre_open false): the game plays the
        ## ordinary solo game - CPU seats return. The hold itself NEVER
        ## falls through to this anymore (the solo law is dead).
        lan_hold_close()
        if has_method("lan_solo"):
                call("lan_solo")

func _lan_hold_cancelled() -> void:
        ## The player cancelled the hold - back to the box.
        lan_hold_close()
        quit_to_box()

func _lan_route() -> void:
        if _lan_routed:
                return
        _lan_routed = true
        LAN.match_started.connect(_lan_on_match_started)
        LAN.lan_denied.connect(_lan_on_denied)
        LAN.match_ended.connect(_lan_on_ended)
        LAN.session_died.connect(_lan_on_session_died)
        LAN.act_received.connect(_lan_on_act)
        LAN.snap_received.connect(_lan_on_snap)
        LAN.prog_received.connect(_lan_on_prog)
        LAN.chat_received.connect(_lan_chat_live)

func _lan_unroute() -> void:
        if not _lan_routed:
                return
        _lan_routed = false
        LAN.match_started.disconnect(_lan_on_match_started)
        LAN.lan_denied.disconnect(_lan_on_denied)
        LAN.match_ended.disconnect(_lan_on_ended)
        LAN.session_died.disconnect(_lan_on_session_died)
        LAN.act_received.disconnect(_lan_on_act)
        LAN.snap_received.disconnect(_lan_on_snap)
        LAN.prog_received.disconnect(_lan_on_prog)
        LAN.chat_received.disconnect(_lan_chat_live)

func _lan_on_match_started(gid: String, seed_v: int, m_seats: Array, params: Dictionary) -> void:
        if gid != game_id:
                return
        lan_hold_close()
        lan_active = true
        lan_seed = seed_v
        lan_seats = m_seats
        lan_params = params
        _lan_add_chat_button()
        if has_method("lan_match_start"):
                call("lan_match_start", seed_v, m_seats)

## THE CHAT SEAT (the owner: "add button in active-multiplayer games that
## is right after back button before the shop button, be in-between, and
## labeled chat") + THE CHAT BUTTON DOTS (the owner: "the button chat
## itself, get top right and top left yellow dots, top right for new
## messages that has not been read, and top left is for mentions").
var _chat_dot_unread: ColorRect = null
var _chat_dot_mention: ColorRect = null

func _lan_add_chat_button() -> void:
        if _hud_row == null or not is_instance_valid(_hud_row):
                return
        for c in _hud_row.get_children():
                if c is Button and (c as Button).text == "CHAT":
                        return
        var b := Arc.button("CHAT", Vector2(96, 56), 20, Color(0.16, 0.10, 0.05, 0.85),
                        func(): LanChatUi.open(self))
        _hud_row.add_child(b)
        _hud_row.move_child(b, 1)      # right after the back button
        _chat_btn = b
        var dot := ColorRect.new()
        dot.color = Color(1.0, 0.82, 0.1)
        dot.size = Vector2(14, 14)
        dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
        dot.visible = false
        b.add_child(dot)
        _chat_dot_unread = dot
        var mdot := ColorRect.new()
        mdot.color = Color(1.0, 0.82, 0.1)
        mdot.size = Vector2(14, 14)
        mdot.mouse_filter = Control.MOUSE_FILTER_IGNORE
        mdot.visible = false
        b.add_child(mdot)
        _chat_dot_mention = mdot
        _lan_chat_live({})
        _place_chat_dots.call_deferred()

func _place_chat_dots() -> void:
        if _chat_btn == null or not is_instance_valid(_chat_btn):
                return
        if _chat_dot_unread != null and is_instance_valid(_chat_dot_unread):
                _chat_dot_unread.position = Vector2(_chat_btn.size.x - 16, -4)
        if _chat_dot_mention != null and is_instance_valid(_chat_dot_mention):
                _chat_dot_mention.position = Vector2(2, -4)

func _lan_chat_live(_msg: Dictionary) -> void:
        if _chat_dot_unread != null and is_instance_valid(_chat_dot_unread):
                _chat_dot_unread.visible = LAN.chat_unread > 0
        if _chat_dot_mention != null and is_instance_valid(_chat_dot_mention):
                _chat_dot_mention.visible = LAN.chat_mention_unread > 0
        _place_chat_dots()

func _lan_on_denied(gid: String, why: String) -> void:
        if gid != game_id:
                return
        lan_hold_close()
        game_toast(why if why != "" else "LAN NOT AVAILABLE HERE")
        if has_method("lan_solo"):
                call("lan_solo")

func _lan_on_ended(gid: String, results: Array, why: String) -> void:
        if gid != game_id:
                return
        if why != "":
                game_toast(why)
        if lan_active and has_method("lan_end"):
                call("lan_end", results)

## THE DISCONNECT LAW in-game: the host's wire died mid-match - the
## verdict lands with an honest dq row (never a corrupted limbo).
func _lan_on_session_died(why: String) -> void:
        if not lan_active or not has_method("lan_end"):
                return
        game_toast(why)
        call("lan_end", [{"name": "THE HOST", "dq": true}])

func _lan_on_act(gid: String, who: int, a: Dictionary) -> void:
        if gid == game_id and has_method("lan_act"):
                call("lan_act", who, a)

func _lan_on_snap(gid: String, data: Dictionary) -> void:
        if gid == game_id and has_method("lan_snap"):
                call("lan_snap", data)

func _lan_on_prog(gid: String, from_dev: String, data: Dictionary) -> void:
        if gid == game_id and has_method("lan_prog"):
                call("lan_prog", from_dev, data)

# ---------- r3 THE ABSOLUTE SEAT HELPERS (both twins) ----------
## The match seats ride in JOIN ORDER and never rotate to the reader:
## index 0 is the room's first-ready player on EVERY device. Colors,
## names and turns key off these indexes; the local player is only
## highlighted with YOU, never re-colored (the owner: "make the color of
## the player be different and not same ... both players see themself as
## shazam and both see the other player as marble").

## My absolute index in the match seats (-1 when not seated).
func lan_my_index() -> int:
        var my_devs := [LAN.my_dev(), LAN.my_dev() + LAN.COMBO_DEV]
        for i in lan_seats.size():
                if my_devs.has(String(lan_seats[i].get("dev", ""))):
                        return i
        return -1

## The absolute seat's display name.
func lan_name_of(idx: int) -> String:
        if idx < 0 or idx >= lan_seats.size():
                return "PLAYER"
        return String(lan_seats[idx].get("name", "PLAYER"))

## The absolute seat's dev.
func lan_dev_of(idx: int) -> String:
        if idx < 0 or idx >= lan_seats.size():
                return ""
        return String(lan_seats[idx].get("dev", ""))

## THE CPU WORD LAW (the owner: "change label CPU anywhere to the
## perspective player name"): a turn banner in a LAN match reads the
## CURRENT PLAYER's name - never "CPU".
func lan_turn_name(idx: int) -> String:
        return lan_name_of(idx).to_upper()

# ============================================== THE BOX STORY (v0.3.9-13)
## THE CHARACTERS' POP-UP DIALOGUE - the one shared lore card every new
## character rides (the owner: "make each character in their games to
## have a proper Pop-up dialogue/text design with proper look with
## proper timing and proper text lines so it appears in other games and
## feel....something alive!"). The invaders/pacman story sheet, grown a
## face: the character name wears ITS OWN color, a name bar seats under
## it, and the words TYPE IN (the typewriter beat - alive, skippable).
## THE STORY SHEET LAW (law 25) shape (a): the raw Arc.sheet + THE
## TRACKED PAIR freed by our own closer - it never joins the sheet
## stack, the back button never eats it. First-start / first-end hooks
## ride `Box.counter` + `Box.bump_counter` (the once-ever law).

var _box_story_pair: Array = []      # the exact dim+card pair
var _box_story_paused := false       # THIS story paused the tree
var _box_story_tween: Tween = null   # the typewriter's hand
var _box_story_typing := false

func box_story_show(title: String, msg: String, after := Callable(),
        btn := "CONTINUE", tint := Color(1.0, 0.82, 0.30)) -> void:
        box_story_down()
        paused = true
        get_tree().paused = true
        _box_story_paused = true
        var root := _overlay_root_ref()
        var sheet := Arc.sheet(root, 0.0)
        var kids := root.get_children()
        var sdim: Control = kids[kids.size() - 2]
        var scc: Control = kids[kids.size() - 1]
        sdim.process_mode = Node.PROCESS_MODE_ALWAYS
        scc.process_mode = Node.PROCESS_MODE_ALWAYS
        _box_story_pair = [sdim, scc]
        # THE NAME PLATE: the character's own color carries the card
        var t := Arc.label(title, 34, tint)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var bar := ColorRect.new()
        bar.custom_minimum_size = Vector2(220, 5)
        bar.color = Color(tint, 0.75)
        bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(bar)
        # THE WORDS: the scroll body, then the typewriter beat
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.44, 240.0,
                        470.0))
        var story := Arc.label(msg, 22, Arc.INK, false)
        story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        story.custom_minimum_size = Vector2(540, 0)
        story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(story)
        sheet.add_child(sc)
        sheet.add_child(Arc.button(btn, Vector2(560, 78), 28, Arc.GOOD,
                        func(): _box_story_btn(after)))
        for b in Arc._buttons_in(sc):
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))
        # the typewriter (runs THROUGH the pause - TWEEN_PAUSE_PROCESS):
        # ~55 glyphs a second, the beat the characters talk at
        story.visible_characters = 0
        var total := msg.length()
        _box_story_typing = true
        _box_story_tween = story.create_tween()
        _box_story_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        _box_story_tween.tween_property(story, "visible_characters",
                        total, maxf(0.6, total / 55.0))
        _box_story_tween.finished.connect(func(): _box_story_typing = false)

## the story button: first press hears the REST of the line (skip the
## typing), the next press walks the story on
func _box_story_btn(after: Callable) -> void:
        if _box_story_typing:
                _box_story_typing = false
                if _box_story_tween != null and _box_story_tween.is_valid():
                        _box_story_tween.kill()
                for n in _box_story_pair:
                        if n != null and is_instance_valid(n):
                                for lbl in (n as Control).find_children("*",
                                                "Label", true, false):
                                        if lbl is Label and (lbl as Label) \
                                                        .visible_characters >= 0:
                                                (lbl as Label) \
                                                                .visible_characters = -1
                return
        box_story_end(after)

func box_story_end(after: Callable) -> void:
        box_story_down()
        get_tree().paused = false
        paused = false
        _box_story_paused = false
        if after.is_valid():
                after.call()

func box_story_down() -> void:
        if _box_story_tween != null and _box_story_tween.is_valid():
                _box_story_tween.kill()
        _box_story_tween = null
        _box_story_typing = false
        for n in _box_story_pair:
                if n != null and is_instance_valid(n):
                        n.queue_free()
        _box_story_pair = []

## THE SESSION SEAT (the flow rig's law, v0.3.9-13): is a character
## story card open right now? - the shared card, or the legacy
## invaders/pacman pair (those games own their own card).
func box_story_open() -> bool:
        if not _box_story_pair.is_empty():
                return true
        return "_story_pair" in self and not (_story_pair_ref() as Array) \
                        .is_empty()

## the session's hand: whatever character story is open ends NOW - the
## quit path calls it so a first-boot lore (the player quits instead of
## tapping through) never carries the tree pause into the next launch
func box_story_dismiss() -> void:
        if not _box_story_pair.is_empty():
                box_story_end(Callable())
                return
        if "_story_pair" in self and has_method("story_down"):
                call("story_down")

func _story_pair_ref() -> Array:
        var v: Variant = get("_story_pair")
        return v if v is Array else []
