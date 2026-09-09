extends GogaGame
## CHECKMATE - v0.3.8: the old war, rebuilt for the box (the SOON teaser
## "CHECKMATE / the old war" graduates).
##
## Owner contract (v0.3.8):
##   - HORIZONTAL only (landscape)
##   - full LEGAL chess - the owner: "i know nothing, make sure to make
##     them correct": every piece moves by the book, castling with all its
##     conditions, en passant, promotion (a picker, all four), check,
##     checkmate, stalemate, the 50-move rule, threefold repetition and
##     insufficient material are ALL live
##   - scoring: each WIN +1, each LOSS -1 (the score never goes negative),
##     a DRAW 0; run bonus /1 (registry coin_div 1)
##   - ONE GOGACoin after each 3 MINUTES of play, on a legal reachable
##     square - whoever lands a piece on it takes it (the CPU races you)
##   - the CPU: SIX profiles with their own OPENING BOOKS (the chess.com
##     study: every personality carries its own book - starter / aggressor /
##     jobava (the London the owner named) / trickster / royal / flanker),
##     each with real programmed failures (the xo law: "good but has real
##     programmed failures to give the user a way to win") and the 2-round
##     adaptive memory: repeat an opening and the burned reply varies, play
##     hyper-aggressive and the safe moods tighten up. Profiles rotate
##     invisibly - one name: CPU.
##   - highlights: the selected piece rings, legal targets dot the board,
##     captures ring their square, the last move stays tinted, a checked
##     king glows red; smooth slides, capture poofs, SFX everywhere
##   - themes (boards) + skins (piece sets) live DIRECTLY in the shop,
##     everything except the defaults is BOUGHT
##
## Probe contract: the whole engine is STATIC - start_state/legal_moves/
## make_move/status/eval/cpu_move drive headless law checks without the
## scene (perft-style counts pinned below).

# ------------------------------------------------------------- the economy
const COIN_EVERY_S := 180.0   # owner: one GOGACoin each 3 minutes
const MEM_ROUNDS := 2         # the xo memory law

# ------------------------------------------------------------- the shop
const SETS := {
        "classic": {"name": "CLASSIC", "price": 0,
                "desc": "cream vs charcoal"},
        "minimal": {"name": "MINIMAL", "price": 180,
                "desc": "the flat geometric set"},
        "bold": {"name": "BOLD", "price": 260,
                "desc": "thick lines, heavy base"},
        "royal": {"name": "ROYAL", "price": 340,
                "desc": "gilded with gems"},
}
const BOARDS := {
        "walnut": {"name": "WALNUT", "price": 0,
                "light": Color("f0d9b5"), "dark": Color("b58863"),
                "frame": Color("6b4a2e"), "hlight": Color(0.4, 0.7, 0.4, 0.45),
                "desc": "the classic wood"},
        "forest": {"name": "FOREST", "price": 220,
                "light": Color("e8e2c9"), "dark": Color("6e8b5e"),
                "frame": Color("3d5233"), "hlight": Color(0.9, 0.85, 0.3, 0.4),
                "desc": "moss and birch"},
        "marble": {"name": "MARBLE", "price": 280,
                "light": Color("dfe3ea"), "dark": Color("7a8699"),
                "frame": Color("3a4353"), "hlight": Color(0.3, 0.6, 1.0, 0.4),
                "desc": "cold polished stone"},
        "neon": {"name": "NEON", "price": 320,
                "light": Color("2a2f45"), "dark": Color("171b2c"),
                "frame": Color("0d1020"), "hlight": Color(0.2, 0.9, 1.0, 0.45),
                "desc": "the grid at night"},
}

# ------------------------------------------------------------- the profiles
## SIX MOODS (the owner: "make many profiles that chosen randomly to make
## the game feel different every time"). Books are public opening theory,
## written as full coordinate-move lines; the brain walks its line while
## the game stays on it, then thinks for itself. depth = search depth,
## qcap = capture-chase cap, miss = the chance the BEST move is skipped
## (real programmed failures), noise = root score jitter.
const PROFILES := {
        "starter": {
                "book": [
                        ["e2e4", "e7e5", "g1f3", "b8c6", "f1b5", "g8f6"],
                        ["e2e4", "e7e5", "g1f3", "b8c6", "f1c4", "f8c5"],
                        ["d2d4", "d7d5", "c2c4", "e7e6", "b1c3", "g8f6"],
                ],
                "depth": 2, "qcap": 2, "miss": 0.10, "noise": 40.0,
                "aggr": 0.5, "safety": 1.0,
        },
        "aggressor": {
                "book": [
                        ["e2e4", "e7e5", "g1f3", "b8c6", "d2d4", "e5d4",
                                "f3d4", "g8f6"],
                        ["e2e4", "e7e5", "f2f4", "e5f4", "g1f3", "g7g5"],
                        ["e2e4", "c7c5", "g1f3", "d7d6", "d2d4", "c5d4"],
                ],
                "depth": 2, "qcap": 3, "miss": 0.12, "noise": 55.0,
                "aggr": 0.9, "safety": 0.5,
        },
        "jobava": {
                "book": [
                        ["d2d4", "d7d5", "b1c3", "g8f6", "c1f4", "e7e6"],
                        ["d2d4", "g8f6", "b1c3", "d7d5", "c1f4", "e7e6"],
                        ["d2d4", "d7d5", "b1c3", "c7c6", "c1f4", "b8d7"],
                ],
                "depth": 2, "qcap": 2, "miss": 0.11, "noise": 48.0,
                "aggr": 0.8, "safety": 0.7,
        },
        "trickster": {
                "book": [
                        ["d2d4", "g8f6", "c1g5", "e7e6", "e2e4", "f8b4"],
                        ["g1f3", "d7d5", "g2g3", "g8f6", "f1g2", "e7e6"],
                        ["e2e4", "e7e6", "d2d4", "d7d5", "b1c3", "g8f6"],
                ],
                "depth": 2, "qcap": 2, "miss": 0.14, "noise": 62.0,
                "aggr": 0.7, "safety": 0.6,
        },
        "royal": {
                "book": [
                        ["d2d4", "g8f6", "c2c4", "e7e6", "b1c3", "b7b6",
                                "e2e4", "c8b7"],
                        ["d2d4", "d7d5", "c2c4", "e7e6", "b1c3", "g8f6",
                                "g1f3", "f8e7"],
                        ["g1f3", "g8f6", "c2c4", "e7e6", "b1c3", "d7d5"],
                ],
                # depth 2 + a deeper quiescence: the same quiet-strength
                # feel at a phone-safe cost (the 3s law lives in the probe)
                "depth": 2, "qcap": 4, "miss": 0.08, "noise": 30.0,
                "aggr": 0.4, "safety": 1.2,
        },
        "flanker": {
                "book": [
                        ["c2c4", "e7e5", "b1c3", "g8f6", "g1f3", "b8c6"],
                        ["c2c4", "g8f6", "b1c3", "e7e6", "g1f3", "d7d5"],
                        ["c2c4", "c7c5", "g1f3", "b8c6"],
                ],
                "depth": 2, "qcap": 4, "miss": 0.09, "noise": 34.0,
                "aggr": 0.3, "safety": 1.1,
        },
}

# ============================================================ STATIC ENGINE
## Board: Array[64], index = rank * 8 + file, a1 = 0, h8 = 63.
## Pieces: P N B R Q K = 1..6, white positive, black negative.
## State: {b, w (white to move), cr (castling bits 1 WK 2 WQ 4 BK 8 BQ),
##         ep (en-passant target square or -1), half, full, hist: []}

const P_VALS := [0, 100, 305, 315, 500, 900, 0]

## piece-square tables (mine, written from the classic shapes) - from
## white's view, index 0 = a1 (BOTTOM-UP: row 0 = white's back rank)
const PST_P := [
        0, 0, 0, 0, 0, 0, 0, 0,
        5, 10, 10, -20, -20, 10, 10, 5,
        5, -5, -10, 0, 0, -10, -5, 5,
        0, 0, 0, 20, 20, 0, 0, 0,
        5, 5, 10, 25, 25, 10, 5, 5,
        10, 10, 20, 30, 30, 20, 10, 10,
        50, 50, 50, 50, 50, 50, 50, 50,
        0, 0, 0, 0, 0, 0, 0, 0,
]
const PST_N := [
        -40, -28, -20, -20, -20, -20, -28, -40,
        -28, -12, 0, 2, 2, 0, -12, -28,
        -20, 4, 12, 16, 16, 12, 4, -20,
        -20, 2, 16, 20, 20, 16, 2, -20,
        -20, 2, 16, 20, 20, 16, 2, -20,
        -20, 4, 12, 16, 16, 12, 4, -20,
        -28, -12, 0, 2, 2, 0, -12, -28,
        -40, -28, -20, -20, -20, -20, -28, -40,
]
const PST_B := [
        -14, -8, -8, -8, -8, -8, -8, -14,
        -8, 2, 0, 0, 0, 0, 2, -8,
        -8, 4, 6, 8, 8, 6, 4, -8,
        -8, 0, 8, 10, 10, 8, 0, -8,
        -8, 4, 8, 10, 10, 8, 4, -8,
        -8, 6, 4, 8, 8, 4, 6, -8,
        -8, 6, 2, 0, 0, 2, 6, -8,
        -14, -8, -8, -12, -12, -8, -8, -14,
]
const PST_R := [
        0, 0, 2, 4, 4, 2, 0, 0,
        8, 12, 12, 12, 12, 12, 12, 8,
        -2, 0, 0, 0, 0, 0, 0, -2,
        -2, 0, 0, 0, 0, 0, 0, -2,
        -2, 0, 0, 0, 0, 0, 0, -2,
        -2, 0, 0, 0, 0, 0, 0, -2,
        -2, 2, 4, 6, 6, 4, 2, -2,
        -4, 0, 4, 10, 10, 4, 0, -4,
]
const PST_Q := [
        -12, -6, -6, -4, -4, -6, -6, -12,
        -6, 0, 0, 0, 0, 0, 0, -6,
        -6, 0, 4, 4, 4, 4, 0, -6,
        -4, 0, 4, 4, 4, 4, 0, -4,
        -4, 0, 4, 4, 4, 4, 0, -4,
        -6, 2, 4, 4, 4, 4, 2, -6,
        -6, 0, 2, 0, 0, 2, 0, -6,
        -12, -6, -6, -4, -4, -6, -6, -12,
]
const PST_K := [
        -40, -46, -46, -52, -52, -46, -46, -40,
        -40, -46, -46, -52, -52, -46, -46, -40,
        -40, -46, -46, -52, -52, -46, -46, -40,
        -34, -40, -40, -46, -46, -40, -40, -34,
        -22, -30, -30, -34, -34, -30, -30, -22,
        -10, -16, -12, -22, -22, -12, -16, -10,
        16, 18, -2, -8, -8, -2, 18, 16,
        18, 26, 12, -8, 0, 8, 30, 18,
]

static func start_state() -> Dictionary:
        var b := []
        for i in 64:
                b.append(0)
        var back := [4, 2, 3, 5, 6, 3, 2, 4]
        for f in 8:
                b[8 + f] = 1                 # white pawns
                b[48 + f] = -1               # black pawns
                b[f] = back[f]               # white back rank
                b[56 + f] = -back[f]         # black back rank
        return {"b": b, "w": true, "cr": 15, "ep": -1, "half": 0,
                "full": 1, "hist": []}

static func inside(f: int, r: int) -> bool:
        return f >= 0 and f < 8 and r >= 0 and r < 8

static func sq(f: int, r: int) -> int:
        return r * 8 + f

## is `target` attacked by the side `by_white`?
static func attacks(b: Array, target: int, by_white: bool) -> bool:
        var tf := target % 8
        var tr := target / 8
        var sgn := 1 if by_white else -1
        # pawns
        var pr := tr - sgn
        for df in [-1, 1]:
                if inside(tf + df, pr) and b[sq(tf + df, pr)] == sgn * 1:
                        return true
        # knights
        for off in [[-2, -1], [-2, 1], [-1, -2], [-1, 2],
                        [1, -2], [1, 2], [2, -1], [2, 1]]:
                if inside(tf + off[0], tr + off[1]) \
                                and b[sq(tf + off[0], tr + off[1])] == sgn * 2:
                        return true
        # king
        for df in [-1, 0, 1]:
                for dr in [-1, 0, 1]:
                        if df == 0 and dr == 0:
                                continue
                        if inside(tf + df, tr + dr) \
                                        and b[sq(tf + df, tr + dr)] == sgn * 6:
                                return true
        # sliders
        for d in [[-1, 0], [1, 0], [0, -1], [0, 1]]:
                var f: int = tf + d[0]
                var r: int = tr + d[1]
                while inside(f, r):
                        var v: int = b[sq(f, r)]
                        if v != 0:
                                if v == sgn * 4 or v == sgn * 5:
                                        return true
                                break
                        f += d[0]
                        r += d[1]
        for d in [[-1, -1], [-1, 1], [1, -1], [1, 1]]:
                var f2: int = tf + d[0]
                var r2: int = tr + d[1]
                while inside(f2, r2):
                        var v2: int = b[sq(f2, r2)]
                        if v2 != 0:
                                if v2 == sgn * 3 or v2 == sgn * 5:
                                        return true
                                break
                        f2 += d[0]
                        r2 += d[1]
        return false

static func king_sq(b: Array, white: bool) -> int:
        var k := 6 if white else -6
        for i in 64:
                if int(b[i]) == k:
                        return i
        return -1

## every pseudo-legal move for the side to move
static func gen_pseudo(st: Dictionary) -> Array:
        var b: Array = st["b"]
        var white: bool = st["w"]
        var sgn := 1 if white else -1
        var out: Array = []
        for i in 64:
                var v: int = b[i]
                if v == 0 or (v > 0) != white:
                        continue
                var f := i % 8
                var r := i / 8
                var pt := absi(v)
                if pt == 1:      # pawn
                        var dr := 1 if white else -1
                        var start_r := 1 if white else 6
                        var last_r := 7 if white else 0
                        # pushes
                        if inside(f, r + dr) and b[sq(f, r + dr)] == 0:
                                if r + dr == last_r:
                                        for promo in [5, 2, 4, 3]:
                                                out.append({"f": i,
                                                        "t": sq(f, r + dr),
                                                        "promo": promo,
                                                        "flag": ""})
                                else:
                                        out.append({"f": i, "t": sq(f, r + dr),
                                                "promo": 0, "flag": ""})
                                if r == start_r \
                                                and b[sq(f, r + 2 * dr)] == 0:
                                        out.append({"f": i,
                                                "t": sq(f, r + 2 * dr),
                                                "promo": 0, "flag": "double"})
                        # captures
                        for df in [-1, 1]:
                                if not inside(f + df, r + dr):
                                        continue
                                var ti: int = sq(f + df, r + dr)
                                var tv: int = b[ti]
                                if tv != 0 and (tv > 0) != white:
                                        if r + dr == last_r:
                                                for promo in [5, 2, 4, 3]:
                                                        out.append({"f": i,
                                                                "t": ti,
                                                                "promo": promo,
                                                                "flag": ""})
                                        else:
                                                out.append({"f": i, "t": ti,
                                                        "promo": 0,
                                                        "flag": ""})
                                elif tv == 0 and ti == int(st["ep"]):
                                        out.append({"f": i, "t": ti,
                                                "promo": 0, "flag": "ep"})
                elif pt == 2:    # knight
                        for off in [[-2, -1], [-2, 1], [-1, -2], [-1, 2],
                                        [1, -2], [1, 2], [2, -1], [2, 1]]:
                                if not inside(f + off[0], r + off[1]):
                                        continue
                                var ti2: int = sq(f + off[0], r + off[1])
                                var tv2: int = b[ti2]
                                if tv2 == 0 or (tv2 > 0) != white:
                                        out.append({"f": i, "t": ti2,
                                                "promo": 0, "flag": ""})
                elif pt == 6:    # king
                        for df in [-1, 0, 1]:
                                for dr2 in [-1, 0, 1]:
                                        if df == 0 and dr2 == 0:
                                                continue
                                        if not inside(f + df, r + dr2):
                                                continue
                                        var ti3: int = sq(f + df, r + dr2)
                                        var tv3: int = b[ti3]
                                        if tv3 == 0 or (tv3 > 0) != white:
                                                out.append({"f": i, "t": ti3,
                                                        "promo": 0,
                                                        "flag": ""})
                        # castling
                        var cr: int = st["cr"]
                        if white and i == 4:
                                if (cr & 1) != 0 and b[5] == 0 and b[6] == 0 \
                                                and not attacks(b, 4, false) \
                                                and not attacks(b, 5, false) \
                                                and not attacks(b, 6, false):
                                        out.append({"f": i, "t": 6,
                                                "promo": 0, "flag": "castle"})
                                if (cr & 2) != 0 and b[3] == 0 and b[2] == 0 \
                                                and b[1] == 0 \
                                                and not attacks(b, 4, false) \
                                                and not attacks(b, 3, false) \
                                                and not attacks(b, 2, false):
                                        out.append({"f": i, "t": 2,
                                                "promo": 0, "flag": "castle"})
                        elif not white and i == 60:
                                if (cr & 4) != 0 and b[61] == 0 \
                                                and b[62] == 0 \
                                                and not attacks(b, 60, true) \
                                                and not attacks(b, 61, true) \
                                                and not attacks(b, 62, true):
                                        out.append({"f": i, "t": 62,
                                                "promo": 0, "flag": "castle"})
                                if (cr & 8) != 0 and b[59] == 0 \
                                                and b[58] == 0 and b[57] == 0 \
                                                and not attacks(b, 60, true) \
                                                and not attacks(b, 59, true) \
                                                and not attacks(b, 58, true):
                                        out.append({"f": i, "t": 58,
                                                "promo": 0, "flag": "castle"})
                else:            # sliders
                        var dirs: Array = []
                        match pt:
                                3: dirs = [[-1, -1], [-1, 1], [1, -1],
                                                [1, 1]]
                                4: dirs = [[-1, 0], [1, 0], [0, -1], [0, 1]]
                                5: dirs = [[-1, -1], [-1, 1], [1, -1],
                                                [1, 1], [-1, 0], [1, 0],
                                                [0, -1], [0, 1]]
                        for d in dirs:
                                var f2: int = f + d[0]
                                var r2: int = r + d[1]
                                while inside(f2, r2):
                                        var ti4: int = sq(f2, r2)
                                        var tv4: int = b[ti4]
                                        if tv4 == 0:
                                                out.append({"f": i, "t": ti4,
                                                        "promo": 0, "flag": ""})
                                        else:
                                                if (tv4 > 0) != white:
                                                        out.append({"f": i,
                                                                "t": ti4,
                                                                "promo": 0,
                                                                "flag": ""})
                                                break
                                        f2 += d[0]
                                        r2 += d[1]
        return out

## copy-make: returns the NEW state after m
static func make_move(st: Dictionary, m: Dictionary) -> Dictionary:
        var b: Array = (st["b"] as Array).duplicate()
        var white: bool = st["w"]
        var f: int = m["f"]
        var t: int = m["t"]
        var flag: String = m["flag"]
        var v: int = b[f]
        var new_ep := -1
        var half: int = int(st["half"]) + 1
        # captures reset the clock
        if b[t] != 0:
                half = 0
        if absi(v) == 1:
                half = 0
                if flag == "double":
                        new_ep = f + (8 if white else -8)
                if flag == "ep":
                        # the captured pawn sits beside the target
                        b[t + (-8 if white else 8)] = 0
        b[t] = v
        b[f] = 0
        if int(m["promo"]) > 0:
                b[t] = int(m["promo"]) if white else -int(m["promo"])
        if flag == "castle":
                if t == 6:
                        b[5] = b[7]
                        b[7] = 0
                elif t == 2:
                        b[3] = b[0]
                        b[0] = 0
                elif t == 62:
                        b[61] = b[63]
                        b[63] = 0
                elif t == 58:
                        b[59] = b[56]
                        b[56] = 0
        # castling rights die when the king or a rook moves
        var cr: int = st["cr"]
        if v == 6:
                cr &= ~(1 | 2)
        elif v == -6:
                cr &= ~(4 | 8)
        if f == 0 or t == 0:
                cr &= ~2
        if f == 7 or t == 7:
                cr &= ~1
        if f == 56 or t == 56:
                cr &= ~8
        if f == 63 or t == 63:
                cr &= ~4
        var full: int = int(st["full"])
        if not white:
                full += 1
        var hist: Array = st["hist"].duplicate()
        hist.append({"f": f, "t": t})
        return {"b": b, "w": not white, "cr": cr, "ep": new_ep, "half": half,
                "full": full, "hist": hist}

static func legal_moves(st: Dictionary) -> Array:
        var out: Array = []
        var white: bool = st["w"]
        for m in gen_pseudo(st):
                var st2 := make_move(st, m)
                var ks := king_sq(st2["b"], white)
                if ks < 0:
                        continue
                if not attacks(st2["b"], ks, not white):
                        out.append(m)
        return out

static func in_check(st: Dictionary) -> bool:
        var ks := king_sq(st["b"], st["w"])
        if ks < 0:
                return false
        return attacks(st["b"], ks, not st["w"])

## the position key for threefold repetition
static func pos_key(st: Dictionary) -> String:
        var s := ""
        for i in 64:
                s += "%d," % int(st["b"][i])
        return s + "|%d|%d|%d" % [1 if st["w"] else 0, int(st["cr"]),
                int(st["ep"])]

## the game status: play | checkmate | stalemate | draw50 | draw3 | drawmat
static func status(st: Dictionary, key_counts: Dictionary) -> String:
        if legal_moves(st).is_empty():
                return "checkmate" if in_check(st) else "stalemate"
        if int(st["half"]) >= 100:
                return "draw50"
        var k := pos_key(st)
        key_counts[k] = int(key_counts.get(k, 0)) + 1
        if int(key_counts[k]) >= 3:
                return "draw3"
        # insufficient material
        var minors := 0
        var other := 0
        for v in st["b"]:
            var vv := int(v)
            if vv == 0 or absi(vv) == 6:
                    continue
            if absi(vv) == 2 or absi(vv) == 3:
                    minors += 1
            else:
                    other += 1
        if other == 0 and minors <= 1:
                return "drawmat"
        return "play"

## the eval: material + piece-square + a pawn-shield whisper, from the
## side-to-move's view
static func eval_pos(st: Dictionary, safety_w: float) -> int:
        var b: Array = st["b"]
        var s := 0
        for i in 64:
                var v: int = b[i]
                if v == 0:
                        continue
                var pt := absi(v)
                var idx := i if v > 0 else (56 - 8 * (i / 8) + (i % 8))
                var pst := 0
                match pt:
                        1: pst = PST_P[idx]
                        2: pst = PST_N[idx]
                        3: pst = PST_B[idx]
                        4: pst = PST_R[idx]
                        5: pst = PST_Q[idx]
                        6: pst = PST_K[idx]
                if v > 0:
                        s += P_VALS[pt] + pst
                else:
                        s -= P_VALS[pt] + pst
        # the pawn shield (king safety, weighted by the profile)
        var wk := king_sq(b, true)
        var bk := king_sq(b, false)
        if wk >= 0:
                var wf := wk % 8
                var wr := wk / 8
                for df in [-1, 0, 1]:
                        if inside(wf + df, wr + 1) \
                                        and b[sq(wf + df, wr + 1)] == 1:
                                s += int(10 * safety_w)
        if bk >= 0:
                var bf := bk % 8
                var br := bk / 8
                for df in [-1, 0, 1]:
                        if inside(bf + df, br - 1) \
                                        and b[sq(bf + df, br - 1)] == -1:
                                s -= int(10 * safety_w)
        return s if st["w"] else -s

static func _order_moves(moves: Array, b: Array) -> Array:
        # MVV-LVA: the juiciest, least-costly captures first
        var scored: Array = []
        for m in moves:
                var sc := 0
                var victim: int = absi(int(b[m["t"]]))
                var attacker: int = absi(int(b[m["f"]]))
                if victim > 0:
                        sc = 1000 + P_VALS[victim] * 10 - P_VALS[attacker]
                if int(m["promo"]) > 0:
                        sc += 800
                scored.append({"sc": sc, "i": scored.size(), "m": m})
        scored.sort_custom(func(a, c): return int(a["sc"]) > int(c["sc"]))
        var out: Array = []
        for e in scored:
                out.append(e["m"])
        return out

## quiescence: chase captures only (the horizon guard)
static func quiesce(st: Dictionary, alpha: int, beta: int, cap: int,
                safety_w: float) -> int:
        var stand := eval_pos(st, safety_w)
        if stand >= beta:
                return beta
        if stand > alpha:
                alpha = stand
        if cap <= 0:
                return alpha
        var caps: Array = []
        for m in gen_pseudo(st):
                if int(st["b"][m["t"]]) != 0 or m["flag"] == "ep":
                        caps.append(m)
        for m in _order_moves(caps, st["b"]):
                var st2 := make_move(st, m)
                var ks := king_sq(st2["b"], st["w"])
                if attacks(st2["b"], ks, not st["w"]):
                        continue
                var sc := -quiesce(st2, -beta, -alpha, cap - 1, safety_w)
                if sc >= beta:
                        return beta
                if sc > alpha:
                        alpha = sc
        return alpha

static func negamax(st: Dictionary, depth: int, alpha: int, beta: int,
                qcap: int, safety_w: float) -> int:
        if depth <= 0:
                return quiesce(st, alpha, beta, qcap, safety_w)
        var moves := legal_moves(st)
        if moves.is_empty():
                return -100000 - depth if in_check(st) else 0
        for m in _order_moves(moves, st["b"]):
                var st2 := make_move(st, m)
                var sc := -negamax(st2, depth - 1, -beta, -alpha, qcap,
                        safety_w)
                if sc >= beta:
                        return beta
                if sc > alpha:
                        alpha = sc
        return alpha

## THE MEMORY LAW (the xo 2-round window) - openings, aggression
static func remember(mem_in: Array, record: Dictionary) -> Array:
        var m := mem_in.duplicate()
        m.append({
                "open": String(record.get("open", "")),
                "aggr": float(record.get("aggr", 0.0)),
                "result": int(record.get("result", 0)),
        })
        while m.size() > MEM_ROUNDS:
                m.pop_front()
        return m

## repeat an opening and the burned book line varies; a hyper-aggressive
## player meets tighter safety
static func adapt(mem_in: Array) -> Dictionary:
        var out := {"burned": "", "tighten": 0.0}
        if mem_in.size() >= 2:
                var a: String = mem_in[0]["open"]
                var b: String = mem_in[1]["open"]
                if a != "" and a == b:
                        out["burned"] = a
                for e in mem_in:
                        out["tighten"] += clampf(float(e["aggr"]) - 0.5, 0.0,
                                0.5)
        return out

## THE CPU MOVE (root): the book first, then the search with the profile's
## programmed failures. history = the game's move list (coordinate strings).
static func cpu_move(st: Dictionary, profile_id: String, history: Array,
                mem: Array, rng: RandomNumberGenerator) -> Dictionary:
        var p: Dictionary = PROFILES[profile_id]
        var flags := adapt(mem)
        # 1. THE BOOK: continue a line that matches, but never a burned one
        if history.size() < 8:
                var candidates: Array = []
                for line in p["book"]:
                        var fit := true
                        for i in history.size():
                                if i >= line.size() or String(line[i]) \
                                                != String(history[i]):
                                        fit = false
                                        break
                        if fit and history.size() < line.size():
                                if flags["burned"] != "" \
                                                and String(line[0]) \
                                                == String(flags["burned"]) \
                                                and rng.randf() < 0.7:
                                        continue     # the burned line varies
                                candidates.append(String(line[history.size()]))
                if not candidates.is_empty():
                        var pick: String = candidates[rng.randi() \
                                % candidates.size()]
                        for m in legal_moves(st):
                                if coord_of(m) == pick:
                                        return m
        # 2. THE SEARCH: every legal move scored, misses and noise applied
        var moves := legal_moves(st)
        if moves.is_empty():
                return {}
        var scored: Array = []
        var depth := int(p["depth"])
        var safety := float(p["safety"]) + float(flags["tighten"]) * 0.5
        for m in moves:
                var st2 := make_move(st, m)
                var sc := -negamax(st2, depth - 1, -200000, 200000,
                        int(p["qcap"]), safety)
                sc += int(rng.randf_range(-float(p["noise"]),
                        float(p["noise"])))
                scored.append({"m": m, "sc": sc})
        scored.sort_custom(func(a, c): return int(a["sc"]) > int(c["sc"]))
        # THE MISS LAW: the best move is skipped with the profile's chance
        if scored.size() > 2 and rng.randf() < float(p["miss"]):
                scored.pop_front()
        return scored[0]["m"]

## coordinate notation ("e2e4", promotions "e7e8q")
static func coord_of(m: Dictionary) -> String:
        var files := "abcdefgh"
        var f: int = m["f"]
        var t: int = m["t"]
        var s := "%s%d%s%d" % [files[f % 8], f / 8 + 1, files[t % 8],
                t / 8 + 1]
        if int(m["promo"]) > 0:
                s += "pnbrqk"[int(m["promo"]) - 1] if int(m["promo"]) <= 5 \
                        else "q"
        return s

## short algebraic for the move log ("Nf3", "exd5", "O-O", "e8=Q+")
static func move_name(st: Dictionary, m: Dictionary) -> String:
        var files := "abcdefgh"
        var b: Array = st["b"]
        var v: int = b[m["f"]]
        var pt := absi(v)
        var captured: bool = int(b[m["t"]]) != 0 or m["flag"] == "ep"
        var names := "  NBRQK"
        if m["flag"] == "castle":
                return "O-O" if int(m["t"]) % 8 == 6 else "O-O-O"
        var s := ""
        if pt == 1:
                if captured:
                        s += files[m["f"] % 8] + "x"
                s += files[m["t"] % 8] + str(m["t"] / 8 + 1)
                if int(m["promo"]) > 0:
                        s += "=" + names[int(m["promo"])]
        else:
                s += names[pt]
                if captured:
                        s += "x"
                s += files[m["t"] % 8] + str(m["t"] / 8 + 1)
        var st2 := make_move(st, m)
        if in_check(st2):
                s += "#" if status(st2, {}).begins_with("checkmate") else "+"
        return s

# ============================================================ the profiles
## THE MOODS (the xo law: one opponent, six moods, rotating invisibly)

# ============================================================ the scene state
var state := "ready"           # ready | play | cpu_wait | round_over
var clock := 0.0
var think_beat := 0.0
var anim_q: Array = []         # the move animations [{sq_from, sq_to, t}]

var st: Dictionary = {}        # the live state
var key_counts := {}           # the threefold ledger
var history: Array = []        # coordinate strings (the book reader)
var names_log: Array = []      # short algebraic (the log strip)
var last_move := {"f": -1, "t": -1}

var rounds := 0
var done_rounds := 0
var wins := 0
var losses := 0
var draws := 0

var profile_order: Array = ["starter", "aggressor", "jobava", "trickster",
        "royal", "flanker"]
var profile_i := 0
var profile := "starter"

var mem: Array = []
var cur := {}                  # {open, aggr, result}
var player_aggr := 0           # quiet/capture tally this round

var player_white := true
var sel := -1
var legal_cache: Array = []    # legal moves for the selected piece
var drag := false
var drag_sq := -1
var drag_pos := Vector2.ZERO
var pending_promo = null       # the move awaiting the promo pick

# the coin
var coin_sq := -1
var coin_t := 0.0
var run_clock := 0.0

# layout
var sq_px := 68.0
var board_origin := Vector2.ZERO

# nodes
var world: Node2D
var board_l: Node2D
var piece_l: Node2D
var fx_l: Node2D
var ready_ui: Control = null
var turn_lbl: Label
var you_lbl: Label
var draw_lbl: Label
var cpu_lbl: Label
var you_t: Label
var draw_t: Label
var cpu_t: Label
var log_lbl: Label
var verdict := ""

var _time := 0.0
var _rng := RandomNumberGenerator.new()
var _tex_cache := {}
var shake_t := 0.0

# ============================================================ the scene

func _goga_setup() -> void:
        _rng.randomize()
        pause_end_run = true    # THE XO/PONG DESIGN: the pause END banks
        var vp := get_viewport_rect().size
        world = Node2D.new()
        add_child(world)
        board_l = Node2D.new()
        board_l.draw.connect(_draw_board)
        world.add_child(board_l)
        piece_l = Node2D.new()
        piece_l.draw.connect(_draw_pieces)
        world.add_child(piece_l)
        fx_l = Node2D.new()
        fx_l.draw.connect(_draw_fx)
        fx_l.z_index = 5
        world.add_child(fx_l)
        _build_widgets(vp)
        _layout(vp)
        _load_meta()
        add_hud_button("SHOP", func(): _shop_open())
        _build_ready()

func _set_skin() -> void:
        var sid := Box.skin_on(game_id)
        if not SETS.has(sid):
                sid = "classic"

func _board_def() -> Dictionary:
        var tid := Box.item_on(game_id, "theme")
        if not BOARDS.has(tid):
                tid = "walnut"
        return BOARDS[tid]

func _load_meta() -> void:
        _set_skin()
        _board_def()

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
        # THE SCORE WIDGET (the xo shape) sits right of the board - the
        # whole 412px row must FIT the right column (the overflow law)
        var wx := vp.x - 460.0
        var widget := Node2D.new()
        widget.position = Vector2(wx + 230.0, 128.0)
        widget.draw.connect(func():
                var bwid := 128.0
                var bh := 70.0
                var gapw := 14.0
                var x0 := -(bwid * 3.0 + gapw * 2.0) * 0.5
                var boxes := [
                        [x0, Color("58c470"), Color("2f7a44")],
                        [x0 + bwid + gapw, Color("6b7280"), Color("4b5563")],
                        [x0 + (bwid + gapw) * 2.0, Color("e8574a"),
                                Color("9c3a32")],
                ]
                for b in boxes:
                        var bx: float = b[0]
                        var col: Color = b[1]
                        widget.draw_rect(Rect2(bx + 5, -bh / 2.0 + 5, bwid, bh),
                                Color(0.09, 0.05, 0.02, 0.85))
                        widget.draw_rect(Rect2(bx, -bh / 2.0, bwid, bh),
                                Color(1, 1, 1, 0.95))
                        widget.draw_rect(Rect2(bx, -bh / 2.0, bwid, bh),
                                col, false, 4.0)
                        widget.draw_rect(Rect2(bx + 40, -bh / 2.0 + 25,
                                bwid - 80, 3), col))
        world.add_child(widget)
        you_t = Arc.label("YOU", 17, Color("2f7a44"))
        draw_t = Arc.label("DRAWS", 17, Color("4b5563"))
        cpu_t = Arc.label("CPU", 17, Color("9c3a32"))
        you_lbl = Arc.label("0", 30, Color("2f7a44"))
        draw_lbl = Arc.label("0", 30, Color("4b5563"))
        cpu_lbl = Arc.label("0", 30, Color("9c3a32"))
        for l in [you_t, draw_t, cpu_t, you_lbl, draw_lbl, cpu_lbl]:
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                world.add_child(l)
        _refresh_widget()
        turn_lbl = Arc.label("", 26, Color(1, 1, 1, 0.92))
        turn_lbl.position = Vector2(wx, 210.0)
        turn_lbl.custom_minimum_size = Vector2(440.0, 36)
        turn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        world.add_child(turn_lbl)
        log_lbl = Arc.label("", 22, Color(1, 1, 1, 0.65))
        log_lbl.position = Vector2(wx, 258.0)
        log_lbl.custom_minimum_size = Vector2(440.0, 150.0)
        log_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
        world.add_child(log_lbl)

func _refresh_widget() -> void:
        you_lbl.text = str(wins)
        draw_lbl.text = str(draws)
        cpu_lbl.text = str(losses)
        var vp := get_viewport_rect().size
        var wx := vp.x - 460.0
        var w := 128.0
        var gapw := 14.0
        var x0 := wx + 230.0 - (w * 3.0 + gapw * 2.0) * 0.5
        var cols := [x0, x0 + w + gapw, x0 + (w + gapw) * 2.0]
        for i in 3:
                var t: Label = [you_t, draw_t, cpu_t][i]
                var v: Label = [you_lbl, draw_lbl, cpu_lbl][i]
                t.position = Vector2(cols[i], 128.0 - 34.0)
                t.custom_minimum_size = Vector2(w, 22)
                v.position = Vector2(cols[i], 128.0 - 12.0)
                v.custom_minimum_size = Vector2(w, 38)

func _layout(vp: Vector2) -> void:
        var top := 120.0
        var bot := banner_bottom() + 24.0
        sq_px = minf((vp.y - top - bot) / 8.0, (vp.x - 560.0) / 8.0)
        sq_px = maxf(40.0, sq_px)
        var bside := sq_px * 8.0
        board_origin = Vector2(36.0 + maxf(0.0, (vp.x - 560.0 - bside) * 0.25),
                top + maxf(0.0, (vp.y - top - bot - bside) * 0.5))

# ============================================================ the drawing

func _sq_rect(i: int) -> Rect2:
        var f := i % 8
        var r := i / 8
        var row := r if player_white else 7 - r
        var col := f if player_white else 7 - f
        return Rect2(board_origin + Vector2(col * sq_px, row * sq_px),
                Vector2(sq_px, sq_px))

func _sq_at(pos: Vector2) -> int:
        var col := int((pos.x - board_origin.x) / sq_px)
        var row := int((pos.y - board_origin.y) / sq_px)
        if col < 0 or col > 7 or row < 0 or row > 7:
                return -1
        if not player_white:
                col = 7 - col
                row = 7 - row
        return row * 8 + col

func _tex(set_id: String, color: String, piece: int) -> Texture2D:
        var names := ["", "pawn", "knight", "bishop", "rook", "queen", "king"]
        var key := "%s_%s_%d" % [set_id, color, piece]
        if not _tex_cache.has(key):
                _tex_cache[key] = load("res://assets/games/chess/%s/%s_%s.png"
                        % [set_id, color, names[piece]])
        return _tex_cache[key]

func _draw_board() -> void:
        var bd := _board_def()
        var check_sq := -1
        if not st.is_empty() and in_check(st):
                check_sq = king_sq(st["b"], st["w"])
        for i in 64:
            var f := i % 8
            var r := i / 8
            var light := (f + r) % 2 == 1
            var rect := _sq_rect(i)
            board_l.draw_rect(rect, bd["light"] if light else bd["dark"])
            # the last-move tint
            if i == int(last_move["f"]) or i == int(last_move["t"]):
                    board_l.draw_rect(rect, Color(1.0, 0.9, 0.3, 0.22))
            # the check glow
            if i == check_sq:
                    var pulse := 0.5 + 0.5 * sin(_time * 6.0)
                    board_l.draw_rect(rect, Color(1.0, 0.25, 0.2,
                            0.30 + 0.25 * pulse))
        # the frame + the coordinates
        var fr := Rect2(board_origin - Vector2(10, 10),
                Vector2(sq_px * 8 + 20, sq_px * 8 + 20))
        board_l.draw_rect(fr, bd["frame"], false, 8.0)
        # the selection + the legal targets
        if sel >= 0:
                var rsel := _sq_rect(sel)
                board_l.draw_rect(rsel, Color(1, 1, 1, 0.35), false, 4.0)
                var pulse2 := 0.6 + 0.4 * sin(_time * 5.0)
                for m in legal_cache:
                        var rt := _sq_rect(int(m["t"]))
                        if int(st["b"][m["t"]]) != 0 or m["flag"] == "ep":
                                board_l.draw_rect(rt.grow(-3.0),
                                        Color(0.95, 0.5, 0.3, 0.5 * pulse2),
                                        false, 5.0)
                        else:
                                var c := rt.get_center()
                                board_l.draw_circle(c, sq_px * 0.13,
                                        Color(0.2, 0.2, 0.2, 0.4))
                                board_l.draw_circle(c, sq_px * 0.13,
                                        Color(1, 1, 1, 0.35))

func _piece_tex(v: int) -> Texture2D:
        var sid := Box.skin_on(game_id)
        if not SETS.has(sid):
                sid = "classic"
        return _tex(sid, "w" if v > 0 else "b", absi(v))

func _draw_pieces() -> void:
        if st.is_empty():
                return
        for i in 64:
                var v: int = st["b"][i]
                if v == 0:
                        continue
                var skip := false
                for a in anim_q:
                        if int(a["sq"]) == i:
                                skip = true
                                break
                if skip:
                        continue
                if drag and drag_sq == i:
                        continue
                var tex := _piece_tex(v)
                var r := _sq_rect(i)
                var pad := sq_px * 0.10
                piece_l.draw_texture_rect(tex, Rect2(
                        r.position + Vector2(pad, pad),
                        Vector2(sq_px - pad * 2, sq_px - pad * 2)), false)

func _draw_fx() -> void:
        # the animated movers
        for a in anim_q:
                var k: float = clampf(float(a["t"]) / float(a["dur"]), 0.0, 1.0)
                var ease := 1.0 - pow(1.0 - k, 3.0)
                var from := _sq_rect(int(a["from"])).get_center()
                var to := _sq_rect(int(a["to"])).get_center()
                var v: int = a["v"]
                var tex := _piece_tex(v)
                var pad := sq_px * 0.10
                var at := from.lerp(to, ease)
                fx_l.draw_texture_rect(tex, Rect2(
                        at - Vector2(sq_px, sq_px) * 0.5
                                + Vector2(pad, pad),
                        Vector2(sq_px - pad * 2, sq_px - pad * 2)), false)
        # the dragged piece follows the finger
        if drag and drag_sq >= 0 and int(st["b"][drag_sq]) != 0:
                var v2: int = st["b"][drag_sq]
                var tex2 := _piece_tex(v2)
                var pad2 := sq_px * 0.08
                fx_l.draw_texture_rect(tex2, Rect2(
                        drag_pos - Vector2(sq_px, sq_px) * 0.5
                                + Vector2(pad2, pad2),
                        Vector2(sq_px - pad2 * 2, sq_px - pad2 * 2)), false)
        # the coin, sitting on its square
        if coin_sq >= 0:
                var tex3: Texture2D = load("res://assets/ui/coin.png")
                if tex3 != null:
                        var pos := _sq_rect(coin_sq).get_center()
                        pos.y += sin(coin_t * 3.4) * 4.0
                        var s := sq_px * 0.52 / float(tex3.get_width())
                        var fade: float = clampf(coin_t / 0.4, 0.0, 1.0)
                        var dst := pos - Vector2(tex3.get_width(),
                                tex3.get_height()) * s * 0.5
                        fx_l.draw_texture_rect(tex3, Rect2(dst,
                                Vector2(tex3.get_width(),
                                tex3.get_height()) * s), false,
                                Color(1, 1, 1, fade))
                        var ga := coin_t * 2.6
                        fx_l.draw_arc(pos, sq_px * 0.36, ga, ga + 1.2, 26,
                                Color(1, 1, 1, 0.5 * fade), 2.2)

# ============================================================ the flow

func _goga_input(event: InputEvent) -> void:
        if sheet_open_count() > 0 or pending_promo != null:
                return
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                if t.pressed:
                        if state == "ready":
                                state = "deal_start"
                                if ready_ui != null:
                                        ready_ui.queue_free()
                                        ready_ui = null
                                _new_round()
                                return
                        _press(t.position)
                else:
                        _release(t.position)
        elif event is InputEventScreenDrag and drag:
                drag_pos = event.position

func _press(at: Vector2) -> void:
    if state != "play" or st.is_empty():
        return
    if st["w"] != player_white:
        return
    var i := _sq_at(at)
    if i < 0:
        return
    var v: int = st["b"][i]
    if sel >= 0:
        # try the move (the plain/promo-queen variant first - the picker
        # re-asks when an underpromotion is wanted)
        for m in legal_cache:
            if int(m["t"]) == i and int(m["promo"]) in [0, 5]:
                _try_player_move(m)
                return
    if v != 0 and (v > 0) == player_white:
        sel = i
        legal_cache = []
        for m in legal_moves(st):
            if int(m["f"]) == i:
                legal_cache.append(m)
        drag = true
        drag_sq = i
        drag_pos = at
        if not legal_cache.is_empty():
            Jukebox.sfx("c_select", -8.0)
        board_l.queue_redraw()
    else:
        sel = -1
        legal_cache = []
        board_l.queue_redraw()

func _release(at: Vector2) -> void:
        if drag and drag_sq >= 0:
            var i := _sq_at(at)
            var moved := false
            if i >= 0 and i != drag_sq and sel == drag_sq:
                for m in legal_cache:
                    if int(m["t"]) == i and int(m["promo"]) in [0, 5]:
                        _try_player_move(m)
                        moved = true
                        break
            drag = false
            drag_sq = -1
            if not moved:
                piece_l.queue_redraw()
                fx_l.queue_redraw()

func _try_player_move(m: Dictionary) -> void:
    if int(m["promo"]) > 0 and int(m["promo"]) != 5:
        return
    if _promo_needed(m):
        pending_promo = m
        _promo_picker()
        return
    _player_move(m)

func _promo_needed(m: Dictionary) -> bool:
    return absi(int(st["b"][m["f"]])) == 1 \
            and (int(m["t"]) / 8 == 7 or int(m["t"]) / 8 == 0) \
            and int(m["promo"]) == 0

func _promo_picker() -> void:
    paused = true
    get_tree().paused = true
    var sheet := sheet_push(0.0, "promo")
    var t := Arc.label("PROMOTE TO", 36, Arc.INK)
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sheet.add_child(t)
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 14)
    sheet.add_child(row)
    for choice in [[5, "QUEEN"], [2, "KNIGHT"], [4, "ROOK"], [3, "BISHOP"]]:
        var b := Arc.button(choice[1], Vector2(150, 84), 22,
                Color("4a5ab8"), func():
                        var mm: Dictionary = pending_promo
                        mm["promo"] = int(choice[0])
                        pending_promo = null
                        get_tree().paused = false
                        paused = false
                        sheet_pop()
                        _player_move(mm))
        row.add_child(b)
    Arc.fit_sheet(sheet, 2)

func _player_move(m: Dictionary) -> void:
        _apply_move(m, true)

## the ONE place a move lands: animation, sound, ledger, verdict
func _apply_move(m: Dictionary, by_player: bool) -> void:
        var nm := move_name(st, m)
        var captured: bool = int(st["b"][m["t"]]) != 0 or m["flag"] == "ep"
        var moved_v: int = st["b"][m["f"]]
        if by_player:
                if captured:
                        player_aggr += 1
                if history.size() < 2:
                        cur["open"] = coord_of(m)
                cur["aggr"] = clampf(float(player_aggr) / 8.0, 0.0, 1.0)
        # the animation record BEFORE the state flips
        anim_q.append({"from": int(m["f"]), "to": int(m["t"]),
                "sq": int(m["t"]), "v": moved_v, "t": 0.0, "dur": 0.22})
        if m["flag"] == "castle":
                # the rook slides too
                var rf: int
                var rt: int
                if int(m["t"]) == 6:
                        rf = 7
                        rt = 5
                elif int(m["t"]) == 2:
                        rf = 0
                        rt = 3
                elif int(m["t"]) == 62:
                        rf = 63
                        rt = 61
                else:
                        rf = 56
                        rt = 59
                anim_q.append({"from": rf, "to": rt, "sq": rt,
                        "v": int(st["b"][rf]), "t": 0.04, "dur": 0.24})
        st = make_move(st, m)
        history.append(coord_of(m))
        names_log.append(nm)
        last_move = {"f": int(m["f"]), "t": int(m["t"])}
        sel = -1
        legal_cache = []
        # THE COIN RACE: a piece landing on the coin square takes it
        if coin_sq >= 0 and int(m["t"]) == coin_sq:
                coin_sq = -1
                if by_player:
                        add_run_coins(1)
                        Jukebox.sfx("c_coin", -3.0)
                        game_toast("YOU TOOK THE GOGACOIN  +1")
                        achievement_count("coins_taken", 1)
                else:
                        Jukebox.sfx("coin", -6.0, 0.8)
                        game_toast("THE CPU GRABBED THE COIN")
        # the sounds
        if captured:
                Jukebox.sfx("c_capture", -4.0)
        elif m["flag"] == "castle":
                Jukebox.sfx("c_castle", -4.0)
        else:
                Jukebox.sfx("c_move", -6.0)
        if absi(moved_v) == 1 and int(m["promo"]) > 0:
                Jukebox.sfx("c_promote", -4.0)
        # the verdict check
        var verdict_now := status(st, key_counts)
        if verdict_now == "checkmate":
                Jukebox.sfx("c_mate", -2.0)
                _resolve("win" if by_player else "lose")
                return
        if verdict_now != "play":
                _resolve("draw")
                return
        if in_check(st):
                Jukebox.sfx("c_check", -5.0)
        # hand the turn over
        if by_player:
                state = "cpu_wait"
                clock = 0.0
                think_beat = _rng.randf_range(0.6, 1.0)
                _banner()
        else:
                state = "play"
                _banner()
        board_l.queue_redraw()
        piece_l.queue_redraw()
        _refresh_log()

func _banner() -> void:
        if state == "round_over":
                return
        var my_turn: bool = st["w"] == player_white
        if my_turn:
                var line := "YOUR MOVE"
                if in_check(st):
                        line = "YOUR MOVE - CHECK!"
                turn_lbl.text = line
                turn_lbl.add_theme_color_override("font_color",
                        Color(0.45, 0.9, 0.6) if not in_check(st)
                        else Color(1.0, 0.45, 0.4))
        else:
                var n := int(_time * 2.5) % 3 + 1
                turn_lbl.text = "CPU IS THINKING%s" % " .".repeat(n)
                turn_lbl.add_theme_color_override("font_color",
                        Color(1.0, 0.6, 0.5))

func _refresh_log() -> void:
        var parts: Array = []
        var start := maxi(0, names_log.size() - 12)
        if start % 2 == 1:
                start += 1
        var n := 0
        var i := start
        while i < names_log.size() and n < 12:
                if i % 2 == 0:
                        parts.append("%d.%s %s" % [i / 2 + 1, names_log[i],
                                names_log[i + 1] if i + 1 < names_log.size()
                                else ""])
                        n += 1
                        i += 2
                else:
                        i += 1
        log_lbl.text = "  ".join(parts)

func _resolve(outcome: String) -> void:
        state = "round_over"
        clock = 0.0
        done_rounds += 1
        cur["result"] = 0 if outcome == "draw" else (1 if outcome == "win" else 2)
        mem = remember(mem, cur)
        cur = {}
        if outcome == "win":
                wins += 1
                add_score(1)
                achievement_count("wins", 1)
                achievement_max("max_score", score)
                verdict = "CHECKMATE - YOU WIN  +1"
                turn_lbl.add_theme_color_override("font_color",
                        Color(0.45, 0.9, 0.6))
                Jukebox.sfx("c_win", -2.0)
        elif outcome == "lose":
                losses += 1
                if score > 0:
                        add_score(-1)
                verdict = "CHECKMATE - THE CPU WINS  -1"
                turn_lbl.add_theme_color_override("font_color",
                        Color(1.0, 0.6, 0.5))
                Jukebox.sfx("c_lose", -3.0)
        else:
                draws += 1
                verdict = "DRAW - %s" % _draw_reason()
                turn_lbl.add_theme_color_override("font_color",
                        Color(0.8, 0.8, 0.85))
                Jukebox.sfx("c_draw", -4.0)
        turn_lbl.text = verdict
        _refresh_widget()
        check_achievements()

func _draw_reason() -> String:
        # the last verdict carried the reason; read it back from the state
        if not in_check(st) and legal_moves(st).is_empty():
                return "STALEMATE"
        if int(st["half"]) >= 100:
                return "50 MOVES"
        var minors := 0
        var other := 0
        for v in st["b"]:
            var vv := int(v)
            if vv == 0 or absi(vv) == 6:
                    continue
            if absi(vv) == 2 or absi(vv) == 3:
                    minors += 1
            else:
                    other += 1
        if other == 0 and minors <= 1:
                return "BARE KINGS"
        return "REPETITION"

## THE OPENER LAW (the xo shape): the loser takes WHITE next; a draw flips
func _new_round() -> void:
        rounds += 1
        if rounds == 1:
                player_white = true
        st = start_state()
        key_counts = {}
        history = []
        names_log = []
        last_move = {"f": -1, "t": -1}
        sel = -1
        legal_cache = []
        anim_q = []
        coin_sq = -1
        run_clock = 0.0
        player_aggr = 0
        cur = {"open": "", "aggr": 0.0}
        profile = String(profile_next(profile_i)[0])
        profile_i = int(profile_next(profile_i)[1])
        state = "play"
        _banner()
        _refresh_log()
        board_l.queue_redraw()
        piece_l.queue_redraw()

func profile_next(i: int) -> Array:
        return [PROFILES.keys()[i % PROFILES.size()], i + 1]

# ============================================================ the tick

func _goga_tick(delta: float) -> void:
        _time += delta
        coin_t += delta
        if shake_t > 0.0:
                shake_t -= delta
        for a in anim_q:
                a["t"] = float(a["t"]) + delta
        for a in anim_q.duplicate():
                if float(a["t"]) >= float(a["dur"]):
                        anim_q.erase(a)
        piece_l.queue_redraw()
        fx_l.queue_redraw()
        board_l.queue_redraw()
        if state == "play" or state == "cpu_wait":
                # THE COIN CLOCK: one GOGACoin each 3 minutes of play
                run_clock += delta
                if coin_sq < 0 and run_clock >= COIN_EVERY_S:
                        run_clock = 0.0
                        _spawn_coin()
        if state == "cpu_wait":
                clock += delta
                _banner()
                if clock >= think_beat:
                        _cpu_turn()
        elif state == "round_over":
                clock += delta
                if clock >= 2.2:
                        # THE OPENER LAW: the LOSER takes WHITE next; a
                        # draw flips the colors
                        if verdict.contains("DRAW"):
                                player_white = not player_white
                        else:
                                player_white = verdict.contains("THE CPU WINS")
                        _new_round()

func _spawn_coin() -> void:
        # a legal reachable square: empty, adjacent (king-wise) to a piece
        var cands: Array = []
        for i in 64:
                if int(st["b"][i]) != 0:
                        continue
                var f := i % 8
                var r := i / 8
                var near := false
                for df in [-1, 0, 1]:
                        for dr in [-1, 0, 1]:
                                if df == 0 and dr == 0:
                                        continue
                                if inside(f + df, r + dr) \
                                                and int(st["b"][sq(f + df,
                                                r + dr)]) != 0:
                                        near = true
                if near:
                        cands.append(i)
        if cands.is_empty():
                return
        coin_sq = int(cands[_rng.randi() % cands.size()])
        coin_t = 0.0
        Jukebox.sfx("c_coin", -8.0, 1.3)
        game_toast("A GOGACOIN APPEARED - RACE FOR IT")

## THE CPU TURN: the book or the search, then the same _apply_move door
func _cpu_turn() -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = int(Time.get_unix_time_from_system() * 1000.0) \
                ^ (rounds * 7919) ^ (names_log.size() * 104729)
        var m := cpu_move(st, profile, history, mem, rng)
        if m.is_empty():
                # should not happen (the verdict door catches mates first)
                state = "play"
                return
        _apply_move(m, false)

# ============================================================ the shop
## DIRECT: piece sets + boards, everything but the defaults bought

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
        var t := Arc.label("CHECKMATE SHOP", 34, Arc.INK)
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
        box.add_child(_shop_label("PIECES - the army you hold"))
        for id in SETS:
                box.add_child(_set_row(id))
        box.add_child(_shop_label("BOARDS - the ground you fight on"))
        for id in BOARDS:
                box.add_child(_board_row(id))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                func(): sheet_pop()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _goga_sheet_popped(id: String) -> void:
        if id == "promo" and pending_promo != null:
                pending_promo = null
                get_tree().paused = false
                paused = false
        elif id == "shop":
                shop_id = ""
                get_tree().paused = false
                paused = false
                _load_meta()
                # THE GATE TRUTH LAW (v0.3.8): the tap-anywhere gate comes
                # back ONLY over the ready state - the old unconditional
                # show floated it over a live game after any mid-play
                # shop visit
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

func _set_row(id: String) -> Control:
        var c: Dictionary = SETS[id]
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

func _board_row(id: String) -> Control:
        var c: Dictionary = BOARDS[id]
        var owned := Box.item_owned(game_id, "theme", id) or int(c["price"]) == 0
        var on: bool = Box.item_on(game_id, "theme") == id \
                or (int(c["price"]) == 0 and Box.item_on(game_id, "theme") == "")
        if on:
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"], c["desc"]],
                        22, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s - FIGHT ON IT" % c["name"],
                        Vector2(560, 60), 22, Color("2a7a68"), func():
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
## The headless contract: a fresh deterministic board any probe can drive.

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
        mem = []
        profile_i = 0
        player_white = true
        paused = true
        _new_round()

func probe_step(dt: float) -> void:
        _goga_tick(dt)
