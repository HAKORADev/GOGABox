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
# v0.3.8-5 ROUND 2 - THE REAL SETS (the owner: "scrape the assets and put
# them as-is"): every skin now names one of the studied build's own tile
# sets - the actual pre-rendered faces + the blank plate back ship in
# assets/games/domino/tiles/<set>/. bone=bg1 jade=bg2 royal=bg3
# cherry=bg4 onyx=bg6 (the same art the studied game sells as its skins).
const SKINS := {
                "bone": {"name": "BONE", "price": 0, "set": "bg1",
                                "desc": "the classic ivory set"},
                "onyx": {"name": "ONYX", "price": 150, "set": "bg6",
                                "desc": "black tiles, gold pips"},
                "cherry": {"name": "CHERRY", "price": 220, "set": "bg4",
                                "desc": "the red pip set"},
                "jade": {"name": "JADE", "price": 280, "set": "bg2",
                                "desc": "cream on green"},
                "royal": {"name": "ROYAL", "price": 340, "set": "bg3",
                                "desc": "the sapphire pip set"},
}
# v0.3.8-5 ROUND 2 - THE REAL GROUNDS: every theme now names one of the
# studied build's own bg_game tables (assets/games/domino/grounds/) -
# tavern=bg2 (green) bluequilt=bg1 (azure) sunset=bg4 (red) marble=bg6
# (violet). The texture IS the table - no painted light.
const THEMES := {
                # v0.3.8-6: every theme wears its own ROOM color (the wall around
                # the frame) and RAIL color (the walnut frame) - the studied
                # tables' own moods.
                "tavern": {"name": "TAVERN", "price": 0, "ground": "bg2",
                                "desc": "the green table",
                                "room": Color("1c3a0e"), "rail": Color("5d4028")},
                "bluequilt": {"name": "AZURE", "price": 200, "ground": "bg1",
                                "desc": "the azure table",
                                "room": Color("122c4e"), "rail": Color("5d4028")},
                "sunset": {"name": "SUNSET", "price": 260, "ground": "bg4",
                                "desc": "the warm red table",
                                "room": Color("40120e"), "rail": Color("5d4028")},
                "marble": {"name": "VIOLET", "price": 320, "ground": "bg6",
                                "desc": "the violet table",
                                "room": Color("241640"), "rail": Color("5d4028")},
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
# v0.3.8-3 THE TAP TRUTH: a press only LIFTS a tile after the finger proves
# it is a drag - a small wobble stays a tap (the tile keeps its seat in the
# fan, the glow shows). The owner's chess law travels here.
var drag_origin := Vector2.ZERO
var drag_armed := false
var shake_t := 0.0
var shake_i := -1

# layout (v0.3.8-6 THE STATIC GROUND - the owner: "our GOGABox itself uses
## standard resolutions for both vertical and horizontal positions, so there
## is static math at this point"): domino is PORTRAIT-ONLY on the FIXED
## 1080x1920 canvas (registry "orientation": "portrait"), so every seat is
## an ABSOLUTE pixel constant. No vp-proportional math anywhere - the same
## numbers land the same pixels on every device, every run.
const SCREEN_W := 1080.0
const SCREEN_H := 1920.0
## THE GROUND FRAME (re-added, the owner: "re-add the ground frame"): the
## felt lives inside a real rail frame; FIELD is the chain zone it holds.
const FRAME := Rect2(30.0, 356.0, 1020.0, 1092.0)   # the outer rail edge
const FIELD := Rect2(54.0, 380.0, 972.0, 1044.0)    # the chain zone inside
## THE BONEYARD POCKET: the yard stack's own reserved seat inside the
## frame's top-left - the snake's census treats it as occupied, so a chain
## row can NEVER bury the pile or its count again (the rig caught the
## BONEYARD label printed under row tiles one time too many).
const POCKET := Rect2(54.0, 380.0, 212.0, 260.0)
var BASE_L := 190.0            # board tile long side (board space)
var hw := 252.0                # hand tile long side
# v0.3.8-5 THE SMOOTH GROUP LAW (the DominoBattle study law): the fit zoom
# and the re-center GLIDE to their target every tick - a placement never
# teleports the table
var _fit_target := 1.0
var _glide := false
var board_rect := Rect2()
var chain_rects: Array = []    # [{rect: Rect2 (SCREEN space), vertical: bool}]
var end_l := Rect2()           # the open play slots (screen space)
var end_r := Rect2()
var hand_rects: Array = []
var pile_pos := Vector2.ZERO
var cpu_pos := Vector2.ZERO
var _fit_scale := 1.0          # the CONTINUOUS fit scale (bbox -> ground)
# the two snake cursors: the open edge each side grows from
# {pos: Vector2 (board space), dir: Vector2 (unit, axis-aligned)}
var cur_l := {}
var cur_r := {}
var _end_board := {}       # side -> the open slot's BOARD-space center

# fly animations [{tile, from, to, ...}] - deal_p / deal_c / place /
# take_p / take_c (v0.3.8-6: the spin-flip flights)
var flies: Array = []
var _deal_p := 0               # the deal's launched-per-side counters
var _deal_c := 0
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
var draw_btn: Button = null    # PASS (lives only when the yard is dry)
var hand_c_lbl: Label
var pile_lbl: Label
var spread := false            # v0.3.8-1: the yard fanned out for a manual draw
# v0.3.8-6 THE ROUND-HONEST YARD (the owner: "they should from the start of
# the round stay same dominoes internally in same positions without these
# modifications"): the yard's 14 slots are BOUND ONCE per round - same
# dominoes, same seats, the whole round. A taken slot keeps its HOLE (the
# player's taps AND the CPU's diet both hole their slot); nothing ever
# reflows, nothing ever rebuilds. The fan's tile size is the HAND size.
var yard_tiles: Array = []     # slot i IS tile i, bound at _finish_deal
var yard_holes := {}           # slot -> true (the hole stays forever)
var yard_rects: Array = []     # 14 fixed rects, built once per round
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
                # v0.3.8-5 THE PARLOR THEME: d_theme.ogg - the sunny table loop
                # composed for this room (tools/v038p5_dc_music.py, 120 BPM D-major,
                # original synthesis - nothing from the studied web game ships)
                Jukebox.music("res://assets/audio/music/d_theme.ogg")
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

# v0.3.8-5 ROUND 2 - THE AS-IS ART SHELF (the owner: "scrape the code and
# the assets and put them as-is"): the real pre-rendered faces, the blank
# plate back and the real ground band, lifted straight from the studied
# build's own atlases. Lazy-loaded once, cached forever.
var _tex_cache := {}

func _set_tex(set_id: String, a: int, b: int) -> Texture2D:
                var lo := mini(a, b)
                var hi := maxi(a, b)
                var key := "%s/%d-%d" % [set_id, lo, hi]
                if not _tex_cache.has(key):
                                _tex_cache[key] = load("res://assets/games/domino/tiles/%s/%d-%d.png"
                                                % [set_id, lo, hi])
                return _tex_cache[key]

func _back_tex(set_id: String) -> Texture2D:
                var key := "%s/back" % set_id
                if not _tex_cache.has(key):
                                _tex_cache[key] = load(
                                                "res://assets/games/domino/tiles/%s/back.png" % set_id)
                return _tex_cache[key]

func _ground_tex(ground_id: String) -> Texture2D:
                var key := "ground/%s" % ground_id
                if not _tex_cache.has(key):
                                _tex_cache[key] = load(
                                                "res://assets/games/domino/grounds/%s.png" % ground_id)
                return _tex_cache[key]

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
                                # v0.3.8-6 THE W-D-L CARDS IN THE HUD ROW (the owner moved the chess
                                # widget "next to score widget, like the dominoes one" - so the
                                # dominoes one lives in the SAME seat now: one law for both games,
                                # and the old top-right seat can never cover a dealt back again):
                                # three white cards, W green / D gray / L red - LEFT of the score.
                                widget_strip = Control.new()
                                widget_strip.custom_minimum_size = Vector2(108.0 * 3.0 + 8.0 * 2.0, 64.0)
                                widget_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
                                widget_strip.draw.connect(_draw_goal_cards.bind(widget_strip))
                                _hud_row.add_child(widget_strip)
                                var score_panel: Control = _score_label.get_parent()
                                _hud_row.move_child(widget_strip, score_panel.get_index())
                                turn_lbl = Arc.label("", 28, Color(1, 1, 1, 0.92))
                                turn_lbl.position = Vector2(0, 302)
                                turn_lbl.custom_minimum_size = Vector2(SCREEN_W, 38)
                                turn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                                world.add_child(turn_lbl)
                                pile_lbl = Arc.label("", 20, Color(1, 1, 1, 0.7))
                                pile_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                                world.add_child(pile_lbl)
                                hand_c_lbl = Arc.label("", 20, Color(1, 1, 1, 0.7))
                                world.add_child(hand_c_lbl)

func _draw_goal_cards(c: Control) -> void:
                                # the W-D-L cards' draw law (the same three cards the chess room wears)
                                var cw := 108.0
                                var ch := 46.0
                                var gapw := 8.0
                                var cols := [Color("58c470"), Color("8b93a1"), Color("e8574a")]
                                var letters := ["W", "D", "L"]
                                var f := ThemeDB.fallback_font
                                var mid_y := c.size.y * 0.5
                                var x0 := c.size.x * 0.5
                                for i in 3:
                                                                var x: float = (cw + gapw) * (i - 1) + x0
                                                                var r := Rect2(x - cw * 0.5, mid_y - ch * 0.5, cw, ch)
                                                                c.draw_rect(Rect2(r.position + Vector2(4, 4), r.size),
                                                                                                Color(0.09, 0.05, 0.02, 0.85))
                                                                c.draw_rect(r, Color(1, 1, 1, 0.95))
                                                                c.draw_rect(r, cols[i], false, 5.0)
                                                                var num: int = [wins, draws, losses][i]
                                                                c.draw_string(f, Vector2(x - cw * 0.5 + 10.0, mid_y + 15.0),
                                                                                                letters[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26,
                                                                                                cols[i])
                                                                c.draw_string(f, Vector2(x - cw * 0.5 + 36.0, mid_y + 17.0),
                                                                                                str(num), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Arc.INK)

func _refresh_widget() -> void:
                                # v0.3.8-6: the cards repaint straight from wins/draws/losses
                                if widget_strip != null and is_instance_valid(widget_strip):
                                                                widget_strip.queue_redraw()

var widget_strip: Control = null

# ============================================================ the layout
## Recomputed on every structural change.
## v0.3.8-4 THE ANCHORED SNAKE (the owner sent the Loop Games Dominoes XAPK
## and demanded the study: "obviously the ground should not work this
## way"): the decompiled truth is ChainDominoDirectionVec + Calculate(simple
## |double)DominoPosition + DoDominosOverlap + CalculateBoardWidth/Height -
## a chain that GROWS from its ends along a direction vector, tiles that
## NEVER move once placed, elbows that turn the line like a road, and a
## table that fits the whole chain's bounding box. The old sheet RE-FLOWED
## the whole snake from the screen center on every placement (tiles slid,
## switched rows, leaned left) - that game is dead.

func _board_scale() -> float:
                return _fit_scale

func _tile_long() -> float:
                return BASE_L

func _tile_short() -> float:
                return BASE_L * 0.5

# v0.3.8-5 ROUND 2 - THE STICK-TOGETHER LAW (the studied matrix steps by
# EXACTLY TILE_HEIGHT: `posx += rot_matrix.dx` - a domino's end touches the
# next domino's end, one solid chain, no daylight): the gap is dead.
const SNAKE_GAP := 0.0

## the rect a tile at `center` occupies in BOARD space
## along = the extent in the flow direction, across = the perpendicular one
func _pose_rect(center: Vector2, dir: Vector2, along: float,
                across: float) -> Rect2:
                if absf(dir.x) > 0.5:
                                return Rect2(center - Vector2(along, across) * 0.5,
                                                Vector2(along, across))
                return Rect2(center - Vector2(across, along) * 0.5,
                                                Vector2(across, along))

## v0.3.8-4 THE PV TRUTH: a placed tile's rect reads its OWN pv (the
## orientation the renderer draws) - the ONE orientation truth.
func _pose_rect_pv(center: Vector2, vert: bool) -> Rect2:
                var sz := Vector2(_tile_short(), _tile_long()) if vert \
                                else Vector2(_tile_long(), _tile_short())
                return Rect2(center - sz * 0.5, sz)

## every placed tile's board-space rect (the fit's bbox census)
func _placed_rects() -> Array:
                var out: Array = []
                for t in chain:
                                if not t.has("px"):
                                                continue
                                var vert: bool = bool(t["pv"]) if t.has("pv") \
                                                else (absf(Vector2(t["pdx"], t["pdy"]).x) < 0.5)
                                out.append(_pose_rect_pv(Vector2(t["px"], t["py"]), vert))
                return out

# v0.3.8-6 THE ROW-PACK LAW (the owner: "no way you can not code a proper
## dominoes board/ground" - and three rounds of elbow bugs agree): the
## chain packs into ROWS of at most ROW_MAX tiles, pure arithmetic - no
## candidate probing, no hit tests, no elbows deciding by committee.
## A row runs; at ROW_MAX ONE corner tile stands vertical astride the
## bend; the next row runs the OPPOSITE way one pitch below. Five to a
## row: the serpentine folds tall-narrow to match the field's aspect -
## seven packed the 20-tile chain 1710 wide (4:1) and the 0.45
## readability floor could not answer a 1.17:1 ground (the probe
## measured the poke-through); five keeps every honest chain above the
## floor. Tiles
## TOUCH edge-to-edge exactly (the studied stick-together law) and a
## double lies ACROSS the flow - the classic. Overlap is impossible by
## construction, and the fit zoom guarantees the whole box sits in the
## chain area - the 28-tile worst case is a closed-form rectangle.
const ROW_MAX := 5

## the row pitch: one long side + one short side - facing doubles clear
func _row_pitch() -> float:
                return _tile_long() + _tile_short()

## the next slot a side's cursor would take (dbl is kept for the call
## signature - under THE PACK LAW it no longer bends the pose). Pure
## math off the cursor.
## THE CORNER: at ROW_MAX the turn domino stands IN the row's own band -
## its long edge flush against the last tile's short edge (the real
## L-turn, full edge contact); the return row one half-pitch down plugs
## its first tile UNDER the corner (the cursor paid the corner's width).
## THE PACK (v0.3.8-5 round 3): every ROW TILE LIES along the flow -
## doubles ride IN-LINE, the Mexican-Train pack. The probe proved the
## alternative dead: on a half-pitch lattice ANY standing tile aligned
## under a standing tile pierces it by half a short, and doubles land
## on aligned columns too often to guard. Rows of lying tiles + standing
## corners = zero overlap BY CONSTRUCTION, 47.5 daylight between rows,
## and the corner stays the only vertical in the field (the opener
## double stands alone at the center, where row 1's top edge meets its
## bottom edge exactly).
func _snake_candidate(cur: Dictionary, _dbl: bool) -> Dictionary:
                var dir: Vector2 = cur["dir"]
                var x: float = cur["x"]
                var y: float = cur["y"]
                if int(cur.get("run", 0)) >= ROW_MAX:
                                # THE CORNER: one vertical tile astride the bend,
                                # in the row's own band, sticking out sideways
                                var cc := Vector2(x + dir.x * (_tile_short() * 0.5), y)
                                var csz := Vector2(_tile_short(), _tile_long())
                                return {"center": cc, "dir": dir,
                                                "rect": Rect2(cc - csz * 0.5, csz),
                                                "vert": true}
                var center := Vector2(x + dir.x * (_tile_long() * 0.5), y)
                var rsz := Vector2(_tile_long(), _tile_short())
                return {"center": center, "dir": dir,
                                                "rect": Rect2(center - rsz * 0.5, rsz),
                                                "vert": false}

## THE STEP: commit the next tile's pose into `entry` and advance the
## side's cursor. The corner turns the row: same edge, one pitch down,
## the heading flips (the S-pack the real tables draw).
func _snake_place(side: int, dbl: bool, entry: Dictionary) -> void:
                var cur: Dictionary = cur_r if side == 2 else cur_l
                var cand := _snake_candidate(cur, dbl)
                entry["px"] = cand["center"].x
                entry["py"] = cand["center"].y
                entry["pv"] = cand["vert"]
                entry["pdx"] = (cand["dir"] as Vector2).x
                entry["pdy"] = (cand["dir"] as Vector2).y
                var dir: Vector2 = cand["dir"]
                if int(cur.get("run", 0)) >= ROW_MAX:
                                # the turn: the cursor pays the corner's width,
                                # drops half a pitch, and heads back (the return
                                # row's first tile lands flush under the corner)
                                cur["x"] = float(cur["x"]) + dir.x * _tile_short()
                                cur["y"] = float(cur["y"]) + _row_pitch() * 0.5
                                cur["dir"] = Vector2(-dir.x, 0)
                                cur["run"] = 0
                else:
                                # every row tile strides ONE LONG - the pack law
                                cur["x"] = float(cur["x"]) + dir.x * _tile_long()
                                cur["run"] = int(cur.get("run", 0)) + 1

## the opener's pose: dead center of the chain area, the double stands
## (the classic), both cursors step off its two ends
func _snake_open(entry: Dictionary) -> void:
                var c := _chain_area().get_center()
                entry["px"] = c.x
                entry["py"] = c.y
                entry["pv"] = int(entry["a"]) == int(entry["b"])
                entry["pdx"] = 1.0
                entry["pdy"] = 0.0
                # the cursors step off the opener's TRUE ends - a standing
                # double's ends are short/2 away, a lying tile's are long/2
                # (the old fixed long/2 left daylight beside a double opener)
                var off := (_tile_short() if bool(entry["pv"]) \
                                else _tile_long()) * 0.5
                cur_r = {"x": c.x + off, "y": c.y, "dir": Vector2(1, 0), "run": 0}
                cur_l = {"x": c.x - off, "y": c.y, "dir": Vector2(-1, 0), "run": 0}

## a from-scratch rebuild (probe-built chains, stale poses): the array order
## IS the left->right order, so the replay just snakes it to the right
func _snake_rebuild() -> void:
                if chain.is_empty():
                                return
                var first: Dictionary = chain[0]
                first.erase("fl")
                _snake_open(first)
                first["fl"] = false
                for i in range(1, chain.size()):
                                var t: Dictionary = chain[i]
                                var dbl: bool = int(t["a"]) == int(t["b"])
                                _snake_place(2, dbl, t)

## THE FIT LAW: the chain's bounding box is CENTERED in the ground and the
## scale walks down in small honest steps only when the box outgrows it.
## Continuous, real, no jumps - and a tile NEVER moves relative to its
## neighbours (the zoom moves them all together).
## v0.3.8-6 THE CHAIN AREA: the field's sub-rect BELOW the boneyard
## pocket strip - the fit centers and scales the chain into THIS, so a
## chain tile can never reach up into the pile's pocket (the pile is
## painted there, the census stays clean board-space, the snake never
## smells the pocket).
func _chain_area() -> Rect2:
                var strip: float = minf(POCKET.size.y, board_rect.size.y * 0.5)
                return Rect2(board_rect.position.x,
                                board_rect.position.y + strip, board_rect.size.x,
                                board_rect.size.y - strip)

func _fit_chain() -> float:
                if chain.size() <= 1:
                                return 1.0
                var bb := _chain_bbox()
                # v0.3.8-5 (the DominoBattle law): the margins are thin - the
                # ground is for dominoes, not for padding
                # v0.3.8-6: the avail lives in the CHAIN AREA (below the pocket)
                var avail := _chain_area().grow(-16.0).size
                if bb.size.x <= 0.0 or bb.size.y <= 0.0:
                                return 1.0
                var s: float = minf(1.0, minf(avail.x / bb.size.x,
                                avail.y / bb.size.y))
                # v0.3.8-5: the floor walks UP to 0.45 - the spiral limits below
                # keep the box compact, so honest play never gets near the floor
                return clampf(s, 0.45, 1.0)

func _chain_bbox() -> Rect2:
                var rs := _placed_rects()
                # the open-end candidates ride the census: the fit has ALREADY
                # made room for the slot it displays, so a tile that lands
                # there never moves the table (no reflow, no jump - the old
                # fit only saw placed tiles and walked a step AFTER every
                # landing)
                if not cur_l.is_empty() and not cur_r.is_empty():
                                rs.append(_snake_candidate(cur_l, false)["rect"])
                                rs.append(_snake_candidate(cur_r, false)["rect"])
                var bb := Rect2()
                var first := true
                for r in rs:
                                if first:
                                                bb = r
                                                first = false
                                else:
                                                bb = bb.merge(r)
                return bb

## board-space pose -> screen rect under the current fit
func _pose_to_screen(t: Dictionary) -> Rect2:
                # v0.3.8-4 THE PV TRUTH: the screen rect reads pv - the ONE
                # orientation truth, the same law the census and the renderer wear
                var vert: bool = bool(t["pv"]) if t.has("pv") \
                                                else (absf(Vector2(t["pdx"], t["pdy"]).x) < 0.5)
                var board := _pose_rect_pv(Vector2(t["px"], t["py"]), vert)
                var bc := _chain_area().get_center()
                var bb := _chain_bbox()
                var off := (board.get_center() - bb.get_center()) * _fit_scale
                var center := bc + off
                var size := board.size * _fit_scale
                return Rect2(center - size * 0.5, size)

func _relayout() -> void:
                                # v0.3.8-6 THE STATIC SEATS (absolute pixels, the 1080x1920 law):
                                # the chain zone IS the frame's field, the CPU fan rides ABOVE the
                                # frame, the hand fan rides BELOW it - nothing overlaps, nothing
                                # scales with the viewport, ever.
                                board_rect = FIELD
                                _relayout_board()
                                cpu_pos = Vector2(SCREEN_W * 0.5, 208.0)
                                # the turn status rides the clear strip between the CPU fan and the
                                # frame's top rail
                                if turn_lbl != null:
                                                turn_lbl.position = Vector2(0, 302)
                                pile_pos = POCKET.get_center() + Vector2(0, -14.0)
                                # the hand fan (v0.3.8-6: OUT of the frame - the owner's law)
                                hand_rects = []
                                for i in hand_p.size():
                                                                hand_rects.append(_hand_slot(hand_p.size(), i))
                                # the CPU fan's status sits just above the frame's top rail
                                if hand_c_lbl != null:
                                                hand_c_lbl.position = Vector2(0, 292)
                                                hand_c_lbl.custom_minimum_size = Vector2(SCREEN_W, 26)

## the board-space half of the relayout (the snake, the fit, the slots) -
## callable on its own so the probe can shrink the ground and certify the
## fit law honestly
func _relayout_board() -> void:
                # the resting yard: the felt's TOP-LEFT corner band - the old
                # mid-left seat drowned under the serpentine's rows once the chain
                # grew wide (the rig caught the stack buried behind row tiles; the
                # rows pack from the center outward, the corner stays open)
                pile_pos = Vector2(board_rect.position.x + 92.0,
                                board_rect.position.y + 96.0)
                if chain.is_empty():
                                chain_rects = []
                                end_l = Rect2()
                                end_r = Rect2()
                                _fit_scale = 1.0
                                return
                # stale poses (probe-built chains)? rebuild the snake honest
                var stale := false
                for t in chain:
                                if not t.has("px"):
                                                stale = true
                                                break
                if stale:
                                _snake_rebuild()
                # v0.3.8-5 THE SMOOTH GROUP LAW: the computed fit is the TARGET -
                # the first placement of a round lands on it at once, later ones
                # glide (a 7.5/s lerp in the tick moves the WHOLE table together -
                # no tile ever moves relative to its neighbours)
                _fit_target = _fit_chain()
                if chain.size() <= 1 or absf(_fit_scale - _fit_target) > 0.35 \
                                                or _fit_scale <= 0.0:
                                _fit_scale = _fit_target
                else:
                                _glide = true
                # the end slots live in _relayout_chain_rects alone (the ONE
                # computation - the old duplicate block also called helpers the
                # row-pack law retired)
                _relayout_chain_rects()

## v0.3.8-5: rigs (the probe, the thumbnail capture) measure the SETTLED
## table - this snaps the glide to its target at once and rebuilds the
## rects, so a synchronous check never reads the mid-zoom transient
func _settle_glide() -> void:
                _fit_scale = _fit_target
                _glide = false
                _relayout_chain_rects()

## v0.3.8-5: the chain rects + end slots, rebuilt on their own so the
## tick's glide can refresh them every frame (cheap: at most 28 rects)
func _relayout_chain_rects() -> void:
                chain_rects = []
                for t in chain:
                                chain_rects.append({"rect": _pose_to_screen(t),
                                                                "vertical": bool(t["pv"])})
                # THE OPEN-END SLOTS: the pure candidate law - the slot IS
                # where the next tile lands (corner honest), no probing, no
                # hit tests: overlap is impossible by construction. Their
                # BOARD-space centers matter (the coin race judges in board
                # space: the screen pan must never steal a landed coin).
                var e := ends(chain)
                end_l = Rect2()
                end_r = Rect2()
                _end_board = {}
                if e.x == -1 or cur_l.is_empty() or cur_r.is_empty():
                                return
                var cl := _snake_candidate(cur_l, false)
                var cr := _snake_candidate(cur_r, false)
                end_l = _board_to_screen_rect(cl["rect"])
                end_r = _board_to_screen_rect(cr["rect"])
                _end_board = {1: cl["center"], 2: cr["center"]}

## a board-space rect through the fit transform (the slot truth)
func _board_to_screen_rect(r: Rect2) -> Rect2:
                var bc := _chain_area().get_center()
                var bb := _chain_bbox()
                var off := (r.get_center() - bb.get_center()) * _fit_scale
                var center := bc + off
                var size := r.size * _fit_scale
                return Rect2(center - size * 0.5, size)

## the SCALED board tile size (the drag carry + the yard read it)
func bw() -> float:
                return BASE_L * _fit_scale

## the finger's distance to a drop seat (0 inside) - Rect2 has no such
## helper in Godot 4, and the wide catch needs the honest number
func _drop_dist(r: Rect2, at: Vector2) -> float:
                if r.has_point(at):
                                return 0.0
                var dx: float = maxf(r.position.x - at.x, at.x - r.end.x)
                var dy: float = maxf(r.position.y - at.y, at.y - r.end.y)
                return maxf(0.0, maxf(dx, dy)) if (dx < 0.0 or dy < 0.0) \
                                else Vector2(maxf(dx, 0.0), maxf(dy, 0.0)).length()

## the fan slot for a hand of `n` tiles, tile `i` - ONE truth for the
## layout AND the deal flies (a landing tile always knows its seat).
## v0.3.8-6: static pixels, BELOW the frame (out of the ground - the
## owner's "in-hand should be out of the frame").
func _hand_slot(n: int, i: int) -> Rect2:
                                var tw2 := hw * 0.5
                                var overlap := 0.0
                                var maxw := SCREEN_W - 48.0
                                var total := tw2 * n
                                if total > maxw and n > 1:
                                                                overlap = (total - maxw) / float(n - 1)
                                var x0 := (SCREEN_W - (total - overlap * (n - 1))) * 0.5
                                var hy := 1548.0
                                return Rect2(Vector2(x0 + i * (tw2 - overlap), hy),
                                                                Vector2(tw2, hw))

## the CPU's mirror slot (backs) - ABOVE the frame, its own honest row
func _cpu_slot(n: int, i: int) -> Rect2:
                                var tw := hw * 0.38
                                var th := hw * 0.60
                                var overlap := 0.0
                                var maxw := SCREEN_W - 56.0
                                var total := tw * n
                                if total > maxw and n > 1:
                                                                overlap = (total - maxw) / float(n - 1)
                                var x0 := cpu_pos.x - (total - overlap * (n - 1)) * 0.5
                                return Rect2(Vector2(x0 + i * (tw - overlap),
                                                                cpu_pos.y - th * 0.5), Vector2(tw, th))

# ============================================================ the drawing

func _draw_table() -> void:
                                # v0.3.8-6 THE ROOM + THE FRAME (the owner: "the white area, make it
                                # use background color as it was, re-add the ground frame"): the
                                # room paints FIRST - one full-screen background color, the same
                                # deep felt tone every theme carries - so no bare clear-color and
                                # no white plates can ever show again (the scraped edge-shadow
                                # PNGs white-plated on the GL stack, the same upload bug the chess
                                # wood hit: canvas primitives only from here on). Then the real
                                # bg_game felt inside the RAIL FRAME (frame re-added by law), with
                                # soft canvas edge shading inside the rails.
                                var t := _theme()
                                # THE ROOM: full-screen background color (the wall around the table)
                                var room: Color = t["room"]
                                table_l.draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), room)
                                # THE FELT: the studied build's own bg_game texture, cover-fit
                                # inside the frame's field
                                var tex := _ground_tex(String(t["ground"]))
                                var ts := tex.get_size()
                                var k: float = maxf(FIELD.size.x / ts.x, FIELD.size.y / ts.y)
                                var dst := ts * k
                                var off := FIELD.get_center() - dst * 0.5
                                table_l.draw_texture_rect(tex, Rect2(off, dst), false)
                                # THE INNER EDGE SHADE (canvas gradient strips - never a texture):
                                # the table dips into shadow where it meets the rails
                                var steps := 12
                                for sk in steps:
                                                                var sa := 0.20 * (1.0 - float(sk) / float(steps))
                                                                var sw := float(sk) * 4.0
                                                                table_l.draw_rect(Rect2(FIELD.position.x,
                                                                                                FIELD.position.y + sw, FIELD.size.x, 4.0),
                                                                                                Color(0, 0, 0, sa))
                                                                table_l.draw_rect(Rect2(FIELD.position.x,
                                                                                                FIELD.end.y - sw - 4.0, FIELD.size.x, 4.0),
                                                                                                Color(0, 0, 0, sa * 0.8))
                                # THE RAIL FRAME (re-added): the walnut rail + its dark outline
                                table_l.draw_rect(FRAME, t["rail"], false, 12.0)
                                table_l.draw_rect(FRAME.grow(5.0), Color(0.09, 0.05, 0.02, 0.85),
                                                                false, 4.0)
                                _draw_pile()
                                _draw_cpu_hand()

func _draw_tile_body(onto: Node2D, r: Rect2, a: int, b: int, vertical: bool,
                sel_glow := 0.0) -> void:
        # v0.3.8-5 ROUND 2 - THE REAL TILE (the owner: "scrape the code and the
        # assets and put them as-is ... remove that fake in-domino shading"):
        # the studied build's own face sprite - one pre-rendered texture per
        # domino - drawn straight into the pose rect. Horizontal poses ride the
        # transpose. The selection ring keeps the studied build's own decision
        # yellow (0xFFFF32). The painted sheen, the painted shade, the painted
        # pip wells, the painted drop shadow: dead.
        var s := _skin()
        if sel_glow > 0.0:
                onto.draw_rect(r.grow(6.0),
                                Color(1.0, 0.951, 0.196, 0.5 * sel_glow), false, 5.0)
        var tex: Texture2D = _set_tex(String(s["set"]), a, b)
        # v0.3.8-5 ROUND 3 - THE HONEST TIP: the Xvfb film pixel-measured
        # draw_texture_rect's transpose drawing the RAW face into the
        # TRANSPOSED rect (rect 86x43, tile 40x75) - every lying domino
        # stood portrait on a landscape footprint. transpose is dead: a
        # lying tile is the standing face tipped -PI/2 on the canvas.
        if vertical:
                onto.draw_texture_rect(tex, r, false, Color.WHITE)
        else:
                onto.draw_set_transform(r.get_center(), -PI * 0.5,
                                Vector2.ONE)
                onto.draw_texture_rect(tex,
                                Rect2(Vector2(-r.size.y, -r.size.x) * 0.5,
                                                Vector2(r.size.y, r.size.x)),
                                false, Color.WHITE)
                onto.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
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
                # the chain (v0.3.8-3: a tile that is still FLYING does not paint -\n        # the old ghost pre-place drew the landed domino first and then the\n        # flight arrived on top of its own body: \"a fever dream situation\")
                for i in chain.size():
                                var info: Dictionary = chain_rects[i]
                                var t: Dictionary = chain[i]
                                if not bool(t.get("landed", true)):
                                                continue
                                var a := int(t["a"])
                                var b := int(t["b"])
                                if bool(t["fl"]):
                                                var tmp := a
                                                a = b
                                                b = tmp
                                _draw_tile_body(chain_l, info["rect"], a, b,
                                                bool(info["vertical"]))

## v0.3.8-6: is this hand/cpu seat's tile still spin-flipping in the air?
func _seat_in_flight(i: int, kind: String) -> bool:
                for f in flies:
                                if String(f.get("kind", "")) == kind \
                                                and int(f.get("seat_i", -1)) == i:
                                                return true
                return false

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
                                # v0.3.8-3: only an ARMED drag hides the fan tile - a mere
                                # tap keeps the tile standing in its seat (the glow speaks)
                                if drag_i == i and drag and drag_armed:
                                                continue
                                # v0.3.8-6: a seat whose spin-flip is still in the air stays
                                # empty until touchdown (the flying tile IS the hand tile)
                                if _seat_in_flight(i, "take_p"):
                                                continue
                                _draw_tile_body(hand_l, rr, int(t[0]), int(t[1]), true, glow)
                                if turn == P and state == "play" and sel < 0 and not opening \
                                                                and can_play(t, e.x, e.y) > 0:
                                                hand_l.draw_rect(rr.grow(2.0), Color(1, 1, 1, 0.18),
                                                                false, 2.5, true)

## v0.3.8-6 THE SPIN-FLIP DRAW: one honest tile in the air - back
## showing, a full 360 spin, the face fading in during the second
## half of the spin, the size easing from where it came to where
## it sits. THE one tile the player tapped is THE tile that lands
## (no ghost swap, no pop-in - the owner's "another one appear
## small then get bigger" is dead).
func _draw_flip_tile(onto: Node2D, center: Vector2, sz: Vector2, a: int,
                b: int, vert: bool, rot: float, fade: float, back_only := false) -> void:
                var s := _skin()
                # THE HONEST TIP: vert=false = the standing face tipped a
                # quarter turn - the FACE rides portrait, the transform does
                # the lying (no transpose: the film caught it transposing the
                # rect instead of the texture)
                if not vert:
                                sz = Vector2(sz.y, sz.x)
                onto.draw_set_transform(center, rot, Vector2.ONE)
                var r := Rect2(-sz * 0.5, sz)
                if back_only or fade <= 0.02:
                                onto.draw_texture_rect(_back_tex(String(s["set"])), r, false)
                elif fade >= 0.98:
                                onto.draw_texture_rect(_set_tex(String(s["set"]), a, b),
                                                r, false)
                else:
                                onto.draw_texture_rect(_back_tex(String(s["set"])), r,
                                                false, Color(1, 1, 1, 1.0 - fade))
                                onto.draw_texture_rect(_set_tex(String(s["set"]), a, b),
                                                r, false, Color(1, 1, 1, fade))
                onto.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_fx() -> void:
                # v0.3.8-3 EVERY FLIGHT RIDES THE FX LAYER (above hand and chain):
                # the deal flights, the take flights and the place flights - one
                # truth for the air traffic.
                for f in flies:
                                var ft: Array = f["tile"]
                                var k: float = clampf(float(f["t"]) / float(f["dur"]), 0.0, 1.0)
                                var ease := 1.0 - pow(1.0 - k, 3.0)
                                var at: Vector2 = (f["from"] as Vector2).lerp(
                                                f["to"] as Vector2, ease)
                                match String(f.get("kind", "")):
                                                "deal_p", "take_p":
                                                                # THE SPIN-FLIP: back as-is, one full turn, the face
                                                                # fades in mid-air, the tile scales from its yard/pile
                                                                # size to its hand seat and drops in normally.
                                                                var fsz: Vector2 = (f.get("from_sz",
                                                                                    Vector2(98, 190)) as Vector2).lerp(
                                                                                (f.get("to_sz", Vector2(hw * 0.5, hw))
                                                                                    as Vector2), ease)
                                                                var fade: float = clampf((k - 0.42) / 0.34, 0.0, 1.0)
                                                                _draw_flip_tile(fx_l, at, fsz, int(ft[0]),
                                                                                int(ft[1]), true, TAU * ease, fade)
                                                "deal_c", "take_c":
                                                                # the CPU's diet: the same spin, the BACK stays
                                                                # (secret is secret) - it lands in its fan seat
                                                                var fsz2: Vector2 = (f.get("from_sz",
                                                                                    Vector2(98, 190)) as Vector2).lerp(
                                                                                (f.get("to_sz", Vector2(hw * 0.38,
                                                                                    hw * 0.60)) as Vector2), ease)
                                                                _draw_flip_tile(fx_l, at, fsz2, int(ft[0]),
                                                                                int(ft[1]), true, TAU * ease, 0.0, true)
                                                "place":
                                                                # THE SMOOTH FALL: the tile leaves STANDING (rot
                                                                # 90deg over its long side) and tips to the landing
                                                                # pose as it arrives - the real domino fall (doubles
                                                                # stand). v0.3.8-6 THE ENEMY FLIP (the owner: "same
                                                                # for user, the animation is instant, there is steps
                                                                # missing"): the CPU's tile flies BACK-UP and the face
                                                                # fades in on the way - the reveal IS the play.
                                                                var pr: Rect2 = f["rect"]
                                                                var rot: float = lerpf(float(f["r0"]),
                                                                                float(f["r1"]), ease)
                                                                var flip: float = 1.0
                                                                if bool(f.get("flip", false)):
                                                                                flip = clampf((k - 0.28) / 0.34, 0.0, 1.0)
                                                                _draw_flip_tile(fx_l, at, pr.size,
                                                                                int(f.get("fa", ft[0])),
                                                                                int(f.get("fb", ft[1])),
                                                                                bool(f["vert"]), rot, flip,
                                                                                bool(f.get("flip", false)) and flip <= 0.02)
                                                _:
                                                                # legacy unnamed flights: the honest face glide
                                                                var tsz := Vector2(bw() * 0.5, bw())
                                                                _draw_flip_tile(fx_l, at, tsz, int(ft[0]),
                                                                                int(ft[1]), true, 0.0, 1.0,
                                                                                bool(f.get("back", false)))
                # the dragged tile: only when the finger ARMED the carry (a small
                # wobble is a tap - the tile never leaps to the finger), and it
                # rides STANDING at board scale above the fingertip
                if drag and drag_armed and drag_i >= 0 and drag_i < hand_p.size():
                                var t: Array = hand_p[drag_i]
                                var dsz := Vector2(bw() * 0.5, bw())   # carried standing, board scale
                                var at2 := drag_pos - Vector2(0, bw() * 0.62)
                                var r := Rect2(at2 - dsz * 0.5, dsz)
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
                                                                # v0.3.8-6: the label sits INSIDE its pocket, never buried
                                                                # (the pocket is reserved - the snake routes around it)
                                                                pile_lbl.position = Vector2(POCKET.position.x, POCKET.end.y - 34.0)
                                                                pile_lbl.custom_minimum_size = Vector2(POCKET.size.x, 28)
                                                                return
                                # a taller honest stack: up to 6 backs with real depth - FIXED
                                # size (98x190, the pocket's own plates; nothing here scales with
                                # the chain's fit zoom any more)
                                var s := Vector2(98.0, 190.0)
                                for k in mini(6, n):
                                                                var r := Rect2(pile_pos - s * 0.5
                                                                                                + Vector2(k * 2.8, -k * 4.4), s)
                                                                _draw_tile_back(table_l, r)
                                pile_lbl.text = "BONEYARD %d" % n
                                pile_lbl.add_theme_font_size_override("font_size", 24)
                                pile_lbl.position = Vector2(POCKET.position.x, POCKET.end.y - 34.0)
                                pile_lbl.custom_minimum_size = Vector2(POCKET.size.x, 28)

## the round-honest yard fan (fx layer): the face-down yard the user picks
## from - FIXED rects bound once per round, taken slots stay HOLES
func _draw_spread() -> void:
                                if not spread or yard_rects.is_empty():
                                                                return
                                var pulse := 0.5 + 0.5 * sin(_time * 4.0)
                                # v0.3.8-5 THE DRAW ROOM: the yard fan dims the field behind it -
                                # the chain sleeps under a soft scrim while the player picks
                                fx_l.draw_rect(FIELD, Color(0, 0, 0, 0.34 + 0.03 * pulse))
                                for i in yard_rects.size():
                                                                if yard_holes.has(i):
                                                                                                continue    # the hole stays exactly where the tile left
                                                                var r: Rect2 = yard_rects[i]
                                                                _draw_tile_back(fx_l, r)
                                                                fx_l.draw_rect(r.grow(-1.0),
                                                                                                Color(1, 1, 1, 0.05 + 0.05 * pulse), false, 2.0)
                                var hint := "TAP A TILE TO DRAW"
                                var f := ThemeDB.fallback_font
                                var hs := 40
                                var hw2 := f.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hs).x
                                var hx: float = FIELD.get_center().x - hw2 * 0.5
                                var hy: float = (yard_rects[0] as Rect2).position.y - 26.0
                                fx_l.draw_rect(Rect2(hx - 24.0, hy - hs - 10.0, hw2 + 48.0, hs + 22.0),
                                                                Color(0, 0, 0, 0.35 + 0.12 * pulse))
                                fx_l.draw_string(f, Vector2(hx, hy), hint,
                                                                HORIZONTAL_ALIGNMENT_LEFT, -1, hs,
                                                                Color(1, 1, 1, 0.72 + 0.28 * pulse))

func _draw_cpu_hand() -> void:
        # v0.3.8-5 ROUND 2 - THE OPPONENT SEAT (the owner: "why shows CPU - nn
        # under its side, that's pretty useless"): the count label is dead. The
        # studied build speaks STATUS there instead - "Opponent move" while the
        # other side thinks - and that is the only text the seat ever shows.
        for k in hand_c.size():
                if _seat_in_flight(k, "take_c"):
                                continue
                var r: Rect2 = _cpu_slot(hand_c.size(), k)
                _draw_tile_back(table_l, r)
        hand_c_lbl.text = "OPPONENT MOVE" \
                        if (turn == C and state == "play") else ""
func _draw_tile_back(onto: Node2D, r: Rect2) -> void:
        # v0.3.8-5 ROUND 2 - THE REAL BACK (the owner: "the tile back now looks
        # like a YGO card cover ... there is no way you even saw a real domino
        # with that cover"): the studied build's own back - its boneyard rides
        # frame "0.png", a BLANK ivory plate. Shipped as-is; the spinner, the
        # sheen, the painted frame: dead.
        var s := _skin()
        onto.draw_texture_rect(_back_tex(String(s["set"])), r, false)
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
                                # THE TAP TRUTH: the carry arms only past a finger-width of
                                # travel - the tile stays standing in the fan under a wobble
                                if not drag_armed and drag_pos.distance_to(drag_origin) > 18.0:
                                                drag_armed = true
                                                Jukebox.sfx("d_pick", -9.0, 1.05)

func _press(at: Vector2) -> void:
                if state != "play" or turn != P:
                                return
                # v0.3.8-1 THE YARD PICK: the fan is up - a tap on a face-down tile
                # takes THAT tile (the honest manual draw, the owner's design)
                if spread:
                                for i in yard_rects.size():
                                                if yard_holes.has(i):
                                                                continue
                                                if yard_rects[i].grow(6.0).has_point(at):
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
                                                                                drag_armed = false
                                                                                drag_origin = at
                                                                                drag_pos = at
                                                                                Jukebox.sfx("d_pick", -8.0)
                                                else:
                                                                sel = i
                                                                                                                                # v0.3.8-3 THE TAP TRUTH: the first tap only
                                                                                                                                # SELECTS - the tile keeps its seat in the fan
                                                                                                                                # (the old code carried it to the finger the
                                                                                                                                # instant it was tapped: glitchy). The carry
                                                                                                                                # arms only when the finger really drags.
                                                                drag_i = i
                                                                drag = true
                                                                drag_armed = false
                                                                drag_origin = at
                                                                drag_pos = at
                                                                Jukebox.sfx("d_pick", -6.0,
                                                                                1.0 + _rng.randf() * 0.05)
                                                hand_l.queue_redraw()
                                                chain_l.queue_redraw()
                                                return
                # an end slot?
                # v0.3.8-4: the tap seats grow too (the wide catch, both input paths)
                if sel >= 0:
                                if end_l.size.x > 0.0 and end_l.grow(26.0).has_point(at):
                                                _player_play(1)
                                                return
                                if end_r.size.x > 0.0 and end_r.grow(26.0).has_point(at):
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
                # v0.3.8-3: only an ARMED drag drops - a tap (never armed) leaves the
                # tile selected for the tap-tap law, exactly where it stood
                # v0.3.8-4 THE WIDE CATCH (the owner: "when i am close to a place
                # more than my hand or the other place, it refuses to put it, make
                # it detect it from wider range"): the drop hunts BOTH ends by
                # DISTANCE now - the finger's tile lands on the nearest fitting end
                # inside a generous finger-halos radius, no more pixel hunting.
                if drag and drag_armed and drag_i >= 0 and sel == drag_i \
                                                                and drag_i < hand_p.size():
                                var dropped := false
                                var e := ends(chain)
                                var cp := can_play(hand_p[drag_i], e.x, e.y)
                                var drop_at := drag_pos - Vector2(0, bw() * 0.62)
                                var reach: float = maxf(120.0, bw() * 0.9)
                                var best_side := 0
                                var best_d := reach
                                if end_l.size.x > 0.0 and (cp & 1) != 0:
                                                # v0.3.8-5 THE WIDER CATCH: half a tile of slack
                                                var dl: float = _drop_dist(end_l.grow(46.0), drop_at)
                                                if dl < best_d:
                                                                best_d = dl
                                                                best_side = 1
                                if end_r.size.x > 0.0 and (cp & 2) != 0:
                                                var dr: float = _drop_dist(end_r.grow(46.0), drop_at)
                                                if dr < best_d:
                                                                best_d = dr
                                                                best_side = 2
                                if best_side == 1:
                                                _place(P, drag_i, 1, drag_pos)
                                                dropped = true
                                elif best_side == 2:
                                                _place(P, drag_i, 2, drag_pos)
                                                dropped = true
                                drag = false
                                drag_armed = false
                                drag_i = -1
                                if not dropped:
                                                hand_l.queue_redraw()
                                                fx_l.queue_redraw()
                else:
                                drag = false
                                drag_armed = false
                                drag_i = -1

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

## THE PLACEMENT (v0.3.8-3): who plays hand[hi] on side (1 left / 2 right).
## THE NO-GHOST LAW: the chain entry lands as FLYING - it does not paint
## until its flight touches down (the old ghost pre-place drew the domino
## on the felt and then the flight arrived on top of its own body).
## THE SMOOTH FALL: the flight carries the tile STANDING and tips it to
## the horizontal pose as it lands - the real domino fall (doubles stand).
func _place(who: int, hi: int, side: int, from_override = null) -> void:
                var hand: Array = hand_p if who == P else hand_c
                var t: Array = hand[hi]
                var e := ends(chain)
                var fl := false
                var idx := 0
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
                                                "fl": fl, "who": who, "landed": false})
                                idx = 0
                else:
                                var rv := e.y
                                if int(t[1]) == rv and int(t[0]) != rv:
                                                fl = true     # [b|a] puts b (== rv) on the left
                                else:
                                                fl = false
                                chain.append({"a": int(t[0]), "b": int(t[1]),
                                                "fl": fl, "who": who, "landed": false})
                                idx = chain.size() - 1
                # v0.3.8-4 THE ANCHORED SNAKE: the new entry's pose is computed NOW
                # from its side's cursor - the tile will never move again (the old
                # sheet re-flowed the whole snake every placement: tiles slid and
                # switched seats - "the dominoes go down and switch positions by
                # themselves")
                var entry: Dictionary = chain[0] if side == 1 \
                                                else chain[chain.size() - 1]
                if chain.size() == 1:
                                _snake_open(entry)
                else:
                                _snake_place(side, int(t[0]) == int(t[1]), entry)
                # the coin spot in BOARD space, captured BEFORE the reflow - the
                # screen pan moves every tile together, so the race is judged where
                # the tiles actually live (the old screen-space check let the pan
                # steal a coin the domino had honestly landed on)
                var coin_anchor := Vector2.ZERO
                var coin_live := coin_side != 0
                if coin_live:
                                coin_anchor = _end_board.get(coin_side, Vector2.ZERO)
                                if coin_anchor == Vector2.ZERO:
                                                coin_live = false
                # the fly source: the drag's fingertip, the hand seat, or the CPU fan
                var from: Vector2
                if from_override != null:
                                from = from_override
                elif who == C:
                                from = cpu_pos
                elif hi < hand_rects.size():
                                from = hand_rects[hi].get_center()
                else:
                                from = Vector2(get_viewport_rect().size.x * 0.5,
                                                get_viewport_rect().size.y - hw)
                hand.remove_at(hi)
                seen_values[int(t[0])] = int(seen_values.get(int(t[0]), 0)) + 1
                seen_values[int(t[1])] = int(seen_values.get(int(t[1]), 0)) + 1
                pass_streak = 0
                opening = false
                sel = -1
                _relayout()
                var ir: Dictionary
                if chain.size() == 1:
                                ir = chain_rects[0]
                else:
                                ir = chain_rects[0] if side == 1 \
                                                else chain_rects[chain_rects.size() - 1]
                var to: Vector2 = (ir["rect"] as Rect2).get_center()
                # THE FLIGHT TRUTH (v0.3.8-5 ROUND 2, the studied tween law): the
                # ghost carries the EXACT half order that will land (fl-honest) -
                # the old ghost flew the hand order and the dots snapped sideways
                # at touchdown. The tip-over reads honest too: a horizontal landing
                # starts standing (+90deg; the flipped half tips the other way so
                # the left half comes from the top), a vertical landing stands.
                var dbl: bool = int(t[0]) == int(t[1])
                var vert: bool = bool(ir["vertical"])
                var fa: int = int(t[0])
                var fb: int = int(t[1])
                if fl:
                                fa = int(t[1])
                                fb = int(t[0])
                # THE TIP IN THE AIR: every tile flies STANDING and a lying
                # landing tips a quarter turn during the flight (rot 0 ->
                # -PI/2) - the same law the body draw rides, so the ghost
                # hands the pose over seamlessly
                flies.append({"kind": "place", "tile": t, "from": from, "to": to,
                                "rect": ir["rect"] as Rect2, "vert": vert,
                                "fa": fa, "fb": fb,
                                "r0": 0.0,
                                "r1": 0.0 if vert else (-PI * 0.5),
                                "t": 0.0, "dur": 0.42, "idx": idx,
                                "flip": who == C})
                # THE COIN RACE: the tile that lands on the coin spot takes it
                # (judged in BOARD space - the landed pose against the slot anchor)
                if coin_live:
                                var dbl2: bool = int(t[0]) == int(t[1])
                                var horiz2 := absf(Vector2(entry["pdx"], entry["pdy"]).x) > 0.5
                                var along2 := (_tile_short() if dbl2 else _tile_long())
                                var across2 := (_tile_long() if dbl2 else _tile_short())
                                if not horiz2:
                                                var tmp2 := along2
                                                along2 = across2
                                                across2 = tmp2
                                var er := _pose_rect(Vector2(entry["px"], entry["py"]),
                                                Vector2(entry["pdx"], entry["pdy"]), along2, across2)
                                if er.has_point(coin_anchor):
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
                # v0.3.8-6 THE SPIN-FLIP TAKE (the owner's own design: "take the
                # domino from that yard as is with the cover of it, then flip it
                # 360 degrees in the air, while spinning it, fade in the face ...
                # scale that tile then drop it to the hand normally"): slot i IS
                # one tile (bound at deal end), the tapped slot's hole STAYS for
                # the whole round, and the REAL tile flies - back showing, one
                # full spin, the face fades in mid-air. The hand ledger grows AT
                # ONCE (the count laws stay honest) but the flown tile's seat is
                # HIDDEN until touchdown - what lands is THE tile you tapped.
                if not spread or i >= yard_tiles.size():
                                return
                if yard_holes.has(i):
                                return
                var t: Array = yard_tiles[i]
                var di: int = deck.find(t)
                if di < 0:
                                return
                var from: Rect2 = yard_rects[i] if i < yard_rects.size() \
                                else Rect2(pile_pos - Vector2(49, 95), Vector2(98, 190))
                deck.remove_at(di)
                yard_holes[i] = true
                hand_p.append(t)
                cur["drew"] = int(cur.get("drew", 0)) + 1
                Jukebox.sfx("d_draw", -6.0)
                # only the HAND fan re-seats (the yard keeps its holes - no reflow)
                hand_rects = []
                for k in hand_p.size():
                                hand_rects.append(_hand_slot(hand_p.size(), k))
                var seat_i := hand_p.size() - 1
                var seat: Rect2 = hand_rects[seat_i]
                flies.append({"kind": "take_p", "tile": t, "seat_i": seat_i,
                                "from": from.get_center(), "to": seat.get_center(),
                                "from_sz": from.size, "to_sz": seat.size,
                                "t": 0.0, "dur": 0.5})
                _sync_draw_btn()
                chain_l.queue_redraw()
                hand_l.queue_redraw()
                fx_l.queue_redraw()

func _draw_tile(who: int) -> void:
                # v0.3.8-6 THE SLOT-HONEST DIET: every draw - the CPU's too -
                # takes a REAL yard slot (the last intact one, the way players
                # draw from the tail), holes it for the round, and flies the spin.
                # The CPU's tile stays a BACK the whole flight (hidden info). The
                # hand ledger grows at once; the flown seat hides till touchdown.
                if deck.is_empty():
                                _pass(who)
                                return
                var slot := -1
                for i in range(yard_tiles.size() - 1, -1, -1):
                                if not yard_holes.has(i) and deck.has(yard_tiles[i]):
                                                slot = i
                                                break
                var t: Array
                var from_r := Rect2(pile_pos - Vector2(49, 95), Vector2(98, 190))
                if slot >= 0:
                                t = yard_tiles[slot]
                                from_r = yard_rects[slot]
                                yard_holes[slot] = true
                else:
                                t = deck.pop_back()
                deck.erase(t)
                var hand: Array = hand_p if who == P else hand_c
                hand.append(t)
                if who == P:
                                cur["drew"] = int(cur.get("drew", 0)) + 1
                                Jukebox.sfx("d_draw", -6.0)
                                _sync_draw_btn()
                else:
                                Jukebox.sfx("d_draw", -9.0, 0.9)
                var seat_i := hand.size() - 1
                if who == P:
                                _relayout()
                                flies.append({"kind": "take_p", "tile": t, "seat_i": seat_i,
                                                "from": from_r.get_center(),
                                                "to": (hand_rects[seat_i] as Rect2).get_center(),
                                                "from_sz": from_r.size,
                                                "to_sz": (hand_rects[seat_i] as Rect2).size,
                                                "t": 0.0, "dur": 0.5})
                else:
                                var seatc := _cpu_slot(hand_c.size(), seat_i)
                                flies.append({"kind": "take_c", "tile": t, "seat_i": seat_i,
                                                "from": from_r.get_center(),
                                                "to": seatc.get_center(),
                                                "from_sz": from_r.size, "to_sz": seatc.size,
                                                "t": 0.0, "dur": 0.42})
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
                # THE DEAL (v0.3.8-3 THE COLLECT THEATER): the tiles LEAVE THE YARD
                # one by one - every tile flies from the boneyard stack to its fan
                # seat (the player's face up, the CPU's face down) and CLACKS as it
                # lands. The hands grow flight by flight; nothing blinks in.
                if state != "ready":
                                state = "deal"
                                deal_i = 0
                                _deal_p = 0
                                _deal_c = 0
                                deal_beat = 0.0
                                turn_lbl.text = "THE DEAL"
                                turn_lbl.add_theme_color_override("font_color",
                                                Color(1, 1, 1, 0.9))
                _relayout()

func _finish_deal() -> void:
                # v0.3.8-6 THE ROUND-HONEST YARD: the 14 leftover tiles bind to
                # their 14 seats NOW - same dominoes, same positions, the whole
                # round. Two centered rows of HAND-SIZE tiles (the owner: "the
                # size of tile from bone yard is near or same to in-hand").
                yard_tiles = deck.duplicate()
                yard_holes = {}
                yard_rects = []
                var sw := hw * 0.5
                var sh := hw
                var cnt := yard_tiles.size()
                var rows := 2
                var per := int(ceil(float(cnt) / float(rows)))
                var gapw := 14.0
                var row_gap := 22.0
                var step := sw + gapw
                var roww := step * (per - 1) + sw
                var sx := FIELD.get_center().x - roww * 0.5
                var totalh := rows * sh + (rows - 1) * row_gap
                var sy := FIELD.get_center().y - totalh * 0.5
                for i in cnt:
                                var rr := i / per
                                var cc := i % per
                                yard_rects.append(Rect2(Vector2(sx + cc * step,
                                                sy + rr * (sh + row_gap)), Vector2(sw, sh)))
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
                # THE LANDING: a flight that touches down speaks its kind - a deal
                # tile joins its hand (the fan re-fans around it), a place tile
                # PAINTS into the chain with its clack
                for f in flies.duplicate():
                                if float(f["t"]) >= float(f["dur"]):
                                                _fly_landed(f)
                                                flies.erase(f)
                # v0.3.8-5 THE SMOOTH GROUP LAW: the zoom glides, never jumps -
                # while it travels, every chain rect + end slot follows per frame
                if _glide:
                                _fit_scale = lerpf(_fit_scale, _fit_target,
                                                minf(1.0, delta * 7.5))
                                if absf(_fit_target - _fit_scale) < 0.002:
                                                _fit_scale = _fit_target
                                                _glide = false
                                _relayout_chain_rects()
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
                                # v0.3.8-3 THE COLLECT THEATER: each beat LAUNCHES one tile
                                # from the yard - the player's face up, the CPU's back - and
                                # the flight lands it in its seat (see _fly_landed)
                                if deal_beat >= 0.16 and deal_i < HAND_N * 2:
                                                deal_beat = 0.0
                                                var t: Array = deck.pop_back()
                                                # v0.3.8-6 THE DEAL THEATER: every dealt tile LEAVES THE
                                                # PILE AS-IS (back showing) and flips through the air - a full
                                                # spin, the player's face fading in mid-air, the CPU's back
                                                # staying secret - landing in its seat with a clack.
                                                if deal_i % 2 == 0:
                                                                var seatp := _hand_slot(HAND_N, _deal_p)
                                                                flies.append({"kind": "deal_p", "tile": t,
                                                                                "from": pile_pos,
                                                                                "to": seatp.get_center(),
                                                                                "from_sz": Vector2(98, 190),
                                                                                "to_sz": seatp.size,
                                                                                "t": 0.0, "dur": 0.42})
                                                                _deal_p += 1
                                                else:
                                                                var seatc := _cpu_slot(HAND_N, _deal_c)
                                                                flies.append({"kind": "deal_c", "tile": t,
                                                                                "from": pile_pos,
                                                                                "to": seatc.get_center(),
                                                                                "from_sz": Vector2(98, 190),
                                                                                "to_sz": seatc.size,
                                                                                "t": 0.0, "dur": 0.42})
                                                                _deal_c += 1
                                                deal_i += 1
                                                Jukebox.sfx("d_draw", -15.0, 1.1 - 0.012 * deal_i)
                                                _relayout()
                                # the deal is done when every launched tile has LANDED
                                if deal_i >= HAND_N * 2 and flies.is_empty():
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

## THE LANDING PAD: a finished flight speaks its kind. Deal tiles JOIN
## their hands here (with the clack), place tiles PAINT into the chain.
func _fly_landed(f: Dictionary) -> void:
                match String(f.get("kind", "")):
                                "deal_p":
                                                hand_p.append(f["tile"])
                                                _relayout()
                                                Jukebox.sfx("d_place", -11.0,
                                                                                1.15 + _rng.randf() * 0.1)
                                "deal_c":
                                                hand_c.append(f["tile"])
                                                _relayout()
                                                Jukebox.sfx("d_place", -14.0,
                                                                                0.92 + _rng.randf() * 0.08)
                                "place":
                                                var idx: int = int(f.get("idx", -1))
                                                if idx >= 0 and idx < chain.size():
                                                                chain[idx]["landed"] = true
                                                Jukebox.sfx("d_place", -4.0,
                                                                                0.96 + _rng.randf() * 0.08)
                                                shake_t = maxf(shake_t, 0.12)
                                "take_p":
                                                # the spin-flip touched down - the seat shows its tile
                                                Jukebox.sfx("d_place", -11.0, 1.15 + _rng.randf() * 0.1)
                                "take_c":
                                                Jukebox.sfx("d_place", -14.0, 0.92 + _rng.randf() * 0.08)
                                _:
                                                pass    # legacy flights already spoke at take

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
                yard_rects = []
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
