extends RefCounted
class_name LanProfile
## GOGAPROFILE — the local player profile (v042, the platform seed).
##
## One profile per device, GitHub-shaped: name, PFP (the drawn one-guy),
## description, links, age, role, gender. NO username, NO database — the
## name is the identity (THE NAME LAW: EN letters only, no emoji, max 20).
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
## app re-adopts its own mirror on first boot.

const PROFILE_PATH := "user://goga_profile.json"
const ANDROID_MEDIA_DIR := "/storage/emulated/0/Android/media/hakora.dev.gogabox/goga_profile"
const WINDOWS_HOME_DIR := "GOGABox/profile"
const ANCHOR_SALT := "gogabox-profile-anchor-v1"
const NAME_MAX := 20
const NAME_MIN := 2
const PFP_VARIANTS := 8
const LINKS_MAX := 3
const DESC_MAX := 140

const ROLES := ["gamer", "developer", "owner"]
const GENDERS := ["male", "female", "other"]

# The one-guy tints (the PFP LAW: simple drawn one guy, variants only).
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

## THE ROLE LAW: owner is unique — first device to claim keeps it.
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

## ---------- the drawn one-guy (THE PFP LAW) ----------
## Painted through a Control's draw signal; ONE implementation serves the
## hold screen, the lobby rows, the profile sheet and the game HUD tags.

static func paint_pfp(canvas: Control, variant: int, center: Vector2, height: float) -> void:
	var tint: Color = PFP_TINTS[clampi(variant, 0, PFP_VARIANTS - 1)]
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

## A small Control that paints one guy (drop-in for rows and sheets).
static func pfp_control(variant: int, size_v: Vector2) -> Control:
	var c := Control.new()
	c.custom_minimum_size = size_v
	c.draw.connect(func():
		paint_pfp(c, variant, Vector2(size_v.x * 0.5, size_v.y * 0.32), size_v.y * 0.62)
	)
	return c
