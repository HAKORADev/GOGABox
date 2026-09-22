class_name TowerData
extends RefCounted
## TOWER BALL (v041-2) - the data + the PURE generators (the miner_data
## law: level math lives in a pure RefCounted so the probe can assert
## fairness on hundreds of seeds without booting the scene).
##
## THE OWNER'S NUMBERS, EXACT:
## - round length ladder: 150, 300, 450, 600, 750, 900 - round 1..6 walks
##   the ladder, round 7+ holds 900. BOTH modes ride the same ladder.
## - lives 3; a crash costs one life and the ROUND CONTINUES (the gold
##   miner law); no lives = the run ends.
## - each round won = +1 score; the score bonus rides registry coin_div 5.
## - a GOGACoin rides the round after every 6 wins, in a LEGAL spot, and
##   it CAN BE MISSED (one seat, one window).
## - fire ball: a long streak turns the ball FIRE for a short window -
##   black things shatter under fire, nothing else forgives them.

const LIVES := 3
const FIRE_AT := 12          # streak that ignites the fire ball
const FIRE_TIME := 5.0       # seconds of fire
const COIN_EVERY := 6        # a coin waits after every 6 rounds won
const COIN_DESIGN_PX := 64.0 # the 2D coin's design-px size - the scale law

# ------------------------------------------------------------------ ladder

static func round_length(r: int) -> int:
        return mini(900, 150 * maxi(1, r))

## the coin rides the round AFTER every 6 wins (won = rounds won so far)
static func coin_due(won: int) -> bool:
        return won > 0 and won % COIN_EVERY == 0

# ------------------------------------------------------------------ skins
# THE TOWER LESSON (the snowy tower's own history): ONE designed palette
# per skin, deterministic per row - never random colors. Black segments
# stay BLACK in every skin: the danger must always read.

const BALL_SKINS := [
        {"id": "classic", "name": "BALLDOZER", "price": 0,
                "color": Color("e2593f")},
        {"id": "gold", "name": "GOLD BALL", "price": 250,
                "color": Color("e8b830")},
        {"id": "emerald", "name": "EMERALD BALL", "price": 350,
                "color": Color("2fa36b")},
        {"id": "sapphire", "name": "SAPPHIRE BALL", "price": 450,
                "color": Color("3567d6")},
        {"id": "candy", "name": "CANDY BALL", "price": 550,
                "color": Color("f06fa0")},
]

## each break skin: a 4-color ramp the rows cycle + the pole color +
## the sky's top/bottom (the ONE theme, re-inked)
const BREAK_SKINS := [
        {"id": "classic", "name": "CLASSIC TOWER", "price": 0,
                "ramp": ["ef6351", "f7b267", "5fb4a2", "7f9cf5"],
                "pole": "d9cfc0", "sky_top": "aee3f5", "sky_bot": "eaf7ff"},
        {"id": "ocean", "name": "OCEAN TOWER", "price": 250,
                "ramp": ["2ec4b6", "4cc9f0", "3a86c8", "6fe7dd"],
                "pole": "cfe8f0", "sky_top": "9fd8ef", "sky_bot": "e8f8ff"},
        {"id": "forest", "name": "FOREST TOWER", "price": 350,
                "ramp": ["6a994e", "a7c957", "588157", "8ab17d"],
                "pole": "d9d2b8", "sky_top": "b5ddb4", "sky_bot": "f0fae8"},
        {"id": "sunset", "name": "SUNSET TOWER", "price": 450,
                "ramp": ["f4978e", "f9c74f", "f3722c", "f8961e"],
                "pole": "f0dcc8", "sky_top": "ffc9a3", "sky_bot": "fff1e0"},
        {"id": "berry", "name": "BERRY TOWER", "price": 550,
                "ramp": ["b5179e", "f72585", "7209b7", "c77dff"],
                "pole": "e6d4ea", "sky_top": "e3b8ef", "sky_bot": "fbeffd"},
]

const BLACK := Color(0.13, 0.12, 0.15)   # the danger, constant everywhere

static func ball_color() -> Color:
        var on := Box.item_on("towerball", "skin_ball")
        for s in BALL_SKINS:
                if s["id"] == on:
                        return s["color"]
        return BALL_SKINS[0]["color"]

static func break_skin() -> Dictionary:
        var on := Box.item_on("towerball", "skin_break")
        for s in BREAK_SKINS:
                if s["id"] == on:
                        return s
        return BREAK_SKINS[0]

static func ramp_color(skin: Dictionary, row: int) -> Color:
        var ramp: Array = skin["ramp"]
        return Color(String(ramp[row % ramp.size()]))

# ------------------------------------------------------------------ BALL
#                                                              mode rows

## One helix disc: `count` arc segments; black flags in honest runs of
## 1-3; the rotation speed + direction. THE FAIRNESS LAWS:
##   - no black in a round's first 8 rows (the warm-up is safe)
##   - black probability ramps with depth (0.05 -> ~0.30)
##   - a ring is never more than 45% black (there is always room)
##   - rows spin slower than the eye can lose (0.7..2.4 rad/s)
static func gen_row(row: int, round_len: int, rng: RandomNumberGenerator,
                round_idx: int) -> Dictionary:
        var count := 10 + rng.randi_range(0, 3)
        var black := []
        for i in count:
                black.append(false)
        if row >= 8:
                var p := 0.05 + 0.25 * (float(row) / float(maxi(1, round_len))) \
                                + 0.015 * float(mini(round_idx, 5))
                # the run writer: walks the ring dropping 1-3 black runs
                var i := 0
                while i < count:
                        if rng.randf() < p:
                                var run := mini(rng.randi_range(1, 3), count - i)
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

# ----------------------------------------------------------- PLATFORM mode

## One block row: `cols` blocks; true = breakable. THE FAIRNESS LAWS:
##   - no hard blocks in a round's first 3 rows
##   - hard probability ramps 0.06 -> ~0.20, in runs of 1-2
##   - a row is never more than 25% hard (and always clears - hard
##     blocks crumble with their row once the breakables are gone)
static func gen_blocks(row: int, cols: int, rng: RandomNumberGenerator,
                round_idx: int, round_len: int) -> Array:
        var out := []
        for i in cols:
                out.append(true)
        if row >= 3:
                var p := 0.06 + 0.14 * (float(row) / float(maxi(1, round_len))) \
                                + 0.01 * float(mini(round_idx, 5))
                var i := 0
                while i < cols:
                        if rng.randf() < p:
                                var run := mini(rng.randi_range(1, 2), cols - i)
                                for k in run:
                                        out[i + k] = false
                                i += run
                        else:
                                i += 1
                var nh := 0
                for b in out:
                        if not b:
                                nh += 1
                var cap := int(floor(float(cols) * 0.25))
                i = cols - 1
                while nh > cap and i >= 0:
                        if not out[i]:
                                out[i] = true
                                nh -= 1
                        i -= 1
        return out

## THE PADDLE BOUNCE LAW (the breakout classic): the hit offset -1..1
## across the paddle's face decides the leave angle, up to 62 degrees
## off vertical - the ball always leaves upward.
static func bounce_angle(offset: float) -> float:
        return clampf(offset, -1.0, 1.0) * deg_to_rad(62.0)

## the serve: a slight random lean so no two serves play alike
static func serve_angle(rng: RandomNumberGenerator) -> float:
        return rng.randf_range(-0.35, 0.35)
