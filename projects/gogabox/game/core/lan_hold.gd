extends CanvasLayer
class_name LanHold
## THE HOLD SCREEN — the system-owned waiting room (v042).
##
## Every multiplayer-capable game opened by two or more holding players
## lands here first: seconds counting, arrivals appearing with their names
## and PFPs, leaves vanishing, THE TEN SECONDS countdown once someone
## commits, and the honest exits (nobody came -> solo; the match started
## without you -> solo; the host died -> back to the box).
##
## The widget is ONE shared class used by both twins (GogaGame + GogaGame3D
## mount it through their base — THE TWIN LAW holds: one widget, two hosts).

signal cancelled

var game_id := ""
var _vb: VBoxContainer
var _rows_box: VBoxContainer
var _clock_label: Label
var _count_label: Label
var _state_label: Label
var _go_btn: Button
var _age := 0.0
var _note_left := 0.0
var _closed := false

static func mount(parent: Node, p_game_id: String) -> LanHold:
	var h := LanHold.new()
	h.game_id = p_game_id
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
	_vb.add_child(Arc.label("LAN WAITING ROOM", 40, Arc.INK))
	_vb.add_child(Arc.label(title.to_upper(), 24, Arc.HOT))
	_clock_label = Arc.label("WAITING 0 S", 26, Arc.INK)
	_vb.add_child(_clock_label)
	_count_label = Arc.label("", 64, Arc.GOOD)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(_count_label)
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 8)
	_vb.add_child(_rows_box)
	_state_label = Arc.label("OPEN THE SAME GAME ON THE OTHER DEVICES", 18, Color("6a4a28"), false)
	_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vb.add_child(_state_label)
	_go_btn = Arc.button("GET IN", Vector2(0, 84), 34, Arc.GOOD, func(): _on_go())
	_vb.add_child(_go_btn)
	_vb.add_child(Arc.button("CANCEL", Vector2(0, 64), 24, Arc.BAD, func(): _close(true)))
	Arc.fit_sheet(_vb, 1)
	LAN.hold_changed.connect(_on_hold_changed)
	LAN.session_changed.connect(_refresh)
	LAN.match_started.connect(_on_match_started)
	LAN.match_left_out.connect(_on_left_out)
	LAN.solo_fallthrough.connect(_on_solo)
	LAN.session_died.connect(_on_died)
	set_process(true)

func _process(delta: float) -> void:
	if _closed:
		return
	_age += delta
	if _note_left > 0.0:
		_note_left -= delta
		if _note_left <= 0.0:
			_close(false)
			return
	var info: Dictionary = LAN.hold_info(game_id)
	if String(info.get("phase", "")) == "count":
		_count_label.text = str(int(ceilf(float(info.get("t_left", 0.0)))))
		_clock_label.text = "STARTING..."
		_go_btn.disabled = true
		_go_btn.text = "READY"
	else:
		_count_label.text = ""
		_clock_label.text = "WAITING %d S" % int(_age)
	_refresh()

func _on_go() -> void:
	Jukebox.sfx("click", -4.0)
	LAN.commit(game_id)
	_go_btn.disabled = true
	_go_btn.text = "READY"

func _on_hold_changed(_gid: String) -> void:
	_refresh()

func _refresh() -> void:
	if _closed or _rows_box == null:
		return
	for c in _rows_box.get_children():
		c.queue_free()
	var holders := LAN.holders_of(game_id)
	var committed := LAN.committed_of(game_id)
	var in_session := LAN.session_size()
	_state_label.text = "%d OF %d IN THE ROOM  -  %d READY" % [holders.size(), in_session, committed.size()]
	for s in holders:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		# v042-1: the row's face rides GogaPfp - a media face paints here
		# exactly like everywhere else (ONE renderer, every seat)
		var media_v: Variant = s.get("pfpm", {})
		var media: Dictionary = media_v if typeof(media_v) == TYPE_DICTIONARY else {}
		var fig := GogaPfp.make(media, Vector2(52, 52))
		fig.variant = int(s.get("pfp", 0))
		row.add_child(fig)
		var name_l := Arc.label(String(s.get("name", "PLAYER")), 24, Arc.INK)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(name_l)
		var st := String(s.get("state", ""))
		var tag := "WAITING"
		if st == "committed:" + game_id:
			tag = "READY"
		elif st.begins_with("playing:"):
			tag = "PLAYING"
		var platform := String(s.get("platform", "pc"))
		tag += "  ·  " + ("PHONE" if platform == "android" else "PC")
		if bool(s.get("ghost", false)):
			tag += "  ·  GHOST"
		row.add_child(Arc.label(tag, 18, Arc.GOOD if tag.begins_with("READY") else Color("6a4a28"), false))
		_rows_box.add_child(row)
	if holders.is_empty():
		_rows_box.add_child(Arc.label("JUST YOU SO FAR", 20, Color("6a4a28")))

func _on_match_started(gid: String, _seed_v: int, _m_seats: Array) -> void:
	if gid != game_id or _closed:
		return
	# the base routes the start to the game; the widget just steps aside
	_close(false)

func _on_left_out(gid: String) -> void:
	if gid != game_id or _closed:
		return
	_count_label.text = ""
	_clock_label.text = "THE MATCH STARTED WITHOUT YOU"
	_go_btn.visible = false
	_note_left = 1.6

func _on_solo(gid: String) -> void:
	if gid != game_id or _closed:
		return
	_count_label.text = ""
	_clock_label.text = "NOBODY JOINED - PLAYING SOLO"
	_go_btn.visible = false
	_note_left = 1.2

func _on_died(_why: String) -> void:
	_close(true)

func _close(cancel: bool) -> void:
	if _closed:
		return
	_closed = true
	queue_free()
	if cancel:
		cancelled.emit()
