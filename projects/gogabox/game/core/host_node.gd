extends Node2D
## host_node - the live wrapper around one running game. Handles:
## the universal GOGABox loading screen, orientation switch in/out,
## entry-fee accounting, per-game play time + coin stats, run reporting
## (best/last/plays + coins), rewarded DOUBLE, interstitial pacing, and the
## game-over sheet. Built fully in code (arsenal style).

var game_def := {}
var router: Node
var fee := 0
var free_play := false
var game: GogaGame

var W := 720.0
var H := 1280.0

var _session_open := true
var _accum := 0.0        # play seconds accumulated since last flush
var _over_sheet_pair: Array = []   # [center, dim] of the live game-over sheet

func _close_over_sheet() -> void:
        for n in _over_sheet_pair:
                if n != null and is_instance_valid(n):
                        n.queue_free()
        _over_sheet_pair.clear()

func configure(g: Dictionary, router_: Node, fee_: int, free_play_: bool) -> void:
        game_def = g
        router = router_
        fee = fee_
        free_play = free_play_

func _ready() -> void:
        var landscape := String(game_def.get("orientation", "portrait")) == "landscape"
        _apply_orientation(landscape)
        await get_tree().process_frame
        await get_tree().process_frame
        W = get_viewport_rect().size.x
        H = get_viewport_rect().size.y

        # full-screen OWN-WORLD background - MUST live on a CanvasLayer. A
        # Control under a Node2D anchors to a ZERO rect in Godot 4.7 (verified
        # headless): the v0.0.3/0.0.4 bg collapsed to 0x0, so the live box menu
        # stayed visible around the board ("game in a small window"). This
        # layer is opaque, covers the REAL viewport, and dies with the host.
        var bg_layer := CanvasLayer.new()
        bg_layer.layer = -1     # below the game world (0), above the hidden box
        add_child(bg_layer)
        var bg := ColorRect.new()
        bg.color = Color("241407")
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bg_layer.add_child(bg)

        # ---- universal GOGABox loading screen (loads the script + assets) ----
        var id := String(game_def["id"])
        # games may opt INTO a banner in their own view (registry "banner": true);
        # default is banner-free play
        if bool(game_def.get("banner", false)):
                Ads.banner_show()
        else:
                Ads.banner_hide()
        await Loader.load_game(self, game_def)

        if not _session_open:
                return
        game = (load(String(game_def["script"])) as GDScript).new()
        game.game_id = id
        game.request_finish.connect(_on_finish)
        game.request_quit.connect(_quit_to_menu)
        add_child(game)

func _process(delta: float) -> void:
        # play-time accounting for the global stats screen
        if game == null or not is_instance_valid(game) or game.over or game.paused:
                return
        _accum += delta
        if _accum >= 5.0:
                _flush_time()

func _flush_time() -> void:
        if _accum > 0.0:
                Box.add_time(String(game_def["id"]), _accum)
                _accum = 0.0

func _apply_orientation(landscape: bool) -> void:
        var root := get_window()
        if landscape:
                root.content_scale_size = Vector2i(1280, 720)
                DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
        else:
                root.content_scale_size = Vector2i(720, 1280)
                DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_PORTRAIT)

func _restore() -> void:
        # box level: free rotation again; the menu re-lays itself out on resize
        _flush_time()
        var root := get_window()
        root.content_scale_size = Vector2i(720, 1280)
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)

func _quit_to_menu() -> void:
        _session_open = false
        _close_over_sheet()
        _flush_time()
        _restore()
        GameHost.end_session()
        if router != null and is_instance_valid(router) and router.has_method("on_game_closed"):
                router.call("on_game_closed")

## Android back button while playing -> pause (never instant-quit).
func request_pause() -> void:
        if game != null and is_instance_valid(game) and not game.over and not game.paused:
                game._pause_open()

func _exit_tree() -> void:
        if _session_open:
                _flush_time()

func _on_finish(final_score: int, earned: int) -> void:
        var id := String(game_def["id"])
        _flush_time()
        var res := Box.record_run(id, final_score)
        var total := earned
        # score -> coins conversion (score itself already may contain coin pickups)
        var bonus := _score_to_coins(final_score)
        total += bonus
        Box.earn(total)
        Box.add_earned(id, total)
        game.achievement_max("max_score", final_score)
        game.check_achievements()

        await get_tree().create_timer(0.55).timeout

        # ---- game over sheet ----
        var sheet := Arc.sheet(game._overlay_root_ref(), 0.0)
        sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
        _over_sheet_pair = [sheet.get_parent(), sheet.get_parent().get_parent()]

        var title := Arc.label("RUN OVER" if not res["new_best"] else "NEW BEST!",
                        46, Arc.HOT if res["new_best"] else Arc.CARD)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(title)

        var stats := Arc.label("score %d   ·   best %d" % [final_score, int(res["best"])], 30, Arc.INK)
        stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(stats)

        var earn_row := Arc.chip("+%d GOGACoins" % total, "res://assets/ui/coin.png",
                        Color(0, 0, 0, 0.08), 30, Color("8a5a14"))
        var cc := HBoxContainer.new()
        cc.alignment = BoxContainer.ALIGNMENT_CENTER
        cc.add_child(earn_row)
        sheet.add_child(cc)

        if not res["new_best"]:
                var hype := Arc.label("best %d" % int(res["best"]), 24, Color("8a6a40"))
                hype.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                sheet.add_child(hype)

        if total > 0:
                # TIERED rewarded: watch-time decides the payout (15s+ = half,
                # 20s+ = 75%, full ad = full reward; config in ads_config.json)
                var hint := Arc.label(Ads.reward_hint(), 16, Color("8a6a40"), false)
                hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                sheet.add_child(hint)
                sheet.add_child(Arc.button("DOUBLE  (watch ad)", Vector2(480, 84), 26, Arc.GOOD, func():
                                Ads.show_rewarded(func(watched: bool, mult: float, _secs: float):
                                                if not watched:
                                                        return
                                                if mult <= 0.0:
                                                        Arc.toast(game._toast_ref(), "too short - watch %d+ seconds for the bonus" % Ads.tier_secs("half"))
                                                        return
                                                var extra := int(round(float(total) * mult))
                                                Box.earn(extra)
                                                Box.add_earned(id, extra)
                                                var msg := "FULL reward! +%d more GOGACoins!" % extra
                                                if mult < 1.0:
                                                        msg = "%d%% reward: +%d more GOGACoins" % [int(round(mult * 100.0)), extra]
                                                Arc.toast(game._toast_ref(), msg)
                                                Jukebox.sfx("coin")))
                                )

        # coin breakdown so earnings never feel random (pickups vs score bonus)
        var breakdown := Arc.label("pickups +%d   ·   score bonus +%d" % [earned, bonus],
                        20, Color("c9a25a"), false)
        breakdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(breakdown)

        var again_free := fee <= 0 or free_play
        var again_txt := "PLAY AGAIN FREE" if again_free else "PLAY AGAIN  -%d" % fee
        var again_btn := Arc.coin_button(again_txt, Vector2(520, 84), 28, Arc.ACCENT) \
                        if not again_free else Arc.button(again_txt, Vector2(520, 84), 28, Arc.ACCENT)
        again_btn.pressed.connect(func():
                        Jukebox.sfx("click", -4.0)
                        var can := free_play or fee == 0 or Box.coins() >= fee
                        if can:
                                if not free_play and fee > 0:
                                        Box.spend(fee)
                                        Box.add_spent(id, fee)
                                if not Box.consume_round_batteries(id):
                                        Arc.toast(game._toast_ref(), "Batteries empty - they refill over time")
                                        return
                                Ads.register_run()
                                _close_over_sheet()
                                _clear_game()
                                game = (load(String(game_def["script"])) as GDScript).new()
                                game.game_id = id
                                game.request_finish.connect(_on_finish)
                                game.request_quit.connect(_quit_to_menu)
                                add_child(game)
                        else:
                                Arc.toast(game._toast_ref(), "Not enough GOGACoins"))
        sheet.add_child(again_btn)
        if not again_free and Box.coins() < fee:
                var need := Arc.label("need %d more GOGACoins to replay" % (fee - Box.coins()),
                                18, Arc.BAD, false)
                need.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                sheet.add_child(need)

        sheet.add_child(Arc.button("BACK TO BOX", Vector2(480, 84), 28, Color(0.42, 0.30, 0.16), func():
                        # pacing owned by the Box: every 3rd run-back shows one.
                        # (v0.0.4 double-gated this through Ads' own counter too,
                        # which is why per-turn ads almost never fired.)
                        if Box.should_show_interstitial(3):
                                        Ads.show_interstitial(func(_shown: bool): _quit_to_menu())
                        else:
                                        _quit_to_menu()))

        if res["new_best"]:
                Arc.confetti(sheet.get_parent().get_parent().get_parent(), Vector2(W / 2.0, H / 3.0))
                Jukebox.jingle_win()
        else:
                Jukebox.jingle_lose()

func _clear_game() -> void:
        if game != null and is_instance_valid(game):
                game.queue_free()
        game = null

func _score_to_coins(s: int) -> int:
        # MODULAR per game (registry "coin_div"): score / divider, and BELOW the
        # divider a run earns nothing ("easy 500-score game -> /100" style).
        # Games with in-run collectables can still rely on pickups; the divider
        # is just the predictable fallback. No key -> default /100.
        var div := int(game_def.get("coin_div", 100))
        if div <= 0 or s < div:
                return 0
        return s / div
