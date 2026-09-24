extends RefCounted
class_name PfpMedia
## THE PFP MEDIA PIPELINE (v042-1) - import, cache, and meta for the
## profile's media faces. THE HONEST BAR: refuse what cannot truly play.
##
##   IMAGES  png / jpg / jpeg / webp / bmp / tga  - the engine's runtime
##           ImageLoader set ("all image formats, even webp")
##   ANIMATED GIF - the box's own decoder (PfpGif), PFP-budgeted
##   VIDEO   .ogv (Theora) - the engine's ONLY runtime streamer; mp4/webm
##           are H.264/VP8 and are refused with a clear toast (no decoder
##           ships in Godot - a fake would be a dummy build)
##
## THE IMPORT LAWS: the media is compressed to a 720 long side (images),
## GIFs to the PFP budget (480 / 150 frames), anything over 16MB or beyond
## the 60-second shape is refused; the entry is stored under its SHA-256
## content hash - "cached with a hash so when changed, the cache knows it
## is different".

const IMG_EXTS := ["png", "jpg", "jpeg", "webp", "bmp", "tga"]
const GIF_EXTS := ["gif"]
const OGV_EXTS := ["ogv"]

## Import a picked file -> face meta {h, ext, w, h, fps, n, dur, bytes}
## or {err: "..."} (the caller toasts the err).
static func import_file(path: String) -> Dictionary:
        if not FileAccess.file_exists(path):
                return {"err": "the file is not there"}
        var ext := path.get_extension().to_lower()
        var f := FileAccess.open(path, FileAccess.READ)
        if f == null:
                return {"err": "cannot read the file"}
        var bytes := f.get_buffer(f.get_length())
        f.close()
        if bytes.size() > LanProfile.MEDIA_FILE_MAX:
                return {"err": "too big - the cap is 16 MB"}
        var hash_v := FileAccess.get_sha256(path)
        if hash_v == "":
                hash_v = str(hash(bytes)).sha1_text()   # honest fallback
        if ext in IMG_EXTS:
                return _import_image(hash_v, ext, bytes)
        if ext in GIF_EXTS:
                return _import_gif(hash_v, bytes)
        if ext in OGV_EXTS:
                return _import_ogv(hash_v, bytes)
        return {"err": "%s is not a face - use png/jpg/webp/gif/ogv" % ext}

static func _import_image(hash_v: String, ext: String, bytes: PackedByteArray) -> Dictionary:
        var img := Image.new()
        var err := img.load_webp_from_buffer(bytes) if ext == "webp" \
                        else _load_any(img, bytes, ext)
        if err != OK or img.is_empty():
                return {"err": "the image cannot be read"}
        img.convert(Image.FORMAT_RGBA8)
        var meta := {"h": hash_v, "ext": "webp", "n": 1, "fps": 0.0,
                "dur": 0.0, "bytes": 0}
        var res := _fit_720(img, LanProfile.MEDIA_720)
        meta["w"] = res.x
        meta["h"] = res.y
        var out := img.save_webp_to_buffer(true, 0.86)
        if out.is_empty():
                return {"err": "the image cannot be stored"}
        meta["bytes"] = out.size()
        LanProfile.cache_store(hash_v, "webp", out, meta)
        return meta

## The honest loader for the formats Image.new().load_* does not cover.
static func _load_any(img: Image, bytes: PackedByteArray, ext: String) -> int:
        # jpg/bmp/tga/pnm ride the buffer loaders the engine ships
        if ext in ["jpg", "jpeg"]:
                return img.load_jpg_from_buffer(bytes)
        if ext == "bmp":
                return img.load_bmp_from_buffer(bytes)
        if ext == "tga":
                return img.load_tga_from_buffer(bytes)
        return img.load_png_from_buffer(bytes)

static func _import_gif(hash_v: String, bytes: PackedByteArray) -> Dictionary:
        var dec := PfpGif.decode(bytes, LanProfile.MEDIA_GIF_720,
                        LanProfile.MEDIA_GIF_MAX_FRAMES)
        if dec.has("err"):
                return {"err": String(dec["err"])}
        var frames: Array = dec["frames"]
        var delays: Array = dec["delays_ms"]
        var total_ms := 0
        for d in delays:
                total_ms += int(d)
        var meta := {"h": hash_v, "ext": "gif", "n": frames.size(),
                "fps": float(frames.size()) / maxf(0.1, float(total_ms) / 1000.0),
                "dur": float(total_ms) / 1000.0, "bytes": bytes.size()}
        if meta["dur"] > LanProfile.MEDIA_MAX_SECS:
                return {"err": "over the 1 minute cap"}
        var sz := Vector2i(frames[0].get_width(), frames[0].get_height())
        meta["w"] = sz.x
        meta["hh"] = sz.y
        LanProfile.cache_store(hash_v, "gif", bytes, meta)
        return meta

static func _import_ogv(hash_v: String, bytes: PackedByteArray) -> Dictionary:
        # the engine streams Theora only; duration is measured at render
        # (the renderer caps playback at the 60s law regardless)
        var meta := {"h": hash_v, "ext": "ogv", "n": 0, "fps": 0.0,
                "dur": -1.0, "bytes": bytes.size(), "w": 0, "hh": 0}
        LanProfile.cache_store(hash_v, "ogv", bytes, meta)
        return meta

## Fit an image under the 720 law (the long side), never upscale.
static func _fit_720(img: Image, cap: int) -> Vector2i:
        var w := img.get_width()
        var h := img.get_height()
        var long_side := maxi(w, h)
        if long_side > cap:
                var k := float(cap) / float(long_side)
                w = maxi(1, int(w * k))
                h = maxi(1, int(h * k))
                img.resize(w, h, Image.INTERPOLATE_LANCZOS)
        return Vector2i(w, h)
