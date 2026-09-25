extends RefCounted
class_name LanChatUi
## THE CHAT SHEET (v042-1, THE CHAT LAW; r3 THE LIVE COOLDOWN + THE
## LAST-READ SEAT) - one shared per-session chat: English only, no emojis,
## every line labeled with the sender's name + face, a hh:mm:ss arrival
## stamp under each message, 1K chars per message, a 5-second cooldown
## that is ALWAYS visible while it runs (the owner: "the cooldown is not
## dynamic, it waits to a send to be toggled so it shows wait nn, make it
## show always wait nn accurately then after count down it enables
## sending more"), 100 messages / 10MB then the earliest slides out
## (never a wipe), tap-to-reply (tap again cancels, tap another switches)
## - and it is NEVER saved: the log dies with the session (it lives in
## LAN).
##
## r3 THE ID LAW: replies carry the message's stable ID, not its index -
## the sliding window could silently retarget an index reply.
## r3 THE LAST-READ SEAT (the owner: "make the chat opens from where is
## the last read message was"): opening the sheet lands the scroll on the
## first line the reader has not seen (LAN.chat_read_id tracks it).
## r3 THE MENTION MARK: a line that names me wears the gold wash.

var _game: Node              # the GogaGame / GogaGame3D (sheet_push lives here)
var _sheet: VBoxContainer = null
var _list: VBoxContainer = null
var _reply := ""             # the tapped message's ID ("" none)
var _reply_bar: Label = null
var _input: TextEdit = null
var _send_btn: Button = null
var _count_l: Label = null
var _scroll: BoxScroll = null
var _connected := false
var _open_id := ""           # the oldest line at open time (the scroll seat)

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
        LAN.chat_ui_open = false
        LAN.chat_mark_read()
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
        _scroll = sc
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
        LAN.chat_ui_open = true
        LAN.chat_mark_read()
        # THE LAST-READ SEAT: the first line I have not read yet
        _open_id = LAN.chat_read_id
        _rebuild()
        _scroll_to_last_read.call_deferred()
        # THE LIVE COOLDOWN rides a Timer on the sheet (a RefCounted has
        # no _process): the send door tells the truth every 0.25s.
        var t := Timer.new()
        t.wait_time = 0.25
        t.autostart = true
        t.timeout.connect(_cooldown_update)
        _sheet.add_child(t)

func _scroll_to_last_read() -> void:
        if _scroll == null or not is_instance_valid(_scroll):
                return
        if _open_id == "":
                _scroll.scroll_vertical = 10000000    # the very bottom
                return
        var idx := _index_of(_open_id)
        if idx < 0:
                _scroll.scroll_vertical = 10000000
                return
        var row_h := 120.0
        if idx < _list.get_child_count():
                row_h = maxf(80.0, _list.get_child(idx).size.y + 10.0)
        _scroll.scroll_vertical = int(idx * row_h)

func _send() -> void:
        var err := LAN.send_chat(_input.text, _reply)
        if err != "":
                _count_l.text = err.to_upper()
                return
        _input.text = ""          # the commit door passed - clearing is safe
        _set_reply("")
        _rebuild()

func _on_chat(_msg: Dictionary) -> void:
        if _list != null and is_instance_valid(_list):
                _rebuild()

func _set_reply(mid: String) -> void:
        _reply = mid
        var idx := _index_of(mid)
        if idx >= 0:
                var m: Dictionary = LAN.chat_log[idx]
                _reply_bar.text = "REPLY TO %s: %s" % [
                                String(m.get("name", "?")),
                                String(m.get("text", "")).substr(0, 60)]
                _reply_bar.visible = true
        else:
                _reply_bar.visible = false

func _index_of(mid: String) -> int:
        if mid == "":
                return -1
        for i in LAN.chat_log.size():
                if String(LAN.chat_log[i].get("id", "")) == mid:
                        return i
        return -1

func _cooldown_update() -> void:
        # THE LIVE COOLDOWN: WAIT n S while it runs, SEND again the second
        # it is done - always visible, never waiting for a send to appear.
        if _send_btn == null or not is_instance_valid(_send_btn):
                return
        var left := LAN.chat_cooldown_left()
        if left > 0.05:
                _send_btn.disabled = true
                _send_btn.text = "WAIT %d S" % int(ceilf(left))
        else:
                _send_btn.disabled = false
                _send_btn.text = "SEND"

func _rebuild() -> void:
        if _list == null or not is_instance_valid(_list):
                return
        for c in _list.get_children():
                c.queue_free()
        var left := LAN.chat_cooldown_left()
        _count_l.text = "%d / %d MESSAGES  -  %.1f KB / 10240 KB" % [
                        LAN.chat_log.size(), LAN.CHAT_MAX_MSGS,
                        float(LAN.chat_bytes) / 1024.0]
        if left > 0.05:
                _count_l.text += "  -  WAIT %d S" % int(ceilf(left))
        if LAN.chat_log.is_empty():
                _list.add_child(Arc.label("say something - it dies with the session, nothing is saved", 20,
                                Color("8a6a40"), false))
                return
        for i in LAN.chat_log.size():
                _list.add_child(_msg_row(i))

func _msg_row(idx: int) -> Control:
        var m: Dictionary = LAN.chat_log[idx]
        var mine := String(m.get("dev", "")) == LAN.my_dev()
        var mentioned: bool = LAN._is_mention(String(m.get("text", ""))) and not mine
        var row := PanelContainer.new()
        var wash := Color(0.98, 0.62, 0.1, 0.22) if mine else Color(0, 0, 0, 0.12)
        if mentioned:
                wash = Color(0.98, 0.72, 0.1, 0.34)   # THE MENTION MARK
        row.add_theme_stylebox_override("panel", Arc.panel_style(wash, 16))
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
        # THE REPLY QUOTE: the answered line rides above the text (by ID -
        # a slid-out line reads as its honest ghost)
        var rt := String(m.get("reply_to", ""))
        var ridx := _index_of(rt)
        if ridx >= 0:
                var src: Dictionary = LAN.chat_log[ridx]
                var q := Arc.label("-> %s: %s" % [String(src.get("name", "?")),
                                String(src.get("text", "")).substr(0, 60)],
                                16, Color("8a6a40"), false)
                q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                v.add_child(q)
        elif rt != "":
                var q2 := Arc.label("-> an earlier line", 16, Color("8a6a40"), false)
                v.add_child(q2)
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
        if _scroll != null:
                var mid := String(m.get("id", ""))
                _scroll.register_tappable(row, func():
                        Jukebox.sfx("click", -6.0)
                        _set_reply("" if _reply == mid else mid))
        return row
