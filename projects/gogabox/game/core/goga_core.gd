extends Node
## GOGA — the game folder runtime (v044 THE BOX, SIMPLIFIED).
##
## The box bakes ZERO games (THE EMPTY BINARY LAW stands); every game is a
## plain folder under the GOGAs/ home tree:
##
##   GOGAs/                   Windows: next to the exe · Android: Downloads
##     games/<id>/            one folder per game - THE FOLDER NAME IS THE ID
##       game.json            the name file (title, os, age, genres, fee...)
##       game.pck             THE ONE ENTRY - the same file name on every game
##       thumb.png            the tile art (game.json "thumb" points at it)
##       ...                  the game's own business - the box never looks
##
## No validator, no importer, no downloads, no updates, no servers. A game
## exists when its folder carries game.json + game.pck; drop the folder in
## place and the entry launches. Share a game = share the folder.
##
## THE SDK (optional, in-process): games that want the economy or a save
## spot call the doors below - zero hardcoded box paths. Games that ignore
## the doors are equally welcome; the box observes nothing.

signal installed_changed            # a game folder landed / left

const ENTRY_PCK := "game.pck"       # THE UNIFIED ENTRY LAW - one name everywhere
const MANIFEST := "game.json"       # the name file
const DEFAULT_SCRIPT := "res://entry.gd"   # the default entry script in a pack

var _home := ""
var _entries: Array = []
var _entries_by_id := {}
var _current_id := ""               # the running game (SDK context)
var _thumb_cache := {}              # path -> ImageTexture (disk thumbs)

func _ready() -> void:
        ensure_tree()
        reload_entries()

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

## The Android seat needs the honest ask: GOGAs lives in the public
## Downloads tree, and Android 11+ gates it behind ALL-FILES-ACCESS. The
## box asks from the first GOGAs use (never at boot), names the WHY, and
## degrades to an honest refusal when denied (the LAN honesty pattern).
func ensure_tree() -> bool:
        var ok := true
        for d in [home(), games_dir()]:
                if not DirAccess.dir_exists_absolute(d):
                        var err := DirAccess.make_dir_recursive_absolute(d)
                        if err != OK:
                                ok = false
        return ok

# ============================================================ THE ENTRIES

## THE UNIFIED FEED: every game folder's manifest dict, flat, with the
## runtime keys injected (root/id/script/kind). This is what
## GameReg.games() merges behind the baked list.
func entries() -> Array:
        return _entries

func entry(id: String) -> Dictionary:
        return _entries_by_id.get(id, {})

## THE SCAN: games/ holds one folder per game. The folder name is the id,
## game.json is the name file, game.pck is the entry. Two file reads, no
## validator - anything else in the folder belongs to the game.
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
                        var e := _read_folder_entry(games_dir().path_join(name), name)
                        if not e.is_empty():
                                # THE COLLISION LAW: two folders claiming the
                                # same id cannot exist (a filesystem holds one
                                # name once) - but a scan racing a rename can
                                # read a double; first wins, named in the log.
                                var gid := String(e["id"])
                                if _entries_by_id.has(gid):
                                        push_warning("GOGA: game id '%s' served twice - the second read was ignored" % gid)
                                else:
                                        _entries.append(e)
                                        _entries_by_id[gid] = e
                name = gdir.get_next()
        gdir.list_dir_end()

func _read_folder_entry(root: String, folder: String) -> Dictionary:
        var mp := root.path_join(MANIFEST)
        var pp := root.path_join(ENTRY_PCK)
        if not FileAccess.file_exists(pp):
                return {}       # no entry pack - not a game, not a refusal
        var e: Dictionary = {}
        if FileAccess.file_exists(mp):
                var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(mp))
                if data is Dictionary:
                        e = data
        # THE NAME LAW: the folder is the id; the title lives in game.json.
        # A folder without a manifest still plays - it wears its folder name.
        e["id"] = folder
        if String(e.get("title", "")).strip_edges() == "":
                e["title"] = folder.to_upper()
        e["root"] = root
        e["kind"] = "godot_embedded"
        # THE PLATFORM TRUTH: game.json "os" (default both). The play button
        # reads it - the honest PHONE ONLY / PC ONLY instead of a dead press.
        var os: Variant = e.get("os", ["android", "pc"])
        if not (os is Array):
                os = ["android", "pc"]
        e["os"] = os
        var plat := "android" if OS.has_feature("android") else "pc"
        e["script"] = String(e.get("script", DEFAULT_SCRIPT))
        e["no_run_for_platform"] = not (plat in (os as Array))
        return e

# ============================================================ THE RUNNER

## Mount the game's pack before the host loads the entry script. THE PCK
## LAW: replace_files=false - the box's own files can NEVER be shadowed by
## a game pack.
func mount_for(e: Dictionary) -> bool:
        var full := String(e.get("root", "")).path_join(ENTRY_PCK)
        if not FileAccess.file_exists(full):
                push_error("GOGA: pack missing: " + full)
                return false
        _current_id = String(e["id"])
        return ProjectSettings.load_resource_pack(full, false)

## The unmount is a NO-OP by engine design (a loaded pack stays for the
## session) - the law is the box's own paths can never be shadowed, so a
## stale pack is harmless.

## Removing a game = deleting its folder (by hand or by this door). The
## box keeps no registry of its own to clean up.
func uninstall(id: String) -> bool:
        var dest_root := games_dir().path_join(id)
        if not DirAccess.dir_exists_absolute(dest_root):
                return false
        _rmdir(dest_root)
        reload_entries()
        installed_changed.emit()
        return true

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

# ============================================================ THE SDK DOORS
## Games call these; ZERO hardcoded box paths. `my_*` ride the CURRENT
## running game (set by mount_for; also settable by tests).

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

## THE PORTABLE SAVE DOOR: saves live in the game's own folder when the
## game wants them there - carried with the folder, never in app-data
## bloat. A game that manages its own files never calls this.
func save_read(rel: String) -> String:
        var p := save_path(rel)
        return FileAccess.get_file_as_string(p) if FileAccess.file_exists(p) else ""

func save_write(rel: String, txt: String) -> bool:
        var p := save_path(rel)
        DirAccess.make_dir_recursive_absolute(p.get_base_dir())
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

## The override seat for a VISUAL asset: a file placed in the game's
## data/visuals/assets wins when present (the modding door), else "" (the
## game uses its packed default).
func visual_override(rel: String) -> String:
        var p := data_path("visuals/assets").path_join(rel)
        return p if FileAccess.file_exists(p) else ""

## The disk thumbnail as a texture (game thumbs are files, not res://).
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

func coins_balance() -> int:
        return Box.coins()

func coins_spend(n: int) -> bool:
        return Box.spend(n)

func coins_earn(n: int) -> void:
        Box.earn(n)

func self_version() -> String:
        var cfg := ConfigFile.new()
        if cfg.load("res://project.godot") == OK:
                var v: String = str(cfg.get_value("application", "config/version", ""))
                if v != "":
                        return v
        return "dev"
