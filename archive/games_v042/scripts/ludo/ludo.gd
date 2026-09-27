extends GogaGame
## BOARD LUDO - v0.3.9-10, the classic one-die ludo (graduated v0.3.9-10;
## the teaser LUDO ROAD renamed by the owner's law - "the word ludo itself
## is trademarked from pachisi, call it board ludo will be good enough").
## The honest brain is the ORIGINAL one-die game the owner grew up on:
## "i played many ludos ... actually to me, the original one dice is the
## better choice, two dices are used just to speed up gameplay".
##
## Owner contract (v0.3.9-13, the test-report round):
##   - THE SEAT TRUTH: the yard seats mirrored WRONG for armies 2/3/4
##     ("the pawns ... in their house/holding area are accurate for
##     player 1 which is user, but all others have inaccurate positions")
##     - the seat origins are the base origin +1.95/+4.05 now, every
##     army's four seats sit ON its own plate's corners
##   - THE BARE CENTER: "the winning area has a circle under the square,
##     remove that circle" - the home medallion is gone; the four
##     triangles point into the bare slab
##   - THE TACTICAL CPU (supersedes the v0.3.9-10 pure-RNG law): "there
##     can be many possibile ways to play the next move, like moving
##     forward to win or release extra pawn or eat an opponent's pawn,
##     there is logic that needs profiles and accurate working on it i
##     mean to make it actually tactical!" - FOUR hidden moods (racer /
##     hunter / guard / chaos) weight ONE scorer over the POST-move
##     board (win 10x, eat 7x, drop 5x, the flee, the wall, the risk);
##     the mood redraws every round
##   - THE FLOW LAW: the mode ask opens the game, the pick seats the
##     TAP ANYWHERE gate, the gate tap starts the round (the snakes
##     board's correction, the house keeps one flow) - and the ask wears
##     its ONE short title ("CHOOSE MODE", law 28's v0.3.9-13 note)
##   - THE CROWN CATCH (the probe's endgame soak): the home square is
##     THE CROWN - the 2-pawn cap lives on the LANE cells only; a cap on
##     the home square refused a 3rd arriving pawn FOREVER (a round no
##     one could ever win)
##
## Owner contract (v0.3.9-10, verbatim intent):
##   - VERTICAL: "the board is squared, making a square in vertical
##     position takes proper place instead of the horizontal which will
##     let us with two big empty screen sides"
##   - THE MODES, asked at the START ("optionals menu at the start", no
##     options button here, no powerups):
##       x1 - each plays ONE side (4 chess-like figures each)
##       x2 - "we drop the 4 sides, user plays as 1-3 and opponent as
##            2-4 so they be turn after a turn" - THE ALLY LAW (pointed
##            so we would not miss it): "if user-owned chess-like from
##            square 1 met with square 3, they should behave like if they
##            were from same square, i mean not eating each other and can
##            set side by side"
##       x4 - "each one is real opponent will be cool, cool chaos i mean,
##            ok really do it then"
##   - THE RULES (the owner is a ludo player): ONE die; "if 6, drop a
##     chess-like and make another roll"; no drop-on-double-anything (one
##     die!); NO bonus move points for eating or for homing ("there is
##     games i played them where eating someone gives you 10 moving
##     points ... we do not need these bad stuff here")
##   - THE GUARDED DROPS: "the ludo game has the guarded areas of drop
##     point" - the colored start cells are safe; the four stars are the
##     classic board's own guarded cells
##   - THE BLOCKADE: "of two chess-likes landed and stayed on same
##     position, the opponent ones can not pass through it while the user
##     can pass through it but illegal to land the third one in it" -
##     with the mid-to-side slide for the pair
##   - eat = "you will return to the square ... will return like it's
##     sliding the whole way till it return to it's side of the square"
##   - THE DICE THEATER (the reference game does it worse - "they are not
##     as good as my imagination!"): the die is NOT always visible - it
##     fades out when done; the ROLL button shows in the turn army's
##     tray; tapping it fades the die in, it shuffles, it settles; "the
##     dice will be in much bigger place"; the same theater for the CPU
##   - THE ARROWS: "when there is legal moves, the game should point on
##     top of the chess-like with a differ arrow that will look different
##     from theme to another"; tapping the pawn paints arrows on the
##     legal areas (and on the base drop when it is legal)
##   - THE HOP WALK: "moving the chess-like should make a very cool
##     well-designed animation of walking step by step ... it should go a
##     little up, then move then drop"
##   - THE MARKS: "they called players as player 1..4, you can just make
##     them 1,2,3,4 marking positions, which is the correct way"
##   - THE COIN CLOCK: "make a gogacoin appear after 6 minutes, a ludo
##     game takes more than 15 minutes anyway" - on a cell that is
##     "legal for the player ... so it knows if it can reach it or not";
##     "passing through it collects it, no need to land on it"; "if
##     opponent stepped on it will take it"
##   - THE CPU: "there is no AI or profiles here, there is just a move
##     that will happen or not and pure RNG" - uniform among legal moves
##   - THE ECONOMY: "if user won, takes one score point, if lost, lose
##     one point, score bonus will be /1 (ludo turns always takes too
##     long anyway)"; no draws - the W/L widget only; "the loser plays
##     first"; TAP ANYWHERE TO START; the END button in the pause menu
##   - THE SHOP: 5 piece skins (the user's pawns only) and 5 themes (the
##     board and the feel) - "skins at the top and themes under them in
##     all other games" (the shelf order law), each skin theme-matched
##
## Probe contract: the whole rules core is STATIC - build_track /
## build_lanes / ring_at / teams_of / legal_moves / apply_move /
## coin_spots drive headless laws without the scene (the bovo contract).
## The scene rides probe_reset(mode, seed) + probe_step(dt) + probe_roll().

const PATH_LEN := 56        # steps from a start cell to HOME (51 ring
                            # cells + 5 lane cells + the home square -
                            # the classic 56-step walk)
const COIN_EVERY := 360.0   # the owner: one GOGACoin after each 6 minutes
const HOP_T := 0.16         # one hop of the walk (up, over, drop)
const FADE_T := 0.16        # the die's fade-in
const SHUF_T := 0.62        # the shuffle
const SETTLE_T := 0.16      # the settle bounce
const CPU_THINK := 0.65     # the CPU's roll beat (it only breathes)
const CPU_PICK := 0.5       # the CPU's move beat

# --------------------------------------------------------- the armies
## THE OWNER'S WHEEL ("green, yellow and red and blue, right? same as old
## windows logo? actually i am not sure + we can skin them normally
## anyway") - so the pens belong to the THEMES and the seats to the
## board: 1 top-left, 2 top-right, 3 bottom-right, 4 bottom-left,
## clockwise. The DEFAULT theme wears the classic ludo pens.
const ARMY_NAMES := {1: "1", 2: "2", 3: "3", 4: "4"}

# =========================================================== THE RULES CORE
## The track: 52 ring cells, CLOCKWISE, built from the classic 15x15
## board: each arm wears two track lines and one tip; the middle line of
## each arm is an army's home lane. Ring index 0 is army 1's start cell.

static func build_track() -> Array:
        var ring := []
        for x in range(1, 6):
                ring.append(Vector2i(x, 6))    # left arm, top line ->
        for y in range(5, -1, -1):
                ring.append(Vector2i(6, y))    # top arm, left column ^ (6)
        ring.append(Vector2i(7, 0))            # the top tip
        for y in range(0, 6):
                ring.append(Vector2i(8, y))    # top arm, right column v
        for x in range(9, 15):
                ring.append(Vector2i(x, 6))    # right arm, top line ->
        ring.append(Vector2i(14, 7))           # the right tip
        for x in range(14, 8, -1):
                ring.append(Vector2i(x, 8))    # right arm, bottom line <-
        for y in range(9, 15):
                ring.append(Vector2i(8, y))    # bottom arm, right column v
        ring.append(Vector2i(7, 14))           # the bottom tip
        for y in range(14, 8, -1):
                ring.append(Vector2i(6, y))    # bottom arm, left column ^
        for x in range(5, -1, -1):
                ring.append(Vector2i(x, 8))    # left arm, bottom line <-
        ring.append(Vector2i(0, 7))            # the left tip
        ring.append(Vector2i(0, 6))            # the loop closes (the one
                                               # cell army 1 never walks)
        return ring

static func build_lanes() -> Dictionary:
        return {
                1: [Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7),
                        Vector2i(4, 7), Vector2i(5, 7)],
                2: [Vector2i(7, 1), Vector2i(7, 2), Vector2i(7, 3),
                        Vector2i(7, 4), Vector2i(7, 5)],
                3: [Vector2i(13, 7), Vector2i(12, 7), Vector2i(11, 7),
                        Vector2i(10, 7), Vector2i(9, 7)],
                4: [Vector2i(7, 13), Vector2i(7, 12), Vector2i(7, 11),
                        Vector2i(7, 10), Vector2i(7, 9)],
        }

## the start cells live at these ring indices (army -> ring)
const RING_STARTS := {1: 0, 2: 13, 3: 26, 4: 39}
## THE GUARDED CELLS: the four starts + the four stars (the classic
## board's own guarded squares, 8 steps past every start)
const SAFE_RING := [0, 13, 26, 39, 8, 21, 34, 47]

static func ring_at(army: int, pos: int) -> int:
        ## the ring index this army walks at `pos` (-1 past the ring:
        ## the home lane and the home square are the army's own)
        if pos < 0 or pos > 50:
                return -1
        return (int(RING_STARTS[army]) + pos) % 52

## THE TEAMS (the ally law): x1 = one army each (only 1 and 2 sit);
## x2 = the user's 1 AND 3 wear ONE team, the CPU's 2 AND 4 the other;
## x4 = pure chaos, every army its own team.
static func teams_of(mode: int) -> Dictionary:
        if mode == 2:
                return {1: 1, 2: 2, 3: 1, 4: 2}
        if mode == 4:
                return {1: 1, 2: 2, 3: 3, 4: 4}
        return {1: 1, 2: 2}

static func is_safe_ring(ring: int) -> bool:
        return SAFE_RING.has(ring)

## the pieces at one ring cell: {team: [army, piece, ...]} (only ring
## positions count; lane cells are one army's private road)
static func ring_occ(poss: Array, ring: int, teams: Dictionary) -> Dictionary:
        var out := {}
        if ring < 0:
                return out
        for a in range(1, 5):
                if not teams.has(a):
                        continue
                for p in 4:
                        if ring_at(a, int(poss[(a - 1) * 4 + p])) == ring:
                                var t := int(teams[a])
                                if not out.has(t):
                                        out[t] = []
                                out[t].append([a, p])
        return out

## THE BLOCKADE: two pawns of ONE team on the cell
static func is_block_at(poss: Array, ring: int, teams: Dictionary) -> bool:
        var occ := ring_occ(poss, ring, teams)
        for t in occ:
                if (occ[t] as Array).size() >= 2:
                        return true
        return false

## can `army` LAND on the ring cell `ring`? returns {ok, eats} - the
## guarded cells coexist, a lone foe is eaten, a block refuses everyone
## (and a third friend too: "illegal to land the third one in it")
static func land_check(poss: Array, army: int, ring: int,
        teams: Dictionary) -> Dictionary:
        var my_team := int(teams[army])
        var occ := ring_occ(poss, ring, teams)
        var my_n := 0
        var eats := []
        for t in occ:
                if int(t) == my_team:
                        my_n += (occ[t] as Array).size()
                else:
                        for e in occ[t]:
                                eats.append(e)
        if my_n >= 2:
                return {"ok": false, "eats": []}    # the third pawn law
        if not (occ as Dictionary).is_empty() and is_block_at(poss, ring,
                        teams):
                return {"ok": false, "eats": []}    # a block refuses all
        if is_safe_ring(ring):
                return {"ok": true, "eats": []}     # THE GUARDED LAW
        return {"ok": true, "eats": eats}

## every legal move for `army` at `roll`: [{piece, np, eats}] - the pass
## law rides here: a foe blockade on the WAY refuses the whole move, the
## team's own blockade is a free road, and the home square wants EXACT
static func legal_moves(poss: Array, army: int, roll: int,
        teams: Dictionary) -> Array:
        var out := []
        var my_team := int(teams[army])
        for p in 4:
                var pos := int(poss[(army - 1) * 4 + p])
                if pos == int(PATH_LEN):
                        continue            # already home
                if pos < 0:
                        if roll != 6:
                                continue    # the drop wants a 6
                        var lc := land_check(poss, army,
                                        int(RING_STARTS[army]), teams)
                        if bool(lc["ok"]):
                                out.append({"piece": p, "np": 0,
                                        "eats": lc["eats"]})
                        continue
                var np := pos + roll
                if np > int(PATH_LEN):
                        continue            # the exact landing law
                # the pass-through: every ring cell on the way
                var blocked := false
                for k in range(pos + 1, np):
                        if k > 50:
                                break
                        var rk := ring_at(army, k)
                        var occ := ring_occ(poss, rk, teams)
                        for t in occ:
                                if int(t) != my_team \
                                                and (occ[t] as Array).size() \
                                                >= 2:
                                        blocked = true
                if blocked:
                        continue
                if np <= 50:
                        var lc := land_check(poss, army,
                                        ring_at(army, np), teams)
                        if bool(lc["ok"]):
                                out.append({"piece": p, "np": np,
                                        "eats": lc["eats"]})
                else:
                        # the lane (51..55) wears the 2-pawn cap (the
                        # blockade law in miniature); the home square (56)
                        # is THE CROWN - every pawn of the team rests
                        # there, all four complete. THE v0.3.9-13 CATCH:
                        # the cap on the home square strangled the
                        # round's end (a 3rd arriving pawn was refused
                        # FOREVER - the probe's endgame soak caught a
                        # round no one could ever win)
                        if np == int(PATH_LEN):
                                out.append({"piece": p, "np": np,
                                        "eats": []})
                        else:
                                var cap := 0
                                for q in 4:
                                        var qp := int(poss[(army - 1) * 4 \
                                                        + q])
                                        if qp == np:
                                                cap += 1
                                if cap < 2:
                                        out.append({"piece": p, "np": np,
                                                "eats": []})
        return out

## the pure result of one move: the mover walks, the eaten go home (no
## bonus moves, the owner's law - the drama is the slide, not the reward)
static func apply_move(poss_in: Array, army: int, piece: int, np: int,
        teams: Dictionary) -> Dictionary:
        var poss := poss_in.duplicate()
        poss[(army - 1) * 4 + piece] = np
        var eaten := []
        if np <= 50:
                var ring := ring_at(army, np)
                if not is_safe_ring(ring):
                        var occ := ring_occ(poss, ring, teams)
                        var my_team := int(teams[army])
                        for t in occ:
                                if int(t) == my_team:
                                        continue
                                for e in occ[t]:
                                        poss[(int(e[0]) - 1) * 4 \
                                                        + int(e[1])] = -1
                                        eaten.append({"army": int(e[0]),
                                                "piece": int(e[1])})
        return {"poss": poss, "eaten": eaten}

## THE COIN SPOTS: the ring cells the player's team can still reach - "a
## place that is currently legal for the player, legal = places of each
## chess-like so it knows if it can reach it or not". A cell under a foe
## blockade is dead to the walk, so it is dead to the coin too.
static func coin_spots(poss: Array, user_armies: Array,
        teams: Dictionary) -> Array:
        var spots := {}
        var my_team := int(teams[int(user_armies[0])])
        for a in user_armies:
                if int(teams[int(a)]) != my_team:
                        continue
                for p in 4:
                        var pos := int(poss[(int(a) - 1) * 4 + p])
                        if pos < 0 or pos > 50:
                                continue    # in base or past the ring
                        for k in range(1, 51 - pos + 1):
                                spots[(int(RING_STARTS[int(a)]) + pos + k) \
                                                % 52] = true
        var out := []
        for r in spots:
                if is_block_at(poss, int(r), teams):
                        continue
                out.append(int(r))
        out.sort()
        return out

## did a walker CROSS the coin cell this move? (the owner: "passing
## through it collects it, no need to land on it")
static func crosses_coin(army: int, from_pos: int, np: int,
        coin_ring: int) -> bool:
        if coin_ring < 0 or np > 50:
                return false
        for k in range(maxi(1, from_pos + 1), np + 1):
                if ring_at(army, k) == coin_ring:
                        return true
        return false

# ==================================================== THE TACTICAL CPU
## THE OWNER'S UPGRADE (v0.3.9-13, verbatim: "the opponent intelligence
## in this game i feel it is weak, i mean there can be many possibile
## ways to play the next move, like moving forward to win or release
## extra pawn or eat an opponent's pawn, there is logic that needs
## profiles and accurate working on it i mean to make it actually
## tactical!") - FOUR hidden moods (the dice game's hidden-mood law)
## weight ONE scorer; every legal move is scored on the POST-move board
## (the threat that matters is the threat AFTER the walk). Each CPU
## army draws its mood fresh at every round's start.
const CPU_MOODS := {
        "racer": {"win": 9.0, "eat": 2.0, "safe": 1.4, "drop": 1.8,
                "block": 0.8, "flee": 1.6, "risk": 0.9, "lane": 2.2,
                "step": 1.0, "jit": 0.6},
        "hunter": {"win": 7.0, "eat": 5.0, "safe": 1.0, "drop": 2.4,
                "block": 1.0, "flee": 0.9, "risk": 0.6, "lane": 1.2,
                "step": 0.7, "jit": 0.6},
        "guard": {"win": 7.0, "eat": 2.4, "safe": 2.6, "drop": 1.2,
                "block": 2.6, "flee": 2.2, "risk": 1.7, "lane": 1.6,
                "step": 0.7, "jit": 0.5},
        "chaos": {"win": 6.0, "eat": 3.0, "safe": 1.6, "drop": 1.8,
                "block": 1.4, "flee": 1.2, "risk": 0.8, "lane": 1.6,
                "step": 0.8, "jit": 2.4},
}

## is the ring cell `ring` threatened for `army`? (a FOE lands there
## with a raw 1..6). The guarded cells are calm, and the team's own
## TWO-pawn block refuses every landing - a wall cannot be eaten.
## `board` is the board the threat is read on (the post-move board for
## the landing check, the live board for the flee check).
static func threatened(board: Array, army: int, ring: int,
        teams: Dictionary) -> bool:
        if ring < 0 or is_safe_ring(ring):
                return false
        var my_team := int(teams[army])
        var occ := ring_occ(board, ring, teams)
        var my_n := 0
        for t in occ:
                if int(t) == my_team:
                        my_n += (occ[t] as Array).size()
        if my_n >= 2:
                return false    # our own wall - nobody lands here
        for fa in teams:
                if int(teams[fa]) == my_team:
                        continue
                for p in 4:
                        var fp := int(board[(int(fa) - 1) * 4 + p])
                        if fp < 0 or fp > 50:
                                continue
                        for k in range(1, 7):
                                if ring_at(int(fa), fp + k) == ring:
                                        return true
        return false

## THE SCORER: one move's worth in the mood's own eyes. Every check
## reads the POST-move board (apply_move's result) - the truth after
## the walk, not the guess before it.
static func cpu_score(poss: Array, army: int, m: Dictionary,
        teams: Dictionary, w: Dictionary) -> float:
        var piece := int(m["piece"])
        var np := int(m["np"])
        var pos := int(poss[(army - 1) * 4 + piece])
        var res := apply_move(poss, army, piece, np, teams)
        var npos: Array = res["poss"]
        var s := 0.0
        # THE WIN: the walk's whole point
        if np == int(PATH_LEN):
                s += 10.0 * float(w["win"])
        # THE EAT: send them home (each extra eater pays more)
        var eats_n := (m["eats"] as Array).size()
        if eats_n > 0:
                s += (7.0 + 2.0 * float(eats_n - 1)) * float(w["eat"])
        # THE DROP: a fresh pawn on the road (the start cell is guarded)
        if pos < 0:
                s += 5.0 * float(w["drop"])
        # THE LANE: the private road - nobody eats you there
        if np > 50 and np < int(PATH_LEN):
                s += 4.0 * float(w["lane"])
        # THE SAFE CELL: the guarded rest
        if np <= 50 and is_safe_ring(ring_at(army, np)):
                s += 3.0 * float(w["safe"])
        # THE WALL: pairing up on the landing cell (post-move truth)
        if np <= 50 and is_block_at(npos, ring_at(army, np), teams):
                s += 3.0 * float(w["block"])
        # THE FLEE: standing threatened, landing calm
        if pos >= 0 and pos <= 50:
                var here := ring_at(army, pos)
                if threatened(poss, army, here, teams):
                        var calm: bool = np > 50 \
                                        or not threatened(npos, army,
                                        ring_at(army, np), teams)
                        if calm:
                                s += 5.0 * float(w["flee"])
        # THE RISK: walking into a foe's 1..6 reach (the post-move board
        # - a threat we just ate no longer counts)
        if np <= 50 and threatened(npos, army, ring_at(army, np), teams):
                s -= 6.0 * float(w["risk"])
        # THE BROKEN WALL: leaving our own pair behind
        if pos >= 0 and pos <= 50 \
                        and is_block_at(poss, ring_at(army, pos), teams) \
                        and not (np <= 50 and is_block_at(npos,
                        ring_at(army, np), teams)):
                s -= 2.5 * float(w["block"])
        # THE STEP: forward is forward (the tie breaker)
        s += float(np) * 0.03 * float(w["step"])
        return s

## the mood's pick: the best-scoring legal move under its own weights,
## the jitter keeping every CPU its own creature
static func cpu_pick(poss: Array, army: int, roll: int,
        teams: Dictionary, mood: String,
        rng: RandomNumberGenerator) -> Dictionary:
        var moves := legal_moves(poss, army, roll, teams)
        if moves.is_empty():
                return {}
        var w: Dictionary = CPU_MOODS.get(mood, CPU_MOODS["chaos"])
        var best: Dictionary = moves[0]
        var best_s := -1e12
        for m in moves:
                var sc := cpu_score(poss, army, m, teams, w)
                sc += rng.randf_range(-float(w["jit"]), float(w["jit"]))
                if sc > best_s:
                        best_s = sc
                        best = m
        return best

# ============================================================ the themes
## 5 themes, the first is the default (the owner's law). A theme owns
## EVERYTHING except the user's pawns: the room, the frame, the tiles,
## the four army pens, the die, the arrow and the feel. The B&W theme is
## the owner's standing ask ("me as white and enemy black"). Each theme
## also carries "aim" (the selection/landing marker color - hard
## contrast against its own tiles) and "tray_ink" (the tray border -
## the v0.3.9-11 contrast round: a black tray on a black room must
## still read).
const THEMES := {
        "table": {"name": "THE TABLE", "price": 0, "style": "round",
                "room": Color("2a2114"), "floor": Color("1f1808"),
                "frame": Color("8a5a2e"), "frame_dark": Color("6e4522"),
                "tile": Color("f3e9d4"), "tile_line": Color("b8a37c"),
                "lane_ink": Color("3a2a14"), "aim": Color("0e6f5c"),
                "tray_ink": Color(0, 0, 0, 0.4),
                "armies": [Color("e0533f"), Color("2f9e55"),
                        Color("e8b23a"), Color("4179df")],
                "desc": "the warm wooden classic - red, green, yellow, blue"},
        "mono": {"name": "BLACK & WHITE", "price": 260, "style": "mono",
                "room": Color("181818"), "floor": Color("0c0c0c"),
                "frame": Color("f2f2f2"), "frame_dark": Color("cfcfcf"),
                "tile": Color("e4e4e4"), "tile_line": Color("6f6f6f"),
                "lane_ink": Color("111111"), "aim": Color("111111"),
                "tray_ink": Color(1, 1, 1, 0.8),
                "armies": [Color("ffffff"), Color("a6a6a6"),
                        Color("474747"), Color("050505")],
                "desc": "you are WHITE, the rivals wear the grays and black"},
        "pixel": {"name": "PIXEL", "price": 320, "style": "pixel",
                "room": Color("1a1c2c"), "floor": Color("10121e"),
                "frame": Color("29366f"), "frame_dark": Color("1d2752"),
                "tile": Color("c4b287"), "tile_line": Color("8a7a52"),
                "lane_ink": Color("29366f"), "aim": Color("1a1c2c"),
                "tray_ink": Color("141733"),
                "armies": [Color("e64539"), Color("38b764"),
                        Color("efc94c"), Color("3b9dd6")],
                "desc": "the 8-bit board - hard edges, hard miles"},
        "neon": {"name": "NEON", "price": 400, "style": "neon",
                "room": Color("060913"), "floor": Color("03050c"),
                "frame": Color("0e1430"), "frame_dark": Color("090d20"),
                "tile": Color("141d3a"), "tile_line": Color("27407a"),
                "lane_ink": Color("7ee8ff"), "aim": Color("7ee8ff"),
                "tray_ink": Color("27407a"),
                "armies": [Color("ff3860"), Color("3dff8e"),
                        Color("ffd23d"), Color("37c8ff")],
                "desc": "the glowing circuit - pawns of light on the dark"},
        "candy": {"name": "CANDY", "price": 460, "style": "round",
                "room": Color("f6d7e0"), "floor": Color("eebfcf"),
                "frame": Color("fff4f7"), "frame_dark": Color("f3dce6"),
                "tile": Color("ffffff"), "tile_line": Color("e3bfcf"),
                "lane_ink": Color("8a4a63"), "aim": Color("d4508c"),
                "tray_ink": Color(0.55, 0.28, 0.4, 0.55),
                "armies": [Color("ff6fa5"), Color("63d1a8"),
                        Color("ffc93c"), Color("9a8cf2")],
                "desc": "the sugar board - soft pawns, sweet miles"},
}

# ------------------------------------------------------- the piece skins
## THE THEME-OWNERSHIP LAW (the dice game's law, the pawn dialect): the
## theme owns everything but the USER's pawns - the equipped skin re-inks
## only those, on every theme (both armies in the x2 double - the ally
## law reads as one team).
const SKINS := {
        "theme": {"name": "THEME PAWNS", "price": 0,
                "col": Color(0, 0, 0), "ink": Color(0, 0, 0),
                "desc": "wear the theme's own pen for your pawns"},
        "ivory": {"name": "IVORY", "price": 150,
                "col": Color("f4ead2"), "ink": Color("4a3a1c"),
                "desc": "the carved classic - yours on any theme"},
        "jade": {"name": "JADE", "price": 220,
                "col": Color("3fae8a"), "ink": Color("0d3024"),
                "desc": "the lucky stone"},
        "rose": {"name": "ROSE", "price": 220,
                "col": Color("f27bb2"), "ink": Color("4d0e2b"),
                "desc": "the bubblegum pawn"},
        "onyx": {"name": "ONYX", "price": 300,
                "col": Color("23272e"), "ink": Color("e8e8e8"),
                "desc": "the shadow pawn - pale rings on black"},
}

# the pip seats of the die face (the dice game's own map)
const PIPS := {
        1: [[0.5, 0.5]],
        2: [[0.3, 0.3], [0.7, 0.7]],
        3: [[0.3, 0.3], [0.5, 0.5], [0.7, 0.7]],
        4: [[0.3, 0.3], [0.7, 0.3], [0.3, 0.7], [0.7, 0.7]],
        5: [[0.3, 0.3], [0.7, 0.3], [0.5, 0.5], [0.3, 0.7], [0.7, 0.7]],
        6: [[0.32, 0.28], [0.68, 0.28], [0.32, 0.5], [0.68, 0.5],
                [0.32, 0.72], [0.68, 0.72]],
}

# ============================================================ state
var mode := 1                 # x1 | x2 | x4 (the mode sheet's pick)
var teams := {}               # army -> team (teams_of(mode))
var playing: Array = [1, 2]   # the armies at the table (clockwise order)
var poss: Array = []          # 16 slots: (army-1)*4+piece -> pos
                              # -1 base, 0..55 the walk, 56 home
var state := "ready"          # ready | roll_wait | rolling | picking |
                              # walking | handoff | round_over
var turn_army := 1            # the army whose turn it is
var opener := 1               # who opens THIS round (the loser law)
var roll := 0                 # the settled face (0 = none yet)
var legal: Array = []         # the turn's legal moves
var sel_piece := -1           # the tapped pawn (-1 none)
var sel_moves: Array = []     # the tapped pawn's legal landings
var turn_note := ""           # the active tray's status line (the dice
                              # game's banner, the tray dialect)
var clock := 0.0              # the state machine's beat
var play_clock := 0.0         # THE COIN CLOCK (live play seconds)
var coin_ring := -1           # the coin's ring cell (-1 none)
var coin_t := 0.0
var rounds := 0
var wins := 0
var losses := 0
var streak := 0
var done := false             # the run's over flag (host owns the rest)
var cpu_moods := {}           # army -> mood key (THE TACTICAL CPU: the
                              # hidden profile, redrawn every round)

# the dice theater (one die, it travels to the turn army's tray)
var die_face := 1
var die_t0 := -1.0            # the theater's start (-1 hidden)
var die_alive := false        # the die is on the table
var die_fading := false       # the fade-out beat
var die_pos := Vector2.ZERO   # where the die sits right now

# the walk (THE HOP WALK)
var walk := {}                # {army, piece, pts, t0, np, coin_hop}
var slides: Array = []        # the eaten: {army, piece, pts, t0, dur}
var pair_off := {}            # "a_p" -> Vector2 (the block slide, the
                              # mid-to-side law, animated in the tick)

# the dust (the squares law) + the verdict glow
var _dust: Array = []
var _time := 0.0
var _rng := RandomNumberGenerator.new()

# the 2048 confirm law (stack-borne)
var _confirm_open_id := ""

# scene
var world: Node2D
var bg_l: Node2D
var board_l: Node2D
var pawn_l: Node2D
var fx_l: Node2D
var verdict_lbl: Label
var goals_row: Control
var ready_ui: Control = null
var board_origin := Vector2.ZERO
var cell := 30.0
var board_side := 450.0
var _track: Array = []
var _lanes: Dictionary = {}

# ============================================================ the scene

func _goga_setup() -> void:
        _rng.randomize()
        pause_end_run = true    # THE PONG LAW: the pause END banks (a ludo
                                # run has no natural death)
        _track = build_track()
        _lanes = build_lanes()
        teams = teams_of(1)
        playing = [1, 2]
        _fresh_poss()
        var vp := get_viewport_rect().size
        world = Node2D.new()
        add_child(world)
        bg_l = Node2D.new()
        bg_l.z_index = -10
        bg_l.draw.connect(_draw_bg)
        world.add_child(bg_l)
        board_l = Node2D.new()
        board_l.draw.connect(_draw_board)
        world.add_child(board_l)
        pawn_l = Node2D.new()
        pawn_l.draw.connect(_draw_pawns)
        world.add_child(pawn_l)
        fx_l = Node2D.new()
        fx_l.z_index = 5
        fx_l.draw.connect(_draw_fx)
        world.add_child(fx_l)
        _layout(vp)
        _build_widgets(vp)
        add_hud_button("SHOP", func(): _shop_open())
        Jukebox.music("res://assets/audio/music/ludo_theme.ogg")
        ## THE FLOW LAW: the optionals ask opens the game FIRST, the
        ## TAP ANYWHERE gate seats after the pick (the snakes board's
        ## own correction, the house keeps one flow)
        _mode_sheet()

func _fresh_poss() -> void:
        poss = []
        for i in 16:
                poss.append(-1)
        pair_off = {}
        walk = {}
        slides = []
        sel_piece = -1
        sel_moves = []
        legal = []
        roll = 0
        coin_ring = -1
        play_clock = 0.0
        die_alive = false
        die_fading = false
        die_t0 = -1.0

# ------------------------------------------------------- the look helpers

func _theme_id() -> String:
        var tid := Box.item_on(game_id, "theme")
        if not THEMES.has(tid):
                tid = "table"
        return tid

func _theme() -> Dictionary:
        return THEMES[_theme_id()]

## THE THEME-OWNERSHIP LAW: the equipped skin re-inks ONLY the user's
## pawns (both armies in the double - the ally law reads as one team)
func _skin_id() -> String:
        var sid := Box.item_on(game_id, "skin")
        if not SKINS.has(sid) or not Box.item_owned(game_id, "skin", sid):
                sid = "theme"
        return sid

func _is_user_army(a: int) -> bool:
        # r3 THE ABSOLUTE SEATS: army a IS room seat a on every device -
        # no rotation. The local army is the one whose seat's dev is mine;
        # the combo seat owns a second army.
        if lan_active:
                var idx: int = int(a) - 1
                if idx < 0 or idx >= lan_seats.size():
                        return false
                return String(lan_seats[idx].get("dev", "")) \
                                in [LAN.my_dev(), LAN.my_dev() + LAN.COMBO_DEV]
        return int(teams.get(a, -1)) == int(teams.get(1, 1)) \
                        and playing.has(a) and teams.has(1) \
                        and int(teams[1]) == int(teams[a])

## THE ABSOLUTE MAPS (r3): the army number IS the room seat - the seat
## dict of army p is lan_seats[p-1], everywhere.
func _lan_seat_of_army(p: int) -> Dictionary:
        var idx: int = int(p) - 1
        if idx < 0 or idx >= lan_seats.size():
                return {}
        return lan_seats[idx]

func _lan_seat_no_of_army(p: int) -> int:
        return int(p)

func _pawn_col(a: int) -> Color:
        var th: Array = _theme()["armies"]
        # r3 THE ABSOLUTE COLOR LAW: in a LAN match every army wears its
        # ROOM seat's color on every device - the owned skin is local and
        # would repaint me differently per device (the dice-conquer law).
        if not lan_active and _is_user_army(a):
                var sid := _skin_id()
                if sid != "theme":
                        return SKINS[sid]["col"]
        return th[(a - 1) % 4]

func _pawn_ink(a: int) -> Color:
        var col := _pawn_col(a)
        ## THE CONTRAST LAW (the B&W round): a dark pawn wears a PALE ring
        ## (a dark ring on a black pawn is invisible), a light pawn wears
        ## the deep one - the outline always reads
        var ink: Color = col.darkened(0.55) if col.v > 0.4 \
                        else col.lightened(0.78)
        if _is_user_army(a):
                var sid := _skin_id()
                if sid != "theme":
                        ink = SKINS[sid]["ink"]
        return ink

func _army_col(a: int) -> Color:
        var th: Array = _theme()["armies"]
        return th[(a - 1) % 4]

func _play_order() -> Array:
        ## the table's clockwise order, only the armies actually playing
        var out := []
        for a in [1, 2, 3, 4]:
                if playing.has(a):
                        out.append(a)
        return out

## THE HOP WALK's geometry: where a pawn at `pos` stands (piece picks the
## base socket; the walk points come from this)
func pos_point(a: int, pos: int, piece := 0) -> Vector2:
        if pos < 0:
                return _socket_point(a, piece)
        if pos <= 50:
                return _cell_point(_track[ring_at(a, pos)])
        if pos <= 55:
                return _cell_point(_lanes[a][pos - 51])
        return _cell_point(Vector2i(7, 7))   # the home square

func _cell_point(g: Vector2i) -> Vector2:
        return board_origin + Vector2((float(g.x) + 0.5) * cell,
                        (float(g.y) + 0.5) * cell)

func _socket_point(a: int, piece: int) -> Vector2:
        ## THE NEST (the owner's v0.3.9-11 round: "the 4 places of a
        ## chess-like are wrong, they should be at the internal edges of
        ## the square") - the classic yard: a centered inner plate (3x3)
        ## and the four seats AT ITS CORNERS, not a loose 2x2 floating
        ## near the outer corner. THE SEAT TRUTH (the owner's v0.3.9-13
        ## round: player 1's seats were accurate but the other three
        ## armies' seats sat OUTSIDE their plates - the mirrored bases
        ## need the mirrored offsets: the seat x/y are the base origin
        ## +1.95/+4.05, never a raw 10.05 which lands left of the
        ## right-side plates)
        var bx := 1.95 if a == 1 or a == 4 else 10.95
        var by := 1.95 if a == 1 or a == 2 else 10.95
        var dx := 2.1 * float(piece % 2)
        var dy := 2.1 * float(piece / 2)
        return board_origin + Vector2((bx + dx) * cell, (by + dy) * cell)

func _cell_rect(g: Vector2i) -> Rect2:
        return Rect2(board_origin + Vector2(float(g.x) * cell,
                        float(g.y) * cell), Vector2(cell, cell))

# ------------------------------------------------------------- the layout

func _layout(vp: Vector2) -> void:
        var banner := banner_bottom()
        var top_y := 96.0
        var tray_h := 74.0
        var bot_y := vp.y - banner - 6.0
        ## THE SLAB SEAT LAW (the owner: "the position of players 3,4
        ## badge is slightly overlapped with the board"): the frame slab +
        ## its shadow reach past board_side by up to ~48px on the biggest
        ## cells - the bottom trays seat BELOW that overhang, and the
        ## layout reserves the room for it
        const SLAB_SEAT := 62.0
        var avail := (bot_y - tray_h - SLAB_SEAT) \
                        - (top_y + tray_h + 14.0)
        board_side = minf(vp.x - 14.0, avail)
        board_side = maxf(board_side, 220.0)
        cell = board_side / 15.0
        var spare := avail - board_side
        board_origin = Vector2((vp.x - board_side) * 0.5,
                        top_y + tray_h + 14.0 + maxf(0.0, spare * 0.5))
        _place_texts(vp)
        bg_l.queue_redraw()
        board_l.queue_redraw()
        pawn_l.queue_redraw()
        fx_l.queue_redraw()

func _place_texts(vp: Vector2) -> void:
        if verdict_lbl != null:
                verdict_lbl.position = Vector2(0, board_origin.y
                                + board_side * 0.5 - 60.0)
                verdict_lbl.custom_minimum_size = Vector2(vp.x, 56)

## the tray seats: 1 top-left, 2 top-right, 3 bottom-right, 4 bottom-left
## (the table's own corners - the numerals the owner asked for)
func _tray_rect(a: int) -> Rect2:
        var vp := get_viewport_rect().size
        var tw := minf(210.0, board_side * 0.46)
        var th := 74.0
        var top_y := 96.0
        var banner := banner_bottom()
        ## the slab overhang (frame + shadow) - the trays never sit under it
        var slab_ext := maxf(10.0, cell * 0.5) + 12.0
        var by := board_origin.y + board_side + slab_ext + 10.0
        match a:
                1:
                        return Rect2(board_origin.x, top_y, tw, th)
                2:
                        return Rect2(board_origin.x + board_side - tw,
                                        top_y, tw, th)
                3:
                        return Rect2(board_origin.x + board_side - tw,
                                        by, tw, th)
                4:
                        return Rect2(board_origin.x, by, tw, th)
        return Rect2(0, 0, 0, 0)

## the die window inside a tray (THE BIGGER PLACE - the owner's ask);
## it is ALSO the roll button now (the grayed waiting die is the button)
func _die_rect(a: int) -> Rect2:
        var tr := _tray_rect(a)
        var s := minf(58.0, tr.size.y * 0.78)
        return Rect2(tr.position.x + tr.size.x - s - 12.0,
                        tr.position.y + (tr.size.y - s) * 0.5, s, s)

# --------------------------------------------------------- the widget row

func _build_widgets(vp: Vector2) -> void:
        # THE W-L CARDS (the squares law: ludo cannot tie - first full
        # team home takes the round)
        goals_row = Control.new()
        goals_row.custom_minimum_size = Vector2(108.0 * 2.0 + 8.0, 64.0)
        goals_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        goals_row.draw.connect(_draw_goal_cards.bind(goals_row))
        _hud_row.add_child(goals_row)
        var score_chip: Control = _score_label.get_parent().get_parent()
        # THE SEAT LAW: the cards seat BEFORE the score chip
        _hud_row.move_child(goals_row, score_chip.get_index())
        verdict_lbl = Arc.label("", 40, Color(1, 1, 1, 0.95))
        verdict_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        verdict_lbl.visible = false
        world.add_child(verdict_lbl)
        _place_texts(vp)

func _draw_goal_cards(c: Control) -> void:
        var cw := 108.0
        var ch := 46.0
        var gapw := 8.0
        var cols := [Color("58c470"), Color("e8574a")]
        var letters := ["W", "L"]
        var f := ThemeDB.fallback_font
        var mid_y := c.size.y * 0.5
        var x0 := c.size.x * 0.5
        for i in 2:
                var x: float = (cw + gapw) * (float(i) - 0.5) + x0
                var r := Rect2(x - cw * 0.5, mid_y - ch * 0.5, cw, ch)
                c.draw_rect(Rect2(r.position + Vector2(4, 4), r.size),
                                Color(0.09, 0.05, 0.02, 0.85))
                c.draw_rect(r, Color(1, 1, 1, 0.95))
                c.draw_rect(r, cols[i], false, 5.0)
                var num: int = [wins, losses][i]
                c.draw_string(f, Vector2(x - cw * 0.5 + 10.0,
                                mid_y + 15.0), letters[i],
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 26, cols[i])
                c.draw_string(f, Vector2(x - cw * 0.5 + 36.0,
                                mid_y + 17.0), str(num),
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Arc.INK)

func _refresh_widget() -> void:
        if goals_row != null:
                goals_row.queue_redraw()

# ------------------------------------------------------- the ready gate

func _build_ready() -> void:
        var vp := get_viewport_rect().size
        ready_ui = Control.new()
        ready_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        ready_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hud.add_child(ready_ui)
        _hud.move_child(ready_ui, 0)
        var l := Arc.label("TAP ANYWHERE TO START", 46, Color(1, 1, 1, 0.95))
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

func _gate_down() -> void:
        if ready_ui != null and is_instance_valid(ready_ui):
                ready_ui.queue_free()
                ready_ui = null

# ============================================================ the drawing

## THE ROOM: wall above, floor below, one honest divider (the fourline
## room law - flat theme colors, primitives only)
func _draw_bg() -> void:
        var vp := get_viewport_rect().size
        var th := _theme()
        bg_l.draw_rect(Rect2(Vector2.ZERO, vp), th["room"])
        var fy := vp.y * 0.82
        bg_l.draw_rect(Rect2(0, fy, vp.x, vp.y - fy), th["floor"])
        bg_l.draw_rect(Rect2(0, fy - 3.0, vp.x, 3.0),
                        (th["floor"] as Color).lightened(0.12))

func _draw_rr(c: CanvasItem, r: Rect2, radius: float, col: Color,
        filled := true, width := -1.0) -> void:
        if radius <= 0.5:
                c.draw_rect(r, col, filled, width)
                return
        var rad := minf(radius, minf(r.size.x, r.size.y) * 0.5)
        var pts := PackedVector2Array()
        var corners := [
                Vector2(r.end.x - rad, r.position.y + rad),
                Vector2(r.end.x - rad, r.end.y - rad),
                Vector2(r.position.x + rad, r.end.y - rad),
                Vector2(r.position.x + rad, r.position.y + rad),
        ]
        for k in 4:
                var cc: Vector2 = corners[k]
                for a in range(0, 91, 15):
                        var ang := deg_to_rad(float(a)) \
                                        - PI * 0.5 + PI * 0.5 * float(k)
                        pts.append(cc + Vector2(cos(ang), sin(ang)) * rad)
        if filled:
                c.draw_colored_polygon(pts, col)
        else:
                c.draw_polyline(pts + PackedVector2Array([pts[0]]), col,
                                width)

## THE BOARD: the classic 15x15 - the frame slab, the track tiles, the
## guarded stars, the four bases with their nests, the home lanes in the
## army pens' colors and the center's four triangles pointing home
func _draw_board() -> void:
        var th := _theme()
        var style: String = th["style"]
        var radius := cell * 0.18
        if style == "pixel":
                radius = 0.0
        var slab_r := maxf(10.0, cell * 0.5)
        var slab := Rect2(board_origin - Vector2(slab_r, slab_r),
                        Vector2(board_side + slab_r * 2.0,
                        board_side + slab_r * 2.0))
        board_l.draw_rect(Rect2(slab.position + Vector2(8, 12), slab.size),
                        Color(0, 0, 0, 0.35))
        _draw_rr(board_l, slab, slab_r * 0.7, th["frame"])
        _draw_rr(board_l, Rect2(slab.position.x, slab.end.y - 10.0,
                        slab.size.x, 10.0), slab_r * 0.5, th["frame_dark"])
        # the track + lane tiles
        var painted := {}
        for a in 4:
                for g in _lanes[a + 1]:
                        painted[g] = true
                        var lr := _cell_rect(g)
                        var shrink := cell * 0.07
                        var lac: Color = _army_col(a + 1)
                        lac = lac.lightened(0.28) if lac.v <= 0.8 \
                                        else lac.darkened(0.05)
                        var lrr := Rect2(lr.position
                                        + Vector2(shrink, shrink),
                                        lr.size - Vector2(shrink, shrink) * 2)
                        _draw_rr(board_l, lrr, radius * 0.5, lac)
                        ## THE LANE RIM: the lane reads even when its fill
                        ## sits close to the tile (the B&W round)
                        _draw_rr(board_l, lrr, radius * 0.5,
                                        (_army_col(a + 1) as Color)
                                        .darkened(0.25), false, 2.0)
        for i in _track.size():
                var g: Vector2i = _track[i]
                if painted.has(g):
                        continue
                var r := _cell_rect(g)
                var shrink := cell * 0.07
                var tile_col: Color = th["tile"]
                var guarded := false
                # the guarded drops wear their army's pen (the owner's
                # "guarded areas of drop point")
                for a in RING_STARTS:
                        if int(RING_STARTS[a]) == i:
                                var ac: Color = _army_col(a)
                                tile_col = ac.lightened(0.34) if ac.v <= 0.8 \
                                                else ac.darkened(0.05)
                                guarded = true
                var gr := Rect2(r.position + Vector2(shrink, shrink),
                                r.size - Vector2(shrink, shrink) * 2)
                _draw_rr(board_l, gr, radius * 0.5, tile_col)
                if guarded:
                        ## THE GUARD RIM: a white start cell on cream tiles
                        ## still reads as guarded (the B&W round)
                        _draw_rr(board_l, gr, radius * 0.5,
                                        th["lane_ink"], false, 2.2)
        # the grid lines over the cross (the tiles read as one board)
        var line_c: Color = th["tile_line"]
        line_c.a = 0.5
        for g in _track:
                var r2 := _cell_rect(g)
                board_l.draw_rect(r2, line_c, false, 1.2)
        for a in 4:
                for g in _lanes[a + 1]:
                        board_l.draw_rect(_cell_rect(g), line_c, false, 1.2)
        # THE STARS: the four guarded mid cells (the classic board's
        # marks) - drawn in the lane ink so they hold on every theme
        for i in [8, 21, 34, 47]:
                var g3: Vector2i = _track[i]
                var c3 := _cell_point(g3)
                _draw_star(c3, cell * 0.26, (th["lane_ink"] as Color))
        # THE BASES: four 6x6 yards - the slab, the centered inner PLATE
        # (the classic paper square) and the four seats at the plate's
        # corners (the owner's internal-edges round, v0.3.9-11)
        for a in 4:
                var army := a + 1
                var bx0 := 0 if army == 1 or army == 4 else 9
                var by0 := 0 if army == 1 or army == 2 else 9
                var br := Rect2(board_origin + Vector2(bx0 * cell,
                                by0 * cell), Vector2(cell * 6, cell * 6))
                var base_col: Color = _army_col(army)
                if not playing.has(army):
                        base_col = (base_col as Color).darkened(0.35)
                        base_col.a = 0.55
                _draw_rr(board_l, Rect2(br.position + Vector2(cell * 0.3,
                                cell * 0.3), br.size - Vector2(cell * 0.6,
                                cell * 0.6)), cell * 0.9,
                                (base_col as Color).lightened(0.42))
                _draw_rr(board_l, Rect2(br.position + Vector2(cell * 0.9,
                                cell * 0.9), br.size - Vector2(cell * 1.8,
                                cell * 1.8)), cell * 0.7, base_col)
                # THE PLATE: the classic inner paper square (1.5..4.5)
                var plate := Rect2(br.position + Vector2(cell * 1.5,
                                cell * 1.5), Vector2(cell * 3, cell * 3))
                _draw_rr(board_l, plate, cell * 0.42, th["tile"])
                _draw_rr(board_l, plate, cell * 0.42,
                                (base_col as Color).darkened(0.15),
                                false, 2.4)
                # the four seats AT THE PLATE'S CORNERS
                for p in 4:
                        var sp := _socket_point(army, p)
                        board_l.draw_circle(sp, cell * 0.30,
                                        Color(1, 1, 1, 0.65))
                        board_l.draw_circle(sp, cell * 0.30,
                                        (base_col as Color).darkened(0.2),
                                        false, 2.4)
                # THE MARK: the bare numeral, seated mid-plate (the
                # owner's "1,2,3,4" law)
                var f := ThemeDB.fallback_font
                var nc := plate.get_center()
                var mark_col: Color = (base_col as Color).darkened(0.3)
                if (mark_col as Color).v < 0.35:
                        mark_col = (base_col as Color).lightened(0.62)
                board_l.draw_string(f, nc + Vector2(-cell * 0.6,
                                cell * 0.24), str(army),
                                HORIZONTAL_ALIGNMENT_CENTER, cell * 1.2,
                                int(cell * 1.05), mark_col)
        # THE HOME: the four triangles pointing in, NOTHING under them
        # (the owner's v0.3.9-13 round: "the winning area has a circle
        # under the square, remove that circle" - the medallion is gone,
        # the tiles' own cream reads behind the triangles)
        var tri := [
                {"army": 2, "pts": [Vector2i(6, 6), Vector2i(8, 6),
                        Vector2i(7, 7)]},
                {"army": 3, "pts": [Vector2i(8, 6), Vector2i(8, 8),
                        Vector2i(7, 7)]},
                {"army": 4, "pts": [Vector2i(8, 8), Vector2i(6, 8),
                        Vector2i(7, 7)]},
                {"army": 1, "pts": [Vector2i(6, 8), Vector2i(6, 6),
                        Vector2i(7, 7)]},
        ]
        for t in tri:
                var pts2 := PackedVector2Array()
                for g in t["pts"]:
                        pts2.append(_cell_point(g))
                var col: Color = _army_col(t["army"])
                if not playing.has(t["army"]):
                        col = (col as Color).darkened(0.35)
                        col.a = 0.55
                board_l.draw_colored_polygon(pts2, col)

func _draw_star(at: Vector2, r: float, col: Color) -> void:
        var pts := PackedVector2Array()
        for k in 8:
                var ang := PI * 0.25 * float(k) - PI * 0.5
                var rr := r if k % 2 == 0 else r * 0.42
                pts.append(at + Vector2(cos(ang), sin(ang)) * rr)
        board_l.draw_colored_polygon(pts, Color(col, 0.8))

## THE PAWN (the chess-like figure): a head, a neck, a base - primitives
## only, the theme's pen or the user's skin
func _draw_pawn(c: CanvasItem, at: Vector2, a: int, scale := 1.0) -> void:
        var col := _pawn_col(a)
        var ink := _pawn_ink(a)
        var bw := cell * 0.40 * scale
        var head_r := cell * 0.125 * scale
        var body_h := cell * 0.26 * scale
        var base_w := cell * 0.46 * scale
        var base_h := cell * 0.13 * scale
        var base_c := at + Vector2(0, cell * 0.16 * scale)
        var head_c := at + Vector2(0, -body_h * 0.55)
        var style: String = _theme()["style"]
        var radius := 3.0
        if style == "pixel":
                radius = 0.0
        # the shadow
        _draw_rr(c, Rect2(base_c + Vector2(2, 3) - Vector2(base_w * 0.5,
                base_h * 0.5), Vector2(base_w, base_h)), radius,
                Color(0, 0, 0, 0.30))
        # the base
        _draw_rr(c, Rect2(base_c - Vector2(base_w * 0.5, base_h * 0.5),
                Vector2(base_w, base_h)), radius, col.darkened(0.18))
        # the neck (a trapezoid widening down)
        var neck := PackedVector2Array([
                head_c + Vector2(-head_r * 0.7, head_r * 0.5),
                head_c + Vector2(head_r * 0.7, head_r * 0.5),
                base_c + Vector2(base_w * 0.24, -base_h * 0.4),
                base_c + Vector2(-base_w * 0.24, -base_h * 0.4),
        ])
        c.draw_colored_polygon(neck, col)
        # the head
        c.draw_circle(head_c, head_r, col)
        # the ink lines (the character)
        c.draw_circle(head_c, head_r, ink, false, 1.6)
        c.draw_circle(head_c + Vector2(-head_r * 0.3, -head_r * 0.3),
                head_r * 0.22, Color(1, 1, 1, 0.5))

## the pawn's seat key: ring cells are SHARED seats (the ally law: two
## armies of one team can meet on the loop), lanes are private, bases
## and home are their own
func _cell_key(a: int, piece: int) -> String:
        var pos := int(poss[(a - 1) * 4 + piece])
        if pos < 0:
                return "b%d_%d" % [a, piece]
        if pos <= 50:
                return "r%d" % ring_at(a, pos)
        if pos <= 55:
                return "l%d_%d" % [a, pos]
        return "h%d_%d" % [a, piece]

## the pair offset (THE BLOCKADE's mid-to-side slide): two pawns of one
## team share a cell by stepping aside, animated in the tick
func _pair_target(a: int, piece: int) -> Vector2:
        var key := _cell_key(a, piece)
        if key.begins_with("b") or key.begins_with("h"):
                return Vector2.ZERO
        var mates := []
        for aa in 4:
                var army := aa + 1
                if not playing.has(army):
                        continue
                for p in 4:
                        if _cell_key(army, p) == key:
                                mates.append([army, p])
        if mates.size() < 2:
                return Vector2.ZERO
        var idx := 0
        for i in mates.size():
                if int(mates[i][0]) == a and int(mates[i][1]) == piece:
                        idx = i
        var pos := int(poss[(a - 1) * 4 + piece])
        # the sideways direction: perpendicular to the travel
        var dir := Vector2(1, 0)
        if pos <= 50:
                var ring := ring_at(a, pos)
                var g0: Vector2i = _track[ring]
                var g1: Vector2i = _track[(ring + 1) % 52]
                var dv := Vector2(g1 - g0)
                dir = Vector2(0, 1) if absf(dv.x) > 0.5 else Vector2(1, 0)
        var side := 1.0 if idx % 2 == 0 else -1.0
        return dir * cell * 0.18 * side

func _pawn_point(a: int, piece: int) -> Vector2:
        var pos := int(poss[(a - 1) * 4 + piece])
        var at := pos_point(a, pos, piece)
        var key := "%d_%d" % [a, piece]
        if pair_off.has(key):
                at += pair_off[key]
        return at

func _draw_pawns() -> void:
        # the drawn order: the board first, the walker on top, the slides
        # above all (the eaten ride their way home)
        var walker_key := ""
        if state == "walking" and not walk.is_empty():
                walker_key = "%d_%d" % [int(walk["army"]),
                                int(walk["piece"])]
        var slide_keys := {}
        for s in slides:
                slide_keys["%d_%d" % [int(s["army"]), int(s["piece"])]] = true
        for a in 4:
                var army := a + 1
                if not playing.has(army):
                        continue
                for p in 4:
                        var key := "%d_%d" % [army, p]
                        if key == walker_key or slide_keys.has(key):
                                continue
                        var pos := int(poss[(army - 1) * 4 + p])
                        if pos == int(PATH_LEN):
                                _draw_home_dot(army, p)
                                continue
                        var pt := _pawn_point(army, p)
                        ## THE CHOSEN LIFT: the tapped pawn rises and grows
                        ## - the tap ANSWERS (the v0.3.9-11 round)
                        if state == "picking" and army == turn_army \
                                        and _is_user_army(army) \
                                        and int(sel_piece) == p:
                                _draw_pawn(pawn_l, pt + Vector2(0,
                                                -cell * 0.14), army, 1.12)
                                continue
                        _draw_pawn(pawn_l, pt, army)
        # the walker rides its own path (THE HOP WALK)
        if walker_key != "":
                var at := _walk_point()
                _draw_pawn(pawn_l, at, int(walk["army"]), 1.06)
        # the slides (the eaten sliding all the way home)
        for s in slides:
                _draw_pawn(pawn_l, _slide_point(s), int(s["army"]), 0.94)

func _draw_home_dot(army: int, piece: int) -> void:
        ## a homed pawn rests as a small disc inside its army's triangle
        var g := Vector2i(7, 7)
        match army:
                1:
                        g = Vector2i(6, 7)
                2:
                        g = Vector2i(7, 6)
                3:
                        g = Vector2i(8, 7)
                4:
                        g = Vector2i(7, 8)
        var at := _cell_point(g)
        var along := Vector2(0, 1) if army == 2 or army == 4 \
                        else Vector2(1, 0)
        at += along * (float(piece - 1) - 1.0) * cell * 0.22
        pawn_l.draw_circle(at, cell * 0.11, _pawn_col(army))
        pawn_l.draw_circle(at, cell * 0.11, _pawn_ink(army), false, 1.4)

func _walk_point() -> Vector2:
        var pts: PackedVector2Array = walk["pts"]
        var n := pts.size()
        if n <= 1:
                return pts[0] if n == 1 else Vector2.ZERO
        var k := clampf((_time - float(walk["t0"])) / HOP_T, 0.0,
                        float(n - 1))
        var i := int(k)
        if i >= n - 1:
                return pts[n - 1]
        var f2 := k - float(i)
        var at: Vector2 = pts[i].lerp(pts[i + 1], f2)
        # the hop's arc: a little up, over, drop (the owner's own walk)
        at.y -= sin(f2 * PI) * cell * 0.22
        return at

func _slide_point(s: Dictionary) -> Vector2:
        var pts: PackedVector2Array = s["pts"]
        var n := pts.size()
        if n <= 1:
                return pts[0] if n == 1 else Vector2.ZERO
        var k := clampf((_time - float(s["t0"])) / float(s["dur"]), 0.0, 1.0)
        k = 1.0 - (1.0 - k) * (1.0 - k)     # the ease-out glide
        var fk := k * float(n - 1)
        var i := int(fk)
        if i >= n - 1:
                return pts[n - 1]
        return pts[i].lerp(pts[i + 1], fk - float(i))

# ------------------------------------------------- the trays + the fx

## THE DICE THEATER: each tray wears its numeral, its glow when the turn
## is there, the die's own pad, and the die itself (the theater: fade in,
## shuffle, settle - then fade out when done). THE WAITING DIE (the
## owner's v0.3.9-11 redesign: "instead of roll show the dice grayed-out
## like it's waiting, when user tap it, the thing will happen") - the old
## ROLL pill is gone; the grayed die IS the button.
func _draw_trays() -> void:
        var f := ThemeDB.fallback_font
        var tink: Color = _theme()["tray_ink"]
        for army in playing:
                var tr := _tray_rect(army)
                var active: bool = army == turn_army \
                                and state != "round_over"
                var col := _army_col(army)
                # the tray: shadow, fill, the theme's rim (a black tray on
                # a black room must still read - the B&W round)
                var fill: Color = (col as Color).darkened(0.42) if not active \
                                else (col as Color).darkened(0.18)
                fx_l.draw_rect(Rect2(tr.position + Vector2(4, 5), tr.size),
                                Color(0, 0, 0, 0.30))
                _draw_rr(fx_l, tr, 12.0, fill)
                _draw_rr(fx_l, tr.grow(-1), 11.0, tink, false, 2.0)
                ## THE ADAPTIVE TRAY INK: white words on a light tray
                ## (mono's white army) are invisible - the ink follows
                ## the fill
                var word: Color = Color(0.07, 0.07, 0.08, 0.95) \
                                if (fill as Color).v > 0.5 \
                                else Color(1, 1, 1, 0.95)
                var word_soft: Color = Color(0.07, 0.07, 0.08, 0.75) \
                                if (fill as Color).v > 0.5 \
                                else Color(1, 1, 1, 0.75)
                if active:
                        var pulse := 0.5 + 0.5 * sin(_time * 5.0)
                        _draw_rr(fx_l, tr.grow(2.0), 13.0,
                                        Color(1, 1, 1, 0.10 + 0.10 * pulse))
                # THE DIE PAD: the die's own seat (a soft inset plate -
                # the die rests somewhere, always)
                var dr := _die_rect(army)
                _draw_rr(fx_l, dr.grow(7.0), 12.0, Color(0, 0, 0, 0.22))
                _draw_rr(fx_l, dr.grow(7.0), 12.0,
                                Color(1, 1, 1, 0.14), false, 1.6)
                # THE WAITING DIE: grayed out at its seat, breathing -
                # the user taps IT to roll
                if active and _is_user_army(army) and state == "roll_wait" \
                                and not die_alive:
                        var breath := 0.5 + 0.5 * sin(_time * 3.4)
                        var ring: Color = Color(1, 1, 1, 0.26 + 0.24 * breath) \
                                        if (fill as Color).v <= 0.5 \
                                        else Color(0.1, 0.1, 0.1,
                                        0.3 + 0.25 * breath)
                        _draw_rr(fx_l, dr.grow(9.0 + 3.0 * breath), 14.0,
                                        ring, false, 2.6)
                        _draw_waiting_die(dr)
                # THE MARK: the bare numeral + the seat's name in a LAN
                # match (THE CPU WORD LAW - a human never reads "CPU")
                var who := "YOU" if _is_user_army(army) \
                                else (_lan_name_of_army(army) if lan_active else "CPU")
                fx_l.draw_string(f, tr.position + Vector2(12.0,
                                tr.size.y * 0.52), str(army),
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 34, word)
                fx_l.draw_string(f, tr.position + Vector2(34.0,
                                tr.size.y * 0.40), who,
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
                                word_soft)
                if active and turn_note != "":
                        fx_l.draw_string(f, tr.position + Vector2(34.0,
                                        tr.size.y * 0.82), turn_note,
                                        HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
                                        word_soft)
        # the die itself (the theater)
        if die_alive:
                _draw_die()

## the grayed die at rest - an honest EMPTY face (no pips: no face has
## settled yet), sitting quietly at its pad
func _draw_waiting_die(dr: Rect2) -> void:
        var style: String = _theme()["style"]
        var radius := dr.size.x * 0.2
        if style == "pixel":
                radius = 0.0
        _draw_rr(fx_l, Rect2(dr.position + Vector2(2, 4), dr.size),
                        radius, Color(0, 0, 0, 0.30))
        _draw_rr(fx_l, dr, radius, Color(0.86, 0.86, 0.86, 0.94))
        _draw_rr(fx_l, dr, radius, Color(0.30, 0.30, 0.30, 0.85),
                        false, 2.0)

func _draw_die() -> void:
        # the die sits in its tray's window - big, but never over the HUD
        var ds := minf(cell * 1.8, 66.0)
        var r := Rect2(die_pos - Vector2(ds * 0.5, ds * 0.5),
                        Vector2(ds, ds))
        var style: String = _theme()["style"]
        var radius := r.size.x * 0.2
        if style == "pixel":
                radius = 0.0
        var age := _time - die_t0
        var alpha := 1.0
        if die_fading:
                alpha = clampf(1.0 - age / FADE_T, 0.0, 1.0)
        elif age < FADE_T:
                alpha = clampf(age / FADE_T, 0.0, 1.0)
        var ink := Color(0.12, 0.10, 0.08)
        var face := Color(1, 1, 1)
        if style == "neon":
                face = Color("eef6ff")
        # the shuffle: the die jitters, the face flickers
        var jitter := Vector2.ZERO
        if not die_fading and age < FADE_T + SHUF_T:
                var j := (age / SHUF_T) * 26.0
                jitter = Vector2(sin(_time * 41.0) * 2.2,
                                cos(_time * 37.0) * 2.2)
                ink = Color(0.12, 0.10, 0.08)
                face = Color(1, 1, 1, 1.0)
                # the flicker face (settle shows the truth)
                var flick := 1 + (int(j) % 6)
                if age < FADE_T + SHUF_T - SETTLE_T:
                        _draw_die_face(r, jitter, flick, face, ink,
                                        radius, alpha)
                        return
        _draw_die_face(r, jitter, die_face, face, ink, radius, alpha)

func _draw_die_face(r: Rect2, jitter: Vector2, face_n: int,
        face: Color, ink: Color, radius: float, alpha: float) -> void:
        var rr := Rect2(r.position + jitter, r.size)
        _draw_rr(fx_l, rr.grow(2.0), radius + 2.0, Color(0, 0, 0, 0.35 * alpha))
        _draw_rr(fx_l, rr, radius, Color(face, alpha))
        var pr := r.size.x * 0.085
        var seats: Array = PIPS[clampi(face_n, 1, 6)]
        for seat in seats:
                var c := rr.position + Vector2(float(seat[0]) * rr.size.x,
                                float(seat[1]) * rr.size.y)
                fx_l.draw_circle(c, pr, Color(ink, alpha))

## the arrows + THE LANDING MARKS (the owner's v0.3.9-11 round: tapping a
## chess-like must ANSWER - the tapped pawn lifts and glows, every legal
## landing wears a big bold marker in the theme's aim color, an eat wears
## the danger red; "a differ arrow that will look different from theme to
## another" stays the law)
func _draw_arrows() -> void:
        if state != "picking":
                return
        var style: String = _theme()["style"]
        var aim: Color = _theme()["aim"]
        var danger := Color("e8574a")
        # the movable pawns' bouncing arrows (the chosen one lifts instead)
        var seen := {}
        for m in legal:
                var pk := int(m["piece"])
                if seen.has(pk):
                        continue
                seen[pk] = true
                if int(sel_piece) == pk:
                        continue
                # the arrow rides the pawn's head
                var at := _pawn_point(turn_army, pk)
                var bob := sin(_time * 6.0) * cell * 0.10
                var top := at + Vector2(0, -cell * 0.62 + bob)
                _draw_arrow(top, PI * 0.5, aim, style, 1.3)
        # THE CHOSEN PAWN: a pulsing glow ring on its floor seat + the
        # pawn itself lifts (drawn in _draw_pawns)
        if sel_piece >= 0:
                var pulse := 0.5 + 0.5 * sin(_time * 6.5)
                var sat := _pawn_point(turn_army, int(sel_piece))
                fx_l.draw_circle(sat, cell * 0.5,
                                Color(aim, 0.16 + 0.14 * pulse))
                fx_l.draw_circle(sat, cell * 0.5, Color(aim, 0.95),
                                false, 3.0)
                # THE LANDINGS: big bold markers - the answer the owner
                # asked for ("show me where to go"); an eat lands in red
                for m in sel_moves:
                        var dest: Vector2 = pos_point(turn_army,
                                        int(m["np"]), int(m["piece"]))
                        var eats: bool = not (m["eats"] as Array) \
                                        .is_empty()
                        var mc: Color = danger if eats else aim
                        fx_l.draw_circle(dest, cell * 0.44,
                                        Color(mc, 0.32 + 0.12 * pulse))
                        fx_l.draw_circle(dest, cell * 0.44,
                                        Color(mc, 0.98), false, 4.5)
                        fx_l.draw_circle(dest, cell * 0.27,
                                        Color(1, 1, 1, 0.85), false, 2.0)
                        fx_l.draw_circle(dest, cell * 0.10,
                                        Color(mc, 0.98))
                        _draw_arrow(dest + Vector2(0,
                                        -cell * 0.66 - pulse * 4.0),
                                        PI * 0.5, mc, style, 1.15)

func _draw_arrow(at: Vector2, dir: float, ink: Color, style: String,
                scale := 1.0) -> void:
        ## a small chevron arrow pointing along `dir` (down by default);
        ## the theme's hand shows in its body
        var s := cell * 0.20 * scale
        var pts := PackedVector2Array()
        var back := dir + PI
        var wing := 0.62
        pts.append(at + Vector2(cos(back + wing), sin(back + wing)) * s)
        pts.append(at + Vector2(cos(dir), sin(dir)) * s * 0.15)
        pts.append(at + Vector2(cos(back - wing), sin(back - wing)) * s)
        if style == "pixel":
                # the blocky chevron (three hard steps)
                var w := s * 0.4
                var pp := PackedVector2Array([
                        at + Vector2(-w, -s * 0.6), at + Vector2(0, 0),
                        at + Vector2(w, -s * 0.6), at + Vector2(w, -s * 0.2),
                        at + Vector2(0, s * 0.4), at + Vector2(-w, -s * 0.2),
                ])
                fx_l.draw_colored_polygon(pp, ink)
                return
        if style == "neon":
                fx_l.draw_colored_polygon(pts, Color(ink, 0.9))
                fx_l.draw_colored_polygon(pts, Color(1, 1, 1, 0.25))
                return
        if style == "mono":
                fx_l.draw_colored_polygon(pts, Color(0.08, 0.08, 0.08))
                return
        var soft := ink
        soft.a = 0.85
        fx_l.draw_colored_polygon(pts, soft)

func _draw_fx() -> void:
        _draw_trays()
        _draw_arrows()
        # the coin (the xo coin law, seated ON its ring cell)
        if coin_ring >= 0:
                var tex: Texture2D = load("res://assets/ui/coin.png")
                if tex != null:
                        var pos := _cell_point(_track[coin_ring])
                        pos.y += sin(coin_t * 3.2) * cell * 0.07
                        var fade: float = clampf(coin_t / 0.4, 0.0, 1.0)
                        var s: float = cell * 0.62 / float(tex.get_width())
                        var pop: float = 1.0 + 0.07 * sin(coin_t * 4.4)
                        fx_l.draw_set_transform(pos, 0.0,
                                        Vector2(s * pop * fade,
                                        s / maxf(0.05, pop) * fade))
                        fx_l.draw_texture(tex,
                                        -Vector2(tex.get_width(),
                                        tex.get_height()) / 2.0,
                                        Color(1, 1, 1, fade))
                        fx_l.draw_set_transform(Vector2.ZERO, 0.0,
                                        Vector2.ONE)
                        var ga: float = coin_t * 2.6
                        fx_l.draw_arc(pos, cell * 0.46, ga, ga + 1.1, 30,
                                        Color(1, 1, 1, 0.5 * fade), 2.2)
        # the dust (the squares law)
        for p in _dust:
                var a: float = clampf(float(p["life"]) / float(p["max"]),
                                0.0, 1.0)
                var c: Color = p["col"]
                c.a = a * 0.85
                fx_l.draw_rect(Rect2(float(p["x"]) - float(p["s"]) * 0.5,
                                float(p["y"]) - float(p["s"]) * 0.5,
                                float(p["s"]), float(p["s"])), c)

func _dust_burst(at: Vector2, col: Color, cnt := 6) -> void:
        for i in cnt:
                _dust.append({
                        "x": at.x + _rng.randf_range(-cell * 0.2,
                                        cell * 0.2),
                        "y": at.y + _rng.randf_range(-cell * 0.1,
                                        cell * 0.12),
                        "vx": _rng.randf_range(-90.0, 90.0),
                        "vy": _rng.randf_range(-140.0, -30.0),
                        "life": _rng.randf_range(0.3, 0.6),
                        "max": 0.6,
                        "s": _rng.randf_range(2.0, 4.5),
                        "col": col,
                })
        if _dust.size() > 120:
                _dust = _dust.slice(_dust.size() - 120)

# ============================================================ the input

# the double-delivery shield (see _goga_input)
var _tap_msec := -100000
var _tap_at := Vector2(-9999, -9999)

func _goga_input(event: InputEvent) -> void:
        if sheet_open_count() > 0:
                return
        var at := Vector2.ZERO
        var pressed := false
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                at = t.position
                pressed = t.pressed
        elif event is InputEventMouseButton:
                var mb := event as InputEventMouseButton
                at = mb.position
                pressed = mb.pressed
        else:
                return
        if not pressed:
                return
        ## THE DOUBLE-DELIVERY SHIELD (the owner's critical report,
        ## reproduced on the rig): the engine walks ONE physical tap as
        ## a synthesized touch AND the original mouse (the reverse on
        ## Android) - the same tap arrived twice, and a toggle law
        ## selected-then-deselected with nothing but the sfx left ("it
        ## makes an SFX but there is nothing happens"). One tap per
        ## spot per heartbeat wins.
        var now := Time.get_ticks_msec()
        if now - _tap_msec < 80 and _tap_at.distance_to(at) < 14.0:
                return
        _tap_msec = now
        _tap_at = at
        ## THE FLOW LAW (the owner's v0.3.9-13 round on the snakes board:
        ## "you showed first the 'tap anywhere' then showed the
        ## optionals, it should be the opposite") - the ask opens the
        ## game, the pick seats the TAP ANYWHERE gate, the gate's tap
        ## opens the round
        if state == "ready":
                _gate_down()
                _mode_sheet()
                return
        if state == "gate":
                _gate_down()
                _new_round()
                return
        _tap(at)

## THE TAP: the waiting die, the pawns, the landings - each its own seat.
## THE SELECTION LAWS (the owner's critical round: "tapping a chess-like
## make it chosen and tapping out of board deselect it so user can tap
## another chess-like"):
##   1. a landing of the chosen pawn walks it (a fat finger seat)
##   2. a movable pawn tap MAKES IT CHOSEN - it lifts, the landings light;
##      tapping the chosen pawn again rests it
##   3. anywhere else - off the board included - deselects, so another
##      pawn can be tapped right away
func _tap(at: Vector2) -> void:
        if state == "roll_wait" and _is_user_army(turn_army) \
                        and not die_alive:
                if _die_rect(turn_army).grow(14.0).has_point(at):
                        _do_roll()
                        return
        if state != "picking":
                return
        if not _is_user_army(turn_army):
                return          # the CPU's picking is its own business
        # 1. a landing of the selected pawn?
        if sel_piece >= 0:
                for m in sel_moves:
                        var dest := pos_point(turn_army, int(m["np"]),
                                        int(m["piece"]))
                        if at.distance_to(dest) <= cell * 0.95:
                                _start_move(int(m["piece"]), int(m["np"]))
                                return
        # 2. a movable pawn of the turn army (armies of the user's team
        # both answer - the ally law: one hand fields them all)
        var movable := {}
        for m in legal:
                movable[int(m["piece"])] = true
        for p in 4:
                if not movable.has(p):
                        continue
                var pp := _pawn_point(turn_army, p)
                if at.distance_to(pp) <= cell * 0.8:
                        if sel_piece == p:
                                sel_piece = -1
                                sel_moves = []     # the chosen one rests
                                return
                        sel_piece = p
                        sel_moves = []
                        for m in legal:
                                if int(m["piece"]) == p:
                                        sel_moves.append(m)
                        Jukebox.sfx("ld_select", -6.0)
                        return
        # 3. anywhere else: the selection rests (the deselect law)
        sel_piece = -1
        sel_moves = []

# ------------------------------------------------------- the mode sheet

func _mode_sheet() -> void:
        ## THE HOUSE OPTIONALS LAW (law 28, the v0.3.9-13 correction:
        ## the ask wears ONE short title - the snake sheet's own
        ## "CHOOSE MODE" words) - three equal cards, ONE color, one tap
        ## seats the gate
        var sheet := sheet_push(0.0, "mode")
        var t := Arc.label("CHOOSE MODE", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 14)
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        sheet.add_child(row)
        for m in [[1, "X1"], [2, "X2"], [4, "X4"]]:
                var mode_v: int = m[0]
                row.add_child(Arc.button(String(m[1]), Vector2(164, 92),
                                30, Arc.ACCENT, func(): _pick_mode(mode_v)))
        # THE CONFIRM-SHEET LAW (the 2048 law): plain sheet buttons keep
        # their default mouse filter - no BoxScroll router lives here, and
        # an IGNORE filter makes the cards DEAD to taps (the film rig
        # caught the silent sheet: every tap landed on the dim below)

# ================================================== THE LAN SEAT (v042-1)
## BOARD LUDO WEARS LAN (the queued shred, the owner's order: "do it as
## part of this patch too"): 2-4 armies, ONE army per seat, TURN_RELAY
## (the snl pattern - the roll and the move are the two relayed acts).
## THE SEAT PERSPECTIVE LAW: the local player's army wears seat 1 on every
## device; the CPU never wakes in a LAN match; the shared seed shuffles
## nothing (the board is fixed) but seats the die's RNG for the coin law.

func lan_match_start(seed_v: int, m_seats: Array) -> void:
        lan_active = true
        lan_seats = m_seats
        _rng.seed = seed_v
        mode = 1 if m_seats.size() <= 2 else 4
        teams = teams_of(mode)
        playing = []
        for i in m_seats.size():
                playing.append(i + 1)     # the ABSOLUTE room seats
        opener = 1
        rounds = 0
        sheet_pop()
        _new_round()

func lan_solo() -> void:
        lan_active = false
        _mode_sheet()

## The army's display name (its room seat's human).
func _lan_name_of_army(a: int) -> String:
        var s := _lan_seat_of_army(a)
        return String(s.get("name", "RIVAL")).to_upper()

func lan_act(who: int, a: Dictionary) -> void:
        # THE WHO GATE: the act lands only when its sender IS the turn's
        # absolute seat (army numbers ARE room seats now).
        if who != turn_army:
                return
        match String(a.get("k", "")):
                "roll":
                        if state == "roll_wait":
                                _apply_roll(int(a.get("r", 1)))
                "move":
                        if state == "picking":
                                _start_move(int(a.get("piece", 0)),
                                                int(a.get("np", 0)), true)

func lan_end(results: Array) -> void:
        # THE DISCONNECT LAW: the room folded under us - the honest verdict
        # (the base already toasted the why).
        var dq := ""
        for r in results:
                if typeof(r) == TYPE_DICTIONARY and bool(r.get("dq", false)):
                        dq = String(r.get("name", "A PLAYER"))
                        break
        if dq != "" and not over:
                game_toast("%s LEFT - THE MATCH IS OVER" % dq.to_upper())
                finish_run(score, run_coins)

func _pick_mode(m: int) -> void:
        mode = m
        teams = teams_of(m)
        playing = [1, 2] if m == 1 else [1, 2, 3, 4]
        # the pick seats the TAP ANYWHERE gate (the flow law) - the
        # round opens on the gate's tap, not on the pick
        state = "gate"
        clock = -1.0
        sheet_pop()
        _build_ready()

func _goga_sheet_popped(id: String) -> void:
        if id == "shop":
                shop_id = ""
                get_tree().paused = false
                paused = false
                _repaint()
                if state in ["ready", "gate"] and ready_ui != null \
                                and is_instance_valid(ready_ui):
                        ready_ui.visible = true
        elif id == "mode" and state == "ready":
                # the back button closed the mode ask - the gate returns
                # so its tap re-opens the ask (the flow law)
                _build_ready()

func _repaint() -> void:
        bg_l.queue_redraw()
        board_l.queue_redraw()
        pawn_l.queue_redraw()
        fx_l.queue_redraw()

# ============================================================ the rounds

func _new_round() -> void:
        _fresh_poss()
        rounds += 1
        verdict_lbl.visible = false
        # THE TACTICAL CPU: every rival draws its hidden mood for the
        # round (the profiles the owner asked for - the dice game's
        # hidden-mood law, the ludo dialect)
        cpu_moods.clear()
        var mood_keys := CPU_MOODS.keys()
        for a in playing:
                if not _is_user_army(int(a)):
                        cpu_moods[int(a)] = mood_keys[_rng.randi() \
                                        % mood_keys.size()]
        # THE OPENER LAW: round 1 is the user's; after that the LOSER's
        # team opens (no draws on this board)
        turn_army = opener
        clock = 0.0
        _start_turn()
        _banner()
        _repaint()
        _refresh_widget()

## the turn opens: the ROLL pill wakes at the turn army's tray (the
## owner's theater) - or the CPU breathes and rolls by itself
func _start_turn() -> void:
        state = "roll_wait"
        roll = 0
        legal = []
        sel_piece = -1
        sel_moves = []
        die_alive = false
        die_fading = false
        die_t0 = -1.0
        clock = 0.0
        _banner()

func _banner() -> void:
        ## the active tray's status note (the tray speaks, no banner strip
        ## fights the bottom trays for space)
        if state == "round_over":
                turn_note = ""
                return
        var dots := ".".repeat(int(_time * 2.5) % 3 + 1)
        if state == "roll_wait":
                ## the waiting die speaks for itself (no TAP ROLL talk -
                ## the v0.3.9-11 tray redesign)
                turn_note = "" if _is_user_army(turn_army) \
                                else "THINKING %s" % dots
        elif state == "picking":
                turn_note = "PICK A PAWN" if _is_user_army(turn_army) \
                                else "THINKING %s" % dots
        elif state == "rolling":
                turn_note = "..."
        else:
                turn_note = ""

# ============================================================ the theater

func _do_roll() -> void:
        roll = _rng.randi_range(1, 6)
        if lan_active:
                # r3: the stamp rides automatically - my room seat IS the
                # turn's army here (the WHO GATE guarantees it)
                LAN.send_act({"k": "roll", "r": roll})
        _apply_roll(roll)

## The ONE roll body (the local roll and the relayed roll land identically).
func _apply_roll(r: int) -> void:
        roll = r
        die_face = r
        die_alive = true
        die_fading = false
        die_t0 = _time
        var dr := _die_rect(turn_army)
        die_pos = dr.get_center()
        state = "rolling"
        clock = 0.0
        Jukebox.sfx("ld_roll", -6.0)
        _banner()

## the settle: the face is the truth - legal moves wake the arrows, an
## empty set walks the turn on (the owner: "if legal, user will act, if
## not, turn is end and then opponent")
func _after_roll() -> void:
        legal = legal_moves(poss, turn_army, roll, teams)
        if legal.is_empty():
                Jukebox.sfx("ld_denied", -8.0)
                _die_fade()
                state = "handoff"    # the denied beat, then the rival
                clock = -0.45
                _banner()
                return
        state = "picking"
        clock = 0.0
        _banner()

## THE DIE FADES OUT once done, the seat empties for the next turn
## (the owner: "remove it (fade out) once done then show the roll button
## in the dice area when the turn is on you")
func _die_fade() -> void:
        if die_alive and not die_fading:
                die_fading = true
                die_t0 = _time

# ============================================================ the move

func _start_move(piece: int, np: int, relayed := false) -> void:
        if lan_active and not relayed:
                LAN.send_act({"k": "move", "piece": piece, "np": np})
        var from_pos := int(poss[(turn_army - 1) * 4 + piece])
        var pts := PackedVector2Array()
        if from_pos < 0:
                pts.append(_socket_point(turn_army, piece))
                Jukebox.sfx("ld_drop", -5.0)
        else:
                pts.append(pos_point(turn_army, from_pos, piece))
        for k in range(from_pos + 1, np + 1):
                pts.append(pos_point(turn_army, k, piece))
        # the coin's hop (pass-through collects, the owner's law)
        var coin_hop := -1
        if crosses_coin(turn_army, from_pos, np, coin_ring):
                for k in range(maxi(1, from_pos + 1), np + 1):
                        if ring_at(turn_army, k) == coin_ring:
                                coin_hop = k - from_pos
                                break
        walk = {"army": turn_army, "piece": piece, "pts": pts,
                "t0": _time, "np": np, "from": from_pos,
                "coin_hop": coin_hop, "coin_done": coin_hop < 0}
        sel_piece = -1
        sel_moves = []
        state = "walking"
        _banner()

func _finish_walk() -> void:
        var a := int(walk["army"])
        var piece := int(walk["piece"])
        var np := int(walk["np"])
        var landed_at := pos_point(a, np, piece)
        var res := apply_move(poss, a, piece, np, teams)
        # THE SLIDE OF THE EATEN (the owner: back "like it's sliding the
        # whole way till it return to it's side of the square") - the path
        # is read from the OLD board (apply_move already sent them home on
        # its copy) - and NO bonus moves, the drama is the slide
        for e in res["eaten"]:
                var ea := int(e["army"])
                var ep := int(e["piece"])
                var old := int(poss[(ea - 1) * 4 + ep])
                var pts := PackedVector2Array()
                for k in range(old, -1, -1):
                        pts.append(pos_point(ea, k, ep))
                pts.append(_socket_point(ea, ep))
                var dur := clampf(0.05 * float(pts.size()) + 0.25, 0.45,
                                1.3)
                slides.append({"army": ea, "piece": ep, "pts": pts,
                        "t0": _time, "dur": dur})
                _dust_burst(landed_at, _army_col(ea), 10)
        poss = res["poss"]
        if int(teams[a]) == int(teams[1]) and not res["eaten"].is_empty():
                achievement_count("captures", res["eaten"].size())
        # the home arrival
        if np == int(PATH_LEN):
                Jukebox.sfx("ld_home", -4.0)
                _dust_burst(landed_at, _army_col(a), 12)
                if int(teams[a]) == int(teams[1]):
                        achievement_count("homes", 1)
        # the blockade's mid-to-side slide (and back)
        _refresh_pair_offs()
        pawn_l.queue_redraw()
        walk = {}
        var mover_team := int(teams[a])
        if _team_home(mover_team):
                _resolve(mover_team)
                return
        # THE 6 LAW: "if 6, drop a chess-like and make another roll" - a
        # 6 keeps the table (no bonus for eating, none for homing); any
        # other face hands the turn to the rival
        _die_fade()
        if roll == 6:
                state = "roll_wait"      # the same army rolls again
                clock = -0.35            # the fade breathes, then the pill
        else:
                state = "handoff"        # the rival's turn
                clock = -0.35

func _refresh_pair_offs() -> void:
        ## every pawn reads its cell-mates: pairs slide mid-to-side, a
        ## freed pawn glides back to the middle (the owner's ask)
        for a in 4:
                var army := a + 1
                if not playing.has(army):
                        continue
                for p in 4:
                        var key := "%d_%d" % [army, p]
                        pair_off[key] = _pair_target(army, p)

func _team_home(t: int) -> bool:
        for a in teams:
                if int(teams[a]) != t:
                        continue
                for p in 4:
                        if int(poss[(int(a) - 1) * 4 + p]) != int(PATH_LEN):
                                return false
        return true

# ============================================================ the turns

func _next_turn() -> void:
        var order := _play_order()
        var idx := order.find(turn_army)
        turn_army = order[(idx + 1) % order.size()]
        _start_turn()

# ============================================================ the verdict

func _resolve(winner_team: int) -> void:
        state = "round_over"
        clock = 0.0
        _die_fade()
        # r3 THE ABSOLUTE VERDICT: MY team is the team of MY first army
        # (the local army is no longer army 1 - it is my room seat's army).
        var my_army := 1
        for a in playing:
                if _is_user_army(int(a)):
                        my_army = int(a)
                        break
        var user_team := int(teams.get(my_army, 1))
        var w := 1 if winner_team == user_team else 2
        if w == 1:
                wins += 1
                streak += 1
                add_score(1)                     # THE OWNER'S LAW: win = +1
                verdict_lbl.text = "YOU BRING THEM ALL HOME  +1"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("7ee2a0"))
                Jukebox.sfx("ld_win", -3.0)
                achievement_count("wins", 1)
                achievement_max("streak", streak)
                var mid := board_origin + Vector2(board_side * 0.5,
                                board_side * 0.5)
                Arc.confetti(_overlay_root_ref(), mid, 34)
        else:
                losses += 1
                streak = 0
                if score > 0:
                        add_score(-1)            # never under zero
                verdict_lbl.text = "THE RIVAL TAKES THE ROUND  -1"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("f2a09a"))
                Jukebox.sfx("ld_lose", -3.0)
        # THE OPENER LAW: the loser's team opens the next round
        var loser_team := user_team if w == 2 else \
                        _other_team(winner_team)
        opener = _team_first_army(loser_team)
        achievement_max("max_score", score)
        _refresh_widget()
        verdict_lbl.visible = true
        ## THE SMOOTH VERDICT: the line rises in instead of snapping
        verdict_lbl.modulate.a = 0.0
        var tw := verdict_lbl.create_tween().set_parallel(true)
        tw.tween_property(verdict_lbl, "modulate:a", 1.0, 0.38) \
                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        turn_note = ""       # the tray goes quiet (the verdict speaks)
        check_achievements()

func _other_team(t: int) -> int:
        for a in teams:
                if int(teams[a]) != int(t):
                        return int(teams[a])
        return 1

func _team_first_army(t: int) -> int:
        var order := _play_order()
        for a in order:
                if int(teams[a]) == int(t):
                        return a
        return 1

# ============================================================ the coin

func _coin_maybe_spawn() -> void:
        if coin_ring >= 0 or play_clock < COIN_EVERY:
                return
        var user_armies := []
        for a in playing:
                if _is_user_army(a):
                        user_armies.append(a)
        if user_armies.is_empty():
                return
        var spots := coin_spots(poss, user_armies, teams)
        if spots.is_empty():
                play_clock = COIN_EVERY   # try again next tick
                return
        coin_ring = spots[_rng.randi() % spots.size()]
        coin_t = 0.0
        game_toast("A GOGACOIN SHINES ON THE BOARD")

func _coin_taken(who_army: int) -> void:
        coin_ring = -1
        play_clock = 0.0
        var at := _cell_point(Vector2i(7, 7))
        if _is_user_army(who_army):
                add_run_coins(1)
                achievement_count("coins", 1)
                Jukebox.sfx("ld_coin", -3.0)
                game_toast("YOU TOOK THE GOGACOIN  +1")
                _dust_burst(at, Color("ffd24a"), 12)
        else:
                Jukebox.sfx("ld_coin", -6.0, 0.8)
                game_toast("%s GRABBED THE COIN" % (_lan_name_of_army(who_army) if lan_active else "THE CPU"))

# ============================================================ the tick

func _goga_tick(delta: float) -> void:
        _time += delta
        coin_t += delta
        clock += delta
        _banner()            # the tray note breathes (the thinking dots)
        # THE COIN CLOCK: live play only, one coin every 6 in-game minutes
        if state in ["roll_wait", "rolling", "picking", "walking"]:
                play_clock += delta
        _coin_maybe_spawn()
        # the die's fade-out lives ABOVE the states - it dies wherever it
        # is, and the seat empties for whoever's turn comes next
        if die_fading and _time - die_t0 >= FADE_T:
                die_alive = false
                die_fading = false
        match state:
                "rolling":
                        var total := FADE_T + SHUF_T
                        if clock >= total and not die_fading:
                                _after_roll()
                "roll_wait":
                        if clock >= 0.0:
                                if not lan_active \
                                                and not _is_user_army(turn_army) \
                                                and not die_alive \
                                                and clock >= CPU_THINK:
                                        _do_roll()
                "handoff":
                        if clock >= 0.0 and not die_alive:
                                _next_turn()
                "picking":
                        if not lan_active \
                                        and not _is_user_army(turn_army) \
                                        and clock >= CPU_PICK:
                                # THE TACTICAL PICK (the owner's upgrade:
                                # "logic that needs profiles and accurate
                                # working on it") - the mood scores every
                                # legal move on the post-move board; the
                                # jitter keeps it a creature, not a solver
                                var m: Dictionary = cpu_pick(poss,
                                                turn_army, roll, teams,
                                                String(cpu_moods.get(
                                                turn_army, "chaos")), _rng)
                                if not m.is_empty():
                                        _start_move(int(m["piece"]),
                                                        int(m["np"]))
                "walking":
                        if not walk.is_empty():
                                var pts_n: int = (walk["pts"] as \
                                                PackedVector2Array).size()
                                var walked := (_time - float(walk["t0"])) \
                                                / HOP_T
                                var hop := int(walked)
                                # the coin's hop: passing collects
                                if not bool(walk["coin_done"]) \
                                                and hop >= int(walk["coin_hop"]):
                                        walk["coin_done"] = true
                                        _coin_taken(int(walk["army"]))
                                if walked >= float(pts_n - 1):
                                        _finish_walk()
                "round_over":
                        if clock >= 2.6:
                                _new_round()
        # the slides live their own life
        if not slides.is_empty():
                var alive := []
                for s in slides:
                        if _time - float(s["t0"]) < float(s["dur"]) + 0.05:
                                alive.append(s)
                slides = alive
        # the pair slide's glide (the mid-to-side law, animated)
        if not pair_off.is_empty():
                var keys := pair_off.keys()
                for key in keys:
                        var parts := String(key).split("_")
                        var army := int(parts[0])
                        var piece := int(parts[1])
                        if not playing.has(army):
                                continue
                        var target := _pair_target(army, piece)
                        pair_off[key] = (pair_off[key] as Vector2) \
                                        .lerp(target, minf(1.0, delta * 9.0))
        # the dust's life
        if not _dust.is_empty():
                var alive2 := []
                for p in _dust:
                        p["life"] = float(p["life"]) - delta
                        if float(p["life"]) <= 0.0:
                                continue
                        p["x"] = float(p["x"]) + float(p["vx"]) * delta
                        p["y"] = float(p["y"]) + float(p["vy"]) * delta
                        p["vy"] = float(p["vy"]) + 420.0 * delta
                        alive2.append(p)
                _dust = alive2
        # THE LIVING LAYER LAW: the animated layers repaint on the tick
        pawn_l.queue_redraw()
        fx_l.queue_redraw()

# ============================================================ the shop
## PIECE SKINS + THEMES (the shelf order law: "skins at the top and
## themes under them in all other games" - the owner caught the dice
## game swapping them, this one wears the right order from birth)

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
        var t := Arc.label("BOARD LUDO SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 300.0,
                        640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        # THE SHELF ORDER LAW: the skins seat first, the themes under.
        # THE SHELF TRUTH LAWS (v0.3.9-11): short section names, no dash
        # talk; the equipped row keeps its seat and says ON.
        box.add_child(_shop_label("PAWN SKINS"))
        for id in SKINS:
                box.add_child(_skin_row(id))
        box.add_child(_shop_label("THEMES"))
        for id in THEMES:
                box.add_child(_theme_row(id))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): sheet_pop()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _shop_label(txt: String) -> Label:
        return Arc.fit_label(txt, 24, Arc.HOT, 560)

func _price_btn(txt: String, price: int, col: Color, cb: Callable) \
                -> Button:
        var b := Arc.coin_button("%s  %d" % [txt, price], Vector2(560, 64),
                22, col, cb)
        if Box.coins() < price:
                b.disabled = true
        return b

func _theme_row(id: String) -> Control:
        var c: Dictionary = THEMES[id]
        var owned := Box.item_owned(game_id, "theme", id) \
                        or int(c["price"]) == 0
        var on: bool = Box.item_on(game_id, "theme") == id \
                        or (int(c["price"]) == 0
                        and Box.item_on(game_id, "theme") == "")
        if on:
                ## THE ON ROW LAW: the equipped row keeps its full seat and
                ## plainly says ON - never a small green description label
                return Arc.on_row("%s  (ON)" % c["name"])
        if owned:
                return Arc.button(c["name"], Vector2(560, 64), 22,
                        Arc.ACCENT, func():
                                Box.equip_item(game_id, "theme", id)
                                Jukebox.sfx("confirm", -4.0)
                                _shop_reopen())
        return _price_btn(c["name"], int(c["price"]), Arc.ACCENT,
                        func():
                                if Box.buy_item(game_id, "theme", id,
                                                int(c["price"])):
                                        Jukebox.sfx("buy")
                                        Box.equip_item(game_id, "theme", id)
                                _shop_reopen())

func _skin_row(id: String) -> Control:
        var s: Dictionary = SKINS[id]
        var owned := Box.item_owned(game_id, "skin", id) \
                        or int(s["price"]) == 0
        var on: bool = _skin_id() == id
        if on:
                return Arc.on_row("%s  (ON)" % s["name"])
        if owned:
                return Arc.button(s["name"], Vector2(560, 64), 22,
                        Arc.ACCENT, func():
                                Box.equip_item(game_id, "skin", id)
                                Jukebox.sfx("confirm", -4.0)
                                _shop_reopen())
        return _price_btn(s["name"], int(s["price"]), Arc.ACCENT,
                        func():
                                if Box.buy_item(game_id, "skin", id,
                                                int(s["price"])):
                                        Jukebox.sfx("buy")
                                        Box.equip_item(game_id, "skin", id)
                                _shop_reopen())

func _shop_reopen() -> void:
        if shop_id != "":
                sheet_pop()
                _shop_open.call_deferred()

# ============================================================ the probe
## The headless contract: a fresh deterministic round any probe drives.

func probe_reset(mode_v: int, seed_v: int) -> void:
        _rng.seed = seed_v
        _gate_down()
        mode = mode_v
        teams = teams_of(mode_v)
        playing = [1, 2] if mode_v == 1 else [1, 2, 3, 4]
        opener = 1
        rounds = 0
        wins = 0
        losses = 0
        streak = 0
        _fresh_poss()
        paused = true
        _layout(get_viewport_rect().size)
        _new_round()

func probe_step(dt: float) -> void:
        _goga_tick(dt)

## THE DRAIN: run the machine until the player may act or the round ends
func probe_drain(max_ticks := 600) -> void:
        var k := 0
        while (state == "rolling" or state == "handoff"
                or state == "walking"
                or (state == "roll_wait" and not _is_user_army(turn_army))
                or (state == "picking" and not _is_user_army(turn_army))) \
                and k < max_ticks:
                _goga_tick(0.05)
                k += 1

## a probe rolls for the user army (the ROLL pill's stand-in) - it waits
## out the fade like a human waiting for the pill to come back
func probe_roll() -> void:
        if state == "roll_wait" and _is_user_army(turn_army):
                var k := 0
                while die_alive and k < 40:
                        _goga_tick(0.05)
                        k += 1
                if not die_alive:
                        _do_roll()

## a probe plays the first legal move for the user army
func probe_play_first() -> void:
        if state == "picking" and _is_user_army(turn_army) \
                        and not legal.is_empty():
                var m: Dictionary = legal[0]
                _start_move(int(m["piece"]), int(m["np"]))
