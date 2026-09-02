#!/usr/bin/env python3
"""THE TEN NEW CURSED DARIO MAPS - painted on a canvas with exact column
math, then printed as GDScript literals. LAWS:
 - the ground row is CONTINUOUS (the owner: "why the ground has empty
   areas between the blocks, weird!") - no pits, no floating grass
 - NO free-floating coins: GOGACoins live inside ? boxes only
 - every ? box stands over a standable surface within jump reach
 - the goal (trophy) sits ON the ground at the far end
 - level 10 = the compact Witcher arena with the GHOST PLATFORM ladder
chars: # ground | B brick | ? box | g ghost platform | m mover | ~ fire |
^ spikes | D goal | d start | T brazier | s snail | f fly | b blocker |
p spitter | h spiky | W witcher
"""
ROWS = 12

def blank(cols):
    return [["."] * cols for _ in range(ROWS)]

def ground(cv, cols):
    for c in range(cols):
        cv[ROWS - 1][c] = "#"

def put(cv, r, c, s):
    for i, ch in enumerate(s):
        assert cv[r][c + i] == ".", f"overlap at {r},{c}: {cv[r][c+i]} vs {ch}"
        cv[r][c + i] = ch

def render(cv):
    return ["".join(r) for r in cv]

LEVELS = []

# ---------------------------------------------------------------- 1 THE FALL
W = 126
cv = blank(W); ground(cv, W)
put(cv, 10, 2, "d")
put(cv, 9, 34, "s")
put(cv, 9, 80, "s")
put(cv, 7, 40, "B?B?B")            # the first boxes (coin + empty)
put(cv, 9, 70, "BB")               # the step
put(cv, 6, 71, "?")                # the high coin box (bump from the step)
put(cv, 10, 54, "T")
put(cv, 10, 98, "T")
put(cv, 7, 104, "B?B")             # one more pair before home
put(cv, 10, 120, "D")
LEVELS.append(render(cv))

# ------------------------------------------------------- 2 THE WOODS REPEAT
W = 134
cv = blank(W); ground(cv, W)
put(cv, 10, 2, "d")
put(cv, 9, 30, "s")
put(cv, 9, 62, "s")
put(cv, 9, 104, "s")
put(cv, 6, 44, "f")
put(cv, 6, 92, "f")
put(cv, 7, 24, "B?B")              # coin + empty
put(cv, 10, 50, "^^")              # the first spikes
put(cv, 9, 58, "BBBB")             # a brick shelf over the spikes
put(cv, 5, 59, "?")                # high box (bump from the shelf)
put(cv, 7, 78, "B?B?B")
put(cv, 10, 88, "T")
put(cv, 9, 112, "BB")
put(cv, 5, 112, "?")
put(cv, 10, 128, "D")
LEVELS.append(render(cv))

# ------------------------------------------------------------ 3 HER MARKS
W = 136
cv = blank(W); ground(cv, W)
put(cv, 10, 2, "d")
put(cv, 9, 28, "s")
put(cv, 9, 96, "s")
put(cv, 6, 38, "f")
put(cv, 5, 88, "f")
put(cv, 7, 20, "B?B?B")
put(cv, 10, 52, "^^^^")            # the spike garden
put(cv, 9, 55, "m")                # the mover rides over it
put(cv, 7, 68, "B?")
put(cv, 9, 68, "BB")
put(cv, 10, 78, "T")
put(cv, 6, 84, "?")                # the power box
put(cv, 9, 84, "BB")
put(cv, 10, 108, "T")
put(cv, 7, 118, "B?B")
put(cv, 10, 130, "D")
LEVELS.append(render(cv))

# ---------------------------------------------------------- 4 THE HUMMING
W = 140
cv = blank(W); ground(cv, W)
put(cv, 10, 2, "d")
put(cv, 9, 26, "s")
put(cv, 9, 58, "s")
put(cv, 5, 70, "f")
put(cv, 5, 110, "f")
put(cv, 9, 46, "p")                # the first spitter
put(cv, 9, 100, "p")
put(cv, 7, 34, "B?B")
put(cv, 10, 64, "~~~")             # the fire strips
put(cv, 9, 78, "BBBB")
put(cv, 5, 79, "?")
put(cv, 10, 90, "T")
put(cv, 7, 96, "B?B?B")
put(cv, 10, 122, "^^^")
put(cv, 9, 126, "BB")
put(cv, 5, 126, "?")
put(cv, 10, 134, "D")
LEVELS.append(render(cv))

# ------------------------------------------------------------ 5 THE BURN
W = 140
cv = blank(W); ground(cv, W)
put(cv, 10, 2, "d")
put(cv, 9, 24, "s")
put(cv, 5, 60, "f")
put(cv, 5, 112, "f")
put(cv, 9, 74, "b")                # THE BLOCKER
put(cv, 9, 118, "p")
put(cv, 10, 40, "~~")
put(cv, 10, 52, "^^")
put(cv, 7, 30, "B?B")
put(cv, 9, 60, "BBBB")
put(cv, 5, 61, "?")
put(cv, 10, 84, "~~~~")            # the burn lane
put(cv, 9, 90, "BB")
put(cv, 5, 90, "?")
put(cv, 10, 100, "T")
put(cv, 7, 104, "B?B?B")
put(cv, 10, 134, "D")
LEVELS.append(render(cv))

# -------------------------------------------------------- 6 RIGGED GROUND
W = 144
cv = blank(W); ground(cv, W)
put(cv, 10, 2, "d")
put(cv, 9, 22, "s")
put(cv, 9, 56, "h")                # THE SPIKY (spikes out = death)
put(cv, 9, 92, "h")
put(cv, 9, 78, "b")
put(cv, 9, 122, "p")
put(cv, 5, 40, "f")
put(cv, 5, 108, "f")
put(cv, 7, 28, "B?B")
put(cv, 10, 60, "^^^")
put(cv, 9, 64, "BBBB")
put(cv, 5, 65, "?")
put(cv, 10, 80, "~~")
put(cv, 7, 86, "B?B")
put(cv, 10, 100, "T")
put(cv, 9, 112, "BBBB")
put(cv, 5, 113, "?")
put(cv, 10, 126, "~~~~")
put(cv, 7, 132, "B?B")
put(cv, 10, 138, "D")
LEVELS.append(render(cv))

# --------------------------------------------------------- 7 FOOTPRINTS
W = 142
cv = blank(W); ground(cv, W)
put(cv, 10, 2, "d")
put(cv, 9, 30, "h")
put(cv, 9, 88, "h")
put(cv, 5, 50, "f")
put(cv, 5, 104, "f")
put(cv, 9, 66, "p")
put(cv, 9, 40, "m")
put(cv, 10, 54, "^^")
put(cv, 7, 24, "B?B?B")
put(cv, 9, 76, "BBBB")
put(cv, 5, 77, "?")
put(cv, 10, 96, "~~~")
put(cv, 9, 100, "g")               # the ghost platform dance
put(cv, 6, 101, "?")               # the high crate - only by ghost
put(cv, 10, 116, "T")
put(cv, 7, 126, "B?B")
put(cv, 10, 136, "D")
LEVELS.append(render(cv))

# ----------------------------------------------------------- 8 THE DREAM
W = 150
cv = blank(W); ground(cv, W)
put(cv, 10, 2, "d")
put(cv, 9, 20, "s")
put(cv, 9, 60, "h")
put(cv, 9, 96, "b")
put(cv, 9, 126, "p")
put(cv, 5, 36, "f")
put(cv, 5, 82, "f")
put(cv, 5, 122, "f")
put(cv, 7, 26, "B?B")
put(cv, 10, 44, "^^")
put(cv, 9, 48, "BBBB")
put(cv, 5, 49, "?")
put(cv, 10, 68, "~~~")
put(cv, 9, 72, "BB")
put(cv, 6, 72, "?")
put(cv, 9, 88, "m")
put(cv, 7, 102, "B?B?B")
put(cv, 10, 116, "~~~~")
put(cv, 9, 122, "g")
put(cv, 6, 123, "?")
put(cv, 10, 136, "T")
put(cv, 10, 144, "D")
LEVELS.append(render(cv))

# ------------------------------------------------------- 9 ONE MORE DOOR
W = 154
cv = blank(W); ground(cv, W)
put(cv, 10, 2, "d")
put(cv, 9, 18, "s")
put(cv, 9, 44, "h")
put(cv, 9, 74, "b")
put(cv, 9, 106, "h")
put(cv, 9, 132, "p")
put(cv, 5, 30, "f")
put(cv, 5, 66, "f")
put(cv, 4, 100, "f")
put(cv, 7, 22, "B?B")
put(cv, 9, 36, "g")
put(cv, 6, 38, "?")
put(cv, 10, 52, "^^^^")
put(cv, 9, 56, "m")
put(cv, 7, 62, "B?B?B")
put(cv, 10, 84, "~~~~~")
put(cv, 9, 88, "BBBB")
put(cv, 5, 89, "?")
put(cv, 10, 118, "^^^")
put(cv, 9, 122, "g")
put(cv, 6, 123, "?")
put(cv, 10, 140, "T")
put(cv, 7, 146, "B?B")
put(cv, 10, 150, "D")
LEVELS.append(render(cv))

# ------------------------------------------------------- 10 THE WITCHER
W = 34
cv = blank(W); ground(cv, W)
put(cv, 10, 2, "d")
put(cv, 10, 8, "T")
put(cv, 10, 26, "T")
put(cv, 9, 6, "g")                 # the ghost ladder: row 9 -> 7 -> 5
put(cv, 7, 11, "g")
put(cv, 5, 16, "g")                # the fight platform - right in her swing
put(cv, 6, 16, "W")                # she flies row 6, swings cols ~13-19
put(cv, 10, 30, "D")
LEVELS.append(render(cv))

# ---------------------------------------------------------------- checks
for i, m in enumerate(LEVELS):
    w = len(m[0])
    ok_even = all(len(r) == w for r in m)
    ground_ok = all(ch == "#" for ch in m[ROWS - 1])
    no_coin = all("c" not in r for r in m)
    no_dead = all(all(ch in "#B?gm~^DdTsbphWf." for ch in r) for r in m)
    print(f"L{i+1}: {w} cols | even={ok_even} ground={ground_ok} "
          f"no_coins={no_coin} chars_ok={no_dead}")
    if not (ok_even and ground_ok and no_coin and no_dead):
        for r in m:
            print("   ", r)

print()
print("LEVELS := [")
for m in LEVELS:
    print("\t[")
    for r in m:
        print(f'\t\t"{r}",')
    print("\t],")
print("]")
