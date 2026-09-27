extends Node2D
## qa_fruits - renders EVERY fruit painter + power fruit + both places to a
## contact sheet the agent can actually LOOK at (the owner: "craft the
## assets better and take a look at them so you know what you have done").
## Lands in --out (default /tmp/snakeqa_fruits).
##
##   godot --path . res://tests/qa_fruits.tscn ++ --out=/tmp/snakeqa_fruits

var _out := "/tmp/snakeqa_fruits"
var _t := 0.0

func _ready() -> void:
        for a in OS.get_cmdline_user_args():
                if a.begins_with("--out="):
                        _out = a.split("=")[1]
        DirAccess.make_dir_recursive_absolute(_out)
        _run_async()

func _process(delta: float) -> void:
        _t += delta

func _shot(name_: String) -> void:
        await get_tree().create_timer(0.25).timeout
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [_out, name_])
        print("[qa] shot ", name_)

func _run_async() -> void:
        await _shot("fruits_sheet")
        await _shot("power_sheet")
        await _shot("places_sheet")
        get_tree().quit(0)

func _draw() -> void:
        var f := Arc.font_ui()
        # ---------- sheet 1: every fruit on the day garden lawn ----------
        var ids := SnakeFruits.FRUITS.keys()
        var cols := 4
        var cell := Vector2(150.0, 170.0)
        var size := Vector2(cols * cell.x, ceilf(ids.size() / float(cols)) * cell.y + 10.0)
        var pl: Dictionary = SnakeFruits.PLACES["day"]
        draw_rect(Rect2(Vector2.ZERO, size + Vector2(0, 40)), pl["field"])
        draw_rect(Rect2(Vector2.ZERO, size + Vector2(0, 40)), pl["deco"], false, 8.0)
        draw_string(f, Vector2(12, 30), "FRUITS v0.2.0 - the edible wardrobe",
                        HORIZONTAL_ALIGNMENT_LEFT, -1, 20, pl["ink"])
        for i in ids.size():
                var id: String = ids[i]
                var at := Vector2((i % cols) * cell.x + cell.x * 0.5,
                                float(i / cols) * cell.y + cell.y * 0.5 + 40.0)
                SnakeFruits.paint_fruit(self, id, at, 44.0, _t)
                draw_string(f, at + Vector2(-50, 58), String(id).to_upper(),
                                HORIZONTAL_ALIGNMENT_CENTER, 100, 13, pl["ink"])
        # ---------- sheet 2: power fruits with auras ----------
        var pow_ids := SnakeFruits.POWERS.keys()
        var pcell := Vector2(130.0, 150.0)
        var origin := Vector2(0.0, size.y + 60.0)
        draw_rect(Rect2(origin, Vector2(cols * pcell.x,
                        ceilf(pow_ids.size() / float(cols)) * pcell.y + 30.0)),
                        SnakeFruits.PLACES["night"]["field"])
        draw_string(f, origin + Vector2(12, 26),
                        "POWER FRUITS - the auras are the type signal",
                        HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.95, 1.0))
        for i in pow_ids.size():
                var pid: String = pow_ids[i]
                var at := origin + Vector2((i % cols) * pcell.x + pcell.x * 0.5,
                                float(i / cols) * pcell.y + pcell.y * 0.5 + 40.0)
                SnakeFruits.paint_power_fruit(self, pid, "apple", at, 34.0, _t)
                draw_string(f, at + Vector2(-55, 62), String(pid).to_upper(),
                                HORIZONTAL_ALIGNMENT_CENTER, 110, 13, Color(0.9, 0.95, 1.0))
        # ---------- sheet 3: the two places side by side ----------
        var o3 := Vector2(0.0, origin.y + ceilf(pow_ids.size() / float(cols)) * pcell.y + 50.0)
        var half := Vector2(300.0, 210.0)
        for k in 2:
                var pid2: String = ["day", "night"][k]
                var ppl: Dictionary = SnakeFruits.PLACES[pid2]
                var r := Rect2(o3 + Vector2(k * half.x, 0.0), half)
                draw_rect(r, ppl["void"])
                var inner := r.grow(-14.0)
                draw_rect(inner, ppl["field"])
                draw_rect(inner, ppl["wall"], false, 5.0)
                for d in 3:
                        draw_circle(inner.position + Vector2(50.0 + d * 80.0, 60.0 + (d % 2) * 40.0),
                                        26.0, Color(ppl["deco"], 0.6))
                if pid2 == "day":
                        # mini sun
                        draw_circle(r.position + Vector2(half.x - 46.0, 40.0), 20.0,
                                        Color(1.0, 0.91, 0.6, 1.0))
                else:
                        # mini moon + flies
                        draw_circle(r.position + Vector2(half.x - 46.0, 40.0), 16.0,
                                        Color(0.93, 0.96, 1.0, 1.0))
                        for fl in 5:
                                draw_circle(r.position + Vector2(40.0 + fl * 44.0,
                                                100.0 + (fl % 3) * 30.0), 3.0, Color(1.0, 0.91, 0.4, 0.8))
                draw_string(f, r.position + Vector2(12, 26), String(ppl["name"]),
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 17, ppl["ink"] if pid2 == "day" \
                                                else Color(0.85, 0.92, 1.0))
