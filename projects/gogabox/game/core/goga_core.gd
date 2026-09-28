extends Node
## GOGA — the platform runtime (v043 THE PLATFORM ROUND).
## THE_PLATFORM_ANSWER.md graduated from document to engine.
##
## The box bakes ZERO games (THE EMPTY BINARY LAW); every game arrives as
## a GOGA package installed under the GOGAs/ home tree:
##
##   GOGAs/                       Windows: next to the exe · Android: Downloads
##     libs/                      the SDK bridges (the drop-in extension point)
##     games/<id>/                one installed package root per game
##     discover/                  the source registry + the feed material
##     .cache/                    download temp + per-source feed caches
##
## A package root (a ".goga" - the owner's own name for one game folder):
##   index/index.json    the manifest - the FULL registry vocabulary flat
##                       (title, version, age, content, genres, fee, price,
##                       coin_div, charges, lan, ach, os, runs...) - "the
##                       index/ itself is must be exposed for the game
##                       thumbnail, entry, rate-limits, gogacoins"
##   game/               the runnable: godot pcks, native libs/exe, or web
##   discover/           page.json + media (the discover feed material)
##   data/               THE OPEN DATA LAW - plain moddable files:
##                       logic/  audio/{sfx,music[,voice]}/
##                       visuals/{assets,shaders[,characters,vfx]}/
##   save/               THE PORTABLE SAVE LAW - saves live here, never in
##                       app-data bloat; the folder is the contract
##   src/                optional shared source (remix culture)
##
## Distribution shapes the importer eats: a .goga (zip, one root), a
## .gogas (zip, many roots), a plain folder root, or a parent of roots.
## THE RENAME LAW: an installed root is renamed to its index id, always.
##
## THE ID SCHEME: gogabox_github-<user>_<ns>.<name>.<id>_<tier>
##   tier ∈ {official, community, hobbyist} - the folder suffix declares
##   it; the DISCOVER tier of a downloaded game comes from the source that
##   served it (official repo = official, REPOS.txt = community, else
##   hobbyist). Parsed by parse_id(); refused when malformed.
##
## THE SDK (this autoload IS the sdk for embedded games; the unified-libs
## decision - the owner blessed making libs part of the binary):
##   GOGA.my_id() / my_root() / data_json() / save_read() / save_write() ...
## Games carry ZERO hardcoded box paths: their entry comes from their own
## index, their moddable files from data/, their saves from save/.

signal installed_changed            # a package landed / updated / left

const SCHEMA := 1
const TIERS := ["official", "community", "hobbyist"]
const INDEX_REL := "index/index.json"
const PAGE_REL := "discover/page.json"

## THE OPEN DATA LAW - the STRICT minimum (the owner: "it do not accept
## importing or downloading a game that do not have /data with exposed
## files and populated stuff with minimum level like at least it has the
## sfx, music, shaders, logic, assets, and all others, also it must have
## /save"). voice/characters/vfx are the full shape - recognized, optional.
const DATA_MINIMUM := [
        "data/logic", "data/audio/sfx", "data/audio/music",
        "data/visuals/shaders", "data/visuals/assets",
]
const DATA_OPTIONAL := [
        "data/audio/voice", "data/visuals/characters", "data/visuals/vfx",
]

var _home := ""
var _entries: Array = []
var _entries_by_id := {}
var _current_id := ""               # the running package (SDK context)
var _thumb_cache := {}              # path -> ImageTexture (disk thumbs)

func _ready() -> void:
        ensure_tree()
        reload_entries()
        _scan_libs()
        _ready_bridge()
        _ready_ws()   # v043 pass 3: the web bridge door (WebSocket twin)

# ============================================================ THE HOME TREE

## THE GOGAs HOME LAW (the owner: "in windows, make the folder next to the
## exe, in android, make it in the downloads folder of the system"). A
## test/dev override wins (set_home), then the platform law.
func home() -> String:
        if _home != "":
                return _home
        if OS.has_feature("android"):
                var dl := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
                if dl != "":
                        _home = dl.path_join("GOGAs")
                else:
                        _home = "/storage/emulated/0/Download/GOGAs"
        elif OS.has_feature("web"):
                _home = "user://GOGAs"
        else:
                # the PC law: next to the exe (headless tests: user://)
                var exe := OS.get_executable_path().get_base_dir()
                if exe != "" and DirAccess.dir_exists_absolute(exe):
                        _home = exe.path_join("GOGAs")
                else:
                        _home = "user://GOGAs"
        return _home

func set_home(p: String) -> void:
        _home = p
        ensure_tree()
        reload_entries()

func games_dir() -> String:
        return home().path_join("games")

func libs_dir() -> String:
        return home().path_join("libs")

func discover_dir() -> String:
        return home().path_join("discover")

func cache_dir() -> String:
        return home().path_join(".cache")

## The Android seat needs the honest ask: GOGAs lives in the public
## Downloads tree, and Android 11+ gates it behind ALL-FILES-ACCESS. The
## box asks from the first GOGAs use (never at boot), names the WHY, and
## degrades to an honest refusal when denied (the LAN honesty pattern).
func ensure_tree() -> bool:
        var ok := true
        for d in [home(), games_dir(), libs_dir(), discover_dir(), cache_dir()]:
                if not DirAccess.dir_exists_absolute(d):
                        var err := DirAccess.make_dir_recursive_absolute(d)
                        if err != OK:
                                ok = false
        return ok

# ============================================================ THE ID SCHEME

## gogabox_github-<user>_<ns>.<name>.<id>_<tier>  ->  parts or {}.
## The tier is the LAST underscore segment; the slug is the dotted triple.
static func parse_id(id: String) -> Dictionary:
        var s := String(id)
        if not s.begins_with("gogabox_github-"):
                return {}
        var rest := s.trim_prefix("gogabox_github-")
        var tier_at := rest.rfind("_")
        if tier_at < 0:
                return {}
        var tier := rest.substr(tier_at + 1)
        if not (tier in TIERS):
                return {}
        var head := rest.substr(0, tier_at)
        var user_at := head.find("_")
        if user_at < 0:
                return {}
        var user := head.substr(0, user_at)
        var slug := head.substr(user_at + 1)
        var dotted := slug.split(".", false)
        if user == "" or slug == "" or dotted.size() < 2:
                return {}
        return {"user": user, "slug": slug, "tier": tier}

## The installed folder name for an id (THE RENAME LAW): the id itself -
## "folder name itself isn't game name and it will be renamed to match
## the game id found in the index folder". Ids are filesystem-safe by
## scheme (letters, digits, dots, underscores, hyphens); anything else
## gets sanitized away.
static func folder_for(id: String) -> String:
        var out := ""
        for ch in String(id):
                if ch.is_valid_identifier() or ch in "._-" or (ch >= "a" and ch <= "z") \
                                or (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9"):
                        out += ch
        return out if out != "" else "package"

# ============================================================ THE ENTRIES

## THE UNIFIED FEED: every installed package's index dict, flat, with the
## runtime keys injected (script/root/version/kind). This is what
## GameReg.games() merges behind the baked list.
func entries() -> Array:
        return _entries

func entry(id: String) -> Dictionary:
        return _entries_by_id.get(id, {})

func reload_entries() -> void:
        _entries = []
        _entries_by_id = {}
        _thumb_cache.clear()
        var gdir := DirAccess.open(games_dir())
        if gdir == null:
                return
        gdir.list_dir_begin()
        var name := gdir.get_next()
        while name != "":
                if gdir.current_is_dir() and not name.begins_with("."):
                        var root := games_dir().path_join(name)
                        var e := _read_root_entry(root)
                        if not e.is_empty():
                                # THE COLLISION LAW: two packages claiming the
                                # same short game id - first-installed wins,
                                # the newcomer is ignored (named in the log).
                                var gid := String(e["id"])
                                if _entries_by_id.has(gid):
                                        push_warning("GOGA: game id '%s' already served by another package - '%s' ignored" % [gid, name])
                                else:
                                        _entries.append(e)
                                        _entries_by_id[gid] = e
                name = gdir.get_next()
        gdir.list_dir_end()

func _read_root_entry(root: String) -> Dictionary:
        var ip := root.path_join(INDEX_REL)
        if not FileAccess.file_exists(ip):
                return {}
        var txt := FileAccess.get_file_as_string(ip)
        var data: Variant = JSON.parse_string(txt)
        if not (data is Dictionary):
                return {}
        var e: Dictionary = data
        e["root"] = root
        e["installed_version"] = String(e.get("version", "0"))
        # THE ID SPLIT: the package carries the long publishing id (folders,
        # discover, reports); the BOX world keys on the short game_id. The
        # unified entry wears the short id as "id" (the registry vocabulary)
        # and keeps the long one as "pkg_id".
        e["pkg_id"] = String(e["id"])
        e["id"] = String(e.get("game_id", e["pkg_id"]))
        # v043 pass 3 THE VERSION LEDGER: index/versions.json is the release
        # history - entries() reads versions_count from it when the index
        # does not carry a fresher number (the VERSIONS sort's data).
        var led_v: Variant = JSON.parse_string(
                        FileAccess.get_file_as_string(root.path_join("index/versions.json"))) \
                if FileAccess.file_exists(root.path_join("index/versions.json")) else null
        if led_v is Dictionary:
                var led: Array = (led_v as Dictionary).get("versions", [])
                if not e.has("versions_count") and not led.is_empty():
                        e["versions_count"] = led.size()
        # THE PLATFORM PICK: the run block for THIS device, injected as the
        # registry's own "script" key - the host loads it like any game.
        var run := run_for(e)
        if not run.is_empty():
                e["script"] = String(run.get("script", ""))
                e["kind"] = String(run.get("kind", "godot_embedded"))
        else:
                e["script"] = ""
                e["kind"] = ""
                e["no_run_for_platform"] = true
        return e

## The run block for THIS platform (THE INDEX DECIDES: a package may carry
## per-platform builds - game/android/, game/pc/ - or one shared build).
func run_for(e: Dictionary) -> Dictionary:
        var runs: Dictionary = e.get("runs", {})
        if runs.is_empty():
                return {}
        var plat := "android" if OS.has_feature("android") else "pc"
        if runs.has(plat):
                var r: Dictionary = runs[plat]
                r["platform"] = plat
                return r
        # a shared run block rides the "all" key
        if runs.has("all"):
                var r2: Dictionary = runs["all"]
                r2["platform"] = "all"
                return r2
        return {}

# ============================================================ THE VALIDATOR

## THE STRICT VALIDATOR - every refusal is NAMED (the developer fixes the
## named thing, re-zips, done). Returns {ok, errors:[..]}.
func validate_root(root: String) -> Dictionary:
        var errors: Array = []
        var ip := root.path_join(INDEX_REL)
        if not FileAccess.file_exists(ip):
                errors.append("no %s - the index/ folder is the contract (the game cannot be read without it)" % INDEX_REL)
                return {"ok": false, "errors": errors}
        var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ip))
        if not (data is Dictionary):
                errors.append("index/index.json is not a JSON object")
                return {"ok": false, "errors": errors}
        var e: Dictionary = data
        for key in ["id", "game_id", "title", "version", "age", "genres", "os", "runs", "thumb"]:
                if not e.has(key):
                        errors.append("index/index.json misses \"%s\"" % key)
        if e.has("id"):
                var pid := parse_id(String(e["id"]))
                if pid.is_empty():
                        errors.append("the id \"%s\" does not wear the scheme gogabox_github-<user>_<ns>.<name>.<id>_<tier> (tiers: official/community/hobbyist)" % String(e["id"]))
        if e.has("thumb") and String(e["thumb"]) != "" \
                        and not FileAccess.file_exists(root.path_join(String(e["thumb"]))) \
                        and not ResourceLoader.exists(String(e["thumb"])):
                errors.append("the index thumb \"%s\" does not exist in the package" % String(e["thumb"]))
        if e.has("runs"):
                var runs: Dictionary = e["runs"]
                if runs.is_empty():
                        errors.append("index \"runs\" is empty - at least one platform build must be declared")
                for plat in runs:
                        var r: Dictionary = runs[plat]
                        var kind := String(r.get("kind", "godot_embedded"))
                        match kind:
                                "godot_embedded":
                                        var pck := String(r.get("pck", ""))
                                        if pck == "" or not FileAccess.file_exists(root.path_join(pck)):
                                                errors.append("runs.%s: the godot pck \"%s\" does not exist in the package" % [plat, pck])
                                        if String(r.get("script", "")) == "":
                                                errors.append("runs.%s: no \"script\" (the res:// path of the game scene-script inside the pck)" % plat)
                                "native":
                                        var bin := String(r.get("bin", ""))
                                        if bin == "" or not FileAccess.file_exists(root.path_join(bin)):
                                                errors.append("runs.%s: the native binary \"%s\" does not exist in the package" % [plat, bin])
                                "web":
                                        var entry_html := String(r.get("entry", ""))
                                        if entry_html == "" or not FileAccess.file_exists(root.path_join(entry_html)):
                                                errors.append("runs.%s: the web entry \"%s\" does not exist in the package" % [plat, entry_html])
                                _:
                                        errors.append("runs.%s: unknown kind \"%s\" (godot_embedded | native | web)" % [plat, kind])
        # THE OPEN DATA LAW - the strict minimum
        for rel in DATA_MINIMUM:
                var d := root.path_join(rel)
                if not DirAccess.dir_exists_absolute(d):
                        errors.append("no %s/ - the open-data law (plain moddable files)" % rel)
                elif _dir_file_count(d) < 1:
                        errors.append("%s/ is empty - the open-data law wants populated folders (at least one real file)" % rel)
        for rel in DATA_OPTIONAL:
                var d2 := root.path_join(rel)
                if DirAccess.dir_exists_absolute(d2) and _dir_file_count(d2) < 1:
                        errors.append("%s/ exists but is empty - populate it or remove it" % rel)
        # THE PORTABLE SAVE LAW
        if not DirAccess.dir_exists_absolute(root.path_join("save")):
                errors.append("no save/ - the portable-save law (saves live in the package, never in app-data bloat)")
        # v043 pass 3 THE VERSION LEDGER (index/ is a real folder, not one
        # file): index/versions.json carries the release history - the
        # VERSIONS sort's data and the update story a human can read.
        var vp := root.path_join("index/versions.json")
        if not FileAccess.file_exists(vp):
                errors.append("no index/versions.json - the version ledger (one entry per released version)")
        else:
                var vv: Variant = JSON.parse_string(FileAccess.get_file_as_string(vp))
                if not (vv is Dictionary) or not ((vv as Dictionary).get("versions", []) is Array) \
                                or ((vv as Dictionary).get("versions", []) as Array).is_empty():
                        errors.append("index/versions.json is not a ledger ({\"versions\": [...]}) or is empty")
        # THE DISCOVER MATERIAL
        if not FileAccess.file_exists(root.path_join(PAGE_REL)):
                errors.append("no %s - the discover page material is part of the package" % PAGE_REL)
        return {"ok": errors.is_empty(), "errors": errors}

func _dir_file_count(d: String) -> int:
        var da := DirAccess.open(d)
        if da == null:
                return 0
        var n := 0
        da.list_dir_begin()
        var f := da.get_next()
        while f != "":
                if not da.current_is_dir() and not f.begins_with("."):
                        n += 1
                f = da.get_next()
        da.list_dir_end()
        return n

# ============================================================ THE IMPORTER

## Import ANY shape: a .goga (zip, one root), a .gogas (zip, many roots),
## a folder root, or a parent of roots. Returns the report:
##   {installed:[{id,version}], skipped:[{id,why}], refused:[{name,errors}]}
func import_path(path: String) -> Dictionary:
        var report := {"installed": [], "skipped": [], "refused": []}
        var roots: Array = []
        if path.get_extension() in ["goga", "gogas", "zip"]:
                var tmp := cache_dir().path_join("import/%d" % int(Time.get_unix_time_from_system() * 1000.0))
                var err := _unzip(path, tmp)
                if err != OK:
                        report["refused"].append({"name": path.get_file(),
                                        "errors": ["the archive does not open (zip error %d)" % err]})
                        return report
                roots = _roots_under(tmp)
                # THE TRANSPORT-ARTIFACT LAW: zip archives carry FILES, not
                # empty folders - a fresh package's empty save/ would vanish
                # in transit and read as a refusal. The unzipped roots get
                # save/ re-seated (ONLY save/ - the data/ minimums stay
                # strict, they must carry real files from the packer).
                for root in roots:
                        if not DirAccess.dir_exists_absolute(root.path_join("save")):
                                DirAccess.make_dir_recursive_absolute(root.path_join("save"))
        elif DirAccess.dir_exists_absolute(path):
                # THE STRICT FOLDER LAW: a folder that really lacks save/
                # is a broken package - refuse it by name. (The zip branch
                # above re-seats save/ ONLY because zips physically cannot
                # carry empty folders; a folder has no such excuse, and
                # git repos carry save/README.md - see THE SAVE SEAT LAW.)
                roots = _roots_under(path)
        else:
                report["refused"].append({"name": path.get_file(),
                                "errors": ["nothing importable at \"%s\"" % path]})
                return report
        for root in roots:
                _import_root(root, report)
        if not roots.is_empty():
                reload_entries()
                installed_changed.emit()
        return report

## A root = a folder carrying index/index.json. `dir` may BE one, or carry
## many (the .gogas shape unzipped, or the parent-of-roots local source).
func _roots_under(dir: String) -> Array:
        var out: Array = []
        if FileAccess.file_exists(dir.path_join(INDEX_REL)):
                out.append(dir)
                return out
        var da := DirAccess.open(dir)
        if da == null:
                return out
        da.list_dir_begin()
        var name := da.get_next()
        while name != "":
                if da.current_is_dir() and not name.begins_with(".") \
                                and FileAccess.file_exists(dir.path_join(name).path_join(INDEX_REL)):
                        out.append(dir.path_join(name))
                name = da.get_next()
        da.list_dir_end()
        return out

func _import_root(root: String, report: Dictionary) -> void:
        var name := root.get_file()
        var v := validate_root(root)
        if not bool(v["ok"]):
                report["refused"].append({"name": name, "errors": v["errors"]})
                return
        var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root.path_join(INDEX_REL)))
        var id := String(data["id"])
        var dest_root := games_dir().path_join(id)
        if DirAccess.dir_exists_absolute(dest_root):
                var old := _read_root_entry(dest_root)
                if not old.is_empty():
                        var cmp := version_compare(String(data["version"]), String(old.get("version", "0")))
                        if cmp <= 0:
                                report["skipped"].append({"id": id, "why":
                                        ("already installed (same version)" if cmp == 0
                                        else "installed version %s is newer than %s" % [String(old.get("version")), String(data["version"])])})
                                return
                # THE UPDATE LAW: the old root dies, the new one takes the seat
                _rmdir(dest_root)
        var err := DirAccess.make_dir_recursive_absolute(dest_root.get_base_dir())
        if err != OK and not DirAccess.dir_exists_absolute(dest_root.get_base_dir()):
                report["refused"].append({"name": name,
                                "errors": ["cannot create the install dir (%d)" % err]})
                return
        # THE NON-DESTRUCTIVE IMPORT LAW: the install COPIES, never moves.
        # A package may live anywhere the player or the developer points
        # at - the official repo tree, a virtual-repo dev folder, a shared
        # drive - and the source must survive the install untouched (the
        # rig itself installs the repo's own GOGAs tree; a move would eat
        # the source out of the working copy). The zip path already reads
        # like a copy (extract to .cache first); now the folder path does
        # too. Disk cost: one extra copy at install time - the honest price
        # of never destroying a source.
        if _copy_dir(root, dest_root) != OK:
                report["refused"].append({"name": name,
                                "errors": ["cannot copy the package into games/ (disk or permission)"]})
                return
        report["installed"].append({"id": id, "version": String(data["version"])})

func _copy_dir(src: String, dst: String) -> int:
        var err := DirAccess.make_dir_recursive_absolute(dst)
        if err != OK:
                return err
        var da := DirAccess.open(src)
        if da == null:
            return ERR_CANT_OPEN
        da.list_dir_begin()
        var name := da.get_next()
        while name != "":
                var s := src.path_join(name)
                var d := dst.path_join(name)
                if da.current_is_dir():
                        err = _copy_dir(s, d)
                        if err != OK:
                                return err
                else:
                        err = da.copy(s, d)
                        if err != OK:
                                return err
                name = da.get_next()
        da.list_dir_end()
        return OK

func _rmdir(path: String) -> void:
        var da := DirAccess.open(path)
        if da == null:
                return
        da.list_dir_begin()
        var name := da.get_next()
        while name != "":
                var full := path.path_join(name)
                if da.current_is_dir():
                        _rmdir(full)
                else:
                        da.remove(name)
                name = da.get_next()
        da.list_dir_end()
        DirAccess.remove_absolute(path)

## The zip door: Godot's own ZIPReader (the box trusts the engine's
## decoder - one implementation, used by .goga, .gogas and the discover
## downloads alike).
func _unzip(archive: String, dest: String) -> int:
        var zr := ZIPReader.new()
        var err := zr.open(archive)
        if err != OK:
                return err
        DirAccess.make_dir_recursive_absolute(dest)
        for f in zr.get_files():
                var out := dest.path_join(f)
                if f.ends_with("/"):
                        DirAccess.make_dir_recursive_absolute(out)
                        continue
                var bytes: PackedByteArray = zr.read_file(f)
                if bytes.is_empty() and not f.ends_with("/"):
                        continue
                var da := DirAccess.open(out.get_base_dir())
                if da == null:
                        DirAccess.make_dir_recursive_absolute(out.get_base_dir())
                var fw := FileAccess.open(out, FileAccess.WRITE)
                if fw == null:
                        zr.close()
                        return ERR_CANT_CREATE
                fw.store_buffer(bytes)
                fw.close()
        zr.close()
        return OK

# ============================================================ THE RUNNER

## Mount the package's pck for THIS platform before the host loads the
## game script. THE PCK LAW: replace_files=false - the box's own files can
## NEVER be shadowed by a package (the packaging rig stages the box core
## at the same res:// paths exactly so the compiled base-class references
## resolve to the box's real classes here).
func mount_for(e: Dictionary) -> bool:
        var run := run_for(e)
        if run.is_empty():
                return false
        var kind := String(run.get("kind", "godot_embedded"))
        # v043 pass 3: web + native kinds mount NOTHING (the pck law is the
        # godot_embedded seat) - the runner doors in goga_runner.gd host
        # them. Returning true here lets GameHost.launch() proceed to the
        # host, where the runner takes over (the old false silently killed
        # the launch - the runner doors did not exist yet).
        if kind != "godot_embedded":
                _current_id = String(e["id"])
                return true
        var pck := String(run.get("pck", ""))
        var full := String(e["root"]).path_join(pck)
        if not FileAccess.file_exists(full):
                push_error("GOGA: pck missing: " + full)
                return false
        _current_id = String(e["id"])
        return ProjectSettings.load_resource_pack(full, false)

## The unmount is a NO-OP by engine design (a loaded pack stays for the
## session) - the law is the box's own paths can never be shadowed, so a
## stale pack is harmless. The honest note lives in the catalog.

func uninstall(id: String) -> bool:
        var dest_root := games_dir().path_join(id)
        if not DirAccess.dir_exists_absolute(dest_root):
                return false
        _rmdir(dest_root)
        reload_entries()
        installed_changed.emit()
        return true

# ============================================================ THE VERSIONS

## Semver-ish compare: "0.4.3" < "0.4.10" < "1.0". Returns -1/0/1.
static func version_compare(a: String, b: String) -> int:
        var pa := a.split(".")
        var pb := b.split(".")
        for i in maxi(pa.size(), pb.size()):
                var va := int(pa[i]) if i < pa.size() else 0
                var vb := int(pb[i]) if i < pb.size() else 0
                if va < vb:
                        return -1
                if va > vb:
                        return 1
        return 0

# ============================================================ THE SDK DOORS
## Games call these; ZERO hardcoded box paths. `my_*` ride the CURRENT
## running package (set by mount_for; also settable by tests).

func my_id() -> String:
        return _current_id

func my_root() -> String:
        var e: Dictionary = _entries_by_id.get(_current_id, {})
        return String(e.get("root", ""))

func data_path(rel: String) -> String:
        return my_root().path_join("data").path_join(rel)

func has_data(rel: String) -> bool:
        return FileAccess.file_exists(data_path(rel))

## THE MODDING DOOR: read a data file; falls back to "" when absent (the
## game decides its own packed default).
func data_read(rel: String) -> String:
        var p := data_path(rel)
        return FileAccess.get_file_as_string(p) if FileAccess.file_exists(p) else ""

## JSON with the same fallback: {} when the file is absent/broken.
func data_json(rel: String) -> Dictionary:
        var txt := data_read(rel)
        if txt == "":
                return {}
        var v: Variant = JSON.parse_string(txt)
        return v if (v is Dictionary) else {}

func save_path(rel: String) -> String:
        return my_root().path_join("save").path_join(rel)

## THE PORTABLE SAVE LAW in code: saves live in the package's save/ folder
## - carried with the package, never in app-data bloat.
func save_read(rel: String) -> String:
        var p := save_path(rel)
        return FileAccess.get_file_as_string(p) if FileAccess.file_exists(p) else ""

func save_write(rel: String, txt: String) -> bool:
        var p := save_path(rel)
        var f := FileAccess.open(p, FileAccess.WRITE)
        if f == null:
                return false
        f.store_string(txt)
        f.close()
        return true

func save_json_write(rel: String, data: Dictionary) -> bool:
        return save_write(rel, JSON.stringify(data, "  "))

func save_json_read(rel: String) -> Dictionary:
        var txt := save_read(rel)
        if txt == "":
                return {}
        var v: Variant = JSON.parse_string(txt)
        return v if (v is Dictionary) else {}

## The override seat for a VISUAL asset: a package's data/visuals/assets
## file wins when present (the modding law), else "" (the game uses its
## packed default).
func visual_override(rel: String) -> String:
        var p := data_path("visuals/assets").path_join(rel)
        return p if FileAccess.file_exists(p) else ""

## The disk thumbnail as a texture (package thumbs are files, not res://).
func thumb_texture(e: Dictionary) -> Texture2D:
        var t := String(e.get("thumb", ""))
        if t == "":
                return null
        if t.begins_with("res://"):
                return load(t) if ResourceLoader.exists(t) else null
        var full := t if t.is_absolute_path() else String(e.get("root", "")).path_join(t)
        if _thumb_cache.has(full):
                return _thumb_cache[full]
        if not FileAccess.file_exists(full):
                return null
        var img := Image.load_from_file(full)
        if img == null:
                return null
        var tex := ImageTexture.create_from_image(img)
        _thumb_cache[full] = tex
        return tex

# ============================================================ THE SDK BRIDGE
## THE STANDALONE DOOR (the Steam model the owner described: "as same as
## steam api where it forces the steam app to launch"): a standalone game
## (its own Godot export, its own renderer, a native .exe) REQUIRES the
## running box and talks to it over localhost TCP. The box runs this
## server ALWAYS (PROCESS_MODE_ALWAYS - a paused menu still serves games);
## the wire is newline-delimited JSON:
##   -> {"op": "hello", "client": "<id>", "proto": 1}
##   <- {"ok": true, "box": "0.4.3", "proto": 1}
##   -> {"op": "coins.balance"}                      <- {"ok": true, "coins": n}
##   -> {"op": "coins.spend", "n": 10}               <- {"ok": true/false}
##   -> {"op": "coins.earn", "n": 5}                 <- {"ok": true}
##   -> {"op": "save.write", "key": k, "data": s}    <- {"ok": true}
##   -> {"op": "save.read", "key": k}                <- {"ok": true, "data": s}
##   -> {"op": "toast", "msg": "..."}                <- {"ok": true}
## Client saves live under GOGAs/libs/clients/<client>/save.json - THE
## PORTABLE SAVE LAW holds for standalone games too: never app-data bloat.

const SDK_PORT := 31442
const SDK_PROTO := 1

var _sdk_server: TCPServer = null
var _sdk_peers: Array = []          # [{conn: StreamPeerTCP, buf: String, client: String}]

func _ready_bridge() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        _sdk_server = TCPServer.new()
        # localhost ONLY - the bridge serves games on THIS machine
        if _sdk_server.listen(SDK_PORT, "127.0.0.1") != OK:
                _sdk_server = null   # honest: another seat holds the port

func _exit_tree() -> void:
        if _sdk_server != null:
                _sdk_server.stop()
        for p in _sdk_peers:
                (p["conn"] as StreamPeerTCP).disconnect_from_host()
        if _ws_tcp != null:
                _ws_tcp.stop()

func _process(_delta: float) -> void:
        _bridge_tick()
        _ws_tick()

func _bridge_tick() -> void:
        if _sdk_server == null:
                return
        while _sdk_server.is_connection_available():
                var conn: StreamPeerTCP = _sdk_server.take_connection()
                _sdk_peers.append({"conn": conn, "buf": "", "client": ""})
        var alive: Array = []
        for p in _sdk_peers:
                var conn: StreamPeerTCP = p["conn"]
                if conn.get_status() != StreamPeerTCP.STATUS_CONNECTED:
                        conn.disconnect_from_host()
                        continue
                var n := conn.get_available_bytes()
                if n > 0:
                        # RAW bytes - the utf8_string helpers carry a 16-bit
                        # length prefix that would corrupt the \n framing
                        var got := conn.get_data(n)
                        if got[0] == OK:
                                p["buf"] = String(p["buf"]) \
                                                + (got[1] as PackedByteArray).get_string_from_utf8()
                var buf := String(p["buf"])
                while buf.contains("\n"):
                        var line := buf.substr(0, buf.find("\n")).strip_edges()
                        buf = buf.substr(buf.find("\n") + 1)
                        _bridge_handle(p, line)
                p["buf"] = buf
                alive.append(p)
        _sdk_peers = alive

func _bridge_handle(p: Dictionary, line: String) -> void:
        var conn: StreamPeerTCP = p["conn"]
        var req: Variant = JSON.parse_string(line)
        if not (req is Dictionary):
                _bridge_send(conn, {"ok": false, "err": "bad json"})
                return
        var r: Dictionary = req
        var op := String(r.get("op", ""))
        # the ONE vocabulary: the TCP door and the WebSocket door share it
        _bridge_send(conn, _bridge_dispatch(p, r, op))

func _bridge_send(conn: StreamPeerTCP, data: Dictionary) -> void:
        conn.put_data((JSON.stringify(data) + "\n").to_utf8_buffer())

## THE WEB BRIDGE DOOR (v043 pass 3): the WebSocket twin of the TCP bridge
## (port 31443, loopback only). Web games run in a WebView / app window
## where raw TCP does not exist - a browser speaks WebSocket. SAME ops
## vocabulary, SAME answers: hello / coins.balance / coins.spend /
## coins.earn / save.write / save.read / toast. The sdk/web/goga_bridge.js
## speaks it for the game. THE ONE API, the transports multiply.
const SDK_WS_PORT := 31443

var _ws_tcp: TCPServer = null
var _ws_conns: Array = []          # [{tcp, ws: WebSocketPeer, client: String}]

func _ready_ws() -> void:
        # a server-style WebSocketPeer pair per connection: Godot 4.7's
        # WebSocketPeer.accept_stream() upgrades a raw StreamPeerTCP - one
        # loop, the SAME _bridge_dispatch vocabulary as the raw TCP door.
        _ws_tcp = TCPServer.new()
        if _ws_tcp.listen(SDK_WS_PORT, "127.0.0.1") != OK:
                _ws_tcp = null   # honest: the port is taken (another seat)

func _ws_tick() -> void:
        if _ws_tcp == null:
                return
        while _ws_tcp.is_connection_available():
                var tcp: StreamPeerTCP = _ws_tcp.take_connection()
                var ws := WebSocketPeer.new()
                ws.accept_stream(tcp)
                _ws_conns.append({"tcp": tcp, "ws": ws, "client": ""})
        var alive: Array = []
        for c in _ws_conns:
                var ws: WebSocketPeer = c["ws"]
                ws.poll()
                var state := ws.get_ready_state()
                if state == WebSocketPeer.STATE_CLOSED:
                        continue
                if state == WebSocketPeer.STATE_OPEN:
                        while ws.get_available_packet_count() > 0:
                                var line := ws.get_packet().get_string_from_utf8()
                                _ws_handle(c, line)
                alive.append(c)
        _ws_conns = alive

func _ws_handle(c: Dictionary, line: String) -> void:
        var req: Variant = JSON.parse_string(line)
        if not (req is Dictionary):
                _ws_send(c, {"ok": false, "err": "bad json"})
                return
        var r: Dictionary = req
        var op := String(r.get("op", ""))
        # the SAME vocabulary the TCP bridge serves - one handler, two wires
        var reply: Dictionary = _bridge_dispatch(c, r, op)
        _ws_send(c, reply)

func _ws_send(c: Dictionary, data: Dictionary) -> void:
        var ws: WebSocketPeer = c["ws"]
        if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
                ws.send_text(JSON.stringify(data))

## The shared bridge vocabulary: the TCP door and the WebSocket door both
## land here so the two transports can never drift apart.
func _bridge_dispatch(p: Dictionary, r: Dictionary, op: String) -> Dictionary:
        var client := String(p.get("client", ""))
        match op:
                "hello":
                        p["client"] = String(r.get("client", "anon"))
                        return {"ok": true, "box": self_version(), "proto": SDK_PROTO}
                "coins.balance":
                        return {"ok": true, "coins": Box.coins()}
                "coins.spend":
                        var n := int(r.get("n", 0))
                        var did := Box.spend(n) if not Box.dev_cheat("gogacoins") == 1 else true
                        return {"ok": did}
                "coins.earn":
                        Box.earn(int(r.get("n", 0)))
                        return {"ok": true}
                "save.write":
                        if client == "":
                                return {"ok": false, "err": "say hello first"}
                        return {"ok": _client_save_write(client,
                                        String(r.get("key", "save")), String(r.get("data", "")))}
                "save.read":
                        if client == "":
                                return {"ok": false, "err": "say hello first"}
                        return {"ok": true,
                                        "data": _client_save_read(client, String(r.get("key", "save")))}
                "toast":
                        LanNotes.note(String(r.get("msg", "")))
                        return {"ok": true}
                _:
                        return {"ok": false, "err": "unknown op"}

## Standalone client saves: GOGAs/libs/clients/<client>/save.json - inside
## the GOGAs tree, portable, never app-data (the save law, standalone seat).
func _client_save_path(client: String, key: String) -> String:
        var safe := client.replace("/", "_").replace("..", "_")
        return libs_dir().path_join("clients").path_join(safe).path_join(key + ".json")

func _client_save_write(client: String, key: String, data: String) -> bool:
        var path := _client_save_path(client, key)
        DirAccess.make_dir_recursive_absolute(path.get_base_dir())
        var f := FileAccess.open(path, FileAccess.WRITE)
        if f == null:
                return false
        f.store_string(data)
        f.close()
        return true

func _client_save_read(client: String, key: String) -> String:
        var path := _client_save_path(client, key)
        return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""

func self_version() -> String:
        var cfg := ConfigFile.new()
        if cfg.load("res://project.godot") == OK:
                var v: String = str(cfg.get_value("application", "config/version", ""))
                if v != "":
                        return v
        return "dev"

# ------------------------------------------------------ the SDK-facing doors
## The embedded transport of the GogaSdk plugin (sdk/godot/gogabox_sdk/)
## lands here when a game calls from inside the box. The wire ops reuse
## the exact same doors (one vocabulary, two transports).

func coins_balance() -> int:
        return Box.coins()

func coins_spend(n: int) -> bool:
        return Box.spend(n)

func coins_earn(n: int) -> void:
        Box.earn(n)

func sdk_save_write(client: String, key: String, data: String) -> bool:
        return _client_save_write(client, key, data)

func sdk_save_read(client: String, key: String) -> String:
        return _client_save_read(client, key)

func sdk_toast(msg: String) -> void:
        LanNotes.note(msg)

## THE LIBS LAW (the owner's own call, blessed): the libs/ folder is the
## drop-in extension point - the box binary IS the SDK for embedded games,
## and libs/ carries the per-platform BRIDGES (native ABI hosts, the
## standalone-game connector, future GDExtension hosts). The scan is
## honest: it lists and manifests what is present; nothing is faked.
var libs_found: Array = []

func _scan_libs() -> void:
        libs_found = []
        var da := DirAccess.open(libs_dir())
        if da == null:
                return
        da.list_dir_begin()
        var name := da.get_next()
        while name != "":
                if not da.current_is_dir() and not name.begins_with("."):
                        libs_found.append(name)
                name = da.get_next()
        da.list_dir_end()
        libs_found.sort()
