class_name BoxScroll
extends ScrollContainer
## Touch-first scrolling for EVERY list in the Box (feed, achievements, stats).
##
## Why this exists: with mouse-emulation enabled, a touch that lands on a
## Button/Control is captured by the emulated mouse and the ScrollContainer
## never sees the drag -> "can not scroll when my finger touches a thumbnail".
## BoxScroll scrolls from RAW ScreenTouch/ScreenDrag events (which always fire,
## even over children), adds inertia, and dispatches taps itself.
##
## Children inside the scrolling area must use mouse_filter = IGNORE (tiles are
## Panels, not Buttons). Register tappables instead:
##     scroll.register_tappable(panel, callback)
## A tap = touch down/up within TAP_PX and TAP_MS that never became a drag.

signal tapped(pos: Vector2)

const TAP_PX := 16.0
const TAP_MS := 400
const START_DRAG_PX := 10.0
const FRICTION_PER_SEC := 0.0025   # velocity multiplier after 1s (strong decay)
const STOP_SPEED := 30.0           # px/s under which inertia ends

var _idx := -1                     # captured touch index (multi-touch safe)
var _start := Vector2.ZERO
var _last := Vector2.ZERO
var _last_t := 0
var _vel := Vector2.ZERO
var _dragging := false
var _tappables: Array = []         # [{ctrl: Control, cb: Callable}]

## While a sheet/overlay covers this scroll, ALL input processing here is
## suspended so the overlay's controls (sliders, buttons) work normally.
var input_locked := false

func _init() -> void:
        horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        follow_focus = false

## Register a control (anywhere inside the content) as tap target.
func register_tappable(ctrl: Control, cb: Callable) -> void:
        _tappables.append({"ctrl": ctrl, "cb": cb})

func _prune_tappables() -> void:
        _tappables = _tappables.filter(func(t): return is_instance_valid(t["ctrl"]))

func _hit_tappable(pos: Vector2) -> bool:
        for t in _tappables:
                var c: Control = t["ctrl"]
                if is_instance_valid(c) and c.is_visible_in_tree() \
                                and c.get_global_rect().has_point(pos):
                        t["cb"].call()
                        return true
        return false

# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
        if input_locked:
                return
        if event is InputEventScreenTouch:
                _touch(event as InputEventScreenTouch)
        elif event is InputEventScreenDrag:
                _drag(event as InputEventScreenDrag)
        elif event is InputEventMouseButton:
                _mouse(event as InputEventMouseButton)

## The scroll area is a pure TOUCH zone: emulated mouse events are swallowed
## so Buttons inside can never capture a press or fire after a tiny drag.
## Everything interactive inside MUST be a registered tappable.
func _mouse(m: InputEventMouseButton) -> void:
        if m.button_index != MOUSE_BUTTON_LEFT:
                return
        if get_global_rect().has_point(m.position):
                get_viewport().set_input_as_handled()

func _owns(pos: Vector2) -> bool:
        return _idx == -1 and get_global_rect().has_point(pos)

func _touch(t: InputEventScreenTouch) -> void:
        if t.pressed:
                if _owns(t.position):
                        _idx = t.index
                        _start = t.position
                        _last = t.position
                        _last_t = Time.get_ticks_msec()
                        _vel = Vector2.ZERO
                        _dragging = false
                return
        if t.index != _idx:
                return
        _idx = -1
        var dist := (t.position - _start).length()
        var ms := Time.get_ticks_msec() - _last_t
        if not _dragging:
                if dist <= TAP_PX and ms <= TAP_MS:
                        get_viewport().set_input_as_handled()
                        tapped.emit(t.position)
                        _hit_tappable(t.position)
                return
        # finger was dragging: swallow the release so no child gets a click,
        # and hand the velocity over to inertia.
        get_viewport().set_input_as_handled()

func _drag(d: InputEventScreenDrag) -> void:
        if d.index != _idx:
                return
        var total := d.position - _start
        if not _dragging:
                if total.length() < START_DRAG_PX:
                        return
                _dragging = true
                _vel = Vector2.ZERO
        var now := Time.get_ticks_msec()
        var dt := maxf(1.0, float(now - _last_t)) / 1000.0
        # instantaneous velocity (px/s), smoothed
        var inst := (d.position - _last) / dt
        _vel = _vel.lerp(inst, 0.35)
        _last = d.position
        _last_t = now
        scroll_horizontal = clampi(scroll_horizontal - int(d.relative.x), 0, 100000)
        scroll_vertical = clampi(scroll_vertical - int(d.relative.y), 0, 100000)
        get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- inertia

func _process(delta: float) -> void:
        if _idx != -1 or _vel.length() < STOP_SPEED:
                return
        var decay := pow(FRICTION_PER_SEC, delta)
        _vel *= decay
        var before := scroll_vertical
        scroll_horizontal = clampi(scroll_horizontal - int(round(_vel.x * delta)), 0, 100000)
        scroll_vertical = clampi(scroll_vertical - int(round(_vel.y * delta)), 0, 100000)
        # hit an edge -> kill that axis' velocity
        if scroll_vertical == before and absf(_vel.y) > absf(_vel.x):
                _vel.y = 0.0
        elif scroll_horizontal == before:
                _vel.x = 0.0

func stop_motion() -> void:
        _vel = Vector2.ZERO
