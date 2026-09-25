extends RefCounted
class_name LanRoster
## THE PAUSE ROSTER (v042-1, the owner: "in the pause menu, add button
## called multiplayer, in it, show each player number and who is the
## player behind it, in a proper well-designed way") + THE VOICE LAW r3:
## the FOUR honest gates, all visible (the owner's semantics law):
##   THEIR MIC  - their live transmission state (the VST wire's truth)
##   THEIR HEAR - their live speaker state (do they hear the room?)
##   MY MIC     - the toggle: can THIS player hear me?
##   MY HEAR    - the toggle: do I hear this player?
## Everything is dev-keyed (the seat numbers renumbered; devs are forever).

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
        # THE VOICE LAW (the owner's semantics, all four gates visible)
        vb.add_child(Arc.label("VOICE", 20, Arc.HOT))
        var note := Arc.label("their mic = you hear them. their hear = they hear the room. my mic = they hear me. my hear = I hear them", 17,
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
                # THE YOU ROW: my master pair - my mic (nobody hears me when
                # it is off) and my hear (I hear nobody when it is off).
                h.add_child(_voice_btn("MY MIC", func(): return Voice.mic_on,
                                func(): Voice.toggle_mic_master()))
                h.add_child(_voice_btn("MY HEAR", func(): return Voice.hear_on,
                                func(): Voice.toggle_hear_master()))
                v.add_child(h)
        else:
                # THE REMOTE TRUTH: their live mic/hear states (the VST
                # wire), then my two gates toward them.
                var rs: Dictionary = Voice.remote_of(dev)
                var tm := Arc.label("THEIR MIC %s" % ("ON" if bool(rs.get("mic", false)) else "OFF"),
                                16, Arc.GOOD if bool(rs.get("mic", false)) else Color("9a8a70"), false)
                tm.custom_minimum_size = Vector2(150, 0)
                h.add_child(tm)
                var th := Arc.label("THEIR HEAR %s" % ("ON" if bool(rs.get("hear", true)) else "OFF"),
                                16, Arc.GOOD if bool(rs.get("hear", true)) else Color("9a8a70"), false)
                h.add_child(th)
                v.add_child(h)
                var h2 := HBoxContainer.new()
                h2.add_theme_constant_override("separation", 10)
                var mic_ok: bool = Voice.has_mic and Voice.mic_granted
                var mic := _voice_btn("MY MIC TO THEM", func(): return Voice.can_hear_me(dev),
                                func():
                                        if OS.get_name() == "Android" \
                                                        and not Voice.mic_granted:
                                                Voice.request_mic()
                                        Voice.toggle_mic_to(dev))
                if not mic_ok:
                        mic.disabled = true
                h2.add_child(mic)
                h2.add_child(_voice_btn("MY HEAR OF THEM", func(): return Voice.i_can_hear(dev),
                                func(): Voice.toggle_hear_from(dev)))
                v.add_child(h2)
        row.add_child(v)
        return row

## The toggle chip: green = on, gray = off. The press runs the toggle
## then repaints from the LIVE getter - and the press's OWN visual state
## is reset (r3 THE UNHANG LAW: the Android chip held its pressed paint
## after the lift, reading as a stuck "holding" state).
static func _voice_btn(txt: String, get_state: Callable, cb: Callable) -> Button:
        var b := Button.new()
        b.text = " %s " % txt
        b.custom_minimum_size = Vector2(120, 52)
        b.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
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
        b.pressed.connect(func():
                # the lift cleans the pressed paint on every state
                b.release_focus()
                b.accept_event())
        return b
