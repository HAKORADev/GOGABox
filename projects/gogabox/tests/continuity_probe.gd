extends SceneTree
## v040-11 THE CONTINUITY LAW verifier: a menu sheet's list keeps its
## scroll offset across the close+rebuild chain (the owner's global nuke).

var fails := 0

func ck(ok: bool, what: String) -> void:
        print(("[PASS] " if ok else "[FAIL] ") + what)
        if not ok:
                fails += 1

func _init() -> void:
        call_deferred("_run")

func _run() -> void:
        var root_ctrl := Control.new()
        root_ctrl.size = Vector2(600, 900)
        get_root().add_child(root_ctrl)
        await process_frame

        # a sheet-like parent + a keyed scroll inside it
        var sheet_a := Control.new()
        root_ctrl.add_child(sheet_a)
        var sc := BoxScroll.new()
        sc.preserve_key = "probe_shop"
        sc.size = Vector2(600, 800)
        sheet_a.add_child(sc)
        var list := VBoxContainer.new()
        sc.add_child(list)
        for i in 60:
                var l := Label.new()
                l.text = "row %d" % i
                l.custom_minimum_size = Vector2(560, 40)
                list.add_child(l)
        await process_frame
        await process_frame
        sc.scroll_vertical = 700
        await process_frame
        ck(sc.scroll_vertical == 700, "scrolled to 700")

        # THE REBUILD CHAIN: free the old sheet, build a new one with the
        # same key, reinstate - the law's exact choreography
        sc.remember()
        sheet_a.queue_free()
        await process_frame
        var sheet_b := Control.new()
        root_ctrl.add_child(sheet_b)
        var sc2 := BoxScroll.new()
        sc2.preserve_key = "probe_shop"
        sc2.size = Vector2(600, 800)
        sheet_b.add_child(sc2)
        var list2 := VBoxContainer.new()
        sc2.add_child(list2)
        for i in 60:
                var l := Label.new()
                l.text = "new row %d" % i
                l.custom_minimum_size = Vector2(560, 40)
                list2.add_child(l)
        print("LEDGER: ", BoxScroll._ledger)
        sc2.reinstate()
        print("AFTER REINSTATE: ", sc2.scroll_vertical)
        await process_frame
        print("AFTER 1 FRAME: ", sc2.scroll_vertical)
        await process_frame
        ck(sc2.scroll_vertical == 700,
                "the rebuilt list re-opens AT 700 (no top-jump, no flicker)")

        # a different key never cross-pollinates
        var sc3 := BoxScroll.new()
        sc3.preserve_key = "other_list"
        root_ctrl.add_child(sc3)
        await process_frame
        ck(sc3.scroll_vertical == 0, "an unrelated list starts at the top")

        print("VERDICT: ", "CONTINUITY LAW HOLDS" if fails == 0
                else "%d FAILS" % fails)
        quit(0 if fails == 0 else 1)
