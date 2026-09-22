class_name TowerData
extends RefCounted
## TOWER BALL (v041-2 r2) - the data + the PURE generators (the miner_data
## law: level math lives in a pure RefCounted so the probe can assert
## fairness on hundreds of seeds without booting the scene).
##
## THE OWNER'S LAWS (r2 restated):
## - round length ladder: 150, 300, 450, 600, 750, 900 - round 1..6 walks
##   the ladder, round 7+ holds 900. BOTH modes ride the same ladder.
## - NO LIVES. "the game ends when you crash yourself with no lives" meant
##   there ARE no lives: one crash ends the run (the owner, r2: "i meant
##   with no lives for real, and not to die when you have no more lives
##   remaining"). The lives system is DEAD.
## - each round won = +1 score; the score bonus rides registry coin_div 5.
## - a GOGACoin rides the round after every 6 wins, in a LEGAL spot, and
##   it CAN BE MISSED (one seat, one window). Both modes.
##
## THE r2 SOURCE LAW - the owner handed the exact sources:
##   Stack Bounce (gamesnacks, PlayCanvas)  -> BALL mode's boost/fire law
##   Neon Tower (gamesnacks, famobi/THREE)  -> PLATFORM mode's whole mechanic
##   Stack Ball 1.2.38 (Azur, APK)          -> the fireball field names
##       (m_killsToStart/m_fillSpeed/m_unfillSpeed/m_fireSpeed) + the look
##   The constants below are the DECOMPILED originals, verbatim.

const COIN_EVERY := 6        # a coin waits after every 6 rounds won
const COIN_DESIGN_PX := 64.0 # the 2D coin's design-px size - the scale law

# ============================================== THE EXACT BOOST LAW (Ball mode)
## Stack Bounce Game.js, verbatim semantics:
##   boostValue starts -0.25; each non-boosting break += 0.03; at >= 1.0 the
##   world slows (slomo 0.1) for a 1.6s charge, then the ball IS the fireball.
##   While boosting the value burns -0.6/s; while NOT boosting it decays
##   -0.15/s; at <= 0 it stops and floors at -0.5 (THE COOLDOWN: from -0.5
##   the next fill needs 50 breaks). The gauge shows itself above 0.1.
const BOOST_START := -0.25
const BOOST_PER_BREAK := 0.03
const BOOST_FLOOR := -0.5
const BOOST_CHARGE_TIME := 1.6
const BOOST_BURN := 0.6
const BOOST_DECAY := 0.15
const BOOST_SHOW := 0.1
const BOOST_SLOMO := 0.1      # the charge slow-mo (the tower spin breathes)
## the streak law verbatim: the k-th consecutive break scores
##   n = max(round(streak), 1)  then streak += 1  (drives pitch + the gauge;
##   the GOGABox score stays the owner's: +1 per round won)

# ==================================== THE EXACT NEON TOWER CONFIG (Platform)
## famobi neon-tower, the decompiled JSON config `Sh` - the platform mode's
## physics + structure, verbatim (ball_radius 0.54 -> 0.8: +48% so Balldozer's
## eyes read at phone distance; every RATIO to the ring stays honest).
const NT_POINTER_ROT := 0.007        # rad per pointer px
const NT_KEYBOARD_ROT := 0.33        # rad/s held (0.0055 rad/frame at 60)
const NT_POLE_R := 2.8
const NT_INTER_RING := 8.7
const NT_RING_R := 6.3
const NT_RING_H := 1.2
const NT_BALL_R := 0.8
const NT_BALL_OFFSET := 4.55
const NT_APEX := 6.0
const NT_GRAVITY := -60.0
const NT_DRAG := 0.02                # QUADRATIC: a = g - sign(v)*v*v*drag
const NT_BOUNCE_V := 23.0
const NT_COMBO_THRESHOLD := 4        # consecutive falls charge the smash
const NT_WALL_DEG := 8.0             # wall width
const NT_WALL_H := [3.0, 6.0]        # low/high
const NT_WALL_SPEEDS := [0.5, 1.2]   # the moving walls (rad/s, readable)
const NT_BALL_ANG := 0.0             # the ball rides the world angle 0

# ------------------------------------------------------------------ ladder

static func round_length(r: int) -> int:
        return mini(900, 150 * maxi(1, r))

## the coin rides the round AFTER every 6 wins (won = rounds won so far)
static func coin_due(won: int) -> bool:
        return won > 0 and won % COIN_EVERY == 0

## THE BOOST MATH (pure, the probe asserts the exact original curve):
## fill  -> the gauge value after one break
## tick  -> the value after `sec` seconds of boosting/not
static func boost_after_break(v: float) -> float:
        return v + BOOST_PER_BREAK

static func boost_tick(v: float, sec: float, boosting: bool) -> float:
        var d := (BOOST_BURN if boosting else BOOST_DECAY) * sec
        return maxf(BOOST_FLOOR, v - d)

static func boost_ready(v: float) -> bool:
        return v >= 1.0

## the streak score verbatim: max(round(streak), 1) BEFORE the increment
static func streak_score(streak: float) -> int:
        return maxi(int(round(streak)), 1)

# ------------------------------------------------------------------ skins
# THE OWNER'S r2 SKIN LAW: "skins should not be another color, a bad
# platform should always be black, skins should be another designs, like
# glass and rock and wood and water, different shaders, different behaviors,
# satisfaction wow-factor, ball can be ice, metal and other things, leading
# to different SFXs and massive GL shaders".
# Each break skin: the material character (roughness/metallic/emission/
# transparency), the break VFX style, its own SFX family, and a 4-color ramp
# the rows cycle (the rhythm stays designed, never random). BLACK stays
# BLACK in every skin - the danger must always read.

const BREAK_SKINS := [
        {"id": "classic", "name": "CLASSIC TOWER", "price": 0,
                "ramp": ["ef6351", "f7b267", "5fb4a2", "7f9cf5"],
                "pole": "d9cfc0", "rough": 0.52, "metal": 0.05,
                "alpha": 1.0, "emission": 0.0,
                "vfx": "shard", "sfx": "tb_break"},
        {"id": "glass", "name": "GLASS TOWER", "price": 250,
                "ramp": ["9fd8e8", "c8ecf5", "aee8f0", "dff6fb"],
                "pole": "d8eef5", "rough": 0.08, "metal": 0.0,
                "alpha": 0.62, "emission": 0.06,
                "vfx": "shard", "sfx": "tb_break_glass"},
        {"id": "rock", "name": "ROCK TOWER", "price": 350,
                "ramp": ["8d8377", "a89b8c", "6f665c", "b5aa9c"],
                "pole": "9a9186", "rough": 0.95, "metal": 0.0,
                "alpha": 1.0, "emission": 0.0,
                "vfx": "rubble", "sfx": "tb_break_rock"},
        {"id": "wood", "name": "WOOD TOWER", "price": 450,
                "ramp": ["b3814f", "c99a63", "8f6238", "d9b380"],
                "pole": "a97e4f", "rough": 0.8, "metal": 0.0,
                "alpha": 1.0, "emission": 0.0,
                "vfx": "splinter", "sfx": "tb_break_wood"},
        {"id": "water", "name": "WATER TOWER", "price": 550,
                "ramp": ["3fb8d8", "6fd4ea", "2f9fc0", "a5e6f5"],
                "pole": "bfe8f2", "rough": 0.12, "metal": 0.1,
                "alpha": 0.55, "emission": 0.04,
                "vfx": "splash", "sfx": "tb_break_water"},
]

const BALL_SKINS := [
        {"id": "classic", "name": "BALLDOZER", "price": 0,
                "color": Color("e2593f"), "rough": 0.42, "metal": 0.12,
                "alpha": 1.0, "trail": "warm"},
        {"id": "ice", "name": "ICE BALL", "price": 250,
                "color": Color("bfe8ff"), "rough": 0.06, "metal": 0.0,
                "alpha": 0.72, "trail": "frost"},
        {"id": "metal", "name": "METAL BALL", "price": 350,
                "color": Color("c9ccd4"), "rough": 0.15, "metal": 0.95,
                "alpha": 1.0, "trail": "spark"},
        {"id": "rubber", "name": "RUBBER BALL", "price": 450,
                "color": Color("4a4f55"), "rough": 0.9, "metal": 0.0,
                "alpha": 1.0, "trail": "none"},
        {"id": "gold", "name": "GOLD BALL", "price": 550,
                "color": Color("e8b830"), "rough": 0.18, "metal": 0.9,
                "alpha": 1.0, "trail": "gold"},
]

const BLACK := Color(0.13, 0.12, 0.15)   # the danger, constant everywhere

static func ball_skin() -> Dictionary:
        var on := Box.item_on("towerball", "skin_ball")
        for s in BALL_SKINS:
                if s["id"] == on:
                        return s
        return BALL_SKINS[0]

static func break_skin() -> Dictionary:
        var on := Box.item_on("towerball", "skin_break")
        for s in BREAK_SKINS:
                if s["id"] == on:
                        return s
        return BREAK_SKINS[0]

static func ramp_color(skin: Dictionary, row: int) -> Color:
        var ramp: Array = skin["ramp"]
        return Color(String(ramp[row % ramp.size()]))

# ============================================ BALL mode rows (the stack)
## One helix disc: `count` arc segments; black flags in honest runs of
## 1-3; the rotation speed + direction. THE FAIRNESS LAWS (r1, kept):
##   - no black in a round's first 8 rows (the warm-up is safe)
##   - black probability ramps with depth (0.05 -> ~0.30)
##   - a ring is never more than 45% black (there is always room)
##   - rows spin slower than the eye can lose (0.7..2.4 rad/s)
## r2 + THE STACK BOUNCE RHYTHM: after every busy stretch comes a small
## clean stretch (their chunk pattern 0: 3-10 safe rings between the
## death-heavy ones) - the dive gets breathing room, the streak feels fair.
const CLEAN_SEAM := 3       # min clean rows after a busy stretch

static func gen_row(row: int, round_len: int, rng: RandomNumberGenerator,
                round_idx: int) -> Dictionary:
        var count := 10 + rng.randi_range(0, 3)
        var black := []
        for i in count:
                black.append(false)
        if row >= 8:
                var busy := true
                var row_mod := row % 14
                # the rhythm: rows 11..13 of every 14-row seam breathe clean
                busy = not (row_mod >= 11 and row_mod <= 13)
                if busy:
                        var p := 0.05 + 0.25 * (float(row) / float(maxi(1, round_len))) \
                                        + 0.015 * float(mini(round_idx, 5))
                        var i := 0
                        while i < count:
                                if rng.randf() < p:
                                        var run := mini(rng.randi_range(1, 3),
                                                        count - i)
                                        for k in run:
                                                black[i + k] = true
                                        i += run
                                else:
                                        i += 1
                        # THE CAP: never 45%+ black - thin the runs from the end
                        var nb := 0
                        for b in black:
                                if b:
                                        nb += 1
                        var cap := int(floor(float(count) * 0.45))
                        i = count - 1
                        while nb > cap and i >= 0:
                                if black[i]:
                                        black[i] = false
                                        nb -= 1
                                i -= 1
        var speed := 0.7 + rng.randf_range(0.0, 0.5) \
                        + 0.8 * (float(row) / 900.0)
        speed = minf(speed, 2.4)
        var dir := 1.0 if row % 2 == 0 else -1.0
        return {"count": count, "black": black, "rot": dir * speed}

## the coin's seat ON a disc: a random BREAKABLE segment (never black,
## never the pole - the legal area). Returns -1 when the row has no
## breakable segment (cannot happen under the fairness laws, but the
## caller honors it).
static func pick_coin_seg(row_data: Dictionary, rng: RandomNumberGenerator) -> int:
        var ok: Array = []
        var black: Array = row_data["black"]
        for i in black.size():
                if not bool(black[i]):
                        ok.append(i)
        if ok.is_empty():
                return -1
        return ok[rng.randi_range(0, ok.size() - 1)]

## which disc carries the coin: 15..40 rows under the top, never within
## 8 rows of the round's end (the coin never sits on the finish sprint)
static func coin_row(round_len: int, rng: RandomNumberGenerator) -> int:
        var lo := 15
        var hi := mini(40, round_len - 9)
        if hi <= lo:
                return -1
        return rng.randi_range(lo, hi)

## the segment under the ball at contact: the ball rides the WORLD angle
## 0 (the camera's side); a segment's window is its slice of the ring,
## rotated by the disc's live rotation. Returns the segment index.
static func seg_under_ball(count: int, rot: float) -> int:
        var seg_ang := TAU / float(count)
        # the ball's angle in the DISC's frame = -rot (the disc spun by rot)
        var a := fposmod(-rot, TAU)
        return int(floor(a / seg_ang)) % count

# ======================================== PLATFORM mode rings (Neon Tower)
## One ring: the SOLID coverage as arc spans + RED (death) arc spans +
## walls. Angles are RADIANS in the ring's own frame. The gap the ball
## falls through = whatever is neither solid nor red.
##   {solid: [[a0,a1],...], red: [[a0,a1],...], walls: [{a, h, spd}],
##    rot: the moving walls' phase, spin: the ring's own slow drift}
##
## THE FAIRNESS LAWS (the probe asserts over 300 seeds x full depth):
##   - the first 3 rings are FULLY SOLID (the original's "start 0" chunk:
##     the ball bounces at the top; the player rotates the first gap under)
##   - every ring from 3 on keeps ONE passable gap >= 18 deg (solvable)
##   - red coverage never exceeds 35% of the ring, never in the gap
##   - walls: max 2 per ring, movers max 1, walls never inside the gap
##   - the difficulty ramps with depth: easy -> mid -> hard (the original's
##     probability step table), nudged by the round idx

const NT_GAP_MIN_DEG := 18.0
const NT_GAP_START_DEG := 50.0
const NT_SOLID_START := 3     # the first rings: fully solid (the start chunk)

static func gen_ring(row: int, round_len: int, rng: RandomNumberGenerator,
                round_idx: int) -> Dictionary:
        # THE START CHUNK: ring 0..2 are full platforms - no gap, no red,
        # no walls. The ball bounces; the player learns the rotation.
        if row < NT_SOLID_START:
                return {"solid": [[0.0, TAU]], "red": [], "walls": [],
                        "gap0": 0.0, "gap": 0.0, "spin": 0.0}
        var gap_min := deg_to_rad(NT_GAP_MIN_DEG)
        var gap_start := deg_to_rad(NT_GAP_START_DEG)
        # the difficulty ramp: 0 easy -> 1 hard across the depth, nudged by
        # the round number (the original's step table compressed to a ramp)
        var depth := float(row) / float(maxi(1, round_len))
        var diff := clampf(depth * 2.2 + 0.06 * float(mini(round_idx, 5)),
                        0.0, 1.0)
        # the guaranteed gap: starts wide, narrows to the floor
        var gap := lerpf(gap_start, gap_min, diff) \
                        + rng.randf_range(0.0, deg_to_rad(14.0))
        var gap_a0 := rng.randf_range(0.0, TAU)
        var solid := []
        var red := []
        var walls := []
        # the red arcs: 0-2 arcs, coverage capped hard (the probe law:
        # red never exceeds 35% of the ring - each arc stays <= 38 deg,
        # two arcs stay under 22%), never in the gap
        if row >= 3:
                var red_p := 0.16 * diff + 0.02
                var arcs := 1 if rng.randf() < 0.55 + 0.3 * diff else 0
                if rng.randf() < 0.25 * diff:
                        arcs = 2
                for i in arcs:
                        var span := clampf(
                                lerpf(gap * 0.8, gap * 2.2, rng.randf()),
                                deg_to_rad(12.0), deg_to_rad(38.0))
                        var a0 := fposmod(gap_a0 + gap + rng.randf_range(
                                deg_to_rad(6.0), TAU - gap - span
                                - deg_to_rad(6.0)), TAU)
                        red.append([a0, a0 + span])
        # the solid: the rest of the circle minus the gap (implied) and red
        var covered: Array = []
        covered.append([gap_a0, gap_a0 + gap])          # the guaranteed gap
        for r in red:
                covered.append(r)
        covered.sort_custom(func(a, b): return a[0] < b[0])
        # merge overlaps then the complement = solid
        var merged: Array = []
        for c in covered:
                if merged.size() > 0 and c[0] <= merged[-1][1] + 1e-6:
                        merged[-1][1] = maxf(merged[-1][1], c[1])
                else:
                        merged.append([c[0], c[1]])
        # walk the complement around the circle
        var cur := 0.0
        for m in merged:
                var s: float = m[0]
                var e: float = m[1]
                if s > cur + 1e-4:
                        solid.append([cur, minf(s, TAU)])
                cur = maxf(cur, e)
                if cur >= TAU:
                        break
        if cur < TAU - 1e-4:
                solid.append([cur, TAU])
        # the walls: stand on the rim, never inside the gap; only the FIRST
        # wall may move (the probe law: max 1 mover), movers appear deep
        if row >= 6:
                var nw := 0 if rng.randf() < 0.55 - 0.25 * diff \
                                else (1 if rng.randf() < 0.85 else 2)
                for i in nw:
                        var a := fposmod(gap_a0 + gap + rng.randf_range(
                                deg_to_rad(10.0),
                                TAU - gap - deg_to_rad(NT_WALL_DEG)
                                - deg_to_rad(10.0)), TAU)
                        var h := lerpf(NT_WALL_H[0], NT_WALL_H[1],
                                        rng.randf() * diff)
                        var spd := 0.0
                        if i == 0 and row >= 14 and rng.randf() < 0.3 * diff:
                                spd = NT_WALL_SPEEDS[0 if rng.randf() < 0.6
                                                else 1] \
                                                * (1.0 if rng.randf() < 0.5
                                                else -1.0)
                        walls.append({"a": a, "h": h, "spd": spd})
        return {"solid": solid, "red": red, "walls": walls,
                "gap0": gap_a0, "gap": gap,
                "spin": 0.0}

## is the world angle `a` (the ring rotated by `rot`) inside the GAP?
static func ring_in_gap(ring: Dictionary, a: float, rot: float) -> bool:
        var g0: float = fposmod(float(ring["gap0"]) + rot, TAU)
        var rel := fposmod(a - g0, TAU)
        return rel < float(ring["gap"])

## which part of the ring owns the world angle `a`: "gap" | "red" | "solid"
static func ring_at(ring: Dictionary, a: float, rot: float) -> String:
        if ring_in_gap(ring, a, rot):
                return "gap"
        var rel := fposmod(a - fposmod(float(ring["gap0"]) + rot, TAU), TAU)
        for r in ring["red"]:
                var s: float = fposmod(float(r[0]), TAU)
                var span: float = float(r[1]) - float(r[0])
                if rel >= s and rel <= s + span:
                        return "red"
        return "solid"

## the nearest solid/red edge ahead of the ball when rotating by `amt`
## (sign matters). Returns the SAFE rotation (<= |amt|) - the original's
## getAvailableRotation: the angular distance to the nearest sector edge
## at the ball's height band, minus the ball's angular half-width.
static func ring_safe_rot(ring: Dictionary, rot: float, amt: float) -> float:
        var ball_half := NT_BALL_R / NT_BALL_OFFSET
        # walk every solid + red edge in the rotation direction, find the
        # first edge the ball would cross
        var best := absf(amt)
        var edges: Array = []
        var g0 := fposmod(float(ring["gap0"]) + rot, TAU)
        edges.append(g0)                       # the gap's two edges are
        edges.append(fposmod(g0 + float(ring["gap"]), TAU))  # solid boundaries
        for r in ring["red"]:
                var s: float = fposmod(float(r[0]) + rot, TAU)
                edges.append(s)
                edges.append(fposmod(s + (float(r[1]) - float(r[0])), TAU))
        for e0 in edges:
                # the edge at world angle e0; the ball's leading face is at
                # NT_BALL_ANG +/- ball_half depending on the direction
                var lead := NT_BALL_ANG + ball_half * signf(amt)
                var d := fposmod((e0 - lead) * signf(amt), TAU)
                if d < best:
                        best = d
        return best * signf(amt)

## the coin's seat in PLATFORM mode: the coin rides the guaranteed GAP of
## a ring 15..40 rings down (fall through it to collect - the legal area).
static func coin_ring(round_len: int, rng: RandomNumberGenerator) -> int:
        var lo := 15
        var hi := mini(40, round_len - 9)
        if hi <= lo:
                return -1
        return rng.randi_range(lo, hi)
