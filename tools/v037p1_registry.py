#!/usr/bin/env python3
"""v0.3.7-1 registry transform v2 - bulletproof block parsing (brace-depth
scan, quote-aware). Replaces age / reveal / ach per game, retires Key
Singer, parks 5 SOON titles. desc/controls survive untouched."""
import re, sys

P = "/home/z/my-project/GOGABox/projects/gogabox/game/core/registry.gd"
src = open(P).read()

AGES = {"snake": "5", "rally": "3", "lanes": "7", "slasher": "7",
        "hopper": "3", "merge": "5", "dario": "7", "xo": "3",
        "matcher": "5", "invaders": "7", "cosmic_spud": "9",
        "pop_siege": "7", "geometry": "3", "maze": "3"}

REVEALS = {
"rally": ['"reveal": {"kind": "chain"},'],
"lanes": ['"reveal": {"kind": "orders", "appear_after": 0,',
          '    "orders": [{"type": "plays", "game": "rally", "count": 3},',
          '        {"type": "beat_best", "game": "rally"}],',
          '    "needs_games": 2},'],
"slasher": ['"reveal": {"kind": "orders", "appear_after": 1,',
          '    "orders": [{"type": "spend_in", "game": "lanes", "amount": 120},',
          '        {"type": "plays", "game": "rally", "count": 5}],',
          '    "needs_games": 3},'],
"hopper": ['"reveal": {"kind": "chain"},'],
"merge": ['"reveal": {"kind": "orders", "appear_after": 2,',
          '    "orders": [{"type": "earn_in", "game": "hopper", "amount": 120},',
          '        {"type": "spend_in", "game": "slasher", "amount": 150}],',
          '    "needs_games": 5},'],
"dario": ['"reveal": {"kind": "orders", "appear_after": 3,',
          '    "orders": [{"type": "plays", "game": "merge", "count": 4},',
          '        {"type": "ach_in", "game": "merge", "count": 2}],',
          '    "needs_games": 6},'],
"xo": ['"reveal": {"kind": "inbox", "minutes": 45, "appear_after": 4,',
          '    "needs_games": 7},'],
"invaders": ['"reveal": {"kind": "orders", "appear_after": 5,',
          '    "orders": [{"type": "spend_in", "game": "dario", "amount": 200},',
          '        {"type": "plays", "game": "xo", "count": 6}],',
          '    "needs_games": 8},'],
"matcher": ['"charge_unlock": 150,',
          '"reveal": {"kind": "orders", "appear_after": 6,',
          '    "orders": [{"type": "plays", "game": "invaders", "count": 5},',
          '        {"type": "spend_charges", "amount": 60}],',
          '    "needs_games": 9},'],
"pop_siege": ['"charge_unlock": 250,',
          '"reveal": {"kind": "direct", "appear_after": 7,',
          '    "needs_games": 10},'],
"geometry": ['"reveal": {"kind": "orders", "appear_after": 8,',
          '    "orders": [{"type": "ach_in", "game": "pop_siege", "count": 2},',
          '        {"type": "spend_in", "game": "matcher", "amount": 200}],',
          '    "needs_games": 11},'],
"maze": ['"reveal": {"kind": "orders", "appear_after": 9,',
          '    "orders": [{"type": "earn_in", "game": "geometry", "amount": 200},',
          '        {"type": "plays", "game": "pop_siege", "count": 4}],',
          '    "needs_games": 12},'],
"cosmic_spud": ['"charge_unlock": 400,',
          '"reveal": {"kind": "direct", "appear_after": 10,',
          '    "needs_games": 13},'],
}

def A(rows):
    out = ['"ach": [']
    for tid, title, desc, tier, k, key, v in rows:
        kp = ', "key": "%s"' % key if key else ""
        out.append('    {"id": "%s", "title": "%s", "desc": "%s", "tier": %d, '
                   '"rule": {"k": "%s"%s, "v": %d}},' % (tid, title, desc, tier, k, kp, v))
    out.append('],')
    return "\n".join(out)

ACH = {
"snake": A([("score_t1","Snack Time","Score 30 in one run",1,"score","",30),
        ("score_t2","Long Boi","Score 100 in one run",2,"score","",100),
        ("score_t3","Anaconda","Score 300 in one run",3,"score","",300),
        ("score_t4","The Floor Is Gone","Score 600 in one run",4,"score","",600),
        ("apples_t1","Fruit Hoarder","Eat 50 fruits total",1,"cnt","apples",50),
        ("apples_t2","Orchard Wiper","Eat 500 fruits total",2,"cnt","apples",500),
        ("apples_t3","The Garden's End","Eat 5000 fruits total",3,"cnt","apples",5000),
        ("coins_t1","Coin Collector","Grab 100 GOGACoins total",1,"cnt","coins_taken",100),
        ("coins_t2","Coin Dragon","Grab 1000 GOGACoins total",2,"cnt","coins_taken",1000),
        ("coins_t3","The Golden Coil","Grab 5000 GOGACoins total",3,"cnt","coins_taken",5000),
        ("len_t1","Half a Hundred","Reach a body of 60",1,"max","length",60),
        ("len_t2","River Snake","Reach a body of 140",2,"max","length",140),
        ("len_t3","The World Coil","Reach a body of 260",3,"max","length",260),
        ("plays_t1","Regular","Play 10 rounds",1,"stat","plays",10),
        ("plays_t2","The Resident","Play 100 rounds",2,"stat","plays",100)]),
"rally": A([("rally_t1","Warm-Up","Return the ball 15 times in one run",1,"max","max_rally",15),
        ("rally_t2","Wall of Paddle","Return the ball 40 times in one run",2,"max","max_rally",40),
        ("rally_t3","Table Legend","Return the ball 100 times in one run",3,"max","max_rally",100),
        ("rally_t4","The Forever Rally","Return the ball 200 times in one run",4,"max","max_rally",200),
        ("score_t1","First Blood","Score 50 in one run",1,"score","",50),
        ("score_t2","Smash Artist","Score 150 in one run",2,"score","",150),
        ("score_t3","Court Legend","Score 400 in one run",3,"score","",400),
        ("plays_t1","Regular","Play 10 rounds",1,"stat","plays",10),
        ("plays_t2","The Regular's Regular","Play 50 rounds",2,"stat","plays",50)]),
"lanes": A([("score_t1","Blooded Wings","Score 500 in one run",1,"score","",500),
        ("score_t2","Sky Reaper","Score 1500 in one run",2,"score","",1500),
        ("score_t3","Storm Born","Score 4000 in one run",3,"score","",4000),
        ("score_t4","The Sky Is Mine","Score 10000 in one run",4,"score","",10000),
        ("kills_t1","Century Hawk","Kill 60 ships in one run",1,"max","best_kills",60),
        ("kills_t2","Ace of Aces","Kill 150 ships in one run",2,"max","best_kills",150),
        ("kills_t3","Death of the Sky","Kill 300 ships in one run",3,"max","best_kills",300),
        ("kills_tot","War Economy","Kill 3000 ships total",2,"cnt","kills",3000),
        ("power_t1","Fully Armed","Max a weapon's power (20)",3,"max","max_power",20),
        ("plays_t1","Regular","Play 10 rounds",1,"stat","plays",10),
        ("plays_t2","Sky Veteran","Play 50 rounds",2,"stat","plays",50)]),
"slasher": A([("score_t1","Sharp Blade","Score 300 in one run",1,"max","max_score",300),
        ("score_t2","Juice Storm","Score 800 in one run",2,"max","max_score",800),
        ("score_t3","The Blade Saint","Score 2000 in one run",3,"max","max_score",2000),
        ("slash_t1","Juice Bar","Slash 100 fruits total",1,"cnt","slashed",100),
        ("slash_t2","Fruit Hurricane","Slash 1000 fruits total",2,"cnt","slashed",1000),
        ("slash_t3","The Orchard Falls","Slash 5000 fruits total",3,"cnt","slashed",5000),
        ("hearts_t1","Untouchable","End a run with all three hearts",2,"max","hearts_kept",3),
        ("plays_t1","Regular","Play 10 rounds",1,"stat","plays",10),
        ("plays_t2","Blade Regular","Play 60 rounds",2,"stat","plays",60)]),
"hopper": A([("tower_t1","Warming Up","Climb 30 platforms in one run",1,"max","max_tower",30),
        ("tower_t2","Above the Clouds","Climb 80 platforms in one run",2,"max","max_tower",80),
        ("tower_t3","The Stratosphere","Climb 150 platforms in one run",3,"max","max_tower",150),
        ("tower_t4","The Edge of the Sky","Climb 300 platforms in one run",4,"max","max_tower",300),
        ("hops_t1","Bunny Boots","Jump 50 times total",1,"cnt","hops",50),
        ("hops_t2","Spring Legs","Jump 500 times total",2,"cnt","hops",500),
        ("hops_t3","The Thousand Knees","Jump 5000 times total",3,"cnt","hops",5000),
        ("height_t1","Where Birds Rest","Climb 500 height in one run",1,"max","max_height",500),
        ("height_t2","Thin Air","Climb 1500 height in one run",2,"max","max_height",1500),
        ("height_t3","The Quiet Zone","Climb 3000 height in one run",3,"max","max_height",3000),
        ("plays_t1","Regular","Play 10 rounds",1,"stat","plays",10),
        ("plays_t2","The Mountain's Own","Play 60 rounds",2,"stat","plays",60)]),
"merge": A([("tile_t1","Getting Warm","Create the 256 tile",1,"max","max_tile",256),
        ("tile_t2","Halfway Hero","Create the 512 tile",2,"max","max_tile",512),
        ("tile_t3","The Cold One","Create the 1024 tile",3,"max","max_tile",1024),
        ("tile_t4","The Real 2048","Create the 2048 tile",4,"max","max_tile",2048),
        ("plays_t1","Regular","Play 10 rounds",1,"stat","plays",10),
        ("plays_t2","Doubler","Play 40 rounds",2,"stat","plays",40)]),
"dario": A([("stomp_t1","Heel of the Hero","Stomp 25 enemies total",1,"cnt","stomped",25),
        ("stomp_t2","Boot Camp","Stomp 100 enemies total",2,"cnt","stomped",100),
        ("stomp_t3","The Stomp Dynasty","Stomp 400 enemies total",3,"cnt","stomped",400),
        ("witcher_t1","Witcher Slayer","Crush the Witcher",2,"max","witcher",1),
        ("clear_t1","The Escape That Wasn't","Clear all ten levels in one run",3,"max","levels_done",10),
        ("score_t1","Curse Runner","Score 2000 in one run",2,"max","max_score",2000),
        ("score_t2","The Curse Breaker","Score 6000 in one run",3,"max","max_score",6000),
        ("plays_t1","Regular","Play 10 rounds",1,"stat","plays",10),
        ("plays_t2","Cursed Regular","Play 30 rounds",2,"stat","plays",30)]),
"xo": A([("wins_t1","Pencil Pusher","Win 10 rounds",1,"cnt","wins",10),
        ("wins_t2","Sketch Master","Win 40 rounds",2,"cnt","wins",40),
        ("wins_t3","The Graphite Hand","Win 120 rounds",3,"cnt","wins",120),
        ("streak_t1","Unstoppable","Win 5 rounds in a row",2,"max","streak",5),
        ("streak_t2","The Machine","Win 10 rounds in a row",3,"max","streak",10),
        ("plays_t1","Doodler","Play 15 rounds",1,"stat","plays",15),
        ("plays_t2","The Page's Owner","Play 60 rounds",2,"stat","plays",60)]),
"matcher": A([("match_t1","Gem Fresh","Match 300 gems total",1,"cnt","matched",300),
        ("match_t2","Gem Hoard","Match 3000 gems total",2,"cnt","matched",3000),
        ("match_t3","The Gem Sea","Match 15000 gems total",3,"cnt","matched",15000),
        ("cascade_t1","Sweet Tooth","Chain a x4 cascade",2,"max","best_cascade",4),
        ("cascade_t2","The Long Chain","Chain a x6 cascade",3,"max","best_cascade",6),
        ("cascade_t3","Gravity's Friend","Chain a x8 cascade",4,"max","best_cascade",8),
        ("hyper_t1","Light Touch","Create a color remover",1,"cnt","hypers",1),
        ("hyper_t2","Remover's Hand","Create 10 color removers",2,"cnt","hypers",10),
        ("depth_t1","Deep Dig","Descend to 20m in one mine",1,"max","depth",20),
        ("depth_t2","The Bottom","Descend to 50m in one mine",3,"max","depth",50),
        ("butter_t1","Moth Keeper","Save 100 butterflies total",1,"cnt","butterflies",100),
        ("butter_t2","The Butterfly Friend","Save 500 butterflies total",2,"cnt","butterflies",500),
        ("ice_t1","Ice Breaker","Melt 25 ice layers total",1,"cnt","melted",25),
        ("ice_t2","The Thaw","Melt 250 ice layers total",2,"cnt","melted",250),
        ("icecrash_t1","Shattermind","Crack 300 ice-crash layers total",2,"cnt","icr_layers",300),
        ("jelly_t1","Jelly Wipe","Dissolve 500 jelly cells total",2,"cnt","jelly_cells",500),
        ("items_t1","Parcel Master","Deliver 100 parcels total",2,"cnt","items",100),
        ("plays_t1","Regular","Play 10 rounds",1,"stat","plays",10),
        ("plays_t2","Wall Regular","Play 50 rounds",2,"stat","plays",50)]),
"invaders": A([("score_t1","Solar Shield","Score 2000 in one run",1,"max","max_score",2000),
        ("score_t2","Star Breaker","Score 6000 in one run",2,"max","max_score",6000),
        ("score_t3","The System's Fist","Score 15000 in one run",3,"max","max_score",15000),
        ("kills_t1","Star Sweep","Destroy 500 enemies total",1,"cnt","kills",500),
        ("kills_t2","Void Cleaner","Destroy 2000 enemies total",2,"cnt","kills",2000),
        ("kills_t3","The Long War's Toll","Destroy 6000 enemies total",3,"cnt","kills",6000),
        ("tour_t1","The Long War","Finish the full tour",3,"cnt","tour_done",1),
        ("boss_t1","Duke Hunter","Meet all three runaway keepers",2,"cnt","bosses_met",3),
        ("defend_t1","Crew Trust","Call 3 defenders total",1,"cnt","defenders_called",3),
        ("stage_t1","Deep Patrol","Reach stage 12",2,"max","max_stage",12),
        ("stage_t2","The Far Orbit","Reach stage 24",3,"max","max_stage",24),
        ("plays_t1","Regular","Play 8 rounds",1,"stat","plays",8),
        ("plays_t2","Watch Commander","Play 40 rounds",2,"stat","plays",40)]),
"cosmic_spud": A([("kills_t1","Swatter","Defeat 500 enemies total",1,"max","kills",500),
        ("kills_t2","Swarm Thinner","Defeat 2000 enemies total",2,"max","kills",2000),
        ("kills_t3","The Swarm's End","Defeat 6000 enemies total",3,"max","kills",6000),
        ("wave_t1","Wave Rider","Reach wave 20 in one run",1,"max","cs_wave",20),
        ("wave_t2","The Storm Surfer","Reach wave 40 in one run",3,"max","cs_wave",40),
        ("score_t1","Spud Legend","Score 400 in one run",1,"max","cs_score",400),
        ("score_t2","Spud Immortal","Score 1000 in one run",2,"max","cs_score",1000),
        ("score_t3","The Golden Harvest","Score 2500 in one run",3,"max","cs_score",2500),
        ("merge_t1","Weapon Smith","Perform 5 weapon merges total",1,"cnt","cs_merge",5),
        ("merge_t2","The Forge Master","Perform 20 weapon merges total",2,"cnt","cs_merge",20),
        ("runs_t1","Drop In","Finish 10 runs",1,"cnt","cs_runs",10),
        ("runs_t2","The Veteran Spud","Finish 50 runs",2,"cnt","cs_runs",50)]),
"pop_siege": A([("pop_t1","Pop Authority","Pop 1000 bloon layers in one run",1,"max","pops_run",1000),
        ("pop_t2","The Pop Storm","Pop 10000 bloon layers in one run",2,"max","pops_run",10000),
        ("moab_t1","The Big One","Ground a blimp",2,"max","moab_kills",1),
        ("moab_t2","Blimp Season","Ground 10 blimps total",3,"max","moab_kills",10),
        ("wave_t1","Half the Siege","Reach wave 25 on any map",1,"max","wave_best",25),
        ("wave_t2","The Siege Breaker","Reach wave 50 on any map",3,"max","wave_best",50),
        ("gear_t1","Full Gear","Push a folk to gear 3",2,"max","gears3",1),
        ("plays_t1","Regular","Play 8 rounds",1,"stat","plays",8),
        ("plays_t2","The Siege Regular","Play 40 rounds",2,"stat","plays",40)]),
"geometry": A([("score_t1","Flash 100","Score 100 in one run",1,"max","max_score",100),
        ("score_t2","Speed Demon","Score 300 in one run",2,"max","max_score",300),
        ("score_t3","Neon Ghost","Score 1000 in one run",3,"max","max_score",1000),
        ("score_t4","The Matrix Runner","Score 2500 in one run",4,"max","max_score",2500),
        ("orbit_t1","Orbit Hunter","Collect 500 golden orbits total",1,"cnt","orbits",500),
        ("orbit_t2","The Orbit Lord","Collect 2500 golden orbits total",2,"cnt","orbits",2500),
        ("flip_t1","Gravity Adept","Flip gravity 250 times total",1,"cnt","flips",250),
        ("flip_t2","The World Upside Down","Flip gravity 1000 times total",2,"cnt","flips",1000),
        ("triple_t1","Triple Threat","Survive all 3 mechanics in one run",2,"cnt","triple",1),
        ("plays_t1","Regular","Play 8 rounds",1,"stat","plays",8),
        ("plays_t2","The Loop's Regular","Play 40 rounds",2,"stat","plays",40)]),
"maze": A([("maps_t1","Escape Artist","Escape 10 mazes in one run",1,"max","max_maps",10),
        ("maps_t2","Wall Reader","Escape 30 mazes in one run",2,"max","max_maps",30),
        ("maps_t3","The Cartographer","Escape 60 mazes in one run",3,"max","max_maps",60),
        ("esc_t1","Loop Breaker","Escape 100 mazes total",1,"cnt","escapes",100),
        ("esc_t2","Matrix Free","Escape 300 mazes total",2,"cnt","escapes",300),
        ("esc_t3","No Walls Hold Me","Escape 1000 mazes total",3,"cnt","escapes",1000),
        ("finder_t1","Cheater","Use the path finder 25 times",1,"cnt","finder_used",25),
        ("plays_t1","Regular","Play 8 rounds",1,"stat","plays",8),
        ("plays_t2","The Maze Walker","Play 40 rounds",2,"stat","plays",40)]),
}

# ------------------------------------------------------- block machinery
def find_block(src, gid):
    """Return (start, end) of the game's {...} span (exclusive of the outer
    braces' trailing comma line). Quote + comment aware brace scan."""
    m = re.search(r'"id": "%s"' % gid, src)
    if not m:
        sys.exit("missing game " + gid)
    # walk back to the opening '{' of this game object
    opening = src.rfind("{", 0, m.start())
    depth = 0
    i = opening
    in_str = False
    while i < len(src):
        c = src[i]
        if src.startswith("#", i) and not in_str:
            i = src.find("\n", i)
            if i < 0:
                break
            continue
        if c == '"':
            in_str = not in_str
        elif not in_str:
            if c in "{[":
                depth += 1
            elif c in "}]":
                depth -= 1
                if depth == 0:
                    return opening, i
        i += 1
    sys.exit("unterminated block " + gid)

def replace_fields(src, gid, reveal_lines, age, ach_text):
    start, end = find_block(src, gid)
    block = src[start:end + 1]
    # 1. the age
    block2, n = re.subn(r'"age": "[^"]*"', '"age": "%s"' % age, block)
    assert n == 1, gid + " age"
    block = block2
    # 2. the reveal (with its optional preceding charge_unlock line)
    if reveal_lines:
        m = re.search(r'"reveal": \{', block)
        assert m, gid + " reveal"
        # consume the whole reveal dict (brace scan)
        d = 0
        j = m.start() + len('"reveal": ')
        while True:
            if block[j] == "{":
                d += 1
            elif block[j] == "}":
                d -= 1
                if d == 0:
                    break
            j += 1
        reveal_txt = "\n".join(reveal_lines).strip()
        while reveal_txt.endswith(","):
            reveal_txt = reveal_txt[:-1]
        # consume an immediately-preceding charge_unlock line if the new
        # text carries one (they arrive together)
        pre = block[:m.start()]
        if reveal_txt.startswith('"charge_unlock"'):
            pre = re.sub(r'\s*"charge_unlock": \d+,\n', "\n", pre)
        block = pre + reveal_txt + block[j + 1:]
    else:
        # an old charge_unlock line may still sit alone (snake has none)
        block = re.sub(r'\s*"charge_unlock": \d+,\n', "\n", block)
    # 3. the ach array: from '"ach": [' to the line '],' at its level
    m2 = re.search(r'"ach": \[', block)
    assert m2, gid + " ach"
    d = 0
    j = m2.start() + len('"ach": ')
    in_str = False
    while j < len(block):
        c = block[j]
        if c == '"':
            in_str = not in_str
        elif not in_str:
            if c == "[":
                d += 1
            elif c == "]":
                d -= 1
                if d == 0:
                    break
        j += 1
    ach_text = ach_text.strip()
    while ach_text.endswith(","):
        ach_text = ach_text[:-1]
    block = block[:m2.start()] + ach_text + block[j + 1:]
    return src[:start] + block + src[end + 1:]

# retire the OLD standalone charge_unlock lines (matcher 100 / keys 200)
src = re.sub(r'\s*"charge_unlock": \d+,\n(?=\s*"reveal")', "\n", src)

for gid in AGES:
    src = replace_fields(src, gid, REVEALS.get(gid, []), AGES[gid], ACH[gid])

# ------------------------------------------------- retire Key Singer (20)
ks_start, ks_end = find_block(src, "keys")
# the block span covers {...}; the entry also owns a trailing comma + newline
after = src[ks_end + 1:]
after = re.sub(r'^\s*,\s*\n', "", after.lstrip("\n"), count=1) \
        if after.lstrip().startswith(",") else after
src = src[:ks_start] + after.lstrip("\n")

# ------------------------------------------------- park the 5 SOON titles
SOON = '''        {"id": "domino", "title": "DOMINO", "tag": "the tile classic", "coming_soon": true,
            "orientation": "auto", "dim": "2d",
            "price": 500, "fee": 10,
            "reveal": {"kind": "direct", "appear_after": 7, "needs_games": 8},
            "desc": "the tile classic: match the ends, empty your hand first - the workshop version is baking",
            "age": "3"},
        {"id": "chess", "title": "CHECKMATE", "tag": "the old war", "coming_soon": true,
            "orientation": "auto", "dim": "2d",
            "price": 700, "fee": 10,
            "reveal": {"kind": "direct", "appear_after": 8, "needs_games": 9},
            "desc": "the old war on a sketch board - the workshop version is baking",
            "age": "3"},
        {"id": "fourline", "title": "FOUR IN LINE", "tag": "drop and connect", "coming_soon": true,
            "orientation": "auto", "dim": "2d",
            "price": 450, "fee": 8,
            "reveal": {"kind": "direct", "appear_after": 9, "needs_games": 10},
            "desc": "drop the discs, make four - the workshop version is baking",
            "age": "3"},
        {"id": "bovo", "title": "FIVE LINES", "tag": "five in a row", "coming_soon": true,
            "orientation": "auto", "dim": "2d",
            "price": 450, "fee": 8,
            "reveal": {"kind": "direct", "appear_after": 10, "needs_games": 11},
            "desc": "five in a row on an endless sketch grid - the workshop version is baking",
            "age": "3"},
        {"id": "dots", "title": "DOTS", "tag": "close the boxes", "coming_soon": true,
            "orientation": "auto", "dim": "2d",
            "price": 450, "fee": 8,
            "reveal": {"kind": "direct", "appear_after": 11, "needs_games": 12},
            "desc": "draw lines between dots, close boxes, take the board - the workshop version is baking",
            "age": "3"},
'''
arr_open = src.find("const GAMES := [")
close = src.rfind("\n]")
src = src[:close] + SOON + src[close:]

open(P, "w").write(src)
print("registry transformed v2")
