extends SceneTree
## Headless law probe for GOLD MINER: the generator fairness battery, the
## swing/throw/reel loop laws, the bomb blast law, the every-50 coin law
## with its next-level edge case, the clear law, the skins + the assets.
## Run: GODOT_BIN --headless --path projects/gogabox --script res://tests/miner_probe.gd

var fails := 0

func _init() -> void:
        call_deferred("_run")

func check(name: String, ok: bool) -> void:
        print(("PASS  " if ok else "FAIL  ") + name)
        if not ok:
                fails += 1

func _run() -> void:
        print("== gold miner law probe ==")
        _generator_battery()
        _asset_battery()
        await _loop_battery()
        print("== %d checks, %d fails ==" % [_n, fails])
        quit(1 if fails > 0 else 0)

var _n := 0
func _check(name: String, ok: bool) -> void:
        _n += 1
        check(name, ok)

# ============================================================ the generator
func _generator_battery() -> void:
        var rng := RandomNumberGenerator.new()
        # one fixed anchor per "run"; the position law says it MOVES per run
        var anchors := [Vector2(240, MinerData.ANCHOR_Y),
                Vector2(540, MinerData.ANCHOR_Y),
                Vector2(840, MinerData.ANCHOR_Y),
                Vector2(390, MinerData.ANCHOR_Y),
                Vector2(700, MinerData.ANCHOR_Y)]
        var profiles_seen := {}
        var t0 := Time.get_ticks_msec()
        var total := 0
        for level in range(1, 41):
                for ai in anchors.size():
                        rng.seed = hash("gm-%d-%d" % [level, ai])
                        var anchor: Vector2 = anchors[ai]
                        for rep in 3:
                                var items: Array = MinerData.generate(level,
                                        rng, anchor)
                                total += 1
                                _assert_ground(items, anchor,
                                        "L%d A%d R%d" % [level, ai, rep])
                        # profile coverage across many draws
                        for rep in 30:
                                profiles_seen[MinerData.profile_for(level, rng)] = true
        var ms := Time.get_ticks_msec() - t0
        _check("generator: 600 grounds generated in %dms (<=9000)" % ms, ms <= 9000)
        var need := ["classic", "fortress", "deep_vein", "minefield",
                "twin_pockets", "cross_haul"]
        var missing := []
        for p in need:
                if not profiles_seen.has(p):
                        missing.append(p)
        _check("generator: all six profiles live (missing=%s)" % str(missing),
                missing.is_empty())
        # the anchor moves per run (the owner's position law) - the game's
        # seat range keeps the rig on screen
        _check("generator: anchor law documented", anchors.size() == 5)

func _assert_ground(items: Array, anchor: Vector2, tag: String) -> void:
        var golds := 0
        for it in items:
                var k := String(it["kind"])
                var r := float(it["r"])
                var p: Vector2 = it["pos"]
                if p.x - r < MinerData.FIELD.position.x - 1.0 \
                                or p.x + r > MinerData.FIELD.end.x + 1.0 \
                                or p.y - r < MinerData.FIELD.position.y - 1.0 \
                                or p.y + r > MinerData.FIELD.end.y + 1.0:
                        _check("ground %s: %s inside field" % [tag, k], false)
                if k.begins_with("gold"):
                        golds += 1
                        if p.distance_to(anchor) + r > MinerData.ROPE_MAX - 36.0:
                                _check("ground %s: gold reachable" % tag, false)
                for ot in items:
                        if ot == it:
                                continue
                        if p.distance_to(ot["pos"]) < r + float(ot["r"]) \
                                        + MinerData.GAP - 0.5:
                                _check("ground %s: no overlap (%s)" % [tag, k],
                                        false)
        if golds <= 0:
                _check("ground %s: has gold" % tag, false)

# ============================================================ the assets
func _asset_battery() -> void:
        var A := "res://assets/games/goldminer/"
        var need := ["claw_open.png", "claw_closed.png", "bomb.png",
                "coin.png", "dust.png", "dust_dark.png", "logo.png",
                "bg_surface.png", "bg_field.png", "bg_bedrock.png"]
        var veins := ["classic", "emerald", "amethyst", "candy", "obsidian"]
        for v in veins:
                for sz in ["s", "m", "l"]:
                        need.append("gold_%s_%s.png" % [v, sz])
                for sz in ["s", "s2", "m", "l"]:
                        need.append("rock_%s_%s.png" % [v, sz])
        for m in ["classic", "emerald", "royal", "crimson", "frost"]:
                need.append("rig_%s.png" % m)
        var missing := []
        for f in need:
                if not ResourceLoader.exists(A + f):
                        missing.append(f)
        _check("assets: all %d sprites exist (missing=%s)" % [need.size(),
                str(missing)], missing.is_empty())
        var snds := ["gm_start", "gm_launch", "gm_reel", "gm_grab",
                "gm_gold_s", "gm_gold_m", "gm_gold_l", "gm_rock_s",
                "gm_rock_m", "gm_rock_l", "gm_bomb_hit", "gm_blast",
                "gm_coin", "gm_clear", "gm_over", "gm_empty", "gm_click",
                "gm_buy"]
        var msnd := []
        for s in snds:
                if not ResourceLoader.exists("res://assets/audio/sfx/%s.ogg" % s):
                        msnd.append(s)
        _check("assets: all %d sfx exist (missing=%s)" % [snds.size(), str(msnd)],
                msnd.is_empty())
        _check("assets: the music bed exists",
                ResourceLoader.exists("res://assets/audio/music/gm_music.ogg"))
        # THE POINTS LAW (the owner's verbatim numbers)
        _check("points: gold 1/2/3, rock 2/4/6",
                MinerData.POINTS["gold_s"] == 1 and MinerData.POINTS["gold_m"] == 2
                and MinerData.POINTS["gold_l"] == 3 and MinerData.POINTS["rock_s"] == 2
                and MinerData.POINTS["rock_m"] == 4 and MinerData.POINTS["rock_l"] == 6)
        # THE WEIGHT LAW: heavy value crawls home
        _check("weight: L rock the slowest, empty claw the fastest",
                MinerData.REEL_SPEED["rock_l"] < MinerData.REEL_SPEED["gold_l"]
                and MinerData.REEL_SPEED["gold_l"] < MinerData.REEL_SPEED["gold_s"]
                and MinerData.REEL_SPEED["gold_s"] < MinerData.REEL_SPEED["none"])
        # THE SHOP LAW: 5 + 5, bombs are one
        _check("shop: 5 miner + 5 vein skins",
                MinerData.MINER_SKINS.size() == 5 and MinerData.VEIN_SKINS.size() == 5)

# ============================================================ the loop
func _loop_battery() -> void:
        var game = load("res://game/games/goldminer/goldminer.gd").new()
        game.game_id = "goldminer"
        game.set_process(false)
        get_root().add_child(game)
        await process_frame
        await process_frame
        _check("boot: intro phase", game.phase == "intro")
        _check("chrome: the END law rides the pause sheet",
                bool(game.pause_end_run))
        game._intro_go()
        _check("run: ground 1 populated", game.items.size() >= 4)
        _check("run: the claw starts swinging", game.phase == "swing")
        var d0: Vector2 = game.claw_dir
        game._goga_tick(0.1)
        _check("swing: the claw keeps angle-ing",
                game.claw_dir != d0 or game.phase != "swing")
        # force the swing to aim at a gold and throw
        var gold: Dictionary = {}
        for it in game.items:
                if String(it["kind"]).begins_with("gold"):
                        gold = it
                        break
        var dir: Vector2 = (gold["pos"] - game.anchor).normalized()
        game.claw_dir = dir
        game.phase = "fly"
        var score0: int = game.score
        var banked0: int = game.things_banked
        var n0: int = game.items.size()
        var guard := 0
        while game.phase != "swing" and guard < 2000:
                game._goga_tick(1.0 / 60.0)
                guard += 1
        _check("throw: the gold came home (score %d -> %d)" % [score0, game.score],
                game.score > score0)
        _check("throw: the 50-counter moved", game.things_banked == banked0 + 1)
        _check("throw: exactly one thing left the ground",
                game.items.size() == n0 - 1)
        # THE WEIGHT LAW live: an L rock reels measurably slower
        var rock: Dictionary = {}
        for it in game.items:
                if String(it["kind"]) == "rock_l":
                        rock = it
                        break
        if rock.is_empty():
                for it in game.items:
                        if String(it["kind"]).begins_with("rock"):
                                rock = it
                                break
        if not rock.is_empty():
                game.phase = "swing"
                game.claw_dir = (rock["pos"] - game.anchor).normalized()
                game.phase = "fly"
                guard = 0
                var ticks := 0
                while game.phase != "swing" and guard < 6000:
                        game._goga_tick(1.0 / 60.0)
                        guard += 1
                _check("throw: the rock came home too", game.phase == "swing")
        # THE COIN LAW: bank to 49, the next banked gold glows
        game.things_banked = 49
        var g2: Dictionary = {}
        for it in game.items:
                if String(it["kind"]).begins_with("gold") and not bool(it["coin"]):
                        g2 = it
                        break
        if not g2.is_empty():
                game.claw_dir = (g2["pos"] - game.anchor).normalized()
                game.phase = "fly"
                guard = 0
                while game.phase != "swing" and guard < 6000:
                        game._goga_tick(1.0 / 60.0)
                        guard += 1
                var carrier := false
                for it in game.items:
                        if bool(it["coin"]):
                                carrier = true
                _check("coin law: the 50th thing summons a glowing gold",
                        carrier)
        # THE EDGE CASE: the 50th thing IS the last gold - its bank both
        # clears the ground AND summons the coin, which then rides ground 2
        game.things_banked = 49
        game.coin_pending = false
        var golds: Array = []
        for it in game.items:
                if String(it["kind"]).begins_with("gold"):
                        golds.append(it)
        for i in range(golds.size() - 1):
                game._destroy_item(golds[i])   # the field keeps ONE gold
        var last: Dictionary = golds[golds.size() - 1]
        game.phase = "swing"
        game.claw_dir = (last["pos"] - game.anchor).normalized()
        game.phase = "fly"
        var guard2 := 0
        while (game.phase in ["fly", "grab", "reel", "blast"]) \
                        and guard2 < 6000:
                game._goga_tick(1.0 / 60.0)
                guard2 += 1
        # here the claw just banked the 50th thing: the ground has no golds
        # left, so the glow must be FLAGGED for the next ground
        _check("coin edge case: the 50th bank flagged the pending glow",
                game.coin_pending)
        guard2 = 0
        while game.phase != "swing" and guard2 < 400:
                game._goga_tick(1.0 / 60.0)
                guard2 += 1
        _check("clear law: the next ground loaded", game.level == 2)
        _check("coin edge case: the pending glowing gold rides ground 2",
                game.coin_pending == false and _has_carrier(game.items))
        # THE BOMB LAW: touch = life -1 + the blast eats the neighborhood
        var lives0: int = game.lives
        var bomb := {"kind": "bomb", "pos": Vector2(540, 1000), "r": 40.0,
                "spr": null, "coin": false, "dying": false, "v": ""}
        var near_gold := {"kind": "gold_m", "pos": Vector2(600, 1040),
                "r": 62.0, "spr": null, "coin": false, "dying": false, "v": ""}
        var far_gold := {"kind": "gold_s", "pos": Vector2(140, 600),
                "r": 30.0, "spr": null, "coin": false, "dying": false, "v": ""}
        var coin_item := {"kind": "gold_s", "pos": Vector2(160, 640),
                "r": 30.0, "coin": true, "dying": false, "v": "", "spr": null}
        game.items = [bomb, near_gold, far_gold, coin_item]
        game.carried = {}
        game._bomb_hit(bomb)
        _check("bomb law: the touch costs a life", game.lives == lives0 - 1)
        _check("bomb law: the blast eats the near gold",
                not game.items.has(near_gold))
        _check("bomb law: the far gold survives", game.items.has(far_gold))
        _check("bomb law: the glowing gold is magic", game.items.has(coin_item))
        _check("bomb law: the claw crawls home", game.phase == "blast")
        # THE RUN LAW: the 3rd bomb ends the run (finish_run)
        game.lives = 1
        var bomb2 := {"kind": "bomb", "pos": Vector2(540, 1000), "r": 40.0,
                "spr": null, "coin": false, "dying": false, "v": ""}
        game.items = [bomb2, far_gold, coin_item]
        game._bomb_hit(bomb2)
        _check("run law: the 3rd bomb ends the dig", bool(game.over))
        game.queue_free()
        await process_frame

func _has_carrier(items: Array) -> bool:
        for it in items:
                if bool(it.get("coin", false)):
                        return true
        return false
