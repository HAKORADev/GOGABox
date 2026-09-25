extends CanvasLayer
class_name LanNotes
## THE TOP-LEVEL MULTIPLAYER NOTES (v042-1 r3, the owner: "currently the
## invitation message appears only in menu with it's all multiplayer
## bottom notifications, make all of them be top-level to appear anywhere
## any time in any position even in-games because they are very
## important").
##
## ONE app-wide layer (built by main.gd, layer 95 - above the hold and
## the achievements, under the toasts). It shows:
##   - INVITE CARDS - interactive, JOIN (or LEAVE AND JOIN when I already
##     ride a session - the switch law) / DECLINE, arriving ANYWHERE: the
##     main menu, a sheet, inside any game, mid-match, even paused
##     (PROCESS_MODE ALWAYS);
##   - NOTE BANNERS - the critical multiplayer lines (kicked, the session
##     died, the confliction line, the match aborted) sliding from the
##     top and leaving on their own.
## The card measures like the popup law (the font ladder, the real wrap).

signal invite_answered(accepted: bool)

static var instance: LanNotes = null

var _queue: Array = []             # {kind:"note"|"invite", ...}
var _live: Dictionary = {}
var _card: PanelContainer = null
var _tween: Tween = null

static func notes() -> LanNotes:
        return instance

static func note(text: String) -> void:
        if instance == null:
                return
        instance._push({"kind": "note", "text": text})

static func invite_card(from_name: String, addr: String, switch: bool) -> void:
        if instance == null:
                return
        # one invite at a time - the freshest wins
        instance._queue = instance._queue.filter(
                        func(q): return q.get("kind", "") != "invite")
        if instance._live.get("kind", "") == "invite":
                instance._down()
        instance._push({"kind": "invite", "from": from_name, "addr": addr,
                "switch": switch})

func _ready() -> void:
        instance = self
        layer = 95
        process_mode = Node.PROCESS_MODE_ALWAYS
        visible = true

func _push(q: Dictionary) -> void:
        _queue.append(q)
        if _live.is_empty():
                _next()

func _next() -> void:
        if _queue.is_empty() or _card != null:
                return
        _live = _queue.pop_front()
        _build_card()

func _down() -> void:
        if _tween != null and _tween.is_valid():
                _tween.kill()
                _tween = null
        if _card != null and is_instance_valid(_card):
                _card.queue_free()
        _card = null
        _live = {}
        _next()

func _build_card() -> void:
        var root := Control.new()
        root.set_anchors_preset(Control.PRESET_FULL_RECT)
        root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(root)
        var cc := VBoxContainer.new()
        cc.set_anchors_preset(Control.PRESET_CENTER_TOP)
        # THE CENTERED GROWTH: the anchor's pivot sits at the top-center -
        # without BOTH-way growth the card expands right and clips.
        cc.grow_horizontal = Control.GROW_DIRECTION_BOTH
        cc.grow_vertical = Control.GROW_DIRECTION_END
        cc.offset_top = 84.0          # a breath below the top bar
        cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        root.add_child(cc)
        var panel := PanelContainer.new()
        var is_invite: bool = String(_live.get("kind", "")) == "invite"
        panel.add_theme_stylebox_override("panel", Arc.panel_style(
                Color(0.16, 0.10, 0.05, 0.96) if is_invite else Color(0.10, 0.05, 0.02, 0.88), 24))
        panel.custom_minimum_size = Vector2(minf(760.0, Arc.sheet_width_for(
                        get_viewport().get_visible_rect().size.x)), 0)
        cc.add_child(panel)
        _card = panel
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 10)
        panel.add_child(v)
        if is_invite:
                var head := Arc.label("INVITE", 30, Arc.HOT)
                head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                v.add_child(head)
                var body_t := "%s invites you to their session" % String(_live.get("from", "A PLAYER"))
                if bool(_live.get("switch", false)):
                        body_t += "\njoining will leave your current session"
                var body := Arc.label(body_t, 21, Color(1.0, 0.94, 0.85), false)
                body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                body.custom_minimum_size.x = minf(700.0, panel.custom_minimum_size.x - 48)
                v.add_child(body)
                var addr := String(_live.get("addr", ""))
                if addr != "":
                        var al := Arc.label(addr, 16, Color(0.85, 0.65, 0.4), false)
                        al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        al.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
                        v.add_child(al)
                var row := HBoxContainer.new()
                row.alignment = BoxContainer.ALIGNMENT_CENTER
                row.add_theme_constant_override("separation", 14)
                var join_txt := "LEAVE AND JOIN" if bool(_live.get("switch", false)) else "JOIN"
                row.add_child(Arc.button(join_txt, Vector2(260, 68), 24, Arc.GOOD,
                                func(): _answer(true)))
                row.add_child(Arc.button("DECLINE", Vector2(200, 68), 22,
                                Color(0.42, 0.30, 0.16), func(): _answer(false)))
                v.add_child(row)
                # the invite waits for an answer, but not forever (20s)
                var t := get_tree().create_timer(20.0, true, false, true)
                t.timeout.connect(func():
                        if _live.get("kind", "") == "invite":
                                _down())
        else:
                var body := Arc.label(String(_live.get("text", "")), 22, Color(1.0, 0.94, 0.85), false)
                body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                body.custom_minimum_size.x = minf(700.0, panel.custom_minimum_size.x - 48)
                v.add_child(body)
                var t2 := get_tree().create_timer(3.2, true, false, true)
                t2.timeout.connect(func():
                        if _live.get("kind", "") == "note":
                                _down())
        Arc.fit_sheet(v, 1)
        # THE BIRTH: slide from the top (the popup law's entrance)
        panel.modulate.a = 0.0
        panel.position.y -= 40.0
        _tween = create_tween().set_parallel(true)
        _tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        _tween.tween_property(panel, "modulate:a", 1.0, 0.22)
        _tween.tween_property(panel, "position:y", panel.position.y + 40.0, 0.22)

func _answer(accepted: bool) -> void:
        Jukebox.sfx("click", -4.0)
        var addr := String(_live.get("addr", ""))
        _down()
        invite_answered.emit(accepted)
        if not accepted or addr == "":
                return
        # THE SWITCH LAW: leaving first is the honest move; the synced
        # updates ride the session_changed signal everywhere.
        if LAN.session_active():
                LAN.leave_session()
        var err := LAN.join_session(addr)
        if err != "":
                note(err.to_upper())
