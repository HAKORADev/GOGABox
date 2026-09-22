class_name GogaGame3D
extends Node3D
## THE 3D TWIN of GogaGame (game/core/game_base.gd) - v041-2 THE 3D SEAT.
## Base class for every 3D GOGABox game. The GameHost instantiates the
## game's script and takes the entry fee exactly like a 2D game; the 3D
## world renders BEHIND all the box chrome (the loader, this HUD, every
## sheet and popup is a CanvasLayer/Control - 2D always paints above 3D),
## so a 3D game gets the WHOLE box service stack for free.
##
## THE TWIN LAW: this file mirrors game_base.gd var-for-var, signal-for-
## signal, method-for-method. GDScript has no multiple inheritance, so a
## shared base would force a base-type change across all 25 shipped 2D
## games - the risk the box never takes. THE COST: an infra change to one
## twin MUST be mirrored to the other (AGENTS.md law 51).
##
## A 3D game builds its world (Camera3D, lights, meshes) in _goga_setup();
## input arrives through the same TouchKit + _goga_input road as 2D (the
## box's key translation and gamepad seat included) - the box never
## learns 3D, the game maps screen events into its own world.

signal request_finish(score: int, coins_earned: int)
signal request_quit
signal request_orientation_reload(orient: String)

var game_id := ""
var score := 0
var run_coins := 0
var over := false
var paused := false
var pause_end_run := false
func _goga_pause_end_ok() -> bool:
        return true
var tk: TouchKit
var start_orientation := ""

func orientation_settled() -> void:
        pass

var score_bonus_enabled := true
var bonus_div_override := -1

var _hud: CanvasLayer
var _score_label: Label
var _coins_label: Label
var _score_prefix := ""
var _overlay_root: Control
var _toast: Dictionary
var _ach_clock := 0.0
var _hud_row: HBoxContainer
var _flow_btns := 0
var _sheet_stack: Array = []
var _pause_pair: Array = []
var _prev_msaa: int = Viewport.MSAA_DISABLED

func _ready() -> void:
        tk = TouchKit.new()
        add_child(tk)
        _build_hud()
        _toast = Arc.toast_overlay(self)
        _toast["layer"].process_mode = Node.PROCESS_MODE_ALWAYS
        # THE 3D QUALITY SEAT (v041-2): 2x MSAA while a 3D game lives - 3D
        # edges crawl without it and the casual look dies. Restored on exit;
        # msaa_3d touches NOTHING 2D (the 2D twins and the menu are safe).
        var vp := get_viewport()
        if vp != null:
                _prev_msaa = vp.msaa_3d
                vp.msaa_3d = Viewport.MSAA_2X
        _goga_setup()

func _exit_tree() -> void:
        var vp := get_viewport()
        if vp != null:
                vp.msaa_3d = _prev_msaa
        # v041-2 r2 THE SEAT DEATH LAW (the twin mirror of game_base's fix):
        # the static game cursor seat dies WITH the game node - a game that
        # armed the OS pointer must never outlive its own node, or the next
        # set_held anywhere (the menu's LMB mirror, the next game) swaps the
        # dead game's images back in (the owner's war-cursor leak).
        if _game_cur_armed:
                _game_cur_armed = false
                GogaCursorLib.game_disarm()

func game_toast(msg: String) -> void:
        Arc.toast(_toast, msg)

# --------------------------------------------------- override these 3

func _goga_setup() -> void:
        pass

func _goga_tick(_delta: float) -> void:
        pass

func _goga_input(_event: InputEvent) -> void:
        pass

# --------------------------------------------------- the game cursor seat

const GogaCursorLib := preload("res://game/core/goga_cursor.gd")
var _game_cur_armed := false

func game_cursor_arm(normal: Texture2D, click: Texture2D = null,
                hotspot := Vector2.ZERO) -> void:
        if not ScaleRule.is_pc() or normal == null:
                return
        _game_cur_armed = GogaCursorLib.game_arm(normal, click, hotspot)

func game_cursor_disarm() -> void:
        if not _game_cur_armed:
                return
        _game_cur_armed = false
        GogaCursorLib.game_disarm()

func _input(event: InputEvent) -> void:
        if not _game_cur_armed:
                return
        if event is InputEventMouseButton \
                        and (event as InputEventMouseButton).button_index \
                        == MOUSE_BUTTON_LEFT and ScaleRule.is_pc():
                GogaCursorLib.set_held((event as InputEventMouseButton).pressed)

# --------------------------------------------------- host-provided services

func set_score(v: int) -> void:
        score = v
        if _score_label != null:
                _score_label.text = _score_prefix + str(v)

func add_score(v: int) -> void:
        set_score(score + v)

func add_run_coins(v: int) -> void:
        run_coins += v
        if _coins_label != null:
                _coins_label.text = str(run_coins)

func finish_run(final_score: int, final_coins := -1) -> void:
        if over:
                return
        over = true
        run_coins = final_coins if final_coins >= 0 else run_coins
        request_finish.emit(final_score, run_coins)

func quit_to_box() -> void:
        request_quit.emit()

# --------------------------------------------------- the sheet stack

func sheet_push(sheet_height := 0.0, id := "", sheet_width := -1.0) -> VBoxContainer:
        var root := _overlay_root_ref()
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        Arc.pending_key = id
        var vb := Arc.sheet(root, sheet_height, sheet_width)
        var kids := root.get_children()
        var dim: Control = kids[kids.size() - 2]
        var cc: Control = kids[kids.size() - 1]
        dim.process_mode = Node.PROCESS_MODE_ALWAYS
        cc.process_mode = Node.PROCESS_MODE_ALWAYS
        dim.gui_input.connect(func(ev: InputEvent):
                if ev is InputEventMouseButton \
                                and (ev as InputEventMouseButton).pressed \
                                and (ev as InputEventMouseButton).button_index \
                                == MOUSE_BUTTON_LEFT:
                        sheet_pop())
        _sheet_stack.append({"dim": dim, "cc": cc, "id": id})
        # v041-2 r2 THE BIRTH GRACE (the twin mirror): one full-rect shield
        # eats every pointer event on the sheet's birth frame, then dies -
        # a sheet opened from inside a press handler can never have a button
        # under the pointer born already pressed.
        var shield := Control.new()
        shield.name = "SheetBirthShield"
        shield.set_anchors_preset(Control.PRESET_FULL_RECT)
        shield.mouse_filter = Control.MOUSE_FILTER_STOP
        root.add_child(shield)
        root.move_child(shield, root.get_child_count() - 1)
        shield.ready.connect(func():
                var tw := shield.create_tween()
                tw.tween_interval(0.05)
                tw.tween_callback(func():
                        if shield != null and is_instance_valid(shield):
                                shield.queue_free()))
        return vb

func sheet_pop() -> void:
        if _sheet_stack.is_empty():
                return
        var s: Dictionary = _sheet_stack.pop_back()
        for k in [s["dim"], s["cc"]]:
                if k != null and is_instance_valid(k):
                        for sc in (k as Control).find_children("*", "BoxScroll", true, false):
                                (sc as BoxScroll).remember()
        for k in [s["dim"], s["cc"]]:
                if k != null and is_instance_valid(k):
                        k.queue_free()
        _goga_sheet_popped(String(s.get("id", "")))

func _goga_sheet_popped(_id: String) -> void:
        pass

func sheet_open_count() -> int:
        return _sheet_stack.size()

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

func check_achievements() -> int:
        var g := GameReg.get_game(game_id)
        var new_count := 0
        for a in g.get("ach", []):
                var ok := _ach_rule_ok(a.get("rule", {}) as Dictionary)
                if ok and Box.grant_achievement(game_id, String(a["id"])):
                        new_count += 1
                        Achiever.award(game_id, a)
        return new_count

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

func set_hud_score_prefix(prefix: String) -> void:
        _score_prefix = prefix + " "
        if _score_label != null:
                _score_label.text = _score_prefix + str(score)

func banner_safe_px() -> float:
        var dpi := DisplayServer.screen_get_dpi()
        var win := DisplayServer.window_get_size()
        var vp := get_viewport().get_visible_rect().size
        if win.x <= 0 or win.y <= 0 or vp.x <= 0.0 or vp.y <= 0.0:
                return 64.0
        var px_per_logical := minf(float(win.x) / vp.x, float(win.y) / vp.y)
        var phys := 52.0 * dpi / 160.0 + 12.0
        return maxf(64.0, ceilf(phys / maxf(0.05, px_per_logical)))

func banner_bottom() -> float:
        return 0.0

func add_hud_button(txt: String, cb: Callable) -> void:
        if _hud_row == null or not is_instance_valid(_hud_row):
                return
        var b := Arc.button(txt, Vector2(96, 56), 20, Color(0.16, 0.10, 0.05, 0.85), cb)
        _hud_row.add_child(b)
        _hud_row.move_child(b, 1 + _flow_btns)
        _flow_btns += 1

func add_hud_chip(txt: String, icon_path := "") -> Label:
        if _hud_row == null or not is_instance_valid(_hud_row):
                return null
        var chip := Arc.chip(txt, icon_path, Color(0, 0, 0, 0.4), 22, Arc.CARD)
        _hud_row.add_child(chip)
        _hud_row.move_child(chip, _hud_row.get_child_count() - 2)
        return chip.get_child(0).get_child(chip.get_child(0).get_child_count() - 1)

## v041-2 r2: a CUSTOM control in the top bar, just left of the score chip
## (the owner: "make a widget next score from the left"). The widget keeps
## its own minimum size - the row flows around it like any chip.
func add_hud_widget(c: Control) -> void:
        if _hud_row == null or not is_instance_valid(_hud_row):
                return
        _hud_row.add_child(c)
        _hud_row.move_child(c, _hud_row.get_child_count() - 2)

func _score_label_ref() -> Label:
        return _score_label

func _coins_label_ref() -> Label:
        return _coins_label

func _score_chip_ref() -> Control:
        if _score_label == null or _score_label.get_parent() == null:
                return null
        return _score_label.get_parent().get_parent() as Control

func _coins_chip_ref() -> Control:
        if _coins_label == null or _coins_label.get_parent() == null:
                return null
        return _coins_label.get_parent().get_parent() as Control

func _overlay_root_ref() -> Control:
        return _overlay_root

func _toast_ref() -> Dictionary:
        return _toast

func _pause_open() -> void:
        if over or paused or not _pause_pair.is_empty():
                return
        paused = true
        get_tree().paused = true
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        var sheet := Arc.sheet(_overlay_root, 0.0)
        var kids := _overlay_root.get_children()
        var dim: Control = kids[kids.size() - 2]
        var cc: Control = kids[kids.size() - 1]
        dim.process_mode = Node.PROCESS_MODE_ALWAYS
        cc.process_mode = Node.PROCESS_MODE_ALWAYS
        _pause_pair = [dim, cc]
        dim.gui_input.connect(func(ev: InputEvent):
                if ev is InputEventMouseButton \
                                and (ev as InputEventMouseButton).pressed \
                                and (ev as InputEventMouseButton).button_index \
                                == MOUSE_BUTTON_LEFT:
                        _pause_close())
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
                _pause_close()
                quit_to_box()))
        Arc.fit_sheet(sheet, 3 if end_ok else 2)

func _pause_close() -> void:
        get_tree().paused = false
        paused = false
        for k in _pause_pair:
                if k != null and is_instance_valid(k):
                        k.queue_free()
        _pause_pair = []

# --------------------------------------------------- unified input plumbing

func ensure_pause_for_box() -> void:
        if over or paused or not _pause_pair.is_empty():
                return
        if not _sheet_stack.is_empty() or box_story_open():
                return
        _pause_open()

# ============================================== THE TAP-ANYWHERE LAW

var _tap_start: Dictionary = {}

func tap_anywhere_start(cb: Callable, note := "TAP ANYWHERE TO START") -> void:
        tap_anywhere_stop()
        var root := _overlay_root_ref()
        var ov := Control.new()
        ov.name = "TapAnywhere"
        ov.set_anchors_preset(Control.PRESET_FULL_RECT)
        ov.mouse_filter = Control.MOUSE_FILTER_STOP
        ov.gui_input.connect(func(ev: InputEvent):
                # v041-2 r2 THE TAP LAW (the twin mirror of game_base's fix):
                # fire on the RELEASE - a tap is press + release, and firing on
                # the press let the same click's emulated touch + release
                # self-press whatever UI the callback built (the optionals
                # skipped themselves).
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
        if not _sheet_stack.is_empty() or not _pause_pair.is_empty() \
                                or box_story_open():
                return
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
        _ach_clock += delta
        if _ach_clock >= 3.0:
                _ach_clock = 0.0
                check_achievements()

# ============================================== THE BOX STORY

var _box_story_pair: Array = []
var _box_story_tween: Tween = null
var _box_story_typing := false

func box_story_show(title: String, msg: String, after := Callable(),
        btn := "CONTINUE", tint := Color(1.0, 0.82, 0.30)) -> void:
        box_story_down()
        paused = true
        get_tree().paused = true
        var root := _overlay_root_ref()
        var sheet := Arc.sheet(root, 0.0)
        var kids := root.get_children()
        var sdim: Control = kids[kids.size() - 2]
        var scc: Control = kids[kids.size() - 1]
        sdim.process_mode = Node.PROCESS_MODE_ALWAYS
        scc.process_mode = Node.PROCESS_MODE_ALWAYS
        _box_story_pair = [sdim, scc]
        var t := Arc.label(title, 34, tint)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var bar := ColorRect.new()
        bar.custom_minimum_size = Vector2(220, 5)
        bar.color = Color(tint, 0.75)
        bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(bar)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport().get_visible_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.44, 240.0, 470.0))
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
        story.visible_characters = 0
        var total := msg.length()
        _box_story_typing = true
        _box_story_tween = story.create_tween()
        _box_story_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        _box_story_tween.tween_property(story, "visible_characters",
                        total, maxf(0.6, total / 55.0))
        _box_story_tween.finished.connect(func(): _box_story_typing = false)

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

func box_story_open() -> bool:
        return not _box_story_pair.is_empty()

func box_story_dismiss() -> void:
        if not _box_story_pair.is_empty():
                box_story_end(Callable())
