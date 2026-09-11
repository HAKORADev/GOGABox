extends Node2D
func _ready() -> void:
        var l := Node2D.new()
        l.draw.connect(func():
                var pts := PackedVector2Array()
                for k in 11:
                        pts.append(Vector2(100 + k * 80, 900))
                l.draw_polyline(pts, Color("ffb020", 0.95), 12.0, true)
                l.draw_polyline(pts, Color(Color("ffb020"), 0.95), 12.0, true)
        )
        add_child(l)
        l.queue_redraw()
        await get_tree().create_timer(1.0).timeout
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/film39/strike_probe.png")
        print("probe saved, px at (180,900)=", img.get_pixel(180, 900))
        get_tree().quit(0)
