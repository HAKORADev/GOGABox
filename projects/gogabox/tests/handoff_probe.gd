extends SceneTree
## v040-12 THE HANDOFF LAW verifier (the scroll nuke's root kill):
## a game shop rebuilds its sheet on every buy - the old sheet's BoxScroll
## dies (queue_free) and a NEW keyless BoxScroll is born in the same
## frame. The handoff law: the newborn ADOPTS the dying scroll's offset
## and restores it before the first draw. No keys, no ledger writes.

var fails := 0

func ck(ok: bool, what: String) -> void:
        print(("[PASS] " if ok else "[FAIL] ") + what)
        if not ok:
                fails += 1

func _init() -> void:
        call_deferred("_run")

func _run() -> void:
        var root_ctrl := Control.new()
        root_ctrl.name = "overlay_scope"
        root_ctrl.size = Vector2(600, 800)
        get_root().add_child(root_ctrl)
        await process_frame
        # ---- the shop sheet v1: a keyless BoxScroll, scrolled to 700
        var sheet1 := Control.new()
        root_ctrl.add_child(sheet1)
        var sc1 := BoxScroll.new()
        sheet1.add_child(sc1)
        var content1 := VBoxContainer.new()
        content1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc1.add_child(content1)
        for i in 60:
                var row := Label.new()
                row.text = "row %d" % i
                row.custom_minimum_size = Vector2(500, 40)
                content1.add_child(row)
        await process_frame
        await process_frame
        sc1.scroll_vertical = 700
        await process_frame
        ck(sc1.scroll_vertical == 700, "the keyless shop list sits at 700")
        # ---- THE BUY: the sheet tears down (queue_free - dies at frame
        # end) and the SAME builder builds the new sheet in the same call
        sheet1.queue_free()
        var sheet2 := Control.new()
        root_ctrl.add_child(sheet2)
        var sc2 := BoxScroll.new()
        sheet2.add_child(sc2)
        var content2 := VBoxContainer.new()
        content2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc2.add_child(content2)
        for i in 60:
                var row := Label.new()
                row.text = "row %d" % i
                row.custom_minimum_size = Vector2(500, 40)
                content2.add_child(row)
        # no frame passes: the dying scroll is still in the tree - the
        # handoff reads it right here, at the newborn's _ready
        await process_frame
        await process_frame
        ck(sc2.scroll_vertical == 700,
                "THE HANDOFF LAW: the rebuilt keyless list re-opens AT 700")
        # ---- a multi-dying-scrolls case must NOT adopt (ambiguity guard):
        # three lists die in the SAME frame the newborn is built - the
        # handoff refuses to guess which offset is mine
        sheet2.queue_free()
        for idx in 2:
                var dying := Control.new()
                root_ctrl.add_child(dying)
                var dsc := BoxScroll.new()
                dying.add_child(dsc)
                var dc := VBoxContainer.new()
                dsc.add_child(dc)
                for i in 60:
                        var row := Label.new()
                        row.custom_minimum_size = Vector2(500, 40)
                        dc.add_child(row)
                dying.queue_free()       # NO await - all dying coexist
        var nb := BoxScroll.new()
        root_ctrl.add_child(nb)
        var nb_content := VBoxContainer.new()
        nb.add_child(nb_content)
        for i in 60:
                var row := Label.new()
                row.custom_minimum_size = Vector2(500, 40)
                nb_content.add_child(row)
        await process_frame
        await process_frame
        ck(nb.scroll_vertical == 0,
                "THE AMBIGUITY GUARD: three dying lists hand off nothing")
        print("VERDICT: %s" % ("HANDOFF LAW HOLDS" if fails == 0
                else "%d FAILS" % fails))
        quit(1 if fails > 0 else 0)
