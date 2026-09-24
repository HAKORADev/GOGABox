extends RefCounted
class_name LanProfile
## GOGAPROFILE — the local player profile (v042, the platform seed; v042-1
## THE PFP MEDIA LAW).
##
## One profile per device, GitHub-shaped: name, FACE (the drawn one-guy OR
## local media), description, links, age, gender. NO username, NO database —
## the name is the identity (THE NAME LAW: EN letters only, no emoji, max
## 20). The role field survives the protocol (the future dev identities);
## the profile SHEET no longer offers it (the owner: "remove the roles
## thing, it is useless").
##
## THE FACE LAW (v042-1, the owner: "i want place holders to be only one
## which is yellow guy-icon in brown background following the theme"):
##   - the PLACEHOLDER is ONE face — the yellow one-guy on the brown plate
##     (the GogaPfp renderer paints it; variant 0);
##   - the face can be LOCAL MEDIA: any image the engine decodes
##     (png/jpg/webp/bmp/tga), an animated GIF (the box's own decoder), or
##     Theora video (.ogv) — up to 60 seconds, compressed to 720p on import,
##     refused honestly otherwise (mp4/webm have no engine decoder);
##   - the media lives in THE CACHE LAW: content hash (SHA-256) named
##     entries under user://pfp_cache/, kept up to 30 days, unused entries
##     swept at boot, the CURRENT face pinned;
##   - the profile JSON carries ONLY the hash + meta (w/h/fps/n/dur/ext) —
##     the media file is fetched from the cache, or from the OWNING device
##     over the session wire when visiting (hash-addressed, so a changed
##     face busts every cache for free).
##
## THE LOCAL-TRUTH LAW: the profile carries the device anchor
## (hash(OS.get_unique_id() + salt)) — the multi-billion-dollar move that
## makes casual manipulation detectable: sessions broadcast a short anchor
## hash and a cloned profile shows up as a GHOST (two seats, one anchor).
##
## THE SURVIVAL LAW: the profile NEVER dies with the app. Three copies:
##   1. user://goga_profile.json (the box's own home),
##   2. Android: /storage/emulated/0/Android/media/<package>/ — the public
##      per-package media dir is writable without permissions and SURVIVES
##      uninstall and data-clear,
##   3. Windows: %USERPROFILE%/GOGABox/profile/ — survives uninstall.
## The NEWEST copy wins (saved_ts inside); every save re-mirrors; a wiped
## app re-adopts its own mirror on first boot. The CURRENT face's media
## file mirrors beside the JSON (the face survives too).

const PROFILE_PATH := "user://goga_profile.json"
const ANDROID_MEDIA_DIR := "/storage/emulated/0/Android/media/hakora.dev.gogabox/goga_profile"
const WINDOWS_HOME_DIR := "GOGABox/profile"
const ANCHOR_SALT := "gogabox-profile-anchor-v1"
const NAME_MAX := 20
const NAME_MIN := 2
const PFP_VARIANTS := 8
const LINKS_MAX := 3
const DESC_MAX := 140

## THE PFP MEDIA BUDGET (v042-1)
const MEDIA_MAX_SECS := 60.0        # videos/GIFs up to 1 minute
const MEDIA_720 := 720              # the long-side cap (the compress law)
const MEDIA_GIF_720 := 480          # GIFs decode in GDScript - a smaller cap
const MEDIA_GIF_MAX_FRAMES := 150
const MEDIA_FILE_MAX := 16 * 1024 * 1024   # the import file cap (16MB)
const MEDIA_WIRE_MAX := 2 * 1024 * 1024    # the visitor transfer cap
const CACHE_DAYS := 30              # the cache's age law

const GENDERS := ["male", "female", "other"]

# The one-guy tints (the drawn faces; variant 0 = THE placeholder guy).
const PFP_TINTS := [
        Color("c96f4a"), Color("4a7ac9"), Color("4ac96f"), Color("b04ac9"),
        Color("c9b04a"), Color("4ac9c0"), Color("c94a7a"), Color("8a9aa8"),
]

static var _cache: Dictionary = {}
static var _loaded := false

## ---------- the store ----------

static func data() -> Dictionary:
        if not _loaded:
                _load()
        return _cache

static func _load() -> void:
        _loaded = true
        var best := {}
        var best_ts := -1.0
        for path in _all_paths():
                var d := _read_json(path)
                if d.is_empty():
                        continue
                var ts := float(d.get("saved_ts", 0.0))
                if ts > best_ts:
                        best_ts = ts
                        best = d
        var merged := _defaults()
        if not best.is_empty():
                merged.merge(best, true)   # the saved truth wins over the defaults
        # THE ANCHOR LAW: the device always stamps its own anchor.
        merged["anchor"] = anchor()
        _cache = merged
        if float(_cache.get("saved_ts", 0.0)) <= 0.0:
                save()

static func _defaults() -> Dictionary:
        return {
                "name": "",
                "pfp": 0,
                "pfp_media": {},        # v042-1: {} = the drawn guy is the face
                "desc": "",
                "links": [],
                "age": 0,
                "role": "gamer",
                "gender": "other",
                "anchor": "",
                "saved_ts": 0.0,
        }

static func save() -> void:
        _cache["saved_ts"] = Time.get_unix_time_from_system()
        _cache["anchor"] = anchor()
        var body := JSON.stringify(_cache)
        for path in _all_paths():
                var dir: String = String(path).get_base_dir()
                if not dir.begins_with("user://"):
                        DirAccess.make_dir_recursive_absolute(dir)
                var f := FileAccess.open(path, FileAccess.WRITE)
                if f != null:
                        f.store_string(body)
                        f.close()
        _mirror_face()

## The current face's media file mirrors beside the profile JSON (THE
## SURVIVAL LAW covers the face too). The hash stays the key.
static func _mirror_face() -> void:
        var meta := face_media()
        if meta.is_empty():
                return
        var src := media_path(String(meta.get("h", "")), String(meta.get("ext", "")))
        if not FileAccess.file_exists(src):
                return
        for path in _all_paths():
                var dir := String(path).get_base_dir()
                if dir.begins_with("user://"):
                        continue
                var dst := dir.path_join("face_" + String(meta.get("h", "")) \
                                + "." + String(meta.get("ext", "")))
                DirAccess.make_dir_recursive_absolute(dir)
                if FileAccess.file_exists(dst):
                        continue
                var rd := FileAccess.open(src, FileAccess.READ)
                var wr := FileAccess.open(dst, FileAccess.WRITE)
                if rd != null and wr != null:
                        wr.store_buffer(rd.get_buffer(rd.get_length()))
                if rd != null:
                        rd.close()
                if wr != null:
                        wr.close()

static func _all_paths() -> Array:
        var paths := [PROFILE_PATH]
        if OS.get_name() == "Android":
                paths.append(ANDROID_MEDIA_DIR + "/goga_profile.json")
        elif OS.get_name() == "Windows":
                var home := OS.get_environment("USERPROFILE")
                if home != "":
                        paths.append(home.path_join(WINDOWS_HOME_DIR + "/goga_profile.json"))
        return paths

static func _read_json(path: String) -> Dictionary:
        var f := FileAccess.open(path, FileAccess.READ)
        if f == null:
                return {}
        var parsed: Variant = JSON.parse_string(f.get_as_text())
        f.close()
        if typeof(parsed) != TYPE_DICTIONARY:
                return {}
        return parsed

## ---------- the fields ----------

static func player_name() -> String:
        return String(data().get("name", ""))

static func set_player_name(v: String) -> void:
        var sn := sanitize_name(v)
        data()["name"] = sn

static func pfp() -> int:
        return clampi(int(data().get("pfp", 0)), 0, PFP_VARIANTS - 1)

static func set_pfp(v: int) -> void:
        data()["pfp"] = clampi(v, 0, PFP_VARIANTS - 1)

## THE FACE (v042-1): the media meta when the face is local media, else {}.
## {h, ext, w, h, fps, n, dur, bytes}
static func face_media() -> Dictionary:
        var m: Variant = data().get("pfp_media", {})
        return m if typeof(m) == TYPE_DICTIONARY else {}

static func set_face_media(meta: Dictionary) -> void:
        data()["pfp_media"] = meta
        if not meta.is_empty():
                # the media face replaces the drawn one as the live face
                data()["pfp"] = 0
        save()

static func clear_face_media() -> void:
        data()["pfp_media"] = {}
        save()

static func role() -> String:
        return String(data().get("role", "gamer"))

static func gender() -> String:
        return String(data().get("gender", "other"))

static func desc() -> String:
        return String(data().get("desc", ""))

static func links() -> Array:
        return data().get("links", [])

static func age() -> int:
        return int(data().get("age", 0))

## THE AGE DISPLAY LAW (v042-1): specific numbers from the select menu,
## anything over 21 visualizes "21+", max 3 chars in the store.
const AGE_CAP := 21

static func age_display(v: int) -> String:
        if v <= 0:
                return ""
        return "21+" if v > AGE_CAP else str(v)

## THE ROLE LAW: owner is unique — first device to claim keeps it.
## (the sheet seat retired v042-1; the field stays for the dev identities)
static func owner_claim() -> String:
        return String(data().get("owner_claim", ""))

static func try_claim_owner() -> bool:
        if role() == "owner":
                return true
        var claim := owner_claim()
        if claim != "" and claim != anchor():
                return false
        data()["owner_claim"] = anchor()
        data()["role"] = "owner"
        save()
        return true

static func release_owner() -> void:
        if role() == "owner" and owner_claim() == anchor():
                data()["role"] = "gamer"
                data()["owner_claim"] = ""
                save()

## ---------- the anchor (the device's special ID) ----------

static func anchor() -> String:
        return str(hash(ANCHOR_SALT + OS.get_unique_id()))

static func anchor_short() -> String:
        var a := anchor()
        return a.substr(a.length() - 6, 6) if a.length() >= 6 else a

## ---------- THE NAME LAW ----------

## EN Unicode letters only + space + ' . - ; NO emoji, NO digits, max 20.
static func sanitize_name(raw: String) -> String:
        var out := ""
        for ch in raw:
                if (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") \
                                or ch == " " or ch == "'" or ch == "." or ch == "-":
                        out += ch
        # collapse spaces, trim
        var parts := out.split(" ", false)
        out = " ".join(parts)
        out = out.strip_edges()
        if out.length() > NAME_MAX:
                out = out.substr(0, NAME_MAX).strip_edges()
        return out

static func name_ok(raw: String) -> bool:
        var s := sanitize_name(raw)
        return s.length() >= NAME_MIN

## ---------- THE CHAT SANITIZER (v042-1, the CHAT LAW) ----------
## English-only, no emojis, no control chars. One truth for the sender AND
## the receiver (never trust a peer's bytes).

static func sanitize_chat(raw: String) -> String:
        var out := ""
        for ch in raw:
                var o := ch.unicode_at(0)
                if o == 9 or (o >= 32 and o <= 126):
                        out += ch
        out = out.replace("\t", " ")
        if out.length() > 1000:
                out = out.substr(0, 1000)
        return out.strip_edges()

## ---------- THE CACHE (v042-1, THE CACHE LAW) ----------

const CACHE_DIR := "user://pfp_cache"

static func media_path(hash_v: String, ext: String) -> String:
        return "%s/%s.%s" % [CACHE_DIR, hash_v, ext]

static func media_meta_path(hash_v: String) -> String:
        return "%s/%s.json" % [CACHE_DIR, hash_v]

## Store an imported/wire face into the cache (the meta + the media bytes).
static func cache_store(hash_v: String, ext: String, bytes: PackedByteArray,
                meta: Dictionary) -> void:
        DirAccess.make_dir_recursive_absolute(CACHE_DIR)
        var f := FileAccess.open(media_path(hash_v, ext), FileAccess.WRITE)
        if f != null:
                f.store_buffer(bytes)
                f.close()
        var mf := FileAccess.open(media_meta_path(hash_v), FileAccess.WRITE)
        if mf != null:
                mf.store_string(JSON.stringify(meta))
                mf.close()

static func cache_meta(hash_v: String) -> Dictionary:
        var f := FileAccess.open(media_meta_path(hash_v), FileAccess.READ)
        if f == null:
                return {}
        var parsed: Variant = JSON.parse_string(f.get_as_text())
        f.close()
        return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

## The 30-day sweep: cache entries untouched for CACHE_DAYS die; the live
## face is pinned. Runs at boot (the renderer calls this once).
static func cache_sweep() -> void:
        var live := String(face_media().get("h", ""))
        var d := DirAccess.open(CACHE_DIR)
        if d == null:
                return
        var now := Time.get_unix_time_from_system()
        var horizon := float(CACHE_DAYS * 24 * 3600)
        for name in d.get_files():
                var path := CACHE_DIR + "/" + String(name)
                var key := String(name).get_basename()
                if key == live:
                        continue
                var old := FileAccess.get_modified_time(path)
                if float(old) > 0.0 and float(now) - float(old) > horizon:
                        DirAccess.remove_absolute(path)

## Does the local cache hold this face's media?
static func cache_has(hash_v: String) -> bool:
        var meta := cache_meta(hash_v)
        if meta.is_empty():
                return false
        return FileAccess.file_exists(media_path(hash_v,
                        String(meta.get("ext", "webp"))))

## ---------- the drawn one-guy (THE PFP LAW) ----------
## Painted through a Control's draw signal; ONE implementation serves the
## hold screen, the lobby rows, the profile sheet and the game HUD tags.
## GogaPfp (goga_pfp.gd) is the front door now - it paints the placeholder
## plate, the drawn variants, and the media faces through this.

static func paint_pfp(canvas: Control, variant: int, center: Vector2, height: float,
                tint_override := Color(0, 0, 0, 0)) -> void:
        var tint: Color = PFP_TINTS[clampi(variant, 0, PFP_VARIANTS - 1)]
        if tint_override.a > 0.0:
                tint = tint_override
        var dark := tint.darkened(0.35)
        var skin := Color("e8c39a")
        var u := height / 10.0   # the unit
        var x := center.x
        var y := center.y
        var line := maxf(1.5, u * 0.22)
        # legs
        canvas.draw_line(Vector2(x - u * 0.9, y + u * 2.6), Vector2(x - u * 0.9, y + u * 5.0), dark, line * 1.6)
        canvas.draw_line(Vector2(x + u * 0.9, y + u * 2.6), Vector2(x + u * 0.9, y + u * 5.0), dark, line * 1.6)
        # body
        var body := Rect2(x - u * 1.6, y + u * 0.2, u * 3.2, u * 2.6)
        Arc.safe_poly(canvas, _round_rect_pts(body, u * 0.8), tint)
        # arms
        canvas.draw_line(Vector2(x - u * 1.6, y + u * 0.8), Vector2(x - u * 2.7, y + u * 1.8), tint, line * 1.5)
        canvas.draw_line(Vector2(x + u * 1.6, y + u * 0.8), Vector2(x + u * 2.7, y + u * 1.8), tint, line * 1.5)
        # head
        canvas.draw_circle(Vector2(x, y - u * 1.1), u * 1.15, skin)
        # the variant's cap (the only per-variant face difference)
        if variant % 2 == 1:
                var cap := Rect2(x - u * 1.25, y - u * 2.35, u * 2.5, u * 0.55)
                Arc.safe_poly(canvas, _round_rect_pts(cap, u * 0.25), dark)
        elif variant % 4 >= 2:
                canvas.draw_circle(Vector2(x, y - u * 1.75), u * 1.05, dark)

static func _round_rect_pts(r: Rect2, rad: float) -> PackedVector2Array:
        var pts := PackedVector2Array()
        var steps := 4
        var corners := [
                [Vector2(r.position.x + r.size.x - rad, r.position.y + rad), 0.0],
                [Vector2(r.position.x + r.size.x - rad, r.position.y + r.size.y - rad), 90.0],
                [Vector2(r.position.x + rad, r.position.y + r.size.y - rad), 180.0],
                [Vector2(r.position.x + rad, r.position.y + rad), 270.0],
        ]
        for c in corners:
                for i in steps + 1:
                        var a := deg_to_rad(c[1] + 90.0 * float(i) / float(steps))
                        pts.append(c[0] + Vector2(cos(a), sin(a)) * rad)
        return pts
