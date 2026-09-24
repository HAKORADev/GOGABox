extends RefCounted
class_name LanChatUi
## THE CHAT SHEET (v042-1, THE CHAT LAW) - one shared per-session chat:
## English only, no emojis, every line labeled with the sender's name +
## face, a hh:mm:ss arrival stamp under each message, 1K chars per
## message, a 5-second cooldown, 100 messages / 10MB then the earliest
## slides out (never a wipe), tap-to-reply (tap again cancels, tap
## another switches) - and it is NEVER saved: the log dies with the
## session (it lives in LAN).
##
## THE SEAT: a CHAT button in active-multiplayer games between the back
## button and the first game button, plus Ctrl+T on PC.

var _game: Node              # the GogaGame / GogaGame3D (sheet_push lives here)
var _sheet: VBoxContainer = null
var _list: VBoxContainer = null
var _reply := -1             # the tapped message's index (-1 none)
var _reply_bar: Label = null
var _input: TextEdit = null
var _send_btn: Button = null
var _count_l: Label = null
var _connected := false

static func open(game: Node) -> void:
        if game.has_meta("lan_chat_open"):
                game.get_meta("lan_chat_open").close()
                return
        var ui := LanChatUi.new()
        ui._game = game
        game.set_meta("lan_chat_open", ui)
        ui._build()

func close() -> void:
        if _connected and LAN.chat_received.is_connected(_on_chat):
                LAN.chat_received.disconnect(_on_chat)
        _connected = false
        if _game != null and is_instance_valid(_game) \
                        and _game.has_meta("lan_chat_open"):
                _game.remove_meta("lan_chat_open")
        if _sheet != null and is_instance_valid(_sheet):
                _game.sheet_pop()
        _sheet = null

func _build() -> void:
        _sheet = _game.sheet_push(0.0, "lanchat")
        _sheet.add_child(Arc.label("CHAT", 42, Arc.INK))
        _count_l = Arc.label("", 17, Color("8a6a40"), false)
        _sheet.add_child(_count_l)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.custom_minimum_size = Vector2(0, 620)
        _list = VBoxContainer.new()
        _list.add_theme_constant_override("separation", 10)
        _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(_list)
        _sheet.add_child(sc)
        # THE REPLY BAR (the tapped message's quote)
        _reply_bar = Arc.label("", 18, Arc.HOT, false)
        _reply_bar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _reply_bar.visible = false
        _sheet.add_child(_reply_bar)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 10)
        # v042-1 r2 THE SMART EXTRA-LINE LAW: the chat writes in a wrapping
        # area (1K chars can be long) - new lines as the line fills, the
        # SEND button sends, nothing scrolls sideways.
        _input = Arc.area("english only, no emojis", "", LAN.CHAT_MSG_MAX,
                        func(_t: String): pass, 2)
        _input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(_input)
        _send_btn = Arc.button("SEND", Vector2(160, 64), 22, Arc.GOOD,
                        func(): _send())
        row.add_child(_send_btn)
        _sheet.add_child(row)
        _sheet.add_child(Arc.button("CLOSE", Vector2(480, 64), 24, Arc.ACCENT,
                        func(): close()))
        Arc.fit_sheet(_sheet, 1)
        LAN.chat_received.connect(_on_chat)
        _connected = true
        _rebuild()

func _send() -> void:
        var err := LAN.send_chat(_input.text, _reply)
        if err != "":
                _count_l.text = err.to_upper()
                return
        _input.text = ""          # the commit door passed - clearing is safe
        _set_reply(-1)
        _rebuild()

func _on_chat(_msg: Dictionary) -> void:
        if _list != null and is_instance_valid(_list):
                _rebuild()

func _set_reply(idx: int) -> void:
        _reply = idx
        if idx >= 0 and idx < LAN.chat_log.size():
                var m: Dictionary = LAN.chat_log[idx]
                _reply_bar.text = "REPLY TO %s: %s" % [
                                String(m.get("name", "?")),
                                String(m.get("text", "")).substr(0, 60)]
                _reply_bar.visible = true
        else:
                _reply_bar.visible = false

func _rebuild() -> void:
        if _list == null or not is_instance_valid(_list):
                return
        for c in _list.get_children():
                c.queue_free()
        _count_l.text = "%d / %d MESSAGES  -  %.1f KB / 10240 KB" % [
                        LAN.chat_log.size(), LAN.CHAT_MAX_MSGS,
                        float(LAN.chat_bytes) / 1024.0]
        if LAN.chat_log.is_empty():
                _list.add_child(Arc.label("say something - it dies with the session, nothing is saved", 20,
                                Color("8a6a40"), false))
                return
        for i in LAN.chat_log.size():
                _list.add_child(_msg_row(i))

func _msg_row(idx: int) -> Control:
        var m: Dictionary = LAN.chat_log[idx]
        var mine := int(m.get("seat", -1)) == LAN.my_seat_no()
        var row := PanelContainer.new()
        row.add_theme_stylebox_override("panel", Arc.panel_style(
                        Color(0.98, 0.62, 0.1, 0.22) if mine else Color(0, 0, 0, 0.12), 16))
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 4)
        # THE LABEL: the sender's face + name
        var head := HBoxContainer.new()
        head.add_theme_constant_override("separation", 8)
        var media_v: Variant = m.get("pfpm", {})
        var media: Dictionary = media_v if typeof(media_v) == TYPE_DICTIONARY else {}
        var fig := GogaPfp.make(media, Vector2(36, 36))
        fig.variant = int(m.get("pfp", 0))
        head.add_child(fig)
        var who := "%s  (you)" % String(m.get("name", "?")) if mine \
                        else String(m.get("name", "?"))
        head.add_child(Arc.label(who, 19, Arc.HOT, false))
        v.add_child(head)
        var text := String(m.get("text", ""))
        # THE REPLY QUOTE: the answered line rides above the text
        var rt := int(m.get("reply_to", -1))
        if rt >= 0 and rt < LAN.chat_log.size():
                var src: Dictionary = LAN.chat_log[rt]
                var q := Arc.label("-> %s: %s" % [String(src.get("name", "?")),
                                String(src.get("text", "")).substr(0, 60)],
                                16, Color("8a6a40"), false)
                q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                v.add_child(q)
        var tl := Arc.label(text, 22, Arc.INK, false)
        tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        v.add_child(tl)
        # THE STAMP: hour:minute:second of the arrival clock
        var ts := int(m.get("ts", 0))
        var stamp := Time.get_time_dict_from_unix_time(ts)
        v.add_child(Arc.label("%02d:%02d:%02d" % [int(stamp.hour),
                        int(stamp.minute), int(stamp.second)], 14,
                        Color("8a6a40"), false))
        row.add_child(v)
        # THE REPLY LAW: tap = reply to it; tap again = cancel; tap another
        # = switch. The row rides the sheet scroll's tappable seat.
        var scroll := _sheet.get_child(2) as BoxScroll if _sheet.get_child_count() > 2 else null
        if scroll != null:
                scroll.register_tappable(row, func():
                        Jukebox.sfx("click", -6.0)
                        _set_reply(idx if _reply != idx else -1))
        return row
