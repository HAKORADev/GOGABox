extends RefCounted
class_name LanRoster
## THE PAUSE ROSTER (v042-1, the owner: "in the pause menu, add button
## called multiplayer, in it, show each player number and who is the
## player behind it, in a proper well-designed way") + THE VOICE LAW
## seat: per-player two-layer toggles (MIC = they hear me / HEAR = I hear
## them) including the YOU row's master pair, with per-LAYER device
## detection ("some people may hear only or listen only and that is ok").

## Build the roster into a pause sheet's VBox. `game` is the GogaGame /
## GogaGame3D (the base carries lan_seats).
static func build(vb: VBoxContainer, game: Node) -> void:
        vb.add_child(Arc.label("MULTIPLAYER", 42, Arc.INK))
        var sub := Arc.label("THE PLAYERS AT THIS TABLE", 20, Arc.HOT)
        vb.add_child(sub)
        var list := VBoxContainer.new()
        list.add_theme_constant_override("separation", 10)
        vb.add_child(list)
        var my_dev := LAN.my_dev()
        for s in LAN.seats:
                list.add_child(_seat_row(s, my_dev))
        if LAN.seats.is_empty():
                list.add_child(Arc.label("no seats - the session ended", 20,
                                Color("8a6a40"), false))
        # THE VOICE LAW (the owner: "add mic support for devices that has
        # both in/out audio devices... two buttons next to each player...
        # one for hearing and second for listening")
        vb.add_child(Arc.label("VOICE", 20, Arc.HOT))
        var note := Arc.label("MIC = they hear me.  HEAR = I hear them.  every layer turns alone - a mic-less PC listens only, and that is fine", 17,
                        Color("8a6a40"), false)
        note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        vb.add_child(note)
        if Voice.mic_note() != "":
                var mn := Arc.label(Voice.mic_note(), 18, Color(0.9, 0.55, 0.2), false)
                mn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                vb.add_child(mn)
        var vlist := VBoxContainer.new()
        vlist.add_theme_constant_override("separation", 8)
        vb.add_child(vlist)
        for s in LAN.seats:
                vlist.add_child(_voice_row(s, my_dev))
        # the state refresh rides a per-frame tick on the sheet's owner
        # (the toggles repaint through their own press handlers - a live
        # chorus here would fight the pause)

static func _seat_row(s: Dictionary, my_dev: String) -> Control:
        var row := PanelContainer.new()
        row.add_theme_stylebox_override("panel", Arc.panel_style(Color(0, 0, 0, 0.12), 18))
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 12)
        # THE PLAYER NUMBER (the owner: "players are numbered")
        var no := Arc.label(str(int(s.get("seat", 1))), 30, Arc.HOT)
        no.custom_minimum_size = Vector2(44, 0)
        h.add_child(no)
        var media_v: Variant = s.get("pfpm", {})
        var media: Dictionary = media_v if typeof(media_v) == TYPE_DICTIONARY else {}
        var fig := GogaPfp.make(media, Vector2(52, 52))
        fig.variant = int(s.get("pfp", 0))
        h.add_child(fig)
        var nm := Arc.label(String(s.get("name", "PLAYER")), 24, Arc.INK)
        nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        h.add_child(nm)
        var me := String(s.get("dev", "")) == my_dev
        var tag := "YOU" if me else ("HOST" if int(s.get("seat", 1)) == 1 else "MEMBER")
        if int(s.get("local_slot", 0)) == 1:
                tag = "COMBO"
        var plat := "PHONE" if String(s.get("platform", "pc")) == "android" else "PC"
        h.add_child(Arc.label("%s  ·  %s" % [tag, plat], 17, Arc.GOOD, false))
        row.add_child(h)
        return row

static func _voice_row(s: Dictionary, my_dev: String) -> Control:
        var row := PanelContainer.new()
        row.add_theme_stylebox_override("panel", Arc.panel_style(Color(0, 0, 0, 0.12), 16))
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 10)
        var no := Arc.label(str(int(s.get("seat", 1))), 22, Arc.HOT)
        no.custom_minimum_size = Vector2(36, 0)
        h.add_child(no)
        var nm := Arc.label(String(s.get("name", "PLAYER")), 20, Arc.INK)
        nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        h.add_child(nm)
        var seat := int(s.get("seat", 1))
        var me := String(s.get("dev", "")) == my_dev
        if me:
                # THE YOU ROW: the master pair (my mic to the room, my hear)
                h.add_child(_voice_btn("MIC", func(): return Voice.mic_on,
                                func(): Voice.toggle_mic_master()))
                h.add_child(_voice_btn("HEAR", func(): return Voice.hear_on,
                                func(): Voice.toggle_hear_master()))
        else:
                var mic_ok: bool = Voice.has_mic and Voice.mic_granted
                var mic := _voice_btn("MIC", func(): return Voice.can_hear_me(seat),
                                func():
                                        if OS.get_name() == "Android" \
                                                        and not Voice.mic_granted:
                                                Voice.request_mic()
                                        Voice.toggle_mic_to(seat))
                if not mic_ok:
                        mic.disabled = true
                h.add_child(mic)
                h.add_child(_voice_btn("HEAR", func(): return Voice.i_can_hear(seat),
                                func(): Voice.toggle_hear_from(seat)))
        row.add_child(h)
        return row

## The toggle chip: green = on, gray = off. The press runs the toggle then
## repaints from the LIVE getter - no full-sheet rebuild, the pause stays
## calm. (Callable returns bool - GDScript lambdas: `func(): return x`.)
static func _voice_btn(txt: String, get_state: Callable, cb: Callable) -> Button:
        var b := Button.new()
        b.text = " %s " % txt
        b.custom_minimum_size = Vector2(120, 52)
        b.add_theme_font_override("font", Arc.font_ui())
        b.add_theme_font_size_override("font_size", 18)
        var paint := func():
                var on: bool = get_state.call()
                b.add_theme_color_override("font_color",
                                Arc.CARD if on else Color("9a8a70"))
                b.add_theme_stylebox_override("normal", Arc.panel_style(
                                Arc.GOOD if on else Color(0, 0, 0, 0.18), 16))
        paint.call()
        b.pressed.connect(func():
                Jukebox.sfx("click", -4.0)
                cb.call()
                paint.call())
        return b
