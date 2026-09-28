class_name GogaRunner
extends Node
## THE RUNNER SEAT (v043 pass 3) - the doors for the NON-embedded kinds.
## The validator always recognized godot_embedded | native | web; until
## now only the embedded door existed and a web/native launch silently
## died in mount_for. The doors:
##
##   web    - the box serves the package's game/web/ over localhost
##            (GogaWebserve) and opens it in an IN-APP surface: Android =
##            the gogabrowser plugin (the system WebView, no browser
##            chrome, no tab, no redirection); PC = the system's own
##            WebView2 runtime in app mode (msedge/chrome --app, a
##            chromeless window - the honest seat until the WebView2
##            extension lands, using the engine the box already trusts).
##            The page's SDK bridge is sdk/web/goga_bridge.js over the
##            WebSocket door (port 31443) - the same ops vocabulary as
##            every other transport.
##   native - PC: the package's exe launches as a CHILD PROCESS (the
##            Steam model); the seat watches the process and ends the
##            session when it exits. SDK-linked games talk back over the
##            TCP bridge (31442). Android: the in-process .so loader is
##            the NEXT platform round - the door refuses honestly today.
##
## The seat owns its own holding UI (the game runs OUTSIDE the box's
## canvas on PC) and reports the session end through GameHost's own
## quit door - the economy, the play time and the box chrome behave
## exactly like any embedded run.

signal finished

var host: Node = null            # the host_node that seated us
var mode := ""                   # "web" | "native"
var why := ""                    # the honest refusal when the door cannot open
var url := ""                    # web: the served URL
var pid := -1                    # the child process (PC web / native)
var _server: GogaWebserve = null
var _watch := 0.0
var _started := false

const WATCH_S := 0.5

## Seat the runner for `g` (a unified entry with root + kind). Returns
## false when the door refuses (the why is on the seat; the host shows it).
func setup(host_node: Node, g: Dictionary) -> bool:
        host = host_node
        var run: Dictionary = GOGA.run_for(g)
        mode = String(run.get("kind", ""))
        var root := String(g.get("root", ""))
        if root == "" or mode == "":
                why = "the entry carries no package root or kind"
                return false
        if mode == "web":
                var entry := String(run.get("entry", ""))
                var entry_path := root.path_join(entry)
                if entry == "" or not FileAccess.file_exists(entry_path):
                        why = "the web entry \"%s\" does not exist in the package" % entry
                        return false
                var serve_dir := entry_path.get_base_dir()
                _server = GogaWebserve.new()
                add_child(_server)
                url = _server.serve(serve_dir)
                if url == "":
                        _server = null
                        why = "the web seat could not open a loopback port"
                        return false
                url += "/" + entry_path.get_file()
                # v043 pass 3: the platform gates ride the OS feature (NOT
                # ScaleRule.is_pc - the headless rig would misread it): the
                # Android plugin on the phone, the app-mode window on a
                # desktop, the honest refusal where no seat exists.
                if OS.has_feature("android"):
                        if not _open_android_web(url):
                                why = "the in-app browser seat is not available on this device"
                                return false
                else:
                        pid = _spawn_pc_web(url)
                        if pid <= 0:
                                why = "no app-mode browser found (Edge or Chrome is the PC web seat)"
                                return false
        elif mode == "native":
                if OS.has_feature("android"):
                        why = "the Android native loader (.so in-process) lands with the next platform round"
                        return false
                var bin := String(run.get("bin", ""))
                var bin_path := root.path_join(bin)
                if bin == "" or not FileAccess.file_exists(bin_path):
                        why = "the native binary \"%s\" does not exist in the package" % bin
                        return false
                var real := ProjectSettings.globalize_path(bin_path)
                # a zip/file-copy install never carries the exec bit - the
                # honest seat grants it (POSIX only; Windows PE needs none)
                if not OS.has_feature("windows"):
                        OS.execute("chmod", ["+x", real])
                pid = OS.create_process(real, [])
                if pid <= 0:
                        why = "the native binary refused to start"
                        return false
        else:
                why = "unknown kind \"%s\"" % mode
                return false
        _started = true
        _build_ui()
        return true

# ------------------------------------------------------------ the surfaces

## PC web: the system's WebView2 runtime in APP MODE - a chromeless
## window (no tabs, no address bar, no redirection), the same engine
## WebView2 would embed. A private user-data dir keeps the seat isolated
## from the player's own browser session. Edge first (it IS the WebView2
## runtime), Chrome as the fallback.
func _spawn_pc_web(target: String) -> int:
        var exe := _find_pc_browser()
        if exe == "":
                return -1
        var profile := ProjectSettings.globalize_path(
                        GOGA.cache_dir().path_join("webseat"))
        var args := [
                "--app=" + target,
                "--window-size=1280,800",
                "--user-data-dir=" + profile,
                "--no-first-run", "--no-default-browser-check",
                "--no-sandbox", "--disable-gpu",
        ]
        return OS.create_process(exe, args)

func _find_pc_browser() -> String:
        var candidates: Array = []
        if OS.has_feature("windows"):
                var pf86 := OS.get_environment("PROGRAMFILES(X86)")
                var pf := OS.get_environment("PROGRAMFILES")
                var lad := OS.get_environment("LOCALAPPDATA")
                if pf86 != "":
                        candidates += [pf86 + "\\Microsoft\\Edge\\Application\\msedge.exe"]
                if pf != "":
                        candidates += [pf + "\\Microsoft\\Edge\\Application\\msedge.exe"]
                if lad != "":
                        candidates += [lad + "\\Microsoft\\Edge\\Application\\msedge.exe",
                                        lad + "\\Google\\Chrome\\Application\\chrome.exe"]
        else:
                # the dev/rig seat on linux: the system browsers first, then
                # the playwright chromium the sandbox carries (the eye pass
                # drives the real web seat through it)
                candidates += ["/usr/bin/chromium", "/usr/bin/chromium-browser",
                                "/usr/bin/google-chrome"]
                var pw := OS.get_environment("HOME")
                if pw != "":
                        var glob := DirAccess.open(pw.path_join(".cache/ms-playwright"))
                        if glob != null:
                                glob.list_dir_begin()
                                var n := glob.get_next()
                                while n != "":
                                        if n.begins_with("chromium-"):
                                                candidates.append(pw.path_join(
                                                                ".cache/ms-playwright").path_join(n)
                                                                .path_join("chrome-linux64/chrome"))
                                        n = glob.get_next()
                                glob.list_dir_end()
        for c in candidates:
                if FileAccess.file_exists(c):
                        return c
        return ""

## Android web: the gogabrowser plugin surface (the system WebView
## in-app). The addon is a desktop/test no-op - the honest false.
func _open_android_web(target: String) -> bool:
        if Engine.has_singleton("GogaBrowser"):
                var b = Engine.get_singleton("GogaBrowser")
                b.load_url(target)
                b.show_surface()
                return true
        return false

func _close_android_web() -> void:
        if Engine.has_singleton("GogaBrowser"):
                var b = Engine.get_singleton("GogaBrowser")
                b.hide_surface()

# ------------------------------------------------------------ the holding UI

## The honest refusal: the door could not open (missing entry, no browser,
## the Android native loader not landed) - the why is NAMED, the session
## ends through the same door. Never a silent death.
func show_refusal() -> void:
        mode = "refused"
        var layer := CanvasLayer.new()
        layer.layer = 5
        add_child(layer)
        var vb := VBoxContainer.new()
        vb.set_anchors_preset(Control.PRESET_FULL_RECT)
        vb.alignment = BoxContainer.ALIGNMENT_CENTER
        vb.add_theme_constant_override("separation", 24)
        layer.add_child(vb)
        var l1 := Label.new()
        l1.text = "CANNOT OPEN"
        l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l1.add_theme_font_size_override("font_size", 48)
        l1.add_theme_color_override("font_color", Color("e08a4a"))
        vb.add_child(l1)
        var l2 := Label.new()
        l2.text = why
        l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l2.custom_minimum_size = Vector2(900, 0)
        l2.add_theme_font_size_override("font_size", 26)
        l2.add_theme_color_override("font_color", Color("b99a72"))
        vb.add_child(l2)
        var btn := Button.new()
        btn.text = "  BACK TO THE BOX  "
        btn.add_theme_font_size_override("font_size", 30)
        btn.pressed.connect(func(): finished.emit())
        var center := HBoxContainer.new()
        center.alignment = BoxContainer.ALIGNMENT_CENTER
        center.add_child(btn)
        vb.add_child(center)

func _build_ui() -> void:
        var layer := CanvasLayer.new()
        layer.layer = 5
        add_child(layer)
        var bg := ColorRect.new()
        bg.color = Color("241407")
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        layer.add_child(bg)
        var vb := VBoxContainer.new()
        vb.set_anchors_preset(Control.PRESET_FULL_RECT)
        vb.alignment = BoxContainer.ALIGNMENT_CENTER
        vb.add_theme_constant_override("separation", 24)
        layer.add_child(vb)
        var title := "%s RUNNING" % ("WEB GAME" if mode == "web" else "NATIVE GAME")
        var l1 := Label.new()
        l1.text = title
        l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l1.add_theme_font_size_override("font_size", 52)
        l1.add_theme_color_override("font_color", Color("f5c56b"))
        vb.add_child(l1)
        var l2 := Label.new()
        l2.text = ("the game opened in its own window - close it to return to the box"
                        if ScaleRule.is_pc() else
                        "the game runs in the app's browser seat - press BACK to return")
        l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l2.custom_minimum_size = Vector2(900, 0)
        l2.add_theme_font_size_override("font_size", 26)
        l2.add_theme_color_override("font_color", Color("b99a72"))
        vb.add_child(l2)
        var btn := Button.new()
        btn.text = "  END SESSION  "
        btn.add_theme_font_size_override("font_size", 30)
        btn.pressed.connect(func():
                _teardown()
                finished.emit())
        var center := HBoxContainer.new()
        center.alignment = BoxContainer.ALIGNMENT_CENTER
        center.add_child(btn)
        vb.add_child(center)

# ------------------------------------------------------------ the watch

func _process(delta: float) -> void:
        if not _started:
                return
        # the PC seats end the session when the child window closes
        if pid > 0 and not OS.is_process_running(pid):
                _watch += delta
                # one settled read - the process table can lag the close
                if _watch >= WATCH_S:
                        _started = false
                        _teardown()
                        finished.emit()
                return
        _watch = 0.0

## Tear the surfaces down (the server dies with the node tree anyway,
## but an explicit stop keeps the loopback ports free for the next seat).
func _teardown() -> void:
        _started = false
        if _server != null:
                _server.stop()
        if pid > 0 and OS.is_process_running(pid):
                OS.kill(pid)
        pid = -1
        _close_android_web()

## The back door (the host's request_pause): the seat IS the session.
func finish_from_back() -> void:
        _teardown()
        finished.emit()
