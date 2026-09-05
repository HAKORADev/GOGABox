extends GogaGame
## MATCHER - v0.3.3 PATCH 5, the donut-purge-and-real-mechanics round.
## THE PATCH 5 LAWS (the owner's patch-4 test report):
##  - THE DONUT PURGE: the pop burst sprites were the template zip's
##    DONUTS - every match wore a tiny donut funeral on the pure gem skin
##    (the owner: "when doing a correct match, it shows donuts, there is
##    something deep wrong with donuts i guess"). The pop frames are now
##    per-color gem-shatter bursts and the donut files are DELETED.
##  - THE SWEEPER SHADER SWAP (the owner: "see how the VFX/shader look
##    now? just swap them, that's it ... i mean the shader on the gem"):
##    the row and the column sweeper gem shaders traded bodies.
##  - THE FALL-AROUND LAW (jelly, the candy-crush school - the owner:
##    "the line next to the jelly line, in the empty grids, it will make
##    the gems fell to that side in an accurate way then that side will
##    get filled from top again"): gems resting on a jelly plug SLIDE
##    diagonally around it into the open seats beside, keep falling, and
##    the column refills from the top - no more airlocked pockets.
##  - THE RISE-MATCH LAW (butterflies): whatever three same gems line up
##    is a REAL match - by hand OR by a rise (the owner: "whatever three
##    same-gems are real valid match btw bruh"); a fly that rises into
##    its own color resolves on the spot. The "- one row per move"
##    widget words are dead ("this is shitty thing that we do not use in
##    our designing"). THE INTENSITY LADDER: the first hatch at 10s, the
##    gap drops 1s per 5 flies spawned, every hatch brings 1..4 flies.
##  - THE COIN COURTESY: a GOGACoin is TAPPABLE (tap = collect, the
##    30s clock restarts from the collect) and gems pass THROUGH it - a
##    drag across a coin carries the gem to the cell beyond, so a match
##    across a coin finally lands (the owner: "i want to move red gem
##    through it to do a match and go down").
##  - THE BANNER SKIN (the owner: "that visual asset when you give game
##    pop-ups is bad, that blue thing, remove it, keep just the text and
##    make it purple/pink so it fits the game style more"): the blue
##    ribbon is gone - the pop-ups speak as pure purple/pink text.
##  - THE MINE POCKETS LAW (the owner: "an area with no sand in same row,
##    it should let the gems fit in"): the earth is a per-CELL limit now
##    - gems fall into the dug holes, matches inside a hole dig deeper,
##    and THE RISE PUSHES THE WHOLE WORLD UP (dirt rows ride with the
##    board so the holes keep their places in the band; the old
##    new-line/full-line mixed bug is dead).
##  - THE RISKY PARCEL LAW (drop, the owner: "make the item if a move
##    happened and it did not moved down a single grid, makes it go up
##    by one grid, and make it risky because if it went up, and the next
##    move still up, the game ends"): a parcel that does not descend on
##    a move CLIMBS one row with a red warning; two climbs in a row and
##    the parcels climb away - the run ends.
## THE PATCH 4 LAWS (the physics-and-feel round; the owner's verdict on
## patch 3: "SFXs are good, VFXs needs more work, shaders needs real work,
## animation+physics needs remake, algorithms needs fucking redesign ...
## the game is still too simple"):
##  - THE HARD LIMIT LAW (diamond mine): gems fell INTO the sand - the
##    gravity write pen now clamps to playable rows; nothing goes through
##    the earth, for real.
##  - THE PHYSICS FALL LAW: every fall is a real free-fall integration
##    (velocity, gravity, a landing bounce + a squash) - no shortcut tweens;
##    the round opens on an EMPTY grid and the gems pour in column by
##    column (gems only - the jelly, ice, earth and parcels lay after).
##  - THE SKIN MEMORY LAW: the equipped skin is SAVED and RE-USED on the
##    next boot (the owner picked "saving the preference, much cooler").
##  - THE ONE-STEP LAW (butterflies): exactly ONE row per move - the x4
##    pace climb is dead.
##  - ICE STORM REBORN (the video's real design): a front spawns at the
##    bottom tile, RUNS UP continuously (tile by tile, no waiting), more
##    fronts join, a column that freezes to the top ends the run. A
##    HORIZONTAL match NEVER clears ice - the VERTICAL one wipes the
##    column's whole ice.
##  - THE SPREAD LAW (jelly): a dry move ALWAYS spreads 2..8 connected
##    cells (the owner: "it should be from 2-8 tiles ... from my tests it
##    spreads by 0-2?").
##  - THE NOVA LAW: color remover + color remover = GRID CLEAR - every gem
##    pops bottom-up, one damage on everything damageable, drop-down items
##    and the coin untouched.
##  - THE SPECIAL STAGE LAW: the sweeping removes SPREADING from the birth
##    cell both ways, the bomb SHAKES then radiates, the remover takes the
##    gems ONE BY ONE bottom-to-up - nothing is instant anymore. The bomb
##    power's dead "flame" call is dead too.
##  - CHALLENGE V4: a full GREEDY PRE-SOLVE plays the board move by move
##    before the round starts; the target is 86..97% of what optimal play
##    scores, the moves and the clock barely fit. Real numbers, real exam.
##  And the v0.3.3 laws still stand: THE OWNER'S SPECIAL TABLE (his words:
##  "the L or T is the bomb, the 4 vertical makes a horizontal line sweeper,
##  the 4 horizontal makes vertical one line sweeper, the +5 in a line
##  makes color remover") - the remover is swap-matched with any 3+ gem and
##  wipes its color bottom-to-up. Butterflies rise AFTER the move fully
##  resolves and a butterfly that touches the top row gets ONE move of
##  grace before the spider dines. Diamond Mine's earth is pure dirt.
##  CHALLENGE derives its rounds from a PRE-SOLVE of the fresh grid.
##  THREE EXTRA MODES: JELLY (the connected virus that eats gems, blocked
##  falls, clear it all on limited moves), ICE CRASH (layered ice 1-5, a
##  rock 6 only specials crack, gems pass through) and DROP DOWN (parcel
##  items ride gravity like the coin, three limit flavors).
## The board cells + backdrop + most SFX come from the owner's uploaded
## Match_3_Template zip; the in-game music is the zip's own track.
##
## THE OWNER LAWS this file obeys:
##  - "every single thing will be 1 score point, and the bonus will be /300"
##  - "make powerups be based on global GOGACoins and not round-balance"
##  - the shop: "CLEARLY A BUTTON AT THE TOP CALLED SHOP IN EVERY SINGLE GAME"
##    (never a row inside the optionals)
##  - "make it drop down like any normal thing ... when it is in the bottom,
##    it should be auto collected"
##  - "make a lose here takes -500 score points ... only in challenge mode"
##  - PEACE = the snake peace: 0 bonus, 0 coins, no power-ups, END in pause
##  - happy + welcoming atmosphere, vertical-only view, banner strip seated

const COLS := 8
const ROWS := 8
const COLORS := 5

## skins: base gem art per skin. The SPECIALS are a shader on the gem sprite
## (skin-safe by construction - the shader works on any texture). The donut
## skin wears the owner's Match_3_Template donuts + checker cells + backdrop.
const SKINS := {
        "gem": {"name": "Gem Vault", "price": 0,
                "tex": ["res://assets/games/matcher/gems/gem_0.png",
                        "res://assets/games/matcher/gems/gem_1.png",
                        "res://assets/games/matcher/gems/gem_2.png",
                        "res://assets/games/matcher/gems/gem_3.png",
                        "res://assets/games/matcher/gems/gem_4.png"]},
        "candy": {"name": "Candy Shop", "price": 220,
                "tex": ["res://assets/games/matcher/gems/candy_0.png",
                        "res://assets/games/matcher/gems/candy_1.png",
                        "res://assets/games/matcher/gems/candy_2.png",
                        "res://assets/games/matcher/gems/candy_3.png",
                        "res://assets/games/matcher/gems/candy_4.png"]},
        "donut": {"name": "Donut Den", "price": 280,
                "tex": ["res://assets/games/matcher/gems/donut_0.png",
                        "res://assets/games/matcher/gems/donut_1.png",
                        "res://assets/games/matcher/gems/donut_2.png",
                        "res://assets/games/matcher/gems/donut_3.png",
                        "res://assets/games/matcher/gems/donut_4.png"]},
}
const SKIN_ORDER := ["gem", "candy", "donut"]

## the eight modes (Bejeweled Classic shelf, renamed per the owner; the
## three v0.3.3-p3 additions follow the candy-crush school the owner asked for)
const MODES := {
        "challenge": {"name": "CHALLENGE", "price": 0,
                "card": "res://assets/games/matcher/modes/card_challenge.png",
                "line": "the analyzed rounds - a real exam now"},
        "peace": {"name": "PEACE", "price": 120,
                "card": "res://assets/games/matcher/modes/card_peace.png",
                "line": "zen - no fail, no coins, no rush"},
        "butterflies": {"name": "BUTTERFLIES", "price": 180,
                "card": "res://assets/games/matcher/modes/card_butterflies.png",
                "line": "save them before the spider dines"},
        "ice": {"name": "ICE STORM", "price": 240,
                "card": "res://assets/games/matcher/modes/card_ice.png",
                "line": "melt the rising frost or freeze"},
        "mine": {"name": "DIAMOND MINE", "price": 300,
                "card": "res://assets/games/matcher/modes/card_mine.png",
                "line": "dig deep, beat the clock"},
        "jelly": {"name": "JELLY", "price": 360,
                "card": "res://assets/games/matcher/modes/card_jelly.png",
                "line": "the sweet virus - eat it before it spreads"},
        "icecrash": {"name": "ICE CRASH", "price": 420,
                "card": "res://assets/games/matcher/modes/card_icecrash.png",
                "line": "shatter the layered ice to the last flake"},
        "drop": {"name": "DROP DOWN", "price": 480,
                "card": "res://assets/games/matcher/modes/card_drop.png",
                "line": "bring the parcels home, beat the limit"},
}
const MODE_ORDER := ["challenge", "peace", "butterflies", "ice", "mine",
                "jelly", "icecrash", "drop"]

## the bought power-ups (unlock once with the wallet; in-play stock pays the
## GLOBAL GOGACoins - the owner: "make powerups be based on global GOGACoins
## and not round-balance"). Cap 3 per run, the gray-out law stays.
const POWERS := {
        "shuffle": {"name": "Shuffle", "price": 100, "refill": 30,
                "icon": "res://assets/games/matcher/power/p_shuffle.png",
                "desc": "reshuffle the whole board"},
        "line": {"name": "Line Blast", "price": 150, "refill": 45,
                "icon": "res://assets/games/matcher/power/p_line.png",
                "desc": "tap a gem: its row and column blow"},
        "bomb": {"name": "Gem Bomb", "price": 200, "refill": 60,
                "icon": "res://assets/games/matcher/power/p_bomb.png",
                "desc": "tap any cell: a 3x3 blast"},
        "vapor": {"name": "Color Vapor", "price": 260, "refill": 80,
                "icon": "res://assets/games/matcher/power/p_vapor.png",
                "desc": "tap a gem: its whole color vanishes"},
}
const POWER_ORDER := ["shuffle", "line", "bomb", "vapor"]
const POWER_MAX := 3

const COIN_EVERY := 30.0        # the owner's rhythm - from last COLLECTED
# CHALLENGE - v0.3.3-p3: the PGB loss bank returns, now SHOWN (the owner:
# "does not show how many rounds won and how many lost ... how many losses
# until end"). v0.3.3-p4: the numbers come from a FULL GREEDY PRE-SOLVE -
# the target eats 86..97% of what optimal play scores (the owner: "there
# IS NO CHALLENGE at all, worth re-working ... you earlier did pong and
# snake and made them really hard")
const CH_LIVES := 5
const CH_MOVES_BASE := 13       # the round-1 move budget
const CH_MOVES_MIN := 8
const CH_TIGHT0 := 0.86         # the round-1 target share of achievable
const CH_TIGHT_MAX := 0.97
const CH_TIME_PER_MOVE0 := 3.3  # seconds per allowed move at round 1
const CH_TIME_PER_MOVE_MIN := 2.3

## the JELLY laws (the owner, v0.3.3-p4: "it should be from 2-8 tiles i
## guess per a match that does not destroy one of it, from my tests it
## spreads by 0-2?") - a dry move ALWAYS spreads 2..8 connected cells
const JELLY_SPREAD_MIN := 2
const JELLY_SPREAD_MAX := 8

## the BUTTERFLIES v5 laws (the owner, v0.3.3-p5: "there is no real
## progression or intensity there, it just spawns one butterfly after a
## long time then does not spawn more, it should spawn first after each
## 10 seconds for first 5 butterflies, then gets 9 for sixth and 8 for 10
## and 7 for 15 and like that with a range of 1-4 butterflies per spawn")
const FLY_GAP0 := 10.0           # the first hatches ride a 10s clock
const FLY_GAP_MIN := 3.0         # the ladder's floor
const FLY_SPAWN_MIN := 1         # every hatch brings 1..4 flies
const FLY_SPAWN_MAX := 4

## the ICE STORM v4 laws (the owner: "it spawns first in the tile at the
## bottom, then runs up, then another layer appear of running up then it
## freeze and the game is lost, you can modify the speed of each state")
const ICE_RISE0 := 0.62         # rows per second at the first front
const ICE_RISE_MAX := 1.2
const ICE_RISE_STEP := 0.05     # every new front runs a bit faster
const ICE_GAP0 := 7.0           # seconds between front spawns
const ICE_GAP_MIN := 3.5
const ICE_GAP_STEP := 0.5
const ICE_FRONTS_MAX := 3

## the ICE CRASH laws (the owner: "up to 5 layers ... level 6 makes it like a
## rock and requires a special thing to crash it down to level 5")
const ICE_CRASH_ROCK := 6

## the SPECIAL STAGE timings (v0.3.3-p4, the owner: "the special animations
## are non-existent at this point ... currently everything still feels
## instant") - the pops ride the effect, nothing pops before its wave
const SWEEP_T := 0.44           # a sweeper bar crosses the board in this
const SWEEP_CELL_T := 0.055     # per-cell delay step of the spreading sweep
const BOMB_RING_T := 0.075      # per ring of the bomb crater
const REMOVER_ROW_T := 0.085    # the remover's per-row climb (one by one)
const REMOVER_CELL_T := 0.014   # the tiny per-cell ripple inside a row
const NOVA_ROW_T := 0.07        # the supernova grid-clear climb

## the PHYSICS FALL laws (v0.3.3-p4, the owner: "switch the game to be
## physical-based ... so things disappear and fade-in/out and drop and move
## physically instead of these weird shortcutting")
const FALL_G := 4300.0          # px/s^2
const FALL_REST := 0.17         # the landing bounce restitution
const FALL_BOUNCE_V := 430.0    # below this impact speed the fall settles

## the DROP laws (the owner: "the round will start with 1-5 items at the top
## line ... it will use both moves and timing or one of them as a limit, so
## there is 3 possibilities")
# DIAMOND MINE - the owner's Bejeweled-Classic spec: "each specific like 25
# seconds it makes another row and clearing a row gives extra 25 seconds and
# the round starts with 60 seconds and some times it make two rows"
const MINE_CLOCK := 60.0        # the dig clock starts at 60s
const MINE_ROW_TIME := 25.0     # a new earth row every 25s...
const MINE_ROW_BONUS := 25.0    # ...and a cleared row pays +25s
const MINE_DOUBLE := 0.25       # ...sometimes two rows at once

# ------------------------------------------------------------ state
var skin := "gem"
var mode := "challenge"
var phase := "pick"             # pick -> play (over = the base's flag)
var busy := false               # a resolve/cascade is on the rails
var grid := []                  # ROWS x COLS of cell dicts
var cell_px := 112.0
var board_o := Vector2.ZERO     # board origin (top-left cell corner)

var cascade := 0
var hinted := []                # the two hint cells (pulse)
var idle_clock := 0.0
var move_pops := 0              # gems popped during the current move (the
                                # drop mode's spawn-after-match feed)

## mode state
var run_clock := 300.0
var round_no := 0
var round_goal := 60
var round_bank := 0             # score banked into the current round
var round_clock := 0.0
var round_time := 60.0
var round_start := 0
var twist := ""                 # "" | "drought" | "rush"
var drought_color := -1
var rush_left := 0.0
var pace := 1                   # butterflies: rows per move - ALWAYS 1 now
                                # (v0.3.3-p4 THE ONE-STEP LAW: the owner saw
                                # "one move makes butterflies goes up by 4
                                # grid areas??? WTF is that")
var frost := [0, 0, 0, 0, 0, 0, 0, 0]  # ice v4: SOLID segments per column
var fronts := []                # ice v4: the live fronts [{col, f, speed}]
var front_clock := 3.0          # the first front spawns fast
var front_gap := ICE_GAP0
var front_count := 0            # fronts spawned this run (the ramp)
var temp := 0.0                 # the temperature gauge (0..1)
var melt_chain := 0.0           # consecutive melts within 3s
var dig_clock := MINE_CLOCK
var mine_rise_clock := MINE_ROW_TIME   # the 25s earth-row clock
var mine_rising := false               # a rise is on the rails (the busy gate)
var depth := 0                  # earth rows cleared (meters descended)
var earth_top := ROWS           # mine: the first earth row (ROWS = no earth)
var earth := []                 # earth rows: earth[r] = [{kind, hp, tr, node, tr_spr}]

## challenge v3: the shown score + the derived rounds
var ch_lives := CH_LIVES
var ch_wins := 0
var ch_losses := 0
var round_moves := 0            # moves spent inside the current round
var round_moves_max := 16       # derived from the pre-solve
var goal_color := -1            # the bonus color quota (-1 = none)
var goal_color_left := 0
var goal_special := ""          # the bonus craft goal (""|"bomb"|"sweep"|"hyper")
var goal_special_done := false

## jelly state: jelly[key] = true; the cell itself holds NO gem (eaten)
var jelly := {}
var jelly_level := 1
var jelly_moves := 24
var jelly_cleared_move := 0     # jelly cells cleared during the current move

## ice-crash state: icel[key] = level 1..6
var icel := {}
var icr_level := 1
var icr_moves := 24
var icr_hit_move := 0

## drop state
var drop_total := 5             # items to deliver this round
var drop_left := 5              # still to deliver (spawn queue included)
var drop_limit_kind := "moves"  # moves | time | both
var drop_moves := 22
var drop_time := 75.0
var drop_items := []            # [{r, c}] live parcels (the grid holds color -2 cells)
var drop_seq := 0               # the parcel id issuer (the rise tracking)
var drop_prev := {}             # drop_id -> row at the move's start

## the coin
var coin_clock := COIN_EVERY
var coin_cell := Vector2i(-1, -1)
var _coin_refill_pending := false

## powers
var charges := {"shuffle": 0, "line": 0, "bomb": 0, "vapor": 0}
var power_used := {"shuffle": 0, "line": 0, "bomb": 0, "vapor": 0}
var armed := ""
var _wave_o := Vector2(-1, -1)  # the tapped origin of the current power wave
var _wave_bottomup := false     # the vapor wipes climb bottom-to-up

## fx pools
var pops := []                  # burst particles {pos, vel, life, max, r, col}
var rings := []                 # shock rings {pos, r, life, max, col, w}
var beams := []                 # star beams {a, b, life, max}
var zaps := []                  # hypercube arcs {a, b, life, max}
var floaters := []              # score texts {pos, txt, life, max, col, size}
var sweeps := []                # sweeper bars {axis, idx, from_i, t, max, col}
var shake := 0.0                # the bomb shake (decays in _tick_fx)
var wipes := []                 # color-remover rising shimmer rows {row, t, max, col}
var _bodies := []               # THE PHYSICS FALLS {node, vel, ty, hold, bounced, land_sfx}

## ui refs
var world: Node2D
var bg_spr: Sprite2D
var rail: Control               # the power-up rail (BoxScroll)
var rail_slots := {}            # power id -> {btn, dots, price}
var chip_mode: Label
var chip_info: Label
var chip_info2: Label
var pick_open := false
var first_moment := true        # the boot optionals owns the first tap
var armed_cursor: Sprite2D
var spider: Sprite2D            # butterflies: the hunter on the top rail
var spider_tw: Tween
var wallet_chip: PanelContainer # the buy popup's live full-balance chip

var tex_gem: Array = []
var _tex := {}                  # lazily loaded aux textures


func _skin_textures() -> Array:
        var out := []
        for p in SKINS[skin]["tex"]:
                out.append(load(p))
        return out


func _t(key: String) -> Texture2D:
        if not _tex.has(key):
                var paths := {
                        "coin": "res://assets/ui/coin.png",
                        "cell": "res://assets/games/matcher/bg/cell.png",
                        "cell_donut0": "res://assets/games/matcher/bg/cell_donut_light.png",
                        "cell_donut1": "res://assets/games/matcher/bg/cell_donut_dark.png",
                        "plate": "res://assets/games/matcher/bg/plate.png",
                        "banner": "res://assets/games/matcher/fx/banner.png",
                        "wing": "res://assets/games/matcher/modes/butterfly.png",
                        "spider": "res://assets/games/matcher/modes/spider.png",
                        "iceb": "res://assets/games/matcher/modes/ice_block.png",
                        "icebt": "res://assets/games/matcher/modes/ice_block_top.png",
                        "earth": "res://assets/games/matcher/modes/earth.png",
                        "dirt": "res://assets/games/matcher/modes/earth.png",
                        "clay": "res://assets/games/matcher/modes/earth_clay.png",
                        "rock": "res://assets/games/matcher/modes/earth_rock.png",
                        "gold": "res://assets/games/matcher/modes/gold.png",
                        "diamond": "res://assets/games/matcher/modes/diamond.png",
                        "artifact": "res://assets/games/matcher/modes/artifact.png",
                        "jelly": "res://assets/games/matcher/modes/jelly.png",
                        "parcel": "res://assets/games/matcher/modes/item_parcel.png",
                        "popfx": "res://assets/games/matcher/fx/popfx_0.png",
                        "exp0": "res://assets/games/matcher/fx/explosion_0.png",
                        "exp1": "res://assets/games/matcher/fx/explosion_1.png",
                        "exp2": "res://assets/games/matcher/fx/explosion_2.png",
                        "exp3": "res://assets/games/matcher/fx/explosion_3.png",
                        "exp4": "res://assets/games/matcher/fx/explosion_4.png",
                        "exp5": "res://assets/games/matcher/fx/explosion_5.png",
                        "exp6": "res://assets/games/matcher/fx/explosion_6.png",
                        "exp7": "res://assets/games/matcher/fx/explosion_7.png",
                }
                _tex[key] = load(paths[key])
        return _tex[key]


func _t_icec(lvl: int) -> Texture2D:
        var k := "icec%d" % clampi(lvl, 1, 6)
        if not _tex.has(k):
                _tex[k] = load("res://assets/games/matcher/modes/icec_%d.png" % clampi(lvl, 1, 6))
        return _tex[k]


func _t_popfx(i: int) -> Texture2D:
        # v0.3.3-p5 THE DONUT PURGE: only the five per-color frames exist
        # (the template zip's donut frames are deleted - the owner: "there
        # is something deep wrong with donuts i guess")
        var idx := clampi(i, 0, 4)
        var k := "popfx%d" % idx
        if not _tex.has(k):
                _tex[k] = load("res://assets/games/matcher/fx/popfx_%d.png" % idx)
        return _tex[k]

## the specials shader - one material per cell, ON the gem sprite (the owner:
## "like a shader on the asset")
var _special_shader: Shader

func _special_mat(kind: String) -> ShaderMaterial:
        if _special_shader == null:
                _special_shader = load("res://assets/games/matcher/specials/special.gdshader")
        var m := ShaderMaterial.new()
        m.shader = _special_shader
        # the shader kinds: 1 bomb - 2 row sweeper - 3 col sweeper - 4 remover
        m.set_shader_parameter("special",
                        1 if kind == "bomb" else (2 if kind == "rowh" \
                        else (3 if kind == "colv" else 4)))
        return m


## v0.3.3-p2 THE WING BAKE: a butterfly's wings are COMPOSED INTO its own
## texture (gem art + the monarch sheet) - the sprite moves as one thing,
## so nothing can ever desync or overlap again (the owner's "flies corrupt
## the line and overlap things" bug died with the separate overlay node).
var _wing_bake := {}     # (skin|color) -> ImageTexture

func _cell_texture(color: int, wing: bool) -> Texture2D:
        var base: Texture2D = tex_gem[color % tex_gem.size()]
        if not wing:
                return base
        var key := "%s|%d" % [skin, color]
        if _wing_bake.has(key):
                return _wing_bake[key]
        var img: Image = base.get_image()
        if img == null:
                return base
        if img.is_compressed():
                img.decompress()
        img.convert(Image.FORMAT_RGBA8)
        var wing_img: Image = (_t("wing") as Texture2D).get_image()
        if wing_img != null:
                if wing_img.is_compressed():
                        wing_img.decompress()
                wing_img.convert(Image.FORMAT_RGBA8)
                # scale the wing sheet onto the gem square, centered
                var size := img.get_width()
                var wimg := Image.create(size, size, false, Image.FORMAT_RGBA8)
                wimg.fill(Color(0, 0, 0, 0))
                var scale_f := float(size) / float(wing_img.get_width()) * 1.15
                var dw := int(wing_img.get_width() * scale_f)
                var dh := int(wing_img.get_height() * scale_f)
                wing_img.resize(dw, dh, Image.INTERPOLATE_LANCZOS)
                var ox := (size - dw) / 2
                var oy := (size - dh) / 2
                wimg.blend_rect(wing_img, Rect2i(0, 0, dw, dh), Vector2i(ox, oy))
                img.blend_rect(wimg, Rect2i(0, 0, size, size), Vector2i(0, 0))
        var tex := ImageTexture.create_from_image(img)
        _wing_bake[key] = tex
        return tex


func _retexture_cell(r: int, c: int) -> void:
        var cell: Dictionary = grid[r][c]
        if cell.is_empty() or not is_instance_valid(cell.get("node")):
                return
        var n: Sprite2D = cell["node"]
        if _is_coin(cell):
                n.texture = _t("coin")
                return
        n.texture = _cell_texture(int(cell["color"]), bool(cell.get("wing", false)))
        _dress_special(r, c)


## THE TOP BANNER (v0.3.3-p2, the owner: a lose/round message "appears inside
## the grid and not somewhere at the top as example"). v0.3.3-p5 THE BANNER
## SKIN: the blue ribbon asset is DEAD (the owner: "that visual asset when
## you give game pop-ups is bad, that blue thing, remove it, keep just the
## text and make it purple/pink so it fits the game style more") - the
## message speaks as pure text, purple for the bad news, pink for the good.
func _banner(txt: String, good := true) -> void:
        var root := _overlay_root_ref()
        var holder := Control.new()
        holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
        holder.set_anchors_preset(Control.PRESET_TOP_WIDE)
        holder.offset_top = 186.0
        holder.offset_bottom = 276.0
        root.add_child(holder)
        var l := Arc.fit_label(txt, 34,
                        Color("e0559b") if good else Color("a44ad0"), 640)
        l.set_anchors_preset(Control.PRESET_FULL_RECT)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        # the soft dark under-shadow keeps it readable on any sky
        var sh := Arc.fit_label(txt, Arc.fit_size(txt, 34, 640, null, true),
                        Color(0.08, 0.03, 0.12, 0.85), 640)
        sh.set_anchors_preset(Control.PRESET_FULL_RECT)
        sh.offset_left = 3
        sh.offset_top = 3
        sh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sh.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
        sh.modulate.a = 0.0
        holder.add_child(sh)
        l.modulate.a = 0.0
        holder.add_child(l)
        l.scale = Vector2.ONE * 0.86
        l.pivot_offset = Vector2(320, 45)
        var tw := holder.create_tween()
        tw.set_parallel(true)
        tw.tween_property(sh, "modulate:a", 1.0, 0.22)
        tw.tween_property(l, "modulate:a", 1.0, 0.22)
        tw.tween_property(l, "scale", Vector2.ONE, 0.26) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.chain().tween_interval(1.15)
        tw.chain().tween_property(holder, "modulate:a", 0.0, 0.3)
        tw.chain().tween_callback(holder.queue_free)


# ================================================================ setup
## THE UNFREEZE LAW (the invaders defend-freeze class): the picker and the
## power sheets pause the whole tree. If the host tears the game down while
## a sheet lives (quit from the box, the run-end flow), the tree would stay
## paused FOREVER - the box frozen under a dead game. Exiting always thaws.
func _exit_tree() -> void:
        get_tree().paused = false


func _goga_setup() -> void:
        # THE SKIN MEMORY LAW (v0.3.3-p4, the owner: "when changing skin, then
        # quit game then return, it defaults the default skin ... a fix could
        # be save the last used skin and re-use it ... i may go with saving
        # the preference, much cooler"): patch 3 READ a progress key that was
        # never WRITTEN - the boot always wore the default while equip_skin
        # saved under skins.on. Both keys now travel together.
        var saved := String(Box.get_progress(game_id, "skin", ""))
        if saved == "" or not SKINS.has(saved):
                saved = String(Box.skin_on(game_id))
        if saved == "" or not SKINS.has(saved):
                saved = "gem"
        skin = saved
        Box.set_progress(game_id, "skin", skin)   # keep both keys honest
        tex_gem = _skin_textures()
        bonus_div_override = 300       # the owner: "the bonus will be /300"
        if mode == "peace":
                score_bonus_enabled = false
                pause_end_run = true
        var vp := get_viewport_rect().size
        cell_px = floorf(minf((vp.x - 88.0) / float(COLS), (vp.y * 0.42) / float(ROWS)))
        world = Node2D.new()
        add_child(world)
        _build_background(vp)
        _build_board_plate()
        _build_hud_extras()
        _build_spider()
        _build_rail()
        _ready_input()
        # THE UNIVERSAL SHOP BUTTON (the owner: "the shop IS CLEARLY A BUTTON
        # AT THE TOP CALLED SHOP IN EVERY SINGLE GAME") - the optionals sheet
        # never sells again
        add_hud_button("SHOP", func(): _shop_open())
        Jukebox.music("res://assets/audio/music/matcher_game.mp3")
        _pick_open(true)


func _build_background(vp: Vector2) -> void:
        # v0.3.3-p3 THE TEMPLATE DEFAULT (the owner: the zip "has grid assets
        # and background ... using it as the default will be cooler"): the
        # template backdrop IS the default look now; peace keeps its pastel sky
        var path := "res://assets/games/matcher/bg/bg_tpl.png"
        if mode == "peace":
                path = "res://assets/games/matcher/bg/bg_peace.png"
        bg_spr = Sprite2D.new()
        bg_spr.texture = load(path)
        var ts := Vector2(vp.x / bg_spr.texture.get_width(), vp.y / bg_spr.texture.get_height())
        bg_spr.scale = Vector2.ONE * maxf(ts.x, ts.y)
        bg_spr.position = vp / 2.0
        bg_spr.z_index = -20
        world.add_child(bg_spr)


func _board_pixel() -> Vector2:
        return Vector2(COLS, ROWS) * cell_px


func _cell_pos(r: int, c: int) -> Vector2:
        return board_o + Vector2(float(c) + 0.5, float(r) + 0.5) * cell_px


func _pos_to_cell(p: Vector2) -> Vector2i:
        var f := (p - board_o) / cell_px
        var c := int(floorf(f.x))
        var r := int(floorf(f.y))
        if r < 0 or c < 0 or r >= ROWS or c >= COLS:
                return Vector2i(-1, -1)
        return Vector2i(r, c)


func _build_board_plate() -> void:
        var vp := get_viewport_rect().size
        var bp := _board_pixel()
        board_o = Vector2((vp.x - bp.x) * 0.5, clampf(vp.y * 0.30, 330.0, vp.y - bp.y - banner_bottom() - 300.0))
        var plate := Sprite2D.new()
        plate.texture = _t("plate")
        plate.centered = false
        plate.position = board_o - Vector2(12, 12)
        plate.scale = Vector2.ONE * cell_px / 120.0
        plate.z_index = -10
        world.add_child(plate)
        var checker: Array = [
                load("res://assets/games/matcher/bg/cell_tpl_light.png"),
                load("res://assets/games/matcher/bg/cell_tpl_dark.png")]
        for r in ROWS:
                for c in COLS:
                        var cell := Sprite2D.new()
                        cell.texture = checker[(r + c) % 2]
                        cell.centered = false
                        cell.position = board_o + Vector2(c, r) * cell_px
                        cell.scale = Vector2.ONE * cell_px / 120.0
                        cell.z_index = -8
                        world.add_child(cell)


func _build_hud_extras() -> void:
        # v0.3.3-p2 THE NOTCH LAW (the owner: "move the widgets under the
        # GOGACoins row ... they behind the physical front camera, make it go
        # down"): the top bar sits LOWER (clears the camera cutout) and the
        # mode chips get their OWN second row under it
        if _hud_row != null and is_instance_valid(_hud_row):
                _hud_row.offset_top = 44.0
                _hud_row.offset_bottom = 108.0
        var row2 := HBoxContainer.new()
        row2.set_anchors_preset(Control.PRESET_TOP_WIDE)
        row2.offset_left = 14
        row2.offset_right = -14
        row2.offset_top = 116.0
        row2.offset_bottom = 170.0
        row2.alignment = BoxContainer.ALIGNMENT_CENTER
        row2.add_theme_constant_override("separation", 10)
        row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hud.add_child(row2)
        var cm := Arc.chip("", "", Color(0, 0, 0, 0.4), 22, Arc.CARD)
        var ci := Arc.chip("", "", Color(0, 0, 0, 0.4), 22, Arc.CARD)
        var ci2 := Arc.chip("", "", Color(0, 0, 0, 0.4), 22, Arc.CARD)
        row2.add_child(cm)
        row2.add_child(ci)
        row2.add_child(ci2)
        chip_mode = cm.get_child(0).get_child(cm.get_child(0).get_child_count() - 1)
        chip_info = ci.get_child(0).get_child(ci.get_child(0).get_child_count() - 1)
        chip_info2 = ci2.get_child(0).get_child(ci2.get_child(0).get_child_count() - 1)
        _refresh_hud()


func _build_spider() -> void:
        if spider != null and is_instance_valid(spider):
                spider.queue_free()
        spider = null
        if mode != "butterflies":
                return
        var sp := Sprite2D.new()
        sp.texture = _t("spider")
        sp.position = Vector2(board_o.x + _board_pixel().x * 0.5, board_o.y - 92)
        sp.scale = Vector2.ONE * (cell_px / 160.0) * 1.3
        sp.z_index = 12
        world.add_child(sp)
        spider = sp


# ================================================================ the optionals
## THE OPTIONALS SCREEN (v0.3.3-p2 THE UNIVERSAL SHAPE): one scrollable
## sheet, one IMAGE box per mood, the skins row - and NO SHOP ROW (the
## owner: "it should not has the shop there, the shop IS CLEARLY A BUTTON AT
## THE TOP CALLED SHOP IN EVERY SINGLE GAME"). It rides the base sheet
## stack, never pauses the tree (the phase gates the play), so the HUD back
## button and the Android back CLOSE it - the owner's dead-back report.

func _pick_open(first := false) -> void:
        if pick_open:
                return
        pick_open = true
        var sheet := sheet_push(0.0, "pick")
        var title := Arc.fit_label("OPTIONALS - THE MOOD SHELF", 34, Arc.HOT, 560)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(title)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(620, clampf(vp.y * 0.5, 340.0, 700.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 10)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        var grid := GridContainer.new()
        grid.columns = 2
        grid.add_theme_constant_override("h_separation", 12)
        grid.add_theme_constant_override("v_separation", 12)
        grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        box.add_child(grid)
        for id in MODE_ORDER:
                grid.add_child(_pick_card(id))
        var st := Arc.fit_label("THE SKINS - THE GEMS YOU MATCH WITH", 20, Arc.HOT, 560)
        st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(st)
        var skinrow := HBoxContainer.new()
        skinrow.alignment = BoxContainer.ALIGNMENT_CENTER
        skinrow.add_theme_constant_override("separation", 10)
        skinrow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        box.add_child(skinrow)
        for sid in SKIN_ORDER:
                skinrow.add_child(_skin_chip(sid))
        var cb := Arc.button("TO THE BOARD" if first_moment else "CLOSE",
                        Vector2(0, 78), 26, Arc.GOOD, func():
                        var go := first_moment and phase != "play"
                        _pick_close()
                        if go:
                                _start_mode(mode))
        cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        box.add_child(cb)
        _pick_finish(sc)


func _pick_finish(sc: BoxScroll) -> void:
        # THE TAPPABLE LAW: BoxScroll owns taps inside scrolls - an
        # unregistered button never fires (the old picker's dead taps)
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))


func _pick_card(id: String) -> Button:
        var m: Dictionary = MODES[id]
        var owned: bool = int(m["price"]) == 0 or Box.item_owned(game_id, "modes", id)
        var on: bool = mode == id and owned
        var b := Button.new()
        b.custom_minimum_size = Vector2(292, 214)
        var sb := Arc.panel_style(Arc.CARD if owned else Color(0.86, 0.82, 0.74, 0.96), 20, 6)
        if on:
                sb.set_border_width_all(4)
                sb.border_color = Arc.GOOD
        b.add_theme_stylebox_override("normal", sb)
        var sbp := sb.duplicate() as StyleBoxFlat
        sbp.bg_color = sbp.bg_color.darkened(0.05)
        b.add_theme_stylebox_override("pressed", sbp)
        var v := VBoxContainer.new()
        v.set_anchors_preset(Control.PRESET_FULL_RECT)
        v.offset_left = 10
        v.offset_right = -10
        v.offset_top = 10
        v.offset_bottom = -8
        v.mouse_filter = Control.MOUSE_FILTER_IGNORE
        v.add_theme_constant_override("separation", 4)
        b.add_child(v)
        var art := TextureRect.new()
        art.texture = load(String(m["card"]))
        art.custom_minimum_size = Vector2(260, 112)
        art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        art.mouse_filter = Control.MOUSE_FILTER_IGNORE
        if not owned:
                art.modulate = Color(1, 1, 1, 0.5)
        v.add_child(art)
        var l := Arc.fit_label(String(m["name"]), 24, Arc.INK, 272)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        v.add_child(l)
        if owned:
                var st := Arc.fit_label("PICKED - TAP TO PLAY" if on else "TAP TO PLAY",
                                16, Color("2c8a44"), 272)
                st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                st.mouse_filter = Control.MOUSE_FILTER_IGNORE
                v.add_child(st)
                # THE START LAW (the owner: "whenever I select something, the
                # game does not start"): an owned mood ALWAYS starts on tap -
                # the picked card included
                b.pressed.connect(func():
                                Jukebox.sfx("confirm", -4.0)
                                _pick_close()
                                _start_mode(id))
        else:
                var chip := Arc.chip(str(int(m["price"])), "res://assets/ui/coin.png",
                                Color(0, 0, 0, 0.5), 16, Arc.COIN)
                chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
                chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
                v.add_child(chip)
                # THE SNAKE LAW: a locked box's tap opens the shop
                b.pressed.connect(func(): _shop_open())
        return b


func _skin_chip(sid: String) -> Button:
        var s: Dictionary = SKINS[sid]
        var owned: bool = int(s["price"]) == 0 or Box.skin_owned(game_id, sid)
        var on := skin == sid and owned
        var b := Button.new()
        b.custom_minimum_size = Vector2(290, 84)
        var sb := Arc.panel_style(Arc.CARD_2 if owned else Color(0.85, 0.8, 0.72, 0.95), 16, 4)
        if on:
                sb.set_border_width_all(3)
                sb.border_color = Arc.GOOD
        b.add_theme_stylebox_override("normal", sb)
        var sbp := sb.duplicate() as StyleBoxFlat
        sbp.bg_color = sbp.bg_color.darkened(0.05)
        b.add_theme_stylebox_override("pressed", sbp)
        var h := HBoxContainer.new()
        h.set_anchors_preset(Control.PRESET_FULL_RECT)
        h.offset_left = 12
        h.offset_right = -12
        h.mouse_filter = Control.MOUSE_FILTER_IGNORE
        h.add_theme_constant_override("separation", 10)
        b.add_child(h)
        var ic := TextureRect.new()
        ic.texture = load(String(s["tex"][0]))
        ic.custom_minimum_size = Vector2(52, 52)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        h.add_child(ic)
        # v0.3.3-p3 (the owner: "make the skins just show the names and the
        # highlight on the in-use one and remove the text of 'on' or tap to
        # use, these are not in my design plannings at all"): the NAME ONLY -
        # the green border IS the in-use highlight (locked skins keep the
        # price chip so the shop walk still makes sense)
        var txt := String(s["name"])
        if not owned:
                txt += "  %d" % int(s["price"])
        var l := Arc.fit_label(txt, 20, Arc.INK, 210)
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        h.add_child(l)
        if on:
                b.disabled = true
        elif owned:
                b.pressed.connect(func(): _pick_equip_skin(sid))
        else:
                b.pressed.connect(func(): _shop_open())
        return b


func _pick_equip_skin(sid: String) -> void:
        # THE SKIN MEMORY LAW: the free default never lives in skins.owned,
        # so Box.equip_skin silently refused it - the preference now rides
        # the progress key (always written), skins.on rides along when owned
        skin = sid
        Box.set_progress(game_id, "skin", sid)
        if Box.skin_owned(game_id, sid):
                Box.equip_skin(game_id, sid)
        _refresh_board_skin()
        Jukebox.sfx("confirm", -3.0)
        _pick_rebuild()


## the stack-safe rebuild: the live optionals pops, a fresh one pushes
func _pick_rebuild() -> void:
        _pick_down()
        _pick_open(false)


func _pick_close() -> void:
        _pick_down()


func _pick_down() -> void:
        if not pick_open:
                return
        pick_open = false
        sheet_pop()


## the base closed a sheet for us (the back button) - keep the flags honest
func _goga_sheet_popped(id: String) -> void:
        match id:
                "pick":
                        pick_open = false
                "power":
                        wallet_chip = null


# ================================================================ the shop
## THE SHOP (v0.3.3-p2): the HUD's top SHOP button is its only door. It
## pushes ON TOP of whatever is live (the optionals stays beneath it and
## comes back on close - the stack owns the layering), never pauses the
## tree, and every rebuild is pop-then-push (no orphan dims). Every price
## is paid from the FULL GOGABox wallet.

func _shop_open() -> void:
        var sheet := sheet_push(0.0, "shop")
        var title := Arc.fit_label("MATCHER SHOP", 34, Arc.INK, 560)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(title)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(620, clampf(vp.y * 0.5, 340.0, 700.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        var sec := Arc.fit_label("THE MOODS - BUY ONE, PICK IT IN OPTIONALS", 20, Arc.HOT, 560)
        sec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(sec)
        for id in MODE_ORDER:
                box.add_child(_shop_mode_row(id))
        var sec2 := Arc.fit_label("THE SKINS", 20, Arc.HOT, 560)
        sec2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(sec2)
        box.add_child(_shop_skin_row("candy"))
        box.add_child(_shop_skin_row("donut"))
        var sec3 := Arc.fit_label("THE POWERS - UNLOCK ONCE, STOCK IN PLAY", 20, Arc.HOT, 560)
        sec3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(sec3)
        for pid in POWER_ORDER:
                box.add_child(_shop_power_row(pid))
        var cb := Arc.button("CLOSE", Vector2(0, 74), 24, Arc.GOOD, func(): _shop_close())
        cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        box.add_child(cb)
        _pick_finish(sc)


## the stack-safe rebuild: the live shop pops, a fresh one pushes
func _shop_rebuild() -> void:
        _shop_down()
        _shop_open()


func _shop_mode_row(id: String) -> Control:
        var m: Dictionary = MODES[id]
        if int(m["price"]) == 0 or Box.item_owned(game_id, "modes", id):
                var l := Arc.fit_label("%s  -  OWNED" % String(m["name"]).to_upper(),
                                20, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        var b := Arc.coin_button("%s  -  %d" % [String(m["name"]).to_upper(), int(m["price"])],
                        Vector2(0, 64), 22, Color("8a4ab8"), func():
                        if Box.buy_item(game_id, "modes", id, int(m["price"])):
                                Jukebox.sfx("m_goal", -4.0)
                                Arc.confetti(_overlay_root_ref(), get_viewport_rect().size / 2.0, 30)
                        else:
                                Jukebox.sfx("error", -6.0)
                                _toast_show("need %d more coins" %
                                                (int(m["price"]) - Box.coins()))
                        _shop_rebuild())
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        if Box.coins() < int(m["price"]):
                b.disabled = true
        return b


func _shop_skin_row(sid: String) -> Control:
        var s: Dictionary = SKINS[sid]
        if Box.skin_owned(game_id, sid) or int(s["price"]) == 0:
                var l := Arc.fit_label("%s  -  OWNED (WEAR IT IN OPTIONALS)" % String(s["name"]).to_upper(),
                                20, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        var b := Arc.coin_button("%s  -  %d" % [String(s["name"]).to_upper(), int(s["price"])],
                        Vector2(0, 64), 22, Color("c45a9a"), func():
                        if Box.buy_skin(game_id, sid, int(s["price"])):
                                skin = sid
                                Box.set_progress(game_id, "skin", sid)
                                _refresh_board_skin()
                                Jukebox.sfx("m_goal", -4.0)
                                Arc.confetti(_overlay_root_ref(), get_viewport_rect().size / 2.0, 30)
                        else:
                                Jukebox.sfx("error", -6.0)
                                _toast_show("need %d more coins" %
                                                (int(s["price"]) - Box.coins()))
                        _shop_rebuild())
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        if Box.coins() < int(s["price"]):
                b.disabled = true
        return b


func _shop_power_row(pid: String) -> Control:
        var p: Dictionary = POWERS[pid]
        if Box.item_owned(game_id, "power", pid):
                var l := Arc.fit_label("%s  -  OWNED" % String(p["name"]).to_upper(),
                                20, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        var b := Arc.coin_button("%s  -  %d" % [String(p["name"]).to_upper(), int(p["price"])],
                        Vector2(0, 64), 22, Color("4a7ab8"), func():
                        if Box.buy_item(game_id, "power", pid, int(p["price"])):
                                Jukebox.sfx("m_goal", -4.0)
                                Arc.confetti(_overlay_root_ref(), get_viewport_rect().size / 2.0, 30)
                                _refresh_rail()
                        else:
                                Jukebox.sfx("error", -6.0)
                                _toast_show("need %d more coins" %
                                                (int(p["price"]) - Box.coins()))
                        _shop_rebuild())
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        if Box.coins() < int(p["price"]):
                b.disabled = true
        return b


func _shop_close() -> void:
        _shop_down()


func _shop_down() -> void:
        sheet_pop()


func _refresh_board_skin() -> void:
        tex_gem = _skin_textures()
        # THE EMPTY-BOARD LAW (v0.3.3-p1): the optionals lives BEFORE the
        # first deal - a skin bought there must not index an unborn grid
        # (the old index error killed the callback mid-sheet and the paused
        # tree froze the app = the owner's "the app crashed")
        for r in ROWS:
                if grid.size() <= r:
                        return
                for c in COLS:
                        if grid[r].size() <= c:
                                continue
                        if _earth_at(r, c):
                                continue
                        var cell: Dictionary = grid[r][c]
                        if cell.is_empty() or int(cell.get("color", -1)) < 0:
                                continue
                        var n: Sprite2D = cell["node"]
                        n.texture = _cell_texture(int(cell["color"]), bool(cell.get("wing", false)))


# ================================================================ mode start
func _start_mode(id: String) -> void:
        mode = id
        first_moment = false
        phase = "play"
        chip_mode.text = String(MODES[id]["name"])
        pace = 1                       # THE ONE-STEP LAW - forever 1
        frost = [0, 0, 0, 0, 0, 0, 0, 0]
        fronts = []
        front_clock = 2.5
        front_gap = ICE_GAP0
        front_count = 0
        temp = 0.0
        dig_clock = MINE_CLOCK
        mine_rise_clock = MINE_ROW_TIME
        mine_rising = false
        depth = 0
        earth_top = ROWS
        coin_clock = COIN_EVERY
        coin_cell = Vector2i(-1, -1)
        charges = {"shuffle": 0, "line": 0, "bomb": 0, "vapor": 0}
        power_used = {"shuffle": 0, "line": 0, "bomb": 0, "vapor": 0}
        armed = ""
        if mode == "peace":
                score_bonus_enabled = false
                pause_end_run = true
                Jukebox.music("res://assets/audio/music/matcher_peace.wav")
        else:
                score_bonus_enabled = true
                pause_end_run = false
                Jukebox.music("res://assets/audio/music/matcher_game.mp3")
        ch_lives = CH_LIVES
        ch_wins = 0
        ch_losses = 0
        round_moves = 0
        round_moves_max = 16
        goal_color = -1
        goal_color_left = 0
        goal_special = ""
        goal_special_done = false
        jelly = {}
        jelly_level = 1
        jelly_moves = 24
        jelly_cleared_move = 0
        icel = {}
        icr_level = 1
        icr_moves = 24
        icr_hit_move = 0
        drop_total = 5
        drop_left = 5
        drop_limit_kind = "moves"
        drop_moves = 22
        drop_time = 75.0
        drop_items = []
        drop_level = 1
        fly_secs = 0.0
        hatch_clock = FLY_GAP0         # v0.3.3-p5: the ladder's first beat
        fly_spawned = 0
        move_pops = 0
        _wave_bottomup = false
        ice_melt_cols = {}
        _deal_board()
        if mode == "challenge":
                # THE FIRST ROUND LAW: round 1 rolls BEFORE the first tick - and
                # THE PRE-SOLVE rides WHILE the pour falls (the sim is pure
                # model, the gems are already dealt)
                round_no = 1
                _roll_round()
        _deal_settle()
        # v0.3.3-p2: the spider only ever lived on the boot screen's mode - a
        # butterflies run started from the picker had NONE (the owner's "there
        # is no spider?")
        _build_spider()
        _refresh_rail()
        _refresh_hud()


func _first_tick_guard() -> bool:
        return phase == "play" and not over


## the gem spawn - mode-aware weights (the challenge drought twist bends one
## color rare; never to zero - a starved board is the OLD static machine)
func _roll_color() -> int:
        var weights := []
        for i in COLORS:
                var w := 1.0
                if twist == "drought" and i == drought_color:
                        w = 0.25
                weights.append(w)
        var total := 0.0
        for w in weights:
                total += w
        var roll := randf() * total
        for i in COLORS:
                roll -= weights[i]
                if roll <= 0.0:
                        return i
        return COLORS - 1


func _new_cell(r: int, c: int, from_y := -1.0) -> Dictionary:
        var col := _roll_color()
        var n := Sprite2D.new()
        n.texture = tex_gem[col % tex_gem.size()]
        var target := _cell_pos(r, c)
        n.position = Vector2(target.x, target.y if from_y < 0.0 else from_y)
        n.scale = Vector2.ONE * cell_px / 100.0
        n.z_index = 2
        world.add_child(n)
        return {"color": col, "special": "", "wing": false, "node": n}


func _deal_board() -> void:
        # clear any old nodes
        for r in ROWS:
                for c in COLS:
                        if grid.size() > r and grid[r].size() > c and not grid[r][c].is_empty():
                                var old: Dictionary = grid[r][c]
                                if is_instance_valid(old.get("node")):
                                        old["node"].queue_free()
        grid = []
        for r in ROWS:
                var row := []
                for c in COLS:
                        row.append({})
                grid.append(row)
        earth = []
        if mode == "mine":
                earth_top = ROWS - 1          # ONE earth row waits at the bottom
                earth.resize(ROWS)
                _lay_earth_row(earth_top, 1.0)
        if mode == "jelly":
                _jelly_lay_level()            # the jelly eats its seats BEFORE
                                              # the gems pour in (gems only law)
        # THE FALL-IN LAW (v0.3.3-p4, the owner: "i want the game to start
        # with empty grid-gems then the gems drops down smoothly and fill
        # the places, notice i said gems only"): the round opens on an EMPTY
        # board and the gems pour in from above, column by column
        for r in ROWS:
                if _in_earth(r):
                        continue
                for c in COLS:
                        if _jelly_at(r, c) or _earth_at(r, c):
                                continue
                        var cell := _new_cell(r, c, board_o.y - cell_px * (1.4 + float(ROWS - r)))
                        grid[r][c] = cell
        # kill the dealt-in matches quietly (reroll the offending cells)
        var guard := 0
        while not _find_matches().is_empty() and guard < 200:
                guard += 1
                for g in _find_matches():
                        for key in g["cells"]:
                                var r := int(key) / COLS
                                var c := int(key) % COLS
                                var cell: Dictionary = grid[r][c]
                                cell["color"] = _roll_color()
                                if is_instance_valid(cell.get("node")):
                                        cell["node"].texture = tex_gem[int(cell["color"]) % tex_gem.size()]
        # the physical pour: column-staggered free falls, the bottom rows land
        # first inside a column, the columns sweep left to right
        for c in COLS:
                for r in range(ROWS - 1, -1, -1):
                        var cell: Dictionary = grid[r][c]
                        if cell.is_empty() or not is_instance_valid(cell.get("node")):
                                continue
                        _fall_to(cell["node"], _cell_pos(r, c).y,
                                        float(c) * 0.05 + float(ROWS - 1 - r) * 0.026)
        if mode == "ice":
                frost = [0, 0, 0, 0, 0, 0, 0, 0]
                fronts = []
                front_count = 0
                front_gap = ICE_GAP0
                front_clock = 2.5
        if mode == "icecrash":
                _icr_lay_level()
        if mode == "drop":
                _drop_roll_round()
        if mode == "butterflies":
                for c in [1, 4, 6]:
                        _hatch_butterfly(ROWS - 1, c)


func _deal_settle() -> void:
        # the input stays locked until the pour lands (the probe and the
        # challenge pre-solve read colors while the fall is in the air)
        busy = true
        await _await_bodies(900)
        busy = false


func _in_earth(r: int) -> bool:
        # v0.3.3-p2 THE MINE PUSHES FROM THE BOTTOM (the owner's Bejeweled
        # Classic spec): the earth band grows UPWARD from the bottom row -
        # earth_top = the first earth row, ROWS = no earth at all
        return mode == "mine" and r >= earth_top


## v0.3.3-p5 THE POCKETS LAW (the owner: "an area with no sand in same row,
## it should let the gems fit in"): the earth limit is PER CELL now - a row
## whose neighbor wears dirt can still own open seats. A cell is solid ONLY
## where a live dirt/clay/rock node stands; every dug hole is a real seat
## gems fall into and match inside.
func _earth_at(r: int, c: int) -> bool:
        if mode != "mine" or r < earth_top or r >= ROWS:
                return false
        if c < 0 or c >= COLS or r < 0:
                return false
        if earth.size() <= r or earth[r] == null or earth[r].size() <= c:
                return false
        var e: Dictionary = earth[r][c]
        return not e.is_empty() and e.has("node") \
                        and is_instance_valid(e.get("node"))


# ================================================================ the model
## cell kinds: every playable cell holds a gem dict. A coin cell replaces
## the gem (color -1). A drop parcel replaces the gem (color -2). A jelly
## cell holds NO gem at all (the jelly ate it) - the jelly layer lives in
## the `jelly` dict. Ice-crash layers ride their cells in the `icel` dict
## (the gem stays matchable - things pass through). The mine's earth band
## lives OUTSIDE the grid.

func _is_coin(cell: Dictionary) -> bool:
        return int(cell.get("color", -1)) == -1 and cell.has("coin")


func _is_item(cell: Dictionary) -> bool:
        return int(cell.get("color", -1)) == -2 and cell.has("item")


func _jelly_at(r: int, c: int) -> bool:
        return mode == "jelly" and jelly.has(r * COLS + c)


func _icel_at(r: int, c: int) -> int:
        if mode != "icecrash":
                return 0
        return int(icel.get(r * COLS + c, 0))


func _playable(r: int, c: int) -> bool:
        if c < 0 or c >= COLS or r < 0 or r >= ROWS:
                return false
        if _jelly_at(r, c):
                return false            # a jelly cell is a solid block
        if _earth_at(r, c):
                return false            # a standing dirt cell is solid
        return true


func _color_at(r: int, c: int) -> int:
        if not _playable(r, c):
                return -2
        var cell: Dictionary = grid[r][c]
        if cell.is_empty() or _is_coin(cell):
                return -1
        return int(cell["color"])


## scan for matches. Returns a list of groups:
##   {cells: {key:int -> true}, dir: "h"|"v", len: int, cross: Vector2i or (-1,-1)}
## The cross is the L/T/+ intersection point (the star gem's birthplace).
## v0.3.3-p5: no more row-level earth skip - the per-cell _color_at decides,
## so gems sitting in dug holes match like everywhere else.
func _find_matches() -> Array:
        var runs := []
        # rows
        for r in ROWS:
                var c := 0
                while c < COLS:
                        var col := _color_at(r, c)
                        if col < 0:
                                c += 1
                                continue
                        var e := c
                        while e + 1 < COLS and _color_at(r, e + 1) == col:
                                e += 1
                        if e - c + 1 >= 3:
                                var cells := {}
                                for k in range(c, e + 1):
                                        cells[r * COLS + k] = true
                                runs.append({"cells": cells, "dir": "h", "len": e - c + 1,
                                                "color": col, "cross": Vector2i(-1, -1)})
                        c = e + 1
        # cols
        for c in COLS:
                var r := 0
                while r < ROWS:
                        var col := _color_at(r, c)
                        if col < 0:
                                r += 1
                                continue
                        var e := r
                        while e + 1 < ROWS and _color_at(e + 1, c) == col:
                                e += 1
                        if e - r + 1 >= 3:
                                var cells := {}
                                for k in range(r, e + 1):
                                        cells[k * COLS + c] = true
                                runs.append({"cells": cells, "dir": "v", "len": e - r + 1,
                                                "color": col, "cross": Vector2i(-1, -1)})
                        r = e + 1
        if runs.is_empty():
                return []
        # merge overlapping runs into groups; a cross of an h and a v run of the
        # same color = the star shape
        var groups := []
        var used := []
        for i in runs.size():
                if used.has(i):
                        continue
                var g: Dictionary = runs[i].duplicate()
                g["cells"] = (runs[i]["cells"] as Dictionary).duplicate()
                used.append(i)
                for j in range(i + 1, runs.size()):
                        if used.has(j):
                                continue
                        var o: Dictionary = runs[j]
                        if int(o["color"]) != int(g["color"]):
                                continue
                        var share := false
                        for key in o["cells"]:
                                if (g["cells"] as Dictionary).has(key):
                                        share = true
                                        break
                        if not share:
                                continue
                        used.append(j)
                        for key in o["cells"]:
                                g["cells"][key] = true
                        g["len"] = int(g["len"]) + int(o["len"])
                        if String(o["dir"]) != String(g["dir"]):
                                # the intersection cell: the shared key
                                for key in o["cells"]:
                                        if (runs[i]["cells"] as Dictionary).has(key):
                                                g["cross"] = Vector2i(int(key) / COLS, int(key) % COLS)
                groups.append(g)
        return groups


## any legal swap on the board? (the deadlock check - brute force, 8x8 is
## nothing for a probe fuzz to churn)
func _has_valid_move() -> bool:
        for r in ROWS:
                for c in COLS:
                        if not _playable(r, c) or grid[r][c].is_empty():
                                continue
                        for d in [Vector2i(0, 1), Vector2i(1, 0)]:
                                var r2: int = r + d.x
                                var c2: int = c + d.y
                                if not _playable(r2, c2) or grid[r2][c2].is_empty():
                                        continue
                                if _is_coin(grid[r][c]) or _is_coin(grid[r2][c2]) \
                                                or _is_item(grid[r][c]) or _is_item(grid[r2][c2]):
                                        continue
                                # hypercube swap is ALWAYS legal (it detonates on contact)
                                if String(grid[r][c].get("special", "")) == "hyper" \
                                                or String(grid[r2][c2].get("special", "")) == "hyper":
                                        return true
                                _swap_model(r, c, r2, c2)
                                var ok := not _find_matches().is_empty()
                                _swap_model(r, c, r2, c2)
                                if ok:
                                        return true
        # v0.3.3-p5 THE HOP MOVES COUNT TOO: a match THROUGH a coin is a
        # real move (the deadlock check may not call a shuffle over a
        # board the coin hop can still save)
        for r in ROWS:
                for c in COLS:
                        if not _playable(r, c) or grid[r][c].is_empty():
                                continue
                        for d in [Vector2i(0, 1), Vector2i(1, 0)]:
                                var r2: int = r + d.x
                                var c2: int = c + d.y
                                if not _playable(r2, c2) or grid[r2][c2].is_empty():
                                        continue
                                if not _is_coin(grid[r2][c2]):
                                        continue
                                var hop := _hop_target(Vector2i(r, c), Vector2i(r2, c2))
                                if hop == Vector2i(-9, -9):
                                        continue
                                _swap_model(r, c, hop.x, hop.y)
                                var ok2 := not _find_matches().is_empty()
                                _swap_model(r, c, hop.x, hop.y)
                                if ok2:
                                        return true
        return false


func _find_a_move() -> Array:
        for r in ROWS:
                for c in COLS:
                        if not _playable(r, c) or grid[r][c].is_empty():
                                continue
                        for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
                                var r2: int = r + d.x
                                var c2: int = c + d.y
                                if not _playable(r2, c2) or grid[r2][c2].is_empty():
                                        continue
                                if _is_coin(grid[r][c]) or _is_coin(grid[r2][c2]) \
                                                or _is_item(grid[r][c]) or _is_item(grid[r2][c2]):
                                        continue
                                if String(grid[r][c].get("special", "")) == "hyper" \
                                                or String(grid[r2][c2].get("special", "")) == "hyper":
                                        return [Vector2i(r, c), Vector2i(r2, c2)]
                                _swap_model(r, c, r2, c2)
                                var ok := not _find_matches().is_empty()
                                _swap_model(r, c, r2, c2)
                                if ok:
                                        return [Vector2i(r, c), Vector2i(r2, c2)]
        # the hop moves are hint-worthy too (the coin match-through)
        for r in ROWS:
                for c in COLS:
                        if not _playable(r, c) or grid[r][c].is_empty():
                                continue
                        for d in [Vector2i(0, 1), Vector2i(1, 0)]:
                                var r2: int = r + d.x
                                var c2: int = c + d.y
                                if not _playable(r2, c2) or grid[r2][c2].is_empty():
                                        continue
                                if not _is_coin(grid[r2][c2]):
                                        continue
                                var hop := _hop_target(Vector2i(r, c), Vector2i(r2, c2))
                                if hop == Vector2i(-9, -9):
                                        continue
                                _swap_model(r, c, hop.x, hop.y)
                                var ok2 := not _find_matches().is_empty()
                                _swap_model(r, c, hop.x, hop.y)
                                if ok2:
                                        return [Vector2i(r, c), hop]
        return []


func _swap_model(r1: int, c1: int, r2: int, c2: int) -> void:
        var a: Dictionary = grid[r1][c1]
        grid[r1][c1] = grid[r2][c2]
        grid[r2][c2] = a


# ================================================================ input
var sel := Vector2i(-1, -1)

func _goga_input(_event: InputEvent) -> void:
        pass


func _ready_input() -> void:
        tk.tapped.connect(func(p): _tap(p))
        tk.dragged.connect(func(from, to): _drag(from, to))


func _tap(p: Vector2) -> void:
        if phase != "play" or busy or over or paused or pick_open \
                        or sheet_open_count() > 0:
                return
        idle_clock = 0.0
        var cellp := _pos_to_cell(p)
        if armed != "":
                _fire_power(cellp)
                return
        if cellp.x < 0:
                _select(Vector2i(-1, -1))
                return
        if mode == "mine" and _earth_at(cellp.x, cellp.y):
                return
        # v0.3.3-p5 THE COIN COURTESY (the owner: "gogacoins can not be
        # tapped ... fix that, it should accept this"): a tap ON the coin
        # collects it - with a gem in hand, the gem HOPS THROUGH to the
        # cell beyond (the match-through law)
        if cellp.x >= 0 and not grid[cellp.x][cellp.y].is_empty() \
                        and _is_coin(grid[cellp.x][cellp.y]):
                if sel.x >= 0 and _hop_target(sel, cellp) != Vector2i(-9, -9):
                        var a := sel
                        sel = Vector2i(-1, -1)
                        _paint_selection()
                        _try_swap(a, _hop_target(a, cellp))
                        return
                _collect_coin_at(cellp)
                return
        _select(cellp)


## the hop law: dragging from a toward a coin, the gem rides THROUGH to the
## cell beyond the coin (same direction) if that seat holds a swap-able gem
func _hop_target(a: Vector2i, coin: Vector2i) -> Vector2i:
        var d := coin - a
        if absi(d.x) + absi(d.y) != 1:
                return Vector2i(-9, -9)     # only a step lands on the coin
        var beyond := coin + d
        if not _playable(beyond.x, beyond.y) or grid[beyond.x][beyond.y].is_empty():
                return Vector2i(-9, -9)
        var cb: Dictionary = grid[beyond.x][beyond.y]
        if _is_coin(cb) or _is_item(cb):
                return Vector2i(-9, -9)
        return beyond


func _drag(from: Vector2, to: Vector2) -> void:
        if phase != "play" or busy or over or paused or pick_open \
                        or sheet_open_count() > 0:
                return
        if armed != "":
                return
        idle_clock = 0.0
        var a := _pos_to_cell(from)
        if a.x < 0:
                return
        var d := to - from
        if d.length() < cell_px * 0.35:
                return
        var dir := Vector2i(0, 0)
        if absf(d.x) > absf(d.y):
                dir = Vector2i(0, 1 if d.x > 0 else -1)
        else:
                dir = Vector2i(1 if d.y > 0 else -1, 0)
        var b := a + dir
        # v0.3.3-p5 THE MATCH-THROUGH LAW (the owner: "i want to move red
        # gem through it to do a match and go down"): a drag INTO a coin
        # carries the gem THROUGH it - the hop lands on the cell beyond
        if b.x >= 0 and b.y >= 0 and b.x < ROWS and b.y < COLS \
                        and not grid[b.x][b.y].is_empty() \
                        and _is_coin(grid[b.x][b.y]):
                var hop := _hop_target(a, b)
                if hop != Vector2i(-9, -9):
                        b = hop
        if not _playable(b.x, b.y):
                return
        sel = Vector2i(-1, -1)
        _try_swap(a, b)


func _select(cellp: Vector2i) -> void:
        if cellp.x < 0:
                sel = Vector2i(-1, -1)
                _paint_selection()
                return
        if sel.x < 0:
                sel = cellp
                Jukebox.sfx("click", -10.0)
        elif sel == cellp:
                sel = Vector2i(-1, -1)
        else:
                var d := Vector2i(absf(sel.x - cellp.x), absf(sel.y - cellp.y))
                var adjacent: bool = d.x + d.y == 1
                var a := sel
                sel = Vector2i(-1, -1)
                if adjacent:
                        _try_swap(a, cellp)
                else:
                        sel = cellp
                        Jukebox.sfx("click", -10.0)
        _paint_selection()


func _paint_selection() -> void:
        for r in ROWS:
                for c in COLS:
                        if grid.size() <= r or grid[r].size() <= c:
                                continue
                        var cell: Dictionary = grid[r][c]
                        if cell.is_empty() or not is_instance_valid(cell.get("node")):
                                continue
                        var n: Sprite2D = cell["node"]
                        if sel == Vector2i(r, c):
                                n.modulate = Color(1.25, 1.25, 1.1)
                        else:
                                n.modulate = Color.WHITE


func _try_swap(a: Vector2i, b: Vector2i) -> void:
        if busy or not _playable(a.x, a.y) or not _playable(b.x, b.y):
                return
        var ca: Dictionary = grid[a.x][a.y]
        var cb: Dictionary = grid[b.x][b.y]
        if ca.is_empty() or cb.is_empty():
                return
        if _is_coin(ca) or _is_coin(cb) or _is_item(ca) or _is_item(cb):
                Jukebox.sfx("error", -12.0)
                _bump(a)
                _bump(b)
                return
        var special_a := String(ca.get("special", ""))
        var special_b := String(cb.get("special", ""))
        if special_a == "hyper" or special_b == "hyper":
                _do_hyper_swap(a, b)
                return
        busy = true
        _swap_model(a.x, a.y, b.x, b.y)
        await _animate_swap(a, b)
        if _find_matches().is_empty():
                # the rubber-band law: an illegal swap goes back with a soft thud
                _swap_model(a.x, a.y, b.x, b.y)
                await _animate_swap(a, b)
                Jukebox.sfx("error", -14.0)
                _bump(a)
                _bump(b)
                busy = false
                return
        Jukebox.sfx("m_swap", -8.0)
        move_pops = 0
        _drop_capture_rows()
        moves_made += 1
        round_moves += 1
        if mode == "jelly":
                jelly_moves -= 1
        if mode == "icecrash":
                icr_moves -= 1
        if mode == "drop":
                drop_moves -= 1
        await _resolve_loop(a, b)
        # v0.3.3-p3 THE AFTER-MOVE LAW (the owner's butterfly example): the
        # butterflies rise only AFTER the whole move has resolved - never
        # during the swap - and every other per-move law walks here too
        await _after_move()
        busy = false


func _bump(cellp: Vector2i) -> void:
        var cell: Dictionary = grid[cellp.x][cellp.y]
        if cell.is_empty() or not is_instance_valid(cell.get("node")):
                return
        var n: Sprite2D = cell["node"]
        # v0.3.3-p2 (the owner's "it weirdly got too huge"): the bump rides
        # the sprite's OWN scale - a coin no longer inflates to gem size
        var base: Vector2 = n.scale
        var tw := n.create_tween()
        tw.tween_property(n, "scale", base * 1.12, 0.07)
        tw.tween_property(n, "scale", base, 0.1)


func _animate_swap(a: Vector2i, b: Vector2i) -> void:
        # the tween-await law: one timer, never finished-after-the-fact
        var moved := 0
        for pair in [[a, b], [b, a]]:
                var cell: Dictionary = grid[pair[0].x][pair[0].y]
                if cell.is_empty() or not is_instance_valid(cell.get("node")):
                        continue
                var n: Sprite2D = cell["node"]
                moved += 1
                var tw := n.create_tween()
                tw.tween_property(n, "position", _cell_pos(pair[0].x, pair[0].y), 0.16) \
                                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        if moved > 0:
                await get_tree().create_timer(0.18, false).timeout


var moves_made := 0

# ================================================================ resolve loop
## THE RESOLVE LAW: match wave -> specials born -> pops -> gravity -> refill
## -> re-scan, until the board is quiet. THE MUTATION LAW: every list a pop
## loop walks is duplicated first (cells vanish inside their own funeral).

## the crown table v2 - THE OWNER'S WORDS ARE THE LAW:
## "the L or T is the bomb, the 4 vertical makes a horizontal line sweeper,
## the 4 horizontal makes vertical one line sweeper, the +5 in a line makes
## color remover". The SWAP CELL wins the crown, an L/T cross births at the
## cross, otherwise the run's middle. Pure - the probe reads it.
func _birth_kinds(groups: Array, swap_a: Vector2i, swap_b: Vector2i) -> Array:
        var born := []
        for g in groups:
                var cells: Dictionary = g["cells"]
                var birth := Vector2i(-1, -1)
                if g["cross"].x >= 0 and cells.has(g["cross"].y * COLS + g["cross"].x):
                        birth = g["cross"]
                elif swap_a.x >= 0 and cells.has(swap_a.y * COLS + swap_a.x):
                        birth = swap_a
                elif swap_b.x >= 0 and cells.has(swap_b.y * COLS + swap_b.x):
                        birth = swap_b
                else:
                        var keys := cells.keys()
                        birth = Vector2i(int(keys[keys.size() / 2]) / COLS, int(keys[keys.size() / 2]) % COLS)
                var kind := ""
                if g["cross"].x >= 0:
                        kind = "bomb"       # the L / T / + shape
                elif int(g["len"]) >= 5:
                        kind = "hyper"      # five in a line = the color remover
                elif int(g["len"]) == 4:
                        kind = "rowh" if String(g["dir"]) == "v" else "colv"
                if kind != "" and birth.x >= 0:
                        born.append({"r": birth.x, "c": birth.y, "kind": kind,
                                        "color": int(g["color"])})
        return born


func _resolve_loop(swap_a := Vector2i(-1, -1), swap_b := Vector2i(-1, -1)) -> void:
        cascade = 0
        while true:
                if over:
                        return
                var groups := _find_matches()
                if groups.is_empty():
                        break
                cascade += 1
                # 1 - the specials this wave births (the swap cell wins the crown)
                var born := _birth_kinds(groups, swap_a, swap_b)   # [{r, c, kind, color}]
                if mode == "ice":
                        # v0.3.3-p4 THE VERTICAL-ONLY MELT: the wave's vertical
                        # groups mark their columns - a HORIZONTAL match never
                        # touches the ice (the owner's correction)
                        for g in groups:
                                if String(g["dir"]) != "v":
                                        continue
                                for key in (g["cells"] as Dictionary).keys():
                                        ice_melt_cols[int(key) % COLS] = true
                var pop := {}
                for g in groups:
                        for key in g["cells"]:
                                pop[key] = true
                for b in born:
                        pop.erase(int(b["r"]) * COLS + int(b["c"]))   # keys are r*COLS+c
                # 2 - the detonation queue: specials caught INSIDE a match explode
                var queue := []
                var blast_union := {}
                _stagger_hint = {}
                for key in pop.keys():
                        var r := int(key) / COLS
                        var c := int(key) % COLS
                        var sp := String(grid[r][c].get("special", ""))
                        if sp != "":
                                queue.append({"r": r, "c": c, "kind": sp})
                # 3 - detonate (chain: blasts can ignite more specials)
                var detonated := {}
                while not queue.is_empty():
                        var it: Dictionary = queue.pop_front()
                        var dkey: int = int(it["r"]) * COLS + int(it["c"])
                        if detonated.has(dkey):
                                continue
                        detonated[dkey] = true
                        blast_union[dkey] = true
                        var extra := _blast_cells(String(it["kind"]), int(it["r"]), int(it["c"]))
                        for key in extra:
                                blast_union[key] = true
                                if not pop.has(key):
                                        pop[key] = true
                                        var r := int(key) / COLS
                                        var c := int(key) % COLS
                                        if _playable(r, c) and not grid[r][c].is_empty():
                                                var sp2 := String(grid[r][c].get("special", ""))
                                                if sp2 != "" and not detonated.has(key):
                                                        queue.append({"r": r, "c": c, "kind": sp2})
                # 4 - pop the wave (fx, score, mode counters) - the blasts
                # sweep and bomb with STAGED pops (the owner's missing effects)
                _icr_mark_stone(blast_union)
                await _pop_cells(pop, born, _stagger_hint.duplicate(), blast_union)
                # 5 - the combo praise
                if cascade >= 2 and mode != "peace":
                        _combo_banner(cascade)
                swap_a = Vector2i(-1, -1)
                swap_b = Vector2i(-1, -1)
                # 6 - gravity + refill + settle
                await _gravity()
        # quiet board: the after-care
        _collect_bottom_coins()
        if mode == "mine":
                _mine_row_check()
        await _mode_aftercare()
        if not _has_valid_move():
                await _shuffle_board(true)
        idle_clock = 0.0
        _paint_selection()


## the stagger hints the blasts leave for _pop_cells (the sweeper sweeps
## left-to-right / top-to-bottom, the bomb radiates)
var _stagger_hint := {}

## what a special detonation covers (in keys). v0.3.3-p3 THE OWNER'S TABLE:
## bomb = the L/T birth = a 3x3 crater; a 4-vertical birth sweeps its whole
## ROW; a 4-horizontal birth sweeps its whole COLUMN; a remover caught in a
## blast zaps a random color (chaos law).
func _blast_cells(kind: String, r: int, c: int) -> Array:
        var out := {}
        match kind:
                "bomb":
                        for dr in range(-1, 2):
                                for dc in range(-1, 2):
                                        var rr2 := r + dr
                                        var cc := c + dc
                                        if _playable(rr2, cc):
                                                out[rr2 * COLS + cc] = true
                                                _stagger_hint[rr2 * COLS + cc] = \
                                                                Vector2(dr, dc).length() * BOMB_RING_T
                        shake = 0.55
                        # v0.3.3-p4 THE BOMB THEATRE: the bomb gem SHAKES,
                        # the crater radiates, then the wave takes the cells
                        var bn: Sprite2D = grid[r][c].get("node") \
                                        if not grid[r][c].is_empty() else null
                        if bn != null:
                                _shake_node(bn)
                        Jukebox.sfx("m_tok_bomb", -3.0)
                        rings.append({"pos": _cell_pos(r, c), "r": 14.0, "life": 0.42,
                                        "max": 0.42, "col": Color(1.0, 0.55, 0.2, 0.95), "w": 9.0})
                        rings.append({"pos": _cell_pos(r, c), "r": 4.0, "life": 0.3,
                                        "max": 0.3, "col": Color(1.0, 0.85, 0.4, 0.8), "w": 5.0})
                        _float_text(_cell_pos(r, c), "BOOM!", Color(1.0, 0.6, 0.2), 32)
                "rowh":
                        for cc in COLS:
                                if _playable(r, cc):
                                        out[r * COLS + cc] = true
                                        _stagger_hint[r * COLS + cc] = \
                                                        absf(float(cc - c)) * SWEEP_CELL_T
                        # THE SWEEP SPREADS FROM THE BIRTH CELL both ways
                        sweeps.append({"axis": "h", "idx": r, "from_i": c, "t": 0.0,
                                        "max": SWEEP_T, "col": Color(0.55, 0.95, 1.0)})
                        Jukebox.sfx("m_sweep", -4.0, randf_range(0.95, 1.1))
                        _float_text(_cell_pos(r, c), "ROW SWEEP!",
                                        Color(0.55, 0.95, 1.0), 30)
                "colv":
                        for rr3 in ROWS:
                                if _playable(rr3, c):
                                        out[rr3 * COLS + c] = true
                                        _stagger_hint[rr3 * COLS + c] = \
                                                        absf(float(rr3 - r)) * SWEEP_CELL_T
                        # THE SWEEP SPREADS FROM THE BIRTH CELL both ways
                        # (v0.3.3-p4: "sideways sweeping remove in a spreading
                        # way also the vertical one")
                        sweeps.append({"axis": "v", "idx": c, "from_i": r, "t": 0.0,
                                        "max": SWEEP_T, "col": Color(1.0, 0.55, 0.95)})
                        if mode == "ice":
                                ice_melt_cols[c] = true   # the vertical arm melts
                        Jukebox.sfx("m_sweep", -4.0, randf_range(0.7, 0.8))
                        _float_text(_cell_pos(r, c), "COLUMN SWEEP!",
                                        Color(1.0, 0.55, 0.95), 30)
                "hyper":
                        # caught in a blast: it takes a random color with it,
                        # ONE BY ONE bottom-to-up like the remover it is
                        var pick := randi() % COLORS
                        for rr4 in ROWS:
                                for cc in COLS:
                                        if _playable(rr4, cc) and not grid[rr4][cc].is_empty() \
                                                        and not _is_coin(grid[rr4][cc]) \
                                                        and not _is_item(grid[rr4][cc]) \
                                                        and int(grid[rr4][cc].get("color", -9)) == pick:
                                                out[rr4 * COLS + cc] = true
                                                _stagger_hint[rr4 * COLS + cc] = \
                                                                float(ROWS - 1 - rr4) * REMOVER_ROW_T \
                                                                + float(cc) * REMOVER_CELL_T
                                                var wn: Sprite2D = grid[rr4][cc].get("node")
                                                if is_instance_valid(wn):
                                                        var vt := wn.create_tween()
                                                        vt.tween_property(wn, "modulate",
                                                                        Color(1.6, 0.6, 1.8), 0.16)
                                                wipes.append({"row": rr4, "t": 0.0, "max": 0.3,
                                                                "col": Color(1.0, 0.7, 1.0),
                                                                "delay": float(ROWS - 1 - rr4) * REMOVER_ROW_T})
                        _float_text(_cell_pos(r, c), "COLOR ZAP!", Color(1, 0.7, 1.0), 34)
                        Jukebox.sfx("m_colorwipe", -4.0)
        return out.keys()


func _pop_cells(pop: Dictionary, born: Array, stagger := {}, blast_keys := {}) -> void:
        if pop.is_empty() and born.is_empty():
                return
        var count := 0
        var rush := rush_left > 0.0
        var max_delay := 0.0
        for key in pop.keys():
                var r := int(key) / COLS
                var c := int(key) % COLS
                if not _playable(r, c):
                        continue
                var cell: Dictionary = grid[r][c]
                if cell.is_empty():
                        continue
                # the coin and the parcels are NEVER destroyed by pops
                if _is_coin(cell) or _is_item(cell):
                        continue
                count += 1
                move_pops += 1
                var col := int(cell["color"])
                var p := _cell_pos(r, c)
                # THE STAGED POP LAW: a blast/sweep/wave staggers its pops by
                # distance so the eye SEES the sweep spread and the wipe climb
                var delay_s := float(stagger.get(key, 0.0))
                max_delay = maxf(max_delay, delay_s)
                var stone_mark: int = int(cell.get("stone_hit", 0))
                _gem_pop_fx(p, col, delay_s)
                if bool(cell.get("wing", false)):
                        # a butterfly collected: +2 mode bonus on top of its gem point
                        if mode == "butterflies":
                                add_score(2)
                                achievement_count("butterflies", 1)
                                Jukebox.sfx("m_flutter", -6.0, randf_range(0.9, 1.15))
                if rush:
                        add_score(1)        # the gold rush twist: pops pay double
                # v0.3.3-p4 THE BURST LAW: the gem POPS - a quick punch, then
                # the shrink-away. The model frees the seat instantly, the
                # sprite rides the wave's delay first.
                if is_instance_valid(cell.get("node")):
                        var n: Sprite2D = cell["node"]
                        var tw := n.create_tween()
                        if delay_s > 0.0:
                                tw.tween_interval(delay_s)
                        var base: Vector2 = n.scale
                        tw.tween_property(n, "scale", base * 1.22, 0.055) \
                                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
                        tw.tween_property(n, "scale", Vector2.ONE * 0.02, 0.1) \
                                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                        tw.parallel().tween_property(n, "modulate:a", 0.0, 0.1)
                        tw.chain().tween_callback(n.queue_free)
                grid[r][c] = {}
                # v0.3.3-p3 THE MODE-TOUCH LAWS (the stone mark was read
                # BEFORE the seat emptied - a dict written after would be a
                # zombie {"stone_hit": 0} cell forever)
                _mode_touch_pop(r, c, stone_mark)
        if count > 0:
                add_score(count)
                achievement_count("matched", count)
                # the zip's candy pop, pitch-laddered by the cascade
                Jukebox.sfx("m_pop_candy", -8.0, 0.94 + 0.055 * mini(cascade, 6) \
                                + randf_range(-0.015, 0.015))
                # the ice law v4: ONLY the wave's vertical groups (or a
                # full-column blast) melt the ice - horizontal never does
                if mode == "ice":
                        _ice_melt_wave()
                # the mine law: the wave drills the matched columns downward
                if mode == "mine":
                        _mine_dig(pop, blast_keys)
        if cascade > 1:
                achievement_max("best_cascade", cascade)
        # THE OWNER'S CROWN TABLE: L/T -> bomb, 4v -> row sweeper, 4h -> column
        # sweeper, 5+ -> color remover - all shader-on-the-asset, any skin
        for b in born:
                var cell: Dictionary = grid[int(b["r"])][int(b["c"])]
                if cell.is_empty() or _is_coin(cell) or _is_item(cell):
                        continue
                cell["special"] = String(b["kind"])
                _dress_special(int(b["r"]), int(b["c"]))
                Jukebox.sfx("m_special", -6.0, 1.0 + 0.05 * born.find(b))
                # the gem wears it with a little arrival pop
                if is_instance_valid(cell.get("node")):
                        var bn: Sprite2D = cell["node"]
                        var btw := bn.create_tween()
                        btw.tween_property(bn, "scale", Vector2.ONE * cell_px / 100.0 * 1.22, 0.1) \
                                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                        btw.tween_property(bn, "scale", Vector2.ONE * cell_px / 100.0, 0.12)
                if String(b["kind"]) == "hyper":
                        achievement_count("hypers", 1)
                if goal_special != "" and String(b["kind"]) == goal_special:
                        goal_special_done = true
                var p := _cell_pos(int(b["r"]), int(b["c"]))
                var words := {"bomb": "BOMB!", "rowh": "ROW SWEEPER!",
                                "colv": "COLUMN SWEEPER!", "hyper": "COLOR REMOVER!"}
                _float_text(p, String(words[String(b["kind"])]), Color(1, 0.9, 0.4))
        # v0.3.3-p4: the resolve WAITS for the whole staged wave - gravity
        # never runs under a still-burning sweeper (the old flat 0.16s await
        # made every blast feel instant)
        await get_tree().create_timer(max_delay + 0.2, false).timeout


## what ONE popped cell means to the layer modes (jelly / ice crash)
func _mode_touch_pop(r: int, c: int, stone_mark := 0) -> void:
        # ICE CRASH: a hit INSIDE the ice cracks its layer by one (the owner:
        # "hits should happen inside it directly btw")
        var lvl := _icel_at(r, c)
        if lvl > 0:
                icr_hit_move += 1
                if lvl >= ICE_CRASH_ROCK:
                        # the rock only answers to SPECIALS - a plain match
                        # just clanks (the stone mark rides the BLAST, read
                        # before the seat emptied)
                        if stone_mark == 1:
                                icel[r * COLS + c] = ICE_CRASH_ROCK - 1
                                Jukebox.sfx("m_icebreak", -4.0)
                                _icr_crack_fx(r, c)
                                # v0.3.3-p4 THE REACTION FIX: the cracked rock
                                # used to keep wearing the level-6 texture (the
                                # refresh call lived only in the plain-hit arm)
                                _refresh_icel_cell(r, c)
                        else:
                                Jukebox.sfx("m_rockhit", -4.0)
                                _float_text(_cell_pos(r, c), "ROCK!", Color(0.8, 0.8, 0.85), 26)
                else:
                        icel[r * COLS + c] = lvl - 1
                        add_score(1)
                        _icr_crack_fx(r, c)
                        if lvl - 1 <= 0:
                                icel.erase(r * COLS + c)
                                Jukebox.sfx("m_icebreak", -5.0, randf_range(0.9, 1.2))
                                achievement_count("icr_layers", 1)
                        else:
                                Jukebox.sfx("m_icehit", -6.0, 0.9 + 0.1 * lvl)
                        _refresh_icel_cell(r, c)
        # JELLY: a match ADJACENT to jelly dissolves it (the jelly cell itself
        # is solid - its neighbors' funerals are its own)
        if mode != "jelly":
                return
        for dd in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
                var d: Vector2i = dd
                var rr5: int = r + d.x
                var cc: int = c + d.y
                if rr5 < 0 or cc < 0 or rr5 >= ROWS or cc >= COLS:
                        continue
                var k: int = rr5 * COLS + cc
                if jelly.has(k):
                        jelly.erase(k)
                        jelly_cleared_move += 1
                        add_score(2)
                        achievement_count("jelly_cells", 1)
                        Jukebox.sfx("m_jelly_pop", -5.0, randf_range(0.9, 1.15))
                        _jelly_pop_fx(rr5, cc)


func _dress_special(r: int, c: int) -> void:
        # v0.3.3-p2 THE SHADER-ON-THE-ASSET LAW (the owner): the special is
        # the gem's own material - it rides every swap, fall and cascade in
        # perfect sync, on ANY skin's texture. No overlay to desync.
        var cell: Dictionary = grid[r][c]
        if cell.is_empty() or not is_instance_valid(cell.get("node")):
                return
        var kind := String(cell.get("special", ""))
        var n: Sprite2D = cell["node"]
        if kind == "":
                n.material = null
                return
        n.material = _special_mat(kind)


func _gem_pop_fx(p: Vector2, col: int, delay_s := 0.0) -> void:
        var cols := [Color("6ec0eb"), Color("e84c60"), Color("6ec878"), Color("f5c446"), Color("c478dc")]
        var c: Color = cols[clampi(col, 0, 4)]
        for i in 9:
                var dir := Vector2.from_angle(randf() * TAU) * randf_range(110.0, 300.0)
                pops.append({"pos": p, "vel": dir, "life": randf_range(0.3, 0.55) + delay_s,
                                "max": 0.55, "r": randf_range(5.0, 12.0), "col": c, "hold": delay_s})
        rings.append({"pos": p, "r": 8.0, "life": 0.3 + delay_s, "max": 0.3,
                        "col": Color(c, 0.8), "w": 5.0, "hold": delay_s})
        # THE PER-COLOR SHATTER (v0.3.3-p5 THE DONUT PURGE: the old frames
        # were the template zip's DONUTS - the owner: "when doing a correct
        # match, it shows donuts"): the popped gem wears ITS OWN color's
        # gem-shatter burst
        var fx := Sprite2D.new()
        fx.texture = _t_popfx(clampi(col, 0, 4))
        fx.position = p
        fx.scale = Vector2.ONE * cell_px / 120.0 * 0.2
        fx.z_index = 8
        fx.modulate.a = 0.0
        world.add_child(fx)
        var tw := fx.create_tween()
        if delay_s > 0.0:
                tw.tween_interval(delay_s)
        tw.set_parallel(true)
        tw.tween_property(fx, "modulate:a", 1.0, 0.05)
        tw.tween_property(fx, "scale", Vector2.ONE * cell_px / 120.0 * 1.15, 0.16) \
                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.chain().tween_property(fx, "modulate:a", 0.0, 0.12)
        tw.chain().tween_callback(fx.queue_free)


func _float_text(p: Vector2, txt: String, col: Color, size := 30) -> void:
        floaters.append({"pos": p, "txt": txt, "life": 0.9, "max": 0.9, "col": col, "size": size})


func _combo_banner(n: int) -> void:
        var words := ["", "", "SWEET!", "SUPER!", "EXQUISITE!", "SPECTACULAR!", "UNREAL!"]
        var w: String = words[mini(n, words.size() - 1)]
        var vp := get_viewport_rect().size
        _float_text(Vector2(vp.x / 2.0, board_o.y - 60.0), w, Color(1, 0.85, 0.35), 40 + 4 * n)
        # v0.3.3-p2: the pentatonic marimba ladder (the owner: "the combo SFXs
        # are the most weirdest ones")
        var step := clampi(n, 2, 7)
        Jukebox.sfx("m_combo_%d" % step, -6.0)


# ================================================================ hypercube
## the hypercube's crown law: swap it with ANY gem (no match needed) and
## every gem of that color zaps off the board. Two hypers = the full wipe.
func _do_hyper_swap(a: Vector2i, b: Vector2i) -> void:
        busy = true
        var ca: Dictionary = grid[a.x][a.y]
        var cb: Dictionary = grid[b.x][b.y]
        var hyper_at := a if String(ca.get("special", "")) == "hyper" else b
        var other_at := b if hyper_at == a else a
        var other: Dictionary = grid[other_at.x][other_at.y]
        var pop := {}
        var both := String(ca.get("special", "")) == "hyper" \
                        and String(cb.get("special", "")) == "hyper"
        if both:
                # THE NOVA LAW (v0.3.3-p4, the owner: "make sure that a color
                # remover + color remover = grid clear with 1 damage for
                # whatever that can be damage and removes all gems without
                # affecting drop-down items"): EVERY gem pops bottom-up in a
                # rising wave; the coin and the parcels are never touched;
                # every damageable layer takes its 1 damage.
                for r in ROWS:
                        for c in COLS:
                                if _playable(r, c) and not grid[r][c].is_empty() \
                                                and not _is_coin(grid[r][c]) \
                                                and not _is_item(grid[r][c]):
                                        pop[r * COLS + c] = true
                _float_text(_cell_pos(hyper_at.x, hyper_at.y), "SUPERNOVA!",
                                Color(1, 0.6, 0.9), 46)
                _nova_damage()
        else:
                var col := int(other.get("color", 0))
                for r in ROWS:
                        for c in COLS:
                                if _playable(r, c) and not grid[r][c].is_empty() \
                                                and not _is_coin(grid[r][c]) \
                                                and not _is_item(grid[r][c]) \
                                                and int(grid[r][c].get("color", -9)) == col:
                                        pop[r * COLS + c] = true
                pop[hyper_at.y * COLS + hyper_at.x] = true
        move_pops = 0
        _drop_capture_rows()
        moves_made += 1
        round_moves += 1
        if mode == "jelly":
                jelly_moves -= 1
        if mode == "icecrash":
                icr_moves -= 1
        if mode == "drop":
                drop_moves -= 1
        Jukebox.sfx("m_hyper", -3.0)
        # THE ONE-BY-ONE BOTTOM-UP WIPE (the owner, v0.3.3-p4: "the color
        # remover should take one by one in a smooth way from bottom to up
        # as i said"): every doomed gem climbs the wave row by row with a
        # small per-cell ripple, each wearing the shimmer
        var delay_map := {}
        for key in pop.keys():
                var r := int(key) / COLS
                var c := int(key) % COLS
                delay_map[key] = float(ROWS - 1 - r) * REMOVER_ROW_T \
                                + float(c) * REMOVER_CELL_T
                var wn: Sprite2D = grid[r][c].get("node")
                if is_instance_valid(wn):
                        var vt := wn.create_tween()
                        vt.tween_property(wn, "modulate",
                                        Color(1.6, 0.6, 1.8), 0.16)
        var wiped_rows := {}
        for key in pop.keys():
                wiped_rows[int(key) / COLS] = true
        for row in wiped_rows.keys():
                wipes.append({"row": int(row), "t": 0.0, "max": 0.3,
                                "col": Color(1.0, 0.7, 1.0),
                                "delay": float(ROWS - 1 - int(row)) * REMOVER_ROW_T})
        Jukebox.sfx("m_colorwipe", -4.0)
        # the lightning arcs
        var hp := _cell_pos(hyper_at.x, hyper_at.y)
        for key in pop.keys():
                var r := int(key) / COLS
                var c := int(key) % COLS
                zaps.append({"a": hp, "b": _cell_pos(r, c), "life": 0.3, "max": 0.3})
        await _pop_cells(pop, [], delay_map)
        await _gravity()
        while true:
                if over:
                        break
                var groups := _find_matches()
                if groups.is_empty():
                        break
                cascade += 1
                var pop2 := {}
                for g in groups:
                        for key in g["cells"]:
                                pop2[key] = true
                await _pop_cells(pop2, [])
                if cascade >= 2:
                        _combo_banner(cascade)
                await _gravity()
        await _after_move()
        busy = false


## the NOVA's one damage on every damageable layer (the owner: "with 1
## damage for whatever that can be damage"): ice-crash layers crack once,
## the mine's earth hp drops once (dead cells clear), the ice storm's
## columns each lose one segment.
func _nova_damage() -> void:
        if mode == "icecrash":
                # the plain layers already took their ONE hit from the pops
                # themselves (the normal touch law) - the nova only adds the
                # rock's crack (a special-blast answer, 6 -> 5)
                for key in icel.keys():
                        if int(icel[key]) >= ICE_CRASH_ROCK:
                                var r := int(key) / COLS
                                var c := int(key) % COLS
                                icel[key] = ICE_CRASH_ROCK - 1
                                _icr_crack_fx(r, c)
                                _refresh_icel_cell(r, c)
                _refresh_hud()
        elif mode == "mine" and earth_top < ROWS:
                for r in range(earth_top, ROWS):
                        for c in COLS:
                                if c >= earth[r].size():
                                        continue
                                var e: Dictionary = earth[r][c]
                                if e.is_empty() or not e.has("node") \
                                                or not is_instance_valid(e["node"]):
                                        continue
                                e["hp"] = int(e.get("hp", 1)) - 1
                                if int(e["hp"]) <= 0:
                                        var n: Sprite2D = e["node"]
                                        _gem_pop_fx(n.position, 2)
                                        if n.has_meta("tr_spr"):
                                                var s: Sprite2D = n.get_meta("tr_spr")
                                                if is_instance_valid(s):
                                                        s.queue_free()
                                        n.queue_free()
                                        earth[r][c] = {}
                _mine_row_check()
                _refresh_hud()
        elif mode == "ice":
                for c in COLS:
                        frost[c] = maxi(0, int(frost[c]) - 1)
                _refresh_ice()
                Jukebox.sfx("m_melt", -5.0)
                _refresh_hud()


# ================================================================ gravity
## THE PHYSICS FALL LAW (v0.3.3-p4): a fall is not a tween anymore - it is
## a real free-fall integration (velocity + gravity, a landing bounce and a
## squash). The bodies ride _tick_fx every frame; the awaits poll frames
## until the last body settles (the old TWEEN-AWAIT hang is structurally
## impossible here - no tween.finished is ever awaited).
func _fall_to(node: Sprite2D, ty: float, hold := 0.0, land_sfx := false) -> void:
        if node == null or not is_instance_valid(node):
                return
        if node.position.y >= ty - 0.5:
                node.position.y = ty
                return
        _bodies.append({"node": node, "vel": 0.0, "ty": ty, "hold": hold,
                        "bounced": false, "land_sfx": land_sfx})


func _tick_bodies(delta: float) -> void:
        for b in _bodies:
                # THE FREED-NODE LAW: a pop can free a falling gem mid-air -
                # check UNTYPED first, a typed assign of a freed instance errors
                var raw: Variant = b["node"]
                if raw == null or not is_instance_valid(raw):
                        b["ty"] = -1.0
                        continue
                var n: Sprite2D = raw
                if float(b["ty"]) < 0.0 or float(b["hold"]) > 0.0:
                        b["hold"] = float(b["hold"]) - delta
                        continue
                var v: float = float(b["vel"]) + FALL_G * delta
                var y: float = n.position.y + v * delta
                var ty: float = float(b["ty"])
                if y >= ty:
                        if not bool(b["bounced"]) and v > FALL_BOUNCE_V:
                                b["vel"] = -v * FALL_REST
                                b["bounced"] = true
                                n.position.y = ty
                                _land_squash(n)
                                if bool(b["land_sfx"]):
                                        Jukebox.sfx("m_land", -16.0, randf_range(0.9, 1.15))
                        else:
                                n.position.y = ty
                                b["ty"] = -1.0
                                b["vel"] = 0.0
                else:
                        n.position.y = y
                        b["vel"] = v
        _bodies = _bodies.filter(func(b): return is_instance_valid(b["node"]) \
                        and float(b["ty"]) >= 0.0)


func _await_bodies(frames := 600) -> void:
        # when the tick gate is closed (a paused sheet, the probe's hold
        # phase, the dead menu) the falls would freeze mid-air forever - the
        # await pumps the integration itself so every fall ALWAYS lands
        var pumping: bool = phase != "play" or over
        for i in frames:
                if _bodies.is_empty():
                        return
                if pumping:
                        _tick_bodies(get_process_delta_time())
                await get_tree().process_frame


## the physical landing: the gem squashes flat for a beat and springs back
func _land_squash(n: Sprite2D) -> void:
        if not is_instance_valid(n):
                return
        var base: Vector2 = n.scale
        var tw := n.create_tween()
        tw.tween_property(n, "scale", Vector2(base.x * 1.15, base.y * 0.82), 0.05)
        tw.tween_property(n, "scale", base, 0.1) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## a quick position rattle for a node that is about to die (the bomb)
func _shake_node(n: Sprite2D, dur := 0.22) -> void:
        if not is_instance_valid(n):
                return
        var home: Vector2 = n.position
        var tw := n.create_tween()
        for i in 4:
                tw.tween_property(n, "position", home + \
                                Vector2(randf_range(-5, 5), randf_range(-4, 4)), dur / 5.0)
        tw.tween_property(n, "position", home, dur / 5.0)


func _gravity() -> void:
        var movers := []          # {node, ty, hold} - the free-fall wave
        var diag := []            # {node, to} - the fall-around slides
        # v0.3.3-p5 THE SEGMENT SETTLE: the column is split into segments
        # by its solids (standing dirt, jelly). Every segment compresses on
        # its own; ONLY the segment connected to the sky refills (fresh
        # gems enter from above the board - nothing teleports through a
        # solid). THE POCKETS LAW rides here too: a dug hole belongs to the
        # sky segment, so the gems FALL INTO IT (the owner: "an area with
        # no sand in same row, it should let the gems fit in"), while a
        # pocket sealed under dirt or a jelly plug stays sealed.
        var guard := 0
        while guard < 40:
                guard += 1
                var moved := false
                for c in COLS:
                        var r := ROWS - 1
                        while r >= 0:
                                if _earth_at(r, c) or _jelly_at(r, c):
                                        r -= 1
                                        continue
                                var seg_top := r
                                while seg_top >= 0 and not _earth_at(seg_top, c) \
                                                and not _jelly_at(seg_top, c):
                                        seg_top -= 1
                                var write := r
                                for rr in range(r, seg_top, -1):
                                        var cell: Dictionary = grid[rr][c]
                                        if cell.is_empty():
                                                continue
                                        if rr != write:
                                                grid[write][c] = cell
                                                grid[rr][c] = {}
                                                movers.append({"node": cell["node"],
                                                                "ty": _cell_pos(write, c).y})
                                                moved = true
                                        write -= 1
                                # refill only when this segment touches the sky
                                if seg_top < 0:
                                        for rr in range(write, seg_top, -1):
                                                if not grid[rr][c].is_empty():
                                                        continue
                                                var fresh := _new_cell(rr, c, board_o.y - cell_px * 1.2)
                                                grid[rr][c] = fresh
                                                movers.append({"node": fresh["node"],
                                                                "ty": _cell_pos(rr, c).y,
                                                                "hold": randf_range(0.0, 0.06)})
                                r = seg_top
                # v0.3.3-p5 THE FALL-AROUND LAW (the owner's candy-crush
                # school: "the line next to the jelly line, in the empty
                # grids, it will make the gems fell to that side in an
                # accurate way then that side will get filled from top
                # again"): gems resting on a jelly plug SLIDE diagonally
                # around it into the open seats beside, keep falling, and
                # both sides refill from the top
                if mode == "jelly" and _jelly_slide_around(diag):
                        moved = true
                if not moved:
                        break
        # one physical wave - every mover free-falls and lands with a bounce
        for m in movers:
                _fall_to(m["node"], float(m["ty"]), float(m.get("hold", 0.0)))
        # the slides tween on their diagonal path
        for d in diag:
                var n: Sprite2D = d["node"]
                if n == null or not is_instance_valid(n):
                        continue
                var tw := n.create_tween()
                tw.tween_property(n, "position", d["to"], 0.16) \
                                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        if not movers.is_empty():
                await _await_bodies()
        if not diag.is_empty():
                await get_tree().create_timer(0.17, false).timeout
        await get_tree().create_timer(0.04, false).timeout


## the diagonal escape: one pass of slide-around moves (the caller loops
## until quiet). A gem slides when it cannot fall straight (the seat below
## is a plug) and a diagonal seat beside the plug is open - cutting the
## corner through a solid is forbidden.
func _jelly_slide_around(diag: Array) -> bool:
        var moved := false
        for r in range(ROWS - 2, -1, -1):
                for c in COLS:
                        if _jelly_at(r, c) or _earth_at(r, c):
                                continue
                        var cell: Dictionary = grid[r][c]
                        if cell.is_empty():
                                continue
                        var below := r + 1
                        if not _jelly_at(below, c):
                                continue        # only a PLUG spawns a slide
                        var dirs := [1, -1] if randf() < 0.5 else [-1, 1]
                        for dc in dirs:
                                var nc: int = c + dc
                                if nc < 0 or nc >= COLS:
                                        continue
                                if _jelly_at(r, nc) or _earth_at(r, nc):
                                        continue    # no corner-cut through a solid
                                if _jelly_at(below, nc) or _earth_at(below, nc):
                                        continue
                                if not grid[below][nc].is_empty():
                                        continue
                                grid[below][nc] = cell
                                grid[r][c] = {}
                                diag.append({"node": cell["node"],
                                                "to": _cell_pos(below, nc)})
                                moved = true
                                break
        return moved


# ================================================================ the coin
## THE COIN LAW (the owner): every 30s AFTER the last coin was COLLECTED,
## a GOGACoin materializes in a real cell (it never matches, it never
## breaks). Clear under it and it falls like everything else; when it lands
## in the bottom row it drops out of the board and is earned.
func _spawn_coin() -> void:
        var candidates := []
        for r in ROWS - 1:
                for c in COLS:
                        if not _playable(r, c) or grid[r][c].is_empty():
                                continue
                        var cell: Dictionary = grid[r][c]
                        if _is_coin(cell) or String(cell.get("special", "")) == "hyper":
                                continue
                        candidates.append(Vector2i(r, c))
        if candidates.is_empty():
                return
        var at: Vector2i = candidates[randi() % candidates.size()]
        var cell: Dictionary = grid[at.x][at.y]
        # the gem that lived here poofs away (a real seat changes hands)
        if is_instance_valid(cell.get("node")):
                var old_n: Sprite2D = cell["node"]
                var tw0 := old_n.create_tween()
                tw0.set_parallel(true)
                tw0.tween_property(old_n, "scale", Vector2.ONE * 0.02, 0.12)
                tw0.tween_property(old_n, "modulate:a", 0.0, 0.12)
                tw0.chain().tween_callback(old_n.queue_free)
        # the coin DROPS IN from above the board - a normal falling thing
        var n := Sprite2D.new()
        n.texture = _t("coin")
        n.scale = Vector2.ONE * cell_px * 0.8 / 192.0
        var target := _cell_pos(at.x, at.y)
        n.position = Vector2(target.x, board_o.y - cell_px * 0.8)
        n.z_index = 3
        world.add_child(n)
        var tw := n.create_tween()
        tw.tween_property(n, "position", target, 0.32) \
                        .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
        grid[at.x][at.y] = {"color": -1, "coin": true, "node": n}
        coin_cell = at
        coin_clock = -1.0        # ticking stops while a coin lives on the board
        Jukebox.sfx("m_special", -10.0, 1.35)
        _float_text(Vector2(target.x, target.y - cell_px * 0.7), "GOGACOIN!", Color(1, 0.85, 0.3), 26)


func _collect_bottom_coins() -> void:
        if coin_cell.x < 0:
                return
        # THE MUTATION LAW: collect from a duplicate pass
        for c in COLS:
                var cell: Dictionary = grid[ROWS - 1][c]
                if cell.is_empty() or not _is_coin(cell):
                        continue
                _collect_coin_at(Vector2i(ROWS - 1, c))
                return


## one coin earned: +1 run coin, the fly-to-HUD theatre, the seat refills
func _collect_coin_at(at: Vector2i) -> void:
        var cell: Dictionary = grid[at.x][at.y]
        if cell.is_empty() or not _is_coin(cell):
                return
        add_run_coins(1)
        achievement_count("coins_taken", 1)
        Jukebox.sfx("m_coin", -4.0)
        _ring_fx(_cell_pos(at.x, at.y), Color(1, 0.85, 0.3))
        _float_text(_cell_pos(at.x, at.y), "+1", Color(1, 0.85, 0.3), 32)
        _coin_fly_to_hud(_cell_pos(at.x, at.y))
        if is_instance_valid(cell.get("node")):
                (cell["node"] as Sprite2D).queue_free()
        grid[at.x][at.y] = {}
        coin_cell = Vector2i(-1, -1)
        coin_clock = COIN_EVERY    # the owner: from the last COLLECTED
        # THE REFILL LAW (the owner's "the place of it stayed empty" bug):
        # the emptied seat is filled by the very next gravity wave
        _auto_refill()


## the auto-collect tick (the owner: "when it is in the bottom, it should be
## auto collected and not waiting for me to tap it")
func _auto_coin_watch() -> void:
        if coin_cell.x != ROWS - 1 or busy or over or phase != "play":
                return
        _collect_coin_at(coin_cell)


## a gravity wave with no resolve loop attached (the coin's seat refill)
func _auto_refill() -> void:
        _coin_refill_pending = true


func _coin_fly_to_hud(from: Vector2) -> void:
        var vp := get_viewport_rect().size
        var fly := Sprite2D.new()
        fly.texture = _t("coin")
        fly.scale = Vector2.ONE * cell_px * 0.5 / 192.0
        fly.position = from
        fly.z_index = 30
        world.add_child(fly)
        var tw := fly.create_tween()
        tw.tween_property(fly, "position", Vector2(vp.x - 70.0, 44.0), 0.5) \
                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        tw.parallel().tween_property(fly, "scale", Vector2.ONE * 0.16, 0.5)
        tw.tween_callback(fly.queue_free)


# ================================================================ shuffle
func _shuffle_board(silent := false) -> void:
        # collect every movable gem color, re-deal until a legal move exists and
        # the board wakes up quiet (no instant matches)
        var cells := []
        for r in ROWS:
                for c in COLS:
                        if not _playable(r, c) or grid[r][c].is_empty():
                                continue
                        var cell: Dictionary = grid[r][c]
                        if _is_coin(cell) or _is_item(cell):
                                continue
                        cells.append(Vector2i(r, c))
        if cells.size() < 4:
                return
        var guard := 0
        while guard < 60:
                guard += 1
                var colors := []
                for cellp in cells:
                        colors.append(int(grid[cellp.x][cellp.y]["color"]))
                colors.shuffle()
                for i in cells.size():
                        grid[cells[i].x][cells[i].y]["color"] = colors[i]
                if not _find_matches().is_empty():
                        continue
                if _has_valid_move():
                        break
        if not _has_valid_move():
                # a pathological pool (a starved board) - re-deal with the FULL
                # palette; any instant matches cascade free, the board wakes up
                for cellp in cells:
                        var col2 := _roll_color()
                        grid[cellp.x][cellp.y]["color"] = col2
                        if is_instance_valid(grid[cellp.x][cellp.y].get("node")):
                                (grid[cellp.x][cellp.y]["node"] as Sprite2D).texture = tex_gem[col2 % tex_gem.size()]
                        grid[cellp.x][cellp.y]["special"] = ""
        if not silent:
                Jukebox.sfx("m_shuffle", -4.0)
                _ring_fx(_cell_pos(ROWS / 2, COLS / 2), Color(1, 1, 1, 0.7))
                _float_text(_cell_pos(ROWS / 2, COLS / 2), "SHUFFLE!", Color(1, 1, 1), 38)
        for cellp in cells:
                var cell: Dictionary = grid[cellp.x][cellp.y]
                if is_instance_valid(cell.get("node")):
                        (cell["node"] as Sprite2D).texture = tex_gem[int(cell["color"]) % tex_gem.size()]
        # v0.3.3-p2: butterflies retexture after a shuffle (their wings ride
        # their own texture now, so a new color just gets a new bake)
        if mode == "butterflies":
                for r in ROWS:
                        for c in COLS:
                                var cell: Dictionary = grid[r][c]
                                if cell.is_empty():
                                        continue
                                if bool(cell.get("wing", false)):
                                        _retexture_cell(r, c)
        # re-dress specials: an overlay whose host changed color stays (specials
        # keep their own identity), flame/star keep working on any color


func _ring_fx(p: Vector2, col: Color) -> void:
        rings.append({"pos": p, "r": 14.0, "life": 0.4, "max": 0.4, "col": col, "w": 7.0})


# ================================================================ the tick
func _goga_tick(delta: float) -> void:
        if phase != "play" or over:
                return
        _tick_fx(delta)
        _tick_idle(delta)
        # the mode clocks (the base gates pause before this runs)
        if mode != "peace":
                _tick_coin(delta)
                _auto_coin_watch()          # the bottom-row coin earns itself
        else:
                peace_secs += delta
        if _coin_refill_pending and not busy:
                _coin_refill_pending = false
                _gravity()                  # fire-and-forget: the seat refills
        match mode:
                "challenge":
                        _tick_challenge(delta)
                "butterflies":
                        _tick_butterflies(delta)
                "ice":
                        _tick_ice(delta)
                "mine":
                        _tick_mine(delta)
                "drop":
                        _tick_drop(delta)
        _refresh_hud()


func _tick_idle(delta: float) -> void:
        if busy:
                idle_clock = 0.0
                return
        idle_clock += delta
        if idle_clock >= 5.0 and hinted.is_empty():
                var mv := _find_a_move()
                if not mv.is_empty():
                        hinted = mv
                        for cellp in mv:
                                var cell: Dictionary = grid[cellp.x][cellp.y]
                                if cell.is_empty() or not is_instance_valid(cell.get("node")):
                                        continue
                                var n: Sprite2D = cell["node"]
                                var tw := n.create_tween().set_loops(2)
                                tw.tween_property(n, "modulate", Color(1.4, 1.4, 1.2), 0.4)
                                tw.tween_property(n, "modulate", Color.WHITE, 0.4)


func _tick_coin(delta: float) -> void:
        if coin_cell.x >= 0 or busy:
                return
        coin_clock -= delta
        if coin_clock <= 0.0:
                _spawn_coin()
                if coin_cell.x < 0:
                        coin_clock = 2.0    # no seat right now - try again soon


## v0.3.3-p3 THE AFTER-MOVE LAW: everything that answers a COMPLETED move
## walks here, in one order: butterflies rise (after the resolve - never
## during the swap), the drop parcels take their step, the spread laws fire.
func _after_move() -> void:
        if over:
                return
        match mode:
                "butterflies":
                        await _rise_butterflies()
                "jelly":
                        if jelly_cleared_move == 0 and not jelly.is_empty():
                                _jelly_spread()
                        jelly_cleared_move = 0
                        _jelly_win_lose()
                "icecrash":
                        if icr_hit_move == 0 and not icel.is_empty():
                                _icr_spread()
                        icr_hit_move = 0
                        _icr_win_lose()
                "drop":
                        # v0.3.3-p4 THE GRAVITY-ONLY LAW (the owner: "the item
                        # goes down in each move instead of going up, going
                        # down is like saying hey player don't worry we got
                        # this, which is stupid" + the original spec: "the
                        # drop logic will be like the gogacoin one"): parcels
                        # NEVER step on their own - they ride the gravity
                        # waves the player's matches open under them
                        await _drop_settle()
                        if over:
                                return
                        # v0.3.3-p5 THE RISKY PARCEL LAW (the owner: "make
                        # the item if a move happened and it did not moved
                        # down a single grid, makes it go up by one grid,
                        # and make it risky because if it went up, and the
                        # next move still up, the game ends, similar to
                        # butterflies but a little different"): a parcel
                        # that did not descend CLIMBS one row - two climbs
                        # in a row and the parcels climb away
                        await _drop_rise_check()
                        if over:
                                return
                        # THE SPAWN-AFTER-MATCH LAW: a move that popped
                        # something feeds the next parcel in from the top
                        if move_pops > 0 and drop_left > 0 and _count_items() < 4:
                                var free := []
                                for c in COLS:
                                        if grid[0][c].is_empty() and not _jelly_at(0, c) \
                                                        and not _is_item(grid[0][c]):
                                                free.append(c)
                                if not free.is_empty():
                                        _drop_spawn(free[randi() % free.size()])
                        _drop_limits_check()
                        move_pops = 0


## the quiet-board after-care for the layer modes (the win checks that must
## also run after cascades/power blasts, not only after swaps)
func _mode_aftercare() -> void:
        if over:
                return
        match mode:
                "jelly":
                        _jelly_win_lose()
                "icecrash":
                        _icr_win_lose()
                "drop":
                        await _drop_settle()
                        # a power blast that carried a parcel down CALMS it
                        # (the risky climb counts real MOVES only)
                        if grid.size() >= ROWS:
                                for r in ROWS:
                                        for c in COLS:
                                                var cell: Dictionary = grid[r][c]
                                                if not cell.is_empty() and _is_item(cell):
                                                        cell["rose"] = 0


## the parcel rows at the move's start (the risky-climb comparison)
func _drop_capture_rows() -> void:
        if mode != "drop":
                return
        drop_prev.clear()
        if grid.size() < ROWS:
                return
        for r in ROWS:
                for c in COLS:
                        var cell: Dictionary = grid[r][c]
                        if not cell.is_empty() and _is_item(cell):
                                drop_prev[int(cell.get("drop_id", -1))] = r


## v0.3.3-p5 THE RISKY PARCEL LAW (the owner: "make the item if a move
## happened and it did not moved down a single grid, makes it go up by one
## grid, and make it risky because if it went up, and the next move still
## up, the game ends, similar to butterflies but a little different"): a
## parcel that did not descend on this move CLIMBS one row with a red
## warning; two climbs in a row (or a second climb at the top row) and the
## parcels climb away - the run ends.
func _drop_rise_check() -> void:
        if mode != "drop" or over or grid.size() < ROWS:
                return
        var risers := []
        for r in ROWS:
                for c in COLS:
                        var cell: Dictionary = grid[r][c]
                        if cell.is_empty() or not _is_item(cell):
                                continue
                        var id := int(cell.get("drop_id", -1))
                        if not drop_prev.has(id):
                                continue        # born mid-move - it waits
                        if r > int(drop_prev[id]):
                                cell["rose"] = 0
                                continue        # it descended - safe
                        risers.append(Vector2i(r, c))
        drop_prev.clear()
        if risers.is_empty():
                return
        for at in risers:
                var r: int = at.x
                var c: int = at.y
                if not grid[r][c].is_empty() and not _is_item(grid[r][c]):
                        continue        # the wave ate it mid-check
                var cell: Dictionary = grid[r][c]
                var rose: int = int(cell.get("rose", 0)) + 1
                if rose >= 2:
                        _banner("THE PARCELS CLIMBED AWAY!", false)
                        _finish_run("the parcels climbed away")
                        return
                cell["rose"] = rose
                if r > 0:
                        # the climb: swap with the seat above, animate both
                        _swap_model(r, c, r - 1, c)
                        var above: Dictionary = grid[r - 1][c]
                        var below2: Dictionary = grid[r][c]
                        var tw_nodes := []
                        if is_instance_valid(above.get("node")):
                                tw_nodes.append({"n": above["node"],
                                                "to": _cell_pos(r - 1, c)})
                        if not below2.is_empty() and is_instance_valid(below2.get("node")):
                                tw_nodes.append({"n": below2["node"],
                                                "to": _cell_pos(r, c)})
                        for m in tw_nodes:
                                var n: Sprite2D = m["n"]
                                var tw := n.create_tween()
                                tw.tween_property(n, "position", m["to"], 0.2) \
                                                .set_trans(Tween.TRANS_SINE) \
                                                .set_ease(Tween.EASE_IN_OUT)
                        var pn: Sprite2D = above.get("node")
                        if is_instance_valid(pn):
                                var wt := pn.create_tween()
                                wt.tween_property(pn, "modulate",
                                                Color(1.6, 0.5, 0.5), 0.14)
                                wt.tween_property(pn, "modulate", Color.WHITE, 0.3)
                _ring_fx(_cell_pos(r, c), Color(1.0, 0.4, 0.4))
        Jukebox.sfx("m_grace", -7.0, 0.8)
        _banner("A PARCEL ROSE - ONE MORE AND IT'S OVER!", false)
        await get_tree().create_timer(0.22, false).timeout


func _tick_challenge(delta: float) -> void:
        round_clock -= delta
        rush_left = maxf(0.0, rush_left - delta)
        round_bank = score - round_start
        if round_clock <= 0.0 or (round_moves >= round_moves_max \
                        and round_bank < round_goal):
                # THE ROUND FAILED - the owner's law: -500 score, and the
                # v0.3.3-p3 loss bank (a life) now SHOWS its math
                ch_losses += 1
                ch_lives -= 1
                set_score(maxi(0, score - 500))
                Jukebox.sfx("m_lifelost", -4.0)
                if ch_lives <= 0:
                        _banner("OUT OF LIVES  -500", false)
                        _finish_run("out of lives - %d wins / %d losses" % [ch_wins, ch_losses])
                        return
                _banner("ROUND LOST  -500  (%d LIVES LEFT)" % ch_lives, false)
                _next_challenge_round()
        elif round_bank >= round_goal:
                ch_wins += 1
                Jukebox.sfx("m_win_fanfare", -4.0)
                Arc.confetti(_overlay_root_ref(), Vector2(get_viewport_rect().size.x / 2.0, board_o.y), 34)
                _banner("ROUND %d CLEAR!  (%d W / %d L)" % [round_no, ch_wins, ch_losses], true)
                _next_challenge_round()


## the pre-solve (the owner: "calculate the matches and the grid before even
## starting it and then set the requirements and time and allowed moves based
## on that"): every legal swap is played on the model, its immediate yield
## measured, and the round's numbers are DERIVED from the real board.
func _analyze_board() -> Dictionary:
        var gains := []
        for r in ROWS:
                for c in COLS:
                        if not _playable(r, c) or grid[r][c].is_empty():
                                continue
                        for d in [Vector2i(0, 1), Vector2i(1, 0)]:
                                var r2: int = r + d.x
                                var c2: int = c + d.y
                                if not _playable(r2, c2) or grid[r2][c2].is_empty():
                                        continue
                                if _is_coin(grid[r][c]) or _is_coin(grid[r2][c2]) \
                                                or _is_item(grid[r][c]) or _is_item(grid[r2][c2]):
                                        continue
                                _swap_model(r, c, r2, c2)
                                var groups := _find_matches()
                                if not groups.is_empty():
                                        var g := 0
                                        for grp in groups:
                                                g += int(grp["len"])
                                                if grp["cross"].x >= 0:
                                                        g += 6      # a bomb follows
                                                elif int(grp["len"]) >= 5:
                                                        g += 8      # a remover follows
                                                elif int(grp["len"]) == 4:
                                                        g += 4      # a sweeper follows
                                        gains.append(float(g))
                                _swap_model(r, c, r2, c2)
        if gains.is_empty():
                return {"moves": 0, "avg": 4.0, "max": 4.0}
        var total := 0.0
        var best := 0.0
        for g in gains:
                total += g
                best = maxf(best, g)
        return {"moves": gains.size(), "avg": total / gains.size(), "max": best}


func _next_challenge_round() -> void:
        round_no += 1
        _deal_board()
        _roll_round()
        _deal_settle()
        _refresh_hud()


func _roll_round() -> void:
        round_no = maxi(1, round_no)
        # v0.3.3-p4 THE REAL EXAM (the owner: "there is no single challenge
        # at all, where it is the big numbers, why the time is so plenty,
        # why the hell you want just 80 gems? ... you earlier did pong and
        # snake and made them really hard"): a GREEDY PRE-SOLVE plays THIS
        # board move by move - every legal swap is simulated with full
        # cascades and refills, the best move is applied, repeat for the
        # whole move budget. The target then eats 86..97% of what OPTIMAL
        # play scores, the moves barely fit, the clock barely fits.
        var budget := clampi(CH_MOVES_BASE - (round_no - 1) / 2,
                        CH_MOVES_MIN, CH_MOVES_BASE)
        var pre := _presolve_round(budget)
        var achievable := float(pre["achievable"])
        round_moves_max = clampi(int(pre["moves"]), 6, budget)
        var tight := minf(CH_TIGHT0 + 0.015 * float(round_no - 1), CH_TIGHT_MAX)
        round_goal = maxi(30, int(ceilf(achievable * tight / 5.0) * 5.0))
        var per_move := clampf(CH_TIME_PER_MOVE0 - 0.08 * float(round_no - 1),
                        CH_TIME_PER_MOVE_MIN, CH_TIME_PER_MOVE0)
        round_time = float(round_moves_max) * per_move + 2.0
        round_clock = round_time
        round_moves = 0
        round_bank = 0
        round_start = score
        # the twists and the bonus goals keep their shape
        goal_color = -1
        goal_color_left = 0
        goal_special = ""
        goal_special_done = false
        var roll := randf()
        if roll < 0.22:
                twist = "drought"
                drought_color = randi() % COLORS
        elif roll < 0.42:
                twist = "rush"
                rush_left = 10.0
        else:
                twist = ""
        var roll2 := randf()
        if round_no >= 3 and roll2 < 0.22:
                goal_special = ["bomb", "sweep", "hyper"][randi() % 3]
        elif roll2 < 0.30:
                goal_color = randi() % COLORS
                goal_color_left = 4 + randi() % 5
        _banner("ROUND %d - SCORE %d IN %d MOVES - %ds" % [round_no, round_goal,
                        round_moves_max, int(round_time)], true)


# ---------------------------------------------------------------- the sim
## THE PURE-MODEL SIMULATOR: no nodes, no awaits, no fx - colors in arrays.
## The pre-solve and the probe both read it. Empty = -1, dead seat = -9.
func _sim_colors() -> Array:
        var out := []
        for r in ROWS:
                var row := []
                for c in COLS:
                        if not _playable(r, c) or grid[r][c].is_empty():
                                row.append(-9)
                        else:
                                var cell: Dictionary = grid[r][c]
                                if _is_coin(cell) or _is_item(cell):
                                        row.append(-9)
                                else:
                                        row.append(int(cell["color"]))
                out.append(row)
        return out


func _sim_dup(cols: Array) -> Array:
        var out := []
        for row in cols:
                out.append((row as Array).duplicate())
        return out


## groups on the sim colors: {cells: {key}, len, color, cross}
func _sim_find_matches(cols: Array) -> Array:
        var runs := []
        for r in ROWS:
                var c := 0
                while c < COLS:
                        var col: int = cols[r][c]
                        if col < 0:
                                c += 1
                                continue
                        var e := c
                        while e + 1 < COLS and cols[r][e + 1] == col:
                                e += 1
                        if e - c + 1 >= 3:
                                var cells := {}
                                for k in range(c, e + 1):
                                        cells[r * COLS + k] = true
                                runs.append({"cells": cells, "dir": "h",
                                                "len": e - c + 1, "color": col,
                                                "cross": Vector2i(-1, -1)})
                        c = e + 1
        for c in COLS:
                var r := 0
                while r < ROWS:
                        if cols[r][c] < 0:
                                r += 1
                                continue
                        var col: int = cols[r][c]
                        var e := r
                        while e + 1 < ROWS and cols[e + 1][c] == col:
                                e += 1
                        if e - r + 1 >= 3:
                                var cells := {}
                                for k in range(r, e + 1):
                                        cells[k * COLS + c] = true
                                runs.append({"cells": cells, "dir": "v",
                                                "len": e - r + 1, "color": col,
                                                "cross": Vector2i(-1, -1)})
                        r = e + 1
        if runs.is_empty():
                return []
        var groups := []
        var used := []
        for i in runs.size():
                if used.has(i):
                        continue
                var g: Dictionary = runs[i].duplicate()
                g["cells"] = (runs[i]["cells"] as Dictionary).duplicate()
                used.append(i)
                for j in range(i + 1, runs.size()):
                        if used.has(j):
                                continue
                        var o: Dictionary = runs[j]
                        if int(o["color"]) != int(g["color"]):
                                continue
                        var share := false
                        for key in o["cells"]:
                                if (g["cells"] as Dictionary).has(key):
                                        share = true
                                        break
                        if not share:
                                continue
                        used.append(j)
                        for key in o["cells"]:
                                g["cells"][key] = true
                        g["len"] = int(g["len"]) + int(o["len"])
                        if String(o["dir"]) != String(g["dir"]):
                                g["cross"] = Vector2i(0, 0)
                groups.append(g)
        return groups


func _sim_yield(groups: Array) -> int:
        var g := 0
        for grp in groups:
                g += int(grp["len"])
                if (grp["cross"] as Vector2i).x >= 0:
                        g += 6          # a bomb follows
                elif int(grp["len"]) >= 5:
                        g += 8          # a remover follows
                elif int(grp["len"]) == 4:
                        g += 4          # a sweeper follows
        return g


## model gravity: compress down, respawn the top with uniform colors
func _sim_gravity(cols: Array, rng: RandomNumberGenerator) -> void:
        for c in COLS:
                var write := ROWS - 1
                for r in range(ROWS - 1, -1, -1):
                        if cols[r][c] == -9:
                                continue
                        if cols[r][c] == -1:
                                continue
                        if r != write:
                                cols[write][c] = cols[r][c]
                                cols[r][c] = -1
                        write -= 1
                while write >= 0 and cols[write][c] == -9:
                        write -= 1
                for r in range(write, -1, -1):
                        if cols[r][c] == -9:
                                continue
                        cols[r][c] = rng.randi_range(0, COLORS - 1)


## the full cascade after one swap - mutates cols, returns the gain
func _sim_run(cols: Array, rng: RandomNumberGenerator) -> int:
        var gain := 0
        for iter in 6:
                var groups := _sim_find_matches(cols)
                if groups.is_empty():
                        break
                gain += _sim_yield(groups)
                for grp in groups:
                        for key in (grp["cells"] as Dictionary).keys():
                                cols[int(key) / COLS][int(key) % COLS] = -1
                _sim_gravity(cols, rng)
        return gain


## THE GREEDY PRE-SOLVE: play `budget` best moves on a copy of the board,
## return the achievable score and the moves actually playable
func _presolve_round(budget: int) -> Dictionary:
        var rng := RandomNumberGenerator.new()
        rng.seed = 1000 + round_no          # stable per round - the exam is fair
        var cols := _sim_colors()
        var total := 0
        var played := 0
        for k in budget:
                var best_gain := 0
                var best_cols := []
                for r in ROWS:
                        for c in COLS:
                                if cols[r][c] < 0:
                                        continue
                                for d in [Vector2i(0, 1), Vector2i(1, 0)]:
                                        var r2: int = r + d.x
                                        var c2: int = c + d.y
                                        if r2 >= ROWS or c2 >= COLS or cols[r2][c2] < 0:
                                                continue
                                        var work := _sim_dup(cols)
                                        var t: int = work[r][c]
                                        work[r][c] = work[r2][c2]
                                        work[r2][c2] = t
                                        var gain := _sim_run(work, rng)
                                        if gain > best_gain:
                                                best_gain = gain
                                                best_cols = work
                if best_gain <= 0:
                        break
                total += best_gain
                cols = best_cols
                played += 1
        return {"achievable": total, "moves": maxi(played, 6)}


# ================================================================ JELLY
## v0.3.3-p3 THE JELLY MODE (the owner's candy-crush-jelly spec): a connected
## sweet virus. It starts as full lines from the bottom (some levels wear it
## on the sides), a match ADJACENT to jelly dissolves that cell, a move with
## zero jelly cleared SPREADS it (+1..3 connected cells), a spread ONTO a gem
## EATS the gem, jelly never falls and nothing falls past it, and the round
## is limited moves with no score or clock - clear the whole grid from it.
func _jelly_lay_level() -> void:
        jelly = {}
        var rows_n := mini(1 + (jelly_level - 1) / 2, 3)
        for r in range(ROWS - rows_n, ROWS):
                for c in COLS:
                        jelly[r * COLS + c] = true
        # side jelly on odd levels (the owner: "some levels may have jelly in
        # the sides and like that")
        if jelly_level % 2 == 1:
                var side := COLS - 1
                for r in range(ROWS - 2, ROWS - 2 - mini(1 + jelly_level / 3, 3), -1):
                        jelly[r * COLS + 0] = true
                        jelly[r * COLS + side] = true
        jelly_moves = clampi(8 + jelly.size() * 2, 14, 34)
        # eat the gems under the jelly + kill any matches the eating made
        for k in jelly.keys():
                var r := int(k) / COLS
                var c := int(k) % COLS
                if not grid[r][c].is_empty() and is_instance_valid(grid[r][c].get("node")):
                        (grid[r][c]["node"] as Sprite2D).queue_free()
                grid[r][c] = {}
        var guard := 0
        while not _find_matches().is_empty() and guard < 100:
                guard += 1
                for g in _find_matches():
                        for key in g["cells"]:
                                var r := int(key) / COLS
                                var c := int(key) % COLS
                                if not grid[r][c].is_empty():
                                        grid[r][c]["color"] = _roll_color()
                                        if is_instance_valid(grid[r][c].get("node")):
                                                (grid[r][c]["node"] as Sprite2D).texture = \
                                                                tex_gem[int(grid[r][c]["color"]) % tex_gem.size()]
        _refresh_jelly()


func _refresh_jelly() -> void:
        for k in jelly.keys():
                if grid[int(k) / COLS][int(k) % COLS].get("jelly_node") != null:
                        continue
                var r := int(k) / COLS
                var c := int(k) % COLS
                var n := Sprite2D.new()
                n.texture = _t("jelly")
                n.position = _cell_pos(r, c)
                n.scale = Vector2.ONE * cell_px / 120.0
                n.z_index = 1
                world.add_child(n)
                var tw := n.create_tween()
                n.scale = Vector2.ONE * cell_px / 120.0 * 0.2
                tw.tween_property(n, "scale", Vector2.ONE * cell_px / 120.0, 0.3) \
                                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                # the idle wobble - the jelly breathes
                var wob := n.create_tween().set_loops()
                wob.tween_property(n, "scale", Vector2(cell_px / 120.0 * 1.05, cell_px / 120.0 * 0.95), 0.7) \
                                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
                wob.tween_property(n, "scale", Vector2(cell_px / 120.0 * 0.96, cell_px / 120.0 * 1.04), 0.7) \
                                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
                grid[r][c] = {"jelly_node": n}


func _jelly_pop_fx(r: int, c: int) -> void:
        var n: Sprite2D = grid[r][c].get("jelly_node")
        if n != null and is_instance_valid(n):
                var tw := n.create_tween()
                tw.set_parallel(true)
                tw.tween_property(n, "scale", Vector2.ONE * cell_px / 120.0 * 1.4, 0.16) \
                                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
                tw.tween_property(n, "modulate:a", 0.0, 0.16)
                tw.chain().tween_callback(n.queue_free)
        grid[r][c] = {}
        _ring_fx(_cell_pos(r, c), Color(1.0, 0.55, 0.8))


func _jelly_spread() -> void:
        # THE SPREAD LAW (v0.3.3-p4, the owner: "jelly sometimes spread and
        # sometimes isn't? while i said it should be from 2-8 tiles i guess
        # per a match that does not destroy one of it, from my tests it
        # spreads by 0-2?"): a dry move ALWAYS spreads 2..8 CONNECTED cells.
        # The old roll-and-hope loop gave up at a border and called 0 spreads
        # a night. Now: the frontier = every free neighbor of the blob, ring
        # by ring, until the want is fed or the board is literally full.
        if jelly.is_empty():
                return
        var want := JELLY_SPREAD_MIN + randi() % (JELLY_SPREAD_MAX - JELLY_SPREAD_MIN + 1)
        var added: Array = []
        var seen := {}
        for k in jelly.keys():
                seen[int(k)] = true
        var ring := _jelly_frontier(seen)
        while added.size() < want and not ring.is_empty():
                ring.shuffle()
                var next_ring := []
                for k in ring:
                        if added.size() >= want:
                                break
                        added.append(int(k))
                        var fresh := _jelly_frontier_cell(int(k), seen)
                        next_ring.append_array(fresh)
                ring = next_ring
        if added.is_empty():
                return          # the whole grid is jelly - the win check fires
        for k in added:
                jelly[int(k)] = true
                # THE EAT LAW: the jelly consumes the gem that lived there
                var sr := int(k) / COLS
                var sc := int(k) % COLS
                var cell: Dictionary = grid[sr][sc]
                if not cell.is_empty() and is_instance_valid(cell.get("node")):
                        var n: Sprite2D = cell["node"]
                        var tw := n.create_tween()
                        tw.set_parallel(true)
                        tw.tween_property(n, "scale", Vector2.ONE * 0.02, 0.22)
                        tw.tween_property(n, "modulate", Color(1.0, 0.4, 0.8), 0.22)
                        tw.chain().tween_callback(n.queue_free)
                grid[sr][sc] = {}
        Jukebox.sfx("m_jelly_spread2", -4.0)
        _refresh_jelly()
        _banner("THE JELLY SPREADS!  +%d" % added.size(), false)
        _refresh_hud()


## every free neighbor of the blob (one BFS ring)
func _jelly_frontier(seen: Dictionary) -> Array:
        var out := []
        for k in jelly.keys():
                out.append_array(_jelly_frontier_cell(int(k), seen))
        return out


func _jelly_frontier_cell(k: int, seen: Dictionary) -> Array:
        var out := []
        var sr := k / COLS
        var sc := k % COLS
        for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
                var dd: Vector2i = d
                var nr: int = sr + dd.x
                var nc: int = sc + dd.y
                if nr < 0 or nc < 0 or nr >= ROWS or nc >= COLS:
                        continue
                var nk := nr * COLS + nc
                if seen.has(nk):
                        continue
                seen[nk] = true
                out.append(nk)
        return out


func _jelly_win_lose() -> void:
        if over:
                return
        if jelly.is_empty():
                jelly_level += 1
                Jukebox.sfx("m_levelup", -3.0)
                Arc.confetti(_overlay_root_ref(), Vector2(get_viewport_rect().size.x / 2.0, board_o.y), 30)
                _banner("LEVEL %d CLEAR!" % (jelly_level - 1), true)
                jelly_cleared_move = 0
                _jelly_lay_level()
                return
        if jelly_moves <= 0:
                _banner("OUT OF MOVES - THE JELLY HOLDS", false)
                _finish_run("the jelly held - level %d" % jelly_level)


# ================================================================ ICE CRASH
## v0.3.3-p3 (the owner: "like jelly but different, it spreads in a connected
## way, but things go pass through it and it has layers ... up to 5 layers
## with different levels of colors/shaders, level 6 makes it like a rock and
## requires a special thing to crash it down to level 5"): hits happen INSIDE
## the ice (a popped iced cell loses one layer), spread happens on a move
## with zero damage, limited moves, clear it all.
func _icr_lay_level() -> void:
        icel = {}
        _icel_nodes.clear()
        var rows_n := mini(1 + (icr_level - 1) / 2, 3)
        for r in range(ROWS - rows_n, ROWS):
                for c in COLS:
                        # v0.3.3-p4: the layers ramp faster (the owner: "it
                        # has to feel much intense")
                        icel[r * COLS + c] = clampi(1 + (icr_level - 1) / 2, 1, 5)
        # a ROCK core appears from level 3 (the owner's level-6 law)
        if icr_level >= 3:
                var rr6 := ROWS - 1 - randi() % rows_n
                icel[rr6 * COLS + randi() % COLS] = ICE_CRASH_ROCK
        var total_hits := 0
        for k in icel.keys():
                total_hits += mini(int(icel[k]), ICE_CRASH_ROCK - 1)
        icr_moves = clampi(int(float(total_hits) * 0.8) + 6, 12, 42)
        _refresh_icel()


func _refresh_icel() -> void:
        for r in ROWS:
                for c in COLS:
                        _refresh_icel_cell(r, c)


## v0.3.3-p4 THE ICE REGISTRY: the layer sprites live HERE, keyed by cell -
## a popped gem wipes its cell dict and the ice survived as an orphan
## double-drawn over a fresh node (the owner's "ice not reacting to
## crashes" and the leak behind the 100%-destroyed crash)
var _icel_nodes := {}

func _refresh_icel_cell(r: int, c: int) -> void:
        if r < 0 or c < 0 or r >= ROWS or c >= COLS:
                return
        var k := r * COLS + c
        var lvl := int(icel.get(k, 0))
        var have: Sprite2D = _icel_nodes.get(k)
        if have != null and not is_instance_valid(have):
                have = null
        if lvl <= 0:
                if have != null:
                        var tw := have.create_tween()
                        tw.tween_property(have, "modulate:a", 0.0, 0.14)
                        tw.tween_callback(have.queue_free)
                        _icel_nodes.erase(k)
                return
        if have == null:
                have = Sprite2D.new()
                have.position = _cell_pos(r, c)
                have.scale = Vector2.ONE * cell_px / 120.0
                have.z_index = 1          # BEHIND the gem - things pass through
                have.modulate.a = 0.0
                world.add_child(have)
                var tw2 := have.create_tween()
                tw2.tween_property(have, "modulate:a", 0.92, 0.2)
                _icel_nodes[k] = have
        have.texture = _t_icec(lvl)


## v0.3.3-p4 THE REACTION LAW (the owner: "it feels like ice not reacting
## to crashes"): every hit SHATTERS - shards fly, the layer flashes and
## rattles, the ring cracks out
func _icr_crack_fx(r: int, c: int) -> void:
        var p := _cell_pos(r, c)
        var icy := Color(0.72, 0.88, 1.0)
        for i in 6:
                var dir := Vector2.from_angle(randf() * TAU) * randf_range(120.0, 300.0)
                pops.append({"pos": p, "vel": dir, "life": randf_range(0.25, 0.45),
                                "max": 0.45, "r": randf_range(4.0, 9.0), "col": icy})
        rings.append({"pos": p, "r": 6.0, "life": 0.28, "max": 0.28,
                        "col": Color(icy, 0.9), "w": 4.0})
        var n: Sprite2D = _icel_nodes.get(r * COLS + c)
        if n != null and is_instance_valid(n):
                _shake_node(n, 0.16)
                var tw := n.create_tween()
                tw.tween_property(n, "modulate", Color(2.0, 2.0, 2.4), 0.07)
                tw.tween_property(n, "modulate", Color(1, 1, 1, 0.92), 0.18)


func _icr_spread() -> void:
        # v0.3.3-p4 THE GUARANTEED SPREAD (the old roll-and-hope died at a
        # border): the freeze crawls 2..4 connected cells from the blob
        if icel.is_empty():
                return
        var want := 2 + randi() % 3
        var seen := {}
        for k in icel.keys():
                seen[int(k)] = true
        var added := 0
        var ring := []
        for k in icel.keys():
                var sr := int(k) / COLS
                var sc := int(k) % COLS
                for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
                        var dd: Vector2i = d
                        var nr: int = sr + dd.x
                        var nc: int = sc + dd.y
                        if nr < 0 or nc < 0 or nr >= ROWS or nc >= COLS:
                                continue
                        var nk := nr * COLS + nc
                        if seen.has(nk):
                                continue
                        seen[nk] = true
                        ring.append(nk)
        while added < want and not ring.is_empty():
                ring.shuffle()
                var k: int = ring.pop_front()
                var cur := int(icel.get(k, 0))
                if cur < ICE_CRASH_ROCK:
                        icel[k] = mini(5, cur + 1)
                        added += 1
                        _refresh_icel_cell(k / COLS, k % COLS)
                # a maxed cell still passes the crawl through its neighbors
                var sr := k / COLS
                var sc := k % COLS
                for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
                        var dd: Vector2i = d
                        var nr: int = sr + dd.x
                        var nc: int = sc + dd.y
                        if nr < 0 or nc < 0 or nr >= ROWS or nc >= COLS:
                                continue
                        var nk := nr * COLS + nc
                        if not seen.has(nk):
                                seen[nk] = true
                                ring.append(nk)
        if added > 0:
                Jukebox.sfx("m_icespread", -6.0)
                _banner("THE FREEZE CRAWLS!", false)


func _icr_win_lose() -> void:
        if over:
                return
        if icel.is_empty():
                icr_level += 1
                Jukebox.sfx("m_levelup", -3.0)
                Arc.confetti(_overlay_root_ref(), Vector2(get_viewport_rect().size.x / 2.0, board_o.y), 30)
                _banner("LEVEL %d SHATTERED!" % (icr_level - 1), true)
                icr_hit_move = 0
                _icr_lay_level()
                return
        if icr_moves <= 0:
                _banner("OUT OF MOVES - THE ICE HOLDS", false)
                _finish_run("the ice held - level %d" % icr_level)


## the special blasts crack the ROCK (the owner: "requires a special thing to
## crash it down to level 5") - the blast marks its cells before they pop
func _icr_mark_stone(pop: Dictionary) -> void:
        if mode != "icecrash":
                return
        for key in pop.keys():
                var r := int(key) / COLS
                var c := int(key) % COLS
                if _playable(r, c) and not grid[r][c].is_empty() \
                                and int(icel.get(key, 0)) >= ICE_CRASH_ROCK:
                        grid[r][c]["stone_hit"] = 1


# ================================================================ DROP DOWN
## v0.3.3-p3 (the owner: "items dropped from top after there is a match ...
## the round will start with 1-5 items at the top line first, with a UI
## widget tells user how many remaining, it will use both moves and timing or
## one of them as a limit, so there is 3 possibilities ... the drop logic will
## be like the gogacoin one here, make it down down down, make the items be
## simply like this, index of all gems except the selected skin")
func _drop_roll_round() -> void:
        drop_total = clampi(3 + drop_level * 2 + randi() % 2, 3, 9)
        drop_left = drop_total
        var kinds := ["moves", "time", "both"]
        drop_limit_kind = kinds[randi() % 3]
        drop_moves = clampi(12 + drop_total * 2 - drop_level * 2, 10, 26)
        drop_time = clampf(42.0 + 5.0 * float(drop_total) - 4.0 * float(drop_level), 32.0, 80.0)
        _drop_lay()


var drop_level := 1

func _drop_lay() -> void:
        # the round opens with 1-5 parcels already sitting on the top line
        var starting := clampi(1 + randi() % 5, 1, mini(5, drop_left))
        var cols_free := []
        for c in COLS:
                cols_free.append(c)
        cols_free.shuffle()
        for i in starting:
                var c: int = cols_free[i]
                # the parcel TAKES the top seat (the gem that lived there goes)
                var cell: Dictionary = grid[0][c]
                if not cell.is_empty() and is_instance_valid(cell.get("node")):
                        (cell["node"] as Sprite2D).queue_free()
                grid[0][c] = {}
                _drop_spawn(c)


func _drop_spawn(c: int) -> void:
        if drop_left <= 0 or not grid[0][c].is_empty() or _jelly_at(0, c):
                return
        var cell: Dictionary = grid[0][c]
        if not cell.is_empty() and is_instance_valid(cell.get("node")):
                (cell["node"] as Sprite2D).queue_free()
        var n := Sprite2D.new()
        n.texture = _t("parcel")
        n.scale = Vector2.ONE * cell_px * 0.92 / 120.0
        var target := _cell_pos(0, c)
        n.position = Vector2(target.x, board_o.y - cell_px * 0.7)
        n.z_index = 3
        world.add_child(n)
        var tw := n.create_tween()
        tw.tween_property(n, "position", target, 0.28) \
                        .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
        grid[0][c] = {"color": -2, "item": true, "node": n, "drop_id": drop_seq}
        drop_seq += 1
        drop_left -= 1
        Jukebox.sfx("m_itemspawn", -6.0)


## v0.3.3-p4 THE GRAVITY-ONLY DELIVERY: the parcels ride the gravity waves
## exactly like the GOGACoin - a parcel falls when the player's matches open
## the seats under it, NEVER on a timer or a per-move step (the owner: "the
## drop logic will be like the gogacoin one here, make it down down down").
## The loop collects what reached the bottom row and lets the column refill
## until every chain has landed - the old build left the grid hanging empty.
func _drop_settle() -> void:
        var guard := 0
        while guard < 8 and not over:
                guard += 1
                var got := 0
                for c in COLS:
                        var cell: Dictionary = grid[ROWS - 1][c]
                        if cell.is_empty() or not _is_item(cell):
                                continue
                        got += 1
                        add_score(3)
                        achievement_count("items", 1)
                        Jukebox.sfx("m_itemget", -4.0)
                        _ring_fx(_cell_pos(ROWS - 1, c), Color(1.0, 0.9, 0.5))
                        _float_text(_cell_pos(ROWS - 1, c), "+3", Color(1.0, 0.9, 0.5), 30)
                        _coin_fly_to_hud(_cell_pos(ROWS - 1, c))
                        if is_instance_valid(cell.get("node")):
                                (cell["node"] as Sprite2D).queue_free()
                        grid[ROWS - 1][c] = {}
                if got > 0:
                        await _gravity()      # the column refills, chains land
                else:
                        break
        if drop_left <= 0 and _count_items() == 0 and not over:
                # THE ROUND CLEAR: every parcel delivered
                drop_level += 1
                Jukebox.sfx("m_levelup", -3.0)
                Arc.confetti(_overlay_root_ref(), Vector2(get_viewport_rect().size.x / 2.0, board_o.y), 30)
                _banner("ALL PARCELS HOME!  ROUND %d" % (drop_level - 1), true)
                _drop_roll_round()


func _count_items() -> int:
        # THE UNBORN-BOARD LAW: the HUD refresh can fire before the first
        # deal (the drop chip builds at setup) - an empty grid owns 0 parcels
        if grid.size() < ROWS:
                return 0
        var n := 0
        for r in ROWS:
                for c in COLS:
                        if not grid[r][c].is_empty() and _is_item(grid[r][c]):
                                n += 1
        return n


func _drop_limits_check() -> void:
        if over:
                return
        if drop_limit_kind == "time" or drop_limit_kind == "both":
                if drop_time <= 0.0:
                        _banner("TIME UP!", false)
                        _finish_run("the parcels waited too long")
                        return
        if drop_limit_kind == "moves" or drop_limit_kind == "both":
                if drop_moves <= 0:
                        _banner("OUT OF MOVES!", false)
                        _finish_run("the moves ran out on the parcels")


func _tick_drop(delta: float) -> void:
        if drop_limit_kind == "time" or drop_limit_kind == "both":
                drop_time -= delta
                if drop_time <= 0.0:
                        _drop_limits_check()


func _tick_butterflies(delta: float) -> void:
        # v0.3.3-p5 THE INTENSITY LADDER (the owner: "it just spawns one
        # butterfly after a long time then does not spawn more"): the first
        # hatch at 10s, the gap drops 1s per 5 flies spawned (10, 9, 8,
        # 7 ...), and every hatch brings 1..4 flies. The old clock hatched
        # on a 40% dice roll and ONLY when the board was flyless - the
        # mode had no pulse at all.
        fly_secs += delta
        hatch_clock -= delta
        if hatch_clock <= 0.0:
                hatch_clock = maxf(FLY_GAP_MIN,
                                FLY_GAP0 - float(fly_spawned / 5))
                _tick_butterfly_hatch()


func _rise_butterflies() -> void:
        # v0.3.3-p2 THE RISE ANIMATION LAW (the owner: "flies are corrupting
        # the line and it's instant with no animations and makes huge
        # glitches like overlapping things"): the MODEL swaps first, then
        # EVERY displaced node tweens to its new home together - nothing
        # teleports, nothing overlaps.
        # v0.3.3-p3 THE GRACE LAW (the owner: "the butterfly should reach the
        # top, and then after that, if it stayed at the top again, the spider
        # will take it, not take it once it is in the top"): touching row 0
        # is SAFE - the spider stirs and watches that column; only a
        # butterfly STILL on row 0 after another rise gets grabbed.
        # v0.3.3-p4 THE ONE-STEP LAW (the owner: "one move makes butterflies
        # goes up by 4 grid areas??? WTF is that, IT MUST BE one step"): the
        # rise is EXACTLY one row per move - pace stays 1 forever
        var movers := []          # [{node, to}]
        var wings := []
        for r in ROWS:
                for c in COLS:
                        var cell: Dictionary = grid[r][c]
                        if not cell.is_empty() and bool(cell.get("wing", false)):
                                wings.append(Vector2i(r, c))
        wings.sort()            # top rows first - the topmost flies first
        for wcell in wings:
                var r: int = wcell.x
                var c: int = wcell.y
                var cell: Dictionary = grid[r][c]
                if cell.is_empty() or not bool(cell.get("wing", false)):
                        continue        # it was swept up by an earlier mover
                if r == 0:
                        continue        # it waits at the top - the grace law
                # swap with whatever sits above (a coin holds it back)
                _swap_model(r, c, r - 1, c)
                # the arrival on row 0 clears its own flag; leaving it too
                if r - 1 != 0:
                        grid[r - 1][c].erase("top_wait")
                var above: Dictionary = grid[r - 1][c]
                if is_instance_valid(above.get("node")):
                        movers.append({"node": above["node"],
                                        "to": _cell_pos(r - 1, c)})
                var below: Dictionary = grid[r][c]
                if not below.is_empty() and is_instance_valid(below.get("node")):
                        movers.append({"node": below["node"],
                                        "to": _cell_pos(r, c)})
        # one wave, one duration - every mover lands together
        var max_dur := 0.0
        for m in movers:
                var n: Sprite2D = m["node"]
                var dist: float = absf(n.position.y - (m["to"] as Vector2).y)
                var dur: float = clampf(dist / 2200.0, 0.12, 0.22)
                max_dur = maxf(max_dur, dur)
                var tw: Tween
                if n.get_meta("rise_tw", 0):
                        var prev: Tween = n.get_meta("rise_tw")
                        if prev != null and prev.is_valid():
                                prev.kill()
                tw = n.create_tween()
                n.set_meta("rise_tw", tw)
                tw.tween_property(n, "position", m["to"], dur) \
                                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        if not movers.is_empty():
                await get_tree().create_timer(max_dur + 0.02, false).timeout
        # v0.3.3-p5 THE RISE-MATCH LAW (the owner: "if the fly is in a red
        # gem, and there is 2 red gems over it, when it moves, it does not
        # do a match, but if i moved it, it will do a match, this is
        # inaccurate logic ... whatever three same-gems are real valid
        # match"): the rise is a real board change - whatever lines it
        # forms RESOLVE right here, before the spider even looks
        if not over and not _find_matches().is_empty():
                await _resolve_loop()
                if over:
                        return
        # THE GRACE LAW, the walk: a butterfly already waiting on row 0 is
        # grabbed; one that just landed gets the spider's stare for a move
        for c in COLS:
                var cell: Dictionary = grid[0][c]
                if not cell.is_empty() and bool(cell.get("wing", false)):
                        if bool(cell.get("top_wait", false)):
                                await _spider_grabs(Vector2i(0, c))
                                return
        for c in COLS:
                var cell: Dictionary = grid[0][c]
                if not cell.is_empty() and bool(cell.get("wing", false)):
                        cell["top_wait"] = true
                        _spider_alert(c)
                        return
        _spider_hunt()


## the spider leans toward the doomed column - the ONE-move warning
func _spider_alert(col: int) -> void:
        if spider == null or not is_instance_valid(spider):
                return
        var want_x := _cell_pos(0, col).x
        if spider_tw != null and spider_tw.is_valid():
                spider_tw.kill()
        spider_tw = spider.create_tween()
        spider_tw.tween_property(spider, "position:x", want_x, 0.3) \
                        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        var pulse := spider.create_tween()
        pulse.tween_property(spider, "modulate", Color(1.5, 0.75, 0.75), 0.18)
        pulse.tween_property(spider, "modulate", Color.WHITE, 0.3)
        Jukebox.sfx("m_grace", -6.0)
        _banner("THE SPIDER STIRS...", false)


## THE SPIDER (the owner: "it should exist and looks toward the nearest
## butterfly to grab it then the game ends"): it glides along the top rail
## toward the highest butterfly, and when one lands on the top row it sweeps
## over, shrinks it away, and the run ends.
func _spider_hunt() -> void:
        if spider == null or not is_instance_valid(spider):
                return
        var best := Vector2i(-1, -1)
        for r in ROWS:
                for c in COLS:
                        var cell: Dictionary = grid[r][c]
                        if not cell.is_empty() and bool(cell.get("wing", false)):
                                best = Vector2i(r, c)
                                break
                if best.x >= 0:
                        break
        if best.x < 0:
                return
        var want_x := _cell_pos(0, best.y).x
        if spider_tw != null and spider_tw.is_valid():
                spider_tw.kill()
        spider_tw = spider.create_tween()
        spider_tw.tween_property(spider, "position:x", want_x, 0.45) \
                        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _spider_grabs(at: Vector2i) -> void:
        if spider == null or not is_instance_valid(spider):
                _finish_run("the spider dined")
                return
        var cell: Dictionary = grid[at.x][at.y]
        var target := _cell_pos(at.x, at.y)
        if spider_tw != null and spider_tw.is_valid():
                spider_tw.kill()
        var tw := spider.create_tween()
        tw.tween_property(spider, "position", target + Vector2(0, -cell_px * 0.5), 0.4) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
        await tw.finished
        # the grab: the butterfly shrinks INTO the spider
        if is_instance_valid(cell.get("node")):
                var n: Sprite2D = cell["node"]
                var gt := n.create_tween()
                gt.set_parallel(true)
                gt.tween_property(n, "position", spider.position, 0.22) \
                                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                gt.tween_property(n, "scale", Vector2.ONE * 0.02, 0.22)
                gt.chain().tween_callback(n.queue_free)
        grid[at.x][at.y] = {}
        var pulse := spider.create_tween()
        pulse.tween_property(spider, "scale", spider.scale * 1.25, 0.12)
        pulse.tween_property(spider, "scale", spider.scale, 0.14)
        Jukebox.sfx("m_gulp", -2.0)
        Jukebox.sfx("m_spider", -4.0)
        _ring_fx(spider.position, Color(0.7, 0.5, 0.9))
        _banner("THE SPIDER DINED!", false)
        await get_tree().create_timer(0.35, false).timeout
        _finish_run("the spider dined")


func _hatch_butterfly(r: int, c: int) -> void:
        if not _playable(r, c) or grid[r][c].is_empty():
                return
        var cell: Dictionary = grid[r][c]
        if _is_coin(cell):
                return
        cell["wing"] = true
        fly_spawned += 1               # the ladder counts every hatch
        # v0.3.3-p2: the wings are BAKED into the gem's own texture - they
        # move with the sprite forever, nothing can desync or overlap
        _retexture_cell(r, c)
        var n: Sprite2D = cell["node"]
        if is_instance_valid(n):
                var base: Vector2 = n.scale
                n.scale = base * 0.2
                var tw := n.create_tween()
                tw.tween_property(n, "scale", base, 0.3) \
                                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        Jukebox.sfx("m_flutter", -8.0)


var peace_secs := 0.0
var hatch_clock := 10.0         # v0.3.3-p5: the ladder starts at 10s
var fly_secs := 0.0            # the butterflies run age
var fly_spawned := 0            # flies hatched this run (the ladder step)

func _tick_butterfly_hatch_timer(delta: float) -> void:
        pass                     # v0.3.3-p4: the hatch rides _tick_butterflies


## new butterflies hatch on the bottom row - THE INTENSITY LADDER: 1..4
## flies per hatch, the gap walks down 1s per 5 flies spawned
func _tick_butterfly_hatch() -> void:
        if mode != "butterflies":
                return
        if busy:
                hatch_clock = maxf(hatch_clock, 0.5)   # wait out the wave
                return
        var want := FLY_SPAWN_MIN + randi() % (FLY_SPAWN_MAX - FLY_SPAWN_MIN + 1)
        var cols := []
        for c in COLS:
                if _playable(ROWS - 1, c) and not grid[ROWS - 1][c].is_empty() \
                                and not _is_coin(grid[ROWS - 1][c]) \
                                and not _is_item(grid[ROWS - 1][c]) \
                                and not bool(grid[ROWS - 1][c].get("wing", false)):
                        cols.append(c)
        cols.shuffle()
        for i in mini(want, cols.size()):
                _hatch_butterfly(ROWS - 1, cols[i])


func _tick_ice(delta: float) -> void:
        # v0.3.3-p4 ICE STORM REBORN (the owner: "currently ice works via
        # spreading tile by tile, but in the game it spawns first in the
        # tile at the bottom, then runs up, then another layer appear of
        # running up then it freeze and the game is lost, you can modify
        # the speed of each state"): a FRONT spawns at the bottom tile and
        # RUNS UP continuously - tile by tile without waiting - more fronts
        # join on a tightening clock, and a column that freezes to the top
        # ends the run. THE SPEEDS: ICE_RISE0 rows/s (+ICE_RISE_STEP per
        # front), a front every ICE_GAP0s (-ICE_GAP_STEP), max 3 live.
        front_clock -= delta
        if front_clock <= 0.0:
                front_clock = front_gap
                front_gap = maxf(ICE_GAP_MIN, front_gap - ICE_GAP_STEP)
                _ice_spawn_front()
        for f in fronts:
                var col := int(f["col"])
                f["f"] = float(f["f"]) + float(f["speed"]) * delta
                while float(f["f"]) >= 1.0:
                        f["f"] = float(f["f"]) - 1.0
                        frost[col] = mini(ROWS, int(frost[col]) + 1)
                        _ice_segment_fx(col, int(frost[col]))
                        if int(frost[col]) >= ROWS:
                                _ice_freeze_over()
                                return
        _refresh_ice()
        melt_chain = maxf(0.0, melt_chain - delta)
        if melt_chain <= 0.0:
                temp = maxf(0.0, temp - delta * 0.4)


## a new front joins: a random column (a frozen column never re-spawns),
## every front a touch faster than the last - the states are TUNABLE here
func _ice_spawn_front() -> void:
        if fronts.size() >= ICE_FRONTS_MAX:
                return
        var free := []
        for c in COLS:
                if int(frost[c]) < ROWS and _ice_front_at(c).is_empty():
                        free.append(c)
        if free.is_empty():
                return
        var col: int = free[randi() % free.size()]
        front_count += 1
        var speed := minf(ICE_RISE_MAX, ICE_RISE0 + ICE_RISE_STEP * float(front_count - 1))
        fronts.append({"col": col, "f": 0.0, "speed": speed})
        Jukebox.sfx("m_freeze", -8.0, 0.85)
        _banner("AN ICE FRONT RISES!", false)
        _refresh_hud()


func _ice_front_at(c: int) -> Dictionary:
        for f in fronts:
                if int(f["col"]) == c:
                        return f
        return {}


## the rise's entrance: a flash ring at the newly solid segment
func _ice_segment_fx(col: int, segments: int) -> void:
        var r := ROWS - segments
        if r < 0:
                return
        _ring_fx(_cell_pos(r, col), Color(0.75, 0.9, 1.0, 0.9))
        var cell: Dictionary = grid[r][col]
        if not cell.is_empty() and is_instance_valid(cell.get("node")):
                var n: Sprite2D = cell["node"]
                var tw := n.create_tween()
                tw.tween_property(n, "modulate", Color(0.75, 0.9, 1.2), 0.1)
                tw.tween_property(n, "modulate", Color.WHITE, 0.2)


func _ice_freeze_over() -> void:
        Jukebox.sfx("m_gong", -4.0)
        _banner("THE ICE FROZE THE COLUMN!", false)
        _finish_run("the ice froze to the top")


## the wave's vertical groups melt the ice (v0.3.3-p4 THE OWNER'S CORRECTION:
## "sometimes when doing horizontal hit with low ice, it clears the line
## while horizontal must never clear a line, vertical is the one that clears
## it"). Built in _resolve_loop from the wave's real groups; blasts mark
## their columns too (a full-column arm counts as vertical).
var ice_melt_cols := {}

func _ice_melt_wave() -> void:
        for c in ice_melt_cols.keys():
                var ci := int(c)
                var lvl := int(frost[ci])
                if lvl <= 0 and _ice_front_at(ci).is_empty():
                        continue
                var took := lvl
                frost[ci] = 0
                fronts = fronts.filter(func(f): return int(f["col"]) != ci)
                add_score(5 * maxi(took, 1))
                achievement_count("melted", maxi(took, 1))
                Jukebox.sfx("m_melt", -5.0, randf_range(0.85, 1.1))
                melt_chain = 3.0
                temp = minf(1.0, temp + 0.2)
                # the melt theatre: the blocks slide down and fade, top first
                for r in range(ROWS - maxi(took, 1), ROWS):
                        var cell: Dictionary = grid[r][ci]
                        var key := "ice_ov%d" % ((ROWS - 1) - r)
                        if cell.is_empty():
                                continue
                        var ov: Sprite2D = cell.get(key)
                        if ov != null and is_instance_valid(ov):
                                cell[key] = null
                                var idx := (ROWS - 1) - r
                                var tw := ov.create_tween()
                                tw.tween_property(ov, "modulate:a", 0.0, 0.14 + 0.05 * idx)
                                tw.tween_callback(ov.queue_free)
                        _ring_fx(_cell_pos(r, ci), Color(0.75, 0.9, 1.0))
                if temp >= 1.0:
                        temp = 0.0
                        add_score(10)
                        _float_text(_cell_pos(ROWS - 1, ci), "HOT HANDS! +10",
                                        Color(1, 0.6, 0.3), 30)
        ice_melt_cols = {}
        _refresh_ice()
        _refresh_hud()


func _refresh_ice() -> void:
        # v0.3.3-p4 THE CONNECTED COLUMN: solid full-cell frosted blocks
        # stack from the bottom, the snow cap rides the top block, and the
        # live front's PARTIAL segment slides in under it - the ice visibly
        # RUNS UP without waiting (the owner's tile-by-tile blessing)
        for c in COLS:
                var lvl := int(frost[c])
                for r in ROWS:
                        var cell: Dictionary = grid[r][c]
                        if cell.is_empty():
                                continue
                        var depth_from_bottom := (ROWS - 1) - r
                        var want := clampi(lvl - depth_from_bottom, 0, 1)
                        var key := "ice_ov%d" % depth_from_bottom
                        var have: Sprite2D = cell.get(key) if cell.get(key) != null else null
                        if want > 0 and (have == null or not is_instance_valid(have)):
                                var ov := Sprite2D.new()
                                ov.texture = _t("icebt") if depth_from_bottom == lvl - 1 \
                                                else _t("iceb")
                                ov.position = _cell_pos(r, c)
                                ov.scale = Vector2.ONE * cell_px / 120.0
                                ov.modulate.a = 0.0
                                ov.z_index = 1
                                world.add_child(ov)
                                cell[key] = ov
                                var tw := ov.create_tween().set_parallel(true)
                                tw.tween_property(ov, "modulate:a", 0.94, 0.18)
                        elif want == 0 and have != null and is_instance_valid(have):
                                cell[key] = null
                                var tw2 := have.create_tween()
                                tw2.tween_property(have, "modulate:a", 0.0, 0.16)
                                tw2.tween_callback(have.queue_free)
                        elif want > 0 and have != null and is_instance_valid(have):
                                have.texture = _t("icebt") if depth_from_bottom == lvl - 1 \
                                                else _t("iceb")
                                have.modulate.a = 0.94
                # the front's partial segment - the sliding top of the column
                var fr: Dictionary = _ice_front_at(c)
                var pkey := "ice_front"
                var cell2: Dictionary = grid[ROWS - 1 - lvl][c] if lvl < ROWS else {}
                var phave: Sprite2D = cell2.get(pkey) if (not cell2.is_empty() \
                                and cell2.get(pkey) != null) else null
                if not fr.is_empty() and lvl < ROWS and not cell2.is_empty():
                        if phave == null or not is_instance_valid(phave):
                                phave = Sprite2D.new()
                                phave.texture = _t("icebt")
                                phave.scale = Vector2.ONE * cell_px / 120.0
                                phave.z_index = 1
                                phave.modulate.a = 0.0
                                world.add_child(phave)
                                cell2[pkey] = phave
                                var tw3 := phave.create_tween()
                                tw3.tween_property(phave, "modulate:a", 0.8, 0.14)
                        var ff: float = clampf(float(fr["f"]), 0.0, 1.0)
                        var base_y := _cell_pos(ROWS - 1 - lvl, c).y
                        phave.position.y = base_y + (1.0 - ff) * cell_px * 0.9
                        phave.position.x = _cell_pos(ROWS - 1 - lvl, c).x
                elif phave != null and is_instance_valid(phave):
                        cell2[pkey] = null
                        var tw4 := phave.create_tween()
                        tw4.tween_property(phave, "modulate:a", 0.0, 0.12)
                        tw4.tween_callback(phave.queue_free)


func _check_ice_over() -> void:
        for c in COLS:
                if int(frost[c]) >= ROWS:
                        _ice_freeze_over()
                        return


# ================================================================ the mine
## v0.3.3-p2 THE DIAMOND MINE, the owner's Bejeweled Classic spec:
##   - the round starts with 60 seconds
##   - every 25 seconds a NEW EARTH ROW rises from the bottom (sometimes two)
##   - clearing a full earth row (digging all 8 of its cells) gives +25s
##   - matches in the row sitting ON the earth dig the earth below them
##   - the earth reaching the top buries the run

func _tick_mine(delta: float) -> void:
        dig_clock -= delta
        if dig_clock <= 0.0:
                _banner("TIME UP!", false)
                _finish_run("the dig clock ran dry")
                return
        mine_rise_clock -= delta
        if mine_rise_clock <= 0.0:
                # v0.3.3-p5 THE BUSY GATE: the rise never fires under a live
                # resolve, and a double rise walks ONE AT A TIME (the old
                # un-awaited pair lifted the model twice while the first
                # wave was still flying - the owner's mixed-bug family:
                # "the new line comes with the empty areas and the top line
                # become full")
                if busy or mine_rising:
                        mine_rise_clock = 0.05
                        return
                mine_rise_clock = MINE_ROW_TIME
                var rows := 1
                if randf() < MINE_DOUBLE:
                        rows = 2         # "some times it make two rows"
                mine_rising = true
                _mine_rise_deferred(rows)


## the rises run sequentially, never interleaved
func _mine_rise_deferred(rows: int) -> void:
        for i in rows:
                await _mine_rise()
                if over:
                        break
        mine_rising = false


## one earth row rises from the bottom - v0.3.3-p3 THE BOARD LIFT (the owner:
## "when a line comes, it will raise the top line up and remove it in a
## smooth way"): the whole board glides up one cell, the top row glides out
## of the frame and fades. v0.3.3-p5 THE WORLD PUSH (the owner's mixed-bug
## report: "when it moves up while the line has empty areas, the new line
## comes with the empty areas and the top line become full"): the DIRT ROWS
## now RIDE UP with the board exactly like the gems do - the holes keep
## their places inside the band - and the fresh row slides in at the BOTTOM
## (the real Diamond Mine push), never re-laid at the top.
func _mine_rise() -> void:
        if earth_top <= 0:
                return
        # 1 - the top row glides out (the smooth removal)
        for c in COLS:
                var old: Dictionary = grid[0][c]
                if not old.is_empty() and is_instance_valid(old.get("node")):
                        var tn: Sprite2D = old["node"]
                        var tw0 := tn.create_tween()
                        tw0.set_parallel(true)
                        tw0.tween_property(tn, "position:y", tn.position.y - cell_px * 1.5, 0.32) \
                                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                        tw0.tween_property(tn, "modulate:a", 0.0, 0.28)
                        tw0.chain().tween_callback(tn.queue_free)
                grid[0][c] = {}
        # 2 - the model lifts: every row moves up one
        for r in range(1, ROWS):
                grid[r - 1] = grid[r]
        # the coin rode row 0 out of the frame - lost, the clock restarts
        coin_cell = Vector2i(-1, -1)
        coin_clock = COIN_EVERY
        # 3 - THE WORLD PUSH: the dirt rows shift up with everything else
        # (the holes ride inside the band), the fresh row enters at the bottom
        for r in range(earth_top, ROWS):
                earth[r - 1] = earth[r]
        earth_top -= 1
        earth.resize(ROWS)
        _lay_earth_row(ROWS - 1, 1.0)
        # 4 - every surviving gem glides to its new row (one wave, together)
        var movers := []
        for r in range(0, ROWS):
                for c in COLS:
                        var cell: Dictionary = grid[r][c]
                        if cell.is_empty() or not is_instance_valid(cell.get("node")):
                                continue
                        movers.append({"node": cell["node"], "to": _cell_pos(r, c)})
        # 5 - the dirt glides with the world (every surviving dirt node rides
        # one row up from where it stands)
        for r in range(earth_top, ROWS - 1):
                if earth[r] == null:
                        continue
                for c in COLS:
                        if c >= earth[r].size():
                                continue
                        var e: Dictionary = earth[r][c]
                        if e.is_empty() or not e.has("node") \
                                        or not is_instance_valid(e["node"]):
                                continue
                        movers.append({"node": e["node"], "to": _cell_pos(r, c)})
        var max_dur := 0.0
        for m in movers:
                var n: Sprite2D = m["node"]
                var dist: float = absf(n.position.y - (m["to"] as Vector2).y)
                var dur: float = clampf(dist / 1600.0, 0.18, 0.3)
                max_dur = maxf(max_dur, dur)
                var tw := n.create_tween()
                tw.tween_property(n, "position", m["to"], dur) \
                                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        # 6 - the fresh dirt slides in from below the frame
        var row: Array = earth[ROWS - 1]
        for c in COLS:
                var e: Dictionary = row[c]
                if e.has("node") and is_instance_valid(e["node"]):
                        var n: Sprite2D = e["node"]
                        n.position.y += cell_px
                        var tw2 := n.create_tween()
                        tw2.tween_property(n, "position:y",
                                        _cell_pos(ROWS - 1, c).y, 0.3) \
                                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                        if n.has_meta("tr_spr"):
                                var sp: Sprite2D = n.get_meta("tr_spr")
                                if is_instance_valid(sp):
                                        sp.position.y += cell_px
                                        var tw3 := sp.create_tween()
                                        tw3.tween_property(sp, "position:y",
                                                        _cell_pos(ROWS - 1, c).y, 0.3) \
                                                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        if max_dur > 0.0:
                await get_tree().create_timer(max_dur + 0.05, false).timeout
        Jukebox.sfx("m_freeze", -8.0, 0.7)
        _banner("THE EARTH RISES!", false)
        _refresh_hud()
        if earth_top <= 0:
                _banner("BURIED!", false)
                _finish_run("buried by the earth")


## fills one earth row - THE PURE DIRT LAW (the owner: "the sand/whatever
## that tiles are, should contain nothing from the matchable jewels") plus
## THE PROGRESSION LAYERS (the owner: "by progression has intense layers like
## 3 layers or 4 or a level of layers that needs only a special item to
## break it"): dirt digs in 1 match, clay in 2, rock only specials crack.
func _lay_earth_row(r: int, density: float) -> void:
        earth[r] = []
        var deep := float(depth)
        for c in COLS:
                var kind := "dirt"
                var roll := randf()
                if roll < clampf(0.05 + deep / 24.0, 0.0, 0.26):
                        kind = "rock"
                elif roll < clampf(0.22 + deep / 11.0, 0.0, 0.55):
                        kind = "clay"
                var tr := ""
                var roll2 := randf()
                if kind != "rock" and roll2 < 0.10 * density:
                        tr = "artifact"
                elif kind != "rock" and roll2 < 0.26 * density:
                        tr = "diamond"
                elif roll2 < 0.52 * density:
                        tr = "gold"
                var hp := 1
                if kind == "clay":
                        hp = 2
                if kind == "rock":
                        hp = 99        # only specials answer
                var e := {"kind": kind, "hp": hp, "tr": tr}
                e["node"] = _earth_sprite(r, c, kind, tr)
                earth[r].append(e)


func _earth_sprite(r: int, c: int, kind: String, tr: String) -> Sprite2D:
        var n := Sprite2D.new()
        n.texture = _t("dirt" if kind == "dirt" else ("clay" if kind == "clay" else "rock"))
        n.position = _cell_pos(r, c)
        n.scale = Vector2.ONE * cell_px / 120.0
        n.z_index = 2
        world.add_child(n)
        if tr != "":
                var s := Sprite2D.new()
                s.texture = _t(tr)
                s.position = _cell_pos(r, c)
                s.scale = Vector2.ONE * cell_px * 0.62 / 110.0
                s.z_index = 3
                s.modulate = Color(1, 1, 1, 0.9)
                world.add_child(s)
                n.set_meta("tr_spr", s)
        return n


## a match wave drills the earth: v0.3.3-p5 THE POCKETS DIG - every matched
## cell digs the standing earth cell DIRECTLY below itself, so gems sitting
## inside a dug hole dig DEEPER (the old rule only saw the gem row above the
## band, so a hole the gems had fallen into went dead).
## v0.3.3-p3 THE LAYER LAW: clay takes two digs, rock only answers to the
## special blasts (blast_keys) - a plain match just clanks off it.
func _mine_dig(pop: Dictionary, blast_keys := {}) -> void:
        if earth_top >= ROWS:
                return
        var digs := []
        for key in pop.keys():
                var r := int(key) / COLS
                var c := int(key) % COLS
                var dr: int = r + 1
                if dr < earth_top or dr >= ROWS or not _earth_at(dr, c):
                        continue
                digs.append(dr * COLS + c)
        digs.sort()
        for dkey in digs:
                var dr: int = int(dkey) / COLS
                var c: int = int(dkey) % COLS
                var row: Array = earth[dr]
                if row.size() <= c:
                        continue
                var e: Dictionary = row[c]
                if e.is_empty() or not e.has("node") \
                                or not is_instance_valid(e["node"]):
                        continue
                var force: bool = blast_keys.has(dkey) \
                                or blast_keys.has((dr - 1) * COLS + c)
                var kind := String(e.get("kind", "dirt"))
                if kind == "rock" and not force:
                        Jukebox.sfx("m_rockhit", -6.0, randf_range(0.9, 1.2))
                        _float_text((e["node"] as Sprite2D).position, "ROCK!",
                                        Color(0.85, 0.85, 0.9), 24)
                        continue
                if kind == "clay" and not force:
                        e["hp"] = int(e.get("hp", 2)) - 1
                        if int(e["hp"]) > 0:
                                Jukebox.sfx("m_dig", -6.0, 1.3)
                                var cn: Sprite2D = e["node"]
                                var ctw := cn.create_tween()
                                ctw.tween_property(cn, "modulate", Color(0.75, 0.6, 0.55), 0.1)
                                ctw.tween_property(cn, "modulate", Color.WHITE, 0.2)
                                continue
                var n: Sprite2D = e["node"]
                _gem_pop_fx(n.position, 2)
                if n.has_meta("tr_spr"):
                        var s: Sprite2D = n.get_meta("tr_spr")
                        if is_instance_valid(s):
                                var tr := String(e.get("tr", ""))
                                var pay: int = int({"gold": 10, "diamond": 25, "artifact": 60}.get(tr, 0))
                                add_score(int(pay))
                                _float_text(s.position, "+%d" % int(pay), Color(1, 0.85, 0.35), 30)
                                Jukebox.sfx("m_" + tr, -4.0)
                                _coin_fly_to_hud(s.position)
                                s.queue_free()
                var tw := n.create_tween()
                tw.tween_property(n, "scale", Vector2.ONE * 0.02, 0.12)
                tw.tween_callback(n.queue_free)
                row[c] = {}
                Jukebox.sfx("m_dig", -5.0, randf_range(0.9, 1.15))
        _mine_row_check()


## the top earth row fully dug -> the whole band SINKS one row (+25s, the
## owner: "clearing a row gives extra 25 seconds") and the board breathes
func _mine_row_check() -> void:
        if earth_top >= ROWS:
                return
        var row: Array = earth[earth_top]
        for c in COLS:
                var e: Dictionary = row[c] if c < row.size() else {}
                if not e.is_empty() and e.has("node") \
                                and is_instance_valid(e["node"]):
                        return          # cells still standing
        # the row is clear: the band sinks with a smooth drop
        depth += 1
        dig_clock += MINE_ROW_BONUS
        Jukebox.sfx("m_descend", -3.0)
        achievement_max("depth", depth)
        _banner("ROW CLEARED!  +%ds" % int(MINE_ROW_BONUS), true)
        var cleared := earth_top
        earth_top += 1
        for r in range(cleared, ROWS):
                if earth[r] == null:
                        continue
                for c in COLS:
                        if c >= earth[r].size():
                                continue
                        var e2: Dictionary = earth[r][c]
                        if e2.is_empty() or not e2.has("node") \
                                        or not is_instance_valid(e2["node"]):
                                continue
                        var n: Sprite2D = e2["node"]
                        var target := _cell_pos(r, c).y
                        var tw := n.create_tween()
                        tw.tween_property(n, "position:y", target, 0.26) \
                                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                        if n.has_meta("tr_spr"):
                                var sp: Sprite2D = n.get_meta("tr_spr")
                                if is_instance_valid(sp):
                                        var tw2 := sp.create_tween()
                                        tw2.tween_property(sp, "position:y", target, 0.26) \
                                                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        _refresh_hud()


# ================================================================ finish
func _finish_run(reason: String) -> void:
        if over:
                return
        _banner(reason, false)
        Jukebox.sfx("m_lose_org", -4.0)
        if mode == "challenge":
                achievement_max("challenge_best", score)
        if mode == "peace":
                achievement_count("peace_secs", int(peace_secs))
        achievement_count("runs_done", 1)
        check_achievements()
        Jukebox.stop_music()
        finish_run(score)


# ================================================================ the power rail
## THE CANDY-CRUSH LAYER: four tap powers, unlocked once with the wallet,
## stocked in-play up to 3 each, refilled with the ROUND balance (the coins
## this run collected from the board) - never the box wallet mid-run.
func _build_rail() -> void:
        var vp := get_viewport_rect().size
        rail = Control.new()
        rail.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
        rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var banner := banner_bottom()
        rail.offset_top = -(banner + 150.0)
        rail.offset_bottom = -banner
        _overlay_root_ref().add_child(rail)
        var row := HBoxContainer.new()
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        row.add_theme_constant_override("separation", 14)
        row.set_anchors_preset(Control.PRESET_FULL_RECT)
        row.offset_top = 6
        row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        rail.add_child(row)
        for pid in POWER_ORDER:
                row.add_child(_rail_slot(pid))
        if mode == "peace":
                rail.visible = false        # the owner: peace wears nothing


func _rail_slot(pid: String) -> Button:
        # v0.3.3-p3 THE RICH ICON RAIL (the owner: "redesign the powerups to
        # look more rich, also remove the other text ... just show empty or nn
        # or grayed out, let the name in the buy pop-up"): the slot is the
        # ICON ONLY - a count bubble top-right, three stock pips underneath,
        # gray when locked/empty/spent. The name and the prices live in the
        # buy popup.
        var p: Dictionary = POWERS[pid]
        var b := Button.new()
        b.custom_minimum_size = Vector2(118, 118)
        var sb := Arc.panel_style(Arc.CARD, 26, 6)
        b.add_theme_stylebox_override("normal", sb)
        var sbp := sb.duplicate() as StyleBoxFlat
        sbp.bg_color = sbp.bg_color.darkened(0.07)
        b.add_theme_stylebox_override("pressed", sbp)
        var ic := TextureRect.new()
        ic.texture = load(String(p["icon"]))
        ic.set_anchors_preset(Control.PRESET_FULL_RECT)
        ic.offset_left = 10
        ic.offset_right = -10
        ic.offset_top = 10
        ic.offset_bottom = -10
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(ic)
        var bubble := Arc.fit_label("", 22, Color.WHITE, 54)
        bubble.set_anchors_preset(Control.PRESET_TOP_RIGHT)
        bubble.offset_left = -46
        bubble.offset_top = -2
        bubble.offset_right = -4
        bubble.offset_bottom = 32
        bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(bubble)
        var pips := Arc.fit_label("", 15, Color("2c8a44"), 100)
        pips.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
        pips.offset_top = -26
        pips.offset_bottom = -6
        pips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(pips)
        rail_slots[pid] = {"btn": b, "dots": pips, "price": bubble, "icon": ic}
        b.pressed.connect(func(): _rail_tap(pid))
        return b


func _refresh_rail() -> void:
        if rail == null:
                return
        for pid in POWER_ORDER:
                var slot: Dictionary = rail_slots[pid]
                var n := int(charges[pid])
                var owned: bool = Box.item_owned(game_id, "power", pid)
                var pips: Label = slot["dots"]
                var bubble: Label = slot["price"]
                var btn: Button = slot["btn"]
                var ic: TextureRect = slot["icon"]
                var spent_out: bool = owned and n <= 0 and int(power_used[pid]) >= POWER_MAX
                bubble.text = str(n) if (owned and n > 0) else ""
                if spent_out:
                        # THE GRAY-OUT LAW (the owner): all 3 used this run ->
                        # the slot goes gray and dead until the next run
                        pips.text = "- - -"
                        pips.add_theme_color_override("font_color", Color(0.5, 0.46, 0.42))
                        btn.modulate = Color(1, 1, 1, 0.38)
                        btn.disabled = true
                else:
                        btn.disabled = false
                        btn.modulate = Color(1, 1, 1, 1) if (owned and n > 0) \
                                        else Color(1, 1, 1, 0.55)
                        if not owned:
                                pips.text = "+"
                                pips.add_theme_color_override("font_color", Color(0.62, 0.5, 0.3))
                        elif n > 0:
                                pips.text = "*".repeat(n) + ("o".repeat(POWER_MAX - n))
                                pips.add_theme_color_override("font_color", Color("2c8a44"))
                        else:
                                pips.text = "o".repeat(POWER_MAX)
                                pips.add_theme_color_override("font_color", Color(0.62, 0.5, 0.36))
                var sb := btn.get_theme_stylebox("normal") as StyleBoxFlat
                if spent_out:
                        sb.set_border_width_all(0)
                else:
                        btn.modulate = Color(1, 1, 1, 1) if spent_out == false else btn.modulate
                        if armed == pid:
                                sb.set_border_width_all(4)
                                sb.border_color = Arc.ACCENT
                        elif n > 0 and owned:
                                sb.set_border_width_all(2)
                                sb.border_color = Arc.GOOD
                        else:
                                sb.set_border_width_all(0)


func _rail_tap(pid: String) -> void:
        if phase != "play" or over or pick_open or mode == "peace" \
                        or sheet_open_count() > 0:
                return
        var owned: bool = Box.item_owned(game_id, "power", pid)
        var n := int(charges[pid])
        if not owned:
                _power_sheet(pid)
                return
        _rail_punch(pid)
        if armed == pid:
                armed = ""
                _set_armed_cursor(false)
                _refresh_rail()
                return
        if n <= 0:
                # THE BUY POPUP: empty -> the quantity arrows ask how many
                # (max 3 - used), the full balance is shown, the round pays
                if int(power_used[pid]) >= POWER_MAX:
                        return              # grayed on the rail anyway
                _power_sheet(pid)
                return
        if pid == "shuffle":
                charges[pid] = n - 1
                power_used[pid] = int(power_used[pid]) + 1
                _refresh_rail()
                await _shuffle_board(false)
                await _resolve_after_power()
                return
        armed = pid
        _rail_punch(pid)
        _set_armed_cursor(true)
        _refresh_rail()
        _toast_show("tap the board - %s" % String(POWERS[pid]["name"]).to_upper())


## THE ARM SFX FADE LAW (v0.3.3-p4, the owner: "the SFX that appears after
## selecting a powerup, it should fade-in then fade-out smoothly when
## executed or discarded"): the armed hum rides its OWN player - a soft
## fade-in on arm, a smooth fade-out on fire or discard.
var _arm_snd: AudioStreamPlayer = null

func _arm_sound_fade_in() -> void:
        var path := "res://assets/audio/sfx/m_arm.wav"
        if not ResourceLoader.exists(path):
                return
        if _arm_snd == null:
                _arm_snd = AudioStreamPlayer.new()
                _arm_snd.bus = "SFX"
                add_child(_arm_snd)
        _arm_snd.stream = load(path)
        _arm_snd.volume_db = -38.0
        _arm_snd.pitch_scale = 1.0
        _arm_snd.play()
        var tw := _arm_snd.create_tween()
        tw.tween_property(_arm_snd, "volume_db", -8.0, 0.22) \
                        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _arm_sound_fade_out() -> void:
        if _arm_snd == null or not is_instance_valid(_arm_snd) \
                        or not _arm_snd.playing:
                return
        var snd := _arm_snd
        var tw := snd.create_tween()
        tw.tween_property(snd, "volume_db", -40.0, 0.18) \
                        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
        tw.tween_callback(snd.stop)


## the slot answers the tap with a physical punch (v0.3.3-p4: "powerups
## animating is poor and feels instant")
func _rail_punch(pid: String) -> void:
        var slot: Dictionary = rail_slots.get(pid, {})
        var b: Button = slot.get("btn")
        if b == null or not is_instance_valid(b):
                return
        b.pivot_offset = b.size / 2.0
        var tw := b.create_tween()
        tw.tween_property(b, "scale", Vector2.ONE * 1.14, 0.07) \
                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.tween_property(b, "scale", Vector2.ONE, 0.16) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_armed_cursor(on: bool) -> void:
        if on and armed_cursor == null:
                _arm_sound_fade_in()
                armed_cursor = Sprite2D.new()
                armed_cursor.texture = _t("diamond")
                armed_cursor.scale = Vector2.ONE * cell_px * 1.5 / 120.0
                armed_cursor.z_index = 40
                armed_cursor.modulate = Color(1, 0.85, 0.4, 0.85)
                world.add_child(armed_cursor)
                var tw := armed_cursor.create_tween().set_loops()
                tw.tween_property(armed_cursor, "rotation", 0.5, 1.2)
                tw.tween_property(armed_cursor, "rotation", -0.5, 1.2)
        elif not on and armed_cursor != null and is_instance_valid(armed_cursor):
                _arm_sound_fade_out()
                armed_cursor.queue_free()
                armed_cursor = null


func _fire_power(cellp: Vector2i) -> void:
        var pid := armed
        if pid == "" or cellp.x < 0 or busy:
                return
        if pid != "shuffle" and not _playable(cellp.x, cellp.y):
                return
        var n := int(charges[pid])
        if n <= 0:
                armed = ""
                _set_armed_cursor(false)
                _refresh_rail()
                return
        # THE VAPOR LAW (v0.3.3-p2, the owner's "sound only, no effect" bug):
        # vapor aims at a COLOR - an empty seat or the coin is a rejected aim,
        # the charge STAYS, the cursor stays armed
        if pid == "vapor":
                var vc := _color_at(cellp.x, cellp.y)
                if vc < 0:
                        Jukebox.sfx("error", -10.0)
                        _toast_show("tap a gem - the vapor needs a color")
                        return
        charges[pid] = n - 1
        power_used[pid] = int(power_used[pid]) + 1
        armed = ""
        _rail_punch(pid)
        _set_armed_cursor(false)
        _refresh_rail()
        busy = true
        _wave_o = Vector2(cellp.x, cellp.y)
        var pop := {}
        match pid:
                "line":
                        for c in COLS:
                                if _playable(cellp.x, c):
                                        pop[cellp.x * COLS + c] = true
                        for r in ROWS:
                                if _playable(r, cellp.y):
                                        pop[r * COLS + cellp.y] = true
                        # the column arm IS a vertical full-column hit - it
                        # melts the ice in that column (v0.3.3-p4 law)
                        if mode == "ice":
                                ice_melt_cols[cellp.y] = true
                        beams.append({"a": _cell_pos(cellp.x, 0),
                                        "b": _cell_pos(cellp.x, COLS - 1), "life": 0.3, "max": 0.3})
                        beams.append({"a": _cell_pos(0, cellp.y),
                                        "b": _cell_pos(ROWS - 1, cellp.y), "life": 0.3, "max": 0.3})
                        Jukebox.sfx("m_star", -4.0)
                "bomb":
                        # v0.3.3-p4 THE DEAD-BOMB FIX (the owner: "the bomb one
                        # currently has it's effect inactive? which is weird in
                        # many ways"): patch 3 called _blast_cells("flame", ...)
                        # - a kind the owner's table retired. The bomb blasts
                        # like the BOMB it is.
                        var extra := _blast_cells("bomb", cellp.x, cellp.y)
                        for key in extra:
                                pop[key] = true
                        Jukebox.sfx("m_flame", -4.0)
                "vapor":
                        var col := _color_at(cellp.x, cellp.y)
                        for r in ROWS:
                                for c in COLS:
                                        if _playable(r, c) and not grid[r][c].is_empty() \
                                                        and not _is_coin(grid[r][c]) \
                                                        and not _is_item(grid[r][c]) \
                                                        and _color_at(r, c) == col:
                                                pop[r * COLS + c] = true
                                                # the vapour wave is VISIBLE: every
                                                # doomed gem flashes before it pops,
                                                # and the wipe CLIMBS bottom-to-up
                                                var vn: Sprite2D = grid[r][c].get("node")
                                                if is_instance_valid(vn):
                                                        var vt := vn.create_tween()
                                                        vt.tween_property(vn, "modulate",
                                                                        Color(1.6, 0.6, 1.8), 0.16)
                        pop[cellp.y * COLS + cellp.x] = true
                        _wave_bottomup = true
                        for r in ROWS:
                                wipes.append({"row": r, "t": 0.0, "max": 0.3,
                                                "col": Color(1.0, 0.7, 1.0),
                                                "delay": float(ROWS - 1 - r) * REMOVER_ROW_T})
                        Jukebox.sfx("m_hyper", -5.0)
        achievement_count("powers_used", 1)
        await _resolve_from_pop(pop)
        busy = false


## the powers and the shuffle resolve through the same loop the swaps use
func _resolve_from_pop(pop: Dictionary) -> void:
        if pop.is_empty():
                return
        cascade = 0
        cascade += 1
        var queue := []
        for key in pop.keys():
                var r := int(key) / COLS
                var c := int(key) % COLS
                if _playable(r, c) and not grid[r][c].is_empty():
                        var sp := String(grid[r][c].get("special", ""))
                        if sp != "":
                                queue.append({"r": r, "c": c, "kind": sp})
        var detonated := {}
        while not queue.is_empty():
                var it: Dictionary = queue.pop_front()
                var dkey := int(it["r"]) * COLS + int(it["c"])
                if detonated.has(dkey):
                        continue
                detonated[dkey] = true
                var extra := _blast_cells(String(it["kind"]), int(it["r"]), int(it["c"]))
                for key in extra:
                        if not pop.has(key):
                                pop[key] = true
                                var r := int(key) / COLS
                                var c := int(key) % COLS
                                if _playable(r, c) and not grid[r][c].is_empty():
                                        var sp2 := String(grid[r][c].get("special", ""))
                                        if sp2 != "" and not detonated.has(key):
                                                queue.append({"r": r, "c": c, "kind": sp2})
        # v0.3.3-p4: the powers ride the WAVE ORIGIN's stagger - the wave
        # spreads from the tapped cell outward; the vapor CLIMBS bottom-up
        # like the remover it imitates
        _icr_mark_stone(pop)
        var stag := {}
        for key in pop.keys():
                var r := int(key) / COLS
                var c := int(key) % COLS
                if _wave_bottomup:
                        stag[key] = float(ROWS - 1 - r) * REMOVER_ROW_T \
                                        + float(c) * REMOVER_CELL_T
                else:
                        stag[key] = Vector2(_wave_o.x - r, _wave_o.y - c).length() * BOMB_RING_T
        await _pop_cells(pop, [], stag, pop.duplicate())
        _wave_bottomup = false
        while true:
                if over:
                        return
                var groups := _find_matches()
                if groups.is_empty():
                        break
                cascade += 1
                var pop2 := {}
                for g in groups:
                        for key in g["cells"]:
                                pop2[key] = true
                await _pop_cells(pop2, [])
                if cascade >= 2:
                        _combo_banner(cascade)
                await _gravity()
        await _gravity()
        _collect_bottom_coins()
        if mode == "mine":
                _mine_row_check()
        # v0.3.3-p4: the layer modes' win/lose + the drop settle ride the
        # power path too (a patch-3 gap: only the swap path checked them)
        await _mode_aftercare()
        move_pops = 0
        if not _has_valid_move():
                await _shuffle_board(true)


func _resolve_after_power() -> void:
        await _resolve_from_pop({})


# ------------------------------------------------ the power sheets
## THE BUY POPUP (v0.3.3-p1, the owner: "when the power is empty, user will
## click and it will show the buying menu for it and will ask for number
## with arrows start from 1 to 3 with dynamic updates like only 2 if
## already 1 used, and gray out the power if the user used all 3 already,
## make it in that buying pop-up shows the GOGABox full balance"):
##  - not owned  -> the wallet UNLOCK button (the full balance pays once)
##  - empty      -> the quantity arrows 1..(3 - used), the total updates
##                  live, the ROUND balance pays, BOTH balances are shown
##  - 3 spent    -> the rail slot itself grays out; the popup never opens
func _power_sheet(pid: String) -> void:
        var sheet := sheet_push(0.0, "power")
        var p: Dictionary = POWERS[pid]
        var t := Arc.fit_label(String(p["name"]).to_upper(), 36, Arc.INK, 560)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var d := Arc.fit_label(String(p["desc"]), 22, Color(0.45, 0.38, 0.28), 560)
        d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(d)
        # THE GLOBAL WALLET LAW (v0.3.3-p2, the owner: "make powerups be based
        # on global GOGACoins and not round-balance"): the popup shows the
        # FULL GOGABox balance and the buy pays it. The round balance is a
        # scoreboard, never a wallet.
        wallet_chip = Arc.coin_chip()
        wallet_chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet_chip)
        var owned: bool = Box.item_owned(game_id, "power", pid)
        if not owned:
                var buy := Arc.button("UNLOCK  -  %d GOGACoins" % int(p["price"]),
                                Vector2(560, 84), 24, Arc.GOOD, func():
                                if Box.spend(int(p["price"])):
                                        Box.buy_item(game_id, "power", pid, 0)
                                        Jukebox.sfx("m_goal", -4.0)
                                        Arc.confetti(_overlay_root_ref(), get_viewport_rect().size / 2.0, 30)
                                        _power_sheet_close()
                                        _refresh_rail()
                                else:
                                        Jukebox.sfx("error", -6.0)
                                        _toast_show("need %d more GOGACoins" % (int(p["price"]) - Box.coins())))
                sheet.add_child(buy)
        else:
                var n := int(charges[pid])
                var used := int(power_used[pid])
                var max_buy: int = POWER_MAX - used - n
                if max_buy <= 0:
                        var done := Arc.fit_label("all %d spent this run - the next run restocks"
                                        % POWER_MAX, 24, Color("2c8a44"), 560)
                        done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        sheet.add_child(done)
                else:
                        # THE ARROWS: - / qty / + , the total rides the qty and
                        # the cap is dynamic (the owner: "arrows start from 1 to
                        # 3 with dynamic updates like only 2 if already 1 used")
                        # (a Dictionary box: GDScript lambdas capture by VALUE -
                        # a plain int would mutate only the handler's own copy)
                        var qty_box := {"n": 1}
                        var row := HBoxContainer.new()
                        row.alignment = BoxContainer.ALIGNMENT_CENTER
                        row.add_theme_constant_override("separation", 14)
                        sheet.add_child(row)
                        var minus := Arc.button("-", Vector2(96, 84), 40, Arc.CARD_2, func(): pass)
                        var qlabel := Arc.fit_label("1", 40, Arc.INK, 90)
                        qlabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        var plus := Arc.button("+", Vector2(96, 84), 40, Arc.CARD_2, func(): pass)
                        row.add_child(minus)
                        row.add_child(qlabel)
                        row.add_child(plus)
                        var total := Arc.fit_label("", 26, Arc.HOT, 560)
                        total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        sheet.add_child(total)
                        var stock := Arc.fit_label("", 20, Color(0.55, 0.45, 0.3), 560)
                        stock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        sheet.add_child(stock)
                        var repaint := func():
                                var q: int = int(qty_box["n"])
                                qlabel.text = str(q)
                                total.text = "BUY %d  -  %d GOGACoins" % [q, q * int(p["refill"])]
                                stock.text = "stocked %d/3  -  %d used this run" % [n + used, used]
                                if wallet_chip != null and is_instance_valid(wallet_chip):
                                        (wallet_chip.get_child(0).get_child(
                                                wallet_chip.get_child(0).get_child_count() - 1)
                                                as Label).text = Box.coins_display()
                                minus.disabled = q <= 1
                                plus.disabled = q >= max_buy
                        minus.pressed.connect(func():
                                qty_box["n"] = maxi(1, int(qty_box["n"]) - 1)
                                repaint.call())
                        plus.pressed.connect(func():
                                qty_box["n"] = mini(max_buy, int(qty_box["n"]) + 1)
                                repaint.call())
                        repaint.call()
                        var buyb := Arc.button("BUY", Vector2(560, 84), 28, Arc.ACCENT, func():
                                var cost: int = int(qty_box["n"]) * int(p["refill"])
                                if Box.spend(cost):
                                        charges[pid] = int(charges[pid]) + int(qty_box["n"])
                                        Jukebox.sfx("m_refill", -4.0)
                                        _power_sheet_close()
                                        _refresh_rail()
                                else:
                                        Jukebox.sfx("error", -6.0)
                                        _toast_show("need %d more GOGACoins" % (cost - Box.coins())))
                        sheet.add_child(buyb)
        var close := Arc.button("CLOSE", Vector2(460, 74), 26, Arc.CARD_2, func(): _power_sheet_close())
        sheet.add_child(close)
        Arc.fit_sheet(sheet, 1)


func _power_sheet_close() -> void:
        sheet_pop()
        wallet_chip = null


# ================================================================ hud
func _refresh_hud() -> void:
        if chip_info == null:
                return
        match mode:
                "challenge":
                        var secs := int(ceilf(round_clock))
                        chip_info.text = "SCORE %d/%d - MV %d/%d - %ds" % [round_bank, round_goal,
                                        round_moves, round_moves_max, secs]
                        chip_info2.text = "R%d  W%d L%d  LIVES %d/%d" % [round_no, ch_wins,
                                        ch_losses, ch_lives, CH_LIVES]
                        chip_info2.add_theme_color_override("font_color",
                                Color("d84a3a") if ch_lives <= 1 else Color("35210f"))
                "peace":
                        chip_info.text = "breathe"
                        chip_info2.text = "%ds" % int(peace_secs)
                "butterflies":
                        chip_info.text = "saved %d" % int(Box.counter(game_id, "butterflies"))
                        var wings_n := 0
                        if grid.size() >= ROWS:
                                for r in ROWS:
                                        for c in COLS:
                                                if not grid[r][c].is_empty() \
                                                                and bool(grid[r][c].get("wing", false)):
                                                        wings_n += 1
                        # v0.3.3-p5: the owner cut the guide words ("this is
                        # shitty thing that we do not use in our designing")
                        chip_info2.text = "flies %d" % wings_n
                "ice":
                        chip_info.text = "heat %d%%" % int(temp * 100.0)
                        var worst := 0
                        for f in frost:
                                worst = maxi(worst, int(f))
                        chip_info2.text = "fronts %d - ice %d/8 - VERTICAL melts" % \
                                        [fronts.size(), worst]
                        chip_info2.add_theme_color_override("font_color",
                                Color("1c6ea8") if worst >= 6 else Color("35210f"))
                "mine":
                        chip_info.text = "%dm  ice-line %ds" % [depth, int(ceilf(mine_rise_clock))]
                        chip_info2.text = "%ds" % int(ceilf(dig_clock))
                        chip_info2.add_theme_color_override("font_color",
                                Color("d84a3a") if dig_clock < 15.0 else Color("35210f"))
                "jelly":
                        chip_info.text = "jelly %d  -  LEVEL %d" % [jelly.size(), jelly_level]
                        chip_info2.text = "moves %d" % maxi(0, jelly_moves)
                        chip_info2.add_theme_color_override("font_color",
                                Color("d84a3a") if jelly_moves <= 5 else Color("35210f"))
                "icecrash":
                        chip_info.text = "ice %d  -  LEVEL %d" % [icel.size(), icr_level]
                        chip_info2.text = "moves %d" % maxi(0, icr_moves)
                        chip_info2.add_theme_color_override("font_color",
                                Color("d84a3a") if icr_moves <= 5 else Color("35210f"))
                "drop":
                        var lim := ""
                        match drop_limit_kind:
                                "moves":
                                        lim = "mv %d" % maxi(0, drop_moves)
                                "time":
                                        lim = "%ds" % int(ceilf(maxf(0.0, drop_time)))
                                "both":
                                        lim = "mv %d - %ds" % [maxi(0, drop_moves),
                                                        int(ceilf(maxf(0.0, drop_time)))]
                        chip_info.text = "parcels left %d" % (drop_left + _count_items())
                        var any_rose := false
                        if grid.size() >= ROWS:
                                for r in ROWS:
                                        for c in COLS:
                                                if not grid[r][c].is_empty() \
                                                                and _is_item(grid[r][c]) \
                                                                and int(grid[r][c].get("rose", 0)) > 0:
                                                        any_rose = true
                        chip_info2.text = "%s  -  round %d%s" % [lim, drop_level,
                                        "  -  RISE!" if any_rose else ""]
                        chip_info2.add_theme_color_override("font_color",
                                Color("d84a3a") if (any_rose or drop_moves <= 4 \
                                                or drop_time <= 10.0) \
                                                else Color("35210f"))


# ================================================================ fx tick
func _tick_fx(delta: float) -> void:
        _tick_bodies(delta)       # THE PHYSICS FALLS first - everything rides them
        # the queue draw - one pass over the pooled fx
        for p in pops:
                if float(p.get("hold", 0.0)) > 0.0:
                        p["hold"] = float(p["hold"]) - delta
                        continue          # a staged pop waits for its sweep
                p["life"] -= delta
                p["pos"] += p["vel"] * delta
                p["vel"].y += 1500.0 * delta
        pops = pops.filter(func(p): return float(p["life"]) > 0.0)
        for r in rings:
                if float(r.get("hold", 0.0)) > 0.0:
                        r["hold"] = float(r["hold"]) - delta
                        continue
                r["life"] -= delta
                r["r"] += 260.0 * delta
        rings = rings.filter(func(r): return float(r["life"]) > 0.0)
        for b in beams:
                b["life"] -= delta
        beams = beams.filter(func(b): return float(b["life"]) > 0.0)
        for z in zaps:
                z["life"] -= delta
        zaps = zaps.filter(func(z): return float(z["life"]) > 0.0)
        for f in floaters:
                f["life"] -= delta
                f["pos"].y -= 46.0 * delta
        floaters = floaters.filter(func(f): return float(f["life"]) > 0.0)
        for s in sweeps:
                s["t"] = float(s["t"]) + delta
        sweeps = sweeps.filter(func(s): return float(s["t"]) < float(s["max"]))
        for w in wipes:
                w["t"] = float(w["t"]) + delta
        wipes = wipes.filter(func(w): return float(w["t"]) < float(w["max"]))
        shake = maxf(0.0, shake - delta * 2.2)
        queue_redraw()


func _draw() -> void:
        if world == null:
                return
        var vp := get_viewport_rect().size
        # THE BOMB SHAKE - the whole world rattles for a beat
        if shake > 0.0:
                world.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 9.0
        elif world.position != Vector2.ZERO:
                world.position = Vector2.ZERO
        for p in pops:
                var a: float = float(p["life"]) / float(p["max"])
                draw_circle(p["pos"], float(p["r"]) * (0.5 + 0.5 * a), Color(p["col"], a))
        for r in rings:
                var a2: float = float(r["life"]) / float(r["max"])
                draw_arc(r["pos"], float(r["r"]), 0.0, TAU, 40, Color(r["col"], a2), float(r["w"]), true)
        for b in beams:
                var a3: float = float(b["life"]) / float(b["max"])
                draw_line(b["a"], b["b"], Color(1.0, 0.95, 0.7, a3 * 0.9), 14.0 * a3 + 2.0)
        for z in zaps:
                var a4: float = float(z["life"]) / float(z["max"])
                # a jagged arc: 5 segments with a wobble
                var prev: Vector2 = z["a"]
                for i in range(1, 6):
                        var t := float(i) / 5.0
                        var pt: Vector2 = (z["a"] as Vector2).lerp(z["b"], t)
                        if i < 5:
                                pt += Vector2(randf_range(-16, 16), randf_range(-16, 16))
                        draw_line(prev, pt, Color(0.8, 0.9, 1.0, a4), 5.0 * a4 + 1.5)
                        prev = pt
        # THE SWEEPER BARS v4: TWO glowing bars race OUTWARD from the birth
        # cell to both edges - the exact shape the spreading pops ride
        for s in sweeps:
                var prog: float = clampf(float(s["t"]) / float(s["max"]), 0.0, 1.0)
                var col: Color = s["col"]
                var from_i: int = int(s.get("from_i", 0))
                if String(s["axis"]) == "h":
                        var y := _cell_pos(int(s["idx"]), 0).y
                        var x0 := _cell_pos(int(s["idx"]), from_i).x
                        var xl: float = maxf(board_o.x, x0 - prog * (x0 - board_o.x))
                        var xr: float = minf(board_o.x + _board_pixel().x,
                                        x0 + prog * (board_o.x + _board_pixel().x - x0))
                        draw_line(Vector2(xl, y), Vector2(x0, y), Color(col, 0.85), 16.0)
                        draw_line(Vector2(x0, y), Vector2(xr, y), Color(col, 0.85), 16.0)
                        draw_line(Vector2(xl, y), Vector2(xr, y), Color(1, 1, 1, 0.5), 5.0)
                        # the racing heads
                        draw_circle(Vector2(xl, y), 9.0, Color(1, 1, 1, 0.9))
                        draw_circle(Vector2(xr, y), 9.0, Color(1, 1, 1, 0.9))
                else:
                        var x2 := _cell_pos(0, int(s["idx"])).x
                        var y0 := _cell_pos(from_i, int(s["idx"])).y
                        var yb: float = board_o.y + _board_pixel().y
                        var yt: float = maxf(board_o.y, y0 - prog * (y0 - board_o.y))
                        var yd: float = minf(yb, y0 + prog * (yb - y0))
                        draw_line(Vector2(x2, yt), Vector2(x2, y0), Color(col, 0.85), 16.0)
                        draw_line(Vector2(x2, y0), Vector2(x2, yd), Color(col, 0.85), 16.0)
                        draw_line(Vector2(x2, yt), Vector2(x2, yd), Color(1, 1, 1, 0.5), 5.0)
                        draw_circle(Vector2(x2, yt), 9.0, Color(1, 1, 1, 0.9))
                        draw_circle(Vector2(x2, yd), 9.0, Color(1, 1, 1, 0.9))
        # THE COLOR-REMOVER WIPE SHIMMER: a rising row of light per wave row
        for w in wipes:
                var del: float = float(w.get("delay", 0.0))
                var tt: float = float(w["t"]) - del
                if tt < 0.0 or tt > float(w["max"]):
                        continue
                var a5: float = 1.0 - tt / float(w["max"])
                var y3 := _cell_pos(int(w["row"]), 0).y
                var col2: Color = w["col"]
                draw_line(Vector2(board_o.x, y3 - 8.0),
                                Vector2(board_o.x + _board_pixel().x, y3 - 8.0),
                                Color(col2, a5 * 0.65), 10.0 * a5 + 2.0)
        for f in floaters:
                var a6: float = float(f["life"]) / float(f["max"])
                var font := ThemeDB.fallback_font
                draw_string(font, f["pos"] + Vector2(2, 2), String(f["txt"]),
                                HORIZONTAL_ALIGNMENT_CENTER, 460, int(f["size"]), Color(0, 0, 0, a6 * 0.5))
                draw_string(font, f["pos"], String(f["txt"]), HORIZONTAL_ALIGNMENT_CENTER,
                                460, int(f["size"]), Color(f["col"], a6))


