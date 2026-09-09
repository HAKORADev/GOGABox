extends GogaGame
## DOMINO - v0.3.8: the tile classic, reborn in the box (the SOON teaser
## "DOMINO / the tile classic" graduates).
##
## Owner contract (v0.3.8):
##   - VERTICAL only (portrait)
##   - ONE mode: the CLASSIC known dominoes (double-six draw, 2 players)
##   - TAP ANYWHERE TO START, then the deal: tiles fly alternately -
##     one to you, one to the CPU - until each holds 7 (the boneyard
##     keeps the other 14)
##   - scoring: each WIN +1, each LOSS -1 (the score never goes negative),
##     a DRAW 0; run bonus /2 (registry coin_div 2)
##   - a GOGACoin appears after each 3rd round, sitting on a LEGAL PLAYABLE
##     SPOT (one of the two chain ends) - whoever puts a domino THERE takes
##     it, the CPU races you for it
##   - NO optionals menu: skins + themes live DIRECTLY in the shop (the
##     owner: "letting it direct like other games will be better")
##   - every skin and theme except the defaults is BOUGHT
##   - input: tap a tile then tap a glowing end, OR drag the tile onto the
##     end - the dragged tile renders at BOARD scale (the hand tile is
##     bigger than the board tile), and the whole board scales down as the
##     chain grows (a scale for big grounds)
##   - highlights: the ends a selected tile fits glow green; a tile with
##     no place glows nothing and shakes; smooth fly-overs and flips
##
## THE RULES (classic draw dominoes - the owner trusts the implementation):
##   - 28 tiles, 7 each, 14 in the boneyard
##   - the holder of the HIGHEST DOUBLE opens with it; no doubles anywhere
##     = the holder of the HEAVIEST tile opens with it
##   - turns alternate; a tile must match one open end
##   - can't play: DRAW from the boneyard until you can (or it empties),
##     then PASS
##   - both pass in a row = BLOCKED: the LOWER pip total wins, a tie draws
##   - empty your hand = DOMINO! you win the round
##
## Probe contract: the whole rules core + CPU brain are STATIC -
## deck/pips/ends/can_play/cpu_pick/remember/adapt drive headless laws
## without the scene, the same contract xo.gd carries.

const P := 1                 # the player
const C := 2                 # the machine

const COIN_EVERY := 3        # owner: a GOGACoin after each 3rd round
const HAND_N := 7            # the classic deal
const MEM_ROUNDS := 2        # the xo memory law travels here

# ---------------------------------------------------------------- the shop
const SKINS := {
        "bone": {"name": "BONE", "price": 0,
                "body": Color("f2ecda"), "edge": Color("c9bfa4"),
                "pip": Color("2a2620"), "line": Color("b3a88c"),
                "desc": "the classic ivory"},
        "onyx": {"name": "ONYX", "price": 150,
                "body": Color("26232b"), "edge": Color("0f0e13"),
                "pip": Color("f0c75e"), "line": Color("4a4556"),
                "desc": "black tiles, gold pips"},
        "cherry": {"name": "CHERRY", "price": 220,
                "body": Color("a83240"), "edge": Color("6e1f2a"),
                "pip": Color("fdf6ec"), "line": Color("d0707e"),
                "desc": "the deep red set"},
        "jade": {"name": "JADE", "price": 280,
                "body": Color("2f7d5c"), "edge": Color("1d523b"),
                "pip": Color("f3efdf"), "line": Color("5aa886"),
                "desc": "green stone"},
        "royal": {"name": "ROYAL", "price": 340,
                "body": Color("2b3a67"), "edge": Color("18234a"),
                "pip": Color("f0c75e"), "line": Color("576a9e"),
                "desc": "navy and gold"},
}
const THEMES := {
        "tavern": {"name": "TAVERN", "price": 0,
                "felt": Color("2e6b46"), "rail": Color("5a3d24"),
                "line": Color(1, 1, 1, 0.06),
                "desc": "the green table"},
        "bluequilt": {"name": "BLUE QUILT", "price": 200,
                "felt": Color("2c4a7c"), "rail": Color("1c2c4a"),
                "line": Color(1, 1, 1, 0.05),
                "desc": "quilted navy felt"},
        "sunset": {"name": "SUNSET", "price": 260,
                "felt": Color("9c4a32"), "rail": Color("4a2418"),
                "line": Color(1, 1, 1, 0.05),
                "desc": "the warm red table"},
        "marble": {"name": "MIDNIGHT MARBLE", "price": 320,
                "felt": Color("22304a"), "rail": Color("101826"),
                "line": Color(1, 1, 1, 0.05),
                "desc": "cold polished stone"},
}

# ---------------------------------------------------------------- profiles
## THE FOUR MOODS (the xo law: one opponent, four moods, rotating
## invisibly). The knobs keep him beatable: real misses, real noise.
const PROFILES := {
        "heavy": {
                "miss_win": 0.08, "noise": 0.30,
                "w_pips": 2.6, "w_double": 1.2, "w_block": 1.4, "w_end": 0.4,
        },
        "keeper": {
                "miss_win": 0.10, "noise": 0.34,
                "w_pips": 1.2, "w_double": 2.0, "w_block": 1.6, "w_end": 1.0,
        },
        "blocker": {
                "miss_win": 0.12, "noise": 0.30,
                "w_pips": 1.6, "w_double": 1.0, "w_block": 2.8, "w_end": 0.7,
        },
        "racy": {
                "miss_win": 0.06, "noise": 0.40,
                "w_pips": 2.0, "w_double": 1.6, "w_block": 0.9, "w_end": 1.4,
        },
}

# ---------------------------------------------------------------- state
var state := "ready"           # ready | deal | play | cpu_wait | round_over
var opening := false           # true until the first tile lands
var clock := 0.0
var think_beat := 0.0
var deal_beat := 0.0
var deal_i := 0

var deck: Array = []           # the shuffled boneyard: [[a,b], ...]
var hand_p: Array = []         # the player's tiles [[a,b], ...]
var hand_c: Array = []         # the CPU's tiles
var chain: Array = []          # placed tiles [{a,b,fl,who}]
var turn := P
var opener_tile: Array = []    # the forced opener (highest double/heaviest)

var rounds := 0
var done_rounds := 0
var wins := 0
var losses := 0
var draws := 0

var profile_order: Array = ["heavy", "keeper", "blocker", "racy"]
var profile_i := 0
var profile := "heavy"

# the 2-round adaptive memory (the xo law)
var mem: Array = []
var cur := {}                  # {open_end, drew, result}

var pass_streak := 0           # both pass in a row = blocked
var seen_values := {}          # value -> how often it hit the table

# the coin race
var coin_side := 0             # 0 = none, 1 = left end, 2 = right end
var coin_t := 0.0

# selection / drag
var sel := -1                  # selected hand index
var drag := false
var drag_i := -1
var drag_pos := Vector2.ZERO
var shake_t := 0.0
var shake_i := -1

# layout (recomputed per draw - immediate mode)
var bw := 150.0                # board tile long side (the 1080 design law)
var hw := 200.0                # hand tile long side (the 1080 design law)
var board_rect := Rect2()
var chain_rects: Array = []    # [{rect: Rect2, vertical: bool}]
var end_l := Rect2()           # the open play slots
var end_r := Rect2()
var hand_rects: Array = []
var pile_pos := Vector2.ZERO
var cpu_pos := Vector2.ZERO

# fly animations [{tile, from, to, r0, r1, t, dur}]
var flies: Array = []
var verdict_txt := ""          # the round-over banner line
var _time := 0.0
var _rng := RandomNumberGenerator.new()

# nodes
var world: Node2D
var table_l: Node2D
var chain_l: Node2D
var hand_l: Node2D
var fx_l: Node2D
var ready_ui: Control = null
var turn_lbl: Label
var you_lbl: Label
var draw_lbl: Label
var cpu_lbl: Label
var draw_btn: Button = null    # PASS (lives only when the yard is dry)
var hand_c_lbl: Label
var pile_lbl: Label
var spread := false            # v0.3.8-1: the yard fanned out for a manual draw
var spread_rects: Array = []   # face-down rects, one per boneyard tile

# ============================================================ STATIC CORE

static func full_deck() -> Array:
        var out := []
        for a in 7:
                for b in range(a, 7):
                        out.append([a, b])
        return out

static func pips(t: Array) -> int:
        return int(t[0]) + int(t[1])

static func is_double(t: Array) -> bool:
        return int(t[0]) == int(t[1])

## the open end values of the chain ((-1,-1) when empty)
static func ends(c: Array) -> Vector2i:
        if c.is_empty():
                return Vector2i(-1, -1)
        var f: Dictionary = c[0]
        var l: Dictionary = c[c.size() - 1]
        var lv := int(f["b"]) if bool(f["fl"]) else int(f["a"])
        var rv := int(l["a"]) if bool(l["fl"]) else int(l["b"])
        return Vector2i(lv, rv)

## can this tile play? bit 1 = left, bit 2 = right
static func can_play(t: Array, lv: int, rv: int) -> int:
        var a := int(t[0])
        var b := int(t[1])
        var out := 0
        if a == lv or b == lv:
                out += 1
        if a == rv or b == rv:
                out += 2
        return out

static func playable(hand: Array, lv: int, rv: int) -> Array:
        var out := []
        for i in hand.size():
                if can_play(hand[i], lv, rv) > 0:
                        out.append(i)
        return out

## THE OPENER LAW: the highest double opens; no doubles = the heaviest tile
static func opener(hp: Array, hc: Array) -> Dictionary:
        var best := -1
        var who := 0
        var tile: Array = []
        for h in [[hp, P], [hc, C]]:
                for t in h[0]:
                        if is_double(t) and int(t[0]) > best:
                                best = int(t[0])
                                who = int(h[1])
                                tile = t
        if best >= 0:
                return {"who": who, "tile": tile}
        best = -1
        for h in [[hp, P], [hc, C]]:
                for t in h[0]:
                        if pips(t) > best:
                                best = pips(t)
                                who = int(h[1])
                                tile = t
        return {"who": who, "tile": tile}

## THE MEMORY LAW (the xo 2-round window)
static func remember(mem_in: Array, record: Dictionary) -> Array:
        var m := mem_in.duplicate()
        m.append({
                "open_end": int(record.get("open_end", 0)),
                "drew": int(record.get("drew", 0)),
                "result": int(record.get("result", 0)),
        })
        while m.size() > MEM_ROUNDS:
                m.pop_front()
        return m

## WHAT THE MEMORY TEACHES: a player who keeps feeding ONE side meets a
## CPU that seals that side; a thirsty player (heavy drawer) meets a CPU
## that dumps its weight faster.
static func adapt(mem_in: Array) -> Dictionary:
        var out := {"side_lock": 0, "thirsty": false}
        if mem_in.is_empty():
                return out
        for e in mem_in:
                if int(e["drew"]) >= 3:
                        out["thirsty"] = true
        if mem_in.size() >= 2:
                var a: int = int(mem_in[0]["open_end"])
                var b: int = int(mem_in[1]["open_end"])
                if a != 0 and a == b:
                        out["side_lock"] = a
        return out

## THE CPU PIPELINE (honest: hidden info stays hidden - the brain reads
## only its own hand, the chain, the public value counts):
##   1. the round win is RIGHT THERE (the last tile) - a rare miss
##   2. score every playable tile: dump weight (pips), doubles early,
##      the block weight (seal values the table already swallowed),
##      the side the player keeps feeding (adapt), a little noise
##   3. the best score wins, ties roll
static func cpu_pick(hand: Array, lv: int, rv: int, profile_id: String,
                chain_in: Array, seen: Dictionary, flags: Dictionary,
                rng: RandomNumberGenerator) -> int:
        var opts := playable(hand, lv, rv)
        if opts.is_empty():
                return -1
        if opts.size() == 1:
                return int(opts[0])
        var p: Dictionary = PROFILES[profile_id]
        # 1. the win
        if hand.size() == 1 and rng.randf() >= float(p["miss_win"]):
                return int(opts[0])
        # 2. the feel
        var chain_n := chain_in.size()
        var best := -INF
        var picks: Array = []
        for i in opts:
                var t: Array = hand[i]
                var s := 0.0
                s += float(p["w_pips"]) * float(pips(t)) * 0.30
                if is_double(t):
                        s += float(p["w_double"]) * (2.4 - minf(2.0,
                                chain_n * 0.14))
                # the touching value stays on the table; the OTHER one is
                # what the chain will demand next - sealing it starves the
                # player of answers
                var touch_lv := int(t[0]) == lv or int(t[1]) == lv
                var touch_rv := int(t[0]) == rv or int(t[1]) == rv
                var v_other := -1
                if touch_lv and not touch_rv:
                        v_other = int(t[0]) if int(t[1]) == lv else int(t[1])
                elif touch_rv and not touch_lv:
                        v_other = int(t[0]) if int(t[1]) == rv else int(t[1])
                if v_other >= 0:
                        s += float(p["w_block"]) * float(seen.get(v_other, 0)) \
                                * 0.5
                # the adapt: seal the side the player keeps feeding
                var sl := int(flags["side_lock"])
                if sl != 0:
                        var wants_left := int(t[0]) == lv or int(t[1]) == lv
                        if (sl < 0) == wants_left:
                                s += 1.1
                # the thirsty law: the player drew a lot - dump heavy faster
                if bool(flags["thirsty"]):
                        s += float(p["w_pips"]) * 0.12
                # keep both colors alive early (the keeper law)
                if chain_n < 6 and not is_double(t):
                        s += float(p["w_end"]) * 0.35
                s += rng.randf() * float(p["noise"])
                if s > best + 0.0001:
                        best = s
                        picks = [i]
                elif absf(s - best) <= 0.0001:
                        picks.append(i)
        return int(picks[rng.randi() % picks.size()])

static func profile_next(i: int) -> Array:
        return [PROFILES.keys()[i % PROFILES.size()], i + 1]

# ============================================================ the scene

func _goga_setup() -> void:
        _rng.randomize()
        pause_end_run = true    # THE XO/PONG DESIGN: the pause sheet's END
                                # is the only bank
        var vp := get_viewport_rect().size
        world = Node2D.new()
        add_child(world)
        table_l = Node2D.new()
        table_l.draw.connect(_draw_table)
        table_l.z_index = -5
        world.add_child(table_l)
        chain_l = Node2D.new()
        chain_l.draw.connect(_draw_chain)
        world.add_child(chain_l)
        hand_l = Node2D.new()
        hand_l.draw.connect(_draw_hand)
        world.add_child(hand_l)
        fx_l = Node2D.new()
        fx_l.draw.connect(_draw_fx)
        fx_l.z_index = 6
        world.add_child(fx_l)
        _build_widgets(vp)
        _load_meta()
        add_hud_button("SHOP", func(): _shop_open())
        _build_ready()
        _relayout()
        _new_round()
        # THE TOAST SEAT LAW (v0.3.8): the shared toast seat (-180..-120
        # off the bottom) paints straight over the dealt hand fan - the
        # rig caught THE CPU HOLDS THE OPENER printed across the fresh
        # tiles. Domino re-seats the SAME one overlay (the newest-wins
        # law untouched) onto the felt just above the hand.
        if _toast.has("label") and is_instance_valid(_toast["label"]):
                var tl: Label = _toast["label"]
                var seat := banner_bottom() + hw * 2.1
                tl.offset_top = -seat - 66.0
                tl.offset_bottom = -seat

func _skin() -> Dictionary:
        var sid := Box.skin_on(game_id)
        if not SKINS.has(sid):
                sid = "bone"
        return SKINS[sid]

func _theme() -> Dictionary:
        var tid := Box.item_on(game_id, "theme")
        if not THEMES.has(tid):
                tid = "tavern"
        return THEMES[tid]

func _load_meta() -> void:
        _skin()
        _theme()

func _build_ready() -> void:
        var vp := get_viewport_rect().size
        ready_ui = Control.new()
        ready_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        ready_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hud.add_child(ready_ui)
        var l := Arc.label("TAP ANYWHERE TO START", 50, Color(1, 1, 1, 0.95))
        l.set_anchors_preset(Control.PRESET_TOP_WIDE)
        l.offset_top = vp.y * 0.40
        l.offset_bottom = vp.y * 0.40 + 76.0
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        ready_ui.add_child(l)
        var tw := l.create_tween().set_loops()
        tw.tween_property(l, "modulate:a", 0.55, 0.9) \
                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        tw.tween_property(l, "modulate:a", 1.0, 0.9) \
                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _build_widgets(vp: Vector2) -> void:
        # v0.3.8-1 THE OWNER'S SEAT: the score leaves the middle of the top
        # bar for the RIGHT side - a compact vertical stack (YOU / DRAWS /
        # CPU), the domino mirror of the chess strip
        var widget := Node2D.new()
        widget.position = Vector2(vp.x - 76.0, 186.0)
        widget.draw.connect(func():
                var bwid := 124.0
                var bh := 58.0
                var gapw := 12.0
                var ys := [-(bh + gapw) - bh * 0.5, -bh * 0.5,
                        (bh + gapw) - bh * 0.5]
                var cols := [Color("58c470"), Color("6b7280"), Color("e8574a")]
                for i in 3:
                        var r := Rect2(-bwid * 0.5, ys[i], bwid, bh)
                        widget.draw_rect(Rect2(r.position + Vector2(4, 4),
                                r.size), Color(0.09, 0.05, 0.02, 0.85))
                        widget.draw_rect(r, Color(1, 1, 1, 0.95))
                        widget.draw_rect(r, cols[i], false, 4.0))
        world.add_child(widget)
        you_lbl = Arc.label("YOU 0", 24, Color("2f7a44"))
        draw_lbl = Arc.label("DRAWS 0", 24, Color("4b5563"))
        cpu_lbl = Arc.label("CPU 0", 24, Color("9c3a32"))
        for l in [you_lbl, draw_lbl, cpu_lbl]:
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                world.add_child(l)
        _refresh_widget()
        turn_lbl = Arc.label("", 28, Color(1, 1, 1, 0.92))
        turn_lbl.position = Vector2(0, 242)
        turn_lbl.custom_minimum_size = Vector2(vp.x, 38)
        turn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        world.add_child(turn_lbl)
        pile_lbl = Arc.label("", 20, Color(1, 1, 1, 0.7))
        world.add_child(pile_lbl)
        hand_c_lbl = Arc.label("", 20, Color(1, 1, 1, 0.7))
        world.add_child(hand_c_lbl)

func _refresh_widget() -> void:
        var vp := get_viewport_rect().size
        var w := 124.0
        var bh := 58.0
        var gapw := 12.0
        var ys := [-(bh + gapw) - bh * 0.5, -bh * 0.5, (bh + gapw) - bh * 0.5]
        var labels := [you_lbl, draw_lbl, cpu_lbl]
        var texts := ["YOU %d" % wins, "DRAWS %d" % draws, "CPU %d" % losses]
        for i in 3:
                var v: Label = labels[i]
                v.text = texts[i]
                v.position = Vector2(vp.x - 76.0 - w * 0.5,
                        186.0 + ys[i] + 14.0)
                v.custom_minimum_size = Vector2(w, bh - 20.0)

# ============================================================ the layout
## Recomputed every draw - the chain snake wraps in rows, the board scale
## steps DOWN as the chain grows (the owner's "a scale for big grounds").

func _board_scale() -> float:
        if chain.size() <= 12:
                return 1.0
        if chain.size() <= 18:
                return 0.85
        if chain.size() <= 24:
                return 0.72
        return 0.6

func _relayout() -> void:
        var vp := get_viewport_rect().size
        # v0.3.8-1 THE GROUND LAW: the score strip moved to the RIGHT cut
        # and the CPU hand row lives top-center - the ground starts just
        # under it and runs to the hand fan, much taller than before.
        var top := 236.0
        var bot := vp.y - banner_bottom() - hw - 78.0
        board_rect = Rect2(18.0, top, vp.x - 36.0, maxf(200.0, bot - top))
        bw = 150.0 * _board_scale()
        chain_rects = []
        # the resting yard: a neat stack on the ground's LEFT edge, mid-height
        pile_pos = Vector2(board_rect.position.x + 46.0,
                board_rect.position.y + board_rect.size.y * 0.5)
        # the CPU hand: top-center of the ground (the mirror of the owner's
        # fan - see _draw_cpu_hand)
        cpu_pos = Vector2(vp.x * 0.5, 140.0)
        if chain.is_empty():
                end_l = Rect2()
                end_r = Rect2()
        else:
                var th := bw * 0.5
                var gap := 3.0
                # v0.3.8-1 THE CENTER LAW: the snake starts at the CENTER of
                # the ground (the old start hugged the top edge - "this is
                # not a real game", the owner)
                var cursor := Vector2(board_rect.position.x
                        + board_rect.size.x * 0.5,
                        board_rect.position.y + board_rect.size.y * 0.5)
                var dir := 1
                var margin_r := board_rect.position.x + board_rect.size.x - 44.0
                var margin_l := board_rect.position.x + 44.0
                var rects: Array = []
                for i in chain.size():
                        var t: Dictionary = chain[i]
                        var dbl: bool = int(t["a"]) == int(t["b"])
                        var size := Vector2(th, bw) if dbl else Vector2(bw, th)
                        var vertical := dbl
                        if not vertical:
                                if dir > 0 and cursor.x + size.x * 0.5 > margin_r \
                                                and i > 0:
                                        vertical = true
                                        size = Vector2(th, bw)
                                elif dir < 0 and cursor.x - size.x * 0.5 < margin_l \
                                                and i > 0:
                                        vertical = true
                                        size = Vector2(th, bw)
                        var r := Rect2(Vector2(cursor.x - size.x * 0.5,
                                cursor.y - size.y * 0.5), size)
                        rects.append({"rect": r, "vertical": vertical})
                        if vertical and i > 0:
                                # the elbow: step past it, drop a row, flip
                                cursor.x += dir * (th + gap + bw * 0.5)
                                cursor.y += bw * 0.5 + 14.0
                                dir = -dir
                        else:
                                cursor.x += dir * (size.x + gap)
                chain_rects = rects
                var lr: Rect2 = rects[0]["rect"]
                var rr: Rect2 = rects[rects.size() - 1]["rect"]
                end_l = Rect2(lr.position.x - bw - 6.0, lr.position.y
                        + (lr.size.y - bw * 0.5) * 0.5, bw, bw * 0.5) \
                        if lr.position.x - bw - 6.0 > margin_l - 14.0 else Rect2()
                end_r = Rect2(rr.position.x + rr.size.x + 6.0, rr.position.y
                        + (rr.size.y - bw * 0.5) * 0.5, bw, bw * 0.5) \
                        if rr.position.x + rr.size.x + 6.0 < margin_r + 14.0 \
                        else Rect2()
        # the hand fan
        hand_rects = []
        var n := hand_p.size()
        if n > 0:
                var tw2 := hw * 0.5
                var overlap := 0.0
                var maxw := vp.x - 48.0
                var total := tw2 * n
                if total > maxw:
                        overlap = (total - maxw) / float(n - 1)
                var x0 := (vp.x - (total - overlap * (n - 1))) * 0.5
                var hy := vp.y - banner_bottom() - hw - 44.0
                for i in n:
                        hand_rects.append(Rect2(Vector2(
                                x0 + i * (tw2 - overlap), hy),
                                Vector2(tw2, hw)))
        # v0.3.8-1 THE YARD SPREAD: when the player must draw, the boneyard
        # fans out face-down across the ground's middle - one rect per tile
        spread_rects = []
        if spread and deck.size() > 0:
                var sw := bw * 0.52
                var sh := bw * 0.92
                var cnt := deck.size()
                var gapw := 6.0
                var row_w := cnt * sw + (cnt - 1) * gapw
                var maxw2 := board_rect.size.x - 40.0
                var step := sw + gapw
                if row_w > maxw2:
                        step = (maxw2 - sw) / float(cnt - 1)
                var sx := board_rect.get_center().x - (step * (cnt - 1) + sw) * 0.5
                var sy := board_rect.get_center().y - sh * 0.5
                for i in cnt:
                        spread_rects.append(Rect2(Vector2(
                                sx + i * step, sy), Vector2(sw, sh)))

# ============================================================ the drawing

func _draw_table() -> void:
        var t := _theme()
        var vp := get_viewport_rect().size
        table_l.draw_rect(Rect2(Vector2.ZERO, vp), t["felt"])
        # the felt pattern: a soft diamond quilt (deterministic)
        var step := 64.0
        var k := 0
        var y := -step
        while y < vp.y + step:
                var x := -step
                var off := (step * 0.5) if k % 2 == 0 else 0.0
                while x < vp.x + step:
                        table_l.draw_line(Vector2(x + off, y),
                                Vector2(x + off + step * 0.5, y + step * 0.5),
                                t["line"], 2.0)
                        table_l.draw_line(Vector2(x + off + step, y),
                                Vector2(x + off + step * 0.5, y + step * 0.5),
                                t["line"], 2.0)
                        x += step
                y += step * 0.5
                k += 1
        # the rail frame around the board area
        var r := board_rect.grow(12.0)
        table_l.draw_rect(r, t["rail"], false, 10.0)
        table_l.draw_rect(r.grow(4.0), Color(0, 0, 0, 0.25), false, 4.0)
        _draw_pile()
        _draw_cpu_hand()

func _draw_tile_body(onto: Node2D, r: Rect2, a: int, b: int, vertical: bool,
                sel_glow := 0.0) -> void:
        ## a GOGABox domino: rounded-ish body, the divider bar, honest pips
        var s := _skin()
        var body: Color = s["body"]
        var edge: Color = s["edge"]
        var pip: Color = s["pip"]
        var line: Color = s["line"]
        if sel_glow > 0.0:
                onto.draw_rect(r.grow(5.0),
                        Color(1.0, 0.9, 0.4, 0.40 * sel_glow), false, 4.0)
        onto.draw_rect(r.grow(2.0), Color(0, 0, 0, 0.30))
        onto.draw_rect(r, edge)
        var inner := r.grow(-3.0)
        onto.draw_rect(inner, body)
        onto.draw_rect(inner.grow(-4.0),
                Color(1, 1, 1, 0.10 if body.v > 0.4 else 0.05))
        var mid := r.get_center()
        if vertical:
                onto.draw_line(Vector2(r.position.x + 6.0, mid.y),
                        Vector2(r.end.x - 6.0, mid.y), line, 3.0)
        else:
                onto.draw_line(Vector2(mid.x, r.position.y + 6.0),
                        Vector2(mid.x, r.end.y - 6.0), line, 3.0)
        # v0.3.8-1 THE PIP TRUTH: a domino half is a SQUARE (the long side
        # is exactly 2x the short one). The old spread read the long side on
        # BOTH axes, so the narrow axis overflowed - the dots sat on the
        # edge or outside the body. Each axis now reads its own extent.
        var hx: float = (r.size.x * 0.5 if vertical else r.size.x * 0.25) * 0.72
        var hy: float = (r.size.y * 0.25 if vertical else r.size.y * 0.5) * 0.72
        var rad := maxf(2.6, minf(r.size.x, r.size.y) * 0.105)
        for half in 2:
                var v := a if half == 0 else b
                var c0: Vector2
                if vertical:
                        c0 = Vector2(r.position.x + r.size.x * 0.5,
                                r.position.y + r.size.y * (0.25 + 0.5 * half))
                else:
                        c0 = Vector2(r.position.x + r.size.x * (0.25 + 0.5 * half),
                                r.position.y + r.size.y * 0.5)
                for pp in _pip_spots(v):
                        var off := Vector2(pp[0] * hx, pp[1] * hy)
                        if not vertical:
                                off = Vector2(pp[1] * hx, pp[0] * hy)
                        onto.draw_circle(c0 + off, rad, pip)

## the classic pip grid: positions in half-halfspace units
static func _pip_spots(v: int) -> Array:
        match v:
                0: return []
                1: return [[0.0, 0.0]]
                2: return [[-1.0, -1.0], [1.0, 1.0]]
                3: return [[-1.0, -1.0], [0.0, 0.0], [1.0, 1.0]]
                4: return [[-1.0, -1.0], [1.0, -1.0], [-1.0, 1.0], [1.0, 1.0]]
                5: return [[-1.0, -1.0], [1.0, -1.0], [0.0, 0.0],
                                [-1.0, 1.0], [1.0, 1.0]]
                6: return [[-1.0, -1.0], [1.0, -1.0], [-1.0, 0.0],
                                [1.0, 0.0], [-1.0, 1.0], [1.0, 1.0]]
        return []

func _draw_chain() -> void:
        # the open-end slots first (under the tiles)
        var can_l := false
        var can_r := false
        if opening and turn == P:
                pass  # the opener tile itself glows in the hand
        elif sel >= 0 and sel < hand_p.size() and not chain.is_empty():
                var e := ends(chain)
                var cp := can_play(hand_p[sel], e.x, e.y)
                can_l = (cp & 1) != 0
                can_r = (cp & 2) != 0
        var pulse := 0.5 + 0.5 * sin(_time * 4.2)
        if end_l.size.x > 0.0:
                var col: Color = Color(0.35, 0.9, 0.5, 0.30 + 0.25 * pulse) \
                        if can_l else Color(1, 1, 1, 0.10)
                chain_l.draw_rect(end_l.grow(-2.0), col, false, 3.0, true)
                if can_l:
                        chain_l.draw_rect(end_l.grow(-8.0),
                                Color(0.35, 0.9, 0.5, 0.10 + 0.08 * pulse))
        if end_r.size.x > 0.0:
                var col2: Color = Color(0.35, 0.9, 0.5, 0.30 + 0.25 * pulse) \
                        if can_r else Color(1, 1, 1, 0.10)
                chain_l.draw_rect(end_r.grow(-2.0), col2, false, 3.0, true)
                if can_r:
                        chain_l.draw_rect(end_r.grow(-8.0),
                                Color(0.35, 0.9, 0.5, 0.10 + 0.08 * pulse))
        # the chain
        for i in chain.size():
                var info: Dictionary = chain_rects[i]
                var t: Dictionary = chain[i]
                var a := int(t["a"])
                var b := int(t["b"])
                if bool(t["fl"]):
                        var tmp := a
                        a = b
                        b = tmp
                _draw_tile_body(chain_l, info["rect"], a, b,
                        bool(info["vertical"]))
        # the flying tiles ride above
        for f in flies:
                var ft: Array = f["tile"]
                var k: float = clampf(float(f["t"]) / float(f["dur"]), 0.0, 1.0)
                var ease := 1.0 - pow(1.0 - k, 3.0)
                var at: Vector2 = (f["from"] as Vector2).lerp(
                        f["to"] as Vector2, ease)
                var sz := Vector2(bw, bw * 0.5)
                chain_l.draw_set_transform(at, 0.0, Vector2.ONE)
                if bool(f.get("back", false)):
                        _draw_tile_back(chain_l, Rect2(-sz * 0.5, sz))
                else:
                        _draw_tile_body(chain_l, Rect2(-sz * 0.5, sz),
                                int(ft[0]), int(ft[1]), true)
                chain_l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_hand() -> void:
        var e := ends(chain)
        for i in hand_p.size():
                var r: Rect2 = hand_rects[i]
                var t: Array = hand_p[i]
                var glow := 0.0
                if sel == i:
                        glow = 1.0
                if opening and turn == P and _is_opener(i):
                        glow = 0.5 + 0.5 * sin(_time * 5.0)
                var lift := -10.0 if sel == i else 0.0
                var rr := Rect2(r.position + Vector2(0, lift), r.size)
                if shake_i == i and shake_t > 0.0:
                        rr.position.x += sin(shake_t * 60.0) * 4.0
                if drag_i == i and drag:
                        continue
                _draw_tile_body(hand_l, rr, int(t[0]), int(t[1]), true, glow)
                if turn == P and state == "play" and sel < 0 and not opening \
                                and can_play(t, e.x, e.y) > 0:
                        hand_l.draw_rect(rr.grow(2.0), Color(1, 1, 1, 0.18),
                                false, 2.5, true)

func _draw_fx() -> void:
        # the dragged tile renders at BOARD scale under the finger (the
        # owner's scale law)
        if drag and drag_i >= 0 and drag_i < hand_p.size():
                var t: Array = hand_p[drag_i]
                var sz := Vector2(bw, bw * 0.5)
                var at := drag_pos - Vector2(0, bw * 0.62)
                var r := Rect2(at - sz * 0.5, sz)
                fx_l.draw_rect(r.grow(5.0), Color(0, 0, 0, 0.35))
                _draw_tile_body(fx_l, r, int(t[0]), int(t[1]), true, 1.0)
        # v0.3.8-1: the spread fan lives above the felt
        _draw_spread()
        # the coin, bobbing on its end slot
        if coin_side != 0:
                var slot := end_l if coin_side == 1 else end_r
                if slot.size.x > 0.0:
                        var tex: Texture2D = load("res://assets/ui/coin.png")
                        if tex != null:
                                var pos := slot.get_center()
                                pos.y += sin(coin_t * 3.4) * 5.0
                                var s := slot.size.y * 0.5 \
                                        / float(tex.get_width())
                                var fade: float = clampf(coin_t / 0.4, 0.0, 1.0)
                                var dst := pos - Vector2(tex.get_width(),
                                        tex.get_height()) * s * 0.5
                                fx_l.draw_texture_rect(tex, Rect2(dst,
                                        Vector2(tex.get_width(),
                                        tex.get_height()) * s),
                                        false, Color(1, 1, 1, fade))
                                var ga := coin_t * 2.6
                                fx_l.draw_arc(pos, slot.size.y * 0.40,
                                        ga, ga + 1.2, 26,
                                        Color(1, 1, 1, 0.5 * fade), 2.2)

func _draw_pile() -> void:
        var n := deck.size()
        if spread:
                # the fan IS the yard now - the resting stack steps aside
                pile_lbl.text = ""
                return
        if n <= 0:
                pile_lbl.text = "THE YARD IS DRY"
                pile_lbl.position = pile_pos + Vector2(-70.0, -14.0)
                pile_lbl.custom_minimum_size = Vector2(160.0, 24)
                return
        # a taller honest stack: up to 6 backs with real depth
        var s := Vector2(bw * 0.44, bw * 0.88)
        for k in mini(6, n):
                var r := Rect2(pile_pos - s * 0.5
                        + Vector2(k * 2.5, -k * 4.0), s)
                _draw_tile_back(table_l, r)
        pile_lbl.text = "BONEYARD %d" % n
        pile_lbl.position = pile_pos + Vector2(-70.0, s.y * 0.5 + 12.0)
        pile_lbl.custom_minimum_size = Vector2(160.0, 24)

## the spread fan (fx layer): the face-down yard the user picks from
func _draw_spread() -> void:
        if not spread or spread_rects.is_empty():
                return
        var pulse := 0.5 + 0.5 * sin(_time * 4.0)
        for i in spread_rects.size():
                var r: Rect2 = spread_rects[i]
                _draw_tile_back(fx_l, r)
                fx_l.draw_rect(r.grow(-1.0),
                        Color(1, 1, 1, 0.05 + 0.05 * pulse), false, 2.0)
        var hint := "TAP A TILE TO DRAW"
        var f := ThemeDB.fallback_font
        fx_l.draw_string(f, Vector2(
                board_rect.get_center().x - 130.0,
                spread_rects[0].position.y - 18.0 + 8.0),
                hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 26,
                Color(1, 1, 1, 0.55 + 0.3 * pulse))

func _draw_cpu_hand() -> void:
        # v0.3.8-1 THE MIRROR LAW: the CPU's fan is set the SAME way as the
        # owner's (a centered row of vertical tiles), riding top-center -
        # the old right-edge mini-slabs made no sense. The tiles show their
        # BACKS: the numbers stay secret.
        var n := hand_c.size()
        if n <= 0:
                hand_c_lbl.text = ""
                return
        var tw := hw * 0.36
        var th := hw * 0.7
        var overlap := 0.0
        var maxw := get_viewport_rect().size.x - 56.0
        var total := tw * n
        if total > maxw:
                overlap = (total - maxw) / float(n - 1)
        var x0 := cpu_pos.x - (total - overlap * (n - 1)) * 0.5
        for k in n:
                var r := Rect2(Vector2(x0 + k * (tw - overlap),
                        cpu_pos.y - th * 0.5), Vector2(tw, th))
                _draw_tile_back(table_l, r)
        hand_c_lbl.text = "CPU - %d" % n
        hand_c_lbl.add_theme_font_size_override("font_size", 22)
        hand_c_lbl.position = Vector2(cpu_pos.x - 80.0,
                cpu_pos.y + th * 0.5 + 4.0)
        hand_c_lbl.custom_minimum_size = Vector2(160.0, 26)

## v0.3.8-1 THE BACK: the tile's reverse - the skin's dark body, a neat
## edge, and the house spinner motif dead center. No pips, no leaks.
func _draw_tile_back(onto: Node2D, r: Rect2) -> void:
        var s := _skin()
        onto.draw_rect(r.grow(2.0), Color(0, 0, 0, 0.30))
        onto.draw_rect(r, s["edge"].darkened(0.45))
        var inner := r.grow(-3.0)
        onto.draw_rect(inner, s["body"].darkened(0.55))
        onto.draw_rect(inner.grow(-4.0), Color(1, 1, 1, 0.06))
        var c := r.get_center()
        var u := minf(r.size.x, r.size.y) * 0.5
        onto.draw_circle(c, u * 0.30, s["edge"].darkened(0.3))
        onto.draw_circle(c, u * 0.16, s["pip"].darkened(0.2))
        for k in 4:
                var ang := k * PI * 0.5 + PI * 0.25
                var d := c + Vector2(cos(ang), sin(ang)) * u * 0.46
                onto.draw_circle(d, u * 0.07, Color(1, 1, 1, 0.30))

# ============================================================ the input

func _goga_input(event: InputEvent) -> void:
        if sheet_open_count() > 0:
                return
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                if t.pressed:
                        if state == "ready":
                                state = "deal"
                                if ready_ui != null:
                                        ready_ui.queue_free()
                                        ready_ui = null
                                Jukebox.sfx("d_draw", -4.0, 1.1)
                                return
                        _press(t.position)
                else:
                        _release(t.position)
        elif event is InputEventScreenDrag and drag:
                drag_pos = event.position

func _press(at: Vector2) -> void:
        if state != "play" or turn != P:
                return
        # v0.3.8-1 THE YARD PICK: the fan is up - a tap on a face-down tile
        # takes THAT tile (the honest manual draw, the owner's design)
        if spread:
                for i in spread_rects.size():
                        if spread_rects[i].grow(6.0).has_point(at):
                                _player_take(i)
                                return
                return
        # the opener: the glowing tile opens on touch
        if opening:
                for i in hand_p.size():
                        if hand_rects[i].has_point(at) and _is_opener(i):
                                _place(P, i, 2)
                                return
                return
        # a hand tile?
        for i in hand_p.size():
                if hand_rects[i].has_point(at):
                        if sel == i:
                                # the double-tap law: a second tap on the
                                # selected tile plays it if only ONE end fits
                                var e := ends(chain)
                                var cp := can_play(hand_p[i], e.x, e.y)
                                if cp == 1:
                                        _place(P, i, 1)
                                elif cp == 2:
                                        _place(P, i, 2)
                                else:
                                        drag_i = i
                                        drag = true
                                        drag_pos = at
                                        Jukebox.sfx("d_pick", -8.0)
                        else:
                                sel = i
                                drag_i = i
                                drag = true
                                drag_pos = at
                                Jukebox.sfx("d_pick", -6.0,
                                        1.0 + _rng.randf() * 0.05)
                        hand_l.queue_redraw()
                        chain_l.queue_redraw()
                        return
        # an end slot?
        if sel >= 0:
                if end_l.size.x > 0.0 and end_l.grow(10.0).has_point(at):
                        _player_play(1)
                        return
                if end_r.size.x > 0.0 and end_r.grow(10.0).has_point(at):
                        _player_play(2)
                        return
                var e2 := ends(chain)
                var cp2 := can_play(hand_p[sel], e2.x, e2.y)
                if cp2 == 1 or cp2 == 2:
                        # tap anywhere on the felt: the single fitting end
                        # plays (the tap-tap-anywhere comfort law)
                        if board_rect.has_point(at):
                                _player_play(1 if cp2 == 1 else 2)
                                return
        sel = -1
        hand_l.queue_redraw()
        chain_l.queue_redraw()

func _release(_at: Vector2) -> void:
        if drag and drag_i >= 0 and sel == drag_i:
                var dropped := false
                var e := ends(chain)
                var cp := can_play(hand_p[drag_i], e.x, e.y)
                var drop_at := drag_pos - Vector2(0, bw * 0.62)
                if end_l.size.x > 0.0 and end_l.grow(14.0).has_point(drop_at) \
                                and (cp & 1) != 0:
                        _player_play(1)
                        dropped = true
                elif end_r.size.x > 0.0 and end_r.grow(14.0).has_point(drop_at) \
                                and (cp & 2) != 0:
                        _player_play(2)
                        dropped = true
                drag = false
                drag_i = -1
                if not dropped:
                        hand_l.queue_redraw()
                        fx_l.queue_redraw()

func _player_play(side: int) -> void:
        if state != "play" or turn != P or sel < 0:
                return
        if opening:
                return
        var e := ends(chain)
        var cp := can_play(hand_p[sel], e.x, e.y)
        if side == 1 and (cp & 1) == 0:
                _deny()
                return
        if side == 2 and (cp & 2) == 0:
                _deny()
                return
        _place(P, sel, side)
        sel = -1

func _deny() -> void:
        shake_i = sel
        shake_t = 0.24
        Jukebox.sfx("c_illegal", -10.0)

func _is_opener(i: int) -> bool:
        if opener_tile.is_empty() or i >= hand_p.size():
                return false
        return int(hand_p[i][0]) == int(opener_tile[0]) \
                and int(hand_p[i][1]) == int(opener_tile[1])

# ============================================================ the moves

## THE PLACEMENT: who plays hand[hi] on side (1 left / 2 right)
func _place(who: int, hi: int, side: int) -> void:
        var hand: Array = hand_p if who == P else hand_c
        var t: Array = hand[hi]
        var e := ends(chain)
        var fl := false
        if side == 1:
                # the tile's touching half must show the left end
                var lv := e.x
                if int(t[0]) == lv and int(t[1]) != lv:
                        fl = true     # [b|a] puts a (== lv) on the right
                elif int(t[1]) == lv and int(t[0]) != lv:
                        fl = false    # [a|b] puts b (== lv) on the right
                else:
                        fl = false    # doubles / both-match: any way stands
                chain.push_front({"a": int(t[0]), "b": int(t[1]),
                        "fl": fl, "who": who})
        else:
                var rv := e.y
                if int(t[1]) == rv and int(t[0]) != rv:
                        fl = true     # [b|a] puts b (== rv) on the left
                else:
                        fl = false
                chain.append({"a": int(t[0]), "b": int(t[1]),
                        "fl": fl, "who": who})
        # the coin spot in WORLD space, captured BEFORE the reflow
        var coin_pos := Vector2.ZERO
        var coin_live := coin_side != 0
        if coin_live:
                var slot := end_l if coin_side == 1 else end_r
                coin_pos = slot.get_center() if slot.size.x > 0.0 \
                        else Vector2.ZERO
                if coin_pos == Vector2.ZERO:
                        coin_live = false
        # the fly source, captured BEFORE the hand shrinks
        var from: Vector2 = cpu_pos if who == C else (hand_rects[hi].get_center()
                if hi < hand_rects.size() else Vector2(
                get_viewport_rect().size.x * 0.5,
                get_viewport_rect().size.y - hw))
        hand.remove_at(hi)
        seen_values[int(t[0])] = int(seen_values.get(int(t[0]), 0)) + 1
        seen_values[int(t[1])] = int(seen_values.get(int(t[1]), 0)) + 1
        pass_streak = 0
        opening = false
        _relayout()
        var to: Vector2
        var ir: Dictionary
        if chain.size() == 1:
                ir = chain_rects[0]
        else:
                ir = chain_rects[0] if side == 1 \
                        else chain_rects[chain_rects.size() - 1]
        to = (ir["rect"] as Rect2).get_center()
        flies.append({"tile": t, "from": from, "to": to,
                "r0": 0.0, "r1": 0.0, "t": 0.0, "dur": 0.24})
        Jukebox.sfx("d_place", -4.0, 0.96 + _rng.randf() * 0.08)
        # THE COIN RACE: the tile that lands on the coin spot takes it
        if coin_live and (ir["rect"] as Rect2).has_point(coin_pos):
                _coin_taken(who)
        _after_move(who)

func _coin_taken(who: int) -> void:
        coin_side = 0
        if who == P:
                add_run_coins(1)
                Jukebox.sfx("d_coin", -3.0)
                game_toast("YOU TOOK THE GOGACOIN  +1")
                achievement_count("coins_taken", 1)
        else:
                Jukebox.sfx("coin", -6.0, 0.8)
                game_toast("THE CPU GRABBED THE COIN")

func _after_move(who: int) -> void:
        if hand_p.is_empty() or hand_c.is_empty():
                _resolve("win" if hand_p.is_empty() else "lose", false)
                return
        turn = C if who == P else P
        clock = 0.0
        if turn == P:
                state = "play"
                _banner()
                _sync_draw_btn()
        else:
                state = "cpu_wait"
                think_beat = _rng.randf_range(0.55, 0.95)
                _banner()
        chain_l.queue_redraw()
        hand_l.queue_redraw()

func _banner() -> void:
        if state == "round_over":
                return
        if turn == P:
                turn_lbl.text = "YOUR MOVE"
                turn_lbl.add_theme_color_override("font_color",
                        Color(0.45, 0.9, 0.6))
        else:
                var n := int(_time * 2.5) % 3 + 1
                turn_lbl.text = "CPU IS THINKING%s" % " .".repeat(n)
                turn_lbl.add_theme_color_override("font_color",
                        Color(1.0, 0.6, 0.5))

## the stuck door: v0.3.8-1 THE MANUAL YARD - no more an instant DRAW
## button while tiles remain. Stuck with a live yard = the yard SPREADS and
## the player taps the tile they take. Only a DRY yard earns the PASS.
func _sync_draw_btn() -> void:
        var stuck := false
        if state == "play" and turn == P and not opening:
                stuck = playable(hand_p, ends(chain).x, ends(chain).y) \
                        .is_empty()
        spread = stuck and deck.size() > 0
        if not stuck:
                if draw_btn != null and is_instance_valid(draw_btn):
                        draw_btn.queue_free()
                        draw_btn = null
                _relayout()
                return
        if spread:
                # the fan is the door now (the relayout owns its geometry)
                if draw_btn != null and is_instance_valid(draw_btn):
                        draw_btn.queue_free()
                        draw_btn = null
                _relayout()
                game_toast("THE YARD SPREADS - TAP A TILE TO DRAW")
                return
        if draw_btn != null and is_instance_valid(draw_btn):
                draw_btn.text = "PASS"
                return
        var vp := get_viewport_rect().size
        var by: float = hand_rects[0].position.y if not hand_rects.is_empty() \
                else vp.y - 240.0
        draw_btn = Arc.button("PASS", Vector2(280, 70), 26, Arc.ACCENT, func():
                _pass(P))
        draw_btn.position = Vector2((vp.x - 280.0) * 0.5, by - 88.0)
        _hud.add_child(draw_btn)
        var tw := draw_btn.create_tween().set_loops()
        tw.tween_property(draw_btn, "modulate:a", 0.6, 0.5)
        tw.tween_property(draw_btn, "modulate:a", 1.0, 0.5)

## THE TAKE: the player picked a face-down tile from the spread fan - it
## flies to the hand, the fan re-fans if the stuck door demands more
func _player_take(i: int) -> void:
        if not spread or i >= deck.size():
                return
        var t: Array = deck[i]
        var from: Vector2 = spread_rects[i].get_center() \
                if i < spread_rects.size() else pile_pos
        deck.remove_at(i)
        hand_p.append(t)
        cur["drew"] = int(cur.get("drew", 0)) + 1
        Jukebox.sfx("d_draw", -6.0)
        _relayout()
        var to: Vector2 = hand_rects[hand_rects.size() - 1].get_center() \
                if not hand_rects.is_empty() \
                else Vector2(get_viewport_rect().size.x * 0.5,
                get_viewport_rect().size.y - hw)
        flies.append({"tile": t, "from": from, "to": to,
                "back": true, "t": 0.0, "dur": 0.26})
        _sync_draw_btn()
        chain_l.queue_redraw()
        hand_l.queue_redraw()
        fx_l.queue_redraw()

func _draw_tile(who: int) -> void:
        if deck.is_empty():
                _pass(who)
                return
        var hand: Array = hand_p if who == P else hand_c
        var t: Array = deck.pop_back()
        hand.append(t)
        if who == P:
                cur["drew"] = int(cur.get("drew", 0)) + 1
                Jukebox.sfx("d_draw", -6.0)
                _relayout()
                _sync_draw_btn()
        else:
                Jukebox.sfx("d_draw", -9.0, 0.9)
                # v0.3.8-1: the CPU's diet is VISIBLE - a back flies from
                # the yard into its fan
                flies.append({"tile": t, "from": pile_pos,
                        "to": Vector2(cpu_pos.x, cpu_pos.y), "back": true,
                        "t": 0.0, "dur": 0.26})
        hand_l.queue_redraw()

func _pass(who: int) -> void:
        pass_streak += 1
        Jukebox.sfx("d_pass", -6.0)
        if who == P:
                game_toast("YOU PASS")
                if draw_btn != null and is_instance_valid(draw_btn):
                        draw_btn.queue_free()
                        draw_btn = null
        else:
                game_toast("THE CPU PASSES")
        if pass_streak >= 2:
                _blocked()
                return
        _after_move(who)

## THE BLOCKED LAW: lower pip total wins, tie = draw
func _blocked() -> void:
        var pp := 0
        for t in hand_p:
                pp += pips(t)
        var pc := 0
        for t in hand_c:
                pc += pips(t)
        if pp < pc:
                _resolve("win", true)
        elif pc < pp:
                _resolve("lose", true)
        else:
                _resolve("draw", true)

func _resolve(outcome: String, blocked: bool) -> void:
        state = "round_over"
        clock = 0.0
        done_rounds += 1
        cur["result"] = 0 if outcome == "draw" else (1 if outcome == "win" else 2)
        mem = remember(mem, cur)
        cur = {}
        if draw_btn != null and is_instance_valid(draw_btn):
                draw_btn.queue_free()
                draw_btn = null
        if outcome == "win":
                wins += 1
                add_score(1)
                achievement_count("wins", 1)
                achievement_max("max_score", score)
                verdict_txt = "DOMINO!  YOU WIN  +1"
                if blocked:
                        verdict_txt = "BLOCKED - YOUR HAND IS LIGHTER  +1"
                Jukebox.sfx("d_win", -3.0)
        elif outcome == "lose":
                losses += 1
                if score > 0:
                        add_score(-1)   # THE OWNER'S LAW: never negative
                verdict_txt = "THE CPU WINS  -1"
                if blocked:
                        verdict_txt = "BLOCKED - THE CPU IS LIGHTER  -1"
                Jukebox.sfx("d_lose", -3.0)
        else:
                draws += 1
                verdict_txt = "BLOCKED - EVEN PIPS  DRAW"
                Jukebox.sfx("d_blocked", -4.0)
        turn_lbl.text = verdict_txt
        turn_lbl.add_theme_color_override("font_color",
                Color(0.45, 0.9, 0.6) if outcome == "win"
                else (Color(1.0, 0.6, 0.5) if outcome == "lose"
                        else Color(0.8, 0.8, 0.85)))
        _refresh_widget()
        check_achievements()

func _new_round() -> void:
        rounds += 1
        deck = full_deck()
        for i in deck.size() - 1:
                var j := _rng.randi_range(i, deck.size() - 1)
                var tmp: Array = deck[i]
                deck[i] = deck[j]
                deck[j] = tmp
        hand_p = []
        hand_c = []
        chain = []
        sel = -1
        drag = false
        drag_i = -1
        pass_streak = 0
        seen_values = {}
        cur = {"open_end": 0, "drew": 0}
        flies = []
        opening = true
        # THE COIN LAW: after every 3rd completed round the next round
        # carries a coin on a play spot
        coin_side = 0
        if done_rounds > 0 and done_rounds % COIN_EVERY == 0:
                coin_side = 1 if _rng.randf() < 0.5 else 2
        profile = String(profile_next(profile_i)[0])
        profile_i = int(profile_next(profile_i)[1])
        # THE DEAL
        if state != "ready":
                state = "deal"
                deal_i = 0
                deal_beat = 0.0
                turn_lbl.text = "THE DEAL"
                turn_lbl.add_theme_color_override("font_color",
                        Color(1, 1, 1, 0.9))
        _relayout()

func _finish_deal() -> void:
        var op := opener(hand_p, hand_c)
        opener_tile = op["tile"]
        turn = int(op["who"])
        if turn == P:
                state = "play"
                game_toast("YOU HOLD THE OPENER - TAP THE GLOWING TILE")
        else:
                state = "cpu_wait"
                think_beat = 0.8
                game_toast("THE CPU HOLDS THE OPENER")
        _banner()
        _sync_draw_btn()

# ============================================================ the tick

func _goga_tick(delta: float) -> void:
        _time += delta
        coin_t += delta
        if shake_t > 0.0:
                shake_t -= delta
                if shake_t <= 0.0:
                        shake_i = -1
        for f in flies:
                f["t"] = float(f["t"]) + delta
        for f in flies.duplicate():
                if float(f["t"]) >= float(f["dur"]):
                        flies.erase(f)
        chain_l.queue_redraw()
        hand_l.queue_redraw()
        fx_l.queue_redraw()
        # THE LIVE TABLE LAW (v0.3.8): the table layer wears the boneyard
        # pile + count and the CPU hand fan + count - without its own
        # redraw they paint once and lie forever (the rig caught the
        # boneyard stuck at 28 after the deal ate half of it)
        table_l.queue_redraw()
        if state == "deal":
                deal_beat += delta
                if deal_beat >= 0.09 and deal_i < HAND_N * 2:
                        deal_beat = 0.0
                        var t: Array = deck.pop_back()
                        if deal_i % 2 == 0:
                                hand_p.append(t)
                        else:
                                hand_c.append(t)
                        deal_i += 1
                        Jukebox.sfx("d_draw", -13.0, 1.1 - 0.015 * deal_i)
                        _relayout()
                if deal_i >= HAND_N * 2 and deck.size() == 14:
                        _finish_deal()
        elif state == "cpu_wait":
                clock += delta
                _banner()
                if clock >= think_beat:
                        _cpu_move()
        elif state == "round_over":
                clock += delta
                if clock >= 1.8:
                        _new_round()

## THE CPU TURN: draw until playable (honest boneyard diet), then place
func _cpu_move() -> void:
        if chain.is_empty():
                var hi := -1
                for i in hand_c.size():
                        if int(hand_c[i][0]) == int(opener_tile[0]) \
                                        and int(hand_c[i][1]) == int(opener_tile[1]):
                                hi = i
                                break
                if hi >= 0:
                        _place(C, hi, 2)
                return
        var e := ends(chain)
        var opts := playable(hand_c, e.x, e.y)
        if opts.is_empty():
                if deck.size() > 0:
                        _draw_tile(C)
                        state = "cpu_wait"
                        clock = 0.0
                        think_beat = 0.45
                        return
                _pass(C)
                return
        var rng := RandomNumberGenerator.new()
        rng.seed = int(Time.get_unix_time_from_system() * 1000.0) \
                ^ (rounds * 7919) ^ (hand_c.size() * 104729)
        var flags := adapt(mem)
        var hi2 := cpu_pick(hand_c, e.x, e.y, profile, chain, seen_values,
                flags, rng)
        if hi2 < 0:
                _pass(C)
                return
        var t: Array = hand_c[hi2]
        var cp := can_play(t, e.x, e.y)
        var side := 2
        if (cp & 1) != 0 and (cp & 2) != 0:
                side = 1 if _rng.randf() < 0.5 else 2
        elif (cp & 1) != 0:
                side = 1
        if int(cur.get("open_end", 0)) == 0:
                cur["open_end"] = -1 if side == 1 else 1
        _place(C, hi2, side)

# ============================================================ the shop
## DIRECT (the owner: no optionals menu - the shop owns everything)

var shop_id := ""

func _shop_open() -> void:
        if shop_id != "":
                return
        shop_id = "shop"
        if ready_ui != null and is_instance_valid(ready_ui):
                ready_ui.visible = false
        paused = true
        get_tree().paused = true
        var sheet := sheet_push(0.0, "shop")
        var t := Arc.label("DOMINO SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 300.0, 640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        box.add_child(_shop_label("TILES - the set you play"))
        for id in SKINS:
                box.add_child(_skin_row(id))
        box.add_child(_shop_label("TABLES - the felt you meet"))
        for id in THEMES:
                box.add_child(_theme_row(id))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                func(): sheet_pop()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _goga_sheet_popped(id: String) -> void:
        if id == "shop":
                shop_id = ""
                get_tree().paused = false
                paused = false
                _load_meta()
                # THE GATE TRUTH LAW (v0.3.8): the tap-anywhere gate comes
                # back ONLY over the ready state - the old unconditional
                # show floated it over a live round after any mid-play
                # shop visit (the rig's probe-driven sheet caught it)
                if state == "ready" and ready_ui != null \
                                and is_instance_valid(ready_ui):
                        ready_ui.visible = true

func _shop_label(txt: String) -> Label:
        return Arc.fit_label(txt, 24, Arc.HOT, 560)

func _price_btn(txt: String, price: int, col: Color, cb: Callable) -> Button:
        var b := Arc.coin_button("%s  %d" % [txt, price], Vector2(560, 64),
                22, col, cb)
        if Box.coins() < price:
                b.disabled = true
        return b

func _skin_row(id: String) -> Control:
        var c: Dictionary = SKINS[id]
        var owned := Box.skin_owned(game_id, id) or int(c["price"]) == 0
        var on: bool = Box.skin_on(game_id) == id \
                or (int(c["price"]) == 0 and Box.skin_on(game_id) == "")
        if on:
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"], c["desc"]],
                        22, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s - WEAR" % c["name"], Vector2(560, 60),
                        22, Color("4a5ab8"), func():
                                Box.equip_skin(game_id, id)
                                Jukebox.sfx("confirm", -4.0)
                                _shop_reopen())
        return _price_btn(c["name"], int(c["price"]), Color("4a5ab8"), func():
                if Box.buy_skin(game_id, id, int(c["price"])):
                        Jukebox.sfx("buy")
                        Box.equip_skin(game_id, id)
                _shop_reopen())

func _theme_row(id: String) -> Control:
        var c: Dictionary = THEMES[id]
        var owned := Box.item_owned(game_id, "theme", id) or int(c["price"]) == 0
        var on: bool = Box.item_on(game_id, "theme") == id \
                or (int(c["price"]) == 0 and Box.item_on(game_id, "theme") == "")
        if on:
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"], c["desc"]],
                        22, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s - LIGHT IT" % c["name"], Vector2(560, 60),
                        22, Color("2a7a68"), func():
                                Box.equip_item(game_id, "theme", id)
                                Jukebox.sfx("confirm", -4.0)
                                _shop_reopen())
        return _price_btn(c["name"], int(c["price"]), Color("2a7a68"), func():
                if Box.buy_item(game_id, "theme", id, int(c["price"])):
                        Jukebox.sfx("buy")
                        Box.equip_item(game_id, "theme", id)
                _shop_reopen())

func _shop_reopen() -> void:
        if shop_id != "":
                sheet_pop()
                _shop_open.call_deferred()

# ============================================================ the probe
## The headless contract: deterministic rounds any probe can drive.

func probe_reset(seed_v: int) -> void:
        _rng.seed = seed_v
        # the gate dies with the probe (headless rounds start mid-flow)
        if ready_ui != null and is_instance_valid(ready_ui):
                ready_ui.queue_free()
                ready_ui = null
        rounds = 0
        done_rounds = 0
        wins = 0
        losses = 0
        draws = 0
        score = 0
        set_score(0)
        run_coins = 0
        mem = []
        profile_i = 0
        state = "play"
        spread = false
        spread_rects = []
        paused = true             # the probe steps the world itself
        _new_round()
        state = "deal"
        # fast-forward the deal instantly
        var guard := 0
        while state == "deal" and guard < 400:
                guard += 1
                deal_beat = 99.0
                _goga_tick(0.016)

func probe_step(dt: float) -> void:
        _goga_tick(dt)
