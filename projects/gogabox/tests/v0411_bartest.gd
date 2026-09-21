extends Node2D
## v041-1 probe 2: can an inverse-stretch-transform CanvasLayer paint the
## KEEP letterbox bars? If the bars turn RED on the grab, the trick works.

var _bar_layer: CanvasLayer
var _bar_root: Control

func _ready() -> void:
        await get_tree().process_frame
        var win := get_window()
        win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
        win.content_scale_size = Vector2i(1920, 1080)
        RenderingServer.set_default_clear_color(Color(0.227451, 0.137255, 0.074510))
        # THE TEST: re-attach the root viewport to the WHOLE window - the
        # engine's KEEP letterbox rect keeps the rest of the window unrendered
        # (black X11 background). Full attach should expose the clear color.
        RenderingServer.viewport_attach_to_screen(
                        win.get_viewport_rid(), Rect2i(), 0)
        # the bar painter: lives in REAL window px via the inverse transform
        _bar_layer = CanvasLayer.new()
        _bar_layer.layer = -100
        add_child(_bar_layer)
        _bar_root = Control.new()
        _bar_layer.add_child(_bar_root)
        var top := ColorRect.new()
        top.color = Color(1, 0, 0)
        _bar_root.add_child(top)
        var bot := ColorRect.new()
        bot.color = Color(0, 1, 0)
        _bar_root.add_child(bot)
        _paint_bars()
        print("BARTEST5 painter ready")
        var t := 0.0
        while t < 40.0:
                await get_tree().process_frame
                _paint_bars()
                t += get_process_delta_time()
        get_tree().quit()

func _paint_bars() -> void:
        var vp := get_viewport()
        var ft := vp.get_final_transform()
        _bar_layer.transform = ft.affine_inverse()
        var wpx := DisplayServer.window_get_size()
        _bar_root.size = Vector2(wpx)
        # landscape design in a portrait window: bars top + bottom
        var scale := minf(float(wpx.x) / 1920.0, float(wpx.y) / 1080.0)
        var ch := 1080.0 * scale
        var bar_h := (float(wpx.y) - ch) / 2.0
        (_bar_root.get_child(0) as ColorRect).position = Vector2.ZERO
        (_bar_root.get_child(0) as ColorRect).size = Vector2(wpx.x, bar_h)
        (_bar_root.get_child(1) as ColorRect).position = Vector2(0, wpx.y - bar_h)
        (_bar_root.get_child(1) as ColorRect).size = Vector2(wpx.x, bar_h)
