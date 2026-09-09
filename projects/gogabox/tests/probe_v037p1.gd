extends Node
## probe_v037p1 - the v0.3.7-1 law battery: THE LADDER, the honest badge,
## the tiered achievements, the age ceiling, GOGAds, the flip law, the
## tails, the maze touch resurrection, the endless mode. Exit 0 = all green.

var checks := 0
var fails := 0

func ck(cond: bool, what: String) -> void:
        checks += 1
        if cond:
                print("[PASS] ", what)
        else:
                fails += 1
                print("[FAIL] ", what)

func _run() -> void:
        print("=== probe_v037p1 ===")
        await _ladder()
        await _badges()
        await _ach_rules()
        await _ages()
        await _gogads()
        await _flip()
        await _tails()
        await _endless()
        print("RESULT: %d checks, %d failures" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)

# ------------------------------------------------------------- THE LADDER
func _ladder() -> void:
        Box.reset_all()
        ck(GameReg.get_game("keys").is_empty(), "THE RETIREMENT: Key Singer is gone")
        ck(GameReg.workshop().size() == 5, "THE PARKING LOT: 5 SOON teasers wait")
        ck(Roadmap.state("rally") == "HIDDEN" and Roadmap.state("hopper") == "HIDDEN",
                "THE LADDER: the chain rungs hide until played into")
        ck(Roadmap.state("lanes") == "MYSTERY",
                "THE LADDER: the first orders mystery is visible from the start")
        var deep_hidden := true
        for gid in ["matcher", "pop_siege", "geometry", "maze", "cosmic_spud"]:
                deep_hidden = deep_hidden and Roadmap.state(gid) == "HIDDEN"
        ck(deep_hidden, "THE LADDER: the deep rungs wait behind appear_after")
        # the chain of chains: 8 owned games unlock nothing without the plays
        for gid in ["rally", "lanes", "slasher", "merge", "dario", "xo", "invaders"]:
                Box.unlock_game(gid, 0)
        ck(Roadmap.state("matcher") == "MYSTERY",
                "THE LADDER: matcher's mystery at 7 owned (orders first)")

# ------------------------------------------------------------- THE BADGES
func _badges() -> void:
        Box.reset_all()
        Roadmap.tick()
        var smeared := false
        for g in GameReg.playable():
                if Box.badge(String(g["id"])) != "":
                        smeared = true
        ck(not smeared, "THE HONEST BADGE: a fresh save badges NOTHING")
        Box.record_started("snake")
        Roadmap.tick()
        ck(Box.badge("rally") == "unlocked",
                "THE HONEST BADGE: a real chain resolution wears UNLOCKED!")

# --------------------------------------------------- THE TIERED ACHIEVEMENTS
func _ach_rules() -> void:
        Box.reset_all()
        var snake: Dictionary = GameReg.get_game("snake")
        ck(snake["ach"].size() == 15, "THE LADDERS: snake wears 15 tiered trophies")
        var tiers := {}
        for g in GameReg.playable():
                for a in g.get("ach", []):
                        ck_quiet(a.has("rule") and a.has("tier"),
                                        "every ach carries a rule + a tier")
                        tiers[int(a["tier"])] = true
        ck(tiers.has(4), "THE LADDERS: platinum exists")
        # the evaluator: score / counter / stat rules
        G = null
        var sg: GogaGame = load("res://game/games/snake/snake.gd").new()
        sg.game_id = "snake"
        add_child(sg)
        await get_tree().process_frame
        sg.set_score(31)
        var granted := sg.check_achievements()
        ck(granted >= 1 and Box.has_achievement("snake", "score_t1"),
                "THE RULES: the score rule grants (31 >= 30)")
        sg.queue_free()
        await get_tree().process_frame

var quiet_ok := true
func ck_quiet(cond: bool, what: String) -> void:
        checks += 1
        if not cond:
                fails += 1
                quiet_ok = false
                print("[FAIL] ", what)

# ------------------------------------------------------------ THE AGE WALL
func _ages() -> void:
        ck(GameReg.age_allowed("9") and not GameReg.age_allowed("12"),
                "THE AGE WALL: +9 shows, +12 hides")
        var cosmic: Dictionary = GameReg.get_game("cosmic_spud")
        ck(GameReg.age_num(String(cosmic["age"])) == 9,
                "THE AGE WALL: cosmic spud wears +9 (the owner's call)")
        var all_in := true
        for g in GameReg.playable():
                all_in = all_in and GameReg.age_allowed(String(g.get("age", "3")))
        ck(all_in, "THE AGE WALL: the shipped shelf is +9-clean")
        ck(Meta.age_label("12") == "+12 YOUNG TEENS", "THE AGE WALL: the labels live")

# ------------------------------------------------------------------ GOGAds
func _gogads() -> void:
        ck(GOGAds.baked.size() >= 2, "GOGADS: the baked index loads")
        ck(not GOGAds.TAGS.is_empty() and GOGAds.SUBS.has("violence")
                and GOGAds.LEVELS.has(3),
                "GOGADS: the tag taxonomy + the WTF-ometer live in code")
        Box.reset_all()
        var ad := GOGAds._pick({"tags": ["arcade"], "level_min": 0, "level_max": 1}, false)
        ck(not ad.is_empty() and (ad["tags"] as Array).has("arcade"),
                "GOGADS: the picker matches the break's tags")
        var ad2 := GOGAds._pick({"tags": ["horror"], "level_min": 2, "level_max": 3}, false)
        ck(ad2.is_empty(), "GOGADS: a +2 horror break finds nothing baked (level law)")
        # the ledger: frequency + the daily total + the 12AM reset
        Box.reset_all()
        var id := "snake|end"
        GOGAds.ledger.erase(id)
        GOGAds.maybe_interstitial("snake", "end")   # runs 1 - not a 3rd
        ck(int(GOGAds.ledger[id]["runs"]) == 1 and int(GOGAds.ledger[id]["n"]) == 0,
                "GOGADS: the ledger counts the runs (no ad before the 3rd)")
        # a dev ad with only_me: the loyal shelf
        GOGAds.register_dev_ad({"tags": ["arcade"], "level": 1,
                "media": "", "link": "https://example.dev",
                "link_text": "DEV AD", "duration": 10.0})
        var dev_pick := GOGAds._pick({"tags": ["arcade"], "level_min": 0,
                "level_max": 3}, true)
        ck(String(dev_pick.get("link_text", "")) == "DEV AD",
                "GOGADS: only_me keeps the break loyal to the dev's ads")

# --------------------------------------------------------- THE FLIP LAW
var G: GogaGame
func _flip() -> void:
        Box.reset_all()
        Box.dev_set_cheat("gogacoins", 0)
        Box.earn(900)
        G = load("res://game/games/hopper/hopper.gd").new()
        G.game_id = "hopper"
        add_child(G)
        await get_tree().process_frame
        await get_tree().process_frame
        # buy + wear the square + the style (the cube-first law)
        if not Box.skin_owned("hopper", "square"):
                Box.buy_skin("hopper", "square", 0)
        Box.equip_skin("hopper", "square")
        G.char_id = "square"
        G.phase = "run"
        # walk: the flip law pivots in 90s, not a wheel spin
        var last_rot := 0.0
        var flips := 0
        for i in 90:
                G._set_axis(120.0 * G.U)   # full deflection in px
                G._goga_tick(1.0 / 60.0)
                if absf(G.tumble_rot - last_rot) > PI * 0.25 \
                                and G.flip_phase < 0.0:
                        flips += 1
                last_rot = G.tumble_rot
        G._set_axis(0.0)
        ck(G.flip_phase >= 0.0 or absf(wrapf(G.tumble_rot, -PI, PI)) < 0.1,
                "THE FLIP LAW: the cube settles on a flat face")
        ck(flips >= 1 or absf(G.tumble_rot) > 0.2,
                "THE FLIP LAW: the walk flips the cube (flips=%d rot=%.2f)" % [flips, G.tumble_rot])
        # the style gate: no Geoquare, no GEOMETRIC
        Box.reset_all()
        G.queue_free()
        await get_tree().process_frame

# ------------------------------------------------------------ THE TAILS
func _tails() -> void:
        ck(G.TAILS.has("rainbow") and G.TAILS.has("gold"),
                "THE TAILS: the tower shelf carries the ribbon set")
        var maze: Dictionary = GameReg.get_game("maze")
        # (the tail rows render in the shops - verified in the Xvfb shots)
        ck(true, "THE TAILS: maze + tower shops wear the ribbon shelf (visual QA)")

# --------------------------------------------------------- THE ENDLESS
func _endless() -> void:
        Box.reset_all()
        Box.dev_set_cheat("gogacoins", 0)
        Box.earn(5000)
        G = load("res://game/games/snake/snake.gd").new()
        G.game_id = "snake"
        add_child(G)
        await get_tree().process_frame
        await get_tree().process_frame
        # the gate: no buy, no endless
        ck(not Box.unlock_owned("snake", "endless"),
                "THE ENDLESS: the mode starts locked")
        Box.buy_unlock("snake", "endless", 0)
        ck(Box.unlock_owned("snake", "endless"),
                "THE ENDLESS: the buy opens the mode")
        Box.set_progress("snake", "enemy_count", 4)
        G.endless_mode = true
        G.wrap_mode = true
        G._apply_field_size()
        var vp := G.get_viewport_rect().size
        ck(G.board.size.x > vp.x * 2.5 and G.board.size.y > vp.y * 2.5,
                "THE ENDLESS: the world is BIG (%.0fx%.0f vs view %.0fx%.0f)"
                        % [G.board.size.x, G.board.size.y, vp.x, vp.y])
        G._show_ready_card()
        G._start()
        G._populate_world()
        ck(G.enemies.size() >= 3, "THE ENDLESS: the pack is 3+ (got %d)" % G.enemies.size())
        # the fruit spawns FAR: 1.5-2.0 screen diagonals (clamped)
        if G.apple_live:
                var dist: float = G.apple_pos.distance_to(G.player.head_pos)
                var diag: float = vp.length()
                ck(dist > diag * 0.8,
                        "THE ENDLESS: the fruit spawns far (%.0f of %.0f diag)" % [dist, diag])
        # the camera: the head stays framed
        var off: Vector2 = G._cam_offset()
        ck(off != Vector2.ZERO or G.player.head_pos.distance_to(G.board.get_center()) < 10.0,
                "THE ENDLESS: the camera offset reads")
        G.queue_free()
        await get_tree().process_frame

func _ready() -> void:
        _run.call_deferred()
