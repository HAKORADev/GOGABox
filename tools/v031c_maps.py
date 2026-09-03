#!/usr/bin/env python3
"""v0.3.1 PATCH III - THE TEN TALL CURSED DARIO MAPS (15 rows).

WHY TALL: the owner - "the empty upper side is bad design, you can
remove it and scale the things up somehow or limit the view for that
area... will be like more rich design this way". The 12-row maps had 6
EMPTY sky rows = half the screen was nothing. These 15-row maps carry a
REAL vertical structure on the jump rhythm (normal jump = 3 rows):
  shelf bands at rows 11 -> 8 -> 5 (-> 2 for the risky coin climbs),
  bats patrolling rows 2-7, spitters on shelves, ghost ladders, movers.
The ground stays CONTINUOUS (row 14), the activity row is 13.

LAWS (validated below, re-checked by dario_probe):
 - ground row 14 = solid "#" wall to wall
 - rows 0-1 stay sky; spikes/fires/braziers/start/goal sit on row 13
 - NO free coins - GOGACoins live inside ? crates only (code caps 5/level)
 - every ? has standable support (B/?/g) within 4 rows below, +-2 cols
 - no two chars share a cell
chars: # ground | B brick | ? box | g ghost | m mover | ~ fire | ^ spikes
| D goal | d start | T brazier | s snail | f fly/bat | b blocker/rhino
| p spitter | h spiky | W witcher
"""
ROWS = 15
GROUND = 14
ACT = 13          # the activity row (on the ground)

def blank(cols):
    return [["."] * cols for _ in range(ROWS)]

def ground(cv):
    for c in range(len(cv[0])):
        cv[GROUND][c] = "#"

def put(cv, r, c, s):
    for i, ch in enumerate(s):
        assert cv[r][c + i] == ".", f"overlap at {r},{c+i}: {cv[r][c+i]} vs {ch}"
        assert 0 <= r < ROWS and 0 <= c + i < len(cv[0]), f"out of canvas at {r},{c+i}"
        cv[r][c + i] = ch

def render(cv):
    return ["".join(r) for r in cv]

def validate(m):
    w = len(m[0])
    assert all(len(r) == w for r in m), "uneven rows"
    assert set(m[GROUND]) == {"#"}, "ground not continuous"
    assert set(m[0]) == {"."} and set(m[1]) == {"."}, "rows 0-1 must be sky"
    for r in range(ROWS):
        for c in range(w):
            ch = m[r][c]
            if ch in "~^DTshbp" and r not in (ACT,) and ch != "p":
                raise AssertionError(f"{ch} off the activity row at {r},{c}")
            if ch == "m" and r not in (10, 11):
                raise AssertionError(f"mover off its ride rows at {r},{c}")
            if ch == "p" and r not in (ACT, 10):
                raise AssertionError(f"spitter off ground/shelf row at {r},{c}")
            if ch in "f" and not (2 <= r <= 8):
                raise AssertionError(f"bat at bad row {r},{c}")
            if ch in "B?" and not (2 <= r <= 11):
                raise AssertionError(f"crate at bad row {r},{c}")
            if ch == "?" and r >= 2:
                sup = False
                for rr in range(r + 1, min(r + 5, ROWS)):
                    for cc in range(max(0, c - 2), min(w, c + 3)):
                        if m[rr][cc] in "#B?g":
                            sup = True
                assert sup, f"crate {r},{c} has no support"
            if ch in "^~" and r != ACT:
                raise AssertionError(f"hazard off ground at {r},{c}")

LEVELS = []

# ---------------------------------------------------------------- 1 THE FALL
W = 132
cv = blank(W); ground(cv)
put(cv, ACT, 2, "d"); put(cv, ACT, 128, "D")
put(cv, ACT, 54, "T"); put(cv, ACT, 96, "T")
put(cv, ACT, 40, "s"); put(cv, ACT, 76, "s"); put(cv, ACT, 108, "s")
put(cv, 5, 62, "f")
put(cv, 11, 36, "B?B?B")
put(cv, 11, 68, "BB"); put(cv, 8, 69, "?")
put(cv, 11, 100, "B?B")
validate(render(cv)); LEVELS.append(render(cv))

# ------------------------------------------------------- 2 THE WOODS REPEAT
W = 138
cv = blank(W); ground(cv)
put(cv, ACT, 2, "d"); put(cv, ACT, 134, "D")
put(cv, ACT, 70, "T"); put(cv, ACT, 112, "T")
put(cv, ACT, 34, "s"); put(cv, ACT, 66, "s"); put(cv, ACT, 102, "s")
put(cv, 4, 50, "f"); put(cv, 6, 92, "f")
put(cv, ACT, 56, "^^"); put(cv, ACT, 120, "^^^")
put(cv, 11, 28, "B?B")
put(cv, 11, 60, "B?B?B")
put(cv, 11, 86, "BBB"); put(cv, 8, 88, "B?")
put(cv, 11, 126, "B?B")
validate(render(cv)); LEVELS.append(render(cv))

# ------------------------------------------------------------ 3 THE MARKS
W = 142
cv = blank(W); ground(cv)
put(cv, ACT, 2, "d"); put(cv, ACT, 138, "D")
put(cv, ACT, 74, "T"); put(cv, ACT, 118, "T")
put(cv, ACT, 36, "s"); put(cv, ACT, 84, "s"); put(cv, ACT, 124, "s")
put(cv, ACT, 96, "h")                      # the spiky turtle says hello
put(cv, 4, 58, "f")
put(cv, ACT, 50, "^^^^"); put(cv, ACT, 106, "^^")
put(cv, 11, 62, "m")                       # the mover (the teleport is dead)
put(cv, 11, 30, "B?B")
put(cv, 11, 76, "B?B?B"); put(cv, 8, 79, "?")
put(cv, 11, 130, "B?B")
validate(render(cv)); LEVELS.append(render(cv))

# ------------------------------------------------------------ 4 THE STONES
W = 146
cv = blank(W); ground(cv)
put(cv, ACT, 2, "d"); put(cv, ACT, 142, "D")
put(cv, ACT, 80, "T"); put(cv, ACT, 124, "T")
put(cv, ACT, 36, "s"); put(cv, ACT, 98, "s")
put(cv, ACT, 52, "b")                      # THE RHINO learns to charge
put(cv, 4, 44, "f"); put(cv, 6, 94, "f")
put(cv, ACT, 60, "^^^^"); put(cv, ACT, 86, "~~~")
put(cv, 11, 40, "m")
put(cv, 11, 30, "B?B")
put(cv, 11, 68, "B?B?B"); put(cv, 8, 70, "?")
put(cv, 11, 106, "B?B")
put(cv, 11, 112, "BBB"); put(cv, 10, 113, "p")     # a spitter ON the shelf
validate(render(cv)); LEVELS.append(render(cv))

# ---------------------------------------------------------- 5 THE HUMMING
W = 150
cv = blank(W); ground(cv)
put(cv, ACT, 2, "d"); put(cv, ACT, 146, "D")
put(cv, ACT, 76, "T"); put(cv, ACT, 118, "T")
put(cv, ACT, 32, "s"); put(cv, ACT, 68, "s")
put(cv, ACT, 44, "h"); put(cv, ACT, 96, "h")
put(cv, ACT, 120, "b")
put(cv, ACT, 84, "p")
put(cv, 4, 56, "f"); put(cv, 5, 104, "f")
put(cv, ACT, 50, "^^^^"); put(cv, ACT, 90, "^^"); put(cv, ACT, 132, "^^^^")
put(cv, ACT, 72, "~~"); put(cv, ACT, 110, "~~~")
put(cv, 11, 26, "B?B")
put(cv, 11, 58, "BB"); put(cv, 8, 59, "?")
put(cv, 11, 100, "B?B?B")
put(cv, 11, 140, "B?B")
validate(render(cv)); LEVELS.append(render(cv))

# ------------------------------------------------------------ 6 THE BURNS
W = 154
cv = blank(W); ground(cv)
put(cv, ACT, 2, "d"); put(cv, ACT, 150, "D")
put(cv, ACT, 84, "T"); put(cv, ACT, 128, "T")
put(cv, ACT, 30, "s"); put(cv, ACT, 62, "s")
put(cv, ACT, 48, "b"); put(cv, ACT, 110, "b")
put(cv, ACT, 72, "p"); put(cv, 10, 119, "p"); put(cv, 11, 118, "BBB")
put(cv, ACT, 94, "h"); put(cv, ACT, 136, "h")
put(cv, 4, 40, "f"); put(cv, 6, 116, "f")
put(cv, ACT, 54, "~~~"); put(cv, ACT, 100, "~~~"); put(cv, ACT, 142, "~~~")
put(cv, ACT, 78, "^^^^")
put(cv, 11, 88, "m")
put(cv, 11, 24, "B?B")
put(cv, 11, 64, "B?B?B"); put(cv, 8, 66, "?")
put(cv, 11, 130, "B?B")
validate(render(cv)); LEVELS.append(render(cv))

# ------------------------------------------------------- 7 THE FOOTPRINTS
W = 150
cv = blank(W); ground(cv)
put(cv, ACT, 2, "d"); put(cv, ACT, 146, "D")
put(cv, ACT, 78, "T"); put(cv, ACT, 120, "T")
put(cv, ACT, 34, "s"); put(cv, ACT, 140, "s")
put(cv, ACT, 58, "h"); put(cv, ACT, 128, "h")
put(cv, ACT, 92, "b")
put(cv, ACT, 104, "p")
put(cv, 4, 48, "f"); put(cv, 7, 100, "f")
put(cv, ACT, 52, "^^^^"); put(cv, ACT, 84, "~~~"); put(cv, ACT, 134, "^^")
put(cv, 11, 26, "B?B")
# the FIRST TIMED CLIMB: a ghost pair under a high coin crate
put(cv, 11, 69, "gg"); put(cv, 8, 70, "?")
put(cv, 11, 112, "B?B?B")
validate(render(cv)); LEVELS.append(render(cv))

# ----------------------------------------------------------- 8 THE DREAM
W = 156
cv = blank(W); ground(cv)
put(cv, ACT, 2, "d"); put(cv, ACT, 152, "D")
put(cv, ACT, 86, "T"); put(cv, ACT, 128, "T")
put(cv, ACT, 32, "s"); put(cv, ACT, 66, "s")
put(cv, ACT, 54, "b"); put(cv, ACT, 118, "b")
put(cv, ACT, 74, "p"); put(cv, ACT, 110, "p")
put(cv, ACT, 94, "h"); put(cv, ACT, 136, "h")
put(cv, 3, 44, "f"); put(cv, 5, 98, "f"); put(cv, 4, 132, "f")
put(cv, ACT, 46, "^^^^"); put(cv, ACT, 90, "^^"); put(cv, ACT, 140, "^^^^")
put(cv, ACT, 100, "~~~")
put(cv, 11, 58, "m"); put(cv, 11, 122, "m")
put(cv, 11, 24, "B?B")
put(cv, 11, 80, "B?B?B"); put(cv, 8, 82, "?")
put(cv, 11, 104, "gg")                     # a ghost ride over the fire field
put(cv, 11, 146, "B?B")
validate(render(cv)); LEVELS.append(render(cv))

# ------------------------------------------------------ 9 THE FRONT DOOR
W = 160
cv = blank(W); ground(cv)
put(cv, ACT, 2, "d"); put(cv, ACT, 156, "D")
put(cv, ACT, 88, "T"); put(cv, ACT, 132, "T")
put(cv, ACT, 30, "s"); put(cv, ACT, 60, "s"); put(cv, ACT, 96, "s")
put(cv, ACT, 50, "b"); put(cv, ACT, 124, "b")
put(cv, ACT, 70, "p"); put(cv, ACT, 108, "p")
put(cv, ACT, 86, "h"); put(cv, ACT, 142, "h")
put(cv, 3, 40, "f"); put(cv, 6, 84, "f"); put(cv, 4, 116, "f"); put(cv, 7, 148, "f")
put(cv, ACT, 64, "^^^^"); put(cv, ACT, 100, "~~~"); put(cv, ACT, 146, "^^^")
# THE RISKY CLIMB: ghosts over the spikes, coins at row 2
put(cv, ACT, 42, "^^^^")
put(cv, 11, 43, "gg")
put(cv, 8, 44, "B?")
put(cv, 5, 47, "gg")
put(cv, 2, 48, "?")
put(cv, 11, 76, "m")
put(cv, 11, 22, "B?B")
put(cv, 11, 112, "B?B?B")
put(cv, 11, 150, "B?B")
validate(render(cv)); LEVELS.append(render(cv))

# ----------------------------------------------------------- 10 THE ARENA
W = 48
cv = blank(W); ground(cv)
put(cv, ACT, 2, "d"); put(cv, ACT, 45, "D")
put(cv, ACT, 8, "T"); put(cv, ACT, 38, "T")
put(cv, 4, 24, "W")
# THE GHOST LADDER to her head (the owner's timed climb, now TALL)
put(cv, 11, 19, "gg")
put(cv, 8, 24, "gg")
put(cv, 5, 18, "gg")
put(cv, 5, 27, "gg")
validate(render(cv)); LEVELS.append(render(cv))

# ---------------------------------------------------------------- report
for i, m in enumerate(LEVELS):
    boxes = sum(r.count("?") for r in m)
    enim = sum(sum(r.count(k) for k in "sfhbpm") for r in m)
    print(f"L{i+1}: {len(m[0])} cols, {boxes} crates, {enim} enemies")

print()
print("LEVELS := [")
for m in LEVELS:
    print("\t[")
    for r in m:
        print(f'\t\t"{r}",')
    print("\t],")
print("]")
