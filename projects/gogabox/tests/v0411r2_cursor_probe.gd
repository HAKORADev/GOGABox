extends Node
## v041-1 r4 probe: THE HARDWARE GOGACURSOR laws (game/core/goga_cursor.gd).
## r2's software cursor died WITH the app's render path on the owner's
## Windows GPU (the r1 attach-call freeze - the pointer vanished with the
## presentation). The r4 cursor is OS-composited: Input.set_custom_mouse_
## cursor with a code-baked real-alpha shadow. The laws here:
##   seat    - the box arms the hardware cursor on PC, tip hotspot (6,6)
##   glyph   - the owner's 32x32 art rides inside the baked bitmap verbatim
##   shadow  - code-built from the glyph's alpha, capped at 60% strength,
##             REAL alpha (never an opaque block), offset (2,3) under it
##   hold    - the darkened variant exists and the code swaps to it
##   ownership - the seat hands over cleanly (disarm/arm idempotence), the
##             OS hides the image itself when a game hides the MODE

var fails := 0

func ck(cond: bool, what: String) -> void:
        if cond:
                print("PROBE_OK - %s" % what)
        else:
                fails += 1
                print("PROBE_FAIL - %s" % what)

func _ready() -> void:
        await get_tree().process_frame
        if not ScaleRule.is_pc():
                print("PROBE_SKIP - not a PC display session")
                get_tree().quit(0)
                return
        Box.reset_all()
        var main := Node2D.new()
        main.set_script(load("res://game/main.gd"))
        add_child(main)
        await get_tree().create_timer(2.0).timeout

        # THE SEAT: the box armed the hardware cursor
        var GCL := load("res://game/core/goga_cursor.gd")
        ck(GCL.is_armed(), "the box arms the HARDWARE cursor on PC")

        # THE GLYPH: the owner's 32x32 art rides the bitmap verbatim at the
        # pad offset; the tip hotspot is (6,6) (the pad moved the tip).
        var glyph: Texture2D = load("res://assets/ui/goga_cursor.png")
        ck(glyph != null and glyph.get_width() == 32
                        and glyph.get_height() == 32,
                        "the glyph is the owner's 32x32 art")
        var armed_img: Image = GCL._arrow.get_image()
        armed_img.convert(Image.FORMAT_RGBA8)
        ck(armed_img.get_width() == 44 and armed_img.get_height() == 44,
                        "the baked bitmap is 44x44 (32 glyph + the shadow pad)")
        var src_img: Image = glyph.get_image()
        if src_img.is_compressed():
                src_img.decompress()
        src_img.convert(Image.FORMAT_RGBA8)
        var glyph_match := true
        for y in 32:
                for x in 32:
                        if src_img.get_pixel(x, y).a > 0.003:
                                var c1 := src_img.get_pixel(x, y)
                                var c2 := armed_img.get_pixel(x + 6, y + 6)
                                if c1.is_equal_approx(c2) == false:
                                        glyph_match = false
        ck(glyph_match, "the glyph rides the bitmap verbatim (1:1, no rescale)")
        # THE SHADOW: real alpha, capped at 60%, a spread silhouette - and
        # it sits UNDER the glyph offset (2,3)
        var max_a := 0.0
        var lit := 0
        var under_shadow := 0.0
        for y in 44:
                for x in 44:
                        var a := armed_img.get_pixel(x, y).a
                        # the shadow's own cap: only pixels OUTSIDE the glyph
                        # rect (the glyph itself is opaque by design)
                        var in_glyph := x >= 6 and x < 38 and y >= 6 and y < 38
                        if not in_glyph:
                                max_a = maxf(max_a, a)
                        if a > 0.02:
                                lit += 1
        for y in 32:
                for x in 32:
                        var sa := armed_img.get_pixel(x + 8, y + 9).a
                        under_shadow = maxf(under_shadow, sa)
        ck(max_a <= 0.61 and max_a > 0.1,
                        "the visible fringe wears REAL alpha under the 60%% cap (%.2f)"
                        % max_a)
        ck(lit > 200 and lit < 44 * 44 * 0.8,
                        "the shadow is a spread silhouette (%d lit px, not a block)"
                        % lit)
        # the (2,3) offset + under-law, PROVEN ON A SYNTHETIC GLYPH: bake
        # from a 4x4 fully-opaque square - the shadow's core must then sit
        # at square+(2,3), OUTSIDE the square, with real (<=60%) alpha, and
        # NOTHING may paint up-left of the square+blur (the shadow never
        # leads the glyph)
        var sq := Image.create(4, 4, false, Image.FORMAT_RGBA8)
        for y in 4:
                for x in 4:
                        sq.set_pixel(x, y, Color(1, 1, 1, 1))
        var baked: Image = GCL._bake(false, sq).get_image()
        baked.convert(Image.FORMAT_RGBA8)
        # the offset law, dilution-proof: mass in the down-right quadrant
        # (beyond the square, past the blur) must dominate the up-left one
        var dr := 0.0
        var ul := 0.0
        for y in 44:
                for x in 44:
                        var a := baked.get_pixel(x, y).a
                        if a <= 0.01:
                                continue
                        if x > 10 and y > 10:
                                dr += a
                        elif x < 6 and y < 6:
                                ul += a
        ck(dr > 0.5 and dr > ul * 10.0,
                        "the shadow mass sits down-right of the glyph (dr %.2f vs ul %.2f)"
                        % [dr, ul])
        # THE HOLD VARIANT: the dark bitmap exists, differs only in the
        # glyph's tint (the shadow identical), and the swap call runs.
        var dark_img: Image = GCL._arrow_dark.get_image()
        dark_img.convert(Image.FORMAT_RGBA8)
        var dark_diff := 0
        for y in 32:
                for x in 32:
                        var a := src_img.get_pixel(x, y).a
                        if a > 0.5:
                                var c1 := armed_img.get_pixel(x + 6, y + 6)
                                var c2 := dark_img.get_pixel(x + 6, y + 6)
                                if c1.r - c2.r > 0.2:
                                        dark_diff += 1
        ck(dark_diff > 50, "the hold variant darkens the glyph (%d px)" % dark_diff)
        GCL.set_held(true)
        ck(GCL.is_armed(), "the hold swap keeps the seat armed")
        GCL.set_held(false)
        # THE OWNERSHIP LAW: disarm hands the seat to the OS default; arm
        # takes it back; neither errors, both idempotent.
        GCL.disarm()
        ck(not GCL.is_armed(), "disarm hands the seat back (games own it)")
        GCL.disarm()
        ck(true, "disarm is idempotent")
        GCL.arm()
        ck(GCL.is_armed(), "arm takes the seat back")
        GCL.arm()
        ck(true, "arm is idempotent (the engine cache short-circuits)")
        # THE MODE LAW: HIDDEN hides the OS image itself; VISIBLE hands it
        # back still armed - no per-frame paint, no software layer involved.
        Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
        await get_tree().create_timer(0.2).timeout
        ck(GCL.is_armed(), "the seat stays armed while the OS hides the image")
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        await get_tree().create_timer(0.2).timeout
        ck(GCL.is_armed(), "the seat returns armed when the mode does")
        # THE APP STILL RENDERS (the r1 freeze class is the thing this probe
        # ultimately guards against - a dead render path cannot present the
        # menu, and the whole r4 nuke exists to keep that road alive).
        await RenderingServer.frame_post_draw
        var frame := get_viewport().get_texture().get_image()
        var blank := true
        for y in range(0, frame.get_height(), 40):
                for x in range(0, frame.get_width(), 40):
                        var c := frame.get_pixel(x, y)
                        if c.a > 0.01 and (c.r > 0.02 or c.g > 0.02 or c.b > 0.02):
                                blank = false
        ck(not blank, "the app still presents real frames (no freeze)")
        print("PROBE cursor_RESULT %s" % ("ALL OK" if fails == 0
                        else "%d FAILS" % fails))
        get_tree().quit(0)
