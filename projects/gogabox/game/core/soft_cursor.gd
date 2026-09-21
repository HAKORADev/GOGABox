class_name SoftCursor
extends Node
## v041-1 r2 THE SOFTWARE GOGACURSOR - THE OWNER'S OWN ARROW, CODE-DRIVEN
## (the owner: "i made a better cursor, here, download the .cur file ...
## use code to make shadow with real alpha transparency so it be real and
## not just blocking what under it and make the hold/click cursor darkening
## using code and make it 1:1 scale to the OS cursor").
##
##   - THE GLYPH: his 32x32 .cur verbatim (assets/ui/goga_cursor.png,
##     committed next to it as goga_cursor_src.cur). No redraw, no resize.
##     The file's stored hotspot (9,9) contradicts the art - the arrow's
##     tip IS pixel (0,0), and an arrow aims with its tip the way the
##     Windows arrow always has. The tip rides the pointer exactly.
##   - THE SHADOW: code-built ONCE from the glyph's own alpha - a blurred
##     black silhouette at 60% strength, offset (2,3)px, composited by the
##     GPU with REAL alpha. The app under it stays visible through it -
##     nothing baked, nothing blocking.
##   - THE HOLD/CHECK: code darkening via self_modulate while the left
##     button is held - one art, two states, no second image.
##   - 1:1: the cursor layer sheds the window's stretch (final) transform
##     every frame and draws in REAL window pixels - the 32px art wears
##     the same footprint the OS pointer would, on any design scale.
##   - THE OWNERSHIP LAW (lives here now): the OS pointer wears a 1x1
##     fully-transparent image (the hardware cursor is silenced WITHOUT
##     touching the mouse MODE). A game that hides/captures the mode
##     (Heavy War's reticle) takes the seat and this cursor hides; a sheet
##     restoring MOUSE_MODE_VISIBLE hands it back.
##
## PROCESS_MODE_ALWAYS: a paused tree (a game's pause sheet) must never
## freeze the pointer - the hardware cursor kept tracking while paused,
## so this software one rides its own always-on frame clock.

## The pointer is the topmost thing the box owns (above the toasts' 100).
const LAYER_NUM := 128
## The hold/click darkening (the owner: "make the hold/click cursor
## darkening using code").
const HELD_TINT := 0.55
## The shadow's strength after the blur (real alpha - never opaque).
const SHADOW_STRENGTH := 0.6
## The shadow's drop offset in real px.
const SHADOW_OFFSET := Vector2(2, 3)

var glyph: Sprite2D
var shadow: Sprite2D
var hotspot := Vector2.ZERO

var _layer: CanvasLayer
var _shadow_tex: ImageTexture

func _init() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS

## (Re)seat the cursor with a glyph texture.
func build(tex: Texture2D) -> void:
        kill()
        if tex == null:
                return
        _layer = CanvasLayer.new()
        _layer.layer = LAYER_NUM
        add_child(_layer)
        shadow = Sprite2D.new()
        shadow.centered = false
        _shadow_tex = null
        shadow.texture = _shadow_from(tex)
        _layer.add_child(shadow)
        glyph = Sprite2D.new()
        glyph.centered = false
        glyph.texture = tex
        _layer.add_child(glyph)

func kill() -> void:
        if _layer != null and is_instance_valid(_layer):
                _layer.queue_free()
        _layer = null
        glyph = null
        shadow = null

func _process(_delta: float) -> void:
        var alive := _layer != null and is_instance_valid(_layer) \
                        and glyph != null
        if not alive:
                return
        var hidden_by_seat: bool = Input.mouse_mode == Input.MOUSE_MODE_HIDDEN \
                        or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
        var show: bool = not hidden_by_seat
        var win := get_window()
        if show and win != null:
                # THE 1:1 LAW: invert the stretch - the layer draws in real
                # px. v041-1 r3: the mapping is rebuilt from DISPLAYSERVER
                # TRUTH (ScaleRule.final_transform_of) - the engine's
                # get_final_transform() goes stale with the window desync
                # (and transiently singular during mode flips), and a
                # singular inverse paints the pointer into infinity: the
                # owner's r2 "no visible cursor".
                _layer.transform = ScaleRule.final_transform_of(win) \
                                .affine_inverse()
                var mp := Vector2(DisplayServer.mouse_get_position()) \
                                - Vector2(DisplayServer.window_get_position())
                var ws := Vector2(DisplayServer.window_get_size())
                # a mouse over another monitor paints no ghost at the window edge
                show = mp.x >= -8.0 and mp.y >= -8.0 \
                                and mp.x <= ws.x + 8.0 and mp.y <= ws.y + 8.0
                glyph.position = mp - hotspot
                shadow.position = mp - hotspot + SHADOW_OFFSET
                # THE HOLD/CHECK LAW
                var held := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
                glyph.self_modulate = Color(HELD_TINT, HELD_TINT, HELD_TINT) \
                                if held else Color.WHITE
        if _layer.visible != show:
                _layer.visible = show

## THE CODE SHADOW: the glyph's own alpha, blurred (two separable box
## passes, radius 2), colored black at 60% strength - REAL alpha, the app
## stays visible through it.
func _shadow_from(tex: Texture2D) -> ImageTexture:
        if _shadow_tex != null:
                return _shadow_tex
        var img: Image = tex.get_image()
        if img == null:
                return null
        if img.is_compressed():
                img.decompress()
        img.convert(Image.FORMAT_RGBA8)
        var w := img.get_width()
        var h := img.get_height()
        var pad := 6
        var sw := w + pad * 2
        var sh := h + pad * 2
        var sil := Image.create(sw, sh, false, Image.FORMAT_RGBA8)
        for y in h:
                for x in w:
                        var a := img.get_pixel(x, y).a
                        if a > 0.01:
                                sil.set_pixel(x + pad, y + pad, Color(0, 0, 0, a))
        var buf := PackedFloat32Array()
        buf.resize(sw * sh)
        for y in sh:
                for x in sw:
                        buf[y * sw + x] = sil.get_pixel(x, y).a
        for _p in 2:
                _blur(buf, sw, sh, 2, true)
                _blur(buf, sw, sh, 2, false)
        for y in sh:
                for x in sw:
                        var a2: float = buf[y * sw + x] * SHADOW_STRENGTH
                        sil.set_pixel(x, y, Color(0, 0, 0, a2))
        _shadow_tex = ImageTexture.create_from_image(sil)
        return _shadow_tex

## One separable box-blur pass over the alpha field (sliding window).
func _blur(buf: PackedFloat32Array, w: int, h: int, r: int, horiz: bool) -> void:
        var tmp := PackedFloat32Array()
        tmp.resize(buf.size())
        var span := float(r * 2 + 1)
        if horiz:
                for y in h:
                        var acc := 0.0
                        for i in range(-r, r + 1):
                                acc += buf[y * w + clampi(i, 0, w - 1)]
                        for x in w:
                                tmp[y * w + x] = acc / span
                                acc += buf[y * w + clampi(x + r + 1, 0, w - 1)] \
                                                - buf[y * w + clampi(x - r, 0, w - 1)]
        else:
                for x in w:
                        var acc := 0.0
                        for i in range(-r, r + 1):
                                acc += buf[clampi(i, 0, h - 1) * w + x]
                        for y in h:
                                tmp[y * w + x] = acc / span
                                acc += buf[clampi(y + r + 1, 0, h - 1) * w + x] \
                                                - buf[clampi(y - r, 0, h - 1) * w + x]
        for i in buf.size():
                buf[i] = tmp[i]
