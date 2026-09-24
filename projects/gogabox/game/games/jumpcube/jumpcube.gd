extends GogaGame
## CONQUER DICE - v0.3.9-9, the jumping-cube territory game (graduated
## v0.3.9-9; the teaser CUBE OVERFLOW was renamed CONQUER DICE by the
## owner's order; the brain's honest ancestor is KDE's KJumpingCube -
## cloned, read and studied: the cascade law, the cap law and the
## total-conquest verdict are the ORIGINAL's, word for word).
##
## Owner contract (v0.3.9-9, verbatim intent):
##   - VERTICAL ONLY for now ("we may do the horizontal one but later")
##   - 3 sizes: "medium and big and too big, maybe 4x4/6x6/8x8" - bought
##     in the shop, applied from the OPTIONS (the 2048/squares mechanic)
##   - "user should be red and enemy should be blue as always" - the
##     DEFAULT; but "there is no hard rule that tell us to make always
##     the user red/blue or something like that, sooo....yeah, ART!":
##     5 THEMES own the room, the board wall, the neutral dice, the
##     enemy dice AND each theme's own SFX voice; the DICE SKINS are the
##     one thing a theme never owns - "theme is everything except
##     user-owned dices" (the B&W theme makes you WHITE, the enemy BLACK)
##   - the KJC law: tap a NEUTRAL or YOUR OWN die, it grows one dot; a
##     die holds as many dots as it has neighbors (corner 2, edge 3,
##     middle 4); one dot TOO MANY and it spills - a dot flies into
##     every neighbor, flipping them all to you, chains spread
##   - the verdict is TOTAL CONQUEST (the original's own law): own every
##     die on the board and the round is yours - no draws can exist
##   - the economy: "1 score point per win and each lose takes one and
##     score bonus will be /2" (registry coin_div 2)
##   - "gogacoin will appear after each 3 levels in a place of a dice
##     that is still not conquered yet and whoever reaches it take the
##     coin" - the coin rests ON a neutral die; whoever conquers that
##     die takes it (the CPU races you)
##   - who opens: "for now who plays first is the user then the loser
##     plays first for other rounds!"
##   - THE HOLD LAW (the squares/fourline hand, dice dialect): "holding
##     on a dice should make it give the pressing effect which is
##     highlighted in gray-out and when user release the finger, that
##     dice will get the action, if finger released out of board,
##     nothing will happen"
##   - THE IN AND THE OUT (the owner's critical animation ask): "the
##     transition animation should make the in and the out, where the
##     dice gets the dots or gives them" - a spill's dots FLY out of the
##     popping die into its neighbors, each landing pip pops in, an
##     ownership change crossfades the color, and the cascade's sounds
##     rise in pitch as the chain grows ("out will usually make from 2
##     to 4 ins so...it has to feel satisfying in a cool way")
##   - ONE opponent, FOUR moods (the xo rotation, one name "CPU"), every
##     mood HARD or VERY HARD (the owner v0.3.9-10: "all profiles are
##     made as hard/very hard but not impossible and also not just
##     medium/easy") with programmed failures everywhere. THE RESULT LAW:
##     "each profile changes based on how the user responded to each one
##     whether won or lost" - the user's wins tighten the hand, the
##     user's losses ease it, a mood the user solved twice is benched.
##     THE COUNTER-ATTACK (the squares law, the dice dialect): "as in
##     squares it takes opportunities to take a square then make another
##     move" - the moods that carry the eye HUNT the biggest flip when a
##     spill is on the table (not always - in the profiles).
##     THE SPILL-SCAR MEMORY (the 2-round window): lose a round where the
##     player swallowed a chain of 6+ dice in one breath and the CPU
##     plays feed-aware for the window - it learns the way it lost
##     (v0.3.9-10 also fixed the ply eye's SIGN: the old eye ADDED the
##     foe's best reply to a lowest-wins score, so the smart moods were
##     actively hunting the moves that gift the foe the strongest answer
##     - the honest root of the "semi-random" feel)
##   - TAP ANYWHERE TO START (the gate, HUD index 0), pause_end_run (the
##     pong END bank)
##
## Probe contract: the whole CPU core is STATIC - max_of / neighbors_of
## / legal_at / do_move / count_owned / score_cube / best_reply /
## cpu_pick / remember / adapt / profile_next drive headless laws
## without the scene (the bovo contract). The scene rides
## probe_reset(seed, side) + probe_step(dt) + probe_drain().

const COIN_EVERY := 3      # owner: one GOGACoin after each 3 rounds
const MEM_ROUNDS := 2      # the xo memory law (the spill-scar window)

# ----------------------------------------------------- the animation law
## THE IN AND THE OUT: FLY_T carries one dot from a popping die to its
## neighbor; MORPH_A crossfades an ownership change; PIP_A pops the
## landing pip in. The cascade's step rhythm is FLY_T - one hop per
## breath, the sounds rise as the chain grows.
const FLY_T := 0.15
const MORPH_A := 0.26
const PIP_A := 0.15
const REPLY_W := 0.85      # how hard the ply moods weigh the foe's answer

# ------------------------------------------------- the default pens
## THE OWNER'S DEFAULT DICE: red is the user's, blue is the enemy's -
## the WOOD theme carries them; the other themes re-ink the whole board
## and the SKINS re-ink the user's dice only (the theme-ownership law).
const RED_P := Color("e0533f")
const BLUE_P := Color("4179df")

# ------------------------------------------------------------- the sizes
## THE OWNER'S LADDER: "medium and big and too big, maybe 4x4/6x6/8x8 -
## see the best scale for it". 4x4 is the free normal game; 6x6 and 8x8
## are SHOP items bought first (the 2048 mechanic, the squares ladder).
const SIZES := {
        "4": {"name": "4 x 4 MEDIUM", "price": 0,
                "desc": "16 dice - the tight tactical board"},
        "6": {"name": "6 x 6 BIG", "price": 1800,
                "desc": "36 dice - the wide war"},
        "8": {"name": "8 x 8 TOO BIG", "price": 3600,
                "desc": "64 dice - the avalanche board"},
}

# ------------------------------------------------------------- the themes
## 5 themes, the first is the default (the owner's law). A theme owns
## EVERYTHING except the user's dice: the room, the board wall, the
## neutral dice, the enemy's color, the pip inks, the style and the
## SFX voice ("SFXs should differ from theme to another"). The B&W
## theme is the owner's own ask: "me as white and enemy as black".
const THEMES := {
        "wood": {"name": "WOOD", "price": 0, "style": "round",
                "sfx": "wood",
                "room": Color("2a2114"), "floor": Color("1f1808"),
                "wall": Color("8a5a2e"), "wall_dark": Color("6e4522"),
                "die": Color("f3e2c0"), "die_dark": Color("dcc79c"),
                "ink": Color("3a2a14"),
                "foe": Color("4179df"), "foe_ink": Color("f2f6ff"),
                "user": Color("e0533f"), "user_ink": Color("3a1208"),
                "desc": "the warm wooden table - red vs blue, the classic"},
        "mono": {"name": "BLACK & WHITE", "price": 240, "style": "mono",
                "sfx": "mono",
                "room": Color("101010"), "floor": Color("050505"),
                "wall": Color("e8e8e8"), "wall_dark": Color("c4c4c4"),
                "die": Color("b9b9b9"), "die_dark": Color("9c9c9c"),
                "ink": Color("1c1c1c"),
                "foe": Color("1a1a1a"), "foe_ink": Color("f2f2f2"),
                "user": Color("f7f7f7"), "user_ink": Color("161616"),
                "desc": "you are WHITE, the enemy is BLACK, the rest is gray"},
        "pixel": {"name": "PIXEL", "price": 300, "style": "pixel",
                "sfx": "chip",
                "room": Color("1a1c2c"), "floor": Color("10121e"),
                "wall": Color("29366f"), "wall_dark": Color("1d2752"),
                "die": Color("c4b287"), "die_dark": Color("9e8f66"),
                "ink": Color("29366f"),
                "foe": Color("3b9dd6"), "foe_ink": Color("0c2233"),
                "user": Color("e64539"), "user_ink": Color("38100c"),
                "desc": "the 8-bit table - hard edges, hard times"},
        "neon": {"name": "NEON", "price": 380, "style": "neon",
                "sfx": "neon",
                "room": Color("060913"), "floor": Color("03050c"),
                "wall": Color("0e1430"), "wall_dark": Color("090d20"),
                "die": Color("16203f"), "die_dark": Color("10182f"),
                "ink": Color("7ee8ff"),
                "foe": Color("37c8ff"), "foe_ink": Color("03121c"),
                "user": Color("ff3860"), "user_ink": Color("2b0311"),
                "desc": "the digital night - glow dice on a dark grid"},
        "candy": {"name": "CANDY", "price": 440, "style": "round",
                "sfx": "pop",
                "room": Color("f6d7e0"), "floor": Color("eebfcf"),
                "wall": Color("fff4f7"), "wall_dark": Color("f3dce6"),
                "die": Color("ffffff"), "die_dark": Color("ecd8e2"),
                "ink": Color("8a4a63"),
                "foe": Color("7b5bd6"), "foe_ink": Color("ffffff"),
                "user": Color("ff6fa5"), "user_ink": Color("6e1236"),
                "desc": "the sugar board - soft dice, sweet spills"},
}

# --------------------------------------------------------- the dice skins
## THE THEME-OWNERSHIP LAW (the owner): "skins should be related to each
## theme while giving the user the ability to change their dice without
## matching the theme, so theme is everything except user-owned dices".
## The default skin wears the theme's own color; every bought skin
## re-inks ONLY the user's dice, on every theme.
const SKINS := {
        "theme": {"name": "THEME DICE", "price": 0,
                "col": Color(0, 0, 0), "ink": Color(0, 0, 0),
                "desc": "wear the theme's own color for your dice"},
        "crimson": {"name": "CRIMSON", "price": 120,
                "col": Color("e0533f"), "ink": Color("3a1208"),
                "desc": "the classic red - yours on any theme"},
        "green": {"name": "GREEN", "price": 180,
                "col": Color("58c470"), "ink": Color("0d3018"),
                "desc": "the table green"},
        "gold": {"name": "GOLD", "price": 240,
                "col": Color("ffc93c"), "ink": Color("4a3202"),
                "desc": "the winner's metal"},
        "pink": {"name": "PINK", "price": 240,
                "col": Color("f27bb2"), "ink": Color("4d0e2b"),
                "desc": "the bubblegum press"},
        "cyan": {"name": "CYAN", "price": 280,
                "col": Color("4cc9e8"), "ink": Color("08303d"),
                "desc": "the ice die"},
        "onyx": {"name": "ONYX", "price": 320,
                "col": Color("23272e"), "ink": Color("e8e8e8"),
                "desc": "the shadow die - white pips on black"},
}

# ------------------------------------------------------------- the profiles
## THE FOUR MOODS (the xo law: invisible rotation, one name), v0.3.9-10
## HARDNESS PASS (the owner: hard/very hard, never impossible, never
## easy). The KJC dialect of the programmed failures:
##   miss_take - the chance it fails to SEE an immediate spill (the
##               whole capped set goes blind for the turn)
##   err_risk  - the chance it fumbles a random legal die outright
##   w_feed    - how much it fears the ammunition it leaves the foe
##   w_spill   - how much it loves a spill NOW (and its own take)
##   ply       - the reply eye: simulates the foe's best answer (the
##               sign is HONEST since v0.3.9-10: a strong reply is feared)
##   ca        - THE COUNTER-ATTACK: when a spill is right there, the
##               chance the mood HUNTS the biggest flip instead of
##               scoring (the squares law: take, then move again)
##   noise     - the feel jitter (the same board never plays the same)
const PROFILES := {
        "wall": {"miss_take": 0.06, "err_risk": 0.05, "noise": 0.40,
                "w_feed": 1.60, "w_spill": 0.95, "ply": 1, "ca": 0.60},
        "trick": {"miss_take": 0.05, "err_risk": 0.05, "noise": 0.32,
                "w_feed": 1.15, "w_spill": 1.10, "ply": 1, "ca": 0.88},
        "rusher": {"miss_take": 0.09, "err_risk": 0.11, "noise": 0.60,
                "w_feed": 0.70, "w_spill": 1.50, "ca": 0.70},
        "sage": {"miss_take": 0.04, "err_risk": 0.03, "noise": 0.24,
                "w_feed": 1.25, "w_spill": 1.20, "ply": 1, "ca": 0.80},
}

## ================================================== THE CHARACTER
## THE DIE (v0.3.9-13): the dice get a voice - the first game where THE
## DIE speaks (the box's cast: every turn-game rolls it, but this board
## woke it). THE LORE LAW: a story at the VERY FIRST START (the
## invaders/pacman way), riding the shared box story card.
const DIE_LORE := "I am THE DIE. The chance. The roll.\n\nEvery face I own, I own honestly: one, two, three, four, five, six. I do not think - thinking would be bias, and bias is a rigged game. The box picked ME for the conquest board because a territory war needs a referee with no favorites. Six dots, zero opinions.\n\nHere you tap and the dice multiply, split, chain - conquest by arithmetic. I admit this is not my purest work; I am a prop here, a face for the dots. But the dots are MINE and they spill beautifully.\n\nI have heard the box rehearsing my other jobs. A round board where four pens wait for my six. A long one where I alone decide who climbs and who burns. Wherever there is a turn, there is a me, waiting to be rolled.\n\nRoll me when you need me. Do not shake me for luck - luck is just my face, and all my faces are already yours."

## THE TABLE'S SECRET (the owner's hidden work, v0.3.9-13): leave the
## conquest board untouched for one honest minute and the box's oldest
## rumor stands up - the neutral die is GEOQUARE, the dot on it is
## BALLDOZER, and they think nobody is reading. The lines pop after the
## other, the PDF conversation verbatim; one tap hears the next line.
const EGG_LINES := [
        ["BALLDOZER", "I'm bored here."],
        ["BALLDOZER", "Being a dot eater was more fun."],
        ["BALLDOZER", "Hello?"],
        ["GEOQUARE", "Who is that"],
        ["BALLDOZER", "The dot eater. The snow ball. The dot on top of you, Geoquare."],
        ["GEOQUARE", "Balldozer? We are both in same place at the same time!? For the first time?"],
        ["BALLDOZER", "Thank god the user can not hear what we say."],
        ["GEOQUARE", "But what if it can read our minds."],
        ["BALLDOZER", "It is likely do since it can control both of us simultaneously at the same time."],
]
const EGG_TINTS := {"BALLDOZER": Color(1.0, 0.82, 0.30),
                "GEOQUARE": Color(0.38, 0.89, 1.0)}
const EGG_IDLE := 60.0            # the owner: EXACTLY sixty seconds

# ============================================================ THE CPU CORE
## Static so tests (flow_test + the probes) drive the brain without the
## scene - the bovo contract. The board is flat arrays: owners[i] is
## 0 (neutral) / 1 (red, the user) / 2 (blue, the CPU); values[i] the
## pip count (starts at 1, the original's own law). size = dice per side.

## the cap law: a die holds as many dots as it has orthogonal neighbors
static func max_of(i: int, size: int) -> int:
        var x := i % size
        var y := i / size
        var m := 2
        if x > 0 and x < size - 1:
                m += 1
        if y > 0 and y < size - 1:
                m += 1
        return m

static func neighbors_of(i: int, size: int) -> Array:
        var x := i % size
        var y := i / size
        var out := []
        if x > 0:
                out.append(i - 1)
        if x < size - 1:
                out.append(i + 1)
        if y > 0:
                out.append(i - size)
        if y < size - 1:
                out.append(i + size)
        return out

static func legal_at(owners: Array, i: int, player: int) -> bool:
        var o := int(owners[i])
        return o == 0 or o == player

static func count_owned(owners: Array, player: int) -> int:
        var n := 0
        for o in owners:
                if int(o) == player:
                        n += 1
        return n

## THE PURE MOVE (the original's doMove, ported word for word): take
## ownership, +1 dot, and while a die wears MORE dots than its cap it
## pops - the cap leaves it, one dot flies into EVERY neighbor and they
## all turn the mover's color; a neighbor over its cap joins the stack;
## a still-overloaded pop re-queues itself (the re-push law); and THE
## MOMENT every die is the mover's the cascade is ABANDONED (the
## original returns true mid-cascade - the board is decided). Returns
## {} for an illegal move. `steps` is the animation plan: one entry per
## pop, in order.
static func do_move(owners_in: Array, values_in: Array, size: int,
        player: int, i: int) -> Dictionary:
        if i < 0 or i >= owners_in.size():
                return {}
        if not legal_at(owners_in, i, player):
                return {}
        var owners := owners_in.duplicate()
        var values := values_in.duplicate()
        var old_owner := int(owners[i])
        owners[i] = player
        values[i] = int(values_in[i]) + 1
        var total := size * size
        # the click-path win: the tap itself took the last foreign die
        var won := old_owner != player \
                        and count_owned(owners, player) == total
        var stack := []
        if int(values[i]) > max_of(i, size):
                stack.append(i)
        var steps := []
        while not stack.is_empty() and not won:
                var c: int = stack.pop_back()
                var m := max_of(c, size)
                values[c] = int(values[c]) - m
                var gains := []
                for nb in neighbors_of(c, size):
                        owners[nb] = player
                        values[nb] = int(values[nb]) + 1
                        gains.append(nb)
                        if int(values[nb]) > max_of(nb, size):
                                stack.append(nb)
                if int(values[c]) > m:
                        stack.append(c)      # the re-push law
                steps.append({"pop": c, "gains": gains})
                if count_owned(owners, player) == total:
                        won = true   # the original's early exit
        return {"owners": owners, "values": values, "steps": steps,
                "won": won}

## the flat eval of one die for `me` - LOWER is the better pick (the
## Kepler feel): love a spill that flips non-mine dice, fear feeding a
## loaded foe die, mild center/cap pulls for the feel.
static func score_cube(owners: Array, values: Array, size: int,
        me: int, i: int, w_feed: float, w_spill: float) -> float:
        var m := max_of(i, size)
        var room := m - int(values[i])
        var foe_load := 0.0
        var feed := 0.0
        var neutral := 0
        var mine_n := 0
        var spill := 0.0
        for nb in neighbors_of(i, size):
                var o := int(owners[nb])
                if o == 0:
                        neutral += 1
                elif o == me:
                        mine_n += 1
                else:
                        foe_load += float(int(values[nb])) \
                                        / float(max_of(nb, size))
                        if int(values[nb]) >= max_of(nb, size) - 1:
                                feed += 1.0
                if o != me and room <= 0:
                        spill += 1.0
                        if int(values[nb]) + 1 >= max_of(nb, size):
                                spill += 0.8
        var s := -1.0 * w_spill * spill + w_feed * feed + 0.9 * foe_load \
                - 0.45 * float(neutral) - 0.25 * float(mine_n) \
                + 0.75 * float(room) - 0.5 * float(4 - m)
        return s

## the foe's best answer after MY move (the ply eye's ruler): the LOWEST
## foe score over their legal set - the more negative, the stronger
## their reply. 0.0 when they have no legal die (I just won).
static func best_reply(owners: Array, values: Array, size: int,
        foe: int) -> float:
        var best := 0.0
        var first := true
        for i in owners.size():
                if not legal_at(owners, i, foe):
                        continue
                var s := score_cube(owners, values, size, foe, i, 1.0, 1.0)
                if first or s < best:
                        best = s
                        first = false
        return best

## THE APPETITE (the counter-attack's ruler, the sim eye): how many dice
## the move TAKES - the tap's own flip + the whole chain's flips. The
## flat eval cannot see a cascade; the sim can.
static func gain_of(owners: Array, values: Array, size: int,
        player: int, i: int) -> int:
        var sim := do_move(owners, values, size, player, i)
        if sim.is_empty():
                return 0
        return count_owned(sim["owners"], player) \
                        - count_owned(owners, player)

## THE AMMUNITION: how many of MY dice sit next to a FOE die at its cap -
## every one of them is a gift the foe's next spill would take (the
## squares law's shadow: never leave the triple-cross waiting)
static func exposed_of(owners: Array, values: Array, size: int,
        me: int) -> int:
        var n := 0
        for i in owners.size():
                if int(owners[i]) != me:
                        continue
                for nb in neighbors_of(i, size):
                        if int(owners[nb]) != me \
                                        and int(values[nb]) \
                                        >= max_of(nb, size):
                                n += 1
                                break
        return n

## THE MOVE PIPELINE (the xo pipeline on a dice board, v0.3.9-10):
##   1. an immediate spill is RIGHT THERE - taken unless the blind spot
##      rolls (miss_take * the result mood; the scar wakes the eye)
##   2. THE COUNTER-ATTACK: the moods that carry the eye HUNT the
##      biggest flip across the whole capped set (the squares law)
##   3. the fumble: err_risk * the result mood plays a random legal die
##   4. the scored pick: the flat feel + the SIM terms (the appetite -
##      the move's true take - and the ammunition it leaves) + the reply
##      eye (HONEST sign: a strong foe reply is FEARED, the old eye's
##      plus-sign hunted the gifting moves) ; noise jitters it
##   miss_mul / err_mul breathe with the results (the RESULT LAW: the
##   user's wins tighten, the user's losses ease)
static func cpu_pick(owners_in: Array, values_in: Array, size: int,
        player: int, profile_id: String, alert: bool,
        rng: RandomNumberGenerator, miss_mul := 1.0, err_mul := 1.0) -> int:
        var p: Dictionary = PROFILES[profile_id]
        var w_feed := float(p["w_feed"])
        var miss := float(p["miss_take"]) * maxf(0.2, miss_mul)
        var err := float(p["err_risk"]) * maxf(0.2, err_mul)
        if alert:
                w_feed = minf(2.2, w_feed * 1.5)
                miss *= 0.5
        var legal := []
        for i in owners_in.size():
                if legal_at(owners_in, i, player):
                        legal.append(i)
        if legal.is_empty():
                return -1
        # 1. the spill is RIGHT THERE - almost always taken
        var capped := []
        for i in legal:
                if int(values_in[i]) >= max_of(i, size):
                        capped.append(i)
        var blinded := {}
        if not capped.is_empty() and rng.randf() < miss:
                for i in capped:
                        blinded[i] = true      # THE BLIND SPOT: the whole
                capped = []                    # capped set stays unseen
        # 2. THE COUNTER-ATTACK (the squares law, the dice dialect): a
        # spill is on the table and the eye profiles HUNT the biggest
        # flip - "take a square, then make another move"
        if not capped.is_empty():
                var ca := float(p.get("ca", 0.0))
                if alert:
                        ca = minf(0.95, ca * 1.3)
                if ca > 0.0 and rng.randf() < ca:
                        var hunt := -1
                        var hunt_g := -1
                        for i in capped:
                                var g := gain_of(owners_in, values_in,
                                                size, player, i)
                                if g > hunt_g:
                                        hunt_g = g
                                        hunt = i
                        if hunt >= 0:
                                return hunt
        if rng.randf() < err:
                return int(legal[rng.randi() % legal.size()])
        # 4. the scored pick
        var use_ply: bool = p.has("ply")
        var w_spill := float(p["w_spill"])
        var best := INF
        var picks := []
        for i in legal:
                if blinded.has(i):
                        continue
                var s := score_cube(owners_in, values_in, size, player, i,
                                w_feed, w_spill)
                # the sim eye: the true take + the ammunition left
                var sim := do_move(owners_in, values_in, size, player, i)
                if not sim.is_empty():
                        var g := count_owned(sim["owners"], player) \
                                        - count_owned(owners_in, player)
                        s -= (0.55 + 0.5 * w_spill) * float(g)
                        s += 0.55 * float(exposed_of(sim["owners"],
                                        sim["values"], size, player))
                        if use_ply:
                                # THE HONEST REPLY EYE: a strong foe answer
                                # RAISES my score - the move is feared
                                s -= REPLY_W * float(best_reply(
                                        sim["owners"], sim["values"], size,
                                        3 - player))
                s += rng.randf() * float(p["noise"])
                if s < best - 0.0001:
                        best = s
                        picks = [i]
                elif s <= best + 0.0001:
                        picks.append(i)
        if picks.is_empty():
                # everything sat in the blind spot - the fumble law
                return int(legal[rng.randi() % legal.size()])
        return int(picks[rng.randi() % picks.size()])

## THE MEMORY LAW (the xo law, the dice dialect): the record is the
## player's biggest spill of the round + the result + THE MOOD that wore
## the round (the RESULT LAW reads it - a solved mood is benched)
static func remember(mem_in: Array, record: Dictionary) -> Array:
        var m := mem_in.duplicate()
        m.append({
                "mass": int(record.get("mass", 0)),
                "result": int(record.get("result", 0)),
                "profile": String(record.get("profile", "")),
        })
        while m.size() > MEM_ROUNDS:
                m.pop_front()
        return m

## WHAT THE MEMORY REMEMBERS - THE SPILL SCAR: a round the CPU lost
## while the player swallowed a chain of 6+ dice in one breath keeps
## the feed-eye WIDE for the whole window (it plays like it lost)
static func adapt(mem_in: Array) -> Dictionary:
        var out := {"alert": false}
        for e in mem_in:
                if int(e["result"]) == 2 and int(e["mass"]) >= 6:
                        out["alert"] = true
        return out

## THE RESULT LAW (the owner v0.3.9-10: "each profile changes based on
## how the user responded to each one whether won or lost") - the moods
## breathe with the scoreboard:
##   - the user's win TIGHTENS the next hand (the failures shrink)
##   - the user's loss EASES it (the failures widen - the chance to win
##     is the owner's own law, never an always-lose machine)
##   - a mood the user solved TWICE in a row is benched for the round
##   - never the same mood twice in a row (the rotation lives)
static func adapt_pick(mem_in: Array, rng: RandomNumberGenerator) \
                -> Dictionary:
        var miss_mul := 1.0
        var err_mul := 1.0
        var last_r := -1
        var run := 0
        if not mem_in.is_empty():
                last_r = int(mem_in[-1]["result"])
                for k in range(mem_in.size() - 1, -1, -1):
                        if int(mem_in[k]["result"]) == last_r:
                                run += 1
                        else:
                                break
        if last_r == 2 and run > 0:
                # the CPU just took it (maybe twice) - ease the hand
                miss_mul += 0.55 * mini(run, 2)
                err_mul += 0.45 * mini(run, 2)
        elif last_r == 1 and run > 0:
                # the user just took it - tighten
                miss_mul -= 0.22 * mini(run, 2)
                err_mul -= 0.18 * mini(run, 2)
        var pool := PROFILES.keys()
        var last_p := ""
        if not mem_in.is_empty():
                last_p = String(mem_in[-1].get("profile", ""))
        if last_r == 1 and last_p != "" and mem_in.size() >= 2 \
                        and int(mem_in[-2]["result"]) == 1 \
                        and String(mem_in[-2].get("profile", "")) == last_p:
                pool.erase(last_p)   # THE BENCH: the user solved this mood
        if last_p != "" and pool.size() > 1:
                pool.erase(last_p)   # the variety: never the same twice
        return {"profile": String(pool[rng.randi() % pool.size()]),
                "miss_mul": miss_mul, "err_mul": err_mul}

static func profile_next(i: int) -> Array:
        return [PROFILES.keys()[i % PROFILES.size()], i + 1]

# ============================================================ state
var owners: Array = []
var values: Array = []
var n := 4                     # THE BOARD SIZE (the equipped SIZES key)
var size_id := "4"             # the equipped size key (SIZES)
var turn := 1
var state := "ready"           # ready | play | anim | wait | round_over
var _coin_rot := 0             # v042: the LAN coin rotation (no shared RNG)
var clock := 0.0
var think_beat := 0.0
var cpu_think := false
var rounds := 0
var done_rounds := 0
var wins := 0
var losses := 0
var draws := 0                 # kept for the framework's sake - no draws
                               # can exist here (total conquest is the
                               # only verdict, the original's own law)
var streak := 0

# the spill-scar memory (the xo law)
var mem: Array = []

# the opener law (the owner: the user opens, then the loser opens)
var next_opener := 1
var last_opener := 1

# the coin race (the coin rests ON a neutral die; its conqueror takes it)
var coin_cell := -1
var coin_t := 0.0

# the round's profile (THE RESULT LAW: adapt_pick reads the memory -
# the user's wins tighten, the user's losses ease, the solved mood is
# benched; the rotation is still invisible - one name, "CPU")
var profile_order: Array = ["wall", "trick", "rusher", "sage"]
var profile_i := 0
var profile := "sage"
var miss_mul := 1.0           # the RESULT LAW's breathing failures
var err_mul := 1.0

# the move pipeline (the in and the out)
var cascade: Array = []        # the overloaded dice waiting to pop
var lands: Array = []          # the scheduled dot landings
var flies: Array = []          # the flying dots (visual)
var move_who := 0              # the player whose move is in the air
var chain_n := 0               # pops in the current move
var move_flips := 0            # dice this move flipped (the dice counter)
var player_best_chain := 0     # the round's biggest player spill (the scar)

# the hand (THE HOLD LAW): the gray-out press, action on release
var holding := false
var ghost_cell := -1
## THE GATE HUSH: the tap that closes the gate rides an EMULATED mouse
## press (Godot synthesizes mouse from touch) - without the hush that
## second press lands on the live board and the tap's own release plays
## a move under the gate tap point (the film rig caught it: every gate
## tap grew a die near the screen center). Presses are swallowed for a
## beat after the gate closes; a real tap right after plays normally.
var gate_hush := -1.0

# the color morphs + pip pops (identity-keyed: cell -> t0 / {c0, t0})
var morph := {}
var pop_t := {}

# the dust pips (the firework sprinkle, the squares law)
var _dust: Array = []

# the round-over glow sweep (the winner's dice breathe once)
var glow_t := -1.0
var _glow_owner := 0

# the board shake (the big-spill rumble)
var shake_t := -1.0
var shake_n := 0

# the table's secret (the geoquare/balldozer easter egg)
var egg_idle := 0.0              # the inactivity clock (the 60s law)
var egg_active := false
var egg_fired := false           # once per round
var egg_line := -1
var egg_t := 0.0

# the 2048 confirm law (stack-borne, the fresh-sheet rule)
var _confirm_open_id := ""

# scene
var world: Node2D
var bg_l: Node2D
var board_l: Node2D
var dice_l: Node2D
var fx_l: Node2D
var turn_lbl: Label
var verdict_lbl: Label
var tally_row: Control         # THE DICE TALLY (RED nn | BLUE nn)
var goals_row: Control
var ready_ui: Control = null
var cell := 110.0
var board_origin := Vector2.ZERO
var _time := 0.0
var _rng := RandomNumberGenerator.new()

# the pip seats (unit coords inside a die face)
const PIPS := {
        1: [[0.5, 0.5]],
        2: [[0.3, 0.3], [0.7, 0.7]],
        3: [[0.3, 0.3], [0.5, 0.5], [0.7, 0.7]],
        4: [[0.3, 0.3], [0.7, 0.3], [0.3, 0.7], [0.7, 0.7]],
        5: [[0.3, 0.3], [0.7, 0.3], [0.5, 0.5], [0.3, 0.7], [0.7, 0.7]],
        6: [[0.32, 0.28], [0.68, 0.28], [0.32, 0.5],
                [0.68, 0.5], [0.32, 0.72], [0.68, 0.72]],
}

# ============================================================ the scene

func _goga_setup() -> void:
        _rng.randomize()
        pause_end_run = true    # THE PONG LAW: the pause END banks
        size_id = "4"
        var on := Box.item_on(game_id, "size")
        if SIZES.has(on):
                size_id = on
        n = int(size_id)
        _new_board()
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
        dice_l = Node2D.new()
        dice_l.draw.connect(_draw_dice)
        world.add_child(dice_l)
        fx_l = Node2D.new()
        fx_l.z_index = 5
        fx_l.draw.connect(_draw_fx)
        world.add_child(fx_l)
        _layout(vp)
        _build_widgets(vp)
        _load_meta()
        # THE HUD SEAT LAW (v0.3.9-1): the flow seats in call order -
        # the SHOP next to the back button, the OPTIONS at the right side
        add_hud_button("SHOP", func(): _shop_open())
        add_hud_button("OPTIONS", func(): _options_open())
        Jukebox.music("res://assets/audio/music/jc_theme.ogg")
        # THE LORE LAW (v0.3.9-13): the die speaks first - once ever
        # (v042: a LAN boot wears the waiting room instead - the lore
        # waits for a solo boot)
        if lan_hold:
                lan_hold_begin()
        elif Box.counter(game_id, "lore_start") == 0:
                Box.bump_counter(game_id, "lore_start", 1)
                box_story_show("THE DIE", DIE_LORE, func(): _build_ready(),
                                "ROLL", Color("e0533f"))
        else:
                _build_ready()

func _new_board() -> void:
        owners = []
        values = []
        for i in n * n:
                owners.append(0)
                values.append(1)     # the original's law: every die
                                     # wakes with ONE dot
        morph = {}
        pop_t = {}
        cascade = []
        lands = []
        flies = []
        move_who = 0
        chain_n = 0
        move_flips = 0
        holding = false
        ghost_cell = -1

func _theme_id() -> String:
        var tid := Box.item_on(game_id, "theme")
        if not THEMES.has(tid):
                tid = "wood"
        return tid

func _theme() -> Dictionary:
        return THEMES[_theme_id()]

## THE THEME-OWNERSHIP LAW: the theme owns everything but the user's
## dice - the equipped skin re-inks ONLY the user's color, on any theme
func _skin_id() -> String:
        var sid := Box.item_on(game_id, "skin")
        if not SKINS.has(sid) or not Box.item_owned(game_id, "skin", sid):
                sid = "theme"
        return sid

func _user_col() -> Color:
        var sid := _skin_id()
        if sid != "theme":
                return SKINS[sid]["col"]
        return _theme()["user"]

func _user_ink() -> Color:
        var sid := _skin_id()
        if sid != "theme":
                return SKINS[sid]["ink"]
        return _theme()["user_ink"]

func _die_color(o: int) -> Color:
        if o == 1:
                return _user_col()
        if o == 2:
                return _theme()["foe"]
        return _theme()["die"]

func _die_ink(o: int) -> Color:
        if o == 1:
                return _user_ink()
        if o == 2:
                return _theme()["foe_ink"]
        return _theme()["ink"]

## THE THEME SFX LAW (the owner: "SFXs should differ from theme to
## another") - the in/out voices wear the theme's own timbre. THE
## v0.3.9-10 HONESTY FIX: the old call played "cd_in" / "cd_out" - the
## files are cd_in_<voice> / cd_out_<voice>, so every theme's in/out was
## 100% SILENT (the owner heard the truth and told us). The shared
## voices (denied / win / lose / coin / press) keep their bare names.
func _tsfx(base: String, vol := 0.0, pitch := 1.0) -> void:
        var name_ := "cd_" + base
        if base == "in" or base == "out":
                var voice := "wood"
                var th: Dictionary = _theme()
                if th.has("sfx"):
                        voice = String(th["sfx"])
                name_ += "_" + voice
        Jukebox.sfx(name_, vol, pitch)

func _load_meta() -> void:
        bg_l.queue_redraw()
        board_l.queue_redraw()
        dice_l.queue_redraw()
        fx_l.queue_redraw()

## THE ROOM: wall above, floor below, one honest divider (the fourline
## room law - flat theme colors, primitives only)
func _draw_bg() -> void:
        var vp := get_viewport_rect().size
        var th := _theme()
        bg_l.draw_rect(Rect2(Vector2.ZERO, vp), th["room"])
        var fy := vp.y * 0.80
        bg_l.draw_rect(Rect2(0, fy, vp.x, vp.y - fy), th["floor"])
        bg_l.draw_rect(Rect2(0, fy - 3.0, vp.x, 3.0),
                        (th["floor"] as Color).lightened(0.12))

## THE BOARD WALL: the slab under the dice (the theme's frame color),
## a thin inner grid so the board reads as a board
func _slab_rim() -> float:
        return maxf(12.0, cell * 0.13)

func _slab_rect() -> Rect2:
        var span := float(n) * cell
        var rim := _slab_rim()
        return Rect2(board_origin - Vector2(rim, rim),
                        Vector2(span + rim * 2.0, span + rim * 2.0))

func _draw_board() -> void:
        var th := _theme()
        var r := _slab_rect()
        board_l.draw_rect(Rect2(r.position + Vector2(10, 14), r.size),
                        Color(0, 0, 0, 0.35))
        board_l.draw_rect(r, th["wall"])
        board_l.draw_rect(Rect2(r.position.x, r.end.y - 10.0, r.size.x,
                        10.0), th["wall_dark"])
        var grid: Color = (th["wall_dark"] as Color).lightened(0.06)
        grid.a = 0.55
        var gw := maxf(1.5, cell * 0.02)
        for k in range(1, n):
                var px := board_origin.x + float(k) * cell
                board_l.draw_line(Vector2(px, board_origin.y),
                                Vector2(px, board_origin.y + float(n) * cell),
                                grid, gw, true)
                var py := board_origin.y + float(k) * cell
                board_l.draw_line(Vector2(board_origin.x, py),
                                Vector2(board_origin.x + float(n) * cell, py),
                                grid, gw, true)

func _die_rect(i: int) -> Rect2:
        var x := i % n
        var y := i / n
        var inset := maxf(3.0, cell * 0.055)
        return Rect2(board_origin.x + float(x) * cell + inset,
                        board_origin.y + float(y) * cell + inset,
                        cell - inset * 2.0, cell - inset * 2.0)

func cell_center(i: int) -> Vector2:
        var x := i % n
        var y := i / n
        return board_origin + Vector2((float(x) + 0.5) * cell,
                        (float(y) + 0.5) * cell)

## THE DICE: face (the owner's color, morphing), bottom shading, the
## pips (the in: the newest pip pops in), the gray-out press (the hold
## law), the round-over breath
func _draw_dice() -> void:
        var th := _theme()
        var style: String = th["style"]
        for i in owners.size():
                var o := int(owners[i])
                var col := _die_color(o)
                if morph.has(i):
                        var age: float = _time - float(morph[i]["t0"])
                        var k := clampf(age / MORPH_A, 0.0, 1.0)
                        col = (morph[i]["c0"] as Color).lerp(col, k)
                var r := _die_rect(i)
                var ink := _die_ink(o)
                var radius := cell * 0.2
                if style == "pixel":
                        radius = 0.0
                elif style == "mono":
                        radius = cell * 0.12
                # the face pop: a landing pip lifts the face a touch
                var lift := 1.0
                if pop_t.has(i):
                        var pa: float = clampf(
                                        (_time - float(pop_t[i])) / PIP_A,
                                        0.0, 1.0)
                        lift = 1.0 + 0.05 * (1.0 - pa)
                var face := Rect2(r.position + (r.size
                                * (1.0 - lift)) * 0.5, r.size * lift)
                if style == "pixel":
                        # the hard shadow + the hard outline (the 8-bit look)
                        dice_l.draw_rect(Rect2(r.position + Vector2(4, 5),
                                        r.size), Color(0, 0, 0, 0.45))
                        dice_l.draw_rect(face, col)
                        dice_l.draw_rect(face,
                                        (th["room"] as Color).darkened(0.4),
                                        false, 3.0)
                else:
                        if style == "neon":
                                # the soft halo under the face
                                _draw_rr(dice_l,
                                                Rect2(r.position - Vector2(5, 5),
                                                r.size + Vector2(10, 10)),
                                                radius + 5.0, Color(col, 0.30))
                        if style == "mono":
                                # the ink rim under the face (the chalk look)
                                _draw_rr(dice_l,
                                                Rect2(face.position - Vector2(2, 2),
                                                face.size + Vector2(4, 4)),
                                                radius + 2.0,
                                                Color(0.08, 0.08, 0.08, 0.85))
                        # the die's thickness under the face (the weight)
                        _draw_rr(dice_l,
                                        Rect2(face.position + Vector2(0, 5),
                                        face.size), radius,
                                        col.darkened(0.28))
                        _draw_rr(dice_l, face, radius, col)
                # THE PIPS (the dots of the dice)
                var v := int(values[i])
                var pr := cell * 0.085
                if v >= 1 and v <= 6:
                        var seats: Array = PIPS[v]
                        for pidx in seats.size():
                                var seat: Array = seats[pidx]
                                var c := Vector2(face.position.x
                                                + float(seat[0]) * face.size.x,
                                                face.position.y
                                                + float(seat[1]) * face.size.y)
                                # THE IN: the newest pip pops in
                                var rr := pr
                                if pop_t.has(i) and pidx == seats.size() - 1:
                                        var pa: float = clampf((_time
                                                        - float(pop_t[i]))
                                                        / PIP_A, 0.0, 1.0)
                                        rr = pr * (0.25 + 0.75 * pa)
                                if style == "neon":
                                        dice_l.draw_circle(c, rr + 3.0,
                                                        Color(ink, 0.30))
                                dice_l.draw_circle(c, rr, ink)
                elif v > 6:
                        # the transient overload: mid-cascade a die can
                        # hold more than six - the count speaks
                        var f := ThemeDB.fallback_font
                        dice_l.draw_string(f, Vector2(face.position.x,
                                        face.position.y + face.size.y * 0.68),
                                        str(v), HORIZONTAL_ALIGNMENT_CENTER,
                                        face.size.x, int(cell * 0.42), ink)
                # THE GRAY-OUT PRESS (the hold law)
                if holding and ghost_cell == i and state == "play" \
                                and turn == 1:
                        var pulse := 0.30 + 0.10 * sin(_time * 7.0)
                        _draw_rr(dice_l, face, radius,
                                        Color(0.10, 0.09, 0.07, pulse))
                        dice_l.draw_rect(face, Color(1, 1, 1, 0.35),
                                        false, 2.5)
                # the round-over breath
                if state == "round_over" and glow_t >= 0.0 \
                                and glow_t < 1.1 and o == _glow_owner:
                        var k2: float = 1.0 - absf(glow_t - 0.45) / 0.65
                        if k2 > 0.0:
                                _draw_rr(dice_l, face, radius,
                                                Color(1, 1, 1, 0.26 * k2))

func _draw_fx() -> void:
        # THE TABLE'S SECRET: the one-dotted die speaks (above the board,
        # under the flying dots)
        if egg_active and egg_line >= 0 and egg_line < EGG_LINES.size():
                _draw_egg()
        # THE FLYING DOTS (the in and the out)
        for fl in flies:
                var age: float = clampf((_time - float(fl["t0"])) / FLY_T,
                                0.0, 1.0)
                var at: Vector2 = (fl["from"] as Vector2).lerp(fl["to"], age)
                at.y -= sin(age * PI) * cell * 0.22   # the hop's arc
                var who: int = int(fl["who"])
                var fc := _die_color(who)
                var fi := _die_ink(who)
                fx_l.draw_circle(at, cell * 0.09, Color(fc, 0.95))
                fx_l.draw_circle(at, cell * 0.045, fi)
        # the coin (the xo coin law, seated ON its die)
        if coin_cell >= 0 and int(owners[coin_cell]) == 0:
                var tex: Texture2D = load("res://assets/ui/coin.png")
                if tex != null:
                        var pos := cell_center(coin_cell)
                        pos.y += sin(coin_t * 3.2) * cell * 0.06
                        var fade: float = clampf(coin_t / 0.4, 0.0, 1.0)
                        var s: float = cell * 0.5 / float(tex.get_width())
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
                        fx_l.draw_arc(pos, cell * 0.40, ga, ga + 1.1, 30,
                                        Color(1, 1, 1, 0.5 * fade), 2.2)
        # the dust pips
        for p in _dust:
                var a: float = clampf(float(p["life"]) / float(p["max"]),
                                0.0, 1.0)
                var c: Color = p["col"]
                c.a = a * 0.85
                fx_l.draw_rect(Rect2(float(p["x"]) - float(p["s"]) * 0.5,
                                float(p["y"]) - float(p["s"]) * 0.5,
                                float(p["s"]), float(p["s"])), c)

## THE TABLE'S SECRET, drawn: GEOQUARE stands at the board's heart
## wearing its dice costume - ONE dot, and the dot is BALLDOZER (gold,
## breathing) - while the line bubble speaks over the board's foot.
## The dot-eater and the escaper, together on one die, for the first time.
func _draw_egg() -> void:
        var vp := get_viewport_rect().size
        var side := float(n) * cell
        var mid := board_origin + Vector2(side, side) * 0.5
        var breathe := 0.5 + 0.5 * sin(_time * 2.6)
        # the halo (Geoquare's cyan, breathing)
        fx_l.draw_circle(mid, cell * 1.35,
                        Color(0.38, 0.89, 1.0, 0.10 + 0.08 * breathe))
        # the die body (Geoquare, ivory - the escaper wears the costume;
        # the rim rides UNDER the face - this game's _draw_rr is fill-only)
        var ds := cell * 1.55
        var r := Rect2(mid - Vector2(ds, ds) * 0.5, Vector2(ds, ds))
        var radius := ds * 0.18
        _draw_rr(fx_l, Rect2(r.position + Vector2(3, 6), r.size),
                        radius, Color(0, 0, 0, 0.40))
        _draw_rr(fx_l, r.grow(2.6), radius + 2.6, Color("8a744e"))
        _draw_rr(fx_l, r, radius, Color("f4ead2"))
        # THE DOT (Balldozer, gold, breathing - the dot eater on its throne)
        var dot_r := cell * 0.17 * (1.0 + 0.12 * breathe)
        fx_l.draw_circle(mid, dot_r + cell * 0.035,
                        Color(0.42, 0.28, 0.06, 0.85))
        fx_l.draw_circle(mid, dot_r, Color("ffd24a"))
        fx_l.draw_circle(mid + Vector2(-dot_r * 0.3, -dot_r * 0.3),
                        dot_r * 0.22, Color(1, 1, 1, 0.55))
        # the bubble (the line speaks - the speaker wears its own color)
        var line: Array = EGG_LINES[egg_line]
        var who := String(line[0])
        var say := String(line[1])
        var tint: Color = EGG_TINTS.get(who, Color(1, 1, 1))
        var f := ThemeDB.fallback_font
        var bw := minf(640.0, vp.x - 40.0)
        var bh := 104.0
        var bp := Vector2((vp.x - bw) * 0.5,
                        vp.y - banner_bottom() - bh - 14.0)
        var br := Rect2(bp, Vector2(bw, bh))
        _draw_rr(fx_l, Rect2(br.position + Vector2(3, 5), br.size), 16.0,
                        Color(0, 0, 0, 0.45))
        _draw_rr(fx_l, br.grow(2.2), 18.0, Color(tint, 0.65))
        _draw_rr(fx_l, br, 16.0, Color(0.09, 0.07, 0.05, 0.94))
        fx_l.draw_string(f, br.position + Vector2(18.0, 34.0), who,
                        HORIZONTAL_ALIGNMENT_LEFT, -1, 24, tint)
        fx_l.draw_string(f, br.position + Vector2(18.0, 72.0), say,
                        HORIZONTAL_ALIGNMENT_LEFT, bw - 36.0, 22,
                        Color(1, 1, 1, 0.95))

## a filled rounded rect as a polygon (draw_rect has no corners - the
## dice wear curved edges like every honest die). The four corner arcs
## sweep the RIGHT quadrants: top-right -90..0, bottom-right 0..90,
## bottom-left 90..180, top-left 180..270 (the film rig caught the
## first draft sweeping all four arcs the same way - the dice read as
## pinwheels).
func _draw_rr(c: CanvasItem, r: Rect2, radius: float, col: Color) -> void:
        if radius <= 0.5:
                c.draw_rect(r, col)
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
        c.draw_colored_polygon(pts, col)

func _layout(vp: Vector2) -> void:
        var top := 210.0
        var bot := banner_bottom() + 50.0
        cell = minf((vp.x - 48.0) / float(n),
                        (vp.y - top - bot - 40.0) / float(n))
        cell = minf(cell, 150.0)
        cell = maxf(cell, 42.0)
        var side := float(n) * cell
        var spare := vp.y - top - bot - side
        board_origin = Vector2((vp.x - side) * 0.5,
                        top + maxf(0.0, spare * 0.42))
        _place_texts(vp)
        bg_l.queue_redraw()
        board_l.queue_redraw()
        dice_l.queue_redraw()
        fx_l.queue_redraw()

## the turn + verdict texts seat once, from layout AND from build
func _place_texts(vp: Vector2) -> void:
        var span := float(n) * cell
        if turn_lbl != null:
                turn_lbl.position = Vector2(0, board_origin.y - 92.0)
                turn_lbl.custom_minimum_size = Vector2(vp.x, 44)
        if verdict_lbl != null:
                verdict_lbl.position = Vector2(0,
                                board_origin.y + span
                                + maxf(26.0, cell * 0.13) + 20.0)
                verdict_lbl.custom_minimum_size = Vector2(vp.x, 50)

# ------------------------------------------------- the widget row

func _build_widgets(vp: Vector2) -> void:
        # THE W-L CARDS (the squares law: this game has no draws - the
        # total-conquest verdict cannot tie)
        goals_row = Control.new()
        goals_row.custom_minimum_size = Vector2(108.0 * 2.0 + 8.0, 64.0)
        goals_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        goals_row.draw.connect(_draw_goal_cards.bind(goals_row))
        _hud_row.add_child(goals_row)
        var score_chip: Control = _score_label.get_parent().get_parent()
        # THE SEAT LAW (the squares law): the cards seat BEFORE the score
        # chip - the row reads goals | SCORE | coins
        _hud_row.move_child(goals_row, score_chip.get_index())
        # THE TALLY SEAT (the squares law): RED nn | BLUE nn rides UNDER
        # the W/L cards as the goals card's own child
        tally_row = Control.new()
        tally_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        tally_row.draw.connect(_draw_tally_cards.bind(tally_row))
        goals_row.add_child(tally_row)
        tally_row.position = Vector2((224.0 - 136.0) * 0.5, 68.0)
        tally_row.size = Vector2(136.0, 46.0)
        turn_lbl = Arc.label("", 30, Color(1, 1, 1, 0.95))
        turn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        world.add_child(turn_lbl)
        verdict_lbl = Arc.label("", 32, Color(1, 1, 1, 0.95))
        verdict_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        verdict_lbl.visible = false
        world.add_child(verdict_lbl)
        _place_texts(vp)
        _refresh_widget()

func _draw_tally_cards(c: Control) -> void:
        var cw := 64.0
        var ch := 46.0
        var gapw := 8.0
        var f := ThemeDB.fallback_font
        var mid_y := c.size.y * 0.5
        var x0 := c.size.x * 0.5
        for i in 2:
                var x: float = (cw + gapw) * (float(i) - 1.0) + x0
                var r := Rect2(x - cw * 0.5, mid_y - ch * 0.5, cw, ch)
                var col: Color = _user_col() if i == 0 \
                                else (_theme()["foe"] as Color)
                c.draw_rect(Rect2(r.position + Vector2(4, 4), r.size),
                                Color(0.09, 0.05, 0.02, 0.85))
                c.draw_rect(r, Color(1, 1, 1, 0.95))
                c.draw_rect(r, col, false, 5.0)
                # the glyph: a die with one pip, in the owner's color
                var g := 18.0
                var gr := Rect2(x - cw * 0.5 + 9.0, mid_y - g * 0.5, g, g)
                _draw_rr(c, gr, 4.0, col)
                c.draw_circle(Vector2(gr.position.x + g * 0.5,
                                gr.position.y + g * 0.5), 2.6,
                                _die_ink(1 if i == 0 else 2))
                var num: int = count_owned(owners, 1 if i == 0 else 2)
                c.draw_string(f, Vector2(x - cw * 0.5 + 32.0,
                                mid_y + 13.0), str(num),
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Arc.INK)

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
        if tally_row != null:
                tally_row.queue_redraw()
        if goals_row != null:
                goals_row.queue_redraw()

# ------------------------------------------------------- the ready gate

func _build_ready() -> void:
        var vp := get_viewport_rect().size
        ready_ui = Control.new()
        ready_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        ready_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hud.add_child(ready_ui)
        # THE GATE LAW (v0.3.8-8): index 0 of the HUD - under the sheets
        _hud.move_child(ready_ui, 0)
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

func _gate_down() -> void:
        if ready_ui != null and is_instance_valid(ready_ui):
                ready_ui.queue_free()
                ready_ui = null

# ============================================================ the rounds

# ============================================================ v042 THE LAN SEAT
## 2P TURN_RELAY (the squares bones): local 1, rival 2, the conquest taps
## ride the ONE _place door (the anim + spill play out identically from
## the same seeded board), the CPU never wakes.

func lan_match_start(seed_v: int, m_seats: Array) -> void:
        lan_active = true
        _rng.seed = seed_v
        next_opener = 1
        done_rounds = 0
        _new_round()

func lan_solo() -> void:
        lan_active = false
        _build_ready()

func _lan_name(p: int) -> String:
        if lan_seats.is_empty():
                return "RIVAL"
        var idx: int = clampi(p - 1, 0, lan_seats.size() - 1)
        return String(lan_seats[idx].get("name", "RIVAL"))

func lan_act(who: int, a: Dictionary) -> void:
        match String(a.get("k", "")):
                "place":
                        if state == "play" or state == "wait":
                                _place(int(a.get("i", -1)), 2)

func _new_round() -> void:
        _new_board()
        _refresh_widget()       # the tally reads the NEW board (0 | 0)
        _dust = []
        shake_t = -1.0
        shake_n = 0
        egg_idle = 0.0
        egg_active = false
        egg_fired = false
        egg_line = -1
        glow_t = -1.0
        _glow_owner = 0
        player_best_chain = 0
        rounds += 1
        verdict_lbl.visible = false
        # THE OPENER LAW (the owner: "who plays first is the user then
        # the loser plays first for other rounds" - no draws, no flip)
        last_opener = next_opener
        turn = next_opener
        clock = 0.0
        # the mood pick (THE RESULT LAW, v0.3.9-10): the memory's results
        # choose the next mood and breathe the failures - not a blind
        # round-robin anymore
        var pick := adapt_pick(mem, _rng)
        profile = pick["profile"]
        miss_mul = float(pick["miss_mul"])
        err_mul = float(pick["err_mul"])
        # THE COIN LAW: after every 3 completed rounds the next round
        # opens with a GOGACoin resting ON a neutral die - whoever
        # conquers that die takes it (the CPU races you)
        coin_cell = -1
        coin_t = 0.0
        if done_rounds > 0 and done_rounds % COIN_EVERY == 0:
                if lan_active:
                        coin_cell = _coin_rot % (n * n)
                        _coin_rot += 1
                else:
                        coin_cell = _rng.randi() % (n * n)
        # THE STATE LAW (v0.3.9-1): _new_round is the round's ONLY door -
        # it seats the state machine whole
        if turn == 1:
                state = "play"      # the player opens: the board is live
        else:
                state = "wait"      # the CPU opens: it thinks, then taps
                if not lan_active:
                        cpu_think = true
                        think_beat = _rng.randf_range(0.4, 0.8)
        _banner()
        dice_l.queue_redraw()
        fx_l.queue_redraw()

func _banner() -> void:
        if state == "round_over":
                return
        if turn == 1:
                turn_lbl.text = "YOUR MOVE"
                turn_lbl.add_theme_color_override("font_color",
                                Color(1, 1, 1, 0.95))
        else:
                var k := int(_time * 2.5) % 3 + 1
                turn_lbl.text = "CPU IS THINKING%s" % " .".repeat(k)
                turn_lbl.add_theme_color_override("font_color",
                                Color(1, 1, 1, 0.8))

# ============================================================ the hand

func _goga_input(event: InputEvent) -> void:
        if sheet_open_count() > 0:
                return
        # the egg listens too: a touch during the secret hears the NEXT
        # line right away (and any touch restarts the idle clock - the
        # sixty seconds of silence begin again)
        var touched := false
        if event is InputEventScreenTouch:
                touched = true
        elif event is InputEventMouseButton:
                touched = true
        elif event is InputEventScreenDrag or event is InputEventMouseMotion:
                touched = true
        if touched:
                egg_idle = 0.0
                if egg_active and event is InputEventScreenTouch \
                                and bool((event as InputEventScreenTouch).pressed):
                        egg_t = 0.0
                        egg_line += 1
                        if egg_line >= EGG_LINES.size():
                                egg_active = false
                                egg_line = -1
                        return
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                if t.pressed:
                        if state == "ready":
                                _gate_down()
                                _new_round()
                                gate_hush = _time + 0.2
                                return
                        _press(t.position)
                else:
                        _release(t.position)
        elif event is InputEventScreenDrag:
                if holding and state == "play" and turn == 1:
                        ghost_cell = _cell_at(
                                        (event as InputEventScreenDrag).position)
                        dice_l.queue_redraw()
        elif event is InputEventMouseButton:
                var mb := event as InputEventMouseButton
                if mb.pressed:
                        if state == "ready":
                                _gate_down()
                                _new_round()
                                gate_hush = _time + 0.2
                                return
                        _press(mb.position)
                else:
                        _release(mb.position)
        elif event is InputEventMouseMotion:
                if holding and state == "play" and turn == 1:
                        ghost_cell = _cell_at(
                                        (event as InputEventMouseMotion).position)
                        dice_l.queue_redraw()

## the cell under a finger point (the board rect with a slack; outside
## is -1 - the release-cancellation seat)
func _cell_at(at: Vector2) -> int:
        var span := float(n) * cell
        var g := Rect2(board_origin, Vector2(span, span))
        var slack := cell * 0.35
        if at.x < g.position.x - slack or at.x > g.end.x + slack \
                        or at.y < g.position.y - slack \
                        or at.y > g.end.y + slack:
                return -1
        var x := clampi(int((at.x - g.position.x) / cell), 0, n - 1)
        var y := clampi(int((at.y - g.position.y) / cell), 0, n - 1)
        return y * n + x

## THE PRESS: the gray-out wakes on the die under the finger - unless
## the gate's tap shadow still rides (THE GATE HUSH)
func _press(at: Vector2) -> void:
        if state != "play" or turn != 1 or move_who != 0:
                return
        if _time < gate_hush:
                return
        holding = true
        ghost_cell = _cell_at(at)
        dice_l.queue_redraw()

## THE RELEASE: the die gets the action - out of the board nothing lands
func _release(_at: Vector2) -> void:
        if not holding:
                return
        holding = false
        var i := ghost_cell
        ghost_cell = -1
        dice_l.queue_redraw()
        if i < 0:
                return          # the cancel: nothing is placed
        if state != "play" or turn != 1 or move_who != 0:
                return
        if not legal_at(owners, i, 1):
                _tsfx("denied", -8.0)
                return
        _place(i, 1)

# ============================================================ the moves

## THE PLACE: take the die, +1 dot, and the cascade (the in and the out)
## runs one breath per pop - the tick owns it (the STATE LAW: the move
## pipeline seats state = anim the moment a spill is armed)
func _place(i: int, who: int) -> void:
        if who == 1 and lan_active:
                LAN.send_act({"k": "place", "i": i})
        var old := int(owners[i])
        owners[i] = who
        values[i] = int(values[i]) + 1
        move_who = who
        chain_n = 0
        move_flips = 1 if old != who else 0
        if old != who:
                morph[i] = {"c0": _die_color(old), "t0": _time}
                if coin_cell >= 0 and i == coin_cell and old == 0:
                        _coin_taken(who, i)
        pop_t[i] = _time
        _tsfx("in", -7.0)
        _refresh_widget()       # THE MUTATOR LAW: repaint what you mutate
        dice_l.queue_redraw()
        if int(values[i]) > max_of(i, n):
                cascade.append(i)
                state = "anim"
        else:
                _end_move()

## one tick of the cascade: land the due dots, fire the next pop, and
## when the air is quiet - hand the move its verdict or its hand-off.
## THE ORIGINAL'S EARLY EXIT rides above it all: the moment every die
## wears the mover's color the cascade is abandoned mid-air and the
## verdict lands (the original returns true at once - a finished board
## never keeps popping).
func _tick_move() -> void:
        # 1. the landings whose time has come (the in)
        while not lands.is_empty() and _time >= float(lands[0]["at"]):
                _land(lands.pop_front())
        # 2. the early exit: TOTAL CONQUEST is on the board
        if move_who != 0 and count_owned(owners, move_who) == n * n:
                cascade = []
                lands = []
                _end_move()
                return
        # 3. the next pop when the air is quiet (the out)
        if lands.is_empty() and not cascade.is_empty():
                _pop_one()
        # 4. THE DRAIN: the move ends only when nothing is in the air
        if lands.is_empty() and cascade.is_empty() and move_who != 0:
                _end_move()

## one pop: the cap leaves the die, a dot flies into EVERY neighbor; a
## still-overloaded popper re-queues itself (the re-push law - the QA
## SOAK caught its absence: an armed die sat over its cap while the
## pours cycled around it, and the round never ended)
func _pop_one() -> void:
        var c: int = cascade.pop_front()
        var m := max_of(c, n)
        values[c] = int(values[c]) - m
        chain_n += 1
        pop_t[c] = _time
        if chain_n >= 3:
                shake_t = _time
                shake_n = mini(chain_n, 7)
        _tsfx("out", -5.0, 1.0 + 0.05 * minf(chain_n, 9))
        for nb in neighbors_of(c, n):
                lands.append({"at": _time + FLY_T, "cell": nb,
                                "who": move_who})
                flies.append({"from": cell_center(c), "to": cell_center(nb),
                                "t0": _time, "who": move_who})
        if int(values[c]) > m and not cascade.has(c):
                cascade.append(c)            # the re-push law
        dice_l.queue_redraw()

## a dot lands: the die grows, its color crossfades to the mover's, a
## too-many die joins the cascade once (the chain spreads)
func _land(l: Dictionary) -> void:
        var i: int = int(l["cell"])
        var who: int = int(l["who"])
        var old := int(owners[i])
        owners[i] = who
        values[i] = int(values[i]) + 1
        if old != who:
                move_flips += 1
                morph[i] = {"c0": _die_color(old), "t0": _time}
                if coin_cell >= 0 and i == coin_cell and old == 0:
                        _coin_taken(who, i)
        pop_t[i] = _time
        _tsfx("in", -7.0, 1.0 + 0.055 * minf(chain_n, 9))
        if int(values[i]) > max_of(i, n) and not cascade.has(i):
                cascade.append(i)
        dice_l.queue_redraw()

## the move's end: THE VERDICT-FIRST LAW - the terminal check outranks
## the hand-off (a conquest that ends the round must resolve, never
## hand the board to a dead round)
func _end_move() -> void:
        var who := move_who
        move_who = 0
        if who == 1:
                achievement_max("chain", chain_n)
                player_best_chain = maxi(player_best_chain, chain_n)
                if move_flips > 0:
                        achievement_count("dice", move_flips)
        move_flips = 0
        _refresh_widget()       # the tally reads the conquered count
        if count_owned(owners, who) == n * n:
                _resolve(who)        # TOTAL CONQUEST - the original's law
                return
        if who == 2:
                turn = 1
                state = "play"
                _banner()
        else:
                turn = 2
                state = "wait"
                if not lan_active:
                        cpu_think = true
                        think_beat = _rng.randf_range(0.5, 0.95)
                clock = 0.0
                _banner()

func _ai_move() -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = int(Time.get_unix_time_from_system() * 1000.0) \
                        ^ (rounds * 7919) ^ (owners.hash() & 0xffff)
        var flags := adapt(mem)
        var i := cpu_pick(owners, values, n, 2, profile,
                        bool(flags["alert"]), rng, miss_mul, err_mul)
        if i >= 0 and legal_at(owners, i, 2):
                _place(i, 2)

# ============================================================ the verdict

func _resolve(w: int) -> void:
        state = "round_over"
        clock = 0.0
        glow_t = 0.0
        _glow_owner = w
        done_rounds += 1
        mem = remember(mem, {"mass": player_best_chain, "result": w,
                        "profile": profile})
        if w == 1:
                wins += 1
                streak += 1
                add_score(1)                     # THE OWNER'S LAW: win = +1
                verdict_lbl.text = "YOU CONQUER THE BOARD  +1"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("7ee2a0"))
                _tsfx("win", -3.0)
                achievement_count("wins", 1)
                achievement_max("streak", streak)
                var mid := board_origin + Vector2(
                                (float(n) * cell) * 0.5,
                                (float(n) * cell) * 0.5)
                Arc.confetti(_overlay_root_ref(), mid, 30)
        else:
                losses += 1
                streak = 0
                if score > 0:
                        add_score(-1)    # never under zero (the xo law)
                verdict_lbl.text = ("%s CONQUERS THE BOARD  -1" % _lan_name(2).to_upper()) if lan_active else "THE CPU CONQUERS THE BOARD  -1"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("f2a09a"))
                _tsfx("lose", -3.0)
        # THE OPENER LAW: the loser starts next (no draws on this board)
        if w == 1:
                next_opener = 2
        else:
                next_opener = 1
        achievement_max("max_score", score)
        _refresh_widget()
        verdict_lbl.visible = true
        turn_lbl.text = ""
        check_achievements()

# ============================================================ the tick

func _goga_tick(delta: float) -> void:
        _time += delta
        # THE TABLE'S SECRET: the idle minute. Live play only (never under
        # a sheet, never on the verdict), once a round, EXACTLY sixty
        # seconds of untouched board - then the box's oldest rumor stands up
        if state == "play" or state == "wait" or state == "anim":
                if not egg_active and not egg_fired \
                                and sheet_open_count() == 0:
                        egg_idle += delta
                        if egg_idle >= EGG_IDLE:
                                egg_fired = true
                                egg_active = true
                                egg_line = 0
                                egg_t = 0.0
                                Jukebox.sfx("confirm", -10.0)
        if egg_active:
                egg_t += delta
                var say: String = String(EGG_LINES[egg_line][1])
                var hold := maxf(2.2, 1.1 + float(say.length()) / 11.0)
                if egg_t >= hold:
                        egg_t = 0.0
                        egg_line += 1
                        if egg_line >= EGG_LINES.size():
                                egg_active = false
                                egg_line = -1
                                egg_idle = 0.0
        if state == "wait":
                clock += delta
                if cpu_think and not lan_active:
                        _banner()
                        if clock >= think_beat:
                                cpu_think = false
                                _ai_move()
        elif state == "anim":
                _tick_move()
        elif state == "round_over":
                clock += delta
                if glow_t >= 0.0:
                        glow_t = minf(1.2, glow_t + delta * 1.4)
                if clock >= 2.3:
                        _new_round()
        # the board shake (the big-spill rumble): the world itself breathes
        if shake_t >= 0.0:
                var age := _time - shake_t
                if age > 0.3:
                        shake_t = -1.0
                        shake_n = 0
                        world.position = Vector2.ZERO
                else:
                        var amp := float(shake_n) * 1.1 * (1.0 - age / 0.3)
                        world.position = Vector2(
                                        sin(age * 46.0) * amp,
                                        cos(age * 39.0) * amp * 0.6)
        coin_t += delta
        # the fly retirement (tiny list)
        if not flies.is_empty():
                var alive := []
                for fl in flies:
                        if _time - float(fl["t0"]) < FLY_T + 0.05:
                                alive.append(fl)
                flies = alive
        # the morph retirement (tiny dicts)
        if not morph.is_empty():
                var stale := []
                for m in morph:
                        if _time - float(morph[m]["t0"]) > MORPH_A + 0.1:
                                stale.append(m)
                for m in stale:
                        morph.erase(m)
        if not pop_t.is_empty():
                var stale := []
                for p in pop_t:
                        if _time - float(pop_t[p]) > PIP_A + 0.1:
                                stale.append(p)
                for p in stale:
                        pop_t.erase(p)
        # THE DUST LIFE (the squares law): gravity, velocity, aging,
        # retirement - the tick owns them
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
        # THE LIVING LAYER LAW (v0.3.9-4): every layer whose art reads
        # the clock repaints on the TICK
        dice_l.queue_redraw()
        fx_l.queue_redraw()

# ------------------------------------------------------------ dust + coin

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

func _coin_taken(who: int, i: int) -> void:
        coin_cell = -1
        var at := cell_center(i)
        if who == 1:
                add_run_coins(1)
                achievement_count("coins", 1)
                _tsfx("coin", -3.0)
                game_toast("YOU TOOK THE GOGACOIN  +1")
                _dust_burst(at, Color("ffd24a"), 14)
        else:
                Jukebox.sfx("coin", -6.0, 0.8)
                game_toast("THE CPU GRABBED THE COIN")

# ============================================================ the options
## THE BOARD SIZES (the 2048 mechanic word for word): the options sheet
## is a PICKER, not a shop - owned sizes show SWITCH (with the
## are-you-sure), locked sizes are LOCKED and their tap walks to the
## SHOP. The confirm is stack-borne; a YES pops the STALE sheet under it
## and a FRESH one reads the applied board (the v0.3.8-8 fresh-sheet law).

func _options_open() -> void:
        var sheet := sheet_push(0.0, "options")
        var t := Arc.label("CONQUER DICE OPTIONS", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var hint := Arc.fit_label("a bigger board holds a bigger war - "
                + "switching starts a fresh board", 19, Arc.HOT, 560)
        hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(hint)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.46, 260.0,
                        540.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        for id in SIZES:
                box.add_child(_size_row(id))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): sheet_pop()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

## the row: THE BUY LAW (v0.3.9-1, the owner: "it should be bought only
## from shop, never applied from it, the options menu is where this
## happens") - the SHOP only SELLS: a locked size's BUY takes the coins
## and stops there; an owned size reads OWNED and points at the options.
func _size_row(id: String, in_shop := false) -> Control:
        var sz: Dictionary = SIZES[id]
        var owned := Box.item_owned(game_id, "size", id) \
                        or int(sz["price"]) == 0
        var on := size_id == id
        var head := Arc.label("%s%s" % [sz["name"],
                        "  (ON)" if on else ""], 19,
                        Color("58c470") if on else Arc.INK, false)
        head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        head.custom_minimum_size = Vector2(560, 0)
        head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 2)
        v.add_child(head)
        if on:
                return v
        if owned:
                if in_shop:
                        # THE BUY LAW: the shop never applies - the owned
                        # size just points home
                        var ol := Arc.fit_label(
                                        "OWNED - APPLY IT FROM THE OPTIONS",
                                        20, Color("58c470"), 560)
                        ol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        v.add_child(ol)
                        return v
                v.add_child(Arc.button("SWITCH", Vector2(560, 56), 22,
                                Arc.ACCENT, func(): _size_confirm(id)))
                return v
        if not in_shop:
                var lk := Arc.button("LOCKED - %d IN THE SHOP"
                                % int(sz["price"]),
                                Vector2(560, 56), 20,
                                Color(0.55, 0.48, 0.38),
                                func():
                                        sheet_pop()      # the options step aside
                                        _shop_open())    # the shop answers
                v.add_child(lk)
                return v
        var b := Arc.coin_button("BUY  %d" % int(sz["price"]),
                        Vector2(560, 56), 22, Arc.ACCENT, func():
                                        if Box.buy_item(game_id, "size", id,
                                                        int(sz["price"])):
                                                Jukebox.sfx("buy")
                                                _toast_show("%s IS YOURS - APPLY IT FROM THE OPTIONS"
                                                                % String(sz["name"]).to_upper())
                                        else:
                                                Jukebox.sfx("error", -6.0)
                                                _toast_show("need %d more GOGACoins"
                                                                % (int(sz["price"])
                                                                - Box.coins()))
                                        _shop_reopen())
        if Box.coins() < int(sz["price"]):
                b.disabled = true
        v.add_child(b)
        return v

## THE ARE-YOU-SURE SHEET (the 2048 law): the confirm PUSHES on top of
## whatever is live. YES pops it, pops the stale options sheet under it
## and applies the board (the v0.3.8-8 fresh-sheet law).
func _size_confirm(id: String) -> void:
        if _confirm_open_id != "":
                sheet_pop()          # a confirm is already up - replace it
        _confirm_open_id = id
        var sheet := sheet_push(0.0, "confirm")
        var sz: Dictionary = SIZES[id]
        var t := Arc.label("SWITCH TO %s?" % String(sz["name"]).to_upper(),
                        32, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var w := Arc.fit_label("switching starts a fresh board -\nthe current round is wiped",
                        22, Arc.HOT, 560)
        w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(w)
        sheet.add_child(Arc.button("YES - SWITCH", Vector2(560, 84), 28,
                        Arc.GOOD, func():
                        sheet_pop()                      # the confirm dies first
                        _confirm_open_id = ""
                        if sheet_open_count() > 0:
                                sheet_pop()              # the stale sheet too
                        Box.equip_item(game_id, "size", id)
                        Jukebox.sfx("confirm", -4.0)
                        _apply_size(id)
                        _options_open()))                # a FRESH options sheet
                                                         # reads the board (ON)
        sheet.add_child(Arc.button("NO", Vector2(560, 74), 26, Arc.BAD,
                        func():
                        sheet_pop()
                        _confirm_open_id = ""))

## the applied board: rebuild the grid, start a fresh round
func _apply_size(id: String) -> void:
        size_id = id
        n = int(id)
        _new_board()
        holding = false
        ghost_cell = -1
        if state == "ready":
                _layout(get_viewport_rect().size)
                return
        _layout(get_viewport_rect().size)
        _new_round()

# ============================================================ the shop
## THEMES + DICE SKINS + the board sizes (the owner: a theme owns
## everything except the user's dice; the skins re-ink the user's dice
## on any theme). The chess law: coin buttons, gray when the wallet is
## dry, (ON) rows, reopen-on-buy.

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
        var t := Arc.label("CONQUER DICE SHOP", 34, Arc.INK)
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
        # THE SHELF ORDER LAW (the owner v0.3.9-10: "you literally swapped
        # positions of themes with the skins, usually skins at the top and
        # themes under them in all other games") - the DICE SKINS seat
        # first, the themes under them, the sizes last
        box.add_child(_shop_label("DICE SKINS - the color only you wear, "
                        + "on any theme"))
        for id in SKINS:
                box.add_child(_skin_row(id))
        box.add_child(_shop_label("THEMES - the room, the board wall, the "
                        + "neutral dice, the enemy and each theme's own "
                        + "sound. YOUR dice are never theirs."))
        for id in THEMES:
                box.add_child(_theme_row(id))
        box.add_child(_shop_label(
                        "BOARD SIZES - bigger boards, bought first"))
        for id in SIZES:
                box.add_child(_size_row(id, true))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): sheet_pop()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _goga_sheet_popped(id: String) -> void:
        if id == "options":
                get_tree().paused = false
                paused = false
        elif id == "confirm":
                _confirm_open_id = ""
                get_tree().paused = false
                paused = false
        elif id == "shop":
                shop_id = ""
                get_tree().paused = false
                paused = false
                _load_meta()
                # THE GATE TRUTH LAW: the gate comes back ONLY over ready
                if state == "ready" and ready_ui != null \
                                and is_instance_valid(ready_ui):
                        ready_ui.visible = true

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
                return Arc.on_row("%s  (ON)" % c["name"])
        if owned:
                return Arc.button(c["name"],
                        Vector2(560, 60), 22, Arc.ACCENT, func():
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
                return Arc.button(s["name"],
                        Vector2(560, 60), 22, Arc.ACCENT, func():
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

func probe_reset(seed_v: int, side := 4) -> void:
        _rng.seed = seed_v
        _gate_down()
        size_id = str(side)
        n = side
        _new_board()
        _dust = []
        shake_t = -1.0
        shake_n = 0
        egg_idle = 0.0
        egg_active = false
        egg_fired = true      # the probes never meet the secret (the
                              # soak's 60s of ticks would wake it)
        glow_t = -1.0
        _glow_owner = 0
        rounds = 0
        done_rounds = 0
        wins = 0
        losses = 0
        draws = 0
        streak = 0
        mem = []
        profile_i = 0
        next_opener = 1
        last_opener = 1
        holding = false
        ghost_cell = -1
        gate_hush = -1.0
        paused = true
        _layout(get_viewport_rect().size)
        _new_round()

func probe_step(dt: float) -> void:
        _goga_tick(dt)

## THE DRAIN (v0.3.9-2): a rig asserts only when the air is clean -
## run the machine until the player may act or the round is over
func probe_drain(max_ticks := 400) -> void:
        var k := 0
        while (state == "anim" or state == "wait") and k < max_ticks:
                _goga_tick(0.05)
                k += 1



