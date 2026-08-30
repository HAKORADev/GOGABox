extends Node
## ============================================================================
## THUMBNAIL CAPTURE HARNESS - dev tool, EXCLUDED from every export preset
## (export_presets.cfg exclude_filter carries dev/* - never ships to players).
##
## Owner-approved pipeline (docs/THUMBNAILS.md, v0.1.6):
##   run the REAL game scene at its NATIVE design resolution, a tiny per-game
##   "drive" (auto-pilot) plays it honestly, we save candidate frames, and a
##   Python post stage downscales to the universal 960x640 thumbnail canvas.
##   A vision pass picks the winner. No baked text (rule R2) unless a drive
##   explicitly opts in - game font first when the game has one.
##
## Run (from repo root):
##   GODOT_BIN --headless --path projects/gogabox \
##     res://dev/thumb_capture/capture.tscn ++ --game=snake --time=20 \
##     --every=0.5 --seed=7 --out=/abs/dir [--hud] [--w=1080] [--h=1920]
##
##   --game   registry id (snake, rally, ...) or "all"
##   --time   total sim seconds to capture (default 20 - make it 40, whatever)
##   --every  seconds between candidate frames (default 0.5)
##   --seed   RNG seed for reproducible runs (default 7)
##   --out    ABSOLUTE output dir for frames
##   --hud    keep the in-game HUD visible (default: hidden, poster look)
##   --warmup sim seconds before the first candidate (default 1.5)
##   --w/--h  override the native capture size (rare)
##
## Multi-scene games (future rooms/levels): a drive may implement
##   segments() -> [{ "name": "lava", "at": 12.0 }, ...]
## frames get tagged with the active segment: snake_t0012.0_lava.png
## ============================================================================

var _args := {}
var _out := "/tmp/thumbs_raw"
var _every := 0.5
var _total := 20.0
var _warmup := 1.5
var _hud := false

var _game: GogaGame
var _drive: Object
var _segs: Array = []
var _seg := ""
var _t := 0.0
var _next_cap := 0.0
var _id := ""
var _queue: Array = []      # game ids left to capture
var _capturing := false
var _frames := 0

func _ready() -> void:
        _args = _parse_args()
        _out = String(_args.get("out", _out))
        _every = float(_args.get("every", "0.5"))
        _total = float(_args.get("time", "20.0"))
        _warmup = float(_args.get("warmup", "1.5"))
        _hud = _args.has("hud")
        var which := String(_args.get("game", "snake"))
        if which == "all":
                for g in GameReg.GAMES:
                        if not bool(g.get("coming_soon", false)):
                                _queue.append(String(g["id"]))
        else:
                _queue.append(which)
        seed(int(_args.get("seed", "7")))
        DirAccess.make_dir_recursive_absolute(_out)
        Engine.max_fps = 240
        _next_game()

func _parse_args() -> Dictionary:
        var d := {}
        for a in OS.get_cmdline_user_args():
                var s := String(a)
                if s.begins_with("--"):
                        s = s.substr(2)
                        var eq := s.find("=")
                        if eq >= 0:
                                d[s.substr(0, eq)] = s.substr(eq + 1)
                        else:
                                d[s] = "1"
        return d

func _next_game() -> void:
        if _queue.is_empty():
                print("[capture] DONE all games")
                get_tree().quit()
                return
        _id = _queue.pop_front()
        var g := GameReg.get_game(_id)
        if g.is_empty():
                print("[capture] unknown game: %s" % _id)
                _next_game()
                return
        var land := String(g.get("orientation", "portrait")) == "landscape"
        var w := int(_args.get("w", "1920" if land else "1080"))
        var h := int(_args.get("h", "1080" if land else "1920"))
        # NATIVE design resolution, 1:1 px - the owner rule: games run at
        # their real resolution, downscaling to 960x640 happens post-stage.
        get_window().size = Vector2i(w, h)
        get_window().content_scale_size = Vector2i(w, h)
        get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
        get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
        for c in get_children():
                c.queue_free()
        var bg := ColorRect.new()
        bg.color = Color("241407")   # the host's own-world background color
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(bg)

        _game = (load(String(g["script"])) as GDScript).new()
        _game.game_id = _id
        _game.request_finish.connect(func(_s: int, _c: int): pass)  # no host chrome
        add_child(_game)

        var drive_path := "res://dev/thumb_capture/drives/%s_drive.gd" % _id
        if ResourceLoader.exists(drive_path):
                _drive = (load(drive_path) as GDScript).new()
                _drive.game = _game
                _segs = _drive.segments() if _drive.has_method("segments") else []
        else:
                _drive = null
                _segs = []
                print("[capture] WARNING no drive for %s - passive capture" % _id)

        _seg = ""
        _t = 0.0
        _next_cap = _warmup
        _capturing = true
        _frames = 0
        print("[capture] %s: native %dx%d, %.1fs, every %.2fs -> %s" %
                        [_id, w, h, _total, _every, _out])
        # HUD is built during _ready -> hide it once setup settles
        await get_tree().process_frame
        await get_tree().process_frame
        if not _hud and _game._hud != null:
                _game._hud.visible = false

func _process(delta: float) -> void:
        if not _capturing or _game == null or not is_instance_valid(_game):
                return
        _t += delta
        if _drive != null and _drive.has_method("tick"):
                _drive.tick(_t)
        # segment tracking (multi-scene/level games)
        for s in _segs:
                if _t >= float(s["at"]):
                        _seg = String(s["name"])
        if _t >= _next_cap:
                _next_cap += _every
                _snap()
        if _t >= _total:
                _capturing = false
                print("[capture] %s: %d candidates" % [_id, _frames])
                _cleanup_game()
                _next_game()

func _snap() -> void:
        var img := get_viewport().get_texture().get_image()
        if img == null or img.is_empty():
                print("[capture] BLACK/EMPTY frame at t=%.1f" % _t)
                return
        var tag := "" if _seg == "" else "_%s" % _seg
        var p := "%s/%s_t%07.1f%s.png" % [_out, _id, _t, tag]
        img.save_png(p)
        _frames += 1

func _cleanup_game() -> void:
        if _drive != null:
                _drive.game = null
        if _game != null and is_instance_valid(_game):
                _game.queue_free()
        _game = null
