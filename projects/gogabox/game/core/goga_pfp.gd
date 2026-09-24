extends Control
class_name GogaPfp
## THE ONE FACE (v042-1) - the profile's PFP renderer. ONE class paints
## EVERY seat: the profile sheet's big face, the lobby rows, the hold
## screen, the member rows, the chat labels, the roster.
##
## THE PLACEHOLDER LAW: with no media, the face is the YELLOW one-guy on
## the BROWN plate (the owner: "i want place holders to be only one which
## is yellow guy-icon in brown background following the theme").
##
## THE FOCUS LAW (the owner: "videos/GIFs be running normally and when
## un-focused or away, like the very tiny out of in-game and like that, it
## shows one frame only"): a GogaPfp with `focused = false` paints ONE
## frame (the poster); `focused = true` (the profile sheet's big face) runs
## the animation at the media's own fps. The renderer also pauses itself
## when it leaves the tree or the menu is unfocused.
##
## THE SIZE LAW: the media texture is drawn KEEP-ASPECT-COVERED inside the
## plate at ANY size - one renderer, accurate at every seat, no stretching
## mistakes anywhere.

const PLATE_BROWN := Color("6b4423")
const PLATE_BROWN_DARK := Color("4a2e14")
const GUY_YELLOW := Color("ffc93c")

## the decoded-media registry: hash -> {tex: [Texture2D], fps, n, dur, poster: Texture2D}
static var _decoded := {}
static var _swept := false

var variant := 0                 # the drawn one-guy variant (the fallback)
var media := {}                  # the face meta {h, ext, fps, n, dur, w, h}
var focused := false             # true = animate (the big profile face)
var plate := true                # paint the brown plate behind the face

var _frame := 0.0
var _video: VideoStreamPlayer = null
var _poster: ImageTexture = null
var _poster_tried := false

static func make(p_face: Dictionary, p_size: Vector2, p_focused := false) -> GogaPfp:
        var g := GogaPfp.new()
        g.media = p_face
        g.focused = p_focused
        g.custom_minimum_size = p_size
        return g

## The face meta for a SEAT dict (the wire's pfpm) or the local profile.
static func face_of_seat(seat: Dictionary) -> Dictionary:
        var m: Variant = seat.get("pfpm", {})
        return m if typeof(m) == TYPE_DICTIONARY else {}

func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        if not _swept:
                _swept = true
                LanProfile.cache_sweep()
        if not media.is_empty() and String(media.get("ext", "")) == "ogv":
                _mount_video()

func _mount_video() -> void:
        var hash_v := String(media.get("h", ""))
        var path := LanProfile.media_path(hash_v, "ogv")
        if not FileAccess.file_exists(path):
                return
        var vs := VideoStreamTheora.new()
        vs.file = path
        _video = VideoStreamPlayer.new()
        _video.stream = vs
        _video.expand = true
        _video.loop = true
        _video.visible = false
        _video.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(_video)

func _process(delta: float) -> void:
        if media.is_empty():
                return
        var ext := String(media.get("ext", ""))
        var n := int(media.get("n", 1))
        if ext == "gif" and n > 1 and focused and is_visible_in_tree():
                _frame = fmod(_frame + float(n) * float(media.get("fps", 8.0)) * delta,
                                float(n))
        elif ext == "ogv" and _video != null:
                if focused and is_visible_in_tree():
                    if not _video.is_playing():
                            _video.play()
                    # THE POSTER HARVEST: one 0.2s play grabs the first frame
                    if not _poster_tried and _video.is_playing():
                            _poster_tried = true
                            var t := get_tree().create_timer(0.2)
                            t.timeout.connect(func():
                                    if is_instance_valid(_video) \
                                                    and _video.get_texture() != null:
                                            _poster = _video.get_texture().get_image() \
                                                            .duplicate()
                                            if is_instance_valid(self):
                                                    queue_redraw())
                else:
                    if _video.is_playing():
                            _video.stop()
        queue_redraw()

func _draw() -> void:
        var sz := size
        if sz.x <= 0.0 or sz.y <= 0.0:
                sz = custom_minimum_size
        var r := Rect2(Vector2.ZERO, sz)
        if plate:
                draw_rect(r, PLATE_BROWN)
                # the plate's inner shade (the theme's own depth)
                draw_rect(Rect2(r.position + Vector2(4, 4),
                                r.size - Vector2(8, 8)), PLATE_BROWN_DARK, false,
                                maxf(2.0, sz.y * 0.02))
        var hash_v := String(media.get("h", ""))
        var ext := String(media.get("ext", ""))
        if media.is_empty() or hash_v == "" or not LanProfile.cache_has(hash_v):
                # THE PLACEHOLDER LAW (the owner: "place holders to be only
                # one which is yellow guy-icon in brown background following
                # the theme"): the ONE yellow one-guy, painted big
                LanProfile.paint_pfp(self, variant,
                                Vector2(sz.x * 0.5, sz.y * 0.5), sz.y * 0.94,
                                GUY_YELLOW)
                return
        if ext == "gif" and int(media.get("n", 1)) > 1:
                var dec := _ensure_gif(hash_v)
                if dec.is_empty():
                        LanProfile.paint_pfp(self, variant,
                                        Vector2(sz.x * 0.5, sz.y * 0.5), sz.y * 0.94)
                        return
                var texs: Array = dec["tex"]
                var idx := int(_frame) % texs.size() if focused else 0
                _draw_cover(texs[idx], r)
        elif ext == "ogv":
                if _video != null and _video.get_texture() != null:
                        _draw_cover(_video.get_texture(), r)
                elif _poster != null:
                        _draw_cover(_poster, r)
                else:
                        LanProfile.paint_pfp(self, variant,
                                        Vector2(sz.x * 0.5, sz.y * 0.5), sz.y * 0.94)
        else:
                var tex := _static_tex(hash_v, ext)
                if tex == null:
                        LanProfile.paint_pfp(self, variant,
                                        Vector2(sz.x * 0.5, sz.y * 0.5), sz.y * 0.94)
                        return
                _draw_cover(tex, r)

## KEEP-ASPECT-COVERED: the art fills the plate, centered, never stretched.
func _draw_cover(tex: Texture2D, r: Rect2) -> void:
        var ts := tex.get_size()
        if ts.x <= 0.0 or ts.y <= 0.0:
                return
        var k := maxf(r.size.x / ts.x, r.size.y / ts.y)
        var ds := ts * k
        var dp := r.position + (r.size - ds) * 0.5
        draw_texture_rect(tex, Rect2(dp, ds), false)

## The GIF decode runs ONCE per hash (the render cache).
func _ensure_gif(hash_v: String) -> Dictionary:
        if _decoded.has(hash_v):
                return _decoded[hash_v]
        var f := FileAccess.open(LanProfile.media_path(hash_v, "gif"), FileAccess.READ)
        if f == null:
                return {}
        var bytes := f.get_buffer(f.get_length())
        f.close()
        var dec := PfpGif.decode(bytes)
        if dec.has("err"):
                return {}
        var texs := []
        for img in dec["frames"]:
                texs.append(ImageTexture.create_from_image(img))
        var out := {"tex": texs, "fps": float(_media_fps(hash_v))}
        _decoded[hash_v] = out
        return out

func _media_fps(hash_v: String) -> float:
        var m := LanProfile.cache_meta(hash_v)
        return float(m.get("fps", 8.0)) if not m.is_empty() \
                        else float(media.get("fps", 8.0))

func _static_tex(hash_v: String, ext: String) -> Texture2D:
        var key := hash_v + "." + ext
        if _decoded.has(key):
                return _decoded[key]["tex"][0]
        var f := FileAccess.open(LanProfile.media_path(hash_v, ext), FileAccess.READ)
        if f == null:
                return null
        var bytes := f.get_buffer(f.get_length())
        f.close()
        var img := Image.new()
        var err := img.load_webp_from_buffer(bytes) if ext == "webp" \
                        else img.load_png_from_buffer(bytes)
        if err != OK or img.is_empty():
                return null
        var tex := ImageTexture.create_from_image(img)
        _decoded[key] = {"tex": [tex]}
        return tex
