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
## v041-1 r7 THE GRAB LAW: announced the moment a finger captures this
## scroll. The menu's arrow-key ride listens - a pending keyboard target
## must NEVER keep gliding while a finger is dragging the same list (the
## two motions used to fight; the finger always wins now).
signal grabbed

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

# ================================================== v040-11 THE CONTINUITY LAW
## THE OWNER'S GLOBAL NUKE ("i bought something, it refreshed the list and
## returned me to the top - happens everywhere, in games and in the main
## menu - eliminate it so it NEVER happens again"). Every BoxScroll carries
## an identity key. Leaving the tree writes its offset into a class-level
## ledger; the refreshed rebuild of the SAME list restores it THE SAME
## FRAME it fills its content - verified on the rig (tests/scroll_law_probe.gd):
## a same-frame restore survives the ScrollContainer's sort clamp, so there
## is no top-jump, no 2-frame dance, no flicker. Anywhere. Forever.
static var _ledger := {}          # preserve_key -> {"v": int, "h": int}

var preserve_key := ""            # set by the sheet/list builder (its id)

## drop a list's memory (a brand-new context: a search, a filter change)
static func forget(key: String) -> void:
        _ledger.erase(key)

## write the CURRENT offset under my key (called automatically on
## tree-exit; also callable right before an in-place teardown)
func remember() -> void:
        if preserve_key == "":
                return
        _ledger[preserve_key] = {"v": scroll_vertical, "h": scroll_horizontal}

## restore the remembered offset - call right AFTER the refreshed content
## is in the tree. If this scroll's layout is already live (an in-place
## content rebuild) the value sticks THIS frame; on a brand-new scroll
## node the first set clamps to 0 (the child has no size until its first
## sort) - so the want rides PENDING and re-applies on the first
## NOTIFICATION_SORT_CHILDREN, which still lands BEFORE the first draw:
## zero flash either way.
var _pending_v := -1
var _pending_h := -1
var _applying := false

func reinstate() -> void:
        if preserve_key == "" or not _ledger.has(preserve_key):
                return
        var s: Dictionary = _ledger[preserve_key]
        _pending_v = int(s["v"])
        _pending_h = int(s["h"])
        _apply_pending()

func _apply_pending() -> void:
        if _applying or _pending_v < 0:
                return
        _applying = true
        scroll_vertical = _pending_v
        scroll_horizontal = maxi(0, _pending_h)
        _applying = false
        if scroll_vertical == _pending_v:
                _pending_v = -1          # stuck this frame - no re-apply needed
                _pending_h = -1

func _notification(what: int) -> void:
        if what == NOTIFICATION_SORT_CHILDREN:
                _apply_pending()

func _exit_tree() -> void:
        remember()

# ============================================== v040-12 THE HANDOFF LAW
## THE SCROLL NUKE'S ROOT KILL. Most game shops rebuild their whole sheet
## on every buy: the old sheet's BoxScroll dies and a NEW scroll is born
## in the same frame. Keyed scrolls ride the ledger (preserve_key + the
## sheet_pop remember), but the games roll their shop scrolls BY HAND -
## keyless - so remember() wrote nothing and every buy jumped the list
## back to the top (the owner, again: "it is still as it is").
## Law: a keyless BoxScroll entering the tree ADOPTS the offset of a
## dying keyless BoxScroll in the same overlay scope (when exactly one is
## dying - two at once means nested lists, not my case). The rebuild of
## the same list continues at the same place: zero per-game keys, and the
## restore rides the PENDING machinery so it lands before the first draw
## (no top flash, no clamp-to-0).
func _ready() -> void:
        _adopt_dying_sibling()

func _adopt_dying_sibling() -> void:
        if preserve_key != "":
                return
        var scope := _overlay_scope()
        if scope == null:
                return
        var found: Array = []
        _collect_dying_keyless(scope, found)
        if found.size() != 1:
                return
        var other := found[0] as BoxScroll
        var v := other.scroll_vertical
        var h := other.scroll_horizontal
        if v <= 0 and h <= 0:
                return                      # the dead list never moved
        _pending_v = v
        _pending_h = h
        _apply_pending()

## the topmost Control ancestor whose parent is not a Control - the one
## scope every sheet/overlay of this screen lives under (same walk the
## topmost law uses)
func _overlay_scope() -> Control:
        var scope: Control = self
        var parent := scope.get_parent()
        while parent is Control:
                scope = parent
                parent = scope.get_parent()
        return scope if parent != null else null

func _collect_dying_keyless(n: Node, out: Array) -> void:
        for c in n.get_children():
                if c == self or not is_instance_valid(c):
                        continue
                if c is BoxScroll and (c as BoxScroll).preserve_key == "" \
                                and _is_dying(c):
                        out.append(c)
                _collect_dying_keyless(c, out)

## a scroll is dying when IT or any ancestor carries the deletion mark
## (the sheet teardown queues the sheet - the scroll inside dies with it)
func _is_dying(n: Node) -> bool:
        var cur := n
        while cur != null:
                if cur.is_queued_for_deletion():
                        return true
                cur = cur.get_parent()
        return false

## While a sheet/overlay covers this scroll, ALL input processing here is
## suspended so the overlay's controls (sliders, buttons) work normally.
var input_locked := false

## A scroll that lives INSIDE a game's own overlay (pause / game-over sheet).
## Those run while GameHost.active_host != null - the guard below would mute
## them, so they opt out with this flag.
var game_safe := false

## v0.3.3-p2 THE TOPMOST-CONTROL LAW (the owner's whole "back/no/hang" bug
## family): a live BoxScroll under a LATER sheet ate every raw touch aimed
## at the sheet's plain buttons - BoxScroll._input runs BEFORE the GUI stage,
## so its capture + set_input_as_handled starved the buttons above (the
## merge2048 are-you-sure NO tap that "hangs", the dario pause over the
## intro dialogue, the invaders menu backs). Law: if a VISIBLE, PROCESSING
## control that lives in a LATER sibling subtree covers this point, the
## touch is NOT MINE - I never capture it, never swallow it, never fire.
## (Verified under Xvfb: with the options scroll alive, the confirm NO click
## died; with the law, plain buttons above scrolls receive their clicks.)
func _covered_by_overlay(pos: Vector2) -> bool:
        # climb to the topmost ancestor whose parent scopes us (a CanvasLayer
        # or a non-Control) - sheets/overlays are LATER children of that scope
        var scope: Control = self
        var parent := scope.get_parent()
        while parent is Control and parent.get_parent() is Control:
                scope = parent
                parent = scope.get_parent()
        if parent == null:
                return false
        var kids := parent.get_children()
        var idx := kids.find(scope)
        for i in range(idx + 1, kids.size()):
                var n := kids[i]
                if n is Control and (n as Control).is_visible_in_tree() \
                                and (n as Control).can_process() \
                                and _blocks_at(n as Control, pos):
                        return true
        return false

## any control in this subtree whose rect owns the point and that is not
## transparent (IGNORE) - an IGNORE container can still host STOP children
func _blocks_at(c: Control, pos: Vector2) -> bool:
        if c.get_global_rect().has_point(pos) \
                        and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
                return true
        for ch in c.get_children():
                if ch is Control and (ch as Control).is_visible_in_tree() \
                                and _blocks_at(ch as Control, pos):
                        return true
        return false

## v040-3 THE CLIP LAW (the owner's battery-chip tap-through): a BoxScroll
## that rides INSIDE another scroll (the carousel strip inside the feed)
## keeps a live global rect even when the outer scroll's clip_contents has
## slid it fully under the top bar - the strip is INVISIBLE there, yet a raw
## has_point() on its rect (and on its cards' rects) handed the top-bar
## button's tap to a hidden card and the game's pre-play page opened over
## the battery chip. Reproduced on the rig: tap at the chip with the feed
## scrolled 286px -> BRICK BREAK's page opened. Law: a point only belongs to
## me if it survives EVERY clip_contents ancestor - if any such ancestor's
## rect does not contain the point, the point is clipped away and the touch
## is NOT MINE (never captured, never dispatched). Checked at capture AND at
## tap dispatch (layout may shift between down and up).
func _clipped_out(pos: Vector2) -> bool:
        var n := get_parent()
        while n != null:
                if n is Control and (n as Control).clip_contents \
                                and not (n as Control).get_global_rect() \
                                                .has_point(pos):
                        return true
                n = n.get_parent()
        return false

func _init() -> void:
        horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        follow_focus = false

## Register a control (anywhere inside the content) as tap target.
func register_tappable(ctrl: Control, cb: Callable) -> void:
        _tappables.append({"ctrl": ctrl, "cb": cb})

## v0.2.3 patch THE NESTED-SCROLL LAW: the box feed and the carousel strip
## are BOTH BoxScrolls stacked on the same screen spot. When both captured a
## touch, the DEEPER one (the strip) dispatched the release first and marked
## the event handled - the outer feed never saw the release, its captured
## index stuck, and the tap went nowhere (the owner's "when i tap a game in
## the top-picks line it does not show its pre-play menu"). Law: if another
## BoxScroll LIVES inside me and covers this point, the touch belongs to IT.
func _nested_scroll_at(pos: Vector2) -> BoxScroll:
        var stack := get_children()
        while not stack.is_empty():
                var n: Node = stack.pop_back()
                if n is BoxScroll and (n as Control).is_visible_in_tree() \
                                and (n as Control).get_global_rect() \
                                                .has_point(pos):
                        return n
                stack.append_array(n.get_children())
        return null

func _prune_tappables() -> void:
        _tappables = _tappables.filter(func(t): return is_instance_valid(t["ctrl"]))

func _hit_tappable(pos: Vector2) -> bool:
        for t in _tappables:
                var c: Control = t["ctrl"]
                if is_instance_valid(c) and c.is_visible_in_tree() \
                                and c.get_global_rect().has_point(pos):
                        # v040-4 THE ANCHOR LAW (the owner's "feed returns a
                        # little up"): a tap fired while the inertia was still
                        # gliding used to let the glide run on PAST the tap
                        # spot (the menu slept and froze it mid-motion) - the
                        # box came back a little higher than where he tapped.
                        # The tap anchors the list: motion dies HERE, the
                        # visible position at the tap IS the position the box
                        # restores to.
                        stop_motion()
                        t["cb"].call()
                        return true
        return false

## The point must sit inside EVERY clipping ancestor's rect, not just mine.
## ScrollContainer clips its content, but a CHILD scroll with
## clip_contents = false (the carousel strip) keeps a GLOBAL RECT that pokes
## above the feed's visible edge once the feed scrolls - taps aimed at the
## TOP BAR (settings / batteries / trophies) landed on that ghost rect and
## fired the invisible card underneath (the owner's "top bar buttons over
## the feed tap through to the game"). A scroll never owns a tap that a
## clipping ancestor hides.
func _visible_point(pos: Vector2) -> bool:
        var p: Node = get_parent()
        while p != null and p is Control:
                var c := p as Control
                if c.clip_contents and not c.get_global_rect().has_point(pos):
                        return false
                p = c.get_parent()
        return true

# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
        # a running game owns the whole screen: never scroll/fire tappables
        # behind it (belt & suspenders on top of menu.set_active(false) -
        # this also covers signal-driven calls that slip past process_mode).
        # game_safe scrolls (inside the game's own sheets) are exempt.
        if GameHost.active_host != null and not game_safe:
                return
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
        if get_global_rect().has_point(m.position) \
                        and not _covered_by_overlay(m.position):
                get_viewport().set_input_as_handled()

func _owns(pos: Vector2) -> bool:
        return _idx == -1 and get_global_rect().has_point(pos) \
                        and _visible_point(pos) \
                        and not _covered_by_overlay(pos)

func _touch(t: InputEventScreenTouch) -> void:
        if t.pressed:
                if _owns(t.position):
                        # the nested law: a BoxScroll INSIDE me owns this
                        # touch - I never capture it, so my index can never
                        # stick waiting for a release the inner already ate
                        if _nested_scroll_at(t.position) != null:
                                return
                        # the topmost law (v0.3.3-p2): a later overlay sheet
                        # owns this touch - see _covered_by_overlay
                        if _covered_by_overlay(t.position):
                                return
                        _idx = t.index
                        _start = t.position
                        _last = t.position
                        _last_t = Time.get_ticks_msec()
                        _vel = Vector2.ZERO
                        _dragging = false
                        grabbed.emit()
                return
        if t.index != _idx:
                return
        _idx = -1
        var dist := (t.position - _start).length()
        var ms := Time.get_ticks_msec() - _last_t
        if not _dragging:
                if dist <= TAP_PX and ms <= TAP_MS:
                        # the clip law re-checks at dispatch: a layout shift
                        # between down and up must not fire a hidden tap
                        if _clipped_out(t.position):
                                return
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
