extends GogaGame
## CURSED DARIO - v0.3.1, REBUILT FROM THE LORE OUT (the owner: the old
## one is "broken", the PGB one is "the worst design ever").
##
## THE LORE: Dario fell into this world through a Witcher's curse. Ten
## levels to the end line, and the last mission is the Witcher herself:
## crush her head ~20 times while she hurls curses. Win and Dario runs
## for the open ground... and a shot comes from behind. He never escaped.
## Every replay the dialogue shifts - deja vu, the trees repeat, he is
## living in a dream. Cursed forever.
##
## Owner laws (v0.3.1):
##   - mario-like: jump-on-enemies to kill, no shooting for Dario
##   - 10 levels; the entry costs 100 coins (registry fee 100); bonus /10
##   - enemies score per kind; blockers shield (3 stomps); spitters shoot;
##     spiky enemies are stompable only when their spikes are down;
##     burning platforms hurt the lingerer; moving platforms carry
##   - "?" blocks: a GOGACoin (max 5 a level), a powerup (ONLY if bought
##     in the shop - else the block shows EMPTY), or nothing
##   - the shop: the night theme (sky + moon) + three powerups: STRONG
##     FOOT (2x stomp damage this level), SHIELD (absorbs one hit or
##     shot, never a fall), POWER JUMP (x2 jump this level)
##   - 3 lives; a death restarts the level at -200 score
##   - controls like the snowy tower: the left half walks, the right
##     side jumps
##   - a dialogue box at level 1, a 10s story pop-up at every level
##     start, end-of-level lines, the Witcher's unique taunt, and the
##     cursed replay variants
##   - banner ads with the ground raised above the strip
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

## the enemy score table (the owner: different points per kind)
const ENEMY_SCORE := {
        "snail": 10, "fly": 15, "spitter": 20, "blocker": 25, "spiky": 30,
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
        1: "DARIO: A door in the middle of a forest. Fine. I walk through doors.",
        2: "DARIO: The same door. The SAME door again.",
        3: "DARIO: Did the forest just... rearrange itself behind me?",
        4: "DARIO: I am not sure I am walking FORWARD anymore.",
        5: "DARIO: Her humming again. Closer. She is HERDING me.",
        6: "DARIO: The burns heal the moment I look away. Of course they do.",
        7: "DARIO: I counted my steps. The number was the same as yesterday.",
        8: "DARIO: I dreamed this level. I dreamed it and it listened.",
        9: "DARIO: One more door. She is behind one more door.",
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
        "DARIO: Another door. Another chapter of the same bad dream.",
        "DARIO: The door makes the same creak. Every time. Every run.",
        "DARIO: One day I will open this door and stay on THIS side. Maybe.",
        "DARIO: The exit smells like the entrance. Funny world. Cursed world.",
        "DARIO: If this is a dream, whose dream is it? ...Hers?",
]
const WITCHER_LINE := "THE WITCHER: YOU WILL NEVER LEAVE, LITTLE HERO. YOU NEVER DID."
const ENDING_LINE := "DARIO: The open ground! I made it! I made it out of-"
const ENDING_SHOT := "...a shot rings out from behind. The Witcher smiles.\nDario never left. Dario will never leave."

# the enemy defs
const E_DEFS := {
        "snail": {"hp": 1, "speed": 90.0, "w": 66.0, "h": 52.0},
        "fly": {"hp": 1, "speed": 130.0, "w": 64.0, "h": 48.0, "fly": true},
        "spitter": {"hp": 2, "speed": 0.0, "w": 66.0, "h": 66.0, "shoot": true},
        "blocker": {"hp": 3, "speed": 60.0, "w": 70.0, "h": 66.0},
        "spiky": {"hp": 1, "speed": 80.0, "w": 64.0, "h": 58.0, "spiky": true},
}

# ============================================================ level data
## tile chars: # ground | B brick | ? block | c coin | s snail | f fly |
## b blocker | p spitter | h spiky | m platform (moves) | ~ burning | ^
## spikes | D door | d start | T torch | * plant
const LEVELS := [
        [ # 1 - the fall (flat + two snails + the first box)
                "                                                                                                                                                    ",
                "                                                                                                                                                    ",
                "                                                                                                                                                    ",
                "                                                                                                                                                    ",
                "                                     c c c                                                                                                          ",
                "                                   =======                                                                                                          ",
                "              c c                                          c c c                                            c c                                     ",
                "            =====             ?                  T        =======             s                 T            =====          D                       ",
                "                                                                 s                                            s                                     ",
                "        *        s                        s         *                       B B B                        s                                          ",
                "  d                                 *                                                                 *                                        *    ",
                "############################   ###########   ###########################################################################  ##########                ",
            ],
        [ # 2 - gaps + the first fly
                "                                                                                                                         ",
                "                                                                                                                         ",
                "                                                                                                                         ",
                "                    c c c                                                                                                ",
                "                  =======                    f                            f                                              ",
                "                                             ___                            ___                                          ",
                "         c c                  ?                                     c c                                     c c          ",
                "       =====            ==========             s          ========== =====                        =====                  ",
                "                                                                 s                                                       ",
                "   d                s          f          *                   B B B                  s          f             D          ",
                "                                                                                                                         ",
                "########      ############   #####    ####################################    ###########   ############################ ",
            ],
        [ # 3 - the blocks teach (coins + the first power box)
                "                                                                                                                              ",
                "                                                                                                                              ",
                "                                                                                                                              ",
                "                                 B ? B ? B                                                                                    ",
                "                                =======                                                                                       ",
                "                    c c c                                        c c c                                                        ",
                "                  =======             f                 T      =======                          ?                             ",
                "         c                       ==========                                          =======                                  ",
                "       =====      s                                   s           f                  s                        D               ",
                "                =====          *          s        ======         B B          *          s          s                        ",
                "  d                                                                                                                           ",
                "#######    #################    ##########    ####################    #############    #######################################",
            ],
        [ # 4 - the movers over the pit
                "                                                                                                                    ",
                "                                                                                                                    ",
                "                                                                                                                    ",
                "                        c c c                                     c c c                                             ",
                "                      =======          m          m             =======                                             ",
                "                                       ___        ___                                                               ",
                "        c c         ?                                                          ?                                    ",
                "      =====      ======            f                f                        ======                                 ",
                "                  =====                                                        =====                                ",
                "   d        s              s              *                   s          s                 s          D             ",
                "                                                                                                                    ",
                "#############    ####      ###      ####      #########    ####      ###      ##########    ########################",
            ],
        [ # 5 - the spitter + the spikes
                "                                                                                                                                           ",
                "                                                                                                                                           ",
                "                                                                                                                                           ",
                "                          c c c                       c c c                                                                                ",
                "                        =======                     =======                             ?                                                  ",
                "         f                        p                       p                            ===                                                 ",
                "      _____                       ____                    ____                                       c c c                                 ",
                "                    s                                  f             h                          =====         D                            ",
                "  d           *            ^          s       ^                   *          ^          s          ^       s                               ",
                "#########    ################    #############    ############################    ##################    #####################              ",
            ],
        [ # 6 - the blocker + the burners
                "                                                                                                                                 ",
                "                                                                                                                                 ",
                "                                                                                                                                 ",
                "                          B ? B                                       ?                                                          ",
                "                         =====            c c c                       ===                                                        ",
                "                                     =======                                                                c c c                ",
                "        c c      b                  ~~~~~~             b                       f                       =====                     ",
                "      =====             s           ~~~~~~                    s         ____          b          s                  D            ",
                "                    ======                                 s                                                s                    ",
                "   d                            s                    *                             *        s         *                          ",
                "                                                                                                                                 ",
                "#########    ###################    ###########    #####################    ###################    ##############################",
            ],
        [ # 7 - the spiky timing game
                "                                                                                                                        ",
                "                                                                                                                        ",
                "                                                                                                                        ",
                "                     c c c                    c c c                                                                     ",
                "                   =======                    ======                     ?                                              ",
                "         f                                                                ====                                          ",
                "      _____          h                    m                h                        h                  D                ",
                "                  _____           s      _____                       s         _____        s                           ",
                "  d        s                                          *                                    *                            ",
                "########    ###########    #########        ##################    ############    ##################################### ",
            ],
        [ # 8 - the gauntlet
                "                                                                                                                                ",
                "                                                                                                                                ",
                "                            B ? B ? B                                                                                           ",
                "                           =======                                                                                              ",
                "                  c c c                  c c c                                                                                  ",
                "                =======        f         =======                                 ?                                              ",
                "       c c            p                       p        f                  ========                          D                   ",
                "     ======                  ____                    _____          s          ====         s                                   ",
                "              s     h                  b                          f                       b         s                           ",
                "  d        ======           ======            s          *        ======     *         ======                                   ",
                "                                                                                                                                ",
                "#########    #################    #############    ###################    ####################    ##############################",
            ],
        [ # 9 - everything, tricky
                "                                                                                                                                     ",
                "                                                                                                                                     ",
                "                                B ? B                                                                                                ",
                "                               =======                                                                                               ",
                "                    c c c                    c c c                    c c c                                                          ",
                "                  =======      f          =======         m         =======                            ?                             ",
                "        c          ======            h                ___       ~~~~~~                    ======                                     ",
                "      =====      ~~~~~~       s        _____     b              ~~~~~~   p                      s         s        D                 ",
                "               ~~~~~~                                            ____                                b                               ",
                "  d       s                            *          s        *                   *        s         *         s                        ",
                "                                                                                                                                     ",
                "##########    ################    #############    ######################    ###################    #################################",
            ],
        [ # 10 - THE WITCHER (the arena + the castle sky)
                "                                                                                                ",
                "                                                                                                ",
                "                                                                                                ",
                "                                                                                                ",
                "                                                                                                ",
                "                                                                                                ",
                "                                                     W                                          ",
                "                                                                                                ",
                "         c c c                                                       c c c                      ",
                "       =======              *                        T              =======                     ",
                "  d                                                                                       D     ",
                "################################################################################################",
            ],
]

# ============================================================ state
var lives := START_LIVES
var level_i := 0
var grid: Array = []               # grid[row][col] = the tile char (solids)
var cols := 0
var rows := 12
var items: Array = []              # coins/blocks entities {kind, node, cell...}
var enemies: Array = []
var movers: Array = []             # moving platforms {node, a, b, t, axis}
var burners: Array = []            # burning platforms {node, cell, heat}
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
var sky_painter: Node2D
var tile_root: Node2D
var ent_root: Node2D
var fx_root: Node2D
var pop_lbl: Label
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

# ============================================================ setup

var _jump_queued := false

func _goga_setup() -> void:
        _rng.randomize()
        pause_end_run = false
        Box.bump_counter(game_id, "playthroughs", 1)   # the cursed replays
        tk.press_started.connect(func(_p):
                var vp := get_viewport_rect().size
                if _p.x >= vp.x * 0.5:
                        _jump_queued = true)
        set_hud_score_prefix("SCORE")
        _build_shop_button()
        _build_hearts()
        lvl_lbl = add_hud_chip("L1")
        _next_level(true)
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

func _shop_open() -> void:
        var root := _overlay_root_ref()
        var sheet := Arc.sheet(root, 0.0)
        sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
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
        var night := Box.item_owned(game_id, "theme", "night")
        box.add_child(_row("THE NIGHT THEME", "a darker sky, a moon, cold stars",
                        THEME_NIGHT_PRICE, "theme", "night", night,
                        func():
                                Box.equip_item(game_id, "theme", "night")
                                _apply_sky()
                                _shop_open()))
        for pid in ["foot", "shield", "jump"]:
                var on := Box.item_owned(game_id, "power", pid)
                var pdesc: String = {
                        "foot": "STRONG FOOT - stomps do DOUBLE damage (per level or death)",
                        "shield": "SHIELD - absorbs one hit or shot, never a fall",
                        "jump": "POWER JUMP - jumps twice as high (per level or death)",
                }[pid]
                box.add_child(_row({"foot": "STRONG FOOT", "shield": "THE SHIELD",
                        "jump": "POWER JUMP"}[pid], pdesc,
                        int(POWER_PRICE[pid]), "power", pid, on, Callable()))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): _drop_sheet(sheet)))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _drop_sheet(sheet: Control) -> void:
        # the sheet lives center-in-dim: freeing the dim frees the pair
        var dim: Control = sheet.get_parent().get_parent()
        if dim != null and is_instance_valid(dim):
                dim.queue_free()

func _row(title: String, desc: String, price: int, cat: String,
                item: String, owned: bool, on_buy: Callable = Callable()) -> Control:
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 2)
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
                                _shop_open())
        if Box.coins() < price:
                b.disabled = true
        v.add_child(b)
        return v

# ============================================================ the level

func _next_level(first := false) -> void:
        _load_level(level_i)
        if not first:
                _story_pop(STORY_END.get(level_i, ""))
        # the start line: first-play script, the cursed pool on replays
        var plays := Box.counter(game_id, "playthroughs")
        var line: String
        if plays >= 2:
                line = String(CURSED_START[(level_i + plays) % CURSED_START.size()])
        else:
                line = String(STORY_START.get(mini(level_i + 1, 10), ""))
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
        bolts = []
        boss = {}
        coins_taken = 0
        boxes_used = 0
        power_foot = false
        power_jump = false
        _phase = "play"
        _locked = false
        world = Node2D.new()
        add_child(world)
        world.position.y = banner_bottom()
        var map: Array = LEVELS[mini(idx, LEVELS.size() - 1)]
        rows = map.size()
        cols = String(map[0]).length()
        grid = []
        tile_root = Node2D.new()
        world.add_child(tile_root)
        sky_painter = Node2D.new()
        sky_painter.z_index = -20
        sky_painter.draw.connect(_paint_sky)
        world.add_child(sky_painter)
        ent_root = Node2D.new()
        ent_root.z_index = 4
        world.add_child(ent_root)
        fx_root = Node2D.new()
        fx_root.z_index = 8
        world.add_child(fx_root)
        var night := Box.item_on(game_id, "theme") == "night"
        var loot_i := 0
        # per level the coin boxes: max 5, then the rest are empty
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
                                        _tile("tile_grass.png", cell)
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
                                        _tile("tile_box_coin.png" if loot == "coin"
                                                else "tile_box_item.png" if loot == "power"
                                                else "tile_box_empty.png", cell)
                                "D":
                                        row.append(".")
                                        items.append({"kind": "door", "cell": cell})
                                        _tile("tile_door_top.png", Vector2i(c, r - 1))
                                        _tile("tile_door.png", cell)
                                "T":
                                        row.append(".")
                                        _tile("deco_torch.png", cell, true)
                                "*":
                                        row.append(".")
                                        _tile("deco_plant.png" if (c % 2 == 0)
                                                else "deco_plant_purple.png", cell, true)
                                "d":
                                        row.append(".")
                                        p_pos = Vector2(c * TILE + TILE / 2.0,
                                                        r * TILE + TILE / 2.0)
                                "W":
                                        row.append(".")
                                        _start_boss(cell)
                                "c":
                                        row.append(".")
                                        var cn := Sprite2D.new()
                                        cn.texture = load("res://assets/games/dario/item_coin.png")
                                        cn.position = _cell_center(cell)
                                        ent_root.add_child(cn)
                                        items.append({"kind": "coin", "node": cn,
                                                "cell": cell})
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
                                        _spawn_mover(cell, true)
                                "~":
                                        row.append(".")
                                        _spawn_burner(cell)
                                _:
                                        row.append(".")
                grid.append(row)
        # the night tint: the tiles dim under the moon
        tile_root.modulate = Color(0.58, 0.60, 0.82) \
                        if Box.item_on(game_id, "theme") == "night" else Color.WHITE
        # THE GROUND SNAP: the grid is complete now - drop every ground
        # dweller onto the first floor under its marked cell
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
        # the player (reborn fresh)
        if p_node != null and is_instance_valid(p_node):
                p_node.queue_free()
        p_node = Node2D.new()
        p_node.position = p_pos
        var pspr := Sprite2D.new()
        pspr.texture = load("res://assets/games/dario/hero_stand.png")
        p_node.add_child(pspr)
        ent_root.add_child(p_node)
        p_vel = Vector2.ZERO
        power_foot = false
        power_jump = false
        power_shield = false
        _apply_sky()

func _tile(name_: String, cell: Vector2i, deco := false) -> void:
        var s := Sprite2D.new()
        s.texture = load("res://assets/games/dario/" + name_)
        s.position = _cell_center(cell)
        s.z_index = -4 if deco else 0
        tile_root.add_child(s)

func _cell_center(c: Vector2i) -> Vector2:
        return Vector2(c.x * TILE + TILE / 2.0, c.y * TILE + TILE / 2.0)

func _spawn_enemy(kind: String, cell: Vector2i) -> void:
        var d: Dictionary = E_DEFS[kind]
        var node := Node2D.new()
        var at := _cell_center(cell)
        # the ground dwellers DROP to the first floor under their cell
        # (the maps mark their COLUMN, not their exact row)
        # (the snap runs after the parse - see the loop at the tail of
        # _load_level; the grid does not exist below us yet)
        node.position = at
        # the body (v0.3.1 catch: the enemies were born WITHOUT a sprite
        # and the animation tick kept hitting a null child)
        var spr := Sprite2D.new()
        var texname := "enemy_snail1.png"
        match kind:
                "fly":
                        texname = "enemy_fly1.png"
                "snail":
                        texname = "enemy_snail1.png"
                "blocker":
                        texname = "enemy_blocker.png"
                "spitter":
                        texname = "deco_plant_purple.png"
                "spiky":
                        texname = "deco_cactus.png"
        spr.texture = load("res://assets/games/dario/" + texname)
        spr.scale = Vector2.ONE * float(d["w"]) / float(spr.texture.get_width())
        node.add_child(spr)
        ent_root.add_child(node)
        enemies.append({
                "kind": kind, "node": node, "hp": int(d["hp"]),
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

func _spawn_mover(cell: Vector2i, horiz: bool) -> void:
        var node := Node2D.new()
        node.position = _cell_center(cell)
        var pl := ColorRect.new()
        pl.color = Color("8a5a3a")
        pl.size = Vector2(TILE * 2.4, 18)
        pl.position = -pl.size / 2.0
        node.add_child(pl)
        ent_root.add_child(node)
        movers.append({"node": node, "axis": 0 if horiz else 1,
                "t": _rng.randf_range(0.0, TAU),
                "a": node.position, "amp": TILE * 2.6, "spd": 1.1,
                "last": node.position.x})

func _spawn_burner(cell: Vector2i) -> void:
        var node := Node2D.new()
        node.position = _cell_center(cell)
        var pl := ColorRect.new()
        pl.color = Color("7a4030")
        pl.size = Vector2(TILE * 1.8, 16)
        pl.position = -pl.size / 2.0
        node.add_child(pl)
        ent_root.add_child(node)
        burners.append({"node": node, "cell": cell, "heat": 0.0})

# ============================================================ the sky

func _apply_sky() -> void:
        _stars = []
        var night := Box.item_on(game_id, "theme") == "night"
        var vp := get_viewport_rect().size
        if night:
                for i in 26:
                        _stars.append(Vector2(_rng.randf_range(0, vp.x),
                                        _rng.randf_range(0, vp.y * 0.5)))
        sky_painter.queue_redraw()

func _paint_sky() -> void:
        var vp := get_viewport_rect().size
        var night := Box.item_on(game_id, "theme") == "night"
        var top := Color("7ec8e8") if not night else Color("141433")
        var bot := Color("b8e4f4") if not night else Color("2c2444")
        if level_i == 9:
                top = Color("88a8d8") if not night else Color("10102c")
                bot = Color("c8d8e8") if not night else Color("241c38")
        sky_painter.draw_rect(Rect2(Vector2.ZERO, vp), top)
        sky_painter.draw_rect(Rect2(Vector2(0, vp.y * 0.45), vp), bot)
        # the underworld: below the bottom tile row the world is DARK
        sky_painter.draw_rect(Rect2(Vector2(-TILE, rows * TILE),
                        Vector2(cols * TILE + TILE * 2.0, vp.y * 2.0)),
                        Color(0.12, 0.09, 0.07))
        if night:
                for s in _stars:
                        var tw := 0.5 + 0.5 * sin(_time * 2.0 + s.x)
                        sky_painter.draw_circle(s, 1.6 + tw,
                                        Color(1, 1, 0.9, 0.25 + 0.45 * tw))
                var moon: Texture2D = load("res://assets/games/dario/deco_moon.png")
                sky_painter.draw_texture(moon, Vector2(vp.x - 170.0, 70.0))
        else:
                # the sun (the small round one, the snowy tower law)
                var sun := Vector2(vp.x - 120.0, 110.0)
                sky_painter.draw_circle(sun, 44.0, Color(1.0, 0.92, 0.55))
                sky_painter.draw_circle(sun, 54.0, Color(1.0, 0.92, 0.55, 0.18))

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
                _physics(delta)
                _cam_follow()
                if _end_t > 2.6 and _end_t - delta <= 2.6:
                        # ...the shot from behind. He never left.
                        Jukebox.sfx("sl_bomb", -2.0)
                        _shake = 1.2
                        p_node.rotation = PI / 2.0
                if _end_t > 4.2:
                        _say(ENDING_SHOT, 5.0)
                        _finish()
                        return
                world.queue_redraw()
                return
        if _phase != "play":
                return
        if _pop_t > 0.0:
                _pop_t -= delta
                if _pop_t <= 0.0 and is_instance_valid(pop_lbl):
                        pop_lbl.queue_free()
                        pop_lbl = null
        _controls(delta)
        _physics(delta)
        _enemies_tick(delta)
        _boss_tick(delta)
        _movers_tick(delta)
        _burners_tick(delta)
        _bolts_tick(delta)
        _cam_follow()
        _hurt_flash = maxf(0.0, _hurt_flash - delta * 3.0)
        p_node.modulate = Color(1, 1 - _hurt_flash, 1 - _hurt_flash)
        if p_node.position.y > rows * TILE + 200.0:
                _die()          # the pit
        world.queue_redraw()

## the snowy-tower controls: the LEFT half walks (the drag anchor), the
## RIGHT side taps to jump
var _walk_anchor := -1.0
var _walk_dir := 0.0

func _controls(delta: float) -> void:
        var vp := get_viewport_rect().size
        var target := 0.0
        if tk.is_down():
                var p := tk.press_pos()
                if p.x < vp.x * 0.5:
                        if _walk_anchor < 0.0:
                                _walk_anchor = p.x
                        var dx := p.x - _walk_anchor
                        if absf(dx) > 14.0:
                                target = clampf(dx / 90.0, -1.0, 1.0)
                else:
                        _walk_anchor = -1.0
        else:
                _walk_anchor = -1.0
        if _jump_queued and on_floor and not _locked:
                _jump()
        _jump_queued = false
        _walk_dir = target
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
        var was_floor := on_floor
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
        var ny := p_node.position.y + p_vel.y * delta
        on_floor = false
        if p_vel.y > 0.0:
                if _solid_at(p_node.position.x - hw + 6.0, ny) \
                                or _solid_at(p_node.position.x + hw - 6.0, ny):
                        ny = float(int(ny / TILE)) * TILE - 0.1
                        p_vel.y = 0.0
                        on_floor = true
        elif p_vel.y < 0.0:
                var top := ny - p_size.y
                if _solid_at(p_node.position.x - hw + 6.0, top) \
                                or _solid_at(p_node.position.x + hw - 6.0, top):
                        ny = float(int(top / TILE)) * TILE + TILE + p_size.y + 0.1
                        p_vel.y = 0.0
                        _bump_block(p_node.position.x, top)
        p_node.position.y = ny
        # the walk animation
        if absf(_walk_dir) > 0.05 and on_floor:
                walk_t += delta * 10.0
                var fi := int(walk_t) % 4 + 1
                p_node.get_child(0).texture = load("res://assets/games/dario/hero_walk%d.png" % fi)
        elif on_floor:
                p_node.get_child(0).texture = load("res://assets/games/dario/hero_stand.png")
        else:
                p_node.get_child(0).texture = load("res://assets/games/dario/hero_jump.png")
        p_node.get_child(0).flip_h = face < 0
        # the items: the coins + the boxes + the door
        _items_tick()

func _bump_block(px: float, py: float) -> void:
        var c := int(px / TILE)
        var r := int(py / TILE) - 0
        for it in items:
                if String(it["kind"]) != "box" or bool(it["used"]):
                        continue
                var cell: Vector2i = it["cell"]
                if cell.x == c and cell.y == r:
                        it["used"] = true
                        boxes_used += 1
                        Jukebox.sfx("d_bump", -4.0)
                        var loot := String(it["loot"])
                        if loot == "coin":
                                coins_taken += 1
                                add_run_coins(1)
                                Jukebox.sfx("d_coin", -4.0)
                                _tile("tile_box_empty.png", cell)
                                _sparkle(_cell_center(cell) + Vector2(0, -40.0))
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
                                _tile("tile_box_empty.png", cell)
                        else:
                                Jukebox.sfx("d_bump", -8.0)
                                _tile("tile_box_empty.png", cell)
                        return

func _grant_power(pid: String) -> void:
        Jukebox.sfx("d_power", -3.0)
        if pid == "foot":
                power_foot = true
                _say("STRONG FOOT! Stomps hit DOUBLE this level.", 2.5)
        elif pid == "shield":
                power_shield = true
                _say("THE SHIELD! One hit is on me.", 2.5)
        else:
                power_jump = true
                _say("POWER JUMP! Twice the sky.", 2.5)

func _items_tick() -> void:
        for it in items.duplicate():
                if String(it["kind"]) == "coin":
                        var n: Sprite2D = it["node"]
                        n.rotation += get_process_delta_time() * 3.0
                        if n.position.distance_to(p_node.position) < 64.0:
                                items.erase(it)
                                add_run_coins(1)
                                Jukebox.sfx("d_coin", -5.0)
                                _sparkle(n.position)
                                n.queue_free()
                elif String(it["kind"]) == "door":
                        var dcell: Vector2i = it["cell"]
                        if _cell_center(dcell).distance_to(p_node.position) < 70.0 \
                                        and _phase == "play":
                                _reach_door()
                                return

func _reach_door() -> void:
        Jukebox.sfx("d_clear", -3.0)
        achievement_max("levels_done", level_i + 1)
        if level_i >= 9:
                # the Witcher's arena door never opens - the boss IS the door
                return
        _locked = true
        _phase = "door"                      # the tick drives the beat
        _door_t = 0.0
        var line := _story_line(false)
        _say(line, 3.5)                      # the end line gets its beat,
                # then the next level's start line follows it in

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
                                e["shoot_t"] -= delta
                                if e["shoot_t"] <= 0.0 and dist < 760.0:
                                        e["shoot_t"] = _rng.randf_range(2.0, 3.2)
                                        _shoot(n.position, e)
                        "spiky":
                                e["spike_t"] += delta
                                var up := fmod(e["spike_t"], 4.0) < 2.0
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
                # the sprite + the flip
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
                                spr.texture = load("res://assets/games/dario/enemy_blocker.png"
                                        if int(e["hp"]) >= 3
                                        else "res://assets/games/dario/enemy_blocker_mad.png")
                        "spiky":
                                spr.modulate = Color(1.0, 0.5, 0.4) \
                                                if bool(e["spike_up"]) else Color.WHITE
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
        if String(e["kind"]) == "blocker" and int(e["hp"]) > 0:
                Jukebox.sfx("d_bosshit", -8.0, 1.3)
                _say("THE BLOCKER HOLDS! Hit it %d more times!" % int(e["hp"]), 1.4)
                return
        if int(e["hp"]) > 0:
                Jukebox.sfx("d_bosshit", -8.0, 1.3)
                return
        e["dead"] = true
        add_score(int(ENEMY_SCORE[String(e["kind"])]))
        Jukebox.sfx("d_stomp", -4.0)
        _sparkle(e["node"].position)
        var pts := int(ENEMY_SCORE[String(e["kind"])])
        _say("+%d" % pts, 0.8)
        achievement_count("stomped", 1)
        e["node"].queue_free()
        enemies.erase(e)

func _hurt_dario() -> void:
        if _phase != "play":
                return
        if power_shield:
                power_shield = false
                Jukebox.sfx("d_bump", -2.0)
                _say("THE SHIELD SHATTERED!", 1.6)
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
        _say("back to the start of this cursed level...", 2.0)
        _load_level(level_i)

# ============================================================ the projectiles

func _shoot(at: Vector2, e: Dictionary) -> void:
        var b := Sprite2D.new()
        b.texture = load("res://assets/games/dario/curse_bolt.png")
        b.position = at
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
                m["t"] += delta * float(m["spd"])
                var off := sin(float(m["t"])) * float(m["amp"])
                var n: Node2D = m["node"]
                if int(m["axis"]) == 0:
                        n.position.x = float(m["a"].x) + off
                else:
                        n.position.y = float(m["a"].y) + off
                # the carry: Dario rides when standing on top
                var top_y: float = n.position.y - 9.0
                if p_vel.y >= 0.0 \
                                and absf(p_node.position.x - n.position.x) < TILE * 1.35 \
                                and absf(p_node.position.y - top_y) < 16.0:
                        p_node.position.y = top_y
                        p_vel.y = 0.0
                        on_floor = true
                        if int(m["axis"]) == 0:
                                p_node.position.x += sin(float(m["t"])) * float(m["amp"]) \
                                                - float(m.get("last", float(m["a"].x) + off))
                        m["last"] = n.position.x

func _burners_tick(delta: float) -> void:
        for b in burners:
                var top_y: float = b["node"].position.y - 8.0
                if absf(p_node.position.x - b["node"].position.x) < TILE * 1.05 \
                                and absf(p_node.position.y - top_y) < 16.0:
                        b["heat"] = float(b["heat"]) + delta
                        if b["heat"] > 1.2:
                                b["heat"] = 0.0
                                _hurt_dario()
                        else:
                                on_floor = true
                                if p_vel.y > 0.0:
                                        p_vel.y = 0.0
                                        p_node.position.y = top_y
                else:
                        b["heat"] = maxf(0.0, float(b["heat"]) - delta * 2.0)

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

func _say(txt: String, secs: float) -> void:
        if pop_lbl != null and is_instance_valid(pop_lbl):
                pop_lbl.queue_free()
        pop_lbl = Arc.fit_label(txt, 24, Color(1, 1, 1), 640)
        pop_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        pop_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        var sb := Arc.panel_style(Color(0.08, 0.07, 0.1, 0.86), 18, 10)
        pop_lbl.add_theme_stylebox_override("normal", sb)
        pop_lbl.z_index = 50
        var vp := get_viewport_rect().size
        pop_lbl.position = Vector2((vp.x - 660.0) / 2.0, 150.0)
        pop_lbl.custom_minimum_size = Vector2(660, 0)
        _hud.add_child(pop_lbl)
        _pop_t = secs

func _story_pop(txt: String) -> void:
        if txt == "":
                return
        _say(txt, 10.0)

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
        node.position = _cell_center(cell) + Vector2(0, -40.0)
        var spr := Sprite2D.new()
        spr.texture = load("res://assets/games/dario/witcher.png")
        node.add_child(spr)
        ent_root.add_child(node)
        boss = {"node": node, "t": 0.0, "shoot_t": 1.6, "hop_t": 0.0}
        _say(WITCHER_LINE, 5.0)

func _boss_tick(delta: float) -> void:
        if boss.is_empty() or _phase != "play":
                return
        var n: Node2D = boss["node"]
        boss["t"] = float(boss["t"]) + delta
        n.position.x = 9.0 * TILE + sin(float(boss["t"]) * 0.9) * 4.0 * TILE
        n.position.y = 6.0 * TILE + sin(float(boss["t"]) * 1.7) * 30.0
        boss["shoot_t"] = float(boss["shoot_t"]) - delta
        if float(boss["shoot_t"]) <= 0.0:
                boss["shoot_t"] = _rng.randf_range(1.3, 2.0)
                for i in 2:
                        var b := Sprite2D.new()
                        b.texture = load("res://assets/games/dario/curse_bolt.png")
                        b.position = n.position
                        ent_root.add_child(b)
                        var dirv := (p_node.position - n.position).normalized()
                        bolts.append({"node": b,
                                "v": Vector2(dirv.x * 380.0, dirv.y * 380.0 - 40.0),
                                "life": 3.0, "witcher": true})
                Jukebox.sfx("d_curse", -5.0)
        # the stomp check
        if p_vel.y > 0.0 and n.position.distance_to(p_node.position) < 86.0 \
                        and p_node.position.y < n.position.y:
                p_vel.y = JUMP_V * 0.7
                boss_hp -= 2 if power_foot else 1
                Jukebox.sfx("d_bosshit", -4.0)
                _sparkle(n.position)
                _say("%d more!" % boss_hp, 1.0)
                if boss_hp <= 0:
                        add_score(BOSS_SCORE)
                        Jukebox.sfx("d_bossdie", -2.0)
                        _sparkle(n.position + Vector2(0, -40))
                        boss["node"].queue_free()
                        boss = {}
                        achievement_max("witcher", 1)
                        achievement_max("levels_done", 10)
                        _the_ending()
        elif n.position.distance_to(p_node.position) < 70.0:
                _hurt_dario()

func _the_ending() -> void:
        _phase = "ending"
        _end_t = 0.0
        _locked = false
        _say(ENDING_LINE, 2.6)

# ============================================================ plumbing

func _goga_input(_event: InputEvent) -> void:
        pass
