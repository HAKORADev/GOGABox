extends Node2D
## host_node - the live wrapper around one running game. Handles:
## the universal GOGABox loading screen, orientation switch in/out,
## entry-fee accounting, per-game play time + coin stats, run reporting
## (best/last/plays + coins), rewarded DOUBLE, interstitial pacing, and the
## game-over sheet. Built fully in code (arsenal style).

var game_def := {}
var router: Node
var fee := 0
var partial := false   # v0.1.4: snake partial-pay - retry charges min(fee, wallet)
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

func configure(g: Dictionary, router_: Node, fee_: int, partial_: bool) -> void:
        game_def = g
        router = router_
        fee = fee_
        partial = partial_

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
        # v0.1.3: the SAME two designs as the box menu (ScaleRule is the one
        # source of truth) + stretch aspect EXPAND - the engine fills the
        # window edge-to-edge at ANY aspect, so a game just gets a little
        # more canvas in design px on taller/wider phones (games read the
        # real viewport W/H, they absorb it naturally).
        var root := get_window()
        root.content_scale_size = ScaleRule.DESIGN_LANDSCAPE if landscape \
                        else ScaleRule.DESIGN_PORTRAIT
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE
                        if landscape else DisplayServer.SCREEN_SENSOR_PORTRAIT)

func _restore() -> void:
        # v0.1.3: NO blind portrait pin. Decide from the REAL window px at
        # this exact moment (a landscape-held phone keeps the landscape
        # design - no flash), release the rotation lock, and let the menu
        # governor keep watching from here: whenever the system actually
        # rotates the window, the design follows within one frame.
        _flush_time()
        ScaleRule.apply(get_window())
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

        # ---- EARNINGS THEATRE (owner spec: kids should feel they run a real
        # business) - the total builds up LIVE: pickups count up first, then
        # the score bonus ticks up one division at a time while the remaining
        # score counts down, then both lines collapse into one sum line and
        # the chip pops to the full amount. A watched ad later shows its
        # multiplier and rolls the chip up to the doubled total.
        var div := int(game_def.get("coin_div", 100))
        var earn_row := Arc.chip("+0 GOGACoins", "res://assets/ui/coin.png",
                        Color(0, 0, 0, 0.08), 30, Color("8a5a14"))
        var cc := HBoxContainer.new()
        cc.alignment = BoxContainer.ALIGNMENT_CENTER
        cc.add_child(earn_row)
        sheet.add_child(cc)
        var earn_lbl: Label = earn_row.get_child(0).get_child(earn_row.get_child(0).get_child_count() - 1)
        var paid := [total]

        var pick_line := Arc.label("", 20, Color("c9a25a"), false)
        pick_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        pick_line.visible = earned > 0
        sheet.add_child(pick_line)
        var bonus_line := Arc.label("", 20, Color("c9a25a"), false)
        bonus_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        bonus_line.visible = bonus > 0
        sheet.add_child(bonus_line)
        var sum_line := Arc.label("", 21, Arc.INK, false)
        sum_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sum_line.visible = false
        sheet.add_child(sum_line)

        var show_total := func(v: int):
                earn_lbl.text = "+%d GOGACoins" % maxi(0, v)
        show_total.call(0)
        var tw := create_tween()
        if earned > 0:
                tw.tween_method(func(v: float):
                                pick_line.text = "picked up  +%d" % int(v)
                                show_total.call(int(v)),
                        0.0, float(earned), 0.55)
        if bonus > 0:
                if earned <= 0:
                        pick_line.visible = false
                tw.tween_method(func(v: float):
                                var k := int(v)
                                var rest := maxi(0, final_score - k * div)
                                bonus_line.text = "score bonus  +%d  ·  score %d ÷ %d" % [k, rest, div]
                                show_total.call(earned + k),
                        0.0, float(bonus), 0.55)
        tw.tween_callback(func():
                # collapse: two lines -> one sum line, chip pops to the total
                pick_line.visible = false
                bonus_line.visible = false
                sum_line.text = "pick up + score bonus = %d + %d" % [earned, bonus]
                sum_line.visible = true
                show_total.call(total)
                Jukebox.sfx("coin", -2.0)
                earn_row.pivot_offset = earn_row.size / 2.0
                var pulse := create_tween()
                pulse.tween_property(earn_row, "scale", Vector2(1.12, 1.12), 0.09)
                pulse.tween_property(earn_row, "scale", Vector2.ONE, 0.12))

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
                # v0.0.9 owner rule ("i told you more than two times"): the
                # honest math line above the ad button - pickups and the score
                # bonus ratio, in ONE modular format (Arc.bonus_ratio_text).
                var ratio := Arc.label("pickups = %d   -   score bonus = %s" %
                                [earned, Arc.bonus_ratio_text(final_score, div)],
                                18, Color("8a6a40"), false)
                ratio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                sheet.add_child(ratio)
                var dbl := [null]   # holder: the lambda cannot capture dbl_btn
                var reward_line := Arc.label("", 20, Arc.GOOD, false)
                reward_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                reward_line.visible = false
                # v0.0.9 REWORK (owner spec): a closed-early ad does NOT gray+
                # clickable (that read as broken) - the button counts down
                # "RETRY IN 10s" grayed AND dead, then comes back green as
                # "RETRY NOW". One tap = one clean new ad attempt. The second-
                # watch no-reward bug is fixed in Ads itself (show-start
                # fallback stamp + load-aware watchdog there).
                var dbl_btn := Arc.button("DOUBLE  (watch ad)", Vector2(480, 84), 26, Arc.GOOD, func():
                                var btn: Button = dbl[0]
                                if btn.disabled:
                                        return
                                btn.text = "LOADING AD..."
                                btn.disabled = true
                                Ads.show_rewarded(func(watched: bool, mult: float, _secs: float):
                                                var b2: Button = dbl[0]
                                                print("[rewarded] watched=%s mult=%.2f" % [watched, mult])
                                                if not watched or mult <= 0.0:
                                                        _reward_retry_countdown(b2)
                                                        var why := "ad closed early - no bonus"
                                                        if mult <= 0.0 and watched:
                                                                why = "too short - watch %d+ seconds for the bonus" % Ads.tier_secs("half")
                                                        Arc.toast(game._toast_ref(), why)
                                                        return
                                                var extra := int(round(float(total) * mult))
                                                Box.earn(extra)
                                                Box.add_earned(id, extra)
                                                var before := int(paid[0])
                                                paid[0] += extra
                                                # reward = x_multiply, then the total rolls up live
                                                reward_line.text = "reward  +%d%%  (=%d GOGACoins)" % [int(round(mult * 100.0)), extra]
                                                reward_line.visible = true
                                                var roll := create_tween()
                                                roll.tween_method(func(v: float):
                                                                earn_lbl.text = "+%d GOGACoins" % int(v),
                                                                float(before), float(paid[0]), 0.45)
                                                roll.tween_callback(func(): Jukebox.sfx("coin"))
                                                # the button TELLS the story: rewarded state,
                                                # grayed out, with the real amount on it
                                                b2.text = "REWARDED!  +%d" % extra
                                                b2.disabled = true
                                                var msg := "FULL reward! +%d more GOGACoins!" % extra
                                                if mult < 1.0:
                                                        msg = "%d%% reward: +%d more GOGACoins" % [int(round(mult * 100.0)), extra]
                                                Arc.toast(game._toast_ref(), msg))
                                                )
                dbl[0] = dbl_btn
                sheet.add_child(reward_line)
                sheet.add_child(dbl_btn)

        # ---- v0.1.4 RETRY ECONOMY (owner rule: "same for retry logic too"):
        # the charge is what the wallet can ACTUALLY pay - snake pours every
        # coin it has (min(fee, wallet)), an empty wallet replays free, other
        # games still pay the full fee. Daily caps + batteries gate the tap
        # BEFORE any coin moves, so a refused retry never eats the wallet.
        var pay_now := fee
        if partial:
                pay_now = Box.snake_entry_cost(fee)
        var again_free := pay_now <= 0
        var again_txt := "PLAY AGAIN FREE" if again_free else "PLAY AGAIN  -%d" % pay_now
        if not again_free and not partial and Box.coins() < fee:
                var need := Arc.label("need %d more GOGACoins to replay" % (fee - Box.coins()),
                                18, Arc.BAD, false)
                need.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                sheet.add_child(need)
        var again_btn := Arc.coin_button(again_txt, Vector2(520, 84), 28, Arc.ACCENT) \
                        if not again_free else Arc.button(again_txt, Vector2(520, 84), 28, Arc.ACCENT)
        again_btn.pressed.connect(func():
                        Jukebox.sfx("click", -4.0)
                        # re-derive the truth at tap time - the wallet moved while
                        # the sheet was open (rewarded DOUBLE may have paid out)
                        var pay := Box.snake_entry_cost(fee) if partial else fee
                        if not Box.daily_ok(id):
                                Arc.toast(game._toast_ref(), "daily limit reached - get back tomorrow to play")
                                return
                        if pay > 0 and Box.coins() < pay:
                                Arc.toast(game._toast_ref(), "Not enough GOGACoins")
                                return
                        var batt := Box.game_battery(id)
                        if not batt.is_empty() and (int(batt["count"]) < int(batt["per_round"]) \
                                        or Box.box_batteries() < int(batt["per_round"])):
                                Arc.toast(game._toast_ref(), "Batteries empty - they refill over time")
                                return
                        if pay > 0:
                                Box.spend(pay)
                                Box.add_spent(id, pay)
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
                        add_child(game))
        sheet.add_child(again_btn)

        sheet.add_child(Arc.button("BACK TO BOX", Vector2(480, 84), 28, Color(0.42, 0.30, 0.16), func():
                        # pacing owned by the Box: every 3rd run-back shows one.
                        # (v0.0.4 double-gated this through Ads' own counter too,
                        # which is why per-turn ads almost never fired.)
                        if Box.should_show_interstitial(3):
                                        Ads.show_interstitial(func(_shown: bool): _quit_to_menu())
                        else:
                                        _quit_to_menu()))

        # BUTTON SAFETY SYSTEM: measure, wrap overflow into a scroll, clamp to
        # the screen edges (this sheet ran off the bottom in landscape).
        # PLAY AGAIN + BACK TO BOX stay pinned at the bottom, always reachable.
        Arc.fit_sheet(sheet, 2)

        if res["new_best"]:
                Arc.confetti(sheet.get_parent().get_parent().get_parent(), Vector2(W / 2.0, H / 3.0))
                Jukebox.jingle_win()
        else:
                Jukebox.jingle_lose()

func _clear_game() -> void:
        if game != null and is_instance_valid(game):
                game.queue_free()
        game = null

## v0.0.9 owner spec: closed-early rewarded -> the button turns gray AND dead
## while it counts "RETRY IN 10s" -> 9 -> ... -> "RETRY NOW" (green, live).
## The countdown also pre-loads a fresh rewarded ad so the retry rarely
## starts from an empty slot. The timer dies with the sheet (child of it).
func _reward_retry_countdown(b: Button) -> void:
        if b == null or not is_instance_valid(b):
                return
        b.text = "RETRY IN 10s"
        b.disabled = true
        var left := [10]
        var t := Timer.new()
        t.wait_time = 1.0
        t.autostart = true
        b.add_child(t)
        t.timeout.connect(func():
                if not is_instance_valid(b):
                        t.queue_free()
                        return
                left[0] -= 1
                if left[0] <= 0:
                        t.queue_free()
                        b.text = "RETRY NOW"
                        b.disabled = false
                        Arc.repaint_button(b, Arc.GOOD)
                        Ads.refresh()   # fresh rewarded ready for the retry
                else:
                        b.text = "RETRY IN %ds" % left[0])

func _score_to_coins(s: int) -> int:
        # MODULAR per game (registry "coin_div"): score / divider, and BELOW the
        # divider a run earns nothing ("easy 500-score game -> /100" style).
        # Games with in-run collectables can still rely on pickups; the divider
        # is just the predictable fallback. No key -> default /100.
        var div := int(game_def.get("coin_div", 100))
        if div <= 0 or s < div:
                return 0
        return s / div
