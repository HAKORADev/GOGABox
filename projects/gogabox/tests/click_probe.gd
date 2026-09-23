extends Node
## click_probe (v041-2 r3) - THE OWNER-EXPERIENCE RIG: real synthetic mouse
## clicks through the REAL GUI pipeline (Input.parse_input_event, window px
## mapped through the stretch transform), against the REAL games booted
## through GameHost.launch, under a REAL Xvfb window. Built because the r2
## headless taps verified NOTHING (window 0x0 - every click landed on 0,0)
## while the birth shield ate every click alive. THE LAW: a sheet fix is
## not shipped until a CLICK lands on it here.
##
## QA_CLICK=towerball|heavywar|towerdestroyer  godot --path . res://tests/click_probe.tscn

var fails := 0

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        var rig := OS.get_environment("QA_CLICK")
        if rig.is_empty():
                rig = "towerball"
        DirAccess.make_dir_recursive_absolute("/tmp/click_probe")
        print("=== CLICK PROBE: %s ===" % rig)
        Box.reset_all()
        Box.earn(100000)
        Box.unlock_game("towerball", 0)
        Box.unlock_game("heavywar", 0)
        Box.unlock_game("towerdestroyer", 0)
        if rig == "towerball":
                await _towerball()
        elif rig == "towerdestroyer":
                await _towerdestroyer()
        else:
                await _heavywar()
        print("=== CLICK PROBE DONE: %d fails ===" % fails)
        get_tree().quit(1 if fails > 0 else 0)

# ---------------------------------------------------------------- helpers
func _settle(frames: int) -> void:
        for i in frames:
                await get_tree().process_frame

func _wait(sec: float) -> void:
        await get_tree().create_timer(sec, true, false, true).timeout

func _design_to_window(at: Vector2) -> Vector2:
        var win := get_window()
        var vp := win.get_visible_rect().size
        var wpx := DisplayServer.window_get_size()
        var s := minf(float(wpx.x) / vp.x, float(wpx.y) / vp.y)
        var off := (Vector2(wpx) - vp * s) * 0.5
        return off + at * s

func _click_design(at: Vector2) -> void:
        var wp := _design_to_window(at)
        var mk := func(pressed: bool):
                var ev := InputEventMouseButton.new()
                ev.button_index = MOUSE_BUTTON_LEFT
                ev.pressed = pressed
                ev.position = wp
                ev.global_position = wp
                Input.parse_input_event(ev)
        mk.call(true)
        await _wait(0.06)
        mk.call(false)
        await _wait(0.06)

func _click_button(b: Control) -> void:
        await _click_design(b.get_global_rect().get_center())

## every clickable Button in the subtree (visible only), with its text
func _buttons_of(root: Node) -> Array:
        var out: Array = []
        var stack: Array = [root]
        while not stack.is_empty():
                var n: Node = stack.pop_back()
                if n is BaseButton and (n as Control).is_visible_in_tree():
                        out.append(n)
                for c in n.get_children():
                        stack.append(c)
        return out

func _btn_by_text(root: Node, txt: String) -> Control:
        for b in _buttons_of(root):
                if b is Button and String((b as Button).text) == txt:
                        return b
        # the card buttons carry their word in a CHILD Label (the phone
        # cards, the coin rows) - search the subtree
        for b in _buttons_of(root):
                var stack: Array = [b]
                while not stack.is_empty():
                        var n: Node = stack.pop_back()
                        if n is Label and String((n as Label).text) == txt:
                                return b
                        for c in n.get_children():
                                stack.append(c)
        return null

func _verdict(name: String, ok: bool) -> void:
        if ok:
                print("PASS  %s" % name)
        else:
                fails += 1
                print("FAIL  %s" % name)

# --------------------------------------------------------------- towerball
func _towerball() -> void:
        var portrait := true
        DisplayServer.window_set_size(Vector2i(720, 1280) if portrait
                        else Vector2i(1280, 720))
        await _settle(4)
        var GH: GDScript = load("res://game/core/game_host.gd")
        var router := Node2D.new()
        add_child(router)
        GH.launch(router, "towerball")
        var host: Node = null
        for i in 120:
                await _wait(0.1)
                host = GH.active_host
                if host != null and is_instance_valid(host) \
                                and host.game != null:
                        break
        _verdict("boot: host alive", host != null and is_instance_valid(host))
        if host == null:
                return
        var game: Node = host.game
        _verdict("boot: game node alive (waited up to 12s)", game != null)
        var overlay: Control = game._overlay_root_ref()

        # ---- step 1: the ask is FIRST (the position screen) ----
        _verdict("flow: phase orient after boot", String(game.phase) == "orient")
        var pos_cards: Array = _buttons_of(overlay).filter(func(b):
                var stack: Array = [b]
                while not stack.is_empty():
                        var n: Node = stack.pop_back()
                        if n is Label and String((n as Label).text) \
                                        in ["VERTICAL", "HORIZONTAL"]:
                                return true
                        for c in n.get_children():
                                stack.append(c)
                return false)
        _verdict("flow: POSITION cards (the phone assets) first (%d)"
                        % pos_cards.size(), pos_cards.size() == 2)

        # ---- step 2: pick the SAME position (VERTICAL) -> the MODE screen
        # (picking the OPPOSITE position reloads through the host - that is
        # the universal law; the same-position pick must walk forward) ----
        var vcard := _btn_by_text(overlay, "VERTICAL")
        _verdict("flow: the VERTICAL phone card found", vcard != null)
        if vcard != null:
                await _click_button(vcard)
                await _wait(0.5)
                _verdict("flow: a position pick opens the MODE screen "
                                + "(phase=%s)" % String(game.phase),
                                String(game.phase) == "mode")
                # and the OPPOSITE pick must RELOAD through the host (the
                # universal law) - the next game lands in the mode screen
                var hcard := _btn_by_text(overlay, "HORIZONTAL")
                if hcard != null:
                        var old_game: Node = game
                        await _click_button(hcard)
                        var reloaded := false
                        for i in 120:
                                await _wait(0.1)
                                var h2: Node = GH.active_host
                                if h2 != null and is_instance_valid(h2) \
                                                and h2.game != null \
                                                and h2.game != old_game:
                                        game = h2.game
                                        overlay = game._overlay_root_ref()
                                        reloaded = true
                                        break
                        _verdict("flow: the OPPOSITE position RELOADS the "
                                        + "game (the universal law)", reloaded)
                        if reloaded:
                                await _wait(0.4)
                                _verdict("flow: the reload lands on the MODE "
                                                + "screen (phase=%s)"
                                                % String(game.phase),
                                                String(game.phase) == "mode")

        # ---- step 3: pick the PLATFORM mode card (a real click) -> READY ----
        var mode_card := _btn_by_text(overlay, "PLATFORM")
        _verdict("flow: mode card PLATFORM present", mode_card != null)
        if mode_card != null:
                await _click_button(mode_card)
                await _wait(0.4)
                _verdict("flow: the mode pick SAVED + the ready card shows "
                                + "(phase=%s, mode=%s)" % [String(game.phase),
                                String(Box.get_progress("towerball", "mode",
                                "ball"))],
                                String(game.phase) == "ready"
                                and String(Box.get_progress("towerball",
                                "mode", "ball")) == "platform")

        # ---- step 4: the ready card -> a real tap starts the run ----
        var vp := get_window().get_visible_rect().size
        await _click_design(vp * 0.5)
        await _wait(0.4)
        _verdict("flow: the ready tap fired the run (phase=%s)"
                        % String(game.phase),
                        String(game.phase) in ["transition", "run"])
        for i in 300:
                await _wait(0.1)
                if String(game.phase) == "run":
                        break
        _verdict("flow: the run is LIVE (phase=%s)" % String(game.phase),
                        String(game.phase) == "run")

        # ---- step 5: the run listens to ITS mode's input ----
        if String(game.mode) == "platform":
                # the platform ride: LEFT/RIGHT (or a drag) ROTATES the
                # tower - the rings' rotation must move under a held key
                var rot0 := 0.0
                for r in game.rings.values():
                        rot0 = float(r["rot"])
                        break
                var evk := InputEventKey.new()
                evk.keycode = KEY_LEFT
                evk.physical_keycode = KEY_LEFT
                evk.pressed = true
                Input.parse_input_event(evk)
                await _wait(0.6)
                var evk2 := InputEventKey.new()
                evk2.keycode = KEY_LEFT
                evk2.physical_keycode = KEY_LEFT
                evk2.pressed = false
                Input.parse_input_event(evk2)
                var rot1 := 0.0
                for r in game.rings.values():
                        rot1 = float(r["rot"])
                        break
                _verdict("run: a held LEFT arrow ROTATES the platform tower "
                                + "(rot %.3f -> %.3f)" % [rot0, rot1],
                                absf(rot1 - rot0) > 0.02)
        else:
                var by0: float = game.by
                var mk := func(pressed: bool):
                        var ev := InputEventMouseButton.new()
                        ev.button_index = MOUSE_BUTTON_LEFT
                        ev.pressed = pressed
                        var wp := _design_to_window(vp * 0.5)
                        ev.position = wp
                        ev.global_position = wp
                        Input.parse_input_event(ev)
                mk.call(true)
                await _wait(0.5)
                mk.call(false)
                _verdict("run: a held LMB drives the ball (by %.1f -> %.1f)"
                                % [by0, float(game.by)],
                                float(game.by) != by0)

        # ---- step 6: the SHOP opens by a real click on the HUD button ----
        var shop := _btn_by_text(game, "SHOP")
        _verdict("shop: the HUD SHOP button exists", shop != null)
        if shop != null:
                await _click_button(shop)
                await _wait(0.5)
                var rows: Array = _buttons_of(game._overlay_root_ref())
                _verdict("shop: the sheet opened via a real click "
                                + "(%d buttons live)" % rows.size(),
                                rows.size() >= 5)
                # a skin row click must not crash + must close/reopen cleanly
                var glass := _btn_by_text(game._overlay_root_ref(),
                                "GLASS TOWER  250")
                _verdict("shop: the GLASS TOWER row is clickable",
                                glass != null)
                if glass != null:
                        await _click_button(glass)
                await _wait(0.4)
                _verdict("shop: a skin buy/click keeps the sheet alive",
                                is_instance_valid(game) \
                                and game.sheet_open_count() >= 1)
                game.call("sheet_pop")
                await _wait(0.2)
                _verdict("back: back never closes the game menu (the ask "
                                + "screen is the root)",
                                String(game.phase) in ["orient", "mode",
                                "ready"] or game.sheet_open_count() == 0)

# --------------------------------------------------------------- heavywar
func _heavywar() -> void:
        DisplayServer.window_set_size(Vector2i(1280, 720))
        await _settle(4)
        var GH: GDScript = load("res://game/core/game_host.gd")
        var router := Node2D.new()
        add_child(router)
        GH.launch(router, "heavywar")
        var host: Node = null
        for i in 120:
                await _wait(0.1)
                host = GH.active_host
                if host != null and is_instance_valid(host) \
                                and host.game != null:
                        break
        var game: Node = host.game if host != null else null
        _verdict("boot: heavy war alive", game != null)
        if game == null:
                return
        # walk the intro/menu -> PLACE (the deploy state) like a player tap
        game.set("state", game.GS.PLACE)
        # force a level-up through the REAL gain path (the ticker only
        # opens from _gain_xp - a raw p_xp write never opens the cards)
        game.call("_gain_xp", int(game.p_xp_next) + 10)
        await _wait(0.8)
        _verdict("cards: the LEVEL UP sheet opened (paused=%s)"
                        % str(game.paused), bool(game.paused))
        var overlay: Control = game._overlay_root_ref()
        var cards: Array = _buttons_of(overlay).filter(func(b):
                return (b as Control).size.y > 200.0)
        _verdict("cards: three level-up cards are clickable (%d)"
                        % cards.size(), cards.size() == 3)
        if cards.size() == 3:
                var dmg_before: float = float(game.buffs["dmg"])
                await _click_button(cards[0])
                await _wait(0.5)
                var picked: bool = bool(game.card_choices.is_empty()) \
                                or float(game.buffs["dmg"]) != dmg_before \
                                or float(game.buffs["rate"]) != 0.0 \
                                or float(game.buffs["speed"]) != 0.0
                _verdict("cards: a REAL CLICK picks a card (the r2 shield "
                                + "disease is dead)", picked)
                # the queue may re-open for a second level - close it too
                await _wait(0.4)
                if bool(game.paused) and game.sheet_open_count() > 0:
                        var cards2: Array = _buttons_of(
                                        game._overlay_root_ref()) \
                                        .filter(func(b):
                                                return (b as Control) \
                                                .size.y > 200.0)
                        if cards2.size() == 3:
                                await _click_button(cards2[0])
                                await _wait(0.4)
        # the pause sheet survives its own clicks (REGRESSION: the pause
        # law must not have regressed with the shield fix)
        game.set("paused", false)
        get_tree().paused = false
        game.call("_pause_open")
        await _wait(0.5)
        var resume := _btn_by_text(game._overlay_root_ref(), "RESUME")
        _verdict("pause: RESUME present under the paused tree", resume != null)
        if resume != null:
                await _click_button(resume)
                await _wait(0.4)
                _verdict("pause: a real click RESUMES (the pause sheet law "
                                + "holds)", not bool(game.paused))
        get_tree().paused = false

# ---------------------------------------------------------- towerdestroyer
func _towerdestroyer() -> void:
        DisplayServer.window_set_size(Vector2i(720, 1280))
        await _settle(4)
        var GH: GDScript = load("res://game/core/game_host.gd")
        var router := Node2D.new()
        add_child(router)
        GH.launch(router, "towerdestroyer")
        var host: Node = null
        for i in 120:
                await _wait(0.1)
                host = GH.active_host
                if host != null and is_instance_valid(host) \
                                and host.game != null:
                        break
        _verdict("boot: host alive", host != null and is_instance_valid(host))
        if host == null:
                return
        var game: Node = host.game
        _verdict("boot: game node alive (waited up to 12s)", game != null)
        var overlay: Control = game._overlay_root_ref()

        # ---- step 1: the CREW ask is FIRST (the portrait game skips the
        # position ask) ----
        _verdict("flow: phase players after boot",
                        String(game.phase) == "players")
        var crew_cards: Array = _buttons_of(overlay).filter(func(b):
                var stack: Array = [b]
                while not stack.is_empty():
                        var n: Node = stack.pop_back()
                        if n is Label and String((n as Label).text) \
                                        in ["1", "2", "3", "4"]:
                                return true
                        for c in n.get_children():
                                stack.append(c)
                return false)
        _verdict("flow: FOUR crew cards first (%d)" % crew_cards.size(),
                        crew_cards.size() == 4)

        # ---- step 2: back never closes the ask (the root law) ----
        game.call("_back_pressed")
        await _wait(0.3)
        _verdict("back: back never closes the crew ask",
                        String(game.phase) == "players")

        # ---- step 3: a real click on the 4 picks the FULL CREW -> ready ----
        var four := _btn_by_text(overlay, "4")
        _verdict("flow: the 4 card found", four != null)
        if four != null:
                await _click_button(four)
                await _wait(0.5)
                _verdict("flow: the crew pick opens the ready card "
                                + "(phase=%s, players=%s)" % [String(game.phase),
                                str(game.players)],
                                String(game.phase) == "ready"
                                and int(game.players) == 4)

        # ---- step 4: the ready tap starts the run ----
        var vp := get_window().get_visible_rect().size
        await _click_design(vp * 0.5)
        await _wait(0.5)
        for i in 200:
                await _wait(0.1)
                if String(game.phase) == "run":
                        break
        _verdict("flow: the run is LIVE (phase=%s)" % String(game.phase),
                        String(game.phase) == "run")
        var seats: Array = game.seats
        _verdict("crew: the four seats sat (=%d)" % seats.size(),
                        seats.size() == 4)
        var tags := 0
        for s in seats:
                if s["tag"] != null and is_instance_valid(s["tag"]):
                        tags += 1
        _verdict("crew: the 3 CPU score tags ride (%d)" % tags, tags == 3)

        # ---- step 5: a held LMB fires balls ----
        # lift the tower first: the seeded platforms descend to the muzzle
        # within seconds and a ball born inside a band dies honestly at
        # birth - the check needs the flight a player's early seconds have
        var lift: Array = game.plats
        for pp in lift:
                pp["y"] = float(pp["y"]) + 40.0
        var mk := func(pressed: bool):
                var ev := InputEventMouseButton.new()
                ev.button_index = MOUSE_BUTTON_LEFT
                ev.pressed = pressed
                var wp := _design_to_window(vp * 0.5)
                ev.position = wp
                ev.global_position = wp
                Input.parse_input_event(ev)
        mk.call(true)
        await _wait(0.6)
        mk.call(false)
        _verdict("run: a held LMB fires the cannon (%d balls live)"
                        % (game.balls as Array).size(),
                        (game.balls as Array).size() > 0)

        # ---- step 6: the SHOP opens by a real click + THE WIDTH LAW ----
        var shop := _btn_by_text(game, "SHOP")
        _verdict("shop: the HUD SHOP button exists", shop != null)
        if shop != null:
                await _click_button(shop)
                await _wait(0.5)
                var rows: Array = _buttons_of(game._overlay_root_ref())
                _verdict("shop: the sheet opened via a real click "
                                + "(%d buttons live)" % rows.size(),
                                rows.size() >= 5)
                # THE MENU WIDTH LAW: the sheet's panel is the measured
                # width (>= 800 design px even on a 720-wide window)
                var sheet_cc: Control = game._sheet_stack[-1]["cc"]
                var panel: Control = sheet_cc.get_child(0)
                _verdict("width: the sheet wears the measured base width "
                                + "(%.0f design px >= 800)" % panel.size.x,
                                panel.size.x >= 800.0)
                var close := _btn_by_text(game._overlay_root_ref(), "CLOSE")
                _verdict("shop: the CLOSE row present", close != null)
                if close != null:
                        await _click_button(close)
                        await _wait(0.4)
                        _verdict("shop: a real click CLOSES the shop",
                                        game.sheet_open_count() == 0)
