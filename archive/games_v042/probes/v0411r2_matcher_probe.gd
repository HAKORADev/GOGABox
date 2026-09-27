extends Node
## v041-1 r2 probe: MATCHER - THE ALWAYS-AFTER-EACH-CHANGE LAW (the owner:
## "i will buy mode or skin while in the optionals menu, the thing got
## bought, will need game re-open to get updated ... make this check always
## after each change"). The walk is the owner's own scenario, every step
## through the real buttons:
##   boot -> the optionals is open (first_moment)
##   the locked PEACE card's tap -> the shop opens ON TOP of it
##   the shop's PEACE - 120 row -> the buy lands + the shop rebuilds (gate)
##   the shop's CLOSE -> the optionals REBUILDS from the live Box state
##   the fresh PEACE card's tap -> THE START LAW: the run starts (the
##   stale locked card would have re-opened the shop instead)

var g: GogaGame = null

func _settle(s: float) -> void:
        await get_tree().create_timer(s).timeout
        await get_tree().process_frame

## The top sheet's cc - the live sheet's content column.
func _top_cc() -> Control:
        var stack: Array = g.get("_sheet_stack")
        if stack == null or stack.is_empty():
                return null
        return stack.back()["cc"]

## The mode card button: a Button under the top sheet carrying a Label
## with the mode's name (the cards are built name-labeled, no .text).
func _find_card(mode_name: String) -> Button:
        var cc := _top_cc()
        if cc == null:
                return null
        for n in cc.find_children("*", "Button", true, false):
                var b := n as Button
                if b == null:
                        continue
                for m in b.find_children("*", "Label", true, false):
                        if (m as Label).text == mode_name:
                                return b
        return null

## A real .text button (the shop's CLOSE row) or a coin_button row (the
## visible text rides a child Label there - b.text stays empty).
func _find_text_button(needle: String) -> Button:
        var cc := _top_cc()
        if cc == null:
                return null
        for n in cc.find_children("*", "Button", true, false):
                var b := n as Button
                if b == null or b.disabled:
                        continue
                if b.text.begins_with(needle):
                        return b
                for m in b.find_children("*", "Label", true, false):
                        if (m as Label).text.begins_with(needle):
                                return b
        return null

func _ready() -> void:
        Box.reset_all()
        Box.dev_set_cheat("gogacoins", 1)   # the fat wallet - the buy lands
        var fails := 0
        var M: GDScript = load("res://game/games/matcher/matcher.gd")
        g = M.new()
        g.game_id = "matcher"
        ScaleRule.apply(get_window())
        add_child(g)
        await _settle(0.8)
        var boot_open: bool = g.pick_open
        print("PROBE matcher_boot_optionals %s" %
                        ("OK" if boot_open else "FAIL"))
        if not boot_open:
                fails += 1
        # the locked PEACE card -> its tap opens the shop (the SNAKE LAW)
        var locked := _find_card("PEACE")
        print("PROBE matcher_locked_card_found %s" %
                        ("OK" if locked != null else "FAIL"))
        if locked == null:
                print("PROBE matcher_RESULT 1 FAIL")
                get_tree().quit()
                return
        locked.pressed.emit()
        await _settle(0.3)
        var shop_row := _find_text_button("PEACE")
        print("PROBE matcher_shop_row_found %s" %
                        ("OK" if shop_row != null else "FAIL"))
        if shop_row == null:
                print("PROBE matcher_RESULT 1 FAIL")
                get_tree().quit()
                return
        # THE BUY - the shop row's real lambda: Box.buy_item + _shop_rebuild
        shop_row.pressed.emit()
        await _settle(0.3)
        var owned_now: bool = Box.item_owned("matcher", "modes", "peace")
        print("PROBE matcher_bought %s" % ("OK" if owned_now else "FAIL"))
        if not owned_now:
                fails += 1
        # THE CLOSE - the real close the player sees; the optionals must
        # rebuild (the ALWAYS-AFTER-EACH-CHANGE law)
        var close_btn := _find_text_button("CLOSE")
        print("PROBE matcher_close_found %s" %
                        ("OK" if close_btn != null else "FAIL"))
        if close_btn == null:
                print("PROBE matcher_RESULT %d FAILS" % (fails + 1))
                get_tree().quit()
                return
        close_btn.pressed.emit()
        await _settle(0.3)
        var fresh := _find_card("PEACE")
        var rebuilt: bool = fresh != null and fresh != locked \
                        and is_instance_valid(fresh)
        print("PROBE matcher_optionals_rebuilt %s" %
                        ("OK" if rebuilt else "FAIL"))
        if not rebuilt:
                fails += 1
        # THE START LAW - the fresh owned card STARTS the mode (the stale
        # locked card would have opened the shop again)
        fresh.pressed.emit()
        await _settle(0.3)
        var started: bool = g.mode == "peace" and g.phase == "play"
        print("PROBE matcher_owned_card_starts %s" %
                        ("OK" if started else "FAIL"))
        if not started:
                fails += 1
        print("PROBE matcher_RESULT %s" % ("ALL OK" if fails == 0
                        else "%d FAILS" % fails))
        get_tree().quit()
