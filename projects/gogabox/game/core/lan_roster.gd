extends RefCounted
class_name LanRoster
## THE PAUSE ROSTER (v042-1, the owner: "in the pause menu, add button
## called multiplayer, in it, show each player number and who is the
## player behind it, in a proper well-designed way") + THE VOICE LAW r4:
## the toggles speak the owner's own words - LISTEN/TALK, direct:
##
##   MY TALK      - off: none of them hear me (my mic gate)
##   MY LISTEN    - off: I hear none of them (my speaker gate)
##   THEIR TALK   - off: my device does not hear their talk
##   THEIR LISTEN - off: their device does not take my talk
##
## r4 THE LIVE TRUTH: the remote states (THEY TALK / THEY LISTEN) repaint
## the moment the VST wire lands a change - the roster was a static
## snapshot before. r4 THE UNHANG PAINT: every chip wears ALL its own
## styleboxes (normal/hover/pressed/disabled/focus) - the engine's gray
## pressed paint can never bleed through and hang "until another click
## happens somewhere else" (the owner: "it should be off/on and that gray
## be on-click only").

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
                LAN.pfp_touch(s)
                list.add_child(_seat_row(s, my_dev))
        if LAN.seats.is_empty():
                list.add_child(Arc.label("no seats - the session ended", 20,
                                Color("8a6a40"), false))
        # THE VOICE LAW (the owner's semantics, all gates visible)
        vb.add_child(Arc.label("VOICE", 20, Arc.HOT))
        var note := Arc.label("MY TALK off = nobody hears me. MY LISTEN off = I hear nobody. THEIR TALK off = I do not hear them. THEIR LISTEN off = they do not hear me", 17,
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
        var st := String(s.get("state", ""))
        if st.begins_with("play:"):
                tag += "  ·  IN-GAME"
        elif st.begins_with("room:"):
                tag += "  ·  IN ROOM"
        var plat := "PHONE" if String(s.get("platform", "pc")) == "android" else "PC"
        h.add_child(Arc.label("%s  ·  %s" % [tag, plat], 17, Arc.GOOD, false))
        row.add_child(h)
        return row

static func _voice_row(s: Dictionary, my_dev: String) -> Control:
        var row := PanelContainer.new()
        row.add_theme_stylebox_override("panel", Arc.panel_style(Color(0, 0, 0, 0.12), 16))
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 6)
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 10)
        var no := Arc.label(str(int(s.get("seat", 1))), 22, Arc.HOT)
        no.custom_minimum_size = Vector2(36, 0)
        h.add_child(no)
        var nm := Arc.label(String(s.get("name", "PLAYER")), 20, Arc.INK)
        nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        h.add_child(nm)
        var dev := String(s.get("dev", ""))
        var me := dev == my_dev
        if me:
                # THE YOU ROW: my master pair - MY TALK (nobody hears me
                # when it is off) and MY LISTEN (I hear nobody when off).
                h.add_child(_voice_btn("MY TALK", func(): return Voice.mic_on,
                                func(): Voice.toggle_mic_master()))
                h.add_child(_voice_btn("MY LISTEN", func(): return Voice.hear_on,
                                func(): Voice.toggle_hear_master()))
                v.add_child(h)
        else:
                # THE REMOTE TRUTH (live): THEY TALK / THEY LISTEN repaint
                # from the VST wire the moment it changes.
                var h0 := HBoxContainer.new()
                h0.add_theme_constant_override("separation", 14)
                h0.add_child(_live_truth(dev, "THEY TALK",
                                func(): return bool(Voice.remote_of(dev).get("mic", false))))
                h0.add_child(_live_truth(dev, "THEY LISTEN",
                                func(): return bool(Voice.remote_of(dev).get("hear", true))))
                v.add_child(h0)
                var h2 := HBoxContainer.new()
                h2.add_theme_constant_override("separation", 10)
                var mic_ok: bool = Voice.has_mic and Voice.mic_granted
                # THEIR LISTEN: their device takes my talk (my mic gate).
                var listen := _voice_btn("THEIR LISTEN",
                                func(): return Voice.can_hear_me(dev),
                                func():
                                        if OS.get_name() == "Android" \
                                                        and not Voice.mic_granted:
                                                Voice.request_mic()
                                        Voice.toggle_mic_to(dev))
                if not mic_ok:
                        listen.disabled = true
                h2.add_child(listen)
                # THEIR TALK: my device hears their talk (my hear gate).
                h2.add_child(_voice_btn("THEIR TALK",
                                func(): return Voice.i_can_hear(dev),
                                func(): Voice.toggle_hear_from(dev)))
                v.add_child(h2)
        row.add_child(v)
        return row

## A live remote-truth label: repaints on every VST arrival (r4), dies
## quiet (the connection rides away with the label's tree exit).
static func _live_truth(dev: String, word: String, get_on: Callable) -> Label:
        var l := Arc.label("", 16, Arc.GOOD, false)
        l.custom_minimum_size = Vector2(150, 0)
        var paint := func():
                var on: bool = get_on.call()
                l.text = "%s %s" % [word, "ON" if on else "OFF"]
                l.add_theme_color_override("font_color",
                                Arc.GOOD if on else Color("9a8a70"))
        paint.call()
        var conn := Voice.voice_state_changed.connect(paint)
        l.tree_exited.connect(func():
                if Voice.voice_state_changed.is_connected(paint):
                        Voice.voice_state_changed.disconnect(paint))
        return l

## The toggle chip: green = on, dark = off. r4 THE UNHANG PAINT: the chip
## wears EVERY state's own stylebox - the engine's default gray pressed
## look cannot bleed through anymore, and the paint re-runs from the LIVE
## getter on the press AND on every remote state change (the gray used to
## hang until the next click somewhere else).
static func _voice_btn(txt: String, get_state: Callable, cb: Callable) -> Button:
        var b := Button.new()
        b.text = " %s " % txt
        b.custom_minimum_size = Vector2(150, 52)
        b.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
        b.add_theme_font_override("font", Arc.font_ui())
        b.add_theme_font_size_override("font_size", 18)
        var paint := func():
                var on: bool = get_state.call()
                for st in ["normal", "hover", "focus"]:
                        b.add_theme_stylebox_override(st, Arc.panel_style(
                                        Arc.GOOD if on else Color(0, 0, 0, 0.18), 16))
                # THE PRESS FLASH: the held/lift paint is the chip's OWN
                # ink one step brighter - never the engine's gray
                b.add_theme_stylebox_override("pressed", Arc.panel_style(
                                Arc.GOOD.lightened(0.18) if on
                                else Color(0, 0, 0, 0.30), 16))
                b.add_theme_stylebox_override("disabled", Arc.panel_style(
                                Color(0, 0, 0, 0.10), 16))
                b.add_theme_color_override("font_color",
                                Arc.CARD if on else Color("9a8a70"))
                b.add_theme_color_override("font_pressed_color",
                                Arc.CARD if on else Color("b0a088"))
                b.add_theme_color_override("font_hover_color",
                                Arc.CARD if on else Color("9a8a70"))
                b.add_theme_color_override("font_focus_color",
                                Arc.CARD if on else Color("9a8a70"))
        paint.call()
        b.pressed.connect(func():
                Jukebox.sfx("click", -4.0)
                cb.call()
                paint.call())
        b.button_down.connect(paint)
        var conn := Voice.voice_state_changed.connect(paint)
        b.tree_exited.connect(func():
                if Voice.voice_state_changed.is_connected(paint):
                        Voice.voice_state_changed.disconnect(paint))
        return b
