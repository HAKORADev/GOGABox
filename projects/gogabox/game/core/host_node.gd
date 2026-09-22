extends Node2D
## host_node - the live wrapper around one running game. Handles:
## the universal GOGABox loading screen, orientation switch in/out,
## entry-fee accounting, per-game play time + coin stats, run reporting
## (best/last/plays + coins), and the game-over sheet. Built fully in
## code (arsenal style). THE 0-ADS LAW: no ad theatre anywhere.

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
var _orient_now := ""    # v0.2.0: the orientation the game is CURRENTLY in

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
        # v0.3.8-5 THE COMFORT LAW: a game buys the full 60 frames; the box
        # menu drops back to its 30-breath on the way out (main sets it at
        # boot, _restore hands it back).
        Engine.max_fps = 60
        # v0.1.8 "auto" orientation (owner: mode chosen WHEN THE GAME LOADS,
        # before the run): a game may support BOTH orientations - the REAL
        # window shape at load decides (hold vertical -> portrait design,
        # hold horizontal -> landscape design), then the sensor locks it for
        # the session. "portrait"/"landscape" pins stay exactly as before.
        var orient := String(game_def.get("orientation", "portrait"))
        var landscape: bool
        if orient == "auto":
                var ws := DisplayServer.window_get_size()
                landscape = ws.x > 0 and ws.y > 0 and ws.x > ws.y
        else:
                landscape = orient == "landscape"
        _orient_now = "horizontal" if landscape else "vertical"
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
        await Loader.load_game(self, game_def)

        if not _session_open:
                return
        game = (load(String(game_def["script"])) as GDScript).new()
        game.game_id = id
        game.request_finish.connect(_on_finish)
        game.request_quit.connect(_quit_to_menu)
        # v0.2.0 THE UNIVERSAL POSITION RELOAD: the game asks, the host reloads
        game.request_orientation_reload.connect(_on_orientation_reload)
        add_child(game)
        # v0.1.9 OWNER FIX: the play counts at START (quit-mid-turn stays
        # "played"). record_run at finish keeps score/best only.
        Box.record_started(id)
        # v0.2.3 CAPACITY HOLD: THIS game's pool stops recharging while its
        # own session is open (menu / other games / closed app = charging)
        Box.set_active_game(id)

## v0.2.0 - a game picked a DIFFERENT play position: unload it and reload
## it in that position. The session (fee, play count, host chrome) is kept
## - the game reboots, nothing else. Same position = nothing happens.
## v0.2.1a OWNER FIX: every decision here is verified against the REAL
## window (the game now judges picks against the live window too), and a
## REFUSED rotation settles the ask in the current shape instead of
## reloading into a lie - no path can leave the ask hanging.
func _on_orientation_reload(o: String) -> void:
        if o != "vertical" and o != "horizontal":
                return
        var vps := get_viewport_rect().size
        if o == _orient_now:
                if (vps.x > vps.y) == (o == "horizontal"):
                        return   # the window truly sits there: do nothing
                _orient_now = ""   # bookkeeping desynced - force the switch
        _apply_orientation(o == "horizontal")
        # wait until the window actually reflects the new design (a rotation on
        # device is async; desktop/headless flips immediately) - capped wait
        var rotated := false
        for i in 30:
                await get_tree().process_frame
                var vps2 := get_viewport_rect().size
                if (vps2.x > vps2.y) == (o == "horizontal"):
                        rotated = true
                        break
        if not _session_open:
                return
        if not rotated:
                # the window REFUSED the position: resync from the real
                # window and let the live game settle its ask in THIS shape
                var vps3 := get_viewport_rect().size
                _orient_now = "horizontal" if vps3.x > vps3.y else "vertical"
                if game != null and is_instance_valid(game):
                        game.orientation_settled()
                return
        _orient_now = o
        _close_over_sheet()
        _clear_game()
        game = (load(String(game_def["script"])) as GDScript).new()
        game.game_id = String(game_def["id"])
        game.start_orientation = o   # the ask screens skip themselves
        game.request_finish.connect(_on_finish)
        game.request_quit.connect(_quit_to_menu)
        game.request_orientation_reload.connect(_on_orientation_reload)
        add_child(game)
        # play count stays: one session = one play (the fee was never re-taken)

func _process(delta: float) -> void:
        # v041-1 r5 THE FLICKER ENGINE IS GONE: the r1 WINDOW-LAW REASSERT
        # re-decided mode/design/shape EVERY FRAME while a game ran - the
        # only per-frame window writer in the whole box. In a drifted state
        # (the maximize trap's screen-covering "windowed" window, a launch
        # re_window race) its writes chased their own tail: window churn,
        # style rebuilds, canvas re-attaches - the owner's "when i open a
        # game ... it keeps flickering forever". THE CORRELATION (his own
        # report): "flickers stop when i pause the game or any in-game menu
        # appears" - pause sets get_tree().paused, the host stops
        # processing, the writer stops. THE LAW NOW: the window is written
        # ONLY on real state changes (launch/orientation re_window, the F11
        # dance in ScaleRule.set_fullscreen - main.gd's handler works
        # in-game too), exactly like every build through v041.
        # v041-1 r6 THE DESIGN GOVERNOR (the owner: "in full screen if i
        # opened a game that is another position than the current one, the
        # app will somehow be stuck in mis-scale because the window itself
        # got resized but the app internally not" + "the debugging work here
        # must go harder"): r5 deleted the per-frame WRITER but left a
        # per-frame READER hole - during a game NOTHING re-asserted the
        # design law, so any missed WM echo / WM fight / foreign window
        # state stranded the canvas mapping forever (STUCK, the exact word).
        # The menu always had its governor (main._process -> menu
        # .apply_resolution); the games have one now: read-compare the real
        # truth, write ONLY on drift (apply_pc/content_scale_size are
        # no-op compares at steady state - zero churn, zero flicker fuel).
        # The poison-shape watchdog rides the same beat (read-only, heals
        # the screen-covering "windowed" window once if it ever appears).
        ScaleRule.heal_poison_shape()
        _assert_design_law()
        # play-time accounting for the global stats screen
        if game == null or not is_instance_valid(game) or game.over or game.paused:
                return
        _accum += delta
        if _accum >= 5.0:
                _flush_time()

## v041-1 r6 THE DESIGN GOVERNOR - the game-side half of the resolution
## law. The game's OWN orientation (_orient_now) is the content's truth;
## the canvas mapping must always agree with it. Writes only on drift.
func _assert_design_law() -> void:
        if _orient_now == "":
                return   # a rotation reload is mid-flight - its own path owns the canvas
        var root := get_window()
        var want := ScaleRule.DESIGN_LANDSCAPE \
                        if _orient_now == "horizontal" \
                        else ScaleRule.DESIGN_PORTRAIT
        if ScaleRule.is_pc():
                ScaleRule.apply_pc(root, want)
        else:
                # phones: EXPAND fills the window edge-to-edge (the design
                # law rides _orient_now - the sensor is LOCKED during play)
                if root.content_scale_aspect \
                                != Window.CONTENT_SCALE_ASPECT_EXPAND:
                        ScaleRule.apply_expand(root)
                if root.content_scale_size != want:
                        root.content_scale_size = want

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
        # v0.4.1 THE DESIGN FOLLOWS THE CONTENT LAW: on a PC the game's OWN
        # orientation picks the design - never the window's shape - and the
        # stretch is KEEP (apply_pc): windowed the window reshapes itself to
        # the game (re_window), fullscreen or off-aspect the brown bars come
        # back instead of any stretch. Landscape games are NOT special
        # anymore: the old EXPAND-on-PC path was the portrait-fullscreen
        # corruption's twin.
        if ScaleRule.is_pc():
                var kind := "landscape" if landscape else "portrait"
                ScaleRule.apply_pc(root, ScaleRule.DESIGN_LANDSCAPE
                                if landscape else ScaleRule.DESIGN_PORTRAIT)
                ScaleRule.re_window(kind)
                return
        ScaleRule.apply_expand(root)
        root.content_scale_size = ScaleRule.DESIGN_LANDSCAPE if landscape \
                        else ScaleRule.DESIGN_PORTRAIT
        # v041-1: the sensor rotation is a PHONE law - a desktop display
        # server answers with "Orientation not supported" (the owner's log
        # spam) and the design/window laws above already own the PC seat.
        if not ScaleRule.is_pc():
                DisplayServer.screen_set_orientation(
                                DisplayServer.SCREEN_SENSOR_LANDSCAPE
                                if landscape else DisplayServer.SCREEN_SENSOR_PORTRAIT)

func _restore() -> void:
        # v0.3.8-5 THE COMFORT LAW: hand the 60 frames back to the box
        Engine.max_fps = 30
        # v0.1.3: NO blind portrait pin. Decide from the REAL window px at
        # this exact moment (a landscape-held phone keeps the landscape
        # design - no flash), release the rotation lock, and let the menu
        # governor keep watching from here: whenever the system actually
        # rotates the window, the design follows within one frame.
        _flush_time()
        if ScaleRule.is_pc():
                # v0.4.1: back to the MENU'S OWN position (pc_position - a
                # landscape game must not leave the menu sideways) - the
                # window follows it, so the menu fills its window again.
                ScaleRule.apply_pc(get_window(), ScaleRule.pc_menu_design())
                ScaleRule.re_window(ScaleRule.pc_position)
        else:
                ScaleRule.apply(get_window())
        # v041-1: the sensor release is a PHONE law (see _apply_orientation)
        if not ScaleRule.is_pc():
                DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)

func _quit_to_menu() -> void:
        _session_open = false
        _close_over_sheet()
        # THE PAUSE NEVER OUTLIVES ITS SESSION (v0.3.9-13, the flow rig's
        # catch): quitting from under an open character story card (the
        # once-ever lore opens at first boot; quitting instead of tapping
        # through) must never carry the tree pause into the next launch
        if game != null and is_instance_valid(game) \
                        and game.has_method("box_story_dismiss"):
                game.box_story_dismiss()
        get_tree().paused = false
        _flush_time()
        # v0.2.3: leaving the game releases its pool's clock (charging resumes
        # from the moment the player is OUT of the game)
        Box.clear_active_game()
        _restore()
        GameHost.end_session()
        if router != null and is_instance_valid(router) and router.has_method("on_game_closed"):
                router.call("on_game_closed")

## Android back button while playing -> THE BACK LAW (v0.3.3-p2): a game
## sheet open -> close it; the pause sheet open -> resume; nothing open ->
## pause. The same behavior as the HUD "<" button (game_base._back_pressed).
func request_pause() -> void:
        if game != null and is_instance_valid(game) and not game.over:
                game._back_pressed()

## v0.4.1 THE UNFOCUS PAUSE LAW: the box lost focus - the game sits on its
## pause sheet (never toggles: if the pause is already open it STAYS).
func ensure_pause_for_box() -> void:
        if game != null and is_instance_valid(game):
                game.ensure_pause_for_box()

func _exit_tree() -> void:
        if _session_open:
                _flush_time()
        Box.clear_active_game()   # v0.2.3: no hold can outlive its host

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
        # v041-1 THE FREED-SEAT GUARD (the owner's log spam: "Required object
        # 'rp_target' is null" + "Lambda capture at index N was freed" +
        # "Tween started with no Tweeners"): the 0.55s theatre delay can
        # outlive the session - a quit-to-box (or a pause-opened exit) frees
        # the game while this coroutine slept. The theatre must never build
        # its sheet over a freed overlay or tween freed labels again.
        if not _session_open:
                return
        if game == null or not is_instance_valid(game) \
                        or not is_instance_valid(game._overlay_root_ref()):
                return

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
        # the chip pops to the full amount.
        var div := _live_div()
        var earn_row := Arc.chip("+0 GOGACoins", "res://assets/ui/coin.png",
                        Color(0, 0, 0, 0.08), 30, Color("8a5a14"))
        var cc := HBoxContainer.new()
        cc.alignment = BoxContainer.ALIGNMENT_CENTER
        cc.add_child(earn_row)
        sheet.add_child(cc)
        var earn_lbl: Label = earn_row.get_child(0).get_child(earn_row.get_child(0).get_child_count() - 1)

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
                if total > 0:
                        sum_line.text = "pick up + score bonus = %d + %d" % [earned, bonus]
                        sum_line.visible = true
                        show_total.call(total)
                        Jukebox.sfx("coin", -2.0)
                        earn_row.pivot_offset = earn_row.size / 2.0
                        var pulse := create_tween()
                        pulse.tween_property(earn_row, "scale", Vector2(1.12, 1.12), 0.09)
                        pulse.tween_property(earn_row, "scale", Vector2.ONE, 0.12)
                elif game != null and is_instance_valid(game) \
                                and not game.score_bonus_enabled:
                        # v0.2.3 patch: a run with NOTHING to pay states the
                        # rule instead of a fake "0 + 0" theatre - the game
                        # zeroed its own bonus (peace style): score / 0 = 0
                        sum_line.text = "peace run  -  score bonus = %d/0" % final_score
                        sum_line.visible = true)

        if not res["new_best"]:
                var hype := Arc.label("best %d" % int(res["best"]), 24, Color("8a6a40"))
                hype.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                sheet.add_child(hype)

        if total > 0:
                # v0.0.9 owner rule ("i told you more than two times"): the
                # honest math line - pickups and the score bonus ratio, in
                # ONE modular format (Arc.bonus_ratio_text). THE 0-ADS LAW:
                # the old rewarded DOUBLE theatre around it is gone whole.
                var ratio := Arc.label("pickups = %d   -   score bonus = %s" %
                                [earned, Arc.bonus_ratio_text(final_score, div)],
                                18, Color("8a6a40"), false)
                ratio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                sheet.add_child(ratio)

        # ---- v0.1.4 RETRY ECONOMY (owner rule: "same for retry logic too"):
        # the charge is what the wallet can ACTUALLY pay - snake pours every
        # coin it has (min(fee, wallet)), an empty wallet replays free, other
        # games still pay the full fee. Daily caps + batteries gate the tap
        # BEFORE any coin moves, so a refused retry never eats the wallet.
        var pay_now := fee
        if partial:
                pay_now = Box.entry_cost(id, fee)
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
                        # re-derive the truth at tap time - the wallet may have
                        # moved while the sheet was open
                        var pay := Box.entry_cost(id, fee) if partial else fee
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
                        _close_over_sheet()
                        _clear_game()
                        game = (load(String(game_def["script"])) as GDScript).new()
                        game.game_id = id
                        game.request_finish.connect(_on_finish)
                        game.request_quit.connect(_quit_to_menu)
                        game.request_orientation_reload.connect(_on_orientation_reload)
                        add_child(game)
                        # v0.1.9: replays count at start too
                        Box.record_started(id)
                        # v0.2.3: the hold survives retries (same game open)
                        Box.set_active_game(id))
        sheet.add_child(again_btn)

        sheet.add_child(Arc.button("BACK TO BOX", Vector2(480, 84), 28, Color(0.42, 0.30, 0.16), func():
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

## v0.2.8: the LIVE bonus divider - the registry coin_div by default, but
## a game with mode-dependent math (2048 board sizes) overrides it through
## the modular bonus_div_override var. ONE helper so the dead menu's
## theatre, the honest-math line and the payout all agree.
func _live_div() -> int:
        var div := int(game_def.get("coin_div", 100))
        if game != null and is_instance_valid(game) \
                        and int(game.bonus_div_override) > 0:
                div = int(game.bonus_div_override)
        return div

func _score_to_coins(s: int) -> int:
        # MODULAR per game (registry "coin_div"): score / divider, and BELOW the
        # divider a run earns nothing ("easy 500-score game -> /100" style).
        # Games with in-run collectables can still rely on pickups; the divider
        # is just the predictable fallback. No key -> default /100.
        # v0.2.0: the game can ZERO its own bonus through the modular
        # score_bonus_enabled flag (snake PEACE style gives the bonus up).
        if game != null and is_instance_valid(game) and not game.score_bonus_enabled:
                return 0
        var div := _live_div()
        if div <= 0 or s < div:
                return 0
        return s / div
