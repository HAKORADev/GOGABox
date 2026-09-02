extends GogaGame
## CURSED DARIO - v0.3.1 PATCH II (the owner's playtest round).
##
## THE LORE: Dario fell into this world through a Witcher's curse. Ten
## levels to the end line, and the last mission is the Witcher herself:
## crush her head ~20 times while she hurls curses. Win and Dario runs
## for the open ground... and a shot comes from behind. He never escaped.
## Every replay the dialogue shifts - deja vu, the trees repeat, he is
## living in a dream. Cursed forever.
##
## WHAT THIS PATCH ROUND FIXES (every owner word kept):
##   - THE SHOP OVERLAY: closing the shop left the DIM alive (the sheet
##     owns a dim+center PAIR - dario freed only the center). The merge
##     PAIR LAW is now the law here too: capture the pair, drop the pair.
##     A purchase re-opens the sheet EXACTLY ONCE (the old on_buy tail
##     stacked copies of the sheet = "a weird overlay").
##   - THE NIGHT THEME TOGGLE: an owned night sky now has a WEAR THE
##     NIGHT / WEAR THE DAY switch right in its shop row
##     (Box.unequip_item clears the theme).
##   - THE CONTROLS: TouchKit tracks ONE press - holding the left thumb
##     and tapping the right thumb REPLACED it, so walking died on the
##     first jump. Dario now tracks touches BY INDEX (raw ScreenTouch):
##     the first left-half touch owns walking (an analog drag anchor),
##     ANY right-half press edge jumps. True snowy-tower two thumbs.
##   - THE SCORE TABLE: the weakest snail no longer pays +10. Every kind
##     pays its tier: snail 5, fly 10, spitter 15, blocker 20, spiky 25,
##     the Witcher 100.
##   - THE DIALOGUE: the game now OPENS with a real dialogue box - a
##     square, scrollable (up-down) telling of the story with a DONE
##     button (the cursed replays get the deja-vu variant). The story
##     pop-ups are BUBBLES over DARIO'S HEAD (white background, black
##     text) that follow him - never a floating top-center strip again.
##   - THE COINS: no free-floating coins anywhere. GOGACoins live INSIDE
##     the ? crates (max 5 a level) and POP OUT when the crate is bumped.
##   - THE WORLD: the ground is CONTINUOUS (no empty areas between the
##     blocks, no floating grass), every shelf/ghost/mover is a 2-tile
##     jump away, every ? crate is bump-reachable, and the goal trophy
##     snaps ON the ground. Level 10 is a compact arena where a ladder
##     of GHOST PLATFORMS appears and vanishes on offset cycles - the
##     hard timed climb to the Witcher's head (the owner's own design).
##   - THE ART: a complete real-asset overhaul (see docs/ASSETS.md):
##     Pixel Adventure by Pixel Frog (Pink Man, Snail, Bat, Plant, Rino,
##     the spiky Turtle with REAL spikes-in/out frames, Ghost, terrain,
##     crates, spikes, fire, falling platforms, the trophy) + the Sunny
##     Land parallax forest sky. The Witcher is the Ghost recolored
##     cursed-lavender with a baked witch hat; her bolts are purple.
##
## Probe contract: the level grid, the player AABB, the enemy list and
## _stomp/_hurt/_load_level drive the laws headless; the maps are consts.

const TILE := 80
const GRAVITY := 2900.0
const JUMP_V := -1180.0
const WALK_V := 470.0
const START_LIVES := 3
const DEATH_COST := 200
const BOSS_HP := 20
const BOSS_SCORE := 100

## the enemy score table (the owner: "why the weakest gave me 10?")
const ENEMY_SCORE := {
        "snail": 5, "fly": 10, "spitter": 15, "blocker": 20, "spiky": 25,
}

const POWER_PRICE := {"foot": 1000, "shield": 1200, "jump": 1000}
const THEME_NIGHT_PRICE := 800

## THE STORY (first playthrough)
const STORY_START := {
        1: "DARIO: ...where am I? The sky is wrong. The last thing I remember is her laugh.",
        2: "DARIO: The woods repeat. I passed that bush an hour ago... or was it a dream?",
        3: "DARIO: There are her marks on the trees. She WANTS me to keep walking.",
        4: "DARIO: These floating stones... nothing here obeys the world I know.",
        5: "DARIO: I hear her humming. It comes from everywhere at once.",
        6: "DARIO: The ground burned me. The ground. This world is rigged against me.",
        7: "DARIO: My footprints from yesterday... they are still there. Fresh.",
        8: "DARIO: I know what hides behind every block already. How do I know that?",
        9: "DARIO: The exit door looks like my front door. I never had a front door.",
        10: "DARIO: There she is. The end line. Whatever it takes.",
}
const STORY_END := {
        1: "DARIO: A trophy in the middle of a forest. Fine. I collect trophies.",
        2: "DARIO: The same trophy. The SAME trophy again.",
        3: "DARIO: Did the forest just... rearrange itself behind me?",
        4: "DARIO: I am not sure I am walking FORWARD anymore.",
        5: "DARIO: Her humming again. Closer. She is HERDING me.",
        6: "DARIO: The burns heal the moment I look away. Of course they do.",
        7: "DARIO: I counted my steps. The number was the same as yesterday.",
        8: "DARIO: I dreamed this level. I dreamed it and it listened.",
        9: "DARIO: One more trophy. She is behind one more trophy.",
        10: "DARIO: For every curse she cast on me - ten stomps. Minimum.",
}
## THE CURSED REPLAYS (from the second playthrough on - deja vu, the dream)
const CURSED_START := [
        "DARIO: Back here. Again. The grass did not even grow back.",
        "DARIO: I know where every enemy stands. I have ALWAYS known.",
        "DARIO: Am I walking, or is the world scrolling under me?",
        "DARIO: Her curse did not just trap me. It REHEARSES me.",
        "DARIO: The bush again. Hello, bush. We meet again, bush.",
        "DARIO: I said my lines before I thought them. That is new. That is bad.",
        "DARIO: Deja vu is just the curse checking my homework.",
        "DARIO: Maybe I never left level one. Maybe level one left me.",
]
const CURSED_END := [
        "DARIO: Another trophy. Another chapter of the same bad dream.",
        "DARIO: The trophies chime the same note. Every time. Every run.",
        "DARIO: One day I will grab this trophy and stay on THIS side. Maybe.",
        "DARIO: The exit smells like the entrance. Funny world. Cursed world.",
        "DARIO: If this is a dream, whose dream is it? ...Hers?",
]
## THE INTRO DIALOGUE BOX (the owner: "a dialogue box when the game
## starts - an up-down scrollable square with the story and a DONE
## button"). First telling vs the cursed replays.
const INTRO_FIRST := "DARIO fell walking home under a green sky.\n\nThe last thing he saw was HER - the Witcher on the hill, smiling, one hand raised. The world folded like wet paper.\n\nHe woke under a wrong sky, in woods that repeat, with ten doors between him and home.\n\nStomp what crawls. Bump the ? crates - a GOGACoin, or a gift for those who bought one. Grab every trophy.\n\nBehind the tenth door SHE waits. Crush her head, again and again, until the curse breaks.\n\nThen run for the open ground. And do not look back."
const INTRO_CURSED := "You have read this before.\n\nThe words did not change. Maybe you did. The sky is wrong again - was it ever right?\n\nTen doors. You counted them yesterday. You will count them tomorrow.\n\nStomp what crawls. Bump the crates you already know. Climb the platforms that will not stay.\n\nShe is still waiting. She always is.\n\n(DONE)"
const WITCHER_LINE := "THE WITCHER: YOU WILL NEVER LEAVE, LITTLE HERO. YOU NEVER DID."
const ENDING_LINE := "DARIO: The open ground! I made it! I made it out of-"
const ENDING_SHOT := "...a shot rings out from behind. The Witcher smiles.\nDario never left. Dario will never leave."

# the enemy defs (boxes sized to the real Pixel Adventure art)
const E_DEFS := {
        "snail": {"hp": 1, "speed": 90.0, "w": 66.0, "h": 44.0},
        "fly": {"hp": 1, "speed": 130.0, "w": 84.0, "h": 55.0, "fly": true},
        "spitter": {"hp": 2, "speed": 0.0, "w": 74.0, "h": 70.0, "shoot": true},
        "blocker": {"hp": 3, "speed": 60.0, "w": 94.0, "h": 61.0},
        "spiky": {"hp": 1, "speed": 80.0, "w": 80.0, "h": 47.0, "spiky": true},
}

# ============================================================ level data
## tile chars: # ground | B brick | ? crate | g ghost platform (2 wide,
## appears and vanishes) | m mover | ~ fire | ^ spikes | D goal trophy |
## d start | T brazier (deco) | s snail | f fly | b blocker | p spitter |
## h spiky | W witcher.  THE GROUND IS CONTINUOUS - the owner killed the
## pits ("empty areas between the blocks"). Coins exist ONLY inside ?s.
const LEVELS := [
        [
                "..............................................................................................................................",
                "..............................................................................................................................",
                "..............................................................................................................................",
                "..............................................................................................................................",
                "..............................................................................................................................",
                "..............................................................................................................................",
                ".......................................................................?......................................................",
                "........................................B?B?B...........................................................B?B...................",
                "..............................................................................................................................",
                "..................................s...................................BB........s.............................................",
                "..d...................................................T...........................................T.....................D.....",
                "##############################################################################################################################",
        ],
        [
                "......................................................................................................................................",
                "......................................................................................................................................",
                "......................................................................................................................................",
                "......................................................................................................................................",
                "......................................................................................................................................",
                "...........................................................?....................................................?.....................",
                "............................................f...............................................f.........................................",
                "........................B?B...................................................B?B?B...................................................",
                "......................................................................................................................................",
                "..............................s...........................BBBBs.........................................s.......BB....................",
                "..d...............................................^^....................................T.......................................D.....",
                "######################################################################################################################################",
        ],
        [
                "........................................................................................................................................",
                "........................................................................................................................................",
                "........................................................................................................................................",
                "........................................................................................................................................",
                "........................................................................................................................................",
                "........................................................................................f...............................................",
                "......................................f.............................................?...................................................",
                "....................B?B?B...........................................B?................................................B?B...............",
                "........................................................................................................................................",
                "............................s..........................m............BB..............BB..........s.......................................",
                "..d.................................................^^^^......................T.............................T.....................D.....",
                "########################################################################################################################################",
        ],
        [
                "............................................................................................................................................",
                "............................................................................................................................................",
                "............................................................................................................................................",
                "............................................................................................................................................",
                "............................................................................................................................................",
                "......................................................................f........?..............................f...............?.............",
                "............................................................................................................................................",
                "..................................B?B...........................................................B?B?B.......................................",
                "............................................................................................................................................",
                "..........................s...................p...........s...................BBBB..................p.........................BB............",
                "..d.............................................................~~~.......................T...............................^^^.........D.....",
                "############################################################################################################################################",
        ],
        [
                "............................................................................................................................................",
                "............................................................................................................................................",
                "............................................................................................................................................",
                "............................................................................................................................................",
                "............................................................................................................................................",
                "............................................................f?............................?.....................f...........................",
                "............................................................................................................................................",
                "..............................B?B.......................................................................B?B?B...............................",
                "............................................................................................................................................",
                "........................s...................................BBBB..........b...............BB..........................p.....................",
                "..d.....................................~~..........^^..............................~~~~............T.................................D.....",
                "############################################################################################################################################",
        ],
        [
                "................................................................................................................................................",
                "................................................................................................................................................",
                "................................................................................................................................................",
                "................................................................................................................................................",
                "................................................................................................................................................",
                "........................................f........................?..........................................f....?..............................",
                "................................................................................................................................................",
                "............................B?B.......................................................B?B...........................................B?B.........",
                "................................................................................................................................................",
                "......................s.................................h.......BBBB..........b.............h...................BBBB......p.....................",
                "..d.........................................................^^^.................~~..................T.........................~~~~........D.....",
                "################################################################################################################################################",
        ],
        [
                "..............................................................................................................................................",
                "..............................................................................................................................................",
                "..............................................................................................................................................",
                "..............................................................................................................................................",
                "..............................................................................................................................................",
                "..................................................f..........................?..........................f.....................................",
                ".....................................................................................................?........................................",
                "........................B?B?B.................................................................................................B?B.............",
                "..............................................................................................................................................",
                "..............................h.........m.........................p.........BBBB........h...........g.........................................",
                "..d...................................................^^........................................~~~.................T...................D.....",
                "##############################################################################################################################################",
        ],
        [
                "......................................................................................................................................................",
                "......................................................................................................................................................",
                "......................................................................................................................................................",
                "......................................................................................................................................................",
                "......................................................................................................................................................",
                "....................................f............?................................f.......................................f...........................",
                "........................................................................?..................................................?..........................",
                "..........................B?B.........................................................................B?B?B...........................................",
                "......................................................................................................................................................",
                "....................s...........................BBBB........h...........BB..............m.......b.........................g...p.......................",
                "..d.........................................^^......................~~~.............................................~~~~................T.......D.....",
                "######################################################################################################################################################",
        ],
        [
                "..........................................................................................................................................................",
                "..........................................................................................................................................................",
                "..........................................................................................................................................................",
                "..........................................................................................................................................................",
                "....................................................................................................f.....................................................",
                "..............................f...................................f......................?................................................................",
                "......................................?....................................................................................?..............................",
                "......................B?B.....................................B?B?B...............................................................................B?B.....",
                "..........................................................................................................................................................",
                "..................s.................g.......h...........m.................b.............BBBB..............h...............g.........p.....................",
                "..d.................................................^^^^............................~~~~~.............................^^^...................T.........D...",
                "##########################################################################################################################################################",
        ],
        [
                "..................................",
                "..................................",
                "..................................",
                "..................................",
                "..................................",
                "................g.................",
                "................W.................",
                "...........g......................",
                "..................................",
                "......g...........................",
                "..d.....T.................T...D...",
                "##################################",
        ],
]

# ============================================================ state
var lives := START_LIVES
var level_i := 0
var grid: Array = []               # grid[row][col] = the tile char (solids)
var cols := 0
var rows := 12
var items: Array = []              # crates/goal entities {kind, node, cell...}
var enemies: Array = []
var movers: Array = []             # moving platforms {node, a, t, amp, last}
var burners: Array = []            # fire pillars {node, cell, heat, fx}
var ghosts: Array = []             # ghost platforms {node, cell, phase, on}
var bolts: Array = []              # the projectiles
var coins_taken := 0
var boxes_used := 0

# the player
var p_node: Node2D
var p_pos := Vector2.ZERO
var p_vel := Vector2.ZERO
var p_size := Vector2(56, 74)
var on_floor := false
var face := 1
var walk_t := 0.0
var power_foot := false
var power_shield := false
var power_jump := false
var _hurt_flash := 0.0

# the boss
var boss: Dictionary = {}
var boss_hp := BOSS_HP

# scene
var world: Node2D
var cam := Vector2.ZERO
var tile_root: Node2D
var ent_root: Node2D
var fx_root: Node2D
var bg_far: Sprite2D
var bg_mid: Sprite2D
var sky_ctl: Control          # screen-space sky: gradient, sun/moon, stars
var hearts_row: HBoxContainer
var heart_icons: Array = []
var lvl_lbl: Label
var _time := 0.0
var _rng := RandomNumberGenerator.new()
var _phase := "play"               # play | door | ending | over
var _door_t := 0.0
var _end_t := 0.0
var _pop_t := 0.0
var _locked := false
var _stars: Array = []

# the shop sheet PAIR (THE PAIR LAW - the sheet owns its dim+center pair;
# freeing only the center left the dim eating every tap - the overlay bug)
var _shop_pair: Array = []
# the intro dialogue pair (same law)
var _intro_pair: Array = []

# ============================================================ setup

var _jump_queued := false

func _goga_setup() -> void:
        _rng.randomize()
        pause_end_run = false
        Box.bump_counter(game_id, "playthroughs", 1)   # the cursed replays
        set_hud_score_prefix("SCORE")
        _build_shop_button()
        _build_hearts()
        lvl_lbl = add_hud_chip("L1")
        _build_sky()
        _next_level(true)
        _intro_open()
        Jukebox.music("res://assets/audio/music/pong_theme.wav")

func _build_shop_button() -> void:
        add_hud_button("SHOP", func(): _shop_open())

func _build_hearts() -> void:
        hearts_row = HBoxContainer.new()
        hearts_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
        hearts_row.offset_left = 14
        hearts_row.offset_top = 86
        hearts_row.offset_right = -14
        hearts_row.add_theme_constant_override("separation", 6)
        _hud.add_child(hearts_row)
        for i in START_LIVES:
                var h := TextureRect.new()
                h.texture = load("res://assets/ui/heart.png")
                h.custom_minimum_size = Vector2(40, 40)
                h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                h.mouse_filter = Control.MOUSE_FILTER_IGNORE
                hearts_row.add_child(h)
                heart_icons.append(h)
        _refresh_hearts()

func _refresh_hearts() -> void:
        for i in heart_icons.size():
                var h: TextureRect = heart_icons[i]
                h.modulate = Color(0.95, 0.2, 0.25) if i < lives \
                                else Color(0.16, 0.12, 0.12, 0.6)

# ============================================================ the shop
## THE PAIR LAW (stolen from merge2048, the game that never had this
## bug): Arc.sheet adds a dim + a center to the overlay root. The pair
## is captured at open and BOTH are dropped at close. A buy rebuilds the
## sheet exactly ONCE. No orphan dims, no stacked sheets.

func _pair_capture(root: Control) -> Array:
        var kids := root.get_children()
        return [kids[kids.size() - 2], kids[kids.size() - 1]]

func _pair_down(pair: Array) -> void:
        for c in pair:
                if c != null and is_instance_valid(c):
                        c.queue_free()

func _shop_open() -> void:
        _pair_down(_shop_pair)
        _shop_pair = []
        var root := _overlay_root_ref()
        var sheet := Arc.sheet(root, 0.0)
        sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
        _shop_pair = _pair_capture(root)
        var t := Arc.label("CURSED DARIO SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.5, 280.0, 620.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        # the NIGHT THEME row: buy it, then WEAR it or TAKE it OFF - the
        # owner: "the night theme exists but no button to switch between
        # themes which is weird?"
        var night := Box.item_owned(game_id, "theme", "night")
        var night_on := Box.item_on(game_id, "theme") == "night"
        if night:
                box.add_child(_theme_toggle(night_on))
        else:
                box.add_child(_row("THE NIGHT THEME",
                                "a darker sky, a moon, cold stars over the forest",
                                THEME_NIGHT_PRICE, "theme", "night",
                                func():
                                        Box.equip_item(game_id, "theme", "night")
                                        _apply_theme()))
        for pid in ["foot", "shield", "jump"]:
                var on := Box.item_owned(game_id, "power", pid)
                var pdesc: String = {
                        "foot": "STRONG FOOT - stomps do DOUBLE damage (per level or death)",
                        "shield": "SHIELD - absorbs one hit or shot, never a fall",
                        "jump": "POWER JUMP - jumps twice as high (per level or death)",
                }[pid]
                box.add_child(_row({"foot": "STRONG FOOT", "shield": "THE SHIELD",
                        "jump": "POWER JUMP"}[pid], pdesc,
                        int(POWER_PRICE[pid]), "power", pid, Callable()))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func():
                                _pair_down(_shop_pair)
                                _shop_pair = []))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _theme_toggle(night_on: bool) -> Control:
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 2)
        var head := Arc.label("THE NIGHT THEME (OWNED) - the sky you wear", 19,
                        Color("58c470"), false)
        head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        head.custom_minimum_size = Vector2(560, 0)
        head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        v.add_child(head)
        var b := Arc.button("WEAR THE DAY" if night_on else "WEAR THE NIGHT",
                        Vector2(560, 56), 22, Color("4a5ab8"), func():
                                if night_on:
                                        Box.unequip_item(game_id, "theme")
                                else:
                                        Box.equip_item(game_id, "theme", "night")
                                _apply_theme()
                                _shop_open())
        v.add_child(b)
        return v

func _row(title: String, desc: String, price: int, cat: String,
                item: String, on_buy: Callable) -> Control:
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 2)
        var owned := Box.item_owned(game_id, cat, item)
        var head := Arc.label("%s%s - %s" % [title, "  (OWNED)" if owned else "",
                        desc], 19,
                        Color("58c470") if owned else Arc.INK, false)
        head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        head.custom_minimum_size = Vector2(560, 0)
        head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        v.add_child(head)
        if owned:
                return v
        var b := Arc.coin_button("BUY  %d" % price, Vector2(560, 56), 22,
                        Color("4a5ab8"), func():
                                if Box.buy_item(game_id, cat, item, price):
                                        Jukebox.sfx("buy")
                                        if on_buy.is_valid():
                                                on_buy.call()
                                _shop_open())          # ONE rebuild - never a stack
        if Box.coins() < price:
                b.disabled = true
        v.add_child(b)
        return v

# ============================================================ the intro
## the scrollable story square with the DONE button (the owner's spec)

func _intro_open() -> void:
        _pair_down(_intro_pair)
        _intro_pair = []
        _locked = true
        var root := _overlay_root_ref()
        var sheet := Arc.sheet(root, 0.0)
        sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
        _intro_pair = _pair_capture(root)
        var cursed := Box.counter(game_id, "playthroughs") >= 2
        var t := Arc.label("THE CURSE", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.42, 240.0, 480.0))
        var story := Arc.label(INTRO_CURSED if cursed else INTRO_FIRST, 21,
                        Arc.INK, false)
        story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        story.custom_minimum_size = Vector2(540, 0)
        story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(story)
        sheet.add_child(sc)
        var done := Arc.button("DONE", Vector2(560, 78), 28, Arc.GOOD, func():
                _pair_down(_intro_pair)
                _intro_pair = []
                _locked = false)
        sheet.add_child(done)
        for b in Arc._buttons_in(sc):
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

# ============================================================ the level

func _next_level(first := false) -> void:
        _load_level(level_i)
        if not first:
                _story_pop(_story_line(true))
        # the start line: first-play script, the cursed pool on replays
        # (level 1 of a fresh run is told by the INTRO BOX instead)
        var plays := Box.counter(game_id, "playthroughs")
        var line: String
        if plays >= 2:
                line = String(CURSED_START[(level_i + plays) % CURSED_START.size()])
        else:
                line = String(STORY_START.get(mini(level_i + 1, 10), ""))
        if not (first and plays < 2):
                _story_pop(line)
        if level_i == 9:
                _story_pop(WITCHER_LINE)
        lvl_lbl.text = "L%d" % (level_i + 1)

func _load_level(idx: int) -> void:
        if world != null and is_instance_valid(world):
                world.queue_free()
        items = []
        enemies = []
        movers = []
        burners = []
        ghosts = []
        bolts = []
        boss = {}
        coins_taken = 0
        boxes_used = 0
        power_foot = false
        power_jump = false
        _phase = "play"
        _locked = false
        _bubble_down()
        world = Node2D.new()
        world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # pixel art stays crisp
        add_child(world)
        world.position.y = banner_bottom()
        var map: Array = LEVELS[mini(idx, LEVELS.size() - 1)]
        rows = map.size()
        cols = String(map[0]).length()
        grid = []
        _build_parallax(rows * TILE)
        tile_root = Node2D.new()
        world.add_child(tile_root)
        ent_root = Node2D.new()
        ent_root.z_index = 4
        world.add_child(ent_root)
        fx_root = Node2D.new()
        fx_root.z_index = 8
        fx_root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # text stays smooth
        world.add_child(fx_root)
        var loot_i := 0
        # per level the coin crates: max 5, then the rest are empty
        var coin_boxes_left := 5
        var power_owned := []
        for pid in ["foot", "shield", "jump"]:
                if Box.item_owned(game_id, "power", pid):
                        power_owned.append(pid)
        var loot_cycle := ["coin", "coin", "none", "coin", "power", "coin",
                "none", "coin", "power", "none"]
        for r in rows:
                var row := []
                for c in cols:
                        var ch := String(map[r])[c]
                        var cell := Vector2i(c, r)
                        match ch:
                                "#":
                                        row.append("#")
                                "B":
                                        row.append("B")
                                        _tile("tile_brick.png", cell)
                                "?":
                                        row.append("?")
                                        var loot: String = loot_cycle[loot_i % loot_cycle.size()]
                                        loot_i += 1
                                        if loot == "coin":
                                                if coin_boxes_left <= 0:
                                                        loot = "none"
                                                else:
                                                        coin_boxes_left -= 1
                                        if loot == "power" and power_owned.is_empty():
                                                loot = "none"
                                        items.append({"kind": "box", "cell": cell,
                                                "loot": loot, "used": false})
                                        _tile("tile_box.png" if loot != "none" else
                                                "tile_box_empty.png", cell)
                                "g":
                                        row.append(".")
                                        _spawn_ghost(cell)
                                "D":
                                        row.append(".")
                                        items.append({"kind": "goal", "cell": cell})
                                "T":
                                        row.append(".")
                                        _brazier(cell)
                                "d":
                                        row.append(".")
                                        p_pos = Vector2(c * TILE + TILE / 2.0,
                                                        r * TILE + TILE / 2.0)
                                "W":
                                        row.append(".")
                                        _start_boss(cell)
                                "s":
                                        row.append(".")
                                        _spawn_enemy("snail", cell)
                                "f":
                                        row.append(".")
                                        _spawn_enemy("fly", cell)
                                "b":
                                        row.append(".")
                                        _spawn_enemy("blocker", cell)
                                "p":
                                        row.append(".")
                                        _spawn_enemy("spitter", cell)
                                "h":
                                        row.append(".")
                                        _spawn_enemy("spiky", cell)
                                "m":
                                        row.append(".")
                                        _spawn_mover(cell)
                                "~":
                                        row.append(".")
                                        _spawn_fire(cell)
                                "^":
                                        row.append(".")
                                        _tile("tile_spikes.png", cell)
                                _:
                                        row.append(".")
                grid.append(row)
        # THE TERRAIN PASS: the ground is one connected body - grass tops on
        # every surface cell (with edge caps at the ends of a segment), dirt
        # below. The goal snaps ON the ground. The owner: "why the ground has
        # empty areas between the blocks, weird!" - never again.
        for r in rows:
                for c in cols:
                        if String(grid[r][c]) != "#":
                                continue
                        var above := r == 0 or String(grid[r - 1][c]) != "#"
                        if above:
                                var left := c == 0 or String(grid[r][c - 1]) != "#"
                                var right := c == cols - 1 or String(grid[r][c + 1]) != "#"
                                var nm := "tile_grass.png"
                                if left and not right:
                                        nm = "tile_grass_l.png"
                                elif right and not left:
                                        nm = "tile_grass_r.png"
                                _tile(nm, Vector2i(c, r))
                        else:
                                _tile("tile_dirt.png", Vector2i(c, r))
        for it in items.duplicate():
                if String(it["kind"]) == "goal":
                        var gcol: int = it["cell"]["x"]
                        var grow := rows - 1
                        while grow > 0 and String(grid[grow][gcol]) != "#":
                                grow -= 1
                        it["cell"] = Vector2i(gcol, grow - 1)   # one above the ground
                        var goal := Sprite2D.new()
                        goal.texture = load("res://assets/games/dario/tile_goal.png")
                        goal.position = _cell_center(it["cell"]) + Vector2(0, 12.0)
                        tile_root.add_child(goal)
                        it["node"] = goal
        # THE GROUND SNAP: drop every ground dweller onto the first floor
        # under its marked cell
        for e in enemies:
                var dd: Dictionary = E_DEFS[String(e["kind"])]
                if bool(dd.get("fly", false)):
                        continue
                var n2: Node2D = e["node"]
                var r2 := clampi(int(n2.position.y / TILE), 0, rows - 1)
                while r2 < rows - 1 and not _solid_at(n2.position.x, (r2 + 1) * TILE):
                        r2 += 1
                n2.position.y = (r2 + 1) * TILE - float(dd["h"]) / 2.0 - 2.0
                e["base_y"] = n2.position.y
        # the spitters sit ON the ground (their pot is their body)
        # the player (reborn fresh)
        if p_node != null and is_instance_valid(p_node):
                p_node.queue_free()
        p_node = Node2D.new()
        p_node.position = p_pos
        var pspr := Sprite2D.new()
        pspr.texture = load("res://assets/games/dario/hero_stand.png")
        pspr.scale = Vector2.ONE * 0.85
        p_node.add_child(pspr)
        ent_root.add_child(p_node)
        p_vel = Vector2.ZERO
        power_foot = false
        power_jump = false
        power_shield = false
        _apply_theme()

func _tile(name_: String, cell: Vector2i) -> void:
        var s := Sprite2D.new()
        s.texture = load("res://assets/games/dario/" + name_)
        s.position = _cell_center(cell)
        tile_root.add_child(s)

func _cell_center(c: Vector2i) -> Vector2:
        return Vector2(c.x * TILE + TILE / 2.0, c.y * TILE + TILE / 2.0)

func _spawn_enemy(kind: String, cell: Vector2i) -> void:
        var d: Dictionary = E_DEFS[kind]
        var node := Node2D.new()
        node.position = _cell_center(cell)
        var spr := Sprite2D.new()
        var texname := "enemy_snail1.png"
        match kind:
                "fly":
                        texname = "enemy_fly1.png"
                "snail":
                        texname = "enemy_snail1.png"
                "blocker":
                        texname = "enemy_blocker1.png"
                "spitter":
                        texname = "enemy_spitter1.png"
                "spiky":
                        texname = "enemy_spiky1.png"
        spr.texture = load("res://assets/games/dario/" + texname)
        spr.scale = Vector2.ONE * float(d["w"]) / float(spr.texture.get_width())
        node.add_child(spr)
        ent_root.add_child(node)
        enemies.append({
                "kind": kind, "node": node, "hp": int(d["hp"]),
                "max_hp": int(d["hp"]),
                "v": Vector2(float(d["speed"]), 0),
                "w": float(d["w"]), "h": float(d["h"]),
                "fly": bool(d.get("fly", false)),
                "spiky": bool(d.get("spiky", false)),
                "spike_up": false, "spike_t": _rng.randf_range(0.0, 1.0),
                "shoot_t": _rng.randf_range(1.0, 2.5),
                "anim_t": _rng.randf_range(0.0, 1.0),
                "base_y": node.position.y,
                "squash": 0.0, "dead": false,
        })

func _spawn_mover(cell: Vector2i) -> void:
        var node := Node2D.new()
        node.position = _cell_center(cell)
        var pl := Sprite2D.new()
        pl.texture = load("res://assets/games/dario/mover_plank.png")
        node.add_child(pl)
        ent_root.add_child(node)
        movers.append({"node": node, "t": _rng.randf_range(0.0, TAU),
                "a": node.position, "amp": TILE * 2.6, "spd": 1.1,
                "last": node.position.x})

func _spawn_fire(cell: Vector2i) -> void:
        var node := Node2D.new()
        # the pillar stands ON the floor of its cell
        node.position = Vector2(cell.x * TILE + TILE / 2.0,
                        (cell.y + 1) * TILE)
        var fx := Sprite2D.new()
        fx.texture = load("res://assets/games/dario/fire1.png")
        fx.position = Vector2(0, -80.0)     # 160 tall art, sunk into the floor
        node.add_child(fx)
        ent_root.add_child(node)
        burners.append({"node": node, "fx": fx, "cell": cell, "heat": 0.0})

func _brazier(cell: Vector2i) -> void:
        var node := Node2D.new()
        node.position = Vector2(cell.x * TILE + TILE / 2.0,
                        (cell.y + 1) * TILE)
        var fx := Sprite2D.new()
        fx.texture = load("res://assets/games/dario/fire1.png")
        fx.scale = Vector2.ONE * 0.62        # the deco flame, smaller
        fx.position = Vector2(0, -52.0)
        node.add_child(fx)
        tile_root.add_child(node)            # deco only - never hurts

func _spawn_ghost(cell: Vector2i) -> void:
        var node := Node2D.new()
        node.position = _cell_center(cell)
        var spr := Sprite2D.new()
        spr.texture = load("res://assets/games/dario/plat_on.png")
        node.add_child(spr)
        ent_root.add_child(node)
        # offset cycles: "appearing in different times and vanish" - the
        # owner's timed climb design. 2.1s solid, 1.5s gone.
        ghosts.append({"node": node, "spr": spr, "cell": cell,
                "phase": float(cell.x) * 1.15 + float(cell.y) * 0.7,
                "on": true, "cyc": 0.0})

# ============================================================ the sky
## the sky is SCREEN-SPACE (a CanvasLayer under the HUD) - the old
## world-space sky scrolled away with the camera. The parallax forest
## lives in the world and advances slower than the camera.

var _sky_cl: CanvasLayer
var _sky_rect: ColorRect
var _moon_tex: TextureRect
var _sun_moon: Control
var _sky_day := Color("a8d8e8")   # sampled from the forest art itself

func _build_sky() -> void:
        _sky_cl = CanvasLayer.new()
        _sky_cl.layer = -10
        add_child(_sky_cl)
        _sky_rect = ColorRect.new()
        _sky_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
        _sky_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _sky_cl.add_child(_sky_rect)
        _sun_moon = Control.new()
        _sun_moon.set_anchors_preset(Control.PRESET_FULL_RECT)
        _sun_moon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _sun_moon.draw.connect(_paint_sun_moon)
        _sky_cl.add_child(_sun_moon)
        _moon_tex = TextureRect.new()
        _moon_tex.texture = load("res://assets/games/dario/deco_moon.png")
        _moon_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _moon_tex.visible = false
        _sky_cl.add_child(_moon_tex)
        _apply_theme()

func _build_parallax(ground_y: float) -> void:
        bg_far = _mk_bg_layer("bg_far.png", ground_y, 0.25, -12)
        bg_mid = _mk_bg_layer("bg_mid.png", ground_y, 0.5, -10)
        # the sky learns its color FROM the forest art - no seam where the
        # layer's baked sky meets the flat fill above it
        var img: Image = bg_far.texture.get_image()
        if img != null and img.get_width() > 0:
                _sky_day = img.get_pixel(0, 0)
        # the underworld: below the ground the world is DARK SOIL (tall
        # windows and any camera pan never expose raw sky under the grass)
        var under := ColorRect.new()
        under.color = Color(0.13, 0.09, 0.07)
        under.position = Vector2(-TILE, ground_y)
        under.size = Vector2(cols * TILE + TILE * 4.0, 4000)
        under.z_index = -6
        world.add_child(under)

func _mk_bg_layer(nm: String, ground_y: float, f: float, z: int) -> Sprite2D:
        var s := Sprite2D.new()
        s.texture = load("res://assets/games/dario/" + nm)
        s.z_index = z
        s.centered = false
        s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
        s.region_enabled = true
        s.set_meta("f", f)
        s.set_meta("gy", ground_y)
        world.add_child(s)
        return s

func _bg_tick() -> void:
        if bg_far == null or not is_instance_valid(bg_far):
                return
        var vp := get_viewport_rect().size
        for bg in [bg_far, bg_mid]:
                var f: float = bg.get_meta("f")
                var gy: float = bg.get_meta("gy")
                # the layer GLUES to the camera horizontally (screen-fixed) while
                # the texture inside the region scrolls slower - true parallax
                bg.position = Vector2(cam.x, gy - bg.texture.get_height() * 3.0)
                bg.scale = Vector2.ONE * 3.0
                bg.region_rect = Rect2(cam.x * f, 0.0,
                                vp.x / 3.0 + 80.0, bg.texture.get_height())

func _apply_theme() -> void:
        var night := Box.item_on(game_id, "theme") == "night"
        var vp := get_viewport_rect().size
        _sky_rect.color = Color(_sky_day.r * 0.16, _sky_day.g * 0.15,
                        _sky_day.b * 0.3) if night else _sky_day
        _moon_tex.visible = night
        if night:
                _moon_tex.position = Vector2(vp.x - 150.0, 70.0)
                _stars = []
                for i in 30:
                        _stars.append(Vector2(_rng.randf_range(0, vp.x),
                                        _rng.randf_range(0, vp.y * 0.5)))
        else:
                _stars = []
        _sun_moon.queue_redraw()
        if bg_far != null and is_instance_valid(bg_far):
                var dim := Color(0.52, 0.5, 0.78) if night else Color.WHITE
                bg_far.modulate = dim
                bg_mid.modulate = dim
                tile_root.modulate = Color(0.78, 0.76, 0.95) if night else Color.WHITE

func _paint_sun_moon() -> void:
        if Box.item_on(game_id, "theme") != "night":
                return
        var vp := get_viewport_rect().size
        for s in _stars:
                var tw := 0.5 + 0.5 * sin(_time * 2.0 + s.x)
                _sun_moon.draw_circle(s, 1.6 + tw,
                                Color(1, 1, 0.9, 0.25 + 0.45 * tw))

# ============================================================ the tick

func _goga_tick(delta: float) -> void:
        _time += delta
        if _phase == "door":
                # the end-line beat, then the next level walks in
                _door_t += delta
                if _door_t >= 3.6:
                        level_i += 1
                        _next_level()
                return
        if _phase == "ending":
                _end_t += delta
                # THE ESCAPE: Dario runs right into the open ground...
                p_vel.x = WALK_V
                _walk_dir = 1.0
                _physics(delta)
                _cam_follow()
                _bg_tick()
                if _end_t > 2.6 and _end_t - delta <= 2.6:
                        # ...the shot from behind. He never left.
                        Jukebox.sfx("sl_bomb", -2.0)
                        _shake = 1.2
                        p_node.rotation = PI / 2.0
                if _end_t > 4.2:
                        _bubble_say(ENDING_SHOT, 5.0)
                        _finish()
                        return
                return
        if _phase != "play":
                return
        if _pop_t > 0.0:
                _pop_t -= delta
                if _pop_t <= 0.0:
                        _bubble_down()
        _controls(delta)
        _physics(delta)
        _enemies_tick(delta)
        _boss_tick(delta)
        _movers_tick(delta)
        _burners_tick(delta)
        _ghosts_tick(delta)
        _bolts_tick(delta)
        _hazards_tick()
        _cam_follow()
        _bg_tick()
        _bubble_follow()
        _hurt_flash = maxf(0.0, _hurt_flash - delta * 3.0)
        p_node.modulate = Color(1, 1 - _hurt_flash, 1 - _hurt_flash)
        if p_node.position.y > rows * TILE + 200.0:
                _die()          # the pit (safety - the ground never opens)

## THE CONTROLS - raw multi-touch (the TouchKit single-press law broke
## the two-thumb scheme: holding LEFT and tapping RIGHT replaced the
## press, so walking died on every jump). The first LEFT-half touch owns
## the analog walk anchor; ANY right-half press edge jumps.
var _walk_idx := -1          # the touch index that owns walking
var _walk_anchor := -1.0
var _walk_pos := Vector2.ZERO
var _walk_dir := 0.0

func _goga_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                var vp := get_viewport_rect().size
                if t.pressed:
                        if t.position.x >= vp.x * 0.5:
                                _jump_queued = true
                        elif _walk_idx == -1:
                                _walk_idx = t.index
                                _walk_anchor = t.position.x
                                _walk_pos = t.position
                else:
                        if t.index == _walk_idx:
                                _walk_idx = -1
                                _walk_anchor = -1.0
        elif event is InputEventScreenDrag:
                var d := event as InputEventScreenDrag
                if d.index == _walk_idx:
                        _walk_pos = d.position

func _controls(_delta: float) -> void:
        var target := 0.0
        if _walk_idx != -1:
                var dx := _walk_pos.x - _walk_anchor
                if absf(dx) > 14.0:
                        target = clampf(dx / 90.0, -1.0, 1.0)
        if _jump_queued and on_floor and not _locked:
                _jump()
        _jump_queued = false
        _walk_dir = 0.0 if _locked else target
        if absf(target) > 0.05 and not _locked:
                face = 1 if target > 0.0 else -1

func _jump() -> void:
        p_vel.y = JUMP_V * (2.0 if power_jump else 1.0)
        on_floor = false
        Jukebox.sfx("d_jump", -6.0, _rng.randf_range(0.95, 1.05))

## the tile physics (hand-rolled AABB vs the grid)
func _solid_at(px: float, py: float) -> bool:
        var c := int(px / TILE)
        var r := int(py / TILE)
        if c < 0 or c >= cols:
                return true            # the world's walls
        if r < 0:
                return false
        if r >= rows:
                return false
        var ch := String(grid[r][c])
        return ch in ["#", "B", "?"]

func _physics(delta: float) -> void:
        p_vel.y += GRAVITY * delta
        p_vel.x = _walk_dir * WALK_V
        if _locked:
                p_vel.x = 0.0
        # the horizontal move
        var nx := p_node.position.x + p_vel.x * delta
        var hw := p_size.x / 2.0
        if p_vel.x > 0.0:
                if _solid_at(nx + hw, p_node.position.y - 10.0) \
                                or _solid_at(nx + hw, p_node.position.y - p_size.y + 10.0):
                        nx = float(int((nx + hw) / TILE)) * TILE - hw - 0.1
        elif p_vel.x < 0.0:
                if _solid_at(nx - hw, p_node.position.y - 10.0) \
                                or _solid_at(nx - hw, p_node.position.y - p_size.y + 10.0):
                        nx = float(int((nx - hw) / TILE)) * TILE + TILE + hw + 0.1
        p_node.position.x = nx
        # the vertical move
        var prev_y := p_node.position.y
        var ny := prev_y + p_vel.y * delta
        on_floor = false
        if p_vel.y > 0.0:
                if _solid_at(p_node.position.x - hw + 6.0, ny) \
                                or _solid_at(p_node.position.x + hw - 6.0, ny):
                        ny = float(int(ny / TILE)) * TILE - 0.1
                        p_vel.y = 0.0
                        on_floor = true
                else:
                        for gp in ghosts:
                                if not bool(gp["on"]):
                                        continue
                                var top: float = gp["node"].position.y - 25.0
                                var gn: Node2D = gp["node"]
                                if absf(p_node.position.x - gn.position.x) < TILE * 1.05 \
                                                and prev_y <= top + 14.0 and ny >= top:
                                        ny = top
                                        p_vel.y = 0.0
                                        on_floor = true
                                        break
        elif p_vel.y < 0.0:
                var top2 := ny - p_size.y
                if _solid_at(p_node.position.x - hw + 6.0, top2) \
                                or _solid_at(p_node.position.x + hw - 6.0, top2):
                        ny = float(int(top2 / TILE)) * TILE + TILE + p_size.y + 0.1
                        p_vel.y = 0.0
                        _bump_block(p_node.position.x, top2)
        p_node.position.y = ny
        # the walk animation (the real Pixel Adventure frames)
        var pspr: Sprite2D = p_node.get_child(0)
        if absf(_walk_dir) > 0.05 and on_floor:
                walk_t += delta * 10.0
                var fi := int(walk_t) % 4 + 1
                pspr.texture = load("res://assets/games/dario/hero_walk%d.png" % fi)
        elif not on_floor:
                pspr.texture = load("res://assets/games/dario/hero_jump.png"
                                if p_vel.y < 0.0 else "res://assets/games/dario/hero_fall.png")
        else:
                pspr.texture = load("res://assets/games/dario/hero_stand.png")
        pspr.flip_h = face < 0
        # the items: the crates + the goal
        _items_tick()

func _bump_block(px: float, py: float) -> void:
        var c := int(px / TILE)
        var r := int(py / TILE)
        for it in items:
                if String(it["kind"]) != "box" or bool(it["used"]):
                        continue
                var cell: Vector2i = it["cell"]
                if cell.x == c and cell.y == r:
                        it["used"] = true
                        boxes_used += 1
                        Jukebox.sfx("d_bump", -4.0)
                        var loot := String(it["loot"])
                        var box_center := _cell_center(cell)
                        if loot == "coin":
                                coins_taken += 1
                                add_run_coins(1)
                                Jukebox.sfx("d_coin", -4.0)
                                _swap_box_art(cell)
                                _coin_pop(box_center + Vector2(0, -46.0))
                        elif loot == "power":
                                # the owned powerup arrives: pick one of the
                                # owned kinds (the run consumes it)
                                var owned := []
                                for pid in ["foot", "shield", "jump"]:
                                        if Box.item_owned(game_id, "power", pid):
                                                owned.append(pid)
                                if not owned.is_empty():
                                        var pid: String = owned[_rng.randi() % owned.size()]
                                        _grant_power(pid)
                                _swap_box_art(cell)
                        else:
                                Jukebox.sfx("d_bump", -8.0)
                                _swap_box_art(cell)
                        return

func _swap_box_art(cell: Vector2i) -> void:
        _tile("tile_box_empty.png", cell)

## the coin pops OUT of the crate (it never floated free in the world)
func _coin_pop(at: Vector2) -> void:
        var cn := Sprite2D.new()
        cn.texture = load("res://assets/games/dario/item_coin.png")
        cn.scale = Vector2.ONE * 0.42
        cn.position = at
        fx_root.add_child(cn)
        var tw := cn.create_tween().set_parallel(true)
        tw.tween_property(cn, "position", at + Vector2(0, -90.0), 0.55) \
                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.tween_property(cn, "modulate:a", 0.0, 0.3).set_delay(0.3)
        tw.chain().tween_callback(cn.queue_free)
        _sparkle(at)

func _grant_power(pid: String) -> void:
        Jukebox.sfx("d_power", -3.0)
        if pid == "foot":
                power_foot = true
                _bubble_say("STRONG FOOT! Stomps hit DOUBLE this level.", 2.5)
        elif pid == "shield":
                power_shield = true
                _bubble_say("THE SHIELD! One hit is on me.", 2.5)
        else:
                power_jump = true
                _bubble_say("POWER JUMP! Twice the sky.", 2.5)

func _items_tick() -> void:
        for it in items.duplicate():
                if String(it["kind"]) == "goal":
                        var dcell: Vector2i = it["cell"]
                        if _cell_center(dcell).distance_to(p_node.position) < 84.0 \
                                        and _phase == "play":
                                _reach_door()
                                return

func _reach_door() -> void:
        Jukebox.sfx("d_clear", -3.0)
        achievement_max("levels_done", level_i + 1)
        if level_i >= 9:
                # the arena's trophy never opens - the boss IS the door
                return
        _locked = true
        _phase = "door"                      # the tick drives the beat
        _door_t = 0.0
        _bubble_say(_story_line(true), 3.5)

func _story_line(is_end: bool) -> String:
        var plays := Box.counter(game_id, "playthroughs")
        if plays >= 2:
                var pool: Array = CURSED_END if is_end else CURSED_START
                return String(pool[(level_i + plays) % pool.size()])
        return String((STORY_END if is_end else STORY_START)
                .get(mini(level_i + 1, 10), ""))

# ============================================================ the enemies

func _enemies_tick(delta: float) -> void:
        for e in enemies.duplicate():
                if bool(e["dead"]):
                        continue
                var n: Node2D = e["node"]
                if not is_instance_valid(n):
                        enemies.erase(e)
                        continue
                var dist := absf(n.position.x - p_node.position.x)
                if dist > get_viewport_rect().size.x * 0.9:
                        continue          # asleep until on screen
                var spd := float(e["v"].x)
                match String(e["kind"]):
                        "spitter":
                                e["shoot_t"] = float(e["shoot_t"]) - delta
                                if float(e["shoot_t"]) <= 0.0 and dist < 760.0:
                                        e["shoot_t"] = _rng.randf_range(2.0, 3.2)
                                        _shoot(n.position, e)
                        "spiky":
                                e["spike_t"] = float(e["spike_t"]) + delta
                                var up := fmod(float(e["spike_t"]), 4.0) < 2.0
                                e["spike_up"] = up
                        _:
                                pass
                # the walkers patrol and turn at walls/ledges
                if spd != 0.0 and String(e["kind"]) != "fly":
                        var nx := n.position.x + spd * delta
                        var ahead := nx + signf(spd) * (float(e["w"]) / 2.0 + 4.0)
                        var foot_y := n.position.y + float(e["h"]) / 2.0 + 6.0
                        if _solid_at(ahead, n.position.y) \
                                        or not _solid_at(ahead, foot_y):
                                e["v"].x = -spd
                                spd = -spd
                        n.position.x = nx
                if bool(e["fly"]):
                        n.position.y = float(e["base_y"]) + sin(_time * 3.0) * 26.0
                        n.position.x += float(e["v"].x) * delta * 0.4
                        var aheadx := n.position.x + signf(float(e["v"].x)) * 40.0
                        if _solid_at(aheadx, n.position.y):
                                e["v"].x = -float(e["v"].x)
                # the sprite: the real animation frames
                var spr: Sprite2D = n.get_child(0)
                var t2 := _time * 6.0
                match String(e["kind"]):
                        "fly":
                                spr.texture = load("res://assets/games/dario/enemy_fly1.png"
                                        if int(t2) % 2 == 0
                                        else "res://assets/games/dario/enemy_fly2.png")
                        "snail":
                                spr.texture = load("res://assets/games/dario/enemy_snail1.png"
                                        if int(t2) % 2 == 0
                                        else "res://assets/games/dario/enemy_snail2.png")
                        "blocker":
                                if int(e["hp"]) < int(e["max_hp"]):
                                        spr.texture = load(
                                                "res://assets/games/dario/enemy_blocker_hit.png")
                                else:
                                        spr.texture = load("res://assets/games/dario/enemy_blocker1.png"
                                                if int(t2) % 2 == 0
                                                else "res://assets/games/dario/enemy_blocker2.png")
                        "spitter":
                                spr.texture = load("res://assets/games/dario/enemy_spitter_atk.png"
                                        if float(e["shoot_t"]) < 0.4
                                        else ("res://assets/games/dario/enemy_spitter1.png"
                                                if int(t2) % 2 == 0
                                                else "res://assets/games/dario/enemy_spitter2.png"))
                        "spiky":
                                # the REAL spikes: out = deadly, in = stompable
                                spr.texture = load("res://assets/games/dario/enemy_spiky2.png"
                                        if bool(e["spike_up"])
                                        else "res://assets/games/dario/enemy_spiky1.png")
                spr.flip_h = float(e["v"].x) > 0.0
                # the contact with Dario
                var hw: float = float(e["w"]) / 2.0
                var hh: float = float(e["h"]) / 2.0
                var dv := (p_node.position - n.position).abs()
                if dv.x < hw + p_size.x / 2.0 - 8.0 and dv.y < hh + p_size.y / 2.0 - 6.0:
                        var from_above := p_vel.y > 0.0 \
                                        and p_node.position.y < n.position.y - hh * 0.3
                        var stompable := true
                        if String(e["kind"]) == "spiky" and bool(e["spike_up"]):
                                stompable = false
                        if from_above and stompable:
                                _stomp(e)
                        else:
                                _hurt_dario()

func _stomp(e: Dictionary) -> void:
        p_vel.y = JUMP_V * 0.62
        e["hp"] = int(e["hp"]) - (2 if power_foot else 1)
        if int(e["hp"]) > 0:
                Jukebox.sfx("d_bosshit", -8.0, 1.3)
                _bubble_say("IT HOLDS! %d more!" % int(e["hp"]), 1.2)
                return
        e["dead"] = true
        var pts := int(ENEMY_SCORE[String(e["kind"])])
        add_score(pts)
        Jukebox.sfx("d_stomp", -4.0)
        _sparkle(e["node"].position)
        _floater(e["node"].position + Vector2(0, -40.0), "+%d" % pts)
        achievement_count("stomped", 1)
        e["node"].queue_free()
        enemies.erase(e)

func _hurt_dario() -> void:
        if _phase != "play":
                return
        if power_shield:
                power_shield = false
                Jukebox.sfx("d_bump", -2.0)
                _bubble_say("THE SHIELD SHATTERED!", 1.6)
                p_vel.y = JUMP_V * 0.5
                return
        _die()

func _die() -> void:
        if _phase != "play":
                return
        lives -= 1
        _refresh_hearts()
        Jukebox.sfx("d_hurt", -3.0)
        set_score(maxi(0, score - DEATH_COST))
        if lives <= 0:
                _phase = "over"
                _flush_achievements()
                finish_run(score)
                return
        _bubble_say("back to the start of this cursed level...", 2.0)
        _load_level(level_i)

# ============================================================ the hazards

func _hazards_tick() -> void:
        # the spikes: touch = hurt (the fire is the lingerer's death)
        for r in rows:
                for c in cols:
                        if String(grid[r][c]) != "^":
                                continue
                        var cx := c * TILE + TILE / 2.0
                        var spike_top := (r + 1) * TILE - 44.0
                        if absf(p_node.position.x - cx) < TILE * 0.5 + p_size.x / 2.0 - 10.0 \
                                        and p_node.position.y + p_size.y / 2.0 > spike_top \
                                        and p_node.position.y - p_size.y / 2.0 < (r + 1) * TILE:
                                _hurt_dario()
                                return

# ============================================================ the projectiles

func _shoot(at: Vector2, e: Dictionary) -> void:
        var b := Sprite2D.new()
        b.texture = load("res://assets/games/dario/spitter_bullet.png")
        b.position = at + Vector2(0, -10.0)
        ent_root.add_child(b)
        var dirv := signf(p_node.position.x - at.x)
        bolts.append({"node": b, "v": Vector2(dirv * 420.0, -60.0),
                "life": 3.0, "witcher": false})
        Jukebox.sfx("d_shot", -8.0)

func _bolts_tick(delta: float) -> void:
        for b in bolts.duplicate():
                var n: Sprite2D = b["node"]
                n.position += Vector2(b["v"]) * delta
                b["life"] = float(b["life"]) - delta
                if float(b["life"]) <= 0.0 or not is_instance_valid(n):
                        bolts.erase(b)
                        if is_instance_valid(n):
                                n.queue_free()
                        continue
                if n.position.distance_to(p_node.position) < 48.0:
                        bolts.erase(b)
                        n.queue_free()
                        _hurt_dario()

# ============================================================ the movers

func _movers_tick(delta: float) -> void:
        for m in movers:
                m["t"] = float(m["t"]) + delta * float(m["spd"])
                var off := sin(float(m["t"])) * float(m["amp"])
                var n: Node2D = m["node"]
                n.position.x = float(m["a"].x) + off
                # the carry: Dario rides when standing on the deck (48 tall)
                var top_y: float = n.position.y - 24.0
                if p_vel.y >= 0.0 \
                                and absf(p_node.position.x - n.position.x) < TILE * 1.35 \
                                and absf(p_node.position.y - top_y) < 16.0:
                        p_node.position.y = top_y
                        p_vel.y = 0.0
                        on_floor = true
                        p_node.position.x += off - float(m.get("last",
                                        float(m["a"].x) + off))
                        m["last"] = n.position.x

func _burners_tick(delta: float) -> void:
        for b in burners:
                var fx: Sprite2D = b["fx"]
                fx.texture = load("res://assets/games/dario/fire1.png"
                        if int(_time * 8.0) % 2 == 0
                        else "res://assets/games/dario/fire2.png")
                var flame_cx: float = b["node"].position.x
                var flame_top: float = b["node"].position.y - 150.0
                if absf(p_node.position.x - flame_cx) < 52.0 \
                                and p_node.position.y + p_size.y / 2.0 > flame_top:
                        b["heat"] = float(b["heat"]) + delta
                        if float(b["heat"]) > 1.2:
                                b["heat"] = 0.0
                                _hurt_dario()
                else:
                        b["heat"] = maxf(0.0, float(b["heat"]) - delta * 2.0)

## the ghost platforms: ON 2.1s, OFF 1.5s, offset phases - the timed
## climb (the owner's design for reaching the Witcher "in a hard way")
func _ghosts_tick(delta: float) -> void:
        var cyc_on := 2.1
        var cyc_len := 3.6
        for gp in ghosts:
                gp["cyc"] = float(gp["cyc"]) + delta
                var ph := fmod(float(gp["cyc"]) + float(gp["phase"]), cyc_len)
                var on := ph < cyc_on
                gp["on"] = on
                var spr: Sprite2D = gp["spr"]
                if on:
                        # blink the last 0.6s as the vanish warning
                        var left := cyc_on - ph
                        spr.texture = load("res://assets/games/dario/plat_on.png")
                        spr.modulate.a = 1.0 if left > 0.6 \
                                        else (0.35 + 0.65 * absf(sin(_time * 14.0)))
                else:
                        spr.texture = load("res://assets/games/dario/plat_off.png")
                        spr.modulate.a = 0.3

# ============================================================ the camera

func _cam_follow() -> void:
        var vp := get_viewport_rect().size
        var view_h := vp.y - banner_bottom()
        cam.x = clampf(p_node.position.x - vp.x * 0.42, 0.0,
                        maxf(0.0, cols * TILE - vp.x))
        cam.y = clampf(p_node.position.y - view_h * 0.55, 0.0,
                        maxf(0.0, rows * TILE - view_h))
        world.position = Vector2(-cam.x, banner_bottom() - cam.y)

# ============================================================ the dialogue
## THE BUBBLE: white background, BLACK text, and it rides OVER DARIO'S
## HEAD (the owner: "the pop-ups over dario's head, not in the top
## center of the screen"). One bubble at a time.

var _bubble: PanelContainer

func _bubble_say(txt: String, secs: float) -> void:
        _bubble_down()
        if txt == "":
                return
        _bubble = PanelContainer.new()
        var sb := Arc.panel_style(Color(1, 1, 1, 0.97), 14)
        sb.border_color = Color(0.12, 0.09, 0.14)
        sb.set_border_width_all(3)
        sb.content_margin_left = 14.0
        sb.content_margin_right = 14.0
        sb.content_margin_top = 8.0
        sb.content_margin_bottom = 8.0
        _bubble.add_theme_stylebox_override("panel", sb)
        var l := Arc.label(txt, 21, Color(0.1, 0.08, 0.12), false)
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l.custom_minimum_size = Vector2(390, 0)
        _bubble.add_child(l)
        fx_root.add_child(_bubble)
        _pop_t = secs
        _bubble_follow()

func _bubble_down() -> void:
        if _bubble != null and is_instance_valid(_bubble):
                _bubble.queue_free()
        _bubble = null
        _pop_t = 0.0

func _bubble_follow() -> void:
        if _bubble == null or not is_instance_valid(_bubble):
                return
        _bubble.reset_size()
        var bs := _bubble.size
        var px := clampf(p_node.position.x - bs.x / 2.0, 6.0,
                        maxf(6.0, cols * TILE - bs.x - 6.0))
        var py := p_node.position.y - p_size.y / 2.0 - bs.y - 18.0
        if py < 4.0:
                py = p_node.position.y + p_size.y / 2.0 + 14.0
        _bubble.position = Vector2(px, py).round()

## the tiny score floater over a stomped enemy
func _floater(at: Vector2, txt: String) -> void:
        var l := Arc.label(txt, 26, Color(1, 1, 1), true)
        var sb := Arc.panel_style(Color(0.12, 0.09, 0.14, 0.9), 10, 6)
        l.add_theme_stylebox_override("normal", sb)
        l.position = at - Vector2(30, 20)
        fx_root.add_child(l)
        var tw := l.create_tween().set_parallel(true)
        tw.tween_property(l, "position", l.position + Vector2(0, -56.0), 0.7) \
                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.35)
        tw.chain().tween_callback(l.queue_free)

func _story_pop(txt: String) -> void:
        if txt == "":
                return
        _bubble_say(txt, 10.0)

# ============================================================ the fx

var _fx: Array = []

func _sparkle(at: Vector2) -> void:
        for i in 6:
                var d := ColorRect.new()
                d.color = Color(1.0, 0.85, 0.3)
                d.size = Vector2(6, 6)
                d.position = at
                fx_root.add_child(d)
                var tw := d.create_tween().set_parallel(true)
                tw.tween_property(d, "position", at + Vector2(
                                _rng.randf_range(-50, 50), _rng.randf_range(-70, -10)), 0.4)
                tw.tween_property(d, "modulate:a", 0.0, 0.4)
                tw.chain().tween_callback(d.queue_free)

# ============================================================ the ending

var _shake := 0.0

func _finish() -> void:
        if _phase == "over":
                return
        _phase = "over"
        _flush_achievements()
        finish_run(score)

func _flush_achievements() -> void:
        achievement_max("max_score", score)
        check_achievements()

# ============================================================ the boss act

func _start_boss(cell: Vector2i) -> void:
        boss_hp = BOSS_HP
        var node := Node2D.new()
        var bx := cell.x * TILE + TILE / 2.0
        node.position = Vector2(bx, 6.0 * TILE - 20.0)
        var spr := Sprite2D.new()
        spr.texture = load("res://assets/games/dario/witcher_appear1.png")
        node.add_child(spr)
        ent_root.add_child(node)
        boss = {"node": node, "t": 0.0, "shoot_t": 1.6, "base_x": bx,
                "iframes": 0.0, "appear_t": 0.6}
        _bubble_say(WITCHER_LINE, 5.0)

func _boss_tick(delta: float) -> void:
        if boss.is_empty() or _phase != "play":
                return
        var n: Node2D = boss["node"]
        boss["t"] = float(boss["t"]) + delta
        boss["iframes"] = maxf(0.0, float(boss["iframes"]) - delta)
        # the appear / idle frames
        var spr: Sprite2D = n.get_child(0)
        if float(boss["appear_t"]) > 0.0:
                boss["appear_t"] = float(boss["appear_t"]) - delta
                var ai := 4 - int(ceilf(float(boss["appear_t"]) / 0.15))
                ai = clampi(ai, 1, 4)
                spr.texture = load("res://assets/games/dario/witcher_appear%d.png" % ai)
        else:
                spr.texture = load("res://assets/games/dario/witcher1.png"
                        if int(_time * 3.0) % 2 == 0
                        else "res://assets/games/dario/witcher2.png")
        # she HAUNTS her summoning ground: a fixed swing around her base
        n.position.x = float(boss["base_x"]) \
                        + sin(float(boss["t"]) * 0.9) * TILE * 2.5
        n.position.y = 6.0 * TILE - 20.0 + sin(float(boss["t"]) * 1.7) * 30.0
        boss["shoot_t"] = float(boss["shoot_t"]) - delta
        if float(boss["shoot_t"]) <= 0.0:
                boss["shoot_t"] = _rng.randf_range(1.3, 2.0)
                for i in 2:
                        var b := Sprite2D.new()
                        b.texture = load("res://assets/games/dario/curse_bolt.png")
                        b.scale = Vector2.ONE * 0.55
                        b.position = n.position
                        ent_root.add_child(b)
                        var dirv := (p_node.position - n.position).normalized()
                        bolts.append({"node": b,
                                "v": Vector2(dirv.x * 380.0, dirv.y * 380.0 - 40.0),
                                "life": 3.0, "witcher": true})
                Jukebox.sfx("d_curse", -5.0)
        # the stomp check (with mercy iframes - no bounce-into-hurt chain)
        var d := n.position.distance_to(p_node.position)
        if float(boss["iframes"]) > 0.0:
                return
        if p_vel.y > 0.0 and d < 96.0 \
                        and p_node.position.y < n.position.y:
                p_vel.y = JUMP_V * 0.7
                boss_hp -= 2 if power_foot else 1
                boss["iframes"] = 0.7
                Jukebox.sfx("d_bosshit", -4.0)
                _sparkle(n.position)
                _floater(n.position + Vector2(0, -50.0), "%d more!" % maxi(0, boss_hp))
                if boss_hp <= 0:
                        add_score(BOSS_SCORE)
                        Jukebox.sfx("d_bossdie", -2.0)
                        _sparkle(n.position + Vector2(0, -40))
                        boss["node"].queue_free()
                        boss = {}
                        achievement_max("witcher", 1)
                        achievement_max("levels_done", 10)
                        _the_ending()
        elif d < 74.0:
                _hurt_dario()

func _the_ending() -> void:
        _phase = "ending"
        _end_t = 0.0
        _locked = false
        _bubble_say(ENDING_LINE, 2.6)
