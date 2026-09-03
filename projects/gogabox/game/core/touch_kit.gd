class_name TouchKit
extends Node
## Shared touch intelligence for ALL box games. Games configure thresholds and
## react to gestures; nobody re-implements swipe detection again.
##
## Usage: var tk := TouchKit.new(); add_child(tk); connect signals or call
## feed(event) from _unhandled_input.

signal tapped(pos: Vector2)
signal swiped(dir: Vector2i, pos: Vector2)
signal dragged(from: Vector2, to: Vector2)
signal press_started(pos: Vector2)
signal press_ended(pos: Vector2)

var swipe_min_px := 42.0
var tap_max_px := 14.0
var tap_max_ms := 260.0
var _press_pos := Vector2.ZERO
var _press_time := 0
var _moved := false
var _down := false
var _drag_prev := Vector2.ZERO

func feed(event: InputEvent) -> void:
        # NOTE: only ScreenTouch/ScreenDrag. project.godot emulates touch from
        # mouse, so desktop clicks arrive here too — one code path everywhere.
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                if t.pressed:
                        _down = true
                        _moved = false
                        _press_pos = t.position
                        _drag_prev = t.position
                        _press_time = Time.get_ticks_msec()
                        press_started.emit(t.position)
                else:
                        if _down:
                                var total := t.position - _press_pos
                                if not _moved and total.length() <= tap_max_px \
                                                and Time.get_ticks_msec() - _press_time <= tap_max_ms:
                                        tapped.emit(t.position)
                                press_ended.emit(t.position)
                        _down = false
        elif event is InputEventScreenDrag:
                var d := event as InputEventScreenDrag
                if _down:
                        var total := d.position - _press_pos
                        if total.length() > swipe_min_px:
                                if not _moved:
                                        _moved = true
                                        var dir := Vector2i.ZERO
                                        if absf(total.x) > absf(total.y):
                                                dir = Vector2i(1 if total.x > 0 else -1, 0)
                                        else:
                                                dir = Vector2i(0, 1 if total.y > 0 else -1)
                                        swiped.emit(dir, d.position)
                                        # the FIRST segment covers the silent
                                        # pre-threshold walk (anchor -> here)
                                        dragged.emit(_press_pos, d.position)
                                else:
                                        # v0.3.2 PATCH: the TRUE polyline segment
                                        # (prev sample -> this one). The old code
                                        # re-emitted anchor -> current chords, so a
                                        # closed loop drawn AROUND a fruit swept its
                                        # interior with invisible diagonals and the
                                        # fruit got cut without the visible slash
                                        # ever touching it (the owner's slasher bug).
                                        dragged.emit(_drag_prev, d.position)
                                _drag_prev = d.position

func is_down() -> bool:
        return _down

func press_pos() -> Vector2:
        return _press_pos

## True while a gesture started but hasn't ended (used to gate game logic).
func busy() -> bool:
        return _down
