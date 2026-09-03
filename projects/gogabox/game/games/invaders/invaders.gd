extends GogaGame
## SPACE INVADERS - the v0.3.2 tour (rebuilt). One war with Space Dash: the
## SSDS crew holds the solar system while the Protector flies the line from
## Neptune inward to the Sun, then into the Hideout. Ten stages, ten waves
## each, wave ten = that world's boss; bosses 3/6/9 run and return for the
## finale gauntlet before THE INVADER. Left half = move, right half = fire.
## (full design: docs/goga_docs/gogames_ideas/invaders.md)
##
## probe: godot --headless --path . res://tests/invaders_probe.tscn

const DIR := "res://assets/games/invaders/"

# ---------------------------------------------------------------- hearts/score
const START_HEARTS := 3
const HEART_EVERY := 1000          # owner: "new heart after 1000 score points"
const WRECK_SCORE := -500          # owner: "each heart loss takes -500 score"
const INVULN_T := 1.4
const SPAM_FLOOR_MS := 30.0        # the lanes spam law (one shot per live frame)

# ---------------------------------------------------------------- power ladder
## owner: "each power level is extra damage, like 1 damage then 2 then 3" -
## the LEVEL is the per-hit damage. 5 levels max ("the user could max 5");
## points to reach each level; death takes 3 LEVELS (the space dash law).
const POWER_MAX := 5
const LVL_PTS := [0, 2, 5, 9, 14]  # cumulative points needed to BE level i+1
const DEATH_POWER_RUNGS := 3

# ---------------------------------------------------------------- loot rhythms
const COIN_WAVES_MIN := 2          # owner: "a GOGACoin after 2-10 waves"
const COIN_WAVES_MAX := 10
const POWER_WAVES_MIN := 1         # owner: "weapon points... 1 per 1-2 waves"
const POWER_WAVES_MAX := 2

## ----------------------------------------------------------------- the crew
## The SSDS ships (Space Dash skins are these same ships - one universe).
## price 0 = the Protector's own hull (starter). The tail color law:
## ember orange, azure blue, verdant green, veteran bright red, phantom red,
## hornet white, titan deep red.
const SHIPS := {
		"azure": {"name": "Azure", "price": 0, "tex": "ship_azure.png",
				"tail": Color(0.45, 0.75, 1.0), "weapon": "orb"},
		"ember": {"name": "Ember", "price": 1500, "tex": "ship_ember.png",
				"tail": Color(1.0, 0.62, 0.18), "weapon": "beam"},
		"verdant": {"name": "Verdant", "price": 2000, "tex": "ship_verdant.png",
				"tail": Color(0.35, 0.95, 0.45), "weapon": "snake"},
		"veteran": {"name": "Veteran", "price": 3000, "tex": "ship_veteran.png",
				"tail": Color(1.0, 0.22, 0.22), "weapon": "arc"},
		"phantom": {"name": "Phantom", "price": 3500, "tex": "ship_phantom.png",
				"tail": Color(1.0, 0.45, 0.45), "weapon": "mg"},
		"hornet": {"name": "Hornet", "price": 4500, "tex": "ship_hornet.png",
				"tail": Color(0.95, 0.97, 1.0), "weapon": "fire"},
		"titan": {"name": "Titan", "price": 6000, "tex": "ship_titan.png",
				"tail": Color(0.62, 0.10, 0.16), "weapon": "missile"},
}
const SHIP_ORDER := ["azure", "ember", "verdant", "veteran", "phantom", "hornet", "titan"]

## loot-pool shop weapons (the space dash pattern: buying = they exist in the
## pool; the pickup SWITCHES you to them, own ladder). No shields here ever.
const SHOP_WEAPONS := {
		"thunder": {"name": "Thunder", "price": 2500},
		"bomb": {"name": "Bomb Launcher", "price": 3500},
}
const SHOP_THEMES := {"name": "Stage Themes Pack", "price": 6000}

## weapon cadences (seconds between shots/shots rhythm)
const ORB_CD := 0.16               # azure: the yellow-weapon cadence, blue balls
const BEAM_CD := 0.20              # ember red beams
const MG_CD := 0.09                # phantom machine gun
const ARC_CD := 0.95               # veteran sound waves
const FIRE_CD := 0.55              # hornet lobs
const MISSILE_CD := 5.0            # owner: titan missile "one per 5 seconds"
## the weapon -> its projectile sprite (the icons and bolts carry the
## weapon's own look, whatever hull fires it - the defender included)
const WEAPON_SPRITE := {"orb": "w_azure", "beam": "w_ember", "snake": "w_verdant",
	"arc": "w_veteran", "mg": "w_phantom", "fire": "w_hornet",
	"missile": "w_titan", "thunder": "fx_thunder", "bomb": "bomb"}
const SNAKE_TICK := 0.5            # verdant: damage is hits/sec - tick 2x/s
const THUNDER_CD := 2.2
const BOMB_CD := 1.4               # owner: bombs have NO ammo limit
const BURN_BASE := 2.0             # hornet burn seconds at L1

## ---------------------------------------------------------------- enemies
## owner score law: +1/+2/+3 only. hp grows 18% per stage ("at the start,
## enemies will not go down, but later they will go down and down" - the
## weapon ladder outgrows them).
const ETYPES := {
		"grunt": {"tex": "en_grunt.png", "hp": 6, "score": 1, "r": 46.0, "scale": 1.0},
		"swift": {"tex": "en_swift.png", "hp": 4, "score": 1, "r": 42.0, "scale": 1.0,
				"weave": 1.0},
		"aimer": {"tex": "en_aimer.png", "hp": 8, "score": 2, "r": 48.0, "scale": 1.0,
				"fires": "aim", "fire_cd": [2.6, 4.2]},
		"diver": {"tex": "en_diver.png", "hp": 5, "score": 1, "r": 40.0, "scale": 1.0,
				"dives": true},
		"tank": {"tex": "en_tank.png", "hp": 22, "score": 2, "r": 60.0, "scale": 1.0},
		"splitter": {"tex": "en_split.png", "hp": 7, "score": 1, "r": 44.0, "scale": 1.0,
				"splits": true},
		"weaver": {"tex": "en_weaver.png", "hp": 10, "score": 2, "r": 50.0, "scale": 1.0,
				"weave": 2.2},
		"spitter": {"tex": "en_spit.png", "hp": 12, "score": 2, "r": 50.0, "scale": 1.0,
				"fires": "fan", "fire_cd": [3.2, 4.4]},
		"brute": {"tex": "en_brute.png", "hp": 30, "score": 3, "r": 62.0, "scale": 1.0,
				"fires": "shotgun", "fire_cd": [3.6, 5.0]},
		"magma": {"tex": "en_magma.png", "hp": 18, "score": 3, "r": 48.0, "scale": 1.0,
				"fires": "aim", "fire_cd": [2.8, 4.0], "trails": true},
		"void": {"tex": "en_void.png", "hp": 26, "score": 3, "r": 54.0, "scale": 1.0,
				"fires": "ring", "fire_cd": [3.4, 4.6], "blink": true},
}
const DIVE_CD := [5.5, 9.0]        # a diver detaches inside this window

## ---------------------------------------------------------------- the tour
## real-world data drives every plate (the background IS the argument).
const STAGES := [
		{"name": "NEPTUNE", "sub": "THE OUTPOST", "bg": "bg_neptune.png",
				"pool": ["grunt", "swift", "diver"],
				"line": "Neptune - 2,100 km/h winds, the fastest sky in the system. The raiders ride them in."},
		{"name": "URANUS", "sub": "THE TILT", "bg": "bg_uranus.png",
				"pool": ["grunt", "swift", "diver", "aimer"],
				"line": "Uranus rolls on its side - 98 degrees - and so does this war."},
		{"name": "SATURN", "sub": "THE RINGS", "bg": "bg_saturn.png",
				"pool": ["grunt", "swift", "aimer", "tank"],
				"line": "Saturn's rings: a billion shards, and every one of them theirs now."},
		{"name": "JUPITER", "sub": "THE GIANT", "bg": "bg_jupiter.png",
				"pool": ["grunt", "swift", "aimer", "tank", "splitter"],
				"line": "Jupiter could swallow 1,300 Earths. Today it only needs to hide them."},
		{"name": "MARS", "sub": "THE RED DUST", "bg": "bg_mars.png",
				"pool": ["grunt", "diver", "aimer", "splitter", "weaver"],
				"line": "Mars - rust, dust and the first footprints of the invasion."},
		{"name": "EARTH", "sub": "HOME", "bg": "bg_earth.png",
				"pool": ["grunt", "diver", "tank", "weaver", "spitter"],
				"line": "HOME. This one is not a line in the sand. This one is everything."},
		{"name": "VENUS", "sub": "THE FURNACE", "bg": "bg_venus.png",
				"pool": ["swift", "diver", "weaver", "spitter", "brute"],
				"line": "Venus - 465 degrees under a crushing sky. Even their hulls hate it here."},
		{"name": "MERCURY", "sub": "THE CRATERS", "bg": "bg_mercury.png",
				"pool": ["swift", "tank", "weaver", "spitter", "brute"],
				"line": "Mercury - 430 by day, -180 by night. No shade out here. Only the line."},
		{"name": "THE SUN", "sub": "THE WALL", "bg": "bg_sun.png",
				"pool": ["tank", "weaver", "spitter", "brute", "magma"],
				"line": "The Sun - 5,500 degrees of wall. This is as far as they get. This is where we stop them."},
		{"name": "THE HIDEOUT", "sub": "THE FRONT DOOR", "bg": "bg_hideout.png",
				"pool": ["weaver", "spitter", "brute", "magma", "void"],
				"line": "Their front door. Everything they are is behind it. End this."},
]
const STAGE_HP_GROWTH := 0.18      # +18% hp per stage

## wave formation patterns (slot layouts, in a 1000x520 local box)
const PATTERNS := ["line", "vee", "arc", "diamond", "columns", "ring", "lattice"]

## ---------------------------------------------------------------- bosses
## every boss: own specials, own voices. "escapes": 3/6/9 leave at 20% hp
## and come back for the finale (the owner's gauntlet law).
const BOSSES := {
		"triton": {"name": "TRITON WARDEN", "tex": "boss_triton.png", "hp": 60,
				"score": 25, "r": 110.0, "moves": ["volley", "divecall"]},
		"monarch": {"name": "TILTED MONARCH", "tex": "boss_monarch.png", "hp": 80,
				"score": 30, "r": 108.0, "moves": ["rolleroll", "ringtilt"]},
		"duke": {"name": "RING DUKE", "tex": "boss_duke.png", "hp": 100,
				"score": 40, "r": 128.0, "moves": ["shardring", "icerain"], "escapes": true},
		"storm": {"name": "STORM TYRANT", "tex": "boss_storm.png", "hp": 130,
				"score": 50, "r": 122.0, "moves": ["redspot", "spiral"]},
		"reaver": {"name": "DUST REAVER", "tex": "boss_reaver.png", "hp": 150,
				"score": 60, "r": 118.0, "moves": ["dustdash", "sandspread"]},
		"mimic": {"name": "THE MIMIC", "tex": "boss_mimic.png", "hp": 170,
				"score": 75, "r": 110.0, "moves": ["mimicbeam", "decoys"], "escapes": true},
		"ash": {"name": "ASH QUEEN", "tex": "boss_ash.png", "hp": 200,
				"score": 90, "r": 116.0, "moves": ["acidrain", "mirror"]},
		"eater": {"name": "SUN EATER", "tex": "boss_eater.png", "hp": 230,
				"score": 110, "r": 116.0, "moves": ["craters", "flarebeam"]},
		"herald": {"name": "SOLAR HERALD", "tex": "boss_herald.png", "hp": 280,
				"score": 150, "r": 124.0, "moves": ["prominence", "heatwave"], "escapes": true},
		"invader": {"name": "THE INVADER", "tex": "boss_invader.png", "hp": 420,
				"score": 200, "r": 150.0, "moves": ["voidflower", "blink", "elitecall"]},
}
const ESCAPE_HP := 0.20            # 3/6/9 run at 20% hp
const INVADER_PHASE2 := 0.40       # rage under 40%

## ---------------------------------------------------------------- defenders
## the DEFEND button: rent a crew ship for 10 waves. One at a time, once per
## ship per run, level-3 weapon, one hit kills, invisible to items.
const DEFEND_WAVES := 10
const DEFENDERS := {
		"azure": {"price": 100}, "ember": {"price": 120}, "verdant": {"price": 150},
		"veteran": {"price": 180}, "phantom": {"price": 200}, "hornet": {"price": 240},
		"titan": {"price": 300},
}

## ---------------------------------------------------------------- dialogue
## alpha pop-ups, white text (the owner's law: translucent enough to see the
## war behind, solid enough to read). Up to 3 variants per situation, rotating.
const LINES := {
		"intro": [
				"SPACE DASH held them off at the rim of the system. This is where they turn. This is where I hold.",
				"I have chased these raiders since the dash wars. They will not touch our sun while I fly.",
				"The crew is still fighting out there in the black. In here, the line is mine.",
		],
		"stage": [
				"Entering %s. The line holds behind me. It ends here.",
				"%s sky ahead. If they pass me here, they pass everything.",
				"One more world between them and home. Not while I fly.",
		],
		"boss_start": [
				"%s on the scope over %s. Whatever it carries - it does not reach the ground.",
				"Big one inbound above %s. %s. Hold my line.",
				"There it is: %s. Every world has a keeper. This one picked the wrong sky.",
		],
		"boss_end": [
				"%s down. The sky over %s is quieter already.",
				"One less hunter above %s. Next world.",
				"That one reports to no one now. Moving on.",
		],
		"escape": {
				"duke": "The Ring Duke bends its ring and RUNS - back toward the hideout. It is calling someone.",
				"mimic": "The Mimic drops our colors and bolts. It flies to answer a signal we cannot hear.",
				"herald": "The Solar Herald dives into the fire and LIVES. All three now wait for their master.",
		},
		"gauntlet": [
				"They came back - all three heralds, kneeling to something bigger in the dark. Finish it.",
				"The hideout doors are open. Whatever wears that throne heard the war outside.",
				"Three keepers, one throne. This is the whole invasion in front of me.",
		],
		"breach": [
				"An enemy reached our solar system. We are in big danger.",
				"One got past me. The planets are exposed. I failed this sky.",
		],
		"ending": "The Invader turns and RUNS - and I am faster. Let it tell them what it saw here.\n\nThe war does not end today. They are always somewhere nearby.\n\nAnd so am I.",
}

## the defender radio (7 ships x call/end/death x 3 variants). The caller is
## the PLAYER'S ship, the called is the rented defender.
const DEFEND_LINES := {
		"azure": {"call": [["OH! Azure, here you are - I really need your powers RIGHT HERE AND RIGHT NOW!", "Azure of the SSDS, answering. The line holds where we stand."],
						["Azure! The sky is too big for one ship today!", "Then it is a good day I was flying nearby. Cover me and I cover you."],
						["I need those blue orbs beside me, Azure!", "Blue dots incoming. Stay on my wing, Protector."]],
				"end": [["sorry %s, I have to get back to help the others!", "Fly safe, Azure. Tell the crew the line held."],
						["the others need me back out there - hold the sky!", "Always do. Go, Azure. We are one sky, all of us."],
						["my ten waves are flown. back to the fleet!", "Good flying, Azure. The gap you leave is safe."]],
				"death": [["I guess I will take rid of them alone. Rest, Azure.", "..."],
						["You blocked that one for me. I will take care of them - take care of yourself, Azure.", "..."],
						["Azure down. One ship, one sky. I carry it from here.", "..."]]},
		"ember": {"call": [["EMBER! Get your fire in this fight RIGHT NOW!", "Ember, burning bright! Point me at them!"],
						["I need your red beams here, Ember!", "Red beams, coming up - nobody slips past us!"],
						["Oh! here you are, Ember - I really need your powers RIGHT HERE AND RIGHT NOW!", "Then watch the sky turn orange!"]],
				"end": [["sorry %s, I have to get back to help the others!", "Go be bright somewhere else, Ember."],
						["the crew needs its fire back out there!", "Keep the line warm, Protector!"],
						["ten waves and my tanks are dry - back to the fleet!", "Good burn, Ember."]],
				"death": [["I guess I will take rid of them alone. Rest, Ember.", "..."],
						["You burned out blocking that hit. I will finish it - rest now, Ember.", "..."],
						["Ember down in a blaze. Their blaze, next.", "..."]]},
		"verdant": {"call": [["VERDANT! I need those sneaky green snakes up here!", "Verdant, coiling in. They will not see the green coming."],
						["Oh! here you are - RIGHT HERE AND RIGHT NOW, Verdant!", "Slithering through their formation as we speak."],
						["Verdant, the line is thin - lend me your beams!", "Green threads through everything. Watch them unravel."]],
				"end": [["sorry %s, I have to get back to help the others!", "Coil back safe, Verdant."],
						["the others call - my snakes fly home!", "Weave well out there, Verdant."],
						["ten waves woven. back to the fleet!", "Good hunting, Verdant."]],
				"death": [["I guess I will take rid of them alone. Rest, Verdant.", "..."],
						["They got through your weave. I will not let it be for nothing.", "..."],
						["Verdant down. The green goes quiet. I do not.", "..."]]},
		"veteran": {"call": [["VETERAN! Sound the arcs - RIGHT HERE AND RIGHT NOW!", "Veteran here. Let the sky hear itself break."],
						["I need your waves, Veteran - they are everywhere!", "Then everywhere they fall. Arcs out!"],
						["Oh! Veteran, just the ship I needed!", "One old hull, all the sound you need."]],
				"end": [["sorry %s, I have to get back to help the others!", "Sound off, Veteran. The sky is yours."],
						["the fleet needs its voice back!", "It will hear me coming. Fly on, Protector."],
						["my ten waves are rung out. going home!", "Ring loud, Veteran."]],
				"death": [["I guess I will take rid of them alone. Rest, Veteran.", "..."],
						["That hit was meant for me. I will spend it well, Veteran.", "..."],
						["Veteran's last arc faded. Mine will not.", "..."]]},
		"phantom": {"call": [["PHANTOM! I need that machine gun chewing RIGHT NOW!", "Phantom, locked on. Listen to me purr."],
						["Oh! here you are, Phantom - RIGHT HERE AND RIGHT NOW!", "Rapid fire, small bites, big piles."],
						["Phantom, swarm inbound - lend me your barrels!", "Barrels hot. Feed me the swarm."]],
				"end": [["sorry %s, I have to get back to help the others!", "Chew through them out there, Phantom."],
						["the crew needs its gunner back!", "They know where to find me. Fly on."],
						["ten waves, a thousand rounds. back to the fleet!", "Good spraying, Phantom."]],
				"death": [["I guess I will take rid of them alone. Rest, Phantom.", "..."],
						["You took that bullet like everything else - fast. Rest, Phantom.", "..."],
						["Phantom offline. My finger is faster anyway.", "..."]]},
		"hornet": {"call": [["HORNET! I need your fire spreading through them RIGHT NOW!", "Hornet, stinging in! Everything they touch will burn!"],
						["Oh! here you are - RIGHT HERE AND RIGHT NOW, Hornet!", "One spark, ten fires. Watch the chain!"],
						["Hornet, their formation is packed - make it count!", "Packed is how they burn best!"]],
				"end": [["sorry %s, I have to get back to help the others!", "Spread your fire far, Hornet."],
						["the others need the sting back out there!", "Keep burning the line clean, Protector."],
						["ten waves of sparks. back to the fleet!", "Good sting, Hornet."]],
				"death": [["I guess I will take rid of them alone. Rest, Hornet.", "..."],
						["Your fire took that one with you. It will not be wasted.", "..."],
						["Hornet down in flames. Theirs are next.", "..."]]},
		"titan": {"call": [["OH! here you are, TITAN - I really need your powers RIGHT HERE AND RIGHT NOW!", "Titan, answering. One missile. Every one of them feels it."],
						["TITAN! The sky is FULL - give me the big blast!", "Full is perfect. I only need one shot every five seconds."],
						["Titan, lend me your thunder from the deep red!", "Deep red, heavy iron. Launching."]],
				"end": [["sorry %s, I have to get back to help the others!", "Carry the big iron safe, Titan."],
						["the fleet needs its missile bank back!", "It never runs dry. Fly on, Protector."],
						["ten waves, ten booms. back to the fleet!", "Boom loud, Titan."]],
				"death": [["I guess I will take rid of them alone. Rest, Titan.", "..."],
						["The heavy one took the heavy hit. I will make it count, Titan.", "..."],
						["Titan down. From here, every shot is mine to make heavy.", "..."]]},
}

# ================================================================= state
var phase := "ready"   # ready|title|wave_in|fight|boss_in|boss|boss_end|gap|breach|ending|over
var stage := 0         # 0..9 (NEPTUNE..THE HIDEOUT)
var wave := 0          # 1..10 inside a stage
var world: Node2D
var rng := RandomNumberGenerator.new()

var ship: Sprite2D
var ship_glow: Sprite2D
var defender: Sprite2D = null         # the rented crew node (visual)
var defender_id := ""                 # "" = none flying
var defender_waves_left := 0
var defender_called: Dictionary = {}  # once-per-run-per-ship
var defender_fire_cd := 0.0

var move_anchor := Vector2.ZERO       # the dario walk law: first left-half touch
var move_idx := -1                    # owns the analog move anchor
var fire_idx := -1
var firing := false
var ship_v := Vector2.ZERO            # for the tail + bank

var hearts := START_HEARTS
var next_heart_at := HEART_EVERY
var invuln := 0.0
var shake := 0.0
var kills := 0

var skin := "azure"                   # the starting ship (Box.skin_on)
var weapon := "orb"                   # current weapon id
var wpower := {}                      # per-weapon level 1..5
var wpts := {}                        # per-weapon points toward the next level
var fire_cd := 0.0
var snake_clock := 0.0
var missile_cd := 0.0
var last_shot_ms := 0

var waves_since_coin := 0
var coin_target := 3
var waves_since_power := 0
var power_target := 1

var enemies: Array = []               # wave enemies (dicts)
var bolts: Array = []                 # player bullets/orbs/beams/bullets/fire
var snakes: Array = []                # verdant weaving beams
var arcs: Array = []                  # veteran sound rings
var missiles: Array = []
var bombs: Array = []
var ebolts: Array = []                # enemy shots
var burns: Array = []                 # hornet burn states on enemies
var loots: Array = []
var trails: Array = []                # dynamic tail dots
var boss: Dictionary = {}             # the active boss ({} when none)
var boss_shards: Array = []           # duke's orbiting shard ring
var boss_decoys: Array = []
var gauntlet: Array = []              # finale sub-phase queue
var gauntlet_i := -1

var form_origin := Vector2.ZERO       # the wave formation anchor
var form_v := Vector2.ZERO
var form_t := 0.0
var wave_clock := 0.0
var stage_transition := 0.0           # theme crossfade clock

var _tex: Dictionary = {}
var fx: Node2D                        # VFX painter (rings/sparks/popups)
var bg_a: TextureRect                 # the two crossfading sky layers
var bg_b: TextureRect
var hud2: CanvasLayer
var hearts_row: HBoxContainer
var weapon_lbl: Label
var power_bar: Control
var boss_bar: Control
var boss_lbl: Label
var wave_lbl: Label                   # the centered wave title
var _ready_card: Control = null
var _sheet_pair: Array = []           # THE PAIR LAW for every sheet
var _dialog_panel: Control = null     # the alpha popup (single, queued)
var _dialog_queue: Array = []
var _dialog_after: Callable = Callable()
var line_roll := {}                   # rotating dialogue variants
var themes_on := false

# ================================================================ setup

func _tex_all() -> void:
		for k in ["ship_azure", "ship_ember", "ship_verdant", "ship_veteran",
						"ship_phantom", "ship_hornet", "ship_titan", "ebolt",
						"en_grunt", "en_swift", "en_aimer", "en_diver", "en_tank",
						"en_split", "en_weaver", "en_spit", "en_brute", "en_magma",
						"en_void", "boss_triton", "boss_monarch", "boss_duke",
						"boss_storm", "boss_reaver", "boss_mimic", "boss_ash",
						"boss_eater", "boss_herald", "boss_invader",
						"w_azure", "w_ember", "w_verdant", "w_veteran", "w_phantom",
						"w_hornet", "w_titan", "bomb", "fx_thunder", "fx_ring",
						"fx_spark", "fx_burn", "fx_trail", "fx_hit", "item_power",
						"item_thunder", "item_bomb", "item_w_azure", "item_w_ember",
						"item_w_verdant", "item_w_veteran", "item_w_phantom",
						"item_w_hornet", "item_w_titan"]:
				_tex[k] = load(DIR + k + ".png")
		for s in STAGES:
				_tex[String(s["bg"]).trim_suffix(".png")] = load(DIR + String(s["bg"]))
		_tex["bg_neutral"] = load(DIR + "bg_neutral.png")
		_tex["coin"] = load("res://assets/ui/coin.png")
		_tex["heart"] = load("res://assets/ui/heart.png")

func _tx(key: String) -> Texture2D:
	return _tex[String(key).trim_suffix(".png")]

func _add_mat() -> CanvasItemMaterial:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		return m

func _goga_setup() -> void:
		rng.randomize()
		_tex_all()
		var vp := get_viewport_rect().size

		# the two crossfading sky layers (the themes-pack law)
		bg_a = TextureRect.new()
		bg_a.size = vp
		bg_a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_a.stretch_mode = TextureRect.STRETCH_SCALE
		bg_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_b = TextureRect.new()
		bg_b.size = vp
		bg_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_b.stretch_mode = TextureRect.STRETCH_SCALE
		bg_b.modulate = Color(1, 1, 1, 0)
		bg_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg_a)
		add_child(bg_b)

		world = Node2D.new()
		add_child(world)

		fx = Node2D.new()
		fx.material = _add_mat()
		fx.draw.connect(_draw_fx)
		world.add_child(fx)

		themes_on = Box.item_owned(game_id, "theme", "pack")
		_apply_stage_sky(stage, true)

		ship = Sprite2D.new()
		world.add_child(ship)
		_build_ship()
		ship.position = Vector2(vp.x * 0.5, vp.y * 0.80)
		ship.z_index = 10                   # the protector always on top

		_build_hud2()
		add_hud_button("SHOP", func(): _shop_open())
		add_hud_button("DEFEND", func(): _defend_open())
		pause_end_run = false

		# weapon ladders: own level per weapon (ship weapon + bought pool weapons)
		for wid in ["orb", "beam", "snake", "arc", "mg", "fire", "missile",
						"thunder", "bomb"]:
				wpower[wid] = 1
				wpts[wid] = 0
		skin = Box.skin_on(game_id)
		if not SHIPS.has(skin):
				skin = "azure"
		weapon = String(SHIPS[skin]["weapon"])
		Jukebox.music("res://assets/audio/music/inv_tour.wav")
		_show_ready_card()

func _build_ship() -> void:
		var old_pos := ship.position if ship != null else Vector2.ZERO
		for c in ship.get_children():
				c.queue_free()
		ship.texture = _tx(SHIPS[skin]["tex"])
		ship.scale = Vector2.ONE * 1.35
		ship.position = old_pos
		ship_glow = Sprite2D.new()
		ship_glow.texture = _tex["fx_trail"]
		ship_glow.scale = Vector2(4.5, 4.5)
		ship_glow.modulate = Color(SHIPS[skin]["tail"], 0.30)
		ship.add_child(ship_glow)

func _build_hud2() -> void:
		hud2 = CanvasLayer.new()
		add_child(hud2)
		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		var vp := get_viewport_rect().size
		row.offset_left = 18
		row.offset_top = -96 - banner_safe_px()
		row.offset_bottom = -40 - banner_safe_px()
		row.offset_right = 760
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud2.add_child(row)
		hearts_row = HBoxContainer.new()
		hearts_row.add_theme_constant_override("separation", 4)
		hearts_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(hearts_row)
		weapon_lbl = Arc.label("", 26, Color(0.85, 0.92, 1.0))
		weapon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(weapon_lbl)
		power_bar = Control.new()
		power_bar.custom_minimum_size = Vector2(130, 30)
		power_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		power_bar.draw.connect(_draw_power_bar)
		row.add_child(power_bar)
		# boss bar (top center, hidden until a boss lives)
		var brow := VBoxContainer.new()
		brow.set_anchors_preset(Control.PRESET_CENTER_TOP)
		brow.offset_left = -330
		brow.offset_right = 330
		brow.offset_top = 86
		brow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud2.add_child(brow)
		boss_lbl = Arc.label("", 26, Color(1.0, 0.5, 0.55))
		boss_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boss_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		brow.add_child(boss_lbl)
		boss_bar = Control.new()
		boss_bar.custom_minimum_size = Vector2(660, 18)
		boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boss_bar.draw.connect(_draw_boss_bar)
		brow.add_child(boss_bar)
		# wave title (center)
		wave_lbl = Arc.label("", 52, Color(1, 1, 1, 0.0))
		wave_lbl.set_anchors_preset(Control.PRESET_CENTER)
		wave_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wave_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud2.add_child(wave_lbl)
		_refresh_hud2()

func _refresh_hud2() -> void:
		for c in hearts_row.get_children():
				hearts_row.remove_child(c)
				c.queue_free()
		for i in mini(hearts, 6):
				var h := TextureRect.new()
				h.texture = _tex["heart"]
				h.custom_minimum_size = Vector2(34, 30)
				h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				h.mouse_filter = Control.MOUSE_FILTER_IGNORE
				hearts_row.add_child(h)
		weapon_lbl.text = String(weapon).to_upper() + "  L%d" % weapon_level()
		power_bar.queue_redraw()
		boss_bar.queue_redraw()

func _draw_power_bar() -> void:
		var lvl := weapon_level()
		for i in range(1, POWER_MAX + 1):
				var r := Rect2((i - 1) * 26, 4, 20, 20)
				var on := i <= lvl
				var col := Color(1, 0.92, 0.55, 0.95) if on else Color(1, 1, 1, 0.16)
				power_bar.draw_rect(r, col)
				power_bar.draw_rect(r, Color(0, 0, 0, 0.35), false, 2.0)

func _draw_boss_bar() -> void:
		if boss.is_empty() or not boss.has("hp_max") or int(boss["hp_max"]) <= 0:
				return
		var frac: float = clampf(float(boss["hp"]) / float(boss["hp_max"]), 0.0, 1.0)
		var r := Rect2(0, 0, 660, 18)
		boss_bar.draw_rect(r, Color(0, 0, 0, 0.45))
		boss_bar.draw_rect(Rect2(0, 0, 660.0 * frac, 18), Color(0.91, 0.34, 0.29))
		boss_bar.draw_rect(r, Color(1, 1, 1, 0.25), false, 2.0)

func _bottom_safe() -> float:
		return 84.0 + banner_bottom()

# ================================================================ ready card

func _show_ready_card() -> void:
		phase = "ready"
		_sheet_down()
		_kill_dialog()
		if _ready_card != null and is_instance_valid(_ready_card):
				_ready_card.queue_free()
		var cc := CenterContainer.new()
		cc.set_anchors_preset(Control.PRESET_FULL_RECT)
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel",
						Arc.panel_style(Color(0.03, 0.04, 0.10, 0.86), 24))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		var t := Arc.label("TAP ANYWHERE TO PLAY", 44, Color(1, 0.92, 0.55))
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var s := Arc.label("left half = move   ·   right half = fire / hold", 20,
						Color(0.75, 0.85, 1.0), false)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(t)
		v.add_child(s)
		var opts := Arc.button("OPTIONALS", Vector2(420, 64), 24, Color("4a5ab8"),
						func(): _optionals_open())
		v.add_child(opts)
		panel.add_child(v)
		cc.add_child(panel)
		_overlay_root_ref().add_child(cc)
		_ready_card = cc

func _start() -> void:
		if phase != "ready":
				return
		if _ready_card != null and is_instance_valid(_ready_card):
				var cc := _ready_card
				_ready_card = null
				var tw := cc.create_tween()
				tw.tween_property(cc, "modulate:a", 0.0, 0.22)
				tw.tween_callback(cc.queue_free)
		Jukebox.sfx("inv_click", -6.0)
		_begin_stage(0, true)

# ================================================================ input
## the dario law: multi-touch by INDEX - the first LEFT-half touch owns the
## move anchor (slide to steer, release to hold position), any RIGHT-half
## press is THE fire finger (hold = continuous). Overlapping never fights.

func _goga_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
				var t := event as InputEventScreenTouch
				if t.pressed:
						_press(t.position, t.index)
				elif t.index == fire_idx:
						fire_idx = -1
						firing = false
				elif t.index == move_idx:
						move_idx = -1

func _press(pos: Vector2, idx := 0) -> void:
		var vp := get_viewport_rect().size
		if phase == "ready":
				if not paused and not over and _sheet_pair.is_empty() \
								and _dialog_panel == null:
						_start()
				return
		if _dialog_panel != null and phase != "breach" and phase != "ending":
				_dialog_dismiss()
				return
		if phase == "breach" or phase == "ending":
				return
		if pos.x < vp.x * 0.5:
				if move_idx == -1:
						move_idx = idx
						move_anchor = pos
		else:
				firing = true
				fire_idx = idx

func _goga_tick(delta: float) -> void:
		_ship_tick(delta)
		_tail_tick(delta)
		_weapon_tick(delta)
		_loot_tick(delta)
		_trail_fade(delta)
		_fx_tick(delta)
		_defender_tick(delta)
		if phase == "fight" or phase == "wave_in":
				_form_tick(delta)
				_enemies_tick(delta)
				_wave_tick(delta)
		elif phase == "boss" or phase == "boss_in":
				_boss_tick(delta)
				_enemies_tick(delta)
		if invuln > 0.0:
				invuln -= delta
				ship.modulate.a = 0.45 + 0.55 * absf(sin(invuln * 14.0))
		else:
				ship.modulate.a = 1.0
		if shake > 0.0:
				shake = maxf(0.0, shake - delta * 34.0)
				world.position = Vector2(rng.randf_range(-shake, shake),
								rng.randf_range(-shake, shake))
		else:
				world.position = Vector2.ZERO
		fx.queue_redraw()
		if stage_transition > 0.0:
				stage_transition -= delta
				var k := clampf(stage_transition / 1.5, 0.0, 1.0)
				bg_b.modulate.a = 1.0 - k

# ================================================================ ship + tail

func _ship_tick(delta: float) -> void:
		var vp := get_viewport_rect().size
		if move_idx == -1:
				ship_v = ship_v.lerp(Vector2.ZERO, minf(1.0, delta * 6.0))
		else:
				var d := (move_anchor - ship.position)
				var want := d * 4.5
				want.x = clampf(want.x, -860.0, 860.0)
				want.y = clampf(want.y, -560.0, 560.0)
				ship_v = ship_v.lerp(want, minf(1.0, delta * 9.0))
		ship.position += ship_v * delta
		ship.position.x = clampf(ship.position.x, 70.0, vp.x - 70.0)
		ship.position.y = clampf(ship.position.y, vp.y * 0.42, vp.y - _bottom_safe() - 40.0)
		ship.rotation = clampf(ship_v.x * 0.0007, -0.35, 0.35)

func _tail_tick(delta: float) -> void:
		# THE DYNAMIC TAIL (owner: the space dash tail was "buggy and static"):
		# trail dots breathe with REAL velocity - faster flight = longer, hotter
		# trail - and every ship wears its own color.
		if phase == "ready" or over:
				return
		var speed := ship_v.length()
		var hot := clampf(speed / 620.0, 0.12, 1.0)
		if speed > 30.0:
				var tpos: Vector2 = ship.position + Vector2(0, 54) - ship_v.normalized() * 26.0
				trails.append({"pos": tpos, "vel": Vector2(rng.randf_range(-14, 14), 150.0 + speed * 0.16),
								"life": 0.38 + hot * 0.30, "max": 0.38 + hot * 0.30,
								"r": 10.0 + hot * 22.0, "col": Color(SHIPS[skin]["tail"], 0.85)})
		if defender != null and is_instance_valid(defender):
				var dtpos: Vector2 = defender.position + Vector2(0, 50)
				trails.append({"pos": dtpos, "vel": Vector2(rng.randf_range(-10, 10), 130.0),
								"life": 0.30, "max": 0.30, "r": 8.0,
								"col": Color(SHIPS[defender_id]["tail"], 0.70)})

func _trail_fade(delta: float) -> void:
		for t in trails:
				t["life"] -= delta
				t["pos"] += t["vel"] * delta
		trails = trails.filter(func(t): return t["life"] > 0.0)

# ================================================================ weapons

func weapon_level() -> int:
		return int(wpower.get(weapon, 1))

func weapon_level_of(wid: String) -> int:
		return int(wpower.get(wid, 1))

## power points feed the ladder; a level IS +1 damage on every per-hit weapon
func _apply_power(wid: String, n: int) -> void:
		var before := weapon_level_of(wid)
		wpts[wid] = int(wpts[wid]) + n
		while int(wpower[wid]) < POWER_MAX and int(wpts[wid]) >= int(LVL_PTS[int(wpower[wid])]):
				wpower[wid] = int(wpower[wid]) + 1
				Jukebox.sfx("inv_power", -4.0)
				_fx_ring(ship.position, 70.0 + 20.0 * float(wpower[wid]),
								Color(1, 0.92, 0.55), 0.4)
		if int(wpower[wid]) >= POWER_MAX and n > 0:
				# a maxed weapon eats points as score (documented lanes law)
				wpts[wid] = mini(int(wpts[wid]), int(LVL_PTS[POWER_MAX - 1]) + 3)
				_score_gain(25)
				_fx_popup(ship.position + Vector2(0, -70), "+25", Color(1, 0.92, 0.55), 30)
		if wid == weapon:
				_refresh_hud2()

func _death_power_drop() -> void:
		# owner: dying takes "3 power levels worth of weapon points" - the level
		# itself drops 3 rungs, the point progress resets (the dash law, invader taste)
		var lvl := weapon_level()
		wpower[weapon] = maxi(1, lvl - DEATH_POWER_RUNGS)
		wpts[weapon] = 0
		_refresh_hud2()

func _shot_ok() -> bool:
		var now := Time.get_ticks_msec()
		if now - last_shot_ms < int(maxf(SPAM_FLOOR_MS, 1000.0 / maxf(10.0,
										Engine.get_frames_per_second()))):
				return false
		last_shot_ms = now
		return true

func _weapon_tick(delta: float) -> void:
		if phase == "ready" or phase == "breach" or phase == "ending" or over or paused:
				return
		fire_cd = maxf(0.0, fire_cd - delta)
		if firing:
				match weapon:
						"orb":
								if fire_cd <= 0.0 and _shot_ok():
										_fire_orb()
						"beam":
								if fire_cd <= 0.0 and _shot_ok():
										_fire_beam()
						"mg":
								if fire_cd <= 0.0 and _shot_ok():
										_fire_mg()
						"snake":
								if fire_cd <= 0.0:
										_fire_snakes()
										fire_cd = 0.35        # the snakes live while held; recast politely
						"arc":
								if fire_cd <= 0.0:
										_fire_arc()
						"fire":
								if fire_cd <= 0.0 and _shot_ok():
										_fire_hornet()
						"missile":
								if fire_cd <= 0.0:
										_fire_missile()
						"thunder":
								if fire_cd <= 0.0:
										_cast_thunder()
						"bomb":
								if fire_cd <= 0.0 and _shot_ok():
										_drop_bomb()
		_bolts_tick(delta)
		_snakes_tick(delta)
		_arcs_tick(delta)
		_missiles_tick(delta)
		_bombs_tick(delta)
		_ebolts_tick(delta)
		_burns_tick(delta)

## ---- azure: blue small balls. more balls, small angle (owner) ----
func _fire_orb() -> void:
		var lvl := weapon_level()
		var n := lvl                                   # L1:1 .. L5:5 balls
		var dmg := lvl                                 # damage = the level
		var spread := deg_to_rad(7.0)
		for k in n:
				var ang := -PI / 2.0 + (float(k) - float(n - 1) / 2.0) * spread
				var b := Sprite2D.new()
				b.texture = _tex["w_azure"]
				b.material = _add_mat()
				b.position = ship.position + Vector2(0, -48)
				b.rotation = ang + PI / 2.0
				world.add_child(b)
				bolts.append({"node": b, "dmg": dmg, "vel": Vector2.from_angle(ang) * 980.0,
								"kind": "orb", "hit": {}})
		fire_cd = ORB_CD
		Jukebox.sfx("inv_shoot_azure", -8.0, 1.0 + 0.03 * float(lvl))

## ---- ember: red beams. more beams, wider range (owner) ----
func _fire_beam() -> void:
		var lvl := weapon_level()
		var n := mini(1 + (lvl - 1) / 2 + (1 if lvl >= 4 else 0), 6)
		var dmg := lvl
		var spread := deg_to_rad(4.0 + 2.0 * float(lvl))   # wider per level
		for k in n:
				var ang := -PI / 2.0 + (float(k) - float(n - 1) / 2.0) * spread
				var b := Sprite2D.new()
				b.texture = _tex["w_ember"]
				b.material = _add_mat()
				b.position = ship.position + Vector2(0, -52)
				b.rotation = ang + PI / 2.0
				world.add_child(b)
				bolts.append({"node": b, "dmg": dmg, "vel": Vector2.from_angle(ang) * 1150.0,
								"kind": "beam", "hit": {}})
		fire_cd = BEAM_CD
		Jukebox.sfx("inv_shoot_ember", -8.0)

## ---- phantom: machine gun, rapid, small (owner) ----
func _fire_mg() -> void:
		var lvl := weapon_level()
		var dmg := int(ceilf(float(lvl) / 2.0))        # 1,1,2,2,3 - small damage
		for sx in [-1.0, 1.0]:
				var b := Sprite2D.new()
				b.texture = _tex["w_phantom"]
				b.material = _add_mat()
				b.position = ship.position + Vector2(sx * 22.0, -42)
				world.add_child(b)
				bolts.append({"node": b, "dmg": dmg,
								"vel": Vector2(rng.randf_range(-40.0, 40.0), -1500.0),
								"kind": "mg", "hit": {}})
		fire_cd = MG_CD
		Jukebox.sfx("inv_shoot_phantom", -12.0, 1.0 + rng.randf_range(-0.05, 0.05))

## ---- verdant: green snakes - slow weaving, PIERCE, damage is hits/sec ----
func _fire_snakes() -> void:
		var lvl := weapon_level()
		var n := 1 + (lvl - 1) / 2                     # L1:1 L2-3:2 L4-5:3
		var tall := 1.0 + 0.25 * float(lvl)            # upgrade = taller (owner)
		for k in n:
				var b := Sprite2D.new()
				b.texture = _tex["w_verdant"]
				b.material = _add_mat()
				b.position = ship.position + Vector2((float(k) - float(n - 1) / 2.0) * 60.0, -40)
				world.add_child(b)
				snakes.append({"node": b, "lvl": lvl, "t": rng.randf() * TAU,
								"tall": tall, "tick": SNAKE_TICK, "hit": {},
								"last_y": b.position.y})   # the sweep owns the whole muzzle path
		snake_clock = 0.0

func _snakes_tick(delta: float) -> void:
		if snakes.is_empty():
				return
		if not firing or weapon != "snake":
				for s in snakes:
						s["node"].queue_free()
				snakes.clear()
				return
		var lvl := weapon_level()
		snake_clock += delta
		var emit := false
		if snake_clock >= 0.05:
				snake_clock = 0.0
				emit = true
		for s in snakes:
				s["t"] += delta * 5.0
				var n: Sprite2D = s["node"]
				n.position.x = ship.position.x + sin(s["t"]) * 90.0   # the snake weave
				n.position.y -= 300.0 * float(s["tall"]) * delta
				n.rotation = cos(s["t"]) * 0.5
				if emit and n.position.y > 0.0:
						trails.append({"pos": n.position, "vel": Vector2(0, 60), "life": 0.22,
										"max": 0.22, "r": 9.0, "col": Color(0.35, 0.95, 0.45, 0.6)})
				if n.position.y < -80.0:
						n.position.y = ship.position.y - 40.0
						n.position.x = ship.position.x
				# the DPS law: every SNAKE_TICK the snake re-damages everything its
				# swept path crossed since the last tick (it is slow ON PURPOSE - the
				# owner: "slow enough to deal high damage by time"); the FURTHER the
				# body along the path, the lower the damage, floor 1, never 0
				s["tick"] -= delta
				if s["tick"] <= 0.0:
					s["tick"] = SNAKE_TICK
					var dmg0: int = int(s["lvl"])
					var sn: Sprite2D = s["node"]
					var last_y: float = float(s.get("last_y", sn.position.y))
					var ny: float = sn.position.y
					var y_lo: float = minf(last_y, ny) - 48.0
					var y_hi: float = maxf(last_y, ny) + 48.0
					var victims: Array = []
					for e in enemies:
						if not is_instance_valid(e["node"]):
							continue
						var ep: Vector2 = e["node"].position
						if absf(ep.x - sn.position.x) < float(e["r"]) * 0.6 + 44.0 and ep.y >= y_lo and ep.y <= y_hi:
							victims.append(e)
					victims.sort_custom(func(a, b):
						return float(a["node"].position.y) > float(b["node"].position.y))
					for i in victims.size():
						_hit_enemy(victims[i], maxi(1, dmg0 - i))
					s["last_y"] = ny

## ---- veteran: sound arcs - open circles, bigger + stronger (owner) ----
func _fire_arc() -> void:
		var lvl := weapon_level()
		var a := Sprite2D.new()
		a.texture = _tex["w_veteran"]
		a.material = _add_mat()
		a.position = ship.position
		world.add_child(a)
		arcs.append({"node": a, "r": 30.0, "grow": 300.0 + 55.0 * float(lvl),
						"dmg": lvl, "hit": {}, "live": 1.5})
		fire_cd = ARC_CD
		Jukebox.sfx("inv_shoot_veteran", -7.0)

func _arcs_tick(delta: float) -> void:
		for a in arcs.duplicate():
				a["r"] += a["grow"] * delta
				a["live"] -= delta
				var n: Sprite2D = a["node"]
				n.position = ship.position
				n.scale = Vector2.ONE * (a["r"] / 22.0)
				n.modulate.a = clampf(a["live"], 0.0, 1.0)
				for e in enemies:
						if not is_instance_valid(e["node"]):
								continue
						var id: int = e["node"].get_instance_id()
						if a["hit"].has(id):
								continue
						if absf(e["node"].position.distance_to(n.position) - a["r"]) < float(e["r"]) * 0.5 + 20.0:
								a["hit"][id] = true
								_hit_enemy(e, a["dmg"])
				if boss.has("node"):
						var id2: int = boss["node"].get_instance_id()
						if not a["hit"].has(id2) and absf(boss["node"].position.distance_to(n.position) - a["r"]) < float(boss["r"]) * 0.4 + 20.0:
								a["hit"][id2] = true
								_hit_boss(a["dmg"], n.position)
				if a["live"] <= 0.0 or a["r"] > 1500.0:
						n.queue_free()
						arcs.erase(a)

## ---- hornet: fire that SPREADS (owner) ----
func _fire_hornet() -> void:
		var lvl := weapon_level()
		var b := Sprite2D.new()
		b.texture = _tex["w_hornet"]
		b.material = _add_mat()
		b.position = ship.position + Vector2(0, -46)
		world.add_child(b)
		bolts.append({"node": b, "dmg": lvl,
						"vel": Vector2(rng.randf_range(-60, 60), -760.0), "kind": "fire",
						"hit": {}})
		fire_cd = FIRE_CD
		Jukebox.sfx("inv_shoot_hornet", -9.0)

func _ignite(at: Vector2, lvl: int, chain_left: int) -> void:
		# the burn: spreads to nearby enemies, longer + hotter per level (owner)
		for e in enemies:
				if not is_instance_valid(e["node"]):
						continue
				if e["node"].position.distance_to(at) < 240.0:
						var id: int = e["node"].get_instance_id()
						var have := false
						for b in burns:
								if b["id"] == id:
										have = true
										break
						if not have:
								burns.append({"id": id, "dps": 1 + int(floorf(float(lvl) / 2.0)),
												"t": BURN_BASE + 0.5 * float(lvl)})
								_fx_popup(e["node"].position, "BURN", Color(1.0, 0.6, 0.25), 22)
		if chain_left > 0:
				var near := _nearest_enemy_pos(at, 260.0)
				if not near.is_empty():
						_ignite(near["node"].position, lvl, chain_left - 1)

func _burns_tick(delta: float) -> void:
		for b in burns.duplicate():
				b["t"] -= delta
				var found := false
				for e in enemies:
						if is_instance_valid(e["node"]) and e["node"].get_instance_id() == int(b["id"]):
								found = true
								b["acc"] = float(b.get("acc", 0.0)) + float(b["dps"]) * delta
								if b["acc"] >= 1.0:
										var step := int(floor(b["acc"]))
										b["acc"] = float(b["acc"]) - float(step)
										_hit_enemy(e, step)
								break
				if not found or b["t"] <= 0.0:
						burns.erase(b)

## ---- titan: ONE missile per 5s, same damage to EVERY enemy (owner) ----
func _fire_missile() -> void:
		var b := Sprite2D.new()
		b.texture = _tex["w_titan"]
		b.position = ship.position + Vector2(0, -50)
		world.add_child(b)
		missiles.append({"node": b, "t": 0.0})
		fire_cd = MISSILE_CD
		Jukebox.sfx("inv_shoot_titan", -5.0)

func _missiles_tick(delta: float) -> void:
		for m in missiles.duplicate():
				m["t"] += delta
				var n: Sprite2D = m["node"]
				n.position.y -= 520.0 * delta
				n.rotation = sin(m["t"] * 10.0) * 0.05
				if m["t"] >= 0.85 or n.position.y < 60.0:
						# the full-field strike: SAME damage to every enemy (owner law)
						var dmg := 1 + weapon_level_of("missile")
						for e in enemies:
								if is_instance_valid(e["node"]):
										_hit_enemy(e, dmg)
						if boss.has("node"):
								_hit_boss(dmg, n.position)
						_fx_explosion(n.position, 1.4, Color(1.0, 0.6, 0.35))
						Jukebox.sfx("inv_boom_small", -4.0)
						shake = maxf(shake, 8.0)
						n.queue_free()
						missiles.erase(m)

## ---- the REWORKED THUNDER: an electric BEAM UP, chaining around itself ----
func _cast_thunder() -> void:
		if fire_cd > 0.0:
				return
		var lvl := weapon_level_of("thunder")
		var beam := Sprite2D.new()
		beam.texture = _tex["fx_thunder"]
		beam.material = _add_mat()
		beam.position = Vector2(ship.position.x, ship.position.y - 260.0)
		beam.scale = Vector2(2.2 + 0.25 * float(lvl), 9.0)
		beam.modulate = Color(0.75, 0.95, 1.0)
		world.add_child(beam)
		var tw := beam.create_tween()
		tw.tween_property(beam, "modulate:a", 0.0, 0.5)
		tw.tween_callback(beam.queue_free)
		var half := 46.0 + 8.0 * float(lvl)            # the beam's own column
		var dmg0 := 2 + lvl                            # the base hit
		# everyone INSIDE the beam column takes the base hit
		for e in enemies:
				if is_instance_valid(e["node"]) and absf(e["node"].position.x - ship.position.x) <= half + float(e["r"]) * 0.4:
						_hit_enemy(e, dmg0)
		if boss.has("node") and absf(boss["node"].position.x - ship.position.x) <= half + float(boss["r"]) * 0.4:
				_hit_boss(dmg0, ship.position)
		# THE CHAIN: nearby ships join, each hop one damage point less, floor 1
		# (owner: "first enemies take 6, after them 5, then 4...")
		var chained: Array = []
		var wave_set: Array = []
		for e in enemies:
				if not is_instance_valid(e["node"]):
						continue
				var d: float = e["node"].position.distance_to(ship.position)
				if d <= half + 260.0 and absf(e["node"].position.x - ship.position.x) > half:
						wave_set.append([d, e])
		wave_set.sort_custom(func(a, b): return a[0] < b[0])
		var hop := 0
		for pair in wave_set:
				var e: Dictionary = pair[1]
				if hop >= 4 + int(ceilf(float(lvl) / 2.0)):
						break
				chained.append(e)
				_hit_enemy(e, maxi(1, dmg0 - 1 - hop))
				_fx_spark(e["node"].position, 5, Color(0.7, 0.9, 1.0), 200.0)
				hop += 1
		Jukebox.sfx("inv_thunder", -5.0)
		shake = maxf(shake, 6.0)
		fire_cd = THUNDER_CD

## ---- the REWORKED BOMB: no ammo limit, detonates ONLY on touch (owner) ----
func _drop_bomb() -> void:
		var b := Sprite2D.new()
		b.texture = _tex["bomb"]
		b.position = ship.position + Vector2(0, -50)
		world.add_child(b)
		bombs.append({"node": b, "vel": Vector2(rng.randf_range(-30, 30), -680.0)})
		fire_cd = BOMB_CD
		Jukebox.sfx("inv_bomb_drop", -8.0)

func _bombs_tick(delta: float) -> void:
		for b in bombs.duplicate():
				var n: Sprite2D = b["node"]
				b["vel"] = Vector2(b["vel"].x, b["vel"].y + 320.0 * delta)  # they arc
				n.position += b["vel"] * delta
				n.rotation += delta * 2.0
				# contact detonation ONLY - a bomb that touches nothing just leaves
				var boom_at := Vector2.ZERO
				for e in enemies:
						if is_instance_valid(e["node"]) and n.position.distance_to(e["node"].position) < float(e["r"]) + 24.0:
								boom_at = n.position
								break
				if boom_at == Vector2.ZERO and boss.has("node") \
								and n.position.distance_to(boss["node"].position) < float(boss["r"]) * 0.6 + 24.0:
						boom_at = n.position
				if boom_at != Vector2.ZERO:
						_bomb_blast(boom_at)
						n.queue_free()
						bombs.erase(b)
				elif n.position.y < -60.0 or n.position.x < -60.0 or n.position.x > get_viewport_rect().size.x + 60.0:
						n.queue_free()
						bombs.erase(b)

func _bomb_blast(at: Vector2) -> void:
		# radius law: each 60px ring deals ONE point less, floor 1 (owner)
		var lvl := weapon_level_of("bomb")
		var center := 3 + 2 * lvl
		var radius := 200.0 + 20.0 * float(lvl)
		for e in enemies:
				if not is_instance_valid(e["node"]):
						continue
				var d: float = e["node"].position.distance_to(at)
				if d <= radius + float(e["r"]):
						var rings := int(floorf(d / 60.0))
						_hit_enemy(e, maxi(1, center - rings))
		if boss.has("node"):
				var d2: float = boss["node"].position.distance_to(at)
				if d2 <= radius + float(boss["r"]) * 0.6:
						var rings2 := int(floorf(d2 / 60.0))
						_hit_boss(maxi(1, center - rings2), at)
		_fx_explosion(at, 2.2, Color(1.0, 0.75, 0.4))
		Jukebox.sfx("inv_bomb_boom", -3.0)
		shake = maxf(shake, 14.0)

## ---- player bolts: travel + hit ----
func _bolts_tick(delta: float) -> void:
		for b in bolts.duplicate():
				var n: Sprite2D = b["node"]
				n.position += b["vel"] * delta
				if n.position.y < -60.0 or n.position.y > get_viewport_rect().size.y + 60.0 \
								or n.position.x < -60.0 or n.position.x > get_viewport_rect().size.x + 60.0:
						n.queue_free()
						bolts.erase(b)
						continue
				if b["kind"] == "fire":
						n.scale = Vector2.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.15)
				var ate := false
				for e in enemies:
						if not is_instance_valid(e["node"]):
								continue
						var id: int = e["node"].get_instance_id()
						if b["hit"].has(id):
								continue
						if n.position.distance_to(e["node"].position) < float(e["r"]) * 0.7 + 14.0:
								b["hit"][id] = true
								_hit_enemy(e, b["dmg"])
								if b["kind"] == "fire":
										_ignite(e["node"].position, weapon_level_of("fire"), 2)
								# every bolt dies on its first victim (swarm weapons refire fast)
								ate = true
								break
				if not ate and boss.has("node") and not b["hit"].has("boss"):
						if n.position.distance_to(boss["node"].position) < float(boss["r"]) * 0.5 + 14.0:
								b["hit"]["boss"] = true
								_hit_boss(b["dmg"], n.position)
								if b["kind"] == "fire":
										_boss_burn(weapon_level_of("fire"))
								ate = true
				if ate:
						_fx_spark(n.position, 4, Color(1.0, 0.9, 0.7), 160.0)
						n.queue_free()
						bolts.erase(b)

func _boss_burn(lvl: int) -> void:
		if boss.is_empty() or not boss.has("node"):
				return
		burns.append({"id": -1, "boss": true, "dps": 1 + int(floorf(float(lvl) / 2.0)),
						"t": BURN_BASE + 0.5 * float(lvl), "acc": 0.0})

# ================================================================ stages/waves

func _apply_stage_sky(idx: int, instant := false) -> void:
		var key := "bg_neutral"
		if themes_on:
				key = String(STAGES[idx]["bg"]).trim_suffix(".png")
		bg_b.texture = _tex[key]
		bg_b.size = get_viewport_rect().size
		if instant:
				bg_a.texture = bg_b.texture
				bg_b.modulate.a = 0.0
		else:
				bg_a.texture = bg_b.texture
				bg_a.modulate.a = 1.0
				bg_b.modulate.a = 0.0
				var tmp := bg_a
				bg_a = bg_b
				bg_b = tmp
				bg_b.modulate.a = 1.0
				var tw := bg_b.create_tween()
				tw.tween_property(bg_b, "modulate:a", 0.0, 1.5)

func _line_pick(key: String) -> String:
		var arr: Array = LINES[key]
		var i := int(line_roll.get(key, 0)) % arr.size()
		line_roll[key] = i + 1
		return String(arr[i])

func _begin_stage(idx: int, first := false) -> void:
		stage = idx
		wave = 0
		if idx == 9:
				Jukebox.music("res://assets/audio/music/inv_finale.wav")
		if not first and themes_on:
				_apply_stage_sky(idx)
		phase = "gap"
		var st: Dictionary = STAGES[idx]
		var intro := _line_pick("intro") if (first and idx == 0) else String(st["line"])
		_dialog_show(intro, func():
				_next_wave())
		achievement_max("max_stage", idx + 1)

func _next_wave() -> void:
		if over:
				return
		wave += 1
		waves_since_coin += 1
		waves_since_power += 1
		if wave >= 10:
				_start_boss_wave()
				return
		phase = "gap"
		var st: Dictionary = STAGES[stage]
		_wave_title("WAVE %d" % wave, "%s - %s" % [st["name"], st["sub"]])
		var tw := create_tween()
		tw.tween_interval(1.1)
		tw.tween_callback(func():
				if over:
						return
				_spawn_wave())

func _wave_title(big: String, small := "") -> void:
		wave_lbl.text = big if small == "" else big + "\n" + small
		wave_lbl.modulate = Color(1, 1, 1, 0)
		wave_lbl.scale = Vector2.ONE
		var tw := wave_lbl.create_tween()
		tw.tween_property(wave_lbl, "modulate:a", 1.0, 0.25)
		tw.tween_interval(1.15)
		tw.tween_property(wave_lbl, "modulate:a", 0.0, 0.35)

## the formation slots (local box, centered)
func _pattern_slots(pattern: String, count: int) -> Array:
		var slots: Array = []
		var cols := mini(6, maxi(3, int(ceilf(count / 2.5))))
		match pattern:
				"line":
						for r in 2:
								for c in cols:
										slots.append(Vector2((float(c) - float(cols - 1) / 2.0) * 150.0,
														120.0 + r * 130.0))
				"vee":
						for i in count:
								var k := i - (count - 1) / 2.0
								slots.append(Vector2(k * 140.0, 120.0 + absf(k) * 90.0))
				"arc":
						for i in count:
								var a := PI * (0.15 + 0.7 * float(i) / maxf(1.0, float(count - 1)))
								slots.append(Vector2(-cos(a) * 430.0, 240.0 - sin(a) * 150.0))
				"diamond":
						var mid := count / 2
						for i in count:
								var k := absf(float(i - mid))
								slots.append(Vector2((float(i) - float(count - 1) / 2.0) * 140.0,
												130.0 + (mid - k) * 70.0))
				"columns":
						for c in 3:
								for r in int(ceilf(float(count) / 3.0)):
										slots.append(Vector2((float(c) - 1.0) * 210.0, 100.0 + r * 130.0))
				"ring":
						for i in count:
								var a := TAU * float(i) / float(count)
								slots.append(Vector2(cos(a) * 400.0, 240.0 + sin(a) * 150.0))
				_:
						# lattice
						for r in 3:
								for c in cols:
										slots.append(Vector2((float(c) - float(cols - 1) / 2.0) * 160.0,
														110.0 + r * 140.0 + (30.0 if c % 2 == 1 else 0.0)))
		while slots.size() > count:
				slots.pop_back()
		while slots.size() < count:
				slots.append(Vector2(rng.randf_range(-420, 420), rng.randf_range(110, 420)))
		return slots

func _spawn_wave() -> void:
		phase = "wave_in"
		var st: Dictionary = STAGES[stage]
		var pool: Array = st["pool"]
		var pattern: String = PATTERNS[(stage * 3 + wave) % PATTERNS.size()]
		var count := 8 + stage + wave
		form_origin = Vector2(get_viewport_rect().size.x * 0.5, 0.0)
		form_v = Vector2(rng.randf_range(40.0, 80.0) * (1.0 if rng.randf() > 0.5 else -1.0), 0.0)
		form_t = 0.0
		var slots := _pattern_slots(pattern, count)
		var hp_mul := 1.0 + STAGE_HP_GROWTH * float(stage)
		for i in count:
				var kind: String = pool[0] if i % 3 == 0 else pool[rng.randi_range(0, pool.size() - 1)]
				var d: Dictionary = ETYPES[kind]
				var n := Sprite2D.new()
				n.texture = _tx(d["tex"])
				n.scale = Vector2.ONE * float(d["scale"])
				var from := Vector2(rng.randf_range(60, get_viewport_rect().size.x - 60), -90.0 - rng.randf_range(0, 240))
				n.position = from
				world.add_child(n)
				enemies.append({"kind": kind, "node": n, "hp": int(ceilf(float(d["hp"]) * hp_mul)),
								"hp_base": int(d["hp"]), "r": float(d["r"]), "score": int(d["score"]),
								"slot": slots[i], "state": "in", "t": rng.randf() * TAU,
								"fire_cd": rng.randf_range(float(d["fire_cd"][0]) if d.has("fire_cd") else 9.0,
												float(d["fire_cd"][1]) if d.has("fire_cd") else 12.0),
								"dive_cd": rng.randf_range(DIVE_CD[0], DIVE_CD[1]) if d.has("dives") else -1.0,
								"data": d})
				var tw := n.create_tween()
				tw.tween_interval(0.05 * float(i))
		Jukebox.sfx("inv_wave", -6.0)

func _form_tick(delta: float) -> void:
		var vp := get_viewport_rect().size
		form_t += delta
		var target_y := 130.0 + 30.0 * sin(form_t * 0.5)
		form_origin.x += form_v.x * delta
		form_origin.y = lerpf(form_origin.y, target_y, minf(1.0, delta * 1.4))
		if form_origin.x < 330.0:
				form_v.x = absf(form_v.x)
		elif form_origin.x > vp.x - 330.0:
				form_v.x = -absf(form_v.x)

func _enemies_tick(delta: float) -> void:
		var vp := get_viewport_rect().size
		for e in enemies.duplicate():
				if not is_instance_valid(e["node"]):
						enemies.erase(e)
						continue
				var n: Sprite2D = e["node"]
				var d: Dictionary = e["data"]
				e["t"] += delta
				match String(e["state"]):
						"in":
								# steer into the slot - drift, not snap (the owner's "feel real")
								var want: Vector2 = form_origin + e["slot"]
								var to := want - n.position
								n.position += to.limit_length(560.0) * delta * 2.4
								n.rotation = clampf(to.x * 0.001, -0.4, 0.4)
								if to.length() < 26.0:
										e["state"] = "hover"
										if phase == "wave_in":
												phase = "fight"
						"hover":
								var weave: float = float(d.get("weave", 0.0))
								var off := Vector2(0.0, sin(e["t"] * 1.6) * 14.0)
								if weave > 0.0:
										off.x = sin(e["t"] * (1.1 + weave)) * (24.0 + 26.0 * weave)
								n.position = form_origin + e["slot"] + off
								n.rotation = sin(e["t"] * 2.0) * 0.06
								# the breach pressure: divers detach and dive the protector
								if float(e["dive_cd"]) > 0.0:
										e["dive_cd"] = float(e["dive_cd"]) - delta
										if e["dive_cd"] <= 0.0:
												e["state"] = "dive"
												e["dive_v"] = Vector2(0.0, 240.0)
												Jukebox.sfx("inv_bomb_drop", -14.0, 1.4)
						"dive":
								# steer at the ship, accelerate down - they must be intercepted
								var dv: Vector2 = e.get("dive_v", Vector2(0, 240))
								var steer := (ship.position - n.position)
								dv.x += clampf(steer.x, -320.0, 320.0) * delta * 1.6
								dv.y += 420.0 * delta
								e["dive_v"] = dv
								n.position += dv * delta
								n.rotation = sin(e["t"] * 9.0) * 0.14
						_:
								pass
				if String(e["state"]) == "in" or String(e["state"]) == "hover":
						# fired kinds shoot on their cadence (some aim, some fan, some ring)
						if d.has("fires") and not over:
								e["fire_cd"] = float(e["fire_cd"]) - delta
								if e["fire_cd"] <= 0.0:
										e["fire_cd"] = rng.randf_range(float(d["fire_cd"][0]), float(d["fire_cd"][1]))
										_enemy_fire(e)
						if d.has("blink") and rng.randf() < delta * 0.12:
								n.position.x = clampf(n.position.x + rng.randf_range(-150.0, 150.0),
												120.0, vp.x - 120.0)
								_fx_spark(n.position, 6, Color(0.7, 0.45, 1.0), 160.0)
						if d.has("trails") and rng.randf() < delta * 6.0:
								trails.append({"pos": n.position + Vector2(0, 30), "vel": Vector2(0, 90),
												"life": 0.4, "max": 0.4, "r": 12.0,
												"col": Color(1.0, 0.55, 0.2, 0.55)})
				# THE BREACH LAW: one past the bottom = the run is lost
				if String(e["state"]) == "dive" and n.position.y > vp.y - _bottom_safe():
						_breach()
						return
				# body contact with the protector (or the defender that eats it)
				if n.position.distance_to(ship.position) < float(e["r"]) * 0.7 + 40.0:
						if defender != null and is_instance_valid(defender) \
										and n.position.distance_to(defender.position) < float(e["r"]) * 0.7 + 40.0:
								_defender_down()
								_kill_enemy(e, false)
						else:
								_hit_enemy(e, 999)
								_wreck()

func _enemy_fire(e: Dictionary) -> void:
		var d: Dictionary = e["data"]
		var from: Vector2 = e["node"].position
		match String(d["fires"]):
				"aim":
						_ebolt(from, (ship.position - from).normalized() * 460.0)
				"fan":
						for k in 3:
								var ang := PI / 2.0 + (float(k) - 1.0) * 0.38
								_ebolt(from, Vector2.from_angle(ang) * 420.0)
				"shotgun":
						for k in 5:
								var ang2 := PI / 2.0 + (float(k) - 2.0) * 0.22
								_ebolt(from, Vector2.from_angle(ang2) * 520.0)
				"ring":
						for k in 8:
								var ang3 := TAU * float(k) / 8.0
								_ebolt(from, Vector2.from_angle(ang3) * 340.0)
		Jukebox.sfx("inv_hit", -18.0, 0.6)

func _ebolt(from: Vector2, vel: Vector2) -> void:
		var b := Sprite2D.new()
		b.texture = _tex["ebolt"]
		b.material = _add_mat()
		b.position = from
		b.rotation = vel.angle() + PI / 2.0
		world.add_child(b)
		ebolts.append({"node": b, "vel": vel})

func _ebolts_tick(delta: float) -> void:
		var vp := get_viewport_rect().size
		for b in ebolts.duplicate():
				var n: Sprite2D = b["node"]
				n.position += b["vel"] * delta
				if n.position.y < -80.0 or n.position.y > vp.y + 80.0 \
								or n.position.x < -80.0 or n.position.x > vp.x + 80.0:
						n.queue_free()
						ebolts.erase(b)
						continue
				if defender != null and is_instance_valid(defender) \
								and n.position.distance_to(defender.position) < 52.0:
						n.queue_free()
						ebolts.erase(b)
						_defender_down()
						continue
				if n.position.distance_to(ship.position) < 44.0:
						n.queue_free()
						ebolts.erase(b)
						_wreck()

func _hit_enemy(e: Dictionary, dmg: int) -> void:
		if not is_instance_valid(e["node"]):
				return
		e["hp"] = int(e["hp"]) - dmg
		_fx_popup(e["node"].position + Vector2(0, -20), "-%d" % dmg, Color(1, 0.95, 0.8), 24)
		if int(e["hp"]) <= 0:
				_kill_enemy(e, true)

func _kill_enemy(e: Dictionary, scored: bool) -> void:
		if not is_instance_valid(e["node"]):
				return
		var d: Dictionary = e["data"]
		_fx_explosion(e["node"].position, 0.9, Color(0.8, 0.85, 1.0))
		Jukebox.sfx("inv_boom_small", -10.0, rng.randf_range(0.9, 1.2))
		var at: Vector2 = e["node"].position
		e["node"].queue_free()
		enemies.erase(e)
		if scored:
				kills += 1
				achievement_count("kills", 1)
				_score_gain(int(e["score"]))
				_fx_popup(at + Vector2(0, -46), "+%d" % int(e["score"]), Color(1, 0.92, 0.55), 30)
				if bool(d.get("splits", false)):
						for k in 2:
								var dd: Dictionary = ETYPES["grunt"]
								var n := Sprite2D.new()
								n.texture = _tex["en_grunt"]
								n.position = at + Vector2(-40.0 + 80.0 * float(k), 0.0)
								world.add_child(n)
								enemies.append({"kind": "grunt", "node": n, "hp": int(ceilf(float(dd["hp"]) *
												(1.0 + STAGE_HP_GROWTH * float(stage)))), "hp_base": int(dd["hp"]),
												"r": float(dd["r"]), "score": int(dd["score"]),
												"slot": e["slot"] + Vector2(-40.0 + 80.0 * float(k), 40.0),
												"state": "hover", "t": rng.randf() * TAU, "fire_cd": 9.0,
												"dive_cd": -1.0, "data": dd})

func _nearest_enemy_pos(at: Vector2, max_d: float) -> Dictionary:
		var best: Dictionary = {}
		var best_d := max_d
		for e in enemies:
				if not is_instance_valid(e["node"]):
						continue
				var d: float = e["node"].position.distance_to(at)
				if d < best_d:
						best_d = d
						best = e
		return best

func _wave_tick(delta: float) -> void:
		if phase != "fight" and phase != "wave_in":
				return
		if not enemies.is_empty():
				return
		# the wave is cleared - anchor the drops, count the defender, roll on
		phase = "gap"
		_wave_end()

func _wave_end() -> void:
		Jukebox.sfx("inv_win_stage", -8.0)
		# the defender's ten waves tick down; at zero it flies home with the radio
		if defender != null and is_instance_valid(defender):
				defender_waves_left -= 1
				if defender_waves_left <= 0:
						_defender_depart()
		# loot: the wave-anchored rolls (owner laws, not kill-counted)
		var vp := get_viewport_rect().size
		if waves_since_coin >= coin_target:
				waves_since_coin = 0
				coin_target = rng.randi_range(COIN_WAVES_MIN, COIN_WAVES_MAX)
				_spawn_loot("coin", Vector2(rng.randf_range(160, vp.x - 160), -60.0))
		if waves_since_power >= power_target:
				waves_since_power = 0
				power_target = rng.randi_range(POWER_WAVES_MIN, POWER_WAVES_MAX)
				_spawn_loot("power", Vector2(rng.randf_range(160, vp.x - 160), -60.0))
		_roll_weapon_drop()
		var tw := create_tween()
		tw.tween_interval(0.9)
		tw.tween_callback(func():
				if over:
						return
				if wave >= 10:
						return
				_next_wave())

func _spawn_loot(kind: String, at: Vector2) -> void:
		var n := Sprite2D.new()
		match kind:
				"coin":
						n.texture = _tex["coin"]
				"power":
						n.texture = _tex["item_power"]
				"heart":
						n.texture = _tex["heart"]
				"wswitch":
						n.texture = _tex["item_w_" + skin]
				"thunder":
						n.texture = _tex["item_thunder"]
				"bomb":
						n.texture = _tex["item_bomb"]
		n.position = at
		world.add_child(n)
		loots.append({"kind": kind, "node": n, "vel": Vector2(rng.randf_range(-30, 30), 150.0)})

func _loot_tick(delta: float) -> void:
		var vp := get_viewport_rect().size
		for l in loots.duplicate():
				var n: Sprite2D = l["node"]
				n.position += l["vel"] * delta
				n.position.x = clampf(n.position.x, 40.0, vp.x - 40.0)
				n.rotation += delta * 1.6
				if n.position.y > vp.y - _bottom_safe() + 40.0:
						n.queue_free()
						loots.erase(l)
						continue
				# THE DEFENDER IS INVISIBLE TO ITEMS: only the protector collects
				if n.position.distance_to(ship.position) < 64.0:
						_collect(String(l["kind"]))
						n.queue_free()
						loots.erase(l)

func _collect(kind: String) -> void:
		match kind:
				"coin":
						add_run_coins(1)
						Jukebox.sfx("inv_coin", -6.0)
						_fx_popup(ship.position + Vector2(0, -60), "+1", Arc.COIN, 28)
				"power":
						_apply_power(weapon, 1)
				"heart":
						hearts = mini(hearts + 1, START_HEARTS)
						Jukebox.sfx("inv_heart", -4.0)
						_refresh_hud2()
				"wswitch":
						# the ship's own icon: +1 point (and home again if swapped away)
						if weapon != String(SHIPS[skin]["weapon"]):
								weapon = String(SHIPS[skin]["weapon"])
								Jukebox.sfx("inv_wswitch", -4.0)
								_fx_popup(ship.position + Vector2(0, -70), String(SHIPS[skin]["name"]).to_upper(), Color(0.85, 0.92, 1.0), 30)
						_apply_power(weapon, 1)
				"thunder", "bomb":
						if weapon != kind:
								weapon = kind
								Jukebox.sfx("inv_wswitch", -4.0)
								_fx_popup(ship.position + Vector2(0, -70), kind.to_upper(), Color(0.7, 0.9, 1.0), 30)
						_apply_power(kind, 1)
				_:
						pass
		_refresh_hud2()

## the weapon-drop rolls happen on top of the wave loot: the owner's law -
## a weapon icon only spawns if the CURRENT ship is the one the weapon needs,
## and thunder/bomb only if bought (the space dash pattern)
func _roll_weapon_drop() -> void:
		if rng.randf() < 0.05:
				_spawn_loot("wswitch", Vector2(rng.randf_range(160, get_viewport_rect().size.x - 160), -60.0))
		for wid in SHOP_WEAPONS:
				if Box.item_owned(game_id, "weapons", wid) and rng.randf() < 0.05:
						_spawn_loot(wid, Vector2(rng.randf_range(160, get_viewport_rect().size.x - 160), -60.0))

# ================================================================ bosses

func _start_boss_wave() -> void:
		phase = "gap"
		if stage < 9:
				_spawn_boss(String(STAGES[stage]["boss"]) if STAGES[stage].has("boss") else _stage_boss_id(stage), false)
		else:
				_gauntlet_next()

## the stage's boss id: 1:triton 2:monarch 3:duke 4:storm 5:reaver 6:mimic
## 7:ash 8:eater 9:herald (stage 10 is the gauntlet + the invader)
func _stage_boss_id(idx: int) -> String:
		return ["triton", "monarch", "duke", "storm", "reaver", "mimic", "ash",
						"eater", "herald"][idx]

func _spawn_boss(bid: String, final: bool, hp_mul := 1.0) -> void:
		var d: Dictionary = BOSSES[bid]
		var n := Sprite2D.new()
		n.texture = _tx(d["tex"])
		n.position = Vector2(get_viewport_rect().size.x * 0.5, -170.0)
		n.scale = Vector2.ONE * (1.0 if bid != "invader" else 1.15)
		world.add_child(n)
		boss = {"id": bid, "node": n, "def": d, "hp": int(ceilf(float(d["hp"]) * hp_mul)),
						"hp_max": int(ceilf(float(d["hp"]) * hp_mul)), "r": float(d["r"]),
						"t": 0.0, "move_t": 2.2, "move_i": 0, "final": final,
						"state": "enter", "angle": 0.0, "phase2": false}
		boss_lbl.text = String(d["name"])
		var line: String
		if gauntlet_i >= 0:
				line = _line_pick("gauntlet")
		else:
				line = _line_pick("boss_start") % [String(d["name"]), String(STAGES[stage]["name"])]
		_dialog_show(line, func():
				if over:
						return
				phase = "boss"
				var tw := n.create_tween()
				tw.tween_property(n, "position:y", 220.0, 1.2).set_trans(Tween.TRANS_CUBIC) \
								.set_ease(Tween.EASE_OUT)
				Jukebox.sfx("inv_boss_in", -3.0))
		_refresh_hud2()

func _boss_tick(delta: float) -> void:
		if boss.is_empty() or not is_instance_valid(boss["node"]):
				return
		var b := boss
		var n: Sprite2D = b["node"]
		var vp := get_viewport_rect().size
		b["t"] = float(b["t"]) + delta
		if String(b["state"]) == "enter":
				return
		if String(b["state"]) == "flee":
				n.position.y -= 900.0 * delta
				n.rotation += delta * 3.0
				if n.position.y < -300.0:
						_boss_gone()
				return
		if String(b["state"]) == "dead":
				return
		# the hover: slow sine drift (never static, the owner's feel-real law)
		n.position.x = vp.x * 0.5 + sin(float(b["t"]) * 0.55) * (vp.x * 0.24)
		n.position.y = 220.0 + sin(float(b["t"]) * 0.9) * 26.0
		n.rotation = sin(float(b["t"]) * 0.8) * 0.05
		# THE INVADER phase 2: rage under 40% (faster, meaner)
		if String(b["id"]) == "invader" and not bool(b["phase2"]) \
						and float(b["hp"]) <= float(b["hp_max"]) * INVADER_PHASE2:
				b["phase2"] = true
				Jukebox.sfx("inv_boss_in", -2.0, 0.8)
				_dialog_show("THE INVADER is done watching. Everything it has - NOW.", Callable())
				shake = 16.0
		# the move clock
		if float(b["move_t"]) > 0.0:
				b["move_t"] = float(b["move_t"]) - delta * (1.55 if bool(b["phase2"]) else 1.0)
				if float(b["move_t"]) <= 0.0:
						var moves: Array = b["def"]["moves"]
						var mv: String = moves[int(b["move_i"]) % moves.size()]
						b["move_i"] = int(b["move_i"]) + 1
						b["move_t"] = rng.randf_range(2.6, 3.8)
						_boss_move(mv)
		_boss_extras(delta)

## the named specials - every boss owns its voices (sfx + vfx)
func _boss_move(mv: String) -> void:
		var n: Sprite2D = boss["node"]
		var at: Vector2 = n.position
		var rage := 1.35 if bool(boss["phase2"]) else 1.0
		match mv:
				"volley":            # triton: three aimed spear lines
						for k in 3:
								_ebolt(at, (ship.position - at).normalized().rotated((float(k) - 1.0) * 0.2) * 560.0)
						Jukebox.sfx("inv_shoot_ember", -6.0, 0.7)
				"divecall":          # triton: summons divers
						for k in 3:
								_summon_diver(at + Vector2((float(k) - 1.0) * 120.0, 60.0))
						Jukebox.sfx("inv_bomb_drop", -6.0, 0.9)
				"rolleroll":         # monarch: sweeps sideways through the frame
						var tw := n.create_tween()
						tw.tween_property(n, "position:x", 260.0, 0.8).set_trans(Tween.TRANS_SINE)
						tw.tween_property(n, "position:x", get_viewport_rect().size.x - 260.0, 1.4) \
										.set_trans(Tween.TRANS_SINE)
						Jukebox.sfx("inv_boss_out", -12.0, 0.7)
				"ringtilt":          # monarch: a tilted ring of bolts
						for k in 10:
								var a := TAU * float(k) / 10.0 + 0.3
								_ebolt(at, Vector2.from_angle(a) * 380.0)
						Jukebox.sfx("inv_hit", -6.0, 0.8)
				"shardring":         # duke: orbiting shards (they BLOCK shots - the seam law)
						boss_shards.clear()
						for k in 4:
								boss_shards.append({"ang": TAU * float(k) / 4.0, "rad": float(boss["r"]) * 0.95,
												"w": 40.0})
						Jukebox.sfx("inv_wswitch", -6.0, 0.7)
				"icerain":           # duke: bolt curtains with a gap
						for k in 12:
								var x: float = 120.0 + float(k) * (get_viewport_rect().size.x - 240.0) / 11.0
								if absf(x - ship.position.x) < 170.0:
										continue                     # the fair gap above the protector
								_ebolt(Vector2(x, -40.0), Vector2(0, 460.0))
						Jukebox.sfx("inv_thunder", -10.0, 1.3)
				"redspot":           # storm: one slow fat orb that floats at the ship
						var o := Sprite2D.new()
						o.texture = _tex["w_hornet"]
						o.material = _add_mat()
						o.scale = Vector2.ONE * 3.2
						o.position = at
						world.add_child(o)
						ebolts.append({"node": o, "vel": (ship.position - at).normalized() * 240.0,
										"big": true})
						Jukebox.sfx("inv_bomb_drop", -4.0, 0.6)
				"spiral":            # storm: rotating bolt spiral
						for k in 14:
								var a2 := TAU * float(k) / 14.0 + float(boss["t"])
								_ebolt(at, Vector2.from_angle(a2) * 330.0)
						Jukebox.sfx("inv_hit", -6.0, 0.55)
				"dustdash":          # reaver: charges the ship's column
						var tw2 := n.create_tween()
						tw2.tween_property(n, "position", Vector2(ship.position.x, 430.0), 0.55) \
										.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
						tw2.tween_property(n, "position:y", 220.0, 0.9).set_trans(Tween.TRANS_SINE)
						Jukebox.sfx("inv_boss_in", -8.0, 1.3)
						shake = maxf(shake, 10.0)
				"sandspread":        # reaver: a 5-fan
						for k in 5:
								var a3 := PI / 2.0 + (float(k) - 2.0) * 0.24
								_ebolt(at, Vector2.from_angle(a3) * 480.0)
						Jukebox.sfx("inv_shoot_phantom", -6.0, 0.6)
				"mimicbeam":         # mimic: a beam that wears OUR blue before it hurts
						_boss_beam(at, Color(0.45, 0.75, 1.0), 0.9, 1.1)
				"decoys", "mirror":  # mimic/ash: lying copies
						_boss_decoys(2)
						Jukebox.sfx("inv_wswitch", -4.0, 0.6)
				"acidrain":          # ash: two curtains, two gaps
						for k in 16:
								var x2: float = 90.0 + float(k) * (get_viewport_rect().size.x - 180.0) / 15.0
								if absf(x2 - ship.position.x) < 210.0:
										continue
								_ebolt(Vector2(x2, -40.0), Vector2(0, 430.0))
						Jukebox.sfx("inv_thunder", -8.0, 1.15)
				"craters":           # eater: orbs that burst into rings
						for k in 3:
								var p := Vector2(rng.randf_range(200.0, get_viewport_rect().size.x - 200.0),
												rng.randf_range(120.0, 360.0))
								var o2 := Sprite2D.new()
								o2.texture = _tex["fx_burn"]
								o2.material = _add_mat()
								o2.scale = Vector2.ONE * 2.4
								o2.position = p
								world.add_child(o2)
								ebolts.append({"node": o2, "vel": Vector2.ZERO, "burst": 0.9})
						Jukebox.sfx("inv_bomb_drop", -8.0, 1.1)
				"flarebeam":         # eater: a sweeping vertical beam
						_boss_beam(at, Color(1.0, 0.8, 0.4), 1.4, 1.3)
				"prominence":        # herald: arcs from the bottom corners
						for side: Vector2 in [Vector2(60, get_viewport_rect().size.y - 120), Vector2(get_viewport_rect().size.x - 60, get_viewport_rect().size.y - 120)]:
								for k in 5:
										var a4: float = (ship.position - (side as Vector2)).angle() + (float(k) - 2.0) * 0.16
										_ebolt(side, Vector2.from_angle(a4) * 470.0)
						Jukebox.sfx("inv_shoot_hornet", -6.0, 0.8)
				"heatwave":          # herald: the pushback
						ship_v += Vector2(0, 460.0)
						_fx_ring(ship.position, 200.0, Color(1.0, 0.7, 0.3), 0.5)
						Jukebox.sfx("inv_boss_out", -8.0, 0.8)
				"voidflower":        # the invader: flower rings
						var petals := 8 if not bool(boss["phase2"]) else 12
						for k in petals:
								var a5 := TAU * float(k) / float(petals) + float(boss["t"]) * 1.7
								_ebolt(at, Vector2.from_angle(a5) * 360.0)
						Jukebox.sfx("inv_hit", -4.0, 0.5)
				"blink":             # the invader: teleport
						_fx_spark(at, 10, Color(0.7, 0.45, 1.0), 300.0)
						n.position = Vector2(rng.randf_range(300.0, get_viewport_rect().size.x - 300.0),
										rng.randf_range(160.0, 300.0))
						_fx_spark(n.position, 10, Color(0.7, 0.45, 1.0), 300.0)
						Jukebox.sfx("inv_wswitch", -2.0, 0.5)
				"elitecall":         # the invader: two void elites
						for k in 2:
								_summon_kind("void", at + Vector2((float(k) - 0.5) * 260.0, 80.0))
						Jukebox.sfx("inv_boss_in", -8.0, 1.2)
				_:
						pass

func _boss_extras(delta: float) -> void:
		# the shard ring orbits; the shards BLOCK player shots (the seam opening
		# faces away from the boss's own drift - a fair hole always exists)
		if not boss_shards.is_empty() and is_instance_valid(boss["node"]):
				for sh in boss_shards:
						sh["ang"] += delta * 1.9
		var dead: Array = []
		for d in boss_decoys:
				if not is_instance_valid(d["node"]):
						dead.append(d)
						continue
				d["t"] += delta
				d["node"].position = boss["node"].position + d["off"] + \
								Vector2(sin(d["t"] * 1.3) * 30.0, sin(d["t"] * 0.9) * 16.0)
				d["node"].modulate.a = 0.55
		for d in dead:
				if is_instance_valid(d["node"]):
						d["node"].queue_free()
				boss_decoys.erase(d)

func _boss_beam(at: Vector2, col: Color, warn: float, live: float) -> void:
		var rect := ColorRect.new()
		rect.color = Color(col.r, col.g, col.b, 0.0)
		rect.size = Vector2(120.0, get_viewport_rect().size.y)
		rect.position = Vector2(at.x - 60.0, 0.0)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(rect)
		var tw := rect.create_tween()
		tw.tween_property(rect, "color:a", 0.28, warn)      # the warning wash
		tw.tween_callback(func(): rect.color.a = 0.75)
		tw.tween_interval(live)
		tw.tween_property(rect, "color:a", 0.0, 0.2)
		tw.tween_callback(rect.queue_free)
		# while the beam burns, standing in it hurts - ticked by a timer chain
		var ticks := int(live / 0.25)
		for i in ticks:
				get_tree().create_timer(warn + 0.25 * float(i + 1)).timeout.connect(func():
						if over or boss.is_empty() or not is_instance_valid(rect):
								return
						if absf(ship.position.x - rect.position.x - 60.0) < 78.0:
								_wreck())
		Jukebox.sfx("inv_thunder", -6.0, 0.85)

func _boss_decoys(k: int) -> void:
		_boss_decoys_clear()
		for i in k:
				var d := Sprite2D.new()
				d.texture = boss["node"].texture
				d.scale = boss["node"].scale * 0.8
				d.modulate.a = 0.55
				d.position = boss["node"].position
				world.add_child(d)
				boss_decoys.append({"node": d, "off": Vector2((float(i) - float(k - 1) / 2.0) * 320.0, 40.0),
								"t": 0.0})

func _boss_decoys_clear() -> void:
		for d in boss_decoys:
				if is_instance_valid(d["node"]):
						d["node"].queue_free()
		boss_decoys.clear()

func _summon_diver(at: Vector2) -> void:
		_summon_kind("diver", at)

func _summon_kind(kind: String, at: Vector2) -> void:
		var d: Dictionary = ETYPES[kind]
		var n := Sprite2D.new()
		n.texture = _tx(d["tex"])
		n.position = at
		world.add_child(n)
		enemies.append({"kind": kind, "node": n, "hp": int(ceilf(float(d["hp"]) *
						(1.0 + STAGE_HP_GROWTH * float(stage)))), "hp_base": int(d["hp"]),
						"r": float(d["r"]), "score": int(d["score"]), "slot": at,
						"state": "dive", "dive_v": Vector2(rng.randf_range(-80, 80), 200.0),
						"t": rng.randf() * TAU, "fire_cd": 3.0, "dive_cd": -1.0, "data": d})

func _hit_boss(dmg: int, at: Vector2) -> void:
		if boss.is_empty() or not is_instance_valid(boss["node"]):
				return
		if String(boss["state"]) == "flee" or String(boss["state"]) == "dead":
				return
		# the shard ring blocks shots that cross it away from the seam
		if not boss_shards.is_empty() and _shard_blocked(at):
				_fx_spark(at, 3, Color(0.9, 0.95, 1.0), 140.0)
				return
		boss["hp"] = int(boss["hp"]) - dmg
		_fx_popup(boss["node"].position + Vector2(0, -float(boss["r"]) * 0.6), "-%d" % dmg,
						Color(1, 0.95, 0.8), 26)
		boss_bar.queue_redraw()
		var esc: bool = bool(boss["def"].get("escapes", false)) and not bool(boss["final"])
		if int(boss["hp"]) <= int(ceilf(float(boss["hp_max"]) * ESCAPE_HP)) and esc:
				_boss_escape()
				return
		if int(boss["hp"]) <= 0:
				_boss_killed()

func _shard_blocked(at: Vector2) -> bool:
		# a shot from below is blocked where a shard covers it; the gaps between
		# the four shards are the honest way in (the lanes seam law, adapted)
		var c: Vector2 = boss["node"].position
		if at.distance_to(c) < float(boss["r"]) * 0.75:
				return false                       # already inside the ring
		for sh in boss_shards:
				var a := atan2(ship.position.y - c.y, ship.position.x - c.x)
				var diff := absf(wrapf(a - float(sh["ang"]), -PI, PI))
				if diff > PI / 4.0:                # the seam = PI/2 between shards
						continue
				# the shard closest to the SHIP'S angle blocks that approach
				var sa := atan2(c.y - ship.position.y, c.x - ship.position.x)
				var sdiff := absf(wrapf(sa - float(sh["ang"]), -PI, PI))
				if sdiff < PI / 5.0:
						return true
		return false

func _boss_escape() -> void:
		String(boss["id"])
		Jukebox.sfx("inv_boss_out", -2.0)
		_fx_spark(boss["node"].position, 14, Color(0.7, 0.5, 1.0), 380.0)
		boss["state"] = "flee"
		var bid: String = boss["id"]
		_dialog_show(String(LINES["escape"][bid]), Callable())
		achievement_count("bosses_met", 1)

func _boss_gone() -> void:
		# an escape ends the wave: the world moves on, the wound stays open
		_boss_cleanup(false)
		if stage >= 9 and wave >= 10:
				_gauntlet_next()          # the keepers run INSIDE the gauntlet chain too
		else:
				_after_boss(true)

func _boss_killed() -> void:
		Jukebox.sfx("inv_boom_big", -2.0)
		_fx_explosion(boss["node"].position, 3.0, Color(1.0, 0.7, 0.4))
		shake = 20.0
		var bid: String = boss["id"]
		var bname: String = boss["def"]["name"]
		var bscore: int = boss["def"]["score"]
		var was_final: bool = bool(boss["final"])
		_boss_cleanup(true)
		_score_gain(bscore)
		_fx_popup(ship.position + Vector2(0, -90), "+%d" % bscore, Color(1, 0.92, 0.55), 40)
		if bid == "invader":
				_the_ending()
				return
		if String(stage_boss_or_gauntlet()) == "gauntlet":
				_gauntlet_boss_down(bid, was_final)
				return
		_dialog_show(_line_pick("boss_end") % [bname, String(STAGES[stage]["name"])], func():
				_after_boss(false))

## helper: are we inside the stage-10 finale?
func stage_boss_or_gauntlet() -> String:
		return "gauntlet" if (stage == 9 and wave >= 10) else "normal"

func _boss_cleanup(include_decoys: bool) -> void:
		if boss.has("node") and is_instance_valid(boss["node"]):
				boss["node"].queue_free()
		boss = {}
		boss_shards.clear()
		boss_lbl.text = ""
		if include_decoys:
				_boss_decoys_clear()

## what follows a boss: the next stage (normal) or the next gauntlet step
func _after_boss(escaped: bool) -> void:
		if stage >= 9:
				return                      # the gauntlet chain drives stage 10 itself
		_clear_field()
		var tw := create_tween()
		tw.tween_interval(0.8)
		tw.tween_callback(func():
				if over:
						return
				_begin_stage(stage + 1))

## ------------------------------------------------------------- the finale
## the owner's gauntlet: #3 alone -> a strong wave -> #3+#6 -> a stronger
## wave -> #3+#6+#9 finished for real -> THE INVADER descends.
func _gauntlet_next() -> void:
		gauntlet_i += 1
		match gauntlet_i:
				0:
						_spawn_boss("duke", false)
				1:
						_gauntlet_wave(1.2, "THE DUKE RAN - AND THE SKY ANSWERS HIM")
				2:
						_spawn_two("duke", "mimic")
				3:
						_gauntlet_wave(1.45, "TWO KEEPERS FLED - NOW A HARDER WAVE")
				4:
						_spawn_trio()
				5:
						_spawn_boss("invader", true)
				_:
						pass

func _spawn_two(a: String, b2: String) -> void:
		# the duo: ONE fight, TWO bodies, a shared HP pool - damage either body
		_spawn_boss(a, false)
		var hp_b := int(BOSSES[b2]["hp"])
		boss["hp"] = int(boss["hp"]) + hp_b
		boss["hp_max"] = int(boss["hp_max"]) + hp_b
		boss["sats"] = []
		_add_satellite(b2, -380.0)

func _add_satellite(bid: String, off_x: float) -> void:
		var d: Dictionary = BOSSES[bid]
		var n := Sprite2D.new()
		n.texture = _tx(d["tex"])
		n.position = Vector2(get_viewport_rect().size.x * 0.5 + off_x, -170.0)
		n.scale = Vector2.ONE * 0.9
		world.add_child(n)
		if not boss.has("sats"):
				boss["sats"] = []
		boss["sats"].append({"id": bid, "node": n, "def": d, "r": float(d["r"]), "off": Vector2(off_x, 90.0)})
		var tw := n.create_tween()
		tw.tween_property(n, "position:y", 300.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		Jukebox.sfx("inv_boss_in", -5.0, 1.05)

func _spawn_trio() -> void:
		# mark the trio FINAL: this time nobody runs - the owner's law
		_spawn_boss("duke", true)
		var total := int(BOSSES["mimic"]["hp"]) + int(BOSSES["herald"]["hp"])
		boss["hp"] = int(boss["hp"]) + total
		boss["hp_max"] = int(boss["hp_max"]) + total
		boss["sats"] = []
		_add_satellite("mimic", -380.0)
		_add_satellite("herald", 380.0)

## every hittable boss body (the main + the gauntlet satellites)
func _boss_bodies() -> Array:
		if boss.is_empty() or not is_instance_valid(boss.get("node", null)):
				return []
		var out: Array = [boss]
		for s in boss.get("sats", []):
				if is_instance_valid(s["node"]):
						out.append(s)
		return out

func _gauntlet_wave(hp_mul: float, title: String) -> void:
		phase = "gap"
		_wave_title(title, String(STAGES[9]["name"]) + " - " + String(STAGES[9]["sub"]))
		var tw := create_tween()
		tw.tween_interval(1.1)
		tw.tween_callback(func():
				if over:
						return
				phase = "wave_in"
				var vp := get_viewport_rect().size
				form_origin = Vector2(vp.x * 0.5, 60.0)
				form_v = Vector2(70.0, 0.0)
				form_t = 0.0
				var pool: Array = STAGES[9]["pool"]
				var count := 14 + 4 * gauntlet_i
				var slots := _pattern_slots("lattice", count)
				for i in count:
						var kind: String = pool[rng.randi_range(0, pool.size() - 1)]
						var d: Dictionary = ETYPES[kind]
						var n := Sprite2D.new()
						n.texture = _tx(d["tex"])
						n.position = Vector2(rng.randf_range(80, vp.x - 80), -90.0 - float(i) * 50.0)
						world.add_child(n)
						enemies.append({"kind": kind, "node": n,
										"hp": int(ceilf(float(d["hp"]) * hp_mul)), "hp_base": int(d["hp"]),
										"r": float(d["r"]), "score": int(d["score"]), "slot": slots[i],
										"state": "in", "t": rng.randf() * TAU, "fire_cd": rng.randf_range(2.0, 4.0),
										"dive_cd": rng.randf_range(4.0, 8.0) if d.has("dives") else -1.0,
										"data": d})
				Jukebox.sfx("inv_wave", -5.0))

func _gauntlet_boss_down(bid: String, was_final: bool) -> void:
		# a keeper burst past its 20% still hands the chain to the next step
		if not was_final:
				_gauntlet_next()
				return
		# the trio's shared pool hit zero - all keepers are dust, call the master
		if was_final:
				_dialog_show("The three keepers are dust. Something bigger stirs behind the doors...",
								func():
										if over:
												return
										_gauntlet_next())

# ================================================================ defender
## the DEFEND button: rent a crew ship for 10 waves. One at a time, once per
## ship per run, level-3 weapon, ONE hit kills it, invisible to items, the
## protector always draws on top.

func _defend_open() -> void:
	if phase == "ready":
		return
	if defender != null and is_instance_valid(defender):
		_toast_show("A defender is already flying.")
		return
	_sheet_open("THE SSDS - DEFEND")
	var sc: BoxScroll = _sheet_scroll()
	var box: VBoxContainer = _sheet_box()
	box.add_child(_sheet_label("rent a crew ship - 10 waves of cover"))
	for id in SHIP_ORDER:
		if id == skin:
			continue                       # the protector is already flying it
		box.add_child(_defend_row(id))
	box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
			func(): _sheet_close()))
	_sheet_finish(sc)

func _defend_row(id: String) -> Control:
	var pr: int = int(DEFENDERS[id]["price"])
	if bool(defender_called.get(id, false)):
		var l := Arc.fit_label("%s  - ALREADY FLOWN THIS RUN" % String(SHIPS[id]["name"]).to_upper(),
				22, Color(0.6, 0.65, 0.75), 560)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l
	var b := Arc.coin_button("%s  %d" % [String(SHIPS[id]["name"]).to_upper(), pr],
			Vector2(560, 64), 22, Color("4a5ab8"), func():
				if Box.coins() < pr:
					return
				if Box.spend(pr):
					_defender_call(id)
					_sheet_close()
				else:
					_toast_show("not enough GOGACoins"))
	if Box.coins() < pr:
		b.disabled = true
	return b

func _defender_call(id: String) -> void:
	defender_called[id] = true
	defender_id = id
	defender_waves_left = DEFEND_WAVES
	defender = Sprite2D.new()
	defender.texture = _tx(SHIPS[id]["tex"])
	defender.scale = Vector2.ONE * 1.1
	defender.z_index = 5                # below the protector (the overlap law)
	defender.position = ship.position + Vector2(-320.0, 40.0)
	world.add_child(defender)
	achievement_count("defenders_called", 1)
	Jukebox.sfx("inv_defend", -4.0)
	# THE RADIO: the caller asks, the called answers (3 variants per ship)
	var lines: Array = DEFEND_LINES[id]["call"]
	var pick: Array = lines[int(line_roll.get("def_" + id, 0)) % lines.size()]
	line_roll["def_" + id] = int(line_roll.get("def_" + id, 0)) + 1
	var caller_line: String = String(pick[0]) % String(SHIPS[skin]["name"]).to_upper()
	_dialog_show(caller_line, func():
		_dialog_show(String(pick[1]) % String(SHIPS[skin]["name"]).to_upper(), Callable()))

func _defender_depart() -> void:
	if defender == null or not is_instance_valid(defender):
		defender = null
		defender_id = ""
		return
	var id := defender_id
	var tw := defender.create_tween()
	tw.tween_property(defender, "position:x", -220.0, 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		if defender != null and is_instance_valid(defender):
			defender.queue_free()
		defender = null
		defender_id = "")
	var lines: Array = DEFEND_LINES[id]["end"]
	var pick: Array = lines[int(line_roll.get("dend_" + id, 0)) % lines.size()]
	line_roll["dend_" + id] = int(line_roll.get("dend_" + id, 0)) + 1
	_dialog_show(String(pick[0]) % String(SHIPS[skin]["name"]).to_upper(), func():
		_dialog_show(String(pick[1]) % String(SHIPS[id]["name"]).to_upper(), Callable()))

func _defender_down() -> void:
	if defender == null or not is_instance_valid(defender):
		return
	var id := defender_id
	_fx_explosion(defender.position, 1.2, Color(SHIPS[id]["tail"], 1.0))
	Jukebox.sfx("inv_boom_small", -4.0)
	defender.queue_free()
	defender = null
	defender_id = ""
	var lines: Array = DEFEND_LINES[id]["death"]
	var pick: String = String(lines[int(line_roll.get("ddth_" + id, 0)) % lines.size()][0])
	line_roll["ddth_" + id] = int(line_roll.get("ddth_" + id, 0)) + 1
	_dialog_show(pick, Callable())

func _defender_tick(delta: float) -> void:
	if defender == null or not is_instance_valid(defender):
		return
	# the wingman law: hover beside the protector, mirror its height softly
	var want := ship.position + Vector2(-240.0, 30.0 + sin(Time.get_ticks_msec() * 0.001) * 18.0)
	defender.position = defender.position.lerp(want, minf(1.0, delta * 3.0))
	defender.rotation = sin(Time.get_ticks_msec() * 0.002) * 0.05
	# it fights with its OWN weapon at level 3, targeting the nearest threat
	defender_fire_cd -= delta
	if defender_fire_cd <= 0.0 and not enemies.is_empty() \
			and phase != "ready" and not over:
		defender_fire_cd = 0.55
		var near := _nearest_enemy_pos(defender.position, 1400.0)
		if not near.is_empty() and is_instance_valid(near["node"]):
			var dir: Vector2 = (near["node"].position - defender.position).normalized()
			var b := Sprite2D.new()
			b.texture = _tx(WEAPON_SPRITE[String(SHIPS[defender_id]["weapon"])])
			b.material = _add_mat()
			b.position = defender.position + dir * 40.0
			b.rotation = dir.angle() + PI / 2.0
			world.add_child(b)
			bolts.append({"node": b, "dmg": 3, "vel": dir * 900.0, "kind": "orb", "hit": {}})
			Jukebox.sfx("inv_shoot_azure", -14.0, 0.8)

# ================================================================ dialogs
## THE ALPHA POPUP: a translucent dark panel + white text, center-top. It
## queues (one at a time), never blocks the war behind it, and taps dismiss.

func _dialog_show(msg: String, after := Callable()) -> void:
	_dialog_queue.append({"msg": msg, "after": after})
	if _dialog_panel == null:
		_dialog_next()

func _dialog_next() -> void:
	_kill_dialog()
	if _dialog_queue.is_empty():
		return
	var d: Dictionary = _dialog_queue.pop_front()
	var root := _overlay_root_ref()
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_CENTER_TOP)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	# THE ALPHA LAW: visible, never solid - the war stays readable behind it
	panel.add_theme_stylebox_override("panel",
			Arc.panel_style(Color(0.02, 0.03, 0.08, 0.55), 18))
	var v := VBoxContainer.new()
	var t := Arc.label(String(d["msg"]), 26, Color(1, 1, 1, 0.96))
	t.custom_minimum_size = Vector2(980, 0)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var hint := Arc.label("tap", 16, Color(1, 1, 1, 0.4), false)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	panel.add_child(v)
	panel.modulate.a = 0.0
	cc.add_child(panel)
	root.add_child(cc)
	_dialog_panel = cc
	cc.position.y = 150.0
	var tw := cc.create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)
	Jukebox.sfx("inv_dialog", -10.0)
	# auto-advance on a read-friendly clock; tap skips (handled in _press)
	var dur := clampf(2.2 + String(d["msg"]).length() * 0.032, 3.0, 6.5)
	var t2 := create_tween()
	t2.tween_interval(dur)
	t2.tween_callback(_dialog_dismiss)
	_dialog_after = d["after"]

func _dialog_dismiss() -> void:
	var cb := _dialog_after
	_kill_dialog()
	if cb.is_valid():
		cb.call()

func _kill_dialog() -> void:
	if _dialog_panel != null and is_instance_valid(_dialog_panel):
		_dialog_panel.queue_free()
	_dialog_panel = null
	_dialog_after = Callable()

# ================================================================ sheets
## THE PAIR LAW: every sheet owns its exact dim+center siblings.

func _sheet_open(title: String) -> void:
	if not _sheet_pair.is_empty():
		_sheet_down()
	if phase != "ready":
		paused = true
		get_tree().paused = true
	var root := _overlay_root_ref()
	var sheet := Arc.sheet(root, 0.0)
	sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
	var kids := root.get_children()
	_sheet_pair = [kids[kids.size() - 2], kids[kids.size() - 1]]
	var t := Arc.label(title, 34, Arc.INK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet.add_child(t)
	var wallet := Arc.coin_chip()
	wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sheet.add_child(wallet)
	var sc := BoxScroll.new()
	sc.game_safe = true
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vp := get_viewport_rect().size
	sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 300.0, 640.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(box)
	sheet.add_child(sc)
	_sheet_pair.append(sc)          # [dim, center, scroll] - the trio we free

func _sheet_scroll() -> BoxScroll:
	return _sheet_pair[2] as BoxScroll

func _sheet_box() -> VBoxContainer:
	return (_sheet_pair[2] as BoxScroll).get_child(0) as VBoxContainer

func _sheet_label(txt: String) -> Label:
	return Arc.fit_label(txt, 24, Arc.HOT, 560)

func _sheet_finish(_sc: BoxScroll) -> void:
	var sc := _sheet_pair[2] as BoxScroll
	for b in Arc._buttons_in(sc):
		if b.disabled:
			continue
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sc.register_tappable(b, Arc._tap_emitter(b))

func _sheet_down() -> void:
	for n in _sheet_pair:
		if n != null and is_instance_valid(n):
			n.queue_free()
	_sheet_pair = []

func _sheet_close() -> void:
	_sheet_down()
	get_tree().paused = false
	paused = false

# ================================================================ shop / optionals

func _shop_open() -> void:
	_sheet_open("SPACE INVADERS SHOP")
	var box := _sheet_box()
	box.add_child(_sheet_label("weapons - they join the loot drops"))
	for id in SHOP_WEAPONS:
		box.add_child(_weapon_row(id))
	box.add_child(_sheet_label("the tour"))
	box.add_child(_themes_row())
	box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
			func(): _sheet_close()))
	_sheet_finish(_sheet_pair[2] as BoxScroll)

func _weapon_row(id: String) -> Control:
	var w: Dictionary = SHOP_WEAPONS[id]
	if Box.item_owned(game_id, "weapons", id):
		var l := Arc.fit_label("%s  - IN THE LOOT" % w["name"], 22,
				Color("58c470"), 560)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l
	var b := Arc.coin_button("%s  %d" % [w["name"], int(w["price"])],
			Vector2(560, 64), 22, Color("8a4ab8"), func():
				if Box.buy_item(game_id, "weapons", id, int(w["price"])):
					Jukebox.sfx("buy")
				_sheet_down()
				_shop_open())
	if Box.coins() < int(w["price"]):
		b.disabled = true
	return b

func _themes_row() -> Control:
	if themes_on:
		var l := Arc.fit_label("Stage Themes Pack  - ON (every world wears its own sky)",
				22, Color("58c470"), 560)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l
	var b := Arc.coin_button("%s  %d" % [SHOP_THEMES["name"], int(SHOP_THEMES["price"])],
			Vector2(560, 64), 22, Color("2a7a68"), func():
				if Box.buy_item(game_id, "theme", "pack", int(SHOP_THEMES["price"])):
					themes_on = true
					_apply_stage_sky(stage, true)
					Jukebox.sfx("buy")
				_sheet_down()
				_shop_open())
	if Box.coins() < int(SHOP_THEMES["price"]):
		b.disabled = true
	return b

## the OPTIONALS menu: pick the ship you start with (no mid-run switching -
## the owner's 2-in-1 law; the weapon comes with the hull)
func _optionals_open() -> void:
	if phase != "ready":
		return
	_sheet_open("OPTIONALS - THE SSDS CREW")
	var box := _sheet_box()
	box.add_child(_sheet_label("pick your ship - the exclusive weapon rides with it"))
	for id in SHIP_ORDER:
		box.add_child(_ship_row(id))
	box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
			func(): _sheet_close()))
	_sheet_finish(_sheet_pair[2] as BoxScroll)

func _ship_row(id: String) -> Control:
	var s: Dictionary = SHIPS[id]
	var owned := Box.skin_owned(game_id, id) or int(s["price"]) == 0
	var on := Box.skin_on(game_id) == id or (int(s["price"]) == 0 and Box.skin_on(game_id) == "")
	if on:
		var l := Arc.fit_label("%s the %s  (ON)" % [String(s["name"]).to_upper(),
				"PROTECTOR" if id == "azure" else "SSDS"], 22, Color("58c470"), 560)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l
	if owned:
		return Arc.button("%s - FLY THIS SHIP" % String(s["name"]).to_upper(),
				Vector2(560, 60), 22, Color("4a5ab8"), func():
						Box.equip_skin(game_id, id)
						skin = id
						weapon = String(s["weapon"])
						_build_ship()
						Jukebox.sfx("confirm", -4.0)
						_sheet_down()
						_optionals_open())
	var b := Arc.coin_button("%s  %d  (ship + its weapon)" % [String(s["name"]).to_upper(),
			int(s["price"])], Vector2(560, 64), 20, Color("4a5ab8"), func():
				if Box.buy_skin(game_id, id, int(s["price"])):
					Jukebox.sfx("buy")
					Box.equip_skin(game_id, id)
					skin = id
					weapon = String(s["weapon"])
					_build_ship()
				_sheet_down()
				_optionals_open())
	if Box.coins() < int(s["price"]):
		b.disabled = true
	return b

# ================================================================ score/hit/over

func _score_gain(v: int) -> void:
	add_score(v)
	while score >= next_heart_at:
		next_heart_at += HEART_EVERY
		if hearts < START_HEARTS:
			hearts += 1
			Jukebox.sfx("inv_heart", -4.0)
			_fx_popup(ship.position + Vector2(0, -110), "+1 HEART",
					Color(1, 0.6, 0.7), 34)
			_refresh_hud2()
		else:
			# hearts are full: the milestone pays score instead (lanes law)
			add_score(25)
			_fx_popup(ship.position + Vector2(0, -110), "+25",
					Color(1, 0.6, 0.7), 26)

## a hit: -500 score (floored), -1 heart, -3 power rungs, 1.4s grace. The
## hit that takes the last heart ends the run (the owner's laws).
func _wreck() -> void:
	if invuln > 0.0 or over:
		return
	hearts -= 1
	invuln = INVULN_T
	Jukebox.sfx("inv_hurt", -2.0)
	Jukebox.sfx("inv_boom_small", -6.0)
	_fx_explosion(ship.position, 1.3, Color(1.0, 0.55, 0.35))
	shake = 16.0
	set_score(maxi(0, score + WRECK_SCORE))
	_death_power_drop()
	if hearts <= 0:
		_game_over()
	_refresh_hud2()

## THE BREACH: one enemy past the bottom = the dialogue + END -> death menu
func _breach() -> void:
	if over or phase == "breach":
		return
	phase = "breach"
	firing = false
	Jukebox.sfx("inv_breach", -2.0)
	shake = 14.0
	_clear_ebolts()
	var lines: Array = LINES["breach"]
	_breach_panel(String(lines[int(line_roll.get("breach", 0)) % lines.size()]))
	line_roll["breach"] = int(line_roll.get("breach", 0)) + 1

func _breach_panel(msg: String) -> void:
	var root := _overlay_root_ref()
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
			Arc.panel_style(Color(0.10, 0.02, 0.04, 0.82), 24))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	var t := Arc.label(msg, 30, Color(1, 0.9, 0.9))
	t.custom_minimum_size = Vector2(900, 0)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var end_b := Arc.button("END", Vector2(420, 76), 28, Arc.BAD, func():
			cc.queue_free()
			_game_over())
	v.add_child(end_b)
	panel.add_child(v)
	cc.add_child(panel)
	root.add_child(cc)

func _game_over() -> void:
	if over:
		return
	phase = "over"
	Jukebox.sfx("inv_over", -3.0)
	Jukebox.stop_music()
	achievement_max("max_score", score)
	var tw := create_tween()
	tw.tween_property(ship, "modulate", Color(1, 0.5, 0.4, 0.0), 0.7)
	tw.parallel().tween_property(ship, "rotation", 1.2, 0.7)
	tw.parallel().tween_property(ship, "position:y", ship.position.y + 160.0, 0.7)
	tw.tween_callback(func():
			check_achievements()
			finish_run(score))

## THE ENDING: the invader "dies" -> it RUNS, the protector chases it off
## screen, the end dialogue closes the loop (nobody dies - the war continues,
## one universe with Space Dash; replays never break the lore)
func _the_ending() -> void:
	phase = "ending"
	firing = false
	_clear_field()
	Jukebox.sfx("inv_escape", -1.0)
	_dialog_show("IT IS RUNNING. After me, Protector - do not let it reach the doors!", Callable())
	var tw := ship.create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(ship, "position", Vector2(
			get_viewport_rect().size.x + 320.0, -260.0), 1.5) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
			var root := _overlay_root_ref()
			var cc := CenterContainer.new()
			cc.set_anchors_preset(Control.PRESET_FULL_RECT)
			var panel := PanelContainer.new()
			panel.add_theme_stylebox_override("panel",
					Arc.panel_style(Color(0.02, 0.03, 0.08, 0.72), 26))
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", 12)
			var t := Arc.label("THE CHASE", 44, Color(1, 0.92, 0.55))
			t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(t)
			var body := Arc.label(String(LINES["ending"]), 24, Color(1, 1, 1, 0.96))
			body.custom_minimum_size = Vector2(940, 0)
			body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(body)
			var end_b := Arc.button("END", Vector2(420, 76), 28, Arc.GOOD, func():
					cc.queue_free()
					achievement_max("max_score", score)
					achievement_count("tour_done", 1)
					check_achievements()
					finish_run(score))
			v.add_child(end_b)
			panel.add_child(v)
			cc.add_child(panel)
			root.add_child(cc))

func _clear_field() -> void:
	for e in enemies:
		if is_instance_valid(e["node"]):
			e["node"].queue_free()
	enemies.clear()
	for b in ebolts:
		if is_instance_valid(b["node"]):
			b["node"].queue_free()
	ebolts.clear()
	_boss_decoys_clear()

func _clear_ebolts() -> void:
	for b in ebolts:
		if is_instance_valid(b["node"]):
			b["node"].queue_free()
	ebolts.clear()

# ================================================================ fx painter

var fx_rings: Array = []
var fx_sparks: Array = []
var fx_pops: Array = []
var fx_booms: Array = []

func _fx_ring(at: Vector2, r0: float, col: Color, life := 0.4) -> void:
	fx_rings.append({"pos": at, "r": r0 * 0.3, "r1": r0, "life": life, "max": life, "col": col})

func _fx_spark(at: Vector2, n: int, col: Color, spd: float) -> void:
	for i in n:
		var a := rng.randf() * TAU
		fx_sparks.append({"pos": at, "vel": Vector2.from_angle(a) * (spd * rng.randf_range(0.3, 1.0)),
				"life": 0.35, "max": 0.35, "col": col})

func _fx_popup(at: Vector2, txt: String, col: Color, fsize: int) -> void:
	fx_pops.append({"pos": at, "txt": txt, "col": col, "life": 0.8, "max": 0.8,
			"size": fsize})

func _fx_explosion(at: Vector2, s: float, col: Color) -> void:
	fx_booms.append({"pos": at, "life": 0.45, "max": 0.45, "s": s, "col": col})
	_fx_spark(at, int(6 * s), col, 240.0 * s)
	_fx_ring(at, 90.0 * s, col, 0.4)

func _draw_fx() -> void:
	var font := Arc.font_big()
	for r in fx_rings:
		var k: float = 1.0 - float(r["life"]) / float(r["max"])
		fx.draw_circle(r["pos"], lerpf(float(r["r"]), float(r["r1"]), k), Color(r["col"], 0.35 * (1.0 - k)))
	for s in fx_sparks:
		fx.draw_circle(s["pos"], 5.0, Color(s["col"], float(s["life"]) / float(s["max"])))
	for b in fx_booms:
		var k2: float = 1.0 - float(b["life"]) / float(b["max"])
		fx.draw_circle(b["pos"], 40.0 * float(b["s"]) * (0.4 + k2), Color(b["col"], 0.55 * (1.0 - k2)))
	for t in trails:
		fx.draw_circle(t["pos"], float(t["r"]) * (float(t["life"]) / float(t["max"])),
				Color(t["col"], 0.5 * float(t["life"]) / float(t["max"])))
	for p in fx_pops:
		var k3: float = float(p["life"]) / float(p["max"])
		fx.draw_string(font, p["pos"] + Vector2(0, (1.0 - k3) * -34.0), String(p["txt"]),
				HORIZONTAL_ALIGNMENT_CENTER, -1, int(p["size"]), Color(p["col"], k3))

func _fx_tick(delta: float) -> void:
	for r in fx_rings:
		r["life"] -= delta
	fx_rings = fx_rings.filter(func(r): return r["life"] > 0.0)
	for s in fx_sparks:
		s["life"] -= delta
		s["pos"] += s["vel"] * delta
	fx_sparks = fx_sparks.filter(func(s): return s["life"] > 0.0)
	for p in fx_pops:
		p["life"] -= delta
	fx_pops = fx_pops.filter(func(p): return p["life"] > 0.0)
	for b in fx_booms:
		b["life"] -= delta
	fx_booms = fx_booms.filter(func(b): return b["life"] > 0.0)


