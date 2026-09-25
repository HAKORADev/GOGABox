extends CanvasLayer
class_name LanHold
## THE ROOM SCREEN — the system-owned multiplayer front door (v042-1 r3,
## the room law). Replaces the old hold/countdown screen whole.
##
## A LAN game boot lands here: the PICKER (open rooms for this game -
## "dimension" list - plus CREATE MY ROOM) or MY ROOM (the members in
## join order = 1ST/2ND/3RD..., the owner's config, and for the members
## the brown WAITING FOR <OWNER> TO START THE GAME line). The match is
## born ONLY when the room's owner presses START - never on a timer
## (THE LONE LAW and THE TEN SECONDS LAW are dead - the owner: "in the
## wait menu, it auto-ends the wait and jump solo, remove this mechanic").
## A room seat is first-come on the host's pump: a racing loser reads
## "CONFLICTION HAPPENED WITH ANOTHER PLAYER" (LAN.room_refused).
##
## The owner's room carries ROOM SETTINGS (the game's own hook
## lan_room_settings(vb) - optional) whose changes broadcast live; the
## members see the config lines and the brown wait. The game never
## initializes before START (the game's match world is built inside
## lan_match_start).
##
## The widget is ONE shared class used by both twins (THE TWIN LAW).

signal cancelled

var game_id := ""
var game: Node = null               # the GogaGame / GogaGame3D (hooks)
var _vb: VBoxContainer
var _body: VBoxContainer
var _clock_label: Label
var _age := 0.0
var _closed := false
var _settings_pair: Array = []      # the inner settings sheet's dim+card

static func mount(parent: Node, p_game_id: String) -> LanHold:
        var h := LanHold.new()
        h.game_id = p_game_id
        h.game = parent
        h.layer = 80
        parent.add_child(h)
        return h

func _ready() -> void:
        var g: Dictionary = GameReg.get_game(game_id)
        var title := String(g.get("title", game_id))
        var dim := ColorRect.new()
        dim.color = Color(0.08, 0.04, 0.02, 0.86)
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(dim)
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(cc)
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel", Arc.panel_style(Arc.CARD, 30, 30))
        cc.add_child(panel)
        _vb = VBoxContainer.new()
        _vb.custom_minimum_size = Vector2(Arc.SHEET_INNER_MIN * 0.86, 0)
        _vb.add_theme_constant_override("separation", 14)
        panel.add_child(_vb)
        _vb.add_child(Arc.label("LAN ROOM", 40, Arc.INK))
        _vb.add_child(Arc.label(title.to_upper(), 24, Arc.HOT))
        _clock_label = Arc.label("WAITING 0 S", 20, Color("6a4a28"), false)
        _vb.add_child(_clock_label)
        _body = VBoxContainer.new()
        _body.add_theme_constant_override("separation", 10)
        _vb.add_child(_body)
        Arc.fit_sheet(_vb, 1)
        LAN.rooms_changed.connect(_refresh)
        LAN.session_changed.connect(_on_session_changed)
        LAN.room_refused.connect(_on_refused)
        LAN.match_started.connect(_on_match_started)
        LAN.session_died.connect(_on_died)
        set_process(true)
        _refresh()

func _process(delta: float) -> void:
        if _closed:
                return
        _age += delta
        _clock_label.text = "WAITING %d S" % int(_age)

func _on_session_changed() -> void:
        _refresh()

func _on_refused(why: String) -> void:
        if _closed:
                return
        if _body != null and is_instance_valid(_body):
                _body.add_child(Arc.label(why.to_upper(), 20, Color(0.9, 0.45, 0.3), false))

## ---------------- the two views ----------------

func _refresh() -> void:
        if _closed or _body == null or not is_instance_valid(_body):
                return
        for c in _body.get_children():
                c.queue_free()
        if not LAN.session_active():
                _on_died("the session is gone")
                return
        var r := LAN.my_room()
        if r.is_empty() or String(r.get("game", "")) != game_id:
                _build_picker()
        else:
                _build_room(r)

## THE PICKER: the open rooms of THIS game (the dimensions) + create.
func _build_picker() -> void:
        var open_rooms := LAN.rooms_for_game(game_id)
        var joinable := []
        for rr in open_rooms:
                if String(rr.get("phase", "wait")) == "wait":
                        joinable.append(rr)
        if joinable.is_empty():
                _body.add_child(Arc.label("NO ROOM OPEN YET - MAKE THE FIRST ONE", 22, Arc.HOT))
        else:
                _body.add_child(Arc.label("OPEN ROOMS - PICK YOURS", 22, Arc.HOT))
                for rr in joinable:
                        _body.add_child(_room_row(rr))
        var cap := LAN.game_room_cap(game_id)
        _body.add_child(Arc.button("CREATE MY ROOM", Vector2(0, 84), 30, Arc.GOOD,
                        func():
                        Jukebox.sfx("click", -4.0)
                        var err := LAN.open_room(game_id, {})
                        if err != "":
                                _body.add_child(Arc.label(err.to_upper(), 20, Color(0.9, 0.45, 0.3), false))
                        else:
                                _refresh()))
        _body.add_child(Arc.label("the room's first player owns it - others join and wait for the owner to start. up to %d players" % cap,
                        17, Color("6a4a28"), false))
        _body.add_child(Arc.button("CANCEL", Vector2(0, 64), 24, Arc.BAD, func(): _close(true)))

func _room_row(rr: Dictionary) -> Control:
        var row := PanelContainer.new()
        row.add_theme_stylebox_override("panel", Arc.panel_style(Color(0, 0, 0, 0.12), 18))
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 10)
        var owner_dev := String(rr.get("owner", ""))
        var os := LAN.seat_by_dev(owner_dev)
        var cap := LAN.game_room_cap(game_id)
        var n: int = (rr.get("members", []) as Array).size()
        var nm := Arc.label("%s'S ROOM  %d/%d" % [String(os.get("name", "PLAYER")).to_upper(), n, cap],
                        22, Arc.INK, false)
        nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        h.add_child(nm)
        var full := n >= cap
        var mine := (rr.get("members", []) as Array).has(LAN.my_dev())
        var tag := "YOURS" if mine else ("FULL" if full else "OPEN")
        h.add_child(Arc.label(tag, 17, Arc.GOOD if not full else Color(0.9, 0.45, 0.3), false))
        var b := Arc.button("JOIN", Vector2(140, 56), 20, Arc.ACCENT, func():
                Jukebox.sfx("click", -4.0)
                var err := LAN.join_room(int(rr.get("rid", 0)))
                if err != "":
                        _body.add_child(Arc.label(err.to_upper(), 20, Color(0.9, 0.45, 0.3), false))
                else:
                        _refresh())
        b.disabled = full or mine
        h.add_child(b)
        row.add_child(h)
        return row

## MY ROOM: the members in join order + the owner's controls / the brown
## wait. The members see WAITING FOR <OWNER> TO START THE GAME.
func _build_room(r: Dictionary) -> void:
        var members := LAN.room_members(int(r.get("rid", 0)))
        var owner_dev := String(r.get("owner", ""))
        var am_owner := owner_dev == LAN.my_dev()
        _body.add_child(Arc.label("THE ROOM - %d/%d  -  SEATS BY WHO GOT READY FIRST" % [
                        members.size(), LAN.game_room_cap(game_id)], 20, Arc.HOT))
        for i in members.size():
                _body.add_child(_member_row(members[i], i + 1,
                                String(members[i].get("dev", "")) == owner_dev))
        # the owner's config lines (the game's own words for its params)
        var params: Dictionary = r.get("params", {})
        if game != null and is_instance_valid(game) \
                        and game.has_method("lan_params_lines"):
                for line in game.call("lan_params_lines", params):
                        _body.add_child(Arc.label(String(line), 19, Arc.INK, false))
        if am_owner:
                if members.size() < 2:
                        _body.add_child(Arc.label("WAIT FOR ONE MORE PLAYER TO START", 20, Color("6a4a28"), false))
                if game != null and is_instance_valid(game) \
                                and game.has_method("lan_room_settings"):
                        _body.add_child(Arc.button("ROOM SETTINGS", Vector2(0, 70), 26,
                                        Color(0.16, 0.10, 0.05, 0.85), func(): _open_settings()))
                _body.add_child(Arc.button("START THE GAME", Vector2(0, 92), 34, Arc.GOOD,
                                func(): _on_owner_start()))
        else:
                var os := LAN.seat_by_dev(owner_dev)
                # THE BROWN WAIT (the owner's law, verbatim words)
                var wait := Arc.label("WAITING FOR %s TO START THE GAME" % String(os.get("name", "THE OWNER")).to_upper(),
                                26, Color(0.62, 0.38, 0.14), false)
                wait.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                wait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                _body.add_child(wait)
        _body.add_child(Arc.button("LEAVE THE ROOM" if not am_owner else "CLOSE MY ROOM",
                        Vector2(0, 64), 22, Arc.BAD, func():
                        Jukebox.sfx("click", -4.0)
                        LAN.leave_room()
                        _refresh()))

func _member_row(s: Dictionary, rseat: int, is_owner: bool) -> Control:
        LAN.pfp_touch(s)
        var row := PanelContainer.new()
        row.add_theme_stylebox_override("panel", Arc.panel_style(Color(0, 0, 0, 0.12), 18))
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 12)
        var no := Arc.label("%d%s" % [rseat, ["ST", "ND", "RD", "TH"][clampi(rseat - 1, 0, 3)]],
                        24, Arc.HOT)
        no.custom_minimum_size = Vector2(74, 0)
        h.add_child(no)
        var media_v: Variant = s.get("pfpm", {})
        var media: Dictionary = media_v if typeof(media_v) == TYPE_DICTIONARY else {}
        var fig := GogaPfp.make(media, Vector2(52, 52))
        fig.variant = int(s.get("pfp", 0))
        h.add_child(fig)
        var name_l := Arc.label(String(s.get("name", "PLAYER")), 24, Arc.INK)
        name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        h.add_child(name_l)
        var me := String(s.get("dev", "")) == LAN.my_dev()
        var tag := "YOU" if me else ""
        if is_owner:
                tag = ("YOU - " if me else "") + "OWNER"
        elif tag == "":
                tag = "MEMBER"
        var platform := String(s.get("platform", "pc"))
        tag += "  ·  " + ("PHONE" if platform == "android" else "PC")
        if bool(s.get("ghost", false)):
                tag += "  ·  GHOST"
        h.add_child(Arc.label(tag, 17, Arc.GOOD if is_owner else Color("6a4a28"), false))
        row.add_child(h)
        return row

## THE OWNER'S SETTINGS: an inner sheet above the room card - the game
## fills it with its own controls (hook lan_room_settings(vb)); every
## change rides LAN.set_room_params to the room live.
func _open_settings() -> void:
        if game == null or not is_instance_valid(game):
                return
        _settings_close()
        var dim := ColorRect.new()
        dim.color = Color(0.05, 0.02, 0.01, 0.7)
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(dim)
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(cc)
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel", Arc.panel_style(Arc.CARD, 30, 30))
        cc.add_child(panel)
        var vb := VBoxContainer.new()
        vb.custom_minimum_size = Vector2(Arc.SHEET_INNER_MIN * 0.8, 0)
        vb.add_theme_constant_override("separation", 12)
        panel.add_child(vb)
        vb.add_child(Arc.label("ROOM SETTINGS", 34, Arc.INK))
        game.call("lan_room_settings", vb)
        vb.add_child(Arc.button("DONE", Vector2(0, 64), 24, Arc.ACCENT,
                        func(): _settings_close()))
        Arc.fit_sheet(vb, 1)
        _settings_pair = [dim, cc]

## THE OWNER'S START: the only birth door - the error lines land in the
## room card (never a toast the room screen could hide).
func _on_owner_start() -> void:
        Jukebox.sfx("unlock", -2.0)
        var err := LAN.start_match()
        if err != "" and _body != null and is_instance_valid(_body):
                _body.add_child(Arc.label(err.to_upper(), 20, Color(0.9, 0.45, 0.3), false))

func _settings_close() -> void:
        for n in _settings_pair:
                if is_instance_valid(n):
                        n.queue_free()
        _settings_pair = []

func _on_match_started(gid: String, _seed_v: int, _m_seats: Array, _params: Dictionary) -> void:
        if gid != game_id or _closed:
                return
        # the base routes the start to the game; the widget just steps aside
        _close(false)

func _on_died(_why: String) -> void:
        _close(true)

func _close(cancel: bool) -> void:
        if _closed:
                return
        _closed = true
        queue_free()
        if cancel:
                cancelled.emit()
