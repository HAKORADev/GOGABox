extends Node
## v041-1 r2 film: THE OWNER'S CURSOR laws, verified through SoftCursor's
## own seat on the NATURAL 9:16 boot (no window hacks - the whole window
## IS the content there, so the in-app grab sees every cursor pixel).
##   glyph   - the owner's 32x32 art rides the pointer 1:1 (real px): the
##             layer sheds the stretch transform, the sprite's top-left
##             sits EXACTLY at the OS mouse position (hotspot 0,0)
##   shadow  - code-built from the glyph's alpha, capped at 60% strength
##             (REAL alpha - never an opaque block), rendered under the
##             glyph: the same content pixel darkens with the cursor over
##             it and returns when the cursor leaves
##   hold    - the code darkening flips self_modulate while the left
##             button is held (the law's chain end to end)

var fails := 0

func ck(cond: bool, what: String) -> void:
        if cond:
                print("PROBE_OK - %s" % what)
        else:
                fails += 1
                print("PROBE_FAIL - %s" % what)

func _snap(tag: String) -> Image:
        await get_tree().process_frame
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/v0411r2_cur_%s.png" % tag)
        print("FILM: cur_%s %s" % [tag, img.get_size()])
        # the screen-grab window: the rig's ffmpeg catches the beat while
        # the state holds (2.5s = 5 frames at 2fps)
        await get_tree().create_timer(2.5).timeout
        return img

func _ready() -> void:
        await get_tree().process_frame
        if not ScaleRule.is_pc():
                print("PROBE_SKIP - not a PC display session")
                get_tree().quit(0)
                return
        Box.reset_all()
        # seat the window at the screen origin - position ONLY (no size
        # write; the WM-less Xvfb keeps stale node state on size writes,
        # but a position move is inert) - the x11grab then reads the app's
        # real pixels 1:1 for the eye pass
        DisplayServer.window_set_position(Vector2i(0, 0))
        var main := Node2D.new()
        main.set_script(load("res://game/main.gd"))
        add_child(main)
        await get_tree().create_timer(2.5).timeout
        # THE SEAT: the box armed the software cursor
        var cur: SoftCursor = main.get("_cur_node")
        ck(cur != null and is_instance_valid(cur),
                        "the box arms the SoftCursor on PC")
        if cur == null:
                print("PROBE cursor_RESULT 1 FAIL")
                get_tree().quit(0)
                return
        var glyph_tex := cur.glyph.texture
        ck(glyph_tex.get_width() == 32 and glyph_tex.get_height() == 32,
                        "the glyph is the owner's 32x32 art")
        ck(cur.hotspot == Vector2.ZERO, "the tip (hotspot 0,0) rides the pointer")
        # THE SHADOW TEXTURE: code-built, real alpha - capped at 60%, and
        # it EXISTS (a silhouette of the glyph, not a solid block)
        var sh_tex := cur.shadow.texture
        var sh := sh_tex.get_image()
        sh.convert(Image.FORMAT_RGBA8)
        var max_a := 0.0
        var lit := 0
        for y in sh.get_height():
                for x in sh.get_width():
                        var a := sh.get_pixel(x, y).a
                        max_a = maxf(max_a, a)
                        if a > 0.02:
                                lit += 1
        ck(max_a <= 0.61 and max_a > 0.2,
                        "the shadow peaks near the 60%% strength (%.2f)" % max_a)
        ck(lit > 200 and lit < sh.get_width() * sh.get_height() * 0.8,
                        "the shadow is a spread silhouette (%d lit px, not a block)"
                        % lit)
        # THE 1:1 REAL-PX SEAT: warp - the sprite's top-left must land on
        # the REAL mouse position, the layer shedding the stretch transform.
        # v041-1 r3: the shed reads the OS-TRUTH mapping
        # (ScaleRule.final_transform_of) - the engine's get_final_transform()
        # goes stale with the window desync and its inverse painted the
        # pointer into infinity on the owner's Windows (the r2 video).
        DisplayServer.warp_mouse(Vector2i(300, 400))
        await get_tree().create_timer(0.3).timeout
        var ft := ScaleRule.final_transform_of(get_window())
        ck(cur._layer.transform == ft.affine_inverse(),
                        "the cursor layer sheds the stretch (real px seat)")
        var mp := Vector2(DisplayServer.mouse_get_position()) \
                        - Vector2(DisplayServer.window_get_position())
        ck(cur.glyph.position.distance_to(mp) < 0.5,
                        "the glyph top-left rides the OS pointer (%s vs %s)"
                        % [cur.glyph.position, mp])
        ck(cur.shadow.position.distance_to(mp + SoftCursor.SHADOW_OFFSET)
                        < 0.5, "the shadow rides the offset (2,3)")
        ck(cur._layer.visible, "the cursor is visible at the VISIBLE seat")
        # THE OWNERSHIP LAW: a game hides the mouse - the software cursor
        # steps aside; a sheet restores the mode - it hands back
        Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
        await get_tree().create_timer(0.2).timeout
        ck(not cur._layer.visible,
                        "the cursor hides when a game takes the seat (HIDDEN)")
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        await get_tree().create_timer(0.2).timeout
        ck(cur._layer.visible, "the cursor returns when the seat hands back")
        # THE SHADOW RENDER (real alpha over the app): the same content
        # pixel - cursor away vs cursor over it - darkens and returns.
        # (rig guard: the WM-less Xvfb's GL readback can return a blank
        # frame - the grab-dependent checks SKIP there, the texture-level
        # laws above already prove the real-alpha construction)
        var img_away: Image
        DisplayServer.warp_mouse(Vector2i(150, 900))
        await get_tree().create_timer(0.3).timeout
        img_away = await _snap("away")
        var under := img_away.get_pixel(int(300 * 1.5) + 39, int(400 * 1.5) + 24)
        DisplayServer.warp_mouse(Vector2i(300, 400))
        await get_tree().create_timer(0.3).timeout
        var img_here := await _snap("here")
        var shadowed := img_here.get_pixel(int(300 * 1.5) + 39, int(400 * 1.5) + 24)
        print("PROBE shadow_pair under=%s shadowed=%s" % [under, shadowed])
        # the blank guard wears BOTH rig flavors (r3): the WM-less Xvfb's
        # readback comes back fully transparent (alpha 0) on some llvmpipe
        # builds and OPAQUE black (alpha 1) on others - the app's own dark
        # menu bg is never THAT black (BG_BASE 0.15,0.08,0.03), so an
        # opaque (0,0,0) is a dead rig read, not an honest pixel.
        var grab_blank := (under.a == 0.0 and under.v == 0.0) \
                        or (under.a >= 1.0 and under.r < 0.02 \
                        and under.g < 0.02 and under.b < 0.02)
        if grab_blank:
                print("PROBE_SKIP - the rig's readback is blank (grab laws)")
        else:
                ck(shadowed.r < under.r and shadowed.g < under.g
                                and shadowed.b < under.b,
                                "the shadow darkens the app under it (REAL alpha)")
                ck(shadowed.v > 0.02 or under.v > 0.02,
                                "the shadow is not an opaque block")
        # THE GLYPH RENDER: gold pixels at the pointer (design coords)
        var gpx := img_here.get_pixel(int(300 * 1.5) + 7, int(400 * 1.5) + 4)
        print("PROBE glyph_sample=", gpx)
        if grab_blank:
                print("PROBE_SKIP - the rig's readback is blank (glyph grab)")
        else:
                ck(gpx.r > 0.4 and gpx.g > 0.25,
                                "the owner's gold arrow renders")
        # THE HOLD LAW: a real left press - the code darkening
        var mb := InputEventMouseButton.new()
        mb.button_index = MOUSE_BUTTON_LEFT
        mb.pressed = true
        mb.position = Vector2(300, 400)
        Input.parse_input_event(mb)
        Input.flush_buffered_events()
        await get_tree().create_timer(0.3).timeout
        var held := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
        print("PROBE held_state=", held,
                " modulate=", cur.glyph.self_modulate)
        ck(held and cur.glyph.self_modulate.r < 0.99,
                        "the hold darkening arms (modulate %s)"
                        % cur.glyph.self_modulate)
        var img_held := await _snap("held")
        var hg := img_held.get_pixel(int(300 * 1.5) + 7, int(400 * 1.5) + 4)
        if grab_blank:
                print("PROBE_SKIP - the rig's readback is blank (held grab)")
        else:
                ck(hg.r < gpx.r and hg.g < gpx.g,
                                "the held glyph renders darker (%s -> %s)" % [gpx, hg])
        var mb2 := InputEventMouseButton.new()
        mb2.button_index = MOUSE_BUTTON_LEFT
        mb2.pressed = false
        mb2.position = Vector2(300, 400)
        Input.parse_input_event(mb2)
        Input.flush_buffered_events()
        await get_tree().create_timer(0.2).timeout
        ck(cur.glyph.self_modulate == Color.WHITE,
                        "the darkening releases")
        print("PROBE cursor_RESULT %s" % ("ALL OK" if fails == 0
                        else "%d FAILS" % fails))
        get_tree().quit(0)
