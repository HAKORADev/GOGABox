class_name TowerDestroyerData
extends RefCounted
## TOWER DESTROYER (v041-3) - the data + the PURE generators (the miner_data
## law: every law the probe must assert lives in a pure RefCounted so
## hundreds of seeds can be checked without booting the scene).
##
## THE SOURCE LAW (v041-2 r2): the owner named the teacher and handed the
## XAPK - Voodoo's FIRE BALLS 3D (com.NikSanTech.FireDots3D 2.7, the
## firebase project is literally fire-balls-3d). The bundle is Unity
## il2cpp: the gameplay constants live compiled (no JSON levels), so the
## study yielded the SHAPE, not numbers - "HOLD TO FIRE", the level ladder,
## the rotating tower of segments, the cannon below. Mechanics study only;
## every asset and every line here is ours (THE USAGE LAW).
##
## THE OWNER'S LAWS (this round, verbatim):
## - "the gameplay will be the same, tower, but bottom-to-top instead of
##    tower ball's top-to-bottom" - the shooter sits at the BOTTOM, the
##    tower comes DOWN to him; progress reads bottom-to-top.
## - "black areas kills you as usual" - a BLACK segment over a shooter's
##    seat when the platform lands kills THAT shooter (the tower ball
##    black law, inverted). Colored leftovers shatter harmlessly.
## - "1 point for each platform destroyed" - the shooter whose ball breaks
##    the LAST colored segment banks the +1. Personal scores.
## - "score bonus will be /100" - registry coin_div 100.
## - "the game will be endless and each platforms will move at different
##    speeds so it be challenging and somehow not-predictable" - every
##    platform rolls its own descent speed AND its own spin.
## - "a gogacoin will appear after 200 platforms and could be missed,
##    after 200 platforms and not 200 points" - the coin rides a COLORED
##    segment of a platform spawned after 200 run-wide destroys; the ball
##    that breaks that segment takes it; the platform passing whole
##    takes the coin away forever. Again at 400, 600...
## - "the play modes will be 1/2/3/4 where each one means extra CPU
##    players" - the four ground seats N/E/S/W; 1 = solo.
## - "make the cpu a little smart ... more human-like, like different
##    detection and different shooting time based on the platform" - every
##    CPU rolls its own personality (detection lead, reaction, bursts,
##    discipline); they time their shots against the ROTATING segments.
## - THE LAN SEED: the seats are a clean PlayerSeat array (input source =
##    human | cpu | network-later); "the current implementation is not
##    true multiplayer ofc" - the shape is ready when the box is.

# ---------------------------------------------------------------- geometry
const SEG_MIN := 8                 # platform slot count range
const SEG_MAX := 12
const R_OUT := 15.0                # platform outer radius (world units)
const R_IN := 3.0                  # platform inner radius
const POLE_R := 1.6
const THICK := 1.2                 # platform thickness
const PITCH := 5.5                 # vertical spacing between platforms
const SEAT_R := 13.0               # the shooters' radius on the ground ring
const SEAT_TOL := 2.2              # a segment covers a seat within this arc
const ALIVE_AHEAD := 14            # platforms kept alive above
const MUZZLE_Y := 1.2              # the death line = the muzzle height
const BALL_SPEED := 46.0
const BALL_R := 0.55
const FIRE_RATE := 7.5             # balls per second while holding
const SPIN_MIN := 0.25
const SPIN_MAX := 1.2

# ------------------------------------------------------------------ pacing
const SPEED_BASE := 1.05           # the descent base at 0 destroyed
const SPEED_GROW := 0.0042         # + per destroyed platform
const SPEED_CAP := 2.4
const SPEED_LO := 0.55             # the per-platform speed band (x base)
const SPEED_HI := 1.65
const HP_TIER := 18                # every N destroyed, hp can grow by 1
const HP_MAX := 3
const GAP_MIN := 0.08              # empty-slot band (balls pass through)
const GAP_MAX := 0.2
const BLACK_MIN := 0.05            # black-slot band (the killer armor)
const BLACK_MAX := 0.2

# -------------------------------------------------------------------- coin
const COIN_AT := 200               # a coin waits after 200 DESTROYED
const COIN_DESIGN_PX := 64.0       # the 2D coin's design-px size (the law)

# ------------------------------------------------------------------- seats
const SEAT_ANGLES := [0.0, PI * 0.5, PI, PI * 1.5]   # front, right, back, left
const SEAT_NAMES := ["YOU", "CPU 1", "CPU 2", "CPU 3"]

# ------------------------------------------------------------------- skins
# THE SKIN LAW (towerball r2): skins are DESIGNS, not colors - each wears
# its own material character; the shop sells them, the game applies them.
const CANNON_SKINS := [
        {"id": "classic", "name": "GUNNER", "price": 0,
                "body": Color(0.55, 0.36, 0.18), "barrel": Color(0.28, 0.24, 0.2),
                "rough": 0.55, "metal": 0.2, "alpha": 1.0, "emission": 0.0,
                "barrel_len": 2.6, "barrel_w": 0.55},
        {"id": "iron", "name": "IRON HOWITZER", "price": 250,
                "body": Color(0.42, 0.44, 0.48), "barrel": Color(0.25, 0.27, 0.3),
                "rough": 0.35, "metal": 0.9, "alpha": 1.0, "emission": 0.0,
                "barrel_len": 2.2, "barrel_w": 0.72},
        {"id": "crystal", "name": "CRYSTAL CANNON", "price": 350,
                "body": Color(0.62, 0.85, 0.92), "barrel": Color(0.75, 0.92, 0.96),
                "rough": 0.06, "metal": 0.05, "alpha": 0.68, "emission": 0.1,
                "barrel_len": 3.0, "barrel_w": 0.42},
        {"id": "carbon", "name": "CARBON PIERCER", "price": 450,
                "body": Color(0.1, 0.1, 0.12), "barrel": Color(0.16, 0.16, 0.19),
                "rough": 0.8, "metal": 0.3, "alpha": 1.0, "emission": 0.0,
                "barrel_len": 3.2, "barrel_w": 0.48},
        {"id": "gold", "name": "GOLD BOMBARD", "price": 550,
                "body": Color(0.95, 0.76, 0.22), "barrel": Color(0.85, 0.6, 0.12),
                "rough": 0.18, "metal": 0.9, "alpha": 1.0, "emission": 0.0,
                "barrel_len": 2.8, "barrel_w": 0.6},
]
const BALL_SKINS := [
        {"id": "classic", "name": "STONE SHOT", "price": 0,
                "color": Color(0.9, 0.87, 0.8), "rough": 0.5, "metal": 0.1,
                "alpha": 1.0, "emission": 0.0},
        {"id": "ice", "name": "ICE SPHERE", "price": 250,
                "color": Color(0.75, 0.91, 1.0), "rough": 0.05, "metal": 0.0,
                "alpha": 0.72, "emission": 0.08},
        {"id": "lava", "name": "LAVA CORE", "price": 350,
                "color": Color(1.0, 0.45, 0.12), "rough": 0.6, "metal": 0.0,
                "alpha": 1.0, "emission": 0.85},
        {"id": "metal", "name": "STEEL BALL", "price": 450,
                "color": Color(0.78, 0.8, 0.85), "rough": 0.12, "metal": 0.95,
                "alpha": 1.0, "emission": 0.0},
        {"id": "gold", "name": "GOLD SHOT", "price": 550,
                "color": Color(0.95, 0.78, 0.25), "rough": 0.15, "metal": 0.9,
                "alpha": 1.0, "emission": 0.0},
]
# the platform palettes (per-platform 4-color ramps, the rhythm law)
const RAMP := [
        ["ef6351", "f7b267", "5fb4a2", "7f9cf5"],
        ["e2593f", "eec643", "57a773", "5ea9dd"],
        ["c86fc9", "f29e74", "79b473", "6fc4e8"],
]
const BLACK := Color(0.13, 0.12, 0.15)   # the danger, constant everywhere

# ------------------------------------------------------------------ palette

static func ramp_color(skin_idx: int, seg_idx: int) -> Color:
        var ramp: Array = RAMP[skin_idx % RAMP.size()]
        return Color(ramp[seg_idx % ramp.size()])

# ------------------------------------------------------------------ pacing

static func speed_base(destroyed: int) -> float:
        return minf(SPEED_CAP, SPEED_BASE + SPEED_GROW * float(destroyed))

## every platform rolls its own speed inside the band - the
## "challenging and somehow not-predictable" law
static func platform_speed(base: float, roll: float) -> float:
        return base * lerpf(SPEED_LO, SPEED_HI, roll)

static func spin_speed(roll: float, sign_roll: float) -> float:
        var s := lerpf(SPIN_MIN, SPIN_MAX, roll)
        return s if sign_roll >= 0.5 else -s

static func segment_hp(depth: int, roll: float) -> int:
        var tier := mini(HP_MAX - 1, int(float(depth) / float(HP_TIER)))
        var hp := 1 + tier
        # within a platform some segments sit tougher (the +1 roll)
        if roll > 0.82 and hp < HP_MAX:
                hp += 1
        return hp

## the slot lottery: colored / black / gap - bands grow with the depth,
## every platform GUARANTEES breakable content (>= 4 colored slots)
static func build_slots(depth: int, rng: RandomNumberGenerator) -> Array:
        var n := rng.randi_range(SEG_MIN, SEG_MAX)
        var t := float(depth)
        var gap_p := minf(GAP_MAX, GAP_MIN + t * 0.0012)
        var black_p := minf(BLACK_MAX, BLACK_MIN + t * 0.0012)
        var slots: Array = []
        for i in n:
                var r := rng.randf()
                if r < gap_p:
                        slots.append({"kind": "gap"})
                elif r < gap_p + black_p:
                        slots.append({"kind": "black"})
                else:
                        slots.append({"kind": "colored",
                                "hp": segment_hp(depth, rng.randf())})
        # the guarantee: at least 4 colored - upgrade the first gaps/blacks
        var colored := 0
        for s in slots:
                if s["kind"] == "colored":
                        colored += 1
        var i2 := 0
        while colored < 4 and i2 < slots.size():
                if slots[i2]["kind"] != "colored":
                        slots[i2] = {"kind": "colored",
                                "hp": segment_hp(depth, rng.randf())}
                        colored += 1
                i2 += 1
        return slots

## the arc each slot owns (rad)
static func slot_arc(n: int) -> float:
        return TAU / float(n)

## which slot covers world angle `a` for a platform rotated by `rot`
static func slot_at(a: float, rot: float, n: int) -> int:
        var arc := slot_arc(n)
        var rel := fposmod(a - rot, TAU)
        return int(floor(rel / arc)) % n

## does the platform's slot over the seat's angle kill that seat?
## THE BLACK LAW: alive black over the seat at the landing line = death;
## alive colored = shatters harmlessly; gap = the seat was already freed.
static func seat_killed(slots: Array, rot: float, seat_angle: float) -> bool:
        var idx := slot_at(seat_angle, rot, slots.size())
        var s: Dictionary = slots[idx]
        if s["kind"] == "black":
                return true
        return false

# -------------------------------------------------------------------- coin

static func coin_due(destroyed: int) -> bool:
        return destroyed > 0 and destroyed % COIN_AT == 0

## the coin rides a random COLORED slot of a platform spawned soon after
## the milestone (the +2nd platform - it must be REACHABLE, not the one
## already at the muzzle); returns the slot index or -1 (no colored seat)
static func coin_slot(slots: Array, rng: RandomNumberGenerator) -> int:
        var colored: Array = []
        for i in slots.size():
                if slots[i]["kind"] == "colored":
                        colored.append(i)
        if colored.is_empty():
                return -1
        return colored[rng.randi_range(0, colored.size() - 1)]

# --------------------------------------------------------------------- cpu

## THE HUMAN-LIKE PERSONALITY (the owner: "a little smart ... different
## detection and different shooting time based on the platform"):
## detection_lead - how early (in seconds of platform travel) the CPU
##   starts answering an incoming colored segment (faster platforms pull
##   an earlier lead: lead *= the platform's own speed factor);
## reaction - the pause before the FIRST ball on a fresh target;
## burst/pause - the human trigger finger (short bursts, breathing room);
## discipline - the chance it correctly holds fire while BLACK rides over
##   its seat (a mistake wastes balls, never kills).
static func cpu_personality(rng: RandomNumberGenerator) -> Dictionary:
        return {
                "detection_lead": rng.randf_range(0.3, 0.9),
                "reaction": rng.randf_range(0.1, 0.4),
                "burst_len": rng.randi_range(2, 6),
                "burst_pause": rng.randf_range(0.25, 0.7),
                "discipline": rng.randf_range(0.65, 0.95),
        }

## when does the CPU fire? Pure law: a colored segment is `eta` seconds
## from the muzzle; the CPU fires when eta <= lead * its speed factor and
## its burst clock allows it. Returns true this frame.
static func cpu_wants_fire(p: Dictionary, eta: float, speed: float,
                black_over: bool, burst_ok: bool, disc_roll: float) -> bool:
        if black_over and disc_roll < float(p["discipline"]):
                return false
        var lead := float(p["detection_lead"]) * maxf(0.7, speed)
        return eta <= lead and burst_ok
