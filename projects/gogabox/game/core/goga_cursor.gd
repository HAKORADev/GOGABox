extends RefCounted
## v041-1 r4 THE HARDWARE GOGACURSOR - the owner's own 32x32 arrow drawn by
## THE OPERATING SYSTEM ITSELF (DisplayServer.cursor_set_custom_image).
##
## WHY HARDWARE (the r2/r3 lesson): the r2 software cursor lived inside the
## app's render path - a CanvasLayer sprite driven by get_final_transform().
## When the r1 attach-call disease froze the render path on the owner's
## Windows GPU, the pointer vanished WITH it ("previously i saw the cursor,
## now i do not even see it"). An OS-composited cursor cannot vanish, cannot
## lag, and is 1:1 with the OS pointer BY DEFINITION - Windows scales
## nothing, the app transforms nothing.
##
##   - THE GLYPH: assets/ui/goga_cursor.png (his .cur, converted at r2) -
##     verbatim pixels, tip at pixel (0,0) (the .cur's stored hotspot (9,9)
##     contradicts the art - an arrow aims with its tip, the way the Windows
##     arrow always has).
##   - THE SHADOW: code-built ONCE from the glyph's own alpha - two box-blur
##     passes (radius 2), black at 60% strength, offset (2,3) - the r2 spec
##     verbatim, BAKED into the cursor bitmap. Windows composites the cursor
##     through a BITMAPV5HEADER with an 8-bit alpha channel
##     (display_server_windows.cpp, CreateIconIndirect) - the shadow wears
##     REAL alpha at the OS level, never an opaque block.
##   - THE HOLD/DARKENING: a second bitmap, the glyph modulated 0.55, the
##     same shadow - swapped in while the left button is held (menu only;
##     a click never re-paints the box cursor over a game's own seat).
##   - THE OWNERSHIP LAW: the box cursor rides the ARROW shape's custom
##     image slot. A game that hides the mouse (Heavy War) hides it for the
##     OS too; when the mode returns to VISIBLE the image is still armed.
##     Games that set their own image simply replace ours; on_game_closed
##     re-arms (the same-image call short-circuits in the engine cache).
##   - 44x44 canvas (32 glyph + 6px pad each side) - CreateIconIndirect
##     takes the bitmap's own size; the classic 32x32 limit is a .cur file
##     era limit, not a CreateIcon limit.

const GLYPH_PATH := "res://assets/ui/goga_cursor.png"
const HELD_TINT := 0.55
const SHADOW_STRENGTH := 0.6
const SHADOW_OFFSET := Vector2(2, 3)
const PAD := 6

static var _arrow: ImageTexture
static var _arrow_dark: ImageTexture
static var _hotspot := Vector2.ZERO
static var _armed := false

static func _glyph_image() -> Image:
        var tex: Texture2D = load(GLYPH_PATH)
        if tex == null:
                return null
        var img: Image = tex.get_image()
        if img == null:
                return null
        if img.is_compressed():
                img.decompress()
        img.convert(Image.FORMAT_RGBA8)
        return img

## One separable box-blur pass over the alpha field (sliding window) -
## the r2 SoftCursor's own algorithm, now feeding a static bitmap.
static func _blur(buf: PackedFloat32Array, w: int, h: int, r: int, horiz: bool) -> void:
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

static func _bake(held: bool, src_img: Image = null) -> ImageTexture:
        var glyph: Image = src_img if src_img != null else _glyph_image()
        if glyph == null:
                return null
        var w := glyph.get_width()
        var h := glyph.get_height()
        var sw := w + PAD * 2
        var sh := h + PAD * 2
        # the shadow silhouette: the glyph's own alpha, blurred, black
        var buf := PackedFloat32Array()
        buf.resize(sw * sh)
        for y in h:
                for x in w:
                        var a := glyph.get_pixel(x, y).a
                        if a > 0.01:
                                buf[(y + PAD) * sw + (x + PAD)] = a
        for _p in 2:
                _blur(buf, sw, sh, 2, true)
                _blur(buf, sw, sh, 2, false)
        var out := Image.create(sw, sh, false, Image.FORMAT_RGBA8)
        var ox := PAD + int(SHADOW_OFFSET.x)
        var oy := PAD + int(SHADOW_OFFSET.y)
        # the shadow first (under), offset (2,3), 60% strength - REAL alpha
        for y in sh:
                for x in sw:
                        var a: float = buf[y * sw + x] * SHADOW_STRENGTH
                        if a > 0.003:
                                out.set_pixel(x, y, Color(0, 0, 0, a))
        # the glyph on top - darkened while held (the code darkening)
        var tint := HELD_TINT if held else 1.0
        for y in h:
                for x in w:
                        var c := glyph.get_pixel(x, y)
                        if c.a > 0.003:
                                out.set_pixel(x + PAD, y + PAD,
                                                Color(c.r * tint, c.g * tint,
                                                c.b * tint, c.a))
        return ImageTexture.create_from_image(out)

## Arm the box cursor on the ARROW shape (idempotent). Returns false when
## the glyph cannot load (the OS default arrow keeps the seat).
static func arm() -> bool:
        if _arrow == null:
                _arrow = _bake(false)
                _arrow_dark = _bake(true)
                _hotspot = Vector2(PAD, PAD)
        if _arrow == null:
                return false
        Input.set_custom_mouse_cursor(_arrow, Input.CURSOR_ARROW, _hotspot)
        _armed = true
        return true

static func set_held(held: bool) -> void:
        # v041-1 r7: the GAME seat owns the swap while it is armed - a
        # game's click cursor replaces the box darkening for the same
        # reason a game's own image replaces the box glyph (the ownership
        # law). The box seat behaves exactly as before when no game seat
        # is live.
        if _game_armed:
                if _game_click == null:
                        return
                var gtex := _game_click if held else _game_norm
                if gtex != null:
                        Input.set_custom_mouse_cursor(gtex,
                                        Input.CURSOR_ARROW, _game_hot)
                return
        if not _armed or _arrow == null:
                return
        var tex := _arrow_dark if held else _arrow
        if tex != null:
                Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, _hotspot)

## The box cursor leaves the seat (the owner turned it off, or a probe).
static func disarm() -> void:
        if not _armed:
                return
        Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
        _armed = false

static func is_armed() -> bool:
        return _armed

# ============================================ v041-1 r7 THE GAME SEAT
## THE OWNER'S ORDER (the Heavy War report): "when hovered on the shop/
## back buttons, the cursor do not be over it, movements tracked but with
## no visual cursor ... the cursor can be used here too, i mean the custom
## in-game one, also a game can make different one for clicking, i mean as
## same as it can do one for the GOGABox-related menus". Two laws fall out
## of that:
##   1. A GAME'S OWN CURSOR SEAT - a game arms its own cursor image (the
##      aim reticle) and a second CLICK image (same capability the box
##      menus have with their held darkening). The images ride the same
##      HARDWARE road as the box cursor (r4's lesson): the OS composites
##      the cursor ABOVE EVERYTHING - HUD buttons, sheets, the whole GUI.
##      An in-world drawn sprite can be painted over by any Control; a
##      hardware cursor cannot be covered by construction. THE VISIBILITY
##      BUG'S ROOT: Heavy War drew its reticle through hud_draw, which
##      joins the overlay root BEFORE the top bar - the SHOP/back buttons
##      painted over it, movements tracked, visual gone.
##   2. THE OWNERSHIP LAW EXTENDED - while a game seat is armed, the box
##      cursor machinery (arm/set_held/disarm) never touches the ARROW
##      shape; on_game_closed re-arms the box cursor (main.gd already
##      calls _apply_gogacursor on the way out).
static var _game_norm: Texture2D = null
static var _game_click: Texture2D = null
static var _game_hot := Vector2.ZERO
static var _game_armed := false
# v041-2 r3 THE SEAT TOKEN LAW (the owner: the r2 leak fix "silently kills
# custom cursor and turns it off but in settings it is still recognized as
# on, even if i replayed, it will not reload the game cursor, if i exited,
# i see system cursor and not GOGACursor"). THE ROOT: queue_free is
# DEFERRED - the dying game's _exit_tree fired AFTER the next seat was
# armed (the replayed game's seat, or the box cursor's re-arm on the
# game-closed road), and r2's unconditional game_disarm() nulled the
# ARROW shape at that moment: the freshly armed seat died with it, every
# custom cursor was gone (the OS arrow showed) while the SETTING stayed
# honestly ON. THE LAW NOW: every game_arm mints a seat TOKEN; only the
# seat that holds the LIVE token may disarm. A dying game with a stale
# token is a no-op - the replayed game's seat, the box arrow, EVERY live
# seat survives the deferred corpse. And when the LIVE game seat does
# leave, it hands the pointer straight back to the box seat (never a
# dead-cursor frame in between).
static var _seat_token := 0

## Arm the game seat: `normal` is the everyday cursor, `click` (optional)
## swaps in while the LEFT button is held. Hotspot is inside the image.
## Idempotent - re-arming with the same images short-circuits in the
## engine cache. Headless (probes/CI): a no-op, reports false.
## Returns the seat TOKEN - keep it; it is the only key that disarms.
static func game_arm(normal: Texture2D, click: Texture2D = null,
                hotspot := Vector2.ZERO) -> int:
        if normal == null or DisplayServer.get_name() == "headless":
                return -1
        _game_norm = normal
        _game_click = click
        _game_hot = hotspot
        _game_armed = true
        _seat_token += 1
        Input.set_custom_mouse_cursor(normal, Input.CURSOR_ARROW, hotspot)
        return _seat_token

## The LIVE game seat leaves the pointer: the box seat returns the same
## frame (the owner's own cursor when the setting says ON, the honest OS
## arrow when it says OFF). A STALE token (a queued-free game whose seat
## was already replaced) does NOTHING - the live seat is untouchable.
static func game_disarm(token: int = -1) -> void:
        if token != -1 and token != _seat_token:
                return   # a corpse's seat - the live seat owns the pointer
        if not _game_armed:
                return
        _game_armed = false
        _game_norm = null
        _game_click = null
        _seat_token += 1   # the token dies with the seat
        # THE HAND-BACK: the box seat is wanted whenever the setting says
        # so - arm it HERE (a game quit then never shows the OS arrow for
        # even one frame, and the game-closed re-arm below becomes a
        # harmless re-assert). OFF: the honest OS arrow.
        if Box.has_method("pc_gogacursor") and Box.pc_gogacursor() \
                        and _arrow != null:
                Input.set_custom_mouse_cursor(_arrow, Input.CURSOR_ARROW,
                                _hotspot)
                _armed = true
        else:
                Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
                _armed = false

static func is_game_armed() -> bool:
        return _game_armed
